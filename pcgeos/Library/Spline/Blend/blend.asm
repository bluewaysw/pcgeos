COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		blend
FILE:		blend.asm

AUTHOR:		Chris Boyke

METHODS:
	Name			Description
	----			-----------

FUNCTIONS:

Scope	Name			Description
-----	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91	Initial version.

DESCRIPTION:
	

	$Id: blend.asm,v 1.1 97/04/07 11:09:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BlendCode	segment

	SetGeosConvention


COMMENT @----------------------------------------------------------------------

C FUNCTION:	Blend

C DECLARATION:	extern void _pascal Blend(BlendParams *params);

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Joon	11/17/93    	Initial version

----------------------------------------------------------------------------@
BLEND	proc	far	params:fptr.BlendParams
		uses	ds,si, es,di
		.enter
	;
	; Create space on the stack so we can copy the BlendParams
	;
		mov	cx, size BlendParams
		sub	sp, cx
	;
	; Copy the BlendParams onto the stack
	;
		segmov	es, ss
		mov	di, sp
		lds	si, ss:[params]
		rep	movsb
		mov	di, sp
	;
	; Call Blend with ss:bp pointing to the BlendParams
	;
		push	bp
		mov	bp, di
		call	Blend
		pop	bp
	;
	; Remove space allocated on the stack for BlendParams
	;
		add	sp, size BlendParams

		.leave
		ret
BLEND	endp

	SetDefaultConvention



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Blend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the nasty on two splines

CALLED BY:	GLOBAL

PASS:		SS:BP - BlendParams

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Blend	proc	far
	uses	ax,bx,cx,dx,di,si,bp,ds,es
	.enter
	call	BlendCreateMemBlocks
	call	BlendCopySourceSplines
	call	BlendGetLengths
	call	BlendInsertPointsInCopies
	call	BlendInsertControls
	call	BlendCalcDifferences
	call	BlendBlend
	call	BlendCleanUp
	.leave
	ret
Blend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendCreateMemBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the (2) mem blocks that will be used to store
		data during blend operations.

CALLED BY:	Blend

PASS:		ss:bp - blend params

RETURN:		DS - data segment of BlendData structure

DESTROYED:	ax, bx, cx, dx, si, di, bp, es

PSEUDO CODE/STRATEGY:	
	Allocate a small block of data to hold the parameters and
	other variables.

	stick the "params" into the data block (freeing up BP)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendCreateMemBlocks	proc near
	.enter


	;
	; Create a temporary object block, in the same file as the
	; other 2 splines.  The temporary object block is locked the
	; entire time.
	;

	mov	ax, LMEM_TYPE_OBJ_BLOCK
	mov	bx, ss:[bp].BP_vmFileHandle
	mov	cx, size BlendData
	call	VMAllocLMem			; ax VM block handle
	call	VMVMBlockToMemBlock
	push	ax				; mem handle

	;
	; Set the block to be run by this thread
	;

	clr	bx
	mov	ax, TGIT_THREAD_HANDLE
	call	ThreadGetInfo			; ax - thread handle

	pop	bx
	call	MemModifyOtherInfo		; set thread handle	

	;
	; Lock it down
	;

	call	ObjLockObjBlock
	mov	es, ax
	mov	di, offset BD_params	

	segmov	ds, ss
	mov	si, bp

	CheckHack <(size BlendParams AND 1) eq 0>
	mov	cx, (size BlendParams)/2
	rep	movsw

	segmov	ds, es

	; init the array that will be used to hold intermediate point values. 

	clr	al
	mov	bx, size PointBlendStruct
	clr	cx, si
	call	ChunkArrayCreate
	mov	ds:[BD_blendPoints], si

	; now, create the 2nd lmem block

	mov	bx, ds:[BD_params].BP_vmFileHandle
	mov	ax, LMEM_TYPE_GENERAL
	clr	cx
	call	VMAllocLMem
	call	VMLock
	mov	ds:[BD_pointsBlock], bp

	; init length  arrays

	mov	bp, offset BD_spline1
	call	BlendInitArrays

	mov	bp, offset BD_spline2
	call	BlendInitArrays

	.leave
	ret
BlendCreateMemBlocks	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendInitArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the arrays used for blend stuff

CALLED BY:

PASS:		ds:bp - current SplineInfo struct

RETURN:		nothing 

DESTROYED:	ax, bx, cx, si, es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendInitArrays	proc near	
	.enter
	segmov	es, ds
	mov	bx, es:[BD_pointsBlock]
	call	MemDerefDS

	; Init length array
	clr	al
	mov	bx, size LengthStruct
	clr	cx
	mov	si, cx
	call	ChunkArrayCreate
	mov	es:[bp].SI_lengthArray, si
	segmov	ds, es
	.leave
	ret
BlendInitArrays	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendCopySourceSplines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make copies of the source splines so I can do with
		them as I please.

CALLED BY:	Blend

PASS:		ds - data segment of BlendData block

RETURN:		

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendCopySourceSplines	proc near
	.enter

EC <	call	ECBlendDataBlocks		>

	;
	; Copy the first spline into this block
	;

	movdw	bxsi, ds:[BD_params].BP_firstOD
	mov	cx, ds:[BlendHandle]
	mov	dx, ds:[BD_pointsBlock]
	mov	ax, MSG_SPLINE_COPY
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	push	cx, di
	call	ObjMessage
	mov	ds:[BD_spline1].SI_chunkHandle, cx
	pop	cx, di

	;
	; Copy the second spline
	;

	movdw	bxsi, ds:[BD_params].BP_secondOD
	call	ObjMessage
	mov	ds:[BD_spline2].SI_chunkHandle, cx

EC <	call	ECBlendDataBlocks		>

	.leave
	ret
BlendCopySourceSplines	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendGetLengths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the splines to turn over their most intimate
		information to us.

CALLED BY:	Blend

PASS:		ds - segment of BlendData block

RETURN:		

DESTROYED:	bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendGetLengths	proc near
	.enter

EC <	call	ECBlendDataBlocks		> 

	mov	bp, offset BD_spline1
	call	BlendGetLength

	mov	bp, offset BD_spline2
	call	BlendGetLength

	.leave
	ret
BlendGetLengths	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendGetLength
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ask the spline to give us an array of all its length
		information. 

CALLED BY:	BlendGetLengths

PASS:		bp - offset in BlendData struct to the current spline's
		SplineInfo struct.

RETURN:		nothing 

DESTROYED:	ax, cx, dx, si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendGetLength	proc near
	.enter

EC <	call	ECBlendDataBlocks		> 

	mov	ax, MSG_SPLINE_GET_ALL_LENGTHS
	mov	cx, ds:[BD_pointsBlock]
	mov	dx, ds:[bp].SI_lengthArray
	mov	si, ds:[bp].SI_chunkHandle
	call	ObjCallInstanceNoLock

	; keep track of initial size of array
	segmov	es, ds
	mov	bx, ds:[BD_pointsBlock]
	call	MemDerefDS
	mov	si, es:[bp].SI_lengthArray
	call	ChunkArrayGetCount
	mov	es:[bp].SI_sizeLengthArray, cx

	; normalize all lengths so they add up to 1
	mov	bx, cs
	mov	ax, 0ffffh
	mov	di, offset BlendNormalizeLengthCB
	call	ChunkArrayEnum
	segmov	ds, es

EC <	call	ECBlendDataBlocks		> 

	.leave
	ret
BlendGetLength	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendNormalizeLengthCB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalize the "length" field of each element in the
		length array so that all the lengths (when considered
		as fractions) add up to 1.

CALLED BY:

PASS:		ds:di - current array element
		ax - Percent field of previous element in array

RETURN:		ax - percent field of current element

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Don't forget, array is stored in high point-num to low
	point-num order

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/18/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendNormalizeLengthCB	proc far
	.enter

	mov	bx, ax			; percent field of NEXT point
	mov	ax, ds:[di].LS_percent	; current percent
	sub	bx, ax			
	mov	ds:[di].LS_length, bx	; normalized length
	.leave
	ret
BlendNormalizeLengthCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendInsertPointsInCopies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go thru the 2 copies, adding points as necessary to
		make them have identical point/location values.

CALLED BY:	BlendFixupCopies

PASS:		ds - segment of BlendData block

RETURN:		ds - might possibly change

DESTROYED:	everythang (except ds, of course)

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendInsertPointsInCopies	proc near	
	.enter

EC <	call	ECBlendDataBlocks		> 

	clr	ds:[BD_spline1].SI_curElt
	clr	ds:[BD_spline2].SI_curElt

	segmov	es, ds
	mov	bx, es:[BD_pointsBlock]
	call	MemDerefDS

startLoop:
	mov	ax, es:[BD_spline1].SI_curElt
	mov	si, es:[BD_spline1].SI_lengthArray
	call	ChunkArrayElementToPtr
EC <	ERROR_C	ILLEGAL_ELEMENT_NUMBER	>
	mov	cx, ds:[di].LS_percent
	
	mov	ax, es:[BD_spline2].SI_curElt
	mov	si, es:[BD_spline2].SI_lengthArray
	call	ChunkArrayElementToPtr 
EC <	ERROR_C	ILLEGAL_ELEMENT_NUMBER	>

	; compare FIRST PERCENT to SECOND PERCENT
	cmp	cx, ds:[di].LS_percent
	jb	addFirst
	ja	addSecond

	; They're equal, so increment counters on both sides, check to see if
	; done.
	mov	cx, 2		; (actually, mov cl,2 and clr ch)
	mov	bp, offset BD_spline1
	call	BlendIncCounter
	mov	bp, offset BD_spline2
	call	BlendIncCounter
	jcxz	done
	jmp	startLoop

addFirst:
	mov	cx, offset BD_spline1
	mov	dx, offset BD_spline2
	jmp	insert

addSecond:
	mov	cx, offset BD_spline2
	mov	dx, offset BD_spline1
insert:
	call	BlendInsertPoint
	jmp	startLoop
done:
	segmov	ds, es
	.leave
	ret
BlendInsertPointsInCopies	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendIncCounter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the current element of the length array,
		checking for an end-of-array condition

CALLED BY:

PASS:		es:bp - SplineInfo struct
		cl - counter to decrement if at end of array

RETURN:		cl - decremented if at end of array

DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendIncCounter	proc near	
	.enter
	mov	si, es:[bp].SI_lengthArray
	mov	ax, es:[bp].SI_curElt
	inc	ax
	cmp	ax, es:[bp].SI_sizeLengthArray
	jl	moreToGo
	dec	cl
	jmp	done
moreToGo:
	mov	es:[bp].SI_curElt, ax
done:
	.leave
	ret
BlendIncCounter	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendInsertPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a point into one of the splines, using data
		from the OTHER one to determine where.  Update the
		current percent amount in the array, and increment the
		OTHER pointer

CALLED BY:

PASS:		es - segment of blend data block
		ds - segment of lengths array
		cx - offset into data block to SplineInfo structure of
		spline in which to insert point
		dx - offset into data block to SplineInfo structure of
		OTHER point

RETURN:		ds & es fixed up if necessary.

DESTROYED:	ax,bx,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:	
	ratio = Divide length OTHER CURVE / length THIS CURVE
	increment counter on OTHER curve

	subdivide param = (1-ratio)
	length (THIS curve) = length THIS CURVE * subdivide
		param.

	subdivide first curve at param


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendInsertPoint	proc near
	.enter

	; Get LENGTH OTHER curve, and increment counter of OTHER array

	mov	bp, dx
	mov	ax, es:[bp].SI_curElt
	mov	si, es:[bp].SI_lengthArray
	call	ChunkArrayElementToPtr
EC <	ERROR_C	ILLEGAL_ELEMENT_NUMBER	> 
	push	di

	push	cx
	call	BlendIncCounter
	pop	cx

	; get LENGTH THIS curve
	mov	bp, cx
	mov	ax, es:[bp].SI_curElt
	mov	si, es:[bp].SI_lengthArray
	call	ChunkArrayElementToPtr
EC <	ERROR_C	ILLEGAL_ELEMENT_NUMBER	> 

	; divide length OTHER / length THIS

	pop	si		; length of THIS curve
	Divide	ds:[si].LS_length, ds:[di].LS_length
	ECMakeSureZero	dx
	neg	ax			; (same as 1-x)
	mov	bx, ax			; subdivide PARAM
	
	; Multiply length of current curve by subdivide param
	mov	ax, ds:[di].LS_length
	mul	bx
	mov	ds:[di].LS_length, dx	; store high word (ie, divide
					; by 65536).

	; Now, use this ratio to subdivide the curve
	mov	dx, bx			; subdivide param
	mov	cx, ds:[di].LS_pointNum	; point # to subdivide at
	mov	ax, MSG_SPLINE_SUBDIVIDE_CURVE
	mov	si, es:[bp].SI_chunkHandle
	push	ds:[LMBH_handle]	; points block handle
	segmov	ds, es			; blend data block
	call	ObjCallInstanceNoLock
	segmov	es, ds			; blend data block
	pop	bx
	call	MemDerefDS		; points block
	.leave
	ret
BlendInsertPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendBlend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the actual blend, spitting out spline objects
		along the way.

CALLED BY:

PASS:		ds - segment of BlendData block

RETURN:		nothing 

DESTROYED:	evrythun

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/ 9/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendBlend	proc near
	.enter
EC <	call	ECBlendDataBlocks		> 

	clr	ax
startLoop:
	push	ax
	call	BlendCreateNextSpline
	pop	ax
	inc	ax
	cmp	ax, ds:[BD_params].BP_numSteps
	jl	startLoop
	.leave
	ret
BlendBlend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendCalcDifferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the differences between the 2 splines,
		including vis bounds, color, and point coordinates.

CALLED BY:	Blend

PASS:		ds - data segment of blend data

RETURN:		nothing 

DESTROYED:	everything

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/17/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendCalcDifferences	proc near
	.enter

EC <	call	ECBlendDataBlocks		> 

	call	BlendCalcIncrement

	call	BlendSetupBlendArrays

	; now, calc vis differences
	mov	ax, MSG_VIS_GET_BOUNDS
	mov	si, ds:[BD_spline1].SI_chunkHandle
	call	ObjCallInstanceNoLock 
	push	bp		; initial y-value
	push	ax		; inital x-value

	; Now get FINAL vis values in ax, bp

	mov	ax, MSG_VIS_GET_BOUNDS
	mov	si, ds:[BD_spline2].SI_chunkHandle
	call	ObjCallInstanceNoLock
 

	pop	bx			; initial x-value
	mov	di, offset BD_visIncs.PBS_x
	call	BlendSetupBlendStruct

	mov	ax, bp			; final y-value
	pop	bx			; initial y-value
	add	di, offset PBS_y
	call	BlendSetupBlendStruct

	; Line color

	mov	bp, offset BD_lineColor
	mov	ax, MSG_SPLINE_GET_LINE_COLOR
	call	BlendSetupColorBlend

	; area color

	mov	bp, offset BD_areaColor
	mov	ax, MSG_SPLINE_GET_AREA_COLOR
	call	BlendSetupColorBlend

	; line width

	mov	ax, MSG_SPLINE_GET_LINE_WIDTH
	mov	si, ds:[BD_spline1].SI_chunkHandle
	call	ObjCallInstanceNoLock
	mov	bx, dx			; just take int part

	mov	si, ds:[BD_spline2].SI_chunkHandle
	call	ObjCallInstanceNoLock
	mov	ax, dx

	mov	di, offset BD_lineWidth
	call	BlendSetupBlendStruct
	
	.leave
	ret
BlendCalcDifferences	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendCalcIncrement
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the increment based on the first percent,
		last percent, and number of steps.

CALLED BY:	BlendCalcDifferences

PASS:		ds - Blend data block

RETURN:		nothing 

DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

	INCREMENT = (LAST - FIRST) / (NUMSTEPS - 1)	

	If NumSteps was initially one, then increment is zero, and
	the blend will be based on the FIRST PERCENT.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	11/ 5/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendCalcIncrement	proc near
	.enter
EC <	call	ECBlendDataBlocks		> 
	mov	ax, ds:[BD_params].BP_lastPct
	sub	ax, ds:[BD_params].BP_firstPct
	mov	cx, ds:[BD_params].BP_numSteps
	dec	cx
	jcxz	noIncrement
	clr	dx
	div	cx			; (last-first)/(numsteps-1)
	mov	ds:[BD_inc], ax
done:
	.leave
	ret

noIncrement:
	mov	ds:[BD_inc], 0
	jmp	done
BlendCalcIncrement	endp

 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendSetupColorBlend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup a "color" blend structure

CALLED BY:

PASS:		ax - message to send to splines to get color values
		bp - offset into BlendData to location of
		ColorBlendStruct .

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendSetupColorBlend	proc near
	.enter
	mov	si, ds:[BD_spline1].SI_chunkHandle
	call	ObjCallInstanceNoLock
	push	dx			; initial green (dl), blue (dh)
	push	cx			; initial red (cl)
	
	mov	si, ds:[BD_spline2].SI_chunkHandle
	call	ObjCallInstanceNoLock
				;(final red in cl, green,blue in dl, dh

	; deal with Red first:
	mov	al, cl			; final red
	pop	bx			; initial red
	clr	ah
	mov	bh, ah

	mov	di, bp
	CheckHack	<offset CBS_red eq 0>
	call	BlendSetupBlendStruct

	; green:
	mov	al, dl			; final green
	pop	cx			; initial green (cl)
	mov	bx, cx
	clr	ah
	mov	bh, ah

	add	di, size BlendStruct
	call	BlendSetupBlendStruct

	; blue
	mov	al, dh			; final blue
	mov	bl, ch			; initial  blue
	clr	ah
	mov	bh, ah

	add	di, size  BlendStruct
	call	BlendSetupBlendStruct

	.leave
	ret
BlendSetupColorBlend	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendSetupBlendStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		ds:di - BlendStruct to fill in
		bx - initial value
		ax - final value
		ds - segment of BlendData block   

RETURN:		nothing 

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendSetupBlendStruct	proc	near
	uses	cx, dx
	.enter
	; store the "first" value in BS_current

	mov	ds:[di].BS_current.WWF_int, bx

	; calc and store distance

	sub	ax, bx
	push	ax

	; calc first value

	mov	dx, ax
	clr	cx
	mov	bx, cx
	mov	ax, ds:[BD_params].BP_firstPct
	call	GrMulWWFixed
	mov	ds:[di].BS_current.WWF_frac,    cx
	add	ds:[di].BS_current.WWF_int, 	dx

	; calc incremental values
	
	pop	dx		; distance
	clr	cx
	mov	bx, cx
	mov	ax, ds:[BD_inc]
	call	GrMulWWFixed
	mov	ds:[di].BS_inc.WWF_frac, cx
	mov	ds:[di].BS_inc.WWF_int, dx
	

	.leave
	ret
BlendSetupBlendStruct	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendSetupBlendArrays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the array and other data structures that will
		be used to store data during blending

CALLED BY:

PASS:		ds - data segment of blend data

RETURN:		

DESTROYED:	everything except ds

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendSetupBlendArrays	proc near
	class	VisSplineClass 
	.enter

EC <	call	ECBlendDataBlocks		> 

	mov	bp, offset BD_spline1
	call	BlendGetPoints
	mov	bp, offset BD_spline2
	call	BlendGetPoints

	; Now, go thru both points arrays, setting up the array that will be
	; used to calculate intermediate points

	clr	ax
startLoop:
	mov	bp, offset BD_spline1
	call	BlendGetCurrentPoint
	jc	done
	push	ax				; point number
	push	dx			; y-coord (initial)
	push	cx			; x-coord (initial)

	; Get FINAL x,y values in cx, dx:
	mov	bp, offset BD_spline2
	call	BlendGetCurrentPoint

	; compute blend structure

	mov	si, ds:[BD_blendPoints]
	call	ChunkArrayAppend
	
	pop	bx			; initial x-coord
	mov	ax, cx			; final x-coord
	call	BlendSetupBlendStruct

	pop	bx			; initial y-coord
	mov	ax, dx			; final y-coord
	add	di, offset PBS_y
	call	BlendSetupBlendStruct
	
	pop	ax
	inc	ax
	jmp	startLoop
done:

EC <	call	ECBlendDataBlocks		> 

	.leave
	ret
BlendSetupBlendArrays	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendGetCurrentPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current spline point

CALLED BY:

PASS:		ax - point number
		ds:bp - SplineInfo structure

RETURN:		CX, DX - point's coordinates, or 
		CARRY if point not found

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendGetCurrentPoint	proc near
	.enter
	push	ds
	mov	bx, ds:[bp].SI_points.handle
	mov	si, ds:[bp].SI_points.offset
	call	MemDerefDS
	call	ChunkArrayElementToPtr 
	jc	done

	LoadPointAsInt	cx, dx, ds:[di].SPS_point
	clc
done:
	pop	ds
	.leave
	ret
BlendGetCurrentPoint	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendGetPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Go into the spline and grab its points array without
		it knowing about it.

CALLED BY:	BlendSetupBlendArrays

PASS:		ds:bp - offset of SplineInfo data structure

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	
	Make sure that the points block is the blend's points block. 


KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendGetPoints	proc	near
	uses	si, ax
	class	VisSplineClass 
	.enter

	mov	si, ds:[bp].SI_chunkHandle
	mov	si, ds:[si]
	add	si, ds:[si].VisSpline_offset
	MemMov	ds:[bp].SI_points.offset, ds:[si].VSI_points,ax
	MemMov	ds:[bp].SI_points.handle, ds:[si].VSI_lmemBlock,ax

EC <	cmp	ax, ds:[BD_pointsBlock]	>
EC <	ERROR_NE	WRONG_MEM_HANDLE >

	.leave
	ret
BlendGetPoints	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendCreateNextSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the next spline.

CALLED BY:

PASS:		ds - segment of BlendData block
		
RETURN:		nothing 

DESTROYED:	everything

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendCreateNextSpline	proc near	
	.enter

EC <	call	ECBlendDataBlocks		> 

	call	BlendUpdatePointsForNextSpline
	call	BlendUpdateAttrsForNextSpline
	call	BlendUpdateVisBoundsForNextSpline


	; Send object off to be duplicated by caller
	mov	ax, ds:[BD_params].BP_outputMessage
	mov	bx, ds:[BD_params].BP_outputOD.handle
	mov	si, ds:[BD_params].BP_outputOD.offset
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	cx, ds:[BlendHandle]
	mov	dx, ds:[BD_spline1].SI_chunkHandle
	call	ObjMessage

EC <	call	ECBlendDataBlocks		> 

	.leave
	ret
BlendCreateNextSpline	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendUpdatePointsForNextSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the points array for the next spline to be
		output. 

CALLED BY:

PASS:		ds - segment of BlendData block 

RETURN:		

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendUpdatePointsForNextSpline	proc near
	.enter
EC <	call	ECBlendDataBlocks		> 

	clr	ax			; point number
	; Update the  points array
startLoop:
	mov	si, ds:[BD_blendPoints]
	call	ChunkArrayElementToPtr
	jc	done
	push	ax			; point number
	push	di			; pointer to PBS_current

	; get current x- and y- coordinate. since they won't all fit in regs,
	; push the x-coord and put y-coord in dx.cx

	; now go to the spline's current point (number in ax)
	segmov	es, ds
	mov	bx, ds:[BD_spline1].SI_points.handle
	mov	si, ds:[BD_spline1].SI_points.offset
	call	MemDerefDS
	call	ChunkArrayElementToPtr
EC <	ERROR_C	ILLEGAL_ELEMENT_NUMBER	> 
	pop	si
	movdw	dxcx, es:[si].PBS_x.BS_current
	movdw	bxax, es:[si].PBS_y.BS_current
	StorePointWWFixed
	segmov	ds, es
	mov	di, si

	; update current for next time:
	call	UpdatePointBlendStruct
	pop	ax
	inc	ax
	jmp	startLoop	
done:
	.leave
	ret
BlendUpdatePointsForNextSpline	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendUpdateAttrsForNextSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update attributes for the next spline

CALLED BY:

PASS:		ds - segment of BlendData block 

RETURN:		

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendUpdateAttrsForNextSpline	proc near
	.enter

	; update line color
	mov	di, offset BD_lineColor
	call	UpdateColorValues

	mov	ax, MSG_SPLINE_SET_LINE_COLOR
	mov	si, ds:[BD_spline1].SI_chunkHandle
	call	ObjCallInstanceNoLock

	; area color
	mov	di, offset BD_areaColor
	call	UpdateColorValues

	mov	ax, MSG_SPLINE_SET_AREA_COLOR
	call	ObjCallInstanceNoLock

	; line width
	mov	di, offset BD_lineWidth
	mov	dx, ds:[di].BS_current.WWF_int
	call	UpdateBlendStruct
	mov	ax, MSG_SPLINE_SET_LINE_WIDTH
	clr	cx
	call	ObjCallInstanceNoLock

EC <	call	ECBlendDataBlocks		> 

	.leave
	ret
BlendUpdateAttrsForNextSpline	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateColorValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve and update the next set of color values.

CALLED BY:	

PASS:		ds:di - address of ColorBlendStruct

RETURN:		(cx, dx) - ColorStruct structure to pass to object

DESTROYED:	di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateColorValues	proc near
	.enter

	CheckHack	<offset CBS_red eq 0>	
	CheckHack	<(offset CBS_green - offset CBS_red) eq \
				(size BlendStruct)
	CheckHack	<(offset CBS_blue - offset CBS_green) eq \
				(size BlendStruct)

	mov	cx, ds:[di].BS_current.WWF_int
	call	UpdateBlendStruct
	ECMakeSureZero	ch

	add	di, size BlendStruct
	mov	dx, ds:[di].BS_current.WWF_int
	call	UpdateBlendStruct
	ECMakeSureZero	dh

	add	di, size BlendStruct
	mov	ax,  ds:[di].BS_current.WWF_int
	call	UpdateBlendStruct
	ECMakeSureZero	ah
	
	mov	dh, al
	mov	ch, CF_RGB
	.leave
	ret
UpdateColorValues	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendUpdateVisBoundsForNextSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:

CALLED BY:

PASS:		ds - segment of BlendData block 

RETURN:		

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendUpdateVisBoundsForNextSpline	proc near
	.enter
	mov	di, offset BD_visIncs
	movdw	bxax, ds:[di].PBS_x.BS_current
	movdw	dxcx, ds:[di].PBS_y.BS_current
	call	UpdatePointBlendStruct
	RoundDW	bxax
	RoundDW	dxcx
	mov	cx, bx
	mov	si, ds:[BD_spline1].SI_chunkHandle
	mov	ax, MSG_VIS_SET_POSITION
	call	ObjCallInstanceNoLock

	; Tell spline to figure out its best size

	mov	ax, MSG_VIS_RECALC_SIZE
	call	ObjCallInstanceNoLock
	.leave
	ret
BlendUpdateVisBoundsForNextSpline	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdatePointBlendStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the "inc" field to the "current" field for the
		current PointBlendStruct

CALLED BY:

PASS:		ds:di - PointBlendStruct to update

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/18/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdatePointBlendStruct	proc	near
	uses	ax
	.enter
	adddw	ds:[di].PBS_x.BS_current, ds:[di].PBS_x.BS_inc, ax
	adddw	ds:[di].PBS_y.BS_current, ds:[di].PBS_y.BS_inc, ax
	.leave
	ret
UpdatePointBlendStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateBlendStruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update a blend structure:  Add the "inc" field to the
		"current" field.

CALLED BY:

PASS:		ds:di - blend struct to update

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateBlendStruct	proc	near
	uses	ax
	.enter
	adddw	ds:[di].BS_current, ds:[di].BS_inc, ax
	.leave
	ret
UpdateBlendStruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendInsertControls
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert control points for every spline point along
		both splines.

CALLED BY:

PASS:		ds - segment of BlendData block 

RETURN:		nothing 

DESTROYED:	ax, si

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendInsertControls	proc near
	.enter
	mov	si, ds:[BD_spline1].SI_chunkHandle
	mov	ax, MSG_SPLINE_INSERT_ALL_CONTROLS
	push	ax
	call	ObjCallInstanceNoLock
	pop	ax

	mov	si, ds:[BD_spline2].SI_chunkHandle
	call	ObjCallInstanceNoLock

	.leave
	ret
BlendInsertControls	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendCleanUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the two memory blocks

CALLED BY:

PASS:		ds - data segment of blend data block		

RETURN:		

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/10/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlendCleanUp	proc near
	.enter

	mov	bx, ds:[BD_pointsBlock]
	call	MemFree
	mov	bx, ds:[BlendHandle]
	call	MemFree
	.leave
	ret
BlendCleanUp	endp


if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlendECDataBlocks
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate the mem blocks

CALLED BY:	various

PASS:		ds - blend data block

RETURN:		nothing 

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	10/28/91	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECBlendDataBlocks	proc near 	uses	es, bx, si
	.enter
	pushf
	call	ECLMemValidateHeap
	mov	si, ds:[BD_blendPoints]
	call	ECCheckChunkArray

	segmov	es, ds
	mov	bx, es:[BD_pointsBlock]
	call	MemDerefDS
	call	ECLMemValidateHeap

	segmov	ds, es
	popf
	.leave
	ret
ECBlendDataBlocks	endp

endif


BlendCode	ends
