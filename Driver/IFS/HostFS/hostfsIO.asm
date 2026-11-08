COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) blueway.Softworks 2026 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		File System Drivers
FILE:		hostfsIO.asm

ROUTINES:
	Name			Description
	----			-----------
    EXT	HostFSHandleOp		DR_FS_HANDLE_OP
    EXT	HostFSCompareFiles	DR_FS_COMPARE_FILES

DESCRIPTION:
	Operations on open files. The private data of each file handle is
	the host's handle for the file.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Resident	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSHandleOp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an operation on an open file.
CALLED BY:	DR_FS_HANDLE_OP
PASS:		ah	= FSHandleOpFunction
		bx	= file handle
		es:si	= DiskDesc
		other args as per FSHandleOpFunction
RETURN:		carry set on error:
			ax	= FileError
		carry clear if successful:
			per FSHandleOpFunction
DESTROYED:	nothing else (bx must survive: the kernel returns to
		code that keeps using the file handle, e.g. the document
		control calling FileGetHandleExtAttributes twice in a row)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSHandleOp	proc	far
frame		local	HostFsFrame
		uses	bx, si, di, ds, es
		.enter
		lea	di, ss:[frame]
		push	ax
		clr	ax
		call	HostFsInitFrame		; function set below
		pop	ax
		call	HostFsPrepDisk
		mov	ss:[di].HFF_ax, ax
		mov	ss:[di].HFF_cx, cx
		mov	ss:[di].HFF_dx, dx
		mov	ss:[di].HFF_ds, ds
	;
	; Our private data in the file handle is the host's handle.
	;
		push	es
		mov	es, es:[FIH_dgroup]
		mov	bx, es:[bx].HF_private
		pop	es
		mov	ss:[di].HFF_handle, bx

		mov	bl, ah
		clr	bh
		shl	bx
		jmp	cs:[handleOpJmpTable][bx]

handleOpJmpTable	nptr.near	\
		doRead,			; FSHOF_READ
		doWrite,		; FSHOF_WRITE
		doPos,			; FSHOF_POSITION
		doTruncate,		; FSHOF_TRUNCATE
		doCommit,		; FSHOF_COMMIT
		doNothing,		; FSHOF_LOCK
		doNothing,		; FSHOF_UNLOCK
		doGetDate,		; FSHOF_GET_DATE_TIME
		doSetDate,		; FSHOF_SET_DATE_TIME
		doSize,			; FSHOF_FILE_SIZE
		doAddRef,		; FSHOF_ADD_REFERENCE
		doCheckDirty,		; FSHOF_CHECK_DIRTY
		doClose,		; FSHOF_CLOSE
		doGetFileID,		; FSHOF_GET_FILE_ID
		doCheckNative,		; FSHOF_CHECK_NATIVE
		doGetExtAttrs,		; FSHOF_GET_EXT_ATTRIBUTES
		doSetExtAttrs,		; FSHOF_SET_EXT_ATTRIBUTES
		doGetAllExtAttrs,	; FSHOF_GET_ALL_EXT_ATTRIBUTES
		doNothing,		; FSHOF_FORGET
		doNothing		; FSHOF_SET_FILE_NAME
CheckHack <length handleOpJmpTable eq FSHandleOpFunction>

	;--------------------
doRead:
		mov	ax, HFF_READ
		jmp	callAxResult
doWrite:
		mov	ax, HFF_WRITE
		jmp	callAxResult
doCheckDirty:
		mov	ax, HFF_CHECK_DIRTY
callAxResult:
		call	HostFsHandleCall
		jc	done
		mov	ax, ss:[di].HFF_ax
		jmp	doneOK

	;--------------------
doPos:
		mov	ax, HFF_POSITION
		jmp	callDxAxResult
doSize:
		mov	ax, HFF_FILE_SIZE
callDxAxResult:
		call	HostFsHandleCall
		jc	done
		mov	ax, ss:[di].HFF_ax
		mov	dx, ss:[di].HFF_dx
		jmp	doneOK

	;--------------------
doGetDate:
		mov	ax, HFF_GET_DATE_TIME
		jmp	callCxDxResult
doGetFileID:
		mov	ax, HFF_GET_FILE_ID
callCxDxResult:
		call	HostFsHandleCall
		jc	done
		mov	cx, ss:[di].HFF_cx
		mov	dx, ss:[di].HFF_dx
		jmp	doneOK

	;--------------------
doTruncate:
		mov	ax, HFF_TRUNCATE
		jmp	callNoResult
doCommit:
		mov	ax, HFF_COMMIT
		jmp	callNoResult
doSetDate:
		mov	ax, HFF_SET_DATE_TIME
		jmp	callNoResult
doAddRef:
		mov	ax, HFF_ADD_REFERENCE
callNoResult:
		call	HostFsHandleCall
		jc	done
		jmp	doneOK

	;--------------------
doClose:
		mov	ax, HFF_CLOSE
		call	HostFsHandleCall
		jc	done
		tst	ss:[di].HFF_ax		; really closed?
		jz	doneOK
		push	cx, dx
		mov	ax, FCNT_CLOSE
		mov	cx, ss:[di].HFF_cx
		mov	dx, ss:[di].HFF_dx
		mov	si, ss:[di].HFF_disk
		call	HostFsNotifyOpenClose
		pop	cx, dx
		jmp	doneOK

	;--------------------
doCheckNative:
	; ch = FileCreateFlags -> carry set if the file matches
		mov	ax, HFF_CHECK_NATIVE
		call	HostFsHandleCall
		jc	done
		tst	ss:[di].HFF_ax
		jz	doneOK			; doesn't match: carry clear
		stc
		jmp	done

	;--------------------
doGetExtAttrs:
		mov	ax, HFF_HANDLE_GET_EXT
		jmp	extAttrs
doSetExtAttrs:
		mov	ax, HFF_HANDLE_SET_EXT
extAttrs:
	; ss:dx	= FSHandleExtAttrData, cx = size or count
		mov	bx, dx
		push	ax
		mov	ax, ss:[bx].FHEAD_attr
		mov	ss:[di].HFF_ax, ax
		mov	ax, ss:[bx].FHEAD_buffer.offset
		mov	ss:[di].HFF_di, ax
		mov	ax, ss:[bx].FHEAD_buffer.segment
		mov	ss:[di].HFF_es, ax
		pop	ax
		jmp	callNoResult

	;--------------------
doGetAllExtAttrs:
		mov	ss:[di].HFF_func, HFF_HANDLE_GET_ALL_SIZE
		call	HostFsGetAllExtAttrs	; ax, cx <- block, count
		jmp	done

	;--------------------
doNothing:
doneOK:
		clc
done:
		.leave
		ret
HostFSHandleOp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFsHandleCall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the host perform a handle operation, then generate
		the notifications it asks for.
CALLED BY:	HostFSHandleOp
PASS:		ax	= HostFsFunction
		ss:di	= HostFsFrame
RETURN:		carry clear if successful (outputs in the frame)
		carry set on error: ax = FileError
DESTROYED:	bx, si

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFsHandleCall proc	near
		uses	cx, dx
		.enter
		mov	ss:[di].HFF_func, ax
		call	HostFsCallFrame
		jc	done
		call	HostFsSendNotifications
done:
		.leave
		ret
HostFsHandleCall endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HostFSCompareFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if two open files refer to the same host file.
CALLED BY:	DR_FS_COMPARE_FILES
PASS:		al	= SFN of first file
		bx	= private data of first file (host handle)
		cl	= SFN of second file
		dx	= private data of second file (host handle)
RETURN:		ah	= flags byte for sahf: je if the same file, carry
			  clear after sahf. Handles that are no longer valid
			  compare unequal.
DESTROYED:	nothing

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HostFSCompareFiles proc	far
frame		local	HostFsFrame
firstId		local	dword
		uses	bx, cx, dx, si, di
		.enter
		lea	di, ss:[frame]
		push	dx			; second handle
		mov	ax, HFF_GET_FILE_ID
		call	HostFsInitFrame
		mov	ss:[di].HFF_handle, bx
		call	HostFsCallFrame
		pop	si			; si <- second handle
		jc	unequal
		mov	ax, ss:[di].HFF_cx
		mov	ss:[firstId].high, ax
		mov	ax, ss:[di].HFF_dx
		mov	ss:[firstId].low, ax

		mov	ax, HFF_GET_FILE_ID
		call	HostFsInitFrame
		mov	ss:[di].HFF_handle, si
		call	HostFsCallFrame
		jc	unequal
		mov	ax, ss:[di].HFF_cx
		cmp	ax, ss:[firstId].high
		jne	unequal
		mov	ax, ss:[di].HFF_dx
		cmp	ax, ss:[firstId].low
		jne	unequal
		lahf				; ZF set, CF clear
		jmp	done
unequal:
		mov	ah, 0			; ZF clear, CF clear
done:
		.leave
		ret
HostFSCompareFiles endp

Resident	ends
