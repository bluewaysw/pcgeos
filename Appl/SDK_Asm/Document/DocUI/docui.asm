COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		DocUI (Sample PC GEOS application)
FILE:		docui.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the DocUI application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: docui.asm,v 1.1 97/04/04 16:33:07 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include vm.def

include object.def
include graphics.def

include Objects/winC.def

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib ui.def

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

DUIProcessClass	class	GenProcessClass
;
;	Handle a change in the GenValue for the X value (sent by GenValue)
;
; Pass:
;	cx - value
; Return:
;	none

DUIProcessClass	endc

idata	segment
	DUIProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;----------------------

; DUIDocument class is our subclass of GenDocument that we use to add
; behavior to the GenDocument

DUIDocumentClass	class	GenDocumentClass

MSG_DUI_DOCUMENT_X_CHANGE	message
MSG_DUI_DOCUMENT_Y_CHANGE	message

DUIDocumentClass endc

idata	segment
	DUIDocumentClass
idata	ends

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

DOCUMENT_PROTOCOL_MAJOR	=	1
DOCUMENT_PROTOCOL_MINOR	=	0

DOCUMENT_WIDTH		=	20*72
DOCUMENT_HEIGHT		=	20*72

INITIAL_X_POS		= 20
INITIAL_Y_POS		= 20

; This is the structure of a datafile.  It is incredibly simple, storing just
; a x,y position

DUIMapBlock	struct
    DUIMB_xPos	word
    DUIMB_yPos	word
DUIMapBlock	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		docui.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for DUIDocumentClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	DUIDocumentInitializeDocumentFile --
		MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE for DUIDocumentClass

DESCRIPTION:	Initialize the document file (newly created).

PASS:
	*ds:si - instance data
	es - segment of DUIDocumentClass

	ax - The message

	cx:dx - optr of document
	bp - file handle

RETURN:
	carry - set if error

DESTROYED:
	bx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

	This message is invoked when a new document has been created and
	the document file needs to be initialized.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
DUIDocumentInitializeDocumentFile	method dynamic	DUIDocumentClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	; Handle this message by creating our version of an empty
	; document, which is a map block with the DUIMapBlock structure
	; in it and initialized to default values.

	mov	bx, ds:[di].GDI_fileHandle		;save file handle

	; Allocate a VM block (making it the size of the structure
	; that we want to save in it) and set that block to be the
	; map block

	; allocate a block, make it the map block and initialize it

	mov	cx, size DUIMapBlock
	call	VMAlloc				;ax = VM block handle
	call	VMSetMapBlock			;make this the map block

	; Lock the newly created block so that we can use it.  Since we
	; are modifying the contents of the block it is essential that we
	; call VMDirty to let the VM code know that the block is modified.

	call	VMLock				;ax = segment, bp = handle
	call	VMDirty				;we're changing the block...
	mov	ds, ax				;ds = block
	mov	ds:DUIMB_xPos, INITIAL_X_POS
	mov	ds:DUIMB_yPos, INITIAL_Y_POS

	call	VMUnlock

	clc			;no error
	ret

DUIDocumentInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	DUIDocumentAttachUIToDocument --
		MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT for DUIDocumentClass

DESCRIPTION:	Update the UI

PASS:
	*ds:si - instance data
	es - segment of DUIDocumentClass

	ax - The message

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/30/91		Initial version

------------------------------------------------------------------------------@
DUIDocumentAttachUIToDocument	method dynamic	DUIDocumentClass,
				MSG_GEN_DOCUMENT_ATTACH_UI_TO_DOCUMENT

	call	UpdateUIForDocument
	ret

DUIDocumentAttachUIToDocument	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateUIForDocument

DESCRIPTION:	Update the UI components for the document

CALLED BY:	INTERNAL

PASS:
	*ds:si - DUIDocument object

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
UpdateUIForDocument	proc	near	uses si
	class	DUIDocumentClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	bx, ds:[di].GDI_fileHandle		;save file handle

	; get position from data file

	call	VMGetMapBlock
	call	VMLock
	mov	ds, ax			;ds = map block
	mov	cx, ds:DUIMB_xPos
	mov	dx, ds:DUIMB_yPos
	call	VMUnlock

	; set the X value

	GetResourceHandleNS	DUIValueX, bx
	mov	si, offset DUIValueX
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp				;not indeterminate
	clr	di
	call	ObjMessage

	; set the Y value

	mov	cx, dx				;cx = y value
	GetResourceHandleNS	DUIValueY, bx
	mov	si, offset DUIValueY
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp				;not indeterminate
	clr	di
	call	ObjMessage

	.leave
	ret

UpdateUIForDocument	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	DUIDocumentChange -- MSG_DUI_DOCUMENT_X_CHANGE and
				MSG_DUI_DOCUMENT_Y_CHANGE for DUIDocumentClass

DESCRIPTION:	Handle change in the X or the Y value

PASS:
	*ds:si - instance data
	es - segment of DUIDocumentClass

	ax - The message

	dx - new value

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
DUIDocumentChange	method dynamic	DUIDocumentClass,
					MSG_DUI_DOCUMENT_X_CHANGE,
					MSG_DUI_DOCUMENT_Y_CHANGE
	uses	cx
	.enter

	mov	cx, ax			;cx saves the message
	mov	bx, ds:[di].GDI_fileHandle
	call	VMGetMapBlock
	call	VMLock
	call	VMDirty
	mov	ds, ax			;ds = map block
	cmp	cx, MSG_DUI_DOCUMENT_Y_CHANGE
	jz	yChange
	mov	ds:DUIMB_xPos, dx
	jmp	common
yChange:
	mov	ds:DUIMB_yPos, dx
common:
	call	VMUnlock

	.leave
	ret

DUIDocumentChange	endm

CommonCode	ends		;end of CommonCode resource
