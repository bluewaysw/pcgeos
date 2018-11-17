COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		SharedDB (Sample PC GEOS application)
FILE:		shareddb.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	tony	7/91		Initial version

DESCRIPTION:
	This file source code for the SharedDB application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

IMPORTANT NOTE:
	This sample application is primarily intended to demonstrate a
	model for handling documents.  Basic parts of a PC/GEOS application
	are not documented heavily here.  See the "Hello" sample application
	for more detailed documentation on the standard parts of a PC/GEOS
	application.

RCS STAMP:
	$Id: shareddb.asm,v 1.1 97/04/04 16:33:17 newdeal Exp $

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

SDBProcessClass	class	GenProcessClass

;define messages for this class here.

SDBProcessClass	endc

idata	segment
	SDBProcessClass	mask CLASSF_NEVER_SAVED
idata	ends

;----------------------

; SDBDocument class is our subclass of GenDocument that we use to add
; behavior to the GenDocument

SDBDocumentClass	class	GenDocumentClass

SDBDocumentClass endc

idata	segment
	SDBDocumentClass
idata	ends

;------------------------------------------------------------------------------
;			Constants and structures
;------------------------------------------------------------------------------

DOCUMENT_PROTOCOL_MAJOR	=	1
DOCUMENT_PROTOCOL_MINOR	=	0

DOCUMENT_WIDTH		=	20*72
DOCUMENT_HEIGHT		=	20*72

OBJECT_BACKGROUND_COLOR	=	C_WHITE

INITIAL_X_POS		= 20
INITIAL_Y_POS		= 20

BOX_WIDTH		= 10
BOX_HEIGHT		= 10

; This is the structure of a datafile.  It is incredibly simple, storing just
; a x,y position

SDBMapBlock	struct
    SDBMB_xPos	word
    SDBMB_yPos	word
SDBMapBlock	ends

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

idata	ends

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		shareddb.rdef		;include compiled UI definitions

;------------------------------------------------------------------------------
;		Code for SDBProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	SDBDocumentRecalcSize -- MSG_VIS_RECALC_SIZE
							for SDBDocumentClass

DESCRIPTION:	Calculate and return our size

PASS:
	*ds:si - instance data
	es - segment of SDBDocumentClass

	ax - The message

	cx - RecalcSizeArgs
	dx - RecalcSizeArgs

RETURN:
	cx - width
	dx - height

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
SDBDocumentRecalcSize	method dynamic	SDBDocumentClass, MSG_VIS_RECALC_SIZE
	mov	cx, DOCUMENT_WIDTH
	mov	dx, DOCUMENT_HEIGHT
	ret

SDBDocumentRecalcSize	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	SDBDocumentInitializeDocumentFile --
		MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE for SDBDocumentClass

DESCRIPTION:	Initialize the document file (newly created).

PASS:
	*ds:si - instance data
	es - segment of SDBDocumentClass

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
SDBDocumentInitializeDocumentFile	method dynamic	SDBDocumentClass,
				MSG_GEN_DOCUMENT_INITIALIZE_DOCUMENT_FILE

	; Handle this message by creating our version of an empty
	; document, which is a map block with the SDBMapBlock structure
	; in it and initialized to default values.

	mov	bx, ds:[di].GDI_fileHandle

	; Allocate a VM block (making it the size of the structure
	; that we want to save in it) and set that block to be the
	; map block

	; allocate a block, make it the map block and initialize it

	mov	cx, size SDBMapBlock
	call	VMAlloc				;ax = VM block handle
	call	VMSetMapBlock			;make this the map block

	; Lock the newly created block so that we can use it.  Since we
	; are modifying the contents of the block it is essential that we
	; call VMDirty to let the VM code know that the block is modified.

	call	VMLock				;ax = segment, bp = handle
	call	VMDirty				;we're changing the block...
	mov	ds, ax				;ds = block
	mov	ds:SDBMB_xPos, INITIAL_X_POS
	mov	ds:SDBMB_yPos, INITIAL_Y_POS

	call	VMUnlock

	clc
	ret

SDBDocumentInitializeDocumentFile	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	SDBDocumentDraw -- MSG_VIS_DRAW for SDBDocumentClass

DESCRIPTION:	Draw ourselves

PASS:
	*ds:si - instance data
	es - segment of SDBDocumentClass

	ax - The message

	cl - DrawFlags
	bp - gstate

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
SDBDocumentDraw	method dynamic	SDBDocumentClass, MSG_VIS_DRAW

	push	ds:[di].GDI_fileHandle		;save file handle

	mov	di, bp				;di = gstate

	; if we were not called as the result of a MSG_META_EXPOSED, then we need
	; to clear the object first

	test	cl, mask DF_EXPOSED
	jnz	noClear
	mov	ax, OBJECT_BACKGROUND_COLOR
	call	GrSetAreaColor
	call	VisGetBounds
	call	GrFillRect
noClear:

	mov	ax, C_LIGHT_BLUE
	call	GrSetAreaColor

	; get position from data file -- get exclusive access to the file
	; to do this

	pop	bx				;bx = file handle
	push	bx

	mov	ax, VMO_READ
	clr	cx				;no timeout
	call	VMGrabExclusive

	call	VMGetMapBlock
	call	VMLock
	mov	ds, ax				;ds = map block
	mov	ax, ds:SDBMB_xPos
	mov	bx, ds:SDBMB_yPos
	mov	cx, ax
	mov	dx, bx

	; center rectangle around the point

	sub	ax, BOX_WIDTH/2
	sub	bx, BOX_HEIGHT/2
	add	cx, BOX_WIDTH/2
	add	dx, BOX_HEIGHT/2
	call	GrFillRect

	call	VMUnlock

	pop	bx
	call	VMReleaseExclusive

	ret

SDBDocumentDraw	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	SDBDocumentStartSelect -- MSG_META_START_SELECT for SDBDocumentClass

DESCRIPTION:	Handle click in object

PASS:
	*ds:si - instance data
	es - segment of SDBDocumentClass

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
SDBDocumentStartSelect	method dynamic	SDBDocumentClass, MSG_META_START_SELECT

	mov	bx, ds:[di].GDI_fileHandle
	push	bx

	push	cx
	mov	ax, VMO_WRITE
	clr	cx				;no timeout
	call	VMGrabExclusive
	pop	cx
	cmp	ax, VMSERV_CHANGES
	jnz	noChanges

	; The file has changed, alert the user

	push	bx, cx, dx
	sub	sp, size StandardDialogOptrParams
	mov	bp, sp
	mov	ss:[bp].SDOP_customFlags, \
		   CustomDialogBoxFlags <0, CDT_NOTIFICATION, GIT_AFFIRMATION,0>
	mov	ss:[bp].SDOP_customString.handle, handle fileChangedString
	mov	ss:[bp].SDOP_customString.chunk, offset fileChangedString
	clr	ax				;none of these are passed
	mov	ss:[bp].SDOP_stringArg1.handle, ax
	mov	ss:[bp].SDOP_stringArg2.handle, ax
	mov	ss:[bp].SDOP_customTriggers.handle, ax
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialogOptr		; pass params on stack
	cmp	ax, IC_YES
	pop	bx, cx, dx
	jnz	done
noChanges:

	push	ds
	call	VMGetMapBlock
	call	VMLock
	call	VMDirty
	mov	ds, ax				;ds = map block
	mov	ds:SDBMB_xPos, cx
	mov	ds:SDBMB_yPos, dx

	call	VMUnlock
	pop	ds

done:
	pop	bx
	call	VMReleaseExclusive

	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
	call	ObjCallInstanceNoLock

	mov	ax, mask MRF_PROCESSED
	ret

SDBDocumentStartSelect	endm

COMMENT @----------------------------------------------------------------------

MESSAGE:	SDBDocumentDocumentHasChanged --
		MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED for SDBDocumentClassClass

DESCRIPTION:	Handle notification that the document has changed

PASS:
	*ds:si - instance data
	es - segment of SDBDocumentClassClass

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
	Tony	8/ 7/91		Initial version

------------------------------------------------------------------------------@
SDBDocumentDocumentHasChanged	method dynamic	SDBDocumentClass,
					MSG_GEN_DOCUMENT_DOCUMENT_HAS_CHANGED

	mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
	call	ObjCallInstanceNoLock

	ret

SDBDocumentDocumentHasChanged	endm

CommonCode	ends		;end of CommonCode resource
