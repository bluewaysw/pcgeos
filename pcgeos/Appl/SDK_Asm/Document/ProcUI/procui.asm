COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ProcUI (Sample PC GEOS application)
FILE:		procui.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the ProcUI application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: procui.asm,v 1.1 97/04/04 16:33:02 newdeal Exp $

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

PUIProcessClass	class	GenProcessClass

MSG_PUI_PROCESS_X_CHANGE	message
MSG_PUI_PROCESS_Y_CHANGE	message
;
;	Handle a change in the GenValue for the X value (sent by GenValue)
;
; Pass:
;	cx - value
; Return:
;	none

PUIProcessClass	endc

idata	segment
	PUIProcessClass	mask CLASSF_NEVER_SAVED
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

PUIMapBlock	struct
    PUIMB_xPos	word
    PUIMB_yPos	word
PUIMapBlock	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

ourFile	hptr	0

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		procui.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for PUIProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	PUIProcessInitializeDocumentFile --
		MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE for PUIProcessClass

DESCRIPTION:	Initialize the document file (newly created).

PASS:
	ds - dgroup
	es - segment of PUIProcessClass

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
PUIProcessInitializeDocumentFile	method dynamic	PUIProcessClass,
					MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE

	; Handle this message by creating our version of an empty
	; document, which is a map block with the PUIMapBlock structure
	; in it and initialized to default values.

	mov	bx, bp				;bx = VM file

	; Allocate a VM block (making it the size of the structure
	; that we want to save in it) and set that block to be the
	; map block

	; allocate a block, make it the map block and initialize it

	mov	cx, size PUIMapBlock
	call	VMAlloc				;ax = VM block handle
	call	VMSetMapBlock			;make this the map block

	; Lock the newly created block so that we can use it.  Since we
	; are modifying the contents of the block it is essential that we
	; call VMDirty to let the VM code know that the block is modified.

	call	VMLock				;ax = segment, bp = handle
	call	VMDirty				;we're changing the block...
	mov	ds, ax				;ds = block
	mov	ds:PUIMB_xPos, INITIAL_X_POS
	mov	ds:PUIMB_yPos, INITIAL_Y_POS

	call	VMUnlock

	clc			;no error
	ret

PUIProcessInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PUIProcessAttachUIToDocument --
		MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT for PUIProcessClass

DESCRIPTION:	Save the file handle for later

PASS:
	ds - dgroup
	es - segment of PUIProcessClass

	ax - The message

	cx:dx - optr of document
	bp - file handle

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
PUIProcessAttachUIToDocument	method dynamic	PUIProcessClass,
					MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT

	; Since our UI always stay the same we just need to save the file
	; handle and redraw our window to reflect the document that we
	; are now attached to.

	mov	ds:[ourFile], bp
	call	UpdateUIForDocument
	ret

PUIProcessAttachUIToDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PUIProcessDetachUIFromDocument --
		MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT for PUIProcessClass

DESCRIPTION:	Zero the file handle

PASS:
	ds - dgroup
	es - segment of PUIProcessClass

	ax - The message

	cx:dx - optr of document
	bp - file handle

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
	Tony	7/23/91		Initial version

------------------------------------------------------------------------------@
PUIProcessDetachUIFromDocument	method dynamic	PUIProcessClass,
					MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT

	; Detach ourselves from the document by severing our only link to it,
	; our storage of the file handle

	mov	ds:[ourFile], 0
	ret

PUIProcessDetachUIFromDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PUIProcessSaveAsCompleted -- MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
						for PUIProcessClass

DESCRIPTION:	Notification that SaveAs has completed (and thus the
		file handle has changed)

PASS:
	ds - dgroup
	es - segment of PUIProcessClass

	ax - The message

	cx:dx - optr of document
	bp - file handle

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
	Tony	7/24/91		Initial version

------------------------------------------------------------------------------@
PUIProcessSaveAsCompleted	method dynamic	PUIProcessClass,
						MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED

	; "save as" causes a new file to be created and causes the file
	;handle to change.  Therefore we must store the new file handle

	mov	ds:[ourFile], bp
	ret

PUIProcessSaveAsCompleted	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	UpdateUIForDocument

DESCRIPTION:	Update the UI components for the document

CALLED BY:	INTERNAL

PASS:
	ds - dgroup

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/25/91		Initial version

------------------------------------------------------------------------------@
UpdateUIForDocument	proc	near

	mov	bx, ds:[ourFile]

	; get position from data file

	call	VMGetMapBlock
	call	VMLock
	mov	ds, ax			;ds = map block
	mov	cx, ds:PUIMB_xPos
	mov	dx, ds:PUIMB_yPos
	call	VMUnlock

	; set the X value

	GetResourceHandleNS	PUIValueX, bx
	mov	si, offset PUIValueX
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp				;not indeterminate
	clr	di
	call	ObjMessage

	; set the Y value

	mov	cx, dx				;cx = y value
	GetResourceHandleNS	PUIValueY, bx
	mov	si, offset PUIValueY
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp				;not indeterminate
	clr	di
	call	ObjMessage

	ret

UpdateUIForDocument	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	PUIProcessChange -- MSG_PUI_PROCESS_X_CHANGE and
				MSG_PUI_PROCESS_Y_CHANGE for PUIProcessClass

DESCRIPTION:	Handle change in the X or the Y value

PASS:
	*ds:si - instance data
	es - segment of PUIProcessClass

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
PUIProcessChange	method dynamic	PUIProcessClass,
					MSG_PUI_PROCESS_X_CHANGE,
					MSG_PUI_PROCESS_Y_CHANGE
	uses	cx
	.enter

	mov	cx, ax			;cx saves the message
	mov	bx, ds:[ourFile]
	tst	bx
	jz	done

	call	VMGetMapBlock
	call	VMLock
	call	VMDirty
	mov	ds, ax			;ds = map block
	cmp	cx, MSG_PUI_PROCESS_Y_CHANGE
	jz	yChange
	mov	ds:PUIMB_xPos, dx
	jmp	common
yChange:
	mov	ds:PUIMB_yPos, dx
common:
	call	VMUnlock

done:
	.leave
	ret

PUIProcessChange	endm

CommonCode	ends		;end of CommonCode resource
