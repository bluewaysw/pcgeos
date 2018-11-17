COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineSuspend.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/14/92   	Initial version.

DESCRIPTION:
	

	$Id: splineSuspend.asm,v 1.1 97/04/07 11:09:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	increment the suspend count.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSuspend	method	dynamic	VisSplineClass, 
					MSG_META_SUSPEND
	inc	ds:[di].VSI_suspendCount

EC <	cmp	ds:[di].VSI_suspendCount, MAX_SUSPEND_COUNT	>
EC <	ERROR_E ILLEGAL_SUSPEND_COUNT				>

	mov	di, offset VisSplineClass
	GOTO	ObjCallSuperNoLock
SplineSuspend	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineUnSuspend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	decrement the suspend count.  If it drops to zero,
		perform the the pending actions

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		nothing 

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineUnSuspend	method	dynamic	VisSplineClass, 
					MSG_META_UNSUSPEND

	dec	ds:[di].VSI_suspendCount
EC <	ERROR_S ILLEGAL_SUSPEND_COUNT			>

	jnz	done

	;
	; Suspend count has reached zero, so check the unSuspend flags
	;

	clr	bl
	xchg	bl, ds:[di].VSI_unSuspendFlags
	test	bl, mask SUSF_GEOMETRY
	jz	afterGeometry

	mov	ax, MSG_VIS_RECALC_SIZE
	call	ObjCallInstanceNoLock
	
afterGeometry:

	test	bl, mask SUSF_UPDATE_UI
	jz	done
	
	mov	cx,UPDATE_ALL
	mov	ax, MSG_SPLINE_BEGIN_UPDATE_UI
	call	ObjCallInstanceNoLock

done:
	mov	ax, MSG_META_UNSUSPEND
	mov	di, offset VisSplineClass
	GOTO	ObjCallSuperNoLock
SplineUnSuspend	endm

