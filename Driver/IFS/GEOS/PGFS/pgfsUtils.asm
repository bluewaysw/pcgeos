COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		pgfsUtils.asm

AUTHOR:		Adam de Boor, Sep 30, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	9/30/93		Initial revision


DESCRIPTION:
	Utility routines
		

	$Id: pgfsUtils.asm,v 1.1 97/04/18 11:46:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.186

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSUDerefSocket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the offset of the PGFSSocketInfo for the indicated
		socket.

CALLED BY:	(EXTERNAL)
PASS:		cx	= socket number
RETURN:		bx	= offset of PGFSSocketInfo in dgroup
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	9/30/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSUDerefSocket proc	far
		uses	ax, dx
		.enter
		mov	ax, size PGFSSocketInfo
		mul	cx
		mov_tr	bx, ax
		add	bx, offset socketInfo
		.leave
		ret
PGFSUDerefSocket endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSUCheckInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the indicated socket is in-use

CALLED BY:	(EXTERNAL) PGFSRHandleRemoval, 
			   PGFSCardServicesCallback
PASS:		ds	= dgroup
		cx	= socket number
RETURN:		carry set if socket in-use
		carry clear if not in-use
		ds:bx	= PGFSSocketInfo for the socket
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/26/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSUCheckInUse proc	near
		.enter
		call	PGFSUDerefSocket
		test	ds:[bx].PGFSSI_flags, mask PSF_PRESENT
		jz	done
		
		test	ds:[bx].PGFSSI_flags, mask PSF_HAS_FONTS
		jnz	inUse
	;
	; If nothing referencing the card, we're willing to see it go.
	; 
		tst_clc	ds:[bx].PGFSSI_inUseCount
		jz	done

inUse:
		
		stc
done:
		.leave
		ret
PGFSUCheckInUse endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSMapOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Map memory into the window given us by card services

CALLED BY:	GFSDevRead, GFSDevMapDir, GFSDevMapEA

PASS:		dxax - 32-bit offset of GFS to map in

RETURN:		es:di - pointer to first byte of data
		carry set if error (card no longer available, etc)
		ds:bx - PGFSSocketInfo for this socket

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/28/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSMapOffset	proc 	near
		
		uses	ax, cx, dx

mapMemPageArgs	local	CSMapMemPageArgs
		
		.enter

		call	LoadVarSegDS
		mov	bx, ds:[curSocketPtr]

	;
	; Get the linear address of the memory.
	;
		adddw	dxax, ds:[bx].PGFSSI_address
		
	;
	; Return the in-bank offset in DI.
	; 
		mov	di, ax
		andnf	di, BANK_SIZE-1

		andnf	ax, not (BANK_SIZE-1)

		movdw	ss:[mapMemPageArgs].CSMMPA_cardOffset, dxax
		mov	ss:[mapMemPageArgs].CSMMPA_page, 0
		mov	dx, ds:[bx].PGFSSI_window

		push	bx
		segmov	es, ss, bx
		lea	bx, ss:[mapMemPageArgs]	; es:bx = ArgPointer
		mov	cx, size CSMapMemPageArgs
		cmp	ds:[inserting], TRUE
		jne	lockBIOS
		CallCS	CSF_MAP_MEM_PAGE, DONT_LOCK_BIOS
		jmp	$10
lockBIOS:
		CallCS	CSF_MAP_MEM_PAGE
$10:
		pop	bx
		mov	es, ds:[bx].PGFSSI_windowSeg

if ERROR_CHECK
		jc	done
		mov	ds:[fsMapped], TRUE
done:
endif
		.leave
		ret
PGFSMapOffset	endp

PGFSMapOffsetFar	proc	far
		call	PGFSMapOffset
		ret
PGFSMapOffsetFar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PGFSUDerefSocketFromDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deref the PGFSSocketInfo given a DiskDesc

CALLED BY:	GFSDevLock, GFSCurPathCopy, GFSCurPathDelete

PASS:		es:si - DiskDesc 

RETURN:		ds:bx - PGFSSocketInfo (ds = dgroup)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/ 3/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PGFSUDerefSocketFromDisk	proc far
		.enter
		call	LoadVarSegDS
		mov	bx, es:[si].DD_drive
		mov	bx, es:[bx].DSE_private
		mov	bx, es:[bx].PGFSPD_socketPtr

		.leave
		ret
PGFSUDerefSocketFromDisk	endp


Resident	ends

