COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		RasterMod
FILE:		truetypeChars.asm

AUTHOR:		Falk Rehwagen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	29/1/21		Initial revision

DESCRIPTION:
	This file contains routines for generating individual characters.

	$Id: truetypeChars.asm,v 1.1 97/04/18 11:45:31 bluewaysw Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TrueTypeGenChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate one character for a font.
CALLED BY:	VidBuildChar (via TrueTypeStrategy)

PASS:		dx - character to build (Chars)
		es - seg addr of font (locked)
		bp - seg addr of gstate (locked)
			GS_fontHandle - handle of font
			GS_fontAttr - font attributes
		ds - seg addr of font info block

RETURN:		es - seg addr of font (locked) (may have changed)
		carry - clear
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	29/ 1/21	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TrueTypeGenChar	proc	far
	uses	ax, bx, cx, dx, ds, si, di, bp
	.enter

	segmov	cx, es
	call	MemSegmentToHandle
	jnc	err

	push	cx		; remember handle

	push	dx		; pass character code
	push	es		; pass font ptr
	mov	ax, 0		; with segment offset 0
	push	ax
	push	bp		; pass gstate ptr
	push	ax		; with segment offset 0
	push	ds		; pass font info block
	push	ax		; with segment offset 0

	segmov	ds, dgroup, ax
	call	TRUETYPE_GEN_CHARS

	; deref font block (may have moved)
	pop	bx
	call	MemDerefES

err:
	clc
	.leave
	ret
TrueTypeGenChar	endp


