COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1994 -- All Rights Reserved

PROJECT:	Pen library
MODULE:		Ink
FILE:		inkClassCommon.asm

AUTHOR:		Andrew Wilson, Oct 10, 1994

ROUTINES:
	Name			Description
	----			-----------
	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	dlitwin	10/10/94	Broken out of inkClass.asm

DESCRIPTION:
	Method handlers for ink class.	

	$Id: inkClassCommon.asm,v 1.1 97/04/05 01:27:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


PenClassStructures	segment	resource
	InkClass
	method	VisObjectHandlesInkReply, InkClass, 
				MSG_VIS_QUERY_IF_OBJECT_HANDLES_INK
PenClassStructures	ends

InkCommon	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkRelocOrUnReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears out instance data that is no longer valid

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkRelocOrUnReloc	method	InkClass, reloc
	.enter

;	Don't do this on VMRT_RELOCATE_AFTER_WRITE, as we were
;	guaranteed to have just done a VMRT_UNRELOCATE_BEFORE_WRITE
;
;	Don't do this on VMRT_RELOCATE_FROM_RESOURCE, as we *assume*
;	that the data is set up correctly straight from the resource...
;
;	Theoretically, we don't even need to do it on VMRT_RELOCATE_AFTER_READ,
;	but just to be safe...

	cmp	dx, VMRT_RELOCATE_AFTER_READ
	je	doClr
	cmp	dx, VMRT_UNRELOCATE_FROM_RESOURCE
	je	doClr
	cmp	dx, VMRT_UNRELOCATE_BEFORE_WRITE
	jne	callSuper
doClr:

;	Nuke any current selection, and nuke the flags that say we have the
;	target/mouse grab/are selecting

	clr	ds:[di].II_cachedGState
	clr	ds:[di].II_antTimer
	clr	ds:[di].II_selectBounds.R_left
	clr	ds:[di].II_selectBounds.R_right
	clr	ds:[di].II_selectBounds.R_top
	clr	ds:[di].II_selectBounds.R_bottom
	andnf	ds:[di].II_flags, not (mask IF_HAS_MOUSE_GRAB or mask IF_SELECTING or mask IF_HAS_TARGET or mask IF_HAS_SYS_TARGET)
callSuper:
	mov	di, offset InkClass
	call	ObjRelocOrUnRelocSuper
	.leave
	ret
InkRelocOrUnReloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetMaxPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the maximum # points

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetMaxPoints	method InkClass, MSG_INK_SET_MAX_POINTS
	.enter
	push	cx
	mov	ax, ATTR_INK_MAX_POINTS
	mov	cx, size word
	call	ObjVarAddData
	pop	ds:[bx]
	.leave
	ret
InkSetMaxPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMaxNumPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the maximum number of points for this array

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		dx - max # points
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetMaxNumPoints	proc	far	uses	ax, bx
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	dx, MAX_INK_POINTS
	mov	ax, ATTR_INK_MAX_POINTS
	call	ObjVarFindData
	jnc	exit
	mov	dx, ds:[bx]
exit:
	.leave
	ret
GetMaxNumPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalidateIfDrawable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends a MSG_VIS_INVALIDATE to the object if it has the 
		VA_DRAWABLE bit set.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	di, ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	4/12/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvalidateIfDrawable	proc	far
	class	InkClass
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].VI_attrs, mask VA_DRAWABLE
	jz	noInvalidate
	mov	ax, MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
noInvalidate:
	ret
InvalidateIfDrawable	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrabTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grabs the target for the current object

CALLED BY:	GLOBAL
PASS:		*ds:si - Ink object
RETURN:		ds:di - ptr to Ink instance data
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrabTarget	proc	far	uses	ax, cx, dx, bp
	.enter
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	mov	di, offset InkClass
	call	ObjCallSuperNoLock
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	.leave
	ret
GrabTarget	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallToView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the passed message to the view.

CALLED BY:	GLOBAL
PASS:		message args
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CallToView	proc	near
	.enter
	push	si
	mov	bx, segment GenViewClass
	mov	si, offset GenViewClass
	ornf	di, mask MF_RECORD
	call	ObjMessage
	mov	cx, di		;CX <- handle of classed event
	pop	si

	mov	ax, MSG_VIS_VUP_CALL_OBJECT_OF_CLASS
	call	VisCallParent
	.leave
	ret
CallToView	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetStrokeWidthAndHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the width/height of the strokes

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		al - width
		ah - height
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetStrokeWidthAndHeight	proc	far	uses	bx
	.enter
	mov	ax, ATTR_INK_STROKE_SIZE
	call	ObjVarFindData
	mov	ax, ds:[bx]
	jc	exit
	call	SysGetInkWidthAndHeight

exit:
	.leave
	ret
GetStrokeWidthAndHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetStrokeSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the stroke size for the ink object.

CALLED BY:	GLOBAL
PASS:		cl - stroke width
		ch - stroke height
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetStrokeSize	method	InkClass, MSG_INK_SET_STROKE_SIZE
	push	cx
	mov	ax, ATTR_INK_STROKE_SIZE or mask VDF_SAVE_TO_STATE
	mov	cx, size InkStrokeSize
	call	ObjVarAddData
	pop	ds:[bx]

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	test	ds:[di].II_flags, mask IF_ONLY_CHILD_OF_CONTENT
	jz	inval
	call	SetInkDestination
inval:
	call	InvalidateIfDrawable
	ret
InkSetStrokeSize	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets a gstate.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/13/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetGState	proc	far	uses	ax, bx, cx, dx, bp, si
	.enter
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	VisCallParent
	mov	di, 0			;Don't change to "clr"
	jnc	exit
	mov	di, bp

exit:
	.leave
	ret
GetGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetInkDestination
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets this object as the dest for the ink info

CALLED BY:	GLOBAL
PASS:		*ds:si - Ink obj
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetInkDestination	proc	far	uses	si
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	cmp	ds:[di].II_tool, IT_SELECTOR
	je	selectTool

;	Set color/width&height of ink
; 	We hack the eraser by drawing fat ink in "white"

	call	GetStrokeWidthAndHeight
.assert CF_INDEX eq 0

	clr	ch
	mov	cl, ds:[di].II_penColor
	cmp	ds:[di].II_tool, IT_ERASER
	jne	10$
	call	GetGState
	tst	di
	jz	10$	
	push	si
	mov	si, WIT_COLOR
	call	WinGetInfo
	pop	si
	mov	cl, al			;CL <- window BG color
	call	GrDestroyState
	mov	ax, ERASER_WIDTH_AND_HEIGHT

10$:
	mov	dx, size InkDestinationInfoParams
	sub	sp, dx
	mov	bp, sp

	mov	ss:[bp].IDIP_brushSize, ax
	mov	ss:[bp].IDIP_color, cl
	mov	ss:[bp].IDIP_createGState, TRUE
	mov	ax, ds:[LMBH_handle]
	movdw	ss:[bp].IDIP_dest, axsi

	mov	ax, MSG_GEN_VIEW_SET_EXTENDED_INK_TYPE
	mov	di, mask MF_STACK 
	call	CallToView

	add	sp, size InkDestinationInfoParams

	mov	cl, GVIT_PRESSES_ARE_INK
setInkType:
	mov	ax, MSG_GEN_VIEW_SET_INK_TYPE
	clr	di
	call	CallToView
	.leave
	ret

selectTool:

;	If this is the select tool, then change the ink type to not allow ink.

	mov	ax, MSG_GEN_VIEW_RESET_EXTENDED_INK_TYPE
	clr	di
	call	CallToView
	
	mov	cl, GVIT_QUERY_OUTPUT
	jmp	setInkType
SetInkDestination	endp

COMMENT @----------------------------------------------------------------------
FUNCTION:	AddToGCNListCommon

DESCRIPTION:	Add/remove this object to/from an Application GCN list

CALLED BY:	INTERNAL
		AddToGCNLists

PASS:		*ds:si	- this object
		ax	- MSG_META_GCN_LIST_ADD or MSG_META_GCN_LIST_REMOVE
		<cx><dx>- gcn list
RETURN:		nothing
DESTROYED:	nothing
------------------------------------------------------------------------------@

AddOrRemoveFromGCNList	proc	near	uses	ax, bx, cx, dx, bp, si
	.enter
	sub	sp, size GCNListParams	; create stack frame
	mov	bp, sp
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, cx
	mov	ss:[bp].GCNLP_ID.GCNLT_type, dx
	mov	bx, ds:[LMBH_handle]
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si
	mov	dx, size GCNListParams	; create stack frame

;	Send the method to the application object

	clr	bx
	call	GeodeGetAppObject
	tst	bx
	jz	exit
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
exit:
	add	sp, size GCNListParams	; fix stack
	.leave
	ret
AddOrRemoveFromGCNList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the ink object as the dest for ink info.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkVisOpen	method	InkClass, MSG_VIS_OPEN


	push	ax, cx, dx, bp

	test	ds:[di].II_flags, mask IF_CONTROLLED
	jz	notControlled

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GAGCNLT_CONTROLLED_INK_OBJECTS
	mov	ax, MSG_META_GCN_LIST_ADD
	call	AddOrRemoveFromGCNList

	; Add ourselves to the global GCN list for ink
	;
	mov	ax, GCNSLT_INK
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GCNListAdd

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
notControlled:
	test	ds:[di].II_flags, mask IF_ONLY_CHILD_OF_CONTENT
	jz	10$			;Branch to skip optimization.
	call	SetInkDestination
10$:
	pop	ax, cx, dx, bp
	mov	di, offset InkClass
	GOTO	ObjCallSuperNoLock
InkVisOpen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Removes the ink object as the dest for ink info

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/19/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkVisClose	method	InkClass, MSG_VIS_CLOSE
	mov	di, offset InkClass
	call	ObjCallSuperNoLock
if 0
;
;	Release the target exclusive when we close - added to fix problem
;	where we could go away yet still have the target exclusive...
;
;	Not a necessary fix...
;
	mov	ax, MSG_META_RELEASE_TARGET_EXCL
	call	ObjCallInstanceNoLock
endif
	call	NukeSelection		;The selection is removed if the
					; object is VisClosed
	mov	di,  ds:[si]
	add	di, ds:[di].Ink_offset
	test	ds:[di].II_flags, mask IF_CONTROLLED
	jz	notControlled

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GAGCNLT_CONTROLLED_INK_OBJECTS
	mov	ax, MSG_META_GCN_LIST_REMOVE
	call	AddOrRemoveFromGCNList

	; Remove ourselves from the global GCN list for ink
	;
	mov	ax, GCNSLT_INK
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	cx, ds:[LMBH_handle]
	mov	dx, si
	call	GCNListRemove

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset

notControlled:
	test	ds:[di].II_flags, mask IF_ONLY_CHILD_OF_CONTENT
	jz	exit
	mov	ax, MSG_GEN_VIEW_RESET_EXTENDED_INK_TYPE
	clr	di
	call	CallToView
exit:
	ret
InkVisClose	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current ink flags

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		cx - flags 
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetFlags	method	dynamic	InkClass, MSG_INK_GET_FLAGS
	.enter
	mov	cx, ds:[di].II_flags
	.leave
	ret
InkGetFlags	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out the various GCN messages when we gain the target
		excl.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGainedTargetExcl	method	InkClass, MSG_META_GAINED_TARGET_EXCL
	.enter
	ornf	ds:[di].II_flags, mask IF_HAS_TARGET
	mov	di, offset InkClass
	call	ObjCallSuperNoLock
	call	UpdateEditControlStatus

EC <	call	ECCheckIfInkObject				>
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	bp, ds:[di].II_tool
	ornf	bp, 0x8000
	call	SendInkControlGCNNotification

	.leave
	ret
InkGainedTargetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends out the various GCN messages when we lose the target
		excl.

CALLED BY:	GLOBAL
PASS:		*ds:si - object
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkLostTargetExcl	method	InkClass, MSG_META_LOST_TARGET_EXCL
	.enter
	mov	di, offset InkClass
	call	ObjCallSuperNoLock

	clr	bx
	call	SendEditControlGCNNotification
	clr	bp
	call	SendInkControlGCNNotification

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	andnf	ds:[di].II_flags, not mask IF_HAS_TARGET
	.leave
	ret
InkLostTargetExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkLostSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When we lose the system target exclusive, this method
		handler is called, so we can erase the selection.

CALLED BY:	GLOBAL
PASS:		*ds:si - InkObject
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkLostSysTargetExcl	method	InkClass, MSG_META_LOST_SYS_TARGET_EXCL
	.enter
	mov	di, offset InkClass
	call	ObjCallSuperNoLock

	clr	di
	call	RedrawSelection			;Erase the selection now that
						; we have lost the target
	jnc	exit
	
	call	StopAntTimer
exit:
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	andnf	ds:[di].II_flags, not mask IF_HAS_SYS_TARGET
	.leave
	ret
InkLostSysTargetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGainedSysTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	When we gain the system target exclusive, this method
		handler is called, so we can draw the selection.

CALLED BY:	GLOBAL
PASS:		*ds:si - InkObject
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGainedSysTargetExcl	method	InkClass, MSG_META_GAINED_SYS_TARGET_EXCL
	.enter
	mov	di, offset InkClass
	call	ObjCallSuperNoLock

	clr	di
	call	RedrawSelection			;Redraw the selection now that
						; we have lost the target
	jnc	exit				;Exit if no selection
	call	StartAntTimerIfNotAlreadyStarted	
exit:	
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	ornf	ds:[di].II_flags, mask IF_HAS_SYS_TARGET
	.leave
	ret
InkGainedSysTargetExcl	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkForceControllerUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forces the ink object to update the edit controller.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkForceControllerUpdate	method	InkClass,
				MSG_META_UI_FORCE_CONTROLLER_UPDATE
	.enter
	cmp	cx, -1
	jne	10$
	cmp	dx, -1
	je	doUpdate
10$:
	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jnz	exit
	cmp	dx, GWNT_SELECT_STATE_CHANGE
	jne	exit
doUpdate:
	call	UpdateEditControlStatus
exit:
	.leave
	ret
InkForceControllerUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeInkData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the ink data.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeInkData	proc	far	uses	ax, di
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	clr	ax
	xchg	ax, ds:[di].II_segments
	tst	ax
	jz	exit
	call	ObjMarkDirty
	call	LMemFree
exit:
	.leave
	ret
FreeInkData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees up extra data.

CALLED BY:	GLOBAL
PASS:		nada
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkFree		method	dynamic InkClass, MSG_META_OBJ_FREE
	call	FreeInkData
	mov	ax, MSG_META_OBJ_FREE
	mov	di, offset InkClass
	GOTO	ObjCallSuperNoLock
InkFree	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current ink flags

CALLED BY:	GLOBAL
PASS:		cx - flags to set
		dx - flags to clear
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetFlags	method	dynamic	InkClass, MSG_INK_SET_FLAGS
	.enter
EC <	test	cx, mask IF_HAS_TARGET					>
EC <	ERROR_NZ	BAD_FLAGS_PASSED_WITH_MSG_INK_SET_FLAGS		>
EC <	test	dx, mask IF_HAS_TARGET					>
EC <	ERROR_NZ	BAD_FLAGS_PASSED_WITH_MSG_INK_SET_FLAGS		>

EC <	test	cx, not (mask InkFlags)					>
EC <	ERROR_NZ	BAD_FLAGS_PASSED_WITH_MSG_INK_SET_FLAGS		>
EC <	test	dx, not (mask InkFlags)					>
EC <	ERROR_NZ	BAD_FLAGS_PASSED_WITH_MSG_INK_SET_FLAGS		>

	ornf	ds:[di].II_flags, cx
	not	dx
	andnf	ds:[di].II_flags, dx
	call	ObjMarkDirty
	.leave
	ret
InkSetFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateToInkOrigin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translates the passed gstate to the ink origin

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
		di - gstate
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 1/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TranslateToInkOrigin	proc	near	uses	ax, bx, cx, dx
	.enter
EC <	call	ECCheckIfInkObject					>
	call	VisGetBounds		;AX - left, BX - top
	mov_tr	dx, ax
	clr	ax			;BX.AX <- y translation (WWFixed)
	clr	cx			;DX.CX <- X translation (WWFixed)
	call	GrApplyTranslation
	.leave
	ret
TranslateToInkOrigin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawMultipleLineSegments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws multiple line segments from the point array.

CALLED BY:	GLOBAL
PASS:		es:di - ptr to first line segment to draw
		cx - # points to draw
		dx = non-zero if printing, else zero
		bp - gstate to draw through
		*ds:si - ink object
RETURN:		nada
DESTROYED:	ax, bx, cx 
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	12/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawMultipleLineSegments	proc	far	uses	bp, di, si
	.enter
EC <	tst	cx							>
EC <	ERROR_Z	-1							>
EC <	call	ECCheckIfInkObject					>

	dec	cx
	shl	cx, 1
	shl	cx, 1
.assert	size Point eq 4
	mov	bx, di
	add	bx, cx			;ES:BX <- ptr to last point
	xchg	di, bp			;ES:BP <- ptr to first point
					;DI <- gstate

	call	GrSaveState
	call	TranslateToInkOrigin
	call	GetStrokeWidthAndHeight	;AX <- brush width/height
	tst	dx
	jz	nextSegment

	push	dx
	mov_tr	dx, ax			;DX <- line width
	clr	dh
	clr	ax
	call	GrSetLineWidth
	pop	dx

nextSegment:
	mov	cx, 1
	mov	si, bp			;DS:SI <- ptr to start of this line seg
loopTop:

;	Scan for the end of the current line segment, then draw it.

EC <	tst	ds:[bp].P_y						>
EC <	ERROR_S	NEGATIVE_Y_COORDINATE					>
	tst	ds:[bp].P_x.high
	js	drawSegment
	inc	cx
	add	bp, size Point
	jmp	loopTop

drawSegment:
	andnf	ds:[bp].P_x, 0x7fff

;	If printing, we should call GrDrawPolyline. Else, we should call
;	GrBrushPolyline, as it is faster, and consistent with the IM ink
;	drawing method.

	tst	dx
	jnz	isPrinting
	call	GrBrushPolyline
common:
	ornf	ds:[bp].P_x, 0x8000

	add	bp, size Point
	cmp	bp, bx
	jbe	nextSegment
	call	GrRestoreState
	.leave
	ret
isPrinting:
	cmp	cx, 2				; if only two points, check
	je	maybeDot			;  for a single point
drawLines:
	call	GrDrawPolyline			
	jmp	common

	; GrDrawPolyline doesn't work for single dot (endpoints equal) as
	; it doesn't draw anything.  If this is the case, fill a rectangle.
maybeDot:
	mov	ax, ds:[si].P_x			; compare coords
	cmp	ax, ds:[si+(size Point)].P_x	;  if not same do normal
	jne	drawLines
	mov	ax, ds:[si].P_y			; compare coords
	cmp	ax, ds:[si+(size Point)].P_y	;  if not same do normal
	jne	drawLines
	push	bx,cx,dx
	call	GrSaveState
	call	GrGetLineColor
	mov	ah, CF_RGB
	call	GrSetAreaColor
	call	GrGetLineWidth			; dx = line width
	mov	ax, dx
	mov	bx, dx				; untransform width
	call	GrUntransform			; axbx = width,height
	movdw	cxdx, axbx			; save untransformed size
	clr	ax,bx
	call	GrUntransform
	sub	cx, ax
	sub	dx, bx
	mov	ax, ds:[si].P_x			; reload x coord
	mov	bx, ds:[si].P_y			; reload x coord
	add	cx, ax
	add	dx, bx				; cxdx = rightbottom coords
	call	GrFillRect
	call	GrRestoreState
	pop	bx,cx,dx
	jmp	common
DrawMultipleLineSegments	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws all the current line segments.

CALLED BY:	GLOBAL
PASS:		cl - DrawFlags
		bp - gstate to draw with
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDraw	method	dynamic InkClass, MSG_VIS_DRAW
	push	si
	xchg	bp, di
	call	GrSaveState

	clr	ah
	mov	al, ds:[bp].II_penColor
	call	GrSetLineColor

	call	SetClipRectToVisBounds

;	Draw the ink now - if we are printing or the appropriate attribute is
;	present, pass the "printing" flag to DrawMultipleLineSegments().

	tst	ds:[bp].II_segments
	jz	noInk
	mov	dx, -1
	test	cl, mask DF_PRINT
	jnz	10$
if 0
	mov	ax, ATTR_INK_DO_NOT_USE_GR_BRUSH_POLYLINE
	call	ObjVarFindData
	jc	10$
endif
	clr	dx
10$:

	push	si
	mov	si, ds:[bp].II_segments	;SI <- chunk array
	mov	bp, di			;BP <- gstate
	clr	ax
	call	ChunkArrayElementToPtr	;DI <- ptr to first element

	call	ChunkArrayGetCount	;CX <- # items in array
	pop	si
	jcxz	afterDraw

;	Draw the line segments

	segmov	es, ds			;DS:DI <- ptr to first line segment
					;BP <- gstate
					;DX <- non-zero if printing
					;CX <- # points to draw
	call	DrawMultipleLineSegments
afterDraw:
	mov	di, bp	
noInk:	
	call	GrRestoreState

	pop	si

;	Now, redraw the selection

	mov	bx, ds:[si]
	add	bx, ds:[bx].Ink_offset
	test	ds:[bx].II_flags, mask IF_HAS_SYS_TARGET
	jz	exit
	call	RedrawSelection
exit:
	ret
InkDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendInkControlGCNNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the GWNT_INK_HAS_TARGET notification.

CALLED BY:	GLOBAL
PASS:		bp - data to send out
		*ds:si - ink obj
RETURN:
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendInkControlGCNNotification	proc	near

;	Record event to send to ink controller

	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_INK_HAS_TARGET
	mov	di, mask MF_RECORD
	call	ObjMessage

	clr	bx
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_INK_STATE_CHANGE
	mov	ax, mask GCNLSF_SET_STATUS
	tst	bp
	jnz	10$
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:

;	Send it to the appropriate gcn list

	GOTO	SendToAppGCNList
SendInkControlGCNNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateEditControlStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine sends out the appropriate SELECT_STATE_CHANGE
		notification block depending upon the state of the ink object.

CALLED BY:	GLOBAL
PASS:		*ds:si - ink object
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateEditControlStatus	proc	far
	class	InkClass
EC <	call	ECCheckObject						>
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	test	ds:[di].II_flags, mask IF_HAS_TARGET
	jnz	sendMessage
	ret
sendMessage:
	push	es, si
	mov	ax, size NotifySelectStateChange
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK or mask HF_SHARABLE
	call	MemAlloc
	mov	es, ax
	mov	ax, 1
	call	MemInitRefCount

;	Determine whether or not there is any ink in the selected area.

	mov	es:[NSSC_selectionType], SDT_INK
	clr	es:[NSSC_clipboardableSelection]
	clr	es:[NSSC_deleteableSelection]

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	tst	ds:[di].II_segments
	jz	20$			;If no segment array, branch

	mov	ax, ds:[di].II_selectBounds.R_left
	cmp	ds:[di].II_selectBounds.R_right, ax
	je	20$

	mov	ax, ds:[di].II_selectBounds.R_top
	cmp	ds:[di].II_selectBounds.R_bottom, ax
	je	20$
	
	
	mov	es:[NSSC_clipboardableSelection], BB_TRUE	
	mov	es:[NSSC_deleteableSelection], BB_TRUE
20$:

	mov	es:[NSSC_pasteable], BB_FALSE
	mov	es:[NSSC_selectAllAvailable], BB_FALSE

;	Check if there is a CIF_INK clipboard format

	push	bx
	clr	bp
	call	ClipboardQueryItem		;If no normal transfer item,
	tst	bp				; branch.
	jz	30$
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, CIF_INK
	call	ClipboardTestItemFormat		;If there is an ink transfer
	jc	30$				; item, then say we can paste
	mov	es:[NSSC_pasteable], 0xff	;
30$:
	call	ClipboardDoneWithItem
	pop	bx
	pop	es, si
	call	MemUnlock
	call	SendEditControlGCNNotification
	ret
UpdateEditControlStatus	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendEditControlGCNNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the GWNT_SELECT_STATE_CHANGE notification.

CALLED BY:	GLOBAL
PASS:		bx - handle of block to send out
RETURN:		*ds:si - ink obj
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/27/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendEditControlGCNNotification	proc	near
	mov	bp, bx
	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_SELECT_STATE_CHANGE
	mov	di, mask MF_RECORD
	call	ObjMessage			;DI <- event handle

	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	mov	ax, mask GCNLSF_SET_STATUS
	tst	bx
	jnz	10$
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:

;	Send it to the appropriate gcn list

	FALL_THRU	SendToAppGCNList

SendEditControlGCNNotification	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendToAppGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the passed event/block to the passed gcn list

CALLED BY:	GLOBAL
PASS:		bx - handle to send (0 if none)
		di - event
		ax - GCNListSendFlags		
		ds - segment of InkObject
		cx, dx - event type
RETURN:		nada
DESTROYED:	ax, bx, cx, dx, bp, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/31/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendToAppGCNList	proc	near
	.enter
	sub	sp, size GCNListMessageParams
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, cx
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, dx
	mov	dx, size GCNListMessageParams
	mov	ss:[bp].GCNLMP_block, bx
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax
	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx
	.leave
	ret
SendToAppGCNList	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateRoomForSegments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates room in the segment array for the passed # segments

CALLED BY:	GLOBAL
PASS:		cx - # segments to add
		*ds:si - ink object
RETURN:		ds:di - ptr to beginning of added room
		cx - # segments in array before call
DESTROYED:	ax
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateRoomForSegments	proc	far		uses	dx, bp
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>
	mov_tr	ax, cx
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	cx, ds:[di].II_segments
	tst	cx
	jnz	10$

;	If there is no chunk array yet, create one

	push	ax, bx, si

	mov	bx, size Point
	clr	cx
	clr	si
	mov	al, mask OCF_DIRTY
	call	ChunkArrayCreate
	mov	cx, si
	pop	ax, bx, si

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ds:[di].II_segments, cx
	call	ObjMarkDirty
10$:

;	Get current # segments

	push	si
	mov	si, cx
EC <	tst	si							>
EC <	ERROR_Z	-1							>
	call	ChunkArrayGetCount
	pop	si

	push	cx		;Save old # line segments
	mov	dx, cx

;	Re allocate the segment array to hold the max possible line segments

	push	ax				;save # points
	mov	bp, ds:[di].II_segments
	mov	bp, ds:[bp]
	ChunkSizePtr	ds, bp, cx

	shl	ax, 1
	shl	ax, 1
	add	cx, ax			;CX <- new size
	mov	ax, ds:[di].II_segments	;
	call	LMemReAlloc
	
;	Add points to object

	mov_tr	di, ax				;
	mov	di, ds:[di]			;DS:DI <- ptr to segment array
	pop	cx
	add	ds:[di].CAH_count, cx
	add	di, ds:[di].CAH_offset		;
	shl	dx, 1				;
	shl	dx, 1				;
	add	di, dx				;DS:DI <- ptr to store next
						; Point structure
	pop	cx
	.leave
	ret
CreateRoomForSegments	endp

if 	ERROR_CHECK
ECCheckIfInkObject	proc	far	uses	es, di
	.enter
	mov	di, segment InkClass
	mov	es, di
	mov	di, offset InkClass					
	call	ObjIsObjectInClass					
	ERROR_NC	-1
	.leave
	ret								
ECCheckIfInkObject	endp
endif	;ERROR_CHECK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current tool for the ink object.

CALLED BY:	GLOBAL
PASS:		CX - InkTool
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
		This does not currently set the object dirty - should it?

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetTool	method	dynamic  InkClass, MSG_INK_SET_TOOL
EC <	cmp	cx, InkTool						>
EC <	ERROR_AE	BAD_TOOL					>

	cmp	cx, IT_SELECTOR
	je	5$
	call	NukeSelection
if 0
	mov	ax, MSG_GEN_VIEW_SET_PTR_IMAGE
	clr	cx
	clr	dx
	mov	bp, PIL_GADGET
	clr	di
	call	CallToView
endif
5$:
	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ds:[di].II_tool, cx
	test	ds:[di].II_flags, mask IF_ONLY_CHILD_OF_CONTENT
	jz	10$			;Branch to skip optimization.
	call	SetInkDestination
10$:
	ret
InkSetTool	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetTool
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Gets the current tool for the ink object.
CALLED BY:	GLOBAL
PASS:		*ds:si	= InkClass object
		ds:di	= InkClass instance data
		ds:bx	= InkClass object (same as *ds:si)
		es 	= segment of InkClass
		ax	= message #
RETURN:		CX - InkTool
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	5/18/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetTool	method dynamic InkClass, MSG_INK_GET_TOOL
	.enter

	mov	cx, ds:[di].II_tool

EC <	cmp	cx, InkTool						>
EC <	ERROR_AE	BAD_TOOL					>

	.leave
	ret
InkGetTool	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetPenColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current pen color for the ink object.

CALLED BY:	GLOBAL
PASS:		CL - Color
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetPenColor	method	dynamic  InkClass, MSG_INK_SET_PEN_COLOR
	call	ObjMarkDirty
	mov	ds:[di].II_penColor, cl
	test	ds:[di].II_flags, mask IF_ONLY_CHILD_OF_CONTENT
	jz	inval
	call	SetInkDestination
inval:
	call	InvalidateIfDrawable
	ret
InkSetPenColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSetDirtyAD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the AD to be activated when the object is dirtied

CALLED BY:	GLOBAL
PASS:		BP - method
		CX:DX - optr
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/24/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSetDirtyAD	method	dynamic InkClass, MSG_INK_SET_DIRTY_AD
	call	ObjMarkDirty
	mov	ds:[di].II_dirtyMsg, bp
	movdw	ds:[di].II_dirtyOutput, cxdx
	ret
InkSetDirtyAD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClipRectToVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets a clip rect of our vis bounds.

CALLED BY:	GLOBAL
PASS:		di - gstate
		*ds:si - VisObject
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetClipRectToVisBounds	proc	far	uses	si, ax, bx, cx, dx
	.enter
	call	VisGetBounds
	mov	si, PCT_INTERSECTION
	call	GrSetWinClipRect
	.leave
	ret
SetClipRectToVisBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkNotifyRedisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	redraws the ink in response to a general notification
		that ink should be redrawn.

CALLED BY:	MSG_NOTIFY_INK_REDISPLAY
PASS:		*ds:si	= InkClass object
		ds:di	= InkClass instance data
		ds:bx	= InkClass object (same as *ds:si)
		es 	= segment of InkClass
		ax	= message #
RETURN:		none
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	4/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkNotifyRedisplay	method dynamic InkClass, 
					MSG_NOTIFY_INK_REDISPLAY
	.enter
	call	InvalidateIfDrawable
	.leave
	ret
InkNotifyRedisplay	endm


InkCommon	ends


InkFile		segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InputDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the passed delta based on the compacted bit stream

CALLED BY:	GLOBAL
PASS:		es,bp,ax - arguments for InputBit/InputBits macros
		dx - current point value 
		ds:di - ptr to store data out
			(used if we read in a "terminate segment" opcode)

RETURN:		dx - updated point value
		es,bp,ax - possibly changed by InputBit/InputBits macros
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InputDelta	proc	near	uses	bx, cx
	.enter
processInput:
	clr	bx
	InputBits	bl, 2
	cmp	bl, 00000001b		;00,01,11 values mean add 0,1,-1 to
	ja	10$			; delta
	add	dx, bx
	jmp	exit
10$:
	cmp	bl, 00000011b
	jne	20$
	dec	dx
	jmp	exit
20$:
	InputBit
	jc	absoluteOrKeyword

;	First 3 bits are 100 - next 4 are signed delta

	clr	bx
	InputBits	bl, 4

	test	bl, 00001000b
	jz	positiveDelta

;	4th bit is 1, subtract remaining 3 bits (+1)

EC <	cmp	bl, 00001000b						>
EC <	ERROR_Z	RESERVED_OPCODE_ENCOUNTERED				>


	andnf	bl, 00000111b
	inc	bl
	sub	dx, bx
	jmp	exit

positiveDelta:
	tst	bl
	jz	doTerminateSegment
	inc	bx
	add	dx, bx
	jmp	exit

doTerminateSegment:
	ornf	ds:[di - (size Point)].P_x, 0x8000
	jmp	processInput

absoluteOrKeyword:
	InputBit
	jnc	isKeyword

;	Else, first 4 bits are 1011 - read next 15 bits as absolute position

	clr	dx
	InputBits	dx, 15
exit:
	.leave
	ret

isKeyword:

;	First 4 bits are 1010 - read in keyword

	InputBits	bl, 6		;Read in keyword
;
;	Process keyword here
;
	jmp	processInput
InputDelta	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendDataFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Appends ink data from the file

CALLED BY:	GLOBAL
PASS:		bx - file handle
		cx, dx - x, y offset to start load at
		ax.di - db item group
		bp - offset into db item group where data lies
		*ds:si - ink object
RETURN:		nada
DESTROYED:	nothing
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/ 9/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AppendDataFromFile	proc	far	uses	ax, bx, cx, dx, bp, di, es
	.enter
;
;	First, get a ptr to / size of the data.
;

	call	DBLock			;Lock down the DB item

	mov	di, es:[di]
EC <	ChunkSizePtr	es, di, bx					>
EC <	add	bx, di							>

	add	di, bp			;ES:DI <- ptr to # ink points
					; (followed by ink data)

	mov_tr	ax, cx			;Save X coord
	mov	cx, es:[di]		;CX <- # points to add
	jcxz	exit			;Exit if no points to add

	push	dx			; Save YOffset
	push	ax			; Save XOffset
	push	cx			;Save # points to add

	call	GetNumPoints	        ; ax <- # existing points
	add	ax, cx			; ax <- # old+new points
	call	GetMaxNumPoints		; dx <- max points
	cmp	ax, dx
	jae	tooManyPoints

	add	di, size word
	mov	bp, di			;ES:BP <- next point to add

;	Create room for the points

	call	CreateRoomForSegments	;DS:DI <- ptr to data to store
	pop	ax			;AX <- # points to add
	pop	cx			;CX <- XOffset to load data
	pop	dx			;DX <- YOffset to load data

	call	UncompactData

exit:
	call	DBUnlock
	.leave
	ret

tooManyPoints:
	mov	cx, offset BadInk
	call	PutupErrorDialog

	pop	ax, ax, ax
	jmp	exit
	
AppendDataFromFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkLoadFromDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads the saved data from the passed DB item

CALLED BY:	GLOBAL
PASS:		ss:bp - InkDBFrame
RETURN:		nada
DESTROYED:	ax, cx, dx, bp
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SEGMENT_TERMINATOR		equ	01000000b
SEGMENT_TERMINATOR_LEN		equ	7

InkLoadFromDBItem	method	dynamic InkClass, MSG_INK_LOAD_FROM_DB_ITEM

	call	NukeSelection

;	Clear out the old data first.

	call	FreeInkData

	tstdw	ss:[bp].IDBF_DBGroupAndItem
	jz	exit

;	Copy the data in from the file.

	mov	bx, ss:[bp].IDBF_VMFile
	movdw	axdi, ss:[bp].IDBF_DBGroupAndItem
	mov	cx, ss:[bp].IDBF_bounds.R_left
	mov	dx, ss:[bp].IDBF_bounds.R_top
	mov	bp, ss:[bp].IDBF_DBExtra
	call	AppendDataFromFile

exit:
	clr	cx
	mov	dx, mask IF_DIRTY			;Set item clean
	mov	ax, MSG_INK_SET_FLAGS
	call	ObjCallInstanceNoLock
	call	InvalidateIfDrawable
	ret
InkLoadFromDBItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FigureCompactSizeCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine that determines the size of the data
		space needed for the compacted line segments

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to Point structure
		cx, dx - previous point
		BP:AX <- # bits that would be stored out to this point
RETURN:		cx, dx - this point
		BP:AX <- # bits that would be stored out (cumulative)
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
	Compaction scheme is like this:
		curX = Point.X & 0x7fff
		curY = Point.Y
		deltaX = prevX-curX;
		deltaY = prevY-curY;
		OutputDelta (deltaX)
		OutputDelta (deltaY);
		If (Point.X & 0x8000)
			Output (SEGMENT_TERMINATOR)	;Segment terminator

		end;

	OutputDelta (delta):

	if (delta == 0) 
		Output (00)
	else if (delta == 1)
		Output (01)
	else if (delta == -1)
		Output (11)
	else if (delta >= -8 && delta < -1) /* Output 3-bit negative delta */
		Output (1001000 | (ABS(delta) - 1))
	else if (delta <= 8 && delta > 1) /* Output 3-bit positive delta */
		Output (1000000 | (delta - 1))
	else	/* Output 15-bit absolute position) */
		Output (1011 0000 0000 0000 000 | delta);


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FigureCompactSizeCallback	proc	near
	mov	bx, ds:[di].P_y
	mov	di, ds:[di].P_x
	tst	di
	jns	5$
	adddw	bpax, SEGMENT_TERMINATOR_LEN
					;Store out 7 bit segment terminator
5$:
	andnf	di, 0x7fff		;Nuke high bit
	xchg	di, cx
	xchg	bx, dx
	sub	di, cx
	jns	10$
	neg	di
10$:
	sub	bx, dx
	jns	20$
	neg	bx
20$:
	cmp	di, 1
	jbe	tinyXDelta
	cmp	di, 8
	jbe	smallXDelta
	adddw	bpax, 12		;4 bit prologue + 15 bit abs value
smallXDelta:
	adddw	bpax, 5			;7 bit delta (5 + 2)	
tinyXDelta:
	adddw	bpax, 2

	cmp	bx, 1
	jbe	tinyYDelta
	cmp	bx, 8
	jbe	smallYDelta
	adddw	bpax, 12		;4 bit prologue + 15 bit abs value
smallYDelta:
	adddw	bpax, 5			;7 bit delta (5 + 2)	
tinyYDelta:
	adddw	bpax, 2
	clc
	ret
FigureCompactSizeCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OutputDelta
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine outputs a stream of bits that represent the
		passed delta according to the passed algorithm:
	if (delta == 0) 
		Output (00)
	else if (delta == 1)
		Output (01)
	else if (delta == -1)
		Output (11)
	else if (delta >= -8 && delta < -1) /* Output 3-bit negative delta */
		Output (1001000 | (ABS(delta) - 1))
	else if (delta <= 8 && delta > 1) /* Output 3-bit positive delta */
		Output (1000000 | (delta - 1))
	else	/* Output 15-bit absolute position) */
		Output (1011 0000 0000 0000 000 | delta);

CALLED BY:	GLOBAL
PASS:		bx - delta
		cx - absolute position
		al, es, bp - info used by OutputBit(s) macros
		ds:di - ptr to current point
RETURN:		nada
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	11/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
OutputDelta	proc	near	uses	dx
	.enter
	mov	dx, cx
	cmp	bx, 1
	jbe	10$
	cmp	bx, -1
	jne	20$
10$:
	mov	cl, 6		;Output 2-bit signed value (-1, 0, 1)
	shl	bl, cl		;Shift 2 low bits to be in high position
	OutputBits	bl, 2	;Output 2 high bits
	jmp	exit
20$:
	mov	cl, 01000000b
	jg	isPositive
	mov	cl, 01001000b
	neg	bx
isPositive:
	cmp	bx, 8
	ja	outputAbsolutePosition
	dec	bx
	or	bl, cl		;Output (100X000 | (delta - 1))
	shl	bl, 1
	OutputBits	bl, 7
exit:
	.leave
	ret
outputAbsolutePosition:

;		Output (1011 0000 0000 0000 000 | delta);

	mov	bl, 10110000b
	OutputBits	bl, 4
	shl	dx, 1
	OutputBits	dx, 15
	jmp	exit
OutputDelta	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompactDataCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine that determines the size of the data
		space needed for the compacted line segments

CALLED BY:	GLOBAL
PASS:		ds:di - ptr to Point structure
		cx, dx - previous point
		al - current bit mask we are building out
		ES:BP - place to write data
RETURN:		cx, dx - this point
		ES:BP - updated to point to where to store more data
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:
	Compaction scheme is like this:
		curX = Point.X & 0x7fff
		curY = Point.Y
		deltaX = prevX-curX;
		deltaY = prevY-curY;
		OutputDelta (deltaX)
		OutputDelta (deltaY);
		If (Point.X & 0x8000)
			Output (SEGMENT_TERMINATOR)	;Segment terminator

		end;

	OutputDelta (delta):

	if (delta == 0) 
		Output (00)
	else if (delta == 1)
		Output (01)
	else if (delta == -1)
		Output (11)
	else if (delta >= -8 && delta < -1) /* Output 3-bit negative delta */
		Output (1001000 | (ABS(delta) - 1))
	else if (delta < 8 && delta > 1) /* Output 3-bit positive delta */
		Output (1000000 | (delta - 1))
	else	/* Output 15-bit absolute position) */
		Output (1011 0000 0000 0000 000 | delta);

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CompactDataCallback	proc	near

PrintMessage <Andrew - add code to determine when to insert "scale" keywords>
	mov	bx, ds:[di].P_x
	andnf	bx, 0x7fff
	sub	bx, cx
	mov	cx, ds:[di].P_x
	call	OutputDelta

	mov	bx, ds:[di].P_y
	sub	bx, dx
	mov	cx, ds:[di].P_y
EC <	tst	cx							>
EC <	ERROR_S	NEGATIVE_Y_COORDINATE					>
	call	OutputDelta
	tst	ds:[di].P_x
	jns	exit

;	Output a segment terminator

	mov	bl, SEGMENT_TERMINATOR shl 1
	OutputBits bl, SEGMENT_TERMINATOR_LEN
exit:
	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y
	andnf	cx, 0x7fff
	clc
	ret
CompactDataCallback	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls passed callback routine on each point in block

CALLED BY:	GLOBAL
PASS:		bx - offset to routine in this segment
		ax, cx, dx, bp, es - data for callback routine
		ds:si - ptr to Point data

RETURN:		same as ChunkArrayEnum
DESTROYED:	di, bx
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoCallback	proc	near	uses	si
	class	InkClass
	.enter

;	Call the passed callback routine once for each point in the
;	array.

	mov	si, ds:[PBH_numPoints]
	tst	si
	jz	exit	
	mov	di, size word		;DS:DI <- ptr to data
top:
	push	bx, di, si
	call	bx
	pop	bx, di, si
	jc	exit
	add	di, size Point
	dec	si
	jnz	top
exit:
	.leave
	ret
DoCallback	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeCompactedSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes the # bytes required to save the passed points.

CALLED BY:	GLOBAL
PASS:		ds - ptr to points
		cx - # points
RETURN:		nada
DESTROYED:	ax, bx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeCompactedSize	proc	near	uses	cx, dx, bp
	.enter
	clrdw	bpax				;BP:AX = # bits that should
						; be stored out
	mov	cx, 0x7fff
	mov	dx, cx
	mov	bx, offset FigureCompactSizeCallback
	call	DoCallback			;BP:AX <- # bits in data size
	adddw	bpax, 7
	shrdw	bpax
	shrdw	bpax
	shrdw	bpax				;BP:AX <- # bytes in data size
EC <	tst	bp							>
EC <	ERROR_NZ	BAD_DATA_SIZE					>
	
	.leave
	ret
ComputeCompactedSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCompactedPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the compacted points out

CALLED BY:	GLOBAL
PASS:		ds - block containing points
		ax.di - DB Item to save to
		ss:bp - InkDBFrame
RETURN:		nada
DESTROYED:	bx, cx, dx, bp, si
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveCompactedPoints	proc	near	uses	ax, di
	.enter
	call	DBLock			;Lock down the DB item
	call	DBDirty			;*ES:DI <- ptr to item to fill with
					; data
	mov	bp, ss:[bp].IDBF_DBExtra
	add	bp, es:[di]		;ES:BP <- ptr to store data
	mov	cx, ds:[PBH_numPoints]
	mov	es:[bp], cx		;
	jcxz	unlockExit		;If no points, exit

EC <	ChunkSizeHandle	es, di, cx					>
EC <	add	cx, es:[di]						>
EC <	push	cx							>

	add	bp, size word		;ES:BP <- ptr to where to store 
					; compacted segments
	mov	cx, 0x7fff
	mov	dx, cx
	mov	al, 0x01
	mov	bx, offset CompactDataCallback
	call	DoCallback

;	Move bits in last byte to be high order bits.

	cmp	al, 1
	je	atByteEnd
doShift:
	shl	al, 1
	jnc	doShift
	mov	es:[bp], al
EC <	inc	bp							>
atByteEnd:

EC <	pop	cx							>
EC <	cmp	cx, bp							>
EC <    ERROR_NZ	SIZE_OF_INK_DATA_DID_NOT_MATCH_COMPUTED_SIZE	>
unlockExit:
	call	DBUnlock
	.leave
	ret
SaveCompactedPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetInkInBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine scans through all of the ink in the object,
		clips the points to the passed bounds, and stores the result
		to a returned block.

CALLED BY:	GLOBAL
PASS:		ss:bp - InkDBFrame
		*ds:si - Ink object
RETURN:		bx - handle of block with clipped points
		ds - segment of block with points
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	9/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetInkInBounds	proc	near
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>

;	Allocate a block large enough to hold 1.5 times as many points as
;	there are in the object (this is because we can conceivably have to
;	add points when we clip the line segments to the passed bounds).

	mov	si, ds:[si]
	add	si, ds:[si].Ink_offset
	mov	si, ds:[si].II_segments
	clr	cx
	tst	si
	jz	alloc
	call	ChunkArrayGetCount		;CX <- # items in array
alloc:
	mov	ax, cx
	shr	ax, 1
	add	ax, cx				;AX <- 1.5 * # points in array
	push	cx				;Save # points


.assert size Point eq 4

	shl	ax, 1				;AX = size of block in bytes
	shl	ax, 1				
	add	ax, size PointBlockHeader
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAlloc
	mov	es, ax				;ES <- dest for block
	pop	cx
	clr	es:[PBH_numPoints]		;Init # points in block
	jcxz	exit

	mov	si, ds:[si]
	add	si, ds:[si].CAH_offset		;DS:SI <- source array
	mov	di, size word			;ES:DI <- dest array
	
	call	ClipPointsToClipRect			;
exit:
	segmov	ds, es
	.leave
	ret
GetInkInBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the ink out to a DB item.

CALLED BY:	GLOBAL
PASS:		ss:bp - InkDBFrame
RETURN:		ax.bp - DB Group/item
DESTROYED:	bx, cx, dx, di
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	8/ 4/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveInk	proc	far	uses	es, ds, si
	class	InkClass
	.enter
EC <	call	ECCheckIfInkObject					>

;	First, we create a block containing all of the points that were in
;	the bounds (we clip the ink to the passed bounds).
;
;	Then, we figure out the size of the points after they've been
;	compacted, allocate a DBItem that will be large enough, then
;	compact the points into the DBItem.
;	

	call	GetInkInBounds		;Returns BX = block handle
	call	SaveCompactedInkToDBItem


	mov	bp, di			;AX.BP <- VM Chain containing data

					;Free up the block containing the
	call	MemFree			; points.
	.leave
	ret
SaveInk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SaveCompactedInkToDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compacts the ink and saves it to a DBItem

CALLED BY:	GLOBAL
PASS:		ds    - segment w/points (including PointBlockHeader)
		ss:bp - InkDBFrame
RETURN:		ax.di - VMChain containing data
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SaveCompactedInkToDBItem	proc	near	uses	bx, cx, dx
	.enter

	call	ComputeCompactedSize	;AX <- # bytes of compacted data

	add	ax, 2				;Add one more word for # data
						; points

;	Create a DBItem large enough to hold the compacted data and any extra
;	space requested by the caller.

	mov_tr	cx, ax
	mov	bx, ss:[bp].IDBF_VMFile
	movdw	axdi, ss:[bp].IDBF_DBGroupAndItem
	add	cx, ss:[bp].IDBF_DBExtra
	tst	di
	jne	noCreate
	tst	ax
	jnz	alloc
	mov	ax, DB_UNGROUPED
alloc:
	call	DBAlloc
	jmp	storeData
noCreate:
	call	DBReAlloc
storeData:

	call	SaveCompactedPoints	;
	.leave
	ret
SaveCompactedInkToDBItem	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkCompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compresses ink

CALLED BY:	GLOBAL
PASS:		cx - handle of block with ink data
		bx - file in which to create DBItem
		ax:di - DBItem to hold data
RETURN:		ax.di - DBItem
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkCompress	proc	far		uses	bx, ds, bp
	.enter
	sub	sp, size InkDBFrame
	mov	bp, sp
	mov	ss:[bp].IDBF_VMFile, bx
	movdw	ss:[bp].IDBF_DBGroupAndItem, axdi
	clr	ss:[bp].IDBF_DBExtra
	mov	bx, cx
	call	MemLock
	mov	ds, ax
	call	SaveCompactedInkToDBItem
	call	MemUnlock
	add	sp, size InkDBFrame
	.leave
	ret
InkCompress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UncompactData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Uncompacts the ink data and stores it out

CALLED BY:	GLOBAL
PASS:		ax - num points
		cx, dx - offset to load data at (will add this to each ink
			 point)
		es:bp - ptr to compacted ink data
		ds:di - ptr to store uncompacted data
EC ONLY:	es:bx - ptr after end of compacted data
			(used for error checking)
RETURN:		ds:di - ptr to last point 
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UncompactDataStack	struct
	UDS_oldSI	word
EC <	UDS_size	word						>
	UDS_yOffset	word
	UDS_xOffset	word
UncompactDataStack	ends

UncompactData	proc	near	uses	ax, bp
	.enter
	push	cx
	push	dx
EC <	push	bx							>
	push	si
	mov	si, sp			;SS:SI <- UncompactDataStack

	mov_tr	cx, ax			;CX <- # points

;	Un-compress the data and add it to the object

	mov	ah, 7			;Init AH for use in InputBit macro
	mov	al, es:[bp]

10$:
EC <	cmp	bp, ss:[si].UDS_size				>
EC <	ERROR_AE INK_DATA_READ_BEYOND_END_OF_BLOCK		>

;
;	Sit in a loop and add each point to the array
;	ES:BP,AX <- used by "InputBit(s)" macro
;	CX <- # points left to add
;	ds:di - ptr to store data out to
;	BX,DX <- prev X,Y coordinates stored out (not used on first time
;		 through loop).
;

	xchg	dx, bx
	call	InputDelta
	add	dx, ss:[si].UDS_xOffset
	mov	ds:[di].P_x, dx
	sub	dx, ss:[si].UDS_xOffset
	xchg	dx, bx
	call	InputDelta
	add	dx, ss:[si].UDS_yOffset
	mov	ds:[di].P_y, dx
	sub	dx, ss:[si].UDS_yOffset
	add	di, size Point
	loop	10$
	ornf	ds:[di - (size Point)].P_x, 0x8000 ;Terminate the last segment

EC < 	push	si							>
EC <	mov	si, di							>
EC <	sub	si, size Point						>
EC <	call	ECCheckBounds						>
EC <	pop	si							>

	pop	si
EC <	pop	bx							>
	pop	dx							
	pop	cx							
	.leave
	ret
UncompactData	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkDecompress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decompresses ink

CALLED BY:	GLOBAL
PASS: 		bx - file handle
		ax:di - DBItem to hold data
RETURN:		bx - handle of block containing data
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	5/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkDecompress	proc	far	uses	ax, cx, dx, bp, ds, es, di
	.enter
	call	DBLock
	mov	di, es:[di]
	mov	ax, es:[di]			;AX <- # points

.assert size Point eq 4
	shl	ax
	shl	ax				;AX = size of buffer to hold
						; data
	add	ax, size PointBlockHeader	;

;	Allocate a block large enough to hold the data

	mov	cx, ALLOC_DYNAMIC_LOCK or mask HF_SHARABLE
	call	MemAlloc
	jc	errorExit

;	

EC <	push	bx				;Save handle of data	>

EC <	ChunkSizePtr	es, di, bx					>
EC <	add	bx, di							>
						;BX <- size of data
	mov	ds, ax
	mov	ax, es:[di]
	add	di, size word
	mov	ds:[PBH_numPoints], ax		;
	tst	ax			;AX = # points to add
	jz	unlockExit		;Exit if no points to add
	clr	cx				;Load data at offset 0,0
	clr	dx				;

	mov	bp, di				;ES:BP <- ptr to compacted ink
	mov	di, size PointBlockHeader	;DS:DI <- ptr to store 
						; uncompacted ink
	call	UncompactData
EC <	pop	bx							>

unlockExit:
	call	MemUnlock			;
exit:
	call	DBUnlock
	.leave
	ret
errorExit:
	clr	bx
	jmp	exit
InkDecompress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkSaveToDBItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves the saved data to the passed DB item

CALLED BY:	GLOBAL
PASS:		ss:bp - InkDBFrame
RETURN:		ax.bp - DB group/item written to
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkSaveToDBItem	method	dynamic InkClass, MSG_INK_SAVE_TO_DB_ITEM

;	Mark the object as clean (the data on disk matches the data here)

	clr	cx
	mov	dx, mask IF_DIRTY
	mov	ax, MSG_INK_SET_FLAGS
	call	ObjCallInstanceNoLock

	call	SaveInk

	ret
InkSaveToDBItem	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateInkTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates an ink transfer format

CALLED BY:	GLOBAL
PASS:		bx - file to create it in
		*ds:si - ink object
RETURN:		ax.di - ink transfer format
DESTROYED:	nada
 
PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	6/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateInkTransferFormat	proc	near	uses	bx, cx, dx, bp, es
	class	InkClass
	.enter

EC <	call	ECCheckIfInkObject					>

;	Get the ink data out of the object and into the clipboard object

	push	bx
	sub	sp, size InkDBFrame
	mov	bp,sp
	mov	ss:[bp].IDBF_VMFile, bx
	clrdw	ss:[bp].IDBF_DBGroupAndItem	;Create new vm chain
	mov	ss:[bp].IDBF_DBExtra, size XYSize

	mov	di, ds:[si]
	add	di, ds:[di].Ink_offset
	mov	ax, ds:[di].II_selectBounds.R_left
	mov	ss:[bp].IDBF_bounds.R_left, ax
	mov	ax, ds:[di].II_selectBounds.R_top
	mov	ss:[bp].IDBF_bounds.R_top, ax
	mov	ax, ds:[di].II_selectBounds.R_right
	mov	ss:[bp].IDBF_bounds.R_right, ax
	mov	ax, ds:[di].II_selectBounds.R_bottom
	mov	ss:[bp].IDBF_bounds.R_bottom, ax
	call	SaveInk
	add	sp, size InkDBFrame
	pop	bx

;	Set the width/height of the ink

	mov	di, bp				;AX.DI <- InkTransferFormat
	pushdw	axdi
	call	DBLock
	mov	di, es:[di]

	mov	bx, ds:[si]
	add	bx, ds:[bx].Ink_offset
	mov	ax, ds:[bx].II_selectBounds.R_right
	sub	ax, ds:[bx].II_selectBounds.R_left
	mov	es:[di].XYS_width, ax
	mov	ax, ds:[bx].II_selectBounds.R_bottom
	sub	ax, ds:[bx].II_selectBounds.R_top
	mov	es:[di].XYS_height, ax
	call	DBDirty
	call	DBUnlock
	popdw	axdi				;AX.DI <- db item
	.leave
	ret
CreateInkTransferFormat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Copy the selected area to the clipboard
CALLED BY:	
PASS:		*ds:si	= InkClass object
		ds:di	= InkClass instance data
		ds:bx	= InkClass object (same as *ds:si)
		es 	= segment of InkClass
		ax	= message #
RETURN:		carry set if the copy was unsuccessful for any reason
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JT	3/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkCopy	method dynamic InkClass, MSG_META_CLIPBOARD_COPY
	.enter

	test	ds:[di].II_flags, mask IF_SELECTING
	LONG jnz	exit
	call	ClipboardGetClipboardFile

;	Create a new clipboard item

	clr	ax
	mov	cx, size ClipboardItemHeader
	call	VMAlloc

	push	ax
	call	VMLock
	mov	es, ax

;	Copy the name of the item in

	push	bx,ds,si
	mov	di, offset CIH_name		;es:di = dest
	mov	bx, handle InkCopyName
	call	MemLock				;Lock the strings resource
	mov	ds, ax
	mov	si, ds:[InkCopyName]
	ChunkSizePtr	ds, si, cx
	rep	movsb
	call	MemUnlock			;Unlock the strings resource
	pop	bx,ds,si

;	Copy the data into the file

	mov	es:[CIH_formatCount],1
	clr	es:[CIH_flags]
	mov	es:[CIH_formats.CIFI_format.CIFID_manufacturer], \
		MANUFACTURER_ID_GEOWORKS
	mov	es:[CIH_formats.CIFI_format.CIFID_type], CIF_INK

	call	CreateInkTransferFormat
	movdw	es:[CIH_formats.CIFI_vmChain], axdi
	
	call	VMDirty				;Unlock the ClipboardItemHeader
	call	VMUnlock


;	Register this new item

	clr	bp
	pop	ax				;Restore vm block handle of
						; ClipboardItemHeader
	call	ClipboardGetClipboardFile
	call	ClipboardRegisterItem
exit:
	.leave
	ret
InkCopy	endm

InkFile		ends

	SetGeosConvention
C_Pen	segment	resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkCompress

C DECLARATION:	extern DBGroupAndItem 
		_pascal InkCompress (Point *inkData, word numPoints, 
				VMFileHandle file, DBGroupAndItem destItem);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKCOMPRESS		proc	far	inkData:hptr, file:hptr, dbItem:dword
	uses	ds, si, di
	.enter
	mov	cx, inkData
	mov	bx, file
	movdw	axdi, dbItem
	call	InkCompress
	mov_tr	dx, ax			;DX.AX - DBGroupAndItem
	mov_tr	ax, di
	.leave
	ret
INKCOMPRESS	endp


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkDecompress

C DECLARATION:	extern DBGroupAndItem 
		_pascal InkDecompress (VMFileHandle file, 
					DBGroupAndItem srcItem);

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	AS	6/19/92		Initial version

------------------------------------------------------------------------------@
INKDECOMPRESS		proc	far	file:hptr, dbItem:dword
	uses	di
	.enter
	mov	bx, file
	movdw	axdi, dbItem
	call	InkDecompress
	mov_tr	ax, bx			;BX <- data
	.leave
	ret
INKDECOMPRESS	endp

C_Pen	ends
	SetDefaultConvention



InkCommon	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkGetBoundsInDigitizerCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the bounds of a vis object in absolute digitizer
		coordinates.
		
CALLED BY:	(GLOBAL)
PASS:		^lbx:si - optr of vis object
RETURN:		carry	- set if unable to convert bounds to digitizer
			  coordinates
		if carry is clear:
			ax = left bound
			bx = top bound
			cx = right bound
			dx = bottom bound
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
	1) Get the bounds of the vis object in document coords
	2) Convert the document coords to screen coords
	3) Convert the screen coords to digitizer coords

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkGetBoundsInDigitizerCoords	proc	far

if INK_DIGITIZER_COORDS

	uses	di,si,ds,bp
	.enter

	;
	; Get the bounds of the vis object in document coords
	;
	Assert	objectOD bxsi, VisClass
	mov	ax, MSG_VIS_GET_BOUNDS
	mov	di, mask MF_CALL
	call	ObjMessage
		; ax, bp, cx, dx <- bounds in document coordinates

	;
	; Convert the document coords to screen coords
	;
	push	ax, bp		; push the left & top bounds
	push	cx, dx		; push the right & bottom bounds
	mov	ax, MSG_VIS_QUERY_WINDOW
	mov	di, mask MF_CALL
	call	ObjMessage	; ax, dx, bp - destroyed
		; cx - window handle
	mov	di, cx		; di <- window handle

	pop	ax, bx		; ax, bx <- right & bottom bounds
	call	WinTransform
	mov_tr	cx, ax
	mov	dx, bx	; cx, dx <- right & bottom bounds in screen coords

	pop	ax, bx		; ax, bx <- left & top bounds
	jc	exit		; check for error after the pop
	call	WinTransform
	jc	exit
			; ax, bx <- left & top bounds in screen coords

	;
	; Convert the screen coords to digitizer coords
	;
	mov	di, DR_MOUSE_ESC_SCREEN_COORDS_TO_MOUSE_COORDS
	call	CallMouseStrategy
		; carry set if no mouse driver or function not supported
exit:
	.leave
	ret
else
	; Degenerate case if INK_DIGITIZER_COORDS not defined
	stc
	ret

endif ; INK_DIGITIZER_COORDS

InkGetBoundsInDigitizerCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallMouseStrategy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the mouse driver strategy

CALLED BY:	(INTERNAL) InkGetBoundsInDigitizerCoords
PASS:		di - MouseFunction to call
		others - arguments to pass MouseFunction
RETURN:		carry set if no mouse driver loaded
		whatever MouseFunction returns
DESTROYED:	whatever MouseFunction destroys

SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/ 3/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if INK_DIGITIZER_COORDS
CallMouseStrategy	proc	near
		uses	ds, si
		.enter
	;
	; save the args to the strategy call
	;
		push	ax, bx
	;
	; get the mouse handle
	;
		mov	ax, GDDT_MOUSE
		call	GeodeGetDefaultDriver
	;
	; bail if there's none
	;
		tst	ax
		jz	noMouseDriver
	;
	; get the strategy and call it
	;
		mov_tr	bx, ax
		call	GeodeInfoDriver
		pop	ax, bx
		call	ds:[si].DIS_strategy

exit:
		.leave
		ret
noMouseDriver:
		pop	ax, bx
		stc
		jmp	exit

CallMouseStrategy	endp
endif ; INK_DIGITIZER_COORDS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InkClipDigitizerCoordsInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clip the digitizer ink to the passed absolute digitizer
		bounds by discarding points that lie outside the bounds.

		If an ink stroke is completely outside the clip bounds, it
		is discarded. This routine assumes the Y digitizer values
		increase from bottom to top and the X digitizer values
		increase from left to right.

CALLED BY:	(GLOBAL)
PASS:		bp - handle of InkDigitizerCoordsHeader data block
		ax - left bound
		bx - top bound
		cx - right bound
		dx - bottom bound
RETURN:		carry set if clipping failed
DESTROYED:	nothing
SIDE EFFECTS:	points may be clipped from the data block
PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/23/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InkClipDigitizerCoordsInk	proc	far

if INK_DIGITIZER_COORDS

	uses	si,di,bp,es
	.enter

	;
	; Lock the data block
	;
	Assert	handle bp
	mov_tr	si, ax		; si <- saved left bound
	xchg	bx, bp		; bx <- block handle, bp <- saved top bound
	call	MemLock
	jc	exit	
	mov	ds, ax		; ds <- block segment
	mov_tr	ax, si		; ax <- left bound
	push	bx		; #1 save block handle
	mov	bx, bp		; bx <- right bound

	;
	; Setup for loop
	;
	mov	bp, ds:[IDCH_count]	; bp <- # points
	mov	si, offset IDCH_data	; ds:si - ptr to source
	movdw	esdi, dssi		; es:di - ptr to dest

loopTop:
	; bp <- # points left to check
	; ds:si - ptr to source
	; es:di - ptr to dest
	push	bp
	mov	bp, ds:[si].IP_x
	BitClr	bp, IXC_TERMINATE_STROKE
	cmp	bp, ax		; check against bounds left
	jb	dropPoint
	cmp	bp, cx		; check against bounds right
	ja	dropPoint

	mov	bp, ds:[si].IP_y
	cmp	bp, bx		; check against bounds top
	ja	dropPoint
	cmp	bp, dx		; check against bounds bottom
	jb	dropPoint

	movsw			; copy X coord
	movsw			; copy Y coord

next:
	pop	bp
	dec	bp
	jnz	loopTop

	;
	; Unlock data block
	;
	pop	bx		; #1 bx <- block handle
	call	MemUnlock
exit:
	.leave
	ret

dropPoint:
	; Check if this point is the end of a stroke in which case we
	; should terminate the previously saved point.
	test	ds:[si].IP_x, mask IXC_TERMINATE_STROKE ; is this a stroke end?
	jz	dontTerminate		; nope -> don't terminate
	cmp	di, offset IDCH_data	; have we copied any points yet?
	jbe	dontTerminate		; nope -> don't terminate
	; terminate the previous point which may already be terminated but
	; doing it again won't hurt
	ornf	es:[di-size InkPoint].IP_x, mask IXC_TERMINATE_STROKE
dontTerminate:
	dec	ds:[IDCH_count]
	add	si, size InkPoint	; increment source pointer
	jmp	next

else
	; Degenerate case if INK_DIGITIZER_COORDS not defined
	stc
	ret

endif ; INK_DIGITIZER_COORDS

InkClipDigitizerCoordsInk	endp

InkCommon	ends

	SetGeosConvention
C_Pen	segment	resource


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkGetBoundsInDigitizerCoords

C DECLARATION:	extern Boolean
		_pascal InkGetBoundsInDigitizerCoords (optr visObject,
					DigitizerBounds _far *bounds);

		Returns FALSE if unable to convert bounds to digitizer
		coordinates.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/23/96    	Initial version

------------------------------------------------------------------------------@
if INK_DIGITIZER_COORDS
INKGETBOUNDSINDIGITIZERCOORDS	proc	far	\
				visObject:optr,
				bounds:fptr.DigitizerBounds
	uses	si, ds
	.enter

	Assert	fptr bounds

	movdw	bxsi, visObject
	call	InkGetBoundsInDigitizerCoords
	jc	error
	lds	si, bounds
	mov_tr	ds:[si].DB_left, ax
	mov	ds:[si].DB_top, bx
	mov	ds:[si].DB_right, cx
	mov	ds:[si].DB_bottom, dx
	mov	ax, TRUE	

done:
	.leave
	ret
error:
	mov	ax, FALSE
	jmp	done
INKGETBOUNDSINDIGITIZERCOORDS	endp

else
; Degenerate case if INK_DIGITIZER_COORDS not defined
INKGETBOUNDSINDIGITIZERCOORDS	proc	far
	mov	ax, FALSE
	retf	(size optr + size fptr)
INKGETBOUNDSINDIGITIZERCOORDS	endp

endif ; INK_DIGITIZER_COORDS


COMMENT @----------------------------------------------------------------------

C FUNCTION:	InkClipDigitizerCoordsInk

C DECLARATION:	extern Boolean
		_pascal InkClipDigitizerCoordsInk (MemHandle inkData,
					DigitizerBounds _far *bounds);

		Returns FALSE if clipping failed

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	lester	12/23/96    	Initial version

------------------------------------------------------------------------------@
if INK_DIGITIZER_COORDS
INKCLIPDIGITIZERCOORDSINK	proc	far	\
				inkData:hptr.InkDigitizerCoordsHeader,
				bounds:fptr.DigitizerBounds
	uses	si, ds
	.enter

	Assert	fptr bounds
	
	lds	si, bounds
	mov	ax, ds:[si].DB_left
	mov	bx, ds:[si].DB_top
	mov	cx, ds:[si].DB_right
	mov	dx, ds:[si].DB_bottom
	push	bp
	mov	bp, inkData	
	call	InkClipDigitizerCoordsInk
	pop	bp

	jc	error
	mov	ax, TRUE
done:
	.leave
	ret
error:
	mov	ax, FALSE
	jmp	done
INKCLIPDIGITIZERCOORDSINK	endp

else
; Degenerate case if INK_DIGITIZER_COORDS not defined
INKCLIPDIGITIZERCOORDSINK	proc	far
	mov	ax, FALSE
	retf	(size hptr + size fptr)
INKCLIPDIGITIZERCOORDSINK	endp
endif ; INK_DIGITIZER_COORDS

C_Pen	ends
	SetDefaultConvention
