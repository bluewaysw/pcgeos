COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		fileDevSpec.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Device-specific support routines for the common code.
		

	$Id: megafileDevSpec.asm,v 1.1 97/04/18 11:46:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata	segment

;Do not separate these two. Normally, the full megafile path is given,
;including a drive spec, and saved into "megaFile". If a relative path
;is given, then it is assumed to be relative to the GEOS system disk
;(where GEOS was booted from, often F:). In that case, the GEOS system disk
;drive spec is written into "optionalMFDriveSpec", and that is used
;as the start of the full path.

optionalMFDriveSpec	char	2 dup (?)
megaFile		char	DOS_STD_PATH_LENGTH + 3 dup (?)

udata	ends

;---

Init	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the file whose absolute name is stored in the ini file.

CALLED BY:	GFSInit
PASS:		nothing
RETURN:		carry set on error
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
driveKeyStr	char	'drive', 0

GFSDevInit 	proc	near
		uses	ds, bx, si, di, dx, cx, es
		.enter
		call	MFSOpenFile
		jc	done
	;
	; Check for caching of the megafile
	;
		call	MFSCheckCaching
	;
	; Fetch the name for the drive; use the default if nothing specified
	; 
		segmov	es, dgroup, di
		mov	di, offset gfsDriveName
		mov	dx, offset driveKeyStr
		segmov	ds, cs, cx			; cx = ds = cs
		mov	si, offset gfsKeyStr
		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				DRIVE_NAME_MAX_LENGTH
		call	InitFileReadString
		pop	bp
		clc
done:
		.leave
		ret
GFSDevInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFSOpenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to reopen the file that holds our filesystem.

CALLED BY:	GFSDevInit
PASS:		nothing
RETURN:		carry set if couldn't reopen the file
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

gfsKeyStr	char	'gfs', 0
fileKeyStr	char	'file', 0

MFSOpenFile	proc	near
		uses	ds, bx, si, di, dx, cx, es, bp
DBCS <		filenameBuf	local DOS_STD_PATH_LENGTH + 3 dup (wchar) >
		.enter

if	DBCS_PCGEOS
		segmov	es, ss
		lea	di, ss:[filenameBuf]
else
		mov	di, segment megaFile
		mov	es, di
		mov	di, offset megaFile
endif

		segmov	ds, cs, cx		; ds, cx <- cs
		mov	dx, offset fileKeyStr
		mov	si, offset gfsKeyStr
SBCS <		mov	bp, (IFCC_UPCASE shl offset IFRF_CHAR_CONVERT) or \
				size megaFile				>
DBCS <		push	bp						>
DBCS <		mov	bp, (IFCC_UPCASE shl offset IFRF_CHAR_CONVERT) or \
				size filenameBuf			>
		call	InitFileReadString
DBCS <		pop	bp						>
		jc	done			;skip if no key found...

if	DBCS_PCGEOS
		;
		; Convert the DBCS string to SBCS for DOS' pleasure.
		;
		push	ax			; save ax

		movdw	dssi, esdi
		segmov	es, <segment megaFile>, di
		mov	di, offset megaFile
charLoop:
		lodsw
		stosb
		tst	ax
		jnz	charLoop

		pop	ax			; restore ax
endif

		call	MFSReopenFile
done:
		.leave
		ret
MFSOpenFile	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	MFSCheckCaching

DESCRIPTION:	Check for the megafile being cached locally

CALLED BY:	INTERNAL

PASS:
	none

RETURN:
	none

DESTROYED:
	none

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	4/20/93		Initial version

------------------------------------------------------------------------------@

noFileStr	char	'none', 0

BYTES_AT_START_TO_CHECK		equ	64
DISK_SPACE_REQ_SIZE		equ	20
CACHE_COPY_STRING_SIZE		equ	64
FILE_COPY_BLOCK_SIZE		equ	50000

MFSCheckCaching	proc	near	uses	ax, bx, cx, dx, si, di, bp, ds, es
cacheFile	local	DOS_STD_PATH_LENGTH + 3 dup(char)
buf1		local	BYTES_AT_START_TO_CHECK dup (byte)
buf2		local	BYTES_AT_START_TO_CHECK dup (byte)
diskSpaceReq	local	DISK_SPACE_REQ_SIZE dup (char)
cacheCopyString	local	CACHE_COPY_STRING_SIZE dup (char)
envBuffer	local	10 dup (char)
newFile		local	word
oldFile		local	word
newSize		local	dword
freeSpace	local	dword
copyBlock	local	word
		.enter

EC <		call	ECCheckStack					>

		segmov	ds, dgroup, ax
		mov	ax, ds:[fileMegaFile]
		mov	oldFile, ax
	;
	; Look for a cache file
	;
		segmov	es, ss
		lea	di, ss:[cacheFile]
		segmov	ds, cs, cx		; ds, cx <- cs
		mov	dx, offset cacheFileStr
		mov	si, offset gfsKeyStr
		push	bp
		mov	bp, (IFCC_UPCASE shl offset IFRF_CHAR_CONVERT) or \
				size megaFile
		call	InitFileReadString
		pop	bp
		LONG jc	done

	;
	; see if it is "none", as an override of the shared .ini file.
	;

		clr	cx
		mov	si, offset noFileStr
		call	LocalCmpStringsNoCase
		stc
		LONG je	done			;skip if so...

	;
	; We found a cache file, see if the drive exists
	;
		mov	al, cacheFile[0]
		sub	al, 'A'
		call	DriveGetStatus
		LONG jc	done
	;
	; Drive exists, try to open the file
	;
		call	tryOpen				;ax = new file
		LONG jc	noCacheFile
		mov	newFile, ax
	;
	; Cache file exists -- check its first 64 bytes and check the file size
	;
		mov	bx, newFile			;get size of cache file
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_END
		clrdw	cxdx
		call	callDOS				;dxax = file size
		LONG jc	cacheFileBad
		movdw	newSize, dxax
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		clrdw	cxdx
		call	callDOS				;position at start
		jc	cacheFileBad

		mov	bx, oldFile			;get size of mega file
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_END
		clrdw	cxdx
		call	callDOS				;dxax = file size
		LONG jc	done
		pushdw	dxax
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		clrdw	cxdx
		call	callDOS				;position at start
		popdw	dxax
		LONG jc	done
		cmpdw	dxax, newSize
		jnz	cacheFileBad

		mov	cx, BYTES_AT_START_TO_CHECK
		mov	bx, newFile			;read from cache file
		segmov	ds, ss
		lea	dx, buf1
		mov	ah, MSDOS_READ_FILE
		call	callDOS
		jc	cacheFileBad
		cmp	ax, BYTES_AT_START_TO_CHECK
		jnz	cacheFileBad

		mov	cx, BYTES_AT_START_TO_CHECK
		mov	bx, oldFile			;read from mega file
		lea	dx, buf2
		mov	ah, MSDOS_READ_FILE
		call	callDOS
		LONG jc	done
		cmp	ax, BYTES_AT_START_TO_CHECK
		LONG jnz done

		segmov	es, ss
		lea	si, buf1
		lea	di, buf2
		mov	cx, BYTES_AT_START_TO_CHECK/2
		repe	cmpsw
		LONG jz	cacheFileGood

	;
	; The cache file is hosed
	;
cacheFileBad:
		mov	bx, newFile
		call	closeFile
		jmp	copyCacheFile
noCacheFile:
	;
	; Check disk space requirements
	;
		segmov	es, ss
		lea	di, diskSpaceReq
		mov	dx, offset diskSpaceStr
		segmov	ds, cs, cx
		mov	si, offset gfsKeyStr
		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				DISK_SPACE_REQ_SIZE
		call	InitFileReadString
		pop	bp
		jc	copyCacheFile
		segmov	ds, ss
		lea	si, diskSpaceReq
		call	UtilAsciiToHex32		;dxax = disk space
		jc	copyCacheFile
		movdw	freeSpace, dxax

		mov	al, cacheFile[0]
		sub	al, 'A'
		call	DiskRegisterDiskSilently	;bx = disk handle
		LONG jc	done
		call	DiskGetVolumeFreeSpace
		LONG jc	done
		cmpdw	dxax, freeSpace
		LONG jb	done

copyCacheFile:
	;
	; One (somewhat hacked) check for Wizard: if there is a non-null
	; environment variable "S", then don't copy the file locally
	;
		segmov	ds, cs
		mov	si, offset envVarString
		segmov	es, ss
		lea	di, envBuffer
		mov	cx, length envBuffer
		call	SysGetDosEnvironment
		jc	afterEnvCheck
		tst	envBuffer[0]
		LONG jnz done
afterEnvCheck:
	;
	; Look for a string to display
	;
		segmov	es, ss
		lea	di, cacheCopyString
		mov	dx, offset cacheCopyStringStr
		segmov	ds, cs, cx
		mov	si, offset gfsKeyStr
		push	bp
		mov	bp, (IFCC_INTACT shl offset IFRF_CHAR_CONVERT) or \
				CACHE_COPY_STRING_SIZE
		call	InitFileReadString
		pop	bp
		jc	afterMessage
		add	di, cx
		mov	{char} es:[di], '$'

		segmov	ds, cs
		mov	dx, offset sepString
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h
		segmov	ds, ss
		lea	dx, cacheCopyString
		mov	ah, MSDOS_DISPLAY_STRING
		int	21h

afterMessage:

	;
	; Copy the file (do it manually)
	;
		mov	bx, oldFile
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		clrdw	cxdx
		call	callDOS

		segmov	ds, ss				;create it
		lea	dx, cacheFile
		mov	cx, mask FA_HIDDEN
		mov	ah, MSDOS_CREATE_TRUNCATE
		call	callDOS
		jc	done
		mov	newFile, ax
	;
	; Allocate a block for temp storage
	;
		mov	ax, FILE_COPY_BLOCK_SIZE
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		jc	errorDeleteCopy
		mov	copyBlock, bx
		mov	ds, ax
	;
	; Loop to copy the file
	;
copyLoop:
		mov	cx, FILE_COPY_BLOCK_SIZE
		mov	bx, oldFile			;read
		clr	dx
		mov	ah, MSDOS_READ_FILE
		call	callDOS				;ax = count
		jc	errorFreeCopyBlock
		tst	ax
		jz	copyDone

		mov	cx, ax
		mov	si, ax
		mov	bx, newFile			;write
		clr	dx
		mov	ah, MSDOS_WRITE_FILE
		call	callDOS
		jc	errorFreeCopyBlock
		cmp	ax, si				;check for short write
		jnz	errorFreeCopyBlock
		jmp	copyLoop

copyDone:
		mov	bx, copyBlock
		call	MemFree
		mov	bx, newFile
		call	closeFile

	;
	; successful copy, open the file
	;
		call	tryOpen
		jc	done
	;
	; We have found a good cache file -- use it
	;
cacheFileGood:
		mov	bx, newFile
		segmov	ds, dgroup, ax
		xchg	bx, ds:[fileMegaFile]
		call	closeFile

	;
	; Copy path name of mega file
	;

		segmov	ds, ss
		lea	si, cacheFile
		segmov	es, dgroup, di
		mov	di, offset megaFile
		mov	cx, size megaFile
		rep	movsb

done:
		.leave
		ret

errorFreeCopyBlock:
		mov	bx, copyBlock
		call	MemFree
errorDeleteCopy:
		mov	bx, newFile
		call	closeFile
		segmov	ds, ss
		lea	dx, cacheFile
		mov	ah, MSDOS_DELETE_FILE
		call	callDOS
		jmp	done

;---

closeFile:
		mov	ah, MSDOS_CLOSE_FILE
callDOS:
		push	bp
		mov	di, DR_DPFS_CALL_DOS
		call	GFSCallPrimary
		pop	bp
		retn

;---

tryOpen:
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		segmov	ds, ss
		lea	dx, cacheFile
		mov	di, DR_DPFS_OPEN_INTERNAL
		push	bp
		call	GFSCallPrimary
		pop	bp
		retn

MFSCheckCaching	endp

cacheFileStr	char	"cacheFile", 0

diskSpaceStr	char	"cacheMinSpace", 0

cacheCopyStringStr	char	"cacheCopyString", 0

envVarString	char	"S", 0

;---

sepString	char	C_CR, C_LF, C_CR, C_LF, '$'


Init		ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevExit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish with the filesystem

CALLED BY:	GFSExit
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevExit	proc	far
		uses	ds, bx, di, ax, bp
		.enter
		segmov	ds, dgroup, ax
		mov	bx, ds:[fileMegaFile]
		mov	ah, MSDOS_CLOSE_FILE
		mov	di, DR_DPFS_CALL_DOS
		call	GFSCallPrimary
EC <		mov	ds:[fileSem].Sem_value, 0	; just in case	>
		.leave
		ret
GFSDevExit	endp

Resident	ends

Movable		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevMapDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring in the contents of the indicated directory

CALLED BY:	EXTERNAL
PASS:		dxax	= offset of directory
		cx	= # of entries in the directory
RETURN:		carry set on error:
			ax	= FileError
			es, di	= destroyed
		carry clear if ok:
			es:di	= first entry in the directory
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevMapDir	proc	near
		uses	ds, bx, cx, dx, si
		.enter
	;
	; Compute the size of the directory in bytes, as we need it a couple
	; places...
	; 
		push	dx, ax
		mov	ax, size GFSDirEntry
		mul	cx
EC <		ERROR_C	DIRECTORY_TOO_LARGE				>
		mov_tr	cx, ax
		pop	dx, ax
	;
	; First look in the cache.
	; 
		segmov	ds, dgroup, di
		mov	di, offset fileDirCacheHead - offset FDC_next
cacheLoop:
		mov	si, ds:[di].FDC_next

		tst	ds:[si].FDC_handle
		jz	notInCache		; => ds:si is free, so not here

		cmpdw	dxax, ds:[si].FDC_offset
		je	haveHandle

		cmp	ds:[si].FDC_next, 0	; ds:si last one?
		je	cacheFull		; yes -- biff it

		mov	di, si		; advance to next
		jmp	cacheLoop

cacheFull:
	;
	; Not in the cache and no free slot in the cache, so free the last
	; one.
	; 
		mov	bx, ds:[si].FDC_handle
		call	MemFree
notInCache:
	;
	; Record offset of directory in free cache entry.
	; 
		movdw	ds:[si].FDC_offset, dxax
	;
	; Allocate a block to hold the directory.
	; 
		push	cx
		mov_tr	ax, cx
		mov	cx, (mask HAF_LOCK shl 8) or mask HF_DISCARDABLE or \
			mask HF_SWAPABLE or mask HF_SHARABLE
		mov	bx, handle 0
		call	MemAllocSetOwner
		jc	noMem
load:
	;
	; Remember the handle and pop the number of bytes to read.
	; 
		mov	ds:[si].FDC_handle, bx
		pop	cx
	;
	; ax = segment to which to load it
	; cx = # bytes to read
	; 
		push	di
	;
	; Use our standard routine to read the bytes. It also checks for short
	; reads.
	; 
		mov	es, ax
		clr	di			; es:di <- dest
		movdw	dxax, ds:[si].FDC_offset; dxax <- offset, cx = #bytes
		call	GFSDevRead
		pop	di
		jc	unlockAndBail

shuffle:
	;
	; Shift this entry to the front of the cache.
	; ds:di = previous entry
	; ds:si = this entry
	; es = segment of locked block
	; 
		mov	dx, ds:[si].FDC_next
		mov	ds:[di].FDC_next, dx	; unlink

		mov	dx, ds:[fileDirCacheHead]
		mov	ds:[si].FDC_next, dx	; link to head
		mov	ds:[fileDirCacheHead], si
	;
	; Data always start at es:0, so return di 0 (clears carry, too)
	; 
		clr	di
done:
		.leave
		ret

haveHandle:
	;
	; Directory has a handle allocated to it already. Try and lock it down.
	; 
		mov	bx, ds:[si].FDC_handle
		call	MemLock
		jc	reload
		mov	es, ax		; return segment in ES
		jmp	shuffle		; go make sure entry is at the front.

reload:
	;
	; Block is discarded, so try to reallocate it the same size.
	; 
		push	cx
		clr	ax		; realloc same size
		mov	cx, mask HAF_LOCK shl 8
		call	MemReAlloc	; ax <- segment
		jnc	load
noMem:
		pop	cx
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

unlockAndBail:
		call	MemUnlock
		jmp	done
GFSDevMapDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnmapDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the directory at the head of the cache.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnmapDir	proc	near
		uses	ds, bx
		.enter
		segmov	ds, dgroup, bx
		mov	bx, ds:[fileDirCacheHead]
		mov	bx, ds:[bx].FDC_handle
		call	MemUnlock
		.leave
		ret
GFSDevUnmapDir	endp

Movable		ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevMapEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring in the extended attributes for a file.

CALLED BY:	EXTERNAL
PASS:		dxax	= offset of extended attributes
RETURN:		carry set on error:
			ax	= FileError for caller to return
		carry clear if ok:
			es:di	= GFSExtAttrs
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevMapEA	proc	far
		uses	ds, dx, bx, cx
		.enter
	;
	; See if we already have these attributes in memory.
	; 
		segmov	ds, dgroup, cx
		mov	bx, ds:[fileEACache]
		tst	bx
		jz	notCached

		cmpdw	dxax, ds:[fileEACacheStart]
		jb	readInNew		; => before what we've got
		cmpdw	dxax, ds:[fileEACacheEnd]
		jae	readInNew		; => after what we've got
	;
	; Falls within the block we've got cached, so lock the thing down,
	; figure where exactly it is, and return that.
	; 
		push	ax
		call	MemLock
		mov	es, ax
		pop	ax
		subdw	dxax, ds:[fileEACacheStart]
		mov_tr	di, ax
		clc
done:
		.leave
		ret

notCached:
	;
	; Nothing cached, so allocate a block of size suitable to the mode
	; we're in (scanning / not scanning)
	; 
		push	ax
		mov	ax, size GFSExtAttrs	; assume just one needed

		tst	ds:[fileScanning]
		jz	allocNew
		mov	ax, FILE_EA_CACHE_SIZE

allocNew:
		mov	cx, ALLOC_DYNAMIC or mask HF_SHARABLE
		mov	bx, handle 0
		call	MemAllocSetOwner
		pop	ax

		jnc	storeEAHandle
	;
	; Couldn't allocate, so return appropriate error code.
	; 
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done

storeEAHandle:
		mov	ds:[fileEACache], bx

readInNew:
	;
	; Have a cache block, but it doesn't contain the attributes we want.
	; Record the offset of these attributes as the start and the end,
	; so we can easily adjust the end once we've read stuff.
	; 
		movdw	ds:[fileEACacheStart], dxax
		movdw	ds:[fileEACacheEnd], dxax
	;
	; Figure how big the block is, cheaply.
	; 
		mov	cx, size GFSExtAttrs
		tst	ds:[fileScanning]
		jz	readIt
		mov	cx, FILE_EA_CACHE_SIZE
readIt:
		push	ax
		call	MemLock			; ax <- cache block
		mov	es, ax
		pop	ax
		clr	di
		call	GFSDevReadLow		; don't check for short read
		jc	invalidateCacheAndReturnError
	;
	; Adjust the range-end variable to be the number of bytes we read
	; beyond the start.
	; XXX: check for getting incomplete ExtAttrs structure?
	; 
		add	ds:[fileEACacheEnd].low, ax
		adc	ds:[fileEACacheEnd].high, 0
		clr	di
		jmp	done

invalidateCacheAndReturnError:
	;
	; Couldn't read, so make the end come before the beginning, thereby
	; invalidating the whole cache.
	; 
		decdw	ds:[fileEACacheEnd]
	;
	; Unlock the block and return carry set.
	; 
		call	MemUnlock
		stc
		jmp	done
GFSDevMapEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnmapEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unlock the extended attributes we read in last.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnmapEA	proc	far
		uses	ds, bx
		.enter
		segmov	ds, dgroup, bx
		mov	bx, ds:[fileEACache]
		call	MemUnlock
		.leave
		ret
GFSDevUnmapEA	endp

Resident	ends

Movable		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevFirstEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the offset of the first extended attribute
		structure for this directory.

CALLED BY:	EXTERNAL
PASS:		dxax	= base of directory
		cx	= # directory entries in there
RETURN:		dxax	= offset of first extended attribute structure
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevFirstEA	proc	far
		uses	bx, si
		.enter
		movdw	bxsi, dxax
		mov	ax, size GFSDirEntry
		mul	cx
		adddw	dxax, bxsi
		.leave
		ret
GFSDevFirstEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevNextEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure out the start of the next GFSExtAttrs structure in
		a directory, given the offset of the current one

CALLED BY:	EXTERNAL
PASS:		dxax	= base of current ea structure
RETURN:		dxax	= base of next
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevNextEA	proc	near
		.enter
		add	ax, size GFSExtAttrs
		adc	dx, 0
		.leave
		ret
GFSDevNextEA	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevLocateEA
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the extended attrs for a file given the base of
		the directory that contains it, the number of entries
		in the directory, and the entry # of the file in the directory

CALLED BY:	EXTERNAL
PASS:		dxax	= base of directory
		cx	= # of entries in the directory
		bx	= entry # within the directory
RETURN:		dxax	= base of extended attrs
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevLocateEA	proc	near
		uses	cx, si
		.enter
		call	GFSDevFirstEA
		movdw	cxsi, dxax
		mov	ax, size GFSExtAttrs
		mul	bx
		adddw	dxax, cxsi
		.leave
		ret
GFSDevLocateEA	endp

Movable	ends

Resident	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevLock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gain exclusive access to the filesystem

CALLED BY:	EXTERNAL
PASS:		al - GFSDevLockFlags
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevLock	proc	far
		uses	ds
		.enter
		call	LoadVarSegDS
		PSem	ds, fileSem
		andnf	al, mask GDLF_SCANNING
		mov	ds:[fileScanning], al
		.leave
		ret
GFSDevLock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Release exclusive access to the filesystem.

CALLED BY:	EXTERNAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevUnlock	proc	far
		uses	ds, bx, ax
EC <		uses	si					>
		.enter
		pushf
		call	LoadVarSegDS
	;
	; Free any cached extended attributes.
	; 
		mov	bx, ds:[fileEACache]
		tst	bx
		jz	eaOK
EC <		mov	ax, MGIT_FLAGS_AND_LOCK_COUNT		>
EC <		call	MemGetInfo				>
EC <		tst	ah					>
EC <		ERROR_NZ	EA_NEVER_UNMAPPED		>
		call	MemFree
		mov	ds:[fileEACache], 0
eaOK:
	;
	; Make sure all blocks in the directory cache are unlocked.
	; 
EC <		mov	si, ds:[fileDirCacheHead]		>
EC <cacheLoop:							>
EC <		mov	bx, ds:[si].FDC_handle			>
EC <		tst	bx					>
EC <		jz	dirCacheOK				>
EC <		mov	ax, MGIT_FLAGS_AND_LOCK_COUNT		>
EC <		call	MemGetInfo				>
EC <		tst	ah					>
EC <		ERROR_NZ	DIR_NEVER_UNMAPPED		>
EC <		mov	si, ds:[si].FDC_next			>
EC <		tst	si					>
EC <		jnz	cacheLoop				>
EC <dirCacheOK:							>

   		VSem	ds, fileSem, TRASH_AX_BX
		popf
		.leave
		ret
GFSDevUnlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevReadLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read bytes from the filesystem

CALLED BY:	EXTERNAL
PASS:		dxax	= offset from which to read them
		cx	= number of bytes to read
		es:di	= place to which to read them
RETURN:		carry set on error (doesn't check for short read):
			ax	= FileError
		carry clear if all bytes read
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifidn PRODUCT, <COMPRESSED>
GFSDevReadRaw	proc	near
else
GFSDevReadLow	proc	far
endif
		uses	ds, dx, di, bx, cx, bp
		.enter
		push	cx, di
		call	LoadVarSegDS
		mov	bx, ds:[fileMegaFile]
		mov	cx, dx
		mov_tr	dx, ax
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		mov	di, DR_DPFS_CALL_DOS
		call	GFSCallPrimary
		pop	cx, dx

		segmov	ds, es
		mov	ah, MSDOS_READ_FILE
		mov	di, DR_DPFS_CALL_DOS
		call	GFSCallPrimary
		.leave
		ret
ifidn PRODUCT, <COMPRESSED>
GFSDevReadRaw	endp
else
GFSDevReadLow	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevReadLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read bytes from the filesystem

CALLED BY:	EXTERNAL
PASS:		dxax	= offset from which to read them
		cx	= number of bytes to read
		es:di	= place to which to read them
RETURN:		carry set on error (doesn't check for short read):
			ax	= FileError
		carry clear if all bytes read
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	9/11/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifidn PRODUCT, <COMPRESSED>

GFSDevReadLow	proc	far
fpos	local	dword				push	dx, ax
dest	local	fptr				push	es, di
	uses	bx,cx,dx,si,di,bp,ds,es
	.enter

	push	cx			; save number of bytes to read
	mov	bx, cx			; bx = number of bytes to read
read:
	segmov	ds, dgroup, si
	div	ds:[cgfsHeader].CGFSH_blocksize
	mov	si, ax
	shl	si, 1			; si = convert to word offset
	shl	si, 1			; si = convert to dword offset
	mov	es, ds:[fileReadSegment]
	clr	di			; es:di = file read buffer
	mov	ds, ds:[cgfsDirectorySegment]
	movdw	dxax, ds:[si]		; dx:ax = offset of entry
	mov	cx, ds:[si+4]		; ??:cx = offset of next entry
	mov	si, dx			; save high word of offset
	andnf	dx, 0x7fff		; clear UNCOMPRESSED bit
	sub	cx, ax			; cx = number of bytes to read
	call	GFSDevReadRaw		; read into es:di
	jc	done

	test	si, 0x8000		; check if block was not compressed
	jnz	copy			; then just copy it

	segmov	ds, dgroup, si
	mov	si, es
	mov	es, ds:[fileDecompressSegment]
	mov	ds, si			; ds:si = input buffer (compressed)
	clr	si, di			; es:di = output buffer (uncompressed)
	call	LZGUncompress		; cx = uncompressed data size
copy:
	segmov	ds, dgroup, si
	mov	si, ds:[cgfsHeader].CGFSH_blocksize
EC <	cmp	cx, si			; compare with blocksize	>
EC <	ERROR_A	CGFS_IMAGE_IS_HOSED					>
	dec	si			; si = blocksize - 1
	and	si, ss:[fpos].low	; si = offset of data
	sub	cx, si			; cx = size of data in block
	segmov	ds, es
	add	si, di			; ds:si = source
	les	di, ss:[dest]		; es:di = dest
	cmp	cx, bx			; size of data vs. size of dest
	jb	move
	mov	cx, bx			; cx = size of dest
move:
	mov	ax, cx			; ax = size of data to copy
	shr	cx, 1
	rep	movsw
	adc	cx, cx
	rep	movsb
	sub	bx, ax
EC <	ERROR_C	CGFS_IMAGE_IS_HOSED	; not really, logic error???	>
	jz	done

	cwd				; dx:ax = ax
	adddw	ss:[fpos], dxax		; update file pointer
	adddw	ss:[dest], dxax		; update destination buffer pointer
	movdw	dxax, ss:[fpos]		; dx:ax = new fpos
	jmp	read
done:
	pop	ax			; ax = number of bytes read

	.leave
	ret
GFSDevReadLow	endp

endif ; PRODUCT, <COMPRESSED>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSDevRead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read bytes from the filesystem

CALLED BY:	EXTERNAL
PASS:		dxax	= offset from which to read them
		cx	= number of bytes to read
		es:di	= place to which to read them
RETURN:		carry set on error:
			ax	= FileError (may be ERROR_SHORT_READ_WRITE)
			cx	= # bytes actually read, of short-read
		carry clear if all bytes read
			ax	= destroyed
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/15/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSDevRead	proc	far
		.enter
		call	GFSDevReadLow
		jc	done
		cmp	ax, cx
		je	done
		mov_tr	cx, ax		; return number read, though
		mov	ax, ERROR_SHORT_READ_WRITE
		stc
done:
		.leave
		ret
GFSDevRead	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFSCloseFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to close the file that holds our filesystem.
		(This is not the normal way to close the megafile.
		See the definition of DR_MFS_CLOSE_MEGAFILE.)

CALLED BY:	DR_MFS_CLOSE_MEGAFILE
PASS:		nothing
RETURN:		carry set if couldn't close the file
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	EDS	4/26/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MFSCloseFile	proc	far	uses ax, bx, dx, si, di, ds, bp
		.enter

		segmov	ds, dgroup, ax
		mov	bx, ds:[fileMegaFile]
		mov	ah, MSDOS_CLOSE_FILE
		mov	di, DR_DPFS_CALL_DOS
		call	GFSCallPrimary

		mov	ds:[fileMegaFile], 0
		clc					;no errors, I guess

		.leave
		ret
MFSCloseFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MFSReopenFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to reopen the file that holds our filesystem.

CALLED BY:	DR_MFS_REOPEN_MEGAFILE
PASS:		nothing
RETURN:		carry set if couldn't reopen the file
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/16/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

.assert (offset optionalMFDriveSpec) eq (offset megaFile)-2

MFSReopenFile	proc	far	uses ax, bx, dx, si, di, ds, bp
		.enter

		mov	si, segment megaFile
		mov	ds, si
		mov	si, offset megaFile

		;if the megafile path is relative, then back up to include
		;the drive specifier that GEOS was booted from.

		cmp	byte ptr ds:[si], '\\'
		jne	openFile

		mov	ax, SGIT_SYSTEM_DISK
		call	SysGetInfo		;ax = handle of system disk
						;(where GEOS was booted from)
		mov	bx, ax
		call	DiskGetDrive		;al = drive number
		add	al, 'A'			;al = drive letter

		mov	si, offset optionalMFDriveSpec
						;ds:si = new full path
		mov	ds:[si]+0, al
		mov	byte ptr ds:[si]+1, ':'

openFile:
		mov	dx, si			;ds:dx = full path
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_ONLY>
		mov	di, DR_DPFS_OPEN_INTERNAL
		push	bp
		call	GFSCallPrimary
		pop	bp
		WARNING_C	CANNOT_OPEN_GFS_IMAGE_FILE
		jc	done

		segmov	ds, dgroup, bx
		mov	ds:[fileMegaFile], ax

ifidn PRODUCT, <COMPRESSED>
		push	es
		segmov	es, ds, di
		mov	di, offset cgfsHeader	;read cgfs header
		clrdw	dxax			;read from beginning of file
		mov	cx, size CompressedGFSHeader
		call	GFSDevReadRaw
		pop	es
		jc	done

		movdw	dxax, ds:[cgfsHeader].CGFSH_filesize
		div	ds:[cgfsHeader].CGFSH_blocksize
		inc	ax			;ax = number of blocks
		shl	ax, 1			;ax = convert to words
		shl	ax, 1			;ax = convert to dwords

		push	ax
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		mov	ds:[cgfsDirectorySegment], ax
		pop	cx
		jc	done

		push	es
		mov	es, ax
		clr	di, dx
		mov	ax, size CompressedGFSHeader
		call	GFSDevReadRaw
		pop	es
		jc	done

		mov	ax, ds:[cgfsHeader].CGFSH_blocksize
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		mov	ds:[fileReadSegment], ax
		jc	done

		mov	ax, ds:[cgfsHeader].CGFSH_blocksize
		mov	cx, ALLOC_FIXED
		call	MemAlloc
		mov	ds:[fileDecompressSegment], ax
endif ; PRODUCT, <COMPRESSED>

done:
		.leave
		ret
MFSReopenFile	endp

Resident	ends
