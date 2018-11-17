COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		SplineGuardian.asm

AUTHOR:		Steve Scholl, Jan  9, 1992

ROUTINES:
	Name			Description
	----			-----------
SplineGuardianTransformSplinePoints

METHODS:
	Name
	----
SplineGuardianInitialize
SplineGuardianActivateCreate
SplineGuardianCreateVisWard
SplineGuardianAnotherToolActivated
SplineGuardianSetSplinePointerActiveStatus		
SplineGuardianLostEditGrab
SplineGuardianGainedEditGrab
SplineGuardianInvertEditIndicator
SplineGuardianGrObjSpecificInitialize		
SplineGuardianStartSelect
SplineGuardianInitToDefaultAttrs
SplineGuardianUpdateEditGrabWithStoredData	
SplineGuardianCompleteCreate
SplineGuardianCompleteTransform
SplineGuardianEndCreate
SplineGuardianEvaluatePARENTPoint
SplineGuardianDrawHandlesRaw
SplineGuardianDrawFG
SplineGuardianDrawBGArea

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/ 9/92		Initial revision

DESCRIPTION:
	$Id: splineGuardian.asm,v 1.1 97/04/04 18:08:54 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjClassStructures	segment resource

SplineGuardianClass		;Define the class record

GrObjClassStructures	ends

GrObjSplineGuardianCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the class of the vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianInitialize	method dynamic SplineGuardianClass, 
							MSG_META_INITIALIZE
	.enter

	mov	di, offset SplineGuardianClass
	CallSuper	MSG_META_INITIALIZE

	GrObjDeref	di,ds,si
	mov	ds:[di].GOVGI_class.segment, segment GrObjSplineClass
	mov	ds:[di].GOVGI_class.offset, offset GrObjSplineClass
	BitSet	ds:[di].GOI_msgOptFlags, GOMOF_SEND_UI_NOTIFICATION

	;This prevents pasted spline objects from going into create
	;or edit mode on MSG_GO_NOTIFY_GROBJ_VALID and grabbing
	;the mouse as a result.
	;

	mov	ds:[di].SGI_splineMode,SM_INACTIVE

	;    All spline objects have the ward control the create
	;

	andnf	ds:[di].GOVGI_flags,not mask GOVGF_CREATE_MODE
	ornf	ds:[di].GOVGI_flags, GOVGCM_VIS_WARD_CREATE \
						shl offset GOVGF_CREATE_MODE

	BitSet	ds:[di].GOI_msgOptFlags, \
	GOMOF_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT

	.leave
	ret
SplineGuardianInitialize		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianCreateVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do a spline intialize on the ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

RETURN:		
		^lcx:dx - newly created ward
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianCreateVisWard	method dynamic SplineGuardianClass, 
						MSG_GOVG_CREATE_VIS_WARD
	.enter

	;    Call our superclass so that the we have a ward
	;    that we can intialize
	;

	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock

	push	dx					;save ward chunk

	mov	ax,MSG_SPLINE_INITIALIZE
	clr	dx					;no params
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	pop	dx					;^lcx:dx <- ward

	.leave
	ret
SplineGuardianCreateVisWard		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianInitCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intialize objects instance data to a zero size object,
		with no rotation and flipping, at the point passed so
		that it can be interactively dragged open.
		
PASS:		
		*(ds:si) - instance data
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		ss:bp - PointDWFixed - location to start create from
RETURN:		
		nothing

DESTROYED:	
		WARNING: May cause block to move and/or chunk to move
		within block

PSEUDO CODE/STRATEGY:
		nothing
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianInitCreate method dynamic SplineGuardianClass, MSG_GO_INIT_CREATE
	uses	ax,cx,dx,bp
	.enter

	;    Get default attributes from body. Must do attributes
	;    before initializing basic data because the visible
	;    bounds of objects with line attributes are affected
	;    by the line width
	;

	mov	ax,MSG_GO_INIT_TO_DEFAULT_ATTRS
	call	ObjCallInstanceNoLock

	mov	bx,bp				;PointDWFixed stack frame

	sub	sp,size BasicInit
	mov	bp,sp

	;    Set center to passed PointDWFixed
	;

	mov	ax,ss:[bx].PDF_x.DWF_int.high
	mov	ss:[bp].BI_center.PDF_x.DWF_int.high,ax
	mov	ax,ss:[bx].PDF_x.DWF_int.low
	mov	ss:[bp].BI_center.PDF_x.DWF_int.low,ax
	mov	ax,ss:[bx].PDF_x.DWF_frac
	mov	ss:[bp].BI_center.PDF_x.DWF_frac,ax

	mov	ax,ss:[bx].PDF_y.DWF_int.high
	mov	ss:[bp].BI_center.PDF_y.DWF_int.high,ax
	mov	ax,ss:[bx].PDF_y.DWF_int.low
	mov	ss:[bp].BI_center.PDF_y.DWF_int.low,ax
	mov	ax,ss:[bx].PDF_y.DWF_frac
	mov	ss:[bp].BI_center.PDF_y.DWF_frac,ax

	;     Set GrObj dimensions at 1 by 1
	;

	mov	bx,1
	clr	ax
	mov	ss:[bp].BI_width.low,ax
	mov	ss:[bp].BI_height.low,ax
	mov	ss:[bp].BI_width.high,bx
	mov	ss:[bp].BI_height.high,bx

	push	ds,si
	segmov	ds,ss,si
	mov	si,bp
	add	si, offset BI_transform
	call	GrObjGlobalInitGrObjTransMatrix
	pop	ds,si

	;    Send method to initialize basic data
	;    and then clear stack frame
	;

	mov	ax,MSG_GO_INIT_BASIC_DATA
	call	ObjCallInstanceNoLock
	add	sp,size BasicInit

	.leave
	ret

SplineGuardianInitCreate endm



if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianInitToDefaultAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the spline
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianInitToDefaultAttrs	method dynamic SplineGuardianClass, 
						MSG_GO_INIT_TO_DEFAULT_ATTRS
	uses	dx
	.enter

	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_SPLINE_INITIALIZE
	clr	dx					;no params
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
SplineGuardianInitToDefaultAttrs		endm

endif




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianGrObjSpecificInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set initialization data that is tool specific
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		bp low 
			low nibble - SplineMode for creating new splines
			high nibble  - SplineMode for editing existing splines
		bp high - GrObjVisGuardianFlags
			only GOVGF_CAN_EDIT_EXISTING_OBJECTS matters

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimzed for SMALL SIZE over SPEED
	
		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGrObjSpecificInitialize	method dynamic SplineGuardianClass, 
					MSG_GO_GROBJ_SPECIFIC_INITIALIZE
	uses	cx
	.enter

	mov	ax, bp

	andnf	ah, mask GOVGF_CAN_EDIT_EXISTING_OBJECTS
	BitClr	ds:[di].GOVGI_flags, GOVGF_CAN_EDIT_EXISTING_OBJECTS
	ornf	ds:[di].GOVGI_flags,ah

	mov	ah,al
	andnf	al,0x0f				;just low nibble

	mov	ds:[di].SGI_splineCreateMode, al

	;   We want existing splines that we edit and splines that finish
	;   creating to edit the same way.
	;
	mov	cl,4
	shr	ah,cl				;high nibble to low nibble
	mov	ds:[di].SGI_splineAfterCreateMode, ah
	mov	ds:[di].SGI_splineMode, ah

	.leave
	ret
SplineGuardianGrObjSpecificInitialize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianAnotherToolActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify selected and edited objects that another tool
		has been activated. If the Spline is not editing
		it should just call its superclass. If, however, it
		is editing and the class of the tool being activated
		is SplineGuardian then it should keep the edit. 
		

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		cx:dx - od of caller
		bp - AnotherToolActivatedFlags

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none			

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			The activating class will be SplineGuardian since
			that is the class of all Spline editing tools
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianAnotherToolActivated	method dynamic SplineGuardianClass, 
					MSG_GO_ANOTHER_TOOL_ACTIVATED
	uses	ax,cx,dx,bp
	.enter

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jnz	callSuper

	test	bp,mask ATAF_SHAPE or mask ATAF_STANDARD_POINTER
	jnz	callSuper

	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	callSuper

	;    Get the class of the tool activating
	;

	push	si				;guardian lmem
	mov	bx,cx				;activating handle
	mov	si,dx				;activating lmem
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_META_GET_CLASS
	call	ObjMessage

	;    Check for activating tool being SplineGuardian 
	;

	cmp	dx,offset SplineGuardianClass
	jne	callSuperPopSI
	cmp	cx,segment SplineGuardianClass
	jne	callSuperPopSI

	;    Have activating SplineGuardian update us with
	;    its SplineMode.
	;
	
	mov	ax,MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	pop	si				;guardian lmem


done:
	.leave
	ret

callSuperPopSI:
	mov	dx,si					;activating lmem
	pop	si					;guardian lmem
	mov	cx,bx					;activating handle
callSuper:
	mov	di,offset SplineGuardianClass
	mov	ax,MSG_GO_ANOTHER_TOOL_ACTIVATED
	call	ObjCallSuperNoLock
	jmp	short done


SplineGuardianAnotherToolActivated		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify Spline that it is losing the edit grab. The
		Spline needs to mark the Spline pointer as inactive

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This message should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/15/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianLostTargetExcl	method dynamic SplineGuardianClass, 
						MSG_META_LOST_TARGET_EXCL
	.enter

	mov	ax, MSG_SG_SET_SPLINE_MODE
	mov	cl, SM_INACTIVE
	call	ObjCallInstanceNoLock

	mov	ax,MSG_SPLINE_SET_MINIMAL_VIS_BOUNDS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	mov	ax,MSG_META_LOST_TARGET_EXCL
	mov	di,segment SplineGuardianClass	
	mov	es, di
	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock

	Destroy	ax,cx,dx,bp

	.leave
	ret
SplineGuardianLostTargetExcl		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianReplaceGeometryInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retransform the spline points for any scale factor
		between the object dimensions and the vis bounds.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass


		ss:bp - BasicInit
RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianReplaceGeometryInstanceData method dynamic SplineGuardianClass, 
					MSG_GO_REPLACE_GEOMETRY_INSTANCE_DATA
	.enter

	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock

	call	SplineGuardianTransformSplinePoints

	mov	ax,MSG_VIS_RECREATE_CACHED_GSTATES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
SplineGuardianReplaceGeometryInstanceData		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianTransformSplinePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform spline points by the scale factor from the
		vis bounds to the object dimensions.
		
CALLED BY:	INTERNAL
		SplineGuardianCompleteTransform

PASS:		
		*ds:si - SplineGuardianClass

RETURN:		
		Spline has been converted

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		WARNING - may cause block to move or object to move within block

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianTransformSplinePoints		proc	far
	class	SplineGuardianClass
	uses	ax,bx,cx,dx,bp,di
	.enter

EC <	call	ECSplineGuardianCheckLMemObject			>

	;    Bail if no scale factor to transform spline points with
	;

	call	GrObjVisGuardianCalcScaleFactorVISToOBJECT
	jc	done

	clr	di					;no window
	call	GrCreateState

	;     Scale the spline in place so that 
	;     MSG_GOVG_NOTIFY_VIS_WARD_CHANGE_BOUNDS won't try to 
	;     move the object.
	;
	
	push	ax,bx,cx,dx				;scale factor
	call	GrObjVisGuardianGetWardWWFixedCenter
	call	GrApplyTranslation
	pop	ax,bx,cx,dx				;scale factor
	call	GrApplyScale
	call	GrObjVisGuardianGetWardWWFixedCenter
	negwwf	dxcx					;x of center
	negwwf	bxax					;y of center
	call	GrApplyTranslation

	;    Convert Spline through gstate and have it
	;    change it vis bounds to match the new size of the Spline
	;

	mov	bp,di					;gstate
	mov	ax,MSG_SPLINE_TRANSFORM_POINTS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	mov	di,bp					;gstate
	call	GrDestroyState

done:
	.leave
	ret
SplineGuardianTransformSplinePoints		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianCompleteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform the splines points with the transformation
		in the normalTransform and then call the super
		class to complete the transform with the new spline data.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		bp - GrObjActionNotificationType

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianCompleteTransform	method dynamic SplineGuardianClass, 
						MSG_GO_COMPLETE_TRANSFORM
	.enter

	call	SplineGuardianTransformSplinePoints

	;
	;    Call the super class only once all the geometry has been done.
	;

	mov	di, offset SplineGuardianClass
	call	ObjCallSuperNoLock

	.leave
	ret
SplineGuardianCompleteTransform		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianCheckForEditWithFirstStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the splineAfterCreateMode is one of the beginner
		modes then we don't want to edit with the first start
		select because it will add an unwanted anchor point

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		^lcx:dx - floater
RETURN:		
		stc - edit with this start select
		clc - don't edit with this start select
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianCheckForEditWithFirstStartSelect	method dynamic\
	 SplineGuardianClass, MSG_GOVG_CHECK_FOR_EDIT_WITH_FIRST_START_SELECT
	.enter

	cmp	ds:[di].SGI_splineAfterCreateMode,SM_BEGINNER_EDIT
	je	dontEdit

	stc
done:
	.leave
	ret

dontEdit:
	;    Need to get object out of inactive mode so that its
	;    anchor points show up
	;

	mov	ax,MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA
	call	ObjCallInstanceNoLock

	clc

	jmp	done

SplineGuardianCheckForEditWithFirstStartSelect		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianBeginCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The spline geos from begin to end create immediately
		so that we can stick it in edit mode.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianBeginCreate	method dynamic SplineGuardianClass, 
						MSG_GO_BEGIN_CREATE
	uses	cx
	.enter

	;    Make sure we will be in spline create mode
	;

	mov	ax,MSG_SG_SWITCH_TO_SPLINE_CREATE_MODE
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_BEGIN_CREATE
	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_GO_NOTIFY_GROBJ_VALID
	call	ObjCallInstanceNoLock

	;    The spline leaves the GrObj's concept of create mode
	;    right away. Even though we initially add points to the
	;    spline with a SplineMode with CREATE in it, as far as the
	;    grobj is concerned it is an object being edited.
	;

	clr	cx				;EndCreatePassFlags
	mov	ax,MSG_GO_END_CREATE
	call	ObjCallInstanceNoLock

	.leave
	ret
SplineGuardianBeginCreate		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianEndCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop the creation of the object and use the existing 
		data.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		ss:bp - GrObjMouseData

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianEndCreate	method dynamic SplineGuardianClass, 
							MSG_GO_END_CREATE
	uses	ax
	.enter

	;    If not in create mode then ignore message
	;

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jz	done

	call	ObjMarkDirty
	andnf	ds:[di].GOI_actionModes, not (	mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING or \
						mask GOAM_ACTION_ACTIVATED  or \
						mask GOAM_CREATE )

	mov	ax,MSG_GO_SUSPEND_COMPLETE_CREATE
	call	ObjCallInstanceNoLock

	call	GrObjGlobalUndoAcceptActions

done:
	clr	cx

	.leave
	ret
	

SplineGuardianEndCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete the interactive create

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 6/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianCompleteCreate	method dynamic SplineGuardianClass, 
						MSG_GO_COMPLETE_CREATE
	.enter

	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_GO_BECOME_EDITABLE
	call	ObjCallInstanceNoLock

	.leave
	ret
SplineGuardianCompleteCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianSwitchToSplineCreateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the splineMode to the mode in splineCreateMode
		

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianSwitchToSplineCreateMode	method dynamic SplineGuardianClass,
				MSG_SG_SWITCH_TO_SPLINE_CREATE_MODE
	uses	cx
	.enter

	mov	cl,ds:[di].SGI_splineCreateMode
	mov	ax,MSG_SG_SET_SPLINE_MODE
	call	ObjCallInstanceNoLock

	.leave
	ret
SplineGuardianSwitchToSplineCreateMode		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianSwitchToSplineAfterCreateMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the current SplineMode is one of the spline
		create modes then switch to SGI_afterCreateMode

CALLED BY:	INTERNAL UTILITY

PASS:		*ds:si - object

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianSwitchToSplineAfterCreateMode method dynamic SplineGuardianClass,
				MSG_SG_SWITCH_TO_SPLINE_AFTER_CREATE_MODE
	uses	cx
	.enter

	; If the spline is ridiculously small, then nuke it.

	mov	ax, MSG_SPLINE_GET_ENDPOINT_INFO
	mov	cl, GET_FIRST
	mov	di, mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard
	jc	destroy

	mov	di, ds:[si]
	add	di, ds:[di].SplineGuardian_offset
	cmp	ds:[di].SGI_splineMode,SM_ADVANCED_CREATE
	ja	done

	mov	cl, ds:[di].SGI_splineAfterCreateMode
	mov	ax,MSG_SG_SET_SPLINE_MODE
	call	ObjCallInstanceNoLock

	;   While the spline is being created it doesn't show
	;   its arrowheads. While it is being edited the arrow heads,
	;   will update correctly for the most part, so force them
	;   to draw if they exist. If we didn't do this then the
	;   arrowheads wouldn't show up until they happened to
	;   be invalidate by some other operation.
	;   

	call	GrObjGetLineInfo
	test	al,mask GOLAIR_ARROWHEAD_ON_START or \
		mask GOLAIR_ARROWHEAD_ON_END
	jz	done

	;   It turns out that a spline won't be closed at the time
	;   we get this message, so we will have to invalidate
	;   closed splines even though they don't draw arrowheads.
	;   Big deal.
	;

	mov	ax,MSG_GO_INVALIDATE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret

destroy:
	; Destroy the object

	mov	ax, MSG_GO_CLEAR_SANS_UNDO
	call	ObjCallInstanceNoLock
	jmp	done

SplineGuardianSwitchToSplineAfterCreateMode		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianSetSplineCreateAndAfterCreateModes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set SGI_splineAfterCreateMode and SGI_splineCreateMode

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		cl - splineCreateMode
		ch - splineAfterCreateMode

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianSetSplineCreateAndAfterCreateModes	method dynamic \
							SplineGuardianClass, 
			MSG_SG_SET_SPLINE_CREATE_AND_AFTER_CREATE_MODES
	.enter

	mov	ds:[di].SGI_splineCreateMode,cl
	mov	ds:[di].SGI_splineAfterCreateMode,ch

	.leave
	ret
SplineGuardianSetSplineCreateAndAfterCreateModes		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SplineGuardianSetSplineMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SplineGuardian method for MSG_SG_SET_SPLINE_MODE

Pass:		*ds:si = SplineGuardian object
		ds:di = SplineGuardian instance

		cl - SplineMode

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianSetSplineMode	method	SplineGuardianClass, 
					MSG_SG_SET_SPLINE_MODE
	uses	ax
	.enter

	mov	ds:[di].SGI_splineMode, cl

	mov	ax, MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA
	call	ObjCallInstanceNoLock

	.leave
	ret
SplineGuardianSetSplineMode	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SplineGuardianUpdateVisWardWithStoredData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SplineGuardian method for 
				MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA

Called by:	

Pass:		*ds:si = SplineGuardian object
		ds:di = SplineGuardian instance

Return:		nothing

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianUpdateVisWardWithStoredData	method	SplineGuardianClass,
				MSG_GOVG_UPDATE_VIS_WARD_WITH_STORED_DATA
	uses	ax,cx
	.enter

	mov	cl, ds:[di].SGI_splineMode
	mov	ax, MSG_SPLINE_SET_MODE
	clr	di
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret

SplineGuardianUpdateVisWardWithStoredData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SplineGuardianUpdateEditGrabWithStoredData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	Send the spline mode to the edit grab
		

Pass:		*ds:si = SplineGuardian object
		ds:di = SplineGuardian instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 17, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianUpdateEditGrabWithStoredData method dynamic SplineGuardianClass, 
				MSG_GOVG_UPDATE_EDIT_GRAB_WITH_STORED_DATA
	uses	cx
	.enter

	mov	ax,MSG_SG_SET_SPLINE_MODE
	mov	cl, ds:[di].SGI_splineMode
	clr	di
	call	GrObjMessageToEdit

	mov	ax,MSG_SG_SET_SPLINE_CREATE_AND_AFTER_CREATE_MODES
	mov	cl, ds:[di].SGI_splineCreateMode
	mov	ch, ds:[di].SGI_splineAfterCreateMode
	clr	di
	call	GrObjMessageToEdit

	.leave
	ret
SplineGuardianUpdateEditGrabWithStoredData	endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SplineGuardianGenerateSplineNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SplineGuardian method for MSG_TG_GENERATE_SPLINE_NOTIFY

		Passes the notification to the GrObjBody so that it can
		coalesce each GrObjSpline's attrs into a single update.

Pass:		*ds:si = SplineGuardian object
		ds:di = SplineGuardian instance

		ss:[bp] - VisSplineGenerateNotifyParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGenerateSplineNotify	method dynamic	SplineGuardianClass,
					MSG_SG_GENERATE_SPLINE_NOTIFY
	.enter

	;
	; Drop this on the floor if the spline is invalid (this
	; happens when a new spline is being created -- in charting,
	; for instance).
	;

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done

	;
	;  If the relayed bit is set, we want to send this to the
	;  ward. Otherwise, to the body
	;
	test	ss:[bp].SGNP_sendFlags,mask SNSF_RELAYED_TO_LIKE_OBJECTS
	jnz	sendToWard

	mov	ax, MSG_GB_GENERATE_SPLINE_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

done:
	.leave
	ret

sendToWard:
	mov	ax, MSG_SPLINE_GENERATE_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	jmp	done
SplineGuardianGenerateSplineNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SplineGuardianSendUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SplineGuardian method for MSG_GO_SEND_UI_NOTIFICATION

		Passes the notification to the GrObjBody so that it can
		coalesce each GrObjSpline's attrs into a single update.

Pass:		*ds:si = SplineGuardian object
		ds:di = SplineGuardian instance

		cx - GrObjUINotificationTypes of notifications that need to
		     be performed.

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianSendUINotification	method dynamic	SplineGuardianClass,
					MSG_GO_SEND_UI_NOTIFICATION
	uses	bp
	.enter

	mov	di, offset SplineGuardianClass
	call	ObjCallSuperNoLock

	;
	; Bail if grobj invalid.  Prevents needless updates in charting
	;

	GrObjDeref	di, ds, si
	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	done


	test	cx,mask GOUINT_SELECT
	jz	done

	;  The guardian has been selected so 
	;  tell the ward to update its controllers (except for select state,
	;  'cause we want the grobj's select state), so that the controllers
	;  will reflect the wards attributes,etc.
	;

	sub	sp, size SplineGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].SGNP_notificationFlags, mask SplineGenerateNotifyFlags
	mov	ss:[bp].SGNP_sendFlags, mask SNSF_UPDATE_APP_TARGET_GCN_LISTS
	mov	ax, MSG_SPLINE_GENERATE_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	add	sp, size SplineGenerateNotifyParams

done:
	.leave
	ret
SplineGuardianSendUINotification	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			SplineGuardianLostSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SplineGuardian method for MSG_GO_LOST_SELECTION_LIST

		Send null notification as we are no longer selected.
		Overrides superclass's refusal to do this because
		GOOF_GROBJ_INVALID is set.

Pass:		*ds:si = SplineGuardian object
		ds:di = SplineGuardian instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	brianc	9/30/94 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianLostSelectionList	method dynamic	SplineGuardianClass,
					MSG_GO_LOST_SELECTION_LIST
	uses	bp
	.enter

	push	ax
	sub	sp, size SplineGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].SGNP_notificationFlags, mask SplineGenerateNotifyFlags
	mov	ss:[bp].SGNP_sendFlags, \
			mask SNSF_UPDATE_APP_TARGET_GCN_LISTS or \
			mask SNSF_NULL_STATUS or \
			mask SNSF_SEND_ONLY or \
			mask SNSF_RELAYED_TO_LIKE_OBJECTS
	mov	ax, MSG_SPLINE_GENERATE_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	add	sp, size SplineGenerateNotifyParams
	pop	ax

	mov	di, offset SplineGuardianClass
	call	ObjCallSuperNoLock

	.leave
	ret
SplineGuardianLostSelectionList	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SplineGuardian method for
		MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

Pass:		*ds:si = GrObj object
		ds:di = GrObj instance

		^hcx = GrObjNotifySelectionStateChange struct

Return:		carry set if relevant diff bit(s) are all set

Destroyed:	nothing

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianCombineSelectionStateNotificationData method dynamic SplineGuardianClass,  MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

	uses	ax

	.enter

	mov	di, offset SplineGuardianClass
	call	ObjCallSuperNoLock

	;
	;  Indicate that a spline object is selected
	;
	mov	bx, cx
	call	MemLock
	jc	done
	mov	es, ax
	BitSet	es:[GONSSC_selectionState].GSS_flags, GSSF_SPLINE_SELECTED
	call	MemUnlock

done:
	.leave
	ret
SplineGuardianCombineSelectionStateNotificationData	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the RectDWFixed that bounds the object in
		the dest gstate coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of RectClass

		ss:bp - BoundingRectData
			destGState
			parentGState

RETURN:		
		ss:bp - BoundingRectData
			rect
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGetBoundingRectDWFixed	method dynamic SplineGuardianClass,
				MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	;    If the guardian is grobj invalid then the vis spline isn't
	;    going to draw anything into a path which will then screw
	;    up the bounds calc. So If grobj invalid then always use
	;    optimized recalc. This fixes a bug with converting
	;    rotated splines from 1.2 documents.
	;

	test	ds:[di].GOI_optFlags, mask GOOF_GROBJ_INVALID
	jnz	callSuper

	call	GrObjCheckForOptimizedBoundsCalc
	jc	callSuper

	CallMod	GrObjGetBoundingRectDWFixedFromPath

includeLineWidth:
	CallMod	GrObjAdjustRectDWFixedByLineWidth

	.leave
	ret

callSuper:
	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock
	jmp	includeLineWidth


SplineGuardianGetBoundingRectDWFixed		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianGetDWFSelectionHandleBoundsForTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It is not trivial to calculate the selection handle
		bounds for rotated or skewed spline

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		ss:bp - RectDWFixed
RETURN:		
		ss:bp - RectDWFixed filled
		
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGetDWFSelectionHandleBoundsForTrivialReject method dynamic SplineGuardianClass, 
		MSG_GO_GET_DWF_SELECTION_HANDLE_BOUNDS_FOR_TRIVIAL_REJECT
	.enter

	mov	di,offset SplineGuardianClass
	call	GrObjGetDWFSelectionHandleBoundsForTrivialRejectProblems

	.leave
	ret
SplineGuardianGetDWFSelectionHandleBoundsForTrivialReject		endm

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Use spline specific GenerateNormalFourPointDWFixeds
		routine which will compenstate for arrowheads if
		they exist.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		ss:bp - BoundingRectData
			destGState
			parentGState

RETURN:		
		ss:bp - BoudingRectData
			rect
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/10/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGetBoundingRectDWFixed	method dynamic SplineGuardianClass, 
						MSG_GO_GET_BOUNDING_RECTDWFIXED
	class	SplineGuardianClass
	uses	dx,cx
	.enter

	mov	bx,bp					;BoundingRectData

	push	ds,si
	sub	sp,size FourPointDWFixeds
	mov	bp,sp
	call	SplineGuardianGenerateNormalFourPointDWFixeds
	mov	di,ss:[bx].BRD_parentGState
	mov	dx,ss:[bx].BRD_destGState
	call	GrObjCalcNormalDWFixedMappedCorners
	mov	di,ss
	mov	ds,di					;Rect segment
	mov	es,di					;FourPoints segment
	mov	si,bx					;rect offset
	mov	di,bp					;FourPoints offset
	call	GrObjGlobalSetRectDWFixedFromFourPointDWFixeds
	add	sp, size FourPointDWFixeds
	pop	ds,si

	mov	bp,bx					;BoundingRectData

	;    This covers arrowheads and problems with the path
	;    code not including lines
	;

	CallMod	GrObjAdjustRectDWFixedByLineWidth

	.leave
	ret
SplineGuardianGetBoundingRectDWFixed		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianGenerateNormalFourPointDWFixeds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in FourPointDWFixeds structure from width and
		height of object -w/2,-h/2,w/2,h/2.
		Compensate for arrowheads if necessary.


CALLED BY:	INTERNAL UTILITY

PASS:		
		*ds:si - instance data
		ss:bp - FourPointDWFixeds	 - empty

RETURN:		
		ss:bp - FourDWPoints - filled

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		nothing
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGenerateNormalFourPointDWFixeds		proc	far
	class	SplineGuardianClass
	uses	si,di,ax,bx,cx,dx
	.enter

EC <	call	ECSplineGuardianCheckLMemObject		>

	CallMod	GrObjGetNormalOBJECTDimensions

	push	ax,bx				;height
	call	GrObjGetArrowheadInfo
	and	al, mask GOLAIR_ARROWHEAD_ON_START or \
			mask GOLAIR_ARROWHEAD_ON_END

	jnz	arrowheads
	pop	ax,bx				;height

continue:
	sar	dx,1				;width/2 int
	rcr	cx,1				;width/2 frac

	sar	bx,1				;height/2 int
	rcr	ax,1				;height/2 frac

	;    Store bottom as height/2 and top as -height/2
	;

	push	dx				;width int
	xchg	bx,ax				;bx <- height frac
						;ax <- height int
	cwd					;sign extend height/2
	movdwf	ss:[bp].FPDF_BR.PDF_y, dxaxbx
	movdwf	ss:[bp].FPDF_BL.PDF_y, dxaxbx
	negdwf	dxaxbx
	movdwf	ss:[bp].FPDF_TR.PDF_y, dxaxbx
	movdwf	ss:[bp].FPDF_TL.PDF_y, dxaxbx

	;    Store right as width/2 and left as -width/2
	;

	pop	ax				;width int
	cwd					;sign extend width/2
	movdwf	ss:[bp].FPDF_BR.PDF_x, dxaxcx
	movdwf	ss:[bp].FPDF_TR.PDF_x, dxaxcx
	negdwf	dxaxcx
	movdwf	ss:[bp].FPDF_BL.PDF_x, dxaxcx
	movdwf	ss:[bp].FPDF_TL.PDF_x, dxaxcx

	.leave
	ret

arrowheads:
	;    When need to expand the bounds to include arrowheads
	;    which might stick outside of the normal bounds. We
	;    must be careful to expand the bounds in equal amounts
	;    in both directions to keep the bounds centered. We
	;    will expand the bounds by the length of the arrowhead
	;    branch. This is definitely overkill but it works.
	;

	clr	bh
	mov	di,bx				;arrowhead length
	shl	di,1				;expand in opposite directions
	pop	ax,bx				;height
	add	dx,di				;expand width
	add	bx,di				;expand height
	jmp	continue


SplineGuardianGenerateNormalFourPointDWFixeds		endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Expand the vis bounds of the ward to include the
		control points.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardian

RETURN:		
		none
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGainedTargetExcl	method dynamic SplineGuardianClass, 
						MSG_META_GAINED_TARGET_EXCL
	.enter


	mov	cx,mask RSA_CHOOSE_OWN_SIZE
	mov	dx,cx
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_RECALC_SIZE
	call	GrObjVisGuardianMessageToVisWard

	mov	ax, MSG_META_GAINED_TARGET_EXCL
	mov	di, offset SplineGuardianClass
	call	ObjCallSuperNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret
SplineGuardianGainedTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianRuleLargeStartSelectForWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	SplineGuardian method for MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Called by:	MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Pass:		*ds:si = SplineGuardian object
		ds:di = SplineGuardian instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianRuleLargeStartSelectForWard	method dynamic	SplineGuardianClass, MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD
	uses	cx
	.enter

	;
	;  If the spline is in create mode, then we want to snap,
	;  otherwise we just want to set the reference.
	;

	cmp	ds:[di].SGI_splineMode,SM_ADVANCED_CREATE
	ja	setReference

	mov	di, offset SplineGuardianClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret

setReference:
	mov	cx, mask VRCS_OVERRIDE or mask VRCS_SET_REFERENCE
	mov	ax, MSG_VIS_RULER_RULE_LARGE_PTR
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToRuler
	jmp	done
SplineGuardianRuleLargeStartSelectForWard	endm



GrObjSplineGuardianCode	ends


GrObjTransferCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianGetTransferBlockFromVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a vm block from the ward with the ward's data in it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		ss:[bp] - GrObjTransferParams

RETURN:		
		cx:dx - 32 bit identifier
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 may 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianGetTransferBlockFromVisWard method dynamic  SplineGuardianClass,
				MSG_GOVG_GET_TRANSFER_BLOCK_FROM_VIS_WARD
	.enter

	;
	;  Tell the spline object that we want the vm block allocated in
	;  the transfer file.
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	cx, bx					;cx <- override
	mov	ax, MSG_SPLINE_CREATE_TRANSFER_FORMAT
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard

	;
	;  Return the block in 32 bit id form
	;
	mov_tr	cx, ax
	clr	dx

	.leave
	ret
SplineGuardianGetTransferBlockFromVisWard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianCreateWardWithTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a vm block from the ward with the ward's data in it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		ss:[bp] - GrObjTransferParams
		cx:dx - 32 bit identifier

RETURN:		^lcx:dx <- new ward

DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	19 may 92	initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianCreateWardWithTransfer	method dynamic	SplineGuardianClass,
					MSG_GOVG_CREATE_WARD_WITH_TRANSFER
	uses	bp

	.enter

	push	cx					;save vm block handle

	;
	;  get the block to store the spline object in
	;
	mov	ax,MSG_GB_GET_BLOCK_FOR_ONE_GROBJ
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

	;
	;  Create our ward in the returned block
	;
	mov	ax,MSG_GOVG_CREATE_VIS_WARD
	call	ObjCallInstanceNoLock

	mov_tr	ax, dx					;^lcx:ax <- spline obj
	pop	dx					;dx <- vm block
	push	cx, ax					;save spline object

	;
	;  Have the spline read in its points
	;
	mov	bx, ss:[bp].GTP_vmFile
	mov	cx, bx					;bp <- transfer file
	mov	ax, MSG_SPLINE_REPLACE_WITH_TRANSFER_FORMAT
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	pop	cx, dx					;return optr
	.leave
	ret
SplineGuardianCreateWardWithTransfer	endm


GrObjTransferCode	ends


GrObjDrawCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianDrawFG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw only the base data of the spline, not the
		inverted stuff

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		cl - DrawFlags
		dx - gstate

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianDrawFG	method dynamic SplineGuardianClass, 
						MSG_GO_DRAW_FG_AREA,
						MSG_GO_DRAW_FG_AREA_HI_RES
	uses	dx,bp
	.enter

	mov	di,dx					;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform

	;   Send draw message to vis ward
	;

	mov	bp,dx
	mov	di,mask MF_FIXUP_DS
	mov	ax, MSG_SPLINE_DRAW_AREA_ONLY
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
SplineGuardianDrawFG		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianDrawFGLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw only the base data of the spline, not the
		inverted stuff.

		This handler is used for the clip stuff also because
		the spline fill uses a path which we can't draw to a
		clip path.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		cl - DrawFlags
		dx - gstate

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianDrawFGLine	method dynamic SplineGuardianClass, 
						MSG_GO_DRAW_FG_LINE,
						MSG_GO_DRAW_FG_LINE_HI_RES,
						MSG_GO_DRAW_CLIP_AREA,
						MSG_GO_DRAW_CLIP_AREA_HI_RES,
						MSG_GO_DRAW_QUICK_VIEW
	uses	cx,dx,bp
	.enter

	mov	di,dx					;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform

	mov	bp,dx
	mov	di,mask MF_FIXUP_DS
	mov	ax, MSG_SPLINE_DRAW_LINE_ONLY
	call	GrObjVisGuardianMessageToVisWard

	;    If the spline is closed don't draw the arrowheads.
	;

	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_SPLINE_GET_CLOSED_STATE
	call	GrObjVisGuardianMessageToVisWard
	tst	cl
	jz	arrowheads

done:
	.leave
	ret

arrowheads:
	mov	di,dx					;gstate
	call	GrObjGetLineInfo
	call	SplineGuardianDrawStartArrowhead
	call	SplineGuardianDrawEndArrowhead
	jmp	done

SplineGuardianDrawFGLine		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianDrawStartArrowhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw arrow head at start of line in needed

CALLED BY:	INTERNAL
		SplineGuardianFGLine

PASS:		*ds:si - object
		di - gstate with normalTransform applied
		al - GrObjLineAttrInfoRecord

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianDrawStartArrowhead		proc	near

	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECSplineGuardianCheckLMemObject			>

	test	al, mask GOLAIR_ARROWHEAD_ON_START
	jz	done

	push	dx					;gstate
	mov	cl,GET_FIRST
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_SPLINE_GET_ENDPOINT_INFO
	call	GrObjVisGuardianMessageToVisWard
	pop	di					;gstate
	jc	done
	mov	bx,bp
	call	GrObjDrawArrowhead

done:
	.leave
	ret
SplineGuardianDrawStartArrowhead		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianDrawEndArrowhead
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw arrow head at end of line in needed

CALLED BY:	INTERNAL
		SplineGuardianFGLine

PASS:		*ds:si - object
		di - gstate with normalTransform applied
		al - GrObjLineAttrInfoRecord

RETURN:		
		nothing
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianDrawEndArrowhead		proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECSplineGuardianCheckLMemObject			>

	test	al, mask GOLAIR_ARROWHEAD_ON_END
	jz	done

	push	dx					;gstate
	mov	cl,GET_LAST
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_SPLINE_GET_ENDPOINT_INFO
	call	GrObjVisGuardianMessageToVisWard
	pop	di					;gstate
	jc	done
	mov	bx,bp
	call	GrObjDrawArrowhead

done:
	.leave
	ret
SplineGuardianDrawEndArrowhead		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianDrawBGArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw only the base data of the spline, not the
		inverted stuff

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		cl - DrawFlags
		dx - gstate

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianDrawBGArea	method dynamic SplineGuardianClass, 
						MSG_GO_DRAW_BG_AREA,
						MSG_GO_DRAW_BG_AREA_HI_RES
	uses	dx,bp
	.enter

	mov	di,dx					;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform

	;   Send draw message to vis ward
	;

	mov	bp,dx
	mov	di,mask MF_FIXUP_DS
	mov	ax, MSG_SPLINE_DRAW_USING_PASSED_GSTATE_ATTRIBUTES
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
SplineGuardianDrawBGArea		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianDrawSpriteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the spline line for sprite.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		dx - gstate

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/ 7/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianDrawSpriteLine	method dynamic SplineGuardianClass, 
						MSG_GO_DRAW_SPRITE_LINE,
						MSG_GO_DRAW_SPRITE_LINE_HI_RES
	uses	dx,bp
	.enter

	mov	di,dx					;gstate
	mov	ax,MSG_GOVG_APPLY_SPRITE_OBJECT_TO_VIS_TRANSFORM
	call	ObjCallInstanceNoLock

	mov	bp,dx
	mov	di,mask MF_FIXUP_DS
	mov	ax, MSG_SPLINE_DRAW_LINE_ONLY
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
SplineGuardianDrawSpriteLine		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianDrawHandlesRaw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convenient places as any to get the spline to draw
		it inverted stuff.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		dx - gstate

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianDrawHandlesRaw	method dynamic SplineGuardianClass, 
						MSG_GO_DRAW_HANDLES_RAW
	uses	bp
	.enter

	mov	di,offset SplineGuardianClass
	call	ObjCallSuperNoLock

	mov	di,dx					;gstate
	call	GrSaveTransform
	call	GrObjApplyNormalTransform
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform
	mov	bp,dx					;gstate
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_SPLINE_DRAW_EVERYTHING_ELSE
	call	GrObjVisGuardianMessageToVisWard
	mov	di,dx					;gstate
	call	GrRestoreTransform

	.leave
	ret
SplineGuardianDrawHandlesRaw		endm


GrObjDrawCode	ends


GrObjRequiredInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianEvaluatePARENTPointForEdit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have object evaluate the passed point in terms
		of editing. (ie could the object edit it self
		at this point).

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjClass

		ss:bp - PointDWFixed in PARENT coordinate system

RETURN:		
		al - EvaluatePositionRating
		dx - EvaluatePositionNotes
	
DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianEvaluatePARENTPointForEdit method dynamic SplineGuardianClass, 
					MSG_GO_EVALUATE_PARENT_POINT_FOR_EDIT
	.enter

	mov	ax,MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
	call	ObjCallInstanceNoLock

	call	GrObjCanEdit?
	jnc	cantEdit

	;    A low evaluation means the point was in the bounds,
	;    but not on the spline or its control or anchor points.
	;    For editing purposes this point is used for a drag 
	;    select. We only allow drag selects on editing object.
	;    Otherwise you would never be able to edit a spline that
	;    was underneath another spline.
	;

	GrObjDeref	di,ds,si
	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jnz	done
	cmp	al, EVALUATE_LOW
	jne	done
	mov	al,EVALUATE_NONE
	
done:
	.leave
	ret

cantEdit:
	;   Object can't be edited, so evaluate as none but leave the 
	;   notes intact.
	;

	mov	al,EVALUATE_NONE
	jmp	done

SplineGuardianEvaluatePARENTPointForEdit		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGuardianEvaluatePARENTPointForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GrObj evaluates point to determine if it should be 
		selected by it. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of SplineGuardianClass

		ss:bp - PointDWFixed in PARENT coordinates

RETURN:		
		al - EvaluatePositionRating
		dx - EvaluatePositionNotes

DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGuardianEvaluatePARENTPointForSelection method dynamic \
	SplineGuardianClass, 	MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION
point	local	PointWWFixed

	uses	cx
	.enter

	mov	bx,ss:[bp]				;orig bp,PARENT pt frame

	;    Convert point to OBJECT and store in stack frame.
	;    If OBJECT coord won't fit in WWF then bail
	;

	push	bp					;local frame
	lea	bp, ss:[point]
	call	GrObjConvertNormalPARENTToWWFOBJECT
	pop	bp					;local frame
	LONG jnc	notEvenClose

	;    Untransform the object coordinate mouse postion into 
	;    the vis coordinates of ward
	;

	clr	di
	call	GrCreateState
	mov	dx,di				;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform
	movwwf	dxcx,point.PF_x
	movwwf	bxax,point.PF_y
	call	GrUntransformWWFixed
	call	GrDestroyState

	;    Round vis coordinate to integer
	;	

	rndwwf	dxcx
	rndwwf	bxax
	mov	cx,dx
	mov	dx,bx

	;    Have spline do its own hit detection
	;

	mov	ax,MSG_SPLINE_HIT_DETECT
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard

	cmp	dl, SST_NONE
	je	notEvenClose
	cmp	dl, SST_INSIDE_VIS_BOUNDS
	je	lowEval

	;    If the hit was on a line segment or anchor or control points
	;    we want to treat that as a high priority select. So in those 
	;    cases pass clc to complete hit detection routine. This will
	;    cause the routine to treat the click as if it was a line, which
	;    is always high priority.
	;

	cmp	dl, SST_SEGMENT
	je	complete				;implied clc
	cmp	dl,SST_ANCHOR_POINT
	je	complete
	cmp	dl,SST_CONTROL_POINT
	je	complete
	stc						;not on line
complete:
	call	GrObjGlobalCompleteHitDetectionWithAreaAttrCheck

checkSelectionLock:
	GrObjDeref	di,ds,si
	test	ds:[di].GOI_locks, mask GOL_SELECT
	jnz	selectionLock

done:
	.leave
	ret


notEvenClose:
	movnf	al,EVALUATE_NONE
	clr	dx
	jmp	checkSelectionLock

lowEval:
	movnf	al, EVALUATE_LOW
	clr	dx
	jmp	checkSelectionLock

selectionLock:
	BitSet	dx, EPN_SELECTION_LOCK_SET
	jmp	done

SplineGuardianEvaluatePARENTPointForSelection		endm

GrObjRequiredInteractiveCode	ends





if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSplineGuardianCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an SplineGuardianClass or one
		of its subclasses
		
CALLED BY:	INTERNAL

PASS:		
		*(ds:si) - object chunk to check
RETURN:		
		none
DESTROYED:	
		nothing - not even flags

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineGuardianCheckLMemObject		proc	far
ForceRef	ECSplineGuardianCheckLMemObject
	uses	es,di
	.enter
	pushf	
	call	ECCheckLMemObject
	mov	di,segment SplineGuardianClass
	mov	es,di
	mov	di,offset SplineGuardianClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_A_DRAW_OBJECT	
	popf
	.leave
	ret
ECSplineGuardianCheckLMemObject		endp

GrObjErrorCode	ends

endif
