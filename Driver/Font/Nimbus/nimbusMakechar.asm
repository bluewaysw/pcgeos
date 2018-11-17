COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusMakechar.asm

AUTHOR:		Gene Anderson, May 26, 1990

ROUTINES:
	Name			Description
	----			-----------
	MakeChar		Make a hinted character.
	MakeCharLow		Make (part of) a hinted character.
	XTuples			Process x hints.
	YTuples			Process y hints.
	XTriple			Process one x hint.
	YTriple			Process one y hint.
	StrokeWidth		Set stroke width to best fit.
	RefLine			Ratchet stroke to reference line.
	Extrema			Find transformed bounds of character.

	SkipTuples		Skip over x or y hints.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/26/90		Initial revision

DESCRIPTION:
	Assembly version of makechar.c
	The original C comments are provided for routine headers,
	and are imbedded in the equivalent assembly code where
	applicable.

	$Id: nimbusMakechar.asm,v 1.1 97/04/18 11:45:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a bitmap version of a character from outlines.
CALLED BY:	NimbusGenChar

PASS: 		ds - seg addr of NimbusVars
		es:di - ptr to outline data (NimbusData)
		cx - handle of outline data
RETURN:		none
DESTROYED:	ax, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: FONT and TRANSFORM set
	(ds:transform[])
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MakeChar	proc	near
	uses	bx
	.enter

	push	cx
	;
	;/* set some global stuff */
	;
	mov	ax, es:[di].ND_xmin
	mov	ds:min_x, ax
	mov	bx, es:[di].ND_ymin
	mov	ds:min_y, bx
	mov	cx, es:[di].ND_xmax
	mov	ds:max_x, cx
	mov	dx, es:[di].ND_ymax
	mov	ds:max_y, dx
	;
	;/* find extents of bitmap and allocate it */
	;
	call	Extrema				;calculate bounds
	call	AllocBMap			;allocate bitmap
	;
	;/* finally...process the character and set deltas */
	;
	clr	ax
	mov	ds:x_offset, ax
	mov	ds:y_offset, ax
	pop	cx				;cx <- handle of odata
	call	MakeCharBase			;create the character

	.leave
	ret
MakeChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeCharLow, MakeCharBase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make a bitmap (or a piece thereof)
CALLED BY:	MakeChar()

PASS:		ds - seg addr of NimbusVars
		es:di - ptr to outline data (NimbusData)
		cx - handle of outline data
RETURN:		none
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MakeCharBase	label	near
	clr	ax
	mov	ds:xvars.NF_num, ax		;x_num = 0;
	mov	ds:yvars.NF_num, ax		;y_num = 0;
MakeCharLow	proc	near
	uses	bx, di, si
	.enter

	push	cx				;save handle of outline data
	;
	;/* skip SW and BBOX */
	;
	add	di, size NimbusData		;skip bounds
	;
	;/* process or skip x_hints */
	;
	mov	dx, ds:GenData.CGD_x_scl	;dx <- x_scl
	tst	dx
	jz	skipXhints			;branch if not using x hints
	call	XTuples				;process x hints
skipXhints:
	call	SkipTuples			;skip x hints
	;
	;/* process or skip y_hints */
	;
	mov	dx, ds:GenData.CGD_y_scl	;dx <- y_scl
	tst	dx
	jz	skipYhints			;branch if not using y hints
	call	YTuples				;process y hints
skipYhints:
	call	SkipTuples
	;
	;/* process segments of the character */
	;
	clr	ax
	mov	ds:h_count, ax
	mov	ds:v_count, ax
	call	Segments			;process character commands

	tst	ds:GenData.CGD_check		;if (check)
	jz	skipCheck
	call	CheckHoles			;check for gaps in strokes
skipCheck:
	pop	bx				;bx <- handle of outline data
	call	MemUnlock			;done with outline data

	.leave
	ret
MakeCharLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SkipTuples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Skip over the x or y hint tuples.
CALLED BY:	MakeCharLow(), MakeBigChar()

PASS:		es:di - ptr to # of tuples
RETURN:		es:di - ptr past tuples
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Assumes size(tuple) = 3*size(word) = 6
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SkipTuples	proc	near
	mov	al, es:[di]
	clr	ah				;ax <- # of triples
	shl	ax, 1
	mov	bx, ax				;bx <- #*2
	shl	ax, 1				;ax <- #*4
	add	ax, bx				;ax <- #*6 = #*3*size(word)
	inc	ax				;one for # of tuples
	add	di, ax				;skip triples
	ret
SkipTuples	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XTuples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process the x_tuples -- the hints for vertical strokes
CALLED BY:	MakeCharLow()

PASS:		ds - seg addr of NimbusVars
		es:di - ptr to x tuples (NimbusTuple[])
		dx - x_scl
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

XTuples	proc	near
	uses	di
	.enter

	;
	;/* first the default triple */
	;
	mov	ax, -2047			;ax <- start
	mov	bx, 2047			;bx <- end
	clr	cx				;cx <- width
	call	XTripleNoAdjust			;XTriple(ax,bx,cx, x_scl)
	;
	;/* now process the real triples ... if any */
	;
	mov	cl, es:[di]
	clr	ch				;cx <- # of triples
	jcxz	afterTuples			;branch if no hints
	inc	di				;skip # of triples
tupleLoop:
	push	cx
	mov	ax, es:[di].NT_start		;ax <- start
	mov	bx, es:[di].NT_end		;bx <- end
	mov	cx, es:[di].NT_width		;cx <- width
	call	XTriple				;process one x triple
	add	di, size NimbusTuple		;advance to next triple
	pop	cx
	loop	tupleLoop			;loop while more hints
afterTuples:
	;
	;/* finally, turn the triples into a set of linear functionals */
	;
	mov	si, offset xvars		;ds:si <- ptr to NimbusFuncs
	call	FormTrans

	.leave
	ret
XTuples	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YTuples
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Proces the y_tuples -- hints for horizontal strokes
CALLED BY:	MakeCharLow()

PASS:		ds - seg addr of NimbusVars
		es:di - ptr to y tuples (NimbusTuple[])
		dx - y_scl
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YTuples	proc	near
	uses	di
	.enter

	;
	;/* first the real triples */
	;
	mov	cl, es:[di]
	clr	ch				;cx <- # of triples
	jcxz	afterTuples			;branch if no hints
	inc	di				;skip # of triples
tupleLoop:
	push	cx
	mov	ax, es:[di].NT_start		;ax <- start
	mov	bx, es:[di].NT_end		;bx <- end
	mov	cx, es:[di].NT_width		;cx <- width
	call	YTriple			;process one triple
	add	di, size NimbusTuple		;advance to next triple
	pop	cx
	loop	tupleLoop			;loop while more hints
afterTuples:
	;
	;/* now automatic hints on <ly,hy> ... if not already present */
	;
	mov	cx, ds:yvars.NF_num		;cx <- # hints set
	mov	ax, ds:max_y			;ax <- max y
	call	DoAutoYHint
	mov	ax, ds:min_y			;ax <- min y
	call	DoAutoYHint
	;
	;/* turn the triples into a set of linear functionals */
	;
	mov	si, offset yvars		;ds:si <- ptr to NimbusFuncs
	call	FormTrans

	.leave
	ret
YTuples	endp

;
;if (y_num == index_of(@@, y_num, y_orus)) {
;	y_orus[y_num] = @@;
;	y_pxls[y_num++] = refline(scale(scl, @@));
;}
;
DoAutoYHint	proc	near
	;
	; adjust for accent character
	;
	add	ax, ds:y_offset
	mov	di, offset yvars.NF_orus	;ds:di <- array to scan
	call	IndexOf				;see if max y in hints
	jc	isPresent			;branch if already there
	mov	ds:yvars.NF_orus[di], ax	;y_orus[y_num] = max y
	call	Scale				;Scale(y_scl, max y)
	call	RefLine				;ratchet to reference line
	mov	ds:yvars.NF_pxls[di], ax	;y_pxls[y_num] = refline(...);
	inc	ds:yvars.NF_num			;y_num++;
	mov	cx, ds:yvars.NF_num		;cx <- y_num
isPresent:
	ret
DoAutoYHint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XTriple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single x_hint
CALLED BY:	XTuples()

PASS:		ax - start of x hint
		bx - end of x hint
		cx - stroke width for x hint
		dx - x_scl
		ds - seg addr of NimbusVars
RETURN:		none
DESTROYED:	ax, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

XTriple	proc	near
	;
	; adjust for accent character
	;
	add	ax, ds:x_offset			;s[0] += dx;
	add	bx, ds:x_offset			;s[1] += dx;

XTripleNoAdjust	label	near
	uses	di
	.enter

	;
	;/* have we already computed the pixel coordinate of the start point? */
	;
	push	cx				;save stroke width
	mov	cx, ds:xvars.NF_num		;cx <- # of x refs
	mov	di, offset xvars.NF_orus	;ds:di <- array to scan
	call	IndexOf				;see if already hinted
	jnc	computeXPixel			;branch if not hinted
	;
	;/* yes ... use it */
	;
	mov	bp, ds:xvars.NF_pxls[di]	;bp <- x_pxls[w];
	;
	;/* unless we already know it...position the other side of the stroke */
	;
afterPixelFound:
	mov	si, ax				;si <- start of x hint
	mov	ax, bx				;ax <- end of x hint
	mov	di, offset xvars.NF_orus	;ds:di <- array to scan
	call	IndexOf				;see if already hinted
	pop	cx				;cx <- stroke width
	jc	done				;branch if other side hinted
	mov	ds:xvars.NF_orus[di], ax	;x_orus[x_num] = b;
	mov	ax, si				;ax <- start of x hint
	call	StrokeWidth			;find stroke_width(a,b,c,scl)
	add	ax, bp				;ax <- p + stroke_width(...)
	mov	ds:xvars.NF_pxls[di], ax	;x_pxls[x_num] = p + ...
	inc	ds:xvars.NF_num			;x_num++;
done:
	.leave
	ret

	;
	;/* no ... round the scaled value to the nearest pixel */
	;
computeXPixel:
	mov	ds:xvars.NF_orus[di], ax	;x_orus[x_num] = a;
	push	ax
	call	Scale				;w = scale(x_scl, a)
	ROUND	ax
	mov	bp, ax				;bp <- ROUND(w)
	mov	ds:xvars.NF_pxls[di], ax	;x_pxls[x_num] = ROUND(w)
	pop	ax
	inc	ds:xvars.NF_num			;x_num++;
	mov	cx, ds:xvars.NF_num		;cx <- x_num
	jmp	afterPixelFound
XTriple	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YTriple
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a single y-hint
CALLED BY:	YTuples()

PASS:		ax - start of y hint
		bx - end of y hint
		cx - stroke width for y hint
		dx - y_scl
		ds - seg addr of NimbusVars
RETURN:		none
DESTROYED:	ax, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YTriple	proc	near
	;
	; adjust for accent character
	;
	add	ax, ds:y_offset			;s[0] += dy;
	add	bx, ds:y_offset			;s[1] += dy;

;YTripleNoAdjust	label	near
	uses	di
	.enter

	;
	;/* have we already computed the pixel coordinate of the start point? */
	;
	push	cx
	mov	cx, ds:yvars.NF_num		;cx <- # of y refs
	mov	di, offset yvars.NF_orus	;ds:di <- array to scan
	call	IndexOf				;see if already hinted
	jnc	computeYPixel			;branch if not hinted
	;
	;/* yes ... use it */
	;
	mov	bp, ds:yvars.NF_pxls[di]	;bp <- y_pxls[w];
	;
	;/* unless we already know it...position the other side of the stroke */
	;
afterPixelFound:
	mov	si, ax				;si <- start of y hint
	mov	ax, bx				;ax <- end of y hint
	mov	di, offset yvars.NF_orus	;ds:di <- array to scan
	call	IndexOf				;see if already hinted
	pop	cx				;cx <- stroke width
	jc	done				;branch if already hinted
	mov	ds:yvars.NF_orus[di], ax	;y_orus[y_num] = b;
	mov	ax, si				;ax <- start of y hint
	call	StrokeWidth			;stroke_width(a,b,c,y_scl)
	add	ax, bp				;ax <- p + stroke_width
	mov	ds:yvars.NF_pxls[di], ax	;y_pxls[y_num] = p + ...;
	inc	ds:yvars.NF_num			;y_num++;
done:
	.leave
	ret

	;
	;/* no ... compute it */
	;
computeYPixel:
	mov	ds:yvars.NF_orus[di], ax	;y_orus[y_num] = a;
	push	ax				;save start of hint
	call	Scale				;w = scale(y_scl, a);
	call	RefLine				;ratchet to reference line
	mov	bp, ax				;bp <- refline(w)
	mov	ds:yvars.NF_pxls[di], ax	;y_pxls[y_num] = refline(w);
	pop	ax				;ax <- start of y hint
	inc	ds:yvars.NF_num			;y_num++;
	mov	cx, ds:yvars.NF_num		;cx <- y_num
	jmp	afterPixelFound
YTriple	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StrokeWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find stroke width in pixels, using actual and canonical widths
CALLED BY:	XTriple(), YTriple()

PASS:		ax - start of stroke
		bx - end of stroke
		cx - ideal stroke width
		dx - scale (x_scl or y_scl)
RETURN:		ax - stroke width
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StrokeWidth	proc	near
	uses	bx, cx, dx
	.enter

	;
	;/* actual width in 16-th pixels */
	;
	sub	ax, bx
	neg	ax				;ax <- (b - a)
	call	Scale				;scale(scl, (b - a));
	tst	ax				;get sign of result
	pushf					;save sign
	jns	actualPositive			;branch if positive
	neg	ax				;ax = -aw;
actualPositive:
	;
	;/* canonical width in 16-th pixels */
	;
	xchg	ax, cx				;ax <- ideal, cx <- aw
	call	Scale				;scale(scl, c);
	tst	ax
	jns	canonicalPositive		;branch if positive
	neg	ax				;cw = -cw;
canonicalPositive:
	;
	;/* actual difference in 16-th pixels */
	;
	mov	dx, cx				;dx <- actual width
	sub	cx, ax				;cx = aw - cw;
	tst	cx
	jns	diffPositive			;branch if positive
	neg	cx				;d = -d;
diffPositive:
	;
	;/* round canonical width if close, actual width otherwise */
	;
	cmp	cx, ONE				;see if close
	jb	isClose				;branch if close
	mov	ax, dx				;ax <- actual width
isClose:
	ROUND	ax
	;
	;/* not less than 1 pixel though */
	;
	cmp	ax, 1
	jae	widthOK				;branch if > 1
	mov	ax, 1				;never want less than 1 pixel
widthOK:
	;
	;/* make the sign correct */
	;
	popf					;recover original sign
	jns	resultPositive			;branch if positive
	neg	ax				;return(-w)
resultPositive:

	.leave
	ret

StrokeWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RefLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Round <a> to nearest pixel -- if close enough to a
		reference line, use the pixel corresponding to that
		reference line.
CALLED BY:	YTuples(), YTriple()

PASS:		ax - value (16th pixels)
		ds - seg addr of NimbusVars
RETURN:		ax - value rounded to nearest pixel
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RefLine	proc	near
	uses	bx, cx, dx, si, di
	.enter

	mov	dx, 10000			;dx <- distance to nearest
	mov	cx, NUM_REFLINES		;cx <- # of ref lines
	clr	si
refLoop:
	mov	bx, ds:GenData.CGD_reflines[si]	;bx <- reference line
	sub	bx, ax				;bx <- distance to ref line
	jns	distIsPos
	neg	bx				;n = -n;
distIsPos:
	cmp	bx, dx				;if (n < d)
	jge	nextLine			;branch if not smaller
	mov	dx, bx				;d = n;
	mov	di, si				;j = i;
nextLine:
	add	si, size word			;i++;
	loop	refLoop

	cmp	dx, ONE				;if (d < ONE)
	jge	notClose			;branch if not close
	mov	ax, ds:GenData.CGD_reflines[di]	;ax <- reflines[j]
notClose:
	ROUND	ax				;round to refline or pixel

	.leave
	ret
RefLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Extrema
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a new bounding box of transformed old bounding box.
CALLED BY:	MakeChar()

PASS:		ds - seg addr of NimbusVars
		(ax,bx),(cx,dx) - bounds of character
RETURN:		(ax,bx),(cx,dx) - bounds of character, transformed
DESTROYED:	si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NB: May be larger than bounding box of character proper.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Extrema	proc	near
	bounds	local	Rectangle		;bounds of character

	uses	di
	.enter

	mov	ds:xb[0], ax
	mov	ds:xb[2], ax			;store min x
	mov	ds:xb[4], cx
	mov	ds:xb[6], cx			;store max x
	mov	ds:yb[0], bx
	mov	ds:yb[6], bx			;store min y
	mov	ds:yb[2], dx
	mov	ds:yb[4], dx			;store max y

	mov	ax, 32767
	mov	bounds.R_left, ax
	mov	bounds.R_bottom, ax
	mov	ax, -32767
	mov	bounds.R_top, ax
	mov	bounds.R_right, ax

	mov	cx, 4				;cx <- # of bounds
	clr	si
boundLoop:
	mov	dx, ds:GenData.transform0
	mov	ax, ds:xb[si]			;ax <- x[i]
	call	Scale
	mov	bx, ax				;bx <- scale(x[i],a)
	mov	dx, ds:GenData.transform1
	mov	ax, ds:yb[si]			;ax <- y[i]
	call	Scale				;scale(y[i],b);
	add	ax, bx				;ax <- scale(x[i],a)+scale(...)
	cmp	ax, bounds.R_left
	jge	notMinX
	mov	bounds.R_left, ax		;lx = xx;
notMinX:
	cmp	ax, bounds.R_right
	jle	notMaxX
	mov	bounds.R_right, ax		;hx = xx;
notMaxX:

	mov	dx, ds:GenData.transform2
	mov	ax, ds:xb[si]			;ax <- x[i]
	call	Scale
	mov	bx, ax				;bx <- scale(x[i],c)
	mov	dx, ds:GenData.transform3
	mov	ax, ds:yb[si]			;ax <- y[i]
	call	Scale				;scale(y[i],d);
	add	ax, bx				;ax <- scale(x[i],c)+scale(...)
	cmp	ax, bounds.R_bottom
	jge	notMinY
	mov	bounds.R_bottom, ax		;ly = yy;
notMinY:
	cmp	ax, bounds.R_top
	jle	notMaxY
	mov	bounds.R_top, ax		;hy = yy;
notMaxY:
	add	si, size word			;i++;
	loop	boundLoop

	;
	;/* be generous */
	;
	mov	ax, bounds.R_left
	TRUNC	ax
	dec	ax				;*plx = TRUNC(lx) - 1;
	mov	bx, bounds.R_bottom
	TRUNC	bx
	dec	bx				;*ply = TRUNC(ly) - 1;
	mov	cx, bounds.R_right
	CEIL	cx
	inc	cx				;*phx = CEIL(hx) + 1;
	mov	dx, bounds.R_top
	CEIL	dx
	inc	dx				;*phy = CEIL(hy) + 1;

	.leave
	ret
Extrema	endp
