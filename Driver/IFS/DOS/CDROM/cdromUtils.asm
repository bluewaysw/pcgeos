COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cdromUtils.asm

AUTHOR:		Adam de Boor, Mar 29, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/29/92		Initial revision


DESCRIPTION:
	NetWare-specific utilities
		

	$Id: cdromUtils.asm,v 1.1 97/04/10 11:55:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMCallPrimary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the primary FSD to do something for us.

CALLED BY:	INTERNAL
PASS:		di	= DOSPrimaryFSFunction to call
		etc.
RETURN:		whatever
DESTROYED:	bp before the call is made

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMCPFrame	struct
    CDROMCPF_ds	sptr
    CDROMCPF_vector fptr.far
CDROMCPFrame	ends

CDROMCallPrimary	proc	far
		.enter
		push	bx, ax, ds
		mov	bp, sp
		segmov	ds, dgroup, ax
		mov	bx, ds:[cdromPrimaryStrat].segment
		mov	ax, ds:[cdromPrimaryStrat].offset
		xchg	ax, ss:[bp].CDROMCPF_vector.offset
		xchg	bx, ss:[bp].CDROMCPF_vector.segment
		mov	ds, ss:[bp].CDROMCPF_ds
		call	ss:[bp].CDROMCPF_vector
		mov	bp, sp
		lea	sp, ss:[bp+size CDROMCPFrame]
		.leave
		ret
CDROMCallPrimary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadVarSegDS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load dgroup into DS

CALLED BY:	INTERNAL
PASS:		nothing
RETURN:		ds	= dgroup
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
dgroupSeg	sptr	dgroup
LoadVarSegDS	proc	near
		.enter
		mov	ds, cs:[dgroupSeg]
		.leave
		ret
LoadVarSegDS	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMPassOnInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass on an interrupt we've decided not to handle

CALLED BY:	(EXTERNAL) CDROMIdleHook, CDROMCriticalError
PASS:		ds:bx	= place where old handler is stored
		on stack (pushed in this order): bx, ax, ds
RETURN:		never
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPOIStack       struct
    DPOIS_bp            word
    DPOIS_ax            word
    DPOIS_bx            word
    DPOIS_retAddr       fptr.far
    DPOIS_flags         word
DPOIStack       ends

CDROMPassOnInterrupt proc	far jmp
                on_stack        ds ax bx retf
        ;
        ; Fetch the old vector into ax and bx
        ;
        	mov     ax, ds:[bx].offset
        	mov     bx, ds:[bx].segment
        	pop     ds

                on_stack        ax bx retf
        ;
        ; Now replace the saved ax and bx with the old vector, so we can
        ; just perform a far return to get to the old handler.
        ;
        	push    bp
                on_stack        bp ax bx retf
        	mov     bp, sp
        	xchg    ax, ss:[bp].DPOIS_ax
        	xchg    bx, ss:[bp].DPOIS_bx
        	pop     bp
                on_stack        retf
        	ret
CDROMPassOnInterrupt endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMUtilSetFailOnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the failOnError flag after grabbing the BIOS lock

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMUtilSetFailOnError proc	near
		uses	ds
		.enter
		call	SysLockBIOS
		mov	ds, cs:[dgroupSeg]
		inc	ds:[failOnError]
		.leave
		ret
CDROMUtilSetFailOnError endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CDROMUtilClearFailOnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the failOnError flag and release the BIOS lock

CALLED BY:	(EXTERNAL)
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDROMUtilClearFailOnError proc	near
		uses	ds
		.enter
		pushf
		mov	ds, cs:[dgroupSeg]
		dec	ds:[failOnError]
		call	SysUnlockBIOS
		popf
		.leave
		ret
CDROMUtilClearFailOnError endp

Resident	ends
