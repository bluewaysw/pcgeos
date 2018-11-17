COMMENT @----------------------------------------------------------------------

	Copyright (c) Geoworks 1992-1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Studio
FILE:		documentOpenClose.asm

ROUTINES:
	Name				Description
	----				-----------
    INT DOC_ObjMessageNoFlags	This file contains the document open/close
				related code for StudioDocumentClass

    INT DOC_ObjMessageFixupDS	This file contains the document open/close
				related code for StudioDocumentClass

    INT SetViewForDisplayMode	Set the view correctly depending on the
				display mode

    INT AttachDetachArticleCallback 
				Attach an article to the document/content

    INT DestroyMasterPages	Destroy the UI for any open master pages

    INT DestroyMPUICallback	Destroy the UI for a master page

    INT StudioDocumentSetRevisionStamp 
				Set the revision stamp for the document

METHODS:
	Name			Description
	----			-----------
    StudioDocumentAttachUIToDocument  
				Document has been opened, add things in
				visually

				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
				StudioDocumentClass

    StudioDocumentDetachUIFromDocument  
				Document is about to be closed

				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
				StudioDocumentClass

    StudioDocumentReloc		Do special relocation for a document

				MSG_META_RELOCATE
				StudioDocumentClass

    StudioDocumentDestroyUIForDocument  
				Destroy the UI for the document

				MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
				StudioDocumentClass

    StudioDocumentStudioCachedDataToFile  
				Sets the revision time for the document to
				now

				MSG_GEN_DOCUMENT_STUDIO_CACHED_DATA_TO_FILE
				StudioDocumentClass

    StudioDocumentSaveAs		Force the document to be dirty so our
				last-revision timestamp gets updated.

				MSG_GEN_DOCUMENT_SAVE_AS,
		    		MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
				StudioDocumentClass

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version

DESCRIPTION:
	This file contains the document open/close related code for
	StudioDocumentClass

	$Id: documentOpenClose.asm,v 1.1 97/04/04 14:38:59 newdeal Exp $

------------------------------------------------------------------------------@

DocOpenClose segment resource

DOC_ObjMessageNoFlags	proc	near
	push	di
	clr	di
	call	ObjMessage
	pop	di
	ret
DOC_ObjMessageNoFlags	endp

DOC_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	di
	ret
DOC_ObjMessageFixupDS	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentAttachUIToDocument --
		MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT for StudioDocumentClass

DESCRIPTION:	Document has been opened, add things in visually

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
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentAttachUIToDocument	method dynamic	StudioDocumentClass,
					MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

	;    Have superclass do its thang

	mov	di, offset StudioDocumentClass
	call	ObjCallSuperNoLock

	; Send the document size to the view (the size is really only sent
	; if we are in page mode, we take care of other modes below)

	call	LockMapBlockES
	call	SendDocumentSizeToView

	; set the page size in the view

	call	SendPageSizeToView

	; change the view attributes based on the display mode

	mov	dx, VLTDM_PAGE			;the view is initially set
						;for PAGE mode
	call	SetViewForDisplayMode

	;    Attach the ruler contents to the ruler views

	push	si					;document chunk
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	mov	cx, ds:[LMBH_handle]
	mov	dx, offset MainHorizontalContent
	mov	si, offset MainHorizontalRulerView
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call	DOC_ObjMessageFixupDS

	mov	dx, offset MainVerticalContent
	mov	si, offset MainVerticalRulerView
	call	DOC_ObjMessageFixupDS
	pop	si					;document chunk

	;    Attach the rulers to the contents

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	cx, ax					;cx = grobj body block

	push	si
	mov	bx, ds:[LMBH_handle]
	mov	bp, CCO_FIRST
	mov	ax, MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD
	mov	si, offset MainVerticalContent
	mov	dx, offset MainVerticalRuler
	call	DOC_ObjMessageFixupDS

	mov	si, offset MainHorizontalContent 
	mov	dx, offset MainHorizontalRuler
	call	DOC_ObjMessageFixupDS
	pop	si

	; for each article
	; - add the text object for the article to the document/content

	push	ds:[LMBH_handle], cx, si
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;cx:dx = document

	segmov	ds, es
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset AttachDetachArticleCallback
	mov	bp, MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD
	call	ChunkArrayEnum
	pop	bx, cx, si
	call	MemDerefDS

	;    Add the graphic body as the last child of the
	;    Document/Content.

	mov	ax, MSG_VIS_ADD_NON_DISCARDABLE_VM_CHILD
	mov	dx, offset MainBody			;cxdx = body
	mov	bp, CCO_LAST
	call	ObjCallInstanceNoLock

	; tell the ruler which content to talk to GCN list

	push	cx				;save main body block
	push	si
	xchgdw	bxsi, cxdx			;bxsi = body, cxdx = content
	mov	si, offset MainHorizontalRuler
	mov	ax, MSG_TEXT_RULER_SET_GCN_CONTENT
	call	DOC_ObjMessageFixupDS
	pop	si
	pop	bx				;bx = body block

	;    Notify the GrObjBody that it has been added to
	;    the Document/Content. And pass GrObjHead to it.

	push	si
	mov	si, offset MainBody
	GetResourceHandleNS	StudioHead, cx
	mov	dx, offset StudioHead
	mov	ax,MSG_GB_ATTACH_UI
	call	DOC_ObjMessageFixupDS
	pop	si

	; if the operation is REVERT_QUICK then we don't want to open any
	; master pages ( because they might be old) -- we should do something
	; better here for the case of editing a detach file, but this will
	; have to do for now

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	ds:[di].GDI_operation, GDO_REVERT
	jz	nukeMasterPages
	cmp	ds:[di].GDI_operation, GDO_REVERT_QUICK
	jnz	notRevertQuick
nukeMasterPages:
	call	DestroyMasterPages
notRevertQuick:

	; attach all master pages

	mov	di, ds:[OpenMasterPageArray]
	mov	cx, ds:[di].CAH_count
	jcxz	noMasterPages
	add	di, ds:[di].CAH_offset
detachMPLoop:
	push	cx
	mov	ax, ds:[di].OMP_vmBlock
	mov	bx, ds:[di].OMP_display
	mov	cx, ds:[di].OMP_content
	call	AttachUIForMasterPage
	add	di, size OpenMasterPage
	pop	cx
	loop	detachMPLoop
noMasterPages:

	; set the target to be the first article
	; and then set the target based on the current tool

	push	si
	clr	cx
	clr	dx
	mov	ax, MSG_VIS_FIND_CHILD_AT_POSITION
	call	ObjCallInstanceNoLock		;cx:dx = child
	movdw	bxsi, cxdx
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	DOC_ObjMessageFixupDS
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	DOC_ObjMessageFixupDS
	pop	si

	mov	ax, MSG_STUDIO_DOCUMENT_SET_TARGET_BASED_ON_TOOL
	call	ObjCallInstanceNoLock

	; if we are in a mode other than page we have to force the text
	; object to send its size to the view -- we must do this on the queue

	cmp	es:MBH_displayMode, VLTDM_PAGE
	jz	pageMode

	mov	ax, MSG_VIS_TEXT_HEIGHT_NOTIFY
	call	dispatchDelayed

	mov	dx, VIS_TEXT_RANGE_SELECTION
	mov	ax, MSG_VIS_TEXT_SHOW_POSITION
	call	dispatchDelayed

pageMode:
	; Force HotSpotText to reposition the hotspots, so that a change
	; in Show Invisibles state between the current session and the
	; session in which document was saved will be visibly accounted for.

	mov	ax, MSG_HSTEXT_REPOSITION_HOT_SPOTS
	call	dispatchDelayed

	; if we already have the MODEL exclusive then we need to send
	; notification

	mov	ax, mask NotifyFlags
	call	SendNotification

	call	VMUnlockES

	ret

;---

dispatchDelayed:
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_STUDIO_DOCUMENT_SEND_TO_FIRST_ARTICLE
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	dx, mask MF_FORCE_QUEUE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	retn

StudioDocumentAttachUIToDocument	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	SetViewForDisplayMode

DESCRIPTION:	Set the view correctly depending on the display mode

CALLED BY:	INTERNAL

PASS:
	*ds:si - document
	es - map block
	dx - mode that the view is currently set for

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
	Tony	9/ 2/92		Initial version

------------------------------------------------------------------------------@
SetViewForDisplayMode	proc	far	uses ax, bx, cx, dx, si, di, bp
	class	StudioDocumentClass
	.enter

	cmp	dx, es:MBH_displayMode
	jz	done

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	mov	si, offset MainView

	; assume DRAFT mode:
	;	clear "no larger than content"
	;	clear "scrollable"

	clr	dx				;no vertical attribute changes
	mov	cx, (mask GVDA_NO_LARGER_THAN_CONTENT or \
						mask GVDA_SCROLLABLE) shl 8
	cmp	es:MBH_displayMode, VLTDM_DRAFT_WITH_STYLES
	jae	gotFlags
	xchg	cl, ch
gotFlags:
	mov	bp, VUM_NOW
	mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	call	DOC_ObjMessageFixupDS

	; if we are going into DRAFT_WITHOUT_STYLES then we need to change the
	; view to normal size

	cmp	es:MBH_displayMode, VLTDM_DRAFT_WITHOUT_STYLES
	jnz	done

	GetResourceHandleNS	StudioViewControl, bx
	mov	si, offset StudioViewControl
	mov	ax, MSG_GVC_SET_SCALE
	mov	dx, 100
	call	DOC_ObjMessageFixupDS
	mov	ax, MSG_GEN_VIEW_CONTROL_SET_ATTRS
	clr	cx
	mov	dx, mask GVCA_ADJUST_ASPECT_RATIO
	call	DOC_ObjMessageFixupDS

done:
	.leave
	ret

SetViewForDisplayMode	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentDetachUIFromDocument --
		MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT for StudioDocumentClass

DESCRIPTION:	Document is about to be closed

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
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentDetachUIFromDocument	method dynamic	StudioDocumentClass,
					MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	push	es

	call	LockMapBlockES

	; for each article
	; - add the text object for the article to the document/content

	push	ds:[LMBH_handle], si
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				;cx:dx = document
	segmov	ds, es
	mov	si, offset ArticleArray
	mov	bx, cs
	mov	di, offset AttachDetachArticleCallback
	mov	bp, MSG_VIS_REMOVE_NON_DISCARDABLE
	call	ChunkArrayEnum
	pop	bx, si
	call	MemDerefDS

	;    Notify the GrObjBody that it is about to be removed from
	;    the Document/Content
	;

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax

	push	si
	mov	si, offset MainBody
	mov	ax,MSG_GB_DETACH_UI
	call	DOC_ObjMessageFixupDS
	pop	si

	;    Detach the rulers from the contents

	mov	ax, es:MBH_grobjBlock
	call	StudioVMBlockToMemBlock
	mov_tr	bx, ax

	push	si
	mov	si, offset MainVerticalRuler
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_REMOVE_NON_DISCARDABLE
	call	DOC_ObjMessageFixupDS

	mov	si, offset MainHorizontalRuler
	call	DOC_ObjMessageFixupDS

	mov	si, offset MainBody			;cxdx = body
	call	DOC_ObjMessageFixupDS
	pop	si

	;    Detach the ruler contents from the ruler views

	push	si					;document chunk
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_display
	mov	si, offset MainHorizontalRulerView
	clrdw	cxdx
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call	DOC_ObjMessageFixupDS
	mov	si, offset MainVerticalRulerView
	call	DOC_ObjMessageFixupDS
	pop	si					;document chunk

	; detach all master pages

	mov	di, ds:[OpenMasterPageArray]
	mov	cx, ds:[di].CAH_count
	jcxz	noMasterPages
	add	di, ds:[di].CAH_offset
detachMPLoop:
	push	cx
	mov	ax, ds:[di].OMP_vmBlock
	mov	bx, ds:[di].OMP_display
	mov	cx, ds:[di].OMP_content
	call	DetachUIForMasterPage
	pop	cx
	add	di, size OpenMasterPage
	loop	detachMPLoop
noMasterPages:

	call	VMUnlockES

	pop	es
	mov	ax, MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	mov	di, offset StudioDocumentClass
	call	ObjCallSuperNoLock

	ret

StudioDocumentDetachUIFromDocument	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	AttachDetachArticleCallback

DESCRIPTION:	Attach an article to the document/content

CALLED BY:	INTERNAL

PASS:
	ds:di - ArticleArrayElement
	cx:dx - document
	bp - message

RETURN:
	carry - set to end (always returned clear)

DESTROYED:
	bx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/10/92		Initial version

------------------------------------------------------------------------------@
AttachDetachArticleCallback	proc	far	uses cx, dx, bp
	.enter

	movdw	bxsi, cxdx			;bxsi = document
	mov	ax, MSG_GEN_DOCUMENT_GET_FILE_HANDLE
	push	di
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	di
	push	bx
	mov_tr	bx, ax
	mov	ax, ds:[di].AAE_articleBlock
	call	VMVMBlockToMemBlock
	mov_tr	cx, ax
	pop	bx
	mov	dx, offset ArticleText
	mov_tr	ax, bp
	mov	bp, CCO_LAST
	cmp	ax, MSG_VIS_REMOVE_NON_DISCARDABLE
	jnz	common

	; send remove to the object itsself

	movdw	bxsi, cxdx
	mov	dl, VUM_NOW

common:
	call	DOC_ObjMessageNoFlags

	clc
	.leave
	ret

AttachDetachArticleCallback	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentReloc -- Relocation for StudioDocumentClass

DESCRIPTION:	Do special relocation for a document

PASS:
	*ds:si - instance data
	es - segment of StudioDocumentClass

	ax - MSG_META_RELOCATE or MSG_META_UNRELOCATE

	dx - VMRelocType

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 5/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentReloc	method dynamic	StudioDocumentClass, reloc

	mov	bx, ds:[LMBH_handle]	;bx = block containing relocation

	; we need to relocate the handles in the OpenMasterPageArray

	mov	si, ds:[OpenMasterPageArray]
	mov	cx, ds:[si].CAH_count
	jcxz	done
	add	si, ds:[si].CAH_offset
relocLoop:
	push	cx
	mov	cx, ds:[si].OMP_display
	call	relocOrUnReloc
	mov	ds:[si].OMP_display, cx
	mov	cx, ds:[si].OMP_content
	call	relocOrUnReloc
	mov	ds:[si].OMP_content, cx
	pop	cx
	add	si, size OpenMasterPage
	loop	relocLoop

done:
	mov	di, offset StudioDocumentClass
	call	ObjRelocOrUnRelocSuper
	ret

relocOrUnReloc:
	push	ax
	cmp	ax, MSG_META_RELOCATE
	mov	al, RELOC_HANDLE
	jz	relocate
	call	ObjDoUnRelocation
	jmp	relocDone
relocate:
	call	ObjDoRelocation
relocDone:
	pop	ax
	retn

StudioDocumentReloc	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	StudioDocumentDestroyUIForDocument --
		MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT for StudioDocumentClass

DESCRIPTION:	Destroy the UI for the document

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
	Tony	6/ 3/92		Initial version

------------------------------------------------------------------------------@
StudioDocumentDestroyUIForDocument	method dynamic	StudioDocumentClass,
					MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

	call	DestroyMasterPages

	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock

StudioDocumentDestroyUIForDocument	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DestroyMasterPages

DESCRIPTION:	Destroy the UI for any open master pages

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
	Tony	3/29/93		Initial version

------------------------------------------------------------------------------@
DestroyMasterPages	proc	near	uses si
	.enter

	; detach all master pages

	mov	dx, si
	mov	si, offset OpenMasterPageArray
	mov	bx, cs
	mov	di, offset DestroyMPUICallback
	call	ChunkArrayEnum

	.leave
	ret

DestroyMasterPages	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DestroyMPUICallback

DESCRIPTION:	Destroy the UI for a master page

CALLED BY:	INTERNAL

PASS:
	ds:di - OpenMasterPage
	*ds:dx - document

RETURN:
	carry - clear

DESTROYED:
	ax, bx, cx, si, di

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	6/ 3/92		Initial version

------------------------------------------------------------------------------@
DestroyMPUICallback	proc	far
	mov	ax, ds:[di].OMP_vmBlock
	mov	si, dx
	call	DestroyUIForMasterPage
	mov	dx, si
	clc
	ret

DestroyMPUICallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentStudioCachedDataToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the revision time for the document to now

CALLED BY:	MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
PASS:		*ds:si	= document object
		cx	= non-zero if document being saved, not auto-saved
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentStudioCachedDataToFile method dynamic StudioDocumentClass,
				MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
	.enter
	jcxz	callSuper		; don't update revision stamp on
					;  auto-save
	call	StudioDocumentSetRevisionStamp
callSuper:
	.leave
	mov	di, offset StudioDocumentClass
	GOTO	ObjCallSuperNoLock
StudioDocumentStudioCachedDataToFile endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentSetRevisionStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the revision stamp for the document

CALLED BY:	(INTERNAL) StudioDocumentStudioCachedDataToFile,
			   StudioDocumentSaveAs
PASS:		*ds:si	= StudioDocument object
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	document is marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentSetRevisionStamp proc near
		uses	ax
		.enter
		push	ds:[LMBH_handle]
		call	LockMapBlockDS
		call	GetNowAsTimeStamp
		mov	ds:[MBH_revisionStamp].FDAT_date, ax
		mov	ds:[MBH_revisionStamp].FDAT_time, bx
		call	VMDirtyDS
		call	VMUnlockDS
	;
	; Dirty notification might have been handled (if map block is the
	; first dirty block in the file) which could have caused the document
	; block to move, so fix up DS before return.
	; 
		pop	bx
		call	MemDerefDS
		.leave
		ret
StudioDocumentSetRevisionStamp endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StudioDocumentSaveAs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the document to be dirty so our last-revision
		timestamp gets updated.

CALLED BY:	MSG_GEN_DOCUMENT_SAVE_AS, MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
PASS:		*ds:si	= StudioDocument object
		ds:di	= StudioDocumentInstance
RETURN:		what those messages return
DESTROYED:	what those messages destroy
SIDE EFFECTS:	the document is marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StudioDocumentSaveAs method dynamic StudioDocumentClass, MSG_GEN_DOCUMENT_SAVE_AS,
		    		MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
		uses	ax, cx, dx, bp
		.enter
	;
	; Make sure "cached data" get written (i.e. revision stamp).
	; 
		mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
		call	ObjCallInstanceNoLock
		.leave
		mov	di, offset StudioDocumentClass
		GOTO	ObjCallSuperNoLock
StudioDocumentSaveAs endm

DocOpenClose ends
