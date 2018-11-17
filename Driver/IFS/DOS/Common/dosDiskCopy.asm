COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	DOS Primary IFS Drivers
MODULE:		Disk Copying
FILE:		driDiskCopy.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	Implementation of disk copying.
		

	$Id: dosDiskCopy.asm,v 1.1 97/04/10 11:55:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DiskCopyCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyLockInfoShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock the FSIR for shared access and remember it's locked

CALLED BY:	(INTERNAL)
PASS:		ds	= DiskCopyData
RETURN:		es	= FSInfoResource
DESTROYED:	nothing
SIDE EFFECTS:	ds:[DCD_status].DCS_FSIR_LOCKED set

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyLockInfoShared proc	near
		uses	ax
		.enter
		call	FSDLockInfoShared
		mov	es, ax
		ornf	ds:[DCD_status], mask DCS_FSIR_LOCKED
		.leave
		ret
DOSDiskCopyLockInfoShared endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyUnlockInfoShared
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release shared access to the FSIR and remember it's no
		longer locked

CALLED BY:	(INTERNAL)
PASS:		ds	= DiskCopyData
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	ds:[DCD_status].DCS_FSIR_LOCKED cleared

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyUnlockInfoShared proc	near
		.enter
		pushf
EC <		test	ds:[DCD_status], mask DCS_FSIR_LOCKED	>
EC <		ERROR_Z	GASP_CHOKE_WHEEZE			>
		call	FSDUnlockInfoShared
		andnf	ds:[DCD_status], not mask DCS_FSIR_LOCKED
		popf
		.leave
		ret
DOSDiskCopyUnlockInfoShared endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy an entire disk from one drive to another (or the same
		drive, actually)

CALLED BY:	DR_FS_DISK_COPY
PASS:		ss:bx	= FSCopyArgs
RETURN:		carry set on error:
			ax	= FormatError/DiskCopyError
		carry clear on success:
			ax	= 0
DESTROYED:	di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopy	proc	far
		uses	bx, cx, dx, si, ds, es
		.enter
	;
	; Allocate the workspace we need. This copies the FSCopyArgs in
	; 
		call	DOSDiskCopyAllocWorkspace
		jc	exit
	;
	; Lock the two drives for exclusive access. Sets DCD_status,
	; DCD_realSource, and DCD_realDest, coping with drive aliases
	; 
		call	DOSDiskCopyLockDrives
	;
	; Lock the source disk in its drive. This should just be a formality,
	; but it's good to be safe. Who knows what auto-save might have done
	; before we could lock the drive.
	; 
		call	DOSDiskCopyLockInfoShared
		mov	si, ds:[DCD_args].FSCA_disk
		clr	al		; lock abort allowed
		call	DOSDiskLock
		mov	ax, ERR_OPERATION_CANCELLED
		jc	cleanup
	;
	; Make sure we are using the right physical source drive
	; (the disk lock above asserts the logical source drive
	; if it is an alias)
	;
		mov	di, ds:[DCD_realSource]
		cmp	di, ds:[DCD_args].FSCA_source
		je	notAlias
		clr	bx
		mov	bl, es:[di].DSE_number	; bx = physical drive number
		inc	bx			; 1-based
		mov	ax, MSDOS_SET_LOGICAL_DRIVE_MAP
		call	DOSUtilInt21
notAlias:
	;
	; Read the boot sector in to get the actual disk geometry, rather
	; than relying on our tables.
	; Initializes DCD_bpb, DCD_numClusters, DCD_clusterSize, DCD_bufferSize,
	; DCD_rootDirSize
	; 
		call	DOSDiskCopyGetDiskGeometry
		jc	cleanup
	;
	; Read in the FAT of the source disk and figure how many used clusters
	; there are on the disk. This will govern how much stuff we allocate
	; 
		call	DOSDiskCopyReadSourceFAT
		jc	cleanup
	;
	; Release the FSIR before we try to allocate the buffers.
	; 
		call	DOSDiskCopyUnlockInfoShared
	;
	; Allocate all the buffers we'll need or are willing to allow ourselves.
	; 
		call	DOSDiskCopyAllocBuffers
		jc	cleanup
	;
	; Now loop, reading and writing things.
	; 
		call	DOSDiskCopyCopyDisk
cleanup:
		call	DOSDiskCopyCleanUp
exit:
		.leave
		ret
DOSDiskCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyAllocWorkspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate room in which we can work.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ss:bx	= FSCopyArgs
RETURN:		carry set on error:
			ax	= DiskCopyError
			ds	= preserved
		carry clear on success:
			ds	= DiskCopyData
			ax	= destroyed
DESTROYED:	bx, ax, cx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyAllocWorkspace proc	near
		.enter
	;
	; Try and allocate the room we need. No point in allocating it
	; dynamic, as we need it locked the entire time. Do initialize it
	; to zero, though.
	; 
		mov	si, bx
		mov	ax, size DiskCopyData
		mov	cx, ALLOC_FIXED or (mask HAF_ZERO_INIT shl 8)
		call	MemAlloc
		jc	noMem
	;
	; Copy the FSCopyArgs into the workspace after saving its handle
	; away.
	; 
		mov	es, ax
		mov	es:[DCD_handle], bx
		segmov	ds, ss
		mov	di, offset DCD_args
		mov	cx, size FSCopyArgs
		rep	movsb
		mov	ds, ax		; ds <- workspace
done:
		.leave
		ret
noMem:
		mov	ax, ERR_DISKCOPY_INSUFFICIENT_MEM
		jmp	done
DOSDiskCopyAllocWorkspace endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyLockDrives
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lock both drives for exclusive access, being careful
		of aliases.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ds	= DiskCopyData
RETURN:		ds:[DCD_status], ds:[DCD_realSource], ds:[DCD_realDest]
DESTROYED:	es, ax, si, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyLockDrives proc	near
		.enter
		call	DOSDiskCopyLockInfoShared
		mov	si, ds:[DCD_args].FSCA_source
		mov	di, ds:[DCD_args].FSCA_dest
		
	;
	; Lock both drives. Because any alias lock is a thread lock, not a
	; semaphore, we don't need to worry about deadlocking on ourselves.
	; XXX: Perhaps we ought to do this in the kernel, then...
	; 
		call	FSDLockDriveExcl
		xchg	si, di

		cmp	si, di
		je	haveRealSourceAndDest

		call	FSDLockDriveExcl

	;
	; Now deal with the two drives being an alias for the same physical
	; drive. We can check this by comparing their DDPD_aliasLock fields.
	; If they match, they are really the same drive. If either drive
	; is managed by some FSD other than us, we don't worry about
	; aliases.
	; 
		mov	bx, es:[si].DSE_fsd
		cmp	es:[bx].FSD_handle, handle 0
		jne	haveRealSourceAndDest

		mov	bx, es:[si].DSE_private		; bx <- dst drive
							;  private data
		tst	bx
		jz	haveRealSourceAndDest
		mov	ax, es:[bx].DDPD_aliasLock
		
		mov	bx, es:[di].DSE_fsd
		cmp	es:[bx].FSD_handle, handle 0
		jne	haveRealSourceAndDest

		mov	bx, es:[di].DSE_private		; bx <- src drive
							;  private data
		tst	bx
		jz	haveRealSourceAndDest
		cmp	ax, es:[bx].DDPD_aliasLock	; same drive?
		jne	haveRealSourceAndDest		; no

		tst	ax				; is either an alias?
		jz	haveRealSourceAndDest		; no
	;
	; Use the one whose number is the physical drive, so we can use BIOS
	; when we need to. We assume the one with the lower number is the actual
	; drive.
	; 
		mov	bl, es:[di].DSE_number		; bl <- src drive #
		cmp	bl, es:[si].DSE_number		; lower than dest?
		jb	setAliasDrive			; yes

		xchg	di, si
		mov	bl, es:[di].DSE_number
setAliasDrive:
	    ;
	    ; es:di = physical drive
	    ; bl = physical drive #
	    ; Tell DOS of our choice.
	    ; 
		clr	bh
		inc	bx			; 1-origin
		mov	ax, MSDOS_SET_LOGICAL_DRIVE_MAP
		call	DOSUtilInt21
		mov	si, di			; make realDest match realSource

haveRealSourceAndDest:
	;
	; Store the DCD_realSource and DCD_realDest values upon which we've
	; decided.
	; 
		mov	ds:[DCD_realSource], di
		mov	ds:[DCD_realDest], si
	;
	; If they're the same drive, set DCS_SINGLE_DRIVE in DCD_status
	; 
		mov	al, mask DCS_DRIVES_LOCKED or mask DCS_FSIR_LOCKED
		cmp	si, di
		jne	setStatus
		ornf	al, mask DCS_SINGLE_DRIVE
setStatus:
		mov	ds:[DCD_status], al

		call	DOSDiskCopyUnlockInfoShared
		.leave
		ret
DOSDiskCopyLockDrives endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyGetDiskGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the boot sector for the source disk and calculate the
		geometry of the disk.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ds	= DiskCopyData
		es	= FSInfoResource
RETURN:		carry set on error:
			ax	= DiskCopyError
		carry clear if ok:
			ax	= destroyed
			ds:[DCD_bpb], ds:[DCD_numClusters],
			ds:[DCD_clusterSize], ds:[DCD_bufferSize], and
			ds:[DCD_rootDirSize], ds:[DCD_startFiles],
			ds:[DCD_fatSize] set
DESTROYED:	ax, bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyGetDiskGeometry proc	near
		.enter
	;
	; Read the boot sector for the disk.
	; 
		mov	si, ds:[DCD_realSource]
		push	ds
		call	DOSDiskReadBootSectorFar
		pop	es
		jc	fail
	;
	; Copy the BiosParamBlock from the boot sector to our storage area.
	; 
		mov	si, offset BS_bpbSectorSize
		mov	cx, size BiosParamBlock
		mov	di, offset DCD_bpb
		rep	movsb
		call	DOSDiskReleaseBootSector
		segmov	ds, es		; ds <- DiskCopyData again
	;
	; Now calculate things. First figure the number of bytes in the
	; root directory.
	; 
		mov	ax, size RootDirEntry
		mul	ds:[DCD_bpb].BPB_numRootDirEntries
		mov	ds:[DCD_rootDirSize], ax
	;
	; Use that to calculate the number of sectors in the root dir so we
	; can figure the start of the files area.
	; 
		div	ds:[DCD_bpb].BPB_sectorSize
		tst	dx
		jz	haveNumRootDirSectors
		inc	ax
haveNumRootDirSectors:
		add	ax, ds:[DCD_bpb].BPB_numReservedSectors
		mov_tr	cx, ax		; save root dir + boot #
		
		mov	ax, ds:[DCD_bpb].BPB_sectorsPerFAT
		mov	dl, ds:[DCD_bpb].BPB_numFATs
		clr	dh
		mul	dx		; dxax <- # FAT sectors
		add	ax, cx		; ax <- # non-files sectors
		mov	ds:[DCD_startFiles], ax
	;
	; Figure the size of a cylinder in bytes so we can set it as the
	; buffer size to use.
	; 
		mov	ax, ds:[DCD_bpb].BPB_sectorSize
		mul	ds:[DCD_bpb].BPB_sectorsPerTrack
		mul	ds:[DCD_bpb].BPB_numHeads
		mov	ds:[DCD_bufferSize], ax
	;
	; Figure the size of a cluster, in bytes.
	; 
		mov	al, ds:[DCD_bpb].BPB_clusterSize
		clr	ah
		mov	cx, ax				; save cluster size
							;  for figuring # clust
		mul	ds:[DCD_bpb].BPB_sectorSize
		mov	ds:[DCD_clusterSize], ax
	;
	; Figure the number of clusters on the disk.
	; 
		mov	ax, ds:[DCD_bpb].BPB_numSectors
		sub	ax, ds:[DCD_startFiles]	; ax <- # sectors for files
		clr	dx
		div	cx			; ax <- # clusters (no
						;  rounding, as any partial
						;  cluster at the end can't be
						;  used as a cluster)
		inc	ax		; account for 2 reserved clusters
		inc	ax		;  at the very start
		mov	ds:[DCD_numClusters], ax
	;
	; Decide if it uses a 12-bit or 16-bit FAT, based on the number of
	; clusters on the disk. Set DCD_fatSize to 4 (number of bits for right
	; shift on odd clusters) if 12-bit.
	; 
		cmp	ax, FAT_16_BIT_THRESHOLD
		jae	done			; DCD zero-initialized, so
						;  just leave DCD_fatSize alone
		mov	ds:[DCD_fatSize], 4
		clc
done:
		.leave
		ret
fail:
		segmov	ds, es		; ds <- DiskCopyData again
		mov	ax, ERR_CANT_READ_FROM_SOURCE
		jmp	done
DOSDiskCopyGetDiskGeometry endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyReadSourceFAT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read the first FAT for the source disk into memory.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ds	= DiskCopyData
RETURN:		carry set on error:
			ax	= DiskCopyError
		carry clear if ok:
			ax	= destroyed
			ds:[DCD_numUsedClust], ds:[DCD_fatBuffer] initialized
DESTROYED:	bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyReadSourceFAT proc	near
		.enter
	;
	; Get the FSIR back again.
	; 
		call	FSDDerefInfo
		mov	es, ax
		mov	si, ds:[DCD_realSource]	; ds:si <- drive from which
						;  to read

	;
	; Allocate room for the entire FAT for both the source and the dest
	; disks.
	; 
		mov	ax, ds:[DCD_bpb].BPB_sectorsPerFAT
		mul	ds:[DCD_bpb].BPB_sectorSize
		mov	ds:[DCD_destFATOff], ax
		shl	ax			; *2, of course
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc
		jc	allocError
	;
	; Read the whole thing into memory.
	; 
		mov	ds:[DCD_fatBuffer], bx
		push	ds
		mov	dx, ds:[DCD_bpb].BPB_numReservedSectors
		clr	bx
		mov	cx, ds:[DCD_bpb].BPB_sectorsPerFAT
		clr	di
		mov	ds, ax
		call	DOSReadSectors
		pop	es			; es <- DCD
		jc	readError
	;
	; Now count the number of clusters in-use. During the loop:
	; 	cl	= value by which to right-shift to get cluster
	;		  value. Toggles between 0 and 4 for 12-bit FAT,
	;		  always 0 for 16-bit
	;	dx	= FAT_CLUSTER_BAD for the FAT size, used to get only
	;		  the proper bits, and to see if the thing is really
	;		  used or just bad (see DOSDiskCopyProcessClusters for
	;		  an explanation)
	;	ds:si	= word in the FAT to examine
	;	di	= # clusters left to process
	;	es	= DiskCopyData
	;
	; 
		mov	di, es:[DCD_numClusters]
		dec	di			; don't count first 2
		dec	di			;  reserved clusters
		clr	cl
		mov	dx, FAT_CLUSTER_BAD	; assume 16-bit FAT
		mov	si, 4			; ditto

		tst	es:[DCD_fatSize]
		jz	clusterLoop

		dec	si			; 12-bit FAT, so first file
						;  entry is at 3, not 4
		mov	dh, 0x0f		; mask out top 4 bits
clusterLoop:
		lodsw				; ax <- next FAT entry
		shr	ax, cl			; right-justify
		test	ax, 8			; neither free nor bad?
		jnz	isUsed			; right, must be used

		and	ax, dx			; mask out unwanted bits
		jz	nextCluster		; => free
		cmp	ax, dx			; bad?
		je	nextCluster		; yes
isUsed:
		inc	es:[DCD_numUsedClust]	; up count
nextCluster:
		dec	di
		jz	clusterLoopDone

		xor	cl, es:[DCD_fatSize]	; flip fat-entry toggle
		jz	clusterLoop		; => advance of si by 2 was
						;  right
		dec	si			; only wanted one, thanks
		jmp	clusterLoop

clusterLoopDone:
		clc
unlockFAT:
	;
	; Have the count of used clusters now, so unlock the FAT.
	; 
		segmov	ds, es			; ds <- DiskCopyData again
		add	ds:[DCD_numUsedClust], 2; account for boot sector and
						;  root dir "clusters" (also
						;  prevents death when copying
						;  empty disk...)
		mov	bx, ds:[DCD_fatBuffer]
		call	MemUnlock
done:
		.leave
		ret

allocError:
		mov	ax, ERR_DISKCOPY_INSUFFICIENT_MEM
		jmp	done

readError:
		mov	ax, ERR_CANT_READ_FROM_SOURCE
		jmp	unlockFAT

DOSDiskCopyReadSourceFAT endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyAllocBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate as many buffers as we, the user, and the system
		will allow us to allocate.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ds	= DiskCopyData
RETURN:		carry set if couldn't allocate any buffers
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyAllocBuffers proc	near
		.enter
	;
	; Figure how many buffers we'd need to hold everything.
	; 
		mov	ax, ds:[DCD_numUsedClust]
		mul	ds:[DCD_clusterSize]
		add	ax, ds:[DCD_rootDirSize]
		adc	dx, 0

		mov	cx, ds:[DCD_bufferSize]	; cx <- cylinder size
		dec	cx			; round up...
		add	ax, cx
		adc	dx, 0
		inc	cx			; back to cylinder size...
		div	cx			; ax <- # cylinder buffers
						;  required (remainder
						;  unimportant)

if _REDMS4
		mov	dx, DISK_COPY_SINGLE_DRIVE_REDWOOD_BUFFER_LIMIT
else
	;
	; Figure how many we'll allow ourselves to allocate, if the system
	; will let us.
	;
	; For a multi-drive copy, we use a predefined max,
	; regardless of the DCF_GREEDY flag, as there's no need to be
	; greedy during the copy (it won't gain us anything).
	;
	; For a single-drive, non-greedy copy, we use a higher predefined max,
	; to limit the number of swaps.
	;
	; For a single-drive, greedy copy, we use as many as we've decided
	; we'll need.
	; 
		mov	dx, DISK_COPY_MULTI_DRIVE_BUFFER_LIMIT
		test	ds:[DCD_status], mask DCS_SINGLE_DRIVE
		jz	allocLoop

		mov	dx, DISK_COPY_SINGLE_DRIVE_NON_GREEDY_BUFFER_LIMIT
		test	ds:[DCD_args].FSCA_flags, mask DCF_GREEDY
		jz	allocLoop

		mov	dx, ax
endif

allocLoop:
	;
	; Try and allocate another buffer of the chosen size. Do not need it
	; locked or anything (in fact, we definitely do not want it locked).
	; 
		mov	ax, ds:[DCD_bufferSize]
		mov	cx, ALLOC_DYNAMIC
		call	MemAlloc
		jc	allocDone
	;
	; Link the previous firstBuffer to this new one through the otherInfo
	; field.
	; 
		mov	ax, ds:[DCD_firstBuffer]
		call	MemModifyOtherInfo
	;
	; Store the new handle and up the number of buffers. If more to allocate
	; do so, s'il vous plais.
	; 
		mov	ds:[DCD_firstBuffer], bx
		inc	ds:[DCD_numBuffers]
		dec	dx
		jnz	allocLoop

allocDone:
	;
	; Count the number of disk swaps that will be required, if this is
	; a single-disk copy, and tell the user this.
	; 
		test	ds:[DCD_status], mask DCS_SINGLE_DRIVE
		jz	checkAnythingAllocated
		
		mov	cx, ds:[DCD_numBuffers]
		jcxz	nothingAllocated

		mov	ax, -1
		mov	di, offset DOSDiskCopyCountSwapCallback
		call	DOSDiskCopyProcessDisk
	    ;
	    ; Take the number of times DOSDiskCopyCountSwapCallback was called,
	    ; being the number of buffers that will be filled during the
	    ; copy, and divide by the number of buffers we were able to allocate
	    ; (which we know is non-zero), rounding up if there's any remainder.
	    ; This gives us the number of disk swaps that will be needed.
	    ; 
		mov	ax, ds:[DCD_numSwaps]
		clr	dx			; zero-extend
		div	ds:[DCD_numBuffers]
		tst	dx			; remainder?
		jz	haveNumSwaps		; none
		inc	ax			; round up
haveNumSwaps:
		mov	ds:[DCD_numSwaps], ax	; record, just in case
		mov_tr	dx, ax
		mov	ax, DCC_REPORT_NUM_SWAPS
		call	DOSDiskCopyCallCallback	; returns carry set/clear + ax
						;  set properly if CF=1
done:
		.leave
		ret

checkAnythingAllocated:
	;
	; See if we were able to allocate anything. If not, we bitch.
	; 
		tst	ds:[DCD_numBuffers]
		jnz	done
nothingAllocated:
		mov	ax, ERR_DISKCOPY_INSUFFICIENT_MEM
		stc
		jmp	done
DOSDiskCopyAllocBuffers endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyCountSwapCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function for DOSDiskCopyProcessClusters to count
		the number of buffers used.

CALLED BY:	(INTERNAL) DOSDiskCopyAllocBuffers via 
       				DOSDiskCopyProcessClusters
PASS:		ds	= DiskCopyData
		dx	= offset of cluster(s)
		cx	= # bytes to process
		si	= starting cluster #
RETURN:		carry set on error:
			ax	= DiskCopyError/FormatError
		carry clear if ok:
			ax	= destroyed
DESTROYED:	si, di, cx, ax, dx, es all allowed
SIDE EFFECTS:	ds:[DCD_numSwaps] may be incremented

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyCountSwapCallback proc	near
		.enter
	;
	; If data at the start of a buffer, up DCD_numSwaps, as it's a new
	; buffer on which we're working.
	; 
		tst	dx
		jnz	done
		inc	ds:[DCD_numSwaps]
done:
		.leave
		ret
DOSDiskCopyCountSwapCallback endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyProcessDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process all the used clusters in the disk.

CALLED BY:	(INTERNAL) DOSDiskCopyAllocBuffers
PASS:		ax	= DiskCopyCallback to pass to user callback function.
			  -1 to not call user callback
		cs:di	= callback function for DOSDiskCopyProcessClusters
		ds	= DiskCopyData
RETURN:		carry set on error:
			ax	= DiskCopyError/FormatError
		carry clear on success
			ax	= destroyed
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyProcessDisk proc	near
		.enter
		mov	ds:[DCD_callbackType], ax
		clr	ax
		mov	ds:[DCD_firstCluster], ax	; root dir
		mov	ds:[DCD_procUsedClust], ax
		mov	ds:[DCD_procClustCB], di
	;
	; Start at beginning of FAT, in spite of two reserved clusters. In our
	; world, cluster 0 is the boot sector and cluster 1 is the root
	; directory.
	; 
		mov	ds:[DCD_fatToggle], al
		mov	ds:[DCD_fatOffset], ax

processLoop:
	;
	; Process the next batch o' clusters.
	; 
		call	DOSDiskCopyProcessClusters
		jc	done
	;
	; Advance DCD_firstCluster to be the one after the last one processed
	; (returned in DCD_curCluster). If still more clusters to handle,
	; loop.
	; 
		mov	ax, ds:[DCD_curCluster]
		mov	ds:[DCD_firstCluster], ax
		cmp	ax, ds:[DCD_numClusters]
		jb	processLoop
		; carry clear if AE
done:
		.leave
		ret
DOSDiskCopyProcessDisk endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyProcessClusters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process as many clusters as will fit in the buffers allocated,
		calling a callback with each contiguous range of good clusters
		and calling the user callback each time we switch to another
		buffer.

CALLED BY:	(INTERNAL) DOSDiskCopyProcessDisk, DOSDiskCopy
PASS:		ds	= DiskCopyData
		ds:[DCD_firstCluster], ds:[DCD_fatToggle], ds:[DCD_fatOffset],
		ds:[DCD_fatSize], ds:[DCD_callbackType], ds:[DCD_procClustCB],
		ds:[DCD_procUsedClust]
RETURN:		carry set on error (as returned by ds:[DCD_procClustCB]):
			ax	= DiskCopyError/FormatError
		carry clear on success:
			ax	= destroyed
			ds:[DCD_fatOffset], ds:[DCD_fatToggle],
			ds:[DCD_procUsedClust] updated
DESTROYED:	
SIDE EFFECTS:	ds:[DCD_curCluster] set to 1 greater than last cluster
     			processed

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyProcessClusters proc	near
		uses	bx, cx, dx, si, di, es
		.enter
	;
	; Set dx to the value by which to mask the word fetched from the FAT
	; and right-shifted to extract the value for the current cluster.
	;
	; We cheat a bit and use the value for a bad cluster, which is the
	; same as the mask would be, except for b3. Since all we're looking for
	; is a value of 0 or FAT_CLUSTER_BAD, neither of which has b3 set, we
	; can and the word with a FAT_CLUSTER_BAD appropriate to the FAT size
	; after we've checked to see if b3 is set. If b3 is set, we have to
	; process the cluster.
	; 
	; This is 0xfff7 for a 16-bit FAT, or 0xff7 for a 12-bit FAT.
	; 
		mov	dx, FAT_CLUSTER_BAD
		tst	ds:[DCD_fatSize]
		jz	haveFATMask
		mov	dh, 0x0f
haveFATMask:
	;
	; Start with first buffer in chain.
	; 
		mov	ax, ds:[DCD_firstBuffer]
		mov	ds:[DCD_curBuffer], ax
	;
	; No used clusters processed this round, yet.
	; 
		clr	di
	;
	; Lock down the source FAT and point es:si to the data for the start
	; cluster.
	; 
		mov	bx, ds:[DCD_fatBuffer]
		call	MemLock
		mov	es, ax
		mov	si, ds:[DCD_fatOffset]
	;
	; Start with the first cluster, as you'd expect.
	; 
		mov	ax, ds:[DCD_firstCluster]
		mov	ds:[DCD_curCluster], ax
bufferLoop:
		mov	ax, -1
		mov	ds:[DCD_rangeStart], ax
		mov	ds:[DCD_prevCluster], ax
		mov	ds:[DCD_bufferOff], 0
clusterLoop:
	;
	; Make sure there's room in the buffer for this cluster and the
	; existing range.
	; 
		call	getRangeSize
		add	ax, ds:[DCD_bufferOff]
		mov	cx, ds:[DCD_rootDirSize]
		tst	ds:[DCD_curCluster]
		jz	haveClusterSize
		mov	cx, ds:[DCD_clusterSize]
haveClusterSize:
		add	ax, cx
		cmp	ax, ds:[DCD_bufferSize]
		ja	nextBuffer		; nope -- advance to the next
	;
	; Check for boot sector or root directory. No matter how big a FAT
	; entry is for the disk, cluster 0 will be at offset 0, and cluster
	; 1 will be either at offset 1 or 2, both of which are less than 3.
	; 
		cmp	si, 3
		jb	processIt
	;
	; See if the current cluster is allocated.
	; 
		mov	ax, es:[si]
		mov	cl, ds:[DCD_fatToggle]
		shr	ax, cl
	
		CheckHack <FAT_CLUSTER_BAD eq 0xfff7>
		test	ax, 8
		jnz	processIt	; => can be neither free nor bad

		and	ax, dx		; mask unnecessary bits
		jz	doCloseRange	; => free

		cmp	ax, dx		; bad cluster?
		je	doCloseRange	; yes => don't process
processIt:
	;
	; Process a used cluster. A range is always closed by encountering
	; a free or bad cluster, or by running out of room in the current
	; buffer, so all we have to do here is decide whether we need to start
	; a new range, or just extend an existing one.
	; 
		inc	di		; another used cluster processed

		mov	ax, ds:[DCD_prevCluster]
		inc	ax
		jnz	extendRange	; => range was active

		mov	ax, ds:[DCD_curCluster]
		mov	ds:[DCD_rangeStart], ax	; else record start...
		mov	ds:[DCD_rangeStartFO], si	; ...and offset of same
		mov	ds:[DCD_rangeStartFT], cl	; ...and toggle of same
extendRange:
		mov	ds:[DCD_prevCluster], ax

nextCluster:
	;
	; Advance to the next cluster on the disk, coping with having been on
	; the root directory.
	; 
		mov	ax, ds:[DCD_curCluster]
		inc	ax
		cmp	ax, 2			; were we on the root?
		je	closeRootDir
		jb	closeBootSect

advanceFATPointer:
		mov	ds:[DCD_curCluster], ax
		cmp	ax, ds:[DCD_numClusters]
		jae	outOfClusters
	;
	; Advance the pointer into the FAT, coping with 12- vs 16-bit FATs.
	;
	; For a 12-bit FAT, we need to advance si by 1 if DCD_fatToggle is
	; currently 0, as we need to get to the second cluster encoded in the
	; 3-byte series. If DCD_fatToggle is non-zero, we need to advance si by
	; 2 to get to the next 3-byte series (see dosDiskFormat.asm for further
	; information on this phenomenon (DOSFormatProcessBadTrack)).
	;
	; For a 16-bit FAT, we always need to advance by 2.
	;
	; This is taken care of by having DCD_fatSize be 0 for a 16-bit FAT, so
	; when it's xor'ed with DCD_fatToggle, the result is always 0.
	; 
		inc	si
		mov	al, ds:[DCD_fatSize]
		xor	ds:[DCD_fatToggle], al
		jnz	clusterLoop		; => si now correct
		inc	si			; else advance another
		jmp	clusterLoop

closeRootDir:
	;
	; Was the root directory, so close the range.
	; 
		call	closeRange
		mov	ax, 2			; ax <- first data cluster
		jmp	advanceFATPointer

closeBootSect:
	;
	; Was the boot sector, so close the range.
	; 
		call	closeRange
		mov	ax, 1
		jmp	advanceFATPointer

doCloseRange:
	;
	; Current cluster is free or bad, so close any open range. If there's
	; an error, closeRange will jump to the right place.
	; 
		call	closeRange
		jmp	nextCluster

outOfClusters:
		call	closeRange
		call	reportPercentage
		jmp	done

nextBuffer:
	;
	; Close the current range before switching buffers.
	; 
		call	closeRange
	;
	; Call the user callback, if desired.
	; 
		call	reportPercentage
		jc	done			; => abort
	;
	; Advance to the next buffer in the chain.
	; 
		mov	bx, ds:[DCD_curBuffer]
		mov	ax, MGIT_OTHER_INFO
		call	MemGetInfo		; ax <- handle of next
		mov	ds:[DCD_curBuffer], ax
		tst	ax
		LONG jnz bufferLoop
done:
	;
	; Record final FAT offset for next call.
	; 
		mov	ds:[DCD_fatOffset], si
	;
	; Unlock the FAT and get out of here with ax and carry flag intact
	; 
		mov	bx, ds:[DCD_fatBuffer]
		call	MemUnlock
		.leave
		ret

	;--------------------
	; Figure how big the current range is, in bytes.
	; 
	; Pass:		ds:[DCD_prevCluster] = end of range
	; 		ds:[DCD_rangeStart] = start of range
	; Return:	ax	= size of range, in bytes (0 if no range
	;			  active)
	; Destroyed:	cx
	;
getRangeSize:
		push	dx
		mov	ax, ds:[DCD_prevCluster]
		inc	ax
		jz	haveRangeSize		; => no range, so 0 size

		mov	cx, ds:[DCD_rangeStart]
		cmp	cx, 1
		jb	useSectorSize		; => boot sector
		je	useRootDirSize		; => root dir
		sub	ax, cx			; ax <- # clusters
		mul	ds:[DCD_clusterSize]
haveRangeSize:
		pop	dx
		retn
useRootDirSize:
		mov	ax, ds:[DCD_rootDirSize]
		pop	dx
		retn
useSectorSize:
		mov	ax, ds:[DCD_bpb].BPB_sectorSize
		pop	dx
		retn

	;--------------------
	; Close any open range. If callback returns an error, don't return to
	; the caller, but vault to done directly, after clearing the return
	; address off the stack.
	;
	; Pass:		ds:[DCD_prevCluster] = end of range
	;		ds:[DCD_rangeStart] = start of range
	; Return:	nothing
	; Destroyed:	ax, cx, dx
closeRange:
	;
	; Figure how big the range is, in bytes (callback can convert it to
	; sectors using that)
	; 
		call	getRangeSize
		tst	ax
		jz	closeRangeDone

		push	es, si, di, dx
	;
	; Load registers for the callback.
	; 	cx	= # bytes in cluster range
	; 	si	= starting cluster # (0 => root dir)
	; 	dx	= offset in buffer of cluster(s)
	; 
		mov_tr	cx, ax		; cx <- # bytes
		mov	si, -1		; signal no range in progress...
		mov	ds:[DCD_prevCluster], si
		xchg	si, ds:[DCD_rangeStart]	; ...while fetching start
		mov	dx, ds:[DCD_bufferOff]
		add	ds:[DCD_bufferOff], cx
	;
	; Fetch the callback we're to call. As a hack, if the callback is
	; DOSDiskCopyCountSwapCallback, don't lock the buffer down, as that
	; would cause a lot of swapping, if doing a greedy single-drive
	; copy, when we know the callback isn't going to do anything with
	; the locked buffer anyway.
	; 
		mov	di, ds:[DCD_procClustCB]
		clr	bx
		cmp	di, offset DOSDiskCopyCountSwapCallback
		je	callCallback
	;
	; Lock down the buffer.
	; 
		mov	bx, ds:[DCD_curBuffer]
		call	MemLock
		mov	es, ax
callCallback:
		call	di		; may destroy si, di, cx, ax, dx, es
					; must preserve bx, ds, bp
		pop	es, si, di, dx
		mov	cx, bx		; see if we need to unlock the buffer
		jcxz	checkError	;  w/o biffing the carry
		call	MemUnlock
checkError:
		jnc	closeRangeDone
	;
	; Error -- get out of this whole function sneakily
	; 
		inc	sp		; nuke old return address...
		inc	sp
		mov	bx, offset done	; ...replacing it with that of "done"
		push	bx
closeRangeDone:
		retn
	;--------------------
	; Pass:		di	= # used clusters in current buffer
	; 		ds	= DiskCopyData
	; Return:	carry set if should abort:
	;			ax	= ERR_OPERATION_CANCELLED
	;		carry clear if should continue
	;			ax	= destroyed
	;		di	= 0
	; 		ds:[DCD_procUsedClust] = updated
	; Destroyed:	nothing
	; 
reportPercentage:
		push	dx
		mov	ax, ds:[DCD_procUsedClust]
		add	ax, di			; ax <- # user clusters
						;  processed
		mov	ds:[DCD_procUsedClust], ax
		clr	di
		mov	dx, 100			; * 100, so we get percentage
		mul	dx
		div	ds:[DCD_numUsedClust]	; ax <- percentage done
		mov_tr	dx, ax			; pass it in dx
		mov	ax, ds:[DCD_callbackType]
		cmp	ax, -1
		je	reportPercentageDone
		call	DOSDiskCopyCallCallback
reportPercentageDone:
		pop	dx
		retn
DOSDiskCopyProcessClusters endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clean up everything that needs cleaning up.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ds	= DiskCopyData
RETURN:		nothing
DESTROYED:	ds (flags preserved)
SIDE EFFECTS:	everything that needs freeing or unlocking is freed or
		    unlocked

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyCleanUp proc	near
		uses	ax, bx, si, es
		.enter
		pushf
	;
	; Make sure the FSIR is locked, so we can unlock the drives.
	;
		test	ds:[DCD_status], mask DCS_FSIR_LOCKED
		jnz	derefFSIR		; => already locked
		call	DOSDiskCopyLockInfoShared
derefFSIR:
		call	FSDDerefInfo
		mov	es, ax
	;
	; Unlock the source disk.
	;
		mov	si, ds:[DCD_args].FSCA_disk
		call	DOSDiskUnlock
	;
	; Unlock the drives, if necessary.
	; 
		test	ds:[DCD_status], mask DCS_DRIVES_LOCKED
		jz	unlockFSIR
		
		mov	si, ds:[DCD_args].FSCA_dest
		call	FSDUnlockDriveExcl
		
		cmp	si, ds:[DCD_args].FSCA_source
		je	unlockFSIR

		mov	si, ds:[DCD_args].FSCA_source
		call	FSDUnlockDriveExcl

unlockFSIR:
	;
	; Done with the FSIR, so unlock it.
	; 
		call	FSDUnlockInfoShared
	;
	; Now free all the buffers we managed to allocate.
	; 
		mov	ax, ds:[DCD_firstBuffer]
freeBufferLoop:
		mov_tr	bx, ax
		tst	bx
		jz	freeOtherBuffers
		mov	ax, MGIT_OTHER_INFO
		call	MemGetInfo		; ax <- next buffer
		call	MemFree			; free this one
		jmp	freeBufferLoop

freeOtherBuffers:
	;
	; Free the FAT buffer
	; 
		mov	bx, ds:[DCD_fatBuffer]
		call	freeMe
	;
	; Free the workspace itself.
	; 
		mov	bx, ds:[DCD_handle]
		call	MemFree
	;
	; Recover error flag and everything else.
	; 
		popf
		.leave
		ret

	;--------------------
freeMe:
		tst	bx
		jz	freeMeDone
		call	MemFree
freeMeDone:
		retn
DOSDiskCopyCleanUp endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyCallCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the user's callback routine.

CALLED BY:	(INTERNAL)
PASS:		ds	= DiskCopyData
		ax	= DiskCopyCallback
		dx	= parameter for it.
RETURN:		carry set if operation cancelled by the callback:
			ax	= ERR_OPERATION_CANCELLED
		carry clear if ok:
			ax	= destroyed
DESTROYED:	dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyCallCallback proc	near
		.enter

FXIP<		mov	ss:[TPD_dataAX], ax			>
FXIP<		mov	ss:[TPD_dataBX], bx			>
FXIP<		movdw	bxax, ds:[DCD_args].FSCA_callback	>
FXIP<		call	ProcCallFixedOrMovable			>
NOFXIP<		call	ds:[DCD_args].FSCA_callback		>
		tst	ax
		jz	done
		mov	ax, ERR_OPERATION_CANCELLED
		stc
done:
		.leave
		ret
DOSDiskCopyCallCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyAskForDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use the callback routine to ask the user for the disk.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ax	= DiskCopyCallback
		ds:[si]	= location of DSE offset for drive
RETURN:		carry set if user cancelled:
			ax	= ERR_OPERATION_CANCELLED
		carry clear if ok:
			ax	= destroyed
DESTROYED:	es, si, dx
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyAskForDisk proc	near
		test	ds:[DCD_status], mask DCS_SINGLE_DRIVE
		jz	done
	;
	; Extract the number for the appropriate drive.
	; 
		call	DOSDiskCopyLockInfoShared
		
		mov	si, ds:[si]
		mov	dl, es:[si].DSE_number
		call	DOSDiskCopyUnlockInfoShared
	;
	; Call the callback routine as usual.
	; 
		call	DOSDiskCopyCallCallback
done:
		ret
DOSDiskCopyAskForDisk endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyReadClusters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read clusters for DOSDiskCopyProcessClusters

CALLED BY:	(INTERNAL) DOSDiskCopyProcessClusters
PASS:		ds	= DiskCopyData
		es:dx	= place to which to read the clusters
		cx	= # bytes to read
		si	= first cluster to read
RETURN:		carry set if couldn't read:
			ax	= ERR_CANT_READ_FROM_SOURCE
		carry clear if ok:
			ax	= destroyed
DESTROYED:	si, di, cx, ax, dx, es allowed
		bx, ds, bp must be preserved
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyReadClusters proc	near
		uses	bx
		.enter
		push	ds
	;
	; Convert the bytes and starting number to sectors.
	; 
		push	ds:[DCD_realSource]
		call	DOSDiskCopyConvertToSectors
	;
	; Read dem sectors.
	; 
		pop	si		; es:si <- DSE
		call	DOSReadSectors
		jnc	done
		mov	ax, ERR_CANT_READ_FROM_SOURCE
done:
		pop	ds
		call	DOSDiskCopyUnlockInfoShared
		.leave
		ret
DOSDiskCopyReadClusters endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyConvertToSectors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert DOSDiskCopyProcessClusters callback arguments to
		sector arguments suitable for passing to DOSReadSectors
		or DOSWriteSectors

CALLED BY:	(INTERNAL) DOSDiskCopyReadClusters,
			   DOSDiskCopyWriteClusters
PASS:		cx	= # bytes for transfer
		si	= starting cluster number (0 => boot sector,
			  1 => root dir)
		es:dx	= transfer location
		ds	= DiskCopyData
RETURN:		bx:dx	= starting sector number
		cx	= number of sectors
		es	= FSIR locked shared
		ds:di	= transfer location
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyConvertToSectors proc near
		.enter
		mov	di, dx		; di <- transfer loc offset

	;
	; Compute the number of sectors.
	; 
		mov_tr	cx, ax
		clr	dx
		div	ds:[DCD_bpb].BPB_sectorSize
		mov_tr	cx, ax

EC <		tst	dx	; s/b no remainder			>
EC <		ERROR_NZ	GASP_CHOKE_WHEEZE			>

	;
	; Compute starting sector.
	; 
		cmp	si, 1
		jz	isRootDir
		jb	isBootSector
		
		dec	si		; 2 reserved clusters don't
		dec	si		;  count

		mov	al, ds:[DCD_bpb].BPB_clusterSize
		clr	ah
		mul	si		; dxax <- # sectors from start o'
					;  files area
		add	ax, ds:[DCD_startFiles]
		adc	dx, 0		; just being careful, even though
					;  this will never actually carry

		xchg	dx, ax		; dx <- low word of sector #, ax <- high
		mov_tr	bx, ax		; bx <- high word of sector #

lockFSIR:
	;
	; Lock the FSIR down for the caller.
	; 
		push	es
		call	DOSDiskCopyLockInfoShared
		pop	ds
		.leave
		ret

isRootDir:
	;
	; Figure starting sector of root directory (beyond boot sector and
	; both FATs).
	; 
		mov	ax, ds:[DCD_bpb].BPB_sectorsPerFAT
		mul	ds:[DCD_bpb].BPB_numFATs
		add	ax, ds:[DCD_bpb].BPB_numReservedSectors
		mov_tr	dx, ax
		clr	bx
		jmp	lockFSIR

isBootSector:
	;
	; Boot sector is sector 0, of course.
	; 
		clr	dx, bx
		jmp	lockFSIR
DOSDiskCopyConvertToSectors endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyWriteClusters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write a mess o' clusters to the destination disk.

CALLED BY:	(INTERNAL) DOSDiskCopyProcessClusters
PASS:		ds	= DiskCopyData
		es:dx	= place from which to write the clusters
		cx	= # bytes to write
		si	= first cluster to write
		ds:[DCD_rangeStartFO], ds:[DCD_rangeStartFT] set
RETURN:		carry set if couldn't read:
			ax	= ERR_CANT_READ_FROM_SOURCE
		carry clear if ok:
			ax	= destroyed
DESTROYED:	si, di, cx, ax, dx, es allowed
		bx, ds, bp must be preserved
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyWriteClusters proc	near
		uses	bx, ds
		.enter
		push	es, dx, cx, si	; save for when we actually write stuff

		cmp	si, 1		; boot sector or root dir?
		ja	markDestFAT	; no
		
		je	doWrite		; => root directory
	;
	; Before writing the boot sector, we want to format the destination
	; disk.
	; 
		call	DOSDiskCopyFormatDest
		jc	doWrite
	;
	; Change the ID in the boot sector we got from the source disk to match
	; that just given to the destination disk.
	; 
		pop	es, dx, cx, si
		mov	bx, dx
		movdw	axdi, ds:[DCD_destDiskID]
		cmp	es:[bx].BS_extendedBootSig, EXTENDED_BOOT_SIGNATURE
		je	storeDiskIDInBS_volumeID
		
		.warn	-field		; I know. I know...
		movdw	es:[bx].BS_oemNameAndVersion.DIS_id, axdi
		mov	es:[bx].BS_oemNameAndVersion.DIS_present, 
			DISK_ID_PRESENT
		.warn	@field
		jmp	doWriteRegistersPopped

storeDiskIDInBS_volumeID:
		movdw	es:[bx].BS_volumeID, axdi
		jmp	doWriteRegistersPopped

markDestFAT:
	;
	; Transfer the FAT entries for this range from the source disk to the
	; destination.
	; 
		call	DOSDiskCopyTransferFATEntries
doWrite:
		pop	es, dx, cx, si
		jc	done

doWriteRegistersPopped:
	;
	; Write all the sectors to the destination.
	; 
		push	ds
		push	ds:[DCD_realDest]
		call	DOSDiskCopyConvertToSectors
		pop	si		; es:si <- DSE
		call	DOSWriteSectors
		jnc	unlockFSIR
		mov	ax, ERR_CANT_WRITE_TO_DEST
unlockFSIR:
		pop	ds
		call	DOSDiskCopyUnlockInfoShared
done:
		.leave
		ret
DOSDiskCopyWriteClusters endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyFormatDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format the destination disk after confirming it's ok.

CALLED BY:	(INTERNAL) DOSDiskCopyWriteClusters
PASS:		ds	= DiskCopyData
RETURN:		carry set on error:
			ax	= DiskCopyError/FormatError
		carry clear if ok:
			ax	= destroyed
DESTROYED:	es, si, dx, cx, bx allowed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyFormatDest proc	near
		.enter
	;
	; If you're familiar with DiskRegisterCommon, this will look familiar
	; to you. Unfortunately, we can't use DiskRegister, since it will try
	; and lock the drive exclusive, and we already have it locked
	; exclusive. So...
	;
	; Fetch the ID from the disk currently in the drive.
	; 
		call	DOSDiskCopyLockInfoShared
		mov	si, ds:[DCD_realDest]

		clr	bx		; assume not formatted
		call	DOSDiskID
		jc	doFormat
	;
	; Disk is formatted. Locate a disk for the thing, if possible.
	; 
		mov	bx, offset FIH_diskList - offset DD_next
diskLoop:
		mov	bx, es:[bx].DD_next
		tst	bx
		jz	notFound
		
		cmp	es:[bx].DD_id.low, dx	; low ID word matches?
		jne	diskLoop		; nope
		cmp	es:[bx].DD_id.high, cx	; high ID word matches?
		jne	diskLoop		; nope
		cmp	es:[bx].DD_drive, si	; same drive?
		jne	diskLoop		; nope
		jmp	verifyDestruction

notFound:
	;
	; Couldn't find a disk handle for the thing, but we need to create one
	; as we need to ask the user if s/he really wants to biff the thing.
	; 
		mov	bh, FNA_SILENT	; be silent if unnamed, as (1) disk
					;  will get a new name in a moment, and
					;  (2) caller will likely prompt with
					;  appropriate name showing
		push	bp, ds
		mov	bp, es:[si].DSE_fsd
		segmov	ds, es			; ds <- FSIR
		call	DiskAllocAndInit	; THIS RELEASES EXCLUSIVE
						;  ACCESS TO THE DRIVE
	;
	; Regain exclusive access to the destination drive, regardless.
	; Even if src and dest are the same drive, there's but one lock
	; on the thing, and we need it.
	; 
		segmov	es, ds			; es <- FSIR
		pop	bp, ds			; ds <- DCD
		pushf
		call	FSDLockDriveExcl
		popf
		jnc	verifyDestruction
		mov	ax, ERR_COULD_NOT_REGISTER_FORMATTED_DESTINATION_DISK
unlockFSIR:
		call	DOSDiskCopyUnlockInfoShared
		stc
		jmp	done

verifyDestruction:
	;
	; Ask the callback routine if it really wants us to nuke this thing
	; 
		mov	dl, es:[si].DSE_number
		call	DOSDiskCopyUnlockInfoShared

	    ;
	    ; But first, check with the system to see if the user should
	    ; even be given the opportunity.
	    ; 
		call	DiskCheckInUse
		mov	ax, ERR_DISK_IS_IN_USE
		jc	done

		mov	ax, DCC_VERIFY_DEST_DESTRUCTION
		call	DOSDiskCopyCallCallback
		jc	done		; no
	;
	; Ok. Since we might have had to give up control of the drive, make
	; sure the destination disk is in the drive.
	; 
		call	DOSDiskCopyLockInfoShared
		mov	si, bx
		clr	al		; lock abort allowed
		call	DOSDiskLock
		mov	ax, ERR_OPERATION_CANCELLED
		jc	unlockFSIR
		mov	bx, si
		mov	si, es:[si].DD_drive
	;--------------------
doFormat:
	;
	; Either destination is unformatted or user has granted our request
	; to blow the monster out of the water. Do so now.
	; 
		push	bx		; save DiskDesc nptr(if disk formatted)
		call	DOSDiskCopyPerformFormat
		pop	si		; si = DiskDesc nptr
		pushf
		tst	si
		jz	noNeedToUnlock	; if dest disk was originally
					;   unformatted, we didn't call
					;   DOSDiskLock earlier.
		call	DOSDiskCopyLockInfoShared	; es:si = DIskDesc
		call	DOSDiskUnlock
		call	DOSDiskCopyUnlockInfoShared

noNeedToUnlock:
		popf
		jc	done
	;
	; Read the destination disk's FAT to the latter half of the FAT
	; buffer
	; 
		call	DOSDiskCopyLockInfoShared
		mov	di, ds:[DCD_destFATOff]
		mov	dx, ds:[DCD_bpb].BPB_numReservedSectors
		mov	cx, ds:[DCD_bpb].BPB_sectorsPerFAT
		mov	si, ds:[DCD_realDest]
		push	ds
		mov	bx, ds:[DCD_fatBuffer]
		call	MemDerefDS		; ds:di <- transfer point
		clr	bx			; bx:dx <- sector #
		call	DOSReadSectors
		pop	ds
		mov	ax, ERR_CANT_WRITE_TO_DEST	; XXX
		jc	done
	;
	; Read FAT successfully, so unlock the FSIR (if read unsuccessfully,
	; DOSDiskCopyCleanUp will unlock the thing for us)
	; 
		call	DOSDiskCopyUnlockInfoShared
done:
		.leave
		ret
DOSDiskCopyFormatDest endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyPerformFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Actually format the destination disk.

CALLED BY:	(INTERNAL) DOSDiskCopyFormatDest
PASS:		es:bx	= DiskDesc (bx = 0 if none)
		es:si	= DriveStatusEntry
		ds	= DiskCopyData
RETURN:		carry set on error:
			ax	= FormatError
		carry clear if ok:
			ax	= destroyed
		FSInfoResource unlocked
DESTROYED:	bx, si, ax, di, es
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyPerformFormat proc	near
args		local	FSFormatArgs
volumeLabel	local	VolumeName
		.enter
	;
	; Set the disk and drive
	; 
		mov	ss:[args].FSFA_disk, bx
		mov	ss:[args].FSFA_dse, si
		mov	al, es:[si].DSE_number
		mov	ss:[args].FSFA_drive, al
	;
	; Tell it to call us back with percentages, and allow quick format
	; 
		mov	ss:[args].FSFA_flags, mask DFF_CALLBACK_PCT_DONE
	;
	; Specify whom it should call.
	; 
		mov	ss:[args].FSFA_callback.segment, SEGMENT_CS
		mov	ss:[args].FSFA_callback.offset,
				offset DOSDiskCopyFormatCallback
	;
	; Insist that it pass our DiskCopyData back to us in DS.
	; 
		mov	ss:[args].FSFA_ds, ds
	;
	; Fetch the target media type from the source disk.
	; 
		mov	bx, ds:[DCD_args].FSCA_disk
		mov	al, es:[bx].DD_media
		mov	ss:[args].FSFA_media, al
	;
	; Make a copy of the volume label in the source disk, since the FSIR
	; could well move around during the format.
	; 
		lea	si, es:[bx].DD_volumeLabel
		lea	di, ss:[volumeLabel]
		mov	ss:[args].FSFA_volumeName.offset, di
		mov	ss:[args].FSFA_volumeName.segment, ss
		segmov	ds, es
		segmov	es, ss
		mov	cx, size DD_volumeLabel
		rep	movsb
		clr	al		; null-terminate the space-padded
		stosb			;  volume label
		
	;
	; Release the FSIR.
	; 
		mov	ds, ss:[args].FSFA_ds
		call	DOSDiskCopyUnlockInfoShared
	;
	; Call ourselves to format the disk.
	; 
		lea	bx, ss:[args]		; ss:bx <- FSFormatArgs
		push	bp
		call	DOSDiskFormat
		pop	bp
		jc	done
	;
	; Fetch the 32-bit ID that gave to the disk and save it for mangling
	; the boot sector we got from the source disk.
	; 
		call	DOSDiskCopyLockInfoShared
		mov	si, ds:[DCD_realDest]
		call	DOSDiskID
		call	DOSDiskCopyUnlockInfoShared
		movdw	ds:[DCD_destDiskID], cxdx
		jnc	done
		mov	ax, ERR_COULD_NOT_REGISTER_FORMATTED_DESTINATION_DISK
done:
		.leave
		ret
DOSDiskCopyPerformFormat endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyFormatCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call our own callback telling it the percentage of the
		disk that's formatted.

CALLED BY:	(INTERNAL) DOSDiskCopyFormatDest via DOSDiskFormat	
PASS:		ds	= DiskCopyData
		ax	= percentage done
RETURN:		carry set to cancel
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyFormatCallback proc	far
		uses	dx
		.enter
		mov_tr	dx, ax		; dx <- percentage
		mov	ax, DCC_REPORT_FORMAT_PCT
		call	DOSDiskCopyCallCallback
		.leave
		ret
DOSDiskCopyFormatCallback endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyTransferFATEntries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transfer the values for the current cluster range from the
		source FAT to the destination, ensuring that none of the
		destination clusters is marked bad.

CALLED BY:	(INTERNAL) DOSDiskCopyWriteClusters
PASS:		ds	= DiskCopyData
		si	= first cluster to write
		cx	= # bytes to write
RETURN:		carry set on error:
			ax	= DiskCopyError
		carry clear if ok
DESTROYED:	es, si, dx, cx, bx, di allowed
SIDE EFFECTS:	entries in the destination FAT are abused.

PSEUDO CODE/STRATEGY:
		Calculate # of clusters in range
		Point to first entry in source FAT

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyTransferFATEntries proc	near
		uses	bp
		.enter
		mov_tr	ax, cx
		clr	dx
		div	ds:[DCD_clusterSize]
		mov_tr	bp, ax			; bp <- # clusters

	;
	; Set up es:si to point to the proper place in the source FAT, and
	; es:di to point to the proper place in the dest FAT.
	; 
		mov	bx, ds:[DCD_fatBuffer]
		call	MemDerefES
		mov	si, ds:[DCD_rangeStartFO]
		mov	di, ds:[DCD_destFATOff]
		add	di, si

		mov	cl, ds:[DCD_rangeStartFT]	; cl <- initial toggle
							;  value
		mov	dx, 0xffff
		tst	ds:[DCD_fatSize]
		jz	setClusterBad
		mov	dh, 0x0f
setClusterBad:
		mov	bx, FAT_CLUSTER_BAD
		and	bx, dx
entryLoop:
	;
	; es:si	= source FAT entry
	; es:di	= dest FAT entry
	; bx	= FAT_CLUSTER_BAD, to proper # bits
	; dx	= mask for obtaining cluster entry
	; cl	= fatToggle
	; bp	= # clusters to process
	;
	; Fetch dest FAT's value so we can see if it's bad.
	; 
		mov	ax, es:[di]
		shr	ax, cl
		and	ax, dx
		cmp	ax, bx
		je	error
EC <		tst	ax						>
EC <		ERROR_NZ	GASP_CHOKE_WHEEZE			>
	;
	; Dest entry not bad, so fetch source and merge it into the dest.
	; 
		mov	ax, dx
		rol	ax, cl		; ax <- mask for fetching source
					;  cluster entry properly shifted
		and	ax, es:[si]	; ax <- cluster entry, properly
					;  shifted
		or	es:[di], ax	; merge into dest

		dec	bp
		jz	done		; (carry cleared by OR)

		inc	si		; always advance at least 1
		inc	di
		xor	cl, ds:[DCD_fatSize]	; change toggle
		jnz	entryLoop	; => now odd cluster, so advance no more

		inc	si		; else advance to new 3-byte set
		inc	di
		jmp	entryLoop
done:
		.leave
		ret

error:
	;
	; Found a bad cluster on the dest where a good cluster needs to be.
	; Don't even try to write to it, but declare an error.
	; 
		mov	ax, ERR_CANT_WRITE_TO_DEST
		stc
		jmp	done
DOSDiskCopyTransferFATEntries endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyWriteFATs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out the destination FAT we've been building.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ds	= DiskCopyData
RETURN:		carry set on error:
			ax	= ERR_CANT_WRITE_TO_DEST
		carry clear if ok:
			ax	= destroyed
DESTROYED:	bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyWriteFATs proc	near
		.enter
		call	DOSDiskCopyLockInfoShared
	;
	; Set up most registers for DOSWriteSectors.
	; 	dx	= sector number
	; 	ds:di	= data to write
	; 	cx	= # sectors to write
	; 	es:si	= DriveStatusEntry
	;
	; In addition:
	; 	bl	= # FATs left to write.
	; 
		mov	dx, ds:[DCD_bpb].BPB_numReservedSectors
		mov	di, ds:[DCD_destFATOff]
		mov	cx, ds:[DCD_bpb].BPB_sectorsPerFAT
		mov	si, ds:[DCD_realDest]

		push	ds
		push	{word}ds:[DCD_bpb].BPB_numFATs
		mov	bx, ds:[DCD_fatBuffer]
		call	MemLock
		mov	ds, ax
		pop	bx
fatLoop:
		push	bx
	;
	; Write this copy out.
	; 
		clr	bx
		call	DOSWriteSectors
		pop	bx
		jc	error
	;
	; Advance to next FAT on the disk.
	; 
		add	dx, cx
		dec	bl
		jnz	fatLoop
done:
	;
	; Recover our beloved DiskCopyData and unlock the FAT buffer.
	; 
		pop	ds
		mov	bx, ds:[DCD_fatBuffer]
		call	MemUnlock

		.leave
		ret
error:
		mov	ax, ERR_CANT_WRITE_TO_DEST
		stc
		jmp	done
DOSDiskCopyWriteFATs endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSDiskCopyCopyDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Main loop for copying a disk.

CALLED BY:	(INTERNAL) DOSDiskCopy
PASS:		ds	= DiskCopyData
RETURN:		carry set on error:
			ax	= DiskCopyError/FormatError
		carry clear if ok:
			ax	= destroyed
DESTROYED:	bx, cx, dx, si, di, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSDiskCopyCopyDisk		proc	far
		.enter
		clr	ax
		mov	ds:[DCD_firstCluster], ax	; root dir
		mov	ds:[DCD_procUsedClust], ax
	;
	; Start at beginning of FAT, in spite of two reserved clusters. In our
	; world, cluster 0 is the boot sector and cluster 1 is the root
	; directory.
	; 
		mov	ds:[DCD_fatToggle], al
		mov	ds:[DCD_fatOffset], ax
processLoop:

if _REDMS4	
		call	getDiskGeo
endif

	;
	; Read a mess o' things
	; 
		mov	ds:[DCD_procClustCB], offset DOSDiskCopyReadClusters
		mov	ds:[DCD_callbackType], DCC_REPORT_READ_PCT
		push	ds:[DCD_fatOffset],
			{word}ds:[DCD_fatToggle],
			ds:[DCD_procUsedClust]

		call	DOSDiskCopyProcessClusters

			CheckHack <offset DCD_fatToggle+1 eq offset DCD_fatSize>
		pop	ds:[DCD_fatOffset],
			{word}ds:[DCD_fatToggle],
			ds:[DCD_procUsedClust]
		jc	jmpDone
		jmp	getDestDisk
jmpDone:
		jmp	done
	;
	; Don't change DCD_firstCluster, as we need it for writing. If single-
	; drive copy, use the callback to get the destination disk.
	;
getDestDisk:

		mov	ax, DCC_GET_DEST_DISK
		mov	si, offset DCD_args.FSCA_dest
		call	DOSDiskCopyAskForDisk
		jc	jmpDone

		test	ds:[DCD_status], mask DCS_SINGLE_DRIVE
		jz	haveDest
	;
	; Make sure the user did as (s)he's told.
	; If we get an error fetching the ID, then just assume the
	; disk isn't formatted yet.
	;
		mov	si, ds:[DCD_realDest]		; dest disk handle
		call	getID
		jc	haveDest

		tstdw	ds:[DCD_destDiskID]
		jnz	checkDestID
	;
	; The destination disk doesn't yet have an ID, so just make
	; sure the ID isn't the same as the source ID
	;
		mov	si, ds:[DCD_args].FSCA_disk
		call	cmpID
		je	getDestDisk
		jmp	haveDest
		
checkDestID:
		cmpdw	cxdx, ds:[DCD_destDiskID]
		jne	getDestDisk
		jmp	haveDest
haveDest:

if _REDMS4	
		call	getDiskGeo
endif

	;
	; Write what we read.
	; 
		mov	ds:[DCD_procClustCB], offset DOSDiskCopyWriteClusters
		mov	ds:[DCD_callbackType], DCC_REPORT_WRITE_PCT
		call	DOSDiskCopyProcessClusters
		jc	done
	;
	; Advance DCD_firstCluster to be the one after the last one processed
	; (returned in DCD_curCluster). If still more clusters to handle,
	; loop.
	; 
		mov	ax, ds:[DCD_curCluster]
		mov	ds:[DCD_firstCluster], ax
		cmp	ax, ds:[DCD_numClusters]
		jae	writeDestFATs

getSourceDisk:
		mov	ax, DCC_GET_SOURCE_DISK
		mov	si, offset DCD_args.FSCA_source
		call	DOSDiskCopyAskForDisk
		jc	done
	;
	; Make sure the user did as (s)he's told
	;
		test	ds:[DCD_status], mask DCS_SINGLE_DRIVE
		LONG jz	processLoop
		
		mov	si, ds:[DCD_args].FSCA_source
		call	getID
		jc	getSourceDisk
		
		mov	si, ds:[DCD_args].FSCA_disk
		call	cmpID
		jne	getSourceDisk
		jmp	processLoop
		
done:
		.leave
		ret

writeDestFATs:
	;
	; Write the destination FAT to the destination disk as many times as
	; necessary.
	; 
		call	DOSDiskCopyWriteFATs
		jmp	done


if _REDMS4

getDiskGeo	label	near
	;
	; Force a read of the source disk.   In Redwood, Datalight DOS seems
	; to screw up on the first read-sector on the second pass through here,
	; because of a disk changed error.   We'll attempt to head that off
	; by doing a disk read here.  -cbh 3/14/94
	;
		push	bx, dx, ax, ds, es, bp, cx
		call	DOSPreventCriticalErr
		mov	bx, ds:[DCD_args].FSCA_disk
		call	DiskGetDrive
		mov	dl, al
		inc	dl			; 1-based
		mov	ah, MSDOS_GET_DISK_GEOMETRY
		call	DOSUtilInt21
		call	DOSAllowCriticalErr
		pop	bx, dx, ax, ds, es, bp, cx
		retn
endif

;;--------------------
getID:
		call	DOSDiskCopyLockInfoShared
		call	DOSDiskID		; cx:dx - ID
		call	DOSDiskCopyUnlockInfoShared
		retn

;;--------------------
cmpID:
		call	DOSDiskCopyLockInfoShared
		cmpdw	cxdx, es:[si].DD_id
		call	DOSDiskCopyUnlockInfoShared
		retn
DOSDiskCopyCopyDisk		endp


DiskCopyCode	ends
