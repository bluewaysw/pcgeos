COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cshobjMove.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/11/92   	Initial version.

DESCRIPTION:
	

	$Id: cshobjMoveCopy.asm,v 1.2 98/06/03 13:46:28 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	begin a MOVE operation for a FileQuickTransfer block	

PASS:		current directory = destination directory
		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass
		cx:0	- FileQuickTransferHeader for block

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectMove	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_MOVE

	mov	ax, MSG_SHELL_OBJECT_MOVE_ENTRY
	mov	dx, FOPT_MOVE
	GOTO	ShellObjectMoveCopyThrowAway
ShellObjectMove	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	begin a COPY operation for a FileQuickTransfer block	

PASS:		current directory = destination directory
		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectCopy	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_COPY
	mov	ax, MSG_SHELL_OBJECT_COPY_ENTRY
	mov	dx, FOPT_COPY
	GOTO	ShellObjectMoveCopyThrowAway
ShellObjectCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectThrowAway
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	begin a THROW_AWAY operation for a FileQuickTransfer block

PASS:		current directory = destination directory
		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass
		cx:0	= FileQuickTransferHeader of block

RETURN:		nothing 

DESTROYED:	ax

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectThrowAway	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_THROW_AWAY

if _NEWDESKBA
	;
	; If we are a student, see if these are coming from a class folder or
	; below.  If so, bail out.
	;
		call	ShellObjectCheckStudentTransferFromClassFolder
		jnc	okay

		mov	ax, ERROR_DELETE_IN_THIS_FOLDER_NOT_ALLOWED
		call	DesktopOKError
		jmp	done
okay:
endif		; if _NEWDESKBA

	;
	; If OCDL_SINGLE, then put up a menu at the beginning to
	; verify deletion.
	;

	mov	ax, MSG_FM_START_THROW_AWAY
	call	VerifyMenuDeleteThrowAway
	jnc	continue
BA<done:							>
	ret

continue:
	mov	ax, MSG_SHELL_OBJECT_THROW_AWAY_ENTRY
	mov	dx, FOPT_THROW_AWAY
	FALL_THRU	ShellObjectMoveCopyThrowAway
ShellObjectThrowAway	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectMoveCopyThrowAway
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Move or copy all the files in the quick transfer block

PASS:		current directory = destination directory
		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass
		cx 	= segment of quick transfer block
		dx	= FileOperationProgressType

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	11/11/92   	Initial version.
	dlitwin	11/28/92	completed header, handled error of
				CheckSrcDestConflict to avoid infinte loop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectMoveCopyThrowAway	proc	far

entryMessage		local	word	push	ax
currentFOPT		local	word	push	dx
evilName	local	FileLongName	; directory name in source
					;  directory that may not be
					;  moved or copied, as it's
					;  an ancestor of the dest. - or -
					;  it's the same name as the
					;  ancestor of the dest and replacing
					;  it would cause the source to be
					;  deleted.
evilError	local	FileError	; error to return if evilName
					;  spotted

ForceRef	evilName
ForceRef	evilError
ForceRef	entryMessage

	.enter

	mov	ss:[howToHandleRemoteFiles], RFBT_NOT_DETERMINED

	mov_tr	ax, dx		; FileOperationProgressType
	mov	ds, cx
	call	SuspendFolders
	call	SetFileOpProgressBox
	
	;
	; Make sure not copying/moving to self or to a descendent. Sets
	; our evilName variable for us.
	; 
	call	CheckSrcDestConflict
	jnc	loopSetup
	cmp	ss:[currentFOPT], FOPT_THROW_AWAY
	jne	errAndExit
	cmp	ax, ERROR_SAME_FILE
	jne	errAndExit
	mov	ax, ERROR_THROW_AWAY_FILE_IN_WB
errAndExit:
	mov	ds:[FQTH_numFiles], 0		; general error, kill operation
	call	DesktopOKError
	jc	unsuspend

loopSetup:
	;
	; loop to copy/move files
	;
	mov	cx, ds:[FQTH_numFiles]		; cx = number of files
	jcxz	unsuspend			; no files, done
	mov	si, size FileQuickTransferHeader	; ds:si = first file

fileLoop:
	call	SetUpMoveCopyParams		; set-up buffers and regs.
	jc	error

	call	SendMoveCopyThrowAwayMessage
	jnc	continue			; if no error, continue

error:
	cmp	ax, YESNO_CANCEL
	je	update

	cmp	ax, ERROR_PATH_TOO_LONG
	jne	gotError
	mov	ax, ERROR_COPY_DEST_PATH_TOO_LONG
if (not _FCAB and not _ZMGR)
	tst	ss:[usingWastebasket]
	jz	gotError
	mov	ax, ERROR_THROW_AWAY_DEST_PATH_TOO_LONG
endif		; if ((not _FCAB) and (not _ZMGR))
gotError:
	call	DesktopOKError
	jnc	continue			; ignored error, continue
	mov	ss:[recurErrorFlag], 0		; clear recursive error
	cmp	ax, DESK_DB_DETACH		; detaching?
	je	unsuspend			; if so, quit, don't update
	cmp	ax, YESNO_NO			; skip this file, continue
	je	continue
	cmp	ax, ERROR_DIRECTORY_NOT_EMPTY	; directory not moved, continue
	je	continue
	cmp	ax, ERROR_COPY_MOVE_TO_CHILD	; item not moved/copied, cont.
	je	continue
	cmp	ax, ERROR_REPLACE_PARENT	; item not moved/copied, cont.
	je	continue

;;same file error will be annoyingly generated for each file in the select
;;group, so once we see it, stop the entire operation - brianc 9/26/90
;;	cmp	ax, ERROR_SAME_FILE		; item not moved/copied, cont.
;;	je	continue
;(	cmp	ax, YESNO_CANCEL		; abort operation	)
;(	je	update							)

	cmp	ax, ERROR_FILE_IN_USE		; file-in-use, continue
	je	continue
	cmp	ax, ERROR_ACCESS_DENIED		; access denied error, continue
	je	continue
	cmp	ax, ERROR_SHARING_VIOLATION
	jne	update				; else, update
	;
	; continue after reporting error (or after YESNO_NO)
	;
continue:
	mov	ss:[recurErrorFlag], 0		; clear recursive error
	add	si, size FileOperationInfoEntry	; move to next file
	loop	fileLoop			; go back to do it, if any

update:
	;
	; finish up
	;
	call	UpdateMarkedWindows		; update folder windows
if GPC_FULL_WASTEBASKET
	call	UpdateWastebasket
endif
	clc					; get rid of any stray carries
unsuspend:
	call	UnsuspendFolders

	.leave
	ret
ShellObjectMoveCopyThrowAway	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendMoveCopyThrowAwayMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to a dummy object of the correct type
		for this FileOperationInfoEntry to perform the
		requested operation

CALLED BY:	ShellObjectMoveCopyThrowAway

PASS:		ds:si - FileOperationInfoEntry 
		ss:bp - inherited local vars

RETURN:		carry SET to abort all subsequent operations

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendMoveCopyThrowAwayMessage	proc near
	uses	cx, ds, si, bp

	.enter	inherit	ShellObjectMoveCopyThrowAway

	movdw	cxdx, dssi
	mov	si, ds:[si].FOIE_info
	call	UtilGetDummyFromTable
	mov	ax, ss:[entryMessage]
	mov	di, mask MF_CALL
	call	ObjMessage

	.leave
	ret
SendMoveCopyThrowAwayMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectMoveEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Move this file, unless we can't	

PASS:		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass

RETURN:		

DESTROYED:	ax,cx,dx,bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectMoveEntry	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_MOVE_ENTRY
		
	mov	ax, ERROR_CANNOT_MOVE
	mov	bl, mask SOA_MOVABLE
	mov	bp, MOVE_UPDATE_STRATEGY
	GOTO	ShellObjectMoveCopyEntryCommon
ShellObjectMoveEntry	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectThrowAwayEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Throw away this entry, unless it should be DELETEd instead

PASS:		*ds:si	- ShellObjectClass object
		ds:di	- ShellObjectClass instance data
		es	- segment of ShellObjectClass
		cx:0	- FileQuickTransferHeader
		cx:dx	- FileOperationInfoEntry
RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/17/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectThrowAwayEntry	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_THROW_AWAY_ENTRY
	;
	; Some objects always get DELETED rather than THROWN AWAY
	;

		test	ds:[di].SOI_attrs, mask SOA_FORCE_DELETE
		jz	notDelete

		call	FilePushDir

		push	ds, dx
		call	ShellObjectChangeToFileQuickTransferDir
		pop	ds, dx

		mov	ax, MSG_SHELL_OBJECT_DELETE_ENTRY
		call	ObjCallInstanceNoLock

		call	FilePopDir
		ret		

notDelete:
		mov	ax, ERROR_CANNOT_MOVE
		mov	bl, mask SOA_MOVABLE
		mov	bp, MOVE_UPDATE_STRATEGY
		GOTO	ShellObjectMoveCopyEntryCommon

ShellObjectThrowAwayEntry	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectCopyEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Copy this file, unless we can't	

PASS:		*ds:si	= ShellObjectClass object
		ds:di	= ShellObjectClass instance data
		es	= segment of ShellObjectClass

RETURN:		

DESTROYED:	ax,cx,dx,bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ShellObjectCopyEntry	method	dynamic	ShellObjectClass, 
					MSG_SHELL_OBJECT_COPY_ENTRY
	mov	ax, ERROR_CANNOT_COPY
	mov	bl, mask SOA_COPYABLE
	mov	bp, COPY_UPDATE_STRATEGY
	FALL_THRU	ShellObjectMoveCopyEntryCommon
ShellObjectCopyEntry	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShellObjectMoveCopyEntryCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed attribute is set, and, if not, don't
		allow the operation to continue

CALLED BY:	ShellObjectMoveEntry, ShellObjectCopyEntry,

PASS:		ds:di - instance data
		ax - DesktopError to put up if op not allowed
		bl - mask to check
		cx:dx - FileOperationInfoEntry
		bp - update strategy 

RETURN:		carry SET to abort operation
			ax - DesktopErrors

DESTROYED:	ax,bx,cx,dx,si,di,bp,es,ds

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/19/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShellObjectMoveCopyEntryCommon	proc	far
	class	ShellObjectClass

	test	ds:[di].SOI_attrs, bl
	jz	cannotDo
if GPC_CREATE_DESKTOP_LINK
	;
	; disallow move and copy of links, except throw away or
	; move between desktop and wastebasket
	;
	pushdw	dssi
	movdw	dssi, cxdx
	test	ds:[si].FOIE_attrs, mask FA_LINK
	popdw	dssi
	jz	afterLink		; not link, allow
	;
	; link debug, allow anything
	;
	cmp	ss:[debugLinks], TRUE
	je	allowOp
	;
	; is link, never allow copy
	;
	test	bl, mask SOA_COPYABLE
	jnz	cannotDo		; don't allow link copy
	;
	; is link, allow move to waste or desktop only
	;
	call	UtilCheckCurIfDesktopDir
	jc	allowOp			; is desktop
	call	UtilCheckCurIfWasteDir	; is waste
	jc	allowOp
	jmp	short cannotDo

afterLink:
endif
if GPC_FOLDER_WINDOW_MENUS
	;
	; disallow move, copy and throw away of executable if not debug
	;
if GPC_DEBUG_MODE
	cmp	ss:[debugMode], TRUE
	je	allowExec
endif
	pushdw	dssi
	movdw	dssi, cxdx
	cmp	ds:[si].FOIE_type, GFT_EXECUTABLE
	je	popCannotDo
;use WOT_EXECUTABLE to handle fake executables
	cmp	ds:[si].FOIE_info, WOT_EXECUTABLE
popCannotDo:
	popdw	dssi
	je	cannotDo
allowExec:
endif
	;
	; We CAN do it, so go ahead -- pass FOIE and update strategy
	; to common routine.
	;
allowOp::
	mov_tr	ax, bp			; update strategy
	movdw	dssi, cxdx
	call	CopyMoveFileToDir
done:
	.leave
	ret

	;
	; We can't do this particular file, but be sure to clear the
	; carry, as we still might have other files to worry about.
	;
cannotDo:
	call	DesktopOKError
	clc
	jmp	done
ShellObjectMoveCopyEntryCommon	endp

if GPC_CREATE_DESKTOP_LINK
UtilCheckCurIfWasteDir	proc	near
	uses	ds, si, bx, cx
	.enter
	segmov	ds, ss, si
	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	mov	si, sp
	call	FileGetCurrentPath	; bx = disk handle
	mov	cx, bx
	call	UtilCheckIfWasteDir
	lea	sp, ds:[si]+PATH_BUFFER_SIZE	; preserves flags
	.leave
	ret
UtilCheckCurIfWasteDir	endp

UtilCheckIfWasteDir	proc	far
	uses	ax, bx, dx, es, di
	.enter
	clr	ax
	push	ax
	segmov	es, ss, di
	mov	di, sp
	mov	dx, SP_WASTE_BASKET
	call	FileComparePathsEvalLinks
	cmc				; if error, not dir
	jnc	done
	cmp	al, PCT_EQUAL
	stc				; assume equal
	je	done
	clc				; else, not dir
done:
	pop	ax
	.leave
	ret
UtilCheckIfWasteDir	endp

UtilCheckCurIfDesktopDir	proc	near
	uses	ds, si, bx, cx
	.enter
	segmov	ds, ss, si
	mov	cx, PATH_BUFFER_SIZE
	sub	sp, cx
	mov	si, sp
	call	FileGetCurrentPath	; bx = disk handle
	mov	cx, bx
	call	UtilCheckIfDesktopDir
	lea	sp, ds:[si]+PATH_BUFFER_SIZE	; preserves flags
	.leave
	ret
UtilCheckCurIfDesktopDir	endp

UtilCheckIfDesktopDir	proc	far
	uses	ax, bx, dx, es, di
	.enter
	segmov	es, cs, di
	mov	di, offset desktopCheckPath
	mov	dx, STANDARD_PATH_OF_DESKTOP_VOLUME
	call	FileComparePathsEvalLinks
	cmc				; if error, not dir
	jnc	done
	cmp	al, PCT_EQUAL
	stc				; assume equal
	je	done
	clc				; else, not dir
done:
	.leave
	ret
UtilCheckIfDesktopDir	endp

desktopCheckPath	char	ND_DESKTOP_RELATIVE_PATH,0
endif






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetUpMoveCopyParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine to compare path string segments to check
		for illegal moves.

CALLED BY:	ShellObjectMoveEntry, ShellObjectCopyEntry, 
		ShellObjectThrowAwayEntry

PASS:		inherits local variables evilName and evilError from above
		ds:si - FileOperationInfoEntry to check

RETURN:		ax - update strategy 

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	5/27/92		added this header (incomplete)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetUpMoveCopyParams	proc	near

		.enter	inherit ShellObjectMoveCopyThrowAway

	call	PrepFilenameForError		; copy name into global area

	;
	; See if the entry is the Evil Name for which we've decided to look.
	;
 
	segmov	es, ss
	lea	di, ss:[evilName]
SBCS <	push	si							>
	CheckHack <offset FOIE_name eq 0>
	call	CompareString
SBCS <	pop	si							>
	mov	ax, ss:[evilError]		; assume yes
	stc					; => error
	je	done				; yes! death! death! death!
	clc
done:
	.leave
	ret
SetUpMoveCopyParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSrcDestConflict
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the source directory contained in the passed
		quick-transfer block doesn't conflict in any way with
		the directory that is our current working directory.

CALLED BY:	ProcessDragFilesCommon
PASS:		ds:0	= FileQuickTransferHeader
		current dir is destination
		ss:bp	= inherited frame from ProcessDragFilesCommon

RETURN:		if error
			carry set
			ax - FileError or DesktopErrors
		else
			carry clear

		evilName filled in
		evilError set


DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LocalDefNLString dotPath <".",0>

CheckSrcDestConflict proc near
		uses	bx, cx, dx, es, di, si, ds
		.enter	inherit	ShellObjectMoveCopyThrowAway

	;
	; if we have FOPT_THROW_AWAY and our source is already in the
	; Wastebasket, warn the user and bail out.
	;
		cmp	ss:[currentFOPT], FOPT_THROW_AWAY
		jne	continueChecking
		lea	si, ds:[FQTH_pathname]
		mov	dx, ds:[FQTH_diskHandle]
		call	IsThisInTheWastebasket
		jnc	continueChecking
		mov	ax, ERROR_THROW_AWAY_FILE_IN_WB
		jmp	done

continueChecking:

if FLOPPY_BASED_DOCUMENTS
	;
	; If both the source and the destination are on different
	; disks in the same removable-media drive, then let's avoid all this
	; link-checking crap.  No one uses links, and this forces two
	; extra disk swaps.
	;
	; Make sure source and dest disks are different
		
		clr	cx
		call	FileGetCurrentPath
		cmp	bx, ds:[FQTH_diskHandle]
		je	notRemovable

		call	DiskGetDrive
		mov	cl, al			; destination drive
	;
	; Make sure source and dest drives are the same (if they
	; are, then this proves that the drive is removable-media --
	; we don't actually have to check this explicitly)
	;
		mov	bx, ds:[FQTH_diskHandle]
		call	DiskGetDrive
		cmp	al, cl
		je	done

notRemovable:
endif

	;
	; Allocate a buffer to hold both the source and the dest complete
	; pathnames.
	; 
		call	ShellAlloc2PathBuffers
	;
	; Build the complete source name.
	; 
		mov	bx, ds:[FQTH_diskHandle]
		clr	dx		; no drive name needed
		mov	si, offset FQTH_pathname
		mov	di, offset PB2_path1
		mov	cx, size PB2_path1
		call	FileConstructActualPath
		LONG jc	freePaths

	;
	; Build the complete destination name.  Destination is the
	; CWD, so just call ConstructActual on "."
	; 
		push	bp			; save frame pointer
		mov	bp, bx			; save source diskhandle in bp
		segmov	ds, cs
		mov	si, offset dotPath
		mov	di, offset PB2_path2
		mov	cx, size PB2_path2
		clr	bx		; use current path
		call	FileConstructActualPath
		pushf
		sub	bx, bp
		popf
		pop	bp			; restore frame pointer
		jc	freePaths
	;
	; if the diskhandles are different, there is no conflict
	;
		tst	bx
		clc			; assume different disks
		jnz	freePaths

		mov	ss:[evilError], ERROR_COPY_MOVE_TO_CHILD
	;
	; If the dest is shorter than the src, it can't be a move to a child
	; directory, but there can be an attempt to replace the parent, so
	; switch the error code if so.
	; 
		segmov	ds, es
		mov	di, offset PB2_path2
SBCS <		call	LocalStringSize					>
DBCS <		call	LocalStringLength				>
		mov_tr	ax, cx		; dest length
		mov	di, offset PB2_path1
SBCS <		call	LocalStringSize					>
DBCS <		call	LocalStringLength				>
		cmp	ax, cx		; cmp dest, source
		jge	compare
		mov	ss:[evilError], ERROR_REPLACE_PARENT
		mov	cx, ax		; cx <- shorter length
compare:
	;
	; Not shorter, so compare the two to find the first mismatch
	; 
		mov	si, offset PB2_path1
		mov	di, offset PB2_path2
SBCS <		repe	cmpsb						>
DBCS <		repe	cmpsw						>
		clc
		jne	freePaths	; no match in prefix, so can't cause
					;  problems
SBCS <		mov	al, ds:[si]					>
DBCS <		mov	ax, ds:[si]					>
		LocalIsNull ax		; run out of src first?
		jnz	checkSeparator
		mov	si, di		; ds:si <- component to copy to
					;  evilName if found separator at end
					;  of other path
SBCS <		mov	al, ds:[si]					>
DBCS <		mov	ax, ds:[si]					>
		LocalIsNull ax
		jnz	checkSeparator
	;
	; Both paths are at their null-terminator, which means they're the
	; same, which means all files in the transfer block would be copied
	; over themselves...
	; 
		mov	ax, ERROR_SAME_FILE
		stc
		jmp	freePaths

checkSeparator:
	;
	; See if mismatched on a backslash in the longer path, which means
	; the error code we stored in evilError should be returned if a source
	; file matches the next component.  If comparing with the root, the
	; mismatch will have occured right AFTER the backslash, so check back
	; one character for this.
	; 
		LocalNextChar dssi	; assume equal, advanced past backslash
		LocalCmpChar ax, C_BACKSLASH
		clc
		je	related

		LocalPrevChar dssi	; past it, so couteract the previous inc
SBCS <		cmp	{char} ds:[si-1], C_BACKSLASH			>
DBCS <		cmp	{wchar}ds:[si-2], C_BACKSLASH			>
		clc
		jne	freePaths
	;
	; Paths are indeed related, so copy the next component from the longer
	; path into the evilName buffer.
	; 
related:
		segmov	es, ss
		lea	di, ss:[evilName]
SBCS <		mov	cx, size evilName				>
DBCS <		mov	cx, length evilName				>
copyEvilNameLoop:
		LocalGetChar ax, dssi
		LocalPutChar esdi, ax
		LocalCmpChar ax, C_BACKSLASH
		je	evilNameCopied
		LocalIsNull ax
		loopne	copyEvilNameLoop
EC <		ERROR_NE	EVIL_NAME_TOO_LONG???			>
evilNameCopied:
SBCS <		mov	{char}es:[di-1], 0				>
DBCS <		mov	{wchar}es:[di-2], 0				>
		segmov	es, ds
		clc
freePaths:
		call	ShellFreePathBuffer
done:
		.leave
		ret
CheckSrcDestConflict endp
