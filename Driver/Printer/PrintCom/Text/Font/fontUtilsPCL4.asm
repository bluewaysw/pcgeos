COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		LaserJet Font Driver
FILE:		fontUtilsPCL4.asm

AUTHOR:		Gene Anderson, Apr 16, 1990
		Dave Durran, Apr 16, 1991

ROUTINES:
	Name			Description
	----			-----------

	PointsToPCL		Convert points to PCL dots (72nds to 300ths)
	PointsToPCL4		Convert points to PCL 1/4 dots

	ConvertTextStyles	Convert PrintTextStyles to GEOS & HP styles

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/16/90		Initial revision
	Dave	4/16/91		New Initial revision
	Dave	1/92		Moved from Laserdwn

DESCRIPTION:
	Utility routines for LaserJet printer driver.

	$Id: fontUtilsPCL4.asm,v 1.1 97/04/18 11:49:53 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointsToPCL, PointsToPCL4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert points (72/inch) to PCL dots (300/inch)
CALLED BY:	UTILITY

PASS:		dx.ah - value (points)
RETURN:		PointsToPCL:
		    ax - converted value (PCL dots)
		PointsToPCL4:
		    ax - converted value (PCL 1/4 dots)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoHPScale	proc	near
	mov	bx, dx
	clr	al				;bx.ax <- value
	mov	dx, HP_SCALE_FACTOR_HIGH
	mov	cx, HP_SCALE_FACTOR_LOW		;dx.cx <- scale factor
	call	GrMulWWFixed
	ret
DoHPScale	endp

PointsToPCL4	proc	near
	push	bx, cx, dx
	call	DoHPScale
	sal	cx, 1
	rcl	dx, 1				;*2
	sal	cx, 1
	rcl	dx, 1				;*4
	jmp	AfterScale
PointsToPCL4	endp

PointsToPCL	proc	near
	push	bx, cx, dx
	call	DoHPScale

AfterScale	label	near
	add	cx, 0x8000
	adc	dx, 0x0000			;round to integer
	mov	ax, dx				;ax <- scaled value
	pop	bx, cx, dx
	ret
PointsToPCL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertTextStyles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert PrinterTextStyles to GEOS styles & HP styles
CALLED BY:	UTILITY

PASS:		ax - PrinterTextStyles
RETURN:		al - TextStyles
		dl - HPFontStyles (plain/italic)
		dh - HPStrokeWeights (normal/bold)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		NOTE: underline is handled differently - it is sent as a 
		style rather than a font.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConvertTextStyles	proc	near
	uses	cx
	.enter

	mov	cx, ax
	clr	al
	mov	dx, HPFS_UPRIGHT or (HPSW_BOOK shl 8)
	test	cx, mask PTS_ITALIC		;see if italic
	jz	notItalic
	mov	dl, HPFS_ITALIC			;set italic style
	ornf	al, mask TS_ITALIC		;al <- italic
notItalic:
	test	cx, mask PTS_BOLD		;see if bold
	jz	notBold
	mov	dh, HPSW_BOLD			;set bold weight
	ornf	al, mask TS_BOLD		;al <- bold
notBold:
	test	cx, mask PTS_SUBSCRIPT		;see if Subscript
	jz	notSubscript
	ornf	al, mask TS_SUBSCRIPT		;al <- Subscript
	jmp	notSuperscript
notSubscript:
	test	cx, mask PTS_SUPERSCRIPT		;see if Superscript
	jz	notSuperscript
	ornf	al, mask TS_SUPERSCRIPT		;al <- Superscript
notSuperscript:
	test	cx, mask PTS_STRIKETHRU		;see if Strikethru
	jz	notStrikethru
	ornf	al, mask TS_STRIKE_THRU		;al <- Strikethru
notStrikethru:

	.leave
	ret
ConvertTextStyles	endp
