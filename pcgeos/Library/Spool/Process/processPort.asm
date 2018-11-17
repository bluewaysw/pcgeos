COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Print Spooler
FILE:		processPort.asm

AUTHOR:		Jim DeFrisco, 15 March 1990

ROUTINES:
	Name			Description
	----			-----------
	InitPrinterPort		Open and initialize the port

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	3/15/90		Initial revision


DESCRIPTION:
	This file contains routines to open and initialise the proper port
	for printing.  To add another type of port to be supported, you must
	do the following:

		0.  The port type must be a stream-type device (i.e. it must
		    support the stream-driver interface calls)

		1.  Add an enum for the type of device as part of the
		    PrinterPortType enumerated type.  Add the
		    appropriate fields into the PortParams union to
		    initialize and communicate with the device.

		2.  Add a dword sized variable in spoolVariable.def to 
		    store the strategy routine address away.

		3.  Add the permanent name of the port driver to the table
		    of permanent names in processTables.asm
		
		4.  Create a file called processPORTTYPE.asm, where 
		    PORTTYPE is the type of port to be supported (e.g.
		    processSerial.asm)  This file will contain the routines
		    to initialize and exit the port drivers.
		
		5.  Write the routines to init and exit the port driver, and
		    add the routine names to the tables in processTables.asm

	$Id: processPort.asm,v 1.1 97/04/07 11:11:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintInit	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpoolVerifyPrinterPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the existence of a printer port

CALLED BY:	GLOBAL

PASS:		ds:si		- pointer to PrintPortInfo struct

RETURN:		ax		- status of operation (SpoolOpStatus), either 
				   SPOOL_OPERATION_SUCCESSFUL (port OK)
				   or
				   SPOOL_CANT_VERIFY_PORT


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		the operation is type-of-port-specific.  Initially, only the
		parallel function does anything.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	To make this work with custom ports, we would need to pass the init
	file category to this routine.  For now, custom port always
	returns SUCCESS.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpoolVerifyPrinterPort	proc	far
		uses	bx,cx,dx,ds,si,es,di,bp

portStrategy	local	fptr.far

		.enter

		; first we need to load the right driver and open the port

		mov	bx, ds:[si].PPI_type	; get port type
		cmp	bx, PPT_NOTHING
		jae	success			; if CUSTOM, or NOTHING

		push	ds, si			; save port info pointer

		call	LoadPortDriverCommon
		jc	loadProblem		; some problem loading

		; OK, we have the driver loaded.  Now initialize it.
		; bx = driver handle

		mov	ax, dgroup		; point into idata
		mov	ds, ax			; ds -> idata
		call	GeodeInfoDriver		; get strategy routine addr
		mov	ax, ds:[si].DIS_strategy.offset
		mov	portStrategy.offset, ax
		mov	ax, ds:[si].DIS_strategy.segment
		mov	portStrategy.segment, ax
		pop	ds, si			; restore port info pointer
		
		; call a driver specific function to open the port

		mov	bx, ds:[si].PPI_type	; get port type
		call	cs:portVerifyTable[bx]	; do rest of function
success:
		mov	ax, SPOOL_OPERATION_SUCCESSFUL ; everything ok
		jnc	exit			; else signal some problem
someProblem:
		mov	ax, SPOOL_CANT_VERIFY_PORT
exit:
		.leave
		ret

		; trouble loading the driver.  call for help.
loadProblem:
		pop	ds, si			; restore port info pointer
		mov	cx, SERROR_CANT_LOAD_PORT_DRIVER
		clr	dx
		call	SpoolErrorBox 
		stc				; signal error
		jmp	someProblem
SpoolVerifyPrinterPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadPortDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load in the right port driver

CALLED BY:	INTERNAL
		SpoolerLoop

PASS:		curJob 

RETURN:		carry	- set if some unrecoverable problem loading driver

DESTROYED:	ax,bx,cx,dx,di,es

PSEUDO CODE/STRATEGY:
		Load in the driver.  If any trouble, notify the user

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadPortDriver proc	far
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; if we've already loaded the driver, don't load it again

		tst	curJob.SJI_sHan			; check for NULL handle
		jnz	done

		clr	bx
		cmp	curJob.SJI_info.JP_portInfo.PPI_type, PPT_NOTHING
		je	haveDriver			; use NULL driver

		mov	bx, curJob.SJI_info.JP_portInfo.PPI_type

		;
		; Pass in the printer name as well, in case the it's
		; needed as an INI category by the called procedure
		;

		push	ds, si
		segmov	ds, ss
		lea	si, curJob.SJI_info.JP_printerName
		ConvPrinterNameToIniCat
		call	LoadPortDriverCommon
		ConvPrinterNameDone
		pop	ds, si

		jc	loadProblem
haveDriver:
		mov	curJob.SJI_sHan, bx		; save stream handle

		; we should also save it in the print queue so we can biff
		; it later should this thread be killed.

		push	ds,ax,si
		call	LockQueue		; lock it down
EC <		ERROR_C	SPOOL_INVALID_PRINT_QUEUE		>
		mov	ds, ax			; ds -> queue
		mov	si, curJob.SJI_qHan	; *ds:si -> QueueInfo
		mov	si, ds:[si]		; dereference it
		mov	ds:[si].QI_portHan, bx	; save away the handle
		call	UnlockQueue		; 
		pop	ds,ax,si
		clc
done:
		.leave
		ret

		; some problem loading driver.  notify user and quit.
loadProblem:
		mov	cx, SERROR_NO_PORT_DRIVER
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox
		stc
		jmp	done
LoadPortDriver endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadPortDriverCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to load a port driver

CALLED BY:	SpoolVerifyPrinterPort, LoadPortDriver

PASS:		bx - PrinterPortType
		ds:si - pointer to null-term .ini category for port
		parameters. 

RETURN:		if error:
			carry set
		else
			bx - driver handle

DESTROYED:	ax,cx,dx,di,si,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
portDriverKeyString 	char	"portDriver",0

LoadPortDriverCommon	proc near


SBCS <		uses	bp						>
DBCS <		uses	bp, ds						>

		.enter

 		call	FilePushDir			;save current path,
 		mov	ax, SP_SYSTEM
 		call	FileSetStandardPath		;and set to system.

 		mov	bx, cs:portNameTable[bx]
		tst	bx
		jnz	haveDriverName

		;
		; The port driver name isn't predefined, so look it up in
		; the .INI file.  
		;

		mov	cx, cs
		mov	dx, offset portDriverKeyString
		mov	bp, FILE_LONGNAME_BUFFER_SIZE
		sub	sp, bp
		segmov	es, ss
		mov	di, sp

		call	InitFileReadString
		jc	portDriverNotFound

		segmov	ds, ss
		mov	si, di
		clr	ax, bx
		call	GeodeUseDriver

		;
		; Restore the stack w/o changing the carry
		;

portDriverNotFound:
		lea	sp, ss:[di][FILE_LONGNAME_BUFFER_SIZE]
		jmp	afterUseDriver

		;
		; The port driver's name is hard-coded, so use it:
		;

haveDriverName:
 		segmov	ds, cs, ax		; ds:si -> port driver name
		mov	si, bx
		clr	ax, bx			; version doesn't matter 
		call	GeodeUseDriver

afterUseDriver:
 		call	FilePopDir		;restore original path.
		.leave
		ret
LoadPortDriverCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPrinterPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open and initialize the printer port

CALLED BY:	INTERNAL (PrintFile)

PASS:		inherits stack frame from SpoolerLoop

RETURN:		carry set if error opening port
		if carry is set, then ax holds an error type (enum PortErrors)
			PE_PORT_INIT_ERROR	- error initializing port
			PE_PORT_NOT_OPENED	- error opening port

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Call the right initialization routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The tables that this routine are driven off of are located 
		in processTables.asm

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPrinterPort	proc	far
		uses	bx, es, di, si, ds
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		mov	bx, curJob.SJI_sHan		; save stream handle
		tst	bx				; any stream handle
		jz	specificInit			; if none, don't do
							; this
		call	GeodeInfoDriver			; get address of
							; strategy routine

		movdw	curJob.SJI_stream, ds:[si].DIS_strategy, ax

		; do other initialization as required
		; the specific init routine will set the error condition
specificInit:
		mov	bx, curJob.SJI_info.JP_portInfo.PPI_type ; get type
		call	cs:portInitTable[bx]		; init the port

		.leave
		ret
InitPrinterPort	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClosePrinterPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open and initialize the printer port

CALLED BY:	INTERNAL (PrintFile)

PASS:		inherits stack frame from SpoolerLoop

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Load the right driver;
		Call the right initialization routine;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The tables that this routine are driven off of are located 
		in processTables.asm

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClosePrinterPort proc	far
		uses	bx
curJob		local	SpoolJobInfo	; all we need to process this job
		.enter inherit

		; see what type of port it is and call the right init routine

		mov	bx, curJob.SJI_info.JP_portInfo.PPI_type ; get type
		call	cs:portExitTable[bx]		; init the port

		; all done

		.leave
		ret
ClosePrinterPort endp

PrintInit	ends



idata		segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamErrorHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle errors coming in from the stream driver

CALLED BY:	serial driver

PASS:		ax	- queue handle for queue assigned to port
		cx	- error word (specific to type of port)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		see what type of error it is and do something about it.
		This function is called from the kernel thread, so it can't
		block or anything.  Best to just post the error and get out
		of here.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	04/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamErrorHandler	proc	far
		mov	dx, cx			; dx <- error code
		mov_tr	cx, ax			; cx <- print queue handle
		mov	ax, MSG_SPOOL_COMM_ERROR
		mov	bx, handle 0		; send message to ourself
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		GOTO	ObjMessage
StreamErrorHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamInputHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle data coming in from the stream driver

CALLED BY:	serial driver

PASS:		cx	- queue handle for queue assigned to port

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		For now, just drop the data on the floor.  I think our
		buffer filling up is the reason hardware handshaking don't
		work...

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	06/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StreamInputHandler	proc	far
		mov	ax, MSG_SPOOL_COMM_INPUT
		mov	bx, handle 0		; send message to ourself
		mov	di, mask MF_FORCE_QUEUE or mask MF_INSERT_AT_FRONT
		GOTO	ObjMessage
StreamInputHandler	endp

idata		ends



PrintError	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommPortErrorHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Found an error signalled from a com port.  Do something.

CALLED BY:	GLOBAL

PASS:		ds	- segment of locked PrintQueue block
		*ds:si	- pointer to print queue that error is for
		dx	- error type

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		chrisb	8/93		changed to always close port

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommPortErrorHandler proc	far
		uses	ax, bx, es
		.enter	
		
		mov	bx, ds:[si]			; QueueInfo
		cmp	ds:[bx].QI_error, SI_ABORT
		mov	bx, ds:[bx].QI_portInfo.PPI_type 
		je	abort
		call	cs:[portErrorTable][bx]
done:
		.leave
		ret

abort:
	;
	; The job has already been aborted, so close the port.  If we
	; don't close it, then the spooler thread (which is probably
	; blocked right now) will never wake up.  Stick dgroup in ES,
	; since all the routines in this table will use it.
	;
		segmov	es, dgroup, ax
		call	cs:[portCloseTable][bx]
		jmp	done
		
CommPortErrorHandler endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CommPortInputHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Found an error signalled from a com port.  Do something.

CALLED BY:	GLOBAL

PASS:		ds	- segment of locked PrintQueue block
		*ds:si	- pointer to print queue that error is for
		dx	- error type

RETURN:		nothing

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

CommPortInputHandler proc	far
		uses	ax, bx
		.enter	

		; call a specific routine, one for each port type

		mov	bx, ds:[si]			; ds:bx -> port
		mov	bx, ds:[bx].QI_portInfo.PPI_type ; get type
		call	cs:portInputTable[bx]		; init the port

		.leave
		ret
CommPortInputHandler endp

PrintError	ends









