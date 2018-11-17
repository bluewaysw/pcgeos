COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GRAPHICS
FILE:		grRoundedRect.asm

AUTHOR:		Steve Scholl, Jun  8, 1989

ROUTINES:
	Name			Description
	----			-----------
	GrDrawRoundRect		draws rectangle frame with rounded corners
	GrDrawRoundRectTo 	draws rectangle frame with rounded corners
	GrFillRoundRect		fills rectangle with rounded corners
	GrFillRoundRectTo 	fills rectangle with rounded corners

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	6/ 8/89		Initial revision
	jim	8/10/89		moved support routines to kernel lib
	jim	10/10/89	added graphics string support, changed names
				(Rounded to Round), added "To" versions.


DESCRIPTION:
	Routines for drawing rectangles with rounded corners

	$Id: graphicsRoundedRect.asm,v 1.1 97/04/05 01:12:57 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsRoundRect	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with rounded corners

CALLED BY:	GLOBAL

PASS:		DI	= GState handle
		SI	= Radius of rounded corners
		(AX,BX)	= Upper-left corner
		(CX,DX)	= Lower-right corner

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 8/89		Initial version
	don	10/23/91	Re-wrote it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawRoundRect	proc	far
		call	EnterGraphics
		call	SetDocPenPos		; update current position
		jnc	drawRoundRect		; perform normal drawing op

		; Deal with drawing to a GString
		;
		tst	di			; clears zero bit, as DI != 0
roundRectGS	label	near
		mov	bp, (GSSC_FLUSH shl 8) or GR_DRAW_ROUND_RECT
		jnz	toGSCommon		; if a Path, jump
		mov	bp, (GSSC_FLUSH shl 8) or GR_FILL_ROUND_RECT
toGSCommon:
		push	dx, cx, bx, ax, si
		mov	cx, 10			; # of bytes on the stack => CX
		segmov	ds, ss
		mov	si, sp			; ds:si -> parameters
		mov	ax, bp			; opcode & control bits => AX
		call	GSStore
		add	sp, cx			; clean up the stack
		jmp	ExitGraphicsGseg
GrDrawRoundRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawRoundRectTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a rectangle with rounded corners

CALLED BY:	GLOBAL

PASS:		DI	= GState handle
		SI	= Radius of rounded corners
		(CX,DX)	= Lower-right corner

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 8/89		Initial version
	don	10/23/91	Re-wrote it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrDrawRoundRectTo	proc	far
		call	EnterGraphics
		jc	writeToGSorPath		; deal with GString or Path
		call	GetDocPenPos		; current position => (AX, BX)

		; Do the normal drawing work
		;
drawRoundRect	label	far
		call	TrivialRejectFar
		push	bp			; save EGframe
		call	PrepRoundRectLow
		call	DrawRoundRectLow
		pop	bp			; restore EGframe
		jmp	ExitGraphics	

		; Handle writing to a GString
		;
writeToGSorPath:
		tst	di			; clears zero bit, as DI != 0
roundRectToGS	label	near
		mov	al, GR_DRAW_ROUND_RECT_TO
		jnz	toGSCommon
		mov	al, GR_FILL_ROUND_RECT_TO
toGSCommon:
		mov	bx, si
		mov	si, dx
		mov	dx, cx
		mov	cl, size OpFillRoundRectTo - 1 ; 6 data bytes to write
		mov	ch, GSSC_FLUSH
		call	GSStoreBytes		; write that data
		jmp	ExitGraphicsGseg	; we're done
GrDrawRoundRectTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillRoundRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a rectangle with rounded corners

CALLED BY:	GLOBAL

PASS:		DI	= GState handle
		SI	= Radius of rounded corners
		(AX,BX)	= Upper-left corner
		(CX,DX)	= Lower-right corner

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 8/89		Initial version
	don	10/23/91	Re-wrote it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFillRoundRect	proc	far
		call	EnterGraphicsFill
		call	SetDocPenPos		; update current position
		jc	roundRectGS		; deal with GString or Path
		jmp	fillRoundRect		; perform filling operation
GrFillRoundRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillRoundRectTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill a rectangle with rounded corners

CALLED BY:	GLOBAL

PASS:		DI	= GState handle
		SI	= Radius of rounded corners
		(CX,DX)	= Lower-right corner

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	6/ 8/89		Initial version
	don	10/23/91	Re-wrote it

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrFillRoundRectTo	proc	far
		call	EnterGraphicsFill
		jc	roundRectToGS		; deal with GString or Path
		call	GetDocPenPos		; current position => (AX, BX)

		; Perform the normal drawing operation
		;
fillRoundRect	label	near
		call	TrivialRejectFar	; do some reject testing
		push	bp			; save EGframe
		call	PrepRoundRectLow	; get the buffer of points
		call	FillRoundRectLow	; now draw a filled round rect
		pop	bp			; restore EGframe
		jmp	ExitGraphics	
GrFillRoundRectTo	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Lower-level rounded rectangle routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrepRoundRectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform all the low-level work of drawing a rounded
		rectangle

CALLED BY:	GrDrawRoundRectTo, GrFillRoundRectTo

PASS:		DS	= GState segment
		ES	= Window segment
		(AX,BX)	= Upper-left corner
		(CX,DX)	= Lower-right corner
		SI	= Radius

RETURN: 	BX	= Handle to buffer holding Points
		CX	= Number of Points

DESTROYED:	AX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		* Calculate the points along each of the 4 quarter-arcs
		* Combine the points into one buffer, and draw it to
		  the screen

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrepRoundRectLowFar	proc	far
		call	PrepRoundRectLow
		ret
PrepRoundRectLowFar	endp

PrepRoundRectLow	proc	near
		.enter

		; Ensure our rectangle has the upper-left corner in (AX, BX)
		;
		cmp	ax, cx
		jle	verticalOK
		xchg	ax, cx
verticalOK:
		cmp	bx, dx
		jle	horizontalOK
		xchg	bx, dx
horizontalOK:
		; Now ensure that the radius is OK
		;
		push	cx, dx			; save lower-right corner
		sub	cx, ax			; horizontal difference => CX
		shr	cx, 1			; divide by two
		cmp	cx, si
		jae	checkVertical
		mov	si, cx			; substitute new radius
checkVertical:
		sub	dx, bx			; vertical difference => DX
		shr	dx, 1			; divide by two
		cmp	dx, si
		jge	radiusDone
		mov	si, dx
radiusDone:
		pop	cx, dx			; restore lower-right corner

		; Now we calculate the points along the inner rectangle, on
		; whose vertices the arcs will be centered
		;
		add	ax, si			; left
		add	bx, si			; top
		sub	cx, si			; right
		sub	dx, si			; bottom

		; Allocate a frame on the stack to hold information
		;
		sub	sp, 4 * (size RoundRectCorner)
		mov	bp, sp

		; Now get all of the point buffers
		;
		clr	di			; start in  quadrant #1
		xchg	ax, cx			; (AX,BX) = upper-right
		call	DoRoundCorner
		xchg	ax, cx			; (AX,BX) = upper-left
		call	DoRoundCorner
		xchg	bx, dx			; (AX,BX) = lower-left
		call	DoRoundCorner
		xchg	ax, cx			; (AX,BX) = lower-right
		call	DoRoundCorner

		; Clean up and exit
		;
		sub	bp, 4 * (size RoundRectCorner)
		call	CombineCorners		; combine into one buffer
		add	sp, 4 * (size RoundRectCorner)

		.leave
		ret
PrepRoundRectLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoRoundCorner
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate and return the points along one rounded corner

CALLED BY:	PrepRoundRectLow

PASS:		DS	= GState segment
		ES	= Window segment
		(AX,BX)	= Center of ellipse
		DI	= Quadrant (0-3)
		SI	= Radius
		SS:BP	= RoundRectCorner

RETURN:		DI	= Next quadrant
		BP	= BP + (size RoundRectCorner)
		Data is stored in the original RoundRectCorner structure
		
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		* Calculate the start/end points for the arc, and find all
		  the points in that arc

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

startEndAngle	word	0, 90, 180, 270, 0

DoRoundCorner	proc	near
		uses	ax, bx, cx, dx, di, si
		.enter
	
		; Determine the bounds of the ellipse
		;
		mov	cx, ax
		mov	dx, bx
		sub	ax, si				; left
		sub	bx, si				; top
		add	cx, si				; right
		add	dx, si				; bottom
		shl	di, 1				; change to word offset

		; Transform the start/end angles into Points
		;
		push	cs:[startEndAngle][di+2]
		mov	si, cs:[startEndAngle][di+0]	; start angle => SI
		call	GetEllipsePointWithAng		; start point => (DI,SI)
		mov	ss:[bp].RRC_params.BAP_startPoint.P_x, di
		mov	ss:[bp].RRC_params.BAP_startPoint.P_y, si
		pop	si				; end angle => SI
		call	GetEllipsePointWithAng		; end point => (DI,SI)
		mov	ss:[bp].RRC_params.BAP_endPoint.P_x, di
		mov	ss:[bp].RRC_params.BAP_endPoint.P_y, si

		; Now call to CalcEllipse() to return a buffer of points
		;
		mov	si, bp			
		add	si, offset RRC_params		; BAP => SS:SI
		mov	di, CET_BOUNDED_ARC_RR		; CalcEllipseType => DI
		call	CalcEllipse			; perform the calc
		mov	ss:[bp].RRC_pointBuffer, bx	; store the point buffer
		mov	ss:[bp].RRC_pointCount, cx	; store the point count
		add	bp, (size RoundRectCorner)	; go to next entry

		.leave
		inc	di				; go to next quadrant
		ret
DoRoundCorner	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombineCorners
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine the four corner buffers into one

CALLED BY:	PrepRoundRectLow

PASS:		SS:BP	= Array of 4 RoundRectCorner structs
		DS	= GState segment
		ES	= Window segment

RETURN:		BX	= Handle of buffer holding points
		CX	= Number of Points

DESTROYED:	AX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		We want to combine all the points in the four corner buffers
		into one buffer, so we can easily either draw the polyline
		or fill the polygon. We have two problems, though:

		1) A corner may have been clipped, either fully or
		   partially. We need to ensure the starting & ending
		   points of a corner are always present, else we won't
		   get parallel sides

		2) The RegionPath code doesn't take kindly to repeated
		   points, so we must ensure none are repeated in the
		   buffer. We know none are repeated in the individual
		   buffers, so we onlyy have to worry when we are "joining"
		   the points together

		Note, we have 5 "extra" pairs of points (not 4), because
		the Point at the end of the buffer must be the first
		point to draw a closed figure, and we must terminate the
		buffer with a double EOREGREC word.

		Normally, we combine the corners proceeding in a counter-
		clockwise direction through quadrants 1-2-3-4. If we have one
		(and only one) negative scale factor, then we combine in a
		clockwise direction (4-3-2-1).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 4/91	Initial version
	Don	 3/13/92	Deal with negative scale factors

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAXIMUM_ROUND_RECT_POINTS	= 16384		; 64K / 4

CombineCorners	proc	near
		uses	ds, es
		.enter

		; Re-allocate the first point buffer to hold all of the points
		;
		mov	ax, ss:[bp+0*(size RoundRectCorner)].RRC_pointCount
		add	ax, ss:[bp+1*(size RoundRectCorner)].RRC_pointCount
		add	ax, ss:[bp+2*(size RoundRectCorner)].RRC_pointCount
		add	ax, ss:[bp+3*(size RoundRectCorner)].RRC_pointCount
		add	ax, 10			; 5 pairs of start/end Points
EC <		cmp	ax, MAXIMUM_ROUND_RECT_POINTS			>
EC <		ERROR_A	GRAPHICS_ROUND_RECT_TOO_MANY_POINTS		>
		shl	ax, 1
		shl	ax, 1			; # of bytes => AX
		mov	cx, (HAF_STANDARD_NO_ERR_LOCK shl 8) or mask HF_SWAPABLE
		call	MemAllocFar		; segment => AX
		push	bx			; save buffer handle

		; Check in which direction we need to create the rounded rect
		;
		call	TestFlip		; carry set to go in "reverse"
		mov	si, size RoundRectCorner
		jnc	combine
		neg	si
		add	bp, 3 * (size RoundRectCorner)

		; Now copy all of the points into one buffer
combine:
		mov	es, ax
		clr	di			; start of buffer => ES:DI
		push	ss:[bp].RRC_params.BAP_startPoint.P_x
		push	ss:[bp].RRC_params.BAP_startPoint.P_y
		mov	cx, 4			; initialize loop count
		clr	dx			; initialize extra-point count

		; Add the point that begins the arc
copyLoop:
		push	cx, si			; save loop count, adjust amount
		mov	ax, ss:[bp].RRC_params.BAP_startPoint.P_x
		mov	bx, ss:[bp].RRC_params.BAP_startPoint.P_y
		call	AddPointCheckBehind	; add point that begins arc

		; Now copy the buffer of points into the new buffer
		;
		mov	bx, ss:[bp].RRC_pointBuffer
		mov	cx, ss:[bp].RRC_pointCount
		tst	bx
		jz	copyDone		; if no buffer, skip
		jcxz	copyDoneFree		; if no points, free buffer
		call	MemLock
		push	bx			; save buffer handle
		mov	ds, ax
		clr	si			; Points buffer => DS:SI
		lodsw
		mov_tr	bx, ax
		lodsw
		xchg	ax, bx			; first point => (AX, BX)
		call	AddPointCheckBehind
		dec	cx
		add	dx, cx			; update point count
		shl	cx, 1			; number of words => CX
		rep	movsw			; copy the words
		pop	bx			; restore buffer handle
copyDoneFree:
		call	MemFree
copyDone:
		; Add the point that ends the arc
		;
		mov	ax, ss:[bp].RRC_params.BAP_endPoint.P_x
		mov	bx, ss:[bp].RRC_params.BAP_endPoint.P_y
		call	AddPointCheckBehind

		pop	cx, si			; restore loop count, adjust
		add	bp, si			; go to next RoundRectCorner
		loop	copyLoop		; loop through four corners

		; Clean up
		;
		pop	ax, bx			; first point => (AX, BX)
		call	AddPointCheckBehind	; and final point to close rect
		mov	ax, EOREGREC		; and terminate the buffer
		stosw
		stosw
		pop	bx			; restore point buffer
		call	MemUnlock		; and we're ready to go
		mov	cx, dx			; number of points => CX

		.leave
		ret
CombineCorners	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPointCheckBehind
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a point to the buffer, ensuring it is not the same
		as the one behind me

CALLED BY:	CombineCorners

PASS:		ES:DI	= Point buffer
		(AX,BX)	= Point to check/add
		DX	= Point count

RETURN:		ES:DI	= Point buffer (updated)
		DX	= Point count (updated)

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddPointCheckBehind	proc	near
		.enter
	
		tst	di			; start of buffer ??
		jz	addPoint		; yes, so always add point
		cmp	ax, es:[di-4].P_x	; same X ??
		jne	addPoint		; nope, so add it
		cmp	bx, es:[di-4].P_y	; same Y ??
		je	done			; yes, so don't add point
addPoint:
		stosw				; store X
		mov_tr	ax, bx
		stosw				; store Y
		inc	dx			; increment point count
done:
		.leave
		ret
AddPointCheckBehind	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRoundRectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the actual rounded rectangle

CALLED BY:	DrawRoundRectTo

PASS:		ES	= Window segment
		DS	= GState segment
		CX	= Number of Points
		BX	= Handle of buffer holding Points

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawRoundRectLow	proc	near
		.enter

		; Draw the one buffer to the screen
		;
		push	bx
		call	MemLock			; lock the polyline buffer
		mov_tr	dx, ax
		clr	si			; DX:SI => buffer
		mov	al, 1			; we want a conencted line
		mov	bp, 1			; num disjoint polylines
		mov	di, GS_lineAttr		; pass line attributes
		call	DrawPolylineLow
		pop	bx			; point buffer handle => BX
		call	MemFree			; let it go
	
		.leave
		ret
DrawRoundRectLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillRoundRectLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill the actual rounded rectangle

CALLED BY:	FillRoundRectTo

PASS:		ES	= Window segment
		DS	= GState segment
		CX	= Number of Points
		BX	= Handle of buffer holding Points

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 4/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FillRoundRectLow	proc	near
		.enter
	
		; Fill the polygon
		;
		push	bx			; save point buffer handle
		call	MemLock			; lock the polyline buffer
		mov_tr	bp, ax			; BP:SI -> buffer
		clr	si
		mov	di, GS_areaAttr		; pass area attributes
		clr	dh			; always have a convex polygon
		mov	dl, RFR_ODD_EVEN	; use odd-even fill rule
		mov	ax, es:[W_winRect].R_top	; minimum Y
		mov	bx, es:[W_winRect].R_bottom	; maximum Y
		dec	cx			; ignore the last point
		cmp	cx, 2			; must have at least three pts
		jbe	doneFill		; if only one, skip draw
		call	TempFillPolygonLow
doneFill:
		pop	bx			; point buffer handle => BX
		call	MemFree			; let it go
	
		.leave
		ret
FillRoundRectLow	endp

GraphicsRoundRect ends


