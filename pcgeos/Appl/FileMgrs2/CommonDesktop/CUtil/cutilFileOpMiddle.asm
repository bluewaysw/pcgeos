COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Util
FILE:		cutilFileOpMiddle.asm

ROUTINES:
	INT	CopyMoveFileToDir - common routine to do high-level move/copy
	INT	DeskFileCopy - copy file or directory!! 
	INT	FileCopyFile - copy single file
	INT	DeskFileMove - move file or directory!!
	INT	FileMoveFile - move single file
	INT	FileCopyMoveDir - recursively move/copy directory
	INT	GetNextFilename - parse filename list

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cutilFileOp.asm

DESCRIPTION:
	This file contains desktop utility routines.

	$Id: cutilFileOpMiddle.asm,v 1.2 98/06/03 13:51:06 joon Exp $

------------------------------------------------------------------------------@
FileOpLow	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMoveReadOnlyCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the "Confirm Read Only" UI is set, we ask the user if they
		really want to move the file, and if so (or if the UI is not
		set), we unset the readonly bit, move the file, and reset the
		read only bit.

CALLED BY:	FileMoveFile

PASS:		ds:si 	= source FOIE
		ds:0	= FileQuickTransferHeader
		es:di 	= destination file
		current dir is destination dir

RETURN:		carry	= set on error
				ax = error code
			= clear if no errors
				ax = YESNO_YES to move despite readonly
					otherwise:
				   = YESNO_NO

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/ 4/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMoveReadOnlyCheck	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter

if not _ZMGR
	push	si, di
GM<	mov	bx, handle OptionsDeleteWarnings	>
GM<	mov	si, offset OptionsDeleteWarnings	>
ND<	mov	bx, handle OptionsList	>
ND<	mov	si, offset OptionsList	>
	mov	cx, mask OMI_CONFIRM_READ_ONLY
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall			; carry if set
	pop	si, di
	mov	ax, YESNO_YES
	jnc	ignoreReadOnly
endif		; if (not _ZMGR) and (not _NIKE)

	mov	ax, WARNING_MOVE_READONLY
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES
	clc
	jne	exit

if not _ZMGR
ignoreReadOnly:
endif		; if (not _ZMGR) and (not _NIKE)
	;
	; Go to the source
	;
	push	ax
	call	FilePushDir
	mov	bx, ds:[FQTH_diskHandle]
	lea	dx, ds:[FQTH_pathname]
	call	FileSetCurrentPath
	jc	popDir

	;
	; clear the source file's read only bit
	;
	lea	dx, ds:[si].FOIE_name
	mov	cl, ds:[si].FOIE_attrs
	andnf	cl, not mask FA_RDONLY
	clr	ch
	call	FileSetAttributes

popDir:
	pop	ax
	call	FilePopDir
exit:
	.leave
	ret
FileMoveReadOnlyCheck	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryCloseFileForMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	setup to call TryCloseOrSaveFile

CALLED BY:	INTERNAL
			FileMoveFile
			FileCopyFile

PASS:		ds:si = source file name
		cx = source disk handle
		bp = 0 move
			ax = error code
		bp = 1 copy

RETURN:		if bp = 0 (move)
			carry clear if closed
			carry set if couldn't close
				ax = error code
		if bp = 1
			nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/2/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if TRY_CLOSE_ON_IN_USE_ERROR

TryCloseFileForMoveCopy	proc	near
	cmp	bp, 1			; no error code for copy
	je	isCopy
	cmp	ax, ERROR_FILE_IN_USE
	je	doClose
	cmp	ax, ERROR_SHARING_VIOLATION
	je	doClose
	cmp	ax, ERROR_ACCESS_DENIED
	stc				; in case not ERROR_FILE_IN_USE
	jne	done
isCopy:
doClose:
	call	FilePushDir
	push	ds, ax, bx, dx
	mov	bx, cx
	segmov	ds, cs
	mov	dx, offset rootPathString
	call	FileSetCurrentPath	; switch to source dir
	pop	ds, ax, bx, dx
	jc	done			; can't CD -> can't close
	push	cx, dx
	mov	dx, si			; ds:dx = file
	mov	cx, bp			; cx = 0 for move -> close
					; cx <> 0 for copy -> save
	call	TryCloseOrSaveFile
	pop	cx, dx
	call	FilePopDir		; preserves flags
	jc	done			; couldn't close, return error
	cmp	bp, 0
	jne	done			; was copy, done
	;
	; try move again and return error
	;	
	tst	ss:[useLocalMoveCopy]
	jz	regularMove
	call	DesktopFileMoveLocal		; no FileMovelocal is currently
	jmp	afterMove			;  supported...
regularMove:
	call	FileMove
afterMove:

done:
	ret
TryCloseFileForMoveCopy	endp

LocalDefNLString rootPathString <C_BACKSLASH, 0>

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopFileMoveLocal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uses FileCopyLocal and FileDelete to do the equivalent of
		a FileMoveLocal, as this is not supported by the filesystem.

CALLED BY:	FileMoveFile, TryCloseFileForMoveCopy

PASS:		ds:si	= source file name
		cx	= source disk handle
		es:di	= destination file name
		dx	= destination disk handle
		
		Either one of the disk handles may be 0, in which case 
		thread's current path will be used and the associated file
		name (either source or destination) may be relative.
		
		If a disk handle is provided, the corresponding path *must*
		be absolute (begin with a backslash).
RETURN:		carry set if errror:
			ax	= ERROR_FILE_NOT_FOUND
				= ERROR_PATH_NOT_FOUND
				= ERROR_TOO_MANY_OPEN_FILES
				= ERROR_ACCESS_DENIED
				= ERROR_SHORT_READ_WRITE (insufficient space
				  on destination disk)
				= ERROR_DIFFERENT_DEVICE
				= ERROR_INSUFFICIENT_MEMORY
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopFileMoveLocal	proc	near
	uses	bx,cx,dx
	.enter

	call	FileCopyLocal
	jc	exit

	call	FilePushDir
	push	ds
	segmov	ds, cs, dx
	mov	dx, offset localMoveRootPath
	mov	bx, cx
	call	FileSetCurrentPath		; set current path to source's
	pop	ds				;  diskhandle
	jc	popDirAndExit

	mov	dx, si				; ds:dx is filename
	call	FileDelete

popDirAndExit:
	call	FilePopDir
exit:
	.leave
	ret
DesktopFileMoveLocal	endp

LocalDefNLString localMoveRootPath <C_BACKSLASH, 0>




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyOrMoveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move or copy a single file

CALLED BY:	INTERNAL
			FileCopyFile, FileMoveFile

PASS:		ds:si 	- source FOIE
		ds:0	= FileQuickTransferHeader
		es:di 	- destination file
		current dir is destination dir
		actionRoutine = near routine to call to perform the
				actual move or copy:
			Pass:	ds:si	= source file
				cx	= source disk handle
				es:di	= dest file
				dx	= dest disk handle
			Return:	carry set on error:
					ax = error code
				carry clear on success

RETURN:		carry set if error
			AX - error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyOrMoveFile	proc	near actionRoutine:word	; address of tiny
							; routine to perform
							; the actual move or
							; copy of the file 
	uses	bx, cx, dx, ds, si, es, di, bp
	.enter
	clr	bx				; non overwrite update
	call	UpdateProgressCommon
	LONG jc	done			; if CANCEL, exit w/AX

	call	SetUpForRecurError
	;
	; Construct the full path for the source file, getting back the
	; real disk handle for the beast, not one of these StandardPath
	; things.
	; 
	call	FilePushDir
	mov	bx, ds:[FQTH_diskHandle]
	lea	dx, ds:[FQTH_pathname]
	call	FileSetCurrentPath
	jc	popDirAndExit

	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	mov	bx, sp
	push	es, di
	mov	di, bx
	segmov	es, ss
		CheckHack <offset FOIE_name eq 0>
	clr	dx			; no drive spec
	clr	bx			; use current dir
	call	FileConstructFullPath
	pop	es, di
	
	segmov	ds, ss
	mov	si, sp			; ds:si <- full source path

	mov	cx, bx			; cx <- source disk handle
	call	FilePopDir
	clr	dx			; use current dir for dest
	call	ss:[actionRoutine]

	mov	bx, sp			; clear stack after the event...
	lea	sp, [bx+PATH_BUFFER_SIZE]

	jnc	done
	;
	; Transform ERROR_FILE_FORMAT_MISMATCH into ERROR_FILE_EXISTS
	;
	cmp	ax, ERROR_FILE_FORMAT_MISMATCH
	jne	40$
	mov	ax, ERROR_FILE_EXISTS
40$:
	;
	; Transform ERROR_SHORT_READ_WRITE to our internal
	; ERROR_INSUFFICIENT_SPACE. Everything else is ok as is
	; 
	cmp	ax, ERROR_SHORT_READ_WRITE
	stc
	jne	done
	mov	ax, ERROR_INSUFFICIENT_SPACE_NO_SUGGESTION
if not _FCAB
	push	ax
	;
	; check if system disk, if so, give suggestion to empty wastebasket
	;
	clr	dx				; no drive name requested
	clr	bx				; use current path
	segmov	ds, cs, si
	mov	si, offset dotPath		; build out current path
	mov	cx, size PathName		; cx is size of buffer
	sub	sp, cx				; es:di is stack buffer
	segmov	es, ss, di
	mov	di, sp
	call	FileConstructActualPath		; bx is actual disk handle
	add	sp, size PathName		; pop stack buffer
	pop	ax

	cmp	bx, ss:[geosDiskHandle]
	jne	isntSystemDisk
	mov	ax, ERROR_INSUFFICIENT_SPACE
isntSystemDisk:

	cmp	ss:[usingWastebasket], NOT_THE_WASTEBASKET
	stc
	je	done
	mov	ax, ERROR_WASTEBASKET_FULL
endif			; if (not _FCAB)
	jmp	done

popDirAndExit:
	call	FilePopDir
done:
	.leave
	ret	@ArgSize
FileCopyOrMoveFile	endp

SBCS <dotPath char '.', 0						>
DBCS <dotPath wchar '.', 0						>


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEnumDirToFQT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the directory in the given FOIE to form a
		FileQuickTransfer block.

CALLED BY:	FileCopyMoveDir, FileDeleteAllDir

PASS:		ds:si	= FOIE containing name of directory to enumerate
		ds:0	= FileQuickTransferHeader

RETURN:		IF ERROR:
			carry set
			ax	= FileError
		ELSE:
			carry clear
			bx	= handle of new FQT block (locked)
			ds	= segment of FQT block
			cx	= number of files to process
			current directory pushed to directory just enumerated
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _FXIP
TableResourceXIP	segment resource
endif

fileEnumDirReturnAttrs	FileExtAttrDesc \
	<FEA_NAME,		FOIE_name,	size FOIE_name>,
	<FEA_FILE_TYPE,		FOIE_type,	size FOIE_type>,
	<FEA_FILE_ATTR,		FOIE_attrs,	size FOIE_attrs>,
	<FEA_FLAGS,		FOIE_flags, 	size FOIE_flags>,
	<FEA_DESKTOP_INFO,	FOIE_info,	size FOIE_info>,
	<FEA_PATH_INFO, 	FOIE_pathInfo, 	size FOIE_pathInfo>,
	<FEA_END_OF_LIST>

if _FXIP
TableResourceXIP	ends
endif

fileEnumDirParams	FileEnumParams <
	FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS or \
	mask FESF_LEAVE_HEADER,				; FEP_searchFlags
	fileEnumDirReturnAttrs,				; FEP_returnAttrs
	size FileOperationInfoEntry,			; FEP_returnSize
	0,						; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,				; FEP_bufSize
	0,						; FEP_skipCount
	0,						; FEP_callback
	0,						; FEP_callbackAttrs
	0,						; FEP_cbData1
	0,						; FEP_cbData2
	size FileQuickTransferHeader			; FEP_headerSize
>
FileEnumDirToFQT proc	near

		uses	dx

		.enter
	;
	; Push to the source directory given in the FQT we were passed.
	; 
		call	FilePushDir

		mov	bx, ds:[FQTH_diskHandle]
		lea	dx, ds:[FQTH_pathname]
		call	FileSetCurrentPath
		jc	popDirAndExit

	;
	; Change to the directory in the FOIE.
	; 
		clr	bx
		lea	dx, ds:[si].FOIE_name
		call	FileSetCurrentPath
		jc	popDirAndExit

		segmov	ds, cs
		mov	si, offset fileEnumDirParams
		call	FileEnumPtr
		jc	popDirAndExit

		call	MemLock
	;
	; Fill in the header. Store the block's handle in the
	; nextBlock field so that we can get at it later (minor hack)
	; 
		push	bx, cx
		mov	ds, ax
		mov	ds:[FQTH_nextBlock], bx
		mov	si, offset FQTH_pathname
		mov	cx, size FQTH_pathname
		call	FileGetCurrentPath
		mov	ds:[FQTH_diskHandle], bx
		pop	bx, cx
		mov	ds:[FQTH_numFiles], cx
		clc
exit:
		.leave
		ret
popDirAndExit:
		call	FilePopDir
		jmp	exit
FileEnumDirToFQT endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyDirExtAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy the extended attributes from the source directory
		to the destination

CALLED BY:	FileCopyMoveDir

PASS:		ds - segment of FileQuickTransferHeader
		ds:si - source directory
		es:di - destination directory
		CWD set to containing directory of destination directory

RETURN:		if error
			carry set
		else
			carry clear 

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
	Allocate the path buffer on the heap, to avoid burdening the stack

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/14/94   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyDirExtAttributes	proc near
		uses	ds, si
		.enter

		push	es, di			; dest. dir
		call	ShellAllocPathBuffer
		mov	bx, es:[PB_handle]
		mov	dx, si			; ds:dx - source name
		mov	si, offset FQTH_pathname
		mov	cx, (size PathName)/2
		rep	movsw
		mov	si, offset PB_path
		mov	di, si
		call	ShellCombineFileAndPath
		mov	cx, ds:[FQTH_diskHandle]
		segmov	ds, es			; ds:si - source path
		clr	dx
		pop	es, di			; es:di - dest path
		call	FileCopyPathExtAttributes

		pushf
		call	MemFree
		popf

		.leave
		ret
CopyDirExtAttributes	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyMoveDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy/move a directory and all its contents to a new directory

CALLED BY:	INTERNAL
			CopyMoveFileOrDir
			FileCopyMoveDir (recursively)

PASS:		ds:si	= FileOperationInfoEntry for directory to copy/move
		ds:0	= FileQuickTransferHeader
		ds:FQTH_nextBlock - is either zero, of the handle of
			the block at DS.

		es:di	= destination directory (to be created if
			  not present yet)

		current dir is the directory in which the 
			destination directory will be created

		ss:[dirCopyMoveRoutine] - routine to call for file
		ss:[enteredFileOpRecursion] = 0 when called initially
					    = 1 when recursively called to
						copy/move a file/directory in
						the top-level directory

RETURN:		carry set if error
			ax - error code
		ss:[enteredFileOpRecursion] = 1 if recursively called to
						copy/move a file/directory in
						the top-level directory


		ds, es - fixed up if moved.

DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/1/89		Initial version
	brianc	10/30/89	use FileMoveFile instead of FileRename
					so different drives are supported

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCopyMoveDir	proc	near

	.enter

	;
	; If DS = ES on entry to this routine, then make sure to fix
	; up ES when we exit.
	;

	mov	ax, ds
	mov	bp, es
	sub	bp, ax			; zero if same, nonzero if different

	clr	bx			; non overwrite update
	call	UpdateProgressCommon
	LONG jc	exit			; if CANCEL, exit w/AX

	call	SetUpForRecurError		; make sure we have error name
						;	in case of createDir
						;	error
	push	ds
	segmov	ds, es				; es:di is dest name
	mov	dx, di				; ds:dx <- name to create
	call	FileCreateDirWithError		; create destination directory
	pop	ds
	LONG jc	exit				; if error, exit

	;
	; Copy extended attributes of directory, if any
	;
	call	CopyDirExtAttributes
		
	push	si, di
	push	es
	push	ds

	mov	dx, ds:[FQTH_nextBlock]		; parent handle

	call	FileEnumDirToFQT
	LONG	jc	FQTerror

	tst	dx
	jz	afterUnlock
	xchg	bx, dx
	call	MemUnlock

	;
	; In EC, force the block to move (via ECF_LMEM_MOVE). Don't
	; use ECF_UNLOCK_MOVE, because it's unreliable
	;
EC <	push	cx							>
EC <	clr	ax, cx							>
EC <	call	MemReAlloc						>
EC <	pop	cx							>

	xchg	bx, dx
afterUnlock:
	push	dx			; parent handle
	jcxz	noMoreFiles

	;
	; Change to destination directory.
	; 
	call	FilePopDir		; return to dest...
	call	FilePushDir		; and save it again
	push	ds
	segmov	ds, es
	mov	dx, di
	clr	bx
	call	FileSetCurrentPath
	pop	ds
	jc	error
	
	mov	si, offset FQTH_files
	segmov	es, ds
fileLoop:
	mov	ss:[enteredFileOpRecursion], 1	; entered recursion-zone
	lea	di, ds:[si].FOIE_name		; es:di <- dest name (same
						;  as source)
	call	UtilCheckInfoEntrySubdir
	jc	isDir
	push	cx				; FileMoveFile nukes cx
	call	ss:[dirCopyMoveRoutine]		; call routine to move/copy
						;  the file
	pop	cx
	jmp	checkError
isDir:
	push	cx, si
	call	FileCopyMoveDir
	pop	cx, si
checkError:
	jc	fileDirError
nextFile:
	add	si, size FileOperationInfoEntry
	loop	fileLoop
	jmp	noMoreFiles

fileDirError:
	cmp	ax, ERROR_FILE_IN_USE
	je	40$
	cmp	ax, ERROR_ACCESS_DENIED
	je	40$
	cmp	ax, ERROR_SHARING_VIOLATION
	jne	error				; if not, return error
40$:
	mov	ax, WARNING_RECURSIVE_ACCESS_DENIED
	lea	dx, ds:[si].FOIE_name		; ds:dx <- file name
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES			; continue?
	je	nextFile			; yes, skip erroneous file
error:
	stc					; indicate error

noMoreFiles:
	pop	dx				; parent block

	push	ax
	pushf
	mov	bx, ds:[FQTH_nextBlock]
	call	MemFree				; free our internal FQT block
	;
	; Now, re-lock the parent, unless we never unlocked it.
	; On the stack are: (flags) DS ES
	
	tst	dx
	jz	afterLock

	mov	bx, dx
	call	MemLock
	mov	di, sp
	mov	ss:[di][4], ax			; fixup DS

	tst	bp
	jnz	afterLock
	mov	ss:[di][6], ax			; fixup ES
afterLock:
	popf
	pop	ax
	pop	ds
	pop	es

	pop	si, di				; restore pointers

	jc	popDirAndExit
	
	cmp	ss:[dirCopyMoveRoutine], offset FileCopyFile
	je	popDirAndExit

	call	DoRemoteFileCheck
	cmc
	jnc	popDirAndExit

	mov	bx, ds:[FQTH_diskHandle]
	lea	dx, ds:[FQTH_pathname]
	call	FileSetCurrentPath
	jc	popDirAndExit
	
	call	SetUpForRecurError
	call	FileDeleteDirWithError

popDirAndExit:
	call	FilePopDir
exit:
	.leave
	ret

FQTerror:
	pop	es, si, di
	jmp	exit

FileCopyMoveDir	endp


;
; ds:si = FileOperationInfoEntry to use in reporting
; ds:0 = FileQuickTransferHeader
;

SetUpForRecurError	proc	near
	uses	ax, bx, cx, dx, ds, es, si, di, bp
	.enter
	
	;
	; build name into special buffer
	;
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
NOFXIP<	segmov	es, <segment dgroup>, di				>
	mov	di, offset pathBuffer
	
	;
	; First the leading path components.
	; 
	push	si
	mov	bx, ds:[FQTH_diskHandle]
	mov	si, offset FQTH_pathname
	mov	dx, TRUE		; add drive specifier
	mov	cx, size pathBuffer
	call	FileConstructFullPath
	pop	si

	;
	; Then the separator.
	; 
SBCS <	mov	al, C_BACKSLASH						>
DBCS <	mov	ax, C_BACKSLASH						>
SBCS <	cmp	es:[di-1], al						>
DBCS <	cmp	es:[di-2], ax						>
	je	addTail
	LocalPutChar esdi, ax
addTail:
	;
	; And finally the file/dir itself.
	; 
	push	si
	CheckHack <offset FOIE_name eq 0>
	call	CopyNullTermString
	pop	si
	;
	; To make life easier in other realms, copy the thing into the global
	; variable, too.
	; 
	mov	di, offset fileOperationInfoEntryBuffer
	mov	cx, size fileOperationInfoEntryBuffer
	rep	movsb

	.leave
	ret
SetUpForRecurError	endp

;----------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDirGetSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get size file or size of directory and files contained within

CALLED BY:	EXTERNAL

PASS:		ds:dx - name of file or directory whose size is desired, in
			current directory.
		current path set to that which holds the file/dir

RETURN:		carry set if error
			ax - error code
		carry clear otherwise
			dx:ax - file size
		ss:[recurErrorFlag] set if recursive operation error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/19/91		Hacked from FileDeleteFileDir

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDirGetSize	proc	far
	uses	bx, cx, ds, es, si, di, bp
	.enter
	call	FileIsFileADirectory?
	jc	sizeDirectory			; if so, get directory size
	;
	; get size of plain file (not in the most efficient manner with two
	; calls to FileGetPathExtAttributes to deal with 256 header, but I
	; don't think this is even used for a single file - brianc 7/12/93)
	;	ds:dx = source file
	;
	sub	sp, size dword + size GeosFileType
	segmov	es, ss
	mov	di, sp
	mov	ax, FEA_SIZE
	mov	cx, size dword
	call	FileGetPathExtAttributes
	jc	error
	add	di, size dword
	mov	cx, size GeosFileType
	mov	ax, FEA_FILE_TYPE
	call	FileGetPathExtAttributes
error:
	pop	dx, cx				; dx:cx = size
	pop	di				; di = GeosFileType
	jc	exit
	mov_tr	ax, cx
	;
	; If this a GEOS file, add 256 to its file size
	;
	cmp	di, GFT_NOT_GEOS_FILE
	je	afterSize
	adddw	dxax, 256
afterSize:
	jmp	exit

	;
	; get size of directory and files within
	;	ds:dx - directory filespec
	;
sizeDirectory:
	mov	ss:[totalDirSize].high, 0	; init size
	mov	ss:[totalDirSize].low, 0

	mov	ss:[recurErrorFlag], 1
	mov	ss:[enteredFileOpRecursion], 0	; no recursion yet
	call	FileSizeAllDir			; size directory (recursively)
	jc	exit				; if error, return error code
	mov	dx, ss:[totalDirSize].high	; else, return size
	mov	ax, ss:[totalDirSize].low
exit:
	.leave
	ret
FileDirGetSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileSizeAllDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get size of directory and all its contents

CALLED BY:	INTERNAL
			FileDirGetSize
			FileSizeAllDir (recursively)

PASS:		ds:dx	= name if directory whose size is desired, in
			  current directory.
		ss:[enteredFileOpRecursion] = 0 when called initially
					    = 1 when recursively called to
						size a file/directory in
						the top-level directory

RETURN:		carry set if error
			ax - error code
		carry clear if no error
			ss:[totalDirSize]  - size updated
		ss:[enteredFileOpRecursion] = 1 if recursively called to
						size a file/directory in
						the top-level directory

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/19/91		Hacked from FileDeleteAllDir

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FSADAttrs	struct
    FSADA_common	FileOperationInfoEntry
    FSADA_size		dword
    FSADA_fileType	GeosFileType
FSADAttrs	ends

fileSizeDirReturnAttrs	FileExtAttrDesc \
	<FEA_NAME,	FSADA_common.FOIE_name,	 size FSADA_common.FOIE_name>,
	<FEA_FLAGS,	FSADA_common.FOIE_flags, size FSADA_common.FOIE_flags>,
	<FEA_FILE_ATTR,	FSADA_common.FOIE_attrs, size FSADA_common.FOIE_attrs>,
	<FEA_SIZE,	FSADA_size,		 size FSADA_size>,
	<FEA_FILE_TYPE,	FSADA_fileType,		 size FSADA_fileType>,
	<FEA_END_OF_LIST>


FileSizeAllDir	proc	near
	uses	bx, ds, dx, si, cx, bp
	.enter

; Allows us to use UtilCheckInfoEntrySubdir
CheckHack	<offset FSADA_common eq 0>

	;
	; Push to the directory to size.
	; 
	call	FilePushDir
	clr	bx
	call	FileSetCurrentPath
	LONG jc	done

	;
	; Enumerate all files and directories in it.
	;
		
	sub	sp, size FileEnumParams
	mov	bp, sp
if FULL_EXECUTE_IN_PLACE
        ;
        ; Copy the iacpLocateServerReturnAttrs table to stack
        ;
        segmov  ds, cs, cx
        mov     si, offset  fileSizeDirReturnAttrs 
        mov     cx, (size FileExtAttrDesc) * (length fileSizeDirReturnAttrs)
        call    SysCopyToStackDSSI
endif
	mov	ss:[bp].FEP_searchFlags, \
			FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS
FXIP<	mov	ss:[bp].FEP_returnAttrs.segment, ds			>
FXIP<	mov	ss:[bp].FEP_returnAttrs.offset, si			>
NOFXIP<	mov	ss:[bp].FEP_returnAttrs.segment, cs			>
NOFXIP<	mov	ss:[bp].FEP_returnAttrs.offset, offset fileSizeDirReturnAttrs >
	mov	ss:[bp].FEP_returnSize, size FSADAttrs
	mov	ss:[bp].FEP_matchAttrs.segment, 0
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum
FXIP<	call    SysRemoveFromStack					>
	jcxz	done
	
	;
	; Lock down the list of files and loop over them all.
	; 
	mov	ss:[enteredFileOpRecursion], 1	; entered recursion-zone
	call	MemLock
	mov	ds, ax
	clr	si
fileLoop:
	call	UtilCheckInfoEntrySubdir
	jc	recurse

	;
	; Not a directory, so just add the file's size into the total.
	; Also account for GeosFileHeader - brianc 7/12/93
	;
	adddw	ss:[totalDirSize], ds:[si].FSADA_size, ax
	cmp	ds:[si].FSADA_fileType, GFT_NOT_GEOS_FILE
	je	nextFile
	adddw	ss:[totalDirSize], 256

nextFile:
	;
	; Advance to the next file and loop if there are more to process.
	; 
	add	si, size FSADAttrs
	loop	fileLoop
	; (carry must be clear, as add to si cannot carry beyond 64K)
finish:
	pushf
	call	MemFree
	popf
done:
	call	FilePopDir
	.leave
	ret

recurse:
	lea	dx, ds:[si].FSADA_common.FOIE_name
	call	FileSizeAllDir
	jc	finish
	jmp	nextFile
FileSizeAllDir	endp

;----------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeleteFileDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete file or directory

CALLED BY:	QTDeleteFiles

PASS:		ds:si - FOIE for thing to delete (file or directory)
		ds:0 - FileQuickTransferHeader
		current dir set to FQTH_diskHandle:FQTH_pathname

RETURN:		carry set if error
		carry clear otherwise
		ax - error code
		ss:[recurErrorFlag] set if recursive operation error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (file to delete is not a directory) {
			FileDelete(source pathname);
		} else {
			for each file X in directory {
				FileDeleteFileDir("source pathname/X");
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeleteFileDir	proc	far
	;
	; clear recursive error flag, note that we don't do this in
	; FileDeleteFirDirCommon as ForceFileDeleteFileDir is called
	; in CopyMoveExistenceCheck, where we don't want to clear
	; recursive error flag - brianc 6/14/93
	;
	mov	ss:[recurErrorFlag], 0
	clr	ax
	call	FileDeleteFileDirCommon
	ret
FileDeleteFileDir	endp

ForceFileDeleteFileDir	proc	far
	mov	ax, mask FDFDCF_OVERRIDE_WARNING
	call	FileDeleteFileDirCommon
	ret
ForceFileDeleteFileDir	endp

FDFDCFlags	record
	FDFDCF_OVERRIDE_WARNING:1,
	:15
FDFDCFlags	end



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeleteFileDirCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a file or directory

CALLED BY:	FileDeleteFileDir, ForceFileDeleteFileDir

PASS:		ax - FDFDCFlags
		ds:00 - FileQuickTransferHeader of FQT block
		ds:si - FileOperationInfoEntry to delete
		current dir is set to the path in the FQTH

RETURN:		if error:
			carry set
			ax - error code
		else
			carry clear 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 1/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeleteFileDirCommon	proc	near
	uses	bx, cx, dx, bp
	.enter

	mov	bp, ax				; store override flag here

	;
	; See if it's a subdirectory, and if so, do special
	; code to delete the directory and all it's contents.
	;

	call	UtilCheckInfoEntrySubdir
	jc	delDirectory

	test	bp, mask FDFDCF_OVERRIDE_WARNING	; override?
	jnz	forceFile				; yes

	mov	ax, WARNING_DELETE_FILE
	test	ds:[si].FOIE_attrs, mask FA_LINK
	jz	haveWarning
	mov	ax, WARNING_DELETE_LINK		; also for subdirs
haveWarning:
	call	DeleteWarningCommon		; warn if desired
	cmp	ax, YESNO_YES			; check if delete
	stc					; assume not
	jne	exit				; if not, exit with AX
forceFile:

if _FCAB
	;File Cabinet: do not allow user to delete one of the all-important
	;default document files:
	;	First Address Book
	;	My Schedule
	;	Default Scrapbook

	call	FileCheckForAllDefaultApplicationDocuments
	mov	ax, YESNO_NO			;pretend that the user
						;did not confirm the deletion.
	jc	exit				;skip to exit if name
						;matched...
endif		; if _FCAB

	clr	ax				; normal handling
	call	FileCheckAndDelete		; else, delete file
	jmp	exit
	;
	; delete directory
	;	ds:dx - source filespec
	;
delDirectory:
	lea	dx, ds:[si].FOIE_name
	call	CheckRootSrcOperation		; can't delete root
	jc	exit

	call	CheckSystemFolderDestruction	; deleting system folder?
	jc	exit				; yes, exit with error
	test	bp, mask FDFDCF_OVERRIDE_WARNING	; override?
	jnz	forceDir			; yes
	mov	ax, WARNING_DELETE_DIR
	call	DeleteWarningCommon	; warn if desired
						; (might turn off progress,
						;	turn back on below)
	cmp	ax, YESNO_YES			; check if delete
	stc					; assume not
	jne	exit				; if not, exit with AX
forceDir:
	mov	ss:[recurErrorFlag], 1
	mov	ss:[enteredFileOpRecursion], 0	; no recursion yet
	mov	ss:[showDeleteProgress], TRUE	; always show progress for DIRs
	call	FileDeleteAllDir		; delete directory (recursively)
exit:
	mov	ss:[showDeleteProgress], TRUE	; ensure progress is enabled
	.leave
	ret
FileDeleteFileDirCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoRemoteFileCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a file is remote, and if it is pops up a 
		dialog informing the user of their options.  This dialog is
		only put up for the first remote file, so check to see if
		it has already been put up before.

CALLED BY:	FileDeleteAllDir, FileCheckAndDelete
		FileCopyMoveDir, FileMoveFile

PASS: 		ds:si	- FileOperationInfoEntry to check

RETURN:		carry SET if file should be treated as read-only

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoRemoteFileCheck	proc	near
	.enter

	test	ds:[si].FOIE_pathInfo, mask DPI_EXISTS_LOCALLY
	jnz	done			; carry is clear

	;
	; File is remote, so make the user choose if they haven't already
	;
	mov	al, ss:[howToHandleRemoteFiles]

	CheckHack <RFBT_NOT_DETERMINED eq 0>

	tst	al
	jz	askUser

returnCarry:
	cmp	al, RFBT_LIKE_NORMAL
	je	done				; carry clear

	stc

done:
	.leave
	ret

askUser:
	mov	ax, WARNING_TREAT_REMOTE_FILES_LIKE_READ_ONLY
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES
	mov	al, RFBT_LIKE_READ_ONLY
	je	gotType
	mov	al, RFBT_LIKE_NORMAL
gotType:
	mov	ss:[howToHandleRemoteFiles], al
	jmp	returnCarry
DoRemoteFileCheck	endp



if _FCAB

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheckForAllDefaultApplicationDocuments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	In File Cabinet -- do not allow deletion of certain
		document files

CALLED BY:

PASS:		ds:dx - filename

RETURN:		carry set if should NOT delete this file

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 1/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCheckForAllDefaultApplicationDocuments	proc	near
	uses	ax, bx, cx, dx, ds, es, si, di, bp
				;documentation for caller is not complete,
				;So I must save everything. (no time!)
	.enter

	mov	bx, handle DOSName_FirstAddressBook	; all strings here
	call	MemLock				; ax = segment
	mov	es, ax				

	mov	di, offset DOSName_FirstAddressBook
	call	FileCheckForDefaultApplicationDocument
	jz	50$				;skip if is that file...

	mov	di, offset DOSName_MySchedule
	call	FileCheckForDefaultApplicationDocument
	jz	50$				;skip if is that file...

	mov	di, offset DOSName_DefaultScrapbook
	call	FileCheckForDefaultApplicationDocument
	jz	50$				;skip if is that file...

	mov	di, offset DOSName_Tetris
	call	FileCheckForDefaultApplicationDocument
	jz	50$				;skip if is that file...

	mov	di, offset DOSName_GeoBanner
	call	FileCheckForDefaultApplicationDocument

50$:	;Z is set if we want to abort file deletion.

	mov	bx, handle DOSName_GeoBanner		; all strings here
	call	MemUnlock			;does not trash flags

	;return CY flag set if the names match

	clc					;assume we did not find name
	jnz	90$				;skip to end if no match...

	;put up an error dialog box

	mov	ax, ERROR_FILE_CABINET_CANNOT_DELETE_FILE	
	call	DesktopOKError
	stc

90$:
	.leave
	ret
FileCheckForAllDefaultApplicationDocuments	endp

FileCheckForDefaultApplicationDocument	proc	near
	mov	di, es:[di]		;es:di = reserved document filename
	ChunkSizePtr	es, di, cx	;cx = size of name to compare against

DBCS <	shr	cx, 1							>
	mov	si, dx			;set ds:si = DOS filename
SBCS <	repe	cmpsb			;repeat compare as long as are equal >
DBCS <	repe	cmpsw			;repeat compare as long as are equal >

	;return Z flag set if the names match
	ret
FileCheckForDefaultApplicationDocument	endp

endif		; if _FCAB


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeleteAllDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete a directory and all its contents

CALLED BY:	INTERNAL
			FileDeleteFileDir
			FileDeleteAllDir (recursively)

PASS:		ds:si	= FileOperationInfoEntry for directory to be
			  recursively deleted
		ds:0	= FileQuickTransferHeader
		current path is that in the FQTH

		ss:[enteredFileOpRecursion] = 0 when called initially
					    = 1 when recursively called to
						delete a file/directory in
						the top-level directory
		ss:[skipDeletingDir] =	0: means delete all files and Dir
				     =	non-zero:means delete all files but do
						NOT delete the directory

RETURN:		carry set if error
			ax - error code
		ss:[enteredFileOpRecursion] = 1 if recursively called to
						delete a file/directory in
						the top-level directory

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeleteAllDir	proc	far
	uses	cx, bx
	.enter

	call	DoRemoteFileCheck
	cmc
LONG	jnc	exit

	push	ds, si				; original FOIE
	push	{word} ss:[enteredFileOpRecursion]	; save this flag

	call	FileEnumDirToFQT		; ds <- FQTH
						; bx <- handle FQTH
	jc	errorInFileEnumDirToFQT

	push	bx				; save FQTH handle

	mov	si, offset FQTH_files		; ds:si <- FOIE to nuke next
	mov	cx, ds:[FQTH_numFiles]
	jcxz	done

getNextFile:
	mov	ss:[enteredFileOpRecursion], 1	; entered recursion-zone

	call	UtilCheckInfoEntrySubdir
	jc	dir
	;
	; if file is a plain file, delete it
	;
	call	SetUpForRecurError
	clr	ax				; normal handling
	call	FileCheckAndDelete		; delete plain file
	jnc	nextFile
	cmp	ax, YESNO_NO			; check if cancel R/O or App
	je	nextFile			; if so, skip this file
	cmp	ax, YESNO_CANCEL
	je	40$

;;allow skipping ACCESS_DENIED errors in recursive delete
	cmp	ax, ERROR_FILE_IN_USE		; file-busy or access denied?
	je	30$				; yes
	cmp	ax, ERROR_ACCESS_DENIED		; file-busy or access denied?
	je	30$
	cmp	ax, ERROR_SHARING_VIOLATION
	jne	40$				; nope, return error
30$:
	mov	ax, WARNING_RECURSIVE_ACCESS_DENIED
	;
	; If we're shutting down, we need to continue without trying
	; to warn the user; doing otherwise results in deadlock, since
	; the UI's ShutdownStatusBox has the focus. -jenny 6/1/93
	;
	cmp	ss:[loggingOut], TRUE
	je	nextFile
	call	DesktopYesNoWarning		; ask user if we should continue
	cmp	ax, YESNO_YES			; should we?
	je	nextFile			; if so, skip this file
						; else return YESNO_NO
40$:
	stc					; indicate error
	jmp	done				; ret. error from FileDelete
						; (also catches DESK_DB_DETACH
						;	and YESNO_CANCEL)
	;
	; delete directory, recursively call ourselves
	;
dir:
	call	FileDeleteAllDir
	jc	done				; catch err in FileDeleteAllDir

nextFile:
	add	si, size FileOperationInfoEntry
	loop	getNextFile

done:
	pop	bx				; restore FQTH handle
	pushf					; save delete results
	call	MemFree				; free the thing
	popf					; restore delete results

	call	FilePopDir			; pop dir pushed in
						;  FileEnumDirToFQT
errorInFileEnumDirToFQT:
	pop	bx				; enteredFileOpRecursion
						;  from beginning of routine
	pop	ds, si				; original FOIE
	jc	exit				; don't delete containing dir
						;  if error
	tst	bl
	jnz	deleteDir			; if enteredFileOpRecursion is
						; set, delete dir anyway
	tst	ss:[skipDeletingDir]
	jnz	exit				; don't delete containing dir

deleteDir:
	call	SetUpForRecurError
	call	FileDeleteDirWithError		; else, delete source directory
						;	which is now empty
exit:
	.leave
	ret
FileDeleteAllDir	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileDeleteDirWithError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the directory whose FOIE is passed, updating the
		progress indicator.

CALLED BY:	FileDeleteAllDir, FileCopyMoveDir
PASS:		ds:si	= FileOperationInfoEntry
		fileOperationInfoEntryBuffer - 32 and 8.3 name info
RETURN:		carry set on error:
			ax	 = error code
DESTROYED:	dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/28/92		Initial version
	dlitwin 4/27/93		added checks for readonly directories

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileDeleteDirWithError	proc	near
	uses	bx, si, cx
	.enter

	clr	bx				; non overwrite update
	call	UpdateProgressCommon
	jc	exit				; if CANCEL, exit w/AX
	lea	dx, ds:[si].FOIE_name
deleteIt:
	call	FileDeleteDir
	jnc 	exit

	cmp	ax, ERROR_ACCESS_DENIED		; something read-only?
	jne	error				; no, return whatever error
						;  we've got

	call	FileGetAttributes		; get attributes so we can
						;  modify them
	test	cx, mask FA_RDONLY		; make sure it's the file that's
						;  read-only
	jz	error				; file not R/O => nothing
						;  we can do to delete it.
	;
	; check if we are exiting GEOS, in which case this is a result
	; of emptying the Wastebasket, and so we don't want to warn people
	;
	cmp	ss:[loggingOut], TRUE
	je	forceDelete

	call	DeleteReadOnlyWarning

	cmp	ax, YESNO_YES			; deletion confirmed?
	jne	error				; unconfirmed, return error

forceDelete:
	andnf	cx, not (mask FA_RDONLY or mask FA_SUBDIR) ; we can't just go
	call	FileSetAttributes			; setting the subdir bit
	jmp	deleteIt

error:
	cmp	ss:[loggingOut], TRUE
	clc					; if we are logging out, we
	je	exit				;   can't put up a dialog, so we
	stc					;   just don't tell the user...
exit:
	.leave
	ret
FileDeleteDirWithError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCheckAndDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns error if file is busy, else deletes file

CALLED BY:	INTERNAL

PASS:		ds:si = FileOperationInfoEntry of file to delete
		ax = FileCheckAndDeleteFlags
			FCADF_OVERRIDE_RO - force deletion of R/O files
		current path set to that holding the file to delete

RETURN:		carry set if error
			ax - error code
				YESNO_NO if user doesn't want R/O or App
							file deletion
				DESK_DB_DETACH if detach while box is up
				YESNO_CANCEL if user cancels
				ERROR_ACCESS_DENIED if file busy

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCheckAndDelete	proc	near
	uses	bx, cx

fileCheckAndDeleteFlags	local	word	push	ax

	.enter

	call	DoRemoteFileCheck
	cmc
	jnc	done

	;
	; When showing progress set up a null destination in case this
	; FileCheckAndDelete is being called to overwrite an existing file
	; during a move or copy.  In this case, fileOpProgressType is going
	; to be FOPT_MOVE or FOPT_COPY, so UpdateProgressCommon will try to
	; update the destination name. - brianc 12/2/92
	;

	push	es, di
NOFXIP <segmov	es, cs						>
NOFXIP <mov	di, offset nullProgressPath			>
	clr	bx				; non overwrite update
FXIP <	push	bx						>
FXIP <	segmov	es, ss, di					>
FXIP <	mov	di, sp		;esdi = null str on stack	>
	call	UpdateProgressCommon
FXIP <	pop	di						>
	pop	es, di
	jc	done				; if CANCEL, exit w/AX

if (not _FCAB and not _ZMGR)
	cmp	ss:[loggingOut], TRUE
	je	notApp

	cmp	ds:[si].FOIE_type, GFT_EXECUTABLE
	jne	notApp
	push	bx, si, cx, bp
GM<	mov	bx, handle OptionsDeleteWarnings	>
GM<	mov	si, offset OptionsDeleteWarnings	>
ND<	mov	bx, handle OptionsList	>
ND<	mov	si, offset OptionsList	>
	mov	cx, mask OMI_CONFIRM_EXECUTABLE
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall			; carry set if selected
	pop	bx, si, cx, bp

	jnc	notApp				; if no check, skip this code
	mov	ax, WARNING_DELETING_APPLICATION
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES
	jne	done
endif		; if ((not _FCAB) and (not _ZMGR) and (not _NIKE))

notApp:
	lea	dx, ds:[si].FOIE_name
	call	FileDelete
	jnc	done
	cmp	ax, ERROR_FILE_IN_USE
	jne	checkRO
inUse:
	mov	ax, ERROR_ACCESS_DENIED

if TRY_CLOSE_ON_IN_USE_ERROR		; to support deleting of in-use file
	push	cx
	mov	cx, 0				; try to close file
	call	TryCloseOrSaveFile
	pop	cx
	jc	done				; couldn't close
	call	FileDelete
	jmp	short done			; can't be R/O error here,
						;	that's detected above
endif

error:
	stc
done:
	.leave
	ret		; <-- EXIT HERE

checkRO:
	cmp	ax, ERROR_SHARING_VIOLATION
	je	inUse

	cmp	ax, ERROR_ACCESS_DENIED		; something read-only?
	jne	error				; no, return whatever error
						;  we've got

	call	FileGetAttributes		; get attributes so we can
						;  modify them
	test	cx, mask FA_RDONLY		; make sure it's the file that's
						;  read-only
	jnz	askUser				; file is R/O => ask user if
						;  we want to delete it.
	test	cx, mask FA_LINK		; see if this is a link
	jz	error				; if not, just set carry --
						; nothing we can do.
	mov	ax, ERROR_ACCESS_DENIED		; if so, it's likely the
	jmp	error				; @dirname.000 file is
						; read-only, but not the link.
						; Return ACCESS_DENIED.
askUser:
	;
	; See if the user wants to force deletion of read-only files
	;

	test	ss:[fileCheckAndDeleteFlags], mask FCADF_OVERRIDE_RO
	jnz	forceDelete

	cmp	ss:[loggingOut], TRUE
	je	forceDelete

	call	DeleteReadOnlyWarning

	cmp	ax, YESNO_YES			; deletion confirmed?
	jne	error				; unconfirmed, return error

forceDelete:
	andnf	cx, not mask FA_RDONLY
	call	FileSetAttributes
	jmp	notApp

FileCheckAndDelete	endp

if not _FXIP
SBCS <nullProgressPath	char	0					>
DBCS <nullProgressPath	wchar	0					>
endif

FileCheckAndDeleteFlags	record
	FCADF_OVERRIDE_RO:1,
	:15
FileCheckAndDeleteFlags	end


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCreateDirWithError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calls FileCreateDir and maps bogus error to a less bogus
		error

CALLED BY:	DesktopEndCreateDir
		FileCopyMoveDir

PASS:		ds:dx = directory to create
		current directory set to place in which to create dir

RETURN:		carry clear if no error
		carry set if error
			ax = ERROR_CANT_CREATE_DIR

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/13/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileCreateDirWithError	proc	far
	.enter

	call	FileCreateDir
	jnc	exit				; no error, done
	cmp	ax, ERROR_ACCESS_DENIED
	jne	done				; not our error
	mov	ax, ERROR_CANT_CREATE_DIR	; else, assume this error
done:
	stc					; make sure error is indicated
exit:
	.leave
	ret
FileCreateDirWithError	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileRootGetAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	if root directory passed, return valid attributes, else
		call DOS to get file attributes

CALLED BY:	EXTERNAL

PASS:		ds:dx = file name

RETURN:		carry set if error
			ax = error code
		carry clear if no error
			cx = attributes

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/26/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileRootGetAttributes	proc	far
	uses	si
	.enter

	mov	cx, mask FA_SUBDIR		; assume root
	mov	si, dx				; ds:si = name
if DBCS_PCGEOS
EC <	cmp	{wchar} ds:[si][2], ':'		; drive letter		>
else
EC <	cmp	{byte} ds:[si]+1, ':'		; drive letter		>
endif
EC <	ERROR_Z	DRIVE_LETTER_NOT_ALLOWED	; not allowed!		>
	cmp	{word} ds:[si], '\\'		; '\' + null ?
	jne	notRoot
DBCS <	cmp	{wchar}ds:[si][2], 0					>
DBCS <	jne	notRoot							>
	clc					; indicate success
	jmp	short done
notRoot:
	call	FileGetAttributes		; call DOS
done:
	.leave
	ret
FileRootGetAttributes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileIsFileADirectory?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether the passed file is a directory

CALLED BY:	INTERNAL

PASS:		ds:dx - pathname

RETURN:		carry set if directory
		carry clear otherwise (either a file, a link to a
			directory, or some error occurred, and we
			can't tell)

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileIsFileADirectory?	proc near
	uses	cx,di,es
	.enter

	call	FileRootGetAttributes
	cmc
	jnc	done

	test	cx, mask FA_LINK
	jnz	done

	test	cx, mask FA_SUBDIR
	jz	done			; (carry clear)
	stc
done:
	.leave
	ret

FileIsFileADirectory?	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteWarningCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	warning user about deleting file, if needed

CALLED BY:	INTERNAL
			FileDeleteFileDir

PASS:		ds:si - FileOperationInfoEntry
		ax = DesktopWarnings:	WARNING_DELETE_FILE,
					WARNING_THROW_AWAY_FILE,
					WARNING_DELETE_DIR,
					WARNING_THROW_AWAY_DIR

RETURN:		ax = YESNO_YES (yes, delete file)
			or YESNO_NO (no, don't delete)
			or YESNO_CANCEL (user cancelled operation)
			or DESK_DB_DETACH (detaching application)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/22/89		Initial version
	dlitwin	5/27/92		added support for throw away
	chrisb	12/92		added single-file check

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteWarningCommon	proc	far
	uses	bx, cx, dx, ds, si, es, di, bp

	.enter

EC <	call	ECCheckFileOperationInfoEntry	>

	mov	bp, ax				; warning code
	;
	; check if "Confirm Delete" is set
	;
if (not _FCAB and not _ZMGR)
ND<	push	bp				; preserve warning code >
ND<	mov	bx, handle FileDeleteOptionsGroup	>
ND<	mov	si, offset FileDeleteOptionsGroup	>
ND<	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	>
ND<	call	ObjMessageCall				>
ND<	cmp	ax, OCDL_FULL				>
ND<	mov	ax, YESNO_YES			; in case option not set >
ND<	pop	bp				; restore warning code	>
ND<	jne	exit					>

GM<	push	bp				; preserve warning code >
GM<	mov	bx, handle OptionsDeleteWarnings 	>
GM<	mov	si, offset OptionsDeleteWarnings	>
GM<	mov	cx, mask OMI_MULTIPLE_WARNINGS		>
GM<	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED >
GM<	call	ObjMessageCall				>
GM<	mov	ax, YESNO_YES			; in case option not set >
GM<	pop	bp				; restore warning code	>
GM<	jnc	exit					>
endif		; if ((not _FCAB) and (not _ZMGR) and (not _NIKE))

	;
	; take down progress box as we are about to prompt to delete file,
	; meaning that progress box will not be needed for that file
	; - only done if delete file warning (not delete dir warning)
	;
	cmp	bp, WARNING_DELETE_FILE
	jne	80$
	cmp	bp, WARNING_THROW_AWAY_FILE
	jne	80$
	call	RemoveFileOpProgressBox
80$:
	;
	; put up warning
	;
	mov	ss:[showDeleteProgress], FALSE	; no progress if we have
						;	confirmation-per-file
	mov	ax, bp				; warning code
	;
	; If there's only one file in the quick transfer block, then
	; make sure we don't put up a "Skip" trigger.
	;

	cmp	ds:[FQTH_numFiles], 1
	ja	gotFlags
	ornf	ax, mask DWF_NO_SKIP_TRIGGER

gotFlags:

	call	DesktopYesNoWarning
if (not _FCAB and not _ZMGR)
exit:
endif
	.leave
	ret
DeleteWarningCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteReadOnlyWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	warning user about deleting read-only file, if needed

CALLED BY:	INTERNAL
			FileCheckAndDelete

PASS:		fileOperationInfoEntryBuffer - 32 and 8.3 name info

RETURN:		ax = YESNO_YES (yes, delete read-only file)
			or YESNO_NO (no, don't delete)
			or YESNO_CANCEL (user cancelled operation)
			or DESK_DB_DETACH (detaching application)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteReadOnlyWarning	proc	near
	push	bx, cx, dx, ds, si, es, di, bp
	;
	; check if "Confirm Read-Only Delete" is set
	;
if (not _FCAB and not _ZMGR)
GM<	mov	bx, handle OptionsDeleteWarnings	>
GM<	mov	si, offset OptionsDeleteWarnings	>
ND<	mov	bx, handle OptionsList	>
ND<	mov	si, offset OptionsList	>
	mov	cx, mask OMI_CONFIRM_READ_ONLY
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall			; carry if set
else
	stc					; "Confirm" is always on
endif		; ((not _FCAB) and (not _ZMGR) and (not _NIKE))
	mov	ax, YESNO_YES			; in case, option not set

	jnc	DROW_exit			; if not, exit
	;
	; put up warning
	;
	mov	ax, WARNING_DELETE_READONLY
	call	DesktopYesNoWarning
DROW_exit:
	pop	bx, cx, dx, ds, si, es, di, bp
	ret
DeleteReadOnlyWarning	endp


if (not _FCAB and not _ZMGR)
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReplaceWarning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	warning user about replacing existing file on a file copy,
		if needed

CALLED BY: 	CopyMoveFileToDir

PASS:		ds:dx = filename of destination file copy
		fileOperationInfoEntryBuffer - 32 and 8.3 source name info

RETURN:		ax = YESNO_YES (yes, replace file)
			or YESNO_NO (no, don't replace)
			or YESNO_CANCEL (user cancelled operation)
			or DESK_DB_DETACH (detaching application)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/25/89		Initial version
	dlitwin	5/22/92		Revised for Wastebasket Checks,made near routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReplaceWarning	proc	near
	uses	bx, cx, si, es, di, bp
	.enter

		; check if we are overwriting a Wastebasket file
	mov	ax, WARNING_REPLACE_WASTEBASKET_FILE	; assume so
	cmp	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET
	jne	warnUser			; ALWAYS warn if so

	mov	ax, WARNING_REPLACE_32_FILE	; "not waste basket" code

		; check if "Confirm on Replace" is set
	push	ax				; save warning code
	push	ds, dx
GM<	mov	bx, handle OptionsWarnings	>
GM<	mov	si, offset OptionsWarnings	>
ND<	mov	bx, handle OptionsList	>
ND<	mov	si, offset OptionsList	>
	mov	cx, mask OMI_CONFIRM_REPLACE
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall			; carry set if item set


	pop	ds, dx
	pop	ax				; retrieve warning code
	jc	warnUser			; if option set, warning user

	mov	ax, YESNO_YES			; else, user wants to replace
	jmp	RW_exit

warnUser:
		; put up warning
	call	DesktopYesNoWarning

RW_exit:
	.leave
	ret
ReplaceWarning	endp

endif		; if ((not _FCAB) and (not _ZMGR) and (not _NIKE))


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckRoot{Src,Dest}Operation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if operation is about to be performed on root
		directory.  If so, return and signal error.

CALLED BY:	INTERNAL
			FileDeleteFileDir
			RenameWithOverwrite
			CopyMoveFileToDir

PASS:		ds:dx = source name (CheckRootSrcOperation)
		es:di = destination name (CheckRootDestOperation)

RETURN:		carry set if error
			AX - error code
		carry clear if no error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckRootSrcOperation	proc	far
	push	si
	mov	si, dx				; ds:si = source
if DBCS_PCGEOS
EC <	cmp	{wchar} ds:[si]+2, ':'		; no drive letters allowed!!>
else
EC <	cmp	{byte} ds:[si]+1, ':'		; no drive letters allowed!!>
endif
EC <	ERROR_Z	DRIVE_LETTER_NOT_ALLOWED				>
	lodsw
	cmp	ax, '\\'			; '\' (al) and null (ah)
	jne	okay
DBCS <	lodsw								>
DBCS <	tst	ax				; NULL?			>
DBCS <	jnz	okay							>
	mov	ax, ERROR_ROOT_FILE_OPERATION	; else, error
	stc
	jmp	short done
okay:
	clc
done:
	pop	si
	ret
CheckRootSrcOperation	endp

CheckRootDestOperation	proc	far
	push	ds, dx
	segmov	ds, es, dx			; ds:dx = dest.
	mov	dx, di
	call	CheckRootSrcOperation		; use src. routine
	pop	ds, dx
	ret
CheckRootDestOperation	endp
FileOpLow	ends
