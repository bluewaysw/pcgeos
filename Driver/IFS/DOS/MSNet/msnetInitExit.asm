COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		msnetInitExit.asm

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


	$Id: msnetInitExit.asm,v 1.1 97/04/10 11:55:25 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetInit
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
MSNetInit	proc	far
		.enter
	;
	; Get the machine name, to ensure a compatible network is actually
	; running.
	; 
		sub	sp, 16
		mov	dx, sp
		segmov	ds, ss
		mov	ax, MSDOS_GET_MACHINE_NAME
		int	21h
		mov	bx, sp
		lea	sp, [bx+16]
		jc	fail
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
		mov	ds:[msnetPrimaryStrat].offset, ax
		mov	ds:[msnetPrimaryStrat].segment, bx
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
	; Since the network is loaded, we remain, even if there are no drives
	; managed by the network yet, as we may be called upon to map some when
	; restoring disk handles.
	;
	; Register with the kernel.
	;
		mov	cx, segment MSNetStrategy
		mov	dx, offset MSNetStrategy
		mov	ax, FSD_FLAGS
		mov	bx, handle 0
		clr	di			; no disk-private data here
		call	FSDRegister
		mov	ds:[fsdOffset], dx

		call	MSNetInitLocateDrives

		call	MSNetInitClearLocalBits

		segmov	es, ds
		call	MSNetInitOpenFiles
	;
	; Intercept int 28h so we can tell the network we're idle. Lord only
	; knows why they need their own call, but there it is...
	; 
		mov	di, offset msnetOldInt28
		mov	bx, segment MSNetIdleHook
		mov	cx, offset MSNetIdleHook
		mov	ax, 28h
		call	SysCatchInterrupt
	;
	; Intercept critical errors so we can cope with network errors
	; gracefully
	; 
		mov	di, offset msnetOldInt24
		mov	bx, segment MSNetCriticalError
		mov	cx, offset MSNetCriticalError
		mov	ax, CRITICAL_VECTOR
		call	SysCatchInterrupt

		clc
done:
		.leave
		ret
fail:
		stc
		jmp	done
MSNetInit		endp


;==============================================================================
;
;			    DRIVE LOCATION
;
;==============================================================================

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetInitLocateDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all the drives we can manage.

CALLED BY:	MSNetInit
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
MSNetInitLocateDrives proc	near
devName		local	MSNetDeviceName
targPath	local	MSNetPath
		uses	ds
		.enter
		mov	dx, ds:[fsdOffset]
		segmov	ds, ss, ax
		mov	es, ax
		lea	si, ss:[devName]
		lea	di, ss:[targPath]
		clr	bx
entryLoop:
		push	dx, bx, bp
		mov	ax, MSDOS_GET_REDIRECTED_DEVICE
		int	21h
		mov	cx, bx
		pop	dx, bx, bp
		jc	done

		cmp	cx, MSNDT_DISK
		jne	nextEntry

	; edigeron 12/17/00 - if the drive letter = 0, then this entry is
	; for a network drive recently accessed but was never assigned a
	; drive letter. This causes GEOS to create an entry for a drive
	; which just generates errors on any attempt to access it. So, just
	; skip over this drive.
		tst	{word}ds:[si]
		jz	nextEntry

		push	si, bx
EC <		cmp	{char}ds:[si+1], ':'				>
EC <		ERROR_NE	UNEXPECTED_MULTI_CHAR_DRIVE_NAME	>
	;
	; Drive is a fixed network drive that's not formattable, not read-only,
	; available over the net, not busy and not an alias.
	; 
		mov	{char}ds:[si+1], 0
		mov	al, ds:[si]
		sub	al, 'A'		; al <- drive number
		mov	ah, MEDIA_FIXED_DISK
		mov	cx, mask DS_PRESENT or mask DS_NETWORK or DRIVE_FIXED
		clr	bx			; no private data needed
		push	dx		; save FSDriver offset
		call	FSDInitDrive
		pop	dx
		pop	si, bx
nextEntry:
		inc	bx
		jmp	entryLoop
done:
		.leave
		ret
MSNetInitLocateDrives endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetInitClearLocalBits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If machine is running as a server, clear the DES_LOCAL_ONLY
		bits for all local drives, as they might be accessed over
		the network.

CALLED BY:	(INTERNAL) MSNetInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	es, ax, si, bx
SIDE EFFECTS:	see above

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNetInitClearLocalBits proc	near
		.enter
	;
	; Clear the LOCAL_ONLY bit from all drives if server installed
	; 
		mov	ax, MSNET_EXISTENCE_CHECK
		int	2fh
		tst	al		; => no one responded to call
		jz	done

		test	bl, mask MSNIF_SERVER
		jz	done		; => not acting as server, so local
					;  disks can't be seen.
		
		call	FSDLockInfoShared
		mov	es, ax
		mov	si, offset FIH_driveList - offset DSE_next
clearLocalBitLoop:
		mov	si, es:[si].DSE_next
		tst	si
		jz	localBitsCleared
		andnf	es:[si].DSE_status, not mask DES_LOCAL_ONLY
		jmp	clearLocalBitLoop

localBitsCleared:
		call	FSDUnlockInfoShared
done:
		.leave
		ret
MSNetInitClearLocalBits endp
;==============================================================================
;
;			 OPEN FILE TAKE-OVER
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetInitOpenFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate all files in the open-file list that are on drives
		we manage and alter their private data and SFN to our
		liking.

CALLED BY:	MSNetInit
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MSNetInitOpenFiles proc	near
		.enter
		clr	bx			; process entire list
		mov	dx, ds:[fsdOffset]	; pass the offset of our
						;  FSDriver record
		mov	di, cs
		mov	si, offset MSNIOF_callback
		call	FileForEach
		.leave
		ret
MSNetInitOpenFiles endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNIOF_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to initialize file handles that were
		opened with the skeleton FSD.

CALLED BY:	MSNetInitOpenFiles via FileForEach
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
MSNIOF_callback	proc	far
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
		call	MSNetCallPrimary
done:
		clc		; continue processing
		.leave
		ret
MSNIOF_callback	endp

Init		ends

;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*
;
;			    EXIT HANDLING
;
;=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*=*

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MSNetExit
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
MSNetExit	proc	far
		uses	es, di, ax
		.enter
		segmov	es, dgroup, ax
		tst	es:[msnetOldInt28].segment
		jz	done		; => didn't get as far as intercepting
					;  it
		mov	di, offset msnetOldInt28
		mov	ax, 28h
		call	SysResetInterrupt

		mov	di, offset msnetOldInt24
		mov	ax, CRITICAL_VECTOR
		call	SysResetInterrupt
done:
		clc
		.leave
		ret
MSNetExit	endp

Resident	ends
