COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc/UI
FILE:		uiStyleToken.asm

AUTHOR:		Gene Anderson, Feb 26, 1991

ROUTINES:
	Name				Description
	----				-----------
EXT	StyleArrayInit			Initialize style token array

EXT	StyleGetTokenByStyle		Use a token given a style
EXT	StyleGetTokenByToken		Use a token given a token
EXT	StyleGetStyleByToken		Given a token, get the associated style
EXT	StyleDeleteStyleByToken		Find and delete a token

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/26/91		Initial revision

DESCRIPTION:
	Routines for managing style token array.  Individual cells
	don't store all their associated styles, since that would
	require an additional 25+ bytes per cell.  Instead, cells
	store a token ID, which is a reference into the style token
	array, which is an array of CellAttrs structures.

	Style tokens are constant for a given spreadsheet (as long
	as there is at least one reference to the style).  This allows
	getting styles very quickly, as a single instruction
	can be done to get a pointer to a style entry (once the
	array is locked).

	NOTE: When you create a cell, you must call StyleGetTokenByStyle()
	to increment the reference count on the style.  You can pass a
	token if you already know it, or if you are creating a cell with
	the default style (eg. a brand new cell, which was previously empty),
	you can skip the call altogether.

	NOTE: When you delete a cell, you must call StyleDeleteStyleByToken()
	to decrement the reference count on the style.  Since you pass a
	token to this routine, it is very quick.  As with creating styles
	(ie. calling StyleGetTokenByStyle()) you can skip the call if the
	style in question is the default style.

	NOTE: As you would expect, changing a cell is just a combination
	of the above two operations: delete the old style and register the
	new one.  An obvious optimization for this is skipping both steps
	if the style token is the same for both.

	NOTE: If you want to change an attribute for all cells, rather
	than cycle through the cells it is possible to cycle through
	all the CellAttrs entries.  This is much faster, as there will
	generally be a small number of CellAttrs, where as there are
	at least 2,097,152 cells.

	$Id: spreadsheetStyleToken.asm,v 1.1 97/04/07 11:13:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleArrayInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a new style token array
CALLED BY:	SpreadsheetNew()

PASS:		bx - file handle of VM file
		es:di - ptr to default CellAttrs
RETURN:		ax - VM handle of array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: style token array is only chunk in VM block
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StyleArrayInit	proc	near
	uses	bx, cx, dx, bp, si, di, ds
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckCellAttrRefCount		;>
	;
	; Allocate a block to use for the style array.
	;
	clr	ax				;ax <- no user ID
	mov	cx, (size LMemBlockHeader)	;cx <- block size
	call	VMAlloc
	push	ax				;save VM handle
	push	es, di
	;
	; Lock and initalize the block for lmem use
	;
	call	VMLock				;ax <- seg addr of block
	mov	ds, ax				;ds <- seg addr of block
	mov	ds, ax				;ds <- seg addr of block
	mov	bx, bp				;bx <- memory handle
	mov	dx, (size LMemBlockHeader)	;dx <- offset of heap
	mov	ax, LMEM_TYPE_GENERAL		;ax <- LMemType
	mov	cx, STYLE_TOKEN_NUM_HANDLES	;cx <- # of handles
	push	bp, si
	mov	si, (size CellAttrs)		;si <- amount of free space
	clr	di				;di <- LocalMemoryFlags
	clr	bp				;bp <- end of space (0 = end)
	call	LMemInitHeap
	pop	bp, si
	;
	; Create an element array
	;
	clr	al				;al <- ObjChunkFlags
	mov	bx, (size CellAttrs)		;bx <- element size
	clr	cx				;cx <- default size header
	mov	si, cx
	call	ElementArrayCreate		;*ds:si <- array
	;
	; Initialize the default style
	;
	pop	cx, dx				;cx:dx <- ptr to element
	clr	bx
	mov	di, bx				;bx:di <- no routine
	call	ElementArrayAddElement
	;
	; Mark the block as dirty and release it
	;
	call	VMDirty
	call	VMUnlock
	pop	ax				;ax <- VM handle of array

	.leave
	ret
StyleArrayInit	endp

InitCode	ends

AttrCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleDeleteStyleByToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Done using a style -- decrement its reference count
CALLED BY:	DeleteCell()

PASS:		ds:si - instance data (SpreadsheetClass)
		ax - style token ID
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 1/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetDeleteStyleByToken	proc	far
	FALL_THRU	StyleDeleteStyleByTokenFar
SpreadsheetDeleteStyleByToken	endp

StyleDeleteStyleByTokenFar	proc	far
	call	StyleDeleteStyleByToken
	ret
StyleDeleteStyleByTokenFar	endp

StyleDeleteStyleByToken	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, di, bp

	cmp	ax, DEFAULT_STYLE_TOKEN		;default style?
	je	isDefault			;branch if default style

	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Lock the style token array, and remove one reference to it. We also
	; need to mark the VM block as dirty so the change will be saved.
	;
	push	ds, si				;save instance ptr
	call	LockStyleArrayFar		;*ds:si <- ptr to style array
	clr	bx
	mov	di, bx				;bx:di <- callback for deleting
	call	ElementArrayRemoveReference
	pushf					;save carry
	call	VMDirty				;we've changed things
	call	VMUnlock			;we're done with array
	popf					;recover carry
	pop	ds, si
	;
	; See if the element is what we have in our cached GState and was
	; actually deleted.  If so, we must invalidate the GState, because
	; the token may be re-used.
	;
	jnc	notRemoved			;branch if element not removed
	cmp	ds:[si].SSI_curAttrs, ax	;same token?
	jne	notRemoved			;branch if different token
	mov	ds:[si].SSI_curAttrs, INVALID_STYLE_TOKEN
notRemoved:
	.leave

isDefault:
	ret
StyleDeleteStyleByToken	endp

AttrCode	ends

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockStyleArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the style token array
CALLED BY:	StyleUseTokenByStyle(), StyleDeleteStyleByToken()

PASS:		ds:si - instance data (SpreadsheetClass)
RETURN:		*ds:si - ptr to array
		bp - VM memory handle of array
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: style token array is only chunk in VM block
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LockStyleArrayFar	proc	far
	call	LockStyleArray
	ret
LockStyleArrayFar	endp

LockStyleArray	proc	near
	uses	ax, bx
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	ax, ds:[si].SSI_styleArray	;ax <- VM handle of style array
	mov	bx, ds:[si].SSI_cellParams.CFP_file ;bx <- handle of file
	call	VMLock
	mov	ds, ax				;ds <- seg addr of block
	mov	si, STYLE_ARRAY_CHUNK		;*ds:si <- array addr

	.leave
	ret
LockStyleArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleGetTokenByStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find and use a style token based on passed style
CALLED BY:	UTILITY

PASS:		ds:si - instance data (SpreadsheetClass)
		es:di - ptr to CellAttrs
RETURN:		ax - style token ID
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetTokenByStyle	proc	far
	FALL_THRU	StyleGetTokenByStyleFar
SpreadsheetGetTokenByStyle	endp

StyleGetTokenByStyleFar	proc	far
	call	StyleGetTokenByStyle
	ret
StyleGetTokenByStyleFar	endp

StyleGetTokenByStyle	proc	near
	uses	bx, cx, dx, si, di, ds, bp
	.enter

EC <	call	ECCheckInstancePtr		;>
EC <	call	ECCheckCellAttr			;>
	call	LockStyleArray			;lock style array
	;
	; We were passed a style, so find (or possibly add) the entry
	; and up the reference count the slow way.
	;
	mov	cx, es
	mov	dx, di				;cx:dx <- ptr to element
	clr	bx
	mov	di, bx				;bx:di <- comparison routine
	call	ElementArrayAddElement
	tst	ax				;default?
	jz	isDefaultToken			;branch if default
afterToken:
	call	VMDirty				;we've changed things...
	call	VMUnlock			;done with array VM block

	.leave
	ret

	;
	; To simplify bookkeeping, we don't increment the reference
	; count on the default style token beyond the initial one.
	; So after having just blindly incremented the reference count
	; above, we fix it up here.
	;
CheckHack <DEFAULT_STYLE_TOKEN eq 0>
isDefaultToken:
	call	ElementArrayRemoveReference
	jmp	afterToken
StyleGetTokenByStyle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleGetStyleByToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a style token ID, return the associated style
CALLED BY:	SetCellTextAttrs()

PASS:		ds:si - instance data (SpreadsheetClass)
		es:di - ptr to CellAttrs to fill
		ax - style token ID
RETURN:		es:di - structure filled in
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetStyleByToken	proc	far
	FALL_THRU	StyleGetStyleByTokenFar
SpreadsheetGetStyleByToken	endp

StyleGetStyleByTokenFar	proc	far
	call	StyleGetStyleByToken
	ret
StyleGetStyleByTokenFar	endp

StyleGetStyleByToken	proc	near
	uses	ax, bx, cx, dx, si, di, bp, ds
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	LockStyleArray			;*ds:si <- ptr to array
	;
	; To avoid a far call, we just do the indirection ourselves
	;
	CAElementToPtr ds, si, ax, si, TRASH_AX_DX
	;
	; Copy the CellAttrs structure into our buffer
	;
	mov	cx, (size CellAttrs) / 2	;cx <- # words to move
	rep	movsw				;copy me jesus

	call	VMUnlock			;done with array

	.leave
EC <	call	ECCheckCellAttrRefCount		;>
	ret
StyleGetStyleByToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleGetAttrByToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a style token ID and an offset into CellAttrs,
		return the cell attribute at that offset.
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		ax - style token
		bx - offset of CellAttrs field to retrieve
RETURN:		ax - attribute
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cheng	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetAttrByToken	proc	far
	FALL_THRU	StyleGetAttrByTokenFar
SpreadsheetGetAttrByToken	endp

StyleGetAttrByTokenFar	proc	far
	call	StyleGetAttrByToken
	ret
StyleGetAttrByTokenFar	endp

StyleGetAttrByToken	proc	far
	uses	dx, si, bp, ds
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	LockStyleArray			;*ds:si <- ptr to array
	;
	; To avoid a far call, we just do the indirection ourselves
	;
	CAElementToPtr ds, si, ax, si, TRASH_AX_DX
EC <	pushdw	esdi				;>
EC <	segmov	es, ds				;>
EC <	mov	di, si				;>
EC <	call	ECCheckCellAttrRefCount		;>
EC <	popdw	esdi				;>
	;
	; Get the appropriate CellAttrs information.
	;
	mov	ax, {word}ds:[si][bx]		;ax <- CellAttrs info

	call	VMUnlock			;done with array

	.leave
	ret
StyleGetAttrByToken	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleGetTokenByToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use a style token (ie. up reference count)
CALLED BY:	UTILITY

PASS:		ds:si - instance data (SpreadsheetClass)
		ax - style token ID
RETURN:		ax - style token ID
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StyleGetTokenByToken	proc	far
	uses	ds, si, bp

	cmp	ax, DEFAULT_STYLE_TOKEN		;default style?
	je	isDefault			;branch if default

	.enter

EC <	call	ECCheckInstancePtr		;>
	call	LockStyleArray			;*ds:si <- ptr 
	call	ElementArrayAddReference
	call	VMDirty				;we've changed things...
	call	VMUnlock			;done with array VM block

	.leave
isDefault:
	ret
StyleGetTokenByToken	endp

if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckCellAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the contents of a CellAttrs structure looks OK.
CALLED BY:	EC UTILITY

PASS:		es:di - ptr to CellAttrs
RETURN:		none
DESTROYED:	none (flags preserved)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ECCheckCellAttrRefCount	proc	far
	pushf
	cmp	es:[di].CA_refCount.REH_refCount.WAAH_low, 50000
	WARNING_A	CELL_ATTR_REF_COUNT_ABOVE_50000
	popf
	FALL_THRU	ECCheckCellAttr
ECCheckCellAttrRefCount	endp

ECCheckCellAttr	proc	far
	uses	ax, bx, cx, dx, si, di
	.enter

	pushf
	;
	; See if it is an unused style element
	; The EC kernel fills these with 0xcc
	;
	mov	al, 0xcc
	mov	cx, (size CellAttrs)-(size CA_refCount)
	push	di
	mov	di, (size CA_refCount)
	repe	scasb				;scan me jesus
	ERROR_E	EMPTY_CELL_ATTR_DATA
	pop	di
	;
	; Check the TextStyle
	;
	test	es:[di].CA_style, not (mask TextStyle)
	ERROR_NZ BAD_CELL_ATTR_DATA
	;
	; Check the pointsize
	;
	clr	ah
	mov	dx, es:[di].CA_pointsize	;dx.ah <- pointsize * 8
	shrwbf	dxah
	shrwbf	dxah
	shrwbf	dxah				;dx.ah <- pointsize
	cmp	dx, MAX_POINT_SIZE
	ERROR_A	BAD_CELL_ATTR_DATA
	;
	; Check the CellInfo
	;
	test	es:[di].CA_justification, not (Justification-1)
	ERROR_NZ BAD_CELL_ATTR_DATA
	;
	; Check the border info
	;
	test	es:[di].CA_border, not (mask CellBorderInfo)
	ERROR_NZ BAD_CELL_ATTR_DATA

	popf

	.leave
	ret
ECCheckCellAttr	endp


endif

DrawCode	ends

AttrCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StyleTokenChangeAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change data for every CellAttr structure

CALLED BY:	SetSpreadsheetAttrs()
PASS:		ds:si - Spreadsheet instance
		bx:di - callback routine
		ss:bp - locals to pass to callback
		ax - data to pass to callback
		dx - data to pass to callback

CALLBACK:
	PASS:	ds:di - ptr to CellAttrs structure
		ss:bp - inherited locals
		ax - data passed to StyleTokenChangeAttr()
		dx - data passed to StyleTokenChangeAttr()
	RETURN:	carry - set to abort
		ax - pass to next entry

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	10/ 5/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StyleTokenChangeAttr		proc	far
	uses	ds, si, bx, cx
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov_tr	cx, bp				;ss:cx <- locals
	call	LockStyleArrayFar		;*ds:si <- style array
	xchg	cx, bp				;ss:bp <- locals

	call	ChunkArrayEnum			;callback for each entry

	xchg	cx, bp				;bp <- VM mem handle
	call	VMDirty
	call	VMUnlock
	mov_tr	bp, cx				;ss:bp <- locals

	.leave
	ret
StyleTokenChangeAttr		endp

AttrCode	ends
