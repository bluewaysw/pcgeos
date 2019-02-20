COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		timebreak.asm

AUTHOR:		Adam de Boor, Apr 14, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/92		Initial revision


DESCRIPTION:
	Support for timing breakpoints.
		
	There are effectively two types of breakpoints handled by this
	code:
		- starting breakpoints, which can be conditional and are
		  responsible for creating...
		- ending breakpoints, which turn off timing for their
		  corresponding starting breakpoints.

	When a start breakpoint is hit, if any associated conditions are
	met, we must:
		1) figure where the ending breakpoint must be set
		2) set it
		3) add the ending breakpoint to the list of active ending
		   breakpoints
		4) if it's the first one to become active, intercept the
		   timer interrupt (again)
		5) record the remaining clock units in the current tick
	
	When an ending breakpoint is hit:
		1) record the remaining clock units in the current tick
		2) make sure the right thread is running, else just skip the bpt
		3) make sure any SP-constraint is met, else just skip the bpt
		4) remove the ending breakpoint from the list
		5) stop intercepting the timer interrupt if no more ending
		   bpts active
		6) add the appropriate number of ticks and c.u.s to the
		   associated starting breakpoint

	During an intercepted timer tick:
		fetch the current thread
		for each active ending breakpoint:
			if breakpoint is for the current thread, add 1 to its
			   tick count
		pass the interrupt on

	$Id: timebreak.asm,v 1.5 94/06/03 18:35:41 jimmy Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		include	stub.def
		include Internal/heapInt.def	; for HandleMem
.386
scode		segment
		assume	cs:scode,ds:cgroup,es:cgroup,ss:sstack



TimeBreak	struct
    TB_bpt	BptClient	; common stuff
    TB_ticks	dword		; accumulated ticks
    TB_cus	word		; accumulated clock units
    TB_hits	dword		; Number of times the thing has been hit
    TB_finish	label fptr	; first handle & offset of place to put 
    				;  finishing breakpoint. handle is 0 to
				;  indicate routine should be finished.
				;  Others may follow.
TimeBreak	ends

EndTB		struct
    ETB_bpt	BptClient	; common stuff
    ETB_next	nptr.EndTB	; next active ending bpt
    ETB_cohort	nptr.EndTB	; next ending bpt set for same hitting of
				;  starting bpt, so all can be cleared when
				;  one is hit.
    ETB_ticks	dword		; accumulated ticks
    ETB_startCUs word		; clock units actually used in first tick
    ETB_stb	nptr.TimeBreak	; associated starting TimeBreak
    ETB_spMin	word		; minimum value for SP for us to accept that
				;  the end is near. Used in dealing with
				;  finishing a recursive routine
    ETB_thread	hptr		; the thread for which the timing is happening
EndTB		ends

tbEndList	nptr.EndTB	; head of chain of active EndTBs
tbOldTimer	fptr.far 0	; old timer interrupt vector while TBs are
				;  active
tbOverhead	word		; clock-units required to service a timing
				;  breakpoint.


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TB_Set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a timing breakpoint.

CALLED BY:	RPC_SETTIMEBRK
PASS:		ds, es = cgroup
		rpc_LastCall	= call just received
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TB_Set		proc	near
		.enter
	;
	; Allocate a TimeBreak record first, calculating the number of ending
	; breakpoints the beastie requires, based on the size of the packet
	; we received.
	; 
		clr	cx
		mov	cl, ds:[rpc_LastCall].RMB_header.rh_length
		sub	cx, offset stiba_endIP
		jz	badArgs
		push	cx
		add	cx, size TimeBreak
		call	Bpt_Alloc
		pop	cx
	
		mov	al, RPC_TOOBIG
		tst	si
		jz	noRoom
	;
	; Initialize it appropriately
	; 
		mov	ds:[si].TB_bpt.BC_handler, offset TBStartHandler
		clr	ax
		mov	ds:[si].TB_bpt.BC_flags, al
		mov	ds:[si].TB_ticks.low, ax
		mov	ds:[si].TB_ticks.high, ax
		mov	ds:[si].TB_cus, ax
		mov	ds:[si].TB_hits.low, ax
		mov	ds:[si].TB_hits.high, ax

		lea	di, ds:[si].TB_finish
		push	si
		lea	si, ({SetTimeBrkArgs}CALLDATA).stiba_endIP
		rep	movsb
	;
	; Now set the breakpoint itself. We don't know what the instruction
	; is supposed to be...
	; 
		mov	cx, ({SetTimeBrkArgs}CALLDATA).stiba_cs
		mov	dx, ({SetTimeBrkArgs}CALLDATA).stiba_ip
		mov	ax, ({SetTimeBrkArgs}CALLDATA).stiba_xipPage
		pop	bx		; bx <- client data
		call	Bpt_Set
		tst	si
		jz	noRoomFreeClient

		mov	{word}ds:[rpc_ToHost], bx
		mov	cx, size word
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
done:
		.leave
		ret

badArgs:
		mov	al, RPC_BADARGS
		call	Rpc_Error
		jmp	done

noRoomFreeClient:
		mov	si, bx
		call	Bpt_Free
noRoom:
		call	Rpc_Error
		jmp	done
TB_Set		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TB_GetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current time & count for the given breakpoint

CALLED BY:	RPC_GETTIMEBRK
PASS:		rpc_LastCall.RMB_data holds offset of TimeBreak
RETURN:		current count (dword)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TB_GetTime	proc	near
		.enter
		mov	si, {word}ds:[rpc_LastCall].RMB_data
		add	si, offset TB_ticks
CheckHack <size GetTimeBrkReply eq size TB_ticks+size TB_cus+size TB_hits>
		mov	cx, size GetTimeBrkReply
		call	Rpc_Reply
		.leave
		ret
TB_GetTime	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TB_ZeroTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zero the time & count for a timing breakpoint

CALLED BY:	RPC_ZEROTIMEBRK
PASS:		rpc_LastCall.RMB_data holds offset of TimeBreak
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TB_ZeroTime	 proc	near
		.enter
		mov	si, {word}ds:[rpc_LastCall].RMB_data
		clr	cx		; zero for storing & for reply length
		mov	ds:[si].TB_ticks.low, cx
		mov	ds:[si].TB_ticks.high, cx
		mov	ds:[si].TB_cus, cx
		mov	ds:[si].TB_hits.low, cx
		mov	ds:[si].TB_hits.high, cx
		call	Rpc_Reply
		.leave
		ret
TB_ZeroTime endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TB_Clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a timing breakpoint.

CALLED BY:	RPC_CLEARTIMEBRK
PASS:		rpc_LastCall.RMB_data holds offset of TimeBreak
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TB_Clear	proc	near
		.enter
	;
	; Clear and biff any and all associated EndTB structures.
	; 
	
		mov	si, offset tbEndList - offset ETB_next
		mov	ax, {word}ds:[rpc_LastCall].RMB_data
clearEndLoop:
		mov	bx, si
		mov	si, ds:[bx].ETB_next
		tst	si
		jz	endsAllCleared
		
		cmp	ds:[si].ETB_stb, ax	; does this one refer to the
						;  start one we're about to
						;  nuke?
		jne	clearEndLoop		; no
		
		mov	cx, ds:[si].ETB_next	; yes -- unlink the end from
		mov	ds:[bx].ETB_next, cx	;  the chain in a nice atomic
						;  fashion
		call	Bpt_Clear		; now clear it
		call	Bpt_Free		; and biff it
		mov	si, bx			; keep going from the previous
						;  EndTB again
		jmp	clearEndLoop
		
endsAllCleared:
	;
	; Clear the breakpoint first.
	; 
		mov_tr	si, ax
		call	Bpt_Clear
	;
	; Now free the TimeBreak record.
	; 
		call	Bpt_Free
		
		clr	cx
		call	Rpc_Reply
		.leave
		ret
TB_Clear	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBStartHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a timer-start breakpoint being hit

CALLED BY:	Bpt_Check
PASS:		ds:si	= TimeBreak
		cx	= BptCallStatus
RETURN:		cx	= new BptCallStatus
		ax	= BptCallResult
DESTROYED:	many things

PSEUDO CODE/STRATEGY:
		if BCS_UNCONDITIONAL || BCS_CONDITION_SATISFIED:
		    start timing & clear BCS_TAKE_IT:
		    1) figure where the ending breakpoint must be set
		    2) set it
		    3) add the ending breakpoint to the list of active ending
		       breakpoints
		    4) if it's the first one to become active, intercept the
		       timer interrupt (again)
		    5) record the remaining clock units in the current tick
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBStartHandler	proc	near
		.enter
		
		test	cx, mask BCS_UNCONDITIONAL or mask BCS_CONDITION_SATISFIED
		jnz	setEndBP
		
done:
		mov	ax, BCR_OK
		.leave
		ret

	;
	; Pop the saved breakpoints off the stack one at a time and free each.
	; 0 sentinel pushed on the stack at start of set loop.
	; 
freeAnySet:
		pop	si 
		tst	si
		jz	cannotSet
		call	Bpt_Free	; free it
		jmp	freeAnySet
cannotSet:
		inc	sp		; discard saved cx
		inc	sp		;  as we're returning our own
	;
	; Bring the thing to a crashing halt if we can't set the end
	; point...
	; 
		mov	cx, mask BCS_UNCONDITIONAL or mask BCS_TAKE_IT
		jmp	done

	;--------------------
setEndBP:
		push	cx		; save passed BptCallStatus

		lea	bx, ds:[si].TB_finish	; ds:bx <- next endbpt to set
		Bpt_Size	si, cx
		sub	cx, offset TB_finish
		shr	cx
		shr	cx		; cx <- # end bpts to set

		clr	ax		; push sentinel
		push	ax
setEndBPLoop:
		call	TBSetEndBP	; set the next one
		jc	freeAnySet	; => error

		push	ax		; save for final linking
		add	bx, size fptr
		loop	setEndBPLoop
	;
	; Ending breakpoint(s) successfully set, so up the number of times the
	; starting breakpoint has been hit.
	; 
		inc	ds:[si].TB_hits.low
		jnz	hitsUpdated
		inc	ds:[si].TB_hits.high
hitsUpdated:
	;
	; Link the new things together through their ETB_cohort field.
	; Only one thing makes it onto the tbEndList, as we only need one of
	; them to track the time.
	; 
		clr	cx		; cx <- ETB_cohort link for next thing
linkLoop:
		pop	si		; ds:si <- next EndTB
		tst	si
		jz	linkDone
		
		mov	ds:[si].ETB_cohort, cx	; link to next ETB set for same
						;  hitting of STB
		mov	cx, si		; save for next iteration
		jmp	linkLoop

linkDone:
	;
	; Link the final one into the tbEndList. Note that interrupts
	; have been off this whole time (yipes!), so this is safe to do.
	;
		mov	si, cx			; si <- last one
		xchg	ds:[tbEndList], cx	; cx <- head of current list
		mov	ds:[si].ETB_next, cx
		jcxz	interceptTimer		; => list was empty, so we
						;  need to intercept the
						;  timer
finish:
	;
	; Tell RestoreState to fetch the current timer count and store it
	; in our data-structure.
	; 
		add	si, offset ETB_startCUs
		mov	ds:[ssResumeTimerCountPtr], si
	;
	; Tell caller not to take this breakpoint, and get out of here.
	; 
		pop	cx
		andnf	cx, not mask BCS_TAKE_IT
	;
	; give timer tick a chance to happen so we don't get thrown off...
	;
		eni
		nop
		dsi
		jmp	done

interceptTimer:
	;
	; This is the first EndTB to become active, so we must intercept the
	; timer interrupt...since state is saved, the easiest thing to do
	; is to change the saved interrupt vector in the state block and
	; have RestoreState put our routine in the real vector.
	; 
		mov	ax, offset TBTimerInt
		xchg	ss:[bp].state_timerInt.offset, ax
		mov	ds:[tbOldTimer].offset, ax
		mov	ax, cs
		xchg	ss:[bp].state_timerInt.segment, ax
		mov	ds:[tbOldTimer].segment, ax
		jmp	finish
TBStartHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBSetEndBP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an ending breakpoint for a starting breakpoint

CALLED BY:	(INTERNAL) TBStartHandler
PASS:		ds:si	= TimeBreak
		ds:bx	= dword holding place at which to set ending
			  breakpoint. If high word is 0, wants to end on
			  return, and low word is non-zero to indicate routine
			  is far. If high word is non-zero, it's a handle,
			  and the offset is the offset within that block at
			  which to place the ending breakpoint
RETURN:		carry set if couldn't set
		carry clear if set:
			ax	= offset of EndTB (not yet linked into
				  tbEndList)
DESTROYED:	dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBSetEndBP	proc	near
		uses	bx, si
		.enter
		mov	ax, ds:[bx].offset
		mov	bx, ds:[bx].segment
		tst	bx
		jz	handleFinish
	;
	; Get the current segment of the end point. If it's not in memory, we
	; can't do all this (for now, since Bpt_Set only takes a segment)...
	; 
		push	es
		mov	es, ds:[kdata]
		mov	bx, es:[bx].HM_addr
		pop	es
		tst	bx
		jz	cannotSet
		clr	dx		; no minimum for SP in this case
haveAddress:
	;
	; bx:ax = place at which to set the breakpoint.
	; dx = threshold above which SP must be when the bpt is hit for timing
	;      to end.
	; Allocate the EndTB structure and initialize it.
	; 
		push	cx, bx, ax
		mov	cx, size EndTB
		mov	bx, si		; save TimeBreak offset
		call	Bpt_Alloc
		mov	ds:[si].ETB_bpt.BC_handler, offset TBEndHandler
		mov	ds:[si].ETB_bpt.BC_flags, mask BCF_AT_FRONT
		mov	ds:[si].ETB_stb, bx
	;
	; Initialize ticks to 0.
	; 
		clr	ax
		mov	ds:[si].ETB_ticks.low, ax
		mov	ds:[si].ETB_ticks.high, ax
	;
	; Set SP threshold and fetch the current thread from the state block.
	; 
		mov	ds:[si].ETB_spMin, dx
		mov	ax, ss:[bp].state_thread
		mov	ds:[si].ETB_thread, ax
	;
	; Now set the ending breakpoint.
	; 
		pop	cx, dx			; cx:dx <- address for bpt
		mov	bx, si			; ds:bx <- BptClient
		mov	ax, -1
		call	Bpt_Set
		pop	cx

		tst	si
		jz	freeCannotSet
		mov_tr	ax, bx			; return BptClient offset,
						;  carry already clear
done:
		.leave
		ret

freeCannotSet:
		mov	si, bx		; si <- EndTB
		call	Bpt_Free
cannotSet:
		stc
		jmp	done

handleFinish:
	;
	; Deal with a start breakpoint whose end is the instruction to which
	; the routine will return. ax is non-zero if the routine is far.
	; 
		push	es
		mov	di, ss:[bp].state_sp
		mov	es, ss:[bp].state_ss	; es:di <- machine's ss:sp
		mov	dx, di			; dx <- spMin
		
		mov	bx, ss:[bp].state_cs	; assume it's near
		tst	ax			; near routine?
		mov	ax, es:[di].offset
		jz	handleFinishHaveAddress	; yes
		mov	bx, es:[di].segment	; no -- get CS too
handleFinishHaveAddress:
		pop	es
		jmp	haveAddress
TBSetEndBP	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBEndHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with an ending breakpoint being hit.

CALLED BY:	Bpt_Check
PASS:		ds:si	= EndTB
		cx	= BptCallStatus
RETURN:		cx	= new BptCallStatus
		ax	= BptCallResult (BCR_OK, BCR_REMOVE_AND_FREE)
DESTROYED:	many things

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBEndHandler	proc	near
		.enter
	;
	; See if the conditions for the end have been satisfied:
	;	* must be executing on the same thread as that in which timing
	;	  started
	;	* SP must be above the minimum specified, to deal with
	;	  timing recursive routines.
	;
		mov	ax, ss:[bp].state_thread
		cmp	ds:[si].ETB_thread, ax	; executing on proper thread?
		jne	doneOK
		
		mov	ax, ss:[bp].state_sp
		cmp	ax, ds:[si].ETB_spMin
		ja	stopTiming
doneOK:
	;
	; Don't do anything about this breakpoint; just leave the BCS alone.
	; If something else wants to stop the machine, that's fine, but we're
	; not going to commit one way or another.
	; 
		mov	ax, BCR_OK
done:
		.leave
		ret

stopTiming:
		push	cx		; save BCS so we can abuse CX
	;
	; Find the EndTB on the list for which this one is a cohort.
	; 
		mov	ax, offset tbEndList - offset ETB_next
findPrevLoop:
		mov_tr	bx, ax
		mov	ax, ds:[bx].ETB_next
		mov	di, ax
findCohortLoop:
		cmp	di, si
		je	foundIt
		mov	di, ds:[di].ETB_cohort
		tst	di
		jz	findPrevLoop	; => hit end of cohort chain w/o finding
					;  it, so this ain't the one
		jmp	findCohortLoop
foundIt:
	;
	; Free all the cohorts except the head, which contains all the
	; timing info, and the one for which we were called, which will be
	; nuked when we return BCR_REMOVE_AND_FREE.
	;
		mov	dx, si		; dx <- bpt for which we were called
		mov_tr	si, ax
		mov	si, ds:[si].ETB_cohort	; si <- first cohort that's not
						;  the head.
freeCohortLoop:
		tst	si			; end of the line?
		jz	cohortsNuked		; yes
		mov	ax, ds:[si].ETB_cohort	; fetch next cohort while this
						;  one still exists.
		cmp	si, dx			; calling bpt?
		je	nextCohort		; yes
		call	Bpt_Clear		; no -- nuke it
		call	Bpt_Free
nextCohort:
		mov_tr	si, ax			; si <- next bpt
		jmp	freeCohortLoop

cohortsNuked:
	;
	; Unlink the whole chain from the loop.
	; 
		mov	si, ds:[bx].ETB_next
		mov	ax, ds:[si].ETB_next
		mov	ds:[bx].ETB_next, ax
	;
	; If this was the final EndTB in the list, reset the timer interrupt
	; to what it was before we got here.
	; 
		tst	ax
		jnz	figureTicks
		
		mov	ax, ds:[tbOldTimer].offset
		mov	ss:[bp].state_timerInt.offset, ax
		mov	ax, ds:[tbOldTimer].segment
		mov	ss:[bp].state_timerInt.segment, ax

figureTicks:
	;
	; Now add the number of ticks accumulated. We also deal in partial
	; ticks, as you might expect, so this gets a bit weird.
	;
	; We've got the clock counter on entry to the stub, and the way it was
	; almost on exit from the stub when this breakpoint was set. A full
	; tick passed for the breakpoint each time the timer got to the same
	; count that's recorded in ETB_startCUs, but of course ETB_ticks got
	; upped partway through that cycle. Also the count decreases as time
	; wears on.
	;
	; Thus, when we subtract the starting clock counter from the current
	; one, if the result is negative, the timer has gone far enough that
	; we've upped ETB_ticks, but not far enough to actually make that
	; increase valid. In this case, we take the difference out of the
	; clock-units already recorded for the starting breakpoint.
	; 
		mov	bx, ds:[si].ETB_stb	; ds:bx <- associated TimeBreak
		mov	ax, ds:[ssTimerCount]
		sub	ax, ds:[si].ETB_startCUs
		js	subtractDiff		; => wrapped through a tick
	;
	; Made it through a full tick, so the difference in AX is the number
	; of clock units we are into the next tick, and we can proceed in
	; a fairly straight-forward fashion.
	; 
		add	ax, ds:[bx].TB_cus
		cmp	ax, GEOS_TIMER_VALUE	; now have a tick's worth of
						;  extra clock units?
		jb	addTicks		; nope -- just add the ticks
						;  from the ETB to the STB
		sub	ax, GEOS_TIMER_VALUE	; yes -- reduce extra units
						;  value by a tick
		inc	ds:[bx].TB_ticks.low	;  and up the STB's tick count
		jnz	addTicks		;  by the same amount
		inc	ds:[bx].TB_ticks.high
		jmp	addTicks

subtractDiff:
	;
	; Partial tick gone past. Reduce the extra ticks by the number remaining
	; until the full tick would have completed.
	; 
		add	ax, ds:[bx].TB_cus
		jns	addTicks		; => enough extra units in the
						;  STB to absorb the difference

		add	ax, GEOS_TIMER_VALUE	; standard multi-precision
		sub	ds:[si].ETB_ticks.low, 1;  arithmetic going on here
		jnc	addTicks
		dec	ds:[si].ETB_ticks.high
addTicks:
	;
	; ax = number of extra clock units for the starting breakpoint.
	;
	; add the number of accumulated ticks from the ETB into the STB
	; 
		mov	ds:[bx].TB_cus, ax
		mov	ax, ds:[si].ETB_ticks.low
		mov	cx, ds:[si].ETB_ticks.high
		tst	cx
		js	ticksAdjusted		; => timer is being funky,
						;  so don't adjust the tick
						;  count...
		add	ds:[bx].TB_ticks.low, ax
		adc	ds:[bx].TB_ticks.high, cx
ticksAdjusted:
	;
	; DX still holds the original bpt with which we were called. If it's not
	; the same as the head of the list, we want to free the head of the
	; list.
	; 
		cmp	si, dx
		je	timingStopped
		call	Bpt_Clear
		call	Bpt_Free

timingStopped:
	;
	; That's all there is to it. We return BCR_REMOVE_AND_FREE to Bpt_Check
	; so it can unlink our EndTB structure and free it.
	;
	; As for the non-ending case, we leave CX alone.
	; 
		mov	ax, BCR_REMOVE_AND_FREE
		pop	cx			; restore BCS
		jmp	done
TBEndHandler	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBTimerInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with a timer interrupt, adding one to the tick count
		for all EndTBs active for the current thread.

CALLED BY:	IRQ 0
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBTimerInt	proc	far
		uses	ax, ds, si
		.enter
		mov	ds, cs:[kdata]
		mov	si, cs:[currentThreadOff]
		mov	ax, ds:[si]
		PointDSAtStub
		mov	si, offset tbEndList - offset ETB_next
bptLoop:
		mov	si, ds:[si].ETB_next
		tst	si
		jz	done
		
		cmp	ds:[si].ETB_thread, ax
		jne	bptLoop
		
		inc	ds:[si].ETB_ticks.low
		jnz	bptLoop
		inc	ds:[si].ETB_ticks.high
		jmp	bptLoop

done:
		.leave
		jmp	cs:[tbOldTimer]
TBTimerInt	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TB_AdjustForOverhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust all active timing breakpoints that are for the
		current thread for the overhead incurred by the just-taken
		breakpoint and its presumed resumption.

CALLED BY:	Bpt_Check
PASS:		ss:bp	= StateBlock
		ds	= cgroup
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TB_AdjustForOverhead proc near
		uses	ax, bx, cx
		.enter
		mov	ax, ds:[tbOverhead]
		mov	cx, ss:[bp].state_thread
		mov	bx, offset tbEndList - offset ETB_next
bptLoop:
		mov	bx, ds:[bx].ETB_next
		tst	bx
		jz	done
	;
	; If bpt not for this thread, ignore it.
	; 
		cmp	ds:[bx].ETB_thread, cx
		jne	bptLoop
	;
	; Move the starting time forward by one overhead amount. If that
	; doesn't cause a wrap, then we're ok.
	; 
		sub	ds:[bx].ETB_startCUs, ax
		jns	bptLoop
	;
	; That wrapped, so wrap the starting time and reduce the number of
	; ticks recorded by one.
	; 
		add	ds:[bx].ETB_startCUs, GEOS_TIMER_VALUE
		sub	ds:[bx].ETB_ticks.low, 1
		jnc	bptLoop
		dec	ds:[bx].ETB_ticks.high
		jmp	bptLoop
done:
		.leave
		ret
TB_AdjustForOverhead endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TB_Calibrate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the overhead of timing breakpoints so we can
		calibrate our tick counts for the breakpoints themselves.

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
	set loop counter to TB_CALIBRATE_COUNT
	set set accumulated cus to 0
	set IRQCommon calibration vector appropriately
	save state
	
	basic loop:
		point state_ip to nop
		point ssResumeTimerCountPtr to tbCalResume
		restore state
		iret to:
			nop
			int 3
			IRQCommon:
			save state
			if calibrating, jump to calibrate_label
		calibrate_label:
		fetch ssTimerCount and subtract it from tbCalResume & normalize
		add to state_dx:state_ax
		reduce state_cx by 1
		jnz basic loop

	restore state
	clear ip, cs, flags from stack
	divide dx:ax by times through the loop & store quotient as overhead
		 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TB_Calibrate	proc	far
		.enter
if ALLOW_TIME_BREAK_POINT_CALIBRATING
	;
	; Initialize loop variables.
	; 
		clr	dx, ax		; dx:ax <- accumulated clock units (0)
		mov	cx, TB_CALIBRATE_COUNT	; cx <- loop counter
	;
	; Point IRQCommon to our current position and tell it we're calibrating
	; 
		ornf	ds:[sysFlags], mask calibrating
	;
	; Set up IRET frame for SaveState to use. Only the CS matters, as we
	; will be adjusting state_ip in the loop anyway.
	; 
		pushf
		push	cs
                push    ax
		call	SaveState

calibrateLoop:
	;
	; Set the state block up to resume at the nop right below, recording
	; the clock counter in tbOverhead when we restore the state, then return
	; to the nop.
	; 
		mov	ss:[bp].state_ip, offset bptInst
                push    ax
                mov     ax, cs
                mov     ss:[bp].state_cs, ax
                pop     ax
		mov	ds:[ssResumeTimerCountPtr], offset tbOverhead
		call	Bpt_Skip
		call	RestoreState
		iret
bptInst:
		nop
		int	3

TB_CalibrateLoop label near
	;
	; IRQCommon will jump here when it sees the calibrating flag set
	; in sysFlags...
	; 
		mov	ds:[bptInst], 0x90	; replace NOP...
		mov	ax, ds:[tbOverhead]
		sub	ax, ds:[ssTimerCount]
		jns	haveUnits		; => timer didn't wrap, so
						;  ax is the number units passed

		mov	ax, DEFAULT_TIMER_VALUE
		sub	ax, ds:[ssTimerCount]	; ax <- units after wrap
		add	ax, ds:[tbOverhead]	; + units passed before wrap
haveUnits:
	;
	; Add the number of units taken that time to that accumulating in
	; dx:ax during the loop (conveniently stored in the state block, of
	; course).
	; 
		add	ss:[bp].state_ax, ax
		adc	{word}ss:[bp].state_dx, 0
	;
	; Decrement the loop counter (also in the state block) and loop if
	; not done.
	; 
		dec	{word}ss:[bp].state_cx
		jnz	calibrateLoop
	;
	; Restore everything and clear the stack of the iret frame RestoreState
	; leaves there for us.
	; 
		call	RestoreState
		add	sp, size IRetFrame
	;
	; dx:ax = accumulated clock units.
	; 
		mov	cx, TB_CALIBRATE_COUNT
		div	cx
		mov	ds:[tbOverhead], ax
	;
	; No longer calibrating...
	; 
		andnf	ds:[sysFlags], not mask calibrating
else
TB_CalibrateLoop label near
                mov     ax, 0xA9                ; Value for a PII-400
                mov     ds:[tbOverhead], ax
endif
		.leave
		ret
TB_Calibrate	endp

scode	ends
