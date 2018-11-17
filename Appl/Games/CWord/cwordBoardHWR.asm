COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Crossword
MODULE:		
FILE:		cwordBoardHWR.asm

AUTHOR:		Peter Trinh, Aug 29, 1994

ROUTINES:
	Name			Description
	----			-----------

	METHODS
	-------
	BoardNotifyWithDataBlock	Notification of possible ink data
	BoardGestureHandleInkChar	Handles character from ink input
	BoardGestureSetModeChar
	BoardGestureReplaceLastChar
	BoardGestureChar
	BoardGestureResetMacro
	BoardGestureSetModeChar
	BoardGestureReplaceLastChar

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardProcessTextQueue		Processes the TextQueue
	BoardCallActionRoutines
	BoardGestureProcessChar
	BoardDoActionLetter		Handles an ink-inputted letter.
	BoardDoActionMinus		Handles an ink-inputted minus sign.
	BoardDoActionPeriod		Handles an ink-inputted period.
	BoardDoActionQuestion		Handles an ink-inputted question mark.

	BoardWaitForVideoExcl
	BoardMapScreenBoundsToCellToken
	BoardMapScreenBoundsToCenterPtDC
	BoardSwitchToPenMode

	================================
	CwordGestureResetCode Segment
	================================

	PRIVATE/INTERNAL ROUTINES
	-------------------------
	BoardGestureResetMacroProc
	BoardGestureResetMacroProcFar


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/29/94   	Initial revision


DESCRIPTION:
	
	Board routines that interact with the HWR library.
		

	$Id: cwordBoardHWR.asm,v 1.1 97/04/04 15:14:04 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CwordHWRCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardNotifyWithDataBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If this is an ink notification, it does handwriting
		recognition on the data.  Then it sends the result
		from the HWR library to the Engine Module for further
		processing.

CALLED BY:	MSG_META_NOTIFY_WITH_DATA_BLOCK
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx:dx	= NotificationType
			cx - NT_manuf
			dx - NT_type
		^hbp	= SHARABLE data block having a "reference count"

RETURN:		nothing
DESTROYED:	ax,cx,dx,bp
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/10/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardNotifyWithDataBlock	method dynamic CwordBoardClass, 
					MSG_META_NOTIFY_WITH_DATA_BLOCK
	.enter

	tst	ds:[di].CBI_engine
	jz	exit

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	handle	bp
;;;;;;;;

	cmp	cx, MANUFACTURER_ID_GEOWORKS
	jne	exit

	cmp	dx, GWNT_INK
	je	inkStuff
	cmp	dx, GWNT_INK_GESTURE
	jne	exit

inkStuff:
	; Working in pen mode. But don't switch modes yet, because the
	; user may be working with the virtual keyboard and has
	; tapped on the screen just to select a square, not enter ink.
	; We want to keep the whole word highlighted which won't
	; happen if we switch modes.
	; Steve 9/19/94
;	call	BoardSwitchToPenMode

	; Create a TextQueueBlock to store result of HWR
	call	HwrCreateTextQueue	; handle to TextQueueBlock
	jc	exit			; jmp if didn't create

	; Recognize the ink points
	call	HwrDoHWR		
	jc	exit			; jmp if no recognition done

	; Pull individual TextInfo off queue and deal with them
	call	BoardProcessTextQueue

	call	HwrDestroyTextQueue

exit:
	; call superclass
	mov	bx, bp			; handle to ink data block
	call	MemIncRefCount		; must do this for SHARABLE blocks

	mov	ax, MSG_META_NOTIFY_WITH_DATA_BLOCK
	mov	di, offset CwordBoardClass
	mov	bp, bx			; handle to ink data block
	call	ObjCallSuperNoLock

	call	MemDecRefCount		; if count = 0, kernel will free

	.leave
EC <	Destroy	ax,cx,dx,bp					>
	ret
BoardNotifyWithDataBlock	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureHandleInkChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will handle the recognized character given its center
		point. 

CALLED BY:	MSG_CWORD_BOARD_GESTURE_HANDLE_INK_CHAR
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		ss:[bp]	= Rectangle (bounds in screen coord)
		cx	= character

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureHandleInkChar	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_GESTURE_HANDLE_INK_CHAR
	.enter

	tst	ds:[di].CBI_engine
	jz	exit

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	tst	ds:[di].CBI_engine
	jz	exit

	call	BoardGestureProcessChar

exit:
	.leave
	ret
BoardGestureHandleInkChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called after receiving a GT_CHAR from
		a call to HWRR_DO_GESTURE_RECOGNITION.  It basically
		sets up the lastCell and currModeChar correctly
		and then stores the new character in the cell
		corresponding to the gesture bounds.

CALLED BY:	MSG_CWORD_BOARD_GESTURE_CHAR
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	= new character
		ss:[bp]	= Rectangle (gesture bounds in screen coord)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureChar	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_GESTURE_CHAR
	uses	ax
	.enter

	tst	ds:[di].CBI_engine
	jz	exit

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	CheckIfHWRChar
	jc	exit			; jmp if unknown character

	mov_tr	ax, cx			; new character
	call	BoardMapScreenBoundsToCellToken
	mov	ds:[di].CBI_lastCell, cx
	clr	ds:[di].CBI_currModeChar
	mov_tr	cx, ax			; new character

	call	BoardGestureProcessChar

exit:
	.leave
	ret
BoardGestureChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureResetMacro
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is sent to abort the current macro mode
		started.  Basically will update the instance data
		lastCell and currModeChar to reflect this abortion.

CALLED BY:	MSG_CWORD_BOARD_GESTURE_RESET_MACRO
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureResetMacro	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_GESTURE_RESET_MACRO
	.enter

	tst	ds:[di].CBI_engine
	jz	exit

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	BoardGestureResetMacroProcFar

exit:
	.leave
	ret
BoardGestureResetMacro	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureSetModeChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the instance data with the appropriate value so
		that we can handle the call to BoardGestureReplaceLastChar.
		This is part of the mechanism to support Graffiti.
		This routine is called after one does a call to
		HWRR_DO_GESTURE_RECOGNITION and the return GestureType
		is a GT_MODE_CHAR.  The value returned in dx should be
		passed here.

CALLED BY:	MSG_CWORD_BOARD_GESTURE_SET_MODE_CHAR
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	= character returned along with GT_MODE_CHAR
			  after the call to HWRR_DO_GESTURE_RECOGNITION	
		ss:[bp]	= Rectangle (gesture bounds in screen coord)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureSetModeChar	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_GESTURE_SET_MODE_CHAR
	uses	ax,cx,dx
	.enter

	tst	ds:[di].CBI_engine
	jz	bail

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

EC <	tst	cx						>
EC <	ERROR_Z	BOARD_UNACCEPTABLE_VALUE_FOR_MODE_CHAR		>

	; In "pen" mode now.
	mov	bx, di				; instance data ptr
	call	BoardGetGStateDI
	BoardEraseHiLites

	; Now find the cell token corresponding to the bound.
	; If the user is drawing a mode char over a
	; "non-selectable-cell", eg a hole, then we want to abort the
	; current macro.

	push	cx				; mode char
	call	BoardMapScreenBoundsToCellToken
	mov_tr	ax, cx				; new cell
	mov	dx, ds:[bx].CBI_engine
	call	EngineGetCellFlagsFar		; cl - cellflags
	test	cl, BOARD_NOT_SELECTABLE_CELL
	pop	cx				; mode char
	jnz	abortModeChar

	mov_tr	ds:[bx].CBI_lastCell, ax	; new cell
	mov	ds:[bx].CBI_currModeChar, cx	; mode char

	call	BoardDrawModeCharCellFar

exit:
	call	GrDestroyState
bail:
	.leave
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
abortModeChar:
	call	BoardGestureResetMacroProcFar
	jmp	exit

BoardGestureSetModeChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureReplaceLastChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will replace the "last char" with this new char.
		Depending on what is stored in CBI_currModeChar,
		different actions will be taken with the following
		assumptions.  If CBI_currModeChar is null, then we
		assume that we are not in any Graffiti Mode, and the
		last character was actually stored in the cell
		designated by CBI_lastCell.  The only instances when
		this is called and CBI_currModeChar is NULL are as
		follows: 

		When the user enters a character, and adds a
			post-character modifier, like an accent.
		Or when the user enters a mode modifier like to enter
			punctuation.

CALLED BY:	MSG_CWORD_BOARD_GESTURE_REPLACE_LAST_CHAR
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #

		cx	= new character
		ss:[bp]	= Rectangle (gesture bounds screen coord)

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	if lastCell is valid {
		if currModeChar == 0 {
			replace the char at lastCell with new char;
			redraw the cell;
		}
		else {
			currModeChar = 0;
			redraw lastCell;
			get new cell correponding to bound;
			lastCell = newCell;
			store new char in newCell;
			redraw newCell;
		}
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 4/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureReplaceLastChar	method dynamic CwordBoardClass, 
				MSG_CWORD_BOARD_GESTURE_REPLACE_LAST_CHAR
	uses	ax, dx
	.enter

	tst	ds:[di].CBI_engine
	jz	exit

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	cmp	ds:[di].CBI_lastCell, INVALID_CELL_TOKEN
	je	exit

	GetInstanceDataPtrDSBX	CwordBoard_offset
	tst	ds:[bx].CBI_currModeChar
	jz	storeCharAndRedrawAtNewBounds

	; We have a Mode Char on the screen somewhere.  Clear our
	; currModeChar.  Redraw the cell that the Mode Char is at, and
	; set the character in the new cell and redraw it.
	clr	ds:[bx].CBI_currModeChar

	mov	ax, ds:[bx].CBI_lastCell
	mov	dx, ds:[bx].CBI_engine
	call	BoardGetGStateDI
	BoardEraseHiLites
	call	BoardRedrawCellFar		; redraw the lastCell
	call	GrDestroyState

	mov_tr	ax, cx				; user letter
	call	BoardMapScreenBoundsToCellToken
	mov	ds:[bx].CBI_lastCell, cx	; update lastCell
	mov_tr	cx, ax				; user letter
	
storeCharAndRedrawAtNewBounds:
	call	BoardGestureProcessCharFar
	
exit:
	.leave
	ret
BoardGestureReplaceLastChar	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardProcessTextQueue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will go through the TextQueue and decide which routine
		to call to handle each TextInfo item in the queue.
		If this routine is called, it implies that we're
		getting ink input.  So will assume working on a Pen
		system, and draw highlights accordingly.

CALLED BY:	BoardNotifyWithDataBlock

PASS:		*ds:si	- CwordBoardClass object
		bx	- handle to TextQueueBlock

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	Repeat Until queue is empty {
		Extract character from the queue.
		Look up character in a table.
		Index into ActionRoutineTable to find the correct routine.
		Call the routine
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	5/17/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardProcessTextQueue	proc	near
	uses	ax,bx,cx,dx,di,bp,es
	.enter

;;; Verify argument(s)
	Assert	TextQueueBlock	bx
	Assert	ObjectBoard	dssi
;;;;;;;;

	; Pseudo-caching GState - could possibly have multiple
	; character informations in the TextQueue and will eventually
	; need to "draw" them.  Don't want to always create a new
	; GState for each "drawing".
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp				; ^h GState
	BoardEraseHiLites			; Dealing in Pen mode

	; Create a TextInfo structure on the stack to pass.
	BoardAllocStructOnStack		TextInfo

	; Extract and process each element from the TextQueue
repeat:
	; init buffer for EC
EC <	ClearBufferForEC	ssbp, TextInfo			>

	call	HwrGetInfoFromQueue		; on the stack
	jcxz	finish				; bail if no elements

	call	BoardWaitForVideoExcl
	mov	dx, di				; ^h GState
	call	BoardCallActionRoutines
	cmp	cx,1				; last char?
	jne	repeat				; jmp if not

finish:

	BoardDeAllocStructOnStack	TextInfo

	BoardDrawHiLites
	call	GrDestroyState

	.leave
	ret

BoardProcessTextQueue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCallActionRoutines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the TextInfo and the GState, will call the
		corresponding action routines to the character.

CALLED BY:	BoardProcessTextQueue, BoardGestureHandleInkChar

PASS:		*ds:si	- CwordBoardClass object
		ss:bp	- TextInfo ptr
		^hdx	- GState

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 1/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCallActionRoutines	proc	near
	uses	ax,cx,di,es
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	TextInfo	ssbp
	Assert	gstate		dx
;;;;;;;;

	; Setup for switch-table lookup
	segmov	es, cs, di

	; Determine what to do with the character and its center point
	mov	di, offset cs:BNWDBswitchTable		; ptr to table
	mov	cx, size BNWDBswitchTable
	mov	ax, ss:[bp].TI_character	
	Assert	e	ah, 0				; byte-sized
	Assert	okForRepScasb
	repne scasb
	mov	ax, offset cs:BoardDoActionLetter
	jne	sendMessage				; not in table

	; Not letters, so is special characters.
	mov	di, cx					; rep count-down
	shl	di					; word-sized
	mov	ax, cs:[ActionRoutineTable][di] 	; message no

sendMessage:
	call	ax

	.leave
	ret
BoardCallActionRoutines	endp


; Jump tables to handle special characters
BNWDBswitchTable Chars 	\
	C_PERIOD,			; selecting a square
	C_QUESTION_MARK,		; asking for a hint
	C_MINUS,			; deleting a square
	C_SPACE				; deleting a square

; Table of near routines 
ActionRoutineTable	nptr.near	\
	BoardDoActionMinus,
	BoardDoActionMinus,
	BoardDoActionQuestion,
	BoardDoActionPeriod

CheckHack < length BNWDBswitchTable eq length ActionRoutineTable >



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureProcessChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the bounds and the character, will do the
		appropriate action, such as setting the cell.  Part of
		the mechanism to handle ink.

CALLED BY:	BoardGestureHandleInkChar, BoardGestureChar
		

PASS:		*ds:si	- CwordBoardClass object
		ss:[bp]	- Rectangle (gesture bounds)
		cx	- character

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureProcessChar	proc	near
class	CwordBoardClass
	uses	ax,bx,dx,di,bp
	.enter


	call	CheckIfHWRChar
	jc	exit				; jmp if not accepted char

	call	BoardGetGStateDI
	BoardEraseHiLites
	
	call	BoardMapScreenBoundsToCenterPtDC

	BoardAllocStructOnStack		TextInfo

	mov_tr	ss:[bp].TI_center.P_x, ax
	mov	ss:[bp].TI_center.P_y, bx
	mov	ss:[bp].TI_character, cx

	BoardEraseHiLites
	mov	dx, di			; ^h GState
	call	BoardCallActionRoutines
	BoardDrawHiLites

	BoardDeAllocStructOnStack	TextInfo

	call	GrDestroyState

exit:
	.leave
	ret
BoardGestureProcessChar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureProcessCharFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far version of BoardGestureProcessChar

CALLED BY:	BoardGestureReplaceLastChar
		
PASS:		*ds:si	- CwordBoardClass object
		ss:[bp]	- Rectangle (gesture bounds)
		cx	- character

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureProcessCharFar	proc	far
	.enter

	call	BoardGestureProcessChar

	.leave
	ret
BoardGestureProcessCharFar	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDoActionLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extracts the point from the TextInfo structure,
		and finds the corresponding cell.  Then attempt to
		store the letter into the cell.  If successful, make
		the cell the selected cell. 

CALLED BY:	BoardProcessTextQueue

PASS:		*ds:si	- CwordBoardClass
		ss:bp	- TextInfo
		dx	- GState Handle

RETURN:		CF	- SET if didn't store letter
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDoActionLetter	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,di
	.enter

;;; Verify argument(s)
	Assert	gstate	dx
	Assert	TextInfo	ssbp
	Assert	ObjectBoard 	dssi
;;;;;;;;

	; Map the document coordinate to the corresponding cellToken
	mov	ax, ss:[bp].TI_center.P_x
	mov	bx, ss:[bp].TI_center.P_y
	call	BoardMapPointToCellTokenFar

	mov_tr	ax, cx				; cellToken
	mov	bx, ss:[bp].TI_character
	push	dx				; ^hGState
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine
	pop	di				; ^hGState
	call	BoardSetLetterInCell

	.leave
	ret
BoardDoActionLetter	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDoActionMinus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extracts the point from the TextInfo structure,
		and finds the corresponding cell.  Then attempt to
		delete the cell.  If successful, make the cell the
		selected cell.  

CALLED BY:	BoardProcessTextQueue, BoardGestureHandleInkChar

PASS:		*ds:si	- CwordBoardClass
		ss:bp	- TextInfo
		^hdx	- GState

RETURN:		CF	- SET if the cell was cleared
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDoActionMinus	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,di
	.enter

;;; Verify argument(s)
	Assert	gstate	dx
	Assert	TextInfo	ssbp
	Assert	ObjectBoard 	dssi
;;;;;;;;

	; Map the document coordinate to the corresponding cellToken
	mov	ax, ss:[bp].TI_center.P_x
	mov	bx, ss:[bp].TI_center.P_y
	call	BoardMapPointToCellTokenFar

	mov	ax, cx				; cellToken
	push	dx				; ^hGState
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine
	pop	di				; ^hGState
	call	BoardClearCell

	.leave
	ret
BoardDoActionMinus	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDoActionPeriod
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extracts the point from the TextInfo structure,
		and finds the corresponding cell.  Then make that cell
		the selected square.

CALLED BY:	BoardProcessTextQueue, BoardGestureHandleInkChar

PASS:		*ds:si	- CwordBoardClass object
		ss:bp	- TextInfo
		dx	- GState Handle

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDoActionPeriod	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,di
	.enter

;;; Verify argument(s)
	Assert	gstate	dx
	Assert	TextInfo	ssbp
	Assert	ObjectBoard 	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	cmp	ds:[di].CBI_system, ST_KEYBOARD
	je	keyboardMode

	; Map the document coordinate to the corresponding cellToken
	mov	ax, ss:[bp].TI_center.P_x
	mov	bx, ss:[bp].TI_center.P_y
	call	BoardMapPointToCellTokenFar


	cmp	cx, ds:[di].CBI_cell
	je	exit
	mov_tr	ax, cx				; dst cell
	call	BoardMoveSelectedSquare

exit:
	.leave
	ret

keyboardMode:
	;    Do this crap so that it can toggle the direction.
	;    This call unfortunately causes the kbd resource to	
	;    be brought into memory. But tough, the user is
	;    a bonehead and is using the virtual keyboard on
	;    a pen system.
	;

	mov	cx, ss:[bp].TI_center.P_x
	mov	dx, ss:[bp].TI_center.P_y
	mov	bx, ds:[di].CBI_direction
	call	BoardSetSelectedWordFromPoint
	jmp	exit

BoardDoActionPeriod	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDoActionQuestion
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Extracts the point from the TextInfo structure,
		and finds the corresponding cell.  Then attempt to
		make the cell HINTED.  If successful, make the cell
		the selected cell.  Making HINTED means giving the
		correct user solution.

CALLED BY:	BoardProcessTextQueue, BoardGestureHandleInkChar

PASS:		*ds:si	- CwordBoardClass object
		ss:bp	- TextInfo
		dx	- GState Handle

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	6/ 6/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDoActionQuestion	proc	near
class	CwordBoardClass

	uses	ax,bx,cx,dx,di
	.enter

;;; Verify argument(s)
	Assert	gstate	dx
	Assert	TextInfo	ssbp
	Assert	ObjectBoard 	dssi
;;;;;;;;

	; Map the document coordinate to the corresponding cellToken
	mov	ax, ss:[bp].TI_center.P_x
	mov	bx, ss:[bp].TI_center.P_y
	call	BoardMapPointToCellTokenFar

	mov_tr	ax, cx				; cellToken
	push	dx				; ^hGState
	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx, ds:[di].CBI_engine
	pop	di				; ^hGState
	call	BoardHintCell

	.leave
	ret
BoardDoActionQuestion	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardWaitForVideoExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Don't start drawing until no one has the video exclusive. 
		This limits the horrible "most of screen invalidate" 
		problem when we try to draw a character but the
		ink code has the video excl

CALLED BY:	BoardProcessTextQueue

PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	7/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardWaitForVideoExcl		proc	near
	uses	ax,bx,si,ds,di
	.enter

	mov	ax,GDDT_VIDEO
	call	GeodeGetDefaultDriver
	mov	bx,ax
	call	GeodeInfoDriver
tryAgain:
	mov	di,DR_VID_GET_EXCLUSIVE
	call	ds:[si][DIS_strategy]
	tst 	bx				;gstate with excl
	jnz	sleepALittle

	.leave
	ret

sleepALittle:
	mov	ax,5				;chosen arbitarily
	call	TimerSleep
	jmp	tryAgain 

BoardWaitForVideoExcl		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMapScreenBoundsToCellToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the rectangular bounds in screen coordinate
		(eg. ink points) will map them to the corresponding
		CellToken. 

CALLED BY:	BoardGestureSetModeChar, BoardGestureReplaceLastChar,
		BoardGestureChar 

PASS:		*ds:si	- CwordBoardClass object
		ss:[bp]	- Rectangle (screen coordinates)

RETURN:		cx	- CellTokenType

DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 4/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMapScreenBoundsToCellToken	proc	far
	uses	ax,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	BoardMapScreenBoundsToCenterPtDC
	call	BoardMapPointToCellTokenFar

	.leave
	ret
BoardMapScreenBoundsToCellToken	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardMapScreenBoundsToCenterPtDC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given the screen bounds, will give the center point of
		the bounds in document coordinate

CALLED BY:	

PASS:		ss:[bp]	- Rectangle (screen coordinates)

RETURN:		ax	- x
		bx	- y

DESTROYED:	nothing
SIDE EFFECTS:	none


PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 5/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardMapScreenBoundsToCenterPtDC	proc	near
	uses	cx,dx
	.enter

	mov	ax, ss:[bp].R_left
	mov	bx, ss:[bp].R_top
	mov	cx, ss:[bp].R_right
	mov	dx, ss:[bp].R_bottom

	call	HwrZeroOutNegative	
	call	HwrFindCenterOfBounds

	push	ds:[LMBH_handle]		; got to fixup ds
	call	HwrUntransformPoint
	mov	cx, bx				; y-coord
	pop	bx				; handle of current ds seg
	call	MemDerefDS
	mov	bx, cx				; y-coord

	.leave
	ret
BoardMapScreenBoundsToCenterPtDC	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSetPenMode
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
BoardSetPenMode	method dynamic CwordBoardClass, 
						MSG_CWORD_BOARD_SET_PEN_MODE
	.enter

	call	BoardSwitchToPenMode

	.leave
	ret
BoardSetPenMode		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardSwitchToPenMode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch from ST_PEN mode to ST_KEYBOARD mode and
		set up the proper draw options and switching the
		look of the highlights

CALLED BY:	Utility

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
BoardSwitchToPenMode		proc	near
	class	CwordBoardClass
	uses	bx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	cmp	ds:[di].CBI_system, ST_PEN
	jne	reallySwitch

done:
	.leave
	ret

reallySwitch:
	call	BoardGetGStateDI

	BoardEraseHiLites
	
	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	ds:[bx].CBI_system, ST_PEN
	andnf	ds:[bx].CBI_drawOptions, not BOARD_INPUT_DRAW_OPTIONS	
	ornf	ds:[bx].CBI_drawOptions, BOARD_PEN_DRAW_OPTIONS

	BoardDrawHiLites

	call	GrDestroyState
	jmp	done

BoardSwitchToPenMode		endp






CwordHWRCode	ends




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;	This segment should be the same as the one in board.asm.  I
;	moved these routines from the board.asm because functionally
;	it belongs in this file; but, there a many calls from the
;	CwordCode segment, so I kept these routines in the same segment. 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


CwordCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureResetMacroProc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This routine is called to abort the current macro mode
		started.  Basically will update the instance data
		lastCell and currModeChar to reflect this abortion.

CALLED:		BoardZoomIn, BoardZoomOut,
		BoardMoveSelectedSquareCommon, BoardVerify,
		BoardLostFocusTargetExcl

PASS:		*ds:si	- CwordBoardClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

	if lastCell is valid {
		if currModeChar != 0 {
			currModeChar = 0;
			redraw lastCell;
		}
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/ 9/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureResetMacroProc	proc	near
class	CwordBoardClass
	uses	ax,dx,si,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	cmp	ds:[di].CBI_system, ST_PEN
	jne	exit
	cmp	ds:[di].CBI_lastCell, INVALID_CELL_TOKEN
	je	exit
	tst	ds:[di].CBI_currModeChar
	jz	exit

	call	HwrResetMacro
	jc	exit				; jmp if err in HwrResetMacro
	tst	dx				; jmp if no macro in
	jz	exit				; progress  

	GetInstanceDataPtrDSDI	CwordBoard_offset
	clr	ds:[di].CBI_currModeChar
	mov	ax, ds:[di].CBI_lastCell
	mov	dx, ds:[di].CBI_engine
	tst	dx
	jz	exit
	call	BoardGetGStateDI
	call	BoardRedrawCellFar
	call	GrDestroyState

exit:
	.leave
	ret
BoardGestureResetMacroProc	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGestureResetMacroProcFar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Far version of BoardGestureResetMacroProc

CALLED BY:	BoardGestureResetMacro

PASS:		*ds:si	- CwordBoardClass object

RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PT	8/29/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGestureResetMacroProcFar	proc	far
	.enter

	call	BoardGestureResetMacroProc

	.leave
	ret
BoardGestureResetMacroProcFar	endp



CwordCode	ends


