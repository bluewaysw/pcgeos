COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		setupMethod.asm

AUTHOR:		Adam de Boor, Oct  5, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/ 5/90	Initial revision


DESCRIPTION:
	Method handlers for the process class.
		

	$Id: setupProcess.asm,v 1.4 98/06/19 10:36:48 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupOpenApplication

DESCRIPTION:	

CALLED BY:	INTERNAL (MSG_GEN_PROCESS_OPEN_APPLICATION)

PASS:		

RETURN:		

DESTROYED:	

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

SetupOpenApplication	method	SetupClass, MSG_GEN_PROCESS_OPEN_APPLICATION

	;
	; Prevent loading of this app except via continueSetup = true
	; 
	push	ax,cx,dx,si
	mov	cx, dgroup
	mov	ds, cx
	mov	si, offset systemCatString
	mov	dx, offset continueSetupString
	call	InitFileReadBoolean	;ax <- -1 / 0
	inc	ax
	pop	ax,cx,dx,si
	je	noProblem

	;ds = dgroup
	call	SetupQuitAppl
	jmp	exit

noProblem:
	;
	; pass on to super class
	;
	mov	di, offset SetupClass
	call	ObjCallSuperNoLock

ifdef	GPC_VERSION
	;
	; Indicate that continuing setup is now running, so that if the user
	; power-cycles the machine without finishing setup (probably because
	; s/he can't see anything on the monitor screen), the UI lib will
	; know to switch back to the system default video mode.
	;
	mov	cx, dgroup
	mov	dx, offset continueSetupRunningString	; cx:dx = key
	mov	ds, cx
	mov	si, offset systemCatString	; ds:si = cat
	mov	ax, sp			;ax <- non-zero, TRUE
	call	InitFileWriteBoolean
	call	InitFileCommit		; need to flush to disk before the user
					;  powers off the system.

	;
	; Register ourselves with the power driver, so that we can tell it
	; not to suspend when the front-panel On/Off button is pressed.
	;
	mov	bx, POWER_ESC_ON_OFF_BUTTON_CONFIRM_REGISTER
	call	OnOffButtonConfirmRegUnreg	; ignore error
endif	; GPC_VERSION

	mov	ax, dgroup
	mov	ds, ax			;ds <- dgroup
	mov	es, ax			;es <- dgroup

	mov	ds:[mouseTested], 0

;
; Deal with serial/parallel port item enable/disable
;
	call	SetupInitSerial
	call	SetupInitParallel
EC<	call	CheckDSDgroup						>

;
; Find the dimensions of the current default video driver.
; 
	mov	ax, GDDT_VIDEO
  	call	GeodeGetDefaultDriver
	mov	bx, ax
	call	GeodeInfoDriver
	mov	es:[defaultVideo].offset, si
	mov	es:[defaultVideo].segment, ds
	
	mov	ax, ds:[si].VDI_pageW
	mov	es:[screenW], ax
	mov	ax, ds:[si].VDI_pageH
	mov	es:[screenH], ax
	
	segmov	ds, dgroup, ax		; ds <- dgroup again

	;----------------------------------------------------------------------
	;set max int level

	call	SysGetConfig		;al <- SysConfigFlags
	test	al, mask SCF_2ND_IC
	mov	cx, 7			;max int level = 7 if 1IC
	je	maxGotten
	mov	cx, 15			;max int level = 15 if 2IC

maxGotten:
	mov	bx, handle MouseIntRange
	mov	si, offset MouseIntRange
	push	cx
	call	SetRangeMax		;destroys ax,dx,bp,di
	pop	cx
;	mov	bx, handle PrinterSerialIntRange
;	mov	si, offset PrinterSerialIntRange
;	call	SetRangeMax

EC<	call	CheckDSDgroup						>

	;
	; setup the UI screen
	;
	mov	ax, MSG_PREF_INIT
	mov	si, offset UISelectList
	mov	bx, handle UISelectList
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	ax, MSG_META_LOAD_OPTIONS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;
	;----------------------------------------------------------------------
	;mode specified?

	mov	si, offset systemCatString
	mov	cx, ds
	mov	dx, offset setupModeString
	call	InitFileReadInteger
	jc	fullSetup
	
	mov	ds:[mode], ax
	
	shl	ax
	xchg	si, ax
	jmp	cs:modeTable[si]
modeTable	nptr	fullSetup,
			afterVideoChange,
			afterPMVideoChange,
			afterPMMouseChange,
			afterSetupVideoChange,
			afterSetupMouseChange,
			afterSetupUIChange,
			upgradeUIChange

CheckHack <length modeTable eq SetupMode>
	
	;----------------------------------------------------------------------
afterPMMouseChange:
	mov	si, offset MouseTestScreen
	mov	bx, handle MouseTestScreen
	jmp	initiateInitialScreen


	;----------------------------------------------------------------------
afterPMVideoChange:
	;
	; Load the mouse driver first.
	;
	mov	ax, MSG_SETUP_LOAD_MOUSE_DRIVER
	mov	bx, handle 0
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	;- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
afterVideoChange:
	;
	; Now bring up the first screen of the video test with the revert
	; option.
	;
	mov	si, offset VideoTestRevertScreen
	mov	bx, handle VideoTestRevertScreen
	jmp	initiateInitialScreen

	;----------------------------------------------------------------------
afterSetupVideoChange:
	mov	ax, MSG_SETUP_LOAD_MOUSE_DRIVER
	mov	bx, handle 0
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	
	mov	si, offset VideoTestScreen
	mov	bx, handle VideoTestScreen
	jmp	initiateInitialScreen

	;----------------------------------------------------------------------
upgradeUIChange::
afterSetupUIChange:
	mov	si, offset UISelectScreen
	mov	bx, handle UISelectScreen
	jmp	initiateInitialScreen

	;----------------------------------------------------------------------
afterSetupMouseChange:
	mov	si, offset MouseSelectScreen
	mov	bx, handle MouseSelectScreen
	jmp	initiateInitialScreen

;;; afterPrinterSelectChange: .....

	;----------------------------------------------------------------------
fullSetup:
	;HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK
	;To make Preferences happy later on, adjust the keyboard::device
	;string to match that stored in the current keyboard driver.
	;HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK HACK

	mov	ax, GDDT_KEYBOARD
	call	getFirstDevice			; es:di <- 1st device string
	mov	dx, offset deviceKeyString	; cx:dx <- key string
	segmov	ds, dgroup, cx
	mov	si, offset keyboardCatString	; ds:si <- category
	call	InitFileWriteString
	call	MemUnlock

	;END OF HACK END OF HACK END OF HACK END OF HACK END OF HACK END OF HACK

	;
	; 2/12/98: If there is no video driver specified in GEOS.INI,
	; set the string manually for telling the user what has been
	; selected for their display. -- eca
	;
	; See if we've got something in [screen0] already
	;
	push	bp
	mov	cx, ds
	mov	dx, offset deviceKeyString	;cx:dx <- key [device]
	mov	si, offset videoCatString	;ds:si <- category [screen0]
	clr	bp				;bp <- InitFileReadFlags
	call	InitFileReadString
	jnc	afterVideoFree			;branch if [screen0] exists
	;
	; There's nothing in GEOS.INI -- grab the 1st device name
	; and write it out
	;
	mov	ax, GDDT_VIDEO
	call	getFirstDevice			;es:di <- 1st device string
	mov	cx, ds				;cx:dx <- key [device]
	call	InitFileWriteString
	call	MemUnlock
afterVideo:
	pop	bp

	mov	si, offset IntroScreen
	mov	bx, handle IntroScreen

initiateInitialScreen:
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	clr	di
	call	ObjMessage

exit:
	ret

	;
	; There's something in GEOS.INI -- just proceed
	;
afterVideoFree:
	call	MemFree				;free GEOS.INI string
	jmp	afterVideo

getFirstDevice:
	push	ds, si
	call	GeodeGetDefaultDriver		; find keyboard driver
	mov_trash	bx,  ax
	call	GeodeInfoDriver			; get extended info struct
	mov	bx, ds:[si].DEIS_resource
	call	MemLock		; Lock down the table
	mov	ds, ax
	mov	si, ds:[DEIT_nameTable]		; ds:si <- name table
	mov	si, ds:[si]			; *ds:si <- first name
	mov	di, ds:[si]			; es:di <- first name
	mov	es, ax
	pop	ds, si
	retn
SetupOpenApplication	endm

ifdef	GPC_VERSION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unregister ourselves with the power driver.

CALLED BY:	MSG_GEN_PROCESS_CLOSE_APPLICATION

PASS:		nothing
RETURN:		cx	= 0 (no extra state block)
DESTROYED:	ax, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	5/24/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupCloseApplication	method dynamic SetupClass, 
					MSG_GEN_PROCESS_CLOSE_APPLICATION

	;
	; Unregister ourselves with the power driver.
	;
	mov	bx, POWER_ESC_ON_OFF_BUTTON_CONFIRM_UNREGISTER
	call	OnOffButtonConfirmRegUnreg	; ignore error

	clr	cx			; no extra state block

	ret
SetupCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OnOffButtonConfirmRegUnreg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Register/Unregister on-off button confirm callback with the
		power driver.

CALLED BY:	INTERNAL
PASS:		bx	= POWER_ESC_ON_OFF_BUTTON_CONFIRM_REGISTER/UNREGISTER
RETURN:		CF clear if function supported
			ax	= non-zero if too many callbacks registered
		CF set if driver not present or function not supported
DESTROYED:	ax, bx, cx, dx, si, di, ds
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/12/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OnOffButtonConfirmRegUnreg	proc	near

	mov	ax, GDDT_POWER_MANAGEMENT
	call	GeodeGetDefaultDriver	; ax = driver handle
	tst	ax
	stc				; assume not present
	jz	afterRegister		; => driver not present
	xchg	bx, ax			; bx = driver handle, ax =
					;  PowerEscCommand
	call	GeodeInfoDriver		; ds:si = DriverInfoStruct
	mov	di, DR_POWER_ESC_COMMAND
	mov	bx, si			; ds:bx = DriverInfoStruct
	mov_tr	si, ax			; si = PowerEscCommand
	mov	dx, vseg SetupOnOffButtonConfirmCB
	mov	cx, offset SetupOnOffButtonConfirmCB
	call	ds:[bx].DIS_strategy

afterRegister:
	ret
OnOffButtonConfirmRegUnreg	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupOnOffButtonConfirmCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell power driver we deny suspend, then revert video mode.

CALLED BY:	(GLOBAL) Power driver
PASS:		nothing
RETURN:		CF set (deny suspend)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ayuen	10/12/00    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupOnOffButtonConfirmCB	proc	far
	pusha

	;
	; Revert video mode.
	;
	mov	bx, handle 0
	mov	ax, MSG_SETUP_REVERT_VIDEO
	clr	di
	call	ObjMessage

	stc				; deny suspend

	popa
	ret
SetupOnOffButtonConfirmCB	endp

endif	; GPC_VERSION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE so we don't
		create a state file, we never being able to restore
		from state...

CALLED BY:	MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
PASS:		nothing of interest to us
RETURN:		ax	= 0 (no state file, thanks)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 3/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupCreateNewStateFile	method	SetupClass,
					MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		clr	ax
		ret
SetupCreateNewStateFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupReenterGEOS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go back to running GEOS normally.

CALLED BY:	MSG_SETUP_REENTER_GEOS
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	process...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupReenterGEOS method	SetupClass, MSG_SETUP_REENTER_GEOS
		.enter
	;
	; Already doing this? If so, don't do it again, silly.
	; 
		mov	al, BB_TRUE
		xchg	al, ds:[reenteringGEOS]
		tst	al
		jnz	done
	;
	; Tell the ui to load things normally.
	;
		mov	ax, MSG_USER_CONTINUE_STARTUP
		mov	bx, handle ui
		mov	di, mask MF_CALL
		call	ObjMessage
	;
	; Don't run us next time, thanks.
	;
		call	SetupClearContinueSetup
	;
	; Get rid of any saved video state so as not to clutter the ini file.
	;
		call	PrefDiscardSavedVideo
	;
	; And shut ourselves down.
	;
		call	SetupQuitAppl
done:
		.leave
		ret
SetupReenterGEOS endp

COMMENT @----------------------------------------------------------------------

METHOD:		SetupGenerateSysInfo -- MSG_SETUP_GENERATE_SYS_INFO
					for SetupClass

DESCRIPTION:	Generate the sysinfo file if the mode is appropriate

PASS:
	*ds:si - instance data
	es - segment of SetupClass

	ax - The method

RETURN:

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

SetupGenerateSysInfo	method dynamic	SetupClass,
					MSG_SETUP_GENERATE_SYS_INFO

	cmp	ds:[mode], MODE_FULL_SETUP
	jz	doIt
	cmp	ds:[mode], MODE_AFTER_VIDEO_CHANGE
	jnz	done
doIt:
	call	SysInfoGenerateFile
done:
	ret

SetupGenerateSysInfo	endm
