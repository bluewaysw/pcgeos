COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel FileSystem Support -- Skeleton Driver
FILE:		fsdSkeleton.asm

AUTHOR:		Adam de Boor, Oct 16, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/16/91	Initial revision


DESCRIPTION:
	Skeleton FS Driver for loading the real one, only.
		

	$Id: fsdSkeleton.asm,v 1.1 97/04/05 01:17:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;
;			  SKELETON FS DRIVER
;
; This fake driver is used only in the opening/loading of the primary
; FS driver. As such, it is very, very simple. Any SFN returned by this thing
; is simply the actual DOS handle. All disks are identified as having a
; 0 32-bit volume ID and being always valid, etc.
;
; The driver sits in kinit, with the strategy vector for fileSkeletonDriver
; being relocated by InitFSD at the right moment.
;------------------------------------------------------------------------------

kinit		segment

if DBCS_PCGEOS

fsFunctions	nptr	FSDSInit,		; DR_INIT
			FSDSDoNothing,		; DR_EXIT
			FSDSError,		; DR_SUSPEND
			FSDSError,		; DR_UNSUSPEND
			FSDSError,		; DRE_TEST_DEVICE
			FSDSError,		; DRE_SET_DEVICE
			FSDSDiskID,		; DR_FS_DISK_ID
			FSDSDiskInit,		; DR_FS_DISK_INIT
			FSDSError,		; DR_FS_DISK_LOCK
			FSDSDoNothing,		; DR_FS_DISK_UNLOCK
			FSDSError,		; DR_FS_DISK_FORMAT
			FSDSDiskFindFree,	; DR_FS_DISK_FIND_FREE
			FSDSDiskInfo,		; DR_FS_DISK_INFO
			FSDSError,		; DR_FS_DISK_RENAME
			FSDSError,		; DR_FS_DISK_COPY
			FSDSError,		; DR_FS_DISK_SAVE
			FSDSError,		; DR_FS_DISK_RESTORE
			FSDSCheckNetPath,	; DR_FS_CHECK_NET_PATN
			FSDSCurPathSet,		; DR_FS_CUR_PATH_SET
			FSDSCurPathGetID,	; DR_FS_CUR_PATH_GET_ID
			FSDSCurPathCallPrimaryIfLoaded,; DR_FS_CUR_PATH_DELETE
			FSDSCurPathCallPrimaryIfLoaded,; DR_FS_CUR_PATH_COPY
			FSDSHandleOp,		; DR_FS_HANDLE_OP
			FSDSAllocOp,		; DR_FS_ALLOC_OP
			FSDSPathOp,		; DR_FS_PATH_OP
			FSDSCompareFiles,	; DR_FS_COMPARE_FILES
			FSDSError,		; DR_FS_FILE_ENUM
			FSDSDoNothing,		; DR_FS_DRIVE_LOCK
			FSDSDoNothing,		; DR_FS_DRIVE_UNLOCK
			FSDSDoNothing		; DR_FS_CONVERT_STRING
else

fsFunctions	nptr	FSDSInit,		; DR_INIT
			FSDSDoNothing,		; DR_EXIT
			FSDSError,		; DR_SUSPEND
			FSDSError,		; DR_UNSUSPEND
			FSDSError,		; DRE_TEST_DEVICE
			FSDSError,		; DRE_SET_DEVICE
			FSDSDiskID,		; DR_FS_DISK_ID
			FSDSDiskInit,		; DR_FS_DISK_INIT
			FSDSError,		; DR_FS_DISK_LOCK
			FSDSDoNothing,		; DR_FS_DISK_UNLOCK
			FSDSError,		; DR_FS_DISK_FORMAT
			FSDSDiskFindFree,	; DR_FS_DISK_FIND_FREE
			FSDSDiskInfo,		; DR_FS_DISK_INFO
			FSDSError,		; DR_FS_DISK_RENAME
			FSDSError,		; DR_FS_DISK_COPY
			FSDSError,		; DR_FS_DISK_SAVE
			FSDSError,		; DR_FS_DISK_RESTORE
			FSDSCheckNetPath,	; DR_FS_CHECK_NET_PATN
			FSDSCurPathSet,		; DR_FS_CUR_PATH_SET
			FSDSCurPathGetID,	; DR_FS_CUR_PATH_GET_ID
			FSDSCurPathCallPrimaryIfLoaded,; DR_FS_CUR_PATH_DELETE
			FSDSCurPathCallPrimaryIfLoaded,; DR_FS_CUR_PATH_COPY
			FSDSHandleOp,		; DR_FS_HANDLE_OP
			FSDSAllocOp,		; DR_FS_ALLOC_OP
			FSDSPathOp,		; DR_FS_PATH_OP
			FSDSCompareFiles,	; DR_FS_COMPARE_FILES
			FSDSError,		; DR_FS_FILE_ENUM
			FSDSDoNothing,		; DR_FS_DRIVE_LOCK
			FSDSDoNothing		; DR_FS_DRIVE_UNLOCK

endif

CheckHack <($-fsFunctions) eq FSFunction>

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Strategy routine for skeleton fs driver

CALLED BY:	File routines
PASS:		di	= function to invoke
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSStrategy	proc	far
		.enter
		call	cs:fsFunctions[di]
		.leave
		ret
FSDSStrategy	endp

;
; For XIP systems, the kinit resource will not be mapped in, so all calls to
; the skeleton driver must go through this stub, which calls the strategy
; routine via ResourceCallInt.
;
if	FULL_EXECUTE_IN_PLACE
FSResident	segment
FSDSStrategyStub	proc	far
	call	FSDSStrategy
	ret
FSDSStrategyStub	endp
FSResident	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSDoNothing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do-nothing routine to handle the three functions with which
		we need do nothing: exit, allocate dos handle, free dos handle

CALLED BY:	DR_EXIT, DR_FS_ALLOC_DOS_HANDLE, DR_FS_FREE_DOS_HANDLE
PASS:		?
RETURN:		carry clear, ?
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		We need a handler for DR_EXIT in case the system aborts before
		the real driver is loaded.
		
		We need do nothing for DR_FS_ALLOC_DOS_HANDLE since we return
		the DOS handle as the SFN from DR_FS_ALLOC_OP.
		
		We need do nothing for DR_FS_FREE_DOS_HANDLE, as we've no way
		to do it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSDoNothing	proc	near
		.enter
		clc
		.leave
		ret
FSDSDoNothing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function should never need calling.

CALLED BY:	DR_SUSPEND, DR_UNSUSPEND, DRE_TEST_DEVICE, DRE_SET_DEVICE,
       		DR_FS_DISK_LOCK, DR_FS_DISK_FORMAT, DR_FS_DISK_RENAME, 
		DR_FS_DISK_COPY, DR_FS_DISK_SAVE, DR_FS_DISK_RESTORE, 
		DR_FS_FILE_ENUM
PASS:		?
RETURN:		?
DESTROYED:	?

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSError	proc	near
EC <		ERROR	ATTEMPTED_TO_PERFORM_UNSUPPORTED_FUNCTION_BEFORE_APPROPRIATE_IFS_DRIVER_WAS_LOADED >
NEC <		.enter							>
NEC <		stc							>
NEC <		.leave							>
NEC <		ret							>
FSDSError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize ourselves and the kernel & ini file handles

CALLED BY:	DR_INIT
PASS:		es	= FSIR
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSInit	proc	near
		uses	ax, bx, dx, ds, es, si
		.ENTER
	;
	; First create a handle for the writable .ini file.
	; 
		LoadVarSeg	ds, ax
		mov	si, ds
		mov	bx, ds:[loaderVars].KLV_initFileHan

		;
		; if bx=0, .ini file was opened r/o, and then closed, therefore
		; don't worry about creating a handle for it.
		;
		tst	bx
		jz	createKernelHandle

		clr	dx		; not geos file
		mov	al, ds:[loaderVars].KLV_initFileDrive
		mov	ah, FileAccessFlags <FE_EXCLUSIVE, FA_READ_WRITE>
		call	FSDSInitFileHandle
		mov	ds:[loaderVars].KLV_initFileHan, bx

createKernelHandle:
	;
	; Now create a handle for the kernel.
	; 
if	not KERNEL_EXECUTE_IN_PLACE and (not FULL_EXECUTE_IN_PLACE)
		mov	al, ds:[loaderVars].KLV_kernelFileDrive
		mov	ah, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		mov	bx, handle 0
		mov	ds, ds:[bx].HM_addr	; ds <- kernel core block
		mov	bx, ds:[GH_geoHandle]	; bx <- kernel file handle
		mov	dx, TRUE		; is geos file
		call	FSDSInitFileHandle
		mov	ds:[GH_geoHandle], bx
	; and create a ThreadLock for the Kernel
	;
	; We used to use a semaphore to allow only one thread at a time
	; to load a resource, but now we are using a threadlock so
	; that we can recursively load resources.  This is required
	; since we allow the async biffing of VM based Object blocks.
	; An example:  we are trying to load in a resource, so we need
	; to find room.  One of the blocks we toss out is an Object
	; block requiring relocation.  This locks down the owner and
	; any imported libraries which may include our initial
	; resource.  Now, this recursive loading won't happen to the
	; kernel, but the other routines effected by this change
	; (GLLoadResourcePrelude, etc) are expecting a threadlock, so
	; we'll give them one.. 
	;
		mov	es, si			; es <- kdata
		mov	si, bx			; si <- kernel file handle
		call	ThreadAllocThreadLock	; bx <- new semaphore
		mov	es:[si].HF_semaphore, bx
		mov	es:[bx].HS_owner, handle 0 ; set semaphore's owner
endif
		.leave
		ret
FSDSInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSInitFileHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a file handle for something opened by the loader
		and passed to us.

CALLED BY:	FSDSInit
PASS:		es	= FSIR
		bx	= DOS handle
		dx	= TRUE/FALSE if file is/isn't a geos file
		al	= drive number on which the file was opened
		ah	= FileAccessFlags with which the file was opened
RETURN:		bx	= pc/geos file handle
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSInitFileHandle proc	near
		uses	ds, dx, si, di
		.enter
	;
	; Get the disk in the drive, registering it in case we've not
	; encountered this drive before.
	; 
		push	bx
		call	DiskRegisterDiskSilently
		mov	si, bx
		pop	bx
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
		mov	al, ah   		; al <- FileAccessFlags
		mov	ah, FSAOF_OPEN
		mov_tr	di, ax			; di.low <- FullFileAccessFlags
						; di.high <- FSAOF_*
		mov_tr	ax, bx			; al <- SFN (DOS handle)
						; ah <- non-zero if device
						;  (DOS handles < 256, so
						;  always 0)
		call	AllocateFileHandle
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
   		mov_tr	bx, ax
		.leave
		ret
FSDSInitFileHandle endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSDiskID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	All disks we ID have a 0 for their volume ID and are always
		valid. When the proper FSD for the drive is loaded, we (the
		kernel) will re-ID the disk anyway.

CALLED BY:	DR_FS_DISK_ID
PASS:		es:si	= DriveStatusEntry for the drive
RETURN:		carry set if ID couldn't be determined
		carry clear if it could:
			cx:dx	= 32-bit ID
			al	= DiskFlags for the disk
			ah	= MediaType (MEDIA_FIXED_DISK)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSDiskID	proc	near
		.enter
	;
	; ID is always 0 for these disks.
	;
		clr	cx
		mov	dx, cx
	;
	; And these disks are always writable and never need to be validated/
	; locked.
	; 
		mov	al, mask DF_WRITABLE or mask DF_ALWAYS_VALID
		mov	ah, MEDIA_FIXED_DISK
		.leave
		ret
FSDSDiskID	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSDiskInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the volume label of the passed disk.

CALLED BY:	DR_FS_DISK_INIT
PASS:		es:si	= DiskDesc for the disk
		ah	= FSDNamelessAction to be passed to FSDGenNameless if
			  the disk has no volume label
RETURN:		carry set on failure
		carry clear on success:
			es	= fixed up if a chunk was allocated by the FSD
			DD_volumeLabel filled in.
			DD_private holding the offset of a chunk of private
				data, if one was allocated.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Since this can only be called during initialization, when
		no multitasking is going on, we don't need synchronization
		on our setting the DTA to whatever we damn well want to
		when we ask DOS for the volume label via an FCB.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/18/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSDiskInit	proc	near
volFCB		local	FCB		; FCB we need to use to locate the
					;  volume label (DOS 2.X has bugs with
					;  4eh(cx=FA_VOLUME))
dta		local	FCB		; DTA for DOS to use during volume
					;  location (needs an unopened
					;  extended FCB).
		uses	ax, cx, dx, si, di, ds
		.enter

	;
	; Initialize the FCB: all 0 except:
	; 	FCB_type	0xff to indicate extended FCB
	; 	FCB_attributes	indicates volume label wanted
	; 	FCB_volume	holds drive number
	;	FCB_name	set to all '?' to match any characters

		mov	di, es:[si].DD_drive
		mov	dl, es:[di].DSE_number
		inc	dx		; make it 1-origin

		push	es
		segmov	es,ss
		lea	di, ss:[volFCB]
		mov	cx, size volFCB
		clr	al
		rep	stosb
		mov	ss:[volFCB].FCB_type, 0xff	; Mark as extended
		mov	ss:[volFCB].FCB_attributes, mask FA_VOLUME; Want volume
		mov	ss:[volFCB].FCB_volume, dl		;set drive

		lea	di, ss:[volFCB].FCB_name
		mov	cx, size volFCB.FCB_name
		mov	al,'?'
		rep 	stosb
		pop	es

		push	ax	; save FSDNamelessAction
	;
	; Set the DTA to our temporary one on the stack, here, to give DOS
	; enough work room.
	;
		segmov	ds, ss
		lea	dx, ss:[dta]			; Point DOS at DTA
		mov	ah, MSDOS_SET_DTA
		int	21h
	;
	; Now ask DOS to find the durn thing.
	; 
		lea	dx, ss:[volFCB]
		mov	ah,MSDOS_FCB_SEARCH_FOR_FIRST
		int	21h

		tst	al
		pop	ax		; ah <- FSDNamelessAction
		jnz	nameless

	;
	; Copy the volume label into the disk descriptor from the DTA.
	; 
		lea	di, es:[si].DD_volumeLabel
		lea	si, ss:[dta].FCB_name
			CheckHack <size FCB_name ge length DD_volumeLabel>
		mov	cx, length DD_volumeLabel
if DBCS_PCGEOS
 		clr	ah
charLoop:
		lodsb				;al <- DOS SBCS
		stosw				;store GEOS DBCS
		loop	charLoop
else
		rep	movsb
endif

done:
		.leave
		ret

nameless:
	;
	; Disk has no volume label, so make one up.
	; 
		call	FSDGenNameless
		jmp	done
FSDSDiskInit	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSDiskFindFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the free space available on the given disk.

CALLED BY:	DR_FS_DISK_FIND_FREE
PASS:		es:si	= DiskDesc of disk whose free space is desired (disk
			  is locked into drive)
RETURN:		carry clear if successful:
			dx:ax	= # bytes free on the disk.
		carry set if error:
			ax	= error code
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSDiskFindFree proc	near
		uses	si, bx, cx
		.enter
		mov	si, es:[si].DD_drive
		mov	dl, es:[si].DSE_number
		inc	dx		; (1-byte inst)
		mov	ah, MSDOS_FREE_SPACE
		int	21h
		cmp	ax, 0xffff
		je	fail
		
		mul	cx			; dx:ax = bytes/cluster
						;  (if > 64K, we're in trouble)
EC <		ERROR_C	FSD_BYTES_PER_CLUSTER_OVER_64K			>
		mul	bx			; dx:ax = bytes free
		clc
done:
		.leave
		ret
fail:
		mov	ax, ERROR_INVALID_DRIVE
		stc
		jmp	done
FSDSDiskFindFree endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch detailed info about a disk in one swell foop.

CALLED BY:	DR_FS_DISK_INFO
PASS:		bx:cx	= fptr.DiskInfoStruct
		es:si	= DiskDesc of disk whose info is desired (disk is
			  locked shared in the drive)
RETURN:		carry set on error
			ax	= error code
		carry clear if successful
			buffer filled in.
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSDiskInfo	proc	near
		uses	bx, cx, dx, si, di, ds, es
		.enter
	;
	; Save address of structure we're to fill in once we've got the info.
	; 
		push	bx, cx
	;
	; Fetch the drive number from the DriveStatusEntry and ask DOS about
	; the disk.
	; 
		mov	bx, es:[si].DD_drive
		mov	dl, es:[bx].DSE_number
		inc	dx
		mov	ah, MSDOS_FREE_SPACE
		int	21h		; ax <- sectors/cluster
					; bx <- free clusters
					; cx <- bytes/sector
					; dx <- total clusters
		cmp	ax, 0xffff
		je	fail
	;
	; Now fill in the structure.
	; 
		pop	ds, di		; ds:di <- structurre to fill in

		push	dx		; save total clusters
		mul	cx		; ax <- bytes/cluster
		mov	ds:[di].DIS_blockSize, ax

		mul	bx		; dx:ax <- bytes free
		mov	ds:[di].DIS_freeSpace.low, ax
		mov	ds:[di].DIS_freeSpace.high, dx

		pop	ax		; ax <- total cluster
		mul	ds:[di].DIS_blockSize	; dx:ax <- bytes total
		mov	ds:[di].DIS_totalSpace.low, ax
		mov	ds:[di].DIS_totalSpace.high, dx
		
		segxchg	ds, es
		add	si, offset DD_volumeLabel	; ds:si <- source
		add	di, offset DIS_name		; es:di <- dest
		CheckHack <length DD_volumeLabel le length DIS_name>
SBCS <		mov	cx, size DD_volumeLabel				>
SBCS <		rep	movsb						>
DBCS <		mov	cx, length DD_volumeLabel			>
DBCS <		rep	movsw						>
		clc
done:
		.leave
		ret
fail:
		stc
		mov	ax, ERROR_INVALID_DRIVE
		jmp	done
FSDSDiskInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSCheckNetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed network path (\\mumble) belongs to us,
		and return a disk handle we can use if so.

CALLED BY:	DR_FS_CHECK_NET_PATH
PASS:		ds:dx	= path to check
		es	= FSInfoResource locked shared.
RETURN:		carry set if path belongs to this net but cannot be reached
			(e.g. not logged into the server)
		carry clear if call ok:
			bx	= disk handle to use, 0 if path not ours
			ds:dx	= file path to actually use (may be different,
				  but doesn't have to be)
			es	= new location of FSIR if disk handle had
				  to be allocated
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		What the heck do I do here?

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSCheckNetPath proc	near
		.enter
		clr	bx	; just say it ain't ours, for now. In the future
				;  we should create a funky disk handle for
				;  each net path in the std path block and look
				;  for it here...
		.leave
		ret
FSDSCheckNetPath endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSCurPathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the thread's current working directory to be that
		passed in, if the directory actually exists. If the change
		is successful, copy the path into the thread's current-path
		block. Note: if the filesystem on which the directory
		resides is case-insensitive, the letters in the path should
		be upcased before being copied into the block.

		The FSD may add whatever data it needs at FP_private, pointing
		FP_path beyond the data stored there. This might be used
		to store the starting cluster or caching information, or
		to store the native path, if virtual paths are supported
		by the FSD.

		In any case, the FSD will likely need to realloc the thread's
		path block before copying the new path in.

CALLED BY:	DR_FS_CUR_PATH_SET
PASS:		ds:dx	= path to set, w/o drive specifier
		es:si	= disk on which the path resides
RETURN:		carry clear if directory-change was successful:
			TPD_curPath block altered to hold the new path and
			any private data required by the FSD (the disk
			handle will be set by the kernel). The FSD may
			have resized the block.
			FP_pathInfo must be set to FS_NOT_STANDARD_PATH
			FP_stdPath must be set to SP_NOT_STANDARD_PATH
		carry set if the directory to which the thread was attempting
		    to change doesn't exist
			ax	= ERROR_PATH_NOT_FOUND
			TPD_curPath may not be altered in any way.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Set default drive
		Set current path
		If error, return error
		Else
			figure length of new path
			resize path block to hold *FP_path+that many bytes
			store drive specifier
			ask DOS for current path
			adjust FP_pathInfo and FP_stdPath
			return carry clear
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSCurPathSet	proc	near
		uses	bx, cx, dx, ds
		.enter

	;
	; To deal with the optimization we "know" is going on in the FSDs,
	; and on the assumption that calling the primary FSD, which is dealing
	; with the underlying operating system, is no worse than issuing the
	; DOS calls we make here, even if the primary FSD has no clue about
	; the drive to which we're setting the current path, we redirect
	; all calls to this function to the primary FSD, if it's been loaded.
	; 
		cmp	es:[FIH_primaryFSD], offset fileSkeletonDriver
		je	doItOurSelves
		mov	bx, es:[FIH_primaryFSD]
		push	di
		push	bp
		call	es:[bx].FSD_strategy
		pop	bp
		pop	di
		jmp	exit
doItOurSelves:
	;
	; Attempt to switch to the passed drive & path. Again, we have no
	; need of synchronization since we're running during kernel
	; initialization, when no multi-tasking takes place.
	; 
		call	FSDSSetDefaultDriveFromDisk
		mov	ah, MSDOS_SET_CURRENT_DIR
DBCS <		call	FSDGeosToDosDSDXInt21				>
SBCS <		int	21h						>
		jc	exit
	;
	; Make our life easier by just unlocking the FSIR now.
	; 
		call	FSDUnlockInfoShared
	;
	; Switch successful. Now we have the joy of setting up the path
	; block. To make life easier for our caller, we allocate the thing
	; large enough to hold a FilePath plus a complete DOS path, even
	; though we store nothing extra ourselves.
	; 
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	ds, ax

		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov	dx, size FilePath + MSDOS_PATH_BUFFER_SIZE
		cmp	ax, dx
		jae	fetchPath
		mov	ax, dx
		clr	cx
		call	MemReAlloc
		jc	failUnlock
		mov	ds, ax
fetchPath:
	;
	; Tell the old FSD we're taking over.
	; 
		call	FSDInformOldFSDOfPathNukage
	;
	; We have no private data to store.
	; 
		mov	di, offset FP_private
		mov	ds:[FP_path], di
	;
	; Perform the remaining pieces of initialization.
	; 
		mov	ds:[FP_stdPath], SP_NOT_STANDARD_PATH
		mov	ds:[FP_pathInfo], FS_NOT_STANDARD_PATH
unlock:
	;
	; And unlock the path block again; it's ready to go.
	; 
		mov	bx, ss:[TPD_curPath]
		call	MemUnlock
done::
	;
	; Restore ES to pointing to the FSIR again, now we're done with
	; nesting problems...
	; 
		pushf
		push	ax
		call	FSDLockInfoShared
		mov	es, ax
		pop	ax
		popf
exit:
		.leave
		ret
failUnlock:
	;
	; Couldn't enlarge the path block, so return an appropriate error
	; code explaining why we couldn't change directories.
	; 
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	unlock
FSDSCurPathSet	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSCurPathGetID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the 32-bit ID number for the thread's current directory.
		If the filesystem doesn't support such an ID number, return
		FILE_NO_ID.

CALLED BY:	DR_FS_CUR_PATH_GET_ID
PASS:		es:si	= DiskDesc on which path is located
RETURN:		cx:dx	= 32-bit ID
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSCurPathGetID proc	near
		.enter
		mov	cx, FILE_NO_ID shr 16
		mov	dx, FILE_NO_ID and 0xffff
		.leave
		ret
FSDSCurPathGetID endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSCurPathCallPrimaryIfLoaded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The passed path block is being deleted or duplicated by the
		kernel, or is being taken over by another FSD. 

		This routine may not cause the path block to be moved on
		the heap, should it be locked when this routine is called.

CALLED BY:	DR_FS_CUR_PATH_DELETE, DR_FS_CUR_PATH_COPY

PASS:		bx	= path handle
		es:si	= disk handle on which path is located
RETURN:		nothing
DESTROYED:	si

PSEUDO CODE/STRATEGY:
		We don't actually have any private data, but we have to
		field this call so we can pass it off to the primary FSD,
		if it's been loaded. This is to compensate for the action
		of our FSDSCurPathSet compatriot.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/25/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSCurPathCallPrimaryIfLoaded proc	near
		uses	di,bp
		.enter
		mov	bp, es:[FIH_primaryFSD]
		cmp	bp, offset fileSkeletonDriver
		je	done
		call	es:[bp].FSD_strategy
done:
		.leave
		ret
FSDSCurPathCallPrimaryIfLoaded endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSSetDefaultDriveFromDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the DOS default drive to that in which the passed
		disk resides.

CALLED BY:	FSDSAllocOp, FSDSCurPathSet
PASS:		es:si	= DiskDesc of disk whose drive is to become the
			  current one
RETURN:		nothing
DESTROYED:	nothing (flags preserved)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSSetDefaultDriveFromDisk proc near
		uses	bx, ax, dx
		.enter
		pushf
		mov	bx, es:[si].DD_drive
		mov	dl, es:[bx].DSE_number
		mov	ah, MSDOS_SET_DEFAULT_DRIVE
		int	21h
		popf
		.leave
		ret
FSDSSetDefaultDriveFromDisk endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSAllocOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a filesystem operation that will allocate a new file
		handle.
PASS:		al	= FullFileAccessFlags
		ah	= FSAllocOpFunction to perform.
		ds:dx	= path
		es:si	= DiskDesc on which the operation will take place,
			  locked into drive (FSInfoResource and affected drive
			  locked shared). si may well not match the disk handle
			  of the thread's current path, in which case ds:dx is
			  absolute.

RETURN:		Carry clear if operation successful:
			al	= SFN of open file
			ah	= non-zero if opened to device, not file.
;			dx	= private data word for FSD
		Carry set if operation unsuccessful:
			ax	= error code.
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Since this is only used during initialization, when a single
		thread is running, we don't need to worry about DOS's current
		path being the thread's current path, as the code must have
		changed to the path through us before and we set it into DOS
		when we made the change, so it must still be there.
		
		The returned SFN is just the DOS handle we get back.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
allocOpDosOps	byte	MSDOS_OPEN_FILE,	; FSAOF_OPEN
			MSDOS_CREATE_TRUNCATE	; FSAOF_CREATE
FSDSAllocOp	proc	near
		uses	bx
		.enter
EC <		cmp	ah, FSAllocOpFunction				>
EC <		ERROR_AE	INVALID_ALLOC_OP			>
	;
	; Set the current DOS drive to the one on which the passed disk resides,
	; in case it's different from our current path's
	; 
		call	FSDSSetDefaultDriveFromDisk
	;
	; See whether we should strip out access modes. This is based on
	; the DOS version. If it's 3 or higher, we leave them in, on the
	; assumption the file may be on a network, where opening something
	; in "compatibility mode" is death to the sharing of executables.
	;
	; If an FSD comes along and objects, it can just mess with the
	; internal data :)
	; 
		push	ds
		LoadVarSeg	ds
		cmp	ds:[dosVersion].low, 3
		jae	nukeGeosBits

		andnf	al, mask FAF_MODE	; leave only the access mode, or
						;  the open will fail.
nukeGeosBits:
		andnf	al, not FAF_GEOS_BITS
		pop	ds
		
	;
	; Perform the desired operation.
	;
		clr	bx
		mov	bl, ah
		mov	ah, cs:[allocOpDosOps][bx]
		push	ax			; save access mode
DBCS <		call	FSDGeosToDosDSDXInt21				>
SBCS <		int	21h						>
		pop	bx			; bx <- requested access mode
		jc	done
	;
	; Since the file exists, we have to see if the caller requested
	; write access on a write-protected disk.
	; 
		cmp	bh, MSDOS_OPEN_FILE
		jne	figureDevice		; need only do this for
						;  FSAOF_OPEN
						
		inc	bx			; convert access mode from
						;  number to bits, b0 = read
						;  requested, b1 = write
						;  requested.
		test	bl, 2			; write requested?
		jz	figureDevice		; no => no check required
		
	;
	; Writing was requested. See if the destination disk is actually
	; writable.
	; 
		mov	bx, si			; es:bx <- disk
		push	ax			; save file handle, in case
						;  disk not writable
		call	FSDCheckDestWritable
		pop	ax			; ax <- file handle again
		jc	notWritable
figureDevice:
		mov_tr	bx, ax	; bx <- file handle
	;
	; See if open to a geos file, so we know to play games with
	; file positions.
	; 
			CheckHack <size GFH_signature eq 4>
		push	cx
		mov	cx, size GFH_signature
		clr	dx
		push	dx		; init signature to 0
		push	dx		;  in case file created/open for writing
					;  only
		mov	dx, sp

		push	ds
		segmov	ds, ss
		mov	ah, MSDOS_READ_FILE
		int	21h
		pop	ds

		clr	dx		; assume not geos
		pop	cx
		cmp	cx, GFH_SIG_1_2
		pop	cx
		jne	seekBackToStart
		cmp	cx, GFH_SIG_3_4
		jne	seekBackToStart
		not	dx		; flag geos file
seekBackToStart:
	;
	; Seek back to the start of the file, whether "start" means past the
	; header or the real start of the file...
	; 
		push	dx
		and	dx, size GeosFileHeader	; yes, I really mean "and"
		clr	cx
		mov	ax, MSDOS_POS_FILE shl 8 or FILE_POS_START
		int	21h
		pop	dx
		pop	cx
	;
	; Determine if the file is actually open to a device.
	; 
		push	dx		; save geos/not geos flag
		mov	ax, MSDOS_IOCTL_GET_DEV_INFO
		int	21h
		test	dx, mask DOS_IOCTL_IS_CHAR_DEVICE
		pop	dx
		mov_tr	ax, bx	; ah is already 0, since DOS file
					;  handles are always < 256
		jz	done
		not	ah		; flag as device
done:
	;
	; Return the DOS default drive to that on which the thread's current
	; path is located, so we can be certain elsewhere this is the case.
	; 
		pushf
		call	FSDGetThreadPathDiskHandle
		xchg	bx, si		; es:si <- disk handle
		call	FSDSSetDefaultDriveFromDisk
		xchg	bx, si		; recover passed disk handle
		popf
		
		.leave
		ret

notWritable:
	;
	; Destination is not writable, so close the file down and return the
	; appropriate error.
	; 
		mov_tr	bx, ax		; bx <- file handle
		mov	ah, MSDOS_CLOSE_FILE
		int	21h
		mov	ax, ERROR_WRITE_PROTECTED
		stc
		jmp	done
FSDSAllocOp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the read/write pointer for the file, dealing with
		hiding the header for the file.

CALLED BY:	FSDSHandleOp
PASS:		bx	= HandleFile
		cx:dx	= new position
		al	= positioning method
RETURN:		carry set on error:
			ax	= error code
		carry clear on success:
			dx:ax	= new position
		bxx	= DOS handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSPosition proc near
		uses	ds, cx, bp
		.enter
	;
	; If file not marked as geos, perform normal position call.
	; 
		LoadVarSeg	ds, bp
		tst	ds:[bx].HF_private	; geos file?
		mov	bl, ds:[bx].HF_sfn	; bx <- DOS handle
		mov	bh, 0
		jz	doNormalPosition	; => no
		
CheckHack <FILE_POS_START lt FILE_POS_RELATIVE and \
	   FILE_POS_END gt FILE_POS_RELATIVE>

		cmp	al, FILE_POS_RELATIVE
		jb	posStart
	;
	; Relative or end position: if the position goes into the header, reset
	; it to the end of the header. Since the offset for end can be
	; negative, it is possible to get back into the header, and the
	; adjustment of the resulting position is the same in both cases...
	; 
		mov	ah, MSDOS_POS_FILE
		int	21h
		jc	done
	    ;
	    ; Adjust resulting position to not include the header. If that
	    ; takes it below 0, we've got ourselves a problem...
	    ; 
		sub	ax, size GeosFileHeader
		sbb	dx, 0
		jnc	done
	    ;
	    ; Pretend it's a request for an absolute 0 position and fall
	    ; through to the absolute code...
	    ; 
		clr	cx
		mov	dx, cx
		mov	al, FILE_POS_START
posStart:
	;
	; Absolute position: just add the size of the header to the requested
	; size.
	; 
		add	dx, size GeosFileHeader
		adc	cx, 0
		mov	ah, MSDOS_POS_FILE
		int	21h
		jc	done
		
		sub	ax, size GeosFileHeader
		sbb	dx, 0		; will *not* generate a borrow
done:
		.leave
		ret

doNormalPosition:
		mov	ah, MSDOS_POS_FILE
		int	21h
		jmp	done
FSDSPosition 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on a file handle. If appropriate, the
		disk on which the file is located will have been validated.

CALLED BY:	DR_FS_HANDLE_OP
PASS:		ah	= FSHandleOpFunction to perform
		bx	= handle of open file
		es:si	= DiskDesc (FSInfoResource and affected drive locked
			  shared)
		other parameters as appropriate.
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful:
			return values depend on subfunction
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    FSHOF_READ		enum	FSHandleOpFunction
    ;	Pass:	ds:dx	= buffer to which to read
    ;		cx	= # bytes to read
    ;	Return:	carry clear if successful:
    ;			ax	= # bytes read
    Pass directly to DOS

    FSHOF_WRITE		enum	FSHandleOpFunction
    ;	Pass:	ds:dx	= buffer from which to write
    ;		cx	= # bytes to write
    ;	Return:	carry clear if successful:
    ;			ax	= # bytes written
    Pass directly to DOS

    FSHOF_POSITION	enum	FSHandleOpFunction
    ;	Pass:	al	= FileSeekModes
    ;		cx:dx	= offset to use
    ;	Return:	carry clear if successful:
    ;			dx:ax	= new absolute file position
    Pass directly to DOS

    FSHOF_TRUNCATE	enum	FSHandleOpFunction
    ;	Pass:	cx:dx	= size to which to truncate the file
    ;	Return:	nothing (besides carry & error code)
    ;
    Seek to position and write 0 bytes

    FSHOF_COMMIT	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing (besides carry & error code)
    If COMMIT call supported, use it, else duplicate & close

    FSHOF_LOCK		enum	FSHandleOpFunction
    ;	Pass:	cx	= top of inherited stack frame, set up as:
    ;			regionStart	local	dword
    ;			regionLength	local	dword
    ;					.enter
    ;	Return:	nothing (besides carry & error code)
    ;
    Pass directly to DOS

    FSHOF_UNLOCK	enum	FSHandleOpFunction
    ;	Pass:	cx	= top of inherited stack frame, set up as:
    ;			regionStart	local	dword
    ;			regionLength	local	dword
    ;					.enter
    ;	Return:	nothing (besides carry & error code)
    ;
    Pass directly to DOS

    FSHOF_GET_DATE_TIME	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx	= last modification time (FileTime record)
    ;		dx	= last modification date (FileDate record)
    ;
    Pass directly to DOS

    FSHOF_SET_DATE_TIME	enum	FSHandleOpFunction
    ;	Pass:	cx	= new modification time (FileTime record)
    ;		dx	= new modification date (FileDate record)
    ;	Return:	nothing (besides carry & error code)
    ;
    Pass directly to DOS

    FSHOF_FILE_SIZE	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	dx:ax	= size of the file
    ;
    Play games with SEEK

    FSHOF_ADD_REFERENCE	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing extra
    ;
    Pass directly to DOS

    FSHOF_CHECK_DIRTY	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	ax	= non-zero if file is dirty.
    ;
    ;	Notes:	This is used by the FileClose code in the kernel to determine
    ;		if it needs to lock the file's disk. IF THE FSD SAYS THE
    ;		FILE IS NOT DIRTY, THE DISK WILL NOT BE LOCKED AND NO I/O FOR
    ;		THE FILE MAY TAKE PLACE.
    ;
    Use GET_DEV_INFO ioctl to determine this.

    FSHOF_CLOSE		enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing extra
    ;
    ;	Notes:	As noted for FSHOF_CHECK_DIRTY, the disk will not be locked
    ;		unless the previous call to FSHOF_CHECK_DIRTY returned that
    ;		the file was dirty. If the disk is not locked, no I/O may
    ;		take place on behalf of the file, not even to update its
    ;		directory entry.
    ;
    Pass directly to DOS
		
    FSHOF_GET_FILE_ID	enum	FSHandleOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx:dx	= file ID
    ;
    Return FILE_NO_ID

    FSHOF_GET_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	ss:dx	= FSHandleExtAttrData
    ;		cx	= size of FHEAD_buffer, or # entries in same if
    ;			  FHEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    Used only for GeodeLoad support of the filesystem drivers, so return
    ERROR_ATTR_NOT_FOUND if file not flagged as geos file or if attribute
    other than FEA_FILE_TYPE requested. Return GFT_EXECUTABLE for FEA_FILE_TYPE

    FSHOF_SET_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	ss:dx	= FSHandleExtAttrData
    ;		cx	= size of FHEAD_buffer, or # entries in same if
    ;			  FHEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    Return ERROR_ATTR_CANNOT_BE_SET    

    FSHOF_COPY_EXT_ATTRIBUTES enum FSHandleOpFunction
    ;	Pass:	cx:dx	= file to which to copy the attributes
    ;	Return:	nothing extra
    Return ERROR_ATTR_NOT_FOUND

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	7/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSHandleOp	proc	near
		uses	bx
		.enter
EC <		cmp	ah, FSHandleOpFunction				>
EC <		ERROR_AE	INVALID_HANDLE_OP			>
	;
	; Vector to correct internal code to handle the thing.
	; 
		xchg	ah, al
		mov	di, ax
		xchg	al, ah
		andnf	di, 0xff
		shl	di
		jmp	cs:[handleOpJmpTable][di]
handleOpJmpTable nptr.near	doRead,		; FSHOF_READ
		 		doWrite,	; FSHOF_WRITE
				doPosition,	; FSHOF_POSITION
				doTruncate,	; FSHOF_TRUNCATE
				doCommit,	; FSHOF_COMMIT
				doLockUnlock,	; FSHOF_LOCK
				doLockUnlock,	; FSHOF_UNLOCK
				doGetSetDateTime,; FSHOF_GET_DATE_TIME
				doGetSetDateTime,; FSHOF_SET_DATE_TIME
				doFileSize,	; FSHOF_FILE_SIZE
				doAddRef,	; FSHOF_ADD_REFERENCE
				doCheckDirty,	; FSHOF_CHECK_DIRTY
				doClose,	; FSHOF_CLOSE
				doGetID,	; FSHOF_FILE_ID
				doCheckNative,	; FSHOF_CHECK_NATIVE
				doGetExtAttrs,	; FSHOF_GET_EXT_ATTRIBUTES
				doSetExtAttrs,	; FSHOF_SET_EXT_ATTRIBUTES
				doCopyExtAttrs,	; FSHOF_COPY_EXT_ATTRIBUTES
				doForget,	; FSHOF_FORGET
				doSetFileName	; FSHOF_SET_FILE_NAME

CheckHack	<length handleOpJmpTable eq FSHandleOpFunction>

	;
	; Convert geos file handle to DOS handle, stored in HF_sfn.
	; 
convertGeosToDos:
		push	ds
		LoadVarSeg	ds, di
		mov	bl, ds:[bx].HF_sfn
		clr	bh		; So DOS gets proper handle...
		pop	ds
		retn

	;--------------------
doRead:
		mov	ah, MSDOS_READ_FILE
		jmp	passToDOS
	;--------------------
doWrite:
		mov	ah, MSDOS_WRITE_FILE
		jmp	passToDOS
	;--------------------
doPosition:
		call	FSDSPosition
		jmp	done
	;--------------------
doClose:
		mov	ah, MSDOS_CLOSE_FILE
passToDOS:
		call	convertGeosToDos
		int	21h
		jmp	done
	;--------------------
doTruncate:
		push	cx, dx
	;
	; Seek to the truncation point.
	; 
		mov	al, FILE_POS_START
		call	FSDSPosition
		jc	truncateDone
	;
	; And write zero bytes there. This truncates under DOS...
	; 
		clr	cx
		mov	ah, MSDOS_WRITE_FILE
		int	21h
truncateDone:
		pop	cx, dx
		jmp	done
		
	;--------------------
doCommit:
	;
	; If DOS version is 3.0 or later, it supports the MSDOS_COMMIT function
	; to flush everything, so use it.
	; 
		call	convertGeosToDos
		push	ds
		LoadVarSeg	ds
		cmp	ds:[dosVersion].low, 3
		pop	ds
		jae	useCommit
	;
	; MSDOS_COMMIT not supported, so do things the old-fashioned way by
	; duplicating the open file and closing the duplicate handle.
	; 
		mov	ah, MSDOS_DUPLICATE_HANDLE
		int	21h
		jc	doneJmp
		
		mov_tr bx, ax
		mov	ah, MSDOS_CLOSE_FILE
		int	21h
doneJmp:
		jmp	done
useCommit:
		mov	ah, MSDOS_COMMIT
		int	21h
		jmp	done
	;--------------------
doLockUnlock:
		call	convertGeosToDos
		push	bp, si, di, dx
		mov	bp, cx
		shr	di
		sub	di, FSHOF_LOCK
		mov_tr	ax, di	; al <- 0 for lock, 1 for unlock
			CheckHack <FSHOF_UNLOCK eq FSHOF_LOCK+1>

		mov	si, ss:[bp].FSHLUF_regionLength.high	; si:di <- len
		mov	di, ss:[bp].FSHLUF_regionLength.low
		mov	cx, ss:[bp].FSHLUF_regionStart.high	; cx:dx <- start
		mov	dx, ss:[bp].FSHLUF_regionStart.low
		mov	ah, MSDOS_LOCK_RECORD
		int	21h
		pop	bp, si, di, dx
		jmp	done
	;--------------------
doGetSetDateTime:
		call	convertGeosToDos
		mov_tr	ax, di
		shr	ax
		sub	ax, FSHOF_GET_DATE_TIME	; al <- 0 for get date/time,
						; al <- 1 for set date/time
			CheckHack <FSHOF_SET_DATE_TIME eq FSHOF_GET_DATE_TIME+1>
		mov	ah, MSDOS_GET_SET_DATE
		int	21h
		jmp	done
	;--------------------
doFileSize:
		push	cx
		push	bx
		call	convertGeosToDos
	;
	; Figure and save current file position
	;
		clr	cx
		mov	dx, cx
		mov	ax, FILE_POS_RELATIVE or (MSDOS_POS_FILE shl 8)
		int	21h
		push	dx, ax
	;
	; Seek to the end, getting us the file size.
	;
		clr	cx
		mov	dx, cx
		mov	ax, FILE_POS_END or (MSDOS_POS_FILE shl 8)
		int	21h
	;
	; Recover original position (cx:di, since we've got stuff in dx) and
	; save the file size.
	;
		pop	cx, di
		push	dx, ax
	;
	; Restore the original position.
	;
		mov	dx, di
		mov	ax, FILE_POS_START or (MSDOS_POS_FILE shl 8)
		int	21h
	;
	; Recover file size, account for file header and return.
	;
		pop	dx, ax
		pop	bx
		push	ds
		LoadVarSeg	ds, cx
		tst	ds:[bx].HF_private
		jz	doFSDone
		sub	ax, size GeosFileHeader
		sbb	dx, 0
doFSDone:
		pop	ds
		pop	cx
		jmp	done
	;--------------------
doAddRef:
	;
	; There's no way to do this w/o knowing stuff about DOS structures,
	; as we can't leave a handle lying in the JFT...
	; 
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		stc
		jmp	done
	;--------------------
doCheckDirty:
	;
	; Use our old friend MSDOS_IOCTL_GET_DEV_INFO to find if the file
	; has been written to.
	; 
		call	convertGeosToDos
		push	dx
		mov	ax, MSDOS_IOCTL_GET_DEV_INFO
		int	21h
		clr	ax
		test	dx, mask DOS_BDEV_IOCTL_FILE_CLEAN
		pop	dx
		jnz	done
		dec	ax	; flag file dirty (1-byte inst)
		jmp	done
	;--------------------
doGetID:
		mov	dx, FILE_NO_ID AND 0xffff
		mov	cx, FILE_NO_ID shr 16
		jmp	done
	;--------------------
doCheckNative:
		stc		; assume so
		jmp	done
	;--------------------
doGetExtAttrs:
		push	bp, ds
		mov	bp, dx
		LoadVarSeg	ds, di
		tst	ds:[bx].HF_private
		jz	attrNotFound	; => not geos

		cmp	ss:[bp].FHEAD_attr, FEA_FILE_TYPE
		jne	attrNotFound
		push	es
		les	di, ss:[bp].FHEAD_buffer
		mov	{GeosFileType}es:[di], GFT_EXECUTABLE
		pop	es
		jmp	popGEADone
attrNotFound:
		mov	ax, ERROR_ATTR_NOT_FOUND
		stc
popGEADone:
		pop	bp, ds
		jmp	done
	;--------------------
doSetExtAttrs:
		mov	ax, ERROR_ATTR_CANNOT_BE_SET
		stc
		jmp	done
	;--------------------
doSetFileName:
EC <		WARNING	FSHOF_SET_FILE_NAME_PASSED_TO_SKELETON_DRIVER	>
		.assert	$ eq doForget
	;--------------------
doForget:

		clc
		jmp	done
	;--------------------
doCopyExtAttrs:
		mov	ax, ERROR_ATTR_NOT_FOUND
		stc

		.assert	$ eq done
	;--------------------
done:
		.leave
		ret
FSDSHandleOp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSPathOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some other operation on a file path that doesn't
		involve the allocation of a file handle.

		If the operation to be performed is destructive to the path
		on which it's to be performed, the FSD is responsible for
		ensuring the path is not actively in-use by any thread.

		For a directory, this means it is not in the path stack of
		any thread (XXX: this is something of a bitch when std paths
		are involved). For a file, no handle may be open to the file.

CALLED_BY:	DR_FS_PATH_OP
PASS:		ah	= FSPathOpFunction to perform
		ds:dx	= path on which to perform the operation
		es:si	= DiskDesc for disk on which to perform it, locked
			  into drive (FSInfoResource and affected drive locked
			  shared). si may well not match the disk handle
			  of the thread's current path, in which case ds:dx is
			  absolute.
RETURN:		carry clear if successful:
			return values vary by function
		carry set if unsuccessful:
			ax	= error code

PSEUDO CODE/STRATEGY:
    FSPOF_CREATE_DIR	enum	FSPathOpFunction
    FSPOF_DELETE_DIR	enum	FSPathOpFunction
    FSPOF_DELETE_FILE	enum	FSPathOpFunction

    FSPOF_RENAME_FILE	enum	FSPathOpFunction
    ;	Pass:	bx:cx	= new name
    ;	Return:	nothing extra
    ;

    FSPOF_MOVE_FILE	enum 	FSPathOpFunction
    ;	Pass:	es:cx	= DiskDesc of destination (locked)
    ;		ss:bx	= FSMoveFileData
    ;	Return:	nothing extra

    FSPOF_GET_ATTRIBUTES enum	FSPathOpFunction
    ;	Pass:	nothing extra
    ;	Return:	cx	= FileAttrs
    
    FSPOF_SET_ATTRIBUTES enum	FSPathOpFunction
    ;	Pass:	cx	= FileAttrs
    ;	Return:	nothing extra

    FSPOF_GET_EXT_ATTRIBUTES enum FSPathOpFunction
    ;	Pass:	ss:bx	= FSPathExtAttrData
    ;		cx	= size of FPEAD_buffer, or # entries in same if
    ;			  FPEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    Return ERROR_UNSUPPORTED_FUNCTION
    
    FSPOF_SET_EXT_ATTRIBUTES enum FSPathOpFunction
    ;	Pass:	ss:bx	= FSPathExtAttrData
    ;		cx	= size of FPEAD_buffer, or # entries in same if
    ;			  FPEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    Return ERROR_UNSUPPORTED_FUNCTION

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSPathOp	proc	near
		.enter
EC <		cmp	ah, FSPathOpFunction				>
EC <		ERROR_AE	INVALID_PATH_OP				>
	;
	; Vector to correct internal code to handle the thing.
	; 
		xchg	ah, al
		mov	di, ax
		xchg	al, ah
		andnf	di, 0xff
		shl	di
		jmp	cs:[pathOpJmpTable][di]

pathOpJmpTable	nptr.near	\
			doCreateDir,	; FSPOF_CREATE_DIR
			doDeleteDir,	; FSPOF_DELETE_DIR
			doDeleteFile,	; FSPOF_DELETE_FILE
			doRenameFile,	; FSPOF_RENAME_FILE
			doMoveFile,	; FSPOF_MOVE_FILE
			doGetSetAttrs,	; FSPOF_GET_ATTRIBUTES
			doGetSetAttrs,	; FSPOF_SET_ATTRIBUTES
			doGetExtAttrs,	; FSPOF_GET_EXT_ATTRIBUTES
			doGetAllExtAttrs,; FSPOF_GET_ALL_EXT_ATTRIBUTES
			doSetExtAttrs,	; FSPOF_SET_EXT_ATTRIBUTES
			doMap,		; FSPOF_MAP_VIRTUAL_NAME
			doMap,		; FSPOF_MAP_NATIVE_NAME
			doCreateLink,	; FSPOF_CREATE_LINK
			doReadLink,	; FSPOF_READ_LINK
			doSetLinkExtraData, ; FSPOF_SET_LINK_EXTRA_DATA
			doGetLinkExtraData, ; FSPOF_GET_LINK_EXTRA_DATA
			doCreateDir ; FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME

CheckHack	<length pathOpJmpTable eq FSPathOpFunction>

	;--------------------
doCreateDir:
		mov	ah, MSDOS_CREATE_DIR
		jmp	passToDOS
	;--------------------
doDeleteDir:
		mov	ah, MSDOS_DELETE_DIR
		jmp	passToDOS
	;--------------------
doDeleteFile:
		mov	ah, MSDOS_DELETE_FILE
		jmp	passToDOS
	;--------------------
doRenameFile:
		push	es
		mov	es, bx
		mov	di, cx
		mov	ah, MSDOS_RENAME_FILE
		int	21h
		pop	es
		jmp	done
	;--------------------
doMoveFile:
		mov	ax, ERROR_DIFFERENT_DEVICE
		cmp	cx, si			; different disks?
		stc
		jne	done			; yes -- unsupported
		
		push	es
		les	di, ss:[bx].FMFD_dest
		mov	ah, MSDOS_RENAME_FILE
		int	21h
		pop	es
		jmp	done
		
	;--------------------
doGetSetAttrs:
		shr	di
		sub	di, FSPOF_GET_ATTRIBUTES
		CheckHack <FSPOF_SET_ATTRIBUTES eq FSPOF_GET_ATTRIBUTES+1>
		mov_tr	ax, di
		mov	ah, MSDOS_GET_SET_ATTRIBUTES
passToDOS:
		int	21h
		.assert	$ eq done
	;--------------------
done:
		.leave
		ret

doGetExtAttrs:
doGetAllExtAttrs:
doSetExtAttrs:
doCreateLink:
doReadLink:
doSetLinkExtraData:
doGetLinkExtraData:
	; Link functions aren't supported by the skeleton
doMap:
	; neither FSPOF_MAP_VIRTUAL_NAME nor FSPOF_MAP_NATIVE_NAME is supported
	; by the skeleton FSD
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		stc
		jmp	done

FSDSPathOp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDSCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We have no basis for the comparison, so always say they're
		not equal, unless they are the same SFN (aka DOS handle,
		from our perspective).

CALLED BY:	DR_FS_COMPARE_FILES
PASS:		al	= SFN of first file
		cl	= SFN of second file
RETURN:		ah	= flags byte (for sahf) that will allow je if the
			  two files refer to the same disk file (carry
			  will be clear after sahf)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDSCompareFiles proc	near
		.enter
		cmp	al, cl	; return == only if same DOS handle
		clc		; but always return carry clear
		sahf
		.leave
		ret
FSDSCompareFiles endp

if DBCS_PCGEOS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDGeosToDosDSDXInt21
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a GEOS string to a DOS string and call int 21

CALLED BY:	UTILITY
PASS:		ds:dx - GEOS string (NULL-terminated)
		ah - DOS Int21Call to make
		depends on function
RETURN:		depends on function
DESTROYED:	depends on function

PSEUDO CODE/STRATEGY:
	This routine is called by the skeleton FSD for calling DOS.
	As the skeleton FSD is used when loading the real FSD, only
	minimal conversion of characters can be done, because the
	real FSD is where character conversion is normally done.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	6/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSDGeosToDosDSDXInt21		proc	near
		uses	ds, di, dx
		.enter

	;
	; Allocate a buffer on the stack
	;
		sub	sp, (size PathName)
		mov	di, sp
		push	ax, si, es
		mov	si, dx			;ds:si <- ptr to source
		segmov	es, ss			;es:di <- ptr to buffer
	;
	; Convert the GEOS string to DOS as best we can
	;
charLoop:
		lodsw				;ax <- GEOS character
EC <		cmp	ax, 0x80					>
EC <		ERROR_AE UNCONVERTABLE_GEOS_CHARACTER_FOR_SKELETON_FSD	>
		stosb				;store DOS character
		tst	ax			;reached NULL?
		jnz	charLoop
	;
	; Point at the converted string for DOS
	;
		pop	ax, si, es
		segmov	ds, ss
		mov	dx, sp			;ds:dx <- ptr to buffer
	;
	; Make the int 21h call
	;
		int	21h
	;
	; Free the buffer preserving the carry
	;
		mov	di, sp
		lea	sp, ss:[di][(size PathName)]

		.leave
		ret
FSDGeosToDosDSDXInt21		endp

endif

kinit		ends
