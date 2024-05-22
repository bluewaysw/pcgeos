COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS	
MODULE:		ResEdit/Document
FILE:		documentOpenClose.asm

AUTHOR:		Cassie Hartzog, Sep 25, 1992

ROUTINES:
	Name			Description
	----			-----------
	DocumentUpdateIncompatibleDocument	A document with an earlier 
				protocol has been opened and must be updated 
				for use with this version of the code. 
	Upgrade10Document	Upgrade earlier (1.0) translation document. 
	Upgrade20Document	Upgrade earlier (2.0) translation document. 
	DestroyUIForDocument	The file is about to be closed. Destroy the UI 
				components created when it was opened. 
	DetachUIFromDocument	Document is about to close, detach the UI from 
				it. 
	CreateUIForDocument	A new document has been created, create the UI 
				for it. 
	AttachUIToDocument	Document has been opened, add things in 
				visually 
	SetCurrentResourceState	Attaching UI to document without a state block. 
				Initialize the current resource, chunk stuff. 
	SetUIState		Sets the state for some UI components. 
	DocumentAddChildren	Attaching UI to the document, add the text, 
				glyph objects as its Vis children. 
	SetNameAndUserNotesInteraction	Document opened, initialize the 
				NameAndNotesInteraction to display the correct 
				stuff. 
	SetTextField		Replace text with passed text. 
	DocumentDelayMessage	Delay the sending of the passed message. 
	REDInitializeDocumentFile	User wants to create a new translation 
				file. 
	CloseFilesAndFreeBlocks	There was an error creating the translation 
				file. Free all blocks, close all files. 
	FreeTheDB		Creation of the translation file failed, free 
				the DB that was created for it. 
	DeleteAllGroups		There was an error creating the translation 
				file. Delete the DB structure that was created 
				for it. 
	ReadLocalizationFile	A new file has been opened, read the 
				localization file information into 
				ResourceArray structure then close it. 
	REDOpenSourceGeode	Open the source geode. 
	REDReadSourceGeode	Read source geode information. 
	AssertFileType		Assert that the file is of the passed file 
				type. 
	SourceGeodeFileError	Put up a dialog reporting the source geode file 
				error passed in ax. 
	LocalizationFileError	Put up a dialog reporting the source geode file 
				error passed in ax. 
	CopyFileNameInfo	Copy destination geode longname and source 
				geode DOS name to TransMapHeader. The user can 
				change the destination name later. 
	LoadTables		Load tables from geode header into memory 
				blocks. 
	FilePosAndRead		Read some bytes from the geode file into a 
				memory block. 
	CloseGeodeAndFreeTables	Close the geode file and free its associated 
				tables. 
	REDOpenLocalizationFile	Opens a document's localization file. 
	BuildLocalizationFileName	Build the localization filename and 
				write it to the specified buffer. 
	REDLockMap		Lock the document's TransMapHeader. 
	OpenSourceFile		Open the file, whose path and name are passed 
				in the TransMapHeader. 
	AssertLocalization	Verify that the source file is a localization 
				file 
	ProcessGeodeHeader	Copy values from the GeodeHeader to the 
				TransMapHeader. 
	CheckIfUILibrary	Determines if geode being parsed is the UI 
				library. 
	AllocResourceHandleTable	Allocate a fixed block on the heap for 
				ResourceHandleTable. 
	REDMarkClean		Mark the document clean so that on close the 
				user won't be prompted to save/discard changes. 
				We want the changes automatically written out 
				to disk, but not committed, so the user can 
				revert the changes. This is used in batch 
				processing. 
	REDCDisplayDialog	Only put the New/Open dialog up if we are not 
				in batch mode. 
	LockTransFileMap	Lock the map block for the translation file 
				whose file handle, group and item numbers are 
				stored in TFF. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CH	9/25/92		Initial revision
	pjc	10/9/95		Now localization files are automatically
				opened based on the geode name.

DESCRIPTION:
	
	This file contains the document open/close related code for
	ResEditDocumentClass.

	$Id: documentOpenClose.asm,v 1.1 97/04/04 17:14:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include Internal/geodeStr.def
include Internal/threadIn.def
include Internal/specUI.def


DocOpenClose segment resource

DOC_ObjMessage_call	proc	near
	push	di
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	DOC_ObjMessage_common, di
DOC_ObjMessage_call	endp

DOC_ObjMessage_send	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	GOTO	DOC_ObjMessage_common, di
DOC_ObjMessage_send	endp

DOC_ObjMessageFixupDS	proc	near
	push	di
	mov	di, mask MF_FIXUP_DS
	FALL_THRU	DOC_ObjMessage_common, di
DOC_ObjMessageFixupDS	endp

DOC_ObjMessage_common	proc	near
	call	ObjMessage
	FALL_THRU_POP	di
	ret	
DOC_ObjMessage_common	endp

.rcheck
.wcheck


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentUpdateIncompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A document with an earlier protocol has been opened and
		must be updated for use with this version of the code.
				
CALLED BY:	MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		carry clear if upgrade successful
		ax - non-zero to up the protocol
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentUpdateIncompatibleDocument	method dynamic ResEditDocumentClass,
			MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT

	;
	; first, get the document's protocol number
	;
	call	GetFileHandle			; ^Hbx <- file handle
	sub	sp, size ProtocolNumber
	mov	di, sp
	segmov	es, ss
	mov	cx, size ProtocolNumber
	mov	ax, FEA_PROTOCOL
	call	FileGetHandleExtAttributes
		CheckHack <offset PN_major eq 0 and offset PN_minor eq 2>
	pop	bx		; bx <- major #
	pop	cx		; cx <- minor #

	;;; This method should never be called if no extended attrs
EC<	jc	error				; => file w/o extended attrs>

	cmp	bx, 2
	je	upgrade20

	cmp	bx, 1
	stc
	jne	error
	
	sub	sp, size UpdateResourceArraryStruct
	mov	bp, sp
	mov	ss:[bp].URAS_EACS.EACS_size, size UpdateResourceArraryStruct
	mov	ss:[bp].URAS_EACS.EACS_callback.segment, cs
	mov	ss:[bp].URAS_EACS.EACS_callback.offset, offset Upgrade10Document	
	call	EnumAllChunks
	add	sp, size UpdateResourceArraryStruct

upgrade20:
	call	Upgrade20Document
	jc	error
	mov	ax, 1				; up the protocol
error:
	ret
DocumentUpdateIncompatibleDocument		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Upgrade10Document
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade earlier (1.0) translation document.

CALLED BY:	DocumentUpdateIncompatibleDocument (via EnumAllChunks)
PASS:		*ds:si	- ResourceArray
		ds:di	- ResourceArrayElement
		cx	- group
		dx	- file handle
		ss:bp	- UpdateResourceArrayStruct
RETURN:		nothing
DESTROYED:	bx, di (by EnumAllChunks), ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Upgrade10Document		proc	far
	uses	cx,dx
	.enter

	; get the old TextStringArgs and clr the byte
	;
	clr	al
	xchg	al, ds:[di].RAE_data.RAD1_stringArgs

	clr	bx
	tst	al
	jz	done
	test	al, mask TEXT_FIRST_ARGUMENT_10
	jz	noArg1
	inc	bh				; there is 1 argument 1

noArg1:
	test	al, mask TEXT_SECOND_ARGUMENT_10
	jz	done
	inc	bl				; there is 1 argument 2

done:
	; store the new string args
	;
	mov	ds:[di].RAE_data.RAD_stringArgs, bx
	call	DBDirty_DS
	clc

	.leave
	ret
Upgrade10Document	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Upgrade20Document
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade earlier (2.0) translation document.

CALLED BY:	DocumentUpdateIncompatibleDocument 
PASS:		*ds:si	- document
RETURN:		carry set on error
DESTROYED:	ax, bx, cx, dx, di, es

PSEUDO CODE/STRATEGY:
	Construct the full source path from the disk handle and path
	as currently stored in the map header.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Upgrade20Document		proc	near

	GetResourceHandleNS	ProjectMenuUI, bx
	mov	si, offset ResetSourcePathInteraction
	mov	dl, VUM_MANUAL
	mov	ax, MSG_GEN_SET_USABLE
	call	DOC_ObjMessage_send

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	DOC_ObjMessage_call
	clc
	ret

Upgrade20Document	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateCompatibleDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade a 3.1 document to 3.2: we need to clear out the 
		TMH_copyrightHandle field of the map block so that it does
		not specify an illegal handle.  The VM block will be created
		when the translation file is updated.

CALLED BY:	MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
RETURN:		carry - set if error
		ax - non-zero to update document's protocol
		cx, dx, bp - destroyed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	12/06/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateCompatibleDocument	method dynamic ResEditDocumentClass, 
					MSG_GEN_DOCUMENT_UPDATE_EARLIER_COMPATIBLE_DOCUMENT
	;
	; check document's protocol number
	;
	call	GetFileHandle			; ^hbx <- file handle
	sub	sp, size ProtocolNumber
	mov	di, sp
	segmov	es, ss
	mov	cx, size ProtocolNumber
	mov	ax, FEA_PROTOCOL
	call	FileGetHandleExtAttributes
		CheckHack <offset PN_major eq 0 and offset PN_minor eq 2>
	pop	bx		; bx <- major #
	pop	cx		; cx <- minor #
	cmp	bx, 3		; accept only 3.xx
	jnz	error
	cmp	cx, 1
	ja	error		; accept .1 or below

	;
	; lock down map block
	;
	call	GetFileHandle		; ^hbx <- file handle
	mov	dx, bx
	call	DBLockMap_DS		; *ds:si <- ResourceMap
	mov	si, ds:[si]		; ds:si <- TransMapHeader

	;
	; clear the copyright item and clean up.
	;
	clr	ds:[si].TMH_copyrightGroup
	clr	ds:[si].TMH_copyrightItem
	call	DBDirty_DS
	call	DBUnlock_DS

	mov	ax, 1			; increment protocol
	
error:	
	ret
UpdateCompatibleDocument	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyUIForDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The file is about to be closed.  Destroy the 
		UI components created when it was opened.

CALLED BY:	UI - MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyUIForDocument		method dynamic ResEditDocumentClass,
				MSG_GEN_DOCUMENT_DESTROY_UI_FOR_DOCUMENT

	push	ax, si

	; detach the OrigContent from the left view
	; 
	mov	di, ds:[si]
	add	di, ds:[di].ResEditDocument_offset
	mov	bx, ds:[di].GDI_display

	; unset the LeftView's content so it can be destroyed
	;
	mov	si, offset LeftView
	movdw	cxdx, 0
	mov	ax, MSG_GEN_VIEW_SET_CONTENT
	call	DOC_ObjMessage_send
	
	mov	bx, ds:[di].REDI_editText.handle
	mov	si, offset OrigContent
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_DESTROY
	call	DOC_ObjMessage_send

	; free the entire content block
	;
	mov	ax, MSG_META_BLOCK_FREE
	call	DOC_ObjMessage_send

	; now let the superclass do its thing
	;
	pop	ax, si
	mov	di, offset ResEditDocumentClass
	GOTO	ObjCallSuperNoLock

DestroyUIForDocument		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DetachUIFromDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document is about to close, detach the UI from it.	

CALLED BY:	MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DetachUIFromDocument		method dynamic ResEditDocumentClass,
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT

	; Free the PosArray

		clr 	bx
		xchg	bx, ds:[di].REDI_posArray
		tst	bx
		jz	noPosArray
		call	MemFree

noPosArray:

	; Remove the document's children

		push	si
		movdw	bxsi, ds:[di].REDI_editText
		mov	ax, MSG_VIS_REMOVE
		mov	dl, VUM_MANUAL
		call	DOC_ObjMessage_send
	
		mov	si, offset TransDrawText
		mov	ax, MSG_VIS_REMOVE
		mov	dl, VUM_MANUAL
		call	DOC_ObjMessage_send

	; Detach the document from the OrigContent

		clrdw	cxdx
		mov	si, offset OrigContent
		mov	ax, MSG_RESEDIT_CONTENT_SET_DOCUMENT
		call	DOC_ObjMessage_send
		pop	si

	; Detach the content from the view (cx:dx = 0)

		call	GetDisplayHandle		;^hbx <- display
		mov	si, offset LeftView		;^lbx:si = LeftView
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		call 	DOC_ObjMessage_send

		ret
DetachUIFromDocument		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateUIForDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new document has been created, create the UI for it.

CALLED BY:	MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClassClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	3/ 4/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateUIForDocument		method dynamic ResEditDocumentClass,
					MSG_GEN_DOCUMENT_CREATE_UI_FOR_DOCUMENT

	; Have superclass do its thang

		mov	di, offset ResEditDocumentClass	
		call	ObjCallSuperNoLock

	; Duplicate the ContentTemplate resource

		GetResourceHandleNS	ContentTemplate, bx	
		clr	ax			; have current geode own block
		clr	cx  			; have current thread run it
		call 	ObjDuplicateResource	; bx = handle of dup'ed block

	; save EditText's optr in my instance data for easy access

		DerefDoc
		mov	ax, offset EditText
		movdw	ds:[di].REDI_editText, bxax

		ret
CreateUIForDocument		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AttachUIToDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document has been opened, add things in visually

CALLED BY:	MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
PASS:		*ds:si	= ResEditDocumentClass object
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		nothing

DESTROYED:	everything

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CH	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AttachUIToDocument	method dynamic ResEditDocumentClass, 
					MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

	; While initializing the UI, ignore all text object height changes

		ornf	ds:[di].REDI_state, mask DS_IGNORE_HEIGHT_CHANGES

	; Have superclass do its thang

		mov	di, offset ResEditDocumentClass	
		call	ObjCallSuperNoLock
		DerefDoc				; ds:di <- document

	; Set LeftView's content (make this a call to force the view
	; to get built out now)

		push	si
		mov	cx, ds:[di].REDI_editText.handle
		mov	dx, offset OrigContent		;^lcx:dx = OrigContent
		pushdw	cxdx
		call	GetDisplayHandle		;^hbx <- display
		mov	si, offset LeftView		;^lbx:si = LeftView
		mov	ax, MSG_GEN_VIEW_SET_CONTENT
		call 	DOC_ObjMessage_call
		popdw	bxsi				;^lbx:si = OrigContent

	; Save the document optr in the OrigContent object

		mov	cx, ds:[LMBH_handle]
		pop	dx				;^lcx:dx = document
		push	dx
		mov	ax, MSG_RESEDIT_CONTENT_SET_DOCUMENT
		call	DOC_ObjMessage_send

	; set EditText's output to be this document, so it receives
	; MSG_META_TEXT_USER_MODIFIED messages

		mov	si, ds:[di].REDI_editText.chunk	;^lbx:si = EditText
		mov	ax, MSG_VIS_TEXT_SET_OUTPUT
		call	DOC_ObjMessage_send
		pop	si

	; add the VisChildren 

		call	DocumentAddChildren

		call	GeodeGetProcessHandle
		mov	ax, MSG_RESEDIT_GET_RESTORING_FROM_STATE
		call	DOC_ObjMessage_call

		call	GetFileHandle		;^hbx <- translation file
		cmp	al, BB_TRUE
		je	restore

		call	SetCurrentResourceState
done:
		ret

restore:
		DerefDoc
		mov	cx, ds:[di].REDI_numChunks
		call	CreatePosArray
		mov	ds:[di].REDI_posArray, cx
		mov	cx, ds:[di].REDI_viewWidth
		call	RecalcChunkPositions
		jmp	done

AttachUIToDocument	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCurrentResourceState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attaching UI to document without a state block.
		Initialize the current resource, chunk stuff.

CALLED BY:	AttachUIToDocument
PASS:		*ds:si - document
		ds:di - document
		^hbx - translation file
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,di,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/12/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCurrentResourceState		proc	near
	.enter

	; Lock the TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	esdi, cxax		; *es:di = TransMapHeader.

	; Count the number of resource elements in the ResourceMapArray.

		segxchg	es, ds
		xchg	di, si			; *ds:si = TransMapHeader
						; *es:di = Document
		call	ChunkArrayGetCount	; cx = # resources in map
		segxchg	es, ds
		xchg	di, si			; *es:di = TransMapHeader
						; *ds:si = Document

	; Get the total number of resources from the array as well.

		mov	di, es:[di]		; es:di <- TransMapHeader
		mov	ax, es:[di].TMH_totalResources
		mov	dl, es:[di].TMH_stateFlags ; DocumentState flags

	; Unlock the TransMapHeader.

		call	DBUnlock

	; Store the resource counts and DS flags in the document.

		DerefDoc
		andnf	dl, mask DS_UPDATE_NOT_COMMITTED
		ornf	ds:[di].REDI_state, dl	; Restore update state
		mov	ds:[di].REDI_totalResources, ax
		mov	ds:[di].REDI_mapResources, cx

		call	SetUIState		; set state for other UI

	; Set current resource = 0 so that info in document instance 
	; data needed for list initialization gets set 
	; (REDI_mapResources, REDI_numChunks).

		mov	ds:[di].REDI_curChunk, PA_NULL_ELEMENT
		clr	ax
		call	SetCurrentResourceInfo

	; Now set REDI_curResource to NULL for drawing so initial
	; draw pass is ignored, until view has sized itself.

		mov	ds:[di].REDI_curResource, PA_NULL_ELEMENT

	; Initialize the ResourceList and ChunkList.

		push	si
		call	GetDisplayHandle	;^hbx <- display
		mov	si, offset ResourceList	;^lbx:si <- Res. List

		push	ds:[di].REDI_numChunks
		mov	cx, ds:[di].REDI_mapResources	;cx <- # resources
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		call 	DOC_ObjMessageFixupDS

		clr	cx
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call 	DOC_ObjMessageFixupDS
		pop	cx			;cx <- # of chunks

		pop	si			;*ds:si <- document
		DerefDoc
		mov	ds:[di].REDI_curTarget, ST_TRANSLATION
		mov	ds:[di].REDI_newTarget, ST_TRANSLATION

	; Now change the display to resource 0.  This must be done
	; after the view is opened and sized (while its width is 
	; non-zero, the document's height is 0, and nothing gets drawn)
	; so delay this message via the queue, twice.

		clr	cx
		mov	bx, ds:[LMBH_handle]
		mov	dx, MSG_RESEDIT_DOCUMENT_CHANGE_RESOURCE
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		mov	ax, MSG_RESEDIT_DOCUMENT_DELAY_MESSAGE
		call	ObjMessage

	; And set the current chunk to 0.
	; Delay this message via the queue, twice.

		clr	cx
		mov	dx, MSG_RESEDIT_DOCUMENT_CHANGE_CHUNK
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		mov	ax, MSG_RESEDIT_DOCUMENT_DELAY_MESSAGE
		call	ObjMessage

		clr	cx
		clr	dx
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	GetDisplayHandle
		mov	si, offset ChunkList
		clr	di
		call 	ObjMessage

		.leave
		ret
SetCurrentResourceState		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUIState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the state for some UI components.

CALLED BY:	AttachUIToDocument, DocumentGainedModelExcl
PASS:		*ds:si = document 
		ds:di = document 
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUIState		proc	far
	uses	si
	.enter

	call	SetNameAndUserNotesInteraction	; init file menu UI
	call	SetResetSourcePathInteraction	; init more file menu UI
	call	SetCopyrightInteraction		; init even more file menu UI hahah!

	;
	; set the filter lists' state to match the filter flags set
	; in the document instance data
	;
	mov	cl, ds:[di].REDI_typeFilter
	mov	ax, MSG_RESEDIT_DOCUMENT_SET_TYPE_FILTER_LIST_STATE
	call	ObjCallInstanceNoLock
	mov	cl, ds:[di].REDI_stateFilter
	mov	ax, MSG_RESEDIT_DOCUMENT_SET_STATE_FILTER_LIST_STATE
	call	ObjCallInstanceNoLock

	; 
	; Set the state of the commit trigger
	;
	GetResourceHandleNS	CommitTrigger, bx
	mov	si, offset CommitTrigger
	mov	ax, MSG_GEN_SET_NOT_ENABLED
 	test	ds:[di].REDI_state, mask DS_UPDATE_NOT_COMMITTED
	jz	setCommitTrigger
	mov	ax, MSG_GEN_SET_ENABLED
setCommitTrigger:
	mov	dl, VUM_NOW
	call	DOC_ObjMessage_send

	.leave
	ret
SetUIState		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentAddChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attaching UI to the document, add the text, glyph
		objects as its Vis children.

CALLED BY:	AttachUIToDocument
PASS:		*ds:si	- document
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentAddChildren		proc	near
	.enter

EC <	call	AssertIsResEditDocument				>
	DerefDoc

	;
	; Add the duplicated TransDrawText and EditText
	; objects as children of the document.
	;
	mov	cx, ds:[di].REDI_editText.handle
	mov	dx, offset TransDrawText	; ^lcx:dx = text object
	mov	ax, MSG_VIS_ADD_CHILD		; add it as a vis child
	mov	bp, CCO_FIRST shl offset CCF_REFERENCE
	call 	ObjCallInstanceNoLock

	;
	; The EditText object must be the first child if the focus and
	; target hierarchies are to work correctly.
	;
	mov	bp, CCO_FIRST shl offset CCF_REFERENCE
	mov	dx, offset EditText
	mov	ax, MSG_VIS_ADD_CHILD		; add it as a vis child
	call 	ObjCallInstanceNoLock

	; mark the objects as window invalid so that 
	; they will get opened when the window group is updated,
	; in case the parent is already opened.	
	;
	push	si
	movdw	bxsi, cxdx
	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset TransDrawText
	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_MANUAL
	mov	ax, MSG_VIS_MARK_INVALID
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	; open the document object so that all the objects 
	; below it will be realized (and therefore visible)
	;
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	call 	ObjCallInstanceNoLock

	.leave
	ret
DocumentAddChildren		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNameAndUserNotesInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document opened, initialize the NameAndNotesInteraction
		to display the correct stuff.

CALLED BY:	SetUIState
PASS:		*ds:si	-	document
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNameAndUserNotesInteraction		proc	near
	uses	si, di
	.enter

	call	GetFileHandle
	call	DBLockMap
	mov	di, es:[di]

	GetResourceHandleNS 	ResEditFileName, bx
	mov	dx, es

	mov	si, offset ResEditFileName
	lea	bp, es:[di].TMH_destName
	call	SetTextField

	mov	si, offset UpdateNameTextEntry
	lea	bp, es:[di].TMH_sourceName
	call	SetTextField

	mov	si, offset ResEditUserNotes
	lea	bp, es:[di].TMH_userNotes
	call	SetTextField

	call	DBUnlock

	.leave
	ret
SetNameAndUserNotesInteraction		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetResetSourcePathInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Document opened, initialize ResetSourcePathInteraction

CALLED BY:	SetUIState, DocumentResetSourcePath
PASS:		*ds:si	-	document
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,bp,es

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/17/00		Initial version (copied from Cassie's original)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetResetSourcePathInteraction		proc	far
	uses	si, di
	.enter

	call	GetFileHandle
	call	DBLockMap
	mov	di, es:[di]

	GetResourceHandleNS 	ProjectMenuUI, bx
	mov	dx, es

	mov	si, offset ProjectMenuUI:ResetSourcePathCurrentPath
	lea	bp, es:[di].TMH_relativePath
	call	SetTextField

	mov	si, offset ProjectMenuUI:ResetSourcePathCurrentGeode
	lea	bp, es:[di].TMH_sourceName
	call	SetTextField

	call	DBUnlock

	.leave
	ret
SetResetSourcePathInteraction		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCopyrightInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes "change copyright" interaction UI.

CALLED BY:	
PASS:		*ds:si -- document object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dmedeiros	12/11/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCopyrightInteraction	proc	far
	uses	ax, bx, dx, es, di, si, bp
	.enter
	call	GetFileHandle
	call	DBLockMap
	mov	di, es:[di]	; es:di <- TransMapHeader

	tst	es:[di].TMH_copyrightItem
	jz	clearCopyrightField
	mov	ax, es:[di].TMH_copyrightGroup
	mov	di, es:[di].TMH_copyrightItem
	push	es
	call	DBLock
	mov	dx, es
	mov	bp, es:[di]	; dx:bp <- copyright string
	GetResourceHandleNS 	FileMenuUI, bx
	mov	si, offset NewCopyrightText		; bx:si <- text object optr
	call	SetTextField	
	call	DBUnlock
	pop	es		; es <- seg of TransMapHeader

	jmp	done

clearCopyrightField:	
	GetResourceHandleNS 	FileMenuUI, bx
	mov	si, offset NewCopyrightText		; bx:si <- text object optr
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	di, mask MF_CALL
	call	ObjMessage
	
done:
	call	DBUnlock
	.leave
	ret
SetCopyrightInteraction	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace text with passed text.

CALLED BY:	SetNameAndUserNotesInteraction, SetResetSourcePathInteraction 
PASS:		dx:bp - ptr to text
		^lbx:si - text object
RETURN:		nothing
DESTROYED:	ax, cx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	4/11/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetTextField		proc	near
		uses	dx, di
		.enter

		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	
		call	DOC_ObjMessage_call

		mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
		call	DOC_ObjMessage_send
		
		.leave
		ret
SetTextField		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DocumentDelayMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delay the sending of the passed message.

CALLED BY:	MSG_RESEDIT_DOCUMENT_DELAY_MESSAGE

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of ResEditDocumentClass
		ax - the message
		dx - the real message to be sent

RETURN:		nothing

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DocumentDelayMessage		method dynamic ResEditDocumentClass,
					MSG_RESEDIT_DOCUMENT_DELAY_MESSAGE
	mov	ax, dx
	mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
	mov	bx, ds:[LMBH_handle]
	call	ObjMessage
	ret
DocumentDelayMessage		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User wants to create a new translation file.

CALLED BY:	UI - MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= document instance data
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		carry - set if error

DESTROYED:	bx, si, di, ds, es (method handler)
		cx, dx 

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CH	9/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDInitializeDocumentFile		method dynamic ResEditDocumentClass, 
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
		.enter

	; Let our superclass do its stuff.
	
		mov	di, offset ResEditDocumentClass
		call	ObjCallSuperNoLock

	; Put up hourglass.

		call	MarkBusyAndHoldUpInput

	; Begin with the translation item as the target.
	
		DerefDoc
		mov	ds:[di].REDI_curTarget, ST_TRANSLATION	

	; Allocate a new handle table.

		call	AllocResourceHandleTable	; es <- DHS segment

	; Create the map block and ResourceArray for translation file.

		call	GetFileHandle		; bx <- document handle
		call 	AllocMapItem		; ax:di <- ResourceMap
		call	DBSetMap		; Mark as map block

	; Set up the destination DBGroup/Item for the parsed data

		sub	sp, size TranslationFileFrame
		mov	bp, sp
		mov	ss:[bp].TFF_handles, es		; DHS segment
		mov	ss:[bp].TFF_transFile, bx	; Document.
		mov	ss:[bp].TFF_destGroup, ax
		mov	ss:[bp].TFF_destItem, di
		clr	ss:[bp].TFF_locFile
		clr	ss:[bp].TFF_geodeFile
EC<		mov	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG >
	
	; Lock the map block and mark it dirty.

		call	DBLock			; *es:di <- map block
		call	DBDirty
		mov	di, es:[di]

if	not DBCS_PCGEOS
	; If importing, get geode filename from import dialog.
	
		call	DIECheckIfImporting
		jnc	getFileNameNoImport
		mov	ax, offset ImportAsciiFileLocText
		call	DIEGetImportFileName
		jmp	gotFileName

getFileNameNoImport:
endif	; not DBCS_PCGEOS

		call	DBUnlock

	; Prompt user for geode filename, and put it in TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_PROMPT_FOR_SOURCE_GEODE_NAME
		call	ObjCallInstanceNoLock
		jc	error

gotFileName:

	; Open, read, and parse the geode.  ReadGeodeFile closes the geode if 
	; and frees the resource tables if successful.

		mov	ax, MSG_RESEDIT_DOCUMENT_READ_SOURCE_GEODE
		call	ObjCallInstanceNoLock	; cx <- # of editable resources
		jc	error			; Error reading the geode?
		mov	ax, EV_NO_RESOURCES
		jcxz	error			; Error if no resource.

	; Open the selected file, and if it was a localization file, 
	; get the LongName of the geode to open.

		mov	ax, MSG_RESEDIT_DOCUMENT_OPEN_LOCALIZATION_FILE
		call	ObjCallInstanceNoLock
		jc	error
		mov	ss:[bp].TFF_locFile, ax

	; Now read the localization file, merging its info into
	; the translation file.
	
		call	ReadLocalizationFile
		jc	error

if	not DBCS_PCGEOS
	; If we are importing, now is the time to apply the changes
	; specified in the ATF to the DB file we just created!

		call	DIECheckIfImporting
		jnc	done
		mov	ax, MSG_RESEDIT_DOCUMENT_ASCII_IMPORT
		GetResourceSegmentNS	ResEditDocumentClass, es
		call	ObjCallInstanceNoLock
		call	DIEDoneImporting
endif	; not DBCS_PCGEOS

done:
		lahf
		add	sp, size TranslationFileFrame
		call	MarkNotBusyAndResumeInput
		sahf
		.leave
		ret

error:
		call	CloseFilesAndFreeBlocks	;close files, free DHS
		call	FreeTheDB		;free all DB groups
SBCS <		call	DIEDisplayDialogAfterErrorIfNecessary		>
		cmp	ax, EV_NO_ERROR		;did user cancel the dialog?
		je	noError
		mov	cx, ax
		mov	ax, MSG_RESEDIT_DOCUMENT_DISPLAY_MESSAGE
		call	ObjCallInstanceNoLock

noError:	
		stc
		jmp	done

REDInitializeDocumentFile		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseFilesAndFreeBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There was an error creating the translation file.
		Free all blocks, close all files.

CALLED BY:	EXTERNAL (InitializeDocumentFile, DocumentUpdateTranslation)
PASS:		*ds:si	- document
		ss:bp	- TranslationFileFrame
RETURN:		nothing
DESTROYED:	bx,dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseFilesAndFreeBlocks		proc	far
	uses	ax, cx
	.enter

	DerefDoc
	tst	ds:[di].REDI_handles
	jz	noHandleStruct

	call	CloseGeodeAndFreeTables

noHandleStruct:
	mov	al, FILE_NO_ERRORS
	tst	ss:[bp].TFF_locFile
	jz	noFile
	test	ss:[bp].TFF_sourceType, GFT_VM
	jz	noFile
	mov	bx, ss:[bp].TFF_locFile
	call	VMClose

noFile:
	; if TFF_otherFile is not a VM file, it is a geode, and
	; was freed in CloseGeodeFile above.
	;

	.leave
	ret
CloseFilesAndFreeBlocks		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeTheDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creation of the translation file failed, free the
		DB that was created for it.

CALLED BY:	
PASS:		*ds:si	- document
RETURN:		
DESTROYED:	bx,dx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	6/ 5/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeTheDB		proc	near
	uses	ax
	.enter

EC <	call	AssertIsResEditDocument				>
	push	ds:[LMBH_handle], si
	call	GetFileHandle
	mov	dx, bx
	call	DBLockMap_DS		; *ds:si <- ResourceMap
	tst	si
	jz	noMap
	mov	bx, cs
	mov	di, offset DeleteAllGroups
	call	ChunkArrayEnum
	mov	bx, dx
	call	DBUnlock_DS
	call	DBGetMap		; ax:di <- ResourceMap group:item
	call	DBGroupFree

noMap:
	pop	bx, si
	call	MemDerefDS

	.leave
	ret
FreeTheDB		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteAllGroups
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	There was an error creating the translation file.
		Delete the DB structure that was created for it.

CALLED BY:	CloseFilesAndFreeBlocks, via ChunkArrayEnum
PASS:		*ds:si	- ResourceMap
		ds:di	- ResourceMapElement	
		^hdx	- translation file

RETURN:		carry clear to continue enumeration
DESTROYED:	ax, bx, di (by ChunkArrayEnum)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/19/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteAllGroups		proc	far

	mov	bx, dx
	mov	ax, ds:[di].RME_data.RMD_group
	tst	ax
	jz	done
	call	DBGroupFree
done:
	clc
	ret
DeleteAllGroups		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadLocalizationFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A new file has been opened, read the localization file
		information into ResourceArray structure then close it.

CALLED BY:	InitializeDocumentFile

PASS:		ss:bp	- TranslationFileFrame
		*ds:si	- document

RETURN:		carry set if unsuccessful 
		ax - error code
		
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	The TransMapHeader contains the localization file's name
	and path when this routine is called.  In CopyLocToTrans,
	the geode's name is read from the localization file's map 
	block header into the TransMapHeader, replacing the localization
	file name.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadLocalizationFile		proc	far
	uses	bx, si
	.enter
	
EC <	call	AssertIsResEditDocument				>
	push	ds:[LMBH_handle]

	; Copy the data from .loc file to the translation file.
	;
	call	CopyLocToTrans			;carry set if error, ax=EV

	push	ax
	pushf
	mov	al, FILE_NO_ERRORS
	clr	bx
	xchg	bx, ss:[bp].TFF_locFile
	call	VMClose
	popf
	pop	ax

	pop	bx
	call	MemDerefDS

	.leave
	ret
ReadLocalizationFile		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDOpenSourceGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the source geode.

CALLED BY:	MSG_RESEDIT_DOCUMENT_OPEN_SOURCE_GEODE
PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
		ss:bp	= TranslationFileFrame

RETURN:		if error,
			carry set
			ax - ErrorValue
		else
			carry clear

DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/27/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDOpenSourceGeode	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_OPEN_SOURCE_GEODE
		uses	cx, dx
		.enter

EC<		cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG >
EC<		ERROR_NE  BAD_TRANSLATION_FILE_FRAME			  >

	; Go to source geode's path.

		call	FilePushDir
		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_SOURCE_PATH
		call	ObjCallInstanceNoLock
		LONG jc	done

	; Lock TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	esdi, cxdx

	; Copy source geode name to TranslationFileFrame.

		push	ds, es, si, di
		segmov	ds, es, si
		lea	si, ds:[di].TMH_sourceName
		segmov	es, ss, di
		lea	di, ss:[bp].TFF_sourceGeodeName
		LocalCopyString
		pop	ds, es, si, di

	; Assert that selected file is an executable.

		push	ds
		mov	ax, GFT_EXECUTABLE
		segmov	ds, ss, dx
		lea	dx, ss:[bp].TFF_sourceGeodeName	; ds:dx = filename
		call	AssertFileType
		pop	ds
		jnc	openGeodeFile
EC <		pushf							>
EC <		cmp	ax, EV_NO_ERROR					>
EC <		ERROR_Z RESEDIT_EXPECT_EXECUTABLE_FILE			>
EC <		popf							>

	; Didn't find geode.  Try alternate (EC/non-EC) version of filename.

	; Determine if name has "EC " prefix.

		push	ds, es, si, di
		segmov	ds, es, si
		lea	si, ds:[di].TMH_sourceName	; es:dx = filename
		LocalGetChar ax, dssi		
SBCS <		cmp	al, 'E'						>
DBCS <		cmp	ax, C_LATIN_CAPITAL_LETTER_E			>
		jne	changeToEC
		LocalGetChar ax, dssi		
SBCS <		cmp	al, 'C'						>
DBCS <		cmp	ax, C_LATIN_CAPITAL_LETTER_C			>
		jne	changeToEC
		LocalGetChar ax, dssi		
SBCS <		cmp	al, ' '						>
DBCS <		cmp	ax, C_SPACE					>
		jne	changeToEC
		segmov	es, ss, di
		lea	di, ss:[bp].TFF_sourceGeodeName
		jmp	copyBaseName

	; Name didn't have "EC " prefix, so add it.

changeToEC:
		lea	si, ds:[di].TMH_sourceName	; es:dx = filename
		segmov	es, ss, di
		lea	di, ss:[bp].TFF_sourceGeodeName
SBCS <		mov	al, 'E'						>
DBCS <		mov	ax, C_LATIN_CAPITAL_LETTER_E			>
		LocalPutChar esdi, ax		
SBCS <		mov	al, 'C'						>
DBCS <		mov	ax, C_LATIN_CAPITAL_LETTER_C			>
		LocalPutChar esdi, ax		
SBCS <		mov	al, ' '						>
DBCS <		mov	ax, C_SPACE					>
		LocalPutChar esdi, ax		

	; Copy name without "EC " prefix.

copyBaseName:
		LocalCopyString
		pop	ds, es, si, di
		
	; Assert that selected file is an executable.

		push	ds
		mov	ax, GFT_EXECUTABLE
		segmov	ds, ss, dx
		lea	dx, ss:[bp].TFF_sourceGeodeName	; ds:dx = filename
		call	AssertFileType
		pop	ds
		jnc	openGeodeFile
EC <		pushf							>
EC <		cmp	ax, EV_NO_ERROR					>
EC <		ERROR_Z RESEDIT_EXPECT_EXECUTABLE_FILE			>
EC <		popf							>

	; We couldn't find an executable.  Handle error.

		mov	ax, EV_FILE_OPEN
		jnc	openGeodeFile
		call	SourceGeodeFileError
		jmp	errorUnlock

openGeodeFile:

	; Open the source geode file.

		push	ds
		segmov	ds, ss, ax			; ds:dx = filename 
		mov	al, FILE_DENY_W or FILE_ACCESS_R
		call	FileOpen
		pop	ds
		mov	bx, ax			; bx <- file handle
		jc	errorUnlock

	; Save the file handle.

		mov	ss:[bp].TFF_geodeFile, bx
		push	ds
		mov	ds, ss:[bp].TFF_handles
		mov	ds:[DHS_geode], bx
		pop	ds

errorUnlock:

	; Unlock TransMapHeader.

		pushf
		push	ax
		call	DBDirty
		call	DBUnlock
		pop	ax
		popf

done:
		call	FilePopDir

		.leave
		ret

REDOpenSourceGeode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDReadSourceGeode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read source geode information.

CALLED BY:	MSG_RESEDIT_DOCUMENT_READ_SOURCE_GEODE

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #
		ss:bp	= TranslationFileFrame

RETURN:		cx	= number of editable resources
		if error, 
			carry set
			ax = ErrorValue
		else
			carry clear

DESTROYED:	if no error, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/22/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDReadSourceGeode	method dynamic ResEditDocumentClass, 
				MSG_RESEDIT_DOCUMENT_READ_SOURCE_GEODE
		uses	dx, bp
		.enter

	; Save original path.

		call	FilePushDir

	; Lock TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	esdi, cxdx

	; Get source geode handle.

		mov	ax, MSG_RESEDIT_DOCUMENT_OPEN_SOURCE_GEODE
		call	ObjCallInstanceNoLock
		jc	errorUnlock
		mov	bx, ss:[bp].TFF_geodeFile

	; Go to source geode's path for later getting extended attributes..

		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_SOURCE_PATH
		call	ObjCallInstanceNoLock
		jc	errorUnlock

	; Copy values from GeodeHeader to TransMapHeader. 

		push	ds, si
		push	bx
		mov	si, ds:[si]	; ds:si <- chunk		
		mov	bx, ds:[si].GenDocument_offset	; bx <- offset of instance data in chunk
		mov	si, ds:[si][bx].GDI_fileHandle	; si <- fileHandle
		pop	bx
		call	ProcessGeodeHeader
			; ax <- resource count
			; bx <- imported library count
			; cx <- exported entry count
		pop	ds, si
		jc	errorUnlock
		mov	ss:[bp].TFF_numResources, ax

	; Make sure resource count fits in one byte.

EC<	 	tst	ah					>
EC<		ERROR_NZ	RESEDIT_INTERNAL_LOGIC_ERROR	>

	; Copy destination geode longname and source geode DOS name to
	; TransMapHeader.

		call	CopyFileNameInfo
		jc	errorUnlock

	; Unlock TransMapHeader.

		call	DBUnlock
	
	; Record resource count in the document instance data.
		push	di
		mov	di, ds:[si]	; ds:di <- chunk		
		mov	di, ds:[di].GenDocument_offset	; di <- offset of instance data in chunk
		mov	ax, ss:[bp].TFF_numResources
		mov	ds:[di].REDI_totalResources, ax
		pop	di

	; Load tables from the geode.

		call	LoadTables
		jc	error			;ax <- ErrorValue

	; Add a ResourceMapElement and create a ResourceArray for each resource

		call	AllocResourceGroups	
		mov	ax, EV_ALLOC_DATABASE
		jc	error

	; Populate the ResourceArrays with dummy chunk names

		call	InitResArrays
		jc	error

	; Parse the chunks which have localization info in the 
	; ResourceMap. Looking for text, gstrings, bitmaps
	
		call	ParseResources		;ax <- # res with chunks
		mov	cx, ax

doneError:

	; Close file and free tables.

		pushf
		push	ax, cx
		call	CloseGeodeAndFreeTables
		pop	ax, cx
		popf

	; Restore the original path.

		call	FilePopDir

		.leave
		ret

errorUnlock:

	; Unlock TransMapHeader.

		call	DBUnlock

error:
		cmp	ax, EV_FILE_READ
		stc
		jne	doneError

		call	SourceGeodeFileError
		jmp	doneError

REDReadSourceGeode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertFileType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Assert that the file is of the passed file type.

CALLED BY:	ReadGeodeFile

PASS:		ax	= GeosFileType
		ds:dx	= filename

RETURN:		carry	= set if error occurs, or types don't match
		ax	= EV_FILE_OPEN if an error occurs, or
			  EV_NO_ERROR if no error, or types don't match

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertFileType	proc	near
fileType	local	GeosFileType
		uses	cx,dx,di,es,ds
		.enter

	; Get the file type.

		mov	bx, ax			; GeosFileType
		segmov	es, ss, ax
		lea	di, ss:[fileType]
		mov	ax, FEA_FILE_TYPE
		mov	cx, size fileType
		call	FileGetPathExtAttributes
		mov	ax, EV_FILE_OPEN
		jc	done

	; Compare against passed type.

		mov	ax, EV_NO_ERROR		; No error value.
		cmp	ss:[fileType], bx
		je	done
		stc

done:
		.leave
		ret
AssertFileType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SourceGeodeFileError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog reporting the source geode file error passed
		in ax.

CALLED BY:	ReadGeodeFile, LoadTables

PASS:		ds:si	- Document
		ax 	- ErrorValue

RETURN:		carry set, ax - EV_NO_ERROR

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	8/11/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SourceGeodeFileError		proc	near
filePath	local	PathName
		uses	bx,cx,dx,si,di,es
		.enter

	; Load source geode path into local variable.

		push	ax
		mov	cx, ss
		lea	dx, ss:[filePath]
		mov	ax, MSG_RESEDIT_DOCUMENT_GET_FULL_SOURCE_PATH
		call	ObjCallInstanceNoLock

	; Lock TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	esdi, cxdx
		pop	ax
		push	si, bp

	; Set up path as first string argument.

		mov	dx, ss	
		lea	bp, ss:[filePath]

	; Set up filename as second string argument.

		mov	bx, es
		lea	si, es:[di].TMH_sourceName 

	; Put up error dialog.

		mov	cx, ax
		call	DocumentDisplayMessage
		pop	si, bp

	; Unlock TransMapHeader

		call	DBUnlock

	; Indicate error has been handled

		mov	ax, EV_NO_ERROR	
		stc

		.leave
		ret
SourceGeodeFileError		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LocalizationFileError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up a dialog reporting the source geode file error passed
		in ax.

CALLED BY:	?

PASS:		ds:si	- Document
		es:di	- TransMapHeader
		ax 	- ErrorValue

RETURN:		carry set, ax - EV_NO_ERROR
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/20/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalizationFileError	proc	near
filePath	local	PathName
fileName	local	DosDotFileName
		uses	bx,cx,dx,si,di,bp,es
		.enter

EC <	call	AssertIsResEditDocument				>

	; Load source geode path into local variable.

		push	ax
		mov	cx, ss
		lea	dx, ss:[filePath]	
		mov	ax, MSG_RESEDIT_DOCUMENT_GET_FULL_SOURCE_PATH
		call	ObjCallInstanceNoLock
		pop	ax

	; Set up filename as second string argument.

		push	ds
		mov	bx, ss
		mov	ds, bx
		lea	si, ss:[fileName]	; bx:si, ds:si = buffer
		call	BuildLocalizationFileName
		pop	ds

	; Set up path as first string argument.

		push	bp
		mov	dx, ss	
		lea	bp, ss:[filePath]

	; Put up error dialog.

		mov	cx, ax
		call	DocumentDisplayMessage
		pop	bp

	; Indicate error has been handled

		mov	ax, EV_NO_ERROR	
		stc

		.leave
		ret
LocalizationFileError	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyFileNameInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy destination geode longname and source geode DOS name to
		TransMapHeader.  The user can change the destination name
		later.

CALLED BY:	ReadGeodeFile

PASS:		ss:bp	- TranslationFileFrame
		es:di	- TransMapHeader
		current directory as geode's source directory

RETURN:		carry set if error
			ax - ErrorValue
DESTROYED:	ax,dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyFileNameInfo	proc	near
DBCS<	tffNptr	local	nptr.TranslationFileFrame	push	bp	>
DBCS<	dosName	local	DosDotFileName				>
		uses	bx,cx,di,si,ds
		.enter

	; Copy the source file longname to destination file longname.

		push	si, di
		segmov	ds, ss, si

SBCS <		lea	si, ss:[bp].TFF_sourceGeodeName	;source		>
DBCS <		mov	si, ss:[tffNptr]				>
DBCS <		add	si, offset TFF_sourceGeodeName	;source		>
		lea	di, es:[di].TMH_destName	;destination
		mov 	{byte} cl, es:[di]
		tst	cl
		jnz	afterMov
		mov	cx, FILE_LONGNAME_BUFFER_SIZE
		rep	movsb
afterMov:
		pop	si, di

	; Get the geode's DOS name.  (This will fail if you try to read a
	; geode off the net, instead of the downloaded version.  Because it
	; is a just a link.)
 
SBCS <		lea	dx, ss:[bp].TFF_sourceGeodeName	;ds:dx <- file name>
DBCS <		mov	dx, ss:[tffNptr]				>
DBCS <		add	dx, offset TFF_sourceGeodeName	;ds:dx <- file name>

if DBCS_PCGEOS

	; For DBCS, load DOS filename onto the stack.
	
		pushdw	esdi
		segmov	es, ss, ax
		lea	di, ss:[dosName]		;es:di <- buffer on stack
		mov	ax, FEA_DOS_NAME
		mov	cx, size DosDotFileName
		call	FileGetPathExtAttributes
		popdw	esdi				;es:di <- TransMapHeader

	; For DBCS, convert name to DBCS, then load into TransMapHeader.

		lea	di, es:[di].TMH_dosName		;es:di <- DBCS buffer to fill
		segmov	ds, ss, ax
		lea	si, ss:[dosName]		;ds:si <- filled SBCS buffer
		LocalCopySBCSToDBCS
else
	; For SBCS, just load DOS filename into TransMapHeader.

		mov	ax, FEA_DOS_NAME
		lea	di, es:[di].TMH_dosName		;es:di <- buffer to fill
		mov	cx, DOS_DOT_FILE_NAME_SIZE
		call	FileGetPathExtAttributes
endif

	; Indicate error code.

		mov	ax, EV_GET_DOS_NAME

		.leave
		ret

CopyFileNameInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load tables from geode header into memory blocks.

CALLED BY:	(EXTERNAL) ReadGeodeFiles, CopyHeaders

PASS:		ss:bp	- TranslationFileFrame
		ax	- number of resources
		bx	- imported library count
		cx	- exported entry count

RETURN:		carry set if error 
		ax - error value
		
DESTROYED:	nothing, but ds is updated

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadTables		proc	far
		uses	bx,cx,dx
		.enter

		push	ds:[LMBH_handle]

EC <		cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG >
EC <		ERROR_NE  BAD_TRANSLATION_FILE_FRAME			>

EC <		tst	ax						>
EC <		ERROR_Z	NO_RESOURCES					>

		segmov	es, ss:[bp].TFF_handles
EC<		cmp	es:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG	>
EC<		ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT			>

	; Calculate size of imported library table.

		push	ax, cx			;save #res, #exports
		mov	ax, bx			;ax <- # imported libraries
		mov	bx, es:[DHS_geode]	;^hbx = geode file handle	
		mov	cx, size ImportedLibraryEntry
		clr	dx
		mul	cx			;ax <- # bytes to read
EC <		tst	dx						>
EC <		ERROR_NZ BLOCK_SIZE_TOO_LARGE				>

	; Calculate location of the imported library table.  Start at the
	; end of the geode header (which is *not* size GeodeFileHeader, as
	; that includes variables from the end of GeodeHeader that are not
	; in the file).

		mov	dx, offset GFH_coreBlock + offset GH_geoHandle
		clr	cx			;cx:dx <- pos of library table

	; Read in import table (if it exists).

		tst	ax
		jz	noImports
		call	FilePosAndRead			
		mov	es:[DHS_importTable], bx
		jc	errorPop2
	
	; Calculate position of export table.

		clr	bx			;bx:ax <- size of import table
		adddw	cxdx, bxax		;cx:dx <- pos of export table

noImports:

	; Calculate size of export table.

		pop	ax			;ax <- # of exported entries
		tst	ax
		jz	noExports
		push	dx
		mov	bx, 4			;size of an export entry
		clr	dx
		mul	bx			;ax <- size of export table
EC <		tst	dx						>
EC <		ERROR_NZ BLOCK_SIZE_TOO_LARGE				>

	; Read in export table.

		mov	bx, es:[DHS_geode]	;^hbx = geode file handle
		pop	dx
		call	FilePosAndRead			
		mov	es:[DHS_exportTable], bx
		jc	errorPop1

noExports:

	; Calculate position of resource table.

		clr	bx		;bx:ax <- size of export table
		adddw	cxdx, bxax	;cx:dx <- pos of resource table

	; Calculate size of resource table.

	 	pop	ax			;ax <- # resources
		push	dx
		mov	bx, 10			;# bytes in resource tables
		clr	dx
		mul	bx			;ax <- size of table entries
EC <		tst	dx						>
EC <		ERROR_NZ BLOCK_SIZE_TOO_LARGE				>

	; Read in resource table.

		pop	dx
		mov	bx, es:[DHS_geode]	;^hbx = geode file handle
		call	FilePosAndRead			
		mov	es:[DHS_resourceTable], bx

		pop	bx
		call	MemDerefDS		;*ds:si <- document

done:
		.leave
		ret

errorPop2:
		pop	bx			;do one pop here
errorPop1:
		pop	bx			;and one pop here
		cmp	ax, EV_FILE_READ
		jne	done
		
		pop	bx
		call	MemDerefDS		;*ds:si <- document
		call	SourceGeodeFileError
		jmp	done

LoadTables		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FilePosAndRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read some bytes from the geode file into a memory block.

CALLED BY:	LoadTables

PASS:		ax	- number of bytes to read
		^hbx	- geode file handle
		cx:dx	- file position 

RETURN:		bx	- handle of block containing table
		ax	- #bytes read
		carry set if error
			ax - ErrorValue

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
should this routine deref ds's handle, instead of pushing it?
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FilePosAndRead		proc	far
	uses	cx, dx, si, ds
	.enter

	tst	ax
	jz	error				;if size is 0, exit now

	; cx:dx is passed offset to position file
	; returns dx:ax as new file position
	push	ax
	mov	al, FILE_POS_START		
	call	FilePos
	pop	ax				;ax <- # bytes to read

	push	ax, bx				;save size, file handle
	mov	dx, ax				;dx <- size to allocate
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			;bx <- handle, ax <- segment
	mov	si, bx				;si <- block handle
	pop	cx, bx				;cx <- # bytes, ^hbx <- file
	mov	ds, ax			
	mov	ax, EV_MEMALLOC
	jc	done

	clr	dx				;ds:dx <- buffer to read into
	clr	al				;return errors
	call	FileRead
	mov	ax, cx
	mov	bx, si				;^hbx <- block handle
	jc	fileReadError
	call	MemUnlock			;unlock the new block

done:	
	.leave
	ret

fileReadError:
	call	MemFree	
	clr	bx
	mov	ax, EV_FILE_READ
error:
	stc
	jmp	done

FilePosAndRead		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseGeodeAndFreeTables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the geode file and free its associated tables.

CALLED BY:	INTERNAL (ReadeGeodeFile, CloseFilesAndFreeBlocks)

PASS:		ss:bp	- TranslationFileFrame
		*ds:si	- document

RETURN:		nothing (flags preserved)

DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseGeodeAndFreeTables		proc	far

EC <	call	AssertIsResEditDocument				>
	pushf

	DerefDoc			; ds:di <- document instance data
	clr	ds:[di].REDI_handles

EC<	cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG	>
EC<	ERROR_NE  BAD_TRANSLATION_FILE_FRAME				>

	tst	ss:[bp].TFF_handles
	jz	done
	segmov	es, ss:[bp].TFF_handles
EC<	cmp	es:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG	>
EC<	ERROR_NE  BAD_DOCUMENT_HANDLES_STRUCT				>

	; Free the geode's tables first
	;
	mov	bx, es:[DHS_importTable]
	tst	bx
	jz	noImports
	call	MemFree

noImports:
	mov	bx, es:[DHS_exportTable]
	tst	bx
	jz	noExports
	call	MemFree

noExports:
	mov	bx, es:[DHS_resourceTable]
	tst	bx
	jz	noTable
	call	MemFree

noTable:
	; Now close the geode.
	;
	mov	bx, es:[DHS_geode]
	tst	bx
	jz	noGeode
	mov	al, FILE_NO_ERRORS
	call	FileClose

noGeode:
	; Free any blocks still in the ResourceHandleTable
	;
	mov	cx, RESOURCE_TABLE_SIZE
	lea	di, es:[DHS_resourceHandleTable]

freeLoop:
	mov	bx, es:[di].RHT_handle
	tst	bx
	jz	continue
	andnf	bx, 0xfffe
	call	MemFree
	clr	es:[di].RHT_handle
continue:
	add	di, size ResourceHandleTable
	loop	freeLoop

	; And free the DocumentHandleStruct itself.
	;
	mov	bx, es:[DHS_handle]
	call	MemFree
	clr	ss:[bp].TFF_handles
done:
	popf
	ret
CloseGeodeAndFreeTables		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDOpenLocalizationFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens a document's localization file.

CALLED BY:	MSG_RESEDIT_DOCUMENT_OPEN_LOCALIZATION_FILE

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		if error,
			carry set
			ax = EV_NO_ERROR
		else
			carry clear
			ax = handle to the localization file

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/19/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDOpenLocalizationFile	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_OPEN_LOCALIZATION_FILE
vmFileName	local	DosDotFileName
		uses	cx, dx, ds, si
		.enter

	; Push current directory.

		call	FilePushDir

	; Go to source geode directory (localization file should be there).

		mov	ax, MSG_RESEDIT_DOCUMENT_CHANGE_TO_FULL_SOURCE_PATH
		call	ObjCallInstanceNoLock	
		jc	donePopDir

	; Lock TransMapHeader.

		mov	ax, MSG_RESEDIT_DOCUMENT_LOCK_MAP
		call	ObjCallInstanceNoLock
		movdw	esdi, cxdx		; es:di = TransMapHeader

	; Construct localization filename.

		push	ds, si
		segmov	ds, ss, si
		lea	si, ss:[vmFileName]
		call	BuildLocalizationFileName
		pop	ds, si

	; Make sure it is a VM file.

		push	ds
		mov	ax, GFT_VM
		segmov	ds, ss, dx
		lea	dx, ss:[vmFileName]	; es:dx <- file name
		call	AssertFileType
		pop	ds
		jnc	openFile		; No error.
		cmp	ax, EV_NO_ERROR
		jne	tryLowerCase		; File open error occured.
		mov	ax, EV_EXPECTED_LOCALIZATION_FILE
		jmp	error			; Was not a VM file.

openFile:

	; Open the file.

		push	ds
		segmov	ds, ss, ax
		mov	ah, VMO_OPEN
		mov	al, mask VMAF_FORCE_READ_ONLY or \
				mask VMAF_FORCE_DENY_WRITE
		clr	cx
		call	VMOpen			; ^hbx <- localization file
		pop	ds
		mov	ax, EV_FILE_OPEN
		jc	error

	; Check file for validity, correct version, protocols, etc.

		call	AssertLocalization	; If error, ax = ErrorValue
		jc	assertError
		mov	ax, bx			; File handle.
		clc

	; If in batch mode, report update attempt and name of localization
	; file.

		pushf
		call	IsBatchMode
		jnc	afterBatchReport
		push	ax, bp
		push	bp
		mov	ax, MSG_VIS_TEXT_APPEND_OPTR
		GetResourceHandleNS	BatchStringsUI, dx
		mov	bp, offset ResEditBatchUpdateText
		call	BatchReportTab
		call	BatchReport
		pop	bp
		mov	ax, MSG_VIS_TEXT_APPEND
		mov	dx, ss
		lea	bp, ss:[vmFileName]
		call	BatchReport
		call	BatchReportReturn
		pop	ax, bp

afterBatchReport:
		popf

donePopDir:

	; Clean up.

		call	FilePopDir	; Restore original directory.
		jnc	exit
		mov	ax, EV_NO_ERROR	; Don't report error again.

exit:

	; Unlock TransMapHeader.

		call	DBUnlock

		.leave
		ret					; <--- EXIT HERE

assertError:

	; Close the localization file gracefully.

		push	ax
		mov	al, FILE_NO_ERRORS
		call	VMClose
		pop	ax
		stc

error:

	; Display error message.

		call	LocalizationFileError
		stc
		jmp	donePopDir

tryLowerCase:

	; Change the name to lowercase.

		push	ds, si
		clr	cx
		segmov	ds, ss, dx
		lea	si, ss:[vmFileName]	; es:dx <- file name
		call	LocalDowncaseString

	; Make sure it is a VM file.

		mov	ax, GFT_VM
		lea	dx, ss:[vmFileName]	; ds:dx <- file name
		call	AssertFileType
		pop	ds, si
		jnc	openFile		; No error.
		cmp	ax, EV_NO_ERROR
		jne	error			; File open error occured.
		mov	ax, EV_EXPECTED_LOCALIZATION_FILE
		jmp	error			; Was not a VM file.

REDOpenLocalizationFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildLocalizationFileName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the localization filename and write it to the
		specified buffer.

CALLED BY:	REDOpenLocalizationFile

PASS:		es:di	= TransMapHeader
		ds:si	= buffer for filename

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildLocalizationFileName	proc	far
		uses	ax,cx,si,di
		.enter

	; Get the geode's DOS name.

		push	di			; Offset of TransMapHeader.
		lea	di, es:[di].TMH_dosName	; es:di <- geode's dos name

	; Copy the DOS name up to the period.

		mov	cx, size DosDotFileName
DBCS <		shr	cx, 1			; convert size to length>
SBCS <		clr	ah						>	

copyLoop:
		LocalGetChar	ax, esdi
		LocalCmpChar	ax, C_PERIOD
		je		foundPeriod
		LocalPutChar	dssi, ax
		loop		copyLoop

	; We filled up the buffer.  Back up for ".vm".

SBCS <		sub	si, 3					 	>
DBCS <		sub	si, 6					 	>

foundPeriod:

	; Check if we are a non-EC geode by looking at the longname.  If so,
	; we can skip all this checking for EC strings.  We shouldn't
	; actually have to do this, but should solve the problem of the
	; misnamed "homescre.geo", which the logic below will rightly assume
	; is an EC geode.  Sigh.

		pop		di		; Offset of TransMapHeader.
		lea		di, es:[di].TMH_sourceName
		LocalGetChar 	ax, esdi	
SBCS <		cmp		al, 'E'					>
DBCS <		cmp		ax, C_LATIN_CAPITAL_LETTER_E		>
		jne		storePeriod
		LocalGetChar	ax, esdi		
SBCS <		cmp		al, 'C'					>
DBCS <		cmp		ax, C_LATIN_CAPITAL_LETTER_C		>
		jne		storePeriod
		LocalGetChar	ax, esdi		
SBCS <		cmp		al, ' '					>
DBCS <		cmp		ax, C_SPACE				>
		jne		storePeriod

	; Now delete any trailing 'EC' or 'E', since there is only one .vm
	; file for both the EC and non-EC case.

	; If eight characters preceed the period, the last letter could be
	; a single 'E', indicating an EC geode.

		cmp		cx, (size DosDotFileName-8)
		jg		rootNameLessThan8
		LocalPrevChar	dssi	
		LocalGetChar	ax, dssi, NO_ADVANCE
		LocalCmpChar	ax, 'E'	
		jne		checkForTrailingEC

	; Is 7 chars plus 'E'.  Put the period on the 'E'.

		jmp		storePeriod

rootNameLessThan8:

	; Check for a trailing 'EC'.

		LocalPrevChar	dssi
		LocalGetChar	ax, dssi, NO_ADVANCE

checkForTrailingEC:

		LocalCmpChar	ax, 'C'
		jne		forwardOne
		LocalPrevChar	dssi
		LocalGetChar	ax, dssi, NO_ADVANCE
		LocalCmpChar	ax, 'E'
		je		storePeriod	; Ends with "EC"
		LocalNextChar	dssi
forwardOne:	
		LocalNextChar	dssi
storePeriod:	

	; Store the .VM extension.

		LocalLoadChar	ax, C_PERIOD
		LocalPutChar	dssi, ax	; store the dot
		LocalLoadChar	ax, 'V'	
		LocalPutChar	dssi, ax
		LocalLoadChar	ax, 'M'	
		LocalPutChar	dssi, ax
		LocalLoadChar	ax, C_NULL	; null terminate it
		LocalPutChar	dssi, ax

		.leave
		ret
BuildLocalizationFileName	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the document's TransMapHeader.

CALLED BY:	MSG_RESEDIT_DOCUMENT_LOCK_MAP

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		cx:dx	= TransMapHeader
		ax	= handle to TransMapHeader

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	7/21/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDLockMap	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_LOCK_MAP
		uses	es,si 
		.enter

EC <		call	AssertIsResEditDocument				>

	; Get document file handle.

		mov	ax, MSG_GEN_DOCUMENT_GET_FILE_HANDLE
		call	ObjCallInstanceNoLock
		mov	bx, ax

	; Lock the TransMapHeader

		call	DBLockMap
		mov	ax, di
		mov	cx, es
		mov	dx, es:[di]

		.leave
		ret
REDLockMap	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OpenSourceFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the file, whose path and name
		are passed in the TransMapHeader.

CALLED BY:

PASS:		es:di 	- TransMapHeader

RETURN: 	^hbx 	- file handle
		cx	- GeosFileType
		Carry set if unsuccessful
			ax - EV_NO_ERROR 
DESTROYED:     	nothing

PSEUDO CODE/STRATEGY:
	Save the current directory
	Switch to the specific directory
	Try to open the file
	Restore the current directory
	Handle error messages here

REVISION HISTORY:
	Name    Date            Description
	----    ----            -----------
	cassie	10/27/92	Initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OpenSourceFile	 proc	far
fileType	local	GeosFileType
	uses	dx,si,di,ds,es
	.enter

	segmov	ds, es, ax			; ds:di <- TransMapHeader

	call	FilePushDir			; save current directory

	; go to the top-level source dir
	;
	mov	dx, offset sourceKey
	call	SetDirectoryFromInitFile
	jc	done

	; change to the file's directory
	;	
	clr	bx
	lea	dx, ds:[di].TMH_relativePath	; ds:dx <- pathname buffer
	call	FileSetCurrentPath	
	jc	error

	; get the file type of the file that was selected
	;
	push	di
	lea	dx, ds:[di].TMH_sourceName	;ds:dx <- file name
	segmov	es, ss, ax
	lea	di, ss:[fileType]
	mov	ax, FEA_FILE_TYPE
	mov	cx, size fileType
	call	FileGetPathExtAttributes
	pop	di
	jc	error

	; try to open the file
	;
	cmp	ss:[fileType], GFT_VM
	je	vmFile
EC <	cmp	ss:[fileType], GFT_EXECUTABLE				>
EC <	ERROR_NE	RESEDIT_EXPECT_EXECUTABLE_FILE			>

	mov	al, FILE_DENY_W or FILE_ACCESS_R
	call	FileOpen			; ^hax <- executable geode
	mov	bx, ax
	jc	error
	jmp	saveHandle

vmFile:	
	mov	ah, VMO_OPEN
	mov	al, mask VMAF_FORCE_READ_ONLY or mask VMAF_FORCE_DENY_WRITE
	clr	cx
	call	VMOpen				; ^hbx <- localization file
	jc	error

saveHandle:
	mov	cx, ss:[fileType]
	clc
done:
	call	FilePopDir			; restore current directory
	.leave
	ret

error:
	mov	ax, EV_FILE_OPEN
	mov	si, di				;ds:si <- transMapHeader


	call	SourceGeodeFileError
	mov	cx, -1				;null file type
	jmp	done

OpenSourceFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertLocalization
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the source file is a localization file

CALLED BY:	InitializeDocumentFile

PASS:		^hbx	- source file handle

RETURN:		carry set if not a localization file
			ax - ErrorValue
DESTROYED:	nothing?

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	11/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertLocalization		proc	near
fileToken	local	GeodeToken
protocol	local	ProtocolNumber
	uses	cx,si,di,ds,es
	.enter

	; get the file type of the file that was selected
	;
	segmov	es, ss, ax
	mov	ax, FEA_TOKEN
	mov	cx, size GeodeToken
	lea	di, ss:[fileToken]
	call	FileGetHandleExtAttributes
	mov	ax, EV_GET_EXT_ATTRS
	jc	error

	; Verify that this file has the localization GeodeToken 
	;
	mov	ax, EV_NOT_LOCALIZATION_FILE
	cmp	{word} ss:[fileToken].GT_chars, LOC_TOKEN_1_2
	jne	error
	cmp	{word} ss:[fileToken].GT_chars+2, LOC_TOKEN_3_4
	jne	error

	; check protocols, etc
	;
	mov	ax, FEA_PROTOCOL
	mov	cx, size ProtocolNumber
	lea	di, ss:[protocol]
	call	FileGetHandleExtAttributes
	mov	ax, EV_GET_EXT_ATTRS
	jc	error

	mov	ax, EV_LOCALIZATION_PROTOCOL
	cmp	ss:[protocol].PN_major, LOCALIZE_PROTOCOL_MAJOR
	jne	error
	cmp	ss:[protocol].PN_minor, LOCALIZE_PROTOCOL_MINOR
	jne	error

	clc

done:
	.leave
	ret

error:
	stc
	jmp	done

AssertLocalization		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessGeodeHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy values from the GeodeHeader to the TransMapHeader.

CALLED BY:	ReadGeodeFile

PASS:		^hbx	- source file handle
		si	- VM document file handle
		es:di	- TransMapHeader

RETURN:		ax	- resource count
		bx	- imported library count
		cx	- exported entry count
		carry set if error
			ax - ErrorValue
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	10/27/92	Initial version
	cassie	1/3/94		Check for UI Library

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessGeodeHeader		proc	near
copyright	local	FileCopyrightNotice
efh		local	ExecutableFileHeader
protocol 	local	ProtocolNumber
geodeName	local	GEODE_NAME_SIZE dup(char)
		uses 	dx, ds
		.enter

EC <		call	ECCheckFileHandle				>

	; Position file to the ExecutableFileHeader.
	
		mov	dx, offset GFH_execHeader
		clr	cx
		mov	al, FILE_POS_START
		call	FilePos

	; Read in ExecutableFileHeader.

		segmov	ds, ss, ax
		lea	dx, ss:[efh]
		mov     cx, size ExecutableFileHeader
		clr     al              	        ; we want errors...
		call    FileRead	
		mov	ax, EV_FILE_READ_HEADERS
		LONG jc	error           

	; File is currently positioned at GeodeHeader.  Move to geode name.

		mov	dx, offset GH_geodeName
		clr	cx
		mov	al, FILE_POS_RELATIVE
		call	FilePos

	; Read in geode name.

		lea	dx, ss:[geodeName]
       	 	mov     cx, GEODE_NAME_SIZE
		clr     al              	        ; we want errors...
		call    FileRead	
		mov	ax, EV_FILE_READ_HEADERS
		jc      error           

	; Set TransMapHeader flag if this is UI library.

		call	CheckIfUILibrary

	; Get geode's protocol numbers.

		push	es, di
		segmov	es, ss, ax
		mov	ax, FEA_PROTOCOL
		mov	cx, size ProtocolNumber
		lea	di, ss:[protocol]
		call	FileGetHandleExtAttributes
		pop	es, di
		mov	ax, EV_GET_EXT_ATTRS
		jc	error

	; Save protocol numbers in the TransMapHeader.

		mov	cx, ss:[protocol].PN_major
		mov	es:[di].TMH_version.PN_major, cx
		mov	cx, ss:[protocol].PN_minor
		mov	es:[di].TMH_version.PN_minor, cx

	; Save resource count in the TransMapHeader.

		mov	ax, ss:[efh].EFH_resourceCount
		mov	es:[di].TMH_totalResources, ax

	; Get geode's "copyright" field information
		push	ax
		push	es, di
		segmov	es, ss, ax
		mov	cx, size FileCopyrightNotice
		lea	di, ss:[copyright]
		mov	ax, FEA_NOTICE		
		call	FileGetHandleExtAttributes
		pop	es, di

	; don't error-check here: if we can't get the
	; copyright info for some reason, at least let
	; the user modify the rest of the file.
		jc	markDirty

	; allocate a DB Item for the copyright
	; field and store the information there.
		mov	bx, si
		mov	si, di		; es:si is temporarily our TransMapHeader
		mov	ax, es:[si].TMH_copyrightGroup
		mov	di, es:[si].TMH_copyrightItem
		tst	di
		jnz	doneAlloc	; don't alloc another item if one already exists
		mov	ax, DB_UNGROUPED

		call	DBAlloc		; di <- item handle
					; ax <- group handle

		; store the DB Item Group and Item handles
		mov	es:[si].TMH_copyrightGroup, ax
		mov	es:[si].TMH_copyrightItem, di

doneAlloc:
		push	es
		call	DBLock
		mov	di, es:[di]	; es:di <- destination
		segmov	ds, ss, ax
		push	si
		lea	si, ss:[copyright]	; ds:si <- source
		rep	movsb			; copy. . .
		pop	si
		call	DBDirty
		call	DBUnlock
		pop	es
		mov	di, si		; es:di <- TransMapHeader
		pop	ax		; ax <- resource count

markDirty:

	; Mark the TransMapHeader dirty.

		call	DBDirty

	; Get other counts from the ExecutableFileHeader.

		mov	bx, ss:[efh].EFH_importLibraryCount
		mov	cx, ss:[efh].EFH_exportEntryCount
		clc
error:
		.leave
		ret

ProcessGeodeHeader		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfUILibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if geode being parsed is the UI library.

CALLED BY:	ParseResources
PASS:		es:di - TransMapHeader
		
RETURN:		flag set if ui library
DESTROYED:	ax,cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	1/ 3/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UILibraryPermName	char	'ui      '
CheckIfUILibrary		proc	near
	uses	si,ds
	.enter inherit ProcessGeodeHeader

	pushdw	esdi
	segmov	es, cs, ax
	mov	di, offset UILibraryPermName	; es:di <- longname of ui lib

	segmov	ds, ss, ax
	lea	si, ss:[geodeName]		; ds:si <- geode permanent name

	; compare only up to size of UILibrary string
	;
	mov	cx, size UILibraryPermName
	repe	cmpsb			
	popdw	esdi

	jnz	done				; mismatch - not UI library
	ornf	es:[di].TMH_flags, mask TMHF_UI_LIBRARY

done:
	.leave
	ret
CheckIfUILibrary		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocResourceHandleTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a fixed block on the heap for ResourceHandleTable.

CALLED BY:	EXTERNAL (InitializeDocumentFile, CreateExecutable, 
		DocumentUpdateTranslation)

PASS:		ds:di	- document
RETURN:		es	- segment of DocumentHandleStruct
DESTROYED:	bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocResourceHandleTable		proc	far
		uses	ax,cx,si
		.enter

	; Allocate a block for the new table.

		mov	cl, size ResourceHandleTable
		mov	ax, RESOURCE_TABLE_SIZE
		mul	cl	
		add	ax, size DocumentHandlesStruct	; ax <- size
		mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_FIXED
		call	MemAlloc

	; Store the handle in the block and in the document.

		segmov	es, ax, cx
		mov	es:[DHS_handle], bx
		mov	ds:[di].REDI_handles, bx
EC<		mov	es:[DHS_signature], DOCUMENT_HANDLES_STRUCT_SIG	>

	; Initialize the resource numbers to -1 (indicating not in use).

		mov	cx, RESOURCE_TABLE_SIZE
		lea	si, es:[DHS_resourceHandleTable]
setLoop:
		mov	es:[si].RHT_number, -1
		add	si, size ResourceHandleTable
		loop	setLoop

		.leave
		ret
AllocResourceHandleTable		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDMarkClean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the document clean so that on close the user won't be
		prompted to save/discard changes.  We want the changes
		automatically written out to disk, but not committed, so the
		user can revert the changes.  This is used in batch
		processing.

CALLED BY:	MSG_RESEDIT_DOCUMENT_MARK_CLEAN

PASS:		*ds:si	= ResEditDocumentClass object
		ds:di	= ResEditDocumentClass instance data
		ds:bx	= ResEditDocumentClass object (same as *ds:si)
		es 	= segment of ResEditDocumentClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	8/17/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDMarkClean	method dynamic ResEditDocumentClass, 
					MSG_RESEDIT_DOCUMENT_MARK_CLEAN
		.enter

	; Set it clean

		and 	ds:[di].GDI_attrs, not (mask GDA_DIRTY)

		.leave
		ret
REDMarkClean	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		REDCDisplayDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Only put the New/Open dialog up if we are not in batch mode.

CALLED BY:	MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
PASS:		*ds:si	= ResEditDocumentControlClass object
		ds:di	= ResEditDocumentControlClass instance data
		ds:bx	= ResEditDocumentControlClass object (same as *ds:si)
		es 	= segment of ResEditDocumentControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	pjc	9/ 8/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
REDCDisplayDialog	method dynamic ResEditGenDocumentControlClass, 
					MSG_GEN_DOCUMENT_CONTROL_DISPLAY_DIALOG
		.enter

		push	ds:[LMBH_handle]

	; Is batch mode on?

		call	IsBatchMode
		jc	afterSuperCall

	; Batch mode isn't on.  Process normally.

		mov	di, offset ResEditGenDocumentControlClass
		call	ObjCallSuperNoLock

afterSuperCall:

	; Hack to end batch mode after this message is processed so we don't
	; get nasty side effects.

		call	IsBatchModeCancelled
		jnc	done
		mov	ax, MSG_RESEDIT_APPLICATION_END_BATCH
		GetResourceHandleNS	AppResource, bx
		mov	si, offset ResEditApp
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

	; Get rid of the batch status dialog.

		mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
		mov	cx, IC_DISMISS
		GetResourceHandleNS	FileMenuUI, bx
		mov	si, offset ResEditBatchStatus
		mov	di, mask MF_CALL
		call	ObjMessage

done:
		pop	bx
		call	MemDerefDS
		.leave
		ret
REDCDisplayDialog	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LockTransFileMap_DS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the map block for the translation file whose
		file handle, group and item numbers are stored in TFF.

CALLED BY:	EXTERNAL - utility
PASS:		ss:bp	- TranslationFileFrame
RETURN:		*es:di	- map block, or
		*ds:si	- map block (if LockTransFileMap_DS is called)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cassie	5/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LockTransFileMap_DS		proc	far
	uses	ax,bx,di,es
	.enter
EC<	cmp	ss:[bp].TFF_signature, TRANSLATION_FILE_FRAME_SIG	>
EC<	ERROR_NE  BAD_TRANSLATION_FILE_FRAME			>
	mov	bx, ss:[bp].TFF_transFile
	mov	ax, ss:[bp].TFF_destGroup
	mov	di, ss:[bp].TFF_destItem
	call	DBLock				; *es:di <- map block
	segmov	ds, es
	mov	si, di				; *ds:si <- map block
	.leave
	ret
LockTransFileMap_DS	endp


DocOpenClose ends

