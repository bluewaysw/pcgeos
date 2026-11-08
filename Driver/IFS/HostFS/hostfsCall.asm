COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsCall.asm

ROUTINES:
	Name			Description
	----			-----------
    INT	HostFsInitFrame		Clear a frame and set its function
    INT	HostFsCallFrame		Have the host execute a frame
    INT	HostFsCurDirId		ID of the thread's current directory
    INT	HostFsFindDrive		Our table entry for a DriveStatusEntry
    INT	HostFsPrepDisk		Store disk context in a frame
    INT	HostFsPrepPath		Store a path and its context in a frame
    INT	HostFsSendNotifications	Generate the notifications a frame asks for
    INT	HostFsNotifyOpenClose	FCNT_OPEN / FCNT_CLOSE, if enabled

DESCRIPTION:
	Talking to the host.

	A request is a HostFsFrame on the caller's stack. Callers do:
		lea	di, ss:[frame]
		mov	ax, HFF_xxx
		call	HostFsInitFrame
		...fill in inputs...
		call	HostFsCallFrame		; carry/ax = result
		...read outputs from ss:[di]...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsInitFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear a request frame and set its function.
CALLED BY:	INTERNAL
PASS:		ss:di	= HostFsFrame
		ax	= HostFsFunction
RETURN:		frame cleared, HFF_func set
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsInitFrame	proc	near
		uses	ax, cx, di, es
		.enter
		push	ax
		segmov	es, ss
		mov	cx, size HostFsFrame
		clr	al
		rep	stosb
		pop	ax
		.leave
		mov	ss:[di].HFF_func, ax
		ret
HostFsInitFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsCallFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the host execute a request frame.
CALLED BY:	INTERNAL
PASS:		ss:di	= HostFsFrame, inputs filled in
RETURN:		carry clear if successful (outputs in the frame)
		carry set on error:
			ax	= FileError
DESTROYED:	ax, bx, cx, dx, si

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsCallFrame	proc	near
		push	di
		mov	bx, ss			; bx:cx <- frame
		mov	cx, di
		mov	dx, size HostFsFrame
		mov	ax, HIF_HOSTFS_CALL
		clr	si, di
		call	HostIfCall		; serialized by the library
		pop	di
		tst	ax
		jnz	portFailed
		mov	ax, ss:[di].HFF_result
		tst	ax
		jnz	failed
		clc
		ret
portFailed:
		mov	ax, ERROR_GENERAL_FAILURE
failed:
		stc
		ret
HostFsCallFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsCurDirId
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the host ID of the thread's current directory and
		its DirPathInfo.
CALLED BY:	INTERNAL
PASS:		nothing (only meaningful if the current path is on our
		drive, which the kernel guarantees for relative paths)
RETURN:		dx:ax	= directory ID
		cx	= DirPathInfo
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsCurDirId	proc	near
		uses	bx, ds
		.enter
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	ds, ax
		mov	cx, ds:[FP_pathInfo]
		mov	ax, ({HostFsPathPrivate}ds:[FP_private]).HFPP_dirId.low
		mov	dx, ({HostFsPathPrivate}ds:[FP_private]).HFPP_dirId.high
		call	MemUnlock
		.leave
		ret
HostFsCurDirId	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsPrepDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the host volume, disk handle and drive status in a
		frame (the latter two for FEA_DISK and FEA_DRIVE_STATUS).
CALLED BY:	INTERNAL
PASS:		ss:di	= HostFsFrame
		es:si	= DiskDesc
RETURN:		HFF_volume, HFF_disk, HFF_driveStatus set
		(HFF_volume = -1 if the drive isn't ours: the host fails)
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsPrepDisk	proc	near
		uses	ax, bx, ds
		.enter
		mov	ss:[di].HFF_disk, si
		mov	bx, es:[si].DD_drive
		mov	ax, es:[bx].DSE_status
		mov	ss:[di].HFF_driveStatus, ax
		mov	ax, -1
		call	HostFsFindDrive		; ds:bx <- our entry
		jc	haveVolume
		mov	ds:[bx].HFD_disk, si	; for host change notifications
		mov	ax, ds:[bx].HFD_volume
haveVolume:
		mov	ss:[di].HFF_volume, ax
		.leave
		ret
HostFsPrepDisk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsFindDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find our table entry for a drive.
CALLED BY:	INTERNAL
PASS:		bx	= DriveStatusEntry offset
RETURN:		carry clear if found:
			ds:bx	= HostFsDrive
		carry set if not one of ours
DESTROYED:	nothing else

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsFindDrive	proc	near
		uses	ax, cx
		.enter
		segmov	ds, dgroup, ax
		mov	ax, bx
		mov	bx, offset hostfsDrives
		mov	cx, HOSTFS_MAX_DRIVES
findLoop:
		tst	ds:[bx].HFD_dse
		jz	next
		cmp	ds:[bx].HFD_dse, ax
		je	found
next:
		add	bx, size HostFsDrive
		loop	findLoop
		stc
		jmp	done
found:
		clc
done:
		.leave
		ret
HostFsFindDrive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsPrepPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store a path and its context in a frame.
CALLED BY:	INTERNAL
PASS:		ss:di	= HostFsFrame
		ds:dx	= path (absolute if it starts with a backslash,
			  else relative to the thread's current directory)
		es:si	= DiskDesc
RETURN:		HFF_ds, HFF_dx, HFF_dirId, HFF_pathInfo, HFF_disk,
		HFF_driveStatus set
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsPrepPath	proc	near
		uses	ax, bx, cx, dx
		.enter
		mov	ss:[di].HFF_ds, ds
		mov	ss:[di].HFF_dx, dx
		call	HostFsPrepDisk
		mov	bx, dx
		push	ds:[bx]			; first character
		call	HostFsCurDirId		; dx:ax <- dir, cx <- path info
		mov	ss:[di].HFF_pathInfo, cx
		pop	bx
		cmp	bl, C_BACKSLASH
		je	done			; absolute: HFF_dirId stays 0
		mov	ss:[di].HFF_dirId.low, ax
		mov	ss:[di].HFF_dirId.high, dx
done:
		.leave
		ret
HostFsPrepPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsSendNotifications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate the file-change notifications the host asked for.
CALLED BY:	INTERNAL, after a successful HostFsCallFrame
PASS:		ss:di	= HostFsFrame (HFF_disk set by HostFsPrepDisk)
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsSendNotifications	proc	near
		uses	ax, bx, cx, dx, si, ds
		.enter
		pushf
		mov	si, ss:[di].HFF_disk	; si <- disk handle
		segmov	ds, ss			; ds:bx <- name, if any
		mov	ax, ss:[di].HFF_notifyType
		tst	ax
		jz	second
		dec	ax
		mov	cx, ss:[di].HFF_notifyId.high
		mov	dx, ss:[di].HFF_notifyId.low
		lea	bx, ss:[di].HFF_notifyName
		call	FSDGenerateNotify
second:
		mov	ax, ss:[di].HFF_notify2Type
		tst	ax
		jz	done
		dec	ax
		mov	cx, ss:[di].HFF_notify2Id.high
		mov	dx, ss:[di].HFF_notify2Id.low
		lea	bx, ss:[di].HFF_notifyName
		call	FSDGenerateNotify
done:
		popf
		.leave
		ret
HostFsSendNotifications	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsNotifyOpenClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate FCNT_OPEN or FCNT_CLOSE if someone asked for them.
CALLED BY:	HostFSAllocOp, HostFSHandleOp
PASS:		ax	= FCNT_OPEN or FCNT_CLOSE
		cx:dx	= file ID
		si	= disk handle
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsNotifyOpenClose	proc	near
		uses	ax, bx, cx, dx
		.enter
		pushf
		call	FSDCheckOpenCloseNotifyEnabled
		jnc	done
		call	FSDGenerateNotify	; no name needed
done:
		popf
		.leave
		ret
HostFsNotifyOpenClose	endp

Resident	ends
