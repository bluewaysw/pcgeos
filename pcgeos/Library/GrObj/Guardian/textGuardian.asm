COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj
FILE:		textGuardian.asm

AUTHOR:		Steve Scholl, Jan  9, 1992

ROUTINES:
	Name	
	----	
TextGuardianCalcGuaranteedDisplayHeightIncrease
TextGuardianCheckCanClickCreate
TextGuardianClickCreate
TextGuardianCalcClickCreateWidth
TextGuardianAdjustMarginsForLineWidth
TextGuardianHeightNotifyInvalidate
TextGuardianCalcNormalizedHeight
TextGuardianCalcEmptyNormalizedHeight
TextGuardianSetTransparentBit
TextGuardianShrinkWidthAfterClickCreate
TextGuardianShrinkHeightIfNecessary
TextGuardianGetVisWardHeight

METHODS:
	Name
	----
TextInitialize
TextGuardianGetPointerImage
TextGuardianActivateCreate
TextGuardianBeginCreate
TextGuardianInvertEditIndicator
TextGuardianDrawFG
TextGuardianDrawFGLine
TextGuardianDrawBGArea
TextGuardianGetBoundingTextGuardianDWFixed
TextGuardianAnotherToolActivated
TextGuardianCompleteCreate
TextGuardianCompleteTransform
TextGuardianCalcDesiredMinHeight		
TextGuardianSetDesiredMinHeight		
TextGuardianCalcDesiredMaxHeight		
TextGuardianSetDesiredMaxHeight		
TextGuardianSpecialResizeConstrain		
TextGuardianHeightNotify
TextGuardianInitToDefaultAttrs
TextGuardianNotifyAction
TextGuardianVisBoundsSetup
TextGuardianGainedSelectionList
TextGuardianLostSelectionList
TextGuardianGainedTargetExcl
TextGuardianLostTargetExcl
TextGuardianConvertScaleToData
TextGuardianSetTextGuardianFlags

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	1/ 9/92		Initial revision


DESCRIPTION:
	
		

	$Id: textGuardian.asm,v 1.1 97/04/04 18:08:49 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

TextGuardianClass		;Define the class record

GrObjClassStructures	ends

GrObjTextGuardianCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianMetaInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the class of the vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
TextGuardianMetaInitialize	method dynamic TextGuardianClass, 
							MSG_META_INITIALIZE
	.enter

	mov	di, offset TextGuardianClass
	CallSuper	MSG_META_INITIALIZE

	GrObjDeref	di,ds,si
	mov	ds:[di].GOVGI_class.segment, segment GrObjTextClass
	mov	ds:[di].GOVGI_class.offset, offset GrObjTextClass

	ornf	ds:[di].TGI_flags, mask TGF_ENFORCE_MIN_DISPLAY_SIZE or \
				   mask	TGF_ENFORCE_DESIRED_MIN_HEIGHT

	;    Set GOMOF_DRAW_FG_AREA so that a null area mask won't stop
	;    the text from getting drawn.
	;

	ornf	ds:[di].GOI_msgOptFlags,mask GOMOF_SPECIAL_RESIZE_CONSTRAIN or\
					mask GOMOF_SEND_UI_NOTIFICATION or \
					mask GOMOF_DRAW_BG or \
					mask GOMOF_DRAW_FG_AREA

	mov	ds:[di].TGI_desiredMinHeight,
			TEXT_GUARDIAN_DESIRED_HEIGHT_UNDEFINED
	mov	ds:[di].TGI_desiredMaxHeight,
			TEXT_GUARDIAN_DESIRED_HEIGHT_UNDEFINED

	;   Text objects have the guardian control the create and
	;   can edit existing texts objects
	;

	andnf	ds:[di].GOVGI_flags,not mask GOVGF_CREATE_MODE
	ornf	ds:[di].GOVGI_flags, GOVGCM_GUARDIAN_CREATE \
					shl offset GOVGF_CREATE_MODE or \
					mask GOVGF_CAN_EDIT_EXISTING_OBJECTS


	.leave
	ret
TextGuardianMetaInitialize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGetEditClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We can edit up to TextGuardianClass

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

RETURN:		
		cx:dx - fptr to class
	
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
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGetEditClass	method dynamic TextGuardianClass, 
						MSG_GOVG_GET_EDIT_CLASS
	.enter

	mov	cx,segment TextGuardianClass
	mov	dx,offset TextGuardianClass

	.leave
	ret
TextGuardianGetEditClass		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGetPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return od of pointer image

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		ss:bp - PointDWFixed

RETURN:		
		ax - mask MRF_NEW_POINTER_IMAGE
		cx:dx - od of pointer image
	
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
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGetPointerImage	method dynamic TextGuardianClass, 
						MSG_GO_GET_POINTER_IMAGE
	.enter

	call	GrObjVisGuardianGetObjectUnderPointToEdit
	jcxz	noEdit

	mov	cl,GOPIS_EDIT
getImage:
	mov	ax,MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	call	ObjCallInstanceNoLock

	.leave
	ret

noEdit:
	mov	cl,GOPIS_CREATE
	jmp	getImage

TextGuardianGetPointerImage		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGetSituationalPointerImage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return default pointer images for situation

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		cl - GrObjPointerImageSituation

RETURN:		
		ah - high byte of MouseReturnFlags
			MRF_SET_POINTER_IMAGE or MRF_CLEAR_POINTER_IMAGE
		if MRF_SET_POINTER_IMAGE
		cx:dx - optr of mouse image
	
DESTROYED:	
		al

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGetSituationalPointerImage	method dynamic TextGuardianClass, 
					MSG_GO_GET_SITUATIONAL_POINTER_IMAGE
	.enter

	mov	ax,mask MRF_SET_POINTER_IMAGE

	cmp	cl,GOPIS_CREATE
	je	create

	cmp	cl,GOPIS_NORMAL
	je	create

	cmp	cl,GOPIS_EDIT
	je	edit

	mov	ax,mask MRF_CLEAR_POINTER_IMAGE

done:
	.leave
	ret

create:
	mov	cx,handle ptrTextCreate
	mov	dx,offset ptrTextCreate
	jmp	done

edit:
	mov	cx,handle ptrTextEdit
	mov	dx,offset ptrTextEdit
	jmp	done

TextGuardianGetSituationalPointerImage	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGetBoundingRectDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the TextGuardianDWFixed that bounds the object in
		the dest gstate coordinate system

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		ss:bp - BoundingTextGuardianData
			destGState
			parentGState

RETURN:		
		ss:bp - BoundingTextGuardianData
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
TextGuardianGetBoundingRectDWFixed method dynamic TextGuardianClass, 
					MSG_GO_GET_BOUNDING_RECTDWFIXED
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	CallMod	GrObjAdjustRectDWFixedByLineWidth

	.leave
	ret
TextGuardianGetBoundingRectDWFixed		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianAnotherToolActivated
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify selected and edited objects that another tool
		has been activated. If the Text is not editing
		it should just call its superclass. If, however, it
		is editing and the class of the tool being activated
		is TextGuardian then it should keep the edit. 
		

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
			The activating class will be TextGuardian since
			that is the class of all Text editing tools
		
		We can't depend on the GrObjTempModes being set correctly
		while handling this messages. Because a tool my activate
		even if we aren't the target.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianAnotherToolActivated	method dynamic TextGuardianClass, 
					MSG_GO_ANOTHER_TOOL_ACTIVATED
	uses	ax,cx,dx,bp
	.enter

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jnz	callSuper

	test	bp,mask ATAF_SHAPE or mask ATAF_STANDARD_POINTER
	jnz	callSuper
	
	;    Since a standard pointer is not activating we clearly
	;    can't remain selected
	;

	mov	ax,MSG_GO_BECOME_UNSELECTED
	call	ObjCallInstanceNoLock

	;    If activating tool is in the edit class then
	;    we can remain editing.
	;

	push	si					;guardian chunk
	push	cx,dx					;od activating
	mov	ax,MSG_GOVG_GET_EDIT_CLASS
	call	ObjCallInstanceNoLock
	pop	bx,si					;activating lmem
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	push	bp
	mov	ax,MSG_META_IS_OBJECT_IN_CLASS
	call	ObjMessage
	pop	bp
	jnc	callSuperPopSI

	;    Have activating TextGuardian update us with
	;    its TextGuardianMode.
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
	mov	di,offset TextGuardianClass
	mov	ax,MSG_GO_ANOTHER_TOOL_ACTIVATED
	call	ObjCallSuperNoLock
	jmp	short done


TextGuardianAnotherToolActivated		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianEndCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We don't want tiny text objects being rejected by the
		default handler. So we have our own.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		cx - EndCreatePassFlags

RETURN:		
		cx - EndCreateReturnFlags
	
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
	srs	11/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianEndCreate	method dynamic TextGuardianClass, 
						MSG_GO_END_CREATE
	uses	dx
	.enter

	test	ds:[di].GOI_optFlags,mask GOOF_FLOATER
	jnz	error

	test	ds:[di].GOI_actionModes, mask GOAM_CREATE
	jz	error

	;    Erase any existing sprite
	;

	clr	dx					;no gstate
	call	MSG_GO_UNDRAW_SPRITE, GrObjClass

	;    Copy new object data from sprite to normal then
	;    eat the evidence.
	;

	call	GrObjCopySpriteToNormal
	call	GrObjDestroySpriteTransform

	;    Clean up mode bits
	;

	GrObjDeref	di,ds,si
	andnf	ds:[di].GOI_actionModes, not (	mask GOAM_ACTION_PENDING or \
						mask GOAM_ACTION_HAPPENING or \
						mask GOAM_ACTION_ACTIVATED )

	;   Since the vis bounds can only be integers and we want
	;   the object dimensions to match the vis bounds we round
	;   our WWFixed object dimensions
	;

	call	GrObjVisGuardianRoundOBJECTDimensions

	;   Regardless of how the text object was opened we want it
	;   right side up
	;

	call	TextGuardianOrderOBJECTDimensions

	call	TextGuardianCheckCanClickCreate
	jc	clickCreate

	test	cx,mask ECPF_ADJUSTED_CREATE
	jz	desiredHeights
	mov	ax,MSG_GO_ADJUST_CREATE
	call	ObjCallInstanceNoLock

desiredHeights:
	;    Calcing these now prevents us from shrinking when
	;    the initial HEIGHT_NOTIFY from the ward tells us
	;    to be only one line of text high.

	mov	ax,MSG_TG_CALC_DESIRED_MIN_HEIGHT
	call	ObjCallInstanceNoLock
	mov	ax,MSG_TG_CALC_DESIRED_MAX_HEIGHT
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	;    Notify ourselves that we have sucessfuly completed the 
	;    interactive create
	;

	mov	ax,MSG_GO_SUSPEND_COMPLETE_CREATE
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_RELEASE_MOUSE
	call	ObjCallInstanceNoLock

	clr	cx				;no return flags

	;    Balance ignore actions in MSG_GO_BEGIN_CREATE
	;

	call	GrObjGlobalUndoAcceptActions

done:	
	.leave
	ret
error:
	mov	cx,mask ECRF_NOT_CREATING
	jmp	done

clickCreate:
	call	TextGuardianClickCreate
	jmp	desiredHeights

TextGuardianEndCreate		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCompleteCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After text has been interactively created: 
		Have it become editable
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
	srs	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCompleteCreate	method dynamic TextGuardianClass, 
				MSG_GO_COMPLETE_CREATE
	uses	cx, dx, bp
	.enter

	mov	ax,MSG_GO_COMPLETE_CREATE
	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_GO_BECOME_EDITABLE
	call	ObjCallInstanceNoLock

	.leave
	ret


TextGuardianCompleteCreate		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianAdjustCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	After text has been interactively created: 
		Have it become editable
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
	srs	8/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianAdjustCreate	method dynamic TextGuardianClass, 
				MSG_GO_ADJUST_CREATE
	uses	cx, dx, bp
	.enter

	;
	;  Set the point size equal to the height of the object,
	;  fer Christ's sake.
	;
	mov	ax, MSG_GO_GET_SIZE
	call	ObjCallInstanceNoLock

	sub	sp, size VisTextSetPointSizeParams
	mov	di, sp
	movwwf	ss:[di].VTSPSP_pointSize, bpax
	mov	bp, di
	clrdw	ss:[bp].VTSPSP_range.VTR_start
	movdw	ss:[bp].VTSPSP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ax, MSG_VIS_TEXT_SET_POINT_SIZE
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	add	sp, size VisTextSetPointSizeParams

	.leave
	ret
TextGuardianAdjustCreate		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianOrderOBJECTDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the width and height both positive to remove
		any flip from the text object

CALLED BY:	INTERNAL
		TextGuardianCompleteCreate

PASS:		*ds:si - Text Guardian

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
	srs	11/ 8/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianOrderOBJECTDimensions		proc	near
	uses	ax,bx,cx,dx
	.enter

	call	GrObjGetNormalOBJECTDimensions
	tst	dx
	js	negWidth
checkHeight:
	tst	bx
	js	negHeight

setDimensions:
	call	GrObjSetNormalOBJECTDimensions

	.leave
	ret

negWidth:
	negwwf	dxcx
	jmp	checkHeight

negHeight:
	negwwf	bxax
	jmp	setDimensions


TextGuardianOrderOBJECTDimensions		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCheckCanClickCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If text object is narrow and no taller
		than one line of text it could have
		been create by just a click.

CALLED BY:	INTERNAL
		TextGuardianCompleteCreate

PASS:		*ds:si - TextGuardian

RETURN:		
		stc - can click create
		clc - buzz

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
	srs	5/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TEXT_GUARDIAN_MAX_DIMENSION_FOR_CLICK_CREATE equ 8
TEXT_GUARDIAN_DEFAULT_WIDTH equ 6*72

TextGuardianCheckCanClickCreate		proc	near
	class	TextGuardianClass
	uses	ax,bx,cx,dx,di,bp
	.enter

EC <	call	ECTextGuardianCheckLMemObject			>

	;    If object width isn't small enough then don't hooey with it
	;

	call	GrObjGetAbsNormalOBJECTDimensions
	cmp	dx, TEXT_GUARDIAN_MAX_DIMENSION_FOR_CLICK_CREATE
	ja	fail

	stc

done:
	.leave
	ret

fail:
	clc
	jmp	done

TextGuardianCheckCanClickCreate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianClickCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size and position of the object for
		a click create

CALLED BY:	INTERNAL
		TextGuardianCompleteCreate

PASS:		*ds:si - TextGuardian

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
	srs	5/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianClickCreate		proc	near
	class	TextGuardianClass
	uses	ax,bx,cx,dx,bp,di
	.enter

	;    Resize the object anchoring the upper left
	;    and grabbing the lower right.
	;

	sub	sp,size PointDWFixed
	mov	bp,sp
	clr	ax
	mov	ss:[bp].PDF_x.DWF_frac,ax
	mov	ss:[bp].PDF_y.DWF_frac,ax

	call	GrObjGetNormalOBJECTDimensions

	;    Width resize is DEFAULT-current width.
	;    Ignoring fracs because they should all be zero.
	;

	call	TextGuardianCalcClickCreateWidth
	sub	cx,dx
	mov	ss:[bp].PDF_x.DWF_int.low,cx
	mov_tr	ax,cx
	cwd
	mov	ss:[bp].PDF_x.DWF_int.high,dx

	;    Height resize is calced height - current height
	;

	call	TextGuardianCalcEmptyNormalizedHeight
	sub	dx,bx					;calced - current
	mov	ss:[bp].PDF_y.DWF_int.low,dx
	mov_tr	ax,dx
	cwd
	mov	ss:[bp].PDF_y.DWF_int.high,dx

	;    Do resize
	;

	mov	cl,HANDLE_LEFT_TOP			;anchor
	mov	ch,HANDLE_RIGHT_BOTTOM		;grabbed
	call	GrObjInteractiveResizeNormalRelative
	add	sp,size PointDWFixed	

	GrObjDeref	di,ds,si
	BitSet	ds:[di].TGI_flags, TGF_SHRINK_WIDTH_TO_MIN_AFTER_EDIT

	call	GrObjVisGuardianRoundOBJECTDimensions

	.leave
	ret
TextGuardianClickCreate		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCalcEmptyNormalizedHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A scummy little routine that calculates the height
		of the object the MSG_GOVG_NORMALIZE will produce for
		a text object that has no text in it.

CALLED BY:	INTERNAL
		TextGuardianClickCreate
		TextGuardianCheckCanClickCreate

PASS:		*ds:si - TextGuardian

RETURN:		
		dx - height

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
	srs	6/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCalcEmptyNormalizedHeight		proc	near
	uses	cx
	.enter

	;    Doing a calc height with any nonzero width on an empty 
	;    text object will return the height of one line in the
	;     current font, point size, etc
	;

	mov	cx,TEXT_GUARDIAN_MAX_DIMENSION_FOR_CLICK_CREATE
	call	TextGuardianCalcNormalizedHeight

	.leave
	ret
TextGuardianCalcEmptyNormalizedHeight		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCalcNormalizedHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A scummy little routine that calculates the height
		of the object the MSG_GOVG_NORMALIZE will produce.

CALLED BY:	INTERNAL
		TextGuardianCalcEmptyNormalizedHeight
		TextGuardianExpandHeightIfNecessary


PASS:		*ds:si - TextGuardian
		cx - width to calc height with

RETURN:		
		dx - height

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
	srs	6/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCalcNormalizedHeight		proc	near
	class	TextGuardianClass
	uses	ax,cx,di,bp
	.enter

	clr	dx					;don't cache
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_VIS_TEXT_CALC_HEIGHT
	call	GrObjVisGuardianMessageToVisWard

	;    Add in half the line width
	;

	call	GrObjGetLineWidth
	shrwwf	dibp
	add	dx,di
	rndwwf	dxbp

	.leave
	ret
TextGuardianCalcNormalizedHeight		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCalcClickCreateWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some dufus is probably going to ask me to set the
		width so that the object doesn't go out of the window
		or the document. I show him/her this routine.

CALLED BY:	INTERNAL
		TextGuardianClickCreate

PASS:		
		*ds:si - TextGuardian

RETURN:		
		cx - width

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
	srs	5/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCalcClickCreateWidth		proc	near
	.enter

EC <	call	ECTextGuardianCheckLMemObject			>

	mov	cx, TEXT_GUARDIAN_DEFAULT_WIDTH

	.leave
	ret
TextGuardianCalcClickCreateWidth		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCompleteTransform
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the text objects vis bounds to match the
		size of the guardian.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		bp - GrObjActionNotificationType

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
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCompleteTransform	method dynamic TextGuardianClass, 
						MSG_GO_COMPLETE_TRANSFORM
	.enter

	call	GrObjVisGuardianRoundOBJECTDimensions
	
	mov	ax,MSG_TG_CALC_DESIRED_MIN_HEIGHT
	call	ObjCallInstanceNoLock

	mov	ax,MSG_TG_CALC_DESIRED_MAX_HEIGHT
	call	ObjCallInstanceNoLock

	;    Set the vis wards vis bounds accordingly to match
	;    the OBJECT dimensions
	;

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	;    Call super class to complete handling of message
	;

	mov	ax,MSG_GO_COMPLETE_TRANSFORM
	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	.leave
	ret
TextGuardianCompleteTransform		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianJumpStartResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a cached state in the text object so that
		one isn't created every pointer event because
		of MSG_VIS_TEXT_CALC_HEIGHT

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		bp - GrObjFunctionsActive
		dx - gstate to draw through or 0

RETURN:		
		ax - MouseReturnFlags
	
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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianJumpStartResize	method dynamic TextGuardianClass, 
						MSG_GO_JUMP_START_RESIZE
	uses	cx,dx,bp
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	push	ax					;MouseReturnFlagss
	mov	ax,MSG_VIS_CREATE_CACHED_GSTATES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	ax					;MouseReturnFlags

	.leave
	ret
TextGuardianJumpStartResize		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianEndResize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy the gstate we created on MSG_GO_JUMP_START_RESIZE

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		ss:bp = GrObjResizeMouseData
			GORSMD_point - deltas to resize
			GORSMD_gstate - gstate to draw with
			GORSMD_goFA - GrObjFunctionsActive
			GORSMD_anchor - anchored handle

RETURN:		
		ax - MouseReturnFlags
	
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
	srs	8/31/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianEndResize	method dynamic TextGuardianClass, 
						MSG_GO_END_RESIZE
	uses	cx,dx,bp
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	push	ax					;MouseReturnFlags
	mov	ax,MSG_VIS_DESTROY_CACHED_GSTATES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	pop	ax					;MouseReturnFlags

	.leave
	ret
TextGuardianEndResize		endm







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianSpecialResizeConstrain
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enforce min display size in sprite data if ENFORCE bit
		is set.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		cl - GrObjHandleSpecification of anchor
RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianSpecialResizeConstrain	method dynamic TextGuardianClass, 
						MSG_GO_SPECIAL_RESIZE_CONSTRAIN
	uses	cx,dx,bp
	.enter

	;   In create mode there is no text that we must be big enough 
	;   to hold.
	;

	test	ds:[di].GOI_actionModes,mask GOAM_CREATE
	jnz	done

	mov	di,cx					;anchor
	call	GrObjGetAbsSpriteOBJECTDimensions
	sub	sp,size PointDWFixed
	mov	bp,sp
	call	TextGuardianCalcGuaranteedDisplayHeightIncrease
	jnc	clearStackFrame
	mov	cx,di					;anchor
	call	GrObjResizeSpriteRelativeToSprite
clearStackFrame:
	add	sp,size PointDWFixed

done:
	.leave
	ret
TextGuardianSpecialResizeConstrain		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCalcGuaranteedDisplayHeightIncrease
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the text object is not tall enough to display
		all the text at the passed width then
		calc the height increase necessary to make it tall
		enough.

CALLED BY:	INTERNAL
		TextGuardianSpecialResizeConstrain

PASS:		
		*ds:si - TextGuardian
		ss:bp - PointDWFixed - empty
		dx:cx - current width
		bx:ax - current height

RETURN:		
		clc - don't need to resize
		stc - need to resize
			ss:bp - PDF_x = 0.0
			ss:bp - PDF_y - necessary height increase

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
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCalcGuaranteedDisplayHeightIncrease		proc	near
	class	TextGuardianClass
	uses	ax,cx,bx,dx,di
	.enter

EC <	call	ECTextGuardianCheckLMemObject			>
	
	GrObjDeref	di,ds,si
	test	ds:[di].TGI_flags,mask TGF_ENFORCE_MIN_DISPLAY_SIZE
	jz	noChange

	;    Get necessary height from absolute value of current width
	;

	push	ax					;current height frac
	rndwwf	dxcx					;current width
	mov	cx,dx
	clr	dx
	mov	ax,MSG_VIS_TEXT_CALC_HEIGHT
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard
	pop	ax					;current height frac

	;    If necessary height > current height calc height change
	;    otherwise punt
	;

	cmp	dx,bx					;nec height,cur height
	jl	noChange
	jg	change
	tst	ax					;current height frac
	jz	noChange

change:
	
	clr	cx					;necessary height frac
	mov	ss:[bp].PDF_x.DWF_int.high,cx
	mov	ss:[bp].PDF_x.DWF_int.low,cx
	mov	ss:[bp].PDF_x.DWF_frac,cx
	mov	ss:[bp].PDF_y.DWF_int.high,cx		;will always be +
	
	;    Height increase is necessary height - current height
	;

	subwwf	dxcx,bxax
	mov	ss:[bp].PDF_y.DWF_int.low,dx
	mov	ss:[bp].PDF_y.DWF_frac,cx

	stc
done:
	.leave
	ret

noChange:
	clc
	jmp	done

TextGuardianCalcGuaranteedDisplayHeightIncrease		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCalcDesiredMinHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Calculate and set the TGI_desiredMinHeight field in the text guardian
	object.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			minDesiredHeight is defined

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCalcDesiredMinHeight	method dynamic TextGuardianClass, 
						MSG_TG_CALC_DESIRED_MIN_HEIGHT
	uses	cx,dx,bp
	.enter

	call	GrObjGetAbsNormalOBJECTDimensions

	rndwwf	bxax
	mov	cx,bx
	mov	ax,MSG_TG_SET_DESIRED_MIN_HEIGHT
	call	ObjCallInstanceNoLock

	.leave
	ret
TextGuardianCalcDesiredMinHeight		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianSetDesiredMinHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set the TGI_desiredMinHeight field in the text guardian
		object. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		cx - desired size in points

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
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianSetDesiredMinHeight	method dynamic TextGuardianClass, 
						MSG_TG_SET_DESIRED_MIN_HEIGHT
	.enter

	mov	ds:[di].TGI_desiredMinHeight,cx

	.leave
	ret
TextGuardianSetDesiredMinHeight		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCalcDesiredMaxHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	Calculate and set the TGI_desiredMaxHeight field in the text guardian
	object.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			maxDesiredHeight is defined

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianCalcDesiredMaxHeight	method dynamic TextGuardianClass, 
						MSG_TG_CALC_DESIRED_MAX_HEIGHT
	uses	cx,dx,bp
	.enter

	call	GrObjGetAbsNormalOBJECTDimensions

	rndwwf	bxax
	mov	cx,bx
	mov	ax,MSG_TG_SET_DESIRED_MAX_HEIGHT
	call	ObjCallInstanceNoLock

	.leave
	ret
TextGuardianCalcDesiredMaxHeight		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianSetDesiredMaxHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Set the TGI_desiredMaxHeight field in the text guardian
		object. 

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		cx - desired size in points

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
	srs	5/ 5/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianSetDesiredMaxHeight	method dynamic TextGuardianClass, 
						MSG_TG_SET_DESIRED_MAX_HEIGHT
	.enter

	mov	ds:[di].TGI_desiredMaxHeight,cx

	.leave
	ret
TextGuardianSetDesiredMaxHeight		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust ObjectTransform for the text objects height

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		dx - height text object wants to be

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
	srs	5/ 7/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianHeightNotify	method dynamic TextGuardianClass, 
						MSG_TG_HEIGHT_NOTIFY
	uses	dx
	.enter

	;    If we are being edited we can't bail from this routine. Even
	;    if TGF_ENFORCE_MIN_DISPLAY_SIZE isn't set editing is lame if
	;    the text object can't grow to accomodate the text being
	;    entered or if it can't shrink. This still allows the
	;    text object to bump into its min/max sizes.
	;        

	test	ds:[di].GOI_tempState, mask GOTM_EDITED
	jnz	10$

	;   If no size things to enforce then leave object at its
	;   current size.
	;

	test	ds:[di].TGI_flags, mask TGF_ENFORCE_MIN_DISPLAY_SIZE or\
				mask TGF_ENFORCE_DESIRED_MIN_HEIGHT or\
				mask TGF_ENFORCE_DESIRED_MAX_HEIGHT

	jz	done

10$:
	test	ds:[di].TGI_flags,mask TGF_ENFORCE_DESIRED_MIN_HEIGHT
	jz	checkMax

	;   Make sure that we don't go below the minimum
	;

	cmp	ds:[di].TGI_desiredMinHeight,
				TEXT_GUARDIAN_DESIRED_HEIGHT_UNDEFINED
	je	checkMax
	cmp	dx,ds:[di].TGI_desiredMinHeight
	jge	checkMax
	mov	dx,ds:[di].TGI_desiredMinHeight

checkMax:
	test	ds:[di].GOI_tempState, mask GOTM_EDITED
	jz	20$
	test	ds:[di].TGI_flags, \
		mask TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING
	jnz	invalidate
20$:
	test	ds:[di].TGI_flags, mask TGF_ENFORCE_DESIRED_MAX_HEIGHT
	jz	invalidate

	;    Make sure we don't go above the maximum
	;	

	cmp	ds:[di].TGI_desiredMaxHeight,
				TEXT_GUARDIAN_DESIRED_HEIGHT_UNDEFINED
	je	invalidate
	cmp	dx,ds:[di].TGI_desiredMaxHeight
	jle	invalidate
	mov	dx,ds:[di].TGI_desiredMaxHeight

invalidate:
	call	TextGuardianHeightNotifyInvalidate
	call	TextGuardianHeightNotifyText
done:
	.leave
	ret

TextGuardianHeightNotify		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianHeightNotifyText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle height notify for an object that is being
		treated as text ( not as a graphic).Change
		height from current height to new height and
		then update text objects vis bounds

CALLED BY:	INTERNAL
		TextGuardianHeightNotify

PASS:		*ds:si - TextGuardian
		dx - new height
		
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
	srs	5/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianHeightNotifyText		proc	near
	class	TextGuardianClass
	uses	ax,cx,dx,bp
	.enter

EC <	call	ECTextGuardianCheckLMemObject		>

	;    If the current height = new height then do nothing.
	;    Othewise just calc the height change from current to new.
	;

	call	TextGuardianGetVisWardHeight
	cmp	dx,bx					;new height, cur height
	je	done

	mov	bp,GOANT_PRE_RESIZE
	call	GrObjOptNotifyAction

	call	GrObjVisGuardianBeginEditGeometryCommon

	sub	dx,bx					;height change
	sub	sp,size PointDWFixed
	mov	bp,sp
	clr	ax					;necessary height frac
	mov	ss:[bp].PDF_x.DWF_int.high,ax
	mov	ss:[bp].PDF_x.DWF_int.low,ax
	mov	ss:[bp].PDF_x.DWF_frac,ax
	mov	ss:[bp].PDF_y.DWF_frac,ax
	mov	ss:[bp].PDF_y.DWF_int.low,dx
	mov	ax,dx
	cwd
	mov	ss:[bp].PDF_y.DWF_int.high,dx
	mov	cl,HANDLE_MIDDLE_TOP
	call	GrObjResizeNormalRelative
	add	sp,size PointDWFixed

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjVisGuardianEndEditGeometryCommon

	BitSet	ds:[di].GOVGI_flags, GOVGF_VIS_BOUNDS_HAVE_CHANGED

	mov	bp,GOANT_RESIZED
	call	GrObjOptNotifyAction

done:

	.leave
	ret
TextGuardianHeightNotifyText		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGetVisWardHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return vis height of vis ward

CALLED BY:	INTERNAL
		TextGuardianHeightNotifyText

PASS:		*ds:si - TextGuardian

RETURN:		
		bx - height in points

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
	srs	5/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGetVisWardHeight		proc	near
	uses	ax,cx,dx,bp,di
	.enter

	mov	ax,MSG_VIS_GET_BOUNDS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard
	mov	bx,dx					;current bottom
	sub	bx,bp					;current height

	.leave
	ret
TextGuardianGetVisWardHeight		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianHeightNotifyInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the area that the text object is growing into
		or is shrinking away from.

CALLED BY:	INTERNAL
		TextGuardianHeightNotify

PASS:		
		*ds:si - TextGuardian
		dx -  new height

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
	srs	5/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianHeightNotifyInvalidate		proc	near
	uses	ax,bx,cx,dx,bp,di
	.enter

EC <	call	ECTextGuardianCheckLMemObject		>

	;   If aren't being edited then don't try any fancy optimized
	;   invalidation. I am expecting this routine to be
	;   called between a call to GrObjVisGuardianBeginEditGeometryCommon
	;   and GrObjVisGuardianEndEditGeometryCommon
	;

	test	ds:[di].GOI_tempState,mask GOTM_EDITED
	jz	done

	push	dx					;new height
	mov	ax,MSG_VIS_GET_BOUNDS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard
	mov	bx,dx					;current bottom
	sub	bx,bp					;current height
	pop	dx					;new height
	cmp	dx,bx					;new height, cur height
	jne	invalidate

done:
	.leave
	ret

invalidate:
	;    We need to invalidate between the new bottom and the
	;    current bottom. The registers currently hold the
	;    following data.
	;    ax - left of vis bounds
	;    cx - right of vis bounds
	;    dx - new height
	;    bx - current height
	;    bp - top of vis bounds
	;

	push	dx,ax					;new height, cur top
	mov	di,OBJECT_GSTATE
	call	GrObjCreateGState
	mov	dx,di					;gstate
	call	GrObjVisGuardianOptApplyOBJECTToVISTransform
	mov	di,dx					;gstate
	mov	dx,bx					;current height
	pop	bx,ax					;new height,cur top
	add	bx,bp					;new bottom
	add	dx,bp					;current bottom
	
	;    Make smaller bottom the top of the inval rect
	;

	cmp	bx,dx					
	jle	inval
	xchg	bx,dx					
inval:
	dec	ax					;avoid some greebles.
	dec	bx
	inc	cx
	inc	dx
	call	GrInvalRect
	call	GrDestroyState
	jmp	done

TextGuardianHeightNotifyInvalidate		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGainedSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select all the text so that
		text attribute changes to the text object would
		affect all of the text.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGainedSelectionList	method dynamic TextGuardianClass, 
						MSG_GO_GAINED_SELECTION_LIST
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	;    Must select after calling super, otherwise text object
	;    will try to invert the selection range
	;

	mov	ax,MSG_VIS_TEXT_SELECT_ALL
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
TextGuardianGainedSelectionList		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianLostSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deselect the text that was selected on gained message.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianLostSelectionList	method dynamic TextGuardianClass, 
						MSG_GO_LOST_SELECTION_LIST
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	mov	di,mask MF_FIXUP_DS
	clr	cx,dx
	mov	ax,MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
TextGuardianLostSelectionList		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the texts object is transparent, we need
		to mark it as non-tranparent and redraw it now so
		that the blitting it does during editing won't smear
		the images of objects behind it.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGainedTargetExcl	method dynamic TextGuardianClass, 
						MSG_META_GAINED_TARGET_EXCL
	.enter

	call	TextGuardianExpandHeightIfNecessary

	;    Call super first so that the draw message below
	;    won't stomp over selection handles.
	;    

	mov	ax,MSG_META_GAINED_TARGET_EXCL
	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	call	GrObjGetAreaInfoAndMask
	test	al,mask GOAAIR_TRANSPARENT
	jz	done

	;    Clear the transparent bit and redraw the text object.
	;    This will draw the text object with the wash color
	;    color underneath it so that when the text object
	;    blits stuff around it won't be moving pieces of
	;    objects that are underneath it.
	;

	mov	di,mask MF_FIXUP_DS
	clr	cx
	mov	dx,mask VTF_TRANSPARENT
	mov	ax,MSG_VIS_TEXT_SET_FEATURES
	call	GrObjVisGuardianMessageToVisWard	

	;    Because we now that the text object doesn't have
	;    a hi res mode we can just clear the GrObjDrawFlags
	;

	mov	di,PARENT_GSTATE
	call	GrObjCreateGState
	mov	bp,di				;gstate
	clr	cx,dx				;DrawFlags, GrObjDrawFlags
	mov	ax,MSG_GO_DRAW
	call	ObjCallInstanceNoLock
	call	GrDestroyState

done:
	Destroy	ax,cx,dx,bp

	.leave
	ret
TextGuardianGainedTargetExcl		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the object is see-thru, then reset the text objects
		TRANSPARENT bit which was modified for editing.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 9/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianLostTargetExcl	method dynamic TextGuardianClass, 
						MSG_META_LOST_TARGET_EXCL
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	call	TextGuardianShrinkWidthAfterClickCreate
	jc	done
	call	TextGuardianShrinkHeightIfNecessary

	call	GrObjGetAreaInfoAndMask
	test	al,mask GOAAIR_TRANSPARENT
	jz	done

	mov	di,mask MF_FIXUP_DS
	mov	cx,mask VTF_TRANSPARENT
	clr	dx
	mov	ax,MSG_VIS_TEXT_SET_FEATURES
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard	

	;    Redraw text object so that other objects can
	;    show through again.
	;

	call	GrObjOptInvalidate


done:
	.leave

	Destroy	ax,cx,dx,bp

	ret
TextGuardianLostTargetExcl		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianExpandHeightIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If TGF_ENFORCE_DESIRED_MAX_HEIGHT and 
		TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING are set
		then expand text object so that all the text will be
		displayed

CALLED BY:	INTERNAL
		TextGuardianGainedTargetExcl

PASS:		*ds:si - Guardian

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianExpandHeightIfNecessary		proc	near
	class	TextGuardianClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECTextGuardianCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].TGI_flags, \
		mask TGF_ENFORCE_DESIRED_MAX_HEIGHT
	jz	done
	test	ds:[di].TGI_flags, \
		mask TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING
	jz	done

	call	GrObjBeginGeometryCommon

	;    If height necessary to display all the text at the
	;    the current width is greater than the
	;    than the current height then expand the height
	;

	call	GrObjGetAbsNormalOBJECTDimensions
	rndwwf	dxcx
	mov	cx,dx					;current width
	call	TextGuardianCalcNormalizedHeight

	rndwwf	bxax					;current height
	cmp	bx,dx					;cur height, nec height
	jge	done

	sub	dx,bx					;nec height-cur height

	;    Resize the object
	;

	sub	sp,size PointDWFixed
	mov	bp,sp
	mov	ax,dx					;height change
	cwd
	mov	ss:[bp].PDF_y.DWF_int.high,dx
	mov	ss:[bp].PDF_y.DWF_int.low,ax
	clr	ax
	clrdwf	ss:[bp].PDF_x,ax
	mov	ss:[bp].PDF_y.DWF_frac,ax	
	mov	cl,HANDLE_MIDDLE_TOP
	call	GrObjResizeNormalRelative
	add	sp,size PointDWFixed

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjEndGeometryCommon
done:

	.leave
	ret
TextGuardianExpandHeightIfNecessary		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianShrinkWidthAfterClickCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the TGF_SHRINK_WIDTH_TO_MIN_AFTER_EDIT is set
		then shrink the text object.

CALLED BY:	INTERNAL
		TextGuardianLostTargetExcl

PASS:		*ds:si - Guardian

RETURN:		
		clc - boring
		stc - the text object had no text, it has been nuked

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianShrinkWidthAfterClickCreate		proc	near
	class	TextGuardianClass
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECTextGuardianCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].TGI_flags, mask TGF_SHRINK_WIDTH_TO_MIN_AFTER_EDIT
	jz	done				;impled clc

	;    Check for the text object having no characters. I am
	;    not checking the high word of the number of characters
	;    because grobj text objects just can't have that many 
	;    characters.
	;	

	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	mov	ax,MSG_VIS_TEXT_GET_TEXT_SIZE
	call	GrObjVisGuardianMessageToVisWard
	tst	ax					;num of chars low word
	jnz	shrink

	;
	; Destroy this object, but not if the document is closing, as
	; we will crash.  (This is a hack.)
	;

	push	si
	movdw	bxsi, ds:[OLMBH_output]
	call	ObjLockObjBlock
	mov	es, ax
	mov	si, es:[si]
	add	si, es:[si].GrObjBody_offset
	test	es:[si].GBI_fileStatus, mask GOFS_OPEN
	call	MemUnlock
	pop	si

	jz	done			; carry is clear

	

	;    Sneaky trick to prevent the object from flashing
	;    it's handles before it is destroyed and to prevent
	;    it from getting the target again while in the
	;    process of being destroyed.
	;

	GrObjDeref	di,ds,si
	ornf	ds:[di].GOI_locks, mask GOL_SELECT or mask GOL_EDIT

	;    Must send this on the queue otherwise the code will
	;    loop infinitely because destroying the object releases
	;    the target and we are in the process of handling a lost
	;    target.
	;

	mov	bx,ds:[LMBH_handle]
	mov	di,mask MF_FORCE_QUEUE
	mov	ax,MSG_GO_CLEAR_SANS_UNDO
	call	ObjMessage
	stc						;flag it was nuked

done:
	.leave
	ret

shrink:
	call	GrObjBeginGeometryCommon

	;    Get the current width and the desired minimum width
	;    and calculate the width change from the current to the new
	;

	call	GrObjGetAbsNormalOBJECTDimensions
	mov	cx,dx					;current width

	sub	sp,size VisTextMinimumDimensionsParameters
	mov	bp,sp
	mov	dx,ss
	mov	ax,MSG_VIS_TEXT_GET_MINIMUM_DIMENSIONS
	mov	di,mask MF_FIXUP_DS or mask MF_CALL
	push	cx					;current width
	call	GrObjVisGuardianMessageToVisWard
	mov	dx,ss:[bp].VTMDP_width.WBF_int		;new width
	tst	ss:[bp].VTMDP_width.WBF_frac
	jz	10$
	inc	dx					;round up new width
10$:
	pop	cx					;current width
	add	sp,size VisTextMinimumDimensionsParameters
	sub	dx,cx					;width change

	;    Resize the object
	;

	sub	sp,size PointDWFixed
	mov	bp,sp
	clr	ax
	clrdwf	ss:[bp].PDF_y,ax
	mov	ss:[bp].PDF_x.DWF_frac,ax	
	mov	ss:[bp].PDF_x.DWF_int.low,dx
	mov_tr	ax,dx					;width change
	cwd						;sign extend change
	mov	ss:[bp].PDF_x.DWF_int.high,dx
	mov	cl,HANDLE_LEFT_MIDDLE
	call	GrObjResizeNormalRelative
	add	sp,size PointDWFixed

	GrObjDeref	di,ds,si
	BitClr	ds:[di].TGI_flags,TGF_SHRINK_WIDTH_TO_MIN_AFTER_EDIT

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjEndGeometryCommon

	clc
	jmp	done

TextGuardianShrinkWidthAfterClickCreate		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianShrinkHeightIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If TGF_ENFORCE_DESIRED_MAX_HEIGHT and 
		TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING are set
		then shrink text object back to desiredMaxHeight

CALLED BY:	INTERNAL
		TextGuardianLostTargetExcl

PASS:		*ds:si - Guardian

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianShrinkHeightIfNecessary		proc	near
	class	TextGuardianClass
	uses	ax,bx,cx,dx,di
	.enter

EC <	call	ECTextGuardianCheckLMemObject				>

	GrObjDeref	di,ds,si
	test	ds:[di].TGI_flags, \
		mask TGF_ENFORCE_DESIRED_MAX_HEIGHT
	jz	done
	test	ds:[di].TGI_flags, \
		mask TGF_DISABLE_ENFORCED_DESIRED_MAX_HEIGHT_WHILE_EDITING
	jz	done

	call	GrObjBeginGeometryCommon

	;    If current height is greater than the desiredMaxHeight
	;    then shrink the height
	;

	call	GrObjGetAbsNormalOBJECTDimensions
	rndwwf	bxax
	mov	ax,ds:[di].TGI_desiredMaxHeight
	cmp	bx,ax
	jl	done

	sub	ax,bx

	;    Resize the object
	;

	sub	sp,size PointDWFixed
	mov	bp,sp
	cwd
	mov	ss:[bp].PDF_y.DWF_int.high,dx
	mov	ss:[bp].PDF_y.DWF_int.low,ax
	clr	ax
	clrdwf	ss:[bp].PDF_x,ax
	mov	ss:[bp].PDF_y.DWF_frac,ax	
	mov	cl,HANDLE_MIDDLE_TOP
	call	GrObjResizeNormalRelative
	add	sp,size PointDWFixed

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	mov	ax,MSG_GO_CALC_PARENT_DIMENSIONS
	call	ObjCallInstanceNoLock

	call	GrObjEndGeometryCommon
done:

	.leave
	ret
TextGuardianShrinkHeightIfNecessary		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianSetTextGuardianFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set text guardian flags

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		cl - TextGuardianFlags to set
		dl - TextGuardianFlags to reset

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianSetTextGuardianFlags	method dynamic TextGuardianClass, 
						MSG_TG_SET_TEXT_GUARDIAN_FLAGS
	uses	dx
	.enter

	not	dl
	andnf	ds:[di].TGI_flags,dl
	ornf	ds:[di].TGI_flags,cl

	.leave
	ret
TextGuardianSetTextGuardianFlags		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianInitToDefaultAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the text attributes after calling the super
		class to init the grobj attributes.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
	srs	5/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianInitToDefaultAttrs	method dynamic TextGuardianClass, 
						MSG_GO_INIT_TO_DEFAULT_ATTRS
	uses	cx,dx,bp

	.enter

	mov	di, 1000
	call	ThreadBorrowStackSpace
	push	di

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	;   We've decided that by default all text objects should
	;   be lineless. You can still enable the line on a text
	;   object, but you can't set the default attributes in
	;   anyway to get lines on the text objects you are about
	;   to create. So there.
	;

	mov	cl,SDM_0
	mov	ax,MSG_GO_SET_LINE_MASK
	call	ObjCallInstanceNoLock

	;    Create frames to hold data areas that must be passed
	;    with para messages
	;

	sub	sp,size VisTextMaxParaAttr
	mov	ax,sp
	sub	sp,size VisTextParaAttrDiffs
	mov	bx,sp

	;    Set up params to VIS_TEXT_GET_PARA_ATTR, pointing
	;    its stack frame at the stack frames just created.	
	;

	mov	dx,size VisTextGetAttrParams
	sub	sp,dx
	mov	bp,sp
	movdw	ss:[bp].VTGAP_attr, ssax
	movdw	ss:[bp].VTGAP_return, ssbx
	mov	ss:[bp].VTGAP_range.VTR_start.high,VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].VTGAP_flags, 0

	;    Get those attributes
	;

	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	ax,MSG_VIS_TEXT_GET_PARA_ATTR
	call	GrObjMessageToGOAMText

	;    Set those para attributes in our ward.
	;    Being a sneaky bastard we leave the same structure on the
	;    stack because the first two fields match.
	;

	mov	ss:[bp].VTGAP_range.VTR_start.high,VIS_TEXT_RANGE_SELECTION
	mov	dx,size VisTextSetParaAttrParams
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_VIS_TEXT_SET_PARA_ATTR
	call	GrObjVisGuardianMessageToVisWard

	;    Clear the stack of all those stack frames
	;

	add	sp, (size VisTextGetAttrParams + \
			size VisTextMaxParaAttr + \
			size VisTextParaAttrDiffs)


	;    Create frames to hold data areas that must be passed
	;    with char messages
	;

	sub	sp,size VisTextCharAttr
	mov	ax,sp
	sub	sp,size VisTextCharAttrDiffs
	mov	bx,sp

	;    Set up params to VIS_TEXT_GET_CHAR_ATTR, pointing
	;    its stack frame at the stack frames just created.	
	;

	mov	dx,size VisTextGetAttrParams
	sub	sp,dx
	mov	bp,sp
	movdw	ss:[bp].VTGAP_attr, ssax
	movdw	ss:[bp].VTGAP_return, ssbx
	mov	ss:[bp].VTGAP_range.VTR_start.high,VIS_TEXT_RANGE_SELECTION
	mov	ss:[bp].VTGAP_flags, 0

	;    Get those attributes
	;

	mov	di,mask MF_FIXUP_DS or mask MF_CALL or mask MF_STACK
	mov	ax,MSG_VIS_TEXT_GET_CHAR_ATTR
	call	GrObjMessageToGOAMText

	;    Set those char attributes in our ward.
	;    Being a sneaky bastard we leave the same structure on the
	;    stack because the first two fields match.
	;

	mov	ss:[bp].VTGAP_range.VTR_start.high,VIS_TEXT_RANGE_SELECTION
	mov	dx,size VisTextSetCharAttrParams
	mov	di,mask MF_FIXUP_DS or mask MF_STACK
	mov	ax,MSG_VIS_TEXT_SET_CHAR_ATTR
	call	GrObjVisGuardianMessageToVisWard

	;    Clear the stack of all those stack frames
	;

	add	sp, (size VisTextGetAttrParams + \
			size VisTextCharAttr + \
			size VisTextCharAttrDiffs)

	call	TextGuardianAdjustMarginsForLineWidth

	call	TextGuardianSetTransparentBit
	call	TextGuardianSetWashColor

	pop	di
	call	ThreadReturnStackSpace
	.leave
	ret
TextGuardianInitToDefaultAttrs		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianSetTransparentBit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the transparent bit in the text object to match
		the grobj bit

CALLED BY:	INTERNAL
		TextGuardianInitToDefaultAttrs
		TextGuardianNotifyAction

PASS:		
		*ds:si - guardian

RETURN:		
		nothign

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianSetTransparentBit		proc	far
	uses	ax,cx,dx,di
	.enter

	mov	cx,mask VTF_TRANSPARENT
	clr	dx
	call	GrObjGetAreaInfoAndMask
	test	al,mask GOAAIR_TRANSPARENT
	jnz	send
	xchg	cx,dx
send:
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_TEXT_SET_FEATURES
	call	GrObjVisGuardianMessageToVisWard

	.leave
	ret
TextGuardianSetTransparentBit		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianSetWashColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set wash color of the text object to match the
		background color of the grobject.

CALLED BY:	INTERNAL
		TextGuardianInitToDefaultAttrs
		TextGuardianNotifyAction

PASS:		
		*ds:si - guardian

RETURN:		
		nothign

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianSetWashColor		proc	far
	class	TextGuardianClass
	uses	ax,cx,dx,di,bp
	.enter

	GrObjDeref	di,ds,si
	mov	cx,ds:[di].GOI_areaAttrToken
	sub	sp,size GrObjFullAreaAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullAreaAttrElement
	jnc	clearFrame
	mov	cl,ss:[bp].GOBAAE_backR
	mov	dl,ss:[bp].GOBAAE_backG
	mov	dh,ss:[bp].GOBAAE_backB
	mov	ch,CF_RGB
	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_TEXT_SET_WASH_COLOR
	call	GrObjVisGuardianMessageToVisWard

clearFrame:
	add	sp,size GrObjFullAreaAttrElement

	.leave
	ret
TextGuardianSetWashColor		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianAdjustMarginsForLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the margins of the text object based on the 
		width of the line

CALLED BY:	INTERNAL

PASS:		*ds:si - TextGuardian

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
	srs	5/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianAdjustMarginsForLineWidth		proc	far
	class	TextGuardianClass
	uses	ax,cx,dx,bp,di
	.enter

EC <	call	ECTextGuardianCheckLMemObject		>

	;    Get the line attributes
	;

	GrObjDeref	di,ds,si
	mov	cx,ds:[di].GOI_lineAttrToken
	sub	sp, size GrObjFullLineAttrElement
	mov	bp,sp
	call	GrObjGetGrObjFullLineAttrElement
	jnc	clearFrame

	;    If the line isn't being drawn then we don't
	;    care how thick it is.
	;

	cmp	ss:[bp].GOBLAE_mask, SDM_0
	je	clearFrame


	movwwf	dxcx,ss:[bp].GOBLAE_width
	mov	ax,MSG_GT_ADJUST_MARGINS_FOR_LINE_WIDTH
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	;    Redraw that fucker
	;

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_VIS_TEXT_RECALC_AND_DRAW
	call	GrObjVisGuardianMessageToVisWard

clearFrame:
	add	sp,size GrObjFullLineAttrElement

	.leave
	ret

TextGuardianAdjustMarginsForLineWidth		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianLineWidthChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the margins of the text object in case the line
		width has changed. We include setting the line mask here
		because if the line mask geos from zero to non zero
		then the line thickness suddenly matters.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		ax,cx,dx,bp - depends on message

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
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianLineWidthChange	method dynamic TextGuardianClass, 
						MSG_GO_SET_LINE_WIDTH,
						MSG_GO_SET_LINE_ATTR,
						MSG_GO_SET_GROBJ_LINE_TOKEN,
						MSG_GO_SET_LINE_MASK
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	call	TextGuardianAdjustMarginsForLineWidth

	.leave
	ret
TextGuardianLineWidthChange		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianInterestingAreaChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Some area attribute changed that forces us to change
		some data in the text object.
		Set the vis text objects transparency bit
		based on the grobj bit
		Set the vis text wash color based on grobj background color

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		ax,cx,dx,bp - depends on message

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
	srs	8/26/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianInterestingAreaChange	method dynamic TextGuardianClass, 
						MSG_GO_SET_AREA_ATTR,
						MSG_GO_SET_TRANSPARENCY,
						MSG_GO_SET_GROBJ_AREA_TOKEN,
						MSG_GO_SET_BG_COLOR
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	call	TextGuardianSetTransparentBit
	call	TextGuardianSetWashColor

	.leave
	ret
TextGuardianInterestingAreaChange		endm






if	ERROR_CHECK
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECTextGuardianCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an TextGuardianClass or one
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
ECTextGuardianCheckLMemObject		proc	near
	uses	es,di
	.enter
	pushf	
	mov	di,segment TextGuardianClass
	mov	es,di
	mov	di,offset TextGuardianClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECTextGuardianCheckLMemObject		endp

endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCombineSelectionStateNotificationData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	TextGuardian method for
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
TextGuardianCombineSelectionStateNotificationData method dynamic TextGuardianClass,  MSG_GO_COMBINE_SELECTION_STATE_NOTIFICATION_DATA

	uses	ax

	.enter

	mov	di, offset TextGuardianClass
	call	ObjCallSuperNoLock

	;
	;  Indicate that a text object is selected
	;
	mov	bx, cx
	call	MemLock
	jc	done
	mov	es, ax
	BitSet	es:[GONSSC_selectionState].GSS_flags, GSSF_TEXT_SELECTED
	call	MemUnlock

done:
	.leave
	ret
TextGuardianCombineSelectionStateNotificationData	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TextGuardianGenerateTextNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	TextGuardian method for MSG_TG_GENERATE_TEXT_NOTIFY

		Passes the notification to the GrObjBody so that it can
		coalesce each GrObjText's attrs into a single update.

Pass:		*ds:si = TextGuardian object
		ds:di = TextGuardian instance

		ss:[bp] - VisTextGenerateNotifyParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Apr  1, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGenerateTextNotify	method dynamic	TextGuardianClass,
				MSG_TG_GENERATE_TEXT_NOTIFY
	.enter

	;
	;  If the relayed bit is set, we want to send this to the
	;  ward. Otherwise, to the body
	;
	test	ss:[bp].VTGNP_sendFlags,mask VTNSF_RELAYED_TO_LIKE_TEXT_OBJECTS
	jnz	sendToWard

	mov	ax, MSG_GB_GENERATE_TEXT_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjMessageToBody
EC <	ERROR_Z	GROBJ_CANT_SEND_MESSAGE_TO_BODY		>

done:
	.leave
	ret

sendToWard:
	mov	ax, MSG_VIS_TEXT_GENERATE_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	jmp	done
TextGuardianGenerateTextNotify	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TextGuardianSendUINotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	TextGuardian method for MSG_GO_SEND_UI_NOTIFICATION

		Passes the notification to the GrObjBody so that it can
		coalesce each GrObjText's attrs into a single update.

Pass:		*ds:si = TextGuardian object
		ds:di = TextGuardian instance

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
TextGuardianSendUINotification	method dynamic	TextGuardianClass,
				MSG_GO_SEND_UI_NOTIFICATION
	uses	bp
	.enter

	mov	di, offset TextGuardianClass
	call	ObjCallSuperNoLock

	test	cx,mask GOUINT_SELECT
	jz	done

	;  The guardian has been selected so 
	;  tell the ward to update its controllers (except for select state,
	;  'cause we want the grobj's select state), so that the controllers
	;  will reflect the wards attributes,etc.
	;

	sub	sp, size VisTextGenerateNotifyParams
	mov	bp, sp
	mov	ss:[bp].VTGNP_notificationTypes, \
		VIS_TEXT_STANDARD_NOTIFICATION_FLAGS \
					and not mask VTNF_SELECT_STATE
	mov	ss:[bp].VTGNP_sendFlags, mask VTNSF_UPDATE_APP_TARGET_GCN_LISTS
	mov	ax, MSG_VIS_TEXT_GENERATE_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	add	sp, size VisTextGenerateNotifyParams
done:
	.leave
	ret
TextGuardianSendUINotification	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianEvaluatePARENTPointForSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	GrObj evaluates point to determine if it should be 
		selected by it.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass
		ss:bp - PointDWFixed in PARENT coordinates


RETURN:		
		al - EvaluatePositionRating
		dx - EvaluatePositionNotes

DESTROYED:	
		ah

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	11/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianEvaluatePARENTPointForSelection method dynamic TextGuardianClass, 
				MSG_GO_EVALUATE_PARENT_POINT_FOR_SELECTION

	.enter

	call	GrObjEvaluatePARENTPointForSelectionWithLineWidth

	.leave
	ret

TextGuardianEvaluatePARENTPointForSelection endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianReplaceGeometryInstanceData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We need to reset the vis bounds of the text object
		to match the object dimensions.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass
		
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
	srs	12/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianReplaceGeometryInstanceData	method dynamic TextGuardianClass, 
					MSG_GO_REPLACE_GEOMETRY_INSTANCE_DATA
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	.leave
	ret
TextGuardianReplaceGeometryInstanceData		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianRuleLargeStartSelectForWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	TextGuardian method for MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Called by:	MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD

Pass:		*ds:si = TextGuardian object
		ds:di = TextGuardian instance

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jan 20, 1993 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianRuleLargeStartSelectForWard	method dynamic	TextGuardianClass,
				MSG_GOVG_RULE_LARGE_START_SELECT_FOR_WARD,
				MSG_GOVG_RULE_LARGE_PTR_FOR_WARD,
				MSG_GOVG_RULE_LARGE_END_SELECT_FOR_WARD
	.enter

	; don't do jack hooey

	.leave
	ret
TextGuardianRuleLargeStartSelectForWard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianIsPointInsideObjectBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a point is inside the object bounds AND it
		is in a valid region inside the text object.

CALLED BY:	MSG_GO_IS_POINT_INSIDE_OBJECT_BOUNDS
PASS:		*ds:si	= TextGuardianClass object
		ds:di	= TextGuardianClass instance data
		ds:bx	= TextGuardianClass object (same as *ds:si)
		es 	= segment of TextGuardianClass
		ax	= message #
		ss:bp	= PointDWFixed
		dx	= size PointDWFixed
		
RETURN: carry:	SET	- Point is inside bounds
		CLEAR	- Point is NOT inside bounds

DESTROYED:	ax
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JimG	7/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianIsPointInsideObjectBounds	method dynamic TextGuardianClass, 
					MSG_GO_IS_POINT_INSIDE_OBJECT_BOUNDS
	uses	cx, dx, bp
	.enter
	
	; Don't do anything if this is the floater.
	test	ds:[di].GOI_optFlags, mask GOOF_FLOATER	; clc implied
	jnz	exit
	
	; Allocate space for the bound rectangle on the stack
	mov	bx, bp					; ss:bx = PointDWFixed
	sub	sp, size RectDWFixed
	mov	bp, sp					; ss:bp = RectDWFixed
	
	; Get my bounds
	mov	ax, MSG_GO_GET_DWF_PARENT_BOUNDS
	call	ObjCallInstanceNoLock
	
	; Set up arguments for utility routine
	
	push	ds, si
	mov	si, ss
	mov	ds, si
	mov	es, si
	mov	si, bp
	mov	di, bx
	
	; ds:si = RectDWFixed - bounds of the object
	; es:di = PointDWFixed - position to test
	
	call	GrObjGlobalIsPointDWFixedInsideRectDWFixed?
	pop	ds, si
	jnc	exitFailFixStack
	
	; We are inside the bounds of the object.
	; Now call the text object to determine if it inside a region.
	
	; First, convert the mouse point to the text objects coords.
	; We are going to put the converted mouse point into the 1st two
	; entries into the RectDWFixed structure and call it a point.
    
    CheckHack <(offset RDWF_left) eq 0>
    CheckHack <(offset RDWF_left) eq (offset PDF_x)>
    CheckHack <(offset RDWF_top) eq (offset PDF_y)>
    
	movdwf	axcxdx, ss:[bx].PDF_x
	subdwf	axcxdx, ss:[bp].RDWF_left
	movdwf	ss:[bp].RDWF_left, axcxdx
	
	movdwf	axcxdx, ss:[bx].PDF_y
	subdwf	axcxdx, ss:[bp].RDWF_top
	movdwf	ss:[bp].RDWF_top, axcxdx
	
	mov	ax, MSG_VIS_TEXT_REGION_FROM_POINT
	mov	di, mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard
EC <	ERROR_Z	GROBJ_VIS_GUARDIAN_SHOULD_HAVE_VIS_WARD			>
	cmp	cx, CA_NULL_ELEMENT
	jz	exitFailFixStack				; no element...
	
	add	sp, size RectDWFixed
	; Okay.. we are in an element.  Return success.
	stc
exit:
	.leave
	ret

exitFailFixStack:
	add	sp, size RectDWFixed
	clc
	jmp	short exit
	
TextGuardianIsPointInsideObjectBounds	endm


GrObjTextGuardianCode	ends

GrObjTransferCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGetTransferBlockFromVisWard
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a vm block from the ward with the ward's data in it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		ss:bp - GrObjTransferParams

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
TextGuardianGetTransferBlockFromVisWard	method dynamic	TextGuardianClass,
				MSG_GOVG_GET_TRANSFER_BLOCK_FROM_VIS_WARD
	uses	bp

	.enter

	;
	;  See whether this text object needs to initialize
	;  the transfer arrays
	;
	clr	bx
	tst	ss:[bp].GTP_textSSP.VTSSSP_common.SSP_xferStyleArray.SCD_vmBlockOrMemHandle
	jnz	afterXfer

	;
	;  We want our text object to allocate the arrays in the vm file
	;
	mov	bx, ss:[bp].GTP_vmFile

	;
	;  Tell the text object to return a vm block with its data
	;
	;  cx:dx <- DBItem
	;
afterXfer:
	lea	ax, ss:[bp].GTP_textSSP
	sub	sp, size VisTextSaveToDBWithStylesParams
	mov	bp, sp
	movdw	ss:[bp].VTSTDBWSP_params, ssax
	clrdw	ss:[bp].VTSTDBWSP_dbItem
	mov	ss:[bp].VTSTDBWSP_flags, mask VTSDBF_TEXT or \
			(VTST_RUNS_ONLY shl offset VTSDBF_CHAR_ATTR) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_PARA_ATTR) or \
			(VTST_NONE shl offset VTSDBF_TYPE) or \
			(VTST_RUNS_ONLY shl offset VTSDBF_GRAPHIC)
	mov	ss:[bp].VTSTDBWSP_xferFile, bx
	mov	ax, MSG_VIS_TEXT_SAVE_TO_DB_ITEM_WITH_STYLES
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	GrObjVisGuardianMessageToVisWard
	add	sp, size VisTextSaveToDBWithStylesParams


	.leave
	ret
TextGuardianGetTransferBlockFromVisWard	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianCreateWardWithTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a vm block from the ward with the ward's data in it

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

		cx:dx - 32 bit identifier
		ss:bp - GrObjTransferParams

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
TextGuardianCreateWardWithTransfer	method dynamic	TextGuardianClass,
					MSG_GOVG_CREATE_WARD_WITH_TRANSFER
	uses	bp

	.enter

	push	cx, dx					;save db item

	;
	;  get the block to store the text object in
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

	mov_tr	ax, cx					;^lax:bx <- text obj
	mov	bx, dx
	pop	cx, dx					;cx:dx <- db item
	push	ax, bx					;save text object

	mov	bx, ss:[bp].GTP_vmFile
	mov_tr	ax, bp					;ss:ax <- GTP
	add	ax, offset GTP_textSSP
	sub	sp, size VisTextLoadFromDBWithStylesParams
	mov	bp, sp
	mov	ss:[bp].VTLFDBWSP_file, bx
	movdw	ss:[bp].VTLFDBWSP_dbItem, cxdx
	movdw	ss:[bp].VTLFDBWSP_params, ssax
	mov	ax, MSG_VIS_TEXT_LOAD_FROM_DB_ITEM_WITH_STYLES
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard
	add	sp, size VisTextLoadFromDBWithStylesParams

	clr	cx
	mov	ax, MSG_VIS_TEXT_SET_VM_FILE
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard	

	;    Vis bounds are not copied with vis wards so we need to
	;    reset them. This prevents problems with getting a
	;    MSG_VIS_TEXT_HEIGHT_NOTIFY when the vis bounds are zero.
	;    This results in adding unnecessary height to the 
	;    the guardian.
	;

	mov	ax,MSG_GOVG_VIS_BOUNDS_SETUP
	call	ObjCallInstanceNoLock

	;    The VisText doesn't copy over stuff in its vis instance
	;    data, so reconstruct the best we can.
	;

	call	TextGuardianAdjustMarginsForLineWidth
	call	TextGuardianSetWashColor
	call	TextGuardianSetTransparentBit

	;    Have the new text object select all its text so that
	;    messages sent to it affect the text
	;

	mov	ax,MSG_VIS_TEXT_SELECT_ALL
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	pop	cx, dx					;return optr

	.leave
	ret
TextGuardianCreateWardWithTransfer	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianClearSansUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If clearing object, must nuke undo as it may have undo
		info for object.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	10/8/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianClearSansUndo	method dynamic TextGuardianClass, 
						MSG_GO_CLEAR_SANS_UNDO
	.enter

	; use suspend mechanism in body to flush undo
	mov	ax, MSG_META_SUSPEND
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody
	mov	ax, MSG_META_UNSUSPEND
	mov	di,mask MF_FIXUP_DS
	call	GrObjMessageToBody

	mov	ax, MSG_GO_CLEAR_SANS_UNDO
	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	.leave

	Destroy	ax,cx,dx,bp

	ret
TextGuardianClearSansUndo		endm

GrObjTransferCode	ends


GrObjDrawCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianDrawFGLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the line foreground component of the rectangle

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass
	
		cl - DrawFlags
		ch - GrObjDrawFlags
		dx - gstate to draw through

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SPEED over SMALL SIZE

		Common cases:
			none

		I nuked the true high res line drawing because
		it caused off by one errors when the text object
		was first created. First the object would draw
		in hi res mode and then on gained target it would
		draw in low res mode. Sometimes they would
		be different by a pixel on the top and left. Not any more.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianDrawFGLine	method dynamic TextGuardianClass, MSG_GO_DRAW_FG_LINE,
						MSG_GO_DRAW_FG_LINE_HI_RES

	uses	cx,dx
	.enter

	mov	di,dx
EC <	call	ECCheckGStateHandle				>
	CallMod	GrObjGetNormalOBJECTDimensions
	call	GrObjCalcCorners
	call	GrDrawRect

	.leave
	ret
TextGuardianDrawFGLine		endm




GrObjDrawCode	ends

GrObjTransferCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TextGuardianWriteInstanceToTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	TextGuardian method for MSG_GO_WRITE_INSTANCE_TO_TRANSFER

Called by:	

Pass:		*ds:si = TextGuardian object
		ds:di = TextGuardian instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos updated to point past data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianWriteInstanceToTransfer	method dynamic	TextGuardianClass,
				MSG_GO_WRITE_INSTANCE_TO_TRANSFER
	uses	cx,dx
	.enter

	mov	di, offset TextGuardianClass
	call	ObjCallSuperNoLock

	;
	;  Write our TextGuardian specific stuff out by pointing at our instance data
	;

	TextGuardianDeref	di,ds,si
	segmov	es, ds

CheckHack <offset TGI_desiredMinHeight eq offset TGI_flags + size TextGuardianFlags>
CheckHack <offset TGI_desiredMaxHeight eq offset TGI_desiredMinHeight + size word>
	add	di, offset TGI_flags
	mov	cx, size TextGuardianFlags + 2 * size word
	call	GrObjWriteDataToTransfer

	.leave
	ret
TextGuardianWriteInstanceToTransfer	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			TextGuardianReadInstanceFromTransfer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	TextGuardian method for MSG_GO_READ_INSTANCE_FROM_TRANSFER

Called by:	

Pass:		*ds:si = TextGuardian object
		ds:di = TextGuardian instance

		ss:[bp] - GrObjTransferParams

Return:		ss:[bp].GTP_curPos updated to point past data

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	May 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianReadInstanceFromTransfer	method dynamic	TextGuardianClass,
				MSG_GO_READ_INSTANCE_FROM_TRANSFER
	uses	cx,dx
	.enter

	mov	di, offset TextGuardianClass
	call	ObjCallSuperNoLock

	;
	;  Read our TextGuardian specific stuff out
	;

	TextGuardianDeref	di,ds,si
	segmov	es, ds

CheckHack <offset TGI_desiredMinHeight eq offset TGI_flags + size TextGuardianFlags>
CheckHack <offset TGI_desiredMaxHeight eq offset TGI_desiredMinHeight + size word>
	add	di, offset TGI_flags
	mov	cx, size TextGuardianFlags + 2 * size word
	call	GrObjReadDataFromTransfer

	.leave
	ret
TextGuardianReadInstanceFromTransfer	endm

GrObjTransferCode	ends



GrObjGroupCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGroupGainedSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select all the text so that
		text attribute changes to the text object would
		affect all of the text.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGroupGainedSelectionList	method dynamic TextGuardianClass, 
					MSG_GO_GROUP_GAINED_SELECTION_LIST
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	mov	ax,MSG_VIS_TEXT_SELECT_ALL
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisGuardianMessageToVisWard

	;   Prevent the VisText from being discard so that it doesn't 
	;   lose the selection
	;

	call	GrObjVisGuardianIncVisWardsInteractibleCount

	.leave
	ret
TextGuardianGroupGainedSelectionList		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TextGuardianGroupLostSelectionList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deselect the text that was selected in 
		MSG_GO_GROUP_GAINED_SELECTION_LIST.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of TextGuardianClass

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
	srs	7/22/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TextGuardianGroupLostSelectionList	method dynamic TextGuardianClass, 
					MSG_GO_GROUP_LOST_SELECTION_LIST
	uses	cx,dx
	.enter

	mov	di,offset TextGuardianClass
	call	ObjCallSuperNoLock

	;    Deselect that text
	;

	mov	di,mask MF_FIXUP_DS
	clr	cx,dx
	mov	ax,MSG_VIS_TEXT_SELECT_RANGE_SMALL
	call	GrObjVisGuardianMessageToVisWard

	;    Counteract the incing of the count in 
	;    MSG_GO_GROUP_GAINED_SELECTION_LIST

	call	GrObjVisGuardianDecVisWardsInteractibleCount

	.leave
	ret
TextGuardianGroupLostSelectionList		endm


GrObjGroupCode	ends
