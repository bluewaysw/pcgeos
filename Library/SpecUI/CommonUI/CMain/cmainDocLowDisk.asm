COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	
MODULE:		
FILE:		cmainDocLowDisk.asm

AUTHOR:		Adam de Boor, Jun  7, 1993

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	6/ 7/93		Initial revision


DESCRIPTION:
	Functions to cope with recovering from disk-full situations.
		

	$Id: cmainDocLowDisk.asm,v 1.1 97/04/07 10:51:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef NIKE_DUTCH
_NIKE_DUTCH = TRUE
else
_NIKE_DUTCH = FALSE
endif

ifdef NIKE_GERMAN
_NIKE_GERMAN = TRUE
else
_NIKE_GERMAN = FALSE
endif




DocDiskFull	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentShowLowDiskError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put up the dialog saying we're out of disk space and
		offering the user the chance to clean up.

CALLED BY:	(EXTERNAL) OLDocumentDetach
PASS:		*ds:si	= GenDocument object
		ax = message to send to ourself when we are done
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Setup required:
			1) duplicate resource
			2) replace \1 in MessageTextText with doc name
			3) replace \1 in DeleteDocTrigger's moniker with doc 
			   name
			4) replace \1 in MoveDocTrigger's moniker with doc
			   name
			5) change to be run by same thread as app obj
			6) attach dialog as child of app
			7) set moniker for box to match app's text moniker
			8) initiate interaction
			9) add document object to filesystem change list
			10) set file selector for deleting to be in same dir
			    as document
			11) initialize free space display

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentShowLowDiskError proc	far
		uses	si, es
		.enter
	;
	; Save the response message
	;
		push	ax
		mov	ax, TEMP_OL_DOCUMENT_NO_DISK_SPACE_MESSAGE
		mov	cx, size word
		call	ObjVarAddData
		pop	ds:[bx]

	;
	; Make a copy of our beloved resource.
	; 
		mov	bx, handle LowDiskUI
;		clr	ax		; owned by current process
		mov	ax, handle ui	; owned by global UI thread
					;	(see below)
		clr	cx		; run by current thread (for now)
		call	ObjDuplicateResource

		mov	di, ds:[si]
		add	di, ds:[di].OLDocument_offset
		mov	ds:[di].OLDI_saveErrorRes, bx
	;
	; Lock down the duplicate so we can mangle it in various ways.
	; 
		mov	di, ds:[si]
		add	di, ds:[di].GenDocument_offset
		lea	dx, ds:[di].GDI_fileName	; ds:dx <- doc name
if HANDLE_DISK_FULL_ON_SAVE_AS
		push	bx				; save ui block
		mov	ax, TEMP_OL_DOCUMENT_SAVE_AS_DISK_FULL
		call	ObjVarFindData
		jnc	haveDocName
		lea	dx, ds:[bx].DCP_name		; ds:dx = save as name
haveDocName:
		pop	bx				; bx = ui block
endif
		push	si, bx
		call	ObjLockObjBlock
		mov	es, ax
		mov	bx, ds:[LMBH_handle]
	;
	; Change the obj block's output to the document object.
	; 
		push	ds
		mov	ds, ax
		call	ObjBlockSetOutput
		pop	ds
	;
	; Replace \1 with the document name in the three relevant places.
	; 
		push	si			; save GenDocument chunk

		mov	si, offset MessageTextText
		clr	bx			; look for \1 from start
		call	OLDocInsertDocName

if not NO_LOW_DISK_DELETE_CURRENT
		mov	si, offset DeleteDocMoniker
		mov	bx, offset VM_data.VMT_text ; look for \1 in mkr text
		call	OLDocInsertDocName
if _NIKE_GERMAN or _NIKE_DUTCH
		mov     bx, es:[si]             ; es:bx = VisMoniker
                mov     es:[bx].VM_width, 0     ; recompute moniker
						; width
endif
endif
		
if not NO_LOW_DISK_MOVE
		mov	si, offset MoveDocMoniker
		mov	bx, offset VM_data.VMT_text ; look for \1 in mkr text
		call	OLDocInsertDocName
if _NIKE_GERMAN or _NIKE_DUTCH
		mov     bx, es:[si]             ; es:bx = VisMoniker
                mov     es:[bx].VM_width, 0     ; recompute moniker
						; width
endif
endif

		pop	si			; restore GenDocument chunk
	;
	; Fetch the text moniker for the app object.
	; 
		mov	bp, (VMS_TEXT shl offset VMSF_STYLE)
		stc				;check app's moniker list
		call	GenFindMoniker	; ^lcx:dx <- moniker
	;
	; Copy it into the object block, calling the thread that runs the
	; application object to perform the copy while we remain blocked.
	; 
if 0
		clr	bx
		call	GeodeGetAppObject
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
		mov_tr	bx, ax			; bx <- thread to call

	CheckHack <size CopyChunkOutFrame eq 10>
	CheckHack <offset CCOF_dest eq 6 and size CCOF_dest eq 4>
	CheckHack <offset CCOF_source eq 2 and size CCOF_source eq 4>
	CheckHack <offset CCOF_copyFlags eq 0 and size CCOF_copyFlags eq 2>
		mov	ax, CCM_OPTR shl offset CCF_MODE
		push	es:[LMBH_handle], si, 	; CCOF_dest
			cx, dx,			; CCOF_source
			ax			; CCOF_copyFlags
		mov	bp, sp
		mov	dx, size CopyChunkOutFrame
		mov	di, mask MF_CALL or mask MF_FIXUP_DS or \
				mask MF_FIXUP_ES or mask MF_STACK
		mov	ax, MSG_PROCESS_COPY_CHUNK_OUT
		call	ObjMessage		; ax <- new chunk
		add	sp, size CopyChunkOutFrame
else
	;
	; the above only works for single threaded apps, copy into temporary
	; global block instead - brianc 7/6/93
	;	^lcx:dx = moniker to copy into object block
	;	es:[LMBH_handle] = object block
	;
	CheckHack <size CopyChunkOutFrame eq 10>
	CheckHack <offset CCOF_dest eq 6 and size CCOF_dest eq 4>
	CheckHack <offset CCOF_source eq 2 and size CCOF_source eq 4>
	CheckHack <offset CCOF_copyFlags eq 0 and size CCOF_copyFlags eq 2>
		mov	ax, CCM_HPTR shl offset CCF_MODE
		push	ax, ax, 		; CCOF_dest (not used)
			cx, dx,			; CCOF_source
			ax			; CCOF_copyFlags
		mov	bp, sp
		mov	dx, size CopyChunkOutFrame
		call	UserHaveProcessCopyChunkOut	; ax = block, cx = size
		add	sp, size CopyChunkOutFrame
		push	ax			; save block handle
EC <		push	cx			; save size		>
	CheckHack <size CopyChunkInFrame eq 8>
	CheckHack <offset CCIF_destBlock eq 6 and size CCIF_destBlock eq 2>
	CheckHack <offset CCIF_source eq 2 and size CCIF_source eq 4>
	CheckHack <offset CCIF_copyFlags eq 0 and size CCIF_copyFlags eq 2>
		mov	dx, 0
		ornf	cx, CCM_HPTR shl offset CCF_MODE	; size + flags
		push	es:[LMBH_handle],	; CCIF_destBlock
			ax, dx,			; CCIF_source
			cx			; CCIF_copyFlags
		mov	bp, sp
		mov	dx, size CopyChunkInFrame
		call	UserHaveProcessCopyChunkIn	; ax = chunk, cx = size
		add	sp, size CopyChunkInFrame
EC <		pop	bx			; verify size		>
EC <		cmp	bx, cx						>
EC <		ERROR_NE	OL_ERROR				>
		pop	bx
		call	MemFree			; free temp block
endif
		mov_tr	cx, ax			; cx = chunk

	;
	; Make dialog have the same moniker.
	; 
		pop	bx
		mov	si, offset LowDiskBox
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	dl, VUM_MANUAL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		pop	si
		call	MemUnlock
	;
	; Change the block to be run by the ui's app object's thread.
	; 
		push	bx, si
		mov	bx, handle ui
		call	GeodeGetAppObject
		mov	ax, MGIT_EXEC_THREAD
		call	MemGetInfo
		movdw	cxdx, bxsi
		pop	bx, si
		call	MemModifyOtherInfo

;done at ObjDuplicateResource call so we get added to correct process' saved
;block list - brianc 7/22/93
;		;
;		; change owner to be global UI thread
;		; so queue flushing will be happy (block is run by global
;		; UI thread) - brianc 7/20/93
;		;
;		mov	ax, handle ui
;		call	HandleModifyOwner

	;
	; Add the root as the first child of the application object.
	; 
		push	si
		xchg	bx, cx			; ^lbx:si <- ui app obj
		mov	si, dx
		mov	dx, offset LowDiskBox	; ^lcx:dx <- dialog
		mov	ax, MSG_GEN_ADD_CHILD_UPWARD_LINK_ONLY
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
	;
	; Bring it up on-screen & beep.
	; 
		movdw	bxsi, cxdx
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_MANUAL
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, MSG_GEN_INTERACTION_INITIATE
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		mov	ax, SST_ERROR
		call	UserStandardSound
		pop	si
	;
	; Add the document object to the filesystem change list so we know to
	; retry the save when something gets deleted.
	; 
		push	bx
		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_FILE_SYSTEM
		call	GCNListAdd
		pop	bx
	;
	; Set the path of the file selector to match that of the document.
	; 
		mov	di, offset DeleteFilesFS	; ^lbx:di <- fsel
		call	OLDCCopyPathToFS
		
if not NO_LOW_DISK_MOVE
		mov	di, offset MoveFileFS		; ^lbx:di <- fsel
		call	OLDCCopyPathToFS
endif
	;
	; Update the free-space display for that disk.
	; 
		call	OLDocUpdateFreeSpaceDisplay
		.leave
		ret
OLDocumentShowLowDiskError endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocInsertDocName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace a single \1 in a text string with the name of
		the current document.

CALLED BY:	(INTERNAL) OLDocumentShowLowDiskError
PASS:		ds:dx	= document filename
		*es:si	= chunk in which to search
		bx	= offset within chunk from which to start search
RETURN:		nothing
DESTROYED:	ax, bx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLDocInsertDocName proc	near
		uses	cx, si
		.enter
	;
	; Find the length of the text in the filename.
	; 
		push	es
		segmov	es, ds
		mov	di, dx
		LocalClrChar	ax
		mov	cx, -1
		LocalFindChar
		not	cx
		dec	cx		; cx <- length w/o null
		pop	es

		push	cx
	;
	; Locate the \1 in the string.
	; 
		mov	di, es:[si]
		inc	ax		; al <- 1 (1-char inst)

		ChunkSizePtr es, di, cx
		add	di, bx
		sub	cx, bx
DBCS<		shr	cx, 1		; #bytes -> #chars		>
		
		LocalFindChar

		pop	cx		; cx <- length of file name
		jne	done		; => no \1, so nothing to insert
	;
	; Insert enough room there in the string for the file name
	; 
		push	ds
		segmov	ds, es
		LocalPrevChar	esdi	; point to \1
		sub	di, ds:[si]	; figure offset from base of chunk
					;  for insertion
		mov	bx, di
		mov	ax, si
		dec	cx		; reduce by 1 char to account for
					;  overwriting \1
DBCS <		shl	cx, 1		; #chars -> #bytes		>
		call	LMemInsertAt
		pop	ds
	;
	; Now copy the text from the file name into the string
	; 
		mov	di, bx		; di <- offset
		add	di, es:[si]	; es:di <- insertion point

		push	si
		mov	si, dx		; ds:si <- filename
DBCS <		shr	cx, 1		; #bytes -> #chars		>
		inc	cx		; account for previous reduction
		LocalCopyNString
		pop	si
done:
		.leave
		ret
OLDocInsertDocName endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocUpdateFreeSpaceDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the number of bytes free on the drive to which the
		file selector for deleting things is set

CALLED BY:	(INTERNAL)
PASS:		*ds:si	= document object
RETURN:		nothing
DESTROYED:	ax, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocUpdateFreeSpaceDisplay proc near
		uses	bx, si, di, bp, es
		.enter
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].OLDocument_offset
		mov	bx, ds:[di].OLDI_saveErrorRes
		mov	si, offset DeleteFilesFS
		mov	ax, MSG_GEN_PATH_GET_DISK_HANDLE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx <- disk handle
		pop	si

		push	bx

		push	cx
		mov	ax, TEMP_OL_DOCUMENT_FREE_SPACE_DRIVE
		mov	cx, size word
		call	ObjVarAddData
		pop	cx
		mov	ds:[bx], cx
		test	cx, DISK_IS_STD_PATH_MASK
		jz	notStdPath		; not std path
		mov	ax, SGIT_SYSTEM_DISK	; else, use system disk
		call	SysGetInfo
		mov	ds:[bx], ax
notStdPath:

		mov	bx, cx
		call	DiskGetVolumeFreeSpace
		pop	bx
		jnc	haveSpace
		clrdw	dxax

haveSpace:
		sub	sp, UHTA_NULL_TERM_BUFFER_SIZE
		mov	cx, mask UHTAF_NULL_TERMINATE
		segmov	es, ss
		mov	di, sp
		call	UtilHex32ToAscii

		mov	dx, ss
		mov	bp, sp
		clr	cx		; null-terminated
		mov	si, offset DeleteFilesFreeSpace
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		add	sp, UHTA_NULL_TERM_BUFFER_SIZE
		.leave
		ret
OLDocUpdateFreeSpaceDisplay endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to save the file again if change is deletion.

CALLED BY:	MSG_NOTIFY_FILE_CHANGE
PASS:		dx	= FileChangeNotificationType
		bp	= FileChangeNotificationData block
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocNotifyFileChange method dynamic OLDocumentClass, MSG_NOTIFY_FILE_CHANGE
		push	dx, bp

		call	OLDocMarkBusy
		;
		; check for flag
		;
		mov	ax, TEMP_OL_DOCUMENT_DISK_FULL_RESOLVED
		call	ObjVarFindData
		LONG jc	passItOnNoUpdate	; don't delete, no need for more
						;	MSG_NOTIFY_FILE_CHANGEs
						;	(removed when OLDoc
						;	destoryed)

		clr	cx
		call	OLDocLookForDelete
		jnc	passItOn
		push	cx
if HANDLE_DISK_FULL_ON_SAVE_AS
		mov	ax, TEMP_OL_DOCUMENT_SAVE_AS_DISK_FULL
		call	ObjVarFindData
		jnc	notSaveAs
		mov	dx, bx			; save data
		mov	ax, TEMP_OL_DOCUMENT_IGNORE_NEXT_DELETE
		call	ObjVarFindData
		jnc	trySaveAsAgain
		call	ObjVarDeleteDataAt
		stc				; simulate error
		jmp	short checkIfSuccessful

trySaveAsAgain:
		mov	bx, dx			; ds:bx = save as data
		mov	dx, size DocumentCommonParams
		sub	sp, dx
		mov	di, sp
		push	es, si
		segmov	es, ss			; es:di = dest
		mov	si, bx			; ds:si = source
		mov	cx, dx			; cx = size
		rep	movsb
		pop	es, si			; *ds:si = OLDocument
		mov	bp, sp			; ss:bp = DocumentCommonParams
		mov	ax, MSG_GEN_DOCUMENT_SAVE_AS
		call	ObjCallInstanceNoLock
						; preserve flags
		lea	sp, ss:[bp][size DocumentCommonParams]
		jnc	checkIfSuccessful
		;
		; if we failed the SAVE_AS, a delete notification will be
		; coming in for the save-as file.  We want to ignore that,
		; otherwise, we'll keep looping here.  There is a chance
		; that we'll ignore a delete from some other thread, but
		; the right thing (stop retrying SAVE_AS) will eventually
		; happen.
		;
		mov	ax, TEMP_OL_DOCUMENT_IGNORE_NEXT_DELETE
		clr	cx
		call	ObjVarAddData
		stc				; indicate error in SAVE_AS
		jmp	short checkIfSuccessful

notSaveAs:
endif
		call	OLDocumentSaveOrUpdate
checkIfSuccessful::
		pop	cx
		jnc	takeDownBoxes
passItOn:
		jcxz	passItOnNoUpdate
		call	OLDocUpdateFreeSpaceDisplay
passItOnNoUpdate:
		pop	dx, bp
		mov	ax, MSG_NOTIFY_FILE_CHANGE
		mov	di, offset OLDocumentClass
		call	ObjCallSuperNoLock

		call	OLDocMarkNotBusy
		ret

takeDownBoxes:
		mov	ax, TEMP_OL_DOCUMENT_NO_DISK_SPACE_MESSAGE
		call	ObjVarFindData
EC <		ERROR_NC OL_ERROR					>
		cmp	{word} ds:[bx], MSG_META_ACK
		jz	detaching
if HANDLE_DISK_FULL_ON_SAVE_AS
		cmp	{word} ds:[bx], MSG_OL_DOCUMENT_CONTINUE_SAVE_AS_AFTER_DISK_FULL
		je	detaching
endif

	; we're closing the file

		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		andnf	ds:[di].GDI_attrs, not mask GDA_CLOSING
		clr	bp
		mov	ax, MSG_GEN_DOCUMENT_CLOSE
		call	ObjCallInstanceNoLock

detaching:
		call	OLDocFinishSaveError
		jmp	passItOnNoUpdate

OLDocNotifyFileChange endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocFinishSaveError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the necessary clean up after save error has been
		resolved, one way or another.

CALLED BY:	(INTERNAL) OLDocNotifyFileChange, 
			   OLDocumentDeleteAfterSaveError
PASS:		*ds:si	= document object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp
SIDE EFFECTS:	removed from FCN list and a message is queued. Doc must
     		continue to exist for a queue delay

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocFinishSaveError proc near
		.enter

		;
		; add flag
		;
		mov	ax, TEMP_OL_DOCUMENT_DISK_FULL_RESOLVED
		mov	cx, 0
		call	ObjVarAddData

		mov	cx, ds:[LMBH_handle]
		mov	dx, si
		mov	bx, MANUFACTURER_ID_GEOWORKS
		mov	ax, GCNSLT_FILE_SYSTEM
		call	GCNListRemove

		mov	ax, MSG_OL_DOCUMENT_SAVE_ERROR_RESOLVED
		mov	bx, cx
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		.leave
		ret
OLDocFinishSaveError endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocLookForDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the notification to see if it involves deleting
		anything, or anything that would affect the free space
		on the disk.

CALLED BY:	(INTERNAL) OLDocNotifyFileChange
PASS:		dx	= FileChangeNotificationType
		^hbp	= FileChangeNotificationData
RETURN:		carry set if anything deleted
		cx	= non-zero if any disk space change
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocLookForDelete proc	near
		uses	es, dx, bp
		.enter
		mov	bx, bp
		call	MemLock
		mov	es, ax
		clr	di
		call	OLDocLookForDeleteLow
		call	MemUnlock
		mov	ax, cx
		clr	ch		; cx <- non-zero if space change
		sahf			; CF <- 1 if delete
		.leave
		ret
OLDocLookForDelete endp

OLDocLookForDeleteLow proc near
		class	OLDocumentClass
		uses	bx
		.enter
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
	notifyUnread,			; FCNT_FILE_UNREAD
	notifyRead			; FCNT_FILE_READ
.assert ($-notificationTable)/2 eq FileChangeNotificationType

notifyDelete:
		ornf	ch, mask CPU_CARRY	; something deleted
notifyContents:
notifyCreate:
		ornf	cl, 1			; disk-space change
		retn

notifySPAdd:
notifySPDelete:
notifyFormat:
notifyRename:
notifyOpen:
notifyClose:
notifyAttributes:
notifyUnread:
notifyRead:
		retn

	;--------------------
notifyBatch:
	;
	; Process the batch o' notifications one at a time.
	; 
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
		call	OLDocLookForDeleteLow
		pop	di, dx
	;
	; Advance pointer, accounting to variable-sized nature of the thing.
	; 
		add	di, size FileChangeBatchNotificationItem
	CheckHack <FCNT_CREATE eq 0 and FCNT_RENAME eq 1>
		cmp	dx, FCNT_RENAME
		ja	batchLoop		; => no name
		add	di, size FileLongName
		jmp	batchLoop
batchLoopDone:
		retn
OLDocLookForDeleteLow endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocSaveErrorResolved
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish up this whole mess of resolving a save error at
		detach time.

CALLED BY:	MSG_OL_DOCUMENT_SAVE_ERROR_RESOLVED
PASS:		*ds:si	= document object
		ds:di	= OLDocumentInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	MSG_META_ACK is called on ourselves
     		OLDI_saveErrorRes is cleared

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocSaveErrorResolved method dynamic OLDocumentClass,
				MSG_OL_DOCUMENT_SAVE_ERROR_RESOLVED
		.enter
	;
	; Bring down and destroy the block holding the dialog box.
	; 
		clr	bx
		xchg	bx, ds:[di].OLDI_saveErrorRes
		push	si
		mov	si, offset LowDiskBox
		mov	ax, MSG_GEN_DESTROY_AND_FREE_BLOCK
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	si
		
	;
	; Send ourselves the final message needed (either a MSG_ACK to
	; continue the app's detaching or CLOSE to continue closing)
	; 
		mov	ax, TEMP_OL_DOCUMENT_NO_DISK_SPACE_MESSAGE
		call	ObjVarFindData
EC <		ERROR_NC OL_ERROR					>
		push	ds:[bx]
		call	ObjVarDeleteData
		pop	ax

		call	ObjCallInstanceNoLock
		
		.leave
		ret
OLDocSaveErrorResolved endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocDeleteSelectedFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempt to delete the file selected in the file selector

CALLED BY:	MSG_OL_DOCUMENT_DELETE_SELECTED_FILE
PASS:		*ds:si	= OLDocument
		ds:di	= OLDocumentInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	File may be deleted & FCN sent. Receipt of the FCN causes
     		another attempt at saving the document and possibly the removal
		of the box.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocDeleteSelectedFile method dynamic OLDocumentClass, MSG_OL_DOCUMENT_DELETE_SELECTED_FILE
pathName	local	PathName
		.enter
		mov	bx, ds:[di].OLDI_saveErrorRes
		mov	si, offset DeleteFilesFS
		mov	cx, ss
		lea	dx, ss:[pathName]
		push	bp
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_FULL_SELECTION_PATH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		mov	bx, bp
		pop	bp
			CheckHack <GFSET_FILE eq 0>
		test	bx, mask GFSEF_TYPE
		jnz	done

	;
	; Change to the root of the thing's disk.
	; 
		call	FilePushDir
		mov_tr	bx, ax
		push	ds
		segmov	ds, cs
		mov	dx, offset rootPath
		call	FileSetCurrentPath
	;
	; Now delete the S.O.B.
	; 
		segmov	ds, ss
		lea	dx, ss:[pathName]
		call	FileDelete
		pop	ds
		jnc	donePopDir
	;
	; For now, just honk. Perhaps we should have a text object for
	; displaying an error message?
	; 
		mov	ax, SST_ERROR
		call	UserStandardSound
donePopDir:
		call	FilePopDir
done:
		.leave
		ret
rootPath	char	'\\', 0
OLDocDeleteSelectedFile endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocDeleteFilesFSNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	if changed drives, update free space

CALLED BY:	MSG_OL_DOCUMENT_DELETE_FILES_FS_NOTIFY

PASS:		*ds:si	= OLDocumentClass object
		ds:di	= OLDocumentClass instance data
		es 	= segment of OLDocumentClass
		ax	= MSG_OL_DOCUMENT_DELETE_FILES_FS_NOTIFY

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocDeleteFilesFSNotify	method	dynamic	OLDocumentClass, MSG_OL_DOCUMENT_DELETE_FILES_FS_NOTIFY
		push	si
		mov	di, ds:[si]
		add	di, ds:[di].OLDocument_offset
		mov	bx, ds:[di].OLDI_saveErrorRes
		mov	si, offset DeleteFilesFS
		mov	ax, MSG_GEN_PATH_GET_DISK_HANDLE
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage		; cx <- disk handle
		pop	si
		test	cx, DISK_IS_STD_PATH_MASK
		jz	notStdPath		; not std path
		mov	ax, SGIT_SYSTEM_DISK	; else, use system disk
		call	SysGetInfo
		mov	cx, ax
notStdPath:

		mov	ax, TEMP_OL_DOCUMENT_FREE_SPACE_DRIVE
		call	ObjVarFindData
		jnc	update
		cmp	ds:[bx], cx		; already have it?
		je	done			; yes, don't do it again
update:
		call	OLDocUpdateFreeSpaceDisplay
done:
		ret
OLDocDeleteFilesFSNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentDeleteAfterSaveError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has decided to just biff the document, rather than
		struggle on any further.

CALLED BY:	MSG_OL_DOCUMENT_DELETE_AFTER_SAVE_ERROR
PASS:		*ds:si	= document
		ds:di	= OLDocumentInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not NO_LOW_DISK_DELETE_CURRENT
OLDocumentDeleteAfterSaveError method dynamic OLDocumentClass, 
					MSG_OL_DOCUMENT_DELETE_AFTER_SAVE_ERROR
		.enter
		;
		; if we have already finished, don't bother with trying again
		; - brianc 1/25/94
		;
		mov	ax, TEMP_OL_DOCUMENT_DISK_FULL_RESOLVED
		call	ObjVarFindData
		jc	done
		call	OLDocFinishSaveError
		mov	cx, TRUE		; delete doc
		call	OLDocDestroyDocument
done:
		.leave
		ret
OLDocumentDeleteAfterSaveError		endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocumentRevertAfterSaveError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	User has decided to just discard changes, rather than
		struggle on any further.

CALLED BY:	MSG_OL_DOCUMENT_REVERT_AFTER_SAVE_ERROR
PASS:		*ds:si	= document
		ds:di	= OLDocumentInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OLDocumentRevertAfterSaveError method dynamic OLDocumentClass, 
					MSG_OL_DOCUMENT_REVERT_AFTER_SAVE_ERROR
		.enter
		;
		; if we have already finished, don't bother with trying again
		; - brianc 1/25/94
		;
		mov	ax, TEMP_OL_DOCUMENT_DISK_FULL_RESOLVED
		call	ObjVarFindData
		jc	done
	;
	; signal that document needs to be reverted before being closed
	;
		mov	di, ds:[si]
		add	di, ds:[di].OLDocument_offset
		ornf	ds:[di].OLDI_attrs, mask OLDA_REVERT_BEFORE_CLOSE

		call	OLDocFinishSaveError
		clr	cx		; don't delete doc
		call	OLDocDestroyDocument
done:
		.leave
		ret
OLDocumentRevertAfterSaveError		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocMoveAfterErrorFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the dialog box to reflect the destination of the move.

CALLED BY:	MSG_OL_DOCUMENT_MOVE_AFTER_ERROR_FEEDBACK
PASS:		*ds:si	= document object
		cx	= entry #
		bp	= GenFileSelectorEntryFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not NO_LOW_DISK_MOVE
OLDocMoveAfterErrorFeedback method dynamic OLDocumentClass,
			    	MSG_OL_DOCUMENT_MOVE_AFTER_ERROR_FEEDBACK
		.enter
		test	bp, mask GFSEF_ERROR
		jnz	done
		
		mov	bx, ds:[di].OLDI_saveErrorRes
		mov	cx, offset MoveFileFS
		mov	dx, offset MoveFileDestText
		call	SetDirText		; cmainUIDocOperations.asm

done:
		.leave
		ret
OLDocMoveAfterErrorFeedback endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLDocMoveAfterSaveError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the document someplace else to clear up the save
		error.

CALLED BY:	MSG_OL_DOCUMENT_MOVE_AFTER_SAVE_ERROR
PASS:		*ds:si	= document object
		ds:di	= OLDocumentInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Unfortunately, we can't use the handy GetPathFromFileSelector
		because that expects either to have a file, or to have a
		text object with a name, and we use our own name, instead.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/ 8/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not NO_LOW_DISK_MOVE
OLDocMoveAfterSaveError		method dynamic OLDocumentClass, MSG_OL_DOCUMENT_MOVE_AFTER_SAVE_ERROR
		.enter
		sub	sp, size DocumentCommonParams
		mov	bp, sp
	;
	; Fetch the destination directory from the file selector.
	; 
		push	bp, si
		mov	dx, ss
		add	bp, offset DCP_path
		mov	cx, size DCP_path
		mov	bx, ds:[di].OLDI_saveErrorRes
		mov	si, offset MoveFileFS
		mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	bp, si
		mov	ss:[bp].DCP_diskHandle, cx
	;
	; Fetch the filename from our instance data.
	; 
		push	si
		mov	si, ds:[si]
		add	si, ds:[si].GenDocument_offset
		add	si, offset GDI_fileName
		segmov	es, ss
		lea	di, ss:[bp].DCP_name
		mov	cx, size GDI_fileName
		rep	movsb
		pop	si
	;
	; No special behaviour for anything else. If the destination
	; already exists, the app object should fail the dialog request and
	; we just receive an error back...
	; 
		mov	ss:[bp].DCP_connection, 0
		mov	ss:[bp].DCP_docAttrs, 0
		mov	ss:[bp].DCP_flags, 0
		
		;
		; clear GDA_CLOSING so SAVE_AS doesn't close and destroy
		; document, we do that ourselves, below
		;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		andnf	ds:[di].GDI_attrs, not mask GDA_CLOSING

		mov	ax, MSG_GEN_DOCUMENT_SAVE_AS
		mov	dx, size DocumentCommonParams
		call	ObjCallInstanceNoLock

		jnc	resolution
		
		mov	ax, SST_ERROR
		call	UserStandardSound
done:
		add	sp, size DocumentCommonParams		
		.leave
		ret

resolution:
		call	OLDocFinishSaveError
		clr	cx		; don't delete doc, as it's the new
					;  save-as'ed one.
		call	OLDocDestroyDocument
		jmp	done
OLDocMoveAfterSaveError endm
endif



DocDiskFull	ends

