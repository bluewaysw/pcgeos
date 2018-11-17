COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		bsProcess.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/26/93   	Initial version.

DESCRIPTION:
	

	$Id: bsProcess.asm,v 1.1 97/04/04 16:53:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSProcessOpenApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Load the mouse driver, if it's not already loaded.

PASS:		ds, es - dgroup

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

mouseCatString char MOUSE_CATEGORY,0

BSProcessOpenApplication	method	dynamic	BSProcessClass, 
					MSG_GEN_PROCESS_OPEN_APPLICATION
		uses	ax,cx,dx,bp,ds,es
		.enter

		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		tst	ax
		jnz	done

		segmov	ds, cs
		mov	si, offset mouseCatString
		mov	ax, SP_MOUSE_DRIVERS
		clr	cx, dx				; Expected
							; protocol number?
		call	UserLoadExtendedDriver
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
	; Tell the mouse driver to ignore the hard icons for now
	;
		mov	di, DR_MOUSE_START_CALIBRATION
		call	BSSetHardIconsOnOff
	;
	; Call superclass LAST, so the calibration stuff isn't on
	; screen before we've loaded the mouse driver.  Pretty weak
	; syncronization, but
	;
		.leave
		mov	di, offset BSProcessClass
		GOTO	ObjCallSuperNoLock
BSProcessOpenApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSProcessCreateNewStateFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure no state file is generated.

PASS:		ds, es - dgroup

RETURN:		ax = 0

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

SIDE EFFECTS:	nukes any state file that the superclass creates

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	8/ 6/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSProcessCreateNewStateFile	method dynamic BSProcessClass, 
				MSG_GEN_PROCESS_CREATE_NEW_STATE_FILE
		clr	ax
		ret
BSProcessCreateNewStateFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSProcessCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Tell the UI to continue startup.

PASS:		*ds:si	- BSProcessClass object
		ds:di	- BSProcessClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/30/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSProcessCloseApplication	method	dynamic	BSProcessClass, 
				MSG_GEN_PROCESS_CLOSE_APPLICATION
	;
	; Turn the hard icons back on
	; 
		mov	di, DR_MOUSE_STOP_CALIBRATION
		call	BSSetHardIconsOnOff
	;
	; Continue the rest of setup
	;
		mov	ax, MSG_USER_CONTINUE_STARTUP
		mov	bx, handle ui
		clr	di
		call	ObjMessage
	;
	; Return no state block, not that it matters...
	;
		clr	cx
		ret
BSProcessCloseApplication	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSetHardIconsOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable or enable the use of the hard icons

CALLED BY:	INTERNAL

PASS:		DI	= DR_MOUSE_START_CALIBRATION (ignore hard icons) or
			  DR_MOUSE_STOP_CALIBRATION (stop ignoring hard icons)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/30/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; this goes under the [system] category
systemCatString1	char	"system", C_NULL
emulationKey1	char	"bstartupPCEmulation", C_NULL

BSSetHardIconsOnOff	proc	near
		uses	ax, bx, cx, dx, di, si, bp, ds
		.enter
	
	;
	; Don't call mouse driver if we are running PC emulation of bullet,
	; because for genmouse driver there are no MouseStartCalibration
	; and MouseStopCalibration routines defined, hence no such entries
	; in mouseHandlers table.  --- AY 11/15/93
	;
		mov	cx, cs
		mov	dx, offset emulationKey1	; cx:dx = emulationKey
		mov	ds, cx
		mov	si, offset systemCatString1	; ds:si = category
		clr	ax			; default to FALSE
		call	InitFileReadBoolean	; rtn ax=TRUE/FALSE, CF
		tst	ax
		jnz	done			; jump if running PC emulation
	;
	;  Tell the pen driver we're done calibrating.
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		mov_tr	bx, ax
		call	GeodeInfoDriver
		call	ds:[si].DIS_strategy
done:
		.leave
		ret
BSSetHardIconsOnOff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSAppStartEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Catch all messages listed below, and forward them to the
		approrpriate object, to ensure all points are the screen
		are recognized.

CALLED BY:	GLOBAL (MSG_META_[START, END]_SELECT)

PASS:		ES	= DGroup
		AX	= Message
		CX,DX,BP= Data

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/30/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSAppStartEndSelect	method dynamic	BSApplicationClass,
					MSG_META_START_SELECT,
					MSG_META_END_SELECT
	;
	; If on the Date & Time screen, let the system handle it
	;
		cmp	es:[doingSomething], DS_DATE_TIME
		jne	doForward
		mov	di, offset BSApplicationClass
		GOTO	ObjCallSuperNoLock
	;
	; Forward the message to the correct object
	;
doForward:
		mov	bx, handle BSWelcomeContent
		mov	si, offset BSWelcomeContent
		cmp	es:[doingSomething], DS_WELCOME
		je	forwardMessage
		mov	bx, handle ScreenVisScreen
		mov	si, offset ScreenVisScreen
forwardMessage:
		mov	di, mask MF_CALL
		GOTO	ObjMessage

BSAppStartEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSCheckCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the pen is calibrated

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		Carry	= Clear if pen is calibrated
			= Set if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/ 7/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BSCheckCalibration	proc	far
		uses	ax, cx, dx, si, ds
		.enter
	
		segmov	ds, cs, cx
		mov	si, offset calibrateCategory	; ds:si = category
		mov	dx, offset calibrateKey	; cx:dx = string
		clr	ax			; assume FALSE
		call	InitFileReadBoolean
		cmp	ax, TRUE		; pen calibrated?
		je	done			; yes, and carry is clear
		stc
done:
		.leave
		ret
BSCheckCalibration	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BSSetCalibration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the calibration to be TRUE or FALSE

CALLED BY:	GLOBAL

PASS:		AX	= TRUE or FALSE

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/ 7/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

calibrateCategory	char	"system",0
calibrateKey		char	"penCalibrated",0

BSSetCalibration	proc	far
		uses	cx, dx, si, ds
		.enter
	
		segmov	ds, cs, cx
		mov	si, offset calibrateCategory	; ds:si = category
		mov	dx, offset calibrateKey	; cx:dx = string
		call	InitFileWriteBoolean
		call	InitFileCommit

		.leave
		ret
BSSetCalibration	endp


