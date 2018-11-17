COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		graphicsPolyline.asm

AUTHOR:		Steve Scholl, Oct 23, 1989

ROUTINES:
	Name			Description
	----			-----------
  EXT	GrDrawPolyline		Draws a polyline
  EXT	GrDrawPolygon		Draws a polgon outline
  INT	GrPolyLineLow
	DrawPolyline
	DrawPolylineLow
	CreateSeparatorFormat
	
	DrawSeparatorFormat

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ted	4/89		Initial revision
	srs	4/89		Lots of stuff
	Steve	10/23/89	Initial revision (klib file)
	jim	1/91		moved everything back to kernel


DESCRIPTION:
	Routines for drawing polylines
		

	$Id: graphicsPolyline.asm,v 1.1 97/04/05 01:12:54 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GraphicsLine segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a simple poly line

CALLED BY:	GLOBAL

PASS:		cx	- number of points in array
		ds:si	- array of points defining the connected lines
		di	- handle of graphics state block


RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Ted	4/89		Initial version
		srs	4/24/89		Broke into two routines
		jim	10/89		gstring support, name change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawPolyline	proc	far
	;
	; Compute size of data at DS:SI.  (Point is 4 bytes)
	;
		push	cx
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx
		
		mov	ss:[TPD_dataBX], handle GrDrawPolylineReal
		mov	ss:[TPD_dataAX], offset GrDrawPolylineReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawPolyline	endp
CopyStackCodeXIP	ends

else

GrDrawPolyline	proc	far
	FALL_THRU	GrDrawPolylineReal
GrDrawPolyline	endp

endif

GrDrawPolylineReal	proc	far
		call	EnterGraphics
		call	SetPolyPenPos		; set pen position
		jc	dplGString
		clr	dl			;not connected

		; common code used by draw polygon too
polylineCommon	label	near

		; first make sure we have a reasonable window handle

		call	TrivialRejectFar	; chunk null window, clip
		mov	di, GS_lineAttr		; use line attributes
		mov	bp, ss:[bp].EG_ds	; set up old ds
		call	DrawPolyline
		jmp	ExitGraphics

		; handle drawing to graphics string
dplGString:
		mov	al, GR_DRAW_POLYLINE	; write first part
polylineGSCommon label	near
		mov	bx, cx			; set up word to write
		mov	cl, 2			; count is a word
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; store header
		mov	cx, bx
                mov     bp, sp
		mov     ds, [bp].EG_ds          ; restore ds (trashed by EG)
		shl     cx, 1                   ; 4 bytes per coordinate point
		shl     cx, 1
		mov     ax, (GSSC_FLUSH shl 8) or 0ffh  ; no code, flush buff
		call    GSStore                 ; store the data
		jmp	ExitGraphicsGseg
GrDrawPolylineReal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetPolyPenPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Utility routine used by Polyline, Polygon, Spline to get
		the last point in a passed buffer in order to set the
		current position

CALLED BY:	INTERNAL
		GrDrawPolyline, GrDrawPolygon, GrFillPolygon, GrDrawSpline

PASS: 		si	- offset to coordinate buffer
		ss:bp	- EGframe
		cx	- # points in buffer
		ds	- gstate segment

RETURN:		penPos is set in gstate to the last point in the buffer
		flags preserved 

DESTROYED:	bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Jim	02/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetPolyPenPos	proc	near
		pushf
		uses	es, ax
		.enter		

		; find the last point so we can set the new penPos

		mov	bx, ss:[bp].EG_ds	; recover old ds
		mov	es, bx			; es:si -> coordinate buffer
		mov	bx, cx			; bx = # points
		dec	bx
		shl	bx, 1			; 4 bytes/coordinate pair
		shl	bx, 1
		mov	ax, es:[si][bx].P_x	; get x coordinate of last pt
		mov	bx, es:[si][bx].P_y	; get y coordinate of last pt
		call	SetDocPenPos

		.leave
		popf				; restore gstring flags
		ret
SetPolyPenPos	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrDrawPolygon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a connected poly line

CALLED BY:	GLOBAL

PASS:		cx	- number of points in array
		ds:si	- array of points defining the connected lines
		di	- handle of graphics state block


RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	2/90		Initial version, mostly copied from
					GrDrawPolyline

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	FULL_EXECUTE_IN_PLACE	

CopyStackCodeXIP	segment resource
GrDrawPolygon	proc	far
	;
	; Compute size of data at DS:SI.  (Point is 4 bytes)
	;		
		push	cx
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx

		mov	ss:[TPD_dataBX], handle GrDrawPolygonReal
		mov	ss:[TPD_dataAX], offset GrDrawPolygonReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrDrawPolygon	endp
CopyStackCodeXIP	ends

else

GrDrawPolygon	proc	far
	FALL_THRU	GrDrawPolygonReal
GrDrawPolygon	endp

endif

GrDrawPolygonReal	proc	far
		call	EnterGraphics
		push	ds			; save GState
		mov	ds, ss:[bp].EG_ds
		mov	ax, ds:[si]		; set curPos to first point
		mov	bx, ds:[si+2]
		pop	ds			; restore GState
		call	SetDocPenPos		; set new current position
		jc	dpgGString
		mov	dl, 1			;connected
		jmp	polylineCommon

		; handle drawing to graphics string
dpgGString:
		mov	al, GR_DRAW_POLYGON	; write first part
		jmp	polylineGSCommon
GrDrawPolygonReal	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GrBrushPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a brushed connected poly line

CALLED BY:	GLOBAL

PASS:		cx	- number of points in array
		ds:si	- array of points defining the connected lines
		di	- handle of graphics state block
		al	- rectangular brush width, in pixels
		ah	- rectangular brush height, in pixels

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		jim	11/91		Initial version, mostly copied from
					GrDrawPolyline
		don	4/95		Small code-size optimizations

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	FULL_EXECUTE_IN_PLACE
	
CopyStackCodeXIP	segment resource
GrBrushPolyline	proc	far
	;
	; Compute size of data at DS:SI.  (Point is 4 bytes.)
	;
		push	cx	
		shl	cx, 1
		shl	cx, 1
		mov	ss:[TPD_callVector].segment, cx
		pop	cx

		mov	ss:[TPD_dataBX], handle GrBrushPolylineReal
		mov	ss:[TPD_dataAX], offset GrBrushPolylineReal
		GOTO	SysCallMovableXIPWithDSSIBlock
GrBrushPolyline	endp
CopyStackCodeXIP	ends

else

GrBrushPolyline	proc	far
		FALL_THRU	GrBrushPolylineReal
GrBrushPolyline	endp

endif

GrBrushPolylineReal	proc	far
		; these locals are only used in the case of the optimized draw
		; for two points
optSep		local	Point
optPoint2	local	Point
optPoint1	local	Point
		call	EnterGraphics
		call	SetPolyPenPos		; set new current position
		jc	bplGString

		; first make sure we have a reasonable window handle

		call	TrivialRejectFar

		jcxz	done			; jmp if no points

		push	ss:[bp].EG_ax		; get brush width/height
		mov	bp, ss:[bp].EG_ds	; set up old ds
		
		; see if there are only 2 points, and optimize for that case
		; (this helps out drawing ink in pen-systems)

		cmp	cx, 2
		LONG je	helpInk

		clr	al
		call	CreateSeparatorFormat
		pop	ax			; restore brush size
		jc	freeBlock
		push	bx			; save SEPARATOR handle
		clr	si			; offset into SEPARATOR block
		mov	bp,1			; num disjoint polylines
		push	dx
		push	ax			; save brush size
		call	GetPolylineBounds
		pop	bp			; bp = brush size
		xchg	ax, bp
		add	cl, al
		adc	ch, 0
		add	dl, ah
		adc	dh, 0
		xchg	bp, ax
		call	TrivialRejectRect	; if outside bounds of window
		mov	ax, bp			; ax = brush shape
		pop	bx
		jc	freePopBlock		; ...do nothing
		clr	si			; bx:si -> point buffer
		mov	di, DR_VID_POLYLINE	; load up function number
		call	es:[W_driverStrategy]	; call video driver
freePopBlock:
		pop	bx			; recover SEPARATOR handle
freeBlock:
		call	MemFree
done:
		jmp	ExitGraphics

		; handle drawing to graphics string
bplGString:
		mov	dx, ax			; store brush size info
		mov	al, GR_BRUSH_POLYLINE	; write first part
		mov	bx, cx			; set up word to write
		mov	cl, size OpBrushPolyline - 1 ; #databytes to write
		mov	ch, GSSC_DONT_FLUSH
		call	GSStoreBytes		; store header
		mov	cx, bx
                mov     bp, sp
		mov     ds, [bp].EG_ds          ; restore ds (trashed by EG)
		shl     cx, 1                   ; 4 bytes per coordinate point
		shl     cx, 1
		mov     ax, (GSSC_FLUSH shl 8) or 0ffh  ; no code, flush buff
		call    GSStore                 ; store the data
		jmp	ExitGraphicsGseg
		
		; if only two points, brush a line
helpInk:
		pop	ax			; restore brush size
		mov	bx, bp			; ax -> point buffer
		.enter				; create local vars
		push	ax			; save brush size
		push	ds			; save GState segment
		mov	ds, bx			;  ds -> points
		lodsw				; get first x coord
		mov	cx, ax
		lodsw				; get first y coord
		mov	dx, ax
		lodsw
		mov	bx, ax
		lodsw
		xchg	ax, bx
		call	GrTransCoord2Far
		mov	optPoint1.P_x, cx
		mov	optPoint1.P_y, dx
		mov	optPoint2.P_x, ax
		mov	optPoint2.P_y, bx
		mov	optSep.P_x, 8000h	; add separator
		mov	optSep.P_y, 8000h
		pop	ds			; restore GState segment
		pop	ax			; restore brush size
		mov	bx, ss
		lea	si, optPoint1		; bx:si -> point buffer
		mov	di, DR_VID_POLYLINE	; load up function number
		push	bp
		call	es:[W_driverStrategy]	; call video driver
		pop	bp
		.leave
		jmp	done

GrBrushPolylineReal	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPolyline
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a poly line

CALLED BY:	GLOBAL

PASS:		ds 	- gstate
		es 	- window
		bp:si 	- segment and offset to points
		cx 	- number of points in array
		di	- offset to attributes to use
		dl 	- 0 if not connected, 1 if connect first and last

RETURN:		nothing

DESTROYED:	bx,bp,si

PSEUDO CODE/STRATEGY:
		Set scaledLineWidth - must be at least one
		Convert points to translated separator format
		Pass point onto next polyline routine

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawPolylineFar	proc	far
	call	DrawPolyline
	ret
DrawPolylineFar	endp

DrawPolyline	proc	near
	call	ScaleLineWidth			;set scaled line width
	jcxz	done				;jmp if no points
	mov	al,dl				;pass connected flag
	call	CreateSeparatorFormat
	jc	freeBlock
	push	bx				;save SEPARATOR handle
	clr	si				;offset into SEPARATOR block
	mov	bp,1				;num disjoint polylines
	call	DrawPolylineMed
	pop	bx				;recover SEPARATOR handle
freeBlock:
	call	MemFree
done:
	ret
DrawPolyline		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPolylineMed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does a trivial reject on the polyline information. If the
		rejected it just returns, otherwise calls DrawPolylineLow

CALLED BY:	INTERNAL
		DrawPolyline
	
PASS:		
		dx:si - segment and offset to points in separator format
		ds - gstate
		cx - number of points
		bp - number of disjoint polylines
		es - window 
		al - connected flag
		di	- offset to attributes to draw with
RETURN:		
		nothing

DESTROYED:	
		ax,bx,cx,dx,bp,di,si		

PSEUDO CODE/STRATEGY:
		none		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	1/22/90		Initial version
	don	4/ 7/95		Optimized to always check window's mask rect
				and saved a few bytes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawPolylineMed		proc	near
	.enter

	; To try to speed things along, we see if the passed polyline will
	; fall anywhere inside of the current Window. If the scaled line
	; width is anything other than 1, then we need to bump the polyline's
	; bounds out to account for the extra width. For line joins, be
	; aware that a mitered line can extend far beyond the end of the
	; line (imagine a join of two lines that are nearly parallel). We
	; can ignore this problem if there are only two point in the polyline
	; (i.e. we are just drawing a single line, which is the most common
	; case).
	;
	cmp	cx, 2				;if only two point
	jbe	doTest				;...don't care about LineJoin
	cmp	ds:[GS_lineJoin], LJ_MITERED
	je	draw
doTest:
	push	ax,cx,dx,si
	call	GetPolylineBounds		;bounds -> ax,bx,cx,dx
	mov	si,ds:[GS_scaledLineWid]
	cmp	si,1
	jbe	notFat
	shr	si,1				;half line width
	inc	si
	sub	ax,si				;extend bounds to include
	sub	bx,si				;fatness
	add	cx,si
	add	dx,si
notFat:
	call	TrivialRejectRect		;if outside of window
	pop	ax,cx,dx,si
	jc	done				;...we're done
draw:
	call	DrawPolylineLow
done:
	.leave
	ret
DrawPolylineMed		endp

DrawPolylineMedFar	proc	far
	call	DrawPolylineMed
	ret
DrawPolylineMedFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetPolylineBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finds X min, X max, Y min, and Y max of the polyline

CALLED BY:	INTERNAL
		DrawPolylineMed

PASS: 		dx:si - segment and offset to points in separator format
		ds - gstate
		cx - number of points
		bp - number of disjoint polylines
RETURN:
		ax,bx	-upper left
		cx,dx	- lower right

DESTROYED:	si

PSEUDO CODE/STRATEGY:
	none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetPolylineBounds	proc	near
	uses	ds,di
	.enter
	mov	ds,dx
	; get 1st coordinate and initialize X min/max, Y min/max
	;di = xMin bx = yMin cx = xMax dx = yMax

	lodsw				; get X coordinate
	mov	di,ax			; initialize X min 
	mov	cx,ax			; initialize X max 

	lodsw				; get Y coordinate
	mov	bx,ax			; initialize Y min
	mov	dx,ax			; initialize Y max
nextX:
	lodsw				; get X coordinate
	cmp	ax,SEPARATOR
	je	separator		; jmp if hit SEPARATOR
	cmp	ax,di			; compare X value with X min  
	jl	newXMin			; if less, store the new X min
	cmp	ax, cx			; if not, compare X value with X max
	jg	newXMax			; if greater, store the new X max
nextY:
	lodsw				; get Y coordinate
	cmp	ax,bx			; compare Y value with Y min  
	jl	newYMin			; if less, store the new Y min
	cmp	ax,dx			; if not, compare Y value with Y max 
	jle	nextX			; if less or equal, jmp to continue
	mov	dx,ax			; store the new Y max
	jmp	short nextX		; check next vertex
	
separator:		;HIT SEPARATOR
	cmp	ds:[si],SEPARATOR
	jne	nextX			; jmp if didn't hit 2nd SEPARATOR

	mov	ax,di
	.leave
	ret				

newXMin:
	mov	di, ax			; store the new X min
	jmp	short nextY		; check Y coordinate
newXMax:
	mov	cx, ax			; store the new X max
	jmp	short nextY		; check Y coordinate
newYMin:
	mov	bx, ax			; store the new Y min
	jmp	short nextX		; check next vertex

GetPolylineBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawPolylineLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Low level routine for drawing polylines

CALLED BY:	INTERNAL
		DrawPolylineMed

PASS:		
		dx:si - array of points in terminated separator format
		ds - segment of graphics state
		es - segment of window 
		cx - number of points
		bp - number of disjoint polylines
		al - connected flag - only used by fatlines
		di	- offset to attributes
RETURN:		
		es - window segement - may have moved

DESTROYED:	
		ax,bx,cx,dx,bp,di,si

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/89	Initial version
	don	12/11/91	Always recalculates the scaled width

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawPolylineLow		proc	far

	; See which polyline draw code we need to use - regular,
	; dashed lines, or fat-lines
	;
	call	ScaleLineWidth			;update the scaled line width
	cmp	ds:[GS_lineStyle], LS_SOLID
	jnz	dashes				;jmp if do dashes
drawBuffer:
	cmp	ds:[GS_scaledLineWid],1
	ja	fatLines			;jmp if fat
	call	DrawSeparatorFormat
freeBuffer:
	cmp	ds:[GS_lineStyle], LS_SOLID
	jz	done				;jmp if no dash block
	pop	bx				;dashes handle
	call	MemFree
done:
	ret

	; Deal with dashes
	;
dashes:
	push	ax, di				;save connected flag
	call	PolyDashedLineLow
	pop	ax, di				;recover connected flag
	tst	bx
	jz	done				;jmp if nothing returned
	clr	si				;offset to dashes
	push	bx				;save dashes block handle
	jmp	drawBuffer

	; Deal with fat-lines
	;
fatLines:
	clr	ah
	mov	cx, ax				;pass connected flag
	call	DoFatLines
	jmp	freeBuffer
DrawPolylineLow		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateSeparatorFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a buffer of coordinates into Separator Format

CALLED BY:	INTERNAL
		GrPolyline
PASS:		
		cx - number of points in array
		bp:si - array of points in document coordinates
		es - window
		al - 0 if not connected, 1 of connected		
RETURN:		
		bx - handle of Separator Format block
		dx - segment of Separator Format block
		ds,es unchanged
		cx - number of points		
		ax - unchanged

		carry - set if there was some overflow problem with coords
DESTROYED:	
		si,bp

PSEUDO CODE/STRATEGY:
	The passed coordinates are in document coordinates. The new buffer
	in Separator Format contains screen coordinates and the coordinates
	are followed by two SEPARATOR constants.

	3fffh - maximum number of points that can be passed

	??? should this return 0 for block handle in certain situation
	like 0 or 1 points

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateSeparatorFormat		proc	far
	uses	ax, di, ds
	.enter

	cmp	cx, 1			; if only one point, force conn flag
	jne	5$
	mov	al, 1
5$:
	mov	dx,cx			;save number of points
	tst	al
	jz	10$			;jmp if not connected
	inc	cx			;number of points including connected
10$:
	push	cx			;save point count
	push	ax			;connected flag
	mov	ax,cx			;number of points, including connected
	inc	ax			;bytes for two SEPARATOR constants
	shl	ax,1	
	shl	ax,1			;number of bytes
EC <	ERROR_C	GRAPHICS_BLOCK_TOO_BIG_TO_ALLOC				>
	mov	cx,ALLOC_DYNAMIC_NO_ERR or (mask HAF_LOCK shl 8)
	call	MemAllocFar
	push	bx			;save handle
	mov	cx,dx			;number of points excluding connected
	mov	ds,bp			;segment of src points
	mov	bp,ax			;segment of dest buffer
	clr	di			;offset to store separator format
	mov	dx,es			;save window segment
	
CSF_10:
	lodsw				;get a point
	mov	bx,ax
	lodsw	
	xchg	ax,bx

	call	GrTransCoordFar		;translate it
	jnc	checkCoords

	; we're way out of bounds.  restore the stack and bail
outOfBounds:
	pop	bx			;restore handle
	pop	ax			;restore connected flag
	pop	cx			;restore point count (to be destroyed)
	clr	cx			;return zero points
	stc				;return error
	jmp	done

checkCoords:
	cmp	ax, MAX_COORD		; if too big, bail
	jg	outOfBounds
	cmp	bx, MAX_COORD
	jg	outOfBounds
EC <	call	CheckCoordFar						>
EC <	push	ax							>
EC <	mov	ax,bx							>
EC <	call	CheckCoordFar						>
EC <	pop	ax							>

	mov	es,bp			;seg of separator format
	stosw				;store translated x
	mov	ax,bx
	stosw				;store translated y
	mov	es,dx			;recover window
	dec	cx			;number of points left
	jne	CSF_10			;jmp if still points

	pop	bx			;handle of separator format to return
	mov	es,bp			;seg of separator format
	pop	ax			;connected flag
	tst	al			
	jz	20$			;jmp if not connected

			;STORE FIRST POINT AT END
	mov	ax,es:0			;first x of separator format
	stosw				;store at end
	mov	ax,es:2			;first y of separator format
	stosw
			;STORE TWO SEPARATORS
20$:
	mov	ax,SEPARATOR
	stosw				;store SEPARATORs
	stosw
	mov	es,dx			;window
	mov	dx,bp			;segment of separator format
	pop	cx			;restore point count
	clc				;signal OK
done:
	.leave
	ret
CreateSeparatorFormat		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSeparatorFormat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will eventually become a driver routine.

CALLED BY:	
PASS:		dx:si - segment and offset points buffer
		es - window segment
		ds - gstate segment
		di - offset to attributes to use
RETURN:		
		es - window segment - may have moved
DESTROYED:	
		ax,bx,cx,dx,bp,si,di

PSEUDO CODE/STRATEGY:
	passed buffer must be in screen coordinates and terminated 
	separator format (SCTSF)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/17/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSeparatorFormat		proc	far
	uses	ds
	.enter
	mov	bx, dx			; bx:si -> points
	mov	di, DR_VID_POLYLINE	; load up function number
	clr	ax			; draw with 1x1 pixel brush
	call	es:[W_driverStrategy]	; call video driver
	.leave
	ret
DrawSeparatorFormat		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleLineWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Computes the scaled line width, and stored in in the GState

CALLED BY:	GLOBAL

PASS:		DS	= GState segment
		ES	= Window segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/11/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleLineWidth	proc	near
		uses	dx, ax
		.enter
	
		movwwf	dxax, ds:[GS_lineWidth]
		call	ScaleScalar			; scaled width => AX
		tst	ax
		jnz	storeScaled
		inc	ax				; make it at one
storeScaled:
		mov	ds:[GS_scaledLineWid], ax

		.leave
		ret
ScaleLineWidth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleScalar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scales a scalar quantity based on the x and y scale factor

CALLED BY:	GLOBAL

PASS:		
		dxax - scalar quantity (WWFixed)
		ds - GState segment

		if ds:GS_window != NULL, then
			es - window segment (may not be 
RETURN:		
		ax - scaled scalar
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
	A scalar quantitiy cannot always be correctly scaled when there are
	idependent scaling factors. So I scale the quantity by both factors
	and take an average. This value will be correct if both the scale 
	factors are the same, otherwise it will off a bit.

	However, the scale factors in the transformation matrix are not 
	independent of the rotation. So we can't always get the scale factor
	directly from the matrix. Also, all the routines we have apply the
	whole matrix to a value at once. So our scalar quantitiy will get
	translated too. All this is overcomeable in some way or another.

	What we do is transform 0,0 and scalar,0. The distance between
	these two points is our value scaled in x. We then transform
	0,scalar. The distance between it and 0,0 tranformed is our
	value scaled in y. When the average these two values and we
	are set. The distance calculation used in only an approximation.
	It is exact when the distance is along a horizontal or vertical
	line (which is the case if no rotation is involved) and it
	gets slowly worse as the distance is measured along a diagonal line.
	But not too bad.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/19/89	Initial version
	jim	12/92		added support for no window
	don	2/95		Optimized

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ScaleScalar		proc	far
	uses	bx,cx,dx,ds,si,di
point0	local	PointWWFixed
point1	local	PointWWFixed
	.enter

	; first figure out if we're gonna use the window or the GState

	mov	cx, ax				; dxcx = scalar
	tst	ds:[GS_window]			; check for no window
	jz	round
	segmov	ds, es, si
	mov	si, offset W_TMatrix		; ds:si -> window matrix

	; ds:si -> matrix to use.  Transform the coords and take the average
	; distance.

	pushwwf	dxcx				; save for later
	clrwwf	bxax
	call	TransCoordFixed			; transform (scalar,0)
	movwwf	point1.PF_x, dxcx		; save result
	movwwf	point1.PF_y, bxax
	clrwwf	bxax
	clrwwf	dxcx
	call	TransCoordFixed			;transform (0,0)
	movwwf	point0.PF_x, dxcx
	movwwf	point0.PF_y, bxax
	push	si
	lea	si, point0
	lea	di, point1
	call	DistanceApprox			; calc scaled in x
	pop	si
	popwwf	bxax				; restore scalar line width
	pushwwf	dxcx				; save first distance
	clrwwf	dxcx
	call	TransCoordFixed			;transform (0,scalar)
	movwwf	point1.PF_x, dxcx		; save result
	movwwf	point1.PF_y, bxax
	lea	si, point0
	call	DistanceApprox			; calc scaled in y
	popwwf	bxax				; restore saved scaled-in-X
	addwwf	dxcx, bxax			; add..
	shrwwf	dxcx				;     ..average..
round:
	rnduwwf	dxcx				;               ..round
	mov	ax, dx			

	.leave
	ret
ScaleScalar		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DistanceApprox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculates the distance between two points using an
		approximation of the distance formula

CALLED BY:	INTERNAL
		ScaleScalar

PASS:		ss:si	- point1 (WWFixed)
		ss:di	- point2 (WWFixed)
RETURN:		dxcx	- WWFixed distance
DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:
	(abs(dx) + abs(dy) + max(abs(dx),abs(dy)))/2

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/23/89	Initial version
	jim	2/93		Changed to do WWFixed math

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DistanceApprox	proc	near
		movwwf	dxcx, <ss:[si].PF_x>
		subwwf	dxcx, <ss:[di].PF_x>		; calculate delta X
		tst	dx				; take abs value
		jns	haveAbsX
		negwwf	dxcx
haveAbsX:
		movwwf	bxax, <ss:[si].PF_y>
		subwwf	bxax, <ss:[di].PF_y>		; calculate delta X
		tst	bx				; take abs value
		jns	haveAbsY
		negwwf	bxax
haveAbsY:
		jgewwf	dxcx, bxax, haveMax
		xchgwwf	dxcx, bxax

		; have maximum, so double it, add other, halve...
haveMax:
		shlwwf	dxcx
		addwwf	dxcx, bxax			; deltaX*2 + deltaY

		sarwwf	dxcx				; final divide by 2
		ret
DistanceApprox	endp

GraphicsLine ends
