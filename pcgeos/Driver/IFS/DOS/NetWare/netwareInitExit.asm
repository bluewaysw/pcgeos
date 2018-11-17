COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		driInitExit.asm

AUTHOR:		Adam de Boor, Mar 29, 1992

ROUTINES:
	Name			Description
	----			-----------


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	3/29/92		Initial revision


DESCRIPTION:
	Functions to initialize and exit the driver.


	$Id: netwareInitExit.asm,v 1.1 97/04/10 11:55:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the driver.

CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry set if couldn't initialize
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		This function is responsible for a number of things to
		initialize the system, as well as this driver, to wit:
			* locate all drives we can manage and create
			  them in the kernel.

KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWInit		proc	far
		.enter
	;
	; call to get the drive flag table.  Look at the return value to
	; figure out whether netware is actually running
	;
		mov	si, 0xffff		;bogus offset
		mov	ax, NFC_GET_DRIVE_FLAG_TABLE
EC <		push	es	; avoid ec +segment death		>
		int	21h			;es:si = drive flag table
EC <		pop	es						>
		cmp	si, 0xffff
		je	fail
	;
	; See if the primary FSD has been loaded yet and ensure its aux protocol
	; number is compatible.
	; 
		mov	ax, GDDT_FILE_SYSTEM
		call	GeodeGetDefaultDriver
		tst	ax
		jz	fail			; not loaded, so we can do
						;  nothing
		mov_tr	bx, ax
		call	GeodeInfoDriver
		
		mov	ax, ds:[si].FSDIS_altStrat.offset
		mov	bx, ds:[si].FSDIS_altStrat.segment
		mov	cx, ds:[si].FSDIS_altProto.PN_major
		mov	dx, ds:[si].FSDIS_altProto.PN_minor

		segmov	ds, dgroup, di
		mov	ds:[nwPrimaryStrat].offset, ax
		mov	ds:[nwPrimaryStrat].segment, bx
		cmp	cx, DOS_PRIMARY_FS_PROTO_MAJOR
		jne	fail
		cmp	dx, DOS_PRIMARY_FS_PROTO_MINOR
		jb	fail
	;
	; We may need the PSP at some point...
	; 
		mov	ah, MSDOS_GET_PSP
		int	21h
		mov	ds:[pspSegment], bx	; save PSP
	;
	; Since NetWare is loaded, we remain, even if there are no drives
	; managed by NetWare yet, as we may be called upon to map some when
	; restoring disk handles.
	;
	; Register with the kernel.
	;
		mov	cx, segment NWStrategy
		mov	dx, offset NWStrategy
		mov	ax, FSD_FLAGS
		mov	bx, handle 0
		clr	di			; no disk-private data here
		call	FSDRegister
		mov	ds:[fsdOffset], dx

		call	NWInitLocateDrives

		segmov	es, ds
		call	NWInitOpenFiles
	;
	; Intercept int 28h so we can tell the network we're idle. Lord only
	; knows why they need their own call, but there it is...
	; 
		mov	di, offset nwOldInt28
		mov	bx, segment NWIdleHook
		mov	cx, offset NWIdleHook
		mov	ax, 28h
		call	SysCatchInterrupt

		clc
done:
		.leave
		ret
fail:
		stc
		jmp	done
NWInit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grabs the interrupt again after returning from suspend

CALLED BY:	DR_UNSUSPEND
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ron	1/18/94    	Initial version
	dloft	6/17/94		Fixed painful dos-trashing bug
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWUnsuspend	proc	far
	uses	ax, bx, cx, di, es
	.enter

		segmov	es, dgroup, bx
		mov	di, offset nwOldInt28
		mov	bx, segment NWIdleHook
		mov	cx, offset NWIdleHook
		mov	ax, 28h
		call	SysCatchInterrupt

		clc

	.leave
	ret
NWUnsuspend	endp


;==============================================================================
;
;			    DRIVE LOCATION
;
;==============================================================================

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWInitLocateDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all the drives we can manage.

CALLED BY:	NWInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWInitLocateDrives proc	near
		.enter
		mov	ax, NFC_GET_DRIVE_FLAG_TABLE
		int	21h
		mov	cx, NW_MAX_NUM_DRIVES	; cx <- drives left to process
		clr	ah			; start with drive 0...
driveLoop:
		lodsb	es:
			CheckHack <NWDT_FREE eq 0>
		test	al, mask NWDF_TYPE
		jz	nextDrive

		push	ax, cx, si
		mov	al, ah
		mov	ah, MEDIA_FIXED_DISK
	;
	; Drive is a fixed network drive that's not formattable, not read-only,
	; available over the net, not busy and not an alias.
	; 
		mov	cx, mask DS_PRESENT or mask DS_NETWORK or DRIVE_FIXED
		mov	dx, ds:[fsdOffset]
		mov	si, offset nwNormalDriveName
		mov	bl, al
		add	bl, 'A'
		cmp	bl, 'Z'
		jbe	allocDrive

		sub	bl, 'Z'-'1'
		mov	si, offset nwSpecialDriveName
allocDrive:
SBCS <		mov	ds:[nwNormalDriveName], bl>
DBCS <		clr	bh>
DBCS <		mov	ds:[nwNormalDriveName], bx>

		clr	bx			; no private data needed
EC <		push	es		; avoid ec +segment death	>
EC <		segmov	es, ds						>
		call	FSDInitDrive
EC <		pop	es						>
		pop	ax, cx, si
nextDrive:
		inc	ah		; next drive number
		loop	driveLoop
		.leave
		ret
NWInitLocateDrives endp

;==============================================================================
;
;			 OPEN FILE TAKE-OVER
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWInitOpenFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all files in the open-file list that are on drives
		we manage and alter their private data and SFN to our
		liking.

CALLED BY:	NWInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version
	sh	04/21/94	XIP'ed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWInitOpenFiles proc	near
		.enter
		clr	bx			; process entire list
		mov	dx, ds:[fsdOffset]	; pass the offset of our
						;  FSDriver record
		mov	di, SEGMENT_CS		; di <- virtual segment
		mov	si, offset NWIOF_callback
		call	FileForEach
		.leave
		ret
NWInitOpenFiles endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWIOF_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to initialize file handles that were
		opened with the skeleton FSD.

CALLED BY:	NWInitOpenFiles via FileForEach
PASS:		ds:bx	= HandleFile
		dx	= offset of our FSDriver record
RETURN:		carry set to end processing
DESTROYED:	ax, cx, bp, di, si, es may all be nuked

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 1/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWIOF_callback	proc	far
		.enter
	;
	; See if the file handle is on one of our drives by checking if the
	; DSE_fsd field of the drive of the disk the file is on matches our
	; own.
	; 
		mov	si, ds:[bx].HF_disk
		tst	si		; device?
		jz	done		; yes => not our responsibility

		call	FSDLockInfoShared
		mov	es, ax
		mov	si, es:[si].DD_drive
		cmp	es:[si].DSE_fsd, dx
		call	FSDUnlockInfoShared
		jne	done

		mov	di, DR_DPFS_INIT_HANDLE
		call	NWCallPrimary
done:
		clc		; continue processing
		.leave
		ret
NWIOF_callback	endp

Init		ends

;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
;
;			    EXIT HANDLING
;
;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWIExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close down our interaction with NetWare.

CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		nothing
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWExit		proc	far
		uses	es, di, ax
		.enter
		segmov	es, dgroup, ax
		tst	es:[nwOldInt28].segment
		jz	done		; => didn't get as far as intercepting
					;  it
		mov	di, offset nwOldInt28
		mov	ax, 28h
		call	SysResetInterrupt
done:
		clc
		.leave
		ret
NWExit		endp

Resident	ends
