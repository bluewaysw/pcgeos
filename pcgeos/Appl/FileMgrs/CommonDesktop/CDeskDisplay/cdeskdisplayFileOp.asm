COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		deskdisplayFileOp.asm

AUTHOR:		Adam de Boor, Jan 30, 1992

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1/30/92		Initial revision


DESCRIPTION:
	Implementation of FileOpActiveBoxClass, FileOpFileListClass, and
	FileOperationBoxClass
		

	$Id: cdeskdisplayFileOp.asm,v 1.1 97/04/04 15:03:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


;-----------------------------------------------------------------------------



FileOperation segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpAppActiveBoxInitiate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	mark application as active

CALLED BY:	MSG_GEN_INTERACTION_INITIATE

PASS:		ds:*si - FileOpAppActiveBox instance

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpAppActiveBoxInitiate	method	FileOpAppActiveBoxClass,
						MSG_GEN_INTERACTION_INITIATE
	;
	; mark desktop as active
	;
	push	ds:[LMBH_handle]
	mov	ax, ACTIVE_TYPE_FILE_OPERATION
	call	DesktopMarkActive			; destroys nothing
	call	MemDerefStackDS
	;
	; call superclass to do the initiate
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	es:[hackModalBoxUp], TRUE	; file-op-active-app box will
	pop	es
						;	be put up
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, offset FileOpAppActiveBoxClass
	call	ObjCallSuperNoLock
	ret
FileOpAppActiveBoxInitiate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpAppActiveBoxDismiss
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	mark application as not active

CALLED BY:	MSG_GEN_GUP_INTERACTION_COMMAND

PASS:		ds:*si - FileOpAppActiveBox instance
		cx - InteractionCommand

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpAppActiveBoxDismiss	method	FileOpAppActiveBoxClass,
						MSG_GEN_GUP_INTERACTION_COMMAND
	cmp	cx, IC_DISMISS
	jne	callSuper
	;
	; mark desktop as not active
	;
	push	ds:[LMBH_handle]
	call	MarkNotActive			; destroys nothing
	call	MemDerefStackDS
	;
	; call superclass to do the dismiss
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	es:[hackModalBoxUp], FALSE	; file-op-active-app box will
						;	be taken down
	pop	es

callSuper:
	mov	di, offset FileOpAppActiveBoxClass
	call	ObjCallSuperNoLock
	ret
FileOpAppActiveBoxDismiss	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpFileListSetFiles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	use new filelist in File Operation File List object

CALLED BY:	MSG_SET_FILE_LIST

PASS:		ds:si - object instance handle
		ax - MSG_SET_FILE_LIST
		es - segment of FileOpFileListClass

		dx - handle of FileQuickTransfer block


RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpFileListSetFileList	method FileOpFileListClass,
					MSG_SET_FILE_LIST
	clr	bx
	xchg	bx, ds:[di].FOFL_buffer		; get last buffer
	tst	bx				; any buffer?
	jz	noBuffer			; no
	call	MemFree				; free last buffer
noBuffer:
	mov	ds:[di].FOFL_buffer, dx		; store buffer handle
	mov	bx, dx
	call	MemLock
	mov	es, ax
	mov	ax, es:[FQTH_numFiles]
	mov	ds:[di].FOFL_count, ax		; store file count
	call	MemUnlock
	mov	ds:[di].FOFL_current, 0		; init current entry
	call	ShowFileListEntry		; show it
	ret
FileOpFileListSetFileList	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpFileListShowNextFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance to the next file in the list of files to be
		processed, displaying its name in ourselves.

CALLED BY:	MSG_SHOW_NEXT_FILE
PASS:		*ds:si	= FileOpFileList object
RETURN:		carry set if no next file to show
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpFileListShowNextFile	method FileOpFileListClass,
						MSG_SHOW_NEXT_FILE
	cmp	ds:[di].FOFL_buffer, 0		; any filelist?
	stc					; assume no files
	jz	done				; no, do nothing
	mov	ax, ds:[di].FOFL_current	; get current entry
	inc	ax				; bump current entry
	cmp	ax, ds:[di].FOFL_count		; was it the last one?
	jne	notLast				; if not, return new current

	;
	; requested next file when current file was last, free file list
	;
	clr	bx				; zero buffer handle
	xchg	bx, ds:[di].FOFL_buffer
	call	MemFree				; free it
	mov	ds:[di].FOFL_count, 0
	mov	ds:[di].FOFL_current, 0
NOFXIP<	mov	dx, cs				; dx:bp = null text	>
NOFXIP<	mov	bp, offset nullFileList					>
FXIP<	mov	dx, C_SPACE						>
FXIP<	push	dx				; use stack		>
FXIP<	mov	dx, ss							>
FXIP<	mov	bp, sp							>
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null-terminated
	call	ObjCallInstanceNoLock
FXIP<	pop	cx				; reset stack		>
	stc
	jmp	short done
notLast:
	mov	ds:[di].FOFL_current, ax	; save new current entry
	call	ShowFileListEntry		; show it
	clc
done:
	ret
FileOpFileListShowNextFile	endm

if not _FXIP
LocalDefNLString nullFileList <' ', 0>
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpFileListGetCurrentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the block and description of the current file
		to be processed.

CALLED BY:	MSG_GET_CURRENT_FILE
PASS:		*ds:si	= FileOpFileList object
RETURN:		carry set if no more files to process
		carry clear if at least one left:
			^hcx:dx	= FileOperationInfoEntry 
			^hcx:0	= FileQuickTransferHeader
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version
	ardeb	2/25/92		changed to return block & offset, rather
				than copying out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpFileListGetCurrentFile	method FileOpFileListClass,
						MSG_GET_CURRENT_FILE
	mov	cx, ds:[di].FOFL_buffer
	stc
	jcxz	done

	;
	; Have a buffer, so figure the location of the current entry, being
	; that many * size FileOperationInfoEntry bytes beyond FQTH_files...
	; 
	mov	ax, ds:[di].FOFL_current
	mov	dx, size FileOperationInfoEntry
	mul	dx
	add	ax, offset FQTH_files
	mov_tr	dx, ax			; ^hcx:dx <- FileOperationInfoEntry

	clc				; signal success
done:
	ret
FileOpFileListGetCurrentFile	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpFileListClearFileList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear out the list of files for this object. Used when the
		operation is canceled...

CALLED BY:	MSG_CLEAR_FILE_LIST
PASS:		*ds:si	= FileOpFileList object
		ds:di	= FileOpFileInstInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version
	ardeb	2/25/92		new filesystem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpFileListClearFileList	method FileOpFileListClass,
						MSG_CLEAR_FILE_LIST
	mov	ds:[di].FOFL_count, 0
	mov	ds:[di].FOFL_current, 0
	clr	bx
	xchg	bx, ds:[di].FOFL_buffer
	tst	bx
	jz	done
	call	MemFree
done:
	ret
FileOpFileListClearFileList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpFileListClearFileListViaProcess
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a MSG_CLEAR_FILE_LIST via the process queue.

CALLED BY:	MSG_CLEAR_FILE_LIST_VIA_PROCESS

PASS:		*ds:si	= FileOpFileList object
		ds:di	= FileOpFileList instance data
		es 	= segment of FileOpFileList
		ax	= MSG_CLEAR_FILE_LIST_VIA_PROCESS

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/22/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpFileListClearFileListViaProcess	method	dynamic	FileOpFileListClass,
						MSG_CLEAR_FILE_LIST_VIA_PROCESS
	;
	; record a MSG_CLEAR_FILE_LIST event
	;
	mov	ax, MSG_CLEAR_FILE_LIST
	mov	bx, ds:[LMBH_handle]		; send to ourselves
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event
	;
	; deliver via process thread
	;
	mov	cx, di
	mov	dx, ds:[LMBH_handle]		; block owned by process
	mov	bp, OFIQNS_PROCESS_OF_OWNING_GEODE
	mov	ax, MSG_META_OBJ_FLUSH_INPUT_QUEUE
	GOTO	ObjCallInstanceNoLock

FileOpFileListClearFileListViaProcess	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOpFileListGetNumFilesLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the number of files left to be processed.

CALLED BY:	MSG_GET_NUM_FILES_LEFT
PASS:		*ds:si	= FileOpFileList object
		ds:di	= FileOpFileInstInstance
RETURN:		cx	= # files left to process
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version
	ardeb	2/25/92		new filesystem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpFileListGetNumFilesLeft	method	FileOpFileListClass,
						MSG_GET_NUM_FILES_LEFT
	mov	cx, ds:[di].FOFL_count
	sub	cx, ds:[di].FOFL_current	; cx = files remaining
	ret
FileOpFileListGetNumFilesLeft	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShowFileListEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update our superclass with the name of the file being
		processed.

CALLED BY:	INTERNAL
       		(FileOpFileListShowNextFile, FileOpFileListSetFileList)
PASS:		*ds:si	= FileOpFileList object
		ds:di	= FileOpFileListInstance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version
	ardeb	2/25/92		new filesystem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShowFileListEntry	proc	near
	class	FileOpFileListClass
	;
	; get the current entry
	;
	call	FileOpFileListGetCurrentFile
	mov	bx, cx
	call	MemLock
	mov	bp, dx
	mov	dx, ax
		CheckHack <offset FOIE_name eq 0>
	push	bx
	;
	; send entry to superclass (Text object)
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	clr	cx				; null-terminated
	call	ObjCallInstanceNoLock
	pop	bx
	call	MemUnlock
	ret
ShowFileListEntry	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOperationBoxSetDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store disk handle of source files for file operation box

CALLED BY:	MSG_FOB_SET_DISK_HANDLE

PASS:		ds:*si - FileOperationBox instance
		cx - disk handle

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOperationBoxSetDiskHandle	method	FileOperationBoxClass,
						MSG_FOB_SET_DISK_HANDLE
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ds:[di].FOB_diskHandle, cx
	ret
FileOperationBoxSetDiskHandle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOperationBoxGetDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get disk handle of source files for file operation box

CALLED BY:	MSG_FOB_GET_DISK_HANDLE

PASS:		ds:*si - FileOperationBox instance

RETURN:		cx - disk handle

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOperationBoxGetDiskHandle	method	FileOperationBoxClass,
						MSG_FOB_GET_DISK_HANDLE
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	cx, ds:[di].FOB_diskHandle
	ret
FileOperationBoxGetDiskHandle	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOperationBox{Move,Copy,Recover,Link}ItemSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set bp to the appropriate FOBT and call
		FileOperationBoxItemSelectedCommon

CALLED BY:	MSG_FOB_MOVE_TO_ITEM_SELECTED,
		MSG_FOB_COPY_TO_ITEM_SELECTED,
		MSG_FOB_RECOVER_TO_ITEM_SELECTED,
		MSG_FOB_LINK_TO_ITEM_SELECTED,

PASS:		none
RETURN:		none
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	12/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOpertionBoxMoveItemSelected	method	FileOperationBoxClass,
						MSG_FOB_MOVE_TO_ITEM_SELECTED
	mov	bp, FOBT_MOVE
	call	FileOperationBoxItemSelectedCommon
	ret
FileOpertionBoxMoveItemSelected	endm
FileOpertionBoxCopyItemSelected	method	FileOperationBoxClass,
						MSG_FOB_COPY_TO_ITEM_SELECTED
	mov	bp, FOBT_COPY
	call	FileOperationBoxItemSelectedCommon
	ret
FileOpertionBoxCopyItemSelected	endm
FileOpertionBoxRecoverItemSelected	method	FileOperationBoxClass,
						MSG_FOB_RECOVER_TO_ITEM_SELECTED
	mov	bp, FOBT_RECOVER
	call	FileOperationBoxItemSelectedCommon
	ret
FileOpertionBoxRecoverItemSelected	endm

ifdef CREATE_LINKS
FileOpertionBoxLinkItemSelected	method	FileOperationBoxClass,
						MSG_FOB_LINK_TO_ITEM_SELECTED
	mov	bp, FOBT_LINK
	call	FileOperationBoxItemSelectedCommon
	ret
FileOpertionBoxLinkItemSelected	endm
endif		; ifdef CREATE_LINKS



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FileOperationBoxItemSelectedCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take the current selection of the file selector and display
		it below the file selector

CALLED BY:	FileOperationBox{Move,Copy,Recover,Link}ItemSelected

PASS:		bp - FileOperationBoxType

RETURN:		none
DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	12/15/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FileOperationBoxItemSelectedCommon proc near 
	.enter

	;
	; allocate a block for two paths on the heap
	;
if GPC_DISABLE_MOVE_COPY_FOR_SOURCE
	mov	ax, size PathName + size PathName + (size hptr)
else
	mov	ax, size PathName + size PathName
endif
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jnc	gotMem

	;
	; report error message from process thread
	;
	mov	ax, MSG_REMOTE_ERROR_BOX
	mov	cx, ERROR_INSUFFICIENT_MEMORY
	mov	bx, handle 0
	call	ObjMessageForce
	jmp	exit

gotMem:
	push	bx				; save mem block handle
	mov	dx, ax

	;
	; Get the new current directory string
	;
	call	FOBGetLastPathComponent		; returns es:di as string

	;
	; Set the text object under the file selector
	;
	call	FOBSetCurrentDirString

if GPC_DISABLE_MOVE_COPY_FOR_SOURCE
	;
	; we have es:0 = dest path, es:[size PathName] = available path
	; buffer, es:[2*(size PathName)] = dest disk
	;
	mov	bx, cs:[FileOperationBoxInfoTable][bp].FOBTTE_sourceDirHandle
	mov	si, cs:[FileOperationBoxInfoTable][bp].FOBTTE_sourceDirOffset
	tst	bx
	jz	noAction
	mov	ax, MSG_GEN_PATH_GET
	mov	dx, es
	push	bp
	mov	bp, size PathName
	mov	cx, size PathName
	call	ObjMessageCall			; cx = disk handle
	pop	bp
	mov	ds, dx
	mov	si, size PathName		; ds:si, cx = src path
	mov	dx, ds:[2*(size PathName)]
	clr	di				; es:di, dx = dest path
	call	FileComparePathsEvalLinks
	jc	enableAction			; error, enable action
	cmp	al, PCT_EQUAL
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	je	haveSrcState			; same, disable action
enableAction:
	mov	ax, MSG_GEN_SET_ENABLED
haveSrcState:
	mov	bx, cs:[FileOperationBoxInfoTable][bp].FOBTTE_actionButtonHandle
	mov	si, cs:[FileOperationBoxInfoTable][bp].FOBTTE_actionButtonOffset
	mov	dl, VUM_NOW
	call	ObjMessageCall
noAction:
endif
	;
	; Free up the block holding the paths and we're done
	;
	pop	bx
	call	MemFree				; free path buffer block	
exit:
	.leave
	ret
FileOperationBoxItemSelectedCommon endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FOBGetLastPathComponent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the current dir from the correct file selector, build
		it out to the full path and return the last component.

CALLED BY:	FileOperationBoxItemSelected

PASS:		bp -	FileOperationBoxType
		dx - global block for two paths (both of size Pathname)

RETURN:		es:di - last component of the path

DESTROYED:	ax, bx, cx, si, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	12/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FOBGetLastPathComponent	proc near
	uses	bp
	.enter

	mov	bx, cs:[FileOperationBoxInfoTable][bp].FOBTTE_fileSelectorHandle
	mov	si, cs:[FileOperationBoxInfoTable][bp].FOBTTE_fileSelectorOffset
	clr	bp				; dx:bp is buffer #1
	mov	cx, size PathName
	mov	ax, MSG_GEN_FILE_SELECTOR_GET_DESTINATION_PATH
	call	ObjMessageCall

	;
	; build out into a full path so we can grab the last component
	;
	mov	bx, cx
	mov	ds, dx
if GPC_DISABLE_MOVE_COPY_FOR_SOURCE
	mov	ds:[(size PathName)+(size PathName)], bx	; store disk
endif
	clr	si				; bx, ds:si is path (buffer #1)
	clr	dx				; no <drivename:> requested
	mov	cx, size PathName
	segmov	es, ds
	mov	di, size PathName		; es:di is buffer #2
	call	FileConstructFullPath

	;
	; Grab the last component, or indicate the root
	;
	mov	di, size PathName		; es:di is buffer #2
SBCS <	mov	al, C_NULL						>
DBCS <	clr	ax							>
SBCS <	cmp	{byte} es:[di], al					>
DBCS <	cmp	{wchar}es:[di], ax					>
	je	rootDir
	mov	cx, size PathName		; search entire buffer
	LocalFindChar				; scasb/w to end of string

	sub	cx, size PathName
	neg	cx				; search as far as we got 
	inc	cx				;  going forward +1
	LocalLoadChar ax, C_BACKSLASH
	std					; search backward
	LocalFindChar				; scasb/w for the backslash
	cld					; restore direction flag
	jne	gotStringInESDI			; no slash, we are pointing at
						;   the string
	LocalNextChar esdi
SBCS <	cmp	{byte} es:[di+1], C_NULL	; is this a root string? >
DBCS <	cmp	{wchar}es:[di+2], C_NULL	; is this a root string? >
	je	gotStringInESDI			;   if so point to backslash
	LocalNextChar esdi			; else skip past backslash
	jmp	gotStringInESDI

rootDir:
SBCS <	mov	{word} es:[di], C_BACKSLASH or (C_NULL shl 8)		>
DBCS <	mov	{wchar}es:[di], C_BACKSLASH				>
DBCS <	mov	{wchar}es:[di][2], C_NULL				>

gotStringInESDI:

	.leave
	ret
FOBGetLastPathComponent	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FOBSetCurrentDirString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the string to the prepend string and then append on the
		passed in string (the directory name to append).

CALLED BY:	FileOperationBoxItemSelected

PASS:		bp - FileOperationBoxType
		es:di - directory name to append

RETURN:		none
DESTROYED:	all, but bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	12/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FOBSetCurrentDirString proc near
	uses	bp
	.enter

	push	di
	push	bp
	mov	bx, cs:[FileOperationBoxInfoTable][bp].FOBTTE_curDirTextHandle
	mov	si, cs:[FileOperationBoxInfoTable][bp].FOBTTE_curDirTextOffset
	mov	ax, MSG_META_SUSPEND
	call	ObjMessageCall
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjMessageCall
	pop	bp

	push	bx
	mov	bx, handle DeskStringsCommon
	call	MemLock				; lock DeskStringsCommon res.
	mov	ds, ax
	mov	bp, cs:[FileOperationBoxInfoTable][bp].FOBTTE_prependTextOffset
	mov	bp, ds:[bp]			; dereference the string handle
	mov	dx, ds
	clr	cx
	pop	bx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessageCall

	mov	bp, bx
	mov	bx, handle DeskStringsCommon	
	call	MemUnlock			; unlock DeskStringsCommon res.
	mov	bx, bp

	pop	di
	clr	cx
	mov	ax, MSG_VIS_TEXT_APPEND_PTR
	mov	dx, es
	mov	bp, di				; dx:bp is the string to append
	call	ObjMessageCall

	mov	ax, MSG_META_UNSUSPEND
	call	ObjMessageCall

	.leave
	ret
FOBSetCurrentDirString endp

if GPC_DISABLE_MOVE_COPY_FOR_SOURCE
FileOperationBoxInfoTable label FileOperationBoxTypeTableEntry
	FileOperationBoxTypeTableEntry<
		handle MoveToEntry,
		offset MoveToEntry,
		handle MoveToCurrentDir,
		offset MoveToCurrentDir,
		offset FOBMoveSelectedFilesTo,
		handle MoveBox,
		offset MoveBox,
		handle MoveOK,
		offset MoveOK
	>
	FileOperationBoxTypeTableEntry<
		handle CopyToEntry,
		offset CopyToEntry,
		handle CopyToCurrentDir,
		offset CopyToCurrentDir,
		offset FOBCopySelectedFilesTo,
		handle CopyBox,
		offset CopyBox,
		handle CopyOK,
		offset CopyOK
	>
	FileOperationBoxTypeTableEntry<
		handle RecoverToEntry,
		offset RecoverToEntry,
		handle RecoverToCurrentDir,
		offset RecoverToCurrentDir,
		offset FOBRecoverSelectedFilesTo,
		handle RecoverBox,
		offset RecoverBox,
		handle RecoverOK,
		offset RecoverOK
	>
ifdef CREATE_LINKS
	FileOperationBoxTypeTableEntry<
		handle CreateLinkToEntry,
		offset CreateLinkToEntry,
		handle CreateLinkToCurrentDir,
		offset CreateLinkToCurrentDir,
		offset FOBPlaceLinkIn,
		0,
		0,
		0,
		0
	>
endif
else
FileOperationBoxInfoTable label FileOperationBoxTypeTableEntry
	FileOperationBoxTypeTableEntry<
		handle MoveToEntry,
		offset MoveToEntry,
		handle MoveToCurrentDir,
		offset MoveToCurrentDir,
		offset FOBMoveSelectedFilesTo
	>
	FileOperationBoxTypeTableEntry<
		handle CopyToEntry,
		offset CopyToEntry,
		handle CopyToCurrentDir,
		offset CopyToCurrentDir,
		offset FOBCopySelectedFilesTo
	>
	FileOperationBoxTypeTableEntry<
		handle RecoverToEntry,
		offset RecoverToEntry,
		handle RecoverToCurrentDir,
		offset RecoverToCurrentDir,
		offset FOBRecoverSelectedFilesTo
	>
ifdef CREATE_LINKS
	FileOperationBoxTypeTableEntry<
		handle CreateLinkToEntry,
		offset CreateLinkToEntry,
		handle CreateLinkToCurrentDir,
		offset CreateLinkToCurrentDir,
		offset FOBPlaceLinkIn
	>
endif
endif  ; GPC_DISABLE_MOVE_COPY_FOR_SOURCE
.assert (($-FileOperationBoxInfoTable) eq FileOperationBoxType)

FileOperation	ends
