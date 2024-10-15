COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		dosPath.asm

AUTHOR:		Adam de Boor, Oct 31, 1991

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	10/31/91	Initial revision


DESCRIPTION:
	Implementation of functions dealing with the thread's current
	path, and of those functions that deal with filenames, except
	file enum.
		

	$Id: dosPath.asm,v 1.1 97/04/10 11:55:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathOps		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSSetDefaultDriveFromDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the DOS default drive to that in which the passed
		disk resides.

CALLED BY:	DOSAllocOp, DOSCurPathSet
PASS:		es:si	= DiskDesc of disk whose drive is to become the
			  current one
RETURN:		carry set if we can't handle the drive
			ax	= ERROR_INVALID_DRIVE
		carry clear if ok
			ax	= preserved
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSSetDefaultDriveFromDisk proc near
		uses	bx, dx
		.enter
		mov	bx, es:[si].DD_drive
		mov	dl, es:[bx].DSE_number
		cmp	dl, MSDOS_MAX_DRIVES
		jae	fail
		push	ax
		mov	ah, MSDOS_SET_DEFAULT_DRIVE
		call	DOSUtilInt21
		pop	ax
		clc
done:
		.leave
		ret
fail:
		mov	ax, ERROR_INVALID_DRIVE	
		stc
		jmp	done
DOSSetDefaultDriveFromDisk endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSEstablishCWDLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to set DOS's current directory to
		the appropriate place for the current thread and the
		operation in progress.

CALLED BY:	DOSEstablishCWD, DOSPathOpMoveFile
PASS:		es:si	= disk on which the operation will be performed
		cwdSem snagged
RETURN:		carry set on error:
			ax	= FileError
		carry clear if ok:
			curPath updated.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	; this variable is also used in dosVirtual.asm for XIP
pathOpsRootPath	char	"\\", 0


DOSEstablishCWDLow proc	far
		uses	ds, bx, ax, dx
		.enter
	;
	; Set default drive to the one on which the operation will be performed,
	; regardless.
	; 
		call	DOSSetDefaultDriveFromDisk
		jc	done
	;
	; See if that's the same as the thread's current disk...
	; 
		call	FSDGetThreadPathDiskHandle
		cmp	bx, si		; same disk as current?
		je	setFromCurrentPath
	;
	; Operation is on a different disk, so switch to the root of that disk
	; instead and mark curPath invalid.
	; 
		clr	bx		; => no unlock & is used to invalidate
					;  curPath
FXIP <		mov	dx, segment fixedRootDir			>
FXIP <		mov	ds, dx						>
FXIP <		mov	dx, offset fixedRootDir				>
NOFXIP <	segmov	ds, cs						>
NOFXIP <	mov	dx, offset pathOpsRootPath			>

		jmp	setCommon


setFromCurrentPath:
	;
	; Set to the thread's current path if that's not already the one
	; stored in DOS.
	; 
		segmov	ds, dgroup, bx
		mov	bx, ss:[TPD_curPath]
		cmp	bx, ds:[curPath]
		je	done
		
		call	MemLock
		mov	ds, ax
		mov	dx, offset FP_private+2	; skip drive specifier
setCommon:
	;
	; Common code to set the current directory. Default drive already
	; set. ds:dx = path to set, bx = handle for curPath
	; 
		mov	ah, MSDOS_SET_CURRENT_DIR
		call	DOSUtilInt21
		pushf
		
		tst	bx
		jz	recordCurPath

		call	MemUnlock
recordCurPath:
		call	PathOps_LoadVarSegDS
		mov	ds:[curPath], bx
		popf
		jc	ensureCurPath0
done:
		.leave
		ret

ensureCurPath0:
		mov	ds:[curPath], 0
		jmp	done
DOSEstablishCWDLow endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSEstablishCWD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Establish the thread's current path as the one in DOS

CALLED BY:	DOSCurPathSet, DOSAllocOp, DOSPathOp
PASS:		es:si	= DiskDesc on which operation is going to take place
RETURN:		carry set on error:
			ax	= FileError
		cwdSem snagged.
		curPath updated.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/19/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSEstablishCWD proc	far
		.enter
	;
	; Gain exclusive rights to mess with things.
	; 
		call	DOSLockCWD
	;
	; Use low-level routine to set things, now the cwdSem is ours
	; 
		call	DOSEstablishCWDLow
		.leave
		ret
DOSEstablishCWD endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathInitPathBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Current path set successfully, so store the results in
		the path block for the thread.

CALLED BY:	DOSCurPathSet

PASS:		ds:dx - path name
		es:si - DiskDesc

RETURN:		carry set if path couldn't be set:
			ax	= ERROR_INSUFFICIENT_MEMORY
		carry clear if path properly set
			bx	= path block handle
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

	This routine will only store the PRIVATE data for the path --
	storing the actual "logical" path is up to the calling routine.
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/11/92		Initial version
	CDB	8/17/92		modified to only save private data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathInitPathBlock proc	near
		.enter

		mov	bx, ss:[TPD_curPath]
	;
	; See just how big the thing is and if that's enough for us.
	; 
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov	cx, size FilePath + 3 + MSDOS_PATH_BUFFER_SIZE
		cmp	ax, cx
		jae	informPrevFSD
	;
	; Enlarge the block to hold what we need to store.
	; 
		mov	ax, cx
		push	cx
		clr	cx
		call	MemReAlloc
		pop	cx
		jc	fail

informPrevFSD:
	;
	; Tell the old FSD we're taking over. 
	; 
		call	FSDInformOldFSDOfPathNukage

	;
	; Lock the path block so we can store our private data there
	;
		call	MemLock
		mov	ds, ax

		mov	ds:[FP_path], cx

	;
	; Store the initial drive specifier and leading backslash DOS won't
	; give us.
	; 
		mov	bx, es:[si].DD_drive
		mov	al, es:[bx].DSE_number
		clr	ah
		add	ax, 'A' or (':' shl 8)	; ax <- drive spec
		mov	di, offset FP_private
		mov	ds:[di], ax
		mov	{char}ds:[di+2], '\\'
		lea	si, ds:[di+3]	; ds:si <- buffer to which to get
					;  the current path
	;
	; Now ask DOS for the current path. It'll be nicely upcased, etc.
	; etc. etc. (XXX: this doesn't seem to be true for DOS 2.X, where
	; if you change to a lower-case directory, in a lower-case directory
	; you stay.)
	; 
		mov	dl, es:[bx].DSE_number
		inc	dx		; 1-origin (1-byte inst)
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	DOSUtilInt21
EC <		ERROR_C	COULD_NOT_GET_CURRENT_DIR			>
if DBCS_PCGEOS
PrintMessage <need to convert DOS to GEOS for DOSPathInitPathBlock?>
endif
	;
	; Perform the remaining pieces of initialization.
	; 
		mov	ds:[FP_stdPath], SP_NOT_STANDARD_PATH
		mov	ds:[FP_pathInfo], FS_NOT_STANDARD_PATH
	;
	; And unlock the path block again; it's ready to go.
	; 
		mov	bx, ss:[TPD_curPath]
		call	MemUnlock
done:
		.leave
		ret
fail:
	;
	; Couldn't enlarge the path block, so return an appropriate error
	; code explaining why we couldn't change directories.
	; 
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jmp	done
DOSPathInitPathBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCurPathSet
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

RETURN:		if directory-change was successful:
			carry clear

			TPD_curPath block altered to hold the new path and
			any private data required by the FSD (the disk
			handle will be set by the kernel). The FSD may
			have resized the block.
			FP_pathInfo must be set to FS_NOT_STANDARD_PATH
			FP_stdPath must be set to SP_NOT_STANDARD_PATH
			FP_dirID must be set to the 32-bit ID for the directory

		else
			carry set

			TPD_curPath may not be altered in any way.

			AX = error code, either
			ERROR_LINK_ENCOUNTERED
				BX = block of link data

			or ERROR_PATH_NOT_FOUND
				BX = unchanged

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
DOSCurPathSet	proc	far
		uses	cx, dx, ds
		.enter

if ERROR_CHECK
	;
	; Validate that the path string is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif

		push	bx	; save BX unless returning link data
		
		mov	bx, dx
		LocalCmpChar	ds:[bx], '\\'				
		je	settingAbsolute
	;
	; Establish thread's current directory as the one in DOS, so relative
	; changes work OK.
	; 
		call	DOSEstablishCWD
		jc	fail
mapPath:
	;
	; Attempt to switch to the passed path, mapping it as we go.
	; 
		call	DOSVirtMapDirPath
		jc	fail
	;
	; Attempt to switch to the final component, as DOSVirtMapDirPath only
	; found the beast, it didn't change there...
	; 
		push	ds, dx
		call	PathOps_LoadVarSegDS
		mov	dx, offset dosNativeFFD.FFD_name
		call	DOSInternalSetDir
		pop	ds, dx
		jc	fail
	;
	; Switch successful. Now we have the joy of setting up the path
	; block. We assume (perhaps foolishly :) that the current directory
	; will not require more than MSDOS_PATH_BUFFER_SIZE+3 bytes to hold it.
	; 3? for the drive letter, colon and leading backslash.
	; 
		call	DOSPathInitPathBlock
	;
	; Record this thing as the path currently set in DOS, unless we
	; encountered an error, in which case mark no path as current.
	; 
fail:
		segmov	ds, dgroup, di
		mov	ds:[curPath], bx
		jnc	gotCurPath
		mov	ds:[curPath], 0
gotCurPath:

	;
	; If we encountered a link, then return BX = link data,
	;

		jnc	notLink
		cmp	ax, ERROR_LINK_ENCOUNTERED
		stc
		jne	notLink
		pop	cx		; garbage pop
		jmp	done
notLink:
		pop	bx
done:
		call	DOSUnlockCWD

		.leave
		ret

settingAbsolute:
	;
	; If setting an absolute path, there's no point in establishing the
	; thread's current path, so just set the default drive from the disk
	; handle and map from there...
	; 
		call	DOSLockCWD
		call	DOSSetDefaultDriveFromDisk
		jc	fail
	;
	; Set the root directory as well.
	;

		push	ds, dx

FXIP <		mov	dx, segment fixedRootDir			>
FXIP <		mov	ds, dx						>
FXIP <		mov	dx, offset fixedRootDir				>
		
NOFXIP <	segmov	ds, cs, dx					>
NOFXIP <	mov	dx, offset rootDir				>

		mov	ah, MSDOS_SET_CURRENT_DIR
		call	DOSUtilInt21
		pop	ds, dx
		jc	fail

		jmp	mapPath
DOSCurPathSet	endp

if	FULL_EXECUTE_IN_PLACE
ResidentXIP	segment resource
	fixedRootDir	char	'\\',0		
ResidentXIP	ends
else
rootDir	char	'\\',0
endif

Resident	segment	resource	; this must be resident (it's only
					;  a byte, anyway) to prevent internal
					;  deadlock when the GFS driver calls
					;  to inform us that it's taking over
					;  a path block. If this were in a
					;  movable resource, it could be
					;  discarded when the call comes
					;  in and force a callback to the
					;  GFS driver, which is bad.

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCurPathDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCurPathDelete proc	far
		.enter
		.leave
		ret
DOSCurPathDelete endp
Resident	ends


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCreateNativeFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a file in the current directory with the native
		name found in dosNativeFFD.FFD_name, returning all the
		appropriate things for DR_FS_ALLOC_OP

CALLED BY:	DOSAllocOpCreate, DOSPathCreateDirectoryFileCommon
PASS:		dosNativeFFD.FFD_name set

		For _MSLF:
		dos7FindData.W32FD_fileName set instead

		es:si	= DiskDesc on which the operation is being performed
		cl	= attributes for the file
		al	= FileAccessFlags
RETURN:		carry set on error:
			ax	= error code
			dx	= private data if we initialize it
				  0 if we haven't initialized it
		carry clear on success:
			al	= SFN
			ah	= 0 (not open to device)
			dx	= private data
		

DESTROYED:	ds, cx, bx (assumed saved by DOSAllocOp), di

		(ds:dx points to DOSFileEntry for this file)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCreateNativeFile proc far
		.enter
	;
	; Create the file whose name is in dosNativeFFD.FFD_name.
	; 
		call	PathOps_LoadVarSegDS
if _MSLF
		tst	ds:[dos7FindData].W32FD_fileName[0]
else
		tst	ds:[dosNativeFFD].FFD_name[0]
endif
		jz	invalidName

		mov	bx, NIL			; allocate a DOS handle
		call	DOSAllocDosHandleFar	;  for our use

if _MSLF
		mov	dx, offset dos7FindData.W32FD_fileName
else
		mov	dx, offset dosNativeFFD.FFD_name
endif
MS <redo:								>
if	_MS and not _MS2 and (not _MS3)
	;
	; Use extended open, instead, so the access flags are done right.
	; 
		push	cx			; save FileAttrs
		push	si
		mov	si, dx			; ds:si <- filename
		mov	dx, mask EOA_CREATE	; dx <- create only
		mov	bl, al			; bx <- ExtendedFileAccessFlags
		clr	bh
		andnf	bl, not FAF_GEOS_BITS
if _MSLF
		mov	ax, MSDOS7F_CREATE_OR_OPEN
else
		mov	ah, MSDOS_EXTENDED_OPEN_FILE
endif
		call	DOSUtilInt21
		mov	dx, si			; ds:dx <- filename, again
		pop	si			; restore SI
		;
		; restore FileAttrs as MSDOS_EXTENDED_OPEN_FILE returns
		; action-taken in CL - brianc 4/29/94
		;
		pop	cx			; cl = FileAttrs
		jc	createError
else
	;
	; Extended open doesn't exist (XXX: DOES IT EXIST IN OS/2?), so we
	; have to create & reopen the file, perhaps.
	; 
OS2 <		clr	ch		; OS/2 upchucks if this is non-0>
		mov	bl, al		; preserve access flags for re-open
					;  should we not be opening in compat
					;  mode
		mov	ah, MSDOS_CREATE_ONLY
		call	DOSUtilInt21
MS <		jc	createError					>
DRI <		jc	errorFreeJFTSlot				>
OS2 <		jc	errorFreeJFTSlot				>
	;
	; If request involves an FAF_EXCLUDE that is not FE_COMPAT (which is
	; what is used by MSDOS_CREATE_ONLY), close the handle we just got
	; and re-open the file using the proper access flags.
	; 
			CheckHack <FE_COMPAT eq 0>
		test	bl, mask FAF_EXCLUDE
		jz	createdOK

		push	bx			; save access flags
		mov_tr	bx, ax			; bx <- file handle
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		pop	ax			; al <- access flags
		andnf	al, not FAF_GEOS_BITS
		mov	ah, MSDOS_OPEN_FILE
		call	DOSUtilInt21
MS <		jc	createError					>
DRI <		jc	errorFreeJFTSlot				>
OS2 <		jc	errorFreeJFTSlot				>
createdOK:
endif
	;
	; No error during the creation, so now we get to do the regular stuff.
	; 
		mov_tr	bx, ax
		call	DOSFreeDosHandleFar		; bl <- SFN
		clr	bh				; not a device
		mov	ax, bx
if SEND_DOCUMENT_FCN_ONLY
		CheckHack <type dosFileTable eq 11>
		mov	dx, bx
		shl	bx
		add	dx, bx
		shl	bx, 2
		add	bx, dx			; *8+*2+*1=*11
else	; not SEND_DOCUMENT_FCN_ONLY
		CheckHack <type dosFileTable eq 10>
		shl	bx
		mov	dx, bx
		shl	bx
		shl	bx
		add	bx, dx			; *8+*2=*10, of course
endif	; SEND_DOCUMENT_FCN_ONLY
		add	bx, offset dosFileTable
		mov	dx, bx			; return private data offset
						;  in dx, please...

		mov	ds:[bx].DFE_index, -1		; index not gotten yet
		mov	ds:[bx].DFE_attrs, cl		; attributes are as
							;  we created them
		mov	ds:[bx].DFE_flags, 0		; neither geos nor
							;  dirty...
		mov	ds:[bx].DFE_disk, si
		mov	di, si

if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	checkDisk
		BitSet	ds:[bx].DFE_flags, DFF_LIKELY_DOC
checkDisk:
endif	; SEND_DOCUMENT_FCN_ONLY

if not _OS2
		call	DOSCheckDiskIsOurs
		jnc	done
		ornf	ds:[bx].DFE_flags, mask DFF_OURS; (clears carry)
else
	;
	; We've no access to the SFT under OS2, so just pretend the disk isn't
	; ours and the SFT isn't valid...
	; 
		clc
endif
done:
		.leave
		ret
invalidName:
		mov	ax, ERROR_INVALID_NAME
		jmp	noPrivateDataError
MS <createError:							>
MS <		cmp	ax, ERROR_TOO_MANY_OPEN_FILES			>
MS <		jne	errorFreeJFTSlot				>
MS <		call	MSExtendSFT					>
MS <		jnc	redo						>

errorFreeJFTSlot:
		mov	bx, NIL
		call	DOSFreeDosHandleFar
noPrivateDataError:
		mov	dx, 0				; no private data
		stc
		jmp	done
DOSCreateNativeFile endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSInitGeosFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the newly-created geos file with appropriate
		values.

CALLED BY:	DOSAllocOpCreate, DOSPathOpCreateDir,
		DOSLinkCreateLink

PASS:		ds	= dgroup
		al	= SFN of open file to initialize
		dx	= GeosFileType for the new file (GFT_DATA,
			  GFT_DIRECTORY)

		es:di	= longname of new file

		ds:[dosNativeFFD.FFD_name] contains DOS name of file in current
			dir to which we are writing.

RETURN:		carry set on error:
			ax	= error code
			file closed & deleted again
		carry clear if ok
DESTROYED:	cx, ds, bx (assumed saved by DOSAllocOp and DOSPathOpCreateDir)
		dx


PSEUDO CODE/STRATEGY:
		copy longname into dosInitHeader.GFH_longName
		store file type in dosInitHeader.GFH_type
		get current date & time and store in dosInitHeader.GFH_created
		copy final component 
		convert SFN to a DOS handle
		write dosInitHeader out
		free the DOS handle

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSInitGeosFile	proc	far
		uses	es, di, si
		.enter

if ERROR_CHECK
	;
	; Validate that the name string is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, es						>
FXIP<		mov	si, di						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
		push	ax
	;
	; Copy the longname into the header.
	; 
		segxchg	ds, es
		mov	si, di		; ds:si - longname
		mov	di, offset dosInitHeader.GFH_longName
		mov	cx, (size GFH_longName)/2
		CheckHack <(size GFH_longName and 1) eq 0>
		rep	movsw
		segxchg	ds, es

	;
	; Set the file type to that passed.
	; 
		mov	ds:[dosInitHeader].GFH_type, dx
if DBCS_PCGEOS
	;
	; Indicate that this is a DBCS file
	;
		mov	ds:[dosInitHeader].GFH_flags, mask GFHF_DBCS
endif
	;
	; Set the creation timestamp for the file.
	; 
		call	DOSGetTimeStamp
		mov	ds:[dosInitHeader].GFH_created.FDAT_date, dx
		mov	ds:[dosInitHeader].GFH_created.FDAT_time, cx
	;
	; Now actually write the beast out. This of course positions the file
	; after the header, which is where we need it.
	; 
		mov	bx, ax
		call	DOSAllocDosHandleFar	; bx <- DOS handle
		mov	dx, offset dosInitHeader
		mov	cx, size dosInitHeader
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
		jc	error
		cmp	ax, size dosInitHeader
		jne	noRoom
	;
	; flush header to disk so that longname can be accessed for
	; filename-existence-checking
	;
		mov	ah, MSDOS_COMMIT
		call	DOSUtilInt21
		jc	error
	;
	; Header written ok, so release the DOS handle and restore the SFN
	; 
		call	DOSFreeDosHandleFar
		pop	ax
done:
		.leave
		ret
noRoom:
	;
	; Unable to write all the header, so return the standard error code
	; for this case, though it seems strangely inappropriate...
	;
		mov	ax, ERROR_SHORT_READ_WRITE
error:
	;
	; Error writing the header, so close down and delete the file
	; 
		inc	sp		; discard saved AX
		inc	sp
		push	ax		; save error code
	;
	; First close down the file.
	; 
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
	;
	; Then delete the thing.
	; 
		mov	dx, offset dosNativeFFD.FFD_name
		mov	ah, MSDOS_DELETE_FILE
		call	DOSUtilInt21
	;
	; Release the JFT slot we allocated.
	; 
		VSem	ds, jftEntries, TRASH_AX_BX
	;
	; And return the original error.
	; 
		pop	ax
		stc
		jmp	done
DOSInitGeosFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocOpCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new file of the passed name, probably with a
		geos header, but optionally not.

CALLED BY:	DOSAllocOp
PASS:		ds:dx	= name of file to create
		es:si	= DiskDesc on which operation is being performed
		ch	= FileCreateFlags
		cl	= FileAttrs
		al	= FileAccessFlags
RETURN:		carry set if couldn't create:
			ax	= error code
		carry clear if ok:
			al	= SFN
			ah	= 0 (not device)
			dx	= data private to the FSD
DESTROYED:	ds, bx, cx (assumed preserved by DOSAllocOp), di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllocOpCreate proc	near
		.enter
if ERROR_CHECK
	;
	; Validate that the name string is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
	;
	; Map the path name to a DOS file, if possible. If the mapping
	; succeeds, it's an error. In the normal case, it'll map all the
	; way to the final component and return ERROR_FILE_NOT_FOUND.
	; 
		mov_tr	bx, ax		; save FileAccessFlags
		call	DOSVirtMapFilePath
		jc	checkMapError
		mov	ax, ERROR_FILE_EXISTS
returnError:
		stc
		jmp	done
checkMapError:
		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	returnError	; => couldn't map intervening
					;  directories, so can't create

	;
	; At this point, dosNativeFFD.FFD_name contains the final component
	; mapped to its DOS name, if the final component is a legal DOS name.
	; This is important, as we check the FCF_NATIVE flag...
	; 
		test	ch, mask FCF_NATIVE
		jz	handleGeosCreate
	;
	; Wants a native-compatible file, so create one. It will make sure the
	; name was valid....
	; 
		mov_tr	ax, bx		; al <- FileAccessFlags
		call	DOSCreateNativeFile
		jc	createNativeError
generateNotify:
	;
	; Figure the ID for the file (don't do this in DOSCreateNativeFile,
	; as that's used for creating @DIRNAME.000 and the like, where we don't
	; want to waste the time).
	; 
		mov	bx, dx
if _MSLF
		GetIDFromFindData	ds:[dos7FindData], cx, dx
else
		GetIDFromDTA	ds:[dosNativeFFD], cx, dx
endif
		movdw	ds:[bx].DFE_id, cxdx
		mov	dx, bx

if SEND_DOCUMENT_FCN_ONLY
		test	ds:[bx].DFE_flags, mask DFF_LIKELY_DOC
		jz	done
endif	; SEND_DOCUMENT_FCN_ONLY

	;
	; Generate a file-change notification for everyone to see.
	; 
		push	ax
		mov	ax, FCNT_CREATE
		call	DOSFileChangeGenerateNotifyWithName	; clears carry
		pop	ax
done:
		.leave
		ret

createNativeError:
	;
	; Clean up private data after error, if we've initialized it
	;
		tst	dx
		jz	noPrivateData
		mov	bx, dx
		mov	ds:[bx].DFE_disk, 0
		mov	ds:[bx].DFE_flags, 0
noPrivateData:
		stc
		jc	done
		.UNREACHED

handleGeosCreate:
		test	ch, mask FCF_NATIVE_WITH_EXT_ATTRS
		jnz	validateLongNameAsNative
	;
	; Generate an unique DOS name for the geos name.
	; 
		call	DOSVirtGenerateDosName
		jc	done
	;
	; Now create and initialize the file.
	; 
createGeosUsingNativeName:
if _MSLF
	;
	; Copy generated DOS name to dos7FindData, so that it can be passed
	; to DOSCreateNativeFile.
	;
		call	DOSUtilCopyFilenameFFDToFindData
endif
		mov_tr	ax, bx			; ax <- FileAccessFlags
		call	DOSCreateNativeFile
		jc	createNativeError	; => couldn't create, so bail

	; (ds = dgroup)
	; Initialize the file as just regular data, until we're told otherwise.
	; 
		push	es, dx
		les	di, ds:[dosFinalComponent]
		mov	bx, dx
		ornf	ds:[bx].DFE_flags, mask DFF_GEOS
		mov	dx, GFT_DATA
		call	DOSInitGeosFile
		pop	es, dx
		jnc	generateNotify
		jmp	createNativeError	; => error during init

validateLongNameAsNative:
	;
	; Make sure the longname passed is identical to the DOS name. If it's
	; not, it doesn't cut the mustard. We allow differences in case,
	; though.
	; 
		call	PathOps_LoadVarSegDS
		tst	ds:[dosNativeFFD].FFD_name[0]
		jnz	createGeosUsingNativeName
		mov	ax, ERROR_INVALID_NAME
		stc
		jmp	done
DOSAllocOpCreate endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocOpOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open an existing file or device.

CALLED BY:	DOSAllocOp
PASS:		ds:dx	= path of file to open
		es:si	= DiskDesc on which operation is being performed
		al	= FullFileAccessFlags
		CWD lock grabbed and thread's path installed in DOS
RETURN:		carry set on error:
			ax	= error code
			bx	= handle of FSLinkHeader data if
				  attempted to open link.
		carry clear on success:
			al	= SFN
			ah	= non-zero if open to device
			dx	= FSD-private data for the file
DESTROYED:	ds, cx (assumed saved by DOSAllocOp)

PSEUDO CODE/STRATEGY:
		This is a several-stage process:
			- map the passed path from virtual to native space
			- see if the file is a geos file *before* opening
			  it properly, as caller might be opening it
			  write-only and deny-read...this causes files to
			  be opened twice, but there's not much we can
			  do about it.
			- if the file is a geos file, but FFAF_RAW is
			  passed, pretend it's not a geos file
			- allocate a JFT slot for the open
			- perform the open
			- if the open succeeded and write access was
			  requested, make sure the destination is writable.
			- if the file's a geos file not opened in raw mode,
			  seek past the header.
			- call DOS to see if the file's actually a device.
			- initialize the dosFileTable entry for the open
			  file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllocOpOpen	proc	near
		.enter
if ERROR_CHECK
	;
	; Validate that the name string is not in a movable code segment
	;
FXIP<		push	bx, si						>
FXIP<		mov	bx, ds						>
FXIP<		mov	si, dx						>
FXIP<		call	ECAssertValidFarPointerXIP			>
FXIP<		pop	bx, si						>
endif
	;
	; Map the geos name to a DOS name.
	; 
		call	DOSVirtMapFilePath
		LONG jc	done

	;
	; See if the thing is a geos file, passing the FileFindDTA that
	; DOSVirtMapFilePath copied to dosNativeFFD for us.
	; 
		call	PathOps_LoadVarSegDS
		push	si
	    ;
	    ; If opened with a longname (FFD_attributes has FA_GEOS_FILE set),
	    ; it must be a geos file, so no need to open it a second time...
	    ; 
		inc	ax		; convert from 0-2 -> 1-3
					;  (1-byte inst)

		test	ds:[dosNativeFFD].FFD_attributes, FA_GEOS_FILE
		jnz	checkRaw
	    ;
	    ; If file will have read permission when it's opened, prefer to
	    ; use that handle and do an extra seek, rather than performing
	    ; two opens here.
	    ; 
		test	al, 1		; readable?
		jnz	revertOpenModeAndOpenIt
		

		mov	dx, offset dosNativeFFD
		mov	si, offset dosOpenHeader
if DBCS_PCGEOS
		mov	cx, size dosOpenHeader + \
				size dosOpenType + size dosOpenFlags
else
		mov	cx, size dosOpenHeader
endif
		push	es
		segmov	es, ds
		push	ax
		call	DOSVirtOpenGeosFileForHeader
		pop	ax
		pop	es
		jc	notGeosFile
	;
	; Mark it as geos file and point dosFinalComponent to the read-in
	; long name, so file-change notification always uses virtual name.
	; 
		ornf	ds:[dosNativeFFD].FFD_attributes, FA_GEOS_FILE
		mov	ds:[dosFinalComponent].segment, ds
		mov	ds:[dosFinalComponent].offset,
				offset dosOpenHeader.GPH_longName
checkRaw:
		test	al, mask FFAF_RAW	; pretend it's not?
		jz	revertOpenModeAndOpenIt	; no -- just open it
notGeosFile:
	;
	; Make sure we know the file's not a geos file...
	; 
		andnf	ds:[dosNativeFFD].FFD_attributes, not FA_GEOS_FILE
revertOpenModeAndOpenIt:
		dec	ax		; convert FAF_MODE back to what
					;  DOS expects (1-byte inst)

		pop	si
	;
	; Make sure there's a JFT slot open for us by allocating one. We pass
	; NIL as the SFN so it stays free, but we will have P'ed jftEntries, so
	; we're content.
	; 
		mov	bx, NIL
		call	DOSAllocDosHandleFar
		mov	dx, offset dosNativeFFD.FFD_name; ds:dx <- file to open

MS <redo:								>
		push	ax			; save access mode & function
		andnf	al, not FAF_GEOS_BITS
		mov	ah, MSDOS_OPEN_FILE
		call	DOSUtilInt21
		pop	bx			; bx <- requested access mode
						;  and DOS function
MS <		jc	openError					>
DRI <		jc	doneReleaseJFTSlot				>
OS2 <		jc	doneReleaseJFTSlot				>
		call	DOSAllocOpFinishOpen
done:
		.leave
		ret

MS <openError:								>
MS <		cmp	ax, ERROR_TOO_MANY_OPEN_FILES			>
MS <		jne	doneReleaseJFTSlot				>
MS <		call	MSExtendSFT					>
MS <		jc	doneReleaseJFTSlot				>
MS <		mov_tr	ax, bx		; ax <- access mode & function	>
MS <		jmp	redo						>
	
doneReleaseJFTSlot:		
	;
	; Release the JFT slot we allocated.  Don't trash AX or BX
	; 
		push	ds
		call	PathOps_LoadVarSegDS
		VSem	ds, jftEntries
		pop	ds

		stc
		jmp	done

DOSAllocOpOpen	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocOpFinishOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish opening a file, determining if it's actually
		a geos file, or if it's a device, initializing its
		DOSFileEntry, etc.

CALLED BY:	(INTERNAL) DOSAllocOpOpen
PASS:		ax	= DOS file handle
		bl	= FileAccessFlags
		ds	= dgroup
		ds:[dosFileType], ds:[dosNativeFFD] set for file just
			opened
RETURN:		carry clear:
			al	= SFN
			ah	= non-zero if open to device
			dx	= FSD-private data for the file
DESTROYED:	ds, cx
SIDE EFFECTS:	DOSFileEntry for the file is initialized
     		dosOpenHeader & dosOpenType may be overwritten

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/16/92	Broke out of DOSAllocOpOpen

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSAllocOpFinishOpen proc near
		.enter
		xchg	ax, bx			; bx <- file handle
						; ax <- access mode
	;------------------------------------------------------------
	;	PHASE ONE: FIGURE IF THE THING IS GEOS AND IF WE CARE
	;------------------------------------------------------------

	;
	; If we knew before (FA_GEOS_FILE is set), we still know...
	; Slight change of plans: if the file type we found before was
	; GFT_OLD_VM, it has a longname, but it's not treated as a geos file.
	; -- ardeb 8/26/92
	; 
		cmp	ds:[dosFileType], GFT_OLD_VM
		je	oldGeos

		test	ds:[dosNativeFFD].FFD_attributes, FA_GEOS_FILE
		jnz	isGeos
	;
	; If file opened for writing only, then we know for sure whether
	; the thing is DOS or GEOS.
	; 
		inc	ax			; convert access flags from 0-2
						; to 1-3, thereby making b0
						; be set if file opened for
		test	al, 1			; reading
		jz	figureDevice		; not geos, and haven't
						;  modified the file position,
						;  so just go do the device
						;  thing...
	;
	; Now check the FFAF_RAW bit to make sure the caller doesn't want us
	; to simply ignore the geos-ness of the file...
	; 
		test	al, mask FFAF_RAW
		jnz	figureDevice		; => caller wants raw access
						;  to the file, so don't
						;  check the header...
	;
	; Else we now have to read the first part of the header to see if the
	; thing is a geos file.
	; 
		push	es, si
		segmov	es, ds
		mov	si, offset dosOpenHeader; es:si <- buffer
if DBCS_PCGEOS
		mov	cx, size dosOpenHeader + size dosOpenType + \
							size dosOpenFlags
else
		mov	cx, size dosOpenHeader + size dosOpenType
endif
						; cx <- # bytes to read
		.assert (dosOpenType-dosOpenHeader) eq size dosOpenHeader and \
			(offset GFH_type eq size dosOpenHeader)
if DBCS_PCGEOS
		.assert (dosOpenFlags-dosOpenType) eq size dosOpenType and \
			(offset GFH_flags eq \
				(size dosOpenHeader + size dosOpenType))
endif

		call	DOSVirtReadFileHeader
		pop	es, si
		jc	notGeos
	;
	; If it's an old-style VM file, we don't treat it as a geos file, as
	; it doesn't have a header as big as we think it does...
	; 
		cmp	ds:[dosOpenType], GFT_OLD_VM
		je	oldGeos
	;
	; It is indeed a geos file, so set the FA_GEOS_FILE bit to clue us
	; in later on... point dosFinalComponent to the read-in long name,
	; so file-change notification always uses virtual name.
	; 
		ornf	ds:[dosNativeFFD].FFD_attributes, FA_GEOS_FILE
		mov	ds:[dosFinalComponent].segment, ds
		mov	ds:[dosFinalComponent].offset,
				offset dosOpenHeader.GPH_longName
	;
	; If the file's a geos file, seek past the header.
	; 
isGeos:
		mov	ax, MSDOS_POS_FILE shl 8 or FILE_POS_START
		clr	cx
		mov	dx, size GeosFileHeader
		call	DOSUtilInt21
		jmp	figureDevice
oldGeos:
	;
	; Remember this is an old PC/GEOS file
	; 
		mov	ds:[dosFileType], GFT_OLD_VM
		andnf	ds:[dosNativeFFD].FFD_attributes, not FA_GEOS_FILE
notGeos:
	;
	; Not a geos file, but we need to have the file position at the
	; start of the file...
	; 
		mov	ax, MSDOS_POS_FILE shl 8 or FILE_POS_START
		clr	cx, dx
		call	DOSUtilInt21

	;------------------------------------------------------------
	;	PHASE TWO: CHECK FOR DOS DEVICE
	;------------------------------------------------------------
figureDevice:
	;
	; Determine if the file is actually open to a device.
	; 
		mov	ax, MSDOS_IOCTL_GET_DEV_INFO
		call	DOSUtilInt21
	;
	; Initialize our internal file-table entry.
	; 
		call	DOSFreeDosHandleFar	; bl <- SFN
		clr	bh			; both for indexing the table,
						;  and to indicate not dev.

		mov	ax, bx
		test	dx, mask DOS_IOCTL_IS_CHAR_DEVICE
		jz	initFileTableEntry
		not	ah		; flag device
	;------------------------------------------------------------
	;	PHASE THREE: INITIALIZE DOSFileEntry
	;------------------------------------------------------------
initFileTableEntry:
if SEND_DOCUMENT_FCN_ONLY
			CheckHack <type dosFileTable eq 11>
		mov	dx, bx
		shl	bx
		add	dx, bx
		shl	bx, 2
		add	bx, offset dosFileTable
		add	bx, dx
else	; not SEND_DOCUMENT_FCN_ONLY
			CheckHack <type dosFileTable eq 10>
		shl	bx
		mov	dx, bx
		shl	bx
		shl	bx
		add	bx, offset dosFileTable
		add	bx, dx
endif	; SEND_DOCUMENT_FCN_ONLY

		mov	ds:[bx].DFE_index, -1	; flag index unknown

if _MSLF
		GetIDFromFindData ds:[dos7FindData], cx, dx
else
		GetIDFromDTA ds:[dosNativeFFD], cx, dx
endif
		movdw	ds:[bx].DFE_id, cxdx

		mov	dl, ds:[dosNativeFFD].FFD_attributes
		mov	ds:[bx].DFE_attrs, dl
		
		mov	ds:[bx].DFE_flags, 0	; assume not geos

		test	dl, FA_GEOS_FILE
		jz	checkOldGeos
		mov	ds:[bx].DFE_flags, mask DFF_GEOS
checkOldGeos:
		cmp	ds:[dosFileType], GFT_OLD_VM
		jne	checkOurs
		mov	ds:[bx].DFE_flags, mask DFF_OLD_GEOS
checkOurs:
		mov	ds:[bx].DFE_disk, si

		mov	dx, bx		; return offset as our private data
					;  for the file

if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	afterDocTree
		BitSet	ds:[bx].DFE_flags, DFF_LIKELY_DOC
afterDocTree:
endif	; SEND_DOCUMENT_FCN_ONLY

if not _OS2
		mov	di, si
		call	DOSCheckDiskIsOurs
		jnc	done
		ornf	ds:[bx].DFE_flags, mask DFF_OURS
done:
else
	;
	; We've no access to the SFT under OS2, so just pretend the disk isn't
	; ours and the SFT isn't valid...
	; 
		clc
endif
		.leave
		ret
DOSAllocOpFinishOpen endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSAllocOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a filesystem operation that will allocate a new file
		handle.
PASS:		al	= FullFileAccessFlags
		ah	= FSAllocOpFunction to perform.
		cl	= old SFN iff ah = FSAOF_REOPEN
		ds:dx	= path
		es:si	= DiskDesc on which the operation will take place,
			  locked into drive (FSInfoResource and affected drive
			  locked shared). si may well not match the disk handle
			  of the thread's current path, in which case ds:dx is
			  absolute.

RETURN:		Carry clear if operation successful:
			al	= SFN of open file
			ah	= non-zero if opened to device, not file.
			dx	= private data word for FSD
			bx	- destroyed
		Carry set if operation unsuccessful:
			ax	= error code.
			bx	= handle of link data (FSLinkHeader)
				  if attempted to open link
DESTROYED:

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
allocOps	nptr.near	DOSAllocOpOpen,
				DOSAllocOpCreate,
				DOSAllocOpOpen
DOSAllocOp	proc	far
		uses	cx, ds
		.enter
EC <		cmp	ah, FSAllocOpFunction				>
EC <		ERROR_AE	INVALID_ALLOC_OP			>

		call	DOSEstablishCWD
		jc	done
	;
	; Re-establish directory indices for any files on this disk that don't
	; have them fixed yet. Note the check to ensure we run the disk, since
	; we might be called as the primary FSD by a secondary FSD...
	; 
		mov	di, si
		call	DOSCheckDiskIsOurs
		jnc	doIt
DRI <		call	DRIFixIndices					>
	;
	; We always open/create things in compatibility mode on local disks
	; so we have the control of whether an application can open something.
	; This also ensures we can always get to our header for local files.
	; 
		andnf	al, not mask FAF_EXCLUDE
doIt:
		mov	bl, ah
		clr	bh
		shl	bx
		push	ax
		call	cs:[allocOps][bx]
		pop	cx
		jnc	maybeSendNotification
done:
		call	DOSUnlockCWD
		.leave
		ret

maybeSendNotification:
	;
	;  We don't want to send notification if it's a re-open
	;

		cmp	ch, FSAOF_REOPEN
		je	done

		call	FSDCheckOpenCloseNotifyEnabled
		jnc	done

	;
	; Send file-change notification about this thing being open
	;  dx = offset to DOSFileEntry
	;
		push	ds, ax, dx, di
		call	PathOps_LoadVarSegDS
		mov	di, dx
if SEND_DOCUMENT_FCN_ONLY
		test	ds:[di].DFE_flags, mask DFF_LIKELY_DOC
		jz	afterNotif
endif	; SEND_DOCUMENT_FCN_ONLY
		movdw	cxdx, ds:[di].DFE_id
		mov	ax, FCNT_OPEN
		call	FSDGenerateNotify	
		clc
afterNotif::
		pop	ds, ax, dx, di
		jmp	done

if 0
reopen:
		push	di, si

		mov	bx, NIL
		call	DOSAllocDosHandleFar
		
		andnf	al, not FAF_GEOS_BITS
		mov	ah, MSDOS_OPEN_FILE
		call	DOSUtilInt21

		call	DOSFreeDosHandleFar

	;
	;  Calculate the offset of the DOSFileEntry
	;

		mov	al, bl				;al <- SFN
		clr	ah
		mov	dl, size DOSFileEntry
		mul	dl				;ax <- private
		mov_tr	di, ax
		add	di, offset dosFileTable		;es:di <- new DFE

	;
	;  Calculate the offset of the old DFE
	;

		mov	al, cl				;al <- SFN
		clr	ah
		mov	dl, size DOSFileEntry
		mul	dl				;ax <- private
		mov_tr	si, ax
		add	si, offset dosFileTable		;es:si <- old DFE

	;
	;  Copy stuff from the old DFE to the new one
	;

		mov	ax, es:[si].DFE_index
		mov	es:[di].DFE_index, ax

		mov	ax, es:[si].DFE_disk
		mov	es:[di].DFE_disk, ax

		mov	al, es:[si].DFE_attrs
		mov	es:[di].DFE_attrs, al

		movdw	es:[di].DFE_id, es:[si].DFE_id, ax

	;
	;  Copy flags from the old DFE to the new one, preserving the
	;  new DFF_DIRTY
	;

		mov	al, es:[si].DFE_flags		;al <- old flags
		and	al, not mask DFF_DIRTY
		and	es:[di].DFE_flags, mask DFF_DIRTY
		or	es:[di].DFE_flags, al

	;
	;  Free the old DOSFileEntry
	;

		clr	es:[si].DFE_flags
		clr	es:[si].DFE_disk

	;
	;  Return dx = offset to the new DOSFileEntry and al = new SFN
	;
		
		mov	al, bl				;al <- SFN
		clr	ah
		mov	dx, di

		pop	di, si

		jmp	done

endif

DOSAllocOp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCheckFileInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed file is currently open and bitch if so.

CALLED BY:	DOSPathOp
PASS:		ds:dx	= path for file to check
		working directory lock snagged

RETURN:		carry clear if OK:
			ax	= preserved
			ds:dx	= dosNativeFFD.FFD_name
			virtual path mapped to native
		If error:
			carry set, ax is one of (FileError):
			ERROR_FILE_IN_USE
			ERROR_LINK_ENCOUNTERED
				bx = handle of link data

DESTROYED:	di, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCheckFileInUse	proc near
		uses	cx
		.enter

		push	bx	; Return unchanged if not a link

	;
	; Map the virtual path to a real one and return ds:dx pointing to the
	; final component.
	; 
		call	DOSVirtMapFilePath
		jc	notFoundOrLink	; File is either not there, or
					; is a link. 
		
	;
	; Get the index for dosNativeFFD.FFD_name in the current directory.
	; 
		call	PathOps_LoadVarSegDS
		clr	bx
		push	ax		; save in case everything's cool
if _MSLF
		GetIDFromFindData	ds:[dos7FindData], ax, dx
else
		GetIDFromDTA	ds:[dosNativeFFD], ax, dx
endif
	;
	; See if any open file has that ID, etc.
	; 
		mov	bx, SEGMENT_CS
		mov	di, offset DCFIU_callback
		call	DOSUtilFileForEach
		pop	ax
		jnc	popBX
		mov	ax, ERROR_FILE_IN_USE
popBX:
		pop	bx
done:
		.leave
		ret

	;
	; If the file's not found, then restore passed BX.  If the
	; file's a link, then return BX to caller
	;
notFoundOrLink:
		cmp	ax, ERROR_LINK_ENCOUNTERED
		stc
		jne	popBX

		pop	cx		; garbage pop
		jmp	done

DOSCheckFileInUse endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCFIU_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to determine if a file is in active use.

CALLED BY:	DOSCheckFileInUse via DOSUtilFileForEach
PASS:		ds:bx	= DOSFileEntry
		axdx	= file ID
		si	= handle of disk on which file resides
RETURN:		carry set to stop processing (open file matches ID)
		carry clear to continue
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCFIU_callback	proc	far
		.enter
	;
	; Check the ID against the ID stored in the private data for the file.
	; 
		cmp	ds:[bx].DFE_id.high, ax
		jne	noMatch
		cmp	ds:[bx].DFE_id.low, dx
		jne	noMatch
	;
	; Matches in all particulars. Upchuck.
	; 
		stc
done:

		.leave
		ret
noMatch:
		clc
		jmp	done
DCFIU_callback	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOpCreateDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a directory with its long-directory file inside it.

CALLED BY:	DOSPathOp

PASS:		ds:dx	= name of directory to create.
		es:si	= DiskDesc for disk on which to perform it
		CWD lock grabbed, with all that implies.

		For _MSLF:
			di = {word} FSPathOpFunction * 2
RETURN:		carry set on error:
			ax	= error code
			if AX = ERROR_LINK_ENCOUNTERED
				bx = handle of link data

		carry clear if happy.
DESTROYED:	ds, dx (assumed saved by DOSPathOp)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpCreateDir	proc	far
		uses	cx
		
		.enter

		push	bx	; return unchanged if not a link
		
	;
	; First map the virtual to the native.  If the file already
	; exists, or a link was encountered, then exit.
	; 
		call	DOSVirtMapDirPath
		jc	checkError
	;
	; If mapping successful, the name is already taken, so bail.
	;

fileExists:
		mov	ax, ERROR_FILE_EXISTS
bail:
		stc
		jmp	done

checkError:
		cmp	ax, ERROR_LINK_ENCOUNTERED
		jne	notLink

	;
	; If a link was encountered, and it's the final component,
	; then return ERROR_FILE_EXISTS
	;
		call	DOSPathCheckMappedToEnd
		je	fileExists		

	;
	; Otherwise, return the link data in BX
	;
		add	sp, 2
		stc
		jmp	doneNoPop

notLink:
		cmp	ax, ERROR_PATH_NOT_FOUND
		jne	bail		; this is the only acceptable error,
					;  as it might mean the final component
					;  doesn't exist.
		
		call	DOSPathCheckMappedToEnd
		jne	bail

	;
	; Generate the appropriate DOS name for the new directory.
	; 3/21/92: as a convenience for the user, try and use the specified
	; name of the directory, if it's a valid DOS name and doesn't
	; already exist.
	; 
		call	PathOps_LoadVarSegDS
if _MSLF
		mov	dx, offset dos7FindData.W32FD_fileName	; assume so
		tst	ds:[dos7FindData].W32FD_fileName[0]
		jz	generateDosName		; => wasn't valid DOS name.

	;
	; Passed name was valid DOS name.  If FSPOF_CREATE_DIR is called,
	; just use the DOS name as the native name.  Otherwise,
	; FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME is called, and we need to
	; check if the valid DOS name is a valid DOS short name.
	;
		Assert	inList, di, <(FSPOF_CREATE_DIR*2), \
				(FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME*2)>
		cmp	di, FSPOF_CREATE_DIR * 2
		je	haveDosName		; => FSPOF_CREATE_DIR

	;
	; FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME is called.
	;
	; If DOSVirtMapDirPath returned identical strings (case-sensitive)
	; in FFD_name and W32FD_fileName, it means the passed name conforms
	; to 8.3 format.  Then we can just use the passed name as the native
	; name.
	;
		;pusha
		push	ax, cx, dx, bx, bp, si, di
		push	es
		mov	si, dx			; ds:si = W32FD_fileName
		segmov	es, ds
		mov	di, offset dosNativeFFD.FFD_name    ; es:di = FFD_name
		clr	cx			; null-terminated
		SBCompareStrings
		pop	es
		pop	ax, cx, dx, bx, bp, si, di
		;popa
		je	haveDosName		; => conforms to 8.3
generateDosName:
else
		mov	dx, offset dosNativeFFD.FFD_name	; assume so
		tst	ds:[dosNativeFFD].FFD_name[0]
		jnz	haveDosName		; => was valid DOS name, but
						;  doesn't exist, else
						;  DOSVirtMapDirPath would
						;  have returned carry clear.
endif
		call	DOSVirtGenerateDosName
		jc	done
if _MSLF
	;
	; Copy the generated filename from dosNativeFFD.FFD_name to
	; dos7FindData.W32FD_fileName, since DOSPathCheckExactMatch
	; furthur below checks *dosFinalComponent against W32FD_fileName.
	;
		call	DOSUtilCopyFilenameFFDToFindData
endif
haveDosName:
	;
	; Make sure the combination of the current dir and the native
	; name doesn't result in a path that's too long...
	; 
		call	DOSPathEnsurePathNotTooLong
		jc	done

	;
	; Figure the ID of the containing directory while we've still got
	; it.
	; 
		mov	bx, dx
		call	DOSFileChangeGetCurPathID	; load current 
		push	cx, dx
		mov	dx, bx
	;
	; Create the directory. If the directory's name matches the
 	; DOS name exactly, then don't bother creating the @DIRNAME
 	; file, as it'll get created when (if) it's needed.
	;

if _MSLF
		mov	ax, MSDOS7F_CREATE_DIR
else
		mov	ah, MSDOS_CREATE_DIR
endif
		call	DOSUtilInt21
		jc	donePopID

		call	DOSPathCheckExactMatch
		jc	generateNotify
		
	;
	; Change to that directory so we can create the @DIRNAME.000 file.
	; 
		call	DOSInternalSetDir
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>

	;
	; Call the common routine to create the file
	; 

		call	DOSPathCreateDirectoryFileCommon
		jc	deleteDir
		
		mov	dx, GFT_DIRECTORY
		push	es
		les	di, ds:[dosFinalComponent]
		call	DOSInitGeosFile
   		pop	es
		jc	deleteDir		; file closed on error

	;
	; Close down the special file.
	; 
   		mov	bl, al
		call	DOSAllocDosHandleFar
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		mov	bx, NIL
		call	DOSFreeDosHandleFar

generateNotify:
	;
	; Generate notification 
	; 
		mov	ax, FCNT_CREATE
		pop	cx, dx			; cxdx <- dir ID
if SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	afterNotif
endif	; SEND_DOCUMENT_FCN_ONLY
		lds	bx, ds:[dosFinalComponent]
		call	FSDGenerateNotify
afterNotif::

	;
	; Much happiness.
	; 
		clc
done:
		pop	bx
doneNoPop:
		.leave
		ret
donePopID:
		add	sp, 4		; discard saved cur-dir ID
		stc
		jmp	done

deleteDir:
		add	sp, 4		; discard saved cur-dir ID
	;
	; Bleah. Couldn't initialize the @DIRNAME.000 file, so we need to
	; biff the directory. This is made more complex by our having wiped
	; out the DOS name of the directory that formerly was in the
	; dosNativeFFD.FFD_name. Happily, DOS can tell us what it is, as it's
	; the final component of the current directory.
	; 
		push	ax
		push	si
		mov	si, offset dosPathBuffer
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	DOSUtilInt21
	;
	; Retreat to the parent directory.
	; 
		push	ds
		segmov	ds, cs
		mov	dx, offset cs:poDotDotPath
FXIP<		push	cx						>
FXIP<		clr	cx						>
FXIP<		call	SysCopyToStackDSDX				>
FXIP<		pop	cx						>
		call	DOSInternalSetDir
FXIP<		call	SysRemoveFromStack				>
		pop	ds
EC <		ERROR_C	GASP_CHOKE_WHEEZE				>
	;
	; Find the start of the last component. Recall that GET_CURRENT_DIR
	; doesn't return an absolute path...
	; 
findFinalComponentLoop:
		mov	dx, si		; record first char after last b.s.
inComponentLoop:
		lodsb
		cmp	al, '\\'
		je	findFinalComponentLoop
		tst	al
		jnz	inComponentLoop
	;
	; ds:dx is name of the final component, so biff it.
	; 
		mov	ah, MSDOS_DELETE_DIR
		call	DOSUtilInt21
		pop	si
	;
	; Recover initial error code, set carry and boogie.
	; 
		pop	ax
		stc
		jmp	done

poDotDotPath	char	'..', 0

DOSPathOpCreateDir endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathEnsurePathNotTooLong
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the directory about to be created (whose name
		is in dosNativeFFD.FFD_name) will actually be reachable.

CALLED BY:	DOSPathOpCreateDir
PASS:		DOS current dir set to directory in which dir will be
		created
RETURN:		carry set on error:
			ax	= ERROR_PATH_TOO_LONG
		carry clear if ok:
			ax	= destroyed
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 8/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathEnsurePathNotTooLong proc near
pathBuf		local	DOS_STD_PATH_LENGTH dup(char)
		uses	ds, dx, si, es, di, cx
		.enter
	;
	; Fetch the current path on the default (current) drive.
	; 
		lea	si, ss:[pathBuf]
		segmov	ds, ss
		mov	ah, MSDOS_GET_CURRENT_DIR
		clr	dl		; fetch from default drive
		call	DOSUtilInt21
	;
	; Find out how long it is.
	; 
		segmov	es, ds
		mov	di, si
		clr	al
		mov	cx, length pathBuf
		repne	scasb
	;
	; Now look for the null in dosNativeFFD.FFD_name, using the number of
	; bytes left in pathBuf as the number of bytes to search through
	; in FFD_name. If we don't see the null in that many bytes, the
	; path is too long and we return an error.
	; 
		jcxz	tooLong
		segmov	es, dgroup, si
if _MSLF
		mov	di, offset dos7FindData.W32FD_fileName
else
		mov	di, offset dosNativeFFD.FFD_name
endif
		repne	scasb
		je	done		; (carry cleared by == comparison)

tooLong:
		mov	ax, ERROR_PATH_TOO_LONG
		stc
done:
		.leave
		ret
DOSPathEnsurePathNotTooLong endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathCreateDirectoryFileCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine to create the DIRNAME.000 file

CALLED BY:	DOSPathOpCreateDir, DOSLinkCreateDirectoryFile

PASS:		ds - dgroup
		es:si - DiskDesc

RETURN:		if error:
			carry set
			ax - FileError
		else
			carry clear
			al - SFN

DESTROYED:	di,cx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 1/92   	copied out from calling procedures

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathCreateDirectoryFileCommon	proc far

		.enter
	;
	; Copy the name of our special file into dosNativeFFD for
	; DOSCreateNativeFile to use
	; 
		push	es, si
		segmov	es, ds
if _MSLF
		mov	di, offset dos7FindData.W32FD_fileName
else
		mov	di, offset dosNativeFFD.FFD_name
endif
			CheckHack <(segment dirNameFile) eq idata>
   		mov	si, offset dirNameFile
		mov	cx, length dirNameFile
		rep	movsb		; cl is zero after this
		pop	es, si
	;
	; Create the thing
	; 
		mov	al, FileAccessFlags <FE_DENY_WRITE, FA_READ_WRITE>
		call	DOSCreateNativeFile
	;
	; Zero out the DFE_disk of the private data slot just allocated so
	; we don't try and flush or otherwise examine this slot once the file
	; is closed.
	; 
		pushf
		tst	dx
		jz	noPrivateData
		mov	di, dx
		mov	ds:[di].DFE_disk, 0	
;do we need this too? - brianc 7/16/93
;		mov	ds:[di].DFE_flags, 0	
noPrivateData:
		popf
		.leave
		ret
DOSPathCreateDirectoryFileCommon	endp

PathOps		ends

PathOpsRare	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCheckDirInUse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the passed directory is in use by any
		thread in the system.
		
		XXX: still a race condition, despite the use of this function.

CALLED BY:	DOSPathOpDeleteDir
PASS:		ds:dx	= directory to be checked
		si	= disk handle on which directory resides
		es	= FSIR
		CWD lock grabbed
		FSIR locked exclusive
RETURN:		carry set if path is in use or couldn't be mapped:
			ax	= ERROR_IS_CURRENT_DIRECTORY
				= ERROR_PATH_NOT_FOUND
		carry clear if path is ok:
			ax	= destroyed
		ds	= dgroup
		mapped path stored in dosNativeFFD.FFD_name
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCheckDirInUse proc	near
		uses	cx, bp, di
		.enter
	;
	; Map the thing to its DOS equivalent.
	; 
		call	DOSVirtMapDirPath
		segmov	ds, dgroup, di		; ds <- dgroup, for return
		jc	done
		
	;
	; Fetch the identifier for the thing.
	; 
		mov	bp, si		; bp <- disk handle for path
		GetIDFromDTA	ds:[dosNativeFFD], cx, dx
	;
	; Enumerate all the paths in the system. 
	; 
		mov	di, SEGMENT_CS
		mov	si, offset DCDIU_callback
		call	FileForEachPath
		
		mov	si, bp		; si <- disk handle again
done:
		.leave
		ret
DOSCheckDirInUse endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DCDIU_callback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback function to determine if a path is in-use.

CALLED BY:	DOSCheckDirInUse via FileForEachPath
PASS:		di	= disk handle of path to process
		bx	= memory handle of path to process
		ds	= kdata
		cxdx	= ID for the path that will be nuked
		bp	= handle for disk on which endangered path lies
RETURN:		carry set if passed path is the one for which we are
			looking:
			ax	= ERROR_IS_CURRENT_DIRECTORY
		carry clear if not
DESTROYED:	ax, di, si, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DCDIU_callback	proc	far
		uses	ds
		.enter
	;
	; Make sure the path is on the same disk.
	; XXX: what about std path cruft?
	; 
		cmp	di, bp
		clc
		jne	done
	;
	; Preserve passed ID and determine the ID for this path (ignore drive
	; specifier in private data).
	; 
		push	cx, dx
		call	MemLock
		mov	ds, ax
		mov	si, offset FP_private+2
		call	DOSFileChangeCalculateID
		call	MemUnlock
		movdw	sidi, cxdx	; sidi <- ^hbx's ID
		pop	cx, dx
	;
	; Check path block's ID against the one we were given.
	; 
		cmp	cx, si
		je	checkLow
noMatch:
		clc
done:
		.leave
		ret
checkLow:
		cmp	dx, di
		jne	noMatch
	;
	; Matches, so return an error.
	; 
		stc
		mov	ax, ERROR_IS_CURRENT_DIRECTORY
		jmp	done
DCDIU_callback	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOpDeleteDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the directory whose path is passed

CALLED BY:	DOSPathOp
PASS:		ds:dx	= directory to delete
		CWD sem snagged
		FSIR locked exclusive
RETURN:		carry set on error:
			ax	= error code
		carry clear on happiness
DESTROYED:	ds, dx (saved by DOSPathOp), di (always nukable)

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpDeleteDir proc	far
disk		local	word		push si
dta		local	FileFindDTA
searchPattern	local	4 dup (char)
foundSpecial	local	byte		; flag so we know if we need to
					;  delete the special file (might not
					;  exist...)
		uses	es, cx
		.enter
	;
	; See if the directory is in use by some other thread. We downgrade
	; the exclusive lock on the FSIR (which was added by the
	; FSDUpgradeSharedInfoLock in DOSPathOp) once that check is complete,
	; as we're safely past the FileForEachPath that needs exclusive
	; access -- ardeb 4/11/96
	;
		call	DOSCheckDirInUse
		call	FSDDowngradeExclInfoLock
		jc	done

		mov	ss:[foundSpecial], 0
	;
	; Set search pattern to *.*
	; 
		mov	{word}ss:[searchPattern][0], '*' or ('.' shl 8)
		mov	{word}ss:[searchPattern][2], '*' or (0 shl 8)
	;
	; This is more complex than for a normal DOS program, as we have to
	; see if there are any files *other than our own special one* in
	; the directory before we delete the special file and the directory
	; itself.
	;
	; Switch into the directory itself.
	; 
		mov	dx, offset dosNativeFFD.FFD_name
		call	DOSInternalSetDir
		jc	done
		
		segmov	es, <segment dirNameFile>, di
		
		mov	ah, MSDOS_FIND_FIRST
		segmov	ds, ss
scanLoop:
		mov	di, offset dirNameFile
if GSDOS
	;
	; GSDOS search uses a JFT slot, so lets make sure that there is an
	; empty slot before we make the call. Since we don't have a SFN we'll
	; just pass it as NIL
	;
		push	bx
		mov	bx, NIL
		call	DOSAllocDosHandleFar
		pop	bx
endif	;GSDOS
	;
	; Snag BIOS lock so we can set the DTA w/o worry, then do that.
	; 
		call	SysLockBIOS
		push	ax			; save DOS call to use
		lea	dx, ss:[dta]
		mov	ah, MSDOS_SET_DTA
		call	DOSUtilInt21
		pop	ax
	;
	; Enumerate *all* files, including hidden and system ones
	;
		
		lea	dx, ss:[searchPattern]
		mov	cx, mask FA_HIDDEN or mask FA_SYSTEM or mask FA_SUBDIR
		call	DOSUtilInt21
		call	SysUnlockBIOS
if GSDOS
		pushf
		push	bx
		mov	bx, NIL
		call	DOSFreeDosHandleFar
		pop	bx
		popf
endif	;GSDOS
		
		jc	scanComplete
		mov	ah, MSDOS_FIND_NEXT
	;
	; If entry is bogus (q.v. DOSEnum) or '.' or '..', then it doesn't
	; count.
	; 
		mov	al, ss:[dta].FFD_name[0]
		cmp	al, '.'
		je	scanLoop
		tst	al
		jz	scanLoop
		cmp	al, es:[di]
		jne	notEmpty	; => not ., .. or special file, so
					;  directory not empty
	;
	; First char matches first char of dirNameFile, so see if it matches
	; in its entirety.
	; 
		lea	si, ss:[dta].FFD_name
checkLoop:
		lodsb
		scasb
		jne	notEmpty	; mismatch => directory contains
					;  files, so fail
		tst	al		; end of name?
		jnz	checkLoop	; no -- keep checking
	;
	; Flag special file found (i.e. it must be nuked) and keep searching.
	; 
		mov	ss:[foundSpecial], TRUE
		jmp	scanLoop

dotDotPath	char	'..', 0

notEmpty:
		mov	ax, ERROR_DIRECTORY_NOT_EMPTY
error:
		stc
done:
if GSDOS
		push	ax
		mov	al, ss:[dta].FFD_drive
		call	DOSClearJFTEntry
		pop	ax
endif	; GSDOS
		mov	si, ss:[disk]
		.leave
		ret
scanComplete:
	;
	; Went through the whole directory without finding anything but
	; ., .., or @DIRNAME.000, so now we have to check for links. Performing
	; a DOSLinkFindFirst (after opening the @DIRNAME.000 file, of course)
	; is sufficient for this test.
	; 
		mov	al, FA_READ_ONLY
		call	DOSLinkOpenDirectoryFile	; bx <- file
		jc	checkReadOnly
		
			CheckHack <(segment dirNameFile eq idata) and \
				   (segment mapLink eq udata)>
		mov	di, offset mapLink
		call	DOSLinkFindFirstFar
		pushf
		call	DOSLinkCloseDirectoryFile
		popf
		jnc	notEmpty	; => there's a link, so can't nuke

checkReadOnly:
	;
	; Check for directory being read-only before we nuke the @DIRNAME.000
	; file, as once it's gone, we can't recover it if there's some error
	; deleting the directory. This probably won't catch all cases, but it'll
	; catch most of them. -- ardeb 3/16/93
	; 
		test	es:[dosNativeFFD].FFD_attributes, mask FA_RDONLY
		jz	okToDelete
		mov	ax, ERROR_ACCESS_DENIED
		jmp	error

okToDelete:
	;
	; Went through the whole directory without finding anything but
	; ., .., or @DIRNAME.000, so we are allowed to biff the directory,
	; after we've deleted @DIRNAME.000, if it was there.
	; 
		tst	ss:[foundSpecial]
		jz	nukeDir
		
		mov	dx, offset dirNameFile
		segmov	ds, es
		mov	ah, MSDOS_DELETE_FILE
		call	DOSUtilInt21
		jc	done
nukeDir:
	;
	; Go back to the parent directory so we can nuke the directory itself.
	; 
		segmov	ds, cs
		mov	dx, offset cs:dotDotPath
FXIP<		push	cx						>
FXIP<		clr	cx						>
FXIP<		call	SysCopyToStackDSDX				>
FXIP<		pop	cx						>
		call	DOSInternalSetDir
FXIP<		call	SysRemoveFromStack				>
	;
	; Now nuke the directory, whose name is, of course, in
	; dosNativeFFD.FFD_name.
	; 
		call	PathOpsRare_LoadVarSegDS
		mov	dx, offset dosNativeFFD.FFD_name
		mov	ah, MSDOS_DELETE_DIR
		call	DOSUtilInt21
	;
	; Send out notification
	; 
		jc	done
		mov	ax, FCNT_DELETE
		mov	si, ss:[disk]
		call	DOSFileChangeGenerateNotifyForNativeFFD	; clears carry
		jmp	done

DOSPathOpDeleteDir endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathCheckExactMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the filename stored at *dosFinalComponent
		matches the mapped-to-DOS version.  If carry
		is returned SET, then callers will be able to avoid
		creating a DIRNAME.000 file, as the DOS name matches
		the GEOS name EXACTLY.  Note that returning carry
		clear erroneously (ie, false negative) is OK -- it
		just means that a redundant dirname file will be created.
		The purpose of this routine is simply to avoid
		creating some (or most) dirname.000 files.

CALLED BY:	DOSPathRenameGeosFile, DOSPathOpCreateDir

PASS:		ds - dgroup

RETURN:		carry SET if match, carry clear otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Any characters that are high ASCII automatically
		signal a mismatch -- this may in fact be a false negative.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/28/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathCheckExactMatch	proc far

		uses	si,es,di,ax
		.enter

		les	di, ds:[dosFinalComponent]
if _MSLF
		mov	si, offset dos7FindData.W32FD_fileName
else
		mov	si, offset dosNativeFFD.FFD_name
endif
compareLoop:
		LocalGetChar	ax, dssi

		LocalCmpChar	ax, 0x80
		jae	done		; carry is clear
	;
	; Can use scasb here, because even with SJIS DOS, ASCII		
	; characters below 0x80 are all single-byte.
	;
		scasb
		clc
		jne	done

		LocalIsNull	ax
		stc
		jnz	compareLoop
done:
		
		.leave
		ret
DOSPathCheckExactMatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathRenameGeosFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Give the destination of a FSPOF_MOVE_FILE or
		FSPOF_RENAME_FILE its proper new pc/geos long name.

CALLED BY:	DOSPathOpMoveFile, DOSPathOpRenameFile
PASS:		es 	= dgroup
		al	= source attributes
		ah	= GeosFileType
		si	= disk handle, in case dirname file needs to
			  be created.  (Only passed by
			  DOSPathOpRenameFile, since DOSPathOpMoveFile
			  can't be used with directories)

		dosFinalComponent = set to new longname
		dosFinalComponentLength = set to length of same w/o null
RETURN:		carry set if rename couldn't be accomplished
DESTROYED:	ax, dx, di, si, ds, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathRenameGeosFile proc	near
		uses	bx, cx
		.enter
	;
	; Allocate a slot in the JFT for us to use.
	; 
		mov	bx, NIL
		call	DOSAllocDosHandleFar
		
	;
	; Now attempt to open the destination name for writing only.
	; 
		segmov	ds, es			; dgroup
		test	al, mask FA_SUBDIR
		jz	openDestFile
	;
	; Destination is actually a directory -- so open the
	; directory-name file.
	;
		mov	dx, offset dosNativeFFD
		mov	al, FA_WRITE_ONLY
		call	DOSVirtOpenSpecialDirectoryFile
		jnc	fileOpen
		
	;
	; If the special directory file doesn't exist, then create it,
	; unless the filename we were given matches the DOS name exactly.
	;
		call	DOSPathCheckExactMatch
		cmc
		jnc	failFreeJFTSlot
	;
	; Create the directory file
	;
		call	DOSVirtCreateDirectoryFile
		jc	failFreeJFTSlot
		jmp	fileOpen
		
openDestFile:
		mov	dx, offset dosNativeFFD.FFD_name
		mov_tr	cx, ax			; save file type
		mov	al, FA_WRITE_ONLY
		call	DOSUtilOpenFar
		jc	failFreeJFTSlot
fileOpen:
		mov_tr	bx, ax		; bx <- file handle
	;
	; Position the file at the start of the longname, depending on the
	; version of the header in use in the file...
	; 
		mov	dx, offset GFHO_longName	; assume 1.X
		cmp	ch, GFT_OLD_VM
		je	positionAndWrite
		mov	dx, offset GFH_longName
positionAndWrite:
		clr	cx
		mov	ax, (MSDOS_POS_FILE shl 8) or FILE_POS_START
		call	DOSUtilInt21

	;
	; Point to the longname, which is null-terminated, and write it to
	; the file. 
	; 
		mov	cx, ds:[dosFinalComponentLength]
		lds	dx, ds:[dosFinalComponent]
		inc	cx			; Include NULL
DBCS <		shl	cx, 1			; cx <- # of bytes	>
		mov	ah, MSDOS_WRITE_FILE
		call	DOSUtilInt21
	;
	; Close the file again, being careful to save any error flag & code
	; from the write.
	; 
		pushf
		push	ax
		mov	ah, MSDOS_CLOSE_FILE
		call	DOSUtilInt21
		pop	ax
		popf

failFreeJFTSlot:
		mov	bx, NIL		; release the JFT slot (already nilled
					;  out by DOS itself during the close)
		call	DOSFreeDosHandleFar
done::
		.leave
		ret
DOSPathRenameGeosFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOpMoveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fun-filled function for frappeing files

CALLED BY:	DOSPathOp
PASS:		ds	= dgroup
		ss:bx	= FSMoveFileData
		cx	= dest disk handle (same disk as source)
		source name mapped and not-in-use; dos name in dosNativeFFD
		CWD lock grabbed

		For _MSLF:
		source name mapped in dos7FindData also.

RETURN:		carry set on error:
			ax	= error code
		carry clear on success
DESTROYED:	ds, dx (saved by DOSPathOp), di (always nukable)

PSEUDO CODE/STRATEGY:
		- map src to DOS name & ensure not in-use (bail if map fails)
		- bail if file is read-only
		- bail if file is a directory
		- get full pathname of the file, using GET_CURRENT_DIR
		  call & copy from dosNativeFFD.FFD_name
		- switch back to thread's directory
		- map destination as file
			- if successful, then bail (dest exists)
			- if fail and error not ERROR_FILE_NOT_FOUND, return
			  error
		- if src is geos file:
			- create unique dos name for dest in
			  dosNativeFFD.FFD_name
		- rename src to dosNativeFFD.FFD_name (contains dest in DOS
		  character set if not geos file)
		- if src is geos file
			- open dest for writing & write partial header
			  containing signature and new longname, then close

		This is very similar to rename, except the new name in this
		case is a full path, so after mapping the source we need to
		switch back to the thread's working directory so the mapping
		of the destination is appropriate. Also, the source cannot
		be a directory, owing to limitations in DOS.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpMoveFile proc far
diskHandle	local	word	push si

if SEND_DOCUMENT_FCN_ONLY
destDiskHandle	local	word	push cx
endif

if _MSLF
srcPath		local	MSDOS7PathName
else
srcPath		local	DOS_STD_PATH_LENGTH+DOS_DOT_FILE_NAME_LENGTH+2 dup(char)
endif

	; the story here is that this used to be just DOS_STD_PATH_LENGTH, but
	; it seems a file can be created in a directory that is at its path's
	; limit.  Because of this, when this file is moved, its path is renamed
	; to the new path, but the old path plus filename is greater than this
	; buffer can handle, given that the path without the file is at the
	; limit.  So we make this buffer large enough to hold the longest path,
	; and then add on room for a filename that is potentially 8.3 characters
	; plus a separator and a null.
	; 	dlitwin and tony  6/17/93

srcFinalComponent local nptr.char
srcAttrs	local	FileAttrs
srcFileType	local	GeosFileType
		uses	es, cx
		.enter
	;
	; bail if file is read-only
	; 
		mov	ax, ERROR_ACCESS_DENIED
if _MSLF
		test	ds:[dos7FindData].W32FD_fileAttrs.low.low, \
				mask FA_RDONLY
else
		test	ds:[dosNativeFFD].FFD_attributes, mask FA_RDONLY
endif
		LONG jnz	fail
	;
	; bail if "file" is directory, since MSDOS_RENAME_FILE will only
	; work to rename a directory in its same parent directory, not to
	; move it about the filesystem. WHY IS THIS? Grrrr...
	; 
		mov	ax, ERROR_CANNOT_MOVE_DIRECTORY
if _MSLF
		test	ds:[dos7FindData].W32FD_fileAttrs.low.low, \
				mask FA_SUBDIR
else
		test	ds:[dosNativeFFD].FFD_attributes, mask FA_SUBDIR
endif
		LONG jnz	fail

	;
	; get full pathname of the file, using MSDOS_GET_CURRENT_DIR call
	; and copy from dosNativeFFD.FFD_name.
	; 
		push	ds
		segmov	ds, ss
		mov	ss:[srcPath], '\\'	; MSDOS_GET_CURRENT_DIR doesn't
						;  give us this, so put it in
		lea	si, ss:[srcPath][1]	;  ourselves and have it start
						;  1 char into the buffer.
		clr	dl			; get path from default drive
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	DOSUtilInt21
		pop	ds
		push	es, cx			; save dest disk
		segmov	es, ss
		lea	di, ss:[srcPath]
		clr	al
		mov	cx, size srcPath
		repne	scasb
		dec	di			; point to last char
		dec	di
		mov	al, '\\'
		scasb
		je	srcSeparatorAdded
		stosb
srcSeparatorAdded:
if _MSLF
		mov	si, offset dos7FindData.W32FD_fileName
else
		mov	si, offset dosNativeFFD.FFD_name
		cmp	cx, size FFD_name
		jle	copyNativeFFD
		mov	cx, size FFD_name
copyNativeFFD:
endif
		mov	ss:[srcFinalComponent], di
		rep	movsb
if _MSLF
		mov	al, ds:[dos7FindData].W32FD_fileAttrs.low.low
else
		mov	al, ds:[dosNativeFFD].FFD_attributes
endif
		mov	ss:[srcAttrs], al
	;
	; If mapping didn't reveal the thing as having a pc/geos name in
	; addition to its native name, we need to check for ourselves. Sigh.
	; 
		test	al, FA_GEOS_FILE
		mov	ax, ds:[dosFileType]
		jnz	mapDestName
		
		segmov	es, ds
		mov	si, offset dosOpenHeader
if DBCS_PCGEOS
		mov	cx, size dosOpenHeader + size dosOpenType + \
							size dosOpenFlags
else
		mov	cx, size dosOpenHeader + size dosOpenType
endif
		mov	dx, offset dosNativeFFD
		call	DOSVirtOpenGeosFileForHeader
		jc	mapDestName
		
		ornf	ss:[srcAttrs], FA_GEOS_FILE
		mov	ax, ds:[dosOpenType]
mapDestName:
		mov	ss:[srcFileType], ax
	;
	; Switch back to thread's directory.
	; 
		pop	es, si			; es:si <- dest DiskDesc
		lds	dx, ss:[bx].FMFD_dest	; ds:dx <- dest name
		call	DOSEstablishCWDLow

EC <		ERROR_C	GASP_CHOKE_WHEEZE	; was established before, so...>
	;
	; Map destination as file.
	; 
		call	DOSVirtMapFilePath
		jc	checkDestMapError
		mov	ax, ERROR_FILE_EXISTS
fail:
		stc
		jmp	done

checkDestMapError:
		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	fail
	;
	; Now in destination directory with DOS name, if dest was valid DOS
	; name, in dosNativeFFD.FFD_name.
	;
	; Fetch the DOS version of the dest dir into dosPathBuffer before
	; we possibly mess it up manipulating the @DIRNAME.000 file.
	;
		segmov	ds, dgroup, si
		mov	si, offset dosPathBuffer
		clr	dl				; default drive
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	DOSUtilInt21
	;
	; If src is geos file, create unique dos name for dest in
	; dosNativeFFD.FFD_name
	; 
		test	ss:[srcAttrs], FA_GEOS_FILE
		jz	srcNotGeosFile
		
	;
	; Special case for moving executables:
	; 	in order to maintain the .geo suffix of executables as
	; 	they're moved around the system (as required by various
	; 	recalcitrant pieces of our system), when moving a geos
	; 	file, attempt to re-use the source file's own DOS name in
	; 	the new directory if the source file's extension isn't
	; 	numeric...
	;
	; 	why generate a new name if the extension is numeric? because
	;	the destination longname could well be different from the
	;	source longname and we need the DOS name of the dest to match
	;	the first 8 chars of the dest longname. If the extension isn't
	;	numeric, the DOS name doesn't matter.
	; 
		segmov	es, ss
		mov	di, ss:[srcFinalComponent]
		mov	al, '.'
		mov	cx, size FileDosName
		repne	scasb			; locate extension
		je	tryUseSrcName		; => no extension (!)
						; else es:di = start of ext.
		call	DOSVirtCheckNumericExtension
		jc	generateDosName		; => extension numeric, so
						;  generate new name
tryUseSrcName:
	;
	; Extension not numeric. See if src DOS name already exists in dest dir.
	; 
		segmov	ds, ss
		mov	dx, ss:[srcFinalComponent]
		mov	ax, (MSDOS_GET_SET_ATTRIBUTES shl 8) or 0 ; get attrs
		call	DOSUtilInt21
		jnc	generateDosName	; => src name exists, so generate new
	;
	; Src name doesn't exist, so copy it into dosNativeFFD.FFD_name
	; to be used for the rename.
	; 
		mov	si, dx			; ds:si <- name to copy
		segmov	es, dgroup, di
		mov	di, offset dosNativeFFD.FFD_name
		mov	cx, size FFD_name
		rep	movsb
if _MSLF
		jmp	copyToFindData
else
		jmp	doRename
endif

generateDosName:
		call	DOSVirtGenerateDosName
if _MSLF
copyToFindData:
	;
	; Copy the filename from dosNativeFFD.FFD_name to
	; dos7FindData.W32FD_fileName, to be passed to MSDOS7F_RENAME_FILE.
	;
		call	DOSUtilCopyFilenameFFDToFindData
endif
		jmp	doRename

srcNotGeosFile:
	;
	; Src is DOS file, so ensure destination name was a valid DOS name
	; (first char of dosNativeFFD.FFD_name is 0 if not).
	; 
		call	PathOpsRare_LoadVarSegDS
		mov	ax, ERROR_INVALID_NAME
if _MSLF
		tst	ds:[dos7FindData].W32FD_fileName[0]
else
		tst	ds:[dosNativeFFD].FFD_name[0]
endif
		jz	fail
doRename:
	;
	; srcPath contains the absolute path of the source file, and
	; dosNativeFFD.FFD_name contains the name to use for the new
	; destination. Now we just need to use the MSDOS_RENAME_FILE function
	; to move the beast.
	; 
		segmov	es, dgroup, di
if _MSLF
		mov	di, offset dos7FindData.W32FD_fileName
else
		mov	di, offset dosNativeFFD.FFD_name
endif
		segmov	ds, ss
		lea	dx, ss:[srcPath]
if _MSLF
		mov	ax, MSDOS7F_RENAME_FILE
else
		mov	ah, MSDOS_RENAME_FILE
endif
		call	DOSUtilInt21
		jc	done

	;
	; If the source is a geos file, open it for writing and adjust its
	; longname appropriately.
	; 
		mov	al, ss:[srcAttrs]
		test	al, FA_GEOS_FILE
		jz	generateNotify

		mov	ah, ss:[srcFileType].low
		call	DOSPathRenameGeosFile
		jnc	generateNotify
	;
	; Writing of new long name failed, so move the darn thing back again.
	; 
		push	ax
if _MSLF
		mov	dx, offset dos7FindData.W32FD_fileName
else
		mov	dx, offset dosNativeFFD.FFD_name
endif
		segmov	es, ss
		lea	di, ss:[srcPath]
		mov	ah, MSDOS_RENAME_FILE
		call	DOSUtilInt21
		pop	ax
		stc
done:
		mov	si, ss:[diskHandle]		; restore disk, in case
		.leave
		ret

generateNotify:
	;
	; First generate FCNT_DELETE notification for the source
	; 
		push	ds
		segmov	ds, ss
		lea	si, ss:[srcPath]
if SEND_DOCUMENT_FCN_ONLY
		mov	ax, ss:[diskHandle]
		Assert	dgroup, es
		cmp	ax, es:[sysDiskHandle]
		jne	sendDelNotif
		call	DOSFileChangeCheckIfPathLikelyHasDoc
		jnc	sendDelNotif
		pop	ds
		jmp	afterDelNotif
sendDelNotif:
endif	; SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeCalculateID	; cxdx <- ID
		pop	ds
		mov	si, ss:[diskHandle]		; si <- disk handle
		mov	ax, FCNT_DELETE
		call	FSDGenerateNotify
afterDelNotif::
	;
	; Now generate notification for creating the dest.
	; 
		mov	ax, FCNT_CREATE
if SEND_DOCUMENT_FCN_ONLY
		mov	si, ss:[destDiskHandle]
endif	; SEND_DOCUMENT_FCN_ONLY
		call	DOSFileChangeGenerateNotifyWithName	; clears carry
		jmp	done
DOSPathOpMoveFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOpRenameFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rename a file or directory.  Does NOT move files

CALLED BY:	DOSPathOp
PASS: 		source name mapped and not-in-use; dos name in dosNativeFFD
		ds	= dgroup
		es:di	= name to which to rename it
		si	= disk handle
		CWD lock grabbed

		For _MSLF:
		source name mapped in dos7FindData also.

RETURN:		carry set on error:
			ax	= error code
		carry clear on success
DESTROYED:	ds, dx (saved by DOSPathOp), di (always nukable)

PSEUDO CODE/STRATEGY:
		- bail if file is read-only
		- DOS2: bail if file is directory
		- copy src DOS name from dosNativeFFD.FFD_name
		- map destination as file
			- if successful, then bail (dest exists)
		- if src is geos file:
			- create unique dos name for dest in
			  dosNativeFFD.FFD_name
		- rename src to dosNativeFFD.FFD_name (contains dest in DOS
		  character set if not geos file)
		- if src is geos file
			- open dest for writing & write partial header
			  containing signature and new longname, then close
			- if src is directory, dest to open is dirNameFile
			  inside renamed directory

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpRenameFile proc far

diskHandle	local	word	push	si
if _MSLF
srcName		local	MSDOS7PathName
else
srcName		local	DOS_DOT_FILE_NAME_LENGTH_ZT dup(char)
endif
srcAttrs	local	FileAttrs
srcFileType	local	GeosFileType
		uses	es, si, cx
		.enter
	;
	; bail if file is read-only
	; 
		mov	ax, ERROR_ACCESS_DENIED
if _MSLF
		test	ds:[dos7FindData].W32FD_fileAttrs.low.low, \
				mask FA_RDONLY
else
		test	ds:[dosNativeFFD].FFD_attributes, mask FA_RDONLY
endif
		jnz	fail
	;
	; DOS2: CAN WE USE RENAME FUNCTION ON A DIRECTORY?
	; 

	;
	; Copy the DOS name of the source from dosNativeFFD.FFD_name to our
	; buffer.
	; 
		push	es, di
if _MSLF
		mov	si, offset dos7FindData.W32FD_fileName
else
		mov	si, offset dosNativeFFD.FFD_name
endif
		lea	di, ss:[srcName]
		segmov	es, ss
		mov	cx, length srcName
		rep	movsb
if _MSLF
		mov	al, ds:[dos7FindData].W32FD_fileAttrs.low.low
else
		mov	al, ds:[dosNativeFFD].FFD_attributes
endif
	;
	; If the thing is a subdirectory, then we always want to treat
	; it as a GEOS file
	;
		test	al, mask FA_SUBDIR
		jz	storeAttrs
		ornf	al, FA_GEOS_FILE
storeAttrs:
		mov	ss:[srcAttrs], al
	;
	; If mapping didn't reveal the thing as having a pc/geos name in
	; addition to its native name, we need to check for ourselves. Sigh.
	; 
		test	al, FA_GEOS_FILE
		mov	ax, ds:[dosFileType]
		jnz	mapDestName
		
		segmov	es, ds
		mov	si, offset dosOpenHeader
if DBCS_PCGEOS
		mov	cx, size dosOpenHeader + size dosOpenType + \
							size dosOpenFlags
else
		mov	cx, size dosOpenHeader + size dosOpenType
endif
		mov	dx, offset dosNativeFFD
		call	DOSVirtOpenGeosFileForHeader
		jc	mapDestName
		
		ornf	ss:[srcAttrs], FA_GEOS_FILE
		mov	ax, ds:[dosOpenType]
mapDestName:
		mov	ss:[srcFileType], ax
	;
	; Now attempt to map the destination name (in the current dir) to
	; see if it already exists, and to see if the destination is a valid
	; DOS name, should the source be a DOS file.
	; 
		pop	ds, dx
		call	DOSVirtMapFilePath
		jc	checkDestMapError
	;
	; 2/10/93: if the file is a geos file and the source and dest files
	; are the same, just go to the part that changes the geos name, as
	; we might well just be changing the case of a directory with a valid
	; DOS name. XXX: this allows renaming a file to its current name to
	; succeed for GEOS files, but not for DOS files.
	; 
		test	ss:[srcAttrs], FA_GEOS_FILE
		jz	destExists		; no excuse if not geos file

		call	PathOpsRare_LoadVarSegDS
		segmov	es, ss
		lea	si, ds:[dosNativeFFD].FFD_name
		lea	di, ss:[srcName]
cmpSrcDestLoop:
		lodsb
		scasb
		jne	destExists
		tst	al
		jnz	cmpSrcDestLoop
		segmov	es, ds			; es <- dgroup too
		jmp	renameGeosPart

destExists:
		mov	ax, ERROR_FILE_EXISTS
fail:
		stc
		jmp	done

checkDestMapError:
		cmp	ax, ERROR_FILE_NOT_FOUND
		jne	fail
	;
	; Now have DOS name for dest, if dest was valid DOS name, in
	; dosNativeFFD.FFD_name.
	;
	; If src is geos file, create unique dos name for dest in
	; dosNativeFFD.FFD_name
	;
	; 4/22/92: if the source is a geos file that's a directory, and the
	; destination name is a legal DOS name, use that as the destination
	; name, rather than generating one. maintains consistency with how
	; directories are created and thereby allows optimization in
	; DOSVirtMapPath for internal components -- ardeb
	; 
		call	PathOpsRare_LoadVarSegDS

		test	ss:[srcAttrs], FA_GEOS_FILE
		jz	srcNotGeosFile
		
		test	ss:[srcAttrs], mask FA_SUBDIR
		jz	generateNewGeosName
		
if _MSLF
		tst	ds:[dos7FindData].W32FD_fileName[0]
else
		tst	ds:[dosNativeFFD].FFD_name[0]
endif
		jnz	doRename		; => valid DOS name, so keep it

generateNewGeosName:
		call	DOSVirtGenerateDosName
if _MSLF
	;
	; Copy the filename from dosNativeFFD.FFD_name to
	; dos7FindData.W32FD_fileName, to be passed to MSDOS7F_RENAME_FILE.
	;
		call	DOSUtilCopyFilenameFFDToFindData
endif
		jmp	doRename

srcNotGeosFile:
	;
	; Src is DOS file, so ensure destination name was a valid DOS name
	; (first char of dosNativeFFD.FFD_name is 0 if not).
	; 
		mov	ax, ERROR_INVALID_NAME
if _MSLF
		tst	ds:[dos7FindData].W32FD_fileName[0]
else
		tst	ds:[dosNativeFFD].FFD_name[0]
endif
		jz	fail
doRename:
	;
	; srcName contains the name of the source file (in the current dir), and
	; dosNativeFFD.FFD_name contains the name to use for the new
	; destination. Now we just need to use the MSDOS_RENAME_FILE function
	; to rename the beast.
	; 
		segmov	es, ds
if _MSLF
		mov	di, offset dos7FindData.W32FD_fileName
else
		mov	di, offset dosNativeFFD.FFD_name
endif
		segmov	ds, ss
		lea	dx, ss:[srcName]
if _MSLF
		mov	ax, MSDOS7F_RENAME_FILE
else
		mov	ah, MSDOS_RENAME_FILE
endif
		call	DOSUtilInt21
		jc	fail

	;
	; If the source is a geos file, open it for writing and adjust its
	; longname appropriately.
	; 
renameGeosPart:
	;
	; Fetch ID for current path, before we possibly cd into a directory
	; to change the name in the @DIRNAME.000 file.
	; 
		call	DOSFileChangeGetCurPathID
		push	cx, dx

		mov	al, ss:[srcAttrs]	; al <- attrs for
						;  DOSPathRenameGeosFile
		test	al, FA_GEOS_FILE		; (clears carry)
		jz	generateNotify

if _MSLF
		test	al, mask FA_SUBDIR
		jz	afterGetAlias

	;
	; The thing we just renamed is a directory (either DOS or GEOS).
	; If dosNativeFFD.FFD_name is null at this point, it means that the
	; destination name didn't exist, it is a valid DOS long name, and
	; it is not a valid DOS short name.
	;
	; In this case, if the source dir was a GEOS dir, we want the
	; destination to remain a GEOS dir.  So we need to let
	; DOSPathRenameGeosFile do its work of changing the GEOS name stored
	; in @dirname.000.
	;
	; Unfortunately, DOSPathRenameGeosFile only works with dosNativeFFD.
	; So, we have to fill dosNativeFFD.FFD_name with the short name alias
	; generated by DOS just now when the dir was renamed.  We do this by
	; calling DOSVirtMapDirPath.  We do it here whether or not the dir
	; was a GEOS dir, and we let DOSPathRenameGeosFile to find out if the
	; dir was indeed a GEOS dir.
	;
		tst	es:[dosNativeFFD].FFD_name[0]
		jnz	afterGetAlias		; => already have name or alias

		segmov	ds, es			; ds = dgroup
		mov	dx, offset dos7FindData.W32FD_fileName
		call	DOSVirtMapDirPath	; dosNativeFFD.FFD_name filled
		Assert	carryClear		; error shouldn't happen.

afterGetAlias:
endif	; _MSLF

		mov	ah, ss:[srcFileType].low
		mov	si, ss:[diskHandle]
		call	DOSPathRenameGeosFile
generateNotify:
		pop	cx, dx
		jc	undo
	;
	; Start with ID for current directory and add ID for srcName
	; 
if SEND_DOCUMENT_FCN_ONLY
		mov	ax, ss:[diskHandle]
		Assert	dgroup, es
		cmp	ax, es:[sysDiskHandle]
		jne	sendNotif
		call	DOSFileChangeCheckIfCurPathLikelyHasDoc
		jc	afterNotif
sendNotif:
endif	; SEND_DOCUMENT_FCN_ONLY
		segmov	ds, ss
		lea	si, ss:[srcName]
		call	DOSFileChangeCalculateIDLow
		mov	si, ss:[diskHandle]
		push	bx
		mov	ax, FCNT_RENAME
		call	PathOpsRare_LoadVarSegDS
		lds	bx, ds:[dosFinalComponent]
		call	FSDGenerateNotify
		pop	bx
afterNotif::
		clc
		jmp	done
undo:
		pop	si			; si <- disk handle again
	;
	; Writing of new long name failed, so move the darn thing back again.
	; 
		push	ax
		mov	dx, offset dosNativeFFD.FFD_name
		segmov	es, ss
		lea	di, ss:[srcName]
		mov	ah, MSDOS_RENAME_FILE
		call	DOSUtilInt21
		pop	ax
		stc
done:
		.leave
		ret
DOSPathOpRenameFile endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCurPathGetID
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
DOSCurPathGetID proc	far
		uses	ds, ax, bx, si
		.enter
	;
	; Just use the absolute native path we stored in the private data to
	; calculate this directory's 32-bit ID.
	; 
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	ds, ax
		mov	si, offset FP_private + 2	; skip drive specifier
		call	DOSFileChangeCalculateID
		call	MemUnlock
		.leave
		ret
DOSCurPathGetID endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCurPathCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCurPathCopy proc	far
		.enter
		.leave
		ret
DOSCurPathCopy endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSCheckNetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSCheckNetPath proc	far
		.enter
		.leave
		ret
DOSCheckNetPath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathCheckMappedToEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the mapping made it to the end of the path before
		returning an error.

CALLED BY:	(INTERNAL) DOSPathErrorCheckLink, DOSPathOpCreateDir
PASS:		nothing
RETURN:		flags set so "je" will branch if mapped to the end
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/ 9/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathCheckMappedToEnd proc	far
SBCS <		uses	ds, es, di					>
DBCS <		uses	ax, ds, es, di					>
		.enter
		call	PathOpsRare_LoadVarSegDS
		les	di, ds:[dosFinalComponent]
SBCS <		add	di, ds:[dosFinalComponentLength]		>
DBCS <		mov	ax, ds:[dosFinalComponentLength]		>
DBCS <		shl	ax, 1						>
DBCS <		add	di, ax						>
SBCS <		cmp	{byte} es:[di], 0				>
DBCS <		cmp	{wchar} es:[di], 0				>
		.leave
		ret
DOSPathCheckMappedToEnd endp

PathOpsRare	ends

ExtAttrs	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathGetAllExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get all the extended attributes for a file given its
		path.  Deal with links, if necessary.

CALLED BY:	DOSPathOp

PASS:		ds:dx - filename
		es:si - DiskDesc

RETURN:		if attributes fetched:
			carry clear
			ax - handle of attribute data (locked)
			cx - # of attributes
		ELSE
			carry set
			ax - FileError

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathGetAllExtAttrs	proc far
		uses	es, di, dx
		.enter

		mov	cx, DVCT_FILE_OR_DIR
		call	DOSVirtMapFilePath
		jc	done
	;
	; It's a file -- build the buffer, and then call the common
	; routine. 
	;
		call	DOSVirtBuildBufferForAllAttrs
		jc	done

		clr	dx	; use path 
		mov	ax, FEA_MULTIPLE
		call	DOSVirtGetExtAttrs

		call	DOSVirtGetAllAttrsCommon
done:
		.leave
		ret
DOSPathGetAllExtAttrs	endp

ExtAttrs	ends

PathOps		segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some other operation on a file path that doesn't
		involve the allocation of a file handle.

		If the operation to be performed is destructive to the path
		on which it's to be performed, the FSD is responsible for
		ensuring the path is not actively in-use by any thread.

		For a directory, this means it is not in the path stack of
		any thread (XXX: this is something of a bitch when std paths
		are involved). For a file, no handle may be open to the file.

CALLED BY:	DR_FS_PATH_OP
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
			if ax = ERROR_LINK_ENCOUNTERED,
				bx = handle of link data
DESTROYED:	

PSEUDO CODE/STRATEGY:
    FSPOF_CREATE_DIR	enum	FSPathOpFunction
    FSPOF_DELETE_DIR	enum	FSPathOpFunction
    ;	Pass:	path-modification semaphore grabbed
    ;	Return:	nothing extra
    ;
    
    FSPOF_DELETE_FILE	enum	FSPathOpFunction

    FSPOF_RENAME_FILE	enum	FSPathOpFunction
    ;	Pass:	bx:cx	= new name (*not* path)
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
    
    FSPOF_SET_EXT_ATTRIBUTES enum FSPathOpFunction
    ;	Pass:	ss:bx	= FSPathExtAttrData
    ;		cx	= size of FPEAD_buffer, or # entries in same if
    ;			  FPEAD_attr is FEA_MULTIPLE
    ;	Return:	nothing extra
    

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	10/31/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOp	proc	far
		uses	ds, dx

paramBX		local	word	push	bx

ForceRef	paramBX		; used by DOSPathErrorCheckLink

		.enter

		push	bp
	;
	; HACK: to cope with FileForEachPath grabbing the FSIR exclusive while
	; we've got our internal cwdSem P'd, we need to grab the FSIR exclusive
	; before we go for the cwdSem. FileForEachPath is only called when
	; deleting a directory. -- ardeb 3/25/96
	; 
		cmp	ah, FSPOF_DELETE_DIR
		jne	establishCWD
		call	FSDUpgradeSharedInfoLock
establishCWD:
	;
	; Set our thread's directory into DOS
	; 
		call	DOSEstablishCWD
		jc	toDone

		mov	al, ah
		clr	ah
		shl	ax
		mov_tr	di, ax
		jmp	cs:[pathOpFunctions][di]
pathOpFunctions	nptr	createDir,	; FSPOF_CREATE_DIR
			deleteDir,	; FSPOF_DELETE_DIR
			deleteFile,	; FSPOF_DELETE_FILE
			renameFile,	; FSPOF_RENAME_FILE
			moveFile,	; FSPOF_MOVE_FILE
			getAttrs,	; FSPOF_GET_ATTRIBUTES
			setAttrs,	; FSPOF_SET_ATTRIBUTES
			getExtAttrs,	; FSPOF_GET_EXT_ATTRIBUTES
			getAllExtAttrs,	; FSPOF_GET_ALL_EXT_ATTRIBUTES
			setExtAttrs,	; FSPOF_SET_EXT_ATTRIBUTES
			mapVirtualName,	; FSPOF_MAP_VIRTUAL_NAME
			mapNativeName,	; FSPOF_MAP_NATIVE_NAME
			createLink,	; FSPOF_CREATE_LINK
			readLink,	; FSPOF_READ_LINK
			setLinkExtraData, ; FSPOF_SET_LINK_EXTRA_DATA
			getLinkExtraData, ; FSPOF_GET_LINK_EXTRA_DATA
			createDir   ; FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME
			
CheckHack <length pathOpFunctions eq FSPathOpFunction>

	;--------------------
createDir:
		call	DOSPathOpCreateDir
		jmp	done

	;--------------------
deleteDir:
		call	DOSPathOpDeleteDir
		jmp	done

	;--------------------
deleteFile:
		call	DOSCheckFileInUse
		jnc	deleteNative

	;
	; If an error occurred, it may be that the final component of
	; the mapped name was a link.  Check this condition, and
	; perform the desired file operation if so. DOSPathErrorCheckLink
	; unlocks the cwdSem in any case.
	;

		mov	di, DLPOF_DELETE
checkLink:
		call	DOSPathErrorCheckLink
		jmp	done

deleteNative:
		mov	ah, MSDOS_DELETE_FILE
		jmp	operateOnNativeName

	;--------------------
renameFile:
		call	DOSCheckFileInUse
		jnc	renameNative

		mov	di, DLPOF_RENAME
		jmp	checkLink

renameNative:
		push	es
		mov	es, bx
		mov	di, cx
		call	DOSPathOpRenameFile
		pop	es
toDone:
		jmp	done

	;--------------------
moveFile:
		mov	ax, ERROR_DIFFERENT_DEVICE
		cmp	cx, si			; same disk?
		stc
		jne	toDone		; no -- unsupported

		call	DOSCheckFileInUse
		jc	toDone

		call	DOSPathOpMoveFile
		jmp	done

	;--------------------
setAttrs:
		mov	ax, (MSDOS_GET_SET_ATTRIBUTES shl 8) or 1
		call	DOSCheckFileInUse
		jnc	operateOnNativeName

		mov	di, DLPOF_SET_ATTRS
		jmp	checkLink

	;- - - - - - - - - -
operateOnNativeName:
	;
	; Name has been properly mapped to its native equivalent in
	; dosNativeFFD.FFD_name, so perform whatever function is in AH on it.
	; 
		call	PathOps_LoadVarSegDS
		mov	dx, offset dosNativeFFD.FFD_name
		push	ax
		call	DOSUtilInt21
		pop	dx
		jc	done

		cmp	dh, MSDOS_GET_SET_ATTRIBUTES
		mov	ax, FCNT_ATTRIBUTES
		je	generateNotify
		mov	ax, FCNT_DELETE
generateNotify:
		call	DOSFileChangeGenerateNotifyForNativeFFD	; clears carry
		jmp	done

	;--------------------
getAttrs:
		call	DOSPathOpGetAttrs

		mov	di, DLPOF_GET_ATTRS
		jmp	checkLink

	;--------------------
getExtAttrs:
	;
	; Map virtual to native name first.
	; 
		call	DOSVirtMapFilePath
		jnc	getExtAttrsNative

		mov	di, DLPOF_GET_EXT_ATTRS
		jmp	checkLink
	;
	; Now call common code to fetch the attribute(s) desired.
	; 
getExtAttrsNative:
		push	es
		mov	ax, ss:[bx].FPEAD_attr
		les	di, ss:[bx].FPEAD_buffer
		clr	dx		; signal file not opened 
		call	DOSVirtGetExtAttrs
		pop	es
		jmp	done

	;--------------------
getAllExtAttrs:
		call	DOSPathGetAllExtAttrs
		mov	di, DLPOF_GET_ALL_EXT_ATTRS
		jmp	checkLink
	;--------------------
setExtAttrs:
	;
	; Make sure file isn't in-use; this maps the name, too
	; 
		call	DOSCheckFileInUse
		jnc	setExtAttrsNative

		mov	di, DLPOF_SET_EXT_ATTRS
		jmp	checkLink

	;
	; Now call common code to set the attribute(s) desired.
	; 
setExtAttrsNative:
		push	es
		mov	bp, bx
		mov	ax, ss:[bp].FPEAD_attr
		les	di, ss:[bp].FPEAD_buffer
		clr	dx		; signal names available
		call	DOSVirtSetExtAttrs
		pop	es
		.assert	$ eq done

	;- - - - - - - - - -
done:
		call	DOSUnlockCWD
		pop	bp

		.leave
		ret

	;--------------------
mapVirtualName:
	;
	; bx:cx = buffer in which to place DOS name
	; 
		call	DOSVirtMapFilePath
		jc	done
	;
	; Now fetch the current directory from DOS as the leading components
	; for the native version.
	; 
		push	si, es
		mov	ds, bx
		mov	si, cx
		mov	{char}ds:[si], '\\'	; DOS doesn't put this in for us
		inc	si
		clr	dl		; default drive
		mov	ah, MSDOS_GET_CURRENT_DIR
		call	DOSUtilInt21
	;
	; Locate the end of the returned path, as we need to tack on the
	; name in dosNativeFFD.
	; 
		mov	di, si
		segmov	es, ds
		clr	al
		mov	cx, -1
		repne	scasb
		dec	di		; point to char before null
		dec	di
		mov	al, '\\'
		scasb			; path sep already there?
		je	copyTail	; yes (di points to null)
		stosb			; no -- add one
copyTail:
	;
	; Path separator has been added, so now we need to copy the name
	; from the FFD_name field. Use a loop-until-null copy loop rather than
	; a straight movsb to cope with a short name at the end of a long path.
	; It wouldn't do to go past the bounds of the path buffer we were
	; given...
	; 
		call	PathOps_LoadVarSegDS
		mov	si, offset dosNativeFFD.FFD_name
copyTailLoop:
		lodsb
		stosb
		tst	al
		jnz	copyTailLoop
		pop	si, es
		jmp	done

	;--------------------
mapNativeName:
		push	si, es
		mov	si, dx
		mov	di, cx
		mov	es, bx
		mov	cx, DOS_STD_PATH_LENGTH
		call	DOSVirtMapDosToGeosName
		pop	si, es
		clc
		jmp	done

	;--------------------
createLink:
		call	DOSLinkCreateLink		
		jmp	done

	;--------------------
readLink:
		mov	di, DLPOF_READ
	;- - - - - - - - - -
linkOp:
	;
	; Map virtual to native name first.  If no error, then the
	; file is a regular file, not a link, so bail.
	; 
		call	DOSVirtMapFilePath
		jnc	notALink
		jmp	checkLink
notALink:
		mov	ax, ERROR_NOT_A_LINK
		stc
		jmp	done	
	;--------------------
setLinkExtraData:
		mov	di, DLPOF_SET_EXTRA_DATA
		jmp	linkOp
	;--------------------
getLinkExtraData:
		mov	di, DLPOF_GET_EXTRA_DATA
		jmp	linkOp

DOSPathOp	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathOpGetAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the FileAttrs, checking for weird cases, etc

CALLED BY:	DOSPathOp

PASS:		ds:dx - path to file

RETURN:		if error:
			carry set
			ax - FileError
		else
			carry clear
			cx - FileAttrs

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	moved into separate procedure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathOpGetAttrs	proc near
		.enter

		call	DOSVirtMapFilePath
		jc	done

	;
	; Get the attributes.  
	;

		mov	ax, (MSDOS_GET_SET_ATTRIBUTES shl 8) or 0
		call	PathOps_LoadVarSegDS
		cmp	ds:[dosNativeFFD].FFD_name, '.'
		je	hack		; cope with getting attributes for
					;  root directory, especially for
					;  things like CD ROM, which say
					;  that . doesn't exist in the root.
					;  -- ardeb 11/23/92

		mov	dx, offset dosNativeFFD.FFD_name
		call	DOSUtilInt21
		jnc	done

	;
	; If FILE_NOT_FOUND, see if the file is "..", and if so,
	; return some hacked value (filled in by
	; DOSVirtMapCheckDosName). 
	;

		cmp	ax, ERROR_FILE_NOT_FOUND
		stc
		jne	done

		push	es
		segmov	es, ds
		call	DOSVirtCheckParentDir
		pop	es
		stc
		jne	done
hack:
		clr	ch
		mov	cl, ds:[dosNativeFFD].FFD_attributes
done:
	;
	; Make sure that whatever version of DOS we're using didn't
	; randomly set the LINK bit!
	;

		pushf
		andnf	cx, not mask FA_LINK
		popf
		.leave
		ret
DOSPathOpGetAttrs	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DOSPathErrorCheckLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An error occurred.  If the error was
		ERROR_LINK_ENCOUNTERED, then see if we were at the end
		of the path being mapped, and if so, call the special
		link routine, as we actually want to operate on that
		link file.  If the link operation to be performed is
		DLPOF_READ_LINK, then just return the block of data

CALLED BY:	DOSPathOp

PASS:		carry set on error:
			ax	= FileError code
			di 	= DOSLinkPathOpFunction to call if final
				  component was a link
			si	= disk handle for operation
			bx - handle of link data to be freed
			dosFinalComponent contains pointer to link filename
		carry clear if ok

		ss:[passedBX] -- data passed to DOSPathOp

RETURN:		values returned from called procedure (address in DI)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/10/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DOSPathErrorCheckLink	proc near

		.enter	inherit	DOSPathOp

		jnc	done

		cmp	ax, ERROR_LINK_ENCOUNTERED
		stc
		jne	done

	;
	; See if dosFinalComponent was actually at the end of the path
	; being mapped.
	;
		call	DOSPathCheckMappedToEnd
		stc
		jne	done

	;
	; It was.  If the routine to call is DLPOF_READ, then just
	; return the data block (in BX).  Otherwise, free it, and call
	; the special links routine.
	;

		cmp	di, DLPOF_READ
		jne	callLinkOp
		clc
		mov	cx, bx		; handle of link data
		jmp	done
	;
	; Free the passed data block, and call the special link routine.
	;

callLinkOp:
		call	MemFree


		mov	ax, ss:[paramBX]
		mov	ss:[TPD_dataBX], ax
		movdw	bxax, cs:[linkOps][di]
		call	ProcCallFixedOrMovable

done:
		.leave
		ret


DefLinkOp	macro	func, num
.assert ($-linkOps) eq num, <Routine for num in the wrong slot>
.assert type func eq far
	fptr.far	func
		endm

linkOps		label	fptr.far
    DefLinkOp DOSLinkDeleteLink, 	DLPOF_DELETE
    DefLinkOp DOSLinkRenameLink, 	DLPOF_RENAME
    DefLinkOp DOSLinkSetAttrs, 		DLPOF_SET_ATTRS
    DefLinkOp DOSLinkGetAttrs, 		DLPOF_GET_ATTRS
    DefLinkOp DOSLinkGetExtAttrs,	DLPOF_GET_EXT_ATTRS
    DefLinkOp DOSLinkGetAllExtAttrs,	DLPOF_GET_ALL_EXT_ATTRS
    DefLinkOp DOSLinkSetExtAttrs,	DLPOF_SET_EXT_ATTRS
    DefLinkOp DOSLinkSetExtraData,	DLPOF_SET_EXTRA_DATA
    DefLinkOp DOSLinkGetExtraData,	DLPOF_GET_EXTRA_DATA
CheckHack <$-linkOps eq DOSLinkPathOpFunction>

DOSPathErrorCheckLink	endp




PathOps		ends
