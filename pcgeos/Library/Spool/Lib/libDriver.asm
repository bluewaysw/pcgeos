COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		libDriver.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------
	MapToPrinterFont	take a requested font and pick the closest
				printer resident font
	UpdateTranslationTable	initializes the translation table in the
				PState
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/31/92		Initial revision

DESCRIPTION:
	Contains miscellaneous spool library routines used in the print
	drivers.

	$Id: libDriver.asm,v 1.1 97/04/07 11:10:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolMisc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolMapToPrinterFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map the PC/GEOS font passed in the Style run to the closest
		printer font we can find.

CALLED BY:	EXTERNAL
		library call back from print driver set font routine

PASS:		cx      =       requested FontID
                dx      =       requested Point Size
                bl      =       requested pitch value
		es	=	PState segment.
		ds	=	device info resource segment address
		

RETURN:		cx	=	corrected FontID
		dx	=	corrected Point Size
		bl	=	corrected pitch value

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	use the fontID to match the typeface available in the printer.
	use the pointsize to select proportional fonts. The = or next smaller
	size gets used. If the size is less than the smallest size, then
	the average width of the string is computed and the string is treatesd
	like a fixed pitch font. For fixed pitch fonts, the next larger pitch
	value is used. This is the next smaller font width. If nothing is
	smaller than the passed font, then the smallest available is used.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	7/92		Initial 2.0 version	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolMapToPrinterFont	proc	far

if	_TEXT_PRINTING
mapFontID	local	word
mapSize		local	word
	uses	ax,si,di
	.enter
if PZ_PCGEOS
	;
	; map FID_BITSTREAM_KANJI_SQUARE_GOTHIC to FID_DTC_URW_SANS and
	; FID_BITSTREAM_KANJI_HON_MINCHO to FID_DTC_URW_ROMAN
	cmp	cx, FID_BITSTREAM_KANJI_SQUARE_GOTHIC
	jne	notSqGothic
	mov	cx, FID_DTC_URW_SANS		; just fall through
notSqGothic:
	cmp	cx, FID_BITSTREAM_KANJI_HON_MINCHO
	jne	notHonMincho
	mov	cx, FID_DTC_URW_ROMAN
notHonMincho:
endif
		;save the incoming parameters. 
	mov	mapSize,dx

		;Match the font IDs.
		;if we cant find a table with the correct font ID then just 
		;use the first font in the device info.
		;cx =  requested FontID
	mov	di,ds:[PI_fontGeometries]	;load the index for the start
						;of the font geometries table.	
fontIDLoop:
	cmp	cx,ds:[di].[FG_fontID]		;see if the fontID matches.
	je	haveFontID			;if so, we have the font
	add	di,size FontGeometry		;point at the next id field
	cmp	{word} ds:[di],FID_INVALID	;at end of tables?
	jne	fontIDLoop			;if not, try next font
	mov	di,ds:[PI_fontGeometries]	;load the index for default
	mov	cx,ds:[di].[FG_fontID]
		;di now has the offset to the first geometry structure we want.

		;Have font ID, need to match point size.
		;cx = corrected FontID
		;dx = requested size from entry, above
		;di = offset of first of this fonts fontGeometry structures.
haveFontID:
	mov	mapFontID,cx			;save the corrected ID.
		;run through the point sizes avail, to obtain the pitch table.

	mov	si,di				;save index for exit of loop.
fontSizeLoop:
	cmp	dx,ds:[di].[FG_pointSize]	;check this pointsize.
	jb	havePreviousFontSize			;if 
	je	haveExactFontSize			;if 
	mov	si,di				;update the previous index.
	add	di,size FontGeometry            ;point at the next structure
	cmp	cx,ds:[di].[FG_fontID]          ;see if the next fontID matches.
	je	fontSizeLoop			;if so, then OK to test next
						;structure's pointsize.
havePreviousFontSize:
	mov	di,si				;get back the index to the 
haveExactFontSize:
	mov	ax,ds:[di].[FG_pointSize]	;save away the corrected point
	mov	mapSize,ax			;size.
	test	bl,bl				;see if proportional.
	jnz	doFixed				;if not, go do fixed pitch
						;matching.
	cmp	dx,ds:[di].[FG_pointSize]	;if the chosen size is still
						;greater than the requested
						;size, then we still need to do
						;some optimizing to fit all the
						;text in. the way that I do
						;this is to convert to a fixed
						;font, and set the char pitch
						;to some fraction of the
						;pointsize.
	jae	loadRegsForExit			;if the requested size is
						;larger or equal to the
						;corrected size, just load the
						;regs for exit.
		;now I need to compute the pitch relative to the pointsize
		;(height). This goes something like this:
		;
		;	pitch(CPI) = (72/pointsize) x 2
	mov	bx,ax			;corrected point size from above
	clr	dx			;clear the extension.
	mov	ax,1440			;get the dividend
	div	bx			;get approx pitch.
	mov	bx,ax
	test	bh,bh			;see if we overflowed
	je	doFixed
	mov	bl,255			;get the finest avail....
		
		;if fixed spacing, match the pitch to the available pitches
doFixed:
	mov	si,ds:[di].[FG_pitchTab]	;load the address of the 
						;pitch table

		;find either the exact value or pick the next highest value
		;for the pitch setting table. The table has to be ordered in 
		;decreasing pitch values with a terminator of 0.
		;ds:si = table pointer
		;bl = value to match. returned the chosen value
		
	cmp	bl,0		;see if prop now.
	jz	havePitch	;if so, were outa here.
	mov	bh,ds:[si]	;save the table's initial value.
				;this gives us an exit value if we are smaller
				;(higher pitch) than the smallest in the tab.
tryNextPitch:
	cmp	bl,ds:[si]	;compare a byte from the table.
	ja	foundPitch
	mov	bh,ds:[si]	;save in the output buffer.
	inc	si		;adjust the pointer.
	jmp	tryNextPitch	;try the next table value.

foundPitch:
	mov	bl,bh		;return the next lowest value.

havePitch:
		;load the output regs with the corrected font info.
		;cx	=>	fontID
		;dx	=>	pointsize
		;bl	=>	pitch.
loadRegsForExit:
	mov	cx,mapFontID
	mov	dx,mapSize
				;bl should be valid from either the pitch
				;routines above, or 0 for proportional.
	.leave
endif	;_TEXT_PRINTING
	ret
SpoolMapToPrinterFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolUpdateTranslationTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the translation table in the PState

CALLED BY:	EXTERNAL
		library call back from print driver set font routine

PASS:		es      =       locked PState address
		dx	=	handle of extended driverInfo resource.
		

RETURN:

DESTROYED:	none

PSEUDO CODE/STRATEGY:
		This routine should be called any time that a change in font
		or a change in the country, resulting in a change in the ISO
		substitutions is requested by the user. It is also called once
		at startup of the print job.
		The way it works is this:
		1) the bottom 128 bytes are assumed to start out as the
			regular ASCII 7 bit table, and are initted as such.
		2) the top 128 bytes are initialized to the code page selected
			by the device specific info resource.
		3) the ISO substitutions are made based on the user's saved
			country parameters.
		4) lastly, the editted extended driver info resource
			sustitutions are made.
		the order of precidence is from beginning(low) to end(high).

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Dave	10/92		Initial 2.0 version	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolUpdateTranslationTable	proc	far

if	_TEXT_PRINTING
	uses    ax,bx,cx,ds,si,di
	.enter

		;this loop inits the low 128 bytes to their offset. ie. no
		;change from the normal ascii table in the low half
	mov	cx,64
	cmp	es:[PS_curFont].FE_symbolSet,PSS_PCGEOS
	jne	initSizeCorrect
	mov	cx,128
initSizeCorrect:
	mov	ax,0100h		;ax init to 0100 or 00,01 stored.
	mov     di, PS_asciiTrans       ; es:di -> trans table
lowInitLoop:
	stosw				; init the table
	add	ax,0202h
	loop	lowInitLoop

		;this part loads the top half of the ASCII set with the 
		;table requested in the device specific info resource.
	mov	bx,es:[PS_curFont].FE_symbolSet
	cmp	bx,PSS_PCGEOS		;see if PCGEOS.
	je	loadEditValues		;if so, just load the editted values.
	mov	cx,64			;128 bytes = 64 words.
	cmp	bx,PSS_ASCII7		;see if we need to stuff all space
					;chars into the high half.
	je	handleASCII7
	mov     bx, cs:[bx].SymbolTableResources ; get the resource han
	call    MemLock ; lock it down
	mov     ds, ax                  ; ds -> table
	clr	si			; init the offset.
	rep	movsw			;fill top half.
	call    MemUnlock               ; release the block
	jmp	makeISOSubs
	
handleASCII7:
	mov	ax,(C_SPACE or (C_SPACE shl 8))
	rep	stosw			;fill top half.

		;this part makes the ISO substitutions into the low 128 bytes
		;really this means that there will be some more pointers to 
		;low 128 bytes in the top half of the PCGEOS set, and some 
		;space substitutions in the low half of the PCGEOS set.
		;(IF there is another country specified)
makeISOSubs:
	cmp	es:PS_jobParams.JP_printerData+PUID_countryCode,PCC_USA
	je	loadEditValues		;if us, no subs.
	mov     bx, dx			; get handle to resource
	call    MemLock ; lock it down
	mov     ds, ax                  ; ds -> resource
	mov     si, size DriverExtendedInfoTable
	mov     si, ds:[si].PDI_subISOTable ; get chunk handle
	mov     si, ds:[si]             ; get pointer to chunk
	cmp	ds:[si],0ffffh		;see if a table exists....
	je	loadEditValuesIn	;if not, go try edit values.
	clr	ax
	mov	ah,es:PS_jobParams.JP_printerData+PUID_countryCode
					;get code.
					;use as index to table of swaps:
					;16words/country x 2bytes/word =32
	mov	cl,3			;really shift left 5 from al
	shr	ax,cl
	add	si,ax			;add offset for this country into index
	clr	bx			;init the trans table offset.
subISOLoop:
	lodsw				;pick up the pair to switch
	cmp	ax,0			;see if at end of table.
	je	loadEditValuesIn	;if so, done here.
	mov	bl,ah			;get offset to load the space to.
	mov	es:[bx].PS_asciiTrans,C_SPACE ;stuff space char there.
	mov	bl,al			;get offset to load char to.
	mov	es:[bx].PS_asciiTrans,ah ;set the translation byte there.
	jmp	subISOLoop

		;this part loads the edited ASCII values from the extended 
		;info resource, if there are any. since this happens last
		;care must be taken to not screw up any user selected country
		;info (ie. the ISO substitutions)
loadEditValues:
	mov     bx, dx			; get handle to resource
	call    MemLock ; lock it down
	mov     ds, ax                  ; ds -> resource
loadEditValuesIn:
	mov     si, size DriverExtendedInfoTable
	mov     si, ds:[si].PDI_asciiTransChars ; get chunk handle
	mov     si, ds:[si]             ; get pointer to chunk
	ChunkSizePtr ds, si, cx         ; cx = chunk size
	shr     cx, 1                   ; see how many pairs
	shr     cx, 1
	jcxz    doneTransChars
transCharLoop:
	lodsw                           ; get next translation pair
	mov     di, ax                  ; set up dest index
	and     di, 0xff
	mov     es:[PS_asciiTrans][di], ah ; store translation byte
	add     si, 2                   ; bump past delimiter
	loop    transCharLoop
doneTransChars:
	mov     bx, dx			; get handle to resource
	call    MemUnlock                       ; free the resource
	.leave
endif	;_TEXT_PRINTING

	ret
SpoolUpdateTranslationTable	endp

if	_TEXT_PRINTING
SymbolTableResources     label   word
                word    0                       ; no entry for 7-bit ascii
                word    handle IBM437Table      ; handle for IBM Code Page 437
						;also Epson 8 bit character set.
                word    handle IBM850Table      ; handle for IBM Code Page 850
                word    handle IBM860Table      ; handle for IBM Code Page 860
                word    handle IBM863Table      ; handle for IBM Code Page 863
                word    handle IBM865Table      ; handle for IBM Code Page 865
                word    handle RomanTable       ; handle for HP Roman table
                word    handle WindowsTable     ; handle for Windows table
                word    handle VenturaTable     ; handle for HP Ventura table
                word    handle LatinTable       ; handle for HP Latin table
                word    0                       ; no entry for PC-GEOS encode
endif	;_TEXT_PRINTING

SpoolMisc	ends
