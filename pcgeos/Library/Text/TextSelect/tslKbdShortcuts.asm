COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:
FILE:		tslKbdShortcuts.asm

AUTHOR:		John Wedgwood, Feb 15, 1990

METHODS:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	John	2/15/90		Initial revision
	reza	12/13/94	Changed all routines called from
				CallKeyBinding to set carry if handled.
DESCRIPTION:
	Functions implemented by VisText that are available via the keyboard
	binding list.

	$Id: tslKbdShortcuts.asm,v 1.1 97/04/07 11:20:15 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TextSelect	segment	resource

TextSelect_DerefVis_DI	proc	near
	class	VisTextClass
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ret
TextSelect_DerefVis_DI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VisTextKeyFunction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Execute one of the VisTextKeyFunction for an object

CALLED BY:	MSG_VIS_TEXT_DO_KEY_FUNCTION
PASS:		*ds:si	= text object
		cx	= function to execute
RETURN:		carry set
DESTROYED:	?

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VisTextDoKeyFunction	proc	far	; MSG_VIS_TEXT_DO_KEY_FUNCTION
	call	TextGStateCreate		; May need a gstate
EC <	cmp 	cx, VisTextKeyFunction					>
EC <	ERROR_AE	INVALID_TEXT_KEY_FUNCTION			>

	mov	di, cx
	call	TSL_HandleKbdShortcut

	call	TextGStateDestroy		; Nuke any state we created
	stc
	ret
VisTextDoKeyFunction endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFForwardChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance the cursor one character, if there is a selection,
		place the cursor at the end of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFForwardChar	proc	near
	call	TSL_SelectGetSelectionEnd	; dx.ax <- select end
	jc	setSelection			; if there is a selection
						;    move to end of selection
	incdw	dxax				; dx.ax <- next position

setSelection:
	;
	; dx.ax	= Position for cursor
	;
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFForwardChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFBackwardChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor backwards one character, if there is a
		selection, place the cursor at the start of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFBackwardChar	proc	near
	call	TSL_SelectGetSelectionStart	; dx.ax <- select start
	jc	move				; If it's a selection we
						;    move to select-start
	
	decdw	dxax				; Else move to previous position
move:
	;
	; dx.ax	= Position for cursor
	;
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFBackwardChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFForwardLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor down one line. If there is a selection, move
		the cursor to the line after the end of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFForwardLine	proc	near
	stc
	GOTO	ForwardOrBackwardLine
VTFForwardLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFBackwardLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor backwards one line. If there is a selection,
		move the cursor to the line preceding the start of the
		selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		ds:*si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFBackwardLine	proc	near
	clc
	FALL_THRU ForwardOrBackwardLine
VTFBackwardLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForwardOrBackwardLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor down or up one line.

CALLED BY:	VTFForwardLine, VTFBackwardLine
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		carry set to move forward
		carry clear to move backward
RETURN:		carry set - cursor move handled, clear otherwise
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForwardOrBackwardLine	proc	near
	class	VisTextClass

	push	ds:[di].VTI_cursorPos.P_y	; save cursor y-position
	lahf					; Save flags
	sub	sp, size PointDWFixed		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame
	sahf					; Restore flags
	jnc	backwards

	;
	; Move forward...
	;
	call	TSL_SelectGetSelectionEnd	; dx.ax <- select end
	jc	moveToOffset			; Branch if is a range

	;
	; The selection was a cursor, move to the next line.
	;
	call	TSL_GetCursorLine		; bx.di <- line w/ cursor on it
	call	TL_LineNext			; bx.di <- next line

common:
	;
	; bx.di	= Line to move to
	;
	call	GetLineIntoPointDWFixed		; Fill in point
	call	AdjustForGoalPosition		; Adjust the position

	;
	; Get the offset of this event and place the cursor there.
	;
	call	ComputeEventPositionAndOffset	; dx.ax <- offset into text

	;
	; dx.ax	= Offset to place cursor at.
	; bx.di	= Line where new event happens.
	;
	; We can't use FakeCursorPositionCharSelection() even though we
	; are positioning the cursor and we are changing to character mode
	; selection. The reason is that FakeCursorPositionCharSelection()
	; computes a position given the offset. We already know the
	; position and we want to use the one we computed.
	;
	call	TR_RegionFromLine		; cx <- region
	mov	di, cx				; di <- region
	clc					; Don't set the goal position
	mov	cl, ST_DOING_CHAR_SELECTION shl offset VTISF_SELECTION_TYPE
	call	FakeSelectionNoAdjust
	jmp	quit

moveToOffset:
	;
	; dx.ax	= Offset to place cursor at.
	;
	clc					; Don't set the goal position
	call	FakeCursorPositionCharSelection

quit:
	add	sp, size PointDWFixed		; Restore stack

	pop	ax				; restore old y-position
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	cmp	ds:[di].VTI_cursorPos.P_y, ax
	je	noMove
	stc
	jmp	exit
noMove:
	clc
exit:
	ret

backwards:
	call	TSL_SelectGetSelectionStart	; dx.ax <- select start
	jc	moveToOffset			; Branch if is a range

	;
	; The selection was a cursor, move to the previous line.
	;
	call	TSL_GetCursorLine		; bx.di <- line w/ cursor on it
	call	TL_LinePrevious			; bx.di <- previous line

	jmp	common
ForwardOrBackwardLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetLineIntoPointDWFixed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the position of the line into a PointDWFixed on the stack.

CALLED BY:	ForwardOrBackwardLine, etc
PASS:		*ds:si	= Instance
		bx.di	= Line
		ss:bp	= PointDWFixed on stack
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 2/24/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetLineIntoPointDWFixed	proc	near
	uses	ax, bx, cx, dx
	.enter
	call	TL_LineToExtPosition		; cx.bx <- Left edge of line
						; dx.ax <- Top edge of line
	incdw	dxax				; Force it into the line
	movdw	ss:[bp].PDF_x.DWF_int, cxbx	; Save left edge of line
	movdw	ss:[bp].PDF_y.DWF_int, dxax
	.leave
	ret
GetLineIntoPointDWFixed	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustForGoalPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust an event position so it reflects the goal-position.

CALLED BY:	ForwardOrBackwardLine
PASS:		*ds:si	= Instance
		bx.di	= Current line
		ss:bp	= PointDWFixed of left edge of line
RETURN:		PointDWFixed adjusted to be at goal position
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/ 4/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustForGoalPosition	proc	near
	class	VisTextClass
	uses	ax, bx, cx, di
	.enter
	;
	; Now account for the goal-position. The goal position assumes that
	; the line is butted up against the left edge of the region. This
	; isn't always true so we figure the left edge of the line and
	; subtract that from the goal-position. We then add this result
	; to the event position in order to get the final "event".
	;
	call	TL_LineGetLeftEdge		; ax <- offset from region
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	mov	bx, ds:[di].VTI_goalPosition	; bx <- goal position
	sub	bx, ax				; bx <- adjusted goal
	jns	gotGoal
	clr	bx				; Force to 0 if before line
gotGoal:
	clr	cx
	
	adddw	ss:[bp].PDF_x.DWF_int, cxbx	; Adjust the X position
	.leave
	ret
AdjustForGoalPosition	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFForwardWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor forward to the next word edge. If there is
		a selection, move the cursor to the end of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
	
KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFForwardWord	proc	near
	call	TSL_SelectGetSelectionEnd	; dx.ax <- select end
	jc	setCursor			; If there was a selection then
						;   we position cursor at end

if	WINDOWS_STYLE_CURSOR_KEYS
	call	FindStartOfNextWord
else
	;
	; There was no selection just a cursor. In that case we need to find
	; the next word edge.
	;
	call	FindNextWordEdge		; dx.ax <- next word edge.
endif

setCursor:
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFForwardWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFBackwardWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor backward to the next word edge. If there is
		a selection, move the cursor to the start of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFBackwardWord	proc	near
	call	TSL_SelectGetSelectionStart	; dx.ax <- select start
	jc	setCursor			; If there was a selection then
						;    we position cursor at start

if	WINDOWS_STYLE_CURSOR_KEYS
	call	FindStartOfPrevWord
else
	;
	; Skip characters backward to find the next word-edge.
	;
	call	FindPreviousWordEdge		; dx.ax <- previous word edge.
endif
setCursor:
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFBackwardWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFForwardParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor to the start of the next paragraph.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFForwardParagraph	proc	near
	call	TSL_SelectGetSelectionEnd	; dx.ax <- select end
	jc	setCursor			; if there was a selection then
						;    we position cursor at end

	call	FindNextParagraphEdge		; dx.ax <- next paragraph edge
setCursor:
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFForwardParagraph	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFBackwardParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move backwards to the previous paragraph edge.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFBackwardParagraph	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	setCursor			; if there was a selection then
						;    we position cursor at start

	call	FindPreviousParagraphEdge	; dx.ax <- prev paragraph edge
setCursor:
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFBackwardParagraph	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFStartOfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor to the start of the line. If there is a
		selection, move the cursor to the start of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFStartOfLine	proc	near
	clr	cx				; Move to start of line
	call	TSL_SelectGetSelectionStart	; dx.ax <- select start
	GOTO	StartOrEndOfLine
VTFStartOfLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFEndOfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor to the end of the line. If there is a selection
		move the cursor to the end of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFEndOfLine	proc	near
	mov	cx, -1				; Move to end of line
	call	TSL_SelectGetSelectionEnd	; dx.ax <- select end
	FALL_THRU StartOrEndOfLine
VTFEndOfLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartOrEndOfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move to the start or end of the line.

CALLED BY:	VTFStartOfLine, VTFEndOfLine
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
		cx	=  0 to move to line start
			  -1 to move to line end
		carry set if selection is a range
		dx.ax	= Position to move to if selection is a range
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/10/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartOrEndOfLine	proc	near
	class	VisTextClass

	mov	bx, ax				; Save position to go to
	lahf					; Save "is selection" flag
	sub	sp, size PointDWFixed		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame
	sahf					; Restore "is selection" flag
	mov	ax, bx				; Restore position to go to

	jc	moveToOffset			; Branch if selection is range

	;
	; The selection was a cursor, move to the next line.
	;
	push	cx				; Save offset to find
	call	TSL_GetCursorLine		; bx.di <- line w/ cursor on it
	
	pushdw	bxdi				; Save line
	call	TL_LineToExtPosition		; cx.bx <- left edge of line
						; dx.ax <- top edge of line
	incdw	dxax				; Force it into the line
	movdw	ss:[bp].PDF_y.DWF_int, dxax	; Save event top
	
	call	TextSelect_DerefVis_DI
	mov	ax, ds:[di].VTI_leftOffset	; dx.ax <- left offset
	cwd
	adddw	cxbx, dxax			; cx.bx <- *real* line-left
	
	movdw	ss:[bp].PDF_x.DWF_int, cxbx	; Save event left
	popdw	bxdi				; Restore line
	pop	cx				; Restore offset to find

	jcxz	moveToLineStart

	;
	; Find the *real* event x-position as an offset from the left edge
	; of the line.
	;
	pushdw	bxdi				; Save line
	push	bp				; Save frame ptr
	movdw	dxax, -1			; Move to line end
	mov	bp, 0x7fff			; Find this position
	call	TL_LineTextPosition		; bx <- Offset from line-left
						; dx.ax <- Position in text
	pop	bp				; Restore frame ptr

	add	ss:[bp].PDF_x.DWF_int.low, bx	; Update event position
	adc	ss:[bp].PDF_x.DWF_int.high, 0
	popdw	bxdi				; Restore line

moveToPosition:
	;
	; dx.ax	= Offset to place cursor at.
	; bx.di	= Line to move on.
	;
	; We can't use FakeCursorPositionCharSelection() even though we
	; are positioning the cursor and we are changing to character mode
	; selection. The reason is that FakeCursorPositionCharSelection()
	; computes a position given the offset. We already know the
	; position and we want to use the one we computed.
	;
	call	TR_RegionFromLine		; cx <- region
	call	TextSelect_DerefVis_DI		; ds:di <- ptr to instance
	movdw	ds:[di].VTI_lastOffset, dxax	; Save new lastOffset field

	mov	di, cx				; di <- region 
	stc					; Set the goal position
	mov	cl, ST_DOING_CHAR_SELECTION shl offset VTISF_SELECTION_TYPE
	call	FakeSelectionNoAdjust
	jmp	quit

moveToOffset:
	;
	; dx.ax	= Offset to place cursor at.
	;
	stc					; Set the goal position
	call	FakeCursorPositionCharSelection

quit:
	add	sp, size PointDWFixed		; Restore stack
	stc
	ret

moveToLineStart:
	call	TL_LineToOffsetStart		; dx.ax <- offset
	jmp	moveToPosition
StartOrEndOfLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFStartOfText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor to the start of the text.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFStartOfText	proc	near
	call	TSL_SelectGetSelectionStart	; dx.ax <- select start
	jc	setCursor			; Branch if is a selection

	clrdw	dxax				; Else use start of document
setCursor:
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFStartOfText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFEndOfText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the cursor to the end of the text.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFEndOfText	proc	near
	call	TSL_SelectGetSelectionEnd	; dx.ax <- select end
	jc	setCursor			; Branch if is a selection

	call	TS_GetTextSize			; dx.ax <- size of text
setCursor:
	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFEndOfText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the word under the cursor, if there is a selection,
		extend the selection out to word-boundaries.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectWord	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- start
						; cx.bx <- end
;;;vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
;;; Changed,  4/26/93 -jw
;;; This does not cause a notification to be sent.
;;;
	;
	; Kick these out to word edges, if they aren't already there.
	;
;;;	call	FindWordEdgeBackwards		; dx.ax <- start of new range
;;;	call	FindWordEdgeForwardsCXBX	; cx.bx <- end of new range

;;;	GOTO	AdjustSelectionToNewRange

	clc
	mov	cl, ST_DOING_CHAR_SELECTION shl offset VTISF_SELECTION_TYPE
	call	FakeSelectionNoAdjustDoublePress
	stc
	ret
;;;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
VTFSelectWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the line the cursor is on (including any CR at the end).
		If there is a selection, adjust it to line boundaries.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectLine	proc	near
PrintMessage <John: VTFSelectLine is not implemented>
	stc
	ret
VTFSelectLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the paragraph the cursor is in (through the CR).

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectParagraph	proc	near
PrintMessage <John: VTFSelectParagraph is not implemented>
	stc
	ret
VTFSelectParagraph	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the entire object.

CALLED BY:	TSL_HandleKbdShortcut
PASS:		*ds:si	= Instance
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectObject	proc	near
PrintMessage <John: VTFSelectObject is not implemented>
	stc
	ret
VTFSelectObject	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustForwardChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection by extending it forward one character.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustForwardChar	proc	near
	stc					; Signal: adjust forward
	call	SelectGetAdjustPosition		; dx.ax <- adjust position
	incdw	dxax				; Move forward one character
	
	GOTO	AdjustSelectionAndSetGoalPosition
VTFSelectAdjustForwardChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustBackwardChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection by extending it backwards one character.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustBackwardChar	proc	near
	clc					; Signal: adjust backwards
	call	SelectGetAdjustPosition		; dx.ax <- adjust position
	decdw	dxax				; Move backward one character
	
	GOTO	AdjustSelectionAndSetGoalPosition
VTFSelectAdjustBackwardChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustForwardWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection by extending it forward one word.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustForwardWord	proc	near
	stc					; Signal: adjust forwards
	call	SelectGetAdjustPosition		; dx.ax <- adjust position
if	WINDOWS_STYLE_CURSOR_KEYS
	call	FindStartOfNextWord
else
	call	FindNextWordEdge		; dx.ax <- next word edge
endif
	
	GOTO	AdjustSelectionAndSetGoalPosition
VTFSelectAdjustForwardWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustBackwardWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection by extending it backwards one word.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustBackwardWord	proc	near
	clc					; Signal: adjust backwards
	call	SelectGetAdjustPosition		; dx.ax <- adjust position
if	WINDOWS_STYLE_CURSOR_KEYS
	call	FindStartOfPrevWord
else
	call	FindPreviousWordEdge		; dx.ax <- prev word edge
endif
	
	GOTO	AdjustSelectionAndSetGoalPosition
VTFSelectAdjustBackwardWord	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustStartOfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection by extending it to the start of the current
		line.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustStartOfLine	proc	near
	sub	sp, size PointDWFixed		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame

	clc					; Signal: adjust backwards
	call	SelectGetAdjustPosition		; dx.ax <- adjust position

moveBackToPrevLineEdge:
	tstdw	dxax				; Check for at doc-start
	jz	doAdjust			; Branch if at doc-start
	
	movdw	cxbx, dxax			; Save old adjust position
	call	FindPreviousLineEdge		; dx.ax <- line start
	
	cmpdw	dxax, cxbx			; Check for no change
	jne	doAdjust			; Branch if different
	
	;
	; We tried to go to the previous line edge and failed... We must have
	; already been at the start of a line. Try again, but this time we
	; move back one character in order to force a change.
	;
	decdw	dxax
	jmp	moveBackToPrevLineEdge

doAdjust:
	;
	; Convert the offset into a coordinate.
	;
	pushdw	dxax				; Save new offset
	call	TSL_ConvertOffsetToCoordinate	; cx.bx <- x position
						; dx.ax <- y position
	movdw	ss:[bp].PDF_x.DWF_int, cxbx	; Save the "event" position
	movdw	ss:[bp].PDF_y.DWF_int, dxax
	popdw	dxax				; Restore new offset

	call	AdjustSelectionAndSetGoalPosition

quit::	
	add	sp, size PointDWFixed		; Restore stack frame
	stc
	ret
VTFSelectAdjustStartOfLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustEndOfLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection by extending it to the end of the current
		line.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustEndOfLine	proc	near
	sub	sp, size PointDWFixed		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame

	stc					; Signal: adjust forward
	call	SelectGetAdjustPosition		; dx.ax <- adjust position

moveForwardToNextLineEdge:
	movdw	cxbx, dxax			; Save position

	call	FindNextLineEdge		; dx.ax <- next line edge

	cmpdw	cxbx, dxax			; Check for no change
	jne	doAdjust
	
	;
	; There was no change. This means that either we were at the end of
	; a line already, or perhaps we're at the end of the text.
	;
	call	TS_GetTextSize			; dx.ax <- end of text
	cmpdw	dxax, cxbx			; Check for at end
	je	doAdjust			; Branch if we are
	
	movdw	dxax, cxbx			; dx.ax <- current position
	incdw	dxax				; Move forward to force change
	jmp	moveForwardToNextLineEdge

doAdjust:
	;
	; Convert the offset into a coordinate.
	;
	pushdw	dxax
	call	TSL_ConvertOffsetToCoordinate	; cx.bx <- x position
						; dx.ax <- y position
	movdw	ss:[bp].PDF_x.DWF_int, cxbx	; Save the "event" position
	movdw	ss:[bp].PDF_y.DWF_int, dxax
	popdw	dxax

	call	AdjustSelectionAndSetGoalPosition

	add	sp, size PointDWFixed		; Restore stack frame
	stc
	ret
VTFSelectAdjustEndOfLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustForwardLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection by extending it to the start of the next
		line.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustForwardLine	proc	near
	;
	; We get the adjustable position, find the line containing that 
	; position and move to the next line. We figure the offset at that
	; position, and if it isn't any different than the position we started
	; with, we try the next line.
	;
	stc					; Adjusting forwards
	call	SelectGetAdjustPosition		; dx.ax <- adjustable position
	
	stc					; Want first line with offset
	call	TL_LineFromOffset		; bx.di <- line

	sub	sp, size PointDWFixed		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame

;-----------------------------------------------------------------------------
tryAgain:
	call	TL_LineNext			; bx.di <- next line
	jc	quit				; Branch if no next line

	;
	; bx.di	= Line we want to move on to
	;
	call	GetLineIntoPointDWFixed		; Fill in the line position
	call	AdjustForGoalPosition

	;
	; Get the offset of this event and place the cursor there.
	;
	call	ComputeEventPositionAndOffset	; dx.ax <- offset into text
	
	call	IsAdjustPosition		; Is dx.ax adjust position?
	je	tryAgain			; Branch if it is
;-----------------------------------------------------------------------------

	;
	; dx.ax	= Offset to place cursor at.
	;
	call	AdjustSelectionAndDoNotSetGoalPosition

quit:
	add	sp, size PointDWFixed		; Restore stack frame
	stc
	ret
VTFSelectAdjustForwardLine	endp

;---------------------------

IsAdjustPosition	proc	near
	uses	ax, bx, cx, dx
	.enter
	movdw	cxbx, dxax			; cx.bx <- position
	call	SelectGetAdjustPosition		; dx.ax <- adjust position
	cmpdw	cxbx, dxax			; Compare them...
	.leave
	ret
IsAdjustPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustBackwardLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection backward to the start of a line.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustBackwardLine	proc	near
	;
	; We get the adjustable position, find the line containing that 
	; position and move to the previous line. We figure the offset at that
	; position, and if it isn't any different than the position we started
	; with, we try the previous line.
	;
	clc					; Adjusting backwards
	call	SelectGetAdjustPosition		; dx.ax <- adjustable position
	
	clc					; Want last line with offset
	call	TL_LineFromOffset		; bx.di <- line

	sub	sp, size PointDWFixed		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame

;-----------------------------------------------------------------------------
tryAgain:
	call	TL_LinePrevious			; bx.di <- previous line
	jc	quit				; Branch if no previous line
	
	;
	; bx.di	= Line we want to move on to
	;
	call	GetLineIntoPointDWFixed		; Get line position
	call	AdjustForGoalPosition

	;
	; Get the offset of this event and place the cursor there.
	;
	call	ComputeEventPositionAndOffset	; dx.ax <- offset into text
	call	IsAdjustPosition		; Is dx.ax adjust position?
	je	tryAgain			; Branch if it is
;-----------------------------------------------------------------------------

	;
	; dx.ax	= Offset to place cursor at.
	;
	call	AdjustSelectionAndDoNotSetGoalPosition

quit:
	add	sp, size PointDWFixed		; Restore stack
	stc
	ret
VTFSelectAdjustBackwardLine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustForwardParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection forward to the start of a paragraph.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustForwardParagraph	proc	near
	stc					; Signal: adjust forward
	call	SelectGetAdjustPosition		; dx.ax <- adjust position
	call	FindNextParagraphEdge		; dx.ax <- next para edge

	GOTO	AdjustSelectionAndDoNotSetGoalPosition
VTFSelectAdjustForwardParagraph	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustBackwardParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection backward to the start of a paragraph.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustBackwardParagraph	proc	near
	clc					; Signal: adjust backwards
	call	SelectGetAdjustPosition		; dx.ax <- adjust position
	call	FindPreviousParagraphEdge	; dx.ax <- prev para edge
	
	GOTO	AdjustSelectionAndDoNotSetGoalPosition
VTFSelectAdjustBackwardParagraph	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustToStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection to include the start of the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustToStart	proc	near
	clrdw	dxax				; dx.ax <- adjusted end
	
	GOTO	AdjustSelectionAndDoNotSetGoalPosition
VTFSelectAdjustToStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFSelectAdjustToEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection to include the end of the text.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFSelectAdjustToEnd	proc	near
	call	TS_GetTextSize			; dx.ax <- end of text
	
	GOTO	AdjustSelectionAndDoNotSetGoalPosition
VTFSelectAdjustToEnd	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteBackwardChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the previous character or delete the selection.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteBackwardChar	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange			; Delete range if there is one

	;
	; Create a range starting 1 character before the cursor.
	; cx.bx == dx.ax == Position of cursor.
	;
	tstdw	dxax				; Check for at start of text
	jz	quit				; Branch if at start

	decdw	dxax				; dx.ax <- start of range

delRange:
	call	DeleteRange

quit:
	stc
	ret
VTFDeleteBackwardChar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the selection is a cursor, delete the next character.
		If the selection is a range, delete the range.
		If the cursor is at the end of the text, do nothing.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteChar	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange			; Delete range if there is one

	;
	; Create a range starting at the cursor position.
	;
	incdw	dxax				; dx.ax <- end of range
	
	;
	; Make sure the position isn't beyond the end.
	;
	call	IsBeyondTextEnd			; carry set if beyond end
	jc	quit				; Branch if nothing to nuke

delRange:
	call	DeleteRange

quit:
	stc
	ret
VTFDeleteChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteBackwardWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete backwards to the previous word edge.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteBackwardWord	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange

	;
	; Selection is a cursor, find previous word edge and delete to there.
	;
	call	FindPreviousWordEdge		; dx.ax <- previous word edge

delRange:
	FALL_THRU	DeleteRange
VTFDeleteBackwardWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a range, updating goal position, etc.
		Does not allow deletion at the end of the text.

CALLED BY:	VTFDeleteBackwardChar, VTFDeleteLine, VTFDeleteBackwardWord
PASS:		*ds:si	= instance ptr.
		dx.ax	= start of range to delete
		cx.bx	= end of range to delete
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DeleteRange	proc	near
	class	VisTextClass

	call	TextSelect_DerefVis_DI
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	quit

	cmpdw	dxax, cxbx			; Order the range.
	je	quit
	jb	ordered
	xchgdw	dxax, cxbx
ordered:

	push	bp
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp

	movdw	ss:[bp].VTRP_range.VTR_start, dxax
	movdw	ss:[bp].VTRP_range.VTR_end, cxbx
	clrdw	ss:[bp].VTRP_insCount		; no insertion.
	mov	ss:[bp].VTRP_flags, mask VTRF_FILTER or \
				    mask VTRF_KEYBOARD_INPUT or \
				    mask VTRF_USER_MODIFICATION
	;
	; We never need to worry about exceeding the size of the text here.
	; We are deleting after all.
	;
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock

	add	sp, size VisTextReplaceParameters
	pop	bp
quit:
	stc
	ret
DeleteRange	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteBackwardLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete from the cursor position to the start of the line.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteBackwardLine	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange

	;
	; Selection is a cursor, find previous line edge and delete to there.
	;
	call	FindPreviousLineEdge		; dx.ax <- previous line edge

delRange:
	GOTO	DeleteRange
VTFDeleteBackwardLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteBackwardParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete backwards to the start of a paragraph (or the start
		of the object).

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteBackwardParagraph	proc	near
	call	TU_NukeCachedUndo
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange			; Branch if it's a selection

	call	FindPreviousParagraphEdge	; dx.ax <- prev paragraph edge.

delRange:
	GOTO	DeleteRange
VTFDeleteBackwardParagraph	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteToStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete to the start of the object.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteToStart	proc	near
	call	TU_NukeCachedUndo
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange			; Branch if not a cursor.
	clrdw	dxax				; Else delete to start.
delRange:
	GOTO	DeleteRange
VTFDeleteToStart	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteToEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete to the end of the object.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteToEnd	proc	near
	call	TU_NukeCachedUndo
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange			; Branch if not a cursor

	call	TS_GetTextSize			; dx.ax <- end of text

delRange:
	GOTO	DeleteRange
VTFDeleteToEnd	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete forward to the next word boundary.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteWord	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- selection start
						; cx.bx <- selection end
	jc	delRange			; Branch if it's a range

	;
	; Selection is a cursor, find next word edge and delete to there.
	;
	call	FindNextWordEdge		; dx.ax <- next word edge

delRange:
	GOTO	DeleteRange
VTFDeleteWord	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete to the end of the current line.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:
	If position is at line-start:
		Nuke to start of next line.
	If position is at line end and last field ends in a CR:
		Nuke to start of next line.
	If position is in the middle of a word-wrapped line:
		Nuke to start of next line.

	If position is at end of word-wrapped line:
		Do nothing

	If position is in the middle of a line which ends in CR:
		Nuke up to the CR.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteLine	proc	near
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange			; Delete range if there is one

	;
	; Delete the line containing the cursor.
	;
	push	bx
	call	TSL_GetCursorLine		; bx.di <- line w/ cursor on it
	call	TL_LineToOffsetEnd		; dx.ax <- end
	pop	bx
	xchgdw	dxax, cxbx			; dx.ax <- start, cx.bx <- end

delRange:
	call	DeleteRange
	stc
	ret
VTFDeleteLine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteParagraph
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the paragraph under the cursor.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteParagraph	proc	near
	call	TU_NukeCachedUndo
	call	TSL_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	jc	delRange

	;
	; Is a cursor, extend to para boundaries and nuke.
	;
	call	ParagraphUnderPoint		; dx.ax/cx.bx <- paragraph

delRange:
	GOTO	DeleteRange
VTFDeleteParagraph	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeleteEverything
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Nuke the whole object.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeleteEverything	proc	near
	call	TU_NukeCachedUndo	
	call	TS_GetTextSize			; dx.ax <- end of object
	movdw	cxbx, dxax			; cx.bx <- start of object
	clrdw	dxax				; 
	GOTO	DeleteRange
VTFDeleteEverything	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFDeselect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deselect, leaving just a cursor.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFDeselect	proc	near
	call	TSL_SelectGetSelectionStart	; dx.ax <- select start

	stc					; Set the goal position
	GOTO	FakeCursorPositionCharSelection
VTFDeselect	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFToggleOverstrikeMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle between overstrike and insert mode.  If the UI is
		not allowing overstrike mode, we'll allow it to be toggled
		off but not back on.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, di, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


VTFToggleOverstrikeMode	proc	near
	class	VisTextClass

	test	ds:[di].VTI_state, mask VTS_OVERSTRIKE_MODE
	jz	enterOverstrikeMode

	mov	ax, MSG_VIS_TEXT_ENTER_INSERT_MODE
	jmp	gotMethod

enterOverstrikeMode:
	call	UserGetOverstrikeMode		; are we really into this?
	jz	quit				; no, skip this stuff
	mov	ax, MSG_VIS_TEXT_ENTER_OVERSTRIKE_MODE

gotMethod:
	mov	cx, -1				; Called from object.
	call	ObjCallInstanceNoLock
quit:
	stc
	ret
VTFToggleOverstrikeMode	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFClearSmartQuotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the variable that prohibits smart quotes

PASS:		nothing
RETURN:		carry set
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFClearSmartQuotes	proc	far
	class	VisTextClass
	uses	ds, ax
	.enter

	mov	ax, segment dgroup
	mov	ds, ax
	clr	ds:[uiSmartQuotes]

	.leave
	stc
	ret
VTFClearSmartQuotes	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFToggleSmartQuotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle smart quotes on and off.

CALLED BY:	TSL_HandleKbdShortcut (via function list)
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		carry set
DESTROYED:	ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFToggleSmartQuotes	proc	near
	class	VisTextClass
	uses	ds
	.enter
	mov	ax, segment dgroup
	mov	ds, ax
	not	ds:[uiSmartQuotes]
	stc
	.leave
	ret
VTFToggleSmartQuotes	endp


if 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFStartSpellCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the spell check box.

CALLED BY:	GLOBAL
PASS:		*ds:si	= Instance ptr
		ds:di	= Instance ptr
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, si, di

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFStartSpellCheck	proc	near
	class	VisTextClass
;
;	IF OBJECT IS EDITABLE AND HAS THE TARGET, THEN BRING UP THE SPELL BOX.
;
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	exit
	test	ds:[di].VTI_state, mask VTS_EDITABLE
	jz	exit
	
	call	T_SelectGetSelection		; dx.ax <- select start
						; cx.bx <- select end
	subdw	dxax, cxbx			; dx.ax <- selection size
	
	mov	cx, dx				; cl <- non-zero if chars
	or	cx, ax				;	selected
	or	cl, ch

	mov	ax, MSG_SPELL_BOX_INITIATE
	call	UserCallApplication

exit:
	stc
	ret
VTFStartSpellCheck	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VTFStartSearchReplace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the search replace box.

CALLED BY:	GLOBAL
PASS:		*ds:si	= instance ptr.
		ds:di	= text instance
RETURN:		carry set
DESTROYED:	ax, bx, cx, dx, bp, si, di

PSEUDO CODE/STRATEGY:
		This page intentionally left blank

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	atw	3/29/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
VTFStartSearchReplace	proc	near
	class	VisTextClass
;
;	IF OBJECT HAS THE TARGET, THEN BRING UP THE SPELL BOX.
;
	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	exit
	mov	ax, MSG_SEARCH_BOX_INITIATE
	call	UserCallApplication
exit:
	stc
	ret
VTFStartSearchReplace	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ForceOffsetLegal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make an offset into the text into something legal.

CALLED BY:	FakeSelectionNoAdjust, FakeSelectionAdjust
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset to check
RETURN:		dx.ax	= Reasonable offset
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ForceOffsetLegal	proc	near
	tst	dx				; Check for negative
	js	forceZero

	pushdw	cxbx
	movdw	cxbx, dxax			; cx.bx <- offset to adjust
	call	TS_GetTextSize			; dx.ax <- max size
	
	cmpdw	cxbx, dxax			; cx.bx <- MIN(maxSize, passed)
	jbe	sizeOK
	movdw	cxbx, dxax			; cx.bx <- max size
sizeOK:
	movdw	dxax, cxbx
	popdw	cxbx

quit:
	ret

forceZero:
	clrdw	dxax
	jmp	quit
ForceOffsetLegal	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FakeCursorPositionCharSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fake positioning the cursor as though it came from the mouse.

CALLED BY:	Utility
PASS:		*ds:si	= Instance ptr
		dx.ax	= New offset for the cursor
		carry set to set the goal position
RETURN:		carry set
DESTROYED:	di, bx, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FakeCursorPositionCharSelection	proc	near
	mov	cx, ax				; cx <- low word of offset

	lahf					; Save "set goal" flag
	sub	sp, size PointDWFixed		; Allocate stack frame
	mov	bp, sp				; ss:bp <- stack frame
	sahf					; Restore "set goal" flag

	pushf					; Save flags
	mov	ax, cx				; Restore low word of offset

	;
	; The implication of a no-adjust character-mode selection is that
	; we are placing a cursor. Doing this requires that we have the
	; position to put the cursor at. Unfortunately none of the callers
	; of this routine will have done this. This means that we need to
	; figure the cursor position.
	;
	call	ForceOffsetLegal		; Make dx.ax legal

	push	ax, dx				; Save offset
	call	TSL_ConvertOffsetToCoordinate	; cx.bx <- x position
						; dx.ax <- y position
	movdw	ss:[bp].PDF_x.DWF_int, cxbx	; Save the cursor position
	movdw	ss:[bp].PDF_y.DWF_int, dxax
	pop	ax, dx				; Restore offset

	call	TR_RegionFromOffset		; cx <- region
	mov	di, cx				; di <- region
	
	;
	; Now that the stack frame is set up we can go ahead and position
	; the cursor.
	;
	popf					; Restore "set goal" flag
	mov	cl, ST_DOING_CHAR_SELECTION shl offset VTISF_SELECTION_TYPE
	call	FakeSelectionNoAdjust

	add	sp, size PointDWFixed		; Restore stack
	stc
	ret
FakeCursorPositionCharSelection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FakeSelectionNoAdjustDoublePress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fake a selection event as though it came from the mouse.

CALLED BY:	VTFForwardChar
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset for the cursor
		cl	= New selection mode
		event position in inheritable PointDWord. 
				This is only required for line selection.
		carry set to set the goal position
RETURN:		nothing
DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FakeSelectionNoAdjustDoublePress	proc	near
	push	cx				; Save new selection mode
	call	TR_RegionFromOffset		; cx <- region
	mov	di, cx				; di <- region
	pop	cx				; Save new selection mode

	mov	bx, mask BI_DOUBLE_PRESS
	GOTO	FakeSelectionNoAdjustGotFlags
FakeSelectionNoAdjustDoublePress	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FakeSelectionNoAdjust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fake a selection event as though it came from the mouse.

CALLED BY:	VTFForwardChar
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset for the cursor
		cl	= New selection mode
		di	= Region in which event occurred
		event position in inheritable PointDWord.
				This is only required for line selection.
		carry set to set the goal position
RETURN:		nothing
DESTROYED:	di, bx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FakeSelectionNoAdjust	proc	near
	mov	bx, 0				; (can't nuke carry)
	FALL_THRU FakeSelectionNoAdjustGotFlags
FakeSelectionNoAdjust	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FakeSelectionNoAdjustGotFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fake a selection event as though it came from the mouse.

CALLED BY:	VTFForwardChar
PASS:		*ds:si	= Instance ptr
		di	= Region to put the cursor in
		dx.ax	= Offset for the cursor
		cl	= New selection mode
		ss:bp	= PointDWFixed where event occurred
		bx	= ButtonInfo
				(BI_DOUBLE_PRESS bit is all we care about)
		carry set to set the goal position
RETURN:		nothing
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FakeSelectionNoAdjustGotFlags	proc	near
	class	VisTextClass
	uses	bp, cx
	.enter
	pushf					; Save "set goal-pos" flag
	;
	; Save the new selection type
	;
	push	di				; Save region for event
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	and	ds:[di].VTI_intSelFlags, not mask VTISF_SELECTION_TYPE
	or	ds:[di].VTI_intSelFlags, cl
	
	call	ForceOffsetLegal		; Make dx.ax legal
	pop	di				; Restore region for event

	;
	; Adjust the selection
	; *ds:si= Instance ptr
	; di	= Region where event occurred
	; dx.ax	= Offset into text where event occurred
	; bx	= ButtonInfo (BI_DOUBLE_PRESS bit is all we care about)
	; VTI_startEventPos set
	; current event position as inheritable PointDWord stack frame for
	;	line selection.
	;
	call	StartSelectNoAdjust
	
	clr	bp
	call	TextCallShowSelection
	
	popf					; Restore "set goal-pos" flag
	jnc	quit				; Branch if no set desired
	;
	; Copy the cursor position into the goal position.
	;
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	mov	bp, ds:[di].VTI_cursorPos.P_x	; Update the goal position.
	mov	ds:[di].VTI_goalPosition, bp
quit:
	call	TA_UpdateRunsForSelectionChange
	call	SendNotif
	.leave
	ret
FakeSelectionNoAdjustGotFlags	endp

SendNotif	proc	near
	push	ax
        mov     ax, VIS_TEXT_STANDARD_NOTIFICATION_FLAGS
        call    TA_SendNotification     ; notify that selection changed
	pop	ax
	ret
SendNotif	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FakeSelectionAdjust
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Fake a selection event as though it came from the mouse.

CALLED BY:	VTFForwardChar
PASS:		*ds:si	= Instance ptr
		dx.ax	= Offset for the cursor
		cl	= New selection mode
		ss:bp	= PointDWFixed where event occurred.
			  This is only required for line selection
RETURN:		carry set
DESTROYED:	di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/ 9/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
FakeSelectionAdjust	proc	near
	class	VisTextClass
	uses	bp, cx
	.enter
	;
	; Save the new selection type
	;
	call	TextSelect_DerefVis_DI		; ds:di <- instance ptr
	and	ds:[di].VTI_intSelFlags, not mask VTISF_SELECTION_TYPE
	or	ds:[di].VTI_intSelFlags, cl
	
	call	ForceOffsetLegal		; Make dx.ax legal

	;
	; Adjust the selection
	; *ds:si= Instance ptr
	; ds:di	= Instance ptr
	; dx.ax	= Offset into text where event occurred
	; bx	= UIFunctionsActive (BI_DOUBLE_PRESS bit is all we care about)
	; VTI_startEventPos set
	; current event position as inheritable PointDWord stack frame for
	;	line selection.
	;
	stc					; Set minimum selection
	call	StartSelectAdjust
	
	clr	bp
	call	TextCallShowSelection
	call	SendNotif
	stc
	.leave
	ret
FakeSelectionAdjust	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AdjustSelectionAnd(DoNot)SetGoalPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adjust the selection and possibly set the goal position.

CALLED BY:	Utility
PASS:		Same as FakeSelectionAdjust, except cl doesn't get passed.
RETURN:		...
DESTROYED:	...

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AdjustSelectionAndSetGoalPosition	proc	near
	mov	cl, ST_DOING_CHAR_SELECTION shl offset VTISF_SELECTION_TYPE
	GOTO	FakeSelectionAdjust
AdjustSelectionAndSetGoalPosition	endp

AdjustSelectionAndDoNotSetGoalPosition	proc	near
	mov	cl, ST_DOING_CHAR_SELECTION shl offset VTISF_SELECTION_TYPE
	GOTO	FakeSelectionAdjust
AdjustSelectionAndDoNotSetGoalPosition	endp

TextSelect	ends

TextFixed	segment

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_GetCursorLineBLOAndHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the line that the cursor is on.

CALLED BY:	UTILITY
PASS:		*ds:si	= Instance ptr
RETURN:		bx.al	= Baseline
		dx.ah	= Line height
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_GetCursorLineBLOAndHeight	proc	far
	class	VisTextClass
	uses	cx
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr

	mov	dx, ds:[di].VTI_cursorPos.P_y	; dx <- cursor y position
	mov	ax, ds:[di].VTI_cursorPos.P_x	; ax <- cursor x position
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- cursor region
	call	TL_LineFromPositionGetBLOAndHeight
	.leave
	ret
TSL_GetCursorLineBLOAndHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_GetCursorLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the line that the cursor is on.

CALLED BY:	UTILITY
PASS:		*ds:si	= Instance ptr
RETURN:		bx.di	= Line cursor is on
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	6/ 7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_GetCursorLine	proc	far
	class	VisTextClass
	uses	ax, cx, dx
	.enter
	call	TextFixed_DerefVis_DI		; ds:di <- instance ptr

	mov	dx, ds:[di].VTI_cursorPos.P_y	; dx <- cursor y position
	mov	ax, ds:[di].VTI_cursorPos.P_x	; ax <- cursor x position
	mov	cx, ds:[di].VTI_cursorRegion	; cx <- cursor region
	call	TL_LineFromPosition		; bx.di <- line cursor is on
	.leave
	ret
TSL_GetCursorLine	endp

TextFixed	ends

TextSelect segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TSL_HandleKbdShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a keyboard shortcut

CALLED BY:	Global
PASS:		*ds:si	= Instance ptr
		di	= VisTextKeyFunction
		ax, cx	= Arguments
		dx	= Argument to pass in bp
RETURN:		nothing
		REPSONDER-ONLY: carry set - binding handled
				carry clear - binding not handled
DESTROYED:	everything

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 4/20/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TSL_HandleKbdShortcut	proc	far
;	If we are under a content, we can get the focus and receive keystrokes
;	before our geometry is done (no VTI_lines structure), so if we can't
;	draw, ignore this key, and exit with carry set

	call	TextCheckCanDraw		;
	jc	exit

	mov	bp, dx				; pass param in bp
	mov	bx, di				; bx <- offset to jmp to
	add	bx, offset cs:visTextBindings	; bx <- place to jmp to
	call	TextSelect_DerefVis_DI		; ds:di <- instance
if SIMPLE_RTL_SUPPORT
	test	ds:[di].VTI_features, mask VTF_RIGHT_TO_LEFT
	je	notRTL
	sub	bx, offset cs:visTextBindings
	add	bx, offset cs:visTextBindingsRTL
notRTL:
endif
	jmp	bx				; Do the call

exit:
	ret

visTextBindings		label	near

	; multi-line only bindings

	DefTextCall	VTFForwardLine
	DefTextCall	VTFBackwardLine
	DefTextCall	VTFSelectAdjustForwardLine
	DefTextCall	VTFSelectAdjustBackwardLine

	DefTextCall	VTFForwardChar
	DefTextCall	VTFBackwardChar
	DefTextCall	VTFForwardWord
	DefTextCall	VTFBackwardWord
	DefTextCall	VTFForwardParagraph
	DefTextCall	VTFBackwardParagraph
	DefTextCall	VTFStartOfLine
	DefTextCall	VTFEndOfLine
	DefTextCall	VTFStartOfText
	DefTextCall	VTFEndOfText
	DefTextCall	VTFSelectWord
	DefTextCall	VTFSelectLine
	DefTextCall	VTFSelectParagraph
	DefTextCall	VTFSelectObject
	DefTextCall	VTFSelectAdjustForwardChar
	DefTextCall	VTFSelectAdjustBackwardChar
	DefTextCall	VTFSelectAdjustForwardWord
	DefTextCall	VTFSelectAdjustBackwardWord
	DefTextCall	VTFSelectAdjustForwardParagraph
	DefTextCall	VTFSelectAdjustBackwardParagraph
	DefTextCall	VTFSelectAdjustToStart
	DefTextCall	VTFSelectAdjustToEnd
	DefTextCall	VTFSelectAdjustStartOfLine
	DefTextCall	VTFSelectAdjustEndOfLine
	DefTextCall	VTFDeleteBackwardChar
	DefTextCall	VTFDeleteBackwardWord
	DefTextCall	VTFDeleteBackwardLine
	DefTextCall	VTFDeleteBackwardParagraph
	DefTextCall	VTFDeleteToStart
	DefTextCall	VTFDeleteChar
	DefTextCall	VTFDeleteWord
	DefTextCall	VTFDeleteLine
	DefTextCall	VTFDeleteParagraph
	DefTextCall	VTFDeleteToEnd
	DefTextCall	VTFDeleteEverything
	DefTextCall	VTFDeselect
	DefTextCall	VTFToggleOverstrikeMode
	DefTextCall	VTFToggleSmartQuotes

if SIMPLE_RTL_SUPPORT
visTextBindingsRTL		label	near

	; multi-line only bindings

	DefTextCall	VTFForwardLine
	DefTextCall	VTFBackwardLine
	DefTextCall	VTFSelectAdjustForwardLine
	DefTextCall	VTFSelectAdjustBackwardLine

	DefTextCall	VTFBackwardChar
	DefTextCall	VTFForwardChar
	DefTextCall	VTFBackwardWord
	DefTextCall	VTFForwardWord
	DefTextCall	VTFForwardParagraph
	DefTextCall	VTFBackwardParagraph
	DefTextCall	VTFStartOfLine
	DefTextCall	VTFEndOfLine
	DefTextCall	VTFStartOfText
	DefTextCall	VTFEndOfText
	DefTextCall	VTFSelectWord
	DefTextCall	VTFSelectLine
	DefTextCall	VTFSelectParagraph
	DefTextCall	VTFSelectObject
	DefTextCall	VTFSelectAdjustBackwardChar
	DefTextCall	VTFSelectAdjustForwardChar
	DefTextCall	VTFSelectAdjustBackwardWord
	DefTextCall	VTFSelectAdjustForwardWord
	DefTextCall	VTFSelectAdjustForwardParagraph
	DefTextCall	VTFSelectAdjustBackwardParagraph
	DefTextCall	VTFSelectAdjustToStart
	DefTextCall	VTFSelectAdjustToEnd
	DefTextCall	VTFSelectAdjustStartOfLine
	DefTextCall	VTFSelectAdjustEndOfLine
	DefTextCall	VTFDeleteBackwardChar
	DefTextCall	VTFDeleteBackwardWord
	DefTextCall	VTFDeleteBackwardLine
	DefTextCall	VTFDeleteBackwardParagraph
	DefTextCall	VTFDeleteToStart
	DefTextCall	VTFDeleteChar
	DefTextCall	VTFDeleteWord
	DefTextCall	VTFDeleteLine
	DefTextCall	VTFDeleteParagraph
	DefTextCall	VTFDeleteToEnd
	DefTextCall	VTFDeleteEverything
	DefTextCall	VTFDeselect
	DefTextCall	VTFToggleOverstrikeMode
	DefTextCall	VTFToggleSmartQuotes
endif

TSL_HandleKbdShortcut	endp

TextSelect ends

