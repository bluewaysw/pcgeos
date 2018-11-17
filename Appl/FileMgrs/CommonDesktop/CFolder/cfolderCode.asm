COMMENT @----------------------------------------------------------------------
	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		cfolderCode.asm
AUTHOR:		Brian Chin


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cfolderClass.asm

DESCRIPTION:
	This file contains folder display object.

	$Id: cfolderCode.asm,v 1.4 98/06/03 13:25:25 joon Exp $

------------------------------------------------------------------------------@
FolderCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draws files in directory

CALLED BY:	MSG_DV_DRAW

PASS:		*ds:si - FolderClass object
		ds:di - FolderClass instance data
		es - segment of FolderClass
		bp - gState

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/17/89		Initial version
	brianc	8/10/89		changed to use display list

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDraw	method	dynamic FolderClass, MSG_DV_DRAW

	test	ds:[di].FOI_folderState, mask FOS_BOGUS	; will be closed?
	jnz	quitJMP				; yes, do nothing

	push	di
	mov	di, bp				; di = gstate
	call	GrGetMaskBounds			; ax, bx, cx, dx = bounds
	pop	di
	jc	quitJMP				; nothing to draw
	;
	; ensure that folder has been scanned
	;

	test	ds:[di].FOI_folderState, mask FOS_SCANNED
	jnz	scanned

	push	ax, bp				; save gState
	mov	ax, MSG_RESCAN			; rescan folder
	call	ObjCallInstanceNoLock
	pop	ax, bp				; retrieve gState
	DerefFolderObject	ds, si, di 

scanned:
	test	ds:[di].FOI_folderState, mask FOS_BOGUS	; will be closed?
	jz	noError				; yes, do nothing more


quitJMP:
	jmp	quit

noError:
	call	FolderFixLayout

	;
	; make sure we have DisplayType
	;
	call	AssertFolderDisplayType

	;
	; draw folder contents
	;
	call	FolderLockBuffer
						; check if displaying dir. size
	mov	di, bp			; gState
	call	GrGetMaskBounds		; get drawing area (ax -> dx)
	;
	; the following stuff is to support drag scrolling while lasso'ing
	; files
	;
	test	ss:[fileDragging], mask FDF_REGION	; lasso'ing?
	jz	444$					; nope, skip

	ornf	ss:[fileDragging], mask FDF_EXPOSED	; leave our mark
	push	ax, bx, di			; save left, top, gstate
	mov	di, ss:[regionSelectGState]
	tst	di				; gasp!, can't clear region
	jz	noRegion
	call	ClearLastRegion			; clear unexposed part of
						;	old lasso
noRegion:
	pop	ax, bx, di			; retrieve stuff
	call	FolderSetBackgroundFillPattern
	jc	skipFill
	call	GrFillRect			;	(clears rest of old

skipFill:
	push	ax				;	 lasso)
	mov	ax, C_BLACK or CF_INDEX shl 8	; restore draw color
	call	GrSetAreaColor
	pop	ax

444$:
	DerefFolderObject	ds, si, di
	mov	di, ds:[di].FOI_displayList	; get beginning of display list

startLoop:
	cmp	di, NIL				; check if end-of-list marker
	je	done				; if so, done
	cmp	es:[di].FR_boundBox.R_bottom, bx ; check name/icon bottom < top
	jl	noDraw			; if so, don't draw this one
	cmp	es:[di].FR_boundBox.R_top, dx	; is name/icon top > bottom
	jg	noDraw			; if so, don't draw this one
	cmp	es:[di].FR_boundBox.R_right, ax	; check name/icon right < left
	jl	noDraw			; if so, don't draw this one
	cmp	es:[di].FR_boundBox.R_left, cx	; check name/icon left > right
	jg	noDraw			; if so, don't draw this one
	push	ax, bx				; save drawing bounds

if _NEWDESK
	mov	ax, mask DFI_CLEAR or mask DFI_DRAW	; always clear & draw
else							; (really for BW only)
	mov	ax, mask DFI_DRAW		; draw icon (for unselected
						;	files)
	test	es:[di].FR_state, mask FRSF_SELECTED	; check if selected
	jz	noSelect				; if not, continue
	mov	ax, mask DFI_CLEAR or mask DFI_DRAW	; else, clear before
							; drawing
noSelect:
endif
	call	DrawFolderObjectIcon		; draw the icon for this object
	pop	ax, bx				; save drawing bounds

noDraw:
	mov	di, es:[di].FR_displayNext	; get next item in display list
	jmp	startLoop			; go back to do it
done:

	DerefFolderObject	ds, si, di

	; Draw cursor if folder is the target
	test	ds:[di].FOI_folderState, mask FOS_TARGET
	jz	afterCursor
	call	FolderDrawCursor

afterCursor:
	call	FolderUnlockBuffer
quit:
	ret
FolderDraw	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AssertFolderDisplayType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the folder's FOI_displayType variable, calling
		the view if necessary

CALLED BY:	FolderDraw

PASS:		*ds:si - FolderClass object

RETURN:		FOI_displayType updated

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AssertFolderDisplayType	proc	near

	class	FolderClass
	
	uses	bx, bp

	.enter

	DerefFolderObject	ds, si, bx
	tst	ds:[bx].FOI_displayType
	jnz	done

	mov	di, mask MF_CALL
	mov	cx, VUQ_DISPLAY_SCHEME
	mov	ax, MSG_VIS_VUP_QUERY
	call	FolderCallView

	jc	answered
	clr	ah

answered:
	mov	ds:[bx].FOI_displayType, ah

done:

	.leave
	ret
AssertFolderDisplayType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderViewSizeChanged
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with the new view bounds

PASS:		*ds:si - folder object
		cx, dx - new window bounds

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/19/89		Initial version
	martin	11/22/92	reworked to handle icon positioning

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderViewSizeChanged	method	dynamic	FolderClass, 
				MSG_META_CONTENT_VIEW_SIZE_CHANGED,
				MSG_META_CONTENT_VIEW_WIN_OPENED

		class	FolderClass

		.enter

if GPC_FOLDER_WINDOW_MENUS
	;
	; hack for restore from state, attach Options menu if wastebasket
	;
	push	ax, es, di
	mov	ax, segment NDWastebasketClass
	mov	es, ax
	mov	di, offset NDWastebasketClass
	call	ObjIsObjectInClass	; C set if so
	pop	ax, es, di
	jnc	notWaste
	push	cx, dx, si
	DerefFolderObject	ds, si, di
	mov	bx, ds:[di].FOI_windowBlock
	mov	si, FOLDER_WINDOW_OFFSET
	mov	ax, MSG_GEN_FIND_CHILD
	mov	cx, handle OptionsMenu
	mov	dx, offset OptionsMenu
	call	ObjMessageCallFixup	; C clear if found
	jnc	found			; already attached
	mov	ax, MSG_GEN_ADD_CHILD
	mov	bp, CCO_LAST
	call	ObjMessageCallFixup
	mov	ax, MSG_GEN_SET_USABLE
	mov	bx, handle OptionsMenu
	mov	si, offset OptionsMenu
	mov	dl, VUM_NOW
	call	ObjMessageCallFixup
found:
	pop	cx, dx, si
	DerefFolderObject	ds, si, di
notWaste:
endif
		
		cmp	cx, ds:[di].FOI_winBounds.P_x
		jne	set
		cmp	dx, ds:[di].FOI_winBounds.P_y
		je	done
set:
		movP	ds:[di].FOI_winBounds, cxdx
		ornf	ds:[di].FOI_positionFlags, mask FIPF_RECALC
		cmp	ax, MSG_META_CONTENT_VIEW_SIZE_CHANGED
		jne	afterInval
		
		mov	ax, MSG_REDRAW		; actually, invalidate.
		call	ObjCallInstanceNoLock 
afterInval:
		call	FolderFixLayout

done:
		.leave
		ret
FolderViewSizeChanged	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderFixLayout
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position any unpositioned icons, if necessary.

CALLED BY:	FolderViewSizeChanged, FolderDraw

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderFixLayout	proc near
		uses	ax,bx,cx,dx,di,si,bp

		class	FolderClass

		.enter

		DerefFolderObject	ds, si, di 

		test	ds:[di].FOI_positionFlags, mask FIPF_RECALC
		jz	done
if _NEWDESK
	;
	; First, Check if this folder has icon positions stored as
	; percentages...  If so, convert them now.
	;

		test	ds:[di].FOI_positionFlags, mask FIPF_PERCENTAGES
		jz	placeUnpositioned
		call	FolderConvertPercentagesToPositions

placeUnpositioned:
endif		; if _NEWDESK
		
	;
	; Handle any needed repositioning of icons if changed.
	;
		call	FolderPlaceUnpositionedIcons

	;
	; Recalc the doc bounds, and send them to the view if changed.
	;
		call	FolderRecalcDocBounds
if _NEWDESK
	;
	; if we had no gstate, we didn't update scrollers, so don't say
	; we recalc'ed
	;
		tst	ds:[di].DVI_gState
		jz	done
endif
		BitClr	ds:[di].FOI_positionFlags, FIPF_RECALC
done:
		.leave
		ret
FolderFixLayout	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGainTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	this folder window has been made the target

CALLED BY:	MSG_META_GAINED_TARGET_EXCL

PASS:		*ds:si - Folder object
		ds:bx, ds:di - Folder instance data

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGainTarget	method	dynamic FolderClass, 
					MSG_META_GAINED_TARGET_EXCL


	test	ds:[bx].FOI_folderState, mask FOS_BOGUS	; will be closed?
	LONG	jnz	exit			; yes, do nothing
	;
	; check if we are target already; if so, exit
	;	(in case UI sends us two methods in a row)
	;
	test	ds:[bx].FOI_folderState, mask FOS_TARGET ; check if target
	jnz	exit			; if so, do nothing

;do this in MSG_UNHIDE_SELECTION to avoid a visual glitch which occurs if the
;cursor is drawn before the file selection inversion - brianc 9/9/94
;	call	FolderLockAndDrawCursor 	; draw cursor

if _GMGR		; _NEWDESK has no LRU
	;
	; update LRU table
	;
	push	bx, si
	mov	bx, ds:[bx].FOI_windowBlock	; bx:si = Folder Window
	mov	si, FOLDER_WINDOW_OFFSET
	call	UpdateWindowLRUStatus
	pop	bx, si
endif		; if _GMGR

	;
	; show selected files
	;
	push	bx				; save instance data addr.
						; show waiting for update
	ornf	ds:[bx].FOI_folderState, mask FOS_UPDATE_PENDING
	mov	bx, ds:[0]
	mov	ax, MSG_UNHIDE_SELECTION
	call	ObjMessageForce			; queue up unhide method
	pop	bx				; retrieve instance addr.

	ornf	ds:[bx].FOI_folderState, mask FOS_TARGET ; mark as target
	mov	ax, ds:[LMBH_handle]		; get folder block handle
	mov	ss:[targetFolder], ax		; save as target folder

if _GMGR		; _NEWDESK needs no menu updating
	;
	; send display options for the target folder to the display
	; options dialog box
	;
	;	*ds:si - Folder object
	;
	mov	bx, ds:[si]
	mov	ax, MSG_GEN_SET_ENABLED		; enable stuff first
	call	FolderTargetCommon
endif		; if _GMGR
	;
	;	NewDesk does update its Sort and View menus though...
	;
	mov	ax, MSG_SEND_DISPLAY_OPTIONS
	call	ObjCallInstanceNoLock		; send the options

if _GMGR
if _FCAB		; disable Close Directory if DOCUMENT
	;
	; disable Close Directory button if this is DOCUMENT directory
	; or root (for floppies)
	;	*ds:si - folder instance
	;
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath
	mov	dx, MSG_GEN_SET_ENABLED		; assume not DOCUMENT dir or
						;  root.
	cmp	{word}ds:[bx].GFP_path, '\\' or (0 shl 8)
	jne	enableDisableCloseDir
	cmp	ax, SP_DOCUMENT			; root of SP_DOCUMENT?
	je	disableUpDir			; yes -- definitely disable

	test	ax, DISK_IS_STD_PATH_MASK	; some other std path?
	jnz	enableDisableCloseDir		; yes -- must be below
						;  SP_DOCUMENT, so going up is
						;  fine.
disableUpDir:
	mov	dx, MSG_GEN_SET_NOT_ENABLED

enableDisableCloseDir:
	mov	ax, dx				; ax = disable/enable method
	mov	bx, handle CloseDirectory
	mov	si, offset CloseDirectory
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
endif		; if _FCAB
endif		; if _GMGR
exit:

	ret
FolderGainTarget	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderLostTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	this folder window has lost the target

CALLED BY:	MSG_META_LOST_TARGET_EXCL

PASS:		*ds:si - FolderClass object
		ds:di - FolderClass instance data
		ds:bx - FolderClass instance data

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		if (files selected) {
			hide selection;
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderLostTarget	method	dynamic FolderClass, MSG_META_LOST_TARGET_EXCL
	.enter
	;
	; stop region, if any
	;
	call	ClearRegionIfNeeded
	;
	; do a trivial reject
	;
	test	ds:[bx].FOI_folderState, mask FOS_BOGUS	; will be closed?
	jnz	exit			; yes, do nothing
	;
	; check if we aren't target already; if so, exit
	;
	test	ds:[bx].FOI_folderState, mask FOS_TARGET ; check if not target
	jz	exit			; if so, do nothing

	; Erase the cursor

;do this in MSG_UNHIDE_SELECTION to avoid a visual glitch which occurs if the
;cursor is drawn before the file selection inversion - brianc 9/9/94
;	call	FolderLockAndDrawCursor

	;
	; check if anything selected; if not, exit
	;

	; hide selected files
	;
	push	bx				; save instance data addr.
						; show waiting for update
	ornf	ds:[bx].FOI_folderState, mask FOS_UPDATE_PENDING
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_HIDE_SELECTION
	call	ObjMessageForce			; queue up hide method
	pop	bx				; retrieve instance data addr.
						; mark as not target
	andnf	ds:[bx].FOI_folderState, not (mask FOS_TARGET)
	mov	ax, ds:[LMBH_handle]
	cmp	ax, ss:[targetFolder]		; check if we were target
	jne	exit				; if not, don't clear it
	clr	ss:[targetFolder]		; else, make us not the target
exit:

if _GMGR		; no DisplayControl for _NEWDESK
	;
	; check if we just lost global target or if we actually lost target
	; within DisplayControl
	;
	push	ds:[bx].FOI_windowBlock		; save GenDislay block
	mov	bx, handle FileSystemDisplayGroup
	mov	si, offset FileSystemDisplayGroup
	mov	ax, MSG_META_GET_TARGET_EXCL
	call	ObjMessageCallFixup		; cx:dx = target
	pop	ax
	cmp	cx, ax				; could it be us?
	jne	reallyLostTarget		; no
	cmp	dx, FOLDER_WINDOW_OFFSET
	je	stillDCTarget			; yes, it's us
reallyLostTarget:

	mov	ax, MSG_GEN_SET_NOT_ENABLED	; disable
	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	call	FolderTargetCommon
stillDCTarget:
endif			; if _GMGR
	.leave
	ret
FolderLostTarget	endm



if _GMGR

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderTargetCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common procedures for Folder{Gain,List}Target

CALLED BY:	FolderLostTarget(MSG_GEN_SET_NOT_ENABLED)
		FolderGainTarget(MSG_GEN_SET_ENABLED)

PASS:		ax - message to send
		*ds:si - folder object

RETURN:		nothing 

DESTROYED:	

PSEUDO CODE/STRATEGY:	

called from FolderLostTarget(MSG_GEN_SET_NOT_ENABLED)
	will not call UpdateFileMenuCommon
called from FolderGainTarget(MSG_GEN_SET_ENABLED)
	will call UpdateFileMenuCommon with bx = select list


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/17/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderTargetCommon	proc	near

	.enter

	mov	cx, NUM_FOLDER_TARGET_ITEMS
	clr	di
	push	si			; Folder chunk handle

commonLoop:

	push	ax, bx, cx, di
	mov	bx, cs:[di][folderTargetTable].handle
	mov	si, cs:[di][folderTargetTable].chunk
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	pop	ax, bx, cx, di
	add	di, size optr
	loop	commonLoop
	;
	; if gained target, disable tree menu
	;
if (_TREE_MENU and (not (_FCAB or _ZMGR)))
	push	ax		; no Tree menu to update on gained-target
	cmp	ax, MSG_GEN_SET_ENABLED	; gained target?
	jne	noTree
	mov	cx, length treeTargetTable
	clr	di
treeLoop:
	push	bx, cx, di			; disable tree items
	mov	bx, cs:[di][treeTargetTable].handle
	mov	si, cs:[di][treeTargetTable].offset
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	pop	bx, cx, di
	add	di, size optr
	loop	treeLoop
noTree:
	pop	ax
endif		; if (_TREE_MENU and (not (_FCAB or _ZMGR)))

	pop	si			; folder chunk handle
	;
	; update file menu state, if needed
	;	ax = MSG_GEN_SET_{NOT_ENABLED,ENABLED} depending on
	;		gain/lost target
	;
	cmp	ax, MSG_GEN_SET_NOT_ENABLED	; were we disabling?
	je	done				; yes, don't enable
	call	UpdateFileMenuCommon
done:
	.leave
	ret
FolderTargetCommon	endp


;------------------------------------------------------------------------
;		folderTargetTable
; these are enabled/disabled depending on target gain/loss
;------------------------------------------------------------------------
folderTargetTable	label	optr
ifndef ZMGR
	optr	DisplayViewModesSub,
		DisplayViewModes,
		DisplaySortBy,
		DisplaySortByList,
		DisplayOptions,
		DisplayOptionsList,
		FileMenuSelectAll
	optr	FileMenuDeselectAll
else
	optr	DisplayViewModes
endif
;------------------------------------------------------------------------
;		folderTargetFileTable
; these are enabled/disabled depending on target gain/loss
;	these are enabled if file selected on target gain
;------------------------------------------------------------------------
folderTargetFileTable	label	optr
if not _ZMGR
	optr	FileMenuOpen
if _PRINT_CAPABILITY
	optr	FileMenuPrint
endif
if _FAX_CAPABILITY
	optr	FileMenuFax
endif
	optr	FileMenuGetInfo,
		FileMenuMove
	optr	FileMenuCopy
	optr	FileMenuDuplicate,
		FileMenuDelete
	optr	FileMenuChangeAttr
	optr	FileMenuRename,
		FileMenuCreateFolder
ifdef CREATE_LINKS
	optr	FileMenuCreateLink
endif
if not _FORCE_DELETE
	optr	FileMenuThrowAway
endif
if _DOCMGR
	optr	FileMenuRecover
endif

else	; _ZMGR
	optr	FileMenuOpen,
		FileMenuMove,
		FileMenuCopy,
		FileMenuRename,
		FileMenuDelete,
		FileMenuGetInfo,
		FileMenuCreateFolder
endif	; _ZMGR

NUM_FOLDER_TARGET_ITEMS = ($-folderTargetTable)/(size optr)
NUM_FOLDER_TARGET_FILE_ITEMS = ($-folderTargetFileTable)/(size optr)


if not _ZMGR
if not _FCAB
if _TREE_MENU
;------------------------------------------------------------------------
;		treeTargetOffsetTable
; these are disabled on target gain
;------------------------------------------------------------------------
treeTargetTable	optr	\
	TreeMenuExpandAll,
	TreeMenuExpandOneLevel,
	TreeMenuExpandBranch,
	TreeMenuCollapseBranch

endif		; if  _TREE_MENU
endif		; if (not _FCAB)
endif		; if (not _ZMGR)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateFileMenuCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine enables or disables file menu items depending
		on whether or not a file is selected.

CALLED BY:	FolderTargetCommon, PrintFolderInfoString

PASS:		*ds:si - FolderClass object

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/29/92		Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateFileMenuCommon	proc	far
	class FolderClass

	uses	ax, bx, cx, dx, di, si, bp
	.enter

	DerefFolderObject	ds, si, di 
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	ds:[di].FOI_selectList, NIL	; empty select list?
	je	updateIt			; yes, disable
	mov	ax, MSG_GEN_SET_ENABLED	; else, enable

updateIt:
	mov	cx, NUM_FOLDER_TARGET_FILE_ITEMS
	clr	di

commonLoop:
	push	ax, cx, di
	mov	bx, cs:[di][folderTargetFileTable].handle
	mov	si, cs:[di][folderTargetFileTable].chunk

	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	pop	ax, cx, di

	add	di, size optr
	loop	commonLoop

if _ZMGR or _BMGR or _DOCMGR
	;
	; on ZMGR, it doesn't make too much sense to open multiple things,
	; so disable File:Open if multiple things are selected, regardless
	; of what they are
	;
	push	ax				; save enable message
	mov	si, FOLDER_OBJECT_OFFSET
	DerefFolderObject	ds, si, di 
	mov	di, ds:[di].FOI_selectList
	cmp	di, NIL				; empty select list?
	je	afterOpenHack			; yes, handled above
	call	FolderLockBuffer		; es = folder buffer
	jz	afterOpenHack			; no folder buffer
	cmp	es:[di].FR_selectNext, NIL	; only one selection?
	call	FolderUnlockBuffer		; (preserves flags)
	je	afterOpenHack			; yes, leave enabled
	mov	bx, handle FileMenuOpen		; else, disable
	mov	si, offset FileMenuOpen
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
if _DOCMGR
	;
	; disable Rename also
	;
	mov	bx, handle FileMenuRename
	mov	si, offset FileMenuRename
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
endif
afterOpenHack:
	pop	ax				; restore enable message
endif ; _ZMGR or _BMGR or _NIKE

if INSTALLABLE_TOOLS
	;
	; update list of installed tools
	;
		CheckHack <MSG_GEN_SET_ENABLED eq MSG_GEN_SET_NOT_ENABLED-1>
	mov_tr	cx, ax
	sub	cx, MSG_GEN_SET_NOT_ENABLED
	
	mov	bx, handle ToolGroup
	mov	si, offset ToolGroup
	mov	ax, MSG_TM_SET_FILE_SELECTION_STATE
	call	ObjMessageCallFixup
endif

	mov	bx, handle FileMenuCreateFolder ; always enable create dir
	mov	si, offset FileMenuCreateFolder ;	when we are target
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup

if _DOCMGR
	;
	; enable or disable empty wastebasket based
	; on any files display
	;
	mov	si, FOLDER_OBJECT_OFFSET
	DerefFolderObject	ds, si, di
	cmp	ds:[di].FOI_displayList, NIL
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	je	doEmpty
	mov	ax, MSG_GEN_SET_ENABLED
doEmpty:
	mov	bx, handle FileEmptyWastebasket
	mov	si, offset FileEmptyWastebasket
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	;
	; also, disable if executables selected
	;
	mov	si, FOLDER_OBJECT_OFFSET
	call	DMDisableForExec
endif

	.leave
	ret
UpdateFileMenuCommon	endp
endif		; if _GMGR

if _DOCMGR
DMDisableForExec	proc	near
		class	FolderClass
		uses	ax, bx, cx, dx, bp, si, di, es
		.enter
		DerefFolderObject	ds, si, di
	;
	; disable based on executable selection
	;
		mov	di, ds:[di].FOI_selectList
		call	FolderLockBuffer		; es = buffer
execLoop:
		cmp	di, NIL
		je	execDone		; end of list, no execs, C clr
		cmp	es:[di].FR_fileType, GFT_EXECUTABLE
		stc				; assume exec found
		je	execDone
;check fake executables also
		cmp	es:[di].FR_desktopInfo, -1
		stc
		mov	di, es:[di].FR_selectNext
		jne	execLoop		; not exec, check next
execDone:
		call	FolderUnlockBuffer	; preserves flags
		jnc	done			; no execs selected
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		mov	cx, NUM_FOLDER_EXECUTABLE_DISABLE_MENU_ITEMS
		mov	di, offset folderExecutableDisableMenuTable
		call	enumObjList
done:
		.leave
		ret

enumObjList	label	near
		push	si
setLoop:
		push	ax, cx, di
		mov	si, cs:[di]
		mov	bx, handle Interface
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	ObjMessageCallFixup
		pop	ax, cx, di
		add	di, size lptr
		loop	setLoop
		pop	si
		retn
DMDisableForExec	endp

folderExecutableDisableMenuTable	label	lptr
	lptr	offset FileMenuCopy,
		offset FileMenuMove,
		offset FileMenuRename,
		offset FileMenuThrowAway
NUM_FOLDER_EXECUTABLE_DISABLE_MENU_ITEMS = ($-folderExecutableDisableMenuTable)/(size lptr)
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The GenView containing us sends us this to tell us
		what its OD is; we need this for sending generic methods
		to it.

CALLED BY:	MSG_META_CONTENT_SET_VIEW

PASS:		ds:si - folder instance
		cx:dx - OD of GenView

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		If the windowBlock is zero then the folder was created
		from restored state info; in this case, we need to print
		the folder's info string in addition to storing the block;
		if the windowBlock is non-zero, the folder was created by
		CreateNewFolderWindow and the block is already stored and
		we don't need to print the folder info string.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSetView	method	dynamic FolderClass, MSG_META_CONTENT_SET_VIEW

	cmp	ds:[di].FOI_windowBlock, 0
	jne	done
	mov	ds:[di].FOI_windowBlock, cx	; save folder window's block

	;
	; print folder info string
	;
	call	PrintFolderInfoString		; print it

done:
	ret
FolderSetView	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetWindowBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the window block of a FolderClass object.  I can't
		believe this wasn't written before...

CALLED BY:	MSG_FOLDER_GET_WINDOW_BLOCK
PASS:		*ds:si	= FolderClass object
		ds:di	= FolderClass instance data

RETURN:		cx - handle of window block
DESTROYED:	none

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/26/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetWindowBlock	method dynamic FolderClass, 
					MSG_FOLDER_GET_WINDOW_BLOCK
	.enter

	mov	cx, ds:[di].FOI_windowBlock

	.leave
	ret
FolderGetWindowBlock	endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle PTR events

CALLED BY:	MSG_META_PTR

PASS:		*ds:si  FolderObject
		cx - X position of mouse, in doc coords of receiving object
		dx - Y position of mouse, in doc coords of receiving object
		bp low  - ButtonInfo
		bh high - UIFunctionsActive

RETURN:		ax - MRF_PROCESSED and MRF_CLEAR_POINTER_IMAGE returned

DESTROYED:	cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderPtr	method	dynamic FolderClass, MSG_META_PTR
	.enter

	test	ds:[di].FOI_folderState, mask FOS_BOGUS	; will be closed?
	jnz	FP_exit				; yes, do nothing

	test	ss:[fileDragging], mask FDF_REGION	; region active?
	jnz	FP_region			; yes

	test	bp, mask UIFA_MOVE_COPY shl 8	; quick-transfer active?

;allow for our START_SELECT quick-transfer in ZMGR - brianc

if _PEN_BASED
	jnz	qtInProgress
	test	ss:[fileDragging], mask FDF_MOVECOPY
qtInProgress:
endif
	jz	FP_exit				; nope, do nothing

	call	ClipboardGetQuickTransferStatus	; really in progress?
	jz	FP_exit				; nope
						; are we in the view?
	test	ds:[di].FOI_folderState, mask FOS_IN_VIEW
	jz	FP_exit				; no, skip feedback
	;
	; quick-transfer is active, provide feedback
	;
	call	CheckQuickTransferType		; check if CIF_FILES supported
	jnc	supported			; yes, check if move or copy
	mov	ax, CQTF_CLEAR			; ...and reset cursor
	jmp	short haveCursor

supported:
	; it was decided for the initial BA release that to be consistent for
	; any user (who may reside on any volume and therefore isn't guarenteed
	; a consistent move/copy default when dealing with other users, classes
	; or Teacher's library on other arbitrary volumes) we are just to
	; default to copy for ALL quick transfers.  The correct solution will
	; be implemented at some later date.  We accomplish this by just setting
	; the remote flag of the source, so it will still check for illegal
	; destinations, but always be a copy in the event of a valid 
	; destination.  dlitwin 6/4/93
BA<	mov	bx, -1			; set remote flag	>
	call	GetDefaultMoveCopyResponse

haveCursor:
	call	ClipboardSetQuickTransferFeedback	; pass bp
	DerefFolderObject	ds, si, bx
	ornf	ds:[bx].FOI_folderState, mask FOS_FEEDBACK_ON

if TOGGLE_FOLDER_DEST
	;
	; highlight potential destination, if accepted
	;
	cmp	ax, CQTF_CLEAR
	je	notAccepted
	clc					; uninvert last one, invert new
	call	ToggleFolderDragDest
notAccepted:
endif
	jmp	short FP_exit
	;
	; update selection rectangle
	;
FP_region:
						; waiting for target drawing?
	test	ds:[bx].FOI_folderState, mask FOS_UPDATE_PENDING
	jnz	FP_exit				; yes, don't update selection
						;	rectangle yet
	mov	di, ss:[regionSelectGState]
	tst	di
	jz	FP_exit			; gasp!, no gstate for region
	call	FixRegionPosition
	;
	; use exposed info, if needed
	;
	test	ss:[fileDragging], mask FDF_EXPOSED	; did exposed clear
							;	old lasso?
	jz	44$					; nope, clear it
	andnf	ss:[fileDragging], not mask FDF_EXPOSED	; else, no clearing
	jmp	short 45$				;	needed

44$:
	call	ClearLastRegion
45$:
	call	SaveAndDrawNewRegion
FP_exit:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE

	.leave
	ret
FolderPtr	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultMoveCopyResponse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	determine the move/copy default given the source and
		destination data.

CALLED BY:	FolderPtr

PASS:		ax - feedback data (true source diskhandle)
		bx - remote flag (of source)
		cx - X coord in document coords
		dx - Y coord in document coords
		*ds:si - FolderClass object

RETURN:		ax =  CQTF_MOVE, CQTF_COPY or CQTF_CLEAR

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/13/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultMoveCopyResponse	proc	far
	class	FolderClass
	uses	bx, cx, dx, si, bp, di, es
	.enter

	mov	bp, bx				; put remote flag in bp

	DerefFolderObject	ds, si, bx
	call	FolderLockBuffer
	jz	afterUnlock			; no buffer, no files

	push	ax				; save source diskhandle
	mov	ax, TRUE
	call	GetFolderObjectClicked
	pop	ax				; restore source diskhandle

	jnc	overWhiteSpace

	test	es:[di].FR_fileAttrs, mask FA_SUBDIR
	jnz	onAFolder
clearIt::
	mov	ax, CQTF_CLEAR			; can't copy to a non-folder
	jmp	gotFlag

onAFolder:
	tst	bp
	jz	notRemote
	mov	ax, CQTF_COPY
	jmp	gotFlag
notRemote:
	call	GetDefaultMoveCopyResponseESDI

gotFlag:
	call	FolderUnlockBuffer
	jmp	done

overWhiteSpace:
	cmp	ds:[bx].FOI_invalidate, NIL
	je	nothingToInvalidate
	mov	di, ds:[bx].FOI_invalidate
	clr	es:[di].FR_trueDH		; invalidate old diskhandle
	mov	ds:[bx].FOI_invalidate, NIL	; nothing more to invalidate

nothingToInvalidate:
	call	FolderUnlockBuffer

afterUnlock:

	tst	bp
	jnz	itsCopy				; copy if files are remote

	tst	ds:[bx].FOI_remoteFlag
	jnz	itsCopy				; copy if destination is remote

	
	;
	; Compare disk handles.  It's a MOVE if they're the same, and
	; a COPY if different.
	;
	cmp	ax, ds:[bx].FOI_actualDisk
	mov	ax, CQTF_MOVE
	je	done
				
itsCopy:
	mov	ax, CQTF_COPY

done:
	.leave
	ret
GetDefaultMoveCopyResponse	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultMoveCopyResponseESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	determine the move/copy default given the source and
		destination data.

CALLED BY:	FolderPtr

PASS:		es:di - FolderRecord of destination file
		*ds:si - FolderClass object 
		ax - true diskhandle of source

RETURN:		ax -  CQTF_MOVE, CQTF_COPY or CQTF_CLEAR

DESTROYED:	none

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/15/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultMoveCopyResponseESDI	proc	near
	class	FolderClass
tempBuffer	local	PathName

	uses	bx, cx, dx, si

	.enter

	;
	; if we are on any kind of remote destination that *isn't* a 
	; StandardPath make it a copy.  If it is a remote StandardPath,
	; then it will be creating a local version and we should check
	; for the case where this will be on the same drive and therefore
	; a default of move.
	;
	test	es:[di].FR_pathInfo, mask DPI_EXISTS_LOCALLY
	jnz	notRemote

	call	GetRemoteMoveCopyResponseESDI
	jmp	exit

notRemote:
	mov	bx, es:[di].FR_trueDH
	tst	bx				; if not evaluated yet
	jnz	gotTrueDiskHandle

	push	ax				; save source diskhandle
	call	FilePushDir
	call	Folder_GetDiskAndPath
	lea	dx, ds:[bx].GFP_path
	mov	bx, ax				; bx, ds:dx = path
	call	FileSetCurrentPath
	pop	ax				; restore source diskhandle
	jc	error

	;
	; Set up registers for FileConstructActualPath or FileReadLink
	; bx = 0 (use current path if FileConstructActualPaht is used)
	; ds:si - FileName
	;	(ds:dx needed for FileReadLink, but close enough:)
	; es:di - buffer for result to be placed in
	; cx - size of destination buffer
	;

	clr	bx				; use current path (set above)
	push	ds, si, es, di
	segmov	ds, es, si
CheckHack< offset FR_name eq 0>
	mov	si, di			; ds:si is filename (and FolderRecord)
	segmov	es, ss, di
	lea	di, ss:[tempBuffer]		; es:di is the tempBuffer
	mov	cx, size PathName		; cx is size of tempBuffer

ND<	cmp	ds:[si].FR_desktopInfo.DI_objectType, WOT_DRIVE	>
ND<	jne	notDriveLink					>
ND<	call	GetDefaultMoveCopyResponseFromDriveLink		>
ND<	jc	afterConstructActual				>
ND<	tst	bx						>
ND<	jnz	afterConstructActual				>
	; drive was removable and so we determined move/copy status on 
	; the drive number.  This isn't perfect (any B: item will be a move
	; to another B: directory, even if they are different drives), but
	; it is as good as we can do without seeking the disk, which is a 
	; horrible thing to do when just passing the mouse over a drive icon.
ND<	pop	ds, si, es, di					>
ND<	call	FilePopDir					>
ND<	jmp	exit						>
ND<notDriveLink:						>

	clr	dx				; no <drivename> requested
	push	ax
	call	FileConstructActualPath
	pop	ax
ND<afterConstructActual:					>
	pop	ds, si, es, di
	jc	error

	mov	es:[di].FR_trueDH, bx		; cache true diskhandle
	push	ax
	call	DiskGetDrive
	call	DriveGetStatus
	test	ah, mask DS_MEDIA_REMOVABLE
	jz	notRemovable
	
	DerefFolderObject	ds, si, si
	mov	ds:[si].FOI_invalidate, di
notRemovable:
	pop	ax

error:
	call	FilePopDir
	jc	itsClear
						; destination diskhandle in bx
gotTrueDiskHandle:				; source diskhandle is in ax
	cmp	bx, ax
	mov	ax, CQTF_MOVE			; default to move
	je	exit				; move if disks are the same

	mov	ax, CQTF_COPY
	jmp	exit
itsClear:
	mov	ax, CQTF_CLEAR
exit:
	.leave
	ret
GetDefaultMoveCopyResponseESDI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRemoteMoveCopyResponseESDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the appropriate response given the file is remote.
		This means that if it is a standard path it will be
		created locally when something is moved or copied into
		it, so we need to check to see if the source is on the
		same disk as where it will be built out.
		In any other case a remote destination is a copy.

CALLED BY:	GetDefaultMoveCopyResponse

PASS:		es:di - FolderRecord of destination file
		*ds:si - FolderClass object 
		ax - true diskhandle of source

RETURN:		ax -  CQTF_MOVE, CQTF_COPY or CQTF_CLEAR
DESTROYED:	bx, cx, si (because our parent routine preserves them)

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	8/16/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRemoteMoveCopyResponseESDI	proc	near
	uses	di,bp,ds,es
	.enter

	;
	; if our source diskhandle isn't the system diskhandle,
	; then we know that even if it builds out a new standard
	; path it will be a copy, so punt.
	;
	cmp	ax, ss:[geosDiskHandle]
	mov	ax, CQTF_COPY
	jne	exit

	;
	; OK, so we know we are copying from the system disk to a 
	; remote directory, and so if it is a standard path itself
	; we switch to CQTF_MOVE, if it is a non-standard path subdir
	; of a standard path we leave it as CQTF_COPY
	;
	call	Folder_GetDiskAndPath
	lea	si, ds:[bx].GFP_path		; ds:si is our folder's path
	mov	bx, ds:[bx].GFP_disk

	;
	; Since we don't (and won't so far as I can tell) have a standard
	; path under a non-standard path, we know if there is any relative
	; path in our folder that the selected file underneath it can't
	; be a StandardPath.  If there is no relative path, then we can
	; just use the diskhandle and the name of the file as our path to
	; parse it.
	;
	LocalIsNull	ds:[si]
	mov	ax, CQTF_COPY
	jnz	exit

	call	FileParseStandardPath
	LocalIsNull	es:[di]			; get first char of relative 
						;  path.
	mov	ax, CQTF_MOVE			; if it is a StandardPath,
	jz	exit				;   a remote file is a move.

	mov	ax, CQTF_COPY			; otherwise a copy.
exit:
	.leave
	ret
GetRemoteMoveCopyResponseESDI	endp



if _NEWDESK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDefaultMoveCopyResponseFromDriveLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the move copy default from a FolderRecord of a 
		NewDesk Drive object

CALLED BY:	GetDefaultMoveCopyResponseESDI

PASS:		ds:si - FolderRecord (filename of Drive Link)
		es:di - local stack buffer in GetDefaultMoveCopyResponseESDI
		cx - size of local stack buffer
		ax - true diskhandle of source

RETURN:		carry	- clear if no errors have occured
				if drive is removable
					bx - zero
					ax - CQTF_MOVE, CQTF_COPY or CQTF_CLEAR
				else
					bx - diskhandle of drive
					ax - true diskhandle of source

			- set on error
DESTROYED:	none

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	2/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDefaultMoveCopyResponseFromDriveLink	proc	near
	uses	cx, dx, bp, si, es, ds
	.enter

	mov	dx, si				; ds:dx - filename of DriveLink
	mov	bp, ax
	call	FileReadLink
	mov	bx, bp				; true diskhandle of source
	jc	exit

	segmov	ds, es, dx
	mov	dx, di
	call	FSDLockInfoShared
	mov	es, ax
	call	DriveLocateByName
	mov	al, es:[si].DSE_number
	call	FSDUnlockInfoShared

	call	DriveGetStatus
	test	ah, mask DS_MEDIA_REMOVABLE
	jnz	isRemovable

	mov	dx, bx			; save source true diskhandle
	call	DiskRegisterDisk	; disk is fixed, so get the diskhandle
	mov	ax, dx			; true diskhandle of source in ax
	; This won't be saved to state, as it will be stored in the
	; folderbuffer, which isn't saved.
	jnc	exit

	clr	bx			; if DiskRegisterDisk fails, 
	mov	ax, CQTF_CLEAR		; don't allow copy
	clc				; carry cleared by clr macro, but 
	jmp	exit			;  then again, it might change...

isRemovable:
	mov	dx, ax			; dl is dest drive number
	call	DiskGetDrive		; get source drive number to al
	cmp	al, dl
	mov	ax, CQTF_MOVE		; assume move
	je	isMove
	mov	ax, CQTF_COPY		; else copy
isMove:
	clr	bx	
exit:
	.leave
	ret
GetDefaultMoveCopyResponseFromDriveLink	endp
endif		; if _NEWDESK





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixRegionPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap coordinates, if needed.

CALLED BY:	FolderPtr

PASS:		di - gstate
		cx - X coord
		dx - Y coord

RETURN:		cx, dx updated
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/15/93	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixRegionPosition	proc	far

	push	cx, dx
	call	GrGetWinBounds
	mov	ss:[regionWinBounds].R_left, ax	; save 'em
	mov	ss:[regionWinBounds].R_top, bx
	mov	ss:[regionWinBounds].R_right, cx
	mov	ss:[regionWinBounds].R_bottom, dx
	pop	cx, dx

	cmp	cx, ss:[regionWinBounds].R_left
	jge	FRP_10
	mov	cx, ss:[regionWinBounds].R_left
FRP_10:
	cmp	cx, ss:[regionWinBounds].R_right
	jle	FRP_20
	mov	cx, ss:[regionWinBounds].R_right
FRP_20:
	cmp	dx, ss:[regionWinBounds].R_top
	jge	FRP_30
	mov	dx, ss:[regionWinBounds].R_top
FRP_30:
	cmp	dx, ss:[regionWinBounds].R_bottom
	jle	FRP_40
	mov	dx, ss:[regionWinBounds].R_bottom
FRP_40:
	ret
FixRegionPosition	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearLastRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	erase current XOR rectangle

CALLED BY:	FolderPtr

PASS:		di - gstate
		cx - X coord
		dx - Y coord

RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/15/93	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ClearLastRegion	proc	far
	cmp	ss:[regionSelectEnd].P_x, NIL	; any region yet?
	je	CLR_done
	push	cx, dx				; save new point
	mov	ax, ss:[regionSelectStart].P_x
	mov	bx, ss:[regionSelectStart].P_y
	mov	cx, ss:[regionSelectEnd].P_x	; get last region
	mov	dx, ss:[regionSelectEnd].P_y
	call	GrDrawRect			; erase it
	pop	cx, dx				; retrieve new point
CLR_done:
	ret
ClearLastRegion	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveAndDrawNewRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw new XOR rectangle

CALLED BY:	FolderPtr

PASS:		di - gstate
		cx - X coord
		dx - Y coord

RETURN:		none
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	01/15/93	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveAndDrawNewRegion	proc	near
	mov	ax, ss:[regionSelectStart].P_x	; get start position
	mov	bx, ss:[regionSelectStart].P_y
	mov	ss:[regionSelectEnd].P_x, cx	; save new end position
	mov	ss:[regionSelectEnd].P_y, dx
	call	GrDrawRect			; draw frame to (cx, dx)
	ret
SaveAndDrawNewRegion	endp


FolderContentEnter	method	dynamic FolderClass, MSG_META_CONTENT_ENTER
	ornf	ds:[di].FOI_folderState, mask FOS_IN_VIEW
	ret
FolderContentEnter	endm

FolderContentLeave	method	dynamic FolderClass, MSG_META_CONTENT_LEAVE
	andnf	ds:[di].FOI_folderState, not mask FOS_IN_VIEW
	ret
FolderContentLeave	endm


ClearRegionIfNeeded	proc	far
	uses	ax, bx, cx, dx, di
	.enter
	test	ss:[fileDragging], mask FDF_REGION	; selection rect?
	pushf
	andnf	ss:[fileDragging], not (mask FDF_REGION)
	popf
	jz	done
	mov	di, ss:[regionSelectGState]		; else, finish it
	call	FixRegionPosition
	call	ClearLastRegion
	call	GrDestroyState
	mov	ss:[regionSelectGState], 0
done:
	.leave
	ret
ClearRegionIfNeeded	endp

if TOGGLE_FOLDER_DEST

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToggleFolderDragDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		*ds:si = FolderObject
		cx - X position of mouse, in doc coords of receiving object
		dx - Y position of mouse, in doc coords of receiving object
		bp low  - ButtonInfo
		bh high - UIFunctionsActive
		carry clear - deselect last one, select new one
		carry set - deselect last one only

RETURN:

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/12/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToggleFolderDragDest	proc	far
	uses	ax, bx, cx, dx, si, di, bp, es
	.enter
	lahf					; save carry
	call	FolderLockBuffer
	jz	exit

	sahf
;	jc	10$				; deselect last one only
;do by saying new one is NIL
	jc	3$
	mov	ax, TRUE			; force checking icon and name
	call	GetFolderObjectClicked		; di = object mouse is over
	jnc	3$				; over nothing
	cmp	ax, CLICKED_ON_ICON		; over icon?
	je	5$				; yes, use it
3$:
	mov	di, NIL				; over nothing, indicate this
5$:
	cmp	di, ss:[fileDraggingDest]	; same as before?
	je	done				; if so, do nothing
	xchg	di, ss:[fileDraggingDest]	; di = last one, save new one
	cmp	di, NIL				; any last one?
	je	10$				; no
	test	es:[di].FR_state, mask FRSF_SELECTED	; selected?
	jnz	10$				; yes, don't allow
	call	ForceExposeFolderObjectIcon	; un-invert last one
10$:
	mov	di, ss:[fileDraggingDest]	; get new one
	cmp	di, NIL				; anything? (FolderEndSelect)
	je	done				; no
	test	es:[di].FR_state, mask FRSF_SELECTED	; selected?
	jnz	done				; yes, don't allow
	;
	; fake selection so DFI_INVERT will really invert - 12/18/98
	;
		mov	ax, es:[di].FR_state
		push	ax
		ornf	es:[di].FR_state, mask FRSF_SELECTED
	call	ForceExposeFolderObjectIcon	; invert new one
		pop	ax
		mov	es:[di].FR_state, ax
done:
	call	FolderUnlockBuffer


exit:
	.leave
	ret
ToggleFolderDragDest	endp

ForceExposeFolderObjectIcon	proc	near
		class	FolderClass
		uses	ax,bx
		.enter			
		DerefFolderObject	ds, si, bx
		mov	ax, ds:[bx].FOI_folderState	; save TARGET state
		push	ax
		ornf	ds:[bx].FOI_folderState, mask FOS_TARGET
		mov	ax, mask DFI_INVERT
		call	ExposeFolderObjectIcon
		pop	ax
		mov	ds:[bx].FOI_folderState, ax	; restore TARGET state
		.leave
		ret
ForceExposeFolderObjectIcon	endp
endif		; if TOGGLE_FOLDER_DEST


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFolderObjectClicked
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	returns pointer to object clicked on

CALLED BY:	INTERNAL -
			FolderButton, FolderEndMoveCopy
			FolderRepositionIcons

		EXTERNAL -
			FolderRecordFindEmptySlot

PASS:		cx, dx - position clicked
		es - segment of locked folder buffer
		*ds:si - FolderClass object
		ax = TRUE to check icon and name seperately
		ax = FALSE to check bounding box

RETURN:		CARRY SET if object was clicked on
			es:di - pointer to entry in folder
				buffer of object clicked

			if AX was passed TRUE:
				ax =	CLICKED_ON_ICON
					CLICKED_ON_NAME

		CARRY CLEAR if no object clicked on

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Loop through ENTIRE display list, and return the offset 
	to the folder record closest to the end of the list. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	O(n) in all cases.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version
	martin	7/31/92		Added ability to deal with overlapping icons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFolderObjectClicked	proc	far
	class	FolderClass

	uses	bx, bp, si

	.enter

	mov	bx, ax				; bx = flag
EC <	cmp	bx, TRUE						>
EC <	je	10$							>
EC <	cmp	bx, FALSE						>
EC <	ERROR_NZ	DESK_BAD_PARAMS					>
EC <10$:								>

	DerefFolderObject	ds, si, si

	mov	bp, NIL
	mov	di, ds:[si].FOI_displayList	; get first file in
						; display list
startLoop:
	cmp	di, NIL				; check if end-of-list marker
	je	done				; if so, exit

	;
	; If this icon is unpositioned, then its current bounds are
	; invalid, so skip it.
	;
		
	test	es:[di].FR_state, mask FRSF_UNPOSITIONED
	jnz	checkNext
		
EC <	call	ECCheckFolderRecordESDI		>
		
	cmp	bx, TRUE			; force icon and name checking?
	je	iconMode			; yes

	;
	; Check entire bounding box
	;

	cmp	cx, es:[di].FR_boundBox.R_left	; check if left of item left
	jl	checkNext			; if so, check next object
	cmp	dx, es:[di].FR_boundBox.R_top	; check if above item top
	jl	checkNext			; if so, check next object
	cmp	cx, es:[di].FR_boundBox.R_right ; check if right of item right
	jg	checkNext			; if so, check next object
	cmp	dx, es:[di].FR_boundBox.R_bottom ; check if below item bottom
	jg	checkNext
	jmp	gotObject	

iconMode:
	;
	; icon mode, check name and icon regions seperately
	;
		
	cmp	cx, es:[di].FR_iconBounds.R_left ; check if left of icon left
	jl	checkName			; if so, check name
	cmp	dx, es:[di].FR_iconBounds.R_top	; check if above icon top
	jl	checkName			; if so, check name
	cmp	cx, es:[di].FR_iconBounds.R_right ; check if right of icon
	jg	checkName			; if so, check name
	cmp	dx, es:[di].FR_iconBounds.R_bottom ; check if below icon bottom
	jg	checkName			; if so, check name
	mov	ax, CLICKED_ON_ICON
	jmp	gotObject			; if not, object clicked on

checkName:
	cmp	cx, es:[di].FR_nameBounds.R_left ; check if left of name left
	jl	checkNext			; if so, check next object
	cmp	dx, es:[di].FR_nameBounds.R_top	; check if above name top
	jl	checkNext			; if so, check next object
	cmp	cx, es:[di].FR_nameBounds.R_right ; check if right of
						  ; name right
	jg	checkNext			; if so, check next object
	cmp	dx, es:[di].FR_nameBounds.R_bottom ; check if below name bottom
	jg	checkNext			; if so, check next object
	mov	ax, CLICKED_ON_NAME		;  else they clicked on name

gotObject:
	mov	bp, di

checkNext:
	mov	di, es:[di].FR_displayNext	; move to next file in list
	jmp	startLoop


done:
	mov	di, bp
	cmp	bp, NIL				; set carry if bp is
						; less than NIL
	.leave
	ret

GetFolderObjectClicked	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize new folder window

CALLED BY:	MSG_INIT

PASS:		*ds:si - folder object
		ds:di - FolderClass instance data

		cx - window block
		bp - disk handle for folder window

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/18/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderInit	method	dynamic FolderClass, MSG_INIT
	.enter

	call	ObjMarkDirty		; opened new window -> dirty

	mov	ds:[di].FOI_windowBlock, cx	; store window block

	clr	ax
	mov	ds:[di].FOI_buffer, ax		; clear buffer
	mov	ds:[di].FOI_fileCount, ax	; no files yet
	mov	ds:[di].FOI_folderState, ax	; no state info
	movP	ds:[di].FOI_winBounds, axax  	; force
							; building display list
	mov	ds:[di].FOI_anchor.P_x, -1	; no anchor point

	mov	ax, NIL
	mov	ds:[di].FOI_displayList, ax 
	mov	ds:[di].FOI_selectList, ax 
	mov	ds:[di].FOI_cursor, ax		; no cursor
	mov	ds:[di].FOI_anchorIcon, ax	; no last toggled icon

	;
	; Fetch the display options from the UI.  Most of this UI doesn't 
	; exist for NewDesk and Zoomer, so we have to load from defaults
	; for those cases.
	;

	;
	; get display Attrs into cl
	; get display Types into ch
	; get display Sort  into dl
	;
if _NEWDESK or _ZMGR
	mov	cl, ss:[defDisplayAttrs]
	mov	ch, ss:[defDisplayTypes]
	mov	dl, ss:[defDisplaySort]
else
	push	si
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	LoadBXSI	DisplayOptionsList
	call	ObjMessageCallFixup
	push	ax
	
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	LoadBXSI	DisplaySortByList
	call	ObjMessageCallFixup
	mov	dx, ax
	pop	cx
	mov	ch, mask FIDT_ALL
	pop	si
endif
	;
	; get display modes into dh
	;
if _NEWDESK
	mov	dh, ss:[defDisplayMode]
else
	push	si, cx, dx
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	LoadBXSI	DisplayViewModes
	call	ObjMessageCallFixup
	pop	si, cx, dx
	mov	dh, al
	DerefFolderObject	ds, si, di
endif

	ECCheckFlags	cl, FI_DisplayAttrs
	ECCheckFlags	ch, FI_DisplayTypes
	ECCheckFlags	dl, FI_DisplaySort
	ECCheckFlags	dh, FI_DisplayMode
	ECMakeSureNonZero	cl		
	ECMakeSureNonZero	ch
	ECMakeSureNonZero	dl		
	ECMakeSureNonZero	dh

	mov	ds:[di].FOI_displayAttrs, cl
	mov	ds:[di].FOI_displayTypes, ch
	mov	ds:[di].FOI_displaySort, dl
	mov	ds:[di].FOI_displayMode, dh
	mov	ah, dh			; expected by SetFolderOpenSize

if GPC_NAMES_AND_DETAILS_TITLES
	;
	; set size of titles objects (since GPC only supports one names
	; and details mode, we can do it once here instead of again on
	; mode changes)
	;
	call	EnableNamesAndDetails	; preserves ah = FI_displayMode
endif
		
	;
	; set open size for window depending on display mode
	;
	call	SetFolderOpenSize

	.leave
	ret
FolderInit	endm

if GPC_NAMES_AND_DETAILS_TITLES
EnableNamesAndDetails	proc	far
		class	FolderClass
		
		call	SetFileBoxWidthHeight
		DerefFolderObject	ds, si, di
if not _DOCMGR
.assert (offset NDFolderTitleName) eq (offset NDDriveTitleName)
.assert (offset NDFolderTitleName) eq (offset NDWastebasketTitleName)
.assert (offset NDFolderTitleSize) eq (offset NDDriveTitleSize)
.assert (offset NDFolderTitleSize) eq (offset NDWastebasketTitleSize)
.assert (offset NDFolderTitleDate) eq (offset NDDriveTitleDate)
.assert (offset NDFolderTitleDate) eq (offset NDWastebasketTitleDate)
		.warn -private
		cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP
		.warn @private
		je	notFull
endif
		push	si
		mov	ax, MSG_GEN_SET_NOT_USABLE
		mov	dl, VUM_NOW
		mov	bx, ds:[di].FOI_windowBlock
		mov	si, offset NDFolderTitles
		push	di
		call	ObjMessageCallFixup
		pop	di
		mov	bx, ds:[di].FOI_windowBlock
		mov	si, offset NDFolderTitleName
		mov	cx, ss:[longTextNameWidth]
		call	setTitleWidth
		mov	si, offset NDFolderTitleSize
		mov	cx, ss:[fullFileDatePos]
		sub	cx, ss:[longTextNameWidth]
		call	setTitleWidth
		mov	si, offset NDFolderTitleDate
if GPC_NO_NAMES_AND_DETAILS_ATTRS
		mov	cx, ss:[fullFileWidth]
		add	cx, 20	; hack for vertical scrollbar
else
		mov	cx, ss:[fullFileAttrPos]
endif
		sub	cx, ss:[fullFileDatePos]
		call	setTitleWidth
if GPC_NO_NAMES_AND_DETAILS_ATTRS ne TRUE
.assert (offset NDFolderTitleAttr) eq (offset NDDriveTitleAttr)
.assert (offset NDFolderTitleAttr) eq (offset NDWastebasketTitleAttr)
		mov	si, offset NDFolderTitleAttr
		mov	cx, ss:[fullFileWidth]
		sub	cx, ss:[fullFileAttrPos]
		call	setTitleWidth
endif
		pop	si
	;
	; set usability of titles for names and details mode
	;
.assert (offset NDFolderTitles) eq (offset NDDriveTitles)
.assert (offset NDFolderTitles) eq (offset NDWastebasketTitles)
		DerefFolderObject	ds, si, di
		mov	ah, ds:[di].FOI_displayMode
		test	ah, mask FIDM_FULL
		jz	notFull
		push	ax, si
		mov	ax, MSG_GEN_SET_USABLE
		mov	dl, VUM_NOW
		mov	bx, ds:[di].FOI_windowBlock
		mov	si, offset NDFolderTitles
		call	ObjMessageCallFixup
		pop	ax, si
notFull:
		ret

	;
	; set folder window title width for names and details mode
	; ^lbx:si = title object
	; cx = width
	;
setTitleWidth	label	near
		sub	cx, 4  ;leave out button borders
		sub	sp, size AddVarDataParams + size GadgetSizeHintArgs
		mov	bp, sp
		segmov	ss:[bp].AVDP_data.segment, ss
		lea	ax, ss:[bp][(size AddVarDataParams)]
		mov	ss:[bp].AVDP_data.offset, ax
		mov	ss:[bp].AVDP_dataSize, size GadgetSizeHintArgs
		mov	ss:[bp].AVDP_dataType, HINT_FIXED_SIZE or mask VDF_SAVE_TO_STATE
		mov	ss:[bp][(size AddVarDataParams)].GSHA_width, cx
		mov	ss:[bp][(size AddVarDataParams)].GSHA_height, 0
		mov	dx, size AddVarDataParams
		mov	ax, MSG_META_ADD_VAR_DATA
		mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		add	sp, size AddVarDataParams + size GadgetSizeHintArgs
		retn
EnableNamesAndDetails	endp

FolderResetNamesAndDetails	method	dynamic	FolderClass, MSG_FOLDER_RESET_NAMES_AND_DETAILS
		call	EnableNamesAndDetails
		ret
FolderResetNamesAndDetails	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFolderOpenSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the view size

CALLED BY:	FolderInit

PASS:		*ds:si 	- FolderClass instance data
		ah 	- FI_DisplayMode

RETURN:		nothing  

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFolderOpenSize	proc	near
	.enter

		call	SetFileBoxWidthHeight

		DerefFolderObject	ds, si, di

		mov	cx, ss:[shortTextBoxWidth]
		add	cx, TEXT_INDENT + 1
		mov	dx, ss:[shortTextBoxHeight]
		shl	dx, 1
		shl	dx, 1
		shl	dx, 1				; *8
		add	dx, TEXT_DOWNDENT
		test	ah, mask FIDM_SHORT
		jnz	sendSize

		mov	cx, ss:[uncompressedFullFileWidth]
		add	cx, TEXT_INDENT + 1
		mov	dx, ss:[longTextBoxHeight]
		shl	dx, 1
		shl	dx, 1
		shl	dx, 1				; *8
		add	dx, TEXT_DOWNDENT
		test	ah, mask FIDM_FULL
		jnz	sendSize

		mov	cx, ss:[smallIconBoxWidth]
		shl	cx, 1				; *2
		add	cx, SMALL_ICON_INDENT + 1
ND <		add	cx, 20				; for scrollbar	>
		mov	dx, ss:[smallIconBoxHeight]
		shl	dx, 1				; *2
		add	dx, SMALL_ICON_DOWNDENT
		test	ah, mask FIDM_SICON
		jnz	sendSize

		mov	cx, ss:[largeIconBoxWidth]
		shl	cx
		mov	dx, ss:[largeIconBoxHeight]
		shl	dx
		call	FolderCheckIfCGA
		jc	cga

	;	
	; Make the large icon size 4 x 3
	;
		shl	cx
		add	dx, ss:[largeIconBoxHeight]
		jmp	notCGA
cga:
		sub	dx, CGA_ICON_HEIGHT_DIFFERENCE * 2
notCGA:
ND <		add	cx, 20				; for scrollbar	>
EC <		test	ah, mask FIDM_LICON				>
EC <		ERROR_Z	BAD_FOLDER_DISPLAY_MODE				>

sendSize:
		sub	sp, size SetSizeArgs
		mov	bp, sp
		mov	ss:[bp].SSA_updateMode, VUM_DELAYED_VIA_UI_QUEUE
	;
	; Make sure the size values don't extend past the low ten bits
	;
		andnf	cx, mask SW_DATA
		andnf	dx, mask SH_DATA
		CheckHack <SST_PIXELS eq 0>

		mov	ss:[bp].SSA_width, cx
		mov	ss:[bp].SSA_height, dx
		mov	ss:[bp].SSA_count, 0
		mov	dx, size SetSizeArgs
		mov	ax, MSG_GEN_SET_INITIAL_SIZE
		mov	di, mask MF_CALL or mask MF_STACK
		call	FolderCallView
		add	sp, size SetSizeArgs

	.leave
	ret
SetFolderOpenSize	endp

FolderCheckIfCGA	proc	near
	cmp	ss:[desktopDisplayType], CGA_DISPLAY_TYPE
	stc					; assume CGA
	je	short done			; yes, CGA
	clc					; else, not CGA
done:
	ret
FolderCheckIfCGA	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetPrimaryMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the primary's moniker.

CALLED BY:	CreateFolderWindowCommon, FolderRemovedFloppy,
		FolderInsertedFloppy

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	added header
	dlitwin 12/31/92	Renamed and made into a FolderClass message

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetPrimaryMonikerVars	struct
	SPMV_moniker	VisMoniker
	SPMV_mnemonic	byte
	SPMV_folderName	PathName
	SPMV_rvmf	ReplaceVisMonikerFrame
GM<	SPMV_diskHandle	word		>
if _NEWDESK and _NDO2000
	SPMV_diskHandle	word
endif
SetPrimaryMonikerVars	ends

FolderSetPrimaryMoniker	method dynamic FolderClass,
					MSG_FOLDER_SET_PRIMARY_MONIKER
	uses	ax,cx,dx

locals		local	SetPrimaryMonikerVars

ForceRef	locals

	.enter

	call	Folder_GetDiskAndPath

GMONLY<	mov	ss:[locals].SPMV_diskHandle, ax		>
if _NEWDESK and _NDO2000
	mov	ss:[locals].SPMV_diskHandle, ax
endif

	push	{word} ds:[bx].GFP_path		; save first two bytes of path
DBCS <	push	{word} ds:[bx].GFP_path[2]				>
	;
	; update Folder Window header
	;
	call	BuildFolderWindowHeader

	DerefFolderObject	ds, si, bx
if GPC_FILE_OP_DIALOG_PATHNAME and not _DOCMGR
	.warn -private
	cmp	ds:[bx].NDFOI_ndObjType, WOT_FOLDER
	je	monikerCheck
	cmp	ds:[bx].NDFOI_ndObjType, WOT_WASTEBASKET
	.warn @private
monikerCheck:
endif
	mov	bx, ds:[bx].FOI_windowBlock	; bx:si = folder window
if GPC_FILE_OP_DIALOG_PATHNAME and not _DOCMGR
	je	skipMonikerForNow
endif
	call	CopyInAndSetNewMoniker		; do it
skipMonikerForNow::
	call	PrintFolderInfoString		; updates it all

if (_ZMGR and not _PMGR)
	;
	; For ZMGR, set path in FolderInfoPath
	;	bx = FOI_windowBlock
	;
	push	bp
	mov	si, offset FolderInfoPath	; ^lbx:si = FolderInfoPath
	mov	dx, ss				; dx:bp = name
	lea	bp, ss:[locals].SPMV_folderName
	clr	cx				; null-terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessageCallFixup
	pop	bp
endif
if GPC_FOLDER_DIR_TOOLS
	;
	; For GPC_FOLDER_DIR_TOOLS, set path in FolderInfoPath, relative
	; to SP_DOCUMENTS or SP_APPLICATION (handled by PathnameStorageClass)
	;	bx = FOI_windowBlock
	;
	mov	si, FOLDER_OBJECT_OFFSET
	DerefFolderObject	ds, si, di
	mov	si, offset NDFolderDirPath	; ^lbx:si = FolderInfoPath
	.warn -private
	cmp	ds:[di].NDFOI_ndObjType, WOT_FOLDER
	.warn @private
	je	usePathInfo
	mov	si, offset NDWasteFolderPath
	.warn -private
	cmp	ds:[di].NDFOI_ndObjType, WOT_WASTEBASKET
	.warn @private
	jne	noPathInfo
usePathInfo:
	push	bp
	push	bx
	call	Folder_GetDiskAndPath		; ds:bx = GenFilePath
	mov	cx, ds
	lea	dx, ds:[bx].GFP_path
	mov	bp, ds:[bx].GFP_disk
	pop	bx
	mov	ax, MSG_GEN_PATH_SET
	call	ObjMessageCallFixup
	pop	bp
if GPC_FILE_OP_DIALOG_PATHNAME and not _DOCMGR
	;
	; set moniker again, using nice normalized name from path object
	;
	push	bp
	mov	dx, ss
	lea	bp, ss:[locals].SPMV_folderName
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjMessageCallFixup
	pop	bp
	call	CopyInAndSetNewMoniker		; do it
endif
noPathInfo:
endif

	;
	; turn off up-arrow if this is root
	;
DBCS <	pop	si				; second two bytes of path>
	pop	ax				; first two bytes of path
if _GMGRONLY		; no Up-Dir button for FileCabinet; NewDesk below
if DBCS_PCGEOS
	cmp	ax, '\\'			; root?
	mov	ax, MSG_GEN_SET_ENABLED		; assume not
	jne	notRoot				; nope
	tst	si
	jnz	notRoot				; nope
else
	cmp	ax, '\\' or (0 shl 8)		; root?
	mov	ax, MSG_GEN_SET_ENABLED		; assume not
	jne	notRoot				; no
endif
	;
	; Might be root.
	; 
	test	ss:[locals].SPMV_diskHandle, DISK_IS_STD_PATH_MASK	; standard path?
	jz	disableUpDir				; no => really is root

	cmp	ss:[locals].SPMV_diskHandle, SP_TOP	; SP_TOP?
	jne	notRoot					; no => can't be root
	
	tst	ss:[topLevelIsRoot]
	jz	notRoot
	
disableUpDir:
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; yes, root!
notRoot:
	mov	si, offset FolderUpButton
	mov	dl, VUM_NOW
	call	ObjMessageFixup			; no MF_CALL (don't
						; trash BP)
	;
	; store current disk handle in up-dir button for quick-transfer
	; feedback
	;	bx:si = up-dir button
	;

	push	bp
	mov	bp, ss:[locals].SPMV_diskHandle
	mov	ax, MSG_DIR_TOOL_SET_DISK_HANDLE
	call	ObjMessageCallFixup
	pop	bp
endif			; if _GMGRONLY
if GPC_FOLDER_DIR_TOOLS
if not _NDO2000
	;
	; disable up dir if at SP_DOCUMENT or SP_APPLICATION, unless
	; in debug mode; always disable if root
	;
	mov	si, FOLDER_OBJECT_OFFSET
	DerefFolderObject	ds, si, di
	.warn -private
	cmp	ds:[di].NDFOI_ndObjType, WOT_FOLDER
	.warn @private
	LONG jne	notFolder
	clr	ax				; null-path on stack
	push	ax
	segmov	es, ss, di
	mov	di, sp
	mov	dx, SP_DOCUMENT
	call	Folder_GetDiskAndPath		; ds:[bx] = GenFilePath
	mov	cx, ds:[bx].GFP_disk
	lea	si, ds:[bx].GFP_path
	push	cx				; undocumented trashing
	call	revFileComparePathsEvalLinks	; C set on error
	pop	cx
	jc	checkRoot
	cmp	al, PCT_EQUAL			; path is DOC?
	je	disableUpIfNotDebug		; yes, disable unless debug
	cmp	al, PCT_SUBDIR			; path is subdir of DOC?
	je	enableUp			; yes, enable
	mov	dx, SP_APPLICATION
	call	revFileComparePathsEvalLinks
	jc	checkRoot
	cmp	al, PCT_EQUAL			; path is APP?
	je	disableUpIfNotDebug		; yes, disable unless debug
	cmp	al, PCT_SUBDIR			; path is subdir of APP?
	je	enableUp			; yes, enable
checkRoot:
	call	Folder_GetActualDiskAndPath
	test	ds:[bx].GFP_disk, DISK_IS_STD_PATH_MASK
	jnz	checkDesktopSub			; not root
if DBCS_PCGEOS
	cmp	{TCHAR}ds:[bx].GFP_path, '\\'	; root?
	jne	checkDesktopSub			; not root
	cmp	{TCHAR}ds:[bx].GFP_path+(size TCHAR), 0
	je	disableUp			; root, disable
else
	cmp	{word}ds:[bx].GFP_path, '\\' or (0 shl 8)	; root?
	je	disableUp			; root, disable
endif
checkDesktopSub:
	;1) enable if below desktop subdir
	;2) if desktop subdir, disable even if debug since it'll show
	;   already-opened desktop
	;3) else, disable if not debug
	;XXX
	push	ds
	sub	sp, PATH_BUFFER_SIZE
	mov	si, FOLDER_OBJECT_OFFSET	; *ds:si = Folder
	call	GetFolderParentPath
	segmov	es, ss				; es:di = parent path
	mov	di, sp
	jc	desktopSubRoot			; at root, disable
	mov	dx, cx				; dx = parent disk handle
	segmov	ds, cs, si			; ds:si = desktop path
	mov	si, offset fspmDesktopPath
	mov	cx, STANDARD_PATH_OF_DESKTOP_VOLUME	; cx = desktop disk
	call	FileComparePathsEvalLinks
desktopSubRoot:
	lea	sp, es:[di][PATH_BUFFER_SIZE]
	pop	ds
	jc	disableUp			; error, disable
	cmp	al, PCT_EQUAL
	je	disableUp			; desktop subdir, disable
	cmp	al, PCT_SUBDIR
	jne	disableUpIfNotDebug		; not below desktop
				; else, below desktop subdir, enable
enableUp:
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	short upCommon

disableUpIfNotDebug:
if GPC_DEBUG_MODE
	cmp	ss:[debugMode], TRUE
	je	enableUp
endif
disableUp:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
upCommon:
	mov	si, FOLDER_OBJECT_OFFSET	; *ds:si = Folder
	DerefFolderObject	ds, si, di
	mov	bx, ds:[di].FOI_windowBlock
	mov	si, offset NDFolderDirUpButton
	mov	dl, VUM_NOW
	push	bp
	call	ObjMessageCallFixup
	pop	bp
	pop	ax
notFolder:
else   ; if _not NDO2000
	mov	si, FOLDER_OBJECT_OFFSET
	DerefFolderObject	ds, si, di
	.warn -private
	cmp	ds:[di].NDFOI_ndObjType, WOT_FOLDER
	.warn @private
	LONG jne	notFolder
	call	Folder_GetActualDiskAndPath
	test	ds:[bx].GFP_disk, DISK_IS_STD_PATH_MASK
	jnz	checkDesktopSub			; not root
if DBCS_PCGEOS
	cmp	{TCHAR}ds:[bx].GFP_path, '\\'	; root?
	jne	checkDesktopSub			; not root
	cmp	{TCHAR}ds:[bx].GFP_path+(size TCHAR), 0
	je	disableUp			; root, disable
else
	cmp	{word}ds:[bx].GFP_path, '\\' or (0 shl 8)	; root?
	je	disableUp			; root, disable
endif
checkDesktopSub:
	;2) if desktop subdir, disable since it'll show
	;   already-opened desktop, else enable
	;XXX
	push	ds
	sub	sp, PATH_BUFFER_SIZE
	mov	si, FOLDER_OBJECT_OFFSET	; *ds:si = Folder
	call	GetFolderParentPath
	segmov	es, ss, di			; es:di = parent path
	mov	di, sp
	jc	desktopSubRoot			; at root, disable
	mov	dx, cx				; dx = parent disk handle
	segmov	ds, cs, si			; ds:si = desktop path
	mov	si, offset fspmDesktopPath
	mov	cx, STANDARD_PATH_OF_DESKTOP_VOLUME	; cx = desktop disk
	call	FileComparePathsEvalLinks
desktopSubRoot:
	lea	sp, es:[di][PATH_BUFFER_SIZE]
	pop	ds
	jc	disableUp			; error, disable
	cmp	al, PCT_EQUAL
	je	disableUp			; desktop subdir, disable
	mov	ax, MSG_GEN_SET_ENABLED
	jmp	short upCommon

disableUp:
	mov	ax, MSG_GEN_SET_NOT_ENABLED
upCommon:
	mov	si, FOLDER_OBJECT_OFFSET	; *ds:si = Folder
	DerefFolderObject	ds, si, di
	mov	bx, ds:[di].FOI_windowBlock
	mov	si, offset NDFolderDirUpButton
	mov	dl, VUM_NOW
	push	bp
	call	ObjMessageCallFixup

	;
	; store current disk handle in up-dir button for quick-transfer
	; feedback
	;	bx:si = up-dir button
	;

	mov	bp, ss:[locals].SPMV_diskHandle
	mov	ax, MSG_DIR_TOOL_SET_DISK_HANDLE
	call	ObjMessageCallFixup
	pop	bp
notFolder:
endif  ; not _NDO2000
endif  ; GPC_FOLDER_DIR_TOOLS
	.leave
	ret

if GPC_FOLDER_DIR_TOOLS
revFileComparePathsEvalLinks	label	near
	segxchg	ds, es
	xchg	si, di
	xchg	cx, dx
	call	FileComparePathsEvalLinks
	segxchg	ds, es
	xchg	si, di
	xchg	cx, dx
	retn

fspmDesktopPath	char	ND_DESKTOP_RELATIVE_PATH, 0
endif
FolderSetPrimaryMoniker	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyInAndSetNewMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces the old moniker with the path.

CALLED BY:	FolderSetPrimaryMoniker

PASS:		bx = Folder Window's block
		scanFolderNameBuffer = moniker string
		di = past last byte in scanFolderNameBuffer

RETURN:		

DESTROYED:	ax,cx,dx, etc.

PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	12/30/92   	Added this header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyInAndSetNewMoniker	proc	near

	uses	si

	.enter	inherit	FolderSetPrimaryMoniker

if _NEWDESK
	call	TruncateMonikerToLastElement
elif _DOCMGR
	call	MakeContentsString
endif
	;
	; set up new visual moniker and copy it into folder window chunk
	;
	mov	ss:[locals].SPMV_moniker.VM_type, 
		VisMonikerType <
			0,		; VMT_MONIKER_LIST (false)
			0,		; VMT_GSTRING (false)
			DAR_NORMAL,	; VMTB_GS_ASPECT_RATIO
			DC_TEXT		; VMT_GS_COLOR
		>				;is ascii text

	mov	ss:[locals].SPMV_moniker.VM_width, 0
	mov	ss:[locals].SPMV_mnemonic, -1	; no mnemonic
						; compute #bytes in search buf
	lea	ax, ss:[locals].SPMV_folderName
	mov	di, ax
	push	es, ax
	segmov	es, ss
	LocalStrSize	includeNull		; cx = number of bytes to copy
	pop	es, ax
	
	add	cx, size VisMoniker + size VMT_mnemonicOffset
						; bx:si = Folder Window
	mov	si, FOLDER_WINDOW_OFFSET	; common offset
						; add in flags to size
	mov	ss:[locals].SPMV_rvmf.RVMF_source.segment, ss
	lea	ax, ss:[locals].SPMV_moniker
	mov	ss:[locals].SPMV_rvmf.RVMF_source.offset, ax
	mov	ss:[locals].SPMV_rvmf.RVMF_sourceType, VMST_FPTR
	mov	ss:[locals].SPMV_rvmf.RVMF_dataType, VMDT_VIS_MONIKER
	mov	ss:[locals].SPMV_rvmf.RVMF_length, cx
	mov	ss:[locals].SPMV_rvmf.RVMF_updateMode, VUM_NOW
	push	bp
	lea	bp, ss:[locals].SPMV_rvmf
	mov	dx, size SPMV_rvmf
if _DOCMGR
	; use primary for DocMgr
	mov	bx, handle FileSystemDisplay
	mov	si, offset FileSystemDisplay
endif
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bp

	.leave
	ret
CopyInAndSetNewMoniker	endp


if _NEWDESK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TruncateMonikerToLastElement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take the full path of the moniker
		and truncate it to just the last elemtent in the path.

CALLED BY:	CopyInAndSetNewMoniker

PASS:		ss:bp - inherited local vars

RETURN:		folderName truncated

DESTROYED:	none

PSEUDO CODE/STRATEGY:	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/2/92   	Initial Version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TruncateMonikerToLastElement	proc	near
	uses	ax, cx, si, di, ds, es

	.enter	inherit	FolderSetPrimaryMoniker

	segmov	ds, ss
	segmov	es, ss
	lea	di, ss:[locals].SPMV_folderName
if GPC_CUSTOM_FLOPPY_NAME
if DBCS_PCGEOS
	cmp	{wchar}es:[di+4], '\\'
	jne	notRoot
	cmp	{wchar}es:[di+2], ':'
	jne	notRoot
	cmp	{wchar}es:[di], 'A'
	je	floppyDir
	cmp	{wchar}es:[di+6], C_NULL
else
	cmp	{word}es:[di+1], ':' or ('\\' shl 8)
	jne	notRoot
	cmp	{char}es:[di], 'A'
	je	floppyDir			; any floppy path
	cmp	{char}es:[di+3], C_NULL
endif
	jne	notRoot				; not root
	jmp	done				; leave root path
floppyDir:
	push	bx
	mov	bx, handle GPCFloppyDiskName
	call	MemLock
	mov	ds, ax
	mov	si, offset GPCFloppyDiskName
	mov	si, ds:[si]
	LocalCopyString				; use floppy name
	call	MemUnlock
	pop	bx
	jmp	done
notRoot:
endif
	mov	si, di
	clr	ax				; look for null term.
SBCS <	mov	cx, size PathName				>
DBCS <	mov	cx, (size PathName)/2				>
	LocalFindChar

	LocalPrevChar	esdi			; back up to null
	std					; reverse direction flag
	LocalLoadChar	ax, '\\'
SBCS <	sub	cx, size PathName				>
DBCS <	sub	cx, size PathName/2				>
	not	cx				; cx is length traversed
	LocalFindChar				; go to last slash
	cld					; reset direction flag
	lea	cx, ss:[locals].SPMV_folderName
	cmp	di, cx				; any slashes?
	je	done				; nope, done
SBCS <	cmp	{byte} es:[di+2], 0		; if null after slash>
DBCS <	cmp	{wchar} es:[di+4], 0		; if null after slash>
	jne	notADrive

SBCS <	mov	{byte} es:[di], 0		; remove space and slash>
DBCS <	mov	{wchar} es:[di], 0		; remove space and slash>
	jmp	done

notADrive:
	LocalNextChar	esdi			; point to slash
	LocalNextChar	esdi			; point past '\\'
	mov	si, di
	lea	di, ss:[locals].SPMV_folderName
	mov	cx, size FileLongName/2
	rep	movsw				; truncate to only
done:						;   the last name
	.leave
	ret
TruncateMonikerToLastElement	endp
endif		; if _NEWDESK

if _DOCMGR
MakeContentsString	proc	near
	uses	ax, bx, cx, dx, si, di, ds, es

	.enter	inherit	FolderSetPrimaryMoniker

	segmov	es, ss
	lea	di, ss:[locals].SPMV_folderName
	clr	bx
	call	FileParseStandardPath
	mov	dx, offset DeskStringsCommon:ContentsWaste
	cmp	ax, SP_WASTE_BASKET
	je	gotContents
	cmp	ax, SP_DOCUMENT
	mov	dx, offset DeskStringsCommon:ContentsDocument
	jne	notDoc
	segmov	ds, cs
	mov	si, offset contentArchivePath
	mov	cx, CONTENT_ARCHIVE_LENGTH
	call	LocalCmpStrings
	jne	gotContents			; use Documents
	cmp	{TCHAR}es:[di][CONTENT_ARCHIVE_LENGTH*(size TCHAR)], '\\'
	je	useArchive
	cmp	{TCHAR}es:[di][CONTENT_ARCHIVE_LENGTH*(size TCHAR)], C_NULL
	je	useArchive
notDoc:
	cmp	{TCHAR}es:[di], 'A'
	jne	notFloppy
	cmp	{TCHAR}es:[di][1*(size TCHAR)], ':'
	jne	notFloppy
	mov	dx, offset DeskStringsCommon:ContentsFloppy
	cmp	{TCHAR}es:[di][2*(size TCHAR)], '\\'
	je	gotContents
notFloppy:
	cmp	{TCHAR}es:[di][1*(size TCHAR)], ':'
	jne	notCD
	cmp	{TCHAR}es:[di][2*(size TCHAR)], '\\'
	jne	notCD
	LocalGetChar	ax, esdi, noAdvance
DBCS <	tst	ah							>
DBCS <	jnz	notCD							>
	sub	al, 'A'
	jb	notCD
	cmp	al, 'Z'-'A'
	ja	notCD
	call	DriveGetStatus
	andnf	ah, mask DS_TYPE
	cmp	ah, DRIVE_CD_ROM
	mov	dx, offset DeskStringsCommon:ContentsCD
	je	gotContents
	; XXX: just use generic folder for everything else
notCD:
	mov	dx, offset DeskStringsCommon:ContentsFolder
	jmp	short gotContents

useArchive:
	mov	dx, offset DeskStringsCommon:ContentsArchive
gotContents:
	mov	bx, handle DeskStringsCommon
	call	MemLock
	mov	ds, ax
	mov	si, dx
	mov	si, ds:[si]
	lea	di, ss:[locals].SPMV_folderName
	LocalCopyString				; use floppy name
	call	MemUnlock
	.leave
	ret
MakeContentsString	endp

contentArchivePath	TCHAR	"Archive"
CONTENT_ARCHIVE_LENGTH equ ($-contentArchivePath)/(size TCHAR)
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildFolderWindowHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	FolderSetPrimaryMoniker

PASS:		*ds:si - folder object

RETURN:		di - past last byte in new window header moniker

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/23/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildFolderWindowHeader	proc	near

	.enter	inherit	FolderSetPrimaryMoniker

	segmov	es, ss				; es:di = buffer for new header
	lea	di, ss:[locals].SPMV_folderName
	mov	cx, size SPMV_folderName
	call	BuildDiskAndPathName		; build null-term'ed string

	.leave

	ret
BuildFolderWindowHeader	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDiskAndPathName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the current path for a Folder object into a readable
		string in the usual form.

CALLED BY:	BuildFolderWindowHeader, 
		DiskNameAndPathnameForFolderInfo

PASS:		*ds:si	= Folder object
		es:di	= buffer for disk and pathname string
		cx	= size of said buffer
RETURN:		es:di	= past last used byte in buffer
DESTROYED:	ax, dx, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	?/?/?		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildDiskAndPathName	proc	near
	class	FolderClass
	.enter
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	BuildDiskAndPathNameFromVarData
	.leave
	ret
BuildDiskAndPathName	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildDiskAndPathNameFromVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build a standard-format full path and disk and drive-name
		string in the passed buffer using GenPath data stored in
		the passed object under the passed vardata types.

PASS:		*ds:si	= object with GenPath data bound to it
       		es:di	= buffer for result
		cx	= size of said buffer
		ax	= vardata tag under which the path is stored
		dx	= vardata tag under which its disk handle is saved

RETURN:		es:di	= after the null-terminator

DESTROYED:	ax, dx, bx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	2/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildDiskAndPathNameFromVarData proc	far
	uses	si, bp

	.enter
	;
	; Get the current path.
	; 
	call	GenPathFetchDiskHandleAndDerefPath	; ax <- disk,
							; ds:bx <- GenFilePath
	;
	; start with drive name
	;
if GPC_FILE_OP_DIALOG_PATHNAME
	;
	; use drive name, but not volume name
	;
	mov	si, bx
	add	si, offset GFP_path
	mov_tr	bx, ax
	mov	dx, -1			; add drive name
	call	FileConstructActualPath
	LocalStrLength		; point past null
else
	push	bx
	mov_tr	bx, ax
	call	DiskGetDrive		; al <- drive #
	call	DriveGetName		; store name
	;
	; Separate drive from volume by ':['
	; 
SBCS <	mov	ax, ':' or ('[' shl 8)					>
DBCS <	mov	ax, ':'							>
	stosw
DBCS <	mov	al, '['							>
DBCS <	stosw								>
SBCS <	dec	cx							>
SBCS <	dec	cx							>
DBCS <	sub	cx, 2*(size wchar)					>
	;
	; Copy in volume name we've already got.
	; 
	call	DiskGetVolumeName
SBCS <	clr	al		; skip to null				>
DBCS <	clr	ax		; skip to null				>
	LocalFindChar			;scasb/scasw
	LocalPrevChar esdi
	inc	cx
DBCS <	inc	cx							>
	;
	; Separate volume name from path by '] '
	; 
SBCS <	mov	ax, ']' or (' ' shl 8)					>
DBCS <	mov	ax, ']'							>
	stosw
DBCS <	mov	al, ' '							>
DBCS <	stosw								>
	;
	; Build full path from data
	; 
	pop	si
	add	si, offset GFP_path
	clr	dx
	call	FileConstructFullPath

	LocalNextChar esdi	; point past null
endif

	.leave
	ret
BuildDiskAndPathNameFromVarData	endp





if _GMGR
if not _FCAB

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUpdateUpDirButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update presence of up-directory button and extra
		pathname disply

CALLED BY:	MSG_UPDATE_UP_DIR_BUTTON

PASS:		*ds:si - FolderClass object
		cx - state of dispay control
			TRUE if maximized
			FALSE if not maximized

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
FolderUpdateUpDirButton	method	dynamic FolderClass, MSG_UPDATE_UP_DIR_BUTTON

	call	PrintFolderInfoString

	ret
FolderUpdateUpDirButton	endm

endif		; if (not _FCAB)
endif		; if _GMGR



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetDisplayOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get current file display options

CALLED BY:	MSG_GET_DISPLAY_OPTIONS

PASS:		ds:si - instance data of this folder

RETURN:		cl - file types to display
		ch - file attributes to display
		dl - sort field
		dh - display modes

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetDisplayOptions	method	dynamic FolderClass, MSG_GET_DISPLAY_OPTIONS
	mov	cl, ds:[di].FOI_displayTypes	; get current info
	mov	ch, ds:[di].FOI_displayAttrs
	mov	dl, ds:[di].FOI_displaySort
	mov	dh, ds:[di].FOI_displayMode
	ret
FolderGetDisplayOptions	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Folder_GetDiskAndPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Locate the disk handle and path for a Folder object

CALLED BY:	INTERNAL
PASS:		ds	= Folder object segment
RETURN:		ax	= disk handle (0 if path invalid)
		ds:bx	= GenFilePath holding the path & disk handle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/28/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Folder_GetDiskAndPath	proc	far
	uses	dx, si
	.enter

	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath

	.leave
	ret
Folder_GetDiskAndPath endp

Folder_GetActualDiskAndPath	proc	far
	uses	dx, si
	.enter

	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, ATTR_FOLDER_ACTUAL_PATH
	mov	dx, TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath

	.leave
	ret
Folder_GetActualDiskAndPath endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUpdateFreeSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update free space instance data and update folder info
		string in folder window

CALLED BY:	MSG_UPDATE_FREE_SPACE

PASS:		object stuff
		cx:dx - bytes free
		bp - disk handle 

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	03/15/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderUpdateFreeSpace	method	FolderClass, MSG_UPDATE_FREE_SPACE
		call	Folder_GetDiskAndPath

	
		cmp	bp, ax
		je	thisDisk

	;
	; They're not the same.  If the folder's disk handle is a
	; standard path, then compare bp against the top level disk
	; handle. 
	;
		
		test	ax, DISK_IS_STD_PATH_MASK
		jz	done

		push	es
FXIP	<	GetResourceSegmentNS dgroup, es, TRASH_BX		>
NOFXIP	<	segmov	es, dgroup, bx					>
		cmp	bp, es:[geosDiskHandle]
		pop	es
		jne	done
thisDisk:		
		DerefFolderObject	ds, si, di	
		cmpdw	ds:[di].FOI_diskInfo.DIS_freeSpace, cxdx
		je	done			; if same, don't waste time
						; else, save new free space
		movdw	ds:[di].FOI_diskInfo.DIS_freeSpace, cxdx
		call	PrintFolderInfoString

done:
		ret	
FolderUpdateFreeSpace	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSendDisplayOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	send current display options for this folder to
		display options dialog box 

CALLED BY:	MSG_SEND_DISPLAY_OPTIONS
			FolderGainTarget

PASS:		*ds:si - folder object

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSendDisplayOptions	method	FolderClass, MSG_SEND_DISPLAY_OPTIONS

if _NEWDESK ;GPC_FOLDER_WINDOW_MENUS
	DerefFolderObject	ds, si, di
	.warn -private
	cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP
	.warn @private
	je	done
endif
	;
	; send current display options to dialog box
	;
	mov	ax, MSG_GET_DISPLAY_OPTIONS
	call	ObjCallInstanceNoLock		; get cx, dx = display options

	call	SendDispOptsLow
done::
	ret
FolderSendDisplayOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendDispOptsLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the UI from the passed in parameters.

CALLED BY:	FolderSendDisplayOptions, GM< FolderLostTarget >

PASS:		*ds:si	- Folder object
		cx, dx	- display options
			cl = FIDT_*
			ch = FIDA_*
			dl = FIDS_*
			dh = FIDM_*
RETURN:		none
DESTROYED:	all

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	See header before code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/93    	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendDispOptsLow	proc	near
if GPC_FOLDER_WINDOW_MENUS
	class	FolderClass
endif
	.enter

if not _FCAB

	;
	; Don't allow passing in zero, as the UI objects always
	; have to have valid states.
	;
		
	ECMakeSureNonZero	cl
	ECMakeSureNonZero	ch
	ECMakeSureNonZero	dl
	ECMakeSureNonZero	dh

if _NEWDESK ;GPC_FOLDER_WINDOW_MENUS
	push	es
	mov	ax, segment NDWastebasketClass
	mov	es, ax
	mov	di, offset NDWastebasketClass
	call	ObjIsObjectInClass		; C set if so
	pop	es
	jc	notBrowse
	DerefFolderObject	ds, si, di
	mov	bx, ds:[di].FOI_windowBlock
	push	cx, dx, si
	clr	cx
	mov	cl, ss:[browseMode]
	mov	si, offset NDFolderMenuBrowseList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	call	ObjMessageCallFixup
	pop	cx, dx, si
notBrowse:
endif
		
	;
	; Set the DisplayViewModes
	;
if not _ZMGR

	push	cx			; FIDT_*, FIDA_*
	push	dx			; FIDS_*, FIDM_*

endif

	mov	cl, dh				; cl = FIDM_*
	clr	ch
	clr	dx				; not indeterminate
if GPC_FOLDER_WINDOW_MENUS
	DerefFolderObject	ds, si, di
	mov	bx, ds:[di].FOI_windowBlock
	push	{word}ds:[di].FOI_positionFlags
	mov	si, offset NDFolderMenuDisplayViewModes
else
GM<	mov	bx, handle DisplayViewModes	>
GM<	mov	si, offset DisplayViewModes	>
ND<	mov	bx, handle GlobalMenuDisplayViewModes	>
ND<	mov	si, offset GlobalMenuDisplayViewModes	>
endif
 	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	call	ObjMessageCallFixup


if not _ZMGR
	;
	; Set the DisplaySortByList
	;
if GPC_FOLDER_WINDOW_MENUS
	pop	cx
	test	cx, mask FIPF_POSITIONED
endif
	pop	cx			; FIDS_*, FIDM_*
	mov	ch, 0
if GPC_FOLDER_WINDOW_MENUS
	mov	si, offset NDFolderMenuDisplaySortByList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	jz	notPositioned
	mov	ax, MSG_GEN_ITEM_GROUP_SET_NONE_SELECTED
notPositioned:
else
GM<	mov	bx, handle DisplaySortByList	>
GM<	mov	si, offset DisplaySortByList	>
ND<	mov	bx, handle GlobalMenuDisplaySortByList	>
ND<	mov	si, offset GlobalMenuDisplaySortByList	>
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
endif
	clr	dx				; not indeterminate
	call	ObjMessageCallFixup

	;
	; Set the DisplayOptionsList
	;

	pop	cx				; ch = FIDA_*
	clr	cl
	xchg	cl, ch				; cl = FIDA_*
	mov	ax, cx
						; hidden + system?
	andnf	al, mask FIDA_HIDDEN or mask FIDA_SYSTEM
	cmp	al, mask FIDA_HIDDEN or mask FIDA_SYSTEM
	jne	missingEitherHiddenOrSystem
	andnf	cl, not mask FIDA_SYSTEM	; use just hidden

missingEitherHiddenOrSystem:
if GPC_FOLDER_WINDOW_MENUS
	mov	si, offset NDFolderMenuDisplayOptionsList
else
GM<	mov	bx, handle DisplayOptionsList				>
GM<	mov	si, offset DisplayOptionsList				>
ND<	mov	bx, handle GlobalMenuDisplayOptionsList			>
ND<	mov	si, offset GlobalMenuDisplayOptionsList			>
endif
	clr	dx				; no indeterminates
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	call	ObjMessageCallFixup

endif		;  if (not _ZMGR)
endif		;  if (not _FCAB)

	.leave
	ret
SendDispOptsLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderHideSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	hide selected files

CALLED BY:	MSG_HIDE_SELECTION

PASS:		ds:si - instance of Folder object

RETURN:	

DESTROYED:	

PSEUDO CODE/STRATEGY:
		uninvert all files in selection list; doesn't do anything to
		selection list itself;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderHideSelection	method	dynamic FolderClass, MSG_HIDE_SELECTION

	tst	ds:[di].DVI_gState		; no gstate - we're gone
	jz	exit
	andnf	ds:[di].FOI_folderState, not (mask FOS_UPDATE_PENDING)

	;moved here from FolderGainedTarget - brianc 9/9/94
	call	FolderLockAndDrawCursor 	; draw cursor

	mov	dx, mask DFI_CLEAR or mask DFI_DRAW
	call	FixSelectList
exit:
	ret
FolderHideSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderShowSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	show selected files

CALLED BY:	MSG_UNHIDE_SELECTION

PASS:		*ds:si - FolderClass object

RETURN:

DESTROYED:

PSEUDO CODE/STRATEGY:
		invert all files in selection list;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderShowSelection	method	dynamic FolderClass, MSG_UNHIDE_SELECTION

	;
	; we need to clear this even if there is no gstate as this can happen
	; if we restore a Folder Window that is completely off screen from a
	; state file - we'll get the GAIN_TARGET which marks FOS_UPDATE_PENDING
	; then get this, but never any MSG_META_EXPOSED to create a gstate
	; with; problems occur when you move the Folder Window back on screen,
	; selections don't highlight because this bit is set - brianc 8/31/90
	;
						; no longer pending
	andnf	ds:[di].FOI_folderState, not (mask FOS_UPDATE_PENDING)
	tst	ds:[di].DVI_gState		; any gstate?
	jz	exit				; no, window closed

	mov	dx, mask DFI_CLEAR or mask DFI_DRAW
	call	FixSelectList

	;moved here from FolderGainedTarget - brianc 9/9/94
	call	FolderLockAndDrawCursor 	; draw cursor
exit:
	ret

FolderShowSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixSelectList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	?

CALLED BY:

PASS:		*ds:si - FolderClass object
		dx - DrawFolderObjectIconFlags

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/15/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixSelectList	proc	far
	class	FolderClass

	uses	ax, bx, es, di, bp
	.enter
	call	FolderLockBuffer
	jz	exit

	DerefFolderObject	ds, si, di
	mov	di, ds:[di].FOI_displayList

checkDisplayLoop:
	cmp	di, NIL
	je	done
	test	es:[di].FR_state, mask FRSF_SELECTED or mask FRSF_DELAYED
	jz	nextDisplay

	andnf	es:[di].FR_state, not mask FRSF_DELAYED	; clear delay bit
	mov	ax, dx
	push	dx
	call	ExposeFolderObjectIcon		; invert icon
	pop	dx
nextDisplay:
	mov	di, es:[di].FR_displayNext
	jmp	short checkDisplayLoop

done:
	call	FolderUnlockBuffer
exit:
	.leave
	ret
FixSelectList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return state flags for this Folder Window

CALLED BY:	MSG_FOLDER_GET_STATE

PASS:		ds:si = instance handle
		ds:bx = instance data

RETURN:		cx - state flags

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	09/25/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderGetState	method	FolderClass, MSG_FOLDER_GET_STATE
	mov	cx, ds:[bx].FOI_folderState
	ret
FolderGetState	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderMetaInitializeVarData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with initializing the path vardata

CALLED BY:	MSG_META_INITIALIZE_VAR_DATA
PASS:		*ds:si	= Folder object
		cx	= vardata type that wants initializing
RETURN:		ds:ax	= initialized vardata entry
DESTROYED:	

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderMetaInitializeVarData method dynamic FolderClass, 
			    		MSG_META_INITIALIZE_VAR_DATA

		cmp	cx, ATTR_FOLDER_PATH_DATA
		je	initFolderPathData
		cmp	cx, ATTR_FOLDER_ACTUAL_PATH
		je	initFolderPathData
		
		mov	di, offset FolderClass
		GOTO	ObjCallSuperNoLock

initFolderPathData:
	;
	; Add the data to the object.
	; 
		mov_tr	ax, cx
		ornf	ax, mask VDF_SAVE_TO_STATE
		mov	cx, size GenFilePath
		call	ObjVarAddData
	;
	; Initialize it to SP_TOP (what the hell.... :)
	; 
		mov	ds:[bx].GFP_disk, SP_TOP
		mov	ds:[bx].GFP_path[0], 0
	;
	; Return offset in ax
	; 
		mov_tr	ax, bx
		ret
FolderMetaInitializeVarData endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	relocate instance of folder class OR default folder object

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
FolderRelocate	method	FolderClass, reloc
	push	es, bx
NOFXIP<	segmov	es, dgroup, bx						>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	cmp	es:[forceQuit], TRUE		; will be quitting?
	pop	es, bx
	jne	noQuit
	ornf	ds:[bx].FOI_folderState, mask FOS_BOGUS	; mark as bogus
	jmp	exit

noQuit:
	cmp	ax, MSG_META_RELOCATE
	je	relocate			; relocate
	
	;
	; tell GenPath mechanism we're outta here
	;
	mov	ax, ATTR_FOLDER_PATH_DATA 
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathUnrelocObjectPath

	mov	ax, ATTR_FOLDER_ACTUAL_PATH
	mov	dx, TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE
	call	GenPathUnrelocObjectPath

	jmp	exit

relocate:

	;
	; Store the chunk handle of the folder in its instance data.
	; Don't use our boffo "deref" macro, because the class pointer
	; isn't relocated yet!
	;

	mov	di, ds:[si]
	mov	ds:[di].FOI_chunkHandle, si

	;
	; If no path bound yet, then object is in the process of being
	; duplicated, rather than restored, so do nothing, as FolderInit and
	; CreateFolderWindowCommon will do all the right things.
	; 
	mov	ax, ATTR_FOLDER_PATH_DATA
	call	ObjVarFindData
	LONG jnc	exit

BA<	call	BACheckAndHandleNonExistentDriveError	>
BA<	jc	markBogus				>

	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathFetchDiskHandleAndDerefPath

	mov	di, ds:[si]			; deref.
	tst	ax				; disk handle restore failed?
	LONG jz	markBogus			; yes -- mark folder as bogus

	;
	; Do a FileConstructFullPath on the actual path to get the
	; actual disk handle, since the actual path may be stored as a
	; standard path
	;

	push	es, di, si
	mov	si, bx				; ds:si - path
	mov_tr	bx, ax				; disk handle (S.P.?)
	call	ShellAllocPathBuffer		; es:di - dest
	clr	dx
	mov	cx, size PathName
	call	FileConstructFullPath
	call	ShellFreePathBuffer
	pop	es, di, si
	
	mov	ds:[di].FOI_actualDisk, bx
	


	clr	ax
	mov	ds:[di].FOI_folderState, ax	; no state flags, yet (done
						;  before finishReInit so
						;  FOS_BOGUS set by markBogus
						;  remains -- ardeb 8/7/92)

	tst	ds:[di].FOI_windowBlock
	jz	noMoniker
	push	ax, di
	mov	ax, MSG_FOLDER_SET_PRIMARY_MONIKER
	mov	bx, ds:[LMBH_handle]
	call	ObjMessageForce
	pop	ax, di
noMoniker:
if GPC_NAMES_AND_DETAILS_TITLES
	;
	; reset names and details column header sizes for possible font change
	;
	tst	ds:[di].FOI_windowBlock
	jz	noReset
	push	ax, di
	mov	ax, MSG_FOLDER_RESET_NAMES_AND_DETAILS
	mov	bx, ds:[LMBH_handle]
	call	ObjMessageForce
	pop	ax, di
noReset:
endif

finishReInit:
	mov	ds:[di].FOI_displayType, al	; no DisplayType yet


	mov	ds:[di].FOI_buffer, ax		; clear buffer, in case error
	mov	ds:[di].FOI_fileCount, ax	; no files yet
	mov	ds:[di].FOI_displayList, NIL	; no displayed files, yet
	mov	ds:[di].FOI_selectList, NIL	; no selected files, yet
	movP	ds:[di].FOI_winBounds, axax	; force display list rebuild
	tst	ds:[di].FOI_windowBlock
	jz	skipDummy
	mov	bx, ds:[LMBH_handle]		; bx = folder object block
	call	SaveNewFolder			; save in global table
BA<	call	BARecheckCreateFolderPermissions	>

skipDummy:
	;
	; folder will be scanned when first drawn
	;
	andnf	ds:[di].FOI_folderState, not mask FOS_SCANNED

exit:
	mov	di, offset FolderClass
	call	ObjRelocOrUnRelocSuper
	ret

markBogus:
	;
	; Close the thing down ASAP
	; 
	call	FolderSendCloseViaQueue
	mov	di, ds:[si]
	clr	ax			; clear AX for finishReInit
	jmp	finishReInit
FolderRelocate	endp

if _NEWDESKBA

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BACheckAndHandleNonExistentDriveError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If we are restarting from state and a folder window was left
		open from a drive that no longer exists (most likely because
		the machine that was previously logged into had a different
		drive configuration), we need to intercept this error before
		it happens, because the regular UI error doesn't explain that
		this might have been caused by logging into a machine with a
		different drive configuration (because in regular GEOS this 
		doesn't happen).

CALLED BY:	FolderRelocate
PASS:		*ds:si	- NDFolderObject
RETURN:		carry set if there was an error (the error is handled *inside*
						 this routine)
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/11/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BACheckAndHandleNonExistentDriveError	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	ax, TEMP_FOLDER_ACTUAL_SAVED_DISK_HANDLE
	call	ObjVarFindData
	mov	si, bx			; ds:si is saved disk handle buffer
	clr	cx
	call	DiskRestore
	jnc	exit

	mov	ax, ERROR_BA_DRIVE_NO_LONGER_VALID
	call	DesktopOKError
	stc

exit:
	.leave
	ret
BACheckAndHandleNonExistentDriveError	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BARecheckCreateFolderPermissions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check our permissions, and force queue a message to ourselves
		setting our CreateFolder UI usable or not usable.  Check to
		see if our WOT has Create Folder in our menu before bothering
		to force queue to ourselves

CALLED BY:	FolderRelocate
PASS:		*ds:si	- NDFolderObject
RETURN:		nothing
DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	6/ 3/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BARecheckCreateFolderPermissions	proc	near
	class	NDFolderClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	IclasGetUserPermissions
	test	ax, mask UP_CREATE_FOLDER
	mov	cx, MSG_GEN_SET_USABLE
	jnz	havePermission
	mov	cx, MSG_GEN_SET_NOT_USABLE
havePermission:
	xchg	si, dx				; save folder chunk handle in dx
	mov	si, ds:[di].NDFOI_ndObjType
	call	BAGetCreateFolderOffset
	tst	si
	jz	exit

	mov	bx, ds:[LMBH_handle]
	xchg	si, dx				; swap menu and folder chunk
	mov	ax, MSG_UPDATE_CREATE_FOLDER_PERMISSIONS	; handles
	call	ObjMessageForce
exit:
	.leave
	ret
BARecheckCreateFolderPermissions	endp
endif		; if _NEWDESKBA

FolderCode	ends
