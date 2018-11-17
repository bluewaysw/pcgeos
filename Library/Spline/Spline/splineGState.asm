COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineGState.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/29/92   	Initial version.

DESCRIPTION:
	Routines for dealing with the GState

	$Id: splineGState.asm,v 1.1 97/04/07 11:08:59 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


SplinePtrCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineCreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate for the spline, and store it it
		VSI_gstate.   If gstate is non-null then simply up the
		ref count

CALLED BY:	GLOBAL

PASS:		*ds:si - VisSplineClass object
		ds:di - VisSplineClass instance data
		es - segment of VisSpline class record

RETURN:		ds, di fixed up (if necessary) to point to the same
		places they pointed to before.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCreateGState	proc	far
	uses	ax, bp
	class	VisSplineClass
	.enter

	; If ref count nonzero, then simply increment it.

	tst	ds:[di].VSI_gstateRefCount
	jnz	incrementRefCount

	call	SplineCreateGStateLow

	mov	di, ds:[si]
	add	di, ds:[di].VisSpline_offset
	mov	ds:[di].VSI_gstate, bp		; store it in the
						; object
incrementRefCount:
	inc	ds:[di].VSI_gstateRefCount
EC <	ERROR_Z	TOO_MANY_CREATE_GSTATE_CALLS		>
	.leave
	ret
SplineCreateGState	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCreateGStateLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Vup for gstate and apply translation to it

CALLED BY:	INTERNAL
		SplineCreateGState
		SplineRecreateCachedGStates

PASS:		*ds:si - spline object

RETURN:		
		bp - gstate

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCreateGStateLow		proc	near
	uses	ax,cx,dx
	.enter

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock

	xchg	bp, di					;preserved data, gstate
	call	SplineTranslateGStateByVisBounds
	xchg	di, bp					;preserved data, gstate

	.leave
	ret
SplineCreateGStateLow		endp

SplineCreateGStateLowFar	proc	far
	call	SplineCreateGStateLow
	ret
SplineCreateGStateLowFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineDestroyGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the Gstate ref count. If zero, destroy the gstate.

CALLED BY:	GLOBAL

PASS:		es:bp - VisSplineInstance data

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineDestroyGState	proc	far
	uses	ax, di
	class	VisSplineClass
	.enter

	; see if spline has a gstate

	 
	tst	es:[bp].VSI_gstateRefCount
	jz	done

	; decrement count
	dec	es:[bp].VSI_gstateRefCount
	jnz	done

	; destroy state
	clr	ax
	xchg	ax, es:[bp].VSI_gstate	
	mov	di, ax
	call	GrDestroyState
done:
	.leave
	ret
SplineDestroyGState	endp

SplinePtrCode	ends

SplineUtilCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetupPassedGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the passed gstate, and translate it for the
		spline's own evil purposes.

CALLED BY:	SplineDraw... methods

PASS:		*ds:si - VisSpline object
		ds:di - VisSpline instance data
		bp - gstate handle

RETURN:		es:bp - VisSplineInstance data
		*ds:si - points array (block locked)

		spline's OLD gstate is stored away in the scratch
		chunk.

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	
	Don't dirty the block, as we're assuming that the old gstate
	will be restored to the instance data when we're done.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSetupPassedGState	proc far
	class	VisSplineClass 
	uses	ax,di
	.enter

	; Store the passed gstate handle in the instance data, preserving
	; whatever was there before in AX
	mov	ax, bp			
	xchg	ax, ds:[di].VSI_gstate	

	; Save the state of the passed GState, preserving DI
	xchg	di, bp			
	call	GrSaveState

	; translate the gstate
	call	SplineTranslateGStateByVisBounds
	xchg	di, bp		; restore DI to point to the spline

	call	SplineMethodCommonReadOnly
	SplineDerefScratchChunk di
	mov	ds:[di].SD_oldGState, ax
	.leave
	ret
SplineSetupPassedGState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRestorePassedGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the passed gstate to what it was.

CALLED BY:	SplineDraw... methods

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		nothing   

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	
	Call this routine BEFORE calling SplineEndmCommon, as it uses
	the scratch chunk.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 6/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRestorePassedGState	proc far
	class	VisSplineClass 
	uses	ax,di
	.enter
	SplineDerefScratchChunk di
	mov	ax, ds:[di].SD_oldGState
	xchg	ax, es:[bp].VSI_gstate
	mov	di, ax
	call	GrRestoreState
	.leave
	ret
SplineRestorePassedGState	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRecreateCachedGStates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy VSI_gstate and create a new one

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object (if any)
		es - segment of VisSplineClass

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
	srs	4/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineRecreateCachedGStates	method dynamic VisSplineClass, 
						MSG_VIS_RECREATE_CACHED_GSTATES
	uses	bp
	.enter

	mov	di,ds:[di].VSI_gstate
	tst	di
	jz	done

	call	GrDestroyState
	call	SplineCreateGStateLowFar

	mov	di, ds:[si]
	add	di, ds:[di].VisSpline_offset
	mov	ds:[di].VSI_gstate, bp		

done:
	.leave
	ret
SplineRecreateCachedGStates		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineTranslateGStateByVisBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set-up the gstate's translation matrix to be offset by
		the vis-bounds of the object

CALLED BY:	SplineCreateGState, SplineDraw

PASS:		*ds:si - VisSplineClass object
		di - gstate handle

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineTranslateGStateByVisBounds	proc far uses	ax,bx,cx,dx
	class	VisSplineClass
	.enter

	; Deref vis-class instance data

	mov	bx, ds:[si]
	add	bx, ds:[bx].Vis_offset

	; load translation values into (DX.CX) and (BX.AX)

	clr	ax
	mov	cx, ax
	mov	dx, ds:[bx].VI_bounds.R_left
	mov	bx, ds:[bx].VI_bounds.R_top

	; Perform the translation
	call	GrApplyTranslation
	.leave
	ret
SplineTranslateGStateByVisBounds	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Recreate any cached gstates

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	Send myself MSG_VIS_RECREATE_CACHED_GSTATES

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineVisOpen	method	dynamic	VisSplineClass, 
					MSG_VIS_OPEN
	.enter

	mov	di, offset VisSplineClass
	call	ObjCallSuperNoLock

	mov	ax, MSG_VIS_RECREATE_CACHED_GSTATES
	call	ObjCallInstanceNoLock

	.leave
	ret
SplineVisOpen	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Nuke the currently held gstate

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup

RETURN:		

DESTROYED:	ax,cx,dx,bp

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	
	I don't know if this is the right way to do it.  All I know is
it's crashing on VisOpen right now, because its trying to nuke a
gstate to a window that may have already been freed.

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/29/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineVisClose	method	dynamic	VisSplineClass, 
					MSG_VIS_CLOSE
	.enter
	mov	di, offset VisSplineClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	clr	ax
	mov	ds:[di].VSI_gstateRefCount, al


	xchg	ax,ds:[di].VSI_gstate
	tst	ax
	jz	done

	mov_tr	di, ax
	call	GrDestroyState

done:
	.leave
	ret
SplineVisClose	endm



SplineUtilCode	ends

