COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Tree
FILE:		treeScan.asm
AUTHOR:		Brian Chin

ROUTINES:
	INT	ReadVolumeLabel - read disk for volume label
	INT	ReadSubDirBranch - read and process entire subdirectory branch
	INT	ReadSubDirectory - read contents of subdirectory
	INT	ProcessDirectory - scan a directory, looking for child subdirs.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/29/89		broken out from treeClass.asm
	brianc	9/18/89		changed to use resizable tree buffer

DESCRIPTION:
	This file contains routines to scan the disk to build the tree
	directory structure display.

	$Id: ctreeScan.asm,v 1.1 97/04/04 15:00:55 newdeal Exp $

------------------------------------------------------------------------------@

TreeCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadVolumeLabel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get volume label of disk and put root into tree buffer

CALLED BY:	INTERNAL
			TreeScan

PASS:		ds:si - instance data of Tree object
		bx - disk handle of disk

RETURN:		carry clear is successful
			volume label stored in Tree object's instance data
			tree buffer contains entry for root
		carry set if error (already reported)

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/17/89		Initial version
	brianc	7/20/89		changed to subroutine for method handler
	brianc	8/4/89		changed to use DiskFileGetVolumeInfo routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadVolumeLabel	proc	near
	class	TreeClass

	;
	; get disk info (volume label, free sectors, etc.)
	;
	call	TreeSetDisk
	push	si				; save instance data offset
	add	si, offset TI_diskInfo		; ds:si = disk info field
	call	GetVolumeNameAndFreeSpace
	pop	si				; retrieve instance data
	jc	exit				; if error, exit
	;
	; add the root directory to the tree buffer
	;
	mov	ax, size TreeAttrs
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	memErr
	mov	es, ax
	mov	ds:[si].TI_diskBuffer, bx
	
SBCS <	mov	{word}es:[TA_name], C_BACKSLASH or (0 shl 8)		>
DBCS <	mov	es:[TA_name][0], C_BACKSLASH				>
DBCS <	mov	es:[TA_name][2], 0					>
	mov	es:[TA_attrs], mask FA_VOLUME
	mov	es:[TA_pathInfo], mask DPI_EXISTS_LOCALLY	; mark local
	mov	ax, ds:[si].TI_disk
	mov	es:[TA_disk], ax

	;
	; CD to the root of this drive, so we can get its file ID
	;

	push	bx
	mov_tr	bx, ax
	call	ShellPushToRoot
	pop	bx
	jc	unlock

	;
	; Fill in the File ID of the root dir, so that file change
	; notification works.
	;
	mov	ax, FEA_FILE_ID
	mov	di, offset TA_id
	push	ds
	segmov	ds, es
	mov	dx, offset TA_name
	mov	cx, size TA_id	
	call	FileGetPathExtAttributes
	pop	ds

	call	FilePopDir
unlock:
	call	MemUnlock
	mov	cx, 1				; cx = number of entries
	mov	bp, 0				; root = 0
	mov	dx, NIL				; parentID for root
	call	ProcessDirectory		; add root to tree buffer
	jnc	exit				; if no error, exit
memErr:
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	call	DesktopOKError			; report error (carry is set)
exit:
	ret
ReadVolumeLabel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadSubDirBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read entire tree rooted at this branch and add entire
		tree of subdirectories to tree buffer

CALLED BY:	INTERNAL
			TreeScan
			ExpandLowCommon (ExpandOneLevelLow, ExpandBranchLow)

PASS:		di - offset in tree buffer of root of branch to read
		bp - level in tree of root of branch
		ds:si - Tree object instance data
			ds:[si].TI_treeBufferNext - next avail. entry
		bx - special hack flag
			mask RSDB_REMOVE - will remove any pathnames
				encountered during processing from the
				collapsed branch buffer (when called from
				ExpandBranchLow)
			not mask RSBD_REMOVE - will not remove any pathnames
				from collapsed branch buffer (when called
				from TreeScan)
			mask RSDB_RESELECT - will mark folder whose pathname
				is stored in pathBuffer/
				selectedFolderDiskHandle as selected and will
				save pointer to it in ds:[si].TI_selectedFolder
			not mask RSDB_RESELECT - will not do that neat stuff
			mask RSDB_ONE_LEVEL_ONLY - only read to depth of
				one level (only used when starting up)

RETURN:		carry clear is successful
		carry set if error
			ax = error code

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/28/89		broken out of TreeScan for new outline
					tree handling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReadSubDirBranch	proc	near
	class	TreeClass

	hackFlag	local	word
	treeLevel	local	word
	stopLevel	local	word

	mov	cx, bp				; save treeLevel

	.enter

	mov	hackFlag, bx			; save obscure stuff
	mov	treeLevel, cx
	inc	cx
	mov	stopLevel, cx			; level to stop at for
						;	RSDB_ONE_LEVEL_ONLY

newLevel:
	mov	cx, ds:[si].TI_treeBufferNext	; point at last entry
	cmp	di, cx				; check if any entries added
						;	from previous level
	LONG je	done				; if none, then done (carry
						;	clear)
	inc	treeLevel			; bump level for new subdirs
	;
	; loop through level of subdirectories in tree buffer and add
	; the subdirectories of each to the tree buffer
	; 	di->cx = range of entries in tree buffer to process
	; 	treeLevel = level for new subdirectories
	;	hackFlag = hack flag
	;
nextSubdir:
	cmp	di, cx				; check if any to process
	je	newLevel			; if none, then finished with
						;	this level
	;
	; build complete pathname of this subdirectory
	;
	call	LockTreeBuffer			; for BuildDirName, etc.
	mov	es, ax				; es = tree buffer segment
	mov	dx, BDN_PATHNAME		; build pathname only
	call	BuildDirName			; build name of this dir.
	;
	; check if this directory is collapsed, if so, don't process it
	;	dgroup:dx = pathname
	;	es:di = tree buffer entry for this directory
	;	ds:si = instance data of tree object
	;	hackFlag = hack flag
	;
	test	hackFlag, mask RSDB_RESELECT	; reselect folder?
	jz	dontReselect			; if not, skip
	mov	bx, ds:[si].TI_disk		; compare disks
	cmp	bx, ss:[selectedFolderDiskHandle]
	jne	dontReselect			; no match, don't select
	push	ax, ds, si, es, di
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds					>
FXIP<	mov	bx, si							>
FXIP<	mov	si, ds							>
NOFXIP<	mov	si, segment dgroup					>
NOFXIP<	mov	ds, si							>
	mov	es, si
	mov	si, dx				; ds:si = path to scan
	mov	di, offset pathBuffer	; es:di = selected path
	call	CompareString			; is this selected folder?
	pop	ax, ds, si, es, di
	jne	dontReselect			; if not, skip
	ornf	es:[di].TE_state, mask TESF_SELECTED	; else, select it
	mov	ds:[si].TI_selectedFolder, di	; save as selected folder
	andnf	hackFlag, not (mask RSDB_RESELECT) ; clear flag so we don't do
						;	this stuff again
dontReselect:
	;
	; check if we want to scan one level only; if so, handle it here
	;
	test	hackFlag, mask RSDB_ONE_LEVEL_ONLY	; one level only?
	jz	notOneLevel
	mov	bx, treeLevel			; current level
	cmp	bx, stopLevel			; stopping here?
	jbe	notOneLevel			; no, continue
	call	CheckForAnySubdirs		; C set if it has subdirs
						; (also saves collapsed path)
	jc	short markAsParent		; if so, mark as parent
	jmp	short notParent			; else, not parent
	;
	; handle removing/not removing pathname from collapsed branch buffer
	;
notOneLevel:
	push	cx				; save end of range to process
	mov	bx, ds:[si].TI_disk		; pass disk handle
	test	hackFlag, mask RSDB_REMOVE	; delete from collapsed buf?
	jz	justRead			; if not, just read 'em
	call	CheckDeleteCollapsedPathname	; else, delete if found
	clc					; indicate not found
	jmp	short donePath
justRead:
	call	CheckCollapsedPathname		; check if collapsed
donePath:
	pop	cx
	jnc	notCollapsed		; if not, process it
markAsParent:
					; else, mark as parent and collapsed
	ornf	es:[di].TE_state, mask TESF_PARENT or mask TESF_COLLAPSED
notParent:
	call	UnlockTreeBuffer		; for ReadSubDirectory
	jmp	short collapsed
notCollapsed:
	call	UnlockTreeBuffer		; for ReadSubDirectory
	mov	ax, di				; ax = parentID for this subdir.
	push	bp				; save locals
	mov	bp, treeLevel
	call	ReadSubDirectory		; read subdirectory and add
						;	it's subdirectories
						;	to tree buffer
	pop	bp				; retrieve locals
	jc	done				; error, exit with AX and carry

collapsed:
	add	di, size TreeEntry		; move to next subdir.
	jmp	nextSubdir			; go back to process it

done:
	.leave
	ret
ReadSubDirBranch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PushToPassedDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Push to the passed directory

CALLED BY:	ReadSubDirectory, CheckForAnySubdirs
PASS:		ds:si	= TreeInstance
		dgroup:dx = path
RETURN:		carry set if couldn't change:
			ax	= error code
		previous directory always pushed
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PushToPassedDir	proc	near
	class	TreeClass
	uses	bx, ds
	.enter
	call	FilePushDir

	mov	bx, ds:[si].TI_disk
FXIP<	mov_tr	ax, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov_tr	bx, ax							>
NOFXIP<	segmov	ds, dgroup, ax						>
	call	FileSetCurrentPath
		
	.leave
	ret
PushToPassedDir	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForAnySubdirs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if this directory has any subdirectories; if so,
		save its pathname in collapsed branch buffer and return
		flag indicating this

CALLED BY:	INTERNAL
			ReadSubDirBranch

PASS:		dgroup:dx = pathname of directory to check
		es:di = entry for directory in tree buffer
		ds:si = instance data of tree object

RETURN:		carry set if directory has subdirectories
		carry clear otherwise

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; We don't want to match links, as we could go into an infinite loop
; if we do...
;
treeMatchAttrs	FileExtAttrDesc \
 <FEA_FILE_ATTR, (mask FA_LINK shl 16) or mask FA_SUBDIR, size FileAttrs>,
 <FEA_END_OF_LIST>
	

checkForSubDirsParams	FileEnumParams <
	FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS,		; FEP_searchFlags
	FESRT_COUNT_ONLY,			; FEP_returnAttrs
	0,					; FEP_returnSize
	treeMatchAttrs,				; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,			; FEP_bufSize
	0					; FEP_skipCount
>

CheckForAnySubdirs	proc	near
	class	TreeClass

	uses	ax, bx, cx, dx, es, di, ds, si, bp

	.enter

	call	PushToPassedDir
	jc	enumComplete

	push	ds, si
	segmov	ds, cs
	mov	si, offset checkForSubDirsParams
	call	FileEnumPtr
	pop	ds, si
	
enumComplete:
	call	FilePopDir
	jc	noSubDirs
	tst	dx			; any matched but not stored?
	jz	noSubDirs		; no

	;
	; this directory contains other subdirectories, save pathname
	; in collapsed branch buffer and return flag
	;	es:di = tree buffer entry of directory containing subdirectories
	;
	mov	bx, ds:[si].TI_disk		; pass disk handle
	call	SaveCollapsedPathname		; save pathname
	stc					; indicate found
	jmp	short done
noSubDirs:
	clc					; indicate no subdirs.
done:
	.leave

	ret
CheckForAnySubdirs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReadSubDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	read in a subdirectory and add it's subdirectories to
		the directory tree buffer

CALLED BY:	INTERNAL
			ReadSubDirBranch

PASS:		ds:[si] - instance data:
			ds:[si].TI_diskBuffer - buffer for reading subdirectory
		dgroup:dx - complete pathname to search
		bp - level for subdirectory's subdirectories
		ax - parentID of this subdirectory

RETURN:		carry clear if successful
		carry set if error
			ax = error code

DESTROYED:	preserves si, di, bx, cx, bp, ds

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version
	brianc	7/17/89		changed to use only kernel file routines
	brianc	7/20/89		changed to subroutine for method handler
	brianc	9/18/89		changed to use resizable tree buffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
readSubDirReturnAttrs	FileExtAttrDesc	\
	<FEA_NAME,		TA_name,	size TA_name>,
	<FEA_FILE_TYPE,		TA_type, 	size TA_type>,
	<FEA_FILE_ATTR,		TA_attrs,	size TA_attrs>,
	<FEA_FLAGS,		TA_flags,	size TA_flags>,
	<FEA_PATH_INFO,		TA_pathInfo,	size TA_pathInfo>,
	<FEA_DISK,		TA_disk,	size TA_disk>,
	<FEA_FILE_ID,		TA_id,		size TA_id>,
	<FEA_END_OF_LIST>

readSubDirParams	FileEnumParams <
	FILE_ENUM_ALL_FILE_TYPES or mask FESF_DIRS,	; FEP_searchFlags
	readSubDirReturnAttrs,		; FEP_returnAttrs
	size TreeAttrs,			; FEP_returnSize
	treeMatchAttrs,			; FEP_matchAttrs
	FE_BUFSIZE_UNLIMITED,		; FEP_bufSize
	0				; FEP_skipCount
>

ReadSubDirectory	proc	near
	class	TreeClass

	push	bx, cx, di
	mov_tr	cx, ax				; cx = parentID

	call	PushToPassedDir
	jc	RSD_done


	;
	; read subdirectory, looking for its subdirectories
	;	bp = level for subdirectory's subdirectories
	;	cx = parentID
	;	ds:si = Tree instance data
	;
	push	ds, si, cx

	segmov	ds, cs
	mov	si, offset readSubDirParams
	call	FileEnumPtr

	pop	ds, si, dx			; dx <- parentID
	mov	ds:[si].TI_diskBuffer, bx	; pass buffer handle
						;  in instance data...
	jcxz	RSD_done			; if no files, exit with
						;  possible carry & ax
	push	ax				; save error code
	pushf					; and flag
	
	call	ProcessDirectory
	jc	processDirError

	popf					; retrieve enum status
	pop	ax				; and error code
RSD_done:
	call	FilePopDir
	pop	bx, cx, di
	ret			; <====  EXIT HERE

processDirError:
	add	sp, 4			; discard previous error
	stc
	mov	ax, ERROR_INSUFFICIENT_MEMORY
	jmp	RSD_done
ReadSubDirectory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go through buffer containing directory and stuff all
		subdirectories into global directory tree buffer

CALLED BY:	INTERNAL
			ReadVolumeLabel
			ReadSubDirectory

PASS:		ds:[si] - instance data:
			ds:[si].TI_treeBuffer - directory tree buffer
			ds:[si].TI_treeBufferSize - size of tree buffer
			ds:[si].TI_treeBuferNext - offset to next available
							record in tree buffer
			ds:[si].TI_diskBuffer - buffer containing directory
		cx - number of entries in buffer
		bp - directory level
		dx - parentID for this subdirectory

RETURN:		carry clear if successful
			ds:[si].TI_treeBufferNext - updated to point to next
						available spot
		carry set otherwise (memory allocation error)
		preserves ax, bx, cx, dx, bp, ds, si, di

DESTROYED:	es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/12/89		Initial version
	brianc	7/17/89		changed to use only kernel file routines
	brianc	7/20/89		changed to subroutine for method handler
	brianc	9/18/89		changed to use resizable tree buffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessDirectory	proc	near
	push	ax, bx, cx, dx, bp, ds, si, di
	clc					; in case no entries
	jcxz	PD_exit
	call	ProcessDirLow
PD_exit:
	pop	ax, bx, cx, dx, bp, ds, si, di
	ret
ProcessDirectory	endp

ProcessDirLow	proc	near
	class	TreeClass
dirLevel	local	word	push	bp
treeDiskHandle	local	word	push	ds:[si].TI_disk
tempBuffer	local	PathName
	.enter

	call	LockTreeBuffer
	mov	es, ax
	mov	di, ds:[si].TI_treeBufferNext	; es:di = next tree record
	call	LockDiskBuffer			; 	to be filled
	push	ds, si
	mov	ds, ax				; ds:si = FileEnum buffer
	clr	si
PD_loop:
EC <	test	ds:[si].TA_attrs, mask FA_SUBDIR or mask FA_VOLUME>
EC <	ERROR_Z	DESKTOP_FATAL_ERROR		; if not, puke		>
	;
	; first, make sure there is enough room in tree buffer for new
	; subdirectory
	;	ds:si = FileEnum buffer (containing TreeAttrs structures)
	;	es:di = next free entry in tree buffer
	;	dx = parentID
	;	ss:[directoryLevel] = tree level
	;	cx = file counter
	;
	mov	ax, ds				; save FileEnum buffer temp.
	mov	bx, si
	pop	ds, si				; retrieve instance data addr.
	push	ds, si				; save instance data again
	push	ax, bx				; save FileEnum buffer
	mov	ax, ds:[si].TI_treeBufferSize	; get current buffer size
	cmp	di, ax				; check if enough room
	jae	noRoom				; if not, make more room
	clc					; else, indicate no error
	jmp	short PD_enoughRoom		; ...and continue

noRoom:
	push	cx				; save file counter
	add	ax, (TREE_BUFFER_NUM_INCREMENT * size TreeEntry) ; new size
;handle too large a tree-structure - 8/9/90
	cmp	ax, 0xf000			; 0xf000 - the largest we want
	jbe	notTooBig			; go for it
	pop	cx				; else, retrieve file count...
	stc					; ...signal memory error...
	jmp	short PD_enoughRoom		; ...and get out

notTooBig:
	mov	bx, ds:[si].TI_treeBuffer	; tree buffer handle
	clr	ch				; tree buffer locked already
	mov	ds:[si].TI_treeBufferSize, ax	; save new tree buffer size
	call	MemReAlloc			; resize tree buffer
	pop	cx				; retrieve file counter
	mov	es, ax				; in case buffer moved
PD_enoughRoom:
	pop	ds, si				; retrieve FileEnum buffer
	jc	afterLoop			; leave loop if mem. error
	;
	; store level in tree buffer entry then copy directory entry
	; from directory buffer to record entry in tree buffer
	; (could be done faster with STOSW, but that would assume knowledge
	;	about the format of the TreeEntry structure)
	;
	mov	ax, ss:[dirLevel]
	mov	es:[di].TE_level, ax		; store level
	mov	es:[di].TE_parentID, dx		; store parentID
	clr	es:[di].TE_state		; default state flags =
						;	not selected, not open

ForceRef	treeDiskHandle			; used in TreeSetTrueDiskHandle
ForceRef	tempBuffer			;   not in this routine
	call	TreeSetTrueDiskHandle

	add	di, offset TE_attrs		; es:di = dir. entry field
	mov	bx, cx				; save counter
	mov	cx, size TreeAttrs
	rep movsb

	mov	cx, bx				; restore counter
						; es:di = next available tree
						;	record entry
	CheckHack <size TreeEntry eq offset TE_attrs+size TE_attrs>

	loop	PD_loop				; go back to process, if more
	clc					; indicate no error
afterLoop:
	pop	ds, si
	pushf					; save status
	mov	ds:[si].TI_treeBufferNext, di	; save next available entry
	call	UnlockTreeBuffer

	mov	bx, ds:[si].TI_diskBuffer
	call	MemFree				; free disk buffer
	popf					; retrieve status

	.leave
	ret
ProcessDirLow	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeSetTrueDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go through buffer containing directory and stuff all
		subdirectories into global directory tree buffer

CALLED BY:	ProcessDirLow

PASS:		es:di - tree entry of directory to set true diskhandle
		inherits the stack of ProcessDirLow
			ss:[treeDiskHandle] - the diskhandle of the tree
			ss:[tempBuffer]     - a PathName sized buffer

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		If the file isn't a link, set the true diskhandle to the
	true diskhandle of its parent directory.  If the parent directory's
	true diskhandle isn't set yet (because it is a link), evaluate it
	and set both.
		If the file is a link, set the true diskhandle to -1 to 
	indicate that it needs to be set.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/17/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeSetTrueDiskHandle	proc	near
	uses	ax, bx, cx, dx, si, ds
	.enter	inherit ProcessDirLow

	test	es:[di].TE_attrs.TA_attrs, mask FA_LINK
	jnz	notALink

	mov	es:[di].TE_attrs.TA_trueDH, -1	; if link set to "undetermined"
	jmp	exit

notALink:
	mov	bx, es:[di].TE_parentID
	cmp	bx, NIL				; A child of the root?
	jne	notChildOfRoot
						; if we are a child of the root
	mov	bx, es:[di].TE_attrs.TA_disk	;  and not a link then the true
	mov	es:[di].TE_attrs.TA_trueDH, bx	;  diskhandle is the file DH
	jmp	exit

notChildOfRoot:
	mov	ax, es:[bx].TE_attrs.TA_trueDH ; do we know parents trueDH?
	cmp	ax, -1
	jne	useParentsTrueDiskHandle

	mov	dx, BDN_PATHNAME
	call	BuildDirName			; Dgroup:dx is path

FXIP<	mov_tr	ax, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov_tr	bx, ax							>
NOFXIP<	segmov	ds, <segment idata>, ax					>
	mov	si, dx
	mov	bx, ss:[treeDiskHandle]		; bx, ds:si is the full path 
	clr	dx				; no <drivename:> requested
	push	es, di
	segmov	es, ss, di
	lea	di, ss:[tempBuffer]		; es:di is a temp buffer
	mov	cx, size PathName		; cx is size of temp buffer
	call	FileConstructActualPath
	pop	es, di
	jnc	setDiskHandle

	mov	dx, si				; in case of error using dx
	call	DesktopOKError			; report error, leave the true
	mov	ax, -1				;  diskhandle as unspecified.
	jmp	useParentsTrueDiskHandle

setDiskHandle:
	mov	ax, bx				; put true diskhandle in ax
	mov	bx, es:[di].TE_parentID
	mov	es:[bx].TE_attrs.TA_trueDH, ax	; set parent's true disk handle

useParentsTrueDiskHandle:			; true disk handle is in ax
	mov	es:[di].TE_attrs.TA_trueDH, ax

exit:
	.leave
	ret
TreeSetTrueDiskHandle	endp


TreeCode ends

