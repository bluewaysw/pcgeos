COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus/CharMod
FILE:		nimbusRegions.asm

AUTHOR:		Gene Anderson, Feb 28, 1990

ROUTINES:
	Name			Description
	----			-----------
	RegionAlloc		Allocate and initialize a region.
EXT	SetPointInRegion	Set an on/off point in a region.
EXT	CopyRegionResize	Clean region, resize font and add the char.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/28/90		Initial revision

DESCRIPTION:
	Contains routines for generating characters defined as regions.

	$Id: nimbusRegions.asm,v 1.1 97/04/18 11:45:28 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Region Characters, The Documentation.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	The Nimbus routines create bitmaps through clever use of the
Postcript winding rule. Points on the outside of characters run counter-
clockwise, and points on the inside of characters run clockwise. This
allows the code to correctly set points in the bitmap by setting the
starting point and inverting all points to the end of the line. This works
because the points on a line always come in pairs. Points lying outside
the character body get inverted an even number of times. Points lying
inside get inverted an odd number of times, ending with them turned on,
the correct state.
	This is perfect for generating PC/GEOS regions, because they
have a similar on/off logic. The routine SetRegionPoint is designed
to be the region equivalent of bmap_bits(), the Nimbus routine that
does the above setting of points in bitmaps. As such, it is C-callable
so that makechar() can call either routine interchangeably depending
on whether the character being generated is a bitmap or region.
	After some simple research, the average number of on/off points
in a character was determined to be ~3.4. As a result of this research,
I decided on 4 as a good number.
	The unused points will be replaced with points as they
are set on each line. If we get to the unpleasant state of no more
unused points on a line, resizing the region block may become
necessary. We check for any remaining bytes at the end of the
block, and use them first. Only if the block is full do we do the
actual (potentially unpleasant) resizing.
	After the character is entirely generated, the region will be
scanned for adjacent duplicate lines and any remaining unused points,
as the concept of unused points is nonstandard (ie. the rest of the
graphics system will barf or do weird things with these values in)
	Also, it should be noted that there is no equivalent for
the set_bit() routine. It is assumed that regions are used for large
characters, such that continuity checking doesn't need to be done,
so the set_bit() routine should never be called. In addition, setting
a single point is much more painful in a region than a bitmap.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RegionAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a region for larger (ie. > 127 lines) characters.
CALLED BY:	AllocBMap()

PASS:		ds - seg addr of NimbusVars
		ax, dx - height of bitmap (in lines)
		es - seg addr of udata
RETURN:		es:bitmapHandle - handle of region
		ds:guano.NB_segment
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RegionAlloc	proc	near
	uses	es, bp
	.enter

	mov	di, es:bitmapHandle		;di <- handle of block to use
	mov	cx, RFR_ODD_EVEN or (UNUSED_PER_LINE shl 8)
	clr	bp				;bp <- minimum y
	call	GrRegionPathInit		;create the RegionPath
	mov	ds:guano.NB_segment, es		;store seg addr of region
	.leave
	mov	es:bitmapSize, cx		;store size of block
	ret
RegionAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPointInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an on/off point in a region character.
CALLED BY:	YPixelate()

PASS:		ds:guano - NimbusBitmap (segment = RegionPath)
		(cx,bp) - (x,y) point to invert from
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	eca	2/28/90		Initial version
	don	8/23/91		Changed to use CallBuildRegion (faster I hope)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPointInRegion	proc	near
	sub	cx, ds:guano.NB_lox		;x' = x - left(x);
	mov	dx, ds:guano.NB_hiy
	sub	dx, bp				;y' = top(y) - y;
	mov	ax, REGION_ADD_ON_OFF_POINT
	call	CallBuildRegion			;add the on/off point
SetBitInRegion	label	near
	ret
SetPointInRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyRegionResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean the region & check for duplicates, calc final size
		and add it to the font, resizing as necessary.
CALLED BY:	CopyCharResize

PASS:		ds - seg addr of NimbusVars
			ds:guano - region
			ds:fontSegment - seg addr of font
		dl - character (Chars)
		di - offset CharGenData
RETURN:		es - seg addr of font (may have changed)
DESTROYED:	ax, cx, dx, si, di, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyRegionResize	proc	near
EC <	call	ECCheckFontSegment		;>
	mov	es, ds:fontSegment		;es <- seg addr of font
SBCS <	sub	dl, es:FB_firstChar		;dl <- char index	>
DBCS <	sub	dl, {byte}es:FB_firstChar	;dl <- char index	>
	clr	dh
	mov	si, dx				;si <- char index
if DBCS_PCGEOS
.assert (size CharTableEntry eq 6)
	shl	si, 1				;*2
	shl	si, 1				;*4
	add	si, dx				;*5
	add	si, dx				;*6
else
.assert (size CharTableEntry eq 8)
	shl	si, 1				;*8 for each CTE
	shl	si, 1
	shl	si, 1				;si <- offset of CharTableEntry
endif
EC <	cmp	es:FB_charTable[si].CTE_dataOffset, CHAR_NOT_BUILT >
EC <	ERROR_NZ	FONT_BAD_CHAR_FLAG >

	push	ds:guano.NB_lox			;save left edge
	push	ds:guano.NB_hiy			;save baseline offset

	mov	ax, REGION_CLEAN		;ax <- routine #
	call	CallBuildRegion			;clean the region
	mov	ax, cx				;ax <- size of character
	push	ax				;save size of character
	add	ax, SIZE_REGION_HEADER		;add space for header
	push	ax
	call	ResizeFont			;resize me jesus
	pop	es:[si].RCD_size		;<- size of char + header
	pop	cx				;cx <- size of character

	pop	bx				;bx <- baseline offset
	mov	ax, es:[di].CGD_heightY		;ax <- scaled baseline for font
	add	ax, es:[di].CGD_scriptY		;add any offset for super/sub
	sub	ax, bx				;ax <- offset to top of bitmap
	mov	es:[si].RCD_yoff, ax
	pop	ax				;ax <- offset to left edge
	mov	bx, es:[di].CGD_heightX
	add	bx, es:[di].CGD_scriptX
	add	ax, bx
	mov	es:[si].RCD_xoff, ax

	mov	ds, ds:guano.NB_segment		;ds <- seg addr of region
	mov	di, si
	add	di, RCD_bounds			;es:di <- ptr to char data
	mov	si, offset RP_bounds		;ds:si <- ptr to region
	shr	cx, 1				;cx <- # of words to copy
	rep	movsw

EC <	cmp	di, es:FB_dataSize		;>
EC <	ERROR_NE	OVERDOSE		;>
	ret
CopyRegionResize	endp
