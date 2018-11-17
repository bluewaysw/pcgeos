COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Libary/StreamC
FILE:		streamCStream.asm

AUTHOR:		John D. Mitchell

FUNCTIONS:

Scope	Name			Description
-----	----			-----------
Ext	StreamGetDeviceMap	Get device attributes mask.
Ext	StreamOpen		Create stream.
Ext	StreamClose		Destory stream.
Ext	StreamSetNotify		Set notification callback function.
Ext	StreamGetError		Retrieve latest driver error code.
Ext	StreamSetError		Specify current driver error code.
Ext	StreamFlush		Purge data from stream.
Ext	StreamSetThreshold	Specify read/write thresholds.
Ext	StreamRead		Get buffer worth of data from stream.
Ext	StreamReadByte		Get single byte from stream.
Ext	StreamWrite		Put buffer worth of data out stream.
Ext	StreamWriteByte		Put single byte out stream.
Ext	StreamQuery		Retrieve number of bytes available to
				read/write.
Ext	StreamEscLoadOptions	Load .INI options.

added 8/95
Ext	StreamSetMessageNotify
Ext	StreamSetRoutineNotify
Ext	StreamSetDataRoutineNotify
Ext	StreamSetNoNotify

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.
	JDM	93.08.24	Optimization/cleanup.
	Doug	1/19/94		Corrected documentation r.e. errors

DESCRIPTION:
	This file contains the implementation of the C wrappers/entries
	into the GEOS Stream driver.

	$Id: streamCStream.asm,v 1.1 97/04/07 11:15:08 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Code Resource
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	SetGeosConvention

StreamCStream	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamGetDeviceMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamGetDeviceMap.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		word	*deviceMask		= Results from driver.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.
		    

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

global	STREAMGETDEVICEMAP:far
STREAMGETDEVICEMAP	proc	far	driver:hptr, retInfo:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	di, DR_STREAM_GET_DEVICE_MAP
	call	ds:[si].DIS_strategy		; Do me baby!

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], ax

	clc				; no possibility of error...
	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMGETDEVICEMAP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamOpen.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		word	buffSize		= Size of stream buffer.
		GeodeHandle	owner		= Geode to own the stream.
		HeapFlags	heapFlags	= HF_FIXED setting for
						  the stream block (either
						  ALLOC_FIXED or 0).
		StreamToken	*stream		= Results from driver.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMOPEN:far
STREAMOPEN	proc	far	driver:hptr,
				buffSize:word,
				owner:hptr,
				heapFlags:word,
				retInfo:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, buffSize
	mov	bx, owner
	mov	cl, {HeapFlags} heapFlags
	mov	di, DR_STREAM_OPEN
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], bx			; Return the stream token.
exit:
	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMOPEN	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamClose.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		Boolean		linger		= FALSE == discard any/all
						  pending data and exit.
						  Otherwise, wait for
						  pending data to be read.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMCLOSE:far
STREAMCLOSE	proc	far	driver:hptr,
				strm:hptr,
				linger:sword
	.enter

	mov	bx, driver
	mov	ax, strm
	call	SCStBeginClose
	push	ax
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, linger
	mov	bx, strm
	mov	di, DR_STREAM_CLOSE
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	
	pop	bx		; bx <- callbacks from SCStBeginClose
	call	SCStFinishClose
	.leave
	ret
STREAMCLOSE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamSetNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamSetNotify.

CALLED BY:	Global.

PASS:		Handle			driver	= Driver to invoke.
		StreamToken		stream	= Stream to muck with.
		StreamNotifyType	notify	= Notification request.
		

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

	NOTE:	This routine *NOT* yet implemented.  StreamGetError *must*
		be called instead to get device-specific error codes such
		as "SerialError" & "ParallelError".  The "StreamError" value
		returned from the various Stream routines tells only of
		basic problems like the stream not being open, and gives no
		indication of device-specific errors, such as UART overruns
		or parity errors.
	
	NOTE2:	This routine will never be implemented. It exists only for
		API compatibility. See the various StreamSet*Notify
		routines.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JDM	93.07.08	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

global	STREAMSETNOTIFY:far
STREAMSETNOTIFY	proc	far	;driver:hptr,
				;strm:hptr,
				;retInfo:fptr
	.enter

	; Return failure.
	mov	ax, -1

	.leave
	ret
STREAMSETNOTIFY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamGetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamGetError.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamRoles	roles		= Roles to investigate.
		word		*errorCode	= Device-specific error code
						  as set via StreamSetError. Is
						  SerialError for serial 
						  driver, ParallelError for
						  parallel driver, etc.
						

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMGETERROR:far
STREAMGETERROR	proc	far	driver:hptr,
				strm:hptr,
				roles:word,
				retInfo:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, roles
	mov	bx, strm
	mov	di, DR_STREAM_GET_ERROR
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already = StreamError

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], ax			; Return driver-specific
						; error code.
exit:

	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMGETERROR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamSetError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamSetError.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamRoles	roles		= Roles to investigate.
		word		errorCode	= Device-specific error code
						  to set, for later reading
						  via StreamGetError.  Is
						  SerialError for serial 
						  driver, ParallelError for
						  parallel driver, etc.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMSETERROR:far
STREAMSETERROR	proc	far	driver:hptr,
				strm:hptr,
				roles:word,
				errorCode:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall
	; Load up arguments to driver function and invoke it.
	mov	ax, roles
	mov	bx, strm
	mov	cx, errorCode
	mov	di, DR_STREAM_SET_ERROR
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMSETERROR	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamFlush
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamFlush.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		StreamToken	stream		= Stream to muck with.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMFLUSH:far
STREAMFLUSH	proc	far	driver:hptr,
				strm:hptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	bx, strm
	mov	di, DR_STREAM_FLUSH
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMFLUSH	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamSetThreshold
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamSetThreshold.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamRoles	roles		= Roles to investigate.
		word		threshold	= Threshold value (bytes).

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMSETTHRESHOLD:far
STREAMSETTHRESHOLD	proc	far	driver:hptr,
					strm:hptr,
					roles:word,
					threshold:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, roles
	mov	bx, strm
	mov	cx, threshold
	mov	di, DR_STREAM_SET_THRESHOLD
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMSETTHRESHOLD	endp

StreamResident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamRead.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamBlocker	blocker		= Block or not?
		word		buffSize	= Number of bytes to read.
		byte		*buffer		= Where to put bytes read.
		word		*numRead	= Results from driver.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMREAD:far
STREAMREAD	proc	far	driver:hptr,
				strm:hptr,
				blocker:word,
				buffSize:word,
				buffer:fptr,
				retInfo:fptr
	strategy	local	fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall
	movdw	ss:[strategy], ds:[si].DIS_strategy, ax	; Save driver entry.

	; Load up arguments to driver function and invoke it.
	mov	ax, blocker
	mov	bx, strm
	mov	cx, buffSize
	lds	si, buffer
	mov	di, DR_STREAM_READ
	call	{dword} ss:[strategy]		; Do me baby!
	pushf
	jc	exitError			; AX already set.

setReturnVal:
	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], cx			; Return # of bytes read.

exit:
	popf
	call	SCUDoneWithDriverCall
	.leave
	ret

exitError:
        cmp     ax, STREAM_SHORT_READ_WRITE
        je      setReturnVal
        jmp     exit
STREAMREAD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamReadByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamReadByte.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamBlocker	blocker		= Block or not?
		byte		*byteRead	= Results from driver.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMREADBYTE:far
STREAMREADBYTE	proc	far	driver:hptr,
				strm:hptr,
				blocker:word,
				retInfo:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, blocker
	mov	bx, strm
	mov	di, DR_STREAM_READ_BYTE
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], al			; Return byte read in.

exit:

	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMREADBYTE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamWrite.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamBlocker	blocker		= Block or not?
		word		buffSize	= Number of bytes to write.
		byte		*buffer		= Where to put bytes read.
		word		*numWritten	= Results from driver.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMWRITE:far
STREAMWRITE	proc	far	driver:hptr,
				strm:hptr,
				blocker:word,
				buffSize:word,
				buffer:fptr,
				retInfo:fptr
	strategy	local	fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall
	movdw	ss:[strategy], ds:[si].DIS_strategy, ax	; Save driver entry.

	; Load up arguments to driver function and invoke it.
	mov	ax, blocker
	mov	bx, strm
	mov	cx, buffSize
	lds	si, buffer
	mov	di, DR_STREAM_WRITE
	call	{fptr.far} ss:[strategy]	; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], cx			; Return # bytes written.

exit:
	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMWRITE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamWriteByte
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamWriteByte.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamBlocker	blocker		= Block or not?
		byte		dataByte	= Byte to send out.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMWRITEBYTE:far
STREAMWRITEBYTE	proc	far	driver:hptr,
				strm:hptr,
				blocker:word,
				dataByte:word
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, blocker
	mov	bx, strm
	mov	cl, {byte} dataByte
	mov	di, DR_STREAM_WRITE_BYTE
	call	ds:[si].DIS_strategy		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMWRITEBYTE	endp

StreamResident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamQuery.

CALLED BY:	Global.

PASS:		Handle		driver		= Driver to invoke.
		StreamToken	stream		= Stream to muck with.
		StreamRoles	roles		= Roles to investigate.
		word		*bytesAvailable	= Results from driver.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMQUERY:far
STREAMQUERY	proc	far	driver:hptr,
				strm:hptr,
				roles:word,
				retInfo:fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	; Load up arguments to driver function and invoke it.
	mov	ax, roles
	mov	bx, strm
	mov	di, DR_STREAM_QUERY
	call	ds:[si].DIS_strategy		; Do me baby!
	jc	exit				; AX already set.

	; Otherwise, fill in the return values.
	lds	si, retInfo			; DS:SI = *retInfo.
	mov	ds:[si], ax			; Return bytes available.

exit:
	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMQUERY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StreamEscLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	C stub for StreamEscLoadOptions.

CALLED BY:	Global.

PASS:		Handle	driver			= Driver to invoke.
		char	*category		= .INI category string.

RETURN:		StreamError
		NOTE:  StreamError provides no indication of driver-specific
		       errors such as overruns or parity errors.  See
		       StreamSetNotify/StreamGetError for details on fetching
		       this error information.

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

global	STREAMESCLOADOPTIONS:far
STREAMESCLOADOPTIONS	proc	far	driver:hptr,
					category:fptr
	strategy	local	fptr
	.enter

	mov	bx, driver
	call	SCUPrepareForDriverCall

	movdw	ss:[strategy], ds:[si].DIS_strategy, ax	; Save driver entry.

	; Load up arguments to driver function and invoke it.
	lds	si, category	
	mov	di, STREAM_ESC_LOAD_OPTIONS
	call	{dword} ss:[strategy]		; Do me baby!

	call	SCUDoneWithDriverCall
	.leave
	ret
STREAMESCLOADOPTIONS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STREAMSETMESSAGENOTIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request message notification for some event

CALLED BY:	(GLOBAL)
PASS:		driver	= handle of stream driver to call
		strm	= stream/unit token
		note	= StreamNotifyType record indicating event and side
			  requesting notification
		msg	= message to send when event happens
		dest	= object to receive the notification
RETURN:		StreamError -	STREAM_NO_ERROR
				STREAM_CLOSED
				
DESTROYED:	bx, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global STREAMSETMESSAGENOTIFY:far
STREAMSETMESSAGENOTIFY proc	far 	driver:hptr, strm:word,
		       			note:word,
					msg:word, dest:optr
		.enter
		
		mov	bx, ss:[driver]
		call	SCUPrepareForDriverCall
		
		mov	bx, ss:[strm]
		mov	ax, ss:[note]
		clr	ah	; clear ah because BorlandC problems
		ornf	al, SNM_MESSAGE shl offset SNT_HOW
		
		movdw	cxdx, ss:[dest]
		push	bp
		mov	bp, ss:[msg]
		mov	di, DR_STREAM_SET_NOTIFY
		call	ds:[si].DIS_strategy
		pop	bp
		jc	error
		
		mov	ax, ss:[note]
		mov	bx, ss:[driver]
		mov	cx, ss:[strm]
		call	SCStRemoveRoutineNotifier
		
		clc
done:
		call	SCUDoneWithDriverCall
		.leave
		ret

error:
		mov	ax, STREAM_CLOSED
		jmp	done
STREAMSETMESSAGENOTIFY endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STREAMSETNONOTIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off notification for some stream-driver event

CALLED BY:	(GLOBAL)
PASS:		driver	= handle of stream driver to call
		strm	= unit # / stream token
		note	= StreamNotifyType indicating side and event to 
			  shut off.
RETURN:		StreamError
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/23/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global STREAMSETNONOTIFY:far
STREAMSETNONOTIFY proc	far driver:hptr, strm:word, note:word
		.enter
		mov	bx, ss:[driver]
		mov	ax, ss:[note]
		mov	dx, ss:[strm]
		call	SCStSetNoNotify
		.leave
		ret
STREAMSETNONOTIFY endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStSetNoNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		CF = SET on error
		ax = StreamError
			STREAM_NO_ERROR
			STREAM_CLOSED

DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStSetNoNotify	proc	near
		.enter
		call	SCUPrepareForDriverCall
		
		xchg	bx, dx
	CheckHack <SNM_NONE eq 0>
		andnf	al, not mask SNT_HOW
		
		mov	di, DR_STREAM_SET_NOTIFY
		push	ax, bx, dx		; save for nuking callback data
		call	ds:[si].DIS_strategy
		pop	cx, bx, dx
		jc	error
		
		mov_tr	ax, cx			; ax <- StreamNotifyType
		mov	cx, bx			; cx <- stream
		mov	bx, dx			; bx <- driver
		call	SCStRemoveRoutineNotifier
		
		clc
done:
		call	SCUDoneWithDriverCall
		.leave
		ret

error:
		mov	ax, STREAM_CLOSED
		jmp	done

SCStSetNoNotify	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STREAMSETROUTINENOTIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request routine notification for some event

CALLED BY:	(GLOBAL)
PASS:		driver	= handle of stream driver to call
		strm	= stream/unit token
		note	= StreamNotifyType record indicating event and side
			  requesting notification
		cbData	= data to pass to routine
		callback= routine to call. Must be in a fixed resource.
RETURN:		StreamError
DESTROYED:	bx, cx
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	STREAMSETROUTINENOTIFY:far
STREAMSETROUTINENOTIFY proc	far driver:hptr, strm:word, note:word, 
				    cbData:word, callback:fptr.far
ForceRef	cbData	; SCStSetRoutineNotifyCommon
ForceRef	callback; SCStSetRoutineNotifyCommon
		.enter
	;
	; Make sure the callback is in fixed memory, thank you.
	;
		Assert	fptrXIP, ss:[callback]
	;
	; Remove any existing callback record for the driver/unit/event
	;
		mov	bx, ss:[driver]
		mov	ax, ss:[note]
		clr	ah	; clear ah because BorlandC problems
EC <		mov	cx, ax					>
EC <		andnf	cx, mask SNT_EVENT			>
EC <		cmp	cx, SNE_DATA shl offset SNT_EVENT	>
EC <		ERROR_E	DATA_ROUTINE_NOTIFIER_MUST_BE_SET_WITH_StreamSetDataRoutineNotify>
		mov	dx, ss:[strm]
		call	SCStSetNoNotify
		jc	done
		
		mov	cx, offset SCStRoutineCallback
		call	SCStSetRoutineNotifyCommon
done:
		.leave
		ret
STREAMSETROUTINENOTIFY endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStSetRoutineNotifyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a routine notifier for a stream

CALLED BY:	(INTERNAL) STREAMSETROUTINENOTIFY,
			   STREAMSETDATAROUTINENOTIFY
PASS:		cx	= offset of callback routine to use
		ss:bp	= inherited frame
		ds	= DS to give to app callback
RETURN:		ax	= StreamError
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStSetRoutineNotifyCommon proc	near
		uses	es
		.enter	inherit	STREAMSETROUTINENOTIFY
	;
	; Gain exclusive access to the callback list.
	;
		push	ds
		call	SCStGrabList
	;
	; Allocate a record for it.
	;
		mov	dx, bx			; dx <- callbackSem

		mov	ax, size StreamCallbackData
		push	cx
		mov	cx, ALLOC_FIXED or mask HF_SHARABLE
		call	MemAlloc
		pop	cx
		jc	cannotAlloc
	;
	; Link it as the head of the callback record chain.
	;
		mov	es, ax
		mov	es:[SCD_handle], bx
		xchg	ax, ds:[scCallbackList]
		mov	es:[SCD_next], ax
		pop	ax			; ax <- DS from entry
		push	ax
		mov	es:[SCD_ds], ax
		mov	bx, ss:[driver]
		mov	es:[SCD_driver], bx
	;
	; Do the usual prepare-for-driver stuff while we've got BX primed.
	;
		call	SCUPrepareForDriverCall	; ds:si <- DIS
	;
	; Copy the rest of the info into the record.
	;
		mov	bx, ss:[strm]
		mov	es:[SCD_unit], bx
		
		movdw	es:[SCD_callback], ss:[callback], ax
		mov	ax, ss:[cbData]
		mov	es:[SCD_data], ax
		mov	ax, ss:[note]
		andnf	ax, not mask SNT_HOW
		mov	es:[SCD_type], al
	;
	; Now contact the driver to register our front-end as the callback
	; routine.
	;
		ornf	ax, SNM_ROUTINE shl offset SNT_HOW
		push	dx
		mov	dx, cx
		mov	cx, segment SCStRoutineCallback
		mov	bp, es			; bp <- callback receives SCD
						;  segment in AX or CX
						;  (depending on threshold)
		mov	di, DR_STREAM_SET_NOTIFY
		call	ds:[si].DIS_strategy
		pop	dx			; dx <- callback list sem
		jc	undo
doneWithList:
	;
	; Release the callback list.
	;
		mov	bx, dx
		call	ThreadVSem
		call	SCUDoneWithDriverCall
popDSDone:
		pop	ds
		.leave
		ret
cannotAlloc:
		mov	ax, STREAM_CANNOT_ALLOC
		jmp	popDSDone

undo:
	;
	; Couldn't register the notifier, so remove the record from the front
	; of the list and free it before returning the error. Because we've
	; held the semaphore, there's no worry that something else could
	; now be at the front...
	;
		call	SCULoadDGroupDS
		mov	bx, es:[SCD_next]
		mov	ds:[scCallbackList], bx
		mov	bx, es:[SCD_handle]
		call	MemFree
		mov	ax, STREAM_CLOSED
		stc
		jmp	doneWithList
SCStSetRoutineNotifyCommon endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		STREAMSETDATAROUTINENOTIFY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Special routine to set a routine notifier for the SNE_DATA
		event, so we can set the threshold at the same time and
		choose the right callback routine.

CALLED BY:	(GLOBAL)
PASS:		driver	= handle of stream driver to call
		strm	= stream/unit token
		note	= StreamNotifyType record indicating event and side
			  requesting notification
		cbData	= data to pass to routine
		callback= routine to call. Must be in a fixed resource.
		threshold= notification threshold to set (MUST COME AFTER
			   PREVIOUS ARGS SO SCStSetRoutineNotifyCommon CAN WORK)
RETURN:		StreamError
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
global	STREAMSETDATAROUTINENOTIFY:far
STREAMSETDATAROUTINENOTIFY proc	far driver:hptr, strm:word, note:word, 
				    cbData:word, callback:fptr.far,
				    threshold:word
ForceRef	cbData		; SCStSetRoutineNotifyCommon
ForceRef	callback	; SCStSetRoutineNotifyCommon
		.enter
	;
	; Make sure the callback is in fixed memory, thank you.
	;
		Assert	fptrXIP, ss:[callback]
	;
	; Remove any existing callback record for the driver/unit/event.
	; We set the SNE_DATA event in the record to allow the caller to
	; not specify it, since it's indicated by this routine being called.
	;
		mov	bx, ss:[driver]
		mov	ax, ss:[note]
		clr	ah	; clear ah because BorlandC problems
		andnf	ax, not mask SNT_EVENT
		ornf	ax, SNE_DATA shl offset SNT_EVENT
		mov	ss:[note], ax
		mov	dx, ss:[strm]
		call	SCStSetNoNotify
		jc	done
		
	;
	; Set the threshold now, while there's no notifier, so when the notifier
	; is set, the proper parameters get passed.
	;
		mov	bx, ss:[driver]
		call	SCUPrepareForDriverCall
		mov	ax, ss:[note]
		test	ax, mask SNT_READER
		mov	ax, STREAM_READ
		jnz	haveSide
		CheckHack <STREAM_WRITE eq STREAM_READ + 1>
		inc	ax
haveSide:
		mov	bx, ss:[strm]
		mov	cx, ss:[threshold]
		mov	di, DR_STREAM_SET_THRESHOLD
		call	ds:[si].DIS_strategy
		call	SCUDoneWithDriverCall
		jc	done
	;
	; Figure the callback to use from the threshold just set.
	;
		cmp	cx, 1
		mov	cx, offset SCStRoutineCallback
		jne	haveCallback
		mov	cx, offset SCStSpecialRoutineCallback
haveCallback:
		inc	bp
		inc	bp	; skip over threshold arg...
		call	SCStSetRoutineNotifyCommon
done:
		.leave
		ret
STREAMSETDATAROUTINENOTIFY endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStGrabList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to the callback list

CALLED BY:	(INTERNAL)
PASS:		nothing
RETURN:		ds	= dgroup
		bx	= callback semaphore
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStGrabList	proc	near
		uses	ax
		.enter
		call	SCULoadDGroupDS
		mov	bx, ds:[scCallbackSem]
		call	ThreadPSem
		.leave
		ret
SCStGrabList	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStRemoveRoutineNotifier
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the notifier record, if any, for the indicated
		driver/unit/event and delete it

		NOTE: The actual notifier should have been unregistered with
		the driver by this time, so a callback doesn't come in that
		uses the StreamCallbackData block that's about to be freed
		by this routine.

CALLED BY:	(INTERNAL) STREAMSETMESSAGENOTIFY, 
			   STREAMSETNONOTIFY,
			   STREAMSETROUTINENOTIFY
PASS:		ax	= StreamNotifyType
		bx	= driver handle
		cx	= unit # / stream token
RETURN:		carry set if not found
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStRemoveRoutineNotifier proc	near
		uses	dx, ds, es, si
		.enter
		mov	dx, bx
	;
	; Gain exclusive right to traverse the chain.
	;
		call	SCStGrabList
		
	;
	; For the loop:
	; 	ds	= segment of current callback
	; 	ax	= StreamNotifyType to check
	; 	bx	= semaphore (not used, but don't destroy)
	; 	cx	= unit # / stream token
	; 	dx	= driver handle
	; 	es:si	= address of pointer to current callback
	; 
		mov	si, offset scCallbackList
		andnf	ax, not mask SNT_HOW	; don't compare SNT_HOW
						;  fields, please.
findLoop:
		segmov	es, ds
		tst	{sptr}ds:[si]
		jz	notFound
		mov	ds, {sptr}ds:[si]
		cmp	ds:[SCD_driver], dx	; same driver?
		jne	next
		cmp	ds:[SCD_unit], cx	; same unit/stream ?
		jne	next
		cmp	ds:[SCD_type], al	; same event & side?
		je	found
next:
		mov	si, offset SCD_next	; es:si <- location of pointer
						;  to next (es loaded at top of
						;  loop)
		jmp	findLoop

found:
	;
	; Unlink this callback from the list.
	;
		mov	dx, ds:[SCD_next]
		mov	es:[si], dx
	;
	; Free the callback data block.
	;
		mov	dx, bx			; save semaphore handle
		mov	bx, ds:[SCD_handle]
		call	MemFree
		mov	bx, dx

		clc				; signal found
done:
	;
	; Release list access.
	;
		call	ThreadVSem		
		.leave
		ret

notFound:
		stc
		jmp	done
SCStRemoveRoutineNotifier endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStBeginClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin the process of closing down a stream, unlinking any
		callback blocks from the list, but *not* freeing them
		until the close is successful.
		
		Caller must call SCStFinishClose at the end, passing error
		flag and the returned AX

CALLED BY:	(EXTERNAL)
PASS:		bx	= driver
		ax	= unit
RETURN:		ax	= head of callback list to be freed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStBeginClose	proc	far
		uses	ds, si, es, cx, dx, di
		.enter
	;
	; Gain exclusive access to the callback list.
	;
		mov	si, bx			; si <- driver handle, for
						;  comparison
		call	SCStGrabList
	;
	; For the loop:
	; 	ds:bx	= previous callback
	; 	es	= current callback
	; 	cx	= current callback
	; 	si	= driver handle for comparison
	; 	ax	= unit # for comparison
	; 	dx	= head of callback list to be freed
	;
		push	bx
		mov	bx, offset scCallbackList - offset SCD_next
		clr	dx
callbackLoop:
	;
	; Fetch next callback from the list and break if none.
	;
		mov	cx, ds:[bx].SCD_next
		jcxz	done
	;
	; See if callback is for this unit of the driver.
	;
		mov	es, cx
		cmp	es:[SCD_driver], si
		jne	next
		cmp	es:[SCD_unit], ax
		jne	next
	;
	; It is. Unlink the callback from the list.
	;
		mov	di, es:[SCD_next]
		mov	ds:[bx].SCD_next, di
	;
	; Place callback at the head of the list to be returned.
	;
		mov	es:[SCD_next], dx
		mov	dx, es
		jmp	callbackLoop

next:
	;
	; Point ds:bx to this callback and loop to examine the next.
	;
		mov	ds, cx
		clr	bx
		jmp	callbackLoop

done:
	;
	; Release the callback list and return the now-detached list we found.
	;
		mov_tr	ax, dx
		pop	bx
		call	ThreadVSem
		mov	bx, si			; bx <- driver handle, again
						;  (same size & faster than
						;  push/pop...)
		.leave
		ret
SCStBeginClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStFinishClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish a close operation, freeing the callbacks (we assume
		since the stream is closed, there's no use for them now) or
		linking them back in (if the stream couldn't be closed)

CALLED BY:	(EXTERNAL)
PASS:		carry set if couldn't close stream
			bx	= head of callback list to relink
		carry clear if stream closed
			bx	= head of callback list to free
RETURN:		nothing
DESTROYED:	bx (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/ 1/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStFinishClose	proc	far
		uses	ds
		.enter
		pushf
		jc	relink
	;
	; Want to free the blocks, now the stream is closed.
	;
freeLoop:
		tst	bx
		jz	done			; => hit end of list
		mov	ds, bx
		push	ds:[SCD_next]		; save segment of next
		mov	bx, ds:[SCD_handle]	; bx <- block handle
		call	MemFree
		pop	bx
		jmp	freeLoop
done:
		popf
		.leave
		ret

relink:
	;
	; Find the end of the passed chain, so we can link the current
	; list head to it.
	;
		push	cx, es
		mov	cx, bx
		jcxz	relinkDone

		call	SCStGrabList

		mov	es, cx			; es <- current callback
relinkLoop:
		tst	es:[SCD_next]
		jz	haveEnd			; => es is last one
		mov	es, es:[SCD_next]
		jmp	relinkLoop

haveEnd:
	;
	; Set head of list to head of passed list (still in CX)
	;
		xchg	ds:[scCallbackList], cx
	;
	; Point tail of list to previous head.
	;
		mov	es:[SCD_next], cx

		call	ThreadVSem
relinkDone:
		pop	cx, es
		jmp	done
SCStFinishClose	endp

StreamCStream	ends

StreamResident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStRoutineCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end for routine notification

CALLED BY:	stream driver
PASS:		ax	= StreamCallbackData segment
		cx	= something interesting
		bp	= something interesting
RETURN:		for everything but special data notifiers:
			nothing
		for special read notifier:
			carry set if byte consumed
		for special write notifier:
			carry set if new byte returned:
				al	= new byte
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStRoutineCallback proc	far
		uses	ds, ax, bx, cx, dx, es
		.enter
		mov	es, ax
		
		push	es:[SCD_data]
		push	cx
		push	bp
		mov	ds, es:[SCD_ds]
		call	es:[SCD_callback]
		
		.leave
		ret
SCStRoutineCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SCStSpecialRoutineCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Front-end routine for special data notification

CALLED BY:	(GLOBAL) stream driver
PASS:		bp	= STREAM_READ/STREAM_WRITE
		cx	= StreamCallbackData segment
		for read:
			al	= byte read
RETURN:		for read:
			carry set if byte consumed
		for write:
			carry set if new byte returned:
				al	= byte to write
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SCStSpecialRoutineCallback proc	far
		uses	ds, bx, cx, dx, es
		.enter
		mov	es, cx
		push	es:[SCD_data]		; pass data word
		push	ax			; and char, if read (junk if
						;  write)
		push	bp			; pass flag
		call	es:[SCD_callback]	; always call routine

		cmp	bp, STREAM_READ
		je	checkRead		; => check AX for true/false

		tst_clc	ah			; character returned for write?
		jz	done			; => no
carrySet:
		stc				; else flag char in AL
done:
		.leave
		ret
checkRead:
		tst_clc	ax			; char consumed?
		jnz	carrySet		; => yes
		jmp	done
SCStSpecialRoutineCallback endp

StreamResident	ends


	SetDefaultConvention
