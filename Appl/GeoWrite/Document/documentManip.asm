COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentSection.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for WriteDocumentClass

	$Id: documentManip.asm,v 1.1 97/04/04 15:56:01 newdeal Exp $

------------------------------------------------------------------------------@

DocRegion segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentFlowRegionChanged --
		MSG_WRITE_DOCUMENT_FLOW_REGION_CHANGED for WriteDocumentClass

DESCRIPTION:	handle a flow region change

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	bp - FlowRegionChangedParams

RETURN:
	bp - based on GrObjActionNotificationType
	     GOANT_QUERY_DELETE - zero to abort the deletion

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentFlowRegionChanged	method dynamic	WriteDocumentClass,
					MSG_WRITE_DOCUMENT_FLOW_REGION_CHANGED
	movdw	cxdx, ss:[bp].FRCP_object
	mov	di, bp

grobjObject	local	optr		push	cx, dx
docObject	local	fptr		push	ds, si
operation	local	GrObjActionNotificationType	\
					push	ss:[di].FRCP_action
fileHandle	local	hptr
grobjBody	local	optr
grobjSize	local	XYSize
grobjBounds	local	RectDWord
	.enter

	call	IgnoreUndoNoFlush

	call	GetFileHandle
	mov	fileHandle, bx

	call	LockMapBlockES
	mov	ax, es:MBH_grobjBlock
	call	VMVMBlockToMemBlock			;ax = mem block
	mov	grobjBody.handle, ax
	mov	grobjBody.chunk, offset MainBody
	call	VMUnlockES

	; get the object's position and size

	push	bp
	lea	bp, grobjBounds
	call	GetGrObjBounds
	pop	bp

	call	MemBlockToVMBlockCX

	; first figure out where this change occurred

	call	GetFileHandle			;bx = file handle
	mov	ax, ss:[di].FRCP_masterPage
	cmp	operation, GOANT_PASTED
	LONG jz pasteRegion
	tst	ax
	LONG jz	articleRegion

	; *** the change happened to a master page

	; change the correct array entry

	push	ax				;save master page
	push	bp
	call	VMLock
	pop	bp

	mov	ds, ax
	mov	si, offset FlowRegionArray
	mov	si, ds:[si]
EC <	mov	di, ds:[si].CAH_count					>
	add	si, ds:[si].CAH_offset
findFlowRegionLoop:
	cmpdw	cxdx, ds:[si].FRAE_flowObject
	jz	flowRegionFound
	add	si, size FlowRegionArrayElement
EC <	dec	di							>
EC <	ERROR_Z	FLOW_REGION_NOT_FOUND					>
	jmp	findFlowRegionLoop
flowRegionFound:

	; are we querying to delete a flow region ?

	cmp	operation, GOANT_QUERY_DELETE
	jz	queryDeleteFlowRegion

	; are we deleting a flow region ?

	cmp	operation, GOANT_DELETED
	jz	deleteFlowRegion

	; set the position and size

setFlowRegionCommon::
	mov	ax, grobjBounds.RD_left.low
	mov	ds:[si].FRAE_position.XYO_x, ax
	mov	ax, grobjBounds.RD_top.low
	mov	ds:[si].FRAE_position.XYO_y, ax

	mov	ax, grobjSize.XYS_width
	mov	ds:[si].FRAE_size.XYS_width, ax
	mov	ax, grobjSize.XYS_height
	mov	ds:[si].FRAE_size.XYS_height, ax

	; recalculate the article regions for the section

recalcCommon:
	call	VMDirtyDS
	call	VMUnlockDS

	pop	cx				;cx = master page block
	movdw	dssi, docObject
	call	LockMapBlockES
	call	FindSectionByMasterPage
EC <	ERROR_NC SECTION_NOT_FOUND					>
	call	RecalculateArticleRegions
	call	VMUnlockES
	jmp	done

	; the user wants to delete a flow region

queryDeleteFlowRegion:

	mov	di, si
	mov	si, offset FlowRegionArray
	call	ChunkArrayGetCount
	cmp	cx, 1
	jnz	canDelete

	mov	{word} ss:[bp], 0		;return "don't delete"
	mov	ax, offset CannotDeleteLastFlowRegionString
	call	DisplayError
canDelete:

	call	VMUnlockDS
	pop	cx				;discard master page block
	jmp	done

	; a flow region has been deleted

deleteFlowRegion:

	mov	di, si
	call	DeleteFlowRegionAccessories

	mov	si, offset FlowRegionArray
	call	ChunkArrayDelete
	jmp	recalcCommon

;--------------------------

articleRegion:

	; *** the change happened in an article region ***

	; lock the article block and find the assocaited region

	mov	ax, ss:[di].FRCP_article
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjLockObjBlock
	mov	ds, ax

	mov	si, offset ArticleRegionArray
	mov	si, ds:[si]
	clr	bx					;bx = region number
EC <	mov	di, ds:[si].CAH_count					>
	add	si, ds:[si].CAH_offset
findArticleRegionLoop:
	cmpdw	cxdx, ds:[si].ARAE_object
	jz	articleRegionFound
	inc	bx
	add	si, size ArticleRegionArrayElement
EC <	dec	di							>
EC <	ERROR_Z	ARTICLE_REGION_NOT_FOUND				>
	jmp	findArticleRegionLoop
articleRegionFound:

	; are we querying to delete an article flow region ?

	cmp	operation, GOANT_QUERY_DELETE
	LONG jz	queryDeleteArticleFlowRegion

	; are we deleting an article flow region ?

	cmp	operation, GOANT_DELETED
	LONG jz	deleteArticleFlowRegion

	; set the position and size

setArticleRegionCommon::

	movdw	ds:[si].VLTRAE_spatialPosition.PD_x, grobjBounds.RD_left, ax
	movdw	ds:[si].VLTRAE_spatialPosition.PD_y, grobjBounds.RD_top, ax

	mov	ax, grobjSize.XYS_width
	mov	ds:[si].VLTRAE_size.XYS_width, ax
	mov	ax, grobjSize.XYS_height
	mov	ds:[si].VLTRAE_size.XYS_height, ax

	; if we are in manual mode then we need to add the region's area to
	; the invalid area, else we have to recalculate it

	push	bx			;save region number
	call	WriteGetDGroupES
	test	es:[miscSettings], mask WMS_AUTOMATIC_LAYOUT_RECALC
	jz	manualRecalc

	mov	di, si			;ds:di = ArticleRegionArrayElement
	mov	ax, fileHandle
	movdw	bxsi, grobjBody
	call	RecalcOneFlowRegion
	jmp	articleCommon

manualRecalc:
	push	ds
	movdw	axdx, ds:[si].ARAE_object
	movdw	dssi, docObject
	call	WriteVMBlockToMemBlock
	mov_tr	cx, ax			;cxdx = grobj object
	call	AddCXDXToInvalidRect
	pop	ds
articleCommon:
	pop	bx			;recover region number

	; notify the text object that the region has changed

recalcArticleCommon:
	push	bp
	mov	ax, MSG_VIS_LARGE_TEXT_REGION_CHANGED
	mov	cx, bx
	mov	si, offset ArticleText
	call	ObjMarkDirty
	call	ObjCallInstanceNoLock
	pop	bp

articleDone:
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

done:

	call	AcceptUndo

	.leave
	ret

	; an article flow region has been deleted

queryDeleteArticleFlowRegion:

	mov	di, si

if 0
	mov	si, offset ArticleRegionArray
	call	ChunkArrayGetCount
	cmp	cx, 1
	jnz	canDeleteArticleRegion
else
	;
	; ensure more than one region in section
	;
	mov	bx, ds:[di].ARAE_meta.VLTRAE_section	;bx = section number
	clr	di					;di = none found yet
	mov	si, offset ArticleRegionArray
	mov	si, ds:[si]
	mov	cx, ds:[si].CAH_count
	add	si, ds:[si].CAH_offset
checkArticleRegionLoop:
	cmp	bx, ds:[si].ARAE_meta.VLTRAE_section
	jne	checkNextArticleRegion
	inc	di
checkNextArticleRegion:
	add	si, size ArticleRegionArrayElement
	loop	checkArticleRegionLoop
	cmp	di, 1					;(can't be zero)
	jne	canDeleteArticleRegion
endif

	mov	{word} ss:[bp], 0		;return "don't delete"
	mov	ax, offset CannotDeleteLastArticleRegionString
	call	DisplayError
canDeleteArticleRegion:

	jmp	articleDone

	; an article flow region has been deleted

deleteArticleFlowRegion:

	mov	di, si
	call	DeleteArticleRegionAccessories

	; figure out which region to give our text to

	;
	; When deleting elements, we donate to the previous region, unless
	; this is the first region, in which case we donate to the next one.
	;
	; For recalculation, we need to recalculate in the region we donate to.
	; If this is the next region, when we delete our region, the next one
	; moves down to get the same region-number as the current one. Sigh...
	;
	mov	si, offset ArticleRegionArray
	call	ChunkArrayPtrToElement		;ax = element
	push	ax				;save current element
	dec	ax				;if this is not the first region
	jns	gotRegionToDonateTo		;then use the previous
	mov	ax, 1				;else use the next
gotRegionToDonateTo:
	mov	bx, di				;ds:bx = region to nuke
	call	ChunkArrayElementToPtr		;ds:di = region to donate to
	adddw	ds:[di].VLTRAE_charCount, ds:[bx].VLTRAE_charCount, ax
	adddw	ds:[di].VLTRAE_lineCount, ds:[bx].VLTRAE_lineCount, ax
	addwbf	ds:[di].VLTRAE_calcHeight, ds:[bx].VLTRAE_calcHeight, ax

;	We want to set the EMPTY flag in the dest region *only* if the empty
;	flag was set in both regions originally.

	mov	ax, ds:[di].VLTRAE_flags
	and	ax, ds:[bx].VLTRAE_flags ;AX <- flags set in both
					 ; regions
	andnf	ax, mask VLTRF_EMPTY	 ;AX <- VLTRF_EMPTY if both regions had
					 ; that flag set
	andnf	ds:[di].VLTRAE_flags, not mask VLTRF_EMPTY
	ornf	ds:[di].VLTRAE_flags, ax ;Set VLTRF_EMPTY flag in dest region 
					 ; if it was set in both original regs
	mov	di, bx	
	call	ChunkArrayDelete

	pop	bx				;bx = region we started at
	tst	bx				;check for donate to next
	LONG jz	recalcArticleCommon
	
	;
	; We did not delete the first region, which means we donated to the
	; previous one.
	;
	dec	bx				;move to previous region
	jmp	recalcArticleCommon

;--------------------------------

pasteRegion:

if _ALLOW_FLOW_REGION_PASTE

	; *** a region has been pasted in ***

	tst	ax
	jz	articleRegionPasted

	; *** a master page region has been pasted -- try to find the master
	; page

	mov_tr	cx, ax				;cx = master page block
	call	LockMapBlockES
	call	FindSectionByMasterPage
	jnc	flowRegionNotFound

	; lock the master page block

	call	VMUnlockES
	push	cx				;save master page block
	mov_tr	ax, cx
	push	bp
	call	VMLock
	pop	bp

	; search the flow region array for where to put this new flow region

	mov	ds, ax
	mov	si, offset FlowRegionArray
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	add	di, ds:[di].CAH_offset
findInsertLoop:
	mov	dx, ds:[di].VLTRAE_section

	; look for a region that we are to the right of

	mov	ax, grobjBounds.RD_left.low
	cmp	ax, ds:[di].FRAE_position.XYO_x
	ja	next
	jb	foundPos
	mov	ax, grobjBounds.RD_top.low
	cmp	ax, ds:[di].FRAE_position.XYO_y
	jb	foundPos
next:
	add	di, size FlowRegionArrayElement
	loop	findInsertLoop

foundPos:

	; ds:di = position to insert before

	call	ChunkArrayInsertAt

	mov	si, di
	mov	ds:[si].FRAE_article, dx

	mov	cx, grobjObject.handle
	call	MemBlockToVMBlockCX
	mov	ds:[si].FRAE_flowObject.handle, cx
	mov	ax, grobjObject.chunk
	mov	ds:[si].FRAE_flowObject.chunk, ax
	jmp	setFlowRegionCommon

flowRegionNotFound:

	;
	; Clear the flow region via the queue, so that it doesn't get
	; nuked until after we're done here.  Don't have it notify the
	; document, as the document has no record of the flow region,
	; and will get confused.
	;
	call	VMUnlockES

	; the master page does not exist -- delete the object

endif

	mov	ax, MSG_FLOW_REGION_CLEAR_NO_NOTIFY
	movdw	bxsi, grobjObject
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	jmp	done

;-------------------------

if _ALLOW_FLOW_REGION_PASTE

articleRegionPasted:

	; *** an article region has been pasted -- try to find the article

	mov	cx, ss:[di].FRCP_article		;cx = article block
	call	LockMapBlockES
	call	FindArticleByBlock
	jnc	flowRegionNotFound

	; lock the article block

	call	VMUnlockES
	mov_tr	ax, cx
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjLockObjBlock
	mov	ds, ax				;ds = article block


	; search the article region array for where to put this new flow region

	mov	si, offset ArticleRegionArray
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	add	di, ds:[di].CAH_offset
findInsertArticleLoop:
	mov	dx, ds:[di].VLTRAE_section

	; look for a region that we are below

	cmpdw	grobjBounds.RD_top, ds:[di].VLTRAE_spatialPosition.PD_y, ax
	ja	nextArticleRegion
	jb	foundArticlePos
	cmpdw	grobjBounds.RD_left, ds:[di].VLTRAE_spatialPosition.PD_x, ax
	jb	foundArticlePos
nextArticleRegion:
	add	di, size ArticleRegionArrayElement
	loop	findInsertArticleLoop

foundArticlePos:

	; ds:di = position to insert before

	;
	; if the region we are inserting before isn't empty, we can't mark
	; ourselves empty
	;
	test	ds:[di].VLTRAE_flags, mask VLTRF_EMPTY
	pushf
	call	ChunkArrayInsertAt
	popf
	jz	wasntEmpty
	mov	ds:[di].VLTRAE_flags, mask VLTRF_EMPTY
wasntEmpty:
	call	ChunkArrayPtrToElement			;ax = element
	mov_tr	bx, ax					;bx = element (region
							;to recalculate)
	mov	si, di

	mov	ds:[si].VLTRAE_section, dx

	mov	cx, grobjObject.handle
	call	MemBlockToVMBlockCX
	mov	ds:[si].ARAE_object.handle, cx
	mov	ax, grobjObject.chunk
	mov	ds:[si].ARAE_object.chunk, ax
	jmp	setArticleRegionCommon

endif

WriteDocumentFlowRegionChanged	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	GetGrObjBounds

DESCRIPTION:	Get the of a grobj object

CALLED BY:	INTERNAL

PASS:
	ds - fixup-able segment
	cx:dx - grobj object
	ss:bp - RectDWord followed by XYSize

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
	Tony	9/18/92		Initial version

------------------------------------------------------------------------------@
GetGrObjBounds	proc	near	uses ax, bx, cx, dx, si, di
	.enter

	; get the bounds

	movdw	bxsi, cxdx
	mov	ax, MSG_GO_GET_DW_PARENT_BOUNDS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; GrObj returns us the bounds of the object accounting for the line
	; width, so we need to bump the bounds inwards on each side by
	; half of the line width (rounded up). - DLR 2/15/95

	push	bp
	clr	di
	call	GrCreateState			; di <- temporary GState

	mov	ax, MSG_GO_APPLY_ATTRIBUTES_TO_GSTATE
	mov	bp, di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	di, bp
	call	GrGetLineWidth			; dx.ax <- line width
	call	GrDestroyState

	sarwwf	dxax				; calculate half of line width
	tst	ax				; calculate ceiling...
	jz	compensate
	inc	dx
compensate:
	add	dx, FLOW_REGION_BOUNDS_BUMP	; add in flow region border
	clr	ax				; high word is always zero
	pop	bp

	; Adjust the bounds, and calculate width & height

	adddw	ss:[bp].RD_left, axdx
	adddw	ss:[bp].RD_top, axdx
	subdw	ss:[bp].RD_right, axdx
	subdw	ss:[bp].RD_bottom, axdx

	mov	ax, ss:[bp].RD_right.low
	sub	ax, ss:[bp].RD_left.low
	mov	ss:[bp+(size RectDWord)].XYS_width, ax
	mov	ax, ss:[bp].RD_bottom.low
	sub	ax, ss:[bp].RD_top.low
	mov	ss:[bp+(size RectDWord)].XYS_height, ax

	.leave
	ret

GetGrObjBounds	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindSectionByMasterPage

DESCRIPTION:	Find a section given a master page block

CALLED BY:	INTERNAL

PASS:
	es - map block (locked)
	cx - master page VM block

RETURN:
	es:di - SectionArrayElement
	carry - set if found

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
FindSectionByMasterPage	proc	near	uses ax, bx, dx, si, ds
	.enter

	segmov	ds, es
	mov	si, offset SectionArray
	mov	bx, cs
	mov	di, offset FindSectionByMasterPageCallback
	call	ChunkArrayEnum			;dx = offset of element
	mov	di, dx

	.leave
	ret

FindSectionByMasterPage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindSectionByMasterPageCallback

DESCRIPTION:	Callback for finding a section via the master page block

CALLED BY:	INTERNAL

PASS:
	ds:di - SectionArrayElement
	cx - master page block

RETURN:
	carry - set if found
	dx - offset of SectionArrayElement

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
FindSectionByMasterPageCallback	proc	far
	cmp	cx, {word} ds:[di].SAE_masterPages
	jz	found
	cmp	cx, {word} ds:[di].SAE_masterPages+2
	jz	found

	clc
	ret

found:
	mov	dx, di
	stc
	ret

FindSectionByMasterPageCallback	endp

;needed by _ALLOW_FLOW_REGION_PASTE
;if _INDEX_NUMBERS

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindArticleByBlock

DESCRIPTION:	Find an article given the article block

CALLED BY:	INTERNAL

PASS:
	es - map block (locked)
	cx - master page VM block

RETURN:
	es:di - ArticleArrayElement
	carry - set if found

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
FindArticleByBlock	proc	near	uses ax, bx, dx, si, ds
	.enter

	segmov	ds, es
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset FindArticleByBlockCallback
	call	ChunkArrayEnum			;dx = offset of element
	mov	di, dx

	.leave
	ret

FindArticleByBlock	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	FindArticleByBlockCallback

DESCRIPTION:	Callback for finding a section via the master page block

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	cx - master page block

RETURN:
	carry - set if found
	dx - offset of ArticleArrayElement

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
FindArticleByBlockCallback	proc	far
	cmp	cx, ds:[di].AAE_articleBlock
	jz	found
	clc
	ret

found:
	mov	dx, di
	stc
	ret

FindArticleByBlockCallback	endp

;endif

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentPreWrapNotification --
		MSG_WRITE_DOCUMENT_GROBJ_PRE_WRAP_NOTIFICATION
						for WriteDocumentClass

DESCRIPTION:	Notification that the wrap area is about to change

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx:dx - grobj object
	bp - master page VM block (or 0 for main body)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/18/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentPreWrapNotification	method dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_GROBJ_PRE_WRAP_NOTIFICATION

	; if master page then do nothing

	tst	bp
	jnz	done

	; main body -- and to invalid region

	call	AddCXDXToInvalidRect

done:
	ret

WriteDocumentPreWrapNotification	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentWrapNotification --
		MSG_WRITE_DOCUMENT_GROBJ_WRAP_NOTIFICATION
						for WriteDocumentClass

DESCRIPTION:	Notification that the wrap area has changed

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

	ax - The message

	cx:dx - grobj object
	bp - master page VM block (or 0 for main body)

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/18/92		Initial version

------------------------------------------------------------------------------@
WriteDocumentWrapNotification	method dynamic	WriteDocumentClass,
				MSG_WRITE_DOCUMENT_GROBJ_WRAP_NOTIFICATION

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	; if master page then recalculate it

	tst	bp
	jz	mainBody

	mov	cx, bp				;cx = master page block
	call	LockMapBlockES
	call	FindSectionByMasterPage
EC <	ERROR_NC SECTION_NOT_FOUND					>
	call	RecalculateArticleRegions
	call	VMUnlockES
	jmp	done

	; main body -- and to invalid region and then recalculate if in
	;	       automatic mode

mainBody:
	call	AddCXDXToInvalidRect

	GetResourceSegmentNS dgroup, es		;es = dgroup	
	test	es:[miscSettings], mask WMS_AUTOMATIC_LAYOUT_RECALC
	jz	done
	call	RecalculateInvalidArticleRegions
done:

	pop	di
	call	ThreadReturnStackSpace

	ret

WriteDocumentWrapNotification	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddCXDXToInvalidRect

DESCRIPTION:	Add the bounds of the graphics obejct CXDX to the invalid
		rectangle stored in the map block

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	cxdx - grobj object

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
	Tony	9/18/92		Initial version

------------------------------------------------------------------------------@
AddCXDXToInvalidRect	proc	near	uses ds
grobjSize	local	XYSize
grobjBounds	local	RectDWord
	ForceRef grobjSize
	.enter

	push	bp
	lea	bp, grobjBounds
	call	GetGrObjBounds
	pop	bp

	call	LockMapBlockDS

	push	bp
	lea	bp, grobjBounds
	call	AddRectToInval
	pop	bp

	call	VMUnlockDS

	.leave
	ret

AddCXDXToInvalidRect	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddRectToInval

DESCRIPTION:	Add the bounds of the graphics obejct CXDX to the invalid
		rectangle stored in the map block

CALLED BY:	INTERNAL

PASS:
	ds - map block
	ss:bp - RectDWord of bounds to add

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
	Tony	9/18/92		Initial version

------------------------------------------------------------------------------@
AddRectToInval	proc	far	uses cx, si
	.enter

	; is there a valid rectangle ?

	tstdw	ds:MBH_invalidRect.RD_bottom
	jz	copy				;no - copy this one in

	movdw	cxsi, ss:[bp].RD_left
	cmpdw	cxsi, ds:MBH_invalidRect.RD_left
	jae	afterLeft
	movdw	ds:MBH_invalidRect.RD_left, cxsi
afterLeft:

	movdw	cxsi, ss:[bp].RD_top
	cmpdw	cxsi, ds:MBH_invalidRect.RD_top
	jae	afterTop
	movdw	ds:MBH_invalidRect.RD_top, cxsi
afterTop:

	movdw	cxsi, ss:[bp].RD_right
	cmpdw	cxsi, ds:MBH_invalidRect.RD_right
	jbe	afterRight
	movdw	ds:MBH_invalidRect.RD_right, cxsi
afterRight:

	movdw	cxsi, ss:[bp].RD_bottom
	cmpdw	cxsi, ds:MBH_invalidRect.RD_bottom
	jbe	afterBottom
	movdw	ds:MBH_invalidRect.RD_bottom, cxsi
afterBottom:
	jmp	done

copy:
	push	di, ds, es
	segmov	es, ds
	mov	di, offset MBH_invalidRect
	segmov	ds, ss
	lea	si, ss:[bp]
	mov	cx, (size RectDWord) / 2
	rep	movsw
	pop	di, ds, es

done:
	call	VMDirtyDS

	.leave
	ret

AddRectToInval	endp

DocRegion ends
