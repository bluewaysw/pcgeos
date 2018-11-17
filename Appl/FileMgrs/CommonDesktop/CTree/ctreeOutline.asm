COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Tree
FILE:		treeOutline.asm
AUTHOR:		Brian Chin

ROUTINES:
		INT	MakeOutlineTree - convert normal tree to outline tree
		INT	MakeNormalTree - convert outline tree to normal tree
		INT	CollapseBranchLow - collapse branch completely
		INT	ExpandBranchLow - expand branch completely
		INT	ExpandOneLevelLow - expand branch one level
		INT	SaveCollapsedPathname - save collapsed branch in buffer
		INT	DeleteCollapsedPathname - removed branch from buffer
		INT	CheckCollapsedPathname - check if branch in buffer
		INT	FindCollapsedPathname - find branch in buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/29/89		broken out from treeClass.asm
	brianc	9/29/89		new outline tree handling

DESCRIPTION:
	This file contains routines for the outline tree display.

	$Id: ctreeOutline.asm,v 1.1 97/04/04 15:00:50 newdeal Exp $

------------------------------------------------------------------------------@

TreeCode segment resource

;not needed - usability 4/3/90
if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeOutlineTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go through tree buffer and move filename over to allow
			outline tree icon to appear

CALLED BY:	INTERNAL
			TreeShowOutline

PASS:		ds:si - instance data of Tree object

RETURN:		ds, si preserved

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		should only be called if tree is currently in normal mode
		this routine does not change the outline mode flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/17/89		Initial version
	brianc	9/28/89		removed displayList, use TESF_DELETED

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeOutlineTree	proc	near
	class	TreeClass

	push	si
	call	LockTreeBuffer
	push	bx				; save handle
	mov	bx, ds:[si].TI_treeBufferNext	; bx = end of buffer
	mov	es, ax				; es:di - first entry
	clr	di
MOT_loop:
	test	es:[di].TE_state, mask TESF_DELETED	; is it deleted?
	jnz	MOT_next			; if so, do next
	call	CheckIfNonParentRoot
	jc	MOT_next			; root is not parent,
						;	don't indent
	;
	; push name over to make room for outline icon
	;
	mov	ax, es:[di].TE_nameBounds.R_left
	mov	cx, es:[di].TE_nameBounds.R_right
	add	ax, TREE_OUTLINE_ICON_WIDTH + TREE_OUTLINE_ICON_HORIZ_SPACING
	add	cx, TREE_OUTLINE_ICON_WIDTH + TREE_OUTLINE_ICON_HORIZ_SPACING
	mov	es:[di].TE_nameBounds.R_left, ax
	mov	es:[di].TE_nameBounds.R_right, cx
MOT_next:
	add	di, size TreeEntry		; move to next tree buffer entry
	cmp	di, bx				; check if end of buffer
	jne	short MOT_loop			; if not, loop
	pop	bx				; unlock tree buffer
	call	MemUnlock
	pop	si
	ret
MakeOutlineTree	endp

;
; return:
;	carry set if root AND not parent
;	carry clear otherwise
;
CheckIfNonParentRoot	proc	near
	tst	di
	jnz	notRoot				; not root, exit with Z clear
	test	es:[di].TE_state, mask TESF_PARENT	; if not parent, Z clr
	stc					; assume, root and not parent
	jz	done				; if not parent, assumption
						;	correct
notRoot:
	clc
done:
	ret
CheckIfNonParentRoot	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeNormalTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	go through tree buffer and move name back to original
			position to cover up outline tree icon

CALLED BY:	INTERNAL
			TreeShowOutline
			SortHierarchy

PASS:		ds:si - instance data of Tree object

RETURN:		ds, si preserved

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		should only be called if tree is currently in outline mode
		this routine does not change the outline mode flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/17/89		Initial version
	brianc	9/28/89		removed displayList, use TESF_DELETED

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeNormalTree	proc	near
	class	TreeClass

	push	si
	call	LockTreeBuffer
	push	bx				; save handle
	mov	bx, ds:[si].TI_treeBufferNext	; bx = end of buffer
	mov	es, ax				; es:di = first entry
	clr	di
MNT_loop:
	test	es:[di].TE_state, mask TESF_DELETED	; is it deleted?
	jnz	MNT_next			; if so, do next
	;
	; push name back over to original spot
	;
	mov	ax, es:[di].TE_nameBounds.R_left
	mov	cx, es:[di].TE_nameBounds.R_right
	sub	ax, TREE_OUTLINE_ICON_WIDTH + TREE_OUTLINE_ICON_HORIZ_SPACING
	sub	cx, TREE_OUTLINE_ICON_WIDTH + TREE_OUTLINE_ICON_HORIZ_SPACING
	mov	es:[di].TE_nameBounds.R_left, ax
	mov	es:[di].TE_nameBounds.R_right, cx
MNT_next:
	add	di, size TreeEntry		; move to next tree buffer entry
	cmp	di, bx				; check if end of buffer
	jne	short MNT_loop			; if not, loop
	pop	bx				; unlock tree buffer
	call	MemUnlock
	pop	si
	ret
MakeNormalTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CollapseBranchLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	collapse given branch

CALLED BY:	INTERNAL
			TreeCollpaseBranch
			TreeButton

PASS:		es:di - root of branch to collapse (in locked tree buffer)
		ds:si - instance data address of Tree object
		selected folder should be es:di

RETURN:		carry clear if successful
		carry set if error
			ax - error code
				ERROR_INSUFFICIENT_MEMORY
		preserves bp

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/17/89		Initial version
	brianc	9/28/89		new outline tree handling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CollapseBranchLow	proc	near
	class	TreeClass

	call	ShowHourglass
	push	bp
	test	es:[di].TE_state, mask TESF_PARENT	; is it a parent?
	jz	CBL_exit			; if not, can't collapse
	ornf	es:[di].TE_state, mask TESF_COLLAPSED	; mark as collapsed
	mov	bx, ds:[si].TI_disk		; pass disk handle
	call	SaveCollapsedPathname		; save the collapsed branch
						;	name
	call	DeleteAllChildren		; delete all children from
						;	tree buffer
	call	SortHierarchy			; rebuild new tree
	jc	CBL_exit			; if error, exit with AX, carry
	push	ds, si
	call	TreeRedrawLow			; redraw ourselves
	pop	ds, si
	clc					; indicate no error
CBL_exit:
	pop	bp
	call	HideHourglass			; (preserves flags)
	ret
CollapseBranchLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteAllChildren
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	delete all children of this subdirectory

CALLED BY:	INTERNAL
			ExpandBranchLow
			CollapseBranchLow

PASS:		es:di - entry of subdirectory in locked tree buffer
		ds:si - instance data of tree object
		selected folder should be es:di (ie. will not be deleted)

RETURN:		ds:[si].TI_treeBufferNext updated
		ds:[si].TI_selectedFolder updated
		es:di - pointer to subdirectory passed
				(THIS MAY HAVE MOVED!!)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		for each entry in tree buffer {
			if a child of es:di, mark as deleted;
		}
		compress tree buffer;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteAllChildren	proc	near
	class	TreeClass
	uses	ax, bx, bp, dx
	.enter

	clr	bp				; first tree buffer entry
	mov	dx, ds:[si].TI_treeBufferNext	; dx = end of buffer
DAC_loop:
	mov	bx, bp
DAC_innerLoop:
	mov	bx, es:[bx].TE_parentID		; get parent
	cmp	bx, NIL				; check if we went off the root
	je	DAC_next			; if so, do next
	cmp	bx, di				; check if child of ES:DI
	jne	DAC_innerLoop			; if not, check parent
	;
	; this tree buffer entry is a child of ES:DI, delete it
	;	es:[bp] = this entry
	;
	test	es:[bp].TE_state, mask TESF_PARENT	; is it a parent
	jz	DAC_notParent			; if not, don't save path
	push	bx, cx, dx, di		; trashed by SaveCollapsed...
	mov	di, bp				; es:di = branch to delete
	mov	bx, ds:[si].TI_disk	; pass disk handle
	call	SaveCollapsedPathname		; so we won't open it later
	pop	bx, cx, dx, di
DAC_notParent:
	ornf	es:[bp].TE_state, mask TESF_DELETED	; mark as deleted
DAC_next:
	add	bp, size TreeEntry		; move to next entry
	cmp	bp, dx				; end of buffer?
	jne	short DAC_loop			; if not, loop
	call	CompressTreeBuffer		; compress tree buffer

	.leave
	ret
DeleteAllChildren	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompressTreeBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	remove all deleted entries from tree buffer

CALLED BY:	DeleteAllChildren, TreeUpdateTree

PASS:		es - segment of locked tree buffer
		ds:si - instance data of tree object
		es:di - pointer to a tree buffer entry

RETURN:		all deleted entries removed
		ds:[si].TI_selectedFolder updated; may have moved
		ds:[si].TI_treeBufferNext updated
		es:di - pointer to tree buffer entry passed
			(THIS MAY HAVE MOVED!!)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		free = find first deleted entry in tree buffer;
		for (next = each entry after this) {
			FixUpParentIDs(free, next);
			free++ = next++;
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompressTreeBuffer	proc	near
	class	TreeClass
	uses	bx, cx, dx, bp
	.enter

	mov	bp, di
	push	ds, si
	mov	dx, ds:[si].TI_treeBufferNext	; dx = end of buffer
	mov	ax, dx
	mov	bx, ds:[si].TI_selectedFolder	; bx = selected folder
	segmov	ds, es
	clr	di				; start of locked tree buffer

outerLoop:
	test	es:[di].TE_state, mask TESF_DELETED	; deleted?
	jnz	foundFree			; if so, start moving

	add	di, size TreeEntry
	cmp	di, dx				; end of buffer?
	jb	outerLoop			; if not, loop
	jmp	done				; else, no free ones, done
	;
	; found free entry
	; find next valid (not deleted) entry, move it up to here
	;	di = free spot
	;
foundFree:
	mov	si, di				; start from free spot
innerLoop:
	test	ds:[si].TE_state, mask TESF_DELETED	; deleted?
	jz	notDeleted

	sub	ax, size TreeEntry	; reduce end of buffer

	; This entry is deleted.  If it's selected, then nuke the
	; selection. 
	cmp	si, bx
	jne	afterNukeSelected
	mov	bx, NIL

afterNukeSelected:
	add	si, size TreeEntry
	jmp	innerNext
	
	;
	; found valid (not deleted) entry, move it up
	;	di = free spot (destination)
	;	si = valid entry to move
	;
notDeleted:
	cmp	si, bx				; are we about to move
						;	selected folder?
	jne	notSelected			; if not, continue
	mov	bx, di				; else, save its new position

notSelected:
	cmp	si, bp				; are we about to move
						;	passed folder?
	jne	notPassed			; if not, continue
	mov	bp, di				; else, save its new position

notPassed:
	call	FixUpParentIDs
	mov	cx, size TreeEntry
	rep	movsb				; move it
						; now:	di = new free spot
						;	si = next entry
innerNext:
	cmp	si, dx				; end of buffer?
	jb	innerLoop			; if not, loop

done:
	pop	ds, si
	mov	ds:[si].TI_selectedFolder, bx	; new position of selected
						;	folder
	mov	ds:[si].TI_treeBufferNext, ax
	mov	di, bp				; return es:di

	.leave
	ret
CompressTreeBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandBranchLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	completely expands the given branch

CALLED BY:	INTERNAL
			TreeExpandBranch

PASS:		es:di - entry of branch to expand in locked tree buffer
		ds:si - instance data of Tree object
		selected folder should be es:di

RETURN:		carry clear if successful
		carry set if error
			ax = error code
		ds, si, bp preserved

DESTROYED:	es - may have moved in ReadSubDirBranch
			(no longer valid!)

PSEUDO CODE/STRATEGY:
		re-scan es:di and add its subdirectories to tree buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/18/89		Initial version
	brianc	9/28/89		new outline tree handling
				 - call ReadSubDirBranch to expand fully
	brianc	12/28/89	broke out ExpandLowCommon for
					ExpandOneLevelLow

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandBranchLow	proc	near
	mov	ax, mask RSDB_REMOVE		; remove collapsed branches
						; don't reselect
	call	ExpandLowCommon
	ret
ExpandBranchLow	endp

;
; pass:	ax = RSDB flag
;
ExpandLowCommon	proc	near
	class	TreeClass

	call	ShowHourglass
	push	bp
; ignore collapsed bit - always allow expanding branch, even if already
; expanded one level
; NOTE: must call DeleteAllChildren to support this
;	test	es:[di].TE_state, mask TESF_COLLAPSED	; collapsed?
;	jz	exit				; if not, no need to expand
	push	ax				; save RSDB flag
	call	DeleteAllChildren
						; mark as not collapsed
	andnf	es:[di].TE_state, not (mask TESF_COLLAPSED)
	mov	bx, ds:[si].TI_disk	; pass disk handle
	call	DeleteCollapsedPathname		; remove from collapsed list
	call	GetBranchLevel			; bp = level in tree
	call	SwapWithLastEntry		; move this branch to end
						;	of tree buffer
	mov	di, ds:[si].TI_treeBufferNext	; end of buffer
	sub	di, size TreeEntry		; last entry (branch to expand)
	pop	ax				; retrieve RSDB flag

	;
	; rescan this branch completely and add any of its subdirectories
	;		to tree buffer
	;	di = offset in tree buffer of entry for this branch
	;	bp = level of this branch
	;	ax = RSDB flag
	;
	mov	bx, ax				; pass RSDB flag
	call	ReadSubDirBranch		; read subdir, adding entire
						;	tree of subdirs to
						;	tree buffer
	jc	exit				; if error, exit with carry, AX
	call	SortHierarchy			; rebuild new tree
	jc	exit				; if error, exit with carry, AX
	push	ds, si
	call	TreeRedrawLow			; redraw ourselves
	pop	ds, si
exit:
	pop	bp
	call	HideHourglass			; preserves flags
	ret
ExpandLowCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapWithLastEntry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	ugly routine used to place the branch at the end of the
		tree buffer so that ReadSubDirBranch can be called to
		correctly add the entire tree rooted at this branch to
		the tree buffer


CALLED BY:	INTERNAL
			ExpandBranchLow

PASS:		es:di = branch to move to end
		ds:si = instance data of Tree object

RETURN:		this entry swapped with last entry
		ds:[si].TI_selectedFolder - updated if moved

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SwapWithLastEntry	proc	near
	class	TreeClass

	push	ax, bx, dx
	push	si
	mov	dx, ds:[si].TI_treeBufferNext	; dx = end of tree buffer
	mov	ax, dx
	sub	ax, size TreeEntry		; ax = last entry
	mov	bx, ds:[si].TI_selectedFolder	; bx = selected folder
	mov	si, ax				; di=this entry, si=last entry
	call	SwapTreeEntry			; swap 'em
	pop	si				; retrieve instance data
	mov	ds:[si].TI_selectedFolder, bx	; selected may have moved
	pop	ax, bx, dx
	ret
SwapWithLastEntry	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ExpandOneLevelLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	expand given branch

CALLED BY:	INTERNAL
			TreeExpandOneLevel
			TreeButton

PASS:		es:di - root of branch to expand in locked tree buffer
			(branch should be collapsed and tree display should
				be in outline mode)
		ds:si - instance data address of Tree object

RETURN:		carry clear if successful
		carry set if error
			ax = error code
		preserves bp

DESTROYED:	es - may have moved in ReadSubDirectory
			(no longer valid!)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/17/89		Initial version
	brianc	9/28/89		new outline tree handling
				 - call ReadSubDirectory to expand one level
	brianc	12/28/89	use ExpandLowCommon

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ExpandOneLevelLow	proc	near
	mov	ax, mask RSDB_REMOVE or mask RSDB_ONE_LEVEL_ONLY
						; remove collapsed branches
						; don't reselect
						; read only one level
	call	ExpandLowCommon			; do it
	ret
ExpandOneLevelLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBranchLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	simple routine to compute branch level (tree depth)
		of this branch

CALLED BY:	INTERNAL
			ExpandOneLevelLow
			ExpandBranchLow

PASS:		es:di = branch to get level of

RETURN:		bp = branch level

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBranchLevel	proc	near
	;
	; compute branch level, root is 0, its subdirs are 1, etc.
	;
	push	di
	mov	bp, -1				; root will be 0
GBL_loop:
	inc	bp
	mov	di, es:[di].TE_parentID		; get its parent
	cmp	di, NIL				; check if we went off the root
	jne	GBL_loop			; if not, loop
	pop	di
	ret
GetBranchLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCollapsedPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	stores the pathname of a collapsed branch into a permanent
		global buffer

CALLED BY:	INTERNAL
			CollapseBranchLow
			DeleteAllChildren
			CheckForAnySubdirs (ReadSubDirBranch)

PASS:		es:di - tree buffer entry of branch
		bx - disk handle of disk containing entry

RETURN:		ss:[collapsedBranchBuffer] - handle of buffer containing
			collapsed branches

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		check if branch is already in the branch buffer;
		if so, done;
		else, find free spot and save it;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveCollapsedPathname	proc	near
	push	ds, si, es, di
	push	bx				; save disk handle
	mov	dx, BDN_PATHNAME
	call	BuildDirName			; ss:dx = pathname
	push	ax				; ax = pathname size (with null)
NOFXIP<	segmov	ds, <segment idata>, si					>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
	mov	si, dx				; ds:si = this dir's pathname
	mov	bx, ss:[collapsedBranchBuffer]	; lock branch buffer
	call	MemLock
	mov	es, ax				; es = segment of branch buffer
	pop	ax				; ax = length for FindCol...
	pop	bx				; bx = disk handle for FindC...
	push	ds, si, ax, bx			; save pathname & length, disk
	call	FindCollapsedPathname		; check if already saved
	pop	ds, si, ax, bx			; retrieve pathname & len, disk
	jc	SCP_done			; if saved already, done
	clr	di				; else, find free spot for it
SCP_findLoop:
						; check if this is end of buffer
	cmp	di, ss:[collapsedBranchBufSize]
	je	SCP_addEntries			; if so, add more entries
	cmp	es:[di].CBE_size, 0		; check if this is empty entry
	jz	SCP_gotEmpty
	add	di, size CollapsedBranchEntry	; move to next one
	jmp	short SCP_findLoop		; go back to check it
	;
	; need to resize buffer to fit more entries
	;
SCP_addEntries:
	push	ax, bx				; save path length, disk han.
	mov	bx, ss:[collapsedBranchBuffer]	; buffer handle
	mov	ax, ss:[collapsedBranchBufSize]	; new size
	add	ax, (COLLAPSED_BRANCH_BUFFER_NUM_INCREMENT * size CollapsedBranchEntry)
	mov	ss:[collapsedBranchBufSize], ax	; save new size
	mov	ch, mask HAF_ZERO_INIT		; zero init, keep locked
	call	MemReAlloc			; updates segment addr (in AX)
	mov	cx, ax				; save new segment addr
	pop	ax, bx				; retrieve path length, disk
	jc	short SCP_done			; if error, don't add entry
	mov	es, cx				; else, set new segment addr
	jmp	short SCP_findLoop		; ...and find free spot & store
	;
	; found available entry
	;	es:di = empty entry
	;	ax = size of pathname
	;	bx = disk handle
	;
SCP_gotEmpty:
	mov	cx, ax				; cx = path size for "rep movsb"
	stosw					; save size of pathname
	mov	ax, bx				; ax = disk handle
	stosw					; save disk handle of pathname
	rep movsb				; copy pathname to branch buffer
						;	(with null-terminator)
SCP_done:
	mov	bx, ss:[collapsedBranchBuffer]	; unlock branch buffer
	call	MemUnlock
	pop	ds, si, es, di
	ret
SaveCollapsedPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteCollapsedPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	erase the pathname of an exapnded branch into a permanent
		global buffer

CALLED BY:	INTERNAL
			ExpandBranchLow

PASS:		es:di - tree buffer entry of branch
		bx - disk handle of disk containing entry

RETURN:		pathname of branch removed from collapsed branch buffer

DESTROYED:	preserves ds, si, es, di

PSEUDO CODE/STRATEGY:
		find the pathname entry in the collapsed branch buffer;
		zero out the size field of the entry to indicate free entry;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteCollapsedPathname	proc	near
	push	ds, si, es, di
	push	bx				; save disk handle
	mov	dx, BDN_PATHNAME
	call	BuildDirName			; ss:dx = pathname
	push	ax				; ax = pathname size (with null)
	mov	bx, ss:[collapsedBranchBuffer]	; lock branch buffer
	call	MemLock
	mov	es, ax				; es = segment of branch buffer
	pop	ax				; retrieve path size into AX
	pop	bx				; retrieve disk handle
	call	FindCollapsedPathname		; di = pathname entry
	jnc	DCP_done			; if not found, done
						; else, delete it
	mov	es:[di].CBE_size, 0		; clear size to indicate free
						;	entry
DCP_done:
						; unlock collapsed branch buffer
	mov	bx, ss:[collapsedBranchBuffer]
	call	MemUnlock
	pop	ds, si, es, di
	ret
DeleteCollapsedPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckCollapsedPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if this directory is a collapsed directory

CALLED BY:	INTERNAL
			TreeScan

PASS:		dgroup:dx - pathname of this directory
		ax - pathname size
		bx - disk handle of disk containing entry

RETURN:		carry set if this is a collapsed directory
		carry clear if this is NOT a collapsed directory

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckCollapsedPathname	proc	near
	push	ds, si, es, di
	push	bx				; save disk handle
	push	ax				; ax = pathname size (with null)
	mov	bx, ss:[collapsedBranchBuffer]	; lock branch buffer
	call	MemLock
	mov	es, ax				; es = segment of branch buffer
	pop	ax				; retrieve path size into AX
	pop	bx				; retrieve disk handle
	call	FindCollapsedPathname		; di = pathname entry
						; carry set if found
	pushf					; save results
						; unlock collapsed branch buffer
	mov	bx, ss:[collapsedBranchBuffer]
	call	MemUnlock
	popf					; retrieve results
	pop	ds, si, es, di
	ret
CheckCollapsedPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckDeleteCollapsedPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if this directory is a collapsed directory
		AND if so, delete it

CALLED BY:	INTERNAL
			ReadSubDirBranch

PASS:		dgroup:dx - pathname of this directory
		ax - pathname size
		bx - disk handle of disk containing entry

RETURN:

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckDeleteCollapsedPathname	proc	near
	push	ds, si, es, di
	push	bx				; save disk handle
	push	ax				; ax = pathname size (with null)
	mov	bx, ss:[collapsedBranchBuffer]	; lock branch buffer
	call	MemLock
	mov	es, ax				; es = segment of branch buffer
	pop	ax				; retrieve path size into AX
	pop	bx				; retrieve disk handle
	call	FindCollapsedPathname		; di = pathname entry
						; carry set if found
	jnc	CDCP_notFound			; if not found, skip
	mov	es:[di].CBE_size, 0		; clear size to indicate free
						;	entry
CDCP_notFound:
						; unlock collapsed branch buffer
	mov	bx, ss:[collapsedBranchBuffer]
	call	MemUnlock
	pop	ds, si, es, di
	ret
CheckDeleteCollapsedPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindCollapsedPathname
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	find the directory in the collapsed branch buffer

CALLED BY:	INTERNAL
			DeleteCollapsedPathname
			CheckCollapsedPathname

PASS:		dgroup:dx - pathname of this directory
		ax - size of pathname
		es - segment of locked collapsed branch buffer
		bx - disk handle of disk containing entry

RETURN:		carry set if this directory is in collapsed branch buffer
			es:di - collapsed branch buffer entry of this directory
		carry clear if this directory is NOT in collapsed branch buffer

DESTROYED:	ax, bx, cx, dx, ds, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindCollapsedPathname	proc	near
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
NOFXIP<	segmov	ds, <segment idata>, si					>
	mov	si, dx				; ds:si = this dir's pathname
	clr	di
FCP_findLoop:
						; check if end of buffer
	cmp	di, ss:[collapsedBranchBufSize]
	je	FCP_notFound			; if so, not found
	cmp	ax, es:[di].CBE_size		; check if this COULD BE match
						;	(compare lengths)
	jne	FCP_next			; if not, try next
	cmp	bx, es:[di].CBE_diskHandle	; check if this is same disk
	jne	FCP_next			; if not, try next
	push	ax, si, di			; save size and offsets
	add	di, offset CBE_pathname		; es:di - possible path match
	call	CompareString			; check if it is a match
	pop	ax, si, di			; retrieve size and offsets
	jne	FCP_next			; if not match, try next
	stc					; indicate match
	jmp	short FCP_gotMatch
FCP_next:
	add	di, size CollapsedBranchEntry	; move to next entry
	jmp	short FCP_findLoop		; go back to check it
FCP_notFound:
	clc					; indicate not found
FCP_gotMatch:
	ret
FindCollapsedPathname	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearCollapsedBranchBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clear all entries from this drive from collapsed
		pathname buffer

CALLED BY:	INTERNAL
			TreeExpandAll
			TreeShowOutline

PASS:		bx - disk handle

RETURN:

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearCollapsedBranchBuffer	proc	near
	push	ds, si, ax, bx, cx
	mov	cx, bx				; cx = disk handle
						; lock branch buffer
	mov	bx, ss:[collapsedBranchBuffer]
	call	MemLock
	mov	ds, ax				; es = segment of branch buffer
	clr	si
CCBB_findLoop:
						; check if end of buffer
	cmp	si, ss:[collapsedBranchBufSize]
	je	CCBB_done			; if so, done
	cmp	ds:[si].CBE_size, 0		; check if empty entry
	je	CCBB_next			; if so, try next
						; compare passed disk handle
						;	with disk handle stored
	cmp	cx, ds:[si].CBE_diskHandle
	jne	CCBB_next			; if not match, check next
	mov	ds:[si].CBE_size, 0		; else, delete entry
CCBB_next:
	add	si, size CollapsedBranchEntry	; move to next entry
	jmp	short CCBB_findLoop		; go back to check it
CCBB_done:
						; unlock collapsed branch buffer
	mov	bx, ss:[collapsedBranchBuffer]
	call	MemUnlock
	pop	ds, si, ax, bx, cx
	ret
ClearCollapsedBranchBuffer	endp


TreeCode ends


