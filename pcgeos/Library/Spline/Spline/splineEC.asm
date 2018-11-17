COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS - Spline edit object
MODULE:		Splines
FILE:		splineEC.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

GLOBAL
ROUTINES:
	ECSplineAnchorPoint
	ECSplineControlPoint
	ECSplineInstanceAndLMemBlock
	ECSplineInstanceAndPoints
	ECSplinePoint
	ECSplinePointsDSSI
	ECSplineScratchChunk
	ECSplineTempAndFilledHandleFlags

LOCAL
ROUTINES:

DESCRIPTION:	Error-checking procedures for the spline code


	$Id: splineEC.asm,v 1.1 97/04/07 11:09:06 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

IF ERROR_CHECK

SplineUtilCode	segment



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECSplineControlPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure ax points to a valid control point

CALLED BY:	GLOBAL

PASS:		ax - point number
		*ds:si - points array

RETURN:		nothing

DESTROYED:	nothing, not even flags

CHECKS:
	1) point # (AX) exists
	2) AX is a CONTROL point
	3) the point's TYPE flag contains no SMOOTHNESS bits
	4) the SELECTED bit is clear
	5) the HOLLOW_HANDLE bit is clear

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineControlPoint	proc	far
	uses	ax, di
	.enter
	pushf
	call	ChunkArrayElementToPtr
	ERROR_C ILLEGAL_SPLINE_POINT_NUMBER
	mov	al, ds:[di].SPS_info
	test	al, mask PIF_CONTROL
	ERROR_Z	EXPECTED_A_CONTROL_POINT


	; HACK HACK HACK Low 3 bits of control point record must always be zero!
	push	ax
	andnf	al, 7
	tst	al
	ERROR_NZ	ILLEGAL_POINT_INFO_RECORD  
	pop	ax

	call	ECSplineTempAndFilledHandleFlags

	popf				; restore flags
	.leave
	ret	
ECSplineControlPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECSplineAnchorPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure ax points to a valid anchor point

CALLED BY:	GLOBAL

PASS:		ax - point #
		*ds:si points array

RETURN:		nothing

DESTROYED:	nothing (flags preserved)

CHECKS:		
	1)	AX is a valid point
	2)	AX is an anchor point
	3)	the PREV bit is clear in Type record
	4)	CONTROL_LINE_DRAWN bit is clear
	5)	not both FILLED_HANDLE and HOLLOW_HANDLE bits are set

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineAnchorPoint	proc	far
	uses	ax, di
	.enter
	pushf				
	call	ChunkArrayElementToPtr
	ERROR_C ILLEGAL_SPLINE_POINT_NUMBER
	mov	al, ds:[di].SPS_info
	test	al, mask PIF_CONTROL
	ERROR_NZ	EXPECTED_AN_ANCHOR_POINT

	; see if both filled-handle and hollow-handle drawn flags are set

	andnf	al, mask PIF_FILLED_HANDLE or mask APIF_HOLLOW_HANDLE
	cmp	al, mask PIF_FILLED_HANDLE or mask APIF_HOLLOW_HANDLE
	ERROR_E		ILLEGAL_POINT_INFO_RECORD

	call	ECSplineTempAndFilledHandleFlags

	popf
	.leave
	ret
ECSplineAnchorPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSplineInstanceAndLMemBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure that the lmemBlock pointer in
	the spline's instance data actually points to a valid LMem
	block.  Also check the SCRATCH CHUNK


CALLED BY:	Internal

PASS:		es:bp - VisSplineInstance data
		ds - data segment of spline's lmem data block

RETURN:		nothing

DESTROYED:	nothing, not even flags	

CHECKS:		

	1) spline's lmem heap is OK
	2) points block is locked
	3) points block is at address pointed to by DS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 4/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineInstanceAndLMemBlock	proc	far
	uses	ax,bx,di
	class	VisSplineClass

	.enter

	pushf

	; Make sure the spline block is OK

	segxchg	ds, es
	call	ECLMemValidateHeap
	segxchg	ds, es

	; Make sure the points block is at the address we think it's at
	
	mov	bx, es:[bp].VSI_lmemBlock
	mov	ax, MGIT_ADDRESS		
	call	MemGetInfo
	mov	bx, ds
	cmp	ax, bx
	ERROR_NE LMEM_BLOCK_AT_INCORRECT_ADDRESS

	; Validate the points block

	call	ECLMemValidateHeap

	; check scratch chunk

	call	ECSplineScratchChunk

	popf

	.leave
	ret
ECSplineInstanceAndLMemBlock	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECSplineInstanceAndPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks that the spline chunk handle and the handle of
		the points array are both valid.

CALLED BY:	internal

PASS:		es:bp - VisSplineInstance data
		*ds:si - points array 

RETURN:		nothing

DESTROYED:	nothing (not even flags)

CHECKS:
	1) see ECSplineInstanceAndLMemBlock
	2) makes sure that SI corresponds to the chunk handle of the
	points in the instance data
	3) makes sure the points array isn't corrupted.

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineInstanceAndPoints	proc	far
	uses	bx
	class	VisSplineClass
	.enter
	pushf
	call	ECSplineInstanceAndLMemBlock
	
	cmp	si, es:[bp].VSI_points		; check points chunk address
	ERROR_NE	DS_SI_NOT_SPLINE_POINTS

	call	ECSplinePointsDSSI
	popf
	.leave
	ret
ECSplineInstanceAndPoints	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECSplinePointsDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that *DS:SI points to the points array.

CALLED BY:	internal

PASS:		*ds:si - points array ?

RETURN:		nothing

DESTROYED:	nothing (flags preserved)

REGISTER/STACK USAGE:	

PSEUDO CODE/STRATEGY:	Make sure it's a valid chunk array,
	make sure there aren't too many points

KNOWN BUGS/SIDE EFFECTS/IDEAS: 	Whenever possible, make a call to 
	ECSplineInstanceAndPoints instead of this function.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplinePointsDSSI	proc	near
	uses	ax,bx,cx,di
	.enter
	pushf
	call	ChunkArrayGetCount
	cmp	cx,	SPLINE_MAX_POINT
	ERROR_G	TOO_MANY_SPLINE_POINTS

	call	SysGetECLevel
	test	ax, mask ECF_APP
	jz	done

	; Test every fucking point

	mov	bx, cs
	mov	di, offset ECSplinePointDSDI
	call	ChunkArrayEnum
	
done:
	popf
	.leave
	ret
ECSplinePointsDSSI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECSplinePoint		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the spline point's info stuff.  Assume that the
		PIF_CONTROL bit is set correctly.

CALLED BY:	internal to VisSplineClass

PASS:		ax - point number
		*ds:si - points array

RETURN:		nothing

DESTROYED:	nothing (flags  preserved)

PSEUDO CODE/STRATEGY:	
	Dereference the point, and call the common routine.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplinePoint	proc	far
	push	ax, di
	pushf	
	call	ChunkArrayElementToPtr
	jmp	ECSplinePointCommon
ECSplinePoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSplinePointDSDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the spline point at ds:di

CALLED BY:

PASS:		ds:di - SplinePointStruc

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplinePointDSDI	proc far
	push	ax, di
	pushf
	call	ChunkArrayPtrToElement	; get element # in AX
	REAL_FALL_THRU	ECSplinePointCommon
ECSplinePointDSDI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSplinePointCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the spline point

CALLED BY:

PASS:		ax - Spline point number
		ds:di - SplinePointStruc

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Must be JMP'd to with AX, DI, and FLAGS pushed on stack (in
	that order)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplinePointCommon	proc far	jmp
	test	ds:[di].SPS_info, mask PIF_CONTROL
	jnz	control
	call	ECSplineAnchorPoint
	jmp	done
control:
	call	ECSplineControlPoint
done:
	popf
	pop	ax, di
	ret
ECSplinePointCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	ECSplineTempAndFilledHandleFlags		
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to make sure that not both the TEMP and the
		HANDLE_DRAWN flags are set in the point's SPS_info
		record

CALLED BY:	ECSplineAnchorPoint, ECSplineControlPoint

PASS:		ds:di - point

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineTempAndFilledHandleFlags	proc	near
	uses	ax
	.enter
	mov	al, ds:[di].SPS_info
	andnf	al, mask PIF_TEMP or mask PIF_FILLED_HANDLE
	cmp 	al, mask PIF_TEMP or mask PIF_FILLED_HANDLE
	ERROR_E	ILLEGAL_POINT_INFO_RECORD
	.leave
	ret
ECSplineTempAndFilledHandleFlags	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSplineScratchChunk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure the scratch chunk exists for the 
		spline object, and make sure the chunk handle of the
		spline object (stored in the scratch chunk) is correct.

CALLED BY:	

PASS:		es:bp - VisSplineInstance data
		ds - segment of scratch chunk

RETURN:		nothing

DESTROYED:	nothing	

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	6/ 4/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineScratchChunk	proc	near
	uses	si
	class	VisSplineClass
	.enter
	pushf
	mov	si, es:[bp].VSI_scratch
	tst	si
	ERROR_Z	SCRATCH_CHUNK_NOT_ALLOCATED

	mov	si, ds:[si]
	mov	si, ds:[si].SD_splineChunkHandle
	mov	si, es:[si]
	add	si, es:[si].VisSpline_offset
	cmp	si, bp
	ERROR_NE SPLINE_POINTER_AND_CHUNK_HANDLE_DONT_MATCH


	popf
	.leave
	ret
ECSplineScratchChunk	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSplineInstanceAndScratch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that es:bp and ds:di point to what they oughtta

CALLED BY:

PASS:		es:bp - VisSplineInstance data 
		ds:di - scratch chunk 

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/11/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineInstanceAndScratch	proc	far
	uses	si
	class	VisSplineClass 
	.enter
	pushf 
	call	ECSplineInstanceAndLMemBlock
	mov	si, es:[bp].VSI_scratch
	mov	si, ds:[si]
	cmp	si, di
	ERROR_NE	DI_NOT_POINTING_TO_SCRATCH_CHUNK
	popf
	.leave
	ret
ECSplineInstanceAndScratch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECSplineAttrChunks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check that the SS_HAS_ATTR_CHUNKS bit is set in the
		instance data.

CALLED BY:	all Set/Get Line/Area attribute methods

PASS:		es:bp - VisSplineInstance data 
		
RETURN:		nothing 

DESTROYED:	Nothing, flags preserved

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/16/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECSplineAttrChunks	proc far
	class	VisSplineClass 
	.enter
	pushf
	test	es:[bp].VSI_state, mask SS_HAS_ATTR_CHUNKS
	ERROR_Z	SPLINE_HAS_NO_ATTR_CHUNKS
	popf
	.leave
	ret
ECSplineAttrChunks	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSplineDSSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that *ds:si is the spline

CALLED BY:

PASS:		

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	6/11/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSplineDSSI	proc far
	uses	es, di
	.enter
	pushf
	segmov	es, <segment VisSplineClass>, di
	mov	di, offset VisSplineClass
	call	ObjIsObjectInClass
	ERROR_NC	DS_SI_WRONG_CLASS
	popf	

	.leave
	ret
ECCheckSplineDSSI	endp


SplineUtilCode	ends


ENDIF
