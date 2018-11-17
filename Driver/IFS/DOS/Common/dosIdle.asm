COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	DOS Filesystem Drivers
MODULE:		Idle Time Hooks
FILE:		dosIdle.asm

AUTHOR:		Adam de Boor, Oct 28, 1992

ROUTINES:
	Name			Description
	----			-----------
    EXT	DOSIdleInit
    EXT	DOSIdleExit
    INT	DOSIdleHook
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/28/92	Initial revision


DESCRIPTION:
	Idle-time hook to keep DOS and TSRs happy
		

	$Id: dosIdle.asm,v 1.1 97/04/10 11:55:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSIdleInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize our idle-time hook

CALLED BY:	(EXTERNAL)
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSIdleInit	proc	near
		uses	ax, dx
		.enter
		mov	ax, SGIT_BIOS_LOCK
		call	SysGetInfo
		mov	ds:[dosBiosLock].segment, dx
		mov	ds:[dosBiosLock].offset, ax
		
		mov	dx, segment DOSIdleHook
		mov	ax, offset DOSIdleHook
		call	SysAddIdleIntercept
		.leave
		ret
DOSIdleInit	endp

Init		ends

if FULL_EXECUTE_IN_PLACE
ResidentXIP	segment resource
else
Resident	segment	resource
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSIdleExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove our idle-time hook

CALLED BY:	(EXTERNAL)
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax,dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _FXIP
DOSIdleExit	proc	far
else
DOSIdleExit	proc	near
endif
		.enter
		mov	dx, cs
		mov	ax, offset @CurSeg:DOSIdleHook
		call	SysRemoveIdleIntercept
		.leave
		ret
DOSIdleExit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSIdleHook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let DOS and TSRs know we're idle

CALLED BY:	kernel
PASS:		nothing
RETURN:		nothing
DESTROYED:	ax, bx
		(ax, bx, dx, si, bp allowed)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSIdleHook	proc	far
		uses	ds
		.enter
	;
	; So long as no one's currently in BIOS or DOS, we can safely issue
	; an int 28h here. We don't have to worry about grabbing the BIOS lock
	; or calling SysEnterCritical, as the system won't context-switch away
	; during the call, owing to our being on the scheduler thread.
	; 
		segmov	ds, dgroup, bx
		lds	bx, ds:[dosBiosLock]
		tst	ds:[bx].TL_sem.Sem_value
		jle	done
		int	28h
		
		mov	ax, 1680h
		int	2fh	; new interrupt used by MS5 (why did they need
				;  a new one?) and Windows (aha!)
done:
		.leave
		ret
DOSIdleHook	endp

if FULL_EXECUTE_IN_PLACE
ResidentXIP	ends
else
Resident	ends
endif
