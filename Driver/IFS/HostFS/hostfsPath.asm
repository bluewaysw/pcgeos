COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsPath.asm

ROUTINES:
	Name			Description
	----			-----------
    EXT	HostFSCurPathSet	DR_FS_CUR_PATH_SET
    EXT	HostFSCurPathGetID	DR_FS_CUR_PATH_GET_ID
    EXT	HostFSAllocOp		DR_FS_ALLOC_OP (open, create)
    EXT	HostFSPathOp		DR_FS_PATH_OP
    EXT	HostFSFileEnum		DR_FS_FILE_ENUM
    INT	HostFsGetAllExtAttrs	Two-phase FSPOF/FSHOF_GET_ALL_EXT_ATTRIBUTES

DESCRIPTION:
	Operations on paths.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSCurPathSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the thread's current directory.
CALLED BY:	DR_FS_CUR_PATH_SET
PASS:		ds:dx	= path to set, w/o drive specifier (always absolute)
		es:si	= disk on which the path resides
RETURN:		carry clear if successful:
			TPD_curPath holds our private data
		carry set on error:
			ax	= ERROR_PATH_NOT_FOUND (or other FileError)
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The host checks the directory exists and gives us its ID, which
	is all we keep (in FP_private): relative paths are resolved by
	the host starting from that ID.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSCurPathSet proc	far
frame		local	HostFsFrame
		uses	bx, cx, dx, si, di, ds, es
		.enter
		lea	di, ss:[frame]
		mov	ax, HFF_CUR_PATH_SET
		call	HostFsInitFrame
		call	HostFsPrepPath
		call	HostFsCallFrame
		jc	done
	;
	; Make sure there's room in the path block for our private data.
	; We only enlarge the block, never shrink it (don't want to mess up
	; other FSD's data).
	;
		mov	bx, ss:[TPD_curPath]
		mov	ax, MGIT_SIZE
		call	MemGetInfo
		mov	cx, size FilePath + size HostFsPathPrivate
		cmp	ax, cx
		jae	informPrevFSD
		mov_tr	ax, cx
		push	ax
		clr	cx			; no special flags
		call	MemReAlloc
		pop	cx
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		jc	done
informPrevFSD:
	;
	; Tell the old FSD it's our block now, then fill in our data.
	;
		call	FSDInformOldFSDOfPathNukage
		call	MemLock
		mov	ds, ax
		mov	ds:[FP_path], cx	; path goes after our data
		mov	ax, ss:[di].HFF_dx
		mov	({HostFsPathPrivate}ds:[FP_private]).HFPP_dirId.low, ax
		mov	ax, ss:[di].HFF_cx
		mov	({HostFsPathPrivate}ds:[FP_private]).HFPP_dirId.high, ax
		mov	ds:[FP_stdPath], SP_NOT_STANDARD_PATH
		mov	ds:[FP_pathInfo], FS_NOT_STANDARD_PATH
		call	MemUnlock
		clc
done:
		.leave
		ret
HostFSCurPathSet endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSCurPathGetID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the 32-bit ID of the thread's current directory.
CALLED BY:	DR_FS_CUR_PATH_GET_ID
PASS:		es:si	= DiskDesc
RETURN:		cx:dx	= ID
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSCurPathGetID proc	far
		uses	ax
		.enter
		call	HostFsCurDirId		; dx:ax <- ID, cx <- path info
		mov	cx, dx
		mov_tr	dx, ax
		.leave
		ret
HostFSCurPathGetID endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSAllocOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open or create a file.
CALLED BY:	DR_FS_ALLOC_OP
PASS:		al	= FullFileAccessFlags
		ah	= FSAllocOpFunction
		ds:dx	= path
		es:si	= DiskDesc
		cl	= FileAttrs		(FSAOF_CREATE)
		ch	= FileCreateFlags	(FSAOF_CREATE)
RETURN:		carry clear if successful:
			al	= SFN (low byte of our handle)
			ah	= 0 (not a device)
			dx	= private data: the host's file handle
		carry set on error:
			ax	= FileError
DESTROYED:	nothing else

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSAllocOp	proc	far
frame		local	HostFsFrame
		uses	bx, cx, si, di
		.enter
		lea	di, ss:[frame]
		push	ax
		mov	bl, ah
		mov	ax, HFF_OPEN		; FSAOF_OPEN, FSAOF_REOPEN
		cmp	bl, FSAOF_CREATE
		jne	haveFunc
		mov	ax, HFF_CREATE
haveFunc:
		call	HostFsInitFrame
		pop	ax
		clr	ah
		mov	ss:[di].HFF_ax, ax	; access flags
		mov	ss:[di].HFF_cx, cx	; attrs and create flags
		call	HostFsPrepPath
		call	HostFsCallFrame
		jc	done
		call	HostFsSendNotifications	; FCNT_CREATE
		mov	si, ss:[di].HFF_disk
		mov	ax, FCNT_OPEN
		mov	cx, ss:[di].HFF_cx
		mov	dx, ss:[di].HFF_dx
		call	HostFsNotifyOpenClose
		mov	dx, ss:[di].HFF_ax	; dx <- host handle
		mov	al, dl
		clr	ah
		clc
done:
		.leave
		ret
HostFSAllocOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsGetAllExtAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch all extended attributes into a new block.
CALLED BY:	HostFSPathOp, HostFSHandleOp
PASS:		ss:di	= HostFsFrame, prepared for the path or handle, with
			  HFF_func = HFF_PATH_GET_ALL_SIZE or
			  HFF_HANDLE_GET_ALL_SIZE (FILL must follow it)
RETURN:		carry clear if successful:
			ax	= handle of locked block with the array of
				  FileExtAttrDesc structures and their values
			cx	= number of entries in the array
		carry set on error:
			ax	= FileError
DESTROYED:	bx, dx, si

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsGetAllExtAttrs proc near
		call	HostFsCallFrame		; size phase
		jc	done
		mov	ax, ss:[di].HFF_ax	; ax <- bytes needed
		mov	cx, ALLOC_DYNAMIC_LOCK
		call	MemAlloc		; bx <- handle, ax <- segment
		jc	noMem
		mov	ss:[di].HFF_es, ax
		inc	ss:[di].HFF_func	; fill phase
		push	bx
		call	HostFsCallFrame
		pop	bx
		jc	fillFailed
		mov	cx, ss:[di].HFF_cx
		mov_tr	ax, bx
		clc
done:
		ret
noMem:
		mov	ax, ERROR_INSUFFICIENT_MEMORY
		stc
		ret
fillFailed:
		push	ax
		call	MemFree
		pop	ax
		stc
		ret
HostFsGetAllExtAttrs endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSPathOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on a path.
CALLED BY:	DR_FS_PATH_OP
PASS:		ah	= FSPathOpFunction
		ds:dx	= path
		es:si	= DiskDesc
		other args as per FSPathOpFunction
RETURN:		carry clear if successful:
			cx	= FileAttrs (FSPOF_GET_ATTRIBUTES)
			ax, cx	= block, count (FSPOF_GET_ALL_EXT_ATTRIBUTES)
		carry set on error:
			ax	= FileError
DESTROYED:	nothing else

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSPathOp	proc	far
frame		local	HostFsFrame
		uses	bx, dx, si, di, ds, es
		.enter
		lea	di, ss:[frame]
		push	ax
		clr	ax
		call	HostFsInitFrame		; function set below
		call	HostFsPrepPath
		mov	ss:[di].HFF_cx, cx
		pop	ax
	;
	; Look up the host function for this FSPathOpFunction.
	;
		push	bx
		mov	bl, ah
		clr	bh
		shl	bx
		mov	bx, cs:[pathOpFuncs][bx]
		mov	ss:[di].HFF_func, bx
		pop	bx
		jmp	dispatch

pathOpFuncs	HostFsFunction	\
		HFF_CREATE_DIR,		; FSPOF_CREATE_DIR
		HFF_DELETE_DIR,		; FSPOF_DELETE_DIR
		HFF_DELETE_FILE,	; FSPOF_DELETE_FILE
		HFF_RENAME,		; FSPOF_RENAME_FILE
		HFF_MOVE,		; FSPOF_MOVE_FILE
		HFF_GET_ATTRS,		; FSPOF_GET_ATTRIBUTES
		HFF_SET_ATTRS,		; FSPOF_SET_ATTRIBUTES
		HFF_PATH_GET_EXT,	; FSPOF_GET_EXT_ATTRIBUTES
		HFF_PATH_GET_ALL_SIZE,	; FSPOF_GET_ALL_EXT_ATTRIBUTES
		HFF_PATH_SET_EXT,	; FSPOF_SET_EXT_ATTRIBUTES
		0,			; FSPOF_MAP_VIRTUAL_NAME
		0,			; FSPOF_MAP_NATIVE_NAME
		0,			; FSPOF_CREATE_LINK
		0,			; FSPOF_READ_LINK
		0,			; FSPOF_SET_LINK_EXTRA_DATA
		0,			; FSPOF_GET_LINK_EXTRA_DATA
		HFF_CREATE_DIR		; FSPOF_CREATE_DIR_WITH_NATIVE_SHORT_NAME
CheckHack <length pathOpFuncs eq FSPathOpFunction>

dispatch:
	;
	; ah	= FSPathOpFunction
	; bx	= as passed
	; HFF_func set, 0 for the functions we don't support
	;
		cmp	ah, FSPOF_RENAME_FILE
		je	rename
		cmp	ah, FSPOF_MOVE_FILE
		je	move
		cmp	ah, FSPOF_GET_EXT_ATTRIBUTES
		je	extAttrs
		cmp	ah, FSPOF_SET_EXT_ATTRIBUTES
		je	extAttrs
		cmp	ah, FSPOF_GET_ALL_EXT_ATTRIBUTES
		je	getAll
		cmp	ah, FSPOF_READ_LINK
		je	notALink
		cmp	ah, FSPOF_GET_LINK_EXTRA_DATA
		je	notALink
		tst	ss:[di].HFF_func
		jz	unsupported
		jmp	callIt

rename:
	; bx:cx	= new name
		mov	ss:[di].HFF_bx, bx
		jmp	callIt

move:
	; es:cx	= DiskDesc of destination, ss:bx = FSMoveFileData
		mov	ax, ERROR_DIFFERENT_DEVICE
		cmp	cx, si
		stc
		jne	done
		mov	ax, ss:[bx].FMFD_dest.offset
		mov	ss:[di].HFF_aux.low, ax
		mov	ax, ss:[bx].FMFD_dest.segment
		mov	ss:[di].HFF_aux.high, ax
		push	ds, si
		lds	si, ss:[bx].FMFD_dest
		cmp	{char}ds:[si], C_BACKSLASH
		pop	ds, si
		je	callIt			; absolute: HFF_auxId stays 0
		call	HostFsCurDirId		; dx:ax <- dir, cx destroyed
		mov	ss:[di].HFF_auxId.low, ax
		mov	ss:[di].HFF_auxId.high, dx
		jmp	callIt

extAttrs:
	; ss:bx	= FSPathExtAttrData, cx = size or count
		mov	ax, ss:[bx].FPEAD_attr
		mov	ss:[di].HFF_ax, ax
		mov	ax, ss:[bx].FPEAD_buffer.offset
		mov	ss:[di].HFF_di, ax
		mov	ax, ss:[bx].FPEAD_buffer.segment
		mov	ss:[di].HFF_es, ax
		jmp	callIt

getAll:
		call	HostFsGetAllExtAttrs	; ax, cx <- block, count
		jmp	done

notALink:
		mov	ax, ERROR_NOT_A_LINK
		stc
		jmp	done

unsupported:
		mov	ax, ERROR_UNSUPPORTED_FUNCTION
		stc
		jmp	done

callIt:
		push	cx
		call	HostFsCallFrame
		pop	cx
		jc	done
		call	HostFsSendNotifications
		cmp	ss:[di].HFF_func, HFF_GET_ATTRS
		jne	ok
		mov	cx, ss:[di].HFF_cx	; FileAttrs
ok:
		clc
done:
		.leave
		ret
HostFSPathOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSFileEnum
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the thread's current directory, calling the
		kernel back for each file and directory.
CALLED BY:	DR_FS_FILE_ENUM
PASS:		cx:dx	= routine to call back
		ds	= segment of FileEnumCallbackData
		es:si	= DiskDesc of current path
		ss:bx	= stack frame to pass to callback (in bp)
RETURN:		carry set if no files/dirs to enumerate:
			ax	= ERROR_NO_MORE_FILES
		else carry & registers as set by the callback
DESTROYED:	ax, bx, cx, dx; bp before & after the callback

PSEUDO CODE/STRATEGY:
	The host lists the directory as it is now, and for each entry
	fills in the attribute descriptors in the FileEnumCallbackData
	itself (value stored and FEAD_value.segment = ds, or segment 0
	if the file doesn't have the attribute). We only call back.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSFileEnum	proc	far
frame		local	HostFsFrame
callback	local	fptr.far
kernelFrame	local	word
enumHandle	local	word
fecd		local	sptr
		uses	si, di, es, ds
		.enter
		mov	ss:[callback].segment, cx
		mov	ss:[callback].offset, dx
		mov	ss:[kernelFrame], bx
		mov	ss:[fecd], ds

		lea	di, ss:[frame]
		mov	ax, HFF_ENUM_BEGIN
		call	HostFsInitFrame
		call	HostFsPrepDisk
		call	HostFsCurDirId		; dx:ax <- dir, cx <- path info
		mov	ss:[di].HFF_dirId.low, ax
		mov	ss:[di].HFF_dirId.high, dx
		mov	ss:[di].HFF_pathInfo, cx
		call	HostFsCallFrame		; ax <- handle, or
		jc	done			;  ERROR_NO_MORE_FILES
		mov	ax, ss:[di].HFF_ax
		mov	ss:[enumHandle], ax

nextFile:
	;
	; Have the host fill in the attributes of the next entry.
	;
		lea	di, ss:[frame]
		mov	ss:[di].HFF_func, HFF_ENUM_NEXT
		mov	ax, ss:[enumHandle]
		mov	ss:[di].HFF_ax, ax
		mov	ax, ss:[fecd]
		mov	ss:[di].HFF_ds, ax
		call	HostFsCallFrame
		jc	enumEnded
	;
	; Call the kernel back. It may biff es, bx, cx, dx, di and si.
	;
		mov	cx, ss:[kernelFrame]
		mov	ax, ss:[callback].offset
		mov	bx, ss:[callback].segment
		mov	ds, ss:[fecd]
		push	bp
		mov	bp, cx			; ss:bp <- kernel's frame
		mov	ss:[TPD_dataAX], ax
		mov	ss:[TPD_dataBX], bx
		call	ProcCallFixedOrMovable
		pop	bp
		jnc	nextFile
	;
	; The callback stopped the enumeration: tell the host, then return
	; what the callback returned.
	;
		push	ax
		lea	di, ss:[frame]
		mov	ss:[di].HFF_func, HFF_ENUM_END
		mov	ax, ss:[enumHandle]
		mov	ss:[di].HFF_ax, ax
		call	HostFsCallFrame
		pop	ax
		stc
		jmp	done

enumEnded:
	; ERROR_NO_MORE_FILES after at least one entry is the normal end
	; (the host has already let go of the enumeration).
		cmp	ax, ERROR_NO_MORE_FILES
		stc
		jne	done
		clc
done:
		.leave
		ret
HostFSFileEnum	endp

Resident	ends
