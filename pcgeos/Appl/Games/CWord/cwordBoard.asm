COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		Board
FILE:		board.asm

AUTHOR:		Peter Trinh, May  3, 1994

ROUTINES:
	Name			Description
	----			-----------

	METHODS
	-------
	BoardToggleSquareSize		Toggles the square size
	BoardZoomIn			Enlarges the square size
	BoardZoomOut			Shrinks the square size
	BoardDecIncSelectedSquare	Inc or dec the selected square 
	BoardTrackCell			Sets the selected cells and clues
	BoardGainedFocusTargetExcl	Allow the drawing/erasure of the
	BoardLostFocusTargetExcl	  hi-lites when gain/lost the focus 
					  and target.

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardMoveSelectedSquareCommon	Moves selected square.
	BoardMoveSelectedSquareScroll	Scroll after a move
	BoardMoveSelectedSquareScrollNoHiLite
	BoardMoveSelectedSquare		EnsureWordsVisible after a move.
	BoardMoveSelectedSquareNoHiLite
	BoardGetMoveStatusForDest	Gets the status if moved
	BoardSkipOverHoles		Skips the selected square over holes...
	BoardMoveSelectedWord		Moves the selected word to dst.
	BoardMoveSelectedWordNoHiLite
	BoardIncrementSelectedWord	Moves selected word right/down one
	BoardIncrementSelectedWordNoHiLite
	BoardDecrementSelectedWord	Moves selected word left/up one sqr
	BoardDecrementSelectedWordNoHiLite
	BoardEnsureWordsVisible		Makes sure intersecting word visible
	BoardGetGStateDI		Return a GState handle in di
	BoardSetLetterInCell		Enters a letter into a cell.
	BoardClearCell			Enters a minus sign into a cell.
	BoardHintCell			Enters a question mark into a cell.
	BoardCheckForDefaultCellSize
	BoardFoolinAround
	BoardTempHighlightCell

	-----			Instance-Data Routines		-----
	METHODS
	-------
	BoardGetDirection
	BoardSetDirection
	BoardGetSystemType
	BoardSetUpLeftCoord
	BoardGetSelectedWord
	BoardSetSelectedWord
	BoardGetVerificationMode
	BoardSetVerificationMode
	BoardGetSelectedCellToken
	BoardSetSelectedCellToken
	BoardGetSelectedDownClueToken
	BoardSetSelectedDownClueToken
	BoardGetSelectedAcrossClueToken
	BoardSetSelectedAcrossClueToken
	-----							-----

	-----		Coordinate Mapping Routines		-----
	METHODS
	-------
	BoardClipDC		Clips all DC out of the Grid area.
	BoardGetCellBounds	Gets the visual bound of a cell.

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardMapAGCToDC		Maps an Absolute Grid Coordinate to a
				Document Coordinate. 
	BoardMapDCToAGC		For debugging only: Reverse mapping of
				above. 
	BoardMapPointToCellToken Maps a DC to the corresponding CellToken
	BoardMapPointToCellTokenFar
	BoardMapScreenBoundsToCellToken Maps a rectangular bound to CellToken
	BoardMapScreenBoundsToCenterPtDC
	BoardGetCellBoundsProc	Gets the visual bound of a cell
	BoardGetBoundsForFirstNLastCells	Gets the visual bound of a "word"
	BoardMapWordToFirstNLastCells	Gets the "word" the includes the cell
	-----							-----

	-----			Graphic Routines		-----
	METHODS
	-------
	BoardVisDraw		Handles redrawing

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardHiLiteCellCommon	Common routine to draw and erase hilite of cell
	BoardDrawHiLiteCell	Draws the highlight.
	BoardEraseHiLiteCell	Erases the highlight.
	BoardUpdateHiLiteCell	Updates the highlight.
	BoardDrawHiLiteSelectedSquare
	BoardEraseHiLiteSelectedSquare
	BoardHiLiteWordCommon	Common routine to draw and erase hilite of word
	BoardDrawHiLiteWord	Draws the highlight.
	BoardEraseHiLiteWord	Erases the highlight.
	BoardUpdateHiLiteWord	Updtates the highlight.
	BoardDrawHiLiteSelectedWord
	BoardEraseHiLiteSelectedWord
	BoardGetHiLiteParams	Gets parameters for hilite routines
*	BoardMoveHiLiteCell	Moves the highlight of the cell
*	BoardMoveHiLiteWord	Moves the highlight of the word

	BoardDrawGridBorders	Handles redrawing of the grid border.
	BoardDrawCell		Draws the cell.
	BoardDrawCellInitVisualBounds	Aux routine for BoardDrawCell.
	BoardReDrawCell
	BoardReDrawCellFar
	BoardDrawModeCharCell
	BoardDrawModeCharCellFar
	BoardEraseSquare	Draws a white square.
	BoardDrawCellLetter	Draws a given letter into a square.
	BoardDrawCellLetterSetGState	Sets the GState for drawing
	BoardDrawCellNumber	Draws the number of the given square.
*	BoardDrawCellSlashed	Draws a slash through the square.
	BoardDrawCellBorders	Draws the cell border.
	BoardDrawModeCharCell
	-----							-----

	Utility routines
	----------------
	CheckIfHWRChar		HWR Char - recognizable by the HWR library
	CheckIfCwordAlpha	Checks if the char is a Cword alpha char
	CheckIfCwordPunct	Checks if the char is a Cword punctuation
	CheckIfInCharacterSet	Checks if the char is in the given char set.
	GetCharacterSetString	Gets the text string which is the
				character set.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/ 3/94   	Initial revision


DESCRIPTION:
	This file contains the routines of the Board Module.
		

	$Id: cwordBoard.asm,v 1.1 97/04/04 15:13:32 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordCode	segment	resource






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDecIncSelectedSquare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will move the selected square in the appropriate
		direction.  If the next square over is the edge or is
		BOARD_NOT_SELECTABLE, then will not advance the
		selected sqaure and will indicate to the user so.

CALLED BY:	MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE,
		MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE

PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #
		cx - direction to move along

RETURN:		dx	= MovedStatus

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDecIncSelectedSquare	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE,
				MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE
	uses	ax, cx, bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	DirectionType	cx
;;;;;;;;

	mov	bp, ds:[di].CBI_cell
	xchg	ax, bp				; cellToken, message#
	mov	dx, ds:[di].CBI_engine

	; I decided to not to save on the jump commands because the
	; calls to the Engine routine will take up more cycles than
	; can be saved by reducing the jump commands.

	; Decide which way we're moving the selected square.
	cmp	cx, ACROSS
	jne	getVerticalCellToken

	cmp	bp, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	jne	getPrevAcrossCell
	call	EngineGetNextCellTokenInRow
	jmp	storeCellToken

getPrevAcrossCell:
	Assert	e	bp, MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE
	call	EngineGetPrevCellTokenInRow
	jmp	storeCellToken

getVerticalCellToken:
	cmp	bp, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	jne	getPrevUpCell
	call	EngineGetNextCellTokenInColumn
	jmp	storeCellToken

getPrevUpCell:
	Assert	e	bp, MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE
	call	EngineGetPrevCellTokenInColumn
	
storeCellToken:
	; Only store if the new cell is valid, ie. one that is not a
	; hole nor NON-EXISTENT
	cmp	bx, ENGINE_GRID_EDGE		; new cellToken
	mov	dx, MS_EDGE
	je	exit

	mov	ax, bx				; new cellToken
	mov	dx, ds:[di].CBI_engine
	call	EngineGetCellFlags

	test	cl, mask CF_HOLE
	mov	dx, MS_HOLE
	jnz	exit

	test	cl, mask CF_NON_EXISTENT
	mov	dx, MS_EDGE
	jnz	exit

	mov	ax, bx				; new cellToken
	call	BoardMoveSelectedSquareScrollNoHiLite

exit:

	.leave
	ret
BoardDecIncSelectedSquare	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveSelectedSquareCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square, which is stored as an
		instance variable in the Board object, to a particular
		destination.  Will display/erase the highlight
		correspondingly.  The selected word will be
		un/highlighted correspondingly.

		Will also reset the HWR macro if in pen mode.

CALLED BY:	BoardMoveSelectedSquareScroll, BoardMoveSelectedSquare

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (new selected cell)
		
RETURN:		dx	- MovedStatus
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/24/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveSelectedSquareCommon	proc	near
class CwordBoardClass
	uses	ax,bx,cx,bp,di,si
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset

if ERROR_CHECK
	pushf
	test	ds:[di].CBI_highlightStatus, mask HS_SELECTED_SQUARE
	ERROR_NZ BOARD_MOVING_SELECTED_SQUARE_WHILE_HIGHLIGHTED
	popf
endif

	cmp	ds:[di].CBI_system, ST_PEN
	jne	dontReset
	call	BoardGestureResetMacroProcFar
dontReset:

	call	BoardGetMoveStatusForDest
	mov	dx, bx				; MovedStatus
	cmp	dx, MS_MOVED
	jne	exit

	mov	ds:[di].CBI_cell, ax		; new selected cell

	; Find the corresponding ClueTokens
	mov	dx, ds:[di].CBI_engine
	call	EngineMapCellTokenToClueToken	; bx - across, cx - down
	mov	bp, bx				; across clue token

	; Store them in the selected clue instance data
	mov	ds:[di].CBI_acrossClue, bx
	mov	ds:[di].CBI_downClue, cx

	; Highlight and display their text strings.
	; If in pen mode then pass dx=0 to highlight clues in both lists
	; If in keyboard mode then pass current direction so that only
	; the clue in that list will be highlighted.

	clr	dx				;assume highlight both
	cmp	ds:[di].CBI_system,ST_PEN
	je	highlight
	mov	dx,ds:[di].CBI_direction

highlight:
	mov	bx, handle DownClueList		; single-launchable
	mov	si, offset DownClueList
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_CLUE_LIST_DISPLAY_ITEM
	call	ObjMessage

	mov	cx, bp				; across clue token
	mov	bx, handle AcrossClueList	; single-launchable
	mov	si, offset AcrossClueList
	mov	di, mask MF_FIXUP_DS
	mov	ax, MSG_CWORD_CLUE_LIST_DISPLAY_ITEM
	call	ObjMessage

	mov	dx, MS_MOVED
exit:
	.leave
	ret
BoardMoveSelectedSquareCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveSelectedSquareScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square and will scroll only when
		at the edge of the window.

CALLED BY:	BoardSkipOverHoles

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (new selected cell)
		
RETURN:		dx	- MovedStatus (from Common routine)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveSelectedSquareScroll	proc	near
	uses	di
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
;;;;;;;;

	clr	di				; need GState
	BoardEraseHiLites

	call	BoardMoveSelectedSquareScrollNoHiLite

	BoardDrawHiLites

	.leave
	ret
BoardMoveSelectedSquareScroll	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveSelectedSquareScrollNoHiLite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square and will scroll only when
		at the edge of the window.  No highlighting done.

CALLED BY:	BoardDecIncSelectedSquare

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (new selected cell)
		
RETURN:		dx	- MovedStatus (from Common routine)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveSelectedSquareScrollNoHiLite	proc	near
class	CwordBoardClass
	uses	ax,bx,cx,di,bp
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
;;;;;;;;

	; Find out if the cell is beyond the visible window.  If so
	; then cause the intersecting two words to be visible.

	BoardAllocStructOnStack	RectDWord
EC <	ClearBufferForEC	ssbp, RectDWord		>

	push	ax, si				; target cell, CWC object
	mov	bx, handle CwordView		; single-launchable
	mov	si, offset CwordView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	mov	ax, MSG_GEN_VIEW_GET_VISIBLE_RECT
	movdw	cxdx, ssbp
	call	ObjMessage
	movdw	ssbp, cxdx
	pop	ax, si				; CWC object

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	bx, ds:[di].CBI_cellWidth
	mov	cx, ds:[di].CBI_cellHeight
	mov	dx, ds:[di].CBI_engine
	push	ax				; target cell
	call	BoardGetCellBoundsProc

	; Now check if cell bounds are outside visible boundary.
	clr	di
	cmpdw	diax, ss:[bp].RD_left
	pop	ax				; target cell
	jbe	outside
	cmpdw	dibx, ss:[bp].RD_top
	jbe	outside
	cmpdw	dicx, ss:[bp].RD_right
	jae	outside
	cmpdw	didx, ss:[bp].RD_bottom
	jae	outside
	
	call	BoardMoveSelectedSquareCommon
exit:

	BoardDeAllocStructOnStack	RectDWord

	.leave
	ret
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

outside:
	call	BoardMoveSelectedSquareNoHiLite
	jmp	exit

BoardMoveSelectedSquareScrollNoHiLite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveSelectedSquare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square to the given destination and
		makes sure that the across and down "word" is visible.

CALLED BY:	BoardTrackCell, BoardDoActionPeriod

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (new selected cell)
		
RETURN:		dx	- MovedStatus (from Common routine)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveSelectedSquare	proc	far
	uses	di
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
;;;;;;;;

	call	BoardGetGStateDI
	BoardEraseHiLites

	call	BoardMoveSelectedSquareNoHiLite

	BoardDrawHiLites

	call	GrDestroyState
	.leave
	ret
BoardMoveSelectedSquare	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveSelectedSquareNoHiLite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square to the given destination and
		makes sure that the across and down "word" is visible.
		No highlights drawn.

CALLED BY:	BoardMoveSelectedSquare, BoardMoveSelectedWordNoHiLite, 
		BoardMoveSelectedSquareScrollNoHiLite

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (new selected cell)
		
RETURN:		dx	- MovedStatus (from Common routine)
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveSelectedSquareNoHiLite	proc	near
	uses	cx
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
;;;;;;;;

	call	BoardMoveSelectedSquareCommon
	cmp	dx, MS_MOVED
	jne	exit

	; Make sure that the two words crossing at this cell is
	; visible on screen
	call	BoardEnsureWordsVisible

exit:
	.leave
	ret
BoardMoveSelectedSquareNoHiLite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetMoveStatusForDest
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the status of a move to the destination.  But
		will not actually move.

CALLED BY:	Board routines

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (destination)

RETURN:		bx	- MovedStatus
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetMoveStatusForDest	proc	near
class	CwordBoardClass
	uses	cx, dx, di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine
	call	EngineGetCellFlags

	test	cl, mask CF_HOLE
	mov	bx, MS_HOLE
	jnz	exit

	test	cl, mask CF_NON_EXISTENT
	mov	bx, MS_EDGE
	jnz	exit

	mov	bx, MS_MOVED
exit:

	.leave
	ret
BoardGetMoveStatusForDest	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSkipOverHoles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square in the direction specified
		and will skip over all holes encountered.  If there
		are no empty cells after a bunch of holes, ie. holes
		near the edge of the grid, then will not move the
		selected square.  Will update the highlights.

CALLED BY:	BoardKbd[Up/Down/Left/Right]

PASS:		*ds:si	- CwordBoardClass object
		bp	- near ptr to the engine routine to call to
			  get the next cell token.

RETURN:		dx	- MovedStatus (MS_EDGE or MS_MOVED)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSkipOverHoles	proc	far
class	CwordBoardClass
	uses	ax,bx,cx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	nptr		bp, cs
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset

	mov	dx, ds:[di].CBI_engine
	mov	ax, ds:[di].CBI_cell

repeat:
	call	bp				; get next cell token
	cmp	bx, ENGINE_GRID_EDGE
	je	cantSkip
	mov	ax, bx				; next cell token
	call	EngineGetCellFlags
	test	cl, BOARD_NOT_SELECTABLE_CELL
	jnz	repeat

	; Found a SELECTABLE cell.
	; Need to move the whole word as well as the cell.
	call	BoardMoveSelectedSquareScroll

exit:
	.leave
	ret

cantSkip:
	mov	dx, MS_EDGE
	jmp	exit

BoardSkipOverHoles	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected word to the given destination and
		orient in the given direction.  Assumes that the
		destination is a capable of being moved into.

CALLED BY:	BoardSetSelectedWordFromPoint

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (destination)
		cx	- DirectionType (Orientation dst)

RETURN:		dx	- MovedStatus

DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveSelectedWord	proc	far
	uses	di
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;

	clr	di				; need GState
	BoardEraseHiLites

	call	BoardMoveSelectedWordNoHiLite

	BoardDrawHiLites

	.leave
	ret
BoardMoveSelectedWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveSelectedWordNoHiLite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected word to the given destination and
		orient in the given direction.  Assumes that the
		destination is a capable of being moved into.  No
		highlighting though.

CALLED BY:	BoardMoveSelectedWord

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (destination)
		cx	- DirectionType (Orientation dst)

RETURN:		dx	- MovedStatus

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveSelectedWordNoHiLite	proc	near
class	CwordBoardClass
	uses	ax,bx,di
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset

if ERROR_CHECK
	pushf
	test	ds:[di].CBI_highlightStatus, mask HS_SELECTED_WORD
	ERROR_NZ BOARD_MOVING_SELECTED_WORD_WHILE_HIGHLIGHTED
	popf
endif

	call	BoardGetMoveStatusForDest
	mov	dx, bx				; MovedStatus
	cmp	dx, MS_MOVED
	jne	exit

	; Set new orientation.
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	ds:[di].CBI_direction, cx

	; Moving the selected square and word highlights
	call	BoardMoveSelectedSquareNoHiLite
	Assert	e	dx, MS_MOVED


exit:
	.leave
	ret
BoardMoveSelectedWordNoHiLite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardIncrementSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will increment the selected square and word.
		Increment means moving to the right or bottom,
		depending on the given direction.  Preserve the
		current orientation though.

CALLED BY:	BoardKbEnter, BoardKbd[Down/Right]

PASS:		*ds:si	- CwordBoardClass object
		cx	- DirectionType

RETURN:		dx	- MovedStatus
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardIncrementSelectedWord	proc	far
	uses	 di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	DirectionType	cx
;;;;;;;;

	call	BoardGetGStateDI
	BoardEraseHiLites

	call	BoardIncrementSelectedWordNoHiLite

	BoardDrawHiLites
	call	GrDestroyState

	.leave
	ret
BoardIncrementSelectedWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardIncrementSelectedWordNoHiLite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will increment the selected square and word.
		Increment means moving to the right or bottom,
		depending on the given direction.  Preserve the
		current orientation though.  Will not highlight.

CALLED BY:	BoardIncrementSelectedWord

PASS:		*ds:si	- CwordBoardClass object
		cx	- DirectionType

RETURN:		dx	- MovedStatus
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardIncrementSelectedWordNoHiLite	proc	near
class	CwordBoardClass
	uses	ax, bx, cx, di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	DirectionType	cx
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	bx, ds:[di].CBI_cell		; curr cellToken

	; Increment the selected square if possible
	mov	ax, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock		; ax - MovedStatus

	.leave
	ret
BoardIncrementSelectedWordNoHiLite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDecrementSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will decrement the selected square and word.
		Decrement means moving to the left or top, depending
		on the given direction.  Preserve current orientation.

CALLED BY:	BoardKbd[Up/Left]

PASS:		*ds:si	- CwordBoardClass object
		cx	- DirectionType

RETURN:		dx	- MovedStatus
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDecrementSelectedWord	proc	far
	uses	di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	DirectionType	cx
;;;;;;;;

	call	BoardGetGStateDI
	BoardEraseHiLites

	call	BoardDecrementSelectedWordNoHiLite

	BoardDrawHiLites
	call	GrDestroyState

	.leave
	ret
BoardDecrementSelectedWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDecrementSelectedWordNoHiLite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will decrement the selected square and word.
		Decrement means moving to the left or top, depending
		on the given direction.  Preserve current orientation.
		No highlighting though.

CALLED BY:	BoardDecrementSelectedWord

PASS:		*ds:si	- CwordBoardClass object
		cx	- DirectionType

RETURN:		dx	- MovedStatus
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDecrementSelectedWordNoHiLite	proc	near
class	CwordBoardClass
	uses	bx, di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	DirectionType	cx
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	bx, ds:[di].CBI_cell		; curr cellToken

	; Move the square, to see if movable.
	mov	ax, MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock		; ax - MovedStatus

	.leave
	ret
BoardDecrementSelectedWordNoHiLite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardTrackCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures that the cell corresponding to the given
		ClueTokenType is at the top left corner of the view.

CALLED BY:	MSG_CWORD_BOARD_TRACK_CELL
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	= ClueTokenType
		bp	= DirectionType

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/12/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardTrackCell	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_TRACK_CELL
	uses	ax, dx, bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	ClueTokenType	cx, bp
;;;;;;;;

	mov	dx, ds:[di].CBI_engine
	mov	bx, bp				; direction
	mov	ax, cx				; clue token
	call	EngineMapClueToFirstEmptyCell
	cmp	bx, ENGINE_NO_EMPTY_CELL
	je	getFirstCell

gotCellToken:
	call	BoardGetGStateDI
	push	di				; ^h GState
	BoardEraseHiLites
	mov_tr	ax, bp				; direction

	; Store the selected direction and clue
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	ds:[di].CBI_direction, ax
	mov	bp, offset CBI_acrossClue
	cmp	ax, ACROSS
	je	storeClue
	mov	bp, offset CBI_downClue
storeClue:
	mov	ds:[di+bp], cx			; new selected clue

	pop	di				; ^h GState
	mov_tr	ax, bx				; dst cell
	call	BoardMoveSelectedSquareNoHiLite
	Assert	e	dx, MS_MOVED

	BoardDrawHiLites

	call	GrDestroyState

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
getFirstCell:
	mov	bx, bp				; direction
	call	EngineMapClueTokenToFirstCellToken
	jmp	gotCellToken

BoardTrackCell	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCheckPuzzleCompletionStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass

RETURN:		
		cx - PuzzleCompletionStatus
	
DESTROYED:	
		ax

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/30/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCheckPuzzleCompletionStatus	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_CHECK_PUZZLE_COMPLETION_STATUS
	uses	dx
	.enter

	mov	cx,PCS_EMPTY			;assume
	mov	dx,ds:[di].CBI_engine
	tst	dx
	jz	done

	call	EngineCheckForAllCellsEmpty
	jnc	done

	mov	cx,PCS_CORRECT
	call	EngineCheckForAllCellsCorrect
	jnc	done

	mov	cx,PCS_FILLED
	call	EngineCheckForAllCellsFilled
	jnc	done

	mov	cx,PCS_PARTIALLY_FILLED
done:
	.leave
	ret
BoardCheckPuzzleCompletionStatus		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGainedFocusTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upon gaining the sys-target or sys-focus exclusive, will
		clear the corresponding highlightStatus bits and will
		update the hi-hilites. 

CALLED BY:	MSG_META_GAINED_SYS_FOCUS_EXCL
		MSG_META_GAINED_SYS_TARGET_EXCL

PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGainedFocusTargetExcl	method dynamic CwordBoardClass, 
					MSG_META_GAINED_SYS_FOCUS_EXCL,
					MSG_META_GAINED_SYS_TARGET_EXCL
	.enter

	push	ax				; msg number
	mov	di, offset CwordBoardClass
	call	ObjCallSuperNoLock
	pop	ax				; msg number

	mov	cl, mask HS_HAS_TARGET
	cmp	ax, MSG_META_GAINED_SYS_FOCUS_EXCL
	jne	gotSetBit
	mov	bp, mask TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	call	BoardSendFocusNotification
	mov	cl, mask HS_HAS_FOCUS
gotSetBit:
	GetInstanceDataPtrDSDI	CwordBoard_offset
	ornf	ds:[di].CBI_highlightStatus, cl
	tst	ds:[di].CBI_engine
	jz	exit				; jmp if Board not initialized

	call	BoardGetGStateDI

	BoardDrawHiLites

	call	GrDestroyState

exit:
EC <	Destroy	ax, cx, dx, bp					>
	.leave
	ret
BoardGainedFocusTargetExcl	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardLostFocusTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Upon losing the sys-target or sys-focus, will reset
		the handwriting macro and clear the corresponding
		highlightStatus bits, and will erase the hi-lites if
		both the HS_HAS_FOCUS and HS_HAS_TARGET bits are
		cleared.

CALLED BY:	MSG_META_LOST_SYS_FOCUS_EXCL
		MSG_META_LOST_SYS_TARGET_EXCL

PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardLostFocusTargetExcl	method dynamic CwordBoardClass, 
					MSG_META_LOST_SYS_FOCUS_EXCL,
					MSG_META_LOST_SYS_TARGET_EXCL
	.enter

	call	BoardGestureResetMacroProcFar

	mov	cl, not mask HS_HAS_TARGET
	cmp	ax, MSG_META_LOST_SYS_FOCUS_EXCL
	jne	gotClearBit
	clr	bp
	call	BoardSendFocusNotification
	mov	cl, not mask HS_HAS_FOCUS
gotClearBit:
	andnf	ds:[di].CBI_highlightStatus, cl
	tst	ds:[di].CBI_engine
	jz	exit				; exit if Board not initialized

	; Test both bits, if they're cleared, then erase the
	; highlights.

	test	ds:[di].CBI_highlightStatus, mask HS_HAS_TARGET
	jnz	exit
	test	ds:[di].CBI_highlightStatus, mask HS_HAS_FOCUS
	jnz	exit

	call	BoardGetGStateDI
	BoardEraseHiLites
	call	GrDestroyState

exit:
	mov	di, offset CwordBoardClass
	call	ObjCallSuperNoLock

EC <	Destroy	ax, cx, dx, bp					>
	.leave
	ret
BoardLostFocusTargetExcl	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSendFocusNotification
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify pen input control (virtual keyboard) that we
		have gained or lost the focus.

CALLED BY:	BoardGainedFocusTargetExcl
		BoardLostFocusTargetExcl
PASS:		
		bp - TextFocusFlags

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
	srs	9/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSendFocusNotification		proc	near
	uses	ax,bx,cx,dx,di,bp
	.enter

;	Record event to send to ink controller

	mov	ax, MSG_META_NOTIFY
	mov	cx, MANUFACTURER_ID_GEOWORKS
	mov	dx, GWNT_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	mov	di, mask MF_RECORD
	call	ObjMessage

	mov	ax, mask GCNLSF_SET_STATUS
	test	bp, mask  TFF_EDITABLE_TEXT_OBJECT_HAS_FOCUS
	jnz	10$
	ornf	ax, mask GCNLSF_IGNORE_IF_STATUS_TRANSITIONING
10$:

;	Send it to the appropriate gcn list

	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_NOTIFY_FOCUS_TEXT_OBJECT
	clr	ss:[bp].GCNLMP_block
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, ax

	mov	ax, MSG_GEN_PROCESS_SEND_TO_APP_GCN_LIST
	call	GeodeGetProcessHandle
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	call	ObjMessage
	add	sp, dx

	.leave
	ret
BoardSendFocusNotification		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEnsureSelectedWordsVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass

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
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEnsureSelectedWordsVisible	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_ENSURE_SELECTED_WORDS_VISIBLE
	.enter

	tst	ds:[di].CBI_engine
	jz	done
	mov	ax,ds:[di].CBI_cell
	call	BoardEnsureWordsVisible

done:
	.leave
	ret
BoardEnsureSelectedWordsVisible		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEnsureWordsVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that the given word denoted by the given
		cell token and direction will be visible. But also make
		sure that the passed cell is visible if the 
		whole words are too big to be shown
		

CALLED BY:	Board routines

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEnsureWordsVisible	proc	far
	uses	ax,bx,cx,dx,si,di,bp

visibleRect	local	Rectangle

	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	BoardAttemptToMakeWordsVisible

	call	BoardGetVisibleRect

	; Find the rectangular bounds that contains selected cell
	;

	mov	bx, ax				; starting and ending cell
	mov	cx, ACROSS
	call	BoardGetBoundsForFirstNLastCells

	;    If all of selected cell is not visible then make it so
	;

	cmp	ax,visibleRect.R_left
	jb	makeSSVisible
	cmp	cx,visibleRect.R_right
	ja	makeSSVisible
	cmp	bx,visibleRect.R_top
	jb	makeSSVisible
	cmp	dx,visibleRect.R_bottom
	ja	makeSSVisible

done:
	.leave
	ret

makeSSVisible:
	push	bp			;locals
	BoardAllocStructOnStack		MakeRectVisibleParams
EC <	ClearBufferForEC	ssbp, MakeRectVisibleParams	>

	clr	di				; extend for dword
	movdw	ss:[bp].MRVP_bounds.RD_left, diax
	movdw	ss:[bp].MRVP_bounds.RD_top, dibx
	movdw	ss:[bp].MRVP_bounds.RD_right, dicx
	movdw	ss:[bp].MRVP_bounds.RD_bottom, didx
	mov	ss:[bp].MRVP_xMargin, MRVM_0_PERCENT
	mov	ss:[bp].MRVP_yMargin, MRVM_0_PERCENT
	clr	ax
	mov	ss:[bp].MRVP_xFlags,ax
	mov	ss:[bp].MRVP_yFlags,ax

	mov	bx, handle CwordView		; single-launchable
	mov	si, offset CwordView
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	dx, size MakeRectVisibleParams
	call	ObjMessage

	BoardDeAllocStructOnStack	MakeRectVisibleParams
	pop	bp			;locals
	jmp	done


BoardEnsureWordsVisible	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetVisibleRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get rectangle visible in window

CALLED BY:	BoardEnsureWordsVisible

PASS:		ss:bp - inherited stack frame

RETURN:		
		stack frame filled in

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetVisibleRect		proc	far
	uses	ax,bx,cx,dx,di,si
visibleRect	local	Rectangle
	.enter inherit 

	mov	bx, handle CwordView		
	mov	si, offset CwordView
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	mov	ax, MSG_GEN_VIEW_GET_WINDOW
	push	bp				; locals
	call	ObjMessage
	pop	bp				; locals
	jcxz	noWindow

	mov	di,cx				;window
	call	GrCreateState
	call	GrGetWinBounds
	call	GrDestroyState
	mov	visibleRect.R_left,ax
	mov	visibleRect.R_top,bx
	mov	visibleRect.R_right,cx
	mov	visibleRect.R_bottom,dx

done:
	.leave
	ret

noWindow:
	mov	visibleRect.R_left,MIN_COORD
	mov	visibleRect.R_top,MIN_COORD
	mov	visibleRect.R_right,MAX_COORD
	mov	visibleRect.R_bottom,MAX_COORD
	jmp	done

BoardGetVisibleRect		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardAttemptToMakeWordsVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure that the given word denoted by the given
		cell token and direction will be visible. 
		

CALLED BY:	Board routines

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardAttemptToMakeWordsVisible	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Find the rectangular bounds that contains the ACROSS word
	; bounds and the DOWN word bounds.
	mov	bp, ax				; cell
	mov	cx, ACROSS
	call	BoardMapWordToFirstNLastCells
	call	BoardGetBoundsForFirstNLastCells
	push	ax, cx				; left, right
	mov	ax, bp				; cell
	mov	cx, DOWN
	call	BoardMapWordToFirstNLastCells
	call	BoardGetBoundsForFirstNLastCells
	pop	ax, cx				; left, right	

	BoardAllocStructOnStack		MakeRectVisibleParams
EC <	ClearBufferForEC	ssbp, MakeRectVisibleParams	>

	clr	di				; extend for dword

	;   Show a little bit more than the word, so user gets a
	;   feel for where word begins and ends. Don't go negative though.
	;

	sub	ax,BOARD_VISIBLE_RECT_ENHANCEMENT
	jns	10$
	clr	ax
10$:
	sub	bx,BOARD_VISIBLE_RECT_ENHANCEMENT
	jns	20$
	clr	bx
20$:
	add	cx,BOARD_VISIBLE_RECT_ENHANCEMENT
	add	dx,BOARD_VISIBLE_RECT_ENHANCEMENT
	call	BoardCoerceVisibleBoundsAttempt
	movdw	ss:[bp].MRVP_bounds.RD_left, diax
	movdw	ss:[bp].MRVP_bounds.RD_top, dibx
	movdw	ss:[bp].MRVP_bounds.RD_right, dicx
	movdw	ss:[bp].MRVP_bounds.RD_bottom, didx
	mov	ss:[bp].MRVP_xMargin, MRVM_0_PERCENT
	mov	ss:[bp].MRVP_yMargin, MRVM_0_PERCENT
	clr	ax
	mov	ss:[bp].MRVP_xFlags,ax
	mov	ss:[bp].MRVP_yFlags,ax

	mov	bx, handle CwordView		; single-launchable
	mov	si, offset CwordView
	mov	di, mask MF_FIXUP_DS or mask MF_STACK
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	dx, size MakeRectVisibleParams
	call	ObjMessage

	BoardDeAllocStructOnStack	MakeRectVisibleParams

	.leave
	ret
BoardAttemptToMakeWordsVisible	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCoerceVisibleBoundsAttempt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	MSG_GEN_MAKE_RECT_VISIBLE behaves badly if the requested
		rect is larger than the view in either direction. It does
		nothing. So coerce the bounds so to be smaller than
		the view size

CALLED BY:	BoardAttemptToMakeWordsVisible

PASS:		
		ax - left of attempted rect
		bx - top of attempted rect
		cx - right of attempted rect
		dx - bottom of attempted rect

RETURN:		
		cx,dx - possibly changed to better values

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCoerceVisibleBoundsAttempt		proc	near
	uses	di,si
visibleRect	local	Rectangle
	.enter

	call	BoardGetVisibleRect
	mov	di,visibleRect.R_right
	sub	di,visibleRect.R_left		;view width
	mov	si,cx
	sub	si,ax				;attempted width
	cmp	di,si				;view to attempted width
	jb	tooWide

checkHeight:
	mov	di,visibleRect.R_bottom
	sub	di,visibleRect.R_top		;view height
	mov	si,dx
	sub	si,bx				;attempted height
	cmp	di,si				;view to attempted height
	jb	tooHigh

done:
	.leave
	ret

tooWide:
	;    New right = attempted left + view width
	mov	cx,ax
	add	cx,di
	sub	cx,2				;hooey
	jmp	checkHeight

tooHigh:
	;    New bottom = attempted top + view height
	mov	dx,bx
	add	dx,di
	sub	dx,2				;hooey
	jmp	done


BoardCoerceVisibleBoundsAttempt		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetGStateDI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates a GState and returns in in register di

CALLED BY:	PRIVATE!

PASS:		*ds:si	- CwordBoardClass object

RETURN:		^hdi	- GState

DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetGStateDI	proc	far
	uses	ax,cx,dx,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp					; ^h GState

;;; Verify return value(s)
	Assert	gstate	di
;;;;;;;;

	.leave
	ret
BoardGetGStateDI	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the value stored at CBI_direction

CALLED BY:	MSG_CWORD_BOARD_GET_DIRECTION
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		ax	= DirectionType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetDirection	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_GET_DIRECTION
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_direction

	.leave
	ret
BoardGetDirection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the field CBI_direction with the given value

CALLED BY:	MSG_CWORD_BOARD_SET_DIRECTION
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		dx	= DirectionType

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetDirection	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_SET_DIRECTION
	uses	ax,cx,dx
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
	Assert	DirectionType	dx
;;;;;;;;

	call	BoardGetGStateDI
	BoardEraseHiLites

	push	di					;gstate
	GetInstanceDataPtrDSDI CwordBoard_offset
	mov	ds:[di].CBI_direction, dx
	mov	cx,dx
	mov	ax,ds:[di].CBI_cell
	call	BoardMoveSelectedSquare
	pop	di					;gstate

	BoardDrawHiLites

	call	GrDestroyState

	.leave
	ret
BoardSetDirection	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetSystemType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the value stored at CBI_system.

CALLED BY:	MSG_CWORD_BOARD_GET_SYSTEM_TYPE
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		ax	- SystemType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetSystemType	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_GET_SYSTEM_TYPE
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_system

	.leave
	ret
BoardGetSystemType	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetUpLeftCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will assign CBI_upLeftCoord a new value.

CALLED BY:	MSG_CWORD_BOARD_SET_UP_LEFT_COORD
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		dx.cx	= Coordinate value
		bp	= GenValueFlags (not used)

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 3/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetUpLeftCoord	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_SET_UP_LEFT_COORD_X,
					MSG_CWORD_BOARD_SET_UP_LEFT_COORD_Y				
	uses	ax, cx, dx, bp
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	cmp	ax, MSG_CWORD_BOARD_SET_UP_LEFT_COORD_X
	jne	modifyY
	mov	ds:[di].CBI_upLeftCoord.P_x, dx
	jmp	exit

modifyY:
	mov	ds:[di].CBI_upLeftCoord.P_y, dx

exit:
	call	BoardInitBounds

	.leave
	ret
BoardSetUpLeftCoord	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the SelectedCell and the Direction.

CALLED BY:	MSG_CWORD_BOARD_GET_SELECTED_WORD
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		ax	= CBI_cell
		dx	= CBI_direction

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetSelectedWord	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_GET_SELECTED_WORD
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_cell
	mov	dx, ds:[di].CBI_direction

	.leave
	ret
BoardGetSelectedWord	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets both the SelectedCell and Direction

CALLED BY:	MSG_CWORD_BOARD_SET_SELECTED_WORD
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	= CellTokenType
		dx	= DirectionType

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetSelectedWord	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_SET_SELECTED_WORD
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	cx
	Assert	DirectionType	dx
;;;;;;;;

	mov	ds:[di].CBI_cell, cx
	mov	ds:[di].CBI_direction, dx

	.leave
	ret
BoardSetSelectedWord	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetVerificationMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the value stored at CBI_verifyMode.

CALLED BY:	MSG_CWORD_BOARD_GET_VERIFICATION_MODE
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		ax	= VerifyModeType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetVerificationMode	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_GET_VERIFICATION_MODE
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_verifyMode

	.leave
	ret
BoardGetVerificationMode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetVerificationMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the field CBI_verifyMode with the given value.

CALLED BY:	MSG_CWORD_BOARD_SET_VERIFICATION_MODE
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		dx	= VerifyModeType

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetVerificationMode	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_SET_VERIFICATION_MODE
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
	Assert	VerifyModeType	dx
;;;;;;;;

	mov	ds:[di].CBI_verifyMode, dx

	.leave
	ret
BoardSetVerificationMode	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetSelectedCellToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the value stored at field CBI_cell.

CALLED BY:	MSG_CWORD_BOARD_GET_SELECTED_CELL_TOKEN
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		ax	= CellTokenType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetSelectedCellToken	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_GET_SELECTED_CELL_TOKEN
	.enter

;;; Verify arument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_cell

	.leave
	ret
BoardGetSelectedCellToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetSelectedCellToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the field CBI_cell with the given value.

CALLED BY:	MSG_CWORD_BOARD_SET_SELECTED_CELL_TOKEN
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		dx	= CellTokenType

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetSelectedCellToken	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_SET_SELECTED_CELL_TOKEN
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	dx
;;;;;;;;

	mov	ds:[di].CBI_cell, dx

	.leave
	ret
BoardSetSelectedCellToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetSelectedDownClueToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the value stored at CBI_downClue.

CALLED BY:	MSG_CWORD_BOARD_GET_SELECTED_DOWN_CLUE_TOKEN
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		ax	= ClueTokenType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetSelectedDownClueToken	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_GET_SELECTED_DOWN_CLUE_TOKEN
	.enter

;;; Verify incoming arument
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_downClue

	.leave
	ret
BoardGetSelectedDownClueToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetSelectedDownClueToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the field CBI_downClue with the given value.

CALLED BY:	MSG_CWORD_BOARD_SET_SELECTED_DOWN_CLUE_TOKEN
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		dx	= ClueTokenType

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetSelectedDownClueToken	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_SET_SELECTED_DOWN_CLUE_TOKEN
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	ClueTokenType	dx, DOWN
;;;;;;;;

	mov	ds:[di].CBI_downClue, dx

	.leave
	ret
BoardSetSelectedDownClueToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetSelectedAcrossClueToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the value stored at the field CBI_acrossClue.

CALLED BY:	MSG_CWORD_BOARD_GET_SELECTED_ACROSS_CLUE_TOKEN
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		ax	= ClueTokenType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetSelectedAcrossClueToken	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_GET_SELECTED_ACROSS_CLUE_TOKEN
	.enter

;;; Verify incoming arument
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax, ds:[di].CBI_acrossClue

	.leave
	ret
BoardGetSelectedAcrossClueToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetSelectedAcrossClueToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the field CBI_acrossClue with the given value.

CALLED BY:	MSG_CWORD_BOARD_SET_SELECTED_ACROSS_CLUE_TOKEN
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		dx	= ClueTokenType

RETURN:		nothing
DESTROYED:	none
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetSelectedAcrossClueToken	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_SET_SELECTED_ACROSS_CLUE_TOKEN
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	ClueTokenType	dx, ACROSS
;;;;;;;;

	mov	ds:[di].CBI_acrossClue, dx

	.leave
	ret
BoardSetSelectedAcrossClueToken	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardClipDC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will clip the given point if it is outside of the
		Grid area.  After being clipped, a new point that is
		within the Grid area will be returned.  If no clipping
		had taken place, then the point will be returned
		unchanged. 

CALLED BY:	MSG_CWORD_BOARD_CLIP_DC
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx,dx	= Point

RETURN:		cx,dx	= clipped Point
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/27/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardClipDC	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_CLIP_DC
	uses	ax
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Examine the x-coordinate
	mov	ax, ds:[di].CBI_upLeftCoord.P_x
	add	ax, BOARD_BORDER_WIDTH
	cmp	cx, ax
	jge	chkUpperBoundX
	mov	cx, ax
	; Ok to fall through
chkUpperBoundX:
	mov	ax, ds:[di].CBI_lowRightCoord.P_x
	sub	ax, BOARD_BORDER_WIDTH
	cmp	cx, ax 
	jle	doY
	mov	cx, ax

doY:
	; Examine the y-coordinate
	mov	ax, ds:[di].CBI_upLeftCoord.P_y
	add	ax, BOARD_BORDER_WIDTH
	cmp	dx, ax
	jge	chkUpperBoundY
	mov	dx, ax
	; Ok to fall through
chkUpperBoundY:
	mov	ax, ds:[di].CBI_lowRightCoord.P_y
	sub	ax, BOARD_BORDER_WIDTH
	cmp	dx, ax
	jle	exit
	mov	dx, ax

exit:

;;; Verify return value(s)
	Assert	InGrid	cxdx
;;;;;;;;

	.leave
	ret
BoardClipDC	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetCellBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the bounds of a given cell.

PASS:		*ds:si	= CwordBoardClass object
		cx	= CellTokenType

RETURN:		ax	= left
		bx	= top
		cx	= right
		dx	= bottom
	
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 2/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetCellBounds	proc far
	uses	di
	class	CwordBoardClass
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	cx
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	ax, cx				; target cell token
	mov	dx, ds:[di].CBI_engine
	mov	bx, ds:[di].CBI_cellWidth
	mov	cx, ds:[di].CBI_cellHeight

	call	BoardGetCellBoundsProc

	.leave
	ret
BoardGetCellBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMapAGCToDC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts an Absolute Grid Coordinate (column, row)
		into a rectangular bound in document coordinates.

CALLED BY:	DO_ACTION methods

PASS:		*ds:si	- CwordBoardClass object
		bx	- column
		cx	- row

RETURN:		ax	- x-coord
		bx	- y-coord

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMapAGCToDC	proc	near
class	CwordBoardClass
	uses	dx, di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	AGC	bxcx
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset

	; Map the column
	mov	ax, bx					; column
	mul	ds:[di].CBI_cellWidth			; column*cellSize
	Assert	e	dx, 0				; no overflow
	add	ax, ds:[di].CBI_upLeftCoord.P_x		; x-coord
	add	ax, BOARD_BORDER_WIDTH
	push	ax					; save new x

	; Map the row
	mov	ax, ds:[di].CBI_cellHeight
	mul	cx					; row*cellSize
	Assert	e	dx, 0				; no overflow
	mov	bx, ds:[di].CBI_upLeftCoord.P_y
	add	bx, ax					; y-coord
	add	bx, BOARD_BORDER_WIDTH
	pop	ax

	.leave
	ret
BoardMapAGCToDC	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMapDCToAGC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a Document coordinate to the Absolute Grid
		coordinate. 

CALLED BY:	DO_ACTION methods

PASS:		*ds:si	- CwordClass object
		ax	- x-coord in Document Coordinate System
		bx	- y-coord

RETURN:		ax	- column in AGC
		bx	- row in AGC

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMapDCToAGC	proc	near
class	CwordBoardClass
	uses	cx, dx, di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	InDoc		axbx
;;;;;;;;

	mov	cx, ax					; x-coord
	mov	dx, bx					; y-coord
	mov	ax, MSG_CWORD_BOARD_CLIP_DC
	call	ObjCallInstanceNoLock
	mov	ax, cx					; clipped x
	mov	bx, dx					; clipped y

	GetInstanceDataPtrDSDI	CwordBoard_offset

	; Map the x-coord
	sub	ax, ds:[di].CBI_upLeftCoord.P_x		; remove offset
	sub	ax, BOARD_BORDER_WIDTH
	clr	dx					; 32 bit dividend
	div	ds:[di].CBI_cellWidth			; 16 bit divisor
	push	ax					; save column

	; Map the y-coord
	mov	ax, bx
	sub	ax, ds:[di].CBI_upLeftCoord.P_y		; remove offset
	sub	ax, BOARD_BORDER_WIDTH
	clr	dx					; 32 bit dividend
	div	ds:[di].CBI_cellHeight			; 16 bit divisor
	mov	bx, ax					; row
	pop	ax					; column

;;; Verify return value(s)
	Assert	AGC	axbx
;;;;;;;;
	
	.leave
	ret
BoardMapDCToAGC	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMapPointToCellToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps a given point to the corresponding CellToken.

CALLED BY:	BoardRedrawGrid

PASS:		*ds:si	- CwordBoardClass object
		ax	- x-coord
		bx	- y-coord

RETURN:		cx	- CellTokenType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMapPointToCellToken	proc	near
class CwordBoardClass
	uses	ax,bx,dx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	InDoc		axbx
;;;;;;;;

	mov	cx, ax
	mov	dx, bx
	mov	ax, MSG_CWORD_BOARD_CLIP_DC
	call	ObjCallInstanceNoLock
	mov	ax, cx
	mov	bx, dx
	call	BoardMapDCToAGC			; Get AGC

	; Get Engine Token
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine

	call	EngineMapAGCToCellToken		; get mapping

;;; Verify return value(s)
	Assert	CellTokenType	cx
;;;;;;;;

	.leave
	ret
BoardMapPointToCellToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMapPointToCellTokenFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far version of BoardMapPointToCellToken

CALLED BY:	BoardMapScreenBoundsToCellToken

PASS:		*ds:si	- CwordBoardClass object
		ax	- x-coord
		bx	- y-coord

RETURN:		cx	- CellTokenType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMapPointToCellTokenFar	proc	far
	.enter

	call	BoardMapPointToCellToken

	.leave
	ret
BoardMapPointToCellTokenFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetCellBoundsProc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the visual bound of a given CellTokenType.

CALLED BY:	BoardGetCellBounds

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType
		dx	- EngineTokenType

		bx	- CellWidth
		cx	- CellHeight

RETURN:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom
	
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetCellBoundsProc	proc	near
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
;;;;;;;;

	push	bx				; cellWidth
	push	cx				; cellHeight

	call	EngineGetCellAGC
	call	BoardMapAGCToDC

	pop	dx				; cellHeight
	pop	cx				; cellWidth
	add	cx, ax
	add	dx, bx
	dec	cx				; right
	dec	dx				; bottom

;;; Verif return value(s)
	Assert	InGrid	axbx
	Assert	InGrid	cxdx
;;;;;;;;

	.leave
	ret
BoardGetCellBoundsProc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetBoundsForFirstNLastCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the bounds of a "word", which is bounded by a
		"head" cellToken and a "tail" cellToken.

CALLED BY:	Board routines

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType (head)
		bx	- CellTokenType (tail)

RETURN:		ax	- left
		bx	- top
		cx	- right
		dx	- bottom

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetBoundsForFirstNLastCellsFar	proc	far
	call	BoardGetBoundsForFirstNLastCells
	ret
BoardGetBoundsForFirstNLastCellsFar	endp

BoardGetBoundsForFirstNLastCells	proc	near
class	CwordBoardClass
	uses	di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	CellTokenType	bx
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine
	push	bx				; tail cellToken
	mov	bx, ds:[di].CBI_cellWidth
	mov	cx, ds:[di].CBI_cellHeight
	call	BoardGetCellBoundsProc
	pop	cx				; tail cellToken
	push	ax, bx				; left, top
	mov	ax, cx				; tail
	mov	dx, ds:[di].CBI_engine
	mov	bx, ds:[di].CBI_cellWidth
	mov	cx, ds:[di].CBI_cellHeight
	call	BoardGetCellBoundsProc
	pop	ax, bx				; left, top

;;; Verify return value(s)
	Assert	l	ax, cx			; left < right
	Assert	l	bx, dx			; top < bottom
	Assert	InDoc	axcx
	Assert	InDoc	bxdx
;;;;;;;;

	.leave
	ret
BoardGetBoundsForFirstNLastCells	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMapWordToFirstNLastCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps the given cell token to a "word", the head and
		tail cell tokens.  The orientation of the "word" is
		given by the DirectionType. 

CALLED BY:	Board routines

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType
		cx	- DirectionType of word

RETURN:		ax	- CellTokenType (head)
		bx	- CellTokenType (tail)

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMapWordToFirstNLastCellsFar	proc	far
	call	BoardMapWordToFirstNLastCells
	ret
BoardMapWordToFirstNLastCellsFar	endp


BoardMapWordToFirstNLastCells	proc	near
class	CwordBoardClass
	uses	di, dx
	.enter

;;; Verify argument(s)
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine
	call	EngineGetFirstAndLastCellsInWord

	.leave
	ret
BoardMapWordToFirstNLastCells	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordBoardEraseHighlights
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message definition

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass

RETURN:		
		nothing

	
DESTROYED:	
		done

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordBoardEraseHighlights	method dynamic CwordBoardClass, 
						MSG_CWORD_BOARD_ERASE_HIGHLIGHTS
	.enter

	tst	ds:[di].CBI_engine
	jz	exit
	
	call	BoardGetGStateDI
	BoardEraseHiLites
	call	GrDestroyState

exit:
	.leave
	ret
CwordBoardEraseHighlights		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardHiLiteCellCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw or erase the highlight of a square.

CALLED BY:	BoardDrawHiLiteCell, BoardEraseHiLiteCell,
		BoardUpdateHiLiteCell

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Drawing in INVERT mode, so don't care if DRAWING or ERASING at
	the moment, ie. ignore bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardHiLiteCellCommon	proc	near
class	CwordBoardClass

	uses	bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	dl,ds:[bx].CBI_drawOptions

	call	BoardHiLiteCellCommonLow

	.leave
	ret
BoardHiLiteCellCommon	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardHiLiteCellCommonLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw or erase the highlight of a square.

CALLED BY:	BoardDrawHiLiteCellCommon

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		dl	- DrawOptions
		cx	- Direction

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Drawing in INVERT mode, so don't care if DRAWING or ERASING at
	the moment, ie. ignore bp

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardHiLiteCellCommonLow	proc	near
class	CwordBoardClass

gstate		local	hptr.GState	push di
token		local	CellTokenType	push ax
direction	local	word		push cx
firstCell	local	CellTokenType	
lastCell	local	CellTokenType
drawOptions	local	DrawOptions

	uses	ax,bx,cx,dx,si,di
	.enter


;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		gstate
	Assert	CellTokenType	token
	Assert	DrawOptions	dl
	Assert	DirectionType	direction
;;;;;;;;

	mov	drawOptions,dl

	mov	al, MM_INVERT
	call	GrSetMixMode

	; Get the cell's bound
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	ax, token			
	mov	dx, ds:[di].CBI_engine
	mov	bx, ds:[di].CBI_cellWidth
	mov	cx, ds:[di].CBI_cellHeight
	call	BoardGetCellBoundsProc

	test	drawOptions,mask DO_SELECTED_WORD
	jnz	alsoSelectedWord

	; Highlight by drawing in from border
	add	ax, BOARD_CELL_FILL_LEFT_INSET
	add	bx, BOARD_CELL_FILL_TOP_INSET
	sub	cx, BOARD_CELL_FILL_RIGHT_INSET	
	sub	dx, BOARD_CELL_FILL_BOTTOM_INSET

fillRect:
	mov	di, gstate
	call	GrFillRect

	; Restore GState
	mov	al, BOARD_MIX_MODE
	call	GrSetMixMode

	.leave
	ret

alsoSelectedWord:
	;    Defaults for drawing with selected word, so as
	;    not to overlap.
	;

	add	ax, BOARD_CELL_FILL_LEFT_INSET_WITH_SW
	add	bx, BOARD_CELL_FILL_TOP_INSET_WITH_SW
	sub	cx, BOARD_CELL_FILL_RIGHT_INSET_WITH_SW
	sub	dx, BOARD_CELL_FILL_BOTTOM_INSET_WITH_SW

	;    Get first and last token of selected word
	;

	push	ax,bx,cx				;left,top, right
	mov	ax,token
	mov	di,ax					;cell token
	mov	cx,direction
	call	BoardMapWordToFirstNLastCells	
	mov	firstCell,ax
	mov	lastCell,bx

	cmp	cx,ACROSS
	pop	ax,bx,cx				;left,top,right
	jne	downSelectedWord

	;    If not the first cell in word then the left edge can move 
	;    back to left edge of cell.
	; 
	
	cmp	di,firstCell
	je	10$
	sub	ax,BOARD_CELL_FILL_LEFT_INSET_WITH_SW
10$:
	;    If not the last cell in word then right edge can move
	;    back to right edge of cell.

	cmp	di,lastCell
	je	fillRect
	add	cx,BOARD_CELL_FILL_RIGHT_INSET_WITH_SW
	jmp	fillRect

downSelectedWord:
	;    If not the first cell in word then top edge can move
	;    back to top edge of cell.

	cmp	di,firstCell
	je	20$
	sub	bx,BOARD_CELL_FILL_TOP_INSET_WITH_SW
20$:
	;    If not the last cell in word then bottom edge can move 
	;    back to bottom edge of cell.

	cmp	di,lastCell
	je	fillRect
	add	dx,BOARD_CELL_FILL_BOTTOM_INSET_WITH_SW
	jmp	fillRect

BoardHiLiteCellCommonLow	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawHiLiteCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the highlight for a cell if it's not already
		highlighted.  Then will set the corresponding bit in
		CBI_highlightStatus. 

CALLED BY:	

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawHiLiteCell	proc	near
class	CwordBoardClass
	uses	bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_drawOptions, mask DO_SELECTED_SQUARE
	jz	exit			; jmp if not drawing selected square
	test	ds:[bx].CBI_highlightStatus, mask HS_SELECTED_SQUARE
	jnz	exit			; jmp if already drawn

	BitSet	ds:[bx].CBI_highlightStatus, HS_SELECTED_SQUARE
	call	BoardHiLiteCellCommon

exit:
	.leave
	ret
BoardDrawHiLiteCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEraseHiLiteCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will erase the highlight of the cell if it's
		highlighted.  And it will clear the corresponding bit
		in CBI_highlightStatus. 

CALLED BY:

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEraseHiLiteCell	proc	near
class	CwordBoardClass
	uses	bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_highlightStatus, mask HS_SELECTED_SQUARE
	jz	exit			; jmp if already erased

	BitClr	ds:[bx].CBI_highlightStatus, HS_SELECTED_SQUARE
	call	BoardHiLiteCellCommon

exit:
	.leave
	ret
BoardEraseHiLiteCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardUpdateHiLiteCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the highlight of a cell if supposed to.

CALLED BY:	BoardVisDraw

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardUpdateHiLiteCell	proc	near
class	CwordBoardClass
	uses	bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_highlightStatus, mask HS_SELECTED_SQUARE
	jz	done			; jmp if not supposed to draw
EC <	test	ds:[bx].CBI_drawOptions, mask DO_SELECTED_SQUARE>
EC <	ERROR_Z BOARD_INCONSISTENT_HIGHLIGHTING_STATE		>

	call	BoardHiLiteCellCommon

done:
	.leave
	ret
BoardUpdateHiLiteCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawHiLiteSelectedSquare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the highlight of the selected square.

CALLED BY:	Global

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		or	- 0 if need to create GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawHiLiteSelectedSquare	proc	far
	class	CwordBoardClass
	uses	ax,cx,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	tst	ds:[bx].CBI_engine
	jz	done

	push	di				; passed GState handle
	call	BoardGetHiLiteParams
	call	BoardDrawHiLiteCell
	pop	ax				; passed GState handle
	tst	ax
	jnz	noNeedToDestroyGState

	; Since the passed GState was NULL, then we created a new
	; GState that must be destroyed
	call	GrDestroyState

noNeedToDestroyGState:
	mov_tr	di, ax				; passed GState handle

done:
	.leave
	ret
BoardDrawHiLiteSelectedSquare	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEraseHiLiteSelectedSquare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the highlight around the selected square.

CALLED BY:	KBD routines

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		or	- 0 if need to create GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEraseHiLiteSelectedSquare	proc	far
	class	CwordBoardClass
	uses	ax,cx,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	tst	ds:[bx].CBI_engine
	jz	done

	push	di				; passed GState handle
	call	BoardGetHiLiteParams
	call	BoardEraseHiLiteCell
	pop	ax				; passed GState handle
	tst	ax
	jnz	noNeedToDestroyGState

	; Since the passed GState was NULL, then we created a new
	; GState that must be destroyed
	call	GrDestroyState

noNeedToDestroyGState:
	mov_tr	di, ax				; passed GState handle

done:
	.leave
	ret
BoardEraseHiLiteSelectedSquare	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardHiLiteWordCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws or erases the highlight around the current
		"word" as defined by a cell token and a direction.

CALLED BY:	BoardDrawHiLiteWord, BoardEraseHiLiteWord,
		BoardUpdateHiLiteWord

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		cx	- DirectionTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Highlight and erase highlight by drawing a filled rectangle in
	INVERT MixMode.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardHiLiteWordCommon	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,bp,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;


	; Get the bounds of the "word"
	call	BoardMapWordToFirstNLastCells
	call	BoardGetBoundsForFirstNLastCells
	
	Assert	le	ax, cx			; left <= right
	Assert	le	bx, dx			; top <= bottom

	push	ax				;left
	mov	al, MM_INVERT
	call	GrSetMixMode

	pop	ax				; left

	push	dx				;bottom
	mov	dx,bx
	add	dx,BOARD_SELECTED_WORD_THICKNESS
	call	GrFillRect
	pop	dx				;bottom	
	push	bx				;top
	mov	bx,dx
	sub	bx,BOARD_SELECTED_WORD_THICKNESS
	call	GrFillRect
	pop	bx				;top

	add	bx,BOARD_SELECTED_WORD_THICKNESS
	sub	dx,BOARD_SELECTED_WORD_THICKNESS
	push	cx				;right
	mov	cx,ax				
	add	cx,BOARD_SELECTED_WORD_THICKNESS
	call	GrFillRect
	pop	cx				;right
	mov	ax,cx
	sub	ax,BOARD_SELECTED_WORD_THICKNESS
	call	GrFillRect

	; Restore GState
	mov	al, BOARD_MIX_MODE
	call	GrSetMixMode

	.leave
	ret
BoardHiLiteWordCommon	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawHiLiteWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the highlight for the "word" if it's not
		already highlighted.  Then will set the corresponding
		bit in CBI_highlightStatus. 

CALLED BY:	

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		cx	- DirectionType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawHiLiteWord	proc	near
class	CwordBoardClass
	uses	bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_drawOptions, mask DO_SELECTED_WORD
	jz	exit			; jmp if not supposed to draw
	test	ds:[bx].CBI_highlightStatus, mask HS_SELECTED_WORD
	jnz	exit			; jmp if already drawn

	BitSet	ds:[bx].CBI_highlightStatus, HS_SELECTED_WORD
	call	BoardHiLiteWordCommon

exit:
	.leave
	ret
BoardDrawHiLiteWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEraseHiLiteWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will erase the highlight for the "word" if it's not
		already erased.  Then will clear the corresponding
		bit in CBI_highlightStatus. 

CALLED BY:	

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		cx	- DirectionType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEraseHiLiteWord	proc	near
class	CwordBoardClass
	uses	bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_highlightStatus, mask HS_SELECTED_WORD
	jz	exit			; jmp if already erased

	BitClr	ds:[bx].CBI_highlightStatus, HS_SELECTED_WORD
	call	BoardHiLiteWordCommon

exit:

	.leave
	ret
BoardEraseHiLiteWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardUpdateHiLiteWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the highlight for the "word" if supposed to.

CALLED BY:	BoardVisDraw

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		cx	- DirectionType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardUpdateHiLiteWord	proc	near
class	CwordBoardClass
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_highlightStatus, mask HS_SELECTED_WORD
	jz	exit			; jmp if not supposed to draw
EC <	test	ds:[bx].CBI_drawOptions, mask DO_SELECTED_WORD	>
EC <	ERROR_Z BOARD_INCONSISTENT_HIGHLIGHTING_STATE		>

	call	BoardHiLiteWordCommon

exit:

	.leave
	ret
BoardUpdateHiLiteWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawHiLiteSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the highlight of the selected word.

CALLED BY:	KBD routines

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		or	- 0 if need to create GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawHiLiteSelectedWord	proc	far
	class	CwordBoardClass
	uses	ax,cx,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	tst	ds:[bx].CBI_engine
	jz	done

	push	di				; passed GState handle
	call	BoardGetHiLiteParams
	call	BoardDrawHiLiteWord
	pop	ax				; passed GState handle
	tst	ax
	jnz	noNeedToDestroyGState

	; Since the passed GState was NULL, then we created a new
	; GState that must be destroyed
	call	GrDestroyState

noNeedToDestroyGState:
	mov_tr	di, ax				; passed GState handle

done:
	.leave
	ret
BoardDrawHiLiteSelectedWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEraseHiLiteSelectedWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the highlight around the selected word.

CALLED BY:	KBD routines

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		or	- 0 if need to create GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEraseHiLiteSelectedWord	proc	far
	class	CwordBoardClass
	uses	ax,cx,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	tst	ds:[bx].CBI_engine
	jz	done

	push	di				; passed GState handle
	call	BoardGetHiLiteParams
	call	BoardEraseHiLiteWord
	pop	ax				; passed GState handle
	tst	ax
	jnz	noNeedToDestroyGState

	; Since the passed GState was NULL, then we created a new
	; GState that must be destroyed
	call	GrDestroyState

noNeedToDestroyGState:
	mov_tr	di, ax				; passed GState handle
done:
	.leave
	ret
BoardEraseHiLiteSelectedWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetHiLiteParams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the necessary parameters for calling any
		HiLiting routines.

CALLED BY:	Board[Draw/Erase]HiLiteSelected[Square/Word]

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		or	- 0 if need to create GState

RETURN:		^hdi	- old or new GState
		ax	- CellTokenType (selected cell)
		cx	- DirectionType (current direction)

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/27/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetHiLiteParams	proc	near
class	CwordBoardClass
	uses	bx,dx,bp
	.enter

;;; Verify arugment(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	tst	di
	jnz	gotGState

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp
gotGState:

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ax, ds:[bx].CBI_cell
	mov	cx, ds:[bx].CBI_direction

;;; Verify return value(s)
	Assert	gstate		di
	Assert	CellTokenType	ax
	Assert	DirectionType	cx
;;;;;;;;

	.leave
	ret
BoardGetHiLiteParams	endp

if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveHiLiteCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the highlight between two given cells.

CALLED BY:	BoardMoveSelectedSquareCommon

PASS:		*ds:si	- CwordBoardClass object
		ax	- src CellTokenType
		bx	- dst CellTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveHiLiteCell	proc	near
	uses	ax, cx, di
	.enter

;;; Verify argument(s)
	Assert	BoardObject	dssi
	Assert	CellTokenType	ax
	Assert	CellTokenType	bx
;;;;;;;;

	push	ax				; src cell
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				; ^GState

	; Unhighlight the src cell.
	pop	ax				; src cell
	call	BoardEraseHiLiteCell

	; Highlight the dst cell
	mov	ax, bx				; dst cell
	call	BoardDrawHiLiteCell

	call	GrDestroyState

	.leave
	ret
BoardMoveHiLiteCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMoveHiLiteWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the highlight between two "word".  The "word" is
		defined by a cell in the word and the orientation of
		the word. 

CALLED BY:	NADA

PASS:		*ds:si	- CwordBoardClass object
		ax	- src CellTokenType
		bx	- dst CellTokenType
		cx	- src DirectionType
		dx	- dst DirectionType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMoveHiLiteWord	proc	near
	uses	ax,cx,si,di,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	CellTokenType	bx
	Assert	DirectionType	cx
	Assert	DirectionType	dx
;;;;;;;;

	push	ax, cx, dx			; src CT, src DT, sdst DT
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				; ^GState
	pop	ax, cx, dx			; src CT, src DT, sdst DT

	call	BoardEraseHiLiteWord

	mov	ax, bx				; dst cellToken
	mov	cx, dx				; dst direction

	call	BoardDrawHiLiteWord

	call	GrDestroyState

	.leave
	ret
BoardMoveHiLiteWord	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVisDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles drawing/redrawing of the grid.

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cl	= DrawFlags: DF_EXPOSED set if GState is et to
			  update window
		^hbp	= GState to draw through

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/31/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVisDraw	method dynamic CwordBoardClass, 
					MSG_VIS_DRAW

gstateHandle	local	hptr.GState	push	bp
clipBounds	local	Rectangle
uLCell		local	CellTokenType
lRCell		local	CellTokenType
selectedSquare	local	CellTokenType

	ForceRef	gstateHandle
	ForceRef	clipBounds
	ForceRef	uLCell
	ForceRef	lRCell
	ForceRef	selectedSquare

	uses	ax,cx,dx
	.enter

	; See if we should do any drawing at all.
	tst	ds:[di].CBI_engine
	LONG jz	exit			; no engine token

;;; Verify argument(s)
	Assert	gstate	ss:[gstateHandle]
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	BoardVisDrawHack
	jc	exit

	mov	ax, ds:[di].CBI_cell
	mov	ss:[selectedSquare], ax

	; Setup the GState
	mov	di, ss:[gstateHandle]
	call	BoardVisDrawPrepGState

	call	BoardVisDrawGetMaskBounds
	jc	exit


	call	BoardDrawGridBorders		; optimize drawing
	call	BoardDrawGridLines

	call	BoardVisDrawGetCellBoundaries

	; Get engine token
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine

	mov	di, ss:[gstateHandle]
	mov	ax, ss:[uLCell]			; current cell in row

	; Draw each cell in the row
drawRow:
	clr	bx				; don't draw borders
	call	BoardDrawCell
	cmp	ax, cx				; curr cell, uRCell
	je	doneRow				; reached end of row
	call	EngineGetNextCellTokenInRow	; get cell to the right
	mov	ax, bx
	jmp	drawRow

doneRow:
	cmp	ax, ss:[lRCell]
	je	doneDrawing

	; update right (ending) cell
	mov	ax, cx				; uRCell
	call	EngineGetNextCellTokenInColumn
	mov	cx, bx				; new uRCell

	; update left (starting) cell
	mov	ax, ss:[uLCell]
	call	EngineGetNextCellTokenInColumn
	mov	ss:[uLCell], bx
	
	mov	ax, bx				; new starting cell
	jmp	drawRow
	
doneDrawing:
	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx, ds:[bx].CBI_direction
	mov	ax, ds:[bx].CBI_cell
	mov	di, ss:[gstateHandle]
	call	BoardUpdateHiLiteCell
	call	BoardUpdateHiLiteWord

	; Draw the mode char if we're in pen mode
	cmp	ds:[bx].CBI_system, ST_PEN
	jne	finishedDrawing
	call	BoardDrawModeCharCell
finishedDrawing:

	call	GrRestoreState
exit:
	.leave
EC <	Destroy	ax, cx, dx, bp					>
	ret
BoardVisDraw	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVisDrawPrepGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Save gstate and set drawing attributes

CALLED BY:	BoardVisDraw

PASS:		di  - gstate

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
	srs	10/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVisDrawPrepGState		proc	near
	uses	ax
	.enter

	call	GrSaveState

	mov	al, BOARD_MIX_MODE
	call	GrSetMixMode

	mov	al, BOARD_AREA_MASK
	call	GrSetAreaMask

	mov	ax, CF_INDEX shl 8 or BOARD_DEFAULT_AREA_COLOR
	call	GrSetAreaColor

	.leave
	ret
BoardVisDrawPrepGState		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVisDrawGetMaskBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get mask bounds into stack frame

CALLED BY:	BoardVisDraw

PASS:		
		di - state
		bp - inherited stack frame

RETURN:		
		clc - no trouble
		stc - bad mask bounds

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVisDrawGetMaskBounds		proc	near
	.enter inherit BoardVisDraw

	; Get the masking bounds
	call	GrGetMaskBounds
	jc	done

	mov	ss:[clipBounds].R_left, ax
	mov	ss:[clipBounds].R_top, bx
	mov	ss:[clipBounds].R_right, cx
	mov	ss:[clipBounds].R_bottom, dx
	clc

done:
	.leave
	ret
BoardVisDrawGetMaskBounds		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVisDrawGetCellBoundaries
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get tokens of cells at corners of mask bounds

CALLED BY:	BoardVisDraw

PASS:		*ds:si - Board
		

RETURN:		
		cx - CellToken for cell in upper right of mask
		uLCell
		lRCell

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	10/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVisDrawGetCellBoundaries		proc	near
	uses	ax,bx,dx
	.enter	inherit BoardVisDraw

	call	BoardMapPointToCellToken
	mov	ss:[uLCell], cx			; upper-left of mask
	mov	ax, ss:[clipBounds].R_right
	call	BoardMapPointToCellToken
	push	cx				; upper-right of mask
	mov	bx, dx				; bottom
	call	BoardMapPointToCellToken
	mov	ss:[lRCell], cx			; lower-right of mask
	pop	cx				; upper-right of mask

	.leave
	ret
BoardVisDrawGetCellBoundaries		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVisDrawHack
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if cell size is out of whack with current
		drawing window. If the window is bigger than the
		vis bounds then we have a problem

CALLED BY:	BoardVisDraw

PASS:		*ds:si - CwordBoardClass object
		bp - inherited stack frame

RETURN:		
		clc - no troubles
		stc - don't draw

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVisDrawHack		proc	near
	class	CwordBoardClass
	uses	ax,bx,cx,dx,di
	.enter inherit BoardVisDraw

	mov	di, ss:[gstateHandle]
	call	GrGetWinBounds
	sub	dx,bx
	sub	cx,ax

	GetInstanceDataPtrDSDI	Vis_offset
	mov	ax,ds:[di].VI_bounds.R_right	
	sub	ax,ds:[di].VI_bounds.R_left
	mov	bx,ds:[di].VI_bounds.R_bottom
	sub	bx,ds:[di].VI_bounds.R_top
	cmp	dx,bx
	ja	nodraw
	cmp	cx,ax
	ja	nodraw
	clc
done:
	.leave
	ret

nodraw:
	;    Make sure we draw later
	;

	mov	bx,ds:[LMBH_handle]
	mov	di,mask MF_FIXUP_DS or mask MF_FORCE_QUEUE
	mov	ax,MSG_VIS_INVALIDATE
	call	ObjMessage
	stc
	jmp	done

BoardVisDrawHack		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawGridLines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw horizontal and vertical grid lines all at once

CALLED BY:	BoardVisDraw

PASS:		*ds:si - CwordBoardClass
		bp - inherited stack frame

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
	srs	10/ 6/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawGridLines		proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,di,si
	.enter	inherit	BoardVisDraw

;;; Verify argument(s)
	Assert	gstate	ss:[gstateHandle]
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	di,gstateHandle
	clr	ax, dx				; don't want scaling
	call	GrSetLineWidth

	mov	ax, CF_INDEX shl 8 or C_BLACK
	call	GrSetLineColor

	push	bp				 ; locals
	mov	si, ds:[si]
	add	si, ds:[si].CwordBoard_offset

	mov	bp,ds:[si].VI_bounds.R_bottom
	sub	bp, BOARD_BORDER_WIDTH
	mov	cx,ds:[si].VI_bounds.R_right
	sub	cx,ds:[si].VI_bounds.R_left	; width
	sub	cx,(BOARD_BORDER_WIDTH*2)
	mov	ax,BOARD_BORDER_WIDTH		; left
	add	cx,ax				; right = width + left
	mov	bx, ds:[si].CBI_cellHeight
	add	bx,BOARD_BORDER_WIDTH-1
	mov	dx,bx				; bottom=top

nextHorizLine:
	call	GrDrawLine
	add	bx,ds:[si].CBI_cellHeight
	mov	dx,bx
	cmp	bx,bp
	jl	nextHorizLine

	mov	bp,ds:[si].VI_bounds.R_right
	sub	bp,BOARD_BORDER_WIDTH
	mov	dx,ds:[si].VI_bounds.R_bottom
	sub	dx,ds:[si].VI_bounds.R_top		;height
	sub	dx,(BOARD_BORDER_WIDTH*2)
	mov	bx, BOARD_BORDER_WIDTH
	add	dx,bx				; bottom = height + top
	mov	ax, ds:[si].CBI_cellWidth
	add	ax,BOARD_BORDER_WIDTH-1
	mov	cx,ax				; bottom=top

nextVerticalLine:
	call	GrDrawLine
	add	ax,ds:[si].CBI_cellWidth
	mov	cx,ax
	cmp	ax,bp
	jl	nextVerticalLine

	pop	bp				; locals

	.leave
	ret
BoardDrawGridLines		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawGridBorders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will only want to draw the border that falls within
		the given mask bounds.

CALLED BY:	BoardVisDraw

PASS:		*ds:si	- CwordBoardClass object
		bp	- inherited stack frame

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/31/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawGridBorders	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,di,si
	.enter	inherit	BoardVisDraw

;;; Verify argument(s)
	Assert	gstate	ss:[gstateHandle]
;;;;;;;;

	; Setup drawing attributes
	mov	di, ss:[gstateHandle]		; for graphic routines

ifdef _DEBUG
	mov	al, MM_INVERT			; So can detect overlaps
	call	GrSetMixMode
endif

	; Get instance pointer to instance data
	mov	si, ds:[si]
	add	si, ds:[si].CwordBoard_offset
	test	ds:[si].CBI_drawOptions, mask DO_COLOR
	jz	10$
	mov	ax, CF_INDEX shl 8 or BOARD_BORDER_COLOR
	call	GrSetAreaColor

10$:
	; Now draw only the portion of the border that is exposed.


	; Check each side to see if it's within the masking region.

	mov	ax, ds:[si].CBI_upLeftCoord.P_x
	mov	cx, ax
	add	cx, BOARD_BORDER_WIDTH		; gridLeft
	cmp	cx, ss:[clipBounds].R_left
	jl	leftNotExposed
	mov	bx, ss:[clipBounds].R_top
	mov	dx, ss:[clipBounds].R_bottom
	call	GrFillRect
leftNotExposed:

	mov	cx, ds:[si].CBI_lowRightCoord.P_x
	mov	ax, cx
	sub	ax, BOARD_BORDER_WIDTH		; gridRight-1
	cmp	ax, ss:[clipBounds].R_right
	jg	rightNotExposed
	call	GrFillRect
rightNotExposed:

	mov	bx, ds:[si].CBI_upLeftCoord.P_y
	mov	dx, bx
	add	dx, BOARD_BORDER_WIDTH		; gridTop
	cmp	dx, ss:[clipBounds].R_top
	jl	topNotExposed
	mov	ax, ss:[clipBounds].R_left
	mov	cx, ss:[clipBounds].R_right
	call	GrFillRect
topNotExposed:

	mov	dx, ds:[si].CBI_lowRightCoord.P_y
	mov	bx, dx
	sub	bx, BOARD_BORDER_WIDTH		; gridBottom-1
	cmp	bx, ss:[clipBounds].R_bottom
	jg	bottomNotExposed
	mov	ax, ss:[clipBounds].R_left
	mov	cx, ss:[clipBounds].R_right
	call	GrFillRect
bottomNotExposed:

ifdef _DEBUG
	mov	al, BOARD_MIX_MODE
	call	GrSetMixMode
endif
	mov	ax, CF_INDEX shl 8 or BOARD_DEFAULT_AREA_COLOR
	call	GrSetAreaColor

	.leave
	ret
BoardDrawGridBorders	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the cell given its cell token

CALLED BY:	BoardVisDraw, BoardRedrawCell

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		dx	- EngineTokenTyp
		bx	- TRUE to draw borders

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 8/94    	Initial version
	JL	7/26/94		Removed verification drawing. Changed
				to draw a slash if CF_WRONG is set.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCell	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,si,di,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
	Assert	gstate		di
;;;;;;;;

	call	EngineGetCellFlags		; cl - cellflags
	test	cl, mask CF_NON_EXISTENT
	jnz	exit

	BoardAllocStructOnStack		Rectangle

	call	BoardDrawCellInitVisualBounds

	test	cl, mask CF_HOLE
	jnz	drawHole

	test	cl, mask CF_WRONG
	jnz	drawSlashed

checkNumber:
	test	cl, mask CF_NUMBER
	jnz	drawNumber

drawText:
	test	cl, mask CF_EMPTY
	jz	drawLetter			; draw letters if not empty

drawBorder:
	tst	bx				;draw borders
	jz	deAlloc
	call	BoardDrawCellBorders
deAlloc:
	BoardDeAllocStructOnStack	Rectangle
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawSlashed:
	call	BoardDrawCellSlashed
	jmp	checkNumber

drawNumber:
	call	BoardDrawCellNumber
	jmp	drawText

drawHole:
	call	BoardDrawHole
	jmp	drawBorder

drawLetter:
	push	bx				;draw borders?
	call	EngineGetUserLetter		; bl - letter
	clr	bh
	call	BoardDrawCellLetter
	pop	bx				;draw borders?
	jmp	drawBorder

BoardDrawCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellInitVisualBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	INTERNAL! Routine to initialize the rectangle with the
		cell's bounds.

CALLED BY:	BoardDrawCell

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType
		dx	- EngineTokenType

		ss:[bp]	- Rectangle

RETURN:		rectangle initialized
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellInitVisualBounds	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx, ds:[bx].CBI_cellHeight
	mov	bx, ds:[bx].CBI_cellWidth
	call	BoardGetCellBoundsProc		; ax - left, bx - top
						; cx - right, dx - bottom

	mov	ss:[bp].R_left, ax
	mov	ss:[bp].R_top, bx
	mov	ss:[bp].R_right, cx
	mov	ss:[bp].R_bottom, dx

	.leave
	ret
BoardDrawCellInitVisualBounds	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardRedrawCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will redraw the cell, by first erasing it, then call
		BoardDrawCell. 

CALLED BY:	BoardSetLetterInCell, BoardClearCell, BoardHintCell

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType
		dx	- EngineTokenType
		^hdi	- GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardRedrawCell	proc	near
	uses	bx,cx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
	Assert	gstate		di
;;;;;;;;

	call	EngineGetCellFlags		; cl - cellflags
	test	cl, mask CF_NON_EXISTENT
	jnz	exit

	call	BoardEraseSquare
	mov	bx,TRUE				;draw borders
	call	BoardDrawCell

exit:
	.leave
	ret
BoardRedrawCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardRedrawCellFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far version of BoardRedrawCell

CALLED BY:	BoardGestureReplaceLastChar

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellTokenType
		dx	- EngineTokenType
		^hdi	- GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardRedrawCellFar	proc	far
	.enter

	call	BoardRedrawCell

	.leave
	ret
BoardRedrawCellFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawModeCharCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the current Mode Char in the cell that it
		belongs in.

CALLED BY:	BoardVisDraw

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		cx	- 0 if don't want to erase before drawing

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/10/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawModeCharCell	proc	near
class	CwordBoardClass
	uses	ax,bx,cx,dx,di,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset

	tst	ds:[bx].CBI_currModeChar
	jz	exit			; jmp if no modeChar
	mov	ax, ds:[bx].CBI_lastCell
	cmp	ax, INVALID_CELL_TOKEN
	je	exit

	mov	dx, ds:[bx].CBI_engine

	mov	bx, cx				; erase flag

	call	EngineGetCellFlags		; cl - cellflags
	test	cl, BOARD_NOT_SELECTABLE_CELL
	jnz	err

	BoardAllocStructOnStack		Rectangle

	call	BoardDrawCellInitVisualBounds

	tst	bx
	jz	dontErase
	call	BoardEraseSquare
dontErase:

	test	cl, mask CF_NUMBER
	jnz	drawNumber

drawModeChar:
	; Draw mode char
	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	bx, ds:[bx].CBI_currModeChar	; character to draw
	call	BoardDrawCellLetter

	call	BoardDrawCellBorders

	BoardDeAllocStructOnStack	Rectangle
exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
drawNumber:
	call	BoardDrawCellNumber
	jmp	drawModeChar

err:
; This branch should never happen.  If it does, we don't want to
; crash or display a weird behavior.  So we'll just signal to the
; programmer and handle the situation the best we could.
	clr	ds:[bx].CBI_currModeChar
	mov	ds:[bx].CBI_lastCell, INVALID_CELL_TOKEN
	SoundUser	SST_NOTIFY
	jmp	exit

BoardDrawModeCharCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawModeCharCellFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far version of BoardDrawModeCharCell.

CALLED BY:	BoardGestureSetModeChar

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		cx	- 0 if don't want to erase before drawing

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawModeCharCellFar	proc	far
	.enter

	call	BoardDrawModeCharCell

	.leave
	ret
BoardDrawModeCharCellFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEraseSquare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the given square

CALLED BY:	BoardRedrawCell

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		dx	- EngineTokenType

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEraseSquare	proc	near
class	CwordBoardClass
	uses	ax,bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
;;;;;;;;

	push	di				; ^hGState

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	bx, ds:[di].CBI_cellWidth
	mov	cx, ds:[di].CBI_cellHeight
	call	BoardGetCellBoundsProc		; ax - left, bx - top
						; cx - right, dx - bottom

	; Set drawing attributes
	pop	di				; ^hGState
	push	ax				; left
	mov	ax, CF_INDEX shl 8 or C_WHITE
	call	GrSetAreaColor
	pop	ax				; left

	; Don't erase highlights or border
	add	ax, BOARD_CELL_FILL_LEFT_INSET
	add	bx, BOARD_CELL_FILL_TOP_INSET
	sub	cx, BOARD_CELL_FILL_RIGHT_INSET	; new right
	sub	dx, BOARD_CELL_FILL_BOTTOM_INSET; new bottom

	call	GrFillRect

	mov	ax, CF_INDEX shl 8 or BOARD_DEFAULT_AREA_COLOR
	call	GrSetAreaColor

	.leave
	ret
BoardEraseSquare	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the cell number.

CALLED BY:	BoardDrawCell
PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		ax	- CellTokenType
		dx	- EngineTokenType
		ss:[bp]	- Rectangle (cell bounds)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Get the number from the engine.  Then convert it to character
	string.  Then display it. 

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellNumber	proc	near
class	CwordBoardClass
	uses	bx,cx
	.enter	inherit	BoardDrawCell

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_drawOptions, mask DO_NUMBER
	jz	exit

	test	ds:[bx].CBI_hideNumber, mask SHOW_TRIANGLE
	jnz	drawTriangle
		
	; Get the number from the engine.
	call	EngineGetCellNumber
	clr	ch
	cmp	cl, ENGINE_NO_NUMBER
	je	exit

	cmp	ds:[bx].CBI_cellWidth,BOARD_MIN_CELL_SIZE_FOR_FONT_NUMBER
	jb	considerRegion
	call	BoardDrawCellNumberFont
	jmp	exit

drawTriangle:
	call	BoardDrawTriangleAtCorner
exit:
	.leave
	ret

considerRegion:
	cmp	ds:[bx].CBI_cellWidth,BOARD_MIN_CELL_SIZE_FOR_REGION_NUMBER
	jb	drawRegionIfNoLetter
drawAsRegion:
	call	BoardDrawCellNumberRegion
	jmp	exit

drawRegionIfNoLetter:
	push	cx				;cell number
	call	EngineGetCellFlags
	test	cl, mask CF_EMPTY
	pop	cx				;cell number
	jnz	drawAsRegion
	jmp	exit


BoardDrawCellNumber	endp


;
;  Draw a triangle at the corner
;
BoardDrawTriangleAtCorner proc	near
	uses ax, bx, cx, dx
	.enter
	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	mov	cx, ax
	add	cx, 2
	mov	dx, bx
	add	dx, 6
	call	GrFillRect

	add	ax, 2
	add	cx, 2
	sub	dx, 2
	call	GrFillRect

	add	ax, 2
	add	cx, 2
	sub	dx, 2
	call	GrFillRect

	.leave
	ret
BoardDrawTriangleAtCorner	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellNumberFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the cell number using the font system

CALLED BY:	BoardDrawCellNumber

PASS:		cx - cell number
		di - GState handle
		ss:bp - Rectangle of cell bounds
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
	srs	8/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellNumberFont		proc	near
	uses	ax,bx,cx,dx,di,si,es,ds
	.enter

	push	cx				; number

	; Setup the GState for drawing
        mov     cx, BOARD_NUM_FONT
        clr     ax
        mov     dx, BOARD_NUM_SIZE
        call    GrSetFont

	; Convert the number into a character string so that we call
	; GrDrawText to display it.
	pop	ax				; number
	clr	dx				; not dword
	mov	si, di				; save ^GState
	mov	cx, mask UHTAF_NULL_TERMINATE

	; Allocate a buffer on the stack for storing text string
	sub	sp, UHTA_NULL_TERM_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss				; es:di = ptr to buffers

	call	UtilHex32ToAscii		; cx = len of str

	xchg	di, si				; ^hGState, buffer ptr
	segmov	ds, es				; ds:si - buffer ptr

	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	add	ax, BOARD_NUM_H_OFFSET
	add	bx, BOARD_NUM_V_OFFSET
	call	GrDrawText

	add	sp, UHTA_NULL_TERM_BUFFER_SIZE	; deallocate buffer

	.leave
	ret
BoardDrawCellNumberFont		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellNumberRegion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the cell number as a region

CALLED BY:	BoardDrawCellNumber

PASS:		cx - cell number
		di - GState handle
		ss:bp - Rectangle of cell bounds

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
	srs	8/16/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellNumberRegion		proc	near
	uses	ax,bx,cx,dx,di,si,es
	.enter

	; Convert the number into a character string so that we call
	; GrDrawText to display it.
	mov	ax,cx				; number
	clr	dx				; not dword
	mov	si, di				; save ^GState
	mov	cx, mask UHTAF_NULL_TERMINATE

	; Allocate a buffer on the stack for storing text string
	sub	sp, UHTA_NULL_TERM_BUFFER_SIZE
	mov	di, sp
	segmov	es, ss				; es:di = ptr to buffers

	call	UtilHex32ToAscii		; cx = len of str

	xchg	di, si				; ^hGState, buffer ptr

	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	call	BoardDrawCellNumberRegionLow

	add	sp, UHTA_NULL_TERM_BUFFER_SIZE	; deallocate buffer

	.leave
	ret
BoardDrawCellNumberRegion		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellNumberRegionLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the cell number using regions

CALLED BY:	BoardDrawCellNumberRegion

PASS:		
		^hdi - GState
		ax - x coord of cell left
		bx - y coord of cell top
		es:si - ptr to ascii numbers to draw

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
	srs	8/15/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellNumberRegionLow		proc	near

	uses	ax,bx,cx,si,ds,bp
	.enter

	segmov	ds,cs				;segment of region table
	mov	bp,si				;offset of ascii numbers


	add	ax, BOARD_NUM_H_OFFSET_SCREEN
	add	bx, BOARD_NUM_V_OFFSET_SCREEN
	
nextLetter:
	tst	{byte}es:[bp]				;null terminator ?
	jz	done

	mov	cl,es:[bp]				;get next number
	sub	cl,C_ZERO				;convert to offset into
	shl	cl					;word sized table
	clr	ch
	mov	si,offset regionOffsets
	add	si,cx
	mov	si,ds:[si]
	call	GrDrawRegion

	add	ax,NUMBER_REGION_SEPARATION
	inc	bp
	jmp	nextLetter


done:
	.leave
	ret
BoardDrawCellNumberRegionLow		endp


regionOffsets	word\
	offset	ZeroRegion,
	offset	OneRegion,
	offset	TwoRegion,
	offset	ThreeRegion,
	offset	FourRegion,
	offset	FiveRegion,
	offset	SixRegion,
	offset	SevenRegion,
	offset	EightRegion,
	offset	NineRegion



ZeroRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,0,2,EOREGREC,
	3,0,0,2,2,EOREGREC,
	4,0,2,EOREGREC,
	EOREGREC

OneRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,1,1,EOREGREC,
	1,0,1,EOREGREC,
	3,1,1,EOREGREC,
	4,0,2,EOREGREC,
	EOREGREC


TwoRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,0,2,EOREGREC,
	1,2,2,EOREGREC,
	2,0,2,EOREGREC,
	3,0,0,EOREGREC,
	4,0,2,EOREGREC,
	EOREGREC


ThreeRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,0,2,EOREGREC,
	1,2,2,EOREGREC,
	2,0,2,EOREGREC,
	3,2,2,EOREGREC,
	4,0,2,EOREGREC,
	EOREGREC

FourRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	1,0,0,2,2,EOREGREC,
	2,0,2,EOREGREC,
	4,2,2,EOREGREC,
	EOREGREC

FiveRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,0,2,EOREGREC,
	1,0,0,EOREGREC,
	2,0,2,EOREGREC,
	3,2,2,EOREGREC,
	4,0,2,EOREGREC,
	EOREGREC

SixRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	1,0,0,EOREGREC,
	2,0,2,EOREGREC,
	3,0,0,2,2,EOREGREC,
	4,0,2,EOREGREC,
	EOREGREC

SevenRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,0,2,EOREGREC,
	2,2,2,EOREGREC,
	4,1,1,EOREGREC,
	EOREGREC

EightRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,0,2,EOREGREC,
	1,0,0,2,2,EOREGREC,
	2,0,2,EOREGREC,
	3,0,0,2,2,EOREGREC,
	4,0,2,EOREGREC,
	EOREGREC

NineRegion	word \
	0,0,3,5,
	-1, EOREGREC,
	0,0,2,EOREGREC,
	1,0,0,2,2,EOREGREC,
	2,0,2,EOREGREC,
	4,2,2,EOREGREC,
	EOREGREC






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawHole
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will draw the hole at this given
		of the cell, will draw the letter.

CALLED BY:	BoardDrawCell

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		bp	- inherited stack frame

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/25/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawHole	proc	near
	class	CwordBoardClass
	uses	ax,bx,cx,dx
	.enter	inherit	BoardDrawCell

;;; Verify argument(s)
	Assert	gstate	di
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	test	ds:[bx].CBI_drawOptions, mask DO_COLOR
	jnz	colorScreen

	; Set the fill color to be black

	mov	al, SDM_50
	call	GrSetAreaMask

getCoords:
	; Get coordinates
	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom
	call	GrFillRect

	mov	al, BOARD_AREA_MASK
	call	GrSetAreaMask
	
	mov	ax, CF_INDEX shl 8 or BOARD_DEFAULT_AREA_COLOR
	call	GrSetAreaColor

	.leave
	ret

colorScreen:
	mov	ax, CF_INDEX shl 8 or BOARD_HOLE_COLOR
	call	GrSetAreaColor
	jmp	getCoords

BoardDrawHole	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the letter, and the upper-left coordinate (DCS)
		of the cell, will draw the letter.

CALLED BY:	BoardDrawCell

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		bx	- Character to draw
		cl	- CellFlags
		ss:[bp]	- Rectangle (cellBounds)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	This version does not support DBCS.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellLetter	proc	near
class	CwordBoardClass
	uses	ax,bx,dx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellFlags	cx
;;;;;;;;

	mov_tr	ax, bx				; character

	; Setup character attributes
	call	BoardDrawCellLetterSetGState

	call	GrCharWidth			; dx - character width
	clr	ah				; not using remainder
	GetInstanceDataPtrDSBX	CwordBoard_offset
	sub	dx, ds:[bx].CBI_cellWidth	; horizontal margin
	inc	dx				; don't include cell
						; border on right
	neg	dx				; get positive value

	Assert	ge	dx, 0			; have centering margin

	shr	dx, 1				; left margin
	mov	bx, ss:[bp].R_left
	add	bx, dx				; centered x
	xchg	ax, bx				; centered x, character
	mov	dx, bx				; character
	mov	bx, ss:[bp].R_bottom

	add	ax, BOARD_TEXT_H_OFFSET
	add	bx, BOARD_TEXT_V_OFFSET
	call	GrDrawChar

	test	cl,mask CF_HINTED
	jnz	hintedLetter

resetGState:
	call	BoardDrawCellLetterResetGState

	.leave
	ret

hintedLetter:
	;    Draw in Faux bold by drawing letter twice one
	;    pixel apart
	;
	inc	ax
	call	GrDrawChar
	jmp	resetGState



BoardDrawCellLetter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellLetterSetGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	PRIVATE - Sets the GState for drawing the cell letters.

CALLED BY:	BoardDrawCellLetter

PASS:		*ds:si	- CwordBoardClass object
		^hdi	- GState
		cl	- CellFlags
		ch 	- DrawOptions

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
	Modified GState.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellLetterSetGState	proc	near
	class	CwordBoardClass
	uses	ax,bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
	Assert	CellFlags	cx
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ch, ds:[bx].CBI_drawOptions

	test	cl,mask CF_HINTED
	jnz	hinted

	mov	ah, BOARD_HINTED_TEXT_STYLE	; reset this style
	mov	al, BOARD_TEXT_STYLE
	call	GrSetTextStyle

setOther:
	mov	dx,ds:[bx].CBI_pointSize.WBF_int
	mov	ah,ds:[bx].CBI_pointSize.WBF_frac
        mov     cx, BOARD_TEXT_FONT
        call    GrSetFont

	clr	ah				; reset
	mov	al, mask TM_DRAW_BASE		; set
	call	GrSetTextMode

	.leave
	ret

hinted:
	test	ch,mask DO_COLOR
	jz	hintedTextStyle
	mov	ax, BOARD_HINTED_TEXT_COLOR or (CF_INDEX shl 8)
	call	GrSetTextColor
hintedTextStyle:
	mov	al,BOARD_HINTED_TEXT_STYLE
	mov	ah,BOARD_TEXT_STYLE			;reset this style
	call	GrSetTextStyle
	jmp	setOther




BoardDrawCellLetterSetGState	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellLetterResetGState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the gstate values to their default state

CALLED BY:	BoardDrawCellLetter

PASS:		^hdi	- GState
		cl	- CellFlags

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:
	Modified GState.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellLetterResetGState	proc	near
	uses	ax,bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	gstate		di
	Assert	CellFlags	cx
;;;;;;;;

	test	cl,mask CF_HINTED or mask CF_WRONG
	jnz	resetColor

setOther:
	clr	al				; set
	mov	ah, mask TM_DRAW_BASE		; reset
	call	GrSetTextMode

	.leave
	ret

resetColor:
	mov	ax, BOARD_TEXT_COLOR or (CF_INDEX shl 8)
	call	GrSetTextColor
	jmp	setOther

BoardDrawCellLetterResetGState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellSlashed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws an downward diagonal slash through the square.

CALLED BY:	BoardDrawCell

PASS:		^hdi	- GState
		ss:[bp]	- Rectangle (cellBounds)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 2/94    	Initial version
	JL	7/26/94		added INSET's to the slash drawn

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellSlashed	proc	near
	uses	ax,bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	gstate	di
;;;;;;;;

	mov	dx, 2
	mov	ax, 0
	call	GrSetLineWidth

	mov	ax, BOARD_SLASH_COLOR or (CF_INDEX shl 8)
	call	GrSetLineColor

	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom

	; Don't overlap highlights or border and go in one
	; more to make sure the pixels on the thick lines
	; will get erased.	
	;
	add	ax, BOARD_CELL_FILL_LEFT_INSET+2
	add	bx, BOARD_CELL_FILL_TOP_INSET+2
	sub	cx, BOARD_CELL_FILL_RIGHT_INSET+2
	sub	dx, BOARD_CELL_FILL_BOTTOM_INSET+2

;;; Verify argument(s)
	Assert	InBoard	axbx
	Assert	InBoard	cxdx
;;;;;;;;
	

	; Draw line upper left to lower right

	call	GrDrawLine


	; Draw line upper right to lower left

	xchg	ax,cx				;x values
	call	GrDrawLine


	mov	dx, 1
	mov	ax, 0
	call	GrSetLineWidth

	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetLineColor

	.leave
	ret
BoardDrawCellSlashed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDrawCellBorders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the border of the cell, given its bound.  Since
		we're drawing a grid, will only need to draw the
		bottom and right side of the square.

CALLED BY:	BoardDrawCell

PASS:		^hdi	- GStates
		ss:[bp]	- Rectangle

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/18/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDrawCellBorders	proc	near
	uses	ax,bx,cx,dx
	.enter

;;; Verify argument(s)
	Assert	gstate	di
;;;;;;;;

	; Setup drawing attributes
ifdef _DEBUG
	mov	al, MM_INVERT			; So can detect overlaps
	call	GrSetMixMode
endif

	clr	ax, dx				; don't want scaling
	call	GrSetLineWidth

	mov	ax, CF_INDEX shl 8 or C_BLACK
	call	GrSetLineColor

	; Draw right border and bottom border
	mov	ax, ss:[bp].R_right
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom
	inc	dx				; fill in corner
	Assert	InGrid	axbx
	Assert	InGrid	cxdx
	call	GrDrawLine			; right border
	dec	dx
	mov	ax, ss:[bp].R_left
	mov	bx, dx				; bottom
	Assert	InGrid	axbx
	call	GrDrawLine			; bottom border

ifdef _DEBUG
	mov	al, BOARD_MIX_MODE
	call	GrSetMixMode
endif

	.leave
	ret
BoardDrawCellBorders	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetLetterInCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If possible, will store the letter in the given cell,
		then will redraw the cell.

CALLED BY:	BoardDoActionLetter, BoardKbdLetters

PASS:		*ds:si	- CwordBoardObject class
		^hdi	- GState
		ax	- CellToken
		dx	- EngineToken
		bx	- User letter

RETURN:		CF	- SET if didn't store letter
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetLetterInCell	proc	far
	uses	cx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	CwordChar	bx
	Assert	EngineTokenType	dx
	Assert	gstate		di
;;;;;;;;

	call	EngineGetCellFlags
	test	cl, BOARD_NOT_WRITABLE_CELL
	stc					; did not make changes
	jnz	exit

	xchg	ax, bx				; character, cellToken
	call	LocalUpcaseChar
	xchg	ax, bx				; cellToken character

	; Store the inputted letter
	call	EngineSetUserLetter

	call	BoardRedrawCell
	clc					; stored letter

exit:
	.leave
	ret
BoardSetLetterInCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardClearCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will erase the user content of the cell and mark it as
		EMPTY.  Then will redraw the cell.

CALLED BY:	BoardDoActionMinus, BoardKbdLetter

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellToken
		dx	- EngineToken
		^hdi	- GState

RETURN:		CF	- SET if didn't make any changes
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardClearCell	proc	far
	uses	cx, bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
	Assert	gstate		di
;;;;;;;;

	call	EngineGetCellFlags
	test	cl, BOARD_NOT_ERASABLE_CELL
	stc					; did not make changes
	jnz	exit

	call	EngineSetCellEmpty
	call	BoardRedrawCell

	clc					; made changes

exit:
	.leave
	ret
BoardClearCell	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardHintCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will get cause the solution letter of the cell to be
		displayed.  The hinted letter will appear lighter than
		the rest of the regular letters.  Once this happens,
		the cell is no-longer modifiable.

CALLED BY:	BoardDoActionQuestion, BoardKbdPunctuation

PASS:		*ds:si	- CwordBoardClass object
		ax	- CellToken
		dx	- EngineToken
		^hdi	- GState

RETURN:		CF	- SET if didn't make any changes
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/15/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardHintCell	proc	far
	uses	bx, cx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	ax
	Assert	EngineTokenType	dx
	Assert	gstate		di
;;;;;;;;

	call	EngineGetCellFlags
	test	cl, BOARD_NOT_HINTABLE_CELL
	stc					; did not make changes
	jnz	exit

	; Get the solution letter and put it as the user letter, easy
	; for drawing.
	call	EngineGetSolutionLetter
	call	EngineSetUserLetter
	call	EngineClrUserLetterVerified
	call	EngineSetUserLetterHinted

	call	BoardRedrawCell
	clc					; made changes

exit:
	.leave
	ret
BoardHintCell	endp







COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfHWRChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will determine if the given character is part of the
		set of characters that the HWR library will recognize.

CALLED BY:	global

PASS:		cx	- character

RETURN:		CF	- SET if not HWR char

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfHWRChar	proc	far
	.enter

	call	CheckIfCwordPunct
	jnc	exit

	push	si				; save trash reg
	mov	si, offset HWREnabledChars
	call	CheckIfInCharacterSet
	pop	si				; restore trashed reg

exit:

	.leave
	ret
CheckIfHWRChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfCwordAlpha
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the character is in the Cword alpha set
		defined in the .ui file.

CALLED BY:	Global - routines of Crossword project.

PASS:		cx	- character

RETURN:		carry	- SET if not in the character set

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfCwordAlpha	proc	far
	uses	si
	.enter

	mov	si, offset KBDEnabledAlpha
	call	CheckIfInCharacterSet

	.leave
	ret
CheckIfCwordAlpha	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfCwordPunct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if the character is in the Cword punctuation
		set which consists of '.', '?', '-', ' '

CALLED BY:	Globabl - routines of Crossword project.

PASS:		cx	- character

RETURN:		carry	- SET if not in the character set

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfCwordPunct	proc	far
	.enter

	; Handle characters that don't belong to a range
	cmp	cx, C_MINUS
	je	exit			; carry CLEAR
	cmp	cx, C_QUESTION_MARK
	je	exit			; carry CLEAR
	cmp	cx, C_PERIOD
	je	exit			; carry CLEAR
	
	;    Don't allow spaces anymore because if the user enters two 
	;    letters in non adjacent squares in the same row the damn
	;    hwr code inserts a space between them. This causes seemingly
	;    random letters to disappear from the puzzle.
	;    steve 10/28/94

	; Actually, the fix to the above metioned problem should be
	; to put a filter into the recognition routine to screen the
	; unwanted spaces.  By removing it from here, spaces won't be
	; accepted as a punctation at all, thus in Graffiti, a dash,
	; which is interpreted as a space, won't erase the cell.
	; 6/29/95 - ptrinh

	cmp	cx, C_SPACE
	je	exit			; carry CLEAR

	stc				; not a Cword punctuation
exit:

	.leave
	ret
CheckIfCwordPunct	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfInCharacterSet
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will check a character if it is in the set of ranges
		of characters.  Assumes the set is in the resource
		CwordCharacterSets.

CALLED BY:	global

PASS:		^lsi	- the set of characters
		cx	- character

RETURN:		CF	- SET if not in character set
DESTROYED:	nothing
SIDE EFFECTS:	

	NOTE: Current version does not support DBCS.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/19/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfInCharacterSet	proc	far
	uses	ax,bx,di,es
	.enter

	mov	bx, handle CwordStrings	; single-launchable
	call	MemLock				; lock down char set
	segmov	es, ax				; segment CwordCharSet

	mov_tr	ax, cx				; charater
	call	GetCharacterSetString
	jc	exit

checkRanges:
	cmp	al, es:[di].IR_first
	jl	nextRange
	cmp	al, es:[di].IR_last
	jle	inRange
nextRange:
	add	di, size InclusiveRange
	loop	checkRanges
	stc					; not in set

exit:
	mov_tr	cx, ax				; char - to restore reg
	call	MemUnlock

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
inRange:
	clc
	jmp	exit

CheckIfInCharacterSet	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetCharacterSetString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will return the string of character pairs that makes
		up the ranges of valid characters.

CALLED BY:	global

PASS:		es	- locked segment of the resource containing
			  the string
		^lsi	- character pairs

RETURN:		es:di	- ptr to string
		cx	- number of byte-pairs in string
		CF	- SET if error


DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	WARNING: This version does not support DBCS.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/20/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetCharacterSetString	proc	far
	uses	ax
	.enter

	mov	di, es:[si]			; get ptr. to string

	; Get the length of the string
	call	LocalStringSize

	; If the size of the string is odd, then the text string in the
	; .ui file is unacceptable.
	shr	cx, 1				; ranges stored in pairs
	jc	err				; jump if odd

	push	cx, di				; # of pairs, ptr to string

scanForError:
	mov	ax, {word}es:[di]
	cmp	ah, al				; last, first of pair
	jb	err
	add	di, 2
	loop	scanForError
	
	pop	cx, di				; # of pairs, ptr to string

	; Everything's honky dory
	clc

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
err:
	ERROR	CWORD_BAD_CHARACTER_RANGE_FOR_HWR

GetCharacterSetString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordChangeShowNumberOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set options of Show/Hide numbers in the square.

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass

RETURN:		
		nothing

	
DESTROYED:	
		done

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	edwin	1/29/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordChangeShowNumberOptions	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_CHANGE_SHOW_NUMBER_OPTION
	.enter

	push	si
	GetResourceHandleNS	NumberOptions, bx
	mov	si, offset NumberOptions
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, mask MF_CALL
	call	ObjMessage		; ax - selection
	pop	si
	;
	;  Store the selection
	;
	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ds:[bx].CBI_hideNumber, al
	;
	;  Set the font size for the cell text
	;
	mov	ds:[bx].CBI_pointSize.WBF_int,
					BOARD_DEFAULT_TEXT_SIZE_NO_NUMBER
	test	al, mask SHOW_TRIANGLE
	jnz	fontWithTriangle

	mov	di, bx

	mov	dx, ds:[di].CBI_cellWidth		;cell size
	mov	bx,BOARD_DEFAULT_CELL_SIZE
	clr	cx,ax
	call	GrUDivWWFixed		

	clr	ax
	mov	bx,BOARD_DEFAULT_TEXT_SIZE_NO_NUMBER	;assumed default int
	cmp	ds:[di].CBI_cellWidth,BOARD_MIN_CELL_SIZE_FOR_REGION_NUMBER
	jb	calcTextSize
	mov	bx,BOARD_DEFAULT_TEXT_SIZE
calcTextSize:
	call	GrMulWWFixed
	mov	ds:[di].CBI_pointSize.WBF_int, dx
fontWithTriangle:
	;
	;  Redraw the board
	;
	GetResourceHandleNS	Board, bx
	mov	si, offset Board
	mov	ax, MSG_VIS_INVALIDATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage		; ax - selection
		
	.leave
	ret
CwordChangeShowNumberOptions		endm

CwordCode	ends

