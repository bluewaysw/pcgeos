COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Timer
FILE:		timerList.asm

ROUTINES:
	Name				Description
	----				-----------
   GLB	TimerStart			Start a timer
   GLB  TimerStartSetOwner		Start a timer for a given owner
   GLB	TimerSleep			Sleep for a given ammount of time
   GLB	TimerBlockOnTimedQueue		Block on a semaphore with timeout
   GLB	TimerStop			Remove a timer

   INT	InsertTimedAction		Insert a timed action

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This file implements the timed action routines.  Timed actions are
either routines that get called on a timed basis or events that get sent on
a timed basis.

	$Id: timerList.asm,v 1.1 97/04/05 01:15:33 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimerStart, TimerStartSetOwner

DESCRIPTION:	Start a timer so that the specified routine will be called or
		events will be sent to the specified process.

CALLED BY:	GLOBAL

PASS:
	al	- TimerType
	bx:si	- timer OD (for TIMER_EVENT_???)
		    OR timer routine vector (for TIMER_ROUTINE_???)
	cx	- timer count in until first timeout (ticks for everything
		  but TIMER_MS_ROUTINE_ONE_SHOT; milliseconds for that)
		    OR TimerCompressedDate (for TIMER_EVENT_REAL_TIME)
	dx	- timer method (for TIMER_EVENT_???)
		    OR timer data (passed in ax (for TIMER_ROUTINE_???)
	di	- timer interval (for continual timers only)
		    OR hours (high byte) and minutes (low byte) (for
		    TIMER_EVENT_REAL_TIME)
	bp	- owner of timer (for TimerStartSetOwner)

RETURN:
	ax - timer ID (needed for TimerStop)
	bx - timer handle
	(interrupts in same state as passed)

DESTROYED:
	none

	For TIMER_EVENT_REAL_TIME
		Pass:
			ax - method
			cx - timer handle
			dx - TimerCompressedDate
			bp - hours (high byte) and minutes (low byte)

	For TIMER_ROUTINE_REAL_TIME
		Pass:
			ax - data
			cx - timer handle
			dx - TimerCompressedDate
			bp - hour (high byte) and minutes (low byte)

	For TIMER_EVENT_[all others]
		Pass:
			ax - method
			cx:dx - tick count (returned by TimerGetCount)
			bp - timer ID (interval, for continual timers)

	For TIMER_ROUTINE_?
		Pass:
			ax - data
			cx:dx - tick count (returned by TimerGetCount)
		Return:
		Destroy:ax, bx, cx, dx, si, di, bp, ds, es

	For TIMER_MS_ROUTINE_ONE_SHOT
		Pass:
			ax - data
			INTERRUPTS OFF
		Return:	nothing
		Destroy:	ax, bx, si, ds

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
-------------------------------------------------------------------------------@
TimerStart 		proc far
	uses	bp
	.enter
	;
	; Set owner of timer to be owner of current thread
	mov	bp, ss:[TPD_processHandle]
	call	TimerStartSetOwner
	.leave
	ret
TimerStart		endp

TimerStartSetOwner 	proc far
	uses	cx,dx,ds,di
	.enter

	; check timer type

EC <	test	al, 1							>
EC <	ERROR_NZ	TIMER_START_BAD_TYPE				>
EC <	cmp	al, TimerType						>
EC <	ERROR_AE	TIMER_START_BAD_TYPE				>

if 0		;Don't do this! CheckDS_ES turns on interrupts, nimrod!
		;ECAssertValidFarPointerXIP does too...

	; check timer destination
if	FULL_EXECUTE_IN_PLACE
EC<	cmp	al, TIMER_MS_ROUTINE_ONE_SHOT				>
EC<	ja	doneWithCheck						>
EC<	cmp	al, TIMER_ROUTINE_CONTINUAL				>
EC<	ja	doneWithCheck						>
EC<	call	ECAssertValidFarPointerXIP				>
EC<doneWithCheck:							>
endif

	; check routine

EC <	cmp	al, TIMER_ROUTINE_CONTINUAL				>
EC <	ja	10$							>
EC <	push	ds							>
EC <	mov	ds,bx							>
EC <	call	CheckDS_ES						>
EC <	pop	ds							>
EC <10$:								>
endif

	pushf
	LoadVarSeg	ds
	INT_OFF

	; if this is a milisecond timer then convert the time from miliseconds
	; to ticks and remainder (value to set in timer)
	;	cx = miliseconds   -> cx = ticks, dx = remainder

	cmp	al, TIMER_MS_ROUTINE_ONE_SHOT
	jnz	notMsTimer

	mov	di, dx				;di <- data

	push	ax

	mov	ax, TIMER_UNITS_PER_MS
	mul	cx				;dx.ax = units
	mov	cx, GEOS_TIMER_VALUE
	div	cx				;ax = ticks, dx = remainder
	mov_tr	cx, ax

	; we need to convert the time being "from now" to being "from last
	; timer interrupt"

	; read (dynamic) current timer value

	call	ReadTimer			;ax = timer units
	tst	ax
	jz	updatedCount

	sub	ax, ds:[currentTimerCount]	;ax = -units gone by

	sub	dx, ax				;add in time gone by (by
						;subtracting a negative)
						;since timer was last
						;programmed.

updatedCount:
	;
	;  It is possible a less than one-tick ms timer to actually expire
	;	in the tick two-removed from when it was started.
	;  If we are called by a msec timer at the end of a tick,
	;	and it takes us until the beginning of the next
	;	tick to reach here, a msec timer approaching one
	;	tick in duration could actually fire in the tick
	;	twice removed.
	;  Got that?
	;		-- todd 01/29/93

	add	dx, ds:[unitsSinceLastTick]
	cmp	dx, GEOS_TIMER_VALUE		;does that take it into the
						; next tick?
	jb	noWrap
	inc	cx				;yup, so one more tick in cx
	sub	dx, GEOS_TIMER_VALUE		; and remove a tick-equivalent
						; from dx

	cmp	dx, GEOS_TIMER_VALUE		; does it take us into the
						; the next next tick?
	jb	noWrap
	inc	cx				;yep, so one more tick in cx
	sub	dx, GEOS_TIMER_VALUE		; and remove a tick from dx

EC<	cmp	dx, GEOS_TIMER_VALUE		; it doesn't put us in the >
EC<	ERROR_A	-1				; next-next-next tick, I hope?>

noWrap:
	pop	ax

notMsTimer:
	push	bx		; save high word of OD
	mov	bx, bp		; set owner of timer 
	call	AllocateHandle
	
	; Add an ID if needed
	
	cmp	al, TIMER_ROUTINE_CONTINUAL
	je	initHandle
	cmp	al, TIMER_EVENT_CONTINUAL	; TIMER_EVENT_CONTINUAL,
	jb	getID				; TIMER_MS_ROUTINE_ONE_SHOT
	cmp	al, TIMER_ROUTINE_REAL_TIME	; & TIMER_*_REAL_TIME all
	jbe	initHandle			; have no ID, or one is provided
getID:	
	mov	di, ds:[timerID]
	inc	di
	jz	noZeroIDPlease		; don't allow ID to wrap to 0
storeID:
	mov	ds:[timerID], di
initHandle:
	mov	ds:[bx].HTI_handleSig, SIG_TIMER
	mov	ds:[bx].HTI_type, al
	pop	ds:[bx].HTI_OD.handle
	mov	ds:[bx].HTI_OD.chunk, si
	mov	ds:[bx].HTI_intervalOrID, di
	mov	ds:[bx].HTI_timeRemaining, cx
	mov	ds:[bx].HTI_method, dx	; store message # (event timers), word
					;  of data (routine timers), or clock
					;  units (ms timers)

	call	InsertTimedAction

	mov	al, ds:[bx].HTI_type
	cmp	al, TIMER_MS_ROUTINE_ONE_SHOT
	je	return0
	cmp	al, TIMER_ROUTINE_CONTINUAL
	je	return0
	cmp	al, TIMER_EVENT_CONTINUAL
	jne	returnID
return0:
	clr	di		; return 0 (expected value for TimerStop) for
				;  continual or ms timers
returnID:
	mov_trash	ax, di
	call	SafePopf

	.leave
	ret

noZeroIDPlease:
	inc	di
	jmp	storeID
TimerStartSetOwner	endp

COMMENT @----------------------------------------------------------------------

C FUNCTION:	TimerSleep

C DECLARATION:	extern void
			_far _pascal TimerSleep(word ticks);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	3/91		Initial version

------------------------------------------------------------------------------@
	SetGeosConvention
TIMERSLEEP	proc	far	; mh:hptr
	C_GetOneWordArg	ax,   bx,cx	;ax = ticks

	FALL_THRU	TimerSleep

TIMERSLEEP	endp
	SetDefaultConvention

COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimerSleep

DESCRIPTION:	Block the current thread for the given amount of time

CALLED BY:	GLOBAL

PASS:
	ax - amount to time (in ticks) to block for

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Allocate a timed action structure on the stack, initialize it as
type TIMED_SLEEP and block on the threadID field.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
-------------------------------------------------------------------------------@

TimerSleep	proc	far	uses ax, bx, cx, dx, ds
	.enter

	; start up the timer with the given time
	mov_tr	cx,ax			;time
	clr	dx			;initialize HTI_method to zero to
					; avoid death on wakeup
	mov	al,TIMER_SLEEP
	call	TimerStart

	push	bx			; save for freeing

	mov	ax,seg idata			;ax = segment of queue
	mov	ds, ax			; ds <- idata for FreeHandle (while
					;  we've got it here...)
	add	bx,offset HTI_method
	call	BlockOnLongQueue

	; this point is reached after the timer interrupt handler has woken
	; up the thread

	pop	bx
	call	FreeHandle
if TEST_TIMER_FREE
TimerSleepFreeHandle	label	near
endif

	.leave
	ret
TimerSleep	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimerBlockOnTimedQueue

DESCRIPTION:	Block on the given queue until another thread wakes this
		thread up or until the time out value has elapsed

CALLED BY:	GLOBAL

PASS:
	ax - segment of queue
	bx - offset of queue
	cx - time out value

RETURN:
	carry - set if time out

DESTROYED:
	ax, bx, cx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Special code is needed since PSem and VSem do not turn off interrupts.
	This is detailed in WakeUpLongQueue.

		BlockOnLongQueue:
			INT_OFF
			test	queue,15
			jz	BOLQ_block
			dec	queue
			ret
		BOLQ_block:
			** Block on the queue

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
-------------------------------------------------------------------------------@

TimerBlockOnTimedQueue	proc	far	uses	ax, bx, cx, dx, si, ds
	.enter

	; since there is a race between two events -- the timer timeout and
	; the semaphore wake-up, turn off interrupts so that we have a
	; consisent state

	INT_OFF

	; test to see if the semaphore wake-up has already happened, in which
	; case we don't need to allocate a timer at all, we just return

	; if the queue has any of the low 4 bits set, we assume that the queue
	; has timed out and is awaiting a wake-up

	mov	ds,ax			;ds:bx = queue
	test	{word}ds:[bx],15
	jz	10$
	dec	{word}ds:[bx]
	jmp	short noTimeout
10$:

	; if the timeout value is 0 then this is really a 'PSem with no wait'
	; call, so timeout (since we just found out that the queue has not
	; been woken up)

	jcxz	timeoutV

	; allocate a handle for the timer

	push	ax				;save segment of queue

	xchg	bx,ax				;bx:si = queue that is blocked
	xchg	si,ax				;on (passed in ax:bx)
	mov	al,TIMER_SEMAPHORE		;timer type

	call	LoadVarSegDS
	mov	dx,ds:[currentThread]		;save thread handle in
						;HTI_method field
						;NOTE: THIS USES currentThread
						;INSTEAD OF TPD_threadHandle TO
						;ALLOW BLOCKING ON TIMED
						;SEMAPHORES FROM DOS IN WAIT/
						;POST SUPPORT

	call	TimerStart			;interrupts remain off

	xchg	ax, dx				;dx = timer ID (in case we need
						;to stop the timer)
	pop	ax				;ax:bx = queue
	xchg	bx,si				;si = timer handle, bx = queue
						;			offset
	clc					;carry will reflect time out
	call	BlockOnLongQueue
	jc	timeout				;if timeout then branch

	mov	bx,si				;bx = handle
	xchg	ax,dx				;ax = ID
	call	TimerStop

noTimeout:
	clc

timeout:

	INT_ON
	.leave
	ret
timeoutV:
	;
	; PSem with no wait case -- need to V the semaphore too (this is handled
	; by HandleSemaphore when a timeout actually occurs)
	;
	inc	{word}ds:[bx-Sem_queue].Sem_value
	stc
	jmp	timeout
	
TimerBlockOnTimedQueue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerCheckList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify the integrity of the timed-action list (EC ONLY)

CALLED BY:	InsertTimedAction, TimerStop
PASS:		ds	= idata
		bx	= handle that shouldn't be in the list, if any
		interrupts off
RETURN:		only if list is ok
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if ERROR_CHECK
TimerCheckList		proc	far	uses ax, di
	.enter
	clr	ax
	mov	di,offset timeListPtr - offset HTI_next
checkLoop:
	mov	di, ds:[di].HTI_next
	tst	di
	jz	done

	test	di,0fh
	ERROR_NZ	CORRUPT_TIMER_LIST

	cmp	ds:[di].HTI_handleSig,SIG_TIMER
	ERROR_NZ	CORRUPT_TIMER_LIST

	cmp	bx, di
	jne	checkLoop
	ERROR	INSERT_TIME_DUPLICATE
done:
	.leave
	ret
TimerCheckList		endp
endif


COMMENT @-----------------------------------------------------------------------

FUNCTION:	InsertTimedAction

DESCRIPTION:	Insert a timed action structure in the timed action list.

CALLED BY:	INTERNAL
		HandleRoutineContinual, HandleEventContinual, TimerSleep,
		TimerStart

PASS:
	interrupts off
	bx - handle of timed action.
	ds - idata

RETURN:
	interrupts still off

DESTROYED:
	ax

REGISTER/STACK USAGE:
	ax - temp
	si - last
	di - ptr

PSEUDO CODE/STRATEGY:
	temp = time to fire for passed structure
	last = &(timerList)
	while (FOREVER)
		ptr = *last
		if (ptr == NULL)
			/* insert structure here */
		else if (temp < ptr->time)
			/* insert structure before ptr on the list */
		else
			temp -= ptr->time
		endif
		last = &(ptr->next)
	end

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
-------------------------------------------------------------------------------@

InsertTimedAction	proc	near	uses cx, si, di
	.enter

	; Make sure these flags are off: direction, interrupt

EC <	push	ax							>
EC <	pushf								>
EC <	pop	ax							>
EC <	test	ax, mask CPU_INTERRUPT or mask CPU_DIRECTION		>
EC <	ERROR_NZ	INSERT_TIME_BAD_FLAGS				>
EC <	pop	ax							>

	; make sure that the current list is not corrupted

EC <	call	TimerCheckList						>

	; Set ax.cx to be the time remaining for this timer

	cmp	ds:[bx].HTI_type, TIMER_EVENT_REAL_TIME
	je	realTimeInsertTimer

	cmp	ds:[bx].HTI_type, TIMER_ROUTINE_REAL_TIME
	je	realTimeInsertTimer


	mov	cx, ds:[bx].HTI_method		;cx = units left
	mov	ax, ds:[bx].HTI_timeRemaining	;ax = ticks left

	cmp	ds:[bx].HTI_type,		;if this is a ms one-shot
		TIMER_MS_ROUTINE_ONE_SHOT	; timer, remaining time (ticks)
	je	haveTimeRemaining		; may well be 0

	clr	cx		; no units if not ms-one-shot

	; If ticks remaining is 0, replace it with 1

	tst	ax
	jnz	haveTimeRemaining
	inc	ax
	mov	ds:[bx].HTI_timeRemaining,ax

haveTimeRemaining:

	; temp ax.cx = = time to fire for passed structure
	; last = &(timerList)

	mov	si,offset timeListPtr

	; while (FOREVER)
	;	ptr = *last

timerLoop:
	mov	di,ds:[si]

	;	if (ptr == NULL)
	;		/* insert structure here */

	tst	di
	jz	insertHere

	;	else if (temp <= ptr->time)
	;		/* insert structure before ptr on the list */

	cmp	ax,ds:[di].HTI_timeRemaining
	jb	subInsertHere
	ja	ticksNotEqual
	cmp	ds:[di].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
	jnz	ticksNotEqual
	cmp	cx, ds:[di].HTI_method
	jbe	subInsertHere
ticksNotEqual:

	;	else
	;		temp -= ptr->time

	sub	ax, ds:[di].HTI_timeRemaining

	;	endif
	;	last = &(ptr->next)
	; end

	lea	si,ds:[di].HTI_next
	jmp	timerLoop

	;
	; Found -- insert here.  If placing before a timer with a long time
	; remaining, then adjust the next timer to be based on the timer
	; we're inserting
	;

subInsertHere:
	sub	ds:[di].HTI_timeRemaining,ax
insertHere:
	mov	ds:[bx].HTI_timeRemaining,ax	;set time remianing for new one
	mov	ds:[bx].HTI_next,di		;link to rest of list
	mov	ds:[si],bx			;link first part of list to us

if TEST_TIMER_CODE
	push	ax
	mov	ax, TIMER_MS_CREATE
	cmp	ds:[bx].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
	je	addTimerLog
	mov	ax, TIMER_OTHER_CREATE
addTimerLog:
	call	TestTimerCodeAddLogEntry
	pop	ax
endif

	; if we're inserting a milisecond timer then handle specially
	cmp	ds:[bx].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
	jnz	done

	; if we're inserting at the front then we must reprogram

	cmp	si, offset timeListPtr
	jnz	done
	mov	si, bx				;si = timer handle
	call	ReprogramTimerSI

done:
	.leave
	ret

	;
	; insert a real-time timer into the linked list
	;
realTimeInsertTimer:
	mov	si, offset realTimeListPtr
	mov	ax, ds:[bx].HTI_timeRemaining	; ax = TimerCompressedDate
	mov	cx, ds:[bx].HTI_intervalOrID	; cx = hours/minutes

realTimeLoop:
	mov	di, ds:[si]			; HandleTimer => DS:DI
	tst	di
	jz	realTimeInsert
	cmp	ax, ds:[di].HTI_timeRemaining
	jb	realTimeInsert
	ja	realTimeNext
	cmp	cx, ds:[di].HTI_intervalOrID
	jb	realTimeInsert

realTimeNext:
	lea	si, ds:[di].HTI_next
	jmp	realTimeLoop
	;
	; Found -- insert here.
	;
realTimeInsert:
	mov	ds:[bx].HTI_next, di		; link to rest of list
	mov	ds:[si], bx			; link first part of list to us

if TEST_TIMER_CODE
	push	ax
	mov	ax, TIMER_OTHER_CREATE
	call	TestTimerCodeAddLogEntry
	pop	ax
endif
	;
	; If we're on a machine with a real-time timer, re-program the sucker
	;
if HARDWARE_RTC_SUPPORT
	cmp	si, offset realTimeListPtr
	jnz	done
	mov	si, ds:[si]			; ds:si = HandleTimer
	call	ReprogramRealTimeTimer
endif
	jmp	done

InsertTimedAction	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	ReprogramRealTimeTimer

DESCRIPTION:	Convert the # of days since 1980 to a day/month/year

CALLED BY:	GLOBAL

PASS:		ds:si	= HandleTimer

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REGISTER/STACK USAGE:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/93		Initial version
-------------------------------------------------------------------------------@
if HARDWARE_RTC_SUPPORT

ifidn	HARDWARE_TYPE, <GULLIVER>

ReprogramRealTimeTimer	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	;  Reset the timer
	mov	ah, TRTCF_RESET_RTC_ALARM
	int	TIMER_RTC_BIOS_INT

	;
	;  Get the new settings for the RT timer
	call	TimerRTCGetBCDRepresentation	; al <- seconds
						; ah <- minutes
						; bl <- 0
						; bh <- hour
						; cl <- day
						; ch <- month
						; dx <- year
						;   dh <- '19'
						;   dl <- '__'

	;
	;  Reorder values and call BIOS.  Elan contains an equivalent of the
	;  Motorla MC146818 which only supports alarms on hour:min:sec and
	;  they occur every 24 hours (i.e., you cannot set an alarm to occur
	;  on a specific DAY in the future).  But that is okay since the
	;  handler checks for timers that have already expired.  If none
	;  expired, no worries.
	;
	mov	ch, bh				; ch = Hour
	mov	cl, ah				; cl = Minute
	mov	dh, al				; dh = Second
	
	mov	ah, TRTCF_SET_RTC_ALARM
	int	TIMER_RTC_BIOS_INT
EC <	ERROR_C	TIMER_SET_RTC_RETURNED_ERROR				>
	
	.leave
	ret
ReprogramRealTimeTimer	endp

else
	.err <need to reprogram RTC here>

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ByteToBCD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a byte to BCD

CALLED BY:	RTCGetBCDRepresentation

PASS:		al	-> byte to translate (0-99)

RETURN:		al	<- BCD representation

DESTROYED:	If using the _IMMEDIATE_SHIFT version, dh is destroyed
		Otherwise, nothing is destroyed.

SIDE EFFECTS:
		None

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/ 3/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn HARDWARE_TYPE, <PC>
_IMMEDIATE_SHIFT equ FALSE
else
_IMMEDIATE_SHIFT equ TRUE
endif

ByteToBCD	proc	near
if not _IMMEDIATE_SHIFT
	uses	cx
	.enter

	mov	ch, ah		; save high-byte

	aam		; ah <- bcd tens digit, al <- bcd ones digit

	;
	;  Move the high-bcd-digit into the high nibble
	;	of ah so we can 'or' it into al.
	;
	mov	cl, 4
	shl	ah, cl

	or	al, ah		; set the high digit in al

	mov	ah, ch		; restore high-byte of al

	.leave
	ret
else
.186
	uses	dx
	.enter
	mov	dh, ah
	aam
	shl	ah, 4
	or	al, ah
	mov	ah, dh
	.leave
	ret
.8086
endif
ByteToBCD	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerRTCGetBCDRepresentation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an RTC timer, determine its BCD representation

CALLED BY:	ReprogramRealTimeTimer

PASS:		ds:si	-> RTC timer

RETURN:		al	<- seconds	(0)
		ah	<- minutes	(1-60)
		bh	<- hour		(1-24)
		cl	<- day		(1-31)
		ch	<- month	(1-12)
		dx	<- year		(1980+)
			   (dh <- century, dl <- year)
DESTROYED:	bl

SIDE EFFECTS:
		none

PSEUDO CODE/STRATEGY:
		For some reason, RTC BIOS just _loves_ using BCD
		encoding.  Why?  I have no idea.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	6/ 1/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	VG230_COMMON or GULLIVER_COMMON

	.assert offset TCD_YEAR		eq	9
	.assert offset TCD_MONTH 	eq	5
TimerRTCGetBCDRepresentation	proc	near
	uses	bp
	.enter

	;
	;  First, get the year.  Return it as 19__, since
	;	BIOS's which want just the last '__' can
	;	just use the low byte, and those that
	;	don't can use the high byte.
	mov	bx, ds:[si].HTI_timeRemaining	; bx <- TimerCompressedDate
	mov	al, bh				; al <- bx shr 8
	shr	al, 1				; al <- bx shr offset TCD_YEAR
	clr	ah				; ax <- year
	mov_tr	bp, ax				; bp <- year

	;
	;  All real-time-timers start from 1980, so
	;	adjust actual value to reflect that.
	add	bp, 1980			; year => BP

	;
	;  Calculate month and day for timer
	and	bx, not (mask TCD_YEAR)		; bx <- month/day

	mov	cl, 8 - (offset TCD_MONTH)
	shl	bx, cl				; bh <- month

	shr	bl, cl				; bl <- day

	;
	;  Get hours and minutes
	mov	cx, ds:[si].HTI_intervalOrID	; hours => CH, minutes => CL


	;
	;  Convert the binary values that we currently have
	;	into their bcd representations

	;
	;  Convert minutes/seconds
	mov	al, cl				; minutes => AL
	call	ByteToBCD	; al <- byte in BCD
	mov	ah, al				; ah <- minutes (BCD)
	clr	al				; al <- seconds (BCD)

	push	ax				; PUSH seconds/minutes

	;
	;  Convert hours
	mov	al, ch				; hours => AL
	call	ByteToBCD	; al <- byte in BCD
	mov	ah, al				; ah <- hours (BCD)
	clr	al				; al <- DOW

	push	ax				; PUSH DOW/hours

	;
	;  Convert months/days
	mov	al, bh				; months => AL
	call	ByteToBCD	; al <- byte in BCD
	mov	ah, al				; ah <- month (BCD)

	mov	al, bl				; day => AL
	call	ByteToBCD	; al <- byte in BCD
						; al <- day (BCD)

	push	ax				; PUSH months/days

	;
	;  Divide year up into century and year
	mov_tr	ax, bp				; dxax <- full year
	clr	dx

	mov	cx, 100				; seperate year and century
	div	cx				; al <- century, dl <- year

	;
	;  Convert year to bcd
						; al <- century
	call	ByteToBCD	; al <- byte in BCD
	mov	ah, al				; ah <- century (BCD)

	mov	al, dl				; al <- year bcd
	call	ByteToBCD	; al <- byte in BCD

	mov_tr	dx, ax				; dh <- century (BCD)
						; dl <- year (BCD)

	pop	cx				; ch <- month
						; cl <- day

	pop	bx				; bh <- hour

	pop	ax				; ah <- minutes
						; al <- seconds
	.leave
	ret
TimerRTCGetBCDRepresentation	endp
endif	; BULLET & JEDI & GULLIVER


endif	; HARDWARE_RTC_SUPPORT

COMMENT @-----------------------------------------------------------------------

FUNCTION:	TimerStop

DESCRIPTION:	Remove a timer structure from the timed action list

CALLED BY:	GLOBAL

PASS:
	bx - handle of timer to remove
	ax - ID returned by TimerStart (always 0 for continual timers)

RETURN:
	carry - set if no timer found
	interrupts in same state as passed

DESTROYED:
	ax, bx

REGISTER/STACK USAGE:
	ax - temp
	si - last
	di - ptr

PSEUDO CODE/STRATEGY:
	last = &(timerList)
	while (FOREVER)
		ptr = *last
		if (ptr == NULL)
			/* return carry set */
		else if (target == ptr)
			/* remove structure *last */
		endif
		last = &(ptr->next)
	end

REGISTER/STACK USAGE:
	dx:cx - address of structure to remove
	ds:si - structure on list
	es:di - next structure on list
	bp - timeToFire for one being removed
	bl - first flag

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
-------------------------------------------------------------------------------@

TimerStop	proc	far
	push	si, di, ds
	pushf
	LoadVarSeg	ds
	INT_OFF

	mov	si, offset timeListPtr
	cmp	ds:[bx].HTI_type, TIMER_EVENT_REAL_TIME
	je	realTime
	cmp	ds:[bx].HTI_type, TIMER_ROUTINE_REAL_TIME
	jne	TS_loop
realTime:
	mov	si, offset realTimeListPtr

	; while (FOREVER)
	;	ptr = *last

TS_loop:
	mov	di,ds:[si]

	;	if (ptr == NULL)
	;		/* return carry set -- timer must have expired */

	tst	di
	stc
	jz	TS_done

	;	else if (target == ptr)
	;		/* remove structure *last */

	cmp	bx,di
	jz	TS_removeHere

	;	endif
	;	last = &(ptr->next)
	; end

	lea	si,ds:[di].HTI_next
	jmp	short TS_loop

	;
	; Remove timer here, but first check to make sure that the ID's match
	; (if necessary). The ID is used to handle the case where a one-shot
	; expires and then gets re-used as a timer handle.
	;

TS_removeHere:
	tst	ax		; continual or ms?
	jz	checkMS
	
	cmp	ax, ds:[di].HTI_intervalOrID
	jne	timerExpired	; if ID mismatch, timer definitely history

				; make sure the timer's actually a one-shot.
				;  it could be a continual whose interval
				;  happens to match the ID we're looking for

	mov	al, ds:[di].HTI_type
	cmp	al, TIMER_ROUTINE_CONTINUAL
	je	timerExpired
	cmp	al, TIMER_EVENT_CONTINUAL
	jne	removeIt	; ID matched, and timer ain't continual,
				;  so we really should biff the thing....

timerExpired:
	stc
	jmp	TS_done

checkMS:
	cmp	ds:[di].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
	jne	removeIt

	;  we want to remove a msec timer.  It's safe to do so,
	;  provided the hardware timer hasn't been reprogrammed
	;  to expire yet.	-- todd 03/08/93
	tst	ds:[di].HTI_timeRemaining	; # of ticks left?
	jnz	removeIt

	;  
	;  we can't re-set the timer to stop a msec timer, so we
	;  just make it call a dummy-routine (actually, a dummy
	;  instruction)		-- todd 09/22/92

	;
	;  however, when we do so, we need to make sure it is
	;  owned by the kernel.  If it isn't, it could be removed
	;  by the handle-clean-up code after the owning geode
	;  left but before it actually expired.  This will could
	;  cause the hardware timer to be reset for a msec timer,
	;  but when it expires, no msec timer is to be found...
	;			-- todd 03/08/93

	mov	ds:[di].HTI_OD.segment, cs
	mov	ds:[di].HTI_OD.offset, offset farReturnInstruction

	mov	ds:[di].HTI_owner, handle 0	; make it owned by kernel
	clc
	jmp	short TS_done
removeIt:

	mov	al, ds:[di].HTI_type

	mov	di,ds:[di].HTI_next		;di = next structure
	mov	ds:[si],di			;unlink from list

	; If we just unlinked a real-time timer, we might
	; want to reprogram the clock.  AL has the timer
	; type.

	cmp	al, TIMER_EVENT_REAL_TIME
	je	stopRealTime
	cmp	al, TIMER_ROUTINE_REAL_TIME
	je	stopRealTime

	; if not the last one then add time of timer removed to time of
	; next timer

	clr	ax				; assume empty list, so tTNF
						;  should be zero
	tst	di
	jz	noNext

	; while adjusting next, set ax to be proper tTNF should the stopped
	; timer have been the first one on the list (in which case di is
	; now the first one...)
	mov	ax, ds:[di].HTI_timeRemaining
	add	ax, ds:[bx].HTI_timeRemaining
	mov	ds:[di].HTI_timeRemaining, ax

noNext:

	; free timer handle

	call	FreeHandle

if TEST_TIMER_FREE
TimerStopFreeHandle	label	near
endif
	clc

TS_done:
	mov	al, 1			;Set AL to 1 to show that the
					; carry was clear.
	jnc	99$
	clr	al			;Else, clear flag (saying carry was
					; clear)
99$:
	call	SafePopf		;Restore interrupt state
	cmp	al, 1			;Set carry if it was set before 
	pop	si, di, ds

farReturnInstruction:			; used for "stopped" msec timers
	ret

stopRealTime:
	;
	; When we stop a real-time clock, we should reprogram
	; the real-time hardware so we don't have any spurious
	; RTC interrupts.

	call	CheckRealTimeTimers

	clr	ax
	jmp	noNext

TimerStop	endp


