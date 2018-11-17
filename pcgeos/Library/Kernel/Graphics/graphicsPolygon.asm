COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		KernelGraphics
FILE:		Graphics/graphicsPolygon.asm

AUTHOR:		Ted H. Kim, 4/13/89

ROUTINES:
	Name			Description
	----			-----------
  GBL	GrFillPolygon		Filled polygon drawing routine
  EXT	GrPolygonLow		Called after 'EnterGraphics'
  EXT	PolygonAfterTrans	external version of GrPolygonAfterTrans
  INT	GrPolygonAfterTrans	Called after transformation
  INT	TransCoord		Transform coordinates of polygon
  INT	GetBounds		Get bounding box of polygon
  INT	CheckTrivial		Check for trivial rejects
  INT   GetBuffer		Allocates memory for ET 
  INT   BuildET			Builds edge table
  INT	ShortenEdge		Determines if an edge needs to be shortened
  INT	InitBresError		Initializes Bresenham's error terms
  INT	PutRecordInET		Stores edge record in ET
  INT	MoveBuckets		Creates space to insert a new bucket
  INT	InsertEdgeRec		Inserts edge record in linked list
  INT	ScanLineCon		Does scan line conversion of polygon
  INT	GetRegBuffer		Allocates memory for region def. buffer
  INT	BuildAEL		Add edges to AEL from ET
  INT	SetWindingScanLineInfo	Sets scan line specific info in AEL
  INT	SetEvenOddScanLineInfo	Sets scan line specific info in AEL
  INT	GenRegDef		Generates region def. for current scan line
  INT	GetOnOff		Returns on,off pair from AEL for region def
  INT	DeleteAEL		Deletes some edge records
  INT	UpdateAEL		Updates the x values in Active Edge List
  INT	YRoutine		Y portion of bresenhams line algorithm
  INT	XRoutine		X portion of bresenhams line algorithm
  INT	ResortAEL		Resorts AEL on new X min values
  INT	DelBuffer		Delete coord and edge table block
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	4/89		Initial revision
	srs	8/89		major reworking
	jim	8/89		moved most of the support to kernel lib
	jim	1/91		moved it all back 

DESCRIPTION:
	This file contains the application interface for drawing filled
	polygons.

	$Id: graphicsPolygon.asm,v 1.1 97/04/05 01:13:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Overview
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Goal: 
	The filled polygon code should draw the polygon that would
	be drawn if you passed the same set of points to the poly line routine
	and then selectively flood filled the correct internal areas. So the
	both right and left edges are considered part of the polygon, not
	just boundaries.
	
	Implementation:
	Before reading further, you should know the basics about the about scan
	converting polygons (often referred to as the scan line algorithm). 
	Descriptions can be found in "Fundamentals of Interactive 
	Computer Graphics" by Foley and Van Dam as well as many other
	computer graphics books. Below I will describe the differences 
	between our implementation and the alogorthm defined in Foley and
	Van Dam.

	There are two rules for defining the "inside" of the polygon. The
	even-odd rule and the non-zero winding rule. These are described in
	the PostScript Reference Manual. Foley and Van Dam only use the 
	even-odd rule. The description below describes the even-odd 
	implementation with special section afterward on the winding rule.

	The basic data structures are the same, with an Edge Table (ET) and an
	Active Edge List (AEL), although some fields have been added to basic 
	Edge Record. The steps up to an including the building of each AEL
	is the same with the following exceptions. Horizontal edges are 
	included in the ET and the AEL. No edges are actually shortened, but
	there are flags in the edgeInfo field of the Edge Record, 
	shortenedTop and shortenedBottom which are set if shortening was
	needed. A version of Bresenhams line generation algorithm is used
	to determine the intersection of an edge with a scan line. This 
	algorithm actually returns two values for each scan line. These two
	values are the left and right pixels of the horizontal line 
	segment that would be drawn if the edge was rendering just as a line.
	The AEL is sorted in increasing order of the left value. 

	Choosing the ON and OFF values from the AEL is considerably different.
	The edges in AEL have two flavors SPAN_TOGGLE and SPAN_ONLY. For the
	most part horizontal edges are SPAN_ONLY and all non-horizontal edges
	are SPAN_TOGGLE. For the horizontal edge we just want to make sure 
	that the pixels from its left x coord to its right x coord (its span)
	are turned on. For the SPAN_TOGGLE edges, we must turn on the span
	between the left and right values, but must toggle our drawing mode.
	For example, to left of the first edge in the AEL the drawing mode is
	off. We hit a SPAN_TOGGLE edge, we must make sure that the left to 
	right span section is turned on, but we toggle the drawing mode to on
	and continue drawing to the right of right until we hit another toggle
	edge. We draw its span and the toggle drawing to off. For edges that
	are shortened, they become SPAN_ONLY for either their top or bottom
	scan line. For more info see the header for GetOnOff.

	Winding Rule:
	When using the winding rule, the active edge list contains the same
	set of edges but not all the same SPAN_TOGGLE edges.
	The SPAN_TOGGLE set for the winding rule is a subset of the set
	for the even-odd rule. The routine SetWindingScanLineInfo, 
	determines which edges are SPAN_TOGGLE under the winding rule. Once
	the edges are properly marked, everything else continues as with
	the even-odd rule.

GOAL REVISITED:
	Almost. Lines that are mostly horizontal (slope less than 1) are drawn 
	from left to right by the bresenham alogorithm in the drivers. 
	However, since scan converting is done from top to bottom,
	mostly horizontal edges that move from right to left when drawn for
	there tops will be 1 pixel off whenever the decision variable is
	exactly zero. So there.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Data Structures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	The structures described below are defined in graphicsConstant.def

Edge Table (ET)
	The edge table consists of a bucket table, a set of linked lists of
	edge records and an offset to the first record of the AEL.

Active Edge List (AEL)
	The active edge list consists of a linked list of edges that all
	cross a given scan line. The first word of the edge table block
	is the offset of the first record of the current AEL.

Bucket Table
	The bucket table starts at offset two (2) into the edge table block
	Each entry in the bucket table has two elements.
	The first is a y coordinate and the second is an absolute offset to
	the first edge in a linked list of EdgeRecords. All the edges in the
	list have their top ( ie minimum ) at the y coord in the bucket table.
	The bucket table is terminated with 8000h. 

Edge Records
	The edge records in the ET are stored one after the other in memory
	right after the bucket table. An Edge Record is part of at most
	one linked list at a time. The list is either the AEL or one of
	the lists that starts in the bucket table. Edges are linked by
	the field ER_allLink. With the final edge having a link of 0.
	

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OPTIMIZATIONS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
	Throw out all edges above or below the window. Would need to make
	the ET block allocation more flexible. If it appears the edges
	won't fit alloc a fff0h block and the check to see if it overflows
	when adding edges.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



GraphicsPolygon	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrFillPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a filled polygon to the screen with the current
		drawing state

CALLED BY:	GLOBAL

PASS:		di	- GState handle
		al	- RegionFillRule (enumerated type)
				RFR_ODD_EVEN - fill with odd/even rule
				RFR_WINDING  - fill with winding rule
		cx	- number of points in array
		ds:si	- array of points defining the polygon

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	The algorithm for filled polygon drawing routine is borrowed from
	X window system.  It was written by Brian Kelleher in Oct. 85
	and based on Bresenham's line drawing algorithm.
	For more information, look at the file,
	"/staff/adam/X11/server/ddx/mi/mipolygen.c".

KNOWN BUGS/SIDE EFFECTS/IDEAS:

		The polygon graphics string element looks like this:

			byte	GR_FILL_POLYGON
			byte	region_fill_rule
			word	#points in list
			dw...	data points

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted	4/89		Handles one or two points
	Ted	4/27/89		Uses local memory heaps
	jim	8/89		changed name, moved most to kernel lib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrFillPolygon	proc	far
	;
	; Compute size of data at DS:SI.  (Point is 4 bytes.)
	;
		push	cx
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx

		mov	ss:[TPD_dataBX], handle GrFillPolygonReal
		mov	ss:[TPD_dataAX], offset GrFillPolygonReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrFillPolygon	endp
CopyStackCodeXIP	ends

else

GrFillPolygon	proc	far
	FALL_THRU	GrFillPolygonReal
GrFillPolygon	endp

endif


GrFillPolygonReal	proc	far
		call	EnterGraphicsFill	; save some registers
		mov	dl, al			; save fill rule
		mov	dh, 0			;  make it a word (NO CLR!!!)
		push	ds			; save GState
		mov	ds, ss:[bp].EG_ds
		mov	ax, ds:[si]		; set curPos to first point
		mov	bx, ds:[si+2]
		pop	ds			; restore GState
		call	SetDocPenPos		; set new current position
		jc	fpGString		; if writing to segment...

		; normal case, call into kernel lib.  check for valid window
		; first

		call	TrivialRejectFar	; make sure there's a window
		mov	di, GS_areaAttr		; di - offset to area atts
		mov	bp, ss:[bp].EG_ds	; grab passed data pointer
		call	DrawPolygonLow		; draw the polygon
		jmp	ExitGraphics

		; handle writing to graphics string
fpGString:
		push	cx			; save #points
		mov	bx, cx			; # of points => BX
		mov	ah, dl			; save winding number
		mov	al, GR_FILL_POLYGON	; assume GString
		mov	cl, size OpFillPolygon - 1 ; # bytes to save
		jnz	changeToPath		; it's a Gstring - go do it
		xchg	ah, bl			; I know, it's weird, but we
		xchg	bl, bh			; want to do the size first
writeData:
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; store header
		pop	cx			; cx = count of coords
		mov	bp, sp
		mov	ds, [bp].EG_ds		; restore ds (trashed by EG)
		shl	cx, 1			; 4 bytes per coordinate point
		shl	cx, 1
		mov	ax, (GSSC_FLUSH shl 8) or 0ffh	; no code, flush buff
		call	GSStore			; store the data
		jmp	ExitGraphicsGseg

		; we're actually going to a path, so change to a Draw
changeToPath:
		mov	al, GR_DRAW_POLYGON	; assume Path
		mov	cl, size OpDrawPolygon - 1 ; 2 bytes for draw polygon
		jmp	writeData
GrFillPolygonReal	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrTestPointInPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Determine if point is in polygon

CALLED BY:	GLOBAL

PASS:		
		al	- RegionFillRule (enumerated type)
				RFR_ODD_EVEN - fill with odd/even rule
				RFR_WINDING  - fill with winding rule
		cx	- number of points in array
		ds:si	- array of points defining the polygon
		di	- handle of graphics state block
		dx,bx  	- point
RETURN:		
		ax = 1 - yes
		ax = 0 - no

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/90		Initial version
	jim	5/11/90		Added support for NULL windows and gstrings

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if 	FULL_EXECUTE_IN_PLACE

CopyStackCodeXIP	segment resource
GrTestPointInPolygon		proc	far
	;
	; Compute size of data at DS:SI.  (Point is 4 bytes.)
	;
		push	cx
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx

		mov	ss:[TPD_dataBX], handle GrTestPointInPolygonReal
		mov	ss:[TPD_dataAX], offset GrTestPointInPolygonReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrTestPointInPolygon		endp
CopyStackCodeXIP	ends

else

GrTestPointInPolygon		proc	far
	FALL_THRU	GrTestPointInPolygonReal
GrTestPointInPolygon		endp

endif

GrTestPointInPolygonReal		proc	far
	call	EnterGraphics
	jc	quickExit			; don't do it for gstrings
	tst	ds:[GS_window]			; check for null window
	jz	quickExit
	push	bp
	mov	bp, ss:[bp].EG_ds		; get segment
		CheckHack <RegionFillRule le 80h>	; works up to 7fh
	cbw					; ax = RegionFillRule
	xchg	dx, ax				; dx = RegionFillRule, ax = x
	call	IsPointInPolygon
	pop	bp				; restore frame pointer
	mov	ss:[bp].EG_ax, ax		;return our dude
	jmp	ExitGraphics

	; gstrings and windowless-gstates would be unhappy to do this work
quickExit:
	mov	ss:[bp].EG_ax, 0		;return our dude
	jmp	ExitGraphicsGseg
GrTestPointInPolygonReal		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrPolygonLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Main entry point for the polygon drawing code in the 
		Kernal Library

CALLED BY:	EXTERNAL
		GrPolygon	

PASS:		ds - graphics state structure
		es - window structure
		bp:si - array of points
		di - offset to area attributes
		(note this is inconsistent with the convention)
		cx - number of points
		dx - flag to indicate winding or odd-even rule

RETURN:		
		es - window segment - may have moved

DESTROYED:	ax, bx, cx,dx, si, di, bp		

PSEUDO CODE/STRATEGY:
		See Overview section

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		See Overview section		

??? Do I need to return a null region for zero pts or null mask special case
when the region is returned not drawn.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/14/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GPL_localVars	struct
    GPL_attr		dw	?	; offset to attributes
    GPL_segGState	dw	?	; segment of graphics state structure
    GPL_numPoints	dw	?	; number of vertices in polygon
    GPL_status		dw	?
    GPL_finalOffset	dw	?
    GPL_numDisjointPolylines	dw	?
    GPL_offsetToPoints	dw	?	; offset to passed coords
    GPL_handleET	dw	?	; handle of edge table block
    GPL_polygonYTop	dw	?	; top of polygon
    GPL_boundXMin	dw	?	; boundaries of polygon clipped
    GPL_boundXMax	dw	?	; to the window
    GPL_boundYMin	dw	?
    GPL_boundYMax	dw	?
    GPL_curBucket	dw	?	; ptr to current bucket in ET
    GPL_handleAEL	dw	?	; handle of active edge list chunk
    GPL_regSize		dw	?	; size of region definition buffer
    GPL_handleReg	dw	?	; handle of region definition buffer
    GPL_offsetReg	dw	?	; pointer into region definition buffer
    GPL_prevLine	dw	?	; pointer into reg. def. of prev. line
    GPL_genFlag		dw	?	; flag indicating different reg. def.
					; and used as swap counter in ResortAEL
    GPL_curScanLine	dw	?	; current scan line number
    GPL_prevEdgeInfo	db	?	; used in BuildET
    GPL_wordAlign	db	?	; makes StackFrame an even num of bytes
    GPL_fillRule	dw	?	;flag indicating odd-even, winding rule
GPL_localVars	ends

GPL_local		equ	[bp - (size GPL_localVars)]

GPL_ret:
	retf				; exit

DrawPolygonLow	proc	far
	uses	ds

	; check for NULL clip region

	test	es:[W_grFlags], mask WGF_MASK_NULL	; see if null mask
	jnz	GPL_ret		; exit if null mask

	tst	cx		; number of points equal zero?
	je	GPL_ret		; if so, exit

	.enter
	push	dx				; fill rule
	push	di
	clr	al				;don't add connected point
	call	CreateSeparatorFormat
	pop	di
	pop	ax				;fill rule

	; if there is a translation error creating separator format,
	; then bail, freeing the separator block as we go

	jc	free

	mov	bp,sp				;create stack frame
	sub	sp, size GPL_localVars
	mov	GPL_local.GPL_fillRule,ax
	mov	GPL_local.GPL_numPoints, cx
	mov	GPL_local.GPL_numDisjointPolylines,1
	mov	GPL_local.GPL_attr,di
	mov	GPL_local.GPL_segGState,ds
	clr	GPL_local.GPL_offsetToPoints	;offset to transed coords
	mov	ds, dx				; segment of transed coords
	push	bx				; save handle of transed coords
	call	GetBounds
	jc	GPL_90				;jmp if rejected
	call	CheckTrivial
	jc	GPL_90				;jmp if rejected

	call	PolygonAfterTrans	

	clr	ax				;no x offset for drawing
	clr	bx				;no y offset for drawing
	mov	si, GPL_local.GPL_attr		;offset to attributes
	mov	ds, GPL_local.GPL_segGState	;graphics state structure
	clr	cx				;cx - offset to region in block
	mov	di,DR_VID_REGION
	push	bp				;stack frame
	call	es:[W_driverStrategy]	
	pop	bp				;recover stack frame
	mov	bx,GPL_local.GPL_handleReg	;handle of region
	call	MemFree
GPL_90:	
	pop	bx				;handle of transed coords
	mov	sp, bp				;destroy stack frame
free:
	call	MemFree			
	.leave
	ret

DrawPolygonLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsPointInPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Determines if passed point is in polygon

CALLED BY:	INTERNAL

PASS:		
		ax,bx - point

		ds - graphics state structure
		es - window structure
		bp:si - array of points
		cx - number of points
		dx - flag to indicate winding or odd-even rule

RETURN:		
		ax = 1 - in
		ax = 0 - buzz
DESTROYED:	
		bx,cx,dx,di,si,bp

PSEUDO CODE/STRATEGY:
		get region
		transform point in screen coords
		check for point in region

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsPointInPolygon		proc	near
	uses	ds
	.enter

	push	ax,bx				;save point

	call	ReturnRegionPolygon

	pop	ax,dx				;point
	tst	bx				;region handle
	jz	noRegion
	push	bx				;handle region
	push	ds				;reg segment
	segmov	ds,es				;window
	mov	bx,dx				;y coord
	call	WinTransCoord
	jc	notInReg			; if out of bounds, bail
	mov	cx,ax				;point
	mov	dx,bx
	add	si, size Rectangle		;offset to region
	pop	ds				;reg segment
	call	GrTestPointInReg
	jnc	notInReg	
	mov	ax,1				;mark hit
cleanUp:
	pop	bx				;region handle
	call	MemFree
done:
	.leave
	ret

notInReg:
	clr	ax				;set not in region
	jmp	short cleanUp

noRegion:
	clr	ax				;set not in region
	jmp 	short done

IsPointInPolygon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnRegionPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Return region generated by polygon code
		Block return starts with bounds of the polygon and then
		the region

CALLED BY:	INTERNAL
		IsPointInPolygon

PASS:		
		bp:si - array of points
		cx - number of points
		dx - flag to indicate winding or odd-even rule
		es - window
RETURN:		

		bx - region block handle - if bx=0 no region
		ds:si - bounds, region
		ax - size of bounds and region
DESTROYED:	
		cx,dx,di

PSEUDO CODE/STRATEGY:
		translate point
		generate region
		destory block of translated points

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnRegionPolygon		proc	near
	.enter

	push	dx				; fill rule
	clr	al				;don't add connected point
	call	CreateSeparatorFormat

	mov	di,dx				;seg of coords
	pop	dx				;fill rule
	jc	bailQuick			;  oops, coords screwed

	push	bx				;handle of coords block
	clr	si				;offset to coords
	mov	bp,1				;num disjoint polygons
	call	ReturnRegionPolygonAfterTrans
	mov	ax,bx				;region handle
	mov	ds,dx				;segment of region
	pop	bx				;handle of coords

	call	MemFree
	mov	bx,ax				;region handle
	mov	ax,si				;size of region
	clr	si				;offset to bound,region
done:
	.leave
	ret

bailQuick:
	call	MemFree				; release block alloc'd in
						;  CreateSeparatorFormat
	clr	bx				; return NO region
	jmp	done
ReturnRegionPolygon		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnRegionPolygonAfterTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
		Returns region created by polygon code for already
		translated point

CALLED BY:	INTERNAL
		ReturnRegionPolygon

PASS:		
		cx - number of coord
		di - segment of coord block
		si - offset to points in coord block
		dx - flag indicating winding or odd-even rule
		bp - number of disjoint polylines
		es - window

RETURN:		
		bx - handle of region - if bx=0 no region
		dx - segment of region
		si - size of region def including bounds

DESTROYED:	
		ax, cx, di

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnRegionPolygonAfterTrans		proc	far
	push	ds,bp				;don't destroy
	mov	ax,bp				;save num disjoint polylines
	mov	bp,sp				;create a frame
	sub	sp, size GPL_localVars
	mov	GPL_local.GPL_numDisjointPolylines,bp
	mov	GPL_local.GPL_fillRule, dx	
	mov	GPL_local.GPL_numPoints, cx	
	mov	GPL_local.GPL_offsetToPoints,si

	mov	ds,di				;seg of coord block
	call	GetBounds			;get polygon bounds
	jc	reject				;jmp if rejected
	call	PolygonAfterTrans
	mov	bx,GPL_local.GPL_handleReg
done:
	mov	sp,bp
	pop	ds,bp
	ret

reject:
	clr	bx				;no region handle
	jmp	short done

ReturnRegionPolygonAfterTrans		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPolygonAfterTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a polygon from a set of translated coordinates

CALLED BY:	EXTERNAL
		FillRoundedRectLow
		FillArcLow

PASS:		ds - gstate
		es - window
		cx - number of coord
		di - segment of coord block
		dx - flag indicating winding or odd-even rule
		si - offset to attributes
		ax - offset to points in coord block 
		bx - number of disjoint polylines
		points in coord block are in separator format

RETURN:		
		es - window segment - may have moved
		region has been drawn

DESTROYED:	
		ax, bx, cx, dx, di, si

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 4/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPolygonAfterTrans		proc	far
	uses	bp
	.enter
	mov	bp,sp				;create a frame
	sub	sp, size GPL_localVars
	mov	GPL_local.GPL_numDisjointPolylines,bx
	mov	GPL_local.GPL_fillRule, dx	
	mov	GPL_local.GPL_numPoints, cx	
	mov	GPL_local.GPL_offsetToPoints,ax
	mov	GPL_local.GPL_attr,si
	mov	GPL_local.GPL_segGState,ds
	mov	ds,di				;seg of coord block
	call	GetBounds			;get polygon bounds
	jc	DPAT_90				;jmp if rejected
	call	CheckTrivial
	jc	DPAT_90				;jmp if rejected
	call	PolygonAfterTrans

	clr	ax				;no x offset for drawing
	clr	bx				;no y offset for drawing
	mov	si, GPL_local.GPL_attr		;offset to attributes
	mov	ds, GPL_local.GPL_segGState	;graphics state structure
	clr	cx				;cx - offset to region in block
	mov	di,DR_VID_REGION
	push	bp				;save stack frame
	call	es:[W_driverStrategy]	
	pop	bp
	mov	bx,GPL_local.GPL_handleReg	;handle of reg def
	call	MemFree
DPAT_90:	
	mov	sp,bp				;destroy stack frame
	.leave
	ret


DrawPolygonAfterTrans		endp

if 0		;if(0)'d out 4/7/90 by eca -- UNUSED

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateRectRegionAfterTrans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level routine for creating a rectangular region. It
		needs the points in screen coordinates

CALLED BY:	GLOBAL
		CreateRectRegionLow

PASS:		ax(si) - left
		bx(di) - top
		cx - right
		dx - bottom
		ds - gstate
		es - window
		EnterGraphics has been called
		coords passed in screen coord

RETURN:
		bx - handle of region block
DESTROYED:
		ax,cx,dx,si,di,bp

PSEUDO CODE/STRATEGY:

	See GrCreateRectRegion

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	See GrCreateRectRegion

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/ 5/89	Initial version
	jim	2/90		moved to klib

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateRectRegionAfterTrans		proc	far

	; move things back to where they belong

	mov	ax, si
	mov	bx, di

	; make sure the coordinates are in the right order

	cmp	ax,cx
	jle	xOrdered
	xchg	ax, cx
xOrdered:
	cmp	bx,dx
	jle	yOrdered
	xchg	bx,dx
yOrdered:

	; if it's rotated, do it the hard way

	test	es:[W_curTMatrix].TM_flags, TM_ROTATED
	jnz	CRRAT_rotated

	push	es			;don't destroy
	push	ax,cx			;save left, right
	mov	si,bx			;save top
	mov	cx,ALLOC_DYNAMIC_NO_ERR or (mask HAF_LOCK shl 8)
	mov	ax,22			;total for bounds and region
	call	MemAllocFar
	mov	es,ax			;seg of block
	pop	ax,cx			;get back left, right
	clr	di			;store at begining

		;ax,si,cx,dx - left,top,right,bottom

	stosw				;left of bounds
	mov	es:[di+12],ax		;left in reg def (si = 2)
	mov	ax,si			;top
	stosw				;top in bounds
	dec	ax			;
	mov	es:[di+4],ax		;top-1 in reg def (si = 4)
	mov	ax,cx			;right
	stosw				;right in bounds
	mov	es:[di+10],ax		;right in reg def (si=6)
	mov	ax,dx			;bottom
	stosw				;bottom of bounds
	mov	es:[di+4],ax		;bottom in reg def (si=8)
	mov	ax, EOREGREC
	mov	es:[di+2],ax		;end of first line of reg def
	mov	es:[di+10],ax		;end of second line of reg def
	mov	es:[di+12], ax		;end of reg def
	pop	es			;recover window
	call	MemUnlock		;bx still holds block
	ret

CRRAT_rotated:

	;push in reverse order y2x1 y2x2 y1x2 y1x1

	push	dx,ax,dx,cx,bx,cx,bx,ax
	mov	cx,4			;number of points
	mov	dx,RFR_ODD_EVEN
	mov	si,sp			;offset to points
	mov	di,ss			;segment of points
	call	ReturnRegionPolygonAfterTrans
	add	sp,16			;reset
	call	MemUnlock		;return unlocked
	mov	ax,si			;size of region including bounds
	mov	ch,mask HAF_NO_ERR
	call	MemReAlloc		;shrink block to size of region
	ret

CreateRectRegionAfterTrans		endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PolygonAfterTrans 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns region defined by polygon. Called when all the 
		coordinates have already been transformed.

CALLED BY:	INTERNAL		
		GrPolygonLow
		ReturnRegionPolygonAfterTrans

PASS:		ss:bp - GPL_Local Stack Frame
		GPL_numDisjointPolylines
		GPL_numPoints - number of points
		GPL_fillRule - flag indicating winding or odd-even rule
		GPL_offsetToPoints - offset to points in transed coord block
		GPL_boundXMin
		GPL_boundXMax
		GPL_boundYMin
		GPL_boundYMax
		ds - segment of transed coord block
RETURN:		
		GPL_handleReg  - handle of region
		dx - segment of region
		si - offset after last byte of reg def

DESTROYED:	ax, bx, cx, di, ds

PSEUDO CODE/STRATEGY:
		see Overview section near begining of file

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	7/7/89		Initial version
	jim	8/10/89		added external version
	srs	10/4/89		now returns region
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PolygonAfterTrans	proc	near
	uses	es
	.enter
	clr	GPL_local.GPL_handleET		;incase never allocated

	call	BuildET
EC < 	call	ECMemVerifyHeapHighEC				>
	call	GetRegBuffer		; get region definition buffer
	call	ScanLineCon		; do scan line conversion 
	call	DelBuffer		; delete buffer for ET
EC < 	call	ECMemVerifyHeapHighEC				>
	mov	dx,ds			;return segment of region
	.leave
	ret

PolygonAfterTrans	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds X min, X max, Y min, and Y max of the polygon

CALLED BY:	INTERNAL
		PolygonAfterTrans

PASS:		ss:bp - GPL_local Stack Frame
		ds - segment of coords block in SEPARATOR format
		GPL_offsetToPoints
		es - window

RETURN:		
		clc - part of polygon is in window
			GPL_boundXMax
			GPL_boundXMin
			GPL_boundYMax
			GPL_boundYMin
			GPL_polygonYTop
		
		stc - polygon and window do not overlap
			GPL bounds info not valid

DESTROYED:	ax, bx, cx, dx, di ,si

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	The bounds will be modified so as not to extend above or below
	the window. The left and right of the bounds cannot be modified
	with easily without screwing up clipping.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted	3/89		Calls Jim's new GrTransCoord routine
	Ted	4/89		Does not do the translation
	Ted	4/89		Made some changes after code review
	Ted	4/89		It now does the trasformation
	Ted	6/7/89		Transformation is already done at this point
	Ted	7/7/89		All the coordinates have already been read in
	srs	9/2/89		now puts bounds in stack frame
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetBounds	proc	near
	mov	si,GPL_local.GPL_offsetToPoints	;point to first vertex

	; get 1st coordinate and initialize X min/max, Y min/max
	;di = xMin bx = yMin cx = xMax dx = yMax

	lodsw				; get X coordinate
	mov	di,ax; initialize X min 
	mov	cx,ax			; initialize X max 

	lodsw				; get Y coordinate
	mov	bx,ax			; initialize Y min
	mov	dx,ax			; initialize Y max
GB_10:
	lodsw				; get X coordinate
	cmp	ax,SEPARATOR
	je	GB_50			;jmp if hit SEPARATOR
	cmp	ax,di			; compare X value with X min  
	jl	GB_60			; if less, store the new X min
	cmp	ax, cx			; if not, compare X value with X max
	jg	GB_70			; if greater, store the new X max
GB_20:
	lodsw				; get Y coordinate
	cmp	ax,bx			; compare Y value with Y min  
	jl	GB_80			; if less, store the new Y min
	cmp	ax,dx			; if not, compare Y value with Y max 
	jle	GB_10			; if less or equal, jmp to continue
;GB_30:					; else fall thru to store the new Y max
	mov	dx,ax			; store the new Y max
	jmp	short GB_10		; check next vertex
	
GB_50:		;HIT SEPARATOR
	cmp	ds:[si],SEPARATOR
	jne	GB_10			;jmp if didn't hit 2nd SEPARATOR

		;CONSTRAIN POLYGON BOUNDS WITHIN WINDOW BOUNDS

;GB_55:		
	mov	GPL_local.GPL_polygonYTop,bx
	mov	GPL_local.GPL_boundXMin,di
	mov	GPL_local.GPL_boundXMax,cx

	cmp	bx,es:W_winRect.R_top		;choose y min
	jge	20$
	mov	bx,es:W_winRect.R_top
20$:
	mov	GPL_local.GPL_boundYMin,bx

	cmp	dx,es:W_winRect.R_bottom	;choose y max
	jle	40$
	mov	dx,es:W_winRect.R_bottom
40$:
	cmp	dx,GPL_local.GPL_boundYMin	;y max to y min
	jl	reject				;jmp if not in window

	mov	GPL_local.GPL_boundYMax,dx

	clc					;not rejected
done:	
	ret				

reject:
	stc					;rejected
	jmp	short done


GB_60:
	mov	di, ax			; store the new X min
	jmp	short GB_20		; check Y coordinate
GB_70:
	mov	cx, ax			; store the new X max
	jmp	short GB_20		; check Y coordinate
GB_80:
	mov	bx, ax			; store the new Y min
	jmp	short GB_10		; check next vertex

GetBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckTrivial
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for trivial rejects

CALLED BY:	INTERNAL
		GrPolygonAfterTrans

PASS:		ss:bp - GPL_local stack frame
		GPL_boundXMax	(see GPL_StackFrame def for descriptions)
		GPL_boundXMin
		GPL_boundYMax
		GPL_boundYmin
		es - segment of window

RETURN:		carry set if the polygon is rejected		
		ds - unchanged

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	4/89		Initial version
	Don	3/92		Removed some redundant checking
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckTrivial	proc	near
	mov	ax, GPL_local.GPL_boundXMin	; ax - X min
	mov	cx, GPL_local.GPL_boundXMax	; cx - X max
	mov	bx, GPL_local.GPL_boundYMin	; bx - Y min
	mov	dx, GPL_local.GPL_boundYMax	; dx - Y max

	cmp	ax, es:[W_maskRect.R_right]
	jg	reject				; reject: past right
	cmp	cx, es:[W_maskRect.R_left]
	jl	reject				; reject: before left
	cmp	bx, es:[W_maskRect.R_bottom]
	jg	reject				; reject: below bottom
	cmp	dx, es:[W_maskRect.R_top]
	jge	done				; don't reject (carry is clear)
reject:
	stc					; do not reject
done:
	ret
CheckTrivial	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetETBuffer 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Allocate block to hold edge table

CALLED BY:	INTERNAL
		GrPolyLineAfterTrans

PASS:		ss:bp - stackframe GPL_local
		ax - number of edges
		
RETURN:		 
		GPL_local.GPL_handleET
		es - segment of edge table

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
	size of edge table = (number of edges) * (size EdgeRecord +4) + 4
		- each edge gets an edge record
		- all edges could have an entry in the bucket table(worst case)
		  takes up 4 bytes for each entry in bucket table
		- 2 bytes for offset that starts the AEL
		- 2 bytes for bucket ending marker 8000h

	See Data Structure section near begining of file for more info
	about table structure

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	if the block needed to hold all the edge records is greater
	than the max that can be alloced, allocate the max and hope
	enough edges are thrown out by PutRecordInET.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	Ted	7/7/89		The heap has already been created 
	srs	8/89		now uses size EdgeRecord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetETBuffer	proc	near
	mov	dx, size EdgeRecord + 4		;read STRATEGY section
	mul	dx				;to see how sizes are calced
	jc	allocMax
	add	ax,4
	jc	allocMax
	cmp	ax,0xfff0			;
	ja	allocMax
alloc:
	mov	cx,ALLOC_DYNAMIC_NO_ERR or ( mask HAF_LOCK shl 8 )
	call	MemAllocFar			; create a block for edge table
	mov	GPL_local.GPL_handleET, bx	; save the handle
	mov	es, ax				; es - seg of block
	ret					; exit

allocMax:
	mov	ax,0xfff0
	jmp	short alloc

GetETBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Builds the Edge Table from the coordinate list		


CALLED BY:	INTERNAL
		PolygonAfterTrans
PASS:		
		ss:bp - stack frame GPL_local
		GPL_offsetToPoints - offset to passed point in coord buffer
		GPL_numDisjointPolylines
		GPL_numPoints
		ds - segment of coordinate buffer
RETURN:		
		GPL_regSize - see comment in STRATEGY of AddPolylineToET
		es - segment of edge table
DESTROYED:	
		ax,bx,cx,dx,di,si

PSEUDO CODE/STRATEGY:
		-alloc buffer for edge table
		-initial edge table
		-repeatedly call AddPolylineToET with each polyline portion
		 of the passed buffer until hitting terminator

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		----------- 
	srs	8/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	BuildET
BuildET		proc	near
	mov	ax,GPL_local.GPL_numPoints

	call	GetETBuffer

	mov	GPL_local.GPL_regSize, 16 	; initial value for buffer size
	mov	di, ET_begBucket		; offset to beg of bucket table
	mov	word ptr es:[di], 08000h	; initialize the edge table
	mov	bx, GPL_local.GPL_numPoints
	shl	bx, 1
	shl	bx, 1				;bx = 4 * (number of edges)
	add	bx,2				;for end of bucket marker
	add	bx, di				;bx points past bucket table
						;to first place for an edge rec
BET_10:
	call	AddPolylineToET
	mov	GPL_local.GPL_offsetToPoints,si
	cmp	ds:[si],SEPARATOR
	jne	BET_10				;jmp if didn't hit 2nd SEP
	
	ret
BuildET		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddPolylineToET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Adds to the edge table all the line segments of a polyline
		portion of a buffer of points in SEPARATOR format

CALLED BY:	INTERNAL
		BuildET

PASS:		
		ss:bp GPL_local stack frame
		bx - offset to put next EdgeRecord at
		GPL_offsetToPoints
		GPL_regSize
		ds - segment of points
		es - segment of ET

RETURN:		
		bx - offset to put next EdgeRecord
		si - offset after SEPARATOR
		ds,es - unchanged
		GPL_regSize
		edges added to the edge table

DESTROYED:	
		ax,cx,dx,di

PSEUDO CODE/STRATEGY:
	An edge is specified by each set of two consecutive points in the
	coordinate buffer. Plus the connecting edge between the last point
	and the first point. These edges will become Edge Records in
	the Edge Table. 

	In the Edge Record the edge vertex with the smallest y value 
	will be placed in yMin and the highest y value in yMax. The x
	coord that goes with yMin will be in xLeft and the other in xBottom.
	Except if the line is horizontal, then xLeft will hold the left most
	x coord and xBottom the right most
	Additional information about the edges in the form of an ER_edgeInfo
	record will also be stored with each element.

	ER_horiz  	- if set means y1=y2, not set means y1<>y2
	ER_ccw		- if set means y1 > y2. The edge as retrieved from
			  the coord buffer was going up. Used to determine
			  relative direction of lines for shortening. Also
			  used by the winding edge stuff.
			  if not set edge moves top to bottom (y1<y2)
	ER_shortenTop	- the top of the edge needs to be shortened for the
			  scan convert stuff to work right (yTop=yTop+1). yTop
			  is not acutally changed, just the flag is set . this
			  flag is set in the routine ShortenEdge. if you want 
			  to know why we need to shorten edges read about
			  polygon scan converting algorithms
	ER_shortenBottom - basically same as SEE_shortenTop except 
		  	  yBottom = yBottom-1
	ER_useYRoutine	- if set means the |dy| > |dx|, ie the line is more
			  vertical than horizontal. Refers to which bresenham
			  routine to use.
	ER_deltaXNeg	- if set then when moving from yTop to yBottom
			  delta x is neg. This used by XRoutine and YRoutine
			  when calculating the pixels that lie on the edge
			  with Bresenhams algorithm

	Quick Definition:
	real edge - non horizontal 

	To determine whether a real edge needs to be shortened I must look at 
	the edgeInfo of the last real edge encountered in the vertex list.
	So when the first real edge is encountered, no attempt to shorten or
	store it is made. When all the edges have been processed, the first
	real edges is shortened if necessary (using edgeInfo from the final
	real edge) and then stored

	For each scanline an edge crossing it will introduce either an on or 
	off x coord in the region definition. So we add two bytes to the
	size of the region (GPL_local.GPL_regSize) for each scanline crossed.
	This is not the final size needed for the region, that will be
	calced later. GPL_regSize is initialized to 16. This covers 8 bytes
	for the region bounds, 2 bytes for the initial y value, 2 bytes for
	the initial EOREGREC, and two bytes for the final EOREGREC. 
	See GetRegBuffer for further info.

	Note: (See Reference to Note in code below)
	If there is only 1 point passed to the polygon code, it won't
	allocate a large enough region buffer. It doesn't think there is
	a connecting line, so for the one edge it only allocates space for
	1 x coord in the reg def, when there are really two (ON,OFF). So
	I add space to the region def for the other x coord. The case of 
	two points works, because it considers the connecting edge, so
	the original edge adds all the space for ON coords and the connecting
	edge adds all the space for the OFF coords. If this makes no sense,
	don't worry, it's very minor.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
		public	AddPolylineToET
APTET___40:
	mov	di,si				;pt to single pt twice
	add	GPL_local.GPL_regSize, 2	;see Note in header
	jmp	short	APTET_4			;

APTET___10:
	or	dl,mask ER_horiz		;set horizontal
	mov	es:[bx].ER_yMin,ax
	mov	es:[bx].ER_yMax,cx

	mov	cx,ds:[di]			;second x
	lodsw					;first x in ax
	cmp	ax,cx
	jl	APTET___23			;jmp if left in ax
	xchg	ax,cx
APTET___23:
	mov	es:[bx].ER_xLeft,ax		;store left x
	mov	es:[bx].ER_xRight,ax		
	mov	es:[bx].ER_xBottom,cx		;store right x
	mov	es:[bx].ER_edgeInfo,dl		;store edgeInfo calced so far
	clr	cx				;delta y for horiz edge
	jmp	short APTET_30			;jmp,to store edge record
						;but don't store prevEdgeInfo

AddPolylineToET		proc	near
	clr	GPL_local.GPL_status		;mov GPL_status,NORMAL_EDGE
	mov	si,GPL_local.GPL_offsetToPoints
	mov	di,si
	add	di,4				;offset to second vertex
	cmp	ds:[di],SEPARATOR
	je	APTET___40			;jmp if only 1 point
APTET_4 label near
	clr	dh				;flag no real edge yet
APTET_5:
	clr	dl				;set edgeInfo defaults in dl
	mov	es:[bx].ER_clockwise,1		;assume clockwise
	mov	ax,ds:[si+2]			;first y
	mov	cx,ds:[di+2]			;second y
	cmp	ax,cx				;ax = first y, bx = second y
	je	APTET___10			;jmp if horiz
	jl	APTET_10			;jmp if downward
	or	dl,mask ER_ccw			;for edgeInfo  in ShortenEdge
	neg	es:[bx].ER_clockwise		;for SetWindingScanLineInfo
	xchg	ax,cx				;ax - top, bx bottom
APTET_10:
	mov	es:[bx].ER_yMin,ax
	mov	es:[bx].ER_yMax,cx

	lodsw					;first x in ax
	mov	cx,ds:[di]			;second x
	test 	dl,mask ER_ccw			;were coords switched 
	jz	APTET_23			;jmp if no
	xchg	ax,cx				;match x's to switched y's
APTET_23:
	mov	es:[bx].ER_xLeft,ax		;store top x
	mov	es:[bx].ER_xRight,ax		;store top x
	mov	es:[bx].ER_xBottom,cx		;store bottom x
	mov	es:[bx].ER_edgeInfo,dl		;store edgeInfo calced so far

		;DETERMINE IF SHORTENING NEEDED FOR CURRENT EDGE
		;BASED ON CURRENT INFO AND PREVIOUS EDGE'S INFO
	tst	dh
	jz	APTET_100			;jmp if first real edge
	mov	al, GPL_local.GPL_prevEdgeInfo	;get prev edge info
	call	ShortenEdge
	mov	GPL_local.GPL_prevEdgeInfo,dl	;set prevEdgeInfo for next edge
	mov	es:[bx].ER_edgeInfo,dl		;save final edgeInfo
	call	InitBresError
APTET_30 label near	;ADJUST REG_SIZE AND STORE IN EDGE TABLE
	cmp	cx,-1
	je	APTET_40			; jmp if edge rejected
	inc	cx				; cx = Y max - Y min + 1
	shl	cx, 1				; cx = 2 * (Y max - Y min + 1)
	add	GPL_local.GPL_regSize, cx	; add to needed region size
EC <	ERROR_C	GRAPHICS_REGION_TOO_BIG 			>
	call	PutRecordInET			; store record into edge table 

APTET_40:			;ADVANCE LOOP VARIABLES
	add	di,4				;next second coord
	add	si,2				;next first coord
	tst	GPL_local.GPL_status		;cmp GPL_status, NORMAL_EDGE
	jne	APTET_45			;jmp if connecting or 1st real
	cmp	ds:[di],SEPARATOR
	jne	APTET_5				;jmp to continue
	
				;OUT OF NORMAL EDGES
	mov	GPL_local.GPL_finalOffset,di	;offset to be returned
	cmp	ds:[si],SEPARATOR
	je	APTET_50			;jmp if only one pt was passed
	mov	GPL_local.GPL_status,CONNECTING_EDGE
	mov	di,GPL_local.GPL_offsetToPoints ;2nd pt of connect is orig 1st
	jmp	APTET_5				;jmp to do connecting edge

APTET_45:			;CONNECTING OR FIRST REAL
	cmp	GPL_local.GPL_status,CONNECTING_EDGE
	jne	APTET_50			;jmp if doing 1st real edge
	tst	dh				;have there been any real edges
	jz	APTET_50			;jmp if no

		;GO BACK TO DO FIRST REAL EDGE
	mov	GPL_local.GPL_status,FIRST_REAL_EDGE
	pop	si				;recover offset to 1st real edg
	sub	si,2				;offset pushed was 2 too high
	mov	di,si				;di - offset to 2nd coord of
	add	di,4				;1st real edge
	jmp	APTET_5				;jmp to do first real edge
	
APTET_50:		;ALL DONE		
	mov	si,GPL_local.GPL_finalOffset
	add	si,2				;pt after SEPARATOR
	ret	

APTET_100:	;FIRST REAL EDGE
	push	si				;save offset to it 
						;actually 2 beyond first coord
	mov	dh,1				;flag at least one first real
	mov	GPL_local.GPL_prevEdgeInfo,dl	;set prevEdgeInfo for next edge
	jmp	short	APTET_40		;continue but don't store edge
AddPolylineToET		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShortenEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if an edge needs to be shortened and sets
		appropriate flags if so.

CALLED BY:	INTERNAL
		AddPolylineToET
PASS:		
		dl 	- current edgeInfo
		al	- edgeInfo from previous edge
		ER_horiz and ER_ccw flags must be set correctly for both 
RETURN:		
		dl	- new edgeInfo
		
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	if the current edge and the previous edge form a local max or 
	local min then nothing changes. if either edge is horizontal then
	nothing changes.

	if both edges are going downward then the top of the current edge
	must be shortened (shortenTop set). if both edge are going upward
	then the bottom of the current edge must be shortened 
	(shortenBottom set).
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShortenEdge		proc	near
	test	dl,mask ER_horiz		;if curr is horiz then no
	jnz	SE_90				;shortening so jmp
	test	al,mask ER_horiz		;if prev is horiz then no 
	jnz	SE_90				;shortening so jmp
	test	dl,mask ER_ccw
	jz	SE_100				;jmp if current downward

					;CURRENT EDGE IS UPWARD
	test	al, mask ER_ccw			;check direction of previous
	jz	SE_90				;jmp if vertex is local max
	or 	dl,mask ER_shortenBottom	;both edges going up so shorten
						;bottom of top(current) edge
			
SE_90:
	ret

SE_100:				;CURRENT EDGE IS DOWNWARD
	test	al, mask ER_ccw			;check direction of prev edge
	jnz	SE_90				;jmp if vertex is local min
	or 	dl,mask ER_shortenTop		;both edges going down,shorten 
						;top of bottom(current) edge
	jmp	short	SE_90

ShortenEdge		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitBresError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the error terms for the Bresenham's algorithm

CALLED BY:	INTERNAL
		AddPolylineToET

PASS:		es - segment of block containing ET
		bx - offset of edge record to init
		es:[bx].ER_xLeft
		es:[bx].ER_xBottom
		es:[bx].ER_yMax
		es:[bx].ER_yMin
		ss:bp GPL_local stack frame
		GPL_local.GPL_boundYMin
		GPL_local.GPL_boundYMax

RETURN:		
		es:[bx].ER_bresD
		es:[bx].ER_bresIncr1
		es:[bx].ER_bresIncr2
		cx - delta y of line inside window
				or
		     -1 if line outside of window so that it will not
			be included in GPL_regSize

DESTROYED:	ax

PSEUDO CODE/STRATEGY:
	See Bresenham alogorithm in Foley and Van Dam

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	6/23/89		Initial version
	Steve	8/16/89		Gutted and rewritten
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitBresError	proc	near
	mov	ax,es:[bx].ER_xBottom
	sub	ax,es:[bx].ER_xLeft		; ax = xBot - xTop
	tst	ax				;get absolute value of delta x
	jns	IBE_10				;
	neg	ax
	or	es:[bx].ER_edgeInfo,mask ER_deltaXNeg
IBE_10:
	mov	cx,es:[bx].ER_yMax
	sub	cx,es:[bx].ER_yMin		;delta y
	cmp	cx,ax				;compare deltas
	jl	IBE_50				;jmp if |delta y| < |delta x|
	or	es:[bx].ER_edgeInfo, mask ER_useYRoutine
	shl	ax				;
	mov	es:[bx].ER_bresIncr1,ax		;incr1 = 2 * delta x
	sub	ax,cx				;2dx-dy
	mov	es:[bx].ER_bresD,ax		;initial decision = 2dx-dy
	sub	ax,cx				;2dx-2dy
	mov	es:[bx].ER_bresIncr2,ax		;incr2 = 2(dx-dy)
	jo	overflow
	jmp	short calcDeltaY

IBE_50:
	shl	cx,1				;2dy
	mov	es:[bx].ER_bresIncr1,cx		;incr1 = 2 * delta y
	sub	cx,ax				;2dy-dx
	mov	es:[bx].ER_bresD,cx		;initial decision = 2dy-dx
	sub	cx,ax				;2dy-2dx
	jo	overflow
	mov	es:[bx].ER_bresIncr2,cx		;incr2 = 2(dy-dx)

		;CALC DELTA Y OF PORTION OF LINE IN BOUNDS

calcDeltaY:
	mov	cx,es:[bx].ER_yMax
	cmp	cx,GPL_local.GPL_boundYMax
	jle	10$
	mov	cx,GPL_local.GPL_boundYMax
10$:
	mov	ax,es:[bx].ER_yMin
	cmp	ax,GPL_local.GPL_boundYMin
	jge	20$
	mov	ax,GPL_local.GPL_boundYMin
20$:
	sub	cx,ax
	tst	cx
	js	30$
done:
	ret	

30$:
	mov	cx,-1
	jmp	short done

overflow:
	; There was an overflow in the subtraction -- so just stick
	; the largest negative number in there and hope for the best.

	mov	es:[bx].ER_bresIncr2, 8000h
	jmp	calcDeltaY		

InitBresError	endp	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PutRecordInET
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the new edge record into the edge table

CALLED BY:	INTERNAL
		AddPolylineToET

PASS:		
		es - segment of ET
		bx - offset to edge record
		es:[bx].ER_yMin = Y min of new edge record
		es:[bx].ER_xLeft = xMinor of new edge record
		ss:bp - stack frame

RETURN:		bx - offset to next place to put edge record

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
	Search the bucket table for yMin bucket
	if bucket not found
		create a new bucket and insert a recrod to this bucket
	if bucket found
		find the right place to insert in list and insert it

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PutRecordInET	proc	near
	push	dx,di,si			;don't destroy
	mov	dx,es:[bx].ER_yMin
	mov	ax,es:[bx].ER_yMax	
	cmp	dx,GPL_local.GPL_boundYMax	;line min to bounds max
	jg	PRIT_ret			;jmp to reject edge
	cmp	ax,GPL_local.GPL_boundYMin	;line max to bounds min
	jl	PRIT_ret			;jmp to reject edge

	mov	si, ET_begBucket		;pt to bucket table
PRIT_10:
	cmp	word ptr es:[si], 08000h	;is it end of bucket table?
	je	PRIT_30				;if so,jmp to create new bucket
	cmp	dx, es:[si]			;compare yMin to curr bucket
	jl	PRIT_25			;if less, make room for new bucket
	je	PRIT_15				; if equal, store in this list
	add	si, 4				; check the next bucket
	jmp	short PRIT_10

	; if match, enter the record into this bucket
PRIT_15:
	add	si, 2				;offset to offset of 1st record
	call	InsertEdgeRec			; insert the new edge record
	add	bx,size EdgeRecord		;next place to store edge rec
EC < 	ERROR_C	GRAPHICS_TOO_MANY_POLYGON_EDGES				>
EC <	cmp	bx,0xfff0						>
EC <	ERROR_A	GRAPHICS_TOO_MANY_POLYGON_EDGES				>
PRIT_ret:
	pop	dx,di,si			;recover
	ret			

PRIT_30:	;CREATE NEW ENTRY AT END OF BUCKET TABLE
	mov	es:[si], dx			; store bucket number
	mov	word ptr es:[si+4], 08000h 	; null terminate bucket table
	mov	word ptr es:[si+2],0		; zero out link
	jmp	short	PRIT_15			; jmp to insert
PRIT_25:	;INSERT NEW BUCKET ENTRY IN MIDDLE OF TABLE
	call	MoveBuckets			; make room for new bucket
	mov	es:[si], dx			; store bucket number
	mov	word ptr es:[si+2],0		; zero out link
	jmp	short PRIT_15			;jmp to insert

	

PutRecordInET	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveBuckets
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the buckets between the current one and the last one 
		down by four bytes so a new record can be inserted

CALLED BY:	INTERNAL
		PutRecordInET

PASS:		si - pointer to the current bucket
		es - segment of edge table

RETURN:		si - points to the place to insert the new bucket

DESTROYED:	cx, di

PSEUDO CODE/STRATEGY:
	Calculate the number words to be moved and
	does string move word in reverse direction

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveBuckets	proc	near
	clr	cx		; cx - number of words to move
	push	si		; si - index through bucket buffer

	; first calculate number of words to move by counting words 
	; to the end of bucket table
MB_10:
	add	si, 4		; check next bucket (each bucket is 2 words)
	add	cx, 2		; since we are doing word move, up it by two 
	cmp	word ptr es:[si], 08000h	; it it end of bucket table? 
	jne	MB_10		; if not, check the next bucket
	inc	cx		; add one for the null terminator

	; cx now contains the number of words to move

	push	ds
	segmov	ds, es		; source and dest are in the same segment
	mov	di, si
	add	di, 4		; di - points to the destination string
	std			; move the words from high addr. to low addr.
	rep	movsw		; just do it!!! 
	cld			; restore the direction
	pop	ds

	pop	si		; si - points to the new bucket position
	ret
MoveBuckets	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertEdgeRec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Steps through a linked list of Edge Records and finds a 
		place to insert	a new record and links it in.
		(used by both bucket table lists and active edge list)

CALLED BY:	INTERNAL
		PutRecordInET, BuildAEL

PASS:		es - segment of the edge table
		si - offset of offset to record to start search with
		bx - offset to unlinked EdgeRecord that 
		     needs to be inserted 
		es:[bx].ER_xLeft - xMin of edge 

RETURN:		new record linked in list

DESTROYED:	ax, si, di

PSEUDO CODE/STRATEGY:
	Search through the list until the xLeft of the record to insert
	is less than or equal to the xLeft of the current record in the list.
	Insert the new record before the current.

	Register Usage:
		bx - offset to record to insert
		si - offset to link to current record
		di - offset to current record

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	srs	8/89		Nuked slope test
	srs	8/89		Insert correctly in empty list
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InsertEdgeRec	proc	near
	mov	ax,es:[bx].ER_xLeft	;left of rec to insert
IER_10:
	mov	di,es:[si]		;offset to curr record
	tst	di
	je	IER_40			;jmp if no curr record
	cmp	ax, es:[di].ER_xLeft 	; compare x coordinates
	jle	IER_40			; if <=, jmp to insert here
	mov	si,di			;make curr in prev
	add	si, ER_allLink		;si points to link in prev
	jmp	short IER_10		; jump to do more

IER_40:		;LINK NEW RECORD IN
	mov	es:[si],bx		;set prev link to new
	mov	es:[bx].ER_allLink,di	;set allLink in new record to 
	ret				

InsertEdgeRec	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScanLineCon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a polygon into region definition, using the scan
		line conversion algorithm 

CALLED BY:	INTERNAL
		PolyLineAfterTransed

PASS:		
		ss:bp -	GPL_local
		ds - segment of region definition buffer
		es - segment of ET

RETURN:		ds - segment containing region
		si - offset to byte after end of region

DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
	For each scan line
		add edges to AEL
		update x values for this scan line
		set ScanLineInofo for each edge
		generate region definition for this scan line
		if necessary, delete edges from AEL 

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScanLineCon	proc	near
	mov	si, ET_begBucket		; beg. of bucket table
	mov	GPL_local.GPL_curBucket, si	; start with first bucket
	mov	di, AEL_allHead			; offset to head of AEL
	mov	word ptr es:[di], 0		; initialize AEL
	mov	GPL_local.GPL_offsetReg, OFFSET_REG_BUFFER; past bounds
	mov	GPL_local.GPL_prevLine, OFFSET_REG_BUFFER; past bounds
	mov	bx,GPL_local.GPL_polygonYTop	;
	mov	GPL_local.GPL_curScanLine, bx	;
	mov	ax,GPL_local.GPL_boundYMax
SLC_10:
	push	ax				; save Y max value 
	call	BuildAEL			; build Active Edge List
	call	UpdateAEL			; update X min values of edges
	call	ResortAEL			; resort edges on X min values
	cmp	GPL_local.GPL_fillRule, RFR_ODD_EVEN	; odd-even rule?
	je	SLC_100				; jmp if ODD_EVEN rule
	call	SetWindingScanLineInfo		;
SLC_20:
	mov	ax,GPL_local.GPL_curScanLine
	cmp	ax,GPL_local.GPL_boundYMin
	jl	SLC_25				; jmp if not within bounds
EC<	call	ECMemVerifyHeapHighEC	>
	call	GenRegDef		; generate reg def for this scan line
EC<	call	ECMemVerifyHeapHighEC	>
SLC_25:
	call	DeleteAEL		; delete edges that are no longer valid
	pop	ax				; restore Y max 
	inc	GPL_local.GPL_curScanLine 	;move down to next scan line
	cmp	GPL_local.GPL_curScanLine, ax	; are we done yet?
	jle	SLC_10				; if not, jmp to keep going
	mov	si, GPL_local.GPL_offsetReg	; get offset into reg. buffer
	mov	ax, EOREGREC			; 
	mov	ds:[si], ax			; terminate the region def 
	ret			

SLC_100:
	call	SetEvenOddScanLineInfo
	jmp 	short	SLC_20

ScanLineCon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRegBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a buffer for the region definition and set the 
		bounds of the region at the begining of the of the buffer
		and the top y and its EOREGREC
		
CALLED BY:	INTERNAL
		GrPolygonAfterTrans

PASS:		ss:bp - GPL_local stack frame
		GPL_regSize - see Strategy
		GPL_boundYMax
		GPL_boundYMin
		GPL_boundXMax
		GPL_boundXMin
	
RETURN:		ds - segment of new memory block allocated
		GPL_handleReg - handle of region block

DESTROYED:	ax,bx,cx,di

PSEUDO CODE/STRATEGY:
	Size of region definition buffer = GPL_regSize+(4*(ybottom-ytop+1)) +
					   ((GPL_numDisjointPolylines -1)*4)
		GPL_regSize = total bytes needed for all 
			the x coordinates in region definition + 
			final EOREGREC + init y + init EOREGREC
			+ bounds
		((GPL_numDisjointPolylines -1)*4) - each dijoint polyline
			except the first one, may result in a blank section
			between parts of the region. A blank section requires
			a y coord and an EOREGREC, that's 4 bytes.
		4 * (Y bottom - Y top + 1) = for each scan line, you need
			two bytes for y coordinate, and two bytes for end
			of region constant.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	srs	9/2/89		Corrected size calculation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRegBuffer	proc	near
	push	es				;don't destroy
	mov	ax, GPL_local.GPL_boundYMax	; ax - Y max
	sub	ax, GPL_local.GPL_boundYMin	; ax = Y max - Y min
	inc	ax				; ax = Y max - Y min + 1
	shl	ax, 1
EC<	ERROR_C	GRAPHICS_BAD_REGION_DEF	; polygon is to complex to draw	>
	shl	ax, 1				; ax = 4 * (Y max - Y min + 1)
EC<	ERROR_C	GRAPHICS_BAD_REGION_DEF	; polygon is to complex to draw	>
	add	ax, GPL_local.GPL_regSize	; add total buffer size
EC<	ERROR_C	GRAPHICS_BAD_REGION_DEF	; polygon is to complex to draw	>
	mov	cx,ALLOC_DYNAMIC_NO_ERR or ( mask HAF_LOCK shl 8 )
	call	MemAllocFar			; create a block for reg def
	mov	GPL_local.GPL_handleReg, bx	; save handle of new block
	mov	es, ax				; es - seg. of new block
	mov	ds, ax				; ds - same

	; initialize the region definition buffer

	clr	di		; di - index through region def. buffer
	mov	ax, GPL_local.GPL_boundXMin	; get X min
	stosw
	mov	ax, GPL_local.GPL_boundYMin	; 
	mov	bx,ax				;save yMin in bx
	stosw
	mov	ax, GPL_local.GPL_boundXMax	;
	stosw
	mov	ax, GPL_local.GPL_boundYMax	; 
	stosw
	mov	ax,bx				; yMin
	dec	ax				; nothing up to this y position
	stosw					;
	mov	ax, EOREGREC			; end of region def. constant
	stosw
	pop	es
	ret

GetRegBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BuildAEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add edges to the Active Edge List from the Edge Table

CALLED BY:	INTERNAL
		ScanLineCon

PASS:		es - segment of edge table
		ss:bp - GPL_local stack frame
		GPL_curScanLine
		GPL_curBucket

RETURN:		AEL may have been modified

DESTROYED:	ax, bx, dx, si, di

PSEUDO CODE/STRATEGY:
	Compare the current scan line number with current bucket number
	if match
		move each record on the buckets linked list into the AEL
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	See Data Structures description near begining of file

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	srs	9/89		Links records into AEL instead of copying
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BuildAEL	proc	near
	mov	bx, GPL_local.GPL_curScanLine	; bx - current scan line number
	mov	di, GPL_local.GPL_curBucket	;ptr to cur bucket table entry
	cmp	word ptr es:[di], 08000h	; are we end of bucket table?
	je	BAEL_ret			; exit if end
	cmp	bx, es:[di]	; is there an entry for this scan line in ET?
	jne	BAEL_ret	; jmp if no new edges to add to AEL

	; otherwise, add new edge records to Active Edge List

	mov	dx,es:[di+2]			;offset to first rec in ET 
	mov	word ptr es:[di+2],0		;nuke ptr to first rec
BAEL_10:
	mov	bx,dx				;offset to rec to insert in AEL
	mov	dx,es:[bx].ER_allLink		;save offset to next rec in ET
	mov	si, AEL_allHead			;start search at head of AEL
	call	InsertEdgeRec			; insert edge record into AEL
	tst	dx				;if more linked edges is ET
	jne	BAEL_10				;then jmp, put next rec in AEL
	add	GPL_local.GPL_curBucket, 4	;done, update index into bucket
						;table to next linked list of
						;edges in ET 
BAEL_ret:
	ret
BuildAEL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetWindingScanLineInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the scan line info for field of each record in the
		AEL for the winding rule.

CALLED BY:	INTERNAL
		ScanLineCon

PASS:		ss:bp 	- GPL_local Stack Frame
		GPL_curScanLine
		es - segment of Edge Table

RETURN:		records in AEL modified
		
DESTROYED:	ax, bx,cx, di

PSEUDO CODE/STRATEGY:
	Same basic strategy as SetEvenOddScanLineInfo. Except that not all
	the edges set to SPAN_TOGGLE for EVEN_ODD rule are set for the
	winding rule. See the Overview section for more info.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SWSLI___20:
	and 	es:[di].ER_edgeInfo, not mask ER_shortenTop	;no longer set
SWSLI___25:
	mov	es:[di].ER_scanLineInfo,SPAN_ONLY;edge span only this scanline
	jmp	short SWSLI_85			;jmp to link
SWSLI___30:
	mov	cx,GPL_local.GPL_curScanLine	;if scanline = yMax then this
	cmp	cx,es:[di].ER_yMax		;is place to shorten.
	jne	SWSLI_55			;jmp to still consider
	jmp	short SWSLI___25		;jmp to ignore

SetWindingScanLineInfo		proc	near
	mov	di,AEL_allHead
	mov	di, es:[di]			; di - offset of 1st rec in AEL
	tst	di				; is AEL empty?
	je	SWSLI_90			; if so, exit
	clr	ax				;init winding num
	mov	bx,1				;status - outside polygon
SWSLI_10:
	mov	es:[di].ER_scanLineInfo,SPAN_TOGGLE	;assume nothing special
	test	es:[di].ER_edgeInfo,mask ER_horiz
	jnz	SWSLI___25			;jmp if horiz
	test	es:[di].ER_edgeInfo, mask ER_shortenTop
	jnz	SWSLI___20			;jmp if shortened top
	test	es:[di].ER_edgeInfo, mask ER_shortenBottom
	jnz	SWSLI___30			;jmp if shortened bottom flag
SWSLI_55 label near	;DO WINDING CHECK
	add	ax, es:[di].ER_clockwise	; update the winding number
	tst	bx				; check current status
	js	SWSLI_100			; jmp if inside
	tst	ax				; outside, so check winding no.
	je	SWSLI_110			; if zero, then SPAN_ONLY
SWSLI_60:					; if non-zero, then SPAN_TOGGLE
	neg	bx				;update  status flag
SWSLI_85 label near	;ADVANCE TO NEXT EDGE RECORD
	mov	di,es:[di].ER_allLink		;offset of next allLink record
	tst	di			
	jnz	SWSLI_10			;jmp if more edges linked
SWSLI_90:
	ret

SWSLI_100:		;INSIDE POLYGON
	tst	ax				;check winding num	
	je	SWSLI_60			;jmp to keep SPAN_TOGGLE
SWSLI_110:		;MARK SPAN_ONLY
	mov	es:[di].ER_scanLineInfo,SPAN_ONLY
	jmp	short SWSLI_85			;jmp to advance to next rec

SetWindingScanLineInfo	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetEvenOddScanLineInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets the scanLineInfo field for each edge record.
		
CALLED BY:	INTERNAL
		ScanLineCon
PASS:		
		ss:bp - stack frame GPL_local
		GPL_curScanLine
		es - segment of ET
RETURN:		
		es - unchanged
		just what is says in the synopsis
DESTROYED:	
		ax,di

PSEUDO CODE/STRATEGY:
	for each edge in the AEL 
		if the edge is horizontal flag it as SPAN_ONLY
		if the edges is shortened on this scan line flag it SPAN_ONLY
		otherwise flag it as SPAN_TOGGLE
		
	See Overview section near begining of file		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/ 7/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SEOSLI___20:
	and 	es:[di].ER_edgeInfo, not mask ER_shortenTop	;no longer set
SEOSLI___25:
	mov	es:[di].ER_scanLineInfo,SPAN_ONLY;edge span only this scanline
	jmp	short SEOSLI_85			;jmp to link
SEOSLI___30:
	mov	ax,GPL_local.GPL_curScanLine	;if scanline = yMax then this
	cmp	ax,es:[di].ER_yMax		;is place to shorten.
	jne	SEOSLI_85			;jmp to still consider
	jmp	short SEOSLI___25		;jmp to ignore

SetEvenOddScanLineInfo		proc	near
	mov	di,AEL_allHead
	mov	di, es:[di]			; di - offset of 1st rec in AEL
	tst	di				; is AEL empty?
	je	SEOSLI_90			; if so, exit
SEOSLI_10:
	mov	es:[di].ER_scanLineInfo,SPAN_TOGGLE	;assume SPAN_TOGGLE
	test	es:[di].ER_edgeInfo,mask ER_horiz
	jnz	SEOSLI___25			;jmp if horiz
	test	es:[di].ER_edgeInfo, mask ER_shortenTop
	jnz	SEOSLI___20			;jmp if shortened top
	test	es:[di].ER_edgeInfo, mask ER_shortenBottom
	jnz	SEOSLI___30			;jmp if shortened bottom flag
SEOSLI_85 label near		;ADVANCE CURRENT EDGE RECORD
	mov	di,es:[di].ER_allLink		;offset of next allLink record
	tst	di			
	jnz	SEOSLI_10			;jmp if more edges linked
SEOSLI_90:
	ret
SetEvenOddScanLineInfo		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenRegDef
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate region definition for this scan line

CALLED BY:	ScanLineCon

PASS:		ds - segment of region definition buffer
		es - segment of edge table
		ss:bp - GPL_local stack frame
		GPL_curScanLine
		GPL_offsetReg
		GPL_prevLine
	
RETURN:		nothing 

DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
	Get the current scan line number
	Step through the AEL 
		get pair of ON, OFF values
		put them in the region def
	Until end of AEL 
	Store end of region def. constant
	
	If the region definition generated for this scan line has the same
	on and off points as the previous line in the region definition then
	the scan line number of the previous scan line is increment. This
	is referred to as optimizing in the code comments.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	Ted	5/2/89		Optimizes the region definition
	srs	8/89		Changed to use GetOnOff instead of GetXCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GenRegDef	proc	near
	mov	GPL_local.GPL_genFlag, 0	;init the optimze flag to can
	mov	di,AEL_allHead
	mov	di, es:[di]			; di - the 1st record in AEL
	mov	si, GPL_local.GPL_offsetReg  	; si - offset to cur reg. def
	mov	bx, GPL_local.GPL_curScanLine	; bx - current scan line number
	mov	ds:[si], bx			; store scan line number at
						; begining of reg def line
	mov	bx, GPL_local.GPL_prevLine	; offset to scan line number of
						; prev line in region def
	cmp	bx, si				; is this the 1st scan line?
	jne	GRD_10				; if not first scan line jmp
	mov	word ptr GPL_local.GPL_genFlag,-1;else can't optimize this line
GRD_10:
	tst	di
	jz	GRD_30				;jmp if no edges
GRD_15:
	call	GetOnOff			; 
	add	si, 2				; for next x coord in reg def
	add	bx, 2				; update pointer into prev line
	cmp	ds:[bx], ax			; store on
	je	GRD_27				; if on coords are same jmp
	mov	word ptr GPL_local.GPL_genFlag, -1;else flag can't optimze line
GRD_27:
	mov	ds:[si], ax			; write new on coord reg def
	add	si, 2				; for next x coord in reg def
	add	bx,2				;update ptr into prev reg line
	cmp	ds:[bx],dx			;are off coords the same
	je	GRD_28				;if off coords are same jmp
	mov	word ptr GPL_local.GPL_genFlag, -1;else flag can't optimze line
GRD_28:
	mov	ds:[si], dx			; write new off coord reg def
	tst	di				;any more edges
	jne	GRD_15				;jmp if yes
GRD_30:
	add	si, 2				;past last x in curr reg line
	mov	ax, EOREGREC			;store end of curr reg line
	add	bx, 2				;advance ptr in prev reg line
	cmp	ds:[bx], ax			;do both end at same place
	je	GRD_40				; if so, skip
	mov	word ptr GPL_local.GPL_genFlag, -1 ; if not, flag no opt
GRD_40:
	mov	ds:[si], ax			; write out EOREGREC to buffer
	add	si, 2				; update the cur reg def index 

	cmp	word ptr GPL_local.GPL_genFlag, 0	; are definitions same?
	je	GRD_100				; if yes, jmp
	mov	bx, GPL_local.GPL_offsetReg	;pt to beg of curr reg def line
	mov	GPL_local.GPL_prevLine, bx	;make it prev for next time
	mov	GPL_local.GPL_offsetReg, si  	;start reg def here next time
GRD_95:
	ret
GRD_100:	;OPTIMIZE
	mov	bx, GPL_local.GPL_prevLine	; if so,
	inc	word ptr ds:[bx]		; just increment Y value
	jmp	short GRD_95			

GenRegDef	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOnOff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get an ON and OFF value for the region definition starting 
		with the passed edge in the AEL 
		

CALLED BY:	INTERNAL
		GenRegDef

PASS:		
		es:[di] - edge to start with
		ss:bp - stack frame GPL_local

RETURN:		ax - ON
		dx - OFF
		es:[di] - next edge to use
			if di = zero then no more edges		

DESTROYED:	cx

PSEUDO CODE/STRATEGY:
	This is a bit complicated so I explain a bit at a time.
	Remember that the active edge list (AEL) is sorted by
	increasing values of xLeft. Also all the edges mentioned below
	are SPAN_TOGGLE until specifically stated. See Overview section
	SetEvenOddScanLineInfo and SetWindingScanLineInfo for more info about 
	SPAN_TOGGLE and SPAN_ONLY

	First consider an AEL with only two edges in it and both the
	edges are perfectly veritcal. The first edge
	is the ON edge and the second edge is the OFF edge. For each edge
	xLeft=xRight. To get the ON/OFF range I just take a value from
	the first edge and a value from the second edge. For arugment sake
	I'll take the xLeft value from the first edge and the xRight value
	from the second edge.

	Now lets consider an AEL with two edges in it, but both edges are
	mostly horizontal. In this case, xLeft<>xRight for both edges. The
	xLeft,xRight variables in each edge represent a horizontal span of
	pixels. If these spans do not overlap then we do just as we did 
	before. We make the xLeft of the first edge ON and the xRight of
	the second edge OFF. However, if the spans overlap things get
	a little more difficult. We know that the xLeft of the second edge
	cannot be less than the xLeft of the first edge, so we can always
	use the first edge's xLeft as the ON. We must make sure that the
	full length of each span as well as the span from xLeft to the 
	largest xRight are filled in. If we choose xLeft and the largest
	xRight then both conditions are met.

	Next lets consider an AEL with 4 edges in it. We take the first two
	and follow the above instructions to get an ON and OFF. We then look
	at xLeft of the third edge. If this xLeft > OFF+1 then we have
	separate spans and our ON,OFF
	values are correct and we return. Otherwise we must combine the 
	next two edges (ie the next would be ON,OFF pair) with our current
	ON,OFF values. With the 3rd and 4th edges,as before, we must make sure
	that the span of each edge and the span between them are filled. So
	we take the largest (ie rightmost) of OFF, xRight of edge 3, xRight of
	edge 4 and make it OFF. Got that.

	We continue looking at pairs of edges until we get separate spans.

	However, we must consider SPAN_ONLY edges. These consist of 
	horizontal edges and edges that are shortened on the current scan
	line. They are similar in that
	the span from xLeft to xRight must be filled in. But, they cannot
	be grouped as part of the ON,OFF pairs mentioned above. So their spans
	are combined in the normal rightmost fashions. But we only check for
	separate spans when we have looked at an even number of 
	SPAN_TOGGLE edges.
	
	That about covers it. Doesn't seem so bad now.	

	Register Usage:
	ax - ON
	dx - OFF
	si - number of SPAN_TOGGLE edges encountered
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetOnOff	proc	near
	push	si,bx
	clr	si				;num TOGGLE edges encountered
	mov	ax,es:[di].ER_xLeft		;init ON
	mov	dx,es:[di].ER_xRight		;init OFF

	cmp	es:[di].ER_scanLineInfo,SPAN_ONLY
	je	GOO_5
	inc	si				;hit a TOGGLE edge
GOO_5:
		;GET SECOND EDGE
	add	di,ER_allLink
	mov	di,es:[di]			;offset to second edge
	tst	di
	jz	GOO_60				;jmp if only one edge

GOO_10:
	mov	bx,es:[di].ER_xLeft
	test	si,0001h
	jnz	GOO_17				;jmp if between ON, OFF span
						;defined by two TOGGLE edges

			;CHECK FOR TWO SEPARATE SPANS
	sub	bx,dx				;if new left > OFF+1 then 
	cmp	bx,1				;separate spans
	jg	GOO_60				;jmp if two separate spans

GOO_17:			;STILL SINGLE SPAN
	cmp	es:[di].ER_scanLineInfo,SPAN_ONLY
	je	GOO_19
	inc	si				;encountered TOGGLE edge
GOO_19:
	mov	cx,es:[di].ER_xRight
	cmp	cx,dx				;is new right > OFF
	jle	GOO_25				;jmp is no
	mov	dx,cx				;new right becomes OFF
GOO_25:
			;GET NEXT EDGE
	add	di,ER_allLink
	mov	di,es:[di]			;offset to second edge
	tst	di
	jnz	GOO_10				;jmp if more edges	

GOO_60:		
;EC<	test	si,0001h			>
;EC<	ERROR_NZ GRAPHICS_ODD_NUM_TOGGLE_EDGES_IN_AEL ;error if in middle ON,OFF span>
	pop	si,bx
	ret

GetOnOff	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteAEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes all the edge records in the AEL that have
		yMax = curScanLine

CALLED BY:	INTERNAL
		ScanLineCon

PASS:		ss:bp - GPL_local StackFrame
		GPL_curScanLine
		es - segment of block containing ET

RETURN:		modified AEL 

DESTROYED:	bx, si, di 

PSEUDO CODE/STRATEGY:
	Step through AEL
		compare Y max with current scan line number
		if equal
			have the link point to the record after this one
		if not equal
			get the next record
	Until end of AEL

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	srs	9/2/89		Beefed up coments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteAEL	proc	near
	mov	bx, GPL_local.GPL_curScanLine	; bx - current scan line number
	mov	di,AEL_allHead
	mov	si, es:[di]		; si - points to the 1st record in AEL
	tst	si
	je	DEL_ret			;jmp if empty AEL
DEL_10:
	cmp	bx, es:[si].ER_yMax	; is Y = Y max?
	je	DEL_20			; jmp if Y= Ymax to delete
	mov	di, si			;
	add	di, ER_allLink		; pt di to link to next rec
	mov	si,es:[di]		;pt to next rec
	tst	si
	je	DEL_ret			; jmp if no more records
	jmp	short DEL_10
DEL_20:				; Y = Y max, so this record must be deleted
	mov	si, es:[si].ER_allLink	; pt to rec after victim record
	mov	es:[di], si		; set prev link around deleted rec
	tst	si			; any more?
	jne	DEL_10			; if yes, check the next record
DEL_ret:
	ret				; otherwise, exit
DeleteAEL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateAEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates the xLeft and xRight value of each record in AEL

CALLED BY:	INTERNAL
		ScanLineCon

PASS:		ss:bp - stack frame GPL_local
		GPL_local.GPL_curScanLine
		es - segment of ET block
RETURN:		
		all edges in the aet have been updated

DESTROYED:	ax,bx,cx,dx,di 

PSEUDO CODE/STRATEGY:
		For each edge check the useYRoutine flag and call the 
		appropriate Bresenham routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	srs	8/89		changed to use XRoutine and YRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateAEL	proc	near
	mov	di, AEL_allHead			
	mov	di, es:[di]			; di - 1st record in AEL
	tst	di				; is AEL is empty?
	je	UAEL_ret			; if so, exit	
UAEL_10:
	test	es:[di].ER_edgeInfo,mask ER_useYRoutine
	jz	UAEL_20
	call	YRoutine
	jmp	short	UAEL_90
UAEL_20:
	call	XRoutine	
UAEL_90:
	add	di, ER_allLink			; offset to link to next rec.
	mov	di, es:[di]			; get the next record
	tst	di				; end of AEL?
	jne	UAEL_10				; if not, continue
UAEL_ret:
	ret					; otherwise, exit
UpdateAEL	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the x value on a given scan line for a edge
		using bresenhams algorithm. This routine is for edges that
		are mostly veritcal ( ie. >=  45 degrees )

CALLED BY:	INTERNAL
		UpdateAEL	

PASS:		ss:bp - GPL_local stack frame
		GPL_curScanLine
		es:[di] - edge record
		ER_incr1	- properly initialized bresenham variable
		ER_incr2	- properly initialized bresenham variable
		ER_d		- current decision variable value
		ER_xLeft	- x left of previous span
		ER_xRight	- x right of previous span
		ER_xBottom	- see EdgeRecord struct def
		ER_edgeInfo	- properly set in AddPolylineToET
RETURN:		
		ER_d		 decision value to be used first point 
				 of the line that is on the next scan line
				 down.
		ER_xLeft	- x coord 
		ER_xRight	- same as ER_xLeft
		es,di		- unchanged
DESTROYED:	
		ax,bx,cx

PSEUDO CODE/STRATEGY:
	Uses Bresenhams algorithm as described in Foley and Van Dam.
	This lines are calced starting at the smallest y and moving toward
	the largest y. It may go either direction in x.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
YRoutine		proc	near
	mov	bx,es:[di].ER_xLeft
	mov	ax,es:[di].ER_bresD		;decision variable
	mov	cx,GPL_local.GPL_curScanLine
	cmp	cx,es:[di].ER_yMin
						;jmp if edge's first scan line
	je	YR_40				;to just use initial xLeft

	tst	ax				;check decision variable
	jg	YR_20				;jmp if d>0 - x changing
	add	ax,es:[di].ER_bresIncr1
	jmp	short	YR_ret
YR_20:
		;X CHANGING - MOVE IT ONE TO LEFT OR RIGHT		
	test	es:[di].ER_edgeInfo, mask ER_deltaXNeg	
	jnz	YR_30				;jmp if delta x is neg
	add	bx,2				;really only 1 - change in x
YR_30:
	dec	bx
	add	ax,es:[di].ER_bresIncr2		;adjust decision variable
YR_40:
	mov	es:[di].ER_xLeft,bx
	mov	es:[di].ER_xRight,bx
YR_ret:
	mov	es:[di].ER_bresD,ax			;save new decision
	ret
YRoutine		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		XRoutine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the horizontal span of pixels on a given scan
		line for an edge using bresenhams algorithm. This routine
		is for lines that are mostly horizontal(ie. > 45 degrees).

CALLED BY:	INTERNAL
		UpdateAEL

PASS:		ss:bp	- GPL_local stack frame
		GPL_curScanLine
		es:[di] - edge record
		ER_incr1	- properly initialized bresenham variable
				- not needed if edge is horizontal
		ER_incr2	- properly initialized bresenham variable
				- not needed if edge is horizontal
		ER_d		- current decision variable value
		ER_xLeft	- x left of previous span
		ER_xRight	- x right of previous span
		ER_xBottom	- see EdgeRecord struct def
		ER_edgeInfo	- properly set in AddPolylineToET

RETURN:		
		ER_d		 decision value to be used first point 
				 of the edge that is on the next scan line
				 down.
				 not returned if line is horiz
		ER_xLeft	- left x coord of span
		ER_xRight	- right x coord of span
		es,di		- unchanged

DESTROYED:	
	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
	Uses Bresenhams algorithm as described in Foley and Van Dam.
	This lines are calced starting at the smallest y and moving toward
	the largest y. It may go either direction in x.

	In the case of a horizontal line, ER_xLeft was set to the
	left edge of the line and xBottom to the right edge of the line, in
	AddPolylineToET

	The comments below like GOING TO RIGHT or TO LEFT refer to the 
	direction of the edge as y is incremented.
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
XR___10:	;HORIZ LINE
	mov	ax,es:[di].ER_xBottom		;really right (see STRATEGY)
	mov	es:[di].ER_xRight,ax
	jmp	short XR_ret

XR___20:		;AT LAST SCAN LINE OF EDGE
	mov	cx,es:[di].ER_xBottom
	test	es:[di].ER_edgeInfo, mask ER_deltaXNeg	
	jnz	XR___25				;jmp if delta x < 0
			;GOING TO RIGHT
	inc	ax				;old right +1
	mov	es:[di].ER_xLeft,ax		;left = old right + 1
	mov	es:[di].ER_xRight,cx		;going to right xRight = xBot
	jmp	short	XR_ret
XR___25:		;GOING TO LEFT
	dec 	bx				;old left -1
	mov	es:[di].ER_xRight,bx		;right = old Left -1
	mov	es:[di].ER_xLeft,cx		;going to left xLeft = xMax
	jmp	short XR_ret

XRoutine		proc	near
	test	es:[di].ER_edgeInfo,mask ER_horiz
	jnz	XR___10				;jmp if this edge is horiz

	clr	dx				;sum of changes to x
	mov	ax,es:[di].ER_xRight		;get previous values into regs
	mov	bx,es:[di].ER_xLeft
	mov	cx,GPL_local.GPL_curScanLine
	cmp	cx,es:[di].ER_yMin
	je	XR_9				;jmp if edge's first scan line
	cmp	cx,es:[di].ER_yMax
	je	XR___20				;jmp if edge's last scan line

			;IN MIDDLE SCAN LINE OF EDGE
	test	es:[di].ER_edgeInfo, mask ER_deltaXNeg	
	jnz	XR_5				;jmp if going to left
			;GOING TO RIGHT
	inc	ax				;start new right and new left
	mov	bx,ax				; at old right+1
	jmp	short	XR_9
XR_5:			;GOING TO LEFT
	dec	bx				;start new left and new right
	mov	ax,bx				;at old left -1
XR_9:
	mov	cx,es:[di].ER_bresD		;decision variable
	tst	cx				;decision varible
	jg	XR_20				;jmp if d>0 - y changing
XR_11:
	inc	dx				;another change to x
	add	cx,es:[di].ER_bresIncr1		;adjust decision variable
	tst	cx
	jle	XR_11				;jmp if another change to x
XR_20:
		;Y CHANGING 
	add	cx,es:[di].ER_bresIncr2		;adjust decision variable
	test	es:[di].ER_edgeInfo, mask ER_deltaXNeg	
	jnz	XR_30 				;jmp if going to left
				;GOING RIGHT
	add	ax,dx				;add number of changes to 
						;get new right
	jmp	short	XR_40
XR_30:				;GOING LEFT
	sub	bx,dx				;sub number of changes
XR_40:						;to get new left
	mov	es:[di].ER_xLeft,bx		;return new left and right
	mov	es:[di].ER_xRight,ax		
XR_ret	label	near
	mov	es:[di].ER_bresD,cx		;save new decision
	ret
XRoutine		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ResortAEL
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resorts the  AEL according to new xLeft values

CALLED BY:	INTERNAL
		ScanLineCon

PASS:		es - segment of ET

RETURN:		resorted AEL

DESTROYED:	ax, bx, cl, dx,si, di

PSEUDO CODE/STRATEGY:
	Uses the Bubble Sort to sort the list

	Register Usage:
		si - offset to link in prev, that points to curr
		di - offset to cur
		bx - offset to next

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	3/89		Initial version
	Ted 	4/89		Made some changes after code review
	srs	9/4/89		Now swaps by changing links
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	ResortAEL	proc	near
RAEL_5:
	clr	cl			; no swaps yet flag
	mov	si,AEL_allHead		;offset to offset to AEL
	mov	di,es:[si]		;offset to first rec
	tst	di
	je	RAEL_ret		;jmp if no edges
	mov	bx, es:[di].ER_allLink	;offset to 2nd record in AEL
	tst	bx			
	je	RAEL_ret		;jmp if only 1 rec in AEL
	mov	dx, es:[di].ER_xLeft 	;get first xLeft
RAEL_10:				
	mov	ax,dx			;set curr left from old next left
	mov	dx, es:[bx].ER_xLeft	;get next left
	cmp	ax, dx		 	;cmp curr Left to next Left
	jg	RAEL_100		;if currX > nextX, jmp swap
RAEL_30:	;ADVANCE 
	mov	si,di			;set prev offset to curr offset
	add	si,ER_allLink		;prev must pt to link
	mov	di,bx			;set curr offset to next offset
	mov	bx, es:[di].ER_allLink	;set next offset
	tst	bx			;are we end of the AEL?
	jne	RAEL_10			;if so, exit
RAEL_ret:
	tst	cl			;were there any swaps?
	jne	RAEL_5			;if so, go back and scan one more time
	ret				; exit

RAEL_100:	;OUT OF ORDER, SWAP CURR AND NEXT 
	mov	dx,ax			;use same left next check
	mov	es:[si], bx		;pt prev to next
	mov	ax,es:[bx].ER_allLink	;get next's link
	mov	es:[di].ER_allLink,ax	;set curr's link to next's link
	mov	es:[bx].ER_allLink,di	;pt next to curr
	mov	cl,-1			;there was a swap, flag it
	xchg	bx,di			;bx - new next and di - new curr
	jmp	short RAEL_30		;jmp to advance
ResortAEL	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DelBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes block for edge table

CALLED BY:	INTERNAL
		GrPolygonAfterTrans	

PASS:		ss:bp - GPL_local stack frame
		GPL_handleET

RETURN:		nothing

DESTROYED:	bx

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Ted	5/3/89		Initial version
	srs	8/89		checks for no ET handle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DelBuffer	proc	near
	mov	bx,GPL_local.GPL_handleET
	tst	bx
	jz	DB_10				;jmp if never allocated because
	call	MemFree				;of trivial reject
DB_10:
	ret
DelBuffer	endp



if ERROR_CHECK

ECMemVerifyHeapHighEC proc near
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
ECMemVerifyHeapHighEC	endp

endif

GraphicsPolygon ends
