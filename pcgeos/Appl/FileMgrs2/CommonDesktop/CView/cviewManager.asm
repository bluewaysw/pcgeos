COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cviewManager.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	8/27/92   	Initial version.

DESCRIPTION:
	

	$Id: cviewManager.asm,v 1.3 98/06/03 13:51:38 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;-----------------------------------------------------------------------------
;	Include common definitions
;-----------------------------------------------------------------------------

include cdesktopGeode.def
ND <include backgrnd.def>
ND <include initfile.def>
DBCS <include system.def>

FileMgrsClassStructures	segment	resource
	DesktopViewClass
ND <	NDDesktopViewClass	>
FileMgrsClassStructures	ends

UtilCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewSetInitialBackgroundColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set what the background color of the view should be set to
		if the displayType is not monochrome.

CALLED BY:	MSG_DESKTOP_VIEW_SET_INITIAL_BG_COLOR
PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		ds:bx	= DesktopViewClass object (same as *ds:si)
		es 	= segment of DesktopViewClass
		ax	= message #
		cl	= background color
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopViewSetInitialBackgroundColor	method dynamic DesktopViewClass, 
					MSG_DESKTOP_VIEW_SET_INITIAL_BG_COLOR
	mov	ds:[di].DVI_backGrColor, cl
	ret
DesktopViewSetInitialBackgroundColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewSpecBuildBranch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept SPEC_BUILD_BRANCH so we can set the actual
		background color of the view.

CALLED BY:	MSG_SPEC_BUILD_BRANCH
PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		ds:bx	= DesktopViewClass object (same as *ds:si)
		es 	= segment of DesktopViewClass
		ax	= message #
		bp	= SpecBuildFlags
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JS	12/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DesktopViewSpecBuildBranch	method dynamic DesktopViewClass, 
					MSG_SPEC_BUILD_BRANCH
	uses	ax, bp, es
	.enter

FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
NOFXIP<	segmov	es, dgroup, ax						>

	mov	cl, ds:[di].DVI_backGrColor
	cmp	cl, C_WHITE
	jne	checkMonochrome

	; Use custom background color for folders with white background

	mov	cl, es:[folderBackColor]

checkMonochrome:
	; If we are in monochrome, make sure no folder backgrounds are 
	; filled with a wash color, as they may be mapped to black in
	; the monochrome case

	mov	al, es:[desktopDisplayType]
	and	al, mask DT_DISP_CLASS
	cmp	al, DC_GRAY_1 shl offset DT_DISP_CLASS
	jne	setColor

	mov	cl, C_WHITE			; clear background color
						; if we are monochrome
setColor:
	mov	ax, MSG_GEN_VIEW_SET_COLOR
	mov	ch, CF_INDEX
	call	ObjCallInstanceNoLock

	.leave

	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock

DesktopViewSpecBuildBranch	endm

UtilCode	ends

;--------------

FolderCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	on ZMGR, override DeskApplication's setting of UIFA_MOVE_COPY
		if doing a START_SELECT quick-transfer so that the view
		doesn't do a wander grab (DeskApplication sets UIFA_MOVE_COPY
		to prevent menus from opening)

CALLED BY:	MSG_META_PTR

PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		es 	= segment of DesktopViewClass
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
	brianc	3/12/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

;
; For some reason, I have decided that we do want the view to do a wandering
; grab.  As a matter of fact, just like a real quick-transfer, all potential
; destinations need to grab the mouse - brianc 6/25/93
;
;if 0
; Added code back in as we don't really want wandering grab, just a grab, so
; we grab for ourselves in UNIV_ENTER - brianc 8/3/93
;
if 1
DesktopViewPtr	method	dynamic	DesktopViewClass, MSG_META_PTR
	push	es
NOFXIP<	segmov	es, dgroup, bx					>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX		>
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	pop	es
	jz	callSuper
	andnf	bp, not mask UIFA_MOVE_COPY shl 8
	ornf	bp, mask UIFA_SELECT shl 8
callSuper:
	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock

DesktopViewPtr	endm
endif

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	to deal with the problem where because an end-select on the
		view will by delayed via the process thread to the folder
		object, a UI-run object (such as the text object) will
		believe that a quick-transfer is still in process after the
		end-select and grab the mouse and provide feedback (the
		actual problem being that the fileDragging flags are not
		tested/cleared until the folder receives end-select, but the
		text object also tests those flags)

CALLED BY:	MSG_META_END_SELECT

PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		es 	= segment of DesktopViewClass
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
	brianc	6/28/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DesktopViewEndSelect	method	dynamic	DesktopViewClass, MSG_META_END_SELECT
	;
	; whether or not FDF_SELECT_MOVECOPY, FDF_MOVECOPY, or
	; FDF_MOVECOPY_PENDING is set, set flag saying that we'll be
	; ending move copy soon.  Then, if one of the above is set between
	; now and when we decide whether to check delayedFileDraggingEnd,
	; delayedFileDraggingEnd will be set correctly
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	es:[delayedFileDraggingEnd], BB_TRUE
	pop	es
	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock

DesktopViewEndSelect	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewEndOther
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	on ZMGR, if doing START_SELECT quick transfer and we get
		an END_OTHER it means we got an END_SELECT with no
		active grab (some timing problem with the user doing some
		quick-transfer really quickly), just stop the quick-transfer

CALLED BY:	MSG_META_END_OTHER

PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		es 	= segment of DesktopViewClass
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

DesktopViewEndOther	method	dynamic	DesktopViewClass, MSG_META_END_OTHER
	push	es
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	pop	es
	jz	callSuper
	call	SendAbortQuickTransfer
callSuper:
	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock

DesktopViewEndOther	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewPostPassiveButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	end quick-transfer for ZMGR

CALLED BY:	MSG_META_POST_PASSIVE_BUTTON

PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		es 	= segment of DesktopViewClass
		ax	= MSG_META_POST_PASSIVE_BUTTON

		cx, dx	= mouse position
		bp low	= ButtonInfo
		bp high	= ShiftState

RETURN:		ax	= MouseReturnFlags
				MRF_PROCESSED
				MRF_REPLAY

ALLOWED TO DESTROY:	
		cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		finish quick-transfer on any button activity

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/12/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DesktopViewPostPassiveButton	method	dynamic	DesktopViewClass,
						MSG_META_POST_PASSIVE_BUTTON
	;
	; on any button activity, stop quick-transfer (okay to do even if
	; valid destination got END_SELECT and already processed and ended
	; quick-transfer)
	;
	push	si
	mov	ax, MSG_FOLDER_QUIT_QUICK_TRANSFER
	movdw	bxsi, ds:[di].GVI_content	; ^lbx:si = Folder
	clr	di
	call	ObjMessage
	pop	si
	;
	; remove post passive
	;
	call	VisRemoveButtonPostPassive
	mov	ax, mask MRF_PROCESSED
	ret
DesktopViewPostPassiveButton	endm

;
; remove PostPassive in this case also - brianc 7/2/93
;
DesktopViewVisClose	method	dynamic	DesktopViewClass, MSG_VIS_CLOSE
	call	VisRemoveButtonPostPassive
	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock
DesktopViewVisClose	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewRawUnivLeave
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	release mouse for view if doing START_SELECT quick-transfer

CALLED BY:	MSG_META_RAW_UNIV_LEAVE

PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		es 	= segment of DesktopViewClass
		ax	= MSG_META_RAW_UNIV_LEAVE

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/15/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DesktopViewRawUnivLeave	method	dynamic	DesktopViewClass,
						MSG_META_RAW_UNIV_LEAVE
	;
	; if START_SELECT quick-transfer, release mouse for view
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	pop	es
	jz	callSuper
	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_RELEASE_GADGET_EXCL
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	VisCallParent
	pop	ax, cx, dx, bp

callSuper:
	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock

DesktopViewRawUnivLeave	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DesktopViewRawUnivEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	grab mouse for view if doing START_SELECT quick-transfer

CALLED BY:	MSG_META_RAW_UNIV_ENTER

PASS:		*ds:si	= DesktopViewClass object
		ds:di	= DesktopViewClass instance data
		es 	= segment of DesktopViewClass
		ax	= MSG_META_RAW_UNIV_ENTER

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	3/15/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _PEN_BASED

DesktopViewRawUnivEnter	method	dynamic	DesktopViewClass,
						MSG_META_RAW_UNIV_ENTER
	;
	; if START_SELECT quick-transfer, grab mouse for view
	;
	push	es
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	test	es:[fileDragging], mask FDF_SELECT_MOVECOPY
	pop	es
	jz	callSuper
	push	ax, cx, dx, bp
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	VisCallParent
	;
	; Grab mouse itself, passing pane window (can't use VisGrabMouse)
	;
	sub	sp, size VupAlterInputFlowData	; create stack frame
	mov	bp, sp				; ss:bp points to it
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].VAIFD_object.handle, ax	; copy object OD into frame
	mov	ss:[bp].VAIFD_object.chunk, si
	mov	ss:[bp].VAIFD_flags, mask VIFGF_MOUSE or mask VIFGF_GRAB or \
				mask VIFGF_PTR or mask VIFGF_NOT_HERE or \
				mask VIFGF_FORCE  ; ...by force
	mov	ss:[bp].VAIFD_grabType, VIFGT_ACTIVE

	mov	ax, MSG_GEN_VIEW_GET_WINDOW
	push	bp
	call	ObjCallInstanceNoLock		; cx = window
	pop	bp
	mov	ss:[bp].VAIFD_gWin, cx

	clr	ax				; init to no translation
	mov	ss:[bp].VAIFD_translation.PD_x.high, ax
	mov	ss:[bp].VAIFD_translation.PD_x.low, ax
	mov	ss:[bp].VAIFD_translation.PD_y.high, ax
	mov	ss:[bp].VAIFD_translation.PD_y.low, ax

	mov	dx, size VupAlterInputFlowData	; pass size of structure in dx
	mov	ax, MSG_VIS_VUP_ALTER_INPUT_FLOW	; send method
	call	ObjCallInstanceNoLock
	add	sp, size VupAlterInputFlowData	; restore stack
	pop	ax, cx, dx, bp

callSuper:
	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock

DesktopViewRawUnivEnter	endm

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NDDesktopViewUpdateBGColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	update the background color if necessary

CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si	= NDDesktopViewClass object
		ds:di	= NDDesktopViewClass instance data
		es 	= segment of NDDesktopViewClass
		ax	= MSG_VIS_DRAW
		cl	= DrawFlags
		^hbp	= GState
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ed	3/14/02  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if _NEWDESK
backgroundCategory	char	BACKGROUND_CATEGORY,0
backgroundColorKey	char	BACKGROUND_COLOR_KEY,0

NDDesktopViewSpecBuildBranch	method	dynamic	NDDesktopViewClass,
					MSG_SPEC_BUILD_BRANCH,
					MSG_ND_DESKTOP_VIEW_UPDATE_BG_COLOR
	uses	ax,bp,es
	.enter
NOFXIP<	segmov	es, dgroup, bx						>
FXIP<	GetResourceSegmentNS dgroup, es, TRASH_BX			>
	mov	al, es:[desktopDisplayType]
	andnf	al, mask DT_DISP_CLASS
	cmp	al, DC_GRAY_1
	je	done

	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	di, {word}ds:[di].GVI_color	; di = CQ_redOrIndex/CQ_info

	push	ds, si
	mov	cx, cs
	mov	dx, offset backgroundColorKey
	mov	ds, cx
	mov	si, offset backgroundCategory
if DBCS_PCGEOS
	clr	bp
	call	InitFileReadString
	jc	donePop			;Exit if key not found in .ini file

	call	MemLock
	mov	ds, ax
	clr	si
	call	UtilAsciiToHex32	;dx:ax = value
	pushf
	call	MemFree
	popf
	jc	donePop
	tst	dx			;illegal value?
	stc
	jnz	donePop
	clc
donePop:
else
	call	InitFileReadInteger
endif
	pop	ds, si
	jc	done

	cmp	ax, di
	je	done

	mov	cx, ax
	clr	dx
	mov	ax, MSG_GEN_VIEW_SET_COLOR
	call	ObjCallInstanceNoLock
done:
	.leave
	; We want GenViewClass's MSG_SPEC_BUILD behavior, however, we don't
	; want DesktopViewClass's behavior for it. So, we'll do a callsuper
	; passing it DesktopViewClass instead of NDDesktopViewClass.
	; MSG_ND_DESKTOP_VIEW_UPDATE_BG_COLOR doesn't exist in any of the
	; superclasses, so the callsuper will get discarded.
	mov	di, offset DesktopViewClass
	GOTO	ObjCallSuperNoLock
NDDesktopViewSpecBuildBranch	endm
endif ; _NEWDESK

FolderCode	ends
