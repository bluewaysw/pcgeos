COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		utilsResident.asm

AUTHOR:		Adam de Boor, Jun  1, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 1/94		Initial revision


DESCRIPTION:
	Utility routines that are resident b/c they're used so much
		

	$Id: utilsResident.asm,v 1.1 97/04/05 01:19:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilVMDirtyDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the block pointed to by DS as dirty.

CALLED BY:	(INTERNAL)
PASS:		ds	= locked VM block with handle as first word
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilVMDirtyDS	proc	far
		uses	bp
		.enter
		pushf
		mov	bp, ds:[LMBH_handle]
		call	VMDirty
		popf
		.leave
		ret
UtilVMDirtyDS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilVMUnlockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	VMUnlock the block pointed to by DS.

CALLED BY:	(INTERNAL)
PASS:		ds	= locked VM block with handle as first word
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilVMUnlockDS	proc	far
		uses	bp
		.enter
		mov	bp, ds:[LMBH_handle]
		call	VMUnlock
		.leave
		ret
UtilVMUnlockDS	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilUnlockDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the memory block pointed to by DS.

CALLED BY:	(INTERNAL)
PASS:		ds	= locked block with handle at first word
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	guess

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 6/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilUnlockDS	proc	far
		uses	bx
		.enter
		mov	bx, ds:[LMBH_handle]
		call	MemUnlock
		.leave
		ret
UtilUnlockDS	endp

Resident	ends
