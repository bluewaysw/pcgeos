COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		nimbusSegments.asm

AUTHOR:		Gene Anderson, May 27, 1990

ROUTINES:
	Name			Description
	----			-----------
	Segments		Process character commands

	NimbusMoveTo		Move CP
	NimbusLineTo		Draw line from CP to (x,y)
	NimbusBezierTo		Draw Bezier from CP to (x3,y3) through points
	NimbusAccentChar	Draw char 1, offset (x,y), draw char 2
	NimbusVertLineTo	Draw line from CP to (x,+/-y)
	NimbusHorizLineTo	Draw line from CP to (+/-x,y)
	NimbusRelLineTo		Draw line from CP to (+/-x,+/-y)
	NimbusRelBezierTo	Draw Bezier from CP to offset points

	Pixelate		Rasterize a line segment
	Vectorize		Rasterize a Bezier curve
	YPixelate		Scan horizontally at y coodinates

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	5/27/90		Initial revision

DESCRIPTION:
	Rasterization routines for hinted Nimbus chars.

	$Id: nimbusSegments.asm,v 1.1 97/04/18 11:45:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Segments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Well we finally can start processing pieces of the character
CALLED BY:	MakeCharLow()

PASS:		es:di - ptr to first command
		ds - seg addr of NimbusVars
		ds:guano - bitmap header (NimbusBitmap)
RETURN:		none
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	JMPs to functions, which all JMP back to "NextCommand"
	This takes (18+15)=33 cycles vs. (29+16)=45 cycles. Whoopie.
	ASSUMES: size(NimbusCommand) = 1
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Segments	proc	near

NextCommand	label	near
	mov	dl, es:[di]			;dl <- command
	inc	di				;skip command
EC <	cmp	dl, NimbusCommands		;>
EC <	ja	DieHorribly			;>
	cmp	dl, NIMBUS_DONE			;end of character?
	je	EndCharData			;branch if end of data
	clr	dh
	shl	dx, 1
	mov	si, dx				;si <- command index
	jmp	cs:funcTable[si]		;call the right function

EndCharData	label	near
	ret
Segments	endp

DieHorribly	label	near
EC <	ERROR	BAD_NIMBUS_COMMAND	>
NEC <	jmp	NextCommand		>

funcTable	label	word
	word	offset	NimbusMoveTo		;=0
	word	offset	NimbusLineTo		;=1
	word	offset	NimbusBezierTo		;=2
	word	offset	DieHorribly		;=3 (DONE)
	word	offset	DieHorribly		;=4 (**unused**)
	word	offset	NimbusAccentChar	;=5
	word	offset	NimbusVertLineTo	;=6
	word	offset	NimbusHorizLineTo	;=7
	word	offset	NimbusRelLineTo		;=8
	word	offset	NimbusRelBezierTo	;=9



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the curent pen position.
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusMoveData
		ds - seg addr of NimbusVars
RETURN:		es:di - ptr beyond data
		(ax,bx) - new current position (untransformed)
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusMoveTo	proc	near
	mov	ax, es:[di].NMD_x		;ax <- x position
	mov	bx, es:[di].NMD_y		;bx <- y position
	push	ax, bx
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	ds:x0, ax
	mov	ds:y0, bx			;store new pen position
	pop	ax, bx
	add	di, size NimbusMoveData		;advance to next command
	jmp	NextCommand
NimbusMoveTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw line from CP to (x,y)
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusLineData
		ds - seg addr of NimbusVars
		(ax,bx) - current position (untransformed)
		ds - seg addr of NimbusVars
RETURN:		es:di - ptr beyond data
		(ax,bx) - new current position (untransformed)
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusLineTo	proc	near
	mov	ax, es:[di].NLD_x
	mov	bx, es:[di].NLD_y		;(ax,bx) <- end position
	add	di, size NimbusLineData
LineCommon	label	near
	push	ax, bx
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	cx, ds:x0
	mov	dx, ds:y0
	call	Pixelate			;rasterize((ax,bx),(cx,dx))
	mov	ds:x0, ax
	mov	ds:y0, bx			;store new pen position
	pop	ax, bx
	jmp	NextCommand
NimbusLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusVertLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw vertical line from CP to (x, +/-y)
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusVertData
		ds - seg addr of NimbusVars
		(ax,bx) - current position (untransformed)
		ds - seg addr of NimbusVars
RETURN:		es:di - ptr beyond data
		(ax,bx) - new current position (untransformed)
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusVertLineTo	proc	near
	add	bx, es:[di].NVD_length		;y += *ch++;
	add	di, size NimbusVertData
	jmp	LineCommon
NimbusVertLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusHorizLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw horizontal line from CP to (+/-x, y)
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusHorizData
		ds - seg addr of NimbusVars
		(ax,bx) - current position (untransformed)
		ds - seg addr of NimbusVars
RETURN:		es:di - ptr beyond data
		(ax,bx) - new current position (untransformed)
DESTROYED:	

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusHorizLineTo	proc	near
	add	ax, es:[di].NHD_length		;x += *ch++;
	add	di, NimbusHorizData
	jmp	LineCommon
NimbusHorizLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusRelLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw line from CP to (+/-x, +/-y)
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusRelLineData
		ds - seg addr of NimbusVars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr beyond data
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusRelLineTo	proc	near
	mov	cx, ax				;save x position
	mov	al, es:[di].NRLD_y
	cbw
	add	bx, ax				;add y offset
	mov	al, es:[di].NRLD_x
	cbw
	add	ax, cx				;(ax,bx) <- (x,y) position
	add	di, size NimbusRelLineData
	jmp	LineCommon
NimbusRelLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusBezierTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a Bezier curve from CP to (x3,y3) through (x1,y1),(x2,y2)
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusRelLineData
		ds - seg addr of NimbusVars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr beyond data
		(ax,bx) - new current position (untransformed)
DESTROYED:

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusBezierTo	proc	near
	mov	ax, es:[di].NBD_x1
	mov	bx, es:[di].NBD_y1
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	ds:x1, ax
	mov	ds:y1, bx
	mov	ax, es:[di].NBD_x2
	mov	bx, es:[di].NBD_y2
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	ds:x2, ax
	mov	ds:y2, bx
	mov	ax, es:[di].NBD_x3
	mov	bx, es:[di].NBD_y3
	push	ax, bx
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	ds:x3, ax
	mov	ds:y3, bx
	add	di, size NimbusBezierData
	REAL_FALL_THRU	BezierCommon		;clean up ESP warning
NimbusBezierTo	endp
BezierCommon	proc	near
	push	di
	push	ds:y3
	push	ds:x3
	push	ds:y2
	push	ds:x2
	push	ds:y1
	push	ds:x1
	push	ds:y0
	push	ds:x0				;vectorize(p0,p1,p2,p3)
	mov	bp, sp				;ss:bp <- ptr to params
	call	Vectorize			;rasterize curve
	add	sp, NimbusPoints - size	NimPoint
	pop	ds:x0
	pop	ds:y0				;set transformed CP
	pop	di
	pop	ax, bx				;(ax,bx) <- new CP
	jmp	NextCommand
BezierCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusRelBezierTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw Bezier from CP to CP+offsets
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusRelBezierData
		ds - seg addr of NimbusVars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr beyond data
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusRelBezierTo	proc	near
	mov	cx, ax				;save x
	mov	al, es:[di].NRBD_y1
	cbw
	add	bx, ax
	mov	al, es:[di].NRBD_x1
	cbw
	add	ax, cx
	push	ax, bx
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	ds:x1, ax
	mov	ds:y1, bx
	pop	cx, bx

	mov	al, es:[di].NRBD_y2
	cbw
	add	bx, ax
	mov	al, es:[di].NRBD_x2
	cbw
	add	ax, cx
	push	ax, bx
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	ds:x2, ax
	mov	ds:y2, bx
	pop	cx, bx

	mov	al, es:[di].NRBD_y3
	cbw
	add	bx, ax
	mov	al, es:[di].NRBD_x3
	cbw
	add	ax, cx
	push	ax, bx				;save new CP (untransformed)
	call	ds:GenData.CGD_trans_fn		;call transformation function
	mov	ds:x3, ax
	mov	ds:y3, bx

	add	di, NimbusRelBezierData
	jmp	BezierCommon
NimbusRelBezierTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NimbusAccentChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw base char, offset (x,y), draw accent char.
CALLED BY:	Segments()

PASS:		es:di - ptr to NimbusAccentData
		ds - seg addr of NimbusVars
		(ax,bx) - current position (untransformed)
RETURN:		none - see SIDE EFFECTS
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	No NimbusCommands (except NIMBUS_DONE) are supposed to
	follow a NIMBUS_ACCENT segment. This allows us to just
	stop processing, rather than make sure the original
	character data is still loaded and scan only to find
	the end of character marker. Also, rather than copy
	and shift the character data for the 2nd character, the
	offset is just added before every transform.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NimbusAccentChar	proc	near
	mov	si, es:[di].NAD_y		;si <- y offset for 2nd char
	push	es:[di].NAD_x			;save offset for 2nd char
	push	si
	push	{word}es:[di].NAD_char2		;save 2nd character

	mov	dl, es:[di].NAD_char1		;dl <- 1st character
	call	FindCharPtr			;es:di == ptr to NimbusData
	mov	bx, es:[di].ND_ymax		;bx <- top of base char
	call	MakeCharBase			;rasterize base character
	;
	;/* if we are using hints, and the bottom of the accent */
	;/* is above the top of the base, make sure the bottom */
	;/* of the accent is one full pixel above the base */
	;
	pop	dx				;dl <- 2nd character
	clr	ax
	mov	ds:xvars.NF_num, ax		;x_num = 0;
	mov	ds:yvars.NF_num, ax		;y_num = 0;
	call	FindCharPtr			;es:di == ptr to NimbusData
	push	cx				;save handle of outline data
	mov	dx, ds:GenData.CGD_y_scl	;dx <- y_scl
	tst	dx				;if (y_scl)
	jz	noYHints			;branch if no y hints
	mov	ax, bx				;y0 <- top of base char
	call	Scale
	call	RefLine				;y1 = refline(scale(y_scl,y0));
	mov	cx, ax				;cx <- y1
	add	si, es:[di].ND_ymin		;y2 = x2+ch[2] /* btm of acct */
	mov	ax, si				;ax <- y2
	call	Scale
	call	RefLine				;y3 = refline(scale(y_scl,y2));
	cmp	cx, ax				;if (y1 == y3)
	jne	noYHints			;branch if y1 != y3
	cmp	si, bx				;if (y2 > y0)
	jle	noYHints			;branch if y2 <= y0
	inc	ds:yvars.NF_num			;y_num = 1;
	mov	ds:yvars.NF_orus[0], si		;y_orus[0] = y2;
	mov	ax, cx
	inc	ax				;ax <- y1 + 1;
	tst	dx				;if (y_scl > 0)
	jns	afterHints
	sub	ax, 2				;ax <- y1 - 1;
afterHints:
	mov	ds:yvars.NF_pxls[0], ax		;y_pxls[0] = y1 + 1 : y1 - 1;
noYHints:
	;
	;/* move and render the accent */
	;
	pop	cx				;cx <- handle of outline data
	pop	ds:y_offset
	pop	ds:x_offset			;offset to draw at
	call	MakeCharLow			;rasterize accent character

	jmp	EndCharData
NimbusAccentChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Pixelate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan convert a vector (ie. a line)
CALLED BY:	NimbusLineTo()/LineCommon(), Vectorize()

PASS:		ds:guano - bitmap to use (NimbusBitmap)
		ds:x_count, ds:x_list[]
		ds:y_count, ds:y_list[] - arrays and counts of points
		(ax,bx),(cx,dx) - end points of line
RETURN:		none
DESTROYED:	cx, dx, si

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

Pixelate	proc	near
	uses	ax, bx, di, bp

	.enter
	;
	;/* maybe scan vertically for later hole filling */
	;
	tst	ds:GenData.CGD_check		;doing continuity checking?
	jz	noChecking			;branch if not...
	call	XPixelate
noChecking:
	;
	;/* scan horizontally, flip all bits to right of line segment */
	;
	call	YPixelate

	.leave
	ret
Pixelate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YPixelate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scan horizontally at half-integer y-coordinates.
CALLED BY:	Pixelate()

PASS:		ds:guano - bitmap to use (NimbusBitmap)
		ds:y_list[] - array of points
		ds:y_count - # of points
		(ax,bx),(cx,dx) - end points of line
RETURN:		ds:y_list[] - array of points
		ds:y_count - # of points, updated
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

vector	word	8,7,6,5,4,3,2,1,0,15,14,13,12,11,10,9

YPixelate	proc	near
	;
	;/* ignore horizontals */
	;
	cmp	bx, dx
	je	ignoreHorizontal
	.enter
	;
	;/* make segment point up */
	;
	jl	ordered
	xchg	ax, cx
	xchg	bx, dx
ordered:
	;
	; (ax,bx) = (x0,y0)
	; (cx,dx) = (x1,y1)
	; si = y   bp = t
	;
	;/* set y at first half integer */
	;
	mov	si, bx
	mov	bp, bx
	andnf	si, FRACTION			;si <- FRACTION(y0)
	shl	si, 1				;table of words...
	add	bp, cs:vector[si]		;y = y0 + vector[FRACTION(y0)];
	mov	si, bp				;si <- y
	TRUNC	bp				;t = TRUNC(y);
	;
	;/* compute the x's */
	;
xLoop:
	cmp	si, dx				;while (y<y1)
	jge	done
	push	ax, bx, cx, dx
	push	cx
	sub	cx, ax				;cx <- (x1-x0)
	mov	ax, dx
	sub	ax, si				;ax <- (y1-y)
	xchg	bx, dx
	sub	bx, dx				;bx <- (y1-y0)
	imul	cx				;dx:ax <- a*b
	idiv	bx				;dx:ax <- a*b/c
	pop	cx
	sub	cx, ax				;cx <- x1 - ...
	tst	ds:GenData.CGD_check		;if (check)
	jnz	savePoint			;branch if continuity checking
afterSave:
	ROUND	cx				;u = ROUND(x);
	call	ds:GenRouts.CGR_xor_func	;call routine to invert bits
	pop	ax, bx, cx, dx
	add	si, ONE				;y += ONE;
	inc	bp				;t += 1;
	jmp	xLoop

done:
ignoreHorizontal:
	.leave
	ret

savePoint:
	mov	di, ds:v_count			;di <- y_count
	cmp	di, MAX_COUNT*(size word)	;&& (y_count < MAX_COUNT)
	jae	afterSave			;branch if too many points
	mov	ds:v_list_x[di], cx		;y_list[y_count].b.lo = x+16384
	mov	ds:v_list_y[di], si		;y_list[y_count].b.hi = y;
	add	ds:v_count, (size word)		;y_count++;
	jmp	afterSave
YPixelate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Vectorize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recursively turn a bezier curve into a bunch of line
		segments and call the function <pixelate> on each of them.
CALLED BY:	Segments()

PASS:		ss:bp - ptr to NimbusPoints
		ds - seg addr of NimbusVars
RETURN:		none
DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
	Uses parametric midpoint subdivision suggested in:
	pp. 164-5, Course Notes #4, SIGGRAPH 1986

	if ((ABS(x1 - x0) + ABS(y1 - y0)) < TWO) &&
	    (ABS(x2 - x1) + ABS(y2 - y1)) < TWO) &&
	    (ABS(x3 - x2) + ABS(y3 - y2)) < TWO) {
		pixelate(x0,y0,x1,y1);
		pixelate(x1,y1,x2,y2);
		pixelate(x2,y2,x3,y3);
	} else {
	    sx1 = (x0 + x1) >> 1;
	    t = (x1 + x2) >> 1;
	    sx2 = (sx1 + t) >> 1;
	    tx2 = (x2 + x3) >> 1;
	    tx1 = (t + tx2) >> 1;
	    sx3 = (sx2 + tx1) >> 1;

	    sy1 = (y0 + y1) >> 1;
	    t = (y1 + y2) >> 1;
	    sy2 = (sy1 + t) >> 1;
	    ty2 = (y2 + y3) >> 1;
	    ty1 = (t + ty2) >> 1;
	    sy3 = (sy2 + ty1) >> 1;
	    vectorize(x0,y0,sx1,sy1,sx2,sy2,sx3,sy3);
	    vectorize(sx3,sy3,tx1,ty1,tx2,ty2,x3,y3);
	}

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

left	equ	ss:[bp][-(size NimbusPoints)-(size word)]
right	equ	ss:[bp][-(size NimbusPoints)*2-(size word)]
arg	equ	ss:[bp]

left_x0		equ	left.NP_p0.NP_x
left_y0		equ	left.NP_p0.NP_y
left_x1		equ	left.NP_p1.NP_x
left_y1		equ	left.NP_p1.NP_y
left_x2		equ	left.NP_p2.NP_x
left_y2		equ	left.NP_p2.NP_y
left_x3		equ	left.NP_p3.NP_x
left_y3		equ	left.NP_p3.NP_y

right_x0	equ	right.NP_p0.NP_x
right_y0	equ	right.NP_p0.NP_y
right_x1	equ	right.NP_p1.NP_x
right_y1	equ	right.NP_p1.NP_y
right_x2	equ	right.NP_p2.NP_x
right_y2	equ	right.NP_p2.NP_y
right_x3	equ	right.NP_p3.NP_x
right_y3	equ	right.NP_p3.NP_y

arg_x0		equ	arg.NP_p0.NP_x
arg_y0		equ	arg.NP_p0.NP_y
arg_x1		equ	arg.NP_p1.NP_x
arg_y1		equ	arg.NP_p1.NP_y
arg_x2		equ	arg.NP_p2.NP_x
arg_y2		equ	arg.NP_p2.NP_y
arg_x3		equ	arg.NP_p3.NP_x
arg_y3		equ	arg.NP_p3.NP_y

Vectorize	proc	near
	;
	;/* if bezier if really short, draw the control path */
	;
	;if ((ABS(x1 - x0) + ABS(y1 - y0) < TWO)
	;
	mov	ax, arg_x1
	sub	ax, arg_x0
	jns	x1_OK
	neg	ax
x1_OK:
	mov	bx, arg_y1
	sub	bx, arg_y0
	jns	y1_OK
	neg	bx
y1_OK:
	add	ax, bx
	cmp	ax, TWO
	jae	divideAgain
	;
	;&& (ABS(x2 - x1) + ABS(y2 - y1) < TWO)
	;
	mov	ax, arg_x2
	sub	ax, arg_x1
	jns	x2_OK
	neg	ax
x2_OK:
	mov	bx, arg_y2
	sub	bx, arg_y1
	jns	y2_OK
	neg	bx
y2_OK:
	add	ax, bx
	cmp	ax, TWO
	jae	divideAgain
	;
	;&& (ABS(x3 - x2) + ABS(y3 - y2) < TWO)
	;
	mov	ax, arg_x3
	sub	ax, arg_x2
	jns	x3_OK
	neg	ax
x3_OK:
	mov	bx, arg_y3
	sub	bx, arg_y2
	jns	y3_OK
	neg	bx
y3_OK:
	add	ax, bx
	cmp	ax, TWO
	jae	divideAgain
	;
	;/* draw the control path */
	;
	mov	ax, arg_x1
	mov	bx, arg_y1
	mov	cx, arg_x0
	mov	dx, arg_y0
	call	Pixelate			;pixelate(x0,y0,x1,y1);
	mov	cx, ax
	mov	dx, bx
	mov	ax, arg_x2
	mov	bx, arg_y2
	call	Pixelate			;pixelate(x1,y1,x2,y2);
	mov	cx, arg_x3
	mov	dx, arg_y3
	call	Pixelate			;pixelate(y2,y2,x3,y3);
	ret

	;
	;/* divide bezier at parametric midpoint using algorithm */
	;/* suggested in: pp 164-5, Course Notes #4, SIGGRAPH 1986 */
	;
divideAgain:
	sub	sp, (size NimbusPoints)*2	;allocate args for recursion
	;
	; x variables	(x0, sx1, sx2, sx3)
	; 		(sx3, tx1, tx2, x3)
	;
	mov	ax, arg_x0
	mov	left_x0, ax			;pass x0
	mov	bx, arg_x1
	add	ax, bx
	sar	ax, 1				;sx1 = (x0 + x1) >> 1;
	mov	left_x1, ax			;pass sx1
	add	bx, arg_x2
	sar	bx, 1				;t = (x1 + x2) >> 1;
	add	ax, bx
	sar	ax, 1				;sx2 = (sx1 + t) >> 1;
	mov	left_x2, ax			;pass sx2
	mov	cx, arg_x3
	mov	right_x3, cx			;pass x3
	add	cx, arg_x2
	sar	cx, 1				;tx2 = (x2 + x3) >> 1;
	mov	right_x2, cx			;pass tx2
	add	bx, cx
	sar	bx, 1				;tx1 = (t + tx2) >> 1;
	mov	right_x1, bx			;pass tx1
	add	ax, bx
	sar	ax, 1				;sx3 = (sx2 + tx1) >> 1;
	mov	left_x3, ax			;pass sx3
	mov	right_x0, ax			;pass sx3
	;
	; y variables	(y0, sy1, sy2, sy3)
	;		(sy3, ty1, ty2, y3)
	;
	mov	ax, arg_y0
	mov	left_y0, ax			;pass y0
	mov	bx, arg_y1
	add	ax, bx
	sar	ax, 1				;sy1 = (y0 + y1) >> 1;
	mov	left_y1, ax			;pass sy1
	add	bx, arg_y2
	sar	bx, 1				;t = (y1 + y2) >> 1;
	add	ax, bx
	sar	ax, 1				;sy2 = (sy1 + t) >> 1;
	mov	left_y2, ax			;pass sy2
	mov	cx, arg_y3
	mov	right_y3, cx			;pass y3
	add	cx, arg_y2
	sar	cx, 1				;ty2 = (y2 + y3) >> 1;
	mov	right_y2, cx			;pass ty2
	add	bx, cx
	sar	bx, 1				;ty1 = (t + ty2) >> 1;
	mov	right_y1, bx			;pass ty1
	add	ax, bx
	sar	ax, 1				;sy3 = (sy2 + ty1) >> 1;
	mov	left_y3, ax			;pass sy3
	mov	right_y0, ax			;pass sy3
	mov	bp, sp
	call	Vectorize			;vectorize(sx3,tx1,tx2,x3);
	add	sp, (size NimbusPoints)
	mov	bp, sp
	call	Vectorize			;vectorize(x0,sx1,sx2,sx3);
	add	sp, (size NimbusPoints)
	ret
Vectorize	endp
