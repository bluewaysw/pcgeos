COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Express (Express menu sample application)
FILE:		express.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/92		Initial version

DESCRIPTION:
	This file source code for the Express application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

	Express demonstrates application interaction with the Express menu.

RCS STAMP:
	$Id: express.asm,v 1.1 97/04/04 16:34:18 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include	geos.def
include	heap.def
include geode.def
include	resource.def
include	ec.def

include object.def
include	graphics.def
include lmem.def
include	file.def
include char.def
include localize.def

include hugearr.def
include vm.def
include font.def
include Objects/winC.def
include Objects/inputC.def
include Internal/threadIn.def


;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def

include	Objects/eMenuC.def

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Object Class include files
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Class & Method Definitions
;------------------------------------------------------------------------------

;Here we define "ExpressProcessClass" as a subclass of the system provided
;"GenProcessClass". As this application is launched, an instance of
;will be created, and will handle all application-related events (methods).
;The application thread will be responsible for running this object,
;meaning that whenever this object handles a method, we will be executing
;in the application thread.

ExpressProcessClass	class	GenProcessClass

;METHOD DEFINITIONS: these methods are defined for ExpressProcessClass.

MSG_EXPRESS_EXPRESS_MENU_CONTROL_ITEM_CREATED	message
;
; This is the response message for our invocations of
; MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
;
; Pass:		ss:bp = CreateExpressMenuControlItemResponseParams
; Return:	nothing
;

;Note: instances of ExpressProcessClass are actually hybrid objects.
;Instead of allocating a chunk in an Object Block to contain the instance data
;for this object, we use the application's DGROUP resource. This resource
;contains both idata and udata sections. Therefore, to create instance data
;for this object (such as textColor), we define a variable in idata,
;instead of defining an instance data field here.

ExpressProcessClass	endc	;end of class definition


;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------
;The "express.ui" file, which contains user-interface descriptions for this
;application, is written in a language called Espire. That file gets compiled
;by UIC, and the resulting assembly statements are written into the
;express.rdef file. We include that file here, so that these descriptions
;can be assembled into our application.
;
;Precisely, we are assembling .byte and .word statements which comprise the
;exact instance data for each generic object in the .ui file. When this
;application is launched, these resources (such as MenuResource) will be loaded
;into the Global Heap. The objects in the resource can very quickly become
;usable, as they are pre-instantiated.

include		express.rdef		;include compiled UI definitions


;------------------------------------------------------------------------------
;		Initialized variables and class structures
;------------------------------------------------------------------------------

idata	segment

;Class definition is stored in the application's idata resource here.

	ExpressProcessClass	mask CLASSF_NEVER_SAVED

;initialized variables (In a sense, these variables can be considered
;instance data for the ExpressProcessClass object. See above.)

idata	ends

;------------------------------------------------------------------------------
;		Uninitialized variables
;------------------------------------------------------------------------------

udata	segment

;
; optr of our chunk array that holds information about the express menu
; control object's control panel items that we create
;
itemList	optr

udata	ends

;------------------------------------------------------------------------------
;		Code for ExpressProcessClass
;------------------------------------------------------------------------------

CommonCode	segment	resource	;start of code resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add ourselves to express menu change list

CALLED BY:	MSG_META_ATTACH

PASS:		ds = es - segment of ExpressProcessClass (dgroup)
		dx = AppLaunchBlock

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressAttach	method	ExpressProcessClass, MSG_META_ATTACH
	push	ax, cx, dx, bp
	;
	; set the app interface level to the same as the default UI interface
	; level (unless we are restoring from state)
	;
	push	ds
	mov	bx, dx			; bx = AppLaunchBlock
	call	MemLock
	mov	ds, ax
	cmp	ds:[ALB_appMode], MSG_GEN_PROCESS_RESTORE_FROM_STATE
	call	MemUnlock		; (preserves flags)
	pop	ds
	je	skipUserLevel

	call	UserGetDefaultUILevel	; ax = UIInterfaceLevel
	GetResourceHandleNS	ExpressApp, bx
	call	ObjSwapLock
	mov	si, offset ExpressApp
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
.warn -private
	mov	ds:[di].GAI_appLevel, ax
.warn @private
	call	ObjSwapUnlock
skipUserLevel:

	pop	ax, cx, dx, bp
	;
	; call superclass to do standard handling
	;
	mov	di, offset ExpressProcessClass
	call	ObjCallSuperNoLock
	ret
ExpressAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create our express menu panel for all express menu controls

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION

PASS:		ds = es - segment of ExpressProcessClass (dgroup)

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, bp, ds, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressOpenApplication	method	ExpressProcessClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION
	;
	; call superclass to do standard handling
	;
	mov	di, offset ExpressProcessClass
	call	ObjCallSuperNoLock
	;
	; add our control panel item to all existing Express Menu Control
	; objects
	;
	mov	dx, size CreateExpressMenuControlItemParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].CEMCIP_feature, CEMCIF_CONTROL_PANEL
	mov	ss:[bp].CEMCIP_class.segment, segment GenInteractionClass
	mov	ss:[bp].CEMCIP_class.offset, offset GenInteractionClass
	mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_STANDARD_PRIORITY
	mov	ss:[bp].CEMCIP_responseMessage, MSG_EXPRESS_EXPRESS_MENU_CONTROL_ITEM_CREATED
	call	GeodeGetProcessHandle		; bx = process handle
	mov	ss:[bp].CEMCIP_responseDestination.handle, bx
	mov	ss:[bp].CEMCIP_responseDestination.chunk, 0
	movdw	ss:[bp].CEMCIP_field, 0		; field doesn't matter
	mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	mov	di, mask MF_RECORD or mask MF_STACK
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	clr	dx				; no extra data block
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
	clr	bp				; no cached event
	call	GCNListSend			; send to all EMCs
	add	sp, size CreateExpressMenuControlItemParams
	;
	; THEN, add ourselves to GCNSLT_EXPRESS_MENU_CHANGE list
	;
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
	call	GCNListAdd
	ret
ExpressOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	removes ourselves from express menu change list

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		ds = es - segment of ExpressProcessClass (dgroup)

RETURN:		cx = 0 (no extra state block)

DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressCloseApplication	method	ExpressProcessClass,
					MSG_GEN_PROCESS_CLOSE_APPLICATION
	;
	; first, un-register ourselves
	;
	call	GeodeGetProcessHandle
	mov	cx, bx
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
	call	GCNListRemove
	;
	; nuke any created control panel items
	;	ds = dgroup
	;
	push	ds, si
	movdw	bxsi, ds:[itemList]
	tst	bx
	jz	noList
	call	MemLock
	push	bx
	mov	ds, ax				; *ds:si = chunk array
	mov	bx, cs
	mov	di, offset ED_callback
	call	ChunkArrayEnum
	pop	bx
	call	MemUnlock
noList:
	pop	ds, si
	;
	; return no extra state block
	;
	clr	cx
	ret
ExpressCloseApplication	endm

;
; pass:		*ds:si = chunk array
;		ds:di = CreateExpressMenuControlItemResponseParams
; return:	carry clear to continue enumeration
;
ED_callback	proc	far
	movdw	cxdx, ds:[di].CEMCIRP_newItem
	movdw	bxsi, ds:[di].CEMCIRP_expressMenuControl
	mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
	mov	bp, VUM_NOW
	mov	di, mask MF_FIXUP_DS		; no MF_CALL!
	call	ObjMessage
	clc
	ret
ED_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressNotifyExpressMenuChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle express menu change

CALLED BY:	MSG_NOTIFY_EXPRESS_MENU_CHANGE

PASS:		ds = es - segment of ExpressProcessClass (dgroup)
		bp = GCNExpressMenuNotificationType
		^lcx:dx = optr of affected Express Menu Control

RETURN:		nothing

DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressNotifyExpressMenuChange	method	ExpressProcessClass,
						MSG_NOTIFY_EXPRESS_MENU_CHANGE

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	uses	ax, cx, dx, bp
	.enter

	cmp	bp, GCNEMNT_CREATED
	LONG jne	callSuper
	;
	; new Express menu created, so add our Express menu panel
	;
	mov	si, dx		; si = ExpressMenuControl chunk

	mov	dx, size CreateExpressMenuControlItemParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].CEMCIP_feature, CEMCIF_CONTROL_PANEL
	mov	ss:[bp].CEMCIP_class.segment, segment GenInteractionClass
	mov	ss:[bp].CEMCIP_class.offset, offset GenInteractionClass
	mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_STANDARD_PRIORITY
	mov	ss:[bp].CEMCIP_responseMessage, MSG_EXPRESS_EXPRESS_MENU_CONTROL_ITEM_CREATED
	call	GeodeGetProcessHandle		; bx = process handle
	mov	ss:[bp].CEMCIP_responseDestination.handle, bx
	mov	ss:[bp].CEMCIP_responseDestination.chunk, 0
	movdw	ss:[bp].CEMCIP_field, 0		; field doesn't matter
	mov	bx, cx			; ^lbx:si <- ExpressMenuControl
	mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	call	ObjMessage
	add	sp, size CreateExpressMenuControlItemParams

callSuper:
	.leave
	mov	di, offset ExpressProcessClass
	call	ObjCallSuperNoLock

	pop	di
	call	ThreadReturnStackSpace

	ret
ExpressNotifyExpressMenuChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpressExpressMenuControlItemCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Express Menu Control object has created an item we
		requested it to

CALLED BY:	MSG_EXPRESS_EXPRESS_MENU_CONTROL_ITEM_CREATED


PASS:		ds = es - segment of ExpressProcessClass (dgroup)
		ss:bp = CreateExpressMenuControlItemResponseParams

RETURN:		nothing

DESTROYED:	bx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpressExpressMenuControlItemCreated	method	ExpressProcessClass,
				MSG_EXPRESS_EXPRESS_MENU_CONTROL_ITEM_CREATED

	push	bp				; save params
	movdw	bxsi, ss:[bp].CEMCIRP_newItem	; ^lbx:si = new object
	;
	; make it a sub-menu
	;
	mov	ax, MSG_GEN_INTERACTION_SET_VISIBILITY
	mov	cl, GIV_POPUP
	clr	di				; no MF_CALL!
	call	ObjMessage
	;
	; duplicate our group to it
	;
	pushdw	bxsi				; save new object
	mov	ax, MGIT_EXEC_THREAD
	call	MemGetInfo			; ax = exec thread
	mov	cx, ax				; make it run new group
	call	MemOwner			; bx = owner of new object
	mov	ax, bx				; make it owner of new group
	GetResourceHandleNS	Interface, bx
	call	ObjDuplicateResource		; bx = handle of duplicated
						;	block
	;
	; set moniker of newly created control panel item
	;	bx = handle of new block
	;
	mov	ax, bx				; ax = new block
						; ^lcx:dx = moniker optr
	GetResourceHandleNS	ExpressMenuPanelMoniker, cx
	mov	dx, offset ExpressMenuPanelMoniker
	popdw	bxsi				; ^lbx:si = new object
	mov	bp, VUM_MANUAL
	push	ax				; save new block handle
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	clr	di				; no MF_CALL!
	call	ObjMessage
	pop	cx				; cx = new block
	;
	; add group to new object
	;	^lbx:si = new object
	;	cx = new block
	;
						; ^lcx:dx = new group
	mov	dx, offset ExpressMenuPanelGroup
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, 0				; not dirty, first child
	clr	di				; no MF_CALL!
	call	ObjMessage
	;
	; set new group usable
	;	^lcx:dx = new group
	;
	pushdw	bxsi				; save new object
	movdw	bxsi, cxdx			; ^lbx:si = new group
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	clr	di				; no MF_CALL!
	call	ObjMessage
	popdw	bxsi				; ^lbx:si = new object
	;
	; set new item usable
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	clr	di				; no MF_CALL!
	call	ObjMessage
	;
	; save away information about the newly created item, so we can
	; clean up after ourselves
	;	ss:bp = CreateExpressMenuControlItemResponseParams
	;	ds = es = dgroup
	;
	movdw	bxsi, es:[itemList]
	tst	bx
	jnz	haveList
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx				; no extra header info
	call	MemAllocLMem
	call	MemLock
	push	bx
	mov	ds, ax
	mov	bx, size CreateExpressMenuControlItemResponseParams
	mov	cx, 0				; no extra header space
	mov	si, 0				; allocate new chunk
	mov	al, mask OCF_IGNORE_DIRTY
	call	ChunkArrayCreate		; *ds:si = chunk arr
	pop	bx				; ^lbx:si = chunk arr
	movdw	es:[itemList], bxsi
	call	MemUnlock
haveList:
	call	MemLock
	mov	ds, ax				; *ds:si = chunk arr
	call	ChunkArrayAppend		; ds:di = new entry
	pop	bp				; ss:bp = params
	mov	ax, ss:[bp].CEMCIRP_newItem.handle
	mov	ds:[di].CEMCIRP_newItem.handle, ax
	mov	ax, ss:[bp].CEMCIRP_newItem.chunk
	mov	ds:[di].CEMCIRP_newItem.chunk, ax
	mov	ax, ss:[bp].CEMCIRP_expressMenuControl.handle
	mov	ds:[di].CEMCIRP_expressMenuControl.handle, ax
	mov	ax, ss:[bp].CEMCIRP_expressMenuControl.chunk
	mov	ds:[di].CEMCIRP_expressMenuControl.chunk, ax
	call	MemUnlock
	ret
ExpressExpressMenuControlItemCreated	endm
					
CommonCode	ends		;end of CommonCode resource
