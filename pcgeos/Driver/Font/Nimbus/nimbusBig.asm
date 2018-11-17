COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Nimbus/CharMod
FILE:		nimbusBig.asm

AUTHOR:		Gene Anderson, Mar 12, 1990

ROUTINES:
	Name			Description
	----			-----------
EXT	MakeBigChar		Generate a character with no hints.
INT	CalcAllocRegion		Calculate size, allocate space for region.
INT	NimbusMove		Move pen position to (x0,y0).
INT	NimbusLine		Line from pen position to (x0,y0).
INT	NimbusMove		Bezier from pen position to (x2,y2).
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	3/12/90		Initial revision

DESCRIPTION:
	Contains routines for generating chars > 500 lines.
		
	$Id: nimbusBig.asm,v 1.1 97/04/18 11:45:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeBigChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate a large character with no hints.
CALLED BY:	NimbusGenChar

PASS:		es:di - ptr to outline data (NimbusData)
		cx - handle of outline data
		ds - seg addr of NimbusVars
			ds:gstateSegment - seg addr of GState
			ds:infoSegment - seg addr of font info block
			ds:GenData - transform, offsets, etc.
			ds:guano - segment, bounds, etc (NimbusBitmap)
			ds:x_pts, ds:y_pts - space for 4 WWFixed points
RETURN:		
DESTROYED:	ax, bx, cx, dx, si, di, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MakeBigCharFar	proc	far
	call	MakeBigChar			;make a big character
	ret
MakeBigCharFar	endp

MakeBigChar	proc	near
	clr	ax
	mov	ds:x_offset, ax
	mov	ds:y_offset, ax			;init character offset
	call	CalcAllocRegion			;calc bounds, allocate region
MakeBigBaseChar	label	near
	clr	ax
	mov	ds:x_offset, ax
	mov	ds:y_offset, ax			;init character offset
MakeBigCharLow	label	near
	push	cx				;save handle of outline data
	add	di, size NimbusData		;skip bounds
	call	SkipTuples			;skip x tuples
	call	SkipTuples			;skip y tuples

NextBigCommand	label	near
	mov	cl, es:[di]			;cl <- command
	add	di, size NimbusCommands		;skip command
EC <	cmp	cl, NimbusCommands		;>
EC <	ja	BigDieHorribly			;>
	cmp	cl, NIMBUS_DONE			;see if end of character
	je	EndBigChar			;branch if end of character
	clr	ch
	shl	cx, 1				;*2 for index
	mov	si, cx				;si <- command index
	jmp	cs:commandTable[si]		;call correct routine
EndBigChar	label	near

	pop	bx				;bx <- handle of outline data
	call	MemUnlock			;unlock outline data
	ret
MakeBigChar	endp

BigDieHorribly	label	near
EC <	ERROR	BAD_NIMBUS_COMMAND		;>
NEC <	jmp	NextBigCommand			;>

commandTable	label	nptr.near
	word	offset	BigNimbusMoveTo		;=0 move(x1,y1)
	word	offset	BigNimbusLineTo		;=1 line(x1,y1)
	word	offset	BigNimbusBezierTo	;=2 bezier(x1,y1,x2,y2,x3,y3)
	word	offset	BigDieHorribly		;=3 done
	word	offset	BigDieHorribly		;=4 ** unused **
	word	offset	BigNimbusAccentChar	;=5
	word	offset	BigNimbusVertLineTo	;=6
	word	offset	BigNimbusHorizLineTo	;=7
	word	offset	BigNimbusRelLineTo	;=8
	word	offset	BigNimbusRelBezierTo	;=9


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusMoveTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set p0=pen to p1=(x1,y1)
CALLED BY:	MakeBigChar()

PASS:		es:di - ptr to (x,y) data point
		ds - seg addr of vars
RETURN:		es:di - ptr to next command
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusMoveTo	proc	near
	mov	si, offset NP_p0		;si <- store in p0
	mov	ax, es:[di].NMD_x
	mov	bx, es:[di].NMD_y		;(ax,bx) <- p0
	push	ax, bx
	call	TransFlipPoint			;(cx,dx) <- transformed point
	mov	ax, REGION_MOVE_PEN		;ax <- routine #
	call	CallBuildRegion
	add	di, size NimbusMoveData		;advance to next command
	pop	ax, bx				;(ax,bx) <- pen (untransformed)
	jmp	NextBigCommand
BigNimbusMoveTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a line from p0=pen to p1=(x,y)
CALLED BY:	MakeBigChar()

PASS:		es:di - ptr to (x,y) data point
		ds - seg addr of vars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr to next command
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusLineTo	proc	near
	mov	ax, es:[di].NLD_x
	mov	bx, es:[di].NLD_y		;(ax,bx) <- p1
	add	di, size NimbusLineData		;advance to next command
BigLineCommon	label	near
	mov	si, offset NP_p1		;si <- store in p1
	push	ax
	call	TransFlipPoint			;(cx,dx) <- transformed point
	mov	ax, REGION_ADD_LINE_CP		;ax <- routine #
	call	CallBuildRegion
	pop	ax				;(ax,bx) <- pen position
	jmp	NextBigCommand
BigNimbusLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusVertLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a line from p0=(x0,y0) to p1=(x0,y1)
CALLED BY:	MakeBigChar()

PASS:		es:di - ptr to NimbusVertData
		ds - seg addr of vars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr to next command
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusVertLineTo	proc	near
	add	bx, es:[di].NVD_length		;y1 = y0 +/- length
	add	di, size NimbusVertData
	jmp	BigLineCommon			;call common routine
BigNimbusVertLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusHorizLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a line from p0=(x0,y0) to p1=(x1,y0)
CALLED BY:	MakeBigChar()

PASS:		es:di - ptr to NimbusHorizData
		ds - seg addr of vars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr to next command
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusHorizLineTo	proc	near
	add	ax, es:[di].NHD_length		;x1 = x0 +/- length
	add	di, size NimbusHorizData
	jmp	BigLineCommon
BigNimbusHorizLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusRelLineTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a line from p0=(x0,y0) to p1=(x1,y1)
CALLED BY:	MakeBigChar()

PASS:		es:di - ptr to NimbusRelLineData
		ds - seg addr of vars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr to next command
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusRelLineTo	proc	near
	mov	cx, ax				;cx <- x0
	mov	al, es:[di].NRLD_y		;al <- y offset
	cbw					;sign extend to word
	add	bx, ax
	mov	al, es:[di].NRLD_x		;al <- x offset
	cbw					;sign extend to word
	add	ax, cx
	add	di, size NimbusRelLineData
	jmp	BigLineCommon
BigNimbusRelLineTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusBezierTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a bezier from p0=(x0,y0) to p3=(x3,y3) through p1,p2
CALLED BY:	MakeBigChar

PASS:		es:di - ptr to (x1,y1) data
		ds - seg addr of vars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr to next command
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusBezierTo	proc	near
	mov	si, offset NP_p1		;si <- store in p1-p3
	mov	ax, es:[di].NBD_x1
	mov	bx, es:[di].NBD_y1		;(ax,bx) <- p1
	call	TransFlipPoint
	mov	ax, es:[di].NBD_x2
	mov	bx, es:[di].NBD_y2		;(ax,bx) <- p2
	call	TransFlipPoint
	mov	ax, es:[di].NBD_x3
	mov	bx, es:[di].NBD_y3		;(ax,bx) <- p3
	call	TransFlipPoint
	add	di, size NimbusBezierData	;advance to next command

BigNimbusBezierCommon	label	near
	push	ax, di
	mov	di, offset points.NP_p1		;ds:di <- ptr to args
	mov	bp, ds
	mov	cx, offset stackBot		;bp:cx <- ptr to "stack"
	mov	ax, REGION_ADD_BEZIER_CP	;ax <- routine #
	call	CallBuildRegion			;BEZIER(pen,p1,p2,p3)
	pop	ax, di				;(ax,bx) <- pen position 
	jmp	NextBigCommand
BigNimbusBezierTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusRelBezierTo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a Bezier curve from CP to offsets
CALLED BY:	MakeBigChar()

PASS:		es:di - ptr to NimbusRelBezierData
		ds - seg addr of vars
		(ax,bx) - current position (untransformed)
RETURN:		es:di - ptr to next command
		(ax,bx) - new current position (untransformed)
DESTROYED:	cx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusRelBezierTo	proc	near
	mov	si, offset NP_p1		;si <- store in p1-p3

	mov	cx, ax				;save x
	mov	al, es:[di].NRBD_y1		;al <- 1st y offset
	cbw
	add	bx, ax
	mov	al, es:[di].NRBD_x1		;al <- 1st x offset
	cbw
	add	ax, cx
	call	TransFlipPoint

	mov	cx, ax				;save x
	mov	al, es:[di].NRBD_y2		;al <- 2nd y offset
	cbw
	add	bx, ax
	mov	al, es:[di].NRBD_x2		;al <- 2nd x offset
	cbw
	add	ax, cx
	call	TransFlipPoint

	mov	cx, ax				;save x
	mov	al, es:[di].NRBD_y3		;al <- 3rd y offset
	cbw
	add	bx, ax
	mov	al, es:[di].NRBD_x3		;al <- 3rd x offset
	cbw
	add	ax, cx
	call	TransFlipPoint

	add	di, size NimbusRelBezierData
	jmp	BigNimbusBezierCommon
BigNimbusRelBezierTo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BigNimbusAccentChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add base character, add accent char offset (x,y)
CALLED BY:	MakeBigChar()

PASS:		es:di - ptr to NimbusRelBezierData
		ds - seg addr of vars
		(ax,bx) - current position (untransformed)
RETURN:		none -- see SIDE EFFECTS
DESTROYED:	ax, bx, cx, dx, si, bp, es

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
	eca	6/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BigNimbusAccentChar	proc	near
	mov	dl, es:[di].NAD_char1		;dl <- 1st character
	push	es:[di].NAD_x
	push	es:[di].NAD_y			;save (x,y) offset
	push	{word}es:[di].NAD_char2		;save 2nd char
	call	FindCharPtr			;get ptr to 1st char data
	call	MakeBigBaseChar
	pop	dx				;dl <- 2nd character
	pop	ds:y_offset
	pop	ds:x_offset
	call	FindCharPtr			;get ptr to 2nd char data
	call	MakeBigCharLow
	jmp	EndBigChar			;don't return
BigNimbusAccentChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallBuildRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call GrRegionPath routines, passing and setting the
		region segment.
CALLED BY:	NimbusMove, NimbusLine, NimbusBezier, SetPointInRegion,
		CopyRegionResize

PASS:		ax - routine #
		ds - seg addr of vars
		rest - depends on routine
RETURN:		none
DESTROYED:	ax, depends on routine

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

regionPathRoutines fptr.far	GrRegionPathClean, \
				GrRegionPathMovePen, \
				GrRegionPathAddLineAtCP, \
				GrRegionPathAddBezierAtCP, \
				GrRegionPathAddOnOffPoint

CallBuildRegion	proc	near
	uses	bx, es
	.enter

	mov	es, ds:guano.NB_segment
	mov_tr	bx, ax				; trash AX, offset => BX
	mov	ax, cs:[regionPathRoutines][bx].offset
	mov	bx, cs:[regionPathRoutines][bx].segment
	call	ProcCallFixedOrMovable
	mov	ds:guano.NB_segment, es

	.leave
	ret
CallBuildRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransformPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform a point.
CALLED BY:	NimbusMove, NimbusLine, NimbusBezier

PASS:		(ax,bx) - coordinate to transform
		ds:GenData.CGD_matrix - transformation matrix
		ds:x_offset,  ds:y_offset - (x,y) offset (for accent chars)
RETURN: 	(cx,dx) - transformed point
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
	x' = x*tm11 + y*tm21
	y' = x*tm12 + y*tm22
	Because the Nimbus numbers have an implied fraction
	of 32768 instead of 65536, a multiply by 2 is done.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransformPoint	proc	near
	uses	ax, bx, es, di
	.enter

	segmov	es, ss, cx

	add	ax, ds:x_offset			;add offset for accent char
	add	bx, ds:y_offset

	clr	cx
	push	bx
	push	cx
	push	ax
	push	cx
	mov	bp, sp				;bp <- offset of y coord

	mov	di, offset GenData.CGD_matrix.FM_11
	call	TransOneCoord
	push	ax

	mov	di, offset GenData.CGD_matrix.FM_12
	call	TransOneCoord
	mov	dx, ax
	pop	cx				;(cx,dx) <- point

	add	sp, (size WWFixed)*2		;clean stack

	.leave
	ret
TransformPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransFlipPoint, TransStorePoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform a point (and flip it) and store it.
CALLED BY:	NimbusMove, NimbusLine, NimbusBezier

PASS:		(ax,bx) - coordinate to transform
		ds:GenData.CGD_matrix - transformation matrix
		ds:x_offset,  ds:y_offset - (x,y) offset (for accent chars)
		si - offset of destination in (x_pts,y_pts)
RETURN:		si - next destination
		(cx,dx) - transformed point
DESTROYED:	bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransFlipPoint	proc	near
	call	TransformPoint			;(cx,dx) <- point
	sub	cx, ds:guano.NB_lox		;x' = x - left(x);
	mov	bp, ds:guano.NB_hiy		;bx <- top(y)
	sub	bp, dx				;y' = top(y) - y;
	mov	dx, bp				;(cx,dx) <- adjusted point
StorePoint	label	near
	mov	ds:points.NP_p0[si].NP_x, cx
	mov	ds:points.NP_p0[si].NP_y, dx
	add	si, (size word)*2		;si <- advance to next point
	ret
TransFlipPoint	endp

TransStorePoint proc	near
	call	TransformPoint
	jmp	StorePoint
TransStorePoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TransOneCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Transform one coordinate (x or y).
CALLED BY:	TransformPoint

PASS:		ds:di - ptr to top of column (FM_11 or FM_12)
		es:bp - ptr to x coord, y coord (WWFixed)
RETURN:		ax - result (sword)
DESTROYED:	bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TransOneCoord	proc	near
	uses	si
	.enter

	mov	si, di				;ds:si <- ptr to 1st row
	mov	di, bp				;es:di <- ptr to x coord
	call	GrMulWWFixedPtr
	mov	bx, cx
	mov	ax, dx				;ax.bx <- x*tm1{1,2}

	add	si, offset FM_22 - offset FM_12	;ds:si <- ptr to 2nd row
	add	di, size WWFixed		;es:di <- ptr to y coord
	call	GrMulWWFixedPtr
	addwwf	axbx, dxcx			;ax.bx <- x*tm1{1,2}+y*tm2{1,2}
	shlwwf	axbx				;ax.bx <- *2
	rndwwf	axbx				;ax <- rounded value (word)

	.leave
	ret
TransOneCoord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcAllocRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the size of the char and allocate a region for it
CALLED BY:	MakeBigChar

PASS:		es:di - ptr to outline data (NimbusData)
		ds - seg addr of vars
RETURN:		ds:guano - bounds, segment of region
DESTROYED:	ax, bx, dx, si, bp

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcAllocRegion	proc	near
	uses	cx
	.enter

	mov	si, offset NP_p0		;ds:si <- ptr to points
	mov	ax, es:[di].ND_xmin
	mov	bx, es:[di].ND_ymin		;(ax,bx) <- lower left
	call	TransStorePoint
	mov	ax, es:[di].ND_xmin
	mov	bx, es:[di].ND_ymax		;(ax,bx) <- upper left
	call	TransStorePoint
	mov	ax, es:[di].ND_xmax
	mov	bx, es:[di].ND_ymax		;(ax,bx) <- upper right
	call	TransStorePoint
	mov	ax, es:[di].ND_xmax
	mov	bx, es:[di].ND_ymin		;(ax,bx) <- lower right
	call	TransStorePoint

	mov	si, offset points.NP_p0.NP_y
	call	FindMinMax
	push	bp				;save min y
	push	dx				;save max y
	mov	si, offset points.NP_p0.NP_x
	call	FindMinMax
	mov	ax, bp				;ax <- min x
	mov	cx, dx				;cx <- max x
	pop	dx				;bx <- max y
	pop	bx				;dx <- min y
	call	AllocBMap			;allocate region

	.leave
	ret
CalcAllocRegion	endp

FindMinMax	proc	near
	mov	bp, 0x7fff
	mov	dx, -0x7fff
	mov	cx, 4				;cx <- # of entries
FMM_loop:
	mov	ax, ds:[si]			;ax <- coordinate
	cmp	ax, bp
	jg	notMin
	mov	bp, ax				;bp <- new minimum
notMin:
	cmp	ax, dx
	jl	notMax
	mov	dx, ax				;dx <- new maximum
notMax:
	add	si, size NimPoint		;advance to next entry
	loop	FMM_loop
	ret
FindMinMax	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CharInRegionAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fake an allocation of a region to generate a character in.
		This routine is essentially a substitution for RegionAlloc().
CALLED BY:	allocBMap()

PASS:		ds	- segment address of NimbusVars
		ax, dx	- height of character
		es	- segment address of udata
RETURN:		es:bitmapHandle		- handle of region
		ds:guano.NB_segment	- segment of RegionPath
DESTROYED:	ax, bx, cx, dx, di, es (may destroy these)

PSEUDO CODE/STRATEGY:
		We need to muck with the NB_lox & NB_hiy values so that
		the characters will end up being in the correct place in
		the region, rather than the upper-left hand corner.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CharInRegionAlloc	proc	near
	;
	; Current, the following transformation takes place for each point
	; add to the region:
	;	x' = x - left(x)
	;	y' = top(y) - y
	; We need to adjust left(x) & top(y) so that the characters will be
	; written to the correct location in the region.
	;
	mov	ax, ds:penPos.P_x
	add	ax, ds:GenData.CGD_heightX
	neg	ax				;this will later be subtracted,
	mov	ds:guano.NB_lox, ax		;...so we'd better negate now

	mov	ax, ds:penPos.P_y
	add	ax, ds:GenData.CGD_heightY	;ax <- scaled baseline for font
	mov	ds:guano.NB_hiy, ax
	ret
CharInRegionAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECNullNimbusRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An error-checking stub that should never be called. Used by
		NimbusGenCharInRegion().

CALLED BY:	INTERNAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
ECNullNimbusRoutine	proc	near
	ERROR	NIMBUS_GEN_CHAR_IN_REGION_SHOULD_NEVER_BE_CALLED
ECNullNimbusRoutine	endp
endif

