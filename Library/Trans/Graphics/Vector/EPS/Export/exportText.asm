COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript Translation Library
FILE:		exportText.asm

AUTHOR:		Jim DeFrisco, 21 March 1991

ROUTINES:
	Name			Description
	----			-----------
	EmitTextField		generate code for GrDrawTextField

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/21/91		Initial revision


DESCRIPTION:
	This file contains all the text-related output code
		

	$Id: exportText.asm,v 1.1 97/04/07 11:25:42 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExportText	segment	resource

; GetPathOrDrawGState
; The text code is called from either the normal text drawing part of the
; translation library, or the path creation part.  This macro fetches the right
; GState handle to use.

GetPathOrDrawGState	macro	reg
	local	done
	mov	reg, tgs.TGS_pathGState
	tst	reg
	jnz	done
	mov	reg, tgs.TGS_gstate
done:
endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate code for a GrDrawTextField element

CALLED BY:	INTERNAL
		TranslateGString

PASS:		si		- handle to gstring
		bx		- gstring opcode (in kind of a twisted way)
		tgs		- inherited local stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
                For GrDrawTextField elements, the text is drawn as a group
		of consecutive style runs (I call this a styles group).  A
		styles group can represent an entire GrDrawTextField element,
		or just a subset.  The difference is that the styles group
		does not have any embedded graphics.

		Each style group is passed on the stack as an array of
		style runs.  Each style run is an array of other info.  The
		structure of a style run is:

	[(string) {attr-info} <track kern> <style matrix> <font> <size>]

		where:
			(string)        - the text string to draw, in parens
			{attr-info}     - commands to set attributes, in curly
					  braces
			<track kern>    - track kerning for style run
			<style-matrix>  - transformation matrix to effect the
					  current style
			<font>          - a valid PostScript font name
			<size>          - the current pointsize

		 These style runs are then strung together on the stack:

		 [ [style-run] [style-run] ... ]

		Finally, the styles group is followed by the space padding,
		the string width (under GEOS) and the position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitTextField	proc	far
		uses	ax, bx, cx, si, di, dx, es
tgs		local	TGSLocals
		.enter	inherit

		; we need to output all that stuff to start an object, output
		; the transform, etc, etc.

		call	EmitStartObject
		call	EmitTransform
		call	ExtractElement

		GetPathOrDrawGState di		; get right gstate handle
		mov	tgs.TGS_locmot.WWF_int, 0 ; init local motion
		mov	tgs.TGS_locmot.WWF_frac, 0 ; init local motion

		; get the size of the string

		mov	bx, si			; ds:bx -> element
		mov	cx, ds:[bx].ODTF_saved.GDFS_nChars ; cx = stringlen

		; set up ds:si to point at style runs

		mov	si, size OpDrawTextField ; bx.si -> 1st style run
		
		; alright, we're ready to go.  The following pointers are set:
		; ds:bx    -> pointer to a OpDrawTextField structure
		; ds:bx.si -> pointer to first TFStyleRun structure
		; cx	   -  # characters in the line

		; before we loop through the style runs, we need to init some
		; variables.  We're keeping track of the total width of the
		; field, so init the variable

		mov	tgs.TGS_width.WWF_frac, 0	; zero total field wid
		mov	tgs.TGS_width.WWF_int, 0
		mov	ax, ds:[bx].ODTF_saved.GDFS_drawPos.PWBF_x.WBF_int
		mov	tgs.TGS_gpos.WWF_int, ax
		mov	ah, ds:[bx].ODTF_saved.GDFS_drawPos.PWBF_x.WBF_frac
		clr	al
		mov	tgs.TGS_gpos.WWF_frac, ax

		; loop through the style runs, getting out the attributes

		call	HandleStyleGroup	; handle next group of runs

		; all done

		mov	bx, tgs.TGS_chunk.handle ; unlock block
		call	MemUnlock		; release string block
		.leave
		ret
EmitTextField	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleStyleGroup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a series of text-only style runs of a GrDrawTextField 
		element

CALLED BY:	INTERNAL
		EmitTextField

PASS:		ds:bx	 - pointer to element
		ds:bx+si - pointer to TFStyleRun structure
		cx	 - #chars to draw in group 
		di	 - gstate handle

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		each style group is output in the following format

		[ array of style runs ] <spacepad> <stringwidth> x y DSG

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HandleStyleGroup proc	near
		uses	es, di
tgs		local	TGSLocals
		.enter	inherit

		; now we need to emit the opening bracket for the array of
		; style run arrays.  

		push	ds, bx, cx, dx
		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax			; ds -> PSCode resource
		mov	bx, tgs.TGS_stream
		EmitPS	emitOpenBracket
		mov	bx, handle PSCode
		call	MemUnlock
		pop	ds, bx, cx, dx
		
		; as we output each style run, we want to keep track of 
		; the total length, so zero it out right now.

		mov	tgs.TGS_gwidth.WWF_frac, 0
		mov	tgs.TGS_gwidth.WWF_int, 0

		; while there are still characters left, keep outputting the
		; style run arrays.
styleRunLoop:
		call	HandleStyleRun
		jc	done			; done if hit embedded graphic
		tst	cx			; ...might be done
		jnz	styleRunLoop		; ...but maybe not

		; all that is left is the closing bracket, the invocation of
		; our PostScript procedure, and the EndObject stuff
done:
		push	si, cx			; save count to return
		push	ds, bx
		movwbf	diah, ds:[bx].ODTF_saved.GDFS_drawPos.PWBF_y
		addwbf	diah, ds:[bx].ODTF_saved.GDFS_baseline
		rndwbf	diah
		push	di
		push	tgs.TGS_gpos.WWF_frac
		push	tgs.TGS_gpos.WWF_int

		mov	ax, tgs.TGS_gwidth.WWF_frac ; add with into current pos
		add	tgs.TGS_gpos.WWF_frac, ax
		mov	ax, tgs.TGS_gwidth.WWF_int
		adc	tgs.TGS_gpos.WWF_int, ax

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> string buffer
		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax			; ds -> PSCode resource
		mov	si, offset emitCloseBracket
		mov	cx, length emitCloseBracket
		rep	movsb

		; write out space padding

		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrGetTextSpacePad	; dxbl = padding
		pop	di
		mov	ah, bl
		mov	bx, dx
		clr	al
		 
		call	WWFixedToAscii		; convert to ascii
		mov	al, ' '			; space delimit things
		stosb

		; write out group width

		mov	bx, tgs.TGS_gwidth.WWF_int ; write out width
		mov	ax, tgs.TGS_gwidth.WWF_frac
		call	WWFixedToAscii		; convert to ascii
		mov	al, ' '
		stosb

		; write out x pos

		pop	bx			; restore x pos
		pop	ax
		tst	tgs.TGS_xfactor		; see if OK
		jnz	xOK
		clr	ax
		clr	bx
xOK:
		call	WWFixedToAscii
		mov	al, ' '
		stosb

		; write out y pos

		pop	bx
		clr	ax
		tst	tgs.TGS_yfactor		; see if OK
		jnz	yOK
		clr	bx
yOK:
		call	WWFixedToAscii		; write Y POS
		mov	al, ' '
		stosb

		mov	si, offset emitDSG
		mov	cx, length emitDSG
		tst	tgs.TGS_pathGState	; if a path, use diff opcode
		jz	copyOp
		mov	si, offset emitPSG
		mov	cx, length emitPSG
copyOp:
		rep	movsb
		call	EmitBuffer		; write it all out

		mov	bx, handle PSCode
		call	MemUnlock
		pop	ds, bx
		
		call	EmitEndObject		; last part...
		pop	si, cx			; restore remaining char count

		.leave
		ret
HandleStyleGroup endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleStyleRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a single style run of a GrDrawTextField element

CALLED BY:	INTERNAL
		HandleStyleGroup

PASS:		ds:bx	 - pointer to element
		ds:bx+si - pointer to TFStyleRun structure
		cx	 - #chars still left to draw (before this run)
		di	 - gstate handle
		es	 - points to locked options block

RETURN:		ds:bx.si - pointer to next StyleRun
		cx	 - #chars still left to draw (after this run)

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		The structure of a Style run (as a PostScript data element)
		is as follows:

		[(this is the string) {attr setting} <track kern> 
		 <style matrix> <font> <point size> ]

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HandleStyleRun	 proc	near
		uses	es, di
tgs		local	TGSLocals
		.enter	inherit

		; setup pointer to text.

		mov	dx, si			; setup dx -> string
		add	dx, bx			
		add	dx, size TFStyleRun	; ds:dx -> characters

		; now check for hyphen

		cmp	cx, ds:[bx][si].TFSR_count ; if total remain = this run
		jne	dealtWithHyphen
		call	CheckAutoHyphen		   ; add hyphen if needed
		mov	ds:[bx][si].TFSR_count, cx ; save new count
dealtWithHyphen:
		push	cx			; save #chars left (total)
		mov	cx, ds:[bx][si].TFSR_count ; get character count

		; need to handle some Greek characters differently, since they
		; don't appear in the StandardEncoding vector for PostScript.
		; Hrmph.  

		call	ConquerTheGreeks	; Yeah, it's late....
		jnc	doTheWork		; no greeks
		mov	dx, cx			; set up #chars here
		jmp	doneRun

		; we want to skip over single tab characters.  Check for 
		; a one-character run, then check to see if is a tab.
doTheWork:
		cmp	cx, 1			; one character ?
		jne	addressStyleRun		;  no, continue
		push	si			; save a reg
		mov	si, dx
		cmp	{byte} ds:[si], C_TAB	; is it a tab ?
		pop	si
		jne	addressStyleRun		;  no, continue
		mov	dx, 1			; #chars in this run
		jmp	doneRun			; exit early

		; set all the attributes in the GState for this run
addressStyleRun:
		add	si, bx			; ds:si -> TFStyleRun
		add	si, TFSR_attr		; point to attributes

		; we have to handle the space padding separately, since
		; it gets hosed by the text field element storing routine
		; in the kernel.  sigh.

		push	di, dx, bx
		GetPathOrDrawGState di		; get right handle
		call	GrGetTextSpacePad	; get space padding
		movwbf	ds:[si].TA_spacePad, dxbl
		pop	di, dx, bx

		call	GrSetTextAttr		; set the text attributes
		sub	si, TFSR_attr
		sub	si, bx			; things back to normal

		; calculate the width of this run, and add it into the
		; running total for the whole group

		push	si, dx			; save the offset
		mov	si, dx			; ds:si -> string
		call	GrTextWidthWBFixed	; figure out how wide
		add	tgs.TGS_gwidth.WWF_frac.high, ah ; update group width
		adc	tgs.TGS_gwidth.WWF_int, dx
		add	tgs.TGS_width.WWF_frac.high, ah	 ; 
		adc	tgs.TGS_width.WWF_int, dx
		pop	si, dx			; restore the offset

		; send out the string and attributes

		push	cx			; save #chars in this run

		; before we do it, check to make sure that we don't begin with
		; a tab.  If we do, lop it off

		push	si
		mov	si, dx
		cmp	{byte} ds:[si], C_TAB	; is it a tab ?
		jne	tabHandled
		inc	dx			; skip over the tab
		dec	cx
tabHandled:
		pop	si
		call	EmitTextString		; emit "[(string},NL"
		call	EmitTextAttr		; emit "{ pscode},NL"
		push	es:[PSEO_fonts]		; save font list enum

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> string buffer
		mov	ch, ds:[bx][si].TFSR_attr.TA_trackKern.low
		clr	cl
		mov	al, ds:[bx][si].TFSR_attr.TA_trackKern.high
		cbw
		mov	dx, ax
		push	bx
		mov	ah, ds:[bx][si].TFSR_attr.TA_size.WBF_frac
		mov	bx, ds:[bx][si].TFSR_attr.TA_size.WBF_int ; get size
		clr	al
		call	GrMulWWFixed		; bx.ax = track kern in pts
		mov	bx, dx
		mov	ax, cx
		call	WWFixedToAscii
		mov	al, ' '			; put in  the separator
		stosb
		pop	bx

		pop	ax			; restore font list enum
		push	bx
		mov	bx, ax
		call	EmitFont		; write style matrix and font
		pop	bx

		push	bx
		mov	ah, ds:[bx][si].TFSR_attr.TA_size.WBF_frac
		mov	bx, ds:[bx][si].TFSR_attr.TA_size.WBF_int ; get p size
		clr	al
		call	WWFixedToAscii

		mov	al, tgs.TGS_newstyle	; get leftover style bits
		call	EmitStyleMatrix

		push	ds, si
		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitCloseBracket
		mov	cx, length emitCloseBracket
		rep	movsb
		mov	si, offset emitCRLF
		mov	cx, length emitCRLF
		rep	movsb
		call	EmitBuffer
		pop	ds, si			; restore style run pointer

		mov	bx, handle PSCode
		call	MemUnlock
		pop	bx			; ds:bx <- base of element

		pop	dx			; restore #chars in this run
doneRun:
		pop	cx			; restore #characters total
		sub	cx, dx			; calc #chars left
		add	si, size TFStyleRun	; bump to next style run
		add	si, dx			;  bump past chars too
		clc				; not an embedded graphic

		.leave
		ret

HandleStyleRun	 endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConquerTheGreeks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since the standard character set in PS doesn't have these
		greek chars that are in our standard set, we add a few special
		style runs to take care of them.

CALLED BY:	INTERNAL
		HandleStyleRun

PASS:		ds:bx	 - pointer to element
		ds:bx+si - pointer to TFStyleRun structure
		ds:dx    - pointer to text to draw
		cx	 - #chars in this style run
		di	 - gstate handle
		es	 - points to locked options block

RETURN:		carry	- set if we've finished with the style run
		everything else intact

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		scan the string for suspicious chars.  If any found, kill 
		them.  No, actually, just take them prisoner.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; returns carry if char in al is a greek one, assumes es == cs, trashes di
FindAGreek	macro
		local	done
		local	maybeLast
		mov	di, offset greekCharTab ; reset pointer
		push	cx			; save count
		mov	cx, LEN_GREEK_TAB	; set up 
		repne	scasb			; look for character in table
		stc				; assume found it
		jcxz	maybeLast
		jmp	done			; found something..

		; we might have something.  Check to see if we're on the last
maybeLast:
		je	done			; nothing, continue
		clc
done:
		pop	cx			; restore count
endm

;--------------------------------------------------------------------

ConquerTheGreeks proc	near
		uses	ax, cx, dx, si, es, di
tgs		local	TGSLocals
		.enter 	inherit

		; for now, don't deal with this routine.

		clc
		jnc	done

		; if this style run is in Symbol font, then bail

		mov	ax, ds:[bx][si].TFSR_attr.TA_font
		and	ax, 0x0fff	; isolate face ID
		cmp	ax, (FID_DTC_URW_SYMBOLPS and 0x0fff)
		je	doneOK

		; if this is a font that we don't have to re-encode (either
		; because it's a dingbats type font or because we're going to
		; download it) then just bail.

		mov	ax, ds:[bx][si].TFSR_attr.TA_font ; get the font id
		push	si, dx, cx
		mov	dl, ds:[bx][si].TFSR_attr.TA_styleSet
		mov	si, tgs.TGS_pageFonts.chunk	; get chunk handle
		mov	si, ds:[si]			; deref chunk
		mov	cx, ds:[si].PF_count		; get #fonts in array
		add	si, offset PF_first + size PageFont ; go to first font
searchLoop:
		cmp	ax, ds:[si].PF_id		; see if we have this
		jne	nextEntry
		cmp	dl, ds:[si].PF_style		; check style too
		jne	nextEntry		
		test	ds:[si].PF_flags, mask PFF_REENCODE ; bail if not reenc
		jnz	tryGreeks			; look for greeks
		pop	si, dx, cx
		jmp	doneOK
nextEntry:
		add	si, size PageFont
		loop	searchLoop		


		; OK, we're gonna search the string for Greek dudes.
tryGreeks:
		pop	si, dx, cx

		mov	tgs.TGS_bmWidth, ax	; save the font. 
		segmov	es, cs, di		; set es:di -> greek char table
		mov	di, offset greekCharTab

		; scan the string.  if none found, leave.

		push	si, cx
		mov	si, dx
scanLoop:
		lodsb			; get character
		cmp	al, C_DAGGER	; below this is OK
		jbe	keepLooking
		cmp	al, C_LY_DIERESIS ; from here on OK
		jb	dangerZone
keepLooking:
		loop	scanLoop
		pop	si, cx		; we made it OK, exit
doneOK:
		clc			; signal we're not finished
done:
		.leave
		ret

;----------------------------------------------------------------

		; in the danger zone.  Do more checking
		; there are 18 characters that we're looking for.
dangerZone:
		FindAGreek
		jnc	keepLooking		; nothing, continue
		
;----------------------------------------------------------------

		; we found something greek.  now the real fun begins
		; basically, we want to loop through each sub-style run,
		; grouping together all verbotten characters.  Til we're
		; done with the whole style run.  But you knew that.

		mov	ax, si
		dec	ax
		pop	si, cx			; restore original values

		cmp	ax, dx			; is it the first letter ?
		je	DoGreek			; first char is greek...

		; next style run should be Roman
		; cx = #chars left in overall style run
		; ds:dx -> next character
		; ds:bx.si -> TFStyleRun struct
DoRoman:
		mov	ax, tgs.TGS_bmWidth	; we stored original fontID here
		mov	ds:[bx][si].TFSR_attr.TA_font, ax ; restore font
		push	bx			; save element pointer
		mov	bx, dx			; ds:bx -> string
getNextRomanChar:
		mov	al, ds:[bx]		; get next char
		FindAGreek
		jc	doneWithRomanRun
		inc	bx			; on to check next character
		mov	ax, bx			; see if we're done
		sub	ax, dx
		cmp	ax, cx
		jb	getNextRomanChar
doneWithRomanRun:
		mov	ax, bx			; calc #chars in this run
		sub	ax, dx			; ax = #chars in this run
		pop	bx			; restore element pointer
		mov	ds:[bx][si].TFSR_count, ax ; store fake count
		mov	es, tgs.TGS_options	; grab options block addr
		GetPathOrDrawGState di		; get right handle
		call	HandleStyleRun
		jcxz	doneRuns
		sub	si, size TFStyleRun	; back it up
		segmov	es, cs, di
		
		; next style run should be Greek
		; cx = #chars left in overall style run
		; ds:dx -> next character
		; ds:bx.si -> TFStyleRun struct
DoGreek:
		mov	ds:[bx][si].TFSR_attr.TA_font, FID_PS_SYMBOL ; set font
		push	bx			; save element pointer
		mov	bx, dx			; ds:bx -> string
getNextGreekChar:
		mov	al, ds:[bx]		; get next char
		FindAGreek
		jnc	doneWithGreekRun
		sub	di, (offset greekCharTab) + 1
		mov	al, cs:greekMapTab[di]	; get Symbol font character
		mov	ds:[bx], al		; store new character code
		inc	bx			; on to check next character
		mov	ax, bx			; see if we're done
		sub	ax, dx
		cmp	ax, cx
		jb	getNextGreekChar
doneWithGreekRun:
		mov	ax, bx			; calc #chars in this run
		sub	ax, dx			; ax = #chars in this run
		pop	bx			; restore element pointer
		mov	ds:[bx][si].TFSR_count, ax ; store fake count
		mov	es, tgs.TGS_options	; grab options block addr
		GetPathOrDrawGState di		; get right handle
		call	HandleStyleRun
		jcxz	doneRuns
		sub	si, size TFStyleRun	; back it up
		segmov	es, cs, di
		jmp	DoRoman
doneRuns:
		stc
		jmp	done

ConquerTheGreeks endp

		; These are the GEOS characters that do not appear in the
		; standard PostScript font set, but do appear in the Symbol
		; font.
greekCharTab	label	char
		char	C_DEGREE, C_NOTEQUAL, C_INFINITY, C_PLUSMINUS
		char	C_LESSEQUAL, C_GREATEREQUAL, C_L_MU, C_L_DELTA
		char	C_U_SIGMA, C_U_PI, C_L_PI, C_INTEGRAL
		char	C_U_OMEGA, C_ROOT, C_APPROX_EQUAL, C_U_DELTA
		char	C_DIVISION, C_DIAMONDBULLET

LEN_GREEK_TAB	=	18

		; these are the character codes for the above GEOS characters
		; in the standard Symbol font encoding under PostScript
greekMapTab	label	char
		char	0xb0, 0xb9, 0xa5, 0xb1, 0xa3, 0xb3, 0x6d, 0x64
		char	0x53, 0x50, 0x70, 0xf2, 0x57, 0xd6, 0xbb, 0x44
		char	0xb8, 0xe0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTextString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a style run string 

CALLED BY:	GLOBAL

PASS:		ds:dx	- pointer to character string
		cx	- #characters in style run

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		This code extracts the characters from the text field, and
		emits a "[(this is the string) " sequence to the stream.  It
		may be changed in the future to detect characters from the
		symbol font and emit separate style runs for those characters.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitTextString	proc	near
		uses	es, dx, si, di, cx
tgs		local	TGSLocals
		.enter	inherit

		; set up es:di -> buffer

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> string buffer
		mov	al, '['
		stosb
		mov	al, '('
		stosb
		push	si
		mov	si, dx
		lea	dx, tgs.TGS_buffer	; set dx = last buffer pos
		add	dx, (size TGS_buffer) - 8
lastLoop:
		lodsb
		call	CheckSpecialChars
		jc	charDone
		stosb				; copy string to buffer
charDone:
		cmp	di, dx			; if past, write out buffer
		ja	bufferFull
nextChar:
		loop	lastLoop

		mov	al, ')'
		mov	ah, ' '
		stosw
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		pop	si

		.leave
		ret

		; string is too big for one buffer-full, split it up
bufferFull:
		call	EmitBuffer		; write out the buffer
		lea	di, tgs.TGS_buffer	; reset pointer
		jmp	nextChar
EmitTextString	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSpecialChars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a character above 0x7f, or some other special chars

CALLED BY:	INTERNAL
		EmitTextString

PASS:		al	- character code
		es:di	- where to write it
		cx	- characters left in style run

RETURN:		al	- last char of octal digit
		carry	- clear if we need to store what is in al

DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		chage code to octal and write it out like

		 \ooo


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckSpecialChars proc near
		uses	bx, cx
		.enter

		tst	al		; see if >128
		js	upper128
		cmp	al, C_LEFT_PAREN ; check for other chars
		je	precedeBackslash
		cmp	al, C_RIGHT_PAREN
		je	precedeBackslash
		cmp	al, C_BACKSLASH 
		je	precedeBackslash
		cmp	al, C_NULL_WIDTH 
		je	omitChar
		cmp	al, C_OPTHYPHEN 
		jne	okDone
		cmp	cx, 1
		jne	omitChar
		mov	al, C_HYPHEN
okDone:
		clc
done:
		.leave
		ret

precedeBackslash:
		mov	{byte} es:[di], C_BACKSLASH
		inc	di
		jmp	okDone
upper128:
		mov	{byte} es:[di], C_BACKSLASH	; write out backslash
		inc	di
		clr	ah
		mov	bx, ax		; save it
		mov	cl, 6		; shift amount for first letter
		shr	bx, cl		; get high two bits
		mov	cl, cs:octalDigits[bx]	; get this digit
		mov	es:[di], cl
		inc	di
		mov	bx, ax
		mov	cl, 3
		shr	bx, cl
		and	bx, 7
		mov	cl, cs:octalDigits[bx]
		mov	es:[di], cl
		inc	di
		mov	bx, ax
		and	bx, 7
		mov	al, cs:octalDigits[bx]
		jmp	okDone

		; get rid of the character
omitChar:
		stc			; signal no store
		jmp	done
CheckSpecialChars endp

octalDigits	label	char
		char	"01234567"

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTextAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get/write the current text attributes

CALLED BY:	INTERNAL
		HandleStyleRun

PASS:		see HandleStyleRun, above
		ds:dx		- pointer to string
		cx		- #characters

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		puts out a set of postscript commands to set some attributes,
		all in a set of curly braces.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitTextAttr	proc	near
		uses	es, dx, si, di, cx, ds, ax, bx
tgs		local	TGSLocals
		.enter	inherit

		; set up es:di -> buffer

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> string buffer
		mov	al, '{'
		stosb

		; send out the color

		call	EmitTextColor

		; do underline and strikethru

		call	EmitUnderlineStrikethru

		; do any local motions for sub/superscript if necc.

		call	EmitLocalMotion

		; done with attributes, close brace

		mov	al, '}'
		stosb
		mov	al, C_CR
		mov	ah, C_LF
		stosw
		call	EmitBuffer

		.leave
		
		ret
EmitTextAttr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitLocalMotion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the amount of up/down we need to shift for 
		subscript/superscript

CALLED BY:	GLOBAL

PASS:		es:di	- where to write PostScript code

RETURN:		es:di	- adjusted to point after anything written

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		get font metrics info, do a few math operations

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitLocalMotion	proc	near
		uses	cx, dx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		; need to do a little local motion to account for super and
		; subscript.  TGS_newstyle has the style bits left over from
		; the last style run, so we can use that to determine if the
		; previous style run was moved (since we have to move it back).
		; Then we look at the new style bits and apply another local
		; motion to deal with possible super/subscript.  Actually, we
		; combine these motions and use one "rmoveto".  If the current
		; style is sub or superscript, then we have to double the
		; movement.

		mov	dx, tgs.TGS_locmot.WWF_int ; get prev local motion
		mov	cx, tgs.TGS_locmot.WWF_frac
		mov	tgs.TGS_locmot.WWF_int, 0
		mov	tgs.TGS_locmot.WWF_frac, 0
		neg	cx 			; negate, since we're fixing
		not	dx			;  the previous motion
		cmc
		adc	dx, 0
		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrGetTextStyle
		pop	di
		and	al, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
		pushf				; save zero flag status
		jz	setMotion		; set it up
		push	cx, dx, si, di
		mov	si, GFMI_HEIGHT			; we want the height
		GetPathOrDrawGState di		; get right handle
		call	GrFontMetrics
		test	al, mask TS_SUPERSCRIPT		; check which
		mov	al, 0				; dx.ax = height
		mov	cx, ax				; dx.cx = height
		mov	bx, SUPERSCRIPT_OFFSET_INT	; assume superscript
		mov	ax, SUPERSCRIPT_OFFSET_FRAC
		jnz	applyTrans			;  no, do subscript
		mov	bx, SUBSCRIPT_OFFSET_INT
		mov	ax, SUBSCRIPT_OFFSET_FRAC
applyTrans:
		call	GrMulWWFixed			; dx.cx = trans amt
		mov	bx, dx				; bx.ax = y trans
		mov	ax, cx
		pop	cx, dx, si, di
		mov	tgs.TGS_locmot.WWF_int, bx ; save for next style run
		mov	tgs.TGS_locmot.WWF_frac, ax
		add	cx, ax			; add in to previous motion
		adc	dx, bx

		; have the motion amount.  Write it out if non-zero.
setMotion:
		popf				; restore zero flag, to see if
		jz	haveAmount		;  we need to mul * 2
		mov	bx, SCRIPT_FACTOR_INT	; div by appropriate amount
		mov	ax, SCRIPT_FACTOR_FRAC	; 
		call	GrSDivWWFixed		; divide by fraction...
haveAmount:
		mov	ax, dx			; check for zero
		or	ax, cx			
		jz	done

		; write out "0 <motion> rmoveto"

		mov	al, ' '			; put in space separator
		stosb				
		mov	ax, cx
		mov	bx, dx			; copy number down to bx.ax
		call	WWFixedToAscii		; convert y motion to ascii

		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitSSM	; invoke local motion proc
		mov	cx, length emitSSM
		rep	movsb
		call	MemUnlock
done:
		.leave
		ret
EmitLocalMotion	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTextColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out text color

CALLED BY:	INTERNAL
		EmitTextAttr, EmitTabLeader

PASS:		tgs	- local stack frame
		es:di	- buffer where to write it

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just get/set the color

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitTextColor	proc	near
		uses	ax, cx, dx, bx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		; send out the color

		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrGetTextColor
		pop	di

		; RGB values need to be tweaked to get them to match what is
		; on-screen...

		call	MapRGBForPrinter

		; save G and B for now

		mov	dx, bx
		mov	bl, al			; set up as int
		clr	bh
		call	UWordToAscii		; write R
		mov	al, ' '
		stosb
		mov	bl, dl
		clr	bh
		call	UWordToAscii		; write G
		mov	al, ' '
		stosb
		mov	bl, dh
		clr	bh
		call	UWordToAscii		; write B

		mov	bx, handle PSCode	; lock PSCode resource
		call	MemLock
		mov	ds, ax
		mov	si, offset emitSC
		mov	cx, length emitSC
		rep	movsb
		call	MemUnlock

		.leave
		ret
EmitTextColor	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitUnderlineStrikethru
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the amount of up/down we need to shift for 
		subscript/superscript

CALLED BY:	GLOBAL

PASS:		es:di	- where to write PostScript code
		ds:dx	- pointer to string 
		cx	- #characters

RETURN:		es:di	- adjusted to point after anything written

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		get font metrics info, do a few math operations

		for underline and strikethru, we need the line thickness,
		the line position (y offset), and the length.

		underline pos offset is gotten from GrFontMetrics
		strikethru pos is 3/5ths the way up from the baseline to
		the xheight (mean height).

		note: there is a problem if a local motion was done on the last
		style run.  that's why we grab the previous local motion amount
		and adjust our position based on that.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

STRIKETHRU_FACTOR_FRAC	equ	0x3333
STRIKETHRU_FACTOR_INT	equ	0xffff

EmitUnderlineStrikethru	proc	near
		uses	cx, dx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		push	di			; get current style bits
		mov	di, tgs.TGS_gstate

		; calc the style run length

		mov	si, dx			; ds:si -> string
		call	GrTextWidthWBFixed	; dx.ah - width of style run
		clr	al
		mov	tgs.TGS_runlen.WWF_frac, ax
		mov	tgs.TGS_runlen.WWF_int, dx

		; grab the current style bits

		call	GrGetTextStyle
		pop	di

		test	al, mask TS_UNDERLINE 
		LONG jz	checkStrikeThru
		push	ax

		; NOTE: since in GEOS the baseline position is messed with
		; in superscript mode, we need to cancel that mode to get the
		; true baseline position for the font.  Hopefully there will
		; be a better way to do this soon, but for new we need to 
		; push the GState, reset the superscript bit, then read the
		; baseline information...

		test	al, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
		jz	notSuperOrSub
		push	di			; save offset
		mov	di, tgs.TGS_gstate
		call	GrSaveState
		mov	ah, al
		and	ah, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
		and	al, not (mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT)
		call	GrSetTextStyle
		pop	di
notSuperOrSub:
		push	di
		mov	di, tgs.TGS_gstate
		mov	si, GFMI_UNDER_POS
		call	GrFontMetrics
		mov	bx, dx			
		mov	cx, ax			; bx.cx = underline pos
		clr	cl
		mov	si, GFMI_BASELINE
		call	GrFontMetrics		; dx.ah = baseline pos
		clr	al
		sub	cx, ax			; underline offset - baseline
		sbb	bx, dx
		mov	si, GFMI_UNDER_THICKNESS ; plus 1/2 line thickness
		call	GrFontMetrics
		clr	al
		push	bx, cx			; save net result
		mov	cx, ax			; dx.cx = thickness
		dec	dx
		jns	divUnderThick
		clr	dx
divUnderThick:
		mov	bx, 2
		clr	ax
		call	GrSDivWWFixed		; calc thickness/2
		pop	bx, ax			; restore result
		add	cx, ax
		adc	dx, bx
		mov	bx, tgs.TGS_locmot.WWF_int ; get prev local motion
		mov	ax, tgs.TGS_locmot.WWF_frac
		neg	ax
		not	bx
		cmc
		adc	bx, 0
		add	cx, ax
		adc	dx, bx
		pop	di
		call	EmitStyleLine
		pop	ax			; restore style byts

		; this is part two of the screwyness that we initiated above.
		; this code just restores the gstate to what it was.

		test	al, mask TS_SUPERSCRIPT or mask TS_SUBSCRIPT
		jz	checkStrikeThru
		push	di			; save offset
		mov	di, tgs.TGS_gstate
		call	GrRestoreState
		pop	di

checkStrikeThru:
		test	al, mask TS_STRIKE_THRU 
		jz	done

		push	di
		mov	di, tgs.TGS_gstate
		mov	si, GFMI_MEAN
		call	GrFontMetrics
		mov	cx, ax
		clr	cl
		mov	ax, STRIKETHRU_FACTOR_FRAC
		mov	bx, STRIKETHRU_FACTOR_INT
		call	GrMulWWFixed
		push	dx, cx
		mov	si, GFMI_UNDER_THICKNESS ; plus 1/2 line thickness
		call	GrFontMetrics
		clr	al
		mov	cx, ax			; dx.cx = thickness
		dec	dx
		jns	divStrikeThick
		clr	dx
divStrikeThick:
		mov	bx, 2
		clr	ax
		call	GrSDivWWFixed		; calc thickness/2
		pop	bx, ax			; restore result
		pop	di
		add	cx, ax
		adc	dx, bx
		mov	bx, tgs.TGS_locmot.WWF_int ; get prev local motion
		mov	ax, tgs.TGS_locmot.WWF_frac
		neg	ax
		not	bx
		cmc
		adc	bx, 0
		add	cx, ax
		adc	dx, bx
		call	EmitStyleLine
done:
		.leave
		ret
EmitUnderlineStrikethru	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitStyleLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		dx.cx	- offset to draw line

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		grabs the current underline width and calculate the length of
		the current style run and uses the passed offset.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	05/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitStyleLine	proc	near
		uses	cx, dx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		; save y offset for later...

		push	cx, dx
		mov	al, ' '				; prepend space char
		stosb

		; first we need to write out the line length.  This is the
		; length of this style run...it was calc'd up above and stored
		; in tgs...

		mov	bx, tgs.TGS_runlen.WWF_int	; get run length
		mov	ax, tgs.TGS_runlen.WWF_frac
		call	WWFixedToAscii			; write out the length
		mov	al, ' '				; append space char
		stosb

		pop	ax, bx

		call	WWFixedToAscii			; write out the offset
		mov	al, ' '				; append space char
		stosb

		; call FontMetrics routine to get the thickness

		push	di
		mov	di, tgs.TGS_gstate
		mov	si, GFMI_UNDER_THICKNESS	; get line thickness
		call	GrFontMetrics
		pop	di
		clr	al
		mov	bx, dx
		dec	bx				; fudge it to work
		jns	writeThickness
		clr	bx
writeThickness:
		call	WWFixedToAscii			; write out thickness

		; write out DrawUnderLine proc name

		mov	bx, handle PSCode		; lock down resource
		call	MemLock
		mov	ds, ax				; ds -> resource
		mov	si, offset emitDUL
		mov	cx, length emitDUL
		rep	movsb
		call	MemUnlock			; release resource

		.leave
		ret
EmitStyleLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the proper PC/GEOS altered font name 

CALLED BY:	GLOBAL

PASS:		see HandleStyleRun

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The initial mapping is done by an earlier routine for 
		each page.  This routine merely looks up the right ID
		and emits the right code.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitFont	proc	near
		uses	ax, cx, dx, bx, ds, si, es
tgs		local	TGSLocals
		.enter	inherit

		; we want to emit the PostScript name, prepended by an 
		; underscore.  We need both the FontID and the style word, 
		; since if we have Roman italic, for example, we want to
		; map it to Times-Italic font in PostScript (as opposed to
		; mapping it to Times-Roman and obliquing it).

		push	di			; save pointer into buffer
		GetPathOrDrawGState di		; get right handle
		call	GrGetFont		; get the current fontID
		call	GrGetTextStyle		; get style byte
		pop	di			; restore buffer pointer
		mov	dl, al			; save style bits

		; cx=fontID, al = style bits.  Find the right entry.

		mov	bx, tgs.TGS_pageFonts.handle ; get block handle
		call	MemLock			; lock block
		mov	ds, ax			; ds -> block
		mov	al, dl			; restore style bits

		; if the mapping fails, we come back here for try #2
tryAgain:
		mov	si, tgs.TGS_pageFonts.chunk	; get chunk handle
		mov	si, ds:[si]		; dereference chunk handle
		mov	dx, cx			; dx = desired font id
		mov	cx, ds:[si].PF_count	; get entry count
		add	si, offset PF_first	; point at first entry
entryLoop:
		add	si, size PageFont	; bump past scratch space
		cmp	dx, ds:[si].PF_id	; id match ?
		jne	nextEntry
		cmp	al, ds:[si].PF_style	; style match ?
		je	foundMatch
nextEntry:
		loop	entryLoop

		; fell off the end.  This probably means that we're trying
		; to map the font to symbol.  If that is the case, then handle
		; that as a special case.  Otherwise, spew warning.
		
		cmp	dx, FID_PS_SYMBOL	; is it symbol font ?
EC <		WARNING_NE PS_MAPPING_UNRECOGNIZED_FONT_TO_HELVETICA	>
		je	mappingOK		; if we really want it, do it
		mov	cx, FID_PS_HELVETICA	; change what we want to some
		jmp	tryAgain		;  thing nicer to look 
mappingOK:		
		segmov	ds, cs, si
		mov	si, offset symbolFont
		jmp	foundCommon		

		; ds:si points at the right PageFont entry.  We need to copy
		; over the name, followed by a "true" or "false" which 
		; indicates whether or not to re-encode.
foundMatch:
		mov	al, ds:[si].PF_newstyle	; get new style bits
foundCommon:
		mov	ah, ds:[si].PF_flags	; get re-encode flag for later
		mov	cl, ds:[si].PF_nlen	; get length of name
		clr	ch
		mov	tgs.TGS_newstyle, al	; set them for later
		add	si, offset PF_name	; ds:si -> name
		rep	movsb			; copy name over
		mov	al, ' '
		stosb

		segmov	ds, cs, si
		mov	si, offset emitTrue
		mov	cx, length emitTrue
		test	ah, mask PFF_REENCODE	; if standard, need to fix
		jnz	copyBoolean
		mov	si, offset emitFalse
		mov	cx, length emitFalse
copyBoolean:
		rep	movsb

		mov	bx, tgs.TGS_pageFonts.handle ; get block handle
		call	MemUnlock
		.leave
		ret
EmitFont	endp

emitTrue	char	" true "
emitFalse	char	" false "

symbolFont	PageFont < FID_PS_SYMBOL, 0, 0, 0, 7, \
			   <0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,\
			    0,0,0,0,0,0,0>,\
			   <"/Symbol78901234567890123456789012345678901234567890123456789">>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckAutoHyphen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if we need to put a hyphen at the end

CALLED BY:	INTERNAL
		EmitTextField

PASS:		ds:bx	 - pointer to TextField element (base of current
			   chunk)
		ds:dx 	 - pointer to text string (within ds:bx)
		ds:bx.si - pointer to TFStyleRun
		cx	 - character count

RETURN:		cx	 - real char count
		ds:bx	 - fixed up
		ds:dx	 - pointer to text string

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckAutoHyphen	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; check for auto one

		test	ds:[bx].ODTF_saved.GDFS_flags, \
						mask HF_AUTO_HYPHEN
		jz	done	

		; have an auto-hyphen.  allocate a new chunk and copy over the
		; string.

		sub	dx, bx				; convert back to offset
		push	cx, ax, es, di, si		; save source reg

		; figure which gstring chunk is being employed to hold the
		; element so we can deref it after the realloc

		mov	si, tgs.TGS_pathchunk
		cmp	bx, ds:[si]			; path chunk?
		je	haveSrcChunk			; yes
		mov	si, tgs.TGS_chunk.chunk		; no, must be main one
haveSrcChunk:

		mov	ax, tgs.TGS_xtrachunk		; use extra chunk
		add	cx, 2				; add some space
		call	LMemReAlloc

		mov	bx, ds:[si]			; deref src chunk

		segmov	es, ds				; es -> string
		mov	di, ax
		mov	di, ds:[di]			; get pointer to chunk
		mov	si, dx				; ds:si -> string
		add	si, bx

		mov	dx, di				; set pointer there too
		sub	cx, 2				; copy this many
		rep	movsb
		mov	al, '-'
		stosb					; store final hypen
		pop	cx, ax, es, di, si
		inc	cx				; really is one more
done:
		.leave
		ret

CheckAutoHyphen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a GR_DRAW_TEXT or GR_DRAW_TEXT_CP element
		or GR_DRAW_CHAR or GR_DRAW_CHAR_CP

CALLED BY:	EXTERNAL
		TransGString

PASS:		es	- points to locked options block
		si	- gstring handle

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		extract the element and draw it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitText	proc	far
		uses	ax, bx, cx, si, di, ds
tgs		local	TGSLocals
		.enter	inherit

		call	ExtractElement		; get the element into a buffer

		call	EmitTextCommon

		; all done, just leave

		mov	bx, tgs.TGS_chunk.handle
		call	MemUnlock

		.leave
		ret
EmitText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTextCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitTextCommon	proc	far
		uses	ax, bx, cx, dx, si, di, ds
tgs		local	TGSLocals
		.enter	inherit

		mov	dl, ds:[si].ODT_opcode		; see if CP
		cmp	dl, GR_DRAW_TEXT		; see if CP
		jne	getCP
		mov	ax, ds:[si].ODT_x1
		mov	bx, ds:[si].ODT_y1
		mov	cx, ds:[si].ODT_len
		add	si, size OpDrawText

		; have all we need.  Output the piece of text.
outputText:
		mov	tgs.TGS_locmot.WWF_int, 0	; init local motion 
		mov	tgs.TGS_locmot.WWF_frac, 0
		call	EmitDrawText

		.leave
		ret

		; CP version.  Get what we need
getCP:
		GetPathOrDrawGState di		; get right handle
		call	GrGetCurPos
		cmp	dl, GR_DRAW_TEXT_CP	; see if CP
		jne	getChar
		mov	cx, ds:[si].ODTCP_len
		add	si, size OpDrawTextAtCP
		jmp	outputText

		; GR_DRAW_CHAR or GR_DRAW_CHAR_CP
getChar:
		mov	cx, 1
		cmp	dl, GR_DRAW_CHAR_CP
		jne	getCharPos
		add	si, offset ODCCP_char
		jmp	outputText
getCharPos:
		mov	ax, ds:[si].ODC_x1
		mov	bx, ds:[si].ODC_x1
		add	si, offset ODC_char
		jmp	outputText
EmitTextCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitDrawText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out some text

CALLED BY:	INTERNAL
		EmitText

PASS:		es	- locked options block
		ds:si	- pointer to string
		cx	- #characters
		ax	- x position
		bx	- y position

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		emit PS code to draw text

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version
		VL	06/95		preserve handle of ds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitDrawText	proc	near
		uses	ax, bx, cx, dx, ds, es, si, di
tgs		local	TGSLocals
		.enter	inherit

		; we need to output all that stuff to start an object, output
		; the transform, etc, etc.

		push	bx			; save y pos
		push	ax			; save x pos
		push	es:[PSEO_fonts]		; save fonts list enum
		push	ds:[LMBH_handle] 
		mov	bx, (GR_DRAW_TEXT - GSE_FIRST_OUTPUT_OPCODE)*2
		call	EmitStartObject
		call	EmitTransform

		; now we need to emit the opening bracket for the array of
		; style run arrays.  (Even thought we're only writing one)

		push	cx
		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax			; ds -> PSCode resource
		mov	bx, tgs.TGS_stream
		EmitPS	emitOpenBracket
		mov	bx, handle PSCode
		call	MemUnlock
		pop	cx
		pop	bx
		call	MemDerefDS
				

		; write out the string and attributes

		mov	dx, si
		call	EmitTextString
		call	EmitTextAttr

		; see if kerning is on.  If not, write out zero for kerning.

		push	cx
		GetPathOrDrawGState di		; get right handle
		call	GrGetFont		; dxah = point size
		rndwbf	dxah			; dx = integer size
		call	GrGetTrackKern		; ax = degree of track kerning
		pop	cx

		; limit to values from graphics.def.  This code stolen from
		; the kernel calculation for kerning.

		cmp	ax, MAX_TRACK_KERNING
		jle	maxOK				;branch if too large
		mov	ax, MAX_TRACK_KERNING
maxOK:
		cmp	ax, MIN_TRACK_KERNING
		jge	minOK				;branch if too small
		mov	ax, MIN_TRACK_KERNING
minOK:
		imul	dx				;ax <- ptsize * degree
		jc	isBig				;branch if too large
		tst	ax
		jns	haveKern			;no branch if negative
		tst	ds:GS_trackKernDegree		;test original sign
		js	haveKern			;branch if orig neg
isBig:
		tst	ds:GS_trackKernDegree		;test original sign
		js	isBigNegative			;branch if negative
		mov	ax, MAX_KERN_VALUE		;ax <- max kern value
		jmp	haveKern
isBigNegative:
		mov	ax, MIN_KERN_VALUE		;ax <- min kern value

haveKern:
		mov	bx, ax
		clr	ax			; bxax = degree of kerning
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> string buffer

		call	WWFixedToAscii
		mov	al, ' '			; put in  the separator
		stosb

		; write out the font

		pop	bx
		call	EmitFont		; write style matrix and font

		; write out point size

		push	di, cx			; save pointer
		GetPathOrDrawGState di		; get right handle
		call	GrGetFont
		pop	di, cx
		mov	bx, dx
		clr	al
		call	WWFixedToAscii

		; output style matrix for styles not covered by font selection

		mov	al, tgs.TGS_newstyle
		call	EmitStyleMatrix

		; output the closing brackets

		push	ds, si, cx
		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitCloseBrackets
		mov	cx, length emitCloseBrackets
		rep	movsb
		mov	bx, handle PSCode
		call	MemUnlock
		pop	ds, si, cx

		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrGetTextSpacePad
		pop	di
		mov	bx, dx			; restore space padding
		mov	ah, bl
		clr	al
		call	WWFixedToAscii		; convert to ascii
		mov	al, ' '			; space delimit things
		stosb

		; calc and write out width

		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrTextWidthWBFixed
		push	ax,cx,dx
		mov	ch, ah
		clr	cl
		clr	ax,bx
		call	GrRelMoveTo		; update current position
		pop	ax,cx,dx
		pop	di
		mov	bx, dx			; write out width
		clr	al
		call	WWFixedToAscii		; convert to ascii
		mov	al, ' '
		stosb

		; write out x pos

		pop	bx			; restore x pos
		clr	ax
		tst	tgs.TGS_xfactor		; see if OK
		jnz	xOK
		clr	bx
xOK:
		call	WWFixedToAscii
		mov	al, ' '
		stosb

		; write out y pos.  This depends on what the passed value
		; means.  Get the mode to see...

		pop	bx			; restore ypos

		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrGetTextMode
		pop	di
		test	al, mask TM_DRAW_BASE	; assume drawing at baseline
		jz	getBaseline		;  no, compute baseline pos
		clr	ax
haveBaseline:
		tst	tgs.TGS_yfactor		; see if OK
		jnz	yOK
		clr	bx
		clr	ax
yOK:
		call	WWFixedToAscii		; write Y POS

		mov	bx, handle PSCode
		call	MemLock
		mov	ds, ax
		mov	si, offset emitDSG
		mov	cx, length emitDSG
		rep	movsb
		call	EmitBuffer		; write it all out

		mov	bx, handle PSCode
		call	MemUnlock

		call	EmitEndObject

		.leave
		ret

		; not drawing at baseline.  Compute where baseline is.
		; in each case, we have to subtract the baseline position,
		; so get that first and adjust it.
getBaseline:
		push	di, cx, dx		; save pointer
		GetPathOrDrawGState di		; get right handle
		mov	si, GFMI_BASELINE	; get baseline offset
		call	GrFontMetrics		; get baseline offset
		mov	ch, ah			; cx will hold fraction
		clr	cl
		add	bx, dx
		mov	ah, GFMI_HEIGHT		; assume drawing from bottom
		test	al, mask TM_DRAW_BOTTOM	; drawing at bottom ?
		jnz	notTop
		mov	ah, GFMI_ACCENT		; assume drawing from accent
		test	al, mask TM_DRAW_ACCENT ; drawing at ACCENT height ?
		jz	doneCalc
notTop:
		mov	al, ah			; get enum into al
		call	GrFontMetrics		; get value
		sub	ch, ah			; do fraction
		sbb	bx, dx			; do integer part

		; not any of these -- drawing at the top of the character box
		; that means we're done...
doneCalc:
		mov	ax, cx
		pop	di, cx, dx
		jmp	haveBaseline
EmitDrawText	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitStyleMatrix
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a transformation matrix for style bits that 
		we have to do ourselves

CALLED BY:	INTERNAL
		EmitDrawText, HandleStyleRun

PASS:		al	- style bits to emulate
		es:di	- where to put matrix

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitStyleMatrix	proc	near
		uses	ds, si, cx
tgs		local	TGSLocals
		.enter	inherit

		; build up the matrix in the gstate, then output it.  But
		; save the current stuff first

		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrSaveState

		call	GrSetNullTransform	; set it up
		call	AddMetricsStyles	; add in the style-related tm

		; read in the matrix to a buffer and emit it

		segmov	ds, ss, si
		lea	si, tgs.TGS_matrix
		call	GrGetTransform		; get matrix

		pop	di
		mov	al, ' '
		stosb
		call	MatrixToAscii		; write it out
		mov	al, ' '
		stosb

		; restore the state of things

		push	di
		GetPathOrDrawGState di		; get right handle
		call	GrRestoreState
		pop	di

		.leave
		ret
EmitStyleMatrix	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddMetricsStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add scales, et al to the transformation matrix for styles
CALLED BY:	SetupTMatrix()

PASS:		di	- gstate handle
		al - styles to implement (TextStyle)
RETURN:		tmatrix in gstate has all scaling/rotation
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/17/90		Initial version
	jim	4/91		converted from nimbus driver

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SCRIPT_FACTOR_INT	=	0
SCRIPT_FACTOR_FRAC	=	0x8000		;superscript,subscript = 1/2

SUBSCRIPT_OFFSET_INT	=	0x0
SUBSCRIPT_OFFSET_FRAC	=	0x1a00		;offset below

SUPERSCRIPT_OFFSET_INT	=	0xffff
SUPERSCRIPT_OFFSET_FRAC	=	0x9fff		;offset above

BOLD_FACTOR_INT		=	0x0001
BOLD_FACTOR_FRAC	=	0x2000		;bold = 1.10

ITALIC_FACTOR_INT	=	0xffff
ITALIC_FACTOR_FRAC	=	0xc996		;italic = tan(-12)

TRANSFORM_STYLES = mask TS_SUPERSCRIPT or \
		   mask TS_SUBSCRIPT or \
		   mask TS_ITALIC or \
		   mask TS_BOLD

AddMetricsStyles	proc	near
		uses	ax, bx, cx, dx, ds
		.enter	

		; first check out width and weight

		push	ax
		clr	ax
		call	GrGetFontWidth
		cmp	al, FWI_MEDIUM			; see if normal
		je	checkWeight
		clr	ah				; it's UNSIGNED, wacko
		mov	dx, ax
		mov	bx, FWI_MEDIUM
		clr	ax, cx
		call	GrUDivWWFixed
		mov	bx, 1
		clr	ax
		call	GrApplyScale
checkWeight:		
		call	GrGetFontWeight
		cmp	al, FW_NORMAL
		je	checkStyles
		clr	ah
		mov	dx, ax
		mov	bx, FW_NORMAL
		clr	ax, cx
		call	GrUDivWWFixed			; dxcx = x factor
		mov	bx, 1
		clr	ax
		call	GrApplyScale

		; Any styles of interest?
checkStyles:
		pop	ax
		test	al, TRANSFORM_STYLES	;any to styles to implement?
		jz	done			;branch if no styles

		; If faking bold, scale horizontally

		test	al, mask TS_BOLD		;bold?
		jz	noBold
		push	ax				; save style bits
		mov	dx, BOLD_FACTOR_INT
		mov	cx, BOLD_FACTOR_FRAC		;dx.cx <- scale factor
		mov	bx, 1
		clr	ax
		call	GrApplyScale
		pop	ax				; restore style bits

		; If doing sub- or superscript, scale both directions.  And
		; adjust the drawing position.
noBold:
		test	al, mask TS_SUBSCRIPT or mask TS_SUPERSCRIPT
		jz	noScript

		push	ax				; save style bites
		mov	dx, SCRIPT_FACTOR_INT
		mov	cx, SCRIPT_FACTOR_FRAC		;dx.cx <- scale factor
		mov	bx, SCRIPT_FACTOR_INT
		mov	ax, SCRIPT_FACTOR_FRAC		;dx.cx <- scale factor
		call	GrApplyScale
		pop	ax				; restore style bites

		; If doing italic, use a skew factor
noScript:
		test	al, mask TS_ITALIC		;italic?
		jz	done
		push	ax
		mov	bx, di				; lock down gstate
		call	MemLock
		push	bx
		mov	ds, ax
		mov	dx, ds:[GS_TMatrix].TM_22.WWF_int	; copy value
		mov	cx, ds:[GS_TMatrix].TM_22.WWF_frac
		mov	bx, ITALIC_FACTOR_INT
		mov	ax, ITALIC_FACTOR_FRAC		;dx.cx <- scale factor
		call	GrMulWWFixed
		mov	ds:[GS_TMatrix].TM_21.WWF_int, dx
		mov	ds:[GS_TMatrix].TM_21.WWF_frac, cx
		pop	bx
		call	MemUnlock
		pop	ax				; restore style buits
done:
		.leave
		ret
AddMetricsStyles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan a graphics string and extract all the font info, including
		which PostScript font we will use (or download)

CALLED BY:	INTERNAL
		TranslateGStringCommon

PASS:		tgs	- passed stack frame with all the crucial info

RETURN:		pageFonts chunk filled with page font info.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		scan string until we reach a new page or the end of the string.
		for each text element found, record the font info, including
		how it maps to the PostScript font set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version
		Jim	1/93		Updated to use 2.0 GString routines

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPageFonts	proc	far
		uses	ax, bx, cx, dx, si, di, es, ds
tgs		local	TGSLocals
		.enter	inherit

		; before we start, initialize the page fonts with FID_PS_HELV,
		; since if we don't find the font, we'll use that.

		push	bx
		mov	bx, tgs.TGS_pageFonts.handle
		push	bx
		call	MemLock				; ax -> block
		mov	es, ax				; es -> pagefonts block
		mov	cx, FID_PS_HELVETICA		; map to helv.
		clr	al				; no style bits
		call	GetPageFontEntry
		pop	bx				; restore block handle
		call	MemUnlock			; unlock the block
		pop	bx

		mov	si, tgs.TGS_gstring		; get gstring handle
		clr	di				; need gstate too
		call	GrCreateState			; di = GState handle

		; now we're going to scan through all the elements of the 
		; string, looking for text elements
keepLooking:
		mov	dx, mask GSC_NEW_PAGE or mask GSC_OUTPUT 
		call	GrDrawGStringAtCP
		mov	ax, dx				; ax = GSRetType

		; check why we stopped.  If we're done, then we're done with
		; our font scanning.  Else check for text-type elements and
		; do the right thing :)

		cmp	ax, GSRT_FAULT			; if some problem
		je	donePage			; ...then exit
		cmp	ax, GSRT_COMPLETE			; else if done
		je	donePage			; ...then done
		cmp	ax, GSRT_NEW_PAGE		; else if end page
		je	donePage			; ...then done

		; there are just a few text calls we need to support...
checkOpcode:
		cmp	cl, GR_END_GSTRING		; if end of string...
		je	donePage
		cmp	cl, GR_NEW_PAGE		; if end of string...
		je	donePage
		cmp	cl, GR_DRAW_TEXT_FIELD		; most common...
		je	handleTextField
		cmp	cl, GR_DRAW_TEXT		; next common...
		je	handleText
		cmp	cl, GR_DRAW_TEXT_CP		; next common...
		jne	keepLooking
handleText:
		call	ExtractDrawTextFont
		jmp	checkNext
handleTextField:
		call	ExtractTextFieldFonts

		; before we go on, check out the next opcode.  Most likely
		; it's not something we're interested in, but you never know.
checkNext:
		cmp	cx, GSRT_COMPLETE		; if done...
		je	donePage
		clr	cx				; just teasing
		call	GrGetGStringElement		; just want opcode
		mov	cl, al
		jmp	checkOpcode

		; done with scan.  Free the GState and GString structures that
		; we allocated above
donePage:
		; since we created a new gstring handle above, get rid of
		; it now.

		call	GrDestroyState			; don't need anymore

		; reset the file back to where it was.

		mov	al, GSSPT_BEGINNING		; set position to begin
		call	GrSetGStringPos

		.leave
		ret

GetPageFonts	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractTextFieldFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab text font info out of GrDrawTextField element

CALLED BY:	INTERNAL
		GetPageFonts

PASS:		si	- handle graphics string
		di	- handle gstate

RETURN:		cx	- GSRetType from call to GrCopyGString.  
			  should be GSRT_ONE, but could be GSRT_COMPLETE.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		yuck, dealing with embedded graphics one more time

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtractTextFieldFonts	proc	near
		uses	ax, bx, dx, di, si, es
tgs		local	TGSLocals
		.enter	inherit

		call	ExtractTextElement
		push	cx				; save return type

		mov	di, tgs.TGS_gstate	; di = gstate handle

		; get the size of the string

		mov	bx, si			; ds:bx -> element
		mov	cx, ds:[bx].ODTF_saved.GDFS_nChars ;  text string size

		; set up ds:si to point at style runs

		mov	si, size OpDrawTextField	; bx.si -> string

		; alright, we're ready to go.  The following pointers are set:
		; ds:bx    -> pointer to a OpDrawTextField structure
		; ds:bx.si -> pointer to first TFStyleRun structure
		; cx	   -  # characters in the line
		; loop through the style runs, getting out the attributes

		call	ExtractStyleGroupFonts	; handle next group of runs

		; all done, just leave

		mov	bx, tgs.TGS_chunk.handle ; unlock block
		call	MemUnlock		; release string block
		pop	cx			; restore return type

		.leave
		ret
ExtractTextFieldFonts	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractTextElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a gstring object from the current gstring to a separate
		buffer.

CALLED BY:	INTERNAL
		Most of the EmitXXX routines call this.

PASS:		si	- gstring handle
		inherits TGSLocals structure

RETURN:		ds:si	- points to data
		cx	- GSRetType from call to GrCopyGString.  
			  should be GSRT_ONE, but could be GSRT_COMPLETE.


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		caller is repsonsible for making sure the GState is updated
		with the new current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	02/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtractTextElement proc	far
		uses	ax, bx, dx, di
tgs		local	TGSLocals
		.enter	inherit

		; lock down our scratch block, clear out the scratch chunk

		mov	bx, tgs.TGS_chunk.handle
		call	MemLock			; 
		mov	ds, ax			; ds -> block

		clr	cx			; resize to zero
		mov	ax, tgs.TGS_chunk.chunk	; ax = chunk handle
		call	LMemFree
		call	MemUnlock

		; first set up to draw into our buffer

		push	si			; save source GString handle
		mov	cl, GST_CHUNK		; it's a memory type gstring
		call	GrCreateGString		; di = gstring handle
		mov	tgs.TGS_chunk.chunk, si	; store new chunk
		pop	si			; restore source gstring

		; now draw the one element into our buffer

		mov	dx, mask GSC_ONE	; return after one element
		call	GrCopyGString
		push	dx			; save return type

		; that's all we need, so biff the string

		mov	dl, GSKT_LEAVE_DATA	; don't kill the data
		mov	si, di			; si = GString handle
		clr	di			; di = GState handle (0)
		call	GrDestroyGString

		; set up a pointer to the data

		mov	bx, tgs.TGS_chunk.handle
		call	MemLock			; 
		mov	ds, ax
		mov	si, tgs.TGS_chunk.chunk	; restore chunk handle
		mov	si, ds:[si]		; ds:si -> data
		pop	cx			; restore return type

		.leave
		ret
ExtractTextElement endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractStyleGroupFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Traverse a style group and extract the font info

CALLED BY:	INTERNAL
		ExtractTextFieldFonts

PASS:		ds:bx    -> pointer to a OpDrawTextField structure
		ds:bx.si -> pointer to first TFStyleRun structure
		cx	   -  # characters in the line, including a count
		 	     of one for each embedded graphic.

RETURN:		ds	-> still points to block, may have changed
		cx	- updated to #chars left to bdo

			  other pointers updated appropriately

DESTROYED:	es

PSEUDO CODE/STRATEGY:
		just loop through all the style runs

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtractStyleGroupFonts	proc	near
		uses	ax, bx, di
tgs		local	TGSLocals
		.enter	inherit

		; while there are still characters left and we haven't hit
		; one of those fucking embedded graphics, keep outputting the
		; style run arrays.
styleRunLoop:
		push	cx			; save #chars left (total)
		mov	cx, ds:[bx][si].TFSR_count ; get character count

		; we want to skip over single tab characters.  Check for 
		; a one-character run, then check to see if is a tab.

		cmp	cx, 1			; one character ?
		jne	getFonts		;  no, continue
		xchg	si, dx			; save a reg,
		cmp	{byte} ds:[bx][si], C_TAB ; is it a tab ?
		xchg	si, dx
		je	doneRun			;  no, continue
getFonts:
		push	cx
		segmov	es, ds, cx		; es -> FontEntry block
		add	si, bx			; ds:si -> TFStyleRun
		add	si, TFSR_attr		; point to attributes
		mov	cx, ds:[si].TA_font	; get font and style info
		mov	al, ds:[si].TA_styleSet	; get style bits
		sub	si, TFSR_attr
		sub	si, bx			; things back to normal
		call	GetPageFontEntry	; map it baby
		segmov	ds, es, cx		; blk may have moved
		pop	cx
		mov	bx, tgs.TGS_chunk.chunk	; dereference again
		mov	bx, ds:[bx]

		; check to see if the font will be downloaded.  If so, check
		; which chars to download.  Assume hyphen since we skipped 
		; checking to see if we needed it.

		test	es:[di].PF_flags, mask PFF_DOWNLOAD ; download font ?
		jz	doneRun

		; we're going to download the font.  optimize things by 
		; checking which characters to download.  Check the string.
		; cx = #chars in this run

		push	cx, bx, si

		add	si, bx			; ds:si -> StyleRun
		add	si, size TFStyleRun	; ds:si -> string
		clr	bh
charLoop:
		lodsb				; get next char
		mov	bl, al			
		and	bl, 7			; bit index
		mov	ah, cs:bitMasks[bx]	; ah = bit mask
		mov	bl, al
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		or	es:[di].PF_map[bx], ah	; twiddle the right bit
		loop	charLoop
		mov	bl, C_HYPHEN and 7	; do hyphen too
		mov	ah, cs:bitMasks[bx]	; ah = bit mask
		mov	bl, C_HYPHEN shr 3
		or	es:[di].PF_map[bx], ah	; twiddle the right bit
		pop	cx, bx, si
doneRun:
		mov	di, cx			; restore #chars in this run
		pop	cx			; restore #characters total
		sub	cx, di			; calc #chars left
		add	si, size TFStyleRun	; bump to next style run
		add	si, di			; bump over string too
		tst	cx			; ...might be done
		jnz	styleRunLoop		; ...but maybe not

		.leave
		ret

ExtractStyleGroupFonts	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExtractDrawTextFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	INTERNAL
		GetPageFonts

PASS:		di	- handle graphics string
		cl	- element opcode (either DRAW_TEXT or DRAW_TEXT_CP)

RETURN:		cx	- GSRetType from call to GrCopyGString.  
			  should be GSRT_ONE, but could be GSRT_COMPLETE.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		stopped on a DRAW_TEXT element

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExtractDrawTextFont	proc	near
		uses	ax, bx, dx, si, di, ds, es
tgs		local	TGSLocals
		.enter	inherit

		; get the current info

		push	cx			; save opcode
		call	ExtractTextElement	; ds:si -> element
		push	cx			; save GSRetType
		call	GrGetFont		; cx = FontID
		call	GrGetTextStyle		; al = style bits
		segmov	es, ds, dx		; es -> block
		call	GetPageFontEntry	; es:di -> entry
		segmov	ds, es, ax		; ds may have moved

		; if we're not mapping to a PostScript font, then do a scan
		; of the characters

		pop	cx			; restore GSRetType
		pop	dx			; restore opcode
		push	cx			; save GSRetType again
		test	es:[di].PF_flags, mask PFF_DOWNLOAD ; download font ?
		jz	done

		; we're going to download the font.  optimize things by 
		; checking which characters to download.  Check the string.

		clr	bh
		add	si, offset ODT_len	; to get at string length
		cmp	dl, GR_DRAW_TEXT	; check assumption
		je	scanChars
		add	si, offset ODTCP_len - offset ODT_len
scanChars:
		mov	cx, ds:[si]		; cx = string length
		add	si, 2			; ds:si -> string
charLoop:
		lodsb				; get next char
		mov	bl, al			
		and	bl, 7			; bit index
		mov	ah, cs:bitMasks[bx]	; ah = bit mask
		mov	bl, al
		shr	bx, 1
		shr	bx, 1
		shr	bx, 1
		or	es:[di].PF_map[bx], ah	; twiddle the right bit
		loop	charLoop
done:
		mov	bx, tgs.TGS_chunk.handle ; unlock block
		call	MemUnlock		; release string block
		pop	cx			; restore GSRetType

		.leave
		ret
ExtractDrawTextFont	endp

bitMasks	byte	0x80, 0x40, 0x20, 0x10, 0x08, 0x04, 0x02, 0x01


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPageFontEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get current font info and write it out to our PageFonts
		struct

CALLED BY:	INTERNAL
		GetPageFonts

PASS:		cx	- desired FontID
		al	- desired style bits
		es	- locked block with PageFonts array

RETURN:		es:di	- pointer into PageFont array at correct entry
			  (es may have moved)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		get current font from GState
		try to map to PostScript font
		fill out a new PageFont struct, if needed
		if (mapping not successful)
		    scan string and determine what chars are needed.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetPageFontEntry	proc	near
		uses	ax, bx, cx, dx, si, ds
tgs		local	TGSLocals
		.enter	inherit

		; lock down the PageFonts array and store this info away.
		; Init the rest of the scratch block

		mov	di, tgs.TGS_pageFonts.chunk	; get chunk handle
		mov	di, es:[di]		; dereference chunk handle
		add	di, offset PF_first	; point to scratch structure
		mov	es:[di].PF_id, cx	; store ID and style info
		mov	es:[di].PF_style, al
		mov	es:[di].PF_flags, 0	; init the flags
		
		; if the font is a bitmap font, them just map it to Times-Roman
		;  app has no  business using one of those anyway

		cmp	cx, FM_PRINTER	; upper end bitmap fonts
		jae	changeToRoman
		cmp	cx, FM_NIMBUSQ	; first outline ID
		jae	checkPS
changeToRoman:
		mov	cx, FID_PS_TIMES_ROMAN	; set to Roman

		; now try to map it to PostScript
checkPS:
		call	MapFontToPostScript	; dh = "closeness"

		; if the font isn't a perfect match, then we should download it

		cmp	dh, FM_EXACT		; if exact, we're done
		je	havePageFont

		; also check to see if that font is available.  If not, then
		; use the PostScript mapping.

		mov	cx, es:[di].PF_id	; get font id
		mov	dl, mask FEF_OUTLINES	; match fontID
		call	GrCheckFontAvail
		cmp	cx, FID_INVALID	; if not, take what PS gave
		je	havePageFont		;   us

		; We didn't get an exact match, so use a download font.
		; set the right flags and change the name to something unique
		; also, don't have to re-encode, so reset that flag.

		and	es:[di].PF_flags, not mask PFF_REENCODE
		or	es:[di].PF_flags, mask PFF_DOWNLOAD

		; map the font id and style combinations to see how far the 
		; font driver will go for us...
		; For 2.0, we want to try to map better for styles.  For
		; 1.2, we're going to punt and do all the style in PostScript

		mov	cx, es:[di].PF_id	; get font id
		mov	dl, es:[di].PF_style	; tack on style bits
		mov	es:[di].PF_newstyle, dl	; store leftovers
		mov	es:[di].PF_nlen, 8	; #chars in new name
		mov	si, di			; save pointer to entry
		add	di, offset PF_name	; point to the name field
		mov	al, '/'			; start it with an X
		mov	ah, 'X'			; start it with an X
		stosw
		mov	al, ch
		call	ByteToHexAscii		; creates a name "/X1234"
		mov	al, cl			;   or something like that 
		call	ByteToHexAscii
		mov	al, dl
		call	ByteToHexAscii		; tack on style bits
		mov	di, si			; restore pointer to entry

		; and another thing.  clear out the bits that tell us which
		; characters to download

		clr	ax
		add	di, offset PF_map
		mov	cx, 16			; 32 bytes to clear
		rep	stosw
		mov	di, si			; recover entry pointer

		; OK, we have the font we wish.  See if it is in the 
		; PageFont array already.  Need to check both ID and style
		; If it's there, we're done.  If it isn't, then realloc the
		; chunk bigger and copy it over.
		; For 1.2, just check the ID, since we never have the font
		; driver do styles
havePageFont:
		mov	si, di			; bump to next entry
		mov	cx, es:[si-2]		; cx = #entries
		jcxz	addEntry		; none yet, add this one
		mov	dx, es:[si].PF_id	; load up compare values
		mov	al, es:[si].PF_style
checkPFloop:
		add	di, size PageFont	; ds:di -> next entry
		cmp	es:[di].PF_id, dx	; same id ?
		jne	nextEntry		;  nope, continue
		cmp	es:[di].PF_style, al	; same style ?
		je	done			;  yes, all done
nextEntry:
		loop	checkPFloop

		; we don't have this font yet.  Alloc a new entry for the 
		; array and copy the info to the last element
addEntry:
		segmov	ds, es, di
		sub	si, offset PF_first	; ds:si -> beginning of chunk
		mov	ax, tgs.TGS_pageFonts.chunk	; handle in ax
		ChunkSizePtr ds, si, cx		; cx = chunk size
		add	cx, size PageFont	; make room for another
		call	LMemReAlloc		; reallocate block
		mov	si, ax			; deref chunk again
		mov	si, ds:[si]		; ds:si -> chunk
		inc	ds:[si].PF_count	; bump the count of structs
		mov	di, si			; set up es:di -> chunk
		add	si, offset PF_first	; ds:si -> scratch element
		add	di, cx			; es:di -> past end of chunk
		mov	cx, size PageFont
		sub	di, cx			; es:di -> last array elemet
		rep	movsb			; copy PageFont element
		sub	di, size PageFont	; es:di -> PageFont element

		; either we just copied one or we don't need to copy one
done:
		.leave
		ret
GetPageFontEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MapFontToPostScript
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the PS name for our fontID

CALLED BY:	INTERNAL
		GetPageFontEntry

PASS:		cx	- fontID
		al	- style bits
		es:di	- pointer to PageFont structure

RETURN:		es:di	- PageFont structure filled in with info on closest
			  Adobe font that is resident in the printer.
		dh	- factor of "closesness" for font

DESTROYED:	dl

PSEUDO CODE/STRATEGY:
		if (adobe fontID)
		    write adobe name
		else
		    map to adobe font ID
		    if (fontID is in supported font list for printer)
		       write equivalent name
		    else 
		       using fontID, map to something intelligent.
		   

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MapFontToPostScript	proc	near
		uses	ax, bx, cx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		mov	es:[di].PF_style, al	; save style bits
		push	di			; pointer to PageFont struct
		push	ax
		and	al, mask TS_ITALIC or mask TS_BOLD ; only look for these

		; if it is an Adobe ID, skip the mapping function

		mov	bx, cx
		and	bx, 0xf000		; isolate manufacturer info
		cmp	bx, FM_ADOBE
		je	haveAdobe
		and	cx, not 0xf000		; clear manufacturer ID
		or	cx, FM_ADOBE		; force adobe
haveAdobe:
		; have an Adobe-type fontID.  Look it up in the table
		; register usage:
		;	ds:di   - points to closes match so far
		;	dl	- had difference in style bits for entry @ds:di 
		;	dh	- hold ID difference, from CalcFontDiff
		;	ds:si	- points to next entry to check
		;	ds:bx	- points into table of entry pointers
		;	al	- holds desired style
		;	cx	- holds desired fontID

		mov	ds, tgs.TGS_options	; get pointer to options blk
		mov	bx, ds:[PSEO_fonts]	; get font enum
		mov	dx, cs:[fontMapOffsets][bx] ; look at right table
		mov	bx, cs:[fontMapHandles][bx] ; look at right table
		push	bx
		push	ax			; save style bits
		call	MemLock
		mov	ds, ax
		pop	ax			; restore style bits
		mov	bx, dx			; ds:bx -> table of tables

		; set up really bad values so we pick the first element in
		; the table

		mov	dh, FM_DONT_USE		; worse difference in fontIDs
		mov	dl, 0xff		; worse difference in styles
		mov	di, ds:[bx]		; point at first element

		; loop through all the font tables.
tableLoop:
		push	bx			; save table pointer
		mov	bx, ds:[bx]		; load up pointer to table
		tst	bx			; if zero, we're done
		jz	foundFont

		; loop through all the font entries.  Like Mary Poppins, we 
		; want it Practically Perfect in Every Way.
fontLoop:
		mov	si, ds:[bx]		; ds:bx -> entry
		tst	si			; check for terminator
		jz	nextFontTable		; all done, no match
		push	bx

		; calculate the font difference

		push	ax
		mov	bx, ds:[si].AFE_id	; get ID of font to check
		mov	ax, cx			; check this one
		call	CalcFontDiff
		cmp	cl, dh			; is it better ?
		jb	haveSomething		;  maybe, keep checking
		mov	cx, ax			; restore desired font
		pop	ax			; restore desired style
		je	checkStyle		; id is same -- check style
		jmp	nextFontEntry		;   no, not better. skip it.

		; might have a better candidate.  see if we need to check style
haveSomething:
		mov	dh, cl			; save new id diff
		mov	cx, ax			; restore desired font
		pop	ax			; restore desired style

		; found a better font.  store some info about it and check to
		; see if we have an exact match.
haveBetterEntry:
		mov	dl, ds:[si].AFE_style	;  else get the new style too
		xor	dl, al			; store difference
		mov	di, si
		tst	dx			; if exact, use it !
		jz	foundFontInt
nextFontEntry:
		pop	bx
		add	bx, 2			; bump to next entry
		jmp	fontLoop

nextFontTable:
		pop	bx			; restore table pointer
		add	bx, 2			; bump to next table pointer
		jmp	tableLoop

;-------------------------------------------------------------------------

		; ID is same as the one we have so far. See if style is 
		; better
checkStyle:
		mov	ah, ds:[si].AFE_style	; get style of candidate
		xor	ah, al			; get difference
		cmp	ah, dl			; better than before ?
		jae	nextFontEntry		;  no, keep looking
		jmp	haveBetterEntry
		
		; have it as close as it gets.  ds:di -> font entry
foundFontInt:
		add	sp, 2			; pop table pointer
foundFont:
EC <		tst	di			; if zero, it's bad	>
EC <		ERROR_Z	PS_BAD_ADOBE_FONT_MAP_TABLE			>
		add	sp, 2			; don't care about font ptr

		; ds:di points at the font.  Get the length of the string,
		; and calculate the modified style bits.

		mov	si, di			; ds:si -> entry
		pop	bx			; restore handle
		pop	ax			; restore original style
		pop	di			; restore buffer pointer
		push	di			; save it again
		mov	cl, ds:[si].AFE_nlen	; get name length
		mov	es:[di].PF_nlen, cl	; save it
		clr	ch
		mov	ah, ds:[si].AFE_style	; get style bits
		not	ah
		and	al, ah			; zero out those bits
		mov	es:[di].PF_newstyle, al	; save what the result it
		mov	dl, ds:[si].AFE_encode	; get encoding to check special
		cmp	dl, AFE_STANDARD	; if standard, reencode
		jne	copyName
		or	es:[di].PF_flags, mask PFF_REENCODE
copyName:
		add	si, AFE_name		; ds:si -> name
		add	di, offset PF_name	; setup to copy name
		rep	movsb			; copy the name over
		pop	di			; restore pointer to struct start

		call	MemUnlock		; release font name segment

		.leave
		ret
MapFontToPostScript	endp

ExportText	ends

ExportType3Font	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DownloadPageFonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Download any fonts that we need to

CALLED BY:	INTERNAL
		TranslateGStringCommon

PASS:		tgs	- inherited stack frame

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Check each font that we scanned the page for.  If it needs
		to be downloaded, do it

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DownloadPageFonts	proc	far
		uses	ax, bx, cx, ds, si
tgs		local	TGSLocals
		.enter	inherit

		; lock down the block that the font descriptions are held
		; and loop through each one

		mov	bx, tgs.TGS_pageFonts.handle	; get block handle
		call	MemLock				; lock block
		mov	ds, ax				; ds -> block
		mov	si, tgs.TGS_pageFonts.chunk	; get chunk handle
		mov	si, ds:[si]			; deref handle

		; grab the number of fonts we need to check, then go to it

		mov	cx, ds:[si].PF_count		; #fonts to check
		jcxz	done				; handle no fonts 
		add	si, offset PF_first		; point to scratch
fontLoop:
		add	si, size PageFont		; bump to next entry
		test	ds:[si].PF_flags, mask PFF_DOWNLOAD ; check font type
		jz	nextEntry			;  nope, continue
		call	DownloadFont			; do this one
nextEntry:
		loop	fontLoop

		; done downloading what we need.  continue
done:
		mov	bx, tgs.TGS_pageFonts.handle	; release block
		call	MemUnlock

		.leave
		ret
DownloadPageFonts	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DownloadFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Download a single font

CALLED BY:	INTERNAL
		DownloadPageFonts

PASS:		ds:si	- points at PageFont entry of font to download

RETURN:		ds:si	- points at same PageFont entry (may have changed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		fill in a template and write it out.  only write out the
		characters that we need

		first download the header
		then download the individual character encodings
		then download the character definitions
		then download a trailer
		then enter the available font table 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DOWNLOAD_FONT_OVERHEAD	equ	12
MINIMUM_PS_VM_REQUIRED	equ	30

DownloadFont	proc	near
		uses	ax, bx, es, cx, dx, di
tgs		local	TGSLocals
		.enter	inherit


		; first count the characters that we need to download.
		; We need this for a few things...

		call	CountCharsToDownload		; cx = #chars 
							; dx = max char #
		; download the header

		call	DownloadFontHeader

		; emit the encoding vector

		call	EmitEncoding

		; we're done encoding, so we're going to have to start calling
		; the font driver to get the right paths for the characters.
		; before we do that, we need the font manufacturer code, 
		; which we have to get via some hacking.  (don't look).
		; note: we know that we always have an outline font here, since 
		; all bitmap (non-outline) fonts will be mapped to Times-Roman.

		push	ds:[si].PF_id			; save font id
		mov	bx, tgs.TGS_chunk.handle 	; make a gstring
		call	MemDerefDS			; ds -> LMem block
		mov	ax, tgs.TGS_chunk.chunk		; ^lbx:si -> chunk 
		call	LMemFree
		mov	bx, tgs.TGS_chunk.handle 	; make a gstring
		call	MemUnlock			; release it 
		mov	cl, GST_CHUNK			; signal its a chunk
		call	GrCreateGString			; di = gstate struct
		mov	tgs.TGS_chunk.chunk, si		; store new chunk han
		pop	cx				; restore font id
		mov	dx, 1				; set ps = 1.0 points
		clr	ax
		call	GrSetFont

		; for 1.2 we're going to simulate ALL style in PostScript.
		; For 2.0, we'll want to change this and get the largest 
		; subset of styles that the actual outline data supports.

		mov	ax, 0xff00			; restore style bits
		call	GrSetTextStyle

		; initialize the various variables we keep track of

		clr	ax				; clear FontBBox
		mov	tgs.TGS_fontBBox.R_right, ax
		mov	tgs.TGS_fontBBox.R_top, ax
		mov	ah, 40h
		mov	tgs.TGS_fontBBox.R_bottom, ax
		mov	tgs.TGS_fontBBox.R_left, ax

		; before we start spewing characters, get the font matrix, so
		; we don't get it for every character.  Just use any char here.

		call	GrSaveState			; save current state

		mov	ax, DR_FONT_GEN_PATH		; di = driver function
		mov	dl, 'a'				; use any char
		clr	dh
		mov	cl, mask FGPF_POSTSCRIPT
		push	di				; save gstate handle
		mov 	bx, di
		call	GrCallFontDriver		; draw the character
		pop	di				; restore gstate handle
		
		segmov	ds, ss, si
		lea	si, tgs.TGS_matrix		; place to put matrix
		call	GrGetTransform			; get font matrix

		call	GrRestoreState

		push	di				; save GState handle
		segmov	ds, es, si			; ds -> PSType3
		mov	bx, tgs.TGS_stream		; get stream blk handle
		EmitPS	emitFontMatrix			; "/FontMatrix "
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer		; es:di -> buffer
		call	MatrixToAscii
		mov	si, offset emitFMDef
		mov	cx, length emitFMDef
		rep	movsb
		call	EmitBuffer

		; now we need to open the CharProcs dict and write out
		; each of the character drawing procedures

		mov	bx, tgs.TGS_stream		; get stream blk handle
		EmitPS	cpstart

		segmov	es, ds, si			; es -> PSType3

		mov	bx, tgs.TGS_chunk.handle 	; relock the block
		call	MemLock				
		mov	ds, ax				; ds -> font block
		pop	dx				; restore gstate han

		; for each bit set in the character map, emit the code to
		; draw the character

		call	EmitFontCharacters		; emit em all
		mov	bx, tgs.TGS_chunk.handle	; deref again 2b sure
		call	MemDerefDS			; ds -> PageFonts

		; done sending all the character definitions.  output
		; a bounding box and close the dict

		mov	si, dx				; si = gstring handle
		clr	di				; di = gstate handle (0)
		mov	dl, GSKT_LEAVE_DATA
		call	GrDestroyGString		; finished with it

		push	ds, es
		segmov	ds, es				; ds -> PSType3
		mov	bx, tgs.TGS_stream		; get stream blk handle
		EmitPS	emitFontBBox			; output start
		segmov	es, ss, di	
		lea	di, tgs.TGS_buffer
		mov	bx, tgs.TGS_fontBBox.R_left	; output BBox info
		call	SWordToAscii			; write left
		mov	al, ' '
		stosb
		mov	bx, tgs.TGS_fontBBox.R_bottom	
		call	SWordToAscii			; write bottom
		stosb
		mov	bx, tgs.TGS_fontBBox.R_right	
		call	SWordToAscii			; write right
		stosb
		mov	bx, tgs.TGS_fontBBox.R_top	
		call	SWordToAscii			; write top
		call	EmitBuffer
		mov	bx, tgs.TGS_stream		
		EmitPS	emitBBDef			; close bracket def
		EmitPS	cpend				; close dictionary
		pop	ds, es				; es -> PSType3
							; ds -> PageFonts
		; output the name of the font

		mov	si, tgs.TGS_pageFonts.chunk	; deref chunk again
		mov	si, ds:[si]
		add	si, tgs.TGS_nchars		; add in chunk offset
		mov	cl, ds:[si].PF_nlen		; get length of name
		clr	ch
		mov	dx, si				
		add	dx, offset PF_name		; ds:dx -> name
		clr	al				; handle errors
		call	SendToStream

		push	ds
		segmov	ds, es
		EmitPS	emitDefineFont			; make it official
		pop	ds

		; finished with the resource now...

		mov	bx, handle PSType3		; release resource
		call	MemUnlock

		.leave
		ret
DownloadFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CountCharsToDownload
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Count the #chars that we will be downloading

CALLED BY:	INTERNAL
		DownloadFont

PASS:		ds:si	- pointer to PageFont entry for font to download

RETURN:		cx	- #chars in PF_map
		dx	- code of highest #char

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each bit set in the PF_map field,
		    inc the count

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CountCharsToDownload	proc	near
		uses	si, ax, bx
		.enter
		clr	cx				; start at beginning
		clr	bx				; to determine done
		clr	dx				; to determine done
		mov	al, 0x80			; initial bit mask
		add	si, offset PF_map
testNextBit:
		test	ds:[si], al			; check bit
		jz	nextBit
		inc	cx				; one more to download
		mov	dx, bx				; update maximum
nextBit:
		inc	bx				; on to next one
		tst	bh				; when non-zero, done
		jnz	done
		shr	al, 1				; to next bit
		jnc	testNextBit
		mov	al, 0x80
		inc	si
		jmp	testNextBit
done:
		.leave
		ret
CountCharsToDownload	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DownloadFontHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out some PostScript for the font header

CALLED BY:	INTERNAL
		DownloadFont

PASS:		tgs	- stack frame
		cx	= #chars to download
		dx	= max char code we're downloading
		ds:si	- pointer to PageFont structure block

RETURN:		es	- pointer to locked PSType3 resource. 
			  caller should unlock

DESTROYED:	cx, dx, bx, ax, di

PSEUDO CODE/STRATEGY:
		yeah, copy some PS code over

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DownloadFontHeader	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; create the font header.  first lock the right resrouce

		push	ds				; save pointer to font
		push	cx				; save #chars
		mov	bx, tgs.TGS_pageFonts.chunk	; deref chunk handle
		mov	bx, ds:[bx]
		sub	bx, si				; get offset
		neg	bx				;  into chunk
		mov	tgs.TGS_nchars, bx		; save it (reuse var)
		mov	bx, handle PSType3		; get resource
		call	MemLock				; lock it down
		mov	ds, ax				; ds -> resource

;		mov	bx, tgs.TGS_stream		; get stream blk handle
;		EmitPS	emitVMtest			; write out code to 
							;  check for enuf mem
;		pop	bx				; restore #chars
;		push	bx				; save #chars
							; reserve 1K/char +
							;  some overhead
;		shr	bx, 1				; about 1/2K per char
;		add	bx, DOWNLOAD_FONT_OVERHEAD + MINIMUM_PS_VM_REQUIRED
		segmov	es, ss, di			; set up buffer
		lea	di, tgs.TGS_buffer		; es:di -> space
;		call	UWordToAscii			; this many 1000s
;		call	EmitBuffer			; write it out

		mov	dx, offset beginType3Header
		mov	cx, offset endType3Header - offset beginType3Header
		mov	bx, tgs.TGS_stream		; get stream blk handle
		clr	al
		call	SendToStream

		; set up CharProcs dictionary

		EmitPS	emitCPstart			; define the CharProcs
		pop	bx
		inc	bx				; for .notdef
		lea	di, tgs.TGS_buffer		; es:di -> space
		call	UWordToAscii			; this many entries
		call	EmitBuffer			; write it out

		mov	dx, offset beginCPdefine
		mov	cx, offset endCPdefine - offset beginCPdefine
		mov	bx, tgs.TGS_stream		; get stream blk handle
		clr	al
		call	SendToStream

		; emit info about encoding vector

		mov	dx, offset beginEVdefine
		mov	cx, offset endEVdefine - offset beginEVdefine
		mov	bx, tgs.TGS_stream		; get stream blk handle
		clr	al
		call	SendToStream

		segmov	es, ds, ax			; put it here for later
		pop	ds				; ds:si -> font entry

		.leave
		ret
DownloadFontHeader	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitFontCharacters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out all the chars for a font

CALLED BY:	INTERNAL
		DownloadFont

PASS:		ds	- pointer to PageFont structure block
		dx	- GState handle

RETURN:		bx	- pointer to chunk where PageFont structure is

DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
		For each character in the PF_map:
		    EmitCharacter

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitFontCharacters	proc	near
tgs		local	TGSLocals
		.enter	inherit

		clr	ax				; start at beginning
		mov	cl, 0x80			; initial bit mask
		mov	bx, tgs.TGS_pageFonts.chunk	; dereference chunk
		mov	bx, ds:[bx]			;
		mov	di, tgs.TGS_nchars		; add offset into chunk
		add	di, offset PF_map
testNextChar:
		test	ds:[bx][di], cl			; check bit
		jz	nextChar
		xchg	di, dx				; di = GState
		call	GrSaveState
		mov	bx, tgs.TGS_chunk.handle	; chunk can move after
		call	MemDerefDS			; ...GString op
		xchg	di, dx
		call	EmitCharacter			; emit encoding info
		xchg	di, dx
		call	GrRestoreState
		xchg	di, dx
		mov	bx, tgs.TGS_chunk.handle	; chunk can move after
		call	MemDerefDS			; ...GString op
		mov	bx, tgs.TGS_pageFonts.chunk	; dereference chunk
		mov	bx, ds:[bx]
nextChar:
		inc	ax				; on to next one
		tst	ah				; when non-zero, done
		jnz	done
		shr	cl, 1				; to next bit
		jnc	testNextChar
		mov	cl, 0x80
		inc	di
		jmp	testNextChar
done:
		.leave
		ret
EmitFontCharacters	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a line to set the encoding for a character

CALLED BY:	INTERNAL
		DownloadFont

PASS:		al	- character code
		ds:bx	- pointer to chunk with PageFont info
		TGS_nchars - offset into chunk of current PageFont struct
		tgs	- inherited stack frame
		dx, di	- gstate to use

RETURN:		ds	- points to same segment (may have moved)

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		write out the PS necc to draw the character
		something like:

			/c97 {0 0 m 0 1 l ....  F} bind def

		We'll get the information about the drawing commands from
		calls into the font driver.

		Also, we need to keep running track of the overall font 
		bounding box, and save off the font matrix.  Both of these
		pieces of info are returned by the font driver for each char.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitCharacter	proc	near
		uses	ax, cx, dx, di, es
tgs		local	TGSLocals
		.enter	inherit

		; write out the beginning stuff

		push	dx			; save GState handle
		mov	dl, al			; dl = char code
		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer space
		mov	{byte} es:[di], '/'	; write as name
		mov	{byte} es:[di+1], 'c'	; write as name
		add	di, 2
		push	bx
		mov	bl, al
		clr	bh
		call	UWordToAscii		; complete name
		pop	bx
		mov	al, ' '			; space separator
		mov	ah, '<'			; open hex string brace
		stosw

		; set up a graphics string to put the char path into.  
		; first zero out the chunk we're going to use.

		mov	ax, tgs.TGS_chunk.chunk	; resize it to zero
		clr	cx
		call	LMemReAlloc		; ds already points there
		mov	bx, tgs.TGS_chunk.handle ; release block while writing
		call	MemUnlock

		pop	bx			; restore GState handle
		push	di			; save buffer offset

		; call the font driver to get the path description
		; dl already has character to get

		mov	di, bx			; di = GState handle
		mov	ax, DR_FONT_GEN_PATH	; 
		mov	cl, mask FGPF_POSTSCRIPT
		clr	dh
		call	GrCallFontDriver	; get char path

		; since we have the block locked that was drawn into, it
		; may have moved.  Get the address once again.

		mov	bx, tgs.TGS_chunk.handle ; relock the block
		call	MemLock	
		mov	ds, ax

		; OK, now the chunk at tgs.TGS_chunk has the graphics string
		; in it, this consists of:
		;
		; 	GR_COMMENT  wx  wy  llx  lly  urx  ury
		;	GR_APPLY_TRANSLATION x y
		; 	GR_APPLY_TRANSFORM  transmatrix
		; 	{ drawing commands }
		;
		; we need to do a few things.  First, update the fontBBox 
		; with this new info about the size of this character.  Then
		; scan through the graphics string and emit args/operators

		pop	di			; restore buffer offset
		mov	si, tgs.TGS_chunk.chunk	; get chunk handle
		ChunkSizeHandle ds, si, dx	; load chunk size into dx
		cmp	dx, 0			; if zero, nothing to do
		LONG jz	doneChar		;   just exit
		mov	si, ds:[si]		; deref handle
		add	dx, si			; dx = byte after chunk end
		lodsb				; get byte
EC <		cmp	al, GR_COMMENT		; looking for a good comment >
EC <		ERROR_NE PS_BAD_CHAR_PATH				     >
		lodsw				; load size info
EC <		cmp	ax, size CharSizeInfo	; should be 6 words	     >
EC <		ERROR_NE PS_BAD_CHAR_PATH				     >
		mov	bx, ds:[si].CSI_wx	; set up to write width
		call	HexEncodeSWord		; write it out
		mov	bx, ds:[si].CSI_wy	; set up to write height
		call	HexEncodeSWord		; write it out
		mov	bx, ds:[si].CSI_llx	; get bounds info
		cmp	tgs.TGS_fontBBox.R_left, bx ; see if we should update
		jle	leftUpdated		;  no, continue
		mov	tgs.TGS_fontBBox.R_left, bx
leftUpdated:
		call	HexEncodeSWord		; write out left bounds
		mov	bx, ds:[si].CSI_lly	; get bounds info
		cmp	tgs.TGS_fontBBox.R_bottom, bx ; see if we should update
		jle	bottomUpdated		;  no, continue
		mov	tgs.TGS_fontBBox.R_bottom, bx
bottomUpdated:
		call	HexEncodeSWord		; write out left bounds
		mov	bx, ds:[si].CSI_urx	; get bounds info
		cmp	tgs.TGS_fontBBox.R_right, bx ; see if we should update
		jge	rightUpdated		;  no, continue
		mov	tgs.TGS_fontBBox.R_right, bx
rightUpdated:
		call	HexEncodeSWord		; write out left bounds
		mov	bx, ds:[si].CSI_ury	; get bounds info
		cmp	tgs.TGS_fontBBox.R_top, bx ; see if we should update
		jge	topUpdated		;  no, continue
		mov	tgs.TGS_fontBBox.R_top, bx
topUpdated:
		call	HexEncodeSWord		; write out left bounds
		mov	al, '0'
		mov	ah, HO_SETCACHE		; setcachedevice proc
		stosw				; 1 more space
		add	si, size CharSizeInfo + \
			    size OpApplyTranslation + \
			    size OpApplyTransform ; bump past GR_APPLY_TRANSFORM
		
		; finally, we're ready to output the path construction operators
		; loop until we're done with the whole chunk
		; at this point:
		;	ds:si -> first path construction operator
		;	ds:dx -> first byte past end of chunk
		;	es:di -> pointer into buffer to write PS code
		; the path construction operators include (for version 1.2)
		;    	GR_DRAW_LINE_TO, GR_MOVE_TO, GR_DRAW_HLINE_TO,
		;	GR_DRAW_VLINE_TO, GR_DRAW_SPLINE
		; we will re-use the TGS_bmXres and Yres for the current pos


		mov	tgs.TGS_bmXres, 8000h	; current xpos
		mov	tgs.TGS_bmYres, 8000h	; current ypos
		clr	tgs.TGS_bmWidth		; clear translation
		clr	tgs.TGS_bmHeight	; clear translation
		cmp	si, dx			; if past end already, quit
		jae	doneChar
pathLoop:		
		mov	al, ds:[si]		; get next opcode
		mov	bx, offset cs:EmitLineto
		cmp	al, GR_DRAW_LINE_TO
		je	haveOpcode
		mov	bx, offset cs:EmitRelLineto
		cmp	al, GR_DRAW_REL_LINE_TO
		je	haveOpcode
		mov	bx, offset cs:EmitMoveto
		cmp	al, GR_MOVE_TO	
		je	haveOpcode
		mov	bx, offset cs:EmitHLineto
		cmp	al, GR_DRAW_HLINE_TO	
		je	haveOpcode
		mov	bx, offset cs:EmitVLineto
		cmp	al, GR_DRAW_VLINE_TO	
		je	haveOpcode
		mov	bx, offset cs:EmitTranslation
		cmp	al, GR_APPLY_TRANSLATION	
		je	haveOpcode
		mov	bx, offset cs:EmitCurveto
		cmp	al, GR_DRAW_CURVE_TO
		je	haveOpcode
		mov	bx, offset cs:EmitRelCurveto
		cmp	al, GR_DRAW_REL_CURVE_TO
		je	haveOpcode
		mov	bx, offset cs:EmitSpline
EC <		cmp	al, GR_DRAW_SPLINE			>
EC <		ERROR_NE PS_BAD_CHAR_PATH			>
haveOpcode:
		call	bx			; call handler, si updated
		mov	bx, tgs.TGS_chunk.handle ; just in case
		call	MemDerefDS		; ds -> PageFonts
		cmp	si, dx			; past end ?
		jb	pathLoop

		; done with chunk.  Output closing brace and other nice stuff

		mov	al, '0'
		mov	ah, HO_FILL		; fill the character
		stosw
doneChar:
		push	ds
		segmov	ds, cs, si
		mov	si, offset emitCharDef
		mov	cx, length emitCharDef
		rep	movsb
		pop	ds
		call	EmitBuffer		; write it out to the stream

		.leave
		ret
EmitCharacter	endp

emitCharDef	char	"> def", NL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitLineto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS lineto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpDrawLineTo
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpDrawLineTo
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			x y l

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		FOR 2.0.  we can optimize this by calculating deltax and 
			  deltay and using rlineto instead of lineto where
			  it is appropriate.  This would tend to decrease the 
			  size of the output stream.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_LINE_SIZE	equ	55

EmitLineto	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; update current position, output x

		mov	bx, ds:[si].ODLT_x2	; get x position
		add	bx, tgs.TGS_bmWidth	; apply translation
		mov	tgs.TGS_bmXres, bx	; update curXpos
		call	HexEncodeSWord		; output ascii rep
		mov	bx, ds:[si].ODLT_y2	; get y position
		add	bx, tgs.TGS_bmHeight	; apply translation
		mov	tgs.TGS_bmYres, bx	; update curYpos
		call	HexEncodeSWord		; output ascii rep
		mov	al, '0'
		mov	ah, HO_LINETO		; lineto command
		stosw				; final space
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buffer if over 70 chars
		jb	done
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		add	si, size OpDrawLineTo	; bump over element
		.leave
		ret
EmitLineto	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitRelLineto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS rlineto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpDrawRelLineTo
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpDrawRelLineTo
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			x y rl

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitRelLineto	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; update current position, output x

		mov	bx, ds:[si].ODRLT_x2.WWF_int	; get x position
		tst	ds:[si].ODRLT_x2.WWF_frac	; round if needed
		jns	haveXoff
		inc	bx
haveXoff:
;		add	bx, tgs.TGS_bmWidth	; apply translation
;		mov	tgs.TGS_bmXres, bx	; update curXpos
		add	tgs.TGS_bmXres, bx	; update curXpos
		call	HexEncodeSWord		; output ascii rep
		mov	bx, ds:[si].ODRLT_y2.WWF_int	; get y position
		tst	ds:[si].ODRLT_y2.WWF_frac	; round if needed
		jns	haveYoff
		inc	bx
haveYoff:
;		add	bx, tgs.TGS_bmHeight	; apply translation
;		mov	tgs.TGS_bmYres, bx	; update curYpos
		add	tgs.TGS_bmYres, bx	; update curYpos
		call	HexEncodeSWord		; output ascii rep
		mov	al, '0'
		mov	ah, HO_RLINETO		; lineto command
		stosw				; final space
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buff if over 70 chars
		jb	done
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		add	si, size OpDrawRelLineTo	; bump over element
		.leave
		ret
EmitRelLineto	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitMoveto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS moveto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpMoveTo
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpMoveTo
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			x y m

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		FOR 2.0.  we can optimize this by calculating deltax and 
			  deltay and using rlineto instead of lineto where
			  it is appropriate.  This would tend to decrease the 
			  size of the output stream.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitMoveto	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; update current position, output x

		mov	bx, ds:[si].OMT_x1	; get x position
		add	bx, tgs.TGS_bmWidth	; apply translation
		mov	ax, ds:[si].OMT_y1
		add	ax, tgs.TGS_bmHeight	; apply translation
		cmp	bx, tgs.TGS_bmXres	; check to see if changed
		jne	doIt
		cmp	ax, tgs.TGS_bmYres
		je	done			; don't do anything if unchange
doIt:
		mov	tgs.TGS_bmXres, bx	; update curXpos
		call	HexEncodeSWord		; output ascii rep
		mov	bx, ax
		mov	tgs.TGS_bmYres, bx	; update curYpos
		call	HexEncodeSWord		; output ascii rep
		mov	al, '0'
		mov	ah, HO_MOVETO		; moveto command
		stosw				; final space
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buffer if over 70 chars
		jb	done
		mov	al, C_CR		; terminate line
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		add	si, size OpMoveTo	; bump past element
		.leave
		ret
EmitMoveto	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitHLineto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS lineto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpDrawHLineTo
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpDrawHLineTo
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			deltax 0 r

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitHLineto	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; update current position, output x

		mov	bx, ds:[si].ODHLT_x2	; get x position
		add	bx, tgs.TGS_bmWidth	; apply x translation
		mov	ax, bx			; save it
		xchg	ax, tgs.TGS_bmXres	; update curpos
		sub	bx, ax			; calc relative lineto
		call	HexEncodeSWord		; output ascii rep
		mov	al, '0'
		mov	ah, HO_HLINETO		; rlineto command
		stosw				; final space
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buffer if over 70 chars
		jb	done
		mov	al, C_CR		; terminate line
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		add	si, size OpDrawHLineTo	; bump past element
		.leave
		ret
EmitHLineto	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitVLineto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS lineto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpDrawVLineTo
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpDrawVLineTo
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			0 deltay r

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitVLineto	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; update current position, output x

		mov	bx, ds:[si].ODVLT_y2	; get y position
		add	bx, tgs.TGS_bmHeight	; apply translation
		mov	ax, bx			; save it
		xchg	ax, tgs.TGS_bmYres	; update curpos
		sub	bx, ax			; calc relative lineto
		call	HexEncodeSWord		; output ascii rep
		mov	al, '0'
		mov	ah, HO_VLINETO		; rlineto command
		stosw				; final space
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buffer if over 70 chars
		jb	done
		mov	al, C_CR		; terminate line
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		add	si, size OpDrawVLineTo	; bump past element
		.leave
		ret
EmitVLineto	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS curveto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpDrawSpline
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpDrawSpline
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			x y c

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		FOR 2.0.  we can optimize this by calculating deltax and 
			  deltay and using rlineto instead of lineto where
			  it is appropriate.  This would tend to decrease the 
			  size of the output stream.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitSpline	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; check to see if the first point is at the current position
		; (it should be).  If not, then output a moveto command.

EC <		cmp	ds:[si].ODS_count, 4	; should only be this many >
EC <		ERROR_NE PS_BAD_CHAR_PATH				   >
		add	si, size OpDrawSpline	; get to the data
		lodsw				; make sure we're at the current
		mov	bx, ax			;   point
		lodsw
		add	bx, tgs.TGS_bmWidth	; add in translation
		cmp	bx, tgs.TGS_bmXres	; check x coord
		jne	outputMoveto
		add	ax, tgs.TGS_bmHeight	; add in translation
		cmp	ax, tgs.TGS_bmYres	; check y coord
		je	doneMoveto
outputMoveto:
		add	bx, tgs.TGS_bmWidth	; apply any translation
		call	HexEncodeSWord		; write out x coord
		mov	bx, ax			; write out y coord
		add	bx, tgs.TGS_bmHeight	; apply any translation
		call	HexEncodeSWord
		mov	al, '0'
		mov	ah, HO_MOVETO
		stosw

		; output the three coords and a curveto command
doneMoveto:
		mov	ax, ds:[si+8]		; update curpos first
		add	ax, tgs.TGS_bmWidth	; add in translation
		mov	tgs.TGS_bmXres, ax
		mov	ax, ds:[si+10]
		add	ax, tgs.TGS_bmHeight	; add in translation
		mov	tgs.TGS_bmYres, ax
		call	OutputCoordPair
		call	OutputCoordPair
		call	OutputCoordPair
		mov	al, '0'
		mov	ah, HO_CURVETO		; write curveto command
		stosw
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buffer if over 70 chars
		jb	done
		mov	al, C_CR		; terminate line
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		.leave
		ret
EmitSpline	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitCurveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS curveto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpDrawCurveTo
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpDrawCurveTo
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			x2 y2 x3 y3 x4 y4 c

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitCurveto	proc	near
tgs		local	TGSLocals
		.enter	inherit

		; output the three coords and a curveto command

		mov	ax, ds:[si].ODCVT_x4	; update curpos first
		add	ax, tgs.TGS_bmWidth	; add in translation
		mov	tgs.TGS_bmXres, ax
		mov	ax, ds:[si].ODCVT_y4
		add	ax, tgs.TGS_bmHeight	; add in translation
		mov	tgs.TGS_bmYres, ax
		add	si, offset ODCVT_x2
		call	OutputCoordPair
		call	OutputCoordPair
		call	OutputCoordPair
		mov	al, '0'
		mov	ah, HO_CURVETO		; write curveto command
		stosw
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buffer if over 70 chars
		jb	done
		mov	al, C_CR		; terminate line
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		.leave
		ret
EmitCurveto	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitRelCurveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	write out a PS curveto command

CALLED BY:	INTERNAL
		EmitCharacter

PASS:		ds:si	- points to OpDrawRelCurveTo
		es:di	- where to write postscript

RETURN:		ds:si	- points after OpDrawRelCurveTo
		es:di	- where to write next postscript code

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
		write out:
			x2 y2 x3 y3 x4 y4 rc

		update current position

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitRelCurveto	proc	near
tgs		local	TGSLocals
		.enter	inherit

		
		; output the three offsets and an rcurveto command

		mov	ax, ds:[si].ODRCVT_x4	; update curpos first
		add	tgs.TGS_bmXres, ax
		mov	ax, ds:[si].ODRCVT_y4
		add	tgs.TGS_bmYres, ax
		add	si, offset ODRCVT_x2
		call	OutputRelCoordPair
		call	OutputRelCoordPair
		call	OutputRelCoordPair
		mov	al, '0'
		mov	ah, HO_RCURVETO		; write curveto command
		stosw
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, MAX_LINE_SIZE	; output buffer if over 70 chars
		jb	done
		mov	al, C_CR		; terminate line
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
done:
		.leave
		ret
EmitRelCurveto	endp


;	simple utility routine to read/write a pair of coords
OutputRelCoordPair	proc	near
tgs		local	TGSLocals
		.enter	inherit
		lodsw	
		mov	bx, ax
		call	HexEncodeSWord
		lodsw
		mov	bx, ax
		call	HexEncodeSWord
		.leave
		ret
OutputRelCoordPair	endp
;	simple utility routine to read/write a pair of coords
OutputCoordPair	proc	near
tgs		local	TGSLocals
		.enter	inherit
		lodsw	
		add	ax, tgs.TGS_bmWidth
		mov	bx, ax
		call	HexEncodeSWord
		lodsw
		add	ax, tgs.TGS_bmHeight
		mov	bx, ax
		call	HexEncodeSWord
		.leave
		ret
OutputCoordPair	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		ds:si	- points to OpApplyTranslation

RETURN:		ds:si	- points to next element

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		just store away the translation

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitTranslation	proc	near
tgs		local	TGSLocals
		.enter	inherit

		mov	ax, ds:[si].OAT_x.WWF_int
		add	tgs.TGS_bmWidth, ax
		mov	ax, ds:[si].OAT_y.WWF_int
		add	tgs.TGS_bmHeight, ax
		add	si, size OpApplyTranslation

		.leave
		ret
EmitTranslation	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HexEncodeSWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change an SWord value to hex-encoded ascii

CALLED BY:	INTERNAL
		various routines

PASS:		bx	- value to convert
		es:di	- buffer pointer to put hex ascii

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		This assumes the following encoding of values

		 0x0e-0xea     - -110 thru 110  (0 = 7c)
		 0xeb-0xff     - -1100 thru 1100 (0 = f5)

		So, for values whose absolute value is less than or equal
		to 110, we output two hex digits.  For larger values, we 
		decompose the value into at least four hex digits

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HexEncodeSWord	proc	near
		uses	ax, bx, cx
		.enter

		; check to see if abs value is less than 110

		mov	ax, bx			; save value
		tst	ax
		jns	haveAbsValue
		neg	ax
haveAbsValue:
		mov	cx, HO_DIGITS_RANGE	; divide by 110
		div	cl			; ah = remainder

		; if original number was negative, then negate both remainder
		; and quotient

		tst	bx
		jns	haveValuesToWrite
		neg	al
		neg	ah

		; OK, we have what we need.  First write out the single digit
haveValuesToWrite:
		push	ax			; save other digit
		mov	al, ah			; do remainder first
		add	al, HO_DIGITS_ZERO	; normalize it to encoded
		call	ByteToHexAscii		;  value

		; next we need to keep writing 110s til we've accounted 
		; for the entire value

		pop	cx			; restore value to cl
		clr	ch			; we already did the remainder
		jcxz	done			; nothing to write

		; OK, we have the 110s digit to do.  It's probably only one
		; but we'll need to check to make sure.
do110s:
		cmp	cl, HO_110S_LOW		; check low side
		jl	handleNeg
		cmp	cl, HO_110S_HIGH	;   and high side
		jg	handlePos
		add	cl, HO_110S_ZERO	; normalize it
		mov	al, cl
		call	ByteToHexAscii
done:
		.leave
		ret

		; number is way negative.  Do something
handleNeg:
		mov	al, HO_110S_LOW	+ HO_110S_ZERO	; write out a -10
		call	ByteToHexAscii
		add	cl, 10			; smaller number now
		jmp	do110s

		; number is way positive.  Do something
handlePos:
		mov	al, HO_110S_HIGH + HO_110S_ZERO	; write out a 10
		call	ByteToHexAscii
		sub	cl, 10			; smaller number now
		jmp	do110s

HexEncodeSWord	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EmitEncoding
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a line to set the encoding for a character

CALLED BY:	INTERNAL
		DownloadFont

PASS:		es	- locked PSType3 data resource
		tgs	- inherited stack frame
		ds	- pointer to PageFont entry

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		write out a packed array that hold the character values
		and some code to deal with it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EmitEncoding	proc	near
		uses	ax, bx, cx, si, di
tgs		local	TGSLocals
		.enter	inherit

		; for each character that we're going to download, put out 
		; a line something like
		;	Encoding 128 /80 put
		; the "/80" is the internal name of the character.  Usually,
		; it's given some interesting name like "/space" or 
		; "/percent", but since this is all internal, let's stay with
		; small names to keep memory usage low. and are easy to 
		; generate algorithmically.

		push	ds			; save font seg
		push	es			; save PSType3 seg
		segmov	es, ss, di		; es:di -> buffer
		lea	di, tgs.TGS_buffer
		mov	al, '<'			; start hex string
		stosb
		mov	si, tgs.TGS_pageFonts.chunk ; ds:si -> font
		mov	si, ds:[si]
		add	si, tgs.TGS_nchars	; ds:si -> PageFont entry
		clr	bx			; start at beginning
		mov	cl, 0x80		; initial bit mask
		add	si, offset PF_map
testNextBit:
		test	ds:[si], cl		; check bit
		jz	nextBit
		push	bx
		mov	al, bl			; output hex bytes
		call	ByteToHexAscii
		pop	bx
		lea	ax, tgs.TGS_buffer	; see if we're full yet
		sub	ax, di			; check buffer size
		neg	ax
		cmp	ax, 70			; output buffer if over 70 chars
		jb	nextBit
		mov	al, C_CR		; terminate line
		mov	ah, C_LF
		stosw
		call	EmitBuffer
		lea	di, tgs.TGS_buffer	; reset pointer
nextBit:
		inc	bx			; on to next one
		tst	bh			; when non-zero, done
		jnz	done
		shr	cl, 1			; to next bit
		jnc	testNextBit
		mov	cl, 0x80
		inc	si
		jmp	testNextBit

		; done with all the characters.  close out the array and 
		; do the actual encoding.
done:
		call	EmitBuffer
		pop	ds			; ds -> PSType3 
		mov	dx, offset emitEAend
		mov	cx, length emitEAend
		clr	al
		mov	bx, tgs.TGS_stream
		call	SendToStream
		segmov	es,ds,si 
		pop	ds	
		.leave
		ret
EmitEncoding	endp

ExportType3Font	ends
