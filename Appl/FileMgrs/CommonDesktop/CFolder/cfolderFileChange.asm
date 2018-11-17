COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cfolderFileChange.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	6/15/93   	Initial version.

DESCRIPTION:
	

	$Id: cfolderFileChange.asm,v 1.2 98/06/03 13:33:18 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


FolderPathCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRescanFolderEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Rescan the attributes of a single entry in a folder.

CALLED BY:	(INTERNAL) FolderNotifyFileChange
PASS:		*ds:si	= Folder object
		dx	= FileChangeNotificationType
		es:bx	= FileChangeNotificationData
		di	= offset of FolderRecord in FOI_buffer
RETURN:		nothing
DESTROYED:	ax, bx, cx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		lock down the buffer of FolderRecords
		if FCNT_DELETE, unlink the thing from all lists it's on and
			resort the folder after invalidating where the item
			was
		else
			copy all the attributes normally used for scanning
				the entire folder, adjusting them to return
				their values in the existing FolderRecord
			if FCNT_RENAME, use the name in the FCND block
			else use the name in the FolderRecord
			get those extended attributes
			
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRescanFolderEntry proc	far
		uses	es, dx, bp, si

fcnd		local	fptr.FileChangeNotificationData push es, bx
rescanAttrs	local	NUM_RETURN_ATTRS dup(FileExtAttrDesc)

		class	FolderClass

		.enter
	;
	; Lock down the FOI_buffer, as we'll always need it.
	; 
		call	FolderLockBuffer

	;
	; If file-change was delete, unlink the matching entry from all
	; lists.
	; 
		cmp	dx, FCNT_DELETE
		LONG je	unlink

	;
	; Need to get the new file attributes. Push to the folder's
	; directory -- Making sure to POP it down below...
	; 
		call	FilePushDir
		push	dx
		mov	ax, ATTR_FOLDER_PATH_DATA
		mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
		pop	dx
	;
	; Copy the array of attributes we usually use when enumerating the
	; directory, adjusting the FEAD_value fields to point to the proper
	; place within the FolderRecord for the beastie that changed.
	; 
	; XIP: folderScanReturnAttrs has been moved into the resource
	;      TableResourceXIP to minimize the size of resources on the heap.
	;
		push	ds, si, dx, di
FXIP<		push	ax						>
FXIP<		mov	bx, handle TableResourceXIP			>
FXIP<		call	MemLock			; ax <- seg		>
FXIP<		mov	ds, ax						>
FXIP<		pop	ax						>
		mov	bx, offset folderScanReturnAttrs
		mov	cx, NUM_RETURN_ATTRS
		clr	si
copyAttrLoop:
NOFXIP<		mov	ax, cs:[bx].FEAD_attr				>
FXIP<		mov	ax, ds:[bx].FEAD_attr				>
		mov	ss:[rescanAttrs][si].FEAD_attr, ax
		mov	ss:[rescanAttrs][si].FEAD_value.segment, es
NOFXIP<		mov	ax, cs:[bx].FEAD_value.offset			>
FXIP<		mov	ax, ds:[bx].FEAD_value.offset			>
		add	ax, di
		mov	ss:[rescanAttrs][si].FEAD_value.offset, ax
NOFXIP<		mov	ax, cs:[bx].FEAD_size				>
FXIP<		mov	ax, ds:[bx].FEAD_size				>
		mov	ss:[rescanAttrs][si].FEAD_size, ax
		add	si, size FileExtAttrDesc
		add	bx, size FileExtAttrDesc
		loop	copyAttrLoop
	;
	; Unlock the XIP resource holding the file attrs
	;
FXIP<		push	bx						>
FXIP<		mov	bx, handle TableResourceXIP			>
FXIP<		call	MemUnlock					>
FXIP<		pop	bx						>

	;
	; Figure out what name we should look for. If the thing was renamed
	; or created, we need to use the FCND_name in the notification block.
	; Else use es:di.FR_name.
	; 
		cmp	dx, FCNT_RENAME
		je	useNewName
		cmp	dx, FCNT_CREATE
		je	useNewName
		segmov	ds, es
		lea	dx, ds:[di].FR_name
		jmp	getAttrs
useNewName:
		lds	dx, ss:[fcnd]
		add	dx, offset FCND_name
getAttrs:
		push	es
		segmov	es, ss
		lea	di, ss:[rescanAttrs]
		mov	ax, FEA_MULTIPLE
		mov	cx, NUM_RETURN_ATTRS
		call	FileGetPathExtAttributes
		pop	es
		pop	ds, si, dx, di

		call	FilePopDir


		jnc	redraw
		cmp	ax, ERROR_ATTR_NOT_FOUND
		je	redraw		; ignore these (might be a DOS file)
		cmp	ax, ERROR_ATTR_NOT_SUPPORTED
		je	redraw
		jmp	queueRescan
redraw:

	;
	; If the attributes changed, then see if we want to continue
	; showing this file.  XXX: Maybe should call CheckFileInList?
	;
		cmp	dx, FCNT_ATTRIBUTES
		jne	afterCheckAttrs

		DerefFolderObject	ds, si, bx
		mov	bh, ds:[bx].FOI_displayAttrs
		call	CheckFileAttrs
		jc	unlink

afterCheckAttrs:
		
		
if _NEWDESK

	;
	; Figure out the NewDeskObjectType for this thing.  Have to do
	; this whenever we get its attributes, because the call to
	; FileGetPathExtAttributes will nuke the old WOT field in
	; certain cases...
	;
		push	ds, si
		segmov	ds, es
		mov	si, di
					; ...ds:si <- FolderRecord
		call	BuildPathAndGetNewDeskObjectType
		pop	ds, si
endif
		
		cmp	dx, FCNT_CREATE
		jne	inval
	;
	; Extra stuff to do on create:
	;	- mark item as unpositioned, as yet.
	; 	- if folder has positioning on, find an empty slot for
	;	  the item, so we can just invalidate it, and not have to
	;	  redraw the entire folder.
	;
		segxchg	es, ds
		ornf	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		DerefFolderObject	es, si, bx

	;
	; Set the RECALC size, since the folder's bounds may need to
	; be recalculated as a result of adding this file.
	;

		ornf	es:[bx].FOI_positionFlags, mask FIPF_RECALC

		test	es:[bx].FOI_positionFlags, mask FIPF_POSITIONED

		jz	restoreSegs

		
		call	FolderRecordFindEmptySlot

restoreSegs:
		segxchg	ds, es			; *ds:si <- Folder again
						; es:di <- FolderRecord
inval:
		call	invalidateItem

		call	FolderUnlockBuffer
	;
	; If file-change was rename, resort the folder, if it's appropriate
	; 
		cmp	dx, FCNT_RENAME

		jne	notRename
jmpResort:
		jmp	resort
notRename:
		cmp	dx, FCNT_CREATE
		je	jmpResort

	;
	; Also do this on an attribute change, so that the greyed out
	; file gets redrawn, at the very least.
	;
		cmp	dx, FCNT_ATTRIBUTES
		je	jmpResort
		
done:
		.leave
		ret

queueRescan:
	;
	; If the file has vanished, things are likely confused, and the best
	; way to unconfuse ourselves is to rescan the folder. This happens,
	; for example, if one converts a 1.x VM file to 2.0. That creates
	; a temp file, writes to it, deletes the old file, and renames the
	; temp file to the new file. Sadly, by the time we (who are running on
	; the same thread) handle the queued notifications, the temp file is
	; history, so we think the rename has no effect on us, and we simply
	; lose track of the file.
	; 
		mov	bx, ds:[LMBH_handle]
		mov	ax, MSG_WINDOWS_REFRESH_CURRENT
		push	di
		mov	di, mask MF_FORCE_QUEUE or mask MF_FIXUP_DS or \
				mask MF_CHECK_DUPLICATE
		call	ObjMessage
		pop	di
unlink:

	;
	; Remove the thing from the display list.  If it's a DELETE,
	; nuke it from the buffer entirely.
	; dx - FileChangeNotificationType
	;
		DerefFolderObject	ds, si, bx
		cmp	dx, FCNT_DELETE
		jne	afterDecrement

	;
	; If a file is being deleted, decrement the file count in the
	; folder's instance data.
	;
		
		dec	ds:[bx].FOI_fileCount
		LONG jz	freeBuffer

afterDecrement:
		
	;
	; If folder has positioning on, invalidate the thing that is now no
	; more, so it gets erased. If positioning is off, the redraw we do
	; after resorting will take care of it for us.
	; 
		test	ds:[bx].FOI_positionFlags, mask FIPF_POSITIONED
		jz	checkCursor
		call	invalidateItem

checkCursor:

	;
	; If the cursor is already NIL, then skip all this garbage
	;
		cmp	ds:[bx].FOI_cursor, NIL
		je	afterCursor

	;
	; If item is recorded as the cursored object, or as the one last
	; clicked, make it not so.
	; 
		cmp	ds:[bx].FOI_cursor, di
		jb	afterCursor
		je	deleteCursor
	;
	; If the cursor is AFTER the object being deleted, decrement
	; the cursor position by the size of one FolderRecord, if
	; we're doing a delete, that is...
	;
		cmp	dx, FCNT_DELETE
		jne	afterCursor
		sub	ds:[bx].FOI_cursor, size FolderRecord
		jmp	afterCursor
deleteCursor:
		push	di
		mov	di, NIL
		call	SetCursor
		pop	di

afterCursor:
		cmp	ds:[bx].FOI_objectClick, di
		jne	shuffleDownToBuffalo
		mov	ds:[bx].FOI_objectClick, NIL

shuffleDownToBuffalo:
		cmp	dx, FCNT_DELETE
		jne	resort
		
	;
	; Now shuffle all the data that come after the nuked item down over
	; top of it.
	; 
		push	ds, si
		mov	cx, ds:[bx].FOI_bufferSize
		lea	si, es:[di+size FolderRecord]
		segmov	ds, es
		sub	cx, si
		rep	movsb
		pop	ds, si
		mov	ds:[bx].FOI_bufferSize, di
	;
	; Shrink the block, so if we enlarge it later, we'll get zeroes.
	; Besides, we like to be tidy.
	; 
		mov_tr	ax, di
		mov	bx, ds:[bx].FOI_buffer
		clr	cx
		call	MemReAlloc
		call	MemUnlock

resort:
	;
	; Forcibly rebuild the selection list and display list.
	; 
		push	bp
		mov	ax, TRUE
		call	BuildDisplayList
	;
	; Redraw the whole thing, if things aren't positioned (if they are,
	; we've taken care of invalidating the affected piece, so a full
	; redraw is unnecessary).
	; 
		DerefFolderObject	ds, si, di
		test	ds:[di].FOI_positionFlags, mask FIPF_POSITIONED
		jnz	resortDone
		or	ds:[di].FOI_positionFlags, mask FIPF_RECALC
		mov	ax, MSG_REDRAW
		call	ObjCallInstanceNoLock
resortDone:
		pop	bp
		jmp	done

	;--------------------
freeBuffer:
	;
	; Turn off positioning, now that the buffer is empty
	; (hopefully, this will nuke the directory positioning file)
	;
		and	ds:[bx].FOI_positionFlags, not mask FIPF_POSITIONED

		clr	ax
		mov	ds:[bx].FOI_bufferSize, ax
		mov	ds:[bx].FOI_cursor, NIL
		xchg	ax, ds:[bx].FOI_buffer
		mov_tr	bx, ax
		call	MemFree
		jmp	resort

	;--------------------
	; Invalidate the affected icon.
	;
	; Pass:		es:di	= FolderRecord
	; 		*ds:si	= FolderInstance
	; Return:	nothing
	; Destroyed:	nothing
	; 
invalidateItem:
	;
	; Invalidate the rectangle that is the item. Also invalidate most of
	; the optimization flags, as any attribute might have changed.
	; 
		push	bp, ds, bx, es, si, dx, di

		DerefFolderObject	ds, si, si
		mov	bp, ds:[si].DVI_gState
		mov	bx, ds:[si].FOI_buffer
		tst	bp
		jz	invalDone
  
		segxchg	ds, es
		andnf	ds:[di].FR_state, not (mask FRSF_HAVE_TOKEN or \
					mask FRSF_HAVE_NAME_WIDTH or \
					mask FRSF_CALLED_APPLICATION or \
					mask FRSF_DOS_FILE_WITH_CREATOR or \
					mask FRSF_DOS_FILE_WITH_TOKEN or \
					mask FRSF_HAVE_NAME_WIDTH)

	;
	; If the folder positioned, then invalidate the individual
	; folder record.  Otherwise, do nothing, as the entire folder
	; will be resorted and redrawn soon.
	;
		
		test	es:[si].FOI_positionFlags, mask FIPF_POSITIONED
		jz	invalDone

		call	FolderRecordInvalRect
	;
	; Adjust all the bounds, in case the name has changed.  Only
	; do this in icon mode
	;
		test	es:[si].FOI_displayMode, mask FIDM_LICON
		jz	invalDone

		test	ds:[di].FR_state, mask FRSF_UNPOSITIONED
		jnz	invalDone

		mov	cx, ds:[di].FR_iconBounds.R_left
		mov	dx, ds:[di].FR_iconBounds.R_top
		call	FolderRecordSetPosition
	;
	; And invalidate again, as bounds might now be larger, and we want the
	; whole thing to draw.
	; 
		call	FolderRecordInvalRect
invalDone:
		pop	bp, ds, bx, es, si, dx, di
		retn

FolderRescanFolderEntry endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take note of a change in the filesystem.

CALLED BY:	MSG_NOTIFY_FILE_CHANGE
PASS:		*ds:si	= Folder object
		dx	= FileChangeNotificationType
		^hbp	= FileChangeNotificationData
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderNotifyFileChange method dynamic FolderClass, MSG_NOTIFY_FILE_CHANGE

		uses	ax, es
		.enter

		mov	bx, bp
		call	MemLock
		mov	es, ax
		clr	di

	;
	; If this is a BATCH change, then see if we can do something
	; clever about it.
	;
		cmp	dx, FCNT_BATCH
		je	batch

		
		call	FolderNotifyFileChangeLow
unlock:
		call	MemUnlock

		.leave
		mov	di, offset FolderClass
		GOTO	ObjCallSuperNoLock

batch:
		call	FolderCheckManyCreates
		jmp	unlock
		
FolderNotifyFileChange endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckManyCreates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the passed batch notification block contains
		several FCNT_CREATE operations, and if so, just issue
		a rescan on this folder, rather than dealing with each
		one separately.

CALLED BY:	FolderNotifyFileChange

PASS:		es - segment of FileChangeBatchNotificationData
		dx - FileChangeNotificationType
		di = 0 (hack, whatever!)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAX_NUM_CREATES_FOR_RESCAN	equ	5

FolderCheckManyCreates	proc near

		
numCreates	local	word		push	di
	

		.enter

EC <		tst	di				>
EC <		ERROR_NZ	DESKTOP_FATAL_ERROR	>

		mov	di, offset FCBND_items
startLoop:
		cmp	di, es:[FCBND_end]
		jae	endLoop
		mov	dx, es:[di].FCBNI_type
		cmp	dx, FCNT_CREATE
		jne	next

		push	di
		add	di, offset FCBNI_disk
		call	FolderCheckIDIsOurs
		pop	di
		
		jnc	next
		
		inc	ss:[numCreates]
next:
		call	PointAtNextBatchNotificationItem
		jmp	startLoop
endLoop:
		cmp	ss:[numCreates], MAX_NUM_CREATES_FOR_RESCAN
		jae	rescan

		clr	di
		mov	dx, FCNT_BATCH 
		call	FolderNotifyFileChangeLow
		jmp	done
rescan:
		push	bp
		mov	ax, MSG_WINDOWS_REFRESH_CURRENT
		call	ObjCallInstanceNoLock
		pop	bp
		
done:
		
		.leave
		ret
FolderCheckManyCreates	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderNotifyFileChangeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single file-change

CALLED BY:	(INTERNAL) FolderNotifyFileChange, self
PASS:		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData
		*ds:si	= Folder object
RETURN:		nothing
DESTROYED:	ax, di, dx, cx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderNotifyFileChangeLow proc near
		class	FolderClass
		uses	bx
		.enter

EC <		cmp	dx, FileChangeNotificationType	>
EC <		ERROR_AE ILLEGAL_VALUE
		mov	bx, dx
		shl	bx
		call	cs:[notificationTable][bx]
		.leave
		ret

notificationTable	nptr.near	\
	notifyCreate,			; FCNT_CREATE
	notifyRename,			; FCNT_RENAME
	notifyOpen,			; FCNT_OPEN
	notifyDelete,			; FCNT_DELETE
	notifyContents,			; FCNT_CONTENTS
	notifyAttributes,		; FCNT_ATTRIBUTES
	notifyFormat,			; FCNT_DISK_FORMAT
	notifyClose,			; FCNT_CLOSE
	notifyBatch,			; FCNT_BATCH
	notifySPAdd,			; FCNT_ADD_SP_DIRECTORY
	notifySPDelete,			; FCNT_DELETE_SP_DIRECTORY
	notifyFileUnread,		; FCNT_FILE_UNREAD
	notifyFileRead			; FCNT_FILE_READ
.assert ($-notificationTable)/2 eq FileChangeNotificationType

notifyCreate:
GM <		call	NotifyUpdateFreeSpace			>
		
		call	FolderCheckIDIsOurs
		jc	createKid
;
; HACK for ZMGR only to rescan if this folder is on a standard path for
; which there is no local copy.  Fixes problem where local standard paths
; created by the system don't sent out the notification we expect.  Only
; reasonable on ZMGR where there is only one Folder Window open. - brianc
; 6/7/93
;
if CREATE_LOCAL_SP_FILE_CHANGE
		call	CheckCreateLocalSP
		jnc	notLocalSP		; no, done
						; else, nuke PathIDs...
		mov	ax, TEMP_FOLDER_PATH_IDS
		call	ObjVarDeleteData
		call	FilePushDir
		mov	ax, ATTR_FOLDER_PATH_DATA
		mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
		call	GenPathSetCurrentPathFromObjectPath
		jc	localSPPopDir		; error, give up
		call	FolderEnsurePathIDs	; ...and regenerate them
localSPPopDir:
		call	FilePopDir
notLocalSP:
endif
		retn
createKid:

if CREATE_LOCAL_SP_FILE_CHANGE
	;
	; First, check if newly created item is a local dir that should be
	; merged with a remote dir.  If so, rescan the entire folder instead
	; of adding a kid (leaving you with two of the dirs)
	;
		call	CheckFolderForFile
		LONG jc	isOurStdPath
endif

	;
	; Check if newly created item already exists.  This can happen if
	; link verification is running when we open this folder.  We get
	; the item once from FileEnum and again from FileChangeNotification.
	;
	; This code was originally only for NewDesk, but it can happen
	; any time a FolderScan happens at about the same time a file
	; is created, so leave it in for all FileMgrs.
	;
		call	CheckFolderForFile
		jnc	makeRoom
		retn
makeRoom:

	;
	; Make room for the new one.
	; 
		push	di
		DerefFolderObject	ds, si, di 
		mov	bx, ds:[di].FOI_buffer
		tst	bx
		jz	allocNew
		mov	ax, ds:[di].FOI_bufferSize
		add	ax, size FolderRecord
		mov	cx, (mask HAF_ZERO_INIT) shl 8
		call	MemReAlloc
		jc	ckMemErr
createCommon:
	;
	; Set di to the offset of the zero-initialized FolderRecord and
	; adjust FOI_bufferSize and FOI_fileCount
	; properly.
	; 
		mov	bx, di
		mov	di, ds:[bx].FOI_bufferSize
		lea	ax, [di+size FolderRecord]
		mov	ds:[bx].FOI_bufferSize, ax
		inc	ds:[bx].FOI_fileCount
		pop	bx		; es:bx <- FCND
		jmp	rescanKid

allocNew:
	;
	; Folder was empty, so create buffer for it.
	; 
		mov	ax, size FolderRecord + size FolderBufferHeader
		mov	cx, ((mask HAF_ZERO_INIT or mask HAF_LOCK) shl 8) \
					or mask HF_SWAPABLE
		call	MemAlloc
		jc	ckMemErr
		mov	ds:[di].FOI_buffer, bx
		mov	ds:[di].FOI_bufferSize, size FolderBufferHeader
	;
	; initialize FolderBufferHeader
	;
		push	es
		mov	es, ax
		mov	ax, ds:[LMBH_handle]
		movdw	es:[FBH_folder], axsi
		mov	es:[FBH_handle], bx
		call	MemUnlock
		pop	es
		jmp	createCommon
ckMemErr:
		pop	di		; pop FCND offset
		retn

	;--------------------
notifyDelete:
GM <		call	NotifyUpdateFreeSpace		>
		
		DerefFolderObject	ds, si, bx
		ornf	ds:[bx].FOI_positionFlags, mask FIPF_RECALC
		jmp	deleteRenameCommon
notifyRename:

	;
	; If it's this folder, fetch the new name, and do what needs
	; to be done
	;
		call	FolderCheckRename
		jc	toRetn
		
	;
	; See if the thing being renamed is in our ancestry
	;
		call	FolderCloseIfIDIsAncestor
		jc	toRetn

deleteRenameCommon:
		call	FolderCloseIfIDIsOurs
		jc	toRetn
		mov	bx, di		; save FCND offset
		call	FolderCheckIDIsKids
		jc	rescanKid
toRetn:
		retn

	;--------------------
notifyOpen:
notifyClose:
if _NEWDESK

		mov	bx, di
		call	FolderCheckIDIsKids

 if OPEN_CLOSE_NOTIFICATION
		jc	redrawOpenClose
		mov	di, bx			
		call	FolderCheckIDIsKidsTarget
 endif
		jnc	toRetn

redrawOpenClose:
ForceRef redrawOpenClose
	;
	; Toggle the FRSF_OPENED bit, and then redraw, unless this
	; thing isn't currently positioned
	;

		push	es
		call	FolderLockBuffer
		xornf	es:[di].FR_state, mask FRSF_OPENED

 if OPEN_CLOSE_NOTIFICATION
		test	es:[di].FR_state, mask FRSF_UNPOSITIONED
		jnz	afterExpose
		mov	ax, mask DFI_CLEAR or mask DFI_DRAW
		call	ExposeFolderObjectIcon
afterExpose:
 endif  ; OPEN_CLOSE_NOTIFICATION
		
		call	FolderUnlockBuffer
		pop	es
endif 	; _NEWDESK

		retn
	;--------------------
		
notifyContents:
GM <		call	NotifyUpdateFreeSpace		>

notifyAttributes:

		
		mov	bx, di		; save FCND offset
		call	FolderCheckIDIsKids
		jc	rescanKid
		retn

rescanKid:
		call	FolderRescanFolderEntry
		retn

	;--------------------
notifyFormat:
	; close if disk is ours
		mov	cx, es:[di].FCND_disk

		call	FolderCloseIfDisk
		retn

	;--------------------

	;
	; A directory has been added or delete as a StandardPath.  If our
	; folder is a descendant of that StandardPath, then force a rescan.
	;
notifySPAdd:
notifySPDelete:
		mov	ax, ATTR_FOLDER_PATH_DATA
		mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
		call	GenPathFetchDiskHandleAndDerefPath
		test	ax, DISK_IS_STD_PATH_MASK
		LONG jz	notStdPath		;branch if not StandardPath
	;
	; Are we below the StandardPath or at it?
	;
		mov	bx, ax			;bx <- our StandardPath
		mov	ax, es:[di].FCND_disk	;bp <- StandardPath added
		cmp	ax, bx			;at StandardPath?
		je	SPisOurStdPath		;branch if at StandardPath

		push	bp
		mov	bp, ax			;bp <- StandardPath added
		mov	cx, ax			; save in cx, as well
		call	FileStdPathCheckIfSubDir
		pop	bp
		tst	ax			;a subdirectory?
		jz	SPisOurStdPath		;branch if a subdirectory
	;
	; if our direct child has been added we need to redraw ourselves
	; as well (although deeper levels like grandchildren don't concern
	; us).  Build out the child, crop the last component and parse to
	; compare against the parent. 
	;
		push	ds, si, es, di, bx, bp
		mov	bp, bx
		mov	bx, cx
		mov	cx, size PathName
		sub	sp, cx
		segmov	es, ss, di
		mov	di, sp			; es:di is our stack buffer
		segmov	ds, cs, si
		mov	si, offset rootDir	; ds:si is our root path
		clr	dx			; no drive, bx is StandardPath
		call	FileConstructFullPath
		mov	ax, C_BACKSLASH
		LocalFindCharBackward
		LocalNextChar	esdi
		clr	ax			; crop last component
		LocalPutChar	esdi, ax
		mov	di, sp			; es:di is our path again
		call	FileParseStandardPath
		add	sp, size PathName		; pop stack buffer
		cmp	ax, bp
		pop	ds, si, es, di, bx, bp
		jne	notStdPath
		

SPisOurStdPath:
if _ZMGR
		;
		; ZMGR HACK: special delayed-via-global-UI update to deal
		; with DiskLock problems which would result in some standard
		; paths pieces being ignored on the scan if the UI is busily
		; updating the express menu - brianc 6/29/93
		;
		push	bp, si
		mov	bx, handle Desktop
		mov	si, offset Desktop
		mov	ax, MSG_GEN_FIND_PARENT
		call	ObjMessageCallFixup	;^lcx:dx = GenField
		pushdw	cxdx
		;
		; put up busy cursor, take down via process
		;
		mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
		mov	bx, handle Desktop
		mov	si, offset Desktop
		call	ObjMessageCallFixup
		;
		; place MSG_WINDOWS_REFRESH_CURRENT event on global UI queue
		;
		mov	bx, handle 0		;our process will route
						;refresh to current (ie only
						;on ZMGR) folder
						;(can't send to folder as it
						;may go away in the meantime)
		mov	ax, MSG_WINDOWS_REFRESH_CURRENT
		mov	di, mask MF_RECORD
		call	ObjMessage		;di = event
		mov	cx, di			;cx = event
		mov	dx, 0			;MessageFlags
		popdw	bxsi			;force-queue to GenField
		mov	ax, MSG_META_DISPATCH_EVENT	; (which is run by
		mov	di, mask MF_FORCE_QUEUE		; global ui thread)
		call	ObjMessage
		;
		; place MSG_GEN_APPLICATION_MARK_NOT_BUSY event on
		; global UI queue
		;
		mov	bx, handle Desktop
		mov	si, offset Desktop
		mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
		mov	di, mask MF_RECORD
		call	ObjMessage		;di = event
		mov	cx, di			;cx = event
		mov	dx, ds:[LMBH_handle]	;get owning geode from folder
		mov	bp, OFIQNS_INPUT_MANAGER	;start flush from here
		mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		pop	bp, si
		retn
endif

isOurStdPath::
	;
	; Force a rescan and redraw of our folder.
	;
		push	bp
		mov	ax, MSG_WINDOWS_REFRESH_CURRENT
		call	ObjCallInstanceNoLock
		pop	bp
notStdPath:
		retn
		
	;--------------------
notifyFileUnread:
notifyFileRead:
		retn
		
	;--------------------
notifyBatch:
	;
	; Process the batch o' notifications one at a time
	; 
		call	ShowHourglass
		
		push	bp
		mov	ax, MSG_META_SUSPEND
		call	ObjCallInstanceNoLock
		pop	bp

		mov	bx, es:[FCBND_end]
		mov	di, offset FCBND_items
batchLoop:
		cmp	di, bx		; done with all entries?
		jae	batchLoopDone
	;
	; Perform another notification. Fetch the type out
	; 
		mov	dx, es:[di].FCBNI_type
		push	di, dx
	;
	; Point to the start of the stuff that resembles a
	; FileChangeNotificationData structure and recurse
	; 
		add	di, offset FCBNI_disk
		call	FolderNotifyFileChangeLow
		pop	di, dx
		call	PointAtNextBatchNotificationItem
		jmp	batchLoop
		
batchLoopDone:
		push	bp
		mov	ax, MSG_META_UNSUSPEND
		call	ObjCallInstanceNoLock
		pop	bp

		call	HideHourglass
		
		retn
FolderNotifyFileChangeLow endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointAtNextBatchNotificationItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Point es:di at the next FileChangeBatchNotificationItem

CALLED BY:	FolderNotifyFileChangeLow, FolderCheckManyCreates

PASS:		es:di - current item
		dx - FileChangeNotificationType of current item

RETURN:		es:di - next item

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/18/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PointAtNextBatchNotificationItem	proc near

		.enter

		add	di, size FileChangeBatchNotificationItem

	CheckHack <FCNT_CREATE eq 0 and FCNT_RENAME eq 1>

		cmp	dx, FCNT_RENAME
		ja	done
		add	di, size FileLongName
done:
		.leave
		ret
PointAtNextBatchNotificationItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCreateLocalSP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if this folder object is on a standard path with
		no local copy and creating a folder with that SP name

CALLED BY:	INTERNAL
			FolderNotifyFileChangeLow

PASS:		*ds:si = Folder object
		es:di = FileChangeNotificationData

RETURN:		carry set if creating local standard path of
			this folder object
		carry clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CREATE_LOCAL_SP_FILE_CHANGE

CheckCreateLocalSP	proc	near
	uses	ax, bx, cx, dx, si, di
	.enter
	mov	ax, ATTR_FOLDER_PATH_DATA
	call	ObjVarFindData
	jnc	done			; not found, carry clear
	mov	cx, ds:[bx].GFP_disk
	test	cx, DISK_IS_STD_PATH_MASK
	jz	done			; not SP, carry clear
	mov	ax, ATTR_FOLDER_ACTUAL_PATH
	call	ObjVarFindData
	jnc	done			; not found, carry clear
	cmp	cx, ds:[bx].GFP_disk	; same SP?
	je	done			; yes, carry clear
	lea	dx, ds:[bx].GFP_path	; ds:dx = actual path
	call	GetTailComponent	; ds:dx = tail of SP
	mov	si, dx			; ds:si = tail of SP
	add	di, offset FCND_name	; es:di = created name
	push	di
	mov	cx, -1
	mov	al, 0
	repne scasb
	not	cx			; cx = length w/null
	pop	di
	repe cmpsb
	clc				; in case no match
	jne	done
	stc				; else, creating local version of SP
done:
	.leave
	ret
CheckCreateLocalSP	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFolderForFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if we created a local version of a directory for
		which we have a remote version in our folder buffer

CALLED BY:	INTERNAL
			FolderNotifyFileChangeLow

PASS:		*ds:si = Folder object
		es:di = FileChangeNotificationData

RETURN:		carry set if remote version exists in our folder buffer
		carry clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFolderForFile	proc	near
	uses	ax, bx, cx, dx
	.enter
	;
	; we know that something was created in our directory, see if the
	; new item's name (all we have to go by) matches the name of one
	; of the items in our folder buffer
	;
	mov	ax, SEGMENT_CS
	mov	bx, offset CheckFolderForFileCB
	movdw	cxdx, esdi		; cx:dx = FileChangeNotificationData
	call	FolderSendToDisplayList	; carry set if match

	.leave
	ret
CheckFolderForFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFolderForFileCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	callback for FolderSendToDisplayList in CheckFolderForFile
		(check for matching name)

CALLED BY:	CheckFolderForFile via FolderSendToDisplayList

PASS:		ds:di = FolderRecord
		cx:dx = FileChangeNotificationData

RETURN:		carry set if match (stops enumeration)
		carry clear otherwise (continue enumeration)

DESTROYED:	ax, ds, si, es, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFolderForFileCB	proc	far
	uses	cx
	.enter
	mov	si, di
		CheckHack <(offset FR_name) eq 0>
	movdw	esdi, cxdx
	add	di, offset FCND_name		; es:di = name of new item
	clr	cx				; cx <- NULL-terminated
	call	LocalCmpStrings
	clc					; in case no match
	jne	done
	stc					; else, match
done:
	.leave
	ret
CheckFolderForFileCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the rename affects this folder, and if so,
		set the folder's path using the new name

CALLED BY:	FolderNotifyFileChangeLow

PASS:		*ds:si - FolderClass object
		es:di - FileChangeNotificationData		

RETURN:		carry SET if rename affected this folder,
		carry CLEAR otherwise

DESTROYED:	ax,bx,cx

PSEUDO CODE/STRATEGY:	Only check the FIRST file ID in the folder's
			vardata.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	5/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckRename	proc near
		uses	dx,di,si,bp

		.enter

		mov	ax, TEMP_FOLDER_PATH_IDS
		call	ObjVarFindData
EC <		ERROR_NC DESKTOP_FATAL_ERROR		> 

		mov	ax, ds:[bx].FPID_disk
		cmp	ax, es:[di].FCND_disk
		jne	notOurs
		
		cmpdw	ds:[bx].FPID_id, es:[di].FCND_id, ax
		je	ours
notOurs:
		clc
done:
		.leave
		ret

ours:

		sub	sp, size PathName
		mov	bp, sp
		
	;
	; Fetch the path from the folder, and monkey with the final
	; component 
	;
		mov	dx, ss
		mov	ax, MSG_FOLDER_GET_PATH
		call	ObjCallInstanceNoLock

	;
	; Drop the last component, and add on the passed filename
	;
		push	ds			; object segment
		push	es, di
		segmov	es, ss
		mov	di, bp
		call	ShellDropFinalComponent
		pop	ds, dx
		add	dx, offset FCND_name
		call	ShellCombineFileAndPath	; es:di - new path
		pop	ds			; object segment


	;
	; Nuke various pieces of vardata that will get in the way when
	; we try to set this object's path
	;
		mov	bp, cx			; disk handle

		
		mov	bx, offset nukeVarDataList
		mov	cx, length nukeVarDataList
nukeLoop:
		mov	ax, cs:[bx]
		call	ObjVarDeleteData
		add	bx, size word
		loop	nukeLoop

afterLoop::

	;
	; Remove this folder from the FileChangeNotification list,
	; since adding the file IDs will add it back in.
	;
		
		call	UtilRemoveFromFileChangeList

		mov	cx, ss
		mov	dx, sp
		mov	ax, MSG_FOLDER_SET_PATH
		call	ObjCallInstanceNoLock

		mov	ax, MSG_FOLDER_SET_PRIMARY_MONIKER
		call	ObjCallInstanceNoLock

		mov	ax, MSG_WINDOWS_REFRESH_CURRENT
		call	ObjCallInstanceNoLock

		add	sp, size PathName
		stc
		jmp	done
		
		
FolderCheckRename	endp


nukeVarDataList	word	\
	ATTR_FOLDER_PATH_DATA,
	TEMP_FOLDER_SAVED_DISK_HANDLE,
	ATTR_FOLDER_ACTUAL_PATH,
	TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE,
	TEMP_FOLDER_PATH_IDS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseIfDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the folder if the passed disk is ours.

CALLED BY:	(INTERNAL) FolderNotifyFileChangeLow, FolderRemovingDisk
PASS:		cx	= disk handle
		*ds:si	= folder object
RETURN:		nothing
DESTROYED:	ax, bx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseIfDisk proc	near
		uses	dx, bp
		.enter
		mov	ax, TEMP_FOLDER_PATH_IDS
		call	ObjVarFindData
				; we're not on the list until this vardata
				; is created, so it *should* exist
EC <		ERROR_NC	DESKTOP_FATAL_ERROR			>
	;
	; Figure the offset past the last entry.
	; 
   		VarDataSizePtr	ds, bx, ax
		mov	dx, bx		; ds:dx <- start
		add	ax, bx		; ds:ax <- end
formatCompareLoop:
	;
	; See if this entry matches the stuff in the notification block
	; 
		cmp	cx, ds:[bx].FPID_disk
		je	ourDisk
	;
	; Nope -- advance to next, please.
	; 
		add	bx, size FilePathID
		cmp	bx, ax
		jb	formatCompareLoop
		jmp	done

ourDisk:
		cmp	bx, dx		; at start?
		jne	rescan		; no -- so keep open, but rescan
		add	bx, size FilePathID
		cmp	bx, ax		; only directory?
		jne	rescan		; no -- so keep open, but rescan

		call	FolderSendCloseViaQueue
		jmp	done

rescan:
		mov	ax, MSG_WINDOWS_REFRESH_CURRENT
		call	ObjCallInstanceNoLock		
done:
		.leave
		ret
FolderCloseIfDisk endp

if _GMGR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyUpdateFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the process to have it update the
		free space of the volume of the passed disk handle

CALLED BY:	FolderNotifyFileChangeLow

PASS:		es:di - FileChangeNotificationData

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	4/14/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyUpdateFreeSpace	proc near
		uses	ax,bx,cx,dx,di,si,bp
		.enter
		mov	cx, es:[di].FCND_disk
		clr	dx, bp,si
		mov	ax, MSG_DESKTOP_UPDATE_FREE_SPACE 
		mov	di, offset CheckDuplicateUpdate
		pushdw	csdi
		mov	di, mask MF_FORCE_QUEUE or \
				mask MF_CHECK_DUPLICATE or \
				mask MF_REPLACE	or \
				mask MF_CUSTOM
		mov	bx, handle 0
		call	ObjMessage

		.leave
		ret
NotifyUpdateFreeSpace	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDuplicateUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if duplicate messages have the same disk
		handle. 
CALLED BY:	
PASS:	ds:bx	= HandleEvent of an event already on queue
	ax	= message of the new event
	cx,dx,bp = data in the new event
	si	= lptr of destination of new event
RETURN:	bp	= new value to be passed in bp in new event
	di	= one of the PROC_SE_* values
CAN DESTROY:	si

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	3/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDuplicateUpdate	proc	far
	.enter

	cmp	ds:[bx].HE_method, ax	; see if MSG_DESKTOP_UPDATE_FREE_SPACE 
	je	found
CheckHack <PROC_SE_CONTINUE eq 0>
notFound:
	clr	di			; di = PROC_SE_CONTINUE
	ret
found:
	;
	; Compare the disk handle in cx to the disk handle in the
	; message handle.  If they are the same then the message is a
	; duplicate and we should replace it.
	;
	cmp	ds:[bx].HE_cx, cx
	jne 	notFound
	mov	di, PROC_SE_EXIT

	.leave
	ret
CheckDuplicateUpdate	endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseIfIDIsAncestor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this folder if the passed file ID is that of a
		folder that might be an ancestor

CALLED BY:	FolderNotifyFileChangeLow

PASS:		*ds:si - folder
		es:di - FileChangeNotificationData

RETURN:		carry SET if closing,
		carry clear otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseIfIDIsAncestor	proc near
		uses	ax,bx,cx,dx,bp
		.enter


		call	FolderDerefAncestorList	
		jc	close		; some error -- nuke this folder

		VarDataSizePtr	ds, bx, ax
		add	ax, bx

		call	FolderFetchIDFromNotificationBlock

		call	FolderCheckIDAgainstListCommon		
		jnc	done
close:
		call	FolderSendCloseViaQueue
		stc
done:
		.leave
		ret
FolderCloseIfIDIsAncestor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDerefAncestorList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dereference the list of ancestor file IDs

CALLED BY:	FolderCloseIfIDIsAncestor

PASS:		*ds:si - folder

RETURN:		if error
			carry set
			some ancestor does not exist and this folder
			should be closed
		else
			carry clear
			ds:bx - ancestor list


DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDerefAncestorList	proc near
		uses	di,si,es

folderPath	local	PathName	
idChunk		local	word
tempChunk	local	word

ForceRef	tempChunk

		.enter


		mov	ax, TEMP_FOLDER_ANCESTOR_IDS
		call	ObjVarFindData
		cmc
		LONG jnc done 	

	;
	; This will take a while...
	;

		call	ShowHourglass

	;
	; Send a MARK_NOT_BUSY via the queue
	;

		mov	ax, MSG_FOLDER_MARK_NOT_BUSY
		mov	bx, ds:[LMBH_handle]
		call	ObjMessageForce

	;
	; Allocate an ID chunk.  Store a null ID as the first element,
	; in case there are no ancestors for this folder.
	;

		call	FilePushDir

		clr	ax
		mov	cx, size FilePathID
		call	LMemAlloc
		mov	ss:[idChunk], ax
		mov_tr	di, ax
		mov	di, ds:[di]
		mov	ds:[di].FPID_disk, -1
		movdw	ds:[di].FPID_id, -1

		mov	dx, ss
		push	bp
		lea	bp, ss:[folderPath]
		call	FolderGetPath
		pop	bp
		mov	bx, cx

		call	BuildAncestorListLow
		jc	freeChunk			; some error - bail
	;
	; Do the actual path, if the user hasn't fallen asleep by now.
	;

		call	FolderCompareActualAndLogicalPaths
		je	afterActual

		mov	ax, ATTR_FOLDER_ACTUAL_PATH
		mov	dx, TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE
		mov	cx, size PathName
		segmov	es, ss
		lea	di, ss:[folderPath]
		call	GenPathGetObjectPath		

		mov	bx, cx
		call	BuildAncestorListLow
		jc	freeChunk

	;
	; Add the ancestor list onto the object
	;

afterActual:
		mov	di, ss:[idChunk]
		ChunkSizeHandle	ds, di, cx
		mov	ax, TEMP_FOLDER_ANCESTOR_IDS
		call	ObjVarAddData
		mov	si, ds:[di]
		mov	di, bx
		segmov	es, ds
		rep	movsb
		clc

freeChunk:
		mov	ax, ss:[idChunk]
		pushf			
		call	LMemFree
		call	FilePopDir
		popf
	
done:
		.leave
		ret
FolderDerefAncestorList	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildAncestorListLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build the whole monstrous list.  SLOW SLOW SLOW

CALLED BY:	FolderDerefAncestorList

PASS:		*ds:si - folder
		bx - disk handle 
		ss:bp - inherited local vars

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BuildAncestorListLow	proc near
		uses	ax,bx,cx,dx,di,si

		.enter	inherit	FolderDerefAncestorList


	;
	; Truncate the final component of the path
	;
startLoop:
		segmov	es, ss
		lea	di, ss:[folderPath]
		call	ShellDropFinalComponent
		cmc
		jnc	done

		push	ds
		segmov	ds, ss
		lea	dx, ss:[folderPath]
		call	FileSetCurrentPath
		pop	ds
		jc	done

		call	FileGetCurrentPathIDs
		jc	done

		mov	ss:[tempChunk], ax
		
	;
	; Append the new chunk onto the end of our existing chunk.
	; You'd think there'd be a utility routine somewhere...
	;

		mov_tr	si, ax			; new chunk
		ChunkSizeHandle	ds, si, cx


		mov	di, ss:[idChunk]
		ChunkSizeHandle ds, di, dx

		mov_tr	ax, di
		push	cx			; size of new chunk
		add	cx, dx
		call	LMemReAlloc
		pop	cx

		mov_tr	si, ax
		mov	di, ds:[si]		; id chunk addr
		add	di, dx			; ds:di - end of (old)
						; ID list.

		segmov	es, ds
		mov	si, ss:[tempChunk]
		mov	si, ds:[si]
		rep	movsb

		mov	ax, ss:[tempChunk]
		call	LMemFree
		jmp	startLoop
		

done:
		.leave
		ret
BuildAncestorListLow	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderFetchIDFromNotificationBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the three words of ID from the notification block

CALLED BY:	(INTERNAL) FolderCheckIDIsKids, FolderCheckIDIsOurs
PASS:		es:di	= FileChangeNotificationData
RETURN:		cxdx	= FileID
		bp	= disk handle
DESTROYED:	bx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderFetchIDFromNotificationBlock proc near
		movdw	cxdx, es:[di].FCND_id
		mov	bp, es:[di].FCND_disk
		ret
FolderFetchIDFromNotificationBlock endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckIDIsOurs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the FCND_disk:FCND_id is one of those for our folder

CALLED BY:	(INTERNAL) FolderNotifyFileChange
PASS:		*ds:si	= Folder object
		es:di	= FileChangeNotificationData
RETURN:		carry set if the ID is one of ours
DESTROYED:	bx, ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckIDIsOurs proc	near
		class	FolderClass
		uses	cx, dx, bp
		.enter
	;
	; Extract the three pertinent words from the block
	; 
		call	FolderFetchIDFromNotificationBlock

		call	FolderCheckFileIDCommon

		.leave
		ret
FolderCheckIDIsOurs		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckFileIDCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether the passed file ID matches one of
		the file IDs associated with this folder.

CALLED BY:	FolderCheckIDIsOurs, FolderCheckFileID

PASS:		*ds:si - folder
		cx:dx - file ID
		bp - disk handle, or 0 to just compare IDs		

RETURN:		if match:
			carry set
		else
			carry clear

DESTROYED:	ax,bx,

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 2/93   	pulled out from FolderCheckIDIsOurs

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckFileIDCommon	proc near
		uses	ax,bx
		.enter


		mov	ax, TEMP_FOLDER_PATH_IDS
		call	ObjVarFindData
EC <		ERROR_NC DESKTOP_FATAL_ERROR		> 

	;
	; Figure the offset past the last entry.
	; 
   		VarDataSizePtr	ds, bx, ax
		add	ax, bx		; ds:ax <- end

		call	FolderCheckIDAgainstListCommon
		.leave
		ret
FolderCheckFileIDCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckIDAgainstListCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the passed ID against the list

CALLED BY:	FolderCheckFileIDCommon, FolderCloseIfIDIsAncestor

PASS:		cx:dx - file ID
		bp - disk handle (or zero)
		ds:bx - file ID list
		ds:ax - end of list

RETURN:		carry SET if found

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 5/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckIDAgainstListCommon	proc near
		.enter

compareLoop:
	;
	; See if this entry matches the passed ID
	; 
		cmp	cx, ds:[bx].FPID_id.high
		jne	next
		cmp	dx, ds:[bx].FPID_id.low
		jne	next
	;
	; See if the disk matches, or if the passed disk is zero (wildcard)
	;
		cmp	bp, ds:[bx].FPID_disk
		je	done
		tst	bp
		jz	done
		

next:
	;
	; Nope -- advance to next, please.
	; 
		add	bx, size FilePathID
		cmp	bx, ax
		jb	compareLoop
		stc
done:
		cmc		; return carry *set* if found
	
		.leave
		ret
FolderCheckIDAgainstListCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	See if the passed file ID compares favorably with one
		of those contained in this folder

PASS:		*ds:si	- FolderClass object
		ds:di	- FolderClass instance data
		es	- segment of FolderClass
		cx:dx	- FileID
		bp	- disk handle, or zero to compare against any
			  and all

RETURN:		if match
			carry set
			cx:dx - folder OD
		else
			carry clear

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/ 2/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderCheckFileID	method	dynamic	FolderClass, 
					MSG_FOLDER_CHECK_FILE_ID
		uses	ax

		.enter

		mov	ax, TEMP_FOLDER_PATH_IDS
		call	ObjVarFindData
		jnc	buildFileIDs

checkIt:

		call	FolderCheckFileIDCommon
		jnc	done

		mov	cx, ds:[LMBH_handle]
		mov	dx, si
done:
		.leave
		ret

buildFileIDs:

	;
	; If we already know that this folder doesn't have a valid
	; path, then don't beat a dead horse.
	;
		test	ds:[di].FOI_folderState, mask FOS_BOGUS
		jnz	done

	;
	; Well, someone's asking us for our ID before we've had a
	; chance to build it (this happens on startup, for example),
	; so go ahead and build it now.
	;
		
		call	FilePushDir

	;
	; Set the path.  If carry set, then some error (directory no
	; longer exists, so just return carry clear, since this can't
	; be a match).
	;
		
		mov	ax, MSG_FOLDER_SET_CUR_PATH
		call	ObjCallInstanceNoLock
		cmc
		jnc	popDir

		call	FolderEnsurePathIDs
		stc		
popDir:
		call	FilePopDir
		jnc	done
		jmp	checkIt


FolderCheckFileID	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetFileID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Just return the FIRST file ID associated with this folder

PASS:		*ds:si	- FolderClass object
		ds:di	- FolderClass instance data
		es	- segment of FolderClass

RETURN:		cx:dx - file ID
		bp - disk handle

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/ 8/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderGetFileID	method	dynamic	FolderClass, 
					MSG_FOLDER_GET_FILE_ID


	;
	; Just return the first in our list of IDs, or zero if none.
	; Not very robust, but hey, we've got time constraints...
	;

		mov	ax, TEMP_FOLDER_PATH_IDS
		call	ObjVarFindData
		jnc	returnNone

		movdw	cxdx, ds:[bx].FPID_id
		mov	bp, ds:[bx].FPID_disk
done:	

		ret
returnNone:
		clr	cx, dx, bp
		jmp	done

FolderGetFileID	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseIfIDIsOurs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this folder if the ID in the notification is 
		for this folder.

CALLED BY:	(INTERNAL) FolderNotifyFileChangeLow

PASS:		*ds:si	= Folder object
		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData

RETURN:		carry set if close under way
		carry clear if ID wasn't for us

DESTROYED:	ax, bx, di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseIfIDIsOurs proc	near
		class	FolderClass
		.enter
		call	FolderCheckIDIsOurs
		jnc	done

		call	FolderSendCloseViaQueue
		stc
done:
		.leave
		ret
FolderCloseIfIDIsOurs		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckIDIsKids
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the affected file is one of our kiddies.

CALLED BY:	(INTERNAL) FolderNotifyFileChange

PASS:		*ds:si	= Folder object
		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData

RETURN:		carry set if it belongs to a kiddie:
			di	= offset of FolderRecord
		carry clear if it's none of ours:
			di	= destroyed
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/11/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckIDIsKids proc	near
		class	FolderClass
		uses	bx, cx, dx, bp, es, si
		.enter

		call	FolderFetchIDFromNotificationBlock

		mov	ax, SEGMENT_CS
		mov	bx, offset FolderCheckIDIsKidsCB
		call	FolderSendToDisplayList
		mov	di, cx		; FolderRecord offset

		.leave
		ret

FolderCheckIDIsKids endp

if OPEN_CLOSE_NOTIFICATION


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckIDIsKidsTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the affected file is the TARGET of one of the
		kids. 

CALLED BY:	(INTERNAL) FolderNotifyFileChange

PASS:		*ds:si	= Folder object
		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData

RETURN:		carry set if it belongs to a kiddie:
			di	= offset of FolderRecord
		carry clear if it's none of ours:
			di	= destroyed

DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	chrisb	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckIDIsKidsTarget	 proc	near
		class	FolderClass
		uses	bx, cx, dx, bp, es, si
		.enter

		call	FolderFetchIDFromNotificationBlock

		mov	bx, offset FolderCheckIDIsKidsTargetCB
		mov	ax, SEGMENT_CS
		call	FolderSendToDisplayList
		mov	di, cx		; FolderRecord offset

		.leave
		ret

FolderCheckIDIsKidsTarget endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckIDIsKidsTargetCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if this ID is a TARGET of one of the files in the
		folder buffer

CALLED BY:	FolderCheckIDIsKidsTarget via FolderSendToDisplayList

PASS:		cx:dx - ID
		bp - disk handle
		ds:di - FolderRecord

RETURN:		if found:
			carry set
			cx - offset to FolderRecord
		else
			carry clear
			cx - unchanged

DESTROYED:	bp,di,es,ax,bx,cx,dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/30/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckIDIsKidsTargetCB	proc far

	uses	ds
	.enter

	test	ds:[di].FR_fileAttrs, mask FA_LINK
	jz	done

	cmpdw	ds:[di].FR_targetFileID, cxdx
	clc
	jne	done

if 0



	;
	; It's almost certainly the one, but fetch the target's disk
	; handle as well, just to be sure.  Since we don't know what
	; directory we're in at the moment, we have to CD to the
	; folder's dir before calling the common routine.
	;
	call	FilePushDir
	push	di, ax
	movdw	bxsi, ds:[FBH_folder]
	mov	ax, MSG_FOLDER_SET_CUR_PATH
	clr	di
	call	ObjMessage
	pop	di, ax
	jc	afterFetch
	call	FolderGetFolderRecordTargetDisk	; bx - target disk

afterFetch:
	call	FilePopDir
	jc	doneCLC

		
	cmp	bx, bp
	jne	doneCLC

	mov	cx, di
	stc
	jmp	done
doneCLC:
	clc

else
	;
	; There are many links in Wizard that point to item files,
	; even though their target file IDs point to an app or
	; something.  To allow open/close notification to work, just
	; ignore the disk handle -- if the IDs match, we're close
	; enough!
	;

	mov	cx, di
	stc
endif


done:
	.leave
	ret
FolderCheckIDIsKidsTargetCB	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCheckIDIsKidsCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the folder record's ID matches the passed one

CALLED BY:	FolderCheckIDIsKids via FolderSendToDisplayList

PASS:		cx:dx - ID
		bp - disk handle
		ds:di - FolderRecord

RETURN:		carry SET if match:
			cx = offset to FolderRecord
		carr CLEAR otherwise (cx unchanged)

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCheckIDIsKidsCB	proc far


		cmp	ds:[di].FR_disk, bp
		jne	doneCLC
		cmp	ds:[di].FR_id.low, dx
		jne	doneCLC
		cmp	ds:[di].FR_id.high, cx
		jne	doneCLC

		stc
		mov	cx, di
		jmp	done
doneCLC:
		clc
done:
		ret

FolderCheckIDIsKidsCB	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateWastebasket
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update wastebasket empty/not-empty state

CALLED BY:	EXTERNAL
			file operations

PASS:		nothing

RETURN:		nothing
			sets wastebasketEmpty global

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       brianc	12/28/98   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if GPC_FULL_WASTEBASKET

idata	segment

wastebasketEmpty	BooleanByte	BB_TRUE

idata	ends

UpdateWastebasket	proc far
		uses	ax, bx, cx, dx, si, di, bp, es, ds
		.enter
	;
	; get count of files in wastebasket directory
	;
		call	FilePushDir
		mov	ax, SP_WASTE_BASKET
		call	FileSetStandardPath
		sub	sp, size FileEnumParams
		mov	bp, sp
		mov	ss:[bp].FEP_searchFlags, FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS
		mov	ss:[bp].FEP_returnAttrs.segment, 0
		mov	ss:[bp].FEP_returnAttrs.offset, FESRT_COUNT_ONLY
		mov	ss:[bp].FEP_returnSize, 0
		mov	ss:[bp].FEP_matchAttrs.segment, 0
		mov	ss:[bp].FEP_bufSize, 0
		mov	ss:[bp].FEP_skipCount, 0
		call	FileEnum		; dx = count
		jc	done			; error, leave alone
		cmp	dx, 1
		jne	notJustDirInfo
		push	dx
		segmov	ds, dgroup, dx
		mov	dx, offset dirinfoFilename
		call	FileGetAttributes
		pop	dx
		jc	notJustDirInfo		; not found
		dec	dx			; else, ignore dir info file
notJustDirInfo:
	;
	; set flag for empty or full wastebasket link
	;
		mov	bl, BB_TRUE
		tst	dx
		jz	haveState
		mov	bl, BB_FALSE
haveState:
		cmp	ss:[wastebasketEmpty], bl
		je	done
		mov	ss:[wastebasketEmpty], bl
	;
	; redraw desktop (first entry in folderTrackingTable)
	;
		movdw	bxsi, ss:[folderTrackingTable].FTE_folder
		tst	bx
		jz	done
		mov	ax, MSG_ND_DESKTOP_REDRAW_WASTEBASKET
		call	ObjMessageCall
done:
		call	FilePopDir		; preserves flags
		.leave
		ret
UpdateWastebasket	endp

;not used
;wastePath	TCHAR	"DESKTOP\\Waste",0
endif

FolderPathCode	ends
