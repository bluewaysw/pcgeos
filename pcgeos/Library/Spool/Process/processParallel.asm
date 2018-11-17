COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processParallel.asm

AUTHOR:		Jim DeFrisco, 26 March 1990

ROUTINES:
	Name			Description
	----			-----------
	InitParallelPort	do init for port
	ExitParallelPort	do exit for port

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/26/90		Initial revision


DESCRIPTION:
	This file contains the routines to initialize and close the
	parallel port.
		
	$Id: processParallel.asm,v 1.1 97/04/07 11:11:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitParallelPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the port and do special parallel port initialization

CALLED BY:	INTERNAL
		InitPrinterPort

PASS:		nothing

RETURN:		carry set if problem opening port
		if carry set, ax = error type (PortErrors enum)

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

InitParallelPort proc	near
		uses	bx,di,cx,dx,ds,si
curJob		local	SpoolJobInfo
		.enter	inherit

		; copy the port address over to idata

		mov	ax, dgroup
		mov	ds, ax
		mov	ax, curJob.SJI_stream.offset	; move offset 
		mov	ds:[parallelStrategy].offset, ax
		mov	ax, curJob.SJI_stream.segment	; move offset 
		mov	ds:[parallelStrategy].segment, ax

		; open the port
tryOpen:
		mov	bx, parallelParams.PPP_portNum
		mov	dx, SPOOL_PARALLEL_BUFFER_SIZE
		mov	di, DR_STREAM_OPEN
		mov	ax, mask SOF_NOBLOCK
		push	bp			; spare this register
		call	curJob.SJI_stream	; open the port
		pop	bp			; restore frame pointer
		jnc	parPortOK
		mov	cx, PERROR_PARALLEL_ERR
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox		; signal problem
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK
		je	tryOpen			; if not cancelling...
		mov	ax, PE_PORT_NOT_OPENED	; otherwise signal error type
		stc
		jmp	done

		; the port opened ok, so let's set up some error conditions
		; first do a PARALLEL_QUERY to make sure the printer isn't 
		; off-line or anything
parPortOK:
		mov	bx, parallelParams.PPP_portNum 
		mov	di, DR_PARALLEL_QUERY	; see if it's ok
		call	curJob.SJI_stream	; 
		tst	ax			; if ax=0, everything is ok
		jz	setErrorMask
		
		; printer is busy or off-line.  Tell the user

		mov	cx, PERROR_SOME_PROBLEM	; else there is some wierd prob
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox		; signal problem
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK		; continue printing?
		je	parPortOK		; yes, so try again
		mov	ax, PE_PORT_INIT_ERROR	; port is open, but not init'd
		stc
		jmp	done

		; printer is OK, set up some error reporting conditions
setErrorMask:
		clr	ax			; don't mask any errors
		mov	bx, parallelParams.PPP_portNum 
		mov	di, DR_PARALLEL_MASK_ERROR
		call	curJob.SJI_stream	; handle all errors

		; set the error notification mechanism

		push	bp			; save frame pointer
		mov	di, DR_STREAM_SET_NOTIFY
		mov	ax, StreamNotifyType <0, SNE_ERROR, SNM_ROUTINE>
		mov	bx, parallelParams.PPP_portNum 
		mov	cx, dgroup
		mov	dx, offset dgroup:StreamErrorHandler
		mov	bp, curJob.SJI_qHan	; value to pass in ax
		call	ds:[parallelStrategy]	; call to driver
		pop	bp

		; set the timeout value

		mov	di, DR_PARALLEL_TIMEOUT
		mov	ax, curJob.SJI_info.JP_timeout
		call	ds:[parallelStrategy]	; set timeout value
		
		; now set the connection info for the printer driver

		mov	di, DR_PRINT_SET_STREAM
		mov	cx, parallelParams.PPP_portNum
		mov	si, curJob.SJI_info.JP_portInfo.PPI_type
		mov	dx, curJob.SJI_sHan	; pass stream handle
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver
		clc				; signal no problem

		; all done
done:
		.leave
		ret
InitParallelPort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitParallelPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the port 

CALLED BY:	INTERNAL
		ExitPrinterPort

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Exitial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ExitParallelPort proc	near
		uses	ax,bx,di
curJob		local	SpoolJobInfo
		.enter	inherit

		; close the port

		mov	bx, parallelParams.PPP_portNum
		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_LINGER
		push	bp
		call	curJob.SJI_stream
		pop	bp

		; all done

		.leave
		ret
ExitParallelPort endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyParallelPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the existence and operation of the port

CALLED BY:	INTERNAL
		SpoolVerifyPrinterPort

PASS:		portStrategy	- inherited local variable
		ds:si - PrintPortInfo

RETURN:		carry		- SET if there is some problem

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		open the port
		do a PARALLEL_VERIFY to check for interrupt operation
		if (needs to be thread driven)
		    change .ini file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

parallelPort	equ	<ds:[si].PPI_params.PP_parallel>

VerifyParallelPort proc	near
portStrategy	local	fptr
		.enter	inherit

		; test the port.  first open it.

		mov	bx, parallelPort.PPP_portNum
		mov	dx, 10			; don't need much
		mov	ax, mask SOF_NOBLOCK
		mov	di, DR_STREAM_OPEN	; check if port is there
		push	bp			; save this register
		call	portStrategy
		pop	bp
		jc	portBusy		; somebody is using the port

		; OK, the port is open.  Now verify the operation of the port.
portOpen:
		mov	bx, parallelPort.PPP_portNum
		mov	di, DR_PARALLEL_VERIFY
		call	portStrategy
		test	ax, mask PE_ERROR	; errors ?
		jnz	portVerifyError		; some port error
		test	ax, mask PE_TIMEOUT	; did the function time out ?
		jnz	portVerifyTimeout	;  yes, thread drive it

		; error and timeout bits are clear.  If the rest is clear, 
		; then we're OK, else there is some error

		tst	ax			; is the printer connected ?
		jz	allOK			;  yes, continue
		mov	cx, SERROR_TEST_OFFLINE
		jmp	foundError

		; everything is ok, so close the port down.
allOK:
		mov	bx, parallelPort.PPP_portNum
		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_DISCARD	; don't care about any data
		call	portStrategy

		; port tests out, exit with flying colors
portExitOK:
		clc			; everything is ok
exit:
		.leave
		ret

		; couldn't open the port since someone was using it
		; tell the user
portBusy:
		mov	cx, SERROR_PORT_BUSY
		clr	dx
		call	SpoolErrorBox
		stc
		jmp	exit



		; VERIFY returned with some error.  Get the user to fix it.
portVerifyError:
		mov	cx, SERROR_TEST_NO_PAPER ; no paper ?
		test	ax, mask PE_NOPAPER	; deal with it
		jnz	foundError
		mov	cx, SERROR_TEST_OFFLINE ; no paper ?
		test	ax, mask PE_OFFLINE	; deal with it
		jnz	foundError
		mov	cx, SERROR_TEST_PARALLEL_ERROR
foundError:
		clr	dx			; no queue yet
		call	SpoolErrorBox
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK		; continue testing ?
		je	portOpen		; yes, so try again

		; all done.  close the port an signal the error

		mov	bx, parallelPort.PPP_portNum
		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_DISCARD	; don't care about any data
		call	portStrategy
		call	threadDriveItBaby	; assume worst-case, rather
						;  than leave it interrupt-
						;  driven and forcing the user
						;  to find out the hard way.

		stc				; signal error
		jmp	exit


		; VERIFY returned with a timeout.  that means we should try
		; to drive it with a thread. First close the port, then 
		; change the interrupt level, then change the .ini file
portVerifyTimeout:
		mov	bx, parallelPort.PPP_portNum
		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_DISCARD	; don't care about any data
		call	portStrategy

		call	threadDriveItBaby
		jmp	portExitOK


threadDriveItBaby:
		; set the port to be thread driven (interrupt level 0)

		mov	bx, parallelPort.PPP_portNum
		mov	di, DR_PARALLEL_SET_INTERRUPT
		clr	al
		call	portStrategy

		; change the .ini file

		push	ds,si,bp
		mov	bx, parallelPort.PPP_portNum	; cx:dx -> key
		segmov	ds, cs, cx			; cx -> PrintInit
		mov	si, offset cs:categoryName	; ds:si -> category
		mov	dx, cs:parallelPortNames[bx]	; get offset to string
		clr	bp				; want interrupt 0
		call	InitFileWriteInteger
		pop	ds,si,bp
		retn

VerifyParallelPort endp

categoryName	char	"parallel",0

PrintInit	ends



PrintError	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ErrorParallelPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle parallel port errors

CALLED BY:	parallel driver, via StreamErrorHandler in idata

PASS:		ds	- segment of locked queue segment
		*ds:si	- pointer to queue that is affected
		dx	- error word

RETURN:		carry	- set if print job should abort
		ds	- still points at PrintQueue (may have changed)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		handle error in parallel port. First query driver to see what
		the error is.  Possible errors include:

			* PE_NOPAPER	- printer is out of paper
			* PE_OFFLINE	- printer is off-line
			* PE_ERROR	- printer has some generic error
			* PE_TIMEOUT	- printer has timed out

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

parPort	equ	<PPI_params.PP_parallel.PPP_portNum>

ErrorParallelPort proc	near
		uses	ax,bx,cx,di,es
		.enter	

		; set up es -> dgroup, so we can get the address of the
		; parallel port driver strategy routine

		mov	ax, dgroup
		mov	es, ax

		; we don't need to query the driver, since we were passed the
		; error type.
		; dx holds the error code.  Wade throught the possibilities

		mov	ax, dx				; set up error here
checkErrors:
		test	ax, mask PE_ERROR		; check if error bit set
		jz	checkTimeout			;  no, may be timeout

		mov	cx, PERROR_NO_PAPER		; set proper enum
		test	ax, mask PE_NOPAPER		; check for no paper
		jnz	signalError

		; check the next error condition

		mov	cx, PERROR_OFF_LINE		; set proper enum
		test	ax, mask PE_OFFLINE		; check off line error
		jnz	signalError			; check other error

		; check the next error condition

		mov	cx, PERROR_PARALLEL_ERR		; set proper enum
		jmp	signalError			; check other error
	
		; either a timeout or fatal-error or other unknown problem
		; (assume off-line)
checkTimeout:
		mov	cx, PERROR_FATAL
		test	ax, mask PE_FATAL
		jnz	signalError

		mov	cx, PERROR_OFF_LINE		; assume off-line
		test	ax, mask PE_TIMEOUT
		jz	signalError

		; we have a timeout, so check retry counter

		mov	cx, PERROR_TIMEOUT		; set proper enum
		mov	bx, ds:[si]			; QueueInfo => DS:BX
		sub	ds:[bx].QI_curRetry, 1		; number of retries left
		jnc	checkRestart			; restart if not borrow
		mov	dl, ds:[bx].QI_maxRetry
		mov	ds:[bx].QI_curRetry, dl		; reset to max retries
		
		; OK, so we want to signal the user that something is wrong.
		; First let's unlock the print queue so we don't clog up 
		; any other threads that are running.
signalError:
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
		jne	checkRestart			;  no, continue

		; the user has decided to call it quits.  Close down the
		; port and let the spooler handle all the errors generated.
		
		mov	bx, ds:[si]			; deref queue handle
		mov	ds:[bx].QI_error, SI_ABORT	; signal abort

		; close the port

		call	CloseParallelPort
		stc					; set error flag
done:
		.leave
		ret

		; if we haven't timed out yet, then just send a restart to
		; the driver
checkRestart:
		cmp	cx, PERROR_TIMEOUT		; only send for timeout
		jne	checkErrorCleared
		mov	di, DR_PARALLEL_RESTART
		mov	bx, ds:[si]			; deref queue handle
		mov	ax, ds:[bx].QI_resend		; send correct flag
		mov	bx, ds:[bx].QI_portInfo.parPort
		call	es:[parallelStrategy]		; send restart msg
signalNoError:
		clc					; signal no error
		jmp	done

		; the user says he's cleared the error.  Let's check and
		; make sure. If any error is returned (i.e. the query
		; returns a non-zero value), we know something is wrong
		; and display the appropriate error to the user.
checkErrorCleared:
		cmp	ax, IC_NULL			; error already displayed?
		je	signalNoError			;  yes, exit quietly
		mov	di, DR_PARALLEL_QUERY		; check for errors
		mov	bx, ds:[si]			; deref queue handle
		mov	bx, ds:[bx].QI_portInfo.parPort
		call	es:[parallelStrategy]		; get error status
		test	ax, mask PE_NOPAPER or \
			    mask PE_OFFLINE or \
			    mask PE_ERROR		; still errors ?
		jz	signalNoError			;  nope, so we're done
		jmp	checkErrors			;  else check it out
ErrorParallelPort endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseParallelPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the parallel port

CALLED BY:	ErrorParallelPort, CommPortErrorHandler

PASS:		*ds:si - QueueInfo
		es - dgroup

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseParallelPort	proc near
		uses	ax,bx,di
		.enter
		mov	bx, ds:[si]			; QueueInfo
		
		mov	bx, ds:[bx].QI_portInfo.parPort
		mov	di, DR_STREAM_CLOSE		; close the port
		mov	ax, STREAM_DISCARD		; kill the data
		call	es:[parallelStrategy]		; signal the driver

		.leave
		ret
CloseParallelPort	endp



PrintError	ends
