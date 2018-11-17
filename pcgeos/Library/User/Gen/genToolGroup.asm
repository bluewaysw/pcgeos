COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		UserInterface/Gen
FILE:		genToolGroup.asm

ROUTINES:
	Name				Description
	----				-----------
   GLB	GenToolGroupClass		Control object

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	Doug	7/92			Initial version

DESCRIPTION:
	This file contains routines to implement the GenToolGroup class

	$Id: genToolGroup.asm,v 1.1 97/04/07 11:45:05 newdeal Exp $

------------------------------------------------------------------------------@

UserClassStructures	segment resource

	GenToolGroupClass

UserClassStructures	ends

if not NO_CONTROLLERS	;++++++++++++++++++++++++++++++++++++++++++++++++++++

ControlObject segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolGroupSetHighlight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	<description here>

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_GEN_TOOL_GROUP_SET_HIGHLIGHT

		cl	- ToolGroupHighlightType

RETURN:		nothing

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolGroupSetHighlight	method dynamic	GenToolGroupClass,
					MSG_GEN_TOOL_GROUP_SET_HIGHLIGHT
EC <	cmp	cl, ToolGroupHighlightType				>
EC <	ERROR_AE	BAD_HIGHLIGHT_TYPE				>

	cmp	cl, TGHT_NO_HIGHLIGHT
	je	nukeHighlight

	push	cx

;	Set the tool group enabled when we are customizing the toolbar, so
;	the tool group can be clicked on, even if the associated controller
;	is disabled (when the highlight goes away, we'll restore the enabled
;	state).

	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	mov	ax, TEMP_TOOL_GROUP_HIGHLIGHT
	call	ObjVarFindData
	jc	existingHighlight

					; Create vardata for highlight
	mov	ax, TEMP_TOOL_GROUP_HIGHLIGHT
	mov	cx, size ToolGroupHighlightType
	call	ObjVarAddData

existingHighlight:
	pop	cx
	mov	ds:[bx], cl		; store color away for later
	call	GenToolGroupDrawHighlightFromScratch
	jmp	short done

nukeHighlight:
					; Nuke vardata
	mov	ax, TEMP_TOOL_GROUP_HIGHLIGHT
	call	ObjVarDeleteData
	jc	skipInval

;	We can't do this, because we have VCGA_ONLY_DRAWS_IN_MARGINS set. We'd
;	have to invalidate our children instead. So, we just invalidate our
;	bounds on screen.
; we have turned off VCGA_ONLY_DRAWS_IN_MARGINS for GenToolGroup, so we can
; use MSG_VIS_INVALIDATE now - brianc 2/5/93

	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

;	call	VisQueryWindow
;	tst	di
;	jz	skipInval
;
;	push	si
;	call	VisGetBounds
;	clrdw	bpsi
;	call	WinInvalReg
;	pop	si

skipInval:
;
;	Now, restore the enabled state from the controller
;

	push	si
	mov	di, ds:[si]
	add	di, ds:[di].GenToolGroup_offset
	movdw	bxsi, ds:[di].GTGI_controller
	tst_clc	bx			;If no controller, disable the 
	jz	noController		; tool group (it is unclear if this
					; can ever happen, though).
	mov	ax, MSG_GEN_GET_ENABLED
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
noController:
	pop	si
	mov	ax, MSG_GEN_SET_ENABLED
	jc	setObj
	mov	ax, MSG_GEN_SET_NOT_ENABLED
setObj:
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock
done:
	ret

GenToolGroupSetHighlight	endm

;--------------

GenToolGroupDrawHighlightFromScratch	proc	near
	call	VisQueryWindow
	tst	di
	jz	done
	call	GrCreateState
	call	GenToolGroupDrawHighlightLow
	call	GrDestroyState
done:
	ret
GenToolGroupDrawHighlightFromScratch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetLineColorForCurrentDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the line color for the current display

CALLED BY:	GLOBAL
PASS:		cl - ToolGroupHighlightType
		*ds:si GenToolGroupClass
		di - gstate
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/21/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetLineColorForCurrentDisplay	proc	near
	.enter
	push	cx
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	UserCallApplication		;AH <- DisplayType
	pop	cx
	and	ah, mask DT_DISP_CLASS
	cmp	ah, DC_GRAY_1 shl offset DT_DISP_CLASS
	ja	isColor

	mov	ax, C_BLACK
	cmp	cl, TGHT_ACTIVE_HIGHLIGHT
	je	setColor
EC <	cmp	cl, TGHT_INACTIVE_HIGHLIGHT				>
EC <	ERROR_NZ	BAD_HIGHLIGHT_TYPE				>

;	We are in B/W mode, so set the map mode to dither, and the color
;	to BW_GREY

	mov	al, CMT_DITHER
	call	GrSetLineColorMap

	mov	ax, C_BW_GREY
	jmp	setColor

isColor:
	mov	ax, ACTIVE_COLOR

	cmp	cl, TGHT_ACTIVE_HIGHLIGHT
	je	setColor
EC <	cmp	cl, TGHT_INACTIVE_HIGHLIGHT				>
EC <	ERROR_NZ	BAD_HIGHLIGHT_TYPE				>
	mov	ax, INACTIVE_COLOR

setColor:
	call	GrSetLineColor
	.leave
	ret
SetLineColorForCurrentDisplay	endp

;--------------
ACTIVE_COLOR	equ	C_LIGHT_VIOLET
INACTIVE_COLOR	equ	C_BROWN

GenToolGroupDrawHighlightLow	proc	far

;	If there are no tools (no children), then don't draw the outline

	push	cx
	mov	ax, MSG_GEN_COUNT_CHILDREN
	call	ObjCallInstanceNoLock
	pop	cx
	tst	dx
	jz	noDraw

	call	GrSaveState

	call	SetLineColorForCurrentDisplay

	mov	dx, 2
	clr	ax
	call	GrSetLineWidth

	call	VisGetBounds
	inc	ax
	inc	bx
	dec	cx
	dec	dx
EC <	cmp	cx, ax							>
EC <	ERROR_BE	BAD_TOOL_GROUP_BOUNDS				>
EC <	cmp	dx, bx							>
EC <	ERROR_BE	BAD_TOOL_GROUP_BOUNDS				>

	call	GrDrawRect

	call	GrRestoreState
noDraw:
	ret
GenToolGroupDrawHighlightLow	endp

ControlObject	ends

GCCommon segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	GenToolGroupBuildBranch

DESCRIPTION:	Intercept spec build to request generation of tools

PASS:
	*ds:si - instance data
	es - segment of class

RETURN:
	none

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Doug	7/15/92		initial version

------------------------------------------------------------------------------@
GenToolGroupBuildBranch	method dynamic	GenToolGroupClass,
						MSG_SPEC_BUILD_BRANCH

	mov	bx, di
	mov	di, 600
	call	ThreadBorrowStackSpace
	push	di

	tst	ds:[bx].GI_comp.CP_firstChild.handle
	jnz	afterToolsGenerated

	push	ax, cx, dx, bp, si

	; Ask controller to build tool set
	;
	mov	ax, MSG_GEN_CONTROL_GENERATE_TOOLBOX_UI
	mov	cx, ds:[LMBH_handle]		; Pass self as tool parent
	mov	dx, si
	mov	si, ds:[bx].GTGI_controller.chunk
	mov	bx, ds:[bx].GTGI_controller.handle
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	pop	ax, cx, dx, bp, si
afterToolsGenerated:
	mov	ax, MSG_SPEC_BUILD_BRANCH	; Then, do specific build
	mov	di, offset GenToolGroupClass
	call	ObjCallSuperNoLock

	pop	di
	call	ThreadReturnStackSpace
	ret

GenToolGroupBuildBranch	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolGroupSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	clear VCGA_ONLY_DRAWS_IN_MARGINS, to deal with drawing
		highlight for tools that don't completely fill a rectangular
		region

CALLED BY:	MSG_SPEC_BUILD

PASS:		*ds:si	= GenToolGroupClass object
		ds:di	= GenToolGroupClass instance data
		es 	= segment of GenToolGroupClass
		ax	= MSG_SPEC_BUILD

		bp	= SpecBuildFlags

RETURN:		nothing

ALLOWED TO DESTROY:	
		ax, cx, dx, bp
		bx, si, di, ds, es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	2/5/93  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolGroupSpecBuild	method	dynamic	GenToolGroupClass, MSG_SPEC_BUILD
	;
	; let superclass do default handling
	;
	mov	di, offset GenToolGroupClass
	call	ObjCallSuperNoLock
	;
	; then clear VCGA_ONLY_DRAWS_IN_MARGINS
	;
EC <	call	VisCheckVisAssumption					>
NEC <	call	VisCheckIfVisGrown					>
NEC <	jnc	done							>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VCI_geoAttrs, not mask VCGA_ONLY_DRAWS_IN_MARGINS
NEC <done:								>
	ret
GenToolGroupSpecBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolGroupDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	<description here>

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- MSG_VIS_DRAW

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenToolGroupDraw	method dynamic	GenToolGroupClass,
						MSG_VIS_DRAW
	push	bp
	mov	di, offset GenToolGroupClass
	call	ObjCallSuperNoLock
	pop	bp

	; Check to see if we should highlight group
	;
	mov	ax, TEMP_TOOL_GROUP_HIGHLIGHT
	call	ObjVarFindData
	jnc	done

	mov	cl, ds:[bx]		; get highlight color
	mov	di, bp
	call	GenToolGroupDrawHighlightLow
done:
	ret
GenToolGroupDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenToolGroupMouseInput
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	<description here>

PASS:		*ds:si	- instance data
		ds:di	- ptr to start of master instance data
		es	- segment of class
		ax 	- The various mouse input messages

		<pass info>

RETURN:		<return info>

ALLOWED TO DESTROY:
		bx, si, di, ds, es

PSEUDO CODE/STRATEGY/KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	doug	7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenToolGroupMouseInput	method dynamic	GenToolGroupClass, MSG_META_PTR,
					      MSG_META_START_SELECT,
					      MSG_META_START_MOVE_COPY,
					      MSG_META_START_FEATURES,
					      MSG_META_START_OTHER,
					      MSG_META_DRAG_SELECT,
					      MSG_META_DRAG_MOVE_COPY,
					      MSG_META_DRAG_FEATURES,
					      MSG_META_DRAG_OTHER,
					      MSG_META_END_SELECT,
					      MSG_META_END_MOVE_COPY,
					      MSG_META_END_FEATURES,
					      MSG_META_END_OTHER,
				MSG_META_QUERY_IF_PRESS_IS_INK

	; Check to see if in special highlight mode.  If so, branch to deal
	; with it.  Otherwise just call superclass.
	;
	push	ax
	mov	ax, TEMP_TOOL_GROUP_HIGHLIGHT
	call	ObjVarFindData
	pop	ax
	jc	highlightMode

	mov	di, offset GenToolGroupClass
	GOTO	ObjCallSuperNoLock

highlightMode:
	cmp	ax, MSG_META_START_SELECT
	je	sendToolgroupSelectedChange

	cmp	ax, MSG_META_QUERY_IF_PRESS_IS_INK
	je	isInk

	jmp	short mouseExit

isInk:
	mov	ax, IRV_NO_INK		; No ink while editing tools
	jmp	short exit

sendToolgroupSelectedChange:
	mov	bx, ds:[di].GTGI_controller.handle
	tst	bx
	jz	afterChangeSent
	push	si
	mov	si, ds:[di].GTGI_controller.chunk
	call	ObjSwapLock
	mov	ax, mask GCSF_HIGHLIGHTED_TOOLGROUP_SELECTED
	call	ControlSendStatusChange
	call	ObjSwapUnlock
	pop	si
afterChangeSent:

mouseExit:
	mov	ax, mask MRF_PROCESSED
exit:
	ret

GenToolGroupMouseInput	endm

GCCommon ends

endif			; NO_CONTROLLERS ++++++++++++++++++++++++++++++++++++

