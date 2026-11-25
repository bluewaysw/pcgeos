COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsWatch.asm

ROUTINES:
	Name			Description
	----			-----------
    EXT	HostFsChangesPending	Handler for HIF_NOTIFY_HOSTFS_CHANGES
    INT	HostFsPollDrive		Notify about the changes on one drive

DESCRIPTION:
	Changes made on the host, outside GEOS.

	The emulator watches the directories GEOS uses and, about once a
	second, queues what changed there: new and deleted entries, and
	files whose contents changed. When changes become pending it sends
	HIF_NOTIFY_HOSTFS_CHANGES; the HostIf library then calls
	HostFsChangesPending on its process thread, which collects the
	queue and generates the matching file-change notifications
	(FCNT_CREATE, FCNT_DELETE, FCNT_CONTENTS).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsChangesPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass changes made on the host to GEOS, for all our drives.
CALLED BY:	HostIf library (HIF_NOTIFY_HOSTFS_CHANGES), on its process
		thread
PASS:		ax	= HIF_NOTIFY_HOSTFS_CHANGES
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, es (allowed)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsChangesPending proc far
		uses	ds
		.enter
		segmov	ds, dgroup, ax
		mov	bx, offset hostfsDrives
		mov	cx, HOSTFS_MAX_DRIVES
driveLoop:
		tst	ds:[bx].HFD_dse
		jz	nextDrive
		tst	ds:[bx].HFD_disk	; GEOS hasn't used it yet:
		jz	nextDrive		;  nothing is watched there
		call	HostFsPollDrive
nextDrive:
		add	bx, size HostFsDrive
		loop	driveLoop
		.leave
		ret
HostFsChangesPending endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsPollDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Collect the host changes queued for one drive and notify
		about each of them.
CALLED BY:	HostFsChangesPending
PASS:		ds:bx	= HostFsDrive
RETURN:		nothing
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsPollDrive	proc	near
frame		local	HostFsFrame
		uses	ax, bx, cx, dx, si, di
		.enter
		mov	dx, ds:[bx].HFD_volume
		mov	si, ds:[bx].HFD_disk
		lea	di, ss:[frame]
pollLoop:
		mov	ax, HFF_POLL_CHANGES
		call	HostFsInitFrame
		mov	ss:[di].HFF_volume, dx
		mov	ss:[di].HFF_disk, si
		push	dx, si
		call	HostFsCallFrame		; ERROR_NO_MORE_FILES when
		pop	dx, si			;  the queue is empty
		jc	done
		call	HostFsSendNotifications
		jmp	pollLoop
done:
		.leave
		ret
HostFsPollDrive	endp

Resident	ends
