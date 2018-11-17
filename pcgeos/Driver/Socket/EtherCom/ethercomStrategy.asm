COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Tedious Endeavors 1998 -- All Rights Reserved

PROJECT:	Native ethernet support
MODULE:		Ethernet link driver
FILE:		ethercomStrategy.asm

AUTHOR:		Todd Stumpf, July 8th, 1998

ROUTINES:

    INT EtherStrategy        Strategy routine
    INT EtherInit            Strategy routine
    INT EtherExit            Strategy routine
    INT EtherDoNothing       Do nothing

DESCRIPTION:

	Routines common to all ethernet link drivers

	$Id:$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ResidentCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine

CALLED BY:	GLOBAL

PASS:		di -> DR_SOCKET_* funciton to call
RETURN:		variable
DESTROYED:	variable
SIDE EFFECTS:	variable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/8/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherStrategy	proc	far
		.enter
	;
	;  See if the function is fixed, or movable, knowing that
	;  all movable segments are stored as virtual segments.
		shl	di, 1
		cmp	cs:[EtherFunctions][di].segment, MAX_SEGMENT
		jae	movable	; => virtual segment

		call	{fptr.far}cs:[EtherFunctions][di]
done:
		.leave
		ret
movable:
	;
	; We've got a vfptr to the routine, so use the canned
	; kernel routines to transform it to a call...
		pushdw	cs:[EtherFunctions][di]
		call	PROCCALLFIXEDORMOVABLE_PASCAL
		jmp	done

EtherStrategy	endp

	DefEtherFunction	macro	routine, cnst
		.assert ($-EtherFunctions) eq cnst*2, <function table is corrupted>
		.assert (type routine eq far)
                fptr.far        routine
	endm

EtherFunctions	label	fptr.far
	DefEtherFunction EtherInit,			DR_INIT
	DefEtherFunction EtherExit,			DR_EXIT
	DefEtherFunction EtherDoNothing,		DR_SUSPEND
	DefEtherFunction EtherDoNothing,		DR_UNSUSPEND
	DefEtherFunction EtherClientRegister,		DR_SOCKET_REGISTER
	DefEtherFunction EtherClientUnregister,		DR_SOCKET_UNREGISTER
	DefEtherFunction EtherAllocConnect,		DR_SOCKET_ALLOC_CONNECTION
	DefEtherFunction EtherLinkConnect,		DR_SOCKET_LINK_CONNECT_REQUEST
	DefEtherFunction EtherUnsupported,		DR_SOCKET_DATA_CONNECT_REQUEST
	DefEtherFunction EtherUnsupported,		DR_SOCKET_STOP_LINK_CONNECT
	DefEtherFunction EtherDisconnect,		DR_SOCKET_DISCONNECT_REQUEST
	DefEtherFunction EtherSendData,			DR_SOCKET_SEND_DATA
	DefEtherFunction EtherAbortSendData,		DR_SOCKET_STOP_SEND_DATA
	DefEtherFunction EtherSendDatagram,		DR_SOCKET_SEND_DATAGRAM
	DefEtherFunction EtherReset,			DR_SOCKET_RESET_REQUEST
	DefEtherFunction EtherUnsupported,		DR_SOCKET_ATTACH
	DefEtherFunction EtherUnsupported,		DR_SOCKET_REJECT
	DefEtherFunction EtherGetInfo,			DR_SOCKET_GET_INFO
	DefEtherFunction EtherSetOption,		DR_SOCKET_SET_OPTION
	DefEtherFunction EtherGetOption,		DR_SOCKET_GET_OPTION
	DefEtherFunction EtherResolveAddr,		DR_SOCKET_RESOLVE_ADDR
	DefEtherFunction EtherStopResolveAddr,		DR_SOCKET_STOP_RESOLVE
	DefEtherFunction EtherCloseMedium,		DR_SOCKET_CLOSE_MEDIUM
	DefEtherFunction EtherConnectMediumRequest,	DR_SOCKET_MEDIUM_CONNECT_REQUEST
	DefEtherFunction EtherActivateMedium		DR_SOCKET_MEDIUM_ACTIVATED
	DefEtherFunction EtherSetMediumOption		DR_SOCKET_SET_MEDIUM_OPTION
	DefEtherFunction EtherDoArpLookup		DR_SOCKET_RESOLVE_LINK_LEVEL_ADDRESS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do nothing		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherUnsupported
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return carry

CALLED BY:	Indicate unsupported function call

PASS:		nothing
RETURN:		carry set
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherUnsupported	proc	far
		stc
EtherDoNothing	label	far
		ret
EtherUnsupported	endp

ResidentCode	ends

InitCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	DR_INIT

PASS:		nothing
RETURN:		CF set on error
DESTROYED:	ax, cx, dx, si, di, bp, ds, es

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherInit	proc	far
		uses	bx
		.enter

	;
	; Create HugeLMem for incoming packets.  Must be done before hooking
	; up to hardware.
	;
		clr	ax		; default max # of mem blocks
		mov	bx, MIN_OPTIMAL_BLOCK_SIZE
		mov	cx, MAX_OPTIMAL_BLOCK_SIZE
		call	HugeLMemCreate	; bx = HugeLMem handle, CF on error
		jc	exit
		GetDGroup	ds, ax
		mov	ds:[recvHugeLMem], bx

	;
	; Device-specific init.
	;
		EthDevInit		; CF on error
		jnc	exit		; => done

	;
	; Device error.  Free HugeLMem
	;
		call	HugeLMemDestroy
		stc

exit:
		.leave
		ret
EtherInit	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EtherExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

CALLED BY:	DR_EXIT

PASS:		nothing
RETURN:		nothing
DESTROYED:	everything except bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	TDS	7/28/98    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EtherExit	proc	far

		EthDevExit

		GetDGroup	ds, ax
		mov	bx, ds:[recvHugeLMem]
		call	HugeLMemDestroy

		ret
EtherExit	endp

InitCode	ends
