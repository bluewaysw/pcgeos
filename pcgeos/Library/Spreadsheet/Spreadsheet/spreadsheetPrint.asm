COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		spreadsheetPrint.asm

AUTHOR:		John Wedgwood, Apr 26, 1991

METHODS:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	 4/26/91	Initial revision

DESCRIPTION:
	Method handlers to support printing.

	$Id: spreadsheetPrint.asm,v 1.1 97/04/07 11:14:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDrawRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a range of cells at a given position given some other
		parameters...

CALLED BY:	via MSG_SPREADSHEET_DRAW_RANGE
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		ax	= Method
		es	= Class segment
		ss:bp	= Pointer to SpreadsheetDrawParams on stack
		    SDP_gstate - handle of GState to draw with
		    SDP_flags - SpreadsheetDrawFlags
		    SDP_drawArea - area to draw to (RectDWord)
		    SDP_topLeft - top/left (r,c) of area to draw
		    SDP_limit - top/left/bottom/right (r,c) of area to draw
		    SDP_margins - margins enforced by printer
		dx	= Size of parameters (if called remotely)
RETURN:		ss:bp	= Pointer to SpreadsheetDrawParams on stack
		    SDP_printlags - SPF_DONE bit set if we've printed it all
		    SDP_topLeft - top/left of next area to draw
DESTROYED:	everything (it's a method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetDrawRange	method	SpreadsheetClass, MSG_SPREADSHEET_DRAW_RANGE
	mov	si, di			; ds:si <- instance ptr
	mov	bx, bp			; ss:bx <- ptr to passed parameters
	;
	; The CellLocals local variable is inherited by almost every
	; routine involved in printing. Do not muck with the local variables
	; unless you know what you're doing. You have been warned.
	;
locals	local	CellLocals
	.enter
	
	;
	; Initialize everything... flags, range, scale, translation, gstate
	;
	andnf	ss:[bx].SDP_printFlags, not (mask SPF_DONE)

	call	SetRangeEnumParams	; Set up the range to call.

	call	ComputeRangeBounds	; Figure out the bounds of the range

	call	ComputeScale		; Compute the amount of scale
	call	ComputeLeftRightScale	; Compute scale amount for header/footer
	call	ScaleDocBounds

	call	ComputeTranslation	; Compute any translations

	mov	di, ss:[bx].SDP_gstate	; di <- gstate
	call	GrSaveState		; Save the gstate

	;
	; Apply the translation & scale
	;
	call	ApplyScaleAndTranslation
	;
	; Set up the GState and draw flags
	;
	mov	ax, ss:[bx].SDP_printFlags
	mov	ss:locals.CL_printFlags, ax	;pass SpreadsheetPrintFlags
	push	ax
	test	ax, mask SPF_PRINT_GRID
	mov	ax, mask SDF_DRAW_GRID		;ax <- assume grid
	jnz	haveGrid
	clr	ax				;ax <- no grid
haveGrid:
	mov	ss:locals.CL_drawFlags, ax
	pop	ax
	mov	di, ss:[bx].SDP_gstate		;di <- handle of GState
	mov	ss:locals.CL_gstate, di		;pass GState handle
	call	InitGStateForDrawing
	;
	; Now we need ax/bx/cx/dx = range of cells to draw
	;
	test	ax, mask SPF_SKIP_DRAW	; Check for just calculating # of pages
	jnz	afterDraw
	;
	; Draw the titles
	; NOTE: applies a translation if drawing titles!
	;
	call	DrawTitles			;draw row/column titles
	;
	; Set a clip rectangle so cells that spill outside their
	; bounds don't spill outside our bounds, too.
	;
	call	SetClipRectForPrinting

	;
	; Draw the range
	;
	push	bx
	mov	ax, ss:[bx].SDP_printFlags
	mov	ss:locals.CL_printFlags, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_top
	mov	cx, ss:locals.CL_params.REP_bounds.R_left
	mov	ss:locals.CL_origin.CR_row, ax
	mov	ss:locals.CL_origin.CR_column, cx
	mov	bx, ss:locals.CL_params.REP_bounds.R_bottom
	mov	dx, ss:locals.CL_params.REP_bounds.R_right
	call	RangeDraw		;draw the range
	pop	bx

afterDraw:
	;
	; Return various parameters useful for applications doing printing
	;
	call	ReturnPrintParams
	;
	; Restore the gstate and set the next cell to start drawing at.
	;
	call	GrRestoreState		; Restore the gstate

	call	SetNewTopLeft		; Set the new top/left cell
	.leave
	ret
SpreadsheetDrawRange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClipRectForPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a clip rectangle so cells don't spill outside our bounds

CALLED BY:	SpreadsheetDrawRange()
PASS:		ss:bp - inherited locals
		ss:bx - ptr to SpreadsheetDrawParams
		di - handle of GState
RETURN:		none
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/29/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetClipRectForPrinting		proc	near
	uses	bx, si
locals	local	CellLocals
	.enter	inherit

	;
	; Since we're translating to the area printed, our clip
	; rectangle goes from (0,0) now.
	;
	movdw	axcx, ss:locals.CL_docBounds.RD_right
	subdw	axcx, ss:locals.CL_docBounds.RD_left
	jnz	noClip				;branch if too large
	movdw	axdx, ss:locals.CL_docBounds.RD_bottom
	subdw	axdx, ss:locals.CL_docBounds.RD_top
	jnz	noClip				;branch if too large
	;
	; If we're doing scale-to-fit or continous printing, there's
	; a decent chance that the area to clip to will be larger
	; than the graphics system can handle.  If this is the case,
	; we simply punt on clipping.
	;
	inc	cx				;+1 for happiness
	inc	dx				;+1 for happiness
	cmp	cx, MAX_COORD/5			;x too large?
	jae	noClip				;branch if too large
	cmp	dx, MAX_COORD/5			;y too large?
	jae	noClip				;branch if too large
	;
	; We've already translated beyond the row & column headers, if
	; any, but we need to adjust our clip rectangle by their area,
	; since CL_docBounds includes them for scaling, page-breaks, etc.
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_ROW_COLUMN_TITLES
	jz	noTitles
	sub	cx, SPREADSHEET_RULER_WIDTH
	sub	dx, SPREADSHEET_RULER_HEIGHT
noTitles:
	mov	ax, -1
	mov	bx, ax				;(ax,bx,cx,dx) <- Rectangle
	mov	si, PCT_REPLACE
	inc	cx
	inc	dx				;(cx,dx) <- bump for line widths
	call	GrSetClipRect
noClip:
	.leave
	ret
SetClipRectForPrinting		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReturnPrintParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return various parameters used for printing

CALLED BY:	SpreadsheetDrawRange()
PASS:		ss:bp - inherited locals
		ss:bx - SpreadsheetDrawParams
		ds:si - ptr to Spreadsheet instance
RETURN:		ss:bx - SpreadsheetDrawParams
			SDP_range - range actually printed
			SDP_translation - translation used
DESTROYED:	ax, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	1/13/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ReturnPrintParams		proc	near
	uses	bp, si, di
	class	SpreadsheetClass
	.enter	inherit	SpreadsheetDrawRange

	;
	; Return the range we've printed
	;
	mov	ax, ss:locals.CL_params.REP_bounds.R_top
	mov	ss:[bx].SDP_range.CR_start.CR_row, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_left
	mov	ss:[bx].SDP_range.CR_start.CR_column, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_bottom
	mov	ss:[bx].SDP_range.CR_end.CR_row, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_right
	mov	ss:[bx].SDP_range.CR_end.CR_column, ax
	;
	; Adjust for the row & column titles, if printed
	;
	clr	ax, cx, dx
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_ROW_COLUMN_TITLES
	jz	noTitles
	mov	cx, SPREADSHEET_RULER_WIDTH
	mov	dx, SPREADSHEET_RULER_HEIGHT
noTitles:
	movdw	ss:[bx].SDP_titleTrans.PD_x, axcx
	movdw	ss:[bx].SDP_titleTrans.PD_y, axdx
	;
	; Return the bounds of the range actually printed
	;
	push	bx
	mov	ss:locals.CL_origin.CR_row, 0
	mov	ss:locals.CL_origin.CR_column, 0
	mov	ax, ss:locals.CL_params.REP_bounds.R_top
	mov	cx, ss:locals.CL_params.REP_bounds.R_left
	mov	bx, ss:locals.CL_params.REP_bounds.R_bottom
	mov	dx, ss:locals.CL_params.REP_bounds.R_right
	call	GetRangeRelBounds32Far

	pop	bx
	mov	ax, ss
	mov	ds, ax
	mov	es, ax
	lea	si, ss:locals.CL_docBounds	;ds:si <- source RectDWord
	mov	cx, (size RectDWord)/(size word)
	lea	di, ss:[bx].SDP_rangeArea	;es:di <- dest RectDWord
	rep	movsw

	.leave
	ret
ReturnPrintParams		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale the doc bounds if necessary.

CALLED BY:	ReturnPrintParams
PASS:		ss:bp	= Inheritable CellLocals
		ss:bx	= ptr to SpreadsheetDrawParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/21/91	Initial version
	cp	 2/25/94	Based on ScaleDrawBounds

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScaleDocBounds	proc	near
locals		local	CellLocals
	.enter	inherit

	;
	; Check for the situation where we want to scale the left/right edges.
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_HEADER or \
					mask SPF_PRINT_FOOTER
	jz	quit				; Branch if not header/footer
	
	;
	; We are doing continuous printing in the header or footer. We need
	; to scale the bounds in CL_docBounds.R_left/right by the amount
	; in CL_columnScale.
	;
	
	push	ax, bx, cx, dx, si, di		; Save misc registers
	;
	; Scale the left edge...
	;
	movdw	didx, locals.CL_docBounds.RD_left
	clr	cx				; didx.cx <- position
	
	mov	bx, locals.CL_columnScale.high
	mov	ax, locals.CL_columnScale.low
	clr	si				; sibx.ax <- scale factor

	push	bx
	call	GrMulDWFixed			; dxcx.bx <- result
	movdw	locals.CL_docBounds.RD_left, dxcx	; Save the scaled result
	pop	bx

	;
	; Scale the right edge...
	;
	movdw	didx, locals.CL_docBounds.RD_right
	clr	cx				; didx.cx <- position	

	call	GrMulDWFixed			; dxcx.bx <- result
	movdw	locals.CL_docBounds.RD_right, dxcx	; Save the scaled result

	pop	ax, bx, cx, dx, si, di		; Restore misc registers
quit:
	.leave
	ret
ScaleDocBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTitles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw row and column titles
CALLED BY:	SpreadsheetDrawRange()

PASS:		ds:si - ptr to Spreadsheet instance
		ss:bx - ptr to SpreadsheetDrawParams
		ss:bp - CellLocals stack frame
		di - handle of  GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawTitles	proc	near
	uses	ax, cx, dx
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	;
	; If we're drawing row and column titles, draw them now
	;
	test	ss:[bx].SDP_printFlags, (mask SPF_PRINT_ROW_COLUMN_TITLES)
	jz	skipDrawTitles
	;
	; The one thing not handled by the rulers is the space in the corner...
	;
	push	bx
	clr	ax				;ax <- left
	clr	bx				;bx <- top
	mov	cx, SPREADSHEET_RULER_WIDTH	;cx <- right
	mov	dx, SPREADSHEET_RULER_HEIGHT	;dx <- top
	call	GrDrawRect
	pop	bx
	mov	ax, ss:locals.CL_params.REP_bounds.R_top
	mov	ss:[bx].SDP_range.CR_start.CR_row, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_left
	mov	ss:[bx].SDP_range.CR_start.CR_column, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_bottom
	mov	ss:[bx].SDP_range.CR_end.CR_row, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_right
	mov	ss:[bx].SDP_range.CR_end.CR_column, ax
	push	bp
	mov	bp, bx				;ss:bp <- SpreadsheetDrawParams
	mov	ax, MSG_SPREADSHEET_RULER_DRAW_RANGE
	call	SendToRuler
	pop	bp
	;
	; Apply a translation so the spreadsheet doesn't get
	; drawn over the top of us
	;
	push	bx
	mov	dx, SPREADSHEET_RULER_WIDTH
	clr	cx				;dx.cx <- x translation
	mov	bx, SPREADSHEET_RULER_HEIGHT
	clr	ax				;bx.ax <- y translation
	call	GrApplyTranslation
	pop	bx
skipDrawTitles:
	.leave
	ret
DrawTitles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute any scaling that needs doing

CALLED BY:	SpreadsheetDrawRange
PASS:		ss:bx	= Pointer to SpreadsheetDrawParams
		ss:bp	= inherited CellLocals
			CL_origin - relative draw origin
RETURN:		SDP_scale set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeScale	proc	near
	uses	ax, cx, dx, bp, di, si
locals	local	CellLocals
	.enter	inherit
	;
	; Assume a scale of 1. The only time this will be different is when
	; we are scaling the region to fit on a single page.
	;
	mov	ss:[bx].SDP_scale.WWF_int,  1
	mov	ss:[bx].SDP_scale.WWF_frac, 0

	test	ss:[bx].SDP_printFlags, mask SPF_SCALE_TO_FIT
	jz	quit
	;
	; The formula for the scale is:
	;	printArea / rangeArea
	;
	; The problem here is that the printArea and the rangeArea can both
	; possibly contain a 32 bit integer. Since we want to allow fractional
	; scaling we are going to end up with a 48 bit value as a result.
	; What we're going to do is this:
	;	scale = printArea / rangeArea (in 48 bit math)
	; Then we take the result and, if there are any bits set in the
	; high word, we gasp and just choose the largest scale we can.
	;
	call	ComputeXScale			; dx.cx <- X scale factor
	call	ComputeYScale			; di.ax <- Y scale factor

	;
	; We need to choose a scale factor now. We want to use the smaller
	; of the X and Y scale factors.
	;
	; dx.cx = X scale factor
	; di.ax = Y scale factor
	; si.bp	= scratch
	;
	movwwf	sibp, dxcx		; Assume X scale factor is smallest
	cmpwwf	dxcx, diax		; See which is the larger
	jbe	setScaleFactor
	movwwf	sibp, diax		; Use the Y scale factor, it's smaller
setScaleFactor:
	;
	; si.bp = Scale factor to use
	;
	movwwf	ss:[bx].SDP_scale, sibp
	
quit:
	.leave
	ret
ComputeScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeRangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the bounds of the range which we're going to draw.

CALLED BY:	SpreadsheetDrawRange
PASS:		ss:bp	= Inheritable CellLocals
		ss:bx	= ptr to SpreadsheetDrawParams
RETURN:		CL_docBounds filled in with the bounds of CL_params.REP_bounds
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: assumes upper left cell is origin, such that the bounds
	returned will be starting at (0,0).
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/27/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GRID_PRINT_SPACING	= 3

ComputeRangeBounds	proc	near
	uses	ax, cx, dx
locals	local	CellLocals
	.enter	inherit

	mov	ax, ss:locals.CL_params.REP_bounds.R_top
	mov	ss:locals.CL_origin.CR_row, ax
	mov	ax, ss:locals.CL_params.REP_bounds.R_left
	mov	ss:locals.CL_origin.CR_column, ax
	;
	; Get the (document coordinate) bounds of the draw area
	;
	push	bx
	mov	ax, locals.CL_params.REP_bounds.R_top
	mov	cx, locals.CL_params.REP_bounds.R_left
	mov	dx, locals.CL_params.REP_bounds.R_right
	mov	bx, locals.CL_params.REP_bounds.R_bottom
	call	GetRangeRelBounds32Far
	pop	bx

if	not _GRID_PRINTING
	;
	; For every non-Redwood product, we only bump the bounds
	; for scale-to-fit.  For non-scale-to-fit, it would cause 1
	; less column to fit with a new document.  For Redwood,
	; they always bump the bounds and just live with it.
	;
	test	ss:[bx].SDP_printFlags, mask SPF_SCALE_TO_FIT
	jz	noBump
endif
	;
	; We want to ensure we have room for any boundary lines
	; drawn around the cells, like grid lines or cell borders.
	; Since these boundary lines are drawn outside of the cell
	; boundaries, we need to bump the coordinate out one in each
	; direction. Unfortunately, other code assumes that we have
	; returned bounds starting at (0, 0), so we'll bump the right
	; & bottom by two, and then adjust the translation for margins
	; by one pixel in the top & left (to draw the image in the
	; correct location. Yes, it's a hack.
	;
	add	locals.CL_docBounds.RD_right.low, GRID_PRINT_SPACING
	adc	locals.CL_docBounds.RD_right.high, 0
	add	locals.CL_docBounds.RD_bottom.low, GRID_PRINT_SPACING
	adc	locals.CL_docBounds.RD_bottom.high, 0
noBump::
	;
	; If we're drawing titles, add space for them, too.
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_ROW_COLUMN_TITLES
	jz	skipTitles
	add	locals.CL_docBounds.RD_right.low, SPREADSHEET_RULER_WIDTH
	adc	locals.CL_docBounds.RD_right.high, 0
	add	locals.CL_docBounds.RD_bottom.low, SPREADSHEET_RULER_HEIGHT
	adc	locals.CL_docBounds.RD_bottom.high, 0
skipTitles:

	.leave
	ret
ComputeRangeBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeXScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the X scale factor to use

CALLED BY:	ComputeScale
PASS:		ss:bp	= Pointer to inheritable CellLocals
		ss:bx	= Pointer to SpreadsheetDrawParams
RETURN:		dx.cx	= X scale factor
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	X-Scale = pageWidth / rangeWidth	(48 bit math)
	if X-Scale > MAX_SCALE then
	    X-Scale = MAX_SCALE
	endif
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeXScale	proc	near
locals	local	CellLocals
	ForceRef locals
	.enter	inherit
	;
	; We are in the header or footer. The CL_columnScale to apply is:
	;	printWidth / rangeWidth
	; If this scale is larger than a word value, then we force it to be
	; the maximum scale.
	;
	call	ComputeWidthScale		; dx.cx <- scale factor
	.leave
	ret
ComputeXScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeYScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the Y scale factor to use

CALLED BY:	ComputeScale
PASS:		ss:bp	= Pointer to inheritable CellLocals
		ss:bx	= Pointer to SpreadsheetDrawParams
RETURN:		di.ax	= Y scale factor
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Y-Scale = pageHeight / rangeHeight	(48 bit math)
	if Y-Scale > MAX_SCALE then
	    Y-Scale = MAX_SCALE
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeYScale	proc	near
	uses	bx, cx, dx
locals	local	CellLocals
	.enter	inherit
	;
	; dx.cx <- pageHeight
	;
	mov	cx, ss:[bx].SDP_drawArea.RD_bottom.low
	sub	cx, ss:[bx].SDP_drawArea.RD_top.low

	mov	dx, ss:[bx].SDP_drawArea.RD_bottom.high
	sbb	dx, ss:[bx].SDP_drawArea.RD_top.high
	
	;
	; bx.ax <- rangeHeight
	;
	mov	ax, locals.CL_docBounds.RD_bottom.low
	sub	ax, locals.CL_docBounds.RD_top.low
	
	mov	bx, locals.CL_docBounds.RD_bottom.high
	sbb	bx, locals.CL_docBounds.RD_top.high
	
	;
	; dx.cx = Print height
	; bx.ax = Document height
	;
	call	ChooseAppropriateScale		; dx.cx = scale factor
	
	mov	di, dx				; Return value in di.ax
	mov	ax, cx
	.leave
	ret
ComputeYScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeLeftRightScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the amount for the CL_columnScale

CALLED BY:	SpreadsheetDrawRange
PASS:		ss:bp	= Inheritable CellLocals
		ss:bx	= SpreadsheetDrawParams
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
    if drawing header/footer then
	LR-Scale = pageWidth / rangeWidth	(48 bit math)
	if LR-Scale > MAX_SCALE then
	    LR-Scale = MAX_SCALE
	endif
    endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeLeftRightScale	proc	near
	uses	cx, dx
locals	local	CellLocals
	.enter	inherit
	;
	; Check for in header/footer.
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_HEADER or \
					mask SPF_PRINT_FOOTER
	jz	quit				; Branch if not header/footer
	
	;
	; We are in the header or footer. The CL_columnScale to apply is:
	;	printWidth / rangeWidth
	; If this scale is larger than a word value, then we force it to be
	; the maximum scale.
	;
	call	ComputeWidthScale		; dx.cx <- scale factor

	;
	; dx.cx	= WWFixed scale factor for left/right edges.
	;
	movwwf	locals.CL_columnScale, dxcx	; Save the scale
quit:
	.leave
	ret
ComputeLeftRightScale	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeWidthScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute pageWidth / rangeWidth

CALLED BY:	ComputeLeftRightScale, ComputeXScale
PASS:		ss:bx	= SpreadsheetDrawParams
		ss:bp	= Inheritable CellLocals
RETURN:		dx.cx	= Scale factor
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeWidthScale	proc	near
	uses	ax, bx
locals	local	CellLocals
	.enter	inherit
	;
	; dx.cx <- printWidth
	;
	mov	cx, ss:[bx].SDP_drawArea.RD_right.low
	sub	cx, ss:[bx].SDP_drawArea.RD_left.low

	mov	dx, ss:[bx].SDP_drawArea.RD_right.high
	sbb	dx, ss:[bx].SDP_drawArea.RD_left.high
	
	;
	; bx.ax <- rangeWidth
	;
	mov	ax, locals.CL_docBounds.RD_right.low
	sub	ax, locals.CL_docBounds.RD_left.low
	
	mov	bx, locals.CL_docBounds.RD_right.high
	sbb	bx, locals.CL_docBounds.RD_left.high
	
	;
	; dx.cx = Print width
	; bx.ax = Document width
	;
	call	ChooseAppropriateScale		; dx.cx = scale factor
	.leave
	ret
ComputeWidthScale	endp

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ChooseAppropriateScale
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force a value to be within the allowable scaling.

CALLED BY:	ComputeLeftRightScale, ComputeXScale, ComputeYScale
PASS:		dx.cx = First range
		bx.ax = Second range
RETURN:		dx.cx = First range / Second range
			If result > MAX_SCALE then dx.cx == MAX_SCALE
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ChooseAppropriateScale	proc	near
	call	GrUDivWWFixed			; Divide...
	jc	tooLarge			; Branch on overflow

	;
	; Check for scale factor being too large.
	;
	cmp	dx, MAX_SPREADSHEET_SCALE	; Check for above maximum
	jbe	gotScale			; Branch if scale is O'tay
tooLarge:
	;
	; The scale is too much. Force it to something reasonable.
	;
	mov	dx, MAX_SPREADSHEET_SCALE
	clr	cx

gotScale:
	ret
ChooseAppropriateScale	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ComputeTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compute the translation needed to get the printed output
		into the right place

CALLED BY:	SpreadsheetDrawParams
PASS:		ss:bx	= Pointer to SpreadsheetDrawParams
		ss:bp	= Pointer to inherited CellLocals
RETURN:		SDP_translation set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	translationX = -ssheetX + (marginX + drawAreaX + centerX)/scale
	translationY = -ssheetY + (marginY + drawAreaY + centerY)/scale

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 7/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ComputeTranslation	proc	near
	uses	ax, cx, dx, di, si
locals	local	CellLocals
	.enter	inherit

	clr	ax				; Because we're zeroing stuff...
	;
	; Zero the translation so we can start accumulating there.
	;
	mov	ss:[bx].SDP_translation.PD_x.high, ax
	mov	ss:[bx].SDP_translation.PD_x.low,  ax
	mov	ss:[bx].SDP_translation.PD_y.high, ax
	mov	ss:[bx].SDP_translation.PD_y.low,  ax
	;
	; Now we may want to center the thing, in which case we need to
	; augment the translation value to contain the amount to shift over
	; in order to get us centered.
	;
	call	CenterVertically
	call	CenterHorizontally
	;
	; Now SDP_translation contains the centering value. We add in the
	; amount for the drawArea and the margins.
	;
	call	AdjustForMargins

	.leave
	ret
ComputeTranslation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterVertically
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust translation to center vertically
CALLED BY:	ComputeTranslation()

PASS:		ss:bx - ptr to SpreadsheetDrawParams
		ss:bp - inherited CellLocals stack frame
RETURN:		ss:[bx].SDP_translation - offset for centering vertically
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CenterVertically	proc	near
locals	local	CellLocals
	.enter	inherit

	test	ss:[bx].SDP_printFlags, mask SPF_CENTER_VERTICALLY
	jz	notCenteredVertically
	;
	; We are centering vertically. Compute the difference between the
	; height of the range (scaled) and the height of the draw area.
	;
	push	bx
	mov	dx, ss:locals.CL_docBounds.RD_bottom.low
	sub	dx, ss:locals.CL_docBounds.RD_top.low
	mov	di, ss:locals.CL_docBounds.RD_bottom.high
	sbb	di, ss:locals.CL_docBounds.RD_top.high
	clr	cx				;di:dx.cx <- multiplier
	mov	ax, ss:[bx].SDP_scale.WWF_frac
	mov	bx, ss:[bx].SDP_scale.WWF_int
	clr	si				;si:bx.ax <- multiplicand
	call	GrMulDWFixed			;dx:cx.bx <- result
	pop	bx
	;
	; Compute height of draw area
	;
	mov	ax, ss:[bx].SDP_drawArea.RD_bottom.low
	mov	si, ss:[bx].SDP_drawArea.RD_bottom.high
	sub	ax, ss:[bx].SDP_drawArea.RD_top.low
	sbb	si, ss:[bx].SDP_drawArea.RD_top.high
	;
	; Compute the difference between the height of the range (scaled)
	; and the height of the draw area
	;
	sub	ax, cx
	sbb	si, dx				;si:ax <- difference
	;
	; Finally, take half of that for the translation
	;
	sar	si, 1
	rcr	ax, 1				;si:ax <- 1/2 difference
	mov	ss:[bx].SDP_translation.PD_y.low, ax
	mov	ss:[bx].SDP_translation.PD_y.high, si
notCenteredVertically:

	.leave
	ret
CenterVertically	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CenterHorizontally
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust translation to center horizontally
CALLED BY:	ComputeTranslation()

PASS:		ss:bx - ptr to SpreadsheetDrawParams
		ss:bp - inherited CellLocals stack frame
RETURN:		ss:[bx].SDP_translation - offset for centering horizontally
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CenterHorizontally	proc	near
locals	local	CellLocals
	.enter	inherit

	test	ss:[bx].SDP_printFlags, mask SPF_CENTER_HORIZONTALLY
	jz	notCenteredHorizontally
	;
	; We are centering horizontally. Compute the difference between the
	; width of the range (scaled) and the width of the draw area.
	;
	push	bx
	mov	dx, ss:locals.CL_docBounds.RD_right.low
	sub	dx, ss:locals.CL_docBounds.RD_left.low
	mov	di, ss:locals.CL_docBounds.RD_right.high
	sbb	di, ss:locals.CL_docBounds.RD_left.high
	clr	cx				;di:dx.cx <- multiplier
	mov	ax, ss:[bx].SDP_scale.WWF_frac
	mov	bx, ss:[bx].SDP_scale.WWF_int
	clr	si				;si:bx.ax <- multiplicand
	call	GrMulDWFixed			;dx:cx.bx <- result
	pop	bx
	;
	; Compute width of draw area
	;
	mov	ax, ss:[bx].SDP_drawArea.RD_right.low
	mov	si, ss:[bx].SDP_drawArea.RD_right.high
	sub	ax, ss:[bx].SDP_drawArea.RD_left.low
	sbb	si, ss:[bx].SDP_drawArea.RD_left.high
	;
	; Compute the difference between the width of the range (scaled)
	; and the width of the draw area
	;
	sub	ax, cx
	sbb	si, dx				;si:ax <- difference
	;
	; Finally, take half of that for the translation
	;
	sar	si, 1
	rcr	ax, 1				;si:ax <- 1/2 difference
	mov	ss:[bx].SDP_translation.PD_x.low, ax
	mov	ss:[bx].SDP_translation.PD_x.high, si
notCenteredHorizontally:

	.leave
	ret
CenterHorizontally	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForMargins
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust translation for margins and draw area
CALLED BY:	ComputeTranslation()

PASS:		ss:bx - ptr to SpreadsheetDrawParams
		ss:bp - inherited CellLocals stack frame
RETURN:		ss:[bx].SDP_translation - adjusted for margins and draw area
DESTROYED:	ax

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/26/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AdjustForMargins	proc	near
	uses	dx
		
	.enter	inherit

	movdw	dxax, ss:[bx].SDP_drawArea.RD_top
if	not _GRID_PRINTING
	test	ss:[bx].SDP_printFlags, mask SPF_SCALE_TO_FIT
	jz	noBump1
endif
	;
	; don't want to adjust translation if we are printing to the
	; screen 
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_TO_SCREEN
	jnz	noBump1
	incdw	dxax
noBump1::
	adddw	ss:[bx].SDP_translation.PD_y, dxax

	movdw	dxax, ss:[bx].SDP_drawArea.RD_left
if 	not _GRID_PRINTING
	test	ss:[bx].SDP_printFlags, mask SPF_SCALE_TO_FIT
	jz	noBump2
endif
	;
	; don't want to adjust the translation if we are printing to
	; the screen
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_TO_SCREEN
	jnz	noBump2
	incdw	dxax
noBump2::
	adddw	ss:[bx].SDP_translation.PD_x, dxax

	mov	ax, ss:[bx].SDP_margins.P_y
	add	ss:[bx].SDP_translation.PD_y.low, ax
	adc	ss:[bx].SDP_translation.PD_y.high, 0

	mov	ax, ss:[bx].SDP_margins.P_x
	add	ss:[bx].SDP_translation.PD_x.low, ax
	adc	ss:[bx].SDP_translation.PD_x.high, 0

	.leave
	ret
AdjustForMargins	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ApplyScaleAndTranslation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the translation and scale for drawing

CALLED BY:	SpreadsheetDrawRange
PASS:		ds:si	= Instance ptr
		ss:bx	= SpreadsheetDrawParams
		ss:bp	= Pointer to inherited CellLocals (filled in)
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	NOTE: the order of applying the translation and scale is important.
	The translation is applied first, as it doesn't take the scale into
	account.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ApplyScaleAndTranslation	proc	near
	uses	ax, bx, cx, dx, di, bp
	.enter
	mov	bp, bx			; bp <- frame ptr
	mov	di, ss:[bp].SDP_gstate	; di <- gstate
	;
	; Apply the translation
	;
	movdw	dxcx, ss:[bp].SDP_translation.PD_x
	movdw	bxax, ss:[bp].SDP_translation.PD_y
	call	GrApplyTranslationDWord	; Apply translation
	;
	; Apply the scale
	;
	movwwf	dxcx, ss:[bp].SDP_scale
	movwwf	bxax, dxcx
	call	GrApplyScale		; Apply the scale
	
	.leave
	ret
ApplyScaleAndTranslation	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetRangeEnumParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the RangeEnumParams for the call to DrawRange.

CALLED BY:	SpreadsheetDrawRange
PASS:		ds:si	= Instance ptr
		ss:bx	= Pointer to SpreadsheetDrawParams
		    SDP_printFlags - SpreadsheetDrawFlags
		    SDP_drawArea - area to draw to (RectDWord)
		    SDP_topLeft - top/left (r,c) of area to draw
		    SDP_limit - top/left/bottom/right (r,c) of area to draw
		ss:bp	= Pointer to inherited CellLocals
RETURN:		RangeEnumParams filled in.
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/29/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetRangeEnumParams	proc	near
	uses	ax
locals	local	CellLocals
	.enter	inherit
	test	ss:[bx].SDP_printFlags, mask SPF_SCALE_TO_FIT
	jz	findBounds
	;
	; We are drawing the entire range in a single page.
	; Copy the limit-bounds into the draw-bounds.
	;
	mov	ax, ss:[bx].SDP_limit.CR_start.CR_row
	mov	ss:locals.CL_params.REP_bounds.R_top, ax

	mov	ax, ss:[bx].SDP_limit.CR_start.CR_column
	mov	ss:locals.CL_params.REP_bounds.R_left, ax

	mov	ax, ss:[bx].SDP_limit.CR_end.CR_row
	mov	ss:locals.CL_params.REP_bounds.R_bottom, ax

	mov	ax, ss:[bx].SDP_limit.CR_end.CR_column
	mov	ss:locals.CL_params.REP_bounds.R_right, ax

	jmp	quit

findBounds:
	;
	; Copy the top-left into the RangeEnumParams bounds.
	;
	mov	ax, ss:[bx].SDP_topLeft.CR_column
	mov	ss:locals.CL_params.REP_bounds.R_left, ax
	mov	ax, ss:[bx].SDP_topLeft.CR_row
	mov	ss:locals.CL_params.REP_bounds.R_top, ax
	
	;
	; Figure out the cell under the lower-right point and limit the entire
	; bounds to the range passed in.
	;
	call	FindLowerRightCell
	call	LimitToRange

quit:
	.leave
	ret
SetRangeEnumParams	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FindLowerRightCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the lower-right cell in the drawing area -- this is
		how much will fit on the current page.

CALLED BY:	SpreadsheetDrawRange
PASS:		ds:si	= Instance ptr
		ss:bx	= Pointer to SpreadsheetDrawParams
		    SDP_printFlags - SpreadsuheetDrawFlags
		    SDP_drawArea - area to draw to (RectDWord)
		    SDP_topLeft - top/left (r,c) of area to draw
		    SDP_limit - top/left/bottom/right (r,c) of area to draw
		ss:bp	= Pointer to inherited CellLocals
RETURN:		locals.CL_params.REP_bounds.R_right/bottom set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FindLowerRightCell	proc	near
	class	SpreadsheetClass
	uses	ax, cx, dx, di
locals	local	CellLocals
	.enter	inherit

	push	bx				;save frame pointer
	;
	; Compute the area we will be drawing to.
	;
	mov	ax, ss:[bx].SDP_drawArea.RD_bottom.low
	sub	ax, ss:[bx].SDP_drawArea.RD_top.low
	mov	dx, ss:[bx].SDP_drawArea.RD_bottom.high
	sbb	dx, ss:[bx].SDP_drawArea.RD_top.high
if	not _GRID_PRINTING
	test	ss:[bx].SDP_printFlags, mask SPF_SCALE_TO_FIT
	jz	noBump1
endif
	;
	; if we are drawing to the screen then we do not want
	; eliminate the border cells
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_TO_SCREEN
	jnz	noBump1
	subdw	dxax, GRID_PRINT_SPACING
noBump1::
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_ROW_COLUMN_TITLES
	jz	noRowTitles
	sub	ax, SPREADSHEET_RULER_HEIGHT
	sbb	dx, 0
noRowTitles:
	push	dx				;pass PD_y.high
	push	ax				;pass PD_y.low

	mov	ax, ss:[bx].SDP_drawArea.RD_right.low
	sub	ax, ss:[bx].SDP_drawArea.RD_left.low
	mov	dx, ss:[bx].SDP_drawArea.RD_right.high
	sbb	dx, ss:[bx].SDP_drawArea.RD_left.high
if	not _GRID_PRINTING
	test	ss:[bx].SDP_printFlags, mask SPF_SCALE_TO_FIT
	jz	noBump2
endif
	;
	; if we are drawing to the screen then we do not want
	; eliminate the border cells
	;
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_TO_SCREEN
	jnz	noBump2
	subdw	dxax, GRID_PRINT_SPACING
noBump2::
	test	ss:[bx].SDP_printFlags, mask SPF_PRINT_ROW_COLUMN_TITLES
	jz	noColumnTitles
	sub	ax, SPREADSHEET_RULER_WIDTH
	sbb	dx, 0
noColumnTitles:
	push	dx				;pass PD_x.high
	push	ax				;pass PD_x.low
	
	mov	ax, ss:[bx].SDP_topLeft.CR_row	;ax <- top row
	mov	cx, ss:[bx].SDP_topLeft.CR_column	;cx <- left column
	mov	bx, sp				;ss:bx <- ptr to PointDWord
	call	Pos32ToCellRelFar
	mov	ss:locals.CL_params.REP_bounds.R_right, cx
	mov	ss:locals.CL_params.REP_bounds.R_bottom, ax
	mov	ax, ss:[bx].PD_x.low		;ax <- x offset to right edge
	mov	di, ss:[bx].PD_y.low		;di <- y offset to bottom edge
	add	sp, (size PointDWord)
	pop	bx				;ss:bx <- frame pointer

	;
	; Now we need to know if the lower-right cell will be clipped.
	; If it will, we want to move the range back in so that we won't be
	; printing clipped cells.
	;
	; ax	= X offset to right edge
	; di	= Y offset to bottom edge
	; locals.CL_params.REP_bounds.R_right/bottom =
	;				 Place we think we should draw to
	;
	mov	cx, ss:locals.CL_params.REP_bounds.R_right	;cx <- column
	inc	cx
	mov	dx, ss:[bx].SDP_topLeft.CR_column	;dx <- origin
	push	ax, bx
	call	ColumnGetRelPos32Far		;ax:dx <- position of column
	pop	ax, bx
	
	cmp	dx, ax				;check for column clipped
	jbe	notClippedX			;branch if not clipped
	dec	ss:locals.CL_params.REP_bounds.R_right	;move in one cell
notClippedX:
	
	mov	ax, ss:locals.CL_params.REP_bounds.R_bottom ;ax <- row
	inc	ax
	mov	dx, ss:[bx].SDP_topLeft.CR_row	;dx <- origin
	push	bx
	call	RowGetRelPos32Far		;ax:dx <- position of column
	pop	bx

	cmp	dx, di				;check for column clipped
	jbe	notClippedY			;branch if not clipped
	dec	ss:locals.CL_params.REP_bounds.R_bottom	;move in one cell
notClippedY:
	
	;
	; OK... This is getting ridiculous. Now we need to do one more check
	; to make sure that we are printing at least one cell.
	;
	mov	ax, ss:locals.CL_params.REP_bounds.R_left
	cmp	ax, ss:locals.CL_params.REP_bounds.R_right
	jbe	leftRightOK
	mov	ss:locals.CL_params.REP_bounds.R_right, ax
leftRightOK:

	mov	ax, ss:locals.CL_params.REP_bounds.R_top
	cmp	ax, ss:locals.CL_params.REP_bounds.R_bottom
	jbe	topBottomOK
	mov	ss:locals.CL_params.REP_bounds.R_bottom, ax
topBottomOK:
	.leave
	ret
FindLowerRightCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LimitToRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Limit the area we are thinking of drawing to the range
		specified by the caller

CALLED BY:	SpreadsheetDrawRange
PASS:		ds:si	= Instance ptr
		ss:bx	= Pointer to SpreadsheetDrawParams
		ss:bp	= Pointer to inherited CellLocals
RETURN:		locals.CL_params.REP_bounds.R_bottom/right limited to the range
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LimitToRange	proc	near
	uses	ax
locals	local	CellLocals
	.enter	inherit
	mov	ax, ss:[bx].SDP_limit.CR_end.CR_row
	cmp	ss:locals.CL_params.REP_bounds.R_bottom, ax
	jbe	bottomOK
	mov	ss:locals.CL_params.REP_bounds.R_bottom, ax
bottomOK:

	mov	ax, ss:[bx].SDP_limit.CR_end.CR_column
	cmp	ss:locals.CL_params.REP_bounds.R_right, ax
	jbe	rightOK
	mov	ss:locals.CL_params.REP_bounds.R_right, ax
rightOK:
	.leave
	ret
LimitToRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetNewTopLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the top/left for the next draw.

CALLED BY:	SpreadsheetDrawRange
PASS:		ds:si	= Instance ptr
		ss:bx	= SpreadsheetDrawParams
		ss:bp	= Pointer to inherited CellLocals
RETURN:		ss:bx.SDP_topLeft set to top/left for next draw
		ss:bx.SDP_printFlags with SPF_DONE set if we are finished
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	if rep.right = limit.right then
	    if rep.bottom = limit.bottom then
		done
	    else
		topLeft.top  = rep.bottom
		topLeft.left = limit.left
	    endif
	else
	    topLeft.left = rep.right
	endif

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/26/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetNewTopLeft	proc	near
	uses	ax
locals	local	CellLocals
	.enter	inherit
	mov	ax, ss:locals.CL_params.REP_bounds.R_right
	cmp	ax, ss:[bx].SDP_limit.CR_end.CR_column
	jne	moveRight
	;
	; We have reached the right edge of the area to print. Move down.
	;
	mov	ax, ss:locals.CL_params.REP_bounds.R_bottom
	cmp	ax, ss:[bx].SDP_limit.CR_end.CR_row
	jne	moveDownAndLeft
	;
	; We're done... We've reached the bottom right corner.
	;
	ornf	ss:[bx].SDP_printFlags, mask SPF_DONE
	jmp	quit

moveDownAndLeft:
	;
	; We've reached the right edge, move down and to the left.
	; ax = bottom edge of the area we were just drawing.
	;
	inc	ax
	mov	ss:[bx].SDP_topLeft.CR_row, ax

	mov	ax, ss:[bx].SDP_limit.CR_start.CR_column
	mov	ss:[bx].SDP_topLeft.CR_column, ax
	jmp	quit

moveRight:
	;
	; ax = right edge of the area we were just drawing
	;
	inc	ax
	mov	ss:[bx].SDP_topLeft.CR_column, ax
quit:
	.leave
	ret
SetNewTopLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetRangeBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds of a range

CALLED BY:	via MSG_SPREADSHEET_GET_RANGE_BOUNDS
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
		ax	= MSG_SPREADSHEET_GET_RANGE_BOUNDS
		dx:bp	= Pointer to range (CellRange)
		dx:cx	= Pointer to RectDWord to fill in
RETURN:		RectDWord pointed at by dx:cx filled int

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/30/91		Initial version
	chrisb	8/94		changed to return bounds instead of size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetGetRangeBounds	method	SpreadsheetClass,
				MSG_SPREADSHEET_GET_RANGE_BOUNDS
locals	local	CellLocals

	mov	si, di			; ds:si <- instance ptr
	mov	es, dx			; es:bp <- ptr to range
					; es:cx <- ptr to RectDWord

	mov	di, bp			; es:di <- ptr to range

	.enter
	;
	; Changed 8/94 - clear out the "origin" field, so that the
	; values returned are valid bounds, rather than just the size
	; of the range.
	;
	clr	ss:locals.CL_origin.CR_row
	clr	ss:locals.CL_origin.CR_column
		
	push	cx			; Save ptr to RectDWord
	mov	ax, es:[di].CR_start.CR_row	; ax <- top
	mov	cx, es:[di].CR_start.CR_column	; cx <- left
	mov	bx, es:[di].CR_end.CR_row	; bx <- bottom
	mov	dx, es:[di].CR_end.CR_column	; dx <- right
	call	GetRangeRelBounds32Far	; get bounds of the range
	pop	di				;es:di <- ptr to dest RectDWord

	segmov	ds, ss
	lea	si, ss:locals.CL_docBounds	;ds:si <- ptr to source RectDWord
	mov	cx, (size RectDWord)/(size word)	;cx <- # of words
	rep	movsw

	.leave
	ret
SpreadsheetGetRangeBounds	endm

PrintCode	ends

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetGetDocBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the bounds of the spreadsheet
CALLED BY:	MSG_VIS_LAYER_GET_DOC_BOUNDS

PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of SpreadsheetClass
		ax - the message

		cx:dx - ptr to RectDWord
RETURN:		cx:dx - filled in

DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/10/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetGetDocBounds	method dynamic SpreadsheetClass, \
						MSG_VIS_LAYER_GET_DOC_BOUNDS
	uses	cx
	.enter

	lea	si, ds:[di].SSI_bounds
	movdw	esdi, cxdx			;es:di <- ptr to dest
	mov	cx, (size RectDWord)/(size word)
	rep	movsw

	.leave
	ret
SpreadsheetGetDocBounds	endm

DrawCode	ends
