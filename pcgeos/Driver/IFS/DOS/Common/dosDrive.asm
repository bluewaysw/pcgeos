COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driDrive.asm

AUTHOR:		Adam de Boor, Mar  9, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/ 9/92		Initial revision


DESCRIPTION:
	Drive-specific functions of the IFS driver.
		

	$Id: dosDrive.asm,v 1.1 97/04/10 11:55:03 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDriveLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with locking an aliased drive.

CALLED BY:	DR_FS_DRIVE_LOCK, DOSDiskGrabAlias
PASS:		es:si	= DriveStatusEntry to lock
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDriveLock	proc	far
		uses	ax, bx
		.enter
	;
	; If drive not ours, do nothing.
	; 
		mov	bx, es:[si].DSE_fsd
		cmp	es:[bx].FSD_handle, handle 0
		jne	done

		mov	bx, es:[si].DSE_private
		tst	bx				;if no private data
		jz	done				;then assume no alias
		test	es:[bx].DDPD_flags, mask DDPDF_ALIAS
		jz	done
		
	;
	; First gain exclusive access to the physical drive.
	; 
		push	bx
		mov	bx, es:[bx].DDPD_aliasLock
		tst	bx
		jz	grabbed		; => was secondary when initialized
					;  and primary never got registered
					;  (e.g. because of a media override
					;  in the ini file), so there's no
					;  synchronization needed, but we
					;  do need to make the DOS call...
		call	ThreadGrabThreadLock
grabbed:
		pop	bx
	;
	; Now tell DOS that ours is the drive of choice.
	; 
		mov	ax, MSDOS_SET_LOGICAL_DRIVE_MAP
		mov	bl, es:[si].DSE_number
		inc	bx
		call	DOSUtilInt21
done:
		.leave
		ret
DOSDriveLock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDriveUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to the physical drive for which
		the passed drive may or may not be an alias...

CALLED BY:	DR_FS_DRIVE_UNLOCK, DOSDiskReleaseAlias
PASS:		es:si	= DriveStatusEntry
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDriveUnlock	proc	far
		uses	ax, bx
		.enter
	;
	; If drive not ours, do nothing.
	; 
		mov	bx, es:[si].DSE_fsd
		cmp	es:[bx].FSD_handle, handle 0
		jne	done

		mov	bx, es:[si].DSE_private
		tst	bx				;if no private data
		jz	done				;then assume no alias
		test	es:[bx].DDPD_flags, mask DDPDF_ALIAS
		jz	done
	;
	; Release exclusive access to the physical drive.
	; 
		mov	bx, es:[bx].DDPD_aliasLock
		tst	bx
		jz	done		; => was secondary when initialized
					;  and primary never got registered
					;  (e.g. because of a media override
					;  in the ini file), so there's no
					;  synchronization needed
		call	ThreadReleaseThreadLock
done:
		.leave
		ret
DOSDriveUnlock	endp

Resident	ends
