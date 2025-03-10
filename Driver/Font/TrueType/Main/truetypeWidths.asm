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
	FR      29/1/21	    Initial revision

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
	FR	01.29.21	Initial version
	JK	10.02.24	width and weight implemented
	JK	19.09.24	cleanup

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeGenWidths	proc	far
	uses	cx, dx, di, ds

	mov	bx, bp
	.enter

	mov	ax, di
	mov	di, 800
	call	ThreadBorrowStackSpace
	push	di

	push	ax			;pass seg addr to fontBuf
	push	bx			;send tMatrix ptr
	push 	cx

	clr	al
	movwbf	dxah, es:GS_fontAttr.FCA_pointsize
	push	dx			;pass point size
	push 	ax

	clr	ah
	mov	al, es:GS_fontAttr.FCA_width
	push	ax			;pass width
	mov	al, es:GS_fontAttr.FCA_weight
	push	ax			;pass wieght
		
	mov	cx, es:GS_fontAttr.FCA_fontID
	call	FontDrFindFontInfo
	push	ds			;pass ptr to FontInfo
	push 	di

	mov	cx, ds			;save ptr to FontInfo
	mov	dx, di

	mov	al, es:GS_fontAttr.FCA_textStyle
	mov	bx, ODF_HEADER
	call	FontDrFindOutlineData
	push	ds			;pass ptr to OutlineEntry
	push	di

	mov	ds, cx
	mov	di, dx

	mov	al, es:GS_fontAttr.FCA_textStyle
	mov	bx, ODF_PART1
	call	FontDrFindOutlineData
	push	ds			;pass ptr to FontHeader
	push	di
	push	ax			;pass stylesToImplement

	mov 	bx, es:GS_window
	tst	bx
	jnz	pass_matrix
	push	0			;pass null ptr
	push	0
	jmp	pass_varblock

pass_matrix:	
	call	MemDerefDS
	push 	ds			;pass ptr to window matrix
	push 	W_TMatrix

pass_varblock:
	segmov	ds, dgroup, dx
	push	ds:variableHandle	;pass varBlock
	call	TRUETYPE_GEN_WIDTHS

	mov	bx, ax			;mov font hdl to bx
	call	MemDerefDS
	segmov	ax, ds

	pop	di
	call	ThreadReturnStackSpace

	clc				;indicate no error

	.leave
	ret
TrueTypeGenWidths	endp
