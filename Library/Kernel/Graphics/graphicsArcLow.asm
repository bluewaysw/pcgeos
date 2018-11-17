COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 
	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphics		
FILE:		graphicsArc.asm

AUTHOR:		Ted H. Kim, 7/6/89

ROUTINES:
	Name			 Description
	----			 -----------
EXT	DrawArcEllipseLow	 Draw an arc or an ellipse
EXT	FillArcEllipseLow	 Fill an arc or an ellipse

	SetupEllipseLow		 Setup prior to CalcEllipse for ellipses
	SetupEllipseLineLow	 Same as above, but uses line, not area, attrs	
	SetupArcLow		 Setup prior to for CalcEllipse for bounded arcs
	SetupArc3PointLow	 Setup prior to CalcEllipse for 3-point arcs
	SetupArc3PointToLow	 Same as above, first point is current position
	SetupRelArc3PointToLow	 Same as above, two points are relative to 1st

	CalcTypeOfArcToFill	 Draws either a pie or chord
EXT	TempFillPolygonLow	 Fills an n-point polygon
EXT	GetEllipsePointWithAng	 Gets point in device coordinates
EXT	CalcEllipsePointWithAng	 Gets point in document coordinates
	Order3PointsInArc	 Orders the points for use by CalcConic
	Convert3PointsToBounds	 Goes from the 3-point to bounds representation
	AveragePointAndStore	 Averages two coordinates, storing in buffer
	CalcInverseSlopeAndStore Calc inverse slope, and stores in a buffer
	CalcLineLineIntersection Calculate the intersection point of two lines
	CalcPointPointDistance	 Calculate distance between two points
	CalcSqrRootDWord	 Calculates the square root of a dword

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/89		Initial revision
	jim	8/89		moved all support routines to kernel lib
	srs	9/89		changed almost everything

DESCRIPTION:
	Contains routines for drawing both arcs and pies.
		
	$Id: graphicsArcLow.asm,v 1.1 97/04/05 01:12:41 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; All the Setup*Low routines take an empty parameter buffer passed in
; SS:BP. To simplify, allocate the largest buffer necessary, so determine
; the largest
;
if (size BoundedArcParams) ge (size ThreePointArcParams)
	if (size ArcReturnParams) ge (size BoundedArcParams)
		SETUP_AE_BUFFER_SIZE	= size ArcReturnParams
	else
		SETUP_AE_BUFFER_SIZE	= size BoundedArcParams
	endif
else
	if (size ArcReturnParams) ge (size ThreePointArcParams)
		SETUP_AE_BUFFER_SIZE	= size ArcReturnParams
	else
		SETUP_AE_BUFFER_SIZE	= size ThreePointArcParams
	endif
endif

GraphicsArc segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawArcEllipseLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine for drawing an arc or an ellipse

CALLED BY:	GrDrawEllipse, GrDrawArc, ....

PASS:		DS	= GState segment
		ES	= Window segment
		DI	= Setup routine to call
		BP	= ArcCloseType
		AX, BX, CX, DX, SI = Data (see setup routine)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawArcEllipseLow	proc	near
	.enter
	
	; Some set-up work
	;
	test	es:[W_grFlags], mask WGF_MASK_NULL ; see if null mask
	jnz	exit				; if so, leave
	push	bp				; save the ArcCloseType
	sub	sp, SETUP_AE_BUFFER_SIZE	; allocate stack frame
	mov	bp, sp				; buffer => SS:BP
	call	di				; call setup routine
	test	di, mask CEF_COLINEAR		; check for colinear points
	jnz	handleColinear
		
	; Generate the points in an ellipse or arc
	;
	mov	si, bp				; parameters => SS:SI
	call	CalcEllipse			; calculate point buffer
	tst	bx				; see if for real
	jz	done				; if trivially rejected, done
	mov	dl, 1				; if ellipse, pass connect flag
	cmp	di, CET_ELLIPSE			; ellipse or arc ??
	je	draw				; ellipse, so just draw it
	call	CloseArc			; close the arc as needed
	mov	dl, al				; connected flag => DL

	; now that we have the points, draw the polyline
	;
draw:
	cmp	cx, 2				; need this many for polyline
	jl	freePoints			; if too few points, abort
	push	bx				; save point buffer handle
	call	MemLock				; lock the polyline buffer
	xchg	dx, ax				; dx:si = buffer, al = connected
	clr	si
	mov	bp, 1				; num disjoint polylines
	mov	di, GS_lineAttr			; pass line attributes
	call	DrawPolylineLow
	pop	bx				; point buffer handle => BX
freePoints:
	call	MemFree				; let it go
done:
	add	sp, SETUP_AE_BUFFER_SIZE+2	; free stack frame
exit:
	.leave
	ret

		; the points are colinear.  Just draw the line.
handleColinear:
	mov	di, GS_lineAttr			; pass line attributes
	call	DrawLineLow
	jmp	done
DrawArcEllipseLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillArcEllipseLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine for filling an arc or an ellipse

CALLED BY:	GrFillEllipse, GrFillArc, ...

PASS:		DS	= GState segment
		ES	= Window segment
		DI	= Setup routine to call
		BP	= ArcCloseType
		AX, BX, CX, DX, SI = Data (see setup routine)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillArcEllipseLowFar	proc	far
	call	FillArcEllipseLow
	ret
FillArcEllipseLowFar	endp

FillArcEllipseLow	proc	near
	.enter
	
	; Some set-up work
	;
	test	es:[W_grFlags], mask WGF_MASK_NULL
	jnz	exit				; if NULL mask, exit
	push	bp				; save the ArcCloseType
	sub	sp, SETUP_AE_BUFFER_SIZE	; allocate stack frame
	mov	bp, sp				; buffer => SS:BP
	call	di				; offset to attirubtes => SI
	test	di, mask CEF_COLINEAR		; check for colinear points
	jnz	done				; don't do anything if colinear

	; Generate the points in an ellipse or arc
	;
	xchg	si, bp				; parameters => SS:SI
	call	CalcEllipse			; do the dirty work
	tst	bx				; anything generated ??
	jz	done				; if trivially rejected, done
	push	bx, ax, dx			; save handle minY, maxY
	clr	dh				; ellipses are convex polygons
	cmp	di, CET_ELLIPSE			; ellipse or arc ??
	je	fill				; ellipse, so just fill it
	call	CloseArc			; choord or pie
	inc	dh				; arcs are not convex (for now)

	; Now we have an array of points (a polygon). Fill the polygon.
	;
fill:
	call	MemLock				; lock the Points buffer
	mov	di, bp				; offset to attirubtes => DI
	mov_tr	bp, ax
	pop	ax, bx				; restore min, max Y positions
	cmp	cx, 2				; more than two points ??
	jle	fillDone			; nope, so free the memory
	clr	si				; Point array => BP:SI
	mov	dl, RFR_ODD_EVEN		; fastest, and will always work
	call	TempFillPolygonLow		; draw the polygon
fillDone:
	pop	bx				; restore points buffer handle
	call	MemFree				; free the sucker
done:
	add	sp, SETUP_AE_BUFFER_SIZE + 2	; stack frame + ArcFillType
exit:
	.leave
	ret
FillArcEllipseLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PathArcEllipseLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine for filling an arc or an ellipse

CALLED BY:	GrFillEllipse, GrFillArc, ...

PASS:		DS	= GState segment
		ES	= Window segment
		DI	= Setup routine to call
		BP	= ArcCloseType
		AX, BX, CX, DX, SI = Data (see setup routine)

RETURN:		DX	= Point buffer
		CX	= # of Points
		(AX,BX)	= End position for arc/ellipse

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PathArcEllipseLow	proc	far
	uses	bp, si
	.enter
	
	; Some set-up work
	;
	push	bp				; save the ArcCloseType
	sub	sp, SETUP_AE_BUFFER_SIZE	; allocate stack frame
	mov	bp, sp				; buffer => SS:BP
	call	di				; offset to attirbutes => SI

	; Generate the points in an ellipse or arc
	;
	xchg	si, bp				; parameters => SS:SI
	call	CalcEllipse			; do the dirty work
	tst	bx				; anything generated ??
	jz	done				; if trivially rejected, done
	cmp	di, CET_ELLIPSE			; ellipse or arc ??
	je	done				; ellipse, so just fill it
	call	CloseArc			; choord or pie

	; Return the last position in document coordinates
done:
	push	ds
	mov	dx, bx				; buffer handle => DX
	mov	ax, ss:[si].ARP_end.P_x
	mov	bx, ss:[si].ARP_end.P_y		; device coords => (AX, BX)
	mov	si, offset GS_TMatrix		; assume using GState
	tst	ds:[GS_window]			; if no window, use GState
	jz	doUntrans
	segmov	ds, es
	mov	si, offset W_curTMatrix		; TMatrix => DS:SI
doUntrans:
	call	UnTransCoordCommonFar		; document coords => (AX, BX)
	pop	ds
	add	sp, SETUP_AE_BUFFER_SIZE + 2	; stack frame + ArcFillType

	.leave
	ret
PathArcEllipseLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Setup routines for specific types of arcs or ellipses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupEllipseLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parameter setup routine for drawing an ellipse

CALLED BY:	DrawArcEllipseLow, FillArcEllipseLow

PASS:		(AX,BX)	= (Left, top) of ellipse bounding box
		(CX,DX)	= (Right, bottom) of ellipse bounding box

RETURN:		DI	= CalcEllipseFlags
		SI	= Offset to CommonAttr to use

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupEllipseLow	proc	near
	mov	di, CET_ELLIPSE			; CalcEllipseFlags => DI
	mov	si, offset GS_areaAttr		; offset to attributes => SI
	ret
SetupEllipseLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupEllipseLineLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Paramater setup routine for drawing an ellipse, but
		returns offset to line, not area, attributes in GState

aCALLED BY:	DrawArcEllipseLow, FillArcEllipseLow

PASS:		(AX,BX)	= (Left, top) of ellipse bounding box
		(CX,DX)	= (Right, bottom) of ellipse bounding box

RETURN:		DI	= CalcEllipseFlags
		SI	= Offset to CommonAttr to use

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupEllipseLineLow	proc	near
	mov	di, CET_ELLIPSE	or \
		    CET_DONT_TRANSFORM shl offset CEF_TRANSFORM
	mov	si, offset GS_lineAttr		; offset to attributes => SI
	ret
SetupEllipseLineLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupArcLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low-level routine for drawing an arc.

CALLED BY:	DrawArcElipseLow, FillArcEllipseLow

PASS: 		AX:SI	= ArcParams
		SS:BP	= BoundedArcParams (empty)
		DS	= GState segment
		ES	= Window segment (if GS_window != 0)

RETURN:		(AX,BX)	= (Left, top) of ellipse bounding box
		(CX,DX)	= (Right, bottom) of ellipse bounding box
		DI	= CalcEllipseFlags
		SI	= Offset to CommonAttr to use
		SS:BP	= BoundedArcParams (filled)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupArcLowFar	proc	far
	call	SetupArcLow
	ret
SetupArcLowFar	endp

SetupArcLow	proc	near
	.enter

	; Transfer the contents of ArcParams to registers
	;	
	push	ds				; save GState
	mov	ds, ax				; ArcParams => DS:SI
	call	ArcParamsBoundsToRegs		; corners => (AX,BX) & (CX,DX)
	mov	di, ds:[si].AP_angle1
	mov	si, ds:[si].AP_angle2
	pop	ds				; GState => DS

	; Calculate the end point
	;
	push	di				; save angle1
	call	GetEllipsePointWithAng
	mov	ss:[bp].BAP_endPoint.P_x, di
	mov	ss:[bp].BAP_endPoint.P_y, si

	; Calculate the starting point
	;
	pop	si				; angle 1 => SI
	call	GetEllipsePointWithAng
	mov	ss:[bp].BAP_startPoint.P_x, di
	mov	ss:[bp].BAP_startPoint.P_y, si
	mov	di, CET_BOUNDED_ARC		; CalcEllipseFlags => DI
	mov	si, offset GS_areaAttr		; offset to attributes => SI

	.leave
	ret
SetupArcLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupArc3PointLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the parameters for drawing a 3 point arc

CALLED BY:	DrawArcEllipseLow, FillArcEllipseLow

PASS:		AX:SI	= ThreePointArcParams
		SS:BP	= ThreePointArcParams (empty)
		DS	= GState segment
		if DS.GS_window is non zero then
			ES = Window segment
		if DS.GS_window is zero then
			ES = undefined

RETURN:		(AX,BX)	= (Left, top) of ellipse bounding box
		(CX,DX)	= (Right, bottom) of ellipse bounding box
		DI	= CalcEllipseFlags
		SI	= Offset to CommonAttr to use
		SS:BP	= ThreePointArcParams (filled)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupArc3PointLowFar	proc	far
	call	SetupArc3PointLow
	ret
SetupArc3PointLowFar	endp


SetupArc3PointLow	proc	near
	
	; Move all the points into registers
	;
	push	ds, es
	mov	ds, ax				; ThreePointArcParams => DS:SI
	segmov	es, ss, di
	mov	di, bp
	mov	cx, (size ThreePointArcParams) / 2
	rep	movsw
	pop	ds, es

	; Now perform all work to setup 3 point arcs
	;
doThreePointArc	label	near
	call	Order3PointsInArc		; put points in proper order
	call	Convert3PointToBounds		; bounds => AX, BX, CX, DX
	mov	di, CET_3PT_ARC			; CalcEllipseFlags => DI
	jnc	haveEllipseFlags
	or	di, mask CEF_COLINEAR		; pass flag back
haveEllipseFlags:
	mov	si, offset GS_areaAttr		; offset to attributes => SI
	ret
SetupArc3PointLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupArc3PointToLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the parameters for drawing a 3 point arc from the
		current position

CALLED BY:	DrawArcEllipseLow

PASS:		AX:SI	= ThreePointArcToParams
		SS:BP	= ThreePointArcParams (empty)
		DS	= GState segment
		ES	= Window segment (if GS_window != 0)

RETURN:		(AX,BX)	= (Left, top) of ellipse bounding box
		(CX,DX)	= (Right, bottom) of ellipse bounding box
		DI	= CalcEllipseFlags
		SI	= Offset to CommonAttr to use
		SS:BP	= ThreePointArcParams (filled)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/91		Initial version
	jim	12/92		changed for fixed point, add setting of curpos

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupArc3PointToLowFar	proc	far
	call	SetupArc3PointToLow
	ret
SetupArc3PointToLowFar	endp

SetupArc3PointToLow	proc	near
	
	; Grab the current position, after moving points around
	;
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	push	ax				; save params segment
	push	ds
	mov	ds, ax
	call	GrGetCurPosWWFixed		; Point #1 => (AX, BX)
	movwwf	ss:[bp].TPAP_point1.PF_x, dxcx
	movwwf	ss:[bp].TPAP_point1.PF_y, bxax
	mov	cx, ds:[si].TPATP_close
	mov	ss:[bp].TPAP_close, cx
	movwwf	dxcx, ds:[si].TPATP_point2.PF_x
	movwwf	bxax, ds:[si].TPATP_point2.PF_y
	movwwf	ss:[bp].TPAP_point2.PF_x, dxcx
	movwwf	ss:[bp].TPAP_point2.PF_y, bxax
	movwwf	dxcx, ds:[si].TPATP_point3.PF_x
	movwwf	bxax, ds:[si].TPATP_point3.PF_y
	movwwf	ss:[bp].TPAP_point3.PF_x, dxcx
	movwwf	ss:[bp].TPAP_point3.PF_y, bxax
	pop	ds				; restore GState segment

	; as an added bonus, set the current position, since we've now
	; used the existing one.
	
	call	SetDocWWFPenPos			; set new pen position
	pop	ax				; restore params segment
	jmp	doThreePointArc			; just do it!
SetupArc3PointToLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupRelArc3PointToLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the parameters for drawing a 3 point arc relative to
		the current position

CALLED BY:	GLOBAL

PASS:		AX:SI	= ThreePointRelArcToParams
		SS:BP	= ThreePointArcParams (empty)
		DS	= GState segment
		ES	= Window segment (if GS_window != 0)

RETURN:		(AX,BX)	= (Left, top) of ellipse bounding box
		(CX,DX)	= (Right, bottom) of ellipse bounding box
		DI	= CalcEllipseFlags
		SI	= Offset to CommonAttr to use
		SS:BP	= ThreePointArcParams (filled)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupRelArc3PointToLowFar proc	far
	call	SetupRelArc3PointToLow
	ret
SetupRelArc3PointToLowFar endp

SetupRelArc3PointToLow	proc	near
	
	; Grab the current position, and calculate the other 2 points
	;
	mov	di, ds:[LMBH_handle]		; GState handle => DI
	push	ax				; save params segment
	push	ds
	mov	ds, ax
	mov	cx, ds:[si].TPRATP_close
	mov	ss:[bp].TPAP_close, cx
	call	GrGetCurPosWWFixed		; Point #1 => (AX, BX)
	movwwf	ss:[bp].TPAP_point1.PF_x, dxcx
	movwwf	ss:[bp].TPAP_point1.PF_y, bxax
	addwwf	dxcx, ds:[si].TPRATP_delta2.PF_x
	addwwf	bxax, ds:[si].TPRATP_delta2.PF_y
	movwwf	ss:[bp].TPAP_point2.PF_x, dxcx
	movwwf	ss:[bp].TPAP_point2.PF_y, bxax
	movwwf	dxcx, ss:[bp].TPAP_point1.PF_x
	movwwf	bxax, ss:[bp].TPAP_point1.PF_y
	addwwf	dxcx, ds:[si].TPRATP_delta3.PF_x
	addwwf	bxax, ds:[si].TPRATP_delta3.PF_y
	movwwf	ss:[bp].TPAP_point3.PF_x, dxcx
	movwwf	ss:[bp].TPAP_point3.PF_y, bxax
	pop	ds
	call	SetDocWWFPenPos			; set new pen position
	pop	ax				; restore params segment
	jmp	doThreePointArc
SetupRelArc3PointToLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Utility Routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcSetCurPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the current position to be the starting point of an arc

CALLED BY:	GrDrawArc, GrFillArc

PASS:		DS	= GState segment
		AX:SI	= ArcParams

RETURN:		Nothing

DESTROYED:	Nothing, not even flags

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/12/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ArcSetCurPos	proc	far
		pushf
		uses	ax, bx, cx, dx, bp
		.enter
	
		; We end at the 1st angle if we're are goemetrically
		; closed (as in ACT_CHORD & ACT_PIE). Else, we end
		; at the 2nd angle (ACT_OPEN).
		;
		push	ds			; save the GState segment
		mov	ds, ax			; ArcParams => DS:SI
		mov	bp, offset AP_angle2
		cmp	ds:[si].AP_close, ACT_OPEN
		je	calcPoint
		mov	bp, offset AP_angle1
calcPoint:
		call	ArcGetAnglePos		; end position => (AX, BX)
		mov	cx, ds
		pop	ds			; restore GState segment
		call	SetDocPenPos		; set new pen position

		.leave
		popf
		ret
ArcSetCurPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ArcGetAnglePos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the coordinate corresponding to the arc & angle

CALLED BY:	ArcSetCurPos, PathStrokeArc

PASS: 		DS:SI	= ArcParams
		BP	= Either (offset AP_angle1) or (offset AP_angle2)

RETURN:		(AX,BX)	= Starting position

DESTROYED:	CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/10/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ArcGetAnglePos	proc	far
		uses	si
		.enter
	
		; This is annoying & slow, but we have no choice
		;
		call	ArcParamsBoundsToRegs	; bounds => AX, BX, CX, DX
		mov	si, ds:[si][bp]		; angle => SI
		call	CalcEllipsePointWithAng	; start => (BX.AX, DX.CX)
		xchg	ax, bx
		rndwwf	axbx
		rndwwf	dxcx
		mov	bx, dx			; start => (AX, BX)

		.leave
		ret
ArcGetAnglePos	endp

ArcParamsBoundsToRegs	proc	near
	mov	ax, ds:[si].AP_left
	mov	bx, ds:[si].AP_top
	mov	cx, ds:[si].AP_right
	mov	dx, ds:[si].AP_bottom
	ret
ArcParamsBoundsToRegs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CloseArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine the type of arc to fill, and add all necessary
		points to the passed buffer

CALLED BY:	DrawArcEllipseLow, FillArcEllipseLow

PASS: 		BX	= Point buffer handle
		CX	= # of Points
		SS:SI	= ArcReturnParams
		SS:SI+SETUP_AE_BUFFER_SIZE = ArcCloseType

RETURN:		CX	= # of Points (updated)
		AL	= 0 (open) or 1 (closed)

DESTROYED:	AH

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CloseArcFar	proc	far
	call	CloseArc
	ret
CloseArcFar	endp

CloseArc	proc	near
	uses	dx, di, bp, es
	.enter

	; Perform some error checking
	;
EC <	cmp	{word}ss:[si+SETUP_AE_BUFFER_SIZE], ArcCloseType	>
EC <	ERROR_AE	GRAPHICS_ARC_ILLEGAL_CLOSE_TYPE			>

	; We need to ensure that the start/end points are in the point buffer,
	; and will also add the center of the circle if needed.
	;
	push	bx, cx				; save the point count
	mov_tr	ax, cx				; count => AX
	shl	ax, 1
	shl	ax, 1				; # of bytes in buffer => AX
	mov	di, ax				; also => DI
	add	ax, 5 * (size Point)		; start/end/center/EOREGREC
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
	call	MemReAlloc			; reallocate the buffer
	mov	es, ax				; segment in AX as we locked it
	pop	cx				; restore Point count

	; Add the last, center, and first points, as necessary
	;
	clr	dl				; assume it's open
	cmp	{word} ss:[si+SETUP_AE_BUFFER_SIZE], ACT_OPEN
	je	terminate
	inc	dl				; nope, it's closed
	mov	bx, offset ARP_end		; end point offet => BX
	mov	bp, -(size Point)		; offset to last point in buffer
	call	AddPointAfterCheck		; add last point if necessary
	cmp	{word} ss:[si+SETUP_AE_BUFFER_SIZE], ACT_PIE
	jne	start				; if not pie, we're done
	mov	bx, offset ARP_center		; center point offset => BX
	mov	bp, -1				; always add the point
	call	AddPointAfterCheck		; add center point
start:
	mov	bx, offset ARP_start		; start point offset => BX
	mov	bp, di
	neg	bp				; check against first point
	call	AddPointAfterCheck		
	mov	ax, es:[P_x]			; store first point as last
	stosw					; ...to complete the polygon
	mov	ax, es:[P_y]
	stosw
	inc	cx				; update point count
terminate:
	mov	ax, EOREGREC			; terminate the buffer
	stosw
	stosw

	; Clean up and exit
	;
	pop	bx				; restore buffer handle
	call	MemUnlock			; unlock the point buffer
	mov	al, dl				; open flag => AL

	.leave
	ret
CloseArc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPointAfterCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a Point to the passed array

CALLED BY:	CloseArc

PASS:		SS:SI	= Source Point array
		BX	= Index into array
		DS:DI	= Destination Point array
		BP	= Index into array to check
		CX	= Current Point count

RETURN:		CX	= Current Point count (updated)
		DS:DI	= Destination Point array (updated)

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/13/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddPointAfterCheck	proc	near
		.enter
	
		; Is the last point in the buffer? If not, add it
		;
		mov	ax, ss:[si][bx].P_x	; newX => AX
		mov	bx, ss:[si][bx].P_y	; newY => BX
		cmp	bp, -1			; always add the point ??
		je	addPoint		; yes, so go do it
		tst	di			; any Points is array yet ??
		jz	addPoint		; nope, so skip comparison
		cmp	ax, es:[di][bp].P_x
		jne	addPoint
		cmp	bx, es:[di][bp].P_y
		je	done
addPoint:
		stosw				; store the X coordinate
		mov_tr	ax, bx
		stosw				; store the Y coordinate
		inc	cx			; update point count
done:
		.leave
		ret
AddPointAfterCheck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TempFillPolygonLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A temporary DrawPolygonLow, used until either the real
		DrawPolygonLow can deal with being passed screen coordinates,
		or Jim's change to add polygon to the video driver are
		completed

CALLED BY:	FillEllipseLow

PASS:		ES	= Window segment
		DS	= GState segment
		BP:SI	= Point array
		DI	= Offset to area attributes
		DH	= 0 for convex polygon, 1 otherwise
		DL	= RegionFillRule
		CX	= Number of points
		BX	= Maximum Y position (not passed to DrawPolygonLow)
		AX	= Minimum Y position (not passed to DrawPolygonLow)

RETURN:		ES	= Window segment (may have moved)

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TempFillPolygonLow	proc	far
	.enter
	
	; Perform some error-checking
	;
EC <	push	bx, di							>
EC <	mov	di, ds:[LMBH_handle]	; GState handle => DI		>
EC <	call	ECCheckGStateHandle					>
EC <	mov	bx, es:[LMBH_handle]	; Window handle => BX		>
EC <	call	ECCheckWindowHandle					>
EC <	pop	bx, di							>
EC <	cmp	cx, 3			; don't allow zero points	>
EC <	ERROR_B	GRAPHICS_POLYGON_TOO_FEW_POINTS				>
	tst	dh			; convex polygon ??
	jnz	notConvex

	; Call the video driver, and let it do the work
	;
	mov	bx, bp
	mov	dx, si			; Point buffer => BX:DX
	mov	si, di			; attributes offset => SI
	clr	al			; always draw the points
	mov	di, DR_VID_POLYGON	; draw a polygon
	call	es:[W_driverStrategy]	; call the video driver
	jmp	done

	; Initialize a Region Path
	;
notConvex:
	push	ds, es, di, cx
	mov	ds, bp			; Point array segment => DS
	clr	di
	mov	ch, 2			; 2 on/off points per line
	mov	cl, dl			; RegionFillRule => CL
	mov	bp, ax			; minimum Y
	mov	dx, bx			; maximum Y
	call	GrRegionPathInit	; RegionPath => ES:0
	mov	bx, es:[RP_handle]	; handle => BX

	; Add the Polygon & complete the RegionPath
	;
	mov	di, si			; Point array => DS:DI
	pop	cx			; # of points => CX
	call	GrRegionPathAddPolygon	; add the polygon
	call	GrRegionPathClean	; clean the RegionPath

	; Now use the video driver to draw the Region
	;
	mov	dx, es
	mov	cx, RP_bounds		; Region => DX:CX
	pop	ds, es, si		; restore GState, Window, attributes
	push	bx			; save RegionPath handle
	clr	ax			; no X offset for drawing
	mov	bx, ax			; no Y offset for drawing
	mov	di, DR_VID_REGION	; video driver function to call
	call	es:[W_driverStrategy]	; do it!

	; Clean up
	;
	pop	bx			; restore RegionPath handle
	call	MemFree			; free it up
done:
	.leave
	ret
TempFillPolygonLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEllipsePointWithAng
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the bounds of an ellipse in document coordinates and
		an angle, returns the Point on that ellipse in device
		coordinates

CALLED BY:	SetupArcLow(), DoRoundCorner()

PASS: 		ES	= Window segment (if GS_window != 0)
		DS	= GState segment
 		(AX,BX)	= Upper-left corner
		(CX,DX)	= Lower-right corner
		SI	= Angle

RETURN:		(DI,SI)	= Point on ellipse (in 2 x device coordinates)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetEllipsePointWithAng	proc	far
		uses	ax, bx, cx, dx, ds
		.enter
	
		; Transform into device coordinates
		;
		call	CalcEllipsePointWithAng
		mov	si, offset GS_TMatrix	; in case there is no window
		tst	ds:[GS_window]		; check for window
		jz	haveTMatrix
		segmov	ds, es			; TMatrix => DS:SI
		mov	si, offset W_curTMatrix
haveTMatrix:
		xchgwwf	bxax, dxcx		; x coord=>DX.CX,y coord=>BX.AX
		call	TransCoordFixed		; go to device coordinates
		rndwwf	dxcx			; X => DX
		rndwwf	bxax			; Y => BX
		mov	di, dx
		mov	si, bx			; point => (DI, SI)

		.leave
		ret
GetEllipsePointWithAng	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEllipsePointWithAng
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a point an ellipse, given the bounds of the
		ellipse, and an angle

CALLED BY:	GLOBAL, GetEllipsePointWithAng()

PASS: 		(AX,BX)	= Upper-left corner
		(CX,DX)	= Lower-right corner
		SI	= Angle

RETURN:		BX.AX	= X-coordinate (WWFixed)
		DX.CX	= Y-coordinate (WWFixed)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Since we are performing this operation in document
		coordinates, we can ignore rotation. Assuming we translate
		the origin of the ellipse to (0, 0), we get:
		
		x^2   y^2
		--- + --- = 1
		A^2   B^2

		Where A = horizontal axis, and B = vertical axis

		With tan(angle) = y/x, we get an easy equation to solve:
			X = A*B / sqr-root(B^2 + (A*tan(angle))^2)

		There are (of course) several different ways of solving
		the simultaneous equations above, but this was chosen as
		it can easily maintain accuracy, without needing to use
		DWFixed variables.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 5/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; Deal with something on the X-axis (0 or 180)
onXAxis:
		popwwf	dxcx			; B => DX.CX
		popwwf	bxax			; A => BX.AX
		clrwwf	dxcx			; no change in Y
		cmp	si, 90
		jl	nearDoneCEPWA
		negwwf	bxax
		jmp	doneCEPWA

		; Deal with something on the Y-axis (90 or 270)
		;
onYAxis:
		popwwf	dxcx			; B => DX.CX
		popwwf	bxax			; A => BX.AX
		clrwwf	bxax			; no change in X
		cmp	si, 180
		jg	nearDoneCEPWA
		negwwf	dxcx
nearDoneCEPWA	label	near
		jmp	doneCEPWA

CalcEllipsePointWithAng	proc	near
		uses	di, si, bp
		.enter
	
		; Calculate A & B, and the offsets
		;
		call	NormalizeAngle		; make between 0 & 359(nukes DI)
		mov	bp, ax
		sub	cx, ax
		clr	ax			; initialize fraction
		shr	cx, 1
		rcr	ax, 1			; set fraction properly
		mov	di, ax
		add	bp, cx
		pushwwf	bpdi			; save X offset
		mov	bp, bx
		sub	dx, bx
		clr	bx			; initialize fraction
		shr	dx, 1
		rcr	bx, 1			; set fraction properly
		mov	di, bx
		add	bp, dx
		pushwwf	bpdi			; save Y offset
		pushwwf	cxax			; save A
		pushwwf	dxbx			; save B

		; See if we have some simple cases (0, 90, 180, 270)
		;
		tst	si
		jz	onXAxis
		cmp	si, 90
		je	onYAxis
		cmp	si, 180
		je	onXAxis
		cmp	si, 270
		je	onYAxis

		; First calculate (A*tan(angle))^2
		;
		pushwwf	cxax			; save A
		mov	dx, si
		clr	ax			; angle => DX.AX
		call	GrQuickTangent		; tangent => DX.AX
		jc	onYAxis
		movwwf	bpdi, dxax		; also store in BPDI
		mov_tr	cx, ax
		popwwf	bxax			; A => BX.AX		
		call	GrMulWWFixed		; tan(angle)*A => DX.CX
		movwwf	bxax, dxcx		; move it to BX.AX
		call	SqrWWFixed		; (tan(angle)*A)^2 => DX:CX

		; Add to that B^2, and then take the square root of the mess
		;
		popwwf	bxax			; B => BX.AX
		pushwwf	bxax			; store B again
		pushdw	dxcx			; save above calculation result
		call	SqrWWFixed		; (B)^2 => DX:CX
		popdw	bxax
		adddw	dxcx, bxax		; result => DX:AX
		clr	ax			; result => dx.cx.ax
		call	SqrRootDWFixed		; result => AX.BX
		movwwf	bxax, dxcx		; result => bx.ax

		; Finally, calculate A*B/sqr-root(mess)
		;
		popwwf	dxcx			; B => DX.CX
		call	GrSDivWWFixed		; do the division
		popwwf	bxax			; A => BX.AX
		call	GrMulWWFixed		; result => DX.CX	

		; Ensure result is on the correct side of the
		; vertical axis by checking angle measurement.
		;
		movwwf	bxax, dxcx		; X => BX.AX
		cmp	si, 90
		jl	calcY
		cmp	si, 270
		jg	calcY
		negwwf	bxax

		; Finally, calculate Y
calcY:
		movwwf	dxcx, bpdi		; tan(angle) => DX.CX
		call	GrMulWWFixed		; Y => DX.CX
		negwwf	dxcx			; coordinate system is reversed

		; Account for offset to the center of the ellipse
doneCEPWA	label	near
		popwwf	bpdi			; pop Y offset to center
		addwwf	dxcx, bpdi		; actual Y coordinate => DX.CX
		popwwf	bpdi			; pop X offset to center
		addwwf	bxax, bpdi		; actual X coordinate => BX.AX

		.leave
		ret
CalcEllipsePointWithAng	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NormalizeAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take an arbitrary signed angle, and turn it into one
		between 0 & 359 degrees

CALLED BY:	CalcEllipsePointWithAng

PASS:		SI	= Angle

RETURN:		SI	= Angle (normalized)

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NormalizeAngle	proc	near
		uses	ax
		.enter
	
		; Ensure we are between 0 & 360. If not, get it there
		;
		mov	di, 360
		sub	si, di
makeLarger:
		add	si, di
		tst	si
		jl	makeLarger
		add	si, di
makeSmaller:
		sub	si, di
		cmp	si, di
		jge	makeSmaller

		.leave
		ret
NormalizeAngle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Order3PointsInArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Due to the implementation of arcs/ellipses by CalcConic(),
		it is necessary to have the 1st point appear 1st when
		moving counter-clockwise around the ellipse, starting at 0
		degrees

CALLED BY:	SetupArc3PointLow

PASS:		SS:BP	= filled ThreePointArcParams
		DS	= GState segment
		if DS.GS_window is non zero then
			ES = Window segment
		if DS.GS_window is zero then
			ES = undefined

RETURN:		If necessary, Points #1 & #3 swapped

DESTROYED:	si, di, ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		There is a simple algorithm:
			Transform all three points to device coordinates
			Find line between #1 & #3
			If #2 is above line
				If #1 is not above/right #3, swap
			Else
				If #3 is not above/right #1, swap

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Order3PointsInArc	proc	near
	uses	ds
	.enter
	
	; Point ds:si at the appropriate translation matrix

	mov	si,offset GS_TMatrix		; assume using gstate tmatrix
	tst	ds:[GS_window]
	jz	translate
	segmov	ds, es				; window segment
	mov	si, offset W_curTMatrix		; ds:si -> TMatrix to use 

translate:
	; First, translate the three points.  Save them locally
	;

	sub	sp, size ThreePointArcParams	; buffer for translated values
	mov	di, sp				; ss:di -> buffer
	movwwf	dxcx, ss:[bp].TPAP_point1.PF_x
	movwwf	bxax, ss:[bp].TPAP_point1.PF_y
	call	TransCoordFixed			; transform Point #1
	movwwf	ss:[di].TPAP_point1.PF_x, dxcx
	movwwf	ss:[di].TPAP_point1.PF_y, bxax
	movwwf	dxcx, ss:[bp].TPAP_point2.PF_x
	movwwf	bxax, ss:[bp].TPAP_point2.PF_y
	call	TransCoordFixed			; transform Point #1
	movwwf	ss:[di].TPAP_point2.PF_x, dxcx
	movwwf	ss:[di].TPAP_point2.PF_y, bxax
	movwwf	dxcx, ss:[bp].TPAP_point3.PF_x
	movwwf	bxax, ss:[bp].TPAP_point3.PF_y
	call	TransCoordFixed			; transform Point #3
	movwwf	ss:[di].TPAP_point3.PF_x, dxcx
	movwwf	ss:[di].TPAP_point3.PF_y, bxax

	; Determine slope of a line between Point #1 & Point #3
	;
	xchgdw	dxcx, bxax			; dxcx = y coord
	subwwf	dxcx, ss:[di].TPAP_point1.PF_y	; dxcx = deltaY
	subwwf	bxax, ss:[di].TPAP_point1.PF_x	; bxax = deltaX
	call	GrSDivWWFixed			; slope => DX.CX
	LONG jc	vert				; deal with vertical

	; Now get the Y intercept (plug in Point #1)
	;
	movwwf	bxax, dxcx			; slope => BX.AX
	movwwf	dxcx, ss:[di].TPAP_point1.PF_x	; pop P1_x
	call	GrMulWWFixed			; mX1 => DX.CX
	subwwf	dxcx, ss:[di].TPAP_point1.PF_y	; dxcx = -b
	negwwf	dxcx				; dxcx = b
	pushwwf	dxcx				; save b

	; Now evaluate X2 along the line between #1 & #3
	;
	movwwf	dxcx, ss:[di].TPAP_point2.PF_x	; restore X2
	call	GrMulWWFixed			;  *slope
	popwwf	bxax				; restore value of b
	addwwf	bxax, dxcx			; bxax = y intercept
	movwwf	dxcx, ss:[di].TPAP_point2.PF_y	; dxcx = xformed Y2

	; Finally, we have enough information to decide if we
	; need to swap points. First find the position of Point #2 wrt
	; the line between #1 & #3 (check Y intercept (bxax). Then check
	; to see if #1 or #3 is above-right of the other.
	;
	clr	si
	jgewwf	dxcx, bxax, above		; jump if so
	inc	si				; bump swap count
above:
	movwwf	dxcx, ss:[di].TPAP_point1.PF_x
	movwwf	bxax, ss:[di].TPAP_point3.PF_x
	jlwwf	dxcx, bxax, checkSwap
	jgwwf	dxcx, bxax, left
	movwwf	dxcx, ss:[di].TPAP_point1.PF_y
	movwwf	bxax, ss:[di].TPAP_point3.PF_y
	jgwwf	dxcx, bxax, checkSwap		; compare y1 vs. y3
left:
	inc	si				; increment swap count

	; Now see if we need to swap points
checkSwap:
	test	si, 1				; 1's bit set ??
	jz	done
	movwwf	dxcx, ss:[bp].TPAP_point1.PF_x	; swap 'em
	movwwf	bxax, ss:[bp].TPAP_point1.PF_y
	xchgwwf	dxcx, ss:[bp].TPAP_point3.PF_x
	xchgwwf	bxax, ss:[bp].TPAP_point3.PF_y
	movwwf	ss:[bp].TPAP_point1.PF_x, dxcx	; swap 'em
	movwwf	ss:[bp].TPAP_point1.PF_y, bxax
done:
	add	sp, size ThreePointArcParams	; restore stack
	.leave
	ret

	; Deal with point #1 & #3 being vertically aligned. Points must
	; occur in counter-clockwise order.
vert:
	clr	si
	movwwf	dxcx, ss:[di].TPAP_point1.PF_y	; dxcx = y1
	movwwf	bxax, ss:[di].TPAP_point3.PF_y	; bxax = y3
	jlwwf	dxcx, bxax, point1Above		; compare y1 & y3
	inc	si				; point #3 is above point #1
point1Above:
	movwwf	dxcx, ss:[di].TPAP_point2.PF_x
	movwwf	bxax, ss:[di].TPAP_point3.PF_x
	jlwwf	dxcx, bxax, checkSwap
	inc	si				; point #2 is right of point #3
	jmp	checkSwap	
Order3PointsInArc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Convert3PointToBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert from a 3-point description of an arc to one described
		by the bounds of an ellipse (actually a circle)

CALLED BY:	SetupArc3PointLow

PASS:		SS:BP	= ThreePointArcParams

RETURN:		carry	- set if points are colinear
		
		if carry clear:
		(AX,BX) = (Left, top) of ellipse bounding box
		(CX,DX) = (Right, bottom) of ellipse bounding box

		else
		(AX,BX) = coords of point 1 (one end of line)
		(CX,DX) = coords of point 2 (other end)
		

DESTROYED:	SI

PSEUDO CODE/STRATEGY:
		We use the following theorem:
			The perpendicular bisectors of the two chords defined
			by the 3 passed points must intersect at the origin
			of the circle.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Convert3PointToBounds	proc	near
	mov	si, bp				; ss:si -> ThreePointArcParams
convertFrame	local	ConvertThreePoint
	.enter
	
	; Calculate x1, x2, y1, & y2
	;
	push	bp				; save local frame
	lea	bp, ss:[convertFrame].CTP_x1	; SS:BP => start of local vars
	movwwf	dxcx, ss:[si].TPAP_point1.PF_x
	movwwf	bxax, ss:[si].TPAP_point2.PF_x
	call	AveragePointAndStore		; x1 = (A+C)/2
	movwwf	dxcx, ss:[si].TPAP_point1.PF_y
	movwwf	bxax, ss:[si].TPAP_point2.PF_y
	call	AveragePointAndStore		; y1 = (B+D)/2
	movwwf	dxcx, ss:[si].TPAP_point2.PF_y
	movwwf	bxax, ss:[si].TPAP_point3.PF_y
	call	AveragePointAndStore		; y2 = (D+F)/2
	movwwf	dxcx, ss:[si].TPAP_point2.PF_x
	movwwf	bxax, ss:[si].TPAP_point3.PF_x
	call	AveragePointAndStore		; x2 = (C+E)/2

	; Calculate m1' & m2'
	;
	movwwf	bxax, ss:[si].TPAP_point1.PF_y	; load Y1
	subwwf	bxax, ss:[si].TPAP_point2.PF_y	; bxax = -deltaY
	movwwf	dxcx, ss:[si].TPAP_point2.PF_x	; load X2
	subwwf	dxcx, ss:[si].TPAP_point1.PF_x	; dxcx = deltaX
	call	CalcInverseSlopeAndStore	; m1' = -((D-B)/(C-A)) ^ -1
	movwwf	bxax, ss:[si].TPAP_point2.PF_y	; load Y2
	subwwf	bxax, ss:[si].TPAP_point3.PF_y	; bxax = -deltaY
	movwwf	dxcx, ss:[si].TPAP_point3.PF_x	; load X3
	subwwf	dxcx, ss:[si].TPAP_point2.PF_x	; dxcx = deltaX
	call	CalcInverseSlopeAndStore	; m2' = -((E-D)/F-C)) ^ -1
	pop	bp				; restore local stack frame

	; Calculate the center of the circle
	;
	call	CalcLineLineIntersection	; find center of the circle
	jc	colinearPoints			; handle colinear case

	; We are now very close. Find the distance from the center of the
	; circle to any of the three points (we'll use Point #3), and then
	; return the bounds of the ellipse
	;
	push	bp				; save stack frame

	; this is a little unusual.  We're going to overwrite TPAP_point2 with
	; the WWFixed center of the ellipse.  It turns out that we need this 
	; later on in the CalcEllipse routine, to accurately position the 
	; center of an arc.  There is nothing after this point that requires
	; the original value, and since it is on the stack it is biffed before
	; returning to the caller anyway...

	movwwf	ss:[si].TPAP_point2.PF_x, bxax	; save center
	movwwf	ss:[si].TPAP_point2.PF_y, dxcx
	
	call	CalcPointPointDistance		; distance => SI.DI
	pushwwf	bxax				; save center.PF_x
	pushwwf	dxcx				; save center.PF_y
	addwwf	dxcx, sidi
	rndwwf	dxcx				; Y2 => DX
	addwwf	bxax, sidi
	rndwwf	bxax
	mov	cx, bx				; X2 => CX
	popwwf	bxax
	subwwf	bxax, sidi
	rndwwf	bxax				; Y2 => BX
	popwwf	axbp
	subwwf	axbp, sidi
	rndwwf	axbp				; X2 => AX
	pop	bp				; restore stack frame
	clc					; points are not colinear
done:		
	.leave
	ret

	; handle this case separately
colinearPoints:
	movwwf	axdx, ss:[si].TPAP_point1.PF_x	; setup point1
	rndwwf	axdx				
	movwwf	bxdx, ss:[si].TPAP_point1.PF_y
	rndwwf	bxdx				
	movwwf	cxdx, ss:[si].TPAP_point3.PF_x	; setup point1
	rndwwf	cxdx				
	movwwf	dxsi, ss:[si].TPAP_point3.PF_y
	rndwwf	dxsi				
	stc
	jmp	done
Convert3PointToBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AveragePointAndStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the average of two coordinate values, and store the
		resulting WWFixed value in the provided buffer

CALLED BY:	Convert3PointToBounds

PASS:		SS:BP	= WWFixed buffer
		dxcx	= Coordinate #1
		bxax	= Coordinate #2
		
RETURN:		SS:BP	= Next buffer (original BP + size WWFixed)

DESTROYED:	dx, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/11/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AveragePointAndStore	proc	near
	addwwf	dxcx, bxax		; overflow can't happen here
	sarwwf	dxcx
	movwwf	ss:[bp], dxcx		; store the integer value
	add	bp, (size WWFixed)	; increment buffer pointer
	ret
AveragePointAndStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInverseSlopeAndStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the inverse slope of a line, based upon two
		points on the line.

CALLED BY:	INTERNAL

PASS:		SS:BP	= WWFixed buffer
		dxcx	= deltaX
		bxax	= -deltaY

RETURN:		SS:BP	= Next buffer (original BP + size WWFixed)

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcInverseSlopeAndStore	proc	near
	uses	si
	.enter
	
	; See if we have a horizontal line
	;
	movwwf	ss:[bp], 0x7fffffff		; largest possible slope
	add	bp, size WWFixed		; go to the next buffer
	mov	si, bx				; check for deltaY = 0
	or	si, ax
	jz	done				; yes, so return vertical

	; Else calculate slope
	;
	call	GrSDivWWFixed			; dxcx = -deltaY/deltaX
	movwwf	<ss:[bp-(size WWFixed)]>, dxcx
done:
	.leave
	ret
CalcInverseSlopeAndStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLineLineIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the intersection between two lines

CALLED BY:	Convert3PointToBounds

PASS:		local	= x1, y1, m1, x2, y2, m2 (see order below)

RETURN:		carry	- set if points are colinear
			  else:
				BX.AX	= X point of intersection
				DX.CX	= Y point of intersection

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		We know: Y = mX + b. Calculate the b value for each line,
		and then find x0. Once we have x0, we can plug it into
		either equation to get y0

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcLineLineIntersection	proc	near
	uses	di, si
convertFrame	local	ConvertThreePoint
	.enter	inherit
	
	; First, let's do a little checking for co-linear Points
	; or for vertical (infinite) slopes
	;
	movwwf	bxax, ss:[convertFrame].CTP_m2
	cmpwwf	bxax, ss:[convertFrame].CTP_m1
	stc						; if points colinear
	LONG je	done
	cmpwwf	bxax, 0x7fffffff		; infinite slope ??
	jne	calc				; nope, so calculate
	xchgwwf	ss:[convertFrame].CTP_m1, bxax	; swap m1 & m2, x1 & x2, y1 & y2
	movwwf	ss:[convertFrame].CTP_m2, bxax
	xchgwwf	ss:[convertFrame].CTP_x1, ss:[convertFrame].CTP_x2, cx
	xchgwwf	ss:[convertFrame].CTP_y1, ss:[convertFrame].CTP_y2, cx

	; First calculate b2 (b2 = y2 - m2x2) (store in SI.DI)
calc:
	movwwf	dxcx, ss:[convertFrame].CTP_x2
	call	GrMulWWFixed			; result => DX.CX
	movwwf	sidi, ss:[convertFrame].CTP_y2
	subwwf	sidi, dxcx			; b2 => SI.DI

	; Now calculate -b1 (b1 = y1 - m1x1) (store in DX.CX)
	;
	movwwf	bxax, ss:[convertFrame].CTP_m1
	movwwf	dxcx, ss:[convertFrame].CTP_x1
	cmpwwf	bxax, 0x7fffffff		; inifinte slope ??
	je	foundX0				; if so, x0 is in DX.CX
	call	GrMulWWFixed			; result => DX.CX
	subwwf	dxcx, ss:[convertFrame].CTP_y1

	; Now calculate x0 (x0 = (b2-b1)/(m1-m2)) (store in BX.AX)
	;
	subwwf	bxax, ss:[convertFrame].CTP_m2
	addwwf	dxcx, sidi			; b2 - b1 => DX.CX
	call	GrSDivWWFixed			; x0 => DX.CX
foundX0:
	movwwf	bxax, dxcx

	; Finally calculate y0 (y0 = m2x0 + b2)
	;
	movwwf	dxcx, ss:[convertFrame].CTP_m2
	call	GrMulWWFixed			; result => DX.CX
	addwwf	dxcx, sidi			; add in b2
	clc
done:
	.leave
	ret
CalcLineLineIntersection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcPointPointDistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calcs distance between two points

CALLED BY:	INTERNAL

PASS:		BX.AX	= X1
		DX.CX	= Y1
		SS:SI	= ThreePointArcParams struture

RETURN:		Carry	= Clear (success)
			  SI.DI	= Distance
		Carry	= Set
			  DI,SI	= Destroyed

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 9/90		Initial version
	don	9/10/91		Optimized a bit, inverted carry returned
	jim	12/4/92		changed to take a pointer to TPAP structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcPointPointDistance	proc	near
	uses	ax, bx, cx, dx, bp
	.enter

	; Calculate deltas. If horizontal or vertical, optimize
	;
	subwwf	bxax, ss:[si].TPAP_point3.PF_x		; get abs deltaX
	tst	bx
	jns	doneX
	negwwf	bxax
doneX:
	subwwf	dxcx, ss:[si].TPAP_point3.PF_y		; get abs deltaY
	tst	dx
	jns	doneY				
	negwwf	dxcx
doneY:
	movwwf	sidi, bxax
	tstwwf	dxcx				; check for no vertical diff
	jz	done				; if none, distance => BX.AX
	movwwf	sidi, dxcx
	tstwwf	bxax				; check for no horizontal diff
	jz	done				; if none, distance => DX.CX

	; Square the deltas, and calc square root of sum
	;
	call	SqrWWFixed			; deltaX ^ 2 => DX:CX
	mov_tr	bp, ax
	movwwf	bxax, sidi			; deltaY => BX.AX
	movdw	sidi, dxcx			; partial sum => SI:DI
	call	SqrWWFixed			; deltaY ^ 2 => DX:CX
	adddwf	dxcxax, sidibp
	call	SqrRootDWFixed			; distance => dx.cx
	movwwf	sidi, dxcx			; want it in SI.DI
	cmc					; invert the carry
done:
	.leave
	ret
CalcPointPointDistance	endp

if (0)

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcSqrRootDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the square root of a 32 bit number

CALLED BY:	CalcPointPointDistance

PASS:		DX:AX	= DWord (High:Low) - ALL INTEGER, NO FRAC

RETURN:		Carry	= Set (success)
			  AX.BX	= Square Root (WWFixed)
				- or -
			= Clear (failure)
			  AX,BX	= Destroyed

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
	A = (N/A +A)/2		

	
	The following produces a reasonable good fraction with little effort.
	In almost all cases repeatedly using this formula returns the
	floor of the square root. So i know that
	(A+x)(A+x) = N = A^2 + R
	x^2 + 2Ax + A^2 = A^2 + R
	X^2 + 2Ax = R
	since x < 1 , throw out X^2
	2Ax = R
	x = R/2A
	In a very few cases (actually I've only found one) the formula
	returns the ceiling. If this happens, I reduce my approximation
	by 1 and and calc x again

	The max value for passed dx is calced by 8192*65535, so that
	the calculation of the initial approx does not puke.

	ffffffh is chosen as the split point for calcing the 
	initial approximation because 300 * 65535 > ffffffh and it
	is easy to check for ffffffh just be checking for dh = 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcSqrRootDWord		proc	near
	uses	cx, dx, di, si
	.enter
	
	cmp	dx,1fffh					
	jae	done				;implied clc

	;; The initial approximation is chosen in a very arbitary fashion
	;;(N/300)+2 if N < ffffffh
	;;(N/8192)+2 if N >= ffffffh
	;; It is important that the above division returns a number
	;; less than 65536 to prevent a divide by 0 error
	;; a much better algorithm is used in GrSqrRootWWFixed but I am
	;; under a tight deadline so I am using this for now

	mov	di,dx				;save value
	mov	si,ax
	mov	bx,300				
	tst	dh
	jz	10$				;jmp if N > ffffffh
	mov	bx,8192				
10$:
	div	bx				;calc initial approx
	add	ax,2				;initial approx

	; Approximate until we get a suitable root
	;
nextApprox:
	mov	bx,ax				;save current approx
	mov	ax,si				;value
	mov	dx,di
	div	bx				;value/approx
	add	ax,bx				;add approx
	shr	ax,1				;take average
	cmp	ax,bx				;cmp new to old
	je	gotInteger			;jmp if last 2 approxs same
	sub	bx,ax				;sub new from old
	cmp	bx,1
	je	gotInteger			;jmp if only 1 dif from last
	cmp	bx,-1
	jne	nextApprox			;fall if only 1 dif from last

	; We've got the integer - go get the fraction
	;
gotInteger:
	clr	dx				;A high
	mov	bx,ax				;A 
	mul	bx				;A^2
	sub	ax,si				
	sbb	dx,di				;A^2 - N = -R
	jg	aWeirdCase
	neg	ax				;+R
	mov	dx,ax				;R
	clr	cx				;R frac
	push	bx				;A
	shl	bx,1				;2 * A
	clr	ax				;2*A frac
	call	GrUDivWWFixed
	mov	bx,cx				;frac of quotient
	pop	ax
	stc					;signal success
done:
	.leave
	ret

aWeirdCase:
	mov	ax,bx				;A
	dec	ax				;better A
	jmp	short gotInteger
CalcSqrRootDWord		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SqrWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Square a WWFixed, yielding a DWFixed number

CALLED BY:	ConjugateEllipse

PASS:		BX.AX	= WWFixed value to square

RETURN:		DX:CX:AX = DWFixed result

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/ 8/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SqrWWFixed	proc	near
		.enter
	
		; Set up registers, and multiply
		;
		movdw	dxcx, bxax
		call	MulWWFixed		; DWFixed result => DX:CX.AX

		.leave
		ret
SqrWWFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply two WWFixed values together, yielding a DWord

CALLED BY:	INTERNAL

PASS:		BX.AX	= WWFixed	(mulitplier)
		DX.CX	= WWFixed	(multiplicand)

RETURN:		DX:CX.AX= DWFixed	(Signed result)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Do full mulitply, but round the low 16 bits of the result.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version
		Don	11/91		Changed to return DWord

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MulWWFixed	proc	near
		uses	bx, si, di
multiplicand	local	dword
frac		local	word
		.enter

		; Some set-up work. Determine sign of result, and
		; prepare for multiplication
		;
		mov	si, dx			; si = negate flag
		xor	si, bx
		pushf				; save sign flag
		clrdw	sidi			; initialize result

		; check each operand, make sure both are positive
		;
		tst	dx			; check multiplicand
		jns	doneMultiplicand	;  nope, continue
		negwwf	dxcx			; do 32-bit negate
doneMultiplicand:
		tst	bx			; check multiplier
		jns	doneMultiplier		;  nope, straight to mul
		negwwf	bxax			; do 32-bit negate
doneMultiplier:

		; now we have two unsigned factors.  Do the multiply
		;
		xchg	ax, cx			; dx.ax = multiplicand
						; bx.cx = mulitplier
		mov	multiplicand.low, ax 	; save away one factor
		mov	multiplicand.high, dx
		mul	cx			; multiply low factors
		mov	frac, dx     		; save away partial result
		mov	ax, multiplicand.high	; get next victim
		mul	cx
		add	frac, ax
		adc	di, dx			; can't overflow to high word
		mov	ax, multiplicand.low	; continue with partial results
		mul	bx
		add	frac, ax		; finish off calc
		adc	di, dx
		adc	si, 0
		mov	ax, multiplicand.high
		mul	bx
		add	di, ax
		adc	si, dx

		; all done with multiply, set up result regs
		;
		mov	ax, frac
		movdw	dxcx, sidi		; DWFixed result => DX:CX.AX

		; multiply is done, check to see if we have to negate the res
		;
		popf				; see if result is negative
		jns	done			;  nope, exit
		negdwf	dxcxax			;  yes, do it
done:
		.leave
		ret
MulWWFixed	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SqrRootDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the square root of a DWFixed number

CALLED BY:	CalcPointPointDistance()

PASS:		DX:CX.AX = DWFixed number (dword integer, word fraction)

RETURN:		DX.CX	 = WWFixed result

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/ 3/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SqrRootDWFixed	proc	near
		.enter
	
		; Take the square root of the WWFixed number
		;
		tst	dx			; check the high word
		jnz	doDWFixed		; it's non-zero, so jump
		mov	dx, cx
		mov	cx, ax			; WWFixed => DX.CX
		call	GrSqrRootWWFixed	; result => DX.CX
done:
		.leave
		ret

		; Take the square root of a DWFixed number.
		; For now, we'll just ignore the fraction
doDWFixed:
		call	GrSqrRootWWFixed	; result/256 => DX.CX
		mov	ax, cx			; result => dx.ax
		mov	cx, 8			; (2^16)^.5 = 2^8
shiftLeft:
		shlwwf	dxax
		loop	shiftLeft
		mov	cx, ax			; dxcx = result
		jmp	done
SqrRootDWFixed	endp

GraphicsArc ends
