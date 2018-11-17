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
		

	$Id: msDrive.asm,v 1.1 97/04/10 11:55:02 newdeal Exp $

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
		ax	= error flag -- non-zero if disk cannot be read
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/10/92		Initial version
	chrisb	11/93		Removed optimization.  Oh well.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDriveCheckChange proc near

		uses	bx, cx, dx, ds
		
		.enter
	;
	; If last-access time is recent, then disk definitely didn't
	; change. 
	;
		
		push	bx
		call	TimerGetCount
		pop	bx
		sub	ax, es:[bx].DSE_lastAccess
		cmp	ax, DOS_DISK_MIN_CHANGE_TIME
		clc
		mov	ax, 0
		jle	done

	;
	; Disk may have changed. Issue an MSDOS_GET_DISK_GEOMETRY to
	; force DOS to access the disk and see if it's changed.
	;

		call	DOSPreventCriticalErr

		mov	dl, es:[bx].DSE_number
		inc	dl			; 1-based
		clr	cx			; for checking error return
		mov	ah, MSDOS_GET_DISK_GEOMETRY
		call	DOSUtilInt21

		call	DOSAllowCriticalErr
	;
	; DOS is not kind enough to return an error to MSDOS_GET_DISK_GEOMETRY
	; so we have to check to see if CX changed

		mov	ax, ERROR_GENERAL_FAILURE
		jcxz	gotErrorCode
		clr	ax
gotErrorCode:

		stc		; flag disk may have changed
done:
		.leave
		ret
DOSDriveCheckChange endp


if 0

if _FXIP
	PrintError <Code needs to be XIP'ed>
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDriveCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the DOS device driver to perform a request.

CALLED BY:	DOSDriveCheckChange
PASS:		es:si	= DOSDrivePrivateData
		ss:bp	= inherited stack frame
		bios lock grabbed
RETURN:		carry set on error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDriveCallDriver proc	near
		uses	ax, bx, es, bp, ds, si
		.enter	inherit	DOSDriveCheckChange
	;
	; Finish filling in the request.
	; 
		mov	al, es:[si].DDPD_unit
		mov	ss:[req].AR_header.RH_unit, al
		mov	ss:[req].AR_header.RH_status, 0
	;
	; First call the "strategy" routine, passing it the request header
	; in es:bx
	; 
		lds	si, es:[si].DDPD_device
		segmov	es, ss
		lea	bx, ss:[req]
		mov	ax, ds:[si].DH_strat
		push	cs
		call	makeCall
	;
	; Now call the "interrupt" routine to process the request. Who thought
	; up this interface, anyway?
	; 
		mov	ax, ds:[si].DH_intr
		push	cs
		call	makeCall
	;
	; See if the thing protesteth too much.
	; 
		test	ss:[req].AR_header.RH_status, mask DDS_ERROR
		jz	ok
		stc
ok:
		.leave
		ret

makeCall:
		push	ds		; set segment for call
		push	ax		;  and offset
		retf			; call the driver. it will return to
					;  "our" caller for us...
DOSDriveCallDriver endp

endif

Resident	ends
