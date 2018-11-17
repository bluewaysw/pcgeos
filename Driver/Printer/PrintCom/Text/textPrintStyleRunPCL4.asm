
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		textPrintStyleRunPCL4.asm

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

	$Id: textPrintStyleRunPCL4.asm,v 1.1 97/04/18 11:50:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintStyleRun
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PrintText prints a text string pointed at by es:si

CALLED BY: 	GLOBAL

PASS: 		bp	- Segment of PSTATE
                ax      - X offset into paper to print for this tile.
                cx      - Y offset into paper to print for this tile.
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
	sub	ax,es:[PS_currentMargins].PM_left	;adjust X pos.
	neg	ax
		;set the cursor position first.....
	add	ax,ds:[si].SRI_xPosition ;integer x pos.
	mov	dx,ds:[si].SRI_yPosition ;integer y pos.
        test    es:[PS_paperInput],mask PIO_TRACTOR     ;check paper type....
        jnz     tiled                   ;if tractor, then skip correction.
        sub     cx,es:[PS_currentMargins].PM_top ;add the top margin to correct
                                       ;for the tile value passed in ax
        sub     dx,cx                   ;get rid of tile offset.
tiled:
	mov	cx,ax			;get x pos from ax
	clr	ax
	push	si
	mov	si,ax			;clear fractions for now.
	call	PrintSetCursor		;set the cursor position.
	pop	si
	LONG jc	exit			;pass erros out.

	mov	ax,ds:[si].SRI_attributes ;number of attribute element
	cmp	ax,es:PS_previousAttribute ;see if the attribute number is the
					;same for this run.
	LONG je	sendTheChars		;if so, skip setting the font, etc....
	mov	es:PS_previousAttribute,ax ;load new previous attribute #
	push	ax			;save element #
	mov	dx,ds:[si].SRI_stringWidth.WBF_int
	mov	ch,ds:[si].SRI_stringWidth.WBF_frac
	clr	cl
	clr	ax
	mov	bx,ds:[si].SRI_numChars    ;get average char width.
	call	GrUDivWWFixed		;do division
	pop	ax			;get back the element #
	push	si			;save the address of the StyleRunInfo
	mov	si,ds:TS_textAttributeInfo ;get handle of element array
	call	ChunkArrayElementToPtr	;get address.

	mov	bx,dx			;get in the divisor registers
	mov	ax,cx

		;here we need to detect whether we have a proportional font or
		;not, and set the pitch to 0 if proportional.
	mov	cx,ds:[di].TAI_font	;get FontID
	mov	dx,(mask FEF_FAMILY or mask FEF_OUTLINES or (FF_MONO shl 8))
	call	GrCheckFontAvail
	cmp	cx,FID_INVALID		;if proportional...
	jne	finishSettingPitch
	clr	bl
	jmp	setFont

		;if here, then the font is fixed pitch. get the char widths.
		;and then convert to a pitch x 10 value.
		;set the font for this run.
		;bx.ax = average char width for this run.
finishSettingPitch:
	clr	cx
	mov	dx,720
	call	GrUDivWWFixed		;do division
	mov	bx,dx			;bx.ax is now the Pitch....
	test	ax,8000h		;see if round ness.
	jz	rounded
	inc	bx
rounded:
	test	bh,bh			;see if the pitch is out of range.
	jz	setFont
	mov	bl,255			;just suggest max range.
		;now we set all the info to set a printer font.
		;cx = FontID
		;dx = point size
		;bl = pitch x 10 cpi (0 if proportional)
		;di = style bits.
setFont:
		;we need to go throught the font variables and load them into
		;the PState for later use. The pitch, size, and fontID are
		;passed in registers, so they get loaded into the PState by
		;PrintSetFontInt.
	mov	cx,ds:[di].TAI_font	;get FontID
	mov	dx,ds:[di].TAI_size.WBF_int     ;get Font size.
	mov	es,bp			;es --> PState address
	mov	al,ds:[di].TAI_color.RGB_red
	mov	es:[PS_curOptFont].[OFE_color].RGB_red,al
	mov	al,ds:[di].TAI_color.RGB_green
	mov	es:[PS_curOptFont].[OFE_color].RGB_green,al
	mov	al,ds:[di].TAI_color.RGB_blue
	mov	es:[PS_curOptFont].[OFE_color].RGB_blue,al
	mov	ax,ds:[di].TAI_spacePad.WBF_int
	mov	es:[PS_curOptFont].[OFE_spacePad],ax
	mov	al,ds:[di].TAI_fontWeight
	mov	es:[PS_curOptFont].[OFE_fontWeight],al
	mov	al,ds:[di].TAI_fontWidth
	mov	es:[PS_curOptFont].[OFE_fontWidth],al
	mov	ax,ds:[di].TAI_trackKern
	mov	es:[PS_curOptFont].[OFE_trackKern],ax
	mov	ax,ds:[di].TAI_style	
        mov     es:PS_asciiStyle,ax
	call	PrintSetFontInt		;set up the font.
	jc	beforePop		;pass any error out.

	call	PrintSetStylesInt	;pich the underline bit out, and set..

beforePop:
	pop	si			;get back the SRI address.
	jc	exit
sendTheChars:
	mov	cx,ds:[si].SRI_numChars	;cx = length of string.
	mov	dx,ds			;get dx:si pointing at text string.
	add	si,SRI_text
	call	PrintText		;send out the buffer.
exit:
	.leave
	ret
PrintStyleRun	endp

