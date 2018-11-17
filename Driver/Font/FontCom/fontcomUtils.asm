COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		fontcomUtils.asm
FILE:		fontcomUtils.asm

AUTHOR:		Gene Anderson, Feb  5, 1992

ROUTINES:
	Name			Description
	----			-----------
	FontAllocFontBlock	Allocate / re-allocate a block for a font

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/ 5/92		Initial revision

DESCRIPTION:
	Common utility routines

	$Id: fontcomUtils.asm,v 1.1 97/04/18 11:45:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FontAllocFontBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	(Re)allocate a memory block for a font to be generated.

CALLED BY:	EXTERNAL: FontGenWidths

PASS:		bx - additional space in block for driver
		cx - number of characters
		ax - number of kerning pairs
		di - 0 to alloc, old handle to reallocate
RETURN: 	es - seg addr of font block
		    es:FB_dataSize - set
		bx - handle of font block
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes size(CharTableEntry) == 8
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(size KernPair)+(size BBFixed) eq 4>

FontAllocFontBlock	proc	near
	uses	ax, cx, dx
	.enter

	shl	ax, 1
	shl	ax, 1				;ax <- # kern pairs * 4
	add	ax, bx				;ax <- added additional space
	mov	bx, di				;bx <- handle or 0
	;
	; NOTE: the following is not really an index, but the
	; calculation is identical.
	;
	FDIndexCharTable cx, dx			;cx == # chars * 8 (or *6)
	add	ax, cx				;ax <- bytes for ptrs+driver
	add	ax, size FontBuf - size CharTableEntry
	mov	cx, mask HF_SWAPABLE \
		or mask HF_SHARABLE \
		or mask HF_DISCARDABLE \
		or ((mask HAF_NO_ERR) \
		or (mask HAF_LOCK)) shl 8
	push	ax				;save size
	tst	bx				;test for handle passed
	jne	oldBlock			;branch handle passed
	mov	bx, FONT_MAN_ID			;cx <- make font manager owner
	call	MemAllocSetOwner		;allocate for new pointsize
	;
	; P the new block handle, as fonts require exclusive access
	;
	call	HandleP
afterAlloc:

	mov	es, ax				;es <- seg addr of font
	pop	es:FB_dataSize			;save size in bytes

	.leave
	ret

oldBlock:
	call	MemReAlloc			;reallocate font block
	jmp	afterAlloc
FontAllocFontBlock	endp
