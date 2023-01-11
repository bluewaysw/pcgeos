COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		TrueType Font Driver
FILE:		truetypeWidths.asm

AUTHOR:		Falk Rehwagen, Jan 29, 2021

ROUTINES:
	Name			Description
	----			-----------
EXT	TrueTypeGenWidths	Generate font header and widths for a font.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	29/1/21		Initial revision

DESCRIPTION:
	Implements a font driver for:
		The TrueType outline fonts

	$Id: truetypeWidths.asm,v 1.1 97/04/18 11:45:30 bluewaysw Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeGenWidths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the character width table for a font.
CALLED BY:	EXTERNAL: GrFindFont

PASS:		di - 0 for new font; handle to rebuild old font (P'd)
		es - seg addr of gstate (locked)
			GS_fontAttr - font attributes
		bp:cx - transformation matrix (TMatrix)
		ds - seg addr of font info block
RETURN:		bx - handle of font (locked)
		ax - seg addr of font (locked)
		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	di is the bx passed to TrueTypeStrategy.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	29/1/21		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeGenWidths	proc	far
	uses	cx, dx, si, di, ds, es, bp

	mov	bx, bp
	.enter
	
	push	di		; font handle or 0

	push	bx		; send tMatrix ptr
	push 	cx
		
				; find font info
	mov	cx, es:GS_fontAttr.FCA_fontID
	call	FontDrFindFontInfo
	push	ds		; pass font info ptr
	push 	di

	clr	al		; pointsize from gstate
	movwbf	dxah, es:GS_fontAttr.FCA_pointsize
	push	dx		; pass point size
	push 	ax

	clr	ah		; text style from gstate
	mov	al, es:GS_fontAttr.FCA_textStyle
	push	ax		; pass text style

	clr	ah		; font weight from gstate
	mov	al, es:GS_fontAttr.FCA_weight
	push	ax		; pass font weight

	segmov	ds, dgroup, dx
	call	TRUETYPE_GEN_WIDTHS

	mov	bx, ax		; mov font hdl to bx
	call	MemDerefDS
	segmov	ax, ds

	clc			;indicate no error

	.leave
	ret
TrueTypeGenWidths	endp
