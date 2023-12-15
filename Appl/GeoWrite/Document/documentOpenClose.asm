COMMENT @----------------------------------------------------------------------

	Copyright (c) Berkeley Softworks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoWrite
FILE:		documentOpenClose.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/92		Initial version
	RainerB	12/2023		Renamed from Writer to GeoWrite


DESCRIPTION:
	This file contains the document open/close related code for
	WriteDocumentClass

	$Id: documentOpenClose.asm,v 1.1 97/04/04 15:56:04 newdeal Exp $

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

MESSAGE:	WriteDocumentCreateUIForDocument --
		MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT for WriteDocumentClass

DESCRIPTION:	Notification that a file has been opened

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
	Tony	4/12/95		Initial version

------------------------------------------------------------------------------@


COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentAttachUIToDocument --
		MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT for WriteDocumentClass

DESCRIPTION:	Document has been opened, add things in visually

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentAttachUIToDocument	method dynamic	WriteDocumentClass,
					MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

	;    Have superclass do its thang

	mov	di, offset WriteDocumentClass
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
	call	WriteVMBlockToMemBlock
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
	GetResourceHandleNS	WriteHead, cx
	mov	dx, offset WriteHead
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

	; set the target toi be the first article
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

	mov	ax, MSG_WRITE_DOCUMENT_SET_TARGET_BASED_ON_TOOL
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
	mov	ax, MSG_WRITE_DOCUMENT_SEND_TO_FIRST_ARTICLE
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	dx, mask MF_FORCE_QUEUE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	retn

WriteDocumentAttachUIToDocument	endm

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
	class	WriteDocumentClass
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

	GetResourceHandleNS	WriteViewControl, bx
	mov	si, offset WriteViewControl
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

MESSAGE:	WriteDocumentDetachUIFromDocument --
		MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT for WriteDocumentClass

DESCRIPTION:	Document is about to be closed

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentDetachUIFromDocument	method dynamic	WriteDocumentClass,
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
	call	WriteVMBlockToMemBlock
	mov_tr	bx, ax

	push	si
	mov	si, offset MainBody
	mov	ax,MSG_GB_DETACH_UI
	call	DOC_ObjMessageFixupDS
	pop	si

	;    Detach the rulers from the contents

	mov	ax, es:MBH_grobjBlock
	call	WriteVMBlockToMemBlock
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
	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock

	ret

WriteDocumentDetachUIFromDocument	endm

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

MESSAGE:	WriteDocumentReloc -- Relocation for WriteDocumentClass

DESCRIPTION:	Do special relocation for a document

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentReloc	method dynamic	WriteDocumentClass, reloc

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
	mov	di, offset WriteDocumentClass
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

WriteDocumentReloc	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	WriteDocumentDestroyUIForDocument --
		MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT for WriteDocumentClass

DESCRIPTION:	Destroy the UI for the document

PASS:
	*ds:si - instance data
	es - segment of WriteDocumentClass

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
WriteDocumentDestroyUIForDocument	method dynamic	WriteDocumentClass,
					MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

	call	DestroyMasterPages

	mov	ax, MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT
	mov	di, offset WriteDocumentClass
	GOTO	ObjCallSuperNoLock

WriteDocumentDestroyUIForDocument	endm

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
		WriteDocumentWriteCachedDataToFile
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
WriteDocumentWriteCachedDataToFile method dynamic WriteDocumentClass,
				MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
	.enter
	jcxz	callSuper		; don't update revision stamp on
					;  auto-save
	call	WriteDocumentSetRevisionStamp
callSuper:
	.leave
	mov	di, offset WriteDocumentClass
	GOTO	ObjCallSuperNoLock
WriteDocumentWriteCachedDataToFile endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentSetRevisionStamp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the revision stamp for the document

CALLED BY:	(INTERNAL) WriteDocumentWriteCachedDataToFile,
			   WriteDocumentSaveAs
PASS:		*ds:si	= WriteDocument object
RETURN:		nothing
DESTROYED:	bx
SIDE EFFECTS:	document is marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentSetRevisionStamp proc near
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
WriteDocumentSetRevisionStamp endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentSaveAs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the document to be dirty so our last-revision
		timestamp gets updated.

CALLED BY:	MSG_GEN_DOCUMENT_SAVE_AS, MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
PASS:		*ds:si	= WriteDocument object
		ds:di	= WriteDocumentInstance
RETURN:		what those messages return
DESTROYED:	what those messages destroy
SIDE EFFECTS:	the document is marked dirty

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WriteDocumentSaveAs method dynamic WriteDocumentClass,
				MSG_GEN_DOCUMENT_SAVE_AS,
		    		MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE

if	_SUPER_IMPEX
	cmp	ax, MSG_GEN_DOCUMENT_SAVE_AS_TEMPLATE
	je	callSuper

	;
	; See what kind of document they want to save it as.
	;
	call	GetSelectedFileType		; cx = file type
	cmp	cx, WDFT_WRITE
	je	callSuper

	;
	; If not a native file, do the export
	;
	call	ExportDocTransparently
	; clears GDA_CLOSING
	mov	ax, MSG_GEN_DOCUMENT_GROUP_SAVE_AS_CANCELLED
	call	GenCallParent
	jmp	done

callSuper:
endif
	mov	di, offset WriteDocumentClass
	call	ObjCallSuperNoLock
	jc	done

	; no error -- set the revision stamp

	mov	ax, MSG_GEN_DOCUMENT_MARK_DIRTY
	call	ObjCallInstanceNoLock	
	mov	ax, MSG_GEN_DOCUMENT_SAVE
	call	ObjCallInstanceNoLock	
done:
	ret

WriteDocumentSaveAs endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteDocumentPhysicalOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invokes Impex converter for non-Geowrite files.

CALLED BY:	MSG_GEN_DOCUMENT_PHYSICAL_OPEN

PASS:		*ds:si	= WriteDocumentClass object
		ds:di	= WriteDocumentClass instance data
		ds:bx	= WriteDocumentClass object (same as *ds:si)
		es 	= segment of WriteDocumentClass
		ss:bp	= DocumentCommonParams

RETURN:		carry set on error, else clear
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	10/30/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	timer.def

WriteDocumentOpen	method dynamic WriteDocumentClass, 
					MSG_GEN_DOCUMENT_OPEN
if	_SUPER_IMPEX
	;
	; See if it's one of our known DOS file types. If not,
	; just let the superclass do its job.
	;
		call	CheckIfNativeFile
		jc	dosFile
endif
	;
	; OK, complete the opening of the file
	;
		mov	ax, MSG_GEN_DOCUMENT_OPEN
		mov	di, offset WriteDocumentClass
		GOTO	ObjCallSuperNoLock

if	_SUPER_IMPEX
dosFile:
	;
	; do nothing if we're quitting
	;
		push	bp
		mov	ax, MSG_GEN_APPLICATION_GET_STATE
		call	UserCallApplication
		pop	bp
		test	ax, mask AS_QUITTING
		jnz	exit
	;
	; For DOS files, we flag the document type in instance data.
	; We also remember the file name so when we save, we export
	; the file back to the original name.
	;
		mov	di, ds:[si]				
		add	di, ds:[di].Gen_offset
		lea	di, ds:[di].WDI_dosFileName
		segmov	es, ds, ax		; es:di = buffer
		push	ds, si
		mov	cx, ss
		lea	dx, ss:[bp].DCP_name
		movdw	dssi, cxdx		; ds:si = filename
		mov	cx, size FileLongName
		rep	movsb			; copy me Jesus
		pop	ds, si
	;
	; Set up the Impex control to do the work (behind the scenes).
	; Also tell the DocumentControl to just hang around for a bit
	; and wait for either an import to be completed or else an
	; error to be displayed.
	;
		push	bp, si
		mov	ax, MSG_WRITE_DC_IMPORT_IN_PROGRESS
		GetResourceHandleNS	WriteDocumentControl, bx
		mov	si, offset WriteDocumentControl
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	bp, si
		call	ImportDocTransparently
exit:
		stc				; return error so we don't
						; open *another* document
		ret
endif
WriteDocumentOpen	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfNativeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if this is a native GeoWrite file

CALLED BY:	WriteDocumentOpen()

PASS:		ss:bp	= DocumentCommonParams

RETURN:		carry	= clear if it is a native GeoWrite file
			- or -
		carry	= set if it is not (i.e. a DOS file)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		stevey 	10/29/98    	Initial version
		Don	2/21/99		Re-wrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_SUPER_IMPEX
CheckIfNativeFile	proc	near
		uses	ax, bx, cx, dx, bp, si, di, es, ds
		.enter
	;
	; Construct the complete path (sigh)
	;
		segmov	ds, ss, ax
		mov	es, ax
		mov	cx, PATH_BUFFER_SIZE + (size GeosFileType)
		sub	sp, cx
		mov	dx, sp
		mov	di, sp			; buffer => ES:DI
		mov	bx, ss:[bp].DCP_diskHandle
		lea	si, ss:[bp].DCP_path
		push	dx
		mov	dx, 1
		call	FileConstructFullPath
		pop	dx
		cmc				; invert carry
		jnc	done			; if error, assume native file
	;
	; Append the filename onto the path. Ensure that a BACKSLASH
	; separates the path from the filename.
	;
		mov	ax, C_BACKSLASH		
SBCS <		cmp	{byte} es:[di-1], al				>
DBCS <		cmp	{word} es:[di-2], ax				>
		je	copyString
		LocalPutChar	esdi, ax
copyString:
		lea	si, ss:[bp].DCP_name
		LocalCopyString
	;
	; OK...now see if this is a GEOS file or not. If we get
	; ERROR_ATTR_NOT_FOUND, then we don't have a GEOS file.
	;
		mov	ax, FEA_FILE_TYPE
		mov	di, dx
		add	di, PATH_BUFFER_SIZE
		mov	cx, size GeosFileType
		call	FileGetPathExtAttributes
		jnc	checkType
		cmp	ax, ERROR_ATTR_NOT_FOUND
		je	dosFile
		clc				; some other error...assume
		jmp	done			; native file and we're done
checkType:
		cmp	{word} es:[di], GFT_NOT_GEOS_FILE
		clc				; assume native file
		jne	done
dosFile:
		stc				; DOS file!!!
done:
		lahf
		add	sp, PATH_BUFFER_SIZE + (size GeosFileType)
		sahf

		.leave
		ret
CheckIfNativeFile	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ImportDocTransparently
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invokes ImportControl to import the document.

CALLED BY:	WriteDocumentOpen
PASS:		*ds:si	= WriteDocument object
		ss:bp	= DocumentCommonParams

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey  11/06/98    	Initial version
	dmedeiros 10/16/00	Made far procedure so it can be called from
				elsewhere.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_SUPER_IMPEX
ImportDocTransparently	proc	far
		class	WriteDocumentClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter
	;
	; Bring up the dialog (because otherwise it's Unhappy) in the
	; background.
	;
		push	bp
		mov	ax, MSG_GEN_INTERACTION_INITIATE_NO_DISTURB
		GetResourceHandleNS WriteImportControl, bx
		mov	si, offset WriteImportControl
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_IMPORT_CONTROL_GET_FILE_SELECTOR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ^lcx:dx = file selector
		Assert	optr, cxdx
		movdw	bxsi, cxdx		; ^lbx:si = file selector
		pop	bp 			; DocumentCommonParams => SS:BP
	;
	; Set the path and then the file.
	;
		push	bp
		mov	ax, MSG_GEN_PATH_SET
		mov	cx, ss
		lea	dx, ss:[bp].DCP_path
		mov	bp, ss:[bp].DCP_diskHandle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		pop	bp
		mov	cx, ss
		lea	dx, ss:[bp].DCP_name
		mov	ax, MSG_GEN_FILE_SELECTOR_SET_SELECTION
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Tell it to do the import now (assuming auto-detect will do
	; the right thing)
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		GetResourceHandleNS WriteImportControl, bx
		mov	si, offset WriteImportControl
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_IMPORT_CONTROL_IMPORT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		
		.leave
		ret
ImportDocTransparently	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedFileType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieves the selection from the "save-as" file selector.

CALLED BY:	WriteDocumentSave
PASS:		nothing
RETURN:		cx = WriteDocumentFileType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey  11/12/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_SUPER_IMPEX
GetSelectedFileType	proc	near
		uses	ax,bx,dx,si,di,bp
		.enter

		GetResourceHandleNS	WriteDocumentControl, bx
		mov	si, offset WriteDocumentControl
		mov	ax, MSG_WRITE_DC_GET_SELECTED_FILE_TYPE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
GetSelectedFileType	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExportDocTransparently
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invokes the ExportCtrl to export the document.

CALLED BY:	WriteDocumentSaveAs
PASS:		cx = WriteDocumentFileType
		ss:bp = DocumentCommonParams
RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	exports the document

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey 	11/12/98    	Initial version
	dmedeiros 10/03/00	made proc _far_ so that we can call it from elsewhere
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_SUPER_IMPEX
ExportDocTransparently	proc	far
		class	WriteDocumentClass
		uses	ax,bx,cx,dx,si,di,bp
		.enter	inherit WriteDocumentSaveAs
	;
	; Bring up the dialog (because otherwise it's Unhappy) in the
	; background.
	;
		push	cx			; save file type
		push	bp			; stack frame
		mov	ax, MSG_GEN_INTERACTION_INITIATE_NO_DISTURB
		GetResourceHandleNS WriteExportControl, bx
		mov	si, offset WriteExportControl
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp			; stack frame
	;
	; Get the format-type selector (a GenDynamicList).
	;
		push	bp
		GetResourceHandleNS WriteExportControl, bx
		mov	si, offset WriteExportControl
		mov	ax, MSG_EXPORT_CONTROL_GET_FORMAT_LIST
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ^lcx:dx = format list
		pop	bp
	;
	; Set the output format (hack, hack, hack)
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	bx, cx
		mov	si, dx			; GenItemGroup => BX:SI
		pop	cx			; WriteDocumentFileType => CX
		cmp	cx, WDFT_TEXT
		mov	cx, 0			; "Ascii" is listed first
		je	setSelection
		mov	cx, 1			; "Rich Text Format" is second
setSelection:
		push	bp
		clr	dx
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		mov	cx, 1			; pretend user clicked on entry
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp

		mov	ax, 10			; !!!hack!!!
		call	TimerSleep		; sleep for a bit to make sure
						; the Import DB finishes with
						; setting the default file name
	;
	; Set the output path to whatever the user selected in the
	; "save-as" dialog (it's in DocumentCommonParams).
	;
		GetResourceHandleNS WriteExportControl, bx
		mov	si, offset WriteExportControl
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_SELECTOR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		movdw	bxsi, cxdx		; ^lbx:si = file selector

		push	bp
		mov	ax, MSG_GEN_PATH_SET
		mov	cx, ss
		lea	dx, ss:[bp].DCP_path
		mov	bp, ss:[bp].DCP_diskHandle
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp
	;
	; Set the output filename to whatever the user had in the
	; "save-as" dialog (it's in DocumentCommonParams).
	;
		mov	ax, MSG_EXPORT_CONTROL_GET_FILE_NAME_FIELD
		GetResourceHandleNS WriteExportControl, bx
		mov	si, offset WriteExportControl
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; ^lcx:dx = optr
		Assert	optr, cxdx
		movdw	bxsi, cxdx

		mov	dx, ss
		lea	bp, ss:[bp].DCP_name	; ss:bp = filename
		clr	cx			; null-terminated
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Tell it to do the export now.
	;
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		GetResourceHandleNS WriteExportControl, bx
		mov	si, offset WriteExportControl
		mov	cx, IC_DISMISS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_EXPORT_CONTROL_EXPORT
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
ExportDocTransparently	endp
endif

DocOpenClose ends
