COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusTrans.asm

AUTHOR:		Gene Anderson, May 30, 1990

ROUTINES:
	Name			Description
	----			-----------
	FormTrans		Form set of linear functionals.
	SortORUsPXLs		Sort ORUs and PXLs by ORUs

	NullTrans		x and y depend only on x or y
	Trans1			x depends on y, y depends on x
	Trans2			x depends on y, y depends on both
	Trans3			x depends on x, y depends on y
	Trans5			x depends on x, y depends on x
	Trans6			x depends on both, y depends on y
	Trans7			x depends on both, y depends on x
	Trans8			x depends on both, y depends on both

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/30/90		Initial revision

DESCRIPTION:
	Routines for transforming outline data points.

	$Id: nimbusTrans.asm,v 1.1 97/04/18 11:45:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Form a set of linear functions to perform interpolation
		betweeen outline and pixel space.
CALLED BY:	XTuples(), YTuples()

PASS:		ds:si - ptr to NimbusFuncs to use (xvars or yvars)
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	for each pair [i, i-1], restate:

	    orus[i] - o		  pxls[i] - p
	------------------- = -------------------
	orus[i] - orus[i-1]   pxls[i] - pxls[i-1]

	as:
	    p = scale(o, scl) + off

	and solve for scl (in 32768-ths), and off (in 16-ths)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormTrans	proc	near
	.enter

	;
	;/* first sort the ORU's and PXL's ascending */
	call	SortORUsPXLs
	;
	;/* form the functionals */
	;
	mov	cx, ds:[si].NF_num		;cx <- # of values
	dec	cx
	jcxz	done				;branch if nothing to do
funcLoop:
	add	si, size word			;i++;
	mov	dx, ds:NF_pxls[si]
	sub	dx, ds:NF_pxls[si][-2]		;a = pxls[i] - pxls[i-1];
	mov	bx, ds:NF_orus[si]
	sub	bx, ds:NF_orus[si][-2]		;= orus[i] - orus[i-1];
	clr	ax
	sarwwf	dxax				;dx.ax <- (a << 15)
	cmp	bx, 2
	jle	divideSmall
	idiv	bx
afterDivide:
	mov	ds:NF_scls[si], ax		;scls[i] = ... / ...
	mov	dx, ax				;dx <- scls[i]
	mov	ax, ds:NF_pxls[si][-2]
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1				;pxls[i-1] << 4;
	mov	ds:NF_offs[si], ax		;offs[i] = ...
	mov	ax, ds:NF_orus[si][-2]		;ax <- orus[i-1]
	call	Scale				;Scale(orus[i-1], scls[i]);
	sub	ds:NF_offs[si], ax		;offs[i] -= ...

	loop	funcLoop
done:
	.leave
	ret

divideSmall:
	jl	divideByOne			;branch if < 2 (ie. one)
	sardw	dxax				;else divide by 2 (>>1)
	jmp	afterDivide

divideByOne:
	mov	ax, dx				;don't bother with divide
	jmp	afterDivide
FormTrans	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SortORUsPXLs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Simple ascending sort of <pxls> and <orus> by <orus>
CALLED BY:	FormTrans()

PASS:		ds:si - ptr to NimbusFuncs to sort (xvars or yvars)
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	Does the ever-popular Shell sort. This is about optimal
	considering (a) the # of elements (b) the elements are
	in an array, so inserting items is potentially painful.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REGISTER USAGE:
	bp - gap
	di - i
	bx - j
	cx - n
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SortORUsPXLs	proc	near
	uses	si, bp
	.enter

	mov	bp, ds:[si].NF_num		;for (gap = n / 2 ;...;...)
	mov	cx, bp				;cx <- n
gapLoop:
	mov	di, bp				;for (i = gap ;...;...)
sortLoop:
	cmp	di, cx				;(...; i < n ;...)
	jae	nextGap
	mov	bx, di				;for (j = i - gap ;...;...)
	push	di
cmpLoop:
	sub	bx, bp				;(...;...; j -= gap)
	js	nextSort			;(...; j >= 0 ;...)
	push	bx
	shl	bx, 1
	mov	ax, ds:[si][bx].NF_orus
	mov	di, si				;di <- j
	add	di, bp				;di <- j+gap
	add	di, bp
	cmp	ax, ds:[di][bx].NF_orus
	jl	nextSort2
	xchg	ds:[di][bx].NF_orus, ax		;swap(orus[j],orus[j+gap]);
	mov	ds:[si][bx].NF_orus, ax
	mov	ax, ds:[si][bx].NF_pxls
	xchg	ds:[di][bx].NF_pxls, ax		;swap(pxls[j],orus[j+gap]);
	mov	ds:[si][bx].NF_pxls, ax
	pop	bx
	jmp	cmpLoop
nextSort2:
	pop	bx
nextSort:
	pop	di
	inc	di				;(...;...; i++)
	jmp	sortLoop
nextGap:
	shr	bp, 1				;(...;...; gap /= 2)
	jnz	gapLoop				;(...; gap > 0 ;...)

	.leave
	ret
SortORUsPXLs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NullTransX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on y, y depends on y (case 0)
			- or -
		x depends on x, y depends on x (case 4)
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NullTrans	proc	near
	clr	ax
	clr	bx
	ret
NullTrans	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoXScan, DoYScan
		DoXScale, DoYScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do full, possibly painful, transformation for x or y.
CALLED BY:	Trans{1,2,3,5,6,7}

PASS: 		DoXScan:
		DoYScan:
			ax - value to scan for
		DoXScale:
		DoYScale:
			(ax,bx) - (x,y) coordinate
RETURN:		DoXScan:
		DoYScan:
		DoXScale:
			ax - transformed value
		DoYScale:
			bx - transformed value
DESTROYED:	dx, si

PSEUDO CODE/STRATEGY:
	DoXScan:
		i = 1;
		while (i < x_num - 1 && y > y_orus[i])
			i++;
		return(x_offs[i] + scale(x, x_scls[i]));
	DoXScale:
		return(scale(x,transform[0]) + scale(y,transform[1]));
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DoXScan	proc	near
	uses	cx
	.enter

	mov	si, size word			;i = 1;
	mov	cx, ds:xvars.NF_num
	dec	cx
	shl	cx, 1				;cx <- x_num - 1
scanLoop:
	cmp	si, cx				;while (i < x_num - 1
	jae	afterScan
	cmp	ax, ds:xvars.NF_orus[si]	;&& x > x_orus[i])
	jle	afterScan
	add	si, size word			;i++;
	jmp	scanLoop

afterScan:
	mov	dx, ds:xvars.NF_scls[si]
	call	Scale				;ax <- scale(x, x_scls[i]);
	add	ax, ds:xvars.NF_offs[si]	;ax <- x_offs[i] + ...

	.leave
	ret
DoXScan	endp

DoYScan	proc	near
	uses	cx
	.enter

	mov	si, size word			;i = 1;
	mov	cx, ds:yvars.NF_num
	dec	cx
	shl	cx, 1				;cx <- y_num - 1
scanLoop:
	cmp	si, cx				;while (i < y_num - 1
	jae	afterScan
	cmp	ax, ds:yvars.NF_orus[si]	;&& y > y_orus[i])
	jle	afterScan
	add	si, size word			;i++;
	jmp	scanLoop

afterScan:
	mov	dx, ds:yvars.NF_scls[si]
	call	Scale				;ax <- scale(y, y_scls[i]);
	add	ax, ds:yvars.NF_offs[si]	;ax <- y_offs[i] + ...

	.leave
	ret
DoYScan	endp

DoXScale	proc	near
	uses	bx
	.enter

	xchg	ax, bx				;ax <- y, bx <- x
	mov	dx, ds:GenData.transform1
	call	Scale				;scale(y,transform[1]);
	xchg	ax, bx				;bx <- f(y), ax <- x
	mov	dx, ds:GenData.transform0
	call	Scale				;scale(x,transform[0]);
	add	ax, bx				;ax <- scl(x,t[0])+scl(y,t[1]);

	.leave
	ret
DoXScale	endp

DoYScale	proc	near
	uses	ax
	.enter

	xchg	ax, bx				;ax <- y, bx <- x
	mov	dx, ds:GenData.transform3
	call	Scale				;scale(y,transform[3]);
	xchg	ax, bx				;bx <- f(y), ax <- x
	mov	dx, ds:GenData.transform2
	call	Scale				;scale(x,transform[2]);
	add	bx, ax				;ax <- scl(x,t[2])+scl(y,t[3]);

	.leave
	ret
DoYScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Trans1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on y, y depends on x
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-------n----
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Trans1	proc	near
	add	ax, ds:x_offset
	add	bx, ds:y_offset
	call	DoXScan				;y depends on x
	push	ax
	mov	ax, bx				;ax <- y
	call	DoYScan				;x depends on y
	pop	bx				;bx <- y'
	ret
Trans1	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Trans2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on y, y depends on both
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Trans2	proc	near
	add	ax, ds:x_offset
	add	bx, ds:y_offset
	mov	cx, ax				;cx <- x
	mov	ax, bx				;ax <- y
	call	DoYScan				;x depends on y
	xchg	ax, cx				;ax <- x, cx <- x'=f(y)
	call	DoYScale			;y depends on both
	mov	ax, cx				;ax <- x'
	ret
Trans2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Trans3
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on x, y depends on y
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Trans3	proc	near
	add	ax, ds:x_offset
	add	bx, ds:y_offset
	xchg	ax, bx				;ax <- y, bx <- x
	call	DoYScan				;y depends on y
	xchg	ax, bx				;ax <- x, bx <- y'=f(y)
	GOTO	DoXScan				;x depends on x
Trans3	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Trans5
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on x, y depends on both
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Trans5	proc	near
	add	ax, ds:x_offset
	add	bx, ds:y_offset
	call	DoYScale			;y depends on both
	GOTO	DoXScan				;x depends on x
Trans5	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Trans6
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on both, y depends on y
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Trans6	proc	near
	add	ax, ds:x_offset
	add	bx, ds:y_offset
	call	DoXScale			;x depends on both
	xchg	ax, bx				;ax <- y, bx <- x'=f(x,y)
	call	DoYScan				;y depends on y
	xchg	ax, bx				;ax <- x', bx <- y'
	ret
Trans6	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Trans7
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on both, y depends on x
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Trans7	proc	near
	add	ax, ds:x_offset
	add	bx, ds:y_offset
	mov	cx, ax				;cx <- x
	call	DoXScale			;x depends on both
	xchg	cx, ax				;ax <- x, cx <- x'=f(x,y)
	call	DoXScan				;y depends on x
	mov	ax, cx				;ax <- x'
	ret
Trans7	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Trans8
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	x depends on both, y depends on both
CALLED BY:	NimbusMoveTo(), NimbusLineTo(), ...

PASS:		(ax,bx) - untransformed point
RETURN:		(ax,bx) - transformed point
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Trans8	proc	near
	add	ax, ds:x_offset
	add	bx, ds:y_offset
	mov	cx, ax				;cx <- x
	call	DoXScale			;x depends on both
	xchg	ax, cx				;ax <- x, cx <- x'=f(x,y)
	call	DoYScale			;y depends on both
	mov	ax, cx				;ax <- x'
	ret
Trans8	endp
