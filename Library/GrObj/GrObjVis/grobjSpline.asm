COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GrObj	
FILE:		grobjSpline.asm

AUTHOR:		Steve Scholl, Dec  7, 1991

ROUTINES:
	Name		
	----		

METHODS:
	Name		
	----		
GrObjSplineBuild
GrObjSplineSetVisBounds
GrObjSplineNotifyChangeBounds	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	12/ 7/91		Initial revision


DESCRIPTION:
	
		

	$Id: grobjSpline.asm,v 1.1 97/04/04 18:08:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrObjClassStructures	segment resource

GrObjSplineClass		;Define the class record

GrObjClassStructures	ends



GrObjSplineGuardianCode	segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSplineBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The variant parent of the GrObjSplineClass is VisSplineClass

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjSplineClass

RETURN:		
		cx:dx - fptr to VisSplineClass
	

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
GrObjSplineBuild	method dynamic GrObjSplineClass, MSG_META_RESOLVE_VARIANT_SUPERCLASS
	.enter

	mov	cx,segment VisSplineClass
	mov	dx, offset VisSplineClass

	.leave
	ret
GrObjSplineBuild		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSplineNotifyChangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjSpline method for MSG_SPLINE_NOTIFY_CHANGE_BOUNDS

Called by:	

Pass:		*ds:si = GrObjSpline object
		ds:di = GrObjSpline instance
		ss:[bp] - A Rectangle structure containing (desired)
				new Vis Bounds
		dx - size (in bytes) of the Rectangle struct

Return:		nothing

Destroyed:	
		ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Mar 13, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSplineNotifyChangeBounds	method	GrObjSplineClass, 
					MSG_SPLINE_NOTIFY_CHANGE_BOUNDS
	.enter

	;    Let the spline guardian know we want to change our bounds
	;

	mov	ax, MSG_GOVG_NOTIFY_VIS_WARD_CHANGE_BOUNDS
	mov	di, mask MF_STACK or mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

	.leave
	ret
GrObjSplineNotifyChangeBounds	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSplineSetVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the bounds of the vis ward

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjSplineClass

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
GrObjSplineSetVisBounds	method dynamic GrObjSplineClass, 
						MSG_GV_SET_VIS_BOUNDS
	.enter

	mov	ax,MSG_SPLINE_SET_VIS_BOUNDS
	call	ObjCallInstanceNoLock

	.leave
	ret
GrObjSplineSetVisBounds		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSplineNotifyCreateModeDone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The default hander in the spline switches to inactive mode.
		We need to switch to the after create mode stored in
		the guardian.
		
PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjSplineClass

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
GrObjSplineNotifyCreateModeDone	method dynamic GrObjSplineClass, 
					MSG_SPLINE_NOTIFY_CREATE_MODE_DONE
	.enter

	mov	di,mask MF_FIXUP_DS
	mov	ax,MSG_SG_SWITCH_TO_SPLINE_AFTER_CREATE_MODE
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

	.leave
	ret
GrObjSplineNotifyCreateModeDone		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			GrObjSplineGenerateNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjSpline method for MSG_SPLINE_GENERATE_NOTIFY

		This routine calls the GrObjBody so that it can coalesce
		each GrObjSpline's attrs into a single update.

Called by:	

Pass:		*ds:si = GrObjSpline object
		ds:di = GrObjSpline instance

		ss:[bp] - SplineGenerateNotifyParams

Return:		nothing

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Jun  7, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSplineGenerateNotify	method dynamic	GrObjSplineClass,
				MSG_SPLINE_GENERATE_NOTIFY
	.enter

	mov	di, size SplineGenerateNotifyParams
	push	di
	mov	di, 800
	call	GrObjBorrowStackSpaceWithData
	push	di

	test	ss:[bp].SGNP_sendFlags, mask SNSF_RELAYED_TO_LIKE_OBJECTS
	jz	callBody

	;
	;  The message has been relayed, so just call our superclass
	;
	mov	di, offset GrObjSplineClass
	call	ObjCallSuperNoLock

done:

	pop	di
	call	GrObjReturnStackSpaceWithData

	.leave
	ret

callBody:

	mov	ax, MSG_SG_GENERATE_SPLINE_NOTIFY
	mov	di, mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>
	jmp	done
GrObjSplineGenerateNotify	endm



GrObjSplineGuardianCode	ends



GrObjDrawCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSplineApplyGStateStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Have the guardian apply its attributes to the gstate

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of GrObjSplineClass

		bp - gstate
RETURN:		
		bp - gstate with attributes applied
	
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSplineApplyGStateStuff	method dynamic GrObjSplineClass,
				MSG_SPLINE_APPLY_ATTRIBUTES_TO_GSTATE
	uses	ax
	.enter

	mov	ax,MSG_GO_APPLY_ATTRIBUTES_TO_GSTATE
	mov	di,mask MF_FIXUP_DS
	call	GrObjVisMessageToGuardian
EC <	ERROR_Z VIS_WARD_HAS_NO_GUARDIAN				>

	.leave
	ret
GrObjSplineApplyGStateStuff		endm

GrObjDrawCode	ends

GrObjTransferCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjSplineGetGrObjVisClass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Description:	GrObjSpline method for MSG_GV_GET_GROBJ_VIS_CLASS

Called by:	MSG_GV_GET_GROBJ_VIS_CLASS

Pass:		nothing

Return:		cx:dx - pointer to GrObjSplineClass

Destroyed:	ax

Comments:	

Revision History:

	Name	    Date	Description
	----	------------	-----------
	jon	Aug  6, 1992 	Initial version.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjSplineGetGrObjVisClass	method dynamic	GrObjSplineClass,
				MSG_GV_GET_GROBJ_VIS_CLASS
	.enter

	mov	cx, segment GrObjSplineClass
	mov	dx, offset GrObjSplineClass

	.leave
	ret
GrObjSplineGetGrObjVisClass	endm

GrObjTransferCode	ends

