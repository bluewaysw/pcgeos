COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		driveLow.asm

AUTHOR:		Adam de Boor, Apr 22, 1990

ROUTINES:
	Name			Description
	----			-----------
    INT	DrivePointAtEntry	Point at the proper disk status entry
				for the indicated drive.
    INT	DriveCallDriver		Call the DOS driver pointed to by ds:si
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/22/90		Initial revision


DESCRIPTION:
	Low-level functions for the Drive module
		

	$Id: driveLow.asm,v 1.1 97/04/05 01:11:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrivePointAtEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a zero-based drive number, return the address of
		the DriveStatusEntry for the drive.

CALLED BY:	DriveGetStatus, DriveGetDefaultMedia
PASS:		al	= zero-based drive number
RETURN:		ds:bx	= DriveStatusEntry
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrivePointAtEntryFar proc far
		     call	DrivePointAtEntry
		     ret
DrivePointAtEntryFar endp

DrivePointAtEntry proc	near	uses	ax
		.enter
EC<		cmp	al, MSDOS_MAX_DRIVES				>
EC<		ERROR_AE	BAD_DRIVE_SPECIFIED			>

					CheckHack <size DriveStatusEntry eq 22>

		xchg	bx, ax
		clr	bh
		shl	bx
		mov	ax, bx		; save al * 2
		shl	bx
		add	ax, bx		; ax <- al * 6
		shl	bx
		shl	bx		; bx = al * 16
		add	bx, ax		; bx <- al * 22
		
		LoadVarSeg	ds
		add	bx, offset driveStatusTable
		.leave
		ret
DrivePointAtEntry endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveCallDriver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Issue a call to a DOS device driver

CALLED BY:	DriveMediaRemovable?, InitDriveMap
PASS:		ds:si	= DeviceHeader of driver to call
		on stack:
			RequestHeader structure for request to issue,
				plus any extra data required by the call.
RETURN:		carry set if driver declares an error
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveCallDriver	proc	far	request:RequestHeader
		uses	ax, es, bx
		.enter
		call	LockDOS
	;
	; First call the "strategy" routine, passing it the request header
	; in es:bx
	; 
		segmov	es, ss, bx
		lea	bx, request
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
		test	request.RH_status, mask DDS_ERROR
		jz	ok
		stc
ok:
		call	UnlockDOS
		.leave
		ret
makeCall:
		push	ds		; Set segment for call
		push	ax		;  and offset
		retf			; Call the driver. It will return
					;  to "our" caller for us...
DriveCallDriver	endp



