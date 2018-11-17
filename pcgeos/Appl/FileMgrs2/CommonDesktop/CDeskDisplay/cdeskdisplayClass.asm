COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1988 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Desktop/DeskDisplay
FILE:		deskdisplayClass.asm
AUTHOR:		Brian Chin

ROUTINES:
	EXT	DeskDisplayGenCloseInteraciton

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/89		Initial version

DESCRIPTION:
	This file contains the desktop GenDisplay object.

	$Id: cdeskdisplayClass.asm,v 1.1 97/04/04 15:02:58 newdeal Exp $

------------------------------------------------------------------------------@





PseudoResident segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	synopsis

CALLED BY:	MSG_META_RELOCATE

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
	brianc	01/02/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayRelocate	method	DeskDisplayClass, reloc
	cmp	ax, MSG_META_RELOCATE		; relocating?
	jne	done				; nope
	mov	ds:[di].DDI_usage, 0		; clear usage count
done:
	mov	di, offset DeskDisplayClass
	call	ObjRelocOrUnRelocSuper
	ret
DeskDisplayRelocate	endm

ifndef GEOLAUNCHER


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayFindKbdAccelerator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the up-directory button for this display is not enabled
		(because this is root), stop the MSG_GEN_FIND_KBD_ACCELERATOR
		search.

CALLED BY:	MSG_META_RELOCATE

PASS:		*ds:si - instance data
		ds:di - DeskDisplay instance data
		es - segment of class
		ax - MSG_GEN_FIND_KBD_ACCELERATOR

		same as MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		carry set if accelerator found and dealt with

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	02/04/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayFindKbdAccelerator	method	DeskDisplayClass, 
						MSG_GEN_FIND_KBD_ACCELERATOR
	;
	; Check if this is the accelerator for the up-directory button
	;
	push	ax, si
	mov	si, offset FolderUpButton	; *ds:si = up-dir button
	call	GenCheckKbdAccelerator
	pop	ax, si
	jnc	callSuper			; no, let superclass do normal
						;	handling
	;
	; This is an accelerator for the up-dir button, if that button is
	; disabled, then we want to eat this accelerator to prevent it from
	; going to another DeskDisplay and activating that up-dir button.
	;
	push	ax, si, cx, dx, bp
	mov	si, offset FolderUpButton	; *ds:si = up-dir button
	mov	ax, MSG_GEN_GET_ENABLED
	call	ObjCallInstanceNoLock		; carry set if enabled
	pop	ax, si, cx, dx, bp
	cmc					; carry clear if enabled
						; carry set if disabled
	jc	done				; yes, disabled, return
						;	accelerator found
	;
	; Button is not disabled, let superclass handle (will send to 
	; up-dir button normally).
	;
callSuper:
	mov	di, offset DeskDisplayClass	; else, let superclass do the
	call	ObjCallSuperNoLock		;	normal work
done:
	ret
DeskDisplayFindKbdAccelerator	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayGenCloseInteraction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set flag that we are doing USER initiated close

CALLED BY:	MSG_GEN_DISPLAY_CLOSE

PASS:		usual method stuff

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	12/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayGenCloseInteraction	method	DeskDisplayClass, MSG_GEN_DISPLAY_CLOSE
	mov	bx, ds:[LMBH_handle]
	;
	; check if tree
	;
if _GMGR and not _ZMGR
ifndef GEOLAUNCHER	; no Tree Window for GeoLauncher
if _TREE_MENU		
	cmp	bx, handle TreeWindow
	jne	folder					; no, folder
	mov	bx, handle TreeObject
	mov	si, offset TreeObject
	mov	ax, MSG_TREE_CLOSE
	call	ObjMessageFixup
	jmp	short done
folder:
endif		; if _TREE_MENU
endif		; ifndef GEOLAUNCHER
endif		; if _GMGR and not _ZMGR
	mov	ax, MSG_GEN_VIEW_GET_CONTENT
	mov	si, offset FolderWindowTemplate:FolderView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	mov	ax, MSG_FOLDER_CLOSE
	mov	bx, cx
	mov	si, dx
	call	ObjMessageFixup
if _GMGR and not _ZMGR
ifndef GEOLAUNCHER	; no Tree Window for GeoLauncher
if _TREE_MENU		
done:
endif		; if _TREE_MENU
endif		; ifndef GEOLAUNCHER
endif		; if _GMGR and not _ZMGR
	ret
DeskDisplayGenCloseInteraction	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplay{Get,Set}OpenState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get/set open state - indicates if Display was created
		in maximized or restored mode

CALLED BY:	MSG_{GET,SET}_OPEN_STATE

PASS:		object stuff
		cx - state (MSG_SET_OPEN_STATE)
			TRUE - opened in maximized mode
			FALSE - opened in restored mode

RETURN:		cx - state (MSG_GET_OPEN_STATE)
			TRUE - opened in maximized mode
			FALSE - opened in restored mode

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	04/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if CLOSE_IN_OVERLAP

DeskDisplayGetOpenState	method	DeskDisplayClass, \
					MSG_DESKDISPLAY_GET_OPEN_STATE
	mov	cx, ds:[di].DDI_openState
	ret
DeskDisplayGetOpenState	endm

DeskDisplaySetOpenState	method	DeskDisplayClass, \
					MSG_DESKDISPLAY_SET_OPEN_STATE
	mov	ds:[di].DDI_openState, cx
	call	ObjMarkDirty
	ret
DeskDisplaySetOpenState	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplaySetUsage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set usage count for this Window

CALLED BY:	MSG_DESKDISPLAY_SET_USAGE

PASS:		cx - usage count

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplaySetUsage	method	DeskDisplayClass, MSG_DESKDISPLAY_SET_USAGE
	mov	ds:[di].DDI_usage, cx
	ret
DeskDisplaySetUsage	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayCloseOldestCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if this Window is the current oldest

CALLED BY:	MSG_DESKDISPLAY_CLOSE_OLDEST_CHECK

PASS:		es - segment of class definition
		ds:di - DeskDisplayInstance

		dgroup variables:
		[oldestUsage] - current oldest usage count
		[oldestWindow] - optr of current oldest Window
		[closableCount] - number of closable Windows

RETURN:		carry set if this window should be closed
			(number of closable windows becomes more than
			 NUM_LRU_ENTRIES with this Window)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Desktop thread is blocked waiting for this to return,
		so we can access its variables safely.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/09/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayCloseOldestCheck	method	DeskDisplayClass, \
					MSG_DESKDISPLAY_CLOSE_OLDEST_CHECK
	cmp	ds:[di].DDI_openState, FALSE	; not closable?
	je	notClosable			; yes, carry clear
		
	;
	; Window is closable, check if older than current oldest
	;
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	ax, ds:[di].DDI_usage		; ax = this Window's usage
	cmp	ax, es:[windowUsageCount]	; just opened Window?
	je	notOlder			; yes, don't treat as potential
						;	oldest

	cmp	ax, es:[oldestUsage]		; older than oldest?
	jae	notOlder			; nope

	;
	; this Window is older than oldest, save its info
	;
	mov	es:[oldestUsage], ax		; save usage
	mov	ax, ds:[LMBH_handle]
	mov	es:[oldestWindow].handle, ax	; save optr
	mov	es:[oldestWindow].offset, si
	;
	; this Window can be closed, check if it brings us beyond threshold
	; number of Windows
	;
notOlder:
	inc	es:[closableCount]
	mov	al, es:[closableCount]
	mov	ah, es:[lruNumber]
	cmp	ah, al				; few enough Windows?
						; if so, carry clear, continue
						;	checking Windows
						; else, abort checking and
						;	close current oldest
						;	(carry set)
notClosable:
	ret
DeskDisplayCloseOldestCheck	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayCloseOldest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	like MSG_DESKDISPLAY_CLOSE_OLDEST_CHECK, but goes
		through all windows

CALLED BY:	MSG_DESKDISPLAY_CLOSE_OLDEST
PASS:		*ds:si	= DeskDisplayClass object
		ds:di	= DeskDisplayClass instance data
		ds:bx	= DeskDisplayClass object (same as *ds:si)
		es 	= segment of DeskDisplayClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	updates ss:[oldestWindow]

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayCloseOldest	method dynamic DeskDisplayClass, 
					MSG_DESKDISPLAY_CLOSE_OLDEST
	uses	ax, cx, dx, bp
	.enter

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>

	;
	; if the lruNumber == 1 just close the window that is open
	; right now
	;
	cmp	es:[lruNumber], 1
	je	setTheWindow

	;
	; Window is closable, check if older than current oldest
	;
	mov	ax, ds:[di].DDI_usage		; ax = this Window's usage
	cmp	ax, es:[windowUsageCount]	; just opened Window?
	je	notOlder			; yes, don't treat as potential
						;	oldest

	cmp	ax, es:[oldestUsage]		; older than oldest?
	jae	notOlder			; nope
	;
	; this Window is older than oldest, save its info
	;
setTheWindow:
	mov	es:[oldestUsage], ax		; save usage
	mov	ax, ds:[LMBH_handle]
	mov	es:[oldestWindow].handle, ax	; save optr
	mov	es:[oldestWindow].offset, si

	;
	; this Window can be closed, check if it brings us beyond threshold
	; number of Windows
	;
notOlder:
	;
	; carry clear mean that we're supposed tp go through all
	; windows
	;
	clc
	.leave
	ret
DeskDisplayCloseOldest	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayGroupCloseOldestCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle calling of children with
		MSG_DESKDISPLAY_CLOSE_OLDEST_CHECK

CALLED BY:	MSG_DESKDG_CLOSE_OLDEST_CHECK

PASS:		*ds:si - DeskDisplayGroupClass

RETURN:		carry set if found window to close
		carry clear if no window to close

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayGroupCloseOldestCheck	method	DeskDisplayGroupClass,
						MSG_DESKDG_CLOSE_OLDEST_CHECK
	clr	bx
	push	bx			; initial child (first child of comp.)
	push	bx
	mov	bx, offset GI_link	; pass offset to LinkPart
	push	bx
	clr	bx
	push	bx			; use canned callback routine
	mov	bx, OCCT_DONT_SAVE_PARAMS_TEST_ABORT ; abort when oldest closed
	push	bx				     ; no params to worry about
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	mov	ax, MSG_DESKDISPLAY_CLOSE_OLDEST_CHECK	; method to send to kids
	call	ObjCompProcessChildren	; return carry set from found window
					;	or carry clear b/c no window
	ret
DeskDisplayGroupCloseOldestCheck	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayGroupCloseOldest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	like MSG_DESKDG_CLOSE_OLDEST_CHECK, but through all
		children

CALLED BY:	MSG_DESKDG_CLOSE_OLDEST
PASS:		*ds:si	= DeskDisplayGroupClass object
		ds:di	= DeskDisplayGroupClass instance data
		ds:bx	= DeskDisplayGroupClass object (same as *ds:si)
		es 	= segment of DeskDisplayGroupClass
		ax	= message #
RETURN:		nothing 
DESTROYED:	nothing 
SIDE EFFECTS:	updates ss:[oldestWindow]

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CP	4/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayGroupCloseOldest	method dynamic DeskDisplayGroupClass, 
					MSG_DESKDG_CLOSE_OLDEST
	.enter
	clr	bx
	push	bx			; initial child (first child of comp.)
	push	bx
	mov	bx, offset GI_link	; pass offset to LinkPart
	push	bx
	clr	bx
	push	bx			; use canned callback routine
	mov	bx, OCCT_DONT_SAVE_PARAMS_TEST_ABORT ; abort when oldest closed
	push	bx				     ; no params to worry about
	mov	bx, offset Gen_offset
	mov	di, offset GI_comp
	mov	ax, MSG_DESKDISPLAY_CLOSE_OLDEST	; method to send to kids
	call	ObjCompProcessChildren	; return carry set from found window
					;	or carry clear b/c no window
	.leave
	ret
DeskDisplayGroupCloseOldest	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DiskDisplayControlTileDisplays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle tiling, by setting horizontal or vertical

CALLED BY:	MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS

PASS:		*ds:si - DeskDisplayGroupClass

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	5/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if not _ZMGR
ifndef GEOLAUNCHER

DiskDisplayGroupTileDisplays	method	DeskDisplayGroupClass,
					MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
	push	si
	mov	bx, handle OptionsList
	mov	si, offset OptionsList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	call	ObjMessageCallFixup		; ax = booleans
	pop	si
	test	ax, mask OMI_TILE_VERTICALLY
	jz	horizontal
;vertical:
	mov	ax, HINT_DISPLAY_GROUP_TILE_HORIZONTALLY
	call	ObjVarDeleteData
	mov	ax, HINT_DISPLAY_GROUP_TILE_VERTICALLY
	jmp	short common

horizontal:
	mov	ax, HINT_DISPLAY_GROUP_TILE_VERTICALLY
	call	ObjVarDeleteData
	mov	ax, HINT_DISPLAY_GROUP_TILE_HORIZONTALLY
common:
	clr	cx
	call	ObjVarAddData

	mov	ax, MSG_GEN_DISPLAY_GROUP_TILE_DISPLAYS
	mov	di, offset DeskDisplayGroupClass
	call	ObjCallSuperNoLock
	ret
DiskDisplayGroupTileDisplays	endm

endif
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayControlSetMaximizedNameState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	set or reset 'maximized-name-on-primary'

CALLED BY:	MSG_DESKDC_SET_MAXIMIZED_NAME_STATE

PASS:		*ds:si - DeskDisplayControlClass
		cl - TRUE to set 'maximized-name-on-primary', FALSE otherwise

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	9/26/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeskDisplayControlSetMaximizedNameState	method	dynamic DeskDisplayControlClass,
					MSG_DESKDC_SET_MAXIMIZED_NAME_STATE
	andnf	ds:[di].GDCII_attrs, not mask GDCA_MAXIMIZED_NAME_ON_PRIMARY
	tst	cl
	jz	done
	ornf	ds:[di].GDCII_attrs, mask GDCA_MAXIMIZED_NAME_ON_PRIMARY
done:
	ret
DeskDisplayControlSetMaximizedNameState	endm



if 0

DisplayDrawLasso	method	DeskDisplayClass, MSG_VIS_DRAW_LASSO
	curBounds	local	Rectangle
	.enter
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	di, es:[regionSelectGState]
	push	cx, dx
	call	WinGetWinBounds
        mov     curBounds.R_left, ax
	mov     curBounds.R_top, bx
	mov     curBounds.R_right, cx
	mov     curBounds.R_bottom, dx
	pop	cx, dx
	cmp     cx, curBounds.R_left
	jg	2$
	mov	cx, curBounds.R_left
2$:
	cmp     cx, curBounds.R_right
	jl	5$
	mov     cx, curBounds.R_right
5$:
	cmp	dx, curBounds.R_top
	jg	10$
	mov	dx, curBounds.R_top
10$:
	cmp     dx, curBounds.R_bottom
	jl      20$
	mov     dx, curBounds.R_bottom
20$:
	cmp	es:[regionSelectEnd].P_x, NIL	; any region yet?
	je	CLR_done			; nope, draw new one
	push	cx, dx				; save new point
	mov	ax, es:[regionSelectStart].P_x
	mov	bx, es:[regionSelectStart].P_y
	mov	cx, es:[regionSelectEnd].P_x	; get last region
	mov	dx, es:[regionSelectEnd].P_y
;clearLasso:
	call	GrDrawRect			; erase it
	pop	cx, dx				; retrieve new point
CLR_done:
	mov	ax, es:[regionSelectStart].P_x	; get start position
	mov	bx, es:[regionSelectStart].P_y
	mov	es:[regionSelectEnd].P_x, cx	; save new end position
	mov	es:[regionSelectEnd].P_y, dx
;drawLasso:
	call	GrDrawRect			; draw frame to (cx, dx)
	.leave
	ret
DisplayDrawLasso	endm

DisplayEndLasso	method	DeskDisplayClass, MSG_META_END_LASSO
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	di, es:[regionSelectGState]
	cmp	es:[regionSelectEnd].P_x, NIL	; any region yet?
	je	CLR_done
	mov	ax, es:[regionSelectStart].P_x
	mov	bx, es:[regionSelectStart].P_y
	mov	cx, es:[regionSelectEnd].P_x	; get last region
	mov	dx, es:[regionSelectEnd].P_y
	call	GrDrawRect			; erase it
CLR_done:
	call	GrDestroyState
	ret
DisplayEndLasso	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeskDisplayEndOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	on ZMGR, if doing START_SELECT quick transfer and we get
		an END_OTHER it means we got an END_SELECT with no
		active grab (some timing problem with the user doing some
		quick-transfer really quickly), just stop the quick-transfer

CALLED BY:	MSG_META_END_OTHER

PASS:		*ds:si	= DeskDisplayClass object
		ds:di	= DeskDisplayClass instance data
		es 	= segment of DeskDisplayClass
		ax	= MSG_META_END_OTHER

		cx, dx	= position
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/24/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DeskDisplayEndOther	method	dynamic	DeskDisplayClass, MSG_META_END_OTHER
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	jz	callSuper
	call	SendAbortQuickTransfer
callSuper:
	segmov	es, <segment DeskDisplayClass>, di
	mov	di, offset DeskDisplayClass
	GOTO	ObjCallSuperNoLock

DeskDisplayEndOther	endm

endif

;
; code for NoQTText
;


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoQTTextEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	if this text object gets an END_SELECT and we are doing a
		hacked START_SELECT quick-transfer, abort the quick-transfer
		as this text object isn't going to accept it (by definition)
		and because this text object doesn't know about our hacked
		START_SELECT quick-transfer and won't abort the quick-transfer
		for us

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si	= NoQTTextClass object
		ds:di	= NoQTTextClass instance data
		es 	= segment of NoQTTextClass
		ax	= MSG_META_END_SELECT

		cx, dx	= position
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/25/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

NoQTTextEndSelect	method	dynamic	NoQTTextClass, MSG_META_END_SELECT,
						MSG_META_LARGE_END_SELECT
	push		es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	pop	es
	jz	callSuper
	;
	; we tried to play by the rules and send MSG_VIS_RELEASE_GADGET_EXCL
	; to our vis-parent hoping we would get a MSG_VIS_LOST_GADGET_EXCL,
	; but to no avail.  Instead we'll just send a MSG_VIS_LOST_GADGET_EXCL
	; directly to ourselves - brianc 6/25/93
	;
	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_LOST_GADGET_EXCL
	call	ObjCallInstanceNoLock		; tell text to drop everything
	pop	ax, cx, dx, bp
	call	SendAbortQuickTransfer
callSuper:
	mov	di, offset NoQTTextClass
	GOTO	ObjCallSuperNoLock

NoQTTextEndSelect	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NoQTTextPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clear UIFA_MOVE_COPY (set in DeskApplicationPtr) if
		not doing quick-transfer.  Could happen if NoQTTextEndSelect
		clears quick-tranfser, but PTR messages are already queued.

CALLED BY:	MSG_META_PTR

PASS:		*ds:si	= NoQTTextClass object
		ds:di	= NoQTTextClass instance data
		es 	= segment of NoQTTextClass
		ax	= MSG_META_PTR

		cx, dx	= position
		bp low	= ButtonInfo
		bp high	= UIFunctionsActive

RETURN:		ax	= MouseReturnFlags

ALLOWED TO DESTROY:	
		cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	6/25/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _ZMGR

;
; DeskApplicationPtr does this now (to deal with the DeskTool gadgets)
; - brianc 6/28/93
;
if 0
NoQTTextPtr	method	dynamic	NoQTTextClass, MSG_META_PTR

NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_MOVECOPY
	jz	clearMoveCopy			; not move-copy (select- or
						;	otherwise)
	;
	; although fileDragging may indicate quick-transfer in progress,
	; we may just be waiting for the folder object to get the end-select
	; via the process from the GenView - brianc 6/28/93
	;
	tst	es:[delayedFileDraggingEnd]
	jz	callSuper			; we are not waiting, move-copy
						;	really in progress
						; otherwise, not move-copy
clearMoveCopy:
	andnf	bp, not (mask UIFA_MOVE_COPY shl 8)
callSuper:
	segmov	es, <segment NoQTTextClass>, di
	mov	di, offset NoQTTextClass
	GOTO	ObjCallSuperNoLock

NoQTTextPtr	endm
endif

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaximizedPrimaryDisplaySetMinimized
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	prevent minimizing, restoring

CALLED BY:	MSG_GEN_DISPLAY_SET_MINIMIZED,
		MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED

PASS:		*ds:si	= MaximizedPrimaryClass object
		ds:di	= MaximizedPrimaryClass instance data
		es 	= segment of MaximizedPrimaryClass
		ax	= MSG_GEN_DISPLAY_SET_MINIMIZED,
			  MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/23/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _KEEP_MAXIMIZED and _CONNECT_TO_REMOTE
MaximizedPrimaryDisplaySetMinimized	method	dynamic	MaximizedPrimaryClass,
					MSG_GEN_DISPLAY_SET_MINIMIZED,
					MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED
	push	es
NOFXIP<	segmov	es, dgroup, bx		; es = dgroup			>
FXIP  <	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	cmp	es:[connection], CT_FILE_LINKING
	pop	es
	jne	callSuper
	mov	cx, ERROR_RFSD_ACTIVE_2
	mov	ax, MSG_REMOTE_ERROR_BOX
	mov	bx, handle 0
	call	ObjMessageForce
	ret

callSuper:
	mov	di, offset MaximizedPrimaryClass
	GOTO	ObjCallSuperNoLock

MaximizedPrimaryDisplaySetMinimized	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaximizedPrimarySetMaximizedTemporarily
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	If the primary was maximized before now, then make
		sure we know to leave it that way when file linking
		is finished.

PASS:		*ds:si	- MaximizedPrimaryClass object
		ds:di	- MaximizedPrimaryClass instance data
		es	- segment of MaximizedPrimaryClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/13/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MaximizedPrimarySetMaximizedTemporarily	method	dynamic	MaximizedPrimaryClass, 
				MSG_MAXIMIZED_PRIMARY_MAXIMIZE_TEMPORARILY

		mov	ax, MSG_GEN_DISPLAY_GET_MAXIMIZED
		call	ObjCallInstanceNoLock
		jnc	done
		
		mov	ax, TEMP_MAXIMIZED_PRIMARY_WAS_MAXIMIZED_BEFORE
		clr	cx
		call	ObjVarAddData
done:
		mov	ax, MSG_GEN_DISPLAY_SET_MAXIMIZED
		GOTO	ObjCallInstanceNoLock 
MaximizedPrimarySetMaximizedTemporarily	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MaximizedPrimaryRestore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Restore the primary, unless it was maximized before

PASS:		*ds:si	- MaximizedPrimaryClass object
		ds:di	- MaximizedPrimaryClass instance data
		es	- segment of MaximizedPrimaryClass

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	12/13/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MaximizedPrimaryRestore	method	dynamic	MaximizedPrimaryClass, 
					MSG_MAXIMIZED_PRIMARY_RESTORE

	;
	; Find (and delete) the vardata.  If it's found, then bail.
	;
		
		mov	ax, TEMP_MAXIMIZED_PRIMARY_WAS_MAXIMIZED_BEFORE
		call	ObjVarDeleteData
		jnc	done

		mov	ax, MSG_GEN_DISPLAY_SET_NOT_MAXIMIZED
		GOTO	ObjCallInstanceNoLock 

done:
		ret
MaximizedPrimaryRestore	endm



endif

PseudoResident	ends


