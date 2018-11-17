
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		textPrintStyleRun.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	PrintText		Print a text string
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	7/19/92		Initial revision


DESCRIPTION:
	This file contains most of the code to implement the 
	print driver ascii text support

	$Id: textPrintStyleRun.asm,v 1.1 97/04/18 11:50:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStyleRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PrintText prints a text string pointed at by es:si

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE
		ax	- X offset into paper to print for this tile.
		cx	- Y offset into paper to print for this tile.
		dx:si	- structure holding the style run info.

RETURN: 	carry	- set if some error sending string to printer

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:
	take the position, style, font info, and set it at the printer,
	then print a string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintStyleRun	proc	far
	uses	ax,bx,cx,dx,si,ds,es,di
	.enter
	mov	es,bp			;PState in es......
	mov	ds,dx			;get the style run info segment into ds.

		;set the cursor position first.....
	sub	ax,es:[PS_currentMargins].PM_left	;fix up the X tile pos.
	neg	ax
	add	ax,ds:[si].SRI_xPosition ;integer x pos.
	mov	dx,ds:[si].SRI_yPosition ;integer y pos.
	test	es:[PS_paperInput],mask PIO_TRACTOR	;check paper type....
	jnz	tiled			;if tractor, then skip correction.
	sub	cx,es:[PS_currentMargins].PM_top ;add the top margin to correct
					;for the tile value passed in ax
	sub	dx,cx			;get rid of tile offset.
tiled:
	mov	cx,ax			;transfer the X pos.
	clr	ax
	push	si
	mov	si,ax			;clear fractions for now.
	call	PrintSetCursor		;set the cursor position.
	pop	si
	jc	exit			;pass erros out.

	mov	ax,ds:[si].SRI_attributes ;number of attribute element
ifndef	SET_CURSOR_MODIFIES_FONT
	cmp	ax,es:PS_previousAttribute ;see if the attribute number is the
					;same for this run.
	jne	getStringMetrics	;if so, skip setting the font, etc....
					;we only need to set what ever the 
					;PrintSetCursor routine nuked.
	push	si			;save the address of the StyleRunInfo
	jmp	setStyles

getStringMetrics:
endif
	push	ax			;save element #
	mov	dx,ds:[si].SRI_stringWidth.WBF_int
if PZ_PCGEOS
	;
	; count full-width characters as double
	; XXX: fix this check when we know which chars a full-width in the
	;      printer font
	;
	;      fixed. though this way is SJIS spesific, I think.
 	;      sigh :-(  C_PARAGRAPH_SIGN U+0xb6, SJIS 0x81f7
	mov	bx,ds:[si].SRI_numChars    ;get average char width.
	mov	cx, bx
	push	si
	add	si, offset SRI_text
doubleLoop:
	lodsw
	cmp	ax, C_DELETE
	jbe	halfWidth
;	cmp	ax, C_HIRAGANA_LETTER_SMALL_A
;	jb	halfWidth
	cmp	ax, C_HALFWIDTH_IDEOGRAPHIC_PERIOD
	jb	fullWidth
	cmp	ax, C_FULLWIDTH_CENT_SIGN
	jb	halfWidth
fullWidth:
	inc	bx
halfWidth:
	loop	doubleLoop
	pop	si 
	clr	ax
	mov	ch,ds:[si].SRI_stringWidth.WBF_frac
	clr	cl
else
	mov	ch,ds:[si].SRI_stringWidth.WBF_frac
	clr	cl
	clr	ax
	mov	bx,ds:[si].SRI_numChars    ;get average char width.
endif
	call	GrUDivWWFixed		;do division
	pop	ax			;get back the element #
	push	si			;save the address of the StyleRunInfo
	mov	si,ds:TS_textAttributeInfo ;get handle of element array
	call	ChunkArrayElementToPtr	;get address.

	mov	bx,dx			;get in the divisor registers
	mov	ax,cx

if 0
;----------------------------------------------------------------------
		;REMOVED THIS TEST DJD 12-6-92
		;OK when we have screen equivalent fonts for proportional
		;ASCII printing.

		;here we need to detect whether we have a proportional font or
		;not, and set the pitch to 0 if proportional.
	mov	cx,ds:[di].TAI_font	;get FontID
	mov	dx,(mask FEF_FAMILY or mask FEF_OUTLINES or (FF_MONO shl 8))
	call	GrCheckFontAvail
	cmp	cx,FID_INVALID		;if proportional...
	jne	finishSettingPitch
	clr	bl
	jmp	setFont

		;ALL FONTS ARE FIXED PITCH DJD 12-6-92
		;if here, then the font is fixed pitch. get the char widths.
		;and then convert to a pitch x 10 value.
		;set the font for this run.
		;bx.ax = average char width for this run.
finishSettingPitch:
;----------------------------------------------------------------------
endif

	clr	cx
	mov	dx,720
	call	GrUDivWWFixed		;do division
	mov	bx,dx			;bx.ax is now the Pitch....
	test	cx,8000h		;see if round ness.
	jz	rounded
	inc	bx
rounded:
	test	bh,bh			;see if the pitch is out of range.
	jz	setFont
	mov	bl,255			;just suggest max range.
		;now we have all the info to set a printer font.
		;cx = FontID
		;dx = point size
		;bl = pitch x 10 cpi (0 if proportional)
setFont:
	mov	cx,ds:[di].TAI_font	;get FontID
	mov	dx,ds:[di].TAI_size.WBF_int     ;get Font size.
	call	PrintSetFont		;set up the font.
	jc	beforePop		;pass any error out.

		;set up the color of the text.
	mov	al,ds:[di].TAI_color.RGB_red
	mov	dl,ds:[di].TAI_color.RGB_green
	mov	dh,ds:[di].TAI_color.RGB_blue
	call	PrintSetColor
	jc	beforePop		;pass any error out.

		;set the style bits for this style run.
setStyles:
	mov	dx,ds:[di].TAI_style	
	call	PrintSetStyles

beforePop:
	pop	si			;get back the SRI address.
	jc	exit

	mov	cx,ds:[si].SRI_numChars
	add	si,SRI_text		;set up offset
	mov	dx,ds			;set up segment
					;bp should still be the PState
	call	PrintText		;send out the buffer.
exit:
	.leave
	ret
PrintStyleRun	endp

