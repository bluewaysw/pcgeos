COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KLib
FILE:		Graphics/graphicsCalcConic.asm

AUTHOR:		Jim DeFrisco, 29 July 1990

ROUTINES:
	Name			Description
	----			-----------
	CalcConic		General purpose conic section calculation

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	7/27/90		Initial revision


DESCRIPTION:
	This module holds the code to calculate the points on any conic
	section.  The code is based on an algorithm presented in "Computer
	Graphics, Principles and Practice" (Foley, van Dam, Feiner, Hughes)
	page 958.
		
	The constant CALC_CONIC_START_ANYWHERE is used to separate code
	that is currently not used, as a conic is scan-converted always
	using the point found at 0 degrees (on the x-axis). This is done
	to avoid some masty problems with starting on a point that is not
	quite on an ellipse this algorithm computes. If one wanted to use
	this code again (which does work & was thouroughly tested), remove
	the EC code prior to each ifdef (the EC code ensure our assertion
	is valid), and define the constant.

	$Id: graphicsCalcConic.asm,v 1.1 97/04/05 01:13:19 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsCalcConic	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcConic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the set of visible points along a conic section

CALLED BY:	GLOBAL
		CalcFullEllipse

PASS:		ss:si		- pointer to ConicParams structure (filled out)

RETURN:		cx		- number of points in returned buffer

DESTROYED:	ax,bx,dx,di

PSEUDO CODE/STRATEGY:
		This routine calculates the points along an arbitrary conic
		section, given the coefficients of the equation
			S(x,y) = Ax^2 + Bxy + Cy^2 + Dx + Ey + F = 0
		and two points on the conic section.  The routine will 
		return a set of (possibly) disjoint polyline segments in a
		supplied buffer.  The set may be disjoint due to the ability
		to limit the search to just part of the coordinate space.
		This limitation is intended be set to the top and bottom of
		the window.

		There is a problem with this algorithm with very thin ellipses.
		Basically, the one-pixel jump to the next part of the ellipse
		may end up jumping over to the other side of the ellipse,
		skipping a few octants in the process.  The algorithm then
		gets all confused, and marches off into the sunset.  We can
		detect these crossings by keeping track of the gradient vector
		at each point on the curve.  The gradient (a vector pointing 
		perpendicular to the curve at that point) will change radically
		if we cross over to the other side of the ellipse.  There
		are separate tests for each octant

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

		; local stack frame for conic section algorithm
ConicFrame	struct	
		; the following are the decision variables used by the Conic
		; routine, along with other misc variables
    CF_d	HugeInt		; main decision variable
    CF_u	HugeInt		; used to update d on square moves
    CF_v	HugeInt		; used to update d on diagonal moves
    CF_k1	HugeInt		; used to update u on square moves
    CF_k2	HugeInt		; used to update u on diag moves and v on square
    CF_k3	HugeInt		; used to update v on diag moves
    CF_dSdx	HugeInt		; x component of gradient vector
    CF_dSdy	HugeInt		; y component of gradient vector
    CF_octCount	word		; octant count
    CF_octant	word		; current octant
    CF_curr	Point		; current point
    CF_last	Point		; last point 
    CF_orig	Point		; first point in current series
    CF_dir	Point		; direction of last pair
    CF_bufPoints word		; #points in buffer
    CF_bufPtr	word		; #bytes left in buffer
    CF_dxsquare	word		; square move x offset
    CF_dysquare	word		; square move y offset
    CF_dxdiag	word		; diag move x offset
    CF_dydiag	word		; diag move y offset
		; specific variables for arcs
    CF_arcDiff	word		; difference between start or end and current
    CF_arcLast	Point		; last point checked when searching for start
ConicFrame	ends


CalcConic	proc	far
		uses	ds, es
Cframe		local	ConicFrame
		.enter

		; first, set up ds:si -> passed parameters.  Also, lock the
		; passed output buffer and set up es -> buffer

		segmov	ds, ss, ax		; ds:si -> ConicParams
		mov	bx, ds:[si].C_hBuffer	; get handle of output buffer
		call	MemLock			; lock it down
		mov	es, ax			; es -> buffer
		clr	Cframe.CF_bufPoints	; start out with no points

		; Get the starting octant number and init everything

		mov	cx, ds:[si].C_beg.P_x
		mov	dx, ds:[si].C_beg.P_y	; starting Point => (CX, DX)
		call	CalcOctant		; starting octant => BX
		mov	Cframe.CF_octant, bx	; save octant #
		mov	Cframe.CF_octCount, 8	; assume we're doing them all
		tst	ds:[si].C_conicType	; if we're an ellipse.
		jz	initConic		; ...this assumption is correct
		mov	Cframe.CF_octCount, 16	; ...else we might need to go
						; ...around the circle twice.
initConic:
		shl	bx, 1			; make it a word
		call	cs:InitConic[bx]	; call right init routine

		; if the starting and ending points are the same, then we're
		; doing all eight octants.  Otherwise, calc how many to do

		mov	Cframe.CF_bufPtr, 0	; init buffer pointer	
		mov	ax, EOREGREC		; init to NULL
		mov	Cframe.CF_arcDiff, ax	; init arc differential value
		mov	Cframe.CF_orig.P_x, ax	; init current point
		mov	Cframe.CF_last.P_x, ax
		mov	Cframe.CF_orig.P_y, ax	; init current point
		mov	Cframe.CF_last.P_y, ax
		mov	ax, ds:[si].C_beg.P_x	; initalize starting position
		mov	Cframe.CF_curr.P_x, ax
		mov	bx, ds:[si].C_beg.P_y
		mov	Cframe.CF_curr.P_y, bx
EC <		mov	cx, ds:[si].C_end.P_x				>
EC <		mov	dx, ds:[si].C_end.P_y				>
EC <		sub	ax, cx			; X difference => AX	>
EC <		sub	bx, dx			; Y difference => BX	>
EC <		or	ax, bx			; any difference => AX	>
EC <		ERROR_NE GRAPHICS_CALC_CONIC_ASSUMES_0_DEGREE_START_END	>
ifdef		CALC_CONIC_START_ANYWHERE
		jz	nextOctant		; if no difference,start drawing
		call	CalcOctantCount		; octant count => BX
		mov	Cframe.CF_octCount, bx	; save octant count
		jmp	nextOctant
endif

		; have #octants calculated.  Start drawing.
nextOctantLoop:
		mov	bx, Cframe.CF_octant	; current octant => BX
		and	bx, 1			; odd or even ?
		shl	bx, 1			; make it a table index
		call	cs:DrawOctant[bx]	; draw this one completely
		jc	abortShort
		mov	bx, Cframe.CF_octant	; get current octant
		sub	bx, 1			; bump to next one
		ja	octOK
		add	bx, 8
octOK:
		mov	Cframe.CF_octant, bx	; update current octant
		dec	Cframe.CF_octCount	; any more to do ?
		jnz	nextOctantLoop

		; OK, we've entered the final octant.  Keep drawing til it's
		; done.  But only if we're not done yet.  We allow ourselves
		; to be within two pixels of the ending point before proceeding
		; to the next octant. It's a hack, but it seems to work :)

		mov	ax, Cframe.CF_curr.P_x	; are we at the end ?
		sub	ax, ds:[si].C_end.P_x	; get ending coord
		jg	checkX
		neg	ax
checkX:
		cmp	ax, END_POINT_DELTA	; if larger than delta value
		ja	doLastOctant		; ...then proceed to next octant
		mov	ax, Cframe.CF_curr.P_y	; are we at the end ?
		sub	ax, ds:[si].C_end.P_y	; get ending coord
		jg	checkY
		neg	ax
checkY:
		cmp	ax, END_POINT_DELTA	; if within delta value
		jbe	done			; ...then we're done
doLastOctant:
		mov	bx, Cframe.CF_octant	; get current octant
		and	bx, 1			; odd or even ?
		shl	bx, 1			; make it a table index
		call	cs:DrawOctant[bx]	; draw this one completely
abortShort:
		jc	abort

		; all done.  all that is left is to calc the #points in buffer
		; first stick in the last point and the closing EOREGRECs
done:
		mov	ax, ds:[si].C_end.P_x	; get ending coord
		mov	Cframe.CF_curr.P_x, ax	; set the final position
		mov	ax, ds:[si].C_end.P_y	; get ending coord
		mov	Cframe.CF_curr.P_y, ax	; set the final position
		mov	al, 1			; add final point
		call	AddPoint

		; return the block handle & number of Points, after
		; re-allocating the block downward in size to hold only
		; the points that were calculated.
cleanUp:
		mov	ax, Cframe.CF_bufPoints	; number of points => AX
		mov	dx, ax
		shl	ax, 1			; 2 * num point
		shl	ax, 1			; 4 * num points
EC <		mov	bx, ax						>
EC <		cmp	es:[bx].P_x, EOREGREC	; terminated properly?	>
EC <		ERROR_NE	GRAPHICS_CALC_CONIC_INVALID_POLYLINE	>
EC <		cmp	es:[bx].P_y, EOREGREC	; terminated properly?	>
EC <		ERROR_NE	GRAPHICS_CALC_CONIC_INVALID_POLYLINE	>
		mov	bx, ds:[si].C_hBuffer	; buffer handle => BX
		call	MemUnlock		; unlock points buffer
		add	ax, 3 * (size Point)	; room for EOREGREC's,start,end
		clr	ch
		call	MemReAlloc		; reallocate block downward
		mov	cx, dx			; number of points => CX

		.leave
		ret

		; For whatever reason, our code has gone astray and we've
		; overflowed the buffer. Under EC, we will have FatalError'ed,
		; but we don't want to crash the system just because we
		; couldn't draw a lousy ellipse. So we'll return zero points
abort:
		clr	Cframe.CF_bufPoints
		mov	{word} es:[0], EOREGREC
		mov	{word} es:[2], EOREGREC
		jmp	cleanUp
CalcConic	endp

END_POINT_DELTA	equ	2

		; these are a few jump tables (call tables, actually) used
		; by CalcConic to init/draw the conic section algorithm
InitConic	label	nptr
		nptr	0		; there is no 0th octant
		nptr	InitOctant1	
		nptr	InitOctant2
		nptr	InitOctant3
		nptr	InitOctant4
		nptr	InitOctant5
		nptr	InitOctant6
		nptr	InitOctant7
		nptr	InitOctant8

DrawOctant	label	nptr
		nptr	DrawEvenOctant	; even numbered ones
		nptr	DrawOddOctant	; even numbered ones


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcOctantCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the number of octants that we need to draw through

CALLED BY:	CalcConic

PASS:		local	= ConicFrame structure on stack
		DS:SI	= ConicParams
		(CX,DX)	= Point on arc

RETURN:		BX	= Octant count

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef		CALC_CONIC_START_ANYWHERE
CalcOctantCount	proc	near
Cframe		local	ConicFrame
		.enter	inherit
	
		; First calculate the octant, and then find difference
		;
		call	CalcOctant		; ending octant => BX
		sub	bx, Cframe.CF_octant	; subtract first one
		neg	bx			; want first-last
		je	endInSameOctant		; deal with ending in same oct
		jg	done			; if positive, jump
		add	bx, 8			; there are 8 octants
done:
		inc	bx

		.leave
		ret
	
		; We're ending in the same octant. Should we have a count
		; of 0 or 8? If end is "after" (< 180) begin, then 0. If
		; it is "before" (> 180), then 8.
		;
endInSameOctant:
		mov	bx, Cframe.CF_octant	; octant # => BX
		shr	bx, 1
		dec	bx			; 0 = 180 to 270, 1 =  90 to 180
		mov	bh, bl			; 2 =   0 to  90, 3 = 270 to 360

		; Try to determine using the horizontal difference
		;
		mov	ax, ds:[si].C_end.P_x
		sub	ax, ds:[si].C_beg.P_x	; horizontal difference => AX
		xor	bl, 0x3			; above or below x-axis ??
		jnz	doXTest			; jump if above
		neg	ax
doXTest:
		tst	ax			; check X difference
		jl	zeroOctants		; if left (right), zero
		jg	eightOctants		; if right (left), eight

		; Darn - we need to check the vertical difference
		;
		mov	ax, ds:[si].C_end.P_y
		sub	ax, ds:[si].C_beg.P_y	; vertical difference => AX
		test	bh, 0x2			; left or right of y-axis ??
		jnz	doYTest			; jump if right
		neg	ax
doYTest:
		tst	ax			; check Y difference
		jl	zeroOctants		; if above (below), zero
EC <		ERROR_E	GRAPHICS_ELLIPSE_START_END_MUST_BE_DIFFERENT	>
eightOctants:
		mov	bx, 8
		jmp	done
zeroOctants:
		clr	bx
		jmp	done
CalcOctantCount	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcOctant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the number of octants we have to traverse

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame	- local structure on stack
		ds:si 		- ptr to ConicParams
		(cx, dx)	- Point on the ellipse or arc

RETURN:		bx		- octant in which Point resides

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
		Calculate the number of octants we will transverse

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcOctant	proc	near
Cframe		local	ConicFrame
		uses	di
		.enter	inherit

		; First we must muck with the points to get them into
		; the appropriate coordinate system (0 degrees is at (0,0)

EC <		sub	cx, ds:[si].C_xOffset	; x coordinate in new C.S.>
EC <		sub	dx, ds:[si].C_yOffset	; y coordinate in new C.S.>

		; calculate the gradient vector
		; dSdx = (2 * A * x) + (B * y) + D
		; dSdy = (B * x) + (2 * C * y) + E

		movqw	Cframe.CF_dSdx, ds:[si].C_D, ax	; init dSdx = D
		movqw	Cframe.CF_dSdy, ds:[si].C_E, ax	; init dSdy = E

EC <		tst	cx			; need this to be zero	>
EC <		ERROR_NZ GRAPHICS_CALC_CONIC_ASSUMES_0_DEGREE_START_END	>
EC <		tst	dx			; need this to be zero >
EC <		ERROR_NZ GRAPHICS_CALC_CONIC_ASSUMES_0_DEGREE_START_END	>

ifdef		CALC_CONIC_START_ANYWHERE
		; calculate the x component

		push	dx			; save y difference
		mov	ax, cx
		tst	ax			; any x part to calc ?
		jz	calcY			; if zero, do y part
		mov	di, ax			; save x position
		cwd				; get doubleword
		saldw	dxax			; x * 2  
		mov	bx, dx			; bx.ax = 2*x
		movdw	dxcx, ds:[si].C_A	; dx.cx = A
		call	MulSDWord		; do 32 bit mulitply
		adddw	Cframe.CF_dSdx, dxcx	; add in partial result
		mov	ax, di			; restore x
		cwd				; make it a dword
		mov	bx, dx			; bx.ax = x
		movdw	dxcx, ds:[si].C_B	; get B
		call	MulSDWord		; do 32 bit mulitply
		adddw	Cframe.CF_dSdy, dxcx	; add in partial result

		; finished using x, now do y part for both equations
calcY:
		pop	ax			; restore y
		tst	ax			; zero ?
		jz	doneY			;  yes, all done
		mov	di, ax			; save y
		cwd				; get doubleword
		saldw	dxax			; y * 2  
		mov	bx, dx			; bx.ax = 2*x
		movdw	dxcx, ds:[si].C_C	; get C
		call	MulSDWord		; do 32 bit mulitply
		adddw	Cframe.CF_dSdy, dxcx	; add in partial result
		mov	ax, di			; restore y
		cwd				; make it a dword
		mov	bx, dx			; bx.ax = y
		movdw	dxcx, ds:[si].C_B	; get B
		call	MulSDWord		; do 32 bit mulitply
		adddw	Cframe.CF_dSdx, dxcx	; add in partial result
doneY:
endif
		; now that we have both parts of gradient calculated, 
		; use them to determine the ending octant

		call	GetOctant		; bx = octant

		.leave
		ret
CalcOctant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOctant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find out which octant a certain part of the conic is in

CALLED BY:	INTERNAL
		CalcOctant

PASS:		Cframe		- inherited locals.  dSdx, dSdy are x and y
				  components of gradient vector

RETURN:		bx		- octant number (1-8)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		if (xcomp > 0) & (ycomp < 0)		{case 1}
		    if xcomp < -ycomp
			return(5)
		    else
			return(6)
		elseif (xcomp > 0) & (ycomp > 0)	{case 2}
		    if xcomp < ycomp
			return(8)
		    else
			return(7)
		elseif (xcomp < 0) & (ycomp < 0)	{case 3}
		    if -xcomp < -ycomp
			return(4)
		    else
			return(3)
		elseif (xcomp < 0) & (ycomp > 0)	{case 4}
		    if -xcomp < ycomp
			return(1)
		    else
			return(2)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetOctant	proc	near
		uses	ax,cx,dx
Cframe		local	ConicFrame
		.enter	inherit

		movqw	dxcxbxax, Cframe.CF_dSdx ; load x component

		tst	dx		; check sign on x component
		js	xcompNeg	; binary search for correct case
		tst	Cframe.CF_dSdy.HI_hi.high ; check sign on y component
		jns	case2

		; case 1: xcomp>0, ycomp<0

		movqw	dxcxbxax, Cframe.CF_dSdy ; load y component
		negqw	dxcxbxax

		; if xcomp > abs(ycomp) octant is 6 else 5

		cmpqw	Cframe.CF_dSdx, dxcxbxax 
		mov	bx, 5
		LONG jbe done
		jmp	oneMore

		; case 2: xcomp>0,ycomp>0
case2:
		cmpqw	dxcxbxax, Cframe.CF_dSdy
		mov	bx, 7		; either octant 7 or 8
		LONG jae done
		jmp	oneMore

		; xcomponent is negative, either case 3 or 4
xcompNeg:
		negqw	dxcxbxax
		tst	Cframe.CF_dSdy.HI_hi.high	; test sign of ycomp
		jns	case4		; found it

		; case 3: xcomp<0, ycomp<0

		negqw	Cframe.CF_dSdy
		cmpqw	dxcxbxax, Cframe.CF_dSdy	; abs(xcomp) greater ?
		mov	bx, 3
		jae	doneNegY
		inc	bx
doneNegY:
		negqw	Cframe.CF_dSdy
		jmp	done

		; case 4: xcomp<0, ycomp>0
case4:
		cmpqw	dxcxbxax, Cframe.CF_dSdy	; xcomp greater ?
		mov	bx, 1
		jbe	done
oneMore:
		inc	bx
done:
		.leave
		ret
GetOctant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 1

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 1.
			k1 = 2A
			k2 = k1 + B
			k3 = k2 + B + 2C
			 u = A + B/2 + D
			 v = u + E
			 d = A + B/2 + D + C/4 + E/2

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant1	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_A
		addqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_u, dxdibxax
		movqw	Cframe.CF_d, dxdibxax	; save partial result
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		rcr	cl, 1
		addqw	Cframe.CF_d, dxdibxax	; d = A+D+B/2 (no carry)
		mov	ch, cl
		rcl	ch, 1			; restore carry, leave cl alone
		adcqw	dxdibxax, Cframe.CF_u
		movqw	Cframe.CF_u, dxdibxax

		; Now calculate v
		;
		addqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		clr	ch
		movqw	dxdibxax, ds:[si].C_E
		sarqw	dxdibxax		; calc E/2
		rcr	ch, 1			; cl holds fraction
		add	cl, ch			; combine fractions
		adcqw	Cframe.CF_d, dxdibxax	; Cframe.CF_d= A+D+B/2 + E/2
		clr	cx			; init other frac again
		movqw	dxdibxax, ds:[si].C_C

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 2

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 2
			k1 = 2C
			k2 = k1 + B
			k3 = k2 + B + 2A
			 u = B/2 + C + E
			 v = u + D
			 d = u + A/4 + D/2

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant2	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_C
		addqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_u, dxdibxax
		movqw	Cframe.CF_d, dxdibxax
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		rcr	cl, 1
		addqw	Cframe.CF_d, dxdibxax	; d = C+E+B/2 (no carry)
		mov	ch, cl
		rcl	ch, 1			; restore carry, leave cl alone
		adcqw	dxdibxax, Cframe.CF_u
		movqw	Cframe.CF_u, dxdibxax

		; Now calculate v
		;
		addqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		clr	ch
		movqw	dxdibxax, ds:[si].C_D
		sarqw	dxdibxax		; calc D/2
		rcr	ch, 1			; cl holds fraction
		add	cl, ch			; combine fractions
		adcqw	Cframe.CF_d, dxdibxax	; d = C+E+B/2 + D/2
		clr	cx			; init other frac again
		movqw	dxdibxax, ds:[si].C_A

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 3

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 3
			k1 = 2C
			k2 = k1 - B
			k3 = k2 - B + 2A
			 u = C - B/2 + E
			 d = u + A/4 - D/2
			 v = u - D

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant3	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_C
		addqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_u, dxdibxax
		movqw	Cframe.CF_d, dxdibxax	; store d (partial)
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		rcr	cl, 1
		subqw	Cframe.CF_d, dxdibxax
		mov	ch, cl
		rcl	ch, 1			; restore carry, leave cl alone
		sbbqw	Cframe.CF_u, dxdibxax	; store u
		movqw	dxdibxax, Cframe.CF_u

		; Now calculate v
		;
		subqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		clr	ch
		movqw	dxdibxax, ds:[si].C_D
		sarqw	dxdibxax		; calc D/2
		rcr	ch, 1			; cl holds fraction
		add	ch, cl			; combine fractions
		sbbqw	Cframe.CF_d, dxdibxax	; bx.ax = C+E-B/2 - D/2
		clr	cx			; init other frac again
		movqw	dxdibxax, ds:[si].C_A

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant3	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 4

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 4
			k1 = 2A
			k2 = k1 - B
			k3 = k2 - B + 2C
			 u = A - B/2 - D
			 d = u + C/4 + E/2
			 v = u + E

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant4	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_A
		subqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_u, dxdibxax
		movqw	Cframe.CF_d, dxdibxax	; add & round with carry bit
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		rcr	cl, 1
		subqw	Cframe.CF_d, dxdibxax	; 
		mov	ch, cl
		rcl	ch, 1			; restore carry, leave cl alone
		sbbqw	Cframe.CF_u, dxdibxax	; add & round with carry bit
		movqw	dxdibxax, Cframe.CF_u

		; Now calculate v
		;
		addqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		movqw	dxdibxax, ds:[si].C_E
		sarqw	dxdibxax		; calc E/2
		adcqw	Cframe.CF_d, dxdibxax	; bx.ax = A-D-B/2 + E/2
		clr	ch
		movqw	dxdibxax, ds:[si].C_C

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant4	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 5

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 5
			k1 = 2A
			k2 = k1 + B
			k3 = k2 + B + 2C
			 u = A + B/2 - D
			 d = u + C/4 - E/2
			 v = u - E

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant5	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_A
		subqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_u, dxdibxax
		movqw	Cframe.CF_d, dxdibxax	; store d (partial)
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		rcr	cl, 1
		addqw	Cframe.CF_d, dxdibxax
		mov	ch, cl
		rcl	ch, 1
		adcqw	dxdibxax, Cframe.CF_u	; add & round with carry bit
		movqw	Cframe.CF_u, dxdibxax	; store u

		; Now calculate v
		;
		subqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		movqw	dxdibxax, ds:[si].C_E
		sarqw	dxdibxax		; calc E/2
		sbbqw	Cframe.CF_d, dxdibxax	; bx.ax = A-D+B/2 - E/2
		clr	ch
		movqw	dxdibxax, ds:[si].C_C

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant5	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 6

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 6
			k1 = 2C
			k2 = k1 + B
			k3 = k2 + B + 2A
			 u = C + B/2 - E
			 d = u + A/4 - D/2
			 v = u - D

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant6	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_C
		subqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_u, dxdibxax
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		adcqw	dxdibxax, Cframe.CF_u	; add & round with carry bit
		movqw	Cframe.CF_u, dxdibxax	; store u
		movqw	Cframe.CF_d, dxdibxax	; store d (partial)

		; Now calculate v
		;
		subqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		movqw	dxdibxax, ds:[si].C_D
		sarqw	dxdibxax		; calc D/2
		sbbqw	Cframe.CF_d, dxdibxax	; bx.ax = C-E+B/2 - D/2
		movqw	dxdibxax, ds:[si].C_A

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant6	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant7
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 7

CALLED BY:	INTERNAL
		CalcConic
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 7
			k1 = 2C
			k2 = k1 - B
			k3 = k2 - B + 2A
			 u = C - B/2 - E
			 d = u + A/4 + D/2
			 v = u + D

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant7	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_C
		subqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_u, dxdibxax
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		sbbqw	Cframe.CF_u, dxdibxax	; add & round with carry bit
		movqw	dxdibxax, Cframe.CF_u	; store u
		movqw	Cframe.CF_d, dxdibxax	; store d (partial)

		; Now calculate v
		;
		addqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		movqw	dxdibxax, ds:[si].C_D
		sarqw	dxdibxax		; calc D/2
		adcqw	Cframe.CF_d, dxdibxax	; bx.ax = A-E-B/2 + D/2
		movqw	dxdibxax, ds:[si].C_A

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant7	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitOctant8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do initialization for octant 8

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Initialize the algorithm for starting in octant 8
			k1 = 2A
			k2 = k1 - B
			k3 = k2 - B + 2C
			 u = A - B/2 + D
			 d = u + C/4 - E/2
			 v = u - E

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitOctant8	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; First, calculate u
		;
		clr	cx
		movqw	dxdibxax, ds:[si].C_A
		addqw	dxdibxax, ds:[si].C_D
		movqw	Cframe.CF_u, dxdibxax
		movqw	dxdibxax, ds:[si].C_B
		sarqw	dxdibxax		; divide B by 2
		sbbqw	Cframe.CF_u, dxdibxax	; add & round with carry bit
		movqw	dxdibxax, Cframe.CF_u	; add & round with carry bit
		movqw	Cframe.CF_d, dxdibxax	; store d (partial)

		; Now calculate v
		;
		subqw	dxdibxax, ds:[si].C_E
		movqw	Cframe.CF_v, dxdibxax	; store v

		; Next calculate d.  We need to accumulate carries when we're
		; adding in the fractions, so use cl & ch as a depository
		;
		movqw	dxdibxax, ds:[si].C_E
		sarqw	dxdibxax
		sbbqw	Cframe.CF_d, dxdibxax
		movqw	dxdibxax, ds:[si].C_C

		; Finally, finish calculating d, & evaluate everything else
		;
		GOTO	EvaluateOctant		; do the rest of the work

		.leave	.UNREACHED
InitOctant8	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EvaluateOctant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete the calculations for initializing an octant

CALLED BY:	InitOctant*

PASS:		ConicFrame on stack
		DS:SI	= ConicParams
		DXDIBXAX = A or C
		CL	= Carry depository

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:
		The calculations of the offsets and the k values for
		each octant are very similar. Use the tables below to
		hold information that distinguishes each octant

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Tables for the values of the offsets for each octant
;
sqreDeltaX	word	 1,  0,  0, -1, -1,  0,  0,  1
sqreDeltaY	word	 0,  1,  1,  0,  0, -1, -1,  0
diagDeltaX	word	 1,  1, -1, -1, -1, -1,  1,  1
diagDeltaY	word	 1,  1,  1,  1, -1, -1, -1, -1

; Tables used to complete the calculations of k1, k2, & k3
;
za	equ	offset C_A			; synonym for this offset
zc	equ	offset C_C			; synonym for this offset
pl	equ	0				; plus (add)
mi	equ	1				; minus (subtract)

k1Table		word	za, zc, zc, za, za, zc, zc, za
k2Table		word	pl, pl, mi, mi, pl, pl, mi, mi
k3Table		word	zc, za, za, zc, zc, za, za, zc

EvaluateOctant	proc	near
Cframe	local	ConicFrame
		.enter	inherit
	
		; Finish calculating d by adding in 1/4 of the value in DXDI
		; to BXAX, adding F, and storing the result
		;
		sarqw	dxdibxax		; divide by 4, keeping carries
		rcr	ch, 1			; accumulate fraction
		sarqw	dxdibxax
		rcr	ch, 1			; accumulate fraction
		add	cl, ch			; add fractions together
		adcqw	dxdibxax, Cframe.CF_d	; bx.cx = u - E/2 + C/4
		shl	cl, 1			; round up
		adcqw	dxdibxax, ds:[si].C_F	; add in F
		movqw	Cframe.CF_d, dxdibxax	; store d

		; First complete the offsets
		;
		mov	di, Cframe.CF_octant	; octant # => DI
		dec	di			; make it zero-based
		shl	di, 1			; change to word-sized offset
		mov	ax, cs:[sqreDeltaX][di]
		mov	Cframe.CF_dxsquare, ax
		mov	ax, cs:[sqreDeltaY][di]
		mov	Cframe.CF_dysquare, ax
		mov	ax, cs:[diagDeltaX][di]
		mov	Cframe.CF_dxdiag, ax
		mov	ax, cs:[diagDeltaY][di]
		mov	Cframe.CF_dydiag, ax
		
		; Calculate k1 (= 2A or 2C)
		;
		mov	bx, cs:[k1Table][di]	; offset to coeeficient => BX
		movqw	dxcxaxbx, ds:[si][bx]	; coeff => DXAX (ok,bx is last)
		shlqw	dxcxaxbx
		movqw	Cframe.CF_k1, dxcxaxbx	; store k1
		movqw	Cframe.CF_k2, dxcxaxbx	; store k2 (partial)

		; Calculate k2 (= K1 + or - B)
		;
		movqw	dxcxbxax, ds:[si].C_B	; B => CXBX
		tst	cs:[k2Table][di]
		jz	finishK2
		negqw	dxcxbxax
finishK2:
		addqw	Cframe.CF_k2, dxcxbxax	; store k2
		
		; Calculate k3 (= K2 + or - B + 2C or 2A)
		;
		addqw	dxcxbxax, Cframe.CF_k2
		movqw	Cframe.CF_k3, dxcxbxax
		mov	bx, cs:[k3Table][di]	; offset to coefficient => BX
		movqw	dxcxaxbx, ds:[si][bx]	; coefficient => CXDI
		shlqw	dxcxaxbx
		addqw	Cframe.CF_k3, dxcxaxbx

		; Finally, see if we need to perform further evaluation
		;
EC <		mov	ax, ds:[si].C_beg.P_x				>
EC <		mov	cx, ds:[si].C_beg.P_y	; starting Point => (CX, AX) >
EC <		sub	ax, ds:[si].C_xOffset	; x coordinate in new C.S.>
EC <		sub	cx, ds:[si].C_yOffset	; y coordinate in new C.S.>
EC <		mov	bx, ax						>
EC <		or	bx, cx			; starting at (0, 0)	>
EC <		ERROR_NZ GRAPHICS_CALC_CONIC_ASSUMES_0_DEGREE_START_END	>
ifdef		CALC_CONIC_START_ANYWHERE
		jz	done
		cwd				; x => DXAX
		mov	bx, dx
		xchg	ax, cx
		cwd				; y => DXAX
		xchg	ax, cx			; x => BXAX, y => DXCX
		call	CompleteDCalc		; finish the d0 calculation
		shr	di, 1			; change to byte offset
		call	CompleteUCalc		; finish the u0 calculation
		call	CompleteVCalc		; finish the v0 calculation
done:
endif
		.leave
		ret
EvaluateOctant	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompleteDCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete the caluclation of d0, which is the general conic
		section equation evaluated at (x+G, y+H). Normally, x=y=0,
		so we do not need to enter into this code. If we need to, then
		we simply calculate the remaining terms, to maintain precision.

CALLED BY:	EvaluateOctant

PASS:		Cframe	= On the stack
		BX:AX	= x coordinate (dword)
		DX:CX	= y coordinate (dword)
		DS:SI	= ConicParams
		DI	= Octant (zero-based times 2)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		S = Ax2 + Bxy +Cy2 + Dx +Ey + F
		
		Where:	x = X + G, depending on octant
			y = Y + H, depending on octant
				
		We are trying to evaluate S at a point along the ellipse
		(for calculating arcs). Normally, we finding points
		starting at (x,y) = (0,0), so most of the terms of
		the calculation drop out. All the constant terms are
		calculated and summed above in EvaluateOctant().

		So we have left:

		S = Ax2 + Bxy + Cy2 + Dx + Ey +
		    2AGx + B(Hx + Gy) + 2CHy

		The first five terms have no fraction, and are independent
		of octant, whereas the second 3 terms may be fractional,
		and are dependent upon the octant where we begin.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/23/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef		CALC_CONIC_START_ANYWHERE

; To make our lives easier, the G & H values are multiplied by
; 2 in the tables, hopefully eliminating some rounding problems later.
;
gValues		word	2,  1, -1, -2, -2, -1,  1,  2
hValues		word	1,  2,  2,  1, -1, -2, -2, -1

CompleteDCalc	proc	near
Cframe		local	ConicFrame
		uses	ax, bx, cx, dx, di
		.enter	inherit
	
		; Some set-up work
		;
		push	bp				; save Cframe
		mov	bp, cs:[gValues][di]		; G => BP
		mov	di, cs:[hValues][di]		; H => DI
		pushdw	dxcx				; save y
		pushdw	bxax				; save x
		pushdw	dxcx				; save y
		push	di				; save H
		push	bp				; save G
		push	di				; save H
		pushdw	bxax				; save x
		push	bp				; save G

		; Calculate B(Hx + Gy) (y = DXCX)
		;
		mov	bx, dx
		pop	ax				; 2G => AX
		cwd
		xchg	bx, dx				; y => DCXX, 2G => BXAX
		call	MulSDWord
		movdw	bpdi, dxcx			; 2Gy => BPDI
		popdw	bxcx				; x => BXCX
		pop	ax				; 2H => AX
		cwd
		xchg	ax, cx				; x => BXAX, 2H => DXCX
		call	MulSDWordAddToBPDI		; 2Hx + 2Gy => BXAX
		xchgdw	bxax, bpdi
		movdw	dxcx, ds:[si].C_B
		call	MulSDWord			; B (2Hx + 2Gy) => DXCX

		; Account that G & H were multiplied by two, so divide
		; entire result by two, and round result
		;
		saldw	dxcx				; carry set for round
		jnc	roundDone
		tst	dx
		jns	roundDone
		add	cx, 1
		adc	dx, 0
roundDone:
		movdw	bxax, bpdi			; x => BXAX
		movdw	bpdi, dxcx

		; Calculate 2AGx (BXAX = x)
		;
		mov_tr	cx, ax
		pop	ax				; 2G => AX
		cwd
		xchg	ax, cx				; x => BXAX, 2G => DXCX
		call	MulSDWord
		movdw	bxax, ds:[si].C_A
		call	MulSDWordAddToBPDI		; add in 2AGx

		; Calculate 2CHy
		;
		pop	ax
		cwd
		mov_tr	cx, ax				; 2H => DXCX
		popdw	bxax				; y => BXAX
		call	MulSDWord
		movdw	bxax, dS:[si].C_C
		call	MulSDWordAddToBPDI		; add in 2CHy

		; Done with fractional part. Calculate Ax2
		;
		popdw	bxax				; x => BXAX
		movdw	dxcx, ds:[si].C_A
		call	MulSDWord
		call	MulSDWordAddToBPDI		; Ax2+frac

		; Calculate Dx (BXAX = x)
		;
		movdw	dxcx, ds:[si].C_D
		call	MulSDWordAddToBPDI		; Ax2+Dx+frac

		; Calculate Bxy (BXAX = x)
		;
		movdw	dxcx, ds:[si].C_B
		call	MulSDWord
		popdw	bxax				; Y => BXAX
		call	MulSDWordAddToBPDI		; Ax2+Bxy+Dx+frac

		; Calculate Cy2 (BXAX = y)
		;
		movdw	dxcx, ds:[si].C_C
		call	MulSDWord
		call	MulSDWordAddToBPDI		; Ax2+Bxy+Cy2+Dx+frac

		; Calculate Ey (BXAX = y)
		;
		movdw	dxcx, ds:[si].C_E
		call	MulSDWordAddToBPDI		; Ax2+Bxy+Cy2+Dx+Ey+frac
		mov_tr	ax, bp				; result => AXDI
		pop	bp
		adddw	Cframe.CF_d, axdi		; add in other d terms

		.leave
		ret
CompleteDCalc	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompleteUCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete the calculation of u0. Again, we have already
		calculated the constant terms, so now we simply need to
		add in those that depend on x & y.

CALLED BY:	EvaluateOctant

PASS:		Cframe	= On the stack
		BX:AX	= x coordinate (dword)
		DX:CX	= y coordinate (dword)
		DS:SI	= ConicParams
		DI	= Octant (zero-based)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		u0 = (C5)((C1)(C2)x + (C3)(C4)y) + constant terms

		C1 = A or B
		C2 = 1 or 2
		C3 = B or C
		C4 = 1 or 2
		C5 = -1 or 1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef		CALC_CONIC_START_ANYWHERE

C1MASK		equ	00000001b		; A (0) or B (1)
C2MASK		equ	00000010b		; 1 (0) or 2 (1)
C3MASK		equ	00000100b		; B (0) or C (1)
C4MASK		equ	00001000b		; 1 (0) or 2 (1)
C5MASK		equ	00010000b		; all positive(0) or negative(1)

uTable		byte	00000010b, 00001101b, 00001101b, 00010010b,
			00010010b, 00011101b, 00011101b, 00000010b
CompleteUCalc	proc	near
Cframe		local	ConicFrame
		uses	ax, bx, cx, dx, di
		.enter	inherit
	
		; Calculate the x term, and save it on the stack
		;
		pushdw	dxcx			; save y
		movdw	dxcx, ds:[si].C_A	; assume A constant
		test	cs:[uTable][di], C1MASK
		jz	gotXConstant
		movdw	dxcx, ds:[si].C_B	; else use B
gotXConstant:
		test	cs:[uTable][di], C2MASK	; do we double the constant ??
		jz	calcXTerm		; no, so jump
		shldw	bxax			; else double X (faster)
calcXTerm:
		call	MulSDWord		; x term => DXCX
		popdw	bxax			; restore y
		pushdw	dxcx			; save x term

		; Calculate the y term
		;
		movdw	dxcx, ds:[si].C_B
		test	cs:[uTable][di], C3MASK
		jz	gotYConstant
		movdw	dxcx, ds:[si].C_C		
gotYConstant:
		test	cs:[uTable][di], C4MASK	; do we double the constant ??
		jz	calcYTerm		; no, so jump
		shldw	bxax			; else double Y (faster)
calcYTerm:
		call	MulSDWord		; y term => DXCX
		popdw	bxax			; x term => BXAX
		adddw	bxax, dxcx		; result => BXAX
		test	cs:[uTable][di], C5MASK	; negate result ??
		jz	addToU			; nope
		negdw	bxax			; yes, so negate it
addToU:
		adddw	ss:[Cframe].CF_u, bxax	; add in result to u0

		.leave
		ret
CompleteUCalc	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompleteVCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Complete the calculation of u0. Again, we have already
		calculated the constant terms, so now we simply need to
		add in those that depend on x & y.

CALLED BY:	EvaluateOctant

PASS:		Cframe	= On the stack
		BX:AX	= x coordinate (dword)
		DX:CX	= y coordinate (dword)
		DS:SI	= ConicParams
		DI	= Octant (zero-based)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		v0 = x(2(C6)A + (C7)B) + y((C8)B + 2(C9)C)

		C4 = +-1
		C5 = +-1
		C6 = +-1
		C7 = +-1

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef		CALC_CONIC_START_ANYWHERE

C6MASK		equ	00000001b		; 2A positive(0) or negative(1)
C7MASK		equ	00000010b		; B  positive(0) or negative(1)
C8MASK		equ	00000100b		; B  positive(0) or negative(1)
C9MASK		equ	00001000b		; 2C positive(0) or negative(1)

vTable		byte	00000000b, 00000000b, 00000101b, 00000101b,
			00001111b, 00001111b, 00001010b, 00001010b

CompleteVCalc	proc	near
Cframe		local	ConicFrame
		uses	ax, bx, cx, dx, di
		.enter	inherit
	
		; Some set-up work
		;
		push	bp			; save stack frame (Cframe)
		pushdw	dxcx			; save y
		pushdw	bxax			; save x

		; Calculate the X term
		;
		movdw	bxax, ds:[si].C_A
		shldw	bxax			; 2A => BXAX
		test	cs:[vTable][di], C6MASK
		jz	secondXTerm
		negdw	bxax			; -2A => BXAX
secondXTerm:
		movdw	dxcx, ds:[si].C_B	; B => DXCX
		test	cs:[vTable][di], C7MASK
		jz	finishX
		negdw	dxcx			; -B => DXCX
finishX:
		adddw	bxax, dxcx
		popdw	dxcx			; restore X => DXCX
		call	MulSDWord
		pushdw	dxcx			; save x term

		; Calculate the Y term
		;
		movdw	bxax, ds:[si].C_C
		shldw	bxax
		test	cs:[vTable][di], C9MASK
		jz	secondYTerm
		negdw	bxax
secondYTerm:
		movdw	dxcx, ds:[si].C_B
		test	cs:[vTable][di], C8MASK
		jz	finishY
		negdw	dxcx
finishY:
		adddw	bxax, dxcx
		popdw	bpdi			; restore x term
		popdw	dxcx			; restore Y => DXCX
		call	MulSDWordAddToBPDI	; multiply & add result
		
		; Add in our result
		;
		mov_tr	ax, bp			; result => AXDI
		pop	bp			; restore Cframe
		adddw	ss:[Cframe].CF_v, axdi	; add in our calculation

		.leave
		ret
CompleteVCalc	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawEvenOctant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do drawing for an even numbered octant

CALLED BY:	INTERNAL 
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		carry	- set if error

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		Do drawing for an even octant.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawEvenOctant	proc	near
		uses	di
Cframe		local	ConicFrame
		.enter	inherit

		; first calc k2/2 so we have an ending condition

		movqw	dxcxbxax, Cframe.CF_k2	; get k2
		sarqw	dxcxbxax		; halve it
		jnc	drawLoop
		incqw	dxcxbxax

		; keep drawing until it's time to stop (imagine that !)
drawLoop:
		jlqw	dxcxbxax, Cframe.CF_v, neardone
		
		; passed the first test.  Now make sure we're not out of whack
		; because of the cross-over problem

		mov	di, Cframe.CF_curr.P_x		; load up curr pos
		cmp	di, ds:[si].C_bounds.R_left 	; off left side ?
		jl	neardone			
		cmp	di, ds:[si].C_bounds.R_right 	; off right side ?
		jg	neardone			
		mov	di, Cframe.CF_curr.P_y		; load up curr pos
		cmp	di, ds:[si].C_bounds.R_top 	; off top side ?
		jl	neardone			
		cmp	di, ds:[si].C_bounds.R_bottom 	; off right side ?
		jle	keepDrawing			
neardone:
		jmp	done
abort:
		jmp	exit

		; do whatever we need to do to make the point get into the list
keepDrawing:
		mov	di, ax
		clr	al			; normal addition
		call	AddPoint		; add in the point
		mov	ax, di
		jc	abort

		; update all the decision vars

		tst	Cframe.CF_d.HI_hi.high	; check sign of d
		jns	updateDiag		; do a diagonal move

		; do a square move
squareMove:
		mov	di, Cframe.CF_dxsquare	; get movement
		add	Cframe.CF_curr.P_x, di	; update xpos
		mov	di, Cframe.CF_dysquare	; get movement
		add	Cframe.CF_curr.P_y, di	; update ypos

		; update u,v,d

		addqw	Cframe.CF_v, Cframe.CF_k2, di	; v = v + k2
		addqw	Cframe.CF_u, Cframe.CF_k1, di	; u = u + k1
		addqw	Cframe.CF_d, Cframe.CF_u, di	; d = d + new u

		; before we continue drawing, make sure we're not at the last
		; point.
checkLastPt:
		mov	di, Cframe.CF_curr.P_x
		cmp	di, ds:[si].C_end.P_x	; at end ?
		LONG jne drawLoop
		mov	di, Cframe.CF_curr.P_y
		cmp	di, ds:[si].C_end.P_y	; at end ?
		LONG je	done
		jmp	drawLoop

		; do a diagonal move
updateDiag:
		mov	di, Cframe.CF_dxdiag	; get movement
		add	Cframe.CF_curr.P_x, di	; update xpos
		mov	di, Cframe.CF_dydiag	; get movement
		add	Cframe.CF_curr.P_y, di	; update ypos
		
		; update u,v,d, and check for crossover.
		;
		;		  dS
		;	see if    -- > 0.  
		;		  dy
		;
		; This partial derivative is equal to (v - u)

		addqw	Cframe.CF_u, Cframe.CF_k2, di	; u = u + k2
		addqw	Cframe.CF_v, Cframe.CF_k3, di	; v = v + k3
		jgqw	Cframe.CF_v, Cframe.CF_u, crossedOver, di
		addqw	Cframe.CF_d, Cframe.CF_v, di	; d = d + new v
		jmp	checkLastPt

		; OK, we've crossed over.  We need to undo the coordinate
		; change and undo the modifications to u and v:
crossedOver:
		mov	di, Cframe.CF_octant	; get current octant
		shl	di, 1			; make it a table index
		call	cs:[evenCrossOver][di]	; repair damage after crossover
		subqw	Cframe.CF_u, Cframe.CF_k2, di	; u = u + k2
		subqw	Cframe.CF_v, Cframe.CF_k3, di	; v = v + k3
		jmp	squareMove		; didn't want to do this

		; all done with this octant.  Update vars to next one.
		; d = round(d - u + v/2 - k2/2 + 3 * k3/8)
		; u = round(-u + v - k2/2 + k3/2)
		; v = round(v - k2 + k3/2)
		; k1 = k1 - 2*k2 + k3
		; k2 = k3 - k2
done:
		clr	cx			; clear out fractions
		movqw	dxdibxax, Cframe.CF_u	; get old u
		negqw	dxdibxax
		addqw	Cframe.CF_d, dxdibxax	; d = d - u
		movqw	Cframe.CF_u, dxdibxax	; u = -u
		movqw	dxdibxax, Cframe.CF_v
		addqw	Cframe.CF_u, dxdibxax	; u = -u + v
		sarqw	dxdibxax		; v/2
		rcr	cl, 1			; one positive fraction
		addqw	Cframe.CF_d, dxdibxax	; d = d - u + v/2

		movqw	dxdibxax, Cframe.CF_k3	; k3
		salqw	dxdibxax		; 2*k3
		addqw	dxdibxax, Cframe.CF_k3	; 3+k3
		sarqw	dxdibxax		; 3*k3/2
		rcr	ch, 1
		sarqw	dxdibxax		; 3*k3/4
		rcr	ch, 1
		sarqw	dxdibxax		; 3*k3/8
		rcr	ch, 1			; accumulate fraction
		add	cl, ch
		adcqw	Cframe.CF_d, dxdibxax	; d = d - u + v/2 +3*k3/8
		clr	ch			; re-init fraction
		movqw	didxbxax, Cframe.CF_k2	; get k2/2
		sarqw	didxbxax		; k2/2
		rcr	ch, 1			; make fraction
		add	cl, ch			; combine fractions
		sbbqw	Cframe.CF_d, dxdibxax	; d = d - u + v/2 +3*k3/8 -k2/2

		; now calculate u
		; u = round(-u + v - k2/2 + k3/2)

		clr	cl			; init fraction. ch = k2/2 frac
		subqw	Cframe.CF_u, dxdibxax	; u = v - u - k2/2
		movqw	dxdibxax, Cframe.CF_k3	; dx.di = k3
		sarqw	dxdibxax		; dx.di = k3/2
		pushf				; save carry for v calc
		rcr	cl, 1
		add	cl, ch			; deal with fractions
		adcqw	Cframe.CF_u, dxdibxax	; bx.ax=v-u-k2/2+k3/2

		; now calculate v
		; v = round(v - k2 + k3/2)

		popf				; restore carry from k3/2
		adcqw	dxdibxax, Cframe.CF_v	; add k3/2
		subqw	dxdibxax, Cframe.CF_k2	; v = v + k3/2 - k2
		movqw	Cframe.CF_v, dxdibxax	; store new v

		; do final two calcs.  these are easy since no fractions
		; k1 = k1 - 2*k2 + k3
		; k2 = k3 - k2

		movqw	dxdibxax, Cframe.CF_k3	
		addqw	Cframe.CF_k1, dxdibxax
		xchgqw	dxdibxax, Cframe.CF_k2	; k2 = k3
		subqw	Cframe.CF_k2, dxdibxax	; k2 = k3-k2
		subqw	Cframe.CF_k1, dxdibxax	; k1 = k1-k2+k3
		subqw	Cframe.CF_k1, dxdibxax	; k1 = k1-2*k2+k3

		mov	ax, Cframe.CF_dysquare
		xchg	ax, Cframe.CF_dxsquare	; dxdiag = dydiag
		neg	ax
		mov	Cframe.CF_dysquare, ax	; dydiag = - dxdiag
		clc
exit:
		.leave
		ret
DrawEvenOctant	endp

		; vectors for procedures to check for cross over on thin
		; ellipses
evenCrossOver	label	nptr			
		nptr	0		; there is no octant 0
		nptr	0		; this is only for even octants
		nptr	FixupInOct2	; check crossover in octant 2
		nptr	0		; this is only for even octants
		nptr	FixupInOct4	; check crossover in octant 4
		nptr	0		; this is only for even octants
		nptr	FixupInOct6	; check crossover in octant 6
		nptr	0		; this is only for even octants
		nptr	FixupInOct8	; check crossover in octant 8


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawEvenOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct2	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		dec	Cframe.CF_curr.P_x	; take away the bump
		dec	Cframe.CF_curr.P_y

		.leave
		ret
FixupInOct2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct4
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawEvenOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct4	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		inc	Cframe.CF_curr.P_x	; take away the bump
		dec	Cframe.CF_curr.P_y

		.leave
		ret
FixupInOct4	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawEvenOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct6	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		inc	Cframe.CF_curr.P_x	; take away the bump
		inc	Cframe.CF_curr.P_y

		.leave
		ret
FixupInOct6	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawEvenOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct8	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		dec	Cframe.CF_curr.P_x	; take away the bump
		inc	Cframe.CF_curr.P_y

		.leave
		ret
FixupInOct8	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawOddOctant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do drawing for an odd octant

CALLED BY:	INTERNAL
		CalcConic

PASS:		ConicFrame on stack
		ds:si	- points to ConicParams

RETURN:		carry	- set if error

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
		Do drawing for an odd octant.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawOddOctant	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		; first calc k2/2 so we have an ending condition

		movqw	dxcxbxax, Cframe.CF_k2	; get low word
		sarqw	dxcxbxax
		jnc	drawLoop
		incqw	dxcxbxax		; round up if needed

		; keep drawing until it's time to stop (imagine that !)
drawLoop:
		jgqw	dxcxbxax, Cframe.CF_u, keepDrawing, di ; check for stop
		jmp	done
abort:
		jmp	exit
		
		; do whatever we need to do to make the point get into the list
keepDrawing:
		mov	di, ax
		clr	al			; normal addition
		call	AddPoint		; add in the point
		mov	ax, di
		jc	abort

		; update all the decision vars

		tst	Cframe.CF_d.HI_hi.high	; check sign of d
		LONG js	updateDiag		; do a diagonal move

		; do a square move

		mov	di, Cframe.CF_dxsquare	; get movement
		add	Cframe.CF_curr.P_x, di	; update xpos
		mov	di, Cframe.CF_dysquare	; get movement
		add	Cframe.CF_curr.P_y, di	; update ypos

		; update u,v,d, and check for cross-over
		;
		;		  dS   dS
		;	see if    -- - -- > 0.  
		;		  dx   dy
		;
		; This partial derivative difference is equal to
		; (2u - v - k2/2).

		addqw	Cframe.CF_v, Cframe.CF_k2, di
		addqw	Cframe.CF_u, Cframe.CF_k1, di
		pushqw	dxcxbxax
		addqw	dxcxbxax, Cframe.CF_v
		subqw	dxcxbxax, Cframe.CF_u
		jlqw	dxcxbxax, Cframe.CF_u, crossedOver, di
		popqw	dxcxbxax
		addqw	Cframe.CF_d, Cframe.CF_u, di

		; before we continue drawing, make sure we're not at the last
		; point.
checkLastPt:
		mov	di, Cframe.CF_curr.P_x
		cmp	di, ds:[si].C_end.P_x	; at end ?
		LONG jne drawLoop
		mov	di, Cframe.CF_curr.P_y
		cmp	di, ds:[si].C_end.P_y	; at end ?
		LONG jne drawLoop
		jmp	done

		; didn't want to do the square move, so undo the
		; change to u & v, and fixup the current point
crossedOver:
		popqw	dxcxbxax
		mov	di, Cframe.CF_octant	; get current octant
		shl	di, 1			; make it a table index
		call	cs:[oddCrossOver][di]	; check if this is right
		subqw	Cframe.CF_v, Cframe.CF_k2, di	; v = v - k2
		subqw	Cframe.CF_u, Cframe.CF_k1, di	; u = u - k1

		; do a diagonal move
updateDiag:
		mov	di, Cframe.CF_dxdiag	; get movement
		add	Cframe.CF_curr.P_x, di	; update xpos
		mov	di, Cframe.CF_dydiag	; get movement
		add	Cframe.CF_curr.P_y, di	; update ypos
		
		; update u,v,d

		addqw	Cframe.CF_u, Cframe.CF_k2, di
		addqw	Cframe.CF_v, Cframe.CF_k3, di
		addqw	Cframe.CF_d, Cframe.CF_v, di
		jmp	checkLastPt			; use common code

		; all done with this octant.  Update vars to next one.
		;  d = d + u - v + k1 - k2
		;  v = 2*u - v + k1 - k2
		;  u = u + k1 - k2
		;  k3 = 4*(k1 - k2) + k3
		;  k2 = 2*(k1 - k2) + k2
done:
		movqw	dxcxbxax, Cframe.CF_u	; load up u
		addqw	Cframe.CF_d, dxcxbxax	; d = d + u
		shlqw	dxcxbxax		; calc 2 * u
		xchgqw	dxcxbxax, Cframe.CF_v	; get v, store 2*u
		subqw	Cframe.CF_v, dxcxbxax	; v = 2*u - v
		subqw	Cframe.CF_d, dxcxbxax	; d = d + u - v
		movqw	dxcxbxax, Cframe.CF_k1	; load up k1
		subqw	dxcxbxax, Cframe.CF_k2	; calc (k1 - k2)
		addqw	Cframe.CF_d, dxcxbxax	; d = d + u - v + k1 - k2
		addqw	Cframe.CF_v, dxcxbxax	; v = 2*u - v + k1 - k2
		addqw	Cframe.CF_u, dxcxbxax	; u = u + k1 - k2
		shlqw	dxcxbxax		; calc 4*(k1 - k2)
		addqw	Cframe.CF_k2, dxcxbxax	; k2 = 2*(k1 - k2) + k2
		shlqw	dxcxbxax
		addqw	Cframe.CF_k3, dxcxbxax	; k3 = 4*(k1 - k2) + k3
		mov	ax, Cframe.CF_dydiag
		xchg	ax, Cframe.CF_dxdiag	; dxdiag = dydiag
		neg	ax
		mov	Cframe.CF_dydiag, ax	; dydiag = - dxdiag
		clc
exit:
		.leave
		ret
DrawOddOctant	endp

		; vectors for procedures to check for cross over on thin
		; ellipses
oddCrossOver	label	nptr			
		nptr	0		; there is no octant 0
		nptr	FixupInOct1	; check crossover in octant 1
		nptr	0		; this is only for ode octants
		nptr	FixupInOct3	; check crossover in octant 3
		nptr	0		; this is only for ode octants
		nptr	FixupInOct5	; check crossover in octant 5
		nptr	0		; this is only for ode octants
		nptr	FixupInOct7	; check crossover in octant 7

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawOddOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct1	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		dec	Cframe.CF_curr.P_x	; take away the bump

		.leave
		ret
FixupInOct1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawOddOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct3	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		dec	Cframe.CF_curr.P_y	; take away the bump

		.leave
		ret
FixupInOct3	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawOddOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct5	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		inc	Cframe.CF_curr.P_x	; take away the bump

		.leave
		ret
FixupInOct5	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixupInOct7
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert to previous point after crossover was detected

CALLED BY:	INTERNAL
		DrawOddOctant

PASS:		Cframe

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	07/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FixupInOct7	proc	near
Cframe		local	ConicFrame
		.enter	inherit

		inc	Cframe.CF_curr.P_y	; take away the bump

		.leave
		ret
FixupInOct7	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a point to the buffer containing the points along the conic

CALLED BY:	INTERNAL
		DrawEvenOctant, DrawOddOctant

PASS:		ConicFrame	- passed on the stack (inherited local var)
		ds:si		- pointer to passed ConicParams structure
		al		- 0 if normal entry.  1 if time to terminate.

RETURN:		carry		- set if Point buffer is full

DESTROYED:	ax,bx

PSEUDO CODE/STRATEGY:
		add the set of points (CF_curr) to the buffer containing
		the other conic points.  Actually, we do a little more 
		work at this point to minimize the number of points that
		we are adding to the buffer.  First, if both points are 
		outside the window (on the same size) then we don't add them
		Second, if the new pair of points is colinear with the last
		pair, we don't add anything until the line changes direction.
		This check uses the curr, last and orig Point variables in
		the ConicFrame structure.  They are all initialized to 
		EOREGREC.  The logic goes like this:

		if (curr.y < winTop.y) OR (curr.y > winBot.y) 
		    if (orig != EOREGREC) && (last != EOREGREC)
			enter (last,EOREGREC)
		    orig = last = EOREGREC
		elseif (last == EOREGREC)
		    enter(curr)
		    last = curr
		elseif (orig == EOREGREC)
		    enter(last)
		    orig = last
		    last = curr
		    set direction
		elseif ((curr-last)==last dir)
		    last = cur
		else
		    enter(last)
		    orig = last
		    last = curr
		    set direction
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	03/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddPoint	proc	near
		uses	ax, bx, cx, dx, di
Cframe		local	ConicFrame
		.enter	inherit

		; We have doubled all of the coordinates of the
		; conic section (to allow the center of the conic
		; to be on an integer), but now we must halve the
		; passed coordinate. We round the point towards
		; the center of the ellipse, so that we don't get
		; a lopsided result.
		;
		mov	bx, Cframe.CF_curr.P_x
		cmp	bx, ds:[si].C_center.P_x
		jge	roundX
		inc	bx
roundX:		sar	bx, 1			; rounded P_x => BX
		mov	cx, Cframe.CF_curr.P_y
		cmp	cx, ds:[si].C_center.P_y
		jge	roundY
		inc	cx
roundY:		sar	cx, 1			; rounded P_Y => CX

		; See if this is the last point, or if we are dealing with arcs

		mov	di, Cframe.CF_bufPtr	; just in case we need it
		tst	al			; time to terminate ??
		LONG	jnz	terminateTheSucker
		cmp	bx, Cframe.CF_last.P_x	; same as last point ??
		jne	checkType
		cmp	cx, Cframe.CF_last.P_y
		LONG	je	exit
checkType:
if	DEBUG_CONIC_SECTION_CODE
		call	PushAllFar
		mov	dx, cx
		mov	cx, bx			; Point => (CX, DX)
		mov	bx, ds:[si].C_window
		call	MemDerefES		; Window => ES
		mov	bx, ds:[si].C_gstate
		call	MemDerefDS		; GState => DS
		mov	ax, cx
		mov	bx, dx			; Point => (AX, BX)
		mov	si, offset GS_lineAttr
		call	FillRectLowFar
		call	PopAllFar
endif
		tst	ds:[si].C_conicType	; type of Conic ??
		LONG	jnz	checkArcFlags	; if not ellipse, jump

		; start the checks for current point outside window
checkBounds:
		cmp	cx, ds:[si].C_winTop	; out of bounds ?
		jl	outOfBounds		; handle this case
		cmp	cx, ds:[si].C_winBot	; out of bounds ?
		jg	outOfBounds		; have all window bounds cases

		; next check the easy cases.  

		cmp	Cframe.CF_last.P_x, EOREGREC ; all done ?
		jne	checkNoOrig		;  no, check again
		mov	es:[di], bx		; set original point
		mov	es:[di+2], cx
		add	di, 4
		inc	Cframe.CF_bufPoints	; one more point entered
		jmp	moveCurrLast		;  yes, just do last=curr
checkNoOrig:
		cmp	Cframe.CF_orig.P_x, EOREGREC ; all done ?
		je	setNewDir		;  no, set new direction

		; steady state, check direction we're moving	

		mov	ax, bx			; set ax,dx = curr
		mov	dx, cx
		sub	ax, Cframe.CF_last.P_x	; calc new direction
		cmp	ax, Cframe.CF_dir.P_x	; check x dir
		jne	newDirection		; going a new way
		sub	dx, Cframe.CF_last.P_y
		cmp	dx, Cframe.CF_dir.P_y
		je	moveCurrLast		; going same direction, continue

		; going a different direction.  Add the last point and
		; calc a new direction to go
newDirection:
		mov	ax, Cframe.CF_last.P_x	; store the x coord, 1st point
		stosw
		mov	ax, Cframe.CF_last.P_y
		stosw
		inc	Cframe.CF_bufPoints	; one more point entered
setNewDir:
		mov	ax, Cframe.CF_last.P_x	; load up last position
		mov	dx, Cframe.CF_last.P_y
		mov	Cframe.CF_orig.P_x, ax	; set orig=last
		mov	Cframe.CF_orig.P_y, dx
		sub	ax, bx			; calc new dir
		neg	ax
		sub	dx, cx			
		neg	dx
		mov	Cframe.CF_dir.P_x, ax	; set new direction
		mov	Cframe.CF_dir.P_y, dx
moveCurrLast:
		mov	Cframe.CF_last.P_x, bx	; set last=curr
		mov	Cframe.CF_last.P_y, cx
done:
		mov	Cframe.CF_bufPtr, di	; update buffer pointer
EC <		cmp	di, ds:[si].C_sBuffer	; compare buffer size	>
EC <		ERROR_A	GRAPHICS_CALC_CONIC_BUFFER_OVERFLOW		>
EC <		clc							>
NEC <		cmp	ds:[si].C_sBuffer, di	; if we're going to	>
NEC <						; overflow, set carry	>
exit:
		.leave
		ret

		; we're out of bounds, handle it
outOfBounds:
		mov	ax, EOREGREC		; we'll need this
		cmp	ax, Cframe.CF_last.P_x	; check current state of things
		je	done
		cmp	ax, Cframe.CF_orig.P_x	
		je	setLastEOR
		mov	cx, Cframe.CF_last.P_x	; save away last
		mov	es:[di], cx
		mov	cx, Cframe.CF_last.P_y
		mov	es:[di+2], cx
		inc	Cframe.CF_bufPoints	; one more point entered
		add	di, 4
		mov	Cframe.CF_orig.P_x, ax 
setLastEOR:
		mov	Cframe.CF_last.P_x, ax 
		jmp	done

		; Time to terminate the string of points.  put in the final
		; two EOREGRECs, after checking to see if we need to add the
		; current & last points.
terminateTheSucker:
		tst	ds:[si].C_conicType	; ellipse, or something else??
		jz	checkLast		; ellipse, so end Point is OK
		mov	bx, ds:[si].C_conicEnd.P_x
		mov	cx, ds:[si].C_conicEnd.P_y		
checkLast:
		cmp	bx, Cframe.CF_last.P_x
		jne	doTermination
		cmp	cx, Cframe.CF_last.P_y
		je	addLastPoint
doTermination:
		mov	ax, EOREGREC		; we'll need this
		cmp	ax, Cframe.CF_last.P_x	; check current state of things
		je	addLastPoint
		mov	dx, Cframe.CF_last.P_x	; save away last
		mov	ax, Cframe.CF_last.P_y
		cmp	ax, ds:[si].C_winTop	; out of bounds ?
		jl	addLastPoint		; handle this case
		cmp	ax, ds:[si].C_winBot	; out of bounds ?
		jg	addLastPoint		; have all window bounds cases
		mov	es:[di], dx		; store X
		add	di, 2
		stosw				; store Y
		inc	Cframe.CF_bufPoints	; one more point entered
addLastPoint:
		mov	ax, EOREGREC		; we'll need this
		cmp	ax, Cframe.CF_curr.P_x	; check current state of things
		je	addFinalEOR
		cmp	cx, ds:[si].C_winTop	; out of bounds ?
		jl	addFinalEOR		; handle this case
		cmp	cx, ds:[si].C_winBot	; out of bounds ?
		jg	addFinalEOR		; have all window bounds cases
		mov	es:[di], bx
		mov	es:[di+2], cx
		inc	Cframe.CF_bufPoints	; one more point entered
		add	di, 4
addFinalEOR:
		stosw				; store one EOREGREC
		stosw				; store another EOREGREC
		jmp	done

		; We are trying to generate the points along an arc. To ensure
		; this stepping algorithm does not go astray, we always start
		; to generate Points from 0 degrees, but simply add those
		; points that fall between (inclusive) the C_conicBeg &
		; C_conicEnd Points.
		;
		; To do this, we have a simple state machine, where C_conicInfo
		; holds the state.
		;
		; CAI_FIND_START: means we are looking for the first point
		; *after* the start point that is closest (or equal). This
		; closest point is stored in CF_arcLast, and needs to
		; eventually be written to the point buffer, if the first
		; point is *not* on the ellipse. If the first point is on
		; the ellipse, then we simply add that point, and change our
		; state to:
		;
		; CAI_FIND_END: means we are looking for the last point
		; closest to the end point that us *before* the end. After
		; this is found, we change our state to:
		;
		; CAI_FIND_DONE: which will ignore all points. The only
		; exception to this is when we pass AL=1 to AddPoint(), when
		; C_conicEnd will be added, and the point buffer will be
		; properly terminated with two EOREGREC words.
		;
checkArcFlags:
		mov	al, ds:[si].C_conicInfo	; ConicArcInfo => AL
		tst	al			; CAI_FIND_START, or not??
		jnz	checkArcEnd
		mov	ax, offset C_conicBeg
		call	CalcDifferential	; difference => AX
		jz	removeArcStart		; if zero, start is on ellipse
		cmp	ax, Cframe.CF_arcDiff	; compare with old difference
		ja	removeArcStartAddFirst	; if larger, we're moving away
		mov	Cframe.CF_arcDiff, ax
		mov	Cframe.CF_arcLast.P_x, bx
		mov	Cframe.CF_arcLast.P_y, cx
nearExit:
		clc
		jmp	exit
removeArcStartAddFirst:
		mov	ax, ds:[si].C_conicBeg.P_x
		stosw				; store start.P_x
		mov	ax, ds:[si].C_conicBeg.P_y
		stosw				; store start.P_y
		mov	ax, Cframe.CF_arcLast.P_x
		stosw				; store closest.P_x
		mov	ax, Cframe.CF_arcLast.P_y
		stosw				; store closest.P_y
		add	Cframe.CF_bufPoints, 2
removeArcStart:
		mov	Cframe.CF_arcDiff, EOREGREC
		mov	ds:[si].C_conicInfo, CAI_FIND_END
		jmp	checkBounds		; now go add the Point

		; Check to see if this Point will end the arc
checkArcEnd:
		cmp	al, CAI_FIND_END	; looking for the end ??
		jne	nearExit		; nope, so get out of here
		mov	ax, offset C_conicEnd
		call	CalcDifferential	; difference => AX
		jz	removeArcEnd		; if right on, we're done
		cmp	ax, Cframe.CF_arcDiff	; compare with old difference
		ja	removeArcEnd		; if larger, we're moving away
		mov	Cframe.CF_arcDiff, ax	; store difference
		jmp	checkBounds		; and add the Point
removeArcEnd:
		mov	Cframe.CF_octCount, 1	; terminate as soon as possible
		mov	ds:[si].C_conicInfo, CAI_DONE
		jmp	nearExit		; don't add the Point
AddPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDifferential
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the difference between the current point and
		the beginning or ending of an arc.

CALLED BY:	AddPoint

PASS:		(BX,CX)	= Current Point
		DS:SI	= ConicParams
		AX	= Offset into ConicParams to find comparison Point

RETURN: 	Zero	= Set if AX = 0

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DIFFERENTIAL_MAXIMUM	equ	3

CalcDifferential	proc	near
Cframe		local	ConicFrame
		uses	bx, si
		.enter	inherit
	
		add	si, ax
		mov	ax, cx
		sub	bx, ds:[si].P_x
		jns	xDiffOK
		neg	bx
xDiffOK:
		sub	ax, ds:[si].P_y
		jns	yDiffOK
		neg	ax
yDiffOK:
		add	ax, bx			; differential => AX
		jz	done			; if zero, we're outta here
		cmp	ax, DIFFERENTIAL_MAXIMUM
		jl	done			; if less than max, jump
		mov	ax, DIFFERENTIAL_MAXIMUM
		tst	ax			; set zero flag properly
done:
		.leave
		ret
CalcDifferential	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulSDWordAddToBPDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used when keeping a sum in BP:DI, will perform the normal
		multiply of two values in BX:AX & DX:CX, and then add the
		result to BP:DI

CALLED BY:	Internal

PASS:		BX:AX	= DWord value #1 (multiplier)
		DX:CX	= DWord value #2 (multiplicand)
		BP:DI	= Running total

RETURN:		BP:DI	= Updated with result of multiplication
		DX:CX	= Result of multiplication

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	don	10/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef		CALC_CONIC_START_ANYWHERE
MulSDWordAddToBPDI	proc	near
		call	MulSDWord
		adddw	bpdi, dxcx
		ret
MulSDWordAddToBPDI	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MulSDWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	GLOBAL

PASS:		bx.ax	- 32-bit signed dword 	(mulitplier)
     		dx.cx	- 32-bit signed dword	(multiplicand)

RETURN:		dx.cx	- 32-bit signed result

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do full mulitply, but toss the high 32 bits of the result, 
		since we assume there is no overflow.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This assumes the result will not overflow and require 64-bits
		The EC version checks this, but the non-EC version just
		ignores any of the high bits.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Jim	08/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifdef		CALC_CONIC_START_ANYWHERE
MulSDWord	proc	near
		uses	ax,bx,si,di
multiplicand	local	dword
result		local	word
		.enter

		mov	si, dx			; si = negate flag
		xor	si, bx

		; check each operand, make sure both are positive

		tst	dx			; check multiplicand
		jns	checkMultiplier		;  nope, continue
		NegateFixed dx,cx		; do 32-bit negate
checkMultiplier:
		tst	bx			; check multiplier
		jns	doUnsignedMul		;  nope, straight to mul
		NegateFixed bx,ax		; do 32-bit negate

		; now we have two unsigned factors.  Do the multiply
doUnsignedMul:
		xchg	ax, cx			; dx.ax = multiplicand
						; bx.cx = mulitplier
		mov	multiplicand.low, ax 	; save away one factor
		mov	multiplicand.high, dx
		mul	cx			; multiply low factors
		mov	result, ax     		; save away partial result
		mov	di, dx			; save away high word of result
		mov	ax, multiplicand.high	; get next victim
		mul	cx
		add	di, ax
EC <		jc	signalError					  >
EC <		tst	dx			; this should be zero too >
EC <		jnz	signalError					  >
		mov	ax, multiplicand.low	; continue with partial results
		mul	bx
		add	di, ax			; finish off calc
EC <		jc	signalError					  >
EC <		tst	dx					  	  >
EC <		jnz	signalError					  >
EC <		mov	ax, multiplicand.high	; check high 		  >
EC <		mul	bx						  >
EC <		or	ax, dx			; this must be zero	  >
EC <		jz	allOK			;  calc done		  >
EC <signalError:							  >
EC <		ERROR	GRAPHICS_32_BIT_MUL_OVERFLOW			  >
EC <allOK:								  >

		; all done with multiply, set up result regs

		mov	cx, result		; grab low part of result
		mov	dx, di			; restore high part of result

		; multiply is done, check to see if we have to negate the res

		tst	si			; see if result is negative
		jns	done			;  nope, exit
		NegateFixed dx,cx		;  yes, do it
done:
		.leave
		ret
MulSDWord	endp
endif

GraphicsCalcConic	ends
