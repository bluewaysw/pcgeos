COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		break.asm

AUTHOR:		Adam de Boor, Apr 20, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/20/92		Initial revision


DESCRIPTION:
	Unconditional-breakpoint support
		

	$Id: break.asm,v 1.4 95/11/02 19:01:58 adam Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		include	stub.def

scode		segment
		assume	cs:scode,ds:cgroup,es:cgroup,ss:sstack



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Break_Set
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set an unconditional breakpoint

CALLED BY:	RPC_SETBREAK
PASS:		rpc_LastCall.RMB_data	= SetBreakArgs
RETURN:		breakpoint number
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Break_Set	proc	near
		.enter
		mov	cx, size BptClient
		call	Bpt_Alloc
		mov	al, RPC_TOOBIG
		tst	si
		jz	noRoom
		
		mov	ds:[si].BC_handler, offset BreakHandler
		mov	ds:[si].BC_flags, 0
		
		mov	cx, ({SetBreakArgs}CALLDATA).sba_cs
		mov	dx, ({SetBreakArgs}CALLDATA).sba_ip

		DPC	DEBUG_FALK2, 'r'
		DPW	DEBUG_FALK2, cx
		DPW	DEBUG_FALK2, dx

		mov	ax, ({SetBreakArgs}CALLDATA).sba_xip

		mov	bx, si		; bx <- client data
		call	Bpt_Set
		tst	si
		jz	noRoomFreeClient
		
	DPC	DEBUG_BPT, 'i'
	DPW	DEBUG_BPT, es
	DPW	DEBUG_BPT, ds
	DA	DEBUG_BPT, <push ds, bx>
	DA	DEBUG_BPT, <lds bx, ds:[si].BD_addr>
	DPW	DEBUG_BPT, ds:[bx]
	DA	DEBUG_BPT, <pop ds, bx>
	DA	DEBUG_BPT, <push si>
		mov	{word}ds:[rpc_ToHost], bx
		mov	cx, size word
		mov	si, offset rpc_ToHost
		call	Rpc_Reply

	DA	DEBUG_BPT, <pop si>
	DPC	DEBUG_BPT, 'I'
	DPW	DEBUG_BPT, es
	DPW	DEBUG_BPT, ds
	DA	DEBUG_BPT, <push ds>
	DA	DEBUG_BPT, <lds bx, ds:[si].BD_addr>
	DPW	DEBUG_BPT, ds:[bx]
	DA	DEBUG_BPT, <pop ds>

done:
		.leave
		ret

noRoomFreeClient:
		mov	si, bx
		call	Bpt_Free
noRoom:
		call	Rpc_Error
		jmp	done
Break_Set	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Break_Clear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear an unconditional breakpoint

CALLED BY:	RPC_CLEARBREAK
PASS:		breakpoint number
RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Break_Clear	proc	near
		.enter
		mov	si, {word}ds:[rpc_LastCall].RMB_data
		call	Bpt_Clear
		call	Bpt_Free
		
	;
	; Send appropriate zero-length reply
	;
		clr	cx
		call	Rpc_Reply
		.leave
		ret
Break_Clear	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BreakHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle an unconditional breakpoint

CALLED BY:	Bpt_Check
PASS:		ds:si	= BptClient
		cx	= BptCallStatus
RETURN:		cx	= new BptCallStatus
		ax	= BptCallResult (BCR_OK)
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BreakHandler	proc	near
		.enter
		mov	cx, mask BCS_TAKE_IT or mask BCS_UNCONDITIONAL
		mov	ax, BCR_OK
		.leave
		ret
BreakHandler	endp

scode		ends
