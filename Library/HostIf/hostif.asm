COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2023 -- All Rights Reserved

PROJECT:	Host Interface Library
FILE:		hostif.asm

AUTHOR:		Falk Rehwagen, Dec 21, 2023

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	fr	12/21/23	Initial revision

DESCRIPTION:
	

	$Id: hostif.asm,v 1.1 97/04/05 01:06:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;------------------------------------------------------------------------------
;			Include files
;------------------------------------------------------------------------------

include geos.def
include ec.def
include heap.def
include geode.def
include resource.def
include library.def
include ec.def
include vm.def
include dbase.def
include file.def
include gcnlist.def
include sem.def

include object.def
include graphics.def
include thread.def
include gstring.def
include Objects/inputC.def

include Objects/winC.def

include Internal/interrup.def
include Internal/im.def
include Internal/heapInt.def

DefLib hostif.def

HOST_API_INTERRUPT 	equ 	0xA0
MAX_ASYNC_OP_SLOTS	equ	16

AsyncSlotData		struct
ASD_registers		word 6 dup (?)
ASD_semaphore		Semaphore
AsyncSlotData		ends


HostIfProcessClass	class	ProcessClass

MSG_HOSTIF_PROCESS_EVENTS	message

HostIfProcessClass	endc

idata   segment

	asyncOpSem	Semaphore <1, 0>

	asyncOpTable	fptr MAX_ASYNC_OP_SLOTS dup (0)

	oldIntVec	fptr 0

idata   ends


udata   segment

    	hostIfGeode		hptr

udata   ends


Resident	segment	resource

HostIfProcessClass	mask CLASSF_NEVER_SAVED


COMMENT @----------------------------------------------------------------------

FUNCTION:	HostIfInterrupt

DESCRIPTION:	Host interface callback service routine.

CALLED BY:	INT A0h (HOST_API_INTERRUPT)

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	4/6/25		Initial version

------------------------------------------------------------------------------@
HostIfInterrupt	proc	far
	call	SysEnterInterrupt		; disable context switching

	;pushf
	push	ax, bx, cx, dx, si, di, bp, ds, es

EC <		call	ECCheckStack						>

if	ERROR_CHECK
	mov	ax, TGIT_THREAD_HANDLE
	clr	bx				; get current thread handle
	call	ThreadGetInfo
	cmp	bx, 0
	jnz	done
	;
	; In the case here where we have big local variables, We want to
	; check stack space before .enter ourselves.  Otherwise if we use
	; ECCheckStack after .enter, it won't give a valid backtrace when
	; sp has wrapped around.  --- AY 2/19/97
	;
	push	ax
	mov	ax, ss:[TPD_stackBot]
	add	ax, 100
					; offset of bottom-most local variable
	cmp	ax, sp
	ERROR_AE -1
	pop	ax
endif	; ERROR_CHECK

	cld					;clear direction flag
	INT_ON

	segmov	ds, dgroup
	mov		bx, ds:hostIfGeode

	;mov_trash	ax, bx
	mov	ax, MSG_HOSTIF_PROCESS_EVENTS
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	pop	ax, bx, cx, dx, si, di, bp, ds, es
	;popf
	call	SysExitInterrupt
	iret

HostIfInterrupt	endp


Resident	ends

Code	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfProcEventProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signs up for the DHCP GCN list.

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfProcEventProcess	method dynamic HostIfProcessClass, 
					MSG_HOSTIF_PROCESS_EVENTS
	.enter

	;
	; process all host event
	;
eventLoop:
	mov	ax, HIF_GET_EVENT
	call	HostIfCall

	cmp	ax, HIF_NOT_FOUND
	je	done

	cmp	ax, HIF_EVENT_NOTIFICATION
	je	doEvent

	; handle async op result
	push	ds, bp
	segmov	ds, dgroup

	push	ax, cx, si
	mov	cl, ah
	clr	ch
	shl	cx
	shl	cx
	mov	si, cx

EC <	mov	ax, ds:asyncOpTable[si].offset 				>
EC <	or 	ax, ds:asyncOpTable[si].segment				>
EC <	ERROR_Z -1							>

	mov	bp, ds:asyncOpTable[si].offset
	mov	ds, ds:asyncOpTable[si].segment
	pop	ax, cx, si

	mov	ds:[bp].ASD_registers, ax
	mov	ds:[bp+2].ASD_registers, si
	mov	ds:[bp+4].ASD_registers, bx
	mov	ds:[bp+6].ASD_registers, cx
	mov	ds:[bp+8].ASD_registers, dx
	mov	ds:[bp+10].ASD_registers, di

	VSem	ds, [bp].ASD_semaphore

	pop	ds, bp
	jmp eventLoop

doEvent:
	; Record the message
	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_HOST_DISPLAY_SIZE_CHANGE
	cmp	si, HIF_NOTIFY_DISPLAY_SIZE_CHANGE
	je	useType
	mov	dx, GWNT_HOST_SOCKET_STATE_CHANGE
useType:
	mov	di, mask MF_RECORD
	call	ObjMessage

	; Send it to the GCN list
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_HOST_NOTIFICATIONS
	mov	cx, di		; event handle
	clr	dx		; no additional block sent
				; not set status flag
	mov	bp, mask GCNLSF_FORCE_QUEUE
	call	GCNListSend

	jmp	eventLoop
done:

	.leave
	ret
HostIfProcEventProcess	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfAttach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Signs up for the DHCP GCN list.

CALLED BY:	MSG_META_ATTACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfAttach	method dynamic HostIfProcessClass, 
					MSG_META_ATTACH
	.enter

	; Commenting this out cuz it causes a crash. There is no default
	; handler for this message, so we won't worry about it.
		mov	di, offset HostIfProcessClass
		call	ObjCallSuperNoLock

		push	ds
		segmov	ds, dgroup
		segmov	cx, cs
		call	MemSegmentToHandle	;cx = handle

		mov	bx, cx
		call	MemOwner

		mov	ds:hostIfGeode, bx

		pop		ds
	; 
	; Setup interrupt handle
	;
		segmov	es, ds
		mov	di, offset oldIntVec

		mov	ax, HOST_API_INTERRUPT
		mov	bx, segment HostIfInterrupt		
		mov	cx, offset HostIfInterrupt	; bx:cx <- fptr of my handler
		call	SysCatchInterrupt

	;
	; Register event interrupt
	;
		mov	ax, HIF_SET_EVENT_INTERRUPT
		call	HostIfCall

	.leave
	ret
HostIfAttach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove self from GCN list

CALLED BY:	MSG_META_DETACH

PASS:		*ds:si	= EtherProcessClass object
		ds:di	= EtherProcessClass instance data
		ds:bx	= EtherProcessClass object (same as *ds:si)
		es 	= segment of EtherProcessClass
		ax	= message #
RETURN:		
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	7/03/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfDetach	method dynamic HostIfProcessClass, 
					MSG_META_DETACH
	uses	ax, bx, cx, dx
	.enter

	.leave
	mov	di, offset HostIfProcessClass
	call	ObjCallSuperNoLock

	ret
HostIfDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if host side API is available and in case it is
		what version is supported.

CALLED BY:	GLOBAL
PASS:		ax - API ID of interest
RETURN:		ax - interface version, 0 mean no host interface found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	12/21/23   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.ioenable

	SetGeosConvention

baseboxID	byte 	"XOBESAB2"

HostIfDetect	proc	far
		uses	bx, cx, dx, si, di

		.enter

		mov	si, ax		; API ID
		mov	ax, HIF_API_CHECK
		call	HostIfCall

		cmp	ax, HIF_OK
		jne	failed
		cmp	si, {word} cs:baseboxID
		jne	failed
		cmp	bx, {word} cs:baseboxID[2]
		jne	failed
		cmp	cx, {word} cs:baseboxID[4]
		jne	failed
		cmp	dx, {word} cs:baseboxID[6]
		jne	failed

		mov	ax, di
done:
		.leave
		ret

failed:
		clr	ax
		jmp	done

HostIfDetect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDetect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if host side API is available and in case it is
		what version is supported.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		ax - interface version, 0 mean no host interface found
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	12/21/23   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

HOSTIFDETECT	proc	far 	apiid:word	
		.enter
		mov	ax, apiid
		.leave
		GOTO	HostIfDetect
HOSTIFDETECT	endp

HostIfCall	proc	far

		push	ds
		segmov	ds, dgroup

		push	bp
		mov	bp, dx

		mov	dx, 38FFh

		; interrupts off
		INT_OFF

		; ping/pong request/response record exchange
		push	ax
		in	ax, dx
		pop	ax

		; send request data
		out	dx, ax
		mov	ax, si
		out	dx, ax
		mov	ax, bx
		out	dx, ax
		mov	ax, cx
		out	dx, ax
		mov	ax, bp
		out	dx, ax

		PSem	ds, asyncOpSem, TRASH_AX_BX

		mov	ax, di
		out	dx, ax

		; receive response data
		in	ax, dx		; di
		mov	di, ax 
		in	ax, dx		; dx
		mov	bp, ax
		in	ax, dx		; cx
		mov	cx, ax
		in	ax, dx		; bx
		mov	bx, ax
		in	ax, dx		; si
		mov	si, ax
		in	ax, dx

		; interrupts on
		INT_ON

		mov	dx, bp
		pop	bp

		cmp	al, HIF_PENDING	
		jne	doneSync

		; handle async operation here
asyncOp:
		push	bp
		sub	sp, AsyncSlotData
		mov	bp, sp				; structure => SS:BP

		mov	ss:[bp].ASD_semaphore.Sem_value, 0
		mov	ss:[bp].ASD_semaphore.Sem_queue, 0

		; register slot
		; ss:bp - ptr to AsyncSlotData struct on stack
		; si    - slot number
		mov	cl, ah
		mov	ch, 0
		shl	cx
		shl	cx
		push	cx
		mov	si, cx
		clrdw	ds:asyncOpTable[si]

		mov	{word} ds:asyncOpTable[si].segment, ss
		mov	{word} ds:asyncOpTable[si].offset, bp

		; unlock slot table access
		VSem	ds, asyncOpSem

		; wait for async op endind
		PSem	ss, [bp].ASD_semaphore

		PSem	ds, asyncOpSem, TRASH_AX_BX

		; fetch async result
		mov	ax, ss:[bp].ASD_registers
		mov	si, ss:[bp+2].ASD_registers
		mov	bx, ss:[bp+4].ASD_registers
		mov	cx, ss:[bp+6].ASD_registers
		mov	dx, ss:[bp+8].ASD_registers
		mov	di, ss:[bp+10].ASD_registers

		; unlock slot
		pop	bp
		clrdw	ds:asyncOpTable[bp]


		; free slot data struct
		add	sp, AsyncSlotData

		;PSem	ds, asyncOpSem

		;jmp	done
		pop	bp

doneSync:	VSem	ds, asyncOpSem

;done:
		pop	ds
		ret


HostIfCall	endp

HOSTIFCALL		proc	far	func:word, 
					data1:dword, 
					data2:dword, 
					data3:word	
		uses	di, si, cx, bx

		.enter
		
		mov	di, data3
		mov	dx, data2.high
		mov	cx, data2.low
		mov	bx, data1.high
		mov	si, data1.low

		mov	ax, func
		
		call 	HostIfCall
		;int	HOST_API_INTERRUPT

		.leave
		
		ret

HOSTIFCALL		endp


HostIfAsyncCallbackData	struct
	; input
	HIACD_callback		fptr
	HIACD_semaphore		word
	
	; output
	HIACD_result		word
HostIfAsyncCallbackData	ends

HostIfCallbackHandler	proc	far

EC <		call	ECCheckStack						>

		mov	ds:[si].HIACD_result, ax
		inc	ds:[si].HIACD_semaphore
			
		ret
			
HostIfCallbackHandler	endp


HostIfCallAsync	proc	far

callbackData	local	HostIfAsyncCallbackData

		.enter
		
		; init  callback structure
		mov	callbackData.HIACD_callback.segment, cs
		mov	callbackData.HIACD_callback.offset, offset cs:HostIfCallbackHandler
		mov	callbackData.HIACD_semaphore, 0
		
		; ss:bp beeing passed as point to callback results structure
		push	bp
		lea	bp, callbackData
		
		int	HOST_API_INTERRUPT
		pop	bp

		; for doe semaphore to get a trigger
waitHere:
                cmp     callbackData.HIACD_semaphore, 0
                je      waitHere

		mov	ax, callbackData.HIACD_result

		; wait for result available
		.leave
		ret

HostIfCallAsync	endp

HOSTIFCALLASYNC		proc	far	func:word, 
					data1:dword, 
					data2:dword, 
					data3:word	
		uses	di, si, cx, bx

		.enter
		
		mov	di, data3
		mov	dx, data2.high
		mov	cx, data2.low
		mov	bx, data1.high
		mov	si, data1.low

		mov	ax, func
		
		int	HOST_API_INTERRUPT

		; wait for result available

		.leave
		
		ret

HOSTIFCALLASYNC		endp

	SetDefaultConvention

Code	ends


