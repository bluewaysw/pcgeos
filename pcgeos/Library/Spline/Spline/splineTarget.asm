COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineTarget.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

DESCRIPTION:
	

	$Id: splineTarget.asm,v 1.1 97/04/07 11:09:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplineObjectCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Notification that we've gained the target
		create a gstate to last until we lose the target
		increment the interactibility count of the points
		block, so that it doesn't get discarded, so that we
		can modify our selection state without dirtying things.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGainedTargetExcl	method	dynamic	VisSplineClass, 
					MSG_META_GAINED_TARGET_EXCL

	mov	di, offset VisSplineClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	call	SplineCreateGState
	call	SplineMethodCommonReadOnly

	;
	; Increment the interactible count of the points block until we
	; lose the target.
	;
EC <	clr	si			>
	call	ObjIncInteractibleCount

	ornf	es:[bp].VSI_editState, mask SES_TARGET
	call	SplineDrawSelectedPoints
	mov	cx,UPDATE_ALL
	call	SplineUpdateUI
	call	SplineEndmCommon
	ret

SplineGainedTargetExcl	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Decrement the interactible count on the points block,
		destroy the gstate creatd on SplineGainedTargetExcl

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/ 8/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineLostTargetExcl	method	dynamic	VisSplineClass, 
					MSG_META_LOST_TARGET_EXCL

	mov	di, offset VisSplineClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset 

	call	SplineMethodCommonReadOnly

	call	ObjDecInteractibleCount

	andnf	es:[bp].VSI_editState, not mask SES_TARGET
	call	SplineEraseSelectedPoints
	call	SplineFreeUndoAndNew
	mov	cx,UPDATE_ALL
	call	SplineUpdateUI
	call	SplineDestroyGState
	call	SplineEndmCommon

	ret

SplineLostTargetExcl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineFreeUndoAndNew
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the UNDO and the NEW POINTS arrays

CALLED BY:	SplineLostTargetExcl

PASS:		es:bp - vis spline instance
		*ds:si - points

RETURN:		nothing 

DESTROYED:	ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineFreeUndoAndNew	proc near
	class	VisSplineClass 
	.enter

	clr	ax
	xchg	ax, es:[bp].VSI_undoPoints
	tst	ax
	jz	afterUndo
	call	LMemFree

afterUndo:
	clr	ax
	xchg	ax, es:[bp].VSI_newPoints
	tst	ax
	jz	done
	call	LMemFree
done:
	.leave
	ret
SplineFreeUndoAndNew	endp

SplineObjectCode	ends
