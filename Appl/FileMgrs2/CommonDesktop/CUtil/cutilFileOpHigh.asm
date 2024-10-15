COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Util
FILE:		cutilFileOpHigh.asm

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

	$Id: cutilFileOpHigh.asm,v 1.2 98/06/03 13:51:03 joon Exp $

------------------------------------------------------------------------------@

FileOpLow segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyMenuDeleteThrowAway
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	use high-level verification of delete if "confirm delete
		single" option is set

CALLED BY: 	ProcessDragFilesCommon

PASS:		ax - MSG_FM_START_DELETE or MSG_FM_START_THROW_AWAY

RETURN:		carry clear if okay to continue delete
		carry set to cancel delete

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/07/90	broken out of FolderStartDelete for use in
					TreeStartDelete
	dlitwin	06/01/92	made it general for throw away and delete
	dlitwin	07/01/92	new three stage delete warnings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VerifyMenuDeleteThrowAway	proc	far
if (not _FCAB and not _ZMGR)
	uses	ax, bx, cx, dx, di, si, bp
	.enter
	push	ax				; save incoming message

GM<	mov	bx, handle OptionsDeleteWarnings	>
GM<	mov	si, offset OptionsDeleteWarnings	>
GM<	mov	cx, mask OMI_SINGLE_WARNING		>
GM<	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED	>
GM<	call	ObjMessageCall				>
GM<	pop	ax				; restore incoming mesage >
GM<	jnc	done				; no high-level confirm >
GM<						;     (continue delete) >

ND<	mov	bx, handle FileDeleteOptionsGroup	>
ND<	mov	si, offset FileDeleteOptionsGroup	>
ND<	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION	>
ND<	call	ObjMessageCall				>
ND<	cmp	ax, OCDL_SINGLE				>
ND<	pop	ax					>
ND<	jne	continueDelete			; no high-level confirm >
ND<						;     (continue delete) >
	cmp	ax, MSG_FM_START_DELETE
	mov	ax, WARNING_DELETE_ITEMS	; else, give high-level confirm
	je	gotWarningMsg
	mov	ax, WARNING_THROW_AWAY_ITEMS	; else, give high-level confirm
gotWarningMsg:
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES			; delete?
	stc					; assume cancel
	jne	done				; nope, cancel
ND<continueDelete:>
	clc					; else, return carry clear
done:
	.leave
else
	clc		; File Cabinet and Zoomer are always in "full" mode
endif		; ((not _FCAB) and (not _ZMGR) and (not _NIKE))
	ret
VerifyMenuDeleteThrowAway	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MenuMoveCommon, MenuCopyCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle file move/copy from menu

CALLED BY:	INTERNAL
			FolderStartMove
			FolderStartCopy
			TreeStartMove
			TreeStartCopy

PASS:		bx = file list buffer

RETURN:		errors handled

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/08/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MenuMoveCommon	proc	far
	mov	ax, handle MoveToEntry
	mov	si, offset MoveToEntry
	mov	bp, mask CQNF_MOVE
	call	MenuMoveCopyCommon
	ret
MenuMoveCommon	endp

if not _FCAB
MenuRecoverCommon	proc	far
	push	ds
	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	mov	dx, ss
	mov	bp, sp
	push	bx				; save file list block
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	mov	bx, handle RecoverToEntry
	mov	si, offset RecoverToEntry
	call	ObjMessageCall			; dx:bp = path, cx = disk handle
	pop	bx				; restore file list block
	mov	ds, dx
	mov	si, bp
	mov	dx, cx				; put disk handle in dx
	call	IsThisInTheWastebasket
	pop	ds
	jc	inWastebasket

	add	sp, PATH_BUFFER_SIZE
	mov	ax, handle RecoverToEntry
	mov	si, offset RecoverToEntry
	mov	bp, mask CQNF_MOVE
	call	MenuMoveCopyCommon
	jmp	exit

inWastebasket:
	add	sp, PATH_BUFFER_SIZE
	mov	ax, ERROR_RECOVER_TO_WASTEBASKET
	call	DesktopOKError

exit:
	ret
MenuRecoverCommon	endp
endif		; if (not _FCAB)

MenuCopyCommon	proc	far
	mov	ax, handle CopyToEntry
	mov	si, offset CopyToEntry
	mov	bp, mask CQNF_COPY
	call	MenuMoveCopyCommon
	ret
MenuCopyCommon	endp

;
; pass:
;	ax:si = file selector for destination
;	bp = mask CQNF_MOVE for move
;		or
;	     mask CQNF_COPY for copy
;	bx = file list transfer buffer
;
MenuMoveCopyCommon	proc	near
	;
	; set up parameters for move
	;
	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	mov	dx, sp
	push	bp				; save move/copy flag
	push	bx				; save file list buffer
	mov	bp, dx
	mov	dx, ss

	mov	bx, ax				; bx:si = file selector
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	call	ObjMessageCall			; dx:bp = path, cx = disk handle
	;
	; move files
	;
	pop	bx				; bx = file list buffer
	mov	ds, dx				; ds:si = dest. path
	mov	si, bp
	pop	ax				; ax = move/copy flag
	jcxz	done				; => no path, so do nothing
	mov	dx, cx				; dx = dest. disk handle
	mov	cx, 1				; bx is heap block
	mov	bp, ax				; pass file move/copy flag
	push	bx
if not _FCAB
	call	IsThisInTheWastebasket
	jnc	notTheWastebasket
	mov	{byte} ss:[usingWastebasket], WASTEBASKET_WINDOW
notTheWastebasket:
endif		; if (not _FCAB)
	call	ProcessDragFilesCommon		; (handles/reports errors)
	mov	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET
	pop	bx
done:
	call	MemFree				; free file list buffer
	add	sp, PATH_BUFFER_SIZE
	ret
MenuMoveCopyCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetQuickTransferMethod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	determine whether quick transfer move or copy should be done

CALLED BY:	INTERNAL
			DriveToolCopyMoveFiles (FileOperation)
			DesktopDirToolQTInternal (FileOperation)
			FolderUpDirQT (FileOperation)

PASS:		dx = destination disk handle
		bx = file list block

RETURN:		carry - set on error
		      - clear otherwise
			   bp = mask CQNF_MOVE or mask CQNF_COPY
				depending on (src = dest)
		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/31/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetQuickTransferMethod	proc	far
	uses	ax, cx, dx, es
	.enter

	call	MemLock
	mov	es, ax
	call	ShellGetRemoteFlagFromFQT

	tst	ax
	jz	fileIsLocal

	call	MemUnlock
	jmp	setToCopy

fileIsLocal:
	call	ShellGetTrueDiskHandleFromFQT

	call	MemUnlock
	jnc	noError

	call	DesktopOKError
	stc					; carry - set
	jmp	done

noError:
	test	dx, DISK_IS_STD_PATH_MASK
	jz	compareThem

NOFXIP<	segmov	es, <segment idata>, dx					>
FXIP<	mov	dx, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, dx							>
	mov	dx, es:[geosDiskHandle]		; SP's are on the system disk

compareThem:
	cmp	cx, dx
	mov	bp, mask CQNF_MOVE
	clc					; clear out error flag
	je	done
setToCopy:
	mov	bp, mask CQNF_COPY

done:
	.leave
	ret
GetQuickTransferMethod	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffUIFAIntoFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store UIFA flags into file list header

CALLED BY:	INTERNAL
			ProcessDragFilesListItem
			ProcessTreeDragItem

PASS:		bx:ax = VM block containing file list
		dh = UIFA flags

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/26/90	Initial version
	dloft	10/7/92		Changed dx to dh so as not to dork the
				BATransferType record.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffUIFAIntoFileList	proc	far
	uses	ax, es, bp
	.enter
	call	VMLock
	mov	es, ax
	mov	es:[FQTH_UIFA].high, dh
	call	VMUnlock
	.leave
	ret
StuffUIFAIntoFileList	endp


if not _FCAB

FileOpLow	ends

PseudoResident	segment	resource

; Moved this here so that FileOpLow isn't loaded on startup -chrisb

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsThisInTheWastebasket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the destination path (dx,ds:si) is the Wastebasket
			or if it is in the Wastebasket

CALLED BY:	FolderUpDirQT (FolderClass)
		ProcessDragFileListItem (FolderClass)
		ProcessTreeDragItem (TreeClass)
		DesktopDirToolQTInternal
		DriveToolCopyMoveFiles
		MenuMoveCopyCommon ({Folder,Tree}Start{Move,Copy})

PASS:		ds:si = pathname
		dx = disk handle

RETURN:		carry set if path is the Wastebasket or in the Wastebasket
		zero flag set if it is the Wastebasket itself and not a subdir

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsThisInTheWastebasket	proc	far
	uses	ax, bx, cx, dx, bp, di, si, es, ds
	.enter

	mov	cx, size PathName
	mov	bp, sp				; save pre-stack-buf. position
	sub	sp, cx				; allocate stack buffer
	segmov	es, ss, di
	mov	di, sp				; es:di is destination buffer
	mov	bx, dx				; bx, ds:si is source path
	clr	dx				; no drive name requested
	call	FileConstructActualPath
	mov	di, sp				; reset es:di to buffer start

	call	FileParseStandardPath		; bx, es:di is path to parse
	cmp	ax, SP_WASTE_BASKET
	clc					; assume not equal
	jne	exit

SBCS <	cmp	{byte} es:[di], 0					>
DBCS <	cmp	{wchar}es:[di], 0					>
	je	setZeroFlag			; if no tail path
SBCS <	cmp	{word} es:[di], C_BACKSLASH or (0 shl 8)		>
DBCS <	cmp	{wchar}es:[di], C_BACKSLASH				>
DBCS <	jne	haveTail						>
DBCS <	cmp	{wchar}es:[di][2], 0					>

	je	setZeroFlag			; if no tail path

DBCS <haveTail:								>
	cmp	ax, SP_TOP			; we know its SP_WASTE_BASKET
	jmp	doneZeroFlag			;  so this will clear z flag

setZeroFlag:
	sub	ax, ax				; sets zero flag
doneZeroFlag:
	stc
exit:
	mov	sp, bp				; pop path buffer off stack
	.leave
	ret
IsThisInTheWastebasket	endp

PseudoResident	ends

FileOpLow	segment	resource

endif		;if (not _FCAB)






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessDragFilesCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	common handler for move/copy of files being quick transfer'ed

CALLED BY:	INTERNAL
			FolderUpDirQT (FolderClass)
			ProcessDragFileListItem (FolderClass)
			ProcessTreeDragItem (TreeClass)
			DesktopDirToolQTInternal
			DriveToolCopyMoveFiles
			MenuMoveCopyCommon ({Folder,Tree}Start{Move,Copy})

PASS:		ds:si = destination pathname for move/copy
		dx = disk handle of destination disk
		bp = mask CQNF_MOVE for move
			or
		     mask CQNF_COPY for copy
		bx:ax = (VM file):(VM block) of quick transfer file list block
			OR
		bx = memory block handle of quick transfer file list block
		cx = 0 if bx:ax = VM block
		   <> 0 if bx = memory block

RETURN:		nothing 

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/19/90	broken out for common use

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
messageTable	word	\
	0,				; FOPT_NONE
	MSG_SHELL_OBJECT_DELETE,	; FOPT_DELETE
	MSG_SHELL_OBJECT_THROW_AWAY,	; FOPT_THROW_AWAY
	MSG_SHELL_OBJECT_COPY,		; FOPT_COPY
	MSG_SHELL_OBJECT_MOVE		; FOPT_MOVE

.assert (size messageTable eq FileOperationProgressTypes)

ProcessDragFilesCommon	proc	far
quickNotifyFlags local	ClipboardQuickNotifyFlags	\
	push	bp

	.enter

	push	ax, cx, dx, bx, bp, si, di
					; save VM block handle, block type
	mov	cx, ds
	call	MemSegmentToHandle	; cx = handle
EC <	ERROR_NC -1							>
	push	cx			; save block handle
	mov	ax, ACTIVE_TYPE_FILE_OPERATION
	call	DesktopMarkActive			; application will be active
	call	MemDerefStackDS		; flags preserved
	pop	ax, cx, dx, bx, bp, si, di
					; retrieve VM block handle, block type

	LONG	jnz realExit			; detaching already, do nothing

	call	FileBatchChangeNotifications	; batch them all up, please
						;  as we don't want to consume
						;  billions of handles

	call	IndicateBusy
	call	InitForWindowUpdate

	;
	; whatever the operation, clear recursive error flag - brianc 5/24/93
	;
	mov	ss:[recurErrorFlag], 0

	;
	; set destination directory as current directory
	;
	push	bx, ax				; save file list block handle
	mov	bx, dx
	mov	dx, si				; ds:dx = destination dir
	mov	di, bx				; save diskhandle in di
	call	FileSetCurrentPath
	pop	bx, dx				; retrieve file list block
	jnc	noError				; if no error, continue

ND<	call	NDCheckIfDriveLink			>
preError::
	call	DesktopOKError			; else, report error
	jmp	exit				;	then quit
noError:
	mov	ax, dx				; bx:ax = VM transfer item
	;
	; go through filenames
	;
	jcxz	lockVMBlock
	push	bx				; save mem handle for unlocking
	call	MemLock				; ax = segment
	jmp	short lockCommon
lockVMBlock:
	mov	di, bp				; save frame pointer
	call	VMLock				; ax = segment, bp = mem handle
	push	bp				; save mem handle for unlocking
	mov	bp, di				; retrieve frame pointer
lockCommon:
	push	cx				; save block flag
	mov	ds, ax				; ds = file list block

	;			**NewDesk Only**
	; If there are items in the incoming list of files that need
	; to be handled specially by a NewDesk system object (printer or 
	; wastebasket etc.) or a BA subclass, this routine breaks each file
	; out and calls a subclassable message on it that allows a BA subclass
	; to do anything it wants with the special object.
	;
ND<	call	NewDeskHandleSpecialObjects			>
	;
	; set up file-operation progress box
	;	bp = quick method
	;	(give precendence to force-COPY if both set)
	;

	mov	ax, FOPT_COPY			; assume copy
	test	ds:[FQTH_UIFA], (mask UIFA_COPY shl 8)	; explicit copy?
	jnz	2$				; yes, use copy
	test	ds:[FQTH_UIFA], (mask UIFA_MOVE shl 8)	; explicit move?
	jnz	1$				; yes, use move
	test	quickNotifyFlags, mask CQNF_COPY	; else, implicit copy?
	jnz	2$				; yes
1$:
	mov	ax, FOPT_MOVE			; else, move

2$:
	cmp	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET
	je	gotType

if not _FORCE_DELETE

	mov	ax, FOPT_THROW_AWAY		; Wastebasket is always a move
	;
	; This code disables Delete override of the Alt key because someone
	; might be forcing a move (Alt key as well) and accidentally drop
	; a file on the open Wastebasket folder, causing a delete.  This
	; is the way things were originally spec'ed, but it was decided that
	; it is too inconsistent to have Delete Override and the Wastebasket
	; Never Saves work only some of the time (only with the Wastebasket
	; dir button, which doesn't even exist in NewDesk).
	;	Comment it back in if it is decided that this is desired.
	;
;	cmp	{byte} ss:[usingWastebasket], WASTEBASKET_WINDOW
;	je	gotType
;

	test	ds:[FQTH_UIFA], (mask UIFA_MOVE shl 8)
	jnz	deleteOverride

						; allow overridding
						;	OMI_WB_NEVER_SAVES
	test	ds:[FQTH_UIFA], (mask UIFA_COPY shl 8)
	jnz	gotType

	push	ax, bx, cx, dx, bp, si
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	cx, mask OMI_WB_NEVER_SAVES
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCall			; carry set if item set
	pop	ax, bx, cx, dx, bp, si
	;
	; Blech.  GeoManager Menu reviews decided that "Hold Items in WB"
	; sounded better than "WB Never Saves", and so this flag means the 
	; exact opposite of what it says in GMGR.  Wizard can't change to
	; agree with GMGR, so GMGR will just use this flag but always do
	; the opposite.
	;
GM<	jc	gotType	>
ND<	jnc	gotType	>
deleteOverride:
endif		; if (not _FORCE_DELETE)

	mov	ax, FOPT_DELETE

gotType:
	;
	; Figure out which message to send, based on the
	; FileOperationProgressTypes 
	;
	mov	dx, ax			; FileOperationProgressTypes
	mov_tr	bx, ax
	mov	ax, cs:[messageTable][bx]

	;
	; Get the type of the first object in the block, and send the
	; message to process similar files
	;

	tst	ds:[FQTH_numFiles]
	jz	outtaHere
	
	mov	si, offset FQTH_files
	mov	si, ds:[si].FOIE_info
	call	UtilGetDummyFromTable	; ^lbx:si - dummy
	push	ax, dx, bp
	mov	cx, ds
	mov	di, mask MF_CALL
	call	ObjMessage
	pop	ax, dx, bp

outtaHere:

	pop	cx				; retrieve block flag
	jcxz	vmBlockUnlock
	pop	bx				; bx = mem handle
	call	MemUnlock			; unlock file list mem block
	jmp	exit

vmBlockUnlock:
	mov	di, bp				; save frame pointer
	pop	bp				; bp = VM mem handle
	call	VMUnlock			; unlock file list VM block
	mov	bp, di				; restore frame pointer

exit:
	call	FinishUpCommon

realExit:
	.leave
	ret
ProcessDragFilesCommon	endp

if _NEWDESK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDCheckIfDriveLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a file is a drive link.  If so it changes
		the error message accordingly.

CALLED BY:	ProcessDragFilesCommon
PASS:		ds:si		- path of file
		di		- diskhandle of file
		ax		- error message from FileSetCurrentPath
RETURN:		ax		- new error message if it is a drive link
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 9/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDCheckIfDriveLink	proc	near
	uses	bx, cx, dx, di, es

	cmp	ax, ERROR_PATH_NOT_FOUND
	jne	dontCheck
	.enter

	call	FilePushDir
	push	ax, ds				; save error and path
	mov	bx, di
	segmov	ds, cs, dx
	mov	dx, offset rootPath
	call	FileSetCurrentPath		; change dir to root of drive
	pop	ax, ds				; restore error and path
	jc	exit

	push	ax				; save error message
	mov	dx, si				; ds:dx is filename
	segmov	es, ss, di
	mov	cx, size NewDeskObjectType
	sub	sp, cx
	mov	di, sp				; es:di is stack buffer buffer
	mov	ax, FEA_DESKTOP_INFO
	call	FileGetPathExtAttributes
	mov	cx, ds:[di]			; get the file's WOT into cx
	add	sp, size NewDeskObjectType
	pop	ax				; restore error message
	jc	exit

	cmp	cx, WOT_DRIVE
	jne	exit
	mov	ax, ERROR_DRIVE_LINK_TARGET_GONE
exit:
	call	FilePopDir
	.leave
dontCheck:
	ret
NDCheckIfDriveLink	endp
LocalDefNLString rootPath <C_BACKSLASH, 0>
endif		; if _NEWDESK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WastebasketDeleteFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete files

CALLED BY:	INTERNAL
			FolderStartDelete (same module)
			TreeStartDelete (diff. module)

PASS:		bx = mem handle of file list block

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WastebasketDeleteFiles	proc	far
	uses	ax, bx, cx, dx, bp, di, si, ds, es
	.enter

	mov	ax, ACTIVE_TYPE_FILE_OPERATION
	call	DesktopMarkActive		; application will be active
	jnz 	done

	call	FileBatchChangeNotifications	; batch them all up, please
						;  as we don't want to consume
						;  billions of handles
	call	IndicateBusy
	call	InitForWindowUpdate

	call	MemLock
	push	bx
	mov	ds, ax
	mov_tr	cx, ax
	mov	ax, MSG_SHELL_OBJECT_DELETE
	LoadBXSI	DefaultDummy
	clr	di
	call	ObjMessage

	call	FileFlushChangeNotifications

	pop	bx
	call	MemUnlock

	call	FinishUpCommon
	mov	ss:[showDeleteProgress], TRUE	; be sure delete progress is
						;	enabled when we leave

done:
	.leave
	ret
WastebasketDeleteFiles	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FinishUpCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common code to finish up a multi-file operation

CALLED BY:	ProcessDragFilesCommon, WastebasketDeleteFiles

PASS:		nothing 

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/10/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FinishUpCommon	proc near
	.enter

	mov	ax, SP_TOP			; just go to top-level
	call	FileSetStandardPath
	call	ClearFileOpProgressBox
	call	IndicateNotBusy
	call	MarkNotActive
	call	FileFlushChangeNotifications

	.leave
	ret
FinishUpCommon	endp




if _NEWDESK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressFileQuickTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a FileQuickTransfer block remove all entries with no
		name (null in the name field).
			*** This routine does not attempt to resize (shrink)
		the block, just compact the data within the block and update
		the count of files ***.

CALLED BY: 	NewDeskHandleSpecialObjects

PASS:		ds - segment of locked down FileQuickTransfer block

RETURN:		ds - segment of locked down compressed FQT block

DESTROYED:	bx,cx,dx,si,di,bp,es

PSEUDO CODE/STRATEGY:
		X is end of compressed section
		Y is begining of chunk to move up to X
		Z is ending of chunk to move up to X

		X = find first marked entry
			no files marked? exit!
		Y = X
	loopTop:
		Y = next unmarked entry or end of list
			end of list? exit!
		Z = next marked entry after Y or end of list
		move entries between Y and Z to X
		X = X + (|Z - Y|) (increment X to end of compressed)
		Y = Z
		jmp loopTop
	exit!
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	08/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressFileQuickTransfer	proc	near
	uses	ax

	.enter

	segmov	es, ds, ax
	mov	di, offset FQTH_files
	mov	cx, ds:[FQTH_numFiles]
	mov	bp, cx				; keep number of entries in bp
	jcxz	done
	mov	dx, size FileOperationInfoEntry

	; di = X, si = Y

	;
	; X = find first marked entry
	;
xLoop:
	cmp	{byte} ds:[di].FOIE_name, 0
	je	xSet
	add	di, dx				; dx is entry size
	loop	xLoop
		;
		; no files marked?
		;
	jmp	done				; exit!

xSet:	;
	; Y = X
	;
	mov	si, di

loopTop:		; **** loopTop ****
		; Y = next unmarked entry or end of list
yLoop:
EC <	call	ECCheckBounds			>
	cmp	{byte} ds:[si].FOIE_name, 0	; is entry marked?
	jne	ySet
	add	si, dx				; go to next entry
	dec	bp				; update file count because
	loop	yLoop				;   we just skiped an entry
		; end of list? exit!
	jmp	done

ySet:
	mov	bx, si				; bx - si is length to copy
zLoop:
	cmp	{byte} ds:[bx].FOIE_name, 0
	je	zSet
	add	bx, dx				; next entry
	loop	zLoop
		; reached end of FileQuickTransfer
zSet:
	push	cx				; save file entry counter
	mov	cx, bx
	sub	cx, si				; get length to copy into cx
	;
	; move entries between Y and Z to X
	;
	rep	movsb
	; 
	; X (di) is updated properly to be X + |Y - Z|
	; Y (si) is updated properly to be Z
	; so just loop unless we are done
	;
	pop	cx				; restore Y entry position
	jcxz	done				; done,if we moved the last file
	jmp	loopTop

done:
	mov	ds:[FQTH_numFiles], bp		; reset to new number of files

	.leave
	ret
CompressFileQuickTransfer	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilGetNextInfoEntryOfSameType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search forward in the FileQuickTransfer block until we
		find a FileOperationInfoEntry of the same type as the
		current one.  Place a NULL in the filename of the
		current entry, to signify that we're finished with it.

CALLED BY:	EXTERNAL

PASS:		ds:si - FileOperationInfoEntry

RETURN:		if found:
			carry clear
			ds:si - next FileOperationInfoEntry
		else:	
			carry set

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilGetNextInfoEntryOfSameType	proc far
	uses	ax,bx,cx,dx
	.enter

	mov	{byte} ds:[si].FOIE_name, 0

	;
	; Figure out where the block ends
	;

	mov	ax, ds:[FQTH_numFiles]
	mov	cx, size FileOperationInfoEntry
	mul	cx
	add	ax, offset FQTH_files	

	;
	; Get the type of the current element
	;

	mov	bx, ds:[si].FOIE_info

	;
	; Scan forward for the next element of this type
	;

searchLoop:
	add	si, size FileOperationInfoEntry
	cmp	si, ax
	ja	notFound
	cmp	ds:[si].FOIE_info, bx
	jne	searchLoop

done:
	.leave
	ret

notFound:
	stc
	jmp	done
UtilGetNextInfoEntryOfSameType	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepFilenameForError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff current filename into global area for error reporting
		(if needed) 

CALLED BY:	ProcessDragFilesCommon

PASS:		ds:si - filename
RETURN:		nothingy

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/27/92		added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrepFilenameForError	proc	far
	uses	si, es, di, cx
	.enter
NOFXIP<	segmov	es, <segment dgroup>, di				>
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
	mov	di, offset dgroup:fileOperationInfoEntryBuffer
	mov	cx, size fileOperationInfoEntryBuffer
	rep movsb
	.leave
	ret
PrepFilenameForError	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyMoveFileToDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copies/moves the specified source file/directory into the
		specified destination directory

CALLED BY:	ShellObjectMoveCopyEntryCommon

PASS:		ds:si - FileOperationInfoEntry of source file
		ds: - FileQuickTransferHeader from which to get src dir

		current directory is destination directory
		ax - update strategy (passed on to MarkWindowForUpdate)

		fileOperationInfoEntryBuffer - 32 and 8.3 source name info

RETURN:		carry set if error
			AX - error
		updates folder window table, if no error
		ss:[recurErrorFlag] set if recursive operation error
		preserves ds, dx, es, di, cx, si, bp

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/28/89		Initial version
	brianc	9/8/89		Combined TextCopyFile, TextMoveFile
	brianc	2/90		rewritten
	dlitwin	5/22/92		added support for new Wastebasket

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyMoveFileToDir	proc	far

updateStrategy	local	word	push	ax

	uses	bx, ds, dx, es, di, cx, si

	.enter

	mov	ss:[enteredFileOpRecursion], 0	; in case of early error

	lea	dx, ds:[si].FOIE_name
	call	CheckRootSrcOperation		; can't copy/move root
	LONG	jc	exit			; if error, handle it

if not _FCAB
	cmp	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET
	je	doneThrowAwayCheck

	;
	; If it's a file or link, put up the "throw away file"
	; warning, else put up the "throw away directory" warning
	;

	mov	ax, WARNING_THROW_AWAY_FILE	; assume file
	call	UtilCheckInfoEntrySubdir
	jnc	gotWastebasketWarning

	mov	ax, WARNING_THROW_AWAY_DIR

gotWastebasketWarning:
	test	ds:[si].FOIE_attrs, mask FA_LINK
	jz	haveWarning
	mov	ax, WARNING_THROW_AWAY_LINK
haveWarning:
	call	DeleteWarningCommon
	cmp	ax, YESNO_YES
	je	doneThrowAwayCheck
	stc
	jc	exit

doneThrowAwayCheck:
endif		; if (not _FCAB)
	;
	; check if complete destination file spec. specifies an existing
	; file, if so, give replace warning if needed
	;
	call	CopyMoveExistenceCheck		; do battery of checks
	jc	exit				; if error, exit with err code

;NOTE: we lose update needed for errors deleting existing directory with
;file-busy or access-denied files that are not deleted
;FAIL-CASE: attempt to overwrite directory contain file-in-use.  A Folder
;Window on that directory will not get updated to reflect the successfully
;deleted files

	segmov	es, ds
	lea	di, ds:[si].FOIE_name		; copy/move to same name in
						;  destination
ND <	cmp	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET	>
ND <	jne	wastebasketThrowsAwayTemplatesTooYouKnow		>
ND <	test	ds:[si].FOIE_flags, mask GFHF_TEMPLATE	; force copy if >
ND <	jnz	copyFile				; file is a template >
ND <wastebasketThrowsAwayTemplatesTooYouKnow:		; and NOT throwingaway>

	cmp	ss:[fileOpProgressType], FOPT_COPY
	je	copyFile			; if so, do it
	call	DeskFileMove			; move file to dest path
	jmp	afterOp				; handle results

copyFile:
	call	DeskFileCopy			; copy file to dest path
afterOp:
	jc	exit

	mov	ax, updateStrategy		; retrieve update strategy
	call	MarkWindowForUpdate		; pass ds:dx = source
	clc
exit:

	.leave					; preserves flags
	ret
CopyMoveFileToDir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyMoveExistenceCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks if file exists

CALLED BY:	CopyMoveFileToDir

PASS:		ds	= FileQuickTransferHeader
		ds:si	= FileOperationInfoEntry of file being moved/copied
		current directory is destination directory

RETURN:		carry set if error
			ax - error code
		carry clear if source file can be copied to destination

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyMoveExistenceCheck	proc	near
	uses	bx, cx, dx, ds, si, es, di, bp
	.enter

	clr	ss:[useLocalMoveCopy]		; default to regular copy
	;
	; check if destination exists
	;
	lea	dx, ds:[si].FOIE_name
	call	FileRootGetAttributes		; does file exist in dest.?
	jnc	destExists			; yes
	cmp	ax, ERROR_FILE_NOT_FOUND	; file doesn't exist in dest.?
	je	exitJMP				; correct -- exit with carry
						;  clear
errorExit:
	stc
exitJMP:
	jmp	exit

destExists:
ND<	call	NDCheckIfNotReplaceable		>
ND<LONG	jc	exit				>
	;
	; Used to check for replacing a parent of the src, but that's handled
	; in SetUpCopyMoveParams by the comparison against evilName, which
	; was so gracefully set up by CheckSrcDestConflict

	;
	; We need to check to see if the file we are conflicting with has
	; been merged into our directory by the magic or StandardPaths, or
	; if it is actually a local file.  
	;
	call	IsConflictingFileRemote
	LONG	jc	exit

	mov	ss:[useLocalMoveCopy], -1
	;
	; If the file we are copying is a remote file, then it may conflict
	; with itself, as it may be mapped into our destination.  In this case
	; we want to ignore any warnings (as we are just making a local copy
	; of what was already mapped in anyway) and just create a local copy,
	; so skip to the end of the routine, and later routines will know what
	; to do because we pass them the CLT_REMOTE_SELF value.
	;
	cmp	ax, CLT_REMOTE_SELF
	clc					; no error...
	LONG	je	exit

	;
	; If the file isn't conflicting with itself, it is either local or
	; is mapped in from another StandardPath tree, so we want to warn
	; the user of an overwrite situation.  If it is local, we will delete
	; the local file, but still want to force a local copy, as the regular
	; copy might wind up conflicting with a mapped in remote file that has
	; been exposed by the deletion of the local file that was obscuring it.
	; If it is mapped in, we don't actually delete anything, and copy
	; locally.  Because the mapped in copy will be obscured by the new
	; local version (which is a different copy), in the eyes of the user
	; it is has been overwriten, and therefore we still want the warning.
	; Check the CLT_REMOTE_OTHER or CLT_LOCAL later in the routine when
	; we decide whether or not to delete the destination.
	;

	mov	bx, ax				; save ConflictLocationType
						; across warning
	;
	; dest exists, ask user if s/he wishes to replace name file
	;
if (not _FCAB and not _ZMGR)
	call	ReplaceWarning
else
	mov	ax, WARNING_REPLACE_32_FILE	; use 32 name
	call	DesktopYesNoWarning
endif		; if ((not _FCAB) and (not _ZMGR))
	cmp	ax, YESNO_YES			; user want to replace?
						; (might be DESK_DB_DETACH
						;	or YESNO_CANCEL)
	jne	errorExit			; they don't, return cancel

	;
	; user wishes to replace existing file
	;
	cmp	bx, CLT_REMOTE_OTHER		; no need to delete dest if it
	LONG	je	exit			; is remote...

	;
	; if not CLT_REMOTE_OTHER, it must be CLT_LOCAL.
	;

	call	CheckThatSourceStillExists	; if the source has been 
	LONG jc	exit				; deleted, cancel operation

	;
	; Create a fake FileQuickTransfer block
	;	ds = FileQuickTransferHeader (move/copy source path)
	;	ds:si = FileOperationInfoEntry (move/copy source filename)
	;	destination for move/copy = current dir
	;
	push	bx, cx, ds, si
	mov	ax, size FileQuickTransferHeader + size FileOperationInfoEntry
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc			; bx = handle, ax = segment
	jnc	noMemErr
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	removeExit

noMemErr:
	push	ds, si				; save incoming FOIE
	push	bx				; save buffer handle
	mov	ds, ax
	mov	ds:[FQTH_nextBlock], 0
	mov	ds:[FQTH_UIFA], 0
		; feedback data and remote flag don't matter because this
		; won't be used with a QuickTransfer, just internally.
	mov	ds:[FQTH_numFiles], 1
	mov	si, offset FQTH_pathname
	mov	cx, size FQTH_pathname
	call	FileGetCurrentPath		; bx = disk handle
	mov	ds:[FQTH_diskHandle], bx
	pop	bx				; retreive buffer handle
	segmov	es, ds				; es:di = FOIE_name
	mov	di, offset FQTH_files
	pop	ds, si				; ds:si = incoming FOIE
.assert (offset FOIE_name eq 0)

	mov	cx, size FOIE_name/2
	rep movsw				; copy source name over
	segmov	ds, es				; ds = new FQTH

	mov	ds:[FQTH_files].FOIE_flags, 0
	mov	ds:[FQTH_files].FOIE_info, 0

	sub	sp, 3 * size FileExtAttrDesc
	mov	di, sp
	segmov	es, ss
	mov	es:[di].FEAD_attr, FEA_FILE_TYPE
	mov	es:[di].FEAD_value.segment, ds
	mov	es:[di].FEAD_value.offset, offset FQTH_files.FOIE_type
	mov	es:[di].FEAD_size, size GeosFileType
	add	di, size FileExtAttrDesc

	mov	es:[di].FEAD_attr, FEA_FILE_ATTR
	mov	es:[di].FEAD_value.segment, ds
	mov	es:[di].FEAD_value.offset, offset FQTH_files.FOIE_attrs
	mov	es:[di].FEAD_size, size FileAttrs
	add	di, size FileExtAttrDesc

	mov	es:[di].FEAD_attr, FEA_PATH_INFO
	mov	es:[di].FEAD_value.segment, ds
	mov	es:[di].FEAD_value.offset, offset FQTH_files.FOIE_pathInfo
	mov	es:[di].FEAD_size, size DirPathInfo

	mov	di, sp
	mov	cx, 3
	mov	ax, FEA_MULTIPLE
	mov	dx, offset FQTH_files.FOIE_name
	call	FileGetPathExtAttributes
EC <	WARNING_C WARNING_FILE_ERROR_IGNORED				>

	add	sp, 3 * size FileExtAttrDesc
	;
	; Turn off delete progress if thing being deleted is a file.
	; If it's a directory, it will get turned on again by
	; FileDeleteFileDirCommon, which is OK, I suppose...
	;

	mov	ss:[showDeleteProgress], FALSE
	mov	cx, ss:[fileOpProgressType]
	mov	ax, FOPT_DELETE
	call	SetFileOpProgressBox

	mov	si, offset FQTH_files		; ds:si = new FOIE
	call	ForceFileDeleteFileDir		; else, del dest
						; return with error status
						;	(might be "cancel")
	pushf
	call	MemFree				; free created FQTH

	call	RemoveFileOpProgressBox
	push	ax
	mov_tr	ax, cx
	call	SetFileOpProgressBox
	pop	ax

	popf

removeExit:
	pop	bx, cx, ds, si

exit:
	.leave
	ret
CopyMoveExistenceCheck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckThatSourceStillExists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the source file has been deleted for some reason, we
		don't want to delete the destination and then fail on
		the copy or move.  Better to just bail out entirely.

CALLED BY:	CopyMoveExistenceCheck

PASS:		ds	= segment of FileQuickTransferBlock of source
		ds:dx	= filename of source

RETURN:		carry	= set if source has been deleted
			= clear if source is still there
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/ 6/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckThatSourceStillExists	proc	near
	uses	bx
	.enter

	call	FilePushDir
	push	dx				; save filename offset
	mov	bx, ds:[FQTH_diskHandle]
	lea	dx, ds:[FQTH_pathname]
	call	FileSetCurrentPath
	pop	dx				; restore filename offset
	jc	exit				; bail if there were any
						; problems setting the path

	call	FileRootGetAttributes		; does source exist?
						; carry will be set if there
exit:						; is any problem finding the
	call	FilePopDir			; file

	.leave
	ret
CheckThatSourceStillExists	endp



if _NEWDESK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDCheckIfNotReplaceable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks a file's WOT to see if this is a candidate for being
		replaced by another file.  Only WOT_FOLDER, WOT_DOCUMENT
		and WOT_EXECUTABLE may be replaced.

CALLED BY:	CopyMoveExistenceCheck

PASS:		ds:dx	= filename of item to check
RETURN:		carry	= set if this item may not be replaced
				ax = ERROR_CANNOT_OVERWRITE_THIS_WOT
			= clear if it may be replaced
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/ 5/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NDCheckIfNotReplaceable	proc	near
	uses	bx,cx,dx,si,di,bp
	.enter

	segmov	es, ss
	mov	bp, sp				; preserve old stack
	mov	cx, size NewDeskObjectType
	sub	sp, cx
	mov	di, sp
	mov	ax, FEA_DESKTOP_INFO
	call	FileGetPathExtAttributes
	mov	bx, es:[di]			; put WOT in bx
	mov	sp, bp				; reset stack
	jnc	checkWOT

	;
	; if we can't fetch a WOT, this file doesn't have extended
	; attributes and therefore is not something we have to worry
	; about overwriting.  If it failed for other reasons, go ahead
	; and error for that reason.
	;
	cmp	ax, ERROR_ATTR_NOT_FOUND
	je	okToOverwrite
	jmp	doNotOverwrite

checkWOT:
	cmp	bx, WOT_FOLDER
	je	okToOverwrite

	cmp	bx, WOT_DOCUMENT
	je	okToOverwrite

	cmp	bx, WOT_EXECUTABLE
	je	okToOverwrite

	mov	ax, ERROR_CANNOT_OVERWRITE_THIS_WOT
doNotOverwrite:
	stc					; any other WOT's are sacred
	jmp	exit

okToOverwrite:
	clc

exit:
	.leave
	ret
NDCheckIfNotReplaceable	endp
endif		; if _NEWDESK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsConflictingFileRemote
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if the file that we have a conflict with is 
	a local file, or if it is remote (mapped in because of the StandardPath
	merging of trees).
		If it is remote, there is the posiblity that it is our source
	file, should our source be in a tree that is being mapped to our
	destination.  In this case we don't want to warn the user of an
	overwrite, as we are just copying the same verion that they see in the
	destination to actually *be* in the destination instead of being mapped
	there, and want to copy/move the file to the local destination.
		If it is not our source file, then we want to warn the user
	of an overwrite because the file being moved/copied in will obscure the
	copy that was being mapped in, effectively 'overwriting' it.  We then
	want to copy/move it to the local destination.
		Should the conflicting file be local, we want to delete it,
	but still want to use the FileCopyLocal routine, as the deletion of
	the local file might reveal a mapped in remote file that would cause
	a regular move/copy to complain.

CALLED BY:	CopyMoveExistenceCheck

PASS:		ds	= FileQuickTransferHeader
		ds:si	= FileOperationInfoEntry of file being moved/copied
		current directory is destination directory

RETURN:		carry	= clear if no error
				ax = ConflictLocationType
				ss:[useLocalMoveCopy] updated correctly
			= set on error
				ax = FileError
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/14/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsConflictingFileRemote	proc	near
	uses	bx,cx,dx,si,di
attrArray	local	3 dup (FileExtAttrDesc)
srcDisk		local	word
srcID		local	dword
destDisk	local	word
destID		local	dword
destPathInfo	local	DirPathInfo
	.enter

	mov	ax, ss
	lea	bx, ss:[destDisk]
	lea	cx, ss:[destID]
	lea	dx, ss:[destPathInfo]
	;
	; Diskhandle FEAD
	;
	mov	ss:[attrArray].FEAD_attr, FEA_DISK
	mov	ss:[attrArray].FEAD_value.segment, ax
	mov	ss:[attrArray].FEAD_value.offset, bx	; destDisk is buffer
	mov	ss:[attrArray].FEAD_size, word
	;
	; FileID FEAD
	;
	add	bp, size FileExtAttrDesc		; next FEAD
	mov	ss:[attrArray].FEAD_attr, FEA_FILE_ID
	mov	ss:[attrArray].FEAD_value.segment, ax
	mov	ss:[attrArray].FEAD_value.offset, cx	; destID is buffer
	mov	ss:[attrArray].FEAD_size, dword
	;
	; PathInfo FEAD
	;
	add	bp, size FileExtAttrDesc		; next FEAD
	mov	ss:[attrArray].FEAD_attr, FEA_PATH_INFO
	mov	ss:[attrArray].FEAD_value.segment, ax
	mov	ss:[attrArray].FEAD_value.offset, dx	; destPathInfo is buffer
	mov	ss:[attrArray].FEAD_size, size DirPathInfo

	sub	bp, 2 * (size FileExtAttrDesc)	; restore bp
	segmov	es, ss, di
	lea	di, ss:[attrArray]		; es:di is FEAD array
	mov	dx, si				; ds:dx is filename

	;
	; grab the attributes of the destination
	;
	mov	ax, FEA_MULTIPLE
	mov	cx, 3				; get all three attributes
	call	FileGetPathExtAttributes
	jc	exit

	test	ss:[destPathInfo], mask DPI_EXISTS_LOCALLY
	mov	ax, CLT_LOCAL
	clc					; no error
	jnz	exit

	;
	; grab the attributes of the source
	;
	call	FilePushDir			; save dest directory
	mov	bx, ds:[FQTH_diskHandle]
	mov	dx, offset FQTH_pathname
	call	FileSetCurrentPath		; set source as currentpath
	jc	popDirAndExit

	lea	ax, ss:[srcDisk]
	lea	bx, ss:[srcID]
	mov	ss:[attrArray].FEAD_value.offset, ax	; buffer is srcDisk
	add	bp, size FileExtAttrDesc		; next FEAD
	mov	ss:[attrArray].FEAD_value.offset, bx	; buffer is srcID
	sub	bp, size FileExtAttrDesc	; restore bp
	mov	dx, si				; ds:dx is filename
	mov	ax, FEA_MULTIPLE
	mov	cx, 2				; we only want disk and fileID
	call	FileGetPathExtAttributes
	
popDirAndExit:
	call	FilePopDir			; restore dest directory
	jc	exit

	;
	; OK, so now we have the attributes we want...
	;
	mov	ax, CLT_REMOTE_OTHER		; assume different files...
	mov	bx, ss:[srcDisk]
	cmp	bx, ss:[destDisk]
	clc					; no error
	jne	exit

	movdw	bxcx, ss:[srcID]
	cmpdw	bxcx, ss:[destID]
	clc					; no error
	jne	exit

	mov	ax, CLT_REMOTE_SELF

exit:
	.leave
	ret
IsConflictingFileRemote	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskFileCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy file/directory

CALLED BY: 	CopyMoveFileToDir

PASS:		ds:si 	= FileOperationInfoEntry for source
				(file or directory)
		ds:0	= FileQuickTransferHeader containing source dir
		es:di 	= name for destination
		current directory is destination directory

RETURN:		carry set if error
		carry clear otherwise
		ax - error code
		ss:[recurErrorFlag] set if recursive operation error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (file to copy is not a directory) {
			FileCopyFile(source pathname,
					complete destination pathname);
		} else {
			FileCreateDir(complete destination pathname);
			for each file X in directory {
				DeskFileCopy("source pathname/X",
					"complete destination pathname/X");
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskFileCopy	proc	far
	.enter
	mov	ss:[dirCopyMoveRoutine], offset FileCopyFile
	call	CopyMoveFileOrDir
	.leave
	ret
DeskFileCopy	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskFileMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move file to new directory

CALLED BY: 	CopyMoveFileToDir

PASS:		ds:si 	= FileOperationInfoEntry for source
				(file or directory)
		ds:0	= FileQuickTransferHeader containing source dir
		es:di 	= name for destination
		current directory is destination directory

RETURN:		carry set if error
		carry clear otherwise
		ax - error code
		ss:[recurErrorFlag] set if recursive operation error

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (file to move is not a directory) {
			FileMoveFile(source pathname,
					complete destination pathname);
		} else {
			FileCreateDir(complete destination pathname);
			for each file X in directory {
				FileMove("source pathname/X",
					"complete destination pathname/X");
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/31/89		Initial version
	brianc	10/30/89	use FileMoveFile instead of FileRename
					so different drives are supported

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskFileMove	proc	far
	.enter
	mov	ss:[dirCopyMoveRoutine], offset FileMoveFile
	call	CopyMoveFileOrDir
	.leave
	ret
DeskFileMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyMoveFileOrDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy or move the current file or directory using a function
		that depends on whether it is a file or a directory

CALLED BY:	DeskFileCopy, DeskFileMove
PASS:		ds:si	= FileOperationInfoEntry for source
		ds:0	= FileQuickTransferHeader containing source dir
		es:di	= name for destination
			  current dir is destination directory
		ax	= ConflictLocationType
		ss:[dirCopyMoveRoutine] = routine to call if source is a file
RETURN:		carry set on error:
			ax	= error code
		carry clear if success:
			ax	= destroyed
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyMoveFileOrDir proc	near
	uses	bx, cx, dx, ds, es, si, di, bp
	.enter
if ENSURE_LOCAL_SP_SUBDIRS
	;
	; Ensure that subdirs of Standard Paths exists locally
	;
	call	EnsureLocalStandardPathSubdirs
endif
	;
	; See if the source is a directory or file and react accordingly
	; 
	call	UtilCheckInfoEntrySubdir
	jc	doDirectory

	clr	ax				; no enum info yet
	call	ss:[dirCopyMoveRoutine]		; else, use regular file routine
	jmp	done

	;
	; do directory
	;	ds:si - source FOIE
	;	es:di - destination filespec
	;
doDirectory:
	mov	ss:[recurErrorFlag], 1
	mov	ss:[enteredFileOpRecursion], 0	; no recursion yet
	push	ds:[FQTH_nextBlock]
	clr	ds:[FQTH_nextBlock]
	call	FileCopyMoveDir			; do directory
	pop	ds:[FQTH_nextBlock]
done:
	.leave
	ret
CopyMoveFileOrDir endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy a single file

CALLED BY:	INTERNAL
			DeskFileCopy, FileCopyMoveDir

PASS:		ds:0	= FileQuickTransferHeader
		ds:si	= FileOperationInfoEntry
		es:di - destination file in current directory
		destination file doesn't already exist

RETURN:		carry set if error
			ax - error code
		carry clear if success

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCopyFile	proc	near
		mov	ax, offset doAction
		push	ax
		call	FileCopyOrMoveFile
		ret
doAction:
if TRY_CLOSE_ON_IN_USE_ERROR
		push	bp
		mov	bp, 1				; do copy
		call	TryCloseFileForMoveCopy
		pop	bp
endif
		tst	ss:[useLocalMoveCopy]
		jz	regularCopy
		call	FileCopyLocal
		jmp	afterCopy
regularCopy:
		call	FileCopy
afterCopy:
		retn
FileCopyFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileMoveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move file

CALLED BY:	INTERNAL
			CopyMoveFileOrDir,
			FileCopyMoveDir

PASS:		ds:si 	- source FOIE
		ds:0	= FileQuickTransferHeader
		es:di 	- destination file
		current dir is destination dir

RETURN:		carry set if error
			ax - error code

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/89	Initial version
	dlitwin	11/04/93	added some readonly checks

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMoveFile	proc	near

	call	DoRemoteFileCheck
	jnc	localFile

	call	FileCopyFile
	jmp	exit

localFile:
	clr	ss:[fileMoveSetReadOnly]	; assume not readonly
	test	ds:[si].FOIE_attrs, mask FA_RDONLY
	jz	startMove			; if not readonly, don't worry

	call	FileMoveReadOnlyCheck
	jc	exit				; readonly, user canceled

	cmp	ax, YESNO_YES			; if ax = YESNO_YES, user chose
	clc					;   to move the read only file
	jne	exit
	;
	; move the file and reset the readonly bit afterward
	;
	mov	ss:[fileMoveSetReadOnly], -1	; set reset bit after move

startMove:
	mov	ax, offset doAction
	push	ax
	call	FileCopyOrMoveFile
	jc	exit

	tst	ss:[fileMoveSetReadOnly]
	jz	exit

	push	ds, dx, cx
	segmov	ds, es, dx
	mov	dx, si				; ds:dx is filename
	clr	ch
	mov	cl, ds:[si].FOIE_attrs
	call	FileSetAttributes		; set the readonly bit
	pop	ds, dx, cx

exit:
	ret					; EXIT HERE <------


doAction:
	tst	ss:[useLocalMoveCopy]
	jz	regularMove
	call	DesktopFileMoveLocal		; no FileMoveLocal is currently
	jmp	afterMove			;  supported...
regularMove:
	call	FileMove
afterMove:
if TRY_CLOSE_ON_IN_USE_ERROR
	jnc	afterTryClose
	push	bp
	mov	bp, 0				; do move
	call	TryCloseFileForMoveCopy
	pop	bp
afterTryClose:
endif
	retn

FileMoveFile	endp
FileOpLow	ends
