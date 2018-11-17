COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		netwareUtils.asm

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
		

	$Id: netwareUtils.asm,v 1.1 97/04/10 11:55:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWCallPrimary
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
NWCPFrame	struct
    NWCPF_ds	sptr
    NWCPF_vector fptr.far
NWCPFrame	ends

NWCallPrimary	proc	far
		.enter
		push	bx, ax, ds
		mov	bp, sp
		segmov	ds, dgroup, ax
		mov	bx, ds:[nwPrimaryStrat].segment
		mov	ax, ds:[nwPrimaryStrat].offset
		xchg	ax, ss:[bp].NWCPF_vector.offset
		xchg	bx, ss:[bp].NWCPF_vector.segment
		mov	ds, ss:[bp].NWCPF_ds
		call	ss:[bp].NWCPF_vector
		mov	bp, sp
		lea	sp, ss:[bp+size NWCPFrame]
		.leave
		ret
NWCallPrimary	endp


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
		NWChangePreferredServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push the old preferred server and switch to that for the
		passed disk.

CALLED BY:	(EXTERNAL)
PASS:		es:si	= DiskDesc whose server should be preferred
		cwdLock grabbed
RETURN:		ax	= old connection ID
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWChangePreferredServer proc	far
		uses	bx, es, si, dx
		.enter
	;
	; Fetch the current connection ID and save it for return.
	; 
		mov	ax, NFC_GET_PREFERRED_CONNECTION_ID
		call	FileInt21
		push	ax
	;
	; Point es:si to the connection id table, after extracting the
	; drive number for the disk into bx
	; 
		mov	bx, es:[si].DD_drive
		mov	bl, es:[bx].DSE_number
		clr	bh
		mov	ax, NFC_GET_DRIVE_CONNECTION_ID_TABLE
		call	FileInt21
	;
	; Fetch connection ID for the drive.
	; 
		mov	dl, es:[si][bx]
EC <		tst	dl						>
EC <		ERROR_Z	DRIVE_NO_LONGER_VALID				>
	;
	; Set that as the preferred connection
	; 
		mov	ax, NFC_SET_PREFERRED_CONNECTION_ID
		call	FileInt21	
		
		pop	ax
		.leave
		ret
NWChangePreferredServer endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWRestorePreferredServer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the preferred server to that whose connection ID
		is passed on the stack.

CALLED BY:	(EXTERNAL)
PASS:		connectionID	= connection ID as returned by
				  NWChangePreferredServer
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	connection ID popped off the stack

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWRestorePreferredServer proc	far	connectionID:word
		uses	ax, dx
		.enter
		pushf
		mov	dl, ss:[connectionID].low
		mov	ax, NFC_SET_PREFERRED_CONNECTION_ID
		call	FileInt21
		popf
		.leave
		ret	@ArgSize
NWRestorePreferredServer endp

Resident	ends
