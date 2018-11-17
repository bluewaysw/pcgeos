COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		
FILE:		cwordBoardBounds.asm

AUTHOR:		Peter Trinh, Aug 30, 1994

ROUTINES:
	Name			Description
	----			-----------

	METHODS
	-------
	BoardMetaContentViewSizeChanged
	BoardZoomIn
	BoardZoomOut

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardInitBounds			Initializes the Board&Content bounds
	BoardCalculateDimensions	Calculates doc&grid dimensions
	BoardCalculateIdealDocumentDimensions
	BoardCalculateDimensionsHypothetical
	BoardInitViewHintsAndRedoPrimaryGeometry
	BoardEnableDisableZoomButton
	BoardReCalcCellAndPointSize

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/30/94   	Initial revision


DESCRIPTION:
	
	These routines are called during the calculation of the new
	Board bounds.

	$Id: cwordBoardBounds.asm,v 1.1 97/04/04 15:14:17 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CwordBoardBoundsCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardInitBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intialize the document bounds for the Board, Content
		and View. Update the necessary instance data.

		EC Version: will update the EC variables accordingly

CALLED BY:	BoardInitializeBoard

PASS:		*ds:si	- CwordBoardClass object

RETURN:		
		cx - doc width
		dx - doc height

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardInitBounds	proc	far
class	CwordBoardClass
	uses	ax,bx,si,di,bp
	.enter

;;; Verify argument(s)
	Assert	objectPtr	dssi, CwordBoardClass
;;;;;;;;

	; Get access to EC variables
EC <	push	es			; save trash seg	>
EC <	LoadVarSeg	es, ax					>

	GetInstanceDataPtrDSDI	CwordBoard_offset

	mov	ax, ds:[di].CBI_upLeftCoord.P_x
	mov	dx, ds:[di].CBI_upLeftCoord.P_y
EC <	mov	es:[ECupLeftBoard].P_x, ax			>
EC <	mov	es:[ECupLeftBoard].P_y, dx			>
	; Move base coord which will be added to the grid's width and
	; height to get the correct coord for CBI_lowRightCoord.
	mov	ds:[di].CBI_lowRightCoord.P_x, ax
	mov	ds:[di].CBI_lowRightCoord.P_y, dx
EC <	mov	es:[EClowRightBoard].P_x, ax			>
EC <	mov	es:[EClowRightBoard].P_y, dx			>

	; Compute the coord of the upper-left of the grid, and use
	; that for a base for the lower-right point.
if ERROR_CHECK
	pushf							
	add	ax, BOARD_BORDER_WIDTH		; grid left	
	add	dx, BOARD_BORDER_WIDTH		; grid top	
	mov	es:[ECupLeftGrid].P_x, ax
	mov	es:[ECupLeftGrid].P_y, dx
	mov	es:[EClowRightGrid].P_x, ax	; base coord	
	mov	es:[EClowRightGrid].P_y, dx	; base coord	
	popf							
endif
	call	BoardCalculateDimensions

	; Add on to the base coord stored at EClowRightGrid
if ERROR_CHECK
	pushf							
	add	es:[EClowRightGrid].P_y, dx	; + grid_height	
	add	es:[EClowRightGrid].P_x, cx	; + grid_width	
	popf							
endif

	; Add on to the base coord stored at CBI_lowRightCoord ...
	add	ds:[di].CBI_lowRightCoord.P_x, ax
	add	ds:[di].CBI_lowRightCoord.P_y, bx
	; ... and EClowRightBoard
if ERROR_CHECK
	pushf
	add	es:[EClowRightBoard].P_y, ax			
	add	es:[EClowRightBoard].P_x, bx			
	; Update EClowRightDoc
	mov	es:[EClowRightDoc].P_x, ax
	mov	es:[EClowRightDoc].P_y, bx

	;   The graphics system appears to be a little sloppy
	;   about it's calculations in GrGetMaskBounds, but we
	;   don't want to die about it.
	inc	es:[EClowRightDoc].P_x				
	inc	es:[EClowRightDoc].P_y				
	popf							
endif

EC <	pop	es			; restore trash seg	>

	; Apparently the Vis object doesn't convert the width and
	; height into coordinates before storing it in VI_bounds.
	; Thus we have to do the conversion for it.
;	dec	ax				; doc_right = doc_width - 1
;	dec	bx				; doc_bottom = doc_height - 1

	; Update the Vis bounds for the Board and Content
	mov	cx, ax				; VI_bounds.R_right
	mov	dx, bx				; VI_bounds.R_bottom
	mov	ax, MSG_VIS_SET_SIZE
	push	ax, cx, dx			; msg, doc_right/bottom
	call	ObjCallInstanceNoLock
	pop	ax, cx, dx			; msg, doc_right/bottom
	push	cx, dx				; doc_right/bottom
	call	 VisCallParent
	pop	cx, dx				; doc_right/bottom


	.leave
	ret
BoardInitBounds	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCalculateDimensions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will calculate the document width and height of the
		current puzzle and the grid Width and height.

CALLED BY:	BoardInitBounds

PASS:		*ds:si	- CwordBoardClass object

RETURN:		ax	- docWidth	(in points)
		bx	- docHeight
		cx	- gridWidth
		dx	- gridHeight

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
	The document width and height includes the 2*margin indicated
	by CBI_upLeft + the visual Board (the grid and borders). 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCalculateDimensions	proc	near
class	CwordBoardClass

	uses	di
	.enter

;;; Verify argument(s)
	Assert	objectPtr	dssi, CwordBoardClass
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine
	call	EngineGetPuzzleDimensions
	clr	ch					;high byte num cols
	mov	dx, BOARD_BORDER_WIDTH
	mov	ax,ds:[di].CBI_cellWidth
	call	BoardCalculateDimensionsHypothetical
	mov	bx,ax
	mov	dx,cx

	.leave
	ret
BoardCalculateDimensions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCalculateDimensionsHypothetical
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will calculate the document size of the
		current puzzle and the grid size. Document and 
		grid are assumed to be square.

CALLED BY:	BoardInitBounds

PASS: 		ax - cell size
		cx - number of columns
		dx - border width

RETURN:		ax	- doc size
		cx	- grid size

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		
	The document width and height includes the 2*margin indicated
	by CBI_upLeft + the visual Board (the grid and borders). 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 3/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCalculateDimensionsHypothetical	proc	far
class	CwordBoardClass

cellSize	local	word	push	ax
borderWidth	local	word	push	dx
numCols		local	word	push 	cx
numPtsBorder	local	word

	uses	bx,dx
	.enter

	;    Number of pts in border = (border width*2-1), because
	;    cell includes line to it's lower right.
	;

	mov	ax, borderWidth
	shl	ax, 1
	dec	ax
	mov	numPtsBorder, ax
	
	;    Grid size = number of colums * cell size
	;

	mov	ax, numCols
	mul	cellSize
	Assert	e	dx, 0			; no overflow
	mov	cx, ax				; gridWidth

	;    Doc size = grid size + border

	add	ax, numPtsBorder

;;; Verify return value(s)
	Assert	urange	cx, 0, BOARD_MAX_CELL_WIDTH*BOARD_MAX_NUM_COL
;;;;;;;;

	.leave
	ret
BoardCalculateDimensionsHypothetical	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetViewPuzzleData
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set number of rows and square size in view

CALLED BY:	BoardInitializeBoard, BoardCleanUp

PASS:		cl - number of rows

RETURN:		
		nothing

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetViewPuzzleData		proc	far
	uses	ax,bx,di,si
	.enter

	mov	bx,handle CwordView
	mov	si,offset CwordView
	mov	di,mask MF_FIXUP_DS or mask MF_CALL 	; MUST be call!
	mov	ax,MSG_CGV_SET_PUZZLE_DATA
	call	ObjMessage

	.leave
	ret
BoardSetViewPuzzleData		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardRedoPrimaryGeometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the primary to redo the geometry of itself and
		it's children

CALLED BY:	BoardInitBounds
		CwordGenViewZoomIn
		CwordGenViewZoomOut

PASS:		
		nothing

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 7/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardRedoPrimaryGeometry	proc	far
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	mov	bx, handle CwordPrimary		; single-launchable
	mov	si, offset CwordPrimary
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GEN_RESET_TO_INITIAL_SIZE
	mov	dl, VUM_NOW
	call	ObjMessage

	.leave
	ret
BoardRedoPrimaryGeometry	endp








COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetCellSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass
		cx - width/height of cell in pixels

RETURN:		
		nothing
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetCellSize	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_SET_CELL_SIZE
	uses	cx,dx,bp
	.enter

	mov	ds:[di].CBI_cellWidth,cx
	mov	ds:[di].CBI_cellHeight,cx

	mov	dx, BOARD_DEFAULT_TEXT_SIZE_NO_NUMBER
	test	ds:[di].CBI_hideNumber, mask SHOW_TRIANGLE
	jnz	fontWithTriangle
	mov	dx, BOARD_DEFAULT_TEXT_SIZE
fontWithTriangle:

	cmp	cx,BOARD_DEFAULT_CELL_SIZE
	je	setPointSize

	;    Calc scale factor from default cell size to cell size
	;

	mov	dx,cx					;cell size
	mov	bx,BOARD_DEFAULT_CELL_SIZE	
	clr	cx,ax
	call	GrUDivWWFixed

	;    Calc new point size. Scale factor times ideal text size.
	;    Round down point size in hopes of getting a bitmap font
	;    and because we are having some trouble with letter
	;    overlapping number
	;

	clr	ax					;default frac
	mov	bx,BOARD_DEFAULT_TEXT_SIZE_NO_NUMBER	;assumed default int
	cmp	ds:[di].CBI_cellWidth,BOARD_MIN_CELL_SIZE_FOR_REGION_NUMBER
	jb	calcTextSize
	test	ds:[di].CBI_hideNumber, mask SHOW_TRIANGLE
	jnz	calcTextSize
	mov	bx,BOARD_DEFAULT_TEXT_SIZE
calcTextSize:
	call	GrMulWWFixed
setPointSize:
	mov	ds:[di].CBI_pointSize.WBF_int,dx
	clr	ds:[di].CBI_pointSize.WBF_frac		;round down

	call	BoardInitBounds

	.leave
	ret

BoardSetCellSize	endm











CwordBoardBoundsCode	ends




