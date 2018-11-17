COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusContinuity.asm

AUTHOR:		Gene Anderson, May 30, 1990

ROUTINES:
	Name			Description
	----			-----------
	XPixelate		Scan vertically at x coordinates
	CheckHoles		Check for missing strokes
	LSort			Sort list of longs

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/30/90		Initial revision

DESCRIPTION:
	Routines exclusively for dealing with continuity checking.
	x_count & y_count are actually 4X the number of points
	stored, as the points are double words, or 4 bytes. This
	allows indexing into the array more quickly.

	$Id: nimbusContinuity.asm,v 1.1 97/04/18 11:45:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XPixelate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan vertically at half-integer x-coordinates.
CALLED BY:	Pixelate()

PASS:		ds:guano - bitmap to use
		ds:x_list[] - array of points
		ds:x_count - # of points
		(ax,bx),(cx,dx) - end points of line
RETURN:		ds:x_list[] - array of points
		ds:x_count - # of points, updated
DESTROYED:	di, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

XPixelate	proc	near
	uses	ax, bx, cx, dx

	;
	;/* ignore verticals */
	;
	cmp	ax, cx				;if (x0 == x1)
	je	ignoreVertical
	.enter
	;
	;/* make segment point left-to-right */
	;
	jl	ordered
	xchg	ax, cx
	xchg	bx, dx
ordered:
	;
	; (ax,bx) = (x0,y0)
	; (cx,dx) = (x1,y1)
	; si = x   bp = t   di = x_count
	;
	;/* set x at first half integer */
	;
	mov	si, ax				;si <- x0
	mov	bp, ax
	andnf	si, FRACTION			;si <- FRACTION(x0)
	shl	si, 1				;table of words...
	add	bp, cs:vector[si]		;x = x0 + vector[FRACTION(x0)];
	mov	si, bp				;si <- x
	TRUNC	bp				;t = TRUNC(x);
	;
	;/* compute the y's */
	;
	mov	di, ds:h_count			;di <- x_count
yLoop:
	cmp	si, cx				;while (x < x1)
	jge	done
	cmp	di, MAX_COUNT*(size word)	;&& (x_count < MAX_COUNT)
	jae	done
	push	ax, bx, cx, dx, si
	xchg	si, ax				;si <- x0, ax <- x
	sub	ax, cx				;ax <- -(x1 - x)
	sub	bx, dx				;bx <- -(y1 - y0)
	sub	cx, si				;cx <- +(x1 - x0)
	push	dx
	imul	bx				;dx:ax <- a*b
	idiv	cx				;dx:ax <- a*b/c
	pop	dx
	sub	dx, ax				;y = y1 - ...
	;
	;/* !!! gotta keep those lo words positive for <lsort> !!! */
	;
	mov	ds:h_list_y[di], dx		;x_list[x_count].b.lo = y+16384
	pop	ax, bx, cx, dx, si
	mov	ds:h_list_x[di], si		;x_list[x_count].b.hi = x
	add	di, size word			;x_count++;
	add	si, ONE				;x += ONE;
	inc	bp				;t += 1;
	jmp	yLoop

done:
	mov	ds:h_count, di			;store new x_count
	.leave
ignoreVertical:
	ret
XPixelate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckHoles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure we catch the significant strokes
CALLED BY:	MakeCharLow()

PASS:		ds - seg addr of NimbusVars
		ds:x_count, ds:x_list,
		ds:y_count, ds:y_list - #, points for check
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Instead of storing the (x,y) coordinates in a single list
	of longs, I store them in two separate lists. This way I
	don't need to hooey around with all this adding and
	subtracting of 16384 to:
		"keep those lo words positive for lsort!!!"
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHoles	proc	near
	uses	bp
	.enter

	;
	;/* make sure near-verticals are continuous */
	;
	mov	cx, ds:v_count			;cx <- # of y pixels * 2
	cmp	cx, MAX_COUNT*(size word)	;if (y < MAX_COUNT)
	jae	afterVerticals			;if too many, don't bother
	call	LSortVertical
	clr	si				;i = 0;
verticalLoop:
	cmp	si, cx				;while (i < y_count)
	jae	afterVerticals
	mov	bp, ds:v_list_y[si]		;y = y_list[i].b.hi;
	mov	bx, ds:v_list_x[si]		;x0 = y_list[i++].b.lo - 16384;
	mov	ax, ds:v_list_x[si][2]		;x1 = y_list[i++].b.lo - 16384;
	add	si, 2*(size word)		;i += 2;
	mov	dx, ax				;dx <- x1
	sub	ax, bx				;ax = (x1 - x0);
	js	verticalLoop			;if ((x1 - x0) > 0)
	je	verticalLoop
	cmp	ax, TWO				;&& ((x1 - x0) < TWO)
	jge	verticalLoop
	add	bx, dx
	sar	bx, 1				;x = (x0 + x1) >> 1;
	call	SetBit				;setbit(bmap,TRUNC(x),TRUNC(y));
	jmp	verticalLoop

afterVerticals:
	;
	;/* make sure near-horizontals are continuous */
	;
	mov	cx, ds:h_count			;cx <- # of x pixels * 2
	cmp	cx, MAX_COUNT*(size word)	;if (x < MAX_COUNT)
	jae	afterHorizontals
	call	LSortHorizontal
	clr	si				;i = 0;
horizontalLoop:
	cmp	si, cx				;while (i < x_count)
	jae	afterHorizontals
	mov	bx, ds:h_list_x[si]		;x = x_list[i].b.hi;
	mov	bp, ds:h_list_y[si]		;y0 = y_list[i++].b.lo - 16384;
	mov	ax, ds:h_list_y[si][2]		;y1 = y_list[i++].b.lo - 16384;
	add	si, 2*(size word)		;i += 2;
	mov	dx, ax				;dx <- y1
	sub	ax, bp				;ax = (y1 - y0);
	js	horizontalLoop			;if ((y1 - y0) > 0)
	je	horizontalLoop
	cmp	ax, TWO				;&& ((y1 - y0) < TWO)
	jge	horizontalLoop
	add	bp, dx
	sar	bp, 1				;y = (y0 + y1) >> 1;
	call	SetBit				;setbit(bmap,TRUNC(x),TRUNC(y));
	jmp	horizontalLoop

afterHorizontals:

	.leave
	ret
CheckHoles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LSortVertical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort list of near vertical strokes.
CALLED BY:	CheckHoles()

PASS:		cx - v_count * (size word)
		ds:v_list_y - list of y coordinates (primary sort)
		ds:v_list_x - list of x coordinates
RETURN:		none
DESTROYED:	ax, bx, dx, di, bp

REGISTER USAGE:
	cx - n
	bx - i
	bp - gap
	di - j
	si - j+gap
PSEUDO CODE/STRATEGY:
	Does the ever-popular Shell sort. This is about optimal
	considering (a) the # of elements (b) the elements are
	in an array, so inserting items is potentially painful.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LSortVertical	proc	near
	uses	cx
	.enter

	mov	bp, cx				;bp <- n*2
gapLoop:
	mov	bx, bp				;for (i = gap ;...;...)
sortLoop:
	cmp	bx, cx				;(...; i < n ;...)
	jae	nextGap
	mov	di, bx				;for (j = i - gap ;...;...)
cmpLoop:
	sub	di, bp				;(...;...; j -= gap)
	js	nextSort			;(...; j >= 0 ;...)
	mov	si, di
	add	si, bp				;si <- j+gap
	mov	dx, ds:v_list_x[di]
	mov	ax, ds:v_list_y[di]
	cmp	ax, ds:v_list_y[si]
	jl	nextSort
	jg	doSwap
	cmp	dx, ds:v_list_x[si]
	jl	nextSort
doSwap:
	xchg	ds:v_list_y[si], ax		;swap(list[j],list[j+gap]);
	mov	ds:v_list_y[di], ax
	xchg	ds:v_list_x[si], dx
	mov	ds:v_list_x[di], dx
	jmp	cmpLoop

nextSort:
	add	bx, size word			;(...;...; i++)
	jmp	sortLoop
nextGap:
	shr	bp, 1				;(...;...; gap /= 2)
	and	bp, 0xfffe			;keep word aligned
	jnz	gapLoop				;(...; gap > 0 ;...)

	.leave
	ret
LSortVertical	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LSortHorizontal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sort list of near horizontal strokes.
CALLED BY:	CheckHoles()

PASS:		cx - h_count * (size word)
		ds:h_list_x - list of x coordinates (primary sort)
		ds:h_list_y - list of y coordinates
RETURN:		none
DESTROYED:	ax, bx, dx, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LSortHorizontal	proc	near
	uses	cx
	.enter

	mov	bp, cx				;bp <- n*2
gapLoop:
	mov	bx, bp				;for (i = gap ;...;...)
sortLoop:
	cmp	bx, cx				;(...; i < n ;...)
	jae	nextGap
	mov	di, bx				;for (j = i - gap ;...;...)
cmpLoop:
	sub	di, bp				;(...;...; j -= gap)
	js	nextSort			;(...; j >= 0 ;...)
	mov	si, di
	add	si, bp				;si <- j+gap
	mov	dx, ds:h_list_y[di]
	mov	ax, ds:h_list_x[di]
	cmp	ax, ds:h_list_x[si]
	jl	nextSort
	jg	doSwap
	cmp	dx, ds:h_list_y[si]
	jl	nextSort
doSwap:
	xchg	ds:h_list_x[si], ax		;swap(list[j],list[j+gap]);
	mov	ds:h_list_x[di], ax
	xchg	ds:h_list_y[si], dx
	mov	ds:h_list_y[di], dx
	jmp	cmpLoop

nextSort:
	add	bx, size word			;(...;...; i++)
	jmp	sortLoop
nextGap:
	shr	bp, 1				;(...;...; gap /= 2)
	and	bp, 0xfffe			;keep word aligned
	jnz	gapLoop				;(...; gap > 0 ;...)

	.leave
	ret
LSortHorizontal	endp

