COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Timer
FILE:		timerInt.asm

ROUTINES:
	Name				Description
	----				-----------
    INT TimerInterrupt		Handle a timer interrupt

    INT IntRecordAddress	From within an interrupt routine, log the
				address pointer passed, in <handle><offset>
				form, to a cyclical buffer for analysis at
				a later point in time under swat. -- For
				crude CPU usage survey.

    INT IntProfileBufferWrapped From within an interrupt routine, log the
				address pointer passed, in <handle><offset>
				form, to a cyclical buffer for analysis at
				a later point in time under swat. -- For
				crude CPU usage survey.

    INT IntSegmentToHandle	From within an interrupt routine, given a
				segment value, return the corresponding
				handle -- For crude CPU usage	 survey
				only!

    INT ReprogramTimerSI	Reprogram the timer chip for the given
				timer handle and for the given number of

    INT ReprogramTimer		Reprogram the timer chip for the given
				timer handle and for the given number of

    INT ReadTimer		Read the value in the timer

    INT FarWriteTimer		Write a new interval to the timer

    INT WriteTimer		Write a new interval to the timer

    GLB TimerStartCount		Record the timer value at the beginning of
				an operation, for use in calculating the
				length of an operation.

    GLB TimerEndCount		Record the timer value at the end of an
				operation, & then calculate the time spent
				in the operation.

    INT HandleRoutineContinual	Handle a timed action of the type
				TIMER_ROUTINE_CONTINUAL

    INT CallTimerRoutine	Utility routine for HandleRoutineContinual
				and HandleRoutineOneShot to call the
				routine in question

    INT HandleRoutineOneShot	Handle a timed action of the type
				TIMER_ROUTINE_ONE_SHOT

    INT HandleMsRoutineOneShot	Handle a timed action of the type
				TIMER_MS_ROUTINE_ONE_SHOT

    INT HandleEventContinual	Handle a timed action of the type
				TIMER_EVENT_CONTINUAL

    INT SendTimerEvent		Common code to send an event from a timer

    INT HandleEventOneShot	Handle a timed action of the type
				TIMER_EVENT_ONE_SHOT

    INT HandleSleep		Handle a timed action of the type
				TIMER_SLEEP

    INT HandleSemaphore		Handle a timed action of the type
				TIMER_SEMAPHORE

    EXT RestoreTimerInterrupt	Restore the timer interrupt

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

DESCRIPTION:
	This file handles timer interrupts

	$Id: timerInt.asm,v 1.1 97/04/05 01:15:26 newdeal Exp $

------------------------------------------------------------------------------@

COMMENT @----------------------------------------------------------------------

FUNCTION:	TimerInterrupt

DESCRIPTION:	Handle a timer interrupt

CALLED BY:	INT 8 -- Timer interrupt

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	There are two classes of timer interrupts this function handles:
		1) the standard 60-interrupts-per-second timing base
		2) special ones that come between the 60-ips ones in order
		   to implement millisecond one-shot timers
	We can differentiate between the two by examining the msTimerFlag
	variable, which is set non-zero when the timer is reprogrammed to to
	an interval shorter than that required for the 60-ips timing base.

	Step 1 in handling a timer interrupt:
	    if the interrupt is for a ms-one-shot:
		walk down the list until we find a timer that's not
		    expired with the arrival of this interrupt and make
		    it the head of the list, null-terminating the list that
		    begins with the timer for which this interrupt was
		    programmed
		reprogram the timer for the time remaining until the next
		    interrupt should happen (either ms-related or 60-ips-
		    related)
		for each timer removed from the list above:
			call the handler for the timer
			free the timer handle
			reduce the number of ms timers that are active by 1
		if no more ms timers active, the interval just programmed will
		    bring us to the next 60-ips interrupt, at which point
		    we will need to return the counter to its normal
		    60-ips value, so set a flag to tell us to do so
		DONE WITH INTERRUPT (ms-timer interrupts don't do any of the
		    normal administrative cruft the 60-ips interrupts need
		    to do, as they, by definition, aren't part of the time-base
		    calculation)

	Step 2:
	    if the previous interrupt was ms-timer related (meaning the
	        timer doesn't have the normal 60-ips value programmed into
		it), reprogram the timer for normal 60-ips operation. If
		the head of the list is a ms timer that gets taken within the
		next tick, we'll reprogram the timer again for it, but for
		now this makes sure the time-base gets started properly
		as soon as possible after the interrupt comes in.

	Step 3:
	    increment the system counter

	Step 4:
	    reduce passCount by 10,000. why? I'm glad you asked. The previous
	        owner of vector 8 is used to receiving 18.2 interrupts per 
		second from the timer chip. We, of course, are used to 
		receiving 60 of them, with a few ms-timer-related interrupts
		thrown in for variety. 18.2 doesn't divide into 60 too well,
		though, and passing off every 3d tick ends up making the DOS
		clock get way ahead of us, which is bad. To combat this,
		without too much overhead, we take the ratio (60/18.2)*10,000
		and store this in the  passCount  variable. Every tick,
		we reduce this counter by 10,000 (a tick, you know) and if
		the result falls below 0, we add that ratio*10,000 back into
		the counter and call the old handler. It's like quick fixed-
		point math not using a power of 2 (gasp!) and has the desired
		effect of passing off 18.2 interrupts per second to the old
		handler...or so close to it as makes no odds.

	Step 5:
	    issue the EOI to the 8259, so if we handle any timed actions,
	        other interrupts (including another timer interrupt) are free
		to arrive, so we don't adversely affect serial communications,
		etc.

	Step 6:
	    decrement the counter of ticks left in the current second. If the
	    second has passed, perform the necessary administrative chores:
		- reset  ticks  to 60 (INTERRUPT_RATE) again.
		- add one second to our software-maintained RTC, with all that
		  implies as far as rippling carries is concerned.
		- update the system swapping/idle-time/etc. statistics

	Step 7:
	    decrement the CPU-usage-decay counter, and divide all threads'
	        CPU usage in half if the counter goes to 0. note that if
		DECAY_COUNT (number of ticks between decays) is the same
		as INTERRUPT_RATE (the number of ticks per second), this
		is actually folded into Step 6, above.

	Step 8:
	    decrement the ticks remaining for the timer on the head of the
	        timer list. If this brings it to 0, process all the timers
		at the head of the list that have thus expired:
		    so long as the HTI_timeRemaining field of the head timer
		    is 0:
		        - if the timer isn't an ms-timer, jump to the
			  appropriate handler through the TimerRoutines
			  table.
			- if the timer is an ms-timer whose HTI_method field
			  (the number of units into the tick at which it should
			  fire) is 0, call the appropriate routine and nuke
			  the timer
			- if the timer is an ms-timer whose HTI_method field
			  is non-zero, reprogram the timer chip to interrupt
			  when the timer should expire and get out of this
			  rut we're in

	Step 9:
	    increment the cpu-usage and priority of the current thread
	        and decrement the time-slice counter. If the time-slice
		has expired, see if there's a higher-priority thread on 
		the run queue and wake it up, if so.

	Step 10:
	    collapse in exhaustion :)
	
RANDOM NOTES:
	we will *never* have a ms timer that crosses a tick boundary, owing to
	the way these things are figured out (storing ticks and units). In the
	event of two ms timers, where the second one crosses the tick boundary,
	it will have an HTI_timeRemaining of 1 and an HTI_method (aka unit
	count) of the amount by which it went into the next tick.
	
	unitsLost is based on the assumption that there is a minimum value we
	can program into the timer. e.g. a counter of 7 would cause us to
	recurse rather badly once the interrupt is acknowledged and the timer
	can interrupt again. To deal with this, we will never program the timer
	for an interval that is smaller than 250 microseconds. If we've got
	an interval that is smaller than 250 microseconds, the firing of that
	timer will be off by that amount, which amount is recorded in unitsLost
	and made up for on the next interrupt.
	
	unitsSinceLastTick will never get larger than the number of units in
	a tick, because of the way millisecond timers are stored in the list,
	as detailed above (we will always take a regular-tick interrupt
	when we cross that tick boundary).

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
	Perhaps use mode 0 to implement ms one-shots? it'll wrap and we'll
	end up with the counter being -(number of ticks latency)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version
	ardeb	4/92		Fixed ms-one-shot timers

------------------------------------------------------------------------------@

if	TEST_MULTI_THREADING

runQueueCount	sword	0
inBiosCount	sword	0
endif

if	TEST_MULTI_THREADING or TIMER_PROFILE
TIStack	struct
    TIS_ds	word
    TIS_bx	word
    TIS_ax	word

if	VERIFY_INTERRUPT_REGS
    TIS_pushFrame	PushAllFrame
endif

    TIS_retAddr	dword
    TIS_flags	word
TIStack	ends
endif

;-----------------------------------------------

TimerInterrupt	proc	far
		
if	VERIFY_INTERRUPT_REGS
	call	SysEnterInterruptSaveRegs
else
	call	SysEnterInterrupt

endif

	push	ax
	push	bx
	push	ds
	ON_STACK ds bx ax iret

	cld
	LoadVarSeg	ds, ax		; use trash reg for speed
SSP <	tst	ds:[inSingleStep]					>
SSP <	ERROR_NZ	-1						>
SSP <	movdw	ds:[instructionsSinceLastInterrupt], 0			>

ifidn	HARDWARE_TYPE, <RESPG2>
	;
	; If we are responder, check for NMI occurence here
	;
	; Check PMI status
	;
		clr	bx
	;
	; bl = contents of IO_NMI_ST
	;      when NMI happened
	;
		xchg	bl, ds:pmiStatus
		tst	bx
		jz	skipNmiCheck

statusChagne::
		push	cx
		or	ds:possibleChange, bx
		and	ds:possibleChange, \
			mask G2NSF_PMI1HL or \
			mask G2NSF_PMI1LH or \
			mask G2NSF_PMI0HL or \
			mask G2NSF_PMI0LH	; mask out unnecessary bits
		mov	cx, 4
		shr	bx, cl			; bit0=lid stat, bit1=phone st
		and	bx, 011b		; we'll use table lookup
		mov	cl, cs:[rspStatTable][bx] ; cx = current machine stat
		mov	ds:machineStatus, cx	; ch = 0
		pop	cx
skipNmiCheck:
		
endif	; HARDWARE_TYPE = <RESPG2>

if TEST_TIMER_CODE
	mov	bx, ds:[unitsLost]
	mov	ax, TIMER_ENTER
	call	TestTimerCodeAddLogEntry
endif


if	TIMER_PROFILE
	; Special code here to log return addresses in a circular buffer, 
	; which will be looked at in swat to generate a crude picture of 
	; where CPU time is going	-- Doug
	;
	mov	bx, sp
	mov	ax, ss:[bx].TIS_retAddr.segment
	mov	bx, ss:[bx].TIS_retAddr.offset
	call	IntRecordAddress
endif

	; Dealing with milisecond timers:
	; If this interrupt is a result of a milisecond timer then reprogram
	; the timer correctly and call the routine here.  We don't go through
	; the normal interrupt code since this is an "extra" interrupt

	clr	ax
	xchg	al, ds:[msTimerFlag]

	tst	al
	jz	notMsTimer

	;------------------------------------------------------------
	;		MILLISECOND TIMER EXPIRATION
	;
	; It is a milisecond timer... Remove all ms timers that are now
	; expired from the list

	push	si
	mov	si, ds:[timeListPtr]

EC <	cmp	ds:[si].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT		>
EC <	ERROR_NE	CORRUPT_TIMER_LIST				>
EC <	cmp	ds:[si].HTI_timeRemaining, 0				>
EC <	ERROR_NE	CORRUPT_TIMER_LIST				>

	;
	;  Now, we can't really treat msec timers like other
	;	timers.  They need to be treated special because
	;	they happen so quickly.  Instead of removing
	;	the first timer and all those msec timers which
	;	occur at the same time, we remove all the msec
	;	timers which should have expired.  We determine
	;	this by examining the unitsSinceLastTick and
	;	removing anything which should already have
	;	expired.
	;		-- todd 01/29/93
	mov	ax, ds:[unitsSinceLastTick]

findMSTimerLoop:
	mov	bx, si
	mov	si, ds:[bx].HTI_next
	cmp	ds:[si].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
	jne	processMSTimerList
	cmp	ds:[si].HTI_method, ax
	jbe	findMSTimerLoop

processMSTimerList:
	; si = first timer not expired. bx = last timer that is expired
	mov	ds:[bx].HTI_next, 0		; so we know when to stop
	mov	bx, si
	xchg	ds:[timeListPtr], bx		; set new head and fetch old
						;  one


	; REPROGRAM for timer in si (and for the ticks already gone)

	mov	ax, ds:[currentTimerCount]	;ax = # units gone by to get to
						; this firing.
	add	ds:[unitsSinceLastTick], ax

if TEST_TIMER_CODE
	push	ax,bx
	mov	bx, ds:[unitsLost]
	mov	ax, TIMER_MS_INTERRUPT
	call	TestTimerCodeAddLogEntry
	pop	ax,bx
endif

	call	ReprogramTimerSI

						; interrupts are off while we
						; call the handlers, so it
						; doesn't much matter whether
						; we do it now or later...

if	HARDWARE_INT_CONTROL_8259

	mov	al, IC_GENEOI			;send EOI, because...
	out	IC1_CMDPORT, al

else

	.err <must generate EOI for timer interrupt here>

endif

	; call the routines for the one or more timers that have expired.
	; we call them with interrupts OFF, as they're very special and are
	; supposed to be high-speed...
msHandlerLoop:
	push	ax

if	TEST_TIMER_CODE
	mov	ax, TIMER_MS_CALL
	call	TestTimerCodeAddLogEntry
endif

	push	ds, bx

	mov	ax, ds:[bx].HTI_intervalOrID
	call	ds:[bx].HTI_OD
	INT_OFF

	pop	ds, bx

if	TEST_TIMER_CODE
	mov	ax, TIMER_MS_RETURN
	call	TestTimerCodeAddLogEntry
endif

	pop	ax

	mov	si, ds:[bx].HTI_next
	call	FreeHandle
	mov	bx, si
	tst	bx
	jnz	msHandlerLoop

	pop	si
	jmp	done

notMsTimer:
	;------------------------------------------------------------
	;	60-IPS TIME-BASE INTERRUPT HANDLING
	;

EC<	tst	ds:[msTimerFlag]				>
EC<	ERROR_NZ CORRUPT_TIMER_LIST				>

	xchg	ax, ds:[unitsLost]		; fetch & zero unitsLost as
						;  they are taken care of by
						;  our transferring them to
						;  unitsSinceLastTick...
if TEST_TIMER_CODE
	mov	bx, TIMER_TB_INTERRUPT
	xchg	ax,bx
	call	TestTimerCodeAddLogEntry
	mov	ax,bx
endif

	mov	ds:[unitsSinceLastTick], ax	; this is a normal 60-ips
						; interrupt, so no units
						; have passed since the last
						; tick... unless there were
						; some lost in getting to this
						; time-base.
	cmp	ax, GEOS_TIMER_VALUE	
	ja	trimUnitsLost
step2:
	; 			*** STEP 2 ***
	; 
	; if a special timer value is set then change the timer interrupt
	; back to ticks

	cmp	ds:[currentTimerCount], GEOS_TIMER_VALUE
	je	timerAt60Hz

if TEST_TIMER_CODE
	mov	bx, ds:[timerLogPtr]
	mov	ds:[bx].TL_type, TIMER_RESET_TB
endif

	mov	ax, GEOS_TIMER_VALUE
	call	ReprogramTimer

timerAt60Hz:


	;			*** STEP 3 ***
	;
	; increment system counter

	inc	ds:[systemCounter.low]
	LONG_EC	jz	incrementHigh
systemCounterUpdated:

	;			*** STEP 4 ***
	;
	; This is to deal with *&^#$! foreign PCs. They (for reasons unknown)
	; use the timer interrupt to send mouse events. This means
	; we must pass the timer interrupts along. In order to get the
	; the (nearly) correct update rate, we pass along every
	; PASS_COUNT of them, not every one.
	;
	; This is also to deal with keeping the DOS clock up-to-date, so it
	; sets the correct time on files we create...
	;
	; If we are passing off the interrupt, we don't send an EOI since the
	; interrupt handler that we are calling should do this itsself.
	; We call the old interrupt handler first since we want the EOI to
	; go out as soon as possible so that we don't miss timer interrupts.
	;
	sub	ds:[passCount], 10000	; reduce by another tick
	jbe	handOff			; => wrapped below 0, so need to
					;  hand the interrupt off to BIOS,
					;  or whomever...

	;			*** STEP 5 ***
	;
	; since we're handling the interrupt, send an EOI

if	HARDWARE_INT_CONTROL_8259
	mov	al, IC_GENEOI		; send EOI
	out	IC1_CMDPORT,al

else

	.err <must generate EOI for timer here>

endif
afterHandOff:

	; test code -- count the number of times that something is in the
	; run queue (and thus waiting to run)

if	TEST_MULTI_THREADING
	tst	ds:[currentThread]
	jz	runQueueEmpty
	tst	ds:[runQueue]
	jz	runQueueEmpty
	inc	cs:[runQueueCount]
runQueueEmpty:
	mov	bx, sp
	cmp	ss:[bx].TIS_retAddr.segment, 0xc800
	jnz	notInBios
	inc	cs:[inBiosCount]

notInBios:
endif


if	ANALYZE_WORKING_SET
	call	WorkingSetTick
endif

	;			*** STEP 6 ***
	;
	; Handle the time-of-day clock and cpu-usage decay for all threads.
	; in the normal system set-up, where DECAY_TIME is equal to
	; INTERRUPT_RATE (the number of ticks in a second), these are both
	; handled at handleSecond based on the countdown of the 'ticks'
	; counter.
	;
	; If DECAY_TIME is different, for some reason, the 'decayCount'
	; countdown timer comes into play for making thread cpu usage decay.
	;
	dec	ds:[ticks]		;times out once per second
	jz	handleSecond

	;			*** STEP 7 ***
	;
if DECAY_TIME ne INTERRUPT_RATE
afterSecond:

	dec	ds:[decayCount]
	jz	doDecay		;this is faster since branch is
					;usually skipped
endif

afterDecay:

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

if	NO_ACTIONS_UNTIL_OLD_TIMER_RETURNS
	tst	ds:[nestedOldInts]
	jnz	afterActions
endif
	;			*** STEP 8 ***
	;
	; Now deal with timed actions.  timeListPtr points at the first timer
	;
	mov	bx, ds:[timeListPtr]
	tst	bx
	jz	afterActions

	dec	ds:[bx].HTI_timeRemaining
	;  It would be a good thing if we could rearrange things so that
	;  this doesn't have to be a long jump.  I have done some testing
	;  and see that this branch can be taken nearly 40% of the time, so
	;  adding a "jz to jmp" only provides a minimal savings.  I wasn't
	;  able to move the code close enough (without causing other jumps
	;  to become long jumps) to get rid of the LONG.  --JimG 4/18/95
	LONG jz	doAction
	js	checkForActionMissedHop

afterActions:





if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	;			*** STEP 9 ***
	;
	; Update the CPU usage and current priority for the running thread.
	; This isn't done if we're in the kernel thread (can't context switch
	; from the kernel thread anyway, so no point in tracking the usage...
	; also we don't have a handle in which to track it :). We don't
	; take the CPU away from the thread even if its curPriority goes above
	; another thread on the run queue until its time slice expires...
	;	
	mov	bx,ds:[currentThread]	;no switching while in kernel mode
	tst	bx
	jz	done

					CheckHack <DECAY_TIME lt 256>
	inc	ds:[bx][HT_cpuUsage]	;update current thread's CPU usage

;	Don't increment the priority beyond PRIORITY_IDLE-1, because we do
;	not want PRIORITY_IDLE threads to run until all other threads are
;	idle.

	cmp	ds:[bx][HT_curPriority], PRIORITY_IDLE-1
	jae	afterRollover
	inc	ds:[bx][HT_curPriority] ;and its priority
	ERROR_Z	THREAD_PRIORITY_OVERFLOW
if	0				;This can no longer happen, due to
					; the branch above
	jz	priorityMaxedOut
endif

afterRollover:

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	;
	; If the thread has used up its time slice, go see if there's anything
	; more important that needs to run.
	;
	dec	ds:[threadTimer]	;update timer
	jz	timeOut		;if time out then branch (this is
				;faster since branch is usually skipped)
done:

if	TEST_TIMER_CODE
	push	ax
	mov	ax, TIMER_LEAVE
	call	TestTimerCodeAddLogEntry
	pop	ax
endif

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	;			*** STEP 10 ***


	pop	ds
	pop	bx
	pop	ax
if	VERIFY_INTERRUPT_REGS
	call	SysExitInterruptVerifyRegs
else
	call	SysExitInterrupt
endif
	iret
;-----------------------------------------------

;
;
;
trimUnitsLost:
	;	*** STEP 1, PART 2 ***
	
	;
	;  We have a units lost count that exceeds a tick.
	;  	If we just load it into the unitsSinceLastTick,
	;	the value will exceed a tick, so we "trim" the
	;	units lost value and store the remainder
	;	in the unitsLost value.  Hopefully we can
	;	make that up on the next, next tick.
	;			-- todd  02/10/92
	mov	ds:[unitsSinceLastTick], GEOS_TIMER_VALUE
	sub	ax, GEOS_TIMER_VALUE
	mov	ds:[unitsLost], ax
	jmp short step2

;-----------------------------------------------

	;		*** STEP 3, PART 2 ***
incrementHigh:
	inc	ds:[systemCounter.high]
	jmp	systemCounterUpdated

;-----------------------------------------------

	;		*** STEP 4, PART 2 ***
handOff:
	; call the previous handler. interrupts are still off, as it will
	; be expecting...

if TEST_TIMER_CODE
	push	ax
	mov	ax, TIMER_HAND_OFF
	call	TestTimerCodeAddLogEntry
	pop	ax
endif

	; Add the fixed-point ratio until the next handOff into the passCount
	; (see the header for more explanation)
	add	ds:[passCount], PASS_COUNT_TIMES_10000

if	NO_ACTIONS_UNTIL_OLD_TIMER_RETURNS
	inc	ds:[nestedOldInts]
endif

	pushf				; simulate an interrupt
	call	ds:[timerSave]

if	NO_ACTIONS_UNTIL_OLD_TIMER_RETURNS
	dec	ds:[nestedOldInts]
endif

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

		; Can't let interrupts be turned on until we remove the
		; the expired timers from the list, or we might recurse
		; causing the 1st interrupt to believe it is a tick
		; timer, but finding a msec timer on the head of the
		; list because the second interrupt took all the tick
		; timers off.		-- todd 10/06/92

		; Heh-heh-heh.  Not!  As there is no way to keep the
		; timer from recursing if the timer routine we hand
		; off to 18.2 times a second turns interrupts back
		; on, we need to be able to deal with waking up and
		; finding a msec timer on the head of the tick list.
		; I just added some code that does that, so we can
		; once more let interrupts rip for a while.
		;			-- todd 01/29/93

	; let interrupts rip for a while, as they might have been off a
	; long time in the previous handler, and we still have much to do.

	INT_ON
	nop
	INT_OFF
	jmp	afterHandOff

;-----------------------------------------------

	;		*** STEP 8, Intermediate jumps ***
	; These are here so that we can avoid long jumps in the main interrupt
	; code.  As long as the branch in the main code is taken less than
	; half the time, this "jump to jump" is more efficient than a "LONG"
	; jump.  --JimG 4/17/95
checkForActionMissedHop:
	jmp	checkForActionMissed
	
;-----------------------------------------------

	;		*** STEP 9, PART 3 ***

timeOut:
	; time slice has timed out: wake up a runable thread if one
	; exists that is higher priority
	;
	; 4/30/92: rather than wasting time in WakeUpRunQueue, which we know
	; will be unable to switch, since we called SysEnterInterrupt at the
	; start of this all, just set the intWakeUpAborted flag.
	; SysExitInterrupt will do the honors for us. We only set that
	; flag if the run queue has another thread on it, however, to
	; avoid EC death... -- ardeb

	mov	ds:[threadTimer],TIME_SLICE
	tst	ds:[runQueue]
	jz	done

	inc	ds:[intWakeUpAborted]
	jmp	done

;-----------------------------------------------

	;		*** STEP 6, PART 2 ***
handleSecond:
	;
	; Handle all the system things that have to be handled every second:
	;	- update the time-of-day clock
	;	- update the run-queue, idle time and context-switch stats
	;
	mov	ds:[ticks],INTERRUPT_RATE
	call	IncrementTime		;bump clock one second
	call	SysUpdateStats		;update/reset system statistics

if DECAY_TIME ne INTERRUPT_RATE
	jmp	afterSecond
endif
	; ELSE -- fall thru to STEP 7, PART 2 (Thought I'd comment this
	; because it wasn't necessarily obvious). --JimG 4/17/95

;-----------------------------------------------

	;		*** STEP 7, PART 2 ***
	;
	; Cut every existing thread's CPU usage in half, recalculating their
	; current priorities at the same time.
	;
if DECAY_TIME ne INTERRUPT_RATE
doDecay:
	mov	ds:[decayCount],DECAY_TIME
endif

	mov	bx, offset threadListPtr - offset HT_next;start at front of list
decayLoop:
	mov	bx,ds:[bx][HT_next]
	tst	bx
	jz	toAfterDecay

	; divide cpu usage in half and adjust thread's curPriority
	; accordingly

	mov	ax,{word}ds:[bx][HT_basePriority];al=basePri, ah=HT_cpuUsage
	shr	ah,1
	mov	ds:[bx][HT_cpuUsage],ah
	add	al,ah
	jc	decayLoop	; If still over 255 after decay, curPrio
				;  must already be maxed out...

;	If the new thread priority is PRIORITY_IDLE, then we know that
;	curPriority is already maxed out, so there's no need to mess with
;	it.

	cmp	al, PRIORITY_IDLE
	je	decayLoop

	mov	ds:[bx][HT_curPriority],al
	jmp	decayLoop

toAfterDecay:
	jmp	afterDecay

;-----------------------------------------------

	;		*** STEP 9, PART 2 ***

if	0
	;No need to do this, as once HT_curPriority reaches PRIORITY_IDLE-1,
	; it is no longer incremented.
priorityMaxedOut:
	dec	ds:[bx].HT_curPriority
	jmp	afterRollover
endif

;-----------------------------------------------

	;		*** STEP 8, PART 3 ***
checkForActionMissed:
	cmp	ds:[bx].HTI_timeRemaining, -1
   LONG	jne	afterActions
	
	;
	;  When processing a 60Hz tick, we find that the lead
	;	timer has no ticks remaining.  This might be
	;	bad.  If the 1st timer is not a msec timer,
	;	this is bad!  That means we left a timer on
	;	the list and it should have been processed
	;  If, however, the first timer is a msec timer,
	;	and the msec timer flag is set, then
	;	it just means we recursed inside this routine
	;	and some other timer interrupt ripped of
	;	all the timers except the msec timer.
	;			-- todd	01/29/93

	mov	ds:[bx].HTI_timeRemaining, 0	; reset timeRemaining to zero

	tst	ds:[msTimerFlag]		; is msec flag not set, bad!
	jz	actionMissedError

	cmp	ds:[bx].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
   LONG	je	afterActions			; if 1st is msec, ignore it

actionMissedError:
	;
	;  Well, we actually missed a timer.  Either the msec
	;	flag was not set indicating an unexpected msec
	;	timer, or the lead timer wasn't a msec timer...
EC<	ERROR	 TIMER_MISSED						>

	; Simply FALL-THRU to doAction in the NON-EC case.  No point in having
	; this jump since I rearranged things.. --JimG 4/17/95
;NEC<	jmp	doAction						>

;-----------------------------------------------
	
	;		*** STEP 8, PART 2 ***
	;	Also called in NON-EC by checkForActionMissed

	; the first timer has counted down to zero -- do the action

doAction:
	push	cx
	push	dx
	push	si
	ON_STACK si dx cx ds bx ax iret

	;
	; To cope with a hardware interrupt extending for more than a timer
	; tick (we've sent the EOI to the timer, so it's possible to recurse
	; in here), we remove all expired timers from the list *first*, with
	; interrupts off, then process their actions.
	;
	; When we first get here, ds:[bx].HTI_timeRemaining *must* be zero, so
	; si will always be set to something before we reach
	; processExpiredTimers. 9/7/92: *unless* the first timer is a ms one-
	; shot whose HTI_timeRemaining has just counted to 0, but whose
	; HTI_method field is non-zero -- ardeb
	; 
	clr	si				; none expired yet.
removeExpiredTimerLoop:
EC <	call	CheckHandleLegal					>

	tst	ds:[bx].HTI_timeRemaining	; any ticks remaining to
						;  expiration?
	jnz	processExpiredTimers		; yes -- nothing further to do

	cmp	ds:[bx].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
	je	checkMSAction			; if timer is ms-one-shot, we
						;  also have to check the unit
						;  count
timerExpired:
	mov	si, bx				; ds:si <- last expired
	mov	bx, ds:[bx].HTI_next		; ds:bx <- next to check
	tst	bx
	jnz	removeExpiredTimerLoop		; loop if another to check

processExpiredTimers:
	clr	ds:[si].HTI_next		; null-terminate expired-timer
						;  list
	xchg	bx, ds:[timeListPtr]		; set new head and get old

	;
	; ds:bx is now the head of a null-terminated list of expired timers.
	; Call the action for each one in turn.
	; 
callActionLoop:
	;
	; Jump to the handling routine for this type of timer. We jump instead
	; of call for speed reasons...
	; 
	push	ds:[bx].HTI_next		; save next timer, as this
						;  one will be freed or
						;  re-inserted in the list
	mov	si, {word}ds:[bx].HTI_type
	andnf	si, 0xff

	jmp	ds:[TimerRoutines][si]

TI_afterCall	label	near
	;
	; All routines in the TimerRoutines array jump back here when they're
	; done.
	; 
	INT_OFF
EC <	call	AssertDSKdata						>

	;
	; Loop if there's still a timer on the list.
	; 
	pop	bx
	tst	bx
	jnz	callActionLoop

doneActionLoop:

	;
	; Whatever actions need doing have been done, so retrieve registers
	; and get back into the flow of things.
	; 
	pop	cx, dx, si
	ON_STACK ds bx ax iret
	jmp	afterActions

checkMSAction:
	;
	; A millisecond timer might have expired (its tick count is down to
	; 0), but *we* process it only if the thing is to expire exactly
	; on a tick boundary (HTI_method, the units into the tick, is 0)
	; 
	ON_STACK si dx cx ds bx ax iret
	tst	ds:[bx].HTI_method
	jz	timerExpired		; => treat it as any other expired
					;  timer
	;
	; ms-timer expires partway through this next tick, so reprogram the
	; timer for that interval and go process the timers that expired.
	; 
	push	si			; save last-expired ptr
	ON_STACK si si dx cx ds bx ax iret
	mov	si, bx
	call	ReprogramTimerSI
	pop	si
	tst	si			; any actually expired?
	jnz	processExpiredTimers	; yes -- process them
	jmp	doneActionLoop		; no -- wait for next interrupt to
					;  process this timer.
	ON_STACK ds bx ax iret

TimerInterrupt	endp





idata	segment
TimerRoutines	word	offset HandleRoutineOneShot,
			offset HandleRoutineContinual,
			offset HandleEventOneShot,
			offset HandleEventContinual,
			offset HandleMsRoutineOneShot,
			offset HandleRealTime,
			offset HandleRealTime,
			offset HandleSleep,
			offset HandleSemaphore
CheckHack <length TimerRoutines eq (LAST_TIMER_TYPE/2)>
idata	ends

HandleMsRoutineOneShot	proc	near
	push	ds,bx
		ON_STACK bx ds si si dx cx ds bx ax iret
if TEST_TIMER_CODE
	mov	ax, TIMER_MS_CALL
	call	TestTimerCodeAddLogEntry
endif

	mov	ax, ds:[bx].HTI_intervalOrID
	;
	;  Interrupts already turned off
	call	ds:[bx].HTI_OD
	INT_OFF		; just to make sure...

	pop	ds, bx
		ON_STACK si si dx cx ds bx ax iret

if TEST_TIMER_CODE
	push	ax
	mov	ax, TIMER_MS_RETURN
	call	TestTimerCodeAddLogEntry
	pop	ax
endif
	call	FreeHandle
	jmp	TI_afterCall
HandleMsRoutineOneShot	endp


if TEST_TIMER_CODE
COMMENT @---------------------------------------------------------------------

FUNCTION:	TestTimerCodeAddLogEntry

DESCRIPTION:    Add a log entry to the timer log

PASS:		ax -> log type
		bx -> data
		ds -> dgroup

RETURN:		nothing
DESTROY:	ax
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TS	10/92		Initial version

------------------------------------------------------------------------------@
TestTimerCodeAddLogEntry  proc far
	uses di
	.enter
EC <	call	AssertDSKdata		; This is to catch our own bugs in  >
EC <					;  test timer code!  --- AY 1/9/97  >
	mov	di, ds:[timerLogPtr]
	mov	ds:[di].TL_type, al
	mov	ds:[di].TL_data, bx

	call	ReadTimer
	mov	ds:[di].TL_count, ax

	mov	ah, ds:[msTimerFlag]
	mov	ds:[di].TL_flag, ah

	mov	ah, ds:[interruptCount]
	mov	ds:[di].TL_level, ah

	NextTimerLog	di
	mov	ds:[timerLogPtr], di
	.leave
	ret
TestTimerCodeAddLogEntry  endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	IntRecordAddress

DESCRIPTION:	From within an interrupt routine, log the address pointer
		passed, in <handle><offset> form, to a cyclical buffer for
		analysis at a later point in time under swat. -- For crude
		CPU usage survey.

CALLED BY:	INTERNAL

PASS:
	ax:bx	- far address pointer to save away

RETURN:
	nothing

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Initial version
        mg      11/00           Support for heap/BIOS subsystem profiling
	mg	12/00		Added idle detection

------------------------------------------------------------------------------@
if	TIMER_PROFILE

TIMER_PROFILE_BUFFER_SIZE	= 2048	; 8K buffer for addresses
					; NOTE:  MUST be a power of 2
					; in size, in order to be able
					; to use "and" instruction
					; below to keep pointer in
					; range of buffer.

idata	segment
timerProfileBuffer	dword	TIMER_PROFILE_BUFFER_SIZE dup (?)
timerProfileOffset	word			; offset into buffer where next
						; address should be stored
timerProfileGeode	word			; Owning geode, if any, to limit
						; additions to buffer to.  If
						; -1, include PC/GEOS code
						; only (No DOS/BIOS/etc.)

; These variables track the usage of important subsystems whose
; use is not recognized by the current CS:IP. Rather, we are checking whether
; the thread holds any of the associated semaphores. Currently, we are
; only tracking heap activity and BIOS/DOS activity other than swapping.
; -- mgroeber 11/19/00
; Also added tracking of idle time -- mgroeber 12/12/00

timerProfileTotal       dword   0               ; total ticks since last reset
timerProfileIdle	dword   0		; total ticks with no thread running
timerProfileHeap        dword   0               ; total ticks with heap sem
timerProfileBIOS        dword   0               ; total ticks with BIOS sem,
                                                ; but outside of heap
idata   ends

IntRecordAddress	proc	near
	uses	cx, si, ds
	.enter
	LoadVarSeg	ds

        incdw   ds:[timerProfileTotal]          ; count ticks since reset
        mov     cx, ds:[currentThread]          ; check activity of this thread

	tst	ds:[currentThread]		; no thread currently running?
	jz	noThread

        cmp     cx, ds:[heapSem].TL_owner       ; do we own the heap?
        je      owningHeap

        cmp     cx, ds:[biosLock].TL_owner      ; do we own BIOS/DOS?
        je     	owningBIOS

ownerKnown:
        mov     si, ds:[timerProfileOffset]     ; if buffer full, exit.
	cmp	si, TIMER_PROFILE_BUFFER_SIZE * (size dword)
	jae	done

        mov     cx, ax                          ; no mov_tr, ax is still needed
	call	IntSegmentToHandle
	jnc	notInHeap
	mov_tr	ax, cx				; ^hax:bx is now address
haveAddress:
	tst	ds:[timerProfileGeode]
	jz	saveIt				; if not restricting owning
						; geode, go for it. 
	tst	ax				; if handle 0 or -1, skip
	jz	done
	cmp	ax, -1
	je	done
	cmp	ds:[timerProfileGeode], -1	; if all PC/GEOS code OK, save
	je	saveIt
	push	bx
	mov	bx, ax
	mov	bx, ds:[bx].HM_owner
	cmp	bx, ds:[timerProfileGeode]
	pop	bx
	jne	done				; skip out if doesn't match.
saveIt:
	mov	ds:[(offset timerProfileBuffer)+si].handle, ax
	mov	ds:[(offset timerProfileBuffer)+si].offset, bx

	add	si, size dword
	mov	ds:[timerProfileOffset], si	; store back location for next
						; time
	cmp	si, TIMER_PROFILE_BUFFER_SIZE * (size dword)
	je	IntProfileBufferWrapped
done:
	.leave
	ret

notInHeap:
	clr	bx				; bx <- 0
	dec	bx				; bx <- -1
	xchg	ax,bx				; put unknown seg in "offset"
						; portion of bin and mark
						; as "unknown segment"
	jmp	short haveAddress

IntProfileBufferWrapped	label near	; A convenient place to set a breakpoint
	jmp	short done

noThread:
        incdw   ds:[timerProfileIdle]           ; yes: count it
	jmp	done				; do not record idle periods

owningHeap:
        incdw   ds:[timerProfileHeap]           ; yes: count it
	jmp	ownerKnown

owningBIOS:
        incdw   ds:[timerProfileBIOS]           ; yes: count it
	jmp	ownerKnown

IntRecordAddress	endp

endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	IntSegmentToHandle

DESCRIPTION:	From within an interrupt routine, given a segment value,
		return the corresponding handle -- For crude CPU usage 
		survey only!

CALLED BY:	INTERNAL

PASS:
	cx - segment address

RETURN:
	carry - set if found
	cx - handle

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	11/91		Scammed from MemSegmentToHandle

------------------------------------------------------------------------------@
if	TIMER_PROFILE

IntSegmentToHandle	proc	near	uses ax, bx, dx, ds
	.enter

	; first try segment:[LMBH_handle]

	mov	ds, cx
	mov	bx, ds:[LMBH_handle]
	LoadVarSeg	ds

	; Make sure the thing's in bounds
	
	test	bx, 0xf				; valid handle ID?
	jnz	10$
	cmp	bx, ds:[loaderVars].KLV_lastHandle	; after table?
	jae	10$
	cmp	bx, ds:[loaderVars].KLV_handleTableStart
	jb	10$

	cmp	ds:[bx].HM_owner, 0		; want to return only alloc'd
	jz	10$				;  handle so caller gets error
						;  if segment points to free

	cmp	cx, ds:[bx].HM_addr
	jz	found

;	cmp	bx, ds:[handleBeingSwappedDontMessWithIt]
;	je	found
10$:
	; do it the slow way

	mov	bx, ds:[loaderVars].KLV_handleBottomBlock
	mov	dx, bx

	; loop through heap until we've wrapped around

STH_loop:
	cmp	cx,ds:[bx].HM_addr
	jz	found
	mov	bx,ds:[bx].HM_next
	cmp	bx,dx
	jnz	STH_loop

	; we've wrapped around -- segment not found

	clr	cx			;return 0 and clear carry
	jmp	done

	; found -- store as the cached value and return handle
found:
	stc
	mov	cx, bx
done:
	.leave
	ret
IntSegmentToHandle	endp
endif


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReprogramTimerSI

DESCRIPTION:	Reprogram the timer chip to fire when the given timer indicates,
		or on the next tick, if the timer's not due to expire

CALLED BY:	INTERNAL

PASS:
	ds - kdata
	si - HandleTimer
	ds:[unitsSinceLastTick] - number of timer units already gone by 
		since the last 60-ips interrupt came in.
	ds:[currentTimerCount] - current initial setting of timer

RETURN:
	none

DESTROYED:
	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

    Given:
	currentTimerCount - the value currently latched into the timer (what
			    the timer counts down from)
	ReadTimer() - represents the (dynamically changing) current value of
		      the timer
	unitsGone - # of timer units that have passed without being reflected
		    in ( currentTimerCount - ReadTimer() )

	newTime = timeToSet - ( currentTimerCount - ReadTimer() ) - unitsGone

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/91		Initial version

------------------------------------------------------------------------------@
if	TEST_TIMER_CODE
idata	segment
minTotalToSet	sword	0xffff
maxTotalToSet	sword	0
lastTotalToSet	sword	0

minNetToSet	sword	0xffff
maxNetToSet	sword	0
lastNetToSet	sword	0

numWraps	sword	0
totalUnitsAdded	sdword	0
totalUnitsLost	sdword	0

timerLogPtr	nptr.TimerLog	timerLog

idata	ends

udata	segment
timerLog	TimerLog TIMER_LOG_LENGTH dup(<>)
udata	ends

endif

FarReprogramTimerSI	proc	far
	call	ReprogramTimerSI
	ret
FarReprogramTimerSI	endp

ReprogramTimerSI	proc	near

	CheckHack	<GEOS_TIMER_VALUE lt 32768>

	; figure out what we should set the timer to. If the next timer
	; isn't an ms-timer, or is one, but isn't due to expire this
	; tick (HTI_timeRemaining is non-zero), we set the interval to
	; be the standard GEOS_TIMER_VALUE. Else it's the units until the
	; ms-timer expires.
	;
	; The calculation of the number of units is always based from the
	; previous tick. Since we may not be at the previous tick (a ms-timer
	; might have fired since then), we reduce the interval by the number
	; of units we know to have passed since the previous tick.
	; 

if TEST_TIMER_CODE
	push	di
   	mov	di, ds:[timerLogPtr]
	mov	al, ds:[si].HTI_type
	mov	ds:[di].TL_type, al
	pop	di
endif

	clr	ds:[msTimerFlag]		; assume not ms-timer
	mov	ax, GEOS_TIMER_VALUE
	cmp	ds:[si].HTI_type, TIMER_MS_ROUTINE_ONE_SHOT
	jnz	noSpecial
	tst	ds:[si].HTI_timeRemaining
	jnz	noSpecial
	dec	ds:[msTimerFlag]		; set to 255
	mov	ax, ds:[si].HTI_method		;ax = timer units remaining
noSpecial:
	sub	ax, ds:[unitsSinceLastTick]

	FALL_THRU	ReprogramTimer

ReprogramTimerSI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReprogramTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reprogram the timer for a particular interval, accounting
		for any units lost to our minimum-interval requirements

CALLED BY:	ReprogramTimerSI, TimerInterrupt
PASS:		ax	= clock units that should pass before the next
			  interrupt
		ds	= dgroup
RETURN:		ds:[currentTimerCount] = interval actually programmed
		ds:[unitsLost]	= units lost to minimum-interval requirement,
			which units must be made up on the next interval
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReprogramTimer	proc	near	uses cx
	.enter

if	TEST_TIMER_CODE
	mov	ds:[lastTotalToSet], ax
	cmp	ax, ds:[minTotalToSet]
	jae	10$
	mov	ds:[minTotalToSet], ax
10$:
	cmp	ax, ds:[maxTotalToSet]
	jbe	20$
	mov	ds:[maxTotalToSet], ax
20$:
endif

if not NO_REPROGRAMMABLE_TIMERS
	; account for inaccuracy in the most-recent interval

	sub	ax, ds:[unitsLost]		; adjust for extra units added
						;  to previous interval to
						;  satisfy our minimum-interval
						;  requirements
	mov	ds:[unitsLost], 0		; no inaccuracy in this interval
						;  yet...

	mov_tr	cx, ax				;cx = total to set

	;
	; In order to get back onto a stable time-base, where we won't have to
	; be reprogramming the timer every interrupt to account for the units
	; spent since the interrupt happened, we sacrifice a few units now
	; and make them up again should another ms-timer be set later on.
	; Without this concession, currentTimerCount would never be
	; GEOS_TIMER_VALUE, as it will always take at least one clock unit
	; to get to this routine, no matter how fast the machine, and if
	; currentTimerCount never becomes GEOS_TIMER_VALUE, TimerInterrupt will
	; never not call us to get the time-base onto a stable footing.
	;
	; We do this only if the current interrupt happened on-schedule
	; (unitsSinceLastTick is 0).
	; 
	cmp	cx, GEOS_TIMER_VALUE
	jne	checkCurrentCount
	tst	ds:[unitsSinceLastTick]
	jz	sacrificeUnitsSinceInterrupt
checkCurrentCount:

	; we must reprogram the timer for cx units plus any that have
	; ticked off since the timer interrupted.

	call	ReadTimer			;set ax = current timer value

	tst	ax
	jz	addInDeficit

	sub	ax, ds:[currentTimerCount]	;ax = -(units gone by)

addInDeficit:
	add	ax, ds:[timebaseDeficit]	;take care of deficit from
						; previous timebase re-
						; establishment (it's negative)
	jo	overflow
	jmp	fine
overflow:
	mov	ax, 8000h			; set maximun negative number
fine:
	
	clr	ds:[timebaseDeficit]		;but only do so once...

	sub	ds:[unitsSinceLastTick], ax	;add those to the units passed
						; since the last tick

	cmp	ds:[unitsSinceLastTick], GEOS_TIMER_VALUE
	ja	truncateUnitsSinceLastTick

transferToCX:

	add	cx, ax				; and reduce the interval we're
						; to set by the same amount

if	TEST_TIMER_CODE
	sub	ds:[totalUnitsAdded].low, ax
	sbb	ds:[totalUnitsAdded].high, 0xffff
	mov	ds:[lastNetToSet], cx
	cmp	cx, ds:[minNetToSet]
	jge	30$
	mov	ds:[minNetToSet], cx
30$:
	cmp	cx, ds:[maxNetToSet]
	jle	40$
	mov	ds:[maxNetToSet], cx
40$:
endif

	;
	; If the interval is too short of our tastes, make it the minimum
	; interval we'll accept and record the slop in the unitsLost
	; variable.
	;


	cmp	cx, MINIMUM_TIMER_VALUE
	jge	noWrap

	mov	ax, MINIMUM_TIMER_VALUE
	sub	ax, cx
	mov	ds:[unitsLost], ax

if	TEST_TIMER_CODE
	add	ds:[totalUnitsLost].low, ax
	adc	ds:[totalUnitsLost].high, 0
	inc	ds:[numWraps]
endif

	mov	cx, MINIMUM_TIMER_VALUE
noWrap:

if TEST_TIMER_CODE
	push	di,bx
   	mov	di, ds:[timerLogPtr]
	mov	al, ds:[di].TL_type
	mov	bx, cx
	call	TestTimerCodeAddLogEntry
	pop	di,bx
endif
	; cx = value to write. This will set currentTimerCount as well

	mov_tr	ax, cx

EC<	cmp	ax, GEOS_TIMER_VALUE			>
EC<	ERROR_A	TIMER_VALUE_SLOWER_THAN_60_HZ		>

	call	WriteTimer
else
	mov	ds:[unitsSinceLastTick], GEOS_TIMER_VALUE

endif	;	!NO_REPROGRAMMABLE_TIMERS


	.leave
	ret

if not NO_REPROGRAMMABLE_TIMERS
sacrificeUnitsSinceInterrupt:
	call	ReadTimer
	tst	ax
	jz	adjustDeficit
	sub	ax, ds:[currentTimerCount]

adjustDeficit:
	mov	ds:[timebaseDeficit], ax
	jmp	noWrap
	
truncateUnitsSinceLastTick:
	mov	ds:[unitsSinceLastTick], GEOS_TIMER_VALUE
	jmp	transferToCX
endif	;	!NO_REPROGRAMMABLE_TIMERS
ReprogramTimer	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	ReadTimer

DESCRIPTION:	Read the value in the timer

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	ax - timer value

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	For the zoomer, we have a count-up timer, not a count-down
	timer.  This can really throw things off, needless to say,
	so we fake a count-down timer by subtracting the value
	read from the timer from the value originally programmed
	into it.

	Of course, it doesn't stop there.  First of all, the
	darn thing counts up from 1 to the number we program+1.
	Of course, until the first tick, it reads zero.  Great,
	isn't it?  So, if we program it for 48, the actual
	legal values to be read from the timer are 0-49.  that's
	right, 50 legal values.  Blech.
				-- todd 02/09/93

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/91		Initial version

------------------------------------------------------------------------------@
ReadTimer	proc	near

if	HARDWARE_TIMER_8253
	mov	al, TIMER_COMMAND_0_READ_COUNTER
	out	TIMER_IO_COMMAND,al
	jmp	$+2			; I/O delay
	in	al, TIMER_IO_0_LATCH		;al = low byte
	jmp	$+2			; I/O delay
	mov	ah, al
	in	al, TIMER_IO_0_LATCH		;al = high byte
	xchg	al, ah
else


endif
	ret


ReadTimer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	WriteTimer

DESCRIPTION:	Write a new interval to the timer

CALLED BY:	INTERNAL

PASS:
	ds - dgroup
	ax - value to write

RETURN:
	ds:[currentTimerCount] - value passed

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/12/91		Initial version

------------------------------------------------------------------------------@
FarWriteTimer	proc	far
	call	WriteTimer
	ret
FarWriteTimer	endp

WriteTimer	proc	near
	mov	ds:[currentTimerCount], ax

EC<	cmp	ax, GEOS_TIMER_VALUE	        ; why are we programming the  >
EC<	ERROR_A TIMER_VALUE_SLOWER_THAN_60_HZ   ; timer for more than a tick? >

if	HARDWARE_TIMER_8253
	push	cx
	mov_tr	cx, ax

	mov	al, TIMER_COMMAND_0_WRITE
	out	TIMER_IO_COMMAND, al
	jmp	$+2			; give 8253 time to react
	mov	al, cl
	out	TIMER_IO_0_LATCH, al
	jmp	$+2			; give 8253 time to react
	mov	al, ch
	out	TIMER_IO_0_LATCH, al

	mov_tr	ax, cx
	pop	cx

else
	;------------------------------------------------------------------
	;	CUSTOM TIMER SUPPORT
	;
	.err <must set count for custom timer>

endif
	ret

WriteTimer	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	TimerStartCount

DESCRIPTION:	Record the timer value at the beginning of an operation, for
		use in calculating the length of an operation.

CALLED BY:	GLOBAL

PASS:		nothing	
		
RETURN:		bx:ax	= Starting TimeRecord<> (dword)

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		Interrupts will be toggled on/off, to allow the system
		counter to be brought up to date, & will be returned OFF

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/12/91		Initial version

------------------------------------------------------------------------------@
TimerStartCount	proc	far
	uses	ds
	.enter
	; First toggle interrupt in an attempt to bring the system counter
	; up-to-date.
	;
	LoadVarSeg	ds, ax
	INT_ON
	nop					; attempt to update counter
	INT_OFF

	; Now store the current timer value
	;
	call	ReadTimer
	mov	bx, ds:[systemCounter].low
	.leave
	ret
TimerStartCount	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	TimerEndCount

DESCRIPTION:	Record the timer value at the end of an operation, & then
		calculate the time spent in the operation.

CALLED BY:	GLOBAL

PASS:		bx:ax	= Starting TimeRecord<> (dword)
		*ds:si	= TimeRecord<> (dword) holding running total

RETURN:		nothing

DESTROYED:	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
		Interrupts will be toggled on/off, to allow the system
		counter to be brought up to date, but wil be returned ON.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/12/91		Initial version

------------------------------------------------------------------------------@
TimerEndCount	proc	far
	uses	ax, bx, cx, es
	.enter

	; Toggle interrupts to bring the system counter up-to-date
	;
	LoadVarSeg	es, cx
	INT_ON
	nop
	INT_OFF

	; Now let's record the time spent, and update our running total
	;
	mov_tr	cx, ax
	call	ReadTimer
	sub	cx, ax				; time unit difference => CX
	js	unitsToSubtract
	add	cx, ds:[si].TR_units		; and in elapsed units
	cmp	cx, GEOS_TIMER_VALUE
	jb	continue
	sub	cx, GEOS_TIMER_VALUE
	dec	bx				; propogate tick "carry"
	jmp	continue
unitsToSubtract:
	add	cx,  ds:[si].TR_units		; add in elapsed units
	jns	continue
	add	cx, GEOS_TIMER_VALUE
	inc	bx				; "borrow" tick from elapsed
continue:
	mov	ds:[si].TR_units, cx		; store new elapsed units
	sub	bx, es:[systemCounter].low	; -(tick difference) => BX
	neg	bx
	js	done				; if negative, do nothing
	add	ds:[si].TR_ticks, bx		; update elapsed ticks
done:
	INT_ON

	.leave
	ret
TimerEndCount	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleRoutineContinual

DESCRIPTION:	Handle a timed action of the type TIMER_ROUTINE_CONTINUAL

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	interrupts off
	bx - handle of timed action
	ds - idata

RETURN:
	** Return is via a jump to "TI_afterCall" for speed

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Call routine, then put structure back on list

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
-----------------------------------------------------------------------------@

HandleRoutineContinual	proc	far
	ON_STACK si si dx cx ds bx ax iret

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif
	mov	ax,ds:[bx].HTI_intervalOrID	;reset counter
	mov	ds:[bx].HTI_timeRemaining,ax
	mov	ds:[bx].HTI_next,0
	call	InsertTimedAction		;put routine back on list

	call	CallTimerRoutine

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	jmp	TI_afterCall			;return to TimerInterrupt

HandleRoutineContinual	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallTimerRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for HandleRoutineContinual and
		HandleRoutineOneShot to call the routine in question

CALLED BY:	HandleRoutineOneShot, HandleRoutineContinual
PASS:		ds	= idata
		bx	= HandleTimer
RETURN:		interrupts on
DESTROYED:	ax, cx, dx (definitely), bx, si (maybe)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallTimerRoutine	proc	near
	.enter

	mov	cx,ds:[systemCounter.high]
	mov	dx,ds:[systemCounter.low]


CallTimerRoutineLow	label	near
	push	di, bp, ds, es

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

if TEST_TIMER_CODE
	mov	ax, TIMER_RT_CALL		; calling a RT timer
	call	TestTimerCodeAddLogEntry
	push	bx				; save timer handle
endif

	; EC: load ES with something meaningful so segment EC that might
	; be invoked (yeek) by the routine won't get hosed. -- ardeb 1/13/95
EC <	segmov	es, ds						>
	mov	ax,ds:[bx].HTI_method
	mov	bp,ds:[bx].HTI_intervalOrID

	INT_ON
	call	ds:[bx].HTI_OD

if TEST_TIMER_CODE
	INT_OFF
	pop	bx				; retrieve handle
	mov	ax, TIMER_RT_RETURN		; return from RT timer
	LoadVarSeg	ds
	call	TestTimerCodeAddLogEntry
endif
	pop	di, bp, ds, es

	.leave
	ret
CallTimerRoutine	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleRoutineOneShot

DESCRIPTION:	Handle a timed action of the type TIMER_ROUTINE_ONE_SHOT

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	interrupts off
	bx - handle of timed action
	ds - idata

RETURN:
	** Return is via a jump to "TI_afterCall" for speed

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
------------------------------------------------------------------------------@

HandleRoutineOneShot	proc	far
			ON_STACK si si dx cx ds bx ax iret
	push	bx
			ON_STACK bx si si dx cx ds bx ax iret

	call	CallTimerRoutine

TimerPopAndFree	label	near
	pop	bx
			ON_STACK si si dx cx ds bx ax iret
	call	FreeHandle
if TEST_TIMER_FREE
TimerRoutineOneShotFreeHandle	label	near
endif

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	jmp	TI_afterCall			;return to TimerInterrupt

HandleRoutineOneShot	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleEventContinual

DESCRIPTION:	Handle a timed action of the type TIMER_EVENT_CONTINUAL

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	interrupts off
	bx - handle of timed action
	ds - idata

RETURN:
	** Return is via a jump to "TI_afterCall" for speed

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Call routine, then put structure back on list

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
------------------------------------------------------------------------------@

HandleEventContinual	proc	far
	ON_STACK si si dx cx ds bx ax iret
	mov	ax,ds:[bx].HTI_intervalOrID	;reset counter
	mov	ds:[bx].HTI_timeRemaining,ax
	mov	ds:[bx].HTI_next,0
	call	InsertTimedAction		;put routine back on list

	call	SendTimerEvent

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	jmp	TI_afterCall			;return to TimerInterrupt

HandleEventContinual	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendTimerEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to send an event from a timer

CALLED BY:	HandleEventContinual, HandleEventOneShot
PASS:		ds	= idata
		bx	= timer handle
RETURN:		interrupts on
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	If the timer is continual and the event from the previous expiration
	hasn't been handled yet, this one will overwrite it.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendTimerEvent	proc	near
	push	di, bp

	; if we're panicing then don't make things worse by trying to use
	; more handles and do more stuff

	mov	cx,ds:[systemCounter.high]
	mov	dx,ds:[systemCounter.low]
	mov	di,mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE or \
			mask MF_REPLACE

SendTimerEventLow	label	near
	on_stack	bp di retn

	test	ds:[exitFlags], mask EF_PANIC
	jnz	noSend

if TEST_TIMER_CODE
	mov	ax, TIMER_MSG_CALL		; sending a message
	call	TestTimerCodeAddLogEntry
	push	bx				; save handle
endif

	mov	ax,ds:[bx].HTI_method
	mov	bp,ds:[bx].HTI_intervalOrID
	mov	si,ds:[bx].HTI_OD.chunk
	mov	bx,ds:[bx].HTI_OD.handle	;OD to send to

	INT_ON
	call	ObjMessageNear			;send it

if TEST_TIMER_CODE
	INT_OFF
	pop	bx				; retrieve handle
	mov	ax, TIMER_MSG_RETURN		; sent a message
	call	TestTimerCodeAddLogEntry
endif
noSend:
	pop	di, bp
	ret
SendTimerEvent	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleEventOneShot

DESCRIPTION:	Handle a timed action of the type TIMER_EVENT_ONE_SHOT

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	interrupts off
	bx - handle of timed action
	ds - idata

RETURN:
	** Return is via a jump to "TI_afterCall" for speed

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
------------------------------------------------------------------------------@

HandleEventOneShot	proc	far
			ON_STACK si si dx cx ds bx ax iret
	push	bx
			ON_STACK bx si si dx cx ds bx ax iret

	call	SendTimerEvent

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	jmp	TimerPopAndFree
HandleEventOneShot	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleSleep

DESCRIPTION:	Handle a timed action of the type TIMER_SLEEP

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	interrupts off
	bx - handle of timed action
	ds - idata

RETURN:
	** Return is via a jump to "TI_afterCall" for speed

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
------------------------------------------------------------------------------@

HandleSleep	proc	far
			ON_STACK si si dx cx ds bx ax iret
	push	bx
			ON_STACK bx si si dx cx ds bx ax iret

	mov	ax,ds
	add	bx,offset HTI_method		;ax:[bx] = thread (it's a queue)
	call	WakeUpLongQueue

	pop	bx

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

	jmp	TI_afterCall

;	jmp	TimerPopAndFree			; Nope. Sleeper might not have
;						;  blocked on the thing yet.
;						;  Let the sleeper free it.
HandleSleep	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	HandleSemaphore

DESCRIPTION:	Handle a timed action of the type TIMER_SEMAPHORE

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	interrupts off
	bx - handle of timed action
	ds - idata

RETURN:
	** Return is via a jump to "TI_afterCall" for speed

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:
	bx - queue
	di - next thread on queue
	cx - target thread

PSEUDO CODE/STRATEGY:
	if (semaphore value >= 0)
		/* thread must have already been removed, do nothing */
	else
		search queue for given thread
		if (thread on queue)
			remove thread, set carry on stack
			increment semaphore value
			make it runnable
		else
			/* assume thread woke up */
		endif
	endif

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	7/88		Initial version
------------------------------------------------------------------------------@

HandleSemaphore	proc	far
	push	di
	push	es
	ON_STACK es di si si dx cx ds bx ax iret

	mov	cx,ds:[bx].HTI_method		;thread that timed out
	les	si,ds:[bx].HTI_OD		;es:si = queue
	cmp	{word}es:[si], KERNEL_INIT_BLOCK; block in kernel/interrupt?
	je	HS_kernelInit

	; test for already V'd

	cmp	es:[si-Sem_queue].Sem_value,0	;is value >= 0 ?
	jge	HS_done				;if so then thread must be gone

	; else do a V

	inc	es:[si-Sem_queue].Sem_value
if TEST_TIMER_CODE
	push	bx
	mov	ax, TIMER_SEMAPHORE
	clr	bx
	call	TestTimerCodeAddLogEntry
	pop	bx
endif


	mov	ax,si				;save queue offset

	; loop through queue to remove this thread
	; di = ptr that moves through list
	; es:si = &(last pointer)

HS_loop:
	mov	di,es:[si]			;di = next thread
	tst	di				;end of list?
	jz	HS_done
	cmp	di,cx				;found ?
	jz	HS_found
	LoadVarSeg	es			;es:si = &(this one)
	lea	si,es:[di].HT_nextQThread
	jmp	HS_loop

	; Thread found, remove it

HS_found:
	mov	di,ds:[di].HT_nextQThread	;remove from list
	mov	es:[si],di

	mov	si, cx				;si = thread
	les	si, dword ptr ds:[si].HT_saveSP	;point at stack
HS_setCarry:
	ornf	es:[si].TBS_flags, mask CPU_CARRY
	mov	si,cx				;wake up this thread
	push	bx				;save handle
	call	WakeUpSI
	pop	bx

HS_done:
	call	FreeHandle

if TEST_TIMER_FREE
TimerSemaphoreFreeHandle	label	near
endif

	pop	es
	pop	di
	ON_STACK si si dx cx ds bx ax iret

if	CATCH_MISSED_COM1_INTERRUPTS
	call	LookForMissedCom1Interrupt
endif

if TEST_TIMER_CODE
	push	ax,bx
	mov	ax, TIMER_SEMAPHORE
	mov	bx, 1
	call	TestTimerCodeAddLogEntry
	pop	ax,bx
endif

	INT_ON					;ensure interrupts
	jmp	TI_afterCall			;return to TimerInterrupt

	; blocked in kernel thread.  Pass KERNEL_INIT_BLOCK to WakeUpSI
	; which signals that the kernel thread is being awoken.

HS_kernelInit:
	inc	es:[si-Sem_queue].Sem_value	;value MUST be before queue
	mov	word ptr es:[si],0		;init queue to 0
	mov	cx,KERNEL_INIT_BLOCK
	les	si,ds:[initStack]
	jmp	HS_setCarry

HandleSemaphore	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	Handle a real-time timer

DESCRIPTION:	This routine should never be called

CALLED BY:	INTERNAL
		TimerInterrupt

PASS:
	interrupts off
	bx - handle of timed action
	ds - idata

RETURN:
	** Return is via a jump to "TI_afterCall" for speed

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Real-time timers should never be activated through this mechanism

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/93		Initial version
------------------------------------------------------------------------------@

HandleRealTime	proc	near
EC <	ERROR	CORRUPT_TIMER_LIST					>
NEC <	INT_ON					;ensure interrupts	>
NEC <	jmp	TI_afterCall			;return to TimerInterrupt >
HandleRealTime	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	RestoreTimerInterrupt

DESCRIPTION:	Restore the timer interrupt

CALLED BY:	EXTERNAL
		EndGeos

PASS:
	ds - kernel variable segment

RETURN:
	es - idata

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

------------------------------------------------------------------------------@

RestoreTimerInterrupt	proc	near
	tst	ds:timerInitialized
	jz	notInitialized
	INT_OFF

	; reset timer to default value. Can't use WriteTimer here as that
	; always programs to mode 2, not the mode 3 that the rest of the world
	; uses.

	TimerReset	DEFAULT_TIMER_VALUE

	; reset the timer vector to the old one.

	segmov	es, ds
	mov	ax, SDI_TIMER_0
	mov	di, offset timerSave
	call	SysResetDeviceInterruptInternal

if	HARDWARE_RTC_SUPPORT

ifidn HARDWARE_TYPE, <GULLIVER>
	;
	;  Restore the previous RTC handler.
	mov	ax, SDI_RTC
	mov	di, segment oldRTCHandler
	mov	es, di
	mov	di, offset oldRTCHandler
	call	SysResetDeviceInterruptInternal	; ax destroyed
else

	.err <need to uninitialize real-time-clock support>
endif

endif
	INT_ON
notInitialized:
	ret
RestoreTimerInterrupt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ZoomerRTCAlarmHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a real-time-clock alarm going off

CALLED BY:	Casio BIOS

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HARDWARE_RTC_SUPPORT

if		GULLIVER_COMMON

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RTCInterruptHandler for GULLIVER
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	IRQ 8

PASS/RETURN/DESTROYED:	Nothing, it's an interrupt handler.  Geez..

STRATEGY:
	We don't necessarily need to catch IRQ8 because it does enough in
	that it wakes the CPU up.  Once the CPU is awoken, the real time
	clock will be checked by either TimerInterrupt or by the setting
	of the clock from the real time clock in the power driver.  But,
	since Gulliver's RTC is a standard goofy Motorola MC146818A device,
	you can only set daily alarms.  So there is the distinct possiblity
	that the alarm went off and we were woken up BUT there is not alarm
	pending (today anyway).  This routine, then handles this problem.
	
	It works like this:
		
		No power driver? Then exit.
		
		Get time and date directly from RTC.  Does NOT set our
		local time and date.  Also, it may not be able to read 
		the RTC because it may be updating; see comment therein.
		
		Convert date into TimerCompressedDate and hours and minutes
		into one word.
		
		Check the first real time timer and compare it to the time
		and date read from the RTC.
		
		If a timer HAS expired, do nothing.  We will wake up as
		expected and the event will be dispatched as described above.
		
		If no timer was set, then clear the RTC alarm and tell the
		power driver that no alarm actually occurred.
		
	    	If a timer was set but none have expired yet, reset the RTC
		alarm and tell the power driver that no alarm actually
		occurred.
		
	Telling the power driver no alarm occurred is done via
	POWER_ESC_RTC_ACK.  This is kind of a hack but we don't need RTC
	ACK's anyway, so I used this way of telling the power driver
	what I mean.  When the power driver receives this message, it
	will simply go back to suspend IF AND ONLY IF it was just coming
	out of suspend.  If we weren't suspended, then nothing happens.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RTCInterruptHandler		proc	far
		uses	ax, bx, cx, dx, ds
		.enter
		
		call	SysEnterInterrupt
		INT_ON
		
		LoadVarSeg	ds, ax
		
		
	; If there's no power driver, there's no point.
	;
		tst	ds:[defaultDrivers].DDT_power
		jz	exit

	; We want to read the time and date from the real-time clock because
	; we may have just woken up.  It is possible that the RTC is busy
	; updating itself, so loop a few times to try to read it.  Give up
	; after a short while because we don't want to hang the system in an
	; interrupt handler.  If we cannot read it and there's no pending timer
	; but we've woken up anyway, we will go back to sleep do to APO
	; anyway, eventually.
		
		mov	cx, 100
tryAgain:
		call	GetTimeDateFromRTC
		jnc	gotIt
		loop	tryAgain
		jmp	exit
	
	;	al	= seconds
	;	ah	= minutes
	;	cl	= hours
	;	ch	= days
	;	dl	= months
	;	bx	= years
		
	; Convert date from RTC to TimerCompressedDate in bx (eventually
	; into ax)
	;
gotIt:
		sub	bx, 1980		; year - 1980, shifted
		shl	bx, offset TCD_YEAR
		clr	dh			; dx = month
		shl	dx, offset TCD_MONTH	; shift it the right amount
		or	bx, dx			; or it in
		or	bl, ch			; or in days
		
		mov	ch, ah			; cl = hrs, ch = mins
		xchg	cl, ch			; cl = mins, ch = hrs
		
		mov	ax, bx			; ax <- TCD
		
	;
	; Now check first real time timer to see if it expired
	;
		mov	bx, ds:[realTimeListPtr]
		tst	bx
		jz	noEventClearAlarm	; no real-timer timers
EC <		call	CheckHandleLegal				>
		cmp	ax, ds:[bx].HTI_timeRemaining
		ja	exit			; if past day, we have event
		jb	noEventReprogram	; if before day, we're done
		cmp	cx, ds:[bx].HTI_intervalOrID
		jb	noEventReprogram	; if before, we're done
		
		; same day, past time; we have an event, don't tell the
		; power driver nothin.
		
exit:
		INT_OFF
	
	;
	; Call BIOS's handler for this vector.. it will take care of sending
	; the proper EOI's.
	;
	
		pushf
		call	ds:[oldRTCHandler]
		
		call	SysExitInterrupt
		
		.leave
		iret


noEventReprogram:
    	;
	; Well, we need to reprogram the alarm just in case it won't get
	; done if the power driver actually sends us back to suspend.
	;
		push	si
		mov	si, bx
		call	ReprogramRealTimeTimer
		pop	si
		
noEvent:
	;
	; Tell power driver that we don't have an RTC event.  This is
	; special in Gulliver; if the power driver was just coming out of
	; suspend, it will return without really waking up.
	;
		push	di, si
		mov	di, DR_POWER_ESC_COMMAND
		mov	si, POWER_ESC_RTC_ACK
		call	ds:[powerStrategy]
		pop	di, si
		jmp	exit
		
noEventClearAlarm:
		mov	ah, TRTCF_RESET_RTC_ALARM
		int	TIMER_RTC_BIOS_INT
		jmp	short noEvent
		
RTCInterruptHandler		endp

else
	.err <put RTC alarm handler here>
endif

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckRealTimeTimers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if any real-time timers have expired

CALLED BY:	TimerInterrupt

PASS:		DS	= kdata

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckRealTimeTimersFar	proc	far
		call	CheckRealTimeTimers
		ret
CheckRealTimeTimersFar	endp

CheckRealTimeTimers	proc	near
		uses	ax, bx, cx
		.enter
	
		; Convert the current date to our TimerCompressedDate
		;
		mov	ax, ds:[years]
		sub	ax, 1980
		mov	cl, offset TCD_YEAR
		shl	ax, cl
		clr	bh
		mov	bl, ds:[months]
		mov	cl, offset TCD_MONTH
		shl	bx, cl
		or	ax, bx
		mov	bl, ds:[days]
		or	al, bl

		; Go through the list of timers
		;
		CheckHack <(offset minutes) - (offset hours) eq 1>
		mov	cx, {word} ds:[hours]	; Hours => CH
		xchg	cl, ch			; Minutes => CL
timerLoop:
		mov	bx, ds:[realTimeListPtr]
		tst	bx
		jz	done			; if no real-timer timers, done
EC <		call	CheckHandleLegal				>
		cmp	ax, ds:[bx].HTI_timeRemaining
		ja	sendEvent		; if past day, generate event
		jb	done			; if before day, we're done
		cmp	cx, ds:[bx].HTI_intervalOrID
		jb	done			; if before, we're done

		; Send an event off, after replacing the head pointer,
		; just to ensure we won't loop back here before the
		; SendTimerEvent returns.
sendEvent:
		push	ax, bx, cx, dx, si
		mov	ax, ds:[bx].HTI_next
		mov	ds:[realTimeListPtr], ax
		mov	ax, (offset afterSendEvent)
		push	ax			; return address
		mov	cx, bx
		mov	dx, ds:[bx].HTI_timeRemaining
		cmp	ds:[bx].HTI_type, TIMER_ROUTINE_REAL_TIME
		je	isRout
		push	di, bp
		mov	di, mask MF_FORCE_QUEUE
		jmp	SendTimerEventLow	; send the event off
isRout:
		jmp	CallTimerRoutineLow		
afterSendEvent:

		pop	ax, bx, cx, dx, si
		
		call	FreeHandle		; free the timer handle
		jmp	timerLoop		; and continue

		; Reset the next RTC alarm
done:
if	HARDWARE_RTC_SUPPORT
		tst	bx			; if NULL, we're done
		jz	clearHardware					
		push	si
		mov	si, bx
		call	ReprogramRealTimeTimer
		pop	si
exit:
		call	TimerNotifyPowerDriver
endif
		INT_OFF

		.leave
		ret
if	HARDWARE_RTC_SUPPORT
clearHardware:
	;
	;  Make sure the RTC hardware doesn't have any spurious
	;  interrupts, or we might wake up when we've critically
	;  suspended, and kill the ram drive due to lack of power.
	mov	ah, TRTCF_RESET_RTC_ALARM
	int	TIMER_RTC_BIOS_INT
	jmp	short exit
endif	
CheckRealTimeTimers	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerNotifyPowerDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the power driver that a real-time timer has expired
	
CALLED BY:	CheckRealTimeTimers

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/29/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HARDWARE_RTC_SUPPORT
TimerNotifyPowerDriver	proc near
		uses	ds, di
		
		.enter
		LoadVarSeg	ds, ax
		tst	ds:defaultDrivers.DDT_power
		jz	done

		mov	di, DR_POWER_RTC_ACK
		call	ds:[powerStrategy]
done:

		.leave
		ret
TimerNotifyPowerDriver	endp
endif	; HARDWARE_RTC_SUPPORT


DosapplCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend operation of the timer while the system goes into
		stasis.

CALLED BY:	EXTERNAL
		DosExecSuspend
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, es, di, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerSuspend	proc	near
		.enter
	;
	; reset timer to default value. Can't use WriteTimer here as that
	; always programs to mode 2, not the mode 3 that the rest of the world
	; uses.
	;
	TimerReset	DEFAULT_TIMER_VALUE
	;
	; reset the timer vector to the old one.
	;
		segmov	es, ds
		mov	ax, SDI_TIMER_0
		mov	di, offset timerSave
		call	SysResetDeviceInterruptInternal
		.leave
		ret
TimerSuspend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring the timer out of stasis.

CALLED BY:	EXTERNAL
		DosExecUnsuspend
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, di, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerUnsuspend	proc	near
		.enter
	;
	; Get the new date & time. XXX: can't notify everyone until all
	; the drivers are awakened...
	; 

		mov	ah,MSDOS_GET_DATE		;get date
		int	21h
		mov	ds:[years],cx
		mov	ds:[months],dh
		mov	ds:[days],dl
		mov	ds:[dayOfWeek],al

		mov	ah,MSDOS_GET_TIME		;get time
		int	21h
		mov	ds:[hours],ch
		mov	ds:[minutes],cl
		mov	ds:[seconds],dh
	;
	; Re-intercept the timer interrupt.
	; 
		segmov	es, ds
		mov	ax, SDI_TIMER_0
		mov	bx, segment TimerInterrupt
		mov	cx, offset TimerInterrupt
		mov	di, offset timerSave
		call	SysCatchDeviceInterruptInternal
	;
	; Start off with a fresh 60-ips timebase.
	; 
		mov	ax, GEOS_TIMER_VALUE
		call	FarWriteTimer
		
		mov	ds:[unitsSinceLastTick], 0
	;
	; Reprogram the timer for the head of the list.
	; 
		mov	si, ds:[timeListPtr]
		call	FarReprogramTimerSI
		.leave
		ret
TimerUnsuspend	endp

DosapplCode	ends
