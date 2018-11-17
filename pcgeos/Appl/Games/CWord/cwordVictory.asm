COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		cwordVictory.asm

AUTHOR:		Steve Scholl, Sep 26, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Steve	9/26/94		Initial revision


DESCRIPTION:
	
		

	$Id: cwordVictory.asm,v 1.1 97/04/04 15:14:22 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; State for the random-number generator. This beast comes from the
; BSD random-number generator, which is supposed to be random in all 31
; bits it produces...
;
RAND_DEG	equ	31
RAND_SEP	equ	3
RAND_MULT	equ	1103515245
RAND_ADD	equ	12345

idata	segment


frontPtr	nptr.dword	randTbl[(RAND_SEP+1)*dword]
rearPtr		nptr.dword	randTbl[1*dword]
endPtr		nptr.dword	randTbl[(RAND_DEG+1)*dword]


randTbl		dword	3,	; generator type
			0x9a319039, 0x32d9c024, 0x9b663182, 0x5da1f342, 
			0xde3b81e0, 0xdf0a6fb5, 0xf103bc02, 0x48f340fb, 
			0x7449e56b, 0xbeb1dbb0, 0xab5c5918, 0x946554fd, 
			0x8c2e680f, 0xeb3d799f, 0xb11ee0b7, 0x2d436b86, 
			0xda672e2a, 0x1588ca88, 0xe369735d, 0x904f35f7, 
			0xd7158fd6, 0x6fa6f051, 0x616e6b96, 0xac94efdc, 
			0x36413f93, 0xc622c298, 0xf5a42ab8, 0x8a88d77b, 
				    0xf5ad9d0e, 0x8999220b, 0x27fb47b9



idata	ends

CwordVictoryCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameSeedRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Seed the random number generator, using 128 bytes of state

CALLED BY:	
PASS:		dx:ax	= initial seed

RETURN:		nothing

DESTROYED:	dx, ax

PSEUDO CODE/STRATEGY:
		state[0] = seed;
		for (i = 1; i < RAND_DEG; i++) {
			state[i] = 1103515245*state[i-1] + 12345;
		}
		frontPtr = &state[RAND_SEP];
		rearPtr = &state[0];
		for (i = 0; i < 10*RAND_DEG; i++) {
			GameRandom();
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	4/14/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameSeedRandom	proc	far
		uses	si, di, bx, cx, ds
		.enter
		mov	bx, handle dgroup	;Do this so there is no segment
		call	MemDerefDS		; relocs to dgroup (so the
						; dgroup resource is 
						; discardable on XIP platforms)

		mov	di, offset (randTbl[1*dword])
		mov	cx, RAND_DEG-1
seedLoop:
		mov	({dword}ds:[di]).low, ax
		mov	({dword}ds:[di]).high, dx
		add	di, size dword

	;
	; Perform a 32-bit unsigned multiply by RAND_MULT, leaving the result
	; in si:bx:
	;
	; 			h	mh	ml	l
	;ax*low(RAND_MULT)			x	x
	;dx*low(RAND_MULT)		x	x
	;ax*high(RAND_MULT)		x	x
	;dx*high(RAND_MULT)	x	x
	;
	; The highest two words are discarded, which means we don't even have
	; to multiply dx by high(RAND_MULT).
	; 
		push	ax
		push	dx
		mov	dx, RAND_MULT AND 0xffff
		mul	dx
		xchg	bx, ax		; bx <- low(result)
		mov	si, dx		; si <- partial high(result)

		pop	ax		; ax <- original dx
		mov	dx, RAND_MULT AND 0xffff
		mul	dx
		add	si, ax		; high(result) += low(dx*low(RAND_MULT))

		pop	ax		; ax <- original ax
		mov	dx, RAND_MULT / 65536
		mul	dx
		add	si, ax		; high(result)+=low(high(RAND_MULT)*ax)
	;
	; Place result in the proper registers and add in the additive factor.
	; 
		mov	dx, si
		mov	ax, bx
		add	ax, RAND_ADD
		adc	dx, 0
		loop	seedLoop
	;
	; Store the final result.
	; 
		mov	({dword}ds:[di]).low, ax
		mov	({dword}ds:[di]).high, dx

	;
	; Initialize the pointers.
	; 
		mov	ds:[frontPtr], offset (randTbl[(RAND_SEP+1)*dword])
		mov	ds:[rearPtr], offset (randTbl[1*dword])
		
	;
	; Now randomize the state according to the degree of the
	; polynomial we're using.
	; 
		mov	cx, 10*RAND_DEG
initLoop:
		mov	dx, 0xffff
		call	GameRandom
		loop	initLoop
		.leave
		ret
GameSeedRandom	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GameRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return a random number

CALLED BY:	GLOBAL

PASS:		dx	= max for returned value

RETURN:		dx	= number between 0 and max-1

DESTROYED:	nothing 

PSEUDO CODE/STRATEGY:
		We assume we're using a type 3 random number generator here,
		so the code looks like this:
			*frontPtr += *rearPtr;
			i = (*frontPtr >> 1)&0x7fffffff;
			if (++frontPtr >= endPtr) {
				frontPtr = state;
				rearPtr += 1;
			} else if (++rearPtr >= endPtr) {
				rearPtr = state;
			}
			
			return(i % DL);

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GameRandom	proc	far
		uses	ds, cx, si, di, ax, bx
		.enter
		mov	bx, handle dgroup	;Do this so there is no segment
		call	MemDerefDS		; relocs to dgroup (so the
						; dgroup resource is 
						; discardable on XIP platforms)
		mov	si, ds:[frontPtr]
		mov	di, ds:[rearPtr]
		mov	ax, ({dword}ds:[di]).low
		mov	cx, ({dword}ds:[di]).high
		add	ax, ({dword}ds:[si]).low
		adc	cx, ({dword}ds:[si]).high
		mov	({dword}ds:[si]).low, ax
		mov	({dword}ds:[si]).high, cx
		
		shr	cx
		rcr	ax
		
		add	si, size dword
		add	di, size dword
		cmp	si, ds:[endPtr]
		jb	adjustRear
		mov	si, offset (randTbl[1*dword])
		jmp	storePtrs
adjustRear:
		cmp	di, ds:[endPtr]
		jb	storePtrs
		mov	di, offset (randTbl[1*dword])
storePtrs:
		mov	ds:[frontPtr], si
		mov	ds:[rearPtr], di

		mov	cx, dx		; ignore high word, to avoid painful
					;  divide. Since all the bits are
					;  random, we just make do with the
					;  low sixteen, thereby avoiding
					;  quotient-too-large faults
		clr	dx
		div	cx
		.leave
		ret
GameRandom	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardPlaySound
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Play a sound.

CALLED BY:	BoardVerify, BoardVerifyWord
PASS:		nothing
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
		Call WavPlayInitSound for the sound

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	DH	3/15/2000   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
; These constants match those used in the [sound] section.
SOUND_CWORD_CHECK_OK	equ	0

BoardPlaySound	proc near
        uses   ax, bx, cx, dx, di, es

soundToken	local	GeodeToken
	.enter

	; Retrieve our GeodeToken.
	segmov	es, ss, ax
	lea	di, soundToken
	mov	bx, handle 0		; bx <- app geode token
	mov	ax, GGIT_TOKEN_ID
	call	GeodeGetInfo

	; Play the sound.
	mov	bx, SOUND_CWORD_CHECK_OK
	mov	cx, es
	mov	dx, di
	call	WavPlayInitSound

	.leave
	ret
BoardPlaySound	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVerify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify all the user letters in non-empty cells and
		give feedback of the results to the user.

		Also reset HWR macro if in PEN mode.
		
CALLED BY:	MSG_CWORD_BOARD_VERIFY
PASS:		*ds:si	= CwordBoardClass object
		ds:di	= CwordBoardClass instance data
		ds:bx	= CwordBoardClass object (same as *ds:si)
		es 	= segment of CwordBoardClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JL	7/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVerify	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_VERIFY
	uses	ax, cx, dx, bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	cmp	ds:[di].CBI_system, ST_PEN
	jne	dontReset
	call	BoardGestureResetMacroProcFar
dontReset:

	call	BoardPlaySound

	mov	dx,ds:[di].CBI_engine
	tst	dx
	jz	done
	call	EngineCheckForAllCellsCorrect
	jnc	success

	call	EngineVerifyAllCells
	call	BoardAnimateVerify

	call	EngineCheckForAllCellsFilled
	jnc	allFilled

enableDisable:
	call	CwordEnableDisableClearXSquares

done:
	.leave
	ret


allFilled:
	;    If no wrong cells on screen, then do something about it
	;

	call	BoardDetermineIfWrongCellOnScreen
	jc	enableDisable
	call	BoardGetWrongCellOnScreen	
	jmp	enableDisable

success:
	call	BoardFoolinAround

	mov	bx,handle CompletedInteraction
	mov	si,offset CompletedInteraction
	mov	ax,MSG_GEN_INTERACTION_INITIATE
	mov	di,mask MF_FIXUP_DS
	call	ObjMessage

	jmp	done

BoardVerify	endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardFoolinAround
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do cool stuff to celebrate the completion of the puzzle

CALLED BY:	BoardVerify

PASS:		*ds:si - Board

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
	srs	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardFoolinAround		proc	near
	uses	ax,cx,dx,bp,es,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	call	TimerGetCount
	call	GameSeedRandom

	mov	bx,handle CwordStrings
	call	MemLock
	mov	es,ax

	mov	dx,length coolTextOffsets
	call	GameRandom
	shl	dx				;word size table
	add	dx,offset coolTextOffsets
	mov	bx,dx				;offset into table
	mov	bx,cs:[bx]			;chunk of text from table
	mov	bx,es:[bx]			;offset of text from chunk

	call	BoardFadeInCoolString

	mov	bx,handle CwordStrings
	call	MemUnlock

	call	BoardDoShootingStars

	call	BoardFadeOutScreen

	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	.leave
	ret

coolTextOffsets	word \
	offset	CoolText,
	offset	FinisText,
	offset	RadText,
	offset	DoneText,
	offset	YesText

BoardFoolinAround		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEnumerateCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call call back routine for each cell. Process left to right
		on first row then right to left and so on.

CALLED BY:	UTILITY

PASS:		*ds:si - Board
		di - offset to near routine in segment cs
		cx,bp - data to pass to call back

		PASSED to call back
			*ds:si - Board
			dx - engine token
			bx - cell token
			cx,bp - data passed to BoardEnumerateCells

RETURN:		
		carry clear - enumerated all cells
			ax - destroyed
		carry set - enumeration stopped
			ax - cell number that stopped

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		call back routine returning carry stops enumeration

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEnumerateCells		proc	near
	class	CwordBoardClass
	uses	dx,bx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	dx,ds:[bx].CBI_engine

	clr	bx					;initial
makeCall:
	call	di
	mov	ax,bx					;cell token
	jc	done

leftToRight:
	call	EngineGetNextCellTokenInRowFar
	cmp	bx,ENGINE_GRID_EDGE
	je	rightToLeftStart
	call	di
	mov	ax,bx					;cell token
	jc	done
	jmp	leftToRight

rightToLeftStart:
	call	EngineGetNextCellTokenInColumnFar
	cmp	bx,ENGINE_GRID_EDGE
	je	doneNoTermination
	call	di
	mov	ax,bx					;cell token
	jc	done

rightToLeft:
	call	EngineGetPrevCellTokenInRowFar
	cmp	bx,ENGINE_GRID_EDGE
	je	leftToRightStart
	call	di
	mov	ax,bx					;cell token
	jc	done
	jmp	rightToLeft

done:
	.leave
	ret

doneNoTermination:
	clc
	jmp	done

leftToRightStart:
	call	EngineGetNextCellTokenInColumnFar
	cmp	bx,ENGINE_GRID_EDGE
	je	doneNoTermination
	jmp	makeCall	

BoardEnumerateCells		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardEnumerateCellsInWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call call back routine for each cell in the word

CALLED BY:	UTILITY

PASS:		*ds:si - Board
		bx - Direction
		ax - CellToken
		di - offset to near routine in segment cs
		cx,bp - data to pass to call back

		PASSED to call back
			*ds:si - Board
			dx - engine token
			bx - cell token
			cx,bp - data passed to BoardEnumerateCellsInWord

RETURN:		
		carry clear - enumerated all cells
			ax - destroyed
		carry set - enumeration stopped
			ax - cell number that stopped

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		call back routine returning carry stops enumeration

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardEnumerateCellsInWord		proc	near
	class	CwordBoardClass
	uses	cx,dx,bx

passedBP	local	word	push bp
passedCX	local	word	push cx
lastToken	local	word	

	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	cx,bx					;direction
	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	dx,ds:[bx].CBI_engine
	call	BoardMapWordToFirstNLastCellsFar
	mov	lastToken,bx
	mov	bx,ax					;first cell

makeCall:
	push	bp,cx					;locals, direction
	mov	cx,passedCX
	mov	bp,passedBP
	call	di
	mov	ax,bx					;current cell
	pop	bp,cx					;locals, direction
	jc	doneWithTermination
	cmp	ax,lastToken
	je	doneNoTermination

	cmp	cx, ACROSS
	je	nextRow
	call	EngineGetNextCellTokenInColumnFar
	jmp	makeCall

doneNoTermination:
	clc
done:
	.leave
	ret

doneWithTermination:
	stc
	jmp	done

nextRow:
	call	EngineGetNextCellTokenInRowFar
	mov	ax,bx					;next cell
	jmp	makeCall

BoardEnumerateCellsInWord		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetWrongCellOnScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a wrong cell and make sure it is visible and select it.

CALLED BY:	BoardVerify

PASS:		
		*ds:si - Board

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
	srs	9/20/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetWrongCellOnScreen		proc	near
	class	CwordBoardClass
	uses	di,dx
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI	CwordBoard_offset
	mov	dx,ds:[di].CBI_engine
	call	EngineFindFirstWrongCell
	jnc	done
	call	BoardMoveSelectedSquare
done:
	.leave
	ret
BoardGetWrongCellOnScreen		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardGetEmptyCellOnScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

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
	srs	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardGetEmptyCellOnScreen	method dynamic CwordBoardClass, 
						MSG_CWORD_BOARD_FIND_EMPTY_CELL
	uses	ax,dx
	.enter

	mov	dx,ds:[di].CBI_engine
	tst	dx
	jz	done
	call	EngineFindFirstEmptyCell
	jnc	done
	call	BoardMoveSelectedSquare
done:
	.leave
	ret

BoardGetEmptyCellOnScreen		endm






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardClearPuzzle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass

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
	srs	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardClearPuzzle	method dynamic CwordBoardClass, 
						MSG_CWORD_BOARD_CLEAR_PUZZLE
	uses	ax,dx
	.enter

	cmp	ds:[di].CBI_system, ST_PEN
	jne	dontReset
	call	BoardGestureResetMacroProcFar
dontReset:
	mov	dx,ds:[di].CBI_engine
	tst	dx
	jz	done
	call	EngineClearAllCells
	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock
	call	CwordEnableDisableClearXSquares

done:
	.leave
	ret
BoardClearPuzzle		endm




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardClearXCells
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass

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
	srs	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardClearXCells	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_CLEAR_X_CELLS
	uses	ax,dx
	.enter

	cmp	ds:[di].CBI_system, ST_PEN
	jne	dontReset
	call	BoardGestureResetMacroProcFar
dontReset:
	mov	dx,ds:[di].CBI_engine
	tst	dx
	jz	done
	call	EngineClearWrongCells
	mov	ax,MSG_VIS_INVALIDATE
	call	ObjCallInstanceNoLock

	call	CwordEnableDisableClearXSquares
done:
	.leave
	ret
BoardClearXCells		endm





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDetermineIfWrongCellOnScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enumerate through the cells and determine if any of the
		wrong cells are currently visible.

CALLED BY:	

PASS:		
		*ds:si - Board

RETURN:		
		stc - yes
		clc - no

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
BoardDetermineIfWrongCellOnScreen		proc	far
	class	CwordBoardClass
	uses	ax,di
visibleRect	local	Rectangle
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSDI CwordBoard_offset
	mov	ax,ds:[di].CBI_cellWidth
	shr	ax,1

	;    Make sure a reasonable portion of the wrong cell
	;    is visible
	;

	call	BoardGetVisibleRect
	add	visibleRect.R_left,ax
	add	visibleRect.R_top,ax
	sub	visibleRect.R_right,ax
	sub	visibleRect.R_bottom,ax

	mov	di,offset BoardIsWrongCellOnScreenCallback
	call	BoardEnumerateCells

	.leave
	ret
BoardDetermineIfWrongCellOnScreen		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardIsWrongCellOnScreenCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if cell is wrong and on screen

CALLED BY:	BoardEnumerateCells

PASS:		
		*ds:si - Board
		dx - engine token
		bx - cell token
		cx,bp - data passed to BoardEnumerateCells

RETURN:		
		clc - if cell is not wrong or not on screen
		stc - if cell is wrong and on screen

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
BoardIsWrongCellOnScreenCallback		proc	near
	uses	ax,bx,cx,dx
visibleRect	local	Rectangle
	.enter inherit

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	CellTokenType	bx
	Assert	EngineTokenType	dx
;;;;;;;;

	mov	ax,bx				;cell token
	call	EngineGetCellFlagsFar
	test	cl,mask CF_WRONG
	jz	dontStop

	mov	cx,ax				;cell token
	call	BoardGetCellBounds
	cmp	ax,visibleRect.R_right
	jg	dontStop
	cmp	cx,visibleRect.R_left
	jl	dontStop
	cmp	bx,visibleRect.R_bottom
	jg	dontStop
	cmp	dx,visibleRect.R_top
	jge	stopIt

dontStop:
	clc
done:
	.leave
	ret

stopIt:
	stc
	jmp	done

BoardIsWrongCellOnScreenCallback		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardAnimateVerify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Highlight each cell and the verify it, drawing
		the slashed if it is wrong.

CALLED BY:	

PASS:		*ds:si - CwordBoardClass object

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
	srs	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardAnimateVerify		proc	far
	class	CwordBoardClass
	uses	ax,cx,bx,dx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;


	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	dx,ds:[bx].CBI_engine
	call	EngineFindFirstWrongCell
	jc	atLeastOneWrongCell

	call	BoardFlashOK

enumerate:
	mov	cx,di				;gstate
	mov	di,offset BoardRedrawWrongCellCallback
	call	BoardEnumerateCells

	mov	di,cx				;gstate
	BoardDrawHiLites
	call	GrDestroyState

	.leave
	ret

atLeastOneWrongCell:
	call	GrGetWinBounds
	call	BoardFlashRect
	jmp	enumerate

BoardAnimateVerify		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardVerifyWord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See message defintion

PASS:		
		*(ds:si) - instance data of object
		ds:[bx] - instance data of object
		ds:[di] - master part of object
		es - segment of CwordBoardClass

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
	srs	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardVerifyWord	method dynamic CwordBoardClass, 
					MSG_CWORD_BOARD_VERIFY_WORD
	uses	ax,cx,dx,bp
	.enter

	cmp	ds:[di].CBI_system, ST_PEN
	jne	dontReset
	call	BoardGestureResetMacroProcFar
dontReset:

	call	BoardPlaySound

	call	BoardGetGStateDI
	BoardEraseHiLites

	GetInstanceDataPtrDSBX CwordBoard_offset
	mov	ax,ds:[bx].CBI_cell
	mov	cx,ds:[bx].CBI_direction
	push	ax,cx				;cell, direction
	call	BoardMapWordToFirstNLastCellsFar
	call	BoardGetBoundsForFirstNLastCellsFar
	call	BoardFlashRect

	pop	ax,bx				;cell, direction
	mov	cx,di				;gstate
	mov	di,offset BoardRedrawWrongCellCallback
	call	BoardEnumerateCellsInWord

	mov	di,cx				;gstate
	BoardDrawHiLites
	call	GrDestroyState

	call	CwordEnableDisableClearXSquares

	.leave
	ret
BoardVerifyWord		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardFlashRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tempoarily invert a rectangle

CALLED BY:	BoardAnimateVerify
		BoardVerifyWord

PASS:		di - Gstate Handle
		ax,bx,cx,dx - rectangle

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
	srs	10/ 5/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardFlashRect		proc	near
	uses	ax
	.enter

	push	ax
	mov	al,MM_INVERT
	call	GrSetMixMode
	pop	ax
	call	GrFillRect	

	push	ax
	mov	ax,15
	call	TimerSleep
	pop	ax

	call	GrFillRect	
	mov	al,MM_COPY
	call	GrSetMixMode

	.leave
	ret
BoardFlashRect		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardRedrawWrongCellCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If the letter is wrong then draw slashed in it.
	
CALLED BY:	BoardEnumerateCells

PASS:		
		*ds:si - CwordBoardClass object
		dx - engine token
		bx - cell token
		cx - gstate

RETURN:		
		ax - passed cell token

DESTROYED:	
		clc - to keep enumerating

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	8/25/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardRedrawWrongCellCallback		proc	near
	uses	ax,cx,dx,di
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert	gstate		cx
	Assert	CellTokenType	bx
	Assert	EngineTokenType	dx
;;;;;;;;

	mov	di,cx				;gstate
	mov	ax,bx				;cell token
	call	EngineVerifyCell
	jc	itsWrong

done:
	clc
	.leave
	ret

itsWrong:
	call	BoardRedrawCellFar
	jmp	done

BoardRedrawWrongCellCallback		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardFadeInCoolString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slowly fade out board and fade in the string

CALLED BY:	

PASS:		
		*ds:si - Board
		es:bx - null terminated cool string

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
	srs	9/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CoolStringStruc	struc
	CSS_stringOffset	word
	CSS_textPos		Point
	CSS_textSize		Point			;width, height
	CSS_scaleX		WWFixed
	CSS_scaleY		WWFixed
CoolStringStruc	ends

BoardFadeInCoolString		proc	far
	class	CwordBoardClass
	uses	ax,bx,cx,dx,di,si,bp,ds

coolLocals	local	CoolStringStruc

	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
	Assert  nullTerminatedAscii esbx
;;;;;;;;
	mov	coolLocals.CSS_stringOffset, bx
	
	call	BoardCreateGStateForCoolString
	GetInstanceDataPtrDSBX CwordBoard_offset
	cmp	ds:[bx].CBI_drawOptions, mask DO_COLOR
	jz	10$
	mov	ax, C_BLUE or (CF_INDEX shl 8)
	call	GrSetTextColor
10$:
	call	BoardCalcCoolStringBounds
	call	BoardShiftCoolStringBounds
	call	BoardCalcCoolScaleFactor
	call	BoardTranslateScaleCoolString


	mov	si,offset FadeMask1

again:
	push	si					;fade offset

	mov	al, SDM_CUSTOM or mask SDM_INVERSE
	segmov	ds,cs					;segment of fades
	call	GrSetAreaMask
	call	GrSetTextMask

	;    Fade out board. Making sure that it is slightly larger than
	;    window
	;

	mov	ax,-1
	mov	bx,-1
	mov	cx,coolLocals.CSS_textSize.P_x
	inc	cx
	mov	dx,coolLocals.CSS_textSize.P_y
	inc	dx
	call	GrFillRect

	;    Fade in cool
	;

	clr	ax,bx					;position
	clr	cx					;null termed		
	segmov	ds,es					;string segment
	mov	si,coolLocals.CSS_stringOffset
	call	GrDrawText

	pop	si
	add	si, (FadeMask16-FadeMask15)
	cmp	si, offset FadeMask16
	jbe	again

	call	GrDestroyState

	.leave
	ret


BoardFadeInCoolString		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardFlashOK
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flash an OK in the puzzle area

CALLED BY:	BoardAnimateVerify

PASS:		
		*ds:si - Board
		di - gstate
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
	srs	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardFlashOK		proc	near
	uses	ax,bx,cx,di,si,ds,es

coolLocals	local	CoolStringStruc
ForceRef	coolLocals

	.enter

	Assert	ObjectBoard	dssi

	segmov	es,cs
	mov	bx,offset okText
	mov	coolLocals.CSS_stringOffset,bx

	call	BoardCreateGStateForCoolString
	mov	al,MM_INVERT
	call	GrSetMixMode
	call	BoardCalcCoolStringBounds
	call	BoardShiftCoolStringBounds
	call	BoardCalcCoolScaleFactor
	call	BoardTranslateScaleCoolString

	call	GrGetWinBounds
	call	GrFillRect

	clr	ax,bx					;position
	clr	cx					;null termed		
	segmov	ds,cs
	mov	si,offset okText
	call	GrDrawText

	mov	ax,15
	call	TimerSleep

	clr	ax					;x pos
	call	GrDrawText

	call	GrGetWinBounds
	call	GrFillRect

	call	GrDestroyState
	.leave
	ret
BoardFlashOK		endp

okText	char	"OK",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardFadeOutScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Slowly fade out screen

CALLED BY:	

PASS:		
		*ds:si - Board

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
	srs	9/21/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardFadeOutScreen		proc	far
	uses	ax,bx,cx,dx,di,si,bp,ds

	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;
	
	call	BoardCreateGStateForCoolString

	mov	si,offset FadeMask1

again:
	mov	al, SDM_CUSTOM or mask SDM_INVERSE
	segmov	ds,cs					;segment of fades
	call	GrSetAreaMask

	call	GrGetWinBounds
	call	GrFillRect

	add	si, (FadeMask16-FadeMask15)
	cmp	si, offset FadeMask16
	jbe	again

	call	GrDestroyState

	.leave
	ret


BoardFadeOutScreen		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardTranslateScaleCoolString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Apply translation and scale in stack frame to gstate

CALLED BY:	BoardFadeInCoolString

PASS:		
		di - gstate
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
	srs	10/28/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardTranslateScaleCoolString		proc	near
	uses	dx,cx,bx,ax

	.enter inherit BoardFadeInCoolString

	Assert	gstate di

	mov	dx,coolLocals.CSS_textPos.P_x
	mov	bx,coolLocals.CSS_textPos.P_y
	clr	ax,cx
	call	GrApplyTranslation

	movwwf	dxcx,coolLocals.CSS_scaleX
	movwwf	bxax,coolLocals.CSS_scaleY
	call	GrApplyScale

	.leave
	ret
BoardTranslateScaleCoolString		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCalcCoolStringBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the bounds of the text string

CALLED BY:	BoardFadeInCoolString

PASS:		
		di - gstate
		bp - inherited stack frame		
			coolLocals.CSS_stringOffset
		es - string segment

RETURN:		
		textPos and textSize in stack frame

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCalcCoolStringBounds		proc	near
	uses	ax,bx,cx,dx,ds,si
	.enter inherit BoardFadeInCoolString

;;; Verify argument(s)
	Assert	gstate	di
;;;;;;;;

	segmov	ds,es
	mov	si,coolLocals.CSS_stringOffset
	Assert  nullTerminatedAscii dssi

	clr	ax,bx					;position
	call	GrGetTextBounds
	mov	coolLocals.CSS_textPos.P_x,ax
	mov	coolLocals.CSS_textPos.P_y,bx
	sub	cx,ax
	mov	coolLocals.CSS_textSize.P_x,cx
	sub	dx,bx
	mov	coolLocals.CSS_textSize.P_y,dx

	.leave
	ret
BoardCalcCoolStringBounds		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardShiftCoolStringBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Shift textPos so that text will be drawn at upper left
		of window

CALLED BY:	BoardFadeInCoolString

PASS:		di - Gstate
		bp - inherited stack frame
			textPos
RETURN:		
		textPos changed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardShiftCoolStringBounds		proc	near
	uses	ax,bx,cx,dx
	.enter inherit BoardFadeInCoolString

;;; Verify argument(s)
	Assert	gstate	di
;;;;;;;;

	call	GrGetWinBounds
	sub	ax,coolLocals.CSS_textPos.P_x
	mov	coolLocals.CSS_textPos.P_x,ax
	sub	bx,coolLocals.CSS_textPos.P_y
	mov	coolLocals.CSS_textPos.P_y,bx


	.leave
	ret
BoardShiftCoolStringBounds		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCalcCoolScaleFactor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc scale factor from text size to window size

CALLED BY:	BoardFadeInCoolString

PASS:		di - Gstate
		bp - inherited stack frame
			textSize
RETURN:		
		scaleX, scaleY

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCalcCoolScaleFactor		proc	near
	uses	ax,bx,cx,dx
	.enter inherit BoardFadeInCoolString

;;; Verify argument(s)
	Assert	gstate	di
;;;;;;;;

	call	GrGetWinBounds
	sub	cx,ax				;window width
	mov	dx,cx
	mov	bx,coolLocals.CSS_textSize.P_x
	clr	ax,cx
	call	GrSDivWWFixed
	movwwf	coolLocals.CSS_scaleX,dxcx

	call	GrGetWinBounds
	sub	dx,bx				;window height
	mov	bx,coolLocals.CSS_textSize.P_y
	clr	ax,cx
	call	GrSDivWWFixed
	movwwf	coolLocals.CSS_scaleY,dxcx

	.leave
	ret
BoardCalcCoolScaleFactor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardCreateGStateForCoolString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a gstate for drawing the COOL string into

CALLED BY:	BoardFadeInCoolString

PASS:		
		*ds:si - Board
RETURN:		
		di - gstate
DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/22/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardCreateGStateForCoolString		proc	near
	uses	ax,cx,dx,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	mov	ax,MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di,bp

	mov	al,mask TM_DRAW_ACCENT
	clr	ah
	call	GrSetTextMode

	mov	ax, C_WHITE or (CF_INDEX shl 8)
	call	GrSetAreaColor

	mov	cx,BOARD_TEXT_FONT
	clr	dx,ax
	call	GrSetFont
	mov	al,mask TS_BOLD
	clr	ah
	call	GrSetTextStyle
	mov	al,FW_MAXIMUM
	call	GrSetFontWeight

	.leave
	ret
BoardCreateGStateForCoolString		endp



FadeMask1	label	byte
	db	11111101b
	db	11111111b
	db	11011111b
	db	11111111b
	db	10111111b
	db	11111011b
	db	11111111b
	db	11111111b

	db	11111111b
	db	11101111b
	db	11111111b
	db	11111110b
	db	01111111b
	db	11111111b
	db	11011111b
	db	11111111b

	db	11101111b
	db	11111111b
	db	11110111b
	db	11111111b
	db	11111111b
	db	01111111b
	db	11111111b
	db	11111101b

	db	11111111b
	db	11111101b
	db	11111111b
	db	11110111b
	db	11111111b
	db	11111111b
	db	10111111b
	db	11101111b

	db	11111110b
	db	11111111b
	db	11111101b
	db	11111111b
	db	11111111b
	db	10111111b
	db	11111111b
	db	11110111b

	db	11011111b
	db	11111111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11011111b
	db	11111111b
	db	11111011b

	db	11111111b
	db	11111110b
	db	11111111b
	db	11101111b
	db	11011111b
	db	11111111b
	db	11111101b
	db	11111111b

	db	11111111b
	db	01111111b
	db	11111111b
	db	10111111b
	db	11101111b
	db	11111111b
	db	11110111b
	db	11111111b

	db	11111011b
	db	10111111b
	db	11111111b
	db	11111111b
	db	11110111b
	db	11111111b
	db	11101111b
	db	11111111b

	db	11111111b
	db	11110111b
	db	11111111b
	db	01111111b
	db	11111111b
	db	11111111b
	db	11111011b
	db	11011111b

	db	10111111b
	db	11111011b
	db	11111111b
	db	11111101b
	db	11111101b
	db	11111111b
	db	11111110b
	db	11111111b

	db	11111111b
	db	11111111b
	db	10111111b
	db	11111111b
	db	11111111b
	db	11111101b
	db	11111111b
	db	10111111b

	db	11111111b
	db	11011111b
	db	11111111b
	db	11111011b
	db	11111110b
	db	11111111b
	db	01111111b
	db	11111110b

	db	01111111b
	db	11111111b
	db	11111110b
	db	11111111b
	db	11111111b
	db	11101111b
	db	11111111b
	db	11111111b

FadeMask15	label	byte
	db	11110111b
	db	11111111b
	db	11101111b
	db	11111111b
	db	11111011b
	db	11111110b
	db	11111111b
	db	11111111b

FadeMask16	label	byte
	db	11111111b
	db	11111111b
	db	11111011b
	db	11011111b
	db	11111111b
	db	11110111b
	db	11111111b
	db	01111111b




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardDoShootingStars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		

RETURN:		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardDoShootingStars		proc	far
	uses	ax,cx,dx,di,si
	.enter

	Assert	ObjectBoard	dssi

	call	BoardGetGStateDI
	mov	al,MM_INVERT
	call	GrSetMixMode

	call	ParticleArrayCreate
	jc	destroyState

	;    Always start with at least one star.
	;

	call	ShootingStarCreate

	;     Choose random number of stars to eventually create
	;

	mov	dx,MAX_STARS_CREATED
	mov	cx,MIN_STARS_CREATED
	call	BoardChooseRandom
	mov	bx,dx
	dec	bx

again:
	call	ParticleDraw
	mov	ax,3
	call	TimerSleep
	call	ParticleAdvance
	call	ParticleCleanup

	tst	bx				;stars left to create
	jz	checkForNoParticles

	;     Maybe create new star, but always continue because
	;     there are stars left to create.
	;

	mov	ax,PERCENT_CHANCE_OF_NEW_STAR
	call	BoardPercentageChance
	jnc	again				;jmp if don't create star
	call	ShootingStarCreate
	dec	bx
	jmp	again

checkForNoParticles:
	call	ChunkArrayGetCount
	tst	cx
	jnz	again

	mov	ax,si
	call	LMemFree

destroyState:
	call	GrDestroyState

	.leave
	ret

	


BoardDoShootingStars		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardPercentageChance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate percentage chance event

CALLED BY:	

PASS:		
		ax - 0-100 percentage chance

RETURN:		
		carry clear - didn't happen
		carry set - happened

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardPercentageChance		proc	near
	uses	dx
	.enter

	mov	dx,100
	call	GameRandom
	inc	dx				;100-1 range
	cmp	ax,dx
	jge	itHappened
	clc
done:
	.leave
	ret

itHappened:
	stc
	jmp	done

BoardPercentageChance		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleArrayCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create chunk array for particles

CALLED BY:	BoardDoShootingStars

PASS:		
		ds - segment of object block

RETURN:		
		clc - array created
			si - chunk handle of chunk array
		stc - array not created
			si - destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleArrayCreate		proc	near
	uses	cx,dx
	.enter

	clr	al
	clr	cx,si
	mov	bx,size Particle
	call	ChunkArrayCreate

	.leave
	ret
ParticleArrayCreate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShootingStarCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a shooting start chunk array element

CALLED BY:	

PASS:		
		*ds:si - chunk array
		di - gstate to window to draw shooting stars

RETURN:		
		clc - particle created
			ax - element
		stc - particle not created
			ax - destroyed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShootingStarCreate		proc	near
	uses	bx,cx,dx

initData	local	ParticleInit

	.enter

	Assert	ChunkArray	dssi
	Assert	gstate	di

	mov	dx,MAX_SPARK_PROB
	mov	cx,MIN_SPARK_PROB
	call	BoardChooseRandom
	mov	initData.PI_sparkProb,dl

	;    Choose gravity.
	;

	mov	dx,MAX_STAR_VERT_GRAVITY_INT
	mov	cx,MIN_STAR_VERT_GRAVITY_INT
	mov	bx,MAX_STAR_VERT_GRAVITY_FRAC
	mov	ax,MIN_STAR_VERT_GRAVITY_FRAC
	call	ParticleChooseVelocity
	movwwf	initData.PI_gravity.PF_y,dxax
	clrwwf	initData.PI_gravity.PF_x



	;    Choose vertical velocity. Always negative so stars
	;    start out shooting upwards.
	;

	mov	dx,MAX_STAR_VERT_VELOCITY_INT
	mov	cx,MIN_STAR_VERT_VELOCITY_INT
	mov	bx,MAX_STAR_VERT_VELOCITY_FRAC
	mov	ax,MIN_STAR_VERT_VELOCITY_FRAC
	call	ParticleChooseVelocity
	negwwf	dxax				;always start up
	movwwf	initData.PI_velocity.PF_y,dxax

	;    Choose horiz velocity
	;

	mov	dx,MAX_STAR_HORIZ_VELOCITY_INT
	mov	cx,MIN_STAR_HORIZ_VELOCITY_INT
	mov	bx,MAX_STAR_HORIZ_VELOCITY_FRAC
	mov	ax,MIN_STAR_HORIZ_VELOCITY_FRAC
	call	ParticleChooseVelocity
	movwwf	initData.PI_velocity.PF_x,dxax

	;    Choose left or right side of window and switch velocity
	;    direction if starting from the right side
	;

	call	GrGetWinBounds
	mov	dx,2
	call	GameRandom
	tst	dx
	je	gotSide				;using left
	mov	ax,cx
	negwwf	initData.PI_velocity.PF_x
	negwwf	initData.PI_gravity.PF_x
gotSide:
	mov	initData.PI_position.P_x,ax

	;    Choose vertical position in top 75% of screen
	;

	call	GrGetWinBounds
	sub	dx,bx					;win height
	mov	ax,dx					;win height
	shr	ax					;50% win height
	shr	ax					;25% win height
	sub	dx,ax					;range = 75% win height
	call	GameRandom
	add	dx,bx					;down from top
	mov	initData.PI_position.P_y,dx

	mov	initData.PI_width,STAR_WIDTH
	mov	initData.PI_height,STAR_HEIGHT

	call	ParticleCreate

	.leave
	ret

ShootingStarCreate		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleChooseVelocity
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calc random velocity

CALLED BY:	ShootingStartCreate

PASS:		
		dx - max int 
		cx - min int 
		bx - max frac 
		ax - min frac 

RETURN:		
		dx:ax - WWFixed velocity

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleChooseVelocity		proc	near
	.enter

	push	dx,cx			;max int,min int
	movdw	dxcx,bxax		;max frac, min frac
	call	BoardChooseRandom
	mov	ax,dx			;frac

	pop	dx,cx			;max int, min int
	call	BoardChooseRandom

	.leave
	ret
ParticleChooseVelocity		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BoardChooseRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Choose random number in range

CALLED BY:	

PASS:		
		dx - max
		cx - min

RETURN:		
		dx

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BoardChooseRandom		proc	near
	.enter

EC<	cmp	dx,cx				>
EC<	ERROR_B	255	>

	sub	dx,cx			;sub min to get range
	inc	dx
	call	GameRandom
	add	dx,cx			;add min

	.leave
	ret
BoardChooseRandom		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new particle in the chunk array

CALLED BY:	ShootingStarCreate

PASS:		
		*ds:si - chunk array
		bp - inherited stack frame

RETURN:		
		clc - particle created
			ax - element
		stc - particle not created
			ax - destroyed

DESTROYED:	
		see RETURN

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleCreate		proc	near
	uses	cx,dx,di

initData	local	ParticleInit

	.enter	inherit

	call	ChunkArrayAppend
	jc	done

	clr	dx
	mov	cx, initData.PI_position.P_x
	movdw	ds:[di].P_curPosition.PF_x,cxdx
	mov	cx, initData.PI_position.P_y
	movdw	ds:[di].P_curPosition.PF_y,cxdx

	movdw	cxdx, initData.PI_velocity.PF_x
	movdw	ds:[di].P_velocity.PF_x,cxdx
	movdw	cxdx, initData.PI_velocity.PF_y
	movdw	ds:[di].P_velocity.PF_y,cxdx

	movdw	cxdx, initData.PI_gravity.PF_x
	movdw	ds:[di].P_gravity.PF_x,cxdx
	movdw	cxdx, initData.PI_gravity.PF_y
	movdw	ds:[di].P_gravity.PF_y,cxdx

	mov	cl, initData.PI_sparkProb
	mov	ds:[di].P_sparkProb,cl

	mov	cl, initData.PI_width
	mov	ds:[di].P_width,cl
	mov	cl, initData.PI_height
	mov	ds:[di].P_height,cl

	clr	ds:[di].P_info

	clc

done:
	.leave
	ret
ParticleCreate		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw all particles in the passed particle array

CALLED BY:	

PASS:		
		*ds:si - particle chunk array
		di - gstate

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
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleDraw		proc	near
	uses	bx,di,bp
	.enter

	Assert	gstate	di
	Assert	ChunkArray dssi

	mov	bp,di				;gstate
	mov	bx,cs
	mov	di,offset ParticleDrawCallback
	call	ChunkArrayEnum

	.leave
	ret
ParticleDraw		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleDrawCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the particle if not already drawn

CALLED BY:	ChunkArrayEnum

PASS:		ds:di - particle
		bp - gstate

RETURN:		
		carry clear

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleDrawCallback		proc	far
	uses	di,ax,bx,cx,dx,bp
	.enter

	Assert	gstate	bp

	;    Draw at new position
	;

	BitSet	ds:[di].P_info, PI_DRAWN

	movwwf	axcx,ds:[di].P_curPosition.PF_x
	rndwwf	axcx
	movwwf	bxcx,ds:[di].P_curPosition.PF_y
	rndwwf	bxcx
	cmp	ax,ds:[bp].P_lastDrawnPosition.P_x
	je	checkNoChange

drawNew:
	mov	cl,ds:[di].P_width
	mov	ch,ds:[di].P_height

	xchg	di,bp					;gstate,offset
	call	DrawAParticle

	;    Save just drawn position and Erase at old position if initialized 
	;

	xchg	ax,ds:[bp].P_lastDrawnPosition.P_x
	xchg	bx,ds:[bp].P_lastDrawnPosition.P_y

	test	ds:[bp].P_info, mask PI_LAST_DRAWN_INITIALIZED
	jz	initLastDrawn

	call	DrawAParticle

initLastDrawn:
	BitSet	ds:[bp].P_info, PI_LAST_DRAWN_INITIALIZED


done:
	clc
	.leave
	ret

checkNoChange:
	cmp	bx,ds:[bp].P_lastDrawnPosition.P_y
	jne	drawNew
	jmp	done
	

ParticleDrawCallback		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawAParticle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	

PASS:		
		di - gstate
		ax - x
		bx - y
		cl - width
		ch - height
RETURN:		

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawAParticle		proc	near
	uses	cx,dx
	.enter

	mov	dl,ch				;height
	clr	ch,dh				;high byte of width and height
	add	cx,ax
	add	dx,bx
	call	GrFillRect

	.leave
	ret
DrawAParticle		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleEraseCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the particle if it is drawn

CALLED BY:	ChunkArrayEnum

PASS:		ds:di - particle
		bp - gstate

RETURN:		
		carry clear

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleEraseCallback		proc	far
	uses	di,ax,bx,cx
	.enter

	Assert	gstate	bp

	test	ds:[di].P_info,mask PI_DRAWN
	jz	done
	test	ds:[di].P_info,mask PI_LAST_DRAWN_INITIALIZED
	jz	done

	BitClr	ds:[di].P_info,PI_DRAWN

	mov	ax,ds:[di].P_lastDrawnPosition.P_x
	mov	bx,ds:[di].P_lastDrawnPosition.P_y
	mov	cl,ds:[di].P_width
	mov	ch,ds:[di].P_height
	mov	di,bp
	call	DrawAParticle
done:
	clc

	.leave
	ret
ParticleEraseCallback		endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleAdvance
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance all particles in the passed particle array

CALLED BY:	

PASS:		
		*ds:si - particle chunk array

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
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleAdvance		proc	near
	uses	bx,di,bp
	.enter

	Assert	ChunkArray dssi

	mov	bx,cs
	mov	di,offset ParticleAdvanceCallback
	call	ChunkArrayEnum

	.leave
	ret
ParticleAdvance		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleAdvanceCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Advance the particle

CALLED BY:	ChunkArrayEnum

PASS:		ds:di - particle

RETURN:		
		carry clear

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleAdvanceCallback		proc	far
	uses	di,bx,ax
	.enter

	;    Treat x gravity as drag in opposite direction of
	;    velocity
	;

	movwwf	bxax,ds:[di].P_velocity.PF_x
	addwwf	ds:[di].P_curPosition.PF_x,bxax
	tst	bx
	movwwf	bxax,ds:[di].P_gravity.PF_x
	js	10$
	negwwf	bxax
10$:
	addwwf	ds:[di].P_velocity.PF_x,bxax

	;     Treat y gravity as gravity, increasing downward velocity
	;

	movwwf	bxax,ds:[di].P_velocity.PF_y
	addwwf	ds:[di].P_curPosition.PF_y,bxax
	movwwf	bxax,ds:[di].P_gravity.PF_y
	addwwf	ds:[di].P_velocity.PF_y,bxax
	
	clr	ah
	mov	al,ds:[di].P_sparkProb
	call	BoardPercentageChance
	jc	makeSpark

done:
	clc

	.leave
	ret

makeSpark:
	call	SparkCreate
	jmp	done

ParticleAdvanceCallback		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SparkCreate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a spark chunk array element. Append it so that
		it will have moved away from the original before the
		next drawing operation

CALLED BY:	

PASS:		
		*ds:si - chunk array
		ds:di - source particle

RETURN:		
		clc - particle created
			ax - element
		stc - particle not created
			ax - destroyed

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SparkCreate		proc	near
	uses	ax,bx,cx,dx

initData	local	ParticleInit

	.enter

	Assert	ChunkArray	dssi

	;    Spark gets same position
	;

	movwwf	cxdx,ds:[di].P_curPosition.PF_x
	rndwwf	cxdx
	mov	initData.PI_position.P_x,cx
	movwwf	cxdx,ds:[di].P_curPosition.PF_y
	rndwwf	cxdx
	mov	initData.PI_position.P_y,cx

	;    no babies
	;	

	clr	initData.PI_sparkProb

	;    Give spark random y gravity bigger than source and
	;    a small x gravity opposite in direction to velocity
	;

	mov	dx,MAX_STAR_TO_SPARK_GRAVITY_INCREASE_INT
	mov	bx,MAX_STAR_TO_SPARK_GRAVITY_INCREASE_FRAC
	mov	cx,MIN_STAR_TO_SPARK_GRAVITY_INCREASE_INT
	mov	ax,MIN_STAR_TO_SPARK_GRAVITY_INCREASE_FRAC
	call	ParticleChooseVelocity
	addwwf	dxax,ds:[di].P_gravity.PF_y
	movwwf	initData.PI_gravity.PF_y,dxax

	mov	dx,MAX_SPARK_HORIZ_DRAG_INT
	mov	cx,MIN_SPARK_HORIZ_DRAG_INT
	mov	bx,MAX_SPARK_HORIZ_DRAG_FRAC
	mov	ax,MIN_SPARK_HORIZ_DRAG_FRAC
	call	ParticleChooseVelocity
	movwwf	initData.PI_gravity.PF_x,dxax

	;    Modify the velocity half of the max increase either up
	;    or down.
	;
	
	mov	bx,MAX_STAR_TO_SPARK_VERT_VELOCITY_INCREASE_FRAC
	mov	dx,MAX_STAR_TO_SPARK_VERT_VELOCITY_INCREASE_INT
	clr	ax,cx
	call	ParticleChooseVelocity
	sub	dx,MAX_STAR_TO_SPARK_VERT_VELOCITY_INCREASE_HALF; sub half from
	addwwf	dxax,ds:[di].P_velocity.PF_y
	movwwf	initData.PI_velocity.PF_y,dxax

	;    Give small horiz velocity in same direction
	;

	mov	dx,MAX_SPARK_HORIZ_VELOCITY_INT
	mov	cx,MIN_SPARK_HORIZ_VELOCITY_INT
	mov	bx,MAX_SPARK_HORIZ_VELOCITY_FRAC
	mov	ax,MIN_SPARK_HORIZ_VELOCITY_FRAC
	call	ParticleChooseVelocity
	tst	ds:[di].P_velocity.PF_x.WWF_int
	jns	20$
	negwwf	dxax
20$:
	movwwf	initData.PI_velocity.PF_x,dxax

	mov	dx,SPARK_MAX_WIDTH
	mov	cx,SPARK_MIN_WIDTH
	call	BoardChooseRandom
	mov	initData.PI_width,dl

	mov	dx,SPARK_MAX_HEIGHT
	mov	cx,SPARK_MIN_HEIGHT
	call	BoardChooseRandom
	mov	initData.PI_height,dl

	call	ParticleCreate

	.leave
	ret


SparkCreate		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleCleanup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all particles no longer on the screen

CALLED BY:	

PASS:		
		*ds:si - particle chunk array
		di - gstate

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
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleCleanup		proc	near
	uses	bx,di,bp
	.enter

	Assert	ChunkArray dssi
	Assert	gstate	di

	call	GrGetWinBounds
	mov	bp,di				;gstate

	mov	bx,cs
	mov	di,offset ParticleCleanupCallback
	call	ChunkArrayEnum

	.leave
	ret
ParticleCleanup		endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ParticleCleanupCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase and delete this particle if it has gone off the
		left, right or bottom of screen

CALLED BY:	ChunkArrayEnum

PASS:		ds:di - particle
		ax - left
		cx - right
		dx - bottom
		bp - gstate

RETURN:		
		carry clear

DESTROYED:	
		nothing

PSEUDO CODE/STRATEGY:
		none

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	srs	9/23/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ParticleCleanupCallback		proc	far
	uses	di
	.enter

	Assert	gstate	bp

	cmp	ax,ds:[di].P_curPosition.PF_x.WWF_int
	jg	cleanup
	cmp	cx,ds:[di].P_curPosition.PF_x.WWF_int
	jl	cleanup
	cmp	dx,ds:[di].P_curPosition.PF_y.WWF_int
	jl	cleanup
	
done:
	clc

	.leave
	ret

cleanup:
	call	ParticleEraseCallback
	call	ChunkArrayDelete
	jmp	done

ParticleCleanupCallback		endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CwordEnableDisableClearXSquares
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	If there are any wrong squares in the puzzle then
		enable Clear X Squares

CALLED BY:	UTILITY

PASS:		*ds:si - Board

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
	srs	11/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CwordEnableDisableClearXSquares		proc	far
	class	CwordBoardClass
	uses	ax,bx,cx,dx,si,di,bp
	.enter

;;; Verify argument(s)
	Assert	ObjectBoard	dssi
;;;;;;;;

	GetInstanceDataPtrDSBX	CwordBoard_offset
	mov	dx,ds:[bx].CBI_engine
	tst	dx
	jz	notEnabled
	call	EngineFindFirstWrongCell
	jnc	notEnabled

	mov	ax,MSG_GEN_SET_ENABLED
sendMessage:
	mov	bx,handle ClearXButton
	mov	si,offset ClearXButton
	mov	di,mask MF_FIXUP_DS
	mov	dl, VUM_NOW
	call	ObjMessage

	.leave
	ret

notEnabled:
	mov	ax,MSG_GEN_SET_NOT_ENABLED
	jmp	sendMessage


CwordEnableDisableClearXSquares		endp


CwordVictoryCode	ends

