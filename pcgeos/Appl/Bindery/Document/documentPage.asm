COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentPage.asm

ROUTINES:
	Name				Description
	----				-----------
    INT AddDeletePageToSection	Add or delete a set of pages to a section

    INT CreateArticleRegionCallback 
				Create an article region (as page of
				creating a page)

    INT ClearArticleTextCachedRegion 
				Clear the cached region for an ArticleText

    INT DoesSpaceContainGraphics 
				See if a given area contains graphics

    INT SetFlowRegionAssociation 
				Set the data the associates a flow region
				with something

    INT InsertOrDeleteSpace	Insert vertical space in the document

    INT InsDelSpaceInArticleCallback 
				Insert or delete space in an article

    INT DeleteArticleRegion	Update the region array (and possibly the
				section array) for a deleted region

    INT SuspendFlowRegionNotifications 
				Suspend flow region notifications

    INT UnsuspendFlowRegionNotifications 
				Suspend flow region notifications

METHODS:
	Name			Description
	----			-----------
    StudioDocumentAppendPagesViaPosition  
				Append pages after the given position

				MSG_STUDIO_DOCUMENT_APPEND_PAGES_VIA_POSITION
				StudioDocumentClass

    StudioDocumentDeletePagesAfterPosition  
				Delete all pages in a section after a given
				position

				MSG_STUDIO_DOCUMENT_DELETE_PAGES_AFTER_POSITION
				StudioDocumentClass

    StudioDocumentInsertAppendPagesLow  
				Low-level insert/append pages

				MSG_STUDIO_DOCUMENT_INSERT_APPEND_PAGES_LOW
				StudioDocumentClass

    StudioDocumentGetGraphicTokensForStyle  
				Get the graphic attribute tokens for a
				style

				MSG_STUDIO_DOCUMENT_GET_GRAPHIC_TOKENS_FOR_STYLE
				StudioDocumentClass

    StudioDocumentGetTextTokensForStyle  
				Get the text attribute tokens for a style

				MSG_STUDIO_DOCUMENT_GET_TEXT_TOKENS_FOR_STYLE
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the section related code for StudioDocumentClass

	$Id: documentPage.asm,v 1.1 97/04/04 14:39:23 newdeal Exp $

------------------------------------------------------------------------------@

DocPageCreDest segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentAppendPagesViaPosition --
		MSG_STUDIO_DOCUMENT_APPEND_PAGES_VIA_POSITION
						for StudioDocumentClass

DESCRIPTION:	Append pages after the given position

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - x pos
	dxbp - y pos

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentAppendPagesViaPosition	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_APPEND_PAGES_VIA_POSITION

	; We know that this happens as a result of an APPEND_SECTION from
	; an article.  We want to partially suspend the document so that
	; the document size is not sent to the view until IS_LAST.

	ornf	ds:[di].SDI_state, mask SDS_SUSPENDED_FOR_APPENDING_REGIONS

	; calculate page number

	call	LockMapBlockES

	call	FindPageAndSectionAbs		;cx = section, dx = page
EC <	ERROR_C	FIND_PAGE_RETURNED_ERROR				>
	mov_tr	ax, dx
	call	MapPageToSectionPage		;ax = section
						;bx = page in section

	call	VMUnlockES
	mov_tr	cx, ax				;cx = section #
	mov	bp, bx				;bp = page # in section
	mov	dx, MSG_STUDIO_DOCUMENT_APPEND_PAGE

	mov	ax, MSG_STUDIO_DOCUMENT_INSERT_APPEND_PAGES_LOW
	call	ObjCallInstanceNoLock

	ret

StudioDocumentAppendPagesViaPosition	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentDeletePagesAfterPosition --
		MSG_STUDIO_DOCUMENT_DELETE_PAGES_AFTER_POSITION
						for StudioDocumentClass

DESCRIPTION:	Delete all pages in a section after a given position

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - x pos
	dxbp - y pos

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentDeletePagesAfterPosition	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_DELETE_PAGES_AFTER_POSITION

	ornf	ds:[di].SDI_state, mask SDS_SUSPENDED_FOR_APPENDING_REGIONS

	; calculate page number

	call	LockMapBlockES

	call	FindPageAndSectionAbs		;cx = section, dx = page
	mov_tr	ax, dx
	call	MapPageToSectionPage		;ax = section
						;bx = page in section
	inc	bx				;bx = page # to nuke

	; we want to delete all pages *after* this page

	call	SectionArrayEToP_ES
	mov	cx, es:[di].SAE_numPages	;cx = # pages in section

	sub	cx, bx				;cx = # of pages to nuke
	jcxz	done

	; ax = section, bx = page #

nukeLoop:
	push	cx
	mov	cx, 1				;set delete flag
	clr	dx				;not direct user action
	call	AddDeletePageToSection
	pop	cx
	loop	nukeLoop

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	; if there is an invalid area (and we are in automatic recalc mode)
	; then something unusual happened (like moving wrap around graphics
	; from a deleted page)

	push	es
	call	StudioGetDGroupES
	test	es:[miscSettings], mask SMS_AUTOMATIC_LAYOUT_RECALC
	pop	es
	jz	noRecalc
	tstdw	es:MBH_invalidRect.RD_bottom
	jz	noRecalc
	mov	ax, MSG_STUDIO_DOCUMENT_RECALC_INVAL
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
noRecalc:
	mov	cl, 1				; delete
	mov	ax, MSG_STUDIO_DOCUMENT_RECALC_HOTSPOTS
	call	ObjCallInstanceNoLock

done:

	; We know that this happens as a result of an IS_LAST from
	; an article.  We want to take care of any pending suspends

EC <	call	AssertIsStudioDocument					>

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	andnf	ds:[di].SDI_state, not mask SDS_SUSPENDED_FOR_APPENDING_REGIONS

	test	ds:[di].SDI_state, mask SDS_SEND_SIZE_PENDING
	jz	noSendSize
	andnf	ds:[di].SDI_state, not mask SDS_SEND_SIZE_PENDING
	call	ReallySendDocumentSizeToView
noSendSize:

	call	VMUnlockES

	ret

StudioDocumentDeletePagesAfterPosition	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentInsertAppendPagesLow --
		MSG_STUDIO_DOCUMENT_INSERT_APPEND_PAGES_LOW
							for StudioDocumentClass

DESCRIPTION:	Low-level insert/append pages

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - section #
	dx - MSG_STUDIO_DOCUMENT_INSERT_PAGE to insert or
	     MSG_STUDIO_DOCUMENT_APPEND_PAGE to append
	bp - page # in section

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/27/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentInsertAppendPagesLow	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_INSERT_APPEND_PAGES_LOW

	mov_tr	ax, cx				;ax = section #
	mov	bx, bp				;bx = page # in section

	call	LockMapBlockES

	; get the number of pages to insert/delete and the offset to do so

	push	dx
	call	SectionArrayEToP_ES		;es:di = SectionArrayElement
	xchg	ax, bx				;ax = page in section
						;bx = section #
	clr	dx				;dxax = page #
	mov	cx, es:[di].SAE_numMasterPages
	div	cx				;ax = set #, dx = remainder
	mul	cx				;ax = offset of group
	xchg	ax, bx				;ax = section number
						;bx = page in section
	pop	dx

	cmp	dx, MSG_STUDIO_DOCUMENT_INSERT_PAGE
	jz	10$
	add	bx, cx				;if append then move one page
	cmp	bx, es:[di].SAE_numPages	;further

	; if we are appending at the end then we need only do one page at a time

	jb	10$
	mov	bx, es:[di].SAE_numPages
	mov	cx, 1
10$:

createLoop:
	push	cx
	clr	cx
	clr	dx				;not direct user action
	call	AddDeletePageToSection
	inc	bx
	pop	cx
	loop	createLoop

	call	VMDirtyES

	; redraw the document (unless we are in galley or draft mode)

	cmp	es:MBH_displayMode, VLTDM_GALLEY
	call	VMUnlockES
	jae	noInvalidate
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
noInvalidate:
	mov	cl, 0				; not delete
	mov	ax, MSG_STUDIO_DOCUMENT_RECALC_HOTSPOTS
	GOTO	ObjCallInstanceNoLock

StudioDocumentInsertAppendPagesLow	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	AddDeletePageToSection

DESCRIPTION:	Add or delete a set of pages to a section

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - locked map block
	ax - section to add pages to
	bx - page number (in section) to insert before
	cl - non-zero for delete
	ch - non-zero to create only (no insert)
	dx - non-zero if this is a direct user action

RETURN:
	carry - set if aborted

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
AddDeletePageToSection	proc	far	uses ax, bx, cx, dx, di
section		local	word	push	ax
pageNum		local	word	push	bx
docobj		local	fptr	push	ds, si
mapBlock	local	sptr	push	es
flags		local	word	push	cx
userActionFlag	local	word	push	dx
insDelParam	local	InsertDeleteSpaceTypes
position	local	dword
vmFile		local	word
numRegions	local	word
insertPos	local	word
invalRect	local	RectDWord
	ForceRef section
	ForceRef docobj
	ForceRef mapBlock
	ForceRef numRegions
createOnlyFlag	equ	flags.high
deleteFlag	equ	flags.low
	.enter
EC <	call	AssertIsStudioDocument					>

	call	IgnoreUndoNoFlush

	call	SuspendFlowRegionNotifications

	call	GetFileHandle
	mov	vmFile, bx

	; insertPos keeps the region number to insert AFTER.  It starts at
	; null because we must search the article table to figure out where
	; to put the first region, but subsequent regions on the same page go
	; in order so that we maintain the order from the master page

	mov	insertPos, CA_NULL_ELEMENT

	; assume we are biffing objects

	mov	insDelParam, mask \
	  IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELETED_SPACE or\
		mask IDST_RESIZE_OBJECTS_INTERSECTING_SPACE or \
		mask IDST_DELETE_OBJECTS_SHRUNK_TO_ZERO_SIZE

	; add space to the document

	push	ax
	call	SectionArrayEToP_ES
	mov	ax, es:MBH_pageSize.XYS_height
	mov	cx, ax			;cx = page height
	mul	pageNum			;dxax = position in this section
	movdw	position, dxax
	pop	ax

	call	FindSectionPosition	;dxax = y position
	adddw	position, dxax

	mov	bx, cx
	clr	cx			;cxbx = page height (space to add)
	movdw	dxax, position		;dx.ax = position to add space

	tst	createOnlyFlag
	LONG jnz afterSpace

	; if deleting then check for graphic objects on the page

	tst	deleteFlag
	LONG jz	doIt

	negdw	cxbx				;we're deleting so make
						;space negative

	tst	userActionFlag
	LONG jnz doIt

	call	DoesSpaceContainGraphics	;any graphics on the page?
	jnc	doIt

if 0	; not used in Condo
		
	; if the user has chosen "do not delete pages with graphics"
	; then honor that request

	push	ds
	call	StudioGetDGroupDS
	test	ds:[miscSettings], mask SMS_DO_NOT_DELETE_PAGES_WITH_GRAPHICS
	pop	ds
	jz	10$
toDone:
	jmp	done
10$:

	push	cx
	mov	ax, offset DeleteGraphicsOnPageString
	mov	cx, offset DeleteGraphicsOnPageTable
	mov	dx, CustomDialogBoxFlags \
			<0, CDT_QUESTION, GIT_MULTIPLE_RESPONSE,0>
	call	ComplexQuery			;ax = InteractionCommand
	pop	cx
	cmp	ax, IC_NULL
	stc
	jz	toDone
	cmp	ax, IC_DISMISS			;DISMISS = Cancel
	stc
	jz	toDone
	cmp	ax, IC_NO			;NO = Move
	jnz	doIt				;YES = Delete
endif
	; it is a move -- set the correct flags and force some recalculation

	mov	insDelParam, mask \
	  IDST_MOVE_OBJECTS_BELOW_AND_RIGHT_OF_INSERT_POINT_OR_DELETED_SPACE or\
		mask IDST_MOVE_OBJECTS_INTERSECTING_DELETED_SPACE or \
		mask IDST_MOVE_OBJECTS_INSIDE_DELETED_SPACE_BY_AMOUNT_DELETED

	push	bx, cx, bp, ds
	mov	ds, mapBlock
	movdw	dxax, position
	movdw	invalRect.RD_bottom, dxax
	adddw	dxax, cxbx
	movdw	invalRect.RD_top, dxax
	clr	dx
	clrdw	invalRect.RD_left, dx
	mov	ax, ds:MBH_pageSize.XYS_width
	movdw	invalRect.RD_right, dxax

	lea	bp, invalRect
	call	AddRectToInval
	pop	bx, cx, bp, ds

doIt:
	movdw	dxax, position
	push	di
	mov	di, insDelParam
	call	InsertOrDeleteSpace
	pop	di

	; increment/decrement number of pages

	mov	cx, 1				;cx = 1 for insert
	tst	deleteFlag
	jz	noDelete3
	neg	cx				;cx = -1 for delete
noDelete3:
	add	es:[di].SAE_numPages, cx
	add	es:MBH_totalPages, cx
	call	VMDirtyES
afterSpace:

	tst	deleteFlag
	jnz	noCreate

	; suspend all articles

	call	SuspendDocument

	; calculate correct master page to use

	mov	ax, pageNum
	clr	dx
	div	es:[di].SAE_numMasterPages	;dx = remainder
	mov	bx, dx
	shl	bx				;make bx offset into MP array

	push	si, ds

	; get master page block and lock it

	mov	ax, es:[di][bx].SAE_masterPages
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjLockObjBlock
	mov	ds, ax
	mov	si, offset FlowRegionArray

	; *ds:si = flow region array

	push	bx
	mov	bx, cs
	mov	di, offset CreateArticleRegionCallback
	call	ChunkArrayEnum
	pop	bx
	call	MemUnlock

	pop	si, ds

	; unsuspend all articles (causes redraw)

	call	UnsuspendDocument

noCreate:
	; recalc hotspots

;;	mov	cl, deleteFlag
;;	call	StudioDocumentRecalcHotspots


	; send updates (since a page has been added)

	mov	ax, mask NF_PAGE or mask NF_TOTAL_PAGES
	call	SendNotification
	clc

done::

	call	UnsuspendFlowRegionNotifications

	call	AcceptUndo

	.leave
	ret

AddDeletePageToSection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentRecalcHotspots
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the StudioArticle to recalculate all hotspots on
		a range of pages affected by the add/delete.

CALLED BY:	AddDeletePageToSection
PASS:		*ds:si - document
		cl - non-zero if deleting pages (in which case recalcs from
			SDI_currentPage, else recalcs from SDI_currentPage+1)
RETURN:		nothing
DESTROYED:	ax, cx, es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	7/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentRecalcHotspots		method dynamic StudioDocumentClass,
					MSG_STUDIO_DOCUMENT_RECALC_HOTSPOTS
		uses	dx
		.enter 

	; get the total number of pages
		
		mov	bl, cl
		call	LockMapBlockES
		mov	ax, es:[MBH_totalPages]
		dec	ax				;ax = last page #
		call	VMUnlockES

	; Get the current page.  The current page is automtically updated
	; when the text recalcs.  And the HotSpot Library takes care of
	; repositioning hotspots when they become visible because the user
	; has moved to a new page.
	;
	; The real problem is that when adding a page, if all hotspots from
	; that page to the end are not repositioned, when we move to a page
	; which is followed by a page with a hotspot, because that following
	; page has not been redrawn, its hotspot is not repositioned, and is
	; drawn over the page preceding its new location.  So we must
	; reposition from the new page to the end.
	;
	; For a page delete, we need only recalc the current page.
	; (this doesn't work yet, because of MSG_VIS_DRAW in HSText, so
	; recalc from deleted page to end.)
		
EC <		call	AssertIsStudioDocument				>
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	cx, ds:[di].SDI_currentPage	;cx = page to recalc
		tst	bl
		jnz	delete				;deleting this page?
		inc	cx				;no, recalc from next pg
delete:
		cmp	cx, ax				;past last page?
		jbe	notPastEnd			;no, it's okay
		mov	cx, ax				;only go to last page
notPastEnd:
		mov	dx, ax

		mov	ax, MSG_STUDIO_ARTICLE_RECALC_HOTSPOTS
		mov	di, mask MF_RECORD
		call	EncapsulateToTargetVisText
		
		.leave
		ret
StudioDocumentRecalcHotspots		endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	CreateArticleRegionCallback

DESCRIPTION:	Create an article region (as page of creating a page)

CALLED BY:	INTERNAL

PASS:
	*ds:si - flow region array
	ds:di - FlowRegionArrayElement (in master page block)
	ss:bp - inherited variables
	es - map block (locked)

RETURN:
	carry - set to finish (always returned clear)

DESTROYED:
	ax, bx, cx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
CreateArticleRegionCallback	proc	far	uses es
	.enter inherit AddDeletePageToSection

	push	ds:[LMBH_handle]

	; find the article block and lock it into es

	push	di, ds
	mov	ax, ds:[di].FRAE_article
	segmov	ds, es
	mov	si, offset ArticleArray
	call	ChunkArrayElementToPtr
	mov	ax, ds:[di].AAE_articleBlock
	movdw	dssi, docobj
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	call	ObjLockObjBlock
	mov	es, ax				;es = article block
	pop	di, ds
	push	bx				;save handle to unlock

	movdw	dxax, position
	add	ax, ds:[di].FRAE_position.XYO_y
	adc	dx, 0				;dx.ax = y position for region
	mov	bx, ds:[di].FRAE_position.XYO_x
	pushdw	ds:[di].FRAE_textRegion
	pushdw	ds:[di].FRAE_size

	segxchg	ds, es				;ds = article, es = master page
	mov	si, offset ArticleRegionArray

	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	mov	numRegions, cx

	cmp	insertPos, CA_NULL_ELEMENT
	jz	searchArray

	; this is a subsequent region of the same page

	push	ax
	mov	ax, insertPos
	sub	cx, ax				;cx = regions left
	dec	cx
	inc	insertPos
	call	ChunkArrayElementToPtr
	add	di, size ArticleRegionArrayElement
	pop	ax
	jmp	regionCommon

	; search the region array to find the place to insert the region
	; easier to traverse ourselves than to use ChunkArrayEnum (faster too)

searchArray:
	add	di, ds:[di].CAH_offset
	jcxz	gotRegion
searchLoop:
	cmpdw	dxax, ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_y
	jb	gotRegion
	ja	next
	cmp	bx, ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_x.low
	jbe	gotRegion
next:
	add	di, size ArticleRegionArrayElement
	loop	searchLoop

gotRegion:
	push	ax
	call	ChunkArrayPtrToElement
	mov	insertPos, ax
	pop	ax

	; We have found the position to insert (before ds:di)

	; Rules for setting flags the the new region:
	; 1) If this is the first and only region in the section, set IS_LAST
	; 2) If inserting after the final region in the section, set EMPTY
	; 3) If inserting before an EMPTY region, set EMPTY
	; Otherwise set no flags
	;
	; Luckily the IS_LAST bit isn't used any more :-)

regionCommon:
	push	ax
	mov	ax, section			;ax = section we're inserting in
	cmp	cx, numRegions
	jz	isFirstRegionOfSection
	cmp	ax, ds:[di-(size ArticleRegionArrayElement)].VLTRAE_section
	jz	notFirstRegionOfSection

	; This is the first region, is it the only one ?

isFirstRegionOfSection:
	jcxz	firstAndOnly
	cmp	ax, ds:[di].VLTRAE_section
	jz	firstButNotOnly
firstAndOnly:
;;;	mov	cx, mask VLTRF_IS_LAST
	clr	cx
	jmp	gotFlags

firstButNotOnly:
	clr	cx
	jmp	gotFlags

	; Check for case 2 and 3

notFirstRegionOfSection:
	jcxz	finalRegionInSection
	cmp	ax, ds:[di].VLTRAE_section
	jz	notFinalRegionInSection
finalRegionInSection:
	mov	cx, mask VLTRF_EMPTY
	jmp	gotFlags

notFinalRegionInSection:
	mov	cx, mask VLTRF_EMPTY
	test	cx, ds:[di].VLTRAE_flags
	jnz	gotFlags
	clr	cx
gotFlags:
	pop	ax

	call	ChunkArrayInsertAt

	call	ClearArticleTextCachedRegion

	; Now that we've created a new element for this region, store it's
	; information.
	; We make the text object's region one pixel smaller than the grobj
	; object so that things will draw correctly

	movdw	ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_y, dxax
	mov	ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_x.low, bx
	mov	ds:[di].ARAE_meta.VLTRAE_flags, cx
	popdw	cxdx
	movdw	ds:[di].ARAE_meta.VLTRAE_size, cxdx
	mov	cx, section
	mov	ds:[di].ARAE_meta.VLTRAE_section, cx

	; if we had deleted any chars/lines/space from this section before
	; we need to reclaim them now

	push	es
	mov	es, mapBlock
	call	VMDirtyES
	mov_tr	ax, cx
	push	di
	call	SectionArrayEToP_ES			;es:di = section
	mov	bx, di					;es:bx = section
	pop	di
	clrdw	dxax
	xchgdw	dxax, es:[bx].SAE_charsDeleted
	movdw	ds:[di].VLTRAE_charCount, dxax
	clrdw	dxax
	xchgdw	dxax, es:[bx].SAE_linesDeleted
	movdw	ds:[di].VLTRAE_lineCount, dxax
	clrdw	dxax
	xchgwbf	dxal, es:[bx].SAE_spaceDeleted
	movwbf	ds:[di].VLTRAE_calcHeight, dxal
	pop	es

	; copy region (if any)

	popdw	axdx				;axdx = region
	tstdw	axdx
	jz	noRegionToCopy

	push	di, bp				;save ptr to article reg
	mov	di, dx				;axdi = source item
	mov	cx, DB_UNGROUPED		;cx = dest group
	mov	bx, vmFile			;source file
	mov	bp, bx				;dest file
	call	DBCopyDBItem			;axdi = item in dest
	mov	dx, di				;axdx = item in dest

	pop	di, bp				;restore ptr to article reg
	movdw	ds:[di].ARAE_inheritedTextRegion, axdx
noRegionToCopy:

	; create a GrObj flow object for the region

	push	di, ds				;save ptr to article reg

	pushdw	ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_y ;y pos
	mov	es, mapBlock
	mov	ax, es:MBH_grobjBlock
	mov	bx, vmFile
	call	VMVMBlockToMemBlock
	pop	bx
	push	ax

	mov	ax, ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_x.low
	mov	cx, ds:[di].ARAE_meta.VLTRAE_size.XYS_width
	mov	dx, ds:[di].ARAE_meta.VLTRAE_size.XYS_height

	mov	di, offset MainBody
	push	di				;push body optr
	call	StudioGetDGroupDS
	push	ds
	mov	di, offset FlowRegionClass
	push	di				;push class pointer
	mov	di, GRAPHIC_STYLE_FLOW_REGION
	push	di
	mov	di, CA_NULL_ELEMENT
	push	di				;textStyle
	mov	di, DOCUMENT_FLOW_REGION_LOCKS
	push	di
	call	CreateGrObj			;cx:dx = new object
	pop	di, ds				;restore ptr to article reg

	; tell the flow region what article block it is associated with

	mov	bx, ds:[LMBH_handle]
	call	VMMemBlockToVMBlock		;ax = article VM block
	mov_tr	bx, ax				;bx = article VM block
	clr	ax				;ax = master page VM block
	call	SetFlowRegionAssociation

	call	MemBlockToVMBlockCX
	movdw	ds:[di].ARAE_object, cxdx

	; calculate the correct text flow region for the flow region, but
	; first see if we can optimize by noticing that there are no wrap
	; objects

	mov	es, mapBlock
	mov	ax, es:MBH_grobjBlock
	mov	bx, vmFile				;bx = file
	call	VMVMBlockToMemBlock
	push	bx
	mov_tr	bx, ax
	mov	si, offset MainBody			;bxsi = grobj body
	mov	ax, MSG_STUDIO_GROBJ_BODY_GET_FLAGS
	push	di, bp
	mov	di, mask MF_CALL
	call	ObjMessage			;ax = StudioGrObjBodyFlags
	pop	di, bp
	test	ax, mask SGOBF_WRAP_AREA_NON_NULL
	pop	ax					;ax = file
	jnz	recalcFlow
	tstdw	ds:[di].ARAE_inheritedTextRegion
	jz	afterFlow
recalcFlow:
	call	RecalcOneFlowRegion
afterFlow:

	mov	si, offset ArticleRegionArray
	call	ChunkArrayPtrToElement		;ax = region number

	; unlock article block

	pop	bx
	call	MemUnlock

	;
	; Recalculate text.
	;
	; If this region was added because the text object asked for it, then
	; we don't need to recalculate (since the text object is in the process
	; of doing just that).
	;
	; If this region was added at the users request, then we have one of
	; two situations:
	;	- This is a new article (we need to create lines/recalculate)
	;	- This is not a new article (we just need to recalculate)
	;

	push	ax					;save region number
	mov	si, offset ArticleText
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	DP_ObjMessageNoFlags

	pop	cx					;cx = region number
	mov	si, offset ArticleText
	mov	ax, MSG_VIS_LARGE_TEXT_REGION_CHANGED
	call	DP_ObjMessageNoFlags

	pop	bx
	call	MemDerefDS

	clc
	.leave
	ret

CreateArticleRegionCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ClearArticleTextCachedRegion

DESCRIPTION:	Clear the cached region for an ArticleText

CALLED BY:	INTERNAL

PASS:
	ds - article block

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
	Tony	6/ 3/92		Initial version

------------------------------------------------------------------------------@
ClearArticleTextCachedRegion	proc	far
	class	StudioArticleClass

	; clear out the gstate region that we're translated for

	push	si
	mov	si, offset ArticleText
	mov	si, ds:[si]
	add	si, ds:[si].Vis_offset
	cmp	ds:[si].VTI_gstateRegion, -1
	pop	si
	ret

ClearArticleTextCachedRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DoesSpaceContainGraphics

DESCRIPTION:	See if a given area contains graphics

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - locked map block
	dx.ax - position to add space
	cx.bx - (signed) amount of space to add

RETURN:
	carry - set if any graphics in space

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/ 1/92		Initial version

------------------------------------------------------------------------------@
DoesSpaceContainGraphics	proc	near	uses ax, bx, cx, dx, si, di, bp
	.enter

EC <	call	AssertIsStudioDocument					>

	sub	sp, size StudioGrObjBodyGraphicsInSpaceParams
	mov	bp, sp
	movdw	ss:[bp].SGBGISP_position, dxax
	negdw	cxbx
	movdw	ss:[bp].SGBGISP_size, cxbx

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	mov	ax, MSG_STUDIO_GROBJ_BODY_GRAPHICS_IN_SPACE
	mov	si, offset MainBody
	mov	di, mask MF_CALL
	call	ObjMessage

	lahf
	add	sp, size StudioGrObjBodyGraphicsInSpaceParams
	sahf

	.leave
	ret

DoesSpaceContainGraphics	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetFlowRegionAssociation

DESCRIPTION:	Set the data the associates a flow region with something

CALLED BY:	INTERNAL

PASS:
	cxdx - flow region
	ax - master page VM block
	bx - article block

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
	Tony	9/12/92		Initial version

------------------------------------------------------------------------------@
SetFlowRegionAssociation	proc	far	uses	ax, bx, cx, dx, si
	.enter

	push	bx
	movdw	bxsi, cxdx			;bxsi = flow region
	mov_tr	cx, ax				;cx = master page
	pop	dx				;dx = article block
	mov	ax, MSG_FLOW_REGION_SET_ASSOCIATION
	call	DP_ObjMessageFixupDS

	.leave
	ret

SetFlowRegionAssociation	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	InsertOrDeleteSpace

DESCRIPTION:	Insert vertical space in the document

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	es - locked map block
	dx.ax - position to add space
	cx.bx - (signed) amount of space to add
	di - InsertDeleteDeleteTypes

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
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
InsertOrDeleteSpace	proc	near	uses ax, bx, cx, dx, si, di, bp
insDelParams	local	InsertDeleteSpaceParams
mapBlockSeg	local	sptr
fileHandle	local	word
	ForceRef mapBlockSeg
	.enter

EC <	call	AssertIsStudioDocument					>

	; fill in the Parameter structure

	mov	insDelParams.IDSP_type, di

	movdw	insDelParams.IDSP_position.PDF_y.DWF_int, dxax
	movdw	insDelParams.IDSP_space.PDF_y.DWF_int, cxbx
	clr	ax
	mov	insDelParams.IDSP_position.PDF_y.DWF_frac, ax
	mov	insDelParams.IDSP_space.PDF_y.DWF_frac, ax

	clrdw	insDelParams.IDSP_position.PDF_x.DWF_int
	clrdw	insDelParams.IDSP_space.PDF_x.DWF_int
	mov	insDelParams.IDSP_position.PDF_x.DWF_frac, ax
	mov	insDelParams.IDSP_space.PDF_x.DWF_frac, ax

	; for each article:
	; - for each text region:
	;   - move region down if needed

	call	GetFileHandle
	mov	fileHandle, bx

	push	ds:[LMBH_handle], si, es
	segmov	ds, es
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset InsDelSpaceInArticleCallback
	call	ChunkArrayEnum
	pop	bx, si, es
	call	MemDerefDS

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax
	mov	si, offset MainBody
	mov	ax, MSG_VIS_LAYER_INSERT_OR_DELETE_SPACE
	push	bp
	lea	bp, insDelParams
	call	DP_ObjMessageNoFlags
	pop	bp

	.leave

	call	SendDocumentSizeToView
	ret

InsertOrDeleteSpace	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	InsDelSpaceInArticleCallback

DESCRIPTION:	Insert or delete space in an article

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	ss:bp - inherited variables

RETURN:
	carry - set to end (always returned clear)

DESTROYED:
	ax, bx, dx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
InsDelSpaceInArticleCallback	proc	far	uses cx, ds
	.enter inherit InsertOrDeleteSpace

	mov	mapBlockSeg, ds

	; lock the article block

	mov	bx, fileHandle
	mov	ax, ds:[di].AAE_articleBlock
	call	VMVMBlockToMemBlock
	mov_tr	bx, ax
	push	bx
	call	ObjLockObjBlock
	mov	ds, ax				;ds = article block

	movdw	dxax, insDelParams.IDSP_position.PDF_y.DWF_int
	mov	si, offset ArticleRegionArray
	mov	di, ds:[si]
	mov	cx, ds:[di].CAH_count
	jcxz	done
	add	di, ds:[di].CAH_offset

	; zip through the article block looking for regions that need to
	; be moved

	; dxax = position to insert/delete space at

sizeLoop:
	jgdw	dxax, ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_y, next

	; move this object -- move the text region (grobj will move the
	; grobj object)

	adddw	ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_y, \
				insDelParams.IDSP_space.PDF_y.DWF_int, bx

	; see if this object needs to be deleted

	jldw	dxax, ds:[di].ARAE_meta.VLTRAE_spatialPosition.PD_y, next
deleteObj::
	mov	es, mapBlockSeg
	call	DeleteArticleRegion
	sub	di, size ArticleRegionArrayElement
next:
	add	di, size ArticleRegionArrayElement
	loop	sizeLoop
done:
	pop	bx
	call	MemUnlock

	clc
	.leave
	ret

InsDelSpaceInArticleCallback	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DeleteArticleRegion

DESCRIPTION:	Update the region array (and possibly the section array)
		for a deleted region

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleRegionArrayElement
	es - map block

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
	Tony	6/ 4/92		Initial version

------------------------------------------------------------------------------@
DeleteArticleRegion	proc	far	uses ax, bx, cx, dx, si, bp
	.enter

	call	ChunkArrayPtrToElement			;ax = region number
	mov_tr	cx, ax					;cx = region number

	push	si
	movdw	bxsi, ds:[di].ARAE_object
	call	VMBlockToMemBlockRefDS
	mov	ax, MSG_GO_CLEAR
	call	DP_ObjMessageNoFlags

	push	cx
	mov	si, offset ArticleText
	mov	ax, MSG_VIS_LARGE_TEXT_REGION_CHANGED
	call	ObjCallInstanceNoLock
	pop	ax
	pop	si

	; clear out the gstate region that we're translated for

	call	ClearArticleTextCachedRegion

	call	ChunkArrayElementToPtr		;ds:di = region

	; we need to update the region array to account for the space lost
	; if we are not at the first region in the section then add everything
	; to the previous region.  If we are at the first region then add
	; everything to the next region *unless* we are at the only region for
	; the section in which case we store the nuked values in the
	; section array

	mov	ax, ds:[di].VLTRAE_section
	mov	bx, di				;ds:bx = dest region
	mov	si, ds:[ArticleRegionArray]
	ChunkSizePtr	ds, si, cx
	add	cx, si				;cx = offset past chunk
	add	si, ds:[si].CAH_offset

	;
	; ds:si	= First region in the region array
	; ds:di	= Region to nuke
	; ax	= Section for (ds:di)
	; ds:cx	= Pointer past end of region array
	;
	cmp	si, di				;first region ?
	jz	firstRegion
	
	;
	; We aren't deleting the very first region. If the preceding region
	; is in the same section, then we ripple information from the current
	; region backwards into that previous one.
	;
	lea	bx, ds:[di-(size ArticleRegionArrayElement)]
	cmp	ax, ds:[bx].VLTRAE_section
	jz	gotRegionToModify
	
	;
	; The previous region is not in the same section as (ds:di). We need
	; to ripple the information forward to the next region (if possible).
	;

firstRegion:
	;
	; ds:di	= Region to delete, it is the first region in its section
	; ds:cx	= Pointer past the end of the region array
	;
	; We want to ripple information forward to the next region in the
	; array, unless the current region is the last one in the section
	; in which case we are suddenly helpless :-)
	;
	sub	cx, size ArticleRegionArrayElement
	cmp	di, cx				; Check for last in array
	je	lastInSection			; Branch if it is
	
	lea	bx, ds:[di+(size ArticleRegionArrayElement)]
	
	cmp	ax, ds:[bx].VLTRAE_section	; Check next not in same section
	jne	lastInSection			; Branch if it isn't

	;
	; The next region exists and is in the same section. Check to see if
	; it's empty.
	;
	test	ds:[bx].VLTRAE_flags, mask VLTRF_EMPTY
	jz	gotRegionToModify		; Branch if not empty

lastInSection:
	;
	; This is the last region in this section. Accumulate the amounts
	; into a safe place.
	;
	push	di
	call	SectionArrayEToP_ES		;es:di = section
	mov	bx, di				;es:bx = section
	pop	di
	adddw	es:[bx].SAE_charsDeleted, ds:[di].VLTRAE_charCount, ax
	adddw	es:[bx].SAE_linesDeleted, ds:[di].VLTRAE_lineCount, ax
	addwbf	es:[bx].SAE_spaceDeleted, ds:[di].VLTRAE_calcHeight, ax
	call	VMDirtyES
	jmp	afterAdjustment

gotRegionToModify:
	adddw	ds:[bx].VLTRAE_charCount, ds:[di].VLTRAE_charCount, ax
	adddw	ds:[bx].VLTRAE_lineCount, ds:[di].VLTRAE_lineCount, ax
	addwbf	ds:[bx].VLTRAE_calcHeight, ds:[di].VLTRAE_calcHeight, ax

afterAdjustment:
	mov	si, offset ArticleRegionArray
	call	ChunkArrayDelete

	.leave
	ret

DeleteArticleRegion	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SuspendFlowRegionNotifications

DESCRIPTION:	Suspend flow region notifications

CALLED BY:	INTERNAL

PASS:
	none

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
	Tony	9/13/92		Initial version

------------------------------------------------------------------------------@
SuspendFlowRegionNotifications	proc	far
	pushf
	push	ds
	call	StudioGetDGroupDS
	inc	ds:[suspendNotification]
	pop	ds
	popf
	ret
SuspendFlowRegionNotifications	endp

UnsuspendFlowRegionNotifications	proc	far
	pushf
	push	ds
	call	StudioGetDGroupDS
	dec	ds:[suspendNotification]
	pop	ds
	popf
	ret
UnsuspendFlowRegionNotifications	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentGetGraphicTokensForStyle --
		MSG_STUDIO_DOCUMENT_GET_GRAPHIC_TOKENS_FOR_STYLE
							for StudioDocumentClass

DESCRIPTION:	Get the graphic attribute tokens for a style

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - style token

RETURN:
	cx - line attr token
	dx - area attr token

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/13/92	Initial version

------------------------------------------------------------------------------@
StudioDocumentGetGraphicTokensForStyle	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_GET_GRAPHIC_TOKENS_FOR_STYLE

	call	GetFileHandle				;bx = file

	call	LockMapBlockDS
	mov	ax, ds:[MBH_graphicStyles]
	call	VMUnlockDS

	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK		;*ds:si = styles
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr
	mov	cx, ds:[di].GSE_lineAttrToken
	mov	dx, ds:[di].GSE_areaAttrToken
	call	VMUnlock

	ret

StudioDocumentGetGraphicTokensForStyle	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentGetTextTokensForStyle --
		MSG_STUDIO_DOCUMENT_GET_TEXT_TOKENS_FOR_STYLE
							for StudioDocumentClass

DESCRIPTION:	Get the text attribute tokens for a style

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - The message

	cx - style token

RETURN:
	cx - char attr token
	dx - para attr token

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/13/92	Initial version

------------------------------------------------------------------------------@
StudioDocumentGetTextTokensForStyle	method dynamic	StudioDocumentClass,
				MSG_STUDIO_DOCUMENT_GET_TEXT_TOKENS_FOR_STYLE

	call	GetFileHandle				;bx = file

	call	LockMapBlockDS
	mov	ax, ds:[MBH_textStyles]
	call	VMUnlockDS

	call	VMLock
	mov	ds, ax
	mov	si, VM_ELEMENT_ARRAY_CHUNK		;*ds:si = styles
	mov_tr	ax, cx
	call	ChunkArrayElementToPtr
	mov	cx, ds:[di].TSEH_charAttrToken
	mov	dx, ds:[di].TSEH_paraAttrToken
	call	VMUnlock

	ret

StudioDocumentGetTextTokensForStyle	endm

DocPageCreDest ends
