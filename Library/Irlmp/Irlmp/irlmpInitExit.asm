COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1995 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		irlmpInitExit.asm

AUTHOR:		Adam de Boor, Jun  6, 1995

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 6/95		Initial revision


DESCRIPTION:
	Functions for initialization/exit
		

	$Id: irlmpInitExit.asm,v 1.1 97/04/05 01:07:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpAllocRegisterSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a semaphore to gain exclusive access to creating
		the server thread.

CALLED BY:	(EXTERNAL) IrlmpLibraryEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	irlmpRegisterSem set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpAllocRegisterSem proc	far
		uses	ax, bx, ds
		.enter
		mov	bx, 1
		call	ThreadAllocSem
		mov	ax, handle 0
		call	HandleModifyOwner
		call	UtilsLoadDGroupDS
		mov	ds:[irlmpRegisterSem], bx
		.leave
		ret
IrlmpAllocRegisterSem endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IrlmpFreeRegisterSem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the semaphore that controls creating the server thread

CALLED BY:	(EXTERNAL) IrlmpLibraryEntry
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	semaphore freed, but irlmpRegisterSem remains non-z

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 6/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IrlmpFreeRegisterSem proc	far
		uses	ds, bx
		.enter
		call	UtilsLoadDGroupDS
		mov	bx, ds:[irlmpRegisterSem]
		call	ThreadFreeSem
		.leave
		ret
IrlmpFreeRegisterSem endp

InitCode	ends
