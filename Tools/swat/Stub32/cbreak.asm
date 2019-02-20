COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Stub -- Conditional Breakpoints
FILE:		cbreak.asm

AUTHOR:		Adam de Boor, May 12, 1989

ROUTINES:
	Name			Description
	----			-----------
    EXT CBreak_Set		Set a conditional breakpoint

    EXT CBreak_Clear		Clear a conditional breakpoint at an
				address

    EXT CBreak_Change		Change the criteria for a breakpoint

    INT CBreakHandler		Handle a conditional breakpoint

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	5/12/89		Initial revision


DESCRIPTION:
	Conditional breakpoints.
		
	These breakpoints are implemented as an array of CBreakArgs
	structures, containing an array of values and operators by
	which the values should be compared to their respective registers.

	The operators themselves are the low four bits for the conditional
	branches that should be taken after the comparison if the breakpoint
	shouldn't be taken.

	Conditional breakpoints are set at absolute memory locations -- Swat
	is responsible for telling us when the block in question moves.

	$Id: cbreak.asm,v 2.7 94/06/03 18:36:18 jimmy Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		include	stub.def

CBreakData	struct
    CBD_bpt		BptClient	; stuff common to all bpts
    CBD_criteria	CBreakArgs	; when we should stop
CBreakData	ends

scode		segment
		assume	cs:scode,ds:cgroup,es:cgroup,ss:sstack


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CBreak_Set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a conditional breakpoint

CALLED BY:	Rpc_Wait (RPC_CBREAK)
PASS:		rpc_LastCall.RMB_data	= a CBreakArgs
RETURN:		Nothing or RPC_TOOBIG if no open slots.
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CBreak_Set	proc	near
	;
	; Allocate room for a CBreakData structure
	; 
		mov	cx, size CBreakData
		call	Bpt_Alloc
		mov	ax, RPC_TOOBIG
		tst	si
		jz	tooBig
	;
	; Initialize the CBreakData with our own internal stuff and copying
	; in the criteria from the host.
	; 
		mov	ds:[si].CBD_bpt.BC_handler, offset CBreakHandler
		mov	ds:[si].CBD_bpt.BC_flags, 0

		push	si
		lea	di, ds:[si].CBD_criteria
		mov	si, offset rpc_LastCall.RMB_data
		mov	cx, size CBreakArgs/2
		rep	movsw
if (size CBreakArgs) and 1
		movsb
endif
		pop	bx
	;
	; Now set the breakpoint itself, passing the cs:ip and the original
	; instruction.
	; 
		mov	cx, ds:[bx].CBD_criteria.cb_cs
		mov	dx, ds:[bx].CBD_criteria.cb_ip
		mov	ax, ds:[bx].CBD_criteria.cb_xipPage
		call	Bpt_Set
		tst	si
		jz	tooBigFreeCBD
	;
	; Return the offset of the CBreakData as the breakpoint number.
	; 
		mov	{word}ds:[rpc_ToHost], bx
		mov	cx, size word
		mov	si, offset rpc_ToHost
		call	Rpc_Reply
		ret

tooBigFreeCBD:
		mov	si, bx
		call	Bpt_Free
tooBig:
		call	Rpc_Error
		ret
CBreak_Set	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CBreak_Clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear a conditional breakpoint at an address

CALLED BY:	Rpc_Wait (RPC_NOCBREAK)
PASS:		rpc_LastCall.RMB_data	= breakpoint # to clear
RETURN:		Nothing
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		Store 0 in the cb_cs field to indicate the thing's free.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CBreak_Clear	proc	near
	;
	; Clear the attached breakpoint first.
	; 
		mov	si, {word}ds:[rpc_LastCall].RMB_data
		call	Bpt_Clear
	;
	; Then free the CBreakData itself.
	; 
		call	Bpt_Free
	;
	; Return a null reply.
	; 
		clr	cx		; Clear for reply and freeing
		call	Rpc_Reply	; Send null reply
		ret			; Done
CBreak_Clear	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CBreak_Change
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the criteria for a breakpoint

CALLED BY:	Rpc_Wait (RPC_CHGCBREAK)
PASS:		rpc_LastCall.RMB_data	= ChangeCBreakArgs structure
RETURN:		Nothing
DESTROYED:	...

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CBreak_Change	proc	near
		mov	di, ({ChangeCBreakArgs}CALLDATA).ccba_num
	;
	; Copy new criteria in.
	;
		lea	si, ({ChangeCBreakArgs}rpc_LastCall.RMB_data).ccba_crit
		add	di, offset CBD_criteria
		mov	cx, size CBreakArgs / 2
		rep	movsw
		
		clr	cx		; Clear CX for null reply
		call	Rpc_Reply	; Reply
		ret			; Done
CBreak_Change	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CBreakHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a conditional breakpoint

CALLED BY:	Bpt_Check
PASS:		rpc_ToHost 	= HaltArgs
		[BP]		= current state
		cx		= BptCallStatus
		ds:si		= CBreakData
		Interrupts off
RETURN:		cx		= new BptCallStatus
		ax		= BptCallResult (always BCR_OK for now)
DESTROYED:	Many things

PSEUDO CODE/STRATEGY:
		Look through all the conditional breakpoints for ones at
		CS:IP. Three possibilities:
			1) no breakpoint at CS:IP: just return and let
			   Swat deal with it.
			2) a breakpoint at CS:IP whose criteria match the
			   current state of affairs: return so Swat can
			   stop if it wants to.
			3) a breakpoint at CS:IP whose criteria don't match:
			   skip the breakpoint.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CBreakHandler	proc	near
		assume	ss:sstack, cs:scode, ds:cgroup
	;
	; See if the stop criteria have been met. Loop variables:
	;	CX	number of words left to check
	;	BX	address of comparison nibbles
	;	SI	current word in CBreak record
	;	DI	current word in HaltArgs record
	;	AX	trashed forming branch instruction.
	;
		push	cx
		lea	si, ds:[si].CBD_criteria.cb_comps
		mov	bx, si		; BX points to the current comparison
					; byte.
		add	si, cb_thread-cb_comps	; Point to cb_thread
		mov	di, offset rpc_ToHost	; Point DI at HaltArgs
		mov	cx, REG_NUM_REGS+1	; Setup compare count 
wordLoop:
	;
	; Need to figure out which nibble of the comparison byte we
	; need and make sure it's in AL. Since CX starts out odd, we
	; choose the low nibble if bit 0 of CX is non-zero.
	;
		mov	al, [bx]	; Fetch comparison byte
		test	cl, 1
		jnz	checkCompare
		shr	al, 1		; Need to shift the top nibble down...
		shr	al, 1
		shr	al, 1
		shr	al, 1
		inc	bx		;  and point to next byte while we're
					;  at it.
checkCompare:
		and	al, 0fh		; Trim off the high nibble.
		jz	skipWord	; 0 => value uninteresting
		or	al, 70h		; Form branch opcode
		mov	ds:[HCBJump], al;  and store it
		cmpsw			; Compare the words
		jmp	short HCBJump	; Clear out prefetch queue
HCBJump:
		jne	mismatch	; THIS INSTRUCTION IS MODIFIED TO BE
					; THE ONE FOR THE CURRENT VALUE. A
					; branch taken implies a mismatch.
		jcxz	match		; Jump is here to handle memory compare.
		loop	wordLoop
	;
	; See if memory check required. First load ES:DI with potential
	; memory address, then see if comparison nibble (in high
	; nibble of [bx]) is non-zero, indicating a memory compare
	; is required
	;
checkMem:
		les	di, dword ptr ds:[si-cb_value].cb_off
		test	byte ptr [bx], 0f0h
		jnz	wordLoop	; Yes -- go do the compare. [bx]
					;  points to the operator, es:[di] to
					;  the word to be checked, and
					;  ds:[si] to the value against which
					;  it is to be compared, since it
					;  points past cb_regs. CX is 0, so if
					;  we match, the jcxz will take
					;  us down the HCBMatch before we loop
					;  forever.
match:
	;
	; Met all the criteria -- take the thing,
	;
		pop	cx		; restore BptCallStatus
		ornf	cx, mask BCS_CONDITION_SATISFIED or mask BCS_TAKE_IT
done:
		andnf	cx, not mask BCS_UNCONDITIONAL
		PointESAtStub	; Restore ES after thrashing by LES,
					;  above.
		mov	ax, BCR_OK
		ret
skipWord:
	;
	; Word unimportant -- advance to next
	;
		inc	si
		inc	si
		inc	di
		inc	di
		loop	wordLoop
	;
	; Got to the end without jumping to HCBMismatch -- must have
	; met all the criteria.
	;
		jmp	checkMem
mismatch:
		pop	cx
		jmp	done
CBreakHandler	endp

scode		ends
		end
