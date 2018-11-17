COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		RasterMod
FILE:		nimbusChars.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/3/89		Initial revision

DESCRIPTION:
	This file contains routines for generating individual characters.

	$Id: nimbusChars.asm,v 1.1 97/04/18 11:45:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusGenChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate one character for a font.
CALLED BY:	VidBuildChar (via NimbusStrategy)

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
	eca	11/ 7/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusGenChar	proc	far
	uses	ax, bx, cx, dx, ds, si, di, bp
	.enter

	mov	di, 400
	call	ThreadBorrowStackSpace
	push	di

EC <	tst	dh				;>
EC <	ERROR_NZ	CANNOT_USE_DOUBLE_BYTE_CHARS_IN_THIS_VERSION ;>

	call	CharSetup			;setup routines, vars

	push	dx				;save character to build
	push	di				;save ptr to CharGenData
	call	FindCharPtr			;find ptr to character
	call	ds:GenRouts.CGR_make_rout	;call MakeChar() routine
	pop	di				;di <- ptr to CharGenData
	pop	dx				;dl <- character built
	call	ds:GenRouts.CGR_resize_rout	;call routine to resize font

	mov	ax, segment udata
	mov	ds, ax				;ax <- seg addr of idata
	mov	bx, ds:bitmapHandle		;bx <- handle of bitmap
	call	MemUnlock			;unlock bitmap block
	mov	bx, ds:variableHandle		;bx <- handle of vars
	call	MemUnlock			;unlock variable block


	pop	di
	call	ThreadReturnStackSpace

	.leave
	clc					;indicate no error
	ret
NimbusGenChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCharPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find ptr to individual character data
CALLED BY:	INTERNAL: NimbusGenChar

PASS:		dl - character (Chars)
		ds - seg addr of NimbusVars
			gstateSegment - seg addr of GState
			infoSegment - seg addr of font info block
			firstChar - first character in font
RETURN:		es:di - ptr to character data
		cx - handle of outline data
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Calls LoadOutlineData which finds the outline data
	with the largest subset of styles built in. The
	styles to implement that are returned is the set of
	styles that is not implied by the outline data.
	(eg. italic returned when making bold-italic from bold data) 
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES the cutoff point for characters is 0x80
	(as does nim2pc)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FindCharPtr	proc	near
	uses	ax, bx, dx, ds
	.enter

	mov	al, dl
EC <	call	ECCheckFirstChar		;>
	sub	al, ds:firstChar		;al <- char index, 1st half
SBCS <	mov	bx, ODF_PART1			;bx <- flag: first half	>
DBCS <	mov	bx, offset NOED_part1		;bx <- flag: first half >
	cmp	dl, NIMBUS_CHAR_MIDPOINT	;see if in second half
	jb	firstHalf			;branch if in first half
	sub	dl, NIMBUS_CHAR_MIDPOINT
	mov	al, dl				;al <- char index, 2nd half
SBCS <	mov	bx, ODF_PART2			;bx <- flag: second half>
DBCS <	mov	bx, offset NOED_part2		;bx <- flag: second half>
firstHalf:
	clr	ah
	mov	di, ax				;di <- char index

	push	ds
EC <	call	ECCheckGStateSegment		;>
	mov	ds, ds:gstateSegment		;ds <- seg addr of gstate
	mov	cx, ds:GS_fontAttr.FCA_fontID	;cx <- font ID
	mov	al, ds:GS_fontAttr.FCA_textStyle
	pop	ds

	mov	ds, ds:infoSegment		;ds <- seg addr of info block
EC <	call	ECCheckInfoSegment		;>
	call	LoadOutlineData			;es == seg addr of odata
	shl	di, 1				;*2 for words
	mov	di, es:[di]			;di <- ptr to char data

	.leave
	ret
FindCharPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup routines, data for calling makechar()
CALLED BY:	NimbusGenChar

PASS:		es - seg addr of font
		ds - seg addr of info block
		bp - seg addr of GState
RETURN:		ds - seg addr of vars
			fontSegment - seg addr of font
			fontHandle - handle of font
			gstateSegment - seg addr of GState
			infoSegment - seg addr of font info block
		es:di - ptr to CharGenData for font
DESTROYED:	ax, bx, cx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CharSetup	proc	near
	uses	es
	.enter

	push	ds				;save seg addr of info block
	push	es				;save seg addr of font

SBCS <	mov	ah, es:FB_firstChar					>
DBCS <	mov	ah, {byte}es:FB_firstChar				>
SBCS <	mov	al, es:FB_lastChar					>
DBCS <	mov	al, {byte}es:FB_lastChar				>
	push	ax
	sub	al, ah
	clr	ah				;ax <- # of chars - 1
if DBCS_PCGEOS
.assert (size CharTableEntry eq 6)
	shl	ax, 1				;*2
	mov	si, ax
	shl	ax, 1				;*4
	add	ax, si				;*6
else
.assert (size CharTableEntry eq 8)
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1				;*8 for each CharTableEntry
endif
	add	ax, size FontBuf		;skip font header
	mov	si, ax
	push	ax				;store offset to GenData

	segmov	ds, es				;ds <- seg addr of font
	call	LockNimbusVars			;ax <- seg addr, bx <- handle
	mov	es, ax				;es <- NimbusVars seg

	mov	cx, size CharGenData		;cx <- # of bytes to mov
	mov	di, offset GenData		;es:di <- ptr to dest
	rep	movsb				;copy me jesus

	mov	cx, size CharGenRouts / 2
	segmov	ds, cs
	mov	si, es:GenData.CGD_routs	;ds:si <- ptr to routine table
	mov	di, offset GenRouts		;es:di <- ptr to dest
	rep	movsw				;copy me jesus

	pop	di				;di <- offset of CharGenData
	mov	ds, ax				;ds <- seg addr of vars
	pop	ax				;ah <- first char, al <- last
	mov	ds:firstChar, ah		;store first char
	pop	ds:fontSegment			;store seg addr of font
	pop	ds:infoSegment			;store seg addr of info block
	mov	ds:gstateSegment, bp		;store gstate segment
	mov	es, bp
	mov	bx, es:GS_fontHandle		;bx <- handle of font
	mov	ds:fontHandle, bx		;store font handle
EC <	call	ECCheckFontHandle		;>
EC <	call	ECCheckFontSegment		;>
EC <	call	ECCheckGStateSegment		;>
EC <	call	ECCheckInfoSegment		;>
EC <	call	ECCheckFirstChar		;>

	.leave
	ret
CharSetup	endp

NimbusBitmapRouts	CharGenRouts <
	offset BMapBits,
	offset SetBit,
	offset BitmapAlloc,
	offset MakeChar,
	offset CopyCharResize
>

NimbusRegionRouts	CharGenRouts <
	offset SetPointInRegion,
	offset SetBitInRegion,
	offset RegionAlloc,
	offset MakeChar,
	offset CopyRegionResize
>

UnhintedRouts 		CharGenRouts <
	offset SetPointInRegion,
	offset SetBitInRegion,
	offset RegionAlloc,
	offset MakeBigChar,
	offset CopyRegionResize
>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockNimbusVars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the NimbusVars block
CALLED BY:	CharSetup(), NimbusGenInRegion()

PASS:		nothing
RETURN:		ax - NimbusVars segment
		bx - NimbusVars handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockNimbusVarsFar	proc	far
	call	LockNimbusVars
	ret
LockNimbusVarsFar	endp

LockNimbusVars	proc	near
	uses	ds
	.enter
	
	mov	ax, segment udata
	mov	ds, ax				;ds <- seg addr of idata
	mov	bx, ds:variableHandle		;bx <- handle of vars
	call	MemLock
	jnc	done				;branch if still in memory
	push	cx
	mov	ax, size NimbusVars		;ax <- size of block
	mov	ch, mask HAF_NO_ERR or mask HAF_LOCK	;ch <- HeapAllocFlags
	call	MemReAlloc			;reallocate variable block
EC <	call	ECNukeVariableBlock		;>
	pop	cx
done:
	.leave
	ret
LockNimbusVars	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyCharResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize the font as necessary and add the char to it.
CALLED BY:	INTERNAL: NimbusGenChar

PASS:		ds - seg addr of vars
			fontSegment - seg addr of font
			fontHandle - handle of font
			gstateSegment - seg addr of GState
			infoSegment - seg addr of font info block
			ds:guano - bitmap (NimbusBitmap)
		dl - character index (not number)
		di - offset of CharGenData
RETURN:		es - seg addr of font (may have changed)
DESTROYED:	ax, cx, dx, si, di, ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This routine should scan the bitmap to see where the data
	actually starts and ends, at least for rotated characters,
	because rotated characters can have a fair amount of white
	space left. Draw a 'P' and its bounding box rotated
	-45 degrees to see what I mean.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/14/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CopyCharResize	proc	near
	.enter

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
	push	ds:guano.NB_width		;save width
	mov	ax, ds:guano.NB_height		;ax <- height of bitmap
	push	ax				;save height
	mov	cx, ds:guano.NB_bytesperline	;cx <- width of bitmap (bytes)

EC <	tst	ch				;>
EC <	ERROR_NZ	FONT_CHAR_TOO_BIG	;>
EC <	tst	ah				;>
EC <	ERROR_NZ	FONT_CHAR_TOO_BIG	;>
	mul	cl				;ax <- width * height
	push	ax				;save size of bitmap
	add	ax, SIZE_CHAR_HEADER		;add space for header
	call	ResizeFont			;resize me jesus
	pop	cx				;cx <- size of bitmap (bytes)
	pop	ax				;ax <- height of bitmap
	mov	es:[si].CD_numRows, al
	pop	ax				;ax <- width of bitmap
	mov	es:[si].CD_pictureWidth, al

	pop	bx				;bx <- baseline offset
	mov	ax, es:[di].CGD_heightY		;ax <- scaled baseline for font
	add	ax, es:[di].CGD_scriptY		;add any offset for super/sub
	sub	ax, bx				;ax <- offset to top of bitmap
	mov	es:[si].CD_yoff, al
	pop	ax				;ax <- offset to left edge
	mov	bx, es:[di].CGD_heightX
	add	bx, es:[di].CGD_scriptX
	add	ax, bx
	mov	es:[si].CD_xoff, al

	mov	ds, ds:guano.NB_segment		;ds <- seg addr of bitmap
	mov	di, si
	clr	si				;ds:si <- ptr to bitmap
	add	di, CD_data			;es:di <- ptr to our data
	rep	movsb

EC <	cmp	di, es:FB_dataSize		;>
EC <	ERROR_NZ	OVERDOSE		;>

	.leave
	ret
CopyCharResize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResizeFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a font, deleting characters if necessary.
CALLED BY:	CopyCharResize, CopyRegionResize

PASS:		es - seg addr of font
		ax - size of character to add (including header)
		di - offset of CharTableEntry for character
		ds - seg addr of NimbusVars
			ds:fontHandle - handle of font block
RETURN:		es - seg addr of font (may have changed)
		es:FB_dataSize - updated
		es:si - ptr to space for character
DESTROYED:	cx, dx, ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResizeFont	proc	near
	uses	ds
	.enter

EC <	call	ECCheckFontHandle		;>
	mov	bx, ds:fontHandle		;bx <- handle of font
	segmov	ds, es, cx
	mov	cx, ds:FB_dataSize		;cx <- current size of font
	mov	dx, cx
	add	dx, ax				;add char size to current
	cmp	dx, MAX_FONT_SIZE		;see if font too big
	jbe	sizeOK				;branch if OK
	call	FontDrDeleteLRUChar		;shrink me jesus
	mov	cx, ds:FB_dataSize		;cx <- new size of font
sizeOK:
	mov	ds:FB_charTable[si].CTE_dataOffset, cx
	mov	si, cx				;si <- offset of new char
	add	ax, cx				;ax <- new size of font
	mov	ds:FB_dataSize, ax		;store new size

	mov	ch, HAF_STANDARD_NO_ERR		;ch <- HeapAllocFlags
	call	MemReAlloc			;add space for new char
	mov	es, ax				;es <- seg addr of font

	.leave
	ret
ResizeFont	endp
