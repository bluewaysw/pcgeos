COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		graphicMathUtils.asm

AUTHOR:		Steve Scholl, Nov 15, 1989

ROUTINES:
	Name			Description
	----			-----------
INT GrObjCalcLineAngle		Calcs angle of line between 2 points
INT GrObjCalcDistance		Calc WWFixed distance between two points
INT GrObjNormalizeDegrees	0 <= degrees < 360
INT GrObjCalcSquareRoot	Calc square root of number

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	11/15/89		Initial revision


DESCRIPTION:
	Utililty routines for graphic class 
		

	$Id: grobjMathUtils.asm,v 1.1 97/04/04 18:07:23 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GrObjExtInteractiveCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcLineAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc angle of line passing from first point to the
		second point

CALLED BY:	INTERNAL

PASS:		
		ax,bx - first point
		cx,dx - second point 

RETURN:		
		clc
			dx:cx - WWFixed angle

		stc - couldn't calc angle
			dx,cx - destroyed
DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		calc radius
		calc dx,dy
		pass -(dy/radius),dx to ArcSine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/ 2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcLineAngle		proc	far
	uses	ax,bx,si,di
	.enter

	push	dx,cx,bx,ax			;save points
	call	GrObjCalcDistance		;get radius
	jc	failedCalcPop
	pop	dx,cx,si,di			;points 

	sub	cx,di				;delta x
	push	cx				;
	sub	dx,si				;delta y

	clr	cx				;no frac delta y
	call	GrSDivWWFixed
	negdw	dxcx				;neg delta y/radius
	pop	bx				;delta x
	call	GrQuickArcSine
	clc					;signal success
done:
	.leave
	ret

failedCalcPop:
	;    Assumed that carry is set when jumping here
	;

	pop	dx,cx,bx,ax			;points 
	jmp	short done	


GrObjCalcLineAngle		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcDistance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calcs distance between two points

CALLED BY:	INTERNAL

PASS:		
		ax,bx - a point
		cx,dx - another point

RETURN:		
		clc
			bx.ax - distance (16 int, 16 frac)

		stc - distance too far to calc
			ax,bx - destroyed

DESTROYED:	
		See RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/ 9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcDistance		proc	far
	uses	cx,dx,si,di,bp
	.enter
	sub	cx,ax				;get abs delta x
	jns	10$
	neg	cx			
10$:
	sub	dx,bx				;get abs delta y
	jns	20$				
	neg	dx
20$:
	jcxz	vertical
	tst	dx
	jz	horizontal

	mov	ax,dx				;sqr abs delta y
	mul	dx
	mov	bx,dx				;high of square
	mov	dx,cx				;abs delta x
	mov_tr	cx,ax				;low of delta y square
	mov	ax,dx				;abs delta x
	mul	dx				;sqr abs delta x
	add	cx,ax				;add low words
	adc	dx,bx				;add high words
	clr	bp				;frac
	call	GrObjCalcSquareRoot
	mov_tr	ax,dx				;int
	mov	bx,cx				;frac
done:
	xchg	ax,bx				;bx <- int, ax <- frac
	.leave
	ret

horizontal:
	mov_tr	ax,cx				;int 
	clr	bx				;frac
	clc					;signal success
	jmp	short done

vertical:
	mov_tr	ax,dx				;int
	clr	bx				;frac
	clc					;signal success
	jmp	short done
GrObjCalcDistance		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcSquareRoot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the square root of a 48 bit number

CALLED BY:	INTERNAL
		CalcAbsDistance

PASS:		
		dx:cx:bp - DWFixed Number to calc square root of

RETURN:		
		clc 
			dx.cx - square root (16 int, 16 frac )
		stc
			couldn't calc
			dx.cx - destroyed

DESTROYED:	
		See RETURN

PSEUDO CODE/STRATEGY:
	A = (N/A +A)/2		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcSquareRoot		proc	far
	uses	ax,bx,di,si,bp
	.enter
	
	cmp	dx,1fffh					
	jae	failed

	mov	di,dx				;number high int
	mov	ax,cx				;number low int
	mov	si,ax				;number low ing

	;    The initial approximation is chosen in a very arbitary fashion
	;    (N/300)+2 if N < ffffffh
	;    (N/16384)+2 if N >= ffffffh
	;    It is important that the above division returns a number
	;    less than 65536 to prevent a divide by 0 error
	;    a much better algorithm is used in GrSqrRootWWFixed but I am
	;    under a tight deadline so I am using this for now
	;    If value is fractional, then use the value itself
	;    as the approximation
	;

	tst	ax				;number low int
	jnz	continue
	tst	di				;number high int
	jnz	continue
	clr	bx				;int of frac approx
	jmp	gotFracApprox

continue:
	mov	bx,300				
	tst	dh
	jz	10$				;jmp if N > ffffffh
	mov	bx,16384
10$:
	div	bx				;calc initial approx
	add	ax,2				;initial approx

nextApprox:
	;   Loop calculating the integer, but ignoring the frac.
	;   

	mov_tr	bx,ax				;save current approx
	mov	ax,si				;number int low
	mov	dx,di				;number int high
	div	bx				;number/approx
	add	ax,bx				;add approx
	shr	ax,1				;take average
	cmp	ax,bx				;cmp new to old
	je	gotInteger			;jmp if last 2 approxs same
	sub	bx,ax				;sub new from old
	cmp	bx,1
	je	gotInteger			;jmp if only 1 dif from last
	cmp	bx,-1
	jne	nextApprox			;fall if only 1 dif from last

gotInteger:
	;    Perform three iterations including the fractional data
	;

	mov_tr	bx,ax				;approx int

gotFracApprox:
	mov	dx,di				;number int high
	mov	cx,si				;number int low
	call	GrObjCalcFracSquareRoot

	clc					;signal success
done:
	.leave
	ret

failed:
	stc
	jmp	done

GrObjCalcSquareRoot		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjCalcFracSquareRoot
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc the square root of a number given the
		integer approximation

CALLED BY:	INTERNAL
		GrObjCalcSquareRoot

PASS:		bx: - integer approximation	
		dx:cx:bp - DWFixed number to get square root of

RETURN:		
		dx:cx - wwfixed square root

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		stack frame
			PDF_x - original Number
			PDF_y low and frac - previous approximation
			PDF_y high - max loops

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This routine should be optimized for SMALL SIZE over SPEED

		Common cases:
			unknown

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/17/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjCalcFracSquareRoot		proc	near
	uses	ax,bx,di,bp,si
	.enter

	sub	sp, size PointDWFixed
	mov	di,sp

	mov	ss:[di].PDF_y.DWF_int.high,8		;max loops
	movdwf	ss:[di].PDF_x,dxcxbp			;N
	mov	cx,bx					;A int
	jcxz	yowza
	clr	bp					;A frac

nextApprox:
	mov	ss:[di].PDF_y.DWF_int.low,cx		;
	mov	ss:[di].PDF_y.DWF_frac,bp
	mov	bx,cx
	mov	ax,bp
	movdwf	dxcxbp,ss:[di].PDF_x
	call	GrSDivDWFbyWWF				;N/A
	mov	si,ax					;A frac
	mov_tr	ax,bx					;A int
	mov	bx,dx					;N/A int high
	cwd						;sign extend A
	adddwf	bxcxbp,dxaxsi				;N/A + A
	shrdwf	bxcxbp,1				;(N/A + A)/2

	dec	ss:[di].PDF_y.DWF_int.high
	jz	gotIt
	cmp	ss:[di].PDF_y.DWF_int.low,cx
	jne	nextApprox
	mov	dx,ss:[di].PDF_y.DWF_frac
	cmp	dx,bp
	je	gotIt
	sub	dx,bp
	cmp	dx,1
	je	gotIt
	cmp	dx,-1
	jne	nextApprox

gotIt:
	mov	dx,cx
	mov	cx,bp

	add	sp,size PointDWFixed

	.leave
	ret

yowza:
	;    GrSDivDWFbyWWF doesn't handle div by zero well
	;    this will prevent that

	mov	bp,8000h				;A frac
	jmp	nextApprox

GrObjCalcFracSquareRoot		endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrObjNormalizeDegrees
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set degrees to be between 0 and 360

CALLED BY:	INTERNAL
		GrObjRotateRelative

PASS:		
		dx:cx - WWFixeddegrees

RETURN:		
		dx:cx - 0 <= degrees < 360

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	2/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GrObjNormalizeDegrees		proc	far

	uses	ax
	.enter
	mov	ax, 360
	add	dx, ax			;we really want to start at "again",
					;but an add and a subtract seem faster
					;than jmp...
above:
	sub	dx, ax
again:
	cmp	dx, ax
	jge	above
	tst	dx
	jl	below
	.leave
	ret
below:
	add	dx, ax
	jmp	short again

GrObjNormalizeDegrees		endp


GrObjExtInteractiveCode	ends



