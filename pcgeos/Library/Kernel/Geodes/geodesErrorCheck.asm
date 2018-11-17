COMMENT @-----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Geode
FILE:		geodeErrorCheck.asm

ROUTINES:
	Name				Description
	----				-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

DESCRIPTION:
	This file contains the error checkin routines

	$Id: geodesErrorCheck.asm,v 1.1 97/04/05 01:12:05 newdeal Exp $

-------------------------------------------------------------------------------@

;--------------------------------------------------------------------------

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckProcessHandle

DESCRIPTION:	Check a process handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - process handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckProcessHandle	proc	far				>
NEC <	FALL_THRU	ECCHECKSTACK					>
NEC <ECCheckProcessHandle	endp					>

NEC <ECCHECKSTACK	proc	far					>
NEC <	ret								>
NEC <ECCHECKSTACK	endp						>

if	ERROR_CHECK

ECCheckProcessHandle	proc	far
	pushf
	push	ax, ds
	call	ECCheckMemHandleNSFar
	LoadVarSeg	ds
	cmp	bx,ds:[bx].HM_owner
	ERROR_NZ	ILLEGAL_PROCESS
	call	NearLockDS
	test	ds:[GH_geodeAttr],mask GA_PROCESS
	ERROR_Z	ILLEGAL_PROCESS
	call	NearUnlock
	pop	ax, ds
	popf
	ret

ECCheckProcessHandle	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckResourceHandle

DESCRIPTION:	Check a resource handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - resource handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckResourceHandle	proc	far				>
NEC <	ret								>
NEC <ECCheckResourceHandle	endp					>

if	ERROR_CHECK

ECCheckResourceHandle	proc	far
	pushf
	push	ax, bx, ds

	call	ECCheckMemHandleNSFar
	call	HandleToID
	ERROR_C	ILLEGAL_RESOURCE

	mov	ds, ax
	call	UnlockDS

	pop	ax, bx, ds
	popf
	ret

ECCheckResourceHandle	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckGeodeHandle

DESCRIPTION:	Check a geode handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - geode handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckGeodeHandle	proc	far					>
NEC <	ret								>
NEC <ECCheckGeodeHandle	endp						>

if	ERROR_CHECK

ECCheckGeodeHandle	proc	far
	pushf
	push	ds
	call	ECCheckMemHandleNSFar
	LoadVarSeg	ds
	cmp	bx,ds:[bx].HM_owner
	ERROR_NZ	ILLEGAL_GEODE
	pop	ds
	popf
	ret

ECCheckGeodeHandle	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckDriverHandle

DESCRIPTION:	Check a driver handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - driver handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckDriverHandle	proc	far				>
NEC <	ret								>
NEC <ECCheckDriverHandle	endp					>

if	ERROR_CHECK

ECCheckDriverHandle	proc	far
	pushf
	push	ax, ds
	call	ECCheckMemHandleNSFar
	LoadVarSeg	ds
	cmp	bx,ds:[bx].HM_owner
	ERROR_NZ	ILLEGAL_DRIVER
	call	NearLockDS
	test	ds:[GH_geodeAttr],mask GA_DRIVER
	ERROR_Z	ILLEGAL_DRIVER
	call	NearUnlock
	pop	ax, ds
	popf
	ret

ECCheckDriverHandle	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckLibraryHandle

DESCRIPTION:	Check a library handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - library handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckLibraryHandle	proc	far				>
NEC <	ret								>
NEC <ECCheckLibraryHandle	endp					>

if	ERROR_CHECK

ECCheckLibraryHandle	proc	far
	pushf
	push	ax, ds
	call	ECCheckMemHandleNSFar
	LoadVarSeg	ds
	cmp	bx,ds:[bx].HM_owner
	ERROR_NZ	ILLEGAL_LIBRARY
	call	NearLockDS
	test	ds:[GH_geodeAttr],mask GA_LIBRARY
	ERROR_Z	ILLEGAL_LIBRARY
	call	NearUnlock
	pop	ax, ds
	popf
	ret

ECCheckLibraryHandle	endp

endif

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCheckQueueHandle

DESCRIPTION:	Check a queue handle for validity

CALLED BY:	GLOBAL

PASS:
	bx - queue handle

RETURN:
	none

DESTROYED:
	nothing -- even the flags are kept intact

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	9/89		Initial version

------------------------------------------------------------------------------@


NEC <ECCheckQueueHandle	proc	far					>
NEC <	ret								>
NEC <ECCheckQueueHandle	endp						>

if	ERROR_CHECK

ECCheckQueueHandle	proc	far
	call	CheckHandleLegal
	pushf
	push	ds
	LoadVarSeg	ds

	cmp	ds:[bx].HQ_handleSig,SIG_QUEUE
	ERROR_NZ	ILLEGAL_QUEUE

	pop	ds
	popf
	ret

ECCheckQueueHandle	endp

COMMENT @----------------------------------------------------------------------

FUNCTION:	ECCHECKSTACK

DESCRIPTION:	Make sure the current stack is not overflowed

CALLED BY:	GLOBAL

PASS:

RETURN:

DESTROYED:

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	11/89		Initial version

------------------------------------------------------------------------------@

ECCHECKSTACK	proc	far			uses ax, bx, ds
	.enter
	pushf

	LoadVarSeg	ds
	cmp	ds:[currentThread],0
	jz	skip

	; Make sure stack segment makes sense. If it lies in DOS/BIOS, then
	; we can't error check anything.
	mov	ax, ss
	cmp	ax, 40h
	ERROR_BE	ILLEGAL_THREAD
	cmp	ax, ds:loaderVars.KLV_pspSegment
	jb	skip

	mov	ax,ss:[TPD_stackBot]
	cmp	ax, size ThreadPrivateData
	ERROR_B	TPD_STACK_BOT_TOO_SMALL
	add	ax, STACK_RESERVED_FOR_INTERRUPTS
	mov	bx, sp
	cmp	ax, bx
	ERROR_AE	STACK_OVERFLOW

	mov	bx,ss:[TPD_blockHandle]
	test	bx, 0xf
	ERROR_NZ	TPD_BLOCK_HANDLE_CORRUPTED
	mov	ax,ds:[bx].HM_size
	shl	ax,1
	shl	ax,1
	shl	ax,1
	shl	ax,1
	mov	bx, sp
	cmp	ax, bx
	ERROR_BE	STACK_POINTER_LARGER_THAN_BLOCK

skip:
	popf
	.leave
	ret

ECCHECKSTACK	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckReservationHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the validity of a reservation handle

CALLED BY:	Global
PASS:		bx - handle to check
RETURN:		nothing
DESTROYED:	nothing - not even flags
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RG	2/27/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	not NEVER_ENFORCE_HEAPSPACE_LIMITS
ECCheckReservationHandle	proc	far
	pushf
	push	ds, bx

	LoadVarSeg	ds

	; check the type

	cmp ds:[bx].HR_type, SIG_RESERVATION
	ERROR_NE	ILLEGAL_RESERVATION

	; check the owner - must be a geode handle

	mov	bx, ds:[bx].HR_owner
	call	ECCheckGeodeHandle

	pop	ds, bx
	popf
	ret
ECCheckReservationHandle	endp
endif	; NEVER_ENFORCE_HEAPSPACE_LIMITS


endif ;ERROR_CHECK
