COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentRegion.asm

ROUTINES:
	Name				Description
	----				-----------
    INT RecalculateMPTextFlowRegions 
				Recalculate the regions stored with each
				flow region of a master page

    INT RecalculateMPTextFlowRegions_int 
				Recalculate the regions stored with each
				flow region of a master page

    INT RecalculateInvalidArticleRegions 
				Recalculate the text flow region for any
				invalid article regions

    INT RecalcInvalidCallback	Recalculate the invalid regions for an
				article

    INT RecalcLayoutCallback	Callback to recalculate the layout for a
				section

    INT RecalcOneFlowRegion	Recalculate the text for region for one
				flow region

    INT RecalcOneFlowRegionLow	Recalculate the text for region for one
				flow region

    INT CalculateRegionForFlowRegion 
				Calculate the text flow region for a flow
				region

    INT AllocRectRegion		Allocate a block and stuff a rectangular
				region into it

    INT CopyRegionToChunk	Copy a region from a block into a chunk and
				free the block

    INT CopyChunkToDB		Copy a chunk to a db item

    INT CalculateDrawRegion	Calculate the draw region for a text region

    INT MungeRegion		Take the flow region and munge it around it
				make the data how we want it

    INT ContinueToMungeRegion	Force the region data to be relative to the
				top of the data-bounding rectangle.

METHODS:
	Name			Description
	----			-----------
    StudioDocumentRecalcLayout	Recalculate the layout

				MSG_STUDIO_DOCUMENT_RECALC_LAYOUT
				StudioDocumentClass

    StudioDocumentRecalcInval	Recalculate the invalid area

				MSG_STUDIO_DOCUMENT_RECALC_INVAL
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the ... related code for StudioDocumentClass

	$Id: documentRegion.asm,v 1.1 97/04/04 14:39:02 newdeal Exp $

------------------------------------------------------------------------------@

DocPageSetup segment resource

RECALC_LOCALS	equ	<\
.warn -unref_local\
flowPosition		local	PointDWord\
flowSize		local	XYSize\
flowObject		local	optr\
inheritedTextRegion	local	dword\
destTextRegion		local	fptr\
destDrawRegion		local	fptr\
grobjBody		local	optr\
fileHandle		local	hptr\
regionExistedBefore	local	word\
flowAroundRegion	local	hptr\
flowThroughRegion	local	hptr\
flowAroundChunk		local	lptr\
flowThroughChunk	local	lptr\
tempChunk		local	lptr\
masterPageFlag		local	word\
.warn @unref_local\
>

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateMPTextFlowRegions

DESCRIPTION:	Recalculate the regions stored with each flow region
		of a master page

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	ax - master page block

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/15/92		Initial version

------------------------------------------------------------------------------@
RecalculateMPTextFlowRegions	proc	far	uses ax, bx, cx, dx, si, di, ds
RECALC_LOCALS
	.enter
EC <	call	AssertIsStudioDocument					>

	call	IgnoreUndoNoFlush

	call	GetFileHandle
	mov	fileHandle, bx

	; first we need to calculate the "flow inside" path and the
	; "flow around" path for the grobj body

	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MasterPageBody
	mov	ax, MSG_STUDIO_GROBJ_BODY_GET_FLAGS
	mov	di, mask MF_CALL
	push	bp
	call	ObjMessage			;ax = StudioGrObjBodyFlags
	pop	bp
	test	ax, mask SGOBF_WRAP_AREA_NON_NULL
	jz	done

	call	RecalculateMPTextFlowRegions_int

done:

	call	AcceptUndo

	.leave
	ret

RecalculateMPTextFlowRegions	endp

DocPageSetup ends

;---

DocRegion segment resource

RecalculateMPTextFlowRegions_int	proc	far
	.enter inherit RecalculateMPTextFlowRegions

	movdw	grobjBody, bxsi

	clr	ax
	mov	flowPosition.PD_x.high, ax
	mov	flowPosition.PD_y.high, ax
	clrdw	inheritedTextRegion, ax

	call	ObjLockObjBlock
	mov	ds, ax				;ds = master page block
	mov	si, offset FlowRegionArray
	call	ObjMarkDirty
	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	add	si, ds:[si].CAH_offset

	; ds:si = FlowRegionArrayElement, cx = count

recalcLoop:
	mov	ax, ds:[si].FRAE_position.XYO_x
	mov	flowPosition.PD_x.low, ax
	mov	ax, ds:[si].FRAE_position.XYO_y
	mov	flowPosition.PD_y.low, ax
	mov	ax, ds:[si].FRAE_size.XYS_width
	mov	flowSize.XYS_width, ax
	mov	ax, ds:[si].FRAE_size.XYS_height
	mov	flowSize.XYS_height, ax

	movdw	flowObject, ds:[si].FRAE_flowObject, ax
	lea	ax, ds:[si].FRAE_textRegion	;ds:ax is pointer to dest
	movdw	destTextRegion, dsax
	lea	ax, ds:[si].FRAE_drawRegion	;ds:ax is pointer to dest
	movdw	destDrawRegion, dsax
	mov	masterPageFlag, TRUE
	call	CalculateRegionForFlowRegion

	jnc	next

	; the flow region changed -- invalidate it

	push	si
	movdw	axsi, flowObject
	mov	bx, fileHandle
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	mov	ax, MSG_GO_INVALIDATE
	clr	di
	call	ObjMessage
	pop	si

next:
	add	si, size FlowRegionArrayElement
	loop	recalcLoop

	mov	bx, grobjBody.handle
	call	MemUnlock

	.leave
	ret

RecalculateMPTextFlowRegions_int	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalculateInvalidArticleRegions

DESCRIPTION:	Recalculate the text flow region for any invalid article
		regions

CALLED BY:	INTERNAL

PASS:
	*ds:si - document

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/15/92		Initial version

------------------------------------------------------------------------------@
RecalculateInvalidArticleRegions	proc	far	uses es
RECALC_LOCALS
documentObj	local	optr
invalidatedFlag	local	word
	.enter

	call	IgnoreUndoNoFlush

EC <	call	AssertIsStudioDocument					>

	mov	bx, ds:[LMBH_handle]
	movdw	documentObj, bxsi
	mov	invalidatedFlag, 0

	call	GetFileHandle
	mov	fileHandle, bx

	call	LockMapBlockDS

	; if the invalid region is null then bail

	tstdw	ds:MBH_invalidRect.RD_bottom
	jz	done

	push	ds
	segmov	es, ds
	call	loadDocouemntObj
	call	SuspendDocument
	pop	ds

	mov	bx, fileHandle
	mov	ax, ds:MBH_grobjBlock
	call	VMVMBlockToMemBlock
	mov	grobjBody.handle, ax
	mov	grobjBody.chunk, offset MainBody

	; we need to iterate through all the articles

	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset RecalcInvalidCallback
	call	ChunkArrayEnum

	; zero the invalid region

	push	es
	segmov	es, ds
	clr	ax
	mov	di, offset MBH_invalidRect
	mov	cx, (size MBH_invalidRect) / 2
	rep	stosw
	pop	es
	call	VMDirtyDS

	push	ds
	segmov	es, ds
	call	loadDocouemntObj
	call	UnsuspendDocument
	pop	ds

done:
	call	VMUnlockDS
	call	loadDocouemntObj

	call	AcceptUndo

	.leave
	ret

;---

loadDocouemntObj:
	movdw	bxsi, documentObj
	call	MemDerefDS
	retn

RecalculateInvalidArticleRegions	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalcInvalidCallback

DESCRIPTION:	Recalculate the invalid regions for an article

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	ss:bp - inherited variables

RETURN:
	carry - clear

DESTROYED:
	ax, bx, cx, dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/15/92		Initial version

------------------------------------------------------------------------------@
RecalcInvalidCallback	proc	far
	.enter inherit RecalculateInvalidArticleRegions

	push	ds:[LMBH_handle]
	segmov	es, ds				;es = map block

	mov	bx, cx
	mov	ax, ds:[di].AAE_articleBlock
	mov	bx, fileHandle
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjLockObjBlock
	mov	ds, ax				;ds = article block

	mov	si, offset ArticleRegionArray
	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	tst	cx
	LONG jz	done
	add	si, ds:[si].CAH_offset

	; loop through the article regions to do the recalculation

recalcLoop:

	; is the region in the invalid area ?

	movdw	dxax, ds:[si].VLTRAE_spatialPosition.PD_x
	cmpdw	dxax, es:MBH_invalidRect.RD_right
	LONG ja	next
	add	ax, ds:[si].VLTRAE_size.XYS_width
	adc	dx, 0
	cmpdw	dxax, es:MBH_invalidRect.RD_left
	LONG jb	next

	movdw	dxax, ds:[si].VLTRAE_spatialPosition.PD_y
	cmpdw	dxax, es:MBH_invalidRect.RD_bottom
	ja	next
	add	ax, ds:[si].VLTRAE_size.XYS_height
	adc	dx, 0
	cmpdw	dxax, es:MBH_invalidRect.RD_top
	jb	next

	; in invalid area -- reclculate

	call	RecalcOneFlowRegionLow
	jnc	next

	; region changed -- force text to recalculate

	tst	invalidatedFlag
	jnz	afterInval
	mov	invalidatedFlag, 1
	push	cx, si, bp, ds
	movdw	bxsi, documentObj
	call	MemDerefDS
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	pop	cx, si, bp, ds
afterInval:

	push	cx, bp
	mov	di, si
	mov	si, offset ArticleRegionArray
	call	ChunkArrayPtrToElement			;ax = region number
	push	ax
	mov_tr	cx, ax
	mov	si, offset ArticleText
	mov	ax, MSG_VIS_LARGE_TEXT_REGION_CHANGED
	call	ObjCallInstanceNoLock
	pop	ax
	mov	si, offset ArticleRegionArray
	call	ChunkArrayElementToPtr
	mov	si, di
	pop	cx, bp

next:
	add	si, size ArticleRegionArrayElement
	dec	cx
	LONG jnz recalcLoop

done:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	pop	bx
	call	MemDerefDS

	clc

	.leave
	ret

RecalcInvalidCallback	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentRecalcLayout -- MSG_STUDIO_DOCUMENT_RECALC_LAYOUT
							for StudioDocumentClass

DESCRIPTION:	Recalculate the layout

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/14/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentRecalcLayout	method dynamic	StudioDocumentClass,
						MSG_STUDIO_DOCUMENT_RECALC_LAYOUT

	call	LockMapBlockES
	call	SuspendDocument

	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;cxdx = document
	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset RecalcLayoutCallback
	call	ChunkArrayEnum
	movdw	bxsi, cxdx
	call	MemDerefDS

	call	RecalculateInvalidArticleRegions

	call	UnsuspendDocument
	call	VMUnlockES

	ret

StudioDocumentRecalcLayout	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentRecalcInval -- MSG_STUDIO_DOCUMENT_RECALC_INVAL
							for StudioDocumentClass

DESCRIPTION:	Recalculate the invalid area

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/14/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentRecalcInval	method dynamic	StudioDocumentClass,
						MSG_STUDIO_DOCUMENT_RECALC_INVAL
	call	IgnoreUndoNoFlush
	call	LockMapBlockES
	call	SuspendDocument
	call	RecalculateInvalidArticleRegions
	call	UnsuspendDocument
	call	VMUnlockES
	call	AcceptUndo
	ret

StudioDocumentRecalcInval	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalcLayoutCallback

DESCRIPTION:	Callback to recalculate the layout for a section

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	cxdx - document

RETURN:
	carry - clear

DESTROYED:
	ax, bx, si, di, bp, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/14/92		Initial version

------------------------------------------------------------------------------@
RecalcLayoutCallback	proc	far
	test	ds:[di].SAE_flags, mask SF_NEEDS_RECALC
	jz	done
	call	VMDirtyDS
	andnf	ds:[di].SAE_flags, not mask SF_NEEDS_RECALC
	segmov	es, ds
	pushdw	cxdx
	movdw	bxsi, cxdx
	call	MemDerefDS
	call	RecalculateArticleRegionsLow
	popdw	cxdx
	segmov	ds, es
done:
	clc
	ret

RecalcLayoutCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalcOneFlowRegion

DESCRIPTION:	Recalculate the text for region for one flow region

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleRegionArrayElement
	ax - VM file
	bxsi - grobj body

RETURN:
	carry - set if recalc needed

DESTROYED:
	ax, bx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/16/92		Initial version

------------------------------------------------------------------------------@
RecalcOneFlowRegion	proc	far
RECALC_LOCALS
	.enter

	mov	fileHandle, ax
	movdw	grobjBody, bxsi

	mov	si, di
	call	RecalcOneFlowRegionLow

	.leave
	ret

RecalcOneFlowRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	RecalcOneFlowRegionLow

DESCRIPTION:	Recalculate the text for region for one flow region

CALLED BY:	INTERNAL

PASS:
	ds:si - ArticleRegionArrayElement
	ss:bp - inherited variables

RETURN:
	carry - set if recalc needed

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/16/92		Initial version

------------------------------------------------------------------------------@
RecalcOneFlowRegionLow	proc	far	uses ax, si
RECALC_LOCALS
	.enter inherit far

	movdw	inheritedTextRegion, ds:[si].ARAE_inheritedTextRegion, ax
	movdw	flowPosition.PD_x, ds:[si].VLTRAE_spatialPosition.PD_x, ax
	movdw	flowPosition.PD_y, ds:[si].VLTRAE_spatialPosition.PD_y, ax
	mov	ax, ds:[si].VLTRAE_size.XYS_width
	mov	flowSize.XYS_width, ax
	mov	ax, ds:[si].VLTRAE_size.XYS_height
	mov	flowSize.XYS_height, ax

	movdw	flowObject, ds:[si].ARAE_object, ax
	lea	ax, ds:[si].VLTRAE_region	;ds:ax is pointer to dest
	movdw	destTextRegion, dsax
	lea	ax, ds:[si].ARAE_drawRegion	;ds:ax is pointer to dest
	movdw	destDrawRegion, dsax
	mov	masterPageFlag, FALSE
	call	CalculateRegionForFlowRegion

	.leave
	ret

RecalcOneFlowRegionLow	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CalculateRegionForFlowRegion

DESCRIPTION:	Calculate the text flow region for a flow region

CALLED BY:	INTERNAL

PASS:
	ss:bp - inherited variables

RETURN:
	new region stored
	carry - set if region changed

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/15/92		Initial version

------------------------------------------------------------------------------@
CalculateRegionForFlowRegion	proc	near uses ax, bx, cx, dx, si, di, ds, es
RECALC_LOCALS
	.enter inherit far

	; delete old region (and save a flag saying if it existed)

	lds	si, destTextRegion
	clr	cx
	clrdw	axdi
	xchgdw	axdi, ds:[si]
	tst	ax
	jz	afterDelete
	mov	bx, fileHandle
	call	DBFree
	lds	si, destDrawRegion
	clrdw	axdi
	xchgdw	axdi, ds:[si]
	call	DBFree
	inc	cx
afterDelete:
	mov	regionExistedBefore, cx

	; do "flow around"

	clr	cl				;no DrawFlags
	mov	dx, mask GODF_DRAW_WRAP_TEXT_AROUND_ONLY or \
		    mask GODF_DRAW_OBJECTS_ONLY
	call	constructRegion			;bx = region
	mov	flowAroundRegion, bx

	; do "flow through"

	clr	cl				;no DrawFlags
	mov	dx, mask GODF_DRAW_WRAP_TEXT_INSIDE_ONLY or \
		    mask GODF_DRAW_OBJECTS_ONLY
	call	constructRegion			;bx = region
	mov	flowThroughRegion, bx

	tst	bx
	jnz	regionExists
	tstdw	inheritedTextRegion
	jnz	regionExists
	tst	flowAroundRegion
	LONG jz	noRegion

	; we have a region

regionExists:

	; if a flow through region exists then use it as the starting point
	; else allocate a rect region the size of the flow region

	mov	bx, flowThroughRegion
	tst	bx
	pushf					; Save "has flow-through" flag
	jnz	flowThroughExists
	
	;
	; If the flow-through region does not exist, we need to flow into
	; the rectangular flow-region.
	;
	clr	ax
	clr	bx
	mov	cx, flowSize.XYS_width
	mov	dx, flowSize.XYS_height
	call	AllocRectRegion
	mov	flowThroughRegion, bx

flowThroughExists:

	; allocate an lmem block and copy the regions in

	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	MemAllocLMem
	call	MemLock
	mov	ds, ax
	mov	bx, flowThroughRegion
	call	CopyRegionToChunk		;si = flow through chunk
	mov	flowThroughChunk, si
	call	LMemAlloc			;ax = temp chunk
	mov	tempChunk, ax

	; if no flow around region exists then we just use the flow through
	; region

	mov	si, flowThroughChunk
	mov	bx, flowAroundRegion
	tst	bx
	jz	gotResultRegion
	call	CopyRegionToChunk		;si = flow around chunk
	mov	flowAroundChunk, si

	; result = FLOW_THROUGH - FLOW_AROUND
	;        = FLOW_THROUGH and (not FLOW_AROUND)

	segmov	es, ds
	mov	di, tempChunk
	mov	si, flowAroundChunk
	mov	ax, mask ROF_NOT_OP
	call	GrChunkRegOp			;TEMP = not AROUND

	mov	si, tempChunk
	mov	bx, flowThroughChunk
	mov	di, flowAroundChunk
	mov	ax, mask ROF_AND_OP
	call	GrChunkRegOp			;AROUND = TEMP and THROUGH
	mov	si, flowAroundChunk		;result is in flow around

gotResultRegion:

	; *ds:si = result region (either flow around or flow through)

	; if there is an inherited region then we need to AND it in

	movdw	axdi, inheritedTextRegion
	tst	ax
	jz	gotFinalResultRegion
	mov	bx, fileHandle
	call	DBLock				;*es:di = inherited region
	segxchg	ds, es
	mov	bx, si				;*es:bx = result
	mov	si, di				;*ds:si = inherited region
	mov	di, tempChunk			;*es:di = tempChunk
	mov	ax, mask ROF_AND_OP
	call	GrChunkRegOp			;tempChunk = result AND inherit
	segxchg	ds, es
	call	DBUnlock
	mov	si, tempChunk
gotFinalResultRegion:
	
	;
	; If there is a flow-through region that is *not* the rectangular
	; flow-region then we need to clip the text in the flow-region to
	; the rectangular region.
	;
	popf					; Rstr "has flow-through" flag
	jz	mungeTheStupidThing
	
	;
	; We had a region to flow into. This means that we need to AND the
	; current result with the rectangular flow region.
	;

	;
	; If the flow-through region does not exist, we need to flow into
	; the rectangular flow-region.
	;
	push	si				; Save region chunk
	push	ds				; Save region segment
	clr	ax
	clr	bx
	mov	cx, flowSize.XYS_width
	mov	dx, flowSize.XYS_height
	call	AllocRectRegion			; bx <- rectangular region
	pop	ds				; Restore region segment
	
	;
	; Allocate a block to hold this thing.
	;
	call	CopyRegionToChunk		; si <- clip chunk

	segmov	es, ds				; es <- segment of r2, result
	pop	bx				; bx <- region chunk (r2)
	mov	di, tempChunk			; di <- place to put result
	
	mov	ax, mask ROF_AND_OP		; And the regions
	call	GrChunkRegOp			; Compute flow region
	mov	si, tempChunk			; Result is in temp chunk

mungeTheStupidThing:

	; munge the region

	call	MungeRegion
	jnc	notEmptyRegion
	mov	bx, ds:[LMBH_handle]
	call	MemFree
	jmp	noRegion
notEmptyRegion:

	; put the bounds at the beignning of the chunk

	push	si
	mov	ax, si				;ax = chunk
	clr	bx				;bx = offset to insert at
	mov	cx, size Rectangle		;cx = size to insert
	call	LMemInsertAt
	mov	si, ds:[si]
	push	si				;save start of chunk
	add	si, size Rectangle
	call	GrGetPtrRegBounds		;ds:si points past end
	pop	si
	dec	bx				;convert to document coordinates
	dec	dx
	mov	ds:[si].R_left, ax
	mov	ds:[si].R_top, bx
	mov	ds:[si].R_right, cx
	mov	ds:[si].R_bottom, dx
	pop	si
finishRegionStuff::

	; calculate draw region here...

	push	si				;Save flow region
	call	CalculateDrawRegion		;*ds:si = draw region
	call	CopyChunkToDB			;axdi = db item
	les	bx, destDrawRegion
	movdw	es:[bx], axdi
	pop	si				;Restore flow region
	
	pushdw	axdi				;Save draw-region db-item

	; adjust the swath Y positions to be relative to the top of the
	; actual data-rectangle portion of the region

	tst	masterPageFlag
	jnz	isMasterPage
	call	ContinueToMungeRegion
	jmp	finishedLastTweaks
isMasterPage:

	; this is a master page -- we do not want the bounds in front of the
	; region (since it gets passed to GrRegOp)

	mov	ax, si
	clr	bx
	mov	cx, size Rectangle
	call	LMemDeleteAt

finishedLastTweaks:

	; now copy the result region to a DB item

	call	CopyChunkToDB			;axdi = db item
	les	bx, destTextRegion
	movdw	es:[bx], axdi

	; free the lmem block

	mov	bx, ds:[LMBH_handle]
	call	MemFree

	; all done -- return carry set to denote that the region changed

	popdw	axdi				;Restore draw-region db-item

	stc
	jmp	done

	; there is no special region

noRegion:
	clrdw	axdi				;axdi = draw region
	mov	cx, regionExistedBefore
	clc
	jcxz	done
	stc

done:

	; tell the flow object what the draw region is

	pushf
	movdw	cxdx, axdi			;cxdx = draw region
	movdw	axsi, flowObject
	mov	bx, fileHandle
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	mov	ax, MSG_FLOW_REGION_SET_DRAW_REGION
	clr	di
	call	ObjMessage
	popf

	.leave
	ret

;---

	; cx,dx = flags, return bx = handle of region

constructRegion:

	; create a gstate and clip to the region bounds

	push	cx, dx
	clr	di
	call	GrCreateState			;di = gstate

	clr	ax
	clr	bx
	mov	cx, flowSize.XYS_width
	mov	dx, flowSize.XYS_height
	mov	si, PCT_REPLACE
	call	GrSetClipRect

	movdw	dxcx, flowPosition.PD_x
	movdw	bxax, flowPosition.PD_y
	negdw	dxcx
	negdw	bxax
	call	GrApplyTranslationDWord

	call	GrInitDefaultTransform

	; draw all the grobj objects into the path

	mov	cx, PCT_REPLACE
	call	GrBeginPath
	pop	cx, dx				;recover flags

	movdw	bxsi, grobjBody
	push	bp
	mov	bp, di				;bp = gstate
	mov	ax, MSG_GB_DRAW
	clr	di
	call	ObjMessage
	mov	di, bp
	pop	bp

	call	GrEndPath

	; convert the path to a region

	mov	cl, RFR_WINDING
	call	GrGetPathRegion			;bx = region
	call	GrDestroyState

	retn

CalculateRegionForFlowRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AllocRectRegion

DESCRIPTION:	Allocate a block and stuff a rectangular region into it

CALLED BY:	INTERNAL

PASS:
	ax, bx, cx, dx - bounds

RETURN:
	bx - block

DESTROYED:
	ax, cx, dx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/18/92		Initial version

------------------------------------------------------------------------------@
AllocRectRegion	proc	near
	mov	si, bx				;si = top
	push	ax, cx
	mov	ax, size Rectangle + size RectRegion
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	ds, ax
	pop	ax, cx

	dec	cx
	mov	ds:R_left, ax
	mov	ds:R_top, si
	mov	ds:R_right, cx
	mov	ds:R_bottom, dx
	dec	si
	mov	ds:[size Rectangle].RR_y1M1, si
	mov	ds:[size Rectangle].RR_eo1, EOREGREC
	mov	ds:[size Rectangle].RR_y2, dx
	mov	ds:[size Rectangle].RR_x1, ax
	mov	ds:[size Rectangle].RR_x2, cx
	mov	ds:[size Rectangle].RR_eo2, EOREGREC
	mov	ds:[size Rectangle].RR_eo3, EOREGREC

	call	MemUnlock

	ret

AllocRectRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyRegionToChunk

DESCRIPTION:	Copy a region from a block into a chunk and free the block

CALLED BY:	INTERNAL

PASS:
	bx - handle of block containing the region
	ds - lmem block

RETURN:
	si - chunk handle

DESTROYED:
	ax, bx, cx, dx, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/19/92		Initial version

------------------------------------------------------------------------------@
CopyRegionToChunk	proc	near

	push	bx

	; get the size of the region

	push	ds
	call	MemLock
	mov	ds, ax
	mov	si, size Rectangle
	call	GrGetPtrRegBounds		;ds:si points past the end
	sub	si, size Rectangle
	mov	cx, si				;cx = size
	mov	dx, ds				;dx = block segment
	pop	ds

	; allocate a chunk and copy the region

	call	LMemAlloc			;ax = chunk
	push	ax
	mov_tr	di, ax
	mov	di, ds:[di]
	segmov	es, ds				;es:di = chunk (dest)
	mov	ds, dx
	mov	si, size Rectangle
	rep	movsb

	pop	si				;si = chunk handle
	segmov	ds, es				;ds = lmem block

	pop	bx
	call	MemFree

	ret

CopyRegionToChunk	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CopyChunkToDB

DESCRIPTION:	Copy a chunk to a db item

CALLED BY:	INTERNAL

PASS:
	*ds:si - chunk
	ss:bp - inherited variables

RETURN:
	axdi - db item

DESTROYED:
	bx, cx, dx, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/19/92		Initial version

------------------------------------------------------------------------------@
CopyChunkToDB	proc	near	uses	si
	.enter inherit CalculateRegionForFlowRegion

	mov	si, ds:[si]			;ds:si = result
	ChunkSizePtr	ds, si, cx		;cx = size
	mov	bx, fileHandle
	mov	ax, DB_UNGROUPED
	call	DBAlloc				;axdi = db item
	push	di
	call	DBLock				;*es:di = db item
	mov	di, es:[di]
	rep	movsb
	call	DBDirty
	call	DBUnlock
	pop	di

	.leave
	ret

CopyChunkToDB	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	CalculateDrawRegion

DESCRIPTION:	Calculate the draw region for a text region

CALLED BY:	INTERNAL

PASS:
	*ds:si - text region

RETURN:
	*ds:si - draw region (newly allocated chunk)

DESTROYED:
	ax, bx, cx, dx, di, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/19/92		Initial version

------------------------------------------------------------------------------@
CalculateDrawRegion	proc	near
	clr	ax
sourceChunk	local	lptr	push	si
nonEmptyFlag	local	word	push	ax
x1		local	word
x1Start		local	word	;y position where this x1 started
x1BumpIn	local	word	;if TRUE then bump xert line for x1 in at top
x2		local	word
x2Start		local	word	;y position where this x2 started
x2BumpIn	local	word	;if TRUE then bump xert line for x2 in at top
nextBandStart	local	word
destChunk	local	lptr
command		local	FlowDrawRegionElement
	.enter

	; set the starting conditions

	clr	cx
	call	LMemAlloc
	mov	destChunk, ax
	mov	si, ds:[si]
	add	si, size Rectangle	

	; we scan the region, doing something each time we hit a new band

lineLoop:
	lodsw				;ax = end of this band
	cmp	ax, EOREGREC
	LONG jz	done
	xchg	ax, nextBandStart	;ax = start of this band
	mov_tr	bx, ax			;bx = start of this band
	lodsw				;ax = x1 or EOREGREC
	cmp	ax, EOREGREC
	LONG jz	empty

	; line is non-empty, is our current start non-empty ?

	mov_tr	cx, ax			;cx = x1
	lodsw				;ax = x2

	tst	nonEmptyFlag
	LONG jz	emptyToNonEmpty

	; if x1 != old x1 then add a command to draw down and across

	cmp	cx, x1
	jz	afterX1
	xchg	cx, x1			;cx = old, store new

	; vertical line from x1Start to here (moved left)

	mov	command.FDRE_command, FDRO_VERT_LINE_BUMPED_LEFT
	tst	x1BumpIn
	jz	10$
	ornf	command.FDRE_command, mask FDRC_BUMP_START_IN
10$:

	; if OLD > NEW then bump end in

	cmp	cx, x1
	jl	20$
	ornf	command.FDRE_command, mask FDRC_BUMP_END_IN
20$:

	mov	dx, x1Start
	mov	command.FDRE_coords.FDRC_vert.FDVC_y1, dx
	mov	command.FDRE_coords.FDRC_vert.FDVC_y2, bx
	mov	command.FDRE_coords.FDRC_vert.FDVC_x, cx
	call	addCommand

	;horizontal line from old x1 to new x1, bumped down if new > old

	mov	dx, x1				;dx = new x1
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x1, cx	;assume
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x2, dx	;new > old
	mov	command.FDRE_command, FDRO_HORIZ_LINE_BUMPED_DOWN or \
					mask FDRC_BUMP_END_IN
	mov	x1BumpIn, 1
	cmp	dx, cx					;compare NEW to OLD
	jg	30$
	clr	x1BumpIn
	mov	command.FDRE_command, FDRO_HORIZ_LINE_BUMPED_UP or \
					mask FDRC_BUMP_END_IN
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x1, dx
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x2, cx
30$:
	mov	command.FDRE_coords.FDRC_horiz.FDHC_y, bx
	call	addCommand

	mov	x1Start, bx
afterX1:

	; if x2 != old x2 then add a command to draw down and acrosss

	cmp	ax, x2
	jz	afterX2
	xchg	ax, x2			;ax = old, store new

	; vertical line from x2Start to here (moved right)

	mov	command.FDRE_command, FDRO_VERT_LINE_BUMPED_RIGHT
	tst	x2BumpIn
	jz	110$
	ornf	command.FDRE_command, mask FDRC_BUMP_START_IN
110$:

	; if OLD < NEW then bump end in

	cmp	ax, x2
	jg	120$
	ornf	command.FDRE_command, mask FDRC_BUMP_END_IN
120$:

	mov	dx, x2Start
	mov	command.FDRE_coords.FDRC_vert.FDVC_y1, dx
	mov	command.FDRE_coords.FDRC_vert.FDVC_y2, bx
	mov	command.FDRE_coords.FDRC_vert.FDVC_x, ax
	call	addCommand

	;horizontal line from old x2 to new x2, bumped up if new > old

	mov	dx, x2				;dx = new x2
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x1, ax	;assume
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x2, dx	;new > old
	mov	command.FDRE_command, FDRO_HORIZ_LINE_BUMPED_UP or \
					mask FDRC_BUMP_START_IN
	clr	x2BumpIn
	cmp	dx, ax					;compare NEW to OLD
	jg	130$
	mov	x2BumpIn, 1
	mov	command.FDRE_command, FDRO_HORIZ_LINE_BUMPED_DOWN or \
					mask FDRC_BUMP_START_IN
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x1, dx
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x2, ax
130$:
	mov	command.FDRE_coords.FDRC_horiz.FDHC_y, bx
	call	addCommand

	mov	x2Start, bx
afterX2:

	; skip past rest of line data

skipToEOL:
	lodsw
	cmp	ax, EOREGREC
	LONG jz	lineLoop
	lodsw
	jmp	skipToEOL

	; we are transitioning from empty to non-empty, add a horizontal
	; line

emptyToNonEmpty:
	mov	x1, cx
	mov	x2, ax
	mov	x1Start, bx
	mov	x2Start, bx
	clr	x1BumpIn
	clr	x2BumpIn
	mov	nonEmptyFlag, 1

	mov	command.FDRE_command, FDRO_HORIZ_LINE_BUMPED_UP
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x1, cx
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x2, ax
	mov	command.FDRE_coords.FDRC_horiz.FDHC_y, bx
	call	addCommand

	jmp	skipToEOL

	; the current line is empty, we must be transitioning from non-empty
	; to empty

empty:
	tst	nonEmptyFlag
	jz	emptyToEmpty

	call	nonEmptyToEmpty
emptyToEmpty:
	jmp	lineLoop


done:
	mov	bx, nextBandStart
	call	nonEmptyToEmpty

	mov	si, destChunk
	.leave
	ret

;---

nonEmptyToEmpty:

	; add a vertical line for the left

	mov	command.FDRE_command, FDRO_VERT_LINE_BUMPED_LEFT
	tst	x1BumpIn
	jz	210$
	ornf	command.FDRE_command, mask FDRC_BUMP_START_IN
210$:
	mov	ax, x1Start
	mov	command.FDRE_coords.FDRC_vert.FDVC_y1, ax
	mov	command.FDRE_coords.FDRC_vert.FDVC_y2, bx
	mov	ax, x1
	mov	command.FDRE_coords.FDRC_vert.FDVC_x, ax
	call	addCommand

	; add a vertical line for the right (y2 is the same)

	mov	command.FDRE_command, FDRO_VERT_LINE_BUMPED_RIGHT
	tst	x1BumpIn
	jz	220$
	ornf	command.FDRE_command, mask FDRC_BUMP_START_IN
220$:
	mov	ax, x2Start
	mov	command.FDRE_coords.FDRC_vert.FDVC_y1, ax
	mov	ax, x2
	mov	command.FDRE_coords.FDRC_vert.FDVC_x, ax
	call	addCommand

	; add a horizontal line bumped down (for the bottom)

	mov	command.FDRE_command, FDRO_HORIZ_LINE_BUMPED_DOWN
	mov	ax, x1
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x1, ax
	mov	ax, x2
	mov	command.FDRE_coords.FDRC_horiz.FDHC_x2, ax
	mov	command.FDRE_coords.FDRC_horiz.FDHC_y, bx
	call	addCommand

	clr	nonEmptyFlag
	mov	x1Start, bx
	mov	x2Start, bx
	retn

;---

	; command = command to add

addCommand:
	push	ax, cx

	; compute source offset (for dereference at end)

	mov	di, sourceChunk
	sub	si, ds:[di]			;si = source offset
	push	si

	; allocate the chunk larger

	mov	ax, destChunk
	mov	di, ax
	ChunkSizeHandle	ds, di, cx
	push	cx
	add	cx, size FlowDrawRegionElement
	call	LMemReAlloc
	pop	cx

	; copy the command in

	mov	di, ds:[di]
	add	di, cx
	segmov	es, ds				;es:di = dest
	segmov	ds, ss
	lea	si, command
	mov	cx, size FlowDrawRegionElement
	rep	movsb
	segmov	ds, es

	; get ds:si pointing at the region again

	mov	di, sourceChunk
	pop	si
	add	si, ds:[di]

	pop	ax, cx
	retn

CalculateDrawRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MungeRegion

DESCRIPTION:	Take the flow region and munge it around it make the data
		how we want it

CALLED BY:	INTERNAL

PASS:
	*ds:si - region

RETURN:
	carry - set if error

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

We need to:

* Adjust the coordiate system to be document coordinates (instead of device
  coordinates)

* Set the bounds of the region to be the biggest contiguous swath

* Modify swaths with holes to have only the widest band

* Do something with very narrow swaths ???

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/23/92		Initial version

------------------------------------------------------------------------------@
MINIMUM_BAND_WIDTH	=	PIXELS_PER_INCH/2

MungeRegion	proc	near	uses si, di
regionChunk			local	lptr	push	si
nextBandStart			local	word
nextBandAfterNonEmptyStart	local	word
nextBandAfterNonEmptyOffset	local	word
regionStart			local	word
currentSwathStart		local	word
tallestSwathStart		local	word
tallestSwathHeight		local	word
tallestSwathOffset		local	word
tallestSwathSize		local	word
currentSwathOffset		local	word
swathCount			local	word
widestBandStart			local	word
widestBandOffset		local	word
widestBandWidth			local	word
bandCount			local	word
bandStartOffset			local	word
realDataExistsForSwathFlag	local	word
swathWithRealDataExistsFlag	local	word
	.enter

	mov	tallestSwathHeight, 0
	mov	swathCount, 0
	mov	swathWithRealDataExistsFlag, 0
	mov	currentSwathStart, EOREGREC
	mov	nextBandStart, EOREGREC

	mov	si, ds:[si]
	mov	regionStart, si

lineLoop:
	lodsw					;ax = start of next band
	cmp	ax, EOREGREC
	LONG jz	regionEnd
	inc	{word} ds:[si-2]		;convert to document coordinates
	inc	ax
	xchg	ax, nextBandStart
	mov_tr	bx, ax				;bx = top
	mov	widestBandWidth, 0
	mov	bandCount, 0

	cmp	{word} ds:[si], EOREGREC
	jz	incNoBands

	cmp	currentSwathStart, EOREGREC
	jnz	notSwathStart
	inc	swathCount
	mov	realDataExistsForSwathFlag, FALSE
	mov	currentSwathStart, bx
	mov	currentSwathOffset, si
	sub	currentSwathOffset, size word	;point at Y pos
notSwathStart:
	mov	bandStartOffset, si

bandLoop:
	lodsw					;ax = x1
	cmp	ax, EOREGREC
	jz	lineEnd
	mov_tr	cx, ax				;cx = x1
	inc	{word} ds:[si]			;convert to document coordinates
	lodsw
	xchg	ax, cx				;ax = x1, cx = x2

	; check to see if this is the new widest band

	mov	di, cx
	sub	di, ax
	cmp	di, widestBandWidth
	jbe	afterWidestBand
	mov	widestBandStart, ax
	mov	widestBandWidth, di
	mov	widestBandOffset, si
	sub	widestBandOffset, 2 * (size word)
afterWidestBand:
	inc	bandCount
	jmp	bandLoop

	; check to see if this is the new tallest swath

incNoBands:
	lodsw
noBands:
	call	checkTallestSwath
	mov	currentSwathStart, EOREGREC
	jmp	lineLoop

lineEnd:

	; if the widest band is still not wide enough then nuke all the bands

	; if there is more than one band nuke all but the widest

	mov	bx, bandStartOffset
	sub	bx, regionStart			;bx = offset to delete at
	mov	ax, regionChunk
	mov	cx, bandCount
	cmp	widestBandWidth, MINIMUM_BAND_WIDTH
	jb	deleteAllBands

	mov	realDataExistsForSwathFlag, TRUE
	dec	cx
	jcxz	afterBands
	shl	cx
	shl	cx				;cx = # bytes to nuke
	call	LMemDeleteAt
	mov	si, bandStartOffset
	mov	ax, widestBandStart
	mov	ds:[si], ax
	add	ax, widestBandWidth
	mov	ds:[si+2], ax
	add	si, 3 * (size word)
afterBands:
	mov	ax, nextBandStart
	mov	nextBandAfterNonEmptyStart, ax
	mov	nextBandAfterNonEmptyOffset, si
	jmp	lineLoop

	; there is no band wide enough -- delete them all

deleteAllBands:
	shl	cx
	shl	cx
	call	LMemDeleteAt
	mov	si, bandStartOffset
	add	si, size word
	jmp	noBands

regionEnd:

	call	checkTallestSwath

	; if there is more than one swath then nuke all but this swath

	tst	swathWithRealDataExistsFlag
	stc
	jz	done
	cmp	swathCount, 1
	jz	done

	; multiple swaths

	mov	ax, regionChunk
	clr	bx
	mov	cx, tallestSwathOffset
	sub	cx, regionStart
	jz	noDeleteAtFront
	sub	cx, 2 * (size word)		;room for Y $
	call	LMemDeleteAt
	mov	si, regionStart
	mov	cx, tallestSwathStart
	mov	ds:[si], cx
noDeleteAtFront:
	mov	cx, tallestSwathSize
	add	cx, 3 * (size word)		;for last EOREGREC
	call	LMemReAlloc
	mov	si, regionStart
	add	si, cx
	mov	ds:[si-(size word)], EOREGREC
	clc
done:
	.leave
	ret

;---

checkTallestSwath:
	mov	ax, currentSwathStart
	cmp	ax, EOREGREC
	jz	notTallestSwath
	tst	realDataExistsForSwathFlag
	jz	notTallestSwath
	inc	swathWithRealDataExistsFlag
	mov	bx, nextBandAfterNonEmptyStart
	sub	bx, ax
	cmp	bx, tallestSwathHeight
	jbe	notTallestSwath
	mov	tallestSwathStart, ax
	mov	tallestSwathHeight, bx
	mov	ax, currentSwathOffset
	mov	tallestSwathOffset, ax
	mov	cx, nextBandAfterNonEmptyOffset
	sub	cx, ax
	mov	tallestSwathSize, cx
notTallestSwath:
	retn

MungeRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ContinueToMungeRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the region data to be relative to the top of the
		data-bounding rectangle.

CALLED BY:	CalculateRegionForFlowRegion
PASS:		*ds:si	= Pointer to region (after rectangle is inserted)
RETURN:		region adjusted
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ContinueToMungeRegion	proc	near
	uses	ax, dx, si
	.enter
	;
	; Get a pointer to the region and the position which we want the
	; region relative to.
	;
	mov	si, ds:[si]		; ds:si <- ptr to rectangle
	mov	dx, ds:[si].R_top	; dx <- Position
	
	add	si, size Rectangle	; ds:si <- ptr to first swath

swathLoop:
	;
	; ds:si	= Pointer to current swath
	; dx	= Position to make region relative to
	;
	cmp	{word} ds:[si], EOREGREC ; Check for end of region
	je	endLoop			; Branch if we're at the end
	
	;
	; Not at the end of the swath. ds:si points at the Y position for
	; this swath.
	;
	sub	{word} ds:[si], dx	; Adjust this swath
	add	si, size word		; Advance past the Y position
	
	;
	; Skip to the next swath
	;
skipSwathLoop:
	lodsw				; ax <- next on/off point
	cmp	ax, EOREGREC		; Check for end of swath
	jne	skipSwathLoop		; Loop until we get past it
	
	jmp	swathLoop		; Loop to do the next swath

endLoop:
	;
	; All done...
	;
	.leave
	ret
ContinueToMungeRegion	endp


DocRegion ends
