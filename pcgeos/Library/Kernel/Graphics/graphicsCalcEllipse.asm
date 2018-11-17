COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KLib
FILE:		Graphics/graphicsCalcEllipse.asm

AUTHOR:		Jim DeFrisco, 27 July 1990

ROUTINES:
	Name			Description
	----			-----------
    EXT	CalcEllipse		Calculates the visible point on the ellipse
    INT	EllipseTrivialRejeect	Trivally reject arc/ellipse by bounds calcs
    INT	ConjugateEllipse	Calculate the conic coefficients

    INT	SetupEllipse		Set up to draw an ellipse
    INT	SetupArc		Set up to draw an arc
    INT Setup3PointArc		Set up to draw a 3-point arc
    INT	SetupArcCommon		Common setup work

    INT TransCoordAndDouble	Transform coordinate & double
    INT AvgTwoCoords		Compute the average of two coordinates
    INT	CheckXMinMax		Check against the current min/max X coordinate
    INT CheckYMinMax		Check against the current min/max Y coordinate
    INT MulSignedDWord		Multiple two signed dwords together

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/27/90		Initial revision


DESCRIPTION:
	This module holds the code to calculate the points on a rotated
	ellipse.  The code is based on an algorithm presented in "Computer
	Graphics, Principles and Practice" (Foley, van Dam, Feiner, Hughes)
	page 951.
		

	$Id: graphicsCalcEllipse.asm,v 1.1 97/04/05 01:12:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsCalcEllipse	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the set of visible points along an ellipse or
		part of an ellipse.

CALLED BY:	GLOBAL
		GrDrawEllipse

PASS:		ax,bx,cx,dx	- bounds of rectangle holding the ellipse
		di		- CalcEllipseFlags
		si		- Data dependent upon CalcEllipseType
				  that is part of CalcEllipseFlags. See:
					SetupEllipse
					SetupArc
					Setup3PointArc
		ds		- gstate segment (locked)
		es		- window segment (locked and owned)
				  A window may or may not be supplied.
				
RETURN:		bx		- handle of buffer holding line segments. If 0,
				  indicates the ellipse was trivially rejected.
		cx		- number of points in buffer
		ax,dx		- min/max y position
		di		- CalcEllipseType (all other CalcEllipseFlags
				  are masked out)
				
DESTROYED:	ax,cx,dx

PSEUDO CODE/STRATEGY:
		This routine transforms the points to get the effect of 
		rotation/skewing/etc, allocates the stack frame that is used
		by the other support routines, allocates the buffer to store
		the ellipse points, and sets up the parameters to call
		the ConjugateEllipse routine.

		The points p1 thru p4 represent the 4 coordinates that
		define the rectangle, as follows:

			p1	      		p2
			+------------------------+
			|			 |
			|			 |
			|	     + J	 + P
			|			 |
			|			 |
			+------------+-----------+
		        p4	     Q		p3

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version
		Don	11/91		Lots of mucking around
		Jim	12/92		Changed to allow no window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; stack frame structure
EllipseFrame	struct	
		; ellipse part of the calculations
    EF_p1	Point		; transformed upper left corner
    EF_p2	Point		; transformed upper right corner
    EF_p3	Point		; transformed lower right corner
    EF_p4	Point		; transformed lower right corner
    EF_J	Point		; center of ellipse
    EF_P	Point		; midpoint between EF_p2 and EF_p3 (rel to J)
    EF_Q	Point		; midpoint between EF_p3 and EF_p4 (rel to J)
    EF_center	PointWWFixed	; more accurate rendition of center, for
				;  three point arcs
		; structure to pass onto the CalcConic routine
    EF_conic	ConicParams	; info passed along to the conic section code
EllipseFrame	ends

		; setup routines for arcs & ellipses. Must mirror
		; definitions of CalcEllipseType!!!
setupRoutines	nptr.near SetupEllipse, SetupArc, SetupArc, Setup3PointArc
		; routines to draw a "simple" ellipse or arc, when
		; the normal ellipse code will not work. These routines
		; must mirror the definitions of CalcEllipseType!!!
simpleRoutines	nptr.near SimpleEllipse, SimpleArc, SimpleArc, SimpleArc

CalcEllipse	proc	far
		uses	di, si, ds, es
Eframe		local	EllipseFrame
		.enter

		; first transform the two corners we need to calculate 
		; J, P and Q.  J=p3-p1, P=p3-p2, Q=p2-p1

		cmp	ax, cx			; ensure AX is smallest X
		jle	horizontalOK		; if OK, jump
		xchg	ax, cx			; else swap the x-coordinates
horizontalOK:
		cmp	bx, dx			; ensure BX is smallest Y
		jle	verticalOK		; if OK, jump
		xchg	bx, dx			; esle swap the y-coordinates
verticalOK:
		push	cx,bx,ax,dx		; save upper right, lower left
		call	TransCoordAndDouble	; calculate p1,p3
		LONG	jc	errorPopFour
		mov	Eframe.EF_p1.P_x, ax	; save away p1
		mov	Eframe.EF_p1.P_y, bx
		mov	Eframe.EF_p2.P_x, cx	; save away p2
		mov	Eframe.EF_p2.P_y, bx
		mov	Eframe.EF_p3.P_x, cx	; save away p3
		mov	Eframe.EF_p3.P_y, dx
		mov	Eframe.EF_p4.P_x, ax	; save away p4
		mov	Eframe.EF_p4.P_y, dx
		call	AvgTwoCoords		; find the midpoint
		mov	Eframe.EF_J.P_x, cx	; save away J
		mov	Eframe.EF_J.P_y, dx
		mov	Eframe.EF_conic.C_center.P_x, cx
		mov	Eframe.EF_conic.C_center.P_y, dx

		; the real center is half of EF_J, since that is doubled.
		; The 3PointArc routine will overwrite this with an even more
		; accurate value,  but store it here for the others. 

		clr	ax
		sarwwf	cxax
		movwwf	Eframe.EF_center.PF_x, cxax
		salwwf	cxax
		sarwwf	dxax
		movwwf	Eframe.EF_center.PF_y, dxax
		salwwf	dxax

		neg	cx			; start out P and Q relatively
		neg	dx
		mov	Eframe.EF_P.P_x, cx	; init P and Q
		mov	Eframe.EF_Q.P_y, dx

		; if there is no rotation, the the calcs for P & Q are easy

		call	TestRotation
		LONG	jnz	handleRotation
		add	sp, 8			; don't need saved coords
		clr	ax
		mov	Eframe.EF_P.P_y, ax	; Py = 0
		mov	Eframe.EF_Q.P_x, ax	; Qx = 0
		mov	ax, Eframe.EF_p2.P_x	; P2x => AX
		add	Eframe.EF_P.P_x, ax
		mov	ax, Eframe.EF_p3.P_y	; P3y => AX
		add	Eframe.EF_Q.P_y, ax
		jmp	checkTooThin
		
		; used later to determine if the ellipse is too thin, and
		; drawn using the colinear code.
doTrivialReject:
		pushf				; save carry, indicating thin
		and	di, mask CEF_TYPE	; CalcEllipseType => DI
EC <		cmp	di, CalcEllipseType	; check validity	>
EC <		ERROR_AE GRAPHICS_ELLIPSE_ILLEGAL_CALC_ELLIPSE_TYPE	>
EC <		test	di, 0x1			; low bit must be zero	>
EC <		ERROR_NZ GRAPHICS_ELLIPSE_ILLEGAL_CALC_ELLIPSE_TYPE	>
		call	cs:[setupRoutines][di]	; calc start/end points, need SI
		call	EllipseTrivialReject	; will we draw it ?
		jc	errorPopOne		; do not try to draw it

		; We want to allocate a minimum of memory, yet have
		; enough for the worst case ellipse that can be drawn.
		; We allocate enough memory to hold all the points on the
		; bounding box of the ellipse (4 * (2H + 2W)), and we
		; look at both the Window & the ellipse's own bounds
		; to minimize the memory required

		mov_tr	si, ax			; left stored in SI
		push	dx
		movwwf	dxax, ds:[GS_lineWidth] ; get line width
		call	ScaleScalar		; scaled line width => AX
		pop	dx
		inc	ax			; make sure it's at least one.
		sub	bx, ax			; adjust top
		add	dx, ax
		mov	Eframe.EF_conic.C_winTop, bx
		mov	Eframe.EF_conic.C_winBot, dx
		sub	dx, bx
		sub	cx, si
		shl	ax, 1			; double line-width
		add	ax, cx			; add in width (no line width)
		add	ax, dx			; add in heght (with line width)
		shl	ax, 1			; *2
		shl	ax, 1			; *4
		shl	ax, 1			; *8
		sub	ax, (size Point)	; size = size - Point
		mov	Eframe.EF_conic.C_sBuffer, ax
		mov	cx, ALLOC_DYNAMIC_NO_ERR
		call	MemAllocFar		; allocate the block
		mov	Eframe.EF_conic.C_hBuffer, bx

		; Calculate the coefficients of the conic section equation

		call	ConjugateEllipse	; calc cooefficients
		jc	colinearPop		; points are colinear, dont draw
		popf				; earlier error with thinness ?
		jc	colinear		; also treat as colinear

		; now calculate the points along the curve

		lea	si, Eframe.EF_conic	; pass pointer to frame
if	DEBUG_CONIC_SECTION_CODE
		mov	ax, ds:[LMBH_handle]
		mov	ss:[si].C_gstate, ax
		mov	ax, es:[LMBH_handle]
		mov	ss:[si].C_window, ax
endif
		call	CalcConic		; # of points => CX	

		; now the buffer is full.  Return handle
done:
		mov	bx, Eframe.EF_conic.C_hBuffer	; get handle
		mov	ax, Eframe.EF_conic.C_winTop	; return min/max coords
		mov	dx, Eframe.EF_conic.C_winBot
exit:
		.leave
		and	di, mask CEF_TYPE	; CalcEllipseType => DI
		ret

		; we encountered an error. Clean up the stack (if necessary)
		; and return both BX & CX = 0 to indicate no points or buffers
		;
errorPopFour:
		add	sp, 6			; pop three words
errorPopOne:	
		pop	ax			; and get rid of one more
error:
		clr	bx			; no buffer handle
		mov	cx, bx			; no points
		jmp	exit

		; The points are colinear (or nearly so), so return a very
		; thin arc or ellipse
colinearPop:
		pop	ax			; clean up the stack
colinear:
		push	di			; save CalcEllipseType
		mov	bx, Eframe.EF_conic.C_hBuffer
		call	MemLock			; ax -> output buffer
		mov	es, ax
		call	cs:[simpleRoutines][di]	; create simple ellipse or arc
		mov	ax, EOREGREC		; store buffer terminator
		stosw
		stosw
		call	MemUnlock		; unlock the block
		pop	di			; restore CalcEllipseType
		jmp	done

		; the ellipse is rotated, calc the corners the hard way
handleRotation:
		mov	Eframe.EF_P.P_y, dx	; finish P & Q initialization
		mov	Eframe.EF_Q.P_x, cx
		pop	ax,bx,cx,dx		; restore p2,p4
		call	TransCoordAndDouble	; calc p2,p4
		jc	error
		mov	Eframe.EF_p2.P_x, ax	; save away p2
		mov	Eframe.EF_p2.P_y, bx
		mov	Eframe.EF_p4.P_x, cx	; save away p4
		mov	Eframe.EF_p4.P_y, dx
		mov	ax, Eframe.EF_p3.P_x	; get p3
		mov	bx, Eframe.EF_p3.P_y
		call	AvgTwoCoords		; calculate Q
		add	Eframe.EF_Q.P_x, cx	; save away Q
		add	Eframe.EF_Q.P_y, dx
		mov	ax, Eframe.EF_p3.P_x	; get p3
		mov	bx, Eframe.EF_p3.P_y
		mov	cx, Eframe.EF_p2.P_x	; get p2
		mov	dx, Eframe.EF_p2.P_y
		call	AvgTwoCoords		; calculate P
		add	Eframe.EF_P.P_x, cx	; save away P
		add	Eframe.EF_P.P_y, dx

		; The ellipse routine cannot handle very thin ellipses too
		; well.  So we should figure out how thin it is before we
		; try to draw one, and draw it as if it were colinear if 
		; necessary.
checkTooThin:
		lea	bx, Eframe.EF_p1.P_x
		mov	cx, 2			; check P1 & P2, P2 & P3
checkOuter:
		mov	dx, cx			; store outer loop count => DX
		mov	cx, 2			; inner loop count = 2 (X & Y)
checkInner:
		mov	ax, ss:[bx+0]
		sub	ax, ss:[bx+4]
		jns	checkWidth		; if positive, jump
		neg	ax			; else make it positive
checkWidth:
		cmp	ax, 4			; minimum width is three
		jg	nextOuter
		add	bx, 2			; go to next coordinate
		loop	checkInner		; check y coordinate, or done
		stc				; if we made it here, too thin
		jmp	doTrivialReject		; do trivial rejection, pass CF
nextOuter:
		shl	cx, 1			; either 2 or 1, now 4 or 2
		add	bx, cx			; go to next Point
		mov	cx, dx			; master loop count => CX
		loop	checkOuter
		jmp	doTrivialReject		; do trivial rejection, pass CF
CalcEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EllipseTrivialReject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if ellipse will be drawn

CALLED BY:	INTERNAL
		CalcEllipse

PASS:		EllipseFrame, on stack
		DS	= GState structure
		ES	= window structure

RETURN:		AX	= Ellipse bounding box - left
		CX	= Ellipse bounding box - right
		BX	= Minimum Y value (of ellipse & window bounds)
		DX	= Maximum Y value (of ellipse & window bounds)
		Carry	= SET if trivially rejected

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		check the bounds of the ellipse vs. the window bounds

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version
		jim	12/92		changed to allow no window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EllipseTrivialReject	proc	near
Eframe		local	EllipseFrame
		uses	di, si
		.enter	inherit

		; if there is rotation, then it's a little more involved

		mov	ax, Eframe.EF_p1.P_x		; load up the coords
		mov	bx, Eframe.EF_p1.P_y
		call	TestRotation			; if rotated, use
		jnz	rejectRotation			; ...do more work

		; no rotation.  So we can just check p1 and p3

		mov	cx, Eframe.EF_p3.P_x		; check right last
		mov	dx, Eframe.EF_p3.P_y		; check bottom next
		cmp	ax, cx				; 90,180,270 rotatation?
		jle	checkTopBottom
		xchg	ax, cx				; swap left & ight
checkTopBottom:
		cmp	bx, dx
		jle	checkCoords
		xchg	bx, dx				; swap top & bottom
		
		; save the corners of the ellipse in ConicParams
checkCoords:
		mov	Eframe.EF_conic.C_bounds.R_left, ax ; store the bounds
		mov	Eframe.EF_conic.C_bounds.R_top, bx 
		mov	Eframe.EF_conic.C_bounds.R_right, cx 
		mov	Eframe.EF_conic.C_bounds.R_bottom, dx 

		; turn these back into actual device coordinates. We don't
		; need to worry about rounding, as we had integer device
		; coordinates prior to doubling.

		sar	ax, 1
		sar	bx, 1
		sar	cx, 1
		sar	dx, 1

		; if there is no window, accept the coords

		tst	ds:[GS_window]
		jz	done

		; check the corners in (AX, BX) & (CX, DX)
		
		cmp	ax, es:[W_maskRect].R_right 	; past right edge ?
		jg	rejectEllipse
		cmp	cx, es:[W_maskRect].R_left 	; before left end ?
		jl	rejectEllipse
		mov	di, es:[W_maskRect].R_bottom	; bottom => DI
		mov	si, es:[W_maskRect].R_top 	; top => SI
		cmp	bx, di			 	; past bottom edge ?
		jg	rejectEllipse
		cmp	dx, si			 	; above top end ?
		jl	rejectEllipse
		cmp	bx, si				; compare tops
		jge	checkBottom
		mov	bx, si
checkBottom:
		cmp	dx, di				; compare bottoms
		jle	done
		mov	dx, di
done:
		clc					; no rejection
		jmp	exit				; we're done
rejectEllipse:
		stc					; reject ellipse
exit:
		.leave
		ret

		; there is rotation. sigh.  we have to do some work.  Get
		; the bounds of the entire ellipse by taking min/max of
		; the four corners.
rejectRotation:
		mov	cx, ax				; init min/max
		mov	dx, bx
		mov	si, Eframe.EF_p2.P_x		; get next x
		call	CheckXMinMax			; check this one out
		mov	si, Eframe.EF_p2.P_y		; get next x
		call	CheckYMinMax			; check this one out
		mov	si, Eframe.EF_p3.P_x		; get next x
		call	CheckXMinMax			; check this one out
		mov	si, Eframe.EF_p3.P_y		; get next x
		call	CheckYMinMax			; check this one out
		mov	si, Eframe.EF_p4.P_x		; get next x
		call	CheckXMinMax			; check this one out
		mov	si, Eframe.EF_p4.P_y		; get next x
		call	CheckYMinMax			; check this one out
		jmp	checkCoords
EllipseTrivialReject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConjugateEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the coefficients of the general conic section
		equation, for an ellipse.

CALLED BY:	CalcEllipse

PASS:		EllipseFrame, on stack

RETURN:		carry	- SET if points are colinear

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		This routine handles translating the points defining the
		ellipse into the coefficients of the general equation for
		a conic section, in preparation for calling the CalcConic 
		routine.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	11/91		Re-write to add more precision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ConjugateEllipse proc	near
		uses	bx
Eframe		local	EllipseFrame
		.enter	inherit

		; Calculate the offset to the new coordinate system
		;	
EC <		mov	ax, Eframe.EF_J.P_x				>
EC <		add	ax, Eframe.EF_P.P_x				>
EC <		mov	Eframe.EF_conic.C_xOffset, ax			>
EC <		mov	ax, Eframe.EF_J.P_y				>
EC <		add	ax, Eframe.EF_P.P_y				>
EC <		mov	Eframe.EF_conic.C_yOffset, ax			>

		; Calculate the cross-product (PxQy - QxPy).
		; If this is zero, then the points are colinear.
		;
		mov	ax, Eframe.EF_P.P_x	; PxQy-QxPy
		mov	dx, Eframe.EF_Q.P_y	;
		imul	dx			; dx:ax = PxQy
		movdw	bxcx, dxax		; move to bx:cx
		mov	ax, Eframe.EF_P.P_y	; PxQy-QxPy
		mov	dx, Eframe.EF_Q.P_x	;
		imul	dx			; dx.ax = PyQx
		subdw	bxcx, dxax		; do 32-bit subtract
		mov	ax, cx
		or	ax, bx			; check for valid ellipse
		stc				; assume colinear
		LONG	jz	exit		; if colinear, we're outta here

		; Calculate D =  2 * Qy * CP  &
		;           E = -2 * Qx * CP
		;
		shldw	bxcx			; double the cross-product
		mov	ax, Eframe.EF_Q.P_y	; get Qy
		cwd				; convert to double word
		xchg	ax, cx			; cross-product => BX:AX
		pushdw	bxax
		call	MulSignedDWord		; this will work
		movqw	Eframe.EF_conic.C_D, dxcxbxax
		popdw	bxax
		mov_tr	cx, ax
		mov	ax, Eframe.EF_Q.P_x	; get Qx
		cwd				; sign extend
		xchg	cx, ax
		negdw	bxax
		call	MulSignedDWord		; finish another result
		movqw	Eframe.EF_conic.C_E, dxcxbxax

		; Calculate A = PyPy + QyQy
		;
		mov	ax, Eframe.EF_P.P_y	; grab Py
		mov	dx, ax
		imul	dx
		movdw	Eframe.EF_conic.C_A.HI_lo, dxax	; PyPy => CX:BX
		mov	ax, dx
		cwd
		movdw	Eframe.EF_conic.C_A.HI_hi, dxdx
		mov	ax, Eframe.EF_Q.P_y	; grab Qy
		mov	dx, ax
		imul	dx			; QyQy => DX:AX
		movdw	cxbx, dxax
		mov	ax, dx
		cwd
		mov	ax, dx			; dxaxcxbx
		addqw	Eframe.EF_conic.C_A, dxaxcxbx	; result => Eframe
		

		; Calculate B = -2(PxPy + QxQy)
		;
		mov	ax, Eframe.EF_P.P_x	; grab Px
		mov	dx, Eframe.EF_P.P_y	; grap Py
		imul	dx			; result => DX:AX
		movdw	Eframe.EF_conic.C_B.HI_lo, dxax
		mov	ax, dx
		cwd
		movdw	Eframe.EF_conic.C_B.HI_hi, dxdx
		mov	ax, Eframe.EF_Q.P_x
		mov	dx, Eframe.EF_Q.P_y
		imul	dx			; result => DX:AX
		movdw	cxbx, dxax		; add both partial results
		mov	ax, dx
		cwd				; dxaxcxbx
		mov	ax, dx
		addqw	dxaxcxbx, Eframe.EF_conic.C_B
		negqw	dxaxcxbx		; negate result
		shlqw	dxaxcxbx		; and double it
		movqw	Eframe.EF_conic.C_B, dxaxcxbx

		; Calculate C = PxPx + QxQx
		;
		mov	ax, Eframe.EF_P.P_x	; grab Px
		mov	dx, ax
		imul	dx
		movdw	cxbx, dxax		; PxPx => CX:BX
		mov	ax, dx
		cwd
		movqw	Eframe.EF_conic.C_C, dxdxcxbx

		mov	ax, Eframe.EF_Q.P_x	; grab Qx
		mov	dx, ax
		imul	dx			; QxQx => DX:AX
		movdw	cxbx, dxax		; result => DX:AX
		mov	ax, dx
		cwd
		addqw	Eframe.EF_conic.C_C, dxdxcxbx

		; F is always zero for ellipses
		;
		clr	ax
		clrqw	Eframe.EF_conic.C_F, ax
exit:
		.leave
		ret
ConjugateEllipse endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup to call CalcConic to calculate the points along a 
		full ellipse (ie not an arc).

CALLED BY:	INTERNAL
		CalcEllipse, SetupArcCommon

PASS:		EllipseFrame, on the stack

RETURN:		local	- EllipseFrame, with the following completed
				EF_conic.C_beg
				EF_conic.C_end

DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		This sets up the starting/ending points for the CalcConic
		routine by using the P & J points calculated earlier.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version
		Don	9/91		Just sets beginning & end points now

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupEllipse	proc	near
Eframe		local	EllipseFrame
		.enter	inherit

		; set up the starting and ending points to be the same.  Just
		; choose P, since we have it already

		mov	ax, Eframe.EF_P.P_x		; get x component
		add	ax, Eframe.EF_J.P_x		; make it a real coord
		mov	Eframe.EF_conic.C_beg.P_x, ax	; set it up
		mov	Eframe.EF_conic.C_end.P_x, ax
		mov	ax, Eframe.EF_P.P_y		; get y component
		add	ax, Eframe.EF_J.P_y		; make it a real coord
		mov	Eframe.EF_conic.C_beg.P_y, ax	; set it up
		mov	Eframe.EF_conic.C_end.P_y, ax
		mov	Eframe.EF_conic.C_conicType, CT_ELLIPSE

		.leave
		ret
SetupEllipse	endp


COMMENT $%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup to calculate the points along a partial ellipse
		(an arc) by determining the starting & ending points.

CALLED BY:	INTERNAL
		CalcEllipse

PASS:		local	- EllipseFrame
		ES	- Window segment
		SS:SI	- BoundedArcParams
		DI	- CalcEllipseType

RETURN:		local	- EllipseFrame, with the following completed
				EF_conic.C_beg
				EF_conic.C_end
				EF_conic.C_conicBeg
				EF_conic.C_conicEnd

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		Simply copy the transformed points from the passed structure
		(which are already in device coordinates).

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%$

SetupArc	proc	near
		uses	ds
Eframe		local	EllipseFrame
		.enter	inherit
	
		; Grab the points from the struct, and store in EllipseFrame
		;
		mov	ax, ss:[si].BAP_startPoint.P_x
		mov	bx, ss:[si].BAP_startPoint.P_y	; start Point => (AX,BX)
		mov	cx, ss:[si].BAP_endPoint.P_x
		mov	dx, ss:[si].BAP_endPoint.P_y	; end Point => (CX,DX)
		call	TestFlip			; if we're not flipped
		jnc	finishSetup			; ...then we're done
		xchg	ax, cx				; else swap start/finish
		xchg	bx, dx
finishSetup:
		segmov	ds, ss				; DS:SI => params
		call	SetupArcCommon			; do rest of the work

		.leave
		ret
SetupArc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Setup3PointArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the starting & ending points along 3-point arc.

CALLED BY:	INTERNAL
		CalcEllipse

PASS:		local	- EllipseFrame
		SS:SI	- ThreePointArcParams
		ES	- Window segment
		DI	- CalcEllipseType

RETURN:		local	- EllipseFrame, with the following completed
				EF_conic.C_beg
				EF_conic.C_end
				EF_conic.C_conicBeg
				EF_conic.C_conicEnd

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:
		Simply copy the points from the passed structure, & transform
		to device coordinates.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/ 3/91		Initial version
	jim	12/92		changed to allow no window

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Setup3PointArc	proc	near
		uses	ds, di, si
Eframe		local	EllipseFrame
		.enter	inherit
	
		; Grab the points of the structure, and store in EllipseFrame
		;
		push	di				; save CalcEllType
		mov	di, si
		mov	si, offset GS_TMatrix
		tst	ds:[GS_window]			; check for window
		jz	haveTransform
		segmov	ds, es, ax
		mov	si, offset W_curTMatrix		; ds:si -> TMatrix
haveTransform:
		movwwf	dxcx, ss:[di].TPAP_point2.PF_x	; stored as center 
		movwwf	bxax, ss:[di].TPAP_point2.PF_y	;  in arc code
		call	TransCoordFixed
EC <		ERROR_C	GRAPHICS_CALC_ELLIPSE_SHOULDNT_HAPPEN		>
		movwwf	Eframe.EF_center.PF_x, dxcx
		movwwf	Eframe.EF_center.PF_y, bxax

		movwwf	dxcx, ss:[di].TPAP_point1.PF_x
		movwwf	bxax, ss:[di].TPAP_point1.PF_y
		call	TransCoordFixed
EC <		ERROR_C	GRAPHICS_CALC_ELLIPSE_SHOULDNT_HAPPEN		>
		rndwwf	dxcx
		rndwwf	bxax
		push	dx, bx				; save x1 and y1

		movwwf	dxcx, ss:[di].TPAP_point3.PF_x
		movwwf	bxax, ss:[di].TPAP_point3.PF_y
		call	TransCoordFixed
EC <		ERROR_C	GRAPHICS_CALC_ELLIPSE_SHOULDNT_HAPPEN		>
		rndwwf	dxcx
		rndwwf	bxax
		mov	cx, dx				; setup point3
		mov	dx, bx
		pop	ax, bx				; restore point1
		segmov	ds, ss, si			; ds -> ArcRetType
		mov	si, di				; restore pointer
		pop	di				; restore CalcEllType
		call	SetupArcCommon			; do rest of the work

		.leave
		ret

Setup3PointArc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetupArcCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fill in the ArcReturnParams structure to allow arcs to
		be filled easily

CALLED BY:	SetupArc, Setup3PointArc

PASS:		local	= EllipseFrame
		DS:SI	= ArcReturnParams (empty)
		DI	= CalcEllipseType
		(AX,BX)	= Start Point
		(CX,DX)	= End Point

RETURN:		DS:SI	= ArcReturnParams (filled)

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We do something very interesting here, where we overwrite
		the passed structure to return the start/end/center points
		of an arc. The passed buffer must be large enough to accomodate
		both the passed setup data & ArcReturnParams.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/19/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetupArcCommon	proc	near
Eframe		local	EllipseFrame
		.enter	inherit
	
		; Store the start/end points in the ConicParams
		; and ArcReturnParams structures
		;
		mov	Eframe.EF_conic.C_conicBeg.P_x, ax
		mov	Eframe.EF_conic.C_conicBeg.P_y, bx
		mov	Eframe.EF_conic.C_conicEnd.P_x, cx
		mov	Eframe.EF_conic.C_conicEnd.P_y, dx
		mov	ds:[si].ARP_start.P_x, ax
		mov	ds:[si].ARP_start.P_y, bx
		mov	ds:[si].ARP_end.P_x, cx
		mov	ds:[si].ARP_end.P_y, dx

		; Now get the start/end points for the ellipse,
		; and initialize the arc status values
		;
		call	SetupEllipse
		mov	Eframe.EF_conic.C_conicInfo, CAI_FIND_START
		mov	Eframe.EF_conic.C_conicType, CT_ARC

		; Now deal with the center of the arc
		;
		cmp	di, CET_BOUNDED_ARC_RR		; if rounded-rects
		je	done				; ...don't ret center
		movwwf	bxax, Eframe.EF_center.PF_x	; center.X => BX.AX
		rndwwf	bxax
		mov	ds:[si].ARP_center.P_x, bx
		movwwf	bxax, Eframe.EF_center.PF_y	; center.Y => BX.AX
		rndwwf	bxax
		mov	ds:[si].ARP_center.P_y, bx
done:
		.leave
		ret
SetupArcCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SimpleEllipse
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a simple ellipse - a parallelogram through the
		points tangent to the ellipse

CALLED BY:	CalcEllipse

PASS:		SS:BP	= EllipseFrame
		ES:0	= Point buffer
		CX	= 0

RETURN:		ES:DI	= Past points added to buffer
		CX	= Count of points added to buffer

DESTROYED:	AX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SimpleEllipse	proc	near
Eframe		local	EllipseFrame
		uses	bx
		.enter	inherit
	
		; Some set-up work
		;
		clr	di			; ES:DI => start of point buffer
		mov	dx, Eframe.EF_J.P_x
		mov	si, Eframe.EF_J.P_y

		; Add the point J+P
		;
		mov	ax, Eframe.EF_P.P_x
		mov	bx, Eframe.EF_P.P_y
		call	WriteSimplePoint

		; Add the point J-Q
		;
		mov	ax, Eframe.EF_Q.P_x
		neg	ax
		mov	bx, Eframe.EF_Q.P_y
		neg	bx
		call	WriteSimplePoint

		; Add the point J-P
		;
		mov	ax, Eframe.EF_P.P_x
		neg	ax
		mov	bx, Eframe.EF_P.P_y
		neg	bx
		call	WriteSimplePoint

		; Add the point J+Q
		;
		mov	ax, Eframe.EF_Q.P_x
		mov	bx, Eframe.EF_Q.P_y
		call	WriteSimplePoint

		; Add the point J+P, again, to close the ellipse
		;
		mov	ax, Eframe.EF_P.P_x
		mov	bx, Eframe.EF_P.P_y
		call	WriteSimplePoint

		.leave
		ret
SimpleEllipse	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SimpleArc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a simple ellipse - a parallelogram through the start
		& end points of the arc, and any other points between them
		that are tangent to the ellipse

CALLED BY:	CalcEllipse

PASS:		SS:BP	= EllipseFrame
		ES:0	= Point buffer
		CX	= 0

RETURN:		ES:DI	= Past points added to buffer
		CX	= Count of points added to buffer

DESTROYED:	AX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		We don't properly display an arc drawn with ACT_CHORD
		if the points are colinear, but I doubt that this is
		a big deal.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SimpleArc	proc	near
Eframe		local	EllipseFrame
		.enter	inherit
	
		; Luckily, we don't need to do *anything*. Just ensure
		; that we return CX = 0 (no points), and the code in
		; CloseArc() will do the rest of the work for us.
		;
		clr	di

		.leave
		ret
SimpleArc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utility Routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransCoordAndDouble
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform a two Points from document to device coordinates,
		and double the result

CALLED BY:	INTERNAL

PASS:		DS	= GState segment
		ES	= Window segment (may not be)
		DI	= CalcEllipseFlags
		(AX,BX)	= Point #1
		(CX,DX)	= Point #2

RETURN:		(AX,BX)	= Transformed Point #1
		(CX,DX)	= Transformed Point #2
		Carry	= Set if overflow

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/13/91	Initial version
	Jim	12/92		Changed to allow no window segment
	Jim	2/93		Increased accuracy to avoid rounding problems

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransCoordAndDouble	proc	near
		.enter
	
		test	di, mask CEF_TRANSFORM	; if set, don't transform
		jne	double			; don't transform, just double

		; check for no window.

		tst	ds:[GS_window]		; if no window, use GState
		jz	useGState

		call	GrTransCoord2Far
		jc	done
double:
		shl	ax, 1
		jo	badCoord
		shl	bx, 1
		jo	badCoord
		shl	cx, 1
		jo	badCoord
		shl	dx, 1	
		jo	badCoord
		clc
done:
		.leave
		ret

badCoord:
		stc
		jmp	done

		; there is no window.  Use the GState segment
useGState:
		push	di, bp, si
		mov	si, GS_TMatrix		; use GState matrix to xlate
		mov	bp, cx			; save 2nd coord pair
		mov	di, dx
		call	TransCoordCommonFar
		xchg	bp, ax			; get 2nd, save first pair
		xchg	di, bx
		jc	doneGS
		call	TransCoordCommonFar
		mov	cx, ax			; align all the results in the
		mov	dx, bx			;  right registers
		mov	ax, bp
		mov	bx, di
doneGS:
		pop	di, bp, si
		jc	done
		jmp	double
		
TransCoordAndDouble	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AvgTwoCoords
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the point that is midpoint between two others

CALLED BY:	INTERNAL

PASS:		(AX,BX)	= Point #1
		(CX,DX)	= Point #2

RETURN:		(CX,DX)	= Midpoint between #1 & #2

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		just take 1/2 the distance between

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AvgTwoCoords	proc	near
		.enter

		sub	cx, ax			; x difference => CX
		sar	cx, 1			; x/2 => CX
		sub	dx, bx			; y difference => CX
		sar	dx, 1			; y/2 => CX
		add	cx, ax			; round as well
		add	dx, bx			; y' => DX

		.leave
		ret
AvgTwoCoords	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckXMinMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if X is a minimum or a maximum

CALLED BY:	EllipseTrivialReject

PASS:		ax	- current minimum
		cx	- current maximum
		si	- new coordinate

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckXMinMax	proc	near
		cmp	ax, si				; check for new min/max
		jl	checkxmax
		mov	ax, si				; done
exit:
		ret
checkxmax:
		cmp	cx, si				; check high end
		jge	exit
		mov	cx, si
		ret
CheckXMinMax	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckYMinMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if Y is a minimum or a maximum

CALLED BY:	EllipseTrivialReject

PASS:		bx	- current minimum
		dx	- current maximum
		si	- new coordinate

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	9/10/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckYMinMax	proc	near
		cmp	bx, si				; check for new min/max
		jl	checkymax
		mov	bx, si				; done
exit:
		ret
checkymax:
		cmp	dx, si				; check high end
		jge	exit
		mov	dx, si
		ret
CheckYMinMax	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulSignedDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Multiply two DWord's together, yielding a dword

CALLED BY:	INTERNAL

PASS:		BX:AX	- 32-bit signed dword 	(mulitplier)
     		DX:CX	- 32-bit signed dword	(multiplicand)

RETURN:		DX:CX:BX:AX	- 64-bit signed result

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MulSignedDWord	proc	near
		uses	si,di
multiplicand	local	dword
result		local	HugeInt
		.enter

		movqw	result, 0		; initialize it
		mov	si, dx			; si = negate flag
		xor	si, bx

		; check each operand, make sure both are positive

		tst	dx			; check multiplicand
		jns	checkMultiplier		;  nope, continue
		negdw	dxcx			; do 32-bit negate
checkMultiplier:
		tst	bx			; check multiplier
		jns	doUnsignedMul		;  nope, straight to mul
		negdw	bxax			; do 32-bit negate

		; now we have two unsigned factors.  Do the multiply
doUnsignedMul:
		xchg	ax, cx			; dx.ax = multiplicand
						; bx.cx = mulitplier
		mov	multiplicand.low, ax 	; save away one factor
		mov	multiplicand.high, dx
		mul	cx			; multiply low factors
		movdw	result.HI_lo, dxax      ; save away partial result
		mov	ax, multiplicand.high	; get next victim
		mul	cx
		add	result.HI_lo.high, ax
		adc	result.HI_hi.low, dx
		mov	ax, multiplicand.low	; continue with partial results
		mul	bx
		add	result.HI_lo.high, ax	; finish off calc
		adc	result.HI_hi.low, dx
		mov	ax, multiplicand.high	; do highest
		mul	bx					
		adddw	result.HI_hi, dxax

		; all done with multiply, set up result regs

		movqw	dxcxbxax, result	; grab result

		; multiply is done, check to see if we have to negate the res

		tst	si			; see if result is negative
		jns	done			;  nope, exit
		negqw	dxcxbxax		;  yes, do it
done:
		.leave
		ret
MulSignedDWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestRotation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Equivalent of test es:[W_curTMatrix], TM_ROTATED, except
		handles case of Window not existing

CALLED BY:	INTERNAL

PASS:		DS	= GState segment
		ES	= Window segment (if present)

RETURN:		Z flag	= Set if not rotated, clear if rotated

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TestRotation	proc	near
		.enter
	
		tst	ds:[GS_window]		; may not be a window
		jnz	checkRotation
		test	ds:[GS_TMatrix].TM_flags, TM_ROTATED
		jmp	done
checkRotation:
		test	es:[W_curTMatrix].TM_flags, TM_ROTATED
done:
		.leave
		ret
TestRotation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TestFlip
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Test to see if the transformation matrix indicates that
		the coordinate system is in some way flipped, meaning
		that we'd need to exchange the start/end points for an
		arc.

PASS:		DS	= GState segment
		ES	= Window segment (if present)

RETURN:		Carry	= Set if not flipped, clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		* Transform two vector, #1-(1,1) & #2-(-1,1)
		* If #1 is after (clockwise) #2, no flip
		* If #1 is before (clockwise) #2, flip
		* Else error

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/17/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TestFlip	proc	far
		uses	ax, bx, cx, dx
		.enter
	
		; Calculate octant for vector #1
		;
		mov	dx, 1
		mov	bx, dx			; original vector = (1, 1)
		call	transCoord		; result -> (DX.CX, BX.AX)
		call	PointToOctant
		push	ax			; save the octant number

		; Calculate octant for vector #2
		;
		mov	dx, -1
		mov	bx, 1			; original vector = (-1, 1)
		call	transCoord		; result -> (DX.CX, BX.AX)
		call	PointToOctant		; octant #2 => AX
		pop	bx			; octant #1 => BX

		; Determine direction of resulting vector. If the difference
		; is 4 or less, than no flip has ocurred. This translates to:
		;	-4 <= result <= 0
		;	 4 <= result
		;
		sub	bx, ax
		jle	negative
		cmp	bx, 4			; if difference less than 4
		jl	flip			; ...than we have a flip
noFlip:
		clc
		jmp	done
negative:
		cmp	bx, -4			; if difference greater than 4
		jge	noFlip			; ...then we don't have a flip
flip:
		stc
done:
		.leave
		ret

		; Tranform a coordinate, except ignore any X or Y offset
		; in the translate matrix (elements TM_31 & TM_32). The
		; result of this calculate is a WWFixed.
transCoord:
		push	di, si, ds, es
		mov	si, offset GS_TMatrix
		tst	ds:[GS_window]		; if no window, use GState
		jz	doTransform
		segmov	ds, es
		mov	si, offset W_curTMatrix
doTransform:
		clr	ax, cx			; fractions = 0
		test	ds:[si].TM_flags, TM_COMPLEX
		jz	doneTransform		; if not complex, we're done
		call	TransCoordFixedComplex	; result -> (DX.CX, BX.AX)
doneTransform:
		pop	di, si, ds, es
		retn
TestFlip	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PointToOctant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a point to an octant

CALLED BY:	INTERNAL
		CalcOctant

PASS:		DX.CX	= X coordinate
		BX.AX	= Y coordinate

RETURN:		AX	= Octant number (1-8)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Stolen from GetOctant (see comments there)

		Octants are numbered rather bizarrely:

			    \ 1 | 8 /
			     \  |  /
			      \ | / 
			    2  \|/  7
			    ---------
			    3  /|\  6
			      / | \
			     /  |  \
			    / 4 | 5 \

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version
		Don	04/94		Modified for another use

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PointToOctant	proc	near
		.enter	inherit

		tst	dx			; check sign on x component
		js	xcompNeg		; binary search for correct case
		tst	bx			; check sign on y component
		jns	case2

		; case 1: xcomp>0, ycomp<0

		negwwf	bxax			; negate Y coord

		; if xcomp > abs(ycomp) octant is 6 else 5

		cmpwwf	dxcx, bxax
		mov	ax, 5
		jbe	done
		jmp	oneMore

		; case 2: xcomp>0,ycomp>0
case2:
		cmpwwf	dxcx, bxax
		mov	ax, 7			; either octant 7 or 8
		jae	done
		jmp	oneMore

		; xcomponent is negative, either case 3 or 4
xcompNeg:
		negwwf	dxcx
		tst	bx			; test sign of ycomp
		jns	case4			; found it

		; case 3: xcomp<0, ycomp<0

		negwwf	bxax
		cmpwwf	dxcx, bxax		; abs(xcomp) greater ?
		mov	ax, 3
		jae	done
		jmp	oneMore

		; case 4: xcomp<0, ycomp>0
case4:
		cmpwwf	dxcx, bxax		; xcomp greater ?
		mov	ax, 1
		jbe	done
oneMore:
		inc	ax
done:
		.leave
		ret
PointToOctant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WriteSimplePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates and writes a point to a point buffer

CALLED BY:	SimpleEllipseLow

PASS:		(AX,BX)	= Offset from center
		(DX,SI)	= Center of arc/ellipse
		ES:DI	= Point buffer
		CX	= Current Point count

RETURN:		ES:DI	= Point buffer (updated)
		CX	= Incremeneted Point count

DESTROYED:	AX, BX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	4/19/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

WriteSimplePoint	proc	near
		.enter

		; Calculate the point, and write it to the buffer
		;		
		add	ax, dx
		sar	ax, 1
		stosw
		mov_tr	ax, bx
		add	ax, si
		sar	ax, 1
		stosw
		inc	cx

		.leave
		ret
WriteSimplePoint	endp

GraphicsCalcEllipse	ends
