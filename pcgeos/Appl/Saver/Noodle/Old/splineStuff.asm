COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Noodle screen saver
FILE:		splineStuff.asm

AUTHOR:		Chris Boyke

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	5/91		Initial version

ROUTINES:
		SplineCalcPolynomialPair
		SplineCalcCoefficients
		SplineConvertCurveToPolyline

DESCRIPTION:
	Spline math calculation routines pulled (and modified slightly)
	from the spline application

	$Id: splineStuff.asm,v 1.1 97/04/04 16:46:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;***************************************************************************
; MACROS:
;***************************************************************************

Neg32   macro   high, low
        neg     low             ;; negate low, leaving CF in opposite state
        not     high            ;;  from that desired ('not' doesn't change CF)
        cmc                     ;; Get CF to proper state (1 if low was 0)
        adc     high, 0         ;; Ripple carry to high to complete operation
endm



;***************************************************************************
; SMUL - signed multiply- multiply AX by CX, storing result in DX:AX
; ax or cx may be negative.  BL is used as a sign register
; 
; DESTROYED:  bx
; This is possibly one of the most obscure pieces of code I've ever written
;***************************************************************************

SMUL 	macro	
local Pos_result
	mov	bl, 1		;; start with sign positive
IRP reg, <ax, cx>
local Pos_&reg
	cmp	reg, 0
	jge	Pos_&reg
	neg	bl		;; sign is negative
	neg	&reg		;; make operand positive
Pos_&reg:
endm				;; end IRP'ing 
	mul	cx
	cmp	bl, 1		;; is the sign positive?
	je	Pos_result	;; yes, then done
	Neg32	dx, ax		;; NO, change sign.
Pos_result:
endm
	

;***************************************************************************
; MovPoint	- move one point structure to another
;***************************************************************************

MovPoint macro	dest, source, reg
	mov	reg, source.P_x
	mov	dest.P_x, reg
	mov	reg, source.P_y	
	mov	dest.P_y, reg
endm

	

NoodleCode	segment


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineCalcPolynomialPair
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate a pair of cubic polynomials
	 given coefficents and a t-value
		

CALLED BY:	internal to SplineMath

PASS:		ds:si - coefficients (in a CoeffStruc)
		ax = t

RETURN:		ax = X(t)
		bx = Y(t)

DESTROYED:	nothing

REGISTER/STACK USAGE:	bx.ax is t, dx.cx is a running total

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:	Should be optimized to multiply WWFixed by
	WORD

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCalcPolynomialPair	proc	near	uses cx, dx, si

	.enter
	clr	bx		; clear high word of bx.ax

IRP field, <P_x, P_y >
	clr	cx
	mov	dx, ds:[si].a.field		; get "a" coefficient
	tst	dx
	jz	aZero_&field
	call	GrMulWWFixed		; result in dx.cx  (A * t)

aZero_&field:
	add	dx, ds:[si].b.field	; A * t + B
	call	GrMulWWFixed		; (A * t + B) * t
	add	dx, ds:[si].c.field	; (A * t + B) * t + C
	call	GrMulWWFixed		; ((A * t + B) * t + C) * t
	add	dx, ds:[si].d.field	; ((A * t + B) * t + C * t) + D

	push	dx			; save integer portion of value
ENDM
	pop	bx			; Y(t)
	pop	ax			; X(t)
	.leave
	ret
SplineCalcPolynomialPair	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineCalcCoefficients
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the coefficients needed to evaluate the 
	Bezier polynomials using Horner's rule

CALLED BY:	CalcCurve

PASS:		ds:si - points in a CurveStruc (P0, P1, P2, P3)
		ds:di - CoeffStruc (a, b, c, d)

RETURN:		a = (-P0 + 3P1 - 3P2 + P3)
		b = (3P0 - 6P1 + 3P2)
		c = (-3P0 + 3P1)
		d = P0

DESTROYED:	nothing

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	use IRP -- makes the procedure very long, but
	also, very short!

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineCalcCoefficients	proc	near	uses ax,bx,cx,dx,si,di
	CC_3P0	local	Point
	CC_3P1	local	Point
	CC_6P1	local	Point
	CC_3P2	local	Point
	.enter

IRP field, <P_x, P_y>

; First, perform multiplications

	mov	ax, ds:[si].CS_P0.field
	mov	cx, 3
	SMUL
	mov	CC_3P0.field, ax	; save 3 * P0

	mov	ax, ds:[si].CS_P1.field	; get P1
	SMUL
	mov	CC_3P1.field, ax	; save 3 * P1
	
	shl	ax, 1			; multiply by 2
	mov	CC_6P1.field, ax	; save 6 * P1

	mov	ax, ds:[si].CS_P2.field ; get P2
	SMUL
	mov	CC_3P2.field, ax	; save 3 * P2

; now, do the adds

	mov	ax, ds:[si].CS_P0.field	; (-P0 + 3*P1 - 3*P2 + P3)
	neg	ax
	add	ax, CC_3P1.field
	sub	ax, CC_3P2.field
	add	ax, ds:[si].CS_P3.field
	mov	ds:[di].a.field, ax		; save "A" coeff

	mov	ax, CC_3P0.field		; (3*P0 - 6*P1 + 3*P2)
	sub	ax, CC_6P1.field
	add	ax, CC_3P2.field
	mov	ds:[di].b.field, ax	; save "B" coeff

	mov	ax, CC_3P0.field	; (-3*P0 + 3*P1)
	neg	ax
	add	ax, CC_3P1.field
	mov	ds:[di].c.field, ax	; save "C"

	mov	ax, ds:[si].CS_P0.field
	mov	ds:[di].d.field, ax	; "D" coeff
ENDM
	.leave
	ret
SplineCalcCoefficients	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	SplineConvertCurveToPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert the current spline curve to a polyline

CALLED BY:	

PASS:		es:si - Noodle
		ax - current point number
		es:di - polyline structure

RETURN:		nothing

DESTROYED:	nothing

REGISTER/STACK USAGE:	
PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	4/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SplineConvertCurveToPolyline	proc	near	uses ax,bx,cx,dx, si, ds,di,bp
	.enter
	segmov	ds, es, ax		; make ds = es

	mov	bp, di			; save polyline address
	mov	di, si			; get start of Noodle
	add	di, offset N_coefficients  ; ds:di = coefficients
	add	si, offset N_points	   ; ds:si = points
	call	SplineCalcCoefficients	; calculate coefficients
	
	xchg	di, bp			; restore polyline address
; NOW:
; si = points
; di = polyline
; bp = coefficients

;
; First, store the LAST point at the end of the polyline
;
	DoPush	si, di
	add	si, 3 * size Point
	add	di, (NOODLE_POINTS_PER_POLYLINE-1)*size Point
	MovPoint ds:[di], ds:[si], ax
	DoPopRV	si, di

; Now, store the FIRST point

	MovPoint  ds:[di], ds:[si], ax
	add	di, size Point		; first point is already there

; now, set up variables to calc other points

	mov	cx, NOODLE_POINTS_PER_POLYLINE-2 
	mov	dx, DELTA_T
	mov	ax, dx
	mov	si, bp			; coefficients in si
startLoop:
	call	SplineCalcPolynomialPair  ; calc X(t) and Y(t)
foo:
	stosw				; store X(t)
	mov	ax, bx			; store Y(t)
	stosw
	add	dx, DELTA_T
	mov	ax, dx			; get next t value
	loop	startLoop		; repeat
done:
	.leave
	ret

SplineConvertCurveToPolyline	endp
		

NoodleCode	ends
