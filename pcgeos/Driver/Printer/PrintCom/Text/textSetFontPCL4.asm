
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		laserjet print driver
FILE:		textSetFontPCL4.asm

AUTHOR:		Dave Durran

ROUTINES:
	Name			Description
	----			-----------

	PrintSetFont		Set a new text mode font
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	1/22/92		Initial revision from laserdwnText.asm


DESCRIPTION:
	This file contains most of the code to implement the PCL 4
	print driver ascii text support

	$Id: textSetFontPCL4.asm,v 1.1 97/04/18 11:49:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrintSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a new font for text mode

CALLED BY: 	GLOBAL

PASS: 		bp	- (es for PrintSetFontInt) Segment of PSTATE	
		bl	- desired pitch value (0 for Proportional)
		cx	- desired font ID
		dx	- desired font size (points)
	additional for PrintSetFontInt
		ax.bh	- WBFixed space padding
		si	- custom spacing
		di	- requested style word

RETURN: 	nothing

DESTROYED: 	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Dave	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintSetFont	proc	far
	uses	es
	.enter
	mov	es,bp		;es--->PState
	call	PrintSetFontInt
	.leave
	ret
PrintSetFont	endp
PrintSetFontInt	proc	near
        mov     es:[PS_curFont].[FE_pitch],bl ;set real pitch
	mov	es:PS_curFont.FE_fontID,cx	;store for later.
	mov	es:PS_curFont.FE_size,dx	;store for later.
        cmp     es:PS_printerSmart,PS_DUMB_RASTER ;see if we can download font
        jne      exit	                        ;if not, skip.
	call	PrintSetFontWayInt
exit:
	ret
PrintSetFontInt	endp

PrintSetFontWayInt	proc	near
	uses	ax,cx,dx,si,di
	.enter
		;set the font using the LaserJet's font selection algorhythim.
	mov	al,es:[PS_curFont].[FE_pitch]
	test	al,al				;0 if proportional.
	jnz	handlePitch
	inc	al				;set to 1 for HP Prop.
	mov	di,offset pr_codes_SetResidentProportional
	jmp	startSetting

handlePitch:
	clr	ah
	mov	cl,10				;pitch is kept x 10
	div	cl
	mov	di,offset pr_codes_SetResidentFixed ;start selection.....

startSetting:
	call	WriteNumByteCommand		;send either the pitch or prop
	jc	exit				;exit on an error.

	mov	ax,es:PS_curFont.FE_size	;get the pointsize...
	call	HexToAsciiStreamWrite
	jc	exit				;exit on an error.
	mov	cl,"v"				;set the Pointsize....
	call	PrintStreamWriteByte
	jc	exit				;exit on an error.

	mov	ax,es:PS_asciiStyle		;get the style word...
	mov	si,offset pr_codes_SetResidentUpright ;assume plain
	test	ax,mask PTS_ITALIC		;see if italic.
	jz	italicSet
	mov	si,offset pr_codes_SetResidentItalic ;Set italic

italicSet:
	call	SendCodeOut
	jc	exit				;exit on an error.
	mov	si,offset pr_codes_SetResidentMedium ;assume plain.....
	test	ax,mask PTS_BOLD
	jz	boldSet
	mov	si,offset pr_codes_SetResidentBold	;Set bold....

boldSet:
	call	SendCodeOut
	jc	exit				;exit on an error.
	mov	si,0				;init the table index.
	mov	ax,es:PS_curFont.FE_fontID	;get the requested ID.

fontIDLoop:
	cmp	cs:[si].fontIDTab,FID_INVALID	;see if at end.
	je	loadTypeface			;if so, load default.
	cmp	ax,cs:[si].fontIDTab		;see if this is the right ID.
	je	loadTypeface			;if so, load HP equiv.
	add	si,2				;point at next entry.
	jmp	fontIDLoop			;do again.....

loadTypeface:
	mov	ax,cs:[si].typefaceTab
	call	HexToAsciiStreamWrite
	jc	exit				;exit on an error.
	mov	cl,"T"
	call	PrintStreamWriteByte

exit:
	.leave
	ret
PrintSetFontWayInt	endp

