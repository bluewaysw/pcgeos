COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		fsdUtils.asm

AUTHOR:		Adam de Boor, Jul 25, 1991

ROUTINES:
	Name			Description
	----			-----------
   RGLB FSDLockInfoExcl		Lock the FSInfoResource for exclusive
				access

   RGLB FSDLockInfoShared	Lock the FSInfoResource for shared access

   RGLB FSDUnlockInfoShared	Release shared lock on FSIR

   RGLB FSDUnlockInfoExcl	Release exclusive lock on FSIR

    INT FSDLockInfoExclToES	Lock the FSInfoResource for exclusive
				access, storing its segment in ES

    GLB FSDUpgradeSharedInfoLock Upgrade a shared lock on the FSIR to an
				exclusive one

    GLB FSDDowngradeExclInfoLock Downgrade an exclusive lock on the FSIR to
				a shared one

   RGLB FSDDerefInfo		The current thread already has the FSIR
				locked somehow, but has misplaced the
				segment, so return it.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	7/25/91		Initial revision


DESCRIPTION:
	General-purpose utility functions.
		

	$Id: fsdUtils.asm,v 1.1 97/04/05 01:17:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FSResident	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDLockInfoExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the FSInfoResource for exclusive access

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		ax	= segment of FSInfoResource locked for exclusive
			  access
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE: this routine is coded so as to keep the count of
		locks for this thread on the block non-zero during the call
		to MemLockExcl, to avoid recursion and internal deadlock
		in case ec +segment is turned on when that code calls PHeap
		in SegmentToHandle.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDLockInfoExcl	proc	far
		uses	bx
		.enter
	;
	; Note an(other) excl lock on the FSIR by this thread. Done first to
	; avoid recursion in PHeap
	; 
		inc	ss:[TPD_exclFSIRLocks]
	;
	; If FSIR already locked excl by this thread, just deref it.
	; 
		mov	bx, handle FSInfoResource
		cmp	ss:[TPD_exclFSIRLocks], 1
		jnz	anotherExclLock
	;
	; If FSIR already locked shared by this thread, upgrade that lock.
	; 
		tst	ss:[TPD_sharedFSIRLocks]
		jnz	upgradeShared
	;
	; Else just lock it excl now.
	; 
		call	MemLockExcl
done:
		.leave
		ret

anotherExclLock:
		call	FSDDerefInfo
		jmp	done

upgradeShared:
		call	MemUpgradeSharedLock
		jmp	done
FSDLockInfoExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDLockInfoShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the FSInfoResource for shared access

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		ax	= segment of FSInfoResource locked for shared access
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE: this routine is coded so as to keep the count of
		locks for this thread on the block non-zero during the call
		to MemLockShared, to avoid recursion and internal deadlock
		in case ec +segment is turned on when that code calls PHeap
		in SegmentToHandle.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDLockInfoShared proc	far
		uses	bx
		.enter
	;
	; Note a(nother) shared lock for this thread. Done first to avoid
	; recursion in PHeap
	; 
		inc	ss:[TPD_sharedFSIRLocks]
	;
	; If already locked shared or excl, just up the shared-lock count for
	; the thread and deref the handle
	; 
		tst	ss:[TPD_exclFSIRLocks]
		jnz	anotherSharedLock
		cmp	ss:[TPD_sharedFSIRLocks], 1
		jne	anotherSharedLock
	;
	; Else lock the thing shared.
	; 
		mov	bx, handle FSInfoResource
		call	MemLockShared
done:
		.leave
		ret

anotherSharedLock:
		call	FSDDerefInfo
		jmp	done
FSDLockInfoShared endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDUnlockInfoShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release shared lock on FSIR

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		NOTE: this routine is coded so as to keep the count of
		locks for this thread on the block non-zero during the call
		to MemUnlockExcl, to avoid recursion and internal deadlock
		in case ec +segment is turned on when that code calls PHeap
		in SegmentToHandle.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDUnlockInfoShared proc	far
		uses	bx
		.enter
		pushf
		cmp	ss:[TPD_sharedFSIRLocks], 1
		ja	decrementCount
EC <		ERROR_B	FSIR_NOT_LOCKED_SHARED_BY_THIS_THREAD		>
	;
	; If actually have the FSIR locked exclusive, leave it locked.
	; 
		tst	ss:[TPD_exclFSIRLocks]
		jnz	decrementCount
	;
	; Else, last lock released, so unlock the block itself.
	; 
		mov	bx, handle FSInfoResource
		call	MemUnlockShared
decrementCount:
		dec	ss:[TPD_sharedFSIRLocks]
		popf
		.leave
		ret
FSDUnlockInfoShared endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDUnlockInfoExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive lock on FSIR

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		NOTE: this routine is coded so as to keep the count of
		locks for this thread on the block non-zero during the call
		to MemUnlockExcl, to avoid recursion and internal deadlock
		in case ec +segment is turned on when that code calls PHeap
		in SegmentToHandle.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDUnlockInfoExcl proc	far
		uses	bx
		.enter
		pushf
		cmp	ss:[TPD_exclFSIRLocks], 1
		ja	decrementCount
EC <		ERROR_B	FSIR_NOT_LOCKED_EXCL_BY_THIS_THREAD		>
	;
	; If also have shared locks on the FSIR, downgrade the lock to shared.
	; 
		mov	bx, handle FSInfoResource
		tst	ss:[TPD_sharedFSIRLocks]
		jnz	downgradeExclLock
	;
	; Else, last lock released, so unlock the block itself.
	; 
		call	MemUnlockExcl
decrementCount:
		dec	ss:[TPD_exclFSIRLocks]
		popf
		.leave
		ret

downgradeExclLock:
		push	ax
		call	MemDowngradeExclLock
		pop	ax
		jmp	decrementCount
FSDUnlockInfoExcl endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDLockInfoExclToES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the FSInfoResource for exclusive access, storing its
		segment in ES

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		es	= segment of FSInfoResource locked for exclusive
			  access
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDLockInfoExclToES proc	far
		uses	ax
		.enter
		call	FSDLockInfoExcl
		mov	es, ax
		.leave
		ret
FSDLockInfoExclToES endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDUpgradeSharedInfoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upgrade a shared lock on the FSIR to an exclusive one

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		es/ds pointing to new location of FSIR if they pointed there
		on entry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		NOTE: this routine is coded so as to keep the count of
		locks for this thread on the block non-zero during the call
		to MemUpgradeSharedLock, to avoid recursion and internal
		deadlock in case ec +segment is turned on when that code
		calls PHeap in SegmentToHandle.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDUpgradeSharedInfoLock proc	far
		uses	bx, ax
		.enter
	;
	; If already locked excl by this thread, just up the count of excl
	; locks.
	; 
   		inc	ss:[TPD_exclFSIRLocks]
		cmp	ss:[TPD_exclFSIRLocks], 1
		jnz	reduceSharedCount
	;
	; Else upgrade the shared lock to excl.
	; 
   		mov	bx, handle FSInfoResource
		call	MemUpgradeSharedLock
reduceSharedCount:
	;
	; Note another shared lock released.
	; 
		dec	ss:[TPD_sharedFSIRLocks]
EC <		ERROR_S	FSIR_NOT_LOCKED_SHARED_BY_THIS_THREAD		>
		.leave
		ret
FSDUpgradeSharedInfoLock endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDDowngradeExclInfoLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Downgrade an exclusive lock on the FSIR to a shared one

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		es/ds pointing to new location of FSIR if they pointed there
		on entry.
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		NOTE: this routine is coded so as to keep the count of
		locks for this thread on the block non-zero during the call
		to MemDowngradeExclLock, to avoid recursion and internal 
		deadlock in case ec +segment is turned on when that code 
		calls PHeap in SegmentToHandle.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/18/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDDowngradeExclInfoLock proc	far
		uses	ax, bx
		.enter
		pushf
	;
	; Do this first to avoid recursion in PHeap
	; 
		inc	ss:[TPD_sharedFSIRLocks]
	;
	; Note another excl lock released. If not the last, then just up
	; the shared-lock count for the thread, leaving the block locked excl
	; 
		dec	ss:[TPD_exclFSIRLocks]
EC <		ERROR_S	FSIR_NOT_LOCKED_EXCL_BY_THIS_THREAD		>
		jnz	done
	;
	; Else, downgrade the lock to shared and up the count of shared locks.
	; 
   		mov	bx, handle FSInfoResource
		call	MemDowngradeExclLock
done:
		popf
		.leave
		ret
FSDDowngradeExclInfoLock endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDDerefInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The current thread already has the FSIR locked somehow, but
		has misplaced the segment, so return it.

CALLED BY:	RESTRICTED GLOBAL
PASS:		nothing
RETURN:		ax	= segment of FSIR
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDDerefInfo	proc	far
		uses	bx, ds
		.enter
EC <		tst	{word}ss:[TPD_exclFSIRLocks]			>
EC <		ERROR_Z	FSIR_NOT_LOCKED					>
		mov	bx, handle FSInfoResource
		LoadVarSeg	ds
		mov	ax, ds:[bx].HM_addr
		.leave
		ret
FSDDerefInfo	endp


FSResident	ends

