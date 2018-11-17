COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Graphics		
FILE:		graphicsEllipse.asm

AUTHOR:		Ted H. Kim,  7/5/89

ROUTINES:
	Name			Description
	----			-----------
	AllocEDB		allocates ellipse delta block
	FillEDB			fills ellipse delta block with deltas +
	FixUpFirstQuadDeltas	modifies deltas in some special cases
	CreateOtherQuads	calls appropriate routines to create quads
	Create###Quad??????	group of routines for creating quads
	CreateEllipseDeltaBuffer returns complete ellipse delta block
	Small1stQuadDeltas	generate 1st quad deltas for small ellipses
	ConvertDeltasToPoints	converts ellipse deltas to screen coords
	CombinePoints		combine points into lines
	CalcOffset		convert angle to offsets to deltas
	InitStackFrame		initializes some variables
	GetFMid1		initializes a variable called 'fmid'
	DoOctant1		gets the points on octant one
	GetFMid2		updates the variable 'fmid'
	DoOctant2		gets the points on octant two
	
	DoSpecialCases		handles ellipses 3 or 4 pixel wide
	GetRBuffer		allocates region definition buffer
	InitRBuffer		initializes the region definition buffer
	GenTopRegion		generates the points of top half of ellipse
	GenBotRegion		generates the points of bottom half of ellipse
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	3/89		Initial revision
	jim	8/89		moved support routines to kernel lib
	srs	9/89		major changes

DESCRIPTION:
	This file contains routines that generate non-rotated,
	origin centered ellipses.

	$Id: graphicsEllipseLow.asm,v 1.1 97/04/05 01:13:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Overview
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ELLIPSE INFO:

	DEFINITIONS:

	Some of these definitions may seem a bit trivial, but I hope to
	eliminate future confusion by making the little things quite clear.

		width  - the number pixels spanning the horizontal distance
			 across an object. In the case of a rectangle:

			 width = xRight - xLeft + 1

		delta x - not to be confused with width. delta x is merely
			  the difference between right and left values.
			
			 delta x = xRight - xLeft			

			 references to delta x in the comments may refer
			 to either the ellipse rect or the deltas from
			 the center of the ellipse. The usage should be
			 clear from the context.

		height  - the number pixels spanning the vertical distance
			 of an object. In the case of a rectangle:

			 height = xBottom - xTop + 1

		delta y - not to be confused with height. delta y is merely
			  the difference between bottom and top values.

			  delta y = xBottom - xTop			

			 references to delta y in the comments may refer
			 to either the ellipse rect or the deltas from
			 the center of the ellipse. The usage should be
			 clear from the context.

		ellipseRect - the rectangle passed to the ellipse drawing
			  code. At its widest point an ellipse will have
			  the same number of pixels as a rectangle drawn
			  with the same coordinates. Same applies to the
			  height.


	DATA STRUCTURES:

		Ellipse Delta Buffer (EDB) contains enough information
		to draw the same size ellipse, or any of its arcs at
		any position on the screen. If you are only drawing one
		ellipse or arc, it provides no benefit, but for multiple
		drawings it saves the time of calculating and mirroring
		the deltas. It consists of a small structure which is
		defined in graphicsConstant.def and a buffer of deltas.
		The buffer immediately follows the structure.
		


	BASIC STEPS for calculating and ellipse are as follows.

	1. Calculate the deltas from the center of the ellipse for the 
	   1st (upper right) quadrant and put them in 
	   an Ellipse Delta Block (EDB).

	2. Mirror the deltas for the 1st quadrant to form the 2nd, 3rd and 
	   4th quadrant and put these deltas in the EDB in that order. The
	   first delta in the buffer corresponds to 0 degrees and the deltas
	   are in counter clockwise order in the block.

	3. Add the center to each delta value and store these points in a
	   points buffer (PB).

	4. Combine these points into longer line segments, either vertical
	   horizontal or diagonal.

	5. Pass these points to a poly line or polygon drawing routine.

	Of course, nothing is really that simple. I will now elaborate on the
	ugliness hiden in each of the above steps and provide any other 
	useful info as I see fit.

	1,2. The algorithm to calculate the deltas for the first quadrant was
	   taken from "Fundamentals Algorithms for Computer Graphics". The 
	   coding was done by Ted, so I know very little about how it works.
	   But I have become quite knowledgeable about what it does. 

	   Consider an ellipseRect that has an odd width and an odd height.
	   This ellipse has an clearly defined pixel at its center.

		   xOfCenter = xLeft + width/2
		   yOfCenter = yTop + height/2

	   example of ellipse with width =7, height =7
	   x marks the center.

		 0123456
		0  ***		
		1 *   *
		2*     *
		3*  x  * 
		4*     *
		5 *   *
		6  ***

	   Here is the same ellipse drawn with the coordinate system that
	   matches the deltas that would be calculated for it. The first
	   quadrant deltas start with `a` and goes counter clockwise though 'b'

		  --- +++
		  3210123
		-3  *b*		
		-2 *   *
		-1*     *
		 0*  x  a 
		+1*     *
		+2 *   *
		+3  ***


	   However, if either the height or width or both are even, then
	   there is no clearly defined pixel at its center.

	   example of ellipse with width=8 and height =8

		  ---- +++
		  43210123
		-4  ****		
		-3 *    *
		-2*      *
		-1*  xx  * 
		 0*  xx  *
		+1*      *
		+2 *    *
		+3  ****

	   As you can see, there are four pixels that are close to the center
	   but none that are acutally at the center. For consistency sake, 
	   the equations for the center will always be used. This has the
	   effect of moving the center down or to the right or both if either
	   or both of the dimensions are even. This off-center center does not
	   alter the looks of an ellipse, but it has a profound affect on the
	   appearance of arcs. 

	   The code that generates the deltas for the 1st quadrant treats an
	   even dimension as the next smallest odd dimensions (that's 
	   techno-babble for one less). This behaviour adversely impacts the
	   code that mirrors the deltas to the other quadrants. Below you
	   will find a routine called FixUpFirstQuadDeltas and a whole bunch
	   of routines like Create2ndQuadOddOdd which handle the various
	   situations. The routines are beautifully commented, read them
	   for more exciting information.

	NOTE: it is quite possible that something could be changed in the
	      code that calculates the 1st quad deltas to cut down on the
	      number of CreateXXXQuadYYYZZZ type routines,
	      but I was in a hurry, so I took the easiest solution.

	4. The algorithm which generates the deltas for the first quadrant 
	   is similar to Bresenhams line algorithm. The difference between
	   two successive deltas is at most 1 in x and y. This results in
	   groups of deltas that can be represented with just one line. 
	   The actual conversion into lines is not done until the deltas are
	   made into to points so that more accurate angles can be calced
	   for the arc code. (See ARC INFO below)

ARC INFO:

	To draw an arc, the first thing that is done is to create an ellipse
	delta block just as described above under ELLIPSE INFO.

	The arc is really a subset of the deltas for the ellipse. The 
	routine CalcOffset converts the angles of the arc into offsets
	into the delta buffer. Then just the deltas between the starting
	and ending offsets are converted and used for the arcs.

	Converting the angles into offset requires that the deltas be
	evenly spaced around the ellipse. This works great for ellipses
	with a clearly defined center. However, read on.

	All arcs created from a given ellipse are drawn with the same 
	center. For ellipses with the off-center problem (discussed above),
	arcs from the lower, right of the ellipse will be smaller than ones
	from the upper left. 

	Consider this example width = 8, height =8 and the four 
	quadrant arcs

	  ****		  ***	**
	 ******		 ****	***
	********	*****	****
	********	*****	****
	****x***	****x	x***
	********	
	 ******		****x	x***
	  ****		*****	****
			 ****	***
			  ***	**

	The solution for calculating offsets, though not pretty, 
	is easy to implement and has the desired affect of producing
	straight sides on filled arcs for angles along the axes. 
	Since the alogorithm that creates the deltas for the 1st quadrant
	of the ellipse treats an even dimension like the odd dimension
	that is one less than the even, I do something similar. I treat
	an ellipse like the next smaller odd,odd ellipse, when I calculate
	the offset from the angle. I still must compensate for the "extra"
	deltas the make the width or height even. This compensation
	is described in the header for the CalcOffest routine.
	


RANDOM REASONING:
	Above I mentioned that all arcs created from a given ellipse are drawn
	with the same center. This decision led to different sized arcs
	for ellipses with the off-center center problem. The alternative
	solution was a sort of floating center. For the even-width 
	even-height case in the ELLIPSE INFO section, I could have attempted
	to choose a good center for each arc being drawn. The most obvious
	case being the 4 quadrant arcs - choosing the corner in that quadrant
	would have provided 4 equally sized arcs. However, for the floating 
	center solution it is not easy to find a good center for many cases
	and you would end up with narrow arcs that do not come to a point.
	
	The solution I chose has its own problems.
	
		different size arcs
		jmp just after comensation angles
	



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@




if	0
GraphicsEllipse segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillEllipseLowTransed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Another entry point for ellipse routine
		It assumes 'EnterGraphics' have already been called 
		and that the coordinates are in screen coordinates.

CALLED BY:	DrawRoundedCap
		DrawRoundedJoin

PASS:		ds - graphics state structure 		
		es - window structure
		ax	- x1 (left)
		bx	- y1 (top)
		cx	- x2 (right)
		dx	- y2 (bottom)
		si	- offset to area attributes

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, si, di, ds, es, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Does not handle rotated ellipses 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FillEllipseLowTransed	proc	far
	clr	di		;starting angle
	clr	bp		;ending angle =0
	call	FillArcLowTransed
	ret
FillEllipseLowTransed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateEllipseDeltaBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns completed Ellipse Delta Block (EDB)

CALLED BY:	

PASS:		ax	- x1 (left)
		bx	- y1 (top)
		cx	- x2 (right)
		dx	- y2 (bottom)
		

RETURN:		
		bx - handle of ellipse delta block
		EDB_deltaX
		EDB_deltaY
		EDB_doNotCombine
		di - number of deltas
		EDB_numDeltas - same as di


DESTROYED:	
	ax,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
	See Overview section near begining of file for more into	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateEllipseDeltaBlock		proc	far
	call	FillEDB
	call	MemUnlock
	ret
CreateEllipseDeltaBlock		endp

					

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AllocEDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate block to hold Ellipse Delta Block

CALLED BY:	INTERNAL
		FillEDB

PASS:		ax	- x1 (left)
		bx	- y1 (top)
		cx	- x2 (right)
		dx	- y2 (bottom)

RETURN:		ds - segment of newly allocated block
		di - handle of newly allocated block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Size of buffer = ((width + height) * 8) + size EllipseDeltaBlock
	(width + height)*8 = worst case. This would handle all 
			     points for	a square.

	The best possible case would be a diamond with 45 degrees sides.
	This would require (width+height)*4 bytes of space. So if the
	requested ellipses best case won't fit in 64k then it is an error.
	If the best case fits, but the worst cases doesn't I allocated
	all 64k and depend on range checking when creating the quads.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version
	Ted	6/2/89		Returns handle in di
	srs	9/12/89		Allocs buffer for entire ellipse instead of
				just a quadrant
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AllocEDB	proc	near
	push	ax, bx, cx, dx
	sub	cx, ax		; get total delta x of ellipse
	inc	cx		; width
	sub	dx, bx		; get total delta y of ellipse
	inc	dx		; height
	add	cx, dx		; cx = width + height
EC<	cmp	cx, 03ffeh	; would best case fit >
EC<	ERROR_GE GRAPHICS_ARC_TOO_BIG	; error if no	>
	cmp	cx,01FFFh	; 
	jge	AEDB_max	; jmp if worst case alloc would be > 65536
	mov	ax, cx		; ax - number of bytes need to be allocated
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	add	ax, size EllipseDeltaBlock
	cmp	ax,0xfff0
	ja	AEDB_max
AEDB_10:
	mov	cx, ALLOC_DYNAMIC_NO_ERR or (mask HAF_LOCK shl 8 )
	call	MemAllocFar	; allocate a memory block for points on ellipse
	mov	ds, ax		; return seg. of block in es
	mov	di, bx		; return the handle of block in bp
	DoPop	dx, cx, bx, ax
	ret

AEDB_max:
	mov	ax,0fff0h	;alloc biggest, ellipse may still fit
	jmp	short AEDB_10

AllocEDB	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FillEDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocates block for ellipse delta block. Generates deltas 
		from center for entire ellipse and puts them in ellipse
		delta block

CALLED BY:	INTERNAL
		CreateEllipseDeltaBlock

PASS:		ax	- x1 (left)
		bx	- y1 (top)
		cx	- x2 (right)
		dx	- y2 (bottom)

RETURN:		ds - ellipse delta block
		ds:EDB_deltaX
		ds:EDB_deltaY
		ds:EDB_doNotCombine
		di - number of deltas
		ds:EDB_numDeltas - same as di
		bx - handle of ellipse delta block

DESTROYED:	ax cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The error checking done after the call to CalcFirstQuadDeltas
	checks the number of deltas against 1/4 of the number of 4 bytes
	deltas that would fill an entirely
	allocated block. Since the first quad never has less deltas than
	the other quads, if it first in 1/4 of a block, the whole thing
	should fit. See AllocEDB for further enlightenment

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FEDB_StackFrame	struct
	FEDB_left		dw		?	; left
	FEDB_right		dw		?	; right
	FEDB_halfDeltaY		dw		?	; height/2
	; for the following variables, refer to page 266
	; of Fundamental Algorithms for Computer Graphics

	FEDB_x			dw		?
	FEDB_y			dw		?
	FEDB_asquareLow		dw		?
	FEDB_asquareHigh		dw		?
	FEDB_bsquareLow		dw		?
	FEDB_bsquareHigh		dw		?
	FEDB_a22Low		dw		?
	FEDB_a22High		dw		?
	FEDB_b22Low		dw		?
	FEDB_b22High		dw		?
	FEDB_xSlopeLow		dw		?
	FEDB_xSlopeMid		dw		?
	FEDB_xSlopeHigh		dw		?
	FEDB_ySlopeLow		dw		?
	FEDB_ySlopeMid		dw		?
	FEDB_ySlopeHigh		dw		?
	FEDB_fmidIntLow		dw		?
	FEDB_fmidIntMid		dw		?
	FEDB_fmidIntHigh		dw		?
	FEDB_fmidFrac		dw		?
FEDB_StackFrame	ends
	
FEDB_Local	equ		<[bp - (size FEDB_StackFrame)]>

FillEDB	proc	near
EC < 	call	ECMemVerifyHeapHighECEllipse		>
	push	es				;don't destroy
	push	bp				; create a stack frame
	mov	bp, sp
	sub	sp, size FEDB_StackFrame	; need thirty six bytes

	mov	FEDB_Local.FEDB_left, ax	; save x1 and x2
	mov	FEDB_Local.FEDB_right, cx
	call	AllocEDB
	push	di				;save handle of EDB
	call	InitStackFrame	
	mov	ax,ds				;make es segment of deltas
	mov	es,ax				;too
	call	CalcFirstQuadDeltas
EC<	cmp	cx,0x0fff					>
EC<	ERROR_G GRAPHICS_ARC_TOO_BIG					>
	call	CreateOtherQuads
	pop	bx				;EDB handle
	mov	sp, bp				
	pop	bp				; exit the stack frame

	sub	di, EDB_startDeltas
	shr	di,1
	shr	di,1
	mov	ds:EDB_numDeltas,di
	pop	es
EC < 	call	ECMemVerifyHeapHighECEllipse		>
	ret
FillEDB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcFirstQuadDeltas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc deltas from center for 1st quadrant of ellipse

CALLED BY:	INTERNAL
		FillEDB

PASS:		ss:bp GA_Local stack frame
		FEDB_y
		FEDB_x
		FEDB_halfDeltaY
		FEDB_deltaY
		FEDB_deltaX
		ds - segment of EDB
		es - same as ds
		di - delta y of ellipse rect
RETURN:		
		cx - number of deltas in first quadrant


DESTROYED:	
		ax,di,si

PSEUDO CODE/STRATEGY:

	see Overview section near begining of file	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CFQD___10:
	call	Small1stQuadDeltas
	jmp	short CFQD_10
CalcFirstQuadDeltas		proc	near
	mov	si,EDB_startDeltas	;offset to store deltas
	test	ds:EDB_deltaY,0001h
	jz	CFQD_5			;jmp if odd height
	add	si,4			;leave room for extra first delta
					;inserted by FixUpFirstQuadDeltas
CFQD_5:
	cmp	ds:EDB_deltaX,4
	jle	CFQD___10
	cmp	ds:EDB_deltaY,4
	jle	CFQD___10
	call	GetFMid1	; calculate fmid
	call	DoOctant1	; get the points in octant1
	call	GetFMid2	; recalculate fmid for octant2
	call	DoOctant2	; get the points in octant2
CFQD_10	label	near
	mov	cx,si		;offset past last delta
	sub	cx,EDB_startDeltas
	shr	cx,1		;divide by 4 to get number of deltas in
	shr	cx,1		;first quadrant
	test	ds:EDB_deltaY,0001h
	jz	CFQD_90		;jmp if even deltaY, (ie odd height)
	call	FixUpFirstQuadDeltas
CFQD_90:
	ret
CalcFirstQuadDeltas		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Small1stQuadDeltas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates 1st quad deltas for small ellipses

CALLED BY:	INTERNAL
		CalcFirstQuadDeltas

PASS:		ss:bp GA_Local stack frame
		FEDB_y	- value for first ellipse delta
		FEDB_x	- value for first ellipse delta
		FEDB_halfDeltaY
		ds:EDB_deltaY - 
		ds:EDB_deltaX - 
		ds - segment of EDB
		si - offset to put deltas at
		es - same as ds

RETURN:		
		si - offset past last delta generated

DESTROYED:	
		ax,bx,cx,dx,di

PSEUDO CODE/STRATEGY:
	The delta generating algorithm does not handle ellipses with
	deltaX <= 4 or deltaY <= 4		

	For most of this cases the ellipse generated is basically a
	rectangle with the pixel in each of the corners missing

		whole ellipse		first quad
			 **		  *
			*  *		   *
			 **

	So I put in the buffer (halfDeltaY-1) deltas, starting with the passed
	FEDB_x and FEDB_y and decrement y each time. This forms the
	right side of the first quadrant. Then with y = halfDeltaY
	Then I decrement x, put in the delta, dec x, put in the
	delta and so on until and including x = 0. This forms the top
	of the first quadrant


	For ellipse both deltas at least 4, we can make the ellipse less
	square.

			  *****			  *
			 *     *		 * *
			*       *		*   *
			 *     *		*   *
			  *****			*   *
						*   *
						 * *
						  *

	For these ellipses, the right side is drawn up to (halfDeltaY-2)
	instead of (halfDeltaY-1). This allows room to add in a diagonal
	pixel.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	either the passed deltaX or deltaY must be less than or equal to 4

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

S1QD___10:	;DELTA X = 4 
	cmp	ds:EDB_deltaY,4
	jle	S1QD_6			;jmp if small

		;LESS SQUARE ELLIPSE
	dec	bx			;make room for diagonal
	jmp	short S1QD_6

S1QD___20:	;DELTA Y = 4
	cmp	ds:EDB_deltaX,4
	jle	S1QD_6			;jmp if small

		;LESS SQUARE ELLIPSE
	dec	bx			;make room for diagonal
	jmp	short S1QD_6

Small1stQuadDeltas		proc	near
	mov	di,si			;where to store
	mov	cx,FEDB_Local.FEDB_x	;initial xDelta
	mov	dx,FEDB_Local.FEDB_y	;initial yDelta
	mov	bx,FEDB_Local.FEDB_halfDeltaY	;stop right side before this
	
	cmp	ds:EDB_deltaX,4
	je	S1QD___10		;jmp to check for less square ellipse
	cmp	ds:EDB_deltaY,4
	je	S1QD___20		;jmp to check for less square ellipse
S1QD_6	label	near
	neg	bx			;y deltas from center are negative

	mov	ax,cx			;store initial delta always
	stosw
	mov	ax,dx
	stosw

	tst	bx			;
	jz	S1QD_30			;jmp if ellipse 1,2 pixels high, means
					;initial delta is whole right side

S1QD_10:		; DO RIGHT SIDE
	dec	dx			;move up right side
	cmp	dx,bx			;
	jle	S1QD_20			;jmp if y is part of top or diagonal
	mov	ax,cx			;store part of right side
	stosw	
	mov	ax,dx
	stosw
	jmp	short S1QD_10		;continue right side

S1QD_20:		;ATTEMPT DIAGONAL
	neg	bx
	cmp	bx,FEDB_Local.FEDB_halfDeltaY
	je	S1QD_25			;jmp if no space for diagonal
	dec	cx			;x
	mov	ax,cx			;store diagonal
	stosw	
	mov	ax,dx
	stosw
	dec 	dx			;set y for top

S1QD_25:
	tst	cx
	jz	S1QD_35			;jmp if very thin, this will result
					;rect WITH corners
S1QD_30:		;DO TOP
	dec	cx			;move right 1
	tst	cx
	jl	S1QD_40			;jmp if done
S1QD_35:
	mov	ax,cx			;store part of top
	stosw
	mov	ax,dx
	stosw
	jmp	short S1QD_30		;continue top
S1QD_40:
	mov	si,di			;return offset after last delta
	ret
Small1stQuadDeltas		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FixUpFirstQuadDeltas
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fixes up the first quadrant deltas when the height is even.

CALLED BY:	INTERNAL
		CalcFirstQuadDeltas

PASS:		
		ds - segment of Ellipse Deltas Buffer
		es - same as ds
		cx - number of deltas in buffer
RETURN:		
		cx - number of deltas in buffer 
		
DESTROYED:	
		ax,di,si

PSEUDO CODE/STRATEGY:
	The first quadrant algorithm returns deltas a through b based on
	the false center f when the height is even. The proper center is
	x, so we create a new first delta c, which has the same values as
	the original a and then we increase the y deltas for the remaining
	ones because the center is one farther away in y.

	  *b*
	 *   *
	*  f  a
	*  x  c
	 *   *
	  ***


	The space for the first delta is currently empty. Make a copy
	of the second delta into the first delta and then decrement the 
	y values of the second through last deltas.

	See Overview section near begining of file for more info.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FixUpFirstQuadDeltas		proc	near
	mov 	si, 4+EDB_startDeltas		;pt to second delta
	mov	di, EDB_startDeltas
	lodsw					;copy second delta into first
	stosw
	lodsw	
	stosw
	push	cx				;number of deltas
	dec	cx				;don't include first delta
	sub	si,2				;pt back to second y
	add	di,2				;pt to second y
FUFQD_10:
	lodsw					;get y
	dec	ax				;adjust for correct center
	stosw					;put it back
	add	si,2				;skip over x
	add	di,2				;skip over x
	dec	cx
	jnz	FUFQD_10
	pop	cx
	ret
FixUpFirstQuadDeltas		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateOtherQuads
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls proper routines to calculate 2nd, 3rd, and 4th
		quadrant of deltas and put them in EDB

CALLED BY:	INTERNAL
		FillEDB

PASS:		
		ds - segment of EDB
		ds:EDB_deltaX
		ds:EDB_deltaY
		cx - number of deltas in first quadrant
		es - same as ds
RETURN:		
		di - offset past last delta in EDB
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
	Based on the ellipseSizeInfo call the appropriate routines

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
COQ___10:	;EVEN WIDTH, ODD HEIGHT
	call	Create2ndQuadEvenOdd
	call	Create3rdQuadEvenOdd
	call	Create4thQuadEvenOdd
	jmp	short	COQ_90
CreateOtherQuads		proc	near
	test	ds:EDB_deltaY,0001h
	jnz	COQ_100			;jmp if even height
	test	ds:EDB_deltaX,0001h 
	jnz	COQ___10		;jmp if even width
 	call	Create2ndQuadOddOdd
	call	Create3rdQuadOddOdd
 	call	Create4thQuadOddOdd 
COQ_90	label	near
	ret 
COQ_100:
	test	ds:EDB_deltaX,0001h
	jnz	COQ_110			;jmp if even width
	;ODD WIDTH,EVEN HEIGHT 	
	call	Create2ndQuadOddEven
	call	Create3rdQuadOddEven 	
	call	Create4thQuadOddEven
	jmp	short	COQ_90 
COQ_110:	;EVEN WIDTH, EVEN HEIGHT
	call	Create2ndQuadEvenEven 	
	call	Create3rdQuadEvenEven
	call	Create4thQuadEvenEven
 	jmp	short	COQ_90
CreateOtherQuads		endp 

 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create2ndQuadOddOdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculate the deltas
 		for the second quadrant and put them in the buffer. Used
 		when both the height and width are odd.  

CALLED BY:	INTERNAL 		
		CreateOtherQuads 
PASS:
	ds - segment containing 1st quad deltas 		
	es - same as ds 		
	cx - number of first quad deltas

RETURN:		Deltas for second quad in EDB 	 

DESTROYED:
	ax,di 

PSEUDO CODE/STRATEGY: 	
	Example of ellipse that with width = 7 , height = 7 	
	Translate deltas a though b to c through d, note copy
	is in 	reverse order.  			 		
		    last delta in 1st quad 		 
		    | 		 
		    v
		  d*b 
		 *   * 		
		*     *	
 		c  x  a <- 1st delta in 1st quad
 		*     *
 		 *   *
		  *** 		 	
	number of first quad deltas = 5
 	number to translate = N1QD-1 = 4
 	start src pt = 0
 	start dest pt = ((N1QD-1)*2) = 8 	
	copy in reverse order 	
	translation ( deltaX >= 0, deltaY >= 0) 		
		negate deltaX 		
		unchanged deltaY

 	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS: 	
	passed cx must always be at least 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/12/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create2ndQuadOddOdd		proc	near
	push	cx			;don't destroy
	mov	di,cx			;num 1st quad deltas (N1QD)
	dec	di			;(N1QD-1)*2)*4 = offset to
	shl	di,1			;to copy first delta to
	shl	di,1 	
	shl	di,1 	
	add	di,EDB_startDeltas
	mov	si,EDB_startDeltas	;offset to first delta to copy
	dec 	cx			;number of deltas to copy
	jz	C2QOO_90
C2QOO_10:	 	
	lodsw				;get delta x
	neg 	ax			;translate delta x
	stosw				;store new delta x
	lodsw				;get delta y
	stosw				;store delta y
	sub	di,8			;reverse order copy 	
	dec	cx
	jnz	C2QOO_10		;jmp if more deltas to do
C2QOO_90:
	pop	cx 	
	ret 
Create2ndQuadOddOdd		endp 
 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create3rdQuadOddOdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculated the deltas
 		for the third quadrant and put them in the buffer. Used when
 		both the height and width of the ellipse are odd.  

CALLED BY:	INTERNAL 		
		CreateOtherQuads
PASS:		 		
		ds - segment containing 1st quad deltas
 		es - same as ds 		
		cx - number of first quad deltas 
RETURN:		 
		Deltas for 3rd quad EDB
DESTROYED:	 

PSEUDO CODE/STRATEGY:
	Example of ellipse that with width = 7 , height = 7 Translate deltas a
	though b to c through d 		

		last delta in 1st quad
		   |  		 
		   v 		 
		  *b*		 		 
		 *   *
		*     a 		
		*  x  * <- 1st delta in 1st quad 		
		c     *
		 *   * 		 
		  *d* 	

	number of first quad deltas = 5
 	number to translate = N1QD-1 = 4
 	start src pt = 1
 	start dest pt = ((N1QD*2)-1) = 9
 	translation (detlaX >= 0, deltaY < 0)
		negate deltaX
 		negate deltaY

See Overview section near begining of file for more info.

KNOWN BUGS/SIDE EFFECTS/IDEAS: 	
	passed cx must always be at least 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create3rdQuadOddOdd		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;(N1QD*2)-1)*4 = offset to begining
	dec	di			;of third quadrant
 	shl	di,1
	shl	di,1
 	add	di,EDB_startDeltas
 	mov	si,4 + EDB_startDeltas	;offset to 2nd delta, 1st to copy
	dec	cx			;number of deltas to copy 
	jz	C3QOO_90
C3QOO_10:
	lodsw				;get delta x
	neg	ax			;translate delta x
	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
	stosw				;store new delta y
 	dec	cx
	jnz	C3QOO_10		;jmp if more deltas to copy
C3QOO_90:
	pop	cx
 	ret 
Create3rdQuadOddOdd		endp 
 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create4thQuadOddOdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 2nd quadrant, calculated the deltas
 		for the 4th quadrant and put them in the buffer. Used when
 		both the height and width of the ellipse are odd.

CALLED BY:	INTERNAL
 		CreateOtherQuads

PASS:
 		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas

RETURN:		Deltas for 4th quad in EDB
		ds:di - points passed last delta for ellipse 

DESTROYED:
	ax,di 

PSEUDO CODE/STRATEGY: 
	Example of ellipse that with width = 7 , height = 7 
	Translate deltas a though b to c through d

 		last delta in 1st quad
 		   |
 		   v
		  a**
 		 *   *
 		b     *
 		*  x  * <- 1st delta in 1st quad
 		*     d
 		 *   * 
		  **c 	

	number of first quad deltas = 	5
 	number to translate = N1QD-2 = 3
 	start src pt = N1QD = 5
 	start dest pt = ((N1QD*3)-1) = 14
 	translation ( deltaX < 0, deltaY < 0)
		negate deltaX
 		negate deltaY

See Overview section near begining of file for more info. 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	passed cx must always be at least 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create4thQuadOddOdd		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;(N1QD*3)-2)*4 = offset to begining
	add	di,cx 	
	sub	di,2			;of 4th quadrant
	shl	di,1 	
	shl	di,1 	
	add	di,EDB_startDeltas
	mov	si,cx			;offset to 1st delta of 2nd quad
	shl	si,1			;N1QD*4
 	shl	si,1
	add	si,EDB_startDeltas
	sub	cx,2			;number of deltas to copy
	jle	C4QOO_90 
C4QOO_10:
 	lodsw				;get delta x
 	neg	ax			;translate delta x
	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
	stosw				;store new delta y
 	dec	cx
	jnz	C4QOO_10		;jmp if more deltas to copy 
C4QOO_90:
	pop	cx
 	ret
Create4thQuadOddOdd		endp

 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create2ndQuadOddEven
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculate the deltas
 		for the second quadrant and put them in the buffer. Used 
		when the width is odd and the height is even 

CALLED BY:	INTERNAL
 		CreateOtherQuads 
PASS:
		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas

RETURN:		Deltas for 2nd quad in EDB 

DESTROYED:
		ax,di 

PSEUDO CODE/STRATEGY: 	
	Example of ellipse that with width = 7 , height = 8 	
	Translate deltas a though b to c through d, note the deltas
 	are in reverse order

 		last delta in 1st quad
		   |
 		   v
 		  d*b
 		 *   *
		*     *
 		*     *
 		c  x  a <- 1st delta in 1st quad
		*     *
 		 *   *
 		  ***
 		 	
	number of first quad deltas = 6
 	number to translate = N1QD-1 = 5
 	start src pt = 0
 	start dest pt = ((N1QD-1)*2) = 10
 	copy in reverse order
 	translation ( deltaX >= 0, deltaY <= 0)
		negate deltaX
 		unchanged deltaY

	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS: 

	passed cx must always be at least 1 

REVISION HISTORY:

	Name	Date		Description
	----	----		-----------
	srs	9/12/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create2ndQuadOddEven		proc	near
	push	cx			;don't destroy
	mov	di,cx			;num 1st quad deltas (N1QD)
	dec	di 			;((N1QD-1)*2))*4 = offset to
	shl	di,1			;copy first delta to
	shl	di,1
 	shl	di,1
 	add	di,EDB_startDeltas
	mov	si,EDB_startDeltas	;offset to first delta to copy
	dec 	cx			;number of deltas to copy
	jz	C2QOE_90
C2QOE_10:
	lodsw				;get delta x
	neg 	ax			;translate delta x
	stosw				;store new delta x
	lodsw				;get delta y
	stosw				;store delta y
	sub	di,8			;reverse order copy
 	dec	cx
	jnz	C2QOE_10		;jmp if more deltas to do
C2QOE_90:
	pop	cx
 	ret 
Create2ndQuadOddEven		endp 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create3rdQuadOddEven
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculated the deltas
 		for the third quadrant and put them in the buffer. Used when
 		the width is odd and the height is even 

CALLED BY:	INTERNAL
 		CreateOtherQuads 
PASS:
		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas

RETURN:		Deltas for 3rd quad in EDB 

DESTROYED:
		ax,di 

PSEUDO CODE/STRATEGY: 	
	Example of ellipse that with width = 7 , height = 8
 	Translate deltas a though b to c through d

		last delta in 1st quad
 		   |
 		   v
		  *b*
 		 *   *
 		*     a
 		*     *
		*  x  * <- 1st delta in 1st quad
 		c     *
 		 *   *
		  *d* 	

	number of first quad deltas = 6
 	number to translate = N1QD-2 = 4
 	start src pt = 2
 	start dest pt = ((N1QD*2)-1) = 11
 	translation ( deltaX >= 0, deltaY < 0)
 		negate deltaX
		negate deltaY, dec deltaY

 	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS: 	
	passed cx must always be at least 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create3rdQuadOddEven		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;(N1QD*2)-1)*4 = offset to begining
	dec	di			;of third quadrant
 	shl	di,1
	shl	di,1 	
	add	di,EDB_startDeltas
 	mov	si,8 + EDB_startDeltas	;offset to 3rd delta, 1st to copy
	sub	cx,2			;number of deltas to copy
	jle	C3QOE_90 		;jmp if nothing to copy
C3QOE_10:
 	lodsw				;get delta x
 	neg	ax			;translate delta x
	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
	dec	ax
 	stosw				;store new delta y
 	dec	cx
 	jnz	C3QOE_10		;jmp if more deltas to copy 
C3QOE_90: 	
	pop	cx
 	ret
Create3rdQuadOddEven		endp 
 
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create4thQuadOddEven
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 2nd quadrant, calculated the deltas
 		for the 4th quadrant and put them in the buffer. Used when
 		the width is odd and the height is even 

CALLED BY:	INTERNAL
 		CreateOtherQuads 
PASS:
		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas

RETURN:		Deltas for 4th quad in EDB
 		ds:di - points passed last delta for ellipse 

DESTROYED:
 		ax,di

PSEUDO CODE/STRATEGY:
 	Example of ellipse that with width = 7 , height = 8
 	Translate deltas a though b to c through d
	
		last delta in 1st quad
 		   |
 		   v
		  a**
		 *   *
 		b     *
 		*     *
		*  x  * <- 1st delta in 1st quad
 		*     d
 		 *   *
		  **c 	

	number of first quad deltas = 6
 	number to translate = N1QD-3 = 3
 	start src pt = N1QD
 	start dest pt = ((N1QD-1)*3) = 15
 	translation (deltaX < 0, deltaY < 0)
 		negate deltaX
		negate deltaY, dec deltaY

	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create4thQuadOddEven		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	dec	di			;(N1QD-1)*3)*4 = offset to begining
	shl	di,1			;of 4th quadrant
 	add	di,cx			;addition makes it times 3
	dec	di			;but cx was one too high
	shl	di,1
 	shl	di,1
 	add	di,EDB_startDeltas
	mov	si,cx			;offset to 1st delta of 2nd quad
	shl	si,1			;N1QD*4
 	shl	si,1
	add	si,EDB_startDeltas
	sub	cx,3			;number of deltas to copy
	jle	C4QOE_90		;jmp if not points to copy 
C4QOE_10:
	lodsw				;get delta x
	neg	ax			;translate delta x
	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
 	dec	ax
	stosw				;store new delta y
 	dec	cx
	jnz	C4QOE_10		;jmp if more deltas to copy 
C4QOE_90:
	pop	cx
 	ret 
Create4thQuadOddEven		endp 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create2ndQuadEvenOdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculate the deltas
 		for the second quadrant and put them in the buffer. Used
 		when the width is even and the height is odd 

CALLED BY:	INTERNAL
 		CreateOtherQuads 

PASS:
		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas

RETURN:		Deltas for 2nd quad in EDB 

DESTROYED:
		ax,di 

PSEUDO CODE/STRATEGY: 	
	Example of ellipse that with width = 8 , height = 7
 	Translate deltas a though b to c through d, note the deltas are in
 	reverse order

 		last delta in 1st quad
		    |
 		    v
 		  *db*
 		 *    *
		*      *
 		c   x  a <- 1st delta in 1st quad
 		*      *
		 *    *
 		  ****

 	number of first quad deltas = 5
 	number to translate = N1QD = 5
 	start src pt = 0
 	start dest pt = ((N1QD*2)-1) = 9
 	copy in reverse order
 	translation ( deltaX >= 0, deltaY < 0)
 		negate deltaX ,dec deltaX
		unchanged delta y

	See Overview section near begining of file for more info. 

 KNOWN BUGS/SIDE EFFECTS/IDEAS:
	passed cx must always be at least 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/12/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create2ndQuadEvenOdd		proc	near
	push	cx			;don't destroy
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;((N1QD*2))-1)*4 = offset to
	dec	di			;copy first delta to 	
	shl	di,1
	shl	di,1 	
	add	di,EDB_startDeltas
	mov	si,EDB_startDeltas	;offset to first delta to copy
C2QEO_10:
	lodsw				;get delta x
 	neg 	ax			;translate delta x
	dec	ax
	stosw				;store new delta x
	lodsw				;get delta y
	stosw				;store delta y
	sub	di,8			;reverse order copy
 	dec	cx
	jnz	C2QEO_10		;jmp if more deltas to do
	pop	cx
 	ret 
Create2ndQuadEvenOdd		endp 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create3rdQuadEvenOdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculated the deltas
 		for the third quadrant and put them in the buffer. Used when
 		when the width is even and the height is odd

CALLED BY:	INTERNAL
 		CreateOtherQuads

PASS:
 		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas 

RETURN:		Deltas for 3rd quad in EDB

DESTROYED:
 		ax,di 

PSEUDO CODE/STRATEGY:
	Example of ellipse that has width = 8 , height = 7
 	Translate deltas a though b to c through d

 		last delta in 1st quad
		    |
 		    v
 		  **b*
 		 *    *
		*      a
 		*   x  * <- 1st delta in 1st quad 		
		c      *
		 *    *
 		  *d** 	

	number of first quad deltas = 5
 	number to translate = N1QD-1 = 4
 	start src pt = 1
 	start dest pt = ((N1QD*2)) = 10
 	translation ( deltaX >= 0, deltaY < 0)
		negate deltaX ,dec deltaX
 		negate delta y

	See Overview section near begining of file for more info. 

KNOWN BUGS/SIDE EFFECTS/IDEAS: 	

	passed cx must always be at least 1

REVISION HISTORY:
 	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create3rdQuadEvenOdd		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;(N1QD*2))*4 = offset to begining
	shl	di,1			;of third quadrant
 	shl	di,1
	add	di,EDB_startDeltas
 	mov	si,4 + EDB_startDeltas	;offset to 2nd delta, 1st to copy
	dec	cx			;number of deltas to copy 
	jz	C3QEO_90
C3QEO_10:
	lodsw				;get delta x
	neg	ax			;translate delta x
	dec	ax
 	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
	stosw				;store new delta y
 	dec	cx
	jnz	C3QEO_10		;jmp if more deltas to copy
C3QEO_90:
	pop	cx
 	ret 
Create3rdQuadEvenOdd		endp 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create4thQuadEvenOdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 2nd quadrant, calculated the deltas
 		for the 4th quadrant and put them in the buffer. Used when
 		when the width is even and the height is odd 

CALLED BY:	INTERNAL
 		CreateOtherQuads 

PASS:
		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas

RETURN:		Deltas for 4th quad in EDB
 		ds:di - points passed last delta for ellipse 

DESTROYED:	 		ax,di

PSEUDO CODE/STRATEGY: 	
	Example of ellipse that with width = 8 , height = 7
 	Translate deltas a though b to c through d

		last delta in 1st quad
 		    |
 		    v
		  *a**
 		 *    *
 		b      *
 		*   x  * <- 1st delta in 1st quad
 		*      d
 		 *    *
		  **c*

 	number of first quad deltas = 5
 	number to translate = N1QD-1 = 4
 	start src pt = N1QD
 	start dest pt = ((N1QD*3)-1) = 14
 	translation ( deltaX < 0, deltaY < 0)
 		negate deltaX ,dec deltaX
 		negate delta y
 	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS: 	
	passed cx must always be at least 1

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create4thQuadEvenOdd		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;(N1QD*3)-1)*4 = offset to begining
	add	di,cx			;of 4th quadrant
 	dec	di
	shl	di,1
 	shl	di,1
 	add	di,EDB_startDeltas
	mov	si,cx			;offset to 1st delta of 2nd quad
	shl	si,1			;N1QD*4
 	shl	si,1
	add	si,EDB_startDeltas
	dec	cx			;number of deltas to copy 
	jz	C4QEO_90
C4QEO_10:
	lodsw				;get delta x
	neg	ax			;translate delta x 	
	dec	ax
	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
	stosw				;store new delta y 	
	dec	cx
	jnz	C4QEO_10		;jmp if more deltas to copy
C4QEO_90:
	pop	cx 	
	ret 
Create4thQuadEvenOdd		endp 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create2ndQuadEvenEven
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculate the deltas
 		for the second quadrant and put them in the buffer. Used
 		when both the height and width are even.  

CALLED BY:	INTERNAL
 		CreateOtherQuads 

PASS:
		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas

RETURN:		Deltas for 2nd quad in EDB 

DESTROYED:
		ax,di 

PSEUDO CODE/STRATEGY: 	
	Example of ellipse that with width = 8 , height = 8
 	Translate deltas a though b to c through d, note the deltas are in
 	reverse order

 		last delta in 1st quad
		    |
 		    v
 		  *cb*
 		 *    *
		*      *
 		*      *
 		d   x  a <- 1st delta in 1st quad
		*      *
 		 *    *
 		  ****

 	number of first quad deltas = 6
 	number to translate = N1QD = 6
 	start src pt = 0
 	start dest pt = ((N1QD*2)-1) = 11
 	copy in reverse order
	translation ( deltaX >= 0, deltaY <= 0)
 		negate deltaX ,dec deltaX
 		unchanged delta y

 	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
 	passed cx must always be at least 2 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/12/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create2ndQuadEvenEven		proc	near
	push	cx			;don't destroy
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;((N1QD*2)-1))*4 = offset to 	
	dec 	di			;copy first delta to 	
	shl	di,1
	shl	di,1
 	add	di,EDB_startDeltas
	mov	si,EDB_startDeltas	;offset to first delta to copy
C2QEE_10:
 	lodsw				;get delta x
 	neg 	ax			;translate delta x
	dec	ax
	stosw				;store new delta x
	lodsw				;get delta y
	stosw				;store delta y
	sub	di,8			;reverse order copy
 	dec	cx
	jnz	C2QEE_10		;jmp if more deltas to do
	pop	cx
 	ret 
Create2ndQuadEvenEven		endp 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create3rdQuadEvenEven
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 1st quadrant, calculated the deltas
 		for the third quadrant and put them in the buffer. Used when
 		both the height and width of the ellipse are even.  

CALLED BY:	INTERNAL
 		CreateOtherQuads

PASS:
 		ds - segment containing 1st quad deltas
 		es - same as ds
 		cx - number of first quad deltas 

RETURN:		Deltas for 3rd quad in EDB

DESTROYED:
 		ax,di 

PSEUDO CODE/STRATEGY:
	Example of ellipse that with width = 8 , height = 8
 	Translate deltas a though b to c through d

 		last delta in 1st quad
		    |
 		    v
 		  **b*
		 *    *
 		*      a
 		*      *
 		*   x  * <- 1st delta in 1st quad
 		c      *
 		 *    *
 		  *d** 


 	number of first quad deltas = 6
 	number to translate = N1QD-2 = 6
 	start src pt = 2
 	start dest pt = ((N1QD*2)) = 12
	translation ( deltaX >= 0, deltaY < 0)
 		negate deltaX ,dec deltaX
 		negate delta y, dec deltaY

 	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
 	passed cx must always be at least 2 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create3rdQuadEvenEven		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;(N1QD*2))*4 = offset to begining
	shl	di,1			;of third quadrant
 	shl	di,1
	add	di,EDB_startDeltas
 	mov	si,8 + EDB_startDeltas	;offset to 3rd delta, 1st to copy
	sub	cx,2			;number of deltas to copy
	jz	C3QEE_90 
C3QEE_10:
 	lodsw				;get delta x
	neg	ax			;translate delta x
	dec	ax
 	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
 	dec	ax
	stosw				;store new delta y 	
	dec	cx
	jnz	C3QEE_10		;jmp if more deltas to copy 
C3QEE_90:
	pop	cx
 	ret 
Create3rdQuadEvenEven		endp 


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Create4thQuadEvenEven
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Using deltas calced for 2nd quadrant, calculated the deltas
 		for the 4th quadrant and put them in the buffer. Used when
 		both the height and width of the ellipse are even.

CALLED BY:	INTERNAL
		CreateOtherQuads

PASS:
		ds - segment containing 1st quad deltas
 		es - same as ds
		cx - number of first quad deltas 

RETURN:
		ds:di - points passed last delta for ellipse 

DESTROYED:
		ax,di

PSEUDO CODE/STRATEGY: 
	Example of ellipse that with width = 8 , height = 8
	Translate deltas a though b to c through d


 		last delta in 1st quad
		    |
 		    v
		  *a**
 		 *    *
 		b      *
 		*      *
		*   x  * <- 1st delta in 1st quad
 		*      d
 		 *    *
		  **c* 

 	number of first quad deltas = 6
 	number to translate = N1QD-2 = 4
 	start src pt = N1QD
 	start dest pt = ((N1QD*3)-2) = 16
	translation ( deltaX < 0, deltaY <= 0)
 		negate deltaX ,dec deltaX
 		negate deltaY ,dec deltaY

 	See Overview section near begining of file for more info.  

KNOWN BUGS/SIDE EFFECTS/IDEAS:
 	passed cx must always be at least 2 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
Create4thQuadEvenEven		proc	near
	push	cx			;don't destory
	mov	di,cx			;num 1st quad deltas (N1QD)
	shl	di,1			;(N1QD*3)-2)*4 = offset to begining
	add	di,cx 	
	sub	di,2			;of 4th quadrant
	shl	di,1 	
	shl	di,1 	
	add	di,EDB_startDeltas
	mov	si,cx			;offset to 1st delta of 2nd quad
	shl	si,1			;N1QD*4 	
	shl	si,1
	add	si,EDB_startDeltas
	sub	cx,2			;number of deltas to copy
	jz	C4QEE_90 
C4QEE_10:
 	lodsw				;get delta x
 	neg	ax			;translate delta x
	dec	ax
 	stosw				;store new x
	lodsw				;get delta y
	neg	ax			;translate delta y
 	dec	ax
	stosw				;store new delta y
 	dec	cx
	jnz	C4QEE_10		;jmp if more deltas to copy 
C4QEE_90:
	pop	cx
 	ret 

Create4thQuadEvenEven		endp 

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	InitStackFrame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Initialize the stack frame with necessary variables 

CALLED BY:	INTERNAL
		FillEDB 

PASS:		ax	- x1 (left)
		bx	- y1 (top)
 		cx	- x2 (right)
		dx	- y2 (bottom)
 		ds 	- segment of Ellipse Delta Buffer 

RETURN:		stack frame initialized
 		ds:EDB_deltaX
 		ds:EDB_deltaY
 		ds:EDB_doNotCombine

DESTROYED:	ax, bx, cx, dx 

PSEUDO CODE/STRATEGY: 	
	x = a, y = 0
	asquare = a * a, bsquare = b * b 	
	a22 = asquare + asquare
	b22 = bsquare + bsquare
 	xslope = b22 * a, yslope = 0 

KNOWN BUGS/SIDE EFFECTS/IDEAS: 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ISF___10:	;ONLY 1 PIXEL WIDE
	mov	ds:EDB_doNotCombine,1		;don't combine
	jmp	short	ISF_1 
ISF___20:	;ONLY 1 PIXEL HEIGHT		
	mov	ds:EDB_doNotCombine,1		;don't combine
	jmp	short	ISF_12

InitStackFrame	proc	near
	clr	ds:EDB_doNotCombine		;assume combine
	mov	si,EDB_startDeltas		;offset to put deltas at
	sub	cx, ax				; get delta x of ellipse
	jz	ISF___10
ISF_1	label	near
	mov	ds:EDB_deltaX,cx
	sar	cx, 1		; divide it by two
	mov	FEDB_Local.FEDB_x, cx		; save X value in stack frame
	mov	word ptr FEDB_Local.FEDB_y, 0  	; save Y value in stack frame 

	push	dx
	mov	ax, cx		; cx = width/2
	mul	cx		; ax = asquare = (width/2) * (width/2)
	mov	FEDB_Local.FEDB_asquareLow, ax	; save low word of asquare 
	mov	FEDB_Local.FEDB_asquareHigh, dx	; save high word of asquare 
	mov	FEDB_Local.FEDB_a22High, dx	; save high word of a22
	shl	ax, 1		; ax = a22 = 2 * asquare
	rcl	word ptr FEDB_Local.FEDB_a22High,1;if so, increment the high word
	mov	FEDB_Local.FEDB_a22Low, ax	; save low word of a22 
	pop	dx
	sub	dx, bx				;get delta y of ellipse
	jz	ISF___20
ISF_12	label	near
	mov	ds:EDB_deltaY,dx
	sar	dx, 1				;divide it by two
	mov	FEDB_Local.FEDB_halfDeltaY, dx	; save height/2 
	mov	ax, dx
	mul	dx 		; ax = bsquare= (height/2) * (height/2)
	mov	FEDB_Local.FEDB_bsquareLow, ax	; save low word of bsquare 
	mov	FEDB_Local.FEDB_bsquareHigh, dx	; save high word of bsquare
	mov	FEDB_Local.FEDB_b22High, dx
	shl	ax, 1		; ax = b22 = bsquare + bsquare
	rcl	word ptr FEDB_Local.FEDB_b22High,1 ;if so, increment high word b22
	mov	FEDB_Local.FEDB_b22Low, ax	; save low word of b22 
	mov	ax, FEDB_Local.FEDB_x		; ax = a
	mul	word ptr FEDB_Local.FEDB_b22Low	; ax = b22 * a
	mov	FEDB_Local.FEDB_xSlopeLow, ax	; save low word of X slope 
	cmp	word ptr FEDB_Local.FEDB_b22High, 0 ; is high word of b22 zero?
	jne	ISF_30		; if not, do one more multiplication
	mov	FEDB_Local.FEDB_xSlopeMid, dx	; dx is middle word of X slope
	mov	word ptr FEDB_Local.FEDB_xSlopeHigh, 0 ; high word of X slope is 0
	jmp	ISF_40		; skip to calculate Y slope
ISF_30:
	push	dx		; save the carry
	mov	ax, FEDB_Local.FEDB_x	; ax = a
	mov	cx, FEDB_Local.FEDB_b22High ; cx = high word of b22
	mul 	cx		; do high word multiplication
	mov	FEDB_Local.FEDB_xSlopeHigh, dx	; save high word of X slope
	pop	dx		; restore the carry
	add	dx, ax		; add the carry
	adc	FEDB_Local.FEDB_xSlopeHigh, 0	; save high word of X slope
	mov	FEDB_Local.FEDB_xSlopeMid, dx	; save middle word of X slope
ISF_40:
	mov	word ptr FEDB_Local.FEDB_ySlopeLow, 0 ; save initial Y slope 
	mov	word ptr FEDB_Local.FEDB_ySlopeMid, 0 ; save initial Y slope 
	mov	word ptr FEDB_Local.FEDB_ySlopeHigh, 0 ; save initial Y slope 
	ret
InitStackFrame	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFMid1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the variable, fmid, which measures the change
		in octant

CALLED BY:	GrEllipse

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	fmid = bsquare * (.25 - a) + asquare

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFMid1	proc	near
	mov	word ptr FEDB_Local.FEDB_fmidIntHigh, 0	; initialize high byte
	mov	cx, FEDB_Local.FEDB_bsquareLow ; dx:cx-interger part of bsquare
	mov	dx, FEDB_Local.FEDB_bsquareHigh
	clr	bx		; bx - fraction part of bsquare
	shr	dx, 1		; divide dx by two
	rcr	cx, 1		; divide cx by two (carry pushed onto cx)
	rcr	bx, 1		; divide bx by two (carry pushed onto bx)
	shr	dx, 1		; divide dx by four
	rcr	cx, 1		; divide cx by four (carry pushed onto cx)
	rcr	bx, 1		; divide bx by four (carry pushed onto bx)
	mov	FEDB_Local.FEDB_fmidFrac, bx	; save fraction part of fmid
				; dx:cx = bsquare * .25
	mov	ax, FEDB_Local.FEDB_xSlopeLow ; bx:ax = X slope = 2 * bsquare * a
	mov	bx, FEDB_Local.FEDB_xSlopeMid
	mov	di, FEDB_Local.FEDB_xSlopeHigh
	shr	di, 1		; divide bx by two
	rcr	bx, 1		; divide ax by two (carry pushed onto ax)
	rcr	ax, 1		; divide ax by two (carry pushed onto ax)
				; bx:ax = bsquare * a
	sub	cx, ax		; dx:cx = bsquare * (.25 - a)
	sbb	dx, bx
	sbb	FEDB_Local.FEDB_fmidIntHigh, di
	add	cx, FEDB_Local.FEDB_asquareLow	; dx:cx=bsquare*(.25-a)+asquare
	adc	dx, FEDB_Local.FEDB_asquareHigh
	adc	FEDB_Local.FEDB_fmidIntHigh, 0
	mov	FEDB_Local.FEDB_fmidIntLow, cx	; save integer part of fmid 
	mov	FEDB_Local.FEDB_fmidIntMid, dx	; save integer part of fmid
	ret

GetFMid1	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoOctant1
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the points in octant1

CALLED BY:	GrEllipse

PASS:		ds:si - place to put deltas

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	while xslope > yslope do
		setpixel (x, y)
		y = y + 1
		yslope = yslope + a22
		if fmid < 0 then
			fmid = fmid + yslope + asquare
		else
			x = x - 1
			xslope = xslope - b22
			fmid = fmid - xslope + yslope + asquare
		endif
	endwhile

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DO1_50:
	retn

DoOctant1	proc	near
DO1_10:
	mov	ax, FEDB_Local.FEDB_xSlopeLow	; ax - X slope (low word)
	mov	bx, FEDB_Local.FEDB_xSlopeHigh	; bx - X slope (high word)
	mov	cx, FEDB_Local.FEDB_ySlopeLow	; cx - Y slope (low word)
	mov	dx, FEDB_Local.FEDB_ySlopeHigh	; dx - Y slope (high word)

	cmp	bx, dx 		; is X slope greater than Y slope? 
	jb	DO1_50		; if not, exit
	ja	DO1_28		; if it is, skip

	mov	bx, FEDB_Local.FEDB_xSlopeMid	; bx - X slope (middle word)
	mov	dx, FEDB_Local.FEDB_ySlopeMid	; dx - Y slope (middle word)

	cmp	bx, dx 		; is X slope greater than Y slope? 
	jb	DO1_50		; if not, exit
	ja	DO1_29		; if it is, skip

	cmp	ax, cx 		; is X slope greater than Y slope? 
	jbe	DO1_50		; if not, exit
DO1_28:
	mov	bx, FEDB_Local.FEDB_xSlopeMid	; bx - X slope (middle word)
	mov	dx, FEDB_Local.FEDB_ySlopeMid	; dx - Y slope (middle word)
DO1_29:
	mov	cx, FEDB_Local.FEDB_x		; cx - current X value
	mov	dx, FEDB_Local.FEDB_y		; dx - current Y value
	mov	ds:[si], cx
	mov	ds:[si+2], dx			; write out the coordinate
	add	si, 4				; update the index
	dec	word ptr FEDB_Local.FEDB_y	; Y = Y + 1
	mov	ax, FEDB_Local.FEDB_ySlopeLow
	mov	bx, FEDB_Local.FEDB_ySlopeMid	; bx:ax = Y slope 
	add	ax, FEDB_Local.FEDB_a22Low
	adc	bx, FEDB_Local.FEDB_a22High	; Y slope = Y slope + a22
	adc	FEDB_Local.FEDB_ySlopeHigh, 0	; Y slope = Y slope + a22
	mov	FEDB_Local.FEDB_ySlopeLow, ax
	mov	FEDB_Local.FEDB_ySlopeMid, bx	; store new Y slope

	mov	cx, FEDB_Local.FEDB_fmidIntLow
	mov	di, FEDB_Local.FEDB_fmidIntHigh	; di:cx - integer part of fmid
	tst	di				; is fmid less than zero?	
	jns	DO1_30				; if not, skip
	mov	di, FEDB_Local.FEDB_fmidIntMid	; di:cx - integer part of fmid
	add	cx, ax
	adc	di, bx				; di:cx = fmid + Y slope
	mov	ax, FEDB_Local.FEDB_ySlopeHigh	; store new Y slope
	adc	FEDB_Local.FEDB_fmidIntHigh, ax
	add	cx, FEDB_Local.FEDB_asquareLow
	adc	di, FEDB_Local.FEDB_asquareHigh	; di:cx=fmid+Yslope+asquare 
	adc	FEDB_Local.FEDB_fmidIntHigh, 0
	mov	FEDB_Local.FEDB_fmidIntLow, cx
	mov	FEDB_Local.FEDB_fmidIntMid, di	; save new fmid
	jmp	DO1_10		; continue ...
DO1_30:
	mov	di, FEDB_Local.FEDB_fmidIntMid	; di:cx - integer part of fmid
	dec	word ptr FEDB_Local.FEDB_x 	; X = X - 1
	mov	ax, FEDB_Local.FEDB_xSlopeLow
	mov	bx, FEDB_Local.FEDB_xSlopeMid	; bx:ax - X slope
	sub	ax, FEDB_Local.FEDB_b22Low
	sbb	bx, FEDB_Local.FEDB_b22High	; X slope = X slope - b22
	sbb	FEDB_Local.FEDB_xSlopeHigh, 0
	mov	FEDB_Local.FEDB_xSlopeLow, ax
	mov	FEDB_Local.FEDB_xSlopeMid, bx	; save new X slope
	sub	cx, ax		; di:cx = fmid - X slope
	sbb	di, bx
	mov	ax, FEDB_Local.FEDB_xSlopeHigh	; save new X slope
	sbb	FEDB_Local.FEDB_fmidIntHigh, ax
	add	cx, FEDB_Local.FEDB_ySlopeLow	; di:cx=fmid-X slope+Y slope
	adc	di, FEDB_Local.FEDB_ySlopeMid
	mov	ax, FEDB_Local.FEDB_ySlopeHigh	; save new X slope
	adc	FEDB_Local.FEDB_fmidIntHigh, ax
	add	cx, FEDB_Local.FEDB_asquareLow  ; di:cx=fmid-Xslope+Yslope+asqaure
	adc	di, FEDB_Local.FEDB_asquareHigh
	adc	FEDB_Local.FEDB_fmidIntHigh, 0
	mov	FEDB_Local.FEDB_fmidIntLow, cx	; save new fmid
	mov	FEDB_Local.FEDB_fmidIntMid, di
	jmp	DO1_10		; continue ...

DoOctant1	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetFMid2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculates fmid for octant2

CALLED BY:	GrEllipse

PASS:		nothing
	
RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	fmid = fmid - (yslope + xslope)/2 + .75 * (b22 - a22)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetFMid2	proc	near
	mov	ax, FEDB_Local.FEDB_xSlopeLow
	mov	bx, FEDB_Local.FEDB_xSlopeMid	; bx:ax - current X slope 
	mov	cx, FEDB_Local.FEDB_ySlopeLow
	mov	dx, FEDB_Local.FEDB_ySlopeMid	; dx:cx - current Y slope 

	add	ax, cx		; bx:ax = X slope + Y slope
	adc	bx, dx

	mov	cx, FEDB_Local.FEDB_xSlopeHigh
	mov	dx, FEDB_Local.FEDB_ySlopeHigh	; dx:cx - current Y slope 
	adc	cx, dx

	clr	dx		; assume no fraction part
	shr	cx, 1	
	rcr	bx, 1
	rcr	ax, 1
	rcr	dx, 1		; cx:bx:ax = (Y slope + X slope)/2

	sub	FEDB_Local.FEDB_fmidFrac, dx	; subtract the fraction part

	mov	dx, cx				; dx - high byte 
	mov	cx, FEDB_Local.FEDB_fmidIntLow
	mov	di, FEDB_Local.FEDB_fmidIntMid	; di:cx = integer part of fmid

	sbb	cx, ax		; subtract the integer part
	sbb	di, bx		; di:cx = fimd - (Y slope + X slope)/2
	sbb	FEDB_Local.FEDB_fmidIntHigh, dx

	mov	ax, FEDB_Local.FEDB_b22Low
	mov	bx, FEDB_Local.FEDB_a22Low
	sub	ax, bx	
	mov	bx, FEDB_Local.FEDB_b22High
	mov	dx, FEDB_Local.FEDB_a22High
	sbb	bx, dx		; bx:ax = b22 - a22
	push	bx
	push	ax
	sal	ax, 1		; keep the sign bit
	rcl	bx, 1		; bx:ax = 2 * (b22 - a22)
	pop	dx
	add	ax, dx
	pop	dx
	adc	bx, dx		; bx:ax = 3 * (b22 - a22)
	clr	dx

	sar	bx, 1		; keep the sign bit
	rcr	ax, 1
	rcr	dx, 1		; bx:ax:dx = 3/2 * (b22 - a22)

	sar	bx, 1		; keep the sign bit
	rcr	ax, 1		
	rcr	dx, 1		; bx:ax:dx = .75 * (b22 - a22)

	add	FEDB_Local.FEDB_fmidFrac, dx	; add the fraction part
	adc	cx, ax		; add the integer part
	adc	di, bx		; di:cx = fmid-(yslope+xslope)/2+.75*(b22-a22) 
	pushf			; save the flags
	tst	bx		; is bx negative?
	jns	GFM2_80		; if not, skip
	popf			; negative, restore the flags
	adc	FEDB_Local.FEDB_fmidIntHigh, -1	; sign extend the word
GFM2_90:
	mov	FEDB_Local.FEDB_fmidIntLow, cx	
	mov	FEDB_Local.FEDB_fmidIntMid, di	; save new fmid
	ret

GFM2_80:
	popf					; restore the flags
	adc	FEDB_Local.FEDB_fmidIntHigh, 0	; positive, sign extend the word
	jmp	GFM2_90

GetFMid2	endp	
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoOctant2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the points in octant2

CALLED BY:	GrEllipse	

PASS:		ds:si - place to put deltas

RETURN:		si - offset past last delta

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	repeat
		setpixel (x, y)
		x = x -1
		xslope = xslope - b22
		if fmid > 0 then
			fmid = fmid - xslope + bsquare
		else
			y = y + 1
			yslope = yslope + a22
			fmid = fmid - xslope + yslope + bsquare
		endif
	until x < 0

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoOctant2	proc	near
DO2_10:
	mov	ax, FEDB_Local.FEDB_xSlopeLow	
	mov	bx, FEDB_Local.FEDB_xSlopeMid	; bx:ax - X slope 
	mov	cx, FEDB_Local.FEDB_x
	mov	dx, FEDB_Local.FEDB_y	; dx:cx - Y value

	mov	ds:[si], cx
	mov	ds:[si+2], dx	; write out the coordinate
	add	si, 4		; update the index
	dec	word ptr FEDB_Local.FEDB_x	; X = X -1
	sub	ax, FEDB_Local.FEDB_b22Low	
	sbb	bx, FEDB_Local.FEDB_b22High	; X slope = X slope - b22
	sbb	FEDB_Local.FEDB_xSlopeHigh, 0
	mov	FEDB_Local.FEDB_xSlopeLow, ax
	mov	FEDB_Local.FEDB_xSlopeMid, bx	; save new X slope
	mov	cx, FEDB_Local.FEDB_fmidIntLow	
	mov	di, FEDB_Local.FEDB_fmidIntHigh	; di:cx - integer part of fmid
	tst	di		; is fmid positive?
	js	DO2_20		; if not, skip
	mov	di, FEDB_Local.FEDB_fmidIntMid	; di:cx - integer part of fmid
	sub	cx, ax		; di:cx = fmid - X slope
	sbb	di, bx
	mov	ax, FEDB_Local.FEDB_xSlopeHigh
	sbb	FEDB_Local.FEDB_fmidIntHigh, ax	; di:cx - integer part of fmid
	add	cx, FEDB_Local.FEDB_bsquareLow	; di:cx=fmid-X slope+bsquare
	adc	di, FEDB_Local.FEDB_bsquareHigh
	adc	FEDB_Local.FEDB_fmidIntHigh, 0	; di:cx - integer part of fmid
	jmp	DO2_30
DO2_15:
	jmp	DO2_10
DO2_20:
	mov	di, FEDB_Local.FEDB_fmidIntMid	; di:cx - integer part of fmid
	mov	ax, FEDB_Local.FEDB_ySlopeLow
	mov	bx, FEDB_Local.FEDB_ySlopeMid	; bx:ax - Y slope 
	dec	word ptr FEDB_Local.FEDB_y	; Y = Y + 1
	add	ax, FEDB_Local.FEDB_a22Low	; Y slope = Y slope + a22
	adc	bx, FEDB_Local.FEDB_a22High
	adc	FEDB_Local.FEDB_ySlopeHigh, 0
	mov	FEDB_Local.FEDB_ySlopeLow, ax	; save new Y slope
	mov	FEDB_Local.FEDB_ySlopeMid, bx
	sub	cx, FEDB_Local.FEDB_xSlopeLow	; di:cx = fmid - X slope
	sbb	di, FEDB_Local.FEDB_xSlopeMid
	mov	dx, FEDB_Local.FEDB_xSlopeHigh
	sbb	FEDB_Local.FEDB_fmidIntHigh, dx	; di:cx - integer part of fmid
	add	cx, ax		; di:cx = fmid - X slope + Y slope
	adc	di, bx
	mov	dx, FEDB_Local.FEDB_ySlopeHigh
	adc	FEDB_Local.FEDB_fmidIntHigh, dx	; di:cx - integer part of fmid
	add	cx, FEDB_Local.FEDB_bsquareLow ; di:cx=fmid-Xslope+Yslope+bsqaure
	adc	di, FEDB_Local.FEDB_bsquareHigh
	adc	FEDB_Local.FEDB_fmidIntHigh, 0	; di:cx - integer part of fmid
DO2_30:
	mov	FEDB_Local.FEDB_fmidIntLow, cx
	mov	FEDB_Local.FEDB_fmidIntMid, di	; save new fmid
	cmp	word ptr FEDB_Local.FEDB_x, 0	; is current X value negative?
	jge	DO2_15		; if not, skip
	ret			; if so, exit
DoOctant2	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ConvertDeltasToPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert Ellipse Delta Block to a buffer of points

CALLED BY:	INTERNAL
		DrawArcLow
		FillArcLow
		
PASS:		ds - segment of ellipse delta block
		ds:EDB_numDeltas
		ds:EDB_deltaX
		ds:EDB_deltaY
		ds:EDB_doNotCombine
		si - starting angle
		dx - ending angle
		ax - x of ellipse center
		cx - y of ellipse center
		bx - number of bytes left in points buffer
		es - segment of points buffer
		di - offset to store points at
RETURN:		
		clc - means pts fit in buffer
		di - offset past last point in point buffer


		stc - means pts won`t fit in buffer
		di - unchanged
		bx - unchanged
		ax - holds size needed

DESTROYED:	
		ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
	convert starting and ending angle into offsets to deltas
	loop
		get delta (start with starting angle offset)
		add center to delta
		store in point buffer
	combine points

	The loop is acutally a bit more complex. Because the ending angle
	may be smaller than the starting angle, the loop may stop at the
	end of the delta block, have to go back to the front and then continue
	until it reaches the ending offset.

	For speeds sake, we wish to only have one ending condition for the
	loop and keep it in a register. So before the loop, I set two 
	variables: dx - first offset to stop at, and CDTP_finalStop - the
	final offset to stop at or -1 if the first stop in all I need.
	 The loop runs until it hits dx, it then it checks finalStop.
	If finalStop is -1 then we're done, otherwise dx is set to finalStop, 
	finalStop is set to -1 and the loop continues.

	Further trouble errupts if the starting angle offset is equal to
	the ending angle offsets, because the original angles may not be equal.
	If the angles are equal, or the ending angle is less than the
	starting angle, then we wish to draw a complete ellipse. If,
	however, the ending angle is greater than the starting angle, we
	only wish to draw a tiny sliver. See STRATEGY of CalcOffset for
	other info.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CDTP_StackFrame	struct
	CDTP_finalStop	dw	?		;offset to stop conversion at
	CDTP_endOfDeltas	dw	?	;offset past last delta
	CDTP_normalizedStartAngle	dw	?;name is clear
	CDTP_normalizedEndAngle		dw	?;name is clear	
	CDTP_destOffset	dw	?		;offset to put points at
	CDTP_numBytesInPtBuffer	dw	?	;bytes avail in pts buffer
CDTP_StackFrame	ends
CDTP_Local	equ	<[bp-(size CDTP_StackFrame)]>

CDTP___10:	;START OFFSET = ENDING OFFSET

		;MAY ONLY BE ONE POINT
	cmp	ds:EDB_numDeltas,1
	je	CDTP___20			;jmp to store one point twice

	mov	di,CDTP_Local.CDTP_normalizedStartAngle
	cmp	di,CDTP_Local.CDTP_normalizedEndAngle
	jl	CDTP___20			;jmp to draw sliver arc

		;WILL HAVE TO SKIP FROM END OF BUFFER TO BEGINING
		;bx = offset to end of buffer
		;dx = offset to ending angle delta
CDTP___15:
	xchg	dx,bx				;first stop at end of delta buf
	add	bx,4				;final stop after converting
						;ending delta
						
	jmp	short CDTP_10

CDTP___20:	;SLIVER ARC - store one point twice 
	cmp	CDTP_Local.CDTP_numBytesInPtBuffer,8
	jb	CDTP___25			;jmp if not room for sliver
	mov	di,CDTP_Local.CDTP_destOffset	;offset to store at
	mov	bx,ax				;x of center
	lodsw					;get x
	add	bx,ax				;convert to point in bx
	lodsw					;get y
	add	cx,ax				;convert to point in cx
	mov	ax,bx				;store point twice
	stosw
	mov	ax,cx
	stosw
	mov	ax,bx
	stosw
	mov	ax,cx
	stosw
	jmp	short 	CDTP_30

CDTP___25:
	jmp	CDTP_100

ConvertDeltasToPoints		proc	far
EC < 	call	ECMemVerifyHeapHighECEllipse		>
	push	bp
	mov	bp,sp
	sub	sp,size CDTP_StackFrame
	mov	CDTP_Local.CDTP_numBytesInPtBuffer,bx
	mov	CDTP_Local.CDTP_destOffset,di
	mov	di,si				;save starting angle
	call	CalcOffset			;convert end angle to offset 
	mov	CDTP_Local.CDTP_normalizedEndAngle,si	
	xchg	di,dx				;di-end offset,dx-start angle
	call	CalcOffset			;convert starting angle
	mov	CDTP_Local.CDTP_normalizedStartAngle,si	
	mov	si,dx				;offset to starting delta
	mov	dx,di				;offset to ending delta
	mov	bx,ds:EDB_numDeltas
	shl	bx,1
	shl	bx,1				
	add	bx,EDB_startDeltas		;offset to end of buffer
	mov	CDTP_Local.CDTP_endOfDeltas,bx

	;SET LOOP STOP CONDITIONS
		;we have
		;bx - offset to end of deltas, dx - offset to end angle delta
		;
		;we want to get
		;dx - first offset stop, bx - final offset stop or -1

	cmp	si,dx				;start offset to end offset
	je	CDTP___10			;jmp if offsets equal
	jg	CDTP___15			;jmp if starting larger

		;START OFFSET < END OFFSET
	add	dx,4				;stop after converting
						;ending delta
	mov	bx,-1				;no final stop
CDTP_10	label	near
		;WILL ALL POINTS FIT IN POINTS BUFFER
	clr	di				;init count of bytes needed
	cmp	bx,-1				;
	je	CDTP_12				;jmp if no final stop
	mov	di,bx				;bytes between start delta
	sub	di,EDB_startDeltas		;and finalStop
CDTP_12:
	add	di,dx				;add to total
	sub	di,si				;(first stop) - (start offset)
	cmp	di,CDTP_Local.CDTP_numBytesInPtBuffer
	ja	CDTP_110			;jmp if points won't fit

	mov	CDTP_Local.CDTP_finalStop,bx	;save final stop

	mov	bx,ax				;x of ellipse center
	mov	di,CDTP_Local.CDTP_destOffset	;offset to store at

CDTP_20:	;COVERT TO POINTS LOOP
	lodsw					;get delta x
	add	ax,bx				;convert to point
	stosw
	lodsw					;get delta y
	add	ax,cx				;convert to point
	stosw
	cmp	si,dx				;cmp with stopping offset
	jne	CDTP_20				;jmp if haven't reached
	cmp	CDTP_Local.CDTP_finalStop, -1
	je	CDTP_30				;jmp if no finalStop
	mov	dx,CDTP_Local.CDTP_finalStop	;set to stop at final stop
	mov	si,EDB_startDeltas		;continue from begining
	mov	CDTP_Local.CDTP_finalStop, -1	;no more finalStop
	jmp	short CDTP_20			;continue converting
CDTP_30	label	near
	mov	si,CDTP_Local.CDTP_destOffset	;offset to points to combine
	call	CombinePoints
	mov	sp,bp
	pop	bp
EC < 	call	ECMemVerifyHeapHighECEllipse		>

	clc					;pts fit
	ret
CDTP_100 label near	;SLIVER WON`T FIT IN PTS BUFFER
	mov	di,8				;eight bytes needed for sliver
CDTP_110:		;PTS WON'T FIT IN PTS BUFFER
	mov	ax,di				;return num bytes needed
	mov	di,CDTP_Local.CDTP_destOffset	;return di unchanged
	mov	bx,CDTP_Local.CDTP_numBytesInPtBuffer
	mov	sp,bp
	pop	bp
	stc
	ret

ConvertDeltasToPoints		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CombinePoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Combine points in ellipse into horizontal, vertical and
		diagonal lines

CALLED BY:	INTERNAL
		ConvertDeltasToPoints

PASS:		es - segment of points
		si - offset to begining of points
		di - offset past last point
		ds - segment of ellispse delta block
RETURN:		
		di - offset past last point
DESTROYED:	
		ax,bx,cx,dx,si

PSEUDO CODE/STRATEGY:
		This routine is basically comprised of 6 loops. Each of
		this loops reads successive points until a point does not
		match the pattern the loop corresponds to. The point before
		the deviate is written out. This point is a transistion 
		point because it ends one pattern and starts the next.
		The 6 loops are for the patterns (sections)
			Horizontal
			Vertical
			Diagonal - up and left


			Diagonal - up and right
			Diagonal - down and left
			Diagonal - down and right
				
		Even though there are really two directions of horizontal
		and vertical lines, only with ellipses one pixel high or
		one pixel wide will the points switch direction 180 degress.
		These thin,narrow ellipses have the doNotCombine flag set in
		their ellipseSizeInfo. However, 90 degree swings from
		one diagonal line to another occur in many ellipse that are
		long and thin or tall and narrow so there are separate loops
		for each type of diagonal.

		Remember that for any two successive points in the buffer,
		either x must change or y must change or both, but never 
		neither. Also, any change will always be by 1.

	Register Usage:
		bp - offset to stop at
		cx,dx - x,y of last point of current pattern
		bx,ax - x,y of new point
		si - place to read from
		di - place to store to	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	must always be at least two points in vertex buffer

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/18/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CB___10:
	retn

CombinePoints		proc	near
	tst	ds:EDB_doNotCombine
	jnz	CB___10
	push	bp,ds		;don't destroy
	mov	ax,es		;make ds also seg of points
	mov	ds,ax
	mov	bp,di		;offset to stop at
	mov	di,si		;start storing after first point
	add	di,4
	lodsw			;get first x
	mov	cx,ax
	lodsw			;get first y
	mov	dx,ax

		;EXAMINE SECOND PT TO FORM PATTERN
	lodsw			;get x
	mov	bx,ax		;save x of new point
	cmp	ax,cx		;cmp with old x
	je	CB_200		;jmp if vertical, no change in x
	lodsw			;get new y
	cmp	ax,dx		;cmp with old y
	je	CB_100		;jmp if horizontal, no change in y
	jmp	CB_20		;jmp to diagonal

CB_100:		;HORIZONTAL SECTION
		;ax - y of horizontal 
	mov	dx,ax		;save y of horizontal
CB_110:
	cmp	si,bp		;reached final offset?
	je	CB_400		;jmp if done. Have y of final in ax
	add	si,2		;skip over x to new y
	lodsw			;get new y
	cmp	ax,dx		;cmp with y of horizontal
	je	CB_110		;jmp if still horiz

	mov	bx,ax		;save new y
	sub	si,8		;pt to last x of horizontal
	lodsw			;get last  x of horizontal
	mov	cx,ax		;last x of horizontal
	add 	si,2		;pt to new x
	lodsw			;get new x
	add	si,2		;pt past new point	
	xchg	ax,bx		;bx - new x, ax - new y
	jmp	short	CB_310	;jmp to end horizontal

CB_200:		;VERTICAL SECTION
		;bx - x of vertical
	mov	cx,bx		;save x of vertical
CB_210:
	add	si,2		;skip over y to get new x
	cmp	si,bp		;reached final offset?
	je	CB_410		;jmp if done. Have final x in ax
	lodsw			;get new x
	cmp	ax,cx		;cmp with x of vertical
	je	CB_210		;jmp if still vertical
	mov	bx,ax		;new x
	sub	si,4		;pt to last y of vertical
	lodsw			;get last y of pattern
	mov	dx,ax		;save last y of pattern
	add	si,2		;pt to new y

CB_300:		;END OF SECTION NO Y
	lodsw			;get second y

		;cx,dx - transition
		;bx,ax - second of new section
CB_310:		;END OF SECTION
	xchg	ax,bx		;ax - second x, bx - second y
	xchg	ax,cx		;ax - transition  x, cx - second x
		;STORE TRANSITION
	stosw
	xchg	ax,dx		;ax - transition y, dx - transition x
	stosw

	xchg	ax,cx		;ax - second x, cx - transition y
	xchg	cx,dx		;cx - transition x, dx - transition y
	xchg	ax,bx		;ax - second y, bx - second x
	cmp	si,bp
	je	CB_450		;jmp if second point is final point
	sub	si,2		;pretend read second x
	cmp	bx,cx		
	je	CB_200		;jmp if vertical
	add 	si,2		;pretend read second y
	cmp	ax,dx
	je	CB_100		;jmp if horizontal
	jmp	CB_20

CB_400:		;GET FINAL X
	mov	bx,ax		;final y
	sub	si,4
	lodsw			;get final x
	jmp	short CB_460

CB_410:		;GET FINAL Y
	mov	bx,ax		;final x
	sub	si,2
	lodsw			;get final y
CB_450:		;STORE FINAL POINT
	xchg	ax,bx		;ax - final x, bx -  final y
CB_460:
	stosw
	mov	ax,bx
	stosw
	pop	bp,ds
	ret

CB_20:		;DIAGONAL SECTION
	
	cmp	bx,cx		;new x to old x
	jl	CB_50		;jmp if going to left

		;GOING RIGHT
	cmp	ax,dx		;new y to old y
	jl	CB_40		;jmp if going up

		;DIAGONAL - DOWN AND RIGHT
CB_30:
	mov	cx,bx		;cx,dx prev point of diagonal
	mov	dx,ax		
	cmp	si,bp
	je	CB_450		;jmp if already read final
	lodsw			;get new x
	mov	bx,ax		;save new x
	cmp	ax,cx		;cmp with prev x of diagonal
	jle	CB_300		;jmp to end diagonal
	lodsw			;get new y
	cmp	ax,dx		;cmp with prev y of diagonal
	jg	CB_30		;continue with diagonal
	jmp	CB_310		;jmp, it's end diagonal

		;DIAGONAL - UP AND RIGHT
CB_40:
	mov	cx,bx		;cx,dx prev point of diagonal
	mov	dx,ax		
	cmp	si,bp		;reached final offset?
	je	CB_450		;jmp if already read final
	lodsw			;get new x
	mov	bx,ax		;save new x
	cmp	ax,cx		;cmp with prev x of diagonal
	jle	CB_300		;jmp to end diagonal
	lodsw			;get new y
	cmp	ax,dx		;cmp with prev y of diagonal
	jl	CB_40		;continue with diagonal
	jmp	CB_310		;jmp, it's end diagonal

CB_50:		;GOING LEFT
	cmp	ax,dx		;cmp new y to old y
	jl	CB_70		;jmp if going up

		;DIAGONAL - DOWN AND LEFT
CB_60:
	mov	cx,bx		;cx,dx prev point in diagonal
	mov	dx,ax		
	cmp	si,bp
	je	CB_450		;jmp if already read final
	lodsw			;get new x
	mov	bx,ax		;save new x
	cmp	ax,cx		;cmp with prev x of diagonal
	jge	CB_300		;jmp to end diagonal
	lodsw			;get new y
	cmp	ax,dx		;cmp with prev y of diagonal
	jg	CB_60		;continue with diagonal
	jmp	CB_310		;jmp, it's end diagonal

		;DIAGONAL - UP AND LEFT
CB_70:
	mov	cx,bx		;cx,dx prev point in diagonal
	mov	dx,ax		
	cmp	si,bp
	je	CB_450		;jmp if already read final
	lodsw			;get new x
	mov	bx,ax		;save new x
	cmp	ax,cx		;cmp with prev x of diagonal
	jge	CB_75		;jmp to end diagonal
	lodsw			;get new y
	cmp	ax,dx		;cmp with prev y of diagonal
	jl	CB_70		;continue with diagonal
	jmp	CB_310		;jmp, if it's end diagonal
CB_75:
	jmp	CB_300



CombinePoints		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts an angle into an offset to a delta in the ellipse
		delta block

CALLED BY:	INTERNAL
		ConvertDeltasToPoints

PASS:		dx - angle 
		si - total number of deltas in buffer
		bl - ellipseSizeInfoRec
		ds - segment of ellipse delta block (EDB)
		ds:EDB_deltaX
		ds:EDB_deltaY
		ds:EDB_numDeltas
		
RETURN:		dx - offset into buffer
		si - normalized angle
DESTROYED:	
		nothin

PSEUDO CODE/STRATEGY:
	normalize angle	
	percent of cirle = (normalized angle/360)
	delta number = percent of circle * number of deltas
	offset = (delta number * 4) + offset to start of deltas

	But things are not so easy. If you read the Overview section you
	know that I treat ellipses with even dimensions as the next
	smallest ellipses with odd dimensions. So in this routine I
	subtract two deltas from the total number of deltas if the
	height is even and two if the width is even. This gives me the
	number of deltas in my ideal odd, odd ellipse. But I must still
	compensate for those "extra" deltas. I do this by adding
	to the angles delta number for each of these "extra" deltas that come
	before my angle in the delta buffer. These extra deltas can exist
	at 0,90,180 and 270 degrees. In the code, by all the comments with
	compensate in them is where all this is done. You should notice that
	in some cases I use > and others >= this makes sure that the 
	quarter pies have straight sides.

	This may all seem a bit weird, but it does work pretty well.

	Also, the calculation for delta number above may return a value equal 
	to the total number of deltas. The offset for this delta number would
	point past the last delta in the buffer. It actually should refer to 
	the first delta. So the delta number is set to zero. At this time
	I also subtract 360 from the normalized angle. This makes the 
	normalized angle negative, which sort of violates the definition.
	But, it provides a numerical continuity on both sides of 0 degrees.
	This is needed in ConvertDeltasToPoints to determine whether to draw
	a whole ellipse or just a sliver. See the STRATEGY section of
	ConvertDeltasToPoints for more info.

	See Overview section for my reasoning and potential problems with it.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/89		Initial version
	srs	9/89		Major Changes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CO___10:	;ANGLE IS LESS THAN 0
	add	dx,360
	jmp	short CO_10

CO___20:	;ANGLE IS GREATER THAN 360
	sub	dx, 360		;		

CalcOffset	proc	near
		;NORMALIZE ANGLE
	cmp	dx, 360		; 
	jge	CO___20		; jmp if angle >= 360
CO_10	label	near
	tst	dx
	jl	CO___10		;jmp if angle < 0

	push	ax,cx		;don't destroy
	push	dx		;save orig angle modulo 360
	tst	dx
	je	CO_35		;jmp if angle = 0 to skip calc
	mov	bx, 360		; bx:ax - 360
	clr	cx		; dx:cx - given angle
	clr	ax
	call	GrUDivWWFixed	;divide the angle by 360
	mov	ax,ds:EDB_numDeltas	;number of deltas in buffer
	test	ds:EDB_deltaY,0001h
	jz	CO_25			;jmp if height is odd
	sub	ax,2			;remove "extra" deltas from total
CO_25:
	test	ds:EDB_deltaX,0001h
	jz	CO_30			;jmp if width is odd
	sub	ax,2			;remove "extra" deltas from total
CO_30:
	mul	cx		;multiply it by percent
	rcl	ax, 1		;round up the fraction part if necessary
	adc	dx, 0		;add it to the integer part
CO_35:
	pop	ax		;recover orig angle
	test	ds:EDB_deltaY,0001h
	jnz	CO_100			;jmp if even height to compensate
CO_40:
	test	ds:EDB_deltaX,0001h
	jnz	CO_110			;jmp if even width to compensate
CO_50:
	cmp	dx,ds:EDB_numDeltas	;compare num to total
	jl	CO_60
	clr	dx			;go back to first point
	sub	ax,360			;normalized angle
CO_60:
	shl	dx,1			;convert number to offset
	shl	dx,1
	add	dx,EDB_startDeltas
	mov	si,ax			;return normalized angle
	pop	ax,cx
	ret

CO_100:		;EVEN HEIGHT
	cmp	ax,180
	jl	CO_105		
	inc	dx			;if angle >=180 then compensate
CO_105:
	tst	ax
	je	CO_40
	inc	dx			;in angle > 0 then compensate
	jmp	short	CO_40

CO_110:		;EVEN WIDTH
	cmp	ax,270
	jl	CO_115
	inc	dx			;if angle >=270 then compensate
CO_115:
	cmp	ax,90
	jle	CO_50
	inc	dx			;if angle > 90 then compensate

	jmp	short CO_50
CalcOffset	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate a region definition buffer

CALLED BY:	GrEllipse

PASS:		ax	- x1 (left)
		bx	- y1 (top)
		cx	- x2 (right)
		dx	- y2 (bottom)

RETURN:		es - segment of newly allocated block
		bp - handle of newly allocated block

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Size of buffer = (total height + 1) * 8 + 24 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Use Local Memory Manager

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRBuffer	proc	near
	push	ax, bx, cx, dx
	sub	dx, bx		; get total height of ellipse
	inc	dx
	cmp	dx, 01ffdh	; is the buffer too big?
	jg	GRB_ret		; exit if so
	shl	dx, 1
	shl	dx, 1		; multiply it by 8 because you need 
	shl	dx, 1		; 8 bytes for each scan line
	add	dx, 24		; add twenty for just in case
	mov	ax, dx		; ax - number of bytes need to be allocated
	mov	cx, ALLOC_DYNAMIC_NO_ERR
	call	MemAllocFar	; allocate a memory block for points on ellipse
	mov	es, ax		; return seg. of block in es
	mov	bp, bx		; return the handle of block in bp
	DoPop	dx, cx, bx, ax
	ret

GRB_ret:
	ERROR	GRAPHICS_BAD_REGION_DEF
	ret

GetRBuffer	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitRBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the region definition buffer

CALLED BY:	GrEllipse

PASS:		es - seg. to region definition buffer
		ax	- x1 (left)
		bx	- y1 (top)
		cx	- x2 (right)
		dx	- y2 (bottom)

RETURN:		nothing

DESTROYED:	di

PSEUDO CODE/STRATEGY:
	Write out the bounding box of ellipse to the definition buffer

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitRBuffer	proc	near
	push	ax
	clr	di		; di - index through buffer
	stosw			; store X1 in region def. buffer 
	mov	ax, bx
	stosw			; store Y1 in region def. buffer
	mov	ax, cx
	stosw			; store X2 in region def. buffer
	mov	ax, dx
	stosw			; store Y2 in region def. buffer
	dec	bx
	mov	ax, bx		; don't draw anything upto Y1-1
	stosw
	mov	ax, EOREGREC	; end of region def. constant
	stosw
	inc	bx		; restore Y1
	pop	ax		; restore X1
	ret
InitRBuffer	endp
endif


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoSpecialCases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Need to do some more work if the width of the ellipse
		is 3 or 4. 

CALLED BY:	FillEDB	

PASS:		ds:[si] - end of ellipse point buffer		

RETURN:		more points added to ellipse buffer

DESTROYED:	ax, bx, cx	

PSEUDO CODE/STRATEGY:
	Problem lies in that the heights of ellipses generated are shorter
	that the actual ellipses. 
	To solve this problem, just add x, y coordinate pair until
	y coordinate is exactly half of the total height.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	This ellipse algorithm does not work for ellipses
	that are 3 or 4 pixel wide.

???	fix for negative y stuff

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoSpecialCases	proc	near
	mov	cx, FEDB_Local.FEDB_right	; cx - right 
	sub	cx, FEDB_Local.FEDB_left	; cx - width
	cmp	cx, 4			; is width 3 or 4?
	jle	DSC_10			; skip to handle it if so
DSC_5:
	ret				; otherwise, exit
DSC_10:
	mov	bx, FEDB_Local.FEDB_y	; bx - the most current y coordinate
	mov	cx, FEDB_Local.FEDB_halfDeltaY	; cx - height/2
DSC_20:
	cmp	bx, cx 			; are we done yet? 
	jl	DSC_30			; if not, get another x, y pair
	mov	FEDB_Local.FEDB_y, bx	; if so, update y coordinate value
	jmp	DSC_5			; and exit
DSC_30:
	mov	ax, ds:[si-4]		; ax - previous x value
	mov	ds:[si], ax		; x coordinate stays the same
	mov	ds:[si+2], bx		; write out the y coordinate value
	add	si, 4			; update the pointer
	inc	bx			; update current y coordinate value
	jmp	DSC_20			; check to see if we are done

DoSpecialCases	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenTopRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate region definition for top half of an ellipse

CALLED BY:	GrEllipse

PASS:		es - seg. to region definition buffer
		ds - seg. to points of ellipse (1st quadrant)
		ds:[si] - points to end of buffer 

RETURN:		di - points to region defintion buffer 

DESTROYED:	ax, bx, cx, dx, bp

PSEUDO CODE/STRATEGY:
	Calculate x offset 
	Get initial y value
	Write out to reg. def. buffer
	For each scan line
		get the x value
		add the x offset
		write out to buffer
		mirror x value about y axis
		add the x offset 
		write out to buffer
	Get the next scan line

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version
	Ted	5/30/89		Takes care of odd or even heights

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenTopRegion	proc	near
	mov	dx, es:[4]		; 
	sub	dx, es:[0]		; dx = right - left
	shr	dx, 1			; divide it by two
	add	dx, es:[0]		; add the offset to it
	mov	di, OFFSET_REG_BUFFER	; di - index though region buffer
	mov	bx, es:[2]		; bx - top
GTR_10:
	mov	bp, 0			; set the flag
	tst	si
	je	GTR_15
	mov	cx, ds:[si-2]		; get the Y coordinate
GTR_15:
	mov	es:[di], bx		; write out to buffer
	add	di, 2
GTR_20:					; si - points to the end of reg. buffer
	tst	si
	je	GTR_30
	cmp	cx, ds:[si-2]		; was there a scan line change?
	jne	GTR_30			; if so, skip
	sub	si, 4			; if not, point to the previous Y coord.
	jmp	GTR_20
GTR_30:
	mov	ax, ds:[si]		; get X coordinate
	neg	ax			; mirror it against Y axis
	add	ax, dx			; add the offset to get document coord.
	cmp	di, OFFSET_REG_BUFFER+2	; is this reg def for the 1st scan line?
	je	GTR_40			; if so, skip
	cmp	ax, es:[di-8]		; current X coord same as prev X coord?
	je	GTR_40			; if so, skip
	mov	bp, -1			; if not, set the flag
GTR_40:
	stosw				; write to reg. buffer
	mov	ax, ds:[si]		; get X coordinate again
	push	dx
	mov	dx, es:[4]		; 
	sub	dx, es:[0]		; dx = right - left
	shr	dx, 1			; divide it by two
	jnc	GTR_45			; skip if even number
	inc	dx			; add one if odd number
GTR_45:
	add	dx, es:[0]		; add the offset to it
	add	ax, dx			; this time don't mirror it
	pop	dx
	cmp	di, OFFSET_REG_BUFFER+4	; is this reg def for the 1st scan line?
	je	GTR_50			; if so, skip			
	cmp	ax, es:[di-8]		; current X coord same as prev X coord?
	je	GTR_50			; if so, skip
	mov	bp, -1			; if not, set the flag
GTR_50:
	stosw				; write to reg. buffer
	mov	ax, EOREGREC		; end of region def. constant
	stosw
	inc	bx			; update the scan line number
	tst	bp			; are reg. definitions different?
	jne	GTR_60			; if so, skip
	cmp	di, OFFSET_REG_BUFFER+8	; is this reg def for the 1st scan line?
	je	GTR_60			; if so, skip
	sub	di, 8			; if same, have di point to prev def
	inc	word ptr es:[di-8]	; increment the scan line number 
GTR_60:					; of the reg. def of previous line
	tst	si			; are we done yet? 
	jne	GTR_10			; handle the next scan line
GTR_ret:
	ret
GenTopRegion	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenBotRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generates region definition for bottom half of an ellipse 

CALLED BY:	GrEllipse

PASS:		es:[di] - pointer into region definition buffer

RETURN:		nothing

DESTROYED:	ax, bx, si

PSEUDO CODE/STRATEGY:
	Traverses the region definition for top half reversely
	For each scan line
		x coordinates stay the same
		write out to buffer
	Get the next scan line

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version
	Ted	5/30/89		Takes care of odd or even height cases

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenBotRegion	proc	near
	mov	si, di			; si points to the end of reg. buffer
	sub	si, 8
	cmp	si, OFFSET_REG_BUFFER	; are we done yet?
	je	GBR_20
	mov	ax, es:[si]		; if not, get y value of last reg. def
	sub	ax, es:[si-8]		; subtract y values of prev. two lines

	mov	dx, es:[6]		; 
	sub	dx, es:[2]		; dx = bottom - top
	shr	dx, 1			; get bit 1 of dx
	jc	GBR_5			; skip if it was an odd number
	dec	ax			; subtract one if even number
GBR_5:
	add	es:[si], ax		; add it to y value
	mov	bx, es:[si]		; if not, get the Y coordinate value
GBR_10:
	sub	si, 8			; have si point to previous scan line 
	mov	ax, es:[si]		; if not, get y value of last reg. def
	cmp	si, 12			; is this the last scan line?
	jne	GBR_15			; if not, skip
	sub	ax, es:[si-4]		; if so, y value is at different offset
	jmp	GBR_17
GBR_15:
	sub	ax, es:[si-8]		; subtract y values of prev. two lines
GBR_17:
	add	bx, ax			; add it to y value
	mov	es:[di], bx		; write out to the buffer
	add	di, 2
	mov	ax, es:[si+2]		; get the 1st X coordinate value
	stosw				; write out to the buffer
	mov	ax, es:[si+4]		; get the 2nd X coordinate value
	stosw				; write out to the buffer
	mov	ax, es:[si+6]		; get the end of scan line constant
	stosw				; write out to the buffer
	cmp	si, 12			; are we done yet?
	jne	GBR_10			; continue ...
GBR_20:
	mov	ax, EOREGREC		; end of region def. constant
	stosw
	ret
GenBotRegion	endp
endif

if	ERROR_CHECK

ECMemVerifyHeapHighECEllipse proc near
	pushf
	push	ax
	push	bx
	call	SysGetECLevel
	test	ax, mask ECF_GRAPHICS
	pop	bx
	pop	ax
	jz	10$		;jmp if less than a HIGH level of EC
	call	ECMemVerifyHeap
10$:
	popf
	ret
ECMemVerifyHeapHighECEllipse	endp

endif

GraphicsEllipse ends
endif
