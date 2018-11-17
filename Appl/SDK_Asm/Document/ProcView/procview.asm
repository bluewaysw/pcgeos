COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		ProcView (Sample PC GEOS application)
FILE:		procview.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the ProcView application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: procview.asm,v 1.1 97/04/04 16:32:55 newdeal Exp $

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

PVProcessClass	class	GenProcessClass

;define messages for this class here.

PVProcessClass	endc

idata	segment
	PVProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

DOCUMENT_PROTOCOL_MAJOR	=	1
DOCUMENT_PROTOCOL_MINOR	=	0

DOCUMENT_WIDTH		=	20*72
DOCUMENT_HEIGHT		=	20*72

VIEW_BACKGROUND_COLOR	=	C_WHITE

INITIAL_X_POS		= 20
INITIAL_Y_POS		= 20

BOX_WIDTH		= 10
BOX_HEIGHT		= 10

; This is the structure of a datafile.  It is incredibly simple, storing just
; a x,y position

PVMapBlock	struct
    PVMB_xPos	word
    PVMB_yPos	word
PVMapBlock	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

ourFile	hptr	0

ourWindow	hptr	0

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		procview.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for PVProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessInitializeDocumentFile --
		MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE for PVProcessClass

DESCRIPTION:	Initialize the document file (newly created).

PASS:
	ds - dgroup
	es - segment of PVProcessClass

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
PVProcessInitializeDocumentFile	method dynamic	PVProcessClass,
					MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE

	; Handle this message by creating our version of an empty
	; document, which is a map block with the PVMapBlock structure
	; in it and initialized to default values.

	mov	bx, bp				;bx = VM file

	; Allocate a VM block (making it the size of the structure
	; that we want to save in it) and set that block to be the
	; map block

	; allocate a block, make it the map block and initialize it

	mov	cx, size PVMapBlock
	call	VMAlloc				;ax = VM block handle
	call	VMSetMapBlock			;make this the map block

	; Lock the newly created block so that we can use it.  Since we
	; are modifying the contents of the block it is essential that we
	; call VMDirty to let the VM code know that the block is modified.

	call	VMLock				;ax = segment, bp = handle
	call	VMDirty				;we're changing the block...
	mov	ds, ax				;ds = block
	mov	ds:PVMB_xPos, INITIAL_X_POS
	mov	ds:PVMB_yPos, INITIAL_Y_POS

	call	VMUnlock

	clc			;no error
	ret

PVProcessInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessAttachUIToDocument --
		MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT for PVProcessClass

DESCRIPTION:	Save the file handle for later

PASS:
	ds - dgroup
	es - segment of PVProcessClass

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
PVProcessAttachUIToDocument	method dynamic	PVProcessClass,
					MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT

	; Since our UI always stay the same we just need to save the file
	; handle and redraw our window to reflect the document that we
	; are now attached to.

	mov	ds:[ourFile], bp
	call	ClearAndDrawDocument
	ret

PVProcessAttachUIToDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessDetachUIFromDocument --
		MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT for PVProcessClass

DESCRIPTION:	Zero the file handle

PASS:
	ds - dgroup
	es - segment of PVProcessClass

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
PVProcessDetachUIFromDocument	method dynamic	PVProcessClass,
					MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT

	; Detach ourselves from the document by severing our only link to it,
	; our storage of the file handle

	mov	ds:[ourFile], 0
	call	ClearAndDrawDocument
	ret

PVProcessDetachUIFromDocument	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessSaveAsCompleted -- MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
						for PVProcessClass

DESCRIPTION:	Notification that SaveAs has completed (and thus the
		file handle has changed)

PASS:
	ds - dgroup
	es - segment of PVProcessClass

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
PVProcessSaveAsCompleted	method dynamic	PVProcessClass,
						MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED

	; "save as" causes a new file to be created and causes the file
	;handle to change.  Therefore we must store the new file handle

	mov	ds:[ourFile], bp
	ret

PVProcessSaveAsCompleted	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessExposed -- MSG_META_EXPOSED for PVProcessClass

DESCRIPTION:	Handle window exposure

PASS:
	ds - dgroup
	es - segment of PVProcessClass

	ax - The message

	cx - window handle

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
	Tony	7/21/91		Initial version

------------------------------------------------------------------------------@
PVProcessExposed	method dynamic	PVProcessClass, MSG_META_EXPOSED

	mov	di, cx			;set ^hdi = window handle
	call	GrCreateState		;Get a default gstate for drawing
	call	GrBeginUpdate		;Start a window update

	; draw the document

	call	DrawDocument

	call	GrEndUpdate		;end the window update
	call	GrDestroyState		;free the gstate

	ret

PVProcessExposed	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessViewWinOpened

DESCRIPTION:	Handle notification that a view window has been created
		by saving the window handle

PASS:
	ds - dgroup
	es - segment of PVProcessClass

	ax - The message

	cx - width of view
	dx - height of view
	bp - window handle

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
	Tony	7/22/91		Initial version

------------------------------------------------------------------------------@
PVProcessViewWinOpened	method dynamic	PVProcessClass,
					MSG_META_CONTENT_VIEW_WIN_OPENED
	mov	ds:[ourWindow], bp
	mov	di, offset PVProcessClass
	call	ObjCallSuperNoLock
	ret

PVProcessViewWinOpened	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessViewWinClosed --

DESCRIPTION:	Handle notification that the window has gone away

PASS:
	ds - dgroup
	es - segment of PVProcessClass

	ax - The message

	bp - window handle

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
	Tony	7/22/91		Initial version

------------------------------------------------------------------------------@
PVProcessViewWinClosed	method dynamic	PVProcessClass,
					MSG_META_CONTENT_VIEW_WIN_CLOSED
	clr	ds:[ourWindow]
	mov	di, offset PVProcessClass
	call	ObjCallSuperNoLock
	ret

PVProcessViewWinClosed	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	PVProcessStartSelect -- MSG_META_START_SELECT for PVProcessClass

DESCRIPTION:	Handle click in view

PASS:
	ds - dgroup
	es - segment of PVProcessClass

	ax - The message

	cx - x position
	dx - y position
	bp - UIFunctionsActive

RETURN:
	ax - MouseReturnFlags

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
PVProcessStartSelect	method dynamic	PVProcessClass, MSG_META_START_SELECT

	mov	bx, ds:[ourFile]
	tst	bx
	jz	done

	push	ds
	call	VMGetMapBlock
	call	VMLock
	call	VMDirty
	mov	ds, ax			;ds = map block
	mov	ds:PVMB_xPos, cx
	mov	ds:PVMB_yPos, dx

	call	VMUnlock
	pop	ds

	call	ClearAndDrawDocument

done:
	mov	ax, mask MRF_PROCESSED
	ret

PVProcessStartSelect	endm

COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawDocument

DESCRIPTION:	Draw the document

CALLED BY:	INTERNAL

PASS:
	ds - dgroup
	di - gstate

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/21/91		Initial version

------------------------------------------------------------------------------@
DrawDocument	proc	near	uses bp, ds
	.enter

	; get the VM file and see if we have a file open

	mov	bx, ds:[ourFile]
	tst	bx
	jz	done

	mov	ax, C_LIGHT_BLUE
	call	GrSetAreaColor

	; get position from data file

	call	VMGetMapBlock
	call	VMLock
	mov	ds, ax			;ds = map block
	mov	ax, ds:PVMB_xPos
	mov	bx, ds:PVMB_yPos
	mov	cx, ax
	mov	dx, bx

	; center rectangle around the point

	sub	ax, BOX_WIDTH/2
	sub	bx, BOX_HEIGHT/2
	add	cx, BOX_WIDTH/2
	add	dx, BOX_HEIGHT/2
	call	GrFillRect

	call	VMUnlock

done:
	.leave
	ret

DrawDocument	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ClearAndDrawDocument

DESCRIPTION:	Clear the view and redraw the document

CALLED BY:	INTERNAL

PASS:
	ds - dgroup

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/21/91		Initial version

------------------------------------------------------------------------------@

ClearAndDrawDocument	proc	near	uses di
	.enter

	; if the window does not exist then don't draw anything

	mov	di, ds:[ourWindow]
	tst	di
	jz	done

	call	GrCreateState

	; clear the window

	mov	ax, VIEW_BACKGROUND_COLOR
	call	GrSetAreaColor

	mov	ax, MIN_COORD
	mov	bx, MIN_COORD
	mov	cx, MAX_COORD
	mov	dx, MAX_COORD
	call	GrFillRect

	; draw the document

	call	DrawDocument

	call	GrDestroyState

done:
	.leave
	ret

ClearAndDrawDocument	endp

CommonCode	ends		;end of CommonCode resource
