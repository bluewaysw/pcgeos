COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		GeoCalc
FILE:		spreadsheetDrawUtils.asm

AUTHOR:		Gene Anderson, Jun  6, 1991

ROUTINES:
	Name				Description
	----				-----------
EXT	TranslateToVisible	Translate GState for on-screen drawing
EXT	CreateGState		Create and initialize GState for drawing
EXT	DestroyGState		Destroy GState
EXT	InitGStateForDrawing	Initialize GState for drawing

EXT	InvertActiveVisibleCell		Invert active cell
EXT	InvertSelectedVisibleCell	Invert selected cell
EXT	InvertSelectedVisibleRange	Invert selected range
EXT	InvertSelectedRect		Invert rectangle
EXT	WhiteoutVisibleCell		Erase cell for redrawing

EXT	GetCellVisPos16		Get visual position of cell
EXT	GetCellVisBounds16	Get visual bounds of cell
EXT	GetRangeVisBounds16	Get visual bounds of range
EXT	GetCellRelBounds32	Get 32-bit bounds of cell
EXT	GetRangeRelBounds32	Get 32-bit bounds of range

EXT	CellSelected?		Cell part of selection?
EXT	SingleCell?		Single cell selected?
EXT	CellVisible?		Cell visible?
EXT	RestrictToVisible	Restrict range to visible region

EXT	SetCellGStateAttrs	Setup GState attributes for a cell
EXT	InitGStateForDrawing	Initialize GState for drawing operations


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	6/ 6/91		Initial revision

DESCRIPTION:
	Utility routines for drawing cells.

	$Id: spreadsheetDrawUtils.asm,v 1.1 97/04/07 11:13:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitGStateForDrawing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize GState for drawing
CALLED BY:	CreateGState

PASS:		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
	NOTE: the area color is initialized to black, because most area
	drawing in the spreadsheet is for inverting the selection.
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/24/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitGStateForDrawing	proc	far
	uses	ax
	.enter

	mov	al, CMT_DITHER			;al <- ColorMapMode
	call	GrSetLineColorMap		;set the color map mode to
	call	GrSetAreaColorMap		;  dither -- it gives reasonable
	call	GrSetTextColorMap		;  results for printing to B&W
	mov	al, MM_COPY			;al <- MixMode (COPY)
	call	GrSetMixMode
	mov	ax, (C_BLACK or CF_INDEX shl 8)
	call	GrSetAreaColor
	;
	; Set to draw text from the baseline
	;
	mov	ax, mask TM_DRAW_BASE		;al <- draw from baseline
	call	GrSetTextMode
	;
	; Set the line end to something nice for cell borders.
	;
	mov	al, LE_SQUARECAP
	call	GrSetLineEnd
		
	.leave
	ret
InitGStateForDrawing	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TranslateToVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Translate GState to visible range for drawing
CALLED BY:	SpreadsheetDraw(), CreateGState(), SpreadsheetInvertRangeLast

PASS:		ds:si - ptr to Spreadsheet instance
		di - handle of GState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	5/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TranslateToVisible	proc	near
	uses	ax, bx, cx, dx
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	;
	; Make sure this our GState, and see if the transformation
	; is already valid.
	; NOTE: be sure not to mark the transform valid if this is
	; not our cached GState.
	;
	cmp	di, ds:[si].SSI_gstate		;our GState?
	jne	doTransform			;branch if not ours
	test	ds:[si].SSI_gsRefCount, mask SSRCAF_TRANSFORM_VALID
	jnz	done				;branch if valid
	;
	; Mark the translation in the GState as valid
	;
	ornf	ds:[si].SSI_gsRefCount, mask SSRCAF_TRANSFORM_VALID
doTransform:
	.enter
	;
	; Reset the translation to the default
	;
	call	GrSetDefaultTransform
	;
	; Add the translation to the visible range
	;
	mov	dx, ds:[si].SSI_offset.PD_x.high
	mov	cx, ds:[si].SSI_offset.PD_x.low	;dx:cx <- x translation
	mov	bx, ds:[si].SSI_offset.PD_y.high
	mov	ax, ds:[si].SSI_offset.PD_y.low	;bx:ax <- y translation
	call	GrApplyTranslationDWord

	.leave
done:
	ret
TranslateToVisible	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a GState to draw to the spreadsheet on screen
CALLED BY:	MoveActiveCell()

PASS:		ds:si - instance data of Spreadsheet
RETURN:		di - handle of GState
		ds:si - updated if necessary
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateGStateFar	proc	far
	call	CreateGState
	ret
CreateGStateFar	endp

CreateGState	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;		>
	mov	di, ds:[si].SSI_gstate		;di <- handle of GState
	tst	di				;any GState?
	jz	createGState			;branch if no GState yet
afterCreate:
EC <	push	ax				;>
EC <	mov	al, ds:[si].SSI_gsRefCount	;>
EC <	andnf	al, mask SSRCAF_REF_COUNT	;>
EC <	cmp	al, MAX_GSTATE_REF_COUNT	;>
EC <	ERROR_AE BAD_GS_REF_COUNT		;>
EC <	pop	ax				;>
	inc	ds:[si].SSI_gsRefCount		;one more reference
	;
	; Translate to the visible drawing area
	;
	GOTO	TranslateToVisible

createGState:
	;
	; If we're in engine mode, don't connect the GState to the window
	;
	test	ds:[si].SSI_attributes, mask SA_ENGINE_MODE
	jnz	engineMode			;branch if in engine mode
	;
	; Get a GState attached to our window
	;
	mov	si, ds:[si].SSI_chunk		;*ds:si <- our object
	push	ax, bp
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				;di <- handle of GState
	pop	ax, bp
	jc	initGState			;branch if successfully created
	;
	; We couldn't get a GState for our Window, so just create one
	;
doCreate:
	clr	di				;di <- no Window
	call	GrCreateState
	;
	; Initialize the GState for drawing
	;
initGState:
	mov	si, ds:[si]
	add	si, ds:[si].Spreadsheet_offset	;ds:si <- ptr to instance data
	call	InitGStateForDrawing		;initialize drawing modes
	mov	ds:[si].SSI_gstate, di		;save new GState
	mov	ds:[si].SSI_curAttrs, INVALID_STYLE_TOKEN

	jmp	afterCreate

engineMode:
	mov	si, ds:[si].SSI_chunk		;*ds:si <- our object
	jmp	doCreate
CreateGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy GState used to draw spreadsheet
CALLED BY:	MoveActiveCell()

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DestroyGStateFar	proc	far
	call	DestroyGState
	ret
DestroyGStateFar	endp

DestroyGState	proc	near
	uses	ax
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	al, ds:[si].SSI_gsRefCount
	andnf	al, mask SSRCAF_REF_COUNT
EC <	tst	al				;>
EC <	ERROR_Z BAD_GS_REF_COUNT		;>

	dec	ds:[si].SSI_gsRefCount		;one less reference
	dec	al
	jnz	done				;branch if still references
	;
	; There are no more references, so nuke away
	;
	clr	di
	xchg	di, ds:[si].SSI_gstate		;di <- handle of GState
	clr	ds:[si].SSI_gsRefCount
	call	GrDestroyState
done:
	.leave
	ret
DestroyGState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertActiveVisibleCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select or deselect the active cell on screen
CALLED BY:	CellDraw()

PASS:		(ax,cx) - cell to invert (r,c)
		di - handle of GState
		ds:si - ptr to Spreadsheet instance data
RETURN:		none
DESTROYED:	(GState attrs changed)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Since this does an invert, this routine can be used for
	selecting or deselecting the active cell.
	NOTE: this routine should only be called for screen drawing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvertActiveVisibleCellFar	proc	far
	call	InvertActiveVisibleCell
	ret
InvertActiveVisibleCellFar	endp

InvertActiveVisibleCell	proc	near
	class	SpreadsheetClass
	uses	ax, bx, cx, dx

EC <	call	ECCheckInstancePtr		;>
	call	CellVisible?			;on screen?
	jnc	quit				;branch if not on screen

	.enter

	call	GetCellVisBounds16		;(ax,bx,cx,dx) <- bounds
	cmp	ax, cx				;column hidden?
	je	skipDraw			;branch if column hidden
	cmp	bx, dx				;row hidden?
	je	skipDraw			;branch if row hidden
	push	ax
	mov	al, MM_INVERT			;al <- MixMode (INVERT)
	call	GrSetMixMode
	pop	ax
	call	GrFillRect
	inc	ax				;2*size(inc REG)=2 bytes
	inc	ax				;size(sub REG, #)=3 bytes
	inc	bx
	inc	bx
	dec	cx
	dec	cx
	dec	dx
	dec	dx
	test	ds:[si].SSI_drawFlags, mask SDF_DRAW_GRID
	jz	noGrid
	inc	ax				;bump beyond grid
	inc	bx
noGrid:
	call	GrFillRect
	mov	al, MM_COPY			;al <- MixMode (COPY)
	call	GrSetMixMode
skipDraw:
	.leave
quit:
	ret
InvertActiveVisibleCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertSelectedVisibleCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a selected cell on screen
CALLED BY:	CellDraw(), SpreadsheetInvertRangeLast

PASS:		(ax, cx) - cell to invert (r,c)
		di - handle of GState
		ds:si - ptr to Spreadsheet instance data
RETURN:		none
DESTROYED:	bx, dx (GState attrs changed)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: this routine should only be called for screen drawing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvertSelectedVisibleCellFar	proc	far
	call	InvertSelectedVisibleCell
	ret
InvertSelectedVisibleCellFar	endp

InvertSelectedVisibleCell	proc	near
	uses	ax, cx

EC <	call	ECCheckInstancePtr		;>
	call	CellVisible?			;on screen?
	jnc	done				;branch if not on screen

	.enter

	call	GetCellVisBounds16		;(ax,bx,cx,dx) <- bounds
	call	InvertSelectedRect

	.leave
done:
	ret
InvertSelectedVisibleCell	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertSelectedVisibleRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a selected range
CALLED BY:	ExtendSelectionRow()

PASS:		(ax,cx)
		(bp,dx) - range to invert (r,c),(r,c)
		di - handle of GState
		ds:si - ptr to Spreadsheet instance data
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: this routine should only be called for screen drawing
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvertSelectedVisibleRangeFar	proc	far
	call	InvertSelectedVisibleRange
	ret
InvertSelectedVisibleRangeFar	endp

InvertSelectedVisibleRange	proc	near
	uses	bp
	.enter

EC <	call	ECCheckInstancePtr		;>
	call	RestrictToVisible
	jnc	done				;branch if off scren
	call	GetRangeVisBounds16
	call	InvertSelectedRect
done:
	.leave
	ret
InvertSelectedVisibleRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvertSelectedRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert a selected rectangle
CALLED BY:	InvertSelectedRange(), InvertSelectedCell()

PASS:		(ax,bx,cx,dx) - visual bounds of rectangle
		di - handle of GState
RETURN:		none
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvertSelectedRect	proc	near
	.enter

	push	ax
	mov	al, MM_INVERT			;al <- MixMode (INVERT)
	call	GrSetMixMode
	pop	ax
	call	GrFillRect
	;
	; Reset the draw mode for any subsequent drawing
	;
	mov	al, MM_COPY			;al <- MixMode (COPY)
	call	GrSetMixMode

	.leave
	ret
InvertSelectedRect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCellVisBounds16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the visual bounds of a cell (Window relative)
CALLED BY:	CellDraw(), MoveActiveCell()

PASS:		(ax,cx) - cell (r,c)
		ds:si - ptr to Spreadsheet instance data
RETURN:		(ax,bx,cx,dx) - bounds of cell
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCellVisBounds16	proc	near
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
	mov	dx, ds:[si].SSI_visible.CR_start.CR_column
	call	ColumnGetRelPos16		;dx <- column offset
	push	dx				;save column position
	push	bx				;save column width
	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetRelPos16			;dx <- row offset
	xchg	bx, dx				;bx <- top of cell
	add	dx, bx				;dx <- bottom of cell
	pop	cx				;cx <- column width
	pop	ax				;ax <- column position
	add	cx, ax				;cx <- right of cell

	.leave
	ret
GetCellVisBounds16	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeVisBounds16
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the visual bounds of a range (Window relative)
CALLED BY:	InvertSelectedRange()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx)
		(bp,dx) - range to get bounds of
RETURN:		(ax,bx,cx,dx) - rectangle of bounds
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	Uses the somewhat dubious seeming algorithm for getting the
	bounds of (a,b,c,d) of (pos(a,b),pos(c+1,d+1)).  However,
	because of the way the get position routines work, this isn't
	a problem.  It just forces the routine to do the last add.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRangeVisBounds16	proc	far
	uses	di
	class	SpreadsheetClass
	.enter

EC <	call	ECCheckInstancePtr		;>
EC <	call	ECCheckOrderedCoords		;>

	mov	di, dx				;di <- column #2
	mov	dx, ds:[si].SSI_visible.CR_start.CR_column
	call	ColumnGetRelPos16		;dx <- column #1 position
	push	dx
	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetRelPos16			;dx <- row #1 position
	push	dx
	mov	ax, bp				;ax <- row #2
	inc	ax
	mov	cx, di				;cx <- column #2
	inc	cx
	mov	dx, ds:[si].SSI_visible.CR_start.CR_column
	call	ColumnGetRelPos16
	mov	cx, dx				;cx <- column #2 +1 position
	mov	dx, ds:[si].SSI_visible.CR_start.CR_row
	call	RowGetRelPos16			;dx <- row #2 +1 position
	pop	bx				;bx <- row #1 position
	pop	ax				;ax <- column #1 position

	.leave
	ret
GetRangeVisBounds16	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetWinBounds32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get 32-bit bounds of visible window
CALLED BY:	RecalcVisibleRangeGState()

PASS:		ds:si - ptr to Spreadsheet instance
		ss:bp - inherited CellLocals
		di - handle of GState
RETURN:		ss:bp - CellLocals
			CL_docBounds - 32-bit window bounds (RectDWord)
		cx - width of Window
		dx - height of Window
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This is a little complicated, so I'll explain.  This routine
		was initially passed a GState or a Window.  When we went to
		GrGetWinBoundsDWord instead of WinGetExtWinBounds, it had to be
		a gstate.  The problem is, we don't want the gstate that has
		the translation to the visible portion applied, because that
		will screw up getting the extended bounds (we'll always get
		bounds relative to the translated origin).  SO, we basically
		want to discard the gstate that was passed, but use the 
		window that is attached to the gstate.  This means we make
		a call to get the window handle and allocate a new gstate for
		it.  

		It may be that this routine can be re-written to make all that
		more efficient, but I'll let gene handle that :)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	7/18/91		Initial version
	jim	8/5/91		fixed for GrGetWinBoundsDWord

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetWinBounds32	proc	far
	uses	ds, si, ax, di
locals	local	CellLocals	
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	call	GrGetWinHandle			; ax = window handle
	mov	di, ax				; di = window handle
	call	GrCreateState			; di = gstate handle

	lea	si, ss:locals.CL_docBounds
	segmov	ds, ss				;ds:si <- ptr to RectDWord
	call	GrGetWinBoundsDWord
	mov	cx, ss:locals.CL_docBounds.RD_right.low
	mov	ax, ss:locals.CL_docBounds.RD_right.high
	sub	cx, ss:locals.CL_docBounds.RD_left.low
	sbb	ax, ss:locals.CL_docBounds.RD_left.high
	mov	dx, ss:locals.CL_docBounds.RD_bottom.low
	mov	ax, ss:locals.CL_docBounds.RD_bottom.high
	sub	dx, ss:locals.CL_docBounds.RD_top.low
	sbb	ax, ss:locals.CL_docBounds.RD_top.high
	inc	cx				;bounds are 0 to width-1
	inc	dx				;bounds are 0 to height-1
	call	GrDestroyState			; kill allocated gstate

	.leave
	ret
GetWinBounds32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCellRelBounds32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get 32-bit bounds of a cell relative to specified origin
CALLED BY:	CellDraw(), MoveActiveCell()

PASS:		(ax,cx) - cell (r,c)
		ds:si - ptr to Spreadsheet instance data
		ss:bp - inherited CellLocals:
			CL_origin - origin cell
RETURN:		ss:bp - CellLocals:
			CL_docBounds - 32-bit cell bounds (RectDWord)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetCellRelBounds32	proc	near
	uses	ax, bx, cx, dx
	class	SpreadsheetClass
locals	local	CellLocals
	.enter	inherit


EC <	call	ECCheckInstancePtr		;>
	mov	dx, ss:locals.CL_origin.CR_row
	call	RowGetRelPos32			;ax:dx <- position of row
	mov	ss:locals.CL_docBounds.RD_top.low, dx
	mov	ss:locals.CL_docBounds.RD_top.high, ax
	add	dx, bx
	adc	ax, 0
	mov	ss:locals.CL_docBounds.RD_bottom.low,  dx
	mov	ss:locals.CL_docBounds.RD_bottom.high,  ax

	mov	dx, ss:locals.CL_origin.CR_column
	call	ColumnGetRelPos32
	mov	ss:locals.CL_docBounds.RD_left.low, dx
	mov	ss:locals.CL_docBounds.RD_left.high, ax
	add	dx, bx
	adc	ax, 0
	mov	ss:locals.CL_docBounds.RD_right.low,  dx
	mov	ss:locals.CL_docBounds.RD_right.high,  ax

	.leave
	ret
GetCellRelBounds32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeRelBounds32
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get bounds of range relative to specified origin
CALLED BY:	RangeDrawGrid()

PASS:		ds:si - ptr to Spreadsheet instance
		(ax,cx),
		(bx,dx) - bounds of range (r,c),(r,c)
		ss:bp - inherited CellLocals:
			CL_origin - origin cell
RETURN:		ss:bp - CellLocals:
			CL_docBounds - 32-bit bounds (RectDWord)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 6/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRangeRelBounds32Far	proc	far
	call	GetRangeRelBounds32
	ret
GetRangeRelBounds32Far	endp

GetRangeRelBounds32	proc	near
	uses	ax, bx, cx, dx
locals	local	CellLocals
	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	push	bx				;save bottom row
	push	ax				;save top row
	push	dx				;save right column
	mov	dx, ss:locals.CL_origin.CR_column
	call	ColumnGetRelPos32		;ax:dx <- position of column
	mov	ss:locals.CL_docBounds.RD_left.low, dx
	mov	ss:locals.CL_docBounds.RD_left.high, ax

	pop	cx				;cx <- right column
	inc	cx				;cx <- right column + 1
	mov	dx, ss:locals.CL_origin.CR_column
	call	ColumnGetRelPos32		;ax:dx <- position of column
	mov	ss:locals.CL_docBounds.RD_right.low, dx
	mov	ss:locals.CL_docBounds.RD_right.high, ax

	pop	ax				;ax <- top row
	mov	dx, ss:locals.CL_origin.CR_row
	call	RowGetRelPos32			;ax:dx <- position of row
	mov	ss:locals.CL_docBounds.RD_top.low, dx
	mov	ss:locals.CL_docBounds.RD_top.high, ax

	pop	ax				;ax <- bottom row
	inc	ax				;ax <- bottom row + 1
	mov	dx, ss:locals.CL_origin.CR_row
	call	RowGetRelPos32			;ax:dx <- position of row
	mov	ss:locals.CL_docBounds.RD_bottom.low, dx
	mov	ss:locals.CL_docBounds.RD_bottom.high, ax

	.leave
	ret
GetRangeRelBounds32	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellSelected?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if specified cell is selected
CALLED BY:	CellDraw(), MoveActiveCell()

PASS:		ds:si - ptr to instance data
		(ax,cx) - cell to check
RETURN:		carry - set if selected
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellSelected?	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	ax, ds:[si].SSI_selected.CR_start.CR_row
	jb	notSelected
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_row
	ja	notSelected
	cmp	cx, ds:[si].SSI_selected.CR_start.CR_column
	jb	notSelected
	cmp	cx, ds:[si].SSI_selected.CR_end.CR_column
	ja	notSelected
	stc					;<- indicate selected
	ret

notSelected:
	clc					;<- indicate not selected
	ret
CellSelected?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SingleCell?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if the selection is just a single cell (amoeba)
CALLED BY:	MoveActiveCell(), NotifyStyleChange()

PASS:		ds:si - ptr to instance data
RETURN:		carry - set if single cell
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SingleCell?	proc	far
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	push	ax
	mov	ax, ds:[si].SSI_selected.CR_start.CR_row
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_row
	jne	multiCell

	mov	ax, ds:[si].SSI_selected.CR_start.CR_column
	cmp	ax, ds:[si].SSI_selected.CR_end.CR_column
	jne	multiCell
	stc					;indicate single cell
done:
	pop	ax
	ret

multiCell:
	clc					;indicate multiple cells
	jmp	done
SingleCell?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CellVisible?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See if specified cell is visible
CALLED BY:	CellDraw(), MoveActiveCell()

PASS:		ds:si - ptr to instance data
		(ax,cx) - cell to check
RETURN:		carry - set if visible
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/20/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CellVisible?	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	ax, ds:[si].SSI_visible.CR_start.CR_row
	jb	notVisible
	cmp	ax, ds:[si].SSI_visible.CR_end.CR_row
	ja	notVisible
	cmp	cx, ds:[si].SSI_visible.CR_start.CR_column
	jb	notVisible
	cmp	cx, ds:[si].SSI_visible.CR_end.CR_column
	ja	notVisible
	stc					;<- indicate visible
	ret

notVisible:
	clc					;<- indicate not visible
	ret
CellVisible?	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RestrictToVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restrict range to visible range
CALLED BY:	InvertSelectedRange()

PASS:		(ax,cx)
		(bp,dx) - range (r,c),(r,c)
RETURN:		carry - set if any part of range on screen
		(ax,cx)
		(bp,dx) - (new) range (r,c),(r,c)
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/ 5/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RestrictToVisible	proc	near
	class	SpreadsheetClass

EC <	call	ECCheckInstancePtr		;>
	cmp	ax, ds:[si].SSI_visible.CR_end.CR_row
	ja	notVisible			;below bottom
	cmp	bp, ds:[si].SSI_visible.CR_start.CR_row	
	jb	notVisible			;above top
	cmp	cx, ds:[si].SSI_visible.CR_end.CR_column
	ja	notVisible			;off right side
	cmp	dx, ds:[si].SSI_visible.CR_start.CR_column
	jb	notVisible			;off left side

	push	bx
	mov	bx, ds:[si].SSI_visible.CR_start.CR_row
	cmp	ax, bx				;top on screen?
	jae	topOK
	mov	ax, bx				;ax <- top visible row
topOK:
	mov	bx, ds:[si].SSI_visible.CR_start.CR_column
	cmp	cx, bx				;left on screen?
	jae	leftOK
	mov	cx, bx				;cx <- left visible column
leftOK:
	mov	bx, ds:[si].SSI_visible.CR_end.CR_row
	cmp	bp, bx				;bottom on screen?
	jbe	bottomOK
	mov	bp, bx				;bp <- bottom visible row
bottomOK:
	mov	bx, ds:[si].SSI_visible.CR_end.CR_column
	cmp	dx, bx				;right on screen?
	jbe	rightOK
	mov	dx, bx				;dx <- right visible column
rightOK:
	pop	bx
	stc					;carry <- some visible portion
	ret

notVisible:
	clc					;carry <- no part visible
	ret
RestrictToVisible	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OrderRangeArgs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make sure range arguments are ordered
CALLED BY:	UTILITY

PASS:		(ax,cx),
		(dx,bx) - range args to order
RETURN:		(ax,cx),
		(dx,bx) - ordered range args
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OrderRangeArgs	proc	near
	.enter

	cmp	ax, dx				;rows OK?
	jbe	rowsOK
	xchg	ax, dx
rowsOK:
	cmp	cx, bx				;columns OK?
	jbe	colsOK
	xchg	cx, bx
colsOK:

	.leave
	ret
OrderRangeArgs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetCellGStateAttrs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set attributes in GState for cell attributes.
CALLED BY:	CellDrawInt()

PASS:		di - handle of GState
		dx - style token ID
		ss:bp - inherited CellLocals
			CL_styleToken - last style token used
		ds:si - ptr to Spreadsheet instance
RETURN:		GState attrs set
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
	NOTE: does not set the background color, since that is not
	usually used (ie. when == C_WHITE, no drawing is done)
	NOTE: it is assumed that locals.CL_styleToken will be initialized
	to -1 before calling RangeEnum() to call CellDrawInt().  If this
	is not the case, then the attributes in the GState may not be
	set correctly.
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/ 2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetCellGStateAttrsFar	proc	far
	call	SetCellGStateAttrs
	ret
SetCellGStateAttrsFar	endp

SetCellGStateAttrs	proc	near
	uses	ax, dx
	class	SpreadsheetClass
locals		local	CellLocals

	.enter	inherit

EC <	call	ECCheckInstancePtr		;>
	mov	ax, dx				;ax <- style token ID
	;
	; Get cell attributes for given token if we don't have them already
	;
	cmp	ax, ss:locals.CL_styleToken	;known attributes?
	LONG je	done				;branch if already known
	push	di, es


	segmov	es, ss, di
	lea	di, locals.CL_cellAttrs		;es:di<-ptr to CellAttrs struct
	call	StyleGetStyleByToken		;get associated styles


	pop	di, es
	mov	ss:locals.CL_styleToken, ax	;store new token
	;
	; Is the GState ours and already initialized?
	;
	cmp	di, ds:[si].SSI_gstate		;our GState?
	jne	setAttrs			;branch if not ours
	cmp	ds:[si].SSI_curAttrs, ax	;known attributes?
	je	done				;branch if already set up
	mov	ds:[si].SSI_curAttrs, ax	;store new token
setAttrs:
	;
	; Set all the attrs at once
	;
	push	ds, si
	segmov	ds, ss
	lea	si, ss:locals.CL_buffer		;ds
CheckHack <(size CL_buffer) ge (size TextAttr)>
	;
	; pointsize
	;
	clr	ah
	mov	dx, ss:locals.CL_cellAttrs.CA_pointsize
	shr	dx
	rcr	ah
	shr	dx
	rcr	ah
	shr	dx
	rcr	ah				;dx.ah <- pointsize (WBFixed)
	movwbf	ds:[si].TA_size, dxah
	;
	; font	
	;
	mov	ax, ss:locals.CL_cellAttrs.CA_font
	mov	ds:[si].TA_font, ax
	;
	; text color
	;
	mov	ax, ss:locals.CL_cellAttrs.CA_textAttrs.AI_color.low
	mov	ds:[si].TA_color.low, ax
	mov	ax, ss:locals.CL_cellAttrs.CA_textAttrs.AI_color.high
	mov	ds:[si].TA_color.high, ax
	;
	; text mask
	;
	mov	al, ss:locals.CL_cellAttrs.CA_textAttrs.AI_grayScreen
	mov	ds:[si].TA_mask, al
	;
	; text styles
	;
	mov	al, ss:locals.CL_cellAttrs.CA_style
	mov	ds:[si].TA_styleSet, al
	mov	ds:[si].TA_styleClear, 0xff
	;
	; Text mode
	;
	mov	ax, mask TM_DRAW_BASE or (mask TM_DRAW_BOTTOM or \
			mask TM_DRAW_ACCENT shl 8)
	mov	{word}ds:[si].TA_modeSet, ax
	;
	; FontWidth and FontWeight
	;
	mov	ax, {word}ss:locals.CL_cellAttrs.CA_fontWeight
	mov	{word}ds:[si].TA_fontWeight, ax
CheckHack <(offset TA_fontWidth) eq (offset TA_fontWeight)+1>
CheckHack <(offset CA_fontWidth) eq (offset CA_fontWeight)+1>
	;
	; Set track kerning
	;
	mov	ax, {word}ss:locals.CL_cellAttrs.CA_trackKern
	mov	ds:[si].TA_trackKern, ax
	;
	; zero everything else
	;
	clr	ax
	mov	ds:[si].TA_spacePad.WBF_int, ax
	mov	ds:[si].TA_spacePad.WBF_frac, al
	mov	ds:[si].TA_pattern.GP_type, al
CheckHack <PT_SOLID eq 0>
	call	GrSetTextAttr
	pop	ds, si
done:
	.leave
	ret
SetCellGStateAttrs	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedrawRulers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw the rulers
CALLED BY:	UTILITY

PASS:		ds:si - ptr to Spreadsheet instance
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/23/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RedrawRulers	proc	far
	uses	ax
	.enter

	mov	ax, MSG_VIS_RULER_INVALIDATE_WITH_SLAVES
	call	SendToRuler

	.leave
	ret
RedrawRulers	endp

DrawCode	ends
