COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsDisk.asm

ROUTINES:
	Name			Description
	----			-----------
    EXT	HostFSDiskID		DR_FS_DISK_ID
    EXT	HostFSDiskInit		DR_FS_DISK_INIT
    EXT	HostFSDiskInfo		DR_FS_DISK_INFO
    EXT	HostFSDiskFindFree	DR_FS_DISK_FIND_FREE
    EXT	HostFSDiskSave		DR_FS_DISK_SAVE
    INT	HostFsGetVolumeName	Copy the volume name

DESCRIPTION:
	Each of our drives holds one always present, writable "disk".

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsGetVolumeName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a drive's name as volume name, space-padded to
		VOLUME_NAME_LENGTH.
CALLED BY:	HostFSDiskInit, HostFSDiskInfo
PASS:		es:di	= buffer for VOLUME_NAME_LENGTH chars
		bx	= DriveStatusEntry offset
RETURN:		es:di	= after the name
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsGetVolumeName proc near
		uses	ax, bx, cx, si, ds
		.enter
		call	HostFsFindDrive		; ds:bx <- our entry
		lea	si, ds:[bx].HFD_name
		jnc	haveName
		segmov	ds, cs
		mov	si, offset unknownName
haveName:
		mov	cx, VOLUME_NAME_LENGTH
copyLoop:
		lodsb
		tst	al
		jnz	storeIt
		dec	si			; stay on the null
		mov	al, ' '
storeIt:
		stosb
		loop	copyLoop
		.leave
		ret
HostFsGetVolumeName endp

unknownName	char	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSDiskID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Identify the disk in one of our drives.
CALLED BY:	DR_FS_DISK_ID
PASS:		es:si	= DriveStatusEntry
RETURN:		carry clear
			cx:dx	= 32-bit disk ID (the root directory ID)
			al	= DiskFlags
			ah	= MediaType
		carry set if the drive isn't ours
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSDiskID	proc	far
		uses	bx, ds
		.enter
		mov	bx, si
		call	HostFsFindDrive		; ds:bx <- our entry
		jc	done
		mov	cx, ds:[bx].HFD_rootId.high
		mov	dx, ds:[bx].HFD_rootId.low
		mov	ax, mask DF_ALWAYS_VALID or mask DF_WRITABLE or \
				(MEDIA_FIXED_DISK shl 8)
		clc
done:
		.leave
		ret
HostFSDiskID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSDiskInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the volume label of a new DiskDesc.
CALLED BY:	DR_FS_DISK_INIT
PASS:		es:si	= DiskDesc
RETURN:		carry clear
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSDiskInit	proc	far
		uses	bx, di
		.enter
		mov	bx, es:[si].DD_drive
		lea	di, es:[si].DD_volumeLabel
		call	HostFsGetVolumeName
		clc
		.leave
		ret
HostFSDiskInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return information about the disk.
CALLED BY:	DR_FS_DISK_INFO
PASS:		bx:cx	= DiskInfoStruct to fill
		es:si	= DiskDesc
RETURN:		carry set on error (ax = FileError)
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSDiskInfo	proc	far
frame		local	HostFsFrame
		uses	bx, cx, dx, si, di, es
		.enter
		push	bx, cx			; DiskInfoStruct
		lea	di, ss:[frame]
		mov	ax, HFF_DISK_INFO
		call	HostFsInitFrame
		call	HostFsPrepDisk
		mov	ax, es:[si].DD_drive
		push	ax
		call	HostFsCallFrame
		pop	dx			; dx <- DriveStatusEntry
		pop	es, bx			; es:bx <- DiskInfoStruct
		jc	done
		mov	es:[bx].DIS_blockSize, 512
		mov	ax, ss:[di].HFF_ax
		mov	es:[bx].DIS_freeSpace.low, ax
		mov	ax, ss:[di].HFF_dx
		mov	es:[bx].DIS_freeSpace.high, ax
		mov	ax, ss:[di].HFF_bx
		mov	es:[bx].DIS_totalSpace.low, ax
		mov	ax, ss:[di].HFF_cx
		mov	es:[bx].DIS_totalSpace.high, ax
		lea	di, es:[bx].DIS_name
		mov	bx, dx
		call	HostFsGetVolumeName
		mov	{char}es:[di], 0
		clc
done:
		.leave
		ret
HostFSDiskInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSDiskFindFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the free space on the disk.
CALLED BY:	DR_FS_DISK_FIND_FREE
PASS:		es:si	= DiskDesc
RETURN:		carry clear: dx:ax = bytes free
		carry set: ax = FileError
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSDiskFindFree proc	far
frame		local	HostFsFrame
		uses	bx, cx, si, di
		.enter
		lea	di, ss:[frame]
		mov	ax, HFF_DISK_INFO
		call	HostFsInitFrame
		call	HostFsPrepDisk
		call	HostFsCallFrame
		jc	done
		mov	ax, ss:[di].HFF_ax
		mov	dx, ss:[di].HFF_dx
done:
		.leave
		ret
HostFSDiskFindFree endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSDiskSave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nothing to save: there is only one disk.
CALLED BY:	DR_FS_DISK_SAVE
RETURN:		cx = 0, carry clear
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSDiskSave	proc	far
		clr	cx			; clears carry
		ret
HostFSDiskSave	endp

Resident	ends
