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
include system.def		; SysMapRealSegment (PM restart support)
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


;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------
HOST_API_INTERRUPT 	equ 	0xA0
MAX_ASYNC_OP_SLOTS	equ	16

;
; The host (basebox) raises HOST_API_INTERRUPT whenever it queues an event,
; and it offers no way to stop doing so. Once our handler is gone, the
; interrupt ends up in the real mode vector (the DPMI host reflects it
; there), which DOSBox leaves at 0000:0000. We point it at the BIOS dummy
; interrupt handler instead, an IRET at F000:FF53 (IBM BIOS convention,
; also provided by DOSBox).
;
IRET_STUB_SEGMENT	equ	0f000h
IRET_STUB_OFFSET	equ	0ff53h
IRET_OPCODE		equ	0cfh

if ERROR_CHECK
HOSTIF_ASYNC_RESULT_WITHOUT_WAITER			enum	Warnings
endif

AsyncSlotData		struct
ASD_registers		word 6 dup (?)
ASD_semaphore		Semaphore
AsyncSlotData		ends


;------------------------------------------------------------------------------
;			Process class
;------------------------------------------------------------------------------
HostIfProcessClass	class	ProcessClass

MSG_HOSTIF_PROCESS_EVENTS	message

HostIfProcessClass	endc


;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------
idata   segment

	asyncOpSem	Semaphore <1, 0>

	asyncOpTable	fptr MAX_ASYNC_OP_SLOTS dup (0)

	oldIntVec	fptr 0

idata   ends

;-----
udata   segment

    	hostIfGeode		hptr
	hostIfDetached		BooleanByte	; set once HostIfShutdown has
						;  unhooked the event interrupt
	hostIfPresent		BooleanByte	; host interface detected and
						;  event interrupt registered

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

EC <	call	ECCheckStack						>

	cld					;clear direction flag
	INT_ON

	segmov	ds, dgroup
	;
	; The host can still raise the event interrupt while we are going
	; away (e.g. socket state changes of connections that are still
	; open). Don't send to a process that is detaching.
	;
	tst	ds:hostIfDetached
	jnz	done
	mov	bx, ds:hostIfGeode

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

	;
	; A result for a slot nobody is waiting on (e.g. a stale result of a
	; previous system incarnation before a restart) is dropped.
	;
	mov	bp, ds:asyncOpTable[si].offset
	mov	ax, ds:asyncOpTable[si].segment
	tst	ax
	jz	noWaiter
	mov	ds, ax
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

noWaiter:
EC <	WARNING	HOSTIF_ASYNC_RESULT_WITHOUT_WAITER			>
	pop	ax, cx, si
	pop	ds, bp
	jmp	eventLoop

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
	; Without a host interface there are no events to handle.
	;
		mov	ax, HIF_API_HOST
		call	HostIfDetect
		tst	ax
		jz	done
	;
	; Make sure a host event that arrives after we are gone lands on an
	; IRET rather than on 0000:0000.
	;
		call	HostIfGuardRealModeVector
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
	; Drop events still queued by the host from a previous incarnation
	; (system restart). The host raises the event interrupt only when its
	; queue changes from empty to non-empty, so left-over events would keep
	; us from ever being notified again.
	;
		call	HostIfDrainEvents
	;
	; Register event interrupt
	;
		mov	ax, HIF_SET_EVENT_INTERRUPT
		call	HostIfCall

		segmov	ds, dgroup, ax
		mov	ds:hostIfPresent, BB_TRUE
done:
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
	;
	; Normally HostIfShutdown has already been called by our client
	; driver at system exit (a library process is not detached then).
	; Doing it here as well covers the library actually being unloaded.
	;
		call	HostIfShutdown

	.leave
	mov	di, offset HostIfProcessClass
	call	ObjCallSuperNoLock

	ret
HostIfDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop handling host events for good: unhook the event
		interrupt and discard all events still queued by the host.

CALLED BY:	GLOBAL. Client drivers that stay loaded until system exit
		(the video driver, from DR_EXIT) must call this, because
		HostIf's process is not detached when the system shuts down.
		HostIfDetach.
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		The host cannot be told to stop raising HOST_API_INTERRUPT.
		So:
		- set hostIfDetached, so a late interrupt no longer posts
		  to our (possibly gone) process,
		- put the previous vector back; together with the IRET in the
		  real mode vector (HostIfGuardRealModeVector) a host event
		  after this is harmless, also after a system restart or
		  after exiting to DOS,
		- drain the host's event queue, so the next incarnation gets
		  notified again (the host only raises the interrupt when the
		  queue changes from empty to non-empty).
		Asynchronous host operations can not complete after this.
		Safe to call more than once.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		2026		Initial version (#665)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfShutdown	proc	far
		uses	ax, di, ds, es
		.enter
		segmov	ds, dgroup, ax
		tst	ds:hostIfDetached
		jnz	done
		mov	ds:hostIfDetached, BB_TRUE

		tst	ds:oldIntVec.segment
		jz	notHooked
		segmov	es, ds
		mov	di, offset oldIntVec
		mov	ax, HOST_API_INTERRUPT
		call	SysResetInterrupt
		clrdw	ds:oldIntVec
notHooked:
		tst	ds:hostIfPresent
		jz	done
		call	HostIfDrainEvents
done:
		.leave
		ret
HostIfShutdown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfGuardRealModeVector
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point the real mode HOST_API_INTERRUPT vector at an IRET,
		unless it is already set.

CALLED BY:	HostIfAttach
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		In protected mode the DPMI host reflects an interrupt nobody
		handles in protected mode to the real mode vector. DOSBox only
		initializes vectors 00h-5Fh and 68h-6Fh, so A0h is 0000:0000.
		Use the BIOS dummy interrupt handler (an IRET at F000:FF53),
		after checking the IRET really is there. The vector is left
		that way when we exit; it is harmless.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		2026		Initial version (#665)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfGuardRealModeVector	proc	near
		uses	ax, bx, cx, dx, es
		.enter
ifdef PROTECTED_MODE
		mov	bl, HOST_API_INTERRUPT
		mov	ax, 0200h		; DPMI: get real mode interrupt vector
		int	31h			; cx:dx <- vector
		jc	done
		or	cx, dx
		jnz	done			; already set, leave it alone
	;
	; Make sure there is an IRET at the stub address.
	;
		mov	ax, IRET_STUB_SEGMENT
		mov	cx, 0ffffh
		call	SysMapRealSegment	; ax <- selector
		mov	es, ax
		mov	bl, es:[IRET_STUB_OFFSET]
		segmov	es, ds			; don't keep the selector loaded
		call	SysUnmapRealSegment
		cmp	bl, IRET_OPCODE
		jne	done

		mov	bl, HOST_API_INTERRUPT
		mov	cx, IRET_STUB_SEGMENT
		mov	dx, IRET_STUB_OFFSET
		mov	ax, 0201h		; DPMI: set real mode interrupt vector
		int	31h
else
		clr	ax
		mov	es, ax
		mov	ax, es:[HOST_API_INTERRUPT*4].offset
		or	ax, es:[HOST_API_INTERRUPT*4].segment
		jnz	done			; already set, leave it alone
		mov	ax, IRET_STUB_SEGMENT
		mov	es, ax
		cmp	{byte} es:[IRET_STUB_OFFSET], IRET_OPCODE
		jne	done
		clr	ax
		mov	es, ax
		INT_OFF
		mov	es:[HOST_API_INTERRUPT*4].offset, IRET_STUB_OFFSET
		mov	es:[HOST_API_INTERRUPT*4].segment, IRET_STUB_SEGMENT
		INT_ON
endif
done:
		.leave
		ret
HostIfGuardRealModeVector	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostIfDrainEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch and discard all events queued by the host.

CALLED BY:	HostIfAttach, HostIfShutdown
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		HIF_GET_EVENT until HIF_NOT_FOUND. Bounded, in case the host
		keeps producing events.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
		2026		Initial version (#665)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostIfDrainEvents	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
		mov	bp, 256			; upper bound
drainLoop:
		mov	ax, HIF_GET_EVENT
		push	bp
		call	HostIfCall
		pop	bp
		cmp	ax, HIF_NOT_FOUND
		je	done
		dec	bp
		jnz	drainLoop
done:
		.leave
		ret
HostIfDrainEvents	endp


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

HOSTIFDETECT	proc	far 	apiid:word	
		.enter
		mov	ax, apiid
		.leave
		GOTO	HostIfDetect
HOSTIFDETECT	endp

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

		.leave
	
		ret

HOSTIFCALL		endp

	SetDefaultConvention

Code	ends


