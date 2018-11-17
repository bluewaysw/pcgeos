COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		VisSpline object
FILE:		splineScratch.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/91		Initial version

DESCRIPTION:
	Routines to handle the scratch chunk(s) used by the spline object.


ROUTINES:
	SplineCreateScratchChunk
	SplineFixupAnchorSD
	SplineFreeScratchChunk
	SplineGetAnchorSD
	SplineSaveAnchorSD
	SplineSaveCXDXToSD


	$Id: splineScratch.asm,v 1.1 97/04/07 11:09:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCreateScratchChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate the scratch chunk.   If it already exists,
		then increment its ref count.

CALLED BY:	

PASS:		*ES:SI - VisSplineClass object
		ES:DI - VisSplineInstance data
		ds - data segment in which to allocate

RETURN:		nothing 

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 4/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCreateScratchChunk	proc	near
	uses	ax, bx, cx
	class	VisSplineClass
	.enter

	mov	ax, es:[di].VSI_scratch
	tst	ax
	jnz	upRefCount


	;
	; allocate new one
	;

	clr	al	
	mov	cx, size ScratchData
	call	LMemAlloc
	mov	es:[di].VSI_scratch, ax 	; store chunk handle

	; set the ref count

	xchg	ax, bx			; ax <- VM override, bx <-
					; chunk handle

	mov	bx, ds:[bx]
	mov	ds:[bx].SD_refCount, 1	; One reference so far

	; Nuke any flags

	clr	ds:[bx].SD_flags

	;
	; store the spline object's chunk handle
	;

	mov	ds:[bx].SD_splineChunkHandle, si


	;
	; zero-initialize the SD_startRect, for the case where the
	; user does an extended selection without previously having
	; done a selection.  
	;

	clrdw	ds:[bx].SD_startRect

done:
	.leave
	ret

upRefCount:
	xchg	ax, bx
	mov	bx, ds:[bx]
	inc	ds:[bx].SD_refCount
EC <	ERROR_Z	BAD_SCRATCH_CHUNK_REF_COUNT	>
	jmp	done

SplineCreateScratchChunk	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineFreeScratchChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the scratch chunk's ref count.  If zero,
		LMemFree the scratch chunk.

CALLED BY:	SplineEndSelect

PASS:		es:bp - VisSplineInstance data
		ds - data segment of scratch chunk

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/31/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineFreeScratchChunk	proc near	 uses	ax, bx
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock		>
	 
	mov	ax, es:[bp].VSI_scratch
	tst	ax
EC <	ERROR_Z	BAD_SCRATCH_CHUNK_REF_COUNT	>

	mov	bx, ax
	mov	bx, ds:[bx]

	dec	ds:[bx].SD_refCount
	jnz	done

	; clear the reference to it in the instance data.

	call	LMemFree
	clr	es:[bp].VSI_scratch
done:
	.leave
	ret
SplineFreeScratchChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSaveAnchorSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save the anchor point number in the scratch data chunk

CALLED BY:	SplineOperateOnWhichPoints

PASS:		ax - current anchor point number
		es:bp - VisSplineInstance data 
		ds  - data  segment of scratch chunk

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	7/ 1/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSaveAnchorSD	proc near uses	di
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock			>
	
	
	SplineDerefScratchChunk di
	mov	ds:[di].SD_anchor, ax

	.leave
	ret
SplineSaveAnchorSD	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetAnchorSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the anchor point number from the ScratchData chunk.

CALLED BY:	SplineOperateOnWhichPoints

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of scratch chunk

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	CHANGED: 8/91:  Allow an "illegal" point number to be
stored/retrieved.  This means can't call ECSplineAnchorPoint (too bad!).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	7/ 1/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetAnchorSD	proc	near
	uses	di
	class	VisSplineClass 
	.enter
EC <	call	ECSplineInstanceAndLMemBlock			>

	SplineDerefScratchChunk	di
	mov	ax, ds:[di].SD_anchor

	.leave
	ret
SplineGetAnchorSD	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSaveCXDXToSD
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save CX and DX in the scratch data chunk

CALLED BY:	SplineOperateSetup

PASS:		es:bp - VisSplineInstance data 
		cx - value to be stored
		ds - data segment of scratch chunk
	
RETURN:		carry clear

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	8/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSaveCXDXToSD	proc near
	class	VisSplineClass
	.enter
EC <	call	ECSplineInstanceAndLMemBlock	> 
	
	SplineDerefScratchChunk di
	mov	ds:[di].SD_paramCX, cx
	mov	ds:[di].SD_paramDX, dx
	clc
	.leave
	ret
SplineSaveCXDXToSD	endp


SplinePtrCode	ends
