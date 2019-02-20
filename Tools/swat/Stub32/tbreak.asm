COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Stub -- Tally Breakpoints
FILE:		tbreak.asm

AUTHOR:		Adam de Boor, June 24, 1990

ROUTINES:
	Name			Description
	----			-----------
	HandleTBreak		Handle the hitting of a tally breakpoint

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/24/90		Initial revision


DESCRIPTION:
	Tally breakpoints. These breakpoints are intended for performance
	monitoring. When hit, they simply increment a counter and continue
	the machine. The counter can be read and reset by Swat whenever
	necessary. A conditional breakpoint can be used as a filter for a
	tally breakpoint, as conditionals are checked first.
	
	Tally breakpoints are set at absolute locations. Swat is responsible
	for changing the stored address if the block in question moves.
		
	$Id: tbreak.asm,v 1.6 94/04/29 17:09:29 jimmy Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		include	stub.def

scode		segment
		assume	cs:scode,ds:cgroup,es:cgroup,ss:sstack

TBreakData	struct
    TBD_bpt	BptClient	; common stuff
    TBD_count	dword		; number of times it's been hit.
TBreakData	ends



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBreak_Set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a tally breakpoint.

CALLED BY:	RPC_SETTBREAK
PASS:		SetTBreakArgs in rpc_LastCall.RMB_data
RETURN:		SetTBreakReply in rpc_ToHost
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBreak_Set	proc	near
		.enter
	;
	; Allocate a TBreakData record first.
	; 
		mov	cx, size TBreakData
		call	Bpt_Alloc
		tst	si
		jz	noRoom
	;
	; Initialize it appropriately
	; 
		mov	ds:[si].TBD_bpt.BC_handler, offset TBreakHandler
		clr	ax
		mov	ds:[si].TBD_bpt.BC_flags, al
		mov	ds:[si].TBD_count.low, ax
		mov	ds:[si].TBD_count.high, ax
	;
	; Now set the breakpoint itself. We don't know what the instruction
	; is supposed to be...
	; 
		mov	cx, ({SetTBreakArgs}CALLDATA).stba_cs
		mov	dx, ({SetTBreakArgs}CALLDATA).stba_ip
		mov	bx, si		; bx <- client data
		mov	ax, -1		; non XIP
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

noRoomFreeClient:
		mov	si, bx
		call	Bpt_Free
noRoom:
		mov	al, RPC_TOOBIG
		call	Rpc_Error
		jmp	done
TBreak_Set	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBreak_GetCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the current count for the given breakpoint

CALLED BY:	RPC_GETTBREAK
PASS:		CALLDATA holds offset of TBreakData
RETURN:		current count (dword)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBreak_GetCount	proc	near
		.enter
		mov	si, {word}ds:[rpc_LastCall].RMB_data
		add	si, offset TBD_count
		mov	cx, size TBD_count
		call	Rpc_Reply
		.leave
		ret
TBreak_GetCount	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBreak_ZeroCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Zero the count for a tally breakpoint

CALLED BY:	RPC_ZEROTBREAK
PASS:		CALLDATA holds offset of TBreakData
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBreak_ZeroCount proc	near
		.enter
		mov	si, {word}CALLDATA
		clr	cx		; zero for storing & for reply length
		mov	ds:[si].TBD_count.low, cx
		mov	ds:[si].TBD_count.high, cx
		call	Rpc_Reply
		.leave
		ret
TBreak_ZeroCount endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBreak_Clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a tally breakpoint.

CALLED BY:	RPC_CLEARTBREAK
PASS:		CALLDATA holds offset of TBreakData
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBreak_Clear	proc	near
		.enter
	;
	; Clear the breakpoint first.
	; 
		mov	si, {word}ds:[rpc_LastCall].RMB_data
		call	Bpt_Clear
	;
	; Now free the TBreakData record.
	; 
		call	Bpt_Free
		
		clr	cx
		call	Rpc_Reply
		.leave
		ret
TBreak_Clear	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TBreakHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a tally breakpoint

CALLED BY:	Bpt_Check
PASS:		ds:si	= TBreakData
		cx	= BptCallStatus
		Interrupts off
RETURN:		cx	= new BptCallStatus
		ax	= BptCallResult (BCR_OK)
DESTROYED:	Many things

PSEUDO CODE/STRATEGY:
		If BCS_UNCONDITIONAL:
			up the tally by one, leaving BCS_TAKE_IT
			alone (assumes that regular breakpoint overrides
			tally breakpoint)
		else if BCS_CONDITION_SATISFIED:
			up the tally and clear BCS_TAKE_IT, on the assumption
			that the conditional breakpoint is the condition
			for us...
		
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TBreakHandler	proc	near
		assume	ss:sstack, cs:scode, ds:cgroup
		.enter

		test	cx, mask BCS_UNCONDITIONAL
		jnz	upTally		; unconditional, so always up tally
		
		test	cx, mask BCS_CONDITION_SATISFIED
		jz	done		; conditional & not matched

		andnf	cx, not mask BCS_TAKE_IT; assume condition meant for
						;  us and clear the take-it
						;  flag
upTally:
		inc	ds:[si].TBD_count.low
		jnz	done		; => no wrap
		inc	ds:[si].TBD_count.high
done:
		mov	ax, BCR_OK
		.leave
		ret
TBreakHandler	endp

scode		ends
		end
