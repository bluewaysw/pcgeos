COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Kernel/Graphics/RegionPaths
FILE:		graphicsRegionPath.asm

AUTHOR:		Gene Anderson, Apr  1, 1990

ROUTINES:
	Name				Description
	----				-----------
EXT	GrRegionPathInit		Allocate/initialize a region for paths.
EXT	GrRegionPathClean		Remove duplicate lines from a region.
EXT	GrRegionPathMovePen		Move current pen position in region.
EXT	GrRegionPathAddOnOffPoint	Add a point to the given region.
EXT	GrRegionPathAddLineAtCP		Add a line to the given region.
EXT	GrRegionPathAddBezierAtCP	Add a Bezier curve to the given region.
EXT	GrRegionPathAddPolygon		Add a polygon to the given region
EXT	GrRegionPathAddPolyline		Add a polyline to the given region

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/ 1/90		Initial revision
	Don	7/24/91		Broke out routines to be globally accessible

DESCRIPTION:
	Contains routines for generating regions based on a path
	described by lines, Bezier curves, and polygons. They are
	used by the font driver for generating large characters,
	the Window system for generating transformed clipping regions,
	and by the rotated ellipse code for generating filled ellipses.

SAMPLE USAGE:
	;
	; Initialize the region, and move the pen to the starting point.
	;
	reg = RegionInit(min_y, max_y);
	RegionMovePen(reg,0,0);
	;
	; Add lines, curves, polygons, etc.
	;
	RegionAddLineAtCP(reg,x1,y1);
	...
	RegionAddBezierAtCP(reg,x5,y5,x6,y6,x7,y7);
	;
	; IMPORTANT: Remove duplicate lines from region.
	;
	size = RegionClean(reg);
	;
	; Do whatever we want with the region...
	;
	GrDrawRegion(reg);
	;
	; IMPORTANT: Free the block the region is stored in.
	;
	MemFree(reg);

	$Id: graphicsRegionPath.asm,v 1.1 97/04/05 01:12:39 newdeal Exp $


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Regions and Paths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ABOUT THE ROUTINES:
	The routines in this file are designed for generating arbitrary
regions from points, lines, Bezier curves and polygons. They were originally
written for use by the Nimbus font driver for generating large characters.
(The PC/GEOS graphics system stores characters larger than 128 lines high
as regions instead of bitmaps, as they are more compact and frequently
quicker to draw.). As such, they are designed around usage by the font
driver. The routines REGION_INIT and REGION_ADD_ON_OFF_POINT are used
by the Nimbus driver for generating regions from the hinted character
definition. Instead of setting points in a bitmap, they are set in a
region. The routines REGION_MOVE_PEN, REGION_ADD_LINE_CP, and
REGION_ADD_BEZIER correspond directly to the character definition
commands and are used for generating unhinted (ie. large) characters.

ABOUT CHARACTERS:
	The Nimbus routines create bitmaps through clever use of the
winding fill rule. Points on the outside of characters run counter-
clockwise, and points on the inside of characters run clockwise. This
allows the code to correctly set points in the bitmap by setting the
starting point and inverting all points to the end of the line. This works
because the points on a line always come in pairs. Points lying outside
the character body get inverted an even number of times. Points lying
inside get inverted an odd number of times, ending with them turned on,
the correct state. However, since the character components do not cross
themselves, the simpler even/odd rule can be used.

ABOUT REGIONS:
	After some simple research, the average number of on/off points
in a character was determined to be ~3.4. (for unrotated characters --
for rotated characters, the number will generally be higher).
As a result of this research, I decided on 4 as a good number.
	To keep from resizing too frequently, the region is
initialized such that each line has some unused points
allocated on it. These are marked with UNUSED_POINT. This means the
initial region will something like:
	word	left, top, right, bottom	;bounding rectangle
	word	line#1, UNUSED, ..., UNUSED, EOREGREC
	word	line#2, UNUSED, ..., UNUSED, EOREGREC
	...
	word	line#n, UNUSED, ..., UNUSED, EOREGREC
	word	EOREGREC			;end-of-region

	The unused points will be replaced with points as they
are set on each line. If we get to the unpleasant state of no more
unused points on a line, resizing the region block may become
necessary. We check for any remaining bytes at the end of the
block, and use them first. Only if the block is full do we do the
actual (potentially unpleasant) resizing.
	After the character is entirely generated, the region will be
scanned for adjacent duplicate lines and any remaining unused points,
as the concept of unused points is nonstandard (ie. the rest of the
graphics system will barf or do weird things with these values in).

ABOUT PATHS:
	 These routines could be used (with appropriate clipping in the
rasterization routines) to generate a smaller section of the region to
avoid hitting the 64K boundary. This will be necessary when paths are
fully implemented in release 2 as arbitrary paths can include any
component from the graphics system (eg. points, lines, text, etc.) and
could grow large very quickly. The easiest way to do this would be to
add a check in SetPointInRegion() to do nothing if the point is out of
bounds. Checks could also be added to trivial reject lines and curves
if they are out of bounds. (note: with Bezier curves, the easiest/safest
way may be to use the bounding rectangle of the control points and see
if that is in the region being generated)
	Note, however, because the components are added arbitrarily,
these routines only do the even/odd fill rule. (The Nimbus routines rely
on this rule being used or a full blown non-zero winding rule being
implemented.) If we are going to be compatible with PostScript (and
make the graphics system more versatile), then it will be necessary to
modify these routines to implement the non-zero winding rule as well.
	Also, these routines currently don't deal with adding new
lines to the region definition because the bounds are known ahead of
time. It may be necessary to add this functionality.
See FindRegionLine() in KLib/Graphics/graphicsRegionRaster.asm.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsRegionPaths segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate and initialize a region for use by the path
		routines during rasterization.
CALLED BY:	GLOBAL

PASS:		di - 0 for new block, handle to realloc old block
		ch - initial # of on/off points per line (>= MIN_REGION_POINTS)
		cl - RegionFillRule
		bp - minimum y
		dx - maximum y
RETURN:		es - seg addr of region block
		cx - size of block (in bytes)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
		This routine initializes the lines in the region to
	have the passed number of on/off points per line.
		This routine also initializes optimizations like the
	current line and current line pointer, as well as a variety of
	other information.
		See the beginning of this file for more details.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/90		Initial version
	don	7/24/91		Changed name & made globally accessible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrRegionPathInit	proc	far
	uses	ax, bx, dx, di, si, ds, bp
	.enter

	; Some error checking
	;
EC <	cmp	ch, MIN_REGION_POINTS					>
EC <	ERROR_B	GRAPHICS_REGION_NOT_ENOUGH_POINTS			>
EC <	cmp	cl, RegionFillRule					>
EC <	ERROR_A	GRAPHICS_REGION_ILLEGAL_REGION_FILL_RULE		>
CheckHack <RFR_ODD_EVEN	eq 0>
CheckHack <RFR_WINDING	eq 1>

	; Set up for allocation our Region block
	;
	mov	al, ch				;al <- # on/off points
	clr	ah
	shl	ax, cl				;if RFR_WINDING, need 2*points
	push	ax				;save # on/off points
	shl	ax, 1				;ax <- size of points / line
	add	ax, REGION_LINE_SIZE		;add space for line #, EOLN
	dec	bp				;for region start...
	add	dx, 2				;for safety...
	push	dx				;save maximum y
	sub	dx, bp				;dx <- # of lines
	push	dx				;save # of scan lines
	mul	dx				;ax <- size of region block
EC <	ERROR_C	GRAPHICS_REGION_TOO_BIG		;			>
	add	ax, size RegionPath + 2		;add space for header, EOR mark
	push	ax				;save block size
	push	cx				;save RegionFillRule

	; Either allocate or re-allocate
	;
	tst	di				;see if alloc or realloc
	jnz	doRealloc			;branch if realloc

	mov	cx, mask HF_SWAPABLE \
		 or mask HF_SHARABLE \
		 or (mask HAF_LOCK shl 8) \
		 or (mask HAF_NO_ERR shl 8) 	;cl, ch <- alloc flags
	call	MemAllocFar
	jmp	afterAlloc
doRealloc:
	mov	bx, di				;bx <- handle of block
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
	call	MemReAlloc

	; Now initialize the RegionPath
	;
afterAlloc:
	mov	ds, ax				;ds <- RegionPath segment
	mov	es, ax				;es <- RegionPath segment
	pop	cx				;restore RegionFillRule
	mov	ds:RP_handle, bx		;store handle
	pop	ds:RP_size			;store size (in bytes)
	mov	ds:RP_curLine, bp		;init current line
	mov	ds:RP_y_min, bp			;store minimum y
	mov	ds:RP_fillRule, cl		;store the RegionFillRule
	mov	di, offset RP_bounds
	mov	ax, 0x7fff
	stosw					;left
	stosw					;top
	mov	ax, 0x8000
	stosw					;right
	stosw					;bottom
	mov	ds:[RP_lastSet].P_x, ax		; init these to something wierd
	mov	ds:[RP_lastSet].P_y, ax		;  so they won't match 1st off
	mov	ds:[RP_flags], al		;clear all flags
	pop	cx				;cx <- # of scan lines
	pop	ds:RP_y_max			;store maximum y
	mov	bx, bp				;bx <- initial line
	mov	ds:RP_curPtr, di		;init current line ptr
	pop	dx				;dx <- # of points / line
	mov	si, dx
lineLoop:
	mov	ax, bx				;ax <- line #
	stosw					;store line #
	mov	ax, UNUSED_POINT
	xchg	cx, dx				;cx <- # of points / line
	rep	stosw				;mark unused points
	mov	cx, dx				;cx <- # of scan lines
	mov	dx, si				;dx <- # of points / line
	mov	ax, EOREGREC			;mark end of line
	stosw
	inc	bx				;next line #
	loop	lineLoop
	stosw					;mark end of region
	mov	ds:RP_endPtr, di		;store end of region ptr
	mov	cx, ds:RP_size			;cx <- size (in bytes)
EC <	sub	di, 2				;di beyond last write	>
EC <	cmp	di, cx				;			>
EC <	ERROR_A	GRAPHICS_REGION_OVERDOSE	;gone too far		>

	.leave
	ret
GrRegionPathInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathClean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check a region for duplicate lines and unused entries.
CALLED BY:	GLOBAL

PASS:		es - seg addr of RegionPath
RETURN:		cx - size of region (in bytes)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Register Usage:
		dx = offset of current dest
		bx = offset of previous dest
		ds:si = source (always >= dest)
		es:di = dest
		bp = right flag (non-zero if right point)
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The block is *NOT* resized to the region size.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 1/90		Initial version
	don	7/24/91		Changed name & made globally accessible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrRegionPathClean	proc	far
	uses	ax, bx, dx, di, si, bp, ds
	.enter

	segmov	ds, es, ax
	;
	; See if the bounds make sense. If they don't, we haven't
	; actually set any points in the region, and so it is
	; empty. Deal with this specially, as to keep the rest of
	; the graphics system from spewing vomit...
	;
	mov	ax, ds:RP_bounds.R_left
	cmp	ax, ds:RP_bounds.R_right
	jg	nullRegion
	mov	ax, ds:RP_bounds.R_top
	cmp	ax, ds:RP_bounds.R_bottom
	jg	nullRegion

	mov	di, size RegionPath		;skip reigon/path header
	mov	si, di				;ds:si <- ptr to source
	mov	dx, di				;dx <- current line ptr
	clr	bx				;no previous line
lineLoop:
	cmp	ds:[si], EOREGREC		;see if end of region
EC <	call	ECCheckOffset			;check within block>
	movsw					;copy line number
	LONG je	endRegion			;branch if end of region
	clr	cx				;initialize counter for winding
	clr	bp				;first point is a left point
	push	di				;save start of line
	tst	ds:[RP_fillRule]		;winding rule ??
	jnz	windingLoop			;yes, so deal with that
	;
	; Scan the next line, removing any unused points.
	;
cleanLoop:
	lodsw
	cmp	ax, UNUSED_POINT		;see if unused point
	je	cleanLoop			;if so, ignore it
EC <	call	ECCheckOffset			;check within block>
	inc	cx				;increment word-in-line count
	cmp	ax, EOREGREC			;see if end of line
	jz	endOfLine
	tst	bp
	jz	notRightPoint
	dec	ax
notRightPoint:
	xor	bp, 1
	stosw
	jmp	cleanLoop
	;
	; See if the line we just copied is the same as the
	; previous line. If so, we can combine the two. CX holds
	; the number of words (including the EOREGREC) in the last line
	;
endOfLine:
	stosw
	pop	cx				;start of line => CX
	sub	cx, di				;subtract end of line
	neg	cx
	shr	cx, 1				;# of words in line => CX
	test	cx, 1				;if even # of words, then
	jz	badLine				;...we'd better fix this line
compareLines:
	push	si, di
	mov	si, bx
	add	si, 2				;ds:si <- previous line data
	mov	di, dx
	add	di, 2				;es:di <- current line data
	repe	cmpsw				;compare lines
	pop	si, di
	je	same
	mov	bx, dx				;bx <- new previous line
	mov	dx, di				;dx <- new current line
	jmp	lineLoop
	;
	; If we have an even number of words on a line, then we need to
	; ignore the last ON point. This situation could arise either
	; if the caller is stupid and doesn't know how to build a region, 
	; or if we run out of memory (the more likely case).
	;
	; Note: words on a line are:
	;	<line #>, <on #1>, <off #1>, ..., <EOREGREC>
	;
badLine:
	sub	di, 2				;ignore last ON point
	mov	es:[di-2], ax			;store the EOREGREC
	jmp	compareLines			;now compare the lines
	;
	; The region is NULL. Here we make the region a properly NULL region,
	; including making the bounds something interesting...
	; PASS: ds = es = seg addr of RegionPath
	; RETURN: di = size of RegionPath and data
	;
nullRegion:
	mov	ax, EOREGREC
	mov	cx, (size Rectangle)/2 + 2
	mov	di, offset RP_bounds
	rep	stosw
	jmp	doneWithRegion
	;
	; Deal with winding rule
	;     CX = cumulative up/down count (up = +1, down = -1)
	;     BP = left/right flag (0 = looking for left, 1 = looking for right)
	;
windingCleanLoop:
	xchg	cx, ax				;up/down count => CX, trash AX
windingNextLoop:
	add	si, 2				;go past up/down word
windingLoop:
	lodsw
	cmp	ax, UNUSED_POINT		;see if unused point
	je	windingNextLoop			;if so, ignore it
EC <	call	ECCheckOffset			;check within block>
	cmp	ax, EOREGREC			;see if end of line
	je	endOfLine			;if so, we're outta here
	tst	bp				;if looking for right
	jz	notRightPoint2
	dec	ax				;...decrement right side
notRightPoint2:
	xor	bp, 1				;swap side we're looking for
	stosw					;store the point
	mov	ax, ds:[si]			;up/down count => AX
	add	ax, cx				;running total => AX
	tst	<{word} ds:[si]>
	jz	ignorePoint			;if count = 0, then ignore point
	jcxz	windingCleanLoop		;if change from 0, keep point
	tst	ax		
	jz	windingCleanLoop		;or if change to 0, keep point
ignorePoint:
	xor	bp, 1				;undo change - point skipped
	sub	di, 2				;speed is important, so use sub
	jmp	windingCleanLoop		;remove point, and loop again
	;
	; We found two lines with the same on/off points
	;
same:
	inc	{word}ds:[bx]			;increment line number
	mov	di, dx				;back up dest if same
	jmp	lineLoop

endRegion:
	;
	; We are at the end of the region, but more likely than not there is
	; an empty band in the region -- nuke it
	;
	;	last band is empty  -> di points at D:  $ <lastY> $ $ D
	;	last band not empty -> di points at D:  $ <lastY> X1 Y1 $ $ D
	;
	cmp	ds:[di-8], EOREGREC
	jnz	doneWithRegion
	;
	; transform:
	;	di points at D:  $ <lastY> $ $ D
	; to:
	;	di points at D:  $ $ D

	sub	di, 4
	mov	{word} ds:[di-2], EOREGREC

doneWithRegion:
	mov	cx, di				;ax <- size of region
	mov	ds:RP_endPtr, di		;store size of region
	;
	; Check to make sure we have a line at the start of the
	; form: "<y1-1>: EOREGREC" to signify there is nothing before
	; the region.
	;
	cmp	ds:RP_eor, EOREGREC		;empty line at start?
	jne	noEmptyLine			;branch if no empty line
done:
	.leave
	ret

	;
	; The region has no empty line at the start. Add one or die...
	; PASS: dx = es = seg addr of RegionPath
	; 	cx = size of RegionPath and data
	; RETURN: cx = updated
noEmptyLine:
	mov	ax, (size RP_data + size RP_eor) ;ax <- add space for blank line
	add	cx, ax				 ;cx <- new size
	push	cx
	mov	di, offset RP_data		;es:di <- ptr to insertion point
	call	RegionAddSpace			;add space for blank line
	mov	ax, ds:RP_y_min
	dec	ax				;ax <- y1-1
	mov	ds:RP_data, ax			;<- store y1-1
	mov	ds:RP_eor, EOREGREC		;<- store EOR
	pop	cx
	jmp	done

GrRegionPathClean	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathMovePen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set current pen position in region/path.
CALLED BY:	GLOBAL

PASS:		(cx,dx) - position to set pen to (Point)
		es - seg addr of RegionPath
RETURN:		es - seg addr of RegionPath
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/90		Initial version
	don	7/24/91		Changed name & made globally accessible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrRegionPathMovePen	proc	far
	.enter

	mov	es:RP_pen.P_x, cx
	mov	es:RP_pen.P_y, dx

	.leave
	ret
GrRegionPathMovePen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathAddOnOffPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an on/off point to a region/path.
CALLED BY:	GLOBAL

PASS:		(cx,dx) - point to add (Point)
		es - seg addr of RegionPath
RETURN:		es - (new) seg addr of RegionPath
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The region pen position is *NOT* updated.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/90		Initial version
	don	7/24/91		Changed name & made globally accessible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrRegionPathAddOnOffPoint	proc	far
	uses	cx, dx
	.enter

	mov	bx, RPD_DOWN			;points are always down ?!
	call	SetPointInRegion		;add point into region

	.leave
	ret
GrRegionPathAddOnOffPoint	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathAddLineAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a line segment to a region/path.
CALLED BY:	GLOBAL

PASS:		(cx,dx) - end point of line (Point)
		es - seg addr of RegionPath
RETURN:		es - (new) seg addr of RegionPath
DESTROYED:	done

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/90		Initial version
	don	7/24/91		Changed name & made globally accessible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GrRegionPathAddLineAtCP	proc	far
	uses	ax, bx, cx, dx, bp
	.enter

	mov	ax, es:RP_pen.P_x
	mov	bx, es:RP_pen.P_y		;(ax,bx) <- endpoint 0
	call	RasterLine			;scan convert line into region

	.leave
	GOTO	GrRegionPathMovePen			;set pen to p1
GrRegionPathAddLineAtCP	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathAddBezierAtCP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a Bezier curve to a region/path.
CALLED BY:	GLOBAL

PASS:		ds:di - ptr to Bezier points (RegionBezier)
			(RB_p0 is set to pen position)
		if (bp != 0) {
		     bp:cx - ptr to top of stack
		} else {
		     cx - maximum stack depth / maximum accuracy
		}
		es - seg addr of RegionPath
RETURN:		es - (new) seg addr of RegionPath
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: IntRegionPoint == WBFixed[2];
	ASSUMES: size(WBFixed) == 3;

	The "stack" passed is used for rasterizing the Bezier curves.
	The routine uses parametric midpoint subdivision until the
	curve is short enough or straight enough to be considered a
	line. More precision requires a larger stack. The Nimbus driver
	uses a 5K stack, of which 2.5K is actually used. (This is when
	generating a 1024 point Roman character at 300dpi, or the
	equivalent of more than a 4200 point Roman character at 72dpi)
	REC_BEZIER_STACK is a recommended stack size (not in bytes) to
	pass in cx if a stack is to be allocated.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/90		Initial version
	don	7/24/91		Changed name & made globally accessible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrRegionPathAddBezierAtCP	proc	far
		mov	ss:[TPD_callVector].segment, size RegionBezier
		mov	ss:[TPD_dataBX], handle GrRegionPathAddBezierAtCPReal
		mov	ss:[TPD_dataAX], offset GrRegionPathAddBezierAtCPReal
		GOTO	SysCallMovableXIPWithDSDIBlock
GrRegionPathAddBezierAtCP	endp
CopyStackCodeXIP	ends

else

GrRegionPathAddBezierAtCP	proc	far
		FALL_THRU GrRegionPathAddBezierAtCPReal
GrRegionPathAddBezierAtCP	endp

endif

GrRegionPathAddBezierAtCPReal	proc	far
	uses	ax, bx, cx, dx, bp, ds, di, si
	.enter

	mov	si, di				;ds:si <- ptr to RegionBezier
	push	ds:[si].RB_p3.P_x
	push	ds:[si].RB_p3.P_y		;save last point

	tst	bp				;see if stack passed
	jnz	stackPassed			;branch if stack passed
	mov	ax, size IntRegionBezier
	mul	cx				;ax == size of stack block
	push	ax				;save stack ptr
	mov	cx, mask HF_DISCARDABLE or \
		   (mask HAF_LOCK shl 8) or \
		   (mask HAF_NO_ERR shl 8)	;cl,ch <- HeapAllocFlags
EC <	ERROR_C	GRAPHICS_REGION_TOO_BIG			;>
	call	MemAllocFar
	mov	bp, ax				;bp <- stack seg addr
	pop	di				;di <- stack ptr
	push	bx				;save handle
	jmp	afterStack

stackPassed:
	mov	di, cx				;bp:di <- ptr to stack
	clr	ax				;ax <- flag: stack passed
	push	ax				;save no handle
afterStack:
	;
	; Pass the initial points, p1-p3:
	;
	push	es
	mov	es, bp
	sub	di, size IntRegionBezier	;es:di <- ptr to 1st params
	push	di
	add	di, offset IRB_p1		;es:di <- ptr to p1
	mov	cx, (size IntRegionBezier) / (size IntRegionPoint) - 1
	clr	al				;al <- fractional position
argLoop:
	stosb					;store x fraction (=0)
	movsw					;copy x position
	stosb					;store y fracion (=0)
	movsw					;copy y position
	loop	argLoop				;loop while more args
	pop	es, si
	;
	; Set the initial point, p0, to the pen position:
	;
	mov	ds, bp				;ds:si <- stack ptr
	mov	ds:[si].IRB_p0.IRP_x.WBF_frac, al
	mov	ds:[si].IRB_p0.IRP_y.WBF_frac, al
	mov	ax, es:RP_pen.P_x
	mov	ds:[si].IRB_p0.IRP_x.WBF_int, ax
	mov	ax, es:RP_pen.P_y
	mov	ds:[si].IRB_p0.IRP_y.WBF_int, ax


	mov	bp, offset  RasterLine
	call	RasterBezier		;scan convert Bezier into region

	pop	bx				;bx <- handle, if any
	tst	bx				;see if stack passed
	jz	done				;yes, we're done
	call	MemFree				;else, free our stack
done:
	pop	dx
	pop	cx
	call	GrRegionPathMovePen		;set pen to p3
	.leave
	ret
GrRegionPathAddBezierAtCPReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathAddPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a polygon to the given region/path.
CALLED BY:	GLOBAL

PASS:		cx - # of points
		ds:di - ptr to points (Point[cx])
		es - seg addr of RegionPath
RETURN:		es - (new) seg addr of RegionPath

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	As with all of the GrRegionPath routines, this currently
	does not deal with self-crossing paths with any rule other
	than the even/odd rule.

	This routine automatically closes the polygon by connecting
	the last point to first.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/90		Initial version
	don	7/24/91		Changed name & made globally accessible

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrRegionPathAddPolygon	proc	far
	;
	; Compute size of data in DS:DI  (Point is 4 bytes)
	;		
		push	cx
		shl	cx, 1				
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx

		mov	ss:[TPD_dataBX], handle GrRegionPathAddPolygonReal
		mov	ss:[TPD_dataAX], offset GrRegionPathAddPolygonReal
		GOTO	SysCallMovableXIPWithDSDIBlock
GrRegionPathAddPolygon	endp
CopyStackCodeXIP	ends

else

GrRegionPathAddPolygon	proc	far	
		FALL_THRU	GrRegionPathAddPolygonReal
GrRegionPathAddPolygon	endp

endif

GrRegionPathAddPolygonReal	proc	far	
	uses	cx, dx
	.enter

	; Add the polyline to the RegionPath, and then close it
	;
	push	ds:[di].P_x
	push	ds:[di].P_y
	call	GrRegionPathAddPolylineReal	;add the polyline
	pop	cx, dx				;(cx,dx) <- 1st point
	call	GrRegionPathAddLineAtCP		;LINE_TO(cx,dx)

	.leave
	ret
GrRegionPathAddPolygonReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrRegionPathAddPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a polyline (multiple lines joined at the endpointd)
		to the RegionPath being built.
CALLED BY:	GLOBAL

PASS:		cx - # of points
		ds:di - ptr to points (Point[cx])
		es - seg addr of RegionPath
RETURN:		es - (new) seg addr of RegionPath

DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	As with all of the GrRegionPath routines, this currently
	does not deal with self-crossing paths with any rule other
	than the even/odd rule.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrRegionPathAddPolyline	proc	far
	;
	; Compute size of data in DS:DI (Point is 4 bytes).
	;
		push	cx
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx
	
		mov	ss:[TPD_dataBX], handle GrRegionPathAddPolylineReal
		mov	ss:[TPD_dataAX], offset GrRegionPathAddPolylineReal
		GOTO	SysCallMovableXIPWithDSDIBlock
GrRegionPathAddPolyline	endp
CopyStackCodeXIP	ends

else

GrRegionPathAddPolyline	proc	far
		FALL_THRU	GrRegionPathAddPolylineReal
GrRegionPathAddPolyline	endp

endif

GrRegionPathAddPolylineReal	proc	far
	uses	cx, dx, di
	.enter
	
	push	cx
	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y
	call	GrRegionPathMovePen		;set pen to 1st point
	pop	cx
	dec	cx				;one point used
lineLoop:
	add	di, size Point			;advance to next point
	push	cx
	mov	cx, ds:[di].P_x
	mov	dx, ds:[di].P_y			;(cx,dx) <- current point
	call	GrRegionPathAddLineAtCP		;LINE_TO(cx,dx)
	pop	cx
	loop	lineLoop			;loop while more points

	.leave
	ret
GrRegionPathAddPolylineReal	endp

GraphicsRegionPaths ends
