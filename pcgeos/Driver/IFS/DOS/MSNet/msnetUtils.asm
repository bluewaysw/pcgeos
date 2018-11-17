COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		msnetUtils.asm

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
		

	$Id: msnetUtils.asm,v 1.1 97/04/10 11:55:26 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetCallPrimary
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
MSNetCPFrame	struct
    MSNetCPF_ds	sptr
    MSNetCPF_vector fptr.far
MSNetCPFrame	ends

MSNetCallPrimary	proc	far
		.enter
		push	bx, ax, ds
		mov	bp, sp
		segmov	ds, dgroup, ax
		mov	bx, ds:[msnetPrimaryStrat].segment
		mov	ax, ds:[msnetPrimaryStrat].offset
		xchg	ax, ss:[bp].MSNetCPF_vector.offset
		xchg	bx, ss:[bp].MSNetCPF_vector.segment
		mov	ds, ss:[bp].MSNetCPF_ds
		call	ss:[bp].MSNetCPF_vector
		mov	bp, sp
		lea	sp, ss:[bp+size MSNetCPFrame]
		.leave
		ret
MSNetCallPrimary	endp


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
		MSNetPassOnInterrupt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass on an interrupt we've decided not to handle

CALLED BY:	(EXTERNAL) MSNetIdleHook, MSNetCriticalError
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

MSNetPassOnInterrupt proc	far jmp
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
MSNetPassOnInterrupt endp


Resident	ends
