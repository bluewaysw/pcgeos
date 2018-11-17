COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Driver		
FILE:		fontTestPCL4.asm

AUTHOR:		Dave Durran, Apr 16, 1991

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/92		Moved from Laserdwn

DESCRIPTION:
	Routines for creating and downloading HP soft fonts.

	$Id: fontDownloadPCL4.asm,v 1.1 97/04/18 11:49:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFontHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create HP soft font header.
CALLED BY:	FontAddFace

PASS:		ds:si - ptr to SoftFontEntry
RETURN:		HPFontHeader created (ds:HPFI_header)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/90		Initial version
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateFontHeader	proc	near
	uses	ax, bx, cx, dx, si, di
curJob	local	FontDriverInfo
	.enter	inherit

	clr	di				;di <- no window
	call	GrCreateState			;make me a GState
	mov	bx, offset ds:HPFI_header 	;ds:bx <- ptr to chunk
	;
	; Set the GEOS font ID & pointsize. The pointsize
	; is set to the size in PCL dots (300ths of an inch)
	; so that conversion of font metrics & data is unnecessary,
	; and the metrics exactly match the data in printer dots.
	;
	mov	dx, ds:[si].SFE_pointsize	;dx.ah <- pointsize
	clr	ah
	call	PointsToPCL			;convert to PCL
	mov	dx, ax
	clr	ah
	mov	cx, ds:[si].SFE_fontID		;cx <- font ID
	call	GrSetFont			;set new font
	;
	; Set style information:
	;
	mov	ax, ds:[si].SFE_style		;ax <- PrinterTextStyles
	call	ConvertTextStyles
	mov	ah, 0xff			;clear all styles
	call	GrSetTextStyle			;set text styles
	mov	ds:[bx].HPFH_style, dl		;upright or italic
	mov	ds:[bx].HPFH_weight, dh		;normal or bold
	;
	; Set custom width and weight.
	;
	mov	al,ds:[si].SFE_optFontEntry.OFE_fontWidth
	call	GrSetFontWidth
	mov	al,ds:[si].SFE_optFontEntry.OFE_fontWeight
	call	GrSetFontWeight
	;
	; Set miscellaneous information:
	;
	mov	ax,size HPFontHeader
	xchg	al,ah				;Big Endian 68000 in LaserJet
	mov	ds:[bx].HPFH_size, ax		;size in bytes of font header.
	mov	al,curJob.FDI_HPtypeface
	mov	ds:[bx].HPFH_fontID, al		;HPFontID
	mov	ds:[bx].HPFH_fontType, HPFT_8_BIT_256_CHARS ;PC-8 type.
	mov	ds:[bx].HPFH_symbolSet, HPCS_PC_8 ;PC-8 type.
	mov	ds:[bx].HPFH_spacing, HPS_PROPORTIONAL 	;always set proportional
	mov	ds:[bx].HPFH_pitch, 0x7800	;should not matter!!!!!! 
	mov	al, ds:[si].SFE_orientation	;al <- orientation
	mov	ds:[bx].HPFH_orientation, al	;<- portrait or landscape
	;
	; Set reserved fields
	;
	clr	ax
	mov	ds:[bx].HPFH_res05, al
	mov	ds:[bx].HPFH_res1, ax 
	mov	ds:[bx].HPFH_res2, ax 
	mov	ds:[bx].HPFH_res3, ax 
	mov	ds:[bx].HPFH_res4, ax 
	mov	ds:[bx].HPFH_res5, ax 
	mov	ds:[bx].HPFH_res6, ax 
	mov	ds:[bx].HPFH_res7, ax 
	mov	ds:[bx].HPFH_res8, al
	;the following misc. fields are set to zero......
	mov	ds:[bx].HPFH_widthType, al	;HPWT_NORMAL
	mov	ds:[bx].HPFH_serifStyle, al	;HPSS_SANS_SERIF_SQUARE
	mov	ds:[bx].HPFH_pitchExt, al	;0
	mov	ds:[bx].HPFH_heightExt, al	;0
	;
	; Set font metrics information:
	;
	mov	dx, ds:[si].SFE_pointsize
	clr	ah
	call	PointsToPCL4			;convert points to PCL 1/4 pts
	xchg	al,ah				;Big Endian 68000
	mov	ds:[bx].HPFH_textHeight, ax	;<- inter-line spacing (PCL4)

	mov	si, GFMI_UNDER_THICKNESS
	call	GetFontInfoPCL
	mov	ds:[bx].HPFH_underThick, ah	;<- underline thickness (PCL)

        mov     si, GFMI_BASELINE
	call	GetFontInfoPCL
	mov	dl,ah
	mov	dh,al			;dx is baseline offset from cell top.
	mov	si, GFMI_UNDER_POS
        call    GetFontInfoPCL
	xchg	al,ah 			;ax is the underline off. from cell top.
	sub	dx,ax
	mov	ds:[bx].HPFH_underDist, dl	;<- underline position (PCL)
						;relative to baseline.

	mov	si, GFMI_MEAN
	call	GetFontInfoPCL4
	mov	ds:[bx].HPFH_x_height, ax	;<- mean / x-height (PCL4)

	mov	si, GFMI_AVERAGE_WIDTH
	call	GetFontInfoPCL4
	mov	ds:[bx].HPFH_textWidth, ax	;<- average width (PCL4)

	call	GetFontBounds			;load the cell height, width,
						;and baseline dist.

	call	GrDestroyState			;done with GState

	.leave
	ret
CreateFontHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFontInfoPCL, GetFontInfoPCL4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get fontm metrics info in PCL dots or PCL 1/4 dots.
CALLED BY:	CreateFontHeader

PASS:		si - info to get (GFM_info)
		di - handle of GState
RETURN:		GetFontInfo:
		    ax - information (in PCL dots)
		GetFontInfo4:
		    ax - information (in PCL 1/4 dots)
	NOTE: the info is byte swapped for the BigEndian 68000
DESTROYED:

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/90		Initial version
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetFontInfoPCL	proc	near
	push	dx
	ornf	si, GFMI_ROUNDED
	call	GrFontMetrics
	mov	al, dh				;ax <- font info
	mov	ah, dl				;Big Endian 68000 in LaserJet
	pop	dx
	ret
GetFontInfoPCL	endp

GetFontInfoPCL4	proc	near
	push	dx
	call	GrFontMetrics
	sal	ah, 1
	rcl	dx, 1				;*2
	sal	ah, 1
	rcl	dx, 1				;*4
	add	ah, 0x80
	adc	dx, 0x0000			;round to integer
	mov	al, dh				;ax <- font info
	mov	ah, dl				;Big Endian 68000 in LaserJet
	pop	dx
	ret
GetFontInfoPCL4	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendFontHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Download HP soft font header.
CALLED BY:	FontAddFace

PASS:		ds:si - ptr to SoftFontEntry
RETURN:		carry - set if download failed
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Downloaded soft fonts are marked as permanent, to
	avoid having them deleted when a soft reset is done, either by
	the printer driver or by the pin-header user.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/90		Initial version
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SendFontHeader	proc	near
	uses	ax, bx, cx, si, di, es
curJob	local	FontDriverInfo
	.enter	inherit

	;
	; Set the current font and notify the printer we
	; are downloading a soft font.
	;
	mov	ax, ds:[si].SFE_fontTag		;ax <- printer font ID
	mov	di, offset pr_codes_SetFontID	;set font ID
	call	WriteNumCommand
	mov	di, offset pr_codes_SendFont	;prepare to send font header
	mov	al, size HPFontHeader		;al <- # to insert (size)
	call	WriteNumByteCommand
	;
	; Download the font header & mark the font as temporary:
	;
	mov	si, offset HPFI_header		;si <- header offset
	mov	es, curJob.FDI_pstate		;es <- seg addr of PState
	mov	cx, size HPFontHeader		;cx <- # of bytes (=64)
	call	PrintStreamWrite		;send font header

	;mov	di, offset pr_codes_FontControl	;mark font as permanent
	;mov	al, HPFC_MAKE_FONT_TEMPORARY	;al <- HPFontControls
	;call	WriteNumByteCommand

	.leave
	ret
SendFontHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DownloadCharData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create & download character data to the printer
CALLED BY:	FontAddChar

PASS: 		al - character to send
		es:di - pointer to SOft Font Entry
RETURN:		carry - set if error
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/16/90		Initial version
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


DownloadCharData	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
curJob	local	FontDriverInfo
	.enter	inherit

		;mov the SFE pointer to ds:si.
	segmov	ds,es
	mov	si,di				;these will be trashed later.

		;get the PState pointer for the printstream driver utilities
		;below.
	mov	es,curJob.FDI_pstate

		;Set the font ID to load the character to.
	push	ax
	mov	ax, ds:[si].SFE_fontTag		;ax <- printer font ID
	mov	di, offset pr_codes_SetFontID	;set font ID
	call	WriteNumCommand			;send the control code out.
	pop	ax

	mov	curJob.FDI_characterCode,al	;save the ASCII code.

	mov	di, offset pr_codes_SelectChar	;set ASCII code to assign
	call	WriteNumByteCommand		;send the control code out.

	mov	dx, ds:[si].SFE_optFontEntry.OFE_trackKern	;+ get this fonts track Kern.
	mov	curJob.FDI_currTrackKern,dx	;+ save in curJob stack frame

	call	GetCharBounds			;get character bounds

;----------------------------------------------------------------------------
;Send the first (maybe the only) band of data from the character bitmap here.
;----------------------------------------------------------------------------
	call	SetUpCharBitmap			;get the character slice.
	LONG jc	errorExit


		;Get the size in bytes of the bitmap data for this band.
	mov	cx,curJob.FDI_charBandSize
		;Send the "I'm going to download a Char" control code + the
		;header bytes for starting a character.
	mov	ax,cx
	add	ax,size HPCharHeader		;add the size of the Header
	mov	di,offset cs:pr_codes_SendChar
	call	WriteNumCommand			;send the control code out.

		;finish loading the constant info into the character header.
	mov	curJob.FDI_CharHeader.HPCH_format,HPCF_STANDARD
	mov	curJob.FDI_CharHeader.HPCH_continuation,HPCF_START
	mov	curJob.FDI_CharHeader.HPCH_size,14
	mov	curJob.FDI_CharHeader.HPCH_class,HPCC_NORMAL
	mov	curJob.FDI_CharHeader.HPCH_orientation,HPO_PORTRAIT
	mov	curJob.FDI_CharHeader.HPCH_res1,0

		;Send the header information for this character.
	push	ds,si,cx
	segmov	ds,ss,cx
	mov	cx,size HPCharHeader
	lea	si,curJob.FDI_CharHeader
		;ds:si	- header data source
		;cx	- size of header to send 
		;es	- PState Segment
	call	PrintStreamWrite		;Send the header.
	pop	ds,si,cx

	push	cx
        mov     cx,es:[PS_swath].[B_height] ;get the number of scanlines.

charBandLoop:
                ;ds:si  - input bitmap data source (beginning of scanline)
                ;es     - PSTATE segment
        push    cx              ;save height of bitmap.
                ;determine the live print width of this scanline.
                ;optimized PrScanBuffer Routine (once/scanline).
        mov     cx,es:PS_bandBWidth ;get the width of the screen input buffer.
                ;send the scanline out
                ;cx     - number of bytes in this scanline.
                ;ds:si  - input bitmap data source (beginning of scanline)
                ;es     - PSTATE segment
        call    PrintStreamWrite        ;send them out.
                ;do another scanline.
        pop     cx
        cmp     cx,1                    ;see if that was the last line.
        je      endCharBand
        inc     es:[PS_newScanNumber]   ;point at next scanline element.
        call    DerefAScanline          ;ds:si --> next scan line.
        loop    charBandLoop

endCharBand:
	pop	cx

	mov	cx,curJob.FDI_numCharBands	;how many more are we sending?
	dec	cx				;minus the first one....
	jcxz	allDone
bandLoop:
	push	cx
;----------------------------------------------------------------------------
;Send successive (maybe the last) band of data from the character bitmap here.
;----------------------------------------------------------------------------
        call    HugeArrayUnlock         ;get rid of last locked block in
	mov	ds,curJob.FDI_sfontSeg	;get the pointer to SoftFontEntry.
	mov	si,curJob.FDI_sfontOff	;get the pointer to SoftFontEntry.
	mov	di,curJob.FDI_gstateHandle	;get the GState hand.
	mov	ax,curJob.FDI_currentYOffset	;get offset to draw.
	sub	ax,curJob.FDI_charBandHeight	;adjust for this slice.
	mov	curJob.FDI_currentYOffset,ax	;save away.
	call	GrClearBitmap			;clear out remnants of last...
	call	DrawTheCharacter		;put the character in the bitmap
        clr     ax                      ;set color number to zero (monochrome)
        mov     es:[PS_curColorNumber],ax
        call    DerefFirstScanline              ;get the pointer to data

	jc	errorExitInLoop

		;Get the size in bytes of the bitmap data for this band.
	mov	cx,curJob.FDI_charBandSize

		;Send the "I'm going to download a Char" control code + the
		;header bytes for continuing a character.
	mov	ax,cx
	add	ax,2				;plus 2 bytes for cont. hdr.
	mov	di,offset cs:pr_codes_ContinueChar
	call	WriteNumCommand			;send the header info out.

        mov     cx,es:[PS_swath].[B_height] ;get the number of scanlines.

contCharBandLoop:
                ;ds:si  - input bitmap data source (beginning of scanline)
                ;es     - PSTATE segment
        push    cx              ;save height of bitmap.
                ;determine the live print width of this scanline.
                ;optimized PrScanBuffer Routine (once/scanline).
        mov     cx,es:PS_bandBWidth ;get the width of the screen input buffer.
                ;send the scanline out
                ;cx     - number of bytes in this scanline.
                ;ds:si  - input bitmap data source (beginning of scanline)
                ;es     - PSTATE segment
        call    PrintStreamWrite        ;send them out.
                ;do another scanline.
        pop     cx
        cmp     cx,1                    ;see if that was the last line.
        je      endContCharBand
        inc     es:[PS_newScanNumber]   ;point at next scanline element.
        call    DerefAScanline          ;ds:si --> next scan line.
        loop    contCharBandLoop

endContCharBand:
	pop	cx

	loop	bandLoop			;dec cx, branch
allDone:
	call	CleanUpCharBitmap	;free the bitmap memory, and destroy it
	clc
errorExit:
	.leave
	ret
errorExitInLoop:
	pop	cx		;adjust stack.
	jmp	errorExit
DownloadCharData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateCharBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a bitmap for drawing a download character.
CALLED BY:	DownloadCharData

PASS:		cx - width of char data (in bits)
		dx - height of char data
RETURN:		if carry clear:
		    ax - handle of Bitmap
		    bx - handle of Window
		    di - handle of GState
		    cx - # of bitmap bands to draw character
		    dx - height of each band
		else:
		    ax - error code (BMCreateErrors)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	size = height * width/8;
	# bands = (size + 16383) / 16384

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Since we can only handle 64K blocks, and the LaserBiplane can
	only handle 32K blocks, we may need to break the bitmap up into
	several bands. To be on the safe side (and not hose the system
	by making 32K blocks), the blocks are limited to 16K instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/14/90		Initial version
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateCharBitmap	proc	near

curJob	local	FontDriverInfo
	.enter	inherit	

	push	cx, dx
	mov	ax, cx				;ax <- width (in bits)
	add	ax, 0x7				;round up to next byte
	shr	ax, 1
	shr	ax, 1
	shr	ax, 1				;ax <- width (in bytes)
	mul	dx				;dx:ax <- size (in bytes)
	add	ax, MAX_BITMAP_SIZE-1
	adc	dx, 0				;round to multiple of 16K
	mov	cx, MAX_BITMAP_OFFSET		;/16384
divLoop:
	sar	dx, 1
	rcr	ax, 1				;/2
	loop	divLoop
EC <	tst	dx				;>
EC <	ERROR_NZ	HP_CHAR_TOO_BIG		;character too fucking big>
	pop	cx, dx				;cx <- width of char
	push	ax				;save # of bands
	mov	bx,ax
	mov	ax, dx				;ax <- height of char
	clr	dx
	div	bx				;ax <- height of each band
	mov	dx, ax				;dx <- height of bitmap

	push	dx				;save for very end.
	mov	al, BMF_MONO
        call    GeodeGetProcessHandle
        mov     di, bx
        mov     bx,curJob.FDI_fileHandle
        call    GrCreateBitmap                  ;
        mov     curJob.FDI_bitmapHandle, ax            ; save bm han for later
        mov     curJob.FDI_gstateHandle, di           ; save gstate han
        call    GrGetWinHandle                  ; ax = window handle
        mov     curJob.FDI_windowHandle, ax         ; save it

	clr	dx
        mov     ax, mask BM_CLUSTERED_DITHER    ; use clustered mode
        call    GrSetBitmapMode                 ; set clustered dither

                ; at this point, the window is invalid, since WinOpen (via
                ; GrCreateBitmap) creates it that way.  This is bad, since
                ; we're not going to get any MSG_META_EXPOSED for it (not being
                ; a real process).  So lets fake an update now.
        call    GrBeginUpdate                   ; start it
        call    GrEndUpdate                     ; end it
	pop	dx				;recover the height.
	mov	ax,curJob.FDI_bitmapHandle	;ax - handle of Bitmap
	mov	bx,curJob.FDI_windowHandle	;bx - handle of Window
	mov	di,curJob.FDI_gstateHandle	;di - handle of GState
	pop	cx				;cx <- # of bands

	.leave
	ret
CreateCharBitmap	endp

cbFileName      char    "cbuf.bm", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTheCharacter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of character data & real width.
CALLED BY:	DownloadCharData()

PASS:		FDI_characterCode - character to use
		FDI_currentYOffset - current offset for the band of the char.
		FDI_currTrackKern - set to reflect the width of char.
		di - GState handle
		ss:bp - inherited locals from DownloadCharData
		ds:si - pointer to SoftFontEntry
RETURN:	
DESTROYED:

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawTheCharacter	proc	near
	uses	ax,bx,cx,dx,ds,si
curJob	local	FontDriverInfo
	.enter	inherit
	; Set the GEOS font ID & pointsize. The pointsize
	; is set to the size in PCL dots (300ths of an inch)
	; so that conversion of font metrics & data is unnecessary,
	; and the metrics exactly match the data in printer dots.
	;
	call	SetTextAttrs			;set new font

	;set the mode to draw in to the baseline offset.
	mov	al,mask TM_DRAW_BASE
	mov	ah,mask TM_DRAW_BOTTOM or mask TM_DRAW_ACCENT or mask TM_DRAW_OPTIONAL_HYPHENS	;reset these flags.
	call	GrSetTextMode
	mov	ax,curJob.FDI_CharHeader.HPCH_leftOffset
	xchg	al,ah
	sub	ax,curJob.FDI_currTrackKern	;+ discount the track Kerning.
	neg	ax
	mov	bx,curJob.FDI_currentYOffset
	clr	dh
	mov	dl,curJob.FDI_characterCode
	call	GrDrawChar
	.leave
	ret
DrawTheCharacter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                GetFontBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Create HP soft font header bounding box and baseline offset.
CALLED BY:      FontAddFace

PASS:           ds:bx - ptr to chunk containing HPFontHeader
		di - GState handle
RETURN:         HPFontHeader metrics created 
DESTROYED:      none

PSEUDO CODE/STRATEGY:
		go through all printable characters to find the largest limits
		of each metric.
		CAUTION: the metric values can not be greater than +-32K
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        Dave    10/91            Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetFontBounds        proc    near
        uses    ax, cx, dx, si, es
curJob  local   FontDriverInfo
        .enter  inherit

;init the values to compare the cell boundaries to.
	clr	ax				;init the metrics scratch space
	mov	curJob.FDI_currentWidth,ax
	mov	curJob.FDI_currentYOffset,ax
	dec	ax				;there has to be a descender.
	mov	curJob.FDI_currentDes,ax

;check to see if the style is subscript, if so, extend the cell height to 
;include the x-height area for the strikethru style.
	mov	es,curJob.FDI_pstate		;es-->PState segment.
	mov	dx,es:PS_asciiStyle		;get styles word.
	and	dx,(mask PTS_SUBSCRIPT or mask PTS_STRIKETHRU)
	cmp	dx,(mask PTS_SUBSCRIPT or mask PTS_STRIKETHRU)
	jne	afterSubInit
	mov	si, GFMI_MEAN or GFMI_ROUNDED
	call	GrFontMetrics			;return x-height in dx.
	mov	curJob.FDI_currentYOffset,dx	;see if larger than previous
afterSubInit:

	; following instruction done above
	;mov	al,255				;start at the end of the set.
	clr	ah
metricsLoop:
        mov     si, GCMI_MIN_X or GCMI_ROUNDED		;get the left offset.
        call    GrCharMetrics
        mov     cx, dx 
        mov     si, GCMI_MAX_X or GCMI_ROUNDED
        call    GrCharMetrics
        sub     dx, cx 				;obtain the character width.
	add	dx,7				;round to byte boundary.
	and	dx,0xfff8
        cmp     curJob.FDI_currentWidth, dx 	;see if larger than previous
	jge	afterWidth			;width.
        mov     curJob.FDI_currentWidth, dx 	;replace with the new larger
						;width.
afterWidth:
        mov     si, GCMI_MAX_Y or GCMI_ROUNDED
        call    GrCharMetrics
	cmp	curJob.FDI_currentYOffset,dx	;see if larger than previous
	jge	afterBaseline			;Baseline offset.
	mov	curJob.FDI_currentYOffset,dx	;replace with the new larger
						;Offset.
afterBaseline:
        mov     si, GCMI_MIN_Y or GCMI_ROUNDED
        call    GrCharMetrics
 	cmp     curJob.FDI_currentDes,dx	;see if larger than previous
        jle     afterHeight			;Descender distance.
        mov     curJob.FDI_currentDes,dx	;replace with the new larger
                                                ;distance.
afterHeight:

	dec	al				;point at next character.
	cmp	al,C_SPACE			;see if we have reached space.
	jne	metricsLoop

;Store the new found dimensions into the font header.
	mov	ax,curJob.FDI_currentYOffset
	sub	ax,curJob.FDI_currentDes
	inc	ax				;PCL baseline compensation.
	mov	dh,al
	mov	dl,ah
	mov	ds:[bx].HPFH_cheight,dx		;store the cell height.
	sal	ax,1
	sal	ax,1
	xchg	al,ah
	mov	ds:[bx].HPFH_height,ax		;store the PCL4 height.
	mov	ax,curJob.FDI_currentWidth
	xchg	ah,al
	mov	ds:[bx].HPFH_cwidth,ax		;store the cell width.
	mov	ax,curJob.FDI_currentYOffset
	inc	ax				;PCL baseline compensation.
	xchg	ah,al
	mov	ds:[bx].HPFH_baseline,ax	;store the baseline distance.

	.leave
	ret
GetFontBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCharBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of character data & real width.
CALLED BY:	DownloadCharData()

PASS:		al - character to use
		ss:bp - inherited locals from DownloadCharData
RETURN:		cx - width (in pixels)
		dx - height (in scanlines)
		HPCH_CharHeader - bounds of character data
		curJob.FDI_currTrackKern altered to suit the delta x of this 
			character.
DESTROYED:	bx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/14/90		Initial version
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCharBounds	proc	near
	uses	si, es
curJob	local	FontDriverInfo
	.enter	inherit
	mov	es,curJob.FDI_pstate		;es-->PState segment.

	clr	di				;di <- no Window
	call	GrCreateState			;make me a GState
	call	SetTextAttrs
	;
	; Get the character bounds:
	;
	clr	ah
	call	GrCharWidth
	mov	cx,dx				;+ save for negative case
	add	dx,curJob.FDI_currTrackKern	;+ see if the track kerning
	jge	dxIsOK				;+
	clr	curJob.FDI_currTrackKern	;+ zero the temp Kern value
	mov	dx,cx				;+ recover the orig. dx
dxIsOK:						;+
	sal	ah,1
	rcl	dx,1				;quarter dot units.
	sal	ah,1
	rcl	dx,1				
	clr	ah				;for the GrCharMetrics rout.
	xchg	dl,dh				;Big Endian 68000 in LaserJet
	mov	curJob.FDI_CharHeader.HPCH_deltaX, dx		;store max x
	mov	si, GCMI_MIN_X or GCMI_ROUNDED
	call	GrCharMetrics
	add	dx,curJob.FDI_currTrackKern	;+ adjust to the track Kerning
	mov	curJob.FDI_CharHeader.HPCH_leftOffset, dx ;store LSB / min x
	mov	si, GCMI_MAX_X or GCMI_ROUNDED
	call	GrCharMetrics
	add	dx,curJob.FDI_currTrackKern	;+ adjust to the track Kerning
	mov	cx, dx					;cx <- right
	mov	si, GCMI_MIN_Y or GCMI_ROUNDED
	call	GrCharMetrics
	mov	bx, dx					;bx <- bottom

;check to see if the style is superscript, if so, extend the cell height to 
;include the x-height area for the strikethru style.
	mov	dx,es:PS_asciiStyle		;get styles word.
	and	dx,(mask PTS_SUPERSCRIPT or mask PTS_STRIKETHRU)
	cmp	dx,(mask PTS_SUPERSCRIPT or mask PTS_STRIKETHRU)
	jne	afterSuperAdjust
	clr	bx				;make baseline the bottom of 
						;char cell.
afterSuperAdjust:

	mov	si, GCMI_MAX_Y or GCMI_ROUNDED
	call	GrCharMetrics
	mov	curJob.FDI_currentYOffset,dx		;init the current YPos.

;check to see if the style is subscript, if so, extend the cell height to 
;include the x-height area for the strikethru style.
	mov	dx,es:PS_asciiStyle		;get styles word.
	and	dx,(mask PTS_SUBSCRIPT or mask PTS_STRIKETHRU)
	cmp	dx,(mask PTS_SUBSCRIPT or mask PTS_STRIKETHRU)
	jne	afterSubAdjust
	mov	si, GFMI_MEAN or GFMI_ROUNDED
	call	GrFontMetrics			;return x-height in dx.
	cmp	curJob.FDI_currentYOffset,dx	;see if larger than previous
	jge	afterSubAdjust			;Baseline offset.
	mov	curJob.FDI_currentYOffset,dx	;see if larger than previous
afterSubAdjust:

	mov	dx,curJob.FDI_currentYOffset	;recover the current YPos.
	inc	dx				;take the zero line into acc.
	mov	ax,dx
	xchg	al,ah				;Big Endian 68000 in LaserJet
	mov	curJob.FDI_CharHeader.HPCH_topOffset, ax ;store ascent / max y
	sub	dx, bx				;dx <- height
	mov	al,dh				;Big Endian 68000 in LaserJet
	mov	ah,dl				;Big Endian 68000 in LaserJet
	mov	curJob.FDI_CharHeader.HPCH_charHeight,ax ;store Height (max y - min y)
	sub	cx, curJob.FDI_CharHeader.HPCH_leftOffset	;cx <- width
	add	cx,7				;round up the number of bits
	and	cx,0xfff8			;to an even byte boundary.
	mov	al,ch				;Big Endian 68000 in LaserJet
	mov	ah,cl				;Big Endian 68000 in LaserJet
	mov	curJob.FDI_CharHeader.HPCH_charWidth,ax ;store width (max x - min x)
	mov	ax, curJob.FDI_CharHeader.HPCH_leftOffset	;ax <- width
	xchg	al,ah				;Big Endian 68000 in LaserJet
	mov	curJob.FDI_CharHeader.HPCH_leftOffset,ax	;ax <- width
	call	GrDestroyState

	.leave
	ret
GetCharBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpCharBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the Character bitmap
CALLED BY:	DownloadCharData

PASS:	curJob.FDI_CharHeader.HPCH_charWidth - width of char data (in bits)
	curJob.FDI_CharHeader.HPCH_charHeight - height of char data
		FDI_currTrackKern - set to reflect the width of char.
	FDI_sfontSeg:FDI_sfontOff	-	address of SoftFontEntry.
RETURN:		
	ds:si			-	address of bitmap data.
	curJob.FDI_numCharBands	-	number of bands 
	curJob.FDI_gstateHandle	-	GState handle
	curJob.FDI_windowHandle	-	window handle
	curJob.FDI_bitmapHandle	-	bitmap handle
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetUpCharBitmap	proc	near
	uses	ax,bx,cx,dx
curJob	local	FontDriverInfo
	.enter	inherit

	mov	ds,curJob.FDI_sfontSeg	;get the pointer to SoftFontEntry.
	mov	si,curJob.FDI_sfontOff	;get the pointer to SoftFontEntry.
	mov	cx,curJob.FDI_CharHeader.HPCH_charWidth
	xchg	cl,ch
	mov	dx,curJob.FDI_CharHeader.HPCH_charHeight
	xchg	dl,dh
	call	CreateCharBitmap		;create bitmap
	mov	curJob.FDI_charBandHeight,dx	;save slice height.
	jc	allocFailed			;branch if allocation failed
	call	DrawTheCharacter		;put the character in the bitmap
	mov	curJob.FDI_numCharBands,cx	;how many bands are we sending?
	mov	curJob.FDI_gstateHandle,di	;save away the GState hand.
	mov	curJob.FDI_windowHandle, bx	;save window handle
	mov	curJob.FDI_bitmapHandle, ax	;save bitmap handle


	mov	es,curJob.FDI_pstate		;set es ->PState

                ; load the bitmap header into the PState
	mov	cx,ax			;Bitmap handle from above
	mov	dx,curJob.FDI_fileHandle ;file handle
        call    LoadSwathHeader         ; bitmap header into PS_swath

                ; get width, and calculate byte width of bitmap
        mov     ax, es:[PS_swath].B_width
        add     ax, 7                   ; round up to next byte boundary
        and     al, 0xf8
        mov     es:[PS_bandWidth], ax   ; load the dot width.
        mov     cl, 3                   ; divide by 8....
        shr     ax, cl                  ; to obtain the byte width.
        mov     es:[PS_bandBWidth], ax

                ; calculate the #bytes/charband
        mov     bx,es:[PS_swath].B_height ; get the height of bitmap.
        clr     dx                      ; dx:ax = divisor
        mul     bx			    ;get number of bands in this
        mov     curJob.FDI_charBandSize,ax      ;swath for counter.

        clr     ax                      ;set color number to zero (monochrome)
        mov     es:[PS_curColorNumber],ax

        call    DerefFirstScanline              ;get the pointer to data


;	ds:si	- input bitmap data source (beginning of scanline)

allocFailed:
	.leave
	ret
SetUpCharBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CleanUpCharBitmap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroy the Character bitmap
CALLED BY:	DownloadCharData

PASS:	
	ds:si - Huge array bitmap address.
	curJob.FDI_gstateHandle	-	GState handle
	curJob.FDI_windowHandle	-	window handle
	curJob.FDI_bitmapHandle	-	bitmap handle
RETURN:		
	nothing
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	9/91		Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CleanUpCharBitmap	proc	near
	uses	ax,bx,cx,dx
curJob	local	FontDriverInfo
	.enter	inherit
        call    HugeArrayUnlock         ;get rid of last locked block in
                                        ;huge array.
        mov     di, curJob.FDI_gstateHandle           ; setup to kill bitmap
        mov     al, BMD_KILL_DATA
        call    GrDestroyBitmap

	clc					;indicate no error
	.leave
	ret
CleanUpCharBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the font, size and text style for a font.
CALLED BY:	GetCharBounds

PASS:		ds:si - ptr to SoftFontEntry
		di - handle of GState
RETURN:		none
DESTROYED:	bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/14/90		Initial version
	Dave	8/91		New Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetTextAttrs	proc	near
	uses	ax,bx,cx,dx
	.enter

	;
	; Set the pointsize
	;
	mov	dx, ds:[si].SFE_pointsize	;dx.ah <- pointsize
	clr	ah
	call	PointsToPCL			;convert to PCL
	mov	dx, ax
	clr	ah				;dx.ah <- pointsize
	mov	cx, ds:[si].SFE_fontID		;cx <- font ID
	call	GrSetFont			;set new font
	;
	; Set style information:
	;
	mov	ax, ds:[si].SFE_style		;ax <- PrinterTextStyles
	call	ConvertTextStyles
	mov	ah, 0xff			;clear all styles
	call	GrSetTextStyle			;set text styles

	;
	; Set custom width and weight.
	;
	mov	al,ds:[si].SFE_optFontEntry.OFE_fontWidth
	call	GrSetFontWidth
	mov	al,ds:[si].SFE_optFontEntry.OFE_fontWeight
	call	GrSetFontWeight

	mov	ah,CF_RGB	;set to draw in RGB values.
	mov	al,ds:[si].SFE_optFontEntry.OFE_color.RGB_red
	mov	bl,ds:[si].SFE_optFontEntry.OFE_color.RGB_green
	mov	bh,ds:[si].SFE_optFontEntry.OFE_color.RGB_blue
	call	GrSetTextColor

	.leave
	ret
SetTextAttrs	endp
