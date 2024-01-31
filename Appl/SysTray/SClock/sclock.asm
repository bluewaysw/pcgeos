COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Designs in Light 2002 -- All Rights Reserved

PROJECT:
MODULE:
FILE:		sclock.asm

DESCRIPTION:
	A clock to sit in the system tray

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include timedate.def
include timer.def

include	sclockConstant.def

include sclock.rdef


idata	segment

ClockClass	mask CLASSF_NEVER_SAVED
ClockProcessClass mask CLASSF_NEVER_SAVED
ClockApplicationClass

idata	ends

Code	segment	resource

;------------------------------------------------------------------------------
;			  ClockProcessClass
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecordCreateMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record a message to all express menu controllers
		asking them to create one of our triggers.

CALLED BY:	ClockOpenApplication()
PASS:		ds - dgroup
RETURN:		di - recorded message
DESTROYED:	ax, bx, dx, bp, cx

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecordCreateMessage proc	near
		uses	si
		.enter
		sub	sp, size CreateExpressMenuControlItemParams
		mov	bp, sp
	;
	; put in the sys tray
	;
		mov	ss:[bp].CEMCIP_feature, CEMCIF_SYSTEM_TRAY
		mov	ss:[bp].CEMCIP_class.segment, ds
		mov	ss:[bp].CEMCIP_class.offset, offset ClockClass
	;
	; standard priority
	;
		mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_STANDARD_PRIORITY
	;
	; tell us when thing is created so we can destroy it later
	;
		mov	ss:[bp].CEMCIP_responseMessage, MSG_CLOCK_APP_CLOCK_CREATED
		clr	bx
		call	GeodeGetAppObject
		mov	ss:[bp].CEMCIP_responseDestination.handle, bx
		mov	ss:[bp].CEMCIP_responseDestination.chunk, si
		movdw	ss:[bp].CEMCIP_field, 0		;field doesn't matter

		mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	;
	; record the message
	;
		clr	bx, si
		mov	di, mask MF_RECORD or mask MF_STACK
		mov	dx, size CreateExpressMenuControlItemParams
		call	ObjMessage
		add	sp, size CreateExpressMenuControlItemParams

		.leave
		ret
RecordCreateMessage endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToExpressMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a recorded message to the express menu

CALLED BY:	ClockOpenApplication()
PASS:		di - recorded message
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToExpressMenu proc	near
		.enter

		mov	cx, di				;cx <- event handle
		clr	dx				;dx <- no extra data
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_OBJECTS
		clr	bp				;bp <- no cached event
		call	GCNListSend

		.leave
		ret
SendToExpressMenu		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start us up

CALLED BY:	MSG_GEN_PROCESS_OPEN_APPLICATION
PASS:		ds, es - dgroup
		cx - AppAttachFlags
		bp - extra state block from before
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockOpenApplication method dynamic ClockProcessClass,
		  		MSG_GEN_PROCESS_OPEN_APPLICATION
		uses	ax, cx, dx, bp
		.enter

		call	RecordCreateMessage
		call	SendToExpressMenu

		.leave
		mov	di, offset ClockProcessClass
		GOTO	ObjCallSuperNoLock
ClockOpenApplication endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockCreateStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Override the desire to create a state file.  Never make one.
		The systray clock will always be loaded.

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		dx - Block handle to block of structure AppInstanceReference
		CurPath	- Set to state directory
RETURN:		ax - VM file handle (or 0 for none)
DESTROYED:	ax

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockCreateStateFile method dynamic ClockProcessClass,
				MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		clr	ax
		ret
ClockCreateStateFile endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockProcessBringUpMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up our menu

CALLED BY:	MSG_CLOCK_PROCESS_BRING_UP_MENU
PASS:		ds - dgroup
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockProcessBringUpMenu method dynamic ClockProcessClass,
					MSG_CLOCK_PROCESS_BRING_UP_MENU
	;
	; bring up our menu
	;
		mov	si, offset ClockMenu
		mov	bx, handle ClockMenu
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
	;
	; make sure we get the focus
	;
		mov	si, offset ClockApp
		mov	bx, handle ClockApp
		mov	ax, MSG_META_GRAB_FOCUS_EXCL
		clr	di
		call	ObjMessage

		ret

ClockProcessBringUpMenu	endm


ClockProcessBringDownMenu method dynamic ClockProcessClass,
					MSG_CLOCK_PROCESS_BRING_DOWN_MENU

		mov	si, offset ClockMenu
		mov	bx, handle ClockMenu
		mov	di, mask MF_FIXUP_DS
		mov	cx, IC_INTERACTION_COMPLETE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		call	ObjMessage

		ret

ClockProcessBringDownMenu	endm



;------------------------------------------------------------------------------
;			ClockApplicationClass
;------------------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockAppClockCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the clock's creation so we can destroy it later

CALLED BY:	MSG_CLOCK_APP_CLOCK_CREATED
PASS:		*ds:si - ClockApplication object
		ds:di - ClockApplicationInstance
		ss:bp - CreateExpressMenuControlItemResponseParams
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockAppClockCreated	method dynamic ClockApplicationClass,
						MSG_CLOCK_APP_CLOCK_CREATED

		movdw	ds:[di].CAI_clock, ss:[bp].CEMCIRP_newItem, ax
		movdw	ds:[di].CAI_emc, ss:[bp].CEMCIRP_expressMenuControl, ax
	;
	; Set the new clock usable -- it has set itself up without any help
	; from us.
	;
		movdw	bxsi, ss:[bp].CEMCIRP_newItem
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	di, mask MF_FIXUP_DS
		GOTO	ObjMessage
ClockAppClockCreated	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockAppDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy our clock before we exit

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si - ClockApp object
		cx -  ack ID
		^ldx:bp	- ack OD
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockAppDetach	method dynamic ClockApplicationClass, MSG_META_DETACH
		uses	si, ax, cx, dx, bp
		.enter

		movdw	bxsi, ds:[di].CAI_emc
		movdw	cxdx, ds:[di].CAI_clock
		clr	ax
		clrdw	ds:[di].CAI_emc, ax
		clrdw	ds:[di].CAI_clock, ax
		mov	bp, VUM_NOW
		mov	ax, MSG_EXPRESS_MENU_CONTROL_DESTROY_CREATED_ITEM
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		mov	di, offset ClockApplicationClass
		GOTO	ObjCallSuperNoLock
ClockAppDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockAppAdjustTimeDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up Preferences Time & Date module

CALLED BY:	MSG_CA_ADJUST_TIME_DATE
PASS:		ds - dgroup
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

pmgrToken GeodeToken <'PMGR', 0>

ClockAppAdjustTimeDate method dynamic ClockApplicationClass,
					MSG_CLOCK_APP_ADJUST_TIME_DATE
	;
	; Create an AppLaunchBlock and fill it in
	;
		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock
		LONG jc	done				;branch if error
		mov	bx, dx				;bx <- handle of ALB
		call	MemLock
		mov	es, ax				;es <- seg of ALB
		mov	di, offset ALB_appRef.AIR_fileName
		mov	si, offset dtApp
		mov	si, ds:[si]
		ChunkSizePtr ds, si, cx
		rep	movsb
		mov	di, offset ALB_dataFile
		mov	si, offset dtModule
		mov	si, ds:[si]
		ChunkSizePtr ds, si, cx
		rep	movsb
		call	MemUnlock
	;
	; Launch the application
	;
launchApp::
		push	bp, bx
		segmov	es, cs
		mov	di, offset pmgrToken
		mov	ax, mask IACPCF_FIRST_ONLY or \
			 IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE
		clr	cx, dx
		call	IACPConnect
		jc	donePop
	;
	; Close the connection we opened
	;
		clr	cx, dx
		call	IACPShutdown
donePop:
		pop	bp, bx
done:
		ret
ClockAppAdjustTimeDate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockAppLostFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure our menu is closed

CALLED BY:	MSG_META_LOST_FOCUS_EXCL
PASS:		*ds:si - ClockApp object
RETURN:		none
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockAppLostFocus	method dynamic ClockApplicationClass,
						MSG_META_LOST_FOCUS_EXCL
		mov	di, offset ClockApplicationClass
		call	ObjCallSuperNoLock
		mov	si, offset ClockMenu
		mov	bx, handle ClockMenu
		mov	di, mask MF_FIXUP_DS
		mov	cx, IC_INTERACTION_COMPLETE
		mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
		GOTO	ObjMessage
ClockAppLostFocus	endm

;------------------------------------------------------------------------------
;			      ClockClass
;------------------------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize ourselves

CALLED BY:	MSG_META_INITIALIZE
PASS:		*ds:si	= Clock object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockInitialize	method dynamic ClockClass, MSG_META_INITIALIZE
		.enter
	;
	; let our superclass initialize its data
	;
		mov	di, offset ClockClass
		call	ObjCallSuperNoLock
	;
	; forcibly set the GA_NOTIFY_VISIBILITY attribute.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		ornf	ds:[di].GI_attrs, mask GA_NOTIFY_VISIBILITY
			CheckHack <Gen_offset eq Clock_offset>

		.leave
		ret
ClockInitialize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the rest of the initialization

CALLED BY:	MSG_SPEC_BUILD
PASS:		*ds:si	= us
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClockSpecBuild	method dynamic ClockClass, MSG_SPEC_BUILD
		uses	ax, cx, dx, bp
		.enter
	;
	; set the message to send when we become visible/non-visible
	;
		mov	ax, ATTR_GEN_VISIBILITY_MESSAGE
		mov	cx, 2
		call	ObjVarAddData
		mov	{word}ds:[bx], MSG_CLOCK_NOTIFY_VISIBILITY
	;
	; send the notification to us
	;
		mov	ax, ATTR_GEN_VISIBILITY_DESTINATION
		mov	cx, size optr
		call	ObjVarAddData
		mov	ax, ds:[LMBH_handle]
		movdw	ds:[bx], axsi

		.leave
		mov	di, offset ClockClass
		GOTO	ObjCallSuperNoLock
ClockSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockNotifyVisibility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note that we can be seen or not

CALLED BY:	MSG_CLOCK_NOTIFY_VISIBILITY
PASS:		*ds:si	= Clock object
		bp	= non-zero if we're visible
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockNotifyVisibility method dynamic ClockClass, MSG_CLOCK_NOTIFY_VISIBILITY
		.enter

		tst	bp
		jz	stopTimer
	;
	; We're becoming visible. Set up a continual timer to fire
	; every minute on the minute, sending us a message to update our
	; display.
	;
		push	di
		call	TimerGetDateAndTime
		sub	dh, 60
		neg	dh			;dh <- seconds until next
		mov	al, 60
		mul	dh			;ax <- # ticks that is
		mov_tr	cx, ax			;cx <- initial delay
		mov	dx, MSG_CLOCK_UPDATE_TIME
		mov	di, 60*60		;di <- 1 minuter interval
		mov	bx, ds:[LMBH_handle]	;^lbx:si <- object
		mov	al, TIMER_EVENT_CONTINUAL
		call	TimerStart
		pop	di
	;
	; record the timer handle and ID
	;
		mov	ds:[di].CI_timerHan, bx
		mov	ds:[di].CI_timerID, ax
	;
	; display the current time
	;
		mov	ax, MSG_CLOCK_UPDATE_TIME
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; let us know about any changes to the time, please
	;
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_DATE_TIME
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListAdd
done:
		.leave
		ret
stopTimer:
	;
	; We're becoming invisible.
	;
		clr	bx
		xchg	bx, ds:[di].CI_timerHan
		mov	ax, ds:[di].CI_timerID
		call	TimerStop
	;
	; no more time notifications
	;
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_DATE_TIME
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		call	GCNListRemove
		jmp	done
ClockNotifyVisibility endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockUpdateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update our moniker to show the current time

CALLED BY:	MSG_CLOCK_UPDATE_TIME
PASS:		*ds:si	= Clock object
		ds:di	= ClockInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockUpdateTime	method dynamic ClockClass, MSG_CLOCK_UPDATE_TIME,
					MSG_NOTIFY_DATE_TIME_CHANGE
		.enter
		mov	bp, si		; preserve object chunk

	;
	; get and format the current time (H:M)
	;
		mov	si, DTF_HM
		call	TimerGetDateAndTime

		sub	sp, DATE_TIME_BUFFER_SIZE
		mov	di, sp
		segmov	es, ss
		push	ax
		pop	ax
		call	LocalFormatDateTime
DBCS <		shl	cx, 1						>
		add	di, cx			;di <- offset past text
		clr	ax
		LocalPutChar esdi, ax
	;
	; set that time as our moniker
	;
		mov	si, bp
		mov	cx, ss
		mov	dx, sp
		mov	bp, VUM_NOW
		mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
		call	ObjCallInstanceNoLock
	;
	; clean up
	;
		add	sp, DATE_TIME_BUFFER_SIZE

		.leave
		ret
ClockUpdateTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClockStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a mouse click

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= Clock object
		(cx,dx) - (x,y)
		bp.low = ButtonInfo
		bp.high = ShiftState
RETURN:		ax - MouseReturnFlags
DESTROYED:	ax, cx, dx, bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClockStartSelect method dynamic ClockClass, MSG_META_START_SELECT
		.enter

	;
	; bring up or close the menu
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		cmp	ds:[di].CI_isMenuOpen, FALSE
		mov	bx, handle 0
		je	doOpen

doClose::
		mov	ax, MSG_CLOCK_PROCESS_BRING_DOWN_MENU
		push	di
		clr	di
		call	ObjMessage
		pop	di
		mov	ds:[di].CI_isMenuOpen, FALSE
		jmp	done
doOpen:
		mov	ax, MSG_CLOCK_PROCESS_BRING_UP_MENU
		push	di
		clr	di
		call	ObjMessage
		pop	di
		mov	ds:[di].CI_isMenuOpen, TRUE
done:
		mov	ax, mask MRF_PROCESSED

		.leave
		ret
ClockStartSelect	endm

Code	ends
