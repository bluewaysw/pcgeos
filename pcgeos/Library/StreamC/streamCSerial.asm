COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Libary/StreamC
FILE:		streamCSerial.asm

AUTHOR:		John D. Mitchell

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
Ext	SerialGetDeviceMap	Get device attributes mask.
Ext	SerialOpen		Create stream.
Ext	SerialClose		Destroy stream.
Ext	SerialSetNotify		Set notification callback function.
Ext	SerialGetError		Retrieve latest driver error code.
Ext	SerialSetError		Specify current driver error code.
Ext	SerialFlush		Purge data from stream.
Ext	SerialSetThreshold	Specify read/write thresholds.
Ext	SerialRead		Get buffer worth of data from stream.
Ext	SerialReadByte		Get single byte from stream.
Ext	SerialWrite		Put buffer worth of data out stream.
Ext	SerialWriteByte		Put single byte out stream.
Ext	SerialQuery		Retrieve number of bytes available to
				read/write.
Ext	SerialEscLoadOptions	Load .INI options.
Ext	SerialSetFormat		Specify the modem data format.
Ext	SerialGetFormat		Retrieve the current modem data format.
Ext	SerialSetModem		Specify the modem control information.
Ext	SerialGetModem		Retrieve the modem control information.
Ext	SerialOpenForDriver	Open the serial port for the driver itself.
Ext	SerialSetFlowControl	Specify the port's flow control handling.
Ext	SerialDefinePort	Specify a serial port.
Ext	SerialStatPort		Retrieve information about a serial port.
Ext	SerialCloseWithoutReset	Close but don't reset the port to its
				previous settings.
Ext	SerialSetRole		Set the role of the driver (DCE or DTE)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.
	JDM	93.07.15	Implemented SetNotify.
	JDM	93.08.24	Optimizations/cleanup.

DESCRIPTION:
	This file contains the implementation of the C wrappers/entries
	into the GEOS Serial driver.

	$Id: streamCSerial.asm,v 1.1 97/04/07 11:15:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Code Resource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

StreamCSerial	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Public Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SERIALLOADDRIVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the serial driver and return its handle

CALLED BY:	(GLOBAL)
PASS:		nothing
RETURN:		handle of driver, or 0 if couldn't load it
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EC <serialDriverName	TCHAR	'SERIALEC.GEO', 0>
NEC <serialDriverName	TCHAR	'SERIAL.GEO', 0>

global SERIALLOADDRIVER:far
SERIALLOADDRIVER proc	far
		uses	ds, si
		.enter
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		segmov	ds, cs
		mov	si, offset serialDriverName
		mov	ax, SERIAL_PROTO_MAJOR
		mov	bx, SERIAL_PROTO_MINOR
		call	GeodeUseDriver
		call	FilePopDir
		mov	ax, 0
		jc	done
		mov_tr	ax, bx
done:
		.leave
		ret
SERIALLOADDRIVER endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialOpen.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		StreamOpenFlags	flags		= Flags to open stream.
		word		inBuffSize	= Size of input buffer.
		word		outBuffSize	= Size of output buffer.
		word		timeout		= Timeout value.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALOPEN:far
SERIALOPEN	proc	far	driver:hptr,
				unit:hptr,
				flags:word,
				inBuffSize:word,
				outBuffSize:word,
				timeout:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, flags
	mov	bx, unit
	mov	cx, inBuffSize
	mov	dx, outBuffSize
	mov	bp, timeout		; (bp not used in stack recovery,
					; so it's trashable)
	mov	di, DR_STREAM_OPEN
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.
	clr	ax				; Indicate no error.

exit:
	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALOPEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialClose.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		Boolean		linger		= FALSE == discard any/all
						  pending data and exit.
						  Otherwise, wait for
						  pending data to be
						  written.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALCLOSE:far
SERIALCLOSE	proc	far	driver:hptr,
				unit:hptr,
				linger:sword
	.enter


	mov	bx, driver
	mov	ax, unit
	call	SCStBeginClose
	push	ax

	call	SCUPrepareForDriverCall


	; Disassociate the callback with this port.
	; NOTE:	DS:SI already set.
	mov	bx, unit
	call	SerialNukeCallback

	; Load up arguments to driver function and invoke it.
	; NOTE:	BX, DS:SI already set.
	mov	ax, linger
	mov	di, DR_STREAM_CLOSE
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	done				; AX already set.
	clr	ax				; Indicate no error.

done:
	call	SCUDoneWithDriverCall
	pop	bx			; bx <- callback chain from
					;  SCStBeginClose
	call	SCStFinishClose
	.leave
	ret
SERIALCLOSE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialSetNotify.

CALLED BY:	Global.

PASS:		Handle			driver	= Driver to invoke.
		SerialUnit		unit	= Serial unit to open.
		SerialModemStatus	*status	= Results from driver.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:	????

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALSETNOTIFY:far
SERIALSETNOTIFY	proc	far	driver:hptr,
				unit:hptr,
				retInfo:fptr.word
	uses	bx,cx,dx
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Validate the given serial port number.
	mov	bx, unit
	call	SerialValidatePortNumber	; Invalid port number?
	mov	ax, STREAM_NO_DEVICE		; Assume invalid.
	jc	exit				; Bail.

	; Is the current status valid?
	; NOTE:	BX already set.
	push	ds
	push	bx
	mov	bx, handle dgroup
	call	MemDerefDS
	pop	bx
	mov	ax, ds:[SerialPortStatusMap][bx]; AX = Latest status.
	pop	ds
	test	ax, SERIAL_PORT_STATUS_UNKNOWN	; Invalid?
	jnz	checkCallback			; Nope.

returnInfoExit:
	; Fill in the return values.
	; NOTE:	AX already set.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], ax			; Return current status.

exit:
	call	SCUDoneWithDriverCall
	.leave
	ret

checkCallback:
	; Have we already set the callback for this port?
	; NOTE:	AX already set.
	test	ax, SERIAL_PORT_INVALID		; Callback already set?
	jz	returnInfoExit			; Yep. So let the user know
						; that there's no status.
	; Otherwise, set up our callback to handle this port.
	; NOTE:	BX already set.
	mov	ax, StreamNotifyType <1,SNE_MODEM,SNM_ROUTINE>
	mov	cx, segment StreamResident
	mov	dx, offset SerialCallback
	push	bp				; Save trashed regs.
	mov	bp, bx				; Pass COM port to callback.
	mov	di, DR_STREAM_SET_NOTIFY
	call	ds:[si].DIS_strategy		; Do me baby!
	pop	bp				; Restore trashed regs.
	jc	exit				; AX already set.

	; Callback installed but as of yet, status unknown.
	mov	ax, SERIAL_PORT_STATUS_UNKNOWN
	jmp	returnInfoExit

SERIALSETNOTIFY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialFlush.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALFLUSH:far
SERIALFLUSH	proc	far	driver:hptr,
				unit:hptr,
				roles:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, roles
	mov	bx, unit
	mov	di, DR_STREAM_FLUSH
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALFLUSH	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialSetFormat.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		SerialFormat	format		= Modems settings.
		SerialMode	mode		= TTY mode.
		SerialBaud	baud		= Transmission speed.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALSETFORMAT:far
SERIALSETFORMAT	proc	far	driver:hptr,
				unit:hptr,
				format:word,
				mode:word,
				baud:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	al, {byte} format
	mov	ah, {byte} mode
	mov	bx, unit
	mov	cx, baud
	mov	di, DR_SERIAL_SET_FORMAT
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALSETFORMAT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialGetFormat.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		SerialFormat	*format		= Modems settings.
		SerialMode	*mode		= TTY mode.
		SerialBaud	*baud		= Transmission speed.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALGETFORMAT:far
SERIALGETFORMAT	proc	far	driver:hptr,
				unit:hptr,
				format:fptr.SerialFormat,
				mode:fptr.SerialMode,
				baud:fptr.SerialBaud
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	bx, unit
	mov	di, DR_SERIAL_GET_FORMAT
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, format
	mov	ds:[si], al
	lds	si, mode
	mov	ds:[si], ah
	lds	si, baud
	mov	ds:[si], cx

exit:

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALGETFORMAT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialSetModem.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		SerialModem	modem		= Modem control settings.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALSETMODEM:far
SERIALSETMODEM	proc	far	driver:hptr,
				unit:hptr,
				modem:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	al, {byte} modem
	mov	bx, unit
	mov	di, DR_SERIAL_SET_MODEM
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALSETMODEM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialGetModem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialGetModem.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		SerialModem	*modem		= Modem control settings.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALGETMODEM:far
SERIALGETMODEM	proc	far	driver:hptr,
				unit:hptr,
				modem:fptr.SerialModem
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	bx, unit
	mov	di, DR_SERIAL_GET_MODEM
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, modem
	mov	ds:[si], al

exit:

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALGETMODEM	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialOpenForDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialOpenForDriver.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		StreamOpenFlags	flags		= Flags to open stream.
		word		inBuffSize	= Size of input buffer.
		word		outBuffSize	= Size of output buffer.
		word		timeout		= Timeout value.
		GeodeHandle	owner		= Geode to own stream.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALOPENFORDRIVER:far
SERIALOPENFORDRIVER	proc	far	driver:hptr,
					unit:hptr,
					flags:word,
					inBuffSize:word,
					outBuffSize:word,
					timeout:word,
					owner:hptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Push the strategy routine onto the stack for PCFOM

	pushdw	ds:[si].DIS_strategy

	; Load the driver function arguments...
	mov	ax, flags
	mov	bx, unit
	mov	cx, inBuffSize
	mov	dx, outBuffSize
	mov	si, owner
	mov	di, DR_SERIAL_OPEN_FOR_DRIVER
	mov	bp, timeout		; (can nuke bp b/c not used for
					; stack cleanup in this routine)

	call	PROCCALLFIXEDORMOVABLE_PASCAL

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALOPENFORDRIVER	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialSetFlowControl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialSetFlowControl.

CALLED BY:	Global.

PASS:		Handle			driver	= Driver to invoke.
		SerialUnit		unit	= Serial unit to open.
		SerialFlowControl	flow	= Flow control settings.
		SerialModem		modem	= Modem control settings.
		SerialModemStatus	status	= Modem status settings.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALSETFLOWCONTROL:far
SERIALSETFLOWCONTROL	proc	far	driver:hptr,
					unit:hptr,
					flow:word,
					modem:word,
					status:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, flow
	mov	bx, unit
	mov	cl, {byte} modem
	mov	ch, {byte} status
	mov	di, DR_SERIAL_SET_FLOW_CONTROL
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALSETFLOWCONTROL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialDefinePort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialDefinePort.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		word		basePort	= Base I/O port of device.
		byte		interruptLevel	= -1 == off.
		SerialUnit	*unit		= Serial unit for port..

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALDEFINEPORT:far
SERIALDEFINEPORT	proc	far	driver:hptr,
					basePort:word,
					interruptLevel:word,
					unit:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, basePort
	mov	cl, {byte} interruptLevel
	mov	di, DR_SERIAL_DEFINE_PORT
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, unit
	mov	ds:[si], bx			; Return SerialUnit.

exit:

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALDEFINEPORT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialStatPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialStatPort.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		word		*interruptLevel	= Port's I/O level.
		Boolean		*portOpen	= 0 == Closed, else open.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALSTATPORT:far
SERIALSTATPORT	proc	far	driver:hptr,
				unit:hptr,
				interruptLevel:fptr,
				portOpen:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	bx, unit
	mov	di, DR_SERIAL_STAT_PORT
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, interruptLevel
	mov	ds:[si], al
	lds	si, portOpen
	mov	ds:[si], ah

exit:

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALSTATPORT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCloseWithoutReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for SerialCloseWithoutReset.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		SerialUnit	unit		= Serial unit to open.
		Boolean		linger		= FALSE == discard any/all
						  pending data and exit.
						  Otherwise, wait for
						  pending data to be
						  written.

RETURN:		Boolean	= 0 iff successful otherwise StreamError code.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Load up the arguments and invoke the driver's entry point with the
	appropriate function.
	Return the results to the caller.

KNOWN DEFECTS/CAVEATS/IDEAS:
	See assembly documentation for more information.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	SERIALCLOSEWITHOUTRESET:far
SERIALCLOSEWITHOUTRESET	proc	far	driver:hptr,
					unit:hptr,
					linger:sword
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Disassociate the callback with this port.
	; NOTE:	DS:SI already set.
	mov	bx, unit
	call	SerialNukeCallback

	; Load up arguments to driver function and invoke it.
	; NOTE:	BX, DS:SI already set.
	mov	ax, linger
	mov	di, DR_SERIAL_CLOSE_WITHOUT_RESET
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
SERIALCLOSEWITHOUTRESET	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SERIALSETROLE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C Stub for SerialSetRole

CALLED BY:	Global
PASS:		Handle		driver		= driver to invoke
		SerialUnit	unit		= serial unit to set role of
		SerialRole	role		= role to set
RETURN:		Boolean = 0 iff no error, else StreamError code
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	grisco	12/12/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	SERIALSETROLE:far
SERIALSETROLE	proc	far	driver:hptr, 
				unit:hptr,
				role:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	mov	bx, unit
	mov	ax, role			; al = SerialRole
	mov	di, DR_SERIAL_SET_ROLE
	call	ds:[si].DIS_strategy

	call	SCUDoneWithDriverCall

	.leave
	ret
SERIALSETROLE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Internal Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialNukeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disassociate SerialCallback's connection with the given
		serial port.

CALLED BY:	Internal	-- SerialClose,
				   SerialCloseWithoutReset.

PASS:		AX	= Serial port id (SerialUnit) to open.
		DS:SI	= Driver Info. structure.

RETURN:		Void.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Nuke the callback function.

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.16	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialNukeCallback	proc	near	uses	ax,bx,cx,dx,di,bp
	.enter

	; Disable the callback associated with the given port.
	; NOTE:	BX, DS:SI already set.
	mov	ax, StreamNotifyType <1,SNE_MODEM,SNM_NONE>
	mov	di, DR_STREAM_SET_NOTIFY
	call	ds:[si].DIS_strategy		; Do me baby!

	.leave
	ret
SerialNukeCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialValidatePortNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the given serial port identifier.

CALLED BY:	Internal	-- SerialSetNotify.

PASS:		BX	= Serial port ID (SerialUnit).

RETURN:		Carry	= Set iff invalid serial port ID.
			  Clear otherwise.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Brute force the checks.

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.16	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialValidatePortNumber	proc	near

	; Relies on the fact that port numbers step by 2 and start from 0
	test	bx, 1			; (clears carry)
	jnz	done			; => invalid
	cmp	bx, SERIAL_COM8+1	; if AE (carry clear), then invalid.
done:
	cmc				; return carry set if invalid
	ret
SerialValidatePortNumber	endp

StreamCSerial	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Fixed Code Resource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamResident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SerialCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modem status notification callback.

CALLED BY:	SerialSetNotify via the Serial driver.

PASS:		AX	= Serial port number (SerialPortNum) (from BP in
			  SetNotify). 
		CL	= SerialModemStatus.

RETURN:		Carry clear.

DESTROYED:	Nada.

SIDE EFFECTS:
	Requires:	????

	Asserts:	????

CHECKS:		None.

PSEUDO CODE/STRATEGY:
	Atomically set the SerialPortStatusMap entry corresponding to the
	given port to the given status.  Clear out the special flag bits
	while we're at it.

KNOWN DEFECTS/CAVEATS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.15	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SerialCallback	proc	far
	uses	ax,bx,cx,ds
	.enter

	; Poke the new status into the correct port's status word holder.
	mov	bx, handle dgroup
	call	MemDerefDS			; DS:SI = Serial port
	mov_tr	bx, ax				; BX = Serial port id.
	clr	ch				; Clear unknown & invalid
						; flags in table.
	mov_tr	ds:[SerialPortStatusMap][bx], cx; Set atomically.
	clc

	.leave
	ret
SerialCallback	endp

StreamResident	ends

	SetDefaultConvention
