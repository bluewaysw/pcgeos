COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


	Copyright (c) GeoWorks 1989 -- All Rights Reserved


PROJECT:	PC GEOS
MODULE:
FILE:		graphicsSpline.asm


AUTHOR:		Steve Scholl, May 24, 1989


ROUTINES:
	Name			Description
	----			-----------
    EXT	GrDrawCurve		Draw a bezier curve
    EXT	GrDrawCurveTo		Draw a curve at the current position
    EXT	GrDrawSpline		Draw a spline (a collection of curves)
    EXT	GrDrawSplineTo		Draw a spline at the current position


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	5/24/89		Initial revision
	Jim	8/9/89		Moved most of the routines to kernel
		lib
	jim	10/10/89 	added graphics string support
	jim	1/91		moved it all back to kernel
	cdb	2/92		gutted


DESCRIPTION:
	Contains routines to draw splines.  Actual bezier curve
	calculation is done in the region code, since it's used by
	the Nimbus font driver as well.


	$Id: graphicsSpline.asm,v 1.1 97/04/05 01:13:33 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsSpline	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawCurve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SYNOPSIS:	Draw a bezier curve

CALLED BY:	GLOBAL

PASS:		ds:si - pointer to 4 points that make up the curve
		di - GState handle

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 4/92 	Initial version.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawCurve	proc	far
		mov	ss:[TPD_callVector].segment, (size Point) * 4
		mov	ss:[TPD_dataBX], handle GrDrawCurveReal
		mov	ss:[TPD_dataAX], offset GrDrawCurveReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawCurve	endp
CopyStackCodeXIP	ends

else

GrDrawCurve	proc	far
	FALL_THRU	GrDrawCurveReal
GrDrawCurve	endp

endif

GrDrawCurveReal	proc far
	call	EnterGraphics
	jc	gString

	; check for valid window before drawing

	call	TrivialRejectFar

	; Load the first point from the passed points, then call the 
	; common routine.

	call	LoadFirstPoint
	mov	cx, 3
	jmp	DrawSplineCommon

	; handle writing to a graphics string
gString:
	mov	cx, 4
	push	di
	mov 	di, ss:[bp].EG_ds	; restore ds
	call	SetFinalPenPosition
	mov	ds, di			; ds -> points
	pop	di
	mov	cx, 4 * size Point
	mov 	ax, (GSSC_FLUSH shl 8) or GR_DRAW_CURVE
	call 	GSStore 		; store the data
	jmp	ExitGraphicsGseg

GrDrawCurveReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawCurveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SYNOPSIS:	Draw a bezier curve starting at the current pen
		position. 


CALLED BY:	GLOBAL

PASS:		ds:si - pointer to next 3 points
		di - GState handle


RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 4/92 	Initial version.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawCurveTo	proc	far
		mov	ss:[TPD_callVector].segment, (size Point) * 3
		mov	ss:[TPD_dataBX], handle GrDrawCurveToReal
		mov	ss:[TPD_dataAX], offset GrDrawCurveToReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawCurveTo	endp
CopyStackCodeXIP	ends

else

GrDrawCurveTo	proc	far
	FALL_THRU	GrDrawCurveToReal
GrDrawCurveTo	endp

endif

GrDrawCurveToReal	proc far
	call	EnterGraphics
	jc	gString

	; check for valid window before drawing

	call	TrivialRejectFar	; won't return if can't draw
	call	GetDocPenPos		; get current pen position
	mov	cx, 3
	jmp	DrawSplineCommon

	; handle writing to a graphics string
gString:
	mov	cx, 3
	push	di
	mov 	di, ss:[bp].EG_ds	; restore ds
	call	SetFinalPenPosition
	mov	ds, di			; ds -> points
	pop	di
	mov	cx, 3 * size Point
	mov 	ax, (GSSC_FLUSH shl 8) or GR_DRAW_CURVE_TO
	call 	GSStore 			; store the data
	jmp	ExitGraphicsGseg

GrDrawCurveToReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRelCurveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a bezier curve from the current pen position

CALLED BY:	GLOBAL
PASS:		ds:si - pointer to next 3 points
		di - GState handle
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		same as GrDrawCurveTo, except we have to to some extra calcs

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	4/22/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ThreePoints	struct
    TP_p1	Point
    TP_p2	Point
    TP_p3	Point
ThreePoints	ends
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawRelCurveTo	proc	far
		mov	ss:[TPD_callVector].segment, size ThreePoints
		mov	ss:[TPD_dataBX], handle GrDrawRelCurveToReal
		mov	ss:[TPD_dataAX], offset GrDrawRelCurveToReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawRelCurveTo	endp
CopyStackCodeXIP	ends

else

GrDrawRelCurveTo	proc	far
	FALL_THRU	GrDrawRelCurveToReal
GrDrawRelCurveTo	endp

endif

GrDrawRelCurveToReal proc	far
	call	EnterGraphics
	jc	writeGString

	; check for valid window before drawing

	call	TrivialRejectFar	; won't return if can't draw
	call	GetDocPenPos		; get current pen position
	jc	done
	sub	sp, 3 * size Point	; alloc some space to figure rel coords
	mov	dx, sp			; ss:si -> buffer space
	push	ds
	xchg	si, dx
	mov	ss:[si].TP_p1.P_x, ax	; store current position
	mov	ss:[si].TP_p2.P_x, ax
	mov	ss:[si].TP_p3.P_x, ax
	mov	ss:[si].TP_p1.P_y, bx
	mov	ss:[si].TP_p2.P_y, bx
	mov	ss:[si].TP_p3.P_y, bx
	mov	ds, di			; setup passed ds
	xchg	si, dx
	xchg	dx, bx
	mov	cx, ds:[si].TP_p1.P_x	; get first x coord
	add	ss:[bx].TP_p1.P_x, cx
	mov	cx, ds:[si].TP_p1.P_y
	add	ss:[bx].TP_p1.P_y, cx
	mov	cx, ds:[si].TP_p2.P_x	; get second x coord
	add	ss:[bx].TP_p2.P_x, cx
	mov	cx, ds:[si].TP_p2.P_y
	add	ss:[bx].TP_p2.P_y, cx
	mov	cx, ds:[si].TP_p3.P_x	; get third x coord
	add	ss:[bx].TP_p3.P_x, cx
	mov	cx, ds:[si].TP_p3.P_y
	add	ss:[bx].TP_p3.P_y, cx
	xchg	bx, dx			; restore current y position
	pop	ds			; restore GState
	mov	di, ss			; load up segptr
	mov	si, dx			; di:si -> extra points
	mov	cx, 3
	call	DrawSplineLow
	add	sp, 3 * size Point	; clean up the stack
done:
	jmp	ExitGraphics


	; handle writing to a graphics string
writeGString:
	call	GetDocPenPos			; ax/bx = curpos
	push	ds				; save GState segment
	mov 	ds, ss:[bp].EG_ds		; restore ds
	add	ax, ds:[si].TP_p3.P_x		; calc new penpos
	add	bx, ds:[si].TP_p3.P_y
	mov	cx, ds				; save points segment
	pop	ds				; restore gstate segment
	call	SetDocPenPos
	mov	ds, cx				; ds -> point buffer
	mov	cx, 3 * size Point
	mov 	ax, (GSSC_FLUSH shl 8) or GR_DRAW_REL_CURVE_TO
	call 	GSStore 			; store the data
	jmp	ExitGraphicsGseg

GrDrawRelCurveToReal endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawSpline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


SYNOPSIS:	Draw a collection of cubic bezier curves.


CALLED BY:	GLOBAL

PASS:		ds:si	- source points list
		cx	- number of points in list
		di	- GState handle

		The number of points passed must be (3n+1), where
		n=1,2,3... 

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		srs	5/11/89		Initial version
		jim	8/9/89		Moved most of code to kernel library
		cdb	2/5/92		rewrote

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawSpline	proc	far
	;
	; Compute size of data at DS:SI. (Point is 4 bytes.)
	;
		push	cx
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx

		mov	ss:[TPD_dataBX], handle GrDrawSplineReal
		mov	ss:[TPD_dataAX], offset GrDrawSplineReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawSpline	endp
CopyStackCodeXIP	ends

else

GrDrawSpline	proc	far
	FALL_THRU	GrDrawSplineReal
GrDrawSpline	endp

endif

GrDrawSplineReal	proc	far

EC <	dec	cx	>
EC <	call	ECCheckSplineNumberOfPoints	>
EC <	inc	cx	>

	call	EnterGraphics
	jc	dsGString

	; check for valid window before drawing

	call	TrivialRejectFar

	; Load the first point from the passed points, then call the 
	; common routine.

	call	LoadFirstPoint
	dec	cx		; number of points -1
	jmp	DrawSplineCommon

	; handle writing to a graphics string
dsGString:
	push	di
	mov     di, ss:[bp].EG_ds	; restore ds 
	call	SetFinalPenPosition		; set pen pos for spline
	pop	di
	mov	al, GR_DRAW_SPLINE	; set up opcode
	mov     bx, cx                  ; set up word to write
	mov     cl, 2			; write word count
	mov	ch, GSSC_DONT_FLUSH
	call    GSStoreBytes            ; store header
	mov     cx, bx
	mov     ds, ss:[bp].EG_ds	; restore ds 
	shl     cx, 1                   ; 4 bytes per coordinate point
	shl     cx, 1
	mov     ax, (GSSC_FLUSH shl 8) or 0ffh  ; no code, flush buff
	call    GSStore                 ; store the data
	jmp	ExitGraphicsGseg

GrDrawSplineReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawSplineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a spline starting at the current pen position

CALLED BY:	GLOBAL

PASS:		ds:si - points to draw (must pass 3n points, where n =
		1, 2, 3...)

		cx - number of points passed
		di - GState handle
		
RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawSplineTo	proc	far
	;
	; Compute size of data at DS:SI.  (Point is 4 bytes)
	;		
		push	cx
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx

		mov	ss:[TPD_dataBX], handle GrDrawSplineToReal
		mov	ss:[TPD_dataAX], offset GrDrawSplineToReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawSplineTo	endp
CopyStackCodeXIP	ends

else

GrDrawSplineTo	proc	far
	FALL_THRU	GrDrawSplineToReal
GrDrawSplineTo	endp

endif

GrDrawSplineToReal	proc far

EC <	call	ECCheckSplineNumberOfPoints	>

	call	EnterGraphics
	jc	dsGString

	; Load the first point from the current pen position
	
	call	TrivialRejectFar
	call	GetDocPenPos		; get current pen position
	jmp	DrawSplineCommon

	; handle writing to a graphics string
	; OPCODE isn't available yet...

dsGString:
	push	di
	mov     di, ss:[bp].EG_ds	; restore ds 
	call	SetFinalPenPosition		; set pen pos for spline
	pop	di
	mov	al, GR_DRAW_SPLINE_TO	; set up opcode
	mov     bx, cx                  ; set up word to write
	mov     cl, 2
	mov	ch, GSSC_DONT_FLUSH
	call    GSStoreBytes            ; store header
	mov     cx, bx
	mov     ds, ss:[bp].EG_ds	; restore ds 
	shl     cx, 1                   ; 4 bytes per coordinate point
	shl     cx, 1
	mov     ax, (GSSC_FLUSH shl 8) or 0ffh  ; no code, flush buff
	call    GSStore                 ; store the data
	jmp	ExitGraphicsGseg

GrDrawSplineToReal	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSplineCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an arbitrary spline

CALLED BY:	GrDrawSpline, GrDrawCurve, GrDrawSplineTo,
		GrDrawCurveTo

PASS:		ax, bx - first point
		di:si - buffer of additional points
		cx - number of points at by ds:si
		ss:bp - EnterGraphics Frame
		ds - gstate
		es - window 

RETURN:		nothing  

DESTROYED:	ax,bx,cx,si,di,ds,es

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSplineCommon	proc far	
	call	DrawSplineLow
	jmp	ExitGraphics
DrawSplineCommon	endp	

DrawSplineLow	proc	near
gState		local	word	push	ds
window		local	word	push	es
separatorBlock	local	hptr

	.enter

	jcxz	done

	; store the final pen position

	call	SetFinalPenPosition

	; convert (ax,bx) to device coordinates

	call	GrTransCoordFar

	; Convert the rest of the points to device coordinates

	push	ax, bx
	mov	al, 0			; don't connect first and last
	push	bp
	mov	bp, di			; source segment
	mov	di, cx			; number of points
	call	CreateSeparatorFormat
	mov	ds, dx
	pop	bp
	mov	separatorBlock, bx
	pop	ax, bx
	jc	done			; if bogus block returned from 
					;  CreateSeparatorFormat, bail

	call	AllocateCurveDataStructures
	push	cx, dx			; temp data block handles

	clr	si			; ds:si - screen-coordinate
					; points. 
startLoop:

	; Convert all the passed curves to one big huge polyline

	call	CurveToPolyline
	sub	di, 3
	cmp	di, 3
	jge	startLoop

	; Add separator to end of polyline

	call	AddSeparator
	
	; Set up parameters for DrawPolylineMedFar

	mov	dx, es			
	mov	si, size CurvePolyline

	mov	ds, gState
	mov	cx, es:[CP_numPoints]
	
	mov	es, window
	mov	di, offset GS_lineAttr	; attributes offset
	clr	al 			; not connected
	push	bp
	mov	bp, 1			; only one disjoint polyline
	call	DrawPolylineMedFar
	pop	bp
	
	; Free the separator

	mov	bx, separatorBlock
	call	MemFree

	; free the data blocks and finish up

	pop	cx, dx			; temp data blocks
	call	FreeCurveDataStructures
done:
	.leave				; restore stack frame
	ret
DrawSplineLow	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocateCurveDataStructures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	allocate 2 blocks on the heap.  One is used
		for the conversion from bezier curve to polyline, the
		other is used to store the polyline points.

CALLED BY:	DrawSplineCommon

PASS:		nothing 

RETURN:		cx - handle of CurvePolyline segment
		     This segment contains the resultant polyline
			points

		dx - handle of RasterBezierPoints segment
			This block contains the source points in
			WBFixed format

		es - segment of CurvePolyline block

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AllocCurveDataStructsFar proc	far
	call	AllocateCurveDataStructures
	ret
AllocCurveDataStructsFar endp

AllocateCurveDataStructures	proc near	
	uses	ax, bx
	.enter
	mov	ax, RASTER_BEZIER_SEGMENT_SIZE
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAllocFar
	mov	dx, bx

	; Allocate and initialize the CurvePolyline segment

	mov	ax, CURVE_POLYLINE_SIZE
	mov	cx, ALLOC_DYNAMIC_NO_ERR_LOCK
	call	MemAllocFar
	mov	es, ax
	mov	es:[CP_size], 	CURVE_POLYLINE_SIZE
	mov	es:[CP_curPtr], size CurvePolyline
	mov	es:[CP_handle], bx
	clr	es:[CP_numPoints]
	mov	cx, bx

	.leave
	ret
AllocateCurveDataStructures	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FreeCurveDataStructures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free 'em

CALLED BY:	DrawSplineCommon

PASS:		cx, dx - handles to free

RETURN:		nothing 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 4/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FreeCurveDataStructsFar	proc	far
	call	FreeCurveDataStructures
	ret
FreeCurveDataStructsFar	endp

FreeCurveDataStructures	proc near	
	.enter
	mov	bx, cx
	call	MemFree
	mov	bx, dx
	call	MemFree
	.leave
	ret
FreeCurveDataStructures	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CurveToPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the bezier curve consisting of the
		passed point (ax,bx) and the next 3
		points (in memory) to a polyline.  

CALLED BY:	DrawSplineCommon

PASS:		
		ax, bx - first point
		ds:si - pointer to next 3 points
		cx - handle of CurvePolyline block
		dx - handle of "stack" block for RasterBezier 

RETURN:		ds:si - points to first location AFTER the 3 points
		passed. 

		ax, bx - last point

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Set up the IntRegionBezier data structure and calling
	RasterBezier to convert the curve to a polyline.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/ 3/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CurveToPolylineFar	proc	far
	call	CurveToPolyline
	ret
CurveToPolylineFar	endp

CurveToPolyline	proc near	
	uses	cx,dx,bp,di
	.enter

	; store points in the RasterBezier block, converting to WBFixed
	; as we go.

	push	bx, ax		; first point

	mov	bx, dx
	call	MemDerefES
	mov	di, RASTER_BEZIER_INITIAL_POINTER

	clr	dl		; use DL as a zero register

	; X-coordinate
	mov	al, dl
	stosb
	pop	ax
	stosw

	; Y-coordinate 

	mov	al, dl
	stosb
	pop	ax
	stosw

	; store the next 3 points

	mov	al, dl

REPT	6
	stosb
	movsw
 ENDM

	; push stuff to be returned to caller

	push	ds:[si-4]		; last x-coord
	push	ds:[si-2]		; last y-coord
	push	ds, si

	; Now, convert the curve to a polyline

	segmov	ds, es, si
	mov	si, RASTER_BEZIER_INITIAL_POINTER

	; polyline block
	
	mov	bx, cx
	call	MemDerefES

	mov	bp, offset  CurveToPolylineCB
	call	RasterBezierFar

	; return stuff to caller

	pop	ds, si
	pop	bx
	pop	ax

	.leave
	ret
CurveToPolyline	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetFinalPenPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the pen position that will result from the
		completion of the given spline procedure

CALLED BY:

PASS:		di:si - buffer of points
		cx - number of points in buffer
		ds - gstate 

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	
	Get the last point in the buffer and store it in the gstate

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetFinalPenPosition	proc near
	uses	es,si,ax,cx, bx
	.enter
	mov	es, di		; source points segment

	; Convert # points to # bytes

	dec	cx

	CheckHack <size Point eq 4>

	shl	cx, 1
	shl	cx, 1

	add	si, cx

	mov	ax, es:[si].P_x
	mov	bx, es:[si].P_y
	call	SetDocPenPos		; set new pen position

	.leave
	ret
SetFinalPenPosition	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadFirstPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the first point in the passed buffer into AX, BX

CALLED BY:	GrDrawCurve, GrDrawSpline

PASS:		di:si - buffer of points

RETURN:		ax, bx, - first point

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadFirstPoint	proc near
	uses	ds
	.enter

	mov	ds, di
	lodsw
	mov	bx, ax
	lodsw
	xchg	ax, bx

	.leave
	ret
LoadFirstPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddSeparator
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a separator token to the end of the passed set of
		points. 

CALLED BY:

PASS:		cx - handle of CurvePolyline block

RETURN:		es - segment of CurvePolyline block

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	3/16/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AddSeparator	proc near
	uses	ax,bx,di
	.enter

	mov	bx, cx
	call	MemDerefES

	mov	di, es:[CP_curPtr]

EC <	push	di
EC <	add	di, size Point				>
EC <	cmp	di, es:[CP_size]			>
EC <	ERROR_G	GRAPHICS_SPLINE_BLOCK_WRONG_SIZE	>
EC <	pop	di					>

	mov	ax, SEPARATOR
	stosw
	stosw

	.leave
	ret
AddSeparator	endp



if ERROR_CHECK


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECCheckSplineNumberOfPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure that the number of points is divisible
		by 3.

CALLED BY:	GrDrawSpline, GrDrawSplineTo

PASS:		cx = 3n (hopefully)

RETURN:		nothing 

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	2/28/92   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECCheckSplineNumberOfPoints	proc near
	uses	ax,cx,dx
	.enter
	pushf

	clr	dx
	mov_tr	ax, cx
	mov	cx, 3
	div	cx
	tst	dx
	ERROR_NZ	GRAPHICS_SPLINE_ILLEGAL_NUMBER_OF_POINTS
	popf

	.leave
	ret
ECCheckSplineNumberOfPoints	endp

endif




GraphicsSpline	ends

