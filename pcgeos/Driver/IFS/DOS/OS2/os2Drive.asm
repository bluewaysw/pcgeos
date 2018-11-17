COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		msDrive.asm

AUTHOR:		Adam de Boor, Mar 19, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/19/92		Initial revision


DESCRIPTION:
	Drive-related code that is common to all versions of MS DOS
		

	$Id: os2Drive.asm,v 1.1 97/04/10 11:55:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDriveCheckChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the drive can assure us the disk hasn't changed
		since something was last locked into the drive.
		
		This is also used before ID'ing a disk to ensure DOS is
		kept apprised of any disk change (which otherwise would
		be lost)

CALLED BY:	DOSDiskLock
PASS:		es:bx	= DriveStatusEntry
RETURN:		carry clear if disk definitely not changed
		carry set if disk might have or definitely has changed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDriveCheckChange proc near
		uses	ax, si
		.enter
	;
	; After a MediaCheck call, if the disk may have changed, we must
	; call BuildBPB and transfer that parameter block to the DOS Device
	; Control Block, but we have no way of doing that for DR DOS, so
	; we cannot call the driver. Instead, we rely on our own wits. If the
	; last access to this disk was within the minChangeTime for the drive,
	; then we claim the  disk hasn't changed.
	; 
		push	ax
		push	bx
		call	TimerGetCount
		pop	bx
		sub	ax, es:[bx].DSE_lastAccess
		cmp	ax, DOS_DISK_MIN_CHANGE_TIME
		pop	ax
		clc
		jle	done
		stc		; flag disk may have changed
done:
		.leave
		ret
DOSDriveCheckChange endp

Resident	ends
