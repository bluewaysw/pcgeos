COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		uiSpreadsheet.asm

AUTHOR:		Gene Anderson, Feb 12, 1991

ROUTINES:
	Name			Description
	----			-----------
    INT RestrictToMask		Restrict the range of cells to the mask
				bounds

    INT CellRedrawDXCX		Draw one cell by invalidating

    INT CellRedraw		Draw one cell by invalidating

    INT BadCellType		Draw one cell as part of range

    INT CellDrawInt		Draw one cell as part of range

    INT SetClipRect		Set a clip rectangle for the cell bounds

    INT ResetClipRect		Reset the clip rectangle

    INT GetDrawBounds		Get bounds of cell for drawing

    INT MoveCellIntoBounds	Bring a cell into the coordinate space...

    INT ScaleDrawBounds		Scale the cell bounds if necessary.

    INT DrawBackground		Draw background color of cell, if
				necessary.

    INT DrawNoteButton		Draw a note thingy in a cell

    INT CellDrawBorders		Draw cell borders for cell

    INT FormatConstantCellAsText 
				Format a constant cell for display as text

    INT DrawCellString		Draw cell contents as text string

    INT UpdateDocUIRedrawAll	Update the document size, update the UI and
				redraw everything

    INT UpdateUIRedrawAll	Update the UI and redraw everything

    INT UpdateUIRedrawSelection Update the UI and redraw the selection

    INT RedrawSelection		Redraw the selection by invalidating

    INT RedrawRange		Redraw a range by invalidating

    INT GetWinLeftRight		Get the left and right of the window for
				invalidating

MSG_VIS_DRAW			Handle expose events to spreadsheet

EXT	CellRedraw		Redraw one cell (invalidate it, silly)

INT	CellDrawInt		Draw one cell as part of range

INT	DrawNoteButton		Draw special cell note marker


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	2/12/91		Initial revision

DESCRIPTION:
	Routines to implement the Spreadsheet class

	$Id: spreadsheetDraw.asm,v 1.1 97/04/07 11:13:21 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle expose events to redraw the spreadsheet
CALLED BY:	MSG_VIS_DRAW

PASS:		*ds:si - instance data
		ds:di - instance specific data
		es - seg addr of SpreadsheetClass
		ax - the method
		bp - handle of GState
		cl - DrawFlags
RETURN:		none
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	eca		2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SpreadsheetDraw	method dynamic	SpreadsheetClass, MSG_VIS_DRAW

locals	local	CellLocals

	mov	di, bp				;di <- handle of GState

	.enter

	;
	; Save si (for the call to ObjMessage later), but also
	; dereference it.
	;
	push	si				; #1 store obj handle
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset	; ds:si <- SS instance data
		
EC <	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE >
EC <	ERROR_NZ MESSAGE_NOT_HANDLED_IN_ENGINE_MODE		>

		
	;
	; Save the gstate's transformation matrix for other layers
	;
	call	GrSaveState
	;
	; Get the range of cells in the mask
	;
	call	RestrictToMask
	jc	quitPop				;branch if mask NULL
	;
	; Recalculate what is visible.  This expose may be the result of
	; the window getting bigger or more of it being uncovered.
	;
	call	RecalcVisibleRangeGState
	;
	; Translate to the appropriate offset for drawing
	;
	call	TranslateToVisible
	;
	; Initialize things for drawing
	;
	call	InitGStateForDrawing
	push	ax				; #2
	clr	ss:locals.CL_printFlags
	mov	ax, ds:[si].SSI_drawFlags
	mov	ss:locals.CL_drawFlags, ax
	mov	ax, ds:[si].SSI_visible.CR_start.CR_row
	mov	ss:locals.CL_origin.CR_row, ax
	mov	ax, ds:[si].SSI_visible.CR_start.CR_column
	mov	ss:locals.CL_origin.CR_column, ax
	pop	ax				; #2
	;
	; Redraw the range
	;
	call	RangeDraw			;redraw the visible range
	;
	; Redraw header & footer marks, if appropriate
	;
	test	ds:[si].SSI_drawFlags, mask SDF_DRAW_HEADER_FOOTER_BUTTON
	jz	noFooter
	cmp	ds:[si].SSI_header.CR_start.CR_row, -1
	je	noHeader
	stc					;carry <- draw header
	call	DrawHeaderFooterMark
noHeader:
	cmp	ds:[si].SSI_footer.CR_start.CR_row, -1
	je	noFooter
	clc					;carry <- draw footer
	call	DrawHeaderFooterMark

noFooter:
	;
	; If spreadsheet is a layer, don't have to draw.
	;
	test	ds:[si].SSI_attributes, mask SA_SSHEET_IS_LAYER
	jnz	quitPop
	;
	; If we don't have to target or focus, also don't have to draw.
	;
	test	ds:[si].SSI_flags, mask SF_IS_SYS_TARGET or mask SF_IS_SYS_FOCUS
	jz	quitPop
	;
	; Looks like we do want to do the draw here, so go ahead and
	; do it.
	;
	pop	si				; #1 *ds:si <- ptr to instance
	push	bp				; #3
	mov	ax, MSG_SPREADSHEET_INVERT_RANGE_LAST
	mov	bp, di				; bp <- gstate handle
	call	ObjCallInstanceNoLock
	pop	bp				; #3
	jmp	done

quitPop:
	pop	si				; #1 restore stack
done:
	call	GrRestoreState

	.leave
	ret
SpreadsheetDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetInvertRangeLast
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Want to force the selected range inversion to happen
		after all the text and graphic objects have been handled,
		to aviod bug #19095.  This should be done by calling
		this method *after* MSG_VIS_DRAW has been passed to
		all the grobj's in the document's tree.

CALLED BY:	GeoCalcDocumentDraw

PASS:		*ds:si	= SpreadsheetClass object
		ds:di	= SpreadsheetClass instance data
		bp	= gstate handle
		ax	= message #

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	- Check whether we have the target or focus.
	- Save the gstate, and perform necessary window translations.
	- Set graphics area attributes.
	- Do the inversion
	- Restore the gstate.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	4/29/94  	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetInvertRangeLast	method dynamic SpreadsheetClass, 
					MSG_SPREADSHEET_INVERT_RANGE_LAST
	uses	ax, cx, bp
	.enter
	;
	; Check whether we have the target or focus.  If not, bail.
	;
	test	ds:[di].SSI_flags, mask SF_IS_SYS_TARGET or mask SF_IS_SYS_FOCUS
	jz	notSelected

	;
	; Preserve the pointer to instance data and the gstate handle.
	;
	mov	si, di					; ds:si <- inst ptr
	mov	di, bp					; di <- gstate handle

	;
	; Save the gstate
	;
	call	GrSaveState
	
	;
	; Perform necessary window translation before drawing.
	;
	call	TranslateToVisible
		
	;
	; Set the area attrs in case they've changed.
	;
	mov	al, SDM_100
	call	GrSetAreaMask
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	
	;
	; Do the inversion.
	;
	call	InvertRangeAndActiveCell
	mov	ax, ds:[si].SSI_active.CR_row
	mov	cx, ds:[si].SSI_active.CR_column
	call	InvertSelectedVisibleCell

	;
	; Done, so restore the gstate.
	;
	call	GrRestoreState

notSelected:
		
	.leave
	ret
SpreadsheetInvertRangeLast	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestrictToMask
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restrict the range of cells to the mask bounds
CALLED BY:	SpreadsheetDraw()

PASS:		ds:si - ptr to Spreadsheet instance
		di - handle of GState
RETURN:		carry - set if mask NULL
		(ax,cx),
		(bx,dx) - range to draw
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/21/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RestrictToMask	proc	near
	.enter	inherit	SpreadsheetDraw

	;
	; Get the mask bounds
	;
	push	ds, si
	segmov	ds, ss
	lea	si, ss:locals.CL_docBounds	;ds:si <- ptr to 
	call	GrGetMaskBoundsDWord
	pop	ds, si
	jc	done				;branch if mask NULL
	;
	; Figure out the upper left cell of the mask.
	;
	lea	bx, ss:locals.CL_docBounds.RD_left
	call	Pos32ToVisCell
	push	ax, cx
	;
	; Figure out the lower right cell of the mask
	;
	lea	bx, ss:locals.CL_docBounds.RD_right
	call	Pos32ToVisCell
	mov	bx, ax
	mov	dx, cx				;(bx,dx) <- end of range
	pop	ax, cx				;(ax,cx) <- start of range

	clc					;carry <- mask not NULL
done:
	.leave
	ret
RestrictToMask	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellRedraw and CellRedrawDXCX
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one cell by invalidating
CALLED BY:	EnterDataFromEditBar()

PASS:		CellRedraw:
		ds:si - instance data (SpreadsheetClass)
		(ax,cx) - cell to draw
		
		CellRedrawDXCX:
		ds:si - instance data (SpreadsheetClass)
		(dx,cx) - cell to draw
		
RETURN:		none
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Currently calls RangeDraw() with one cell to redraw
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/25/91		Initial version
	jeremy	7/24/92		Added CellRedrawDXCX

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellRedrawDXCX	proc	far
	class	SpreadsheetClass
	mov	ax, dx			; Simple, eh?
	FALL_THRU CellRedraw
CellRedrawDXCX	endp
	
CellRedraw	proc	far
	class	SpreadsheetClass
	uses	ds, si
	.enter

EC <	call	ECCheckInstancePtr		;>
	;
	; Has drawing been suppressed?
	;
	test	ds:[si].SSI_flags, mask SF_SUPPRESS_REDRAW
	jnz	done
	;
	; Is cell even visible?
	;
	call	CellVisible?			;cell visible?
	jnc	done				;branch if not visible
	call	CreateGState			;di <- handle of GState
	;
	; We've got a GState that is translated to the visible region,
	; which is the area we're interested in, so we work relative to
	; it and restrict our visible changes to it.
	;
	call	FindCellOverlap			;(ax,bx,cx,dx) <- bounds
CheckHack <MAX_CELL_BORDER_WIDTH eq 1>
	dec	ax
	dec	bx
	inc	cx
	inc	dx				;bump bounds for borders
	call	GrInvalRect

	call	DestroyGState			;done with GState
done:
	.leave
	ret
CellRedraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellDrawInt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one cell as part of range
CALLED BY:	RangeDraw() via RangeEnum()

PASS:		ss:bp - ptr to RangeDraw() local variables
			CL_drawFlags - SpreadsheetDrawFlags
			CL_origin - origin for drawing
			CL_gstate - GState for drawing
			CL_styleToken - current style token
			CL_data1.low - CellBorderInfo
				--- cell borders that have been seen
				--- for the range being drawn
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any
RETURN:		carry - clear (ie. don't abort enum)
		ss:bp - ptr to RangeDraw() local variables
			CL_data1.low - CellBorderInfo (updated)
			CL_styleToken - current style token (updated)
			CL_data3 - column to right of overlap (if any)
DESTROYED:	none
		ss:bp - ptr to RangeDraw() local variables
			CL_buffer -- destroyed

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

BadCellType	proc	near
EC <	ERROR	ILLEGAL_CELL_TYPE >
NEC <	ret			  >
BadCellType	endp

CellDrawInt	proc	far
	uses	dx, di
	class	SpreadsheetClass

locals		local	CellLocals

	.enter	inherit
EC <	call	ECCheckInstancePtr		;>
EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>

	mov	dx, es:[di]			;es:dx <- ptr to cell data
	mov	di, ss:locals.CL_gstate		;di <- GState to draw with
	;
	; es:dx	= Pointer to cell data, dx == 0 if no data
	; ax/cx	= Row/Column of the cell
	; ds:si	= Spreadsheet instance
	; di	= GState
	;

	;
	; Get draw bounds. If the bounds are outside the graphics system then
	; we want to adjust the graphics system origin to make it OK.
	;
	call	GetDrawBounds			; carry set if out of bounds
	jz	quit				; z flag set if hidden

	pushf					; Save "bounds OK" flag
	jnc	boundsOK
	
	call	GrSaveState			; Save current status
	call	MoveCellIntoBounds		; Adjust the origin
boundsOK:
	push	locals.CL_bounds.R_right	; save for drawing cell
	push	locals.CL_bounds.R_top		; indicator
	;
	; Format the cell data as text and adjust the bounds if needed to
	; account for text larger than the normal cell bounds.
	;
	call	FindCellOverlapNoLock
	;
	; If the text still won't fit, set a clip rectangle so it
	; doesn't munge the cells around it.
	;
	pushf					; save "cell clipped" flag
	jnc	notClipped
	;
	; Save the current GState as there is no other way to reset
	; the clip region after we are done.
	;
	call	GrSaveState
	call	SetClipRect
notClipped:
	;
	; If we're printing the header and footer, we may need to fudge
	; the bounds to account for them spanning the entire page.
	;
	call	ScaleDrawBounds
	;
	; Draw background color if necessary
	;
	call	DrawBackground
	;
	; Draw the cell string (seems sort of anticlimatic by now)
	; if there actually is one.  Empty strings come from cells
	; that have attributes only (like borders or background color).
	;
	LocalIsNull	ss:locals.CL_buffer	;any string?
	jz	skipDraw			;branch if no string
	call	DrawCellString
skipDraw:
	;
	; Record cell borders we've seen
	;
	push	ax
	mov	al, ss:locals.CL_cellAttrs.CA_border
	ornf	{byte}ss:locals.CL_data1, al
	pop	ax
	;
	; Check for wanting to draw any note indicator
	;
	popf
	pop	locals.CL_bounds.R_top
	pop	locals.CL_bounds.R_right
	pushf
	test	ss:locals.CL_drawFlags, mask SDF_DRAW_NOTE_BUTTON
	jz	noNotes				;branch if we don't want this
	call	DrawNoteButton			;draw any note indicator
noNotes:
	;
	; If we set a clip rectangle, get rid of it
	;
	popf					;restore "cell clipped" flag
	jnc	wasntClipped
	;
	; Restore the GState, and thereby reset the clip region to
	; whatever the application may have set it to.
	;
	call	GrRestoreState
wasntClipped:
	;
	; If we adjusted the graphics system origin as part of drawing this
	; cell then we need to adjust it back.
	;
	popf					;restore "bounds OK" flag
	jnc	quit
	call	GrRestoreState			;restore graphics state
quit:

	clc					;don't abort

	.leave
	ret

CellDrawInt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetClipRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a clip rectangle for the cell bounds

CALLED BY:	CellDrawInt()
PASS:		di - handle of GState
		ss:bp - inherited locals
			CL_bounds
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetClipRect		proc	near
	uses	ax, bx, cx, dx, si
locals	local	CellLocals
	.enter	inherit

	mov	ax, ss:locals.CL_bounds.R_left
	mov	bx, ss:locals.CL_bounds.R_top
	mov	cx, ss:locals.CL_bounds.R_right
	mov	dx, ss:locals.CL_bounds.R_bottom
	mov	si, PCT_INTERSECTION
	call	GrSetClipRect

	.leave
	ret
SetClipRect		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDrawBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of cell for drawing
CALLED BY:	CellDrawInt()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx) - (r,c) of cell
		ss:bp - inherited locals
		di - handle of GState
RETURN:		CL_bounds - bounds of cell, 16-bit
		CL_docBounds - bounds of cell, 32-bit
		carry set if any part of the CL_docBounds falls outside of
			the area that the graphics system can handle.
		if carry clear, z flag set if row or column hidden
			(bounds *not* set for this case)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	ASSUMES: assumes MAX(row height) < 64K
	ASSUMES: assumes MAX(column width) < 64K
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/28/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetDrawBounds	proc	near
	uses	ax, bx, cx, dx
locals	local	CellLocals
	.enter	inherit

	call	GetCellRelBounds32
	
EC <	call	ECCheckInstancePtr		;>
	;
	; Check to see if the bounds look reasonable...
	; It's not enough to just check the high word. That must be zero of
	; course, but the low word cannot be larger than the constant
	; LARGEST_POSITIVE_COORDINATE defined by the graphics system.
	;
	mov	ax, LARGEST_POSITIVE_COORDINATE

	tst	ss:locals.CL_docBounds.RD_left.high
	jnz	boundsTooFarOut
	cmp	ss:locals.CL_docBounds.RD_left.low, ax
	ja	boundsTooFarOut

	tst	ss:locals.CL_docBounds.RD_top.high
	jnz	boundsTooFarOut
	cmp	ss:locals.CL_docBounds.RD_top.low, ax
	ja	boundsTooFarOut

	tst	ss:locals.CL_docBounds.RD_right.high
	jnz	boundsTooFarOut
	cmp	ss:locals.CL_docBounds.RD_right.low, ax
	ja	boundsTooFarOut

	tst	ss:locals.CL_docBounds.RD_bottom.high
	jnz	boundsTooFarOut
	cmp	ss:locals.CL_docBounds.RD_bottom.low, ax
	ja	boundsTooFarOut

	;
	; The bounds look OK... Stuff them...
	; ...unless the cell is hidden...
	;
	mov	ax, ss:locals.CL_docBounds.RD_left.low
	cmp	ax, ss:locals.CL_docBounds.RD_right.low
	je	cellHidden			;branch if (left==right)
	mov	ss:locals.CL_bounds.R_left, ax
	mov	bx, ss:locals.CL_docBounds.RD_top.low
	cmp	bx, ss:locals.CL_docBounds.RD_bottom.low
	je	cellHidden			;branch if (top==bottom)
	mov	ss:locals.CL_bounds.R_top, bx
	mov	cx, ss:locals.CL_docBounds.RD_right.low
	mov	ss:locals.CL_bounds.R_right, cx
	mov	dx, ss:locals.CL_docBounds.RD_bottom.low
	mov	ss:locals.CL_bounds.R_bottom, dx
cellHidden:
	clc					; Signal: bounds are OK

quit:
	.leave
	ret

boundsTooFarOut:
	;
	; The bounds of the cell fall outside the area we can draw to. Let the
	; caller know about the problem.
	;
	stc					; Signal: bounds are not OK
	jmp	quit

GetDrawBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MoveCellIntoBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring a cell into the coordinate space...

CALLED BY:	CellDrawInt
PASS:		ss:bp	= Inheritable CellLocals
RETURN:		ss:bp.CL_docBounds set
		ss:bp.CL_bounds set
		ss:bp.CL_gstate modified for new origin
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/22/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MoveCellIntoBounds	proc	near
	uses	ax, bx, cx, dx, di
locals	local	CellLocals
	.enter	inherit
	mov	dx, locals.CL_docBounds.RD_left.high
	mov	cx, locals.CL_docBounds.RD_left.low

	mov	bx, locals.CL_docBounds.RD_top.high
	mov	ax, locals.CL_docBounds.RD_top.low

	mov	di, locals.CL_gstate		; di <- gstate
	call	GrApplyTranslationDWord		; Apply the translation
	
	;
	; Zero the top/left...
	;
	clr	di
	mov	locals.CL_docBounds.RD_left.high, di
	mov	locals.CL_docBounds.RD_left.low,  di
	mov	locals.CL_docBounds.RD_top.high,  di
	mov	locals.CL_docBounds.RD_top.low,   di
	
	mov	locals.CL_bounds.R_left, di
	mov	locals.CL_bounds.R_top, di
	
	;
	; Adjust the bottom/right.
	;
	sub	locals.CL_docBounds.RD_right.low,  cx
	sbb	locals.CL_docBounds.RD_right.high, dx
EC <	ERROR_NZ VISIBLE_POSITION_TOO_LARGE			>

	sub	locals.CL_docBounds.RD_bottom.low,  ax
	sbb	locals.CL_docBounds.RD_bottom.high, bx
EC <	ERROR_NZ VISIBLE_POSITION_TOO_LARGE			>

	;
	; Copy the bottom-right into the cell bounds.
	;
	mov	ax, locals.CL_docBounds.RD_right.low
	mov	locals.CL_bounds.R_right, ax

	mov	ax, locals.CL_docBounds.RD_bottom.low
	mov	locals.CL_bounds.R_bottom, ax
	.leave
	ret
MoveCellIntoBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleDrawBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale the cell bounds if necessary.

CALLED BY:	CellDrawInt
PASS:		ss:bp	= Inheritable CellLocals
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 8/21/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScaleDrawBounds	proc	near
locals		local	CellLocals
	.enter	inherit

	;
	; Check for the situation where we want to scale the left/right edges.
	;
	test	locals.CL_printFlags, mask SPF_PRINT_HEADER or \
					mask SPF_PRINT_FOOTER
	jz	quit				; Branch if not header/footer
	
	;
	; We are doing continuous printing in the header or footer. We need
	; to scale the bounds in CL_bounds.R_left/right by the amount
	; in CL_columnScale.
	;
	
	push	ax, bx, cx, dx			; Save misc registers
	;
	; Scale the left edge...
	;
	mov	dx, locals.CL_bounds.R_left	; dx.cx <- position
	clr	cx
	
	mov	bx, locals.CL_columnScale.high
	mov	ax, locals.CL_columnScale.low
	
	call	GrMulWWFixed			; dx.cx <- result
	mov	locals.CL_bounds.R_left, dx	; Save the scaled result
	
	;
	; Scale the right edge...
	;
	mov	dx, locals.CL_bounds.R_right
	clr	cx
	
	call	GrMulWWFixed			; dx.cx <- result
	mov	locals.CL_bounds.R_right, dx	; Save the scaled result

	pop	ax, bx, cx, dx			; Restore misc registers
quit:
	.leave
	ret
ScaleDrawBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBackground
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw background color of cell, if necessary.
CALLED BY:	CellDrawInt()

PASS:		ss:bp - inherited locals
		(ax,cx) - (r,c) of cell
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 3/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawBackground	proc	near
	uses	ax, bx, cx, dx
locals	local	CellLocals

	cmp	{word}ss:locals.CL_cellAttrs.CA_bgAttrs, \
					(CF_INDEX shl 8) or C_WHITE
	je	done

	.enter	inherit

	;
	; Set the background color.  This is done separately from 
	; SetCellGStateAttrs() because the normal case of C_WHITE
	; does not have to do this.
	;
	mov	al, ss:locals.CL_cellAttrs.CA_bgAttrs.AI_grayScreen
	call	GrSetAreaMask
	mov	ah, ss:locals.CL_cellAttrs.CA_bgAttrs.AI_color.CQ_info
	mov	al, ss:locals.CL_cellAttrs.CA_bgAttrs.AI_color.CQ_redOrIndex
	mov	bx, {word}ss:locals.CL_cellAttrs.CA_bgAttrs.AI_color.CQ_green
	call	GrSetAreaColor
	mov	ax, ss:locals.CL_bounds.R_left
	mov	bx, ss:locals.CL_bounds.R_top
	mov	cx, ss:locals.CL_bounds.R_right
	mov	dx, ss:locals.CL_bounds.R_bottom
	call	GrFillRect

	.leave
done:
	ret
DrawBackground	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawNoteButton
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a note thingy in a cell

CALLED BY:	CellDrawInt
PASS:		es:dx	= Pointer to the cell
		ax/cx	= Row/column
		di	= GState
		ss:bp	= inherited CellLocals
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/15/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawNoteButton	proc	near
	uses	ax, bx, cx, dx
locals	local	CellLocals

	xchg	dx, si				;es:si <- ptr to cell data
	tst	es:[si].CC_notes.segment	;check for notes
	xchg	dx, si				;Restore registers
	jz	quit				;branch if no notes
	
	.enter	inherit

	;
	; Set the area color and mask to something reasonable.
	; NOTE: we don't reset it when we're done, because the
	; only other routine affected by area color when drawing
	; is DrawBackground(), and it explicitly sets the area
	; color and mask itself.
	;
	mov	ax, NOTE_TAB_COLOR		;draw it in red please
	call	GrSetAreaColor
	mov	al, SDM_100
	call	GrSetAreaMask

	mov	ax, ss:locals.CL_bounds.R_right
	mov	bx, ss:locals.CL_bounds.R_top
	mov	cx, ax
	sub	ax, NOTE_TAB_SIZE		;size of thingy is 5
	dec	cx				;don't draw on the border
	mov	dx, bx
	add	dx, NOTE_TAB_SIZE
	inc	bx				;don't draw on the border
	call	GrFillRect			;draw the thingy

	.leave
quit:
	ret
DrawNoteButton	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellDrawBorders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw cell borders for cell
CALLED BY:	RangeDraw() via RangeEnum()

PASS:		ss:bp - ptr to RangeDraw() local variables
			CL_drawFlags - SpreadsheetDrawFlags
			CL_origin - origin for drawing
			CL_gstate - GState for drawing
			CL_styleToken - current style token
		(ax,cx) - cell coordinates (r,c)
		carry - set if cell has data
		*es:di - ptr to cell data, if any
RETURN:		carry - clear (ie. don't abort enum)
		ss:bp - ptr to RangeDraw() local variables
			CL_styleToken - current style token (updated)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	NOTE: cell borders are drawn separately, because if they are drawn
	at the same time as the cells themselves, the background color of
	an adjacent cell will most likely obliterate the border of a cell.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/30/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellDrawBorders	proc	far
	uses	ax, bx, cx, dx, di
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	bx, ss:locals.CL_gstate		;bx <- GState to draw with
	xchg	bx, di				;*es:bx <- ptr to cell data
						;di <- gstate to use
EC <	ERROR_NC BAD_CALLBACK_FOR_EMPTY_CELL	;>
	;
	; Get the border info
	;
	push	ax
	mov	bx, es:[bx]			;es:bx <- ptr to cell data
	mov	dx, bx				;es:dx <- ptr to cell data
	mov	ax, es:[bx].CC_attrs		;ax <- cell style attrs
	mov	bx, offset CA_border		;bx <- offset of attrs
	call	StyleGetAttrByToken		;al <- CellBorderInfo
	;
	; See if there are any borders to draw
	;
	test	al, mask CBI_LEFT or \
			mask CBI_TOP or \
			mask CBI_RIGHT or \
			mask CBI_BOTTOM
	pop	ax
	jz	quit				;branch if no borders
	;
	; Get draw bounds. If the bounds are outside the graphics system then
	; we want to adjust the graphics system origin to make it OK.
	;
	call	GetDrawBounds			; carry set if out of bounds
	jz	quit				; z flag set if hidden

	pushf					; Save "boundsOK" flag
	jnc	boundsOK
	
	call	GrSaveState			; Save current status
	call	MoveCellIntoBounds		; Adjust the origin
boundsOK:
	;
	; Format the cell data as text and adjust the bounds if needed to
	; account for text larger than the normal cell bounds.  This
	; is basically what CellDrawInt() does, so we do the same
	; calculation to match it so the border goes around the text.
	;
	call	FindCellOverlapNoLock
	;
	; Set line attributes
	;
	movdw	bxax, ss:locals.CL_cellAttrs.CA_borderAttrs.AI_color
CheckHack <offset CQ_redOrIndex eq 0>
CheckHack <offset CQ_info eq 1>
CheckHack <offset CQ_green eq 2>
CheckHack <offset CQ_blue eq 3>
	call	GrSetLineColor
	mov	al, ss:locals.CL_cellAttrs.CA_borderAttrs.AI_grayScreen
	call	GrSetLineMask
	;
	; Scale the bounds if we're in the header or footer
	;
	call	ScaleDrawBounds
	;
	; Load the cell bounds, as we'll need at least 3 of them
	;
	mov	ax, ss:locals.CL_bounds.R_left
	mov	bx, ss:locals.CL_bounds.R_top
	mov	cx, ss:locals.CL_bounds.R_right
	mov	dx, ss:locals.CL_bounds.R_bottom
	;
	; Draw the left side, if any
	;
	test	ss:locals.CL_cellAttrs.CA_border, mask CBI_LEFT
	jz	noLeft
	call	GrDrawVLine
noLeft:
	;
	; Draw the top, if any
	;
	test	ss:locals.CL_cellAttrs.CA_border, mask CBI_TOP
	jz	noTop
	call	GrDrawHLine
noTop:
	;
	; Draw the right, if any
	;
	test	ss:locals.CL_cellAttrs.CA_border, mask CBI_RIGHT
	jz	noRight
	push	ax
	mov	ax, cx				;ax <- right side
	call	GrDrawVLine
	pop	ax
noRight:
	;
	; Draw the bottom, if any
	;
	test	ss:locals.CL_cellAttrs.CA_border, mask CBI_BOTTOM
	jz	noBottom
	mov	bx, dx				;bx <- bottom
	call	GrDrawHLine
noBottom:
	;
	; If we adjusted the graphics system origin as part of drawing this
	; cell then we need to adjust it back.
	;
	popf					;restore "bounds OK" flag
	jnc	quit
	call	GrRestoreState			;restore graphics state
quit:

	.leave
	ret
CellDrawBorders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FormatConstantCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Format a constant cell for display as text

CALLED BY:	DrawConstantCell()
PASS:		es:di - ptr to CellCommon data
		ds:si - ptr to SpreadsheetInstance
RETURN:		carry - set if error formatting
		es:di - ptr to CL_buffer (formatted text)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/10/93		broke out from DrawConstantCell()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FormatConstantCellAsText	proc	near
	uses	ax, bx, cx
	class	SpreadsheetClass
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	;
	; Format the number into a buffer.
	;
	mov	bx, ds:[si].SSI_cellParams.CFP_file
	mov	cx, ds:[si].SSI_formatArray

	push	ds, si
	segmov	ds, es, ax
	mov	si, di
	add	si, offset CC_current		;ds:si <- ptr to float number
	segmov	es, ss, ax
	lea	di, ss:locals.CL_buffer		;es:di <- ptr to the buffer

	mov	ax, ss:locals.CL_cellAttrs.CA_format
	call	FloatFormatNumber		;convert to ASCII
	pop	ds, si				;ds:si <- spreadsheet instance

	.leave
	ret
FormatConstantCellAsText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCellString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw cell contents as text string
CALLED BY:	DrawFormulaCell(), DrawTextCell(), DrawConstantCell()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx) - (r,c) of cell
		ss:bp - inherited locals
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/27/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack	<(size JustifyTextParams) eq 8>

DrawCellString	proc	near
	uses	ax, bx, cx, dx, ds, si
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>

	push	ax
	;
	; See if the bounds are in the mask region. If we are printing,
	; the GState refers to a GString, and the cell is always
	; considered "visible"
	;
	mov	ax, ss:locals.CL_bounds.R_left
	mov	bx, ss:locals.CL_bounds.R_top
	mov	cx, ss:locals.CL_bounds.R_right
	mov	dx, ss:locals.CL_bounds.R_bottom
	call	GrTestRectInMask
	cmp	al, TRRT_OUT			;visible?
	pop	ax
	je	done				;branch if not visible

	call	RowGetBaseline			;dx <- baseline offset
	andnf	dx, not (ROW_HEIGHT_AUTOMATIC)

	mov	ax, ss:locals.CL_bounds.R_left
	add	ax, CELL_INSET
	sub	cx, CELL_INSET
	add	bx, dx				;bx <- top + baseline

	mov	di, ss:locals.CL_gstate		;di <- handle of GState
	;
	; Setup params for GrJustifyText()
	;
	mov	ss:locals.CL_justParams.JTP_yPos, bx
	mov	ss:locals.CL_justParams.JTP_rightX, cx
	mov	ss:locals.CL_justParams.JTP_leftX, ax
	lea	bx, ss:locals.CL_justParams	;ss:bx <- ptr to args

	mov	dl, ss:locals.CL_justGeneral	;dl <- Justification

	segmov	ds, ss
	lea	si, ss:locals.CL_buffer		;ds:si <- ptr to string

	clr	cx				;cx <- NULL-terminated text
	call	GrJustifyText
done:

	.leave
	ret
DrawCellString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpreadsheetCompleteRedraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the spreadsheet and all related objects to redraw.

CALLED BY:	via MSG_SPREADSHEET_COMPLETE_REDRAW
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		es	= Class segment
		ax	= Method
RETURN:		nothing
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 5/ 6/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SpreadsheetCompleteRedraw	method	dynamic SpreadsheetClass,
				MSG_SPREADSHEET_COMPLETE_REDRAW

bounds	local	RectDWord
	.enter

	mov	si, di				; ds:si <- instance ptr
EC <	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE >
EC <	ERROR_NZ MESSAGE_NOT_HANDLED_IN_ENGINE_MODE	>

	call	CreateGStateFar			; di <- handle of GState
	;
	; Get the window bounds, and invalidate.  We don't call
	; GetWinBounds32(), as that uses an untranslated GState.
	; That would be fine, except the GState we have is translated,
	; and the result would be invalidating the wrong area.
	;
	push	ds, si
	segmov	ds, ss
	lea	si, ss:bounds			; ds:si <- ptr to win bounds
	call	GrGetWinBoundsDWord
	call	GrInvalRectDWord
	pop	ds, si

	call	DestroyGStateFar		; Nuke gstate
	;
	; Tell the rulers to update themselves, too.
	;
	call	RedrawRulers

	.leave
	ret
SpreadsheetCompleteRedraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateDocUIRedrawAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the document size, update the UI and redraw everything
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		ax - SpreadsheetNotifyFlags
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateDocUIRedrawAll	proc	far
	class	SpreadsheetClass
	.enter

	;
	; Recalculate the document size for the view
	;
	call	RecalcViewDocSize
	;
	; Update the UI and redraw everything
	;
	call	UpdateUIRedrawAll

	.leave
	ret
UpdateDocUIRedrawAll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateUIRedrawAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI and redraw everything

CALLED BY:	UTILITY
PASS:		ds:si - ptr to Spreadsheet instance
		ax - SpreadsheetNotifyFlags
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: if you make changes to the spreadsheet that may change the
	size of the document space (eg. changing a column width), you
	should call UpdateDocUIRedrawAll(), which recalculates the
	document size as well.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateUIRedrawAll		proc	far
	uses	ax, cx, dx, bp, si
	class	SpreadsheetClass
	.enter
	;
	; Update the UI
	;
	call	SS_SendNotification
	;
	; Redraw everything
	;
	mov	si, ds:[si].SSI_chunk
	mov	ax, MSG_SPREADSHEET_COMPLETE_REDRAW
	call	ObjCallInstanceNoLock
	.leave
	ret
UpdateUIRedrawAll		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateUIRedrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the UI and redraw the selection
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		ax - SpreadsheetNotifyFlags
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateUIRedrawSelection	proc	far
	uses	di
	.enter
	;
	; Update the UI
	;
	call	SS_SendNotification
	;
	; Redraw / invalidate the selection
	;
	call	CreateGState
	call	RedrawSelection
	call	DestroyGState

	.leave
	ret
UpdateUIRedrawSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw the selection by invalidating
CALLED BY:	UpdateUIRedrawSelection()

PASS:		ds:si - ptr to Spreadsheet instance
		di - handle of GState (translated to visible)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/16/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RedrawSelection	proc	far
	uses	ax, cx, dx, bp
	class	SpreadsheetClass
	.enter

	;
	; Invalidate the selected area...
	; We've got a GState that is translated to the visible region,
	; which is the area we're interested in, so we work relative to it.
	;
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	mov	cx, ds:[si].SSI_selected.CR_start.CR_column
	mov	bp, ds:[si].SSI_selected.CR_end.CR_row
	mov	dx, ds:[si].SSI_selected.CR_end.CR_column
	call	RedrawRange

	.leave
	ret
RedrawSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedrawRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw a range by invalidating
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
		di - handle of GState (translated to visible)
		(ax,cx)
		(bp,dx) - range (r,c),(r,c)
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/20/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RedrawRange	proc	far
	uses	ax, bx, cx, dx
	class	SpreadsheetClass
	.enter

	;
	; Restrict our changes to the visible range.
	;
	call	RestrictToVisible
	jnc	offScreen			;branch if off-screen
	;
	; Get the top and bottom bound of the range
	;
	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetRelPos16			;dx <- row #1 position
	push	dx
	mov	ax, bp				;ax <- row #2
	inc	ax				;ax <- row #2 + 1
	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetRelPos16			;dx <- row #2 position
	pop	bx				;bx <- row #1 position
CheckHack < MAX_CELL_BORDER_WIDTH eq 1>
	dec	bx
	inc	dx				;bump bounds for borders
	;
	; Bump out as far as we can go left and right, mostly
	; because it seems a good thing...
	;
	call	GetWinLeftRight
	;
	; Invalidate me jesus...
	;
	call	GrInvalRect
offScreen:

	.leave
	ret
RedrawRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWinLeftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the left and right of the window for invalidating

CALLED BY:	UTILITY
PASS:		di - handle of GState
RETURN:		ax - left of window
		cx - right of window
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	5/ 3/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetWinLeftRight		proc	near
	uses	bx, dx
	.enter

	call	GrGetWinBounds

	.leave
	ret
GetWinLeftRight		endp

DrawCode	ends
