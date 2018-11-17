COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pgfsEntry.asm

AUTHOR:		Adam de Boor, Sep 29, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/29/93		Initial revision


DESCRIPTION:
	The three entry points for this driver.
		

	$Id: pgfsEntry.asm,v 1.1 97/04/18 11:46:36 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSPStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for supporting PCMCIA driver functions

CALLED BY:	GLOBAL
PASS:		di	= PCMCIAFunction
RETURN:		varies
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DefPFunction	macro	routine, constant
.assert ($-pfuncs) eq constant*2, <Routine for constant in the wrong slot>
.assert (type routine eq far), <routine should be far>
		fptr	routine
		endm

pfuncs		label	fptr.far
DefPFunction PGFSEInit,			DR_INIT
DefPFunction PGFSEExit,			DR_EXIT
	; These next two should unregister & register, should they ever be
	; needed...
DefPFunction PGFSEDoNothing,			DR_SUSPEND
DefPFunction PGFSEDoNothing,			DR_UNSUSPEND
DefPFunction PGFSICheckSocket,			DR_PCMCIA_CHECK_SOCKET
DefPFunction PGFSRObjectionResolved,		DR_PCMCIA_OBJECTION_RESOLVED
DefPFunction PGFSRCloseSocket,			DR_PCMCIA_CLOSE_SOCKET
DefPFunction PGFSEDoNothing,			DR_PCMCIA_DEVICE_ON
DefPFunction PGFSEDoNothing,			DR_PCMCIA_DEVICE_OFF
	.assert ($-pfuncs) eq PCMCIAFunction*2

PGFSPStrategy	proc	far
		uses	ds, es
		.enter
		segmov	ds, dgroup, ax
		HandleFarEscape pgfs, done

		mov	ss:[TPD_dataBX], bx
		mov	es, ax
		shl	di
		movdw	bxax, cs:[pfuncs][di]
		call	ProcCallFixedOrMovable
done:
		.leave
		ret
PGFSPStrategy	endp

PGFSEDoNothing	proc	far
		clc
		ret
PGFSEDoNothing	endp

Init	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSEInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we can actually function.

CALLED BY:	DR_INIT
PASS:		ds, es 	= dgroup
RETURN:		carry set on error
DESTROYED:	ax, bx, cx, dx, ds, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSEInit 	proc	far
		.enter
	;
	; See if the primary FSD has been loaded yet and ensure its
	; aux protocol number is compatible.
	; 
		call	PCMCIAGetPrimaryIFSStrat
		jc	fail
		
		movdw	ds:[gfsPrimaryStrat], bxax
	;
	; Fetch the power-management driver's strategy.
	; 
		mov	ax, GDDT_POWER_MANAGEMENT
		call	GeodeGetDefaultDriver
		tst	ax
		jz	doRegistration
		push	ds
		mov_tr	bx, ax
		call	GeodeInfoDriver
		movdw	bxax, ds:[si].DIS_strategy
		pop	ds
		movdw	ds:[powerStrat], bxax
doRegistration:
	;
	; Register as a card-services client.
	; 
		mov	di, segment PGFSCardServicesCallback
		mov	si, offset PGFSCardServicesCallback
		mov	cx, size regArgList
		segmov	es, cs, ax
		mov	bx, offset regArgList
		CallCS	CSF_REGISTER_CLIENT
		jc	fail

		mov	ds:[csHandle], CS_HANDLE_REG
	;
	; Register ourselves as a filesystem driver.
	; 
		mov	cx, segment GFSStrategy
		mov	dx, offset GFSStrategy
		mov	bx, handle 0
		clr	di		; no private data
		mov	ax, FSD_FLAGS
		call	FSDRegister
		
		mov	ds:[gfsFSD], dx
		clc
done:
		.leave
		ret
fail:
		stc
		jmp	done
PGFSEInit 	endp

regArgList	CSRegisterClientArgs <
	mask CSRCAA_ARTIFICIAL_EXCLUSIVE or mask CSRCAA_ARTIFICIAL_SHARED or \
	    mask CSRCAA_MCD,
	mask CSEM_CARD_DETECT_CHANGE,
	< 0, segment dgroup, 0, 0>,
	0201h
>
Init	ends




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSEExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up after ourselves

CALLED BY:	DR_EXIT
PASS:		ds	= dgroup (from strategy routine)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	driver unregistered as FSD and as card services client

PSEUDO CODE/STRATEGY:
		XXX: should probably check for error from FSDUnregister and
		make sure we've deleted any drives...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/ 4/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSEExit	proc	far
		uses	ax, dx, bx
		.enter
		
		clr	bx
		xchg	ds:[restartTimer], bx
		tst	bx
		jz	unregFSD
		mov	ax, ds:[restartTimerID]
		call	TimerStop

unregFSD:
		mov	dx, ds:[gfsFSD]
		call	FSDUnregister

	;
	; Release any windows we allocated from Card Services
	;
		mov	cx, PGFS_MAX_SOCKETS
		mov	bx, offset socketInfo
releaseLoop:
		test	ds:[bx].PGFSSI_flags, mask PSF_WINDOW_ALLOCATED
		jz	releaseNext

		andnf	ds:[bx].PGFSSI_flags, not mask PSF_WINDOW_ALLOCATED
		mov	dx, ds:[bx].PGFSSI_window
		call	SysLockBIOS
		call	PGFSReleaseWindow
		call	SysUnlockBIOS
releaseNext:
		add	bx, size PGFSSocketInfo
		loop	releaseLoop
		

		
		mov	dx, ds:[csHandle]
		CallCS	CSF_DEREGISTER_CLIENT
		
		clc
		.leave
		ret
PGFSEExit	endp

Resident	ends
