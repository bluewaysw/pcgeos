COMMENT @----------------------------------------------------------------------
	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		cfolderMisc.asm
AUTHOR:		Brian Chin


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cfolderClass.asm

DESCRIPTION:
	This file contains folder display object.

	$Id: cfolderMisc.asm,v 1.3 98/06/03 13:34:53 joon Exp $

------------------------------------------------------------------------------@

FolderPathCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Save the path and disk handle

PASS:		*ds:si	- FolderClass object
		es	- segment of FolderClass
		
		cx:dx	- fptr to path
		bp	- disk handle

RETURN:		carry	- set on error
			- clear if OK

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	Initial version.
	dlitwin	11/14/92	made it return carry set on error, mainly
				so the NDDriveClass subclass object knows
				to do its special stuff
	dlitwin	12/31/92	no longer sets the primary's moniker, this
				is now handled elsewhere.
	dlitwin 01/14/93	Sets its own internal remote flag

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSetPath	method	dynamic	FolderClass, 
					MSG_FOLDER_SET_PATH
	.enter

	mov	es, cx
	mov	di, dx
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathSetObjectPath
	jc	closeError

	push	ds, si
	segmov	ds, es
	mov	si, di				; ds:si - passed path
	call	ShellAllocPathBuffer		; es:di - path buffer
	mov	bx, bp
	clr	dx
	mov	cx, size PathName
	call	FileConstructActualPath
	pop	ds, si

	;
	; We should never get an error here, because the first call to
	; GenPathSetObjectPath would have returned an error, but it
	; HAS happened, so...
	;
	jc	afterSetActual

	;
	; See if this is the wastebasket, or any children thereof
	; (actual disk handle is SP_WASTE_BASKET) 
	;
	push	di
	call	FileParseStandardPath
	pop	di
	cmp	ax, SP_WASTE_BASKET
	jne	afterWasteBasket

	push	di
	mov	ax, MSG_DESKTOP_VIEW_SET_INITIAL_BG_COLOR
	mov	cl, WASTEBASKET_BACKGROUND
	clr	di
	call	FolderCallView
	pop	di

afterWasteBasket:

	call	FolderSetRemoteFlag

	mov	ax, ATTR_FOLDER_ACTUAL_PATH
	mov	dx, TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE
	mov	bp, bx

	DerefFolderObject	ds, si, bx
	mov	ds:[bx].FOI_actualDisk, bp

	call	GenPathSetObjectPath

afterSetActual:
	call	ShellFreePathBuffer
	jc	closeError

	;
	; If all is well, store drive number of disk
	;
	mov	bx, bp				; bx = disk handle
	call	DiskGetDrive			; al = drive number
	mov	dl, al				; dl = drive number
	mov	ax, TEMP_FOLDER_DRIVE		; don't save to state
	mov	cx, size byte
	call	ObjVarAddData
	mov	{byte} ds:[bx], dl
	clc					; indicate no error

done:
	.leave
	ret					; <====  EXIT HERE

closeError:
	call	FolderSendCloseViaQueue
	stc						; indicate an error
	jmp	done

FolderSetPath	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetRemoteFlag
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get the remote status of this directory and cache it.

PASS:		*ds:si	- FolderClass object
		es:di	- path of folder
		bx	- diskhandle of path

RETURN:		carry	- set on error
				ax = error message
			- clear if OK

DESTROYED:	ax, cx, dx

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin 01/14/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSetRemoteFlag	proc	near
	class	FolderClass
dirPathInfo	local	DirPathInfo
	uses	bx, si, di, es
	.enter

	call	FilePushDir
	push	ds, si
	segmov	ds, cs, dx
	mov	dx, offset rootDir		; ds:dx is a root
			CheckHack <segment rootDir eq @CurSeg>
	call	FileSetCurrentPath
	pop	ds, si
	jc	exit

	push	ds, si
	segmov	ds, es, dx
	mov	dx, di				; ds:dx is folder path
	segmov	es, ss, di
	lea	di, ss:[dirPathInfo]		; es:di is buffer
	mov	cx, size DirPathInfo
	mov	ax, FEA_PATH_INFO
	call	FileGetPathExtAttributes
	pop	ds,si
	jc	exit

	DerefFolderObject	ds, si, si
	clr	ds:[si].FOI_remoteFlag		; default to file being local
	test	es:[di], mask DPI_EXISTS_LOCALLY
	jnz	exit
	mov	ds:[si].FOI_remoteFlag, -1	; else file is remote
exit:
	call	FilePopDir

	.leave
	ret
FolderSetRemoteFlag	endp

LocalDefNLString rootDir <C_BACKSLASH, 0>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderEnsurePathIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the object has the array of 32-bit IDs and disk
		handles for its path

CALLED BY:	FolderScan, FolderCheckFileID

PASS:		*ds:si	= Folder object
		CWD set to folder's directory

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/21/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderEnsurePathIDs proc	near
	class	FolderClass
	uses	cx,dx,bp
	.enter

	mov	ax, TEMP_FOLDER_PATH_IDS
	call	ObjVarFindData
	cmc
	LONG jnc	done

	call	FileGetCurrentPathIDs		; *ds:ax <- array o' ids
	LONG	jc	done			; not ok

	call	FolderCompareActualAndLogicalPaths
	je	copyIDs
	;
	; The actual and logical paths differ, so we were reached by a link
	; somewhere. Fetch the ID for the logical path.
	; 

	push	ax

	;
	; Push to root of disk holding logical path.
	; 
	call	FilePushDir

	push	bx, dx, ds
	mov	bx, ds:[bx].GFP_disk
	segmov	ds, cs
	mov	dx, offset rootPath
	call	FileSetCurrentPath
	pop	bx, dx, ds
	;
	; Set up structures for fetching the components of a file ID
	; 
	sub	sp, size FileID + size word + 2 * size FileExtAttrDesc
	mov	bp, sp
	mov	ss:[bp].FEAD_attr, FEA_DISK
	mov	ss:[bp].FEAD_size, size word
	mov	ss:[bp].FEAD_value.segment, ss
	lea	ax, ss:[bp+2*size FileExtAttrDesc]
	mov	ss:[bp].FEAD_value.offset, ax

	mov	ss:[bp+FileExtAttrDesc].FEAD_attr, FEA_FILE_ID
	mov	ss:[bp+FileExtAttrDesc].FEAD_size, size FileID
	mov	ss:[bp+FileExtAttrDesc].FEAD_value.segment, ss
	inc	ax
	inc	ax
	mov	ss:[bp+FileExtAttrDesc].FEAD_value.offset, ax
	;
	; Fetch them.
	; 
	push	es
	segmov	es, ss		; es:di <- array of descriptors
	mov	di, bp
	mov	cx, 2		; cx <- 2 of them
	mov	ax, FEA_MULTIPLE
	lea	dx, ds:[bx].GFP_path	; ds:dx <- path whose attrs are wanted
	call	FileGetPathExtAttributes
	pop	es

	call	FilePopDir

	;
	; Clear the stack, fetching the ID and the chunk holding the other
	; IDs
	; 
	lea	sp, ss:[bp+2*size FileExtAttrDesc]
	pop	bx			; bx <- disk handle
	popdw	cxdx			; cxdx <- ID
	pop	ax			; ax <- chunk
	jc	doneFreeIDs
	
	;
	; Make room for another ID at the start of the array (easiest place
	; to put it.
	; 
	push	bx, cx
	clr	bx
	mov	cx, size FilePathID
	call	LMemInsertAt
	pop	bx, cx
	;
	; And store the ID there.
	; 
	mov	di, ax
	mov	di, ds:[di]
	mov	ds:[di].FPID_disk, bx
	movdw	ds:[di].FPID_id, cxdx

copyIDs:
	mov_tr	di, ax				; save handle
	ChunkSizeHandle ds, di, cx		; cx <- # bytes needed to
						;  store the thing
	
	mov	ax, TEMP_FOLDER_PATH_IDS	; don't save to state, as we
						;  need to build this for each
						;  session
	call	ObjVarAddData			; ds:bx <- place to store ids
	push	si, di, es
	mov	si, ds:[di]			; ds:si <- source
	mov	di, bx
	segmov	es, ds				; es:di <- dest
	rep	movsb
	pop	si, ax, es
	call	LMemFree			; free array
	
	;
	; Now add ourselves to the general-change list for the file system.
	; 
	call	UtilAddToFileChangeList

done:
	.leave
	ret

doneFreeIDs:
	call	LMemFree
	stc
	jmp	done

LocalDefNLString rootPath <C_BACKSLASH, 0>
FolderEnsurePathIDs endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCompareActualAndLogicalPaths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the folder's actual and logical paths are the
		same

CALLED BY:	FolderEnsurePathIDs, FolderDerefAncestorList

PASS:		*ds:si - folder object

RETURN:		ZF set for branching as you'd expect

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCompareActualAndLogicalPaths	proc far
		uses	ax,si,es

		.enter

		mov	ax, ATTR_FOLDER_ACTUAL_PATH
		call	ObjVarFindData
		lea	di, ds:[bx].GFP_path
		mov	ax, ATTR_FOLDER_PATH_DATA
		call	ObjVarFindData
		segmov	es, ds
		lea	si, ds:[bx].GFP_path
compareLoop:
		lodsb
		scasb
		jne	compareDone
		tst	al
		jnz	compareLoop

compareDone:
		.leave
		ret
FolderCompareActualAndLogicalPaths	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read current directory, build list of files therein

CALLED BY:	MSG_SCAN

PASS:		*ds:si - FolderClass object
		ds:di - FolderClass instance data
		dx:bp - pathname for new directory (dx = 0 => no change)

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		MSG_INIT must have been sent and processed before
			MSG_SCAN can be processed (the folder
			window's block handle is needed).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/17/89		Initial version
	brianc	8/10/89		changed to use display list
	brianc	9/18/89		changed to use resizable folder buffer
	martin	11/15/92	added a header to the folder buffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _FXIP
TableResourceXIP	segment resource
endif

folderScanReturnAttrs	FileExtAttrDesc	\
	<FEA_FILE_ATTR, 	offset FR_fileAttrs, 	size FR_fileAttrs>,
	<FEA_NAME, 		offset FR_name, 	size FR_name>,
	<FEA_FILE_TYPE, 	offset FR_fileType, 	size FR_fileType>,
	<FEA_CREATOR, 		offset FR_creator, 	size FR_creator>,
	<FEA_TOKEN, 		offset FR_token, 	size FR_token>,
	<FEA_PATH_INFO, 	offset FR_pathInfo, 	size FR_pathInfo>,
	<FEA_SIZE, 		offset FR_size, 	size FR_size>,
	<FEA_MODIFICATION,	offset FR_modified, 	size FR_modified>,
	<FEA_CREATION, 		offset FR_created, 	size FR_created>,
	<FEA_FILE_ID, 		offset FR_id, 		size FR_id>,
	<FEA_GEODE_ATTR,	offset FR_geodeAttrs,	size FR_geodeAttrs>,
	<FEA_FLAGS,		offset FR_fileFlags,	size FR_fileFlags>,
	<FEA_DISK,		offset FR_disk,		size FR_disk>,
	<FEA_TARGET_FILE_ID,	offset FR_targetFileID,	size FR_targetFileID>

if _NEWDESK
FileExtAttrDesc <FEA_DESKTOP_INFO, offset FR_desktopInfo, size FR_desktopInfo>
endif		; if _NEWDESK

NUM_RETURN_ATTRS equ ($-folderScanReturnAttrs)/size FileExtAttrDesc
FileExtAttrDesc	<FEA_END_OF_LIST>

if _FXIP
TableResourceXIP	ends
endif

folderScanParams	FileEnumParams <
	FILE_ENUM_ALL_FILE_TYPES 		\
		or mask FESF_DIRS 	 	\
		or mask FESF_LEAVE_HEADER,	 	; FEP_searchFlags
	folderScanReturnAttrs,				; FEP_returnAttrs
	size FolderRecord,				; FEP_returnSize
	0,						; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,				; FEP_bufSize
	0,						; FEP_skipCount
	0,						; FEP_callback
	0,						; FEP_callbackAttrs
	0,						; FEP_cbData1
	0,						; FEP_cbData2
	size FolderBufferHeader				; FEP_headerSize
>

FolderScan	method	dynamic FolderClass, MSG_SCAN
	.enter

	call	FilePushDir
	call	ShowHourglass

	test	ds:[di].FOI_folderState, mask FOS_BOGUS	; will be closed?
	jnz 	exit				; yes, do nothing
	ornf	ds:[di].FOI_folderState, mask FOS_SCANNED
	mov	ds:[di].FOI_displayList, NIL	; no files yet
	mov	ds:[di].FOI_selectList, NIL	; none here either
	mov	ds:[di].FOI_cursor, NIL		; none here either
	mov	ds:[di].FOI_fileCount, 0	; ditto

	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jc	closeError

	;
	; Make sure we have array of IDs for this path.
	; 
	call	FolderEnsurePathIDs
	jc	closeError

	;
	; first, set up volume name and disk ID for floppy nonsense
	; (also get free space on disk)
	;
	push	si
	call	Folder_GetActualDiskAndPath	; ax <- disk handle

	DerefFolderObject	ds, si, si
	add	si, offset FOI_diskInfo		; ds:si = disk info fields
	mov_tr	bx, ax
	call	GetVolumeNameAndFreeSpace	; fill in other disk
						; info fields
	pop	si
	jnc	noError
closeError:
	call	FolderSendCloseViaQueue		; error, close us up
exit:
	; update the number of files open
	mov	ax, ds:[di].FOI_fileCount
	add	ss:[numFiles], ax
	call	HideHourglass
	call	FilePopDir
	.leave
	ret			; <--- EXIT HERE ALSO

noError:
	DerefFolderObject	ds, si, di 

	;
	; Clear out FOI_buffer and free any previous buffer.
	; 
	clr	bx
	xchg	ds:[di].FOI_buffer, bx	; in case no files
	tst	bx
	jz	doEnum
	call	MemFree
doEnum:
	; XXX: include search pattern if defined

	push	ds, si, di
	segmov	ds, cs
	mov	si, offset folderScanParams
	call	FileEnumPtr		; bx <- buffer, cx <- # found,
					; dx <- # missed
	pop	ds, si, di

	jc	badError
	tst	dx			; miss any?
	jz	haveBuffer		; no

	push	bx, cx, dx		; save buffer et al
	mov	ax, ERROR_TOO_MANY_FILES
	call	DesktopOKError		; notify user
	pop	bx, cx, dx
	clc
	jmp	haveBuffer		; and go deal with those we did find

badError:
	call	DesktopOKError
	jmp	exit


haveBuffer:
;	jcxz	exit				; if no files, then done
;even though there are no files, call FolderLoadDirInfo to set up scrollbars
;in our GenView - brianc 6/18/93
	jcxz	noFiles
	mov	ds:[di].FOI_buffer, bx


	call	ProcessFiles			; process these files
	jc	badError			; if error, handle it

noFiles:
	;
	; all files are in folder buffer; now build list of files to display
	; according to options the user has set
	;

	call	FolderLoadDirInfo

	;
	; Call the NewDesk-specific file processing AFTER building the
	; display list
	;

ND <	call	NDFolderProcessFiles				>
		
	jmp	exit

FolderScan	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set initial settings for each FolderRecord

CALLED BY:	INTERNAL
			FolderScan

PASS:		*ds:si	= FolderClass object
		ds:di	= FolderClass instance data
		bx	= handle of buffer holding FolderRecord structures
			  created by FileEnum
		cx	= number of files in the buffer

RETURN:		carry clear	
			FOI_fileCount set
			FOI_bufferSize set

		preserves ax, ds, si, es

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/18/89		Initial version
	martin	11/23/92	Added FolderBufferHeader

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessFiles	proc	near
		class	FolderClass
		uses	ax, di, si, es
		.enter
		push	ds, di


	;
	; Fetch the actual disk handle
	;
		mov	bp, ds:[di].FOI_actualDisk
		mov	ds:[di].FOI_fileCount, cx
 		segmov	es, ds, ax
		call	MemLock
		mov	ds, ax

	;
	; Initialize FolderBufferHeader
	;

		mov	ds:[FBH_handle], bx
		mov	ax, es:[LMBH_handle]
		movdw	ds:[FBH_folder], axsi

		mov	si, offset FBH_buffer	; ds:si = file buffer buffer

	;
	; Initialize FolderRecords returned by FileEnumPtr
	;
		
PF_loop:
		mov	ds:[si].FR_invPos, cx	; store counter as
						; inverted pos. 

		mov	ds:[si].FR_state, mask FRSF_UNPOSITIONED

ND<		call	BuildPathAndGetNewDeskObjectType		>

		mov	ds:[si].FR_trueDH, bp	; set true dh to that of parent
		test	ds:[si].FR_fileAttrs, mask FA_LINK
		jz	gotTrueDiskHandle

		clr	ds:[si].FR_trueDH	; if link, this will be
						;   determined later
gotTrueDiskHandle:

	;
	; If this is a GEOS file, add 256 to its file size - brianc 7/12/93
	;
if not _NEWDESK
		test	ds:[si].FR_fileAttrs, mask FA_SUBDIR or mask FA_LINK
		jnz	afterSize		; leave subdir alone
		cmp	ds:[si].FR_fileType, GFT_NOT_GEOS_FILE
		je	afterSize		; leave non-GEOS alone
		adddw	ds:[si].FR_size, 256
afterSize:
endif

		add	si, size FolderRecord	; move to next tree
						; buffer entry
		loop	PF_loop			; go back to process all files


		mov	di, si
		pop	ds, si			; ds:si = Folder instance

	;
	; Save important FolderBuffer information
	;

		mov	ds:[si].FOI_bufferSize, di	; and overall size
		call	MemUnlock			; unlock folder buffer


		clc
		.leave
		ret

ProcessFiles	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compare the passed path to this folder's path

CALLED BY:	MSG_FOLDER_CHECK_PATH

PASS:		dx:bp - pathname to compare with
		cx - disk handle to compare with

RETURN:		carry clear if pathnames are the same
			ax	= 0
		carry set if pathnames are different
			ax	= 0 if folder instance is a subdirectory of
					the passed pathname
				= non-zero if passed pathname is unrelated to
				  folder's

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/8/89		Initial version
	dlitwin	5/21/92		updated for 2.0 and new FileParseStandardPath
	dlitwin	10/25/92	updated to work with file system links

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckPath	method	dynamic FolderClass, MSG_FOLDER_CHECK_PATH

	uses	cx, bx, dx, bp, si, di, ds, es
	.enter

	push	dx
	mov	ax, ATTR_FOLDER_ACTUAL_PATH
	mov	dx, TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath
	pop	dx

	segmov	es, ds, di
	lea	di, ds:[bx].GFP_path
	xchg	dx, ax				; dx, es:di is the folder's path
	mov	ds, ax
	mov	si, bp				; cx, ds:si is passed path
	call	FileComparePaths

	cmp	al, PCT_EQUAL
	je	done				; carry is clear

	cmp	al, PCT_SUBDIR
	mov	ax, 0				; clear AX w/o munging flags
	stc
	je	done
	dec	ax				; don't munge carry
done:
	.leave
	ret
FolderCheckPath	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get folder's pathname

CALLED BY:	MSG_FOLDER_GET_PATH

PASS:		*ds:si - Folder object
		dx:bp - buffer for pathname (PATH_BUFFER_SIZE)

RETURN:		dx:bp - pathname (null-terminated)
		cx - disk handle

DESTROYED:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetPath	method	FolderClass, MSG_FOLDER_GET_PATH
	uses	dx
	.enter
	;
	; copy pathname from instance data into buffer
	;
	mov	es, dx
	mov	di, bp
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	mov	cx, size PathName
	call	GenPathGetObjectPath
	.leave
	ret
FolderGetPath	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRescan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	reread current directory

CALLED BY:	MSG_RESCAN

PASS:		*ds:si - FolderClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRescan	method	dynamic	FolderClass, MSG_RESCAN

	tst	ds:[di].FOI_suspendCount
	jnz	suspended


ND <	mov	ax, MSG_FOLDER_SAVE_ICON_POSITIONS	>
ND <	call	ObjCallInstanceNoLock 			>

	mov	ax, MSG_SCAN
	call	ObjCallInstanceNoLock
done:
	ret

suspended:
	ornf	ds:[di].FOI_folderState, mask FOS_RESCAN_ON_UNSUSPEND
	jmp	done
FolderRescan	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FolderRefresh
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Rescans, and redraws the given folder.

CALLED BY:	GLOBAL

PASS:		*ds:si	= FolderClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	11/9/92		Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRefresh	method	dynamic FolderClass, MSG_WINDOWS_REFRESH_CURRENT

	andnf	ds:[di].FOI_folderState, not mask FOS_SCANNED
	mov	ax, MSG_REDRAW
	call	ObjCallInstanceNoLock
	ret
FolderRefresh	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with folder being suspended.

CALLED BY:	MSG_REDRAW
PASS:		*ds:si	= Folder object
		ds:di	= FolderInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRedraw	method dynamic FolderClass, MSG_REDRAW
		tst	ds:[di].FOI_suspendCount
		jnz	suspended
		mov	di, offset FolderClass
		GOTO	ObjCallSuperNoLock
suspended:
		ornf	ds:[di].FOI_folderState, mask FOS_REDRAW_ON_UNSUSPEND
		ret
FolderRedraw	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRemovingDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the folder window is open to the disk being removed,
		close it.

CALLED BY:	MSG_META_REMOVING_DISK
PASS:		cx	= disk handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRemovingDisk method dynamic FolderClass, MSG_META_REMOVING_DISK
		.enter
	;
	; Close/rescan the folder if open to the passed disk.
	; 
		call	FolderCloseIfDisk
	;
	; If current path is on the disk being nuked, get off it.
	; 
		push	cx
		clr	cx
		call	FileGetCurrentPath
		pop	cx
		cmp	bx, cx
		jne	done

		mov	ax, SP_TOP
		call	FileSetStandardPath
done:
		.leave
		ret
FolderRemovingDisk endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Suspend changes on this here folder.

CALLED BY:	MSG_META_SUSPEND
PASS:		*ds:si	= Folder object
		ds:di	= FolderInstance
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSuspend	method dynamic FolderClass, MSG_META_SUSPEND
		inc	ds:[di].FOI_suspendCount
EC <		ERROR_Z	DESKTOP_FATAL_ERROR	; suspend count overflow>
		
		mov	di, offset FolderClass
		GOTO	ObjCallSuperNoLock
FolderSuspend	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUnsuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unsuspend changes on this here folder, acting on whatever
		things got aborted while it was suspended.

CALLED BY:	MSG_META_UNSUSPEND
PASS:		*ds:si	= Folder object
		ds:di	= FolderInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderUnsuspend	method dynamic FolderClass, MSG_META_UNSUSPEND

EC <		tst	ds:[di].FOI_suspendCount			>
EC <		ERROR_Z	DESKTOP_FATAL_ERROR				>
		dec	ds:[di].FOI_suspendCount
		jz	actOnAbortedThings
passItUp:
		mov	di, offset FolderClass
		GOTO	ObjCallSuperNoLock

actOnAbortedThings:
	;
	; Fetch out the folder state and clear the *_ON_UNSUSPEND bits from it
	; 
		mov	ax, ds:[di].FOI_folderState
		andnf	ds:[di].FOI_folderState, 
				not (mask FOS_REBUILD_ON_UNSUSPEND or \
				     mask FOS_RESORT_ON_UNSUSPEND or \
				     mask FOS_REDRAW_ON_UNSUSPEND or \
				     mask FOS_RESCAN_ON_UNSUSPEND)
	;
	; Rescan if told to. This rebuilds the lists, so just jump to the
	; redraw case.
	; 
		test	ax, mask FOS_RESCAN_ON_UNSUSPEND
		jz	checkResort
		push	ax
		mov	ax, MSG_RESCAN
		call	ObjCallInstanceNoLock
		pop	ax
		jmp	checkRedraw
checkResort:
	;
	; See if rebuild or resort requested.
	; 
		test	ax, mask FOS_RESORT_ON_UNSUSPEND or  \
				mask FOS_REBUILD_ON_UNSUSPEND
		jz	checkRedraw
	;
	; Yup. Set ax to TRUE or FALSE, as appropriate.
	; 
		push	ax
		and	ax, mask FOS_RESORT_ON_UNSUSPEND
		jz	rebuild
		mov	ax, TRUE
rebuild:
		call	BuildDisplayList
		pop	ax
checkRedraw:
	;
	; See if folder-redraw requested.
	; 
		test	ax, mask FOS_REDRAW_ON_UNSUSPEND
		jz	unsuspendComplete
	;
	; Do so.
	; 
		mov	ax, MSG_REDRAW
		call	ObjCallInstanceNoLock
unsuspendComplete:
		mov	ax, MSG_META_UNSUSPEND
		jmp	passItUp
FolderUnsuspend	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUnsuspendWindow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Unsuspend the folder's window.  This is a method so
		that it can be called on the queue.  It's a bug to 

PASS:		*ds:si	- FolderClass object
		ds:di	- FolderClass instance data
		es	- segment of FolderClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/28/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderUnsuspendWindow	method	dynamic	FolderClass, 
					MSG_FOLDER_UNSUSPEND_WINDOW

		mov	bx, ds:[di].FOI_windowBlock
		mov	si, FOLDER_VIEW_OFFSET
		mov	ax, MSG_GEN_VIEW_UNSUSPEND_UPDATE
		call	ObjMessageNone
		ret
FolderUnsuspendWindow	endm



FolderPathCode	ends

;------------------------------------------------------------------------------



FolderUtilCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderOpenSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	open selected files

CALLED BY:	MSG_OPEN_SELECT_LIST

PASS:		ds:si = instance data of folder

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		open all selected files

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/27/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderOpenSelectList	method	FolderClass, MSG_OPEN_SELECT_LIST
if (_ZMGR or _NEWDESKBA or _BMGR)
	;
	; on ZMGR, it doesn't make too much sense to open multiple things,
	; so do nothing if so
	;   Also for Wizard BA, as we don't open more than one thing at a 
	; time either.
	;
	DerefFolderObject	ds, si, di 
	mov	di, ds:[di].FOI_selectList
	cmp	di, NIL				; empty select list?
	je	afterOpenHack			; yes, handled below
	call	FolderLockBuffer		; es = folder buffer
	jz	afterOpenHack			; no folder buffer
	cmp	es:[di].FR_selectNext, NIL	; only one selection?
	call	FolderUnlockBuffer		; (preserves flags)
	jne	done				; nope, do nothing
afterOpenHack:
endif		; if (_ZMGR or _NEWDESKBA or _BMGR)
	;
	; start opening the list of files with the first one (what an
	; excellent place to start!)
	;
	mov	ss:[doingMultiFileLaunch], TRUE	; init flag
	mov	ss:[tooManyFoldersReported], FALSE	; init flag
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = ourselves
	mov	si, FOLDER_OBJECT_OFFSET	; common offset

if _NEWDESKBA		; turn off input to prevent multi-keystrokes
	mov	ax, MSG_GEN_APPLICATION_IGNORE_INPUT
	push	dx, bp
	call	UserCallApplication
	pop	dx, bp
endif		; if _NEWDESKBA

	clr	cx				; start with first in list
	mov	ax, MSG_OPEN_FILE_IN_SELECT_LIST
	call	ObjMessageForce
if (_ZMGR or _NEWDESKBA or _BMGR)
done:
endif		; if (_ZMGR or _NEWDESKBA or _BMGR)
	ret
FolderOpenSelectList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderOpenFileInSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	open file specified by entry number passed

CALLED BY:	MSG_OPEN_FILE_IN_SELECT_LIST

PASS:		cx - entry number in select list
		ds:*si - Folder object
		ds:bx - Folder instance data

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderOpenFileInSelectList	method	dynamic FolderClass,
					MSG_OPEN_FILE_IN_SELECT_LIST

	cmp	ss:[willBeDetaching], TRUE	; received DETACH?
	je	dontOpen			; yes, open no more files
	mov	bp, cx				; save current entry number
	inc	cx				; 1-based entry number
	mov	dx, bx				; ds:dx = instance data
	mov	di, ds:[bx].FOI_selectList	; di = selection list head
ND<	call	NDGetSelectionIntoDI 					>
ND<	jc	dontOpen			; if whitespace click	>

	call	FolderLockBuffer
	jz	dontOpen
	jmp	checkFile		

findFile:
	mov	di, es:[di].FR_selectNext	; es:di = next selection

checkFile:
	cmp	di, NIL				; check if end of list
	je	noMoreFiles			; if so can't find file to
						;	open, done
	loop	findFile			; loop to find file to open
	;
	; es:di = folder buffer entry of file to open
	; ds:*si = Folder object instance
	; ds:dx = Folder object instance data
	; bx = folder buffer handle
	; bp = entry number of file to open
	;
	push	ds, bp				; save stuff
	call	FileOpenESDI			; open es:di
	pop	ds, cx				; cx = current entry number
	;
	; send method via queue to launch next file
	;	cx = entry number of file to open
	;	*ds:si = Folder object
	;
	cmp	ss:[willBeDetaching], TRUE	; received DETACH?
	je	noMoreFiles			; yes, open no more files

	call	FolderUnlockBuffer
	inc	cx				; open next file in select list
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = ourselves
	mov	ax, MSG_OPEN_FILE_IN_SELECT_LIST
	call	ObjMessageForce
	jmp	exit
	;
	; no more files will be opened, mark application as no longer active
	;
noMoreFiles:
	call	FolderUnlockBuffer			; unlock folder buffer


dontOpen:
if _NEWDESKBA
	; accept input again (see FolderOpenSelectList)
	; This will only work as long as only 0 or 1 icons are ever
	; selected.
		
	push	dx, bp
	mov	ax, MSG_GEN_APPLICATION_ACCEPT_INPUT
	call	UserCallApplication
	pop	dx, bp
endif		; if _NEWDESKBA
	mov	ss:[doingMultiFileLaunch], FALSE	; clear flag
	mov	ss:[tooManyFoldersReported], FALSE	; make sure flag is
							;	cleared
exit:
	ret
FolderOpenFileInSelectList	endm


if _NEWDESK
;
;
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDGetSelectionIntoDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is a quick hack routine to avoid the warning "private
		instance variable NDFOI_popUpType used outside NDFolderClass.
		Because a regular FolderClass is never instantiated in NewDesk,
		this FolderClass handler is always called on a NDFolderClass
		object.  Since this code is in the middle, only a nasty
		callback would avoid this warning.
			Exits if popUpType is WPUT_WHITESPACE, leaves di
		pointing to FOI_selectList if popUpType is WPUT_SELECTION or
		sets di to NDFOI_nonSelect if it is not.

CALLED BY:	FolderOpenFileInSelectList

PASS:		ds:bx	- NDFolder instance data
		di	- FOI_selectList of above object

RETURN:		carry	clear - object clicked on
				di - FOI_selectList or NDFOI_nonSelect
			set - WhiteSpace clicked on

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDGetSelectionIntoDI	proc far
	class	NDFolderClass
	.enter

	cmp	ds:[bx].NDFOI_popUpType, WPUT_WHITESPACE
	je	dontOpen			; can't open a folder twice
	cmp	ds:[bx].NDFOI_popUpType, WPUT_SELECTION
	je	itsASelection
	mov	di, ds:[bx].NDFOI_nonSelect	; else open the single object
itsASelection:
	clc
	jmp	done
dontOpen:
	stc
done:
	.leave
	ret
NDGetSelectionIntoDI	endp
endif		; if _NEWDESK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSelectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	select all files in folder

CALLED BY:	MSG_SELECT_ALL

PASS:		*ds:si - FolderClass object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		go through display list, copying all files to select list

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSelectAll	method	FolderClass, MSG_SELECT_ALL

	call	FolderLockBuffer
	jz	exit

	call	DeselectAll			; deselect all files

	DerefFolderObject	ds, si, bx
	mov	di, ds:[bx].FOI_displayList	; start of display list
	mov	ds:[bx].FOI_selectList, di	; copy to select list

startLoop:
	cmp	di, NIL				; check if end-of-list mark
	je	done				; if so, done!
	ornf	es:[di].FR_state, mask FRSF_SELECTED	; mark as selected
	call	InvertIfTarget
	mov	ax, es:[di].FR_displayNext	; get next item
	mov	es:[di].FR_selectNext, ax	; copy to select list
	mov	di, ax
	jmp	short startLoop
done:
	call	PrintFolderInfoString		; update info string

	call	FolderUnlockBuffer
exit:
	ret
FolderSelectAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDeselectAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	deselect all files in folder

CALLED BY:	MSG_DESELECT_ALL

PASS:		*ds:si - FolderClass object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		NOT a dynamic method (is called directly)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDeselectAll	method	FolderClass, MSG_DESELECT_ALL
	call	FolderLockBuffer
	jz	exit

	call	DeselectAll			; deselect all files
	call	PrintFolderInfoString		; update info string


	call	FolderUnlockBuffer
exit:
	ret
FolderDeselectAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGreyFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grey file specified

CALLED BY:	MSG_GREY_FILE

PASS:		*ds:si - FolderClass object
		ds:di - FolderClass instance data
		dx:bp = filename

RETURN:		file grey'ed

DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGreyFile	method	dynamic FolderClass, MSG_GREY_FILE

		uses	cx
		.enter

		mov	ax, SEGMENT_CS		; ax <- vseg if XIP'ed
		mov	bx, offset FolderGreyFileCB
		call	FolderSendToDisplayList
		
		.leave
		ret
FolderGreyFile	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGreyFileCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback routine to grey a file

CALLED BY:	FolderGreyFile via FolderSendToDisplayList

PASS:		ds:di - FolderRecord
		dx:bp - filename to grey

RETURN:		carry set if file greyed

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGreyFileCB	proc far
		.enter
		mov	si, di			; ds:si - FolderRecord
						; filename 
		CheckHack <offset FR_name eq 0>
		
		mov	es, dx
		mov	di, bp
		clr	cx
		call	LocalCmpStrings
		clc
		jne	done

		mov	di, si
		call	FolderRecordGetParent
		mov	ax, mask DFI_GREY	; grey it out
		call	ExposeFolderObjectIcon
		stc
done:
		.leave
		ret
FolderGreyFileCB	endp



FolderUtilCode	ends

;----------------------------------------------------------------------



FileOperation	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rename selected files

CALLED BY:	MSG_FM_START_RENAME

PASS:		ds:si - instance handle of Folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/21/89		Initial version
	brianc	8/31/89		use FolderStartFileOperation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartRename	method	FolderClass, MSG_FM_START_RENAME
	;
	; first disable destination name entry so user doesn't get to enter
	; a name and then see it overwritten by the default destination name
	;
	call	RenameSetup
	;
	; now, do all the stuff to put up the rename box
	;
	mov	ax, offset FileOperationUI:RenameCurDir
	mov	bx, offset FileOperationUI:RenameFromEntry
	mov	cx, offset FileOperationUI:RenameBox
	mov	dx, offset FileOperationUI:RenameStatus
	call	FolderStartFileOperation
	jc	done				; if error, done
	;
	; then update destination name field characteristics for this file
	; and fill source name as default destination name
	;
	call	RenameStuff
done:
	ret
FolderStartRename	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			FolderStartChangeToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Changes the token of selected files

CALLED BY:	process

PASS:		*ds:si	= FolderClass object
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/23/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartChangeToken	method	FolderClass, MSG_FM_START_CHANGE_TOKEN
		.enter
		mov	ax, offset FileOperationUI:ChangeIconCurDir
		mov	bx, offset FileOperationUI:ChangeIconNameList
		mov	cx, offset FileOperationUI:ChangeIconBox
		mov	dx, offset FileOperationUI:ChangeIconStatus
		call	FolderStartFileOperation
		jc	exit				; if error, done
	;
	; Initialize UI to the correct state
	;
		call	ChangeIconShowIcon
	;
	; Bring up the change icon dialog
	;
		mov	bx, handle FileOperationUI
		mov	si, offset FileOperationUI:ChangeIconBox
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		call	ObjMessageNone

exit:
		.leave
		ret
FolderStartChangeToken	endm


ifdef CREATE_LINKS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartCreateLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	make link's of selected files

CALLED BY:	MSG_FM_START_CREATE_LINK

PASS:		ds:si - instance handle of Folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartCreateLink	method	FolderClass, MSG_FM_START_CREATE_LINK
	.enter

GM<	cmp	ds:[bx].FOI_selectList, NIL	; no selected files?	>
GM<	je	done				; yes, do nothing	>
ND<	call	NDCheckForNoSelection					>
ND<	jc	done							>

	push	si				; save instance data handle

	call	SetLinkDefaultDestination

	mov	bx, handle CreateLinkBox
	mov	si, offset CreateLinkBox
	push	ds:[LMBH_handle]
	call	UserDoDialog
	call	MemDerefStackDS
	pop	si					; *ds:si is folder obj.
	cmp	ax, OKCANCEL_OK
	jne	done

	call	CreateFileListBuffer
	jc	done

	mov	cx, size PathName
	sub	sp, cx					; allocate stack buffer
	mov	bp, sp
	mov	dx, ss					; dx:bp is stack buffer
	push	bx					; preserve FQT
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	mov	bx, handle CreateLinkToEntry
	mov	si, offset CreateLinkToEntry
	call	ObjMessageCall
	mov	ds, dx
	mov	dx, bp
	mov	bx, cx					; cx, ds:dx is pathname
	call	FileSetCurrentPath
	mov	ax, ds
	mov	bx, dx
;MarkForRescan doesn't exist anymore? 12/18/98
;	call	MarkForRescan

	pop	bx					; restore FQT
	add	sp, size PathName			; pop stack buffer

createLink::
	call	CreateLinkCommon
	call	MemFree					; free fQT block
	call	UpdateMarkedWindows

done:
	.leave
	ret
FolderStartCreateLink	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLinkDefaultDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the CreateLinkToEntry FileSelector to the appropriate
		default directory.

CALLED BY:	FolderStartCreateLink

PASS:		*ds:si - Folder object

RETURN:		ds unchanged

DESTROYED:	all but ds

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLinkDefaultDestination	proc	near
ND<	class NDFolderClass >
	.enter

	call	Folder_GetDiskAndPath
	lea	dx, ds:[bx].GFP_path
	mov	bp, ax

if _NEWDESK
	mov	si, ds:[si]
	cmp	ds:[si].NDFOI_popUpType, WPUT_WHITESPACE
	jne	gotPath

	segmov	es, ds, di
	mov	di, dx				; es:di is pathname
	mov	cx, size PathName
	clr	ax				; search for null
	repne	scasb
	dec	di				; backup to null
	mov	al, '\\'
	cmp	{byte} es:[di-1], al
	je	gotSlash
	stosb
gotSlash:
	mov	ax, '.' or ('.' shl 8)
	stosw					; go up one directory
	mov	al, 0
	stosb					; null terminate
	push	di
gotPath:
	push	si
endif		; if _NEWDESK

	mov	cx, ds				; bp, cx:dx is path
	mov	ax, MSG_GEN_PATH_SET
	mov	bx, handle CreateLinkToEntry
	mov	si, offset CreateLinkToEntry
	call	ObjMessageCall

if _NEWDESK
	pop	si
	cmp	ds:[si].NDFOI_popUpType, WPUT_WHITESPACE
	jne	done
	pop	di
	sub	di, 4
	mov	{byte} es:[di], 0		; truncate bogus "\.."
done:
endif		; if _NEWDESK

	.leave
	ret
SetLinkDefaultDestination	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateLinkCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates link's given a FQT block and a destination
		path and diskhandle

CALLED BY:	FolderStartCreateLink, QTCreateLink

PASS:		bx    = handle of FQT block
		current directory set to path of destination

RETURN:		bx    = still pointing to FQT block

DESTROYED:	all but bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/1/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateLinkCommon	proc	near
	uses	bx
	.enter

	sub	sp, size FileLongName
	mov	dx, sp					; allocate stack buffer1
	sub	sp, (size PathName)+(size FileLongName)	; dx holds this buffer
	mov	si, sp					; allocate stack buffer2
	mov	bp, sp					; bp holds this buffer
	segmov	ds, ss, ax				; ds:si is stack buffer2

	push	bx					; preserve FQT
	call	MemLock
	mov	es, ax
	cmp	es:[FQTH_numFiles], 0
	je	unlockAndExit
	mov	di, offset FQTH_pathname
	mov	cx, -1
	clr	ax					; searching for null
	repne	scasb					; get length
	not	cx					; invert for length
	segxchg	ds, es
	mov	di, si					; es:di is stack buffer2
	mov	si, offset FQTH_pathname		; ds:si is FQTH_pathname
	rep	movsb					; copy pathname to buf.
	dec	di					; back up to null
	mov	al, '\\'
	cmp	{byte} es:[di-1], al
	je	gotSlash
	stosb						; give it a slash
gotSlash:
	mov	ax, di					; save this at-end-of-
	mov	bx, dx					;  -dir place.
NDONLY <mov	{byte} ss:[bx], ' '			; add space to link name
	mov	bx, ds:[FQTH_diskHandle]
	mov	si, offset FQTH_files

linkLoop:						; ds:si is FOIE
	mov	di, dx					; es:di is stack buffer1
NDONLY <inc	di					; skip space	>
CheckHack< FOIE_name eq 0>
	mov	cx, (size FileLongName) - 2		; because we added space
	rep	movsb					; fill link name
	mov	{byte} es:[di], 0			; term. if not already

	sub	si, (size FileLongName) - 2		; restore si
	mov	cx, size FileLongName
	mov	di, ax					; at-end-of-dir place
	rep	movsb					; fill target pathname
	mov	di, bp					; es:di is pathname

	push	ds, ax
	segmov	ds, es, ax
	;
	; ds:dx is now the link name and bx, es:di is the target
							; cx zero means get the 
	clr	cx					;  attrs from the target
	call	FileCreateLink
	jnc	noError
	cmp	ax, ERROR_FILE_EXISTS
	jne	notExists
	mov	ax, ERROR_LINK_EXISTS
notExists:
	call	DesktopOKError
	stc
noError:
	pop	ds, ax
	jc	unlockAndExit

	add	si, (size FileOperationInfoEntry) - (size FileLongName)
	dec	ds:[FQTH_numFiles]			; goto next FOIE
	cmp	ds:[FQTH_numFiles], 0
	jne	linkLoop

unlockAndExit:
	pop	bx
	call	MemUnlock				; unlock FQT

	add	sp, (size PathName) + (2 * (size FileLongName))

	.leave
	ret
CreateLinkCommon	endp
endif		; ifdef CREATE_LINKS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartDeleteThrowAway
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete selected files

CALLED BY:	MSG_FM_START_DELETE, MSG_FM_START_THROW_AWAY

PASS:

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/21/89		Initial version
	brianc	8/31/89		use FolderStartFileOperation
	dlitwin	6/2/92		generalized to work with Throw Away

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartDeleteThrowAway	method	FolderClass, MSG_FM_START_DELETE,
						MSG_FM_START_THROW_AWAY
	.enter

GM<	cmp	ds:[bx].FOI_selectList, NIL	; no selected files?	>
GM<	je	exit				; yes, do nothing	>
ND<	call	NDCheckForNoSelection					>
ND<	jc	exit							>
	;
	; create list of files to delete
	;
	push	ax
	call	CreateFileListBuffer
	pop	cx				; preserve ax
	jc	exit				; error reported, done
	;
	; delete selected files
	;	bx = file list buffer
	;
if not _FCAB and (not _FORCE_DELETE)
	cmp	cx, MSG_FM_START_DELETE
	jne	mustBeThrowAway

	call	WastebasketDeleteFiles		; delete files in file list
	jmp	done

mustBeThrowAway:
	mov	ss:[usingWastebasket], WASTEBASKET_WINDOW

NOFXIP<	segmov	ds, cs, si			; segment of path name	>
FXIP  <	mov	si, bx							>
FXIP  <	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP  <	mov	bx, si							>
	mov	si, offset rootString
	mov	dx, SP_WASTE_BASKET
	mov	bp, mask CQNF_MOVE
	mov	cx, -1				; definitely not zero
	call	ProcessDragFilesCommon

	mov	ss:[usingWastebasket], NOT_THE_WASTEBASKET
endif		; if (not _FCAB)
if _FCAB or _FORCE_DELETE
	call	WastebasketDeleteFiles		; delete files in file list
endif		; if _FCAB
done::
	call	MemFree
exit:
	.leave
	ret
FolderStartDeleteThrowAway	endm

if _FXIP
idata	segment
endif

LocalDefNLString rootString <C_BACKSLASH, 0>

if _FXIP
idata	ends
endif

if not _FCAB
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartRecover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	un-delete selected files to a selected directory, or (if no
		file chosen) allow user to select a file or dir to undelete.

CALLED BY:	MSG_FM_START_RECOVER

PASS:		*ds:si - folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/2/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartRecover	method	FolderClass, MSG_FM_START_RECOVER
	.enter

	push	bx, si				; save folder instance handle
	call	Folder_GetDiskAndPath
	mov	si, bx
	inc	si
	inc	si				; inc past disk handle word
	mov	dx, ax				; put disk handle in dx
	call	IsThisInTheWastebasket
	mov	dx, si
	pop	bx, si
	jnc	notInWastebasket

	push	bx, si				; save these as they will get
	mov	bp, SP_DOCUMENT			; destroyed

NOFXIP<	mov	cx, cs				; rootString in cx:dx	>
FXIP  < mov	dx, ds
FXIP  <	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP  <	mov	cx, ds							>
FXIP  <	mov	ds, dx							>
	mov	dx, offset rootString
	mov	ax, MSG_GEN_PATH_SET
	mov	bx, handle RecoverToEntry
	mov	si, offset RecoverToEntry	; set destination directory box
	call	ObjMessageCall			; to SP_DOCUMENT if grabbing
	pop	bx, si				; selected files from the WB
	jc	handleError

GM<	cmp	ds:[bx].FOI_selectList, NIL	; no selected files?	>
GM<	je	getSourceFile			; yes, do nothing	>
ND<	call	NDCheckForNoSelection					>
ND<	jc	getSourceFile						>

	call	CreateFileListBufferReturnError	; bx = quick transfer block
	mov	si, -1				; set si non-zero
	jc	handleError
	jmp	getDestDir

notInWastebasket:
	mov	bp, ax				; disk handle in bp
	mov	cx, ds				; path in cx:dx
	mov	ax, MSG_GEN_PATH_SET
	mov	bx, handle RecoverToEntry
	mov	si, offset RecoverToEntry	; set destination directory box
	call	ObjMessageCall			; to shown directory if not in
	jc	handleError			; the Wastebasket directory	

getSourceFile:
	call	RecoverGetSourceFile		; returns bx=QuickTransferBlock
	jc	handleError			;   with file to undelete
						; si = zero means cancel
getDestDir:
	push	bx
	;
	; use MSG_GEN_PATH_SET to store source dir
	;
	mov	ax, handle RecoverBox
	mov	si, offset RecoverBox
	call	FolderMoveCopySetSrcDir
	mov	bx, handle RecoverBox
	mov	si, offset RecoverBox
	call	UserDoDialog			; bring up undelete box, modally
	pop	bx
	cmp	ax, OKCANCEL_OK			; user wants to move files?
	jne	exit				; no, exit

	call	MenuRecoverCommon
	jmp	exit

handleError:
	tst	si
	jz	exit
	call	DesktopOKError
exit:
	.leave
	ret
FolderStartRecover	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecoverGetSourceFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a file from the Wastebasket to undelete.

CALLED BY:	FolderStartRecover, TreeStartRecover

PASS:		nothing

RETURN:		carry set on error or cancel
			si = zero if cancel
			si = non-zero if error, ax = error code
		carry clear if successful
			bx = quick transfer block with selected item

DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RecoverGetSourceFile	proc far
	uses	cx, dx, bp, di, ds
	.enter

	mov	bp, SP_WASTE_BASKET
NOFXIP<	mov	cx, cs				; path in cx:dx		>
FXIP  <	mov	ax, ds							>
FXIP  <	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP  <	mov	cx, ds							>
FXIP  <	mov	ds, ax							>
	mov	dx, offset rootString
	mov	ax, MSG_GEN_PATH_SET
	mov	bx, handle RecoverSrc
	mov	si, offset RecoverSrc		; set destination directory box
	call	ObjMessageCall			; to shown directory if not in
	mov	si, -1				; the Wastebasket directory
	LONG	jc	exit

	mov	bx, handle RecoverSrcBox
	mov	si, offset RecoverSrcBox
	call	UserDoDialog			; bring up source box modally
	cmp	ax, OKCANCEL_OK			; canceled?
LONG	jne	userCanceled

	mov	ax, size FileQuickTransferHeader + FileOperationInfoEntry
	mov	cx, ALLOC_DYNAMIC_LOCK or (mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	si, -1				; non-zero
	jc	exit
	mov	ds, ax

	push	bx				; save mem block handle
	mov	dx, ds
	mov	bp, offset FQTH_pathname
	mov	cx, size PathName
	mov	ax, MSG_GEN_PATH_GET
	mov	bx, handle RecoverSrc
	mov	si, offset RecoverSrc
	call	ObjMessageCall			; get the file's path into 
	mov	ds:[FQTH_numFiles], 1		; the FileQuickTransferHeader
	mov	ds:[FQTH_diskHandle], cx

	mov	ax, MSG_GEN_FILE_SELECTOR_GET_SELECTION
	mov	cx, ds
	mov	dx, size FileQuickTransferHeader + FOIE_name
	mov	bx, handle RecoverSrc
	mov	si, offset RecoverSrc
	call	ObjMessageCall			; get file's name into FOIE
	pop	bx				; restore mem block handle
	clr	ax				; start off with no flags
	test	bp, mask GFSEF_NO_ENTRIES
	jz	gotSelection
	mov	ax, ERROR_NO_SELECTION
	call	DesktopOKError
	jmp	userCanceled

gotSelection:
	test	bp, mask GFSEF_READ_ONLY
	jz	gotReadOnly
	or	al, mask FA_RDONLY
gotReadOnly:
	andnf	bp, mask GFSEF_TYPE
	cmp	bp, GFSET_SUBDIR shl offset GFSEF_TYPE
	jne	gotSubDir
	mov	al, mask FA_SUBDIR
gotSubDir:
	cmp	bp, GFSET_VOLUME shl offset GFSEF_TYPE
	jne	gotVolume
	or	al, mask FA_VOLUME
gotVolume:
	mov	ds:[FQTH_files+FOIE_attrs], al	; attrs
	mov	ds:[FQTH_files+FOIE_pathInfo], mask DPI_EXISTS_LOCALLY
	call	MemUnlock			; unlock this block
	clc					; no error
	jmp	exit

userCanceled:
	clr	si				; indicate no error
	stc					; (though cancelled...)
exit:
	.leave
	ret
RecoverGetSourceFile	endp

endif				; if (not _FCAB)



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFileListBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a transfer block holding the list of selected files

CALLED BY:	FolderStartDelete, ...
PASS:		*ds:si	= Folder object
RETURN:		carry set if couldn't create
		carry clear if could:
			bx	= handle of buffer block
DESTROYED:	ax,cx, dx, di, bp, es

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateFileListBuffer	proc	far
	class	FolderClass
	.enter
	call	CreateFileListBufferReturnError
	jnc	done
	call	DesktopOKError
	stc					; indicate error
done:
	.leave
	ret
CreateFileListBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateFileListBufferReturnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine for CreateFileListBuffer and SendFileList
		that builds a FileQuickTransfer block with the files that
		are currently selected in the folder. If the block cannot
		be allocated, it returns an error, rather than reporting
		one to the user.

			If NewDesk, then check the folder instance data for
		the NDFOI_popUpType and if not WPUT_SELECTION, build out the
		appropriate FQT.

CALLED BY:	CreateFileListBuffer, SendSelectedFiles
PASS:		*ds:si	= Folder object
RETURN:		carry set on error:
			ax	= error code
		carry clear if ok:
			bx	= handle of FileQuickTransfer block
DESTROYED:	ax, cx, dx, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/25/92		Initial version
	dlitwin	9/15/92		added NewDesk popup alterations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateFileListBufferReturnError proc	near
	uses	ds, es

if _NEWDESK
	class	NDFolderClass
else
	class	FolderClass
endif

	.enter

if _NEWDESK
	DerefFolderObject	ds, si, bx
	mov	al, ds:[bx].NDFOI_popUpType
	cmp	al, WPUT_SELECTION
	je	clickedOnSelection

	cmp	al, WPUT_WHITESPACE
	je	clickedInWhiteSpace

	call	NDBuildSingleItem
	jmp	done	

clickedInWhiteSpace:
	call	NDBuildParentItem
	jmp	done

clickedOnSelection:
endif		; if _NEWDESK

	;
	; allocate buffer for file list
	;
	mov	ax, (INIT_NUM_DRAG_FILES * size FileOperationInfoEntry) + \
				size FileQuickTransferHeader
	push	ax
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	pop	dx				; retrieve EOF(buffer)
	jc	memError

	;
	; fill in quick transfer file list buffer header
	;	FQTH_nextBlock, FQTH_UIFA and FQTH_numFiles are ZERO
	;
	mov	es, ax				; es - file list buffer segment
	mov	es:[FQTH_nextBlock], 0
	mov	es:[FQTH_UIFA], 0
	push	bx				; save file buffer handle
	call	Folder_GetDiskAndPath
	mov	es:[FQTH_diskHandle], ax
	DerefFolderObject	ds, si, si
	mov	bp, ds:[si].FOI_selectList	; bp = select list
	mov	ax, ds:[si].FOI_buffer		; ax = folder buffer handle,
						;  since bx currently occupied
	lea	si, ds:[bx].GFP_path
	mov	di, offset FQTH_pathname	; es:di = path in buffer header
	mov	cx, size PathName
	rep movsb				; copy pathname into file list
	mov_tr	bx, ax				; bx <- folder buffer
	call	MemLock				; lock folder buffer
	mov	ds, ax				; ds = folder buffer segment
	mov	di, bx				; di = folder buffer handle
	pop	bx				; bx = file list buffer handle
	push	di				; save folder buffer handle
	mov	di, offset FQTH_files		; es:di - skip header
	call	GetFolderBufferNames		; pass: ds:bp, es:di, bx, dx
	mov	es:[FQTH_numFiles], cx		; save number of files
	mov_tr	ax, bx				; ax = file list
	pop	bx				; unlock folder buffer
	call	MemUnlock			;	(preserves flags)
	mov_tr	bx, ax				; bx = file list
	call	MemUnlock			; unlock file list buffer
						;	(preserves flags)
	jnc	done				; if no file list error, done
						;	(carry clear)
	call	MemFree				; else, free file list buffer
memError:
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; report memory error
	stc
done:
	.leave
	ret
CreateFileListBufferReturnError endp


if _NEWDESK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDBuildSingleItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build out the FQT from the NDFOI_nonSelected pointer instead
		the selection list.

CALLED BY:	CreateFileListBufferReturnError

PASS:		*ds:si	= NDFolder object
		ds:bx = NDFolder instance

RETURN:		carry	- clear if no error
				bx = handle to FQT block
			- set if error
				ax = error code
DESTROYED:	ax, cx, dx, si

SIDE EFFECTS:	none
PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDBuildSingleItem	proc	near
	uses	bp, di, es
	class NDFolderClass
	.enter

	mov	bp, bx				; ds:bp = NDFolder instanc data
	mov	ax, size FileQuickTransferHeader + size FileOperationInfoEntry
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or		\
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax	
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jc	exit

	push	bx				; save block handle	

	call	Folder_GetDiskAndPath		; locked down into es
	mov	es:[FQTH_diskHandle], ax
	mov	di, offset FQTH_pathname
	lea	si, ds:[bx].GFP_path
	mov	cx, size PathName/2
	rep	movsw				; copy path into FQTH
	mov	es:[FQTH_nextBlock], 0
	mov	es:[FQTH_UIFA], 0
	mov	es:[FQTH_numFiles], 1
	mov	di, offset FQTH_files
	mov	bx, ds:[bp].FOI_buffer
	mov	bp, ds:[bp].NDFOI_nonSelect	; file offset within buffer
	push	ds				; save folder objectblock
	call	MemLock
	mov	ds, ax
	call	CopyOneSelectedFilename		; ds:bp -> es:di
	call	MemUnlock
	pop	ds				; restore folder objectblock
	pop	bx				; restore FQT block handle
	call	MemUnlock

exit:
	.leave
	ret
NDBuildSingleItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDBuildParentItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build out the FQT from the parent folder.

CALLED BY:	CreateFileListBufferReturnError

PASS:		*ds:si	= NDFolder object
		ds:bx = NDFolder instance

RETURN:		carry	- clear if no error
				bx = handle to FQT block
			- set if error
				ax = error code
DESTROYED:	ax, cx, dx, si

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
	To do this we temporarily add a ".." or "\.." to the end of the
	path and then construct the full path into the FQTH.
	We then skip to the end of the original path, remove the "\.." and
	read the last segment of the path into the FOIE name field.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/16/92		Initial version
	dloft	1/16/93		Changed to preserve WOT

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDBuildParentItem	proc	near
	uses	bp, di, es
	class NDFolderClass
	.enter

	;
	; allocate the new FQT block with one entry.
	;
	mov	bp, bx				; ds:bp = NDFolder instanc data
	mov	ax, size FileQuickTransferHeader + size FileOperationInfoEntry
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	mov	es, ax
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	LONG	jc	exit

	push	bx				; save block handle	
						; locked down into es

	push	ds:[bp].NDFOI_ndObjType	 	; save NewDeskObjectType

	;
	; add ".." or "\.." to the end of the original path and build out
	; to the FQTH
	;
	call	Folder_GetDiskAndPath
	push	es
	segmov	es, ds, si
	lea	di, es:[bx].GFP_path		; es:di is pathname
	mov	bp, di				; save this offset (used later)
	clr	ax				; search for null
	mov	cx, size PathName
	repne	scasb
	dec	di
	mov	al, '\\'
	cmp	{byte} es:[di-1], al
	je	afterSlash
	stosb					; make sure it has a slash
afterSlash:
	mov	ax, '.' or ('.' shl 8)
	stosw					; add ".." to end
	clr	ax
	stosb					; null terminate
	pop	es				; restore FQT block
	mov	di, offset FQTH_pathname
	clr	dx				; no <drivename>: prepended
	mov	si, bp				; ds:si is path to build from
	mov	bx, ds:[bx].GFP_disk
	mov	cx, size PathName
	call	FileConstructFullPath
	mov	es:[FQTH_diskHandle], bx
	;
	; Remove the "\.." from the end and get the last path segment into 
	; the FOIE
	;
	push	es				; save block again
	segmov	es, ds, di
	mov	di, si				; es:di is folder's path
	mov	cx, size PathName
	clr	ax				; search for null
	repne	scasb
	sub	di, 4				; back track before "\..0"
	stosb					; clip the ".." off
	mov	ax, '\\'
	std					; reverse the search direction
	mov	cx, size FileLongName
	mov	bp, di
	sub	bp, si
	cmp	bp, cx
	jge	longPath
	mov	cx, bp
	inc	cx
	inc	cx
longPath:
	repne	scasb
	cld					; reset search direction
	mov	si, di
	pop	es				; restore FQT block
	inc	si				; ds:[si] is the slash now
	inc	si				; ds:[si] points past the slash

	mov	di, offset FQTH_files		; es:[di] points to FOIE_name
.assert(offset FOIE_name eq 0)
	mov	cx, size FileLongName/2
	rep	movsw				; copy folder name
	;
	; set up other misc FQTH things
	;
	mov	di, offset FQTH_files		; reset to begining of FOIE
	mov	es:[di].FOIE_type, GFT_DIRECTORY
	mov	es:[di].FOIE_attrs, mask FA_SUBDIR
	mov	es:[di].FOIE_flags, 0
	mov	es:[di].FOIE_pathInfo, mask DPI_EXISTS_LOCALLY
	mov	es:[FQTH_nextBlock], 0
	mov	es:[FQTH_UIFA], 0
	mov	es:[FQTH_numFiles], 1
	pop	es:[di].FOIE_info		; NewDeskObjectType
	pop	bx				; restore FQT block handle
	call	MemUnlock

exit:
	.leave
	ret
NDBuildParentItem	endp

endif		; if _NEWDESK	
	
	
if INSTALLABLE_TOOLS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the selected files in the given folder

CALLED BY:	MSG_META_APP_GET_SELECTION
PASS:		*ds:si	= Folder object
RETURN:		ax	= handle of quick transfer block (0 if couldn't
			  allocate the block)
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetSelection method dynamic FolderClass, MSG_META_APP_GET_SELECTION
	.enter
	call	CreateFileListBufferReturnError
	jnc	done
	clr	bx
done:
	mov_tr	ax, bx
	.leave
	ret
FolderGetSelection endm
endif ; INSTALLABLE_TOOLS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartCreateDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create directory/directories

CALLED BY:	MSG_FM_START_CREATE_DIR

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/23/89		Initial version
	brianc	8/31/89		use FolderStartFileOperation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartCreateDir	method	FolderClass, MSG_FM_START_CREATE_DIR
	mov	ax, offset FileOperationUI:CreateDirCurDir
	clr	bx
	mov	cx, offset FileOperationUI:CreateDirBox
	mov	dx, offset FileOperationUI:CreateDirStatus
	call	FolderStartFileOperation
	jc	done
	call	CreateDirStuff		; clear create dir name field
done:
	ret
FolderStartCreateDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move selected files

CALLED BY:	MSG_FM_START_MOVE

PASS:		ds:si - instance handle of Folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/25/89		Initial version
	brianc	8/31/89		use FolderStartFileOperation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartMove	method	FolderClass, MSG_FM_START_MOVE
GM<	cmp	ds:[bx].FOI_selectList, NIL	; no selected files?	>
GM<	je	done				; yes, do nothing	>
ND<	call	NDCheckForNoSelection					>
ND<	jc	done							>

	push	si
	mov	ax, handle MoveToEntry
	mov	si, offset MoveToEntry
	call	FolderMoveCopySetCurDir
	;
	; use MSG_GEN_PATH_SET to store source dir
	;
	mov	ax, handle MoveBox
	mov	si, offset MoveBox
	call	FolderMoveCopySetSrcDir

	;
	; bring up move box, modally
	;
	mov	bx, handle MoveBox
	mov	si, offset MoveBox
	push	ds:[LMBH_handle]
	call	UserDoDialog
	call	MemDerefStackDS
	pop	si				; ds:si = folder instance data
	cmp	ax, OKCANCEL_OK			; user wants to move files?
	jne	done				; no, done
	;
	; build list of files to move
	;
	call	CreateFileListBuffer		; bx = file list buffer
	jc	done				; error reported, done
	;
	; do move
	;
	call	MenuMoveCommon			; handles errors
done:
	ret
FolderStartMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy selected files

CALLED BY:	MSG_FM_START_COPY

PASS:		ds:si - instance handle of Folder object
if _NIKE	
		cl	=  NK_FOLDER, NK_DISK
endif _NIKE

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/25/89		Initial version
	brianc	8/31/89		use FolderStartFileOperation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartCopy	method	FolderClass, MSG_FM_START_COPY
GM<	cmp	ds:[bx].FOI_selectList, NIL	; no selected files?	>
GM<	je	done				; yes, do nothing	>
ND<	call	NDCheckForNoSelection					>
ND<	jc	done							>

		
	push	si			; folder chunk handle
	mov	ax, handle CopyToEntry
	mov	si, offset CopyToEntry
	call	FolderMoveCopySetCurDir
	;
	; use MSG_GEN_PATH_SET to store source dir
	;
	mov	ax, handle CopyBox
	mov	si, offset CopyBox
	call	FolderMoveCopySetSrcDir

afterSetDir::
	;
	; bring up copy box, modally
	;
	mov	bx, handle CopyBox
	mov	si, offset CopyBox
	push	ds:[LMBH_handle]
	call	UserDoDialog
	call	MemDerefStackDS
	pop	si				; folder chunk handle
	cmp	ax, OKCANCEL_OK			; user wants to move files?
	jne	done				; no, done
	;
	; build list of files to copy
	;
	call	CreateFileListBuffer		; bx = file list buffer
	jc	done				; error reported, done
	;
	; do copy
	;
	call	MenuCopyCommon			; handles errors
done:
	ret
FolderStartCopy	endp


if _NEWDESK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDCheckForNoSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for no selection only if popUpType is WPUT_SELECTION

CALLED BY:	FolderStartCopy

PASS:		ds:bx = NDFolder instance

RETURN:		carry - set if no selection and popUpType is WPUT_SELECTION
		      - clear otherwise

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	9/18/92		added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDCheckForNoSelection	proc	far
	class	NDFolderClass
	.enter

	cmp	ds:[bx].NDFOI_popUpType, WPUT_SELECTION
	jne	ok
	cmp	ds:[bx].FOI_selectList, NIL
	jne	ok
	stc
	jmp	done
ok:
	clc
done:
	.leave
	ret
NDCheckForNoSelection	endp
endif		; if _NEWDESK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderMoveCopySetDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets a file selector to the current folder directory

CALLED BY:	FolderStartCopy, FolderStartMove

PASS:		ds = folder object segment
		^lax:si - File Selector to set to current directory

RETURN:		nothing

DESTROYED:	ax, bx, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/17/92		added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderMoveCopySetCurDir	proc	near
	uses	cx, dx, bp, di
	class	FolderClass
	.enter
GM <	;								>
GM <	; for GeoManager, change only the first time			>
GM <	;								>
GM <	tst	ss:[startFromScratch]		; restoring from state?	>
GM <	jz	leaveAlone			; yes, leave alone	>
GM <	push	ax							>
GM <	mov	bx, ax				; ^lbx:si = File Selector >
GM <	mov	ax, MSG_VIS_FIND_PARENT					>
GM <	call	ObjMessageCallFixup		; any vis parent?	>
GM <	pop	ax							>
GM <	tst	cx							>
GM <	jnz	leaveAlone			; yes, leave alone	>
	push	ax
	call	Folder_GetDiskAndPath
	mov_tr	bp, ax				; bp <- disk handle
	mov	cx, ds
	lea	dx, ds:[bx].GFP_path		; dx:bp <- path to set
	pop	bx				; ^lbx:si <- file selector
	mov	ax, MSG_GEN_PATH_SET
	call	ObjMessageCallFixup
GM <leaveAlone:								>
	.leave
	ret
FolderMoveCopySetCurDir	endp

FolderMoveCopySetSrcDir	proc	near
	uses	cx, dx, bp, di
	class	FolderClass
	.enter
	push	ax
	call	Folder_GetDiskAndPath
	mov_tr	bp, ax				; bp <- disk handle
	mov	cx, ds
	lea	dx, ds:[bx].GFP_path		; dx:bp <- path to set
	pop	bx				; ^lbx:si <- file selector
	mov	ax, MSG_GEN_PATH_SET
	call	ObjMessageCallFixup
	.leave
	ret
FolderMoveCopySetSrcDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	duplicate selected files

CALLED BY:	MSG_FM_START_DUPLICATE

PASS:		ds:si - instance handle of Folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartDuplicate	method	FolderClass, MSG_FM_START_DUPLICATE
	;
	; first disable destination name entry so user doesn't get to enter
	; a name and then see it overwritten by the default destination name
	;
	call	DuplicateSetup
	;
	; now, do all the stuff to put up the duplicate box
	;
	mov	ax, offset FileOperationUI:DuplicateCurDir
	mov	bx, offset FileOperationUI:DuplicateFromEntry
	mov	cx, offset FileOperationUI:DuplicateBox
	mov	dx, offset FileOperationUI:DuplicateStatus
	call	FolderStartFileOperation
	jc	done					; if error, done
	;
	; then update destination name field characteristics for this file
	; and fill source name as default destination name
	;
	call	DuplicateStuff
done:
	ret
FolderStartDuplicate	endp

if not _FCAB

if _DOS_LAUNCHERS
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCreateEditDosLauncher
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use file selected to create or edit a launcher is selection
		is only one file and if it is the right type.

CALLED BY:	DesktopSendToCurrentOrTree

PASS:		ss    - dgroup
		ds:si - instance handle of Folder object
		ds:di - instance data of Folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCreateEditDosLauncher	method	FolderClass,
					MSG_CREATE_DOS_LAUNCHER,
					MSG_EDIT_DOS_LAUNCHER
	.enter

	mov	cx, ds:[di].FOI_selectList
	cmp	cx, NIL
	je	notCorrectFile

	mov	bx, ds:[di].FOI_buffer
	push	ds, si					; save folder object
	call	MemLock
	mov	ds, ax					; lock folder buffer
	mov	si, cx					; now ds:si is selection
	mov	dx, si					; save folder record
	cmp	ds:[si].FR_selectNext, NIL		; more than one file?
	jne	notCorrectUnlockAndPop

		CheckHack <(offset FR_name) eq 0>
	mov	ax, si
NOFXIP<	segmov	es, dgroup, di				; es = dgroup	>
FXIP  <	mov	di, bx							>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX	; es = dgroup	>
FXIP  <	mov	bx, di							>
	mov	di, offset launcherGeosName		; es:di is an idata buf
	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2
	rep	movsw					; copy name to idata
	mov	si, ax					; restore name pointer
	mov	di, offset launchFileName		; es:di is an idata buf
	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2
	rep	movsw					; copy name to idata
	segmov	es, ds, si
	mov	di, dx					; es:di is FolderRecord
	pop	ds, si					; restore folder object

	call	CheckIfSingleFileIsCorrect
	call	MemUnlock
	jc	notCorrectFile

	call	Folder_GetDiskAndPath
	add	bx, offset GFP_path
	call	DOSLauncherFileSelected
	jmp	done

notCorrectUnlockAndPop:
	call	MemUnlock
	pop	ds, si
notCorrectFile:
	cmp	ss:[creatingLauncher], 0
	mov	bx, handle GetCreateLauncherFileBoxSelectTrigger
	mov	si, offset GetCreateLauncherFileBoxSelectTrigger
	mov	cx, handle GetCreateLauncherFileBox
	mov	dx, offset GetCreateLauncherFileBox
	jne	gotObject

	mov	bx, handle GetEditLauncherFileBoxSelectTrigger
	mov	si, offset GetEditLauncherFileBoxSelectTrigger
	mov	cx, handle GetEditLauncherFileBox
	mov	dx, offset GetEditLauncherFileBox

gotObject:
	push	cx, dx
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ObjMessageCall

	pop	bx, si
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageForce
done:
	.leave
	ret
FolderCreateEditDosLauncher	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfSingleFileIsCorrect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if the file is a *.exe, *.com, *.bat, *.btm if we
		are creating, or has the LAUN creator token if we are editing.

CALLED BY:	FolderCreateEditDOSLauncher

PASS:		ss    - dgroup
		es:di - FolderRecord

RETURN:		carry clear if file is correct
		carry set if file is not correct

DESTROYED:	all but bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfSingleFileIsCorrect	proc	near
	uses	ax, cx, bp, ds, si, es, di
	.enter

	cmp	ss:[creatingLauncher], 1
	je	checkForDOSExecutable

	cmp	es:[di].FR_fileType, GFT_EXECUTABLE
	jne	notCorrectFile
	cmp	{word} es:[di].FR_creator.GT_chars, 'L' or ('A' shl 8)
	jne	notCorrectFile
	cmp	{word} es:[di+2].FR_creator.GT_chars, 'U' or ('N' shl 8)
	jne	notCorrectFile
	cmp	{word} es:[di].FR_creator.GT_manufID, MANUFACTURER_ID_GEOWORKS
	jne	notCorrectFile
	jmp	correctFile

checkForDOSExecutable:
	cmp	es:[di].FR_fileType, GFT_NOT_GEOS_FILE
	jne	notCorrectFile				; as if nothing selected
	mov	si, di					; save FolderRecord ptr
		CheckHack <(offset FR_name) eq 0>
	mov	bp, di					; save filename in bp
	mov	cx, -1
	clr	ax
	LocalFindChar					; repne scasb/scasw
	not	cx
	mov	di, bp					; restore filename
	LocalLoadChar ax, '.'
	LocalFindChar					; go to dot extender
	jne	notCorrectFile				; no dot = see ya!

	call	CheckIfBatComExe
	jmp	done

correctFile:
	clc						; correct
	jmp	done

notCorrectFile:
	stc						; not correct
done:
	.leave
	ret
CheckIfSingleFileIsCorrect	endp
endif		; _DOS_LAUNCHERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartChangeAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change attributes of selected files

CALLED BY:	MSG_FM_START_CHANGE_ATTR

PASS:		ds:si - instance handle of Folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderStartChangeAttr	method	FolderClass, MSG_FM_START_CHANGE_ATTR
	mov	ax, offset FileOperationUI:ChangeAttrCurDir
	mov	bx, offset FileOperationUI:ChangeAttrNameList
	mov	cx, offset FileOperationUI:ChangeAttrBox
	mov	dx, offset FileOperationUI:ChangeAttrStatus
	call	FolderStartFileOperation
	jc	done				; if error, done
	;
	; show attributes for first file
	;
	call	ChangeAttrShowAttrs
done:
	ret
FolderStartChangeAttr	endp

endif		; if (not _FCAB)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	fill in info and put up Get Info dialog box

CALLED BY:	MSG_FM_GET_INFO

PASS:		ds:si - instance handle of Folder object
		es - segment of FolderClass
		ax - MSG_FM_GET_INFO

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/24/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetInfo	method	FolderClass, MSG_FM_GET_INFO
	;
	; set up and bring up GetInfo dialog box
	;
	mov	ax, offset FileOperationUI:GetInfoPath
	mov	bx, offset FileOperationUI:GetInfoFileList
	mov	cx, offset FileOperationUI:GetInfoBox
	mov	dx, 0				; no status
	call	FolderStartFileOperation
	jc	done				; if error, done
	;
	; show first file
	;
	;
	; our combo of hints makes the box grow by itself each time for
	; no reason, so reset here each time before bringing it up
	;
	mov	bx, handle GetInfoBox
	mov	si, offset GetInfoBox
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_NOW
	call	ObjMessageCall
	call	ShowCurrentGetInfoFile
done:
	ret
FolderGetInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUpDirQT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move/copy files to parent directory

CALLED BY:	MSG_UP_DIR_QT

PASS:		ds:*si - Folder object
		ds:bx - Folder object instance data
		bp - handle of file list block

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/31/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderUpDirQT	method	FolderClass, MSG_UP_DIR_QT
	.enter

FC<	; don't allow transferring above document level			>
FC<	call	Folder_GetDiskAndPath					>
FC<	cmp	ax, SP_DOCUMENT			; in DOCUMENT?		>
FC<	jne	doIt							>
FC<	cmp	{word}ds:[bx].GFP_path, '\\' or (0 shl 8)		>
FC<	je	exit							>
FC< doIt:								>
	;
	; get parent directory name, if root do nothing
	;
	sub	sp, PATH_BUFFER_SIZE		; allocate path buffer on stack
	call	GetFolderParentPath
	jc	done

	;
	; move/copy files to parent directory
	;	ss:sp = parent directory
	;	cx = disk handle
	;
	mov	dx, cx				; dx = dest. disk handle
	segmov	ds, ss				; ds:si = destination directory
	mov	si, sp
	mov	bx, bp				; bx = file list block handle
	mov	bp, -1				; NOT Waste basket (no override)
	call	GetQuickTransferMethod		; bp = move or copy
	jc	error
	mov	cx, 1				; indicate BX is mem. block
	push	bx				; save it

if not _FCAB
	call	IsThisInTheWastebasket
	jnc	notTheWastebasket
	mov	{byte} ss:[usingWastebasket], WASTEBASKET_WINDOW
notTheWastebasket:
endif		; if (not _FCAB)

	call	ProcessDragFilesCommon		; move/copy files
	mov	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET
	pop	bp
done:
	mov	bx, bp				; bx = file list block handle
error:
	call	MemFree				; free it
	add	sp, PATH_BUFFER_SIZE		; nuke path buffer on stack
FC<exit:>
	.leave
	ret
FolderUpDirQT	endm


FileOperation	ends


if not _FCAB
UtilCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfBatComExe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	CheckIfBatComExe

CALLED BY:	CheckIfSingleFileIsCorrect, WFileSelectorFilterRoutine,
		GetNewDeskObjectType

PASS:		es:di - three letter extention after '.'

RETURN:		carry clear if it is a *.BAT(*.BTM), *.COM, *.EXE
		carry set if not

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfBatComExe	proc	far
	uses	ax, bx, cx, dx, bp, ds, si, es, di
	.enter

	clr	bx					; default bx to zero
SBCS <	cmp	{byte} es:[di+3], 0			; if not null teminated>
DBCS <	cmp	{wchar} es:[di+3*2], 0			; if not null teminated>
	jne	isNotBatComExe

	; check *.COM
SBCS <	cmp	{word} es:[di], 'C' or ('O' shl 8)			>
DBCS <	cmp	{wchar} es:[di], 'C'					>
	jne	checkExe
DBCS <	cmp	{wchar} es:[di][1*2], 'O'				>
DBCS <	jne	checkExe						>
SBCS <	cmp	{word} es:[di+2], 'M' or (0 shl 8)			>
DBCS <	cmp	{wchar} es:[di][2*2], 'M'				>
DBCS <	jne	checkExe						>
DBCS <	cmp	{wchar} es:[di][3*2], C_NULL				>
	je	isBatComExe

checkExe:
SBCS <	cmp	{word} es:[di], 'E' or ('X' shl 8)			>
DBCS <	cmp	{wchar} es:[di], 'E'					>
	jne	checkBat
DBCS <	cmp	{wchar} es:[di][1*2], 'X'				>
DBCS <	jne	checkBat						>
SBCS <	cmp	{word} es:[di+2], 'E' or (0 shl 8)			>
DBCS <	cmp	{wchar} es:[di][2*2], 'E'				>
DBCS <	jne	checkBat						>
DBCS <	cmp	{wchar} es:[di][3*2], C_NULL				>
	je	isBatComExe

checkBat:
	segmov	ds, cs, si
	mov	si, offset systemCategoryStr
	mov	cx, cs
	mov	dx, offset batchExtStr

	;
	; Allocate a buffer, and upcase the thing
	;

	mov	bp, InitFileReadFlags <IFCC_UPCASE,,,0>
	call	InitFileReadString

SBCS <	mov	si, (offset defaultExt) -1	; ds:si is default ext	>
DBCS <	mov	si, (offset defaultExt) -2	; ds:si is default ext	>
	jnc	lockBlock			; if no error lock block

	clr	bx					; no block
	jmp	checkLoop

lockBlock:
	call	MemLock
	mov	ds, ax
SBCS <	mov	si, -1					; after inc will be 0 >
DBCS <	mov	si, -2					; after inc will be 0 >

checkLoop:	; es:di is src ext., ds:si+1 is ext to check against
	LocalNextChar dssi			; next char
	LocalCmpChar ds:[si], ' '
	je	checkLoop
	LocalCmpChar ds:[si], '\t'
	je	checkLoop
	LocalCmpChar ds:[si], 0
	je	isNotBatComExe
SBCS <	cmp	{byte} ds:[si+1], 0	; make sure we don't skip end	>
DBCS <	cmp	{wchar}ds:[si][1*2], 0	; make sure we don't skip end	>
	je	isNotBatComExe
SBCS <	cmp	{byte} ds:[si+2], 0	; make sure we don't skip end	>
DBCS <	cmp	{wchar} ds:[si][2*2], 0	; make sure we don't skip end	>
	je	isNotBatComExe
	cmpsw				; check first two chars
	jne	nextExt			; next extention
DBCS <	cmpsw								>
DBCS <	jne	nextExt							>
SBCS <	cmpsb				; check last char		>
DBCS <	cmpsw				; check last char		>
	je	isBatComExe
	LocalPrevChar 	dssi		; ... as it will be incremented above
	LocalPrevChar 	esdi		; reset es:di
nextExt:
	LocalPrevChar	esdi
	LocalPrevChar 	esdi		; reset es:di
	jmp	checkLoop

isNotBatComExe:
	tst	bx
	stc
	jz	exit
	call	MemUnlock		; unlock block if it exists
	jmp	exit

isBatComExe:
	tst	bx
	clc
	jz	exit
	call	MemUnlock		; unlock block if it exists
exit:
	.leave
	ret
CheckIfBatComExe	endp

LocalDefNLString defaultExt <"BAT BTM", 0>
					; default extensions that indicate
					;  a batch file.
systemCategoryStr	char	"system", 0
batchExtStr		char	"batch ext", 0

UtilCode	ends
endif		; if (not _FCAB)
