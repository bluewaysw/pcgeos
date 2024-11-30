COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	NTaker
MODULE:		Document
FILE:		documentCode.asm

AUTHOR:		Andrew Wilson, Feb 12, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/92		Initial revision

DESCRIPTION:
	This file contains the file-handling/interface code for the NTaker
	app.

	$Id: documentCode.asm,v 1.1 97/04/04 16:17:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NO_OBJ		equ	-1
DocumentCode	segment	resource

COMMENT @----------------------------------------------------------------------

FUNCTION:	Utilities

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/18/92		Initial version

------------------------------------------------------------------------------@

if	ERROR_CHECK
EnsureNotPenMode	proc	near	
	push	ax
	call	SysGetPenMode
	tst	ax
	ERROR_NZ	IN_PEN_MODE
	pop	ax
	ret
EnsureNotPenMode	endp
ForceRef	EnsureNotPenMode
endif

if	ERROR_CHECK
EnsureIsPenMode	proc	near	
	push	ax
	call	SysGetPenMode
	tst	ax
	ERROR_Z	NOT_IN_PEN_MODE
	pop	ax
	ret
EnsureIsPenMode	endp
endif

NTakerDocDeref_DSDI	proc	near
EC <	push	es							>
EC <	GetResourceSegmentNS	NTakerDocumentClass, es			>

EC <	mov	di, offset NTakerDocumentClass				>
EC <	call	ObjIsObjectInClass					>
EC <	ERROR_NC	ILLEGAL_OBJECT_PASSED_TO_NTAKER_DOC_ROUTINE	>
EC <	pop	es							>

	mov	di, ds:[si]
	add	di, ds:[di].GenDocument_offset
	ret
NTakerDocDeref_DSDI	endp

;---
NTakerDocGetHandleOfDisplayBlock	proc	near	uses	di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	bx, ds:[di].GDI_display
	.leave
	ret
NTakerDocGetHandleOfDisplayBlock	endp

NTakerDocGetFileHandle	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	bx, ds:[di].GDI_fileHandle
	.leave
	ret
NTakerDocGetFileHandle	endp

;---

NTakerDocGetCurFolder	proc	near
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	ax, ds:[di].NDOCI_curFolder.high
	mov	di, ds:[di].NDOCI_curFolder.low
EC <	tstdw	axdi							>
EC <	ERROR_Z	NULL_FOLDER						>
	.leave
	ret
NTakerDocGetCurFolder	endp

;---

NTakerDocGetCurMoveFolder	proc	near
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	ax, ds:[di].NDOCI_curMoveFolder.high
	mov	di, ds:[di].NDOCI_curMoveFolder.low
	tstdw	axdi
	.leave
	ret
NTakerDocGetCurMoveFolder	endp
;---

NTakerDocGetCurMoveFolder_CXDX	proc	near	uses	ax, di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	call	NTakerDocGetCurMoveFolder
	movdw	cxdx, diax
	tstdw	cxdx
	.leave
	ret
NTakerDocGetCurMoveFolder_CXDX	endp

;---
NTakerDocGetSearchBlock	proc	near
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	cx, ds:[di].NDOCI_searchBlock
	tst	cx
	.leave
	ret
NTakerDocGetSearchBlock	endp
;---

NTakerDocGetCurNote	proc	near
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	movdw	axdi, ds:[di].NDOCI_curNote
	tstdw	axdi
	.leave
	ret
NTakerDocGetCurNote	endp

;---

NTakerDocGetCurPage	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	cx, ds:[di].NDOCI_curPage
	.leave
	ret
NTakerDocGetCurPage	endp

;---

NTakerDocSetCurPage	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	ds:[di].NDOCI_curPage, cx
	.leave
	ret
NTakerDocSetCurPage	endp

;---

NTakerDocResetCurPage	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	ds:[di].NDOCI_curPage, 0
	.leave
	ret
NTakerDocResetCurPage	endp

;---

NTakerDocGetInkObj	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	bp, ds:[di].NDOCI_inkObj
	.leave
	ret
NTakerDocGetInkObj	endp

;---

NTakerDocGetTextObj	proc	near	uses di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	bp, ds:[di].NDOCI_textObj
	.leave
	ret
NTakerDocGetTextObj	endp

;---

NTakerDocSetCurFolder	proc	near	uses	cx, di
	class	NTakerDocumentClass
	.enter
EC <	tstdw	axdi							>
EC <	ERROR_Z	NULL_FOLDER						>
	mov	cx, di
	call	NTakerDocDeref_DSDI
	movdw	ds:[di].NDOCI_curFolder, axcx
	call	SendNumTopicsToDisplay
	.leave
	ret
NTakerDocSetCurFolder	endp

;---

NTakerDocSetCurNote	proc	near
	class	NTakerDocumentClass
	.enter
	push	cx
	mov	cx, di
	call	NTakerDocDeref_DSDI
	cmpdw	axcx, ds:[di].NDOCI_curNote
	movdw	ds:[di].NDOCI_curNote, axcx
	pop	cx
	.leave
	ret
NTakerDocSetCurNote	endp

;---

NTakerDocSetCurMoveFolder	proc	near
	class	NTakerDocumentClass
	.enter
	push	cx
	tstdw	axdi
	jz	done
	mov	cx, di
	call	NTakerDocDeref_DSDI
	mov	ds:[di].NDOCI_curMoveFolder.high, ax
	mov	ds:[di].NDOCI_curMoveFolder.low, cx
done:
	pop	cx
	.leave
	ret
NTakerDocSetCurMoveFolder	endp

;---
NTakerDocSetNilNote	proc	near
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	ds:[di].NDOCI_curNote.high, 0
	mov	ds:[di].NDOCI_curNote.low, 0
	.leave
	ret
NTakerDocSetNilNote	endp

;---
NTakerDocSetSearchBlock	proc	near	uses	bx
	class	NTakerDocumentClass
	.enter		
	call	NTakerDocDeref_DSDI

;	Free the old search block, if any

	mov	bx, ds:[di].NDOCI_searchBlock
	tst	bx
	jz	10$
	call	MemFree
10$:
	mov	ds:[di].NDOCI_searchBlock, dx
	.leave
	ret
NTakerDocSetSearchBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendNumTopicsToDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Informs the display of the # subtopics displayed

CALLED BY:	GLOBAL
PASS:		*ds:si - document
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendNumTopicsToDisplay	proc	near	uses	ax, bx, cx, dx, di
	.enter
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	call	InkFolderGetNumChildren		;CX <- # sub topics
	mov	ax, MSG_NTAKER_DISPLAY_SET_NUM_SUB_TOPICS
	call	SendToDisplay
	.leave
	ret
SendNumTopicsToDisplay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPageSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the page size for the current document

CALLED BY:	GLOBAL
PASS:		bx - file handle
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitPageSize	proc	near	uses	si, ds
	localPageSizeReport	local	PageSizeReport 
	.enter
	segmov	ds, ss
	lea	si, localPageSizeReport
	call	SpoolGetDefaultPageSizeInfo
	call	InkSetDocPageInfo
	.leave
	ret
InitPageSize	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerDocumentInitializeDocumentFile --
		MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE
					for NTakerDocumentClass

DESCRIPTION:	Initialize the document file (newly created).

PASS:
	*ds:si - instance data
	es - segment of NTakerDocumentClass

	ax - The message

	cx:dx - optr of document
	bp - file handle

RETURN:
	carry - set if error

DESTROYED:
	bx, cx, dx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

	This message is invoked when a new document has been created and
	the document file needs to be initialized.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
NTakerDocumentInitializeDocumentFile	method dynamic	NTakerDocumentClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	.enter
	mov	bx, ds:[di].GDI_fileHandle
	call	InkDBInit

	call	InitPageSize

	clr	ax
	call	InkSetDocGString

	call	ReadDisplayData
	call	CreateNote
	call	SetNoteType
	call	WriteDisplayData

	clc			;no error
	.leave
	ret

NTakerDocumentInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerDocumentReadCachedDataFromFile --
		MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
					for NTakerDocumentClass

DESCRIPTION:	Read in data to instance data

PASS:
	*ds:si - instance data
	es - segment of NTakerDocumentClass

	ax - The message

RETURN:
	none

DESTROYED:
	bx, cx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

	This message is invoked when a document has been opened/reverted.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version
------------------------------------------------------------------------------@
NTakerDocumentReadCachedDataFromFile	method dynamic	NTakerDocumentClass,
				MSG_GEN_DOCUMENT_READ_CACHED_DATA_FROM_FILE
	call	ReadDisplayData
	mov	cx, TRUE
	call	ResetMonikersAndSelectCurrentNote

	call	GetCurrentViewType
	mov_tr	cx, ax			;CX <- ViewType
	mov	ax, MSG_NTAKER_DOC_SET_VIEW_TYPE
	GOTO	ObjCallInstanceNoLock

NTakerDocumentReadCachedDataFromFile	endm

ReadDisplayData	proc	near
	class	NTakerDocumentClass

	mov	bx, ds:[di].GDI_fileHandle
	call	InkDBGetDisplayInfo

	call	NTakerDocSetCurFolder
	
	movdw	axdi, dxcx
	call	NTakerDocSetCurNote
	mov	cx, bp
	call	NTakerDocSetCurPage
	ret

ReadDisplayData	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerDocumentWriteCachedDataToFile --
		MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE
					for NTakerDocumentClass

DESCRIPTION:	Read in data to instance data

PASS:
	*ds:si - instance data
	es - segment of NTakerDocumentClass

	ax - The message

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

	This message is invoked when a new document has been created and
	the document file needs to be initialized.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
NTakerDocumentWriteCachedDataToFile	method dynamic	NTakerDocumentClass,
				MSG_GEN_DOCUMENT_WRITE_CACHED_DATA_TO_FILE

	jcxz	isAutosave
	call	SaveCurrentNoteIfNeeded
	call	WriteDisplayData
exit:
	ret
isAutosave:
	call	NTakerDocGetHandleOfDisplayBlock
	mov	dx, offset CardTitle
	call	GetTextUserModifiedState	;Z flag set if not dirty
	pushf
	mov	cx, bx
	call	SetTextObjectNotModified
	call	SaveCurrentNoteIfNeeded
	call	WriteDisplayData
	popf
	jz	exit				;Branch if title was not dirty

;	Mark the title (and the document) dirty

	push	si
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardTitle
	mov	ax, MSG_VIS_TEXT_SET_USER_MODIFIED
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	mov	ax, MSG_META_TEXT_USER_MODIFIED
	call	ObjCallInstanceNoLock
	jmp	exit
NTakerDocumentWriteCachedDataToFile	endm

WriteDisplayData	proc	near
	class	NTakerDocumentClass

	call	NTakerDocDeref_DSDI
	mov	bx, ds:[di].GDI_fileHandle
	movdw	dxcx, ds:[di].NDOCI_curNote
	mov	bp, ds:[di].NDOCI_curPage
	mov	ax, ds:[di].NDOCI_curFolder.high
	mov	di, ds:[di].NDOCI_curFolder.low
	call	InkDBSetDisplayInfo
	ret

WriteDisplayData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentAttachUIToDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates Ink/Text objects for display.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	We do this on the ATTACH_UI instead of the CREATE_UI, because the
GenContent/GenDocument will have its Vis data thrown away when it is saved
to state, and the vis linkage will be destroyed, so it is easiest/safest
just to nuke the objects instead of having to deal with removing/adding them
to the vis linkage all the time.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version
	JT	4/7/92		Modified to set vis bounds of ink object
	JT	5/12/92		Break the code to create either InkObject or
				TextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentAttachUIToDocument	method	NTakerDocumentClass,
					MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT
	.enter

	mov	di, offset NTakerDocumentClass
	call	ObjCallSuperNoLock
	call	NTakerDocCreateInkObject
	call	NTakerDocCreateTextObject

	call	NTakerDocGetFileHandle
	call	InkDBGetHeadFolder
	call	InkFolderGetNumChildren		;CX <- # topics
	mov	ax, MSG_NTAKER_DISPLAY_SET_HAS_TOPICS
	call	SendToDisplay
	.leave
	ret
NTakerDocumentAttachUIToDocument	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDocumentWidthAndHeightWithoutMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current width/height of the document.

CALLED BY:	GLOBAL
PASS:		*ds:si - doc object
RETURN:		cx, dx - width, height
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDocumentWidthAndHeightWithoutMargins	proc	near	uses	ds, si
	localPageSizeReport	local	PageSizeReport 
	.enter
	call	NTakerDocGetFileHandle

	segmov	ds, ss
	lea	si, localPageSizeReport
	call	InkGetDocPageInfo
	mov	cx, localPageSizeReport.PSR_width.low
	mov	dx, localPageSizeReport.PSR_height.low
	sub	cx, localPageSizeReport.PSR_margins.PCMP_left
EC <	ERROR_C	INVALID_MARGINS						>
	sub	cx, localPageSizeReport.PSR_margins.PCMP_right
EC <	ERROR_C	INVALID_MARGINS						>
	sub	dx, localPageSizeReport.PSR_margins.PCMP_top
EC <	ERROR_C	INVALID_MARGINS						>
	sub	dx, localPageSizeReport.PSR_margins.PCMP_bottom
EC <	ERROR_C	INVALID_MARGINS						>
	.leave
	ret
GetDocumentWidthAndHeightWithoutMargins	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAndInitializeInkObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the ink object, sets various instance data, 
		the size, and various flags.

CALLED BY:	GLOBAL
PASS:		*ds:si - NTaker doc object
RETURN:		^lcx:dx - ink object
DESTROYED:	ax, bx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAndInitializeInkObject	proc	near	uses	si
	.enter

	push	si
	call	GetDocumentWidthAndHeightWithoutMargins

	call	NTakerDocGetFileHandle
	push	bx
	mov	bx, ds:[LMBH_handle]
	GetResourceSegmentNS	NTakerInkClass, es
	mov	di, offset NTakerInkClass
	call	ObjInstantiate
	pop	bx			;BX <- file handle

;	Set the vis bounds of the ink object

	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

	call	InkGetDocGString	;ax = gstring of background type
	mov_tr	cx, ax			;cx = gstring of background type
	cmp	cx, IBT_CUSTOM_BACKGROUND
	jne	common
	call	GetCustomGStringHandle	;ax = Custom GString
	mov_tr	dx, ax			;dx = Custom GString
common:

	mov	ax, MSG_NTAKER_INK_SET_BACKGROUND
	call	ObjCallInstanceNoLock

;	Tell the ink object that it is the only child of the content, so it
;	can perform its magic optimizations.

	mov	ax, MSG_INK_SET_FLAGS

	mov	cx, mask IF_HAS_UNDO or mask IF_ONLY_CHILD_OF_CONTENT or mask IF_CONTROLLED
	clr	dx
	call	ObjCallInstanceNoLock

;	Set the dirty AD to be our document object

	pop	dx			
	mov	cx, ds:[LMBH_handle]	;^lCX:DX <- Document object

	mov	ax, MSG_INK_SET_DIRTY_AD
	mov	bp, MSG_META_TEXT_USER_MODIFIED
	call	ObjCallInstanceNoLock

	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	.leave
	ret
CreateAndInitializeInkObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocCreateInkObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Create the Ink Object
CALLED BY:	NTakerDocumentAttachUIToDocument
PASS:		BX - database file handle
		*ds:si - document object
RETURN:		nothing
DESTROYED:	ax,cx,dx,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocCreateInkObject	proc	near
	class	NTakerDocumentClass

	.enter
	call	CreateAndInitializeInkObject

;	Add the ink object to ourselves

	call	NTakerDocDeref_DSDI
	mov	ds:[di].NDOCI_inkObj, dx

	.leave
	ret
NTakerDocCreateInkObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateAndInitializeTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates and initializes a text object

CALLED BY:	GLOBAL
PASS:		*ds:si - doc object
RETURN:		^lcx:dx - text object
DESTROYED:	ax, bx, di, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/27/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateAndInitializeTextObject	proc	near	uses	si
	.enter

	push	si
	GetResourceSegmentNS	NTakerTextClass, es
	mov	di, offset NTakerTextClass
	mov	bx, ds:[LMBH_handle]
	call	ObjInstantiate

	mov	ax, MSG_VIS_TEXT_SET_FEATURES
	mov	cx, mask VTF_ALLOW_UNDO or mask VTF_ALLOW_SMART_QUOTES
	clr	dx
	call	ObjCallInstanceNoLock

	mov	ax, MSG_VIS_SET_GEO_ATTRS
	mov	cx, mask VGA_ALWAYS_RECALC_SIZE
	call	ObjCallInstanceNoLock

;	mov	ax, MSG_VIS_TEXT_SET_FILTER
;	mov	cl, mask VTF_NO_TABS
;	call	ObjCallInstanceNoLock

;	Set the dirty AD to be ourselves

	mov	cx, ds:[LMBH_handle]	;^lCX:DX <- Document object
	pop	dx

	mov	ax, MSG_VIS_TEXT_SET_OUTPUT
	call	ObjCallInstanceNoLock

;	Set the maximum length of the text object

	mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
	mov	cx, TEXT_MAX_LENGTH
	call	ObjCallInstanceNoLock
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	.leave
	ret
CreateAndInitializeTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocCreateTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Create the Text Object

CALLED BY:	NTakerDocumentAttachUIToDocument
PASS:		BX - database file handle
RETURN:		nothing
DESTROYED:	ax,cx,dx,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocCreateTextObject	proc	near
	class	NTakerDocumentClass
	.enter

	call	CreateAndInitializeTextObject

;	Add the text object to ourselves

	call	NTakerDocDeref_DSDI
	mov	ds:[di].NDOCI_textObj, dx

	.leave
	ret
NTakerDocCreateTextObject	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Call_ChangeDocumentSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set up parameters to pass in to ChangeDocumentSize and 
		call it
CALLED BY:	LoadCurrentNote
PASS:		*ds:bp	= optr of the vis object
		*ds:si  = document object
		cl	= note type
		bx	= DB file handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Call_ChangeDocumentSize	proc	near	uses	cx, dx, bp, di
	.enter

	call	GetDocumentWidthAndHeightWithoutMargins
	xchg	bp, si
	call	ChangeDocumentSize
	xchg	bp, si
	.leave
	ret
Call_ChangeDocumentSize	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeDocumentSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Change the size of document object and ink or text object
		on the screen
CALLED BY:	GLOBAL
PASS:		*ds:si	= optr of the ink object
		cx 	= new width of the document
		dx	= new height of the document
		*ds:bp  = document object
RETURN:		nothing
DESTROYED:	cx, dx, bp, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 6/92		Initial version
	JT	5/20/92		Modified to work with geometry manager for
				document object with two children
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeDocumentSize	proc	near	uses	ax, bx, si
	.enter

;	Set the size of the ink/text object

	push	bp
	;Set the top, bottom, left, right margins to be 1/4"(18 points) each
	mov	ax, MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock
	pop	si

;	Mark the geometry of the document object as invalid

	mov	ax, MSG_VIS_MARK_INVALID
	mov	cx, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjCallInstanceNoLock
	.leave
	ret
ChangeDocumentSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentDetachUIFromDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nukes all created objects

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	di, ax, dx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/92		Initial version
	JT	5/12/92		Modified to destroy text object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentDetachUIFromDocument	method	NTakerDocumentClass,
				MSG_GEN_DOCUMENT_DETACH_UI_FROM_DOCUMENT
	.enter
	mov	di, offset NTakerDocumentClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_DESTROY
	mov	dl, VUM_NOW
	call	CallTextObject

	call	NTakerDocDeref_DSDI					
	mov	ds:[di].NDOCI_textObj, NO_OBJ				

	mov	ax, MSG_VIS_DESTROY
	mov	dl, VUM_NOW
	call	CallInkObject

	call	NTakerDocDeref_DSDI
	mov	ds:[di].NDOCI_inkObj, NO_OBJ

	clr	ds:[di].NDOCI_curObj

	.leave
	ret
NTakerDocumentDetachUIFromDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallInkObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a method to the ink object

CALLED BY:	GLOBAL
PASS:		*ds:si - document object
		ax - message
		cx, dx, bp - message params

RETURN:		ax, cx, dx, bp - method return values
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallInkObject	proc	near	uses	si, di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	si, ds:[di].NDOCI_inkObj
	call	ObjCallInstanceNoLock
	.leave
	ret
CallInkObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a method to the text object

CALLED BY:	GLOBAL
PASS:		*ds:si - document object
		ax - message
		cx, dx, bp - message params

RETURN:		ax, cx, dx, bp - method return values
DESTROYED:	bx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Copy from CallInkObject

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallTextObject	proc	near	uses	si
	class	NTakerDocumentClass
	.enter
	call	NTakerDocDeref_DSDI
	mov	si, ds:[di].NDOCI_textObj
	call	ObjCallInstanceNoLock
	.leave
	ret
CallTextObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCurrentViewType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current selection of the ViewTypeList

CALLED BY:	GLOBAL
PASS:		ds - obj block
RETURN:		ax - ViewType
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCurrentViewType	proc	near	uses	bx, cx, dx, bp, si, di
	.enter
	GetResourceHandleNS ViewTypeList, bx
	mov	si, offset ViewTypeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;ax = selection
	.leave
	ret
GetCurrentViewType	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerDocumentNewNote -- MSG_NTAKER_DOC_NEW_NOTE
						for NTakerDocumentClass

DESCRIPTION:	Create a new note

PASS:
	*ds:si - instance data
	es - segment of NTakerDocumentClass

	ax - The message

RETURN:

DESTROYED:
	ax, bx, cx, dx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/18/92		Initial version
	JT	5/12/92		Modified to set the note type - ink or text
------------------------------------------------------------------------------@
NTakerDocumentNewNote	method dynamic	NTakerDocumentClass,
						MSG_NTAKER_DOC_NEW_NOTE

	; first save the current note (if needed)

	call	SaveCurrentNoteIfNeeded

	call	CreateNote
	call	SetNoteType

	mov	cx, TRUE
	call	ResetMonikersAndSelectCurrentNote

;	If the user is in the "list" view, and he creates a card, then
;	change to the "CARD" view.

	call	GetCurrentViewType

	cmp	ax, VT_LIST
	jnz	exit

	mov	ax, MSG_NTAKER_DOC_EDIT_SELECTED_CARD
	call	ObjCallInstanceNoLock
exit:
	ret

NTakerDocumentNewNote	endm

CreateNote	proc	near
	class	NTakerDocumentClass

	call	NTakerDocDeref_DSDI
	mov	bx, ds:[di].GDI_fileHandle
	mov	ax, ds:[di].NDOCI_curFolder.high
	mov	di, ds:[di].NDOCI_curFolder.low
	call	InkNoteCreate			;axdi = note note

	clr	cx
	call	InkNoteCreatePage		;cx = first page (0)
	mov	dx, di				;axdx = note
	call	NTakerDocDeref_DSDI
	movdw	ds:[di].NDOCI_curNote, axdx
	mov	ds:[di].NDOCI_curPage, cx

	ret

CreateNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNoteType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set the type of note - ink or text
CALLED BY:	NTakerDocumentNewNote
PASS:		*ds:si - document object
RETURN:		nothing
DESTROYED:	ax, bx, cx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNoteType	proc	near	uses	si,di
	class	NTakerDocumentClass
	.enter

	push	si, di
	GetResourceHandleNS CardTypeList, bx
	mov	si, offset CardTypeList
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		;ax = selection
	pop	si, di

	xchg	cx, ax
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurNote
	call	InkNoteSetNoteType

	.leave
	ret
SetNoteType	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableTextDisableInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the text and ink objects.

CALLED BY:	LoadCurrentNote
PASS:		*ds:si - doc object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableTextDisableInk	proc	near
	.enter
	;disable text object
	mov	ax, MSG_VIS_SET_ATTRS
	mov	ch, mask VA_DRAWABLE or mask VA_DETECTABLE
	clr	cl
	mov	dl, VUM_NOW
	call	CallTextObject

	;disable ink object
	mov	ax, MSG_VIS_SET_ATTRS
	mov	ch, mask VA_DRAWABLE or mask VA_DETECTABLE
	clr	cl
	mov	dl, VUM_NOW
	call	CallInkObject

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	CallInkObject

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	CallTextObject
	.leave
	ret
DisableTextDisableInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableTextDisableInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Visually diable ink object and enable text object
CALLED BY:	LoadCurrentNote
PASS:		*ds:si - document object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableTextDisableInk	proc	near	uses	ax, cx, dx, bp, di
	.enter

	call	NTakerDocGetTextObj
	call	DisplayObject

;	Make the view not-horizontally-scrollable, and grab the focus
;	for the text object.

	mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	mov	dx, mask GVDA_TAIL_ORIENTED
	mov	cx, mask GVDA_DONT_DISPLAY_SCROLLBAR or (mask GVDA_SCROLLABLE) shl 8
	mov	bp, VUM_NOW
	call	SendToView

;	Tell the view that we want ink with standard override

	mov	ax, MSG_GEN_VIEW_RESET_EXTENDED_INK_TYPE
	call	SendToView

	mov	ax, MSG_GEN_VIEW_SET_INK_TYPE
	mov	cl, GVIT_INK_WITH_STANDARD_OVERRIDE
	call	SendToView

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	CallTextObject

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	CallTextObject

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	SendToView

	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	SendToDisplayGroup
	.leave
	ret
EnableTextDisableInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableTextEnableInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Visually diable text object and enable ink object
CALLED BY:	LoadCurrentNote
PASS:		*ds:si - document object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableTextEnableInk	proc	near	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	mov	dx, mask GVDA_TAIL_ORIENTED shl 8
	mov	cx, mask GVDA_SCROLLABLE or (mask GVDA_DONT_DISPLAY_SCROLLBAR) shl 8
	mov	bp, VUM_NOW
	call	SendToView

	; if trying to set the detectable bit
	mov	ax, MSG_GEN_VIEW_SET_INK_TYPE
	mov	cl, GVIT_PRESSES_ARE_INK
	call	SendToView

	call	NTakerDocGetInkObj
	call	DisplayObject

;
;	Make the view horizontally scrollable
;

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	CallInkObject

	.leave
	ret
DisableTextEnableInk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the current object

CALLED BY:	GLOBAL
PASS:		*ds:si - Doc object
		*ds:bp - object to display
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayObject	proc	near	uses	di
	class	NTakerDocumentClass
	.enter

	call	NTakerDocDeref_DSDI
	cmp	bp, ds:[di].NDOCI_curObj
	je	grabTarget

	tst	ds:[di].NDOCI_curObj
	jz	addNewObj

;	Remove the old object that used to be under the tree

	push	si, bp
	mov	si, ds:[di].NDOCI_curObj
	mov	ax, MSG_VIS_REMOVE
	mov	dl, VUM_MANUAL		;Update comes below
	call	ObjCallInstanceNoLock
	pop	si, bp
	call	NTakerDocDeref_DSDI
addNewObj:
;
;	Add the new object to the content, make it visible, and mark the
;	geometry invalid.
;
	push	si, bp
	mov	dx, bp
	mov	ds:[di].NDOCI_curObj, dx
	mov	cx, ds:[LMBH_handle]		;^lCX:DX <- obj to add
	mov	ax, MSG_VIS_ADD_CHILD
	mov	bp, CCO_FIRST shl offset CCF_REFERENCE
	call	ObjCallInstanceNoLock


	mov	si, dx				;*DS:SI <- obj just added
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid
	pop	si, bp

grabTarget:

;	Make the object drawable, etc.

	push	si
	mov	si, bp
	mov	ax, MSG_VIS_SET_ATTRS
	mov	cl, mask VA_DRAWABLE or mask VA_DETECTABLE
	clr	ch
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
	pop	si

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	SendToView

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	SendToDisplayGroup

	.leave
	ret
DisplayObject	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearInkObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine clears the ink object out without setting the
		document dirty.

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerDocument object
RETURN:		nada
DESTROYED:	ax, cx, bx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearInkObject	proc	near
	.enter

;	Clear out the ink data, and mark the object as clean.

	mov	dx, size InkDBFrame
	sub	sp, dx
	mov	bp, sp
	clr	ss:[bp].IDBF_VMFile
	clrdw	ss:[bp].IDBF_DBGroupAndItem
	mov	ax, MSG_INK_LOAD_FROM_DB_ITEM
	call	CallInkObject
	add	sp, size InkDBFrame
	.leave
	ret
ClearInkObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine clears the passed text object without having
		the dirty AD sent out.

CALLED BY:	GLOBAL
PASS:		^lBX:SI <- text object
RETURN:		nada
DESTROYED:	ax, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearTextObject	proc	near	
	.enter

	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
ClearTextObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadNoteData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the data into the current note object, depending upon
		the type of data involved

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerDocument object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadNoteData	proc	near	
	.enter
	push	si
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurNote
	call	InkNoteGetNoteType
	clr	ch
	push	cx				;cx - note type
.assert	NT_INK	eq	0
	jcxz	loadInkNote
	
	clr	cx				;Display the first (only) page
	call	NTakerDocSetCurPage
	call	NTakerDocGetTextObj
	mov	dx, ds:[LMBH_handle]		;^lDX:BP <- text obj
	pop	si				;si - note type
	call	InkNoteLoadPage

	pop	si				;offset of NTakerDocumentClass
	call	EnableTextDisableInk
;
;	Only ink cards can have multiple pages, so since we are loading
;	a text note, just disable the page control
;
	call	DisablePageGadgetry

	jmp	exit

loadInkNote:
	call	NTakerDocGetInkObj
	mov	dx, ds:[LMBH_handle]		;^lDX:BP <- this object	
;	call	Call_ChangeDocumentSize
	call	NTakerDocGetCurPage
	pop	si				;si - note type
	call	InkNoteLoadPage
	pop	si				;offset of NTakerDocumentClass
	call	DisableTextEnableInk

	;update the current page display

	push	ax
	call	SysGetPenMode		;Don't update page display if not in
	tst	ax			; pen mode
	pop	ax
	jz	exit
	push	cx			;Save current page
	call	InkNoteGetPages		; pass: ax, di -- note
					;       bx -- file handle
					; return: ax,di -- DB item
					; containing chunk array of pages
	call	InkNoteGetNumPages	; cx = total number of pages
	pop	ax
	inc	ax
	call	UpdateNumberPages
exit:
	.leave
	ret
LoadNoteData	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	LoadCurrentNote

DESCRIPTION:	Load the current note

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

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
	Tony	2/18/92		Initial version
	Julie	3/30/92		Modified to fix a bug while loading the first
				page of the note
	Julie	5/12/92		Modified to load either ink or text object
------------------------------------------------------------------------------@
LoadCurrentNote	proc	near	uses	si
	class	NTakerDocumentClass
	.enter

	mov	ax, MSG_GEN_PROCESS_UNDO_IGNORE_ACTIONS
	call	GeodeGetProcessHandle
	mov	cx, TRUE			;Flush undo actions
	clr	di
	call	ObjMessage

	call	UpdateEnableDisable
	LONG jz	disable

	; note exists -- load it

;
;	Load up the title and keyword fields, and the various date fields
;

	call	NTakerDocGetHandleOfDisplayBlock
	mov	cx, bx
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurNote
	mov	dx, offset CardTitle
	call	InkSendTitleToTextObject

	mov	dx, offset CardKeywords
	call	InkNoteSendKeywordsToTextObject

	call	LoadNoteData

	;display the creation date
	call	NTakerDocGetCurNote
	call	NTakerDocGetFileHandle
	call	InkNoteGetCreationDate	
	call	DisplayCreationDate

	;display the modification date
	call	NTakerDocGetCurNote
	call	NTakerDocGetFileHandle
	call	InkNoteGetModificationDate	
	call	DisplayModificationDate
;
;	Since we have a note loaded/displayed, enable the "print current note"
;	and "print current page" print options.
;
	;enable CurPage in GenItemGroup

	mov	ax, MSG_GEN_SET_ENABLED
	jmp	enableDisableCommon

disable:
	call	DisablePageGadgetry
	call	DisableTextDisableInk

	; no note is loaded -- clear out the ink and text objects	

	call	ClearInkObject

	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardTitle

	call	ClearTextObject

	mov	si, offset CardKeywords
	call	ClearTextObject

;
;	Since we do not have any notes loaded/displayed, disable the
;	"print current note" and "print current page" print options.
;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
enableDisableCommon:
	;disable CurPage in GenItemGroup
	mov	dl, VUM_NOW
	GetResourceHandleNS PrintCurPage, bx
	mov	si, offset PrintCurPage
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;disable CurNote in GenItemGroup
	GetResourceHandleNS PrintCurCard, bx
	mov	si, offset PrintCurCard
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_PROCESS_UNDO_ACCEPT_ACTIONS
	call	GeodeGetProcessHandle
	clr	di
	call	ObjMessage

	.leave
	ret

LoadCurrentNote	endp

;---

	; returns z flag set if disabled

UpdateEnableDisable	proc	near	uses si
	class	NTakerDocumentClass
	.enter

	call	NTakerDocGetCurNote
	pushf
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	10$

	call	NTakerDocGetHandleOfDisplayBlock
	push	si
	mov	si, offset ListCreationDate
	call	ClearTextObject
	mov	si, offset ListModificationDate
	call	ClearTextObject

	mov	si, offset CardCreationDate
	call	ClearTextObject
	mov	si, offset CardModificationDate
	call	ClearTextObject
	pop	si

	mov	ax, MSG_GEN_SET_NOT_ENABLED

10$:
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	; enable/disable icon bar and view

	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset NTakerView
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	si, offset CardTitleKeywordsGroup
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS	NTakerIconBar, bx
	mov	si, offset NTakerIconBar
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage


	popf
	.leave
	ret

UpdateEnableDisable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToView/SendToDisplayGroup/SendToDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a message to the view/display group

CALLED BY:	GLOBAL
PASS:		*ds:si - doc obj
		ax, cx, dx, bp - args for message
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToView	proc	near	uses	bx, si, di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset NTakerView
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SendToView	endp
if 0
CallToView	proc	near	uses	bx, si, di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset NTakerView
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	.leave
	ret
CallToView	endp
endif
SendToDisplayGroup	proc	near	uses bx, si, di
	.enter
	GetResourceHandleNS	NTakerDispGroup, bx
	mov	si, offset NTakerDispGroup
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SendToDisplayGroup	endp
SendToDisplay		proc	near	uses	bx, si, di
	.enter
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset NTakerDisp
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SendToDisplay	endp
SetTextObjectNotModified	proc	near	uses	bx, si, di, ax
	.enter
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	movdw	bxsi, cxdx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SetTextObjectNotModified	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	SaveCurrentNoteIfNeeded

DESCRIPTION:	Save the current note if needed

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object
	di - non-zero if we want to save the title

RETURN:	none

DESTROYED:	DI

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/18/92		Initial version
	JT	5/13/92		Modified to save text object
------------------------------------------------------------------------------@
SaveCurrentNoteIfNeeded	proc	near	uses	si, ax, bx, cx, dx, bp	
	.enter

	call	NTakerDocGetCurNote
	LONG jz	done

	call	NTakerDocGetFileHandle
	call	InkNoteGetNoteType
	clr	ch
	jcxz	saveInkNote

;	If text note, save it out

	call	NTakerDocGetTextObj
	mov	bx, ds:[LMBH_handle]
	mov	dx, bp
	call	GetTextUserModifiedState
	jz	afterInk

	call	NTakerDocGetCurNote
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurPage
	call	NTakerDocGetTextObj

	
	push	si
	mov	dx, ds:[LMBH_handle]
	mov	si, NT_TEXT
	call	InkNoteSavePage
	pop	si
	jmp	common

saveInkNote:
	; save ink if it is dirty
	mov	ax, MSG_INK_GET_FLAGS
	call	CallInkObject
	test	cx, mask IF_DIRTY
	jz	afterInk

	call	NTakerDocGetCurNote
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurPage
	call	NTakerDocGetInkObj

	push	si
	mov	dx, ds:[LMBH_handle]
	mov	si, NT_INK
	call	InkNoteSavePage
	pop	si

common:
	call	TimerGetDateAndTime_CXDX
	call	InkNoteSetModificationDate
	call	DisplayModificationDate

afterInk:
	call	NTakerDocGetHandleOfDisplayBlock
	mov	dx, offset CardTitle
	call	GetTextUserModifiedState
	jz	afterTitle

	mov	cx, bx
	call	SetTextObjectNotModified
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurNote
	call	InkNoteSetTitleFromTextObject

	call	TimerGetDateAndTime_CXDX
	call	InkNoteSetModificationDate
	call	DisplayModificationDate

;	Since the title has changed, redisplay the note list.

	clr	cx
	mov	ax, MSG_NTAKER_DOC_RESET_NOTE_LIST
	mov	bx, ds:[LMBH_handle]
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage

afterTitle:
	call	NTakerDocGetHandleOfDisplayBlock
	mov	dx, offset CardKeywords
	call	GetTextUserModifiedState
	jz	afterKeywords

	mov	cx, bx
	call	SetTextObjectNotModified
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurNote
	call	InkNoteSetKeywordsFromTextObject

	call	TimerGetDateAndTime_CXDX
	call	InkNoteSetModificationDate
	call	DisplayModificationDate

afterKeywords:

done:
	.leave
	ret
SaveCurrentNoteIfNeeded	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTextUserModifiedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the text is user modified or not, and sets it 
		not-user-modified in a synchronous manner

CALLED BY:	GLOBAL
PASS:		^lbx:dx - text object
RETURN:		z flag set if not dirty (jz notDirty)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTextUserModifiedState	proc	near	uses	ax, cx, di, si, bp
	.enter
	mov	si, dx
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	tst	cx
	.leave
	ret
GetTextUserModifiedState	endp



COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerDocumentTextUserModified -- MSG_META_TEXT_USER_MODIFIED
						for NTakerDocumentClass

DESCRIPTION:	Handle notification that a text object (the title or the
		keywords) have been made dirty

PASS:
	*ds:si - instance data
	es - segment of NTakerDocumentClass

	ax - The message

	cx:dx - text object

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/18/92		Initial version

------------------------------------------------------------------------------@
NTakerDocumentTextUserModified	method dynamic	NTakerDocumentClass,
						MSG_META_TEXT_USER_MODIFIED

	; force the file dirty

	mov	bx, ds:[di].GDI_fileHandle
	call	DBLockMap
	call	DBDirty
	call	DBUnlock
	ret

NTakerDocumentTextUserModified	endm


COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerDocumentChangeNote -- MSG_NTAKER_DOC_CHANGE_NOTE
						for NTakerDocumentClass

DESCRIPTION:	Change notes (user selected a different note)

PASS:
	*ds:si - instance data
	es - segment of NTakerDocumentClass

	ax - The message

	cx - note number

RETURN:
	nothing
DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/18/92		Initial version
	Julie	2/24/92		Revised
	Julie	3/30/92		Revised to fix bug while loading the note
------------------------------------------------------------------------------@
NTakerDocumentChangeNote	method dynamic	NTakerDocumentClass,
						MSG_NTAKER_DOC_CHANGE_NOTE
	.enter
	cmp	cx, GIGS_NONE
	je	setToNoNote

	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	call	InkFolderGetChildInfo
	push	di, ax
	pushf
	call	SaveCurrentNoteIfNeeded		;This must be done here, and
						; not above, as it can change
						; the ordering of the notes,
						; if the title changes
	popf
	pop	di, ax
	jc	setToNoNote

	call	NTakerDocSetCurNote
	call	NTakerDocResetCurPage		;set the current page to be 
						;the first page of the note.
	jmp	loadNote


setToNoNote:
	call	NTakerDocSetNilNote
loadNote:
	call	LoadCurrentNote
	.leave
	ret

NTakerDocumentChangeNote	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentDisplayNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display a note when the user select that note from the
		search result dialog box.

CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentDisplayNote	method dynamic NTakerDocumentClass, 
					MSG_NTAKER_DOC_DISPLAY_NOTE
	.enter

	; first, determine which item in the list is selected
	push	si
	GetResourceHandleNS SearchList, bx
	mov	si, offset SearchList	
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	cmp	ax, GIGS_NONE
	je	done			;excl is nil

	push	ax
	call	NTakerDocGetSearchBlock
	mov	bx, cx
	pop	cx
	call	GetSelectedNoteHandle	;PASS:cx - entry index
					;bx - handle of the mem block
					;RETURN:ax:di - note hadle
	push	di, si
	call	NTakerDocGetFileHandle
	call	NTakerDocSetCurNote
	pop	di, si
	call	InkGetParentFolder	;axdi <= parent folder
	call	NTakerDocSetCurFolder

	mov	cx, TRUE
	call	ResetMonikersAndSelectCurrentNote

	call	GetCurrentViewType
	cmp	ax, VT_LIST
	jne	done
	call	SetToCardView
done:
	.leave
	ret
NTakerDocumentDisplayNote	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayDate_BXSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Common routine called by DisplayCreationDate / 
		DisplayModificationDate to display the date

CALLED BY:	DisplayCreationDate / DisplayModificationDate

PASS:		cx -- date
		dx -- time
		bx:si -- optr of the date to be displayed

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayDate_BXSI	proc	near
	class	NTakerDocumentClass
	uses	ax,bx,cx,dx,si,di,bp,es

	dateBuffer	local	DATE_TIME_BUFFER_SIZE dup (char)
	; This is a buffer that will hold the text string returned by
	; LocalFormatDateTime

	.enter

	segmov	es, ss
	lea	di, dateBuffer		;ES:DI <- ptr to dateBuffer

	pushdw	bxsi
	mov	ax, cx
	mov	bx, dx
	mov	si, DTF_LONG_NO_WEEKDAY
	call	LocalFormatDateTime
	popdw	bxsi

	push	bp			;save local variables
	mov	dx, ss
	lea	bp, dateBuffer
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	.leave
	ret
DisplayDate_BXSI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayCreationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Displays the creation date of the note
CALLED BY:	GLOBAL
PASS:		cx -- date
		dx -- time
		*ds:si - doc object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayCreationDate	proc	near
	class	NTakerDocumentClass
	uses	bx, si
	.enter
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset ListCreationDate
	call	DisplayDate_BXSI

	mov	si, offset CardCreationDate
	call	DisplayDate_BXSI

	.leave
	ret
DisplayCreationDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayModificationDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Displays the modifiaction date of the note
CALLED BY:	GLOBAL
PASS:		cx -- date
		dx -- time
		*ds:si - doc object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayModificationDate	proc	near
	class	NTakerDocumentClass
	uses	bx, si
	.enter

	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset ListModificationDate
	call	DisplayDate_BXSI

	mov	si, offset CardModificationDate
	call	DisplayDate_BXSI

	.leave
	ret
DisplayModificationDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerGetDateAndTime_CXDX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		call the routine "TimerGetDateAndTime", and move the
		result into cx, dx
CALLED BY:	GLOBAL
PASS:		none
RETURN:		cx, dx -- date, time
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerGetDateAndTime_CXDX	proc	near	uses	ax,bx
	.enter
	call	TimerGetDateAndTime
	mov_tr	cx, ax
	mov_tr	dx, bx
	.leave
	ret
TimerGetDateAndTime_CXDX	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentInsertPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Insert a new page at the end of the note
		(The new created page will be the last page of the note)
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/27/92		Initial version
	JT	5/14/92		Modified for text object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentInsertPage	method dynamic NTakerDocumentClass,\
				MSG_NTAKER_DOC_INSERT_PAGE
	.enter
EC <	call	EnsureIsPenMode						>
	call	SaveCurrentNoteIfNeeded

	call	NTakerDocGetCurNote
	call	NTakerDocGetFileHandle	
	mov	cx, CA_NULL_ELEMENT	;This will create a page at the end.
	call	InkNoteCreatePage

	call	InkNoteGetPages		; pass: ax, di -- note
					;       bx -- file handle
					; return: ax,di -- DB item
					; containing chunk array of pages
	call	InkNoteGetNumPages	; cx = total number of pages

	dec	cx			; transform page number to be 0-based
	call	NTakerDocSetCurPage	

	call	LoadCurrentNote
	.leave
	ret
NTakerDocumentInsertPage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateNumberPages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Update the current page number and maximum page number in
		PageGroup (GenRangeClass).
CALLED BY:	NTakerDocumentInsertPage
PASS:		ax - index of current page (starting at 1)
		cx - index of max page (which ranges from 1)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/27/92		Initial version
	atw	6/17/92		Changed to work with page setup control

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateNumberPages	proc	near	uses	ax, bx, cx, bp, es
	.enter
EC <	call	EnsureIsPenMode						>
	push	ax, cx

	mov	ax, size NotifyPageStateChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	mov     es:[NPSC_firstPage], 1
	pop	es:[NPSC_currentPage], es:[NPSC_lastPage]
	call	MemUnlock

;	Record a notification event

	mov	bp, bx
	call	SendPageControlNotification
	.leave
	ret
UpdateNumberPages	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisablePageGadgetry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	On pen systems, disable the pen control (else, do nothing).

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisablePageGadgetry	proc	near	uses	ax
	.enter
	call	SysGetPenMode
	tst	ax
	jz	exit
	push	bx, bp, di, si
	clr	bp
	call	SendPageControlNotification

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	GetResourceHandleNS	NewPageTrigger, bx
	mov	si, offset NewPageTrigger
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, bp, di, si
exit:
	.leave
	ret
DisablePageGadgetry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendPageControlNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a notification block off to the page control.

CALLED BY:	GLOBAL
PASS:		bp - handle of notification block (0 if no active doc)
		ds - object block
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendPageControlNotification	proc	near	uses	ax, bx, cx, dx, bp, di
	.enter
EC <	call	EnsureIsPenMode						>
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_PAGE_STATE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			;DI <- event handle

;	Send it to the appropriate gcn list

	mov_tr	ax, bp
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_APP_TARGET_NOTIFY_PAGE_STATE_CHANGE
	mov	ss:[bp].GCNLMP_block, ax
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, mask GCNLSF_SET_STATUS
	tst	ax
	jnz	10$
	ornf	ss:[bp].GCNLMP_flags, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx
	.leave
	ret
SendPageControlNotification	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentNextPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to the next page

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerDocument object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentNextPage	method	NTakerDocumentClass, 
			MSG_META_PAGED_OBJECT_NEXT_PAGE
	call	NTakerDocGetCurPage
	add	cx, 2
	mov	ax, MSG_META_PAGED_OBJECT_GOTO_PAGE
	GOTO	ObjCallInstanceNoLock
NTakerDocumentNextPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentPreviousPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to the next page

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerDocument object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentPreviousPage	method	NTakerDocumentClass, 
			MSG_META_PAGED_OBJECT_PREVIOUS_PAGE
	.enter
	call	NTakerDocGetCurPage
	jcxz	exit
	mov	ax, MSG_META_PAGED_OBJECT_GOTO_PAGE
	call	ObjCallInstanceNoLock
exit:
	.leave
	ret
NTakerDocumentPreviousPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentGotoPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Display the page selected in the GenRangeClass, PageGroup
		and update the current page number
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
		cx - page number to go to (1 = first page)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/28/92		Initial version
	JT	5/14/92		Modified for text object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentGotoPage	method dynamic NTakerDocumentClass, \
				MSG_META_PAGED_OBJECT_GOTO_PAGE
	.enter

;	If we are going to the current page, branch to exit

	dec	cx			; Transform page number to be 0-based.
	call	NTakerDocDeref_DSDI
	cmp	cx, ds:[di].NDOCI_curPage
	jz	exit

;	Make sure that the page we are going to is in bounds. Exit if not.

	push	cx
	call	NTakerDocGetFileHandle	; in bx
	call	NTakerDocGetCurNote	; in diax
	call	InkNoteGetPages
	call	InkNoteGetNumPages
	pop	ax
	cmp	ax, cx
	jae	exit

;	Save the current note, set the new page number, and load the note

	push	ax
;	inc	ax			;AX <- current page (1-based)
	call	SaveCurrentNoteIfNeeded
	pop	cx			; cx <= new page number (0-based)
	call	NTakerDocSetCurPage	; in cx

	call	LoadCurrentNote
exit:
	.leave
	ret
NTakerDocumentGotoPage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentQueryForNoteListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the moniker for the passed note list.

CALLED BY:	GLOBAL
PASS:		^lcx:dx - list requesting the moniker
		bp - position requested
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentQueryForNoteListMoniker	method	NTakerDocumentClass,
				MSG_NTAKER_DOC_QUERY_FOR_NOTE_LIST_MONIKER
	.enter
	call	NTakerDocGetCurFolder
	call	NTakerDocGetFileHandle
	mov	si, 1			;Set "display folders" flag
	call	InkFolderDisplayChildInList
	.leave
	ret
NTakerDocumentQueryForNoteListMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentQueryForMoveListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the moniker for the passed note list.

CALLED BY:	GLOBAL
PASS:		^lcx:dx - list requesting the moniker
		bp - position requested
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentQueryForMoveListMoniker	method	NTakerDocumentClass,
				MSG_NTAKER_DOC_QUERY_FOR_MOVE_LIST_MONIKER
	.enter
	call	NTakerDocGetCurMoveFolder
	call	NTakerDocGetFileHandle
	mov	si, 1				;Set "display folders" flag
	call	InkFolderDisplayChildInList
	.leave
	ret
NTakerDocumentQueryForMoveListMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentQueryForSearchListMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the moniker for the passed note list.

CALLED BY:	GLOBAL
PASS:		^lcx:dx - list requesting the moniker
		bp - position requested
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentQueryForSearchListMoniker	method	NTakerDocumentClass,
				MSG_NTAKER_DOC_QUERY_FOR_SEARCH_LIST_MONIKER
	.enter
	push	di, cx
	call	NTakerDocGetSearchBlock		;get search block in cx
	mov	bx, cx
	pop	di, cx
	tst	bx
	je	done
	mov_tr	ax, bp					;ax - entry #
	call	DisplaySearchResultInList
done:
	.leave
	ret
NTakerDocumentQueryForSearchListMoniker	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSelectedNoteHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get a note handle in the search result block
CALLED BY:	DisplaySearchResultInList
PASS:		cx - entry index
		bx - handle of the mem block
RETURN:		ax:di - note hadle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSelectedNoteHandle	proc	near	uses	cx,si,es
	.enter

	call	MemLock	
	mov	es, ax

	;offset of the item in mem block =
	;size of Header + (entry index) * size of element(which is 4)

	shl	cx, 1
	shl	cx, 1
	add	cx, size FindNoteHeader	;size of block header
	mov	si, cx
	movdw	axdi, es:[si]

	call	MemUnlock

	.leave
	ret
GetSelectedNoteHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplaySearchResultInList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Display the search result in GenList
CALLED BY:	NTakerDocumentRequestEntryMoniker
PASS:		cx:dx - optr of output list
		bx - search result block handle
		ax - entry #
RETURN:		nothing
DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/16/92		Initial version
	JT	6/1/92		Modified to copy in the icon for text and
				ink note
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplaySearchResultInList	proc	near
	class	NTakerDocumentClass
	titleStr	local	INK_DB_MAX_TITLE_SIZE+2	dup (char)
	.enter

	push	bp			;preserve local variables
	push	cx, dx, ax		;save output list optr and index entry

	mov_tr	cx, ax			;cx - entry index
	call	GetSelectedNoteHandle	;get note handle in di:ax
	call	NTakerDocGetFileHandle	;bx - file handle
	call	InkNoteGetNoteType	;cl - note type
	clr	ch
	mov	dx, cx			;dx - note type
	tst	dx
	jz	common
	mov	dx, 1
common:
	segmov	ds, ss
	lea	si, titleStr
	call	InkGetTitle		;pass: di.ax - note handle
					;bx - file handle or override
					;ds:si - dest for string
					;return: cx - length of name w/null
	mov	di, ds
	mov	cx, si		;di:cx <= title of the note

	mov	ax, dx			;ax - note type

	pop	bx, si, dx		;bx:si <= optr of output list
					;dx - index entry
	call	InkNoteCopyMoniker

	pop	bp

	.leave
	ret
DisplaySearchResultInList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchGetNumMatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get number of matched string from the header of search
		result block
CALLED BY:	NTakerDocumentGetNumberOfEntries
PASS:		nothing
RETURN:		cx - number of matches
DESTROYED:	es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchGetNumMatches	proc	near	uses	ax,bx
	.enter
	call	NTakerDocGetSearchBlock
	jcxz	done
	mov	bx, cx
	call	MemLock
	mov	es, ax
	mov	cx, es:[FNH_count]		; cx <= # of matched string
	call	MemUnlock
done:
	.leave
	ret
SearchGetNumMatches	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCustomBackgroundEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Enable or Disable the Custom Background list entry in the
		BackgroundList depending upon whether ther is a custom
		gstring in the file.

CALLED BY:	NTakerDocumentGainedDocExcl 
PASS:		*ds:si = NTakerDocumentClass
		
RETURN:		nothing
DESTROYED:	ax, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCustomBackgroundEntry	proc	near
	class	NTakerDocumentClass
	uses	bx,si, bp
	.enter

	call	NTakerDocGetFileHandle

	call	InkGetDocCustomGString
	tst	ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jz	disable
	mov	ax, MSG_GEN_SET_ENABLED
disable:
	mov	dl, VUM_NOW
	GetResourceHandleNS CustomBackgroundEntry, bx
	mov	si, offset CustomBackgroundEntry
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
SetCustomBackgroundEntry	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupGlobalInkOnlyUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the state of UI objects that various documents
		share.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupGlobalInkOnlyUI	proc	near	uses	si
	localPageSizeReport	local	PageSizeReport
	.enter			

	call	NTakerDocGetFileHandle

	;pass to SpoolSetDocSize
	;	cx	- TRUE (document is open)
	;	ds:si	- PageSizeReport structure
	push	ds, si
	segmov	ds, ss
	lea	si, localPageSizeReport
	call	InkGetDocPageInfo	
	mov	cx, TRUE
	call	SpoolSetDocSize
	pop	ds, si			;*ds:si - NTakerDocumentClass

	;
	; for ink object only
	;

	call	InkGetDocGString	;ax = gstring type
	mov_tr	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	GetResourceHandleNS NTakerBackgroundList, bx
	mov	si, offset NTakerBackgroundList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	call	SetCustomBackgroundEntry	;*ds:si = NTakerDocumentClass
	.leave
	ret
SetupGlobalInkOnlyUI	endp


COMMENT @----------------------------------------------------------------------

MESSAGE:	NTakerDocumentGainedModelExcl -- MSG_META_GAINED_MODEL_EXCL
						for NTakerDocumentClass

DESCRIPTION:	...

PASS:
	*ds:si - instance data
	es - segment of NTakerDocumentClass

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
	Tony	2/18/92		Initial version
	JT	4/6/92		Modified to update UI and set background
	JT	5/14/92		Modified for text object - no background
------------------------------------------------------------------------------@
NTakerDocumentGainedModelExcl	method dynamic	NTakerDocumentClass,
					MSG_META_GAINED_MODEL_EXCL
	push	ax, cx, dx, bp

	call	SysGetPenMode
	tst	ax
	jz	notInkMode

	call	SetupGlobalInkOnlyUI

notInkMode:
	pop	ax, cx, dx, bp
	mov	di, offset NTakerDocumentClass
	GOTO	ObjCallSuperNoLock
NTakerDocumentGainedModelExcl	endm

NTakerDocumentLostModelExcl	method dynamic	NTakerDocumentClass,
					MSG_META_LOST_MODEL_EXCL
	.enter
	call	UpdateEnableDisable

	clr	dx
	call	NTakerDocSetSearchBlock


	push	si
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	GetResourceHandleNS MoveBox, bx
	mov	si, offset MoveBox	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS CreateTopicBox, bx
	mov	si, offset CreateTopicBox
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage	

	GetResourceHandleNS SearchResultBox, bx
	mov	si, offset SearchResultBox	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	GetResourceHandleNS SearchKeywordBox, bx
	mov	si, offset SearchKeywordBox	
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	;pass to SpoolSetDocSize
	;	cx	- FALSE (document is closed)
	;	DS:SI	= PageSizeReport structure
	;	CX	= TRUE (document is open)
	;		= FALSE (document is closed)

	call	SysGetPenMode
	tst	ax
	jz	notPenMode

	clr	bp
	call	SendPageControlNotification

	mov	cx, FALSE
	call	SpoolSetDocSize
notPenMode:
	pop	si
	mov	ax, MSG_META_LOST_MODEL_EXCL
	mov	di, offset NTakerDocumentClass
	call	ObjCallSuperNoLock
	.leave
	ret
NTakerDocumentLostModelExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceApplyOnList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is called to notify the document object of the current
		selection on the passed list object

CALLED BY:	GLOBAL
PASS:		^lbx:si - list object
RETURN:		nothing
DESTROYED:	ax, cx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceApplyOnList	proc	near
	.enter

;	Notify the document object about the current selection

	mov	cx, TRUE		;Mark as modified
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_APPLY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
ForceApplyOnList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectCurrentNoteInNoteList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine selects the current note in the note list. 
		If there is no current note, it selects the first item
		(or if no items in list, sets "no selection").

CALLED BY:	GLOBAL
PASS:		*ds:si - ptr to NTakerDocument object
RETURN:		nada
DESTROYED:	ax, cx, dx, di, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectCurrentNoteInNoteList	proc	near	uses	si
	class	NTakerDocumentClass
	.enter

	call	GetNoteInfo
	jnc	noCurrentNote		;If there is no current note, branch.

	mov_tr	cx, ax
setSelectionCommon:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
sendMessageCommon:
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
noCurrentNote:
	tst	dx			;If no notes or folders, branch
	jz	noChildren
	clr	cx			;Else, select first item in list
	jmp	setSelectionCommon

noChildren:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	jmp	sendMessageCommon
SelectCurrentNoteInNoteList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetMonikersAndSelectCurrentNote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the monikers in the note list.

CALLED BY:	GLOBAL
PASS:		*ds:si - document object
		cx - non-zero if you want to notify the document of the
		     new selection.
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetMonikersAndSelectCurrentNote	proc	near	
	.enter

;	Find out how many monikers should be displayed

	push	cx
	clr	cx
	call	NTakerDocGetCurFolder	;AX.DI <- cur folder

	call	NTakerDocGetFileHandle	;BX <- file handle
	call	InkFolderGetNumChildren	;CX <- # folders, DX <- # notes
	xchg	cx, dx
	add	cx, dx

;	Set the # items

	push	si
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList

	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	call	SelectCurrentNoteInNoteList
	pop	cx			;Restore "notify selection" flag
	jcxz	exit


	push	si
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList
	call	ForceApplyOnList
	pop	si
exit:
	call	DisplayCurrentFolderName
	.leave
	ret

ResetMonikersAndSelectCurrentNote	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResetNumItemsAndResetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the # items in the list object, changes the 
		selection, and notifies the document.

CALLED BY:	GLOBAL
PASS:		^lbx:dx - dynamic list object
		cx - # items
RETURN:		nada
DESTROYED:	ax, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 6/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ResetNumItemsAndResetSelection	proc	near	uses	si
	.enter

	mov	si, dx
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage


	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	jcxz	setSelection
	clr	cx
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
setSelection:
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

;	Notify document of selection change

	call	ForceApplyOnList

	.leave
	ret
ResetNumItemsAndResetSelection	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ResetMoveFolderList

DESCRIPTION:	Reset the list of notes in the move dialog box

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	none

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Julie	2/26/92		Initial version

------------------------------------------------------------------------------@
ResetMoveFolderList	proc	near

	call	NTakerDocGetCurMoveFolder
	call	NTakerDocGetFileHandle
	call	InkFolderGetNumChildren	;CX <- # folders, DX <- # notes
	
	GetResourceHandleNS	MoveTopicList, bx
	mov	dx, offset MoveTopicList
	call	ResetNumItemsAndResetSelection

	call	DisplayCurrentMoveFolderName

	ret

ResetMoveFolderList	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ResetSearchList

DESCRIPTION:	Reset the list of notes in the search dialog box

CALLED BY:	INTERNAL

PASS:
	*ds:si - document object

RETURN:
	none

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Julie	3/16/92		Initial version

------------------------------------------------------------------------------@
ResetSearchList	proc	near

	call	SearchGetNumMatches

	GetResourceHandleNS	SearchList, bx
	mov	dx, offset SearchList
	call	ResetNumItemsAndResetSelection
	ret

ResetSearchList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayCurrentFolderName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Display the name of the current folder
CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayCurrentFolderName	proc	near	uses	si
	class	NTakerDocumentClass
	.enter

	call	NTakerDocGetHandleOfDisplayBlock
	mov	cx, bx				;^lCX:DX <- text object to
	mov	dx, offset TopicName		; load with folder name

	call	NTakerDocGetFileHandle		; bx -- file handle
	call	NTakerDocGetCurFolder		; ax:di -- parent folder

	call	InkSendTitleToTextObject
	call	InkGetParentFolder
	tstdw	axdi
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	setEnabled
	mov	ax, MSG_GEN_SET_NOT_ENABLED
setEnabled:
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset UpTopic
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
DisplayCurrentFolderName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayCurrentMoveFolderName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Display the name of the current move folder
CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisplayCurrentMoveFolderName	proc	near
	class	NTakerDocumentClass
	.enter

	call	NTakerDocGetFileHandle		; bx -- file handle
	call	NTakerDocGetCurMoveFolder	; ax:di -- parent folder
	jz	setDisabled

	GetResourceHandleNS MoveTopicNameDisplay,cx
	mov	dx, offset MoveTopicNameDisplay
	call	InkSendTitleToTextObject

	call	InkGetParentFolder
	tstdw	axdi
	mov	ax, MSG_GEN_SET_ENABLED
	jnz	setEnabled
setDisabled:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
setEnabled:
	GetResourceHandleNS MoveUpTopicTrigger,bx
	mov	si, offset MoveUpTopicTrigger
	mov	dl, VUM_NOW
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	.leave
	ret
DisplayCurrentMoveFolderName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddItemAndForceApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds an item and forces an apply on the list

CALLED BY:	GLOBAL
PASS:		ax - offset to add an item at
		*ds:si - NTaker doc object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddItemAndForceApply	proc	near	uses	si
	.enter

	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList

;	Add new item.

	push	ax
	mov_tr	cx, ax
	mov	dx, 1
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx

;	Select it.

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

;	Tell the document about the new selection.

	call	ForceApplyOnList
	.leave
	ret
AddItemAndForceApply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfTooDeeplyNested
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't let them nest the topics more than 10 levels deep.

CALLED BY:	GLOBAL
PASS:		*ds:si - GenDocument
		BX - file han
		ax:di - current folder
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfTooDeeplyNested	proc	near	uses	ax, bx, cx, dx, bp, di
	.enter
	mov	cx, 10
loopTop:
	call	InkGetParentFolder
	tstdw	diax		;This should clear the carry
EC <	ERROR_C	-1							>
	jz	exit
	loop	loopTop

;	We have too many levels of topics - tell the user that he can't create
;	no more.

        sub     sp, size StandardDialogOptrParams
        mov     bp, sp
        mov     ss:[bp].SDOP_customFlags, \
                   CustomDialogBoxFlags <0, CDT_ERROR, GIT_NOTIFICATION,0>

	GetResourceHandleNS tooManyTopicLevels,ss:[bp].SDOP_customString.handle
        mov     ss:[bp].SDOP_customString.chunk, offset tooManyTopicLevels
        clr     ax                              ;none of these are passed
        mov     ss:[bp].SDOP_stringArg1.handle, ax
        mov     ss:[bp].SDOP_stringArg2.handle, ax
        mov     ss:[bp].SDOP_customTriggers.handle, ax
	clr	ss:[bp].SDOP_helpContext.segment
        call    UserStandardDialogOptr          ; pass params on stack
	stc
exit:
	.leave
	ret
CheckIfTooDeeplyNested	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentBringupCreateTopicBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the create topic box if possible

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentBringupCreateTopicBox	method dynamic NTakerDocumentClass,
				MSG_NTAKER_DOC_BRINGUP_CREATE_TOPIC_BOX
	.enter
	call	NTakerDocGetFileHandle		; bx -- file handle
	call	NTakerDocGetCurFolder		; ax:di -- parent folder
	
	call	CheckIfTooDeeplyNested
	jc	exit

;	Bring up the box

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	CreateTopicBox, bx
	mov	si, offset CreateTopicBox
	clr	di
	call	ObjMessage
exit:
	.leave
	ret
NTakerDocumentBringupCreateTopicBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentCreateFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Creating a new folder
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentCreateFolder	method dynamic NTakerDocumentClass, \
				MSG_NTAKER_DOC_CREATE_FOLDER
	.enter
	call	NTakerDocGetFileHandle		; bx -- file handle
	call	NTakerDocGetCurFolder		; ax:di -- parent folder

	call	InkFolderCreateSubFolder	;return ax:di- new child folder
	call	SendNumTopicsToDisplay
	GetResourceHandleNS TopicNameTextEdit, cx
	mov	dx, offset TopicNameTextEdit	;cx:dx - optr of NewFolderTitle

	call	InkFolderSetTitleFromTextObject

	movdw	dxcx, axdi
	call	InkGetParentFolder
	call	InkFolderGetChildNumber	

	call	AddItemAndForceApply
;exit:
	.leave
	ret
NTakerDocumentCreateFolder	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentGetParentFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Go to the parent folder of the current folder
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentGetParentFolder	method dynamic NTakerDocumentClass, \
				MSG_NTAKER_DOC_GET_PARENT_FOLDER
	.enter
	call	SaveCurrentNoteIfNeeded
	call	NTakerDocGetFileHandle		; bx -- file handle
	call	NTakerDocGetCurFolder		; ax:di -- parent folder
	call	InkGetParentFolder
	call	NTakerDocSetCurFolder

	call	NTakerDocSetNilNote

	mov	cx, TRUE
	call	ResetMonikersAndSelectCurrentNote

	.leave
	ret
NTakerDocumentGetParentFolder	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentGetParentMoveFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Go to the parent folder of the current folder
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentGetParentMoveFolder	method dynamic NTakerDocumentClass, \
				MSG_NTAKER_DOC_GET_PARENT_MOVE_FOLDER
	.enter
EC <	test	es:[features], mask NF_CREATE_TOPICS			>
EC <	ERROR_Z	-1							>
	call	SaveCurrentNoteIfNeeded

	call	NTakerDocGetFileHandle		; bx -- file handle
	call	NTakerDocGetCurMoveFolder	; ax:di -- parent folder
						; of the curMoveFolder

	call	InkGetParentFolder
	call	NTakerDocSetCurMoveFolder
	jz	done

	call	NTakerDocSetNilNote
	call	ResetMoveFolderList		; list the sub-folders in
						; the parent folder
						; and update the text display
						; of the current move folder
done:
	.leave
	ret
NTakerDocumentGetParentMoveFolder	endm
if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentCardListDoubleClick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		open a folder when it is double-clicked or the Open trigger
		button is pressed
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentCardListDoubleClick	method dynamic NTakerDocumentClass, \
				MSG_NTAKER_DOC_CARD_LIST_DOUBLE_CLICK
	.enter

	; first, determine which item in the list is selected
	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	cmp	ax, GIGS_NONE
	je	done			; excl is nil

	mov_tr	cx, ax
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	call	InkFolderGetChildInfo
	jnc	isNote			; it is a note

	mov	ax, MSG_NTAKER_DOC_DOWN_TOPIC
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
isNote:
	mov	ax, MSG_NTAKER_DOC_EDIT_SELECTED_CARD
	call	ObjCallInstanceNoLock
	jmp	done
NTakerDocumentCardListDoubleClick	endm
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentEditSelectedCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Edits the selected card.

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentEditSelectedCard	method	NTakerDocumentClass, 
				MSG_NTAKER_DOC_EDIT_SELECTED_CARD

;	Do nothing if folder selected

	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	cmp	ax, GIGS_NONE
	je	exit			; excl is nil

	mov_tr	cx, ax
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	call	InkFolderGetChildInfo
	jc	exit			;Exit if folder selected

	call	SetToCardView
exit:
	ret

NTakerDocumentEditSelectedCard	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetToCardView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the view to "Card".

CALLED BY:	GLOBAL
PASS:		ds - obj block
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetToCardView	proc	near	uses	ax, bx, cx, dx, di, si
	.enter
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, VT_CARD
	clr	dx			
	GetResourceHandleNS	ViewTypeList, bx
	mov	si, offset ViewTypeList
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	call	ForceApplyOnList
	.leave
	ret
SetToCardView	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentDownTopic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the currently selected topic as the current topic

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentDownTopic	method	NTakerDocumentClass, 
				MSG_NTAKER_DOC_DOWN_TOPIC

;	Do nothing if folder selected

	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si
	cmp	ax, GIGS_NONE
	je	exit			; excl is nil

	mov_tr	cx, ax
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	call	InkFolderGetChildInfo
	jnc	exit			;Exit if note selected

	call	NTakerDocSetCurFolder
	call	NTakerDocSetNilNote

	mov	cx, TRUE
	call	ResetMonikersAndSelectCurrentNote
exit:
	ret
NTakerDocumentDownTopic	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentMoveOpenFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		open a folder in the move dialog box
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentMoveOpenFolder	method dynamic NTakerDocumentClass, \
				MSG_NTAKER_DOC_MOVE_OPEN_FOLDER
	.enter

EC <	test	es:[features], mask NF_CREATE_TOPICS			>
EC <	ERROR_Z	-1							>

	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurMoveFolder
	jz	done

	; first, determine which item in the list is selected
	push	bx, si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GetResourceHandleNS MoveTopicList, bx
	mov	si, offset MoveTopicList	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si
	cmp	ax, GIGS_NONE
	je	done			; excl is nil
					; return cx:dx -ItemID:curFolder handle

	mov_tr	cx, ax
	call	NTakerDocGetCurMoveFolder
	call	InkFolderGetChildInfo
	jnc	done			; it is a note


	call	NTakerDocSetCurMoveFolder
	call	NTakerDocSetNilNote
	jz	done
	call	ResetMoveFolderList	

done:
	.leave
	ret
NTakerDocumentMoveOpenFolder	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentInitMoveBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Brings up and initialize the MoveBox dialog box
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentInitMoveBox	method dynamic NTakerDocumentClass, \
				MSG_NTAKER_DOC_INIT_MOVE_BOX
	.enter

EC <	test	es:[features], mask NF_CREATE_TOPICS			>
EC <	ERROR_Z	-1							>
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	call	NTakerDocSetCurMoveFolder	

	push	ax, bx, di, si
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS MoveBox, bx
	mov	si, offset MoveBox	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage	
	pop	ax, bx, di, si

	call	ResetMoveFolderList

	.leave
	ret
NTakerDocumentInitMoveBox	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteCurrentItemAndForceApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the currently selected item and sends an APPLY to the
		list.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteCurrentItemAndForceApply	proc	near	uses	si
	.enter


;	Get index of currently selected item

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	NTakerDocGetHandleOfDisplayBlock
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	si, offset CardList
	call	ObjMessage


;	Delete the currently selected item

	push	ax
	mov_tr	cx, ax
	mov	dx, 1
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage


;	Change selection to be consistent with old selection

	mov	ax, MSG_GEN_DYNAMIC_LIST_GET_NUM_ITEMS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS	
	call	ObjMessage
	pop	ax
	jcxz	setNoSelection
;
;	AX <- old selection
;	CX <- new # items
;
	cmp	ax, cx
	jb	10$
	dec	ax
10$:
	mov_tr	cx, ax
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
setSelCommon:
	clr	dx
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

;	Force an apply

	call	ForceApplyOnList
	.leave
	ret
setNoSelection:
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
	jmp	setSelCommon	
DeleteCurrentItemAndForceApply	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Move a note or folder to another folder
		Move a parent/ancestor folder to its subfolder is not allowed
		Move a folder to itself is not allowed
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentMove	method dynamic NTakerDocumentClass, MSG_NTAKER_DOC_MOVE
	.enter
	cmpdw	ds:[di].NDOCI_curMoveFolder, ds:[di].NDOCI_curFolder, ax
	jz	done

	; first, determine which item in the list is selected
	push	bx, si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, si
	cmp	ax, GIGS_NONE
	je	done				; excl is nil

	push	ax
	call	SaveCurrentNoteIfNeeded
	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	pop	cx

	call	InkFolderGetChildInfo		; return ax:di -- 
						; note or folder handle
	jc	moveFolder			; it is a folder

	call	NTakerDocGetCurMoveFolder_CXDX
	call	InkNoteMove			; pass di, ax -- note to move
						;  cx ,dx -- new parent folder
						;      bx -- file handle
	jmp	redisplayMonikers

moveFolder:

	call	NTakerDocGetCurMoveFolder_CXDX
	call	CheckIfMoveToSubFolder
	jc	done
	call	InkFolderMove			; pass di, ax -- folder to move
						;  cx ,dx -- new parent folder
redisplayMonikers:
	call	DeleteCurrentItemAndForceApply
done:
	.leave
	ret
NTakerDocumentMove	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfMoveToSubFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Check to see if the destination folder is the parent or
		ancestor folder of the source folder or if the destination
		is the source folder; none of the above is allowed -- set carry
CALLED BY:	NTakerDocumentMove
PASS:		dx, cx -- destination folder
		ax, di -- source folder
RETURN:		carry is set if the source folder is moved  to its sub-folder
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfMoveToSubFolder	proc	near
	uses	ax,bx,cx,dx,di
	.enter

	cmpdw	diax, cxdx			; folder move to itself 
						; not allowed
	je	isInvalidFolder

recursiveGetParent:
	pushdw	diax				; axdi:source
	movdw	diax, cxdx			; axdi:dest
	call	InkGetParentFolder		; axdi:parent of dest
	popdw	cxdx				; cxdx:source
	cmpdw	diax, cxdx			; whether if parent of dest 
						; = source
	je	isInvalidFolder
	
	; check to see if it goes to the top level
	tstdw	diax				; whether parent of dest = 0,
						; top level
	je	done
	xchgdw	cxdx,diax			; cxdx: parent of dest => dest
						; diax: source
	jmp	recursiveGetParent	

isInvalidFolder:
	stc

done:
	.leave
	ret
CheckIfMoveToSubFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Delete a note or a folder
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentDelete	method dynamic NTakerDocumentClass, \
				MSG_NTAKER_DOC_DELETE
	.enter

	call	SaveCurrentNoteIfNeeded

	; first, determine which item in the list is selected
	push	si
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	si

	cmp	ax, GIGS_NONE
	je	nothingToDelete
	mov_tr	cx, ax


	call	NTakerDocGetFileHandle
	call	NTakerDocGetCurFolder
	call	InkFolderGetChildInfo	; return ax:di -- note or folder handle
	jc	deleteFolder		; it is a folder

	call	NTakerDocGetFileHandle
	call	InkNoteDelete			; pass di, ax -- note to delete
						;      bx     -- file handle
	call	NTakerDocSetNilNote
	jmp	updateList

deleteFolder:

	;check if there is any child in the current folder
	;if there is children, ask if the user want to delete the folder
	call	NTakerDocGetFileHandle
	call	InkFolderGetNumChildren		; pass: di, ax -- folder
						;       bx -- file handle
						; return: cx -- # sub folders
						;         dx -- # notes
	add	cx, dx
	jcxz	doFolderDelete
	push	ax
	call	DeleteFolderDialog
	cmp	ax, IC_YES
	pop	ax
	jne	nothingToDelete

doFolderDelete:
	call	InkFolderDelete			; pass di, ax -- 
						; folder to be deleted
						;      bx -- file handle

updateList:
	call	DeleteCurrentItemAndForceApply
nothingToDelete:
	.leave
	ret
NTakerDocumentDelete	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentResetNoteList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the note list via the queue.

CALLED BY:	GLOBAL
PASS:		cx - non-zero if we want to notify the document of the
		     selection	
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentResetNoteList	method	NTakerDocumentClass,
				MSG_NTAKER_DOC_RESET_NOTE_LIST
	.enter
	call	ResetMonikersAndSelectCurrentNote
	.leave
	ret
NTakerDocumentResetNoteList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteFolderDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Brings up a dialog to ask the user if he/she wants to
		delete a folder even though it is not empty
CALLED BY:	NTakerDocumentDelete
PASS:		nothing
RETURN:		ax = IC_YES or IC_NO
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteFolderDialog	proc	near	uses	bp
	.enter

        sub     sp, size StandardDialogOptrParams
        mov     bp, sp
        mov     ss:[bp].SDOP_customFlags, \
                   CustomDialogBoxFlags <0, CDT_QUESTION, GIT_AFFIRMATION,0>

	GetResourceHandleNS topicNotEmptyString, ss:[bp].SDOP_customString.handle
        mov     ss:[bp].SDOP_customString.chunk, offset topicNotEmptyString
        clr     ax                              ;none of these are passed
        mov     ss:[bp].SDOP_stringArg1.handle, ax
        mov     ss:[bp].SDOP_stringArg2.handle, ax
        mov     ss:[bp].SDOP_customTriggers.handle, ax
	clr	ss:[bp].SDOP_helpContext.segment
        call    UserStandardDialogOptr          ; pass params on stack

	.leave
	ret

DeleteFolderDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentSearchByTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search a note by title which is entered by the user

CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
		dx - handle of block containing SearchReplaceStruct
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentSearchByTitle	method dynamic NTakerDocumentClass, MSG_SEARCH
	offsetSI	local	word
	segDS		local	word
	.enter

	push	bp
	call	SaveCurrentNoteIfNeeded
	pop	bp

	mov	segDS, ds
	mov	offsetSI, si
	call	NTakerDocGetFileHandle		; bx -- file handle
	push	dx				; save the block handle of
						; SearchReplaceStruct

	push	bx				; save file handle
	mov	bx, dx
	call	MemLock
	mov	ds, ax
	mov	si, offset SRS_searchString	;DS:SI <- string to match
	mov	al, ds:[SRS_params]		;AL <- search options
	pop	bx

	;get SearchTextOptions in ah
	push	ax, si, bx, bp
	GetResourceHandleNS SearchOptionsListGroup, bx
	mov	si, offset SearchOptionsListGroup
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL
	call	ObjMessage			;AL = non-zero if search in
						; body option selectted
	mov_tr	cx, ax
	pop	ax, si, bx, bp
	mov	ah, cl

	call	InkNoteFindByTitle		;pass:
						;DS:SI <- string to match
						;AL - SearchOptions
						;AH - non-zero if we want to
						; search body text	
						;BX <- file handle
						;return: DX-search block handle
	pop	bx
	call	MemFree
	cmp	dx, 0
	je	noMatchDialog

	mov	ds, segDS
	mov	si, offsetSI
	call	NTakerDocSetSearchBlock
	call	SearchResultDialog
	call	ResetSearchList
	jmp	done

noMatchDialog:
	call	SearchNoMatchDialog
done:
	.leave
	ret
NTakerDocumentSearchByTitle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchResultDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Bring up a dialog box of search result
CALLED BY:	NTakerDocumentSearchByTitle / NTakerDocumentSearchByKeyword
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax,bx,si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchResultDialog	proc	near
	class	NTakerDocumentClass
	uses	si,bp
	.enter

	GetResourceHandleNS SearchResultBox, bx
	mov	si, offset SearchResultBox	
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage

	.leave
	ret
SearchResultDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchNoMatchDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Bring up a dialog box to tell user that there is no matched
		string via searching
CALLED BY:	NTakerDocumentSearchByTitle / NTakerDocumentSearchByKeyword
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SearchNoMatchDialog	proc	near	uses	ax,bp
	.enter
        sub     sp, size StandardDialogOptrParams
        mov     bp, sp
        mov     ss:[bp].SDOP_customFlags,
                 CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_NOTIFICATION,0>

	GetResourceHandleNS searchNoMatchString,ss:[bp].SDOP_customString.handle
        mov     ss:[bp].SDOP_customString.chunk, offset searchNoMatchString
        clr     ax                              ;none of these are passed
        mov     ss:[bp].SDOP_stringArg1.handle, ax
        mov     ss:[bp].SDOP_stringArg2.handle, ax
        mov     ss:[bp].SDOP_customTriggers.handle, ax
	clr	ss:[bp].SDOP_helpContext.segment
        call    UserStandardDialogOptr          ; pass params on stack

	.leave
	ret
SearchNoMatchDialog	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentCloseSearchDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Close Dialog box and do some clean up work while the
		user hit the close trigger in the search result dialog box.

CALLED BY:	NTakerDocumentSearchByTitle / NTakerDocumentSearchByKeyword

PASS:		*ds:si	= NtakerDocumentClass object
		ds:di	= NtakerDocumentClass instance data
		ds:bx	= NtakerDocumentClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentCloseSearchDialog	method dynamic NTakerDocumentClass, 
				MSG_NTAKER_DOC_CLOSE_SEARCH_DIALOG
	.enter
	clr	dx
	call	NTakerDocSetSearchBlock
	.leave
	ret
NTakerDocumentCloseSearchDialog	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentSearchByKeyword
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Search a note by keyword which is entered by the user
CALLED BY:	
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/19/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentSearchByKeyword	method dynamic NTakerDocumentClass, 
					MSG_NTAKER_DOC_SEARCH_BY_KEYWORD
	offsetSI	local	word
	segDS		local	word
	option		local	word
	.enter

	push	bp
	call	SaveCurrentNoteIfNeeded
	pop	bp

	mov	segDS, ds
	mov	offsetSI, si
	call	NTakerDocGetFileHandle		; bx -- file handle
	push	bx

	;check to see if SearchByAllKeywordListEntry is on
	;if it is on, set the option in AX to be 1.

	push	bp				;save local variables
	GetResourceHandleNS SearchByAllKeywordList, bx
	mov	si, offset SearchByAllKeywordList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	mov	option, ax

	GetResourceHandleNS SearchKeywordTextEdit, bx
	mov	si, offset SearchKeywordTextEdit
	clr	dx
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, cx
	call	MemLock				; cx - block handle of
						; the block containing text
						; that is, string to match
	mov	ds, ax
	clr	si

	pop	bx				;bx - file handle
	push	cx				;cx - block handle
	mov	ax, option
	call	InkNoteFindByKeywords		;pass:
						;DS:SI <- string to match
						;AX - SearchOptions
						;BX <- file handle
						;return: DX-search block handle
	pop	bx
	push	bx
	call	MemUnlock
	cmp	dx, 0
	je	noMatchDialog

	mov	ds, segDS
	mov	si, offsetSI
	call	NTakerDocSetSearchBlock
	call	SearchResultDialog
	mov	ds, segDS
	mov	si, offsetSI
	call	ResetSearchList
	jmp	done

noMatchDialog:
	call	SearchNoMatchDialog

done:
	pop	bx				;free the block containing
	call	MemFree				;the text entered by user
	.leave
	ret
NTakerDocumentSearchByKeyword	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentPrintReportPageSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Sent to report the page size and layout options
		that the user has selected.
CALLED BY:	
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
		dx	= Size PageSizeReport
		ss:bp	= PageSizeReport structure
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/ 2/92   	Initial version
	JT	4/ 7/92		Modified to set background type
	JT	5/14/92		Modified for text object
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentPrintReportPageSize	method dynamic NTakerDocumentClass, 
					MSG_PRINT_REPORT_PAGE_SIZE
	.enter
EC <	call	EnsureIsPenMode						>

;
;	The user should only be able to do this in pen mode
;

	mov	bx, ds:[di].GDI_fileHandle


	push	ds, si
	segmov	ds, ss
	mov	si, bp
	call	InkSetDocPageInfo
	pop	ds, si

	mov	cx, ss:[bp].PSR_width.low
	mov	dx, ss:[bp].PSR_height.low
	sub	cx, ss:[bp].PSR_margins.PCMP_left
EC <	ERROR_C	INVALID_MARGINS						>
	sub	cx, ss:[bp].PSR_margins.PCMP_right
EC <	ERROR_C	INVALID_MARGINS						>
	sub	dx, ss:[bp].PSR_margins.PCMP_top
EC <	ERROR_C	INVALID_MARGINS						>
	sub	dx, ss:[bp].PSR_margins.PCMP_bottom
EC <	ERROR_C	INVALID_MARGINS						>


	call	NTakerDocDeref_DSDI
	mov	si, ds:[di].NDOCI_inkObj
	call	ChangeDocumentSize
	.leave
	ret
NTakerDocumentPrintReportPageSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentBackgroundSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the message sent out when the user selects a new
		BG.

CALLED BY:	GLOBAL
PASS:		cx - InkBackgroundType
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentBackgroundSelected	method	NTakerDocumentClass,
					MSG_NTAKER_DOC_BACKGROUND_SELECTED
	.enter
EC <	call	EnsureIsPenMode						>
	call	NTakerDocGetInkObj		;*ds:bp = Ink object
	mov	bx, ds:[di].GDI_fileHandle
	mov	ax, cx
	call	InkSetDocGString

	mov_tr	cx, ax				;cx = InkBackgroundType
	cmp	cx, IBT_CUSTOM_BACKGROUND
	jne 	common

	call 	GetCustomGStringHandle		;ax = Custom GString Vmem handle

common:	
	mov	si, bp
	mov_tr	dx, ax			;dx = Custom GString Vmem handle
	mov	ax, MSG_NTAKER_INK_SET_BACKGROUND
	call	ObjCallInstanceNoLock
	.leave
	ret
NTakerDocumentBackgroundSelected	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCustomGStringHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get GString handle
CALLED BY:	INTERNAL
PASS:		bx - database file handle
RETURN:		ax - custom GString
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	6/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCustomGStringHandle	proc	near	uses	cx,si
	.enter

	call	InkGetDocCustomGString		;ax = Custom GString Vmem handle
EC <	tst	ax							>
EC <	ERROR_Z	-1							>
	mov_tr	si, ax
	mov	cx, GST_VMEM
	call	GrLoadGString
	mov_tr	ax, si

	.leave
	ret
GetCustomGStringHandle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentCustomBackgroundPaste
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Get GStrings from the clipboard and paste it to the document
CALLED BY:	GLOBAL
PASS:		*ds:si	= NTakerDocumentClass object
		ds:di	= NTakerDocumentClass instance data
		ds:bx	= NTakerDocumentClass object (same as *ds:si)
		es 	= dgroup
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	4/16/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentCustomBackgroundPaste	method dynamic NTakerDocumentClass, 
					MSG_NTAKER_DOC_CUSTOM_BACKGROUND_PASTE
	dbFileHan	local	word
	vmBlockHan	local	word
	docSI		local	word
	docDS		local	word
	.enter

EC <	call	EnsureIsPenMode						>

	push	bp
	mov	bx, ds:[di].GDI_fileHandle	;bx <= Database file handle
	mov	dbFileHan, bx
	mov	docDS, ds
	mov	docSI, si

;	ClipboardQueryItem:
;	PASS:
;	bp - ClipboardItemFlags (for quick/normal)
;	RETURN:
;	bp - number of formats available (0 if no transfer item)
;	cx:dx - owner of transfer item
;	bx:ax - (VM file handle):(VM block handle) to transfer item header
;			(pass to ClipboardRequestItemFormat)

	clr	bp			;Get normal transfer item
	call	ClipboardQueryItem
	push	ax, bx			;save VM file handle and block handle
	tst	bp
	LONG	jz finishTransfer	

;	ClipboardRequestItemFormat:
;	PASS:
;	cx:dx - format manufacturer:format type
;	bx:ax = transfer item header (returned by ClipboardQueryItem)
;	RETURN:
;	bx - file handle of transfer item
;	ax:bp - VM chain (0 if none)
;	cx - extra data word 1
;	dx - extra data word 2

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_GRAPHICS_STRING
	call	ClipboardRequestItemFormat

;		GrLoadGString
;		PASS:cl	- type of handle passed in bx (enum GStringType):
;			  GST_VMEM		- VMem file handle
;     		     bx - handle to file where gstring is stored
;		     si - vmem block handle of gstring beginning
;		RETURN:	si- handle of graphics string

	tst	ax
	LONG je	finishTransfer		;no transfer item

	;load source gstring
	push	cx, dx
	mov_tr	si, ax			;si = vmem block handle of string
					;beginning
	mov	cx, GST_VMEM
	call	GrLoadGString		;return si = GString handle of the 
					;source transfer item
	pop	cx, dx

;	VMAlloc
;	PASS:
;		bx - VM file handle, unless ss:TPD_vmFile  is
;		     non-zero, in which case ss:TPD_vmFile is used.
;		ax - user specified id.
;		cx - number of bytes (may be 0, in which case no associated
;		     memory is allocated; memory must be allocated separately
;		     and given to the block with VMAttach)
;	RETURN:
;		ax - VM block handle, marked dirty if memory actually allocated

	pop	cx, bx			;restore VM file handle/ block handle
	pop	bp			;restore local variable
	push	bp
	push	cx, bx			;save VM file handle and block handle

	;allocate a block in the document file (VM file) to store GString 
	;destination GString
	mov	bx, dbFileHan

	;Free up the previous VM chain if any
	call	InkGetDocCustomGString
	tst	ax
	jz	setNewCustomGString

	push	di
	mov	di, ax
	call	HugeArrayDestroy	;pass: bx - VMfile handle
					;      dx - HugeArray dir block handle
	pop	di

setNewCustomGString:
					;     ax = VM block handle

	;Create destination GString
	push	si			;save source GString handle
	mov	cx, GST_VMEM		
	call	GrCreateGString		;DI <- new gstring to draw to
	mov	vmBlockHan, si

	;save the VM block handle for the GString in the Map block
	mov	ax, si
	call	InkSetDocCustomGString	;pass bx = database handle	
	pop	si			;SI <- source gstring

	;Copy source GString to destination GString
	clr	dx			;no contrl flags
	call	GrCopyGString		;pass si = source gstring
					;     di = destination gstring
	call	GrEndGString		;End the gstring

	;Destroy the source gstring
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString	

	;Destroy the dest gstring and exit
	mov	si, di			;SI <- gstring to kill
	clr	di			;DI <- GState = NULL
	mov	dl, GSKT_LEAVE_DATA
	call	GrDestroyGString

	;enable the Custom background GenListEntry
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	GetResourceHandleNS CustomBackgroundEntry, bx
	mov	si, offset CustomBackgroundEntry
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

finishTransfer:
	pop	ax, bx
	call	ClipboardDoneWithItem
	pop	bp

	mov	bx, dbFileHan
	call	InkGetDocGString
	mov_tr	cx, ax
	cmp	cx, IBT_CUSTOM_BACKGROUND
	jne	done
	call	GetCustomGStringHandle

	push	bp
	mov	ds, docDS
	mov	si, docSI
	call	NTakerDocGetInkObj
	mov	si, bp
	mov_tr	dx, ax
	mov	ax, MSG_NTAKER_INK_SET_BACKGROUND
	call	ObjCallInstanceNoLock
	pop	bp

done:	
	.leave
	ret
NTakerDocumentCustomBackgroundPaste	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentNextCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the next card

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerDocument obj
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentNextCard	method	dynamic NTakerDocumentClass, MSG_NTAKER_DOC_NEXT_CARD
	.enter
	call	SaveCurrentNoteIfNeeded
	call	GetNoteInfo
	jnc	getFirstNote
	dec	dx				;DX <- index of last note
						;CX <- index of first note
	inc	ax				;AX <- index of cur note+1
	cmp	ax, dx
	ja	setSelection
	mov_tr	cx, ax
setSelection:
	mov	ax, MSG_NTAKER_DOC_CHANGE_NOTE
	call	ObjCallInstanceNoLock
	call	SelectCurrentNoteInNoteList
exit:
	.leave
	ret
getFirstNote:
	cmp	cx, dx
	jz	exit				;Exit if no notes
	jmp	setSelection
NTakerDocumentNextCard	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNoteInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the note information.

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerDoc object
RETURN:		ax - current selection number (meaningless if carry clear)
		bx - file handle
		cx - # folders
		dx - total # notes + # folders
		carry set if current selection is note
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNoteInfo	proc	near		uses	di
	class	NTakerDocumentClass
	.enter
	call	NTakerDocGetFileHandle
	call	NTakerDocDeref_DSDI
	movdw	dxcx, ds:[di].NDOCI_curNote
	tst_clc	dx
	jnz	haveNote
	jcxz	noCurrentNote
haveNote:
	call	NTakerDocGetCurFolder
	call	InkFolderGetChildNumber		;Returns AX = index of note
	stc
noCurrentNote:
	pushf
	push	ax
	call	NTakerDocGetCurFolder
	call	InkFolderGetNumChildren		;CX <- # sub folders
						;DX <- # notes
	pop	ax
	add	dx, cx				;DX <- total # notes
	popf
	.leave
	ret
GetNoteInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentPrevCard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the prev card

CALLED BY:	GLOBAL
PASS:		*ds:si - NTakerDocument obj
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 2/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentPrevCard	method	dynamic NTakerDocumentClass, MSG_NTAKER_DOC_PREV_CARD
	.enter
	call	SaveCurrentNoteIfNeeded
	call	GetNoteInfo
	jnc	getLastNote
	cmp	ax, cx
	jnz	10$
	mov	cx, dx
	dec	cx				;CX <- index of last note
	jmp	setSelection
10$:
	dec	ax
	mov_tr	cx, ax				;CX <- selection to set
setSelection:
	mov	ax, MSG_NTAKER_DOC_CHANGE_NOTE
	call	ObjCallInstanceNoLock
	call	SelectCurrentNoteInNoteList
exit:
	.leave
	ret
getLastNote:
	cmp	cx, dx
	jz	exit			;Exit if no notes
	mov	cx, dx
	dec	cx
	jmp	setSelection
NTakerDocumentPrevCard	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentChangeFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reflect the changed document features.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentChangeFeatures	method	NTakerDocumentClass,
				MSG_NTAKER_DOC_CHANGE_FEATURES
	.enter
	call	NTakerDocGetFileHandle
	call	InkDBGetHeadFolder
	call	NTakerDocSetCurFolder
	call	NTakerDocSetNilNote
	mov	cx, -1
	call	ResetMonikersAndSelectCurrentNote
	.leave
	ret
NTakerDocumentChangeFeatures	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentTextLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When the title text loses the focus, we save the document on
		the off chance that the title has changed, in which case we
		need to update the display.	

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentTextLostFocus	method NTakerDocumentClass,
				MSG_META_TEXT_LOST_FOCUS
	.enter

;	If we are doing a rename (or something similar) that does a DETACH_UI
;	without doing a DESTROY_UI, we want to ignore this save message

	cmp	ds:[di].NDOCI_inkObj, NO_OBJ
	je	exit
	cmp	ds:[di].NDOCI_textObj, NO_OBJ
	je	exit

	call	NTakerDocGetHandleOfDisplayBlock	;If we've already
	tst	bx					; closed the display,
	jz	exit					; just exit
	cmp	dx, offset CardTitle
	jne	exit

;	When the title text object loses the focus, save the current note -
;	this will update the title in the card list.

	call	SaveCurrentNoteIfNeeded
exit:
	.leave
	ret
NTakerDocumentTextLostFocus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NTakerDocumentSetViewType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the view type for the document.

CALLED BY:	GLOBAL
PASS:		cx - ViewType
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NTakerDocumentSetViewType	method	NTakerDocumentClass,
				MSG_NTAKER_DOC_SET_VIEW_TYPE
	.enter
	cmp	cx, VT_CARD
	jnz	sendToDisplay

;
;	We are switching to View mode - ensure that the current selection is
;	a card, if any exist
;
	push	cx, si
	call	GetNoteInfo
       	jc	10$			;Branch if current selection is note
	cmp	cx, dx			;If no notes, branch
	jz	10$

;	Select the first note in the list

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	NTakerDocGetHandleOfDisplayBlock
	mov	si, offset CardList
	clr	dx
	clr	di
	call	ObjMessage 
	call	ForceApplyOnList
10$:
	pop	cx, si
sendToDisplay:
	mov	ax, MSG_NTAKER_DISPLAY_SET_VIEW_TYPE
	call	SendToDisplay
	.leave
	ret
NTakerDocumentSetViewType	endp


DocumentCode	ends		;end of CommonCode resource
