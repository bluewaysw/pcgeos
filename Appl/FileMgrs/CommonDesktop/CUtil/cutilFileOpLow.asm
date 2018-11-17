COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Util
FILE:		cutilFileOpLow.asm

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

	$Id: cutilFileOpLow.asm,v 1.1 97/04/04 15:02:16 newdeal Exp $

------------------------------------------------------------------------------@
FileOpLow	segment resource


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
;	call	FileConstructFullPath		; bx <- disk handle
;this works for links
	call	FileConstructActualPath		; bx <- disk handle
	pop	di

	call	FileParseStandardPath		;ax = StandardPath

if GPC_PRESERVE_DIRECTORIES
	call	CheckIniSpecialFolder
	jc	error
endif
	;
	; See if the remainder of the path is either NULL, or
	; BACKSLASH,NULL. 
	;

SBCS <	cmp	{byte} es:[di], 0					>
DBCS <	cmp	{wchar}es:[di], 0					>
	je	error

SBCS <	cmp	{word} es:[di], C_BACKSLASH or (0 shl 8)		>
DBCS <	cmp	{wchar}es:[di], C_BACKSLASH				>
	clc
	jne	done
DBCS <	cmp	{wchar}es:[di], 0					>
DBCS <	jne	done				;branch (carry clear)	>

error:
	stc
	mov	ax, ERROR_SYSTEM_FOLDER_DESTRUCTION

done:
	mov	di, sp
	lea	sp, ss:[di][size PathName]

	.leave
	ret
CheckSystemFolderDestruction	endp

if 0  ; now read from .ini file
if GPC_PRESERVE_DIRECTORIES
cardGamesDir	TCHAR	"Card Games"
CARD_GAMES_DIR_LENGTH equ 10
gamesDir	TCHAR	"Games"
GAMES_DIR_LENGTH equ 5
homeOfficeDir	TCHAR	"Home Office"
HOME_OFFICE_DIR_LENGTH equ 11
strategyGamesDir	TCHAR	"Strategy Games"
STRATEGY_GAMES_DIR_LENGTH equ 14
toolsDir	TCHAR	"Tools"
TOOLS_DIR_LENGTH equ 5
endif
endif

if GPC_PRESERVE_DIRECTORIES
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSpecialFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if directory is special folder (Home Office, Tools,
		Games, etc.)

CALLED BY:	INTERNAL
			CreateNewFolderWindowCommon

PASS:		cx:dx = pathname
		bp = disk handle

RETURN:		carry set if special folder
		carry clear if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/98	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckSpecialFolder	proc	far
	uses	ax, bx, cx, dx, si, di, bp, ds, es
	.enter

	; create full for full path

	mov	ds, cx
	mov	si, dx
	mov	bx, bp
	mov	cx, size PathName
	sub	sp, cx
	mov	di, sp
	segmov	es, ss

	clr	dx
	push	di
	call	FileConstructActualPath		; bx <- disk handle
	pop	di

	call	FileParseStandardPath		;ax = StandardPath

	call	CheckIniSpecialFolder
	mov	ax, ERROR_SYSTEM_FOLDER_DESTRUCTION	; in case special folder
done::
	mov	di, sp
	lea	sp, ss:[di][size PathName]
	.leave
	ret
CheckSpecialFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIniSpecialFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if directory is special folder specified in .ini
		file

CALLED BY:	INTERNAL
			CheckSystemFolderDestruction
			CheckSpecialFolder

PASS:		ax = StandardPath/disk handle
		es:di = path tail

RETURN:		carry set if .ini special folder
		carry clear if not

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CISFParams struct
	CISFP_diskHandle	word
	CISFP_path		fptr
CISFParams ends

CheckIniSpecialFolder	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es
cisfParams	local	CISFParams
	.enter
	mov	cisfParams.CISFP_diskHandle, ax
	movdw	cisfParams.CISFP_path, esdi
	;
	; enumerate .ini special folder string section
	;
	segmov	es, ss, bx
	lea	bx, cisfParams
	segmov	ds, cs, cx
	mov	si, offset specialFolderCat
	mov	dx, offset specialFolderKey
	mov	di, SEGMENT_CS
	mov	ax, offset CISFCallback
	push	bp
	mov	bp, 0
	call	InitFileEnumStringSection
	pop	bp
	.leave
	ret
CheckIniSpecialFolder	endp

specialFolderCat	char	'fileManager', 0
specialFolderKey	char	'cuiFolders', 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CISFCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback to check if directory is special folder specified
		in .ini file

CALLED BY:	CheckIniSpecialFolder via InitFileEnumStringSection

PASS:		ds:si = string section (<SP>,<path>)
		es:bx = CISFParams
		dx = section #
		cx = section length

RETURN:		carry set if .ini special folder (stop enumeration)
		carry clear if not (continue enumeration)

DESTROYED:	ax, cx, dx, di, si, bp, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	1/2/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CISFCallback	proc	far
	uses	es
	.enter
SBCS <	clr	ah							>
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, '0'
	jb	notIniPath			; bad disk handle
	LocalCmpChar	ax, '9'
	ja	notIniPath			; bad disk handle
	sub	ax, '0'
	mov	cx, ax
SBCS <	clr	ah							>
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, ','			; single digit disk handle?
	je	doCompare			; yes
	LocalCmpChar	ax, '0'
	jb	notIniPath
	LocalCmpChar	ax, '9'
	ja	notIniPath
	sub	ax, '0'
	mov	dl, 10
	mul	dl
	add	cx, ax				; cx = two digit disk handle
	LocalGetChar	ax, dssi
	LocalCmpChar	ax, ','
	jne	notIniPath			; max two-digit disk handle
doCompare:
	mov	dx, es:[bx].CISFP_diskHandle
	mov	di, es:[bx].CISFP_path.offset
	mov	es, es:[bx].CISFP_path.segment
	call	FileComparePaths
	cmp	al, PCT_EQUAL
	stc					; assume equal
	je	done
notIniPath:
	clc					; else, not equal
done:
	.leave
	ret
CISFCallback	endp

endif  ; GPC_PRESERVE_DIRECTORIES


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
NOFXIP< mov	dx, cs						>
NOFXIP<	mov	bp, offset createDirNullString			>
FXIP <	clr	bx						>
FXIP <	push	bx						>
FXIP <	mov	dx, ss						>
FXIP <	mov	bp, sp		;dx:bp = null str on stack	>
	mov	bx, handle CreateDirNameEntry
	mov	si, offset CreateDirNameEntry
	call	CallSetText
FXIP <	pop	bp						>
		ret
CreateDirStuff	endp

if not _FXIP
SBCS <createDirNullString	byte	0				>
DBCS <createDirNullString	wchar	0				>
endif


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
		;;	DesktopOKErrorBox
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
NOFXIP<	mov	dx, cs						>
NOFXIP<	mov	bp, offset nullFileOpProgressName		>
FXIP <	clr	dx						>
FXIP <	push	dx						>
FXIP <	mov	dx, ss						>
FXIP <	mov	bp, sp		;dx:bp = ptr to null		>
	push	dx, bp
	mov	ax, -1
	call	SetFileOpProgressSrcName	; preserves si
	pop	dx, bp
	mov	ax, -1
	call	SetFileOpProgressDestName
FXIP <	pop	dx						>
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

if not _FXIP
SBCS <nullFileOpProgressName	byte	0				>
DBCS <nullFileOpProgressName	wchar	0				>
endif

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

CALLED BY:	FileCopyMoveDir
		FileMoveFile
		FileCopyFile
		FileCheckAndDelete
		FileDeleteDirWithError

PASS:		ds:si	= FileOperationInfoEntry for source
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

if _AVOID_POWER_OFF
	;
	; Avoid powering off during a long file operation
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
	jz	10$				; nope
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

PASS:		ds:si	= FileOperationInfoEntry of source
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
SBCS <	tst	<{byte} es:[di]>		; check if null		>
DBCS <	tst	{wchar}es:[di]			; check if null		>
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
NOFXIP< segmov	ds, cs						>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX		>
	mov	si, offset progressNullPath
notCurPath:
	mov	dx, -1				; non-zero so we put in <XX:>
	mov	bx, ax
	mov	cx, SPAUAFOIN_BUFFER_SIZE
	mov	ax, di				; ax = start of buffer
if GPC_FILE_OP_DIALOG_PATHNAME
	push	ax
	call	FileConstructActualPath
	pop	ax
	LocalStrLength
	LocalPrevChar	esdi			; point at null-term
else
	call	FileConstructFullPath
endif
						; XXX: this probably isn't
						;	needed as we'll have
						;	at least the drive
						;	letter and colon
	cmp	di, ax				; did we store anything?
	je	needSep				; nope, force seperator
SBCS <	cmp	{byte} es:[di-1], C_BACKSLASH	; already got seperator? >
DBCS <	cmp	{wchar} es:[di-2], C_BACKSLASH	; already got separator? >
	je	haveSep				; yes, don't stick on another
needSep:
SBCS <	mov	al, C_BACKSLASH						>
DBCS <	mov	ax, C_BACKSLASH						>
	LocalPutChar esdi, ax
haveSep:
	pop	ds, si				; restore progress text
	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2
	rep	movsw				; copy file name onto end
	mov	dx, es
	mov	bp, sp
	add	bp, 4				; make up for pushes
	
gotPath:		; dx:bp is path
if GPC_FILE_OP_DIALOG_PATHNAME
	call	NormalizeProgressPath		; may be new buffer (dx:bp)
endif
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
if GPC_FILE_OP_DIALOG_PATHNAME
	call	ClearProgressPathBuffer		; clear new buffer, if any
endif
	add	sp, SPAUAFOIN_BUFFER_SIZE	; remove stack buffer

	.leave
	ret
SetProgressAndUpdateActiveFileOpIfNeeded	endp

if _FXIP
idata	segment
endif

SBCS <progressNullPath	char	0					>
DBCS <progressNullPath	wchar	0					>

if _FXIP
idata	ends
endif

if GPC_FILE_OP_DIALOG_PATHNAME
idata	segment
progressPathBuffer	hptr	0
idata	ends

;
; pass: dx:bp = progress path
; return: ss:[progressPathBuffer]
;
NormalizeProgressPath	proc	near
	uses	ax, bx, cx, si, di, ds, es
	.enter
	mov	es, dx
	mov	di, bp		; es:di = path
	clr	bx		; path contains drive name
	call	FileParseStandardPath
	mov	cx, ax		; save SP constant

	GetResourceHandleNS	FileOpDialogStrings, bx
	call	MemLock
	mov	ds, ax		; ds <- FileOpDialogString resource
	mov	ax, cx		; ax <- SP constant
	
	cmp	ax, SP_DOCUMENT
	jne	notDoc
	mov	si, offset docDirText
	mov	si, ds:[si]
	call	getStrLen	; cx <- len (with slash)

spCommon:
	mov	dx, ds
	cmp	{TCHAR}es:[di], 0
	jne	haveSlash
	dec	cx		; no tail, no slash	
haveSlash:
	push	cx
	mov	ax, SPAUAFOIN_BUFFER_SIZE
	mov	cx, (mask HAF_ZERO_INIT shl 8) or ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	pop	cx
	jc	done		; mem error, no normalize
	pushdw	esdi		; save tail offset
	mov	ss:[progressPathBuffer], bx
	mov	es, ax
	clr	di
	LocalCopyNString
	popdw	dssi		; ds:si = tail, or just null
	LocalCopyString
	mov	dx, es
	clr	bp
	jmp	short done

notDoc:
	cmp	ax, SP_APPLICATION
	jne	notAppDoc
	mov	si, offset appDirText
	mov	si, ds:[si]
	call	getStrLen		; assume tail, need slash 
	jmp	short spCommon

notAppDoc:
	cmp	ax, SP_WASTE_BASKET
	jne	notWaste
	mov	si, offset wasteDirText
	mov	si, ds:[si]
	call	getStrLen		; assume tail, need slash
	jmp	short spCommon

notWaste:
	cmp	ax, STANDARD_PATH_OF_DESKTOP_VOLUME
	jne	notAppDocDesktop
	push	si
	mov	si, offset desktopPath
	mov	si, ds:[si]
	call	getStrLen
	call	LocalCmpStringsNoCase
	pop	si
	jne	notAppDocDesktop
	mov	bx, cx
	cmp	{TCHAR}es:[di][bx], 0
	je	gotDesktop
	cmp	{TCHAR}es:[di][bx], '\\'
	jne	notAppDocDesktop
	inc	di			; skip past "desktop\" in path
gotDesktop:
	add	di, bx			; skip past "desktop" in path
	mov	si, offset desktopText
	mov	si, ds:[si]
	call	getStrLen
	jmp	short spCommon

notAppDocDesktop:
done:
	GetResourceHandleNS	FileOpDialogStrings, bx
	call	MemUnlock
	.leave
	ret

getStrLen:
SBCS <	clr	al >
DBCS <	clr	ax >
	pushdw	esdi
	segmov	es, ds, cx
	mov	cx, -1
	mov	di, si
SBCS <	repne	scasb >
DBCS <  repne	scasw >
	not	cx
	dec	cx
	popdw	esdi
	retn
NormalizeProgressPath	endp

ClearProgressPathBuffer	proc	near
	uses	bx
	.enter
	clr	bx
	xchg	bx, ss:[progressPathBuffer]
	tst	bx
	jz	done
	call	MemFree
done:
	.leave
	ret
ClearProgressPathBuffer	endp
endif

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
	chrisb	9/24/92   	Initial version.

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
SBCS <	cmp	{byte} pathBuf[0], 0	; any tail?			>
DBCS <	cmp	{wchar} pathBuf[0], 0	; any tail?			>
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
SBCS <	mov	al, 0							>
DBCS <	clr	ax							>
	mov	cx, -1
SBCS <	repne scasb							>
DBCS <	repne scasw							>
	not	cx			; cx = length w/null
	LocalLoadChar ax, C_BACKSLASH
	lea	di, pathBuf
SBCS <	repne scasb							>
DBCS <	repne scasw							>
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
	call	ShellPushToRoot
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

LocalDefNLString curPathPath <'.'>
LocalDefNLString elspsNullPath <0>

endif


FileOpLow	ends
