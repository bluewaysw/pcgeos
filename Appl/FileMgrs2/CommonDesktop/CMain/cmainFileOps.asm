COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Main
FILE:		mainFileOps.asm

ROUTINES:
	INT	RenameWithOverwrite - rename file, overwriting existing one
	INT	UpdateFilenameList - update filename list in dialog box
	INT	ShowFileOpStatus - report file operation and filename
	INT	ShowFileOpResult - report file operation results
	INT	GetCheckOneFilename - parse filename list for single filename
	INT	GetDestinationName - handle wildcards in dest. filename
	INT	WildcardRename - rename with wildcards
	INT	WildcardDelete - delete with wildcards
	INT	WildcardMove - move with wildcards
	INT	WildcardCopy - copy with wildcards
	INT	CheckForWildcards - check path/filename for wildcard chars
	INT	BuildWildcardBuffer - build list of filenames from wildcard

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/89		Initial version

DESCRIPTION:
	This file contains support routines for file operations.

	$Id: cmainFileOps.asm,v 1.3 98/06/03 13:37:21 joon Exp $

------------------------------------------------------------------------------@

FileOperation segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopFileOpSkip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip to next file in file list for this file operation,
		dismisses file op box if no more files

CALLED BY:	MSG_FILE_OP_SKIP

PASS:		cx - file op box chunk
		dx - file op file list chunk

RETURN:		carry set if dismissed
		carry clear otherwise

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/23/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopFileOpSkip	method	DesktopClass, MSG_FILE_OP_SKIP_FILE
	push	cx				; save file op box chunk
	mov	bx, handle FileOperationUI
	mov	si, dx
	mov	ax, MSG_SHOW_NEXT_FILE	; skip to next file
	call	ObjMessageCall
	pop	si				; si = file op box
	jnc	done			; => file being shown, so leave up

	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessageForce
	stc
done:
	ret
DesktopFileOpSkip	endm



;
; file operation status strings
;
;moved for LOCALIZATION - brianc 11/30/90
;renameStatusString	byte	'Renaming ',0
;createDirStatusString	byte	'Creating folder ',0
;duplicateStatusString	byte	'Duplicating ',0
;changeAttrStatusString	byte	'Changing attributes of ',0
if 0
renameResultString	byte	' files renamed.',0
renameOneResultString	byte	' file renamed.',0
createDirResultString	byte	' folders created.',0
createDirOneResultString	byte	' folder created.',0
duplicateResultString	byte	' files duplicated.',0
duplicateOneResultString	byte	' file duplicated.',0
changeAttrResultString	byte	' files with attributes changed.',0
changeAttrOneResultString	byte	' file with attributes changed.',0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopEndRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rename file(s) specified by dialog box

CALLED BY:	MSG_META_END_RENAME

PASS:

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/22/89		Initial version
	brianc	10/11/89	added wildcard support
	brianc	1/18/90		hacked for 8.3 and 32 name support

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopEndRename	method	DesktopClass, MSG_FM_END_RENAME
	call	ShowHourglass
	call	InitForWindowUpdate
	;
	; disable name entry field and reply bar
	;
	mov	bx, handle FileOperationUI
	mov	si, offset FileOperationUI:RenameToEntry
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	cx, offset FileOperationUI:RenameControl
	call	FileOpDisableControls
	;
	; change to directory specified in rename box, we don't care what
	; directory we are in when we quit, so no need to save current
	; directory
	;
	mov	si, offset FileOperationUI:RenameFromEntry
	call	GetSrcFromFileListAndSetCurDir
	jnc	notDone
unlockDone:
	tst	ax
LONG	jz	done
	call	MemUnlock
	jmp	done				; if no more, done
notDone:
	;
	; get destination filename
	;
	push	bx, dx
	mov	si, offset FileOperationUI:RenameToEntry
	call	CallGetText			; get dest. filename(s)
	pop	bx, ax
	jcxz	unlockDone			; if no dest. name, done

	; check if the destination file name has visible characters
	push	bx, ax
	mov	bx, dx
	call	MemLock
	push	ds
	mov	ds, ax
	clr	dx			; ds:dx = beg. of name buffer
	call	CheckForBlankName
	pushf
	call	MemUnlock
	popf
	mov	dx, bx
	pop	ds
	pop	bx, ax
	jnc	visibleDestFile
	mov	ax, ERROR_BLANK_NAME
	call	DesktopOKError

	jmp	done
visibleDestFile:

	push	bx				; save FQT
	mov	bx, dx
	mov	dx, ax				; ds:dx <- FOIE

	push	bx
	call	MemLock				; lock dest. filename buffer
	mov	es, ax				; es:di = dest fname
	clr	di
	;
	; update rename status in rename box
	;
	mov	si, offset FileOperationUI:RenameStatus	; status field
	mov	bp, offset RenameStatusString	; status text
		CheckHack <offset FOIE_name eq 0>
	call	ShowFileOpStatus
	;
	; rename file
	;	es:di = entered destination name
	;	ds:dx = FOIE
	;

	CheckHack	<offset FOIE_name eq 0>
	call	RenameWithOverwrite		; rename ds:dx to es:di
	mov	cx, 1				; one file renamed
	jnc	noError
	mov	cx, 0				; no files renamed
	call	DesktopOKError			; report error
	jnc	noError
	cmp	ax, DESK_DB_DETACH		; detaching, no update
	je	noUpdate
	cmp	ax, YESNO_CANCEL		; user-cancel operation, update
	je	finishUp			;	previous files

	cmp	ax, YESNO_NO			; no rename, just update name
	je	updateNames			;	list
	stc					; don't update names
	jmp	finishUp


noError:
	;
	; update folder windows
	;
	pushf
	mov	ax, RENAME_UPDATE_STRATEGY
	call	MarkWindowForUpdate		; pass ds:dx = source name
						; preserves cx
	popf
	jc	finishUp			; if error, don't update names
updateNames:
	;
	; update name entries in rename dialog box
	;	(if no more files, box will be dismissed)
	;
	mov	ax, MSG_RENAME_NEXT
	mov	si, offset FileOperationUI:RenameToEntry
	call	UpdateSrcAndDestNames		; move to next file when done
finishUp:
	;
	; show rename results
	;
	mov	si, offset FileOperationUI:RenameStatus	; result field
	call	ShowFileOpResult		; show file count of renamed
	;
	; finish up
	;
	call	UpdateMarkedWindows		; update affected window(s)
noUpdate:
	mov	ss:[recurErrorFlag], 0		; clear error handling flag
	pop	bx				; throw away dest. fname buffer
	call	MemFree

	pop	bx				; bx <- FQT block
	call	MemUnlock

done:
	mov	ax, SP_TOP			; just go to top-level path
	call	FileSetStandardPath
	;
	; disable name entry field and reply bar
	;
	mov	bx, handle FileOperationUI
	mov	si, offset FileOperationUI:RenameToEntry
	mov	ax, MSG_GEN_SET_ENABLED
	mov	cx, offset FileOperationUI:RenameControl
	call	FileOpDisableControls
	;
	; finish up
	;
	call	HideHourglass
	ret
DesktopEndRename	endp

;
; pass:
;	bx - UI object handle
;	si - name entry field
;	ax - method
;	cx - reply bar
FileOpDisableControls	proc	near
	push	ax				; save method
	push	cx				; save reply bar
	mov	dl, VUM_NOW
	call	ObjMessageCall			; do name entry
	pop	si				; retrieve reply bar
	pop	ax				; retrieve method
	mov	dl, VUM_NOW
	call	ObjMessageCall			; do reply bar
	ret
FileOpDisableControls	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopRenameNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move to next file in Rename dialog box

CALLED BY:	MSG_RENAME_NEXT

PASS:
RETURN:
DESTROYED:

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopRenameNext	method	DesktopClass, MSG_RENAME_NEXT
	;
	; tell file list to show next file
	;
	mov	cx, offset RenameBox
	mov	dx, offset RenameFromEntry
	mov	ax, MSG_FILE_OP_SKIP_FILE
	mov	bx, handle 0			; send to ourselves
	call	ObjMessageCall
	jc	exit				; no more files
	;
	; then update destination name field characteristics for this file
	; and fill source name as default destination name
	;
	call	RenameStuff
exit:
	ret
DesktopRenameNext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopEndCreateDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	create directory/directories specified by dialog box

CALLED BY:	MSG_META_END_CREATE_DIR

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
	brianc	10/12/89	added wildcard checking

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopEndCreateDir	method	DesktopClass, MSG_FM_END_CREATE_DIR
	call	ShowHourglass
	call	InitForWindowUpdate
	;
	; temporarily change to directory specified in create dir box
	;
	mov	bx, offset FileOperationUI:CreateDirBox
	mov	si, offset FileOperationUI:CreateDirCurDir
	call	ChangeToFileOpSrcDir
	LONG jc	exit				; if error reported, done
if (_ZMGR and not _PMGR)
MAX_NUM_ZMGR_WORLD_DIRS = 22	; 21 + 1 for the Desk Accessories folder
				;	which doesn't show up in Express Menu
	;
	; for ZMGR, limit number of directories allowed in WORLD
	;
	push	ax				; allocate two bytes on stack
	segmov	ds, ss
	mov	si, sp
	mov	cx, size word
	call	FileGetCurrentPath		; bx = disk handle
	pop	ax				; ax = two bytes of path
	cmp	bx, SP_APPLICATION		; WORLD?
	jne	allowDir			; nope
if DBCS_PCGEOS
	ERROR	-1
PrintMessage <fix DesktopEndCreateDir>
endif
	cmp	ax, '\\' or (0 shl 8)		; with null path?
	je	checkNumDirs
	cmp	al, 0				; or null path?
	jne	allowDir
checkNumDirs:
	sub	sp, size FileEnumParams
	mov	bp, sp
	mov	ss:[bp].FEP_searchFlags, mask FESF_DIRS
	mov	ss:[bp].FEP_returnAttrs.segment, 0
	mov	ss:[bp].FEP_returnAttrs.offset, FESRT_COUNT_ONLY
	mov	ss:[bp].FEP_returnSize, 0
	mov	ss:[bp].FEP_matchAttrs.segment, 0
	mov	ss:[bp].FEP_bufSize, 0
	mov	ss:[bp].FEP_skipCount, 0
	call	FileEnum			; dx = count
	jc	allowDir			; detect error later
	cmp	dx, MAX_NUM_ZMGR_WORLD_DIRS
	jb	allowDir
	mov	ax, ERROR_TOO_MANY_WORLD_DIRS
	call	DesktopOKError
	mov	cx, 1				; pretend dirs were created
	jmp	DECD_noFiles			; clean up

allowDir:
endif
	;
	; get source filename(s) buffer
	;
	mov	si, offset FileOperationUI:CreateDirNameEntry
	call	CallGetText			; get filename(s)
	tst	cx
	mov	cx, 0				; count of directories created
						;	(preserve flags)
	LONG jz	DECD_noFiles			; if no files, done
	mov	bx, dx
	push	bx
	call	MemLock				; lock filename buffer
	mov	ds, ax				; ds = filename buffer segment
	clr	dx				; ds:dx = beg. of fname buffer
	;
	; create directory
	;	ds:dx = directory name
	;
	call	PrepDSDXForError		; do this while...?
	mov	si, offset FileOperationUI:CreateDirStatus	; status field
	mov	bp, offset CreateDirStatusString ; status text
	clc					; DOS name, need conversion
	call	ShowFileOpStatus		; use common status reporting

	call	CheckForBlankName
	jc	dirError

if ENSURE_LOCAL_SP_SUBDIRS
	;
	; make sure that SP subdirs exist locally - brianc 6/7/93
	;
	call	EnsureLocalStandardPathSubdirs
endif

	call	FileCreateDirWithError		; ds:dx = filename
	jnc	DECD_noError
dirError:
	call	DesktopOKError
						; returns C=1 for error
	jmp	short DECD_noCreate
DECD_noError:
	mov	ax, CREATE_DIR_UPDATE_STRATEGY
	mov	si, dx				; pass ds:si = new dir. name
	call	MarkWindowForUpdate
	inc	cx				; bump created dir count
	clc					; indicate no error
DECD_noCreate:
	mov	si, offset FileOperationUI:CreateDirStatus	; result field
	push	cx
	call	ShowFileOpResult		; show number of dirs created
	call	UpdateMarkedWindows		; redraw affected window(s)
	pop	cx
	pop	bx				; throw away filename buffer
	call	MemFree
DECD_noFiles:
	mov	ax, SP_TOP			; just go to top-level path
	call	FileSetStandardPath
	;
	; if no errors, bring down box
	;
	tst	cx				; any dirs created?
	jz	exit				; no
	mov	bx, handle FileOperationUI	; yes, bring down box
	mov	si, offset CreateDirBox
	mov	cx, IC_DISMISS
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	call	ObjMessageCall
exit:
	call	HideHourglass
	ret
DesktopEndCreateDir	endp

PrepDSDXForError	proc	near
	uses	es, di, si, cx
	.enter
NOFXIP<	segmov	es, dgroup, di						>
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
	mov	di, offset fileOperationInfoEntryBuffer
	CheckHack <offset FOIE_name eq 0>
	mov	si, dx
	mov	cx, size FOIE_name
	rep movsb
	.leave
	ret
PrepDSDXForError	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForBlankName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if a string contains any non-blank characters
		before its null-terminator.

CALLED BY:	DesktopEndCreateDir

PASS:		ds:dx - string

RETURN:		carry	set if string is blank (or null string)
				ax - ERROR_BLANK_NAME
			clear if name has visible characters

DESTROYED:	nothing

SIDE EFFECTS:
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForBlankName	proc	near
	uses	si
	.enter

	mov	si, dx				; ds:si is string

blankCheck:
	LocalGetChar ax, dssi			;ax <- character
	LocalIsNull ax				;NULL?
	jz	noVisCharFound			;branch if reached NULL
SBCS <	clr	ah							>
	call	LocalIsSpace			;space?
	jnz	blankCheck			;branch if still spaces

	clc
	jmp	exit

noVisCharFound:
	mov	ax, ERROR_BLANK_NAME
	stc
exit:
	.leave
	ret
CheckForBlankName	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopEndDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	duplicate file(s) specified by dialog box

CALLED BY:	MSG_FM_END_DUPLICATE

PASS:

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopEndDuplicate	method	dynamic DesktopClass, MSG_FM_END_DUPLICATE
	call	ShowHourglass
	call	InitForWindowUpdate
        mov     ss:[enteredFileOpRecursion], 0  ; in case of early error
	mov	ax, FOPT_COPY
	call	SetFileOpProgressBox
	;
	; disable name entry field and reply bar
	;
	mov	bx, handle FileOperationUI
	mov	si, offset FileOperationUI:DuplicateToEntry
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	cx, offset FileOperationUI:DuplicateControl
	call	FileOpDisableControls
	;
	; get source path and source name
	;	returns:
	;		ds = FQT block
	;		ds:dx - source name info
	;
	mov	ax, offset FileOperationUI:DuplicateFromEntry
	mov	bx, offset FileOperationUI:DuplicateBox
	mov	si, offset FileOperationUI:DuplicateCurDir
	call	CopyMoveSourceSetUp
	LONG jc	done				; no more files

	push	bx, dx				; save FQT & FOIE offset
	mov	bx, ds:[FQTH_diskHandle]
	mov	dx, offset FQTH_pathname
	call	FileSetCurrentPath
	LONG jc	errorNoUpdateDestFreed

	;
	; get destination name
	;
	mov	si, offset FileOperationUI:DuplicateToEntry
	call	CallGetText			; get dest. filename
;	jcxz	noDestNameGiven
	tst	cx
	LONG jz	noDestNameGiven

	; check if the destination has visible character
	push	bx, ax
	mov	bx, dx
	call	MemLock
	push	ds
	mov	ds, ax
	clr	dx			; ds:dx = beg. of name buffer
	call	CheckForBlankName
	pushf
	call	MemUnlock
	popf
	mov	dx, bx
	pop	ds
	pop	bx, ax
	jnc	visibleDestFile
	mov	ax, ERROR_BLANK_NAME
	call	DesktopOKError

	jmp	noDestNameGiven
visibleDestFile:

	mov	bx, dx
	pop	dx				; ds:dx <- FOIE
	push	bx				; save dest filename block
	push	dx				; and FOIE again
	call	MemLock				; lock dest. filename buffer
	;
	; Report status using src name
	;
	push	ax
	mov	si, offset FileOperationUI:DuplicateStatus	; status field
	mov	bp, offset DuplicateStatusString ; status text
	call	ShowFileOpStatus		; use common status reporting
	segmov	es, ds				; es <- FQT
	pop	ds
	clr	dx				; ds:dx <- dest name

	call	FileGetAttributes
	pop	si				; es:si <- source FOIE
	jnc	destExists

	cmp	ax, ERROR_FILE_NOT_FOUND	; only acceptable error
	stc					; in case other error
	jne	errorNoUpdate
	;
	; valid destination name that doesn't already exist
	;	es = FQT
	;	ds:dx = destination name
	;
	segxchg	ds, es
	mov	di, dx				; es:di <- dest name

	call	FileBatchChangeNotifications
	call	SuspendFolders

	call	DeskFileCopy

	call	UnsuspendFolders
	call	FileFlushChangeNotifications
	jmp	short afterFileDup		; go to finish duplicate

	;
	; dest filename exists, report error
	;
destExists:
	mov	ax, ERROR_FILE_EXISTS		; cannot dup. to existing name
	stc					; indicate error
errorNoUpdate:
	; es is FQT
	; sp	-> dest name handle
	; 	   FQT handle
	call	DesktopOKError			; report error
	mov	cx, 0				; no files duplicated
	cmp	ax, DESK_DB_DETACH		; detaching?
	jne	finishUp			; no, so show results
	jmp	noUpdate

errorNoUpdateDestFreed:
	call	DesktopOKError

noDestNameGiven:
	pop	dx				; ds:dx <- FOIE
	mov	cx, 0
	jmp	noUpdateNoDest

	;
	; duplication done, handle errors, etc.
	;
afterFileDup:
	mov	cx, 1				; assume one file duplicated
	jnc	update				; if no error, update
	mov	cx, 0				; no files duplicated
	call	DesktopOKError			; report error
	jnc	update				; if ignored error, update
	cmp	ax, DESK_DB_DETACH		; detaching, no update
	je	noUpdate
        ;
	; handle errors
	;       YESNO_NO - user wants to skip copy/move of current item
	;       YESNO_CANCEL - user wants to cancel complete copy/move operation
	;       ERROR_ACCESS_DENIED - file-busy/access-denied error for this
	;                               item
	;	ERROR_SHARING_VIOLATION - ditto
        ;       ERROR_DIR_NOT_EMPTY - can only happen when moving directory
	;                               to another disk, in which case
	;                               enteredFileOpRecursion will send us
	;                               to "update"
	;       other - other file system error
	;
	cmp     ss:[enteredFileOpRecursion], 1  ; did we do recursive file op?
	stc					; C set to not update name list
	je      update                          ; yes, update this file as
						;       we could have made
						;       non-top-level changes
						;       before getting error
	;
	; error on top-level duplicate
	;
	cmp	ax, YESNO_CANCEL		; user-cancel operation, update
	je	finishUp			;	previous files
	cmp	ax, YESNO_NO			; no dup, update name list
	je	updateNames			;	and update prev. files
	cmp	ax, ERROR_ACCESS_DENIED		; top-level no dup, update
	je	updateNames			;	name list & prev. files
	cmp	ax, ERROR_SHARING_VIOLATION	; ditto
	je	updateNames
	stc					; else, other error - update
						;	this file, but don't
						;	update name list
update:
	;
	; update affected folder windows
	;
	pushf
	mov	ax, COPY_UPDATE_STRATEGY
	call	MarkWindowForUpdate		; preserves cx
	popf
	jc	finishUp			; error - don't update names
updateNames:
	;
	; update name entries in duplicate dialog box
	;	(if no more files, box will be dismissed)
	;
	mov	ax, MSG_DUPLICATE_NEXT
	mov	si, offset FileOperationUI:DuplicateToEntry
	call	UpdateSrcAndDestNames		; move to next file when done
finishUp:
	;
	; show duplicate results
	;
	mov	si, offset FileOperationUI:DuplicateStatus	; result field
if 0
	mov	bp, offset duplicateResultString	; result text
	mov	dx, offset duplicateOneResultString	; result text
endif
	call	ShowFileOpResult		; show file count of duplicated
	;
	; finish up
	;
	call	UpdateMarkedWindows		; update affected window(s)
if _NEWDESK
	call	UpdateWastebasket
endif
noUpdate:
	pop	bx				; throw away dest. fname buffer
	call	MemFree

noUpdateNoDest:
	pop	bx				; unlock FQT
	call	MemUnlock
	mov	ss:[recurErrorFlag], 0		; clear error handling flag
done:
	mov	ax, SP_TOP			; just go to top-level path
	call	FileSetStandardPath

	call	ClearFileOpProgressBox
	;
	; re-enable name entry field and reply bar
	;
	mov	bx, handle FileOperationUI
	mov	si, offset FileOperationUI:DuplicateToEntry
	mov	ax, MSG_GEN_SET_ENABLED
	mov	cx, offset FileOperationUI:DuplicateControl
	call	FileOpDisableControls
	;
	; finish up
	;
	call	HideHourglass
	ret
DesktopEndDuplicate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDuplicateNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move to next file in Duplicate dialog box

CALLED BY:	MSG_DUPLICATE_NEXT

PASS:		es	= segment of DesktopClass

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDuplicateNext	method	dynamic DesktopClass, MSG_DUPLICATE_NEXT

	;
	; tell file list to show next file
	;

	mov	cx, offset DuplicateBox
	mov	dx, offset DuplicateFromEntry
	mov	ax, MSG_FILE_OP_SKIP_FILE
	mov	bx, handle 0			; send to ourselves
	call	ObjMessageCall
	jc	exit				; no more files

	;
	; then update destination name field characteristics for this file
	; and fill source name as default destination name
	;

	call	DuplicateStuff
exit:
	ret
DesktopDuplicateNext	endm


ifndef GEOLAUNCHER		; no Change Attr in GeoLauncher


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopEndChangeAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change attributes for file specified in dialog box

CALLED BY:	MSG_FM_END_CHANGE_ATTR

PASS:		es	= segment of DesktopClass

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/16/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopEndChangeAttr	method	dynamic DesktopClass, MSG_FM_END_CHANGE_ATTR

	call	InitForWindowUpdate
	;
	; change to directory specified in change attr box, we don't care what
	; directory we are in when we quit, so no need to save current
	; directory
	;
	mov	si, offset FileOperationUI:ChangeAttrNameList
	call	GetSrcFromFileListAndSetCurDir
	jnc	doIt

	tst	ax
	jz	exit
	call	MemUnlock
	jmp	exit
doIt:
	push	bx

	mov	si, offset FileOperationUI:ChangeAttrStatus	; status field
	mov	bp, offset ChangeAttrStatusString ; status text
	call	ShowFileOpStatus

	;
	; change attributes of file
	;	ss:[fileOperationInfoEntryBuffer] = source
	;
	call	SetNewFileAttributes		; cx = new attributes
	mov	cx, 1				; one file with attrs changed
	jnc	noError				; yes
	mov	cx, 0				; no files with attrs changed
	call	DesktopOKError			; report error
	jnc	updateNames
	cmp	ax, DESK_DB_DETACH		; detaching, no update
	je	done
	cmp	ax, YESNO_CANCEL		; user-cancel operation, update
	je	finishUp			;	previous files
	cmp	ax, YESNO_NO			; no change, just update name
	je	updateNames			;	list
	stc					; error - don't update name

noError:
	pushf
	push	cx				; save deleted file count
	mov	ax, CHANGE_ATTR_UPDATE_STRATEGY
	call	MarkWindowForUpdate		; pass ds:dx = source name
	pop	cx				; retrieve delete count
	popf

	jc	finishUp			; error - don't update name
updateNames:
	;
	; update name entries in change attrs dialog box
	;	(if no more files, box will be dismissed)
	;
	mov	ax, MSG_CHANGE_ATTR_NEXT
	call	UpdateNameListManually		; move to next file when done
	;
	; show change attrs results
	;
finishUp:
	mov	si, offset FileOperationUI:ChangeAttrStatus	; result field
if 0
	mov	bp, offset changeAttrResultString	; result text
	mov	dx, offset changeAttrOneResultString	; result text
endif
	call	ShowFileOpResult		; show file count of renamed
	;
	; finish up
	;
	call	UpdateMarkedWindows		; update affected window(s)
done:
	pop	bx				; bx <- FQT
	call	MemUnlock

	mov	ax, SP_TOP			; just go to top-level path
	call	FileSetStandardPath

exit:
	ret
DesktopEndChangeAttr	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNewFileAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set new flags and attributes for file

CALLED BY:	INTERNAL
			DesktopEndChangeAttr

PASS:		ds:dx	- filename

RETURN:		carry	- set on error
				ax = error code
			- clear otherwise

DESTROYED:	bx, si, ax, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/16/89		broken out from old Change Attr handling
	dlitwin	9/21/93		Changed the name to Set... from Get... and
				added flags and attrs setting.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNewFileAttributes	proc	near
	uses	dx, cx
changeAttrs		local	2 dup (FileExtAttrDesc)
fileAttrs		local	FileAttrs
flagsAttrs		local	GeosFileHeaderFlags
	.enter

	;
	; Get the original FileAttrs so we can preserve the FileAttrs
	; that we don't want to change.
	;
	call	FileGetAttributes		; cx = FileAttrs
	LONG jc	exit

	andnf	cl, not (mask FA_RDONLY or mask FA_ARCHIVE or \
			 mask FA_HIDDEN or mask FA_SYSTEM)
	mov	ss:[fileAttrs], cl

	;
	; Get the File Attributes
	;
	mov	bx, handle GetInfoAttrToList
	mov	si, offset GetInfoAttrToList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	push	dx, bp
	call	ObjMessageCall			; ax = FileAttrs
	pop	dx, bp

	;
	; Fill the File Attributes FEAD
	;
	ornf	ss:[fileAttrs], al		; FileAttrs
	lea	ax, ss:[fileAttrs]		; ss:ax is FileAttrs
	mov	ss:[changeAttrs].FEAD_attr, FEA_FILE_ATTR
	segmov	ss:[changeAttrs].FEAD_value.segment, ss
	mov	ss:[changeAttrs].FEAD_value.offset, ax
	mov	ss:[changeAttrs].FEAD_size, size FileAttrs

	;
	; check to see if this is a Geos file or not.  If not, don't attempt
	; to set the GeosFileHeaderFlags.
	;
	mov	ax, FEA_FILE_TYPE
	push	ax				; allocate word on stack
	segmov	es, ss
	mov	di, sp				; es:di point to stack buffer
	mov	cx, size GeosFileType
	call	FileGetPathExtAttributes
	pop	cx
	jnc	geosFile			; if it has an FEA_FILE_TYPE
						;   it is a geos file
	cmp	ax, ERROR_ATTR_NOT_FOUND
	jne	exit				; some weird error happened...

	mov	cx, 1				; default to one attribute
	jmp	notGeosFile

geosFile:
	;
	; Get the Flags
	;
	mov	bx, handle GetInfoAttrToList
	mov	si, offset GetInfoAttrToList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	push	dx, bp
	call	ObjMessageCall			; ax - GeosFileHeaderFlags
	pop	dx, bp
	andnf	ax, 0xff00			; high bits only

	;
	; Fill the Flags FEAD
	;
	mov	ss:[flagsAttrs], ax		; Flags
	lea	ax, ss:[flagsAttrs]		; ss:ax is Flags

	lea	di, ss:[changeAttrs]
	add	di, size FileExtAttrDesc	; use second FEAD
	mov	ss:[di].FEAD_attr, FEA_FLAGS
	segmov	ss:[di].FEAD_value.segment, ss
	mov	ss:[di].FEAD_value.offset, ax
	mov	ss:[di].FEAD_size, size GeosFileHeaderFlags
	mov	cx, 2				; two attributes to set

notGeosFile:
	segmov	es, ss
	lea	di, ss:[changeAttrs]
	mov	ax, FEA_MULTIPLE
	call	FileSetPathExtAttributes
	;
	; The above will set the ARCHIVE bit if it is a GEOS file (i.e.
	; when the GEOS file header is written).  If the user wants to
	; turn off the archive bit, make another call.  This correctly
	; deals with READ_ONLY  - brianc 10/11/94
	;	es:di = changeAttrs (FileAttrs)
	;	cx = 1 if not GEOS file
	;
	jc	exit				; whoops, error from above
	cmp	cx, 1
	je	exit				; not GEOS file, carry clear
	test	ss:[fileAttrs], mask FA_ARCHIVE
	jnz	exit				; leave set, carry clear
	mov	cx, 1				; set only FileAttrs
	mov	ax, FEA_MULTIPLE
	call	FileSetPathExtAttributes
exit:
	.leave
	ret
SetNewFileAttributes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetOldFileAttributes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the UI for the existing set of attributes for the
		file

CALLED BY:	ChangeAttrShowAttrs

PASS:		cx - old FileAttrs

RETURN:		nothing

DESTROYED:	ax,cx,di,si,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 9/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetOldFileAttributes	proc	near
	uses	bx, dx
	.enter
						; make sure we only use the
						;	attributes we have
	andnf	cx, mask FA_RDONLY or mask FA_ARCHIVE or \
				mask FA_HIDDEN or mask FA_SYSTEM
	mov	bx, handle ChangeAttrToList
	mov	si, offset ChangeAttrToList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	dx, 0				; no indeterminates
	call	ObjMessageCall
	.leave
	ret
SetOldFileAttributes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetOldFileHeaderFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the original file header flags

CALLED BY:	ChangeAttrShowAttrs

PASS:		ds:dx - filename

RETURN:		nothing

DESTROYED:	ax,dx,si,di,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 9/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetOldFileHeaderFlags	proc near
		uses	bx,cx

		.enter

	;
	; See what type of file this is
	;
		push	ax		; garbage push
		mov	di, sp
		segmov	es, ss
		mov	ax, FEA_FILE_TYPE
		mov	cx, size GeosFileType
		call	FileGetPathExtAttributes
		pop	ax		; GeosFileType


	;
	; If it's a document, then set the Template group enabled
	;

		push	dx
		mov	bx, handle ChangeFlagsToList
		mov	si, offset ChangeFlagsToList

CheckHack <	MSG_GEN_SET_NOT_ENABLED eq MSG_GEN_SET_ENABLED+1>

		cmp	ax, GFT_VM
		mov	ax, MSG_GEN_SET_ENABLED
		je	gotMessage
		inc	ax
gotMessage:
		mov	dl, VUM_NOW
		call	ObjMessageNone
		pop	dx

	;
	; Now, display the old setting.
	;

		call	ShellGetFileHeaderFlags	; ax - flags
		mov_tr	cx, ax
		clr	dx			; no indeterminates
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		call	ObjMessageNone

		.leave
		ret

SetOldFileHeaderFlags	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopChangeAttrNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move to next file in Change Attributes dialog box

CALLED BY:	MSG_CHANGE_ATTR_NEXT

PASS:

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopChangeAttrNext	method	DesktopClass, MSG_CHANGE_ATTR_NEXT

	; tell file list to show next file

	mov	cx, offset ChangeAttrBox
	mov	dx, offset ChangeAttrNameList
	mov	ax, MSG_FILE_OP_SKIP_FILE
	mov	bx, handle 0			; send to ourselves
	call	ObjMessageCall
	jc	exit				; no more files
	;
	; then show attributes for this file
	;
	call	ChangeAttrShowAttrs

exit:
	ret
DesktopChangeAttrNext	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableChangeAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disables the Change button in "Change Attributes"
		and shows the hourglass.

CALLED BY:	ChangeAttrShowAttrs
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableChangeAttrs	proc	near
	uses	ax,bx,cx,dx,si,bp
	.enter

	call	ForceShowHourglass
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	bx, handle ChangeAttrCtrlChange
	mov	si, offset ChangeAttrCtrlChange
	mov	dl, VUM_NOW
	call	ObjMessageCall

	.leave
	ret
DisableChangeAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnableChangeAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enables the Change button in "Change Attributes"
		and hides the hourglass.

CALLED BY:	ChangeAttrShowAttrs
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PC	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EnableChangeAttrs	proc	near
	uses	ax,bx,cx,dx,si,bp
	.enter

	call	ForceHideHourglass
	mov	ax, MSG_GEN_SET_ENABLED
	mov	bx, handle ChangeAttrCtrlChange
	mov	si, offset ChangeAttrCtrlChange
	mov	dl, VUM_NOW
	call	ObjMessageCall

	.leave
	ret
EnableChangeAttrs	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeAttrShowAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Show the attributes for this file

CALLED BY:	DesktopChangeAttrNext, FolderStartChangeAttr,
		TreeStartChangeAttr

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp,ds,es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 9/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeAttrShowAttrs	proc	far

	; Show hourglass and disable the Change Button.

	call	DisableChangeAttrs

	; update state of "Next" button
	;
	mov	ax, offset ChangeAttrCtrlNext
	mov	si, offset ChangeAttrNameList
	call	DisableIfLastFile

	;
	; change to directory specified in change attr box, we don't care what
	; directory we are in when we quit, so no need to save current
	; directory
	;

	mov	si, offset FileOperationUI:ChangeAttrNameList
	call	GetSrcFromFileListAndSetCurDir
	jnc	doIt

	tst	ax
	jz	exit
	jmp	done
doIt:
	;
	; get attributes of file
	;
	CheckHack	<offset FOIE_name eq 0>
	call	FileGetAttributes		; get attrs with name
						; cx = file attributes
	jnc	noError
	call	DesktopOKError			; report error
	clr	cx				; no attributes
noError:

	;
	; Fetch the file header flags
	;
	call	SetOldFileHeaderFlags
	;
	; set buttons to show current attributes
	;

	call	SetOldFileAttributes

done:
	call	MemUnlock
exit:
	mov	ax, SP_TOP			; just go to top-level path
	call	FileSetStandardPath

	; Remove hourglass and enable the Change button again.

	call	EnableChangeAttrs

	ret
ChangeAttrShowAttrs	endp


COMMENT @-------------------------------------------------------------------
		DesktopEndChangeToken
----------------------------------------------------------------------------

DESCRIPTION:

CALLED BY:	GLOBAL
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/28/92   	Initial version

----------------------------------------------------------------------------@
DesktopEndChangeToken	method dynamic DesktopClass,
					MSG_FM_END_CHANGE_TOKEN
		.enter

		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	bx, handle ChangeIconCtrlChange
		mov	si, offset ChangeIconCtrlChange
		mov	dl, VUM_NOW
		call	ObjMessageCall

		call	ShowHourglass
		call	InitForWindowUpdate
	;
	; change to directory specified in change Icon box, we don't care what
	; directory we are in when we quit, so no need to save current
	; directory
	;
		mov	si, offset FileOperationUI:ChangeIconNameList

		call	GetSrcFromFileListAndSetCurDir
		jnc	doIt

		tst	ax
		jz	exit
		call	MemUnlock
		jmp	exit
doIt:
		push	bx
	;
	; get new Icon for file from the Change Icon dialog
	;
		push	dx
		mov	bx, handle ChangeIconList
		mov	si, offset ChangeIconList
		mov	ax, MSG_ICON_LIST_GET_SELECTED
		call	ObjMessageCall
		mov	di, dx				; ax:cx:di = GeodeToken
		pop	dx				; ds:dx = filename
	;
	; change token of file
	;	ss:[fileOperationInfoEntryBuffer] = source
	;
		mov	si, offset FileOperationUI:ChangeIconStatus
		mov	bp, offset ChangeIconStatusString
		call	ShowFileOpStatus
		call	ShellSetToken
		mov	cx, 1				; one token changed
		jnc	noError				; yes
		clr	cx				; no tokens changed
		call	DesktopOKError			; report error
		jnc	noError
		cmp	ax, DESK_DB_DETACH		; detaching, no update
		je	done
		cmp	ax, YESNO_CANCEL		; user-cancel update
		je	finishUp			;	previous files
		cmp	ax, YESNO_NO			; no change, update name
		je	updateNames			;	list
		stc					; error -
							; don't update name

;change Icon error can still cause file system changes, so update - 4/19/90

noError:
	;
	; update folder windows (handled by file-change notification now)
	;
;		pushf
;		push	cx				; cx=deleted file count
;		mov	ax, mask FWUF_RESCAN_SOURCE or 		\
;			    mask FWUF_DS_IS_FQT_BLOCK
;		call	MarkWindowForUpdate		; ds:dx = source name
;		pop	cx
;		popf
		jc	finishUp			; error -
							; don't update name
updateNames:
	;
	; update name entries in change Icons dialog box
	;	(if no more files, box will be dismissed)
	;
		mov	ax, MSG_CHANGE_TOKEN_NEXT
		call	UpdateNameListManually		; next file when done
	;
	; show change Icons results
	;
finishUp:
		mov	si, offset FileOperationUI:ChangeIconStatus
		call	ShowFileOpResult		; show file count
	;
	; finish up
	;
		call	UpdateMarkedWindows		; update
							; affected window(s)
done:
		pop	bx				; bx <- FQT
		call	MemUnlock

		mov	ax, SP_TOP			; just go to
							; top-level path
		call	FileSetStandardPath
exit:
		call	HideHourglass

		mov	ax, MSG_GEN_SET_ENABLED
		mov	bx, handle ChangeIconCtrlChange
		mov	si, offset ChangeIconCtrlChange
		mov	dl, VUM_NOW
		call	ObjMessageForce

		.leave
		ret

DesktopEndChangeToken	endm


COMMENT @-------------------------------------------------------------------
		DesktopChangeTokenNext
----------------------------------------------------------------------------

DESCRIPTION:

CALLED BY:	GLOBAL

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/27/92   	Initial version

----------------------------------------------------------------------------@
DesktopChangeTokenNext	method dynamic DesktopClass,
					MSG_CHANGE_TOKEN_NEXT
		.enter
	;
	; tell file list to show next file
	;
		mov	cx, offset ChangeIconBox
		mov	dx, offset ChangeIconNameList
		mov	ax, MSG_FILE_OP_SKIP_FILE
		mov	bx, handle 0			; send to ourselves
		call	ObjMessageCall
		jc	exit				; no more files
	;
	; then show attributes for this file
	;
		call	ChangeIconShowIcon
exit:
		.leave
		ret
DesktopChangeTokenNext	endm



COMMENT @-------------------------------------------------------------------
			ChangeIconShowIcon
----------------------------------------------------------------------------

DESCRIPTION:	Disable 'Next' button if no more files, set the
		current Icon, and (in NewDeskBA) have the IconList only
		show the appropriate icons based on the
		NewDeskObjectType.

CALLED BY:	INTERNAL - FolderStartChangeToken

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/27/92	Initial version

---------------------------------------------------------------------------@
ChangeIconShowIcon	proc	near
		uses	bx, dx, bp, si
		.enter
	;
	; update state of "Next" button
	;
		mov	ax, offset ChangeIconCtrlNext
		mov	si, offset ChangeIconNameList
		call	DisableIfLastFile
	;
	; change to directory specified in change attr box, we don't care what
	; directory we are in when we quit, so no need to save current
	; directory
	;
		mov	si, offset FileOperationUI:ChangeIconNameList
		call	GetSrcFromFileListAndSetCurDir	; bx = mem handle
		jnc	doIt

		tst	ax
		jz	exit
		jmp	done
doIt:

BA <		call	SetIconListForFile				>
		call	SetCurrentIconForFile
done:
		call	MemUnlock
exit:
		mov	ax, SP_TOP		; just go to top-level path
		call	FileSetStandardPath
		.leave
		ret
ChangeIconShowIcon	endp



COMMENT @-------------------------------------------------------------------
			SetCurrentIconForFile
----------------------------------------------------------------------------

DESCRIPTION:	Sets the ChangeIconCurrentIcon object to display the
		icon of the given file.

CALLED BY:	INTERNAL - ChangeIconShowIcon

PASS:		ds:dx	= filename
RETURN:		ax, cx, dx, si, bp
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92	Initial version

---------------------------------------------------------------------------@
SetCurrentIconForFile	proc	near
		uses	bx
		.enter
	;
	; get token of file
	;
		CheckHack	<offset FOIE_name eq 0>
		call	ShellGetToken			; get token
		mov	dx, di
		mov	bp, ax				; bp:cx:dx = token

		jnc	noError
		call	DesktopOKError			; report error
		clr	bp, cx, dx			; no token
noError:
	;
	; set buttons to show current icon
	;
		mov	bx, handle ChangeIconCurrentIcon
		mov	si, offset ChangeIconCurrentIcon
		mov	ax, MSG_ICON_DISPLAY_SET_ICON
		call	ObjMessageCall
		.leave
		ret
SetCurrentIconForFile	endp

if _NEWDESKBA


COMMENT @-------------------------------------------------------------------
			SetIconListForFile
----------------------------------------------------------------------------

DESCRIPTION:	Sets the ChangeIconList object in the change icon
		dialog to use the proper list depending on the
		NewDeskObjectType of the given file.

CALLED BY:	INTERNAL - ChangeIconShowIcon

PASS:		ds:dx	= filename
RETURN:		nothing
DESTROYED:	ax, cx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	martin	10/30/92	Initial version

---------------------------------------------------------------------------@
SetIconListForFile	proc	near
		uses	bx, dx
		.enter
		call	ShellGetObjectType
		jnc	noError
		call	DesktopOKError			; report error
		jmp	gotTable
noError:
	;
	; Get proper list depending on type, quick solution for now...
	; change to lookup table later.
	;
		clr	cx, dx				; assume all tokens
		cmp	ax, WOT_TEACHER_COURSE
		jne	next1
		mov	dx, handle ClassIconLookupTable
		mov	cx, offset ClassIconLookupTable
		jmp	gotTable
next1:
		cmp	ax, WOT_GEOS_COURSEWARE
		jne	next2
		mov	dx, handle CoursewareIconLookupTable
		mov	cx, offset CoursewareIconLookupTable
		jmp	gotTable
next2:
		cmp	ax, WOT_DOS_COURSEWARE
		jne	gotTable
		mov	dx, handle CoursewareIconLookupTable
		mov	cx, offset CoursewareIconLookupTable
gotTable:
	;
	; set IconList to show proper list
	;
		mov	bx, handle ChangeIconList
		mov	si, offset ChangeIconList
		mov	ax, MSG_ICON_LIST_SET_TOKEN_LIST
		call	ObjMessageCall
		.leave
		ret
SetIconListForFile	endp

endif	; if _NEWDESKBA

endif	; ifndef GEOLAUNCHER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopGetInfoNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move to next file in get info list

CALLED BY:	MSG_GET_INFO_NEXT, MSG_GET_INFO_OK

PASS:

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopGetInfoNext	method	DesktopClass, MSG_GET_INFO_NEXT, \
						MSG_GET_INFO_OK
	;
	; first, save current notes, if MSG_GET_INFO_OK
	;
	cmp	ax, MSG_GET_INFO_OK
	jne	noSave
	call	GetInfoSaveNotes
noSave:
	;
	; tell file list to show next file
	;
	mov	cx, offset GetInfoBox
	mov	dx, offset GetInfoFileList
	mov	ax, MSG_FILE_OP_SKIP_FILE
	mov	bx, handle 0			; send to ourselves
	call	ObjMessageCall
	jc	exit				; no more files
	;
	; then show info for this file
	;
	call	ShowCurrentGetInfoFile
exit:
	ret
DesktopGetInfoNext	endm

DesktopHackGetInfoOK	method	DesktopClass, MSG_HACK_GET_INFO_OK
	mov	bx, handle GetInfoCtrlOK
	mov	si, offset GetInfoCtrlOK
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCall
	ret
DesktopHackGetInfoOK	endm

DesktopGetInfoEnableOK	method	DesktopClass, MSG_GET_INFO_ENABLE_OK
	mov	bx, handle GetInfoCtrlOK
	mov	si, offset GetInfoCtrlOK
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCall
	ret
DesktopGetInfoEnableOK	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowCurrentGetInfoFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	show current file in get info box

CALLED BY:	INTERNAL
			DesktopGetInfoNext
			FolderGetInfo

PASS:		nothing

RETURN:		carry clear if a file was shown
		carry set if no more files

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/22/90	Extracted from original FolderGetInfo

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
getInfoReturnAttrs	FileExtAttrDesc	\
	<FEA_MODIFICATION,	GIS_modified,		size GIS_modified>,
	<FEA_FILE_ATTR,		GIS_fileAttrs,		size GIS_fileAttrs>,
	<FEA_CREATION,		GIS_created,		size GIS_created>,
	<FEA_FILE_TYPE,		GIS_fileType,		size GIS_fileType>,
	<FEA_SIZE,		GIS_size,		size GIS_size>,
	<FEA_USER_NOTES,	GIS_userNotes,		size GIS_userNotes>,
	<FEA_RELEASE,		GIS_release,		size GIS_release>,
	<FEA_CREATOR,		GIS_creator,		size GIS_creator>,
	<FEA_FLAGS,		GIS_flags,		size GIS_flags>,
	<FEA_DOS_NAME,		GIS_dosName,		size GIS_dosName>,
	<FEA_OWNER,		GIS_owner,		size GIS_owner>

GetInfoStruct	struct
    GIS_modified	FileDateAndTime
    GIS_fileAttrs	FileAttrs
    GIS_created		FileDateAndTime
    GIS_fileType	GeosFileType
    GIS_size		sdword
    GIS_userNotes	FileUserNotes
    GIS_release		ReleaseNumber
    GIS_creator		GeodeToken
    GIS_flags		GeosFileHeaderFlags
if _DOS_LONG_NAME_SUPPORT
    ; GEOS supports DOS long names of length up to FILE_LONGNAME_LENGTH
    ; *DOS chars*, both in SBCS and DBCS.
    GIS_dosName		char	FILE_LONGNAME_LENGTH + 1 dup(?)
else
    GIS_dosName		char	DOS_DOT_FILE_NAME_LENGTH_ZT dup(?)
endif
    GIS_owner		FileOwnerName
    GIS_attrs		FileExtAttrDesc length getInfoReturnAttrs dup(<>)
if DBCS_PCGEOS
if _DOS_LONG_NAME_SUPPORT
    GIS_dosName2	wchar	FILE_LONGNAME_LENGTH + 1 dup(?)
else
    GIS_dosName2	wchar	DOS_DOT_FILE_NAME_LENGTH_ZT dup(?)
endif
endif
GetInfoStruct	ends

ShowCurrentGetInfoFile	proc	far
	call	ShowHourglass
	;
	; update state of "Next" button
	;
	mov	ax, offset GetInfoCtrlNext
	mov	si, offset GetInfoFileList
	call	DisableIfLastFile
	;
	; change to directory specified in rename box, we don't care what
	; directory we are in when we quit, so no need to save current
	; directory
	;
	mov	si, offset FileOperationUI:GetInfoFileList
	call	GetSrcFromFileListAndSetCurDir
	push	bx
	jc	errorReport
	jmp	doIt

errorFreeAttrsReport:
	pop	bx
	call	MemFree
errorReport:
	call	DesktopOKError			; report error
	pop	bx				; bx <- FQT block
	tst	ax
LONG	jz	done
	call	MemUnlock
	jmp	done				; if no more files, done

doIt:
	;
	; ds:dx	= FileOperationInfoEntry
	; handle of block containing same pushed on the stack
	;
	; get DOS file info:
	; 	- allocate a block to hold the extended attributes and the
	;	  descriptors by which we get them
	;	- copy the descriptors into the block wholesale
	;	- fix up the FEAD_value.segment fields of the duplicated
	;	  descriptors to point to the block
	;	- call FileGetPathExtAttributes
	;
	mov	ax, size GetInfoStruct
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	LONG jnc	noError
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; else, report mem error
	jmp	errorReport

noError:
	push	bx
	mov	es, ax
	push	ds
	segmov	ds, cs
	mov	si, offset getInfoReturnAttrs
	mov	di, offset GIS_attrs
	mov	cx, size getInfoReturnAttrs
	rep	movsb
	mov	di, offset GIS_attrs
	mov	cx, length GIS_attrs
	mov	si, di
setAttrSegmentsLoop:
	mov	es:[di].FEAD_value.segment, es
	add	di, size FileExtAttrDesc
	loop	setAttrSegmentsLoop
	pop	ds

	mov	di, si
	mov	cx, length GIS_attrs
	mov	ax, FEA_MULTIPLE
		CheckHack <offset FOIE_name eq 0>
	call	FileGetPathExtAttributes
	jnc	haveAttrs
	cmp	ax, ERROR_ATTR_NOT_FOUND	; not geos file?
	je	haveAttrs
	cmp	ax, ERROR_ATTR_NOT_SUPPORTED
	stc
	jne	errorFreeAttrsReport		; no -- report other error
haveAttrs:

	;
	; set up name field
	;
NOFXIP<	mov	dx, segment fileOperationInfoEntryBuffer	; dx:bp= name >
FXIP<	push	ds							>
FXIP<	GetResourceSegmentNS dgroup, ds					>
FXIP<	mov	dx, ds							>
FXIP<	pop	ds							>
	mov	bp, offset fileOperationInfoEntryBuffer.FOIE_name
	mov	ax, offset GetInfoName
	call	SetGetInfoText
	segmov	ds, es
	;
	; Set up DOSName field.
	;
	mov	si, offset GIS_dosName
SBCS <	mov	cx, size GIS_dosName-1					>
DBCS <	mov	cx, size GIS_dosName					>
	mov	ax, '?'
if DBCS_PCGEOS
	;
	; XXX: should use disk handle for file
	;
	clr	dx				;dx <- disk handle (0 = primary)
	clr	bx				;bx <- DosCodePage (0 = current)
	mov	di, offset GIS_dosName2		;es:di <- ptr to dest buffer
endif
	call	LocalDosToGeos
	mov	dx, ds
SBCS <	mov	bp, offset GIS_dosName					>
DBCS <	mov	bp, offset GIS_dosName2					>
	mov	ax, offset GetInfoDOSName
	call	SetGetInfoText

	;
	; set up attributes field
	;
	; (stores GFHF_ flags and FA_ flags in UI
	; for easy retrieval when changing file attributes)
	mov	cx, ds:[GIS_flags]	; GFHF_ flags uses high 8 bits
	mov	cl, ds:[GIS_fileAttrs]	;  so we can use low 8 bits for FA_
	clr	dx			; no indeterminates
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	bx, handle GetInfoAttrToList
	mov	si, offset GetInfoAttrToList
	call	ObjMessageCall
	;
	; disable if not GEOS VM file
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	ds:[GIS_fileType], GFT_VM
	jne	notVM
	mov	ax, MSG_GEN_SET_ENABLED
notVM:
	mov	dl, VUM_NOW
	mov	bx, handle GetInfoAttrTemplate
	mov	si, offset GetInfoAttrTemplate
	call	ObjMessageCall
	;
	; Put up owner, if known, else "-"
	;
	call	PointAndInitGetInfoBuffer	; dx:bp <- infoBuffer thingy
	tst	ds:[GIS_owner][0]		; owner known?
	jz	setInfoOwner			; no
	mov	dx, ds
	mov	bp, offset GIS_owner
setInfoOwner:
	mov	ax, offset GetInfoOwner
	call	SetGetInfoText

	;
	; set up last modification field
	;
	call	PointAndInitGetInfoBuffer	; es:di=dx:bp=time
						; string buffer

	mov	ax, ds:[GIS_modified].FDAT_time
	mov	bx, ds:[GIS_modified].FDAT_date
	tst	bx
	jz	setModified
	call	UtilFormatDateAndTime

setModified:
	mov	ax, offset GetInfoDate
	call	SetGetInfoText

	;
	; set up creation field
	;
	call	PointAndInitGetInfoBuffer	; es:di=dx:bp=time
						; string buffer

	mov	ax, ds:[GIS_created].FDAT_time
	mov	bx, ds:[GIS_created].FDAT_date
	tst	bx
	jz	setCreationDate
	call	UtilFormatDateAndTime

setCreationDate:
	mov	ax, offset GetInfoCreated
	call	SetGetInfoText

	;
	; See if this file's a link, and if so, get its target
	;

	call	GetInfoCheckLink

	;
	; Account for GeosFileHeader - brianc 7/12/93
	;
	test	ds:[GIS_fileAttrs], mask FA_SUBDIR or mask FA_LINK
	jnz	haveFileSize			; leave subdir alone
	cmp	ds:[GIS_fileType], GFT_NOT_GEOS_FILE
	je	haveFileSize			; leave non-GEOS alone
	adddw	ds:[GIS_size], 256
haveFileSize:

						; subdirectory?
	test	ds:[GIS_fileAttrs], mask FA_SUBDIR
	jz	printSize			; no -- use size as returned

	;
	; this is a directory -- let's get the total size of all files within
	; it
	;
	call	PointToGetInfoBuffer		; es:di = dx:bp = size buffer
						; ds:dx - 8.3 dir name
	push	ds
NOFXIP<	segmov	ds, <segment fileOperationInfoEntryBuffer>, dx		>
FXIP<	mov	dx, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, dx							>
	mov	dx, offset fileOperationInfoEntryBuffer.FOIE_name
	call	FileDirGetSize			; dx:ax = size
	pop	ds				; ds = buffer segment

	jc	printSize			; pass on error code
	mov	ds:[GIS_size].low, ax
	mov	ds:[GIS_size].high, dx

printSize:
	pushf					; save error status for later
	push	ax				; save err code (in case error)

	;
	; set up file size field
	;
	call	PointAndInitGetInfoBuffer	; es:di = dx:bp = size buffer
	mov	dx, ds:[GIS_size].low
	mov	ax, ds:[GIS_size].high
	call	ASCIIizeDWordAXDX
	mov	dx, es				; dx:bp = filesize string
	mov	ax, offset GetInfoSize
	call	SetGetInfoText

if 0
	; I'm tired of seeing this damn compilation message!

PrintMessage <need a FileInUse? function to do this now>
	;
	; show file busy state
	;	ds = file header buffer segment
	;	(file header is all ZEROs for non-GEOS file or
	;		error-reading-GEOS file)
	;
	mov	cx, offset NotBusyMoniker	; assume file not busy
;;;	mov	ax, mask VTS_EDITABLE		; set editable bit
	tst	si				; file busy?
	jz	gotBusyState			; no, show it
	mov	cx, offset BusyMoniker		; indicate file busy
;;;	mov	ax, mask VTS_EDITABLE shl 8	; clear editable bit
gotBusyState:
;;;	push	ax				; save editable flag for later
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	dl, VUM_NOW
	mov	bx, handle FileOperationUI
	mov	si, offset GetInfoBusy
	call	ObjMessageCall
endif
	;
	; set up geos file type
	;
	call	PointAndInitGetInfoBuffer

	;
	; show "DOS File" if not a GEOS file - brianc 2/2/93
	;
	mov	cx, ds:[GIS_fileType]	; cx = geos file type
	test	ds:[GIS_fileAttrs], mask FA_SUBDIR
	push	ds
	mov	bx, handle DeskStringsRare
	pushf					; save FA_SUBDIR result
	call	MemLock
	popf
	mov	ds, ax				; ds = string segment
	mov	si, offset GetInfoGeosFileTypeDirectoryString
	jnz	gotString			; FA_SUBDIR is set
	cmp	cx, GFT_DIRECTORY
	je	gotString
	mov	si, offset GetInfoGeosFileTypeNonGeos
	cmp	cx, GFT_NOT_GEOS_FILE
	je	gotString
	mov	si, offset GetInfoGeosFileTypeExecString
	cmp	cx, GFT_EXECUTABLE
	je	gotString
	mov	si, offset GetInfoGeosFileTypeVMString
	cmp	cx, GFT_VM
	je	gotString
	mov	si, offset GetInfoGeosFileTypeDataString
	cmp	cx, GFT_DATA
	je	gotString
	mov	si, offset GetInfoGeosFileTypeOldVMString
EC <	cmp	cx, GFT_OLD_VM						>
EC <	ERROR_NZ	GET_INFO_UNKNOWN_FILE_TYPE			>

gotString:
	mov	si, ds:[si]			; deref. string
	call	CopyNullTermString
	call	MemUnlock			; unlock string block
	pop	ds
	mov	ax, offset GetInfoGeosType
	call	SetGetInfoText
if 0
	;
	; set up token field
	;
	mov	si, offset GFH_core.GFHC_token	; ds:si = token field
	call	GetInfoTokenCommon		; build token string
	mov	ax, offset GetInfoToken
	call	SetGetInfoText
endif
	;
	; set up release field
	;
	mov	si, offset GIS_release	; ds:si = release field
	call	GetInfoRelProtCommon		; build release string
	mov	ax, offset GetInfoRelease
	call	SetGetInfoText

	;
	; set up creator field
	;
	mov	si, offset GIS_creator	; ds:si = creator field
	call	GetInfoTokenCommon		; build creator string
	mov	ax, offset GetInfoCreator
	call	SetGetInfoText
	;
	; set up user notes field
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume a link
	mov	bx, (mask VTS_EDITABLE or mask VTS_SELECTABLE) shl 8	; clr
	test	ds:[GIS_fileAttrs], mask FA_LINK
	jnz	haveEnableMessage		; yep, it's a link
	test	ds:[GIS_fileAttrs], mask FA_SUBDIR
	jnz	setUserNotesEnabled

	mov	ax, MSG_GEN_SET_NOT_ENABLED	; assume not GEOS file
	mov	bx, (mask VTS_EDITABLE or mask VTS_SELECTABLE) shl 8	; clr
	cmp	ds:[GIS_fileType], GFT_NOT_GEOS_FILE
	je	haveEnableMessage
	cmp	ds:[GIS_fileType], GFT_OLD_VM
	je	haveEnableMessage

setUserNotesEnabled:
	mov	ax, MSG_GEN_SET_ENABLED
	mov	bx, mask VTS_EDITABLE or mask VTS_SELECTABLE	; set

haveEnableMessage:
	push	bx				; save VTS
	mov	bx, handle GetInfoUserNotesGroup
	mov	si, offset GetInfoUserNotesGroup
	mov	dl, VUM_NOW
	call	ObjMessageCall			; (in)activate user notes field
	pop	cx				; new VTS
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	bx, handle GetInfoUserNotes
	mov	si, offset GetInfoUserNotes
	call	ObjMessageCall

	mov	dx, ds
	mov	bp, offset GIS_userNotes
	mov	ax, offset GetInfoUserNotes
	call	SetGetInfoText			; show user notes
;;;	;
;;;	; make notes editable or not depending on whether file is in use
;;;	;
;;;	mov	bx, handle GetInfoUserNotes
;;;	mov	si, offset GetInfoUserNotes
;;;	pop	cx				; bits to set/clear
;;;	clr	dx
;;;	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_STATE
;;;	call	ObjMessageCall
	;
	; clean notes, OK disabled
	;
;	mov	bx, handle GetInfoCtrlOK
;	mov	si, offset GetInfoCtrlOK
;	mov	ax, MSG_GEN_SET_NOT_ENABLED
;	mov	dl, VUM_NOW
;	call	ObjMessageCall

	mov	bx, handle 0
	mov	ax, MSG_HACK_GET_INFO_OK
	call	ObjMessageForce
	;
	; put up Get Info dialog box
	;
	mov	bx, handle GetInfoBox
	mov	si, offset GetInfoBox
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageNone
	;
	; clean up
	;
	pop	ax				; get err code (in case error)
	popf					; retrieve error flag
	jnc	noErr				; no error, continue
	call	DesktopOKError			; report earlier error
						; (put on top of GetInfoBox)
noErr:
	pop	bx				; free attribute buffer
	call	MemFree

	pop	bx				; bx <- FQT block
	call	MemUnlock

	clc					; had a file to show
done:
	mov	ss:[recurErrorFlag], 0		; clear flag possibly set
						;	by FileDirGetSize
	call	HideHourglass			; (preserves flags)
	ret
ShowCurrentGetInfoFile	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetInfoCheckLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the file's a link, and if so, get and display
		its target. Otherwise, set the link text not usable.

CALLED BY:	ShowCurrentGetInfoFile

PASS:		ds:0 - GetInfoStruct

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	allocates 400 bytes on the stack!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetInfoCheckLink	proc near
	uses	di,si,ds,es

buffer	local	PathName
fullPath local	PathName

	.enter
	test	ds:[GIS_fileAttrs], mask FA_LINK
	jz	notUsable

	mov	ax, MSG_GEN_SET_USABLE
	call	callIt

NOFXIP<	segmov	ds, dgroup, dx						>
FXIP<	mov	dx, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, dx							>
	mov	dx, offset fileOperationInfoEntryBuffer.FOIE_name
	segmov	es, ss
	lea	di, ss:[buffer]
	mov	cx, size buffer
	call	FileReadLink
	jc	notUsable		; set the object not usable

	;
	; Construct the full path, including disk name.
	;

	mov	dl, TRUE
	mov	si, di
	segmov	ds, ss
	lea	di, ss:[fullPath]
	mov	cx, size fullPath
	call	FileConstructFullPath
	jc	notUsable

	;
	; Set the text, using the full path
	;

	push	bp
	lea	bp, ss:[fullPath]
	mov	dx, ss
	mov	ax, offset GetInfoLink
	call	SetGetInfoText
	pop	bp

done:
	.leave
	ret
notUsable:
	mov	ax, MSG_GEN_SET_NOT_USABLE
	call	callIt
	jmp	done


	;
	; Set the link object usable or not, depending...
	;

callIt:
	mov	bx, handle GetInfoLink
	mov	si, offset GetInfoLink
	mov	dl, VUM_NOW
	call	ObjMessageNone
	retn
GetInfoCheckLink	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointAndInitGetInfoBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	point to the getInfo buffer, and initialize it to
		contain a single dash, in the event that the
		attributes we want aren't available

CALLED BY:	ShowCurrentGetInfoFile

PASS:		nothing

RETURN:		es:di, dx:bp - pointing to getInfoStringBuffer (in
		dgroup)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 3/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointAndInitGetInfoBuffer	proc near
	.enter
	call	PointToGetInfoBuffer
	mov	{word} es:[di], '-'
DBCS <	mov	{wchar}es:[di][1*2], 0					>
	.leave
	ret
PointAndInitGetInfoBuffer	endp

PointToGetInfoBuffer	proc	near
NOFXIP<	mov	dx, segment dgroup		; es:di = dx:bp = attrs	>
NOFXIP<	mov	es, dx							>
FXIP<	GetResourceSegmentNS dgroup, es					>
FXIP<	mov	dx, es				; dx = es = dgroup	>
	mov	di, offset getInfoStringBuffer
	mov	bp, di
	ret
PointToGetInfoBuffer	endp


GetInfoRelProtCommon	proc	near
	call	PointAndInitGetInfoBuffer	; es:di = dx:bp = release buf
	cmp	ds:[GIS_fileType], GFT_NOT_GEOS_FILE
	je	done
	lodsw					; get major #
	call	ASCIIizeWordAX			; show major #
	LocalLoadChar ax, '.'
	LocalPutChar esdi, ax
	lodsw					; get minor #
	call	ASCIIizeWordAX			; show minor #
;
; no second part for ZMGR - brianc 6/24/93
;
if not _ZMGR
SBCS <	mov	ax, ' ' or (' ' shl 8)		; show four spaces	>
DBCS <	mov	ax, ' '							>
	stosw
	stosw
DBCS <	stosw								>
DBCS <	stosw								>
	lodsw					; get change #
	call	ASCIIizeWordAX			; show change #
	LocalLoadChar ax, '-'
	LocalPutChar esdi, ax
	lodsw					; get engineering #
	call	ASCIIizeWordAX			; show engineering #
endif
done:
	ret
GetInfoRelProtCommon	endp

GetInfoTokenCommon	proc	near
	call	PointAndInitGetInfoBuffer	; es:di = dx:bp = token buffer
	lodsb
	dec	si
	tst	al
	jz	done				; no token
	call	GetNameFromTokenDB
	jnc	done				; dx:bp = name from token DB
	LocalLoadChar ax, '\"'
	LocalPutChar esdi, ax
	mov	cx, 4
if DBCS_PCGEOS
charLoop:
	lodsb
	stosw
	loop	charLoop
else
	rep movsb
endif

DBCS <	mov	ax, '\"'						>
DBCS <	stosw								>
	push	bx, cx, dx
	call	LocalGetNumericFormat		; bx=thousands separator (DBCS)
SBCS <	mov	ah, bl				; sorry, SBCS (sic:) for now >
DBCS <	mov	ax, bx							>
DBCS <	stosw								>
	pop	bx, cx, dx
SBCS <	mov	al, '\"'						>
SBCS <	stosw								>
	lodsw					; ax = manuf ID
	call	ASCIIizeWordAX
SBCS <	clr	al							>
DBCS <	clr	ax							>
	LocalPutChar esdi, ax			; null-terminate
done:
	ret
GetInfoTokenCommon	endp

;
; Find the text moniker for a creator token in the DB. Much faster than
; questing after the application itself...
;
GetNameFromTokenDB	proc	near
	uses	ax, bx, dx, si, di, bp, ds
	.enter
	mov	ax, {word} ds:[si].GT_chars+0
	mov	bx, {word} ds:[si].GT_chars+2
	mov	si, ds:[si].GT_manufID
	mov	dh, ss:[desktopDisplayType]
	mov	bp, VMSF_TEXT_MASK
	clr	cx				; alloc global block
	push	di				; save buffer offset
	push	bp				; pass VisMonikerSearchFlags
	push	cx				; pass unused buffer size
	call	TokenLoadMoniker		; di = block, cx = size
	mov	bx, di
	pop	di				; retrieve buffer offset
	jc	done				; nothing in token DB
	call	MemLock
	mov	ds, ax
	test	ds:[VM_type], mask VMT_GSTRING	; make sure not gstring
	stc					; assume gstring
	jnz	freeAndDone			; if gstring, skip
	mov	si, offset VM_data + offset VMT_text	; ds:si = string
	sub	cx, size VisMoniker + size VMT_mnemonicOffset
						; cx = string size
	rep movsb				; copy over string
SBCS <	clr	al							>
DBCS <	clr	ax							>
	LocalPutChar esdi, ax			; null-terminate
	clc
freeAndDone:
	pushf
	call	MemFree				; free gstring buffer
	popf
done:
	.leave
	ret
GetNameFromTokenDB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGetInfoText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the text for a text object in the GetInfo DB

CALLED BY:	ShowCurrentGetInfoFile, GetInfoCheckLink

PASS:		ax - chunk handle of text object
		dx:bp - pointer to text

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 3/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGetInfoText	proc near
	uses	si
	.enter
	mov	bx, handle FileOperationUI
	mov_tr	si, ax
	call	CallSetText

	.leave
	ret
SetGetInfoText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopUserNotesMadeDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enabled OK button in Get Info box if user notes field
		changed

CALLED BY:	MSG_TEXT_MADE_DIRTY

PASS:		cx:dx = text object

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/04/90	broken out for usability fixes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopUserNotesMadeDirty	method	DesktopClass, MSG_META_TEXT_USER_MODIFIED
	cmp	cx, handle GetInfoUserNotes
	jne	done
	cmp	dx, offset GetInfoUserNotes
	jne	done
	mov	bx, handle GetInfoCtrlOK
	mov	si, offset GetInfoCtrlOK
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
	jmp	exit
done:
	cmp	cx, handle RenameToEntry
	jne	done
	cmp	dx, offset RenameToEntry
	jne	done
	mov	bx, handle RenameCtrlRename
	mov	si, offset RenameCtrlRename
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
exit:
	ret
DesktopUserNotesMadeDirty	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetInfoSaveNotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save user notes, if changed

CALLED BY:	INTERNAL
			DesktopGetInfoOk
			DesktopGetInfoNext

PASS:		nothing

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/04/90	broken out for usability fixes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetInfoSaveNotes	proc	near
	call	ShowHourglass
	;
	; change to directory specified in rename box, we don't care what
	; directory we are in when we quit, so no need to save current
	; directory
	;
	mov	si, offset FileOperationUI:GetInfoFileList
	call	GetSrcFromFileListAndSetCurDir
	jnc	10$
	tst	ax
	jz	exit
	call	MemUnlock
exitJMP::
	jmp	exit				; if error reported, done

10$:
	push	bx				; save FQT block handle
	;
	; save file attributes
	;	ds:dx = filename
	;
	call	SetNewFileAttributes
	jnc	attrDone
	call	DesktopOKError
noNotesToFreeJMP:
	jmp	noNotesToFree
	;
	; check if user notes changed
	;
attrDone:
	mov	bx, handle GetInfoUserNotes
	mov	si, offset GetInfoUserNotes
	mov	ax, MSG_VIS_TEXT_GET_USER_MODIFIED_STATE
	call	ObjMessageCall			; cx = 0 if clean
	jcxz	noNotesToFreeJMP		; exit if so
	push	dx
	;
	; get notes entered
	;
	mov	bx, handle GetInfoUserNotes
	mov	si, offset GetInfoUserNotes
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; return global block
	call	ObjMessageCall

	mov	bx, cx				; bx = notes block handle
	call	MemLock				; lock notes
	pop	dx				; ds:dx <- FOIE
		CheckHack <offset FOIE_name eq 0>

	push	bx				; save notes handle
	mov	es, ax
	clr	di				; es:di <- buffer

;	Get the size of the user notes in CX (including the null).
;	If it's larger than the max size (how could this possibly happen?)
;	then truncate it at the max size

	call	LocalStringSize		;CX <- size of buffer
	inc	cx			; ...including null
DBCS <	inc	cx			; ...including null		>
	cmp	cx, size FileUserNotes
	jbe	setNotes
	mov	cx, size FileUserNotes
SBCS <	mov	{char} es:[size FileUserNotes-1], C_NULL	>
DBCS <	mov	{wchar} es:[size FileUserNotes-2], C_NULL	>

setNotes:

	mov	ax, FEA_USER_NOTES		; ax <- attr to set
	call	FileSetPathExtAttributes
	jnc	noError
	call	DesktopOKError			; report error
noError:
	;
	; clean up
	;
	pop	bx				; free notes buffer
						;	(0 if null notes)
	tst	bx
	jz	noNotesToFree
	call	MemFree
noNotesToFree:
	pop	bx				; bx <- FQT block
	call	MemUnlock
	clc					; indicate success

	mov	ax, SP_TOP
	call	FileSetStandardPath		; be in top level path
exit:
	call	HideHourglass
	ret
GetInfoSaveNotes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDriveToolInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	user clicked or double-clicked on drive icon

CALLED BY:	MSG_DRIVETOOL_INTERNAL

PASS:		cl = drive number

RETURN:		nothing

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDriveToolInternal	method	DesktopClass, MSG_DRIVETOOL_INTERNAL
	.enter

registerDisk::
	;
	; register disk
	;
	mov	al, cl
	call	DiskRegisterDiskSilently
	jnc	diskRegistered

	mov	ax, ERROR_DRIVE_NOT_READY
	call	DesktopOKError
	jmp	exit
	;
	; open root directory Folder Window for this drive
	;
diskRegistered:					; bx = new disk handle
	;
	; if openRootPath has changed, then the corresponding XIP code
	; has to be changed too.
	;
NOFXIP <	mov	dx, cs				; dx:bp = root	>
NOFXIP <	mov	bp, offset openRootPath				>
FXIP <		mov	bp, C_BACKSLASH					>
FXIP <		push	bp						>
FXIP <		mov	dx, ss						>
FXIP <		mov	bp, sp			;dx:bp = backslash char	>
	push	bx
ND <	mov	cx, WOT_DRIVE			; open a drive folder	>
	call	CreateNewFolderWindow		; do it
	pop	cx				; cx <- disk handle, in case
						;  rescan needed
FXIP <		pop	bp						>
	jnc	exit				; new Folder Window created
	tst	ax				; existing Folder Window
						;	brought to front?
	jnz	exit				; no, done
	;
	; existing Folder Window for root directory of selected drive was
	; brought to front (not newly created), force rescan and redraw
	;
	;
	; if openRootPath has changed, then the corresponding XIP code
	; has to be changed too.
	;
NOFXIP <	mov	dx, cs				; dx:bp = root	>
NOFXIP <	mov	bp, offset openRootPath				>
FXIP <		mov	bp, C_BACKSLASH					>
FXIP <		push	bp						>
FXIP <		mov	dx, ss						>
FXIP <		mov	bp, sp			;dx:bp = backslash char	>
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	FindFolderWindow		; get folder object
	call	ShellFreePathBuffer		;  nuke returned path buffer
FXIP <		pop	bp						>
	jnc	exit				; not found, just exit
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, MSG_WINDOWS_REFRESH_CURRENT
	mov	di, mask MF_CALL
	call	ObjMessage
exit:
	.leave
	ret
DesktopDriveToolInternal	endm


ife FULL_EXECUTE_IN_PLACE
LocalDefNLString openRootPath <C_BACKSLASH,0>

endif


if _GMGR
if not _ZMGR
ifndef GEOLAUNCHER	; no Tree Window for GeoLauncher
if _TREE_MENU		; no Tree Window for NIKE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopNewTreeDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	user selects new drive for tree

CALLED BY:	MSG_NEW_TREE_DRIVE

PASS:		cx = identifier of DriveLetter object which got clicked

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/29/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopNewTreeDrive	method	DesktopClass, MSG_NEW_TREE_DRIVE
	;
	; get drive number
	;
	clr	ch				; cx = drive #
	mov	bp, cx				; bp = drive
	;
	; set new Tree Drive, if disk is good
	; else, leave current Tree Window alone and report error
	;
	call	SetTreeDriveAndShowTreeWindow
	ret
DesktopNewTreeDrive	endm

;
; pass:
;	bp = drive number
;
SetTreeDriveAndShowTreeWindow	proc	far
	;
	; try to register disk
	;
	mov	ax, bp				; al = drive number
	call	DiskRegisterDiskSilently
	jnc	noError				; bx = disk handle
	mov	ax, ERROR_DRIVE_NOT_READY
	call	DesktopOKError			; report error

	mov	ax, MSG_UPDATE_TREE_DRIVE
	mov	bx, handle TreeObject		; restore current tree drive
	mov	si, offset TreeObject		; in Tree Menu Drive List
	call	ObjMessageCallFixup

	jmp	short done			; do nothing more

noError:
	;
	; set new drive for Tree Window
	;	bx = disk handle
	;
	mov	cx, bx				; cx = disk handle
	mov	ax, MSG_TREE_STORE_NEW_DRIVE
	mov	bx, handle TreeObject
	mov	si, offset TreeObject
	call	ObjMessageFixup
	;
	; show Tree Window with new drive (brings-to-front or creates)
	;
	call	IsTreeWindowUp			; if up already, just front it
	jc	up
	call	CreateTreeWindow		; else, create
	jmp	short done
up:
	call	BringUpTreeWindow
done:
	ret
SetTreeDriveAndShowTreeWindow	endp

;
; returns:
;	carry set if Tree Window is up
;	carry clear if NOT
;
IsTreeWindowUp	proc	far
	mov	bx, handle FileSystemDisplayGroup	; ^lbx:si = DC
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjMessageCallFixup		; dx = # of children
	tst	dx				; any?
	jz	done				; nope, (carry clear)
	mov	cx, handle TreeWindow		; ^lcx:dx = Tree Window
	mov	dx, offset TreeWindow
	mov	ax, MSG_GEN_FIND_CHILD	; try to find Tree Window
	call	ObjMessageCallFixup
	cmc					; carry set if found
						; carry clear if NOT
done:
	ret
IsTreeWindowUp	endp

CreateTreeWindow	proc	near
	mov	ax, TRUE
	call	TreeWindowCommon
	ret
CreateTreeWindow	endp

BringUpTreeWindow	proc	far
	mov	ax, FALSE
	call	TreeWindowCommon
	ret
BringUpTreeWindow	endp

;
; pass:
;	ax = TRUE to create
;	ax = FALSE to bring to front
;
TreeWindowCommon	proc	near
if CLOSE_IN_OVERLAP
;;	;
;;	; get current window, in case it needs to be closed
;;	;
;;	push	ax				; save flag
;;	mov	bx, handle FileSystemDisplayGroup
;;	mov	si, offset FileSystemDisplayGroup
;;	mov	cx, TL_GEN_DISPLAY
;;	mov	ax, MSG_GET_TARGET
;;	call	ObjMessageCallFixup
;;	pop	ax				; retreive flag
;;	push	cx, dx				; save current window
endif		; if CLOSE_IN_OVERLAP
	cmp	ax, FALSE			; create?
	je	bringUp				; nope, just bring to front
EC <	cmp	ax, TRUE						>
EC <	ERROR_NZ	0						>
	;
	; create Tree Window
	;	^lbx:si = DisplayControl
	;
	mov	cx, handle TreeWindow		; ^lcx:dx = Tree Window
	mov	dx, offset TreeWindow
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, mask CCF_MARK_DIRTY or CCO_LAST
	call	ObjMessageCallFixup
	;
	; set horizontal and vertical increment amounts in
	; Directory Tree pane
	;
	mov	bx, handle TreeView
	mov	si, offset TreeView
	mov	cx, ss:[widest83FilenameWidth]
	mov	dx, ss:[desktopFontHeight]
	push	bp
	sub	sp, size PointDWord
	mov	bp, sp
	mov	ss:[bp].PD_x.low, cx
	clr	ss:[bp].PD_x.high
	mov	ss:[bp].PD_y.low, dx
	clr	ss:[bp].PD_y.high
	mov	dx, size PointDWord
	mov	ax, MSG_GEN_VIEW_SET_INCREMENT
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage
	add	sp, size PointDWord
	pop	bp
bringUp:
	;
	; bring up Tree Window (existing or just created)
	;
	mov	bx, handle TreeWindow
	mov	si, offset TreeWindow
	mov	dl, VUM_NOW
	mov	ax, MSG_GEN_SET_USABLE		; (also brings it up)
	call	ObjMessageCallFixup
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjMessageCallFixup
if CLOSE_IN_OVERLAP
	;
	; before closing, add Tree Window to LRU table
	;
	mov	bx, handle TreeWindow		; bx:si = Tree Window
	mov	si, offset TreeWindow
	call	UpdateWindowLRUStatus
	;
	; close current window if in maximized mode and current window
	; is closable
	;
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_DISPLAY_GROUP_GET_FULL_SIZED
	call	ObjMessageCallFixup		; carry set if maximized
	mov	cx, FALSE			; assume not maximized
	jnc	77$
	mov	cx, TRUE			; maximized
77$:
;;	pop	bx, si				; bx:si = current window
	push	cx				; save state
;;	cmp	bx, handle TreeWindow		; if current window is
;;	jne	80$				;	Tree Window, don't
;;	cmp	si, offset TreeWindow		;	close, we just brought
;;	je	notMax				;	it up!
;;80$:
	cmp	cx, TRUE			; maximized?
	jne	notMax				; no, don't close
;;	mov	ax, MSG_DESKDISPLAY_GET_OPEN_STATE
;;	call	ObjMessageCallFixup		; cx = state
;;	cmp	cx, TRUE			; can we close?
;;	jne	notMax				; nope
;;	mov	ax, MSG_GEN_DISPLAY_CLOSE
;;	call	ObjMessageCallFixup		; else, close
;;also deals with LRU table - brianc 10/8/90
	call	CloseOldestWindowIfPossible
;;
notMax:
	pop	cx				; retreive max state
	mov	bx, handle TreeWindow
	mov	si, offset TreeWindow
	mov	ax, MSG_DESKDISPLAY_SET_OPEN_STATE
	call	ObjMessageCallFixup
endif		; if CLOSE_IN_OVERLAP
	ret
TreeWindowCommon	endp

endif		; ifdef TREE_MENU
endif		; ifndef GEOLAUNCHER
endif		; if (not _ZMGR)
endif		; if _GMGR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDriveToolQTInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hack method handler to get desktop thread running

CALLED BY:	MSG_DRIVETOOL_QT_INTERNAL

PASS:		cx:dx = OD of DriveTool object which got QuickTransfer
		bp = mem handle of block of filenames

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDriveToolQTInternal	method	DesktopClass,
					MSG_DRIVETOOL_QT_INTERNAL
	.enter

	push	bp				; save block handle
	mov	bx, cx				; bx:si = object
	mov	si, dx
	;
	; get drive letter for move/copy to root directory
	;
	mov	ax, MSG_DRIVE_TOOL_GET_DRIVE
	call	ObjMessageCall			; bp = drive number
						; dx = disk handle
	pop	bx				; retrieve block handle
	call	DriveToolCopyMoveFiles

	.leave
	ret
DesktopDriveToolQTInternal	endm


if	_FCAB or _PEN_BASED

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDeskToolQTInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hack method handler to get desktop thread running

CALLED BY:	MSG_DESKTOOL_QT_INTERNAL

PASS:		cx:dx = OD of DeskTool object which got QuickTransfer
		bp = mem handle of block of filenames

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/18/89	Initial version
	dlitwin	6/1/92		Changed 'Trash' to 'Waste Basket' and tweaked
				  to handle GCM-only Waste Basket as a desktool

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDeskToolQTInternal	method	DesktopClass,
					MSG_DESKTOOL_QT_INTERNAL
	push	bp				; save block handle
	mov	bx, cx				; bx:si = object
	mov	si, dx
	mov	ax, MSG_DESK_TOOL_GET_TYPE
	call	ObjMessageCallFixup		; dl = tool type
	pop	bx				; retrieve block handle

	cmp	dl, DESKTOOL_WASTEBASKET
	je	wasteBasket
	mov	bx, bp				; bx = file list
	call	MemFree				; free it
	jmp	short done

wasteBasket:
	call	WastebasketDeleteFiles
	call	MemFree				; free up file list (bx)

done:
	ret
DesktopDeskToolQTInternal	endm
endif		; if _FCAB


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopDirToolQTInternal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hack method handler to get desktop thread running

CALLED BY:	MSG_DIRTOOL_QT_INTERNAL

PASS:		cx:dx = OD of DirTool object which got QuickTransfer
		bp = mem handle of block of filenames

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopDirToolQTInternal	method	DesktopClass, \
					MSG_DIRTOOL_QT_INTERNAL
	push	bp				; save block handle
	mov	bx, cx				; bx:si = object
	mov	si, dx
	mov	ax, MSG_DIR_TOOL_GET_TYPE
	call	ObjMessageCallFixup		; dl = tool type
	pop	bp				; retrieve block handle

	cmp	dl, DIRTOOL_UPDIR		; up/dir?
	je	upDir				; yes, handle specially
	;
	; move/copy to application or document directory
	;	bp = file list block
	;	dl = appl or doc
	;
	mov	bx, bp				; bx = file list block
	mov	bp, SP_DOCUMENT
	cmp	dl, DIRTOOL_DOCDIR
	je	haveDestination
	mov	bp, SP_APPLICATION
	cmp	dl, DIRTOOL_APPLDIR
	je	haveDestination
	mov	bp, SP_DOS_ROOM
	cmp	dl, DIRTOOL_DOSROOMDIR
	je	haveDestination
	mov	bp, SP_WASTE_BASKET
	mov	{byte} ss:[usingWastebasket], WASTEBASKET_BUTTON
EC <	cmp	dl, DIRTOOL_WASTEDIR					>
EC <	ERROR_NZ	UNKNOWN_DIRTOOL_TYPE				>
haveDestination:
	xchg	bp, dx				; bp = tool type
						; dx = dest disk handle/SP
NOFXIP <	segmov	ds, cs						>
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
	mov	si, offset FileOperationNullPath ; ds:si = null path for SP
	call	GetQuickTransferMethod		; bp = move or copy
	jc	error

	mov	cx, 1				; indicate BX is mem. block
	push	bx				; save file list block handle
	call	ProcessDragFilesCommon		; move/copy files
	mov	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET
	pop	bx				; bx = file list block handle
error:
	call	MemFree				; free list
	jmp	done

upDir:
if not _FCAB
	push	bp				; save file list handle
	mov	ax, MSG_META_GET_OBJ_BLOCK_OUTPUT
	call	ObjMessageCallFixup		; cx:dx = OD (Folder object)
	pop	bp				; bp = file list handle
	mov	ax, MSG_UP_DIR_QT
	mov	bx, cx
	mov	si, dx
	call	ObjMessageCall			; let folder do the work
endif		; if (not _FCAB)
FC<	mov	ax, MSG_UP_DIR_QT					    >
FC<	call	DesktopSendToCurrentWindow ; sends only to FolderClass obj. >
done:
	ret
DesktopDirToolQTInternal	endm

if FULL_EXECUTE_IN_PLACE
idata	segment
endif

LocalDefNLString FileOperationNullPath <0>

if FULL_EXECUTE_IN_PLACE
idata	ends
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DriveToolCopyMoveFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	move/copy files to a drive

CALLED BY:	INTERNAL
			DesktopDriveToolQTInternal

PASS:		bx = filelist mem. block handle
		bp = drive number

RETURN:		(frees file list block)

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DriveToolCopyMoveFiles	proc	near
	.enter

	push	bx				; save filelist block handle
	mov	ax, bp				; al = drive number
	call	DiskRegisterDisk		; bx = disk handle
	mov	dx, bx				; dx = disk handle
	pop	bx				; bx = filelist block handle
	jnc	haveDiskHandle			; no error
	mov	ax, ERROR_DRIVE_NOT_READY
	call	DesktopOKError			; else, report drive not ready
	jmp	short exit			; done
haveDiskHandle:
	;
	; get destination directory (root)
	;
NOFXIP <	segmov	ds, cs						>
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
	mov	si, offset driveToolRootDir	; ds:si = dest. pathname
	;
	; process file list
	;	ds:si = destination pathname
	;	dx = destination disk handle
	;	bp = dirtool
	;
	call	GetQuickTransferMethod		; bp = move or copy
	jc	error

	mov	cx, 1				; indicate bx = memory block
	push	bx
	call	ProcessDragFilesCommon		; pass ds:si, dx, bp, bx, cx
	pop	bx
error:
	call	MemFree				; free file list block
exit:
	.leave
	ret
DriveToolCopyMoveFiles	endp

if FULL_EXECUTE_IN_PLACE
idata	segment
endif

SBCS <driveToolRootDir	byte	C_BACKSLASH,0	; copy to root		>
DBCS <driveToolRootDir	wchar	C_BACKSLASH,0	; copy to root		>

if FULL_EXECUTE_IN_PLACE
idata	ends
endif


if (not _FCAB and not _ZMGR)
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopEmptyWastebasket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	save current settings in Options menu to geos.ini file

CALLED BY:	MSG_EMPTY_WASTEBASKET

PASS:		global variable 'loggingOut':
			= non-zero to give waring if Option is set
			  0 to bypass warning (regardless of the UI option).
				This should only be used when emptying on
				logout.

RETURN:		nothing

DESTROYED:	???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	05/19/92	Initial version
	dlitwin	01/02/93	added waring override flag (cx = 0)
	dlitwin	04/26/93	changed waring override flag to be global

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopEmptyWastebasket	method dynamic DesktopClass, MSG_EMPTY_WASTEBASKET
	.enter

	call	FilePushDir
	cmp	ss:[loggingOut], TRUE
	je	skipWarning

GM<	mov	bx, handle OptionsWarnings	>
GM<	mov	si, offset OptionsWarnings	>
ND<	mov	bx, handle OptionsList	>
ND<	mov	si, offset OptionsList	>
	mov	cx, mask OMI_CONFIRM_EMPTY_WB
	mov	ax, MSG_GEN_BOOLEAN_GROUP_IS_BOOLEAN_SELECTED
	call	ObjMessageCallFixup		; carry if set
	jnc	skipWarning

	mov	ax, WARNING_EMPTY_WASTEBASKET
	call	DesktopYesNoWarning
	cmp	ax, YESNO_YES
	LONG	jne	done

skipWarning:
	mov	ax, SP_WASTE_BASKET
	call	FileSetStandardPath

	mov	ax, size FileQuickTransferHeader + size FileOperationInfoEntry
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	mov	ds, ax				; lock into ax
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	LONG	jc	error
	push	bx				; save block handle

	clr	ax
	mov	ds:[FQTH_nextBlock], ax
	mov	ds:[FQTH_UIFA], ax
		; feedback data and remote flag don't matter because this
		; won't be used with a QuickTransfer, just internally.
	mov	ds:[FQTH_numFiles], 1		; just the Waste Basket
	mov	ds:[FQTH_diskHandle], SP_PRIVATE_DATA
SBCS <	mov	ds:[FQTH_pathname], 0		; no path string	>
DBCS <	mov	{wchar}ds:[FQTH_pathname], 0	; no path string	>

	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx				; allocate path buffer on stack
	clr	dx				; drive name doesn't matter
	mov	bx, SP_WASTE_BASKET
	mov	si, offset FQTH_pathname	; points to 0, or null-string
	segmov	es, ss, di
	mov	di, sp				; point es:di to stack buffer
	call	FileConstructFullPath

	std					; reverse search direction
SBCS <	mov	al, C_BACKSLASH			; search for last '\\'	>
DBCS <	mov	ax, C_BACKSLASH			; search for last '\\'	>
SBCS <	repne	scasb							>
DBCS <	repne	scasw							>
	cld					; reset direction flag to 0
	segxchg	ds, es				; swap these
	mov	si, di
	inc	si				; this points ds:si to the
	inc	si				;  path of the Waste Basket
DBCS <	inc	si							>
DBCS <	inc	si							>
	mov	di, size FileQuickTransferHeader + offset FOIE_name
SBCS <	mov	cx, FILE_LONGNAME_BUFFER_SIZE				>
DBCS <	mov	cx, FILE_LONGNAME_BUFFER_SIZE/2				>
SBCS <	rep	movsb							>
DBCS <	rep	movsw							>
	add	sp, PATH_BUFFER_SIZE		; pop stack buffer
	segmov	ds, es, si			; restore ds with block

	mov	si, size FileQuickTransferHeader
	mov	ds:[si].FOIE_type, GFT_DIRECTORY
	mov	ds:[si].FOIE_attrs, mask FA_SUBDIR
	mov	ds:[si].FOIE_pathInfo, mask DPI_EXISTS_LOCALLY

	clr	ss:[enteredFileOpRecursion]
	mov	ss:[skipDeletingDir], -1	; as non-zero as it gets

	call	FileBatchChangeNotifications

	call	FileDeleteAllDir

	call	FileFlushChangeNotifications

	mov	ss:[skipDeletingDir], 0		; reset to default of delete dir
	pop	bx				; restore block handle
	pushf					; MemFree doesn't preserve
	call	MemFree
	popf

	jnc	rescan
error:
	;
	; If we're shutting down, don't report errors; not only is it
	; pointless but it results in deadlock since the UI's
	; ShutdownStatusBox has the focus, meaning the user can't click
	; on our OK trigger, so our box stays up forever and prevents
	; shutdown from proceeding. - jenny 5/3/93
	;
	cmp	ss:[loggingOut], TRUE
	je	rescan
	call	DesktopOKError

rescan:
NOFXIP <	mov	ax, cs						>
FXIP<	mov	cx, ds							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	ax, ds							>
FXIP<	mov	ds, cx							>
	mov	bx, offset driveToolRootDir
	mov	cx, SP_WASTE_BASKET
	call	UpdateMarkedWindows
if _NEWDESK
	call	UpdateWastebasket
endif

done:
	call	FilePopDir
	.leave
	ret
DesktopEmptyWastebasket	endm

endif				; if ((not _FCAB) and (not _ZMGR) and
				; (not _NIKE)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		common file operation routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	break out small routines common to file operations to
		save space

CALLED BY:	INTERNAL
			DesktopEndRename
			DesktopEndDelete
			DesktopEndCreateDir
			DesktopEndCopy
			DesktopEndMove
			DesktopEndDuplicate

PASS:

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/16/90	routines broken out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
;
; change to directory specified in file op box, we don't care what
; directory we are in when we quit, so no need to save current
; directory
;
; pass:
;	si = chunk of cur dir text object
;	bx = chunk of file op box
; returns:
;	carry clear if successful
;	carry set if error encountered and reported
;
ChangeToFileOpSrcDir	proc
	call	GetAndExtractPathFromVolPath
	;
	; Set that as our current path.
	;
	xchg	bx, cx
;	mov	ss:[folderUpdateSrcDiskHandle], bx	; save for update
	mov	dx, si			; ds:dx <- path to set
	call	FileSetCurrentPath
	;
	; Free the path block, preserving the carry, of course.
	;
	mov	bx, cx
	pushf
	call	MemFree
	popf
	jnc	done
	call	DesktopOKError			; report error (preserves C)
done:
	ret
ChangeToFileOpSrcDir	endp

;
; pass:
;	si = chunk of cur dir text object
; return:
;	carry clear if no error
;		ds:si = path
;		bx = path buffer handle
;		cx = disk handle
;	carry set if error reported
;
GetAndExtractPathFromVolPath	proc	near
	mov	bx, handle FileOperationUI
	clr	dx
	mov	ax, MSG_GEN_PATH_GET
	call	ObjMessageCall
	jc	error

	;
	; Lock down the returned path block.
	;
	mov	bx, dx
	call	MemLock
	mov	ds, ax
	clr	si
done:
	ret
error:
	mov	ax, ERROR_PATH_NOT_FOUND	; assume error
	call	DesktopOKError
	jmp	done
GetAndExtractPathFromVolPath	endp


if 0 ; no substitution - usability 5/3/90

;
; pass:
;	ds:si = pathname to check
;	bx = handle of pathname buffer
; return:
;	carry clear if NO substitute made
;		nothing destroyed
;	carry set if substitute made
;		bx = new path buffer handle (old buffer freed)
;			= 0 if MemAlloc error
;				(if error, passed buffer is freed)
;		ds:si = unsubstituted path
;
UnsubstitutePathname	proc	near
	uses	di, bp, es
	.enter
	mov	bp, si				; save pathname for later
	segmov	es, cs
	mov	di, offset applUnsubstitute
	call	MainCheckSubdir			; ds:si = remainder of pathname
	jne	notAppl
	;
	; unsubstitute "Applications"
	;
	mov	dx, offset applPathname
	jmp	short unsubstituteCommon

notAppl:
	mov	si, bp				; ds:si = pathname to check
	mov	di, offset docUnsubstitute
	call	MainCheckSubdir
	jne	notDoc
	;
	; unsubstitute "Documents"
	;
	mov	dx, offset docPathname
unsubstituteCommon:
	push	bx				; save old path buffer handle
	push	ds				; save remaider pathname seg.
	xchg	dx, si				; dx = remainder of pathname
						; si = original appl/doc path
NOFXIP<	segmov	ds, dgroup, ax		; ds:si = original appl/doc path >
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
	mov	ax, PATHNAME_BUFFER_LENGTH
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jnc	50$
	pop	ax				; dump pathname segment
	pop	bx				; free old buffer
	call	MemFree
	clr	bx				; indicate error
	jmp	short errorExit

50$:
	mov	es, ax
	clr	di
	call	CopyNullString			; copy original appl/doc path
	pop	ds
	mov	si, dx				; ds:si = remainder of pathname
	call	CopyNullTermString		; tack it on
	mov	cx, bx				; save new path buffer handle
	pop	bx				; get old path buffer handle
	call	MemFree				; free it
	mov	bx, cx				; return new path buffer handle
	segmov	ds, es
	clr	si				; ds:si = unsubstituted path
errorExit:
	stc					; indicate unsubstitution made
	jmp	short done

notDoc:
	mov	si, bp				; restore ds:si for exit
	clc
done:
	.leave
	ret
UnsubstitutePathname	endp

applUnsubstitute	byte	'Applications',0
docUnsubstitute		byte	'Documents',0

MainCheckSubdir	proc	near
	uses	ax, cx, di
	.enter
	clr	al
	mov	cx, -1
	push	di
	repne scasb
	pop	di
	not	cx
	dec	cx				; sans null-terminator
	repe cmpsb
	jne	done
	cmp	{byte} ds:[si], 0		; null-term -> exact match
	je	done
	cmp	{byte} ds:[si], '\\'		; slash -> ds:si subdir of es:di
done:
	.leave
	ret
MainCheckSubdir	endp

endif

;
; get source filename
;
; pass:
;	si - source filename file operation file list
; returns:
;	carry - clear if file returned
;		set if no more files
;
GetSrcNameFromFileList	proc	near
	uses	ds, es, si, di
	.enter
	mov	bx, handle FileOperationUI
	mov	ax, MSG_GET_CURRENT_FILE
	call	ObjMessageCall
	jc	done
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	mov	si, dx
	segmov	es, ss
	mov	di, offset fileOperationInfoEntryBuffer
	mov	cx, size fileOperationInfoEntryBuffer
	rep	movsb
	call	MemUnlock
done:
	.leave
	ret
GetSrcNameFromFileList	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetSrcFromFileListAndSetCurDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current file from the passed FileOpFileList object
		and set our current directory to be that specified in the
		FQT block bound to the list, returning the FOIE for the
		next file to process.

CALLED BY:	?
PASS:		*FileOperationUI:si	= FileOpFileList object to call
RETURN:		carry	= set on error
			ax = FileError if couldn't change to directory
				bx = handle of block to unlock when done
				-or-
			ax = zero if we couldn't get the last file
				bx = *not* a handle of a block, so don't unlock!

		carry	= clear if directory set.
			ds:dx	= FileOperationInfoEntry for the file
			bx	= handle of block to unlock when done

DESTROYED:	cx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/25/92		Initial version
	dlitwin 5/19/93		changed a fatal error to be a returned
				error

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetSrcFromFileListAndSetCurDir proc	near
		uses	si, es, di
		.enter
	;
	; Fetch the address of the FOIE to process next. Caller should have
	; checked to see if there's a file left to process...
	;  dlitwin 5/19/93:  ...but is seems that a case where no file is left
	; to process when the user does a jackhammer like pressing of the action
	; button, so don't fatal error, instead return carry set and ax = zero.
	;
		mov	bx, handle FileOperationUI
		mov	ax, MSG_GET_CURRENT_FILE
		call	ObjMessageCall
		mov	ax, 0			; don't use 'clr' because this
		jc	done			; would mess with the flags.

	; Lock the block down and copy the current file into
	; fileOperationInfoEntryBuffer, in case something somewhere needs it
	;
		mov	bx, cx
		call	MemLock
		mov	ds, ax
		mov	si, dx
		segmov	es, ss
		mov	di, offset fileOperationInfoEntryBuffer
		mov	cx, size fileOperationInfoEntryBuffer
		rep	movsb
	;
	; Now switch to the directory described in the header.
	;
		push	bx, dx
		mov	bx, ds:[FQTH_diskHandle]
		mov	dx, offset FQTH_pathname
		call	FileSetCurrentPath
		pop	bx, dx
done:
		.leave
		ret
GetSrcFromFileListAndSetCurDir endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyMoveSourceSetUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a FileQuickTransfer block to hold the next source
		file upon which to operate

CALLED BY:	DesktopEndDuplicate
PASS:		*FileOperationUI:si = object holding current directory
		*FileOperationUI:ax = object holding list of files
RETURN:		carry set if no more files
		carry clear if another file on which to operate:
			ds:dx	= FileOperationInfoEntry to use
			ds:0	= FileQuickTransferHeader
			bx	= handle of same
DESTROYED:	ax, cx, dx, bp, si, di, es

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version
	ardeb	2/25/92		Updated for 2.0 FS

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyMoveSourceSetUp	proc	near

	mov	si, ax
	mov	bx, handle FileOperationUI
	mov	ax, MSG_GET_CURRENT_FILE
	call	ObjMessageCall			; ^hcx:dx <- FOIE
	jc	exit				; => no more files to do

	mov	bx, cx
	call	MemLock
	mov	ds, ax
	mov	ax, ds:[FQTH_diskHandle]

	;
	; XXX: copy the thing into fileOperationInfoEntryBuffer, in case
	; something needs it
	;

	segmov	es, ss
	mov	si, dx
	mov	di, offset fileOperationInfoEntryBuffer
	mov	cx, size fileOperationInfoEntryBuffer
	rep	movsb

	clc					; indicate file returned
exit:
	ret
CopyMoveSourceSetUp	endp

;
; called by:
;	DesktopEndRename
;	DesktopEndDuplicate
; pass:
;	ax = method to send to ourselves to update name list
;	si = destination filename chunk
; preserves:
;	cx
;
UpdateSrcAndDestNames	proc	near
	push	cx				; save file count
	push	si				; save dest filename chunk
	call	UpdateNameListManually
	pop	si				; retrieve dest filename chunk
	mov	bx, handle FileOperationUI
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset nullFilenameString			>
FXIP <		mov	dx, ss						>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	bp, sp			;dx:bp = null string	>
	call	CallSetText			; erase dest. filename
FXIP <		pop	cx			;restore the stack	>
	pop	cx				; retrieve file count
	ret
UpdateSrcAndDestNames	endp

;
; called by:
;	DesktopEndRename (via UpdateSrcAndDestNames)
;	DesktopEndDuplicate (via UpdateSrcAndDestNames)
;	DesktopEndChangeAttr
; pass:
;	ax = method to send to ourselves to update name list
; preserves:
;	cx
;
UpdateNameListManually	proc	near
	push	cx				; save file count
	mov	bx, handle 0			; send to ourselves
	call	ObjMessageForce			; do when operation finishes
	pop	cx				; retrieve file count
	ret
UpdateNameListManually	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisableIfLastFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Disable the passed button if the current file is the
		last one in the list

CALLED BY:	DesktopRenameNext,
		DesktopDuplicateNext,
		ChangeAttrShowAttrs,
		DesktopGetInfoNext

PASS:		ax - chunk handle of "Next" button
		si - chunk handle of file list

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/10/93   	added header


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DisableIfLastFile	proc	near

	push	ax				; save "Next" button
	mov	bx, handle FileOperationUI	; bx:si = file list
	mov	ax, MSG_GET_NUM_FILES_LEFT
	call	ObjMessageCall			; cx = number files remaining

	mov	ax, MSG_GEN_SET_ENABLED	; assume more than 1 file
	cmp	cx, 1
	ja	sendIt				; yes
	mov	ax, MSG_GEN_SET_NOT_ENABLED
sendIt:
	pop	si				; bx:si = "Next" button
	mov	dl, VUM_NOW
	call	ObjMessageNone
	ret
DisableIfLastFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChangeDestNameCharacteristics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:	RenameStuff, DuplicateStuff

PASS:		si - source name file list
		ax - destination name file list

		if not _DOS_LONG_NAME_SUPPORT
		cx - instruction field
		bx - instruction string
		endif


RETURN:		carry CLEAR if successful
			fileOperationInfoEntryBuffer - filled with
			next file

		carry SET if no more names


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/10/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChangeDestNameCharacteristics	proc	near
if not _DOS_LONG_NAME_SUPPORT
	push	cx				; save instruction field
	push	bx				; save instruction string
endif
	push	ax				; save dest name list
	call	GetSrcNameFromFileList
	pop	si				; retrieve dest name list
if not _DOS_LONG_NAME_SUPPORT
	pop	cx				; retrieve instructions
	jnc	good
	pop	ax				; clean up stack
	jmp	short noMoreNames

good:
	push	cx				; save instructions again
else
	jc	noMoreNames
endif	; not _DOS_LONG_NAME_SUPPORT

	;
	; clear destination name entry field
	;

	mov	bx, handle FileOperationUI
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset nullFilenameString			>
FXIP <		mov	dx, ss						>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	bp, sp			;dx:bp = null string	>
	call	CallSetText			; erase dest. filename
FXIP <		pop	cx			;restore the stack	>

if not _DOS_LONG_NAME_SUPPORT
	;
	; Set the maximum destination filename length.  If the thing
	; being copied is a subdir, then always allow 32-character
	; filenames.
	;

	mov	cx, FILE_LONGNAME_LENGTH	; assume longname
	test	ss:[fileOperationInfoEntryBuffer].FOIE_attrs, mask FA_SUBDIR
	jnz	setLength

	cmp	ss:[fileOperationInfoEntryBuffer].FOIE_type, GFT_NOT_GEOS_FILE
	jne	setLength

	mov	cx, DOS_DOT_FILE_NAME_LENGTH

setLength:
	push	cx
	mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
	call	ObjMessageCall
	pop	ax				; ax <- max length

	pop	cx				; cx <- DOS instructions
	mov	bp, offset nullStringString	; assume longname
	cmp	ax, FILE_LONGNAME_LENGTH
	je	setInst
	mov	bp, cx
setInst:
	call	LockString			; dx = string segment
	call	DerefDXBPString			; dx:bp = instruction string
	pop	si				; bx:si = instruction field
	call	CallSetText
	call	UnlockString
endif	; not _DOS_LONG_NAME_SUPPORT
	clc					; indicate success
noMoreNames:
	ret
ChangeDestNameCharacteristics	endp

;
; then update destination name field characteristics for this file
; and fill source name as default destination name
;
; called by:
;	FolderStartRename
;	TreeStartRename
; pass:
;	nothing
; return:
;	nothing
;
RenameStuff	proc	far
        ;
	; update state of "Next" button
	;
	mov     ax, offset RenameCtrlNext
	mov     si, offset RenameFromEntry
	call    DisableIfLastFile
	;
	; update destination name field characteristics for this file
	;
	mov	si, offset RenameFromEntry
	mov	ax, offset RenameToEntry
if not _DOS_LONG_NAME_SUPPORT
	mov	cx, offset RenameInstructions
	mov	bx, offset RenDupInstructionString
endif
	call	ChangeDestNameCharacteristics
	jc	exit				; no more files
	;
	; stuff source name in destination name field
	;
	mov	bp, offset fileOperationInfoEntryBuffer.FOIE_name
	mov	dx, ss				; dx:bp = name to set
	mov	bx, handle RenameToEntry
	mov	si, offset RenameToEntry
	call	CallSetText
	;
	; make destination name entry field the focus and select the default
	; name
	;
	call	EnableMakeFocusAndSelect
	;
	; disable Rename and mark not modified
	;
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	ObjMessageCall
	mov	bx, handle RenameCtrlRename
	mov	si, offset RenameCtrlRename
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCall
exit:
	ret
RenameStuff	endp

EnableMakeFocusAndSelect	proc	near
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCall
	;
	; make destination name entry field the focus
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjMessageCall
	;
	; select the default name
	;
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL
	mov	cx, 0
	mov	dx, TEXT_ADDRESS_PAST_END_LOW
	call	ObjMessageCall
	ret
EnableMakeFocusAndSelect	endp

;
; clear and disable Duplicate name field
;
; called by:
;	FolderStartDuplicate
;	TreeStartDuplicate
; pass:
;	nothing
; return:
;	nothing
; destroys:
;	ax, bx, cx, dx, di, bp
;
DuplicateSetup	proc	far
	push	si
	;
	; clear destination name entry
	;
	mov	bx, handle DuplicateToEntry
	mov	si, offset DuplicateToEntry
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset nullName				>
	clr	cx
FXIP <		mov	dx, ss						>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	bp, sp			;dx:bp = null string	>
	call	ObjMessageCallFixup
FXIP <		pop	ax			;restore the stack	>

	;
	; disable destination name entry so user doesn't get to enter
	; a name and then see it overwritten by the default destination name
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
	pop	si
	ret
DuplicateSetup	endp


;
; clear and disable Rename name field
;
; called by:
;	FolderStartRename
;	TreeStartRename
; pass:
;	nothing
; return:
;	nothing
; destroys:
;	ax, bx, cx, dx, di, bp
;
RenameSetup	proc	far
	push	si
	;
	; clear destination name entry
	;
	mov	bx, handle RenameToEntry
	mov	si, offset RenameToEntry
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset nullName				>
	clr	cx
FXIP <		mov	dx, ss						>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	bp, sp			;dx:bp = null string	>
	call	ObjMessageCallFixup
FXIP <		pop	ax			;restore the stack	>

	;
	; disable destination name entry so user doesn't get to enter
	; a name and then see it overwritten by the default destination name
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
	pop	si
	ret
RenameSetup	endp

ForceRef RenameSetup		; used in different source code module


ife FULL_EXECUTE_IN_PLACE
LocalDefNLString nullName <0>
endif



if DBCS_PCGEOS
DOS_NAME_BUFFER_SIZE = \
	((DOS_FILE_NAME_CORE_LENGTH + 1 + DOS_FILE_NAME_EXT_LENGTH + 1)+1)*(size wchar)
else
DOS_NAME_BUFFER_SIZE = \
	((DOS_FILE_NAME_CORE_LENGTH + 1 + DOS_FILE_NAME_EXT_LENGTH + 1)+1) and 0xfffe
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DuplicateStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the destination name field characteristics for
		this file and fill source name as default destination name

CALLED BY:	DesktopDuplicateNext, TreeStartDuplicate

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/10/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DuplicateStuff	proc	far

        ;
	; update state of "Next" button
	;

	mov     ax, offset DuplicateCtrlNext
	mov     si, offset DuplicateFromEntry
	call    DisableIfLastFile

	;
	; update destination name field characteristics for this file
	;

	mov	si, offset DuplicateFromEntry
	mov	ax, offset DuplicateToEntry
if not _DOS_LONG_NAME_SUPPORT
	mov	cx, offset DuplicateInstructions
	mov	bx, offset RenDupInstructionString
endif
	call	ChangeDestNameCharacteristics
	LONG jc	exit				; no more files

	;
	; stuff source name in destination name field
	;

	mov	bp, offset fileOperationInfoEntryBuffer.FOIE_name
	test	ss:[fileOperationInfoEntryBuffer].FOIE_attrs, mask FA_SUBDIR
	LONG jnz longName

	cmp	ss:[fileOperationInfoEntryBuffer].FOIE_type, GFT_NOT_GEOS_FILE
	jne	longName

	;
	; handle DOS 8.3 name - add/replace 8th char with "~" to/of
	; filename core
	;

	push	ds, es
	mov	ax, ss
	mov	ds, ax
	mov	es, ax
	mov	si, bp
	sub	sp, DOS_NAME_BUFFER_SIZE
	mov	di, sp
	mov	bp, sp
	mov	cx, DOS_FILE_NAME_CORE_LENGTH
copyLoop:
	LocalGetChar ax, dssi
	LocalCmpChar ax, '.'
	je	addTilde
	LocalIsNull ax
	jz	addTilde
	LocalCmpChar ax, '?'
	jne	store
if not DBCS_PCGEOS
	;
	; Funky DOS char mapped to funky geos char sequence; drop all three
	; chars on the floor.
	;
EC <	lodsb								>
EC <	tst	al							>
EC <	ERROR_Z	GOT_INVALID_NAME_FROM_FILE_ENUM				>
EC <	cmp	al, '.'							>
EC <	ERROR_E	GOT_INVALID_NAME_FROM_FILE_ENUM				>
EC <	lodsb								>
EC <	tst	al							>
EC <	ERROR_Z	GOT_INVALID_NAME_FROM_FILE_ENUM				>
EC <	cmp	al, '.'							>
EC <	ERROR_E	GOT_INVALID_NAME_FROM_FILE_ENUM				>

NEC <	inc	si							>
NEC <	inc	si							>
endif
	jmp	copyLoop
store:
	LocalPutChar esdi, ax
	loop	copyLoop
	LocalPrevChar esdi			; erase 8th char
	LocalNextChar dssi			; no si adjust needed
addTilde:
	LocalPrevChar dssi			; restore char
	LocalLoadChar ax, '~'
extLoop:
	LocalPutChar esdi, ax
	LocalGetChar ax, dssi
	LocalIsNull ax
	jnz	extLoop
	LocalPutChar esdi, ax			; store null
	mov	dx, ss				; dx:bp = name
	mov	bx, handle DuplicateToEntry
	mov	si, offset DuplicateToEntry
	call	CallSetText
	add	sp, DOS_NAME_BUFFER_SIZE
	pop	ds, es
	jmp	short afterSetName

longName:
	;
	; handle longname - append "(Copy)" (localized)
	;	ss:bp = longname
	;
	push	ds, es
	sub	sp, 30+FILE_LONGNAME_LENGTH	; room for template & fname
	segmov	es, ss				; es:di = buffer
	mov	di, sp
	GetResourceHandleNS	Dup32PrefixString, bx
	call	MemLock
	mov	ds, ax				; ds = template segment
	mov	si, offset Dup32PrefixString
	mov	si, ds:[si]			; si = template string
	clr	cx
charLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax				; end of string?
	jz	stringDone			; yes
	LocalCmpChar ax, 01h			; filename param?
	jne	notFilename			; nope
	push	ds, si
	segmov	ds, ss				; ds:si = longname
	mov	si, bp
innerLoop:					; copy longname into buffer
	LocalGetChar ax, dssi
	LocalIsNull ax
	jz	innerDone
	cmp	cx, 20+FILE_LONGNAME_LENGTH	; too long?
	ja	10$				; yep, skip
	LocalPutChar esdi, ax
	inc	cx
10$:
	jmp	short innerLoop
innerDone:
	pop	ds, si				; restore pointer into string
	jmp	short nextChar
notFilename:
	cmp	cx, 20+FILE_LONGNAME_LENGTH	; too long?
	ja	nextChar			; yep, skip
	LocalPutChar esdi, ax			; copy character verbatim
	inc	cx
nextChar:
	jmp	short charLoop
stringDone:
	LocalPutChar esdi, ax			; store null-terminator
	call	MemUnlock			; unlock string resource
						; cx = length w/o null
	cmp	cx, FILE_LONGNAME_LENGTH	; too long?
	jbe	lengthOK
	mov	cx, FILE_LONGNAME_LENGTH	; yes, use full name length
lengthOK:
	mov	dx, ss				; dx:bp = complete string
	mov	bp, sp
	mov	bx, handle DuplicateToEntry
	mov	si, offset DuplicateToEntry
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessageCall
	add	sp, 30+FILE_LONGNAME_LENGTH	; remove stack buffer
	pop	ds, es
afterSetName:
	;
	; make destination name entry field the focus and select the default
	; name
	;
	call	EnableMakeFocusAndSelect
exit:
	ret
DuplicateStuff	endp


ife FULL_EXECUTE_IN_PLACE
LocalDefNLString nullFilenameString <0>
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RenameWithOverwrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rename 8.3 filename, overwriting existing file with
		destination name, if confirmation given by user

CALLED BY:	INTERNAL
			DesktopEndRename

PASS:		ds:dx = source name
		es:di = destination name
		correct disk asserted

RETURN:		carry set if error
			ax - error code

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RenameWithOverwrite	proc	near
	call	CheckRootSrcOperation		; can't rename root
	jc	done
	call	CheckRootDestOperation		; can't rename TO root
	jc	done
	call	CheckSystemFolderDestruction	; can't rename system folder
	jc	done

	;
	; check if new name is already in use (needed as conflicting named
	; links are not detected by FileRename)
	;
	push	ds, dx
	segmov	ds, es				; ds:dx = dest name
	mov	dx, di
	call	FileGetAttributes		; C set if error (ie not found)
	pop	ds, dx
	mov	ax, ERROR_FILE_EXISTS		; assume exists
	cmc					; C set if exists
	jc	done				; exists, return with C set

	call	FileRename			; do rename

if TRY_CLOSE_ON_IN_USE_ERROR		; to support renaming of in-use file
	jnc	done				; no error
	push	cx
	mov	cx, 0				; try to close file
	call	TryCloseOrSaveFile
	pop	cx
	jc	done
	call	FileRename			; try again
endif

done:
	ret
RenameWithOverwrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFilenameList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update list of filenames

CALLED BY:	INTERNAL
			DesktopEndRename
			DesktopEndDelete
			DesktopEndCreateDir
			DesktopEndMove
			DesktopEndCopy

PASS:		ax:bx = start of next filename is list
		si = text object for filename list

RETURN:

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/22/89		Documented, adapted for general use

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0

;no longer needed 12/19/90

UpdateFilenameList	proc	near
	push	ax, bx, cx, dx, bp, ds, es, si, di
	mov	dx, ax				; dx:bp = new src name list
	mov	bp, bx
	mov	bx, handle FileOperationUI
	call	CallSetText
	pop	ax, bx, cx, dx, bp, ds, es, si, di
	ret
UpdateFilenameList	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowFileOpStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	show name of file for file operation

CALLED BY:	INTERNAL
			DesktopEndRename
			DesktopEndDelete
			DesktopEndCreateDir
			DesktopEndCopy
			DesktopEndMove

PASS:		ds:dx - filename
		si - status field
		bp - status string chunk (in DeskStringsRare block)
		carry set if ds:dx is longname and no conversion is needed
		carry clear if ds:dx is DOS name and conversion is required

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/25/89		Initial version
	brianc	9/8/89		changed to common routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowFileOpStatus	proc	near
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter
	mov	cx, si				; save status field
	mov	si, bp				; si = status string chunk
	mov	bp, ds				; bp = filename segment
SBCS <	sub	sp, 60+FILE_LONGNAME_LENGTH	; (50 chars for param string)>
DBCS <	sub	sp, (60+FILE_LONGNAME_LENGTH)*2	; (50 chars for param string)>
	segmov	es, ss				; es:di = buffer
	mov	di, sp
	mov	bx, handle DeskStringsRare
	push	bx
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			; ds:si = status string
	clr	bx
charLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax				; end of string?
	jz	stringDone			; yes
	LocalCmpChar ax, 01h			; filename param?
	jne	notFilename			; nope
	push	ds, si				; save status string
	push	di				; save name offset
	push	di				; save again
	mov	ds, bp				; ds:si = filename
	mov	si, dx
innerLoop:
	LocalGetChar ax, dssi
	LocalIsNull ax
	jz	innerDone
	cmp	bx, 54+FILE_LONGNAME_LENGTH	; too long?
	ja	10$				; yep, skip
	LocalPutChar esdi, ax
	inc	bx
10$:
	jmp	short innerLoop
innerDone:
	mov	si, di				; si = current offset
	pop	ax				; ax = original offset
	sub	ax, si				; ax = name length
	pop	si				; dgroup:si = fname to convert
	pop	ds, si				; restore pointer into string
	jmp	short nextChar
notFilename:
	cmp	bx, 54+FILE_LONGNAME_LENGTH	; too long?
	ja	nextChar			; yep, skip
	LocalPutChar esdi, ax			; copy character verbatim
	inc	bx
nextChar:
	jmp	short charLoop
stringDone:
	LocalPutChar esdi, ax			; store null-terminator
	pop	bx
	call	MemUnlock			; unlock string resource

	mov	dx, ss				; dx:bp = complete string
	mov	bp, sp
	mov	bx, handle FileOperationUI	; bx:si = status field
	mov	si, cx
	call	CallSetText
SBCS <	add	sp, 60+FILE_LONGNAME_LENGTH				>
DBCS <	add	sp, (60+FILE_LONGNAME_LENGTH)*2				>
	.leave
	ret
ShowFileOpStatus	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowFileOpResult
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	show number of files involved in success file operation

CALLED BY:	INTERNAL
			DesktopEndRename
			DesktopEndDelete
			DesktopEndCreateDir
			DesktopEndCopy
			DesktopEndMove

PASS:		cx - number of files
		si - result field
		bp - result string
		dx - result string (singular)

RETURN:		preserves es, di

DESTROYED:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/25/89		Initial version
	brianc	9/8/89		changed to common routine
	clee	5/16/94		changed for XIP

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowFileOpResult	proc	near
	push	es, di

if 0

	mov	ax, cx				; get file count
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegment dgroup, es, TRASH_BX				>
	mov	di, offset fileCountBuffer
	call	ASCIIizeWordAX			; convert to ASCII string
						; 	(preserves bx, cx)
	push	bp				; save result string
	cmp	cx, 1
	jne	10$
	pop	bp
	push	dx				; else, use singular
10$:

	mov	dx, bx				; dx - seg of ASCII file count
	mov	bx, handle FileOperationUI	; bx:si = result field
	push	si				; save result field
	mov	bp, offset fileCountBuffer	; dx:bp = ASCII # files
	call	CallSetText

	mov	dx, cs				; get result string segment
	pop	si				; bx:si = result field
	pop	bp				; dx:bp = result string
	call	CallAppendText

else

	mov	bx, handle FileOperationUI
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset nullResultString			>
FXIP <		mov	dx, ss						>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	bp, sp			;dx:bp = null string	>
	call	CallSetText
FXIP <		pop	di			;restore the stack	>

endif

	pop	es, di
	ret
ShowFileOpResult	endp


ife FULL_EXECUTE_IN_PLACE
LocalDefNLString nullResultString <0>
endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForWildcards
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks filename for wildcards

CALLED BY:	INTERNAL

PASS:		ds:dx = null-terminated string to check

RETURN:		Z set if filename contains wildcard(s)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		check only the tail component

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0	; cannot enter wildcard chars - 6/12/90

CheckForWildcards	proc	near
	push	si, ax, dx, bp
	mov	bp, dx				; dx:bp = path to check
	mov	dx, ds
	call	GetTailComponent
	mov	si, bp				; ds:si = tail component
CFWs_loop:
	lodsb
	tst	al
	jz	CFWs_exit			; if null-term., exit with
						;	Z clear
	cmp	al, '*'
	je	CFWs_done			; exit with Z set
	cmp	al, '?'
	je	CFWs_done			; exit with Z set
	jmp	short CFWs_loop			; check next char
CFWs_exit:
	cmp	al, 0ffh			; will clear Z flag
CFWs_done:
	pop	si, ax, dx, bp
	ret
CheckForWildcards	endp

endif

;
; util routines
;

if 0
;no longer needed 12/19/90
GetUpdateDSDXList	proc	near
	mov	ax, ds
	mov	bx, dx
	call	GetNextFilename
	mov	dx, bx
	call	UpdateFilenameList
	ret
GetUpdateDSDXList	endp
endif

; NAME: 	CallGetText
; PASS: 	nothing
; RETURN: 	cx = length of text
;			if cx != 0,
;	  	dx = handle of block containing text
;
CallGetText	proc	near

	mov	bx, handle FileOperationUI
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; get text in a global block
	call	ObjMessageCall
	mov	dx, cx				; dx = handle
	mov	cx, ax				; cx = length of block
	jcxz	freeTheDarnBlock

done:
	ret
freeTheDarnBlock:
	;
	; If we've been given an empty block, free the thing so the callers
	; don't have to do so.
	;
	mov	bx, dx
	call	MemFree
	jmp	done

CallGetText	endp

FileOperation	ends
