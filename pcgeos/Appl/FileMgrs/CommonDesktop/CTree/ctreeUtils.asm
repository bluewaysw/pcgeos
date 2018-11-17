COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Tree
FILE:		treeUtils.asm
AUTHOR:		Brian Chin

ROUTINES:
	INT	ExposeTreeFolderIcon - get GState and draw icon/name pair
	INT	SetDirectoryTreePathname - show pathname above tree display
	INT	GetTreeFolderIcon - get correct bitmap for a folder icon in tree
	INT	GetTreeFolderName - get name of a folder in tree
	INT	BuildDirName - build complete pathname of subdir. in tree
	INT	SortHierarchy - combine all subdirs. into tree structure
	INT	ExpandDirectory - find all subdirs. of a directory
	INT	BuildTreeIconBounds - get name bounds, icon bounds, bounding box
	INT	GetTreeIconCoords - compute coordinates of an icon within tree
	INT	GetTreeFolderBoundBox - get bounding box for a folder's
						icon/name pair in tree display

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/29/89		broken out from treeClass.asm
	brianc	9/29/89		moved here from treeClass.asm

DESCRIPTION:
	This file contains utility routines for the Tree class.

	$Id: ctreeUtils.asm,v 1.1 97/04/04 15:00:49 newdeal Exp $

------------------------------------------------------------------------------@

TreeCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExposeTreeFolderIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get gState and draw icon for this folder object

CALLED BY:	INTERNAL
			TreeButton

PASS:		ds:si - instance data of Tree
		es:di - pointer to folder buffer entry for object
		ax =	DTI_CLEAR_ONLY if only clear
			DTI_DRAW_ONLY if only draw
			DTI_CLEAR_AND_DRAW if clear then draw

RETURN:		bp, ds, si, es, di - unchanged

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExposeTreeFolderIcon	proc	near
	class	TreeClass

	push	di, bp, bx, cx
	mov	cx, VIEW_MAX_SUBVIEWS
	clr	bx
ETFI_loop:
	mov	bp, ds:[si][bx].TI_subviews	; get window
	tst	bp				; any thing?
	jz	ETFI_next			; if not, check next
	mov	bp, ds:[si][bx].TI_gStates	; get associated GState
	tst	bp
	jz	ETFI_next
	push	ax, bx, cx			; ax = draw flag
	call	DrawTreeFolderIcon		; pass bp=gState, es:di=entry
	pop	ax, bx, cx
ETFI_next:
	add	bx, 2
	loop	ETFI_loop
	pop	di, bp, bx, cx
	ret
ExposeTreeFolderIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetDirectoryTreePathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	builds new pathname and volume string of the form
		"[volume]  c:/.../..." and shows it in Directory Tree
		window

CALLED BY:	INTERNAL
			TreeScan
			TreeButton

PASS:		es:di = tree buffer entry of folder at end of current path
		ds:si = instance data of Tree object

RETURN:		es, di, ds, si preserved

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetDirectoryTreePathname	proc	near
	push	es, di, si
	mov	dx, BDN_VOLUME_AND_PATHNAME	; do it all
	call	BuildDirName			; ss:dx = pathname of es:di
	mov	bp, dx
NOFXIP<	mov	dx, segment idata		; dx:bp = new pathname	>
FXIP<	push	ds							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	dx, ds				; dx = dgroup		>
FXIP<	pop	ds							>
	mov	bx, handle TreeUI
	mov	si, offset TreeUI:TreePathname
	call	CallFixupSetText		; show new current pathname
	pop	es, di, si
	ret
SetDirectoryTreePathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTreeFolderIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	selects the correct folder bitmap to use depending on the
		state of the folder (outline/collapsed)

CALLED BY:	INTERNAL
			DrawTreeFolderIcon

PASS:		es:bp - tree buffer entry of this folder

RETURN:		ds:si - offset of bitmap

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		this is only called when the tree is in outline mode

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/20/89		Broken out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTreeFolderIcon	proc	near
FXIP <	push	cx						>
	mov	si, cs				; bitmaps in this segment
	mov	ds, si						
	mov	si, offset treeIconBitmap	; assume uncollapsed
FXIP <	mov	cx, offset treeIconBitmapEnd			>
FXIP <	sub	cx, offset treeIconBitmap			>
	test	es:[bp].TE_state, mask TESF_COLLAPSED	; check if collapsed
	jz	GTFI_gotIt			; if not, done
	mov	si, offset collapsedIconBitmap	; else, get collapsed bitmap
FXIP<	mov	cx, offset collapsedIconBitmapEnd			>
FXIP<	sub	cx, offset collapsedIconBitmap				>
GTFI_gotIt:
		
FXIP <	call	SysCopyToStackDSSI	;ds:si = bitmap on stack	>
FXIP <	pop	cx						>
	ret
GetTreeFolderIcon	endp

.assert (segment GetTreeFolderIcon) eq (segment treeIconBitmap)
.assert (segment GetTreeFolderIcon) eq (segment collapsedIconBitmap)
.assert (segment DrawTreeFolderIcon) eq (segment treeIconBitmap)
.assert (segment DrawTreeFolderIcon) eq (segment collapsedIconBitmap)


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTreeFolderName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	gets pointer to name of this folder

CALLED BY:	INTERNAL
			DrawTreeFolderIcon

PASS:		es:bp - tree buffer entry of this folder

RETURN:		ds:si - pointer to folder's name

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/3/89		Initial revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTreeFolderName	proc	near
	segmov	ds, es, si
	mov	si, bp
	add	si, offset TE_attrs.TA_name
	ret
GetTreeFolderName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDirName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build complete pathname for this directory

CALLED BY:	INTERNAL
			TreeScan
			TreeButton

PASS:		es:di - tree buffer entry for this directory
		dx -	BDN_PATHNAME - builds normal pathname ("/.../...")
			BDN_VOLUME_AND_PATHNAME - builds the load
							("[volume]  /.../...")
		ds:si - instance data of Tree object
				(if BDN_VOLUME_AND_PATHNAME)

RETURN:		dgroup:dx - pathname
		ax - length of pathname (including null-terminator)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildDirNameFar	proc	far
	call	BuildDirName
	ret
BuildDirNameFar	endp

BuildDirName	proc	near
	class	TreeClass

	push	bx, cx, di, es
	push	ds, si				; save instance data
	segmov	ds, es, ax			; ds:si = tree buffer entry
	mov	si, di
FXIP<	mov_tr	ax, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov_tr	bx, ax							>
NOFXIP<	segmov	es, <segment idata>, ax		; set ES = dgroup	>
						; end of pathname buffer
	std					; set direction flag
SBCS <	mov	di, (offset buildDirNameBuffer)+(size buildDirNameBuffer-1) >
DBCS <	mov	di, (offset buildDirNameBuffer)+(size buildDirNameBuffer-2) >
SBCS <	clr	al							>
DBCS <	clr	ax							>
	LocalPutChar esdi, ax			; stuff null-terminator
	cmp	ds:[si].TE_parentID, NIL	; check if passed root
	je	BDN_justRoot			; if so, special handling
BDN_doParent:
	cmp	ds:[si].TE_parentID, NIL	; check if this is root
	je	BDN_foundRoot			; if so, branch
	mov	bx, offset TE_attrs.TA_name
	clr	cx				; initialize filename length
BDN_checkForNull:
SBCS <	cmp	byte ptr ds:[si][bx], 0		; check if null-term.	>
DBCS <	cmp	{wchar}ds:[si][bx], 0		; check if null-term.	>
	je	BDN_foundNameEndCheck		; if so, found end of name
	inc	cx
	LocalNextChar dsbx			; else, check next char.
	jmp	short BDN_checkForNull
BDN_foundNameEndCheck:
	jcxz	BDN_nullDirName			; no chars in directory name!
BDN_foundNameEnd:
	LocalPrevChar dsbx			; backup to last char.
SBCS <	mov	al, ds:[si][bx]			; get char. from tree buffer >
DBCS <	mov	ax, ds:[si][bx]			; get char. from tree buffer >
	LocalPutChar esdi, ax			; store in pathname buffer
	loop	BDN_foundNameEnd		; loop to copy whole name
	LocalLoadChar ax, C_BACKSLASH		; store pathname seperator
	LocalPutChar esdi, ax
BDN_nullDirName:
	mov	si, ds:[si].TE_parentID		; get parent
	jmp	short BDN_doParent
BDN_justRoot:
	LocalLoadChar ax, C_BACKSLASH
	LocalPutChar esdi, ax			; store root name
BDN_foundRoot:
;;no drive letters in pathnames
;;	mov	al, ':'
;;	stosb
;;	mov	al, ss:[rootSearchName]		; get current drive
;;	stosb
	pop	ds, si				; restore instance data
	cmp	dx, BDN_VOLUME_AND_PATHNAME	; check if doing volume name
	jne	BDN_noVolumeName		; if not, skip
						; check if volume label exists
;	cmp	ds:[si].TI_diskInfo.DIS_name, 0
;	je	BDN_noVolumeName		; if not, skip
	LocalLoadChar 	ax, ' '			; store two spaces
	LocalPutChar esdi, ax
;;match Folder Window headers - one space only
;;	mov	al, ' '
;;	stosb
	LocalLoadChar 	ax, ']'			; store volume end mark
	LocalPutChar esdi, ax
	mov	bx, offset TI_diskInfo.DIS_name
;;;	cmp	{word} ds:[si][bx], 'U' or ('n' shl 8)	; unnamed?
;;;	je	40$				; yes
;;;	inc	di				; else, erase volume end mark
;;;40$:
	clr	cx				; initialize volume length
BDN_checkForVolEnd:
SBCS <	cmp	byte ptr ds:[si][bx], 0		; check if null-term.	>
DBCS <	cmp	{wchar}ds:[si][bx], 0		; check if null-term.	>
	jz	BDN_foundVolEnd			; if so, found end of name
	inc	cx
	LocalNextChar dsbx			; else, check next char.
	jmp	short BDN_checkForVolEnd
BDN_foundVolEnd:
	jcxz	BDN_noVolChars
	LocalPrevChar dsbx			; backup to last char.
SBCS <	mov	al, ds:[si][bx]			; get char. from volume label >
DBCS <	mov	ax, ds:[si][bx]			; get char. from volume label >
	LocalPutChar esdi, ax			; store in pathname buffer
	loop	BDN_foundVolEnd			; loop to copy whole name
BDN_noVolChars:
;;;						; unnamed?
;;;	cmp	{word} ds:[si].TI_diskInfo.DIS_volumeName, 'U' or ('n' shl 8)
;;;	jne	60$				; no
	LocalLoadChar 	ax, '['			; else, store volume start mark
	LocalPutChar esdi, ax
;;;60$:
	LocalLoadChar ax, ':'
	LocalPutChar esdi, ax
	cld
	mov	bx, ds:[si].TI_disk
	call	DiskGetDrive
	
	clr	cx
	call	DriveGetName
EC <	tst	cx							>
EC <	ERROR_Z	DRIVE_TOOL_BOUND_TO_INVALID_DRIVE			>
	LocalPrevChar 	dscx		; don't need null-term, thanks
   	sub	di, cx
	push	di		; save di 1 low...
	LocalNextChar esdi	; di was already 1 low, so bump it back up
				;  to where we really want the drive name
				;  stored.
	call	DriveGetName
	
	pop	di		; restore di before drive name, it having been
				;  changed by DriveGetName...
BDN_noVolumeName:
	LocalNextChar esdi
	mov	dx, di				; dgroup:dx <- path
	mov	ax, offset buildDirNameBuffer + (size PathName)
	sub	ax, di				; ax = length of pathname
DBCS <	shr	ax, 1				; ax <- length of pathname >
	cld					; restore direction flag
	pop	bx, cx, di, es
	ret
BuildDirName	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortHierarchy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sorts the entries the tree buffer so that the
		various subdirectories are placed with their parents

CALLED BY:	INTERNAL
			CollapseBranchLow
			ExpandLowCommon
			TreeScan
			TreeUpdateTree

PASS:		ds:[si] - instance data:
			ds:[si].TI_treeBuffer - handle of tree buffer
			ds:[si].TI_treeBufferNext - last entry in tree buffer

RETURN:		carry clear if successful
		carry set if error
			ax - error code
				ERROR_INSUFFICIENT_MEMORY
		preserves ds, si

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version
	brianc	7/20/89		changed to be subroutine for method handler
	brianc	8/18/89		added support for outline tree stuff
	brianc	9/28/89		nuked displayList for new outline tree handling
	brianc	10/26/89	set doc size to fit tree display
	brianc	11/24/92	add memory error handling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortHierarchy	proc	near
	class	TreeClass

	call	SortTreeBuffer			; sort alphabetically
	mov	ax, ds:[si].TI_treeBufferNext	; get bytes used by entries
	clr	dx				; 32-bit by 16-bit divide
	mov	cx, size TreeEntry
	div	cx				; ax = number of entries
	inc	ax				; make room for end-of-list mark
	shl	ax, 1				; ax = size of word table
						;	for tree entries
	mov	cx, mask HAF_LOCK shl 8		; locked buffer
	call	MemAlloc			; index table for tree buffer
	jc	SH_exit				; if error, exit
	push	bx				; save handle
	mov	es, ax				; es - segment of index table
	push	ds, si				; save instance data address
	call	LockTreeBuffer
	mov	cx, ds:[si].TI_treeBufferNext	; get last entry of tree buffer
	mov	ds, ax				; ds:si = tree buffer
	clr	si				; 	(ds:si = entry for root)
	mov	di, si				; es:di - start of index table
	call	ExpandDirectory			; expand the root's children
	mov	ax, NIL				; store end-of-index-table mark
	stosw					;	in the index table
	;
	; ds - segment of locked tree buffer
	; es - segment of locked index table for tree buffer
	;
	call	BuildTreeIconBounds		; fill in name/icon bounds
	;
	; special case check:  if root is not a parent (i.e. it has no
	; subdirectories), then force normal tree so that the root name isn't
	; indented without an outline icon (force normal whether or not
	; outline mode)
	;	ds - segment of locked tree buffer
	;
	test	ds:[0].TE_state, mask TESF_PARENT	; 0 = root (always)
	pop	ds, si				; retrieve instance data addr
	push	ax, bx				; save largest bounds
	jz	SH_normal			; if root is not a parent,
						;	force normal tree
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline mode?
	jnz	SH_outline			; if so, skip
SH_normal:
	call	MakeNormalTree			; make sure no outline icons
SH_outline:
	call	UnlockTreeBuffer
	pop	cx, dx				; retrieve largest bounds
	pop	bx				; clobber index table for
	call	MemFree				;	tree buffer
	;
	; set size of TreeView document to fit the tree display
	;	cx - X size
	;	dx - Y size
	;
	push	si
	mov	bx, handle TreeUI	; bx:si tree's GenView
	mov	si, offset TreeUI:TreeView
	mov	di, mask MF_FIXUP_DS
	call	GenViewSetSimpleBounds
	pop	si
	clc					; indicate success
SH_exit:
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; IN CASE of error
	ret
SortHierarchy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandDirectory
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adds the given directory and its subdirectories to the
		tree-buffer-index-table

CALLED BY:	INTERNAL
			SortHierarchy
			ExpandDirectory (recursively)

PASS:		ds:si - tree buffer entry of directory to expand
		es:di - position of next free spot in tree-buffer-index-table
		cx - last entry in tree buffer

passed recursively:
		bp - last tree buffer entry in display list
		ax - directory being expanded

RETURN:		es:di - updated
		bp - last entry in display list
			(NOT yet marked as last with NIL - this needs to be
				done by caller (SortHierarchy))

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		store DIRECTORY in index table;
		if (DIRECTORY != collapsed) {
			for each ENTRY in tree buffer {
				if (ENTRY == subdirectory of DIRECTORY) {
					mark DIRECTORY as a parent;
					ExpandDirectory(ENTRY);
				}
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version
	brianc	7/20/89		changed to be subroutine for method handler
	brianc	8/17/89		added support for outline tree stuff
	brianc	9/28/89		nuked displayList for new outline tree handling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandDirectory	proc	near
	test	ds:[si].TE_state, mask TESF_DELETED	; deleted?
	jnz	ED_exit				; if so, exit
	push	ax, si
	mov	ax, si				; get position of this dir.
	stosw					; save in index table
	test	ds:[si].TE_state, mask TESF_COLLAPSED	; collapsed?
	jnz	ED_done				; if so, don't expand
	clr	si				; start at begining of buffer
ED_loop:
	cmp	ax, ds:[si].TE_parentID		; check if this is a child
	jne	ED_next				; if not, skip to next one
	mov	bx, ax				; get parent
	ornf	ds:[bx].TE_state, mask TESF_PARENT	; mark it as a parent
	call	ExpandDirectory			; else, recursively expand
						;	the subdirectory
ED_next:
	add	si, size TreeEntry		; move to next entry
	cmp	si, cx				; check if we reached end
	jne	ED_loop				; if not, loop back for more
ED_done:
	pop	ax, si
ED_exit:
	ret
ExpandDirectory	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortTreeBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sort tree buffer entries alphabetically

CALLED BY:	SortHierarchy

PASS:		ds:si - instance data of tree object
			ds:[si].TI_treeBuffer - tree buffer handle

RETURN:		entries sorted
		ds, si preserved

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SortTreeBuffer	proc	near
	class	TreeClass

	push	ds, si
	call	LockTreeBuffer
	mov	dx, ds:[si].TI_treeBufferNext	; dx = end of tree buffer
	mov	bx, ds:[si].TI_selectedFolder	; bx = selected folder
	mov	ds, ax
	mov	es, ax				; ds:bp - entry to fill
	mov	bp, size TreeEntry		;	(keep root first)
STB_fillNext:
	mov	si, bp				; ds:si = smallest so far
	mov	di, si
	push	bx
STB_nextEntry:
	add	di, size TreeEntry		; es:di = scanner for smallest
	cmp	di, dx				; check if end of buffer
	jae	STB_doneScan			; if so, fill next position
	push	si, di
	add	si, offset TE_attrs.TA_name
	add	di, offset TE_attrs.TA_name
	push	cx, dx
	clr	cx				; compare null-termed strings
SBCS <	clr	ax				; convert both folder names >
SBCS <	mov	bx, '_'				; bx = default character >
	call	LocalCmpStrings			; compare ds:si to es:di
	pop	cx, dx
	pop	si, di
	jbe	STB_nextEntry			; if ds:si <= es:di, check next
	mov	si, di				; else, point to new smallest
	jmp	short STB_nextEntry		; check next
STB_doneScan:
	pop	bx
	;
	; swap position-to-fill with smallest
	;	ds/es:bp = position to fill
	;	ds/es:si = smallest
	;	bx = selected folder
	;
	cmp	bp, si				; check if we need to move
	je	STB_noSwap			; if not, don't
	mov	di, bp
	call	SwapTreeEntry			; si=smallest, di=pos. to fill
						;	dx = end of tree buffer
						;	bx = selected folder
						;		(updated)
STB_noSwap:
	add	bp, size TreeEntry		; move to next entry to fill
	cmp	bp, dx				; end of buffer?
	jb	STB_fillNext			; if not, go back to fill it
	pop	ds, si
	mov	ds:[si].TI_selectedFolder, bx	; in case it moved
	call	UnlockTreeBuffer
	ret
SortTreeBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapTreeEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	swap tree entries and update all parent IDs

CALLED BY:	INTERNAL
			SwapWithLastEntry
			SortTreeBuffer

PASS:		es - segment of locked tree buffer
		si - entry 1
		di - entry 2
		dx - end of tree buffer
		bx - currently selected folder

RETURN:		bx - new position of selected folder

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapTreeEntry	proc	near
	push	ds, si, di, ax, cx
	push	es, di				; save entry 2
	;
	; move entry 1 to temporary buffer
	;
	segmov	ds, es				; ds:si = entry 1
	push	ds, si				; save entry 1
NOFXIP<	segmov	es, <segment idata>, di		; es:di = temp buffer	>
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
	mov	di, offset swapTreeEntryBuffer
	mov	cx, size TreeEntry
	rep movsb
	;
	; move entry 2 to entry 1
	;
	pop	es, di				; es:di = entry 1
	pop	ds, si				; ds:si = entry 2
	push	si
	mov	cx, size TreeEntry
	rep movsb
	;
	; move temporary buffer to entry 2
	;
NOFXIP<	segmov	ds, <segment idata>, si		; ds:si = temp buffer	>
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
	mov	si, offset swapTreeEntryBuffer
	pop	di				; es:di = entry 2
	mov	cx, size TreeEntry
	rep movsb
	pop	ds, si, di, ax, cx
	;
	; fix up selected folder
	;
	cmp	si, bx				; was entry 1 selected folder?
	jne	STE_notOne			; if not, check entry 2
	mov	bx, di				; else, save entry 2 as selected
	jmp	short STE_fixedSelected
STE_notOne:
	cmp	di, bx
	jne	STE_fixedSelected
	mov	bx, si
STE_fixedSelected:
	;
	; fix up parent ID pointers, AFTER swapping; else, we will miss
	; the entry in the temporary buffer
	;
	push	di
	push	di
	mov	di, NIL-1
	call	FixUpParentIDs			; entry 1 -> TEMP
	mov	di, si
	pop	si
	call	FixUpParentIDs			; entry 2 -> entry 1
	mov	si, NIL-1
	pop	di
	call	FixUpParentIDs			; TEMP -> entry 2
	ret
SwapTreeEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixUpParentIDs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	since entry is being moved, change all pointers to this
		entry to point to new position

CALLED BY:	INTERNAL
			SwapTreeEntry
			CompressTreeBuffer

PASS:		es:si - entry to be moved
		es:di - new position
		dx - end of tree buffer

RETURN:		

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each entry in tree buffer {
			if (parentID == si) {
				parentID = di;
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixUpParentIDs	proc	near
	push	bp
	clr	bp				; start of tree buffer
FUPID_loop:
	test	es:[bp].TE_state, mask TESF_DELETED	; deleted?
	jnz	FUPID_next			; if so, skip
	cmp	es:[bp].TE_parentID, si		; is parent one to be moved?
	jne	FUPID_next			; if not, skip
	mov	es:[bp].TE_parentID, di		; else, store new parentID
FUPID_next:
	add	bp, size TreeEntry		; move to next entry
	cmp	bp, dx				; end of buffer?
	jne	FUPID_loop			; if not, loop
	pop	bp
	ret
FixUpParentIDs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildTreeIconBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	computes the bounds of icon/names that represent
		subdirectories in the directory tree display

CALLED BY:	INTERNAL
			SortHierarchy

PASS:		ds - segment of locked tree buffer
		es - segment of locked index table for tree buffer

RETURN:		icon/name bounds filled in tree buffer entries
		ax - largest X coordinate encountered
		bx - largest Y coordinate encountered
		preserves ds, es

DESTROYED:

PSEUDO CODE/STRATEGY:
		go through index table in order, building the name/icon
			bounds for each tree buffer entry pointed to
			by the index table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildTreeIconBounds	proc	near
	mov	bp, ss:[calcGState]		; bp = calc'ing gState
	clr	di				; offset into tree buffer index
	mov	ax, di				; ax = max. X coord. so far
	mov	bx, di				; bx = max. Y coord. so far
BTIB_loop:
	mov	si, es:[di]			; get offset into tree buffer
						;	from index table
	cmp	si, NIL				; check if end-of-index-table
	je	BTIB_done			; if so, get out
	push	ax, bx				; save max coords.
	mov	ax, ds:[si].TE_level		; tree level (folder's "column")
	mov	bx, di
	shr	bx, 1				; bx = this folder's "row"
	call	GetTreeIconCoords		; ax = X coord, bx = Y coord
	mov	ds:[si].TE_iconBounds.R_left, ax
	add	ax, TREE_OUTLINE_ICON_WIDTH
	mov	ds:[si].TE_iconBounds.R_right, ax
	add	ax, TREE_OUTLINE_ICON_HORIZ_SPACING
	mov	ds:[si].TE_nameBounds.R_left, ax
	push	bx				; save name top
	push	ax				; save name left
	mov	ds:[si].TE_nameBounds.R_top, bx
	mov	cx, ss:[desktopFontHeight]	; cx = name height
	sub	cx, TREE_OUTLINE_ICON_HEIGHT	; (assume name > icon)
	shr	cx, 1
	jnc	BTIB_even
	inc	cx
BTIB_even:
	add	bx, cx
	mov	ds:[si].TE_iconBounds.R_top, bx
	add	bx, TREE_OUTLINE_ICON_HEIGHT
;border width = 0 fix
;	dec	bx				; convert to offset
	mov	ds:[si].TE_iconBounds.R_bottom, bx
	push	si				; save entry
						; point to this folder's name
	add	si, offset TE_attrs.TA_name
	xchg	di, bp				; di = gState, bp = index offset
	mov	cx, size TA_name		; check all chars in name
	call	GrTextWidth			; dx = name length
	pop	si				; retrieve entry
	pop	cx				; retrieve name left
	add	cx, dx				; cx = name right
	mov	ds:[si].TE_nameBounds.R_right, cx	; save name right
	pop	ax				; retrieve name top
	add	ax, ss:[desktopFontHeight]	; bx = name height
;border width = 0 fix
;	dec	ax				; convert to offset
	mov	ds:[si].TE_nameBounds.R_bottom, ax	; save name bottom
	call	GetTreeFolderBoundBox		; get bounding box
	pop	ax, bx				; retrieve max coords
	cmp	ax, cx				; bigger X coord?
	ja	BTIB_bigX			; if not, continue
	mov	ax, cx				; if so, save it
BTIB_bigX:
	cmp	bx, dx				; bigger Y coord?
	ja	BTIB_bigY			; if not, continue
	mov	bx, dx				; if so, save it
BTIB_bigY:
	xchg	di, bp				; di = index offset, bp = gState
	add	di, 2				; move to next index
	jmp	short BTIB_loop			; loop back for more
BTIB_done:
	ret
BuildTreeIconBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTreeIconCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	given the icon's "row" and "column" location, returns
		X and Y coordinate location

CALLED BY:	INTERNAL
			TreeDraw
			DrawTreeFolderIcon

PASS:		ax - "column"
		bx - "row"

RETURN:		ax - X coord
		bx - Y coord

DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/20/89		Broken out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTreeIconCoords	proc	near
	mov	cx, TREE_OUTLINE_ICON_HEIGHT+TREE_OUTLINE_ICON_HORIZ_SPACING + TREE_OUTLINE_ICON_INDENT
	mul	cx				; ax = X coord. of folder
	xchg	ax, bx				; bx = X coord, ax = "row"
	mov	cx, ss:[desktopFontHeight]
	mul	cx				; ax = Y coord. of folder
	xchg	ax, bx				; ax = X coord, bx = Y coord
	ret
GetTreeIconCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTreeFolderBoundBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	compute new bounding box for icon/name combination

CALLED BY:	INTERNAL
			BuildTreeIconBounds

PASS:		ds:si - pointer to folder in tree buffer

RETURN:		new bounding box stored in folder's tree buffer entry
		ax, bx, cx, dx - bounds

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTreeFolderBoundBox	proc	near
	;
	; do left
	;
	mov	ax, ds:[si].TE_iconBounds.R_left
	cmp	ax, ds:[si].TE_nameBounds.R_left
	jle	GTFBB_gotLeft
	mov	ax, ds:[si].TE_nameBounds.R_left
GTFBB_gotLeft:
	mov	ds:[si].TE_boundBox.R_left, ax
	;
	; do top
	;
	mov	bx, ds:[si].TE_iconBounds.R_top
	cmp	bx, ds:[si].TE_nameBounds.R_top
	jle	GTFBB_gotTop
	mov	bx, ds:[si].TE_nameBounds.R_top
GTFBB_gotTop:
	mov	ds:[si].TE_boundBox.R_top, bx
	;
	; do right
	;
	mov	cx, ds:[si].TE_iconBounds.R_right
	cmp	cx, ds:[si].TE_nameBounds.R_right
	jge	GTFBB_gotRight
	mov	cx, ds:[si].TE_nameBounds.R_right
GTFBB_gotRight:
	mov	ds:[si].TE_boundBox.R_right, cx
	;
	; do bottom
	;
	mov	dx, ds:[si].TE_iconBounds.R_bottom
	cmp	dx, ds:[si].TE_nameBounds.R_bottom
	jge	GTFBB_gotBottom
	mov	dx, ds:[si].TE_nameBounds.R_bottom
GTFBB_gotBottom:
	mov	ds:[si].TE_boundBox.R_bottom, dx
	ret
GetTreeFolderBoundBox	endp

LockTreeBuffer	proc	near
	class	TreeClass

	mov	bx, ds:[si].TI_treeBuffer
	call	MemLock
	ret
LockTreeBuffer	endp

UnlockTreeBuffer	proc	near
	class	TreeClass

	mov	bx, ds:[si].TI_treeBuffer
	call	MemUnlock
	ret
UnlockTreeBuffer	endp

LockDiskBuffer	proc	near
	class	TreeClass

	mov	bx, ds:[si].TI_diskBuffer
	call	MemLock
	ret
LockDiskBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeSetDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the disk handle for the Tree object and save it away
		so it can be restored when we restart.

CALLED BY:	ReadVolumeLabel, TreeStoreNewDrive
PASS:		ds:si	= TreeInstance
		bx	= new disk handle
RETURN:		ds:si	= fixed up
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should probably handle bad disk handles here same way the
		UI handles them...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeSetDisk	proc	near
		class	TreeClass
		uses	es, di, cx, ax
		.enter
	;
	; Save the disk handle away in our instance data.
	; 
		mov	ds:[si].TI_disk, bx
	;
	; Now find how much space it'll take to save the beast.
	; 
		clr	cx		; => fetch # bytes required to save
		call	DiskSave
	;
	; Allocate that much under our favorite vardata tag..
	; 
		mov	ax, TEMP_TREE_SAVED_DISK_HANDLE or \
			mask VDF_SAVE_TO_STATE
		mov	di, bx		; save disk handle
		mov	si, offset TreeObject
		call	ObjVarAddData
	;
	; And call DiskSave again to actually save the disk.
	; 
		xchg	di, bx
		segmov	es, ds
		call	DiskSave
	;
	; Dereference the Tree object again for our caller.
	; 
		mov	si, ds:[si]
		.leave
		ret
TreeSetDisk	endp


TreeCode ends
