COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	Jedi
MODULE:		Startup
FILE:		jsProcess.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/26/93   	Initial version.

DESCRIPTION:
	

	$Id: jsProcess.asm,v 1.1 97/04/04 16:53:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load the mouse driver, if it's not already loaded.

PASS:		ds	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/26/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

mouseCatString char MOUSE_CATEGORY, 0

JSProcessOpenApplication	method	dynamic	JSProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
		uses	ax,cx,dx,bp,ds,es
		.enter
	;
	;  Okay.  They want the default date to be 1-1-95.
	;  our command.com doesn't have the date-set capability
	;  of a regular command.com, so we need to do it explicitly
	;  on startup.  I know.  It sucks.  It works.
	;			-- todd 06/15/95
	;
		mov	ax, 1995			; ax <- 1995
		mov	bl, 1				; bl <- January
		mov	bh, bl				; bh <- 1st
		clr	dx				; 00.00 minutes
		mov	ch, dl				; 12am
		mov	cl, mask SDTP_SET_DATE or mask SDTP_SET_TIME
		call	TimerSetDateAndTime	; ax, bx, cx, dx destroyed

if 0		; turned off for Leia project 01/19/96
	;
	; Set the default touch screen status to off.
	;
		mov	dx, JEDI_TOUCH_ON_DISABLE
		mov	al, JEDI_TOUCH_ON_CMOS_ADDRESS
		mov	cx, JEDI_TOUCH_ON_MASK
		call	JSWriteCMOSWord
endif

	;
	;  Do we have a mouse driver?
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		tst	ax
		jnz	done
	;
	;  Get a mouse driver.
	;
		segmov	ds, cs
		mov	si, offset mouseCatString
		mov	ax, SP_MOUSE_DRIVERS
		clr	cx, dx				; Expected
							; protocol number?
FXIP<		call	SysCopyToStackDSSI				>
		call	UserLoadExtendedDriver	; bx <- handle
						; cx, dx, di, si destroyed
FXIP<		call	SysRemoveFromStack				>
EC <		ERROR_C -1						>
		mov	ax, GDDT_MOUSE
		call	GeodeSetDefaultDriver

		mov	ax, GDDT_VIDEO
		call	GeodeGetDefaultDriver

		mov_tr	bx, ax
		call	GeodeInfoDriver
		mov	di, DR_VID_SHOWPTR
		call	ds:[si].DIS_strategy
done:
	;
	; Tell the mouse driver to ignore the hard icons for now.
	;
		call	CheckEmulation			; cf clear if emulating
		jnc	doneHardIcons

		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver		; ax = handle
		mov_tr	bx, ax
		call	GeodeInfoDriver
		mov	di, DR_MOUSE_START_CALIBRATION
		call	ds:[si].DIS_strategy
doneHardIcons:
if 0
	;
	;  Put up calibration screen.
	;
		mov	ax, MSG_JS_PRIMARY_DO_CALIBRATION
		mov	bx, handle MyJSPrimary
		mov	si, offset MyJSPrimary
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
endif
if _CITY_LIST
	;
	; Set the viewpt of the city list.
	;
		call	JWTDatabaseInit
		call	JWTDatabaseSetAllViewpt
	;
	; See how many cities are in the viewpt.
	;
		call	JWTDatabaseGetViewptRecordCount		; cx <- count
        ;
        ; Tell out dynamic list of cities, how many things are in the
        ; city list.
        ;
                mov     ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		clr	di
                mov     bx, handle JCityList
                mov     si, offset JCityList
		call    ObjMessage

        ;
        ; Find out what the local city is so we can make it the selection
        ;
                call    JWTDatabaseGetLocalCity         ; cx <- selection
        ;
        ; Find out what the viewpt record is so we know which entry to
        ; highlight
        ;
		call    JWTDatabaseGetViewptRecordNumber
						; cx <- viewpt number
  
        ;
	; Set the new selection. and tell it to send it's apply
	; message once so the header of the list is updated.
        ;
                clr     dx
                mov     ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
                mov     bx, handle JCityList
                mov     si, offset JCityList
		clr	di
                call    ObjMessage

		mov	ax, MSG_GEN_APPLY
		clr	di
;;		call	ObjMessage
endif ; _CITY_LIST

	call	JSPInitiateDaylightSavingsTransitionMechanism
	
	;
	; Call superclass LAST, so the calibration stuff isn't on
	; screen before we've loaded the mouse driver.  Pretty weak
	; syncronization, but
	;
		.leave
		mov	di, offset JSProcessClass
		GOTO	ObjCallSuperNoLock
JSProcessOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSWriteCMOSWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a word to CMOS

CALLED BY:	(INTERNAL) JSProcessOpenApplication

PASS:		al	-> address of cmos
		cx	-> mask of cmos to clear
		dx	-> bit value to write to cmos

RETURN:		carry set on error

DESTROYED:	ax, bx, cx

SIDE EFFECTS:
		Locks/Unlock BIOS
		Changes one word of CMOS data

PSEUDO CODE/STRATEGY:
		** Must be called with interrupts on **

		Grab BIOS exclusive
		Turn off interrupts

		read the current CMOS word
		not the mask
		and the mask with current CMOS value
		or the new value into old value
		write the result to CMOS
		Turn on interrupts
		Release BIOS exclusive

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/29/93    	Initial version (JediUtilWriteCMOSWord)
	cthomas	2/24/95		Stolen from bullet power driver for Jedi
	AY	8/17/95		Copied from JPref to here (JSWriteCMOSWord)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 0	; removed for Leia	01/19/96
	.ioenable

JSWriteCMOSWord	proc	far

	call	SysLockBIOS

	INT_OFF					; turn off interrupts

	mov	ah, JEDI_BIOS_READ_CMOS_WORD
	not	cx				; not the mask
	and	bx, cx				; zero selected bits
	or	bx, dx				; set new bit values

	; Commit AFTER writing
	;

	mov	ah, JEDI_BIOS_WRITE_CMOS_WORD

done::
	INT_ON					; turn on interrupts

	GOTO	SysUnlockBIOS

JSWriteCMOSWord	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSProcessCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure no state file is generated.

PASS:		ds	= dgroup

RETURN:		ax = 0

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

SIDE EFFECTS:	nukes any state file that the superclass creates

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

JSProcessCreateNewStateFile	method dynamic JSProcessClass, 
				MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		clr	ax
		ret
JSProcessCreateNewStateFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Tell the UI to continue startup.

PASS:		ds	= dgroup

RETURN:		nothing
DESTROYED:	all 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/30/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	uiFeaturesString	char "uiFeatures", C_NULL
	defaultLauncherString	char "defaultLauncher", C_NULL

EC<	homeScreenString	char "EC Home Screen", C_NULL	>
NEC<	homeScreenString	char "Home Screen", C_NULL	>

JSProcessCloseApplication	method	dynamic	JSProcessClass, 
				MSG_GEN_PROCESS_CLOSE_APPLICATION
	;
	;  Write the continueStartup = false flag.
	;
		mov	cx, cs
		mov	ds, cx
		mov	si, offset systemString
		mov	dx, offset continueKey
		clr	ax				; FALSE
		call	InitFileWriteBoolean
	;
	;  Change default launcher to be HomeScreen.
	;
		push	es
		mov	es, cx
		mov	si, offset uiFeaturesString
		mov	dx, offset defaultLauncherString
		mov	di, offset homeScreenString
		call	InitFileWriteString
		pop	es
	;
	; Turn the hard icons back on
	;
		call	CheckEmulation
		jnc	doneHardIcons

		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver		; ax = handle
		mov_tr	bx, ax
		call	GeodeInfoDriver
		mov	di, DR_MOUSE_STOP_CALIBRATION
		call	ds:[si].DIS_strategy
doneHardIcons:
	;
	; Continue the rest of setup
	;
		mov	ax, MSG_USER_CONTINUE_STARTUP
		mov	bx, handle ui
		clr	di
		call	ObjMessage
if _CITY_LIST
	;
	; We don't need to use the city database anymore.
	; Let it go.
	;
		call	JWTDatabaseExit
endif
	;
	; Return no state block, not that it matters...
	;
		clr	cx
		ret

systemString char "system",0
continueKey char "continueSetup",0		

JSProcessCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckEmulation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if we're emulating on a PC

CALLED BY:	
PASS:		nothing
RETURN:		carry set if not emulating, 
		carry clear if emulating
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

systemCatString1	char	"system", C_NULL
emulationKey1		char	"PCEmulation", C_NULL

CheckEmulation	proc	far
		uses	cx, dx, ds, si, ax
		.enter
	;
	; Read PCEmulation key from ini file
	;
		mov	cx, cs
		mov	dx, offset emulationKey1	; cx:dx = emulationKey
		mov	ds, cx
		mov	si, offset systemCatString1	; ds:si = category
		clr	ax			; default to FALSE
		call	InitFileReadBoolean	; rtn ax=TRUE/FALSE, CF
		jc	done
		cmp	ax, BW_TRUE             ; CF set if ax == FALSE
done:
		.leave
		ret
CheckEmulation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSPSetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current date when sent by the date gadget

CALLED BY:	MSG_JSP_SET_DATE

PASS:		cx	= year
		dl	= month
		dh	= day of month
		bp	= day of week

RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	1/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSPSetDate	method dynamic JSProcessClass, 	MSG_JSP_SET_DATE
		.enter
if 0
	;
	; Kernel can't handle dates before 1980.
	;
		cmp	cx, 1980
endif
	;
	; BIOS can't handle dates before 1992 -- it wins :)
	;
		cmp	cx, 1992
		jb	reset
	;
	; Set new date -- notifies GCN list.
	;
		mov_tr	ax, cx			; year
		mov	bx, dx			; month, day
		mov	cl, mask SDTP_SET_DATE
		call	TimerSetDateAndTime
done:
		.leave
		ret
reset:
	;
	; Set the date gadget's date back to system time
	;
		mov	ax, SST_ERROR
		call	UserStandardSound

		mov	ax, MSG_DATE_INPUT_SET_CURRENT_DATE
		mov	bx, handle DateGadget
		mov	si, offset DateGadget
		clr	di
		call	ObjMessage

		jmp	done

JSPSetDate	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSPSetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets system time when sent by 

CALLED BY:	MSG_JSP_SET_TIME

PASS:		ch - hours
		dl - minutes
		dh - seconds

RETURN:		nothing
DESTROYED:	all

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	1/11/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
JSPSetTime	method dynamic JSProcessClass, 	MSG_JSP_SET_TIME
		.enter

		clr	dh
		mov	cl, mask SDTP_SET_TIME
		call	TimerSetDateAndTime

		.leave
		ret
JSPSetTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		JSPInitiateDaylightSavingsTransitionMechanism
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine opens the WorldTime application in engine mode
   		via IACP and sends it a message that will initiate the
   		daylight savings transition mechanism.

CALLED BY:	JSProcessOpenApplication
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PB	5/10/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

serverAppToken	GeodeToken	<"WTIM",MANUFACTURER_ID_GEOWORKS>

JSPInitiateDaylightSavingsTransitionMechanism	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter
	
   ; Create a launch block to pass to IACPConnect
   ; --------------------------------------------
	mov	dx, MSG_GEN_PROCESS_OPEN_ENGINE
	call	IACPCreateDefaultLaunchBlock	; dx = handle to AppLaunchBlock
		
   ; Clear launch flags 
   ; ------------------
	mov	bx, dx				; bx <- handle of AppLaunchBlock
	call	MemLock				; ax = AppLaunchBlock segment
	mov	es, ax
	mov	es:[ALB_launchFlags], mask ALF_OPEN_FOR_IACP_ONLY
	call	MemUnlock

   ; Connect to the desired server
   ; -----------------------------
	mov	di, offset cs:[serverAppToken]
	segmov	es, cs, dx			; es:di points to GeodeToken
	mov	ax, mask IACPCF_FIRST_ONLY	; ax <- connect flag
	call	IACPConnect			; bp = IACPConnection
	jc	done

   ; Package parameters and message to send
   ; --------------------------------------
	push	bp				; set aside IACPConnection
	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, JNT_INITIATE_DAYLIGHT_SAVINGS_TRANSITION_MECHANISM
	clr	bx, si
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = handle of msg to send
	pop	bp				; restore IACPConnection

   ; Send the message 
   ; ----------------
	clr	cx				; cx <- no completion msg
	mov	bx, di				; bx <- handle of msg to send
	mov	dx, TO_PROCESS			; set TravelOption
	mov	ax, IACPS_CLIENT		; side sending
	call 	IACPSendMessage
	
   ; Shut down connection
   ; --------------------
	clr	cx, dx
	call	IACPShutdownAll

done:
	.leave
	ret
JSPInitiateDaylightSavingsTransitionMechanism	endp
