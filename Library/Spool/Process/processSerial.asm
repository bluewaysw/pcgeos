COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processSerial.asm

AUTHOR:		Jim DeFrisco, 26 March 1990

ROUTINES:
	Name			Description
	----			-----------
	InitSerialPort		do init for port
	ExitSerialPort		do exit for port

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision


DESCRIPTION:
	This file contains the routines to initialize and close the serial 
	port
		

	$Id: processSerial.asm,v 1.1 97/04/07 11:11:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the port and do special serial port initialization

CALLED BY:	INTERNAL
		InitPrinterPort

PASS:		nothing

RETURN:		carry set if problem opening port
		if carry set, then ax = error type (PortErrors)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

serialParams	equ	<curJob.SJI_info.JP_portInfo.PPI_params.PP_serial>

InitSerialPort	proc	near
		uses	bx,di,cx,dx,ds
curJob		local	SpoolJobInfo
		.enter	inherit

		; copy the port address over to idata

		mov	ax, dgroup
		mov	ds, ax
		mov	ax, curJob.SJI_stream.offset	; move offset 
		mov	ds:[serialStrategy].offset, ax
		mov	ax, curJob.SJI_stream.segment	; move offset 
		mov	ds:[serialStrategy].segment, ax

		; open the port
tryOpen:
		mov	bx, serialParams.SPP_portNum
		mov	dx, SPOOL_SERIAL_OUTPUT_BUFFER_SIZE
		mov	cx, SPOOL_SERIAL_INPUT_BUFFER_SIZE
		mov	di, DR_STREAM_OPEN
		mov	ax, mask SOF_NOBLOCK
		push	bp			; save frame pointer
		call	curJob.SJI_stream	; open the port
		pop	bp			; restore frame pointer
		jnc	serialPortOK
		mov	cx, PERROR_SERIAL_ERR
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox		; signal problem
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_DISMISS
		jne	tryOpen			; if not cancelling...
		mov	ax, PE_PORT_NOT_OPENED	; signal error type
		stc				;  again..
		jmp	done

		; initialize the port parameters
serialPortOK:
		mov	al, serialParams.SPP_format
		mov	ah, serialParams.SPP_mode
		mov	bx, serialParams.SPP_portNum
		mov	cx, serialParams.SPP_baud
		mov	di, DR_SERIAL_SET_FORMAT
		push	bp
		call	curJob.SJI_stream	; open the port
		pop	bp

		; set the flow control 

		clr	ah
		mov	al, serialParams.SPP_flow
		mov	bx, serialParams.SPP_portNum
		mov	cl, serialParams.SPP_stopRem
		mov	ch, serialParams.SPP_stopLoc
		mov	di, DR_SERIAL_SET_FLOW_CONTROL
		push	bp
		call	curJob.SJI_stream	; open the port
		pop	bp

		; set the error notification mechanism

		push	bp			; save frame pointer
		mov	di, DR_STREAM_SET_NOTIFY
		mov	ax, StreamNotifyType <0, SNE_ERROR, SNM_ROUTINE>
		mov	bx, serialParams.SPP_portNum 
		mov	cx, dgroup
		mov	dx, offset dgroup:StreamErrorHandler
		mov	bp, curJob.SJI_qHan	; value to pass in ax
		call	ds:[serialStrategy]	; call to driver
		pop	bp

		; set up something to read the input stream when it's full

		push	bp			; save frame pointer
		mov	di, DR_STREAM_SET_NOTIFY
		mov	ax, StreamNotifyType <1, SNE_DATA, SNM_ROUTINE>
		mov	bx, serialParams.SPP_portNum 
		mov	cx, dgroup
		mov	dx, offset dgroup:StreamInputHandler
		mov	bp, curJob.SJI_qHan	; value to pass in ax
		call	ds:[serialStrategy]	; call to driver
		pop	bp

		; now set the connection info for the printer driver

		mov	di, DR_PRINT_SET_STREAM
		mov	cx, serialParams.SPP_portNum
		mov	si, curJob.SJI_info.JP_portInfo.PPI_type
		mov	dx, curJob.SJI_sHan	; pass stream handle
		mov	bx, curJob.SJI_pstate	; pass pstate handle
		call	curJob.SJI_pDriver
		clc				; signal no error

		; all done
done:
		.leave
		ret
InitSerialPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the port 

CALLED BY:	INTERNAL
		ClosePrinterPort

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		put pseudo code here

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExitSerialPort	proc	near
		uses	ax,bx,di
curJob		local	SpoolJobInfo
		.enter	inherit

		; close the port

		mov	bx, serialParams.SPP_portNum
		mov	ax, STREAM_LINGER
		mov	di, DR_STREAM_CLOSE
		push	bp
		call	curJob.SJI_stream	; open the port
		pop	bp

		; all done

		.leave
		ret
ExitSerialPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifySerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the existance and operation of the port

CALLED BY:	INTERNAL
		SpoolVerifyPrinterPort

PASS:		portStrategy	- inherited local variable
		ds:si - PrintPortInfo

RETURN:		carry		- SET if there is some problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		just return with carry clear for now.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

serialPort	equ	<ds:[si].PPI_params.PP_serial>

VerifySerialPort proc	near
		uses	ax, bx, cx, di
portStrategy	local	fptr
		.enter	inherit

		; get the device map from the serial driver and check if
		; our guy is there

		mov	di, DR_STREAM_GET_DEVICE_MAP
		call	portStrategy

		; ax has device map, test for the bit we're interested in

		mov	cx, serialPort.SPP_portNum	; get port number
		mov	bx, 1
		shl	bx, cl				; should line up
		and	ax, bx
		jz	noWayJose			; port doesn't exist
		clc
exit:
		.leave
		ret

		; can't find the port.  signal error.
noWayJose:
		mov	cx, SERROR_MISSING_COM_PORT
		clr	dx
		call	SpoolErrorBox
		stc
		jmp	exit
VerifySerialPort endp

PrintInit	ends



PrintError	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ErrorSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle serial port errors

CALLED BY:	serial driver, via StreamErrorHandler in idata

PASS:		ds	- segment of locked queue segment
		*ds:si	- pointer to queue that is affected
		dx	- error code (SerialErrors)

		inherits curJob local variabes

RETURN:		carry	- set if print job should abort
		ds	- still points at PrintQueue (may have changed)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		handle error in serial port. Possible errors include:

			* SE_BREAK	- Break condition detected on line
			* SE_FRAME	- Framing error
			* SE_PARITY	- Parity error
			* SE_OVERRUN	- new byte received before old byte read

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

serPort	equ	<PPI_params.PP_serial.SPP_portNum>

ErrorSerialPort proc	near
		uses	ax,bx,cx,di,es
		.enter	

		; set up es -> dgroup, so we can get the address of the
		; serial port driver strategy routine

		mov	ax, dgroup
		mov	es, ax

		; we don't need to query the driver, since we were passed the
		; error type.  For the serial port, just put up a generic
		; sounding error box

		mov	cx, PERROR_SERIAL_ERR		; set proper enum

		; OK, so we want to signal the user that something is wrong.
		; First let's unlock the print queue so we don't clog up 
		; any other threads that are running.

		call	UnlockQueue			; release the queue
		mov	dx, si				; dx = queue handle
		call	SpoolErrorBox
		push	ax				; save error code
		call	LockQueue			; get queue back, since
		mov	ds, ax				; caller expects it 
		pop	ax				; restore error code

		; check to see what to do...

		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS, IC_NULL
		cmp	ax, IC_DISMISS			; should we abort?
		jne	signalNoError			;  no, continue

		; the user has decided to call it quits.  Close down the
		; port and let the spooler handle all the errors generated.
		
		mov	bx, ds:[si]			; deref queue handle
		mov	ds:[bx].QI_error, SI_ABORT	; signal abort

		; close the port

		mov	bx, ds:[bx].QI_portInfo.serPort
		mov	di, DR_STREAM_CLOSE		; close the port
		mov	ax, STREAM_DISCARD		; kill the data
		call	es:[serialStrategy]		; signal the driver
		stc					; set error flag
done:
		.leave
		ret

		; apparently we don't really have a problem.  At least none
		; that we want to kill the job for...
signalNoError:
		clc					; set no-error flag
		jmp	done
ErrorSerialPort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputSerialPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Empty the input buffer so we can continue

CALLED BY:	INTERNAL
		CommPortInputHandler
PASS:		ds:bx -> QueueInfo structure
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	6/24/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BOGUS_READ_STACK_USAGE	equ	32			; amount to read @time

InputSerialPort	proc	near
		uses	ax, bx, cx, dx, es, di
		.enter

		; set up es -> dgroup, so we can get the address of the
		; serial port driver strategy routine

		mov	ax, dgroup
		mov	es, ax

		; just read the data.
		
		push	ds, si
		mov	bx, ds:[si]			; dereference queuehan
		mov	bx, ds:[bx].QI_portInfo.serPort
		mov	di, DR_STREAM_READ		; close the port
		mov	ax, STREAM_NOBLOCK		; kill the data
		segmov	ds, ss, si
		sub	sp, BOGUS_READ_STACK_USAGE	; do a bit at a time
		mov	si, sp
		call	es:[serialStrategy]		; signal the driver
		add	sp, BOGUS_READ_STACK_USAGE	; restore stack
		pop	ds, si

		.leave
		ret
InputSerialPort	endp

PrintError	ends
