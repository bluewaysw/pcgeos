COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		processCustom.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/28/92   	Initial version.

DESCRIPTION:
	

	$Id: processCustom.asm,v 1.1 97/04/07 11:11:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrintInit	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyCustomPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyCustomPort	proc near
		clc
		ret
VerifyCustomPort	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitCustomPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass initialization parameters to the stream driver

CALLED BY:	InitPrinterPort

PASS:		stack frame inherited from SpoolerLoop

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitCustomPort	proc near
		uses	ax,bx,cx,dx,di,si,bp

curJob		local	SpoolJobInfo	; all we need to process this job
		.enter	inherit

		;
		; Have the stream driver load its options
		;

		push	ds			; dgroup
		segmov	ds, ss
		lea	si, curJob.SJI_info.JP_printerName
		mov	di, STREAM_ESC_LOAD_OPTIONS
		call	curJob.SJI_stream
		pop	ds	

	; open the port
		
tryOpen:
	; copy the port data into a block to pass in BX
		mov	ax, size CPP_info
		mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
		call	MemAlloc
		
		push	es, ds
		mov	es, ax
		lea	si, customParams.CPP_info
		segmov	ds, ss
		clr	di
		mov	cx, size CPP_info/2
		rep	movsw
	if size CPP_info and 1
		movsb
	endif
		pop	es, ds
		call	MemUnlock
		
		push	bx

	; assume DR_STREAM_OPEN will fail
		mov	customParams.CPP_unit, -1

		mov	dx, SPOOL_PARALLEL_BUFFER_SIZE
		mov	di, DR_STREAM_OPEN
		mov	ax, mask SOF_NOBLOCK
		push	bp
		call	curJob.SJI_stream	; open the port
		pop	bp
		
		pop	cx
		push	bx
		pushf
		mov	bx, cx
		call	MemFree
		popf
		pop	bx

		jnc	portOK
		mov	cx, PERROR_PARALLEL_ERR
		mov	dx, curJob.SJI_qHan
		call	SpoolErrorBox		; signal problem
		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK
		je	tryOpen			; if not cancelling...
		mov	ax, PE_PORT_NOT_OPENED	; otherwise signal error type
		stc
		jmp	done

portOK:
		mov	customParams.CPP_unit, bx

		; set the error notification mechanism

		push	bp			; save frame pointer
		mov	di, DR_STREAM_SET_NOTIFY
		mov	ax, StreamNotifyType <0, SNE_ERROR, SNM_ROUTINE>
		mov	cx, dgroup
		mov	dx, offset dgroup:StreamErrorHandler
		lea	si, curJob.SJI_stream
		mov	bp, curJob.SJI_qHan	; value to pass in ax
		call	{fptr.far}ss:[si]	; call to driver
		pop	bp

	;
	; now set the connection info for the printer driver
	;
		mov	di, DR_PRINT_SET_STREAM
		mov	cx, bx
		mov	si, curJob.SJI_info.JP_portInfo.PPI_type
		mov	dx, curJob.SJI_sHan	; pass stream handle
		mov	bx, curJob.SJI_pstate
		call	curJob.SJI_pDriver
		clc				; signal no problem

		; all done
done:


	.leave
	ret
InitCustomPort	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExitCustomPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the custom port

CALLED BY:	SpoolerLoop

PASS:		ss:bp - inherited local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	9/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExitCustomPort	proc near

curJob		local	SpoolJobInfo	; all we need to process this job
		.enter	inherit

	;
	; close the port
	;
		mov	bx, customParams.CPP_unit
		cmp	bx, -1
		je	exit
	;
	; check if we should kill (user cancel) or flush (otherwise)
	; pending data
	;
if _KILL_CUSTOM_PORT_DATA_ON_CANCEL
		push	ds, si
		call	LockQueue
		mov	ds, ax
		mov	si, curJob.SJI_qHan
		mov	si, ds:[si]
		cmp	ds:[si].QI_error, SI_ABORT
		pushf
		call	UnlockQueue
		popf
		pop	ds, si
endif

		mov	di, DR_STREAM_CLOSE
		mov	ax, STREAM_LINGER
if _KILL_CUSTOM_PORT_DATA_ON_CANCEL
		jne	linger			; not abort, flush data
		mov	ax, STREAM_DISCARD	; else, discard data
linger:
endif
		push	bp
		call	curJob.SJI_stream
		pop	bp
exit:
		.leave
		ret
ExitCustomPort	endp

PrintInit	ends


PrintError	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ErrorCustomPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle errors from the custom port

CALLED BY:	custom driver via StreamErrorHandler

PASS:		ds	- segment of locked queue segment
		*ds:si	- pointer to queue that is affected
		dx	- error word (PrinterError from printDr.def)


RETURN:		carry set if print job should abort
		ds - fixed up if necessary

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Copied from ErrorParallelPort with barely any understanding of
	what I'm doing.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/ 9/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ErrorCustomPort proc	near
		uses	ax,bx,cx,di,es
		.enter	
		mov	cx, dx
		call	UnlockQueue			; release the queue
		mov	dx, si				; dx = queue handle
		call	SpoolErrorBox
		push	ax				; save error code
		call	LockQueue			; get queue back, since
		mov	ds, ax				; caller expects it 
		pop	ax				; restore error code

	; check to see what to do...

		TestUserStandardDialogResponses	SPOOL_BAD_USER_STANDARD_DIALOG_RESPONSE, IC_OK, IC_DISMISS
		cmp	ax, IC_OK			; should we abort?
		je	doRestart			;  no, continue

	; the user has decided to call it quits.  Close down the
	; port and let the spooler handle all the errors generated.
		
abort:
		mov	bx, ds:[si]			; deref queue handle
		mov	ds:[bx].QI_error, SI_ABORT	; signal abort

	; close the port

		call	CloseCustomPort
		stc					; set error flag
done:
		.leave
		ret

doRestart:
		push	si
		mov	si, ds:[si]
		mov	ax, ds:[si].QI_resend
		les	si, ds:[si].QI_threadInfo
		mov	bx, es:[si].SJI_info.JP_portInfo.PPI_params.PP_custom.CPP_unit
		mov	di, STREAM_ESC_RESTART_OUTPUT
		call	es:[si].SJI_stream
		pop	si
		jc	abort
		jmp	done
ErrorCustomPort endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseCustomPort
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the custom port

CALLED BY:	CloseCustomPortFar, ErrorCustomPort, CommPortErrorHandler

PASS:		*ds:si	- QueueInfo

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	8/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CloseCustomPort	proc near
		uses	bx,di,ax,dx, si, es

		.enter

		mov	si, ds:[si]
		les	si, ds:[si].QI_threadInfo
		mov	bx, es:[si].SJI_info.JP_portInfo.PPI_params.PP_custom.CPP_unit
		mov	di, DR_STREAM_CLOSE		; close the port
		mov	ax, STREAM_DISCARD		; kill the data
		call	es:[si].SJI_stream		; signal the driver
		.leave
		ret
CloseCustomPort	endp



PrintError	ends
