COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Startup
FILE:		cmainProcess.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/89		Initial version

DESCRIPTION:
	This file contains a Startup application


	$Id: cmainProcess.asm,v 1.1 97/04/04 16:52:21 newdeal Exp $

------------------------------------------------------------------------------@

;##############################################################################
;	Initialized data
;##############################################################################


;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

;------------------------------------------------------------------------------
; Startup Process class table
;------------------------------------------------------------------------------

	StartupProcessClass	mask CLASSF_NEVER_SAVED
	StartupClass		mask CLASSF_NEVER_SAVED





StartupProcessFlags	record
	SPF_MONITOR_ACTIVE:1
	;Set if the keyboard moniker is in

	SPF_DETACH_PENDING:1
	;Set if a detach was aborted because a room was still open.

	SPF_DETACHING:1
	; Set if user has selected an option requiring a shutdown, which is
	; now in progress. Used to prevent multiple shutdowns.

	SPF_IGNORING_INPUT:1
	; Set if ignoring input (while waiting for room to shutdown)

	SPF_PENDING_FIELD:1
	; Set if we are waiting for the current field to exit before we
	; open a new field (pendingField)

	SPF_DETACH_AFTER_VERIFY:1
	; Set if a MSG_META_DETACH has come in, but the verify thread
	; is still going.

	:3

StartupProcessFlags	end

;
; general state flags
;
processFlags	StartupProcessFlags 0

;
; currently opened field
;
currentField		optr	0

;
; field waiting to be opened
;
pendingField		optr	0



;------------------------------------------------------------------------------
; Monitor stuff
;------------------------------------------------------------------------------

;
; So that we can watch for the "Hot key" being pressed, in order to 
; switch back to the Startup main screen
;
hotKeyMonitor	Monitor <>

ifdef ISTARTUP

KeySequenceMode record
	:5
	KSM_LOGOUT_QUERY:1	; we are querying the user about logout
	KSM_ESCAPE:1		; we are in escape sequence mode
	KSM_EDLAN:1		; we are in edlan compatibility mode (bios key)
KeySequenceMode	end


;
; Watch for the sequence:
;
keySequenceMode		KeySequenceMode 0
keySequenceState	byte	0	    ; current state of FSM
keySequenceEndState	byte	0	    ; final state of FSM
keySequence		byte	8 dup (0)   ; array of scancodes to watch for

endif

idata	ends



;##############################################################################
;	Uninitialized data
;##############################################################################

udata	segment
;------------------------------------------------------------------------------
; Death/Detach stuff
;------------------------------------------------------------------------------

inEngineMode	byte	(?)	;Is non-zero if we are in engine mode.
detachOD	optr		;Object to send ACK to after detach is finished
detachID	word		;ID passed with detach

ifdef ISTARTUP

autologCountdown	byte	(?)	;number of minutes to wait for the
					;user to acknowledge autologin.
					;if -1, then autologin was ack'ed.
autologRoom		dword		;room to go to, if autologin.

verifyThread		hptr

keyboardDriverStrategy	fptr

endif

udata	ends


;##############################################################################
;	MAIN CODE
;##############################################################################

InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupOpenEngine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a flag letting Startup know we are in engine mode.

CALLED BY:	GLOBAL
PASS:		don't care
RETURN:		don't care
DESTROYED:	whatever superclass trashes
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupOpenEngine	method	StartupClass, MSG_GEN_PROCESS_OPEN_ENGINE
	mov	es:[inEngineMode],TRUE
	mov	di, offset StartupClass
	GOTO	ObjCallSuperNoLock
StartupOpenEngine	endm


COMMENT @----------------------------------------------------------------------

METHOD:		StartupOpenApplication

DESCRIPTION:	Startup application, then startup our help text banner

PASS:
	*ds:si - instance data
	es - segment of StartupClass

	ax - MSG_GEN_PROCESS_OPEN_APPLICATION
	bp - handle of state block
	dx - handle of AppLaunchBlock
	cx - AppAttachFlags
RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@
StartupOpenApplication	method	StartupClass, MSG_GEN_PROCESS_OPEN_APPLICATION

EC <		tst	es:[inEngineMode]			>
EC <		ERROR_NZ STARTUP_ERROR					>

ifndef GPC  ; no main window
ifdef WELCOME
		push	ax, cx, dx, bp
		mov	bx, handle StartupWindow
		mov	si, offset StartupWindow
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		mov	di, mask MF_CALL
		call	ObjMessage
		pop	ax, cx, dx, bp
endif
endif

		mov	di, offset StartupClass
		call	ObjCallSuperNoLock

	;
	; now, after attaching to state file, change owner of field
	; resources to UI, so that flushing via input queue will be
	; happy (the fields are run by the global UI thread)
	;
		mov	bx, handle Room1Field
		call	ChangeResourceOwner
		mov	bx, handle Room2Field
		call	ChangeResourceOwner
		mov	bx, handle Room3Field
		call	ChangeResourceOwner
ifdef ISTARTUP
		mov	bx, handle LoginRoomField
		call	ChangeResourceOwner
 ifdef MOUSETUTORIAL
		mov	bx, handle MouseRoomField
		call	ChangeResourceOwner
 endif

		call	IStartupOpenApplication

endif


ifdef WELCOME
		call	WelcomeOpenApplication
endif

		ret

StartupOpenApplication	endm

ifdef WELCOME
		

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WelcomeOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open application handler for WELCOME
	
CALLED BY:	StartupOpenApplication

PASS:		ds - dgroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WelcomeOpenApplication	proc near

		.enter

if (0)	; No express menu trigger and just return to Welcome

		call	CreateExpressMenuTrigger
endif	; (0)

	;
	; Return to the field from which we shutdown.  There will be no such
	; field if we are starting for the first time, if we exited from the
	; Startup main screen, or if we exited using "Exit to DOS".  (The
	; last only applies to Welcome, not IStartup).
	;
		call	SysGetConfig
		test	al, mask SCF_RESTARTED
		jz	skipReturnField
		
		mov	ax, MSG_STARTUP_APP_GET_RETURN_FIELD
		call	GenCallApplication
		jc	enterRoom

skipReturnField:
	;
	; If first time using device, run set up program in CUI field
	;
ifdef GPC
		push	ds
		segmov	ds, cs, cx
		mov	si, offset startupCat
		mov	dx, offset startupKey
		call	InitFileReadBoolean
		pop	ds
		jnc	gotStartup
		mov	ax, FALSE
gotStartup:
		cmp	ax, TRUE
		je	doneStartup
		mov	bx, handle Room1Field
		mov	si, offset Room1Field
		mov	ax, MSG_STARTUP_FIELD_START_SET_UP
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; open field
	;
		mov	cx, handle Room1Field
		mov	dx, offset Room1Field
		mov	ax, MSG_STARTUP_OPEN_FIELD	; Enter selected room
		mov	bx, handle 0
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
	;
	; run set up application
	;
		mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
		call	IACPCreateDefaultLaunchBlock	; dx = ALB
		jc	doneStartupErr		; mem error
		mov	bx, dx			; bx = ALB
		call	MemLock
		jc	doneStartupErr		; mem error (block left)
		mov	es, ax
		mov	ax, handle Room1Field
		mov	es:[ALB_genParent].handle, ax
		mov	ax, offset Room1Field
		mov	es:[ALB_genParent].offset, ax
		call	MemUnlock
		segmov	es, cs, di
		mov	di, offset startupToken
		clr	ax
		call	IACPConnect
		jc	doneStartupErr		; couldn't launch error
		clr	cx
		call	IACPShutdown
		mov	bx, handle Room1Field
		mov	si, offset Room1Field
		mov	ax, MSG_STARTUP_FIELD_FINISH_SET_UP
		mov	di, mask MF_CALL
		call	ObjMessage
		jmp	doneWithInitialRoom

doneStartupErr:
		mov	bx, handle Room1Field
		mov	si, offset Room1Field
		mov	ax, MSG_STARTUP_FIELD_CLEAN_UP_SET_UP
		mov	di, mask MF_CALL
		call	ObjMessage
		clr	cx
		mov	ax, MSG_GEN_FIELD_LOAD_DEFAULT_LAUNCHER
		mov	di, mask MF_CALL
		call	ObjMessage
		jmp	doneWithInitialRoom

doneStartup:
endif

ifdef PRODUCT_WIN_DEMO

	mov	bx, handle WelcomeDialog
	mov	si, offset WelcomeDialog
	call	UserCreateDialog

	call	UserDoDialog

	call	UserDestroyDialog

endif

	;
	; FIND OUT WHAT ROOM THE USER WANTS TO STARTUP IN
	;
		call	StartupGetStartupRoom
		jz	enterRoom

		mov	bx, handle StartupApp
		mov	si, offset StartupApp
		mov	di, mask MF_CALL
		mov	ax, MSG_STARTUP_APP_SWITCH_TO_STARTUP
		call	ObjMessage
		jmp	doneWithInitialRoom

enterRoom:
		mov	ax, MSG_STARTUP_OPEN_FIELD	; Enter selected room
		mov	bx, handle 0
		mov	di, mask MF_CALL
		call	ObjMessage

doneWithInitialRoom:

	; INSTALL MONITOR

		test	ds:[processFlags], mask SPF_MONITOR_ACTIVE
		jnz	monitorIn

		mov	bx, offset dgroup:hotKeyMonitor
				; Install just after kbd chars converted
		mov	al, ML_DRIVER+1
		mov	cx, segment Resident
		mov	dx, offset StartupHotKeyMonitor
		call	ImAddMonitor
		or	ds:[processFlags], mask SPF_MONITOR_ACTIVE
monitorIn:

		.leave
		ret
WelcomeOpenApplication	endp

ifdef GPC
startupCat	char	'welcome',0
startupKey	char	'finishedSetup',0
startupToken	GeodeToken <<'GPCs'>,0>
endif

endif


ifdef ISTARTUP


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open application for IStartup

CALLED BY:	StartupOpenApplication

PASS:		ds, es - dgroup

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/ 1/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IStartupOpenApplication	proc near
		.enter


	;
	; Get escape sequence
	;

		mov	di, offset keySequence		;es:di =
							;sequence buffer
		call	IclasGetEscapeSequence		;get escape sequence
		mov	es:[keySequenceEndState], cl

	;
	; Check to see if anyone is logged in. Call the Net Library routine
	; because the Iclas Library is not initialized yet.
	;
		call	IclasNetGetUserType	
		cmp	ah, UT_LOGIN
		jne	realUser
	;
	; No one's logged in.  Open Login field.
	;
		mov	cx, handle LoginRoomField
		mov	dx, offset LoginRoomField
		jmp	enterRoom

realUser:

	;
	; Check to see if we are returning from running courseware (or
	; shelling out to DOS).  If yes, then skip link verification
	; and don't bother checking for autologin.  Just return to the
	; field from which we shutdown.
	;

		mov	ax, MSG_STARTUP_APP_GET_RETURN_FIELD
		call	GenCallApplication
		jc	wasRunningCourseware

	;
	; We're restarting GEOS as a user after logging in with
	; slowLogin = true
	;

		call	IclasInitUserVariables
		call	IclasSetupUserHome
		jc	alreadyLoggedIn

		call	IclasEnterUserHome
		call	IclasInitOtherVariables	; depends on
						; SP_TOP  and ini file
		call	IStartupInitUser
		jc	doneWithInitialRoom

		call	IStartupGetStartupRoom
		jc	enterRoom

		mov	bx, handle StartupApp
		mov	si, offset StartupApp
		mov	di, mask MF_CALL
		mov	ax, MSG_STARTUP_APP_SWITCH_TO_STARTUP
		call	ObjMessage
		jmp	doneWithInitialRoom

alreadyLoggedIn:
	;
	; another user is already logged in with the same login ID, or
	; the license limit is exceeded.  Logout right away.
	;
		mov	ax, MSG_STARTUP_APP_LOGOUT
		mov	cx, FALSE			; do not query user
		call	GenCallApplication
		jmp	done	



wasRunningCourseware:
		call	IclasInitUserVariables
		call	IclasEnterUserHome

		call	IclasInitOtherVariables
		call	IStartupBeginPollingForMessages
		call	CreateTriggerIfPermissionSet

enterRoom:

	;
	; Enter the room.  Do this FORCE_QUEUE, so that the spooler is
	; loaded before the room is entered.  Otherwise, things will
	; crash. 
	;
		

		mov	ax, MSG_STARTUP_OPEN_FIELD	; Enter selected room
		mov	bx, handle 0
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

doneWithInitialRoom:
						; INSTALL MONITOR
		test	ds:[processFlags], mask SPF_MONITOR_ACTIVE
		jnz	done

	;
	; Save strategy routine for keyboard driver
	;
		mov	ax, GDDT_KEYBOARD
		call	GeodeGetDefaultDriver

		push	ds, si
		mov	bx, ax
		call	GeodeInfoDriver
		movdw	es:[keyboardDriverStrategy], ds:[di].DIS_strategy, ax
		pop	ds, si

		mov	bx, offset dgroup:hotKeyMonitor
				; Install just after kbd chars converted
		mov	al, ML_DRIVER+1
		mov	cx, segment Resident
		mov	dx, offset StartupHotKeyMonitor
		call	ImAddMonitor
		or	ds:[processFlags], mask SPF_MONITOR_ACTIVE
done:
	;
	; Do this last -- after we've already entered the user's home,
	; so that the spooler will find state files from a shutdown,
	; if necessary.
	;

		call	IStartupLoadSpooler

	;
	; Also need to do this last, because we need to be in the
	; user's home so that the INI files are set up correctly, lest
	; we get weird off-by-one errors in the default printer when
	; shutting down and restoring f
	;
		
		call	IStartupDeterminePrinterStatus

		.leave
		ret



IStartupOpenApplication	endp


endif






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeResourceOwner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the resource in, and set its owner to be UI

CALLED BY:	StartupOpenApplication

PASS:		bx - resource handle

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	7/ 1/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeResourceOwner	proc	near
	;
	; force resource to load in, so it can be relocated using startup's
	; relocation tables
	;
	.assert (offset Room1Field eq offset Room2Field)
	.assert (offset Room2Field eq offset Room3Field)
ifdef ISTARTUP
	.assert (offset Room3Field eq offset LoginRoomField)
 ifdef MOUSETUTORIAL
	.assert (offset LoginRoomField eq offset MouseRoomField)
 endif
endif
	mov	si, offset Room1Field
	mov	ax, MSG_GEN_GET_USABLE	; something handle in Gen
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	;
	; change owner to ui
	;
	mov	ax, handle ui		; ax = UI
	call	HandleModifyOwner
	ret
ChangeResourceOwner	endp


ifdef ISTARTUP	;--------------------------------------------------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupLoadSpooler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the spooler.  Do this AFTER entering the user's
		home, so that print jobs that were cancelled the last
		time we shut down to DOS will be restarted.

CALLED BY:	IStartupOpenApplication

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/25/93   	Copied from UserLoadSpooler

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <spoolerName 	char	"SPOOLEC.GEO",0			>
NEC <spoolerName 	char	"SPOOL.GEO",0			>

IStartupLoadSpooler	proc	near

		uses	ax,bx,cx,dx,si,di,bp,ds,es

		.enter

	;
	; See if it's already loaded
	;
		
		segmov	ds, dgroup, ax
		tst	ds:[spoolerHandle]
		jnz	done
		


	;
	; Load it.  We need to create an AppLaunchBlock,
	; since the parent field needs to be the global UI field,
	; otherwise the spooler will exit when the currently displayed
	; field is exited
	;
		
		mov	ax, size AppLaunchBlock
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK	or \
				mask HF_SHARABLE or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		mov	es, ax
		
		mov	ax, MSG_GEN_FIND_PARENT
		call	UserCallApplication

		movdw	es:[ALB_genParent], cxdx

		mov	dx, bx			; AppLaunchBlock handle
		call	MemUnlock		; necessary?
		
		clr	ax
		mov	cx, MSG_GEN_PROCESS_OPEN_APPLICATION
		segmov	ds, cs
		mov	si, offset spoolerName
		mov	bx, SP_SYSTEM
		call	UserLoadApplication
		jc	done

		segmov	ds, dgroup, ax
		mov	ds:[spoolerHandle], bx

done:
		.leave
		ret
IStartupLoadSpooler	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallSpoolSetDefaultPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the default printer for the system, either after
		returning from state as a user, or the first time the
		system boots.  If this is a first-time boot, then just
		store the printer number for later, since the spooler
		won't have been loaded yet.

CALLED BY:	IStartupLoadSpooler, FindPrinterWithMatchingQueueCB

PASS:		ax - printer number to make default

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		Things happen radically differently in slow vs. fast
		login, so any changes made here should be tested in
		both.  Things to watch out for:

		- If a user has printers defined in her user .ini
		file, then this routine has to be called AFTER
		IStartupInitUser, so that the user's .ini file is
		correctly in-use, and thus, the correct printer is selected.



REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/25/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallSpoolSetDefaultPrinter	proc near
		uses	ds, bx
		.enter

	;
	; In slow login, this routine is called before the spooler is
	; loaded, so we just bail if this is the case, in the hope
	; that this routine will get called again later.  In fast
	; login, things seem to happen at the right time.  Please do
	; not change ANY of this hooey unless you are absolutely sure
	; of what you're doing, because people keep breaking it, and I
	; keep fixing it, and I'm sick of doing this.
	;
	;					
		
		
		segmov	ds, dgroup, bx
		mov	bx, ds:[spoolerHandle]
		tst	bx
		jz	done

		push	ax
		mov	ax, enum SpoolSetDefaultPrinter
		call	ProcGetLibraryEntry

		pop	ss:[TPD_dataAX]
		call	ProcCallFixedOrMovable
done:
		
		.leave
		ret
CallSpoolSetDefaultPrinter	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupInitUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Init IStartup for user.  If autologin, also goes into the
		room.

CALLED BY:	IStartupOpenApplication (slow login)
		StartupFieldNotifyNoFocus (fast login)

PASS:		nothing

RETURN:		if carry set, autologin. 

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	4/16/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IStartupInitUser	proc	far
		uses	ax, bx, si, di, bp
		.enter

		call	IStartupBeginPollingForMessages
		call	CreateTriggerIfPermissionSet

	;
	; Set the capture to the default queue, if any, for this workstation.
	;
		
		call	IStartupSetDefaultPrinter

	;
	; Start link verification.
	;

		call	IStartupVerifyLinks

	;
	; hide/show K2-level trigger as needed
	;

		mov	cx, MSG_GEN_SET_USABLE		; assume student
		call	IclasGetCurrentUserType
		cmp	ah, UT_STUDENT
		je	setK2level
		cmp	ah, UT_GENERIC
		je	setK2level
		CheckHack <MSG_GEN_SET_NOT_USABLE eq MSG_GEN_SET_USABLE+1>
		inc	cx

setK2level:
		push	ax				; UserType
		mov_tr	ax, cx
		mov	bx, handle Room1
		mov	si, offset Room1
		call	callObjMessageVumNow

	;
	; Set the SelfGuided screen not usable if user can't enter it.
	;

		call	IclasGetUserPermissions
		test	ax, mask UP_SELF_GUIDED_LEVEL
		mov	ax, MSG_GEN_SET_USABLE
		jnz	gotMessage
		CheckHack <MSG_GEN_SET_NOT_USABLE eq MSG_GEN_SET_USABLE+1>
		inc	ax

gotMessage:
		mov	bx, handle Room3
		mov	si, offset Room3
		call	callObjMessageVumNow

		pop	ax				; UserType


	;
	; Check autologin
	;
		cmp	ah, UT_STUDENT
		je	checkAutologin
		cmp	ah, UT_GENERIC
		jne	noAutoLogin

checkAutologin:
		call	GetAutologStatus
		jc	noAutoLogin

	;al = autologin timeout, ah = IclasAutologinLevel,
	;and ^lcx:dx = room to enter.

		clr	ah			; ax = timeout period
		call	WaitForAutologTimeout
		stc				; indicate autologin
		jmp	done
noAutoLogin:
		clc
done:
		.leave
		ret

callObjMessageVumNow:
		clr	di
		mov	dl, VUM_NOW
		call	ObjMessage
		retn

IStartupInitUser	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupSetDefaultPrinter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set this user's default printer to the one that was
		set when the machine was first booted.

CALLED BY:	IStartupInitUser

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
	This code has broken so many times it's not even funny. In
	slow login, IStartupInitUser (which calls
	IStartupSetDefaultPrinter) is called by
	IStartupOpenApplication before the spooler is loaded, so this
	routine basically does nothing, but that's OK, because
	IStartupDeterminePrinterStatus is called later, which does the
	right thing.  In fast login, IStartupInitUser is called by
	StartupFieldNotifyNoFocus, after the user has logged in, so
	this routine does the right thing.  What a mess!!!
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IStartupSetDefaultPrinter	proc near
		uses	ax,bx,cx,dx,es

		.enter

		mov	bx, handle DefaultPrinterQueue
		push	bx
		
		call	ObjLockObjBlock
		mov	es, ax
		assume	es:AppResource
		mov	bx, es:[DefaultPrinterQueue]
		assume	es:dgroup

	;
	; es:bx - queue name
	;
		call	FindPrinterWithMatchingQueue

		pop	bx
		call	MemUnlock

		.leave
		ret
IStartupSetDefaultPrinter	endp

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupGetStartupRoom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the optr of the field we should start in

CALLED BY:	IStartupOpenApplication, WelcomeOpenApplication

PASS:		nothing

RETURN:		if zero flag set, ^lcx:dx = field we should start in

DESTROYED:	ax,bx,cx,dx,si,di,bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	????	4/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupGetStartupRoom	proc	far

	push	ds
	mov	bx, handle IniStrings		;Lock resource
	call	MemLock
	mov	ds, ax
	mov_tr	cx, ax				;CX <- strings resource

	assume ds:IniStrings

	mov	dx, ds:[StartupRoomKeyString]	;CX:DX <- key string
	mov	si, ds:[CategoryString]		;DS:SI <- category string
	call	InitFileReadInteger
 	jnc	10$				;Branch if string found
	clr	ax				;Else, enter Startup room.
10$:
	mov	bx, handle IniStrings		;Unlock strings resource
	call	MemUnlock

	assume ds:dgroup

	pop	ds

;	IF THE USER WANTS TO STARTUP IN ONE OF THE ROOMS, GO
;	THERE DIRECTLY

	mov	cx, handle Room1Field		;assume room 1
	mov	dx, offset Room1Field
	dec	ax
	je	done

	mov	cx, handle Room2Field		;assume room 2
	mov	dx, offset Room2Field
	dec	ax
	je	done

	mov	cx, handle Room3Field		;assume room 3
	mov	dx, offset Room3Field
	dec	ax
done:
	ret
StartupGetStartupRoom	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupGetStartupRoom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get optr of field we should startup in

CALLED BY:	IStartupOpenApplication, StartupFieldNotifyNoFocus
PASS:		nothing
RETURN:		carry set if we have a field to startup in
			^lcx:dx = field to startup in
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	7/24/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

IStartupGetStartupRoom	proc	far
		uses	ax,bx,si,di,bp
		.enter
	;
	; FIND OUT WHAT ROOM THE USER WANTS TO STARTUP IN
	;
		call	StartupGetStartupRoom
		stc				; assume we have startup room
		jz	done
	;
	; No startup room in .ini file.
	;
		call	IclasNetGetUserType
		cmp	ah, UT_STUDENT
		jz	student
		cmp	ah, UT_GENERIC
		clc				; assume no startup room
		jnz	done
student:
	;
	; Students should automatically enter K2Shell if they don't have a
	; preferred startup room set in their .ini file.
	;
		mov	cx, handle Room1Field
		mov	dx, offset Room1Field
		stc				; we have a startup room
done:
		.leave
		ret
IStartupGetStartupRoom	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupDeterminePrinterStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Since we're returning from DOS, where the user may
		have changed the current LPT capture, see if we can
		figure out which queue LPT1 is rerouted to, and see if
		there's a printer in the .INI file that uses that
		queue, and if so, make that our current default
		printer. 

CALLED BY:	IStartupOpenApplication

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

noQueueName	char	"nONe",0
ForceRef noQueueName

IStartupDeterminePrinterStatus	proc near
ifdef BUILD_STATE_FILE

	;
	; If we pass this compilation flag, then istartup will keep
	; the DefaultPrinterQueue chunk empty, which is what we want
	; for the template state file.  We DON'T want this in the
	; normal case!
	;
		
%out ********** WARNING:  BUILD_STATE_FILE constant is set ***********
		ret
else


	uses	ax,bx,cx,dx,di,si,ds,es

queueName		local	NetObjectName
queueNamePtr		local	fptr.char
		.enter

		
		segmov	ds, ss
		lea	si, ss:[queueName]
		mov	bx, PARALLEL_LPT1
		call	NetPrintGetCaptureQueue
		jc	done

		tst	<{char} ds:[si]>
		jnz	haveQueue

	;
	; If there was no capture, then we still need to initialize
	; the DefaultPrinterQueue variable to some non-null value.
	; God help us if a sysop ever creates a queue called "nONe"
	;
		segmov	ds, cs
		mov	si, offset noQueueName
		
haveQueue:
		
		
		movdw	ss:[queueNamePtr], dssi		

	;
	; If this is the first boot, then store the queue name in the
	; "DefaultPrinterQueue" chunk, so that subsequent logins will set
	; their printers to this value.
	;

		segmov	es, ds
		mov	di, si
		call	LocalStringSize
		inc	cx
		
		mov	bx, handle DefaultPrinterQueue
		call	ObjLockObjBlock
		mov	ds, ax
		mov	si, offset DefaultPrinterQueue
		mov	di, ds:[si]
		tst	<{char} ds:[di]>
		jnz	afterStoreDefaultQueue

	;
	; The queue name is blank, so reallocate the chunk, and copy
	; it in.
	;
		mov	ax, si		
		call	LMemReAlloc
		call	ObjMarkDirty
		segmov	es, ds
		mov	di, es:[si]

		lds	si, ss:[queueNamePtr]
		LocalCopyString

afterStoreDefaultQueue:
		call	MemUnlock

	;
	; Now, find a printer with this queue, and make it the default.
	;
		lea	bx, ss:[queueName]
		segmov	es, ss		
		call	FindPrinterWithMatchingQueue

	;
	; Stop capturing, so GEOS apps can print to the local printer,
	; if need be.
	;
		mov	bx, PARALLEL_LPT1
		call	NetPrintEndCapture
done:
		.leave
		ret


endif	; ifdef BUILD_STATE_FILE
IStartupDeterminePrinterStatus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPrinterWithMatchingQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a printer whose queue matches the passed queue

CALLED BY:	IStartupDeterminePrinterStatus

PASS:		es:bx - null-terminated queue name

RETURN:		nothing.  Calls SpoolSetDefaultPrinter to set the default.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
printerCategoryStr char "printer",0
printersKeyStr char "printers",0

FindPrinterWithMatchingQueue	proc near
		uses	ax,cx,dx,di,si,bp,ds
		.enter
		tst	<{char} es:[bx]>
		jz	done

	;
	; Look for a printer that is redirected to this queue
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset printerCategoryStr
		mov	dx, offset printersKeyStr

		mov	bp, mask IFRF_READ_ALL
		mov	di, cx
		mov	ax, offset FindPrinterWithMatchingQueueCB
		call	InitFileEnumStringSection

done:
		
		.leave
		ret
FindPrinterWithMatchingQueue	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindPrinterWithMatchingQueueCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine.  For each named printer, see if it's
		defined as going to a network queue, and if so, see if
		that queue name matches the passed queue name, and if
		so, set that printer to be the default printer

CALLED BY:	FindPrinterWithMatchingQueue

PASS:		es:bx - passed queue name
		ds:si - printer name
		dx - printer number

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

initCodeQueueKey	char	"queue",0

FindPrinterWithMatchingQueueCB	proc far

		uses	es, bx

passedQueue	  local	fptr.char	push	es, bx
initFileQueueName local	NetObjectName		

		.enter	

	;
	; See if this printer is defined as going to a queue
	;
		mov	cx, cs

		push	dx, bp
		mov	dx, offset initCodeQueueKey
		segmov	es, ss
		lea	di, ss:[initFileQueueName]
		mov	bp, size initFileQueueName
		call	InitFileReadString
		pop	dx, bp

		jc	doneCLC

	;
	; Compare the two queue names
	;
		clr	cx
		lds	si, ss:[passedQueue]
		call	LocalCmpStrings
		jne	doneCLC

	;
	; They match, so make this printer the new default
	;
		mov_tr	ax, dx
		call	CallSpoolSetDefaultPrinter
		stc
		jmp	done

doneCLC:
		clc
done:
		.leave
		ret
FindPrinterWithMatchingQueueCB	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateExpressMenuTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a trigger in all existing express menus, and
		add ourselves to the express menu notification

CALLED BY:	WelcomeOpenApplication, IStartupOpenApplication

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef WELCOME
CreateExpressMenuTrigger	proc far
		.enter
	;
	; Add a button to all currently existing ExpressMenuControl
	; objects.
	;		
		mov	dx, size CreateExpressMenuControlItemParams
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].CEMCIP_feature, CEMCIF_UTILITIES_PANEL
		mov	ss:[bp].CEMCIP_class.segment, segment GenTriggerClass
		mov	ss:[bp].CEMCIP_class.offset, offset GenTriggerClass
		mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_NETMSG_SEND_MESSAGE
		mov	ss:[bp].CEMCIP_responseMessage,
				MSG_STARTUP_EXPRESS_MENU_CONTROL_ITEM_CREATED
		mov	ss:[bp].CEMCIP_responseDestination.handle, handle 0
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
	; THEN, add ourselves to the GCNSLT_EXPRESS_MENU_CHANGE system
	; notification list so we can create a "Return to Welcome" trigger for
	; any new Express Menu Control objects that come along
	;	
		mov	cx, handle 0
		clr	dx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
		call	GCNListAdd

		.leave
		ret
CreateExpressMenuTrigger	endp
endif ; not WELCOME


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetAutologStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check if autologin.  If yes, get room to which we should
		autolog into.

CALLED BY:	IStartupInitUser

PASS:		nothing

RETURN:		carry clear if autologin, carry set if not autologin
		al = autologin timeout for the class
		ah = IclasAutologinLevel
		^lcx:dx = room to enter if autologin

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/ 6/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

GetAutologStatus	proc	near
autologInfo 	local	IclasPathStruct
	uses	bx,si,ds
	.enter

	mov	cx, ss
	lea	dx, autologInfo
	clr	ax				;only get autologin info
	call	IclasGetAutologClass
	jc	done
	;
	; User was autologged in.  Get autolog info (timeout and room).
	;
	call	FilePushDir
	mov	ds, cx
	mov	si, dx
	call 	IclasSetClassDir
	call	IclasGetAutologInfo
	call	FilePopDir
	;
	; Get room optr
	;
	mov	ax, cx
	mov	cx, handle Room1Field
	mov	dx, offset Room1Field
	cmp	ah, AUTOLOG_K2_LEVEL
	je	haveRoom
;guided:
	cmp	ah, AUTOLOG_GUIDED_LEVEL
	jne	unGuided
	mov	cx, handle Room2Field
	mov	dx, offset Room2Field
unGuided:
	cmp	ah, AUTOLOG_UNGUIDED_LEVEL
	jne	haveRoom
	mov	cx, handle Room3Field
	mov	dx, offset Room3Field
haveRoom:
	clc	
done:
	.leave
	ret
GetAutologStatus	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WaitForAutologTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Wait for the user's acknowledgement of the autologin.
		If the user responds before the timeout, then go to the
		desired room.  Otherwise logout.

CALLED BY:	IStartupInitUser
PASS:		al	= timeout period
		cx:dx	= room to go to.

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	3/2/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

WaitForAutologTimeout	proc	near
userName	local	NET_USER_FULL_NAME_BUFFER_SIZE + USER_ID_LENGTH + 4 \
			dup (char)
			; fullname + CR + '(' + ID + ')' + null
	uses	ax,bx,cx,dx,ds,es,si,di,bp
	.enter

	;
	; setup the autologCountdown variable, which is used by 
	; CountdownAutologinTimeout.
	;
	mov	bx, segment udata
	mov	ds, bx
	mov	ds:[autologCountdown], al

	movdw	ds:[autologRoom], cxdx

if 0
	;do we still need this?
	push	bp
	mov	ax, MSG_STARTUP_APP_SWITCH_TO_STARTUP
	call	GenCallApplication
	pop	bp
endif

	;
	; AutologInter should display the user's name in big letters.
	;
	mov	cx, ss
	lea	dx, userName
	call	IclasGetUserFullName
EC <    ERROR_C STARTUP_ERROR                                           >

	; append CR and user ID
	mov	ds, cx			; ds = ss
	movdw	esdi, cxdx
	LocalStrLength	TRUE		; es:di = char after null, cx = length
SBCS <	mov	{word} es:[di - 1], C_CR + (C_LEFT_PAREN shl 8)		>
DBCS <	movdw	es:[di - 2], <C_CR + (C_LEFT_PAREN shl 16)>		>
	LocalNextChar	esdi
	mov	si, di			; ds:si = beginning of ID
	call	NetUserGetLoginName
	LocalStrLength	TRUE		; es:di = char after null, cx = length
SBCS <	mov	{word} es:[di - 1], C_RIGHT_PAREN + (C_NULL shl 8)	>
DBCS <	movdw	es:[di - 2], <C_RIGHT_PAREN + (C_NULL shl 16)>		>

	push	bp
	mov	bp, dx
	mov	dx, ss			; dx:bp = userName
	clr	cx
	mov	bx, handle AutologName
	mov	si, offset AutologName
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	;
	; enable AutologInter, and start the timeout countdown.
	;
	push	bp
	mov	bx, handle AutologInter
	mov	si, offset AutologInter
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	;This was causing the autolog timeout to be one minute longer than
	;requested!
	;mov	cx, 3600			;one minute timer...
	mov	cx, 60
	mov	al, TIMER_EVENT_ONE_SHOT
	call	GeodeGetProcessHandle		;returns bx = process handle
	clr	si
	mov	dx, MSG_STARTUP_COUNTDOWN_AUTOLOGIN
	call	TimerStart

	push	ds
	mov	dx, segment dgroup
	mov	ds, dx
	mov	ds:[autologTimerHandle], bx
	mov	ds:[autologTimerID], ax
	pop	ds

	; unblank screen and then disable screen saver
	call	ImInfoInputProcess	; rtn bx = hptr of input process
	mov	ax, MSG_IM_DEACTIVATE_SCREEN_SAVER
	clr	di
	call	ObjMessage
	mov	ax, MSG_IM_DISABLE_SCREEN_SAVER
	clr	di
	call	ObjMessage

	.leave
	ret
WaitForAutologTimeout	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupCountdownAutologin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Countdown another minute of the autologin timeout.
		If the timeout expired, then logout.  Otherwise, decrement
		autologCountdown and restart the timer.

CALLED BY:	MSG_STARTUP_COUNTDOWN_AUTOLOGIN
PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es 	= segment of StartupClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupCountdownAutologin	method dynamic StartupClass, 
					MSG_STARTUP_COUNTDOWN_AUTOLOGIN
	uses	ax,bx,cx,dx,ds,si,di,bp
	.enter

	push	ds	
	mov	bx, segment udata
	mov	ds, bx

	; 
	; if autologCountdown = -1, then the user already acknowledged
	; the autologin, so just ignore.
	;
	cmp	ds:[autologCountdown], -1
	je	popAndExit
	
	cmp	ds:[autologCountdown], 0
	je	logoutNow

	;
	; there's still time left on the clock.  Decrement a minute, and
	; re-start the timer.
	;
	dec	ds:[autologCountdown]
	mov	cx, 3600			;one minute timer...
	mov	al, TIMER_EVENT_ONE_SHOT
	call	GeodeGetProcessHandle		;returns bx = process handle
	clr	si
	mov	dx, MSG_STARTUP_COUNTDOWN_AUTOLOGIN
	call	TimerStart

	mov	ds:[autologTimerHandle], bx
	mov	ds:[autologTimerID], ax

	jmp	popAndExit

logoutNow:
	pop	ds
	push	bp
	mov	bx, handle AutologInter
	mov	si, offset AutologInter
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp
	
	mov	ax, MSG_STARTUP_APP_LOGOUT
	mov	cx, FALSE			; do not query user
	call	GenCallApplication

	; re-enable screen saver
	call	ImInfoInputProcess	; rtn bx = hptr of input process
	mov	ax, MSG_IM_ENABLE_SCREEN_SAVER
	clr	di
	call	ObjMessage

exit:
	.leave
	ret

popAndExit:
	pop	ds
	jmp	exit

StartupCountdownAutologin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupAutologinUser
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In response to the user acknowledging the autologin, complete
		the autologin.

CALLED BY:	MSG_STARTUP_AUTOLOGIN_USER
PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es 	= segment of StartupClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	5/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

wshellUnguidedStateFile	char	"WSHELLUN.STA", C_NULL

StartupAutologinUser	method dynamic StartupClass, 
					MSG_STARTUP_AUTOLOGIN_USER

	;kill the autologin timer -- otherwise it'll be left around for the
	;next autologin and can mess things up.
	push	ds
	mov	bx, segment dgroup
	mov	ds, bx
	mov	bx, ds:[autologTimerHandle]
	mov	ax, ds:[autologTimerID]
	call	TimerStop
	pop	ds

	mov	bx, handle AutologInter
	mov	si, offset AutologInter
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	di, mask MF_CALL
	call	ObjMessage

	; re-enable screen saver
	call	ImInfoInputProcess	; rtn bx = hptr of input process
	mov	ax, MSG_IM_ENABLE_SCREEN_SAVER
	clr	di
	call	ObjMessage

	;
	; complete autologin by flagging that the timeout was acknowledged,
	; and going into the room.
	;

	mov	bx, segment udata
	mov	ds, bx
	mov	ds:[autologCountdown], -1

	movdw	cxdx, ds:[autologRoom]

	cmp	cx, handle Room3Field
	jne	openField

	;
	; We were autologged into the Unguided room.  Since we want to
	; have the classes and class folders open, we need to delete
	; WSHELL_UN.STA so wshellba won't restore from state.
	;

	mov	ax, SP_STATE
	call	FileSetStandardPath

	push	dx
	segmov	ds, cs
	mov	dx, offset wshellUnguidedStateFile
	call	FileDelete
	pop	dx

openField:
	mov	ax, MSG_STARTUP_OPEN_FIELD	; Enter selected room
	mov	bx, handle 0
	mov	di, mask MF_CALL
	GOTO	ObjMessage

StartupAutologinUser	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupVerifyLinks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Spawn a low-priority thread that will whir away in the
		background, verifying links, etc.

CALLED BY:	IStartupOpenApplication

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

IStartupVerifyLinks	proc far
	uses	ax,bx,cx,dx,di,si,ds
	.enter
	;
	; Clear the iclas abort flag so that we don't skip out on verification
	; by accident.
	;
	call	IclasClearAbort

	mov	al, PRIORITY_LOW
	clr	bx
	mov	cx, segment VerifyLinksInThread
	mov	dx, offset VerifyLinksInThread
	mov	di, 2000		; lots o' stack space, for
					; file stuff
	mov	bp, handle 0
	call	ThreadCreate

	segmov	ds, dgroup, ax
	mov	ds:[verifyThread], bx

	.leave
	ret
IStartupVerifyLinks	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateTriggerIfPermissionSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a trigger for the express menu if the
		UP_MESSAGING permission flag is set

CALLED BY:	VerifyLinksInThread

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

CreateTriggerIfPermissionSet	proc far
		uses	cx, dx, bp
		.enter

		call	IclasGetUserPermissions
		test	ax, mask UP_MESSAGING
		jz	done
		call	CreateExpressMenuTrigger
done:
		.leave
		ret
CreateTriggerIfPermissionSet	endp

endif		;--------------------------------------------------------------

InitCode	ends


idata	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyLinksInThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the links in our very own thread

CALLED BY:	IStartupVerifyLinks via ThreadCreate

PASS:		nothing 

RETURN:		doesn't

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

VerifyLinksInThread	proc near
	;
	; Grab the verify semaphore to prevent early logout
	;

		call	IclasGrabVerifySem

		
		mov	bx, handle UpgradeInteraction
		mov	si, offset UpgradeInteraction
		call	IclasInitUserOptr

	;
	; Release the verify semaphore.  Logout is now enabled
	;		
		call	IclasReleaseVerifySem

		
		clr	cx, bp, si
		mov	dx, handle 0
		call	ThreadDestroy
		.UNREACHED
VerifyLinksInThread	endp

endif		;--------------------------------------------------------------

idata	ends


InitCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check extraData word from the AppLaunchBlock to see if we are
		being launched from the install program.

Copied from Proc/procClass.asm:

;	MSG_META_ATTACH is sent to any Geode which has a process, when it is
; first loaded.  It is also used in the object world to notify objects on
; an "active list" that the application has been brought back up from a 
; state file.  As the method is used for different purposes, the data
; passed varies based on usage:
;
; As sent automatically by GeodeLoad when loading a geode in which 
; GA_APPLICATION IS set (cx, dx values passed to GeodeLoad in di, bp):
;
; Pass:
;	dx	- Block handle to block of structure AppLaunchBlock
;		  (MUST BE PASSED)
; Return:
;	Nothing

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupAttach	method	StartupClass, MSG_META_ATTACH

if	(1)
	; Before any messages go flying about, change the GenFields that
	; Welcome has to be run by the global UI thread.  See routine header
	; for more info.		-- Doug 6/1/92
	;
	call	ChangeFieldsToBeRunByGlobalUIThread
endif

	mov	di, offset StartupClass
	GOTO	ObjCallSuperNoLock
StartupAttach	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	ChangeFieldsToBeRunByGlobalUIThread

DESCRIPTION:	Change running thread of Startup's fields to be the global UI
		thread, to prevent horrible death that would otherwise occur
		when the fields are added below the GenSystem object.  Yes, 
		this is a pretty bizarre thing for an app to be doing, but
		Startup is a pretty bizarre app.

		We do this at the very start of MSG_ATTACH to make sure that
		the change occurs before any message is sent to the field
		objects.  As the fields are marked as "ui-object" in the .gp
		file, you might be concerned that MSG_PROCESS_CREATE_UI_THREAD
		will come along & stomp over the "other info" thread, undoing
		our work here.  Not so.  MSG_PROCESS_CREATE_UI_THREAD will
		only set the running thread for blocks still having an
		"other info" value of -2.  We escape with impunity.

		We can also do this before the call to ObjAssocVMFile, which
		associates Welcome's resources with its state files.  This is
		possible because ObjAssocVMFile doesn't care what thread runs
		any of a geode's resources; it only needs to know what thread
		should run any duplicated resources that are suddenly now
		being loaded.

		Similarly, we should be able to exit, or detach, without having
		to do anything further, as the effected resources are part of
		Welcome's original resources; the new running thread we stuff
		here won't be saved out to state, rather it will just be 
		discarded as the memory handle is freed.  Next time we start
		up, we'll need to do this same operation, again at
		MSG_META_ATTACH.

CALLED BY:	INTERNAL
		WelcomeAttach

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	6/1/92		Initial version
------------------------------------------------------------------------------@

if	(1)
ChangeFieldsToBeRunByGlobalUIThread	proc	near	uses	ax, bx
	.enter
	mov	bx, handle ui		; get FIRST thread of UI (which at
	call	ProcInfo		; this time runs system object)
	mov	ax, bx			; pass in ax, as new running thread

	push	ax
	mov	bx, handle Room1Field
					; bx = handle of block to modify
					; ax = new HM_otherInfo value
	call	MemModifyOtherInfo
	pop	ax

	push	ax
	mov	bx, handle Room2Field
					; bx = handle of block to modify
					; ax = new HM_otherInfo value
	call	MemModifyOtherInfo
	pop	ax

	push	ax
	mov	bx, handle Room3Field
					; bx = handle of block to modify
					; ax = new HM_otherInfo value
	call	MemModifyOtherInfo
	pop	ax

ifdef ISTARTUP
	push	ax
	mov	bx, handle LoginRoomField
					; bx = handle of block to modify
					; ax = new HM_otherInfo value
	call	MemModifyOtherInfo
	pop	ax

ifdef MOUSETUTORIAL
	mov	bx, handle MouseRoomField
					; bx = handle of block to modify
					; ax = new HM_otherInfo value
	call	MemModifyOtherInfo
endif
endif
	.leave
	ret
ChangeFieldsToBeRunByGlobalUIThread	endp
endif

InitCode	ends


CommonCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupMouseTutorial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method is called when the user clicks on the Mouse
		Tutorial trigger from the startup screen.  It runs the
		Mouse Tutorial, and changes the keyboard default to 
		the Entry Level trigger.

CALLED BY:	MSG_STARTUP_MOUSE_TUTORIAL
PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es 	= segment of StartupClass
		ax	= message #
RETURN:		
DESTROYED:	ax, bx, cx, dx, ds, si
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CL	11/14/92   	Initial version
	Joon	3/8/93		Mouse tutorial runs in it's own room

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef MOUSETUTORIAL	;------------------------------------------------------

StartupMouseTutorial	method dynamic StartupClass, 
					MSG_STARTUP_MOUSE_TUTORIAL
	.enter
	;
	; Open field from which mouse tutorial will be run
	;
	mov	ax, MSG_STARTUP_OPEN_FIELD
	mov	bx, handle 0
	mov	cx, handle MouseRoomField
	mov	dx, offset MouseRoomField
	mov	di, mask MF_CALL
	call	ObjMessage

	;
	; once the mouse tutorial is run, the default action becomes
	; entering k2 shell for students and entry level for everyone else
	;
	call	IclasGetCurrentUserType

	mov	bx, handle Room1
	mov	si, offset Room1
	cmp	ah, UT_STUDENT
	je	haveRoom
	cmp	ah, UT_GENERIC
	je	haveRoom

	mov	bx, handle Room2
	mov	si, offset Room2

haveRoom:
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	.leave
	ret
StartupMouseTutorial	endm

endif			; ifdef MOUSETUTORIAL ---------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupOpenField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open field

CALLED BY:	MSG_STARTUP_OPEN_FIELD
PASS:		ds = es = dgroup
		^lcx:dx = field to open
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupOpenField method dynamic StartupClass, MSG_STARTUP_OPEN_FIELD

	;
	; if we are detaching or waiting for another field to exit before
	; opening a new field, ignore any request to open a field
	;
ifdef ISTARTUP
	test	ds:[processFlags], mask SPF_DETACHING or \
			mask SPF_PENDING_FIELD or mask SPF_DETACH_AFTER_VERIFY
else
	test	ds:[processFlags], mask SPF_DETACHING or mask SPF_PENDING_FIELD
endif
	LONG jnz	done

	tstdw	ds:[currentField]		; no current field?
	jz	openField			; yes, open requested one
	cmpdw	cxdx, ds:[currentField]		; entering current field again?
	je	openField			; yes, do it

	;
	; else, close current field before opening new one.  Wait for
	; current field to finishing detaching (MSG_META_FIELD_NOTIFY_DETACH)
	; before opening new field
	;
	movdw	ds:[pendingField], cxdx		; save field to open
	ornf	ds:[processFlags], mask SPF_PENDING_FIELD

	; We need to ask everyone concerned if this is ok.  When this
	; procedure is done, the ACK message below will be sent back
	; to us and we can begin closing this field.
	;
	mov	ax, CFCT_BEGIN_FIELD_CHANGE
	mov	dx, handle 0
	clr	cx
	mov	bx, MSG_STARTUP_CONFIRM_FIELD_CHANGE_ACK
	call	UserConfirmFieldChange
	jnc	done

	; If carry set form UserConfirmFieldChange, then a confirmation
	; process is already in progress.  In that case, clean up and
	; bail.
	andnf	ds:[processFlags], not mask SPF_PENDING_FIELD
	clrdw	ds:[pendingField]
	jmp	done

openField:
	;
	; open requested field
	;
	movdw	ds:[currentField], cxdx		; save field
	movdw	bxsi, cxdx			; ^lbx:si = field to open

	;
	; Set the field we should return to after a shutdown to DOS
	;
	mov	ax, MSG_STARTUP_APP_SET_RETURN_FIELD
	call	GenCallApplication

ifdef WELCOME
	cmp	bx, handle Room1Field		; no background bitmap for
	je	noBitmap			;  consumer ui field
endif
	mov	ax, MSG_GEN_FIELD_ENABLE_BITMAP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

ifdef WELCOME
noBitmap:
endif
	mov	ax, MSG_META_ATTACH
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_USABLE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage
done:
	ret
StartupOpenField endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupConfirmFieldChangeAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback from UserConfirmFieldChange.

CALLED BY:	MSG_STARTUP_CONFIRM_FIELD_CHANGE_ACK

PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es 	= segment of StartupClass
		ax	= message #
		cx	= TRUE : go ahead and begin change
			  FALSE : abort field change
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	8/26/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupConfirmFieldChangeAck	method dynamic StartupClass, 
					MSG_STARTUP_CONFIRM_FIELD_CHANGE_ACK

	; CX = 0 -- abort field change!
	jcxz	diveDiveDive

	; We're coo'.  Begin changing the field by zapping current one.
	
	;
	; start ignoring input while we wait for current field to detach,
	; we'll accept input again when we get MSG_META_FIELD_NOTIFY_DETACH
	;
	call	StartupIgnoreInput

	;
	; tell current field to detach
	;
	movdw	bxsi, ds:[currentField]
	clr	cx
	clr	dx
	clr	bp
	mov	ax, MSG_META_DETACH
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	GOTO	ObjMessage			; <-- EXIT POINT

diveDiveDive:
	andnf	ds:[processFlags], not mask SPF_PENDING_FIELD
	clrdw	ds:[pendingField]
	ret					; <-- EXIT POINT

StartupConfirmFieldChangeAck	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldNotifyStartLauncherError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Error starting launcher for field, detach field.

CALLED BY:	MSG_META_FIELD_NOTIFY_START_LAUNCHER_ERROR
PASS:		ds = es = dgroup
		^lcx:dx = GenField
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupFieldNotifyStartLauncherError method dynamic StartupClass, MSG_META_FIELD_NOTIFY_START_LAUNCHER_ERROR
	clr	bp				; always return to Startup
						;	and detach field
	GOTO	ReturnToStartupAndDetachField
StartupFieldNotifyStartLauncherError endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldNotifyNoFocus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that no more stuff in room, detach it.

CALLED BY:	MSG_META_FIELD_NOTIFY_NO_FOCUS
PASS:		ds = es = dgroup
		^lcx:dx = GenField
		bp = non-zero if shutdown
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef ISTARTUP	;--------------------------------------------------------------

ifndef GPC  ; nowhere to return to

StartupFieldNotifyNoFocus	method dynamic StartupClass, 
					MSG_META_FIELD_NOTIFY_NO_FOCUS
	tst	bp
	jz	notShutdown

	;
	; Shutdown, ReturnToStartupAndDetachField will not return us to Startup
	; main screen, but we also want to set the main screen primary
	; not-usable so when this no-focus field gets set not-usable and
	; disappears, the main screen won't show itself
	;
	push	cx, dx, bp
	mov	bx, handle StartupWindow
	mov	si, offset StartupWindow
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp

notShutdown:
						; if shutdown, don't return
						;	to Startup
	FALL_THRU	ReturnToStartupAndDetachField
StartupFieldNotifyNoFocus endm

endif

else	; ISTARTUP ------------------------------------------------------------

StartupFieldNotifyNoFocus	method dynamic StartupClass, 
					MSG_META_FIELD_NOTIFY_NO_FOCUS
	uses	cx, dx
	.enter

	; Don't do anything if ignoring input
	;
	test	ds:[processFlags], mask SPF_IGNORING_INPUT
	LONG 	jnz detachField

	; Assume we don't want to see the CYWA screen.
	;
	push	cx, dx, bp
	mov	bx, handle StartupWindow
	mov	si, offset StartupWindow
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp

	; Check to see if we are shutting down.
	;
	tst	bp
	jnz	fallThru

	; We are not shutting down.
	;
	cmp	cx, handle LoginRoomField
	je	login

	call	IclasGetIStartupRoomToEnter
	cmp	cx, IIR_LOGIN_ROOM
	je	returnToLogin

	cmp	cx, IIR_K2_ROOM
	jne	notK2

	mov	cx, handle Room1Field
	mov	dx, offset Room1Field
	jmp	openField

notK2:
	cmp	cx, IIR_GUIDED_ROOM
	jne	notGuided

	mov	cx, handle Room2Field
	mov	dx, offset Room2Field
	jmp	openField

notGuided:
	cmp	cx, IIR_UNGUIDED_ROOM
EC <	ERROR_NE	-1		; IclasIStartupRoom unknown	>
	jne	returnToLogin

	mov	cx, handle Room3Field
	mov	dx, offset Room3Field
	jmp	openField

returnToLogin:
	call	IStartupStopTimer	; stop polling for messages
	call	IStartupRemoveFromGCNList

	mov	cx, handle LoginRoomField
	mov	dx, offset LoginRoomField
	jmp	openField

login:
	; IStartupInitUser will return carry set and open the field itself
	; if we are doing autologin.
	;
	call	IStartupInitUser
	jc	detachField

	; FIND OUT WHAT ROOM THE USER WANTS TO STARTUP IN
	;
	clr	bp			; assume we want to return to startup
	call	IStartupGetStartupRoom
	jnc	fallThru

openField:
	mov	ax, MSG_STARTUP_OPEN_FIELD
	mov	bx, handle 0
	clr	di
	call	ObjMessage

detachField:
	mov	bp, -1			; just detach field

fallThru:
	.leave
	FALL_THRU	ReturnToStartupAndDetachField
StartupFieldNotifyNoFocus endm

endif	;----------------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnToStartupAndDetachField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ReturnToStartupAndDetachField

CALLED BY:	INTERNAL
			StartupFieldNotifyStartLauncherError
			StartupFieldNotifyNoFocus
PASS:		ds = es = dgroup
		^lcx:dx = GenField
		bp = non-zero to just detach field
		bp = zero to return to Startup and detach field
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		When this is called, there are no apps in the field, so
		we can just detach it, and not worry about whether we
		should saving to state or quit apps.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnToStartupAndDetachField	proc	far
	;
	; return to Startup screen
	;
	pushdw	cxdx				; save field
	tst	bp				; return to Startup?
	jnz	detachField			; nope

	mov	ax, MSG_STARTUP_APP_SWITCH_TO_STARTUP
	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	clr	di
	call	ObjMessage

detachField:
	;
	; start ignoring input while we wait for field to detach,
	; we'll accept input again when we get MSG_META_FIELD_NOTIFY_DETACH
	;
	call	StartupIgnoreInput

	;
	; detach field
	;
	popdw	bxsi				; ^lbx:si = field
	mov	ax, MSG_META_DETACH
	clr	cx
	clr	dx
	clr	bp
	clr	di
	GOTO	ObjMessage

ReturnToStartupAndDetachField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupProcessGotoField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle (most likely IACP) message to go to a particular field.

CALLED BY:	MSG_STARTUP_PROCESS_GOTO_FIELD

PASS:		*ds:si	= StartupProcessClass object
		ds:di	= StartupProcessClass instance data
		ds:bx	= StartupProcessClass object (same as *ds:si)
		es 	= segment of StartupProcessClass
		ax	= message #
		cx	= StartupField
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	joon	12/09/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupProcessGotoField	method dynamic StartupProcessClass, 
					MSG_STARTUP_PROCESS_GOTO_FIELD

	mov	ax, cx
	cmp	ax, SF_WELCOME
	jne	checkField1

	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	mov	di, mask MF_CALL
	mov	ax, MSG_STARTUP_APP_SWITCH_TO_STARTUP
	GOTO	ObjMessage

checkField1:
	mov	cx, handle Room1Field		;assume room 1
	mov	dx, offset Room1Field
	cmp	ax, SF_FIELD1
	je	gotoField

ifndef WELCOME
	mov	cx, handle Room2Field		;assume room 2
	mov	dx, offset Room2Field
	cmp	ax, SF_FIELD2
	je	gotoField
endif

	mov	cx, handle Room3Field		;assume room 3
	mov	dx, offset Room3Field
	cmp	ax, SF_FIELD3
	jne	done

gotoField:
	mov	bx, handle 0
	mov	ax, MSG_STARTUP_OPEN_FIELD
	mov	di, mask MF_CALL
	GOTO	ObjMessage
done:
	ret
StartupProcessGotoField	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupRemoveFromGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove IStartup from the express menu change GCN list,
		since the current user is logging out, and the next
		user may or may not have permission to send messages.
		Also prevents bogus "send messages appears twice" that
		I've seen occasionally

CALLED BY:	StartupFieldNotifyNoFocus

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/25/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef ISTARTUP
IStartupRemoveFromGCNList	proc near
		uses	ax,bx,cx,dx
		.enter

		mov	cx, handle 0
		clr	dx
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
		call	GCNListRemove

		.leave
		ret
IStartupRemoveFromGCNList	endp
endif


COMMENT @----------------------------------------------------------------------

METHOD:		StartupTryToSwitchToStartup -- 
		MSG_STARTUP_TRY_TO_SWITCH_TO_STARTUP for StartupClass

DESCRIPTION:	Tries to switch to startup.  Actually, begins the process.

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_STARTUP_TRY_TO_SWITCH_TO_STARTUP

RETURN:		nothing
		ax, cx, dx, bp - destroyed

ALLOWED TO DESTROY:	
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chris	8/ 2/93        	Initial Version, taken from OLField in spec UI

------------------------------------------------------------------------------@

ifndef _VS150			;normal stuff

StartupTryToSwitchToStartup	method	StartupClass,
					MSG_STARTUP_TRY_TO_SWITCH_TO_STARTUP

	;
	; Inform current field that we are going to detach it.  If it is in
	; 'quitOnClose' mode, it will quit all apps and detach itself, at
	; which time we'll get MSG_META_FIELD_NOTIFY_NO_FOCUS when we'll
	; switch to main screen.  If not, we'll just switch to main screen
	; now and wait for user to exit Startup (when we'll detach this field)
	; or enter another field (when we'll detach this field).
	;
	tstdw	ds:[currentField]	; no current field
	jz	switchBackNow

	movdw	bxsi, ds:[currentField]	; ^lbx:si = current field
	mov	ax, MSG_GEN_FIELD_ABOUT_TO_CLOSE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry clear if not 'quitOnClose'
	jnc	switchBackNow

	;
	; Else, we have to wait until all applications in the field quit
	; themselves.  When that happens, the field will detach itself and
	; we'll get MSG_META_FIELD_NOTIFY_NO_FOCUS.  The user can choose to
	; abort the field-close by aborting exiting of one of the apps, so
	; we can't really turn on ignore-input or anything like that.
	;
	ret

switchBackNow:
	;
	; switch back to main screen now
	;
	mov	ax, MSG_STARTUP_APP_SWITCH_TO_STARTUP
	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	clr	di
	GOTO	ObjMessage

StartupTryToSwitchToStartup	endp

else			;REDWOOD
	
StartupTryToSwitchToStartup	method dynamic	StartupClass, \
				MSG_STARTUP_TRY_TO_SWITCH_TO_STARTUP
	;
	; Record our true application launch message and send out a 
	; query now to the document group of the current application.
	;
	call	MemOwner		;get the process handle
	mov	ax, MSG_STARTUP_REALLY_TRY_TO_SWITCH_TO_STARTUP
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			;pass in cx to MSG_META_QUERY_DOCUMENTS

	;
	; Let's try saving any documents that are open, by sending a message
	; to the application with the full screen exclusive.  7/27/93 cbh
	;
	push	si
	mov	ax, MSG_META_QUERY_SAVE_DOCUMENTS
	mov	bx, segment GenClass
	mov	si, offset GenClass
	mov	di, mask MF_RECORD
	call	ObjMessage

	clr	bp
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_TRANSPARENT_DETACH_FULL_SCREEN_EXCL
	mov	cx, di
	clr	dx
	call	GCNListSend
	pop	si
	ret
StartupTryToSwitchToStartup	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupReallyTryToSwitchToStartup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to Startup main screen, leaving current field.

CALLED BY:	MSG_STARTUP_REALLY_TRY_TO_SWITCH_TO_STARTUP
			(F2 monitor or "Return to Welcome" button in
				ExpressMenuControl control panel)
PASS:		ds = es = dgroup
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Tell current field that we are about to close it.  It will
		want to quit all current apps if it is in 'quitOnClose' mode.
		If so, we'll wait to get MSG_META_FIELD_NOTIFY_NO_FOCUS
		before we actually switch to Startup's main screen.  If not,
		we can switch immediately.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/26/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef _VS150

StartupReallyTryToSwitchToStartup	method	StartupClass,
				MSG_STARTUP_REALLY_TRY_TO_SWITCH_TO_STARTUP

	;
	; Inform current field that we are going to detach it.  If it is in
	; 'quitOnClose' mode, it will quit all apps and detach itself, at
	; which time we'll get MSG_META_FIELD_NOTIFY_NO_FOCUS when we'll
	; switch to main screen.  If not, we'll just switch to main screen
	; now and wait for user to exit Startup (when we'll detach this field)
	; or enter another field (when we'll detach this field).
	;
	tstdw	ds:[currentField]	; no current field
	jz	switchBackNow

	movdw	bxsi, ds:[currentField]	; ^lbx:si = current field
	mov	ax, MSG_GEN_FIELD_ABOUT_TO_CLOSE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage		; carry clear if not 'quitOnClose'

;	Changed 7/23/93 cbh to not wait for apps before switching.
;	jnc	switchBackNow

	;
	; Else, we have to wait until all applications in the field quit
	; themselves.  When that happens, the field will detach itself and
	; we'll get MSG_META_FIELD_NOTIFY_NO_FOCUS.  The user can choose to
	; abort the field-close by aborting exiting of one of the apps, so
	; we can't really turn on ignore-input or anything like that.
	;
;	ret

switchBackNow:
	;
	; switch back to main screen now
	;
	mov	ax, MSG_STARTUP_APP_SWITCH_TO_STARTUP
	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	clr	di
	GOTO	ObjMessage

StartupReallyTryToSwitchToStartup	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupShellToDOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shell to DOS

CALLED BY:	MSG_STARTUP_SHELL_TO_DOS
PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es 	= segment of StartupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/10/92   	Initial version
	Joon	5/16/93		Write out batch file before shutting down
	dlitwin	9/8/93		Added Iclas call to inform that we are
				shelling to DOS, not logging out.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

SPAWN_MAX_BATCH_SIZE	equ	4096

idline	char	"@ECHO OFF", C_CR, C_LF, \
		"CD Z:\\PUBLIC", C_CR, C_LF, "H:", C_CR, C_LF, \
		"SET ID=", C_NULL
dline	char	C_CR, C_LF, "SET D=", C_NULL
cvline	char	C_CR, C_LF, "SET CV=", C_NULL
gline	char	C_CR, C_LF, "SET G=", C_NULL
hvline	char	C_CR, C_LF, "SET HV=", C_NULL
path	char	"PATH", C_NULL
teacher	char	"TEACHERS", C_NULL
student	char	"STUDENTS", C_NULL
generic	char	"GENERICS", C_NULL
office	char	"OFFICE", C_NULL
admin	char	"ADMIN", C_NULL

IStartupShellToDOS	method dynamic StartupClass, 
					MSG_STARTUP_SHELL_TO_DOS
	;
	; Add drive mapping commands
	;
	mov	ax, SPAWN_MAX_BATCH_SIZE
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			; create batch buffer
	LONG jc	done

	mov	bp, bx				; bp <= memory block handle
	mov	es, ax
	clr	di				; es:di = buffer
	;
	; Write out 'SET ID=<loginName>'
	;
	segmov	ds, cs
	mov	si, offset cs:[idline]		; ds:si = idline
	call	MyLocalCopyString

	push	ds
	segmov	ds, es
	mov	si, di
	call	NetUserGetLoginName
	pop	ds

	call	MyLocalScanEOBuffer
	;
	; Write out 'SET D=<paddedID>'
	;
	mov	si, offset cs:[dline]		; ds:si = dline
	call	MyLocalCopyString
	call	IclasGetUserDir
	call	MyLocalScanEOBuffer
	;
	; Write out 'SET CV=<connection number> if generic
	;
	call	IclasGetCurrentUserType
	cmp	ah, UT_GENERIC
	jne	writeG

	mov	si, offset cs:[cvline]
	call	MyLocalCopyString
	call	IclasGetUserDir			; UserDir == connection number
	call	MyLocalScanEOBuffer
writeG:
	;
	; Write out 'SET G=<userType>'
	;
	mov	si, offset cs:[gline]
	call	MyLocalCopyString

	call	IclasGetCurrentUserType
	mov	si, offset cs:[teacher]
	cmp	ah, UT_TEACHER
	je	haveUser
	mov	si, offset cs:[student]
	cmp	ah, UT_STUDENT
	je	haveUser
	mov	si, offset cs:[generic]
	cmp	ah, UT_GENERIC
	je	haveUser
	mov	si, offset cs:[office]
	cmp	ah, UT_OFFICE
	je	haveUser
	mov	si, offset cs:[admin]
	cmp	ah, UT_ADMIN
	je	haveUser
	mov	si, offset cs:[nullString]
haveUser:
	call	MyLocalCopyString
	;
	; Write out 'SET HV=<homeVolume>'
	;
	mov	si, offset cs:[hvline]
	call	MyLocalCopyString
	mov	ax, SGIT_SYSTEM_DISK
	call	SysGetInfo
	mov	bx, ax
	call	DiskGetVolumeName
	call	MyLocalScanEOBuffer
	mov	al, ':'
	stosb
	mov	ax, C_CR or (C_LF shl 8)
	stosw
	;
	; Write out path statement
	;
	mov	si, offset cs:[path]
	call	MyLocalCopyString
	mov	al, '='
	stosb
	mov	cx, 0ffh			; what's the maximum
	mov	si, offset cs:[path]		; ds:si = path environment var
	call	SysGetDosEnvironment
	jc	crlf
	cmp	{word} es:[di], 'Z:'
	je	crlf

	push	di
	call	MyLocalScanEOBuffer
	not	cx
	segmov	ds, es
	mov	si, di
	add	di, 8				; length of 'Z:.;Y:.;'
	std
	rep	movsb
	cld
	pop	di
	;
	; Write 'Z:.;Y:.'
	;
	mov	ax, 'Z:'
	stosw
	mov	ax, '.;'
	stosw
	mov	ax, 'Y:'
	stosw
	mov	ax, '.;'
	stosw
crlf:
	call	MyLocalScanEOBuffer
	mov	ax, C_CR or (C_LF shl 8)
	stosw
	;
	; Write out map commands
	;
	segmov	ds, es
	mov	si, di				; ds:si = buffer
	mov	dx, di				; dx = bytes already in buffer
	call	IclasAddMapCommandsToBatchFile
	mov	cx, dx
	;
	; Write everything to temp.bat
	;
	call	IStartupCreateTempFile
	jc	memFree

	clr	ax, dx
	call	FileWrite

	pushf
	call    FileClose
	popf

memFree:
	pushf
	mov	bx, bp
	call	MemFree
	popf
	jc	done

	mov	ax, SST_CLEAN
	clr	cx, dx, bp
	call	SysShutdown
done:
	ret

MyLocalCopyString:
	LocalCopyString
	dec	di				; es:di = C_NULL
	retn

MyLocalScanEOBuffer:
	mov	al, C_NULL
	mov	cx, -1
	repne	scasb
	dec	di				; es:di = C_NULL
	retn

IStartupShellToDOS	endm

;
; Pass:		nothing
; Return:	if carry set, error
;		else bx = handle 
;
environmentVariable	char	"V"
nullString		char	C_NULL
batchfile		char	"TEMP.BAT",C_NULL

IStartupCreateTempFile	proc	near
tempFile	local	PathName
	uses	ds, es, cx
	.enter
	;
	; Get "virtual drive" environment variable.
	;
	segmov	ds, cs
	mov	si, offset cs:[environmentVariable]
	segmov	es, ss
	lea	di, ss:[tempFile]
	mov	cx, size PathName
	call	SysGetDosEnvironment
	jc	done

	clr	al
	mov	cx, -1
	repne	scasb
	dec	di
	;
	; Append TEMP.BAT to virtual drive
	;
	mov	si, offset cs:[batchfile]
	mov	cx, size batchfile
	rep	movsb
	;
	; Create batch file
	;
	segmov  ds, ss
	lea     dx, ss:[tempFile]
	clr     cx                              ; cx = FileAttrs
	mov     ax, (FileCreateFlags <1,0,FILE_CREATE_TRUNCATE> shl 8)\
	            + FileAccessFlags <FE_NONE, FA_WRITE_ONLY> 
	call    FileCreate
	mov_tr  bx, ax                          ; bx = file handle
done:
	.leave
	ret
IStartupCreateTempFile	endp

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IStartupBeginEDLANMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up dialog box asking user whether or not to begin
		EDLAN compatibility mode (pass keys on to BIOS).
		Begin EDLAN compatibility mode if appropriate.

CALLED BY:	MSG_STARTUP_BEGIN_EDLAN_MODE
PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es 	= segment of StartupClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	3/25/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

IStartupBeginEDLANMode	method dynamic StartupClass, 
					MSG_STARTUP_BEGIN_EDLAN_MODE
	mov	bx, handle EDLanQueryString
	mov	si, offset EDLanQueryString
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]		; ds:si = EDLanQueryString

	.assert (offset SDP_helpContext eq offset SDP_customTriggers+4)
	.assert (offset SDP_customTriggers eq offset SDP_stringArg2+4)
	.assert (offset SDP_stringArg2 eq offset SDP_stringArg1+4)
	.assert (offset SDP_stringArg1 eq offset SDP_customString+4)
	.assert (offset SDP_customString eq offset SDP_customFlags+2)
	.assert (offset SDP_customFlags eq 0)

	clr	ax
	pushdw	axax			; don't care about SDP_helpContext
	pushdw	axax			; don't care about SDP_customTriggers
	pushdw	axax			; don't care about SDP_stringArg2
	pushdw	axax			; don't care about SDP_stringArg1
	pushdw	dssi			; save SDP_customString (ax:dx)
	mov	ax, CustomDialogBoxFlags <TRUE, CDT_QUESTION, GIT_AFFIRMATION,0>
	push	ax
	call	UserStandardDialog
	call	MemUnlock

	cmp	ax, IC_YES
	je	enterEDLan

	ANDNF	es:[keySequenceMode], not (mask KSM_EDLAN)
	ret				; <==== EXIT HERE

enterEDLan:
	mov	di, DR_KBD_ADD_HOTKEY
	clr	ax
	mov	cx, (VC_ISCTRL shl 8) or VC_INVALID_KEY
	mov	bx, handle StartupApp
	mov	si, offset StartupApp
	mov	bp, MSG_STARTUP_APP_KEYBOARD_DRIVER_CHAR
	jmp	es:[keyboardDriverStrategy]	; call keyboard driver

IStartupBeginEDLANMode	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupNotifyExpressMenuChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Create a button in the express menu whenever one is
		created.  In WELCOME, we create a "Return to Welcome"
		button. In IStartup, we create a "Send Messages" button.

PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		es	= dgroup

		bp	= GCNExpressMenuNotificationType
		^lcx:dx	= Express Menu Controller

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       brianc	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef WELCOME
StartupNotifyExpressMenuChange	method	dynamic	StartupClass, 
					MSG_NOTIFY_EXPRESS_MENU_CHANGE
	.enter

	cmp	bp, GCNEMNT_CREATED
	jne	done

	mov	bx, cx		; ^lbx:si <- ExpressMenuControl
	mov	si, dx

	mov	dx, size CreateExpressMenuControlItemParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].CEMCIP_feature, CEMCIF_UTILITIES_PANEL
	mov	ss:[bp].CEMCIP_class.segment, segment GenTriggerClass
	mov	ss:[bp].CEMCIP_class.offset, offset GenTriggerClass
	mov	ss:[bp].CEMCIP_itemPriority, CEMCIP_NETMSG_SEND_MESSAGE
	mov	ss:[bp].CEMCIP_responseMessage, MSG_STARTUP_EXPRESS_MENU_CONTROL_ITEM_CREATED
	mov	ss:[bp].CEMCIP_responseDestination.handle, handle 0
	mov	ss:[bp].CEMCIP_responseDestination.chunk, 0
	movdw	ss:[bp].CEMCIP_field, 0		; field doesn't matter
	mov	ax, MSG_EXPRESS_MENU_CONTROL_CREATE_ITEM
	mov	di, mask MF_STACK
	call	ObjMessage
	add	sp, size CreateExpressMenuControlItemParams

done:
	.leave
	ret
StartupNotifyExpressMenuChange	endm
endif ; not WELCOME


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupExpressMenuControlItemCreated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		es	= dgroup

		ss:bp	= CreateExpressMenuControlItemResponseParams

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       brianc	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef WELCOME
StartupExpressMenuControlItemCreated	method	dynamic	StartupClass, 
				MSG_STARTUP_EXPRESS_MENU_CONTROL_ITEM_CREATED

	movdw	bxsi, ss:[bp].CEMCIRP_newItem

	;
	; Now, set the action message of the trigger
	;

	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
ifdef WELCOME
	mov	cx, MSG_STARTUP_TRY_TO_SWITCH_TO_STARTUP
else
	mov	cx, MSG_STARTUP_SEND_TEXT_MESSAGE
endif
	clr	di
	call	ObjMessage

	;
	; Set the destination of the trigger
	;
	mov	ax, MSG_GEN_TRIGGER_SET_DESTINATION
	mov	cx, handle 0
	mov	dx, 0
	clr	di
	call	ObjMessage

	;
	; Set its moniker properly.
	; 

	mov	cx, handle StartupUtilitiesPanelMoniker
	mov	dx, offset StartupUtilitiesPanelMoniker
	mov	bp, VUM_MANUAL
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_OPTR
	clr	di
	call	ObjMessage

	;
	; Set it usable, finally.
	; 
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	ret
StartupExpressMenuControlItemCreated	endm
endif ; not WELCOME


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupIngoreInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	begin ingore input, if not already doing so

CALLED BY:	

PASS:		ds - dgroup of StartupClass (dgroup)

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupIgnoreInput	proc	far
	test	ds:[processFlags], mask SPF_IGNORING_INPUT
	jnz	alreadyIgnoring
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	call	GenCallApplication
	ornf	ds:[processFlags], mask SPF_IGNORING_INPUT
alreadyIgnoring:
	ret
StartupIgnoreInput	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StarutpAcceptInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	end ingore input, if haven't already done so

CALLED BY:	

PASS:		ds - dgroup of StartupClass (dgroup)

RETURN:		nothing

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupAcceptInput	proc	far
	test	ds:[processFlags], mask SPF_IGNORING_INPUT
	jz	afterAcceptInput
	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	GenCallApplication
	andnf	ds:[processFlags], not mask SPF_IGNORING_INPUT
afterAcceptInput:
	ret
StartupAcceptInput	endp

CommonCode	ends


ExitCode	segment

COMMENT @----------------------------------------------------------------------

METHOD:		StartupDetach

DESCRIPTION:	Detach the Startup application

PASS:
	*ds:si - instance data
	es - segment of StartupClass

	ax - MSG_META_DETACH

	cx, dx, bp - ?
RETURN:
	carry - ?
	ax, cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Initial version

------------------------------------------------------------------------------@

StartupDetach	method	StartupClass, MSG_META_DETACH
	tst	es:[inEngineMode]	;If in engineMode, just pass to
	jz	1$			; superclass	
	mov	di, offset StartupClass
	GOTO	ObjCallSuperNoLock
1$:
	cmp	dx, -1			;If DETACH sent by Startup, don't ACK.
	jne	3$
	mov	dx, ds:[detachOD].handle
	mov	bp, ds:[detachOD].chunk
3$:
	mov	ds:[detachOD].handle,dx		;Save OD to ACK away...
	mov	ds:[detachOD].chunk,bp
	mov	ds:[detachID], cx

ifdef ISTARTUP

	;
	; If verify thread is active, can't detach
	;

	tst	ds:[verifyThread]
	jz	threadGone
	ornf	ds:[processFlags], mask SPF_DETACH_AFTER_VERIFY
	ret

threadGone:

endif

	;
	; If any field still open, we can't detach.
	; 
	cmpdw	ds:[currentField], 0
	jz	normalDetach

	;
	; A field is still open, we are waiting for it to detach (a DETACH was
	; sent to it by the same guy that sent a detach to our field).  We'll
	; just wait until that field exits (we'll get
	; MSG_META_FIELD_NOTIFY_DETACH).
	;
	ornf	ds:[processFlags], mask SPF_DETACH_PENDING
	ret

normalDetach:
	test	ds:[processFlags], mask SPF_MONITOR_ACTIVE
	jz	MonitorOut

	push	cx,dx,bp,es
	mov	bx, offset dgroup:hotKeyMonitor
	mov	al, mask MF_REMOVE_IMMEDIATE
	call	ImRemoveMonitor
	pop	cx,dx,bp,es

	and	ds:[processFlags], not mask SPF_MONITOR_ACTIVE
MonitorOut:

	;
	; call superclass to detach
	;

	mov	ax, MSG_META_DETACH
	mov	di, offset StartupClass
	GOTO	ObjCallSuperNoLock

StartupDetach	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Handle notification that the verify thread is done.

PASS:		ds, es	- dgroup
		dx - verify thread handle

RETURN:		nothing 

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

StartupAck	method	dynamic	StartupClass, 
					MSG_META_ACK
		cmp	dx, ds:[verifyThread]
		jne	gotoSuper

		clr	ds:[verifyThread]
		test	ds:[processFlags], mask SPF_DETACH_AFTER_VERIFY
		jnz	reSendDetach		; <- EXIT

		ret				; <- EXIT

gotoSuper:
		mov	di, offset StartupClass
		GOTO	ObjCallSuperNoLock	; <- EXIT

StartupAck	endm

endif		;--------------------------------------------------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupFieldNotifyDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that another room is closed. If none open and detach
		pending, call ourselves with MSG_META_DETACH and the original
		parameters.

CALLED BY:	MSG_META_FIELD_NOTIFY_DETACH
PASS:		ds = es = dgroup
		^lcx:dx = GenField
		bp = non-zero if shutdown
RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupFieldNotifyDetach method dynamic StartupClass,
						MSG_META_FIELD_NOTIFY_DETACH
	;
	; if the current field has detached, note this
	;
	cmpdw	cxdx, ds:[currentField]
	jne	notCurrentField
	clrdw	ds:[currentField]
notCurrentField:

	;
	; if we were ignoring input while waiting for the field to detach,
	; we'll accept input now
	;
	call	StartupAcceptInput

	;
	; if we were waiting for the field to exit before we exit ourselves,
	; exit now
	;
	test	ds:[processFlags], mask SPF_DETACH_PENDING
	jz	notDetachPending

reSendDetach label near

	mov	dx, ds:[detachOD].handle
	mov	bp, ds:[detachOD].chunk
	mov	cx, ds:[detachID]
	mov	ax, MSG_META_DETACH
	mov	bx, handle 0
	mov	di, mask MF_CALL
	GOTO	ObjMessage			; <-- EXIT HERE

notDetachPending:

	;
	; if we were waiting for the current field to exit before opening
	; a new field, open that new field now
	;
	test	ds:[processFlags], mask SPF_PENDING_FIELD
	jz	noPendingField
	andnf	ds:[processFlags], not mask SPF_PENDING_FIELD

	movdw	cxdx, ds:[pendingField]		; ^lcx:dx = pending field
	mov	ax, MSG_STARTUP_OPEN_FIELD
	mov	bx, handle 0
	clr	di
	GOTO	ObjMessage		; <-- EXIT HERE ALSO

noPendingField:

	ret
StartupFieldNotifyDetach endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine does misc closing/cleanup before we exit.

CALLED BY:	GLOBAL

PASS:		nothing 

RETURN:		cx = 0 (no state block)

DESTROYED:	ax,cx,dx,bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	1/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifndef WELCOME
StartupCloseApplication	method	StartupClass, MSG_GEN_PROCESS_CLOSE_APPLICATION

	;
	; remove ourselves from the GCNSLT_EXPRESS_MENU_CHANGE system
	;

	mov	cx, handle 0
	clr	dx
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_EXPRESS_MENU_CHANGE
	call	GCNListRemove

ifdef ISTARTUP
	call	IStartupStopTimer
endif

	clr	cx				; no state block
	ret
StartupCloseApplication	endm
endif ; not WELCOME


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupShutdownAck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	restore owner of field resources

CALLED BY:	MSG_META_SHUTDOWN_ACK

PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		es 	= segment of StartupClass
		ax	= MSG_META_SHUTDOWN_ACK

		^lcx:si	= ack OD
		^ldx:bp	= object that sent ack back to us

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We can leave the burden thread as that doesn't matter
		when shutting down.  The owner is relevant for unrelocating.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/19/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupShutdownAck	method	dynamic StartupClass, MSG_META_SHUTDOWN_ACK

	mov	bx, handle Room1Field
	mov	ax, handle 0
	call	HandleModifyOwner
	mov	bx, handle Room2Field
	mov	ax, handle 0
	call	HandleModifyOwner
	mov	bx, handle Room3Field
	mov	ax, handle 0
	call	HandleModifyOwner
ifdef ISTARTUP
	mov	bx, handle LoginRoomField
	mov	ax, handle 0
	call	HandleModifyOwner
ifdef MOUSETUTORIAL
	mov	bx, handle MouseRoomField
	mov	ax, handle 0
	call	HandleModifyOwner
endif
endif
	mov	ax, MSG_META_SHUTDOWN_ACK
	mov	di, offset StartupClass
	GOTO	ObjCallSuperNoLock

StartupShutdownAck	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Always use same state filename - ISTARTUP.STA.

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es 	= segment of StartupClass
		ax	= message #
		dx	= Block handle to block of structure AppLaunchBlock
		CurPath	= Set to state directory
RETURN:		ax	= VM file handle (0 if we don't want a state
			  file/couldn't create one).
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	5/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef ISTARTUP	;--------------------------------------------------------------

statefileName	char	"ISTARTUP.STA", C_NULL

StartupCreateNewStateFile	method dynamic StartupClass, 
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
	mov	bp, dx			; bp = AppLaunchBlock

	segmov	ds, cs
	mov	dx, offset cs:[statefileName]
	mov	ax, (VMO_CREATE_TRUNCATE shl 8) or mask VMAF_FORCE_DENY_WRITE \
			or mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION
	clr	cx			; Use standard compaction threshhold
	call	VMOpen
	jc	error

	xchg	bp, bx			; bp = VM file, bx = AppLaunchBlock
	mov	si, dx			; ds:si = state file name

	call	MemLock			; lock AppLaunchBlock
	mov	es, ax
	mov	di, offset AIR_stateFile
	mov	cx, size statefileName
	rep	movsb
	call	MemUnlock

	mov	ax, bp
	ret				; <==== GOOD EXIT

error:
	clr	ax			; no state file created
	ret				; <==== BAD EXIT
StartupCreateNewStateFile	endm

endif		;--------------------------------------------------------------

ExitCode	ends



;##############################################################################
;	FIXED, RESIDENT CODE
;##############################################################################

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupHotKeyMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An input monitor to detect when the hot key is pressed.

CALLED BY:	IM
PASS:		al	= MF_DATA
		di	= event type
		cx, dx, bp 	- event data
		ds	= segment of Monitor being called
		si	= nothing
		ss:sp	= IM's stack

RETURN:		al	= MF_DATA (never MF_MORE_TO_DO)
		di	= event type
		cx, dx, bp, si = event data

DESTROYED:	maybe ah, bx, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/89		Initial version
	joon	11/92		IStartup: shutdown on key sequence
	ayuen	05/23/00	GPC: restart with default video mode on hotkey

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef	GPC

screen0Cat	char	"screen 0", 0

StartupHotKeyMonitor	proc	far

	cmp	di, MSG_META_KBD_CHAR
	jne	exit

	;
	; Check if RCtrl-LShift-F12.
	;
SBCS <	cmp	cx, (CS_CONTROL shl 8) or VC_F12			>
DBCS <	cmp	cx, C_SYS_F12						>
	jne	exit		;If not, exit
	cmp	dh, mask SS_RCTRL or mask SS_LSHIFT
	jne	exit

	;
	; Only accept first-press.
	;
	test	dl, mask CF_FIRST_PRESS	; see if press or not
	jz	Done			; if not, don't send method, but
					; skill consume event

	test	ds:[processFlags], mask SPF_DETACHING
	jne	Done		;Ignore if detaching

	;
	; Hot key is pressed.  Remove [screen 0] settings in GEOS.INI, and
	; then restart the system.  Can't call SysShutdown directly from here
	; because the IM thread stack is too small, so we need to call it on
	; our own thread.
	;
	pusha
	segmov	ds, cs
	mov	si, offset screen0Cat	; ds:si = screen0Cat
	call	InitFileDeleteCategory

	mov	bx, handle 0
	mov	ax, MSG_PROCESS_CALL_ROUTINE
	push	SST_RESTART		; PCRP_dataAX
	push	seg SysShutdown, offset SysShutdown	; PCRP_address
	; ss:sp = ProcessCallRoutineParams, valid up to PCRP_dataAX
	mov	bp, sp			; ss:bp = ProcessCallRoutineParams
	mov	dx, size ProcessCallRoutineParams
	mov	di, mask MF_STACK
	call	ObjMessage
	add	sp, offset PCRP_dataAX + size PCRP_dataAX
	popa

Done:
	clr	ax		; consume the event.
exit:
	ret
StartupHotKeyMonitor	endp

elifndef ISTARTUP	;--------------------------------------------------------------

StartupHotKeyMonitor	proc	far
				; If not a kbd char, return immediately
if 0 ; no hotkey
	cmp	di, MSG_META_KBD_CHAR
	jne	exit

	mov	bx, segment idata
	mov	ds, bx
				; see if hot key
	cmp	cx, (0xff00 or VC_F2)
	jne	exit		;If not, exit

	test	dh, mask ShiftState	;If any modifier pressed, ignore it.
	jnz	exit			;
				; Test CharFlags
	test	dl, mask CF_FIRST_PRESS	; see if press or not
	jz	Done			; if not, don't send method, but
					; skill consume event

	test	ds:[processFlags], mask SPF_DETACHING
	jne	Done		;Ignore if detaching

				; if hot key pressed, try to jump user back to
				; main screen.
	mov	bx, handle 0
	mov	ax, MSG_STARTUP_TRY_TO_SWITCH_TO_STARTUP
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
Done:
	clr	ax		; consume the event.
exit:
endif
	ret

StartupHotKeyMonitor	endp

else	; ISTARTUP -----------------------------------------------------------

StartupHotKeyMonitor	proc	far
	;
	; If not a kbd char, return immediately
	;
		cmp	di, MSG_META_KBD_CHAR
		LONG	jne exit

		test	dl, mask CF_FIRST_PRESS
		LONG	jz exit				; must be first press

		mov	bx, segment idata
		mov	ds, bx

		cmp	ds:[currentField].handle, handle LoginRoomField
		LONG	je exit

		test	ds:[keySequenceMode], mask KSM_ESCAPE
		jnz	inEscapeSequenceMode

	;
	; Check if we should run switch to host connectivity app...
	;
		cmp	cx, C_BACKQUOTE
		jne	checkQuizDialog
		mov	bl, dh
		and	bl, mask SS_LALT or mask SS_RALT or \
				mask SS_LCTRL or mask SS_RCTRL
		LONG jz	exit

		mov	ax, MSG_STARTUP_SWITCH_TO_HOST
		mov	bx, handle 0
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	consumeKey
		
checkQuizDialog:
	;
	; If both shift keys are down, bring up the quiz edit dialog
	;
		mov	bl, dh
		and	bl, mask SS_LSHIFT or mask SS_RSHIFT
		cmp	bl, mask SS_LSHIFT or mask SS_RSHIFT
		je	doQuizDialog

	;
	; Also bring it up on ALT +
	;
		cmp	cx, '+'
		jne	checkCtrlScrollLock

		test	dh, mask SS_LALT or mask SS_RALT
		LONG jz	exit

doQuizDialog:
		mov	ax, MSG_STARTUP_DO_QUIZ_DIALOG
		mov	bx, handle 0
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	consumeKey

checkCtrlScrollLock:
	;
	; Test for Ctrl-ScrollLock (EDLan mode)
	;
		cmp	cx, (VC_ISCTRL shl 8) or VC_SCROLLLOCK
		jne	checkEscape
		test	dh, mask SS_LALT or mask SS_RALT
		LONG	jz exit
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	exit

		test	ds:[keySequenceMode], mask KSM_EDLAN
		jnz	consumeKey		; skip if already in EDLan mode

		ornf	ds:[keySequenceMode], mask KSM_EDLAN
	
		mov	bx, handle 0
		mov	ax, MSG_STARTUP_BEGIN_EDLAN_MODE
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	short consumeKey

checkEscape:
	;
	; Test for Ctrl-Alt-Shift-ESC
	;
		cmp	cx, (VC_ISCTRL shl 8) or VC_ESCAPE
		jne	exit
		test	dh, mask SS_LCTRL or mask SS_RCTRL
		jz	exit
		test	dh, mask SS_LALT or mask SS_RALT
		jz	exit
		test	dh, mask SS_LSHIFT or mask SS_RSHIFT
		jz	exit
						; start escape sequence mode
		ornf	ds:[keySequenceMode], mask KSM_ESCAPE
		jmp	short consumeKey

inEscapeSequenceMode:
		test	dl, mask CF_STATE_KEY or mask CF_TEMP_ACCENT
		jnz	exit				; ignore state keys

		test	dh, mask SS_LALT or mask SS_RALT ; ALT should be down
		jz	resetState

		clr	bh
		mov	bl, ds:[keySequenceState]	; bl <= state number
		mov	bh, ds:[bx + keySequence]	; bh <= sequence char
		mov	ax, bp				; ah <= scancode
		cmp	ah, bh
		jne	resetState			; reset if not
							; in sequence

		inc	bl			; increment state number
		mov	ds:[keySequenceState], bl	; upate state number
		cmp	bl, ds:[keySequenceEndState]	; have we
							; reached final state?
		jne	consumeKey			; done if not

		test	ds:[processFlags],
				mask SPF_DETACHING or mask SPF_PENDING_FIELD
		jnz	resetState			; ignore if detaching

		mov	bx, handle 0
		mov	ax, MSG_STARTUP_SHELL_TO_DOS
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage

resetState:
		andnf	ds:[keySequenceMode], not (mask KSM_ESCAPE)
		mov	ds:[keySequenceState], 0	; reset state

consumeKey:
		clr	ax				; consume the event
exit:
		ret

StartupHotKeyMonitor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupSwitchToHost
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Run the host connectivity app

CALLED BY:	MSG_STARTUP_SWITCH_TO_HOST
PASS:		*ds:si	= StartupClass object
		ds:di	= StartupClass instance data
		ds:bx	= StartupClass object (same as *ds:si)
		es	= segment of class
		ax	= message #
RETURN:		nothing
DESTROYED:	bx, si, di, ds, es allowed
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dloft	4/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HostAppInfoStruct	CoursewareInfoStruct <
	0,0,<0,0>,0,"SEH.ITM",0
>

;FakeItemFile	char	\
;	'?|Host Connectivity^ECHO RUNNING HOST CONNECTIVITY^SEH^%V%G^:SEH', \
;	C_CR, C_LF, 0

sehPath		char	'SEH.ITM', 0

StartupSwitchToHost		method dynamic StartupClass, MSG_STARTUP_SWITCH_TO_HOST
		uses	cx, dx, bp
		.enter

		call	FilePushDir

		mov	al, IDT_SPECUTIL
		clr	cx
		call	IclasChangeDir

		segmov	ds, cs, ax
		mov	dx, offset sehPath
		call	IclasFileRead
		jc	done

		push	bx
 		segmov	es, cs				; ds:dx -> item line
		mov	bp, offset HostAppInfoStruct	; es:bp -> CIS
		call	IclasExecItemLine
		pop	bx

		call	MemFree

done:		
		call	FilePopDir
		.leave
		ret
StartupSwitchToHost		endm

endif		; ifdef ISTARTUP ----------------------------------------------

Resident	ends
