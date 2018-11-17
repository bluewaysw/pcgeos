COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Timer
FILE:		timerInit.asm

ROUTINES:
	Name		Description
	----		-----------
   EXT	InitTimer	Initialize the timer module

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/88		Initial version

DESCRIPTION:
	This module initializes the timer module.  See manager.asm for
documentation.

	$Id: timerInit.asm,v 1.1 97/04/05 01:15:35 newdeal Exp $

-------------------------------------------------------------------------------@

COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitTimer

DESCRIPTION:	Initialize the process module

CALLED BY:	INTERNAL
		InitGeos

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx, si

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Initialize the time and date from MS-DOS
	Set the timer interrupt to the PC GEOS handler and calculate the
	totalCount value used in idle time calculations.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/88		Initial version

-------------------------------------------------------------------------------@

InitTimer	proc	near
	push	ds
	segmov	ds, cs
	mov	si, offset timerLogString
	call	LogWriteInitEntry
	pop	ds

	call	InitTimeDate		;init time and date from MS-DOS
	call	SetTimerInterrupt
	mov	ds:timerInitialized, 1

if	HARDWARE_RTC_SUPPORT

ifidn	HARDWARE_TYPE, <GULLIVER>

	;
	;  Set up a handler for RTC interrupt.
	;
	mov	ax, SDI_RTC
	mov	bx, segment RTCInterruptHandler
	mov	cx, offset RTCInterruptHandler
	mov	di, segment oldRTCHandler
	mov	es, di
	mov	di, offset oldRTCHandler
	call	SysCatchDeviceInterruptInternal
	
	;
	; Make sure the RTC hardware is the way we
	; want it to be (namely no pending Alarm
	; from the previous reboot)...
	mov	ah, TRTCF_RESET_RTC_ALARM
	int	TIMER_RTC_BIOS_INT

else
	.err <need to initialize real-time-clock support>
endif

endif
	ret
InitTimer	endp

timerLogString	char	"Timer Module", 0


COMMENT @-----------------------------------------------------------------------

FUNCTION:	SetTimerInterrupt

DESCRIPTION:	Set the routine TimerInterrupt to handle INT 8

CALLED BY:	INTERNAL
		InitTimer

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:
	Set up timer for interrupts 60 times per second
	Set up the interrupt vector for our special routine
	Count the number of times that a special loop can be run in one
	second.  This is used for idle time computation.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

SetTimerInterrupt	proc	near	uses es
	.enter

	; save old interrupt vector

	clr	ax
	mov	es, ax
	mov	ax, es:[TIMER_INTERRUPT_VECTOR].offset	;save old vector
	mov	ds:timerSave.offset,ax
	mov	ax, es:[TIMER_INTERRUPT_VECTOR].segment
	mov	ds:timerSave.segment,ax
	
	push	ds:[runQueue]			;save pass value of runQueue

	;set temporary vector for speed test

	INT_OFF
	mov	es:[TIMER_INTERRUPT_VECTOR].offset, offset STI_tempVector
	mov	es:[TIMER_INTERRUPT_VECTOR].segment,cs

	; enable interrupts for Timer1


	; set timer for interrupts 60 times per second

	mov	ax, GEOS_TIMER_VALUE
	call	FarWriteTimer
	INT_ON

	call	ComputeCPUSpeed
	call	ComputeDispatchLoopSpeed

	; set up real interrupt handler

	INT_OFF
	clr	ax
	mov	es, ax
	mov	es:[TIMER_INTERRUPT_VECTOR].offset ,offset TimerInterrupt
	mov	es:[TIMER_INTERRUPT_VECTOR].segment, segment TimerInterrupt
	
	INT_ON

	; reset tickCount and runQueue

	mov	ds:[ticks],INTERRUPT_RATE / 2
	pop	ds:[runQueue]

if	0 ; ERROR_CHECK
	; if machine is fast enough, set up some default ec
	mov	dx, ds:[totalCount].high
	mov	ax, ds:[totalCount].low
	mov	cx, 53666	; idle count on a base PC
	div	cx
	
	cmp	ax, 4
	jb	ecDone
	ornf	ds:[sysECLevel], mask ECF_NORMAL
	cmp	ax, 5
	jb	ecDone
	ornf	ds:[sysECLevel], mask ECF_SEGMENT
	cmp	ax, 6
	jb	ecDone
	ornf	ds:[sysECLevel],
			mask ECF_HEAP_FREE_BLOCKS or mask ECF_LMEM_OBJECT
	cmp	ax, 8
	jb	ecDone
	ornf	ds:[sysECLevel], mask ECF_LMEM_FREE_AREAS
ecDone:
endif

	.leave
	ret

SetTimerInterrupt	endp

STI_tempVector	proc	far
	push	ax
	push	ds

if	HARDWARE_INT_CONTROL_8259

	mov	al,IC_SPECEOI or SDI_TIMER_0		;send EOI
	out	IC1_CMDPORT,al

else


endif

	mov	ax,seg idata
	mov	ds,ax

	; Notify the power management driver that we need to exit the
	; idle state

	tst	ds:defaultDrivers.DDT_power
	jz	noPowerDriver1
	push	di
	mov	di, DR_POWER_NOT_IDLE
	call	ds:powerStrategy
	pop	di
noPowerDriver1:

	dec	ds:[ticks]
	jnz	notDone

	mov	ds:[runQueue],1

	; Notify the power management driver that a thread will be woken
	; up when we exit the interrupt

	tst	ds:defaultDrivers.DDT_power
	jz	noPowerDriver2
	push	di
	mov	di, DR_POWER_NOT_IDLE_ON_INTERRUPT_COMPLETION
	call	ds:powerStrategy
	pop	di
noPowerDriver2:

notDone:
	pop	ds
	pop	ax
	iret

STI_tempVector	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ComputeCPUSpeed

DESCRIPTION:	Compute the CPU speed by timing a known loop

CALLED BY:	SetTimerInterrupt

PASS:
	ds - kernel variable segment

RETURN:
	cpuSpeed - set

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version
	Falk	7/16/09	overflow check to fix fast CPU bug
	Falk	7/18/09	make Perf report correct speed
	Falk	7/26/09	limit the fix to Breadbox Ensemble

------------------------------------------------------------------------------@


	; Base count is 53666, so the number should be 1118, but that gives
	; the wrong result.  This seems to give the right result.

BASE_XT_TOTAL_COUNT_DIV_BY_30_MUL_10_DIV_16	=	2817

versionKeyStr		char	"version", 0
versionCategoryStr	char	"system", 0

ComputeCPUSpeed	proc	near

if not KERNEL_EXECUTE_IN_PLACE and (not FULL_EXECUTE_IN_PLACE)

	; to make the computation of totalCount consistent on 386's, it is
	; essential for the paragraph offset of the loop used here (waitLoop)
	; to be the same each time.

	mov	ax, offset countLoop
	and	ax, 15
	jz	noMoveNecessary

	; need to move the loop backward ax bytes

	push	ds
	segmov	ds, cs
	segmov	es, cs
	mov	si, offset countLoop		;source = countLoop
	mov	di, si
	sub	di, ax				;compute dest
	mov	cx, (offset endCountLoop) - (offset countLoop)
	rep	movsb

	; store nop's at the end

	mov	cx, ax
	mov	ax, 0x90		;nop
	rep	stosb
	pop	ds
noMoveNecessary:
endif
	mov	bx,offset runQueue	;for testing...
	mov	ds:[runQueue],0
	mov	ds:[ticks],2 + 2

	; wait to sync on first interrupt...

if	INTERRUPT_RATE gt 255

	mov	ax, 2
waitLoop:
	cmp	ax,ds:[ticks]
	jnz	waitLoop

else

	mov	al, 2
waitLoop:
	cmp	al,ds:[ticks]
	jnz	waitLoop

endif

	; time this loop...

	nop				;16 nop's so that we can move the
	nop				;loop (above)
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

countLoop:
	cmp	word ptr ds:[bx],0
	jnz	endCountLoop
	inc	ds:[curStats].SS_idleCount.low	;increment double word
	jnz	countLoop
	inc	ds:[curStats].SS_idleCount.high
	jmp	countLoop

endCountLoop:

	; divide count by magic number to get CPU speed

	; ugly math here to keep precision.  The count that we have is for
	; two interrupts (1/30 of a second).  Multiply this value by 16, then
	; divide by BASE_COUNT/(30*10/16).  This leaves us a value * 10
	; speed of the machine.

	clr	dx		; reset idleCount for COmputeDispatchLoopSpeed
	mov	ax, dx		;  as we fetch the idleCount we got
	xchg	dx, ds:[curStats].SS_idleCount.high
	xchg	ax, ds:[curStats].SS_idleCount.low	;dx:ax = count
	mov	cx, 4
10$:
	shl	ax
	rcl	dx
	loop	10$

	; FIX_START
	; check for right kernel version - looks for version 4x
	push	ds, ax, dx
	segmov	ds, cs, cx
	mov	si, offset versionCategoryStr
	mov	dx, offset versionKeyStr		
	call	InitFileReadInteger
	jnc	gotValue

	pop	ds, ax, dx
	jmp	versionError	
gotValue:
	dec	ax
	dec	ax
	dec	ax
	dec	ax
	tst	ax
	pop	ds, ax, dx
	jne	versionError

	; check for overflow on fast CPU before hand
	; fix fast CPU bug
	cmp	dx, 0x0b00
	jbe	noOverflow

	mov	dx, 0x0b00
	mov	ax, 0xffff
	
noOverflow:
versionError:
	; FIX_END

	mov	cx, BASE_XT_TOTAL_COUNT_DIV_BY_30_MUL_10_DIV_16
	div	cx
	cmp	dx, BASE_XT_TOTAL_COUNT_DIV_BY_30_MUL_10_DIV_16/2
	jbe	noRound
	inc	ax
noRound:

	; need this FIX for Perf to show correct speed
	tst	ax
	jnz	notNull
	dec	ax
notNull:
	; end of Perf FIX

	mov	ds:[cpuSpeed], ax

	ret

ComputeCPUSpeed	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ComputeDispatchLoopSpeed

DESCRIPTION:	Compute the dispatch loop speed

CALLED BY:	SetTimerInterrupt

PASS:
	ds - kernel variable segment

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	1/91		Initial version

------------------------------------------------------------------------------@

ComputeDispatchLoopSpeed	proc	near

if not KERNEL_EXECUTE_IN_PLACE and (not FULL_EXECUTE_IN_PLACE)

	; to make the computation of totalCount accurate on 386's, it is
	; essential for the paragraph offset of the loop used here (waitLoop)
	; to be the same as the paragraph offset of the loop in Dispatch
	; (DispatchLoop).

	; First, compute the difference, then move the loop to the correct
	; spot

	mov	ax, offset countLoop
	sub	ax, offset DispatchLoop
	and	ax, 15
	jz	noMoveNecessary

	; need to move the loop backward ax bytes

	push	ds
	segmov	ds, cs
	segmov	es, cs
	mov	si, offset countLoop		;source = countLoop
	mov	di, si
	sub	di, ax				;compute dest
	mov	cx, (offset endCountLoop) - (offset countLoop)
	rep	movsb

	; store nop's at the end

	mov	cx, ax
	mov	ax, 0x90		;nop
	rep	stosb
	pop	ds
noMoveNecessary:
endif
	mov	bx,offset runQueue	;for testing...
	mov	ds:[runQueue], 0

	mov	ds:[ticks],2 + 2

	; wait to sync on first interrupt...

if	INTERRUPT_RATE gt 255

	mov	ax, 2
waitLoop:
	cmp	ax,ds:[ticks]
	jnz	waitLoop

else

	mov	al, 2
waitLoop:
	cmp	al,ds:[ticks]
	jnz	waitLoop

endif

	; time this loop...

	nop				;16 nop's so that we can move the
	nop				;loop (above)
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop

countLoop:
	tst	ds:runQueue
	jnz	endCountLoop
	call	Idle
	jmp	countLoop

endCountLoop:

	; multiply count by 30 to get the value for a full second

	mov	ax, ds:[curStats].SS_idleCount.low
	mov	cx, 30
	mul	cx

	; transfer count into totalCount for later use...

	mov	ds:[totalCount].high, dx
	mov	ds:[totalCount].low, ax

	; reset the idleCount to zero to avoid a long count in the first
	; second (wouldn't that be tragic?)

	clr	ax
	mov	ds:[curStats].SS_idleCount.high, ax
	mov	ds:[curStats].SS_idleCount.low, ax

	ret

ComputeDispatchLoopSpeed	endp

COMMENT @-----------------------------------------------------------------------

FUNCTION:	InitTimeDate

DESCRIPTION:	Set the time and date variables

CALLED BY:	INTERNAL
		InitTimer

PASS:
	ds - kernel variable segment

RETURN:
	none

DESTROYED:
	ax, bx, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/88		Initial version
-------------------------------------------------------------------------------@

InitTimeDate	proc	near
	mov	ah,MSDOS_GET_TIME		;get time
	int	21h
	mov	ds:[hours],ch
	mov	ds:[minutes],cl
	mov	ds:[seconds],dh

	mov	ah,MSDOS_GET_DATE		;get date
	int	21h
	mov	ds:[years],cx
	mov	ds:[months],dh
	mov	ds:[days],dl
	mov	ds:[dayOfWeek],al
	ret
InitTimeDate	endp
