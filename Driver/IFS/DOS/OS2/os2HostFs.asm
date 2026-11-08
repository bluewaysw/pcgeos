COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		OS/2 (DOSBox/BASEBOX) IFS Driver
FILE:		os2HostFs.asm

ROUTINES:
	Name			Description
	----			-----------
    INT DOSHostFsInt21		Try to execute a DOS call via the host
    INT OS2HostFsInit		Detect and enable the host FS fast path
    INT OS2HostFsGetDriveParams	Classify a drive using host information
    INT OS2HostFsPollChanges	Collect host file changes, notify GEOS
    EXT OS2HostFsChangesPending	HostIf handler: host changes pending
    INT OS2HostFsShutdown	Unregister the handler (DR_EXIT)

DESCRIPTION:
	BASEBOX host file system fast path.

	When running under pcgeos-basebox, DOS file system calls made
	through DOSUtilInt21 are handed to the emulator as a DOS register
	frame and executed directly by its DOS core. This skips the INT 21h
	dispatch and, in the protected mode kernel, the DPMI host's
	reflection to real mode and the copying through its transfer
	buffer. Handles, current directories and error codes are shared
	with the regular DOS path, so any call the host does not take is
	simply issued as a normal INT 21h.

	Everything here is inert unless HOST_FS_FASTPATH is set and the
	host answers the API check, so the same driver still runs on real
	DOS.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if HOST_FS_FASTPATH

;
; Stack layout of DOSHostFsInt21. The register frame passed to the host
; sits at the bottom, so ss:bp addresses both.
;
HostFsStack	struct
    HFS_frame	HostFsFrame	; passed to the host
    HFS_flags	CPUFlags	; caller's flags, returned via popf
    HFS_bp	word		; caller's bp
HostFsStack	ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSHostFsInt21
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the host execute a DOS call, if it can.

CALLED BY:	DOSUtilInt21 (with the BIOS lock held)
PASS:		registers for the DOS call (ah = function)
RETURN:		ZF set if the host executed the call:
			registers as DOS would return them
			CF as DOS would return it
			ax = extended error code if CF set
		ZF clear if not executed:
			all registers unchanged, CF clear
			-> caller must issue the call through DOS
DESTROYED:	nothing (see above)

PSEUDO CODE/STRATEGY:
	Build a HostFsFrame on the stack from the registers. Reject
	functions the host did not announce at enable time without
	touching the port. Otherwise pass ss:frame to HIF_FS_INT21 and,
	if the host reports success with the magic value, load the
	results back from the frame.

	The 12-word port exchange runs with interrupts off, like
	HostIfCall, so it cannot interleave with another HostIf user.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	11/ 6/26	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSHostFsInt21	proc	near
		push	bp
		pushf
		sub	sp, size HostFsFrame
		mov	bp, sp
	;
	; Save the register image. It doubles as our register save area.
	;
		mov	ss:[bp].HFS_frame.HFF_ax, ax
		mov	ss:[bp].HFS_frame.HFF_bx, bx
		mov	ss:[bp].HFS_frame.HFF_cx, cx
		mov	ss:[bp].HFS_frame.HFF_dx, dx
		mov	ss:[bp].HFS_frame.HFF_si, si
		mov	ss:[bp].HFS_frame.HFF_di, di
		mov	ss:[bp].HFS_frame.HFF_ds, ds
		mov	ss:[bp].HFS_frame.HFF_es, es
		mov	ss:[bp].HFS_frame.HFF_flags, 0
		mov	ss:[bp].HFS_frame.HFF_extErr, 0
	;
	; Cheap reject: is this AH in the map the host gave us? The map is
	; all zeroes if the fast path is not enabled.
	;
		call	LoadVarSegDS
		mov	bl, ah
		mov	cl, bl
		and	cl, 7			; cl <- bit within byte
		shr	bl, 1
		shr	bl, 1
		shr	bl, 1			; bl <- byte index
		clr	bh
		mov	al, ds:hostFsFuncMap[bx]
		shr	al, cl
		test	al, 1
		jz	notHandled
	;
	; Hand ss:bp (the frame) to the host. ax only carries the HostIf
	; status; whether the host executed the call is in bx.
	;
		mov	ax, HIF_FS_INT21
		mov	bx, ss			; bx:cx <- frame
		mov	cx, bp
		mov	dx, size HostFsFrame
		clr	si, di
		call	HostIfCall		; ax <- status, si <- magic,
						;  bx <- outcome
		cmp	ax, HIF_OK
		jne	notHandled
		cmp	si, HOSTFS_MAGIC
		jne	notHandled
		cmp	bx, HOSTFS_EXECUTED
		jne	notHandled
	;
	; Executed. Load the results; on error DOS leaves the error in ax,
	; but DOSUtilInt21's callers want the extended error code, which
	; the host provides directly (no extra INT 21h/59h needed).
	;
		mov	ax, ss:[bp].HFS_frame.HFF_ax
		test	ss:[bp].HFS_frame.HFF_flags, HOSTFS_FRAME_CARRY
		jz	loadRest
		mov	ax, ss:[bp].HFS_frame.HFF_extErr
loadRest:
		mov	bx, ss:[bp].HFS_frame.HFF_bx
		mov	cx, ss:[bp].HFS_frame.HFF_cx
		mov	dx, ss:[bp].HFS_frame.HFF_dx
		mov	si, ss:[bp].HFS_frame.HFF_si
		mov	di, ss:[bp].HFS_frame.HFF_di
		mov	ds, ss:[bp].HFS_frame.HFF_ds
		or	ss:[bp].HFS_flags, mask CPU_ZERO
		test	ss:[bp].HFS_frame.HFF_flags, HOSTFS_FRAME_CARRY
		jz	clearCarry
		or	ss:[bp].HFS_flags, mask CPU_CARRY
		jmp	exit
clearCarry:
		and	ss:[bp].HFS_flags, not mask CPU_CARRY
		jmp	exit

notHandled:
	;
	; The host leaves the frame alone if it does not execute the call,
	; so it still holds the caller's registers.
	;
		mov	ax, ss:[bp].HFS_frame.HFF_ax
		mov	bx, ss:[bp].HFS_frame.HFF_bx
		mov	cx, ss:[bp].HFS_frame.HFF_cx
		mov	dx, ss:[bp].HFS_frame.HFF_dx
		mov	si, ss:[bp].HFS_frame.HFF_si
		mov	di, ss:[bp].HFS_frame.HFF_di
		mov	ds, ss:[bp].HFS_frame.HFF_ds
		and	ss:[bp].HFS_flags, not (mask CPU_ZERO or mask CPU_CARRY)
exit:
		mov	sp, bp
		add	sp, size HostFsFrame	; flags are restored by popf
		popf
		pop	bp
		ret
DOSHostFsInt21	endp

Resident	ends


Init		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2HostFsInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Detect the BASEBOX FS sub-API and enable the fast path.

CALLED BY:	OS2Init
PASS:		ds	= dgroup, with pspSegment already set
RETURN:		hostFsAvail set if the fast path is active
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	HostIfDetect for HIF_API_FS: the host answers with the ID
	"XOBESAB2" and the sub-API version. On real hardware the port
	reads back 0FFFFh and the ID check fails.

	HIF_FS_ENABLE registers our PSP (the host only serves this
	process) and has the host fill hostFsFuncMap with the DOS
	functions it executes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	11/ 6/26	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2HostFsInit	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		.enter
	;
	; Is this BASEBOX, and does it have the FS sub-API?
	;
		mov	ax, HIF_API_FS
		call	HostIfDetect		; ax <- sub-API version, 0 if none
		cmp	ax, HOSTFS_API_VERSION
		jb	done
	;
	; Enable it.
	;
		mov	ax, HIF_FS_ENABLE
		mov	si, ds:[pspSegment]
		mov	bx, ds			; bx:cx <- function map
		mov	cx, offset hostFsFuncMap
		mov	dx, HOSTFS_FUNC_MAP_SIZE
		mov	di, HOSTFS_OPT_FILE_NOTIFY ; watch for host file changes
		call	HostIfCall		; ax <- status, si <- magic,
						;  cx <- drive generation
		cmp	ax, HIF_OK
		jne	done
		cmp	si, HOSTFS_MAGIC
		jne	done
		mov	ds:[hostFsGeneration], cx
		mov	ds:[hostFsAvail], BB_TRUE
	;
	; Have the HostIf library call us when host file changes are pending,
	; then collect anything queued already.
	;
		mov	ax, HIF_NOTIFY_FS_CHANGES
		mov	cx, segment OS2HostFsChangesPending
		mov	dx, offset OS2HostFsChangesPending
		call	HostIfRegisterNotify
		call	OS2HostFsChangesPending	; far: we're in Init
done:
		.leave
		ret
OS2HostFsInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2HostFsGetDriveParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Classify a drive from the host's drive table.

CALLED BY:	OS2CreateDrive
PASS:		bx	= drive number (0-origin)
		ds	= dgroup
RETURN:		carry clear if the host knows the drive:
			cx	= DriveExtendedStatus
			ah	= MediaType
			al	= DDPDFlags
			dx	= sector size
		carry set if the DOS-based detection should be used
DESTROYED:	ax, cx, dx (if carry set)

PSEUDO CODE/STRATEGY:
	Only non-removable host directory mounts and FAT images are
	classified here. Those are what the IOCTL-based detection cannot
	identify under DOSBox (they end up as DRIVE_UNKNOWN). Missing
	drives, floppies, CD-ROMs and the Z: drive keep their existing
	detection, so the visible drive set does not change.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	FR	11/ 6/26	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2HostFsGetDriveParams	proc	near
		uses	bx, si, di
		.enter
		tst	ds:[hostFsAvail]
		jz	noInfo

		mov	ax, HIF_FS_GET_DRIVE_INFO
		mov	si, bx			; si <- drive
		clr	bx, cx, dx, di
		call	HostIfCall		; ax <- status, si <- flags,
						;  bx <- kind, cx <- sector size
		cmp	ax, HIF_OK
		jne	noInfo
		mov	di, cx			; di <- bytes per sector
		test	si, mask HFDF_REMOVABLE
		jnz	noInfo
		cmp	bx, HOSTFS_DRIVE_LOCAL
		je	fixedDisk
		cmp	bx, HOSTFS_DRIVE_FAT
		jne	noInfo
fixedDisk:
		mov	cx, DRIVE_FIXED or mask DS_PRESENT
		test	si, mask HFDF_REMOTE
		jz	haveStatus
		or	cx, mask DS_NETWORK
haveStatus:
		mov	ax, MEDIA_FIXED_DISK shl 8	; al = no DDPDFlags
		mov	dx, di
		tst	dx
		jnz	haveSize
		mov	dx, MSDOS_STD_SECTOR_SIZE
haveSize:
		clc
		jmp	done
noInfo:
		stc
done:
		.leave
		ret
OS2HostFsGetDriveParams	endp

Init		ends


Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2HostFsChangesPending
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pass changes made on the host to GEOS.
CALLED BY:	HostIf library (HIF_NOTIFY_FS_CHANGES), on its process thread
PASS:		ax	= HIF_NOTIFY_FS_CHANGES
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, si, di, bp, es (allowed)

PSEUDO CODE/STRATEGY:
	The emulator watches the DOS directories GEOS uses through the
	fast path and queues what changed on the host: new and deleted
	entries, and files whose contents changed. Its IDs are computed
	the way DOSFileChangeCalculateID does, so the notifications match
	the ones this driver generates itself. It also adds new host
	files to DOSBox's directory cache, so DOS can see them at all.
	When changes become pending it sends HIF_NOTIFY_FS_CHANGES; we
	collect them all here.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2HostFsChangesPending proc far
		call	OS2HostFsPollChanges
		ret
OS2HostFsChangesPending endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2HostFsPollChanges
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Collect the host changes the emulator queued and notify
		about each of them.
CALLED BY:	OS2HostFsInit, OS2HostFsChangesPending
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2HostFsPollChanges proc near
nameBuf		local	FILE_LONGNAME_BUFFER_SIZE dup(char)
		uses	ax, bx, cx, dx, si, di, ds
		.enter
pollLoop:
		mov	ax, HIF_FS_POLL_CHANGES
		mov	bx, ss			; bx:cx <- name buffer
		lea	cx, ss:[nameBuf]
		mov	dx, size nameBuf
		clr	si, di
		call	HostIfCall		; ax <- HIF_OK if a change:
		tst	ax			;  si = type, bx = drive,
		jnz	done			;  cx:dx = ID
	;
	; Find the disk in that drive (registering it if GEOS hasn't seen
	; it yet; it's a fixed DOSBox drive, so nothing is asked).
	;
		push	si			; type
		mov	al, bl
		call	DiskRegisterDiskSilently ; bx <- disk handle
		pop	ax			; ax <- type
		jc	pollLoop		; drive gone: skip it
		mov	si, bx
		segmov	ds, ss			; ds:bx <- name
		lea	bx, ss:[nameBuf]
		call	FSDGenerateNotify
		jmp	pollLoop
done:
		.leave
		ret
OS2HostFsPollChanges endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OS2HostFsShutdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop being called for host file changes.
CALLED BY:	OS2Exit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OS2HostFsShutdown proc	near
		uses	ax, cx, dx, ds
		.enter
		segmov	ds, dgroup, ax
		tst	ds:[hostFsAvail]
		jz	done
		mov	ax, HIF_NOTIFY_FS_CHANGES
		mov	cx, segment OS2HostFsChangesPending
		mov	dx, offset OS2HostFsChangesPending
		call	HostIfUnregisterNotify
done:
		.leave
		ret
OS2HostFsShutdown endp

Resident	ends

endif	; HOST_FS_FASTPATH
