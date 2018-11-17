COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	(c) Copyright GeoWorks 1995.  All Rights Reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		User/User
FILE:		userMain.asm

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE 
				Attach to state file

    MTD MSG_GEN_PROCESS_OPEN_APPLICATION 
				Startup application

    INT UserNotifyPCMCIA        Inform the PCMCIA library (if there is one)
				that it should register as a client now
				that the graphical setup has been completed

    INT UI_LogWriteEntry        Called by the UI to write an entry out to
				the log file.

    INT UserLoadTaskDriver      Load the task-switch driver specified in
				the ini file.

    INT InitOverstrikeMode      Sets up overstrike mode flag.

    INT InitActivationDialogMode 
				Sets up activation dialog flag.

    INT InitKbdAcceleratorMode  Sets up kbd accelerator mode flag.

    INT LoadMouseDriver         Retrieve and load the mouse driver
				specified.

    INT ShowDefaultPtr          Perform a SHOW_PTR for the default video
				driver to bring pointer on screen.

    INT GetIniString            Fetch a string from the .ini file.

    INT StartupAppls_callback   Callback function to start up an
				application listed in the execOnStartup
				key.

    INT StartupApplsBG_callback Callback function to start up an
				application listed in the
				execOnStartupBackground key.

    GLB LoadApplicationWithErrorMessage 
				Loads an application and puts up a
				SysNotify box if any error.

    INT LoadScreenBlanker

    GLB UserLoadSpooler         Loads up the spooler as an application so
				we can specify which field it will come up
				on. Returns carry set if error.

    GLB UserLoadHWR             Loads up the handwriting-recognition
				driver.

    MTD MSG_USER_UPDATE_SOUND_PARAMS 
				This routine updates the sound parameters
				(like if the sound driver is loaded or not)

    MTD MSG_USER_FREE_SOUND_HANDLE 
				Free a sound handle

    INT SetDefaultInputMap      Set the default button map

    INT CheckNumMouseButtons

    INT CheckKey

    EXT UserAllocObjBlock       Allocate a block on the heap, to be used
				for holding UI objects.

    MTD MSG_PROCESS_NOTIFY_PROCESS_EXIT 
				Notificatin of process exit

    MTD MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE 
				Create state file for UI

    INT UIBusyTimerRoutine      Handle time-out of busy timer -- check to
				see if UI thread is busy or not, & set ptr
				accordingly

    INT LaunchHomescreen        Launches/brings-to-top homescreen

    MTD MSG_USER_PROMPT_FOR_PASSWORD 
				Prompt for the password

    INT NotifyPowerDriverPasswordOK 
				Tell the power driver that the entered
				password is OK, or, perhaps, that none was
				needed.

    MTD MSG_USER_IS_PASSWORD_DIALOG_ACTIVE 
				Tell whether the password dialog is
				on-screen

    INT VerifyBIOSPassword      Verify a password vs. the BIOS password

    MTD MSG_USER_PASSWORD_ENTERED 
				Deal with the password being entered

    INT UserEncryptPassword     Encrypt a password (or other string)

    EXT CalculateHash           Calculate the 32-bit ID for a string

    INT InstallRemovePasswordMonitor 
				Install or remove the APM password monitor.

    INT	UserInstallRemoveKeyClickMonitor
				Install or remove the key click monitor (for
				responder) .

    INT UserKeyClickRoutine	Routine for the key click  monitor.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Doug	6/2/92		Reworked to allow UI to be an application

DESCRIPTION:

	This file contains handler methods for the UI process itself

	$Id: userMain.asm,v 1.3 98/03/18 02:07:08 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UserClassStructures	segment resource

	UserClass	mask CLASSF_NEVER_SAVED

UserClassStructures	ends

idata	segment

LocalDefNLString stateFile <"UI State", 0>


idata	ends

include Internal/prodFeatures.def

Init segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserAttach -- MSG_META_ATTACH for UserClass

DESCRIPTION:	Initialize the process

PASS:
	ds - core block of geode
	es - segment where process class defined (same as ds for applications)

	di - MSG_META_ATTACH

	cx - ?
	dx - ?
	bp - ?
	si - ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	keys (case and white space are ignored):
	    under the [ui] category:
		specific
		execOnStartup 		= programNameStr [programNameStr]
		execOnStartupBackground	= programNameStr [programNameStr]
		otherVideoDrivers	= driverName [driverName]

	    under the [input] category:
		numberOfMouseButtons	= {1,2,3}
		clickToType		= {true, false}
		selectRaises		= {true, false}
		selectDisplaysMenu	= {true, false}
		featuresExecutesDefault	= {true, false}
		clickGoesThrough	= {true, false}
	
	if the values for the "execOnStartup" and "otherVideoDrivers"
		keys span more than 1 line, they would need to be converted
		to 'blobs'. Just enclose the parameters within curly
		braces, ie. '{' and '}'

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version
	Cheng	12/89		Modified to use the new init file routines

------------------------------------------------------------------------------@


UserAttach	method	UserClass, MSG_META_ATTACH

	; Set flag to indicate initializing
	;
	ornf	ds:[uiFlags], mask UIF_INIT

	; Set the priority of the UI between "focus" and "high"

	clr	bx				;change this thread
	mov	al, PRIORITY_HIGH + (PRIORITY_FOCUS - PRIORITY_HIGH)/2
	mov	ah, mask TMF_BASE_PRIO		;modify priority
	call	ThreadModify
	mov	ds:[uiThread], bx		;store UI thread here,
						; so that ui utility routines
						; can compare w/current 
						; running thread.

	mov	bx, handle 0
	mov	cx, 1				;Allocate 1 word
	call	GeodePrivAlloc
	tst	bx
	jnz	haveUndo
	mov	bx, handle cannotAllocUndoError
	call	MemLock
	mov	ds, ax
	mov	si, ds:[cannotAllocUndoError]
	mov	ax, SST_DIRTY
	jmp	SysShutdown
haveUndo:
	mov	ds:[undoOffset], bx
	;----------------------------------------------------------------------
	;Get the strategy entry point for the keyboard driver

	mov	ax, offset cs:logKbdStr
	call	UI_LogWriteEntry

	;---------------------------------------------------------------------
	
	call	InitOverstrikeMode		;initialize overstrike mode

	call	InitActivationDialogMode	;initialize activation dialog

	;---------------------------------------------------------------------
	
	call	InitKbdAcceleratorMode		;initialize kbd accelerator mode

	;----------------------------------------------------------------------
	;SET UP SOUND DRIVER

	mov	ax, offset cs:logSoundStr
	call	UI_LogWriteEntry

	clr	di
	mov	ax, MSG_USER_UPDATE_SOUND_PARAMS
	mov	bx, handle 0
	call	ObjMessage

if PLAY_STARTUP_SHUTDOWN_MUSIC
	;---------------------------------------------------------------------
	;PLAY STARTUP MUSIC
	sub	sp, size GeodeToken
	segmov	es, ss
	mov	di, sp
	mov	ax, GGIT_TOKEN_ID
	mov	bx, handle 0
	call	GeodeGetInfo
	mov	cx, es
	mov	dx, di
	mov	bx, UIS_STARTUP
	call	WavPlayInitSound
	add	sp, size GeodeToken
endif	; PLAY_STARTUP_SHUTDOWN_MUSIC

	;CREATE A BLOCK TO PUT UI OBJECTS IN

	clr	bx
	call	UserAllocObjBlock		;create a new object block,
						;to be run by UI

;	mov	ds:[uiSystemObj].handle, bx	;store block handle
;	Now stored below - the problem is that if the SPUI takes a long time
;	to load, another already-loaded geode could call UserCallSystem,
;	which causes death if the handle is set but the chunk isn't.

	mov	ds:[uiFlowObj].handle, bx	;store block handle

	;----------------------------------------------------------------------
	;CREATE A FLOW OBJECT FOR HANDLING USER INPUT

	mov	ax, offset cs:logFlowObjStr
	call	UI_LogWriteEntry

	mov	di, segment FlowClass
	mov	es, di
	mov	di, offset FlowClass
	call	ObjInstantiate			;create a flow object
	mov	ds:[uiFlowObj].chunk, si	;store handle to object
	call	ImGrabInput			;grab input from the IM for
						; this Flow object
	call	WinGrabChange			;grab window change events

	;-----------------------------------------------------------------------
if	(AUTO_BUSY)
	;STARTUP BUSY WATCH TIMER

	mov	ax, offset cs:logWatchTimerStr
	call	UI_LogWriteEntry

	mov	ax, ss
	mov	ds:[uiStack], ax		; Store segment of stack, we'll
						; need later
	call	TimerGetCount
	mov	dx, ax				; copy current time to cx:dx
	mov	cx, bx
	call	UIBusyTimerRoutine		; Call as if from first time-out
						; -- will self perpetuate
endif

	;----------------------------------------------------------------------
	;PUTUP TITLE SCREEN
;
;
;	call	SysConfig			;See if restarting or not
;	test	al, mask SCF_RESTARTED
;	jnz	afterTitleScreen		;if restarting, skip title
; NO TITLE SCREEN!
;	call	UserPutupTitleScreen
;afterTitleScreen:

	;-----------------------------------------------------------------------
	;CHECK WHETHER SOFTWARE HAS EXPIRED

ifdef	SOFTWARE_EXPIRES	; in case SOFTWARE_EXPIRES isn't defined
if	SOFTWARE_EXPIRES

	call CheckSoftwareExpiration

endif
endif

	;-----------------------------------------------------------------------
	;LOAD IN INTITIAL SPECIFIC UI LIBRARY

	mov	ax, offset cs:logSpecUIStr
	call	UI_LogWriteEntry

	mov	ax, SP_SYSTEM
	call	FileSetStandardPath

;	Set the flag denoting whether or not we should unbuild the children
;	of controllers or not. If set to true, then dual-build controllers
;	will unbuild and destroy their children when they are closed. This
;	hurts performance, as the children will have to be re-created and
;	built when the box is brought back up, but it reduces the amount of
;	heap space used on machines with limited heap/swap space.

	push	ds				;save dgroup block
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[unbuildControllersString]
	call	InitFileReadBoolean
	pop	ds
	jc	10$
	mov	ds:[unbuildControllers], al
	
10$:
	push	ds				;save dgroup block
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]	;ds:si <- category
	mov	dx, offset cs:[specificStr]	;cx:dx <- key
	clr	bp				;tell routine to create buffer
	push	cx
	call	InitFileReadString		;bx <- mem handle to string
	pop	cx
	jc	useDefaultSpecific		

	mov	bp, bx				;save mem handle
	call	MemLock
	mov	ds, ax
	clr	si

	mov	ax, SPUI_PROTO_MAJOR		;protocol to look for
	mov	bx, SPUI_PROTO_MINOR
	call	GeodeUseLibrary
	pushf					;Save carry (error) flag
	xchg	bx, bp
	call	MemFree				;Free up block with UI name
	mov	bx, bp
	popf					;Restore error flag
	jnc	gotUI

useDefaultSpecific:
	mov	ds,cx				;if not found then use OL
	mov	si,offset cs:[defaultUI]

	mov	ax, SPUI_PROTO_MAJOR		;protocol to look for
	mov	bx, SPUI_PROTO_MINOR
	call	GeodeUseLibrary
	jnc	gotUI
EC <	ERROR	UI_CANNOT_LOAD_SPECIFIC_UI				>
NEC <	mov	bx, handle cannotLoadSPUIError				>
NEC <	call	MemLock							>
NEC <	mov	ds, ax							>
assume	ds:Strings    
NEC <	mov	si, ds:[cannotLoadSPUIError]				>
assume	ds:dgroup
NEC <	mov	ax, SST_DIRTY						>
NEC <	jmp	SysShutdown						>
gotUI:
	pop	ds				;retrieve dgroup
	mov	ds:[uiSpecUILibrary], bx	; Store away handle of specific
						; UI library we're using, so 
						; that we can free it later.

						;bx = specific UI to
						; make system object
	push	bx
	mov	bx, ds:[uiFlowObj].handle

	;-----------------------------------------------------------------------
	;CREATE THE UI SYSTEM OBJECT
						;bx = ui obj block
	mov	di, segment GenSystemClass
	mov	es, di
	mov	di, offset GenSystemClass
	call	ObjInstantiate			;create a system object

;	Store handle of system object last, so if someone tries to call
;	UserCallSystem in between the next two instructions, the call will
;	go nowhere (handle = 0) instead of crashing (handle != 0, chunk = 0)

	mov	ds:[uiSystemObj].chunk, si
	mov	ds:[uiSystemObj].handle, bx
	pop	dx				;get specific UI
	mov	ax, MSG_GEN_SYSTEM_SET_SPECIFIC_UI	;set specific UI
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	;-----------------------------------------------------------------------
	; initialize token database

	mov	ax, offset cs:logTokenDBStr
	call	UI_LogWriteEntry

	call	TokenInitTokenDB
	jnc	tokenDBInitialized

if  ERROR_CHECK
	cmp	dx, BAD_PROTOCOL_IN_SHARED_TOKEN_DATABASE_FILE
	ERROR_E	SHARED_TOKEN_DATABASE_FILE_HAS_BAD_PROTOCOL_NUMBER
	cmp	dx, ERROR_OPENING_SHARED_TOKEN_DATABASE_FILE
	ERROR_E	COULD_NOT_OPEN_SHARED_TOKEN_DATABASE_FILE
	ERROR	COULD_NOT_OPEN_LOCAL_TOKEN_DATABASE_FILE
endif

ife  ERROR_CHECK
	mov	bx, handle sharedTokenDBOpenError
	call	MemLock
	mov	ds, ax
assume	ds:Strings
	cmp	dx, BAD_PROTOCOL_IN_SHARED_TOKEN_DATABASE_FILE
	jne	sharedFileError
	mov	si, ds:[tokenDBProtocolError]	;DS:SI <- First string.
	jmp	doNotify
sharedFileError:
	cmp	dx, ERROR_OPENING_SHARED_TOKEN_DATABASE_FILE
	jne	localFileError
	mov	si, ds:[sharedTokenDBOpenError]	;DS:SI <- First string.
	jmp	doNotify
localFileError:
	cmp	dx, ERROR_OPENING_LOCAL_TOKEN_DATABASE_FILE
	mov	si, ds:[localTokenDBOpenError]	;DS:SI <- First string.
doNotify:
	clr	di				;no second string
	mov	ax, mask SNF_EXIT
	call	SysNotify
				;Since no screens have been registered yet, 
				; SysNotify will just exit, and will not
				; return.
assume	ds:dgroup
	.unreached
endif

tokenDBInitialized:	

;	;-----------------------------------------------------------------------
;	;REMOVE TITLE SCREEN
;
;	call	UserRemoveTitleScreen

;	push	bx, si			; save for later

	;-----------------------------------------------------------------------
	;CREATE A SCREEN OBJECT
	
;	pop	bx, si

	;bx = object block, si = system object

	mov	ax, offset cs:logScreensStr
	call	UI_LogWriteEntry

	call	UserMakeScreens			;create all necessary screens


;Mouse driver is loaded after running graphical setup (if any) in
;UserContinueStartup.  We call SetDefaultInputMap again there also.
;The SetDefaultInputMap initialize some things to default values as
;the mouse info is not available yet.  This should be okay as none of
;those values are critical until after we load mouse driver. - brianc 11/2/92
;	;----------------------------------------------------------------------
;	;LOAD MOUSE DRIVER -- Do this *before* setting the default button map
;
;	mov	ax, offset cs:logMouseDrvStr
;	call	UI_LogWriteEntry
;
;	call	LoadMouseDriver
;
;	call	InitMousePosition

	;----------------------------------------------------------------------
	;SET DEFAULT BUTTON MAP

	mov	ax, offset cs:logInputMapStr
	call	UI_LogWriteEntry

	call	SetDefaultInputMap

	;-----------------------------------------------------------------------
	;INITIALIZE SCREEN BLANKER

	mov	ax, offset cs:logScreenBlankerStr
	call	UI_LogWriteEntry

	call	LoadScreenBlanker

	;----------------------------------------------------------------------
	; Finish attaching the UI application itself

	mov	ax, MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN
	call	UserCallSystem
	mov	di, cx			; Add UI app below screen object
	mov	bp, dx
	push	ds
	mov	cx, cs
	mov	ds, cx
	clr	ax		; default AppLaunchFlags, GenUILevel
	clr	dx		; create AppLaunchBlock, as we don't have one
	mov	si, offset cs:[uiStr]
					; force restoring from state, we'll
					;	set state file name below
	mov	cx, MSG_GEN_PROCESS_RESTORE_FROM_STATE
	mov	bx, SP_SYSTEM
	call	PrepAppLaunchBlock	; got one, in dx
	;
	; stuff our state file name
	;
	mov	bx, dx			; bx = AppLaunchBlock
	call	MemLock
	mov	es, ax			; es:di = AppLaunchBlock statefile field
	mov	di, offset ALB_appRef.AIR_stateFile
	mov	si, segment stateFile	; ds:si = our state file
	mov	ds, si
	mov	si, offset stateFile
	mov	cx, length stateFile
	LocalCopyNString		; copy over
	call	MemUnlock
	pop	ds			; Need ds = core block for ObjCallSuper

	mov	di, segment UserClass	; Call our superclass, which is the
	mov	es, di			; GenProcessClass, to startup the "app"
	mov	di, offset UserClass	; side of this library.
	mov	ax, MSG_META_ATTACH
	call	ObjCallSuperNoLock

	;
	; don't do any more here as we may be waiting for the user to finish
	; with graphical setup or to respond to the "delete state files?"
	; dialog.  Stuff should be done in the UserContinueStartup handler or
	; the UserDeleteStateFilesDialogResponse handler.
	;

	; Clear flag to indicate done initializing
	;
	andnf	ds:[uiFlags], not mask UIF_INIT

		
		ret
	
UserAttach	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserAttachToPassedStateFile --
		MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE for UserClass

DESCRIPTION:	Attach to state file

PASS:
	ds - core block of geode
	es - segment where process class defined (same as ds for applications)

	ax - MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE

	cx - AppAttachMode
	dx - handle of AppLaunchBlock

RETURN:
	carry - ?
	ax - extra state block (0 for none)
	cx, dx, bp - ?

DESTROYED:
	bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/15/92	modified from welcome

------------------------------------------------------------------------------@


UserAttachToPassedStateFile	method	dynamic	UserClass,
				MSG_GEN_PROCESS_ATTACH_TO_PASSED_STATE_FILE

	call	FilePushDir	; save current dir
	mov	ax, SP_STATE	;Go to the hot&juicy state directory
	call	FileSetStandardPath
EC <	cmp	cx, MSG_GEN_PROCESS_RESTORE_FROM_STATE			>
EC <	ERROR_NZ -1		;This should only be called if we are	>
				; restoring from state

	push	cx		; Save AppAttachBlock, mode for later
	push	dx		;
	push	ds		;

	; Try & open any passed state file

	mov	bx, dx		; Get handle of AppLaunchBlock
	call	MemLock		;

	mov	ds, ax		;
				; Setup ds:dx as filename to open
	mov	dx, offset ALB_appRef.AIR_stateFile

				; Open existing VM file
	mov	ax, (VMO_OPEN shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx		; use standard compaction threshhold
	call	VMOpen		; Go ahead, open it!

;	Pretend we couldn't restore from state file, so continue startup, in
;	OPEN_APPLICATION mode...

	mov	ds:[ALB_appMode], MSG_GEN_PROCESS_OPEN_APPLICATION

;	DON'T CHANGE THIS TO a "clr", BECAUSE THAT TRASHES THE CARRY

	mov	ds:[ALB_appRef.AIR_stateFile],0	;Nuke statefile name

	call	FilePopDir
	pop	ds
	mov	dx, bx		;Save VM handle
	pop	bx
	pop	cx
	call	MemUnlock	;Unlock the AppLaunchBlock
	xchg	bx, dx		;BX <- VM handle, DX <- AppLaunchBlock
	jc	exit		; Branch if error

				; bx = VM file handle

	; Prepare to associate the state file with the current process
	; by storing the VM handle until UserOpenApplication (after deleting
	; state files, if necessary, way down in
	; UserDeleteStateFilesDialogResponse)
	segmov	es, dgroup, cx			; SH
	mov	es:[stateFileHandle], bx
exit:
	clr	ax			;No extra state block
	ret
UserAttachToPassedStateFile	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserOpenApplication -- MSG_GEN_PROCESS_OPEN_APPLICATION for
		UserClass

DESCRIPTION:	Startup application

PASS:
	ds - core block of geode
	es - segment where process class defined (same as ds for applications)

	ax - MSG_GEN_PROCESS_OPEN_APPLICATION

	cx - AppAttachFlags
	dx - handle of AppLaunchBlock
	bp - handle of state block

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
	brianc	10/15/92	Initial version

------------------------------------------------------------------------------@


UserOpenApplication	method	dynamic	UserClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION

	mov	di, offset UserClass
	call	ObjCallSuperNoLock

	;----------------------------------------------------------------------
	;CREATE FIELD FOR "DELETE STATE?" BOX, FOR GRAPHICAL SETUP, AND
	;FOR SPOOLER

	mov	ax, MSG_GEN_SYSTEM_GET_DEFAULT_SCREEN
	call	UserCallSystem			; ^lcx:dx = default screen

	push	cx
	push	dx			; save screen object

	mov	bx, ds:[uiSystemObj].handle
	mov	di, segment GenFieldClass
	mov	es, di
	mov	di, offset GenFieldClass
	call	ObjInstantiate

	;
	; Add field as generic child of system object
	;
	mov	ax, MSG_META_ATTACH
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	;
	; don't care about field notifications, so set notification destination
	; to UI thread and ignore notifications (0 notification means something
	; else)
	;
	call	ObjSwapLock		; *ds:si = GenField
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset	; ds:di = gen instance
.warn -private
	mov	ds:[di].GFI_notificationDestination.handle, handle 0
	mov	ds:[di].GFI_notificationDestination.chunk, 0
.warn @private
	call	ObjSwapUnlock

					; SET vis parent for GenField
	pop	dx
	pop	cx

	mov	ax, MSG_GEN_FIELD_SET_VIS_PARENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	mov	dl, VUM_NOW		; Set as usable, so it comes
	mov	ax, MSG_GEN_SET_USABLE	;	up
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

					; Bring to top, let have focus, etc.
	mov	ax, MSG_GEN_BRING_TO_TOP
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

					; Make it default field for now
	mov	cx, bx
	mov	dx, si
	mov	ax, MSG_GEN_SYSTEM_SET_DEFAULT_FIELD
	call	UserCallSystem

	;----------------------------------------------------------------------

	;TURN ON INK MODE IF NECESSARY
	call	SysGetPenMode
	tst	ax
	jz	noPen

	mov	ax, offset cs:logPenModeStr
	call	UI_LogWriteEntry
	call	ImStartPenMode
	mov	si, offset cannotEnterPenModeError
	mov	di, offset cannotEnterPenModeErrorTwo
	jc	gotoPrintErrorAndExit

if	_UI_NO_HWR
	clr	bx				; no HWR handle
else	; _UI_NO_HWR
	mov	ax, offset cs:logLoadHWRStr
	call	UI_LogWriteEntry
	call	UserLoadHWR			; bx <- HWR handle
	mov	si, offset cannotLoadHWRLibraryError
	mov	di, offset cannotLoadHWRLibraryErrorTwo
endif	; _UI_NO_HWR

gotoPrintErrorAndExit:
	LONG jc	printErrorAndExit
	mov	ds:[hwrHandle], bx

noPen:

	;----------------------------------------------------------------------
	;LOAD THE SPOOLER SO NEITHER pref NOR welcome HAS TO DEAL WITH IT
	;unless otherwise specified in the init file. 

	call	UserLoadSpooler
	mov	ds:[spoolerHandle], bx

	mov	si, offset loadSpoolerErrorOne	;DS:SI <- First string.
	mov	di, offset loadSpoolerErrorTwo	;
	LONG jc	printErrorAndExit		;report error

	;----------------------------------------------------------------------
	;LOAD THE MAILBOX LIBRARY
	
	call	UserLoadMailbox
	mov	ds:[mailboxHandle], bx
	tst	bx
	jnz	doHelp
	
	; if couldn't load mailbox, then drop mailbox & medium notifications on
	; the floor
	
	mov	si, SST_MAILBOX
	call	SysIgnoreNotification

	mov	si, SST_MEDIUM
	call	SysIgnoreNotification
doHelp:
	
	;----------------------------------------------------------------------
	;ADD SYSTEM HELP OBJECTS TO GCN LIST

	mov	cx, handle SysHelpObject
	mov	dx, offset SysHelpObject	;^lcx:dx <- OD to add
	mov	bx, MANUFACTURER_ID_GEOWORKS	;bx <- manufacturer
	mov	ax, GAGCNLT_NOTIFY_HELP_CONTEXT_CHANGE
	call	GCNListAdd
CheckHack <(handle SysHelpObject) eq (handle SysModalHelpObject)>
	mov	dx, offset SysModalHelpObject	;^lcx:dx <- OD to add
	call	GCNListAdd


	;----------------------------------------------------------------------
	;RUN GRAPHICAL SETUP, IF NECESSARY

	push	ds
	mov	cx, cs
	mov	ds, cx

	;if setting up then start graphical setup program

	mov	ax, offset cs:logGrSetupStr
	call	UI_LogWriteEntry


	mov	si, offset cs:[systemCategoryStr]
	mov	dx, offset cs:[continueSetupStr]
	call	InitFileReadBoolean		;ax <- -1 / 0
	jc	doStartup

	tst	ax
	je	doStartup			;branch if false

	clr	bx				;Force shutdown if error.
	clr	bp				;No ExtraData to pass
	mov	si, offset cs:[graphicalSetupStr]
	mov	ah, mask ALF_NO_ACTIVATION_DIALOG
					;don't display "Loading ..." dialog,
					;   as the user hasn't asked for an
					;   application to be loaded
	call	LoadApplicationWithErrorMessage

	; we've started graphical setup, let it run.  When it finishes, it
	; sends us MSG_USER_CONTINUE_STARTUP.

	pop	ds
	jmp	startupDone

doStartup:
	pop	ds
	call	UserContinueStartup

startupDone:

	;
	; don't do any more here as we may be waiting for Graphical Setup
	; to finish.  Stuff should be done in the UserContinueStartup handler.
	;

	ret					; <-- EXIT HERE


printErrorAndExit:
	
	mov	bx, handle loadSpoolerErrorOne
	call	MemLock
	mov	ds, ax
	mov	di, ds:[di]
	mov	si, ds:[si]
	mov	ax, mask SNF_EXIT
	call	SysNotify

	mov	bx, handle loadSpoolerErrorOne
	call	MemUnlock

	mov	ax, SST_CLEAN_FORCED
	GOTO	SysShutdown





UserOpenApplication	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserContinueStartup --
		MSG_USER_CONTINUE_STARTUP for UserClass

DESCRIPTION:	Continue startup after running Graphical Startup

PASS:
	ds - core block of geode
	es - segment where process class defined (same as ds for applications)

	ax - MSG_USER_CONTINUE_STARTUP

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
	brianc	10/26/92	Initial version
	lester	11/25/96	added call to ImSetMouseBuffer

------------------------------------------------------------------------------@
UserContinueStartup	method	UserClass, MSG_USER_CONTINUE_STARTUP

	;----------------------------------------------------------------------
	;LOAD MOUSE DRIVER -- Do this *before* setting the default button map

	mov	ax, offset cs:logMouseDrvStr
	call	UI_LogWriteEntry

	call	LoadMouseDriver

if INK_DIGITIZER_COORDS
	;----------------------------------------------------------------------
	; SET THE BUFFER FOR STORING DIGITIZER COORDINATES IF APPROPRIATE
	; -- this has to be done after the mouse driver is loaded
	call	SysGetPenMode
	tst	ax
	jz	noPen
	call	ImSetMouseBuffer
noPen:
endif ; INK_DIGITIZER_COORDS

	; now that we've run graphical setup, let's recheck the state
	; of things (okay to do even if we haven't run graphical setup)

	call	SetDefaultInputMap

if PCMCIA_SUPPORT
	; Then, we inform the PCMCIA library (if there is one) that now
	; would be a good time to register as a Card Services client
	;					-- todd 11/17/93
	call	UserNotifyPCMCIA
endif

	;----------------------------------------------------------------------
	;CHECK FOR CRASH LAST TIME

	;
	; is there a temporary reason to delete the 

	segmov	ds, cs
	mov	si, offset uiCategoryStr
	mov	cx, cs
	mov	dx, offset alwaysDeleteStateFiles
	mov	ax, FALSE
	call	InitFileReadBoolean
	cmp	ax, FALSE
	jne	forceDelete

	mov	dx, offset tempDeleteStateFilesStr
	call	InitFileReadBoolean
	jc	noTemporaryDeleteDirective
	cmp	ax, FALSE
	je	noTemporaryDeleteDirective

	mov	dx, offset tempDeleteStateFilesStr
	call	InitFileDeleteEntry
	jmp	forceDelete

noTemporaryDeleteDirective:

	call	SysGetConfig
	test	al, mask SCF_CRASHED	;If we crashed, delete our statefile
	jz	notCrashed

	;
	; should we automatically delete state files after a crash?
	;

	mov	dx, offset deleteStateFilesStr
	call	InitFileReadBoolean
	jc	dontForceDelete
	cmp	ax, FALSE
	je	dontForceDelete

forceDelete:
	mov	cx, IC_NO		;Delete state files
	call	GeodeGetDGroupDS
	GOTO	UserDeleteStateFilesDialogResponse

dontForceDelete:
	;
	; put up "delete state files?" and wait for response
	;

	mov	dx, offset noResetBoxString
	call	InitFileReadBoolean
	jc	askUser
	cmp	ax, FALSE
	jz	askUser

;	We don't want to kill the state files, as this flag is used mainly
;	when debugging, so the system doesn't display the box each time the
;	system has died. The bug we are looking into may depend on the
;	current state files, so don't delete them.
;
;	Basically, this is a no-bozo flag. If you can't deal with the state
;	files hanging around, don't use this.


notCrashed:
	mov	cx, IC_YES		;Leave state files alone!
	call	GeodeGetDGroupDS
	GOTO	UserDeleteStateFilesDialogResponse
	
askUser:
	call	GeodeGetDGroupDS


;	PUT UP THE BOX ASKING THE USER IF HE WANTS TO NUKE THE STATEFILES

	mov	bx, handle UIApp
	mov	si, offset UIApp
	mov	cx, handle DeleteStateConfirmBox
	mov	dx, offset DeleteStateConfirmBox
	mov	ax, MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

if 1
	mov	bx, handle DeleteStateConfirmBox
	mov	si, offset DeleteStateConfirmBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage
else
;can't user UserDoDialog yet
	mov	bx, handle DeleteStateConfirmBox
	mov	si, offset DeleteStateConfirmBox
	call	UserDoDialog			; ax = response
	mov	cx, ax				; cx = response
	call	UserDeleteStateFilesDialogResponse
endif

	;
	; don't do any more here as we may be waiting for the user to respond
	; to the "delete state files?" dialog.  Stuff should be done in the
	; UserDeleteStateFilesDialogResponse handler.
	;

	ret
UserContinueStartup	endm

if PCMCIA_SUPPORT

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserNotifyPCMCIA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inform the PCMCIA library (if there is one) that it
		should register as a client now that the graphical
		setup has been completed

CALLED BY:	UserContineStartup

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:
		Calls PCMCIA library

PSEUDO CODE/STRATEGY:
		Try to find loaded pcmcia library.
		If not loaded,
			don't do anything
		If loaded,
			Get Library entry point for PCMCIASetupComplete
			Generate virtual fptr to routine
			ProcCall the Library routine
		done

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	11/17/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NEC<pcmciaName	char	"pcmcia  lib ",0	>
EC<pcmciaName	char	"pcmcia  Elib",0	>

UserNotifyPCMCIA	proc	near
	uses	ax, bx, cx, dx, di, es
	.enter

	segmov	es, cs, ax
	mov	di, offset pcmciaName
	mov	ax, size pcmciaName - 1
FXIP<	segxchg	ds, es							>
FXIP<	xchg	si, di			;ds:si = pcmciaName		>
FXIP<	clr	cx			;null terminated string		>
FXIP<	call	SysCopyToStackDSSI	;ds:si = pcmciaName on stack	>
FXIP<	segxchg	ds, es							>
FXIP<	xchg	si, di			;es:di = pcmciaName on stack	>
	mov	cx, mask GA_LIBRARY
	clr	dx
	call	GeodeFind		; bx <- Handle of pcmcia
FXIP<	call	SysRemoveFromStack	;restore the stack		>
	jnc	done		; => no library by that name

	mov	ax, enum PCMCIASetupComplete

	call	ProcGetLibraryEntry		; bx:ax <- virtual fptr

	call	ProcCallFixedOrMovable
done:
	.leave
	ret
UserNotifyPCMCIA	endp

endif ;PCMCIA


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserDeleteStateFilesDialogResponse --
		MSG_USER_DELETE_STATE_FILES_DIALOG_RESPONSE for UserClass

DESCRIPTION:	Startup application

PASS:
	ds - core block of geode
	es - segment where process class defined (same as ds for applications)

	ax - MSG_USER_DELETE_STATE_FILES_DIALOG_RESPONSE

	cx - InteractionCommand
		IC_YES, IC_NO, IC_NULL

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
	brianc	10/15/92	Initial version

------------------------------------------------------------------------------@


UserDeleteStateFilesDialogResponse	method	UserClass,
				MSG_USER_DELETE_STATE_FILES_DIALOG_RESPONSE

	push	cx			;save choice (IC_NO = delete clipboard)
	cmp	cx, IC_NO		;If the user chose "NO", delete all
	LONG jne	continue	; the state files.  Else, continue.

;	CLOSE THE UI STATE FILE SO WE CAN DELETE IT

	clr	bx
	xchg	bx, ds:[stateFileHandle]
	tst	bx
	jz	noStateFile
	mov	al, FILE_NO_ERRORS
	call	VMClose
	clr	bx
	call	GeodeGetAppObject

;	TELL THE APPLICATION OBJECT THERE AIN'T NO STATE FILE

	mov	ax, MSG_GEN_APPLICATION_SET_NOT_ATTACHED_TO_STATE_FILE
	clr	di
	call	ObjMessage
noStateFile:

;	DELETE ALL THE FILES IN THE STATE DIRECTORY (WHEE!)

	call	FilePushDir
	mov	ax, SP_STATE			;Go to the state directory
	call	FileSetStandardPath
		
	sub	sp, size FileEnumParams
	mov	bp, sp

	;
	; Copy data to the stack
	;
FXIP<	segmov	es, cs, di						>
FXIP<	mov	di, offset stateString	;es:di = state str		>
FXIP<	clr	cx			;cx = null-terminated str	>
FXIP<	call	SysCopyToStackESDI	;es:di = state str on stack	>

	clr	ax
	mov	ss:[bp].FEP_searchFlags, mask FESF_CALLBACK or \
			FILE_ENUM_ALL_FILE_TYPES
	mov	ss:[bp].FEP_returnAttrs.segment, ax
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_NAME
	mov	ss:[bp].FEP_returnSize, size FileLongName
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	mov	ss:[bp].FEP_skipCount, ax
	mov	ss:[bp].FEP_matchAttrs.segment, ax
	mov	ss:[bp].FEP_callback.segment, ax
	mov	ss:[bp].FEP_callback.offset, FESC_WILDCARD
FXIP<	mov	ss:[bp].FEP_cbData1.offset, di				>
FXIP<	mov	ss:[bp].FEP_cbData1.segment, es				>
NOFXIP<	mov	ss:[bp].FEP_cbData1.offset, offset stateString		>
NOFXIP<	mov	ss:[bp].FEP_cbData1.segment, cs				>
	mov	ss:[bp].FEP_cbData2.low, TRUE
	call	FileEnum
FXIP<	call	SysRemoveFromStack					>

	jc	popExit				;If error (none found), exit
	jcxz	popExit				;If no files, branch

	push	ds

	call	MemLock
	mov	ds, ax				;DS <- buffer w/filenames
	clr	dx				;DS:DX <- first file to delete

deleteLoop:
	call	FileDelete
	add	dx, size FileLongName		;Go to the next file
	loop	deleteLoop
	call	MemFree				;Free up the filename buffer
	pop	ds

popExit:
	call	FilePopDir

continue:
	;
	; Check .INI file to determine whether to initialize clipboard.
	;
	push	ds
	mov	cx, cs
	mov	dx, offset cs:[noClipboardKeyString]
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	call	InitFileReadBoolean
	pop	ds
	pop	cx				;retrieve delete state flag
	jc	openClipboard			;if no key, open clipboard
	tst	ax				;if noClipboard = false,
						; open clipboard
	jz	openClipboard
	;
	; noClipboard = true, so zero stored clipboard file handle and
	; skip opening file.
	;
	clr	ds:[uiTransferVMFile]
	jmp	fileOpened

openClipboard:
	;
	; Initialize clipboard using the passed delete state flag
	;	cx = IC_NO to delete clipboard
	;
	mov	ax, offset cs:logClipboardStr
	call	UI_LogWriteEntry

	call	ClipboardOpenClipboardFile
EC <	ERROR_C	UI_CANNOT_CREATE_TRANSFER_FILE				>
ife ERROR_CHECK
	jnc	fileOpened
	mov	bx, handle transferFileError
	push	ds
	call	MemLock
	mov	ds, ax
assume	ds:Strings
	mov	si, ds:[transferFileError]	;DS:SI <- First string.
	clr	di				;no second string
	mov	ax, mask SNF_EXIT
	call	SysNotify
	pop	ds
	mov	ax, SST_CLEAN_FORCED
	GOTO	SysShutdown			;just bail
assume	ds:dgroup

endif

fileOpened:

;	NOW THAT WE HAVE DELETED ANY NASTY STATE FILES, ATTACH TO OUR
;	STATE FILE

	mov	bx, ds:[stateFileHandle]
	tst	bx		;Branch if no state file
	jz	noblock
	call	ObjAssocVMFile	;Returns AX <- block of extra info
	jnc	noError
	;
	; Protocols must have been off, or something, so close down the
	; file and biff it. XXX: Nuke all the other files, too? They'll
	; probably get nailed by the same thing that nailed ours anyway...
	;
	mov	al, FILE_NO_ERRORS
	call	VMClose
	mov	ds:[stateFileHandle], 0	; since we don't have one...
	push	ds
	mov	dx, segment stateFile
	mov	ds, dx
	mov	dx, offset stateFile
	call	FileDelete
	pop	ds
	jmp	noblock
noError:
	mov	ax, MSG_GEN_APPLICATION_SET_ATTACHED_TO_STATE_FILE
	clr	bx			;Tell the app object we have a state
	call	GeodeGetAppObject	; file.
	clr	di
	call	ObjMessage
noblock:

	;
	; after starting app, restoring from, dealing with crash and deleting
	; state files, startup fields (which depend on state)
	;
					; bx = obj block with screens
	mov	bx, ds:[uiSystemObj].handle
	call	UserMakeScreenFields

	;----------------------------------------------------------------------
	;LOAD TASK-SWITCHING DRIVER
	;unless the user specifies "noTaskSwitcher = true"
	;4/12/93: moved from UserAttach so clipboard is opened before task
	;driver is loaded, as it may need to import something from the t/s's
	;clipboard to the GEOS clipboard -- ardeb

	push	ds
	mov	cx, cs
	mov	dx, offset cs:[noTaskSwitcherKeyString]
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	call 	InitFileReadBoolean
	pop	ds
	jc	loadTS			;if no key, load TS by default
	tst	ax			;if noTaskSwitcher = false, go load it
if DBCS_PCGEOS
	jnz	noTS			;branch if noTaskSwitcher = true
else
	jz	loadTS
	jmp	noTS
endif

loadTS:
	call	UserLoadTaskDriver

noTS:
	;
	; start any apps on execOnStartup or execOnStartupBackground list
	;
	clr	cx				;No ExtraData to pass
	call	StartupAppls			;carry set if shutdown

	ret
UserDeleteStateFilesDialogResponse	endp

LocalDefNLString stateString <"*", 0>


;-------------------------------------------------------------------------------
;system category cat name and keys

systemCategoryStr		char	"system", 0

continueSetupStr		char	"continueSetup", 0

if DBCS_PCGEOS
if	ERROR_CHECK
LocalDefNLString graphicalSetupStr <"EC G Setup", 0>
else
LocalDefNLString graphicalSetupStr <"G Setup", 0>
endif
else
if	ERROR_CHECK
LocalDefNLString graphicalSetupStr <"EC Graphical Setup", 0>
else
LocalDefNLString graphicalSetupStr <"Graphical Setup", 0>
endif
endif

if	ERROR_CHECK
LocalDefNLString uiStr <"uiec.geo", 0>
else
LocalDefNLString uiStr <"ui.geo", 0>
endif

;------------------------------------------------------------------------------
;ui category cat name and keys

uiCategoryStr			char	"ui", 0

noResetBoxString		char	"doNotDisplayResetBox",0

deleteStateFilesStr		char	"deleteStateFilesAfterCrash",0

tempDeleteStateFilesStr		char	"forceDeleteStateFilesOnceOnly",0

alwaysDeleteStateFiles		char	"forceDeleteStateFiles",0

specificStr			char	"specific", 0

execOnStartupStr		char	"execOnStartup", 0

execOnStartupBGStr		char	"execOnStartupBackground", 0

numberOfScreensStr		char	"numberOfScreens", 0

initialScreenStr		char	"initialScreen", 0

driverStr			char	"driver", 0

deviceStr			char	"device", 0

overstrikeModeStr		char	"overstrikeMode",0

kbdAcceleratorModeStr		char	"kbdAcceleratorMode",0
				
noSpoolerKeyString		char 	"noSpooler", 0

noMailboxKeyString		char 	"noMailbox", 0

noTaskSwitcherKeyString		char 	"noTaskSwitcher", 0

noClipboardKeyString		char 	"noClipboard", 0

noActivationDialogString	char	"noActivationDialog",0

;------------------------------------------------------------------------------
;input category cat name and keys

inputCategoryStr		char	"input", 0

numMouseButtonsStr		char	"numberOfMouseButtons", 0

clickToTypeStr			char	"clickToType", 0

selectRaisesStr			char	"selectRaises", 0

selectDisplaysMenuStr		char	"selectDisplaysMenu", 0

clickGoesThroughStr		char	"clickGoesThrough", 0

specificUICompatibleStr		char	"specificUICompatible", 0

blinkingCursorStr		char	"blinkingCursor", 0

keyboardOnlyStr			char	"keyboardOnly", 0

noKeyboardStr			char	"noKeyboard", 0

floatingKbdStr			char	"floatingKbd",0

unbuildControllersString	char	"unbuildControllers",0

;------------------------------------------------------------------------------




COMMENT @-----------------------------------------------------------------------

FUNCTION:	UI_LogWriteEntry

DESCRIPTION:	Called by the UI to write an entry out to the log file.

CALLED BY:	INTERNAL (UserAttach)

PASS:		ax - offset to string

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	3/91		Initial version

-------------------------------------------------------------------------------@

logKbdStr		byte	"Keyboard driver", 0
logInputMapStr		byte	"Input Map", 0
logSoundStr		byte	"Sound driver", 0
logTaskStr		char	"Task-Switch Driver", 0
logDefaultTaskStr	char	"Using Default Task-Switch Driver", 0
logFlowObjStr		byte	"Creating Flow Object", 0
if (AUTO_BUSY)
logWatchTimerStr	byte	"Watch Timer", 0
endif
logSpecUIStr		byte	"Specific UI", 0
logClipboardStr		byte	"Clipboard", 0
logTokenDBStr		byte	"Token DB", 0
logPenModeStr		byte	"Entering Pen Mode",0

if not _UI_NO_HWR
logLoadHWRStr		byte	"HWR Library",0
endif ; not _UI_NO_HWR

logScreensStr		byte	"Screens", 0
logScreenBlankerStr	byte	"Screen Blanker", 0
logSpoolerStr		byte	"Spooler", 0
logMailboxStr		byte	"Mailbox", 0
logGrSetupStr		byte	"Graphical Setup", 0
logMouseDrvStr		byte	"Mouse driver", 0
logLoadOverriddenStr	char	" - disabled", 0

UI_LogWriteEntry	proc	near	uses	ds, si
	.enter
FXIP	<	mov	si, SEGMENT_CS	>
FXIP	<	mov	ds, si	>
NOFXIP	<	segmov	ds, cs, si	>
	mov	si, ax
	cmp	ax, offset logFlowObjStr
	je	notInit
	cmp	ax, offset logDefaultTaskStr
	je	notInit
	cmp	ax, offset logPenModeStr
	je	notInit
	call	LogWriteInitEntry
done:
	.leave
	ret
notInit:
	call	LogWriteEntry
	jmp	done
UI_LogWriteEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadTaskDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the task-switch driver specified in the ini file.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
taskDriverCat	char	"task driver", 0
EC <LocalDefNLString defaultTaskDR <"NONTSEC.GEO", 0>			>
NEC <LocalDefNLString defaultTaskDR <"NONTS.GEO", 0>			>
UserLoadTaskDriver proc	near
		uses	ds
		.enter
	;
	; First try the user-specified one. It may refuse to load b/c the
	; task-switcher isn't loaded, or there may not be one defined.
	; 
		mov	ax, offset cs:logTaskStr
		call	UI_LogWriteEntry
		
		mov	ax, SP_TASK_SWITCH_DRIVERS
		mov	cx, TASK_PROTO_MAJOR
		mov	dx, TASK_PROTO_MINOR
		segmov	ds, cs
		mov	si, offset taskDriverCat
		call	UserLoadExtendedDriver
		jnc	setDefaultDriver
	;
	; Since that failed, try the default driver. I know the thing is
	; defined to be an extended driver, but I also know the default driver
	; doesn't do squat with the DRE_TEST_DEVICE and DRE_SET_DEVICE calls,
	; so I'm not going to try and fudge them...
	; 
		mov	ax, offset cs:logDefaultTaskStr
		call	UI_LogWriteEntry

		mov	ax, SP_TASK_SWITCH_DRIVERS
		call	FileSetStandardPath		

		mov	si, offset defaultTaskDR
		mov	ax, TASK_PROTO_MAJOR
		mov	bx, TASK_PROTO_MINOR
		call	GeodeUseDriver
		jc	done
setDefaultDriver:
	;
	; bx = driver handle; set it as *the* task-switch driver for the system.
	; 
		mov	ax, GDDT_TASK
		call	GeodeSetDefaultDriver
done:
		.leave
		ret
UserLoadTaskDriver endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	InitOverstrikeMode

SYNOPSIS:	Sets up overstrike mode flag.

CALLED BY:	UIAttach

PASS:		ds -- dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 8/91		Initial version

------------------------------------------------------------------------------@

InitOverstrikeMode	proc	near
	uses	ax, cx, dx, si
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>

	push	ds				;save current ds
	mov	cx, cs				;setup ds:si = category
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[overstrikeModeStr]
	call	InitFileReadBoolean		;get boolean value
	jnc	setMode				;not found, branch
	clr	al				;else default mode is off
setMode:
	pop	ds				;restore ds
	mov	ds:uiOverstrikeMode, al		;store boolean value
	.leave
	ret
InitOverstrikeMode	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	InitActivationDialogMode

SYNOPSIS:	Sets up activation dialog flag.

CALLED BY:	UIAttach

PASS:		ds -- dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/ 8/91		Initial version

------------------------------------------------------------------------------@

InitActivationDialogMode	proc	near
	uses	ax, cx, dx, si
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>

	push	ds				;save current ds
	mov	cx, cs				;setup ds:si = category
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[noActivationDialogString]
	call	InitFileReadBoolean		;get boolean value
	jnc	setMode				;not found, branch
	clr	al				;else default mode is off
setMode:
	pop	ds				;restore ds
	mov	ds:uiNoActivationDialog, al	;store boolean value
	.leave
	ret
InitActivationDialogMode	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	InitKbdAcceleratorMode

SYNOPSIS:	Sets up kbd accelerator mode flag.

CALLED BY:	UIAttach

PASS:		ds -- dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/15/92	Initial version

------------------------------------------------------------------------------@

InitKbdAcceleratorMode	proc	near
	uses	ax, cx, dx, si
	.enter

EC <	push	ax, bx							>
EC <	mov	bx, ds							>
EC <	mov	ax, segment dgroup					>
EC <	cmp	ax, bx							>
EC <	ERROR_NZ	0						>
EC <	pop	ax, bx							>

	push	ds				;save current ds
	mov	cx, cs				;setup ds:si = category
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[kbdAcceleratorModeStr]
	call	InitFileReadBoolean		;get boolean value
	jnc	setMode				;not found, branch
	mov	al, -1				;else default mode is on
setMode:
	pop	ds				;restore ds
	mov	ds:uiKbdAcceleratorMode, al	;store boolean value
	.leave
	ret
InitKbdAcceleratorMode	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadMouseDriver

DESCRIPTION:	Retrieve and load the mouse driver specified.

CALLED BY:	INTERNAL (UserAttach)

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,bp,di,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	The video driver maintains a "hide cursor" ref count.
	If there is already a mouse driver, the ref count is assumed
		to be 0 (the cursor will already be visible)
	if there is not yet a mouse driver, the ref count is
		assumed to 1. If a mouse driver can be loaded here,
		it is decremented to 0.  If a mouse driver can't be loaded
		here, it is left at 1.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

------------------------------------------------------------------------------@
mouseCategoryStr	char	MOUSE_CATEGORY, 0
secondMouseCategoryStr	char	"secondMouse",0

LoadMouseDriver	proc	near
		uses ds

		.enter

	;
	; See if there is a mouse driver already
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		tst	ax	
		jnz	done
	;
	; Load mouse driver specified in .ini file
	;

		segmov	ds, cs
		mov	si, offset mouseCategoryStr
		mov	ax, SP_MOUSE_DRIVERS
		mov	cx, MOUSE_PROTO_MAJOR
		mov	dx, MOUSE_PROTO_MINOR
		call	UserLoadExtendedDriver
		jc	errorLoadingDriver

loadedMouseDriver:
	;
	; Now set this driver as the default mouse driver for others to find.
	;	bx = mouse handle
	;
		mov	ax, GDDT_MOUSE
		call	GeodeSetDefaultDriver
	;
	; Make pointer visible
	;
		call	ShowDefaultPtr
done:

	;
	; Whether or not we loaded the default mouse driver, see if there's
	; a second mouse driver as well, as on pen-based
	; systems that can use an optional mouse.
	;
		
		segmov	ds, cs
		mov	si, offset secondMouseCategoryStr
		mov	ax, SP_MOUSE_DRIVERS
		mov	cx, MOUSE_PROTO_MAJOR
		mov	dx, MOUSE_PROTO_MINOR
		call	UserLoadExtendedDriver

		.leave
		ret




errorLoadingDriver:
	;
	; If we can't load the mouse driver indicated in the .ini file,
	; or there is no driver indicated, default to loading the keyboard-
	; based driver, as an alternative to having nothing at all.
	; -- Doug 1/93
	;
		call	SysGetPenMode		; Unless, of course, this is a
		tst	ax			; pen system -- then
						; just return
		jnz	done

		push	es
		mov	si, offset defaultMouseDriverStr
		segmov	es, cs, di
		mov	di, offset defaultMouseDeviceStr
if FULL_EXECUTE_IN_PLACE
		push	ds, si
		clr	cx
		segxchg	ds, es
		xchg	si, di			;ds:si = mouse device
		call	SysCopyToStackDSSI	;ds:si = mouse device on stack
		segxchg	ds, es
		xchg	si, di			;es:di = mouse device on stack
		call	SysCopyToStackDSSI	;ds:si = mouse driver on stack
endif
		mov	ax, SP_MOUSE_DRIVERS
		mov	cx, MOUSE_PROTO_MAJOR
		mov	dx, MOUSE_PROTO_MINOR
		call	UserLoadSpecificExtendedDriver
if FULL_EXECUTE_IN_PLACE
		call	SysRemoveFromStack
		call	SysRemoveFromStack	;release stack space
		pop	ds, si
endif		
		pop	es
		jc	done			; exit if error
		jmp	loadedMouseDriver

LoadMouseDriver	endp

NEC <LocalDefNLString defaultMouseDriverStr <"kbmouse.geo",0>		>
EC  <LocalDefNLString defaultMouseDriverStr <"kbmousee.geo",0>		>

LocalDefNLString defaultMouseDeviceStr <'Arrow Key Mouse (Use Ins, Del, and F4.)', 0>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowDefaultPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a SHOW_PTR for the default video driver to
		bring pointer on screen.

CALLED BY:	LoadMouseDriver
PASS:		nothing
RETURN:		nothing
DESTROYED:	bx, di, ax, cx, dx, ds, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/90		Initial version
	brianc	11/2/92		changed to ShowDefaultPtr

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowDefaultPtr	proc	near
		.enter
		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver	; ax <- video driver
		tst	ax			; no video driver, no ptr
		jz	done			;	to hide
		mov	bx, ax
		call	GeodeInfoDriver		;ds:si <- DriverInfoStruct

		mov	di, DR_VID_SHOWPTR
		call	ds:[si].DIS_strategy
done:
		.leave
		ret
ShowDefaultPtr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetIniString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch a string from the .ini file.

CALLED BY:	INTERNAL
PASS:		ds:si	= category string
		cx:dx	= key string
RETURN:		carry clear if key found:
			ds:si	= string from the .ini file
			bx	= handle of buffer in which string is allocated
				  (locked, must be freed by caller)
		carry set if key not found
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetIniString	proc	near	uses bp, cx, ax
		.enter
		mov	bp, INITFILE_INTACT_CHARS
		call	InitFileReadString
		jc	done
		
		call	MemLock
		mov	ds, ax
		clr	si
done:
		.leave
		ret
GetIniString	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	StartupAppls

DESCRIPTION:	

CALLED BY:	INTERNAL (UserAttach, MSG_USER_STARTUP_APPLS)

PASS:		CX - Value to pass as ALB_extraData in AppLaunchBlock

RETURN:		carry set if user wants to shutdown because of app launch
			error
		carry clear if all is well (apps successfully launched or
			user is allow us to continue even though app launch
			error occurred)

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version

-------------------------------------------------------------------------------@

StartupAppls	method	UserClass, MSG_USER_STARTUP_APPLS
	;----------------------------------------------------------------------
	;load in all programs specified

	push	ds
	mov	bx, cx				; pass ALB_extraData in BX
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[execOnStartupStr]
	mov	bp, mask IFRF_READ_ALL		; look in all ini files, please
	mov	di, cs
	mov	ax, offset StartupAppls_callback
	push	bx
	call	InitFileEnumStringSection
	pop	ax
	cmc					;carry clear if enum error
	jnc	doneShutdown			;enum error, continue
	;
	; startup apps were enumerated, see if user wants to shutdown
	; because of an error launching one of them
	;
	cmp	ax, bx				;did callback alter this?
	jne	doneShutdown			;yes, shutdown requested

	mov	bx, ax				; pass ALB_extraData in BX
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:[uiCategoryStr]
	mov	dx, offset cs:[execOnStartupBGStr]
	mov	bp, mask IFRF_READ_ALL		; look in all ini files, please
	mov	di, cs
	mov	ax, offset StartupApplsBG_callback
	push	bx
	call	InitFileEnumStringSection
	pop	ax
	cmc					;carry clear if enum error
	jnc	doneShutdown			;enum error, continue

	cmp	ax, bx				;did callback alter this?
	je	done				;nope, no shutdown, continue
doneShutdown:
	stc					;else, indicate shutdown
						;	requested
done:
	pop	ds
	ret

StartupAppls	endm

NEC <LocalDefNLString defaultUI	<"motif.geo",0>				>
EC  <LocalDefNLString defaultUI	<"motifec.geo",0>			>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartupAppls_callback, StartupApplsBG_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to start up an application listed in
		the execOnStartup key.

CALLED BY:	StartupAppls via InitFileEnumStringSection
PASS:		ds:si	= app to start
		dx	= section #
		cx	= length of section
		es	= ?
		bx	= extraData to pass to application
RETURN:		es, bx	= values to pass to next iteration
		carry set to stop enumeration
DESTROYED:	ax, cx, dx, di, si, bp may all be biffed

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartupAppls_callback proc	far
		.enter
		cmp	cx, -1
		je	done
	;
	; Now load the app. We always give the user a choice of whether to
	; shut down or not.
	; 
		mov	bp, bx
		mov	bx, 1		; it's ok for app to not exist
		mov	ah, mask ALF_NO_ACTIVATION_DIALOG
					;don't display "Loading ..." dialog,
					;   as the user hasn't asked for an
					;   application to be loaded
		call	LoadApplicationWithErrorMessage
	;
	; Return extra data in bx again.
	; 
		mov	bx, bp
		jnc	done
	;
	; User is shutting down the system, so change BX to tell StartupAppls
	; that we actually were called, but stop enumerating sections (NOT
	; doesn't touch the carry)
	; 
		not	bx
done:
		.leave
		ret
StartupAppls_callback endp


StartupApplsBG_callback proc	far
		.enter
		cmp	cx, -1
		je	done
	;
	; Now load the app. We always give the user a choice of whether to
	; shut down or not.
	; 
		mov	bp, bx
		mov	bx, 1		; it's ok for app to not exist
	;
	; Start the app without an activation dialog, in the background
	; and don't bring it to the top. It does receive MSG_VIS_OPEN, so
	; when the user switches to it, there is no delay as the UI is
	; opened.
	;
		mov	ah, mask ALF_NO_ACTIVATION_DIALOG or \
			    mask ALF_OPEN_IN_BACK or \
			    mask ALF_DO_NOT_OPEN_ON_TOP
		call	LoadApplicationWithErrorMessage
	;
	; Return extra data in bx again.
	; 
		mov	bx, bp
		jnc	done
	;
	; User is shutting down the system, so change BX to tell StartupAppls
	; that we actually were called, but stop enumerating sections (NOT
	; doesn't touch the carry)
	; 
		not	bx
done:
		.leave
		ret
StartupApplsBG_callback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadApplicationWithErrorMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads an application and puts up a SysNotify box if any error.

CALLED BY:	GLOBAL
PASS:		ds:si - ptr to application to load
		bx - 0 if we want to force a shutdown with an error
		     non-zero if we want to give the user a choice
		bp - value to stuff in ALB_extraData
		ah - AppLaunchFlags

RETURN:		carry set if the user is shutting down the system.
		ax = 0 if no error
DESTROYED:	ax, bx, cx, dx
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadApplicationWithErrorMessage	proc	near
	uses	es, ds, di, si, bp
	.enter
	push	bx			;Save error flag
	push	ax			;Save AppLaunchFlags
	mov	ax, size AppLaunchBlock
	mov	cx, (mask HAF_ZERO_INIT shl 8) or mask HF_SHARABLE or ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	pop	cx			; ch <- AppLaunchFlags
	mov	dx, bx			; Put block handle in dx
	jc	doneWithLoad		;
	push	ds			;
	mov	ds, ax			;
	mov	ds:[ALB_extraData],bp	;
	pop	ds			;
	call	MemUnlock		;Unlock AppLaunchBlock
	mov	ah, ch			; ah <- AppLaunchFlags
FXIP<	push	ds, si							>
FXIP<	clr	cx			;cx = null-terminated str	>
FXIP<	call	SysCopyToStackDSSI	;dssi = appl name on stack	>
	mov	cx, MSG_GEN_PROCESS_OPEN_APPLICATION
	clr	bx			;search system dirs
	call	UserLoadApplication	;
FXIP<	call	SysRemoveFromStack	;release stack space		>
FXIP<	pop	ds, si							>
doneWithLoad:
	pop	bx
	mov	ax, 0			;Assume no error
	LONG jnc exit			;If no error, branch

;	GET LENGTH OF APPLICATION NAME IN CX

	segmov	es, ds, di		;
	mov	di, si			;ES:DI <- application name
if DBCS_PCGEOS
	call	LocalStringSize		;CX <- # bytes in app name w/o null
else
	mov	cx, -1
	clr	al
	repne	scasb
	not	cx			;CX <- # bytes in app name + null
endif

;	CREATE STACK FRAME TO BUILD OUT ERROR MESSAGE IN

SBCS <	add	cx, 3			;Add bytes for quotes, and period>
DBCS <	add	cx, 4*(size wchar)	;Add bytes for quotes, and period>
	sub	sp, cx			;Create stack frame
	mov	bp, sp			;
	push	cx			;Save size of stack frame
	segmov	es, ss, di
	mov	di, bp			;ES:DI <- dest for name
SBCS <	mov	al, C_QUOTE						>
DBCS <	mov	ax, C_QUOTATION_MARK					>
	LocalPutChar	esdi, ax	;Add open quote
SBCS <	sub	cx, 4			;CX <- size of text (sans null-term)>
DBCS <	sub	cx, 4*(size wchar)	;CX <- size of text (sans null-term)>
	rep	movsb			;Copy filename onto the stack
SBCS <	mov	ax, C_QUOTE		;ax <- quote + null		>
DBCS <	mov	ax, C_QUOTATION_MARK					>
	stosw				;Save out ending punctuation + null
DBCS <	clr	ax							>
DBCS <	LocalPutChar esdi, ax						>
	mov	dx, bx			;DX <- shutdown flag

;	FIRST AND SECOND STRINGS MUST BE IN SAME SEGMENT, SO MUST MOVE FIRST
;	STRING ONTO THE STACK.

	mov	bx, handle cannotLoadAppError
	call	MemLock
	mov	ds, ax			;DS:SI <- null terminated first string
assume	ds:Strings
	mov	si, ds:[cannotLoadAppError]
	ChunkSizePtr	ds, si, cx
	sub	sp, cx			;Make room on stack for first
					; string.
	mov	di, sp
	push	cx			;Save size of stack frame
	push	di			;Save ptr to stack frame
	rep	movsb
	call	MemUnlock	
assume	ds:dgroup
	segmov	ds, ss
	pop	si			;DS:SI <- first string
	mov	di, bp			;DS:DI <- second string

	mov	ax, mask SNF_ABORT or mask SNF_CONTINUE
	tst	dx			;If serious shutdown, don't allow user
	jnz	80$			; to continue	
	mov	ax, mask SNF_EXIT	;
80$:
	call	SysNotify		;
	pop	cx			;Get stack frame size
	add	sp, cx			;Nuke stack frame	
	pop	cx			;Get stack frame size
	add	sp, cx			;Nuke stack frame
	test	ax, mask SNF_ABORT	;
	jz	90$			;
	mov	ax, SST_CLEAN_FORCED	;
	call	SysShutdown		;Shutdown the system
	stc				;Set carry to denote shutdown
	jmp	99$
90$:
	clc
99$:
	mov	ax, -1
exit:
	.leave
	ret
LoadApplicationWithErrorMessage	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	LoadScreenBlanker

DESCRIPTION:	

CALLED BY:	INTERNAL (InitGeos)

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	5/90		Initial version

-------------------------------------------------------------------------------@


screenBlankerKeyString		byte	"screenBlanker", 0
screenBlankerTimeoutKeyString	byte	"screenBlankerTimeout", 0

LoadScreenBlanker	proc	near	uses	ds
	.enter
	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:uiCategoryStr
	mov	dx, offset cs:screenBlankerKeyString
	call	InitFileReadBoolean	;ax <- -1 / 0
	jc	done			;default to off

	inc	ax			;transform T to 0, F to 1
	jne	done			;branch if F
	
	mov	dx, offset cs:screenBlankerTimeoutKeyString
	call	InitFileReadInteger	;ax <- value
	mov	cx, SCREEN_BLANKER_DEFAULT ;default value
	jc	useDefault		;use default if no value retrieved
	mov	cx, ax

useDefault:
	mov	ax, MSG_IM_SET_SCREEN_SAVER_DELAY
	mov	di, mask MF_FORCE_QUEUE
	call	UserMessageIM

	mov	ax, MSG_IM_ENABLE_SCREEN_SAVER	; turn it on
	mov	di, mask MF_FORCE_QUEUE
	call	UserMessageIM

done:
	.leave
	ret
LoadScreenBlanker	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadSpooler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads up the spooler as an application so we can specify which
		field it will come up on. Returns carry set if error.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if error
		else, bx - geode process handle
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString spoolerName <"SPOOLEC.GEO",0>			>
NEC <LocalDefNLString spoolerName <"SPOOL.GEO",0>			>

UserLoadSpooler	proc	near	uses	ds
	.enter

	mov	si, offset spoolerName
	mov	dx, offset noSpoolerKeyString
	mov	ax, offset logSpoolerStr
	call	UserLoadSysLibraryApp
	
	.leave
	ret
UserLoadSpooler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadMailbox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads up the mailbox library as an application so we can
		specify which field it will come up on. Returns carry set if
		error.

CALLED BY:	(INTERNAL)
PASS:		nada
RETURN:		carry set if error
			bx	= 0
		else
			bx 	= geode process handle
DESTROYED:	ax, dx, cx, si
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <LocalDefNLString	mailboxName, <"MAILBOXE.GEO", C_NULL>		>
NEC <LocalDefNLString	mailboxName, <"MAILBOX.GEO", C_NULL>		>

UserLoadMailbox	proc	near	uses	ds
	.enter

	mov	si, offset mailboxName
	mov	dx, offset noMailboxKeyString
	mov	ax, offset logMailboxStr
	call	UserLoadSysLibraryApp
	
	.leave
	ret
UserLoadMailbox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadSysLibraryApp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a library application that lives in SP_SYSTEM

CALLED BY:	(INTERNAL) UserLoadSpooler, 
			   UserLoadMailbox
PASS:		cs:si	= filename of application
		cs:dx	= boolean ini key to look for to see if load should
			  be skipped
		ax	= log string to use
RETURN:		carry set if couldn't load:
			bx	= 0
		carry clear if no error:
			bx	= geode handle (0 if ini file said not to
				  load it)
DESTROYED:	ax, cx, dx, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserLoadSysLibraryApp proc	near
		.enter
	;
	; Log what we're about to load.
	; 
		call	UI_LogWriteEntry
	;
	; First check the .ini file for an override that would make us
	; not load this thing.
	; 
		push	si
		mov	cx, cs
		mov	ds, cx
		mov	si, offset cs:[uiCategoryStr]
		call	InitFileReadBoolean
		pop	si
		jc	loadIt			;if no key, load  by default
		tst	ax			;if false, load it
		jz	loadIt

		mov	ax, offset logLoadOverriddenStr
		call	UI_LogWriteEntry
		clr	bx			; return a 0 handle to indicate
						;  we didn't load it
		jmp	done
loadIt:
	;
	; It's ok to load the thing.
	; ds = cs
	; 
		;
		; Now load the beastie
		;
		mov	bx, SP_SYSTEM
		mov	ah, mask ALF_NO_ACTIVATION_DIALOG
						;don't display "Loading ..." DB
						;   as the user hasn't asked for
						;   an application to be loaded
		clr	cx			;default open mode
		mov	dx, cx			;no ALB passed
		call	UserLoadApplication
		jnc	done
		mov	bx, 0
done:
		.leave
		ret
UserLoadSysLibraryApp endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserLoadHWR
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads up the handwriting-recognition driver.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		carry set if error
		else, bx - geode process handle
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	7/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _UI_NO_HWR

HWRKeyString	char	"hwr",0
EC <HWRString	char	"palmec.geo",0	>
NEC <HWRString	char	"palm.geo",0	>

UserLoadHWR	proc	near	uses	ds
	.enter
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath

	mov	cx, cs
	mov	ds, cx
	mov	si, offset cs:uiCategoryStr
	mov	dx, offset HWRKeyString
	call	GetIniString
	jc	loadDefault

;	Save the handle containing the library name
;	Try to load the library
;	Free the library name

	push	bx
	clrdw	axbx
	call	GeodeUseLibrary
	mov_tr	ax, bx			;AX <- library handle
	pop	bx
	pushf
	call	MemFree
	popf
	mov_tr	bx, ax			;BX <- library handle
exit:
	.leave
	ret
loadDefault:
	segmov	ds, cs
	mov	si, offset HWRString
	clrdw	axbx
	call	GeodeUseLibrary
	jmp	exit
UserLoadHWR	endp

endif ; not _UI_NO_HWR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserUpdateSoundParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine updates the sound parameters (like if the sound
		driver is loaded or not)

CALLED BY:	GLOBAL
PASS:		ds - segment of UserClass
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/19/90		Initial version
	kho	8/18/95		Add support for keyclick in responder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
soundString		char	"sound",0
soundMaskString		char	"soundMask",0
EC <LocalDefNLString libraryString <"soundec.geo",0>			>
NEC <LocalDefNLString libraryString <"sound.geo", 0>			>

UserUpdateSoundParams	method	dynamic UserClass,
						MSG_USER_UPDATE_SOUND_PARAMS
	uses	es, ds
	.enter

	PSem	ds, soundDriverSem, TRASH_AX_BX
	push	ds
	segmov	es, ds
	mov	cx, cs
	mov	ds, cx

	mov	si, offset uiCategoryStr
	;
	; Read the standard sound mask
	;
	mov	dx, offset soundMaskString
	mov	ax, SOUND_MASK_ALL
	call	InitFileReadInteger
	mov	es:[soundMask], ax

	mov	dx, offset soundString
	call	InitFileReadBoolean
	pop	ds
	jc	yesSound		;If no sound parameter, default to 
					; having sound. 
	tst	ax			;If parameter was "false", no sound
	jz	noSound			;
					;Else, we have sound...
yesSound:
	tst	ds:[soundDriver]	;Check to see if library already loaded
	jnz	exit			;If so, exit
	push	ds
	mov	ax, SP_SYSTEM
	call	FileSetStandardPath
	segmov	ds, cs, di
	mov	si, offset libraryString
	clr	ax			;Don't care about protocol
	mov	bx, ax
	call	GeodeUseLibrary
	pop	ds
	jc	noSoundLoaded
	mov	ds:[soundDriver],bx
	push	ds
	call	GeodeInfoDriver		;Get ptr to strategy routine
	mov	bx, ds:[si].DIS_strategy.offset
	mov	dx, ds:[si].DIS_strategy.segment
	pop	ds
	mov	ds:[soundDriverEntry].offset, bx
	mov	ds:[soundDriverEntry].segment, dx
	jmp	exit
noSound:
	mov	bx, ds:[soundDriver]	;If no library loaded yet, just exit
	tst	bx
	jz	exit
	call	GeodeFreeLibrary	;Nuke the library
noSoundLoaded:
	clr	ds:[soundDriver]
exit:
		
	VSem	ds, soundDriverSem, TRASH_AX_BX
	.leave
	ret
UserUpdateSoundParams	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RespUpdateSoundParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update params for responder.

CALLED BY:	INTERNAL (UserUpdateSoundParams / SetUpStandardSounds)
PASS:		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		We need to update key click and alarm tone. To be API
		complete, standardSoundHandles and soundMask are
		updated so that UserStandardSound gives the right key
		click or alarm tone.

		In SetUpStandardSounds, responder specific sounds are
		initialized and handles stored in respSpecialSoundHandles.
		All we need to do is to take the right handles into
		standardSoundHandles.

		If key click is NONE, we change soundMask to prevent
		UserStandardSound from making the sound.

		Why would SetUpStandardSounds need to call me:
		Well, UserUpdateSoundParams is called when library
		inits, but SetUpStandardSounds is not called until
		the first UserStandardSound event.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/29/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserFreeSoundHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free a sound handle

CALLED BY:	MSG_USER_FREE_SOUND_HANDLE
PASS:		*ds:si	= UserClass object
		ds:di	= UserClass instance data
		ds:bx	= UserClass object (same as *ds:si)
		es 	= segment of UserClass
		ax	= message #

		cx	= block handle to destroy

RETURN:		nothing
DESTROYED:	ax

SIDE EFFECTS:
		Free's block who's handle is passed in cx
		
PSEUDO CODE/STRATEGY:
		Free that puppy.

		You are probably asking "why does this routine
			even exist?"

		Well, I'll tell you.  The sound library uses timers
			to determine when the next note is going to
			play and when the next note is going to turn
			off.  When the last note of the song turns
			off, it would be nice to free up the block
			that contained the sound (since it will never
			be used again).  The problem comes in that
			the song ends in a timer.

		Since a timer is not executing on its own thread,
			it can't do anything that will cause the
			thread to block.  This is to prevent deadlock
			from occuring.

		Thus, what we do is send a message to a thread which
			can block, and let it do the blocking for us.

		Just thought you should know.
				-- todd	02/04/93
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	2/ 4/93   	Initial version
	AY	6/22/95		Changed to call Sound lib to do the work

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserFreeSoundHandle	method dynamic UserClass, 
					MSG_USER_FREE_SOUND_HANDLE

	mov	bx, cx			; ^hbx = SoundControl to free
	call	MemLock
	mov	ds, ax			; ds:0 = SoundControl
	mov	si, ds:[SC_status].SBS_type	; si = SoundType
	shl	si
	pushdw	cs:[freeRoutineTable][si]
	call	PROCCALLFIXEDORMOVABLE_PASCAL	; Do NOT use GOTO!

	ret
UserFreeSoundHandle	endm

		CheckHack <ST_SIMPLE_FM eq 0>
		CheckHack <ST_STREAM_FM eq 2>
		CheckHack <ST_SIMPLE_DAC eq 4>
		CheckHack <ST_STREAM_DAC eq 6>
freeRoutineTable	vfptr	\
	SoundFreeMusic,
	SoundFreeMusicStream,
	MemFree,			; There's currently no way to allocate
					; a ST_SIMPLE_DAC sound, so we should
					; never be passed such blocks.  If we
					; do get this block type due to some
					; error, we just free the block but
					; don't bother freeing SBS_mutExSem.
					; --- AY 6/22/95
	SoundFreeSampleStream

		CheckHack <SoundType shr 1 eq length freeRoutineTable>



COMMENT @----------------------------------------------------------------------

FUNCTION:	SetDefaultInputMap

DESCRIPTION:	Set the default button map

CALLED BY:	INTERNAL(UserAttach)

PASS:
	ds - dgroup

RETURN:		none

DESTROYED:	ax, bx, cx, dx, si, di, bp

REGISTER/STACK USAGE:
	bp = offset of table
	cx = table size
	dh = bits to mask OUT
	dl = bits to mask IN

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	8/89		Initial version
	Cheng	12/89		Rewrote to use the new init file routines

------------------------------------------------------------------------------@

idata	segment

tableOffset	word	0
outMask		byte	0
inMask		byte	0

idata	ends

SetDefaultInputMap	proc	near

	clr	ds:[inMask]
	clr	ds:[outMask]

	mov	si, offset cs:[inputCategoryStr]

	;-----------------------------------------------------------------------
	;check all possible options

	call	CheckNumMouseButtons

	mov	dx, offset cs:[clickToTypeStr]
	mov	bl, mask UIBF_CLICK_TO_TYPE
	call	CheckKey

	mov	dx, offset cs:[selectRaisesStr]
	mov	bl, mask UIBF_SELECT_ALWAYS_RAISES
	call	CheckKey

	mov	dx, offset cs:[selectDisplaysMenuStr]
	mov	bl, mask UIBF_SELECT_DISPLAYS_MENU
	call	CheckKey

	mov	dx, offset cs:[clickGoesThroughStr]
	mov	bl, mask UIBF_CLICK_GOES_THRU
	call	CheckKey

	mov	dx, offset cs:[specificUICompatibleStr]
	mov	bl, mask UIBF_SPECIFIC_UI_COMPATIBLE
	call	CheckKey

	mov	dx, offset cs:[blinkingCursorStr]
	mov	bl, mask UIBF_BLINKING_CURSOR
	call	CheckKey

	mov	dx, offset cs:[keyboardOnlyStr]
	mov	bl, mask UIBF_KEYBOARD_ONLY
	call	CheckKey
	; 
	; if no .ini file entry for "keyboardOnly", default to false
	; if pen system, otherwise consult mouse driver.
	;
	jnc	afterKeyboardOnly
	call	SysGetPenMode
	tst	ax
	jnz	afterKeyboardOnly
	mov	ax, GDDT_MOUSE
	call	GeodeGetDefaultDriver		;ax = mouse driver
	tst	ax
	jz	keyboardOnly
	mov_tr	bx, ax
	push	ds, si				;save category string
	call	GeodeInfoDriver		;ds:si = MouseDriverInfoStruct
	test	ds:[si].MDIS_flags, mask MDIF_KEYBOARD_ONLY
	pop	ds, si				;restore category string
	jz	afterKeyboardOnly
keyboardOnly:
						;if no mouse driver then
						;default to keyboard only
	or	ds:[inMask], mask UIBF_KEYBOARD_ONLY
afterKeyboardOnly:

	mov	dx, offset cs:[noKeyboardStr]
	mov	bl, mask UIBF_NO_KEYBOARD
	call	CheckKey

	;-----------------------------------------------------------------------
	;done checking

;
;	Check to see if we always want the floating kbd to come on screen,
;	even if there is a kbd attached.
;
;	if so, set the flag.
;
	push	ds
	mov	dx, offset cs:[floatingKbdStr]
	mov	cx, cs		;CX:DX <- key
	mov	ds, cx		;DS:SI <- category
	clr	ax		;Default to "false"
	call	InitFileReadBoolean
	pop	ds
	mov	ds:[floatingKbdEnabled], al

	;----------------------------------------------------------------------
	;allocate a block for the input map

	mov	si, ds:[tableOffset]
	mov	ax, size ButtonMapEntry
	mul	cs:[si].IMH_buttonMapCount
	add	ax, size InputMapHeader

	push	ds

	push	ax
	mov	cx, ALLOC_DYNAMIC_NO_ERR or (mask HAF_LOCK shl 8)
	call	MemAlloc

	mov	es,ax				;es:di = destination
	clr	di

	;-----------------------------------------------------------------------
	;copy the stuff

	segmov	ds, cs
	push	ds:[si].IMH_buttonMapTable	; save location of map array

		CheckHack <(size InputMapHeader and 1) eq 0>
	mov	cx, size InputMapHeader/2	; first move the header in
	rep	movsw

	pop	si			; ds:si <- ButtonMapEntry array
	pop	cx			; cx <- block size

	sub	cx, size InputMapHeader	; reduce by already-moved header
	shr	cx			; moving words...
	rep	movsw
	jnc	setMapPointer
	movsb

setMapPointer:
	mov	es:[IMH_buttonMapTable], 	; point to new location of
			size InputMapHeader	;  map array
	pop	ds

	;-----------------------------------------------------------------------
	;set the constrain key

	mov	ax, word ptr es:[IMH_constrain1]

	;-----------------------------------------------------------------------
	;save the ui flags

	mov	cl, es:[IMH_flags]
	or	cl, ds:[inMask]
	not	ds:[outMask]
	and	cl, ds:[outMask]
	mov	es:[IMH_flags],cl

	;-----------------------------------------------------------------------
	;unlock the block

	call	MemUnlock

	;-----------------------------------------------------------------------
	;store the handle

	mov	ds:[uiInputMapHandle],bx
	mov	ds:[uiButtonFlags],cl
	ret
SetDefaultInputMap	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckNumMouseButtons

DESCRIPTION:	

CALLED BY:	INTERNAL (SetDefaultInputMap)

PASS:		si - offset to category ASCIIZ string

RETURN:		tableOffset

DESTROYED:	ax,dx

REGISTER/STACK USAGE:
	bx - table size
	bp - table offset

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@
DEFAULT_NUM_BUTTONS	=	3

inputMapTable	nptr.InputMapHeader 	OneButton, 
					TwoButton,
					ThreeButton
			

CheckNumMouseButtons	proc	near	uses bx, bp, cx, si
	.enter

	push	ds
	segmov	ds, cs, cx
	mov	dx, offset cs:[numMouseButtonsStr]
	call	InitFileReadInteger	;ax <- integer value
	pop	ds
	jnc	gotNumButtons		;use default if bad integer

	push	bx, si, ds
	mov	ax, GDDT_MOUSE
	call	GeodeGetDefaultDriver	;ax = mouse driver
	mov_tr	bx, ax
	mov	ax, DEFAULT_NUM_BUTTONS
	tst	bx
	jz	10$
	call	GeodeInfoDriver		;ds:si = MouseDriverInfoStruct
	mov	ax, ds:[si].MDIS_numButtons
10$:
	pop	bx, si, ds

gotNumButtons:
	dec	ax			; 0-origin, thanks
	shl	ax			; *2 to index buttonMapTable
	mov_tr	bx, ax

	cmp	bx, size inputMapTable
	jbe	useTableOffset
	mov	bx, (DEFAULT_NUM_BUTTONS-1) shl 1
useTableOffset:
	mov	ax, cs:[inputMapTable][bx]
	mov	ds:[tableOffset], ax

	.leave
	ret
CheckNumMouseButtons	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	CheckKey

DESCRIPTION:	

CALLED BY:	INTERNAL (SetDefaultInputMap)

PASS:		si - offset to category ASCIIZ string
		dx - offset to key ASCIIZ string
		bl - mask
		

RETURN:		ds:[inMask], ds:[outMask] - modified by bl
		carry set if .ini file entry *not* found
		carry clear if found

DESTROYED:	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	12/89		Initial version

-------------------------------------------------------------------------------@

CheckKey	proc	near
	push	ds

	mov	cx, cs
	mov	ds, cx

	call	InitFileReadBoolean	;ax <- boolean
	pop	ds
	jc	exit			;exit w/C set (not found)

	tst	ax			;false?
	je	negOption
	or	ds:[inMask], bl
	jmp	short found

negOption:
	or	ds:[outMask], bl
found:
	clc				;found

exit:
	ret

CheckKey	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserInstallRemoveKeyClickMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install an input monitor to intercept key press and
		make noise if appropriate, or remove the monitor.

CALLED BY:	UserAttach (INT)
PASS:		cx	= non zero to install monitor
		cx	= 0 to remove monitor
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/17/95    	Initial version (modified after
				OLFieldEnsureStickyMonitor) 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSoftwareExpiration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the software has expired

CALLED BY:	UserAttach()
PASS:		none
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	
	Doesn't return if the specified date has passed.

PSEUDO CODE/STRATEGY:
	NOTE: To make the system expire, place this code in the UI library.
	A call in UserAttach() (found in Library/User/User/userMain.asm)
	before the specific UI is loaded, where the code for the title
	screen used to be should suffice.  Be sure to enclose the call
	in an "if SOFTWARE_EXPIRES / endif" pair.

	NOTE: This routine needs an error string defined in the Strings
	segment.  Use LocalDefString in userStrings.asm.  Be sure to
	enclose the string in an "if SOFTWARE_EXPIRES / endif" pair.
	Something like:
if SOFTWARE_EXPIRES

LocalDefString softwareExpiredError 
<"This test version of the software has expired -- 
  please download a new version.", 0>

endif

	Finally, to get the software to compile correctly, place:
;----------------------------------------------------------------------
; Set this flag "true" if your product "expires" after a given date.
; Set the year, month and day for the last day the software should work.
----------------------------------------------------------------------
		E.g.	SOFTWARE_EXPIRES = TRUE
			SOFTWARE_EXPIRATION_YEAR	equ	1997
			SOFTWARE_EXPIRATION_MONTH	equ	9
			SOFTWARE_EXPIRATION_DAY		equ	1

	(or FALSE, depending on the version you're compiling) in
	Library/User/uiConstant.gp.
	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/ 4/97    	Initial version
	tom	9/10/97		Minor changes as installed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef SOFTWARE_EXPIRES	; in case SOFTWARE_EXPIRES isn't defined
if SOFTWARE_EXPIRES

CheckSoftwareExpiration	proc	near
		uses	ax, bx, cx, dx
		.enter

		call	TimerGetDateAndTime
		cmp	ax, SOFTWARE_EXPIRATION_YEAR		;check year
		ja	softwareExpired
		jb	done					;OK if
								;year
								;less than
		cmp	bl, SOFTWARE_EXPIRATION_MONTH		;check month
		ja	softwareExpired
		jb	done					;OK if
								;month
								;less than
		cmp	bh, SOFTWARE_EXPIRATION_DAY		;check day
		ja	softwareExpired
done:
		.leave
		ret

	;
	; the software has expired.  display an error and exit the system
	;
softwareExpired:
		mov	bx, handle softwareExpiredError
		call	MemLock
		mov	ds, ax
assume	ds:Strings    
		mov	si, ds:[softwareExpiredError]
assume	ds:dgroup
		mov	ax, SST_DIRTY
		jmp	SysShutdown

CheckSoftwareExpiration	endp

endif
endif

;------------------------------------------------------------------------------
;	Default button mapping table for a one button mouse
;------------------------------------------------------------------------------

OneButton	InputMapHeader <
	OneButtonMap,			; IMH_buttonMapTable
	length OneButtonMap,		; IMH_buttonMapCount
	mask SS_LSHIFT,			; IMH_contrain 1
	mask SS_RSHIFT,			; IMH_contrain 2
	mask UIBF_CLICK_TO_TYPE or \
	mask UIBF_SELECT_ALWAYS_RAISES or \
	mask UIBF_BLINKING_CURSOR	; IMH_flags
>
OneButtonMap	ButtonMapEntry \
	<
	    BUTTON_0,
	    0,
	    MSG_META_START_SELECT,
	    0
	>,
	<
	    BUTTON_0,
	    mask SS_LSHIFT,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND
	>,
	<
	    BUTTON_0,
	    mask SS_RSHIFT,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND
	>,
	<
	    BUTTON_0,
	    mask SS_LCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_RCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_LSHIFT or mask SS_LCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND or mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_RSHIFT or mask SS_RCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND or mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_LALT or mask SS_LCTRL,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_MOVE
	>,
	<
	    BUTTON_0,
	    mask SS_RALT or mask SS_RCTRL,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_MOVE
	>,
	<
	    BUTTON_0,
	    mask SS_LALT,
	    MSG_META_START_FEATURES,
	    mask UIFA_POPUP
	>,
	<
	    BUTTON_0,
	    mask SS_RALT,
	    MSG_META_START_FEATURES,
	    mask UIFA_POPUP
	>

;------------------------------------------------------------------------------
;	Default button mapping table for a two button mouse
;------------------------------------------------------------------------------

TwoButton	InputMapHeader <
	TwoButtonMap,		; IMH_buttonMapTable
	length TwoButtonMap,	; IMH_buttonMapCount
	mask SS_LSHIFT,			; IMH_contrain 1
	mask SS_RSHIFT,			; IMH_contrain 2
	mask UIBF_CLICK_TO_TYPE or \
	mask UIBF_SELECT_ALWAYS_RAISES or \
	mask UIBF_BLINKING_CURSOR	; IMH_flags
>

TwoButtonMap	ButtonMapEntry \
	<
	    BUTTON_0,
	    0,
	    MSG_META_START_SELECT,
	    0
	>,
	<
	    BUTTON_0,
	    mask SS_LSHIFT,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND
	>,
	<
	    BUTTON_0,
	    mask SS_RSHIFT,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND
	>,
	<
	    BUTTON_0,
	    mask SS_LCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_RCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_LSHIFT or mask SS_LCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND or mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_RSHIFT or mask SS_RCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND or mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_LALT,
	    MSG_META_START_FEATURES,
	    mask UIFA_POPUP
	>,
	<
	    BUTTON_0,
	    mask SS_RALT,
	    MSG_META_START_FEATURES,
	    mask UIFA_POPUP
	>,
	<
	    BUTTON_2,
	    0,
	    MSG_META_START_MOVE_COPY,
	    0
	>,
	<
	    BUTTON_2,
	    mask SS_LSHIFT,
	    MSG_META_START_MOVE_COPY,
	    0
	>,
	<
	    BUTTON_2,
	    mask SS_RSHIFT,
	    MSG_META_START_MOVE_COPY,
	    0
	>,
	<
	    BUTTON_2,
	    mask SS_LALT,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_MOVE
	>,
	<
	    BUTTON_2,
	    mask SS_RALT,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_MOVE
	>,
	<
	    BUTTON_2,
	    mask SS_LCTRL,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_COPY
	>,
	<
	    BUTTON_2,
	    mask SS_RCTRL,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_COPY
	>


;------------------------------------------------------------------------------
;	Default button mapping table for a three button mouse
;------------------------------------------------------------------------------

ThreeButton	InputMapHeader <
	ThreeButtonMap,		; IMH_buttonMapTable
	length ThreeButtonMap,	; IMH_buttonMapCount
	mask SS_LSHIFT,			; IMH_contrain 1
	mask SS_RSHIFT,			; IMH_contrain 2
	mask UIBF_CLICK_TO_TYPE or \
	mask UIBF_SELECT_ALWAYS_RAISES or \
	mask UIBF_BLINKING_CURSOR	; IMH_flags
>

ThreeButtonMap	ButtonMapEntry \
	<
	    BUTTON_0,
	    0,
	    MSG_META_START_SELECT,
	    0
	>,
	<
	    BUTTON_0,
	    mask SS_LSHIFT,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND
	>,
	<
	    BUTTON_0,
	    mask SS_RSHIFT,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND
	>,
	<
	    BUTTON_0,
	    mask SS_LCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_RCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_LSHIFT or mask SS_LCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND or mask UIFA_ADJUST
	>,
	<
	    BUTTON_0,
	    mask SS_RSHIFT or mask SS_RCTRL,
	    MSG_META_START_SELECT,
	    mask UIFA_EXTEND or mask UIFA_ADJUST
	>,

	<
	    BUTTON_1,
	    0,
	    MSG_META_START_FEATURES,
	    mask UIFA_POPUP
	>,
	<
	    BUTTON_1,
	    mask SS_LALT,
	    MSG_META_START_FEATURES,
	    mask UIFA_PAN
	>,
	<
	    BUTTON_1,
	    mask SS_RALT,
	    MSG_META_START_FEATURES,
	    mask UIFA_PAN
	>,

	<
	    BUTTON_2,
	    0,
	    MSG_META_START_MOVE_COPY,
	    0
	>,
	<
	    BUTTON_2,
	    mask SS_LSHIFT,
	    MSG_META_START_MOVE_COPY,
	    0
	>,
	<
	    BUTTON_2,
	    mask SS_RSHIFT,
	    MSG_META_START_MOVE_COPY,
	    0
	>,
	<
	    BUTTON_2,
	    mask SS_LALT,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_MOVE
	>,
	<
	    BUTTON_2,
	    mask SS_RALT,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_MOVE
	>,
	<
	    BUTTON_2,
	    mask SS_LCTRL,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_COPY
	>,
	<
	    BUTTON_2,
	    mask SS_RCTRL,
	    MSG_META_START_MOVE_COPY,
	    mask UIFA_COPY
	>

Init ends

;----------------------

Build segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserAllocObjBlock

DESCRIPTION:	Allocate a block on the heap, to be used for holding UI
		objects.

CALLED BY:	EXTERNAL

PASS:
	bx - handle of thread to run block (0 for current thread)

RETURN:
	bx - handle of block

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

	To allocate an object block run by your process, use this code:

		call	GeodeGetProcessHandle	;returns bx = process handle
		call	ProcInfo		;returns bx = first thread han
		call	UserAllocObjBLock	;returns bx = memory handle

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	2/89		Initial version

------------------------------------------------------------------------------@


UserAllocObjBlock	proc	far	uses ax, cx, dx, si, di, bp
	.enter
	mov	si, bx				; Save thread to run block
	mov	ax, GEN_OBJ_BLOCK_INIT_SIZE	; for now, just 64 bytes
	mov	cx,ALLOC_DYNAMIC_NO_ERR or (mask HAF_LOCK shl 8) or mask HF_SHARABLE
	push	si, ds
	call	MemAlloc			; allocate the block
	mov	ds, ax				; set segment to block
	push	bx
	mov	ax,LMEM_TYPE_OBJ_BLOCK
	mov	cx, STD_INIT_HANDLES
	mov	dx, size ObjLMemBlockHeader
	mov	si, STD_INIT_HEAP
	mov	di, STD_LMEM_OBJECT_FLAGS
	clr	bp
	call	LMemInitHeap			; Initialize the heap
	pop	bx
	pop	si, ds

	call	MemUnlock			; Unlock it for now.

	tst	si				; See if current thread should
	jnz	UA_10				; be used -- skip if not.

						; Else get current thread
	mov	si,bx				; save memory handle
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx
	call	ThreadGetInfo
	mov	bx, ax
	xchg	bx,si				; bx = mem handle, si = thread
UA_10:
	mov	ax, si
	call	MemModifyOtherInfo

	.leave
	ret

UserAllocObjBlock	endp

Build ends

;----------------------

Exit segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserDetach -- MSG_META_DETACH for UserClass

DESCRIPTION:	This method commands the UI process to exit.  Before we
		can do that, we have to shut down all applications which 
		depend on us.  SO, we detach the system object & wait for
		an acknowledge, at which time we actually detach the UI
		process.

PASS:
	ds - dgroup of process
	es - segment of ui_ProcessClass

	ax - The method

	cx - caller's ID
	dx:bp	- OD to send MSG_META_ACK to when the UI has exited

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/89		Initial version

------------------------------------------------------------------------------@


UserDetach	method	UserClass, MSG_META_DETACH

	; If we haven't started detaching the system, do so now.
	;
	test	ds:[uiFlags], mask UIF_DETACHING_SYSTEM
	jz	notYetDetachingSystem

	; We've just received a second detach.  The question is this:  Is
	; this coming from the System object, asking the UI app to shutdown,
	; or just the result of multiple SysShutdown requests?
	; SysShutdown always passes Ack OD = NULL.   The same is true if
	; the user somehow exited the UI app via the "QUIT" mechanism.
	; In both these cases, we want to initiate a global system shutdown.
	; The system object, on the other hand, will always pass itself as
	; the Ack OD.  It's not incredibly pretty, but is a reliable way to
	; tell these cases apart.
	;
	tst	dx
	jz	done				; if Ack OD = NULL, just exit,
						; as there's nothing more that
						; can be done, & no place to
						; send an ACK to.  (App
						; shutdowns require an Ack OD)

	cmp	dx, ds:[uiSystemObj].handle	; If Ack OD = System object,
	jne	justAckSender			; start UI application shutdown.
	cmp	bp, ds:[uiSystemObj].chunk
	jne	justAckSender			; Otherwise, just "ACK" the
						; sender

if 0		; Removed 10/19/92: GenProcessClass has special code to
		; send an ACK rather than sending META_DETACH to the superclass
		; when it receives GEN_PROCESS_FINAL_DETACH on the UI thread.
		; This turns out to be what we really want to do, as the
		; GenSystem object will get the final ACK it needs and send
		; us an ACK back again, allowing us to finally finish shutting
		; down in UserAck -- ardeb

	; If it is the system object asking us to detach, the system object
	; will be history by the time this (the UI) process is ready to 
	; exit -- we won't actually be able to ACK it, so clear the source
	; now, before proceeding.  The sys object is aware of this, as
	; you fill find matching documentation in genSystem.asm noting that
	; this is the case.
	;
	clr	dx
	clr	bp
endif

	; If we haven't started detaching the application, do so now.
	;
	test	ds:[uiFlags], mask UIF_DETACHING_APP
	jz	notYetDetachingApp
	
justAckSender:
	; If we have, then just ack whoever the heck sent this message to us.
	;
	xchg	bx, dx				;^lBX:SI <- ACK OD
	xchg	si, bp
	mov	ax, MSG_META_ACK
	clr	di
	GOTO	ObjMessage

notYetDetachingApp:
						; Set flag to indicate the UI
						; is detaching itself as an app
	ornf	ds:[uiFlags], mask UIF_DETACHING_APP

	; & Ssend MSG_META_DETACH on to our superclass, GenProcessClass, to
	; cause it to start shutting down the UI application.
	;
	mov	di, segment UserClass
	mov	es, di
	mov	di, offset UserClass
	GOTO	ObjCallSuperNoLock

notYetDetachingSystem:
						; Set flag to indicate the UI
						; is detaching the system
	ornf	ds:[uiFlags], mask UIF_DETACHING_SYSTEM
						; Store ID & OD to send
						; MSG_META_ACK to later, when
						; UI process is gone.
	mov	ds:[uiAckID], cx
	movdw	ds:[uiAckOD], dxbp

if PLAY_STARTUP_SHUTDOWN_MUSIC
	; Play shutdown music.
	;
	push	ax, ds
	;---------------------------------------------------------------------
	;PLAY STARTUP MUSIC
	sub	sp, size GeodeToken
	segmov	es, ss
	mov	di, sp
	mov	ax, GGIT_TOKEN_ID
	mov	bx, handle 0
	call	GeodeGetInfo
	mov	cx, es
	mov	dx, di
	mov	bx, UIS_SHUTDOWN
	call	WavPlayInitSound
	add	sp, size GeodeToken
	pop	ax, ds

endif	; PLAY_STARTUP_SHUTDOWN_MUSIC

;done in GenFieldDetach
if 0
	;
	; put up exiting status box
	;
	push	ax
	mov	bx, handle UIApp
	mov	si, offset UIApp
	mov	cx, handle ShutdownStatusBox
	mov	dx, offset ShutdownStatusBox
	mov	ax, MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	mov	bx, handle ShutdownStatusBox
	mov	si, offset ShutdownStatusBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax
endif

	mov	dx, handle 0			; Pass ackOD as UI process
	clr	bp
	clr	cx				; No ID used
	call	UserCallSystem			; Force detach, by calling
						; system object
						; (Can't GOTO, as not in
						;  resident)

done:
	ret

UserDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserDetachAbort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the UIF_DETACHING flag

CALLED BY:	MSG_META_DETACH_ABORT
PASS:		ds = es	= dgroup
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserDetachAbort	method	UserClass, MSG_META_DETACH_ABORT
	andnf	ds:[uiFlags], not mask UIF_DETACHING_SYSTEM
	ret
UserDetachAbort	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	UserAck

DESCRIPTION:	Handle acknowledgement that the system object has finished
		detaching.

PASS:
	ds - dgroup of process
	es - segment of ui_ProcessClass

	ax - MSG_META_ACK

	cx - caller's ID
	dx:bp	- object finishing detach (Should be either the System object,
		  or the UI's GenApplication object)

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	12/89		Split out from MSG_META_DETACH

------------------------------------------------------------------------------@

UserAck	method	UserClass, MSG_META_ACK
	cmp	dx, ds:[uiSystemObj].handle
	jne	notSystemObject
	cmp	bp, ds:[uiSystemObj].chunk
	je	systemObjectAck
notSystemObject:

	cmp	dx, handle UIApp
EC <	ERROR_NZ	UI_PROCESS_UNKOWN_ACK_SOURCE			>
	cmp	bp, offset UIApp
EC <	ERROR_NZ	UI_PROCESS_UNKOWN_ACK_SOURCE			>

	; Pass ACK from app object on to superclass, GenProcessClass, to 
	; finish performing shutdown of application side of UI.
	;
	mov	di, offset UserClass
	CallSuper	MSG_META_ACK
	ret

systemObjectAck:
	mov	ds:[uiSystemObj].handle, -1	
	; Stop the screen saver

	mov	ax, MSG_IM_DISABLE_SCREEN_SAVER
	mov	di, mask MF_FORCE_QUEUE
	call	UserMessageIM

	; Remove the Screen code's Input Monitor
	call	UserScreenExit

	call	SysGetPenMode
	tst	ax
	jz	noPen
	call	ImEndPenMode
noPen:
	; Release our hold on some system exclusives, which we had set up
	; in MSG_META_ATTACH of the UI process.
	mov	bx, ds:[uiFlowObj].handle
	mov	si, ds:[uiFlowObj].chunk
	call	ImReleaseInput			; Release IM grab
	call	WinReleaseChange		; Release Window system grab

	; Free the specific UI we used earlier, but after queue has 
	; been flushed one more time, so that no more IM events are coming
	; through.
	mov	ax, MSG_USER_FREE_SPECIFIC_UI
	mov	cx, ds:[uiSpecUILibrary]	; specific UI to free
	mov	bx, handle 0			; send to ourselves
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

;	Free up the hwr library if necessary.

	clr	bx
	xchg	bx, ds:[hwrHandle]
	tst	bx
	jz	noHWRLib
	call	GeodeFreeLibrary
noHWRLib:
	

	;
	; Close down the Token database
	;
	call	TokenExitTokenDB

	;
	; Save out the current clipboard item
	;
	call	ClipboardCloseClipboardFile

if PLAY_STARTUP_SHUTDOWN_MUSIC
	;
	; If there was a shutdown sound playing, this will wait until it
	; exits.  Otherwise, this should do nothing.
	;
	call	WavLockExclusive
	call	WavUnlockExclusive
endif	; PLAY_STARTUP_SHUTDOWN_MUSIC


	; DO NOT send MSG_META_ACK to the superclass, since MetaClass will
	; try & handle this as if we'd called ObjInitDetach, which we HAVE NOT.
	; Instead, send MSG_META_DETACH *not* to our superclass, 
	; GenProcessClass, but rather, to its superclass "ProcessClass,"
	; which we didn't do earlier.  ProcessClass will send the
	; MSG_META_ACK for us.

					; Get ID & OD passed to MSG_META_DETACH
					; above.
	mov	cx, ds:[uiAckID]
	mov	dx, ds:[uiAckOD].handle
	mov	bp, ds:[uiAckOD].chunk
					; Send to superclass of GenProcessClass
					; It will flush the app queue with one
					; more method, then exit the thread.
					; (& send out MSG_META_ACK)
	mov	di, offset GenProcessClass
	mov	ax, MSG_META_DETACH
	CallSuper	MSG_META_DETACH
	ret	

UserAck	endm



COMMENT @----------------------------------------------------------------------

METHOD:		UserFreeSpecificUI

DESCRIPTION:	Frees up a specific UI library.  Undoes the UseLib we did
		at attach time.

PASS:
	*ds:si - instance data
	es - segment of ui_ProcessClass

	ax - MSG_USER_FREE_SPECIFIC_UI

	3cx	- specific UI to free
	dx, bp - ?

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
	Doug	1/90		Initial version

------------------------------------------------------------------------------@

UserFreeSpecificUI	method	UserClass, MSG_USER_FREE_SPECIFIC_UI
	; Free up specific UI library that we used earlier
	mov	bx, cx
	call	GeodeFreeLibrary		; Free up the specific UI
	ret
UserFreeSpecificUI	endm



COMMENT @----------------------------------------------------------------------

METHOD:		UserNotifyProcessExit -- MSG_PROCESS_NOTIFY_PROCESS_EXIT for
							UserClass

DESCRIPTION:	Notificatin of process exit

PASS:
	*ds:si - instance data
	es - segment of UserClass

	ax - The method

	cx - process handle

RETURN:
	carry - ?
	ax - ?
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	5/90		Initial version

------------------------------------------------------------------------------@

UserNotifyProcessExit	method dynamic	UserClass, MSG_PROCESS_NOTIFY_PROCESS_EXIT

	; send MSG_GEN_FIELD_PROCESS_EXIT to all generic children of the
	; system

	push	cx		;Save process handle
	mov	ax, MSG_GEN_FIELD_PROCESS_EXIT	; pass cx = process handle
	mov	bx, segment GenFieldClass	; class for method
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	;
	; We may want to change this later as MSG_GEN_FIELD_PROCESS_EXIT
	; returns carry set if it finds the process.  We can avoid sending
	; the method to the fields after the one with the process.  Currently,
	; the method is just sent to all fields, fields after the one where
	; the process is located will not find the process and so there is no
	; problem.  (Unless another process can start up and take the old
	; process handle and add itself to the field.)
	;
	mov	ax, MSG_GEN_SEND_TO_CHILDREN
	call	UserCallSystem
	pop	dx		;Restore process handle
	clr	bx				; destination class ignored
	mov	si, bx
	mov	ax, MSG_NOTIFY_APP_EXITED
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	cx, di				; cx = event handle
	clr	dx				; no extra data
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_APPLICATION
	clr	bp				; GCNListSendFlags
	call	GCNListSend
	ret
UserNotifyProcessExit	endm


COMMENT @----------------------------------------------------------------------

METHOD:		UserCreateNewStateFile --
		MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE for UserClass

DESCRIPTION:	Create state file for UI

PASS:
	*ds:si - instance data
	es - segment of UserClass

	ax - MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE method

	dx - AppLaunchBlock

	CurPath - set to state directory

RETURN:
	carry - ?
	ax - VM file handle (0 for no state file, or error creating)
	cx - ?
	dx - ?
	bp - ?

DESTROYED:
	bx, si, di, ds, es (method handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/13/92	Initial version

------------------------------------------------------------------------------@

UserCreateNewStateFile	method dynamic	UserClass, 
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE

	mov	ax, ds:[stateFileHandle]
	tst	ax				; have we got one already?
	jnz	done				; yes, use it

	clr	di				; clear tried-delete flag
tryCreate:
	mov	dx, offset stateFile		; ds:dx = name of state file
	mov	ax, (VMO_CREATE_ONLY shl 8) or \
			mask VMAF_USE_BLOCK_LEVEL_SYNCHRONIZATION or \
			mask VMAF_FORCE_DENY_WRITE
	clr	cx				; standard compaction threshold
	call	VMOpen				; bx = VM file handle
	jnc	creationOK
	;
	; handle disk full
	;	ax = error
	;	di = tried-delete flag
	;
	mov	si, offset outOfDiskSpaceStr1	; assume disk full error
	cmp	ax, VM_UPDATE_INSUFFICIENT_DISK_SPACE
	jz	error
	mov	si, offset cannotCreateFileStr1
	tst	di				; tried deleting yet?
	jnz	error				; yes, put up error message
	call	FileDelete			; else, try deleting
	inc	di				; indicate tried deleting
	jmp	short tryCreate			; and trying again

error:
	mov	bx, handle outOfDiskSpaceStr1
	call	MemLock
	mov	ds, ax

	mov	di, offset outOfDiskSpaceStr2
	cmp	si, offset outOfDiskSpaceStr1
	je	displayError
	mov	di, offset cannotCreateFileStr2
	call	UserCheckIfPDA
	jnc	displayError			; not PDA, use this error
	mov	di, offset cannotCreateFileStr2PDA	; else, this one
displayError:

	mov	si, ds:[si]
	mov	di, ds:[di]
	mov	ax, mask SNF_EXIT
	call	SysNotify
	call	MemUnlock
	clr	ax				; no state file
	ret			; <-- EXIT HERE ALSO

creationOK:
	;
	; successfully created new state file
	;	bx = VM file handle
	;
	mov	ax, bx				; return file handle in ax
done:
	.leave
	ret
UserCreateNewStateFile	endm

Exit ends

;----------------------

Resident segment resource



if	(AUTO_BUSY)

;---------------------------------------------------------------------------
;
;	Busy timer stuff
;
;---------------------------------------------------------------------------

DELAY_TO_UI_BUSY_PTR	= 40			; 1/60's of a second allowed
						; to pass before busy cursor
						; goes up



COMMENT @----------------------------------------------------------------------

FUNCTION:	UIBusyTimerRoutine

DESCRIPTION:	Handle time-out of busy timer -- check to see if UI thread
		is busy or not, & set ptr accordingly

CALLED BY:	INTERNAL

PASS:	cx:dx	system time

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Basically, we want to set the UI busy cursor if the UI will not be able
to respond to the user's input within a half second or so.  We clear the cursor
when the UI has nothing more to process & has an empty input queue.  The trick
is determing when the UI is "Busy".


KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	5/90		Initial version
------------------------------------------------------------------------------@

UIBusyTimerRoutine	proc	far	uses	ds
	.enter
	mov	ax, segment idata
	mov	ds, ax
	mov	ax, ds:[uiStack]		; Fetch segment of ui thread

	push	cx
	push	dx
	call	ThreadInfoQueue			; Find out when thread was
						; last dispatched
	mov	di, ax				; copy num events to di
	mov	ax, cx				; copy sys time to ax:bx
	mov	bx, dx
	pop	dx
	pop	cx

	cmp	ax, -1				; See if idle or running
	jne	running
	cmp	bx, -1
	jne	running
;idle:
	mov	ax, DELAY_TO_UI_BUSY_PTR+1	; time to next routine call
	jmp	short notBusy			; & branch -- set ptr not busy

running:
						; cx:dx is current time
	sub	dx, bx				; get elapsed time
	sbb	cx, ax
	tst	cx
	jnz	busy				; if > DELAY_TO_UI_BUSY_PTR,
	cmp	dx, DELAY_TO_UI_BUSY_PTR	; then change ptr image to be
	jae	busy				; busy.
	mov	ax, dx
	neg	ax
	add	ax, DELAY_TO_UI_BUSY_PTR+1	; figure out time remaing until
						; we would like to check again

						; Set ptr not busy
notBusy:
	clr	cx				; Clear ptr image to default
	clr	dx
	jmp	short setPtr

busy:
	mov	ax, DELAY_TO_UI_BUSY_PTR+1	; Start over.
	mov	cx, segment pBusy		; Set ptr image to BUSY
	mov	dx, offset pBusy

setPtr:
	push	ax				; Save new time delay
	mov	bp, PIL_FLOW			; Set UI/Flow level
	mov	ax, MSG_IM_SET_PTR_IMAGE	; with method sent to the
	call	ImInfoInputProcess
	mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
	call	ObjMessage
	pop	cx
						; cx = delay to timeout to use
	mov	ax, TIMER_ROUTINE_ONE_SHOT
	mov	bx, segment UIBusyTimerRoutine
	mov	si, offset UIBusyTimerRoutine
;	clr	dx				; timer data - not yet used
	call	TimerStart

	.leave
	ret
UIBusyTimerRoutine	endp


pBusy PointerDef <
	16,				; PD_width
	16,				; PD_height
	7,				; PD_hotX
	7				; PD_hotY
>

	byte	11111111b, 11111111b,
		11111111b, 11111111b,
		11111111b, 11111111b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		01111111b, 11111110b,
		11111111b, 11111111b,
		11111111b, 11111111b,
		11111111b, 11111111b,
		00000000b, 00000000b

	byte	11111111b, 11111111b,
		10000000b, 00000001b,
		11010111b, 11101011b,
		01010111b, 11101010b,
		01011000b, 00011010b,
		01011100b, 00111010b,
		01011110b, 01111010b,
		01011110b, 01111010b,
		01011100b, 00111010b,
		01011010b, 01011010b,
		01011010b, 01011010b,
		01010110b, 01101010b,
		11010000b, 00001011b,
		10000000b, 00000001b,
		11111111b, 11111111b,
		00000000b, 00000000b
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserUseLibrary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:Calls GeodeUseLibrary. This is mainly a hack, added because some
	libraries make calls to the UI thread (for example, the OL library does
	an ObjInstantiate, which calls the UI thread). The problem is that it
	makes this call while it has the Geode semaphore, and the UI can
	possibly be waiting on the semaphore, so we have a hot and juicy
	deadlock. This routine is added so we can load the library from the UI
	thread, and so avoid any of that nonsense.


CALLED BY:	GLOBAL
PASS:		ss:bp - pointer to UserUseLibraryFrame
RETURN:		if error:
			carry set
			ax - error code (GeodeLoadError)

		if no error:
			carry clear
			bp - handle of library

DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserUseLibrary	method	UserClass, MSG_USER_USE_LIBRARY
	mov	ax, SP_SYSTEM		; all libs currently in SYSTEM
	call	FileSetStandardPath

	mov	ax, ss:[bp].UULF_protocol.PN_major
	mov	bx, ss:[bp].UULF_protocol.PN_minor
	segmov	ds, ss
	lea	si, [bp].UULF_libname	;DS:SI <- file to load
	call	GeodeUseLibrary		;
	mov	bp,bx			;BP <- handle of library (if no error)
	ret
UserUseLibrary	endm



COMMENT @----------------------------------------------------------------------

METHOD:		UserLaunchApplication

DESCRIPTION:	Handler for remote request to UI to launch an application.
		This is in resident to minimize the amount of locked memory
		during this operation.

PASS:
	*ds:si - instance data

	ax - MSG_USER_LAUNCH_APPLICATION

	dx	- AppLaunchBlock specifying just what to do

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
	Doug	3/90		Initial version

------------------------------------------------------------------------------@

UserLaunchApplication	method	UserClass, \
					MSG_USER_LAUNCH_APPLICATION
	clr	ax		; Use data in AppLaunchBlock
	clr	cx		; Use data in AppLaunchBlock
	mov	si, -1		; Use data in AppLaunchBlock
	call	UserLoadApplication

	ret
UserLaunchApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserInvalTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate a window tree for KLib

CALLED BY:	KLib when error window comes down
PASS:		cx	= root window to invalidate. if 0, invalidate
			  current pointer root (TO BE USED ON RETURN FROM
			  A TASK SWITCH, ONLY).
		dx	= error window that came down
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; NOTE:  Placed in Resident to Prevent bogus disk swaps from SysNotify

UserInvalTree	method	UserClass, MSG_META_INVAL_TREE
		.enter
		jcxz	findRoot
inval:
		mov	si, cx		; Preserve root window
		mov	di, dx		; di <- error window
		;
		; Fetch the screen bounds of the error window, giving us
		; ax, bx, cx, and dx containing the rectangle for the window.
		;
		call	WinGetWinScreenBounds
		mov	di, si		; di <- root of tree to invalidate
		clr	bp		; Indicate area is rectangular and
		clr	si		;  not a region
		call	WinInvalTree
		.leave
		ret
findRoot:
	;
	; Refresh the pointer image in the video driver.
	; 
		mov	bp, -1
		call	ImSetPtrImage
	;
	; If a mouse driver be resident, force the video driver to display
	; the pointer image we just refreshed, since it will have made
	; the pointer hidden...
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		tst	ax
		jz	fetchPtrWin	; => no mouse driver, so don't
					;  do this...
	;
	; Force the pointer back on-screen.
	; 
		call	ImGetPtrWin
		call	GeodeInfoDriver
		push	ax, bx, cx, dx, si, di, bp
		mov	di, DR_VID_SHOWPTR
		call	ds:[si].DIS_strategy
		pop	ax, bx, cx, dx, si, di, bp
	;
	; Fetch the current pointer root and use it for both the root and
	; the error window.
	; 
fetchPtrWin:
		call	ImGetPtrWin
		mov	cx, di
		mov	dx, di
		jmp	inval
UserInvalTree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserInvalBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine invalidates the passed bounds on the passed
		window.

CALLED BY:	GLOBAL
PASS:		cx - root window to invalidate
		ss:bp - ptr to Rectangle structure (bounds to invalidate)
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UserInvalBounds	method	UserClass, MSG_META_INVAL_BOUNDS
	mov	di, cx			;DI <- window to invalidate
	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom
	clrdw	bpsi
	call	WinInvalTree
	ret
UserInvalBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserKeyClickRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process MSG_META_KBD_CHAR

CALLED BY:	im::ProcessUserInput

PASS:		al	= mask MF_DATA
		di	= event type
		MSG_META_KBD_CHAR:
			cx	= character value
			dl	= CharFlags
			dh	= ShiftState
			bp low	= ToggleState
			bp high = scan code
		MSG_IM_PTR_CHANGE:
			cx	= pointer X position
			dx	= pointer Y position
			bp<15>	= X-is-absolute flag
			bp<14>	= Y-is-absolute flag
			bp<0:13>= timestamp
		si	= event data
		ds 	= seg addr of monitor

RETURN:		al	= mask MF_DATA if event is to be passed through
			  0 if we've swallowed the event

DESTROYED:	ah, bx, ds, es (possibly)
		cx, dx, si, bp (if event swallowed)

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Click according to dgroup:[keyClickType].

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/17/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	ends


FlowCommon	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Route GWNT_HARD_ICON_BAR_FUNCTION mesages arriving here
		to Flow object, only to be able to pull off fake icon area.

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_META_NOTIFY

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FAKE_SIZE_OPTIONS
UserMetaNotify	method	UserClass, MSG_META_NOTIFY
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	callSuper
	cmp	dx, GWNT_HARD_ICON_BAR_FUNCTION
	je	callFlow
	cmp	dx, GWNT_STARTUP_INDEXED_APP
	jne	callSuper

	; Relay to flow object
callFlow:
	segmov	es, dgroup, di		; SH
	mov	bx, es:[uiFlowObj].handle
	mov	si, es:[uiFlowObj].chunk
	; Just drop the icon event if we are low on handles.
	;
	; We don't really need to force-queue the message, but if we don't,
	; MF_CAN_DISCARD_IF_DESPERATE won't actually check the free handle
	; threshold because the flow object is on the same thread and the
	; message is handled right away.  So here it is.
	;
	; Oh, now we want to check duplicate also.  So force-queue is required.
		CheckHack <segment FNCheckDuplicateHardIconEvent eq @CurSeg>
	push	cs			; ObjMessage is in a fixed segment ...
	mov	di, offset FNCheckDuplicateHardIconEvent
	push	di
	mov	di, mask MF_FORCE_QUEUE or mask MF_CAN_DISCARD_IF_DESPERATE \
			or mask MF_CHECK_DUPLICATE or mask MF_CUSTOM
	call	ObjMessage		; DO NOT use GOTO, since we're passing
					;  things on stack.
	ret

callSuper:
	mov	di, segment UserClass	; Call our superclass, which is the
	mov	es, di			; GenProcessClass,
	mov	di, offset UserClass
	GOTO	ObjCallSuperNoLock

UserMetaNotify	endm
endif

FlowCommon	ends

Password segment resource



COMMENT @----------------------------------------------------------------------

MESSAGE:	UserPromptForPassword --
		MSG_USER_PROMPT_FOR_PASSWORD for UserClass

DESCRIPTION:	Prompt for the password

PASS:
	*ds:si - instance data
	es - segment of UserClass

	ax - The message

RETURN:	nuthin'

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/23/93		Initial version
	ChrisT	3/24/95		Added Jedi mods
	stevey	5/30/95		rewrote jedi parts completely

------------------------------------------------------------------------------@


UserPromptForPassword	method dynamic	UserClass, MSG_USER_PROMPT_FOR_PASSWORD

SBCS <dateTimeBuffer	local	DATE_TIME_BUFFER_SIZE dup (char)	>
DBCS <dateTimeBuffer	local	DATE_TIME_BUFFER_SIZE/2 dup (wchar)	>
	.enter

	; only one password screen at a time, please

	tst	ds:[passwordActive]
	LONG jnz	done
	dec	ds:[passwordActive]

	; first check for a BIOS password

	clrdw	cxdx				;null buffer --
	call	VerifyBIOSPassword		;does password exist?
	jc	noBIOSPassword
	tst	ax
	jnz	throwUpDialog			;BIOS password exists but is
						;not set
noBIOSPassword:
	; no BIOS password, check the .ini file

	segmov	ds, cs
	mov	si, offset uiCategoryStr2
	mov	cx, cs
	mov	dx, offset passwordKeyStr
	clr	ax				;default value
	call	InitFileReadBoolean
	tst	ax
	LONG jz	doneNotActive

throwUpDialog::


	; put up the password screen

	mov	bx, handle UserPasswordDialog
	mov	si, offset UserPasswordDialog
	call	UserCreateDialog

	; stuff date into password screen

	push	bp

	push	si
	push	bx
	call	TimerGetDateAndTime	; ax = year, bl = month
					; bh = day, cl = day of week
	mov	dx, ss
	mov	es, dx
	lea	di, dateTimeBuffer
	mov	si, DTF_SHORT
	call	LocalFormatDateTime	; cx = size w/o null
	cmp	cx, MAX_PASSWORD_SOURCE_SIZE	; bigger than max?
	jbe	goodSize		; no, use full date
	mov	cx, MAX_PASSWORD_SOURCE_SIZE	; else, clip
goodSize:
	pop	bx
	lea	bp, dateTimeBuffer
	mov	si, offset GetPasswordDate
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	si

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage

	pop	bp

done:
	.leave
	ret

doneNotActive:

	call	NotifyPowerDriverPasswordOK
		
	mov	ax, dgroup
	mov	ds, ax
	clr	ds:[passwordActive]
	jmp	short done

UserPromptForPassword	endm

uiCategoryStr2		char	"ui", 0
passwordKeyStr		char	"password", 0
passwordTextKeyStr	char	"passwordText", 0
pwEncryptEnableKeyStr	char	"passwordEncrypt", 0





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyPowerDriverPasswordOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the power driver that the entered password is OK,
		or, perhaps, that none was needed.

CALLED BY:	UserPromptForPassword, UserPasswordEntered

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


NotifyPowerDriverPasswordOK	proc near
		uses	ax,bx,ds,si,di
		.enter
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver	; ax <- driver handle

		mov	bx, ax			; into bx for GeodeInfoDriver

		tst	bx			; quit if no power driver
		jz	done
		
		call	GeodeInfoDriver
		mov	di, DR_POWER_PASSWORD_OK
		call	ds:[si].DIS_strategy
done:
		.leave
		ret
NotifyPowerDriverPasswordOK	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UserIsPasswordDialogActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Tell whether the password dialog is on-screen

PASS:		*ds:si	- UserClass object
		ds:di	- UserClass instance data
		es	- dgroup

RETURN:		ax - TRUE if on-screen, FALSE otherwise

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/ 6/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


UserIsPasswordDialogActive	method	dynamic	UserClass, 
					MSG_USER_IS_PASSWORD_DIALOG_ACTIVE

		mov	al, ds:[passwordActive]
		cbw
		ret
UserIsPasswordDialogActive	endm



COMMENT @----------------------------------------------------------------------

FUNCTION:	VerifyBIOSPassword

DESCRIPTION:	Verify a password vs. the BIOS password

CALLED BY:	INTERNAL

PASS:
	cx:dx - password to compare (0 to compare against no password)

RETURN:
	carry - set if no BIOS password exists
	ax - non-zero if password does not match

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/26/93		Initial version

------------------------------------------------------------------------------@


	CheckHack <BIOS_PASSWORD_SIZE eq PASSWORD_ENCRYPTED_SIZE>

VerifyBIOSPassword	proc	near	uses bx, si, di, ds
	.enter

	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver
	tst	ax
	stc
	jz	done
	mov_tr	bx, ax
	call	GeodeInfoDriver
	mov	di, DR_POWER_VERIFY_PASSWORD
	call	ds:[si].DIS_strategy
done:
	.leave
	ret

VerifyBIOSPassword	endp

COMMENT @----------------------------------------------------------------------

MESSAGE:	UserPasswordEntered -- MSG_USER_PASSWORD_ENTERED for UserClass

DESCRIPTION:	Deal with the password being entered

PASS:
	*ds:si - instance data
	es - segment of UserClass

	ax - The message

	cx:dx - trigger

RETURN:

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/23/93		Initial version

------------------------------------------------------------------------------@


UserPasswordEntered	method dynamic	UserClass, MSG_USER_PASSWORD_ENTERED
uiBlock		local	word	push	cx
password	local	PASSWORD_ENCRYPTED_SIZE + 1 dup (char)
SBCS <entered		local	MAX_PASSWORD_SOURCE_SIZE + 1 dup (char)	>
DBCS <entered		local	MAX_PASSWORD_SOURCE_SIZE + 1 dup (wchar)>
SBCS <datePassword	local	MAX_PASSWORD_SOURCE_SIZE + 1 dup (char)	>
DBCS <datePassword	local	MAX_PASSWORD_SOURCE_SIZE + 1 dup (wchar)>
enteredHashed	local	PASSWORD_ENCRYPTED_SIZE dup (char)
	.enter


	; zero out the buffer we store the password in
	push	cx, es

	mov	dx, ss
	mov	es, dx
	lea	di, entered
	clr	ax
	mov	cx, size entered/2
	rep	stosw
if (size entered and 1)
	stosb
endif
	pop	cx, es

	; get the password entered
	mov	bx, cx
	mov	si, offset GetPasswordText
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	push	bp
	lea	bp, entered
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	; see if we encrypt it, or leave it as-is

	mov	cx, cs
	mov	ds, cx

	mov	si, offset uiCategoryStr2
	mov	dx, offset pwEncryptEnableKeyStr 
	call	InitFileReadBoolean
	segmov	ds, ss
	segmov	es, ss
	lea	si, entered
	lea	di, enteredHashed
	jc	encrypt

	tst	ax
	jnz	encrypt			; => FFFFh = TRUE

	mov	cx, size entered / 2
	rep	movsw
if (size entered and 1)
	movsb		; just incase it ever changes from 8...
endif
	jmp	short verifyPassword

encrypt:
	; encrypt the password

	call	UserEncryptPassword
	mov	si, offset MustEnterPasswordString
	LONG jnc	doneBadWithString

verifyPassword:

	; get the password from BIOS if it exists
	mov	cx, ss
	lea	dx, enteredHashed

	call	VerifyBIOSPassword
	jc	noBIOS

	tst	ax
	jmp	short compareDone

noBIOS:
	; no BIOS password, use the .ini file

	segmov	es, ss
	lea	di, password

	mov	cx, cs
	mov	ds, cx
	mov	si, offset uiCategoryStr2
	mov	dx, offset passwordTextKeyStr

	push	bx, bp
	mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
			(PASSWORD_ENCRYPTED_SIZE+1)
	call	InitFileReadString
	pop	bx, bp
	jc	doneGood

	; compare the passwords

	segmov	ds, ss
	segmov	es, ss
	lea	si, password
	lea	di, enteredHashed
	mov	cx, PASSWORD_ENCRYPTED_SIZE
	repe	cmpsb
	je	doneGood		; we have a match

	; get date to build secret date password

	mov	bx, uiBlock
	mov	si, offset GetPasswordDate
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	mov	dx, ss
	push	bp
	lea	bp, datePassword
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	bp

	; encrypt the secret date password

	segmov	ds, ss
	segmov	es, ss
	lea	si, datePassword

	lea	di, password
	call	UserEncryptPassword
	jnc	doneBad			; null date password?!?

	; compare the encrypted secret date password with the actual entered
	; password (non-encrypted)

	lea	si, password
	lea	di, entered
	mov	cx, PASSWORD_ENCRYPTED_SIZE
	repe	cmpsb

compareDone:
	jnz	doneBad

doneGood:
	mov	ax, dgroup
	mov	ds, ax
	clr	ds:[passwordActive]

	call	NotifyPowerDriverPasswordOK

	mov	si, offset UserPasswordDialog
	call	UserDestroyDialog


exit:
	.leave
	ret

doneBad:
	mov	si, offset PasswordErrorString
doneBadWithString:
	push	si
	mov	si, offset GetPasswordText
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	clr	di
	call	ObjMessage
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	clr	di
	call	ObjMessage
	pop	si

	push	bp		;save locals
	push	bx		;save string handle
	clr	ax
	push	ax		;finish message (none)
	pushdw	axax		;finish OD (none)
	pushdw	axax		;help context
	pushdw	axax		;custom triggers
	pushdw	axax		;string arg2
	pushdw	axax		;string arg1
;ugh -- this is pretty silly, but please update the '28' if you add pushes here
.assert (size GenAppDoDialogParams eq 28)
	call	MemLock		;lock string
	push	ds
	mov	ds, ax
	mov	si, ds:[si]
	pop	ds
	pushdw	axsi		;customString
	mov	ax, mask CDBF_SYSTEM_MODAL or \
			(CDT_ERROR shl offset CDBF_DIALOG_TYPE) or \
			(GIT_NOTIFICATION shl offset CDBF_INTERACTION_TYPE)
	push	ax
	mov	bp, sp
	mov	dx, size GenAppDoDialogParams
	mov	bx, handle UIApp
	mov	si, offset UIApp
	mov	di, mask MF_STACK
	mov	ax, MSG_GEN_APPLICATION_DO_STANDARD_DIALOG
	call	ObjMessage
	add	sp, size GenAppDoDialogParams
	pop	bx		;bx = string handle
	call	MemUnlock
	pop	bp		;restore locals
	jmp	exit

UserPasswordEntered	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	UserEncryptPassword

DESCRIPTION:	Encrypt a password (or other string)

CALLED BY:	INTERNAL

PASS:
	ds:si - text for password (null terminated)
	es:di - buffer for result (PASSWORD_ENCRYPTED_SIZE)
	Note: ds:si *cannot* be pointing to the movable XIP code resource.
RETURN:
	carry - set if non-null password given
	buffer - filled

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if password is null
		fill buffer with zeros
	else
		hash seed value = 0x43E809F1
		calculate hash value for password
		store hash value hex in buffer as hex dword (8 hex chars)

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/10/92		Initial version

------------------------------------------------------------------------------@

UserEncryptPassword	proc	far	uses ax, bx, cx, dx, di

if      FULL_EXECUTE_IN_PLACE
        ;
        ; Make sure the fptr passed in is valid
        ;
EC <    push  	bx                                          >
EC <    mov   	bx, ds	                                    >
EC <    call    ECAssertValidFarPointerXIP                  >
EC <    pop   	bx                                          >
endif
		
	.enter

	clr	ax
SBCS <	cmp	{char} ds:[si], al					>
DBCS <	cmp	{wchar} ds:[si], ax					>
	jnz	passwordExists

	mov	cx, PASSWORD_ENCRYPTED_SIZE
	rep	stosb
	clc
	jmp	done

passwordExists:
	movdw	cxdx, 0x43e809f1		;starting seed
	call	CalculateHash			;cxdx = hash value

	mov	bx, 8
nibbleLoop:
	clr	ax
	mov	al, ch
	shr	al
	shr	al
	shr	al
	shr	al
	add	al, '0'
	cmp	al, '9'
	jbe	10$
	add	al, 'a'-('0'+10)
10$:
	stosb

	shl	dx
	rcl	cx
	shl	dx
	rcl	cx
	shl	dx
	rcl	cx
	shl	dx
	rcl	cx

	dec	bx
	jnz	nibbleLoop
	stc
done:
	.leave
	ret

UserEncryptPassword	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateHash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the 32-bit ID for a string

CALLED BY:	(EXTERNAL)
PASS:		ds:si	= path whose ID wants calculating
		cxdx	= hash seed value
RETURN:		cxdx	= 32-bit ID
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	dword hashValue = cx:dx;
	TCHAR *path = ds:si;

	for (i=0; i<strlen(path); i++) {
		hashValue *= 33;
		hashValue += path[i];
	}
	return hashValue = cx:dx;

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CalculateHash proc	near	uses	ax, bx, si, di, bp
		.enter
		mov	bx, cx
		mov	cl, 5
SBCS <		clr	ah						>
charLoop:
		LocalGetChar ax, dssi
		LocalIsNull ax		; end of string?
		jz	done		; yes
	;
	; Multiply existing value by 33
	; 
		movdw	dibp, bxdx	; save current value for add
		rol	dx, cl		; *32, saving high 5 bits in low ones
		shl	bx, cl		; *32, making room for high 5 bits of
					;  dx
		mov	ch, dl
		andnf	ch, 0x1f	; ch <- high 5 bits of dx
		andnf	dl, not 0x1f	; nuke saved high 5 bits
		or	bl, ch		; shift high 5 bits into bx
		adddw	bxdx, dibp	; *32+1 = *33
	;
	; Add current character into the value.
	; 
		add	dx, ax
		adc	bx, 0
		jmp	charLoop		
done:
	;
	; Return ID in cxdx
	; 
		mov	cx, bx
		.leave
		ret

CalculateHash	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InstallRemovePasswordMonitor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install or remove the APM password monitor.

CALLED BY:	UserPromptForPassword, UserPasswordEntered

PASS:		cx = nonzero to install monitor, zero to remove

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	3/22/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


Password ends
