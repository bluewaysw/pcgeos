COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		splineCutPaste.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/14/92   	Initial version.

DESCRIPTION:
	

	$Id: splineCutPaste.asm,v 1.1 97/04/07 11:09:07 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineCreateTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.
		cx	= vm file to use

RETURN:		ax - vm block handle


DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineCreateTransferFormat	method	dynamic	VisSplineClass, 
					MSG_SPLINE_CREATE_TRANSFER_FORMAT
	uses	cx, dx, bp
	.enter

	call	ObjMarkDirty

	push	cx			; transfer file
	mov	bx, cx

	clr	ax
	mov	cx, size SplineVMChainHeader
	call	VMAlloc
	push	ax			; transfer vm  block handle
	call	VMLock
	mov	es, ax
	mov	es:SVMCH_protocol, SPLINE_VM_CHAIN_PROTOCOL

EC <	segmov	es, ds			; Avoid segment EC death... >
					;  caused by CopyChunkToVMBlock
					;  reallocing the block to which ES
					;  is pointing...

	mov	bx, bp			; mem handle of vm block
	mov	cx, ax			; address of vm block

	; Copy the entire spline

	mov	dx, size SplineVMChainHeader	; set initial offset
	mov	ax, offset SVMCH_spline
	call	CopyChunkToVMBlock

	call	SplineMethodCommon

	mov	si, es:[bp].VSI_points
	mov	ax, offset SVMCH_points
	call	CopyChunkToVMBlock

	mov	si, es:[bp].VSI_lineAttr
	mov	ax, offset SVMCH_lineAttr
	call	CopyChunkToVMBlock

	mov	si, es:[bp].VSI_areaAttr
	mov	ax, offset SVMCH_areaAttr
	call	CopyChunkToVMBlock

	push	es
	mov	es, cx
	mov	es:[SVMCH_endOfData], dx
	pop	es
	

	push	bx			; transfer block mem handle
	call	SplineEndmCommon
	pop	bx

	; restore things the way we found them


	pop	ax		; returned to caller

	mov	bp, bx
	pop	bx		; transfer file		
	call	VMDirty
	call	VMUnlock

	.leave
	ret
SplineCreateTransferFormat	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CopyChunkToVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy a chunk into the passed vm block

CALLED BY:

PASS:		ax - offset in header of vm block at which to store
		pointer to current info

		bx - handle of vm block
		cx - segment address of vm block
		dx - pointer to end of block

		*ds:si - chunk to copy

RETURN:		cx,dx updated if changed

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CopyChunkToVMBlock	proc near
	uses	di, si, es
	.enter

	; Always store the current offset, so when pasting, we can use
	; it to calculate the size. 

	mov	es, cx		; segment of vm block
	mov	di, ax
	mov	es:[di], dx	; store current offset

	tst	si
	jz	done

	mov	si, ds:[si]
	ChunkSizePtr	ds, si, cx
	push	cx			; # bytes
	mov	ax, cx
	add	ax, dx
	mov	ch, mask HAF_NO_ERR		; be a spud
	call	MemReAlloc
	mov	es, ax
	pop	cx			; # bytes to copy
	mov	di, dx
	shr	cx
	rep	movsw
	jnc	afterByte
	movsb
afterByte:
	mov	dx, di
	mov	cx, es
done:
	.leave
	ret
CopyChunkToVMBlock	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineReplaceWithTransferFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Paste in spline data.

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

		cx - vm file handle
		dx - vm block handle

RETURN:		ax - SplinePasteReturnType

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineReplaceWithTransferFormat	method	dynamic	VisSplineClass, 
				MSG_SPLINE_REPLACE_WITH_TRANSFER_FORMAT
	uses	cx,dx

transferMemBlock local	hptr	
transferSegment	local	word
spline		local	fptr

	.enter

	movdw	spline, dssi
	segmov	es, ds			; es:di - VisSplineInstance

	mov	bx, cx			; transfer file
	mov	ax, dx			; transfer vm block
	push	bp
	call	VMLock
	mov	bx, bp
	pop	bp
	mov	transferMemBlock, bx
	mov	ds, ax
	mov	transferSegment, ax
	
	cmp	ds:[SVMCH_protocol], SPLINE_VM_CHAIN_PROTOCOL
	jg	protoTooNew
	jl	protoTooOld

	mov	si, ds:[SVMCH_spline]
	add	si, ds:[si].Vis_offset

	;
	; Copy instance data from transfer fromat to new spline.  We
	; don't really copy ver much instance data -- just the state,
	; bounds, marker shape, etc.
	;
	; Nuke all state vars but 2:
	;
	mov	al, ds:[si].VSI_markerShape
	mov	es:[di].VSI_markerShape, al
	mov	al, ds:[si].VSI_state
	andnf	al, mask SS_CLOSED or mask SS_FILLED 
	ornf	es:[di].VSI_state, al
	push	si,di			;transfer, instance data offsets
	add	si,offset VI_bounds
	add	di,offset VI_bounds
	mov	cx,(size Rectangle/2)
	rep	movsw
	pop	si,di			;transfer, instance data offsets

	; Now, copy the points

	mov	cx, ds			; transfer vm block

	lds	si, spline	; restore original spline ptr
	push	bp
	call	SplineMethodCommon	; ds - spline's lmem block
	mov	di, bp			; pointer to spline
	pop	bp
	mov	spline.offset, di

	mov	bx, offset VSI_points
	mov	dx, offset SVMCH_points
	call	PasteFromVMBlock

	mov	bx, offset VSI_lineAttr
	mov	dx, offset SVMCH_lineAttr
	call	PasteFromVMBlock

	mov	bx, offset VSI_areaAttr
	mov	dx, offset SVMCH_areaAttr
	call	PasteFromVMBlock

	push	bp			; local frame
	les	bp, spline		; es:bp - spline again

	call	SplineInvalidate

	call	SplineEndmCommon
	pop	bp			; local frame

	mov	ax, SPRT_OK	

unlock:
	push	bp
	mov	bp, transferMemBlock
	call	VMUnlock
	pop	bp

	.leave
	ret

protoTooOld:
	mov	ax, SPRT_TOO_OLD
	jmp	unlock
protoTooNew:
	mov	ax, SPRT_TOO_NEW
	jmp	unlock


SplineReplaceWithTransferFormat	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PasteFromVMBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine to paste the passed data from the vm
		block. 

CALLED BY:	SplineReplaceWithTransferFormat

PASS:		bx - offset in spline instance data to chunk handle
		dx - offset in vm block to pointer to data
		ds - segment of spline's lmem block
		ss:bp - local vars			

RETURN:		ds - updated if moved

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/14/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PasteFromVMBlock	proc near
	uses	ax,bx,cx,dx,di,si,bp

	.enter	inherit SplineReplaceWithTransferFormat

	les	di, spline
	mov	si, es:[di][bx]		; chunk handle in instance
					; data.

	tst	si			; dest chunk handle
	jz	done

	mov	es, transferSegment
	mov	di, dx
	mov	cx, es:[di]+2		; get next offset
	mov	bx, es:[di]		; current offset
	sub	cx, bx			; calc size
	
	mov	ax, si			; dest chunk handle
	call	LMemReAlloc
	segxchg	ds, es			; ds - source seg, es - dest
	mov	di, es:[si]		; es:di - dest
	mov	si, bx			; ds:si - source, es:di - dest

	shr	cx
	rep	movsw
	jnc	afterMovsb
	movsb
afterMovsb:
	segxchg	ds, es			; ds <- lmem block
	
done:
	.leave
	ret
PasteFromVMBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineSetPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the points of the spline 	

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup
		ss:bp	- SplineSetPointParams

RETURN:		SplineReturnType

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/18/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineSetPoints	method	dynamic	VisSplineClass, 
					MSG_SPLINE_SET_POINTS

	uses	cx, dx

params		local	nptr.SplineSetPointParams push bp
curPoint	local	fptr
splineInstance	local	nptr
pointType	local	SplinePointTypeEnum
pointTypeInc	local	byte		; 0 or 1
pointSize	local	word


	.enter

if ERROR_CHECK
	push	ax, bx
	mov	bx, ss:[params]
	mov	al, ss:[bx].SSPP_flags
	test	al, not mask SplineSetPointFlags
	ERROR_NZ ILLEGAL_FLAGS
	andnf	al, mask SSPF_TYPE
	cmp	al, SSPT_POINT
	je	ok
	cmp	al, SSPT_WWFIXED
	ERROR_NE ILLEGAL_VALUE
ok:
	pop	ax, bx
endif

	;
	; Suspend ourselves so geometry won't happen until the end. 
	;
	push	bp
	mov	ax, MSG_META_SUSPEND
	call	ObjCallInstanceNoLock
	pop	bp

	;
	; Nuke whatever was there before.
	;

	clr	cx
	mov	dx, SPLINE_MAX_POINT
	mov	ax, MSG_SPLINE_DELETE_RANGE
	call	ObjCallInstanceNoLock

	mov	bx, ss:[params]
	mov	cx, ss:[bx].SSPP_numPoints

	push	bp			; local vars
	call	SplineMethodCommon

	;
	; make sure we can add this many points
	;

	call	SplineCheckToAddPoints
	mov_tr	ax, bp			; spline instance
	pop	bp
	mov	ss:[splineInstance], ax
	LONG	jc	noAdd

	mov	bx, ss:[params]
	movdw	ss:[curPoint], ss:[bx].SSPP_points, ax
	
	;
	; See what type of points we're adding.  If they're all
	; anchors, then the type never changes, so the increment is
	; zero.  If the array includes controls, then the increment is
	; one. 
	;

	clr	ss:[pointTypeInc]
	mov	al, SPTE_ANCHOR_POINT
	test	ss:[bx].SSPP_flags, mask SSPF_HAS_CONTROLS
	jz	gotType

	mov	ss:[pointTypeInc], 1
	test	ss:[bx].SSPP_flags, mask SSPF_FIRST_POINT_IS_CONTROL
	jz	gotType
	mov	al, SPTE_PREV_CONTROL
gotType:
	mov	ss:[pointType], al

	mov	al, ss:[bx].SSPP_flags
	andnf	ax, mask SSPF_TYPE
	mov	ss:[pointSize], ax

startLoop:
	tst	cx
LONG 	jz	endLoop
	push	bx, cx, es, si

	;
	; Append a new point to the array.  Don't pass x & y coords,
	; as they'll be filled in later.
	;
	mov	bl, ss:[pointType]
	clr	bh
	mov	bl, cs:[pointInfoTable][bx]

	push	bp
	mov	bp, ss:[splineInstance]
	call	SplineAddPointFar	; ds:di - point address
	mov_tr	ax, bp
	pop	bp
	mov	ss:[splineInstance], ax

EC <	ERROR_C	ILLEGAL_SPLINE_POINT_NUMBER 	>

	;
	; Whether we are loading integer or WWFixed points, CX gets
	; the first word, and DX gets the second.
	;
	CheckHack	<offset PF_x.WWF_frac eq offset P_x>
	CheckHack	<offset PF_x.WWF_int eq offset P_y>

	les	si, ss:[curPoint]
	mov	cx, es:[si]
	mov	dx, es:[si+2]

	cmp	ss:[pointSize], SSPT_WWFIXED
	jne	integer
	movdw	bxax, es:[si].PF_y
	StorePointWWFixed		; stores point at ds:di.SPS_point
	jmp	afterStore
integer:
	StorePointAsInt	ds:[di].SPS_point, cx, dx
afterStore:
	pop	bx, cx, es, si
	
	;
	; Set the point type for the next point
	;
	mov	al, ss:[pointType]
	add	al, ss:[pointTypeInc]
	cmp	al, SplinePointTypeEnum
	jl	gotNextType
	clr	al
gotNextType:
	mov	ss:[pointType], al

	;
	; Set the pointer to fetch the next point
	;
	
	mov	ax, ss:[pointSize]
	add	ss:[curPoint].offset, ax
	dec	cx
	jmp	startLoop

	;
	; Now that we've added all the points, recalculate our bounds.
	;
endLoop:
	push	bp
	mov	bp, ss:[splineInstance]
	mov	ax, MSG_VIS_RECALC_SIZE
	call	SplineSendMyselfAMessage
	mov_tr	ax, bp
	pop	bp
	mov	ss:[splineInstance], ax

noAdd:

	;
	; Whether or not we added the points, end the suspension (will
	; recalc vis bounds), before exiting
	;

	push	bp
	mov	bp, ss:[splineInstance]
	mov	ax, MSG_META_UNSUSPEND
	call	SplineSendMyselfAMessage
	call	SplineEndmCommon 
	pop	bp


	.leave
	ret
SplineSetPoints	endm

pointInfoTable	byte	\
	SPT_ANCHOR_POINT,
	SPT_NEXT_CONTROL,
	SPT_PREV_CONTROL


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMakePolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the spline's points to a regular n-sided polygon

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

		cx,dx	= half width, half height of polygon
		bp = number of sides to the polygon

RETURN:		SplineReturnType

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	16 sep 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMakePolygon	method	dynamic	VisSplineClass, MSG_SPLINE_MAKE_POLYGON

nPoints		local	word	push	bp
polygonHeight	local	word	push	dx
polygonWidth	local	word	push	cx
curAngle	local	WWFixed
incAngle	local	WWFixed
blockHandle	local	hptr
setPointParams	local	SplineSetPointParams

	uses	ax, cx, dx, bp
	.enter


	mov	ax, ss:[nPoints]
	mov	ss:[setPointParams].SSPP_numPoints, ax

	cmp	ax, 3		; must have at least 3 points
	jae	enough
doneJMP:
	jmp	done
enough:
	cmp	ax, SPLINE_MAX_POINT
	ja	doneJMP

CheckHack	<size PointWWFixed eq 8>
	mov	cl, 3
	shl	ax, cl
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	doneJMP
	mov	es, ax

	mov	ss:[blockHandle], bx
	mov	ss:[setPointParams].SSPP_points.segment, ax
	clr	ss:[setPointParams].SSPP_points.offset
	mov	ss:[setPointParams].SSPP_flags, SSPT_WWFIXED

	;
	;  Calculate the incremental angle (= 360/nPoints)
	;

	mov	bx, ss:[nPoints]
	mov	dx, 360
	clr	ax, cx
	call	GrUDivWWFixed
	movwwf	ss:[incAngle], dxcx

	;
	;  Set up our starting angle = 90 + 1/2 incAngle, so that the
	;  bottom of the generated polygon will be flat.
	;  
	shrwwf	dxcx					;dxcx <- 1/2 angle
	add	dx, 90					;start at lower left
	movwwf	ss:[curAngle], dxcx

	clr	di			; es:di - next point
pointLoop:
	movwwf	dxax, ss:[curAngle]
	pushdw	dxax
	call	GrQuickCosine
	mov_tr	cx, ax					;dxcx <- cosine
	mov	bx, ss:[polygonWidth]
	clr	ax
	call	GrMulWWFixed				;dxcx <- x
	movwwf	es:[di].PF_x, dxcx

	popdw	dxax
	call	GrQuickSine
	mov_tr	cx, ax					;dxcx <- sine
	mov	bx, ss:[polygonHeight]
	clr	ax
	call	GrMulWWFixed				;dxcx <- y
	movdw	es:[di].PF_y, dxcx

	;
	;  Increment the current angle and advance the Points pointer
	;
	addwwf	ss:[curAngle], ss:[incAngle], ax
	add	di, size PointWWFixed

	;
	;  Loop if more points to generate
	;
	dec	ss:[nPoints]
	jnz	pointLoop	
	
	;
	;  Set the spline's points to be the polyline we just computed
	;
	push	bp
	lea	bp, ss:[setPointParams]
	mov	ax, MSG_SPLINE_SET_POINTS
	call	ObjCallInstanceNoLock
	pop	bp

	mov	bx, ss:[blockHandle]
	call	MemFree

	mov	ax, MSG_SPLINE_CLOSE_CURVE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
SplineMakePolygon	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineMakeStar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Set the spline's points to a regular n-sided star

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= Segment of VisSplineClass.

		ss:[bp] - SplineMakeStarParams

RETURN:		SplineReturnType

DESTROYED:	nothing 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jon	16 sep 92	initial revision
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineMakeStar	method	dynamic	VisSplineClass, MSG_SPLINE_MAKE_STAR

	mov	bx, bp		; passed params

passedParams	local	nptr	push	bp
nPoints		local	word
curAngle	local	WWFixed
incAngle	local	WWFixed
setPointParams	local	SplineSetPointParams
blockHandle	local	hptr

	uses	ax, cx, dx, bp
	.enter

	mov	ax, ss:[bx].SMSP_starPoints
	mov	ss:[nPoints], ax

	cmp	ax, 2
	jae	enough
doneJMP:
	jmp	done
enough:
	cmp	ax, SPLINE_MAX_POINT/2
	ja	doneJMP

CheckHack	<size PointWWFixed eq 8>
	mov	cl, 4				; allocate 2
						; PointWWFixed structs
						; for each star point
	shl	ax, cl
	mov	cx, ALLOC_DYNAMIC_LOCK
	call	MemAlloc
	jc	doneJMP
	mov	es, ax

	mov	ss:[setPointParams].SSPP_points.segment, ax
	clr	ss:[setPointParams].SSPP_points.offset
	mov	ss:[setPointParams].SSPP_flags, SSPT_WWFIXED
	mov	ss:[blockHandle], bx

	;
	;  Calculate the incremental angle (= 360/# points = 180/# star points)
	;

	mov	dx, 180
	mov	bx, ss:[nPoints]
	clr	ax, cx
	call	GrUDivWWFixed
	movwwf	ss:[incAngle], dxcx

	shl	bx
	mov	ss:[setPointParams].SSPP_numPoints, bx

	;
	;  Set up our starting angle = 270, so that a point will be centered
	;  on top of the star
	;  
	mov	ss:[curAngle].WWF_int, 270
	clr	ss:[curAngle].WWF_frac

	clr	di				; es:di - destination

pointLoop:
	movwwf	dxax, ss:[curAngle]
	pushdw	dxax
	call	GrQuickCosine
	mov_tr	cx, ax					;dxcx <- cosine
	mov	bx, ss:[passedParams]
	mov	bx, ss:[bx].SMSP_outerRadius.P_x
	clr	ax
	call	GrMulWWFixed				;dxcx <- x
	movdw	es:[di].PF_x, dxcx

	popdw	dxax
	call	GrQuickSine
	mov_tr	cx, ax					;dxcx <- sine
	mov	bx, ss:[passedParams]
	mov	bx, ss:[bx].SMSP_outerRadius.P_y
	clr	ax
	call	GrMulWWFixed				;dxcx <- y
	movdw	es:[di].PF_y, dxcx

	;
	;  Now do the inner radius point
	;
	movwwf	dxax, ss:[curAngle]
	addwwf	dxax, ss:[incAngle]
	movwwf	ss:[curAngle], dxax
	add	di, size PointWWFixed

	pushdw	dxax
	call	GrQuickCosine
	mov_tr	cx, ax					;dxcx <- cosine
	mov	bx, ss:[passedParams]
	mov	bx, ss:[bx].SMSP_innerRadius.P_x
	clr	ax
	call	GrMulWWFixed				;dxcx <- x
	movdw	es:[di].PF_x, dxcx

	popdw	dxax
	call	GrQuickSine
	mov_tr	cx, ax					;dxcx <- sine
	mov	bx, ss:[passedParams]
	mov	bx, ss:[bx].SMSP_innerRadius.P_y
	clr	ax
	call	GrMulWWFixed				;dxcx <- y
	movdw	es:[di].PF_y, dxcx

	;
	;  Increment the current angle and advance the Points pointer
	;
	addwwf	ss:[curAngle], ss:[incAngle], ax
	add	di, size PointWWFixed

	;
	;  Loop if more points to generate
	;
	dec	ss:[nPoints]
LONG 	jnz 	pointLoop	
	
	;
	;  Set the spline's points to be the polyline we just computed
	;
	push	bp
	lea	bp, ss:[setPointParams]
	mov	ax, MSG_SPLINE_SET_POINTS
	call	ObjCallInstanceNoLock
	pop	bp

	mov	bx, ss:[blockHandle]
	call	MemFree

	mov	ax, MSG_SPLINE_CLOSE_CURVE
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
SplineMakeStar	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SplineGetEndpointInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Get endpoint info for Steve

PASS:		*ds:si	= VisSplineClass object
		ds:di	= VisSplineClass instance data
		es	= dgroup
		cl	- GetEndpointType

RETURN:		if error (not enough points)
			carry set
		else
			carry clear
			ax, bp - endpoint
			cx, dx - adjacent point
		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cdb	9/ 9/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SplineGetEndpointInfo	method	dynamic	VisSplineClass, 
					MSG_SPLINE_GET_ENDPOINT_INFO

	call	SplineMethodCommonReadOnly


	;
	; If no anchors, or first and last anchor are same, then bail.
	;

	call	SplineGotoFirstAnchor
LONG	jc	error
	mov_tr	bx, ax			; first anchor

	call	SplineGotoLastAnchor
	cmp	ax, bx
LONG	je	error

	cmp	cl, GET_FIRST
	je	getFirst

	;
	; Do the last anchor and its previous neighbor
	;

	LoadPointAsInt 	cx, dx, ds:[di].SPS_point
	mov	bx, -1
	jmp	getNeighbor

getFirst:

	;
	; Do the first point and its next anchor.  
	;

	call	SplineGotoFirstAnchor
	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	mov	bx, 1

getNeighbor:
	;
	; Go to the neighbor -- BX is direction to move (+1 or -1).
	; If there is no such point, then bail, as we won't be able to
	; determine a useful angle.
	;
	; If the neighbor is too close to the original point to give a
	; valid result, then keep moving
	;

	add	ax, bx
	call	ChunkArrayElementToPtr	; ds:di - next (previous) point
	jc	error
	call	SplinePointAtCXDXFar
	jc	getNeighbor

	mov_tr	ax, cx
	mov	bx, dx	
	LoadPointAsInt	cx, dx, ds:[di].SPS_point

	add	ax, es:[bp].VI_bounds.R_left
	add	cx, es:[bp].VI_bounds.R_left
	add	dx, es:[bp].VI_bounds.R_top
	add	bx, es:[bp].VI_bounds.R_top
	push	bx				; y-coord of endpoint
	call	SplineEndmCommon
	pop	bp
	clc
done:

	.leave
	ret
error:
	call	SplineEndmCommon
	stc
	jmp	done

SplineGetEndpointInfo	endm

