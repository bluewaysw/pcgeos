COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		
FILE:		cwordBoardKbd.asm

AUTHOR:		Peter Trinh, Aug 30, 1994

ROUTINES:
	Name			Description
	----			-----------

	METHODS
	-------
	BoardKbdChar		Maps keyboard input to routines
	BoardStartSelect	Selects a square
	BoardStartMoveCopy	Toggles direction

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardKbdLetters		Handles letter keypresses.
	BoardKbdPunctuation	Handles punctuation keypresses.
	BoardKbdEnter		Handles the ENTER key.
	BoardKbdDown		... DOWN ARROW key
	BoardKbdUp		... UP ARROW key
	BoardKbdRight		... RIGHT ARROW key
	BoardKbdLeft		... LEFT ARROW key
	BoardKbdShiftDown	... SHIFT DOWN ARROW
	BoardKbdShiftUp		... SHIFT UP ARROW
	BoardKbdShiftRight	... SHIFT RIGHT ARROW
	BoardKbdShiftLeft	... SHIFT LEFT ARROW
	BoardKbdPuzzle		... CTRL-P
	BoardKbdVerify		... CTRL-V
	BoardKbdZoom		... CTRL-Z
	BoardKbdSave		... CTRL-S
	BoardKbdDelete		... DELETE
	BoardKbdBackspace	... BACKSPACE
	BoardKbdSpace		... SPACE BAR
	BoardKbdPeriod		... PERIOD

	BoardSetSelectedWordFromPoint
	BoardSwitchToKeyboardMode
	BoardToggleDirection		Toggles curr direction and highlights
	BoardToggleDirectionNoHiLite    Toggles curr direction
	BoardClearSelectedCell		Clears the selected cell.

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/30/94   	Initial revision


DESCRIPTION:
	
	This file contains all keyboard and mouse related routines.
		

	$Id: cwordBoardKbd.asm,v 1.1 97/04/04 15:14:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


CwordBoardKbdCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Maps the keyboard input to the appropriate routines
		that takes care of the input.

CALLED BY:	MSG_META_KBD_CHAR
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	= character value
		dl	= CharFlags
		bp low	= ToggleState
		bp high	= scan code

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdChar	method dynamic CwordBoardClass, 
					MSG_META_KBD_CHAR
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	;    Tab navigation is a disaster in the crossword puzzle. Suddenly
	;    the user cannot type to puzzle and can't figure out how to
	;    fix it. Eat the tab.
	;

	cmp	cl,C_TAB
	je	exit

	tst	ds:[di].CBI_engine		; Board isn't init yet
	jz	callSuper

	call	BoardSwitchToKeyboardMode

	pushdw	dssi				; *ds:si - Board object
	segmov	ds, cs
	mov	si, offset BoardKbdShortcuts	; table
	mov	ax, length BoardKbdShortcuts
	call	FlowCheckKbdShortcut
	mov	di, si				; offset into table
	popdw	dssi				; *ds:si - Board object
	jnc	notInTable
	call	{nptr} cs:[BoardKbdActions][di]
	jnc	handled

notInTable:
	call	BoardKbdLetters
	jc	callSuper

handled:
EC <	ERROR_C BOARD_CHAR_SHOULD_HAVE_BEEN_HANDLED	>
	jmp	done
exit:
	cmp	dl, mask CF_RELEASE
	je	done

	GetResourceHandleNS	AcrossClueList, bx
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	mov	di, mask MF_FORCE_QUEUE

	and	dh, mask SS_LSHIFT or  mask SS_RSHIFT
	jnz	prev
		
	mov	si, offset AcrossClueList
	call	ObjMessage
	jmp	done
prev:
	mov	si, offset DownClueList
	call	ObjMessage
done:
	.leave
EC <	Destroy	ax, cx, dx, bp	>
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
callSuper:
	mov	ax, MSG_META_KBD_CHAR
	mov	di, offset CwordBoardClass
	call	ObjCallSuperNoLock
	jmp	done

BoardKbdChar	endm


	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;
BoardKbdShortcuts KeyboardShortcut \
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>,		;<left arrow>
	<1, 0, 0, 1, 0xf, VC_DOWN>,		;<Shift><down arrow>
	<1, 0, 0, 1, 0xf, VC_UP>,		;<Shift><up arrow>
	<1, 0, 0, 1, 0xf, VC_RIGHT>,		;<Shift><right arrow>
	<1, 0, 0, 1, 0xf, VC_LEFT>,		;<Shift><left arrow>
	<1, 0, 0, 0, 0xf, VC_DEL>,		;<Delete>
	<0, 0, 0, 0, 0xf, VC_BACKSPACE>,	;<Backspace>
	<0, 0, 0, 0, 0x0, C_SPACE>,		;<SpaceBar>
	<1, 0, 0, 0, 0x0, C_PERIOD>,		;<.>
	<1, 0, 0, 0, 0x0, C_QUESTION_MARK>	;<?>

BoardKbdActions nptr \
	offset BoardKbdDown,
	offset BoardKbdUp,
	offset BoardKbdRight,
	offset BoardKbdLeft,
	offset BoardKbdShiftDown,
	offset BoardKbdShiftUp,
	offset BoardKbdShiftRight,
	offset BoardKbdShiftLeft,
	offset BoardKbdDelete,
	offset BoardKbdBackspace,
	offset BoardKbdSpace, 
	offset BoardKbdPeriod,
	offset BoardKbdPunctuation

CheckHack <length BoardKbdShortcuts eq length BoardKbdActions>



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when the mouse is clicked.  This is used to
		determine the new selected square and selected word. If
		the click is on the current selected square then the
		direction of the selected word is toggled. If the click
		is not on the currently selected square then the new cell 
		becomes the selected square, the will be moved to pass 
		through that selected cell, but the current direction will
		be left unchanged.

CALLED BY:	MSG_META_START_SELECT
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	- X position of mouse
		dx	- X position of mouse
		bp low  - ButtonInfo
		bp high - UIFunctionsActive	(In Objects/uiInputC.def)

RETURN:		ax	- MouseReturnFlags
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardStartSelect	method dynamic CwordBoardClass, 
					MSG_META_START_SELECT
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	InDoc	cxdx
;;;;;;;;

	tst	ds:[di].CBI_engine
	jz	exit

	mov	bx,ds:[di].CBI_direction
	call	BoardSetSelectedWordFromPoint

exit:
	mov	ax, mask MRF_PROCESSED

	.leave
	ret
BoardStartSelect	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardStartMoveCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent when the mouse is clicked.  This is used to
		determine which cell is to become the new selected
		square, and then highlights the down word.  If the
		current selected cell was clicked, then will just
		toggle the direction.

CALLED BY:	MSG_META_START_MOVE_COPY
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	- X position of mouse
		dx	- X position of mouse
		bp low  - ButtonInfo
		bp high - UIFunctionsActive	(In Objects/uiInputC.def)

RETURN:		ax	- MouseReturnFlags
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardStartMoveCopy	method dynamic CwordBoardClass, 
					MSG_META_START_MOVE_COPY
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	InDoc	cxdx
;;;;;;;;

	tst	ds:[di].CBI_engine
	jz	exit

	;    Toggle the direction by default
	;

	mov	bx,DOWN
	cmp	ds:[di].CBI_direction,ACROSS
	je	setPoint
	mov	bx,ACROSS
setPoint:
	call	BoardSetSelectedWordFromPoint

exit:
	mov	ax, mask MRF_PROCESSED

	.leave
	ret
BoardStartMoveCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdLetters
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A letter was inputted from the keyboard.  Deal with it.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		cx	- character value
		dl	- CharFlags
		bp low	- ToggleState
		bp high	- scan code

RETURN:		CF	- SET if didn't handle

DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdLetters	proc	near
class	CwordBoardClass
	uses	ax,cx,dx,bp,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	CheckIfCwordAlpha
	jc	exit

	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ax, ds:[bx].CBI_cell
	mov	dx, ds:[bx].CBI_engine
	mov	bx, cx				; character
	call	BoardSetLetterInCell

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock

	BoardDrawHiLites
	call	GrDestroyState


handled:
	clc

exit:
	.leave
	ret
BoardKbdLetters	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdPunctuation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This is the central routine that causes the correct
		functionality corresponding to the inputted
		"functional-punctuation" marks.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		cx	- character value
		dl	- CharFlags
		bp low	- ToggleState
		bp high	- scan code

RETURN:		CF	- SET if didn't handled
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdPunctuation	proc	near
class	CwordBoardClass
	uses	ax,cx,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
EC <	call	CheckIfCwordPunct				>
EC <	ERROR_C	CHARACTER_IS_NOT_A_CWORD_PUNCTUATION		>
;;;;;;;;

	cmp	cx, C_PERIOD
	je	exit				; CF CLEAR if jump
	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ax, ds:[bx].CBI_cell
	mov	dx, ds:[bx].CBI_engine

	cmp	cx, C_MINUS
	jne	hintCell
	call	BoardClearCell
	jmp	finishAction
hintCell:
	call	BoardHintCell
finishAction:

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock

	BoardDrawHiLites
	call	GrDestroyState

handled:
	clc

exit:

	.leave
	ret
BoardKbdPunctuation	endp

if	0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdEnter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle the current direction

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
	
	Not using the Board's API.  Debatable as to use it or not in
	this instance.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/22/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdEnter	proc	near
class	CwordBoardClass
	uses	ax, di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	; Want to increment in the opposite direction as the
	; orientation of the word.
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	cx, DOWN
	cmp	ds:[di].CBI_direction, ACROSS		; curr direction
	je	gotDirection
	mov	cx, ACROSS
gotDirection:
	call	BoardIncrementSelectedWord

handled:
	clc
	
	.leave
	ret
BoardKbdEnter	endp

endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square down, and keep the current
		direction.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdDown	proc	near
class	CwordBoardClass
	uses	ax, cx, di, bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	GetInstanceDataPtrDSDI	CwordBoard_offset

	cmp	ds:[di].CBI_direction, DOWN
	jne	movingSelectedWord

	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock

	BoardDrawHiLites
	call	GrDestroyState

	cmp	dx, MS_MOVED
	jne	cantMove

handled:

	clc
	
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movingSelectedWord:
	mov	cx, DOWN
	call	BoardIncrementSelectedWord
	cmp	dx, MS_MOVED
	je	handled

cantMove:
	cmp	dx, MS_HOLE
	jne	userErr
	mov	bp, offset EngineGetNextCellTokenInColumn
	call	BoardSkipOverHoles
	cmp	dx, MS_MOVED
	je	handled

userErr:
	SoundUser	SST_WARNING
	jmp	handled

BoardKbdDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square up if the direction is DOWN.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdUp	proc	near
class	CwordBoardClass
	uses	ax, cx, di, bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	GetInstanceDataPtrDSDI	CwordBoard_offset

	cmp	ds:[di].CBI_direction, DOWN
	jne	movingSelectedWord

	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock

	BoardDrawHiLites
	call	GrDestroyState

	cmp	dx, MS_MOVED
	jne	cantMove

handled:
	clc
	
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movingSelectedWord:
	mov	cx, DOWN
	call	BoardDecrementSelectedWord
	cmp	dx, MS_MOVED
	je	handled

cantMove:
	cmp	dx, MS_HOLE
	jne	userErr
	mov	bp, offset EngineGetPrevCellTokenInColumn
	call	BoardSkipOverHoles
	cmp	dx, MS_MOVED
	je	handled

userErr:
	SoundUser	SST_WARNING
	jmp	handled

BoardKbdUp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square right if direction is ACROSS.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdRight	proc	near
class	CwordBoardClass
	uses	ax, cx, di, bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	GetInstanceDataPtrDSDI	CwordBoard_offset

	cmp	ds:[di].CBI_direction, ACROSS
	jne	movingSelectedWord

	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock

	BoardDrawHiLites
	call	GrDestroyState

	cmp	dx, MS_MOVED
	jne	cantMove

handled:
	clc

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movingSelectedWord:
	mov	cx, ACROSS
	call	BoardIncrementSelectedWord
	cmp	dx, MS_MOVED
	je	handled

cantMove:
	cmp	dx, MS_HOLE
	jne	userErr
	mov	bp, offset EngineGetNextCellTokenInRow
	call	BoardSkipOverHoles
	cmp	dx, MS_MOVED
	je	handled

userErr:
	SoundUser	SST_WARNING
	jmp	handled

BoardKbdRight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the selected square left if direction is ACROSS

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdLeft	proc	near
class	CwordBoardClass
	uses	ax, cx, di, bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	GetInstanceDataPtrDSDI	CwordBoard_offset

	cmp	ds:[di].CBI_direction, ACROSS
	jne	movingSelectedWord

	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock

	BoardDrawHiLites
	call	GrDestroyState

	cmp	dx, MS_MOVED
	jne	cantMove

handled:
	clc

	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
movingSelectedWord:
	mov	cx, ACROSS
	call	BoardDecrementSelectedWord
	cmp	dx, MS_MOVED
	je	handled

cantMove:
	cmp	dx, MS_HOLE
	jne	userErr
	mov	bp, offset EngineGetPrevCellTokenInRow
	call	BoardSkipOverHoles
	cmp	dx, MS_MOVED
	je	handled

userErr:
	SoundUser	SST_WARNING
	jmp	handled

BoardKbdLeft	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdShiftDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will toggle the direction.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdShiftDown	proc	near
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardToggleDirection

handled:
	clc

	.leave
	ret
BoardKbdShiftDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdShiftUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will toggle the direction.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdShiftUp	proc	near
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardToggleDirection

handled:
	clc

	.leave
	ret
BoardKbdShiftUp	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdShiftRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will toggle the direction.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdShiftRight	proc	near
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardToggleDirection

handled:
	clc

	.leave
	ret
BoardKbdShiftRight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdShiftLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves the selected square to the left and change the
		direction to ACROSS.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdShiftLeft	proc	near
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardToggleDirection

handled:
	clc

	.leave
	ret
BoardKbdShiftLeft	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the square.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdDelete	proc	near
class	CwordBoardClass
	uses	ax,cx,dx,di,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardGetGStateDI
	BoardEraseHiLites

	call	BoardClearSelectedCell

	BoardDrawHiLites
	call	GrDestroyState

handled:
	clc

	.leave
	ret
BoardKbdDelete	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdBackspace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there is a letter in the current square then
			delete it
		If the current square is empty then
			move back a square and delete letter there

		

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
	The normal functionality for the backspace key in overstike mode
	is to delete the character to the left of the currently highlighted
	char. However, in the crossword puzzle this makes it difficult to
	delete the last char in a word since the cursor remains on the last
	square after you type it. This solution, described in the synopsis
	is attempt to provide normal backspace functionality and allow
	easy deletion of the last char.
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdBackspace	proc	near
	class	 CwordBoardClass
	uses	ax,cx,dx,di,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx,ds:[di].CBI_engine
	mov	ax,ds:[di].CBI_cell

	call	BoardGetGStateDI
	BoardEraseHiLites

	call	EngineGetCellFlagsFar
	test	cl,mask CF_EMPTY or mask CF_HINTED
	jnz	decrementSelectedSquare

clearCell:
	call	BoardClearSelectedCell

redrawHighlights:
	BoardDrawHiLites
	call	GrDestroyState

handled:
	clc

	.leave
	ret

decrementSelectedSquare:
	push	cx					;cell flags
	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_DECREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock
	pop	cx					;cell flags

	;   If the original cell was a hinted letter then don't
	;   try to delete the letter that is now the selected square.
	;   It just seems like the right thing to do. The user 
	;   performed an ambiguous action, so don't destroy anything. If
	;   they really want to delete the letter at the newly selected
	;   square they can just hit backspace again.
	;

	test	cl,mask CF_HINTED
	jnz	redrawHighlights
	jmp	clearCell

BoardKbdBackspace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdSpace
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erases the selected square and moves the selected
		square forward one square.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	Nothing
SIDE EFFECTS:	None

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/23/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdSpace	proc	near
	class	CwordBoardClass
	uses	ax, di, cx, bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardGetGStateDI
	BoardEraseHiLites

	call	BoardClearSelectedCell

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	cx,ds:[bx].CBI_direction
	mov	ax, MSG_CWORD_BOARD_INCREMENT_SELECTED_SQUARE
	call	ObjCallInstanceNoLock

	BoardDrawHiLites
	call	GrDestroyState

handled:
	clc

	.leave
	ret
BoardKbdSpace	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardKbdPeriod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will toggle the direction.

CALLED BY:	BoardKbdChar
PASS:		*ds:si	- CwordBoardClass object
		dl	- CharFlags

RETURN:		CF	- CLEAR
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardKbdPeriod	proc	near
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Only deal with character on the press and not the release or
	; repeat-press.
	test	dl, mask CF_FIRST_PRESS
	jz	handled

	call	BoardToggleDirection

handled:
	clc

	.leave
	ret
BoardKbdPeriod	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetSelectedWordFromPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the direction to the passed type and set the selected 
		square to the be the one under the point. Move highlights
		as necessary.  If the destination is an invalid cell,
		eg. a hole, then, no action will be performed.  If the
		destination is the current cell, then will toggle word
		direction. 

CALLED BY:	BoardStartMoveCopy
		BoardStartSelect

PASS:		*ds:si - CwordBoard
		cx - x in document coords
		dx - y in document coords
		bx - DirectionType (Orientation of word)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetSelectedWordFromPoint		proc	far
class	CwordBoardClass
	uses	ax,bx,cx,dx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard dssi
	Assert	InDoc	cxdx
;;;;;;;;

	mov_tr	ax,cx				; x
	xchg	bx,dx				; y, direction
	call	BoardMapPointToCellTokenFar

	GetInstanceDataPtrDSDI	CwordBoard_offset
	cmp	cx, ds:[di].CBI_cell
	je	togglingDirection

	mov_tr	ax, cx				; dst cell
	mov	cx, dx				; orientation
	call	BoardMoveSelectedWord

exit:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
togglingDirection:
	call	BoardToggleDirection
	jmp	exit

BoardSetSelectedWordFromPoint		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetKeyboardMode
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
	srs	9/19/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSetKeyboardMode	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_SET_KEYBOARD_MODE
	.enter

	call	BoardSwitchToKeyboardMode

	.leave
	ret
BoardSetKeyboardMode		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSwitchToKeyboardMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch from ST_PEN mode to ST_KEYBOARD mode and
		set up the proper draw options and switching the
		look of the highlights

CALLED BY:	BoardKbdChar

PASS:		*ds:si - CwordBoardClass

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
	srs	8/24/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardSwitchToKeyboardMode		proc	near
	class	CwordBoardClass
	uses	bx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	cmp	ds:[di].CBI_system, ST_KEYBOARD
	jne	reallySwitch

done:
	.leave
	ret

reallySwitch:
	call	BoardGetGStateDI
	BoardEraseHiLites
	
	call	BoardGestureResetMacroProcFar

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ds:[bx].CBI_system, ST_KEYBOARD
	andnf	ds:[bx].CBI_drawOptions, not BOARD_INPUT_DRAW_OPTIONS	
	ornf	ds:[bx].CBI_drawOptions, BOARD_KEYBOARD_DRAW_OPTIONS

	BoardDrawHiLites
	call	GrDestroyState

	jmp	done

BoardSwitchToKeyboardMode		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardToggleDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggles the current direction, CBI_direction, and
		updates the highlight correspondingly.

CALLED BY:	Board routines

PASS:		*ds:si	- CwordBoardClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardToggleDirection	proc	near
	uses	di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	BoardGetGStateDI
	BoardEraseHiLites

	call	BoardToggleDirectionNoHiLite

	BoardDrawHiLites
	call	GrDestroyState

	.leave
	ret
BoardToggleDirection	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardToggleDirectionNoHiLite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggles the direction without drawing the highlights.

CALLED BY:	BoardToggleDirection

PASS:		*ds:si	- CwordBoardClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	7/28/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardToggleDirectionNoHiLite	proc	near
class	CwordBoardClass
	uses	ax,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	cx, DOWN
	cmp	ds:[di].CBI_direction, ACROSS
	je	gotDirection
	mov	cx, ACROSS
gotDirection:
	mov	ds:[di].CBI_direction, cx
	mov	ax,ds:[di].CBI_cell
	call	BoardMoveSelectedWord

	.leave
	ret
BoardToggleDirectionNoHiLite	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardClearSelectedCell
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the selected cell.  Ie., make it an empty cell.

CALLED BY:	BoardKbdDelete, BoardBackSpace

PASS:		*ds:si	- CwordBoardClass object
		^di	- GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	nothing

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 2/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardClearSelectedCell	proc	near
class	CwordBoardClass
	uses	ax,bx,dx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		di
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ax, ds:[bx].CBI_cell
	mov	dx, ds:[bx].CBI_engine
	call	BoardClearCell

	.leave
	ret
BoardClearSelectedCell	endp








CwordBoardKbdCode	ends




