COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS - Spline edit object
MODULE:				
FILE:		splineUtils.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

GLOBAL
ROUTINES:

LOCAL
ROUTINES: 

DESCRIPTION:	This file contains general "Utility" routines 

	$Id: splineUtils.asm,v 1.1 97/04/07 11:08:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplinePtrCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMouseMethodCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Subtract the upper left-hand corner of the VIS bounds
	from the mouse coordinates (cx and dx).  Store these
	coordinates and the mouse-flags (UIFA etc) in the scratch data
	chunk.

CALLED BY:	SplineStartSelect, SplineDragSelect, SplinePtr, etc.

PASS:		*ds:si - VisSpline object
		ds:di - Vis instance data
		cx, dx - mouse position (screen coordinates)

RETURN:		cx, dx - "Vis" object coordinates
		(also, see SplineMethodCommon for values returned)

		bx - SplineMode

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/20/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMouseMethodCommonReadOnly	proc	far
	class	VisSplineClass 

	.enter

	; Read-only version of SplineMouseMethodCommon (doesn't mark
	; blocks dirty)

	sub	cx, ds:[di].VI_bounds.R_left
	sub	dx, ds:[di].VI_bounds.R_top	
	call	SplineMethodCommonReadOnly
	GetEtypeFromRecord	bx, SS_MODE, es:[bp].VSI_state 

	.leave
	ret
SplineMouseMethodCommonReadOnly	endp

SplineMouseMethodCommon	proc far	
	class	VisSplineClass

	sub	cx, ds:[di].VI_bounds.R_left
	sub	dx, ds:[di].VI_bounds.R_top	
	call	SplineMethodCommon
	GetEtypeFromRecord	bx, SS_MODE, es:[bp].VSI_state 
	ret
SplineMouseMethodCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineMethodCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the common registers, lock the spline's lmem
		block.	

CALLED BY:	methods

PASS:		*ds:si - VisSpline object
		ds:di - VisSpline instance data

RETURN:		es:bp - VisSplineInstance data
		*ds:si - spline points

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	
	Most spline methods write data, therefore the default case is
	to mark both blocks dirty here at the beginning.  If a method
	is known not to write data, then SplineMethodCommonReadOnly should
	be called instead.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMethodCommonReadOnly	proc	far
	; Read-only version of SplineMethodCommon (doesn't mark object
	; block dirty)

	call	SplineMethodCommonLow
	ret

SplineMethodCommonReadOnly	endp

SplineMethodCommon	proc	far

	.enter

	call	ObjMarkDirty
	call	SplineMethodCommonLow

	;
	; Mark the points block dirty, too
	;
	push	bp
	mov	bp, ds:[LMBH_handle]
	call	VMDirty
	pop	bp

	.leave
	ret
SplineMethodCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMethodCommonLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine called whenever we want to lock the
		points block, etc.

CALLED BY:	SplineMethodCommon, SplineMethodCommonReadOnly

PASS:		*ds:si - spline object
		ds:di - VisSplineInstance

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMethodCommonLow	proc near
	class	VisSplineClass 

	uses	ax,bx

	.enter

	; set ES pointing to spline block
	
	segmov	es, ds, ax

	; set DS to spline's points block

	mov	bx, es:[di].VSI_lmemBlock
	call	ObjLockObjBlock
	mov	ds, ax

	; create scratch chunk

	call	SplineCreateScratchChunk

	; Now, set ES:BP as fptr to VSI data

	mov	bp, di

	; set *DS:SI as points array

	mov	si, es:[bp].VSI_points

EC <	call	ECSplineInstanceAndLMemBlock	> 

	.leave
	ret
SplineMethodCommonLow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetVMFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the VM file containing the current spline

CALLED BY:	SplineMethodCommon

PASS:		ds - segment in same VM file as VisSpline object

RETURN:		bx - spline's VM file

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/12/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineGetVMFile	proc far
	uses	ax
	.enter

	mov	bx, ds:[LMBH_handle]
	mov	ax, MGIT_OWNER_OR_VM_FILE_HANDLE
	call	MemGetInfo
	mov_tr	bx, ax

	.leave
	ret
SplineGetVMFile	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineEndmCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Common routine for ending a method:  free the scratch
		chunk, unlock the spline's memory block

CALLED BY:	methods

PASS:		es:bp - VisSplineInstance data 
		ds - data segment of spline's lmem block 

RETURN:		nothing 

DESTROYED:	bx (flags preserved)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 3/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineEndmCommon	proc far	call

	class	VisSplineClass 

	.enter

	pushf

EC <	call	ECSplineInstanceAndLMemBlock	> 

	; Free the scratch chunk and unlock the points block

	call	SplineFreeScratchChunk
	mov	bx, ds:[LMBH_handle]
	call	MemUnlock

	popf

	.leave
	ret
SplineEndmCommon	endp


SplinePtrCode	ends



SplineUtilCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSendMyselfAMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to myself, fixing up any moved
		segments and pointers if necessary

CALLED BY:	SplineDetermineIfBoundsGrown

PASS:		es:bp - VisSplineInstance data
		ds - spline's data block

		ax - message number
		cx, dx, bx - other data to pass (in cx, dx, and bp)

RETURN:		es, bp, and ds fixed up, if necessary
		ax, cx, dx - returned from method (sorry, no bp!)

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/21/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineSendMyselfAMessage	proc far	
	uses		bx,si
	class	VisSplineClass
	.enter

EC <	call	ECSplineInstanceAndLMemBlock	> 
	push	ds:[LMBH_handle]

	SplineDerefScratchChunk si
	mov	si, ds:[si].SD_splineChunkHandle

	segmov	ds, es			; point DS to my object block
	mov	bp, bx
	call	ObjCallInstanceNoLock	; send message!

	; Point ES:BP back to the spline

	segmov	es, ds		
	mov	bp, es:[si]
	add	bp, es:[bp].VisSpline_offset

	; Pop the points block's handle. 

	pop	bx

	; Dereference the (locked) points block

	call	MemDerefDS		
EC <	call	ECSplineInstanceAndLMemBlock	>
	.leave
	ret
SplineSendMyselfAMessage	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineRelocate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data

		ax - MSG_META_RELOCATE/MSG_META_UNRELOCATE
		cx - handle of block containing relocation
		dx - VMRelocType:
			VMRT_UNRELOCATE_BEFORE_WRITE
			VMRT_RELOCATE_AFTER_READ
			VMRT_RELOCATE_AFTER_WRITE
		bp - data to pass to ObjRelocOrUnRelocSuper
RETURN:		carry - set if error
		bp - unchanged

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/24/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineRelocate	method	dynamic	VisSplineClass, reloc

	cmp	dx, VMRT_RELOCATE_AFTER_READ
	jne	done

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ax
	mov	ds:[di].VSI_gstate, ax
	mov	ds:[di].VSI_gstateRefCount, al
done:
	mov	di, offset VisSplineClass
	call	ObjRelocOrUnRelocSuper
	ret
SplineRelocate	endm



SplineUtilCode	ends
