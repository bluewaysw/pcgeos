COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Util
FILE:		cutilFileOp.asm

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
	brianc	7/89		Initial version

DESCRIPTION:
	This file contains desktop utility routines for REDWOOD ONLY.
	The difference is, this version assumes floppy based operation
	with a fast C: drive, and does things to improve swapping.

	$Id: cutilFileOpRedwood.asm,v 1.2 98/06/03 13:51:09 joon Exp $

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
endif		; ((not _FCAB) and (not _ZMGR))
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
	jc	afterDiskHandleCheck

	tst	ax
	jz	fileIsLocal

	call	MemUnlock
	jmp	setToCopy

fileIsLocal:
	call	ShellGetTrueDiskHandleFromFQT

afterDiskHandleCheck:
	call	MemUnlock
	jnc	noError

	call	DesktopOKError
	stc					; carry - set
	jmp	done

noError:
	test	dx, DISK_IS_STD_PATH_MASK
	jz	compareThem

FXIP<	mov	dx, bx							>
FXIP<	GetResourceSegment dgroup, es, TRASH_BX				>
FXIP<	mov	bx, dx							>
NOFXIP<	segmov	es, <segment idata>, dx					>
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

	cmp	{byte} es:[di], 0
	je	setZeroFlag			; if no tail path
	cmp	{word} es:[di], '\\' or (0 shl 8)
	je	setZeroFlag			; if no tail path

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

	push	ax				; save VM block handle
	mov	ax, ACTIVE_TYPE_FILE_OPERATION
	call	DesktopMarkActive			; application will be active
	pop	ax				; retrieve VM block handle

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

if (not _FCAB and not _ZMGR)

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
	mov	ax, FOPT_DELETE

else		; if ((not _FCAB) and (not _ZMGR))

	mov	ax, FOPT_DELETE			; FCAB and ZMGR always delete

endif		; if ((not _FCAB) and (not _ZMGR))

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
rootPath	char '\\', 0
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
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
NOFXIP<	segmov	es, <segment dgroup>, di				>
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
	;
	; Used to check for replacing a parent of the src, but that's handled
	; in SetUpCopyMoveParams by the comparison against evilName, which
	; was so gracefully set up by CheckSrcDestConflict
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
	call	OverwriteProgress
	LONG jc	exit				; if "cancel", exit

	call	UtilCheckInfoEntrySubdir
	jnc	overwriteFile
	;
	; overwriting a directory, create a fake FileQuickTransfer block
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
	jmp	short overwriteDirExit		; exit with memory error

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
	mov	cx, size FOIE_name
	rep movsb				; copy source name over
	mov	es:[FQTH_files].FOIE_type, GFT_DIRECTORY
	mov	es:[FQTH_files].FOIE_attrs, mask FA_SUBDIR
	mov	es:[FQTH_files].FOIE_flags, 0
	mov	es:[FQTH_files].FOIE_info, 0
	segmov	ds, es				; ds = new FQTH
	mov	si, offset FQTH_files		; ds:si = new FOIE
	call	ForceFileDeleteFileDir		; else, del dest
						; return with error status
						;	(might be "cancel")
	pushf
	call	MemFree				; free created FQTH
	popf
overwriteDirExit:
	pop	bx, cx, ds, si
	jmp	short exit

overwriteFile:
	clr	ax
	call	FileCheckAndDelete		; overwrite file

exit:
	.leave
	ret
CopyMoveExistenceCheck	endp

;
; pass:
;	ds:si	= FileOperationInfoEntry being moved/copied
;	ds:0	= FileQuickTransferHeader
;	current dir is destination dir
; returns:
;	carry clear to continue
;	carry set if cancel
;		ax = YESNO_CANCEL
; destroys:
;	nothing
;
OverwriteProgress	proc	near
	uses	bx
	.enter
	mov	bx, -1				; set flag for overwrite update
	call	UpdateProgressCommon
	.leave
	ret
OverwriteProgress	endp


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

PASS:		ds:si - FOIE of file/dir to move
		ds:0 - FileQuickTransferHeader
		es:di - destination name
		current dir set to directory in which to create the
			destination name

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
	call	ss:[dirCopyMoveRoutine]		; else, use regular file rout
	jmp	done

	;
	; do directory
	;	ds:si - source FOIE
	;	es:di - destination filespec
	;
doDirectory:
	mov	ss:[recurErrorFlag], 1
	mov	ss:[enteredFileOpRecursion], 0	; no recursion yet
	call	FileCopyMoveDir			; do directory
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
	chris	9/ 1/93		Floppies copies go to RAM disk intermediately
				for Redwood

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
		push	bp
		mov	bp, offset CallFileCopy
		call	RedwoodCopyMove
		pop	bp
		retn
		
FileCopyFile	endp




COMMENT @----------------------------------------------------------------------

ROUTINE:	RedwoodCopyMove

SYNOPSIS:	Does a special Redwood copy or move, using an intermediate
		file on the RAM disk.

CALLED BY:	FileCopyFile, FileMoveFile

PASS:		bp -- offset to CallFileCopy or CallFileMove
		ds:0	= FileQuickTransferHeader
		ds:si	= FileOperationInfoEntry
		es:di - destination file in current directory
		destination file doesn't already exist

RETURN:		carry set if error
			ax - error code
		carry clear if success

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	9/ 1/93       	Initial version

------------------------------------------------------------------------------@

RedwoodCopyMove	proc	near
		;
		; Set current dir to SP_TOP, then copy our source file to
		; MMTEMPWW there.   Then copy that file to our destination.
		; Then delete the temp file and restore the path.
		;
		push	ds, si, cx, bx			;save registers

		push	es, di, dx			;save destination

		push	cx
		clr	cx				;don't trash all of mem
		call	FileGetCurrentPath		;get dest disk handle
		pop	cx
		cmp	bx, cx				;same as source?
		jz	normalFileCopy			;yes, do normal copy

		mov	dx, SP_TOP			;set dest file to SP_TOP
		segmov	es, cs
		mov	di, offset tempFile		;temp file

		call	bp				;if copy to RAM fails
		jc	normalFileCopy			;  then try normal copy

		segmov	ds, es				;temp file is source
		mov	si, di
		mov	cx, dx

normalFileCopy:
		pop	es, di, dx			;dest file
		call	bp

		;
		; Delete the temporary file now, if it's there at all.
		;
		push	ax
		pushf
		call	FilePushDir

		mov	bx, SP_TOP
		segmov	ds, cs
		mov	dx, offset nullByte
		call	FileSetCurrentPath
		mov	dx, offset tempFile
		call	FileDelete

		call	FilePopDir
		popf
		pop	ax
;exit:
		pop	ds, si, cx, bx			;restore registers
		ret

RedwoodCopyMove	endp

CallFileMove	proc	near
		call	FileMove
		ret
CallFileMove	endp

CallFileCopy	proc	near
		call	FileCopy
		ret
CallFileCopy	endp

tempFile	char	"MMTEMPWW"
nullByte	byte	0



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
			AX - error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		DOS can move within the same drive, so try using it;
		if (ERROR_DIFFERENT_DEVICE) {
			FileCopyFile(source, dest);
			FileDelete(source);
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/30/89	Initial version
	chris	9/ 1/93		Floppies copies go to RAM disk intermediately
				for Redwood

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileMoveFile	proc	near
	mov	ax, offset doAction
	push	ax
	call	FileCopyOrMoveFile
	ret

doAction:	
	push	bp
	mov	bp, offset CallFileMove
	call	RedwoodCopyMove
	pop	bp

if TRY_CLOSE_ON_IN_USE_ERROR
	jnc	done
	push	bp
	mov	bp, 0				; do move
	call	TryCloseFileForMoveCopy
	pop	bp
done:
endif
	retn
FileMoveFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryCloseFileForMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	setup to call TryCloseFile

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
	call	FileMove		; try move again and return error
done:
	ret
TryCloseFileForMoveCopy	endp

rootPathString	byte	'\\', 0

endif


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

dotPath char '.', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileEnumDirToFQT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate the directory in the given FOIE to form a
		FileQuickTransfer block.

CALLED BY:	INTERNAL - FileCopyMoveDir, ...

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
fileEnumDirReturnAttrs	FileExtAttrDesc \
	<FEA_NAME,		FOIE_name,	size FOIE_name>,
	<FEA_FILE_TYPE,		FOIE_type,	size FOIE_type>,
	<FEA_FILE_ATTR,		FOIE_attrs,	size FOIE_attrs>,
	<FEA_FLAGS,		FOIE_flags, 	size FOIE_flags>,
	<FEA_DESKTOP_INFO,	FOIE_info,	size FOIE_info>,
	<FEA_END_OF_LIST>

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
	; Fill in the header.
	; 
		push	bx, cx
		mov	ds, ax
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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileCopyMoveDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy/move a directory and all its contents to a new directory

CALLED BY:	INTERNAL
			CopyMoveFileOrDir
			FileCopyMoveDir (recursively)

PASS:		ds:si	= FileOperationInfoEntry for directory to copy/move
		ds:0	= FileQuickTransferHeader
		es:di	= destination directory (to be created if
			  not present yet)
		current dir is destination directory

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

DESTROYED:	

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
	uses	es, di
	.enter
	clr	bx			; non overwrite update
	call	UpdateProgressCommon
	LONG jc	exit			; if CANCEL, exit w/AX

	call	SetUpForRecurError		; make sure we have error name
						;	in case of createDir
						;	error
	push	ds
	segmov	ds, es, dx			; es:di is dest name
	mov	dx, di				; ds:dx <- name to create
	call	FileCreateDirWithError		; create destination directory
	pop	ds
	LONG jc	exit				; if error, exit

	
	push	es, ds, si, di		; XXX: ideally we'd unlock the parent
					;  buffer here, to allow it to swap
					;  as we enum the new dir...
	call	FileEnumDirToFQT
	LONG	jc	FQTerror
	jcxz	noMoreFiles

	;
	; Change to destination directory.
	; 
	call	FilePopDir		; return to dest...
	call	FilePushDir		; and save it again
	push	bx, ds
	segmov	ds, es
	mov	dx, di
	clr	bx
	call	FileSetCurrentPath
	pop	bx, ds
	jc	error
	
	mov	si, offset FQTH_files
	segmov	es, ds
fileLoop:
	mov	ss:[enteredFileOpRecursion], 1	; entered recursion-zone
	lea	di, ds:[si].FOIE_name		; es:di <- dest name (same
						;  as source)
	call	UtilCheckInfoEntrySubdir
	jc	isDir
	call	ss:[dirCopyMoveRoutine]		; call routine to move/copy
						;  the file
	jmp	checkError
isDir:
	push	bx, cx, si
	call	FileCopyMoveDir
	pop	bx, cx, si
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
	stc					; assume not
	jne	error				; if not, return error
40$:
	mov	ax, WARNING_RECURSIVE_ACCESS_DENIED
	lea	dx, ds:[si].FOIE_name		; ds:dx <- file name
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES			; continue?
	je	nextFile			; yes, skip erroneous file
	stc					; indicate error
error:
	call	MemFree
	pop	es, ds, si, di			; recover original FOIE
	stc
	jmp	popDirAndExit

noMoreFiles:
	call	MemFree				; free our internal FQT block
	pop	es, ds, si, di			; ds:si <- original FOIE
	
	cmp	ss:[dirCopyMoveRoutine], offset FileCopyFile
	je	popDirAndExit
	
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
	pop	es, ds, si, di
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
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
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
	mov	al, '\\'
	cmp	es:[di-1], al
	je	addTail
	stosb
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
	jc	done

	;
	; Enumerate all files and directories in it.
	;
 
	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, \
			FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS
	mov	ss:[bp].FEP_returnAttrs.segment, cs
	mov	ss:[bp].FEP_returnAttrs.offset, offset fileSizeDirReturnAttrs
	mov	ss:[bp].FEP_returnSize, size FSADAttrs
	mov	ss:[bp].FEP_matchAttrs.segment, 0
	mov	ss:[bp].FEP_bufSize, FE_BUFSIZE_UNLIMITED
	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum
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
	; in CopyMoveExistanceCheck, where we don't want to clear
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
		ds:si - FileOperationInfoEntry to delete

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

	mov	si, dx			;set ds:si = DOS filename
	repe	cmpsb			;repeat compare as long as are equal

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
	uses	ds, si, cx
	push	bx
	.enter
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
	pop	bx				; restore pushed enteredFileO...
						;  from beginning of routine
	.leave

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
	pop	bx
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

	;
	; When showing progress set up a null destination in case this
	; FileCheckAndDelete is being called to overwrite an existing file
	; during a move or copy.  In this case, fileOpProgressType is going
	; to be FOPT_MOVE or FOPT_COPY, so UpdateProgressCommon will try to
	; update the destination name. - brianc 12/2/92
	;

	push	es, di
NOFXIP <	segmov	es, cs						>
NOXIP <		mov	di, offset nullProgressPath			>
	clr	bx				; non overwrite update
FXIP <		push	bx						>
FXIP <		segmov	es, ss, di					>
FXIP <		mov	di, sp			;esdi = null str on stack >
	call	UpdateProgressCommon
FXIP <		pop	di						>
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
endif		; if ((not _FCAB) and (not _ZMGR))

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

nullProgressPath	char	0


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

	call	FileCreateDir
	jnc	exit				; no error, done
	cmp	ax, ERROR_ACCESS_DENIED
	jne	done				; not our error
	mov	ax, ERROR_CANT_CREATE_DIR	; else, assume this error
done:
	stc					; make sure error is indicated
exit:
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
EC <	cmp	{byte} ds:[si]+1, ':'		; drive letter		>
EC <	ERROR_Z	DRIVE_LETTER_NOT_ALLOWED	; not allowed!		>
	cmp	{word} ds:[si], '\\'		; '\' + null ?
	jne	notRoot
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
	jc	notDir

	test	cx, mask FA_LINK
	jnz	notDir

	test	cx, mask FA_SUBDIR
	jz	done			; (carry clear)
	stc
done:
	.leave
	ret

notDir:
	clc
	jmp	done
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
endif		; if ((not _FCAB) and (not _ZMGR))

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
endif		; ((not _FCAB) and (not _ZMGR))
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

endif		; if ((not _FCAB) and (not _ZMGR))


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
EC <	cmp	{byte} ds:[si]+1, ':'		; no drive letters allowed!!>
EC <	ERROR_Z	DRIVE_LETTER_NOT_ALLOWED				>
	lodsw
	cmp	ax, '\\'			; '\' (al) and null (ah)
	jne	okay
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


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSystemFolderDestruction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if operation is about to be performed on a GEOS
		system folder (DOCUMENT, SYSTEM, SYSAPPL, etc.).  If so,
		return and signal error.

CALLED BY:	INTERNAL
			FileDeleteFileDirCommon
			RenameWithOverwrite

PASS:		ds:dx = source name

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
	brianc	08/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSystemFolderDestruction	proc	far
	uses	bx, cx, dx, si, di, bp, ds, es
	.enter

	; create full for full path

	mov	cx, size PathName
	sub	sp, cx
	mov	di, sp
	segmov	es, ss

	mov	si, dx				;ds:si = tail
	clr	bx, dx
	push	di
	call	FileConstructFullPath		; bx <- disk handle
	pop	di

	call	FileParseStandardPath		;ax = StandardPath

	;
	; See if the remainder of the path is either NULL, or
	; BACKSLASH,NULL. 
	;

	cmp	{byte} es:[di], 0
	je	error

	cmp	{word} es:[di], '\\' or (0 shl 8)
	clc
	jne	done

error:
	stc
	mov	ax, ERROR_SYSTEM_FOLDER_DESTRUCTION

done:
	mov	di, sp
	lea	sp, ss:[di][size PathName]

	.leave
	ret
CheckSystemFolderDestruction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareTransferSrcDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if source and destination of quick transfer is
		same or different disk

CALLED BY:	INTERNAL
			FolderEndMoveCopy
			TreeEndMoveCopy
			DriveToolEndMoveCopy

PASS:		bx:ax = destination
		dx:cx = source

RETURN:		carry clear if same
		carry set if different

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompareTransferSrcDest	proc	far
	uses	ax, bx, cx, dx, ds, si, es, di

	diskInfo	local	DiskInfoStruct 

	.enter
	;
	; get disk info from destination
	;
	push	dx, cx			; save source
	mov	si, ax			; bx:si = dest.
	mov	ax, MSG_GET_DISK_INFO
	mov	dx, ss
	push	bp
	lea	bp, diskInfo
	call	ObjMessageCall
	pop	bp
	;
	; get disk info from source
	;
	pop	bx, si			; bx:si = source
	push	ax		 	; save dest disk handle
	mov	ax, MSG_GET_DISK_INFO
	mov	dx, ss
	push	bp
	lea	bp, diskInfo
	call	ObjMessageCall
	pop	bp

	;
	; See if the disk handles match. If they do, the src & dest are
	; the same. If they don't, they aren't...
	; 
	pop	dx
	call	CompareDiskHandles
	clc
	je	done
	stc				; signal mismatch
done:
	.leave
	ret
CompareTransferSrcDest	endp

;
; clear create folder name field
;
; called by:
;	FolderStartCreateDir
;	TreeStartCreateDir
; pass:
;	nothing
; return:
;	nothing
;
CreateDirStuff	proc	far
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset createDirNullString			>
FXIP <		clr	bx						>
FXIP <		push	bx						>
FXIP <		mov	dx, ss						>
FXIP <		mov	bp, sp		;dx:bp = null str on stack	>
	mov	bx, handle CreateDirNameEntry
	mov	si, offset CreateDirNameEntry
	call	CallSetText
FXIP <		pop	bp						>
	ret
CreateDirStuff	endp

createDirNullString	byte	0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFileOpProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up file-operation progress box

CALLED BY:	WastebasketDeleteFiles
		ProcessDragFilesCommon

PASS:		ax - FileOperationProgressTypes
			FOPT_DELETE
			FOPT_THROW_AWAY
			FOPT_MOVE
			FOPT_COPY

RETURN:		ss:[fileOpProgressType] - set to progress type

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFileOpProgressBox	proc	far
	uses	ax, bx, cx, dx, si, di, bp
	.enter
EC <	cmp	ax, LAST_FOPT_TABLE_ENTRY				>
EC <	ERROR_AE	BAD_FILE_OP_PROGRESS_TYPE			>
EC <	test	ax, 1				; check odd		>
EC <	ERROR_NZ	BAD_FILE_OP_PROGRESS_TYPE			>
EC <	cmp	ax, FOPT_NONE						>
EC <	ERROR_Z	BAD_FILE_OP_PROGRESS_TYPE				>
	mov	ss:[fileOpProgressType], ax	; store progress type
	;
	; set correct moniker for file operation progress box
	;	(if move or copy)
	;	ax = progress type
	;
	mov	si, ax
	mov	ss:[cancelOperation], 0		; clear cancel flag
	mov	dx, cs:[FileOpProgressMonikerObjTable][si]
	mov	ss:[cancelMonikerToChange], dx
	mov	cx, cs:[FileOpProgressMonikerTable][si]
	jcxz	skipMoniker			; do not replace moniker
	push	si
	mov	bx, handle ProgressUI
	mov	si, dx				; moniker object
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	call	ObjMessageCall

	pop	si
	mov	ax, MSG_GEN_SET_ENABLED
	; for BA, make a throw away non-stoppable.  This was done because when
	; you stop a throw away of a folder, half of its contents may reside
	; in the wastebasket, but the other half in the original location.  
	; if you try to recover that folder, it will (if you don't know what
	; you are doing and click 'OK' to overwrite the original) delete the
	; half that wasn't thrown away when it overwrites.  This way if they 
	; throw away a folder with multiple items, they must wait until it is
	; done being thrown away, and then they can recover the entire thing
	; should they choose to.  The better solution, merging similarly named
	; folders when recovering (or providing this option in all potential
	; overwrite situations) is more work than I have time to do right now.
	; dlitwin 6/9/93
BA<	cmp	si, FOPT_THROW_AWAY		>
BA<	jne	gotMsg				>
BA<	mov	ax, MSG_GEN_SET_NOT_ENABLED	>
BA<gotMsg:					>
	mov	bx, handle ProgressUI
	mov	si, cs:[FileOpProgressStopTriggerTable][si]
	mov	dl, VUM_NOW
	call	ObjMessageCall

skipMoniker:
	mov	ss:[fileOpProgressBoxUp], FALSE	; box not up yet
	.leave
	ret
SetFileOpProgressBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearFileOpProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take down file-operation progress box

CALLED BY:	WastebasketDeleteFiles
		ProcessDragFilesCommon

PASS:		nothing

RETURN:		ss:[fileOpProgressType] - set to FOPT_NONE
		flags preserved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearFileOpProgressBox	proc	far
	uses	si
	.enter
	pushf					; save flags
	mov	si, FOPT_NONE
	xchg	ss:[fileOpProgressType], si	; clear progress type
						; si = old progress type
	call	TakeDownFileOpBox		; bring down box
	popf					; retrieve flags
	.leave
	ret
ClearFileOpProgressBox	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveFileOpProgressBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take down file-op progress box

CALLED BY:	INTERNAL
		;;	DesktopYesNoBox
		;;	DekstopOKErrorBox
			DeleteFileWarning

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RemoveFileOpProgressBox	proc	near
	uses	si
	.enter
	mov	si, ss:[fileOpProgressType]
	cmp	si, FOPT_NONE
	je	done
	call	TakeDownFileOpBox
done:
	.leave
	ret
RemoveFileOpProgressBox	endp

;
; pass:
;	si = curent fileOpProgresType
;
TakeDownFileOpBox	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	cmp	ss:[fileOpProgressBoxUp], TRUE	; box up?
	jne	done				; nope
	;
	; clear filenames
	;
EC <	cmp	si, LAST_FOPT_TABLE_ENTRY				>
EC <	ERROR_AE	BAD_FILE_OP_PROGRESS_TYPE			>
EC <	test	si, 1				; check odd		>
EC <	ERROR_NZ	BAD_FILE_OP_PROGRESS_TYPE			>
EC <	cmp	si, FOPT_NONE						>
EC <	ERROR_Z	BAD_FILE_OP_PROGRESS_TYPE				>
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset nullFileOpProgressName		>
FXIP <		clr	dx						>
FXIP <		push	dx						>
FXIP <		mov	dx, ss						>
FXIP <		mov	bp, sp		;dx:bp = ptr to null		>
	push	dx, bp
	mov	ax, -1
	call	SetFileOpProgressSrcName	; preserves si
	pop	dx, bp
	mov	ax, -1
	call	SetFileOpProgressDestName
FXIP <		pop	dx						>
	;
	; clear monikers in detach-while-active box, if needed
	; also, update attention needed string
	;
	cmp	ss:[detachActiveHandling], TRUE	; detach-while-active box up?
	jne	afterActiveBoxUpdate		; nope
	cmp	ss:[activeType], ACTIVE_TYPE_FILE_OPERATION
	jne	afterActiveBoxUpdate		; nope
	push	si				; save fileOpProgressType
	call	ClearActiveFileOpMonikers
	pop	si
	cmp	ss:[hackModalBoxUp], TRUE	; file-op-app-active box up?
	jne	afterActiveBoxUpdate		; nope
	call	InformActiveBoxOfAttention	; change to attn-req'd string
						; (in PseudoResident resource)
afterActiveBoxUpdate:
	;
	; take down box
	;
	mov	bx, handle ProgressUI
	mov	si, cs:[FileOpProgressBoxTable][si]
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageCall			; take down box
	mov	ss:[fileOpProgressBoxUp], FALSE	; box not up anymore
done:
	.leave
	ret
TakeDownFileOpBox	endp

nullFileOpProgressName	byte	0

ClearActiveFileOpMonikers	proc	far
	mov	cx, offset ActiveEmptyMoniker
	mov	dx, cx
	push	ds
	segmov	ds, ss				; needed for FIXUP_DS
	call	SetActiveFileOpMonikers		; clear monikers
	pop	ds
	ret
ClearActiveFileOpMonikers	endp

;
; called by:
;	ClearActiveFileOpMonikers (same segment)
;	DeskApplicationActiveAttention (diff. segment)
;	DeskApplicationDetachConfirm (diff. segment)
; pass:
;	cx, dx - monikers for source, destination progress strings
;			in file operation active box
;
SetActiveFileOpMonikers	proc	far
	push	bp
	push	dx				; save destination moniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	mov	bx, handle ActiveUI
	mov	si, offset ActiveFileOpSourceGroup
	call	ObjMessageCallFixup
	pop	cx				; cx = destination moniker
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	mov	si, offset ActiveFileOpDestinationGroup
	call	ObjMessageCallFixup
	pop	bp
	ret
SetActiveFileOpMonikers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateProgress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update file-operation progress boxes

CALLED BY:	FileMoveCopyDir
		FileMoveFile
		FileCopyFile
		FileCheckAndDelete
		FileDeleteDirWithError

PASS:		bx	= non-zero if Overwrite update
			= zero if other
		ds:si	= FileOperationInfoEntry for source
		ds:0	= FileQuickTransferHeader for source
		es:di	= destination name, if needed
		destination directory is current directory

RETURN:		carry clear to continue
		carry set cancel operation
			ax - YESNO_CANCEL

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/19/90	Initial version
	brianc	06/27/90	added cancel support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateProgressCommon	proc	near
	uses	bx, cx, dx, si, di, ds, es, bp
	.enter

if _ZMGR
	;
	; for ZMGR, to avoid powering off during a long file operation
	; because of user-inactivity, bump the mouse - brianc 6/15/93
	;
	push	di
	clr	di
	call	ImGetMousePos			; cx, dx - scr pos
	neg	ss:[mouseBumpAmt]		; negate for next time
	add	cx, ss:[mouseBumpAmt]		; add 1 or -1 to X dir
	call	ImPtrJump
	pop	di
endif

	clr	al
	xchg	ss:[cancelOperation], al
	tst	al				; cancel?
	je	10$				; nope
	mov	ax, YESNO_CANCEL		; return cancel
	stc
	jmp	short exit

10$:
	cmp	ss:[fileOpProgressType], FOPT_NONE
	je	done				; progress box is not up
EC <	test	ss:[fileOpProgressType], 1				>
EC <	ERROR_NZ	BAD_FILE_OP_PROGRESS_TYPE			>
EC <	cmp	ss:[fileOpProgressType], LAST_FOPT_TABLE_ENTRY		>
EC <	ERROR_AE	BAD_FILE_OP_PROGRESS_TYPE			>
	cmp	ss:[fileOpProgressType], FOPT_DELETE
	jne	notDeleteHack
	cmp	ss:[showDeleteProgress], TRUE	; show delete progress?
	jne	done				; nope, skip
notDeleteHack:
	;
	; Call specific routine to update the box.
	; 
	call	UpdateProgressForFOPT
	;
	; put up box, if not already up
	;
	cmp	ss:[fileOpProgressBoxUp], TRUE	; box up yet?
	je	done				; yes
	mov	ss:[fileOpProgressBoxUp], TRUE	; indicate box up
	mov	bx, handle ProgressUI
	mov	si, ss:[fileOpProgressType]	; get progress type
	mov	si, cs:[FileOpProgressBoxTable][si]
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageCall			; put up box
done:
	clc					; continue
exit:
	.leave
	ret
UpdateProgressCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateProgressForFOPT
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up for:
		FOPT_DELETE, FOPT_THROW_AWAY, FOPT_MOVE, FOPT_COPY

CALLED BY:	UpdateProgress

PASS:		bx	= non-zero if Overwrite Update
		ds:si	= FileOperationInfoEntry of source
	  	ds:0	= FileQuickTransferHeader
		if FOPT_DELETE or FOPT_THROW_AWAY:
		  	current dir is dir holding FOIE
		if FOPT_MOVE or FOPT_COPY
		  	es:di	= destination name
		  	current dir is destination dir


RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	  XXX: WANT FULL PATH NAME HERE, BUT IT'S SLOW TO BUILD EACH TIME, SO
	  PROBABLY (YECH) NEED GLOBAL VARIABLE, OR BUILD IT INTO THE FQTH AT
	  THE START AND USE THAT.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/28/92		combined UpdateProgressForMoveorCopy
				 with UpdateProgressForDelete

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateProgressForFOPT	proc	near
	.enter

	mov	ax, ss:[fileOpProgressType]	; ax = progress type
	cmp	ax, FOPT_NONE
	je	exit
	tst	bx
	jz	notOverwrite

	cmp	ax, FOPT_COPY			; skip this if copying
	je	exit				; on overwrite update
	cmp	ax, FOPT_MOVE			; skip this if moving
	je	exit				; on overwrite update

notOverwrite:
		CheckHack <offset FOIE_name eq 0>
	mov	dx, ds
	mov	bp, si
	mov	si, ax 

	clr	ax				; assume default disk handle
	cmp	si, FOPT_DELETE
	je	gotDiskHandle
;no!, if we are throwing away, we are doing a move, so we need to use the
;disk handle in FQTH_diskHandle as the source! - brianc 6/25/92
;	cmp	si, FOPT_THROW_AWAY
;	je	gotDiskHandle
	mov	ax, ds:[FQTH_diskHandle]	; otherwise its a MoveCopy
gotDiskHandle:
	push	es, di
	;
	; If we have a null destination name, don't bother with dest progress
	; name.  This can happen if we pass null because we are doing a
	; FileCheckAndDelete to overwrite a file on a move or copy.
	; (See FileCheckAndDelete) - brianc 12/2/92
	;
	tst	<{byte} es:[di]>		; check if null
	pushf					; save null status
	call	SetFileOpProgressSrcName	; preserves si
	popf
	pop	dx, bp
	jz	exit				; if null destination name, done
	cmp	si, FOPT_DELETE
	je	exit
	cmp	si, FOPT_THROW_AWAY
	je	exit
	clr	ax
	call	SetFileOpProgressDestName
exit:
	.leave
	ret
UpdateProgressForFOPT	endp




;
; dx:00	= FileQuickTransferHeader
; dx:bp = source name (GEOS char set)
; ax = source disk handle
;	(0 to use current disk)
;	(-1 to use no disk)
;
SetFileOpProgressSrcName	proc	near
	uses	si
	.enter
	mov	si, cs:[FileOpProgressSrcNameTable][si]
	mov	di, offset ActiveFileOpSource
	call	SetProgressAndUpdateActiveFileOpIfNeeded
	.leave
	ret
SetFileOpProgressSrcName	endp

;
; dx:00	= FileQuickTransferHeader
; dx:bp = destination name (GEOS char set)
; ax = destination disk handle
;	(0 to use current disk)
;	(-1 to use no disk)
;
SetFileOpProgressDestName	proc	near
	uses	si
	.enter
	mov	si, cs:[FileOpProgressDestNameTable][si]
	tst	si
	jz	done
	mov	di, offset ActiveFileOpDestination
	call	SetProgressAndUpdateActiveFileOpIfNeeded
done:
	.leave
	ret
SetFileOpProgressDestName	endp

SPAUAFOIN_BUFFER_SIZE	equ	PATH_BUFFER_SIZE + FILE_LONGNAME_BUFFER_SIZE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetProgressAndUpdateActiveFileOpIfNeeded
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up progress box strings correctly

CALLED BY:	

PASS:		dx:00 = FileQuickTransferHeader
		dx:bp = progress text (GEOS char set)
		si = progress text field
		di = active file op text field
		ax = disk handle of operation
			(ax = 0 to use current disk handle)
			(ax = -1 to use no disk)

RETURN:		nothing
DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/19/92		added this header, rewrote to add full paths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetProgressAndUpdateActiveFileOpIfNeeded	proc	near
	uses	ax, bx, cx, dx, bp, di, si, ds, es
	.enter

	sub	sp, SPAUAFOIN_BUFFER_SIZE			
	mov	cx, sp
	push	di				; save active file text field
	push	si				; save progress text field
	cmp	ax, -1
	je	gotPath

	push	dx, bp				; save progress text
	segmov	es, ss, di
	mov	di, cx				; es:di points to 
	;
	; when setting up the tail for FileConstructFullPath (ds:si), we use
	; FQTH_pathname if are passing in a disk handle (very likely a
	; standard path).  But if we are using the current directory (ax=0),
	; we don't want to use FQTH_pathname.  Instead, we just pass a
	; null, as the current directory is the full path we desire
	; - brianc 6/25/92
	; Modified to be just null, instead of slash-null (also updated
	; comment above to remove slash-null reference) - brianc 12/2/92
	;
	mov	ds, dx
	mov	si, offset FQTH_pathname	; ds:si is trailing path
	tst	ax				; using current path?
	jnz	notCurPath			; no, use FQTH_pathname
	segmov	ds, cs
	mov	si, offset progressNullPath
notCurPath:
	mov	dx, -1				; non-zero so we put in <XX:>
	mov	bx, ax
	mov	cx, SPAUAFOIN_BUFFER_SIZE
	mov	ax, di				; ax = start of buffer
	call	FileConstructFullPath
						; XXX: this probably isn't
						;	needed as we'll have
						;	at least the drive
						;	letter and colon
	cmp	di, ax				; did we store anything?
	je	needSep				; nope, force seperator
	cmp	{byte} es:[di-1], '\\'		; already got seperator?
	je	haveSep				; yes, don't stick on another
needSep:
	mov	al, '\\'
	stosb
haveSep:
	pop	ds, si				; restore progress text
	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2
	rep	movsw				; copy file name onto end
	mov	dx, es
	mov	bp, sp
	add	bp, 4				; make up for pushes
	
gotPath:		; dx:bp is path
	mov	bx, handle ProgressUI
	pop	si				; restore progress text field
	push	dx, bp
	call	CallSetText

	pop	dx, bp				; retrieve source name
	mov	bx, handle ActiveUI		; bx:si = active text field
	pop	si
	cmp	ss:[detachActiveHandling], TRUE	; detach-while-active box up?
	jne	done				; nope
	cmp	ss:[activeType], ACTIVE_TYPE_FILE_OPERATION
	jne	done				; nope

	call	CallSetText

done:
	add	sp, SPAUAFOIN_BUFFER_SIZE	; remove stack buffer

	.leave
	ret
SetProgressAndUpdateActiveFileOpIfNeeded	endp

progressNullPath	char	0

;
; FileOperationProgressTypes must match this table
;
FileOpProgressBoxTable	label	word
	word	0				; FOPT_NONE
	word	offset DeleteProgressBox	; FOPT_DELETE
	word	offset DeleteProgressBox	; FOPT_THROW_AWAY
	word	offset MoveCopyProgressBox	; FOPT_COPY
	word	offset MoveCopyProgressBox	; FOPT_MOVE

LAST_FOPT_TABLE_ENTRY = ($-FileOpProgressBoxTable)

FileOpProgressSrcNameTable	label	word
	word	0				; FOPT_NONE
	word	offset DeleteProgressName	; FOPT_DELETE
	word	offset DeleteProgressName	; FOPT_THROW_AWAY
	word	offset MoveCopyProgressFrom	; FOPT_COPY
	word	offset MoveCopyProgressFrom	; FOPT_MOVE

FileOpProgressDestNameTable	label	word
	word	0				; FOPT_NONE
	word	0		 		; FOPT_DELETE
	word	0				; FOPT_THROW_AWAY
	word	offset MoveCopyProgressTo	; FOPT_COPY
	word	offset MoveCopyProgressTo	; FOPT_MOVE

FileOpProgressMonikerTable	label	word
	word	0				; FOPT_NONE
	word	offset DeleteProgressMoniker	; FOPT_DELETE
	word	offset ThrowAwayProgressMoniker	; FOPT_THROW_AWAY
	word	offset CopyProgressMoniker	; FOPT_COPY
	word	offset MoveProgressMoniker	; FOPT_MOVE

FileOpProgressMonikerObjTable	label	word
	word	0				; FOPT_NONE
	word	offset DeleteProgressNameGroup	; FOPT_DELETE
	word	offset DeleteProgressNameGroup	; FOPT_THROW_AWAY
	word	offset MoveCopyProgressFromGroup; FOPT_COPY
	word	offset MoveCopyProgressFromGroup; FOPT_MOVE

FileOpProgressStopTriggerTable	label	word
	word	0				; FOPT_NONE
	word	offset DeleteProgressCancel	; FOPT_DELETE
	word	offset DeleteProgressCancel	; FOPT_THROW_AWAY
	word	offset MoveCopyProgressCancel	; FOPT_COPY
	word	offset MoveCopyProgressCancel	; FOPT_MOVE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UtilCheckInfoEntrySubdir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the FileOperationInfoEntry at ds:si is in fact
		a subdirectory

CALLED BY:	INTERNAL

PASS:		ds:si - FileOperationInfoEntry

RETURN:		IF SUBDIR
			carry flag set
		ELSE
			CF clear

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UtilCheckInfoEntrySubdir	proc near
	.enter

	;
	; Both "test" instructions clear the carry
	;

	test	ds:[si].FOIE_attrs, mask FA_LINK
	jnz	done
	test	ds:[si].FOIE_attrs, mask FA_SUBDIR
	jz	done
	stc
done:
	.leave
	ret
UtilCheckInfoEntrySubdir	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TryCloseOrSaveFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	try to close or save file to rename (close), move (save),
		delete (close) file that is in-use

CALLED BY:	

PASS:		ds:dx = filename
		correct path asserted
		cx = 0 to close file
			ax - error code
		cx <> 0 to save file

RETURN:		carry clear if file closed/saved, can try operation again
		carry set if couldn't close
			ax - error code unchanged

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

TCFExtAttrBuf	struct
	TEAB_attr	FileAttrs
	TEAB_type	GeosFileType
	TEAB_creator	GeodeToken
	TEAB_fileID	FileID
	TEAB_disk	word
TCFExtAttrBuf	ends

TCFExtAttrDesc	struct
	TEAD_attr	FileExtAttrDesc
	TEAD_type	FileExtAttrDesc
	TEAD_creator	FileExtAttrDesc
	TEAD_fileID	FileExtAttrDesc
	TEAD_disk	FileExtAttrDesc
TCFExtAttrDesc	ends

TryCloseOrSaveFile	proc	far
	uses	ax, bx, cx, dx, es, di, si

filenameOff	local	word	push	dx
eaBuf		local	TCFExtAttrBuf
eaDesc		local	TCFExtAttrDesc
iacpConnection	local	word
closeSaveMsg	local	word

	.enter

	mov	closeSaveMsg, MSG_GEN_DOCUMENT_CLOSE
	jcxz	haveMsg
	mov	closeSaveMsg, MSG_GEN_DOCUMENT_SAVE
	jmp	short tryClose			; skip checking error code

haveMsg:
	cmp	ax, ERROR_SHARING_VIOLATION
	je	tryClose
	cmp	ax, ERROR_FILE_IN_USE
	je	tryClose
	cmp	ax, ERROR_ACCESS_DENIED
	LONG jne	noClose
tryClose:
	mov	eaDesc.TEAD_attr.FEAD_attr, FEA_FILE_ATTR
	mov	eaDesc.TEAD_attr.FEAD_size, size FileAttrs
	mov	eaDesc.TEAD_attr.FEAD_value.segment, ss
	lea	ax, eaBuf.TEAB_attr
	mov	eaDesc.TEAD_attr.FEAD_value.offset, ax

	mov	eaDesc.TEAD_type.FEAD_attr, FEA_FILE_TYPE
	mov	eaDesc.TEAD_type.FEAD_size, size GeosFileType
	mov	eaDesc.TEAD_type.FEAD_value.segment, ss
	lea	ax, eaBuf.TEAB_type
	mov	eaDesc.TEAD_type.FEAD_value.offset, ax

	mov	eaDesc.TEAD_creator.FEAD_attr, FEA_CREATOR
	mov	eaDesc.TEAD_creator.FEAD_size, size GeodeToken
	mov	eaDesc.TEAD_creator.FEAD_value.segment, ss
	lea	ax, eaBuf.TEAB_creator
	mov	eaDesc.TEAD_creator.FEAD_value.offset, ax

	mov	eaDesc.TEAD_fileID.FEAD_attr, FEA_FILE_ID
	mov	eaDesc.TEAD_fileID.FEAD_size, size FileID
	mov	eaDesc.TEAD_fileID.FEAD_value.segment, ss
	lea	ax, eaBuf.TEAB_fileID
	mov	eaDesc.TEAD_fileID.FEAD_value.offset, ax

	mov	eaDesc.TEAD_disk.FEAD_attr, FEA_DISK
	mov	eaDesc.TEAD_disk.FEAD_size, size word
	mov	eaDesc.TEAD_disk.FEAD_value.segment, ss
	lea	ax, eaBuf.TEAB_disk
	mov	eaDesc.TEAD_disk.FEAD_value.offset, ax

	mov	ax, FEA_MULTIPLE
	segmov	es, ss
	lea	di, eaDesc
	mov	cx, (size TCFExtAttrDesc)/(size FileExtAttrDesc)
	call	FileGetPathExtAttributes
	LONG jc	noClose				; couldn't fetch attrs
						;	-> not closable

	test	eaBuf.TEAB_attr, mask FA_SUBDIR
	LONG jnz	noClose

	cmp	eaBuf.TEAB_type, GFT_VM
	LONG jne	noClose

	mov	ax, {word} eaBuf.TEAB_creator.GT_chars
	or	ax, {word} eaBuf.TEAB_creator.GT_chars+2
	or	ax, eaBuf.TEAB_creator.GT_manufID
	LONG jz	noClose				; no creator

	;
	; Check if really in-use by this system (could be in-use by remote
	; system!)  A necessity for the save-for-copy.
	;
	mov	ax, eaBuf.TEAB_disk		; ax = disk
	movdw	cxdx, eaBuf.TEAB_fileID		; cxdx = file ID
	mov	di, SEGMENT_CS
	mov	si, offset TCFCallback
	clr	bx				; process all files
	call	FileForEach
	LONG jnc	noClose			; not in use, don't bother

	cmp	closeSaveMsg, MSG_GEN_DOCUMENT_SAVE
	je	afterAsk			; don't ask for save
	mov	dx, filenameOff			; ds:dx = filename
	mov	ax, WARNING_OPERATION_FILE_IN_USE
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES
	LONG jne	noClose
afterAsk:

	lea	di, eaBuf.TEAB_creator
	mov	ax, mask IACPCF_FIRST_ONLY or \
			(IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE)
	clr	bx				; don't launch server, just
						;	find an existing one
	push	bp
	call	IACPConnect
	mov	bx, bp
	pop	bp
	jnc	30$
	cmp	ax, IACPCE_NO_SERVER
	LONG je	wasClosed			; if we can't find the server,
						;	(and it was in-use),
						;	assume that the server
						;	went away in the mean-
						;	time -> file was closed
	jmp	noClose				; else, didn't close

30$:
	mov	iacpConnection, bx

	; 1) allocate a queue

	call	GeodeAllocQueue

	; OK, first, before trying to close/save, make sure the document has 
	; finished opening.  Send the document a bogus message, w/a completion
	; message so we know when its done being opened/aborted somehow(?)
	; We can't "call" the server, only send it a message, and it can
	; send us one back. However, we can't go on until we're sure the
	; document is ready.  Through the magic of the IACP completion message,
	; we can do all this.
	;
	; 2) record a junk message to be send to this queue; this is the
	;    completion message we give to IACP
	; 3) Build the dummy message
	; 4) call IACPSendMessage to send the request. When it's done, the
	;    server (or IACP if the server has decided to vanish) will send
	;    the message recorded in #2 to our unattached event queue.
	; 5) call QueueGetMessage to pluck the first message from the head
	;    of the queue. This will block until the server has done its thing.
	; 6) nuke the junk message.
	;
					; bx = queue (dest for completion msg)

	push	bx			; save queue handle
	mov	ax, MSG_META_NOTIFY 
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_DOCUMENT_OPEN_COMPLETE
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; cx <- completion msg

	push	cx, bp
	mov	ax, MSG_META_DUMMY
	mov	bx, segment GenDocumentClass	; ClassedEvent
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	cx, bp
	mov	bx, di			; bx <- msg to send
	mov	dx, TO_APP_MODEL	; send to model document
	mov	ax, IACPS_CLIENT
	;
	; PASS:           bp      = local vars
	;                 bx      = recorded message to send
	;                 dx      = TravelOption, -1 if recorded message
	;				contains the proper destination already
	;                 cx      = completionMsg, 0 if none
	;                 ax      = IACPSide doing the sending.
	; RETURN:         ax      = number of servers to which message was sent
	;
	push	bp
	mov	bp, iacpConnection
	call	IACPSendMessage
	pop	bp
	pop	bx			; get queue handle
	call	QueueGetMessage		; wait for junk completion msg to arrive
	push	bx
	mov_tr	bx, ax			; bx <- junk completion msg
	call	ObjFreeMessage		; nuke it
	pop	bx

	;
	; Send the document a message to close/save. There's a
	; bit of fun, here, as we need to block until the server has
	; processed the request. We can't "call" the server, only send it
	; a message, and it can send us one back. However, we're not supposed
	; to return from this routine until the print has either finished or
	; been aborted.  Through the magic of the IACP completion message,
	; we can do all this.
	;
	; 2) record a junk message to be send to this queue; this is the
	;    completion message we give to IACP
	; 3) Build the Print message
	; 4) call IACPSendMessage to send the request. When it's done, the
	;    server (or IACP if the server has decided to vanish) will send
	;    the message recorded in #2 to our unattached event queue.
	; 5) call QueueGetMessage to pluck the first message from the head
	;    of the queue. This will block until the server has done its thing.
	; 6) nuke the the junk message.
	;
					; bx = queue (dest for completion msg)

	push	bx			; save queue handle
	mov	ax, MSG_META_DUMMY
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; cx <- completion msg

	push	cx, bp
	mov	ax, closeSaveMsg
	mov	bp, 0
	mov	bx, segment GenDocumentClass	; ClassedEvent
	mov	si, offset GenDocumentClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	cx, bp
	mov	bx, di			; bx <- msg to send
	mov	dx, TO_APP_MODEL	; send to model document
	mov	ax, IACPS_CLIENT
	;
	; PASS:           bp      = local vars
	;                 bx      = recorded message to send
	;                 dx      = TravelOption, -1 if recorded message
	;				contains the proper destination already
	;                 cx      = completionMsg, 0 if none
	;                 ax      = IACPSide doing the sending.
	; RETURN:         ax      = number of servers to which message was sent
	;
	push	bp
	mov	bp, iacpConnection
	call	IACPSendMessage
	pop	bp
	pop	bx			; get queue handle
	call	QueueGetMessage		; wait for junk completion msg to arrive
	push	bx
	mov_tr	bx, ax			; bx <- junk completion msg
	call	ObjFreeMessage		; nuke it
	pop	bx

	;
	; send dummy message to app model (document group -- document may be
	; gone) to effectively flush queue for server and actually get the
	; document closed/saved
	;

					; bx = queue (dest for completion msg)

	push	bx			; save queue handle
	mov	ax, MSG_META_DUMMY
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di			; cx <- completion msg

	push	cx, bp
	mov	bp, 0
	mov	ax, MSG_META_DUMMY
	mov	bx, segment GenDocumentGroupClass	; ClassedEvent
	mov	si, offset GenDocumentGroupClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	pop	cx, bp
	mov	bx, di			; bx <- msg to send
	mov	dx, TO_APP_MODEL	; send to model document
	mov	ax, IACPS_CLIENT
	;
	; PASS:           bp      = local vars
	;                 bx      = recorded message to send
	;                 dx      = TravelOption, -1 if recorded message
	;				contains the proper destination already
	;                 cx      = completionMsg, 0 if none
	;                 ax      = IACPSide doing the sending.
	; RETURN:         ax      = number of servers to which message was sent
	;
	push	bp
	mov	bp, iacpConnection
	call	IACPSendMessage
	pop	bp
	pop	bx			; get queue handle
	call	QueueGetMessage		; wait for junk completion msg to arrive
	push	bx
	mov_tr	bx, ax			; bx <- junk completion msg
	call	ObjFreeMessage		; nuke it
	pop	bx

	; 7) nuke the queue
					; bx = queue
	call	GeodeFreeQueue		; nuke the queue (no further need)

	push	bp
	clr	cx, dx				; shutting down the client.
	mov	bp, iacpConnection
	call	IACPShutdown
	pop	bp

wasClosed:
	clc				; indicate success
	jmp	short done

noClose:
	stc
done:
	.leave
	ret
TryCloseOrSaveFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TCFCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback function to check if file is in-use

CALLED BY:	FileForEach (from TryCloseOrSaveFile)

PASS:		ax - disk handle of file in question
		cxdx - FileID of file in question
		bx - handle of opened file

RETURN:		carry set if file matches (i.e. file is in use)
		carry clear otherwise

DESTROYED:	di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		may be broken out as a FileInUse? routine

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TCFCBExtAttrBuf	struct
	TCBEAB_fileID	FileID
	TCBEAB_disk	word
TCFCBExtAttrBuf	ends

TCFCBExtAttrDesc	struct
	TCBEAD_fileID	FileExtAttrDesc
	TCBEAD_disk	FileExtAttrDesc
TCFCBExtAttrDesc	ends

TCFCallback	proc	far
	uses	ax, bx, cx, dx

fileDisk	local	word	\
		push	ax
fileID		local	FileID
eaBuf		local	TCFCBExtAttrBuf
eaDesc		local	TCFCBExtAttrDesc

	.enter

	movdw	fileID, cxdx

	mov	eaDesc.TCBEAD_fileID.FEAD_attr, FEA_FILE_ID
	mov	eaDesc.TCBEAD_fileID.FEAD_size, size FileID
	mov	eaDesc.TCBEAD_fileID.FEAD_value.segment, ss
	lea	ax, eaBuf.TCBEAB_fileID
	mov	eaDesc.TCBEAD_fileID.FEAD_value.offset, ax

	mov	eaDesc.TCBEAD_disk.FEAD_attr, FEA_DISK
	mov	eaDesc.TCBEAD_disk.FEAD_size, size word
	mov	eaDesc.TCBEAD_disk.FEAD_value.segment, ss
	lea	ax, eaBuf.TCBEAB_disk
	mov	eaDesc.TCBEAD_disk.FEAD_value.offset, ax

	mov	ax, FEA_MULTIPLE
	segmov	es, ss
	lea	di, eaDesc
	mov	cx, (size TCFCBExtAttrDesc)/(size FileExtAttrDesc)
	call	FileGetHandleExtAttributes
	jc	noMatch				; couldn't fetch attrs
						;	-> no match

	mov	ax, eaBuf.TCBEAB_disk		; ax = disk
	cmp	ax, fileDisk
	jne	noMatch
	movdw	cxdx, eaBuf.TCBEAB_fileID		; cxdx = file ID
	cmpdw	cxdx, fileID
	jne	noMatch
	stc					; indicate match
	jmp	short done

noMatch:
	clc
done:
	.leave
	ret
TCFCallback	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureLocalStandardPathSubdirs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ensure that the destination directory of a copy, move or
		create dir exists locally

CALLED BY:	INTERNAL
			CopyMoveFileOrDir

PASS:		current directory is destination directory

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		do non-disk accessing stuff first

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		assumes that only one level of non-standard paths exists
		below standard paths need be ensured

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if ENSURE_LOCAL_SP_SUBDIRS

EnsureLocalStandardPathSubdirs	proc	far
pathBuf		local	PathName
dirPathInfo	local	DirPathInfo
	uses	ax, bx, cx, dx, ds, si, es, di
	.enter
	segmov	ds, ss
	lea	si, pathBuf
	mov	cx, size pathBuf
	call	FileGetCurrentPath	; bx = disk handle (might be SP)
	test	bx, DISK_IS_STD_PATH_MASK
	jz	done			; not SP, nothing to do
	cmp	{byte} pathBuf[0], 0	; any tail?
	jz	done			; nope, system will ensure full SP
	;
	; okay, we have SP with tail -- we assume tail is just one component,
	; so we'll just do a create-dir and let the system ensure the local
	; SP before creating the local tail
	;
	; let's actually check to see it the tail is one component, if not,
	; then we must've been ensured previously
	;
	segmov	es, ss
	lea	di, pathBuf
	mov	al, 0
	mov	cx, -1
	repne scasb
	not	cx			; cx = length w/null
	mov	al, '\\'
	lea	di, pathBuf
	repne scasb
	je	done			; found a '\\', more than 1 component
	;
	; one more check to see if current path exists locally
	;
	segmov	ds, cs
	mov	dx, offset curPathPath
	mov	ax, FEA_PATH_INFO
	segmov	es, ss
	lea	di, dirPathInfo
	mov	cx, size dirPathInfo
	call	FileGetPathExtAttributes
	test	dirPathInfo, mask DPI_EXISTS_LOCALLY
	jnz	done			; exists locally, all done
	;
	; now create tail, letting system ensure SPs
	;
	call	FilePushDir
	segmov	ds, cs
	mov	dx, offset elspsNullPath
	call	FileSetCurrentPath
	segmov	ds, ss
	lea	dx, pathBuf
	call	FileCreateDir
	call	FilePopDir
	jc	done			; error create dir, leave at popped dir
	segmov	ds, ss
	lea	dx, pathBuf
	call	FileSetCurrentPath	; else, switch to newly created dir
done:
	.leave
	ret
EnsureLocalStandardPathSubdirs	endp

elspsNullPath	byte	0
curPathPath	byte	'.',0

endif


FileOpLow	ends
