COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		gfsPath.asm

AUTHOR:		Adam de Boor, Apr 14, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	4/14/93		Initial revision


DESCRIPTION:
	Functions that deal with paths.
		

	$Id: gfsPath.asm,v 1.1 97/04/18 11:46:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Movable	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSPathReadLastLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an FSPathLinkData block for the link whose name was
		just mapped.

CALLED BY:	(INTERNAL) GFSCurPathSet, GFSAllocOp, GFSPathOp
PASS:		ds	= dgroup
		gfsLastFound = set
RETURN:		^hbx	= FSPathLinkData, locked
DESTROYED:	di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSPathReadLastLink proc	near
		uses	es, si, cx, dx
		.enter
		segmov	es, ds
		mov	di, offset gfsLastFound
		mov	si, offset gfsNullPath	; ds:si <- null tail
		call	GFSMPReadLink		; ^hbx <- FSPathLinkData
		.leave
		ret
GFSPathReadLastLink endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCurPathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the thread's current working directory to be that
		passed in, if the directory actually exists. If the change
		is successful, the driver should add whatever private data
		it needs at FP_private and point FP_path beyond that data.

		Before doing so, the driver should call FSDInformOldFSDOfPath-
		Nukage to inform the previous filesystem driver for the path
		that it is losing control of the block, so it may clean up any
		state indicated by the private data it stored in the block.
		The only time it need not do this is when it, itself, is the
		previous driver and it has nothing to do on
		DR_FS_CUR_PATH_DELETE.

		Once this is done, the driver has free rein of the block
		following FP_private.

		It is the kernel's responsibility to copy in whatever
		logical path it sees fit to return to applications in
		light of the driver's success in setting the path.

		NOTE: THE PRIMARY FSD MUST BE ABLE TO ACCEPT CALLS TO
		THIS FUNCTION (AND DR_FS_CUR_PATH_DELETE) FOR DRIVES THAT
		IT DOES NOT MANAGE.

CALLED BY:	DR_FS_CUR_PATH_SET
PASS:		ds:dx	= path to set, w/o drive specifier (always absolute)
		es:si	= disk on which the path resides
RETURN:		carry clear if directory-change was successful:
			TPD_curPath block altered to hold the private data
			required by the FSD. The FSD may have resized the block.
			FP_pathInfo must be set to FS_NOT_STANDARD_PATH
			FP_stdPath must be set to SP_NOT_STANDARD_PATH
		carry set if error:
			Either the directory to which the thread was
			attempting to change doesn't exist:
				ax	= ERROR_PATH_NOT_FOUND
				TPD_curPath may not be altered in any
				way.

			OR: A link was encountered, which needs to be
			traversed by the kernel.
			    	ax	= ERROR_LINK_ENCOUNTERED
				bx	= handle of locked FSPathLinkData
					  block.
DESTROYED:	cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCurPathSet	proc	far
		uses	ds, es, bx
		.enter

if ERROR_CHECK
	;
	; Validate that the path is not in a movable code segment
	;
FXIP<	push	bx, si							>
FXIP<	mov	bx, ds							>
FXIP<	mov	si, dx							>
FXIP<	call	ECAssertValidFarPointerXIP				>
FXIP<	pop	bx, si							>
endif

	;
	; Gain exclusive access to the device.
	; 
if _PCMCIA
		mov	al, mask GDLF_DISK
else
		clr	al
endif
		call	GFSDevLock
	;
	; Map the path to its directory entry.
	; 
		call	GFSMapPath		; ds <- dgroup, too
		jc	bail
	;
	; Mapping successful. Make sure the final component is actually a
	; directory.
	; 
		mov	al, ds:[gfsLastFound].GDE_attrs
		test	al, mask FA_SUBDIR
		jnz	initPathBlock
	;
	; Not a directory. Perhaps a link?
	; 
		test	al, mask FA_LINK
		mov	ax, ERROR_PATH_NOT_FOUND
		jz	bail
	;
	; It's a link, so fetch the link data and return the error to the
	; kernel.
	; 
		call	GFSPathReadLastLink
		pop	ax		; discard passed BX
		push	bx		; and return our own
		mov	ax, ERROR_LINK_ENCOUNTERED
bail:
		stc
		jmp	unlock

initPathBlock:
	;
	; All systems are go. Make sure there's room in the block for our
	; private data. We only enlarge the block, never shrink it (don't
	; want to mess up other FSD's data).
	; 
		mov	bx, ss:[TPD_curPath]
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov	cx, size FilePath + size GFSPathPrivate
		cmp	ax, cx
		jae	informPrevFSD	; there's enough room
		
		mov_tr	ax, cx		; else resize to be just big enough
		push	ax
		clr	cx		; no special flags
		call	MemReAlloc
		pop	cx
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jc	unlock		; if couldn't enlarge, then couldn't
					;  change directory

informPrevFSD:
	;
	; Block is proper size, everything's happy, so tell the old FSD it's
	; our town now.
	; 
		call	FSDInformOldFSDOfPathNukage
	;
	; Set up the private data from our global variables.
	; 
		segmov	es, ds		; es <- dgroup
		call	MemLock
		mov	ds, ax
		mov	ds:[FP_path], cx; Store path after our private data
		
		movdw	({GFSPathPrivate}ds:[FP_private]).GPP_dirEnts, \
			es:[gfsLastFound].GDE_data, \
			ax
		mov	ax, es:[gfsLastFound].GDE_size.low
		mov	({GFSPathPrivate}ds:[FP_private]).GPP_size, ax
		movdw	({GFSPathPrivate}ds:[FP_private]).GPP_attrs, \
			es:[gfsLastFoundEA], \
			ax
	;
	; Perform the remaining pieces of initialization.
	; 
		mov	ds:[FP_stdPath], SP_NOT_STANDARD_PATH
		mov	ds:[FP_pathInfo], FS_NOT_STANDARD_PATH
	;
	; Unlock the path block and return carry clear.
	; 
		call	MemUnlock

if _PCMCIA
	;
	; Increment the in-use count for this card
	;
		mov	bx, es:[curSocketPtr]
		inc	es:[bx].PGFSSI_inUseCount
endif
		clc
unlock:
		call	GFSDevUnlock
		.leave
		ret
GFSCurPathSet	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSCurPathGetID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the 32-bit ID number for the thread's current directory.

CALLED BY:	DR_FS_CUR_PATH_GET_ID
PASS:		es:si	= DiskDesc on which path is located (locked)
RETURN:		cx:dx	= 32-bit ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSCurPathGetID	proc	far
		uses	ds, bx, ax
		.enter
		mov	bx, ss:[TPD_curPath]
		call	MemLock
		mov	ds, ax
		movdw	cxdx, ({GFSPathPrivate}ds:[FP_private]).GPP_attrs, ax
		call	MemUnlock
		.leave
		ret
GFSCurPathGetID	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSAllocOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a filesystem operation that will allocate a new file
		handle.

CALLED BYL	DR_FS_ALLOC_OP
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
			dx	= private data word for FSD

		Carry set if operation unsuccessful:
			ax	= error code.  See NOTE 1 about links

DESTROYED:	
SIDE EFFECTS:	

FSAllocOpFunction	etype byte
    FSAOF_OPEN		enum	FSAllocOpFunction
    ;	Pass:	nothing extra
    ;	Return:	nothing extra
    ;

    FSAOF_CREATE		enum	FSAllocOpFunction
    ;	Pass:	cl	= FileAttrs
    ;		ch	= FileCreateFlags
    ;	Return:	nothing extra
    ;	Notes:	the passed file does not exist, according to the kernel, so
    ;		the checking for disk writability that applies to FSAOF_OPEN
    ;		does not apply here, for the simple reason that the kernel
    ;		will have already checked it.
    ;
    ;		The driver should return an error if the file is found to
    ;		actually exist, rather than truncating the existing file.
    ;


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSAllocOp	proc	far
		uses	ds, si, di, es, cx
		.enter
		cmp	ah, FSAOF_CREATE
		jne	doOpen
	;
	; Create not allowed on this filesystem, bub. The kernel should
	; protect us from this, since no disk we register will ever have
	; DF_WRITABLE set, but you never know...
	; 
		mov	ax, ERROR_WRITE_PROTECTED
		stc
		jmp	done

doOpen:
	;
	; Not scanning. We don't care about the access flags, as we
	; don't do any access controls here, as no one can modify
	; these files anyway
	;

if _PCMCIA
		mov	al, mask GDLF_DISK
else
		clr	al
endif
		call	GFSDevLock
	;
	; Map that sucker.
	; 
		call	GFSMapPath	; ds <- dgroup, too
		jc	unlockDone
		
	;
	; Make sure the thing we found is a file, not a directory or link.
	; 
		mov	al, ds:[gfsLastFound].GDE_attrs
		test	al, mask FA_SUBDIR or mask FA_LINK
		jnz	cannotOpen
	;
	; Allocate a GFSFileEntry for our use.
	; 
		call	GFSAllocFileEntry	; dx:si <- GFSFileEntry
						;  al <- index
		jc	unlockDone
	;
	; Transfer the requisite pieces from the global variables to the
	; new entry.
	; 
		push	ax
		mov	es, dx
		movdw	es:[si].GFE_extAttrs, ds:[gfsLastFoundEA], ax
		movdw	es:[si].GFE_data, ds:[gfsLastFound].GDE_data, ax
		movdw	es:[si].GFE_size, ds:[gfsLastFound].GDE_size, ax
		mov	al, ds:[gfsLastFound].GDE_fileType
		mov	es:[si].GFE_fileType, al
		mov	es:[si].GFE_refCount, 1
if _PCMCIA

	;
	; Store the socket pointer in the file table, and increment the
	; in-use count for this socket.
	;
		push	bx
		mov	bx, ds:[curSocketPtr]
		inc	ds:[bx].PGFSSI_inUseCount
		mov	es:[si].GFE_socket, bx
		pop	bx
endif
		clr	ax, es:[si].GFE_curPos.low, es:[si].GFE_curPos.high
	;
	; Generate file-open notification, if required.
	; 
		movdw	cxdx, ds:[gfsLastFoundEA]	; cxdx <- ID
		mov	ax, FCNT_OPEN			; ax <- notification
							;  type
		call	GFSNotifyIfNecessary

	;
	; Return dx (private data) as GFSFileTableBlock segment, and al as
	; the index. ah is always 0 (we don't do devices).
	; 
		mov	dx, es
		pop	ax
		clr	ah
		jmp	done		; (device unlocked by
					; GFSNotifyIfNecessary)
unlockDone:
		call	GFSDevUnlock
done:
		.leave
		ret

cannotOpen:
		test	al, mask FA_SUBDIR
		mov	ax, ERROR_ACCESS_DENIED
		stc
		jnz	unlockDone
	;
	; It's a link. Read the data for the link and return that.
	; 
		call	GFSPathReadLastLink
		jc	unlockDone
		mov	ax, ERROR_LINK_ENCOUNTERED
		stc
		jmp	unlockDone
GFSAllocOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSAllocFileEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a GFSFileEntry structure.

CALLED BY:	(INTERNAL) GFSAllocOp
PASS:		ds	= dgroup
RETURN:		carry clear if successful:
			dx:si	= GFSFileEntry
			al	= index of file entry within its
				  GFSFileTableBlock
		carry set if not:
			ax	= ERROR_TOO_MANY_OPEN_FILES
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GFSAllocFileEntry proc	near
		uses	bx, ds, cx, ds
		.enter
	;
	; ds:bx points to the GFSFileTableBlock being processed throughout
	; the loop (of course, bx becomes 0 almost immediately, but there
	; you have it)
	; 
		mov	bx, offset gfsFileTable - offset GFTB_next
blockLoop:
		tst	ds:[bx].GFTB_next	; any next block to check?
		jz	allocNew		; no -- allocate another
		
		mov	ds, ds:[bx].GFTB_next	; ds:bx <- current block
		clr	bx
	;
	; Loop through the entries looking for one with a refCount of 0
	; 
		mov	si, offset GFTB_entries - size GFSFileEntry
		mov	ax, -1
		mov	cx, length GFTB_entries
entryLoop:
		add	si, size GFSFileEntry	; point to next entry
		inc	ax			; adjust entry index properly
		cmp	ds:[si].GFE_refCount, 0	; unused?
		loopne	entryLoop		; sigh

		jne	blockLoop		; => ran out of entries, so
						;  advance to the next block
		
	;
	; Success (carry already clear). dx:si <- GFSFileEntry, al is index
	; 
		mov	dx, ds
done:
		.leave
		ret

allocNew:
	;
	; Allocate a new fixed block of entries and link it in.
	; 
		mov	si, bx		; save bx
		mov	ax, size GFSFileTableBlock
		mov	cx, ALLOC_FIXED or (mask HAF_ZERO_INIT shl 8)
		mov	bx, handle 0
		call	MemAllocSetOwner
		jc	allocErr

		mov	bx, si		; ds:bx <- previous block, again
		mov	ds:[bx].GFTB_next, ax
		jmp	blockLoop
allocErr:
		mov	ax, ERROR_TOO_MANY_OPEN_FILES
		jmp	done
GFSAllocFileEntry endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GFSPathOp
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
GFSPathOp	proc	far
		uses	ds, dx

paramBX		local	word	push	bx

ForceRef	paramBX		; used by GFSPathErrorCheckLink

		.enter

		push	bp
		mov	al, ah
		clr	ah
		shl	ax
		mov_tr	di, ax
if _PCMCIA
		mov	al, mask GDLF_DISK
else
		clr	al
endif
		call	GFSDevLock
		
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
deleteDir:
deleteFile:
renameFile:
moveFile:
setAttrs:
setExtAttrs:
createLink:
setLinkExtraData:
		mov	ax, ERROR_WRITE_PROTECTED
		stc
		jmp	done

mapNativeName:
mapVirtualName:
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		stc
		jmp	done

	;--------------------
getAttrs:
		call	GFSMapPath		; ds <- dgroup, too
		jc	done
		mov	cl, ds:[gfsLastFound].GDE_attrs
		andnf	cx, (not FA_GEOS and 0xff)
		jmp	done

	;--------------------
getExtAttrs:
	;
	; Map virtual to native name first.
	; 
		call	GFSMapPath		; ds <- dgroup, too
		jc	done
	;
	; Now call common code to fetch the attribute(s) desired.
	; 
		push	es
		mov	ax, ss:[bx].FPEAD_attr
		les	di, ss:[bx].FPEAD_buffer
		clr	dx		; signal file not opened 
		call	GFSEAGetExtAttrs
		pop	es
		jmp	done

	;--------------------
getAllExtAttrs:
		call	GFSMapPath
		jc	done
		movdw	dxax, ds:[gfsLastFoundEA]
		call	GFSEAGetAllExtAttrs
done:
		call	GFSDevUnlock
		pop	bp

		.leave
		ret

	;--------------------
readLink:
		call	GFSMapPath		; ds <- dgroup, too
		jc	done
		
		mov	ax, ERROR_NOT_A_LINK
		test	ds:[gfsLastFound].GDE_attrs, mask FA_LINK
		stc
		jz	done
		
		push	bx
		call	GFSPathReadLastLink
		mov	cx, bx			; return it in cx
		pop	bx

doneOK:
		clc
		jmp	done


	;--------------------
getLinkExtraData:
	;
	; Map the name to a directory entry.
	; 
		call	GFSMapPath		; ds <- dgroup, too
		jc	done
	;
	; Make sure the thing is a link.
	; 
		mov	ax, ERROR_NOT_A_LINK
		test	ds:[gfsLastFound].GDE_attrs, mask FA_LINK
		stc
		jz	done
	;
	; It is. Read the link file into memory so we can get to the extra data.
	; 
		push	es
		push	bx		; save passed bx for after
		segmov	es, ds
		mov	di, offset gfsLastFound	; es:di <- dir entry
		call	GFSReadEntireLink	; ds, ^hbx <- GFSLinkData
		jc	getExtraDataFailed
		pop	bp		; ss:bp <- FSPathLinkExtraDataParams
		push	bp
		les	di, ss:[bp].FPLEDP_buffer
		cmp	cx, ds:[GLD_extraDataSize]
		jbe	copyExtraData
		mov	cx, ds:[GLD_extraDataSize]; asking for more than there
						  ;  is
copyExtraData:
	;
	; Copy as many bytes as were asked for or are present.
	; 
		push	cx			; save for return
		mov	si, ds:[GLD_diskSize]	; extra data follows the saved
		add	si, ds:[GLD_pathSize]	;  disk and target path
		add	si, offset GLD_savedDisk;  which begin here
		rep	movsb
		pop	cx
		
		call	MemFree			; free the GLD block
		pop	bx
		pop	es
		jmp	doneOK

getExtraDataFailed:
		pop	bx
		pop	es
		jmp	done
GFSPathOp	endp


Movable	ends
