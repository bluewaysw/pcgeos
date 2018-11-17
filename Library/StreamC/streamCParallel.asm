COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Libary/StreamC
FILE:		streamCParallel.asm

AUTHOR:		John D. Mitchell

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
Ext	ParallelGetDeviceMap	Get device attributes mask.
Ext	ParallelOpen		Create stream.
Ext	ParallelClose		Destory stream.
Ext	ParallelSetNotify	Set notification callback function.
Ext	ParallelGetError	Retrieve latest driver error code.
Ext	ParallelSetError	Specify current driver error code.
Ext	ParallelFlush		Purge data from stream.
Ext	ParallelSetThreshold	Specify read/write thresholds.
Ext	ParallelWrite		Put buffer worth of data out stream.
Ext	ParallelWriteByte	Put single byte out stream.
Ext	ParallelQuery		Retrieve number of bytes available to
				read/write.
Ext	ParallelEscLoadOptions	Load .INI options.
Ext	ParallelMaskError	Set which errors to ignore. 
Ext	ParallelTimeout		Set number of seconds to wait before
				timing out.
Ext	ParallelRestart		Restart a timed out send.
Ext	ParallelVerify		Test a closed port for a properly
				responding printer.
Ext	ParallelSetInterrupt	Set the interrupt level for the port.
Ext	ParallelStatPort	Get port settings (if it exists).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.
	JDM	93.08.24	Optimization/cleanup.

DESCRIPTION:
	This file contains the implementation of the C wrappers/entries
	into the GEOS Parallel driver.

	$Id: streamCParallel.asm,v 1.1 97/04/07 11:15:10 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Code Resource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

StreamCParallel	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Public Code
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PARALLELLOADDRIVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the parallel driver and return its handle

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
parallelDriverName	TCHAR	'PARALLEL.GEO', 0

global PARALLELLOADDRIVER:far
PARALLELLOADDRIVER proc	far
		uses	ds, si
		.enter
		call	FilePushDir
		mov	ax, SP_SYSTEM
		call	FileSetStandardPath
		segmov	ds, cs
		mov	si, offset parallelDriverName
		mov	ax, PARALLEL_PROTO_MAJOR
		mov	bx, PARALLEL_PROTO_MINOR
		call	GeodeUseDriver
		call	FilePopDir
		mov	ax, 0
		jc	done
		mov_tr	ax, bx
done:
		.leave
		ret
PARALLELLOADDRIVER endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelOpen.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit to open.
		StreamOpenFlags	flags		= Flags to open stream.
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

global	PARALLELOPEN:far
PARALLELOPEN	proc	far	driver:hptr,
				unit:hptr,
				flags:word,
				outBuffSize:word,
				timeout:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, flags
	mov	bx, unit
	mov	dx, outBuffSize
	mov	bp, timeout
	mov	di, DR_STREAM_OPEN
	call	ds:[si].DIS_strategy			; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELOPEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelQuery.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit to open.
		Boolean		*printerBusy	= FALSE iff printer ready
						  for work.  Otherwise,
						  printer is busy.

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

global	PARALLELQUERY:far
PARALLELQUERY	proc	far	driver:hptr,
				unit:hptr,
				retInfo:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	bx, unit
	mov	di, DR_PARALLEL_QUERY
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], ax			; Return bytes available.

exit:
	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELQUERY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelMaskError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelMaskError.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit ID.
		ParallelError	errorMask	= Mask representing which
						  error codes to ignore.

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

global	PARALLELMASKERROR:far
PARALLELMASKERROR	proc	far	driver:hptr,
					unit:hptr,
					errorMask:ParallelError
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, errorMask
	mov	bx, unit
	mov	di, DR_PARALLEL_MASK_ERROR
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELMASKERROR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelTimeout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelTimeout.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit ID.
		word		waitSecs	= Number of seconds to
						  wait for printer to
						  respond.

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

global	PARALLELTIMEOUT:far
PARALLELTIMEOUT	proc	far	driver:hptr,
				unit:hptr,
				waitSecs:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, waitSecs
	mov	bx, unit
	mov	di, DR_PARALLEL_TIMEOUT
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELTIMEOUT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelRestart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelRestart.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit ID.
		Boolean		resendPending	= FALSE iff the pending
						  byte should be discarded.

RETURN:		Boolean	= 0 iff successful otherwise resend of pending
		byte failed.

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

global	PARALLELRESTART:far
PARALLELRESTART	proc	far	driver:hptr,
				unit:hptr,
				resendPending:sword
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, resendPending
	mov	bx, unit
	mov	di, DR_PARALLEL_RESTART
	call	ds:[si].DIS_strategy		; Do me baby!
	mov	ax, -1				; Assume error.

	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELRESTART	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelVerify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelVerify.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit ID.
		ParallelError	*error		= 0 iff printer there
						  and happy...

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

global	PARALLELVERIFY:far
PARALLELVERIFY	proc	far	driver:hptr,
				unit:hptr,
				retInfo:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	bx, unit
	mov	di, DR_PARALLEL_VERIFY
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], ax			; Return error code.

exit:
	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELVERIFY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelSetInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelSetInterrupt.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit ID.
		ParallelInterrupt	pInt	= Interrupt to run the
						  printer or 0 for port
						  to be thread driven.

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

global	PARALLELSETINTERRUPT:far
PARALLELSETINTERRUPT	proc	far	driver:hptr,
					unit:hptr,
					pInt:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, pInt
	mov	bx, unit
	mov	di, DR_PARALLEL_SET_INTERRUPT
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELSETINTERRUPT	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParallelStatPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for ParallelStatPort.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		ParallelUnit	unit		= Parallel unit ID.
		byte		*intLevel	= Interrupt level.
		byte		*portOpen	= FALSE iff port closed.

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

global	PARALLELSTATPORT:far
PARALLELSTATPORT	proc	far	driver:hptr,
					unit:hptr,
					intLevel:fptr.byte,
					portOpen:fptr.byte
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	bx, unit
	mov	di, DR_PARALLEL_STAT_PORT
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, intLevel			; DS:SI = *intLevel.
	mov	ds:[si], al			; Return interrupt level.
	lds	si, portOpen			; DS:SI = *portOpen.
	mov	ds:[si], ah			; Return port open state.

exit:
	call	SCUDoneWithDriverCall
	.leave
	ret
PARALLELSTATPORT	endp


StreamCParallel	ends

	SetDefaultConvention
