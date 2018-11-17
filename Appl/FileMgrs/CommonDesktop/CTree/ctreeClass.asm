COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Tree
FILE:		treeClass.asm
AUTHOR:		Brian Chin

ROUTINES:
	EXT	TreeExposed - handle MSG_META_EXPOSED
	EXT	TreeDraw - handle MSG_TREE_DRAW
	EXT	TreeRedraw - handle MSG_TREE_REDRAW
	EXT	TreeStartSelect - handle MSG_META_START_SELECT
	EXT	TreePtr - handle MSG_META_PTR
	EXT	TreeEndSelect - handle MSG_META_END_SELECT
	EXT	TreeEndMoveCopy - handle MSG_META_END_MOVE_COPY
	EXT	TreeScan - handle MSG_TREE_SCAN (read new disk)
	EXT	TreeShowOutline - handle MSG_OUTLINE_TREE (show outline tree)
	EXT	TreeCollapseBranch - handle MSG_COLLAPSE_BRANCH
	EXT	TreeExpandOneLevel - handle MSG_EXPAND_ONE_LEVEL
	EXT	TreeExpandBranch - handle MSG_EXPAND_BRANCH
	EXT	TreeExpandAll - handle MSG_EXPAND_ALL
	EXT	TreeMarkBranchDirty - handle MSG_MARK_BRANCH_DIRTY
	EXT	TreeUpdateBranch - handle MSG_UPDATE_TREE
	EXT	TreeRelocate - handle MSG_META_RELOCATE
	EXT	TreeViewWinClosed - handle MSG_META_CONTENT_VIEW_WIN_CLOSED
	EXT	TreeSubviewOpened - handle MSG_META_CONTENT_VIEW_WIN_OPENED
	;
	; file operations on directories in Tree Window
	;
	EXT	TreeOpenSelectList - handle MSG_OPEN_SELECT_LIST
	EXT	TreeStartRename - handle MSG_FM_START_RENAME
	EXT	TreeStartDeleteThrowAway - handle MSG_FM_START_DELETE,
						MSG_FM_START_THROW_AWAY
	EXT	TreeStartCreateDir - handle MSG_FM_START_CREATE_DIR
	EXT	TreeStartMove - handle MSG_FM_START_MOVE
	EXT	TreeStartRecover - handle MSG_FM_START_RECOVER
	EXT	TreeStartCopy - handle MSG_FM_START_COPY
	EXT	TreeStartDuplicate - handle MSG_FM_START_DUPLICATE
	EXT	TreeStartChangeAttr - handle MSG_FM_START_CHANGE_ATTR
	INT	TreeStartFileOperation - common code for starting
				file operations from TreeWindow

	INT	DrawTreeFolderIcon - draw one icon/name pair in tree display
	INT	DrawConnectionToParent - draw lines in tree directory display
	INT	GetTreeFolderClicked - get subdirectory icon clicked on

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/89		Initial version
	brianc	8/16/89		changed to subclass of DeskVis class
	brianc	8/17/89		added support for outline tree stuff
	brianc	9/28/89		changes for new outline tree handling
	brianc	11/2/89		subclass of Meta again, for splitting support

DESCRIPTION:
	This file contains directory tree display object.

	$Id: ctreeClass.asm,v 1.2 98/06/03 13:47:32 joon Exp $

------------------------------------------------------------------------------@

TreeCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Tree{Gain,Lost}Target
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	enable/disable Tree Menu items

CALLED BY:	MSG_{GAINED,LOST}_TARGET_EXCL

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeGainTarget	method	TreeClass, MSG_META_GAINED_TARGET_EXCL
	;
	; update LRU table
	;
	push	bx, si
	mov	bx, handle TreeWindow		; bx:si = Tree Window
	mov	si, offset TreeWindow
	call	UpdateWindowLRUStatus
	pop	bx, si
	;
	; enable Tree Window-related stuff
	;
	mov	ax, MSG_GEN_SET_ENABLED
	call	TreeTargetCommon
	ret
TreeGainTarget	endm

TreeLostTarget	method	TreeClass, MSG_META_LOST_TARGET_EXCL
	;
	; check if we lost target within display control
	;
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_META_GET_TARGET_EXCL
	call	ObjMessageCallFixup		; cx:dx = target
	cmp	cx, handle TreeWindow		; could it be us?
	jne	reallyLostTarget		; nope
	cmp	dx, offset TreeWindow
	je	stillDCTarget			; yes, no disabling
reallyLostTarget:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	TreeTargetCommon
stillDCTarget:
	ret
TreeLostTarget	endm

TreeTargetCommon	proc	near
	mov	cx, NUM_TREE_TARGET_ITEMS
	clr	di
commonLoop:
	push	ax, cx, di
	mov	bx, cs:[di][targetTable].handle
	mov	si, cs:[di][targetTable].chunk
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	pop	ax, cx, di
	add	di, size optr
	loop	commonLoop

	cmp	ax, MSG_GEN_SET_ENABLED	; gain target?
	jne	noView				; nope

if INSTALLABLE_TOOLS
	;
	; update list of installed tools if gained target (something's always
	; selected in the tree).
	;
	mov	cx, TRUE	
	mov	bx, handle ToolGroup
	mov	si, offset ToolGroup
	mov	ax, MSG_TM_SET_FILE_SELECTION_STATE
	call	ObjMessageCallFixup
endif
	;
	; disable view menu if tree gained target
	;
	mov	cx, length targetViewTable
	clr	di
viewLoop:
	push	cx, di
	mov	bx, cs:[di][targetViewTable].handle
	mov	si, cs:[di][targetViewTable].offset
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	pop	cx, di
	add	di, size optr
	loop	viewLoop
noView:
	ret
TreeTargetCommon	endp

;
; the following are enabled/disabled depending on target gain/loss
;
targetTable	optr	\
	TreeMenuExpandAll,
	TreeMenuExpandOneLevel,
	TreeMenuExpandBranch,
	TreeMenuCollapseBranch,
	FileMenuOpen,
	FileMenuGetInfo,
	FileMenuCreateFolder,
	FileMenuMove,
	FileMenuCopy,
	FileMenuDuplicate,
	FileMenuDelete,
	FileMenuChangeAttr,
	FileMenuRename
ifdef CREATE_LINKS
	optr	FileMenuCreateLink
endif
if not _FORCE_DELETE
	optr	FileMenuThrowAway
endif

NUM_TREE_TARGET_ITEMS = ($-targetTable)/(size optr)

;
; the following are disabled on target gain
;
targetViewTable	optr	\
	DisplayViewModesSub,
	DisplayViewModes,
	DisplaySortBy,
	DisplaySortByList,
	DisplayOptions,
	DisplayOptionsList,
	FileMenuSelectAll,
	FileMenuDeselectAll


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeExposed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw tree object

CALLED BY:	MSG_META_EXPOSED

PASS:		ds:si - instance
		cx - window handle

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeExposed	method	TreeClass, MSG_META_EXPOSED
	mov	bp, ds:[si]			; deref.
	mov	di, cx				; di = window
	call	GrCreateState 		; create GState for window
	mov	cx, ss:[desktopFontID]
	mov	dx, ss:[desktopFontSize]
	clr	ah				; no fractional part
	call	GrSetFont
	call	GrBeginUpdate
	push	di
	mov	bp, di				; pass GState in bp
	call	TreeDraw
	pop	di
	call	GrEndUpdate
	call	GrDestroyState 		; clobber GState
	ret
TreeExposed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draws directory tree

CALLED BY:	MSG_TREE_DRAW

PASS:		ds:si - handle of TreeClass instance data
			ds:[si].TI_treeBuffer - handle of tree buffer
		es - segment of TreeClass
		bp - gState with proper font/size set up

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version
	brianc	8/17/89		displayList added to support outline tree stuff
	brianc	9/28/89		displayList removed, used TSEF_DELETED

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeDraw	method	TreeClass, MSG_TREE_DRAW
	test	ds:[bx].TI_displayMode, mask TIDM_BOGUS
	jnz	notActive
	;
	; ensure that tree has been scanned
	;
	mov	di, ds:[si]
	test	ds:[di].TI_displayMode, mask TIDM_SCANNED
	jnz	scanned
	push	bp				; save gState
	mov	ax, MSG_TREE_RESCAN		; rescan tree
	call	ObjCallInstanceNoLock
	pop	bp				; retrieve gState
scanned:
	mov	si, ds:[si]			; deref.
	test	ds:[si].TI_displayMode, mask TIDM_BOGUS	; will be closed?
	jnz	notActive
	cmp	ds:[si].TI_treeBuffer, 0
	je	notActive
	;
	; update tree menu drive list
	;
	mov	cx, ds:[di].TI_drive		; cx = drive number
	call	EnsureTreeMenuDrive		; update tree menu drive list
	;
	; draw
	;
	call	LockTreeBuffer			; lock tree buffer
	push	bx				; save handle
	mov	es, ax				; ds = segment of tree buffer
	mov	di, bp				; get GState
	call	GrGetMaskBounds			; get drawing area (bx, dx)
	clr	di				; es:di = first entry
TD_loop:
	test	es:[di].TE_state, mask TESF_DELETED	; deleted?
	jnz	TD_noDraw			; if so, skip
	cmp	es:[di].TE_boundBox.R_bottom, bx	; icon above window?
	jl	TD_noDraw			; if so, don't draw
	cmp	es:[di].TE_boundBox.R_top, dx	; icon below window?
	jg	TD_drawLines			; if so, just draw lines
	push	bx, dx				; save drawing bounds
	mov	ax, DTI_CLEAR_AND_DRAW		; clear and draw icon
	call	DrawTreeFolderIcon		; draw icon/name for this folder
	pop	bx, dx
TD_drawLines:
	;
	; branch lines must be drawn since they can extend anywhere above
	; the icon in question
	;
	push	bx, dx
	call	DrawConnectionToParent		; draw branch lines
	pop	bx, dx
TD_noDraw:
	add	di, size TreeEntry		; move to next entry
	cmp	di, ds:[si].TI_treeBufferNext	; end of buffer?
	jne	TD_loop				; if not, loop
	pop	bx				; retreive tree buffer handle
	call	MemUnlock			; unlock it
notActive:
	ret
TreeDraw	endp

;
; pass:
;	cx = drive number (0-based)
; return:
;	nothing
; destory:
;	nothing
;
EnsureTreeMenuDrive	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter
	mov	al, cl				; ax = drive #
	call	DriveGetDefaultMedia		; ah = media
	mov	cx, ax				; cx = identifier
	mov	bx, handle TreeMenuDriveList
	mov	si, offset TreeMenuDriveList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageFixup
	.leave
	ret
EnsureTreeMenuDrive	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	redraw all subviews

CALLED BY:	MSG_TREE_REDRAW

PASS:		ds:si - instance

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeRedraw	method	TreeClass, MSG_TREE_REDRAW
	mov	si, ds:[si]
	cmp	ds:[si].TI_treeBuffer, 0
	je	notActive
	call	TreeRedrawLow
notActive:
	ret
TreeRedraw	endp

TreeRedrawLow	proc	near
	class	TreeClass

	mov	cx, VIEW_MAX_SUBVIEWS
	clr	bx
TRL_loop:
	mov	di, ds:[si][bx].TI_gStates	; get one of subview
	tst	di				; anything there?
	jz	TRL_noWindow			; if not, do next
	push	bx, cx				; save counters
	push	ds:[si][bx].TI_subviews		; save associated window
	call	GrGetWinBounds			; ax, bx, cx, dx = bounds
	sub	cx, ax				; convert to win. coords.
	sub	dx, bx
	clr	ax
	mov	bx, ax
	mov	bp, ax				; bp = 0 -> rect. region
	pop	di
	call	WinInvalReg			; invalidate to force redraw
	pop	bx, cx				; restore counters
TRL_noWindow:
	add	bx, 2
	loop	TRL_loop			; do next subview
	ret
TreeRedrawLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTreeFolderIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw folder icon in tree display

CALLED BY:	INTERNAL
			TreeStartSelect
			ExposeTreeIcon

PASS:		es:di - pointer to entry in tree buffer for this folder
		ds:si - instance data of Tree object
		bp - gState to draw with (desktop font set)
		ax =	DTI_CLEAR_ONLY if only clear
			DTI_DRAW_ONLY if only draw
			DTI_CLEAR_AND_DRAW if clear then draw
			DTI_INVERT_ONLY if only inverting

RETURN:		ds, es, si, di, bp unchanged

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		if (not DTI_DRAW_ONLY) {
			clear name area;
			clear icon area;
		}
		if (not DTI_CLEAR_ONLY) {
			draw name;
			draw icon;
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/20/89		Broken out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTreeFolderIcon	proc	near
	class	TreeClass

	push	ds, si
	xchg	di, bp				; di = gState, bp = entry
	;
	; check if doing less than complete redraw (invert only or draw only)
	;
	cmp	ax, DTI_INVERT_ONLY		; check if inverting only
	LONG je	DTI_invertOnly			; if so, do it

	push	ax				; save flag
	cmp	ax, DTI_DRAW_ONLY		; check if draw only
	je	DTI_drawOnly			; if so, skip clearing
	;
	; get bounds and white name and icon areas
	;
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetAreaColor
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline?
	jz	DTFI_noEraseOutline				; if not, skip
	test	es:[bp].TE_state, mask TESF_PARENT	; check if a parent
	jz	DTFI_noEraseOutline		; if not, don't erase
	mov	ax, es:[bp].TE_iconBounds.R_left
	mov	bx, es:[bp].TE_iconBounds.R_top
	mov	cx, es:[bp].TE_iconBounds.R_right
	mov	dx, es:[bp].TE_iconBounds.R_bottom
	call	GrFillRect			; white out icon area
DTFI_noEraseOutline:
	mov	ax, es:[bp].TE_nameBounds.R_left
	mov	bx, es:[bp].TE_nameBounds.R_top
	mov	cx, es:[bp].TE_nameBounds.R_right
	mov	dx, es:[bp].TE_nameBounds.R_bottom
	call	GrFillRect			; white out name area
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor			; restore drawing color
DTI_drawOnly:
	;
	; check if clear AND draw 
	;
	pop	ax				; restore flag
	cmp	ax, DTI_CLEAR_ONLY		; check if clearing only
	je	DTI_clearOnly			; if so, done
	;
	; get icon position and draw icon, if in outline mode
	;
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline?
	jz	DTFI_noDrawOutline				; if not, skip
	test	es:[bp].TE_state, mask TESF_PARENT	; check if a parent
	jz	DTFI_noDrawOutline		; if not, don't draw
	mov	ax, es:[bp].TE_iconBounds.R_top	; get icon position
	mov_trash	bx, ax
	mov	ax, es:[bp].TE_iconBounds.R_left
	call	GetTreeFolderIcon		; ds:si = icon for this object
	clr	dx				; no callback
	call	GrFillBitmap			; draw icon
	;
	; For XIP, we have to release the stack space which is borrowed
	; inside the GetTreeFolderIcon().
	;
FXIP <	call	SysRemoveFromStack				>
DTFI_noDrawOutline:
	;
	; set underline if remote file
	;
	test	ss:[desktopFeatures], mask DF_SHOW_REMOTE
	jz	notRemote
	test	es:[bp].TE_attrs.TA_pathInfo, mask DPI_ENTRY_NUMBER_IN_PATH
	jz	notRemote
	mov	ax, mask TS_UNDERLINE		; set underline
	call	GrSetTextStyle
notRemote:
	;
	; get name position and draw
	;
	mov	bx, es:[bp].TE_nameBounds.R_top	; Y coord.
	mov	ax, es:[bp].TE_nameBounds.R_left; X coord.
	call	GetTreeFolderName		; ds:si = name of this object
	;
	; copy name to stack buffer so it can be converted to GEOS character
	; set
	;	ds:si = name
	;	ax, bx = coords to draw name at
	;	di = GState
	;	es:bp = TreeEntry to draw
	;
	clr	cx				; null-terminated name
	call	GrDrawText
	;
	; clear underline (remote flag)
	;
	mov	ax, (mask TS_UNDERLINE) shl 8	; clear underline
	call	GrSetTextStyle

	test	es:[bp].TE_state, mask TESF_SELECTED	; check if selected
	jz	DTI_notSelected			; if not, skip inverting
DTI_invertOnly:
	mov	bx, es:[bp].TE_nameBounds.R_top		; get name bounds
	mov	cx, es:[bp].TE_nameBounds.R_right
	mov	dx, es:[bp].TE_nameBounds.R_bottom
	mov	al, MM_INVERT
	call	GrSetMixMode
	mov	ax, es:[bp].TE_nameBounds.R_left	; get name bounds (left)
	call	GrFillRect			; invert it to show selected
	mov	al, MM_COPY
	call	GrSetMixMode			; restore mode
DTI_notSelected:
DTI_clearOnly:
	xchg	di, bp				; di = entry, bp = gState
	pop	ds, si
	ret
DrawTreeFolderIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawConnectionToParent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draws the "L" shaped connecting line between a folder
		and its parent

CALLED BY:	INTERNAL
			TreeDraw

PASS:		es:di - address of treeBuffer entry of this folder
		bp - graphics state
		ds:si - instance data of Tree object

RETURN:		preserves ds, es, di, bp, si

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		get parent folder;
		draw vertical line from parent down to us;
		draw horizontal line from parent across to us;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawConnectionToParent	proc	near
	class	TreeClass

	push	bp, di
	xchg	di, bp				; di = gState, bp = entry
	mov	bx, es:[bp].TE_parentID		; bx = parent of this directory
	cmp	bx, NIL				; check if this is root
	je	DCTP_done			; if so, no connection to draw
	;
	; es:bp - this folder
	; es:bx - parent folder
	;
	; draw vertical line
	;
	mov	ax, es:[bx].TE_boundBox.R_left	; left of parent
	add	ax, TREE_OUTLINE_ICON_WIDTH/2 - 1	; X-center of parent
	mov	bx, es:[bx].TE_boundBox.R_bottom	; bottom of parent
	inc	bx				; fine tune
	mov	dx, es:[bp].TE_boundBox.R_top	; top of ourselves
	mov	cx, es:[bp].TE_boundBox.R_bottom	; bottom of ourselves
	sub	cx, dx				; our height
	shr	cx, 1				; half height
	add	dx, cx				; Y-center of ourselves
	call	GrDrawVLine
	;
	; draw horizontal line
	;
	mov	bx, dx
	mov	cx, es:[bp].TE_boundBox.R_left	; left of ourselves
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline mode?
	jz	DCTP_shortLine			; if not, short horiz. line
	test	es:[bp].TE_state, mask TESF_PARENT	; am I a parent?
	jnz	DCTP_shortLine			; if so, short horiz. line
						; else, draw ling horiz. line
	add	cx, TREE_OUTLINE_ICON_WIDTH + TREE_OUTLINE_ICON_HORIZ_SPACING
DCTP_shortLine:
	sub	cx, 3				; fine tune
	call	GrDrawHLine
DCTP_done:
	pop	bp, di
	ret
DrawConnectionToParent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Tree{Start,End}Select
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If user single-clicks on a folder icon, highlight it.
		If user double-clicks on folder icon, open window to
		show contents.

CALLED BY:	MSG_META_START_SELECT

PASS:		ds:si - handle of instance of Tree
		es - segment of TreeClass
		cx - X coord of press
		dx - Y coord of press
		bp - button info

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/14/89		Initial version
	brianc	8/3/89		modified to use icon/name bounds
	brianc	12/22/89	changed to allow direct manipulation
				with directory tree

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartSelect	method	TreeClass, MSG_META_START_SELECT
	mov	ss:[treeDragging], 0		; init dragging flag
	;
	; check if any directory clicked on
	;
	mov	si, bx				; deref. instance handle
	call	LockTreeBuffer
	push	bx				; save tree buffer handle
	mov	es, ax				; pass segment of tree buffer
	call	GetTreeFolderClicked		; get folder clicked on, if any
	jnc	done				; if none, done
	;
	; if position contains a folder, handle press
	;
	push	bp				; save button info
	push	ax				; save click on icon/name flag
	call	ToggleTreeSelection		; update visually
	pop	ax
	cmp	ax, CLICKED_ON_NAME		; check if clicked on name
	pop	bp				; retrieve button info
	je	nameClick			; if click-on-name, handle it
	;
	; clicked on outline tree icon, either collapse branch or expand branch
	;
	test	bp, mask BI_DOUBLE_PRESS	; check if double-click
	jnz	done				; yes, ignore it
	test	es:[di].TE_state, mask TESF_COLLAPSED	; check if collapsed
	jz	collapseIt			; if not, then collapse it
	call	ExpandOneLevelLow		; else, expand it
checkAndHandleErr:
	jnc	done				; if no error, done
	call	TreeMemError			; else, report error
						;	(ds:si = TreeInstance)
	jmp	short done

collapseIt:
	call	CollapseBranchLow		; collapse branch
	jmp	short checkAndHandleErr

nameClick:
	test	bp, mask BI_DOUBLE_PRESS	; check if double-click
	jnz	double				; if so, open folder
						; single click, allow double
	andnf	ds:[si].TI_displayMode, not mask TIDM_DISALLOW_DOUBLE
	jmp	short done			; do no more, already selected

double:
	test	ds:[si].TI_displayMode, mask TIDM_DISALLOW_DOUBLE
	jnz	done				; no double-clicks allowed
						; no double-clicks until single
	ornf	ds:[si].TI_displayMode, mask TIDM_DISALLOW_DOUBLE
	call	TreePreOpenFolder		; bop us into overlapping mode
	call	OpenTreeFolder			; then, open folder
done:
	pop	bx				; retreive tree buffer handle
	call	MemUnlock			; unlock tree buffer
	mov	ax, mask MRF_PROCESSED
	ret
TreeStartSelect	endm

ToggleTreeSelection	proc	near
	class	TreeClass
	.enter

	push	di				; save newly-clicked folder
	xchg	di, ds:[si].TI_selectedFolder	; make this the selected folder
	andnf	es:[di].TE_state, not (mask TESF_SELECTED)	; unselect last
	mov	ax, DTI_INVERT_ONLY
	call	ExposeTreeFolderIcon		; update last-one on screen
	pop	di				; restore newly-clicked folder
	ornf	es:[di].TE_state, mask TESF_SELECTED	; select it
	mov	ax, DTI_INVERT_ONLY
	call	ExposeTreeFolderIcon		; update it on screen
	call	SetDirectoryTreePathname	; show new pathname

	.leave
	ret
ToggleTreeSelection	endp

TreePreOpenFolder	proc	near
if 0	; do nothing - 7/16/90
	uses	si, di
	.enter
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_DISP_CTRL_SET_OVERLAPPING
	call	ObjMessageCallFixup
	.leave
endif
	ret
TreePreOpenFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start direct manipulation

CALLED BY:	MSG_META_START_MOVE_COPY

PASS:		mouse stuff
		object stuff

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/19/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartMoveCopy	method	TreeClass, MSG_META_START_MOVE_COPY
	mov	ss:[treeDragging], 0		; init flags
	;
	; check if any directory clicked on
	;
	mov	si, bx				; deref. instance handle
	call	LockTreeBuffer
	push	bx				; save tree buffer handle
	mov	es, ax				; passed segment of tree buffer
	call	GetTreeFolderClicked		; get folder clicked on, if any
	LONG jnc	done			; if none, done
	;
	; allocate ClipboardStartQuickTransfer parameter block on stack
	;
	push	di				; save clicked-on folder
	push	si				; save instance data offset
	sub	sp, size ClipboardQuickTransferRegionInfo	; alloc. params
	mov	bp, sp				; ss:bp = params
	call	GetTreeDriverStrategy		; ax:bx = driver strategy
	mov	ss:[bp].CQTRI_strategy.high, ax
	mov	ss:[bp].CQTRI_strategy.low, bx
	mov	ss:[bp].CQTRI_region.high, handle DragIconResource
	mov	ss:[bp].CQTRI_region.low, offset folderIconRegion
	;
	; get click position in screen coords
	;
	push	bp				; save SQRS_* frame
	push	cx, dx				; save mouse click position
	mov	bx, handle TreeView		; get focus subview window
	mov	si, offset TreeView
	mov	ax, MSG_GEN_VIEW_GET_WINDOW	; get window handle
	call	ObjMessageCallFixup		; in cx
	mov	di, cx				; di = window
	call	GrCreateState
	pop	ax, bx				; retrieve mouse click position
	call	GrTransform		; doc -> screen coords
	call	GrDestroyState
	pop	bp				; ss:bp = SQRS_* frame
	mov	cx, ax				; cx, dx = screen mouse coords
	mov	dx, bx
	sub	ax, DRAG_REGION_WIDTH/2
	sub	bx, DRAG_REGION_HEIGHT/2
	mov	ss:[bp].CQTRI_regionPos.P_x, ax	; mouse position (screen coord)
	mov	ss:[bp].CQTRI_regionPos.P_y, bx
	;
	; start UI part of quick move/copy
	;	cx, dx = mouse position in screen coords
	;
	mov	bx, handle DragIconResource	; lock icon region resource
	call	MemLock		;	to ensure in-memory
	mov	si, mask CQTF_USE_REGION		; use region
	mov	ax, CQTF_MOVE			; initial cursor
	call	ClipboardStartQuickTransfer
	lahf					; save result
	call	MemUnlock			; unlock region block
						;	(preserves flags)
						; restore stack pointer
						;	(preserves flags)
	lea	sp, ss:[bp]+(size ClipboardQuickTransferRegionInfo)
	pop	si				; retrieve instance data offset
	pop	di				; (es:di = clicked-on folder)
	jc	done		; quick-transfer already in progress, done
				;	(cursor & region not started)
						; else, feeback cursor active
	ornf	ds:[si].TI_displayMode, mask TIDM_FEEDBACK_ON
	;
	; direct manipulation with clicked-on folder begun successfully
	;
	ornf	ss:[treeDragging], mask TDF_MOVECOPY	; flag it
	;
	; create and register transfer item
	;	ds:si = tree instance
	;	es:di = clicked-on folder (in tree buffer)
	;
	call	GenerateTreeDragItem		; bx:ax = VM block handle of
						;	transfer item
	mov	bp, mask CIF_QUICK
	call	ClipboardRegisterItem
;no error returned for quick-transfer
;	jc	error				; handle error
	;
	; successfully started quick-transfer, allow mouse to roam all over
	; for quick-transfer destination
	;
	mov	bx, handle TreeView		; bx:si = our View
	mov	si, offset TreeView
	mov	ax, MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
;	jmp	short done
;
;error:
;	;
;	; handle registering error (not enough memory)
;	;
;	mov	bx, si				; pass ds:bx = instance data
;	call	TreeStopQuickTransferFeedback
;	mov	ax, ERROR_INSUFFICIENT_MEMORY
;	call	DesktopOKError			; report error
;	andnf	ss:[treeDragging], not mask TDF_MOVECOPY	; unflag it
done:
	pop	bx
	call	MemUnlock			; unlock tree buffer
	mov	ax, mask MRF_PROCESSED
	ret
TreeStartMoveCopy	endm

GetTreeDriverStrategy	proc	far
	uses	cx, dx, ds, si, bp, di
	.enter
	mov	bx, handle TreeUI
	mov	si, offset TreeUI:TreeWindow
	mov	ax, MSG_VIS_VUP_QUERY
	mov	cx, VUQ_VIDEO_DRIVER
	call	ObjMessageCall			; ax = handle
	mov	bx, ax
	call	GeodeInfoDriver			; ds:[si] = DriverInfoStruct
	mov	ax, ds:[si].DIS_strategy.segment
	mov	bx, ds:[si].DIS_strategy.offset
	.leave
	ret
GetTreeDriverStrategy	endp

;
; needed because View has 'grabWhilePressed' set and grabs on both
; MSG_META_START_MOVE_COPY and MSG_META_DRAG_MOVE_COPY, so we want to make
; sure that it is released
;
TreeDragMoveCopy	method	TreeClass, MSG_META_DRAG_MOVE_COPY
	test	ss:[treeDragging], mask TDF_MOVECOPY
	jz	done
	mov	bx, handle TreeView		; bx:si = our View
	mov	si, offset TreeView
	mov	ax, MSG_GEN_VIEW_ALLOW_GLOBAL_TRANSFER
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
done:
	ret
TreeDragMoveCopy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreePtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle PTR events (provide feedback for quick-transfer)

CALLED BY:	MSG_META_PTR

PASS:		*ds:si  TreeObject
		cx - X position of mouse, in doc coords of receiving object
		dx - Y position of mouse, in doc coords of receiving object
		bp low  - ButtonInfo
		bh high - UIFunctionsActive

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/14/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreePtr	method	TreeClass, MSG_META_PTR
	.enter

	test	ds:[bx].TI_displayMode, mask TIDM_BOGUS
	jnz	done
	test	bp, mask UIFA_MOVE_COPY shl 8	; possible quick-transfer?
	jz	done				; nope
	call	ClipboardGetQuickTransferStatus	; quick-transfer in progress?
	jz	done				; nope
	mov	si, bx				; save instance data offset
	call	CheckQuickTransferType		; check if CIF_FILES supported
						;	(bx = true disk handle
						;	 ax = remote flag)
	jnc	supported
	mov	ax, CQTF_CLEAR			; not supported, so 
	jc	haveCursor			;   clear cursor
	
supported:
	tst	ax
	mov	ax, CQTF_COPY			; copy if source is remote
	jnz	haveCursor

	push	bx				; save source true diskhandle
	call	LockTreeBuffer
	mov	es, ax				; es is segment of tree buffer
	call	GetTreeFolderClicked		; es:di = tree folder
	mov	dx, es:[di].TE_attrs.TA_pathInfo
	test	dx, mask DPI_EXISTS_LOCALLY
	jz	destSet				; doesn't matter what disk is, 
						;   the file is remote
	mov	cx, es:[di].TE_attrs.TA_trueDH
	cmp	cx, -1				; is dest true diskhandle set?
	jne	destSet				;  if not, set it
	call	TreePtrGetTrueDiskHandle	; cx is diskhandle
	mov	es:[di].TE_attrs.TA_trueDH, cx	
destSet:
	call	UnlockTreeBuffer
	pop	bx				; restore source true diskhandle

	mov	ax, CQTF_COPY			; copy if destination is remote
	test	dx, mask DPI_EXISTS_LOCALLY
	jnz	haveCursor

	mov	ax, CQTF_MOVE			; default to move
	cmp	bx, cx				; are these the same disk?
	je	haveCursor			; move if they are on same disk

	mov	ax, CQTF_COPY			; copy if on different disks

haveCursor:
	call	ClipboardSetQuickTransferFeedback	; pass bp
	ornf	ds:[si].TI_displayMode, mask TIDM_FEEDBACK_ON
done:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE

	.leave
	ret
TreePtr	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreePtrGetTrueDiskHandle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the true diskhandle of a directory in the tree buffer.

CALLED BY:	TreePtr

PASS:		ds:si  TreeObject instance data
		es:di  TreeEntry pointer in Tree buffer

RETURN:		cx - true diskhandle of this directory

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/17/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreePtrGetTrueDiskHandle	proc	near
	class	TreeClass
	uses	ax, bx, cx, dx, di, si, ds, es
	.enter

	mov	dx, BDN_PATHNAME
	call	BuildDirName		; dgroup:dx is path
	mov	bx, ds:[si].TI_disk	; bx is diskhandle
NOFXIP<	segmov	ds, <segment idata>, ax					>
FXIP<	mov_tr	ax, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov_tr	bx, ax							>
	mov	si, dx			; bx, ds:si is full path
	clr	dx			; no <drivename:> requested
	segmov	es, ss, di
	mov	cx, size PathName
	sub	sp, cx
	mov	di, sp			; es:di points to temp stack buffer
	call	FileConstructActualPath
			; if an error occurs here, there isn't much we can do
	add	sp, size PathName
	mov	cx, bx			; return true diskhandle in cx

	.leave
	ret
TreePtrGetTrueDiskHandle	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStopQuickTransferFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL -
		clear move/copy cursor if doing quick transfer

CALLED BY:	MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL

PASS:		*ds:si  TreeObject
		cx - X position of mouse, in doc coords of receiving object
		dx - Y position of mouse, in doc coords of receiving object
		bp low  - ButtonInfo
		bh high - UIFunctionsActive

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/02/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStopQuickTransferFeedback	method	TreeClass, \
					MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL
	test	ds:[bx].TI_displayMode, mask TIDM_FEEDBACK_ON
	jz	done
	mov	ax, CQTF_CLEAR
	call	ClipboardSetQuickTransferFeedback
	andnf	ds:[bx].TI_displayMode, not mask TIDM_FEEDBACK_ON
done:
	ret
TreeStopQuickTransferFeedback	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeQuitQuickTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	abort quick transfer if we are the source because the
		View is closing up

CALLED BY:	MSG_META_CONTENT_VIEW_CLOSING

PASS:		

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/13/91	Update for 2.0 quick-transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeQuitQuickTransfer	method	TreeClass, MSG_META_CONTENT_VIEW_CLOSING
	;
	; end direct manipulation
	;
	test	ss:[treeDragging], mask TDF_MOVECOPY	; in progress?
	mov	ss:[treeDragging], 0
	jz	done				; if not, do nothing
	;
	; tell 'em we are done
	;
	call	ClipboardAbortQuickTransfer	; abort quick move/copy
done:
	ret
TreeQuitQuickTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateTreeDragItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	build quick transfer stuff for Tree Window

CALLED BY:	INTERNAL
			TreeStartMoveCopy

PASS:		ds:si - Tree object instance data
		es:di - tree folder to generate drag item for

RETURN:		bx:ax - VM block handle of transfer item

DESTROYED:	bx, cx, dx, es, si, di, bp
		(preserves ds, si)

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/18/90	header comment header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenerateTreeDragItem	proc	near
	class	TreeClass

	uses	ds, si
	.enter

	mov	ss:[treeDragSource], di		; save dragging folder
	tst	di				; is it root directory?
	jz	rootDir				; yes
	mov	di, es:[di].TE_parentID		; else, get parent
rootDir:
	mov	dx, BDN_PATHNAME
	call	BuildDirName			; dgroup:dx = root or parent
						;		pathname
	;
	; allocate block for root or parent pathname
	;
	mov	cx, size FileOperationInfoEntry + size FileQuickTransferHeader
	call	ClipboardGetClipboardFile	; bx = UI's transfer VM file
	call	VMAlloc				; ax = transfer VM block handle
	push	ax				; save transfer VM block handle
	call	VMLock				; ax = segment, bp = mem handle
	pop	bx				; bx = transfer VM block handle
	;
	; save parent pathname (or root) in file quick transfer header
	;
	push	ds:[si].TI_disk	; save disk handle
	push	es				; save tree buffer segment
	mov	es, ax				; es:di = path buf. in header
	mov	di, offset FQTH_pathname
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
NOFXIP<	segmov	ds, dgroup, si						>
	mov	si, dx				; ds:si = pathname of dir.
	mov	cx, size PathName
	rep movsb				; copy over pathname
	pop	ds				; ds = segment of tree buffer
	;
	; setup rest of header
	;
	mov	es:[FQTH_nextBlock], 0		; no next transfer data block
	mov	es:[FQTH_UIFA], 0		; no flags yet
	pop	ax
	mov	es:[FQTH_diskHandle], ax	; source disk handle
	call	ShellGetTrueDiskHandleFromFQT
	push	cx				; save true diskhandle
	mov	es:[FQTH_numFiles], 1		; only one file - selected dir.
	;
	; add name of selected directory to file quick transfer buffer
	;
	mov	si, ss:[treeDragSource]		; get dragging folder
	add	si, offset TE_attrs.TA_name	; ds:si = dir's name
						;	(or C:\ for root)
						; es:di = buffer for name
	mov	di, size FileQuickTransferHeader + offset FOIE_name

	;
	; Fetch path info into AX (will use it later) 
	;

	mov	ax, ds:[si].TA_pathInfo

	mov	cx, size FOIE_name + size FOIE_type + size FOIE_attrs \
			+ size FOIE_flags + size FOIE_pathInfo

	CheckHack <offset FOIE_name eq offset TA_name>
	CheckHack <offset FOIE_type eq offset TA_type>
	CheckHack <offset FOIE_attrs eq offset TA_attrs>
	CheckHack <offset FOIE_flags eq offset TA_flags>
	CheckHack <offset FOIE_pathInfo eq offset TA_pathInfo>
	CheckHack <size FOIE_pathInfo eq size TA_pathInfo>

	rep 	movsb

	clr	cx				; assume local
	test	ax, mask DPI_EXISTS_LOCALLY
	jnz	haveFlag
	dec	cx				; remote
haveFlag:
	push	cx				; save remote flag
	call	VMUnlock			; unlock path. block (pass bp)
	push	bx				; save its VM block handle
	;
	; build TransferItem
	;
	mov	cx, size ClipboardItemHeader
	call	ClipboardGetClipboardFile	; bx = UI's transfer VM file
	call	VMAlloc				; ax = VM block handle
	push	ax				; save it
	call	VMLock				; ax = segment, bp = mem handle
	mov	es, ax
	pop	ax				; ax = transfer VM block handle
	mov	cx, handle DesktopUI		; our block handle (owner)
	mov	es:[CIH_owner].handle, cx
	mov	es:[CIH_owner].chunk, offset DesktopUI:TreeObject
	mov	es:[CIH_flags], mask CIF_QUICK
	mov	es:[CIH_sourceID].handle, 0	; no associated document
	mov	es:[CIH_sourceID].chunk, 0
	mov	es:[CIH_formatCount], 1
	mov	es:[CIH_formats][0].CIFI_format.CIFID_manufacturer, \
							MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats][0].CIFI_format.CIFID_type, CIF_FILES
	pop	es:[CIH_formats][0].CIFI_vmChain.high
	clr	es:[CIH_formats][0].CIFI_vmChain.low
	pop	es:[CIH_formats][0].CIFI_extra2	; source remote flag
	pop	es:[CIH_formats][0].CIFI_extra1	; source true disk handle
	call	VMUnlock			; unlock transfer item (pass bp)

	.leave
	ret
GenerateTreeDragItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetTreeFolderClicked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns pointer to folder within tree that was clicked on

CALLED BY:	INTERNAL
			TreeStartSelect

PASS:		cx, dx - position clicked
		es - segment of locked tree buffer
		ds:si - instance data

RETURN:		C=1 if object was clicked on
			ax =	CLICKED_ON_ICON
				CLICKED_ON_NAME
		C=0 if no object clicked on
		es:di - pointer to entry in folder buffer of object clicked

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version
	brianc	8/17/89		displayList added to support outline tree stuff
	brianc	9/28/89		displayList removed, used TSEF_DELETED

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetTreeFolderClicked	proc	far
	class	TreeClass

	clr	di				; first entry
GTFC_loop:
	test	es:[di].TE_state, mask TESF_DELETED	; deleted?
	jnz	GTFC_checkNext			; if so, check next
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline mode?
	jz	GTFC_checkName			; if not, can't be icon
	test	es:[di].TE_state, mask TESF_PARENT	; check if parent
	jz	GTFC_checkName			; if not, can't be icon
	cmp	cx, es:[di].TE_iconBounds.R_left ; check if left of icon left
	jl	GTFC_checkName			; if so, check for click on name
	cmp	dx, es:[di].TE_iconBounds.R_top	; check if above icon top
	jl	GTFC_checkName			; if so, check for click on name
	cmp	cx, es:[di].TE_iconBounds.R_right ; check if right of icon right
	jg	GTFC_checkName			; if so, check for click on name
	cmp	dx, es:[di].TE_iconBounds.R_bottom ; check if below icon bottom
	mov	ax, CLICKED_ON_ICON
	jng	GTFC_gotObject			; if not, object clicked on
GTFC_checkName:
	cmp	cx, es:[di].TE_nameBounds.R_left ; check if left of name left
	jl	GTFC_checkNext			; if so, check next object
	cmp	dx, es:[di].TE_nameBounds.R_top	; check if above name top
	jl	GTFC_checkNext			; if so, check next object
	cmp	cx, es:[di].TE_nameBounds.R_right ; check if right of name right
	jg	GTFC_checkNext			; if so, check next object
	cmp	dx, es:[di].TE_nameBounds.R_bottom ; check if below name bottom
	mov	ax, CLICKED_ON_NAME
	jng	GTFC_gotObject			; if not, object clicked on
GTFC_checkNext:
	add	di, size TreeEntry		; move to next display list item
	cmp	di, ds:[si].TI_treeBufferNext	; end of buffer?
	jne	GTFC_loop			; if not, loop
	clc					; indicate not found
	ret
GTFC_gotObject:
	stc
	ret
GetTreeFolderClicked	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle quick transfer (file move or copy)

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		ds:si - instance handle of tree object
		es - segment of TreeClass
		ax - MSG_META_END_MOVE_COPY
		cx, dx - mouse position
		bp - UIFA flags
			UIFA_MOVE - if move override
			UIFA_COPY - if copy override

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/22/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeEndMoveCopy	method	TreeClass, MSG_META_END_MOVE_COPY

	moveCopyFlag	local	word
	destFolderSeg	local	word
	destFolderOff	local	word
	transferVMfile	local	word
	transferVMblock	local	word
	UIFAFlags	local	word

	mov	bx, bp				; bx = UIFA flags

	.enter

	mov	UIFAFlags, bx
	mov	moveCopyFlag, mask CQNF_NO_OPERATION	; assume not accepted

	push	cx, dx, bp, si
	call	TreeStopQuickTransferFeedback	; stop feedback, if needed
	pop	cx, dx, bp, si
	;
	; a simple trivial reject case
	;
	mov	si, ds:[si]			; deref.
	test	ds:[si].TI_displayMode, mask TIDM_BOGUS
	jnz	notActiveJMP
	cmp	ds:[si].TI_treeBuffer, 0
	jne	noNotActive
notActiveJMP:
	jmp	notActive
noNotActive:
	;
	; check if we dropped stuff on anything of interest
	;
	call	LockTreeBuffer			; lock tree buffer
	push	bx				; save buffer handle
	mov	es, ax
	mov	destFolderSeg, ax
	call	GetTreeFolderClicked		; es:di = tree folder
	mov	destFolderOff, di
	jnc	exitJMP				; if not, done
	;
	; dropped on something, what?
	;
	cmp	ax, CLICKED_ON_NAME		; name?
;	jne	exit				; no, must be icon - do nothing
	je	10$
exitJMP:
	jmp	exit
10$:
	;
	; see if CIF_FILES is supported
	;
	push	bp				; save locals
	mov	bp, mask CIF_QUICK
	call	ClipboardQueryItem		; returns:
						; cx:dx - owner of drag files
						; bx:ax - transfer item header
	mov	di, bp				; di = count of formats
	pop	bp				; retreive locals
	mov	transferVMfile, bx		; save transfer item header
	mov	transferVMblock, ax
	tst	di				; ax = count of formats
	jz	done				; if no transfer item, done
	;
	; check if we are dropping ourselves onto ourselves, a thing we want
	; to determine early on
	;
	cmp	cx, handle DesktopUI		; are we ourselves?
	jne	validSource			; no, valid
	cmp	dx, offset DesktopUI:TreeObject	; are we ourselves?
	jne	validSource			; no, valid
	mov	di, destFolderOff		; cx = destination
	cmp	di, ss:[treeDragSource]		; are we ourselves?
	je	done				; yes, bail out quickly
validSource:
	push	cx, dx				; save owner (cx:dx)
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_FILES
	call	ClipboardTestItemFormat		; is CIF_FILES supported?
	pop	dx, cx				; retreive owner (dx:cx)
	jc	done				; if not, done
	;
	; check if we should be doing a move or a copy
	;	dx:cx - owner
	;
	mov	bx, handle DesktopUI		; bx:ax - us
	mov	ax, offset DesktopUI:TreeObject
	call	CompareTransferSrcDest		; same disk?
	mov	ax, mask CQNF_MOVE		; assume so, do move
	jnc	44$				; yes, same disk
	mov	ax, mask CQNF_COPY		; else, do copy
44$:
	mov	moveCopyFlag, ax		; store as method
	;
	; get transfer item and process it
	;
	mov	bx, transferVMfile		; bx:ax = transfer item header
	mov	ax, transferVMblock
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_FILES			; transfer format
	push	bp
	call	ClipboardRequestItemFormat	; get file list block (BX:AX)
	pop	bp
	tst	ax				; CIF_FILES supported?
	jz	done				; no, done

	mov	cx, destFolderSeg
	mov	es, cx				; es:di = dest folder
	mov	di, destFolderOff
	mov	cx, moveCopyFlag		; cx = QNF_{MOVE,COPY}
	mov	dx, UIFAFlags			; dx = UIFA flags
	push	bp, ds
	call	ProcessTreeDragItem
	pop	bp, ds
done:
	;
	; tell UI we are done
	;
	mov	bx, transferVMfile		; bx:ax = transfer item header
	mov	ax, transferVMblock
	call	ClipboardDoneWithItem
exit:
	pop	bx				; unlock tree buffer
	call	MemUnlock
notActive:
	;
	; whatever the case, stop the UI part of quick-transfer (clears
	; default quick-transfer cursor, etc.)
	;
	push	bp				; save locals
	mov	bp, moveCopyFlag		; bp = ClipboardQuickNotifyFlags
	call	ClipboardEndQuickTransfer
	pop	bp				; retrieve locals

	mov	ax, mask MRF_PROCESSED

	.leave
	ret
TreeEndMoveCopy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessTreeDragItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy/move list of files to specified folder

CALLED BY:	INTERNAL
			TreeEndMoveCopy

PASS:		es:di - tree buffer entry stuff was dropped on
			(tree buffer locked)
		ds:si - tree object instance data
		bx:ax - (VM file):(VM block) of file list block
		cx - mask CQNF_MOVE if move
		     mask CQNF_COPY if copy
		dx - UIFA flags

RETURN:	

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/22/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessTreeDragItem	proc	near
	class	TreeClass

	;
	; stuff UIFA flags into file transfer list
	;
	call	StuffUIFAIntoFileList

	push	cx				; save move/copy flags
	;
	; get destination folder name
	;
	mov	dx, BDN_PATHNAME		; dgroup:dx = dest. pathname
	push	ax				; save VM block handle
	call	BuildDirName
	pop	ax				; retrieve VM block handle
	push	dx
	mov	dx, ds:[si].TI_disk	; dx = dest. disk han.
NOFXIP<	segmov	ds, dgroup, si						>
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
	pop	si				; ds:si = destination pathname
						;	(directory name)
	pop	bp				; retrieve move/copy flags
	mov	cx, 0				; indicate bx = VM block
	call	IsThisInTheWastebasket
	jnc	notTheWastebasket
	mov	{byte} ss:[usingWastebasket], WASTEBASKET_WINDOW
notTheWastebasket:
	call	ProcessDragFilesCommon		; process file list
	mov	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET
						; pass ds:si, bx:ax, bp, dx, cx
	ret
ProcessTreeDragItem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeScan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read an entire disk's directory structure and stuff them into
		the tree buffer.

CALLED BY:	MSG_TREE_SCAN

PASS:		ds:si - instance handle of TreeClass
		cx - disk handle of disk to scan

RETURN:		ax - 0 if successful
		ax - error code if failure

DESTROYED:	preserves ds, si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/12/89		Initial version
	brianc	7/17/89		changed to use only kernel file routines
	brianc	7/20/89		changed to method handler
	brianc	9/28/89		broke out ReadSubDirBranch for new outline
					tree handling

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeScan	method	TreeClass, MSG_TREE_SCAN
	uses	ds, si
	.enter
	call	ShowHourglass
	mov	si, ds:[si]			; deref. handle
	test	ds:[si].TI_displayMode, mask TIDM_BOGUS
	jnz	afterMemErrJMP
	;
	; allocate buffer for storage of tree, if needed
	;
	cmp	ds:[si].TI_treeBuffer, 0	; any buffer
	jne	haveBuffer			; yes, use it
	mov	ds:[si].TI_selectedFolder, NIL	; no selected folder yet
	push	cx				; save disk handle
	mov	ax, INIT_NUM_TREE_BUFFER_ENTRIES * (size TreeEntry)
	push	ax				; save size
	mov	cx, ALLOC_DYNAMIC		; (not locked)
	call	MemAlloc
	jnc	noErr
	add	sp, 4				; clean up stack
	mov	ax, ERROR_INSUFFICIENT_MEMORY	; error code
cleanMemErr:
	call	TreeMemError			; report error and close Tree
afterMemErrJMP:
	jmp	short afterMemErr

noErr:
	mov	ds:[si].TI_treeBuffer, bx	; save handle of tree buffer
	pop	ds:[si].TI_treeBufferSize	; size of tree buffer
	pop	cx				; retrieve disk handle
haveBuffer:
	;
	; allocate disk buffer for all directory reads
	;
	push	cx				; save disk handle
						; mark as scanned
	ornf	ds:[si].TI_displayMode, mask TIDM_SCANNED
	mov	ds:[si].TI_treeBufferNext, 0	; start of tree buffer
	;
	; save currently selected folder
	;	ax = 0-based drive
	;
	call	SaveSelectedFolder		; sets TI_selectedFolder = NIL
	;
	; if Tree is in normal mode, clear all collapsed branch buffer
	;	entries for this disk handle
	;
	pop	bx				; bx = disk handle to scan
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline?
	jnz	outlineMode			; yes, keep collapsed branches
	call	ClearCollapsedBranchBuffer	; pass bx = disk handle
outlineMode:
	;
	; read and process volume label
	; (add root directory to tree buffer)
	;	bx = disk handle to scan
	;
	call	DiskGetDrive			; al = drive number
	clr	ah
	mov	ds:[si].TI_drive, ax		; store drive number
	call	ReadVolumeLabel			; pass bx = disk handle
	mov	ax, 0				; in case error (already
						;	reported)
						; (PRESERVE CARRY!!)
	jc	freeAndError			; if error, handle it
	;
	; read and process all resulting directories
	; (add their subdirectories to tree buffer)
	;
	clr	di				; initial offset into tree buf.
	mov	bp, 0				; root=0
	mov	bx, mask RSDB_RESELECT		; heed collapsed branches
						;  and reselect saved folder
						; root level only?
	test	ds:[si].TI_displayMode, mask TIDM_ROOT_LEVEL
	jz	noRootLevelOnly			; no
						; else, heed collapsed branches,
						;  reselect saved folder,
						;  and read only one level
	mov	bx, mask RSDB_RESELECT or mask RSDB_ONE_LEVEL_ONLY
	andnf	ds:[si].TI_displayMode, not mask TIDM_ROOT_LEVEL
noRootLevelOnly:
	call	ReadSubDirBranch		; process tree
						; carry = error status
						; ax = error code
	;
	; ds:si = instance data
	;
freeAndError:
	jc	cleanMemErr			; if error, handle it
	call	LockTreeBuffer
	mov	es, ax
	mov	di, ds:[si].TI_selectedFolder	; get selected folder
	cmp	di, NIL				; check if saved one was found
	jne	TS_foundSelected		; if so, use it
	ornf	es:[0].TE_state, mask TESF_SELECTED	; else, select root
	mov	di, 0
	mov	ds:[si].TI_selectedFolder, di
TS_foundSelected:
	call	SetDirectoryTreePathname	; show new volume/pathname
	call	UnlockTreeBuffer
	call	SortHierarchy			; sort the tree buffer
						;	by hierarchy
	jc	cleanMemErr			; if mem error, report it

afterMemErr:
	clr	ax				; indicate success
						; (or error already reported)
	call	HideHourglass
	.leave
	ret
TreeScan	endp


ife FULL_EXECUTE_IN_PLACE
LocalDefNLString rootSaveName <C_BACKSLASH, 0>
endif



TreeMemError	proc	near
	class	TreeClass

	push	ax				; save error code
						; need to rescan next time
	andnf	ds:[si].TI_displayMode, not mask TIDM_SCANNED
						; mark as bogus
						; scan only root level next time
	ornf	ds:[si].TI_displayMode, mask TIDM_BOGUS or mask TIDM_ROOT_LEVEL
	mov	ax, ss:[geosDiskHandle]		; ...and use system disk
	mov	ds:[si].TI_disk, ax
	xchg	bx, ax				; (1-byte inst.)
	call	DiskGetDrive			; al = drive
	mov	cl, al
	clr	ch				; cx = drive
	call	EnsureTreeMenuDrive		; set drive in menu drive list
	mov	bx, handle TreeWindow
	mov	si, offset TreeWindow
	mov	ax, MSG_GEN_DISPLAY_CLOSE
	call	ObjMessageCallFixup
	pop	ax				; retrieve error code
	tst	ax
	jz	done				; error already reported
	call	DesktopOKError			; else, report it
done:
	ret
TreeMemError	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove ourselves from the file-change list, if we're there.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= Tree object
		^ldx:bp	= ack OD
		cx	= ack ID
		ds:di	= TreeInstance
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeDetach	method dynamic TreeClass, MSG_META_DETACH
	uses	ax, cx, dx, bp
	.enter
	call	UtilRemoveFromFileChangeList
	.leave
	mov	di, offset TreeClass
	GOTO	ObjCallSuperNoLock
TreeDetach endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStoreNewDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store new disk for directory tree in Tree Window

CALLED BY:	MSG_TREE_STORE_NEW_DRIVE
			(DesktopNewTreeDrive)

PASS:		usual object stuff
		cx - new disk handle to store

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/27/90	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStoreNewDrive	method	TreeClass, MSG_TREE_STORE_NEW_DRIVE
	mov	di, ds:[si]
	test	ds:[di].TI_displayMode, mask TIDM_BOGUS
	jnz	exit
	;
	; store new disk handle
	;
	mov	bx, cx
	xchg	si, di
	call	TreeSetDisk
	xchg	si, di
	;
	; mark as needing scanning
	;
	andnf	ds:[di].TI_displayMode, not mask TIDM_SCANNED
	;
	; always scan just the root level, as this is much speedier
	;
	ornf	ds:[di].TI_displayMode, mask TIDM_ROOT_LEVEL

	;
	; Add to file-change list (for disk-format, if nothing else) if
	; not already there.
	; 
	test	ds:[di].TI_displayMode, mask TIDM_ON_FILE_CHANGE_LIST
	jnz	onFileList
	ornf	ds:[di].TI_displayMode, mask TIDM_ON_FILE_CHANGE_LIST
	call	UtilAddToFileChangeList
onFileList:
	;
	; redraw later; if Tree Window is not visible, will do nothing
	;
	cmp	ds:[di].TI_treeBuffer, 0
	je	notActive
	mov	ax, MSG_TREE_REDRAW
	mov	bx, ds:[LMBH_handle]		; bx:si = our instance
	call	ObjMessageForce
notActive:
	;
	; mark tree as dirty
	;
	call	ObjMarkDirty			; mark as dirty
exit:
	ret
TreeStoreNewDrive	endm

TreeRescan	method	TreeClass, MSG_TREE_RESCAN
	mov	di, ds:[si]			; deref.
	;
	; scan with current disk handle
	;
	mov	cx, ds:[di].TI_disk	; cx = disk handle
	call	TreeScan			; scan
	tst	ax				; any error?
	jz	done				; no
	call	DesktopOKError
done:
	ret
TreeRescan	endm

TreeRefresh	method	TreeClass, MSG_WINDOWS_REFRESH_CURRENT
	mov	di, ds:[si]			; deref.
	cmp	ds:[di].TI_treeBuffer, 0
	je	notActive
	;
	; mark tree as needing to be scanned, will be done on redraw
	; (no redraw/rescan if tree not visible)
	;
	andnf	ds:[di].TI_displayMode, not mask TIDM_SCANNED
	call	TreeRedraw
notActive:
	ret
TreeRefresh	endm



if 0	; don't track floppy status - 4/6/90

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NotifyFloppyChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	store new information about new floppy in system

CALLED BY:	INTERNAL
			TreeScan

PASS:		ds:si = instance data of Tree Object

RETURN:		

DESTROYED:	ax, bx, cx, dx, ds, si, es, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/03/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NotifyFloppyChange	proc	near
	class	TreeClass
	mov	ax, ds:[si].TI_drive		; al = 0-based drive number
	mov	cx, ax				; cx = 0-based drive number
	call	DriveGetStatus			; is this a removable media?
	test	ah, mask DS_MEDIA_REMOVABLE
	jz	done				; no, done
	;
	; get old volume name for this drive
	;
	clr	bp				; point at first entry
	jcxz	gotOldVolume
bumpPtr:
	add	bp, size FloppyTrackingEntry	; point at next entry
	loop	bumpPtr
gotOldVolume:
	;
	; send out MSG_REMOVED_FLOPPY with old volume name for this drive
	;	dx:bp = floppy entry for this drive with old volume's
	;		information
	;
	mov	bx, ss:[floppyTrackingTable]	; bx = handle of floppy table
	call	MemLock
	mov	dx, ax				; dx:bp = floppy tracking struct
	push	dx, bp				; save floppy entry
	mov	ax, MSG_REMOVED_FLOPPY	; removed this floppy
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	BroadcastToFolderWindows
	pop	dx, bp				; retrieve floppy entry
	;
	; store new volume name in floppy tracking table
	;	ds:si = instance data
	;	dx:bp = floppy entry for this drive
	;
	mov	es, dx				; es:di = drive's floppy entry
	mov	di, bp
	mov	bx, ds:[si].TI_disk	; bx = disk handle
	call	DiskHandleGetDrive		; al = 0-based drive number
	mov	es:[di].FTE_driveNumber, al	; store drive number
	add	di, offset FTE_diskInfo		; es:di = disk info entry
	add	si, offset TI_diskInfo		; ds:si = new disk info
	mov	cx, size DiskInfoStruct
	rep movsb				; copy disk info over
	;
	; send out MSG_INSERTED_FLOPPY with new volume name for this drive
	;	dx:bp = floppy entry for this drive with new volume's
	;		information
	;
	mov	ax, MSG_INSERTED_FLOPPY	; inserted this floppy
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	BroadcastToFolderWindows	; do it
	mov	bx, ss:[floppyTrackingTable]	; unlock floppy table
	call	MemUnlock
done:
	ret
NotifyFloppyChange	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveSelectedFolder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	saves pathname of currently selected folder, if any

CALLED BY:	TreeScan, TreeUpdateTree

PASS:		ds:si - instance data of tree object

RETURN:		pathBuffer & selectedFolderDiskHandle
			contains pathname/disk handle of selected folder
		ds, si preserved

DESTROYED:	

PSEUDO CODE/STRATEGY:
		save pathname of selected folder, if any;
		if none, save root name;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveSelectedFolder	proc	near
	class	TreeClass

	push	ds, si
	mov	ax, ds:[si].TI_disk	; save disk handle
	mov	ss:[selectedFolderDiskHandle], ax
	mov	bx, ds:[si].TI_treeBuffer	; tree buffer handle
	mov	di, ds:[si].TI_selectedFolder	; di = current selection
NOFXIP <	segmov	ds, cs			; ds:si - root dir	>
NOFXIP <	mov	si, offset rootSaveName				>
FXIP <		segmov	ds, ss, si					>
FXIP <		mov	si, C_BACKSLASH					>
FXIP <		push	si						>
FXIP <		mov	si, sp			;ds:si = root dir	>
	cmp	di, NIL				; check if any folder selected
	je	SSF_noneSelected		; if none, use root name
	;
	; else, save pathname of selected folder so that we can try to
	; reselect it after rescanning the disk
	;
	call	MemLock				; lock tree buffer
	push	bx				; save handle
	mov	es, ax				; es:di = selected folder
	mov	dx, BDN_PATHNAME		; build complete pathname of
	call	BuildDirName			;	selected folder (SS:DX)
	pop	bx				; unlock tree buffer
	call	MemUnlock
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
NOFXIP<	segmov	ds, dgroup, si						>
	mov	si, dx				; ds:si = search name
SSF_noneSelected:
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
NOFXIP<	mov	di, segment pathBuffer					>
NOFXIP<	mov	es, di				; es:di =buffer for selection >
	mov	di, offset pathBuffer
	call	CopyNullTermString		; save pathname in buffer
FXIP <	pop	si				;restore the stack	>
	pop	ds, si
	mov	ds:[si].TI_selectedFolder, NIL	; flag indicating selected
						;	folder not found yet
	ret
SaveSelectedFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeUpdateDiskName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update disk name in instance data and update path disk
		in Tree Window

CALLED BY:	MSG_UPDATE_DISK_NAME (sent when disk renamed)

PASS:		object stuff
		dx - disk handle with new name

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeUpdateDiskName	method	TreeClass, MSG_UPDATE_DISK_NAME
	;bx = ds:[si]
	test	ds:[bx].TI_displayMode, mask TIDM_BOGUS
	jnz	done
	cmp	ds:[bx].TI_treeBuffer, 0
	jz	done				; no tree buffer
						; our disk renamed?
	cmp	dx, ds:[bx].TI_disk
	jne	done				; nope

	mov	si, bx				; ds:si = tree instance

	segmov	es, ds				; es:di = volume name field
	mov	di, si
	add	di, offset TI_diskInfo.DIS_name
	mov	bx, dx				; bx = disk handle
	call	DiskGetVolumeName		; update volume name

	call	LockTreeBuffer
	mov	es, ax
	mov	di, ds:[si].TI_selectedFolder	; es:di = selected folder
	call	SetDirectoryTreePathname	; update it
	call	UnlockTreeBuffer
done:
	ret
TreeUpdateDiskName	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeUpdateFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update disk free space in instance data

CALLED BY:	MSG_UPDATE_FREE_SPACE (sent when disk renamed)

PASS:		object stuff
		cx:dx - new free space (in bytes)
		bp - disk handle with new free space

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/06/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeUpdateFreeSpace	method	TreeClass, MSG_UPDATE_FREE_SPACE
	;bx = ds:[si]
	test	ds:[bx].TI_displayMode, mask TIDM_BOGUS
	jnz	done
						; our disk with new free space?
	cmp	dx, ds:[bx].TI_disk
	jne	done				; nope
	mov	ds:[bx].TI_diskInfo.DIS_freeSpace.high, cx ; store new value
	mov	ds:[bx].TI_diskInfo.DIS_freeSpace.low, dx
done:
	ret
TreeUpdateFreeSpace	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeUpdateTreeDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update Tree Menu Drive List with current drive

CALLED BY:	MSG_UPDATE_TREE_DRIVE

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeUpdateTreeDrive	method	TreeClass, MSG_UPDATE_TREE_DRIVE
	mov	cx, ds:[bx].TI_drive		; cx = drive number
	call	EnsureTreeMenuDrive		; update tree menu drive list
	ret
TreeUpdateTreeDrive	endm



if 0	; no switching to normal mode - usability 4/90

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeShowOutline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	toggle outline tree mode

CALLED BY:	MSG_OUTLINE_TREE

PASS:		ds:si - instance handle of Tree object

RETURN:		

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
TreeShowOutline	method	TreeClass, MSG_OUTLINE_TREE
	push	si				; save instance handle
	mov	si, ds:[si]			; deref. instance data
	cmp	ds:[si].TI_treeBuffer, 0
	je	notActive
	mov	bp, ds:[si].TI_displayMode	; get old mode
	xor	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; toggle it
	test	bp, mask TIDM_OUTLINE		; was it outline?
	jnz	TSO_makeNormal			; if so, make it normal
	call	MakeOutlineTree			; then make it outline
	jmp	short TSO_done
TSO_makeNormal:
	mov	bx, ds:[si].TI_disk	; current drive's
							;	disk handle
	pop	si				; get instance handle
	push	si				; save again
	call	ClearCollapsedBranchBuffer	; remove all collapsed branches
						;	for this drive
	mov	cx, bx				; cx = disk handle
	call	TreeScan			; just rescan the whole thing
TSO_done:
	pop	si				; retrieve instance handle
	mov	ax, MSG_TREE_REDRAW
	call	ObjCallInstanceNoLock		; redraw ourselves
	call	ObjMarkDirty			; mark as dirty
notActive:
	ret
TreeShowOutline	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeCollapseBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	collapse selected branch

CALLED BY:	MSG_COLLAPSE_BRANCH

PASS:		ds:si - instance data handle of Tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeCollapseBranch	method	TreeClass, MSG_COLLAPSE_BRANCH
	mov	bp, si				; bp = object chunk
	mov	si, ds:[si]			; deref. instance handle
	test	ds:[si].TI_displayMode, mask TIDM_BOGUS
	jnz	TCB_exit
	cmp	ds:[si].TI_treeBuffer, 0
	je	TCB_exit
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline mode?
	jz	TCB_exit			; if not, exit
	call	LockTreeBuffer
	push	bx
	mov	es, ax				; es - segment of tree buffer
	mov	di, ds:[si].TI_selectedFolder	; get selected folder
	test	es:[di].TE_state, mask TESF_PARENT	; check if a parent
	jz	TCB_done			; if not, can't collapse
	test	es:[di].TE_state, mask TESF_COLLAPSED	; check if collapsed
	jnz	TCB_done			; if so, done already
	call	CollapseBranchLow		; collapse branch
	jnc	TCB_noErr			; successful, continue
	call	TreeMemError			; else, report error
						;	(ds:si = TreeInstance)
	jmp	short TCB_done

TCB_noErr:
	mov	si, bp				; *ds:si = object
	call	ObjMarkDirty			; mark as dirty
TCB_done:
	pop	bx				; unlock tree buffer
	call	MemUnlock
TCB_exit:
	ret
TreeCollapseBranch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeExpandAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	expand the whole farkin' tree

CALLED BY:	MSG_EXPAND_ALL

PASS:		ds:si - instance handle of Tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/18/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeExpandAll	method	TreeClass, MSG_EXPAND_ALL

	test	ds:[di].TI_displayMode, mask TIDM_BOGUS
	jnz	TEA_exit
	cmp	ds:[di].TI_treeBuffer, 0
	je	TEA_exit
	test	ds:[di].TI_displayMode, mask TIDM_OUTLINE	; outline mode?
	jz	TEA_exit			; if not, exit
	mov	bx, ds:[di].TI_disk	; current drive's
							;	disk handle
	call	ClearCollapsedBranchBuffer	; remove all collapsed branches
						;	for this drive
	mov	cx, bx				; cx = current disk handle
	call	TreeScan			; just rescan the whole thing
	mov	ax, MSG_TREE_REDRAW
	call	ObjCallInstanceNoLock		; redraw ourselves
	call	ObjMarkDirty			; mark as dirty
TEA_exit:
	ret
TreeExpandAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeExpandBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	expand selected branch completely

CALLED BY:	MSG_EXPAND_BRANCH

PASS:		ds:si - instance data handle of Tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/18/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeExpandBranch	method	TreeClass, MSG_EXPAND_BRANCH
	mov	bp, si				; save object chunk
	mov	si, ds:[si]			; deref. instance handle
	test	ds:[si].TI_displayMode, mask TIDM_BOGUS
	jnz	TEB_exit
	cmp	ds:[si].TI_treeBuffer, 0
	je	TEB_exit
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline mode?
	jz	TEB_exit			; if not, exit
	call	LockTreeBuffer
	push	bx
	mov	es, ax				; es - segment of tree buffer
	mov	di, ds:[si].TI_selectedFolder	; get selected folder
	test	es:[di].TE_state, mask TESF_PARENT	; check if a parent
						; (ignore collapsed bit)
	jz	TEB_done			; if not, don't expand
	call	ExpandBranchLow			; expand selected branch
	jnc	noErr				; if no error, continue
	call	TreeMemError			; else, report error
						;	(ds:si = TreeInstance)
	jmp	short TEB_done

noErr:
	mov	si, bp				; *ds:si = object
	call	ObjMarkDirty			; mark as dirty
TEB_done:
	pop	bx				; unlock tree buffer
	call	MemUnlock
TEB_exit:
	ret
TreeExpandBranch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeExpandOneLevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	expand selected branch one level

CALLED BY:	MSG_EXPAND_ONE_LEVEL

PASS:		ds:si - instance data handle of Tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/18/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeExpandOneLevel	method	TreeClass, MSG_EXPAND_ONE_LEVEL
	mov	bp, si				; save object chunk
	mov	si, ds:[si]			; deref. instance handle
	test	ds:[si].TI_displayMode, mask TIDM_BOGUS
	jnz	TEOL_exit
	cmp	ds:[si].TI_treeBuffer, 0
	je	TEOL_exit
	test	ds:[si].TI_displayMode, mask TIDM_OUTLINE	; outline mode?
	jz	TEOL_exit			; if not, exit
	call	LockTreeBuffer
	push	bx
	mov	es, ax				; es - segment of tree buffer
	mov	di, ds:[si].TI_selectedFolder	; get selected folder
	test	es:[di].TE_state, mask TESF_PARENT	; check if a parent
	jz	TEOL_done			; if not, can't collapse
	test	es:[di].TE_state, mask TESF_COLLAPSED	; check if collapsed
	jz	TEOL_done			; if not, already expanded
	call	ExpandOneLevelLow		; expand branch
	jnc	noErr				; if no error, continue
	call	TreeMemError			; else, report error
						;	(ds:si = TreeInstance)
	jmp	short TEOL_done			; if error, don't mark dirty

noErr:
	mov	si, bp				; *ds:si = object
	call	ObjMarkDirty			; expanded => dirty
TEOL_done:
	pop	bx				; unlock tree buffer
	call	MemUnlock
TEOL_exit:
	ret
TreeExpandOneLevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeMarkBranchDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	mark passed branch (if it exists) as dirty, for later
		updating; used to update tree display after file operations

CALLED BY:	MSG_MARK_BRANCH_DIRTY

PASS:		ds:si = instance handle of tree object
		cx = disk handle of branch to mark
		dx:bp = pathname of branch to mark

RETURN:		branch (if it exists) marked

DESTROYED:	

PSEUDO CODE/STRATEGY:
		while not done {
			if (last component of passed pathname == entry name) {
				if (passed pathname == entry's pathname) {
					mark entry as dirty;
					done;
				}
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeMarkBranchDirty	method	TreeClass, MSG_MARK_BRANCH_DIRTY
	test	ds:[bx].TI_displayMode, mask TIDM_BOGUS
LONG	jnz	noTreeWindow
	
	mov	di, sp

	test	cx, DISK_IS_STD_PATH_MASK
	jnz	checkSystemDisk

	cmp	ds:[bx].TI_disk, cx
	jne	noTreeWindow

	push	di
isTreeWindow:

	;
	; find last
	;
	mov	es, dx				; es:di = pathname
	mov	di, bp
	clr	al				; find null-terminator
	mov	cx, 07fffh
	repne scasb
	mov	cx, di
	dec	di				; es:di = null
	std					; search backward for '\'
	sub	cx, bp				; size of pathname (with null)
	mov	al, '\\'
	repne scasb
	cld
	inc	di				; point to last char checked
	cmp	byte ptr es:[di]+1, 0		; check if entry is root
	je	TMBD_root			; if so, leave di at ('\',0)
	inc	di				; else, point to first char of
						;	last path component
TMBD_root:
	mov	si, ds:[si]			; deref. instance handle
	mov	cx, ds:[si].TI_treeBufferNext	; cx = end of buffer
	jcxz	clearStack			; if not active, done
	call	LockTreeBuffer
	push	bx				; save tree buffer handle
	segmov	ds, es				; ds:si = last path component
	mov	si, di
	mov	es, ax				; es:di = first entry
	clr	di
TMBD_loop:
	cmp	di, cx				; end of buffer?
	je	TMBD_done			; if so, done
	push	di, si				; save entry ptr & last comp.
	add	di, offset TE_attrs.TA_name	 ; es:di = entry name
	call	CompareString			; check if this MIGHT BE
						;	branch to mark dirty
	pop	di, si				; retrieve entry ptr & comp.
	jne	TMBD_next			; if not, check next
	mov	dx, BDN_PATHNAME		; build pathname for this entry
	call	BuildDirName
	push	es, di, si			; save entry & last component
FXIP<	mov	di, bx							>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
FXIP<	mov	bx, di							>
NOFXIP<	mov	di, segment dgroup					>
NOFXIP<	mov	es, di				; es:di=this entry's pathname >
	mov	di, dx
	mov	si, bp				; ds:si = passed pathname
	call	CompareString			; check if this is branch to
						;	mark dirty
	pop	es, di, si			; retrieve entry & last comp.
	jne	TMBD_next			; if not, check next
	ornf	es:[di].TE_state, mask TESF_DIRTY	; else, mark as dirty
	jmp	short TMBD_done			; done
TMBD_next:
	add	di, size TreeEntry		; move to next entry
	jmp	short TMBD_loop			; check it
TMBD_done:
	pop	bx				; unlock tree buffer
	call	MemUnlock

clearStack:
	pop	sp			; clear stack

noTreeWindow:
	ret

checkSystemDisk:
	;
	; Affected path is std path. React if displaying system disk.
	; 
	mov	ax, ds:[bx].TI_disk
	cmp	ax, ss:[geosDiskHandle]
	jne	noTreeWindow
	;
	; Construct full path for playing with branches.
	; 
	sub	sp, size PathName
	mov	ax, sp
	push	di, ds, si
	mov	ds, dx			; ds:si <- tail
	mov	si, bp
	segmov	es, ss			; es:di <- buffer
	mov_tr	di, ax
	mov	bx, cx			; bx <- disk handle
	mov	cx, size PathName	; cx <- buffer size
	clr	dx			; dx <- no drive name, please
	call	FileConstructFullPath
	pop	ds, si
	jc	clearStack		; => error in construction

	mov	dx, ss			; dx:bp <- full path
	mov	bp, sp
	mov	cx, bx
	jmp	isTreeWindow		; leave original sp on the stack
					;  for clearStack to pop
TreeMarkBranchDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeUpdateTree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update all dirty branches; used to update tree display after
		file operations

CALLED BY:	MSG_UPDATE_TREE

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeUpdateTree	method	TreeClass, MSG_UPDATE_TREE
	call	ShowHourglass
	mov	si, ds:[si]			; deref. instance handle
	test	ds:[si].TI_displayMode, mask TIDM_BOGUS
	jnz	noChangeJMP
	cmp	ds:[si].TI_treeBuffer, 0	; any tree buffer contents?
	jne	noNoChanges
noChangeJMP:
	jmp	noChanges			; no, do nothing
noNoChanges:
 	call	LockTreeBuffer
	mov	es, ax
	;
	; delete all children of dirty entries so that we won't rescan
	; a child if we will later rescan its parent
	;
	mov	bx, ds:[si].TI_selectedFolder	; bx = current selected folder
	mov	cx, es:[bx].TE_parentID		; cx = parent of selected folder
	mov	dx, ds:[si].TI_treeBufferNext	; dx = end of buffer
	clr	di				; start of buffer
deleteLoop:
	cmp	di, dx				; end of buffer?
	je	deleteDone
	call	CheckIfParentDirty		; is parent dirty?
	jz	deleteNext			; if not, check next
						; indicate tree updated
	ornf	es:[di].TE_state, mask TESF_DELETED	; mark as deleted
	cmp	di, bx				; deleting selected folder?
	jne	deleteNext			; if not, continue
	mov	bx, NIL				; else, indicate need to
						;	reselect after scan
deleteNext:
	add	di, size TreeEntry
	jmp	deleteLoop

deleteDone:
	mov	di, cx				; pass parent of selected as
						;  entry to fixup to Compress..
	cmp	bx, NIL				; did we delete
						; selected folder?
	jne	notDeleted			; if not, continue
	push	es, di, ax, bx			; save entry, buf, end of buf
	call	SaveSelectedFolder		; else, save its pathname
						; sets TI_selectedFolder==NIL
	pop	es, di, ax, bx			; retrieve entry,buf,end of buf
notDeleted:
	call	CompressTreeBuffer		; remove deleted entries
	mov	bp, di				; save parent of old selected
	;
	;
	; rescan all remaining dirty entries, starting from the end
	;
	;
	mov	di, ds:[si].TI_treeBufferNext	; di = end of buffer
	sub	di, size TreeEntry
	test	es:[di].TE_state, mask TESF_DIRTY	; is last one dirty?
	jz	TUT_checkPrevious		; if not, check previous one
						; indicate tree updated
	call	TreeUpdateBranch		; if so, update it
	jc	TUT_done			; if error, done
TUT_checkPrevious:
	tst	di				; just checked first one?
	jz	TUT_done			; if so, done (carry is clear)
	sub	di, size TreeEntry		; else, move to previous one
	test	es:[di].TE_state, mask TESF_DIRTY	; is this one dirty?
	jz	TUT_checkPrevious		; if not, check previous one
	call	SwapWithLastEntry		; move dirty one to end (end
						;	is not dirty)
	mov	bx, ds:[si].TI_treeBufferNext	; bx = last entry
	sub	bx, size TreeEntry
	cmp	bp, bx				; was parent last entry?
	jne	TUT_parentNotLast		; if not, continue
	mov	bp, di				; else, parent is now here
	jmp	short TUT_parentNotHere
TUT_parentNotLast:
	cmp	bp, di				; was parent here?
	jne	TUT_parentNotHere		; if not, continue
	mov	bp, bx				; else, parent is last now
TUT_parentNotHere:
	push	di				; save scan position
	mov	di, bx				; update last entry
						; indicate tree updated
	call	TreeUpdateBranch		;	(dirty entry)
	pop	di				; retrieve scan pos
	jnc	short TUT_checkPrevious		; do previous one (if no err)
TUT_done:
	;
	; else, done rescanning; redraw
	;
	jc	error				; if error handle it
	mov	di, bp				; retrieve parent of selected
	cmp	ds:[si].TI_selectedFolder, NIL	; check if able to reselect
	jne	TUT_reselected			; if so, continue
	;
	; else, old selected folder was deleted, selected its parent
	; (parent can't be deleted because of delete loop above)
	;
	ornf	es:[di].TE_state, mask TESF_SELECTED	; mark parent
	mov	ds:[si].TI_selectedFolder, di	; select parent
	call	SetDirectoryTreePathname	; update pathname display
TUT_reselected:
	call	UnlockTreeBuffer		; unlock tree buffer
	call	SortHierarchy			; rebuild new tree
	jc	error				; if mem error, handle it
	call	TreeRedrawLow			; redraw new tree
noChanges:
	call	HideHourglass			; coffee break over
	ret

error:
	call	TreeMemError			; handle error
	jmp	short noChanges			; ...and bail out

TreeUpdateTree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfParentDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	checks if this entry is a descendent of a entry that is
		marked DIRTY

CALLED BY:	INTERNAL
			TreeUpdateTree

PASS:		es:di = entry

RETURN:		Z set if not
		Z clear if so

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfParentDirty	proc	near
	push	bp
	mov	bp, di
CIPD_loop:
	mov	bp, es:[bp].TE_parentID		; get parent
	cmp	bp, NIL				; went off root?
	je	CIPD_done			; if so, done (Z set)
	test	es:[bp].TE_state, mask TESF_DIRTY	; dirty?
	jz	CIPD_loop			; if not, loop
						; else, done (Z clear)
CIPD_done:
	pop	bp
	ret
CheckIfParentDirty	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeUpdateBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	rescan dirty branch

CALLED BY:	INTERNAL
			TreeUpdateTree

PASS:		es:di - entry of branch to upate (must be at end of
				locked tree buffer)
		ds:si - instance data of Tree object

RETURN:		carry clear if successful
		carry set if error
			ax - error code
		es - segment of locked tree buffer (may have moved)

DESTROYED:	preserves ds, si, es, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeUpdateBranch	proc	near
	class	TreeClass

	push	bp
						; mark not dirty and not parent
						;  if a parent, SortHierarchy
						;  will remark it
	andnf	es:[di].TE_state, not (mask TESF_DIRTY or mask TESF_PARENT)
	;
	; check if branch was collapsed
	;	If so, we don't need to rescan the branch because nothing
	;	inside it will be added to tree buffer since it is collapsed.
	;	All we need to do is find out if it is still a parent.  If
	;	the its last subdirectory was deleted, it is no longer a
	;	parent.
	;
	;	If not, we have rescan the branch to find what's in there.
	;	Many ugly things need to be done.
	;
	test	es:[di].TE_state, mask TESF_COLLAPSED	; was it collapsed?
	jz	TUB_notCollapsed		; no
	mov	dx, BDN_PATHNAME
	call	BuildDirName			; dgroup:dx = pathname
	call	CheckForAnySubdirs		; else, does it have any subs?
						; (this saves pathname in
						;  collapsed branch buffer,
						;  not a if its already there)
	jnc	TUB_notParentAnymore		; if not, unmark, delete path
						; else, mark parent, collapsed
	ornf	es:[di].TE_state, mask TESF_PARENT or mask TESF_COLLAPSED
	clc					; no error
	jmp	short TUB_done			; that's all!

TUB_notCollapsed:
	call	GetBranchLevel			; bp = level
	call	UnlockTreeBuffer		; unlock tree buffer
	mov	bx, mask RSDB_RESELECT		; reselect folder; heed
						;	collapsed branches
	cmp	ds:[si].TI_selectedFolder, NIL	; check if we need to reselect
	je	TUB_reselect			; if so, do it
	clr	bx				; else, don't reselect; heed
						;	collapsed branches
TUB_reselect:
	push	ds:[si].TI_treeBufferNext	; current end of buffer
	push	ds, si, di
	call	ReadSubDirBranch		; rescan entire branch
						; carry = status, ax = err code
	pop	ds, si, di
	pushf					; save ReadSubDirBranch status
	push	ax
	call	LockTreeBuffer			; may have moved
	mov	es, ax
	pop	ax				; retrieve status
	popf	
	;
	; ReadSubDirBranch marks entry as PARENT and COLLAPSED if it finds
	; the entry's pathname in the collapsedBranchBuffer; however, if we've
	; deleted all subdirectories in the entry, it is no longer a PARENT;
	; in this case, we need to mark as not a PARENT and not COLLAPSED
	; and remove entry's pathname from collapsedBranchBuffer
	;
	pop	bx				; retrieve end of buffer
	jc	TUB_done			; if ReadSubDirBranch error,
						;	exit w/carry and AX
	cmp	bx, ds:[si].TI_treeBufferNext	; check if anything added
	jne	TUB_isParent			; if so, is a parent
TUB_notParentAnymore:
						; mark as not PARENT/COLLAPSED
	andnf	es:[di].TE_state, not (mask TESF_PARENT or mask TESF_COLLAPSED)
	mov	bx, ds:[si].TI_disk	; pass disk handle
	call	DeleteCollapsedPathname		; remove collapsed pathname
TUB_isParent:
	clc					; no error
TUB_done:
	pop	bp
	ret
TreeUpdateBranch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeCloseIfMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close Tree Window if it is for the disk specified
		by the passed disk handle

CALLED BY:	MSG_CLOSE_IF_MATCH

PASS:		dx - disk handle

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	06/22/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeCloseIfMatch	method	TreeClass, MSG_CLOSE_IF_MATCH
	cmp	ds:[bx].TI_disk, dx
	jne	done				; no match
	mov	bx, handle TreeWindow
	mov	si, offset TreeWindow
	mov	ax, MSG_GEN_DISPLAY_CLOSE
	call	ObjMessageNone
done:
	ret
TreeCloseIfMatch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeCloseIfDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close Tree Window if it is for the drive specified

CALLED BY:	MSG_CLOSE_IF_MATCH

PASS:		cl - drive number

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeCloseIfDrive	method	TreeClass, MSG_CLOSE_IF_DRIVE
	clr	ch				; cx = drive number
	cmp	cx, ds:[bx].TI_drive
	jne	done				; no match
	mov	bx, handle TreeWindow
	mov	si, offset TreeWindow
	mov	ax, MSG_GEN_DISPLAY_CLOSE
	call	ObjMessageNone
done:
	ret
TreeCloseIfDrive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeRemovingDisk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close the tree if the disk passed is our disk

CALLED BY:	MSG_META_REMOVING_DISK
PASS:		cx	= disk handle
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	5/14/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeRemovingDisk method dynamic TreeClass, MSG_META_REMOVING_DISK
		.enter
		push	cx
		mov	dx, cx
		call	TreeCloseIfMatch
		clr	cx
		call	FileGetCurrentPath
		pop	cx
		cmp	bx, cx
		jne	done
		mov	ax, SP_TOP
		call	FileSetStandardPath
done:
		.leave
		ret
TreeRemovingDisk endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeNotifyFileChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cope with file-change notification.

CALLED BY:	MSG_NOTIFY_FILE_CHANGE
PASS:		*ds:si	= Tree object
		dx	= FileChangeNotificationType
		^hbp	= FileChangeNotificationData
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeNotifyFileChange method dynamic TreeClass, MSG_NOTIFY_FILE_CHANGE
		push	es
		mov	bx, bp
		call	MemLock
		mov	es, ax
		clr	di
		mov	cx, TRUE			; update when done
		call	TreeNotifyFileChangeLow
		pop	es
		call	MemUnlock
		mov	ax, MSG_NOTIFY_FILE_CHANGE
		mov	di, offset TreeClass
		GOTO	ObjCallSuperNoLock
TreeNotifyFileChange endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeNotifyFileChangeLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single file-change

CALLED BY:	(INTERNAL) TreeNotifyFileChange, self
PASS:		dx	= FileChangeNotificationType
		es:di	= FileChangeNotificationData
		cx	= non-zero if should update the tree when
			  notification has been seen
		*ds:si	= Tree object
RETURN:		nothing
DESTROYED:	ax, di, dx, cx, es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeNotifyFileChangeLow proc near
		class	TreeClass
		uses	bx
		.enter
		mov	bx, dx
		shl	bx
		call	cs:[notificationTable][bx]
		jcxz	done
		jnc	done			; => no change

		push	bp, di
		mov	ax, MSG_UPDATE_TREE
		call	ObjCallInstanceNoLock
		pop	bp, di
done:
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

	;
	; A directory has been either added or deleted as a StandardPath.
	; Since there is no easy way to determine what parts of the tree
	; are affected by the change, (TreeMarkIfIDMatches assumes
	; that a change affects only one thing) we just rescan.
	;
notifySPAdd:
notifySPDelete:
		push	bp
		mov	ax, MSG_TREE_RESCAN
		call	ObjCallInstanceNoLock
		mov	ax, MSG_TREE_REDRAW
		call	ObjCallInstanceNoLock
		pop	bp
		clc			;carry <- don't update
		retn

notifyCreate:
	; mark containing dir dirty. should force it to be rescanned
		mov	ax, mask TESF_DIRTY
		call	TreeMarkIfIDMatches
		retn

	;--------------------
notifyDelete:
	; mark affected thing deleted, which should cause it to go away...
		mov	ax, mask TESF_DELETED
		call	TreeMarkIfIDMatches
		retn

notifyRename:
	; mark parent dir dirty. should force it to be rescanned
		mov	ax, mask TESF_DIRTY
		call	TreeMarkParentIfIDMatches
		retn

	;--------------------
notifyOpen:
notifyClose:
	; NEWDESK FOLKS MIGHT WANT TO DO SOMETHING HERE
		clc
		retn

	;--------------------
notifyAttributes:
notifyContents:
notifyFileUnread:
notifyFileRead:
		clc
		retn

	;--------------------
notifyFormat:
	; close if disk is ours
		mov	dx, es:[di].FCND_disk
		mov	ax, MSG_CLOSE_IF_MATCH
		push	bp
		call	ObjCallInstanceNoLock
		pop	bp
		clc
		retn

	;--------------------
notifyBatch:
	;
	; Process the batch o' notifications one at a time
	; 
		push	cx
		mov	bx, es:[FCBND_end]
		mov	di, offset FCBND_items
		clr	ax
		push	ax
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
		clr	cx		; don't update
		call	TreeNotifyFileChangeLow
		pop	di, dx
		pop	ax
		lahf
		or	al, ah
		push	ax
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
		pop	ax
		mov	ah, al
		sahf			; set carry if carry came back set
					;  from any of our sub calls
		pop	cx
		retn
TreeNotifyFileChangeLow endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeMarkIfIDMatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark an entry in the tree with a particular flag if its
		ID matches that in the notification

CALLED BY:	(INTERNAL) TreeNotifyFileChangeLow, TreeMarkParentIfIDMatches
PASS:		ax	= TE_StateFlags
		es:di	= FileChangeNotificationData
		*ds:si	= Tree object
RETURN:		carry set if found a match:
			^hbx:di	= TreeEntry that matched, marked
		carry clear if no match:
			bx, di = destroyed
DESTROYED:	dx
SIDE EFFECTS:	entry, if found, is marked with passed flag.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeMarkIfIDMatches proc	near
		class	TreeClass
		uses	bp, cx, si, es
		.enter
	;
	; Fetch the ID into something non-perishable
	; 
		movdw	cxdx, es:[di].FCND_id
		mov	bp, es:[di].FCND_disk
		mov	si, ds:[si]
		mov	bx, ds:[si].TI_treeBuffer
		tst	bx		; clears carry
		jz	done

		push	ax
		call	MemLock
		mov	es, ax
		pop	ax
		mov	di, -size TreeEntry
checkLoop:
		add	di, size TreeEntry
		cmp	di, ds:[si].TI_treeBufferNext
		jae	unlock
		
		cmp	es:[di].TE_attrs.TA_disk, bp
		jne	checkLoop
		cmp	es:[di].TE_attrs.TA_id.low, dx
		jne	checkLoop
		cmp	es:[di].TE_attrs.TA_id.high, cx
		jne	checkLoop

		ornf	es:[di].TE_state, ax
		stc
unlock:
		call	MemUnlock
done:
		.leave
		ret
TreeMarkIfIDMatches endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeMarkParentIfIDMatches
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark the parent directory of the matching entry with a
		particular flag.

CALLED BY:	(INTERNAL) TreeNotifyFileChangeLow
PASS:		ax	= TE_StateFlags
		es:di	= FileChangeNotificationData
		*ds:si	= Tree object
RETURN:		carry set if found
DESTROYED:	bx, di, ax, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/17/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeMarkParentIfIDMatches proc	near
		class	TreeClass
		uses	es
		.enter
	;
	; Use the regular routine to locate the thing whose ID matches, as
	; it's easier that way.
	; 
		push	ax
		clr	ax		; don't change its state, just find
					;  it...
		call	TreeMarkIfIDMatches
		pop	ax
		jnc	done
	;
	; See if the thing has a parent and mark it if so.
	; 
		mov_tr	dx, ax
		call	MemLock
		mov	es, ax
		
		mov	di, es:[di].TE_parentID
		cmp	di, NIL
		je	unlock
		
		ornf	es:[di].TE_state, dx
		stc
unlock:
		call	MemUnlock
done:
		.leave
		ret
TreeMarkParentIfIDMatches		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeViewWinClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	shutdown of tree object

CALLED BY:	MSG_META_CONTENT_VIEW_WIN_CLOSED
			exiting and splitting

PASS:		ds:si = instance data of tree object
		bp = window

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		we get this when we split the Tree Window;
		we get this for EACH subview when we quit;
		we get this for EACH when we iconfiy;

		remove window from subview list;
		if ((not split) and (not iconify)) {
			if (first subview) {
				free tree buffer;
			}
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeViewWinClosed	method	TreeClass,
				MSG_META_CONTENT_VIEW_WIN_CLOSED
	andnf	ds:[bx].TI_displayMode, not mask TIDM_BOGUS	; clear flag
	push	bp				; save window
	;
	; remove from subview list
	;
	mov	cx, VIEW_MAX_SUBVIEWS
	clr	bx
	mov	di, ds:[si]			; deref.
TWD_loop:
	cmp	ds:[di][bx].TI_subviews, bp	; is this it?
	jne	TWD_next			; if not, check next entry
	clr	ds:[di][bx].TI_subviews		; remove from subview list
	;
	; free associated GState, also
	;
	push	di, si
	clr	si
	xchg	si, ds:[di][bx].TI_gStates
	tst	si
	jz	noGState
	mov	di, si				; di = GState
	call	GrDestroyState
noGState:
	pop	di, si
	jmp	short TWD_removed
TWD_next:
	add	bx, 2				; move to next entry
	loop	TWD_loop
TWD_removed:
	pop	bp				; retrieve window
	;
	; do other stuff
	;
	cmp	ss:[exitFlag], 1		; are we exiting?
	jne	callSuper			; if not, don't clobber buffer
	mov	di, ds:[si]			; deref. instance
	mov	bx, ds:[di].TI_treeBuffer	; free tree buffer
	tst	bx				; already freed? (split)
	jz	callSuper			; if so, already clobbered
	mov	ds:[di].TI_treeBuffer, 0
	mov	ds:[di].TI_treeBufferSize, 0
	mov	ds:[di].TI_treeBufferNext, 0
	call	MemFree
callSuper:
	mov	di, offset TreeClass
	call	ObjCallSuperNoLock		; superclass, finish up
						;	(pass on window)
	ret
TreeViewWinClosed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close up Tree window - remove from Display Control

CALLED BY:	MSG_TREE_CLOSE
		this message is sent from the Tree Window GenDisplay when it
		receives MSG_GEN_DISPLAY_CLOSE.

PASS:		*ds:si - Tree object

RETURN:

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeClose	method	dynamic	TreeClass, MSG_TREE_CLOSE
	;
	; manually closing, free tree buffer
	;
	mov	bx, ds:[di].TI_treeBuffer
	tst	bx
	jz	10$
	mov	ds:[di].TI_treeBuffer, 0
	mov	ds:[di].TI_treeBufferSize, 0
	mov	ds:[di].TI_treeBufferNext, 0
	call	MemFree
						; needs scanning
	andnf	ds:[di].TI_displayMode, not mask TIDM_SCANNED
10$:
	;
	; manually closing, remove TreeWindow from display control
	;
	mov	bx, handle TreeWindow
	mov	si, offset TreeWindow
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	mov	cx, bx				; cx:dx = Tree Window
	mov	dx, si
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_GEN_FIND_CHILD
	call	ObjMessageCallFixup		; still in DC?
	jc	done				; nope
	mov	ax, MSG_GEN_REMOVE_CHILD	; else, remove
	mov	bp, mask CCF_MARK_DIRTY		; dirty linkage
	call	ObjMessageCallFixup
done:
	ret
TreeClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeViewWinOpened
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	new subview being created, splitting or initial startup

CALLED BY:	MSG_META_CONTENT_VIEW_WIN_OPENED

PASS:		ds:si - instance of Tree object
		bp - subview's window handle

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		save subview handle in subview list;
		create and save GState for the subview;

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeViewWinOpened	method	TreeClass, MSG_META_CONTENT_VIEW_WIN_OPENED
	mov	si, ds:[si]			; deref.
	mov	cx, VIEW_MAX_SUBVIEWS
	clr	bx
TSC_loop:
	tst	ds:[si][bx].TI_subviews		; is one stored here?
	jnz	TSC_next			; if so, check next
	mov	ds:[si][bx].TI_subviews, bp	; save it
	mov	di, bp				; di = window
	call	GrCreateState
	mov	cx, ss:[desktopFontID]
	mov	dx, ss:[desktopFontSize]
	clr	ah				; no fractional part
	call	GrSetFont
	mov	ds:[si][bx].TI_gStates, di	; save gstate
	jmp	short TSC_done			; done
TSC_next:
	add	bx, 2
	loop	TSC_loop
TSC_done:
	ret
TreeViewWinOpened	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeOpenSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	open Folder Window for selected directory

CALLED BY:	MSG_OPEN_SELECT_LIST

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeOpenSelectList	method	TreeClass, MSG_OPEN_SELECT_LIST
	mov	si, ds:[si]			; deref.
	cmp	ds:[si].TI_treeBuffer, 0
	je	notActive
	call	LockTreeBuffer
	push	bx				; save tree buffer handle
	mov	es, ax				; es:di = selected folder
	mov	di, ds:[si].TI_selectedFolder
	cmp	di, NIL				; just in case
	je	done
	call	TreePreOpenFolder		; bop us into overlapping mode
	call	OpenTreeFolder			; open it
done:
	pop	bx				; retreive tree buffer handle
	call	MemUnlock			; unlock tree buffer
notActive:
	ret
TreeOpenSelectList	endm

OpenTreeFolder	proc	near
	class	TreeClass

	ornf	es:[di].TE_state, mask TESF_OPENED
	mov	dx, BDN_PATHNAME		; build regular pathname
	call	BuildDirName			; build pathname from es:di
	mov	bp, dx				; dx:bp = new text
NOFXIP<	mov	dx, segment dgroup					>
FXIP<	push	ds							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	dx, ds							>
FXIP<	pop	ds							>
	mov	bx, ds:[si].TI_disk	; pass disk handle
	call	CreateNewFolderWindow		; open new folder window
	ret
OpenTreeFolder	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeKeyboard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle keypresses in Tree Window

CALLED BY:	MSG_META_KBD_CHAR

PASS:		ch - CharacterSet
		cl - character value
		dl - CharFlags
		dh - ShiftState
		bp (low) - ToggleState
		bp (high) - scan code

RETURN:

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TreeKeyboard	method	TreeClass, MSG_META_KBD_CHAR
	mov	ax, si				; save chunk handle, in case
	mov	si, ds:[si]			; ds:si = instance data
						; only accept first and repeat
	test	dl, mask CF_FIRST_PRESS or mask CF_REPEAT_PRESS
	jz	fup
	tst	dh
	jnz	fup				; ignore all with modifiers
	push	ax, cx
	mov	ax, cx
	segmov	es, cs, di
	mov	di, offset treeKeysTable
	mov	cx, TREE_KEYS_TABLE_SIZE
	repne	scasw
	pop	ax, cx
	je	goodKey
fup:
	;
	; we don't want this, send it back to the GenView
	;
	mov	bx, handle TreeView		; ^lbx:si = GenView
	mov	si, offset TreeView
	mov	ax, MSG_META_FUP_KBD_CHAR
	call	ObjMessageFixup
	jmp	short done
	
goodKey:
	;
	; process keyboard shortcut
	;	ds:si = Tree instance data
	;	di = after matching entry in char table offset
	;
	mov	bx, ds:[si].TI_treeBuffer
	tst	bx
	jz	done				; no buffer, do nothing
	mov	bp, ax				; bp = Tree chunk handle
	call	MemLock				; lock tree buffer
	mov	es, ax

	sub	di, 2				; point at matching entry
	add	di, (offset treeKeysRoutineTable - offset treeKeysTable)
	mov	bx, di
	mov	bx, cs:[bx]			; bx = offset to handler
	mov	di, ds:[si].TI_selectedFolder	; es:di = current selection
	call	bx				; call keyboard shortcut handler
						; es:di = new selection
	jnc	done				; if no change selection, done
;	push	cx				; save scroll direction
	call	ToggleTreeSelection		; select new one
;	push	di				; save new selection
;	mov	di, {word} ds:[si].TI_subviews
;	call	WinGetWinBounds			; ax, bx, cx, dx = bounds
;	pop	di				; retrieve new selection
;	pop	bp				; restore scroll direction
;	cmp	bx, es:[di].TE_boundBox.R_top
;	ja	needScroll
;	cmp	dx, es:[di].TE_boundBox.R_bottom
;	jb	needScroll
;	cmp	ax, es:[di].TE_boundBox.R_left
;	ja	needScroll
;	cmp	cx, es:[di].TE_boundBox.R_right
;	jae	afterScroll
;needScroll:
;	push	si				; save folder instance offset
;	mov	bx, handle TreeView		; ^lbx:si = GenView
;	mov	si, offset TreeView
;	mov	ax, bp				; ax = scroll message
;	call	ObjMessageCallFixup
;	pop	si				; si = folder instance offset
;afterScroll:
	mov	bx, ds:[si].TI_treeBuffer
	call	MemUnlock			; unlock folder buffer
done:
	ret
TreeKeyboard	endm

;
; keyboard shortcut handling routines
;
; pass:
;	ds:si = Tree instance data
;	es:di = current selection
;	*ds:bp = Tree object
; return:
;	carry set to make new selection
;		es:di = new selection
;	carry clear otherwise
;
TreeKeyBlankEnter	proc	near
	mov	ax, MSG_OPEN_SELECT_LIST
	mov	si, bp				; *ds:si = tree object
	call	ObjCallInstanceNoLock		; open it
	clc					; don't change selection
	ret
TreeKeyBlankEnter	endp

TreeKeyPlus	proc	near
	mov	ax, MSG_EXPAND_ONE_LEVEL
	mov	si, bp				; *ds:si = tree object
	call	ObjCallInstanceNoLock		; open it
	clc					; don't change selection
	ret
TreeKeyPlus	endp

TreeKeyMinus	proc	near
	mov	ax, MSG_COLLAPSE_BRANCH
	mov	si, bp				; *ds:si = tree object
	call	ObjCallInstanceNoLock		; open it
	clc					; don't change selection
	ret
TreeKeyMinus	endp

TreeKeyHome	proc	near
	class	TreeClass
	clr	di				; go to root
	stc					; change selection
	ret
TreeKeyHome	endp

TreeKeyEnd	proc	near
	class	TreeClass
	mov	di, ds:[si].TI_treeBufferNext	; end of buffer
goEndLoop:
	sub	di, size TreeEntry		; es:di = last entry
	tst	di				; found root before match?
	je	goEndFound			; yes, use root
	tst	es:[di].TE_parentID		; is parent root?
	jne	goEndLoop			; nope, check previous
goEndFound:
	stc					; change selection
	ret
TreeKeyEnd	endp

TreeKeyDown	proc	near
	class	TreeClass
;	mov	cx, MSG_GEN_VIEW_SCROLL_DOWN
	tst	di				; root?
	jz	exit				; yes, has no siblings, done
						;	(carry clear)
	mov	dx, di				; default if none found
	mov	ax, es:[di].TE_parentID		; ax = parent
goDownLoop:
	add	di, size TreeEntry		; es:di = next one
	cmp	di, ds:[si].TI_treeBufferNext	; end of buffer?
	je	done				; reached end, didn't find any
	cmp	ax, es:[di].TE_parentID		; same parent?
	jne	goDownLoop			; no, continue loop
	mov	dx, di				; same parent, use this
done:
	mov	di, dx				; di = new selection
	stc					; change selection
exit:
	ret
TreeKeyDown	endp

TreeKeyUp	proc	near
;	mov	cx, MSG_GEN_VIEW_SCROLL_UP
	tst	di				; root?
	jz	exit				; yes, has no siblings, done
						;	(carry clear)
	mov	bx, di				; bx = selection
	mov	dx, di				; in case none found
	mov	ax, es:[di].TE_parentID		; ax = parent
	clr	di				; start at root
goUpLoop:
	cmp	ax, es:[di].TE_parentID		; same parent?
	jne	goUpNext			; no, continue loop
	mov	dx, di				; same parent, use this
goUpNext:
	add	di, size TreeEntry		; es:di = next one
	cmp	di, bx				; reached selection?
	jne	goUpLoop			; yes
	mov	di, dx				; di = new selection
	stc					; change selection
exit:
	ret
TreeKeyUp	endp

TreeKeyLeft	proc	near
;	mov	cx, MSG_GEN_VIEW_SCROLL_LEFT
	tst	di				; root?
	jz	done				; no parent (carry clear)
	mov	di, es:[di].TE_parentID		; di = new selection (parent)
	stc					; change selection
done:
	ret
TreeKeyLeft	endp

TreeKeyRight	proc	near
	class	TreeClass
;	mov	cx, MSG_GEN_VIEW_SCROLL_RIGHT
	mov	bx, di				; bx = selection
	clr	di				; start at root
goRightLoop:
	cmp	bx, es:[di].TE_parentID		; is parent the selection?
	je	done				; yes, select this one
	add	di, size TreeEntry		; else, es:di = next one
	cmp	di, ds:[si].TI_treeBufferNext	; end of buffer?
	jne	goRightLoop			; no, loop
	clc
	jmp	exit				; else, leave selection
done:
	stc					; change selection
exit:
	ret
TreeKeyRight	endp

if DBCS_PCGEOS

treeKeysTable	Chars \
	C_SYS_LEFT,
	C_SYS_RIGHT,
	C_SYS_UP,
	C_SYS_DOWN,
	C_SPACE,
	C_SYS_ENTER,
	C_SYS_HOME,
	C_SYS_END,
	C_PLUS_SIGN,
	C_MINUS_SIGN,
	C_SYS_NUMPAD_PLUS,
	C_SYS_NUMPAD_MINUS

treeKeysRoutineTable	nptr \
	TreeKeyLeft,
	TreeKeyRight,
	TreeKeyUp,
	TreeKeyDown,
	TreeKeyBlankEnter,
	TreeKeyBlankEnter,
	TreeKeyHome,
	TreeKeyEnd,
	TreeKeyPlus,
	TreeKeyMinus,
	TreeKeyPlus,
	TreeKeyMinus
.assert (length treeKeysRoutineTable eq length treeKeysTable)
TREE_KEYS_TABLE_SIZE = (length treeKeysTable)

else

treeKeysTable	label	word
	word	(CS_CONTROL shl 8) or VC_LEFT
	word	(CS_CONTROL shl 8) or VC_RIGHT
	word	(CS_CONTROL shl 8) or VC_UP
	word	(CS_CONTROL shl 8) or VC_DOWN
	word	(CS_BSW shl 8) or VC_BLANK
	word	(CS_CONTROL shl 8) or VC_ENTER
	word	(CS_CONTROL shl 8) or VC_HOME
	word	(CS_CONTROL shl 8) or VC_END
	word	(CS_BSW shl 8) or C_PLUS
	word	(CS_BSW shl 8) or C_MINUS
	word	(CS_CONTROL shl 8) or VC_NUMPAD_PLUS
	word	(CS_CONTROL shl 8) or VC_NUMPAD_MINUS
TREE_KEYS_TABLE_SIZE = ($-treeKeysTable)/2

treeKeysRoutineTable	label	word
	word	offset TreeKeyLeft
	word	offset TreeKeyRight
	word	offset TreeKeyUp
	word	offset TreeKeyDown
	word	offset TreeKeyBlankEnter
	word	offset TreeKeyBlankEnter
	word	offset TreeKeyHome
	word	offset TreeKeyEnd
	word	offset TreeKeyPlus
	word	offset TreeKeyMinus
	word	offset TreeKeyPlus
	word	offset TreeKeyMinus
TREE_KEYS_ROUTINE_TABLE_SIZE = ($-treeKeysRoutineTable)/2
.assert (TREE_KEYS_ROUTINE_TABLE_SIZE eq TREE_KEYS_TABLE_SIZE)

endif

TreeCode ends

;-----------------------------------------------------------------------------



TreeFileOp	segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartRename
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up rename dialog box with name of selected directory
		in "From" field

CALLED BY:	MSG_FM_START_RENAME

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartRename	method	TreeClass, MSG_FM_START_RENAME
	;
	; first disable destination name entry so user doesn't get to enter
	; a name and then see it overwritten by the default destination name
	;
	call	RenameSetup
	;
	; now, do all the stuff to put up the rename box
	;
	mov	ax, offset FileOperationUI:RenameCurDir
	mov	bx, offset FileOperationUI:RenameFromEntry
	mov	cx, offset FileOperationUI:RenameBox
	mov	dx, offset FileOperationUI:RenameStatus
	call	TreeStartFileOperation
	jc	done				; if error, done
	;
	; then update destination name field characteristics for this file
	; and fill source name as default destination name
	;
	call	RenameStuff
done:
	ret
TreeStartRename	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartDeleteThrowAway
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up delete dialog box with name of selected directory
		in "Delete" field.  Also handle ThrowAway

CALLED BY:	MSG_FM_START_DELETE, MSG_FM_START_THROW_AWAY

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version
	dlitwin	6/2/92		generalized to work with Throw Away

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartDeleteThrowAway	method	TreeClass, MSG_FM_START_DELETE,
						MSG_FM_START_THROW_AWAY
	.enter
	;
	; error if delete/throw away root directory
	;
	push	ax				; save message
	call	TreeMoveCopyCheckRoot
	pop	ax				; ax = DELETE/THROW_AWAY
	jc	exit				; error reported

	;
	; clear transfer buffer for selected folder
	;
	push	ax
	call	CreateTreeTransferBuffer
	pop	cx
	jc	done				; if error handled, exit
	;
	; delete or throw away the folder
	;	bx = tree transfer block
	;
	cmp	cx, MSG_FM_START_DELETE
	jne	mustBeThrowAway

	call	WastebasketDeleteFiles		; (handles errors itself)
	jmp	done

mustBeThrowAway:
	mov	ss:[usingWastebasket], WASTEBASKET_WINDOW

NOFXIP <	segmov	ds, cs, si	; point ds:si to rootString	>
NOFXIP <	mov	si, offset rootString				>
FXIP <		segmov	ds, ss, si					>
FXIP <		mov	si, C_BACKSLASH					>
FXIP <		push	si						>
FXIP <		mov	si, sp			;ds:si = root dir	>
	mov	dx, SP_WASTE_BASKET
	mov	bp, mask CQNF_MOVE
	mov	cx, -1				; definitely not zero
	call	ProcessDragFilesCommon
FXIP <		pop	cx						>
	mov	ss:[usingWastebasket], NOT_THE_WASTEBASKET

done:
	call	MemFree

exit:
	.leave
	ret
TreeStartDeleteThrowAway	endm

ife FULL_EXECUTE_IN_PLACE
LocalDefNLString rootString	<C_BACKSLASH, 0>
endif

CreateTreeTransferBuffer	proc	near
	class	TreeClass
	call	TreeCreateTransferReturnError
	jnc	done
	call	DesktopOKError
	stc
done:
	ret
CreateTreeTransferBuffer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeCreateTransferReturnError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a FileQuickTransfer block for the selected folder
		in the tree, returning an error, rather than reporting it,
		if that's not possible.

CALLED BY:	CreateTreeTransferBuffer, TreeStartFileOperation
PASS:		ds:bx	= TreeInstance
RETURN:		carry set on error:
			ax	= error code
		carry clear if successful:
			bx	= block handle
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeCreateTransferReturnError proc near
	class	TreeClass

	uses	ds

	.enter

	mov	si, bx				; deref. instance data
	mov	bx, ds:[si].TI_treeBuffer
	call	MemLock
	push	bx
	mov	es, ax
	mov	di, ds:[si].TI_selectedFolder
	push	di				; save selected folder
	tst	di				; is it root directory?
	jz	rootDir				; yes
	mov	di, es:[di].TE_parentID		; else, get parent
rootDir:
	mov	dx, BDN_PATHNAME
	call	BuildDirNameFar			; dgroup:dx = root or parent
						;		pathname
	pop	di				; retrieve selected folder
	;
	; allocate transfer block for root or parent pathname
	;
	mov	ax, size FileOperationInfoEntry + size FileQuickTransferHeader
	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE or \
			(mask HAF_ZERO_INIT shl 8)
	call	MemAlloc
	jnc	noMemErr
	mov	bx, ERROR_INSUFFICIENT_MEMORY
	stc					; indicate error
	jmp	short done

noMemErr:
	;
	; save parent pathname (or root) in file quick transfer header
	;
	push	ds:[si].TI_disk	; save disk handle
	push	es				; save tree buffer segment
	push	di				; save selected folder
	mov	es, ax				; es:di = path buf. in header
	mov	di, offset FQTH_pathname
FXIP<	mov	si, bx							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	bx, si							>
NOFXIP<	segmov	ds, dgroup, si						>
	mov	si, dx				; ds:si = pathname of dir.
	mov	cx, size PathName
	rep 	movsb				; copy over pathname
	pop	si				; si = selected folder
	pop	ds				; ds = segment of tree buffer
	;
	; setup rest of header
	;	FQTH_nextBlock and FQTH_UIFA are ZERO
	;
	mov	es:[FQTH_numFiles], 1		; only one file - selected dir.
	pop	es:[FQTH_diskHandle]		; source disk handle
	;
	; add name of selected directory to file quick transfer buffer
	;
	; If the root dir is selected, then just use "." instead of
	; "\", since the parent's name is "\", and we'll get into
	; trouble if we don't use ".".  The only operation allowed is
	; create dir, so just copy the name, as that's all we need.

	mov	di, offset FQTH_files

	tst	si
	jz	root

	add	si, offset TE_attrs.TA_name	; ds:si = dir's name
						;	(or C:\ for root)
						; es:di = buffer for 8.3 name

	mov	cx, size TA_name + size TA_type + size TA_attrs + \
			size TA_flags + size TA_pathInfo

	CheckHack <offset TA_name eq offset FOIE_name>
	CheckHack <offset TA_type eq offset FOIE_type>
	CheckHack <offset TA_attrs eq offset FOIE_attrs>
	CheckHack <offset TA_flags eq  offset FOIE_flags>
	CheckHack <offset TA_pathInfo eq offset FOIE_pathInfo>
copyIt:
	rep movsb				; copy over directory name,
						;  file type & file attrs

	call	MemUnlock			; unlock transfer block
	clc					; indicate good file list
done:
	mov_tr	ax, bx				; ax = file list
	pop	bx				; unlock tree buffer
	call	MemUnlock			;	(preserves flags)
	mov	bx, ax				; bx = file list (leave in
						;  ax too in case it's an
						;  error code...)
	.leave
	ret
root:
	segmov	ds, cs
	mov	si, offset dotPath
	mov	cx, size dotPath
	jmp	copyIt
TreeCreateTransferReturnError	endp

SBCS < dotPath	char	".",0	>
DBCS < dotPath  wchar	".",0	>

if INSTALLABLE_TOOLS

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fetch the selected directory selected in the tree

CALLED BY:	MSG_META_APP_GET_SELECTION
PASS:		*ds:si	= Tree object
		ds:bx	= Tree object
RETURN:		ax	= handle of quick transfer block, or 0 if couldn't
			  allocate one
DESTROYED:	cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	8/25/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeGetSelection method dynamic TreeClass, MSG_META_APP_GET_SELECTION
	.enter
	call	TreeCreateTransferReturnError
	jnc	done
	clr	bx		; signal failure
done:
	mov_tr	ax, bx
	.leave
	ret
TreeGetSelection endm
endif ; INSTALLABLE_TOOLS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartCreateDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up create dir dialog box

CALLED BY:	MSG_FM_START_CREATE_DIR

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartCreateDir	method	TreeClass, MSG_FM_START_CREATE_DIR
	mov	ax, offset FileOperationUI:CreateDirCurDir
	clr	bx
	mov	cx, offset FileOperationUI:CreateDirBox
	mov	dx, offset FileOperationUI:CreateDirStatus
	call	TreeStartFileOperation
	jc	done
	call	CreateDirStuff		; clear create dir name field
done:
	ret
TreeStartCreateDir	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up move dialog box with name of selected directory
		in "From" field

CALLED BY:	MSG_FM_START_MOVE

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartMove	method	TreeClass, MSG_FM_START_MOVE
	;
	; error if moving root directory
	;
	call	TreeMoveCopyCheckRoot
	jc	done				; error reported

	push	bx				; save instance data offset
	mov	ax, handle MoveToEntry
	mov	bx, offset MoveToEntry
	call	TreeMoveCopySetCurDir
	;
	; bring up move box, modally
	;
	mov	bx, handle MoveBox
	mov	si, offset MoveBox
	call	UserDoDialog
	pop	bx				; retrieve instance data
	cmp	ax, OKCANCEL_OK
	jne	done
	;
	; build tree transfer buffer
	;
	call	CreateTreeTransferBuffer	; bx = buffer
	jc	done				; if error handled, done
	;
	; do move
	;
	call	MenuMoveCommon			; handles errors
done:
	ret
TreeStartMove	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeMoveCopySetCurDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets a file selector to the current folder directory

CALLED BY:	TreeStartCopy, TreeStartMove

PASS:		*ds:si = tree object
		^lax:bx - File Selector to set to current directory

RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeMoveCopySetCurDir	proc	near
	uses	cx, dx, bp, di, si, es
	class	TreeClass
	.enter

	;
	; TREE is GeoManager-only, change only the first time
	;
	tst	ss:[startFromScratch]		; restoring from state?
	jz	leaveAlone			; yes, leave alone
	push	ax, bx, si
	mov	si, bx				; ^lbx:si = File Selector
	mov	bx, ax
	mov	ax, MSG_VIS_FIND_PARENT
	call	ObjMessageCallFixup		; any vis parent?
	pop	ax, bx, si
	tst	cx
	jnz	leaveAlone			; yes, leave alone

	push	ax, bx				; save file selector object

	mov	di, ds:[si]			; dereference this handle
	mov	bx, ds:[di].TI_treeBuffer
	call	MemLock
	mov	es, ax
	mov	di, ds:[di].TI_selectedFolder
	;
	; shouldn't ever be the root, but check just the same...
	;
	mov	dx, es:[di].TE_parentID
	cmp	dx, NIL
	je	gotBufferEntryNum
	mov	di, dx				; set to parent if not at root
gotBufferEntryNum:
	mov	dx, BDN_PATHNAME
	call	BuildDirNameFar			; es:di is tree buffer entry
	call	MemUnlock
NOFXIP<	mov	cx, segment dgroup		; returns path in dgroup:dx >
FXIP<	push	ds							>
FXIP<	GetResourceSegmentNS dgroup, ds, TRASH_BX			>
FXIP<	mov	cx, ds							>
FXIP<	pop	ds							>
	mov	di, ds:[si]
	mov	bp, ds:[di].TI_disk

	mov	ax, MSG_GEN_PATH_SET
	pop	bx, si				; restore file selector object
	call	ObjMessageCallFixup

leaveAlone:
	.leave
	ret
TreeMoveCopySetCurDir	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartRecover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allow user to choose file to undelete and where to undelete it
		to, which defaults to current selection if not in the
		Wastebasket.  If current selection is in the Wastebasket, then
		the destination is set to SP_TOP and this selection (if not the
		Wastebasket itself) will be undeleted.

CALLED BY:	MSG_FM_START_RECOVER

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartRecover	method	TreeClass, MSG_FM_START_RECOVER
	;
	; error if moving root directory
	;
	call	TreeMoveCopyCheckRoot
	LONG	jc	exit			; error reported

	push	si
	mov	bp, SP_TOP			; default to SP_TOP
NOFXIP <	mov	cx, cs			; rootString in cx:dx	>
NOFXIP <	mov	dx, offset rootString				>
FXIP <		mov	cx, ss						>
FXIP <		mov	dx, C_BACKSLASH					>
FXIP <		push	dx						>
FXIP <		mov	dx, sp			;cx:dx = rootStirng	>
	mov	ax, MSG_GEN_PATH_SET
	mov	bx, handle RecoverToEntry
	mov	si, offset RecoverToEntry	; set destination directory box
	call	ObjMessageCall			; to SP_TOP if we are grabbing
FXIP <		pop	si			;restore the stack	>
	pop	si
	jc	handleError

	mov	di, ds:[si]			; dereference this handle
	mov	bx, ds:[di].TI_treeBuffer
	call	MemLock
	mov	es, ax
	mov	di, ds:[di].TI_selectedFolder
	mov	dx, BDN_PATHNAME
	call	BuildDirNameFar			; es:di is tree buffer entry
	call	MemUnlock
	mov	ax, dx				; put pathname offset in ax
	mov	di, ds:[si]
	mov	dx, ds:[di].TI_disk
	push	ds, si				; save tree handle
	segmov	ds, ss, si
	mov	si, ax				; dx,ds:si is path
	call	IsThisInTheWastebasket
	mov	ax, si				; put string offset in ax
	pop	ds, si				; restore tree handle
	jnc	notInWastebasket
	jz	getSourceFile

	mov	bx, ds:[si]			; point ds:bx to tree instance
	call	CreateTreeTransferBuffer
	jc	exit
	jmp	getDestDir

notInWastebasket:
	mov	bp, dx				; disk handle in bp
	mov	cx, ss				; path in cx:dx
	mov	dx, ax
	mov	ax, MSG_GEN_PATH_SET
	mov	bx, handle RecoverToEntry
	mov	si, offset RecoverToEntry	; set destination directory box
	call	ObjMessageCall			; to shown directory if not in
	jc	handleError			; the Wastebasket directory	

getSourceFile:
	call	RecoverGetSourceFile		; returns bx=QuickTransferBlock
	jc	handleError			;   with file to undelete
						; si = zero means cancel
getDestDir:
	push	bx				; save QuickTransferBlock
	mov	bx, handle RecoverBox
	mov	si, offset RecoverBox
	call	UserDoDialog			; bring up box, modally
	pop	bx

	cmp	ax, OKCANCEL_OK
	jne	exit

	call	MenuRecoverCommon
	jmp	exit

handleError:
	tst	si
	jz	exit
	call	DesktopOKError
exit:
	ret
TreeStartRecover	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up copy dialog box with name of selected directory
		in "From" field

CALLED BY:	MSG_FM_START_COPY

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartCopy	method	TreeClass, MSG_FM_START_COPY
	;
	; error if moving root directory
	;
	call	TreeMoveCopyCheckRoot
	jc	done				; error reported

	mov	ax, handle CopyToEntry
	mov	bx, offset CopyToEntry
	call	TreeMoveCopySetCurDir
	;
	; bring up copy box, modally
	;
	push	bx				; save instance data offset
	mov	bx, handle CopyBox
	mov	si, offset CopyBox
	call	UserDoDialog
	pop	bx				; retrieve instance data
	cmp	ax, OKCANCEL_OK
	jne	done
	;
	; build tree transfer buffer
	;
	call	CreateTreeTransferBuffer	; bx = buffer
	jc	done				; if error handled, done
	;
	; do copy
	;
	call	MenuCopyCommon			; handles errors
done:
	ret
TreeStartCopy	endm

TreeMoveCopyCheckRoot	proc	near
	class	TreeClass

	cmp	ds:[bx].TI_selectedFolder, 0	; root?
	clc					; assume not
	jne	done				; nope, exit with carry clear
	mov	ax, ERROR_ROOT_FILE_OPERATION
	call	DesktopOKError
	stc					; indicate error
done:
	ret
TreeMoveCopyCheckRoot	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartDuplicate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up duplicate dialog box with name of selected directory
		in "From" field

CALLED BY:	MSG_FM_START_DUPLICATE

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartDuplicate	method	TreeClass, MSG_FM_START_DUPLICATE
	;
	; first disable destination name entry so user doesn't get to enter
	; a name and then see it overwritten by the default destination name
	;
	call	DuplicateSetup
	;
	; now, do all the stuff to put up the duplicate box
	;
	mov	ax, offset FileOperationUI:DuplicateCurDir
	mov	bx, offset FileOperationUI:DuplicateFromEntry
	mov	cx, offset FileOperationUI:DuplicateBox
	mov	dx, offset FileOperationUI:DuplicateStatus
	call	TreeStartFileOperation
	jc	done				; if error, done
	;
	; then update destination name field characteristics for this file
	; and fill source name as default destination name
	;
	call	DuplicateStuff
done:
	ret
TreeStartDuplicate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartChangeAttr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up change attr dialog box with name of selected directory
		in "From" field

CALLED BY:	MSG_FM_START_CHANGE_ATTR

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartChangeAttr	method	TreeClass, MSG_FM_START_CHANGE_ATTR
	mov	ax, offset FileOperationUI:ChangeAttrCurDir
	mov	bx, offset FileOperationUI:ChangeAttrNameList
	mov	cx, offset FileOperationUI:ChangeAttrBox
	mov	dx, offset FileOperationUI:ChangeAttrStatus
	call	TreeStartFileOperation
	jc	done
	;
	; show attributes for first file
	;
	call	ChangeAttrShowAttrs
done:
	ret
TreeStartChangeAttr	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up get info dialog box with name of selected directory

CALLED BY:	MSG_FM_GET_INFO

PASS:		ds:si - instance handle of tree object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartGetInfo	method	TreeClass, MSG_FM_GET_INFO
	;
	; set up and bring up GetInfo dialog box
	;
	mov	ax, offset FileOperationUI:GetInfoPath
	mov	bx, offset FileOperationUI:GetInfoFileList
	mov	cx, offset FileOperationUI:GetInfoBox
	clr	dx				; no status
	call	TreeStartFileOperation
	jc	done				; if error, done
	;
	; show directory info
	;
	call	ShowCurrentGetInfoFile
done:
	ret
TreeStartGetInfo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeStartFileOperation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	put up file operation dialog box, setting current directory
		and source file name fields

CALLED BY:	INTERNAL
			TreeStartRename
			TreeStartDelete
			TreeStartCreateDir
			TreeStartMove
			TreeStartCopy
			TreeStartDuplicate

PASS:		ds:si - instance handle of Tree object
		ax - lmem chunk handle of current directory Text object
		bx - lmem chunk handle of source filename Text object
		cx - lmem chunk handle of dialog box
		dx - lmem chunk handle of status string

RETURN:		carry set if error
		carry clear otherwise

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeStartFileOperation	proc	near
	class	TreeClass

	mov	si, ds:[si]			; deref.
	cmp	ds:[si].TI_treeBuffer, 0
	je	earlyAbort
	;
	; save handles
	;
	push	ds:[si].TI_disk	; save src disk handle
	push	cx				; save dialog box handle
	push	dx				; save status string handle
	push	bx				; save source filenane handle
	push	ax				; save current directory handle

	;
	; build complete pathname of selected directory
	;
	mov	di, ds:[si].TI_selectedFolder	; di = selected folder
	tst	di				; is it root directory?
	jnz	fileOpOK			; no, continue
	cmp	cx, offset FileOperationUI:CreateDirBox	; create dir?
	je	fileOpOK			; yes, allow CreateDir with root
	mov	ax, ERROR_ROOT_FILE_OPERATION
errorClearStack:
	call	DesktopOKError			; report error
	add	sp, 10				; dump parameters
earlyAbort:
	stc					; indicate error
	jmp	done				; ...and finish up
fileOpOK:
	mov	bx, si				; ds:bx <- instance
	call	TreeCreateTransferReturnError
	jc	errorClearStack

	pop	si				; si <- cur dir text object
	call	MemLock
	push	ds
	mov	ds, ax
	mov	cx, ax
	mov	dx, offset FQTH_pathname
	mov	bp, ds:[FQTH_diskHandle]
	pop	ds
	push	bx
	mov	bx, handle FileOperationUI
	mov	ax, MSG_GEN_PATH_SET
	push	cx
	call	ObjMessageCallFixup
	pop	cx
	cmp	si, offset FileOperationUI:CreateDirCurDir	; create dir?
	jne	pathSet
	
	;
	; For create dir, the current dir is the selected dir, not the
	; parent.  Unless the selected dir is ROOT, which seems to
	; cause weird problems which I'm not interested in looking
	; into, so I'll just add a cheesy hack
	;
	
	mov	dx, offset FQTH_files.FOIE_name
	clr	bp
	mov	ax, MSG_GEN_PATH_SET
	call	ObjMessageCallFixup
pathSet:
	pop	bx
	call	MemUnlock
	pop	si				; *FileOperationUI:si = source
						;  fname FileOpList object
	tst	si
	jz	noSourceName
	mov	dx, bx				; dx <- FQT block handle
	mov	bx, handle FileOperationUI	; ^lbx:si = file list object 
	mov	ax, MSG_SET_FILE_LIST
	call	ObjMessageCallFixup
	jmp	setStatus

noSourceName:
	;
	; No source name, so transfer block no longer needed.
	; 
	call	MemFree
	mov	bx, handle FileOperationUI

setStatus:
	;
	; clear status string
	;
	pop	si				; bx:si = status string
	tst	si
	jz	noStatusString
NOFXIP <	mov	dx, cs						>
NOFXIP <	mov	bp, offset treeNullStatusString			>
FXIP <		mov	dx, ss						>
FXIP <		clr	bp						>
FXIP <		push	bp						>
FXIP <		mov	bp, sp			;dx:bp = null string	>
		call	CallFixupSetText
FXIP <		pop	cx			;restore the stack	>
noStatusString:
	;
	; store disk handle and dialog box and enable dialog box
	;
	pop	si				; bx:si = dialog box
	pop	cx				; cx = disk handle of operation
	mov	ax, MSG_FOB_SET_DISK_HANDLE
	call	ObjMessageCall
	cmp	si, offset FileOperationUI:GetInfoBox	; don't put up GetInfo
							;	yet
	je	noBoxYet
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessageFixup
noBoxYet:
	clc					; indicate no error
done:
	ret
TreeStartFileOperation	endp

ife FULL_EXECUTE_IN_PLACE
treeNullStatusString	byte 0
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeGetDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return disk info for this instance of Tree Class

CALLED BY:	MSG_GET_DISK_INFO

PASS:		object stuff
		dx:bp = buffer for disk info
			(size DiskInfoStruct bytes)

RETURN:		buffer filled with disk info
		ax	= disk handle

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeGetDiskInfo	method	dynamic TreeClass, MSG_GET_DISK_INFO
	mov	ax, ds:[di].TI_disk
	lea	si, ds:[di].TI_diskInfo
	mov	es, dx
	mov	di, bp
	mov	cx, size DiskInfoStruct
	rep movsb
	ret
TreeGetDiskInfo	endm


TreeFileOp	ends

;-----------------------------------------------------------------------------



TreeCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start/restart tree object

CALLED BY:	MSG_META_RELOCATE/MSG_META_UNRELOCATE

PASS:		*ds:si	= object
		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
RETURN:		carry - set if error
		bp - unchanged

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeRelocate	method	TreeClass, reloc

	GetResourceSegmentNS dgroup, es		; es = dgroup
	cmp	es:[forceQuit], TRUE		; will be quitting?
	jne	noQuit
	ornf	ds:[bx].TI_displayMode, mask TIDM_BOGUS	; mark as bogus
	jmp	short TR_exit			; do nothing else

noQuit:
	cmp	ax, MSG_META_RELOCATE
	jne	TR_exit

	mov	es:[treeRelocated], TRUE

	mov	di, ds:[si]			; deref.
	;
	; clear subview list
	;
	mov	cx, VIEW_MAX_SUBVIEWS
	clr	bx
TR_loop:
	clr	ds:[di][bx].TI_subviews		; remove from subview list
	add	bx, 2				; move to next entry
	loop	TR_loop
	
	;
	; See if there's a saved disk handle lurking in our vardata.
	; 
	mov	ax, TEMP_TREE_SAVED_DISK_HANDLE
	call	ObjVarFindData
	jnc	useSystemDisk		; => not saved, so do nothing
	
	;
	; Yup. Try and restore it. Don't bother prompting the user for the disk,
	; though, as it ain't crucial...
	; 
	clr	cx			; no callback
	push	si
	mov	si, bx			; ds:si <- data
	call	DiskRestore
	pop	si
	mov_tr	bx, ax
	jnc	useThisDisk

	;
	; If couldn't restore that disk, see if we can register a disk
	; currently in the drive.
	; 
	mov	di, ds:[si]
	mov	ax, ds:[si].TI_drive
	call	DiskRegisterDiskSilently
	jnc	useThisDisk		; yup.

useSystemDisk:
	;
	; Use the system disk by default.
	; 
	mov	bx, es:[geosDiskHandle]

useThisDisk:
	mov	ds:[di].TI_disk, bx	; save disk handle
	;
	; mark tree as needing to be scanned, will be done on first redraw
	;
;; Always do this as we don't save collapsed branch buffer to disk anymore
;; - 5/7/90
	ornf	ds:[di].TI_displayMode, mask TIDM_ROOT_LEVEL
;;
	andnf	ds:[di].TI_displayMode, not mask TIDM_SCANNED
	mov	ds:[di].TI_treeBuffer, 0	; no tree buffer yet
	mov	ds:[di].TI_treeBufferSize, 0
	mov	ds:[di].TI_treeBufferNext, 0
TR_exit:
	segmov	es, <segment TreeClass>, di
	mov	di, offset TreeClass
	call	ObjRelocOrUnRelocSuper
	ret
TreeRelocate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TreeBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	redirect help request to app object

CALLED BY:	MSG_META_BRING_UP_HELP

PASS:		*ds:si	= TreeClass object
		ds:di	= TreeClass instance data
		es 	= segment of TreeClass
		ax	= MSG_META_BRING_UP_HELP

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/12/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TreeBringUpHelp	method	dynamic	TreeClass, MSG_META_BRING_UP_HELP

	mov	bx, handle FileSystemDisplay
	mov	si, offset FileSystemDisplay
	clr	di
	GOTO	ObjMessage

TreeBringUpHelp	endm

TreeCode	ends
