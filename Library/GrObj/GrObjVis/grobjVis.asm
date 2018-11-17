COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Berkeley Softworks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Admin	
FILE:		grobjVis.asm

AUTHOR:		Steve Scholl, Dec 10, 1991

ROUTINES:
	Name			Description
	----			-----------
GrObjVisMessageToGuardian

MESSAGE HANDLERS:
	Name			Description
	----			-----------
GrObjVisGetWWFixedCenter
GrObjVisSetGuardianLink
GrObjVisVupCreateGState
GrObjVisVisInvalidate
GrObjVisVupAlterInputFlow
GrObjVisAlterFTVMCExcl
GrObjVisSetRealizedAndUpwardLink
GrObjVisClearRealizedAndUpwardLink
GrObjVisReloc
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	12/10/91		Initial revision


DESCRIPTION:
	
		

	$Id: grobjVis.asm,v 1.1 97/04/04 18:08:46 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GrObjClassStructures	segment resource

GrObjVisClass		;Define the class record

GrObjClassStructures	ends


GrObjVisGuardianCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisInitialize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

RETURN:		

	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisInitialize	method dynamic GrObjVisClass, MSG_META_INITIALIZE
	.enter

;	NO NO NO. Master classes are not allowed to send message initialize
;       to their super class
;
;	mov	di, offset GrObjVisClass
;	CallSuper	MSG_META_INITIALIZE

	mov	bx,Vis_offset
	call	ObjInitializePart

	;    Clear all geometry management bits that will make
	;    my life miserable
	;

	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	andnf	ds:[di].VI_optFlags, not (mask VOF_GEO_UPDATE_PATH or \
					mask VOF_GEOMETRY_INVALID or \
					mask VOF_IMAGE_INVALID or \
					mask VOF_IMAGE_UPDATE_PATH )
	andnf	ds:[di].VI_attrs, not mask VA_MANAGED
	ornf	ds:[di].VI_attrs, mask VA_FULLY_ENABLED

	; Mark ourselves as an INPUT NODE, so we get all
	; MSG_VIS_VUP_ALTER_INPUT_FLOW's coming up from below us.
	;			-- Doug 4/29/92
	; Good.  We need to do this now, as well, in order to get
	; MSG_META_MUP_ALTER_FTVMC_EXCL. -- Doug 2/5/93
	;
	ornf	ds:[di].VI_typeFlags, mask VTF_IS_INPUT_NODE

	.leave
	ret
GrObjVisInitialize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGetPotentialWardSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Default handler

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

RETURN:		
		cx - size in bytes
	
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
	srs	3/ 9/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGetPotentialWardSize	method dynamic GrObjVisClass, 
					MSG_GV_GET_POTENTIAL_WARD_SIZE
	.enter

	;    Add in the GrObjVis and its master variant instance
	;    data size.
	;

	mov	di,ds:[si]
	les	di,ds:[di].MB_class
	mov	cx,es:[di].Class_instanceSize
	add	cx,POTENTIAL_BASE_WARD_SIZE
	mov	bx,es:[di].Class_masterOffset
	mov	di,ds:[si]
	add	di,ds:[di+bx]
	les	di,ds:[di].MB_class
	add	cx,es:[di].Class_instanceSize

	.leave
	ret
GrObjVisGetPotentialWardSize		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisFinalObjFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrease the potential size of our block

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

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
	srs	3/10/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisFinalObjFree	method dynamic GrObjVisClass, 
						MSG_META_FINAL_OBJ_FREE
	.enter

	mov	ax,MSG_GV_GET_POTENTIAL_WARD_SIZE
	call	ObjCallInstanceNoLock
	mov	di,mask MF_FIXUP_DS
	mov	dx,ds:[LMBH_handle]
	mov	ax,MSG_GB_DECREASE_POTENTIAL_EXPANSION
	call	GrObjMessageToBody

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_GOVG_CLEAR_VIS_WARD_OD
	call	GrObjVisMessageToGuardian

	mov	di,offset GrObjVisClass
	mov	ax,MSG_META_FINAL_OBJ_FREE
	call	ObjCallSuperNoLock

	.leave
	ret
GrObjVisFinalObjFree		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisAlterFTVMCExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept requests for the target or focus and relay them to
		our vis guardian.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass
	
		cx:dx - optr to grab/release exclusive for
		bp - MetaAlterFTVMCExclFlags

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
	srs	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisAlterFTVMCExcl	method dynamic GrObjVisClass, \
						MSG_META_MUP_ALTER_FTVMC_EXCL
	.enter

	;    If this is for the target or focus then pass it to our guardian
	;    otherwise handle it normally
	;

	test	bp, mask MAEF_TARGET or mask MAEF_FOCUS
	jz	callSuper

	push	bp				;original flags
	andnf	bp,mask MAEF_GRAB or mask MAEF_TARGET or mask MAEF_FOCUS
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>
	pop	bp				;original flags

	;    We've handle the target request
	;

	andnf	bp, not (mask MAEF_TARGET or mask MAEF_FOCUS)

	;    If there are any other request, pass message to
	;    our superclass
	;

	test	bp, MAEF_MASK_OF_ALL_HIERARCHIES
	jz	done			; otherwise done.

callSuper:
	; Pass message on to superclass  for handling outside of
	; this class.
	;

	mov	di, offset GrObjVisClass
	call	ObjCallSuperNoLock

done:
	Destroy	ax,cx,dx,bp

	.leave
	ret

GrObjVisAlterFTVMCExcl		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisSetGuardianLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set parent link in object

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

		cx:dx - od of parent to be

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
	srs	12/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisSetGuardianLink	method dynamic GrObjVisClass, \
						MSG_GV_SET_GUARDIAN_LINK
	.enter

	call	ObjMarkDirty

	mov	ds:[di].GVI_guardian.handle,cx
	mov	ds:[di].GVI_guardian.chunk,dx

	.leave
	ret
GrObjVisSetGuardianLink		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisVupCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send message to guardian to create a gstate

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

RETURN:		
		bp - gstate

		stc - defined as returned		
	
DESTROYED:	

		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisVupCreateGState	method dynamic GrObjVisClass, MSG_VIS_VUP_CREATE_GSTATE
	.enter

	mov	ax,MSG_GOVG_CREATE_GSTATE
	mov	di,mask MF_CALL					;MessageFlags
	call	GrObjVisMessageToGuardian
	jz	noGuardianDam

done:
	stc

	.leave
	ret

noGuardianDam:
	;    This is probably happening because the text object
	;    is requesting a gstate while handling MSG_META_FINAL_OBJ_FREE.
	;    Give it one anyway
	;
	
	clr	di					;no window
	call	GrCreateState
	mov	bp,di
	jmp	done

GrObjVisVupCreateGState		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisVisInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept vis trying to invalidate itself and pass the
		message to guardian

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

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
	srs	1/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisVisInvalidate	method dynamic GrObjVisClass, MSG_VIS_INVALIDATE
	.enter

	mov	ax,MSG_GO_INVALIDATE
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

	.leave
	ret
GrObjVisVisInvalidate		endm









COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisVupAlterInputFlow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercept the mouse grabs by the vis ward and just eat
		them.  The guardian grabs the mouse on start selects
		and releases it on end selects. If the ward needs other
		behaviour then its grobj vis must subclass this message.
		If it is a mouse grab request then set the mouse event
		type in the guardian (ie small or large)

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

		ss:bp - VupAlterInputFlowData

RETURN:		
		nothing
	
DESTROYED:	
		ax,cx,dx,bp

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisVupAlterInputFlow	method dynamic GrObjVisClass, \
						MSG_VIS_VUP_ALTER_INPUT_FLOW
	.enter
	
	;    Check for mouse related message, 
	;    if not, jump to just sendToParent
	;

	test	ss:[bp].VAIFD_flags, mask VIFGF_MOUSE
	jz	sendToParent

	;    if mouse *grab*, then set mouse event type in guardian
	;

	mov	ax, MSG_GO_GRAB_MOUSE
	test	ss:[bp].VAIFD_flags, mask VIFGF_GRAB
	pushf
	jnz	grabOrRelease
	mov	ax, MSG_GO_RELEASE_MOUSE

grabOrRelease:
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

	popf
	jz	sendToParent
	
	mov	cl, VWMET_SMALL				;assume
	test	ss:[bp].VAIFD_flags, mask VIFGF_LARGE
	jz	setMouseEventType
	mov	cl,VWMET_LARGE

setMouseEventType:
	mov	ax,MSG_GOVG_SET_VIS_WARD_MOUSE_EVENT_TYPE
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

done:
	.leave
	ret

sendToParent:
	;    We need to clear it for the next level up of
	;    this handler
	;

	andnf	ss:[bp].VAIFD_flags, not mask VIFGF_NOT_HERE

	call	VisCallParent
	jmp	done

GrObjVisVupAlterInputFlow		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisSetVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bounds of the vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

		ss:bp - Rect

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
	srs	4/11/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisSetVisBounds	method dynamic GrObjVisClass, 
						MSG_GV_SET_VIS_BOUNDS
	uses	cx,dx
	.enter

	mov	cx,ss:[bp].R_left
	mov	dx,ss:[bp].R_top
	mov	ax,MSG_VIS_SET_POSITION
	call	ObjCallInstanceNoLock

	mov	cx,ss:[bp].R_right
	mov	dx,ss:[bp].R_bottom
	sub	cx,ss:[bp].R_left
	sub	dx,ss:[bp].R_top
	mov	ax,MSG_VIS_SET_SIZE
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjVisSetVisBounds		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGetGrObjVisClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjVis method for MSG_GV_GET_GROBJ_VIS_CLASS

Called by:	MSG_GV_GET_GROBJ_VIS_CLASS

Pass:		nothing

Return:		cx:dx - pointer to GrObjVisClass

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGetGrObjVisClass	method dynamic	GrObjVisClass,
				MSG_GV_GET_GROBJ_VIS_CLASS
	.enter

	mov	cx, segment GrObjVisClass
	mov	dx, offset GrObjVisClass

	.leave
	ret
GrObjVisGetGrObjVisClass	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGetGuardian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return od of guardian

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

RETURN:		
		cx:dx - od of guardian
	
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
	srs	9/ 3/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGetGuardian	method dynamic GrObjVisClass, 
						MSG_GV_GET_GUARDIAN
	.enter

	movdw	cxdx,ds:[di].GVI_guardian

	.leave
	ret
GrObjVisGetGuardian		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisNotifyGeometryValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark sure the geometry invalid bit is clear. some objects
		have error checking code that pukes if it is not clear.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

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
	srs	11/28/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisNotifyGeometryValid	method dynamic GrObjVisClass, 
						MSG_VIS_NOTIFY_GEOMETRY_VALID
	.enter

	mov	di,ds:[si]
	add	di,ds:[di].Vis_offset
	BitClr	ds:[di].VI_optFlags, VOF_GEOMETRY_INVALID

	mov	di,offset GrObjVisClass
	call	ObjCallSuperNoLock

	.leave
	ret
GrObjVisNotifyGeometryValid		endm




GrObjVisGuardianCode	ends

GrObjDrawCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisReloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the REALIZED bit is set if we have a visual parent


PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

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
		ax,cx,dx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This method should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/25/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisReloc	method dynamic GrObjVisClass, reloc
	.enter

	mov	di,offset GrObjVisClass
	call	ObjRelocOrUnRelocSuper
	jc	done

	;    If vis part not built just punt
	;

	mov	di,ds:[si]
	tst	ds:[di].Vis_offset
	jz	done
	add	di,ds:[di].Vis_offset

	;    If we haven't been attached to the body then we can't
	;    have been realized
	;

	tst	ds:[di].VI_link.LP_next.handle
	jz	done

	;    Cool
	;

	BitSet	ds:[di].VI_attrs, VA_REALIZED

done:
	.leave
	
	Destroy	ax,cx,dx

	ret
GrObjVisReloc		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisMessageToGuardian
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the vis ward's guardian

CALLED BY:	INTERNAL (UTILITY)

PASS:		*ds:si - GrObjVis
		ax - message
		cx,dx,bp - message data
		di - MessageFlags

RETURN:		
		if no guardian return
			zero flag set
		else
			zero flag cleared
			if MF_CALL
				ax,cx,dx,bp
				no flags except carry
			otherwise 
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
	srs	1/ 7/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisMessageToGuardian		proc	far
	class	GrObjVisClass
	uses	bx,di,si
	.enter

EC <	call	ECGrObjGrObjVisCheckLMemObject				>

	mov	si,ds:[si]
	add	si,ds:[si].GrObjVis_offset
	mov	bx,ds:[si].GVI_guardian.handle
	tst	bx							
	jz	done
	mov	si,ds:[si].GVI_guardian.chunk
	ornf	di, mask MF_FIXUP_DS
	call	ObjMessage

	ClearZeroFlagPreserveCarry	si
done:
	.leave
	ret

GrObjVisMessageToGuardian		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisGetWWFixedCenter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the WWFixed center of the visual bounds

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass

RETURN:		
		dx:cx - WWFixed x of center
		bp:ax - WWFixed y of center
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	12/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisGetWWFixedCenter	method dynamic GrObjVisClass, 
						MSG_GV_GET_WWFIXED_CENTER
	.enter

	mov	di,bx
	add	di,ds:[di].Vis_offset

	;    (width)/2 + left
	;

	mov	dx,ds:[di].VI_bounds.R_right
	mov	bx,ds:[di].VI_bounds.R_left
	sub	dx,bx					;width int
	clr	cx					;width frac
	sar	dx,1					;width/2 int
	rcr	cx,1					;width/2 frac
	add	dx,bx					;width/2 + left

	;    (height)/2 + top
	;

	mov	bp,ds:[di].VI_bounds.R_bottom
	mov	bx,ds:[di].VI_bounds.R_top
	sub	bp,bx					;height int
	clr	ax					;height frac
	sar	bp,1					;height/2 int
	rcr	ax,1					;height/2 frac
	add	bp,bx					;height/2 + top


	.leave
	ret
GrObjVisGetWWFixedCenter		endm

GrObjDrawCode	ends


GrObjAlmostRequiredCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisSetRealizedAndUpwardLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

oSYNOPSIS:	Set the object's realized bit and the upward link
		to the body.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass
		
		cx:dx - object to upward link to (the body)

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
	srs	8/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisSetRealizedAndUpwardLink	method dynamic GrObjVisClass, 
					MSG_GV_SET_REALIZED_AND_UPWARD_LINK
	uses	dx
	.enter

	call	ObjMarkDirty

	mov	di,bx
	add	di,ds:[di].Vis_offset
	BitSet	ds:[di].VI_attrs,VA_REALIZED

	mov	ds:[di].VI_link.LP_next.handle,cx
	ornf	dx,LP_IS_PARENT
	mov	ds:[di].VI_link.LP_next.chunk,dx

	.leave
	ret
GrObjVisSetRealizedAndUpwardLink		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjVisClearRealizedAndUpwardLink
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the object's realized bit and the upward link
		to the body.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjVisClass
		
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
	srs	8/13/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjVisClearRealizedAndUpwardLink	method dynamic GrObjVisClass, 
					MSG_GV_CLEAR_REALIZED_AND_UPWARD_LINK
	.enter

	call	ObjMarkDirty

	mov	di,bx
	add	di,ds:[di].Vis_offset
	BitClr	ds:[di].VI_attrs,VA_REALIZED

	clr	ax
	mov	ds:[di].VI_link.LP_next.handle,ax
	mov	ds:[di].VI_link.LP_next.chunk,ax

	.leave
	ret
GrObjVisClearRealizedAndUpwardLink		endm

GrObjAlmostRequiredCode	ends





if	ERROR_CHECK
GrObjErrorCode	segment resource
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECGrObjGrObjVisCheckLMemObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks to see if *ds:si* is a pointer to an object stored
		in an object block and that it is an GrObjGrObjVisClass or one
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
ECGrObjGrObjVisCheckLMemObject		proc	far
	uses	es,di
	.enter
	pushf	
	mov	di,segment GrObjVisClass
	mov	es,di
	mov	di,offset GrObjVisClass
	call	ObjIsObjectInClass
	ERROR_NC OBJECT_NOT_OF_CORRECT_CLASS
	popf
	.leave
	ret
ECGrObjGrObjVisCheckLMemObject		endp

GrObjErrorCode	ends
endif




