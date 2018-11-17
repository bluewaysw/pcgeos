COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		PostScript translation library
FILE:		exportArc.asm

AUTHOR:		Jim DeFrisco, Jan 18, 1993

ROUTINES:
	Name			Description
	----			-----------
	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	1/18/93		Initial revision


DESCRIPTION:
	Special code to deal with 3Point arcs.
		

	$Id: exportArc.asm,v 1.1 97/04/07 11:25:16 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ExportArc	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Convert3PointToNormalArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does most of the work to deal with 3Point arcs

CALLED BY:	INTERNAL
		EmitDrawArc3Point, EmitFillArc3Point
PASS:		ds:si	- points to some type of 3PointArc GStringElement
		TGSLocals - stack frame inherited
RETURN:		es:di	- offset into string buffer after coords written
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Convert3PointToNormalArc	proc	far
		uses	si, ds
tgs		local	TGSLocals
		.enter	inherit

		; first do some pre-processing of the coords so that we are
		; all on the same page when it comes to parameters.  This is
		; based, of course, on the opcode.  There are 5 opcodes all
		; together.  The 3 draw ones are grouped together, and the
		; 2 fill ones are together (sequential in enum value).

		clr	bh
		mov	bl, ds:[si].ODATP_opcode	; grab the opcode
		sub	bl, GR_DRAW_ARC_3POINT		; make into table entry
		cmp	bl, GR_DRAW_REL_ARC_3POINT_TO-GR_DRAW_ARC_3POINT ;fill?
		jbe	haveTableIndex			;  yes, continue

		; if we are doing a fill operation, map the fill ones to the
		; draw ones, since (coordinate wise) we'll be producing the 
		; same thing.

		sub	bl, GR_FILL_ARC_3POINT-GR_DRAW_ARC_3POINT

		; OK, now we know what we're dealing with.  Call the right
		; setup routine
haveTableIndex:
		shl	bx, 1				; *2 for word index
		call	cs:arc3CoordSetup[bx]		; setup coords

		; OK, now they are all reduced to one ThreePointArcParams 
		; structure.  Get on with the real work.  We need to calculate
		; the bounds of the rectangle that encloses the ellipse that
		; defines the arc, along with the starting and ending angles.

		call	Order3PointsInArc		; put points in order
		call	Convert3PointToBounds		; bounds => AX,BX,CX,DX
		call	CalcArcAngles			; 

		; OK, we have it all.  Output the hooey.

		segmov	es, ss, di
		lea	di, tgs.TGS_buffer	; es:di -> buffer
		movdw	bxax, tgs.TGS_newArc.CAP_ang1
		call	WWFixedToAscii
		mov	al, ' '
		stosb
		movdw	bxax, tgs.TGS_newArc.CAP_ang2
		call	WWFixedToAscii
		mov	al, ' '
		stosb

		clr	bx, ax
		tst	tgs.TGS_xfactor		; check to see what it is
		jz	x2OK
		movdw	bxax, tgs.TGS_newArc.CAP_br.PF_x
x2OK:
		call	WWFixedToAscii		; save coordinate value
		mov	al, ' '
		stosb
		clr	bx, ax
		tst	tgs.TGS_xfactor		; check to see what it is
		jz	x1OK
		movdw	bxax, tgs.TGS_newArc.CAP_tl.PF_x
x1OK:
		call	WWFixedToAscii		; save coordinate value
		mov	al, ' '
		stosb
		clr	bx, ax
		tst	tgs.TGS_yfactor		; check to see what it is
		jz	y2OK
		movdw	bxax, tgs.TGS_newArc.CAP_br.PF_y
y2OK:
		call	WWFixedToAscii		; save coordinate value
		mov	al, ' '
		stosb
		clr	bx, ax
		tst	tgs.TGS_yfactor		; check to see what it is
		jz	y1OK
		movdw	bxax, tgs.TGS_newArc.CAP_tl.PF_y
y1OK:
		call	WWFixedToAscii		; save coordinate value
		mov	al, ' '
		stosb

		.leave
		ret
Convert3PointToNormalArc	endp


arc3CoordSetup	label	nptr
		word	offset Setup3PointArc
		word	offset Setup3PointArcTo
		word	offset Setup3PointRelArcTo


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Setup3PointArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Coord setup routine

CALLED BY:	INTERNAL
		Convert3PointToNormalArc
PASS:		ds:si	- pointer to OpDrawArc3Point or OpFillArc3Point struct
		tgs	- TGSLocals stack frame
RETURN:		fill in tgs.TGS_arc field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Setup3PointArc	proc	near
		uses	es, si, di, cx
tgs		local	TGSLocals
		.enter	inherit

		; this is easy, just copy the info over

		add	si, offset ODATP_close	; get to start of struct
		mov	cx, size ThreePointArcParams
		segmov	es, ss, di
		lea	di, tgs.TGS_arc	; es:di -> destination
		rep	movsb

		.leave
		ret
Setup3PointArc	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Setup3PointArcTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Coord setup routine

CALLED BY:	INTERNAL
		Convert3PointToNormalArc
PASS:		ds:si	- pointer to OpDrawArc3PointTo or OpFillArc3PointTo
			  struct
		tgs	- TGSLocals stack frame
RETURN:		fill in tgs.TGS_arc field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Setup3PointArcTo proc	near
		uses	ax, bx, es, si, di, cx
tgs		local	TGSLocals
		.enter	inherit

		; this is a little tougher than the last.  Copy the last
		; part and get the current position to fill in the first.

		mov	ax, ds:[si].ODATPT_close	; get close type
		mov	tgs.TGS_arc.TPAP_close, ax

		mov	di, tgs.TGS_gstate	; so we can get the current pos
		call	GrGetCurPosWWFixed
		movdw	tgs.TGS_arc.TPAP_point1.PF_x, dxcx ; store first coord
		movdw	tgs.TGS_arc.TPAP_point1.PF_y, bxax

		add	si, offset ODATPT_x2	; get to start of struct
		mov	cx, 2*(size PointWWFixed) ; copying 2 coords
		segmov	es, ss, di
		lea	di, tgs.TGS_arc.TPAP_point2.PF_x ; es:di -> destination
		rep	movsb

		.leave
		ret
Setup3PointArcTo endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Setup3PointRelArcTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Coord setup routine

CALLED BY:	INTERNAL
		Convert3PointToNormalArc
PASS:		ds:si	- pointer to OpDrawRElArc3Point struct
		tgs	- TGSLocals stack frame
RETURN:		fill in tgs.TGS_arc field
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Setup3PointRelArcTo proc near
		uses	si, di, cx, ax, bx, dx
tgs		local	TGSLocals
		.enter	inherit

		; get current position and calc the other coords based on
		; the relative coords stored in the element

		mov	ax, ds:[si].ODRATPT_close	; get close type
		mov	tgs.TGS_arc.TPAP_close, ax

		mov	di, tgs.TGS_gstate	; so we can get the current pos
		call	GrGetCurPosWWFixed
		movdw	tgs.TGS_arc.TPAP_point1.PF_x, dxcx ; store first coord
		movdw	tgs.TGS_arc.TPAP_point1.PF_y, bxax

		adddw	dxcx, ds:[si].ODRATPT_x2	; get rel coords
		adddw	bxax, ds:[si].ODRATPT_y2
		movdw	tgs.TGS_arc.TPAP_point1.PF_x, dxcx
		movdw	tgs.TGS_arc.TPAP_point1.PF_y, bxax

		movdw	dxcx, ds:[si].ODRATPT_x3	; get rel coords
		movdw	bxax, ds:[si].ODRATPT_y3
		adddw	dxcx, tgs.TGS_arc.TPAP_point1.PF_x
		adddw	bxax, tgs.TGS_arc.TPAP_point1.PF_y
		movdw	tgs.TGS_arc.TPAP_point3.PF_x, dxcx
		movdw	tgs.TGS_arc.TPAP_point3.PF_y, bxax

		.leave
		ret
Setup3PointRelArcTo endp


;-----------------------------------------------------------------------
;	These were taken/modified from the kernel code for 3 point arcs
;-----------------------------------------------------------------------

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Order3PointsInArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Due to the implementation of arcs/ellipses by CalcConic(),
		it is necessary to have the 1st point appear 1st when
		moving counter-clockwise around the ellipse, starting at 0
		degrees

CALLED BY:	SetupArc3PointLow

PASS:		tgs	- inherited TGSLocals stack frame

RETURN:		If necessary, Points #1 & #3 swapped

DESTROYED:	nothing

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
	jim	1/18/93		modified for use with PS xlation lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Order3PointsInArc	proc	near
		uses	ds, di
tgs		local	TGSLocals
		.enter	inherit
	
		; save the coords, transform the 3 points by the GState
		; do the calc and then restore the points.

		pushwwf	tgs.TGS_arc.TPAP_point1.PF_x
		pushwwf	tgs.TGS_arc.TPAP_point1.PF_y
		pushwwf	tgs.TGS_arc.TPAP_point2.PF_x
		pushwwf	tgs.TGS_arc.TPAP_point2.PF_y
		pushwwf	tgs.TGS_arc.TPAP_point3.PF_x
		pushwwf	tgs.TGS_arc.TPAP_point3.PF_y

		; Determine slope of a line between Point #1 & Point #3
		;
		movdw	dxcx, tgs.TGS_arc.TPAP_point3.PF_y
		movdw	bxax, tgs.TGS_arc.TPAP_point3.PF_x
		subwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_y	; dxcx = deltaY
		subwwf	bxax, tgs.TGS_arc.TPAP_point1.PF_x	; bxax = deltaX
		call	GrSDivWWFixed			; slope => DX.CX
		LONG jc	vert				; deal with vertical

		; Now get the Y intercept (plug in Point #1)
		;
		movwwf	bxax, dxcx			; slope => BX.AX
		movwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_x	; pop P1_x
		call	GrMulWWFixed			; mX1 => DX.CX
		subwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_y	; dxcx = -b
		negwwf	dxcx				; dxcx = b
		pushwwf	dxcx				; save b

		; Now evaluate X2 along the line between #1 & #3
		;
		movwwf	dxcx, tgs.TGS_arc.TPAP_point2.PF_x	; restore X2
		call	GrMulWWFixed			;  *slope
		popwwf	bxax				; restore value of b
		addwwf	bxax, dxcx			; bxax = y intercept
		movwwf	dxcx, tgs.TGS_arc.TPAP_point2.PF_y ; dxcx = xformed Y2

		; Finally, we have enough information to decide if we
		; need to swap points. First find the position of Point #2 wrt
		; the line between #1 & #3 (check Y intercept (bxax).Then check
		; to see if #1 or #3 is above-right of the other.
		;
		clr	si
		jgewwf	dxcx, bxax, above		; jump if so
		inc	si				; bump swap count
above:
		movwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_x
		movwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_x
		jlwwf	dxcx, bxax, checkSwap
		jgwwf	dxcx, bxax, left
		movwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_y
		movwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_y
		jgwwf	dxcx, bxax, checkSwap		; compare y1 vs. y3
left:
		inc	si				; increment swap count

		; Now see if we need to swap points.  First restore original
		; coordinates.
checkSwap:
		popwwf	tgs.TGS_arc.TPAP_point3.PF_y
		popwwf	tgs.TGS_arc.TPAP_point3.PF_x
		popwwf	tgs.TGS_arc.TPAP_point2.PF_y
		popwwf	tgs.TGS_arc.TPAP_point2.PF_x
		popwwf	tgs.TGS_arc.TPAP_point1.PF_y
		popwwf	tgs.TGS_arc.TPAP_point1.PF_x
		test	si, 1				; 1's bit set ??
		jnz	done
		movwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_x	; swap 'em
		movwwf	bxax, tgs.TGS_arc.TPAP_point1.PF_y
		xchgwwf	dxcx, tgs.TGS_arc.TPAP_point3.PF_x
		xchgwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_y
		movwwf	tgs.TGS_arc.TPAP_point1.PF_x, dxcx	; swap 'em
		movwwf	tgs.TGS_arc.TPAP_point1.PF_y, bxax
done:
		.leave
		ret

		; Deal with point #1 & #3 being vertically aligned. Points must
		; occur in counter-clockwise order.
vert:
		clr	si
		movwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_y	; dxcx = y1
		movwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_y	; bxax = y3
		jlwwf	dxcx, bxax, point1Above		; compare y1 & y3
		inc	si				; pt #3 is above #1
point1Above:
		movwwf	dxcx, tgs.TGS_arc.TPAP_point2.PF_x
		movwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_x
		jgewwf	dxcx, bxax, point2Right
		dec	si
point2Right:
		inc	si				; pt #2 is right of #3
		jmp	checkSwap	
Order3PointsInArc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Convert3PointToBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert from a 3-point description of an arc to one described
		by the bounds of an ellipse (actually a circle)

CALLED BY:	SetupArc3PointLow

PASS:		tgs	- inherited TGSLocals stack frame

RETURN:		tgs.TGS_newArc.CAP_bounds filled in

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
	jim	1/18/93		modified for use in PS xlation lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Convert3PointToBounds	proc	near
tgs		local	TGSLocals
		.enter	inherit
	
		; Calculate x1, x2, y1, & y2
		;
		movwwf	bxax, tgs.TGS_arc.TPAP_point1.PF_x
		addwwf	bxax, tgs.TGS_arc.TPAP_point2.PF_x
		sarwwf	bxax
		movwwf	tgs.TGS_newArc.CAP_p1.PF_x, bxax

		movwwf	bxax, tgs.TGS_arc.TPAP_point1.PF_y
		addwwf	bxax, tgs.TGS_arc.TPAP_point2.PF_y
		sarwwf	bxax
		movwwf	tgs.TGS_newArc.CAP_p1.PF_y, bxax

		movwwf	bxax, tgs.TGS_arc.TPAP_point2.PF_y
		addwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_y
		sarwwf	bxax
		movwwf	tgs.TGS_newArc.CAP_p2.PF_y, bxax

		movwwf	bxax, tgs.TGS_arc.TPAP_point2.PF_x
		addwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_x
		sarwwf	bxax
		movwwf	tgs.TGS_newArc.CAP_p2.PF_x, bxax

		; Calculate m1' & m2'
		;
		movwwf	bxax, tgs.TGS_arc.TPAP_point1.PF_y	; load Y1
		subwwf	bxax, tgs.TGS_arc.TPAP_point2.PF_y	; bxax = -dY
		movwwf	dxcx, tgs.TGS_arc.TPAP_point2.PF_x	; load X2
		subwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_x	; dxcx = dX
		call	CalcInverseSlope	 ; m1' = -((D-B)/(C-A)) ^ -1
		movwwf	tgs.TGS_newArc.CAP_m1, dxcx
		movwwf	bxax, tgs.TGS_arc.TPAP_point2.PF_y	; load Y2
		subwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_y	; bxax = -dY
		movwwf	dxcx, tgs.TGS_arc.TPAP_point3.PF_x	; load X3
		subwwf	dxcx, tgs.TGS_arc.TPAP_point2.PF_x	; dxcx = dX
		call	CalcInverseSlope	 ; m2' = -((E-D)/F-C)) ^ -1
		movwwf	tgs.TGS_newArc.CAP_m2, dxcx

		; Calculate the center of the circle
		;
		call	CalcLineLineIntersection		; find center 

		; We are now very close. Find the distance from the center 
		; of the circle to any of the three points (we'll use 
		; Point #3), and then return the bounds of the ellipse
		;
		call	CalcPointPointDistance		; distance => SI.DI

		movwwf	tgs.TGS_newArc.CAP_radius, sidi
		movwwf	tgs.TGS_newArc.CAP_center.PF_x, bxax
		movwwf	tgs.TGS_newArc.CAP_center.PF_y, dxcx

		addwwf	dxcx, sidi
		movwwf	tgs.TGS_newArc.CAP_br.PF_y, dxcx

		addwwf	bxax, sidi
		movwwf	tgs.TGS_newArc.CAP_br.PF_x, bxax
		
		movwwf	bxax, tgs.TGS_newArc.CAP_center.PF_y
		subwwf	bxax, sidi
		movwwf	tgs.TGS_newArc.CAP_tl.PF_y, bxax

		movwwf	bxax, tgs.TGS_newArc.CAP_center.PF_x
		subwwf	bxax, sidi
		movwwf	tgs.TGS_newArc.CAP_tl.PF_x, bxax

		.leave
		ret
Convert3PointToBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcArcAngles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get start/end angles for 3Point arc

CALLED BY:	INTERNAL
		Convert3PointToNormalArc
PASS:		tgs	- inherited stack frame
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jim	1/18/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcArcAngles	proc	near
		uses	ax,bx,cx,dx
tgs		local	TGSLocals
		.enter	inherit

		; calculate angle 1

		movwwf	dxcx, tgs.TGS_arc.TPAP_point1.PF_y
		subwwf	dxcx, tgs.TGS_newArc.CAP_center.PF_y
		movwwf	bxax, tgs.TGS_newArc.CAP_radius
		call	GrSDivWWFixed
		movwwf	bxax, tgs.TGS_arc.TPAP_point1.PF_x
		subwwf	bxax, tgs.TGS_newArc.CAP_center.PF_x
		call	GrQuickArcSine			; dxcx = angle
		movwwf	tgs.TGS_newArc.CAP_ang1, dxcx

		; calculate angle 2

		movwwf	dxcx, tgs.TGS_arc.TPAP_point3.PF_y
		subwwf	dxcx, tgs.TGS_newArc.CAP_center.PF_y
		movwwf	bxax, tgs.TGS_newArc.CAP_radius
		call	GrSDivWWFixed
		movwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_x
		subwwf	bxax, tgs.TGS_newArc.CAP_center.PF_x
		call	GrQuickArcSine			; dxcx = angle
		movwwf	tgs.TGS_newArc.CAP_ang2, dxcx

		.leave
		ret
CalcArcAngles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcInverseSlope
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the inverse slope of a line, based upon two
		points on the line.

CALLED BY:	INTERNAL

PASS:		dxcx	= deltaX
		bxax	= -deltaY

RETURN:		dxcx	= slope

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/91		Initial version
	jim	1/18/93		modified for use with EPS lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcInverseSlope	proc	near
	uses	si
	.enter
	
	; See if we have a horizontal line
	;
	mov	si, bx				; check for deltaY = 0
	or	si, ax
	jz	horizontal			; yes, so return big inv slope

	; Else calculate slope
	;
	call	GrSDivWWFixed			; dxcx = -deltaY/deltaX
done:
	.leave
	ret

horizontal:
	movdw	dxcx, 0x7fffffff		; largest possible slope
	jmp	done
CalcInverseSlope	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLineLineIntersection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the intersection between two lines

CALLED BY:	Convert3PointToBounds

PASS:		tgs	- inherited stack frame

RETURN:		BX.AX	= X point of intersection
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
	jim	1/18/93		modified for use with EPS lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcLineLineIntersection	proc	near
		uses	di, si
tgs		local	TGSLocals
		.enter	inherit
	
		; First, let's do a little checking for co-linear Points
		; or for vertical (infinite) slopes
		;
		movwwf	bxax, tgs.TGS_newArc.CAP_m2
		cmpwwf	bxax, 0x7fffffff		; infinite slope ??
		jne	calc				; nope, so calculate
		xchgwwf	tgs.TGS_newArc.CAP_m1, bxax	; swap m1 & m2, 
		movwwf	tgs.TGS_newArc.CAP_m2, bxax	;   x1 & x2, y1 & y2
		xchgwwf	tgs.TGS_newArc.CAP_p1.PF_x,\
			tgs.TGS_newArc.CAP_p2.PF_x, cx
		xchgwwf	tgs.TGS_newArc.CAP_p1.PF_y,\
			tgs.TGS_newArc.CAP_p2.PF_y, cx

		; First calculate b2 (b2 = y2 - m2x2) (store in SI.DI)
calc:
		movwwf	dxcx, tgs.TGS_newArc.CAP_p2.PF_x
		call	GrMulWWFixed			; result => DX.CX
		movwwf	sidi, tgs.TGS_newArc.CAP_p2.PF_y
		subwwf	sidi, dxcx			; b2 => SI.DI

		; Now calculate -b1 (b1 = y1 - m1x1) (store in DX.CX)
		;
		movwwf	bxax, tgs.TGS_newArc.CAP_m1
		movwwf	dxcx, tgs.TGS_newArc.CAP_p1.PF_x
		cmpwwf	bxax, 0x7fffffff		; inifinte slope ??
		je	foundX0				; if so, x0 is in DX.CX
		call	GrMulWWFixed			; result => DX.CX
		subwwf	dxcx, tgs.TGS_newArc.CAP_p1.PF_y

		; Now calculate x0 (x0 = (b2-b1)/(m1-m2)) (store in BX.AX)
		;
		subwwf	bxax, tgs.TGS_newArc.CAP_m2
		addwwf	dxcx, sidi			; b2 - b1 => DX.CX
		call	GrSDivWWFixed			; x0 => DX.CX
foundX0:
		movwwf	bxax, dxcx

		; Finally calculate y0 (y0 = m2x0 + b2)
		;
		movwwf	dxcx, tgs.TGS_newArc.CAP_m2
		call	GrMulWWFixed			; result => DX.CX
		addwwf	dxcx, sidi			; add in b2

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
		tgs	- inherited TGSLocals

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
	jim	1/18/93		changed again for EPS lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcPointPointDistance	proc	near
		uses	ax, bx, cx, dx, bp
tgs		local	TGSLocals
		.enter	inherit

		; Calculate deltas. If horizontal or vertical, optimize
		;
		subwwf	bxax, tgs.TGS_arc.TPAP_point3.PF_x	; get abs dX
		tst	bx
		jns	doneX
		negwwf	bxax
doneX:
		subwwf	dxcx, tgs.TGS_arc.TPAP_point3.PF_y	; get abs dY
		tst	dx
		jns	doneY				
		negwwf	dxcx
doneY:
		movwwf	sidi, bxax
		tstwwf	dxcx				; vertical diff ?
		jz	done				;  none, dist => BX.AX
		movwwf	sidi, dxcx
		tstwwf	bxax				; horizontal diff ?
		jz	done				;  none, dist => DX.CX

		; Square the deltas, and calc square root of sum
		;
		call	SqrWWFixed			; deltaX ^ 2 => DX:CX
		mov_tr	bp, ax				; save fraction part
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



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SqrWWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Square a WWFixed, yielding a dword

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

ExportArc	ends
