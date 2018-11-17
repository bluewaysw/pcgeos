COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeEvent.asm

ROUTINES:
	Name				Description
	----				-----------
   GLB  ObjProcBroadcastMessage		Send an event to all processes.
   GLB	ObjMessage			Send an message

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version
	Tony	10/88		Comments from Doug's code review added

DESCRIPTION:
	This file contains the routines to send events.

	$Id: geodesEvent.asm,v 1.1 97/04/05 01:12:12 newdeal Exp $

-------------------------------------------------------------------------------@
GLoad	segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeAllocQueue

DESCRIPTION:	Allocate an event queue

CALLED BY:	GLOBAL

PASS:
	none

RETURN:
	bx - handle of queue

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

GeodeAllocQueue	proc	far
	push	ds

	LoadVarSeg	ds
	mov	bx, ss:[TPD_processHandle]
	call	MemIntAllocHandle
	mov	ds:[bx].HQ_handleSig,SIG_QUEUE

	pop	ds
	ret

GeodeAllocQueue	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeFlushQueue

DESCRIPTION:	Flush all events in one queue to another queue, synchronously.

CALLED BY:	GLOBAL

PASS:
	bx - handle of queue to flush
	si - handle of destination queue

	cx:dx	- OD to send any event to which was previously destined for
		  the method table of the thread reading the source queue
		  (To specify the method table of the thread reading
		  the destination queue pass the destination queue
	 	   handle in cx)
	di - MessageFlags -- Only the following requests apply:
		MF_INSERT_AT_FRONT - set to flush source queue's events to the
				     front of the destination queue.  If clear,
				     events are placed at the back.

RETURN:
	Nothing

DESTROYED:
	Nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/90		Initial version
------------------------------------------------------------------------------@
GeodeFlushQueue	proc	far	uses	ax, cx, di, ds
	.enter
	LoadVarSeg	ds

EC <	call	ECCheckQueueHandle				>
EC <	xchg	bx, si						>
EC <	call	ECCheckQueueHandle				>
EC <	xchg	bx, si						>

	call	SysEnterCritical	; No context switches, please.

	INT_OFF
				
	; First, if the source queue is empty (semaphore value 0 or negative),
	; then we're all done - let's get out of here!
	;
	tst	ds:[bx].HQ_semaphore.Sem_value

;	js	done		; The logical thing to do
;	jz	done

	LONG jle	done		; The short thing to do...

	; FIRST, go through all events in the source queue, and
	; change any HE_OD's which match the source queue handle to be
	; the destination's queue handle.  OK, it's true -- I don't totally
	; understand what this is all about.  I do know that a fatal error
	; will result without this fixup.  (The direction for this
	; change comes from adam) -- doug

	push	di			; Save passed flags for later

fixupSourceQueue:
	mov	di, ds:[bx].HQ_frontPtr	; Fetch first handle
	push	di			; preserve here for later test...
fixupLoop:
	tst	di
	jz	afterFixup
	cmp	ds:[di].HE_OD.handle, bx	; See if source handle is queue
	jne	doneWithHandle
	mov	ds:[di].HE_OD.handle, cx	; If so, replace w/OD passed
	mov	ds:[di].HE_OD.chunk, dx
doneWithHandle:

	INT_ON				; Can't hold up interrupts while
					; traversing queue...
	nop				; Let enough time pass to allow ints
	INT_OFF
	mov	di, ds:[di].HE_next	; fetch next handle to do
	and	di, 0xfff0
	jmp	fixupLoop		; and loop...

afterFixup:
	pop	ax			; Get back original frontPtr
	cmp	ax, ds:[bx].HQ_frontPtr	; See if first event has changed
					; (Only possible if added in front,
					; at interrupt time)
	jne	fixupSourceQueue	; if changed, start over.

	pop	di		; Restore passed flags

	; NOW, move events queued in source over to the front/back of
	; the destination queue

				; Code optimization -- this line needed
				; for both insert at back & insert
				; in front cases.  Fetch source front ptr,
				; replace old ptr with a 0.
	clr	cx
	xchg	ds:[bx].HQ_frontPtr, cx

	; If the destination queue is empty (semaphore value 0 or negative),
	; then handle this case specially (Doesn't matter if front or back
	; adding)
	tst	ds:[si].HQ_semaphore.Sem_value
;	js	moveOver	; The logical thing to do
;	jz	moveOver

	jle	moveOver	; The short thing to do...

	test	di, mask MF_INSERT_AT_FRONT
	jnz	insertAtFront

;insertAtBack:
	; Move Source events to back of Dest queue, leave the source queue
	; empty.  To accomplish this, shift handles around like this:
	; 0 -> Source frontPtr -> Dest(backPtr) next
	; 0 -> Source backPtr -> Dest backPtr

	mov	di, ds:[si].HQ_backPtr
	and	ds:[di].HE_next, 0x000f
	or	ds:[di].HE_next, cx
	clr	cx
	xchg	ds:[bx].HQ_backPtr, cx
	mov	ds:[si].HQ_backPtr, cx

	
	jmp	afterEventsMoved

insertAtFront:
	; Move Source events to front of Dest queue, leaving the source
	; queue empty.  To accomplish, shift handles around like this:
	; 0 -> Source frontPtr -> Dest frontPtr -> Source(backPtr) next,
	; 0 -> Source backPtr
	;
	xchg	ds:[si].HQ_frontPtr, cx
	clr	di
	xchg	ds:[bx].HQ_backPtr, di
	and	ds:[di].HE_next, 0x000f
	or	ds:[di].HE_next, cx
	jmp	afterEventsMoved

moveOver:
	; Simply move all events over to the dest queue, which is 
	; currently empty.  To accomplish this, Just copy front & back ptr
	; values from the source queue to the dest, & leave null ptrs
	; in the source queue.

	mov	ds:[si].HQ_frontPtr, cx
	clr	cx
	xchg	ds:[bx].HQ_backPtr, cx
	mov	ds:[si].HQ_backPtr, cx

afterEventsMoved:

	; Finally, clean up semaphores for both queues

					; Zero out count in source queue's
					; semaphore, as it has no events
					; to offer anyone.  At the same time,
					; fetch the # of events moved into 
					; cx.
	clr	cx
	xchg	ds:[bx].HQ_semaphore.Sem_value, cx

					; Inc "counter" variables to keep
					; 	the combine routine happy,
					; 	since we've changed both 
					; 	queues.
	inc	ds:[bx].HQ_counter	; Indicate queue has changed
	inc	ds:[si].HQ_counter	; Indicate queue has changed.

	INT_ON				; Allow ints once again

semFixupLoop:
	VSem	ds, [si].HQ_semaphore	; & let destination queue know of new
					; events needing to be processed
	loop	semFixupLoop

done:
	INT_ON

	call	SysExitCritical		; Allow context switches

	.leave
	ret

GeodeFlushQueue	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeFreeQueue

DESCRIPTION:	Free an event queue

CALLED BY:	GLOBAL

PASS:
	bx - handle of queue to free (or thread handle to free queue for)

RETURN:
	none

DESTROYED:
	bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

GeodeFreeQueue	proc	far
	push	ds
	LoadVarSeg	ds

EC <	call	ECCheckQueueHandle				>

	; start at front of queue, remove all events

	push	bx
	mov	bx,ds:[bx].HQ_frontPtr

freeLoop:
	tst	bx
	jz	done
	push	ds:[bx].HE_next			;save next event
	cmp	ds:[bx].HE_handleSig,SIG_EVENT_DATA
	jnz	noData

	; event has data in additional handles -- must free them also

	push	bx
	mov	bx,ds:[bx].HE_bp		;first data handle
dataLoop:
	tst	bx
	jz	doneData
	push	ds:[bx].HED_next
	call	FarFreeHandle
	pop	bx
	jmp	dataLoop
doneData:
	pop	bx

noData:
	call	FarFreeHandle
	pop	bx
	and	bx, 0xfff0
	jmp	freeLoop

done:
	pop	bx
	call	FarFreeHandle

	pop	ds

	ret

GeodeFreeQueue	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjDuplicateMessage

DESCRIPTION:	Duplicate an encapsulated message

CALLED BY:	GLOBAL

PASS:
	bx - message to duplicate

RETURN:
	ax - duplicate message

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/17/92		Initial version

------------------------------------------------------------------------------@
ObjDuplicateMessage	proc	far	uses bx, si, ds,cx
	.enter

	LoadVarSeg	ds, ax
	call	FarDupHandle		;si = handle passed, bx = new handle

	; change owner of duplicate to current process

	mov	ax, ss:[TPD_processHandle]
	andnf	ds:[bx].HE_next, 0xf
	ornf	ds:[bx].HE_next, ax

	; if there is stack data then copy it

	cmp	ds:[si].HG_type, SIG_EVENT_STACK
	jnz	done

	mov	cx,si				;original HandleEvent
	mov	si, ds:[si].HE_bp
	call	DupStackData			;ax = copy
	mov	ds:[bx].HE_bp, ax

done:
	mov_tr	ax, bx

	.leave
	ret

ObjDuplicateMessage	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	DupStackData

DESCRIPTION:	Duplicate stack data for an event

CALLED BY:	INTERNAL

PASS:
	cx - original HandleEvent that bx was duplicated from
	bx - duplicated HandleEvent
	si - HandleEventData to duplicate
	ds - kdata

RETURN:
	ax - duplicated HandleEventData

DESTROYED:
	si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/17/92		Initial version

------------------------------------------------------------------------------@
DupStackData	proc	near
	uses	bx
	.enter

EC <	call	AssertDSKdata					>

	; recurse...

	; Save the duplicated HandleEvent, so we can put it in
	; the HED_next field of the last HandleEventData.

	mov	ax, bx				;duplicated HandleEvent

	; If the next field of the HandleEventData is the original
	; HandleEvent then this is the last HandleEventData.

	push	si				;HandleEventData to duplicate
	mov	si, ds:[si].HED_next
	cmp	si,cx				;next field, orig HandleEvent
	je	dupThisHED
	
	; Duplicate the next HED first

	call	DupStackData

dupThisHED:
	; Duplicate this HED and set its next field to either the 
	; just duplicated next HED or the new HandleEvent if this is
	; the last HED.

	pop	bx				;HandleEventData to duplicate
	call	FarDupHandle			;bx = new HandleEventData
	mov	ds:[bx].HED_next, ax		;
	mov_tr	ax, bx				;new HandleEventData

	.leave
	ret

DupStackData	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			QueuePostMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds passed message to the queue indicated.

CALLED BY:	EXTERNAL
PASS:		bx	- handle of queue
		ax	- message to post
		si	- calling thread
		di	- MessageFlags, though only the following apply:

			  MF_INSERT_AT_FRONT - set to insert event at front of
			  queue instead of the back, where events are normally
			  added.

RETURN:
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QueuePostMessage	proc	far	uses	ax, cx, si, ds
	.enter
	LoadVarSeg	ds

EC <	call	ECCheckQueueHandle				>

	mov	bp, bx				;Keep queue handle in bp
	xchg	ax, si				;and message (event) in si
						;ax = calling thread

	INT_OFF

	inc	ds:[bp].HQ_counter		;for CheckDuplicate sync'ing
	mov	bx,si				;bx = si = new event

	mov	ds:[si].HE_callingThreadHigh, ah
	clr	ah
	mov	cl, 4
	shr	ax, cl				;get high 4 bits low byte
						;of caller in low 4 bits
	mov	ds:[si].HE_next, ax		;Init HE_next for event on a
						;queue, before linkage.

	test	di,mask MF_INSERT_AT_FRONT
	jnz	insertAtFront

	xchg	bx,ds:[bp].HQ_backPtr		;bx = last event
;EC <	call	CheckEventHandleZ					>

	; si = our new event, bx = old last event

	tst	bx				;only event on queue ?
	jz	only
	or	ds:[bx].HE_next, si		;link them
	jmp	afterLink

	; insert the event at the front of the queue

insertAtFront:
	xchg	bx, ds:[bp].HQ_frontPtr		;bx = first event
;EC <	call	CheckEventHandleZ					>

	; si = our new event, bx = old first event

	or	ds:[si].HE_next, bx		;link them
	and	bx, 0xfff0			;only event on queue ?
	jnz	afterLink

	; this is the only event, so set the backPtr too

	mov	ds:[bp].HQ_backPtr,si

	; easiest just to fall through. this is a rare case and it's
	; only about 4 cycles difference (20 for the store vs. 16 for
	; a jump) and it's smaller besides... -- ardeb
only:
	mov	ds:[bp].HQ_frontPtr,si
afterLink:

	mov	bx, bp				;bx = event queue handle

if	CATCH_MISSED_COM1_INTERRUPTS
	pushf
	call	LookForMissedCom1Interrupt
	popf
endif

	VSem	ds, [bx].HQ_semaphore

if	CATCH_MISSED_COM1_INTERRUPTS
	pushf
	call	LookForMissedCom1Interrupt
	popf
endif

	INT_ON

	.leave
	ret

QueuePostMessage	endp

GLoad	ends



COMMENT @----------------------------------------------------------------------

FUNCTION:	GeodeInfoQueue

DESCRIPTION:	Return information about a queue

CALLED BY:	GLOBAL

PASS:
	bx - handle of queue about which to get information. If 0, uses
	     current thread's event queue.

RETURN:
	ax - number of events in the queue
	bx - thread's event queue, if bx was zero on entry

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@

GeodeInfoQueue	proc	far
	push	ds
	LoadVarSeg	ds
	tst	bx
	jnz	haveQ

	; use current thread's queue
	mov	bx, ss:[TPD_threadHandle]
	mov	bx, ds:[bx].HT_eventQueue

	; thread has queue?
	clr	ax		; assume no (so no events in the queue)
	tst	bx
	jz	noQ
haveQ:

EC <	call	ECCheckQueueHandle				>

	mov	ax,ds:[bx].HQ_semaphore.Sem_value
noQ:
	pop	ds
	ret

GeodeInfoQueue	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjProcBroadcastMessage

DESCRIPTION:	Broadcast an event to all threads with event queues.

CALLED BY:	GLOBAL

PASS:
	bx - encapsulated message to broadcast

RETURN:
	none

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/89		Initial version

-------------------------------------------------------------------------------@

ObjProcBroadcastMessage	proc	far
	uses	di, si
	.enter
	
	mov	di, cs
	mov	si, offset PBE_callback
	mov	cx, bx			;cx = message
	call	ThreadProcess

	mov	bx, cx
	call	ObjFreeMessage
	
	.leave
	ret
ObjProcBroadcastMessage	endp

	; cx = message

PBE_callback	proc	far	uses	bx, cx
	.enter

	tst	ds:[bx].HT_eventQueue	; does thread have event queue?
	jz	done			; no -- nowhere to send event

	xchg	bx, cx			; bx = message, cx = destination
	call	MessageSetDestination
	clr	cx
	mov	di, mask MF_RECORD	;don't delete it
	call	MessageDispatch
	clc
done:
	.leave
	ret

PBE_callback	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	PushAll

DESCRIPTION:	Push all registers

CALLED BY:	INTERNAL

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
	Tony	1/90		Initial version

------------------------------------------------------------------------------@

	; WARNING: The order that registers are pushed here must match the
	; structure PushAllFrame in localcon.def.  At least one routine,
	; WinInvalReg, depends on this order.

PushAllFar proc far
	call	PushAll
	mov	bp, sp
	pushdw	ss:[bp].PAF_fret
	mov	bp, ss:[bp].PAF_bp
	ret
PushAllFar endp

PushAll	proc	near
	push	es, ds, bp, di, si, dx, cx, bx, ax
	mov	bp, sp
	push	ss:[bp].PAF_ret		; push passed return address for return.
	mov	bp, ss:[bp].PAF_bp	; recover passed bp
	ret
PushAll	endp

;-----

PopAllFar proc far
	mov	bp, sp			; pop return address into slot saved
	popdw	ss:[bp+4].PAF_fret	;  for it...
	call 	PopAll
	ret
PopAllFar endp

PopAll	proc	near
	mov	bp, sp
	pop	ss:[bp+2].PAF_ret	; pop return address into slot saved
					;  for it...
	pop	es, ds, bp, di, si, dx, cx, bx, ax
	ret
PopAll	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SafePopf
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Silly routine to pop the flags word safely on a buggy 286.
		This should only be used when interrupts are off and an
		interrupt may not be allowed to come in unless the popped
		flags word re-enables them. Some '286 processors allow
		interrupts even if the popped flags word also has interrupts
		disabled. The iret instruction does no such thing...

CALLED BY:	INTERNAL
PASS:		flags on stack
RETURN:		flags popped
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SafePopf	proc	far
		iret
SafePopf	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjGetMessageInfo

DESCRIPTION:	Get information about an event

CALLED BY:	GLOBAL

PASS:
	bx - event handle

RETURN:
	ax - method
	cx:si - destination OD
	carry set if event has stack data
	carry clear if event has register data

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ObjGetMessageInfo	proc	far	uses ds
	.enter

EC <	call	CheckEventHandle					>

	LoadVarSeg	ds
	mov	ax, ds:[bx].HE_method
	mov	cx, ds:[bx].HE_OD.handle
	mov	si, ds:[bx].HE_OD.chunk

	cmp	ds:[bx].HE_handleSig, SIG_EVENT_REG
	je	done			; event reg, carry clear
	stc				; stack data event, carry set
done:

	.leave
	ret

ObjGetMessageInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjGetMessageData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the passed register data from an event

CALLED BY:	GLOBAL
PASS:		bx	= Event handle

RETURN:		cx, dx, bp  as contained within the event
		carry set if event has stack data
		carry clear if event has register data
		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CT	3/31/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjGetMessageData	proc	far	uses ds
	.enter

EC <	call	CheckEventHandle					>

	LoadVarSeg	ds
	mov	cx, ds:[bx].HE_cx
	mov	dx, ds:[bx].HE_dx
	mov	bp, ds:[bx].HE_bp

	cmp	ds:[bx].HE_handleSig, SIG_EVENT_REG
	je	done			; event reg, carry clear
	stc				; stack data event, carry set
done:
	.leave
	ret
ObjGetMessageData	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	MessageSetDestination

DESCRIPTION:	Change message (event) destination optr

CALLED BY:	GLOBAL

PASS:
	bx - event handle
	cx:si - destination

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
	Doug	8/92		Initial version

------------------------------------------------------------------------------@
MessageSetDestination	proc	far	uses ds
	.enter
EC <	call	CheckEventHandle					>

	LoadVarSeg	ds
	mov	ds:[bx].HE_OD.handle, cx
	mov	ds:[bx].HE_OD.chunk, si

	.leave
	ret

MessageSetDestination	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	ObjFreeMessage

DESCRIPTION:	Free an event handle

CALLED BY:	GLOBAL

PASS:
	bx - event handle

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
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ObjFreeMessage	proc	far
	call	PushAll
EC <	call	CheckEventHandle					>

	; use MessageDispatch to free the sucker, ensuring that we
	; have a null destination to that nothing will be sent

	LoadVarSeg	ds

	clr	di			; default callback, NULL MessageFlags
					;	so as not to preserve message
	mov	ds:[bx].HE_OD.handle, di
	call	MessageDispatch

	call	PopAll
	ret

ObjFreeMessage	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QueueGetMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the next message from a given queue, blocking if it
		is empty, until there is a message added to it which can be
		returned.

CALLED BY:	EXTERNAL
PASS:		bx	- handle of queue
RETURN:		ax	- message (event)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QueueGetMessage	proc	far	uses	bx, di, ds
	.enter

EC <	call	ECCheckQueueHandle				>

	push	bx

	LoadVarSeg	ds

	PSem	ds, [bx].HQ_semaphore

	; we've got an event -- do it!

	INT_OFF					;exclusive access, please

	pop	di				;di = event queue

	inc	ds:[di].HQ_counter		;for CheckDuplicate sync'ing
	mov	bx, ds:[di].HQ_frontPtr		;get event
EC <	call	CheckEventHandle					>
	mov	ax, ds:[bx].HE_next
	and	ax, 0xfff0
	mov	ds:[di].HQ_frontPtr,ax		;fix front pointer
	tst	ax
	jnz	notEmpty
	mov	ds:[di].HQ_backPtr,ax		;no more events -- zero backPtr
						; so we know to adjust
						; HQ_frontPtr in SendEvent
notEmpty:
	mov_tr	ax, bx				;return in ax

	INT_ON

	.leave
	ret
QueueGetMessage	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MessageDispatch

DESCRIPTION:	Given a handle to a message, dispatch it

CALLED BY:	GLOBAL

PASS:
	bx	- handle of message (event) to dispatch
	di	- MessageFlags, but with the meaning of MF_RECORD changed
		  to mean "dispatch, but don't destroy message".

RETURN:
		ax, cx, dx, bp -- as per ObjMessage

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version

------------------------------------------------------------------------------@

MessageDispatch	proc	far

	push	ax, cx, dx, bp	; in case non-MF_CALL, so we can restore

	push	si, di

	; Setup default behavior of ObjMessage (with carry fix), & convert
	; MF_RECORD to mean "dispatch", but don't destroy.
	;
	push	cs		; push callback on stack
	mov	si, offset MessageDispatchDefaultCallBack
	push	si
	mov	si, di
	and	si, mask MF_RECORD
	and	di, not mask MF_RECORD
	call	MessageProcess

	test	di, mask MF_CALL
	pop	si, di
	jnz	pop4Done

	pop	ax, cx, dx, bp	; if non-call, restore passed registers
	ret

pop4Done:
	add	sp, 8		; fixup stack for above pushes
	ret
MessageDispatch	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	MessageProcess

DESCRIPTION:	Given a handle to a message, process it

CALLED BY:	GLOBAL

PASS:
	bx	- handle of message (event) to dispatch
	di	- data to pass to callback routine, if any
	si	- non-zero to preserve event, or zero to destroy it

	on stack (pushed in this order):
		fptr  - address of callback routine (segment pushed first)
		vfptr - address of callback routine if geode is XIP'ed
RETURN:
	ax, cx, dx, bp - as returned by callback  (Note that callback is
			 passed data in event, not registers passed in, so
			 ax, cx, dx & bp passed in are effectively destroyed.

DESTROYED:
	nothing


CALLBACK ROUTINE:
	Pass:
		Same as ObjMessage (except di passed through from caller)
		Carry - set if event has stack data
		ss:[sp+4] (right above return address) - calling thread
	Return:
		none
	Destroy:
		ax, cx, dx, si, di, bp, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	Doug	8/92		New API
	SH	4/94		XIP'ed
------------------------------------------------------------------------------@

MessageProcess	proc	far call	callBack:fptr
	uses	bx, si, di
	.enter
	;
	; We record a log entry containing the handle of the message
	; to process.  This allows us to track a message, from where
	; it was sent, to where it was received
	;
	InsertGenericProfileEntry PET_MP, 1, PMF_MESSAGE, bx

	; 10/17/95 -- changed the ordering of these pushes to keep
	; CallLibraryEntry from showing up as the last frame of the stack
	; for an event-driven thread. don't push callVector.segment
	; and callVector.offset together. -- ardeb

	push	ss:[TPD_dataAX]
	push	ss:[TPD_callVector].segment
	push	ss:[TPD_dataBX]
	push	ss:[TPD_callVector].offset
	push	ss:[TPD_callTemporary]

EC <	call	CheckEventHandle					>
EC <	call	ECCheckStack						>

	tst	si
	jz	havePreserveFlag
	mov	si, mask MF_RECORD
havePreserveFlag:
	mov	ss:[TPD_dataAX], si		; save message flags
	mov	ss:[TPD_dataBX],di

	mov	si, callBack.segment
	mov	ss:[TPD_callVector].segment,si
	mov	si, callBack.offset
	mov	ss:[TPD_callVector].offset,si

	mov	ss:[TPD_callTemporary], ds
	LoadVarSeg	ds

	push	bp				; preserve stack ptr for
						; this routine

	; if parameters on stack then copy them

	mov	di,sp				;save stack pointer
	mov	bp,ds:[bx].HE_bp		;assume no stack
	cmp	ds:[bx].HE_handleSig,SIG_EVENT_STACK
	jnz	noStack

	ornf	ss:[TPD_dataAX], mask MF_STACK
	mov	si,bp				;si <- first data handle
	mov	dx,ds:[bx].HE_dx		;allocate space on stack
	inc	dx
	andnf	dx,not 1			;round to words
	shr	dx,1				;convert to words

allocLoop:
	mov	bx,si				;bx = data handle (for eventual
						; FreeHandle)
	add	si, offset HED_word0		;ds:si = source
	mov	cx, 6				; assume 6 words
	sub	dx, cx				; adjust total accordingly
	jae	copyLoop
	add	cx, dx				; wrong. scale back cx

copyLoop:
	lodsw
	push	ax				;store data
	loop	copyLoop
	mov	si, ds:[bx].HED_next		;si <- next handle
	test	ss:[TPD_dataAX], mask MF_RECORD
	jnz	noFree1
	call	FreeHandle
noFree1:
	tst	dx
	jg	allocLoop			;loop until all data copied
	mov	bp, sp				;ss:sp is now first word
						; of data
	mov	bx, si				;restore event handle from the
						; HED_next field of the last
						; data handle, which is set
						; to point to the event handle
						; by SendEvent

noStack:
	push	bp				;save passed-in bp so we can
						; determine whether to return
						; value from handler
	push	di				;save stack pointer that's
						; above the data

	; save calling thread on stack (b4-7 are stored in b0-3 of HE_next)

	mov	al,ds:[bx].HE_next.low
	mov	cl,4
	shl	al,cl				;al = calling thread low
	mov	ah,ds:[bx].HE_callingThreadHigh	;ax = calling thread
	push	ax				;save calling thread

	mov	si,ds:[bx].HE_OD.chunk
	mov	cx,ds:[bx].HE_cx
	mov	dx,ds:[bx].HE_dx
	mov	ax,ds:[bx].HE_method

	push	ds:[bx].HE_OD.handle		;save this (cbh 10/22/91)
   
	test	ss:[TPD_dataAX], mask MF_RECORD	;recorded messages must be
						; freed explicitly
	jnz	noFree2
	call	FreeHandle
noFree2:
	;	
	; Changed (cbh 10/22/91) as this appears very un-atomic.  Seems to
	; fix the bug I found where messages were being sent to the wrong
	; location.
	;
;	mov	bx, ds:[bx].HE_OD.handle
	pop	bx				;bx = OD high (cbh 10/22/91)

	mov	di, ss:[TPD_dataBX]
	mov	ds, ss:[TPD_callTemporary]

	test	ss:[TPD_dataAX], mask MF_STACK
	jz	haveStackFlag
	stc				;pass in carry set if data on stack
haveStackFlag:
	;
	; Even thought we are in a fixed segment
NOFXIP<	call	ss:[TPD_callVector]		;do it	>
FXIP <	mov	ss:[TPD_dataAX], ax			>
FXIP <	mov	ss:[TPD_dataBX], bx			>
FXIP <	movdw	bxax, ss:[TPD_callVector]		>
FXIP <	call	ProcCallFixedOrMovable			>

	; Event is finished -- callingThread is on stack, return values (if
	; any) are in carry, ax, cx, dx, bp

	mov_trash	di,ax		;save ax (1-byte inst)
	lahf				;get flags
	pop	si			;si = callingThread
	tst	si
	jz	noReturn

	push	ds
	LoadVarSeg	ds
	lds	bx,{dword}ds:[si].HT_saveSP;ds:bx = stack for proc to return

	mov	ds:[bx].TBS_flags.low,ah;return flags (overflow *not* returned)
	mov	ds:[bx].TBS_cx,cx
	mov	ds:[bx].TBS_dx,dx
	;
	; If bp didn't change during the call, then don't modify bp in our
	; caller. This makes it possible for MF_STACK-called messages to not
	; trash BP, while still allowing them to return a value in BP, if they
	; want. It used to be impossible for them to not trash BP when calling
	; another thread, as the BP we passed to the handler was almost
	; guaranteed to be different from the one in the calling thread, and
	; our wanton overwriting of TBS_bp with our own ensured that BP in the
	; caller was biffed. -- ardeb/tony 3/19/92
	; 
	mov_tr	ax, bp			; ax <- bp returned from handler
	mov	bp, sp
	cmp	ax, ss:[bp+4]		; on_stack: ds, sp-above-data, original-
					;  bp
	je	returnDI
	mov	ds:[bx].TBS_bp,ax	; returned bp is different, so return
					;  it.
returnDI:
	mov	ds:[bx].TBS_di,di	;return ax in di (moved to di above)

	; si is now runnable again -- run it

	call	WakeUpSI
	pop	ds

noReturn:
	pop	bx			; restore saved sp (above data)
	mov	sp,bx			;  this also clears the original-bp
					;  from the stack.

	sahf
	mov_trash	ax,di

	mov	di, bp
	pop	bp			; get our stackframe back
	mov	ss:[bp], di		; store value to return in bp

	pop	ss:[TPD_callTemporary]
	pop	ss:[TPD_callVector].offset
	pop	ss:[TPD_dataBX]
	pop	ss:[TPD_callVector].segment
	pop	ss:[TPD_dataAX]

	.leave
	ret	@ArgSize
SwatLabel MessageProcess_end
MessageProcess	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MessageDispatchDefaultCallBack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the default callback routine used for dispatching
		messages by MessageDispatch.  It converts the parameters
		passed in to be in ObjMessage format, & then falls through
		to ObjMessage.  At this time, the only change is to convert
		the passed in "carry set if stack" data to the MF_STACK flag
		required by ObjMessage.  This is not forced by
		MessageDispatch itself for the sake of alternative callback
		routines that would actually like to pass non-MessageFlags
		data in di.

CALLED BY:	INTERNAL
		MessageDispatch (when default callback is called for)
PASS:
RETURN:
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	8/92		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MessageDispatchDefaultCallBack	proc	far
	jnc	haveStackFlagSetCorrectly
	ornf	di, mask MF_STACK
haveStackFlagSetCorrectly:

	FALL_THRU	ObjMessage
SwatLabel MessageDispatchDefaultCallBack_end
MessageDispatchDefaultCallBack	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	ObjMessage

DESCRIPTION:	Send a message to an object

CALLED BY:	GLOBAL

PASS:
	bx:si - destination, either:
		^lbx:si = object descriptor
		-or-
		bx = process ID, si = other data
	di - flags -- MessageFlags:
		MF_CALL - Message expects return values.  If the message
			  is routed via the event queue then the caller will
			  block until the message is processed.  If MF_CALL
			  then ax, cx, dx and bp are return values.  If
			  !MF_CALL then ax, cx, dx and bp and returned intact.
		MF_FORCE_QUEUE - Send the message via the event queue (even if
				 it could otherwise be handled via a direct
				 call)
		MF_STACK - Paramters are being passed on the stack where:
				ss:bp - paramters being passed
				dx - number of paramters in bytes
				(cx can also contain data)
			   If the message is sent via the event queue, the
			   stack parameters are copied into kernel data space
			   and then copied to the destination stack
		MF_RETURN_ERROR - If the message cannot be sent, return an
				  error code in di (instead of calling
				  FatalError)
		MF_CHECK_DUPLICATE - Check if a message of the same type is
				     already queued (requires MF_FORCE_QUEUE).
				     *** SEE NOTE BELOW ***
		MF_CHECK_LAST_ONLY - Modifies MF_CHECK_DUPLICATE so that only
				     the last message in the queue (for the
				     given destination object) is checked.
		MF_REPLACE - Modifies MF_CHECK_DUPLICATE so that a duplicate
			     event will be replaced (if not given then the
			     duplicate event is dropped)
		MF_CUSTOM - Modifies MF_CHECK_DUPLICATE so that a caller
			    supplied routine is called to determine if two
			    messages are duplicates (and to optionally
			    combine the messages).  The callback routine is
			    passed on the stack (segment pushed first).
		MF_DISCARD_IF_NO_MATCH - If comparing messages and no match is
					 found, discard this event (do not put
					 it in the queue)
		MF_MATCH_ALL - Send all events (of the same type) to the custom
			       combination routine, even if the OD's don't match
		MF_INSERT_AT_FRONT - Insert the event at the front of the queue
		MF_FIXUP_DS - Returns ds pointing at the same block as passed,
			      even if the block moves.  *** SEE NOTE 2 ***

		MF_FIXUP_ES - Returns es pointing at the same block as passed,
			      even if the block moves.  *** SEE NOTE 2 ***

		MF_CAN_DISCARD_IF_DESPERATE - This event can be dropped on the
					      floor if the system is desparate
					      and is running out of handles
		MF_RECORD - Don't actually send the event, just package it
			    up and return its handle in di.  Flags that are
			    legal with this are: MF_STACK
	ax - method number
	cx - event word 0
	dx - event word 1
	bp - event word 2

	if MF_CUSTOM passed, far pointer to callback routine pushed on
		the stack. The routine must be locked in memory for the
		duration of the ObjMessage.

	NOTE 2:  For MF_FIXUP_DS and MF_FIXUP_ES, the segment
	register in question MUST point to an LMem block or core
	block, or other block whose first word is the block's handle.

RETURN:
	interrupts ON
	di - error code (MessageError):
		MESSAGE_NO_ERROR (0) - No error
	if MF_CUSTOM passed - custom routine popped off the stack
	if MF_CALL - ax, cx, dx, bp, carry - return values

DESTROYED:
	none
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

	Compare/combine routine:
	DESCRIPTION:	Compare two events (the event being passed and an
			event already in the queue) and determine if there is
			a match.  If there is a match, combine the two events
			into one event in the queue.
	PASS:
		ax, cx, dx, si, bp - event being sent
		ds:bx - event in queue (structure Event)
	RETURN:
		di - flags:
			PROC_SE_EXIT - to exit without queueing the new
					message. The routine may have modified
					the event at ds:bx to incorporate the
					event being sent.
			PROC_SE_STORE_AT_BACK - to store the new message
						at the back of the queue.
			PROC_SE_CONTINUE - to continue down the queue
		cx, dx, bp - possible return values to the caller of ObjMessage
	DESTROYED:
		none

	Method Routine:
	PASS:
		es - segment of class called
		If class is a subclass of ProcessClass:
			ds - dgroup of process
			si - other data (passed by caller)
		else
			*ds:si - instance data of object called
			ds:bx - instance data of object called (= *ds:si)

			if class of method handler is in a master part
			    ds:di - data for master part of method handler
			else
			    ds:di - instance data of object called (= *ds:si)
		cx, dx, bp - other data
		ax - method number
	RETURN (if method has return values, else these may also be destroyed):
		ax, cx, dx, bp
	CAN DESTROY:
		bx, si, di, ds, es

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

	Messages can be sent to objects, processes, queues, or threads.
	Sending to a process is identical to sending to the process's first
	thread.  Each object block has an associated thread that executes
	messages sent to the objects in the block. Messages that are to be
	executed by the current thread are accomplished with direct calls
	unless the MF_FORCE_QUEUE flag is passed.

	if (destination does not exist)
		return error
	endif
	destQueue = (destination handle) {
	switch (destQueue->type) {
	    case Memory handle {
		destQueue = destQueue->executing thread
		goto th
	    }
	    case Process handle {
		h = h->first thread
		goto th
	    }
	    case Thread handle {
	    th:
		h = h->queue
	    }
	    case Queue handle {
	    }
	}
	if (h == currentThread && !MF_FORCE_QUEUE) {

	if (MF_FORCE_QUEUE or (destination run by another thread))
		SendEvent()
	else
		SendMessage()
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	This routine can be called from interrupt level.

*** NOTE: Due to a constraint in the implementation, if MF_CHECK_DUPLICATES is
	  passed and MF_CHECK_LAST_ONLY is not, the events are checked IN THE
	  WRONG ORDER!  *** BEWARE ***

	Since sending an event does a V on a semaphore, a context switch can
happen if the first thread of the process receiving the event is waiting for
an event and is a higher priority.  (A context switch can also happen because
interrupts are turned on, allowing a timer interrupt).

	Calling convention with parameters on the stack (passing FooStructure):

		sub	sp,size FooStructure	;allocate space
		mov	bp,sp			;bp points at BOTTOM of space
		(mov	ss:[bp].FS_field,???	;set up parameters)

		mov	dx,size FooStructure
		mov	di, mask MF_STACK or (other flags)
		call	ObjMessage
		add	sp,size FooStructure	;de-allocate space

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version (ProcSendEvent)
	Tony	10/88		Comments from Doug's code review added
	Tony	7/20/89		Changed to ObjMessage

-------------------------------------------------------------------------------@

ObjMessage	proc	far
 	InsertMessageProfileEntry PET_OBJMESSAGE, 1, ax
	; check that flags are correct

EC <	test	di, not mask MessageFlags				>
EC <	ERROR_NZ	BAD_FLAGS_RESERVED_MUST_BE_0			>
EC <	test	di, mask MF_RECORD					>
EC <	jz	OM_5							>
EC <	test	di, not (mask MF_RECORD or mask MF_STACK)		>
EC <	ERROR_NZ	BAD_FLAGS_CANNOT_BE_USED_WITH_MF_RECORD		>
EC <OM_5:								>
EC <	test	di,mask MF_CHECK_DUPLICATE				>
EC <	jnz	OM_10							>
	; no duplicate checking
EC <	test	di,mask MF_CHECK_LAST_ONLY or mask MF_REPLACE or \
				mask MF_DISCARD_IF_NO_MATCH or \
				mask MF_CUSTOM or mask MF_MATCH_ALL	>
EC <	ERROR_NZ	BAD_FLAGS_REQUIRES_MF_CHECK_DUPLICATE		>
EC <	jmp	OM_15							>
	; duplicate checking
EC <OM_10:								>
EC <	test	di,mask MF_FORCE_QUEUE					>
EC <	ERROR_Z	BAD_FLAGS_REQUIRES_MF_FORCE_QUEUE			>
EC <	test	di,mask MF_STACK					>
EC <	ERROR_NZ	BAD_FLAGS_CANNOT_STACK_AND_CHECK		>
EC <	test	di,mask MF_CALL						>
EC <	ERROR_NZ	BAD_FLAGS_CANNOT_CALL_AND_CHECK			>
EC <	test	di,mask MF_INSERT_AT_FRONT				>
EC <	ERROR_NZ	BAD_FLAGS_CANNOT_INSERT_AT_FRONT_AND_CHECK	>
EC <OM_15:								>

EC <	test	di, mask MF_FORCE_QUEUE					>
EC <	jz	17$							>
EC <	test	di, mask MF_CALL					>
EC <	jz	18$							>
EC <	ERROR	CANNOT_HAVE_BOTH_MF_FORCE_QUEUE_AND_MF_CALL		>
EC <17$:								>
EC <	test	di, mask MF_INSERT_AT_FRONT				>
EC <	ERROR_NZ INSERT_AT_FRONT_REQUIRES_FORCE_QUEUE			>
EC <18$:	

EC <	test	di,mask MF_FIXUP_ES					>
EC <	jz	OM_20							>
EC <	test	di,mask MF_FIXUP_DS					>
EC <	ERROR_Z	BAD_FLAGS_CANNOT_FIXUP_ES_ONLY				>
EC <OM_20:								>
   
EC <	test	di, mask MF_STACK					>
EC <	jz	OM_30							>
EC <	tst	dx							>
EC <	ERROR_Z	BAD_ARGS_CANNOT_PASS_EMPTY_STACK_FRAME			>
EC <	cmp	dx, OBJ_MESSAGE_MAX_STACK_SIZE				>
EC <	ERROR_A	BAD_ARGS_CANNOT_PASS_HUGE_STACK_FRAME			>
EC <OM_30:								>

	test	di, mask MF_RECORD
	LONG jnz recordMode

	tst	bx			;null ?
	jz	OM_doRet

EC <	call	CheckHandleLegal					>

	push	ds
	push	ax

	; determine if the destination is a process or an object

	LoadVarSeg	ds

	; non-EC - make sure handle is valid

NEC <	FAST_CHECK_HANDLE_LEGAL	ds					>

	mov	al,ds:[bx].HG_type
	cmp	al, SIG_QUEUE
	LONG jz	useEventQueue
	cmp	al, SIG_THREAD
	mov	ax, bx			; assume it's a thread and place the
					;  thread handle in ax for 'thread'
	jz	thread
	cmp	bx,ds:[bx].HM_owner	;a process owns itself
  	jz	process

	; destination is an object -- determine thread to execute it

	xchg	ax, si				;save si (1-byte inst)
	mov	si, ds:[bx].HM_owner
	cmp	ds:[si].HG_type, SIG_VM
	jnz	normal
	mov	si, ds:[si].HVM_execThread
	jmp	common

normal:
	mov	si, ds:[bx].HM_otherInfo
common:
	xchg	ax, si				;si <- old si, ax <- thread

thread:
EC <	xchg	ax, bx			; bx <- thread, ax <- od handle >
EC <	call	ECCheckThreadHandle					>
EC <	xchg	ax, bx			; the two may be different...	>
	cmp	ax,ds:[currentThread]
	jnz	useEventGetQueue		;if different then must queue it
	test	di,mask MF_FORCE_QUEUE
	jz	directCall

useEventGetQueue:
	xchg	ax,bx				;ax = OD_handle, bx = thread
	mov	bx,ds:[bx].HT_eventQueue
EC <	call	ECCheckQueueHandle					>
	xchg	ax,bx				;ax = queue, bx = OD_handle
	jmp	useEvent

OM_doRet label near
 	InsertMessageProfileEntry PET_END_CALL, 1, ax
	test	di,mask MF_CUSTOM
	jnz	ret4
	ret
ret4:
	ret	4

	; sending to an object in this thread, call it

directCall:
	pop	ax
	pop	ds


	; If error checking then push the lock count for the object block so
	; that we can make sure that it gets unlocked the right number of times

if	ERROR_CHECK

	; Old "SendMessageAndEC routine pulled in here to lighten EC stack
	; load -- Doug 9/17/92

	; send a message and check to make sure that the lock count on the
	; object block does not change

	push	ax			; use ax b/c we can fetch just al
	push	ds			;  allowing us to avoid a word fetch
	LoadVarSeg	ds		;  on an 8088 and an unaligned word
	mov	al,ds:[bx].HM_lockCount	;  fetch on 16-bit processors
	pop	ds
	xchg	ax,si
	XchgTopStack	si
	xchg	ax,si

	call	SendMessage

	; CANNOT grab the heap semaphore in ObjMessage, since this can
	; be called from interrupt code

;;;	call	NullSegmentRegisters

	XchgTopStack	si
	pushf
	push	ds
	LoadVarSeg	ds
	cmp	bx, ds:[bx].HM_owner		;cannot check methods to process
	jz	10$				;since lock count on core block
						;may change due to resources
						;being loaded in another thread
	cmp	ds:[bx].HT_handleSig,SIG_THREAD
	jz	10$
	xchg	ax,si
	cmp	al,ds:[bx].HM_lockCount
	ERROR_NZ	OBJ_MESSAGE_LOCK_COUNT_CHANGED
	xchg	ax,si
10$:
	pop	ds
	popf
	pop	si
	ret

else
	jmp	SendMessage
endif


	; destination is a process -- send to its first thread

process:
	mov	ax, ds:[bx].HM_otherInfo	;get first thread
	jmp	thread

	; destination is a queue - use it unless it has a thread attached.
	; The initial ATTACH method is sent to the queue for the process
	; since the initial thread hasn't been created yet. When that message
	; is dispatched, HE_OD.handle is the queue handle. To keep from
	; repeatedly queueing the message, if the queue has an associated
	; thread, pretend the message was being sent to the thread instead
	; so a direct call can be made if the bound thread is the current one.

useEventQueue:
	mov	ax, ds:[bx].HQ_thread
	tst	ax
	jz	queueUnbound
	mov	bx, ax			;place in bx too so when event is
					; dispatched, we don't come here again
	jmp	thread

	; we're in record mode (just returning a handle to the event)
	; we fall through this way and pass bx as the queue to send to but
	; it does not matter since this is ignored with MF_REPLACE.

recordMode:
	push	ds
	push	ax

	LoadVarSeg	ds

queueUnbound:
	mov	ax, bx			; need queue handle in ax

	; use an event to send the message, ax = queue handle to send to

useEvent:

	; cannot remote call from UI (for now)

EC <	test	di,mask MF_CALL						>
EC <	jz	OM_notUI						>
EC <	push	ax							>
EC <	mov	ax,ss:[TPD_processHandle]				>
EC <	cmp	ax,ds:[uiHandle]					>
EC <	pop	ax							>
EC <	jnz	OM_notUI						>
EC <	;								>
EC <	; We can remote call the IM from the UI, though			>
EC <	;								>
EC <	cmp	bx,ds:[imThread]					>
EC <	je	OM_notUI						>
EC <	;								>
EC <	; And we can remote call from anything but the first UI thread	>
EC <	; (the Express Menu spawns a thread to use IACP to launch	>
EC <	;  applications)						>
EC <	;								>
EC <	push	bx							>
EC <	mov	bx, ds:[uiHandle]					>
EC <	mov	bx, ds:[bx].HM_otherInfo	; bx = first thread	>
EC <	cmp	bx, ds:[currentThread]					>
EC <	pop	bx							>
EC <	jne	OM_notUI						>
EC <	ERROR	CANNOT_REMOTE_CALL_FROM_UI				>
EC <OM_notUI:								>

	;
	; FALL THRU to the routine to send an event.  Due to the complexity
	; of what is on the stack, this is the easiest way to organize this
	; routine such that swat can backtrace
	;


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SendEvent

DESCRIPTION:	Send an event

CALLED BY:	INTERNAL
		ObjMessage

PASS:
	same as ObjMessage except:
	on stack (in order pushed):
		ds passed
		ax passed (method number)
	ds - kernel variables
	ax - queue handle to which to send

RETURN:
	same as ObjMessage

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	if (MF_CHECK_DUPLICATE)
		if (queue not empty)
			tempPtr = HQ_backPtr
			repeat
				tempPtr = event before tempPtr
				if (MF_CUSTOM)
					if (customRoutine() == MATCH)
						return no error
					endif
				else
					if (tempPtr->eventType == passed type)
						if (MF_REPLACE)
							replace old event
						endif
						return no error
					endif
				endif
			until (tempPtr = PH_eventStartPtr or MF_CHECK_LAST_ONLY)
		endif
	endif
	replace last event with passed event
	VSem(PH_eventSem)	/* Wake up thread waiting for events */

	if (REMOTE_CALL) {
		block on remoteCallSem
	}

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	See ObjMessage

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	Tony	10/88		Comments from Doug's code review added

-------------------------------------------------------------------------------@

	;
	; This routine is actually a continuation of ObjMessage.  DO NOT MOVE
	;

	; See if we are running out of handles and is the
	; MF_CAN_DISCARD_IF_DESPERATE flag was passed

	test	di, mask MF_CAN_DISCARD_IF_DESPERATE
	jz	noDrop
	cmp	ds:[loaderVars].KLV_handleFreeCount,
					FREE_HANDLE_DESPERATION_THRESHOLD
	jae	noDrop
	pop	ax
	pop	ds
	test	di, mask MF_CUSTOM
	stc					;return error condition
	mov	di, MESSAGE_NO_HANDLES
	jmp	OM_SE_exit
noDrop:

	push	bx				;save OD handle
	call	AllocateHandle			;bx = new handle
	mov	ds:[bx].HE_cx,cx
	mov	ds:[bx].HE_dx,dx
	mov	ds:[bx].HE_OD.chunk,si

	;
	; Insert to keep track of the handle of the message sent.
	;
	InsertGenericProfileEntry PET_SEND_EVENT, 1, PMF_MESSAGE, bx

	; if parameters on stack them copy them (si free)

	test	di,mask MF_STACK
	jz	noStack
	mov	ds:[bx].HE_handleSig,SIG_EVENT_STACK
	push	ax, bx, cx, dx			;save temp variables
	lea	si,ds:[bx].HE_bp		;si points at link (event's
						; bp value contains first
						; data handle since the register
						; value itself isn't needed)
	inc	dx				;convert dx to words
	andnf	dx, not 1
	add	bp, dx				;point past end word
	shr	dx,1
allocLoop:
	call	AllocateHandle			;allocate handle for data
	mov	ds:[si],bx
	mov	ds:[bx].HED_handleSig, SIG_EVENT_DATA
	lea	si,ds:[bx].HED_word0		;ds:si = dest
	mov	cx, 6				; assume 6 words
	sub	dx, cx				; adjust total accordingly
	jae	copyLoop
	add	cx, dx				; adjust cx by overshoot
copyLoop:
	dec	bp
	dec	bp
	mov	ax,ss:[bp]			;copy data
	mov	ds:[si],ax
	add	si,2
	loop	copyLoop
	lea	si,ds:[bx].HED_next
	tst	dx
	jg	allocLoop			;loop until all data copied

	pop	ax, bx, cx, dx
	mov	{word}ds:[si], bx		; point last handle at
						;  event handle so we can get
						;  it back when dispatching
	jmp	afterStack

noStack:
	mov	ds:[bx].HE_bp,bp
	mov	ds:[bx].HE_handleSig,SIG_EVENT_REG
afterStack:

	; on the stack: OD.handle (bx), message (ax), ds

	INT_OFF				;exclusive access to everything

	pop	si				;si = OD handle
	mov	ds:[bx].HE_OD.handle, si
	pop	ds:[bx].HE_method		;store method

	; on the stack: ds

	push	si
	push	bp

	; on the stack: bp, bx, ds

	mov	bp, sp
	xchg	si, ss:[bp+4]	;si = ds

	; on the stack: bp, bx, bx

	xchg	si, ss:[bp+2]	;si = bx

	; on the stack: bp, ds, bx

	mov_trash	bp, ax			;bp = queue

	mov	si, bx				;ds:si = event

	; figure callingThread and save it

	clr	bx				;assume no return
	test	di,mask MF_CALL			;push value for callingThread
	jz	noRet
	mov	bx,ds:[currentThread]
	shr	bl
	shr	bl
	shr	bl
	shr	bl
noRet:
	mov	ds:[si].HE_callingThreadHigh,bh
	mov	ds:[si].HE_next.low, bl

	; handle (ds:si) is set up
	;	ax, bx - trashed

	test	di, mask MF_RECORD		;if recording then skip...
	jnz	recordExit
	inc	ds:[bp].HQ_counter		;for CheckDuplicate sync'ing
	test	di,mask MF_CHECK_DUPLICATE
	jz	noCheckDup

	call	CheckDuplicates
	LONG jnc removeEvent

	; link the puppy into the list

noCheckDup:
	inc	ds:[bp].HQ_counter		;for CheckDuplicate sync'ing
	mov	bx,si				;bx = si = new event

	test	di,mask MF_INSERT_AT_FRONT
	jnz	insertAtFront

	xchg	bx,ds:[bp].HQ_backPtr		;bx = last event
EC <	call	CheckEventHandleZ					>

	; si = our new event, bx = old last event

	tst	bx				;only event on queue ?
	jz	only
	or	ds:[bx].HE_next,si		;link them
	jmp	OM_SE_afterLink

	; insert the event at the front of the queue

insertAtFront:
	xchg	bx, ds:[bp].HQ_frontPtr		;bx = first event
EC <	call	CheckEventHandleZ					>

	; si = our new event, bx = old first event

	mov	ds:[si].HE_next, bx		;link them
	and	bx, 0xfff0			;only event on queue ?
	jnz	OM_SE_afterLink

	; this is the only event, so set the backPtr too

	mov	ds:[bp].HQ_backPtr,si

	; easiest just to fall through. this is a rare case and it's
	; only about 4 cycles difference (20 for the store vs. 16 for
	; a jump) and it's smaller besides... -- ardeb
only:
	mov	ds:[bp].HQ_frontPtr,si
	; because this label is used by tcl code as such
	; OM_SE_afterLink+31 if it is moved be sure to check that
	; the tcl code in /staff/pcgeos/Tools/swat/lib.new/objprof.tcl
	; still works!!!
OM_SE_afterLink label near

	mov	bx, bp				;bx = event queue handle
	mov	ax,ds:[si].HE_method
	mov	si,ds:[si].HE_OD.chunk

	test	di,mask MF_CALL			;test for remote call
	jz	noCall			;branch if no remote call

	; remote call needed -- call routine to block, will return after call
	; is finished
	
	; first we must recover bp from the stack since the return values
	; will be stuffed in our context switch stack frame before
	; WaitForRemoteCall returns

;	ON_STACK   bp ds bx
	pop	bp
;	ON_STACK   ds bx

	pop	ds		; recover original ds for fixup

	test	di, mask MF_CUSTOM
	jnz	OM_SE_customRemoteWait

	call	WaitForRemoteCall
	xchg	ax, di		; return ax correctly (1-byte inst)
	mov	di, MESSAGE_NO_ERROR

if	CATCH_MISSED_COM1_INTERRUPTS
	pushf
	call	LookForMissedCom1Interrupt
	popf
endif

	INT_ON

	InsertMessageProfileEntry PET_END_CALL, 0, ax

	pop	bx
	ret

	; finish up for recording an event
recordExit:
	INT_ON
	InsertMessageProfileEntry PET_END_CALL, 0, ax
	mov	ax, ss:[TPD_processHandle]	;store owner in next field
	mov	ds:[si].HE_next, ax

	mov	di, si			;di returns event handle
	mov	ax, ds:[di].HE_method
	mov	si, ds:[di].HE_OD.chunk
	pop	bp
	pop	ds
	pop	bx
	ret

;----------------------------

	; no remote call -- must wake up

noCall:

if	CATCH_MISSED_COM1_INTERRUPTS
	pushf
	call	LookForMissedCom1Interrupt
	popf
endif

	VSem	ds, [bx].HQ_semaphore

doneGood:
	test	di,mask MF_CUSTOM
	mov	di,MESSAGE_NO_ERROR

if	CATCH_MISSED_COM1_INTERRUPTS
	pushf
	call	LookForMissedCom1Interrupt
	popf
endif

	INT_ON

;	ON_STACK   bp ds bx
	pop	bp
	pop	ds
	pop	bx
OM_SE_exit label near
	InsertMessageProfileEntry PET_END_CALL, 0, ax
	jnz	ret4_2
	ret
ret4_2:
	ret	4

;----------------------------

	; remove event since combined

removeEvent:
	mov	ax,ds:[si].HE_method		;ax = ax passed
	mov	bx,si				;bx = handle
	mov	si,ds:[bx].HE_OD.chunk		;si = si passed

	; if this is an event with data in additional handles then this is
	; an error

EC <	cmp	ds:[bx].HE_handleSig, SIG_EVENT_STACK			>
EC <	ERROR_Z	CANNOT_REPLACE_EVENT_WITH_DATA				>

	call	FreeHandle			;turns on interrupts
	jmp	doneGood

;----------------------------
	; because this label is used by tcl code as such
	; OM_SE_customRemoveWait+9 if it is moved be sure to check that
	; the tcl code in /staff/pcgeos/Tools/swat/lib.new/objprof.tcl
	; still works!!!
OM_SE_customRemoteWait label near
	test	di, mask MF_STACK
	jnz	customStackRemoteWait
	call	WaitForRemoteCall
	InsertMessageProfileEntry PET_END_CALL, 1, ax
customWaitCommon:
	xchg	ax, di		; return ax correctly (1-byte inst)
	mov	di, MESSAGE_NO_ERROR
	INT_ON
	pop	bx
	ret	4

customStackRemoteWait:
	push	bp
	call	WaitForRemoteCall
	pop	bp
	jmp	customWaitCommon
ObjMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessageForceQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads DI with "mask MF_FORCE_QUEUE" before calling ObjMessage
		(basically a hack to save bytes).

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	various important but undocumented things
 
PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ObjMessageForceQueue	proc	near
	mov	di, mask MF_FORCE_QUEUE
	FALL_THRU	ObjMessageNear	;Don't change to REAL_FALL_THRU because
					; swat can't decode the stack.
ObjMessageForceQueue	endp

ObjMessageNear	proc	near
	call	ObjMessage
	ret
ObjMessageNear	endp

;-------------------------------



COMMENT @----------------------------------------------------------------------

FUNCTION:	CheckDuplicates

DESCRIPTION:	Check the event queue for a duplicate event

CALLED BY:	INTERNAL
		SendEvent

PASS:
	di - flags passed to ObjMessage
	ds:si - new event (in a new handle)
	ds:bp - handle of destination HandleQueue

RETURN:
	carry - set to put the event at the back of the queue

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/89		Initial version

------------------------------------------------------------------------------@

CheckDuplicates	proc	near

	;	if (queue not empty)
	;		tempPtr = HQ_backPtr
	;		repeat

tryAgain:
	mov	bx, ds:[bp].HQ_backPtr		;start looking at back of queue
	test	di, mask MF_CHECK_LAST_ONLY
	jnz	10$

	; if MF_CHECK_DUPLICATE and not MF_CHECK_LAST_ONLY, start at front

	mov	bx, ds:[bp].HQ_frontPtr
10$:

searchLoop:
	tst	bx				;test for empty
	jz	notFound
EC <	call	CheckEventHandle					>

	; To ensure that interrupts are not off too long, turn them on and off
	; again.  If the event queue has changed, start over. We decide if the
	; event queue has changed by checking the event counter which is
	; incremented every time the event queue is accessed.

	mov	ax,ds:[bp].HQ_counter
	INT_ON
	nop				;allows interrupts to really be on
					;since INT_ON delays one instruction
					;on the 8086
	INT_OFF
	cmp	ax,ds:[bp].HQ_counter
	jnz	tryAgain		; Not the same as before -- must
					; have changed so restart

	; queue is not empty
	; ds:bx = event on queue to test duplicate for

	; test for custom routine supplied to do event compare/combine

	;			if (MF_CUSTOM)
	;			else
	;				if (tempPtr->eventType == passed type)
	;				endif
	;			endif

	test	di, mask MF_MATCH_ALL
	jnz	dontCheckOD
	mov	ax,ds:[si].HE_OD.handle
	cmp	ax,ds:[bx].HE_OD.handle
	jnz	noMatch

	; if the destination is a process, a thread or a queue then don't
	; check the low word

	xchg	ax, bx
HMA <	cmp	ds:[bx].HG_type, SIG_UNUSED_FF	;make sure it's not kcode    >
HMA <	je	checkOD							     >

	cmp	ds:[bx].HG_type, SIG_NON_MEM
	xchg	ax, bx
	jae	dontCheckOD

	xchg	ax, bx				;is this a process ?
HMA <checkOD:								    >
	cmp	bx, ds:[bx].HM_owner
	xchg	ax, bx
	jz	dontCheckOD
	mov	ax,ds:[si].HE_OD.chunk
	cmp	ax,ds:[bx].HE_OD.chunk
	jnz	noMatch

dontCheckOD:
	test	di,mask MF_CUSTOM	;custom compare/combine routine ?
	jnz	custom
	mov	ax,ds:[si].HE_method
	cmp	ax,ds:[bx].HE_method	;no custom routine passed, compare
	jz	match		;event types

	;		until (tempPtr = PH_eventStartPtr or MF_CHECK_LAST_ONLY)

noMatch:
	mov	bx,ds:[bx].HE_next
	and	bx, 0xfff0
	test	di,mask MF_CHECK_LAST_ONLY
	jz	searchLoop

notFound:

	; if MF_DISCARD_IF_NO_MATCH then return a match, even though one was
	; not found

	test	di, mask MF_DISCARD_IF_NO_MATCH
	jnz	found

	stc				;put in event queue
	ret

	; match found -- act according to MF_REPLACE

match:
	test	di,mask MF_REPLACE	;if not replacing then just return
	jz	found

	; replace old event with new

	push	bx, cx, si
	mov	cx,7			;copy 7 words
CD_loop:
	lodsw
	mov	ds:[bx],ax
	add	bx,2
	loop	CD_loop
	pop	bx, cx, si

found:
	clc
	ret

;******************************************************

	; Handling special case - calling custom routine to check for a
	; matching event

custom:
	push	di
	push	bp
	push	si
	mov	ax,ds:[si].HE_method
	mov	bp,ds:[si].HE_bp
	mov	si,ds:[si].HE_OD.chunk
	;
	; Find the call vector on the stack, which looks like:

CD_stack	struct
    CD_si		word
    CD_bp		word
    CD_di		word
    CD_retAddrCD	word
    CD_bx		word
    CD_bp2		word
    CD_ds		word
    CD_retAddrOM	dword
    CD_customRoutine	dword
CD_stack	ends

	mov	di, sp
	call	ss:[di].CD_customRoutine
	pop	si
	mov	ds:[si].HE_bp, bp	;save bp (in case it was modified)

	tst	di			;set flags based on return value
	pop	bp
	pop	di

	jz	noMatch		;if PROC_SE_CONTINUE then continue
	js	found		;if PROC_SE_EXIT, get out of here
	jmp	notFound

CheckDuplicates	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	WaitForRemoteCall

DESCRIPTION:	Wait for a remote call to finish

CALLED BY:	INTERNAL
		SendEvent

PASS:
	interrupts off
	di - MessageFlags
	ds - from entry...
	bx - queue handle being called

RETURN:
	carry, cx, dx, bp - return values from caller
	di - ax return value
	ds - restored/fixed up

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	2/89		Initial version

------------------------------------------------------------------------------@

WaitForRemoteCall	proc	near

	; push correct handles for fixups and push address for later

	test	di,mask MF_FIXUP_DS or mask MF_FIXUP_ES
	jnz	dsOrBoth

	; fixup none -- save DS only

EC <	call	NullDSIfObjBlock					>
	push	ds
	mov	di,offset fixupNone
	jmp	notES

dsOrBoth:
	test	di,mask MF_FIXUP_ES
	jz	dsOnly

	; fixup both -- push handles for both segments

EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	CheckHandleLegal					>
EC <	mov	bx, es:[LMBH_handle]					>
EC <	call	CheckHandleLegal					>
EC <	pop	bx							>

	push	ds:[LMBH_handle]
	push	es:[LMBH_handle]

	mov	di,offset fixupDSES
	jmp	gotOffset

dsOnly:
EC <	push	bx							>
EC <	mov	bx, ds:[LMBH_handle]					>
EC <	call	CheckHandleLegal					>
EC <	pop	bx							>

	push	ds:[LMBH_handle]
	mov	di,offset fixupDS

notES:
EC <	call	NullESIfObjBlock					>
gotOffset:
	push	di			; push near return addr to which
					;  DispatchSI is to return

	LoadVarSeg	ds	; so it's there when we recover...

	; do a full block

if	SUPPORT_32BIT_DATA_REGS
	push	ds
	push	esi
	push	edi
	push	ecx
	pushf
	push	edx
	mov	ecx, eax		; ecx.high = eax.high
	rol	ebx, 16			; bx = orig ebx.high
	mov	cx, bx			; cx = orig ebx.high
	ror	ebx, 16			; restore ebx
	push	ecx			; push eax.high, ebx.high
	push	es
	push	fs
	push	gs
	push	ebp
else
	push	ds
	push	si
	push	di
	push	cx
	pushf
	push	dx
	push	es
	push	bp
endif

if UTILITY_MAPPING_WINDOW
	;
	; save current utility mapping windows
	;
	call	UtilWindowSaveMapping
endif

if	TRACK_INTER_RESOURCE_CALLS
FXIP <	push	ds:[curXIPResourceHandle] ;Save the current XIP		>
					  ;resource handle
endif
FXIP <	push	ds:[curXIPPage]						>
	mov	si,ds:[currentThread]
	mov	ds:[si][HT_saveSS],ss
	mov	ds:[si][HT_saveSP],sp

	; switch to kernel mode

	call	SwitchToKernel			;ds <- idata

	; now wake the receiver thing up

	VSem	ds,[bx].HQ_semaphore

	jmp	Dispatch


;----------
; Return points for fixing things up. We're allowed to nuke BX here, and DS
; is already idata from the LoadVarSeg we do before the block.
;
; Note that if we're only fixing up DS, or not fixing up anything at all,
; ES was restored by DispatchSI. In the fixupNone case, however, we do need
; to recover DS as we loaded DS with idata before blocking.

fixupDSES:
	pop	bx			; recover es's handle
EC <	call	CheckHandleLegal					>
	mov	es, ds:[bx].HM_addr	; and reload ES

fixupDS:
	pop	bx
EC <	call	CheckHandleLegal					>
	mov	ds, ds:[bx].HM_addr
	ret

fixupNone:
	pop	ds
	ret

WaitForRemoteCall	endp

;---------------------------------------------------

NEC <ECCheckEventHandle	proc	far					>
NEC <	ret								>
NEC <ECCheckEventHandle	endp						>

if	ERROR_CHECK

ECCheckEventHandle	proc	far
	call	CheckEventHandle
	ret
ECCheckEventHandle	endp

	; bx = event handle

CheckEventHandle	proc	near
	pushf
	push	ds
	LoadVarSeg	ds

	test	bx,15
	ERROR_NZ	ILLEGAL_HANDLE
	cmp	bx, ds:[loaderVars].KLV_handleTableStart
	ERROR_B	ILLEGAL_HANDLE
	cmp	bx,ds:[loaderVars].KLV_lastHandle
	ERROR_AE	ILLEGAL_HANDLE

	cmp	ds:[bx].HE_handleSig,SIG_EVENT_REG
	jz	10$
	cmp	ds:[bx].HE_handleSig,SIG_EVENT_STACK
	ERROR_NZ	ILLEGAL_HANDLE
10$:

	pop	ds
	popf
	ret

CheckEventHandle	endp


CheckEventHandleZ	proc	near
	tst	bx
	jz	10$
	call	CheckEventHandle
10$:
	ret

CheckEventHandleZ	endp

endif
