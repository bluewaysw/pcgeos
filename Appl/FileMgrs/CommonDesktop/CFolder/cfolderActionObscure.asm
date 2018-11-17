COMMENT @----------------------------------------------------------------------
	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/Folder
FILE:		cfolderActionObscure.asm
AUTHOR:		Brian Chin


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of cfolderClass.asm

DESCRIPTION:
	This file contains folder display object.

	$Id: cfolderActionObscure.asm,v 1.3 98/06/03 13:24:47 joon Exp $

------------------------------------------------------------------------------@
FolderAction	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start file selection

CALLED BY:	MSG_META_START_SELECT

PASS:		ds:si - handle of instance of Folder
		es - segment of FolderClass
		cx - X coord of press
		dx - Y coord of press
		bp - button info

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		PLAIN:
			if over object deselect all and select it
			if not over object deselect all
		ADJUST:
			if over object, toggle it
			if not over object, do nothing
		EXTEND:
			if no anchor point:
				if over object deselect all and select it
				if not over object deselect all
			if anchor point:
				deselect all and select new range
		EXTEND and ADJUST:
			if no anchor point:
				if over object, toggle it
				if not over object, do nothing
			if anchor point:
				select new range

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/31/89		Initial version
	brianc	8/30/89		changed from MSG_META_BUTTON to ...

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartSelect	method	dynamic	FolderClass, MSG_META_START_SELECT
if _PEN_BASED
	mov	ss:[lastMousePosition].P_x, cx	; for icon repositioning
	mov	ss:[lastMousePosition].P_y, dx
endif
	mov	ss:[fileDragging], 0		; no dragging ops yet
	mov	ss:[fileDoubleClick], FALSE	; no double-click yet

	call	FolderLockBuffer
	LONG jz	saveAnchorAndExit

	mov	ax, FALSE			; no default checking
	call	GetFolderObjectClicked		; check if click on object
						; es:di = object if so
	jnc	noObject			; if none, handle it
	;
	; click on object
	;
	test	bp, mask BI_DOUBLE_PRESS
	jnz	doubleClick
	;
	; single click
	;
single:
	mov	ss:[fileDragging], mask FDF_MOVECOPY_PENDING
	mov	ss:[fileToMoveCopy], di		; save file to move/copy
	mov	ss:[fileDraggingDest], NIL
				; allow double-clicks again
	andnf	ds:[bx].FOI_folderState, not mask FOS_DISALLOW_DOUBLE
	mov	ds:[bx].FOI_objectClick, di	; save object single-clicked
if _NEWDESK
if GPC_MAIN_SCREEN_LINK
	cmp	es:[di].FR_desktopInfo.DI_objectType, WOT_LOGOUT
	je	openIt
endif
endif
	test	bp, mask UIFA_ADJUST shl 8
	jnz	objAdjust
	test	bp, mask UIFA_EXTEND shl 8
	jnz	objExtend
	;
	; plain click on object
	;
	mov	ds:[bx].FOI_anchor.P_x, cx	; save as anchor point
	mov	ds:[bx].FOI_anchor.P_y, dx
;
; to allow quick-transfer of multiple files on ZMGR, don't deselect if click
; on already-selected file - brianc 3/12/93
;
if _PEN_BASED
	test	es:[di].FR_state, mask FRSF_SELECTED
	jnz	done				; skip deselect and re-select
endif

	call	DeselectAll
	call	SelectESDIEntry
	jmp	done

doubleClick:
	mov	ss:[fileDoubleClick], TRUE	; received double-click
	test	ds:[bx].FOI_folderState, mask FOS_DISALLOW_DOUBLE
	jnz	done				; no double-clicks allowed!
	cmp	di, ds:[bx].FOI_objectClick	; same as prev. single-click?
	jne	single				; nope, treat as single-click
						; no more double-clicks
						;	until single-click
	ornf	ds:[bx].FOI_folderState, mask FOS_DISALLOW_DOUBLE

openIt::
	call	ClearRegionIfNeeded

if _NEWDESKBA
	;
	; Rather than calling FileOpenESDI directly, send a message,
	; as various subclasses will want to do various things.  
	;
	mov	cx, es
	mov	dx, di
	mov	ax, MSG_FOLDER_OPEN_ICON
	call	ObjCallInstanceNoLock
else
	call	FileOpenESDI
endif
	jmp	short done

objAdjust:
	test	bp, mask UIFA_EXTEND shl 8
	jnz	objAdjExt
	;
	; adjust click on object
	;
	jmp	short noObjAdjust

objExtend:
	jmp	short done			; all work done in DRAG, END

objAdjExt:
	jmp	short done			; ignore for now

noObject:
	;
	; click on nothing
	;
	test	bp, mask UIFA_ADJUST shl 8
	jnz	noObjAdjust
	test	bp, mask UIFA_EXTEND shl 8
	jnz	noObjExtend
	;
	; plain click on nothing
	;
	mov	ds:[bx].FOI_anchor.P_x, cx	; save as anchor point
	mov	ds:[bx].FOI_anchor.P_y, dx
	cmp	ds:[bx].FOI_selectList, NIL	; emtpy select list?
	je	noInfoStringUpdate		; yes, leave info string alone
	call	DeselectAll

	call	PrintFolderInfoString		; update folder info

noInfoStringUpdate:
	jmp	short done

noObjAdjust:
	test	bp, mask UIFA_EXTEND shl 8
	jnz	noObjAdjExt
	;
	; adjust click on nothing
	;
	movP	ds:[bx].FOI_anchor, cxdx	; save as anchor point
	jmp	done			; do nothing

noObjExtend:
	jmp	objExtend			; handle the same

noObjAdjExt:
	jmp	done			; ignore for now

saveAnchorAndExit:
	movP	ds:[bx].FOI_anchor, cxdx	; save as anchor point
	jmp	exit			; done

done:
	call	FolderUnlockBuffer
exit:
	mov	ax, mask MRF_PROCESSED
	ret
FolderStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	start selection rectangle

CALLED BY:	MSG_META_DRAG_SELECT

PASS:		mouse stuff

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDragSelect	method	dynamic	FolderClass, MSG_META_DRAG_SELECT

	;
	; On pen-based systems, a drag-select signals the start of a move.
	;

if _PEN_BASED
	; 
	; If user is holding down shift key then don't do quick transfer
	;

	test	bp,mask UIFA_EXTEND shl 8
	jnz	noQT

	test	ss:[fileDragging], mask FDF_MOVECOPY_PENDING
	jz	noQT
	andnf	ss:[fileDragging], not mask FDF_MOVECOPY_PENDING
	tst	ss:[fileToMoveCopy]
	jz	noQT

				; indicate START_SELECT quick-transfer
	ornf	ss:[fileDragging], mask FDF_SELECT_MOVECOPY
	push	si
	call	FolderDragMoveCopy
	pop	si
	;
	; add post-passive button to deal with ending the quick-transfer on
	; a non-destination.  Since this is for ZMGR where apps are full-
	; screen, this should be sufficient (post-passive only works within
	; the app)
	;
	DerefFolderObject	ds, si, si
	mov     bx, ds:[si].FOI_windowBlock     ; bx:si = our View
	mov     si, FOLDER_VIEW_OFFSET
	mov	ax, MSG_VIS_ADD_BUTTON_POST_PASSIVE
	call	ObjMessageCallFixup		; cx = window
	ret

noQT:
endif

	push	cx				; save press location
	push	dx
	mov	si, bx
	mov	di, ds:[si].DVI_window		; di = window
	call	GrCreateState			; di = gState
	mov	ss:[regionSelectGState], di	; save it
;	mov	al, LS_DASHED		; LineStyle
;	clr	bl				; skip distance
;	call	GrSetLineStyle
;this is faster - brianc 9/20/90
	mov	al, SDM_50
	call	GrSetLineMask
	mov	al, MM_INVERT
	call	GrSetMixMode

	call	GrGetWinBounds			; ax, bx, cx, dx = bounds
	mov	ss:[regionWinBounds].R_left, ax	; save 'em
	mov	ss:[regionWinBounds].R_top, bx
	mov	ss:[regionWinBounds].R_right, cx
	mov	ss:[regionWinBounds].R_bottom, dx
	mov	ss:[fileDragging], mask FDF_REGION ; indicate region started
	pop	dx				; retrieve press location
	pop	cx
	test	bp, mask UIFA_EXTEND shl 8	; extending selection?
	jz	80$				; no, handle normally
	cmp	ds:[si].FOI_anchor.P_x, -1	; any anchor?
	jne	80$				; if so, use it
	mov	ds:[si].FOI_anchor.P_x, cx	; else, use current position
	mov	ds:[si].FOI_anchor.P_y, dx
80$:
	mov	ax, ds:[si].FOI_anchor.P_x
	mov	ss:[regionSelectStart].P_x, ax
	mov	ax, ds:[si].FOI_anchor.P_y
	mov	ss:[regionSelectStart].P_y, ax
	mov	ss:[regionSelectEnd].P_x, NIL	; no region end yet
	mov	ax, mask MRF_PROCESSED
	ret
FolderDragSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= FolderClass object
		ds:di	= FolderClass instance data
		es	= segment of FolderClass

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	7/17/92   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderEndSelect	method	dynamic FolderClass, MSG_META_END_SELECT

if _PEN_BASED
	mov	ss:[delayedFileDraggingEnd], BB_FALSE
endif
	cmp	ss:[fileDoubleClick], TRUE	; if ending double-click,
	je	exit_JZ				;	do nothing
	mov	al, ss:[fileDragging]		; get file dragging status
	mov	ss:[fileDragging], 0		; done file dragging

if _PEN_BASED

	test	al, mask FDF_MOVECOPY
	jz	notQT
	GOTO	FolderEndMoveCopy
notQT:
endif

	test	al, mask FDF_REGION		; check if region select active
	jnz	endRegion			; if so, handle it
;;hack - don't select item when adjusting selected rectangle - 6/7/90
	test	bp, mask UIFA_ADJUST shl 8
	jnz	7$				; select w/singularity
;;
	test	bp, mask UIFA_EXTEND shl 8	; extending?
	jz	exit_JZ				; nope
	cmp	ds:[bx].FOI_anchor.P_x, -1	; any anchor?
	jne	10$				; if so, use it
7$:
	mov	ds:[bx].FOI_anchor.P_x, cx	; else, use current position
	mov	ds:[bx].FOI_anchor.P_y, dx
10$:
	mov	ax, ds:[bx].FOI_anchor.P_x
	mov	ss:[regionSelectStart].P_x, ax
	mov	ax, ds:[bx].FOI_anchor.P_y
	mov	ss:[regionSelectStart].P_y, ax
	jmp	short select			; select range

endRegion:
	;
	; end region select
	;
	mov	di, ss:[regionSelectGState]
	call	FixRegionPosition
	call	ClearLastRegion
	call	GrDestroyState
	mov	ss:[regionSelectGState], 0

select:
	mov	ss:[regionSelectEnd].P_x, cx	; save new end position
	mov	ss:[regionSelectEnd].P_y, dx
	call	FolderLockBuffer

exit_JZ:
	jz	exit

	push	ds:[bx].FOI_selectList		; save select list status
	test	bp, mask UIFA_EXTEND shl 8	; extending selection?
	jz	30$				; no, handle normally
	test	bp, mask UIFA_ADJUST shl 8	; extending and adjusting?
	jnz	30$				; yes, don't deselect all
	call	DeselectAll			; else, deselect for extend
30$:
	call	SelectRange
	pop	ax				; ax = old selection status
	cmp	ax, NIL				; was there a selection before?
	jne	skipOpt				; yes, skip optimization check
	cmp	ax, ds:[bx].FOI_selectList	; is there still no selection?
	je	noInfoUpdate			; yes!, no need to update info

skipOpt:
	call	PrintFolderInfoString		; update info string

noInfoUpdate:
	call	FolderUnlockBuffer

exit:
	mov	ax, mask MRF_PROCESSED
	ret
FolderEndSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SelectRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	select range of files

CALLED BY:	INTERNAL
			FolderEndSelect

PASS:		ss:[regionStartSelect] - upper left
		ss:[regionEndSelet] - lower right
		*ds:si - FolderClass object 
		es - segment of locked folder buffer
		bp - button flags

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/18/90	broken out

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SelectRange	proc	far
	class	FolderClass
	uses	bx

	.enter

	call	HackSelectBoundsForNamesOnly
	
	DerefFolderObject	ds, si, bx
	mov	di, ds:[bx].FOI_displayList
	mov	bx, NIL

fileLoop:
	cmp	di, NIL
	je	done
	call	CheckFileInRegion
	jnc	nextFile			; no
	test	es:[di].FR_state, mask FRSF_SELECTED	; selected?
	jnz	selected
	;
	; unselected, select it
	;
	call	AddToSelectList
	mov	bx, di
	jmp	short nextFile
	;
	; selected, if ADJUST, unselect
	;
selected:
	test	bp, mask UIFA_ADJUST shl 8	; adjust?
	jz	nextFile			; no, leave file alone
	call	RemoveFromSelectList		; else, unselect
nextFile:
	mov	di, es:[di].FR_displayNext
	jmp	fileLoop

done:
	cmp	bx, NIL
	je	exit

	mov	di, bx
	call	SetCursor
exit:
	.leave
	ret
SelectRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HackSelectBoundsForNamesOnly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	?

CALLED BY:	SelectRange

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/16/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HackSelectBoundsForNamesOnly	proc	near
	class	FolderClass

	uses	ax, di

	.enter

	DerefFolderObject	ds, si, bx
	test	ds:[bx].FOI_displayMode, mask FIDM_SHORT
	jz	done				; not "Names Only", done
	mov	di, ds:[bx].FOI_displayList
hackLoop:
	cmp	di, NIL
	je	done				; nothing found, no adjustment
	call	CheckFileInRegion		; is file in select bounds?
	jc	adjust				; yes, adjust select bounds
	mov	di, es:[di].FR_displayNext	; else, check next file
	jmp	short hackLoop

adjust:
	mov	ax, es:[di].FR_boundBox.R_left	; bump select bounds outward
	mov	di, ss:[regionSelectEnd].P_x	;	to include whole column
	cmp	di, ss:[regionSelectStart].P_x
	jge	adjustStart
	mov	ss:[regionSelectEnd].P_x, ax
	jmp	short done

adjustStart:
	mov	ss:[regionSelectStart].P_x, ax
done:
	.leave
	ret
HackSelectBoundsForNamesOnly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckFileInRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the file falls in the selection rectangle

CALLED BY:	HackSelectBoundsForNamesOnly

PASS:		es:di - file to check

RETURN:		carry SET if in region, carry CLEAR otherwise

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	3/16/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckFileInRegion	proc	near
	class	FolderClass
	uses	ax,bx,cx,dx,si,bp
	.enter

	mov	ax, ss:[regionSelectStart].P_x
	mov	bx, ss:[regionSelectStart].P_y
	mov	cx, ss:[regionSelectEnd].P_x
	mov	dx, ss:[regionSelectEnd].P_y
	cmp	ax, cx
	jl	swapY
	xchg	ax, cx
swapY:
	cmp	bx, dx
	jl	swapDone
	xchg	bx, dx
swapDone:

	DerefFolderObject	ds, si, si
	test	ds:[si].FOI_displayMode, mask FIDM_LICON
	jnz	iconMode		; icon mode -> check icon only

if 0	; text modes, use complete bounding box
	cmp	ax, es:[di].FR_nameBounds.R_right
	jg	notName
	cmp	bx, es:[di].FR_nameBounds.R_bottom
	jg	notName
	cmp	cx, es:[di].FR_nameBounds.R_left
	jl	notName
	cmp	dx, es:[di].FR_nameBounds.R_top
	jge	yesIn
notName:
	cmp	ax, es:[di].FR_iconBounds.R_right
	jg	notIn
	cmp	bx, es:[di].FR_iconBounds.R_bottom
	jg	notIn
	cmp	cx, es:[di].FR_iconBounds.R_left
	jl	notIn
	cmp	dx, es:[di].FR_iconBounds.R_top
	jl	notIn
else	; text modes, use complete bounding box
	cmp	ax, es:[di].FR_boundBox.R_right
	jg	notIn
	mov	bp, es:[di].FR_boundBox.R_bottom
	sub	bp, 2					; bottom leeway
	cmp	bx, bp
	jg	notIn
	cmp	cx, es:[di].FR_boundBox.R_left
	jl	notIn
	mov	bp, es:[di].FR_boundBox.R_top
	add	bp, 3					; top leeway
	cmp	dx, bp
	jl	notIn
endif	; text modes, use complete bounding box
yesIn:
	stc
	jmp	short done

iconMode:
	cmp	ax, es:[di].FR_iconBounds.R_right
	jg	notIn
;	cmp	bx, es:[di].FR_nameBounds.R_bottom	; <- use name bottom
;3 pixel leeway on bottom
	mov	bp, es:[di].FR_nameBounds.R_bottom
	sub	bp, 3
	cmp	bx, bp
	jg	notIn
	cmp	cx, es:[di].FR_iconBounds.R_left
	jl	notIn
;	cmp	dx, es:[di].FR_iconBounds.R_top
;3 pixel leeway on top
	mov	bp, es:[di].FR_iconBounds.R_top
	add	bp, 3
	cmp	dx, bp
	jl	notIn
	jmp	short yesIn
	
notIn:
	clc
done:
	.leave
	ret
CheckFileInRegion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStopQuickTransferFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL -
		clear move/copy cursor if doing quick transfer

CALLED BY:	MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL

PASS:		*ds:si - FolderClass object 

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Not dynamic (is called directly)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStopQuickTransferFeedback	method	FolderClass, 
					MSG_META_CONTENT_VIEW_LOST_GADGET_EXCL,
					MSG_FOLDER_STOP_FEEDBACK

	DerefFolderObject	ds, si, bx
	test	ds:[bx].FOI_folderState, mask FOS_FEEDBACK_ON
	jz	noFeedback			; not doing feedback

	mov	ax, CQTF_CLEAR			; clear any move/copy cursor
	call	ClipboardSetQuickTransferFeedback
	andnf	ds:[bx].FOI_folderState, not mask FOS_FEEDBACK_ON
if TOGGLE_FOLDER_DEST
	stc					; deselect any feedback
	call	ToggleFolderDragDest		;	selection
endif
	jmp	short done			; skip over clearing drag
						;	selection

noFeedback:
	call	ClearRegionIfNeeded		; stop drag selection
done:
	ret
FolderStopQuickTransferFeedback	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	begin direct manipulation

CALLED BY:	MSG_META_START_MOVE_COPY

PASS:		*ds:si - FolderClass object
		bx - offset to FolderClass instance data
RETURN:		none

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/18/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderStartMoveCopy	method	dynamic FolderClass, MSG_META_START_MOVE_COPY

	mov	ss:[lastMousePosition].P_x, cx
	mov	ss:[lastMousePosition].P_y, dx
	mov	ss:[fileDragging], 0		; init dragging flag
	clr	ss:[fileToMoveCopy]

	;
	; check if any folder clicked on
	;

	call	FolderLockBuffer
	jz	done

	mov	ax, FALSE			; no default checking
	call	GetFolderObjectClicked		; check if click on object
	call	FolderUnlockBuffer		; (preserves flags!!)
	jnc	done				; if no object, do nothing

	mov	ss:[fileToMoveCopy], di		; save file to move/copy
	mov	ss:[fileDraggingDest], NIL

done:
	mov	ax, mask MRF_PROCESSED
	ret
FolderStartMoveCopy	endm

;
; needed because View has 'grabWhilePressed' set and grabs on both
; MSG_META_START_MOVE_COPY and MSG_META_DRAG_MOVE_COPY, so we want to make
; sure that it is released
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDragMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Build out the quick transfer list

PASS:		*ds:si	- FolderClass object
		ds:di	- FolderClass instance data
		es	- segment of FolderClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	
		called statically from FolderDragSelect

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	2/11/93   	added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FolderDragMoveCopy	method	FolderClass, MSG_META_DRAG_MOVE_COPY

if _PEN_BASED or _DOCMGR  ; no dragging at all for DocMgr
	;
	; do nothing for real move/copy, only operate on fake move/copy
	;
	test	bp, mask UIFA_MOVE_COPY shl 8
	jnz	clearState
endif
		
	tst	ss:[fileToMoveCopy]
	jz	done

	ornf	ss:[fileDragging], mask FDF_MOVECOPY

	call	StartDragMoveOrCopy		; attempt to start quick-trns.
	jnc	ok				; started successfully
						; else, clear flags

clearState::
	andnf	ss:[fileDragging], not (mask FDF_MOVECOPY or \
					mask FDF_SELECT_MOVECOPY )
	jmp	done

ok:
	ornf	ss:[fileDragging], mask FDF_DRAG_STARTED ; the quick transfer
				 ; has moved or timed out, indicating a drag

done:
	mov	ax, mask MRF_PROCESSED
	ret
FolderDragMoveCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderBringToFront
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	brings the folder associated with this folder window
		to the front

CALLED BY:	MSG_FOLDER_BRING_TO_FRONT

PASS:		ds:si - instance handle of this folder

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Should probably be called MSG_FOLDER_BRING_TO_TOP

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderBringToFront	method	FolderClass, MSG_FOLDER_BRING_TO_FRONT

if _FCAB		; deselect when bringing to front for FileCabinet
	;
	; deselect all files so user doesn't wonder why files are selected
	; from a seemingly-just-opened Folder Window
	; (this also generates a PrintFolderInfoString which will update the
	; state of the Open Directory button)
	;
	mov	ax, MSG_DESELECT_ALL
	call	ObjCallInstanceNoLock
endif		; if _FCAB

	;
	; Make sure the display / primary isn't minimized
	;

	DerefFolderObject	ds, si, di
	mov	bx, ds:[di].FOI_windowBlock	; bx:si = folder window
	mov	si, FOLDER_WINDOW_OFFSET

	mov	ax, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	call	ObjMessageNone

	mov	ax, MSG_GEN_BRING_TO_TOP
	call	ObjMessageNone
	ret
FolderBringToFront	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderEndMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle quick transfer (file move or copy)

CALLED BY:	MSG_META_END_MOVE_COPY

PASS:		ds:si - instance handle of folder object
		es - segment of FolderClass
		ax - END_MOVE_COPY
		cx, dx - mouse position
		bp (high) - UIFA flags
			UIFA_MOVE - if move override
			UIFA_COPY - if copy override

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		called statically from FolderEndSelect

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/16/89	Initial version
	brianc	03/13/91	Updated for 2.0 quick-transfer
	martin	07/08/92	Added flexible placement of icons
	AY	11/22/92	Supported a new manufacturer ID

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderEndMoveCopy	method	FolderClass, MSG_META_END_MOVE_COPY

FolderTransferFlags	record
	FTF_SOURCE_IS_DEST:1		; source folder is dest. folder
	FTF_DROP_ON_FILE:1		; drop stuff on file icon
	FTF_DROP_ON_FOLDER:1		; drop stuff on folder icon
	FTF_SRC_DEST_DIFF_DISK:1	; if src and dest are different disks
	FTF_NO_OPERATION:1		; if item is not accepted
	:11
FolderTransferFlags	end

UIFAFlags		local	word	push	bp
mousePos		local	Point	push	dx, cx
destFile		local	fptr
folderTransferFlags	local	FolderTransferFlags
sourceHandle		local	word
sourceChunk		local	word
transferVMfile		local	word
transferVMblock		local	word
manufacturer		local	ManufacturerID
	.enter

	;
	; clear quick-transfer flags
	;
	andnf	ss:[fileDragging], not (mask FDF_MOVECOPY or \
						mask FDF_SELECT_MOVECOPY)

if _PEN_BASED
	;
	; if ZMGR, VisContent didn't do a ClipboardHandleEndMoveCopy
	; because we faked it with a END_SELECT, so we need to do it
	; ourselves
	;
	mov	bx, -1			; have active grab (us)
	clc				; don't check quick-transfer status
	call	ClipboardHandleEndMoveCopy
endif

	mov	folderTransferFlags, mask FTF_NO_OPERATION	; assume error

	;
	; stop feedback, if we are doing it
	;
	mov	ax, MSG_FOLDER_STOP_FEEDBACK
	push	bp
	call	ObjCallInstanceNoLock		; could trash cx, dx, bp
	pop	bp

	;
	; do simple trivial-reject
	;
	DerefFolderObject	ds, si, di
	;
	; check if we support the current transfer item
	; (we only handle CIF_FILES)
	;
	push	bp				; save locals pointer
	mov	bp, mask CIF_QUICK		; get quick-transfer item
	call	ClipboardQueryItem		; returns: bp = format count
	mov	di, bp				; di = format count
	pop	bp				; retrieve locals pointer

	mov	sourceHandle, cx		; cx:dx = transfer item owner
	mov	sourceChunk, dx
	mov	transferVMfile, bx		; bx:ax = transfer item header
	mov	transferVMblock, ax

	tst	di				; any quick-transfer item?
	jz	noTransfer			; if not, done
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	ss:[manufacturer], cx
	mov	dx, CIF_FILES
	call	ClipboardTestItemFormat		; is there a CIF_FILES?
	jnc	foundFormat			; yes, use it

if _NEWDESKBA
	mov	cx, MANUFACTURER_ID_WIZARD
	mov	ss:[manufacturer], cx
	call	ClipboardTestItemFormat
	jnc	foundFormat
endif		; if _NEWDESKBA

noTransfer:

if _NEWDESK
	test	ss:[fileDragging], mask FDF_DRAG_STARTED
	LONG	jnz	doneNoLock

	;
	; There was no DRAG operation, so bring up the pop-up menu.
	;

	call	FolderLockBuffer
	jz	whiteSpace		; no buffer, just bring up
					; whitespace popup

	mov	ax, TRUE
	mov	cx, ss:[mousePos].P_x
	mov	dx, ss:[mousePos].P_y
	call	GetFolderObjectClicked
	jnc	whiteSpace

	call	NDObjectPopUp
	jmp	done	

whiteSpace:
	call	NDWhiteSpacePopUp
	jmp	done

else

	jmp	doneNoLock

endif		; _NEWDESK

foundFormat:
	;
	; we have a CIF_FILES transfer item, check if stuff was dropped
	; on folder icon or file icon
	;
	clr	folderTransferFlags		; assume not drop on file or
						;  folder

	call	FolderLockBuffer
	jnz	haveBuffer

	;
	; there's no folder buffer
	;
	mov	ss:[destFile].segment, ds	; prevent rampant death from
						; loading es with uninitialized
						; segment later on
	mov	ss:[destFile].offset, -1	; no files in folder
	jmp	gotDestFlags

haveBuffer:	
	mov	destFile.segment, es
	mov	ax, TRUE			; force checking icon and name
	mov	cx, mousePos.P_x
	mov	dx, mousePos.P_y
	call	GetFolderObjectClicked		; es:di = dest. file
	mov	destFile.offset, di
	jnc	gotDestFlags			; => drop on background, so
						;  leave FTF clear
	cmp	ax, CLICKED_ON_ICON		; drop on icon?
	jne	gotDestFlags			; no
	;
	; dropped on file or folder, check which
	;
	mov	ax, mask FTF_DROP_ON_FOLDER	; assume folder
	test	es:[di].FR_fileAttrs, mask FA_SUBDIR
	jnz	setDestFlags
	mov	ax, mask FTF_DROP_ON_FILE

setDestFlags:
	mov	ss:[folderTransferFlags], ax

gotDestFlags:
	;
	; check to see if source == dest
	;
	mov	dx, sourceHandle		; dx:cx = source
	mov	cx, sourceChunk
	cmp	dx, ds:[LMBH_handle]
	jne	different
	cmp	cx, FOLDER_OBJECT_OFFSET	; common offset
	jne	different			; source different than dest.
	;
	; destination is same as source (us!); if drop onto ourselves or
	; drop onto nothing, get out
	;
	ornf	folderTransferFlags, mask FTF_SOURCE_IS_DEST	; same src/dest
	test	folderTransferFlags, mask FTF_DROP_ON_FILE or \
					mask FTF_DROP_ON_FOLDER	;
								;anything?

;; conditionals for quick demo:
GM <	jz	done							>
ND <	LONG	jz	moveIcon			; if neither,	>
							; move icon
	mov	bx, ss:[fileToMoveCopy]		; bx = file being dragged
	cmp	bx, destFile.offset		; drop onto ourselves?


;; conditionals for quick demo:
GM <	jz	done							>
ND <	LONG	je	moveIcon		; yes, move icon	>
						; (if moved before)
	mov	ax, folderTransferFlags
	andnf	ax, mask FTF_DROP_ON_FILE or mask FTF_SOURCE_IS_DEST
	cmp	ax, mask FTF_DROP_ON_FILE or mask FTF_SOURCE_IS_DEST
	je	done				; if drop on file in same
						;	Folder Window, do nada

	;
	; cases of interest:
	;	1) dropping unselected file onto selected file
	;	2) dropping unselected file onto unselected file
	;	3) dropping only selected file onto unselected file
	;	4) dropping selected files onto unselected file
	;
	mov	es, destFile.segment		; es = folder buffer segment
	test	es:[bx].FR_state, mask FRSF_SELECTED	; drag-file selected?
	jz	different			; no, do transfer
	mov	bx, destFile.offset		; bx = destination file
	test	es:[bx].FR_state, mask FRSF_SELECTED	; dest. selected?
	jnz	done				; yes, do nothing
						; else, we are not in select
						;	list, do transfer
different:
	;
	; check if we are on same drive
	;	dx:cx = source
	;
	mov	ax, ss:[mousePos].P_x
	mov	ss:[lastMousePosition].P_x, ax
	mov	ax, ss:[mousePos].P_y
	mov	ss:[lastMousePosition].P_y, ax 
	;
	; get transfer item and process it
	;
	mov	bx, transferVMfile		; bx:ax = transfer item header
	mov	ax, transferVMblock
	mov	cx, ss:[manufacturer]
	mov	dx, CIF_FILES			; transfer format to get
	push	bp	
	call	ClipboardRequestItemFormat	; bx:ax = file list VM block
	pop	bp				; cx is true disk handle of src
						; dx is remote flag of source
	push	ax, bx				; save file list VM block
	mov	ax, cx				; ax is true dishandle of src
	mov	bx, dx				; bx is remote flag of source
	mov	cx, ss:[mousePos].P_x
	mov	dx, ss:[mousePos].P_y		; cx, dx are mouse coords
	DerefFolderObject	ds, si, di

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

	mov	di, ax
	pop	ax, bx				; restore file list VM block

	cmp	di, CQTF_CLEAR
	je	done

if GPC_DRAG_SOUND
	call	UtilDragSound
endif

	mov	cx, ss:[folderTransferFlags]
	cmp	di, CQTF_MOVE
	je	finishCompCheck			; if same, skip

	ornf	cx, mask FTF_SRC_DEST_DIFF_DISK

finishCompCheck:
	les	di, ss:[destFile]		; es:di = dest. file/folder
	mov	dx, ss:[UIFAFlags]		; dx = UIFA flags
	call	ProcessDragFileListItem

done:
	call	FolderUnlockBuffer

doneNoLock:
	;
	; tell UI we are done
	;
	mov	bx, ss:[transferVMfile]		; bx:ax = transfer item header
	mov	ax, ss:[transferVMblock]
	call	ClipboardDoneWithItem

	;
	; tell UI that quick-transfer is over
	;
	mov	cx, mask CQNF_NO_OPERATION	; item not accepted?
	test	ss:[folderTransferFlags], mask FTF_NO_OPERATION
	jnz	haveQNF				; yes
	test	ss:[folderTransferFlags], mask FTF_SRC_DEST_DIFF_DISK
	mov	cx, mask CQNF_MOVE		; assume same disk -> move
	jz	haveQNF
	mov	cx, mask CQNF_COPY		; else, diff disk -> copy
haveQNF:
	push	bp
	mov	bp, cx
	call	ClipboardEndQuickTransfer
	pop	bp

	mov	ax, mask MRF_PROCESSED
	.leave
	ret

if _NEWDESK
moveIcon:

BA <	call	UtilAreWeInEntryLevel?		; don't allow moving	>
BA <	jc	done				; icons in entry level	>

	push	cx, dx, di

	mov	bx, transferVMfile		; bx:ax = transfer item header
	mov	ax, transferVMblock
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_FILES			; transfer format to get
	push	bp
	call	ClipboardRequestItemFormat	; bx:ax = file list VM block
	pop	bp

	mov	cx, mousePos.P_x
	mov	dx, mousePos.P_y
	call	FolderRepositionIcons

	pop	cx, dx, di
	jmp	done

endif	; _NEWDESK

FolderEndMoveCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ProcessDragFileListItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	copy/move list of files

CALLED BY:	INTERNAL
			FolderEndMoveCopy

PASS:		*ds:si - instance data of destination folder object
		es:di - destination file/folder, or
			di = NIL if none.

		bx:ax - (VM file):(VM block) of file list

		cx - FolderTransferFlags
			FTF_SOURCE_IS_DEST
			FTF_DROP_ON_FILE
			FTF_DROP_ON_FOLDER
			FTF_SOURCE_NOT_IN
			FTF_DEST_NOT_IN
			FTF_SRC_DEST_DIFF_DISK

		dh - UIFA flags
			UIFA_COPY shl 8 - set if explicit copy
			UIFA_MOVE shl 8 - set if explicit move

RETURN:	

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/13/89		Initial version
	brianc	12/26/89	modified to allow dropping files into
					folder icons in a Folder Window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ProcessDragFileListItem	proc	near

dropOnFolderPathname	local	PathName
quickNotifyFlags	local	ClipboardQuickNotifyFlags

	class	FolderClass

	uses	ds, si
		
	.enter

EC <	cmp	di, NIL				>
EC <	je	afterCheck			>
EC <	push	ds, si				>
EC <	segmov	ds, es				>
EC <	mov	si, di				>
EC <	call	ECCheckFileOperationInfoEntry	>
EC <	pop	ds, si				>
EC <afterCheck:					>

	;
	; stuff UIFA flags into file list transfer block
	;
	call	StuffUIFAIntoFileList

	mov	ss:[quickNotifyFlags], mask CQNF_MOVE
	test	cx, mask FTF_SRC_DEST_DIFF_DISK		; same disk?
	jz	gotFlags				; yes, move
	mov	ss:[quickNotifyFlags], mask CQNF_COPY	; else, copy

gotFlags:

	push	bx
	push	ax				; save VM block
	call	Folder_GetDiskAndPath
	mov_tr	dx, ax				; dx <- disk handle
	pop	ax				; recover VM block
	;
	; get destination pathname - depends on drop location
	;
	test	cx, mask FTF_DROP_ON_FOLDER	; drop on folder?
	jnz	dropOnFolder			; yes
	;
	; drop in background, copy directly to this folder
	;
	lea	si, ds:[bx].GFP_path		; ds:si = dest. pathname
	jmp	short gotDestPath
	;
	; drop onto folder icon, copy into specified folder
	;
dropOnFolder:
	push	ax				; save VM block
	push	es, di				; save dest. folder
	segmov	es, ss				; es:di = complete path buffer
	lea	di, ss:[dropOnFolderPathname]
	lea	si, ds:[bx].GFP_path		; ds:si = pathname
SBCS <	cmp	{char}ds:[si], 0					>
DBCS <	cmp	{wchar}ds:[si], 0					>
	je	prefixCopied
	call	CopyNullSlashString		; pathname + '\'
prefixCopied:
	pop	ds, si				; retrieve dest. folder
						; ds:si = FOIE
EC <	call	ECCheckFileOperationInfoEntry	>

ND<	mov	cx, ds:[si].FR_desktopInfo.DI_objectType ; cx = file's WOT >

CheckHack< offset FR_name eq 0>
	add	si, offset FR_name
	call	CopyNullTermString		; tack onto pathname
	segmov	ds, es, si			; ds:si = complete dest. path
	lea	si, ss:[dropOnFolderPathname]

ND<	cmp	cx, WOT_DRIVE	; cx holds the file's WOT from above	>
ND<	jne	notDriveLink						>
ND<	call	GetDrivesTruePath					>
ND<notDriveLink:							>

	pop	ax				; retrieve VM block
gotDestPath:
	pop	bx				; recover VM file
	clr	cx				; indicate bx:ax = VM block
if not _FCAB
	call	IsThisInTheWastebasket
	jnc	notTheWastebasket
	mov	{byte} ss:[usingWastebasket], WASTEBASKET_WINDOW
notTheWastebasket:
endif		; if (not _FCAB)

	push	bp
	mov	bp, ss:[quickNotifyFlags]
	call	ProcessDragFilesCommon		; pass: ds:si, bp, 
						; bx:ax, dx, cx
	pop	bp

	mov	{byte} ss:[usingWastebasket], NOT_THE_WASTEBASKET

	.leave
	ret
ProcessDragFileListItem	endp



if _NEWDESK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDrivesTruePath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the destination file is a drive link, make the destination
		path reflect the true path of the disk, not the path of the 
		link to the disk.

CALLED BY:	ProcessDragFileListItem

PASS:		ds:si - path of drive link
		dx    - diskhandle of drive link

RETURN:		ds:si - path of evaluated drive link (root of a drive)
		dx    - diskhandle of evauluated drive link

			On Error of the FileConstructActualPath,
				ds:si and dx
			will remain the original drive link.  Later
			evaluation will probably fail and the error 
			will be handled then appropriately, as this
			routine and its caller aren't equipt to do so.

DESTROYED:	nothing

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	7/23/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDrivesTruePath	proc	near
	uses	ax, bx, cx, es, di
	.enter

	;
	; Allocate a temporary path buffer on the heap because we already
	; have a path on the stack (passed in ds:si actually), and two paths
	; can get quite large (about .5k).
	;
	call	ShellAllocPathBuffer

	;
	; Construct the actual path into the temp buffer
	;
	push	dx, si			; save orig. diskhandle and path ptr
	mov	bx, dx			; bx is diskhandle
	clr	dx			; no <drivename> requested
	mov	di, offset PB_path	; es:di is buffer
	mov	cx, size PathName
	call	FileConstructActualPath
	pop	dx, si			; restore orig. diskhandle and path ptr
	jc	errorNoCopy

	;
	; If there was no error, copy the new actual path back over the
	; original drive link path.  If there was an error, we stick with
	; the original drive link path.
	;
	mov	dx, bx			; put new diskhandle in dx
	segxchg	ds, es
	xchg	si, di			; swap buffer pointers
	mov	cx, (size PathName)/2
	rep	movsw			; copy actual path over original path
	sub	di, size PathName	; reset es:di to buffer's beginning
	segxchg	ds, es
	xchg	si, di			; swap buffers pointers back again.

errorNoCopy:
	call	ShellFreePathBuffer

	.leave
	ret
GetDrivesTruePath	endp
endif		; if _NEWDESK


if 0				;feedback is too radical

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderNotifyQuickTransferFeedback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	give user additional feedback about quick-transfer

CALLED BY:	MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK
		from Flow object

PASS:		bp - ClipboardQuickTransferFeedback

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderNotifyQuickTransferFeedback	method	dynamic FolderClass,
			MSG_META_CLIPBOARD_NOTIFY_QUICK_TRANSFER_FEEDBACK

	test	ss:[fileDragging], mask FDF_MOVECOPY	; doing quick-transfer?
	jz	done				; nope

	cmp	bp, CQTF_MOVE			; move?
	je	clearIcon			; yes, clear icon
	cmp	bp, CQTF_SET_DEFAULT		; uninteresting event?
	je	done				; yes, do nothing
	cmp	bp, CQTF_CLEAR_DEFAULT		; uninteresting event?
	je	done				; yes, do nothing
						; else, redraw it
	test	ds:[di].FOI_folderState, mask FOS_SRC_LIST_CLEARED
	jz	done				; already redrawn
	mov	dx, mask DFI_CLEAR or mask DFI_DRAW
	andnf	ds:[di].FOI_folderState, not mask FOS_SRC_LIST_CLEARED
	jmp	short haveDrawFlags

clearIcon:
	test	ds:[di].FOI_folderState, mask FOS_SRC_LIST_CLEARED
	jnz	done				; already cleared
	mov	dx, mask DFI_CLEAR		; clear icon
	ornf	ds:[di].FOI_folderState, mask FOS_SRC_LIST_CLEARED

haveDrawFlags:
	mov	di, ss:[fileToMoveCopy]		; check if fileToMoveCopy
						;	in select list

	call	FolderLockBuffer
	test	es:[di].FR_state, mask FRSF_SELECTED
	jnz	useSelectList			; selected, use select list
						; else not selected, use file
	mov	ax, dx				; ax = draw flags
	call	ExposeFolderObjectIcon
	jmp	short afterDraw

useSelectList:
	call	FixSelectList

afterDraw:
	call	FolderUnlockBuffer
done:
	ret
FolderNotifyQuickTransferFeedback	endm

endif				; if 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderOpenIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens the icon whose name matches the name that is passed in

CALLED BY:	MSG_FOLDER_OPEN_ICON
PASS:		*ds:si	= FolderClass object
		ds:di	= FolderClass instance data
		ds:bx	= FolderClass object (same as *ds:si)
		es 	= segment of FolderClass
		ax	= message #
		cx:dx	= fptr to name buffer
RETURN:		if carry clear
			ax	= GeosFileType of object opened
			^lcx:dx	= FolderClass object if ax == GFT_DIRECTORY
		if carry set
			error
DESTROYED:	bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
 	JS	12/16/92   	Parts copied from Allen Yuen's Open Roster code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderOpenIcon	method dynamic FolderClass, MSG_FOLDER_OPEN_ICON

fptrToName	local	fptr		push	cx, dx
folderObject	local	fptr		push	ds, si

	.enter

		call	FolderLockBuffer ; return bx = hptr, es = sptr, ZF
		jnz	lockedBuffer
		stc				; exit with error
		jmp	short done

lockedBuffer:
		mov	cx, ds:[di].FOI_fileCount
		mov	di, offset FBH_buffer
		lds	si, fptrToName

objectLoop:
		CheckHack <FR_name eq 0>
		push	si, di, cx
		clr	cx
		call	LocalCmpStrings
		pop	si, di, cx
		
		je	found
		add	di, size FolderRecord
		loop	objectLoop

		lds	si, ss:[folderObject]
		stc
		jmp	short unlock

found:
		push	bp
		lds	si, ss:[folderObject]
		call	FileOpenESDI 	; carry flag is preserved through ret
		pop	bp

		mov	ax, es:[di].FR_fileType	; return GeosFileType
unlock:
		call	FolderUnlockBuffer
done:
		.leave
		ret
FolderOpenIcon	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderBringUpHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	redirect help request to app object

CALLED BY:	MSG_META_BRING_UP_HELP

PASS:		*ds:si	= FolderClass object
		ds:di	= FolderClass instance data
		es 	= segment of FolderClass
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

if _GMGR

FolderBringUpHelp	method	dynamic	FolderClass, MSG_META_BRING_UP_HELP

	mov	bx, handle FileSystemDisplay
	mov	si, offset FileSystemDisplay
	clr	di
	GOTO	ObjMessage

FolderBringUpHelp	endm

endif

if _NEWDESK
FolderBringUpHelp	method	dynamic FolderClass, MSG_META_BRING_UP_HELP
	;
	; send to primary
	;
	mov	bx, ds:[di].FOI_windowBlock
	tst	bx				; if this is a dummy object
	jz	exit
	mov	si, FOLDER_WINDOW_OFFSET	; common offset
	call	ObjMessageNone
exit:
	ret
FolderBringUpHelp	endm
endif

FolderAction	ends
FolderObscure	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderQuitQuickTransfer
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
	brianc	03/13/91	Updated for 2.0 quick-transfer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if not _PEN_BASED
FolderQuitQuickTransfer	method	FolderClass, MSG_META_CONTENT_VIEW_CLOSING,
						MSG_FOLDER_QUIT_QUICK_TRANSFER
else
FolderQuitQuickTransfer	method	FolderClass, MSG_META_CONTENT_VIEW_CLOSING,
						MSG_FOLDER_QUIT_QUICK_TRANSFER,
						MSG_META_LOST_SYS_FOCUS_EXCL
endif
	;
	; end direct manipulation
	;
						; dragging in progress?
	test	ss:[fileDragging], mask FDF_MOVECOPY
	pushf					; save results
						; done file dragging
	andnf	ss:[fileDragging], not (mask FDF_MOVECOPY)
	popf					; dragging in progress?
	jz	noMoveCopy			; if not, do nothing
	call	ClipboardAbortQuickTransfer
	jmp	short done

noMoveCopy:
	call	ClearRegionIfNeeded
done:
	ret
FolderQuitQuickTransfer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUpdateDiskName
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update disk name instance data and update Folder Window
		header

CALLED BY:	MSG_UPDATE_DISK_NAME

PASS:		object stuff
		dx - disk handle with new name

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/05/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderUpdateDiskName	method	FolderClass, MSG_UPDATE_DISK_NAME
	;
	; See if the message applies to us (disk handle is our disk handle)
	; 
	call	Folder_GetDiskAndPath
	cmp	dx, ax				; us?
	jne	done				; => no

	;
	; Yes. Fetch the new name of the disk into our instance data.
	; 
	mov_tr	bx, ax
	DerefFolderObject	ds, si, di 
	add	di, offset FOI_diskInfo.DIS_name
	segmov	es, ds			; es:di <- buffer
	call	DiskGetVolumeName
	
	;
	; And go update our moniker/header
	; 
	mov	ax, MSG_FOLDER_SET_PRIMARY_MONIKER
	call	ObjCallInstanceNoLock
done:
	ret
FolderUpdateDiskName	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFolderParentPath
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Figure the parent directory of the passed folder

CALLED BY:	INTERNAL (FolderUpDir, FolderUpDirQT)
PASS:		*ds:si	= Folder object
		pathBuf	= buffer on stack
RETURN:		pathBuf filled with parent directory
		cx	= disk handle
		carry set if folder is already at root (pathBuf is also
			root)
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	1/29/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFolderParentPath	proc	far	pathBuf:PathName
		uses	es, di, si, bx
		class	FolderClass
		.enter
	;
	; Construct the full path in the passed buffer
	; 
		segmov	es, ss				; es:di = path buffer
		lea	di, ss:[pathBuf]
		mov	cx, size pathBuf
		mov	ax, ATTR_FOLDER_PATH_DATA
		mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
;		push	bp
;		clr	bp		; no drive specifier, please
;		call	GenPathConstructFullObjectPath
;		pop	bp
;must handle links:
		call	GenPathFetchDiskHandleAndDerefPath
EC <		tst	ax						>
EC <		ERROR_Z	PATH_BUFFER_TOO_SMALL				>
		lea	si, ds:[bx].GFP_path
		mov_tr	bx, ax
		clr	dx
		call	FileConstructActualPath
EC <		ERROR_C	PATH_BUFFER_TOO_SMALL				>
		LocalStrLength			; point es:di past null
		LocalPrevChar	esdi		; point at null
;end of change
	;
	; See if the thing is already the root directory.
	; 
		push	bx			; save disk handle for return

		cmp	{word} ss:[pathBuf][0], '\\' or (0 shl 8) ; root?
DBCS <		jne	notRoot						>
DBCS <		cmp	{wchar}ss:[pathBuf][2], 0			>
		stc				; assume so
		je	done			; yes, do nothing
DBCS <notRoot:								>
	;
	; Nope. ES:DI points to the null, so locate the backslash preceding it.
	; We use a scasb with DF set, but would like to have CX be number of
	; chars we need to examine, so figure that out first.
	; 
		lea	cx, ss:[pathBuf]	; cx <- start
SBCS <		sbb	cx, di			; cx <- negative of	>
DBCS <		sub	cx, di			; cx <- negative of	>
						;  length w/null (carry still
						;  set from above)
		neg	cx			; cx <- length of path w/null
DBCS <		shr	cx, 1						>
DBCS <		inc	cx			; cx <- length of path w/null>
	;
	; Now locate the most-recent backslash.
	; 
		LocalLoadChar ax, C_BACKSLASH
		std
		LocalFindChar 			; find parent
		cld
EC <		ERROR_NZ	PATH_WITH_NO_SLASH	; no slash?!?	>
		LocalNextChar esdi		; point at slash
		tst	cx			; will be root?
		jnz	truncate		; no (not all chars searched)
		LocalNextChar esdi		; leave '\\' for root
truncate:
SBCS <		clr	al						>
DBCS <		clr	ax						>
		LocalPutChar esdi, ax		; null-terminate here	>
		clc				; flag not root before
done:
		pop	cx			; return cx = disk handle
		.leave
		ret
GetFolderParentPath	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderUpDir
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this Folder Window and open its parent (if this is
		not the root - MSG_FOLDER_UP_DIR of root Folder Window
		just closes it).  If parent is already opened, brings it to
		front.

CALLED BY:	MSG_FOLDER_UP_DIR

PASS:		usual object stuff

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
FolderUpDir	method	FolderClass, MSG_FOLDER_UP_DIR
if _FCAB
	call	Folder_GetDiskAndPath
	cmp	ax, SP_DOCUMENT			; in document?
	jne	doIt				; no, so ok
	cmp	{word}ds:[bx].GFP_path, '\\' or (0 shl 8)	; root of
DBCS <	jne	doIt							>
DBCS <	cmp	{wchar}ds:[bx].GDP_path[2], 0				>
								;  document?
	je	exit				; yes -- go nowhere
doIt:
endif		; if _FCAB
	;
	; get parent directory name, if root do nothing
	;
	sub	sp, PATH_BUFFER_SIZE		; allocate path buffer on stack
	call	GetFolderParentPath
	jc	done				; => was root, so do nothing

	;
	; Parse the beast down to a standard path, if appropriate, as that's
	; what the extant folder will have, if it's indeed extant...
	; 
	mov	bx, cx				; bx <- disk handle
	segmov	es, ss
	mov	di, sp				; es:di <- path to parse
	call	FileParseStandardPath
	tst	ax
	jz	createNew			; => use disk handle in bx
	mov_tr	bx, ax				; bx <- std path, es:di = tail
createNew:
	mov	dx, es				; dx:bp <- path to check
	mov	bp, di

if GPC_FOLDER_DIR_TOOLS
	sub	sp, (size FolderRecord) + 1
	segmov	es, ss
	mov	di, sp
	mov	es:[di].FR_desktopInfo.DI_objectType, WOT_FOLDER
	call	InheritAndCreateNewFolderWindow
	add	sp, (size FolderRecord) + 1
else
	call	InheritAndCreateNewFolderWindow
endif
done:
	add	sp, PATH_BUFFER_SIZE		; free stack buffer

FC<exit:					>
	ret
FolderUpDir	endm



if 0		; don't track floppy-out status - 4/6/90

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderRemovedFloppy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this folder window represents a floppy disk, then
		show that floppy's volume name in the window header.
		Called when that floppy is removed from its drive.

CALLED BY:	MSG_REMOVED_FLOPPY

PASS:		ds:si = Folder Object instance handle
		ax = MSG_REMOVED_FLOPPY
		dx:bp = floppy entry for removed floppy

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderRemovedFloppy	method	dynamic FolderClass, MSG_REMOVED_FLOPPY


	;
	; check if this Folder Window's floppy is already out
	;
	test	ds:[di].FOI_folderState, mask FOS_FLOPPY_OUT
	jnz	done				; if so, no change
	;
	; check if we need to do this nonsense; if non-removable media,
	; we don't need to
	;
	mov	bx, ds:[di].FOI_diskInfo.DIS_diskHandle
	call	DiskHandleGetDrive		; al = drive letter
	call	DriveGetStatus			; ah = drive status
	test	ah, mask DS_MEDIA_REMOVABLE	; is it removable media?
	jz	done				; no, done
	;
	; check if this Folder Window's floppy (removable media) was removed
	;
	mov	es, dx				; es:di = volume name removed
	push	si, di
	lea	si, ds:[di].FOI_diskInfo.DIS_volumeName
	mov	di, bp
	add	di, offset FTE_diskInfo.DIS_volumeName
						; ds:si = our volume name
	
	call	CompareString			; same?

	pop	si, di
	jne	done				; no, floppy not removed
	tst	ds:[di].FOI_diskInfo.DIS_volumeName	; both names null?
	jne	continue			; no, continue
						; else, use disk handle for
						;	comparison
	mov	ax, ds:[di].FOI_diskInfo.DIS_diskHandle
	cmp	ax, es:[bp].FTE_diskInfo.DIS_diskHandle
	jne	done
continue:
	;
	; our floppy has been removed!  change volume name in header
	;
	ornf	ds:[di].FOI_folderState, mask FOS_FLOPPY_OUT	; mark it

	mov	ax, MSG_FOLDER_SET_PRIMARY_MONIKER
	call	ObjCallInstanceNoLock
done:
	ret
FolderRemovedFloppy	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderInsertedFloppy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this folder window represents a floppy disk, then
		restore that floppy's pathname in the window header.
		Called when that floppy is re-inserted into a drive.

CALLED BY:	MSG_INSERTED_FLOPPY

PASS:		ds:si = Folder Object instance handle
		ax = MSG_INSERTED_FLOPPY
		dx:bp = floppy table entry of floppy inserted into drive

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderInsertedFloppy	method	dynamic FolderClass, MSG_INSERTED_FLOPPY

	;
	; check if this Folder Window's floppy is out
	;
	test	ds:[di].FOI_folderState, mask FOS_FLOPPY_OUT
	jz	done				; if not, can't be inserted
	;
	; check if we need to do this nonsense; if non-removable media,
	; we don't need to
	;
	mov	bx, ds:[di].FOI_diskInfo.DIS_diskHandle
	call	DiskHandleGetDrive		; al = drive number
	call	DriveGetStatus			; ah = drive status
	test	ah, mask DS_MEDIA_REMOVABLE	; is it removable media?
	jz	done				; no, done
	;
	; check if this Folder Window's floppy (removable media) was inserted
	;
	push	si, di
	lea	si, ds:[di].FOI_diskInfo.DIS_volumeName

	mov	es, dx				; es:di = volume name inserted
	lea	di, es:[bp].FTE_diskInfo.DIS_volumeName
						; ds:si = our volume name
	call	CompareString			; same?
	pop	si, di
	jne	done				; no, our floppy not inserted
	;
	; our floppy was inserted!  restore volume name in header
	;
	andnf	ds:[di].FOI_folderState, not (mask FOS_FLOPPY_OUT)	; mark

	mov	ax, MSG_FOLDER_SET_PRIMARY_MONIKER
	call	ObjCallInstanceNoLock
done:
	ret
FolderInsertedFloppy	endm

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderGetDiskInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	return disk info for this instance of Folder Class

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
FolderGetDiskInfo	method	FolderClass, MSG_GET_DISK_INFO
	call	Folder_GetDiskAndPath
	mov	si, ds:[si]			; deref.
	add	si, offset FOI_diskInfo
	mov	es, dx
	mov	di, bp
	mov	cx, size DiskInfoStruct
	rep movsb
	ret
FolderGetDiskInfo	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close the folder window for this folder object

CALLED BY:	MSG_CLOSE_FOLDER_WIN
		this is sent when updating after a file operation
		requires closing a folder window

PASS:		ds:si - instance handle of Folder object

RETURN:		folder window closed

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/12/89		Initial version
	brianc	10/26/89	do FolderWinDeath stuff explicitly instead
					of calling FolderWinDeath
					(avoids calling superclass)
	brianc	12/15/89	MSG_GEN_CLOSE_INTERACTION
	dlitwin	11/14/92	added Dummy check

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseWin	method	dynamic FolderClass, MSG_CLOSE_FOLDER_WIN

	mov	bx, ds:[di].FOI_windowBlock
	tst	bx				; if this is a dummy object
	jz	exit				; don't close it

	mov	si, FOLDER_WINDOW_OFFSET	; common offset
	mov	ax, MSG_GEN_DISPLAY_CLOSE
	call	ObjMessageNone
exit:
	ret
FolderCloseWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseIfMatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this Folder Window if it is for the disk specified
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
	brianc	04/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseIfMatch	method	FolderClass, MSG_CLOSE_IF_MATCH
	call	Folder_GetDiskAndPath
	cmp	ax, dx
	jne	done				; no match
	mov	ax, MSG_CLOSE_FOLDER_WIN
	call	ObjCallInstanceNoLock
done:
	ret
FolderCloseIfMatch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseIfGone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this Folder Window if the directory it shows is no
		longer around.  If it is still around, it rescans it.

CALLED BY:	MSG_CLOSE_IF_GONE

PASS:		ds:*si - Folder Window object
		ds:bx - Folder Window instance

RETURN:		Folder Window closed if ...

DESTROYED:	

PSEUDO CODE/STRATEGY:
       		this used to rescan if the path still existed, but that's
		handled by file-change notification, and MarkWindowsForUpdate
		sends this message out excessively anyway, so don't bother.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	05/31/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseIfGone	method	FolderClass, MSG_CLOSE_IF_GONE
	call	FilePushDir			; save current dir
	mov	ax, ATTR_FOLDER_PATH_DATA
	mov	dx, TEMP_FOLDER_SAVED_DISK_HANDLE
	call	GenPathSetCurrentPathFromObjectPath
	jnc	done				; no error
	mov	ax, MSG_CLOSE_FOLDER_WIN	; else, close
	call	ObjCallInstanceNoLock
done:
	call	FilePopDir			; restore current dir
	ret
FolderCloseIfGone	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseIfDrive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Close this Folder Window if the passed drive matches drive
		of disk we are showing.

CALLED BY:	MSG_CLOSE_IF_DRIVE

PASS:		ds:*si - Folder Window object
		ds:bx - Folder Window instance

		cl - drive number

RETURN:		Folder Window closed if ...

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	07/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseIfDrive	method	dynamic	FolderClass, MSG_CLOSE_IF_DRIVE
	mov	ax, TEMP_FOLDER_DRIVE
	call	ObjVarFindData
	jnc	done				; not found?
	cmp	cl, {byte} ds:[bx]
	jne	done				; no match

	; 10/7/93: don't close if there are two or more path IDs for the
	; folder (three, if logical and actual are different) -- ardeb
	
	call	FolderCompareActualAndLogicalPaths
	mov	dx, 2 * size FilePathID
	je	checkNumIDs
	mov	dx, 3 * size FilePathID

checkNumIDs:
	mov	ax, TEMP_FOLDER_PATH_IDS
	call	ObjVarFindData
	jnc	closeIt				; not found, so close (why not?)
	
	VarDataSizePtr	ds, bx, cx
	cmp	cx, dx
	jae	done

closeIt:
	mov	ax, MSG_CLOSE_FOLDER_WIN	; else, close
	call	ObjCallInstanceNoLock
done:
	ret
FolderCloseIfDrive	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderViewWinClosed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close up folder window - kill the various objects, free
		the various buffers, unhook window from application

CALLED BY:	MSG_META_CONTENT_VIEW_WIN_CLOSED
		this method is sent when shutting down desktop AND when
			user clicks in pushpin in folder window header
			AND when we manually close folder windows after
			a file operation that makes the window invalid
			AND when iconifying

PASS:		ds:si - Folder object instance handle
		bp - window

RETURN:

DESTROYED:	

PSEUDO CODE/STRATEGY:
		case:
			(pushpin):
			(manual close):
				free buffers in folder object;
				remove folder object from global folder list;
				call superclass to do stuff;
				unhook folder object from application & free it;
			(shutdown):
				free buffers in folder object;
				remove folder object from global folder list;
				call superclass to do stuff;
			(iconify):
				call superclass to do stuff;

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/12/89		Initial version
	brianc	10/13/89	modified for shutting down
	brianc	10/26/89	manual close check
	brianc	12/15/89	completely re-organized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderViewWinClosed	method	dynamic FolderClass,
				MSG_META_CONTENT_VIEW_WIN_CLOSED
	uses	ax, bp
	.enter

	;
	; If the entire file manager is closing (F3) this is the only
	; chance we'll get to save icon positions!  Otherwise, some
	; other routine has already freed the buffer of FolderRecords
	; (and hopefully saved the icon positions), so don't do it
	; here.  -martin
	;
ND <	tst	ds:[di].FOI_buffer					>
ND <	jz	closeOnly						>
ND <	mov	ax, MSG_FOLDER_SAVE_ICON_POSITIONS			>
ND <	call	ObjCallInstanceNoLock 					>
ND <closeOnly:								>
						
	andnf	ds:[di].FOI_folderState, not (mask FOS_TARGET or mask FOS_FOCUS)
						; manual closing or pushpin?
	cmp	ss:[exitFlag], 1		; shutdown?
	jne	callSuper			; no

	call	FreeFolderBuffers
	call	FolderCloseNotifyDesktop

callSuper:
	.leave
	mov	di, offset FolderClass
	GOTO	ObjCallSuperNoLock
FolderViewWinClosed	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the folder from the GCN lists on which it should
		not remain

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= Folder object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	11/12/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderDetach	method dynamic FolderClass, MSG_META_DETACH
	uses	ax, cx, dx, bp	; save for superclass
	.enter
	call	UtilRemoveFromFileChangeList
	.leave
	mov	di, offset FolderClass
	GOTO	ObjCallSuperNoLock
FolderDetach		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	close up folder window - kill the various objects, free
		the various buffers, unhook window from application

CALLED BY:	MSG_FOLDER_CLOSE
		this message is sent from the Folder Window GenDisplay when it
		receives MSG_GEN_DISPLAY_CLOSE.

PASS:		*ds:si - Folder object

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/03/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderClose	method	dynamic FolderClass, MSG_FOLDER_CLOSE, 
					MSG_CLOSE_FOR_BAD_CREATE
		
	;
	; update numFiles
	;
	mov	ax, ds:[di].FOI_fileCount
	mov	bx, ss:[numFiles]
	sub	bx, ax
	jnc	setNumFiles

	; if bx < 0 => bx := 0
	clr	bx

setNumFiles:
	mov	ss:[numFiles], bx	

if _NEWDESK
	mov	ax, MSG_FOLDER_SAVE_ICON_POSITIONS
	call	ObjCallInstanceNoLock
	mov	di, ds:[si]
endif

	;
	; Remove ourselves from the filesystem change notification list, if
	; we're there.
	; 
	call	UtilRemoveFromFileChangeList

	call	FreeFolderBuffers
	call	FolderCloseNotifyDesktop
	call	DestroyFolderObject
if _NEWDESK
	;
	; Release the focus and target from our app object so when we send
	; MSG_META_ENSURE_ACTIVE_FT to our app object's parent, it can decide
	; for itself whether we should retain the sys focus/target or if
	; some other app that is now above all our folder windows should
	; get them.
	; 
	mov	ax, MSG_META_RELEASE_FOCUS_EXCL
	mov	bx, handle Desktop
	mov	si, offset Desktop
	call	ObjMessageCall

	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	ObjMessageCall

	;
	; Send MSG_META_ENSURE_ACTIVE_FT to the field above our 
	; application obj.
	;

	push	bx, si				; save Desktop Object (AppObj)
	mov	ax, MSG_META_ENSURE_ACTIVE_FT
	mov	bx, segment GenFieldClass
	mov	si, offset GenFieldClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di				; move classed event into cx
	pop	bx, si				; restore Desktop Object
	mov	ax, MSG_GEN_GUP_SEND_TO_OBJECT_OF_CLASS
	call	ObjMessageCall

endif		; if _NEWDESK

	ret
FolderClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeFolderBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clean up instance data of folder object

CALLED BY:	INTERNAL

PASS:		*ds:si - FolderClass object 

RETURN:		preserves ds:si

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeFolderBuffers	proc	near
	class	FolderClass

	DerefFolderObject	ds, si, di 
	mov	ds:[di].FOI_selectList, NIL	; clear lists, in case
	mov	ds:[di].FOI_displayList, NIL	;	other methods come in!!
	mov	ds:[di].FOI_cursor, NIL
	clr	ds:[di].FOI_fileCount
	clr	bx
	xchg	bx, ds:[di].FOI_buffer		; get folder buffer
	tst	bx
	jz	done
	call	MemFree				; free it!! yeah!!
done:
	ret
FreeFolderBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderCloseNotifyDesktop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	removes folder from global folder list

CALLED BY:	INTERNAL

PASS:		*ds:si - Folder object

RETURN:		nothing 

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderCloseNotifyDesktop	proc	near
	uses	di, bx
	.enter

	mov	ax, MSG_DESKTOP_FOLDER_CLOSING
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	mov	bx, handle 0
	call	ObjMessageFixup
 
	.leave
	ret
FolderCloseNotifyDesktop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyFolderObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	destroys folder object and associated folder window object,
		unhooking it from application

CALLED BY:	FolderClose

PASS:		*ds:si - FolderClass object

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DestroyFolderObject	proc	near
	class	FolderClass
	;
	; remove ourselves from Quick Transfer notification
	;
	mov	bx, ds:[LMBH_handle]		; bx:di = notification OD
	mov	di, si
	call	ClipboardClearQuickTransferNotification

	;
	; Remove the primary from the generic tree.  If there is no
	; window block, then just bail, as we may get this message
	; multiple times  
	;

	DerefFolderObject	ds, si, si
	clr	bx
	xchg	bx, ds:[si].FOI_windowBlock	; ^lbx:si - primary
	tst	bx
	jz	done

if GPC_FOLDER_WINDOW_MENUS
	call	NDUnhookWBOptionsMenuIfWastebasket
else
ND<	call	NDUnhookSortViewMenu		>
endif

	mov	si, FOLDER_WINDOW_OFFSET

	mov	ax, MSG_GEN_REMOVE
	mov	bp, mask CCF_MARK_DIRTY
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup

	;
	; remove obj block output of window block
	;
	clr	cx, dx
	mov	ax, MSG_META_SET_OBJ_BLOCK_OUTPUT
	call	ObjMessageCallFixup

	;
	; free folder window block
	;

	mov	ax, MSG_META_BLOCK_FREE
	call	ObjMessageCallFixup

	;
	; free folder object block
	;

	mov	si, FOLDER_OBJECT_OFFSET	; common offset
	mov	ax, MSG_META_BLOCK_FREE
	call	ObjCallInstanceNoLock 
done:
	ret

DestroyFolderObject	endp



if _NEWDESK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDUnhookSortViewMenu
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Unhooks the GlobalMenuSortAndView object from its parent.

CALLED BY:	DestroyFolderObject, DesktopDetach

PASS:		ds	= segment that can be fixup up
RETURN:		ds fixed up
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/25/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if GPC_FOLDER_WINDOW_MENUS

NDUnhookWBOptionsMenuIfWastebasket	proc	near
	mov	si, FOLDER_OBJECT_OFFSET	; *ds:si = folder object
	mov	cx, segment NDWastebasketClass
	mov	dx, offset NDWastebasketClass
	mov	ax, MSG_META_IS_OBJECT_IN_CLASS
	call	ObjCallInstanceNoLock	; C set if so
	jnc	done
	call	NDUnhookWBOptionsMenu
done:
	ret
NDUnhookWBOptionsMenuIfWastebasket	endp

NDUnhookWBOptionsMenu	proc	far
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	mov	ax, MSG_GEN_FIND_PARENT
	mov	bx, handle OptionsMenu
	mov	si, offset OptionsMenu
	call	ObjMessageCallFixup
	jcxz	exit

	push	cx, dx
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	bx, handle OptionsMenu
	mov	si, offset OptionsMenu
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup

	mov	ax, MSG_GEN_REMOVE_CHILD
	pop	cx, dx			; parent is in cx:dx, child in bx:si
	xchg	bx, cx			;    swap them so:
	xchg	si, dx			; child in cx:dx, parent in bx:si
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessageCallFixup

exit:
	.leave
	ret
NDUnhookWBOptionsMenu	endp

else

NDUnhookSortViewMenu	proc	far
	uses	ax, bx, cx, dx, bp, di, si
	.enter

	mov	ax, MSG_GEN_FIND_PARENT
	mov	bx, handle GlobalMenuSortAndView
	mov	si, offset GlobalMenuSortAndView
	call	ObjMessageCallFixup
	jcxz	exit

	push	cx, dx
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	bx, handle GlobalMenuSortAndView
	mov	si, offset GlobalMenuSortAndView
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	ObjMessageCallFixup
	and	ss:[globalMenuState].GMB_low, not mask GMBL_SORT

	mov	ax, MSG_GEN_REMOVE_CHILD
	pop	cx, dx			; parent is in cx:dx, child in bx:si
	xchg	bx, cx			;    swap them so:
	xchg	si, dx			; child in cx:dx, parent in bx:si
	mov	bp, mask CCF_MARK_DIRTY
	call	ObjMessageCallFixup

exit:
	.leave
	ret
NDUnhookSortViewMenu	endp
endif	; GPC_FOLDER_WINDOW_MENUS
endif		; if _NEWDESK




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetDisplayOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set new file display options for folder window OR for
		default folder object

CALLED BY:	MSG_SET_DISPLAY_OPTIONS

PASS:		*ds:si - FolderClass object
		cl - file types to display
		ch - file attributes to display
		dl - sort field
		dh - display modes

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di, es

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/10/89		Initial version
	brianc	11/10/89	added default support
	martin	7/29/92		added support for flexible placement of icons

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef SMARTFOLDERS
FolderRestoreDisplayOptions	method	dynamic FolderClass, MSG_RESTORE_DISPLAY_OPTIONS
	ornf	ds:[di].FOI_positionFlags, mask FIPF_RESTORE_OPTS
	mov	ax, MSG_SET_DISPLAY_OPTIONS
	call	ObjCallInstanceNoLock
	ret
FolderRestoreDisplayOptions	endm
endif

FolderSetDisplayOptions	method	dynamic FolderClass, MSG_SET_DISPLAY_OPTIONS
	.enter

if _NEWDESK

	;
	; If the folder is positioned, or dirty, then allow this
	; through.  To make this work, we'll have to store something
	; bogus in the existing "sort" field.
	;

	test	ds:[di].FOI_positionFlags, mask FIPF_POSITIONED
	jz	checkDiffs
ifdef SMARTFOLDERS
	test	ds:[di].FOI_positionFlags, mask FIPF_RESTORE_OPTS
	jz	reSort
	andnf	ds:[di].FOI_positionFlags, not mask FIPF_RESTORE_OPTS
	jmp	short checkDiffs
		
reSort:
endif
	mov	ds:[di].FOI_displaySort, -1
checkDiffs:

endif

	;
	; check if new display options are same as current ones
	;

	cmp	ds:[di].FOI_displayTypes, cl
	jne	different			; if different, change 'em
	cmp	ds:[di].FOI_displayAttrs, ch
	jne	different			; if different, change 'em
	cmp	ds:[di].FOI_displaySort, dl
	jne	different			; if different, change 'em
	cmp	ds:[di].FOI_displayMode, dh
	LONG je	done			; if all same, do nothing

different:
	;
	; new display options are different, use them
	;
	mov	ax, cx				; ax, bx = new display options
	mov	bx, dx
	xchg	ds:[di].FOI_displayTypes, cl	; save new info
	xchg	ds:[di].FOI_displayAttrs, ch
	xchg	ds:[di].FOI_displaySort, dl
	xchg	ds:[di].FOI_displayMode, dh	; cx, dx = old display options
	;
	; 	build new display list using new info
	;
	;
	; first, determine if we need to re-sort the file list
	; we do if we changed sort field, or if the list of files
	; changed (more or less files showing)
	;	- display types (cl, al) can't be changed by user
	;	- display mode (dh, bh) change requires re-sort
	;	- display sort (dl, bl) change requires re-sort
	;	- display attr change (ch, ah) (except compressed)
	;		requires re-sort
	;
	cmp	dl, bl				; sort change requires re-sort
	jne	sort
	cmp	ch, ah				; check attrs
	je	noSort			; if no change, no re-sort
	andnf	ch, not mask FIDA_COMPRESSED
	andnf	ah, not mask FIDA_COMPRESSED
	cmp	ch, ah				; actual attr change?
	je	noSort				; yes, re-sort needed
						; else, compressed change, no
						;	re-sort needed
sort:
	BitClr	ds:[di].FOI_positionFlags, FIPF_POSITIONED	
	mov	ax, TRUE			; assume sort needed
	jmp	preSort

noSort:
	mov	ax, FALSE			; else, no sort

preSort:
	;
	; now decide whether the view mode has been changed:
	;	names -> icon	load position info
	;	icon  -> names	save position info
	;


	cmp	bh, dh
	je	continueBuild
	test	dh, mask FIDM_LICON
	jnz	saveIconPositions
	test	bh, mask FIDM_LICON
	jz	positionGeoManagerStyle
	call	FolderLoadDirInfo
ifdef SMARTFOLDERS
	;
	; if no data loaded from dir info file, position normally
	;
	test	ds:[di].FOI_positionFlags, mask FIPF_POSITIONED
	jz	positionGeoManagerStyle
endif
	jmp	noError


saveIconPositions:
	push	ax
	mov	ax, MSG_FOLDER_SAVE_ICON_POSITIONS
	call	ObjCallInstanceNoLock
	pop	ax

positionGeoManagerStyle:

	BitClr	ds:[di].FOI_positionFlags, FIPF_POSITIONED	
	

continueBuild:
	;
	; Suspend visual updates, and unsuspend them via the queue,
	; since, in certain cases, an exposed event will come in
	; before we've received MSG_META_CONTENT_VIEW_SIZE_CHANGED
	;
	push	ax
	mov	ax, MSG_GEN_VIEW_SUSPEND_UPDATE
	clr	di
	call	FolderCallView
	pop	ax

	call	BuildDisplayList

	pushf
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_FOLDER_UNSUSPEND_WINDOW
	call	ObjMessageForce		
	popf

	jnc	noError				; if no error, continue

	mov	ax, ERROR_INSUFFICIENT_MEMORY	; else, report error
	call	DesktopOKError

	call	FolderSendCloseViaQueue		; ...and close Folder Window
	jmp	done

noError:
	DerefFolderObject	ds, si, di
	BitSet	ds:[di].FOI_positionFlags, FIPF_RECALC
	call	ObjMarkDirty			; new display options -> dirty

if GPC_NAMES_AND_DETAILS_TITLES
	;
	; set usability of titles for names and details mode
	;
if not _DOCMGR
.assert (offset NDFolderTitles) eq (offset NDDriveTitles)
.assert (offset NDFolderTitles) eq (offset NDWastebasketTitles)
endif
	DerefFolderObject	ds, si, si
if not _DOCMGR
	.warn -private
	cmp	ds:[di].NDFOI_ndObjType, WOT_DESKTOP
	.warn @private
	je	noTitle
endif
	mov	ax, MSG_GEN_SET_NOT_USABLE
	test	ds:[di].FOI_displayMode, mask FIDM_FULL
	jz	notFull
	mov	ax, MSG_GEN_SET_USABLE
notFull:
	mov	dl, VUM_NOW
	mov	bx, ds:[di].FOI_windowBlock
	mov	si, offset NDFolderTitles
	call	ObjMessageCallFixup
noTitle:
endif
		
done:
	.leave
	ret
FolderSetDisplayOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSendCloseViaQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a close message to the folder on its queue, with the
		bogus flag set.

CALLED BY:	FolderDraw, FolderSetPath, FolderScan,
		FolderSetDisplayOptions, FolderRelocate

PASS:		*ds:si - FolderClass object

RETURN:		none

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	11/14/92	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSendCloseViaQueue	proc	far
	class	FolderClass

	uses	di, ax, bx

	.enter

	DerefFolderObject	ds, si, di
	ornf	ds:[di].FOI_folderState, mask FOS_BOGUS
	mov	ax, MSG_CLOSE_FOLDER_WIN
	mov	bx, ds:[LMBH_handle]		; bx:si = folder object
	call	ObjMessageForce

	.leave

	ret
FolderSendCloseViaQueue	endp


if not _FCAB

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	FolderSetViewMode, FolderSetSortMode, FolderSetViewOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	change to given mode

CALLED BY:	MSG_SET_VIEW_MODE
		MSG_SET_SORT_MODE
		MSG_SET_VIEW_OPTIONS

PASS:		ax = message
		MSG_SET_VIEW_MODE
		MSG_SET_SORT_MODE
			cx = identifier of exclusive
		MSG_SET_VIEW_OPTIONS
			cx = mask of selected booleans
			bp = mask of modified booleans

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/15/89		Initial version
	brianc	9/26/89		moved from Main/ module to Folder/ module
	brianc	12/15/89	support for all modes
	brianc	1/10/90		usability update
	brianc	4/21/92		new GenItem, GenBoolean

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSetViewMode	method	FolderClass, MSG_SET_VIEW_MODE
		clr	ax
		mov	bh, cl		; bh = FIDM_*
		clr	bl
		call	FolderSetDisplayCommon
		ret
FolderSetViewMode	endm

FolderSetSortMode	method	FolderClass, MSG_SET_SORT_MODE
		clr	ax
		mov	bx, cx			; bl = FIDS_*
		call	FolderSetDisplayCommon
		ret
FolderSetSortMode	endm

FolderSetViewOptions	method	FolderClass, MSG_SET_VIEW_OPTIONS
		mov	ax, bp			; ah = modified FIDA_*
		test	al, mask FIDA_HIDDEN
		jz	10$
		ornf	al, mask FIDA_SYSTEM
10$:
		xchg	al, ah		; view options -> ah
		clr	bx
		call	FolderSetDisplayCommon
		ret
FolderSetViewOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FolderSetDisplayCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the Display to the specified parameters

CALLED BY:	FolderSetViewMode, FolderSetSortMode, FolderSetViewOptions

PASS:		al = FIDT_*
		ah = FIDA_*
		bl = FIDS_*
		bh = FIDM_*

RETURN:		none
DESTROYED:	all

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	3/23/93    	Added header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FolderSetDisplayCommon	proc	near
	.enter
	push	ax				; save bits to change
	mov	ax, MSG_GET_DISPLAY_OPTIONS
	call	ObjCallInstanceNoLock		; cx, dx - current display
						;		options
	pop	ax				; retrieve bits to change

	tst	al			; do types - exclusive (DATAs or ALL)
	jz	10$
	mov	cl, al				; use new bit
	jmp	short sendBits
10$:
	tst	ah			; do attrs - nonExclusive
	jz	20$
	xor	ch, ah				; TOGGLE bit
	jmp	short sendBits
20$:
	tst	bl			; do sort - exclusive
	jz	30$
	mov	dl, bl
	jmp	short sendBits
30$:
	tst	bh			; do mode - exclusive
EC <	ERROR_Z	BUILD_DISPLAY_LIST_NO_DISPLAY_MODE			>
	mov	dh, bh
sendBits:
	mov	ax, MSG_SET_DISPLAY_OPTIONS	; set new display options
	call	ObjCallInstanceNoLock		; pass display options (CX,DX)
	mov	ax, MSG_REDRAW		; redraw to show new mode
	call	ObjCallInstanceNoLock
	mov	ax, MSG_SEND_DISPLAY_OPTIONS
	call	ObjCallInstanceNoLock		; update dialog box
	.leave
	ret
FolderSetDisplayCommon	endp
endif		; if (not _FCAB)

FolderObscure	ends
