COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		msnetHooks.asm

AUTHOR:		Adam de Boor, Nov 21, 1992

ROUTINES:
	Name			Description
	----			-----------
	MSNetIdleHook		Let the network know the system is idle
	MSNetCriticalError	Catch network-related critical errors
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	11/21/92	Initial revision


DESCRIPTION:
	Interrupt hooks
		

	$Id: msnetHooks.asm,v 1.1 97/04/10 11:55:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetIdleHook
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Let the network know the system is idle.

CALLED BY:	int 28h
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/28/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNetIdleHook	proc	far
		push	bx, ax, ds
	;
	; Issue the i'm-idle-you-silly-network interrupt
	; 
		mov	ah, 84h
		int	2ah
	;
	; Fetch the old int 28h vector
	; 
		segmov	ds, dgroup, ax
		mov	bx, offset msnetOldInt28
		jmp	MSNetPassOnInterrupt
MSNetIdleHook	endp


COMMENT @-----------------------------------------------------------------------

FUNCTION:	MSNetCriticalError

DESCRIPTION:	Handle critical error from network

CALLED BY:	EXTERNAL
		INT 24h

PASS:
	ah - bit 7: 0 if disk error, otherwise 1
	bp:si - address of device header control block
	di - lower byte - error code
	
	on stack:
		iret frame to caller of DOS
		es
		ds
		bp
		di
		si
		dx
		cx
		bx
		ax
		iret frame from "int 24h"	<- sp


RETURN:
	al - action code:
		0 - ignore error
		1 - retry operation
		2 - terminate program through INT 23h
		3 - Fail system call in progress

DESTROYED:
	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/92		Initial version
-------------------------------------------------------------------------------@
MSNetCriticalError	proc	far
		push	bx, ax, ds
		call	LoadVarSegDS

		cmp	di, CriticalErrors
		jae	itsOurs
		mov	bx, offset msnetOldInt24
		jmp	MSNetPassOnInterrupt

itsOurs:
	;
	; Anything critical enough, we just fail the thing with the proper
	; error code and rely on the caller of the function to put up something
	; that looks nice.
	; 
		mov	ax, di
		add	ax, ERROR_WRITE_PROTECTED
		mov	bx, 1		; return carry set (primary driver will
					;  get extended error info, even on an
					;  FCB call, so...)
		call	FSDRecordError
		pop	bx, ax, ds
		mov	al, CR_FAIL
		iret
MSNetCriticalError	endp

Resident	ends
		
