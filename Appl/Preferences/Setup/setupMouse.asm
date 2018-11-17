COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		setupMouse.asm

AUTHOR:		Cheng, 6/90

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial revision
	Adam	10/90		Substantial revision to add extended mouse
				driver support.

DESCRIPTION:

	$Id: setupMouse.asm,v 1.1 97/04/04 16:28:03 newdeal Exp $

-------------------------------------------------------------------------------@



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupMouseSelected

DESCRIPTION:	Acknowledge the selection of a mouse driver by the user and
		put up whatever next screen is appropriate.

CALLED BY:	MSG_SETUP_MOUSE_SELECTED

PASS:		ds,es - dgroup

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	6/90		Initial version
	Adam	10/90		Revised for extended drivers

-------------------------------------------------------------------------------@

SetupMouseSelected	method	SetupClass, MSG_SETUP_MOUSE_SELECTED
		.enter
	;
	; Find the mouse that user has selected
	;
		mov	bx, handle MouseSelectList
		mov	si, offset MouseSelectList
		call	UtilGetSelection
		cmp	cx, -1
		jne	haveMouse
		jmp	done

haveMouse:
		mov	ds:[mouseDevice], cx

	;
	; Fetch the extra word of info for the device so we know what to do.
	;
		mov	ax, MSG_PREF_TOC_LIST_GET_SELECTED_ITEM_INFO
		mov	di, mask MF_CALL
		call	ObjMessage
		mov	ds:[mouseInfo], ax	; save the extra info

		test	ax, mask MEI_SERIAL
		jz	checkGen
	;
	; Mouse is serial, so put up serial-port-selection screen next,
	; after initializing the list based on the current value, of course.
	; ds:[mousePort] is initialized by method sent out due to
	; MSG_GEN_LIST_SET_EXCL
	; 
		mov	si, offset mouseCatString
		mov	cx, ds
		mov	dx, offset portKeyString
		call	InitFileReadInteger
		dec	ax			; convert to 0-origin
		jnc	havePort
		clr	ax		; assume COM1 if nothing there.
havePort:
		xchg	cx, ax
		mov	si, offset MouseSerialPortList
		mov	bx, handle MouseSerialPortList
		call	UtilSetSelection

		mov	si, offset MouseSerialPortScreen
		mov	bx, handle MouseSerialPortScreen
		jmp	initiateNextScreen

checkGen:
	;
	; Mouse is not serial, so nuke the port key in the mouse category to
	; indicate this.
	; 
		mov	si, offset mouseCatString
		mov	cx, ds
		mov	dx, offset portKeyString
		push	ax
		call	InitFileDeleteEntry
		pop	ax

		test	ax, mask MEI_GENERIC
		jz	checkIRQ
	;
	; Mouse is generic, so put up the generic-mouse-have-you-installed-
	; your-driver-software-properly screen next.
	; 
		mov	si, offset GenMouseScreen
		mov	bx, handle GenMouseScreen
		jmp	initiateNextScreen

checkIRQ:
		test	ax, mask MEI_IRQ
		jz	checkNoMouse
	;
	; Neither generic, nor serial, but mouse needs an interrupt level
	; anyway. Set the range to the suggested initial value, then put
	; up the mouse-interrupt screen.
	;
		andnf	ax, mask MEI_IRQ
		mov	cl, offset MEI_IRQ
		shr	ax, cl

		call	SetupSetInitialMouseInt
		mov	si, offset MouseIntScreen
		mov	bx, handle MouseIntScreen
		jmp	initiateNextScreen

checkNoMouse:

		; Assume that selection 0 means "no mouse"
		cmp	ds:[mouseDevice], 0
		jne	doMouseTest

	;
	; no mouse
	;
		call	SetupNoMouse
		jmp	done

doMouseTest:
	;
	; No further information required by either party, so go to the test
	; screen.
	;
		mov	si, offset MouseTestScreen
		mov	bx, handle MouseTestScreen

initiateNextScreen:
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage

	;
	; Tell the list to store the chosen device and its info word in the .ini file.
	;
		mov	bx, handle MouseSelectList
		mov	si, offset MouseSelectList
		mov	di, mask MF_CALL
		mov	ax, MSG_META_SAVE_OPTIONS
		call	ObjMessage

done:
		.leave
		ret
SetupMouseSelected	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupNoMouse

DESCRIPTION:	

CALLED BY:	INTERNAL (SetupMouseSelected)

PASS:		ds - dgroup

RETURN:		

DESTROYED:	ax,bx,cx,dx,di,si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	1/91		Initial version

-------------------------------------------------------------------------------@

SetupNoMouse	proc	near
		mov	si, offset NoMouseScreen
		mov	bx, handle NoMouseScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage
	;
	; Nuke driver & mouse keys
	;

		mov     si, offset mouseCatString
;		mov     cx, cs
;		mov     dx, offset cs:[deviceKey]
		mov	cx, segment dgroup
		mov	dx, offset deviceKeyString
		call	InitFileDeleteEntry

;		mov     dx, offset cs:[driverKey]
		mov	dx, offset driverKeyString
		call	InitFileDeleteEntry

		call	InitFileCommit

		mov	ds:[mouseTested], -1	;Allow the user to proceed
		ret
SetupNoMouse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSetInitialMouseInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the initial value displayed by the mouse interrupt
		range.

CALLED BY:	SetupMouseSelected, SetupSerialPortSelected
PASS:		ax	= initial level
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version
	dloft	7/92		GenRange->GenValue changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSetInitialMouseInt	proc	near
		.enter
	;
	; Set mouse int to that stored in the INI file, if anything. If
	; nothing, use the passed level.
	;
		push	ax
		mov	si, offset mouseCatString
		mov	cx, ds
		mov	dx, offset mouseIRQKeyString
		call	InitFileReadInteger
		pop	dx
		jc	haveIRQ
		xchg	dx, ax
haveIRQ:
		clr	cx			; dx:cx = int.fract
		mov	bp, cx			; 0 = determinate state
		mov	si, offset MouseIntRange
		mov	bx, handle MouseIntRange
		mov	di, mask MF_CALL
		mov	ax, MSG_GEN_VALUE_SET_VALUE
		call	ObjMessage
		.leave
		ret
SetupSetInitialMouseInt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupSetMousePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the chosen mouse port.

CALLED BY:	MSG_SETUP_SET_MOUSE_PORT
PASS:		ds	= dgroup
		cx	= SerialPortNum of chosen port.
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupSetMousePort method SetupClass, MSG_SETUP_SET_MOUSE_PORT
		.enter
		mov	ds:[mousePort], cx
		.leave
		ret
SetupSetMousePort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupMousePortSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge the selection of a serial port for the mouse

CALLED BY:	MSG_SETUP_MOUSE_PORT_SELECTED
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupMousePortSelected	method	SetupClass, MSG_SETUP_MOUSE_PORT_SELECTED
		.enter
		mov	ax, ds:[mousePort]
		mov	bx, handle MouseTestScreen
		mov	si, offset MouseTestScreen
		mov	cx, handle MouseIntScreen
		mov	dx, offset MouseIntScreen
		call	SetupNextSerialScreen
		jc	done
	;
	; Set the port into the ini file.
	;
		call	SetupWriteMousePort
done:
		.leave
		ret
SetupMousePortSelected	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupWriteMousePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the "port" key for the [mouse] category to the current
		mouse port.

CALLED BY:	SetupMousePortSelected, SetupMouseIntSelected
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	bp, si, cx, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupWriteMousePort proc near
		.enter
		mov	bp, ds:[mousePort]
		shr	bp
		inc	bp		; 1-4, not 0-3
		mov	si, offset mouseCatString
		mov	cx, ds
		mov	dx, offset portKeyString
		call	InitFileWriteInteger
		call	InitFileCommit
		.leave
		ret
SetupWriteMousePort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupMouseIntSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge the selection of the mouse's interrupt level by
		the user.

CALLED BY:	MSG_SETUP_MOUSE_INT_SELECTED
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupMouseIntSelected	method	SetupClass, MSG_SETUP_MOUSE_INT_SELECTED
		.enter
	;
	; Fetch the interrupt level and store it away
	;
		mov	bx, handle MouseIntRange
		mov	si, offset MouseIntRange
		call	GetRange
		mov	ds:[mouseIRQ], cx

	;
	; If we're here b/c we needed to get the interrupt number for a non-
	; standard serial port, tell the serial driver about the thing.
	; 
		test	ds:[mouseInfo], mask MEI_SERIAL
		jz	writeIRQ
		mov	ax, ds:[mousePort]
		call	SetupDefineSerialPort
		jc	backToPortSelect
	;
	; Write the mouse port to the ini file now we're sure the port's ok
	;
		call	SetupWriteMousePort
doTest:
	;
	; Bring up the test screen.
	;
		mov	bx, handle MouseTestScreen
		mov	si, offset MouseTestScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
sendMethod:
		clr	di
		call	ObjMessage
		.leave
		ret
writeIRQ:
	;
	; Mouse is a non-serial one that required an interrupt, so write the
	; interrupt level to the [mouse] category and go test the thing.
	; 
		mov	bp, cx
		mov	si, offset mouseCatString
		mov	cx, ds
		mov	dx, offset mouseIRQKeyString
		call	InitFileWriteInteger
		jmp	doTest

backToPortSelect:
	;
	; Port doesn't actually exist, so go back to the serial port screen.
	;
		mov	bx, handle MouseIntScreen
		mov	si, offset MouseIntScreen
		mov	ax, MSG_SETUP_SCREEN_DISMISS
		jmp	sendMethod
SetupMouseIntSelected	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SMTakeFocusAwayFromTheDamnTrigger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the "Click here to test" trigger doesn't have the
		focus.

CALLED BY:	SetupMouseTestOnScreen
PASS:		ds	= dgroup
RETURN:		mouseTested set to 0
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/24/90	Initial version
	dloft	6/23/92		Quick fix to get focus back to interaction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SMTakeFocusAwayFromTheDamnTrigger	proc	near
		.enter
	;
	; Force the focus off the damn test trigger.
	;
		mov	ax, MSG_META_RELEASE_FOCUS_EXCL
		mov	bx, handle MouseTestTrigger
		mov	si, offset MouseTestTrigger
		mov	di, mask MF_CALL
		call	ObjMessage
	
	;
	; Flag the mouse as untested in case the user was able to trigger the
	; damn thing before we could get the focus off it.
	;
		mov	ds:[mouseTested], 0
		.leave
		ret
SMTakeFocusAwayFromTheDamnTrigger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupMouseTestOnScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with bringing up the MouseTest screen.

CALLED BY:	MSG_SETUP_MOUSE_TEST_ON_SCREEN
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupMouseTestOnScreen	method	SetupClass, MSG_SETUP_MOUSE_TEST_ON_SCREEN
		.enter
	;
	; Take focus from the the trigger so we don't get a method queued
	; that the test has completed.
	;
		call	SMTakeFocusAwayFromTheDamnTrigger
	;
	; Now load the mouse driver.
	;
		mov	ax, MSG_SETUP_LOAD_MOUSE_DRIVER
		mov	bx, handle 0
		clr	di
		call	ObjMessage
	;
	; Take focus again in case a standard box got put up...
	;
		call	SMTakeFocusAwayFromTheDamnTrigger
		.leave
		ret
SetupMouseTestOnScreen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupLoadMouseDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to load the mouse driver whose description has been
		built up into the [mouse] category.

CALLED BY:	MSG_SETUP_LOAD_MOUSE_DRIVER
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
	If there's already a mouse driver loaded, the hide pointer
	count is expected to be zero on entry.

	Otherwise, hide count is expected to be one, so we'll
	decrement it if we successfully load the mouse.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: We cannot just use our variables to do this as we might have
	gotten here in MODE_AFTER_PM_MOUSE_CHANGE and have none of the
	variables set.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetupLoadMouseDriver	method	SetupClass, MSG_SETUP_LOAD_MOUSE_DRIVER
		.enter
		mov	ds:[mouseTested], 0	; haven't tested this one...
	;
	; Unload any previously-loaded mouse driver first.
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
		tst	ax
		jz	noOldMouse
		
		mov	bx, ax
		call	GeodeFreeDriver

		clr	bx
		mov	ax, GDDT_MOUSE
		call	GeodeSetDefaultDriver
		jmp	loadNewDriver

noOldMouse:
	;
	; First turn on the mouse pointer again
	;
		call	SetupShowPointer
loadNewDriver:
	;
	; Use the UI's routine to load the thing.
	;
		mov	si, offset mouseCatString
		mov	ax, SP_MOUSE_DRIVERS
		clr	cx				; Expected
							; protocol number?
		clr	dx				; don't care.
		call	UserLoadExtendedDriver
		jnc	setDefault
	;
	; Put up an error message appropriate to the reason for failure.
	; 
		mov	bp, offset noMouseGEO
		cmp	ax, GLE_FILE_NOT_FOUND
		je	putupError
		
		mov	bp, offset loadMouseFailed
		cmp	ax, GLE_DRIVER_INIT_ERROR
		jne	putupError
		
		mov	bp, offset noSuchSerialMouse
		test	ds:[mouseInfo], mask MEI_SERIAL
		jnz	putupError
		
		mov	bp, offset noSuchGenericMouse
		test	ds:[mouseInfo], mask MEI_GENERIC
		jnz	putupError

		mov	bp, offset noSuchMouse
putupError:
		call	MyError

		call	SetupHidePointer
done:
		.leave
		ret

setDefault:
		mov	ax, GDDT_MOUSE
		call	GeodeSetDefaultDriver
		jmp	done
SetupLoadMouseDriver	endp



COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetupMouseTest

DESCRIPTION:	Handle a mouse test

CALLED BY:	MSG_SETUP_MOUSE_TEST

PASS:		ds = es = dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, es, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Cheng	2/90		Initial version

-------------------------------------------------------------------------------@

SetupMouseTest	method	SetupClass, MSG_SETUP_MOUSE_TEST
	.enter
	mov	ax, SST_NOTIFY		;Just a general beep
	call    UserStandardSound	;destroys ax,bx

	mov	ds:[mouseTested], -1	;Allow the user to proceed, since
					; s/he has been able to test the mouse

	.leave
	ret
SetupMouseTest	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupMouseTestComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Acknowledge completion of mouse test, but don't let user
		proceed unless s/he has actually tested the mouse.

CALLED BY:	MSG_SETUP_MOUSE_TEST_COMPLETE
PASS:		ds = es = dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es, ds

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
setupCategory char "setup",0
printerKey char "printer",0

SetupMouseTestComplete	method	SetupClass, MSG_SETUP_MOUSE_TEST_COMPLETE
		.enter
		tst	ds:[mouseTested] 
		jnz	ok
		mov	bp, offset mouseNotTested
		call	MyError
		jmp	done

ok:
		cmp	ds:[mode], MODE_AFTER_PM_MOUSE_CHANGE
		je	setupComplete
		cmp	ds:[mode], MODE_AFTER_SETUP_MOUSE_CHANGE
		je	setupComplete

	; See if we should skip the printer

		mov	cx, cs
		mov	ds, cx
		mov	si, offset setupCategory
		mov	dx, offset printerKey
		mov	ax, TRUE
		call	InitFileReadBoolean
		tst	ax
		jz	skipPrinter
		
		mov	bx, handle PrinterSelectScreen
		mov	si, offset PrinterSelectScreen
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		clr	di
		call	ObjMessage

	;
	; make the first printer in the list be the one selected
	;
		clr	cx
		mov	bx, handle PrinterSelectList
		mov	si, offset PrinterSelectList
		call	UtilSetSelection

done:
		.leave
		ret

setupComplete:
	;
	; Only here to make sure the mouse is ok, so bring up the DoneScreen
	; with the mouse-test-complete text in it.
	; 
		mov	si, offset MouseDoneText
		call	SetupComplete
		jmp	done

skipPrinter:
	; Act as if we've tested a printer
		segmov	ds, dgroup, ax
		ornf	ds:[ptestState], mask PTS_TESTED
		mov	ax, MSG_SETUP_PRINTER_TEST_COMPLETE
		mov	bx, handle 0
		clr	di
		call	ObjMessage
		jmp	done
SetupMouseTestComplete	endp
