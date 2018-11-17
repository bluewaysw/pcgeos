COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GRAPHICS
FILE:		grFatLine.asm

AUTHOR:		Steve Scholl, Apr 24, 1989

ROUTINES:
	Name			Description
	----			-----------
    INT DoFatLines		The main routine
    INT CheckForSpecialCases	Examines points list for problems
    INT RemovePointRedundancies Cleans up list of points
    INT DrawFatPolyLine		Looping routine for drawing poly lines
    INT HandleFatPolyConnection Special routine called for connected polys
    INT DrawFatPolyLineLow	Draws fat line segment with proper end, join
    INT	BasicFatLineCalcs	Just what it says
    INT DrawFatLineReg		Draw region defining fat lines
    INT HandleMiteredConnection Restore first join info
    INT CalcJoin		Calcs line join between two fat lines
    INT CalcBeveledJoin		Calcs beveled join information
    INT CalcMiteredJoin		Calcs mitered join information
    INT CheckMiterLimit		Decides when angle too acute to do miter
    INT CalcLineAngle		Calcs angle of line and other info
    INT CalcCCWAngleDiff	Calcs CCW angle difference between two lines
    INT MakeEndCap		Calls correct cap routine based on line type
    INT MakeButtCap		Calculates butt cap for a fat line
    INT MakeSquareCap		Calculates square cap for a fat line

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	4/24/89		Initial revision
	jim	8/8/89		moved it all over to kernel lib


DESCRIPTION:
	Contains routines for calculating fat lines 
		

	$Id: graphicsFatLine.asm,v 1.1 97/04/05 01:12:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

USETESTLINES	=	0

MAX_DELTA 	= 181
MEC_FIRST 	= 10100000b
MEC_SECOND 	= 00000000b

GraphicsFatLine segment resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFatLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
		dx:si - array of points in terminated separator format
		ds - segment of graphics state
		es - segment of window 
		cx - connected flag - only used if one set of points
		di	- offset to attributes to use

RETURN:		

DESTROYED:	

PSEUDO CODE/STRATEGY:
		Determine number of disjoint polylines
		if only one
			pass ptr, number of points, connect flag	
		if more than one
			counte
			pass ptr to first, number of first, clear connect flag
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoFatLines		proc	far
	mov	ax, di				; save attribute offset
	push	cx				;save connected flag
	call	GetContiguousPoints
	pop	bx				;get connected flag
	jc	onlyOne
	pushf					;save final status
10$:
	push	dx,di,ax			;save offset to next
	clr	di				;not connected
	call	DoFatLinesLow
	pop	dx,di,ax
	popf					;get final status
	jc	done				;jmp if done
	mov	si,di				;start of next set
	call	GetContiguousPoints
	pushf					;save final status
	jmp	short 10$

onlyOne:
	mov	di,bx				;connected flag
	call	DoFatLinesLow
done:
	ret
DoFatLines		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetContiguousPoints
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return number of points in current contiguous set and a
		flag indicating if this is the last set.
		
CALLED BY:	
		DoFatLines
PASS:		
		dx:si - start of new set
RETURN:		
		dx:si - start of current set
		dx:di	- start of next set if any
		cx - number

		stc - means final set of points
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetContiguousPoints		proc	near
	uses	ds, ax
	.enter
	mov	ds,dx
	mov	di,si				;save start
	clr	cx				;number of points
10$:
	lodsw					;get x or separator
	cmp	ax,SEPARATOR
	je	hitSeparator
	add	si,2				;past y
	inc	cx				;number of points
	jmp	short 10$

hitSeparator:
	lodsw					;get x or 2nd separator
	cmp	ax,SEPARATOR
	je	hitTerminator
	sub	si,2				;pt back to x
	xchg	di,si				;di - next set, si - curr set
	clc
done:
	.leave
	ret

hitTerminator:
	mov	si,di				;si - current set
	stc
	jmp	done
GetContiguousPoints		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoFatLinesLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up stack variables and calls appropriate routines to 
		draw a fat line or polygon.
		Lines are drawn using the lineAttributes including end and
		join types

CALLED BY:	INTERNAL
		DrawFatLine
		DrawFatFrame
		GrPolyLine
PASS:		
		cx -	number of points in polygon
		di -	0,1 1 - connect last point with first 0 - don't connect
		dx:si -	segment and offset to list of points
		es -	Window structure
		ds -	graphics state
		ax	- offset to attributes to use
	
RETURN:		
	nothing
DESTROYED:	
	ax,bx,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
	The data for each line is kept in two fatLine struct that are on the
	stack. bp points to the top of these structs and si and di are the
	offsets from bp to them. The struct that di refers to is the current
	line and si refers to the previous lines info. By current I mean the
	one being calculated, not the one to be drawn next. The previous line
	is drawn after the current one is calculated so that the joins can
	be drawn correctly.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	
FatLineLocal	struct			
    FLL_secondA	Point <> 	;basic four corners of fat line
    FLL_secondExtra	Point <>;used for beveled joins
    FLL_secondB	Point <>	;basic four corners of fat line
    FLL_firstB	Point <>	;basic four corners of fat line
    FLL_firstExtra	Point <>;used for beveled joins
    FLL_firstA	Point <> 	;basic four corners of fat line
    FLL_firstSeparator	word	?
    FLL_secondSeparator word	?
    FLL_origFirst	Point <>
    FLL_origSecond	Point <>
    FLL_deltaYInt	dw	?		;reduced delta y of orig line
    FLL_deltaYFrac	dw	?	
    FLL_deltaXInt	dw	?		;reduced delta x of orig line
    FLL_deltaXFrac	dw	?
    FLL_distanceInt	dw	?		;length of orig line
    FLL_distanceFrac	dw	?
    FLL_kdxInt		dw	(?)		;see BasicFatLineCalcs
    FLL_kdxFrac		dw	(?)
    FLL_kdyInt		dw	(?)		;see BasicFatLineCalcs
    FLL_kdyFrac		dw	(?)
    FLL_kdxHigh		dw	(?)		;see BasicFatLineCalcs
    FLL_kdxLow		dw	(?)
    FLL_kdyHigh		dw	(?)		;see BasicFatLineCalcs
    FLL_kdyLow		dw	(?)
    FLL_angleInt	dw	?		;angle of orig line
    FLL_angleFrac	dw	?
    FLL_sineInt		dw	?		;sine of angle above
    FLL_sineFrac	dw	?
    FLL_cosineInt	dw	?		;cosine of above angle
    FLL_cosineFrac	dw	?
    FLL_joinDeltaYInt	dw	?		;delta y to miter intersection
    FLL_joinDeltaYFrac	dw	?
    FLL_joinDeltaXInt	dw	?		;delta x to miter intersection
    FLL_joinDeltaXFrac	dw	?
FatLineLocal	ends


DFL_LocalRec RECORD DFL_unused:4,DFL_savedFirstB:1,DFL_connectionBeveled:1, DFL_firstLine:1, DFL_connected:1
	;DFL_connected - set if last point should be connected with first
	;DFL_firstLine - set if working on first line of poly line
	;DFL_connectionBeveled - set if join between connection line and first
	;	line is too acute to be mitered
	;DFL_savedFirstB - set if connection point saved was a B, otherwise A
	;		   was saved.

DFL_StackFrame		struct
    DFL_fatLineOne	FatLineLocal <>
    DFL_fatLineTwo	FatLineLocal <>
    DFL_gState		dw	(?)	;handle of GState
    DFL_attrOffset	dw	(?)	;offset to attributes to use
    DFL_firstPtOffset	dw	(?)	;offset to first point of list
    DFL_firstEndOffset	dw	?	;offset to first end of line
    DFL_secondEndOffset	dw	?	;offset to second end of line
    DFL_savedFirst	Point <>;used for connecting lines
    DFL_memHandle	dw	?	;handle of block contain points list
    DFL_hypoInt		dw	?	;temp variable used in miter calcs
    DFL_hypoFrac	dw	?
    DFL_halfCCWAngleDiffInt	dw	?
    DFL_halfCCWAngleDiffFrac	dw	?
    DFL_segment		dw	?
    DFL_flags		db	(?)	;a DFL_LocalRec
    DFL_wordAligned	db	(?)
DFL_StackFrame	ends

DFL_Local	equ	[bp - (size DFL_StackFrame)]
DFL_FLPrev	equ	DFL_Local[si]
DFL_FLCurr	equ	DFL_Local[di]

DoFatLinesLow	proc	near
	test	es:[W_grFlags], mask WGF_MASK_NULL	; see if null mask
	jnz	DFL_ret
	push	ax				; save attribute offset
	call	CheckForSpecialCases
	pop	ax
	jc	DFL_free			;nothing to draw
	mov	bp,sp
	sub	sp,size DFL_StackFrame		;create space for stack vars
	mov	ss:DFL_Local.DFL_segment,dx
	mov	ss:DFL_Local.DFL_memHandle,bx
	mov	ss:DFL_Local.DFL_firstPtOffset,si;for connection if needed
	mov	ss:DFL_Local.DFL_firstEndOffset,si
	add	si,size Point			;offset to second point
	mov	ss:DFL_Local.DFL_secondEndOffset,si
	mov	ss:DFL_Local.DFL_gState,ds
	mov	ss:DFL_Local.DFL_attrOffset,ax
	or	di,mask DFL_firstLine			;it's the first line
	test	di,mask DFL_connected
	mov	word ptr ss:DFL_Local.DFL_flags,di	;set connected flag
	mov	si,DFL_fatLineOne		;offset to fatline struct 
	mov	di,DFL_fatLineTwo		;offset to other fatline struct
	mov	ss:DFL_FLPrev.FLL_firstSeparator,SEPARATOR
	mov	ss:DFL_FLPrev.FLL_secondSeparator,SEPARATOR
	mov	ss:DFL_FLCurr.FLL_firstSeparator,SEPARATOR
	mov	ss:DFL_FLCurr.FLL_secondSeparator,SEPARATOR
	jz	DFL_20				;bra if not connected
	call	HandleFatPolyConnection
DFL_20:
	call	DrawFatPolyLine

	mov	bx,ss:DFL_Local.DFL_memHandle	;for freeing
	mov	ax,ss:DFL_Local.DFL_attrOffset	; restore attribute offset
	mov	sp,bp
DFL_free:
	tst	bx
	je	DFL_ret				;no block was allocated
	call	MemFree
DFL_ret:
	ret
DoFatLinesLow	endp
	


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckForSpecialCases
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks for consecutive duplicate points and some other
		special cases. If consecutive duplicate points are found
		the RemovePointRedundancies is called to handle it. Otherwise
		any corrections or rejections that need to made and can be
		made here are. 

CALLED BY:	INTERNAL
		DoFatLines
PASS:		
		cx -	number of points in polygon
		di -	0,1 1 - connect last point with first 0 - don't connect
		dx:si -	segment and offset to list of points
		es -	Window structure
		ds -	graphics state
RETURN:		
		dx:si - segment and offset to new points list
		cx - number of points in new list
		bx - handle of block points are in (block locked)
		     if no block created then bx = 0
		stc - don't draw anything
		di - may have been corrected ( see STRATEGY)
		es,ds - unchanged

DESTROYED:	
	ax,bx,bp

PSEUDO CODE/STRATEGY:
	
	If 0 or 1 point is passed then carry is set so that nothing is drawn
		
	If only two points are passed and they are the same then
		if BUTTCAP draw nothing
		otherwise draw normal, except no connection allowed (di=0)

	If more than two points are passed and consecutive duplicate points
	are found then RemovePointRedundancies is called. See its header.

	The following assume no consecutive duplicate points.

		If only two points are passed then draw normal

		If first point = last point and connection requested then
		ignore last point		

		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none	
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckForSpecialCases	proc	near
	cmp	cx,1
	jle	CFSC_100			;jmp if only 0 or 1 points
	push	ds,si,cx
	dec	cx				;number of comparisons
	mov	ds,dx				;segment of points
	lodsw					;save first point = last point
	push	ax				;check
	lodsw
	push	ax
	sub	si,4				;point back at first point
CFSC_10:
	lodsw					;get x
	mov	bx,ax				;save temp
	lodsw					;get y 
	cmp	ds:[si],bx			; cmp x with next x
	jne	CFSC_20				;jmp not consecutive duplicate
	cmp	ds:[si+2],ax			;cmp y with next y
	je	CFSC_120			;jump to SAME
CFSC_20:	
	loop	CFSC_10				;continue checking points
			;CHECK FOR FIRST = LAST
	pop	ax,bx				;recover first point
	pop	cx				;recover count
	tst	di				;if not connected no problem
	je	CFSC_30				;jmp if not connected
	cmp	ds:[si],ax			;check first x with last x
	jne	CFSC_30				;jmp if first <> last
	cmp	ds:[si+2],bx			;check first y with last y
	jne	CFSC_30				;jmp if first <> last
	dec	cx				;ignore last point
CFSC_30:
	pop	ds,si
CFSC_40:
	clr	bx				;return empty mem handle
	clc					;flag draw
	ret

CFSC_100:					; 0 or 1 points
	clr	bx				;no mem handle
	stc					;flag no draw
	ret
	
		;ONLY TWO POINTS AND THEY ARE THE SAME
CFSC_115:					
	cmp 	ds:[GS_lineEnd], LE_BUTTCAP
	je	CFSC_100			;butt cap so no draw
	clr	di				;no connection allowed 
	jmp	short	CFSC_40			;draw normal

		;FOUND DUPLICATE CONSECUTIVE POINTS
CFSC_120:
	pop	ax,bx				;recover first point
	dec	cx				;number points after duplicate
	mov	bp,cx				;pass in bp to RPR
	pop	ds,si,cx
	cmp	cx,2
	je	CFSC_115			;jmp if two points

	FALL_THRU	RemovePointRedundancies			

CheckForSpecialCases	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemovePointRedundancies
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes copy of points list and removes consecutive occurrences
		of points and handle special cases


CALLED BY:	INTERNAL
		RemovePointRedundancies
PASS:		
		ax,bx	x,y of first point
		cx -	number of points in polygon
		bp - 	number of points after duplicate
		di -	0,1 1 - connect last point with first 0 - don't connect
		dx:si -	segment and offset to list of points
		es -	Window structure
		ds -	graphics state
RETURN:		
		dx:si - segment and offset to new points list
		bx - handle of block points are in (block unlocked)
		cx - number of points in new list
		stc - don't draw anything
		es,ds,di - unchanged
DESTROYED:	
	ax,bx,bp

PSEUDO CODE/STRATEGY:
	After removing redundant points:

	Special Case 1. Last point = first point on connected poly
	Solution - ignore last point

	Special Case 2. Line with only two points that are same
	and butt cap.
	Solution - return carry set to signal do nothing

	Special Case 3. Line with only two points that are same
	and they are connected and not butt cap
	Solution - draw unconnected
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	if there are almost 64k worth of points then I will try to allocate
	more than 64k and bad things will happen		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RPR_LocalVars	struct
	RPR_firstPoint	Point <>;temp storage
	RPR_numPoints	dw	?		;num points that will be in 
						;new list
	RPR_remPoints	dw	?		;remaining points in old list
	RPR_memHandle	dw	?
	RPR_connected	db	?		;non-zero if connected
	RPR_wordAlign	db	?
RPR_LocalVars	ends

RemovePointRedundancies		proc	near
	push	es				;don't destroy
	push	ax,bx,cx
	shl	cx,1				;num bytes occupied by points
	shl	cx,1
	add	cx,size RPR_LocalVars
	mov	ax,cx
	mov	cx,ALLOC_DYNAMIC_NO_ERR or ( mask HAF_LOCK shl 8 )
	call	MemAllocFar
	mov	es,ax				;dest list seg from MemAlloc
	mov	es:RPR_memHandle,bx
	pop	ax,bx,cx
	push	ds				;save gstate
	mov	ds,dx				;src list
	mov	word ptr es:RPR_connected,di
	mov	di,size RPR_LocalVars		;offset into dest list
	mov	es:RPR_firstPoint+P_x,ax	;save for later
	mov	es:RPR_firstPoint+P_y,bx	;save for later
	dec 	cx
	mov	es:RPR_numPoints,cx		;one less point in new list
	mov	es:RPR_remPoints,bp		
	sub	cx,bp				;number of points to move
	shl	cx,1				;number of words to move
	rep	movsw
	tst	bp				;are there any remaining pts
	je	RPR_16				;jmp if no
	lodsw					;don't repeat this point
	mov	cx,ax
	lodsw	
	mov	dx,ax
RPR_2:
	lodsw					;get next x
	mov	bx,ax				;save next x
	lodsw					;get next y
	cmp	dx,ax				;compare y's
	jne	RPR_5
	cmp	cx,bx				;compare x's
	je	RPR_10
RPR_5:				;NOT SAME POINT,store point in new list
	xchg 	ax,bx				;becomes x,y
	stosw					;store x
	xchg	ax,bx				;becomes y,x
	stosw					;store y
	mov	dx,ax				;new non-repeatable point
	mov	cx,bx
	jmp	short	RPR_15
RPR_10:				;SAME POINT
	dec	es:RPR_numPoints		;1 less pt will be in new list
RPR_15:
	dec 	es:RPR_remPoints		;1 less pt in old list
	jne	RPR_2				;continue if remaining points
RPR_16:
	pop	ds				;recover GState
	cmp	es:RPR_numPoints,1
	ja	RPR_20				;jmp if stored at least 2 pts
						;in new list
			;ONLY TWO POINTS AND THEY ARE THE SAME
	mov	cl,ds:[GS_lineEnd]
	cmp	cl, LE_BUTTCAP
	je	RPR_18				;jmp if Special Case 2
	inc	es:RPR_numPoints
	xchg 	ax,bx				;only one point in new list
	stosw					;store last to make two
	xchg	ax,bx
	stosw			
	clr	es:RPR_connected		;no connection allowed SC3
	jmp	short	RPR_30		
RPR_18:				;SPECIAL CASE 2
	stc					;flag don`t draw anything
	jc	RPR_60		
RPR_20:				;CHECK FOR SPECIAL CASE 1
	tst	es:RPR_connected
	je	RPR_30				;poly not connected so no prob
	cmp	cx,es:RPR_firstPoint+P_x
	jne	RPR_30				;jmp if no connection problem
	cmp	dx,es:RPR_firstPoint+P_y
	jne	RPR_30				;jmp if no connection problem
	dec	es:RPR_numPoints		;don't include last point
RPR_30:

	clc					;flag to draw stuff
RPR_60:
;	pushf					;save returning carry flag
	mov	bx,es:RPR_memHandle
;	call	MemUnlock
	mov	cx,es:RPR_numPoints
	mov	di,word ptr es:RPR_connected
	mov	dx,es				;dx - segment of points
	mov	si,size RPR_LocalVars		;offset to points
;	popf
	pop	es
	ret
RemovePointRedundancies	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFatPolyLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Controlling routine for DrawFatPolyLineLow. It loops once
		for each line calling DrawFatPolyLineLow, handles converting
		current line info into prev line info and takes care of
		the connecting line in connected polygons.

CALLED BY:	INTERNAL
		DoFatLines

PASS:		
	DFL_Local (see structure definition)
	cx -	number of points in polygon
	es -	Window structure
	ds -	graphics state
	if its a connected line then
	DFL_FLCurr - FatLineLocal struct with connecting line info
	bp,di,si ( see equates for DFL_Local, DFL_FLCurr )
RETURN:		
	nothing

DESTROYED:	
	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:
	For connected fat lines any given line cannot be drawn unless
	the information for the next line has been calculated. So the
	drawing is one step out of phase with the calculations.

	The calcs for each end of the line a done separately. The second end is
	pretty boring, usually just a butt cap is created. The first end
	calculations must also modify the information stored for the
	second end of the previous line to form the join correctly.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFatPolyLine	proc 	near
DFPL_0:
	xchg	si,di				;make curr into prev
	call	DrawFatPolyLineLow
	dec	cx				;number of points left to draw
	cmp	cx,1		
	ja	DFPL_0				;jmp if at least 2 points left
	jb	DFPL_90				;if no points then connection 
						;already drawn so jmp
	test	ss:DFL_Local.DFL_flags, mask DFL_connected 
	jz	DFPL_90				;if unconnected skip to end
	mov	bx,ss:DFL_Local.DFL_firstPtOffset;make original first point
	mov	ss:DFL_Local.DFL_secondEndOffset,bx;2nd point of connect line
	jmp	short DFPL_0			;draw connecting line segment
DFPL_90:
	xchg	di,si				;make curr into prev for 
	call	DrawFatLineReg			;drawing the last guy
	ret
DrawFatPolyLine		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleFatPolyConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the Butt Cap information for the connecting
		line (last point to first point) of the polygon.
		 This allows the join between the
		connecting line and the first line to drawn correctly

CALLED BY:	INTERNAL
		DoFatLines
PASS:		
	DFL_Local ( see structure definition )
	DFL_FLCurr ( see structure definition )
	cx - number of points in points array
	es -	Window structure
	ds -	graphics state
	bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
RETURN:		
	DFL_FLCurr - has connecting line information

DESTROYED:	
	ax,bx,dl

PSEUDO CODE/STRATEGY:
	see STRATEGY for DrawFatPolyLine		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleFatPolyConnection		proc	near
	mov	ax,DFL_Local.DFL_secondEndOffset
	mov	bx,DFL_Local.DFL_firstEndOffset	
	push	ax,bx				;save original values
	mov	DFL_Local.DFL_secondEndOffset,bx;first point in list is
						;2nd of connection line
	mov	ax,cx				;make ax offset to last point
	dec	ax				;(numPoints-1) *
	shl	ax, 1				;(size Point) +
	shl	ax, 1
	add	ax,bx				;orig offset
	mov	DFL_Local.DFL_firstEndOffset,ax	;first point of connection
	call	BasicFatLineCalcs
	mov	dl,MEC_SECOND			;do join stuff for second end
	call	CalcJoin
	pop	ax,bx
	mov	DFL_Local.DFL_firstEndOffset,bx	;original values
	mov	DFL_Local.DFL_secondEndOffset,ax
	ret
HandleFatPolyConnection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFatPolyLineLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does calculations for current line, uses some of that
		info to complete the definition of the previous line and
		then draw the previous line segment. The segment is drawn
		with half the joining stuff between it and it's previous
		line and half the joining stuff between it and the current
		line.

CALLED BY:	INTERNAL
		DrawFatPolyLine
PASS:		
	DFL_Local ( see structure definition )
	DFL_FLPrev ( see structure definition )
	DFL_FLCurr ( see structure definition )
	ds - GState
	bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
RETURN:		
	DFL_FLCurr - line terminated with a butt cap, unless it's the last
	line to be drawn.

DESTROYED:	
	ax,bx,dx

PSEUDO CODE/STRATEGY:
	See STRATEGY for DrawFatPolyLine		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFatPolyLineLow	proc 	near
	call	BasicFatLineCalcs
	
				;DEFINE FIRST END OF LINE SEGMENT
	mov	dl,MEC_FIRST		
	mov	dh,ss:DFL_Local.DFL_flags
	test	dh,mask DFL_connected
	jnz	DFPLL_10			;bra if connected to do join
	test	dh, mask DFL_firstLine
	jz	DFPLL_10			;bra if not first line
						;first line of unconnected poly
	call	MakeEndCap			;so give it proper end cap
	jmp	short	DFPLL_20
DFPLL_10:
	call	CalcJoin			;otherwise it must be joined

DFPLL_20:			;DEFINE SECOND END OF LINE SEGMENT
	mov	dl,MEC_SECOND
	test	ss:DFL_Local.DFL_flags,mask DFL_connected
	jnz	DFPLL_30			;bra if connected to do join
	cmp	cx,2
	jne	DFPLL_30			;jmp if not last line
						;last line of unconnected poly
	call	MakeEndCap			;so give it proper end cap
	jmp	short	DFPLL_40
DFPLL_30:
	call	CalcJoin
DFPLL_40:
	test	ss:DFL_Local.DFL_flags, mask DFL_firstLine
	jnz	DFPLL_50			;don't draw first line
	call	DrawFatLineReg			;draw previous line
DFPLL_50:
	and	ss:DFL_Local.DFL_flags,not mask DFL_firstLine;no longer first
	ret
DrawFatPolyLineLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BasicFatLineCalcs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the endpoints and the width for a fat line it
		calculates the delta x (kdx) and delta y (kdy) values between
		the corners on one end of the fat line. Then each delta value
		is split into two integer values High and Low
		with |High|>=|Low|. All this information is returned in
		a FatLine_Local structure

		|kdx-|	_
		/\	|
	       /  \	kdy
	      /	  /\	|
	     /	 /  \	_
		/   /	
	       /   /
	      /	  /
	     /
CALLED BY:	INTERNAL
		HandleFatPolyConnection
		DrawFatPolyLineLow

PASS: 		DFL_FLCurr ( see structure definition )
		DFL_Local ( see structure definition )
		bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
RETURN:		
		DFL_Local.firstEndOffset - next point
		DFL_Local.secondEndOffset - next point
			
DESTROYED:	
		ax,bx,dx

PSEUDO CODE/STRATEGY:
	We need four points. Two are on one end of the line and two on the
	other. On either end the two points lie on a line perpendicular to 
	the original line.  We know the slope of the crossing line, it is
	merely the inverse slope of the original line. Because of this 
	the routine calculates delta x from the y coords and vice versa.
	dx - means delta y of original line
	dy - means delta x of original line
	k=(width)/(dx^2+dy^2)
	k*dx = x distance to corner of fat line from other corner
	k*dy = y distance to corner of fat line from other corner

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BasicFatLineCalcs	proc	near
	push	cx,si				;don't destroy 
	mov	si,DFL_Local.DFL_firstEndOffset	;si - offset to first point

	mov	ds,ss:DFL_Local.DFL_segment
;	mov	bx,ss:DFL_Local.DFL_memHandle
;	call	MemLock				;lock points list block 
;	mov	ds,ax				;put segment in ds

;save initial points in fatline struct and in registers for internal use
;cx = first x, dx = first y, ax = 2nd x, bx = 2nd y
	lodsw				
	mov	cx,ax				;put first x coord in cx
	lodsw
	mov	dx,ax				;put first y coord in dx
	mov	DFL_Local.DFL_firstEndOffset,si
	mov	si,DFL_Local.DFL_secondEndOffset;si offset to second point
	lodsw
	mov	bx,ax
	lodsw
	xchg	ax,bx				;ax = x coord, bx = y coord
	mov	DFL_Local.DFL_secondEndOffset,si

;	push	bx,ax				;unlock list of points block
;	mov	bx,ss:DFL_Local.DFL_memHandle	;without destroying anything
;	call	MemUnlock
;	pop	bx,ax

	mov	ds,ss:DFL_Local.DFL_gState	;put GState back in ds

;IF	USETESTLINES
;	call	GrTransCoord2
;ENDIF
			
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_x,cx	;store initial points
	mov	ss:DFL_FLCurr.FLL_origFirst+P_x,cx
	mov	ss:DFL_FLCurr.FLL_firstA+P_x,cx		;in FatLine_Local struct
	mov	ss:DFL_FLCurr.FLL_firstB+P_x,cx
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_y,dx
	mov	ss:DFL_FLCurr.FLL_origFirst+P_y,dx
	mov	ss:DFL_FLCurr.FLL_firstA+P_y,dx
	mov	ss:DFL_FLCurr.FLL_firstB+P_y,dx
	mov	ss:DFL_FLCurr.FLL_secondExtra+P_x,ax
	mov	ss:DFL_FLCurr.FLL_origSecond+P_x,ax
	mov	ss:DFL_FLCurr.FLL_secondA+P_x,ax
	mov	ss:DFL_FLCurr.FLL_secondB+P_x,ax
	mov	ss:DFL_FLCurr.FLL_secondExtra+P_y,bx
	mov	ss:DFL_FLCurr.FLL_origSecond+P_y,bx
	mov	ss:DFL_FLCurr.FLL_secondA+P_y,bx
	mov	ss:DFL_FLCurr.FLL_secondB+P_y,bx

IF	0	;USETESTLINES	
		;draw original line for testing
	push	ax,bx,cx,dx,si			;save it
	push	di,bp
	call	DrawLine
	pop	di,bp
	pop	ax,bx,cx,dx,si
ENDIF
	xchg	ax,cx				;make subn second - first
	xchg	bx,dx
	sub	dx,bx				;calc delta x from y's 
	sub	cx,ax				;calc delta y from x's 
	mov	bx,cx				;put delta y in bx, trust me
	mov	si, ds:[GS_scaledLineWid]		;get line width (no hooey)
	dec	si
	clr	ax				;need for later, but useful now
	clr	cx				;trust me
	mov	ss:DFL_FLCurr.FLL_kdxFrac,ax	;fracs set to zero, because
	mov	ss:DFL_FLCurr.FLL_kdyFrac,ax	;ints maybe set if line is
	mov	ss:DFL_FLCurr.FLL_angleFrac,ax	;horiz or vert
	mov	ss:DFL_FLCurr.FLL_sineFrac,ax
	mov	ss:DFL_FLCurr.FLL_cosineFrac,ax
	mov	ss:DFL_FLCurr.FLL_angleInt,0ffffh	;mark as not calculated

		;SEE IF ORIGINAL LINE IS HORIZONTAL OR VERTICAL
	tst	dx				;check delta y of orig line
	je	BFLC_10				;bra if horizontal
	tst	bx				;check delta x of orig line
	jne	BFLC_23				;bra if not vertical
				;VERTICAL
	xchg	ax,si				;makes ax= width, si=0
	mov	ss:DFL_FLCurr.FLL_cosineInt,0
	tst	dx		
	jns	BFLC_5				;bra if orig line drawn down
	neg	ax				;for upward line, kdx < 0
	mov	ss:DFL_FLCurr.FLL_angleInt,90
	mov	ss:DFL_FLCurr.FLL_sineInt,1
	jmp	short	BFLC_16
BFLC_5:						;downward line
	mov	ss:DFL_FLCurr.FLL_angleInt,270	
	mov	ss:DFL_FLCurr.FLL_sineInt,-1
	jmp	short	BFLC_16			;skip calc
BFLC_10:			;HORIZONTAL
	mov	ss:DFL_FLCurr.FLL_sineInt,0
	tst	bx
	jns	BFLC_15				;bra if orig line drawn right
	neg	si				;for leftward , kdy < 0
	mov	ss:DFL_FLCurr.FLL_angleInt,180	
	mov	ss:DFL_FLCurr.FLL_cosineInt,-1
	jmp	short	BFLC_16
BFLC_15:					;rightward drawn line
	mov	ss:DFL_FLCurr.FLL_angleInt,0	
	mov	ss:DFL_FLCurr.FLL_cosineInt,1
BFLC_16:
	mov	ss:DFL_FLCurr.FLL_kdyInt,si	
	mov	ss:DFL_FLCurr.FLL_kdxInt,ax	
	jmp	BFLC_45			;skip calc of kdx,kdy
BFLC_23:
	;must reduce delta x and y to below 182 so that the sum of 
	;squares will not by greater than 65535
BFLC_25:
	cmp	bx,MAX_DELTA
	jg	BFLC_30				;bra to reduction delta > 181 
	cmp	bx,-MAX_DELTA
	jl	BFLC_30				;bra to reduction delta < -181
	cmp	dx,MAX_DELTA
	jg	BFLC_30				;bra to reduction delta > 181
	cmp	dx,-MAX_DELTA
	jg	BFLC_40				;bra past reduction delta> -181
BFLC_30:
	sar	bx,1				;divde both deltas by 2
	rcr	ax,1				;for reduction
	sar	dx,1
	rcr	cx,1
	jmp	short	BFLC_25			;continue reduction process
BFLC_40:
	mov	ss:DFL_FLCurr.FLL_deltaYInt,dx	;delta y of orig line 
	mov	ss:DFL_FLCurr.FLL_deltaYFrac,cx
	mov	ss:DFL_FLCurr.FLL_deltaXInt,bx	;delta x of orig line
	mov	ss:DFL_FLCurr.FLL_deltaXFrac,ax
	call	GrSqrWWFixed			;square delta x
	xchg	ax,cx				;make bx:ax delta x squared
	xchg	bx,dx				;and dx:cx is delta y
	call	GrSqrWWFixed			;square delta y -> dx:cx
	add	cx,ax				;add frac of squared deltas
	adc	dx,bx				;add integer of squared deltas
	call	GrSqrRootWWFixed
	mov	ss:DFL_FLCurr.FLL_distanceInt,dx
	mov	ss:DFL_FLCurr.FLL_distanceFrac,cx
	mov	ax,cx				;make sqrt(dx^2+dy^2) 
	mov	bx,dx				;the divisor
	mov	dx,si				;put width in dx:cx
	clr	cx
	call	GrUDivWWFixed			;calculate k in dx:cx
	mov	ax,cx				;make k multiplier
	mov	bx,dx			;
	mov	dx,ss:DFL_FLCurr.FLL_deltaYInt
	mov	cx,ss:DFL_FLCurr.FLL_deltaYFrac
	call	GrMulWWFixed			;calc kdx -> dx:cx
	mov	ss:DFL_FLCurr.FLL_kdxInt,dx
	mov	ss:DFL_FLCurr.FLL_kdxFrac,cx
	mov	dx,ss:DFL_FLCurr.FLL_deltaXInt
	mov	cx,ss:DFL_FLCurr.FLL_deltaXFrac
	call	GrMulWWFixed			;calc kdy -> dx:cx
	mov	ss:DFL_FLCurr.FLL_kdyInt,dx
	mov	ss:DFL_FLCurr.FLL_kdyFrac,cx
BFLC_45:					
			;CALC HIGH AND LOW VALUES FOR X
	mov	bx,ss:DFL_FLCurr.FLL_kdxInt
	mov	ax,ss:DFL_FLCurr.FLL_kdxFrac
	Round	bx,ax				;round initial kdx
	mov	cx,bx				;save rounded value
	clr	ax				;divide rounded value by two 
	sar	bx,1				;to get unrounded high value
	rcr	ax,1
	Round	bx,ax				;rounded high
	sub	cx,bx				;sub High from initial 
						; rounded to get Low
	mov	ss:DFL_FLCurr.FLL_kdxHigh,bx
	mov	ss:DFL_FLCurr.FLL_kdxLow,cx

			;CALC HIGH AND LOW VALUES FOR Y
	mov	dx,ss:DFL_FLCurr.FLL_kdyInt
	mov	ax,ss:DFL_FLCurr.FLL_kdyFrac
	Round	dx,ax				;round initial kdy
	mov	cx,dx				;save rounded value
	clr	ax				;divide rounded value by two 
	sar	dx,1				;to get unrounded high value
	rcr	ax,1
	Round	dx,ax				;rounded high
	sub	cx,dx				;sub High from initial rounded
						; to get Low
	mov	ss:DFL_FLCurr.FLL_kdyHigh,dx
	mov	ss:DFL_FLCurr.FLL_kdyLow,cx

	pop	cx,si
	ret
BasicFatLineCalcs	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawFatLineReg
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the region defined by the FatLineLocal struct at
		DFL_FLPrev with the current lineJoin type

CALLED BY:	DrawFatPolyLineLow

PASS:		DFL_FLPrev  ( see structure definition )
		ds - GState
		es - Window
		bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
RETURN:		
	nothing

DESTROYED:	
	ax,bx,dx

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawFatLineReg	proc	near
	push	cx,si,di,bp,ds			;save the ship
	cmp	ds:[GS_lineJoin], LJ_MITERED
	jne	DFLR_draw
	call	HandleMiteredConnection	
DFLR_draw:

IF USETESTLINES
	call	DrawMyLines
ELSE
	mov	ax, si
	mov	si, ss:DFL_Local.DFL_attrOffset ; get offset to attributes
	add	ax, bp				;point si to points in
	sub	ax, size DFL_StackFrame		;FatLineLocal struct
	mov	bx, 1				;num disjoint polylines
	mov	cx, 6				;number of points
	mov	di, ss				;segment of array
	mov	dx, RFR_ODD_EVEN
	call	DrawPolygonAfterTrans
ENDIF
	pop	cx,si,di,bp,ds
	ret	
DrawFatLineReg	endp
	





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		HandleMiteredConnection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It checks to see if we are drawing the connecting
		line of a closed polygon and substitutes in previously
		saved points to form the join correctly. It also checks
		to see if the connecting join needs to be drawn beveled
		and if so it changes nothing

CALLED BY:	INTERNAL
		DrawFatLineReg
PASS:		
	DFL_Local ( see structure definition )
	DFL_FLPrev ( see structure definition )
	ds - GState
	es - Window Structure 		
	cx - number of points remaining to draw
	bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
RETURN:		
	DFL_FLPrev - may have been changed

DESTROYED:	
	bx,dx

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 2/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
HandleMiteredConnection	proc	near
	tst	cx
	jne	HMC_ret					;skip if not drawing 
							; connecting line

	test	ss:DFL_Local.DFL_flags, mask DFL_connectionBeveled
	jne	HMC_ret					;skip if connection
							; join was beveled
	
	mov	dx,ss:DFL_Local.DFL_savedFirst+P_x	;join points from
	mov	bx,ss:DFL_Local.DFL_savedFirst+P_y

	test	ss:DFL_Local.DFL_flags, mask DFL_savedFirstB
	jnz	HMC_10
	mov	ss:DFL_FLPrev.FLL_secondA+P_x,dx	;first end of
	mov	ss:DFL_FLPrev.FLL_secondExtra+P_x,dx	;first line drawn
	mov	ss:DFL_FLPrev.FLL_secondA+P_y,bx
	mov	ss:DFL_FLPrev.FLL_secondExtra+P_y,bx
	jmp	short	HMC_ret
HMC_10:
	mov	ss:DFL_FLPrev.FLL_secondB+P_x,dx
	mov	ss:DFL_FLPrev.FLL_secondB+P_y,bx

HMC_ret:
	ret
HandleMiteredConnection		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcJoin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	Calculates the points at either end of a fat line to
		form the join correctly with the preceding or next line
PASS:		
	DFL_FLPrev  ( see structure definition )
	DFL_FLCurr ( see structure definition )
	ds - GState
	es - Window Structure 		
	dl - MEC_FIRST or MEC_SECOND
	bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
RETURN:		
	nothing

DESTROYED:	
	ax,bx,dx

PSEUDO CODE/STRATEGY:
	none		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
 	none
REVISION HISTORY:
 	Name	Date		Description
 	----	----		-----------
	srs	4/13/89		Initial version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcJoin	proc	near
	push	cx,di,si,bp
	call	MakeButtCap
	tst	dl
	jns	CJ_end				;just do butt cap if second end
	mov	dh,ds:[GS_lineJoin]
	cmp	dh, LJ_BEVELED
	je	CJ_100
	cmp	dh, LJ_ROUND
	je	CJ_120
	call	CalcMiteredJoin		
CJ_end:
	pop	cx,di,si,bp
	ret

CJ_100:
	call	CalcBeveledJoin
	jmp	short	CJ_end

CJ_120:
	mov	dl,MEC_FIRST			;put round cap on first
	call	DrawRoundCap			;end of current line to
	jmp	short	CJ_end			;make the join

CalcJoin		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcBeveledJoin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For the first end of a line its butt cap has just been calced
		so it exchanges info between curr and prev FatLine_Local
		strucs needed to draw beveled edge correctly. In the case
		of the first line it flags it as beveled so that the 
		connecting line will be drawn correctly. This only matters
		when the join type is miter, but the angle between the first
		line and the connecting line is too acute to be drawn beveled.

CALLED BY:	INTERNAL
		CalcJoin

PASS:		
	DFL_FLPrev (read structure definitions)
	DFL_FLCurr (read structure definitions)
	si,di	- (see equates for DFL_FLPrev and DFL_FLCurr)

RETURN:		
	modified FatLine_Local strucs

DESTROYED:	
	ax,bx

PSEUDO CODE/STRATEGY:
	 
	A beveled join is formed by drawing a line between the corner of a
	fat lines second end and a corner of the first end of the next line.
	Because of the way I calculate points, either secondA is connected
	to firstA or secondB to firstB. If the counter clockwise angle between
	the two lines ( see CalcCCWAngleDiff ) is less than 180 degrees then
	the B points are connected, otherwise its the A. Trust Me. When a 
	beveled line is drawn its first end is connected to the previous
	line's second end, but its second end is just drawn with
	a butt cap.


KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcBeveledJoin		proc	near
	test	ss:DFL_Local.DFL_flags,mask DFL_firstLine
	jz	CBJ_30					;bra if not first line
	or	ss:DFL_Local.DFL_flags,mask DFL_connectionBeveled
CBJ_30:
	call	CalcCCWAngleDiff
	cmp	dx,180				;check CCW angle diff	
	jg	CBJ_40

	mov	ax,ss:DFL_FLPrev.FLL_secondB+P_x	;make prev secondB into
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_x,ax	;curr firstExtra
	mov	ax,ss:DFL_FLPrev.FLL_secondB+P_y
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_y,ax
	jmp	short	CBJ_ret
CBJ_40:
	mov	ax,ss:DFL_FLPrev.FLL_secondA+P_x	;make prev secondA into
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_x,ax	;curr firstExtra
	mov	ax,ss:DFL_FLPrev.FLL_secondA+P_y
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_y,ax
	
CBJ_ret:
	ret
CalcBeveledJoin		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckMiterLimit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines if the angle between the joined fat lines is
		to small to do a miter join

CALLED BY:	INTERNAL
		CalcMiterJoin

PASS:		
		dx:ax	- counter clockwise angle between the two lines
		ds	- graphics state
RETURN:		
		stc	- angle two small	
		clc	- no problem bob
DESTROYED:	
		bx,cx
	
PSEUDO CODE/STRATEGY:
	
	According to Adobe if 1/(sin(a/2)) > miterlimit then the join
	should be a bevel instead of miter. ( a = angle between the two
	lines). For speeds sake i store then inverted miterlimit in
	the GState and if sin(a/2) < 1/miterlimit then do bevel.

	Note that the angle passed is the counter clockwise difference between
	the angle of the two lines (see CalcMiteredJoin), but the angle used
	here is the smallest angle between the lines as they are drawn. This
	angle is 0 if the lines are identical and can be as much as 180 if
	the second line continues with the same slope as the first line.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/ 3/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckMiterLimit	proc	near
	push	dx,ax					;save passed angle
	cmp	ds:[GS_inverseMiterLimit],0ffffh	
	je	CML_110					;special case, no miter
		;CONVERT PASSED ANGLE TO ANGLE BETWEEN LINES
	cmp	dx,180
	jnb	CML_10
	mov	bx,180					;if angle < 180 then
	clr	cx
	sub	cx,ax					;180-angle
	sbb	bx,dx
	mov	ax,cx					;keep info in dx:ax
	mov	dx,bx
	jmp	short	CML_20
CML_10:							;if angle >= 180 then
	sub	dx,180					;angle - 180
CML_20:
	sar	dx,1					;need angle/2
	rcr	ax,1
	call	GrQuickSine
	tst	dx		
	jns	CML_25
	NegateFixed	dx,ax				;force sine positive
CML_25:
	cmp	dx,1			
	jne	CML_100			;jmp if sine <> 1	
	clc				;if sine = 1 then sine > inverse limit
					;flag do miter
CML_50:
	pop	dx,ax
	ret

CML_100:
	cmp	ax,ds:[GS_inverseMiterLimit]
	ja	CML_50					;ja means carry clear
CML_110:
	stc						;flag bevel
	jmp	CML_50

CheckMiterLimit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcMiteredJoin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For the first end of the current line it calculates the
		point which forms a mitered join between two
		fat line segments. This point is then stored in the
		second point info for the prev line and the first point
		info for the current line. This routine is only called for the
		first end of the line segment. The second end always has a
		butt cap put on it. That butt cap info is used by the next
		line to enter this routine to calculate the join points.
		

CALLED BY:	INTERNAL
		DrawFatLineReg
PASS:		
	DFL_FLPrev  (read structure definitions)
	DFL_FLCurr  (read structure definitions)
	si,di,bp - (see equates for DFL_FLPrev and DFL_FLCurr)
	ds - GState
	es - Window Structure 		
	dl - MEC_FIRST or MEC_SECOND
RETURN:		
	both DFL_FLPrev and DFL_FLCurr strucs have been modified to include
	points for miter join and line angles and other stuff.

DESTROYED:	
	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
	A miter join is formed by allowing the "outside edge" of each
	fat line to continue until they intersect. This forms a diamond
	shape region which is filled to form the join. Because of the
	way that I calculated the corners of my fat lines, either the
	outside edges formed by the B points of each line will be intersected
	or the outside edges formed by the A points will be intersected, but
	never B to A. The pair of lines connected is determined by the
	counter-clockwise angle between the two lines. If the angle is
	less than 180 degrees the B's are used, otherwise it's the A's

	The calculations to determine the intersection are very obscure.
	If you really want to know, here are the basic equations
	but you really need the diagram to understand what they mean.
	a - angle between the lines
	b - angle of previous line
	c - angle of current line
	w - width of lines
	y' = w/2*sin(a/2)
	r = y'/cos(a/2) - hypo - distance from fat line corner to intersect pt
	prevY'' = r*sin(b) - delta y to intersection point from prev corner
	prevX'' = r*cos(b) - delta x to intersection point from prev corner
	currY'' = r*sin(c) - delta y to intersection point from curr corner
	currX'' = r*cos(c) - delta x to intersection point from curr corner

	The last four points are added or subtracted as needed from the
	the proper corners to get the intersection point. But each
	intersection point is calculated from both lines and the resulting
	points are averaged to get the final intersection  point.

	The firstExtra and secondExtra points are set to the calculated
	intersection points so that the same drawing routine can be used
	for beveled lines which need 6 point and miters which only need
	4 points.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcMiteredJoin		proc	near
	call	CalcCCWAngleDiff
	call	CheckMiterLimit
	jnc	CMJ_25				;jmp if angle not too acute
	call	CalcBeveledJoin
	jmp	CMJ_ret
CMJ_25:
	shr	dx,1				;need half of angle
	rcr	ax,1
	mov	DFL_Local.DFL_halfCCWAngleDiffInt,dx
	mov	DFL_Local.DFL_halfCCWAngleDiffFrac,ax
	call	GrQuickSine			;sine in dx:ax
	mov	bx,ds:[GS_scaledLineWid]
	dec	bx
	clr	cx
	shr	bx,1				;width/2 in bx:cx
	rcr	cx,1
	xchg	ax,cx				;for mul
	call	GrMulWWFixed			;(w/2)(sin(a/2))=y' in dx:cx
	push	dx,cx				;save y'
	mov	dx,DFL_Local.DFL_halfCCWAngleDiffInt
	mov	ax,DFL_Local.DFL_halfCCWAngleDiffFrac
	call	GrQuickCosine			;in dx:ax
	pop	bx,cx				;y'
	xchg	bx,dx				;y' in dx:cx, cos(a/2) in bx:ax
	call	GrSDivWWFixed			;hypotenuse in dx:cx
	mov	ss:DFL_Local.DFL_hypoInt,dx
	mov	ss:DFL_Local.DFL_hypoFrac,cx

	mov	bx,ss:DFL_FLPrev.FLL_sineInt	;prev angle b
	mov	ax,ss:DFL_FLPrev.FLL_sineFrac	;prev angle b
	call	GrMulWWFixed			;y''=sin(b)*hypo in dx:cx
	mov	ss:DFL_FLPrev.FLL_joinDeltaYInt,dx
	mov	ss:DFL_FLPrev.FLL_joinDeltaYFrac,cx

	mov	bx,ss:DFL_FLPrev.FLL_cosineInt	;prev angle
	mov	ax,ss:DFL_FLPrev.FLL_cosineFrac	;prev angle
	mov	dx,ss:DFL_Local.DFL_hypoInt
	mov	cx,ss:DFL_Local.DFL_hypoFrac
	call	GrMulWWFixed			;x'' in dx:cx
	mov	ss:DFL_FLPrev.FLL_joinDeltaXInt,dx
	mov	ss:DFL_FLPrev.FLL_joinDeltaXFrac,cx

	mov	bx,ss:DFL_FLCurr.FLL_sineInt	;cur angle c
	mov	ax,ss:DFL_FLCurr.FLL_sineFrac	;cur angle c
	mov	dx,ss:DFL_Local.DFL_hypoInt
	mov	cx,ss:DFL_Local.DFL_hypoFrac
	call	GrMulWWFixed			;y''=sin(c)*hypo in dx:cx
	mov	ss:DFL_FLCurr.FLL_joinDeltaYInt,dx
	mov	ss:DFL_FLCurr.FLL_joinDeltaYFrac,cx

	mov	bx,ss:DFL_FLCurr.FLL_cosineInt	;cur angle
	mov	ax,ss:DFL_FLCurr.FLL_cosineFrac	;cur angle
	mov	dx,ss:DFL_Local.DFL_hypoInt
	mov	cx,ss:DFL_Local.DFL_hypoFrac
	call	GrMulWWFixed			;x'' in dx:cx
	mov	ss:DFL_FLCurr.FLL_joinDeltaXInt,dx
	mov	ss:DFL_FLCurr.FLL_joinDeltaXFrac,cx

	cmp	DFL_Local.DFL_halfCCWAngleDiffInt,90
	jle	CMJ_30
	jmp	CMJ_50
CMJ_30:	
	mov	dx,ss:DFL_FLPrev.FLL_secondB+P_y
	clr	cx
	sub	cx,ss:DFL_FLPrev.FLL_joinDeltaYFrac
	sbb	dx,ss:DFL_FLPrev.FLL_joinDeltaYInt

	mov	bx,ss:DFL_FLCurr.FLL_firstB+P_y
	mov	ax,ss:DFL_FLCurr.FLL_joinDeltaYFrac
	add	bx,ss:DFL_FLCurr.FLL_joinDeltaYInt			

	Average	bx,ax,dx,cx
	push	bx				;save averaged y value

	mov	dx,ss:DFL_FLPrev.FLL_secondB+P_x
	mov	cx,ss:DFL_FLPrev.FLL_joinDeltaXFrac
	add	dx,ss:DFL_FLPrev.FLL_joinDeltaXInt	;intersect delta x

	mov	bx,ss:DFL_FLCurr.FLL_firstB+P_x
	clr	ax
	sub	ax,ss:DFL_FLCurr.FLL_joinDeltaXFrac
	sbb	bx,ss:DFL_FLCurr.FLL_joinDeltaXInt;intersect delta x in bx:ax

	Average	bx,ax,dx,cx				;average x in bx

	mov	ss:DFL_FLPrev.FLL_secondB+P_x,bx
	mov	ss:DFL_FLCurr.FLL_firstB+P_x,bx
	mov	ss:DFL_FLPrev.FLL_secondExtra+P_x,bx
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_x,bx
	pop	cx					;retrieve average y
	mov	ss:DFL_FLPrev.FLL_secondB+P_y,cx
	mov	ss:DFL_FLCurr.FLL_firstB+P_y,cx
	mov	ss:DFL_FLPrev.FLL_secondExtra+P_y,cx
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_y,cx

	test	ss:DFL_Local.DFL_flags, mask DFL_firstLine
	jz	CMJ_40					;bra if not first line
	mov	ss:DFL_Local.DFL_savedFirst+P_x,bx	;save this info for
	mov	ss:DFL_Local.DFL_savedFirst+P_y,cx	;drawing connecting lin
	or	ss:DFL_Local.DFL_flags, mask DFL_savedFirstB
CMJ_40:
	jmp	CMJ_ret

CMJ_50:			
		;DO CALCS FOR POINT A
	
	mov	dx,ss:DFL_FLPrev.FLL_secondA+P_y
	mov	cx,ss:DFL_FLPrev.FLL_joinDeltaYFrac
	add	dx,ss:DFL_FLPrev.FLL_joinDeltaYInt	;intersect delta y

	mov	bx,ss:DFL_FLCurr.FLL_firstA+P_y
	clr	ax
	sub	ax,ss:DFL_FLCurr.FLL_joinDeltaYFrac
	sbb	bx,ss:DFL_FLCurr.FLL_joinDeltaYInt	;intersect y in bx:ax

	Average	bx,ax,dx,cx
	push	bx		;save averaged y

	mov	dx,ss:DFL_FLPrev.FLL_secondA+P_x
	clr	cx
	sub	cx,ss:DFL_FLPrev.FLL_joinDeltaXFrac
	sbb	dx,ss:DFL_FLPrev.FLL_joinDeltaXInt	;intersect delta x

	mov	bx,ss:DFL_FLCurr.FLL_firstA+P_x
	mov	ax,ss:DFL_FLCurr.FLL_joinDeltaXFrac
	add	bx,ss:DFL_FLCurr.FLL_joinDeltaXInt	;intersect delta x

	Average	bx,ax,dx,cx				;average x in bx

	mov	ss:DFL_FLPrev.FLL_secondA+P_x,bx
	mov	ss:DFL_FLCurr.FLL_firstA+P_x,bx
	mov	ss:DFL_FLPrev.FLL_secondExtra+P_x,bx
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_x,bx
	pop	cx					;retrieve y
	mov	ss:DFL_FLPrev.FLL_secondA+P_y,cx
	mov	ss:DFL_FLCurr.FLL_firstA+P_y,cx
	mov	ss:DFL_FLPrev.FLL_secondExtra+P_y,cx
	mov	ss:DFL_FLCurr.FLL_firstExtra+P_y,cx

	test	ss:DFL_Local.DFL_flags, mask DFL_firstLine
	jz	CMJ_ret					;bra if not first line
	mov	ss:DFL_Local.DFL_savedFirst+P_x,bx	;save point for 
	mov	ss:DFL_Local.DFL_savedFirst+P_y,cx	;drawing connectin line
	and	ss:DFL_Local.DFL_flags, not mask DFL_savedFirstB
CMJ_ret:
	ret
CalcMiteredJoin	endp	




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcLineAngle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the angle of the line stored in the
		FatLine_Local struct at ss:DFL_FLCurr and the sine
		and cosine for that angle. All this info is stored
		back in the FatLine_Local struct

CALLED BY:	CalcMiteredJoin
PASS:		DFL_FLCurr ( see structure definition )
		bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)

RETURN:		DFL_FLCurr  changed

DESTROYED:	
		ax,bx,cx,dx

PSEUDO CODE/STRATEGY:
	Note: this information may already have been calculated in 
	BasicFatLineCalcs or the last time in this routine
	and stored in the FatLineLocal struct. If ffffh is in the
	FLL_angleInt field then nothing has been calculated.		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/28/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcLineAngle		proc	near
	cmp	ss:DFL_FLCurr.FLL_angleInt,0ffffh
	jne	CAC_90				;jmp if angle already calced
	mov	bx,ss:DFL_FLCurr.FLL_distanceInt
	mov	ax,ss:DFL_FLCurr.FLL_distanceFrac
	mov	dx,ss:DFL_FLCurr.FLL_deltaYInt
	mov	cx,ss:DFL_FLCurr.FLL_deltaYFrac
	call	GrSDivWWFixed			;delta y/ distance -> dx:cx
	mov	bx,ss:DFL_FLCurr.FLL_deltaXInt
	NegateFixed	dx,cx			;coord system is upside down
	call	GrQuickArcSine			;angle in dx:cx
	mov	ss:DFL_FLCurr.FLL_angleInt,dx
	mov	ss:DFL_FLCurr.FLL_angleFrac,cx
	mov	ax,cx				;GrQuickSine needs dx:ax
	call	GrQuickSine
	mov	ss:DFL_FLCurr.FLL_sineInt,dx
	mov	ss:DFL_FLCurr.FLL_sineFrac,ax
	mov	dx,ss:DFL_FLCurr.FLL_angleInt
	mov	ax,ss:DFL_FLCurr.FLL_angleFrac
	call	GrQuickCosine
	mov	ss:DFL_FLCurr.FLL_cosineInt,dx
	mov	ss:DFL_FLCurr.FLL_cosineFrac,ax
CAC_90:
	ret
CalcLineAngle		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCCWAngleDiff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the counter clockwise difference between two
		lines

CALLED BY:	INTERNAL
		CalcBeveledJoin
		CalcMiteredJoin
PASS:		
		DFL_FLCurr  ( see structure definition )
		DFL_FLPrev  ( see structure definition )
		bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)

RETURN:		
	dx:ax	Int and Frac of difference in angles
	
DESTROYED:	
	bx,cx

PSEUDO CODE/STRATEGY:
	need difference between prev and current angle
	by difference i mean the angle measured counter clockwise
	from the prev line to the current line if they were both
	drawn from the same point
	 if prev > curr then
		360 - (prev-curr) = 360 + curr - prev
	 else
		- (prev-curr) = curr - prev
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCCWAngleDiff		proc	near
	xchg	si,di					;switch to calc prev
	call	CalcLineAngle				;angle for prev line
	xchg	si,di					;switch back
	call	CalcLineAngle				;angle for current Line

	mov	cx,ss:DFL_FLPrev.FLL_angleInt		;prev angle
	mov	bx,ss:DFL_FLPrev.FLL_angleFrac		;prev angle
	mov	dx,ss:DFL_FLCurr.FLL_angleInt		;cur angle
	mov	ax,ss:DFL_FLCurr.FLL_angleFrac		;cur angle


	sub	ax,bx					;first do curr - prev
	sbb	dx,cx
	cmp	cx,ss:DFL_FLCurr.FLL_angleInt
	jb	CCCWAD_20				;jmp if prev < curr
	ja	CCCWAD_10				;jmp if prev > curr
	cmp	bx,ss:DFL_FLCurr.FLL_angleFrac		;ints equal, check frac
	jbe	CCCWAD_20				;jmp if prev <= curr
CCCWAD_10:						;if prev > curr then 
	add	dx,360					;360 + (curr - prev)
CCCWAD_20:
		ret
CalcCCWAngleDiff		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeEndCap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles calculation and/or drawing of proper end caps
		for line segments

CALLED BY:	INTERNAL
		DrawFatPolyLineLow

PASS:		
	DFL_FLCurr  ( see structure definition )
	dl	- flags for which end or ends to butt cap
		MEC_FIRST = 10000000
		MEC_SECOND = 00000000
	bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)

RETURN:		
	nothing

DESTROYED:	
	ax,bx

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	4/12/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeEndCap		proc	near
	mov	al,ds:[GS_lineEnd]
	cmp	al, LE_SQUARECAP
	je	MEC_10
	cmp	al, LE_ROUNDCAP
	je	MEC_20
	call	MakeButtCap
	jmp	short	MEC_end
MEC_10:
	call	MakeSquareCap		
	jmp	short	MEC_end
MEC_20:
	call	DrawRoundCap		;really round
	call	MakeButtCap
MEC_end:
	ret
MakeEndCap		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawRoundCap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a cirle at the end of the DFL_FLCurr line.

CALLED BY:	INTERNAL
		MakeEndCap
		DrawFatLineReg

PASS:		
		DFL_FLCurr  ( see structure definition )
		dl - MEC_FIRST or MEC_SECOND
		bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)

RETURN:		
		nothing
DESTROYED:	
		ax,bx

PSEUDO CODE/STRATEGY:
		Calculates the square that surrounds the circle that
		fits on the end of a line. The dimension of the square
		are the width of the line. If a square cannot be centered
		on the original line point because the width is even, the
		fatty material is kept to the upper right.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	5/25/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawRoundCap		proc	near
	uses	cx, dx, di, si, bp, ds
	.enter

	mov	ax,ds:[GS_scaledLineWid]		;orig width
	shr	ax,1				;orig/2 big half
	mov	cx,ax
	push	ax				;on stack x left
	mov	bx,ss:DFL_FLCurr.FLL_kdxHigh
	cmp	bx,ss:DFL_FLCurr.FLL_kdxLow
	je	DRC_10
	dec	ax
DRC_10:
	push	ax				;on stack xright,xleft

	push	cx				;on stack top,xright,xleft
	mov	bx,ss:DFL_FLCurr.FLL_kdyHigh
	cmp	bx,ss:DFL_FLCurr.FLL_kdyLow
	je	DRC_20
	dec	cx
DRC_20:
	push	cx				;on stack bot,top,xright,xleft
	tst	dl
	jns	DRC_50					;jmp if second end
	
	mov	dx,ss:DFL_FLCurr.FLL_origFirst+P_y	
	pop	ax
	add	dx,ax					;bottom
	mov	bx,ss:DFL_FLCurr.FLL_origFirst+P_y	
	pop	ax
	sub	bx,ax					;top
	mov	cx,ss:DFL_FLCurr.FLL_origFirst+P_x
	pop	ax
	add	cx,ax					;right
	mov	ax,ss:DFL_FLCurr.FLL_origFirst+P_x	
	pop	si
	sub	ax,si					;left
	jmp	short	DRC_90
DRC_50:	
	mov	dx,ss:DFL_FLCurr.FLL_origSecond+P_y	
	pop	ax
	add	dx,ax					;bottom
	mov	bx,ss:DFL_FLCurr.FLL_origSecond+P_y	
	pop	ax
	sub	bx,ax					;top
	mov	cx,ss:DFL_FLCurr.FLL_origSecond+P_x
	pop	ax
	add	cx,ax					;right
	mov	ax,ss:DFL_FLCurr.FLL_origSecond+P_x	
	pop	si
	sub	ax,si					;left

	; Now actually draw the sucker
	;
DRC_90:
	mov	di, offset SetupEllipseLineLow		;setup routine to use
	call	FillArcEllipseLowFar			;fill the sucker

	.leave
	ret
DrawRoundCap	endp

IF	0
DrawRoundCap		proc	near
	push	cx,dx,di,si,bp,ds
	mov	ax,ds:[GS_scaledLineWid]	;orig width
	mov	bx,ax				;orig width
	shr	ax,1				;orig/2 big half
	mov	bx
	dec	bx				;orig width -1 
	sub	bx,ax				;little half

	tst	dl
	jns	DRC_50					;jmp if second end
	
	mov	cx,ss:DFL_FLCurr.FLL_origFirst+P_x	;calc upper left
	sub	cx,ax
	mov	dx,ss:DFL_FLCurr.FLL_origFirst+P_y	
	sub	dx,ax
	mov	si,dx					;save upper left
	mov	ax,cx
	mov	cx,ss:DFL_FLCurr.FLL_origFirst+P_x	;calc lower right
	add	cx,bx
	mov	dx,ss:DFL_FLCurr.FLL_origFirst+P_y
	add	dx,bx
	jmp	short	DRC_90
DRC_50:	
	mov	cx,ss:DFL_FLCurr.FLL_origSecond+P_x	;calc upper left
	sub	cx,ax
	mov	dx,ss:DFL_FLCurr.FLL_origSecond+P_y	
	sub	dx,ax
	mov	si,dx					;save upper left
	mov	ax,cx
	mov	cx,ss:DFL_FLCurr.FLL_origSecond+P_x	;calc lower right
	add	cx,bx
	mov	dx,ss:DFL_FLCurr.FLL_origSecond+P_y
	add	dx,bx

DRC_90:
	mov	bx,si					;put top in bx
	mov	si,GS_lineAttr				;draw with line attrs
	call	FillEllipseLowTransed
	pop	cx,dx,di,si,bp,ds
	ret
DrawRoundCap		endp
ENDIF


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeButtCap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a FatLine_Local struct with the initial points
		and kdx and kdy it returns, in the FatLine struct,
		the butt cap corners of one or both ends of the fat line

CALLED BY:	INTERNAL
		MakeEndCap
		CalcJoin
PASS:		
	DFL_FLCurr ( see structure definition )
	dl	- flags for which end or ends to butt cap
		MEC_FIRST = 10000000
		MEC_SECOND = 00000000
	bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
RETURN:		
		DFL_FLCurr data changed

DESTROYED:	
		ax,bx

PSEUDO CODE/STRATEGY:
	Consider the values in the FatLine_Local struct kdxHigh and kdxLow.
	The represent the delta x to each side of the fat line from the
	initial end point. |kdxHigh|>=|kdxLow|.  If the values are not
	equal the fatter part of the line is put to the right. Similarly with
	kdyHigh and kdyLow, the fatter part of the line is on the bottom.
	The weird stuff with checking the signs and switching register was
	empirically determined to do the right thing based on the way the
	initial kdx,kdy values were calculated. Isn't that nice.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MakeButtCap	proc	near
	push	cx,si
	mov	cx,ss:DFL_FLCurr.FLL_kdxHigh
	mov	ax,ss:DFL_FLCurr.FLL_kdxLow
	mov	si,ss:DFL_FLCurr.FLL_kdyLow
	mov	bx,ss:DFL_FLCurr.FLL_kdyHigh

	tst	cx
	js	MBC_10		;bra if delta x is negative
	tst	bx
	jns	MBC_90		;normal case, x>0, y>0, do nothing
	xchg	bx,si		;switch hi,lo
	js	MBC_90
MBC_10:				;delta x is negative
	tst	bx
	jns	MBC_20		;bra if delta y is positive
	xchg	bx,si
MBC_20:
	xchg	ax,cx
MBC_90:		
	tst	dl
	jns	MBC_100		;bra if don't do first end

	add	ss:DFL_FLCurr.FLL_firstA+P_x,ax
	sub	ss:DFL_FLCurr.FLL_firstA+P_y,bx
	add	ss:DFL_FLCurr.FLL_firstExtra+P_x,ax
	sub	ss:DFL_FLCurr.FLL_firstExtra+P_y,bx
	sub	ss:DFL_FLCurr.FLL_firstB+P_x,cx	
	add	ss:DFL_FLCurr.FLL_firstB+P_y,si	
	jmp	short MBC_end
MBC_100:
	add	ss:DFL_FLCurr.FLL_secondA+P_x,ax
	sub	ss:DFL_FLCurr.FLL_secondA+P_y,bx
	add	ss:DFL_FLCurr.FLL_secondExtra+P_x,ax
	sub	ss:DFL_FLCurr.FLL_secondExtra+P_y,bx
			
	sub	ss:DFL_FLCurr.FLL_secondB+P_x,cx
	add	ss:DFL_FLCurr.FLL_secondB+P_y,si

MBC_end:
	pop	cx,si
	ret
MakeButtCap		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeSquareCap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given a FatLine_Local struct with the initial points
		and kdx and kdy it returns, in the FatLine struct,
		the square cap corners of one or both ends of the fat line

CALLED BY:	INTERNAL
		MakeEndCap
PASS:		
	DFL_FLCurr ( see structure definition )
	dl	- flags for which end or ends to square cap
		MEC_FIRST = 10000000
		MEC_SECOND = 00000000
	bp,si,di (see equates for DFL_Local, DFL_FLPrev, DFL_FLCurr)
Return:		
	DFL_FLCurr data changed

DESTROYED:	
		ax,bx

PSEUDO CODE/STRATEGY:
	the kdx and kdy values in the FatLine_Local struct represent not
	only the slope of the original line, but the y and x distance to
	move the width of the line along the line. So to calc the square
	caps, half of these delta values are added to the original line
	end points and then MakeButtCap is called. 
	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	3/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MakeSquareCap	proc	near
	push	cx,si
	mov	bx,ss:DFL_FLCurr.FLL_kdyInt	;Round 1/2 the delta x distance
	mov	ax,ss:DFL_FLCurr.FLL_kdyFrac	
	sar	bx,1
	rcr	ax,1
	Round	bx,ax

	mov	si,ss:DFL_FLCurr.FLL_kdxInt	;Roune 1/2 the delta y distance
	mov	cx,ss:DFL_FLCurr.FLL_kdxFrac	
	sar	si,1
	rcr	cx,1
	Round	si,cx
	
	tst	dl
	jns	MSC_10		;bra if don't do first end
			;add deltas to first end point
	sub	ss:DFL_FLCurr.FLL_firstA+P_x,bx
	sub	ss:DFL_FLCurr.FLL_firstA+P_y,si
	sub	ss:DFL_FLCurr.FLL_firstExtra+P_x,bx
	sub	ss:DFL_FLCurr.FLL_firstExtra+P_y,si
	sub	ss:DFL_FLCurr.FLL_firstB+P_x,bx	
	sub	ss:DFL_FLCurr.FLL_firstB+P_y,si	
	jmp	short	MSC_end
MSC_10:
				;add deltas to second end point
	add	ss:DFL_FLCurr.FLL_secondA+P_x,bx
	add	ss:DFL_FLCurr.FLL_secondA+P_y,si
	add	ss:DFL_FLCurr.FLL_secondExtra+P_x,bx
	add	ss:DFL_FLCurr.FLL_secondExtra+P_y,si
	add	ss:DFL_FLCurr.FLL_secondB+P_x,bx
	add	ss:DFL_FLCurr.FLL_secondB+P_y,si

MSC_end:
	call	MakeButtCap
	pop	cx,si
	ret
MakeSquareCap		endp




IF 	USETESTLINES

DrawMyLines	proc	near
	push	ax,bx,cx,dx,si				;save it
	mov	ax,ss:DFL_FLPrev.FLL_secondA+P_x
	mov	bx,ss:DFL_FLPrev.FLL_secondA+P_y
	mov	cx,ss:DFL_FLPrev.FLL_secondExtra+P_x
	mov	dx,ss:DFL_FLPrev.FLL_secondExtra+P_y
	push	di,bp,si
	call	DrawLine
	pop	di,bp,si
	mov	ax,ss:DFL_FLPrev.FLL_secondExtra+P_x
	mov	bx,ss:DFL_FLPrev.FLL_secondExtra+P_y
	mov	cx,ss:DFL_FLPrev.FLL_secondB+P_x
	mov	dx,ss:DFL_FLPrev.FLL_secondB+P_y
	push	di,bp,si
	call	DrawLine
	pop	di,bp,si
	mov	ax,ss:DFL_FLPrev.FLL_secondB+P_x
	mov	bx,ss:DFL_FLPrev.FLL_secondB+P_y
	mov	cx,ss:DFL_FLPrev.FLL_firstB+P_x
	mov	dx,ss:DFL_FLPrev.FLL_firstB+P_y
	push	di,bp,si
	call	DrawLine
	pop	di,bp,si
	mov	ax,ss:DFL_FLPrev.FLL_firstB+P_x
	mov	bx,ss:DFL_FLPrev.FLL_firstB+P_y
	mov	cx,ss:DFL_FLPrev.FLL_firstExtra+P_x
	mov	dx,ss:DFL_FLPrev.FLL_firstExtra+P_y
	push	di,bp,si
	call	DrawLine
;	mov	si,GS_lineAttr		;use line attributes
;	mov	di,DR_VID_LINE
;	call	es:[W_driverStrategy]		; make call to driver
	pop	di,bp,si
	mov	ax,ss:DFL_FLPrev.FLL_firstExtra+P_x
	mov	bx,ss:DFL_FLPrev.FLL_firstExtra+P_y
	mov	cx,ss:DFL_FLPrev.FLL_firstA+P_x
	mov	dx,ss:DFL_FLPrev.FLL_firstA+P_y
	push	di,bp,si
	call	DrawLine
	pop	di,bp,si
	mov	ax,ss:DFL_FLPrev.FLL_firstA+P_x
	mov	bx,ss:DFL_FLPrev.FLL_firstA+P_y
	mov	cx,ss:DFL_FLPrev.FLL_secondA+P_x
	mov	dx,ss:DFL_FLPrev.FLL_secondA+P_y
	push	di,bp,si
	call	DrawLine
	pop	di,bp,si
	pop	ax,bx,cx,dx,si				;save it
	ret
DrawMyLines	endp

ENDIF

GraphicsFatLine ends
