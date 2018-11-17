COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		saverApplication.asm

AUTHOR:		Adam de Boor, Dec  8, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	12/ 8/92	Initial revision


DESCRIPTION:
	Implementation of SaverApplicationClass
		

	$Id: saverApplication.asm,v 1.1 97/04/07 10:44:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
FXIP <SaverFixedCode segment resource					>
	SaverApplicationClass
FXIP <SaverFixedCode	ends						>
idata	ends

SaverAppCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACreateTriggerCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to one or more express menu controllers
		asking them to create one of our two triggers.

CALLED BY:	(INTERNAL)
PASS:		di	= MessageFlags
			if !MF_RECORD:
				^lcx:dx	= controller
		*ds:si	= SaverApplication object
		ax	= response message
		bx	= CreateExpressMenuControlItemPriority for trigger
RETURN:		if MF_RECORD, di = recorded message
DESTROYED:	ax, bx, dx, bp, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACreateTriggerCommon proc	near
		class	SaverApplicationClass
		uses	si
		.enter
		sub	sp, size CreateExpressMenuControlItemParams
		mov	bp, sp
	;
	; The thing is something for a utility
	; 
		mov	ss:[bp].CEMCIP_feature, CEMCIF_UTILITIES_PANEL
	;
	; Make it a GenTrigger, please.
	; 
		mov	ss:[bp].CEMCIP_class.segment, segment GenTriggerClass
		mov	ss:[bp].CEMCIP_class.offset, offset GenTriggerClass
	;
	; Used passed item priority (ExpressMenu will determine position.)
	; 
		mov	ss:[bp].CEMCIP_itemPriority, bx
	;
	; Send us the passed message when the thing's created.
	; 
		mov	ss:[bp].CEMCIP_responseMessage, ax
		mov	ax, ds:[LMBH_handle]
		mov	ss:[bp].CEMCIP_responseDestination.handle, ax
		mov	ss:[bp].CEMCIP_responseDestination.chunk, si
	;
	; The field doesn't matter, as we either are talking to all controllers,
	; or to one whose OD we have.
	; 
		movdw	ss:[bp].CEMCIP_field, 0		; field doesn't matter

		mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
		movdw	bxsi, cxdx
	;
	; If recording, set destination to 0:0, just to be safe.
	; 
		test	di, mask MF_RECORD
		jz	sendMessage
		clr	bx, si
sendMessage:
		ornf	di, mask MF_STACK
		mov	dx, size CreateExpressMenuControlItemParams
		call	ObjMessage
		add	sp, size CreateExpressMenuControlItemParams
		.leave
		ret
SACreateTriggerCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACreateSaveScreenTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a Save Screen trigger

CALLED BY:	(INTERNAL)
PASS:		di	= MessageFlags
		^lcx:dx	= controller, if not MF_RECORD
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACreateSaveScreenTrigger proc	near
		class	SaverApplicationClass
		mov	ax, MSG_SAVER_APP_SAVE_SCREEN_TRIGGER_CREATED
		mov	bx, CEMCIP_SAVER_SCREEN_SAVER
		GOTO	SACreateTriggerCommon
SACreateSaveScreenTrigger		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACreateLockScreenTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a Lock Screen trigger

CALLED BY:	(INTERNAL)
PASS:		di	= MessageFlags
		^lcx:dx	= controller, if not MF_RECORD
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SACreateLockScreenTrigger proc	near
		class	SaverApplicationClass
		mov	ax, MSG_SAVER_APP_LOCK_SCREEN_TRIGGER_CREATED
		mov	bx, CEMCIP_SAVER_SCREEN_LOCK
		GOTO	SACreateTriggerCommon
SACreateLockScreenTrigger		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SASendToExpressMenuControllers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a recorded message to all the active express menu
		controllers.

CALLED BY:	(INTERNAL) SAAttach
PASS:		di	= recorded message
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SASendToExpressMenuControllers proc	near
		class	SaverApplicationClass
		.enter
		mov	cx, di				; cx = event handle
		clr	dx				; no extra data block
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
		clr	bp				; no cached event
		call	GCNListSend			; send to all EMCs
		.leave
		ret
SASendToExpressMenuControllers		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAHookExpressMenus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create our triggers in the existing express menu controllers
		and set up to be told about new ones.

CALLED BY:	(INTERNAL) SAAttach
PASS:		*ds:si	= SaverApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAHookExpressMenus proc	near
		class	SaverApplicationClass
		.enter
	;
	; Create an array in which to track these things.
	; 
		push	si
		mov	bx, size SAExpressMenu
		clr	cx, si		; default header size, create chunk
					;  for me, please.
		mov	al, mask OCF_IGNORE_DIRTY
		call	ChunkArrayCreate
		mov_tr	ax, si
		pop	si
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		mov	ds:[di].SAI_expressMenus, ax
	;
	; First, add ourselves to the GCNSLT_EXPRESS_MENU_CHANGE system
	; notification list so we can create triggers
	; in new Express Menu Control objects
	;
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
		call	GCNListAdd
	;
	; Now create the Save Screen trigger for each one.
	; 
		mov	di, mask MF_RECORD
		call	SACreateSaveScreenTrigger
		call	SASendToExpressMenuControllers
	;
	; Then the lock screen trigger.
	; 
		mov	di, mask MF_RECORD
		call	SACreateLockScreenTrigger
		call	SASendToExpressMenuControllers

		.leave
		ret
SAHookExpressMenus endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SANotifyExpressMenuChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to express menu change notification.

CALLED BY:	MSG_NOTIFY_EXPRESS_MENU_CHANGE
PASS:		*ds:si	= SaverApplicationClass object
		ds:di	= SaverApplicationClass instance data
		ds:bx	= SaverApplicationClass object (same as *ds:si)
		es 	= segment of SaverApplicationClass
		ax	= message #
		bp	= GCNExpressMenuNotificationType
		^lcx:dx	= optr of affected Express Menu Control
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Don't bother destroying any triggers as they will be
		destroyed on MSG_META_DETACH.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	12/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SANotifyExpressMenuChange	method dynamic SaverApplicationClass, 
					MSG_NOTIFY_EXPRESS_MENU_CHANGE
		.enter

		cmp	bp, GCNEMNT_CREATED
		jne	checkDestroyed
	;
	; First create the Save Screen trigger.
	;
		push	cx, dx
		clr	di
		call	SACreateSaveScreenTrigger
		pop	cx, dx
	;
	; Then the lock screen trigger.
	;
		clr	di
		call	SACreateLockScreenTrigger
done:
		.leave
		ret
checkDestroyed:
		cmp	bp, GCNEMNT_DESTROYED
		jne	done
	;
	; Find and remove the record for the controller from our array.
	; 
		mov	si, ds:[di].SAI_expressMenus
		mov	bx, cs
		mov	di, offset SANEMC_callback
		call	ChunkArrayEnum
		jmp	done
SANotifyExpressMenuChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SANEMC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the record for a controller and nuke it.

CALLED BY:	(INTERNAL) SANotifyExpressMenuChange via ChunkArrayEnum
PASS:		*ds:si	= SAI_expressMenus
		ds:di	= SAExpressMenu to check
		^lcx:dx	= EMC for which we're looking
RETURN:		carry set if found and destroyed
DESTROYED:	di, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Don't need to actually nuke the triggers or anything, as
		the EMC will take care of that.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SANEMC_callback	proc	far
		.enter
		cmp	ds:[di].SAEM_emc.handle, cx
		jne	notIt
		cmp	ds:[di].SAEM_emc.chunk, dx
		jne	notIt
		
		call	ChunkArrayDelete
		stc
done:
		.leave
		ret
notIt:
		clc
		jmp	done
SANEMC_callback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to be a screen saver.

CALLED BY:	MSG_META_ATTACH
PASS:		*ds:si	= SaverApplication object
		^hdx	= AppLaunchBlock
		bp	= extra state block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	app object registered as screen saver

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAAttach	method dynamic SaverApplicationClass, MSG_META_ATTACH
		.enter
	;
	; Call the superclass first.
	; 
		mov	di, offset SaverApplicationClass
		push	dx
		call	ObjCallSuperNoLock
	;
	; Copy the saver ID from the AppLaunchBlock.
	; 
		pop	bx
		call	MemLock
		mov	es, ax
		mov	ax, es:[ALB_extraData]
		call	MemUnlock
		andnf	ax, mask SED_SAVER_ID
		
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		mov	ds:[di].SAI_saverID, ax
	;
	; If not the master saver, don't do any of this stuff, as we'll rely
	; on the master saver to tell us what window and bounds &c to use.
	; 
		cmp	ax, SID_MASTER_SAVER
		jne	done
	;
	; Locate the window of the screen on which we'll be opening our
	; main window.
	; 
		mov	ax, MSG_GEN_GUP_QUERY
		mov	cx, GUQT_SCREEN
		call	ObjCallInstanceNoLock	; bp <- window
		
		mov	ax, MSG_SAVER_APP_SET_PARENT_WIN
		call	ObjCallInstanceNoLock
	;
	; Now register with the input manager.
	; 
		push	si
		call	ImInfoInputProcess	; bx <- IM thread
		mov	ax, MSG_IM_INSTALL_SCREEN_SAVER
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	si, MSG_SAVER_APP_START
		mov	bp, MSG_SAVER_APP_STOP
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
	;
	; Hook any and all express menus
	; 
		call	SAHookExpressMenus
done:
		.leave
		ret
SAAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SASetParentWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the window on which our main saver window will open.

CALLED BY:	MSG_SAVER_APP_SET_PARENT_WIN

PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance
		bp	= handle of parent window

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SASetParentWin	method dynamic SaverApplicationClass, 
				MSG_SAVER_APP_SET_PARENT_WIN
		.enter
		mov	ds:[di].SAI_parentWin, bp
	;
	; Now fetch the bounds of the parent window and assume we'll be saving
	; to the whole thing.
	; 
		mov	di, bp
		call	WinGetWinScreenBounds
		sub	dx, bx
		sub	cx, ax
		inc	dx
		inc	cx
		clr	ax
			CheckHack <R_bottom eq 6 and R_right eq 4 and \
					R_top eq 2 and R_left eq 0>
		push	dx, cx, ax, ax
		
		mov	bp, sp		; ss:bp <- Rectangle
		mov	dx, size Rectangle
		mov	ax, MSG_SAVER_APP_SET_BOUNDS
		call	ObjCallInstanceNoLock
		add	sp, size Rectangle
		
	; XXX: if currently saving, close and re-open?
		.leave
		ret
SASetParentWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SASetBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bounds of what we'll be drawing to.

CALLED BY:	MSG_SAVER_APP_SET_BOUNDS
PASS:		*ds:si	= SaverApplication object
		ss:bp	= Rectangle containing bounds, relative to parent
			  window.
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	SAI_bounds set from passed rectangle

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SASetBounds	method dynamic SaverApplicationClass, MSG_SAVER_APP_SET_BOUNDS
		.enter
		add	di, offset SAI_bounds
		segmov	es, ds
		mov	si, bp
	CheckHack <size Rectangle eq 8>
		movsw	ss:
		movsw	ss:
		movsw	ss:
		movsw	ss:
		.leave
		ret
SASetBounds	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAUnhookExpressMenus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from any and all express menus

CALLED BY:	(INTERNAL) SADetach
PASS:		*ds:si	= SaverApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAUnhookExpressMenus proc	near
		class	SaverApplicationClass
		uses	si
		.enter
	;
	; Remove ourselves from the GCN list for the things.
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
		call	GCNListRemove
	;
	; Now nuke all the triggers
	; 
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		mov	si, ds:[di].SAI_expressMenus
		mov	bx, cs
		mov	di, offset SAUEM_callback
		tst	si		; not allocated (app object didn't
					;  get attached, as we never entered
					;  app mode)
		jz	done
		call	ChunkArrayEnum
done:
		.leave
		ret
SAUnhookExpressMenus		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAUEM_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to destroy both triggers we added to
		an express menu controller.

CALLED BY:	SAUnhookExpressMenus via ChunkArrayEnum
PASS:		ds:di	= SAExpressMenu
RETURN:		carry set to stop enumerating
DESTROYED:	ax, cx, dx, bp (bx, si, di allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAUEM_callback	proc	far
		.enter
		pushdw	ds:[di].SAEM_lockTrigger	; save for next message

		movdw	bxsi, ds:[di].SAEM_emc		; ^lbx:si <- controller
	;
	; Nuke the Save Screen trigger first.
	; 
		movdw	cxdx, ds:[di].SAEM_saveTrigger	; ^lcx:dx <- created
							;  item
		mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
		mov	bp, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Now the Lock Screen trigger.
	; 
		popdw	cxdx
		mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
		mov	bp, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		
		clc		; keep enumerating
		.leave
		ret
SAUEM_callback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SADetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare to leave this vale of tears

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= SaverApplication object
		cx	= caller's ack ID
		^ldx:bp	= ackOD
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	app object unregistered as screen saver

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SADetach	method dynamic SaverApplicationClass, MSG_META_DETACH
		uses	ax, cx, dx, bp
		.enter
	;
	; Always quit. We never save to state. Ever.
	; 
		CheckHack <SaverApplication_offset eq GenApplication_offset>
		ornf	ds:[di].GAI_states, mask AS_QUITTING
	;
	; If not master saver and not dying, then not registered.
	; 
		cmp	ds:[di].SAI_saverID, SID_MASTER_SAVER
		je	unhook
		cmp	ds:[di].SAI_saverID, SID_DYING_SAVER
		jne	passItUp
unhook:
		
	;
	; Unhook the various express menu things.
	; 
		call	SAUnhookExpressMenus
	;
	; Unregister with the input manager.
	; 
		call	ImInfoInputProcess	; bx <- IM thread
		mov	ax, MSG_IM_REMOVE_SCREEN_SAVER
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Now call the superclass.
	; 
passItUp:
		.leave
		mov	di, offset SaverApplicationClass
		GOTO	ObjCallSuperNoLock
SADetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin saving the screen.  (called by input manager)

CALLED BY:	MSG_SAVER_APP_START

PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAStart		method dynamic SaverApplicationClass, MSG_SAVER_APP_START
		.enter

		cmp	ds:[di].SAI_saverID, SID_DYING_SAVER
		je	doneShort

EC <		cmp	ds:[di].SAI_saverID, SID_MASTER_SAVER		>
EC <		ERROR_NE	SHOULD_NOT_START_A_SLAVE_SAVER		>

	;
	; User forcing screen blanking off with pointer?
	;
		call	SACheckNeverOn			; forced off with ptr?
		jc	doBlank				; branch if not

		call	ImInfoInputProcess
		mov	ax, MSG_IM_DEACTIVATE_SCREEN_SAVER
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
doneShort:
		jmp	done

doBlank:
	;
	; Start the wakeup monitor
	;
		mov	al, ds:[di].SAI_wakeupOptions
		mov	ah, ds:[di].SAI_inputOptions
		call	SIStartWakeupMonitor
	;
	; Handle any password stuff
	;
		cmp	ds:[di].SAI_lockMode, SLM_AUTOMATIC
		jne	noLock
		
		test	ds:[di].SAI_mode, mask SMF_CANT_LOCK
		jnz	noLock

		BitSet	ds:[di].SAI_state, SSF_LOCK_SCREEN
noLock:
	;
	; Reduce our priority so we don't interfere with background stuff.
	;
		mov	ax, (mask TMF_BASE_PRIO shl 8) or PRIORITY_LOW
		test	ds:[di].SAI_inputOptions, mask SIO_REDUCE_PRIORITY
		jz	setPrio
		mov	al, PRIORITY_IDLE
setPrio:
		clr	bx
		call	ThreadModify

	;
	; Open the window for saving the screen.
	; 
		mov	di, ds:[di].SAI_parentWin
		call	SAOpenWin
	;
	; If we were locking the screen, dismantle that now.
	; 
		push	bx, di
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		test	ds:[di].SAI_state, mask SSF_SCREEN_LOCKED
		jz	setWin

		mov	ax, MSG_SAVER_APP_UNLOCK_SCREEN
		call	ObjCallInstanceNoLock
setWin:
	;
	; Tell ourselves about the new window.
	; 
		pop	dx, bp		; dx <- window, bp <- gstate
		mov	ax, MSG_SAVER_APP_SET_WIN
		call	ObjCallInstanceNoLock		

	;
	; Hide mouse ptr
	;
		mov	ax, mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE
		call	ImSetPtrFlags
done:
		.leave
		ret
SAStart		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SACheckNeverOn
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if user has mouse positioned to not blank screen

CALLED BY:	(INTERNAL) SAStart

PASS:		ds:di	= SaverApplicationInstance
RETURN:		carry - set if blanking should happen
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 3/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SACheckNeverOn	proc	near
		class	SaverApplicationClass
		uses	ax, bx, cx, dx, di
		.enter
	;
	; See if the user doesn't want blanking to occur and the pointer is
	; correctly positioned for this option in the lower right
	;
		test	ds:[di].SAI_inputOptions, mask SIO_NEVER_ON
		stc
		jz	done

		push	di
		mov	di, ds:[di].SAI_parentWin
		call	ImGetMousePos		;(cx,dx) <- (x,y) pos of mouse
		pop	di
	;
	; See if mouse falls within the border on the right-hand side
	; 
		mov	ax, ds:[di].SAI_bounds.R_right
		sub	ax, SAVER_INPUT_BORDER_SIZE
		cmp	cx, ax
		jb	done			; => mouse to left (carry set)
						;  so blank ok
		
		mov	ax, ds:[di].SAI_bounds.R_bottom
		sub	ax, SAVER_INPUT_BORDER_SIZE
		cmp	dx, ax			; if below, then mouse above
						;  (carry set) so blank ok
done:
		.leave
		ret
SACheckNeverOn	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetc the color flags to use in opening a window.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR
PASS:		*ds:si	= SaverApplication object
RETURN:		ax	= WinColorFlags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAGetWinColor	method dynamic SaverApplicationClass, 
				MSG_SAVER_APP_GET_WIN_COLOR
		.enter
		mov	ax, C_BLACK or (mask WCF_PLAIN) shl 8
		.leave
		ret
SAGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAGetWinODs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the output descriptors to use for WinOpen

CALLED BY:	MSG_SAVER_APP_GET_WIN_ODS
PASS:		*ds:si	= SaverApplication object
RETURN:		^lcx:dx	= input OD
		^lax:bp	= exposure OD
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAGetWinODs	method dynamic SaverApplicationClass, MSG_SAVER_APP_GET_WIN_ODS
		.enter
		clr	ax, cx, dx, bp	; no messages going anywhere...
		.leave
		ret
SAGetWinODs	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAOpenWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open a window for us to use.

CALLED BY:	(INTERNAL) SAStart

PASS:		*ds:si	= SaverApplication object
		es	= dgroup
		di	= parent window

RETURN:		bx	= opened window
		di	= gstate (properly initialized)

DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAOpenWin	proc	near
		class	SaverApplicationClass
		uses	si
		.enter
		push	di			; save parent win for layer
						;  priority change
	;
	; Now set up the huge parameter list for WinOpen to use. The window
	; is a plain one (no expose or mouse events) the same size as the
	; screen, with a black background. We create a gstate at the same
	; time to save some...time that is.
	;
		call	GeodeGetProcessHandle
		push	bx			; Our layer ID
		push	bx			; window is ours
		push	di			; parent window
		clr	ax
		push	ax			; use rectangular window region
		push	ax

		mov	bx, ds:[si]
		add	bx, ds:[bx].SaverApplication_offset

		push	ds:[bx].SAI_bounds.R_bottom,
			ds:[bx].SAI_bounds.R_right,
			ds:[bx].SAI_bounds.R_top,
			ds:[bx].SAI_bounds.R_left

		mov	ax, MSG_SAVER_APP_GET_WIN_ODS
		call	ObjCallInstanceNoLock
		mov_tr	di, ax			; ^ldi:bp <- exposure object

		mov	ax, MSG_SAVER_APP_GET_WIN_COLOR
		call	ObjCallInstanceNoLock	; ax <- WinColorFlags
	
		mov	si, mask WPF_CREATE_GSTATE
		call	WinOpen
		
	;
	; Force window to be on top of everything.
	; 
		mov	ax, 1			; affect just the window and
						;  make it the highest-priority
						;  window in its layer.
		mov	dx, di			; give unique layer ID
		call	WinChangePriority
		
		mov	ax, mask WPF_LAYER or \
				((1 shl offset WPD_LAYER) or \
				 (1 shl offset WPD_WIN)) shl offset WPF_PRIORITY
		mov	dx, di
		pop	di			; di <- parent window
		push	dx
		call	WinChangePriority	; now raise the layer itself.
		pop	di

	;
	; Set all the color-map modes to be solid and on-black so by default
	; non-black objects draw as white on a b&w display.
	;
		mov	ax, ColorMapMode <1,CMT_CLOSEST>
		call	GrSetAreaColorMap
		call	GrSetLineColorMap
		call	GrSetTextColorMap
	;
	; Set a blank cursor as the cursor of choice for this window.
	; 
		mov	bp, PIL_WINDOW
		mov	cx, handle blankCursor
		mov	dx, offset blankCursor
		call	WinSetPtrImage

		.leave
		ret
SAOpenWin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SASetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate for drawing.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance
		dx	= window handle
		bp	= gstate handle

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SASetWin	method dynamic SaverApplicationClass, MSG_SAVER_APP_SET_WIN
		.enter

		tst	ds:[di].SAI_curWindow
		jz	setNew
		
		push	di
		mov	di, ds:[di].SAI_curGState
		call	GrDestroyState
		pop	di
setNew:
		mov	ds:[di].SAI_curWindow, dx
		mov	ds:[di].SAI_curGState, bp

		.leave
		ret
SASetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the recorded window and gstate handles

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance
		dx	= window handle being erased

RETURN: 	carry set if unset
		carry clear if passed window not current window
		dx	= window handle
		bp	= gstate handle

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAUnsetWin	method dynamic SaverApplicationClass, MSG_SAVER_APP_UNSET_WIN
		.enter

		cmp	ds:[di].SAI_curWindow, dx
		jne	dontUnset

		clr	dx, bp
		xchg	ds:[di].SAI_curWindow, dx
		xchg	ds:[di].SAI_curGState, bp
		stc
done:
		.leave
		ret
dontUnset:
		mov	dx, ds:[di].SAI_curWindow
		mov	bp, ds:[di].SAI_curGState
		clc
		jmp	done
SAUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen, please.

CALLED BY:	MSG_SAVER_APP_STOP

PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 8/92	Initial version
	stevey	1/7/93		fixed to check passwords again

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAStop		method dynamic SaverApplicationClass, 
						MSG_SAVER_APP_STOP
		.enter
	;
	; Make sure we actually started (might not have if got started while
	; changing savers...)
	; 
		mov	dx, ds:[di].SAI_curWindow
		tst	dx
		jz	done
		
	;
	; Remove the wakeup monitor.
	; 
		call	SIRemoveWakeupMonitor
	;
	; Unset the window, which will cause our subclass to stop doing things.
	; 
		mov	ax, MSG_SAVER_APP_UNSET_WIN
		call	ObjCallInstanceNoLock	; bp <- gstate
	;
	; Put up password dialog if we're locking the screen.
	;
 		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		test	ds:[di].SAI_state, mask SSF_LOCK_SCREEN
		jz	noPassword

		mov	ax, MSG_SAVER_APP_LOCK_SCREEN
		push	bp
		call	ObjCallInstanceNoLock
		pop	bp
noPassword:
	;
	; Close the window and nuke the gstate.
	; 
		mov	di, bp
		call	WinClose

	;
	; Unhide mouse ptr
	;
		mov	ax, (mask PF_HIDE_PTR_IF_NOT_OF_ALWAYS_SHOW_TYPE) shl 8
		call	ImSetPtrFlags
done:
		.leave
		ret
SAStop		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SADispatchEventIfMine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the given event is intended for this saver, as indicated
		by the passed saver ID matching our own, dispatch the
		event to ourselves.

CALLED BY:	MSG_SAVER_APP_DISPATCH_EVENT_IF_MINE

PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance
		cx	= handle of recorded message to dispatch
		dx	= saver ID against which to compare

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SADispatchEventIfMine method dynamic SaverApplicationClass,
		      		MSG_SAVER_APP_DISPATCH_EVENT_IF_MINE
		.enter
		mov	bx, cx
		cmp	ds:[di].SAI_saverID, dx
		jne	done			; assume *someone* will field
						;  it, so we needn't free it,
						;  and in fact we shouldn't,
						;  as the intended recipient
						;  would then get boned...
	;
	; Make sure the message comes to us...
	; 
		mov	cx, ds:[LMBH_handle]
		call	MessageSetDestination
	;
	; ...and dispatch it.
	; 
		mov	di, mask MF_CALL
		call	MessageDispatch
done:
		.leave
		ret
SADispatchEventIfMine endm

SATriggerData	struct
    SATD_emOffset	word
    SATD_moniker	word
    SATD_message	word
SATriggerData	ends

saveScreenTriggerData	SATriggerData 	<
	SAEM_saveTrigger, 
	SaveScreenMoniker,
	MSG_SAVER_APP_FORCE_SAVE
>
lockScreenTriggerData	SATriggerData	<
	SAEM_lockTrigger,
	LockScreenMoniker,
	MSG_SAVER_APP_FORCE_LOCK
>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SASaveScreenTriggerCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a Save Screen trigger

CALLED BY:	MSG_SAVER_APP_SAVE_SCREEN_TRIGGER_CREATED
PASS:		*ds:si	= SaverApplication object
		ss:bp	= CreateExpressMenuControlItemResponseParams
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SASaveScreenTriggerCreated method dynamic SaverApplicationClass, 
				MSG_SAVER_APP_SAVE_SCREEN_TRIGGER_CREATED
		mov	bx, offset saveScreenTriggerData
		GOTO	SATriggerCreatedCommon
SASaveScreenTriggerCreated endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SALockScreenTriggerCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a Lock Screen trigger

CALLED BY:	MSG_SAVER_APP_LOCK_SCREEN_TRIGGER_CREATED
PASS:		*ds:si	= SaverApplication object
		ss:bp	= CreateExpressMenuControlItemResponseParams
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SALockScreenTriggerCreated method dynamic SaverApplicationClass, 
				MSG_SAVER_APP_LOCK_SCREEN_TRIGGER_CREATED
		mov	bx, offset lockScreenTriggerData
		FALL_THRU	SATriggerCreatedCommon
SALockScreenTriggerCreated endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SATriggerCreatedCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a trigger.

CALLED BY:	(INTERNAL) SALockScreenTriggerCreated, 
			   SASaveScreenTriggerCreated
PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance
		cs:bx	= SATriggerData
		ss:bp	= CreateExpressMenuControlItemResponseParams
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SATriggerCreatedCommon proc	far
		class	SaverApplicationClass
		push	si, bp
		mov	al, ds:[di].SAI_mode
		push	ax, bx
	
	;
	; Set the destination of the trigger's action message to be us
	; 
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		movdw	bxsi, ss:[bp].CEMCIRP_newItem
		mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	di
	;
	; Set the message itself.
	; 
		push	di
		mov	cx, cs:[di].SATD_message
		mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	di
	;
	; Set the trigger's moniker.
	; 
		push	di
		mov	cx, handle SaverStrings
		mov	dx, cs:[di].SATD_moniker
		mov	bp, VUM_MANUAL
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	di
	;
	; Now set the thing usable. If the thing is the lock screen trigger
	; and we can't lock the screen, however, we do no such thing.
	; 
		pop	ax
		push	di
		cmp	cs:[di].SATD_message, MSG_SAVER_APP_FORCE_LOCK
		jne	setUsable
		test	al, mask SMF_CANT_LOCK
		jnz	findController
setUsable:
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
findController:
	;
	; Look for the controller in our array, storing the trigger's OD
	; in the proper place if we already know about this controller.
	; 
		pop	si, bp, bx
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset

		mov	si, ds:[di].SAI_expressMenus
		mov	dx, cs:[bx].SATD_emOffset
		mov	bx, cs
		mov	di, offset SATCC_callback
		call	ChunkArrayEnum
		jc	done
	;
	; Not found, so create a new record for the controller.
	; 
		call	ChunkArrayAppend

		segmov	es, ds		; zero-initialize it
		mov	si, di
		clr	ax
		mov	cx, size SAExpressMenu / 2
		rep	stosw
		
		mov	ax, ss:[bp].CEMCIRP_expressMenuControl.handle
		mov	ds:[si].SAEM_emc.handle, ax
		
		mov	ax, ss:[bp].CEMCIRP_expressMenuControl.chunk
		mov	ds:[si].SAEM_emc.chunk, ax

		mov	bx, dx

		mov	ax, ss:[bp].CEMCIRP_newItem.handle
		mov	ds:[bx][si].handle, ax

		mov	ax, ss:[bp].CEMCIRP_newItem.chunk
		mov	ds:[bx][si].chunk, ax
done:		
		ret
SATriggerCreatedCommon endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SATCC_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this record is for the same EMC as just created a
		trigger for us and update it if so.

CALLED BY:	SATriggerCreatedCommon via ChunkArrayEnum
PASS:		ds:di	= SAExpressMenu
		dx	= offset within same to store new item
		ss:bp	= CreateExpressMenuControlItemResponseParams
RETURN:		carry set if this record was for the same EMC
		carry clear if not
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SATCC_callback	proc	far
		.enter
		mov	ax, ss:[bp].CEMCIRP_expressMenuControl.handle
		cmp	ds:[di].SAEM_emc.handle, ax
		jne	no
		
		mov	ax, ss:[bp].CEMCIRP_expressMenuControl.chunk
		cmp	ds:[di].SAEM_emc.chunk, ax
		jne	no
		
		mov	bx, dx
		mov	ax, ss:[bp].CEMCIRP_newItem.handle
		mov	ds:[di][bx].handle, ax
		mov	ax, ss:[bp].CEMCIRP_newItem.chunk
		mov	ds:[di][bx].chunk, ax
		
		stc
done:
		.leave
		ret

no:
		clc
		jmp	done
SATCC_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAForceSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forcibly save the screen, after waiting an appropriate
		amount of time for the user to get his/her paws off the mouse

CALLED BY:	MSG_SAVER_APP_FORCE_SAVE
PASS:		*ds:si	= SaverApplication
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAForceSave	method dynamic SaverApplicationClass, MSG_SAVER_APP_FORCE_SAVE
		.enter
	;
	; Create a one-shot timer to send the appropriate message to the
	; input manager.
	; 
		call	ImInfoInputProcess
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, SAVER_FORCE_SAVE_DELAY
		mov	dx, MSG_IM_ACTIVATE_SCREEN_SAVER
		call	TimerStart

		.leave
		ret
SAForceSave	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAForceLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forcibly save the screen, after waiting an appropriate
		amount of time for the user to get his/her paws off the mouse

CALLED BY:	MSG_SAVER_APP_FORCE_LOCK
PASS:		*ds:si	= SaverApplication
		ds:di	= SaverApplicationInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAForceLock	method dynamic SaverApplicationClass, MSG_SAVER_APP_FORCE_LOCK
		.enter
	;
	; Set the lock-screen bit in instance data
	;
		ornf	ds:[di].SAI_state, mask SSF_LOCK_SCREEN
	;
	; Tell ourselves to forcibly save the screen.
	; 
		mov	ax, MSG_SAVER_APP_FORCE_SAVE
		call	ObjCallInstanceNoLock
		.leave
		ret
SAForceLock	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SANewConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with being talked to by the Lights Out preferences 
		module and others.

CALLED BY:	MSG_META_IACP_NEW_CONNECTION

PASS:		*ds:si	= SaverApplication object
		dx	= non-zero if just launched
		^hcx	= AppLaunchBlock

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SANewConnection method dynamic SaverApplicationClass, 
				MSG_META_IACP_NEW_CONNECTION
		tst	dx		; just launched?
		jnz	passItUp	; yes -- always pass everything.
		jcxz	passItUp
	;
	; Figure whether we should take this as a signal to change
	; savers, and if not, whether we should pass the ALB to our superclass.
	; 
		mov	bx, cx
		call	MemLock
		mov	es, ax
	;
	; If not opened in app mode, assume we need to pass ALB up.
	; 
		clr	ax			; assume not launched by
						;  preflo
		cmp	es:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION
		jne	testPurpose
		mov	ax, es:[ALB_extraData]
testPurpose:
		call	MemUnlock
		test	ax, mask SED_NOT_JUST_TESTING; launched by preflo?
		jnz	launchedWithAPurpose		; yes
passItUp:
		segmov	es, <segment SaverApplicationClass>, di
		mov	di, offset SaverApplicationClass
		mov	ax, MSG_META_IACP_NEW_CONNECTION
		GOTO	ObjCallSuperNoLock

launchedWithAPurpose:
	;
	; See if ID stored in ALB matches our own. If not, we don't pass the
	; ALB up, as it's not intended for us.
	; 
		andnf	ax, mask SED_SAVER_ID
		cmp	ds:[di].SAI_saverID, ax
		je	checkMaster
dontPassALB:
		clr	cx		; don't pass ALB along, as it will
					;  only cause problems
		jmp	passItUp
checkMaster:
		cmp	ax, SID_MASTER_SAVER	; are we the master saver?
		jne	dontPassALB		; no -- don't change
	;
	; App-mode connection to master saver (us :) -- see if ALB mentions
	; us and change to the indicated saver if not.
	; 
		push	dx, bp
		mov	ax, MSG_SAVER_APP_CHANGE_SAVER_IF_NOT_ME
		call	ObjCallInstanceNoLock
		pop	dx, bp
		jmp	dontPassALB
SANewConnection endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAChangeSaverIfNotMe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed AppLaunchBlock refers to us and change
		screen savers if it doesn't.

CALLED BY:	MSG_SAVER_APP_CHANGE_SAVER_IF_NOT_ME
PASS:		*ds:si	= SaverApplication object
		ds:di	= SaverApplicationInstance
		^hcx	= AppLaunchBlock
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	MSG_SAVER_APP_CHANGE_SAVERS is invoked on ourself if the
		ALB doesn't refer to us.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAChangeSaverIfNotMe method dynamic SaverApplicationClass, 
		     		MSG_SAVER_APP_CHANGE_SAVER_IF_NOT_ME
		.enter
		CheckHack <Gen_offset eq SaverApplication_offset>
EC <		cmp	ds:[di].SAI_saverID, SID_MASTER_SAVER	>
EC <		ERROR_NE	SHOULD_NOT_SEND_CHANGE_SAVER_TO_NON_MASTER>
	;
	; Set up registers to compare the AIR_diskHandle/AIR_fileName pairs
	; from the AppInstanceReference stored in our instance data and in the
	; given AppLaunchBlock.
	; 
		push	si
		mov	bx, cx
		call	MemLock
	    ;
	    ; cx/ds:si <- path 1
	    ; 
		lea	si, ds:[di].GAI_appRef.AIR_fileName
		mov	cx, ds:[di].GAI_appRef.AIR_diskHandle
	    ;
	    ; dx/es:di <- path 2
	    ; 
		mov	es, ax
		mov	di, offset ALB_appRef.AIR_fileName
		mov	dx, es:[ALB_appRef].AIR_diskHandle

		mov	al, PCT_EQUAL
		tst	dx		; if no saver specified, it means us
		jz	pathsCompared

		call	FileComparePaths
pathsCompared:
		pop	si
		call	MemUnlock

		cmp	al, PCT_EQUAL
		je	done
	;
	; The two paths are not equal, so the user must want to use some other
	; screen saver. Make a copy of the AppLaunchBlock, since the one we've
	; got will be nuked when we return, and tell ourselves to launch the
	; new one.
	; 
		call	SaverDuplicateALB
		mov	cx, bx
		mov	ax, MSG_SAVER_APP_CHANGE_SAVERS
		call	ObjCallInstanceNoLock
done:
		.leave
		ret
SAChangeSaverIfNotMe		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAChangeSavers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change to a different screen saver.

CALLED BY:	MSG_SAVER_APP_CHANGE_SAVERS
PASS:		*ds:si	= SaverApplication object
		^hcx	= AppLaunchBlock
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAChangeSavers	method dynamic SaverApplicationClass, 
			MSG_SAVER_APP_CHANGE_SAVERS
		.enter
	;
	; Mark ourselves as no longer the master, thus preventing two master
	; savers from being registered at the same time.
	; 
		mov	ds:[di].SAI_saverID, SID_DYING_SAVER
	;
	; First use the AppLaunchBlock to load the new one.
	; 
		mov	ah, (mask ALF_SEND_LAUNCH_REQUEST_TO_UI_TO_HANDLE) or (mask ALF_NO_ACTIVATION_DIALOG)
		mov	dx, cx
		clr	cx
		push	si
		mov	si, -1		; use path in ALB
		call	UserLoadApplication
		pop	si
	;
	; Then tell ourselves to quit.
	; 
		mov	ax, MSG_META_QUIT
		call	ObjCallInstanceNoLock
		.leave
		ret
SAChangeSavers	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SALoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load those options supported by this class

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= SaverApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	things from the Lights Out category are loaded into
     		instance data.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
.warn -private
saOptionTable	SAOptionTable <
	saCategory, length saOptions
>
saOptions	SAOptionDesc <
	saWakeupOptions, size SAI_wakeupOptions, offset SAI_wakeupOptions
>, <
	saInputOptions, size SAI_inputOptions, offset SAI_inputOptions
>, <
	saLockMode, size SAI_lockMode, offset SAI_lockMode
>
.warn @private

saCategory	char	'Lights Out', 0
saWakeupOptions	char	'wakeupOptions', 0	; SAI_wakeupOptions
saInputOptions	char	'inputOptions', 0	; SAI_inputOptions
saPassword	char	'password', 0		; SAI_password
saLockMode	char	'lockScreen', 0		; SAI_lockMode

saUseNet	char	'usenet', 0		; SAI_mode.SMF_USE_NETWORK

SALoadOptions	method dynamic SaverApplicationClass, MSG_META_LOAD_OPTIONS
		uses	si, es, ax
		.enter
		segmov	es, cs
		mov	bx, offset saOptionTable
		call	SaverApplicationGetOptions

		segmov	es, ds
		segmov	ds, cs, cx
		mov	si, offset saCategory
		
	;
	; See if we should use the network password, if the net is loaded.
	; 
		andnf	es:[di].SAI_mode, not (mask SMF_USE_NETWORK or \
					       mask SMF_CANT_LOCK)

		mov	dx, offset saUseNet
		call	InitFileReadBoolean
		jc	verifyOnNetwork		; not present => try network,
						;  if there
		tst	ax
		jz	fetchPassword		; => don't use network, even
						;  if there
verifyOnNetwork:
		call	SPCheckNetwork		; make sure the net is viable
		jnc	fetchPassword
		ornf	es:[di].SAI_mode, mask SMF_USE_NETWORK

	;
	; Fetch the password from the ini file.
	; 
fetchPassword:
		add	di, offset SAI_password
		mov	bp, size SAI_password
		mov	dx, offset saPassword
		call	InitFileReadData
		jnc	storePasswordLen
		clr	cx
storePasswordLen:
		segmov	ds, es
		mov	ds:[di-SAI_password].SAI_passwordLen, cx
	;
	; Update the lock-screen triggers, after figuring whether to set
	; SMF_CANT_LOCK
	; 
		jcxz	checkIfCanUseNet

updateLockScreenTriggers:
		.leave
		call	SAUpdateLockScreenTriggers
	;
	; Pass the call up to our superclass.
	; 
		mov	di, offset SaverApplicationClass
		GOTO	ObjCallSuperNoLock

checkIfCanUseNet:

	;
	; If network not flagged as viable source of password, we can't
	; lock the screen.
	; 
		test	ds:[di-SAI_password].SAI_mode, mask SMF_USE_NETWORK
		jnz	updateLockScreenTriggers
		ornf	ds:[di-SAI_password].SAI_mode, mask SMF_CANT_LOCK
		jmp	updateLockScreenTriggers

SALoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAUpdateLockScreenTriggers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the Lock Screen triggers usable or not usable
		based on the new state of SMF_CANT_LOCK.

CALLED BY:	(INTERNAL) SALoadOptions
PASS:		*ds:si	= SaverApplication object
RETURN:		nothing
DESTROYED:	bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAUpdateLockScreenTriggers proc	near
		class	SaverApplicationClass
		uses	ax, dx, bp, si
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		mov	si, ds:[di].SAI_expressMenus
		tst	si
		jz	done
		mov	cl, ds:[di].SAI_mode
		mov	bx, cs
		mov	di, offset SAULST_callback
		call	ChunkArrayEnum
done:
		.leave
		ret
SAUpdateLockScreenTriggers		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAULST_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the SAEM_lockTrigger for this express menu usable
		or not usable, based on the passed SaverModeFlags record

CALLED BY:	(INTERNAL) SAUpdateLockScreenTriggers via ChunkArrayEnum
PASS:		*ds:si	= SAI_expressMenus
		ds:di	= SAExpressMenu with which to mess
		cl	= SaverModeFlags
RETURN:		carry set to stop enumerating (always clear)
DESTROYED:	si, di, es all allowed.
		ax, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAULST_callback	proc	far
		uses	cx
		.enter
		mov	ax, MSG_GEN_SET_NOT_USABLE
		test	cl, mask SMF_CANT_LOCK
		jnz	haveMessage
		mov	ax, MSG_GEN_SET_USABLE
haveMessage:
		movdw	bxsi, ds:[di].SAEM_lockTrigger
		tst	bx
		jz	done
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		clc
		.leave
		ret
SAULST_callback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaverApplicationGetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a bunch of integer options, given a table describing
		them.

CALLED BY:	(GLOBAL)
PASS:		*ds:si	= SaverApplication object
		es:bx	= SAOptionTable
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FXIP <SaverFixedCode	segment resource				>
SaverApplicationGetOptions proc	far
		class	SaverApplicationClass
		uses	di, ax, cx, dx, si, bp, ds, es
		.enter
		mov	di, ds:[si]
		add	di, ds:[di].SaverApplication_offset
		segxchg	ds, es
		mov	si, ds:[bx].SAOT_category
		mov	cx, ds:[bx].SAOT_numOptions
		add	bx, offset SAOT_options
optionLoop:
		push	cx
		mov	cx, ds
		mov	dx, ds:[bx].SAOD_key
		call	InitFileReadInteger
		jc	nextOption
		
		mov	bp, ds:[bx].SAOD_offset
		mov	es:[di+bp], al
		cmp	ds:[bx].SAOD_size, 1
		je	nextOption
		mov	es:[di+bp+1], ah
nextOption:
		pop	cx
		add	bx, size SAOptionDesc
		loop	optionLoop
		.leave
		ret
SaverApplicationGetOptions endp
FXIP <SaverFixedCode	ends					>
SaverAppCode	ends
