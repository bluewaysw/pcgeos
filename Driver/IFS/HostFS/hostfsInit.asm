COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsInit.asm

ROUTINES:
	Name			Description
	----			-----------
    EXT	HostFSInit		DR_INIT: find the host, register the drive
    EXT	HostFSExit		DR_EXIT

DESCRIPTION:
	Initialization and exit.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Init	segment	resource

hostfsKeyStr	char	'hostfs', 0
drivesKeyStr	char	'drives', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we run under BASEBOX, register ourselves and
		create a drive for each host directory listed in GEOS.INI.
CALLED BY:	DR_INIT
PASS:		nothing
RETURN:		carry set if we can't run (the driver is unloaded again)
DESTROYED:	ax, bx, cx, dx, si, di, ds, es

PSEUDO CODE/STRATEGY:
	HostIfDetect for HIF_API_HOSTFS: 0 on real hardware.
	HIF_HOSTFS_INIT drops anything mounted by a previous session.
	Then every line of [hostfs] drives = { NAME=HOST PATH ... } is
	mounted by the host (which validates the path) and becomes a
	drive. With no drive configured we fail, so we're unloaded.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	11/ 6/26	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSInit	proc	far
		.enter
	;
	; Is this BASEBOX, and does it have the host file system?
	;
		mov	ax, HIF_API_HOSTFS
		call	HostIfDetect		; ax <- sub-API version, 0 if none
		cmp	ax, HOSTFS_API_VERSION
		jb	fail
	;
	; Start from a clean slate on the host.
	;
		mov	ax, HIF_HOSTFS_INIT
		clr	si, bx, cx, dx, di
		call	HostIfCall
		cmp	ax, HIF_OK
		jne	fail
		cmp	si, HOSTFS_MAGIC
		jne	fail
	;
	; Register ourselves, so the drives have an FSD to point to.
	;
		mov	cx, segment HostFSStrategy
		mov	dx, offset HostFSStrategy
		mov	ax, FSD_FLAGS
		mov	bx, handle 0
		clr	di			; no private data with disks
		call	FSDRegister
		segmov	ds, dgroup, ax
		mov	ds:[hostfsFSD], dx
	;
	; Mount the configured drives.
	;
		segmov	ds, cs, cx
		mov	si, offset hostfsKeyStr	; ds:si <- category
		mov	dx, offset drivesKeyStr	; cx:dx <- key
		mov	di, cs
		mov	ax, offset HostFSInitDriveCallback
		clr	bx			; bx <- drives so far
		push	bp
		mov	bp, IFCC_INTACT shl offset IFRF_CHAR_CONVERT
		call	InitFileEnumStringSection
		pop	bp
		tst	bx
		jz	noDrives
	;
	; Have the HostIf library call us when host file changes are pending.
	;
		mov	ax, HIF_NOTIFY_HOSTFS_CHANGES
		mov	cx, segment HostFsChangesPending
		mov	dx, offset HostFsChangesPending
		call	HostIfRegisterNotify
		clc
done:
		.leave
		ret

noDrives:
		segmov	ds, dgroup, ax
		mov	dx, ds:[hostfsFSD]
		call	FSDUnregister
fail:
		stc
		jmp	done
HostFSInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSInitDriveCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mount one line of [hostfs] drives and create its drive.
CALLED BY:	HostFSInit via InitFileEnumStringSection
PASS:		ds:si	= the line ("NAME=HOST PATH", null-terminated)
		cx	= its length
		bx	= number of drives created so far
RETURN:		bx	= number of drives created so far
		carry clear (continue), set to stop when the table is full
DESTROYED:	ax, cx, dx, di, si, bp, ds, es

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSInitDriveCallback proc far
		cmp	bx, HOSTFS_MAX_DRIVES
		jae	full
		jcxz	done			; empty line
	;
	; Have the host check and mount the directory. It writes the drive
	; name into our table entry.
	;
		push	bx
		mov	ax, size HostFsDrive
		mul	bx
		mov	di, ax
		add	di, offset hostfsDrives	; dgroup:di <- our entry
		push	di
		mov	bx, ds			; bx:cx <- line
		mov	cx, si
		mov	dx, segment dgroup	; dx:di <- name buffer
		add	di, offset HFD_name
		mov	si, DRIVE_NAME_MAX_LENGTH
		mov	ax, HIF_HOSTFS_MOUNT
		call	HostIfCall		; si <- volume, cx:dx <- root ID
		pop	di
		tst	ax
		jnz	skip			; host logged why
		segmov	ds, dgroup, ax
		mov	ds:[di].HFD_volume, si
		mov	ds:[di].HFD_rootId.high, cx
		mov	ds:[di].HFD_rootId.low, dx
	;
	; Create the drive. It is writable: no DES_READ_ONLY.
	;
		mov	al, -1			; next free drive number
		mov	ah, MEDIA_FIXED_DISK
		mov	cx, HOSTFS_DRIVE_STATUS
		mov	dx, ds:[hostfsFSD]
		lea	si, ds:[di].HFD_name
		push	di
		call	FSDInitDrive		; dx <- DriveStatusEntry
		pop	di
		segmov	ds, dgroup, ax
		mov	ds:[di].HFD_dse, dx
		pop	bx
		inc	bx
		jmp	done
skip:
		pop	bx
done:
		clc
		ret
full:
		stc
		ret
HostFSInitDriveCallback endp

Init	ends


Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish with the filesystem: stop being called for host
		changes. The host closes any files still open when the
		volumes are set up again on the next start.
CALLED BY:	DR_EXIT
PASS:		nothing
RETURN:		carry clear
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSExit	proc	far
		uses	ax, cx, dx
		.enter
		mov	ax, HIF_NOTIFY_HOSTFS_CHANGES
		mov	cx, segment HostFsChangesPending
		mov	dx, offset HostFsChangesPending
		call	HostIfUnregisterNotify
		clc
		.leave
		ret
HostFSExit	endp

Resident	ends
