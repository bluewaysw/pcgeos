
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:	Practice Project
MODULE:		Uki program
FILE:		uki.asm

Author		Jimmy Lefkowitz, January 14, 1991

	$Id: uki.asm,v 1.1 97/04/04 15:47:09 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCode segment resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiChooseUki
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL

PASS:		ax = 0; only do functions
		ax != 0; do full init

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	2/ 7/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiChooseUki	method	UkiContentClass, MSG_UKI_CHOOSE_UKI

	UkiAssignFunction	initGame, UkiInitGame
	UkiAssignFunction	validMove, UkiIsClickValidMove
	UkiAssignFunction	movePiece, UkiMovePiece
	UkiAssignFunction	adjustMoveValues, UkiAdjustMoveValues
	UkiAssignFunction	userInput, UkiGetMouseClick
	UkiAssignFunction	computerFindMove, UkiComputerFindBestMove 

	; Start the game, maybe
	tst	ax
	jz	done
	mov	ax, UKI_INIT_BOARD_SIZE
	mov	es:[cells], al
	call	UkiSetUpBoardSizeUI
	mov	ax, MSG_UKI_START
	call	ObjCallInstanceNoLock
done:
	ret
UkiChooseUki	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiInitGame

DESCRIPTION:   initializes all state variables for a new game


PASS:          nothing

RETURN:        nothing

DESTROYED:     ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiInitGame	proc	far

;CELLS = 7 
;LINES = CELLS+1
;BAD_COORD = LINES
;MAXCELLS = CELLS*CELLS

	mov	es:[obstacles], 0

	mov	al, es:[cells]
	shr	al
	mov	bl, al
	mov	cx, mask GDN_PLAYER2
	call	UkiSetNode

	dec	al
	mov	cx, mask GDN_PLAYER1
	call	UkiSetNode

	dec	bl
	mov	cx, mask GDN_PLAYER2
	call	UkiSetNode

	inc	al
	mov	cx, mask GDN_PLAYER1
	call	UkiSetNode
initLoop:
	; keep initting the obstcles until the first guy can go...
	call	UkiInitObstacles
	call	UkiComputerMoveSearch	; find best move
	; if the bestMoveCoord has an x coordinate of BAD_COORD then
	; there were no possible moves for player1 so re-init the obstacles
	cmp	es:[bestMoveCoord].x_pos,BAD_COORD 
	je	initLoop
	; if no obstacles got put up, try again...
	; unless of course there aren't supposed to be any
	tst	es:[obstacles]
	jnz	done	; have obstacles, ok we are done
	; ok, no obstacles, if maxObstacles is zero then we are not supposed
	; to have obstacles so we are done, else try again
	tst	es:[maxObstacles]	
	jnz	initLoop
done:
	ret
UkiInitGame	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiInitObstacles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	
	put up a symmetric pattern of obstacles four at a time,
	up to maxObstacles
	(could be 0)

CALLED BY:	UkiInitGame

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	
	for each of the upper left quadrant squares, randomly decide to
	add an obstacle, if yes then duplicate it symmetrically in other
	3 quadrants until we are done with all the upper left quadrant or have
	reached the maximum number of obstacles
KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/18/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiInitObstacles	proc	near
	
	; start at  0,0
	mov	ax, 0
	mov	bx, ax
	; init number of obstacles to zero
	mov	es:[obstacles], ax
initloop:
	; if the node already has an obstacle then we are being called
	; again from UkiInitGame because they board set up didn't allow
	; a first move, so just blank out the obstacle and continue as if
	; this was a blank space all along
	; if the current node is not empty (zero) then don't put an
	; obstacle there
	call	UkiGetNode
	cmp	cl, mask GDN_OBSTACLE
	jne	notObstacle
	mov	dl, 0
	call	UkiDoObstacle
notObstacle:
	tst	cx
	jnz	cont
	; else randomly decide to add an obstacle or not using a weighting
	; factor of OBSTACLE_FREQEUNCY
	mov	dx, es:[obstacles]
	cmp	dx, es:[maxObstacles]
	jge	done
	call	FastRandom
	and	dx, UKI_OBSTACLE_FREQUENCY
	tst	dx
	jnz	cont
	; we have decided to add an obstacles do add it symetrically to all
	; four quadrants
	mov	dl, mask GDN_OBSTACLE
	call	UkiDoObstacle
cont:
	; we are only doing the upper quadrant do calculate the x and y
	; to which we need to loop through, not effecient, but whose counting?
	push	bx
	inc	al
	mov	bl, es:[cells]
	shr	bl
;	inc	bl
	cmp	al, bl
	pop	bx
	jl	initloop
	inc	bl
	mov	al, es:[cells]
	shr	al
;	inc	al
	cmp	bl, al
	mov	al, 0
	jl	initloop
done:
	ret
UkiInitObstacles	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiDoObstacle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adds four obstacles the given one in the first quadrant and
		then added the other 3 symmetric ones in the other three
		quadrants

CALLED BY:	GLOBAL

PASS:		ax, bx = cell coordinate in first quadrant
		dl = value to put in the 4 cells (GameDataNode type)

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	11/30/92		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDoObstacle	proc	near 
	uses	ax, bx
	.enter
	mov	cl, dl
	call	UkiSetNode
	push	bx
	push	ax
	mov	al, es:[cells]
	dec	al
	sub	al, bl
	mov	bl, al
	pop	ax
	mov	cl, dl
	call	UkiSetNode
	push	bx
	mov	bl, es:[cells] 
	dec	bl
	sub	bl, al
	mov	al, bl
	pop	bx
	mov	cl, dl
	call	UkiSetNode
	pop	bx
	mov	cl, dl
	call	UkiSetNode
	tst	dl		; if we are clearing things out
	jz	done		; then don't update number of obstacles
	add	es:[obstacles], 4
done:
	.leave
	ret
UkiDoObstacle	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiAdjustMoveValues

DESCRIPTION:   change the parameters to calculate moves value as game
	       goes along

PASS:          nothing

RETURN:        nothing

DESTROYED:      nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiAdjustMoveValues	proc	far
	cmp	dl, 20
	jl	done
	mov	es:[generalValue2], UKI_EDGE_MOVE_VALUE_1
	cmp	dl, 35
	jl	done
	mov	es:[generalValue2], UKI_EDGE_MOVE_VALUE_2
	cmp	dl, 50
	jl	done
	mov	es:[generalValue2], UKI_EDGE_MOVE_VALUE_3
	cmp	dl, 65
	jl	done
	mov	es:[generalValue2], UKI_EDGE_MOVE_VALUE_4
	cmp	dl, 80
	jl	done
	mov	es:[generalValue2], UKI_EDGE_MOVE_VALUE_5
done:

	ret
UkiAdjustMoveValues	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiGetMouseClick

DESCRIPTION:   respond to a mouse click on the board

PASS:          	cx,dx = position of mouse click in grid coordinates
		
RETURN:        

DESTROYED:      

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiGetMouseClick	proc	far
	; now see the current status of that cell 
	mov	bx, es:[gameBoard]
	call	MemLock
	mov	ds, ax
	mov_tr	ax, cx
	mov_tr	bx, dx
	call	UkiGetNode
	
	; see if it is occupied by a piece owned by the current player
	tst	cl
	jnz	noMove

	xchg	ax, cx
	xchg	bx, dx
	call	UkiIsClickValidMove
	tst	cl
	jz	noMove
	mov	ch, al
	mov	dh, bl
	call	UkiMovePiece
	call	UkiCallComputerMove
	mov	si, UKI_MOVE_MADE
	jmp	done
noMove:
	mov	si, UKI_NO_MOVE_MADE
done:
	mov	bx, es:[gameBoard]
	call	MemUnlock
	ret
UkiGetMouseClick	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiIsClickValidMove

DESCRIPTION:   check to see if a move is a legal move

PASS:          cl, dl = clicked position

RETURN:        cl = number of opponents captured (0 == illegal move)
	       al, bl = cl, dl that got passed in
	
DESTROYED:      

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiIsClickValidMove	proc	far
	.enter
	mov_tr	ax, cx
	mov_tr	bx, dx
	clr	cl
	mov	dl, -1
	mov	dh, -1
checkloop:
	call	UkiCheckLine
	inc	dl
	cmp	dl, 2
	jl	checkloop
	mov	dl, -1
	inc	dh
	cmp	dh, 2
	jl	checkloop
	.leave
	ret
UkiIsClickValidMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCheckLine

DESCRIPTION:   	giveen a starting position and direction see if any
	       	opponents are captured along that line

PASS:		al, bl starting point
	 	dl, dh = direction vector (ie -1,-1 or 1,0 or 0,1)
		cl = value of move so far
RETURN:        
		cl = value of move after checking this row
			(ie. passed in cl + number of oppnents 
			 taken in this row)

DESTROYED:      

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCheckLine	proc	near
	uses	ax, bx, dx
	.enter
	push	cx
	mov	cl, dl
	or	dl, dh
	tst	dl
	pushf
	mov	dl, cl
	clr	cl
	popf	
	jz	nogoodPopCX
	cmp	es:[whoseTurn], offset player1
	jz	doplayer1
	mov	ah, mask GDN_PLAYER1
	jmp	checkloop
doplayer1:
	mov	ah, mask GDN_PLAYER2
checkloop:
	add	al, dl
	add	bl, dh
	call	UkiCheckBounds
	jc	nogoodPopCX

	push	cx
	call	UkiGetNode
	tst	cl
	jz	nogoodPopCXCX
	cmp	cl, mask GDN_OBSTACLE
	jz	nogoodPopCXCX
	mov	si, es:[whoseTurn]
	cmp	cl, es:[si].SP_player
	jz	contPopCX
	pop	cx
	inc	cl
	jmp	checkloop
nogoodPopCX:
	pop	cx
	jmp	done
nogoodPopCXCX:
	pop	cx
	pop	cx
	jmp	done
contPopCX:
	pop	cx
	mov	al, cl
	pop	cx
	add	cl , al
done:
	.leave
	ret
UkiCheckLine	endp


if 0
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiIsEdgeMove
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	????

PASS:		al, bl = position
		dl, dh is line vector

RETURN:		ch = 0 or 1

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/17/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiIsEdgeMove	proc	near
	uses	ax, bx, dx
	.enter
	clr	ch
	tst	al
	jnz	checkHighX
doVertical:
	tst	dl
	jnz	done
	mov	ch, 1
	jmp	done
checkHighX:
	inc	al
	cmp	al, es:[cells]
	jnz	checkLowY
	jmp	doVertical	
checkLowY:
	tst	bl
	jnz	checkHighY
doHorizontal:
	tst	dh
	jnz	done
	mov	ch, 1
	jmp	done
checkHighY:
	inc	bl
	cmp	bl, es:[cells]
	jnz	done
	jmp	doHorizontal
done:
	.leave
	ret
UkiIsEdgeMove	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiCheckBounds

DESCRIPTION:   check the bounds of a position


PASS:          al, bl grid position

RETURN:        

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCheckBounds	proc	near
	tst	al
	jl	outOfBounds
	tst	bl
	jl	outOfBounds
	cmp	al, es:[cells]
	jge	outOfBounds
	cmp	bl, es:[cells]
	jge	outOfBounds
	clc
	jmp	done
outOfBounds:
	stc
done:
	ret
UkiCheckBounds	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      	UkiMovePiece

DESCRIPTION:  	update board and screen for a given move

PASS:           ch,dh: position to move to
		cl: type of move (1 = jump, 3 = replication)

RETURN:        nothing

DESTROYED:     

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiMovePiece	proc	far
	mov	al, ch
	mov	bl, dh
	mov	si, es:[whoseTurn]
	inc	es:[si].SP_numberOfGuys
	mov	cl, es:[si].SP_player
	call	UkiSetNode

	mov	cl, es:[si].SP_pieceColor
	clr	es:[si].SP_noMoveCount
	call	UkiDrawPlayer
		; if we took a hint, then the new piece got drawn over
		; the hint, so mark the hint as BAD_COORD so that it
		; doesn't try to undo it later
	cmp	al, es:[hintMoveCoord].x_pos
	jnz	skiphint
	cmp	bl, es:[hintMoveCoord].y_pos
	jnz	skiphint
	mov	es:[hintMoveCoord].x_pos, BAD_COORD
skiphint:
	call	UkiAffectOpponent
	ret	
UkiMovePiece	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiAffectOpponent

DESCRIPTION:   turn over all captured opponents updating board and screen

PASS:          al,bl = position moved to

RETURN:        

DESTROYED:      

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	
UkiAffectOpponent	proc	near
			
	mov	dl, -1
	mov	dh, -1
checkloop:
	clr	cx
	clr	si
	call	UkiCheckLine
	tst	cl
	jz	cont
	call	UkiDoAffect
cont:
	inc	dl
	cmp	dl, 2
	jl	checkloop
	mov	dl, -1
	inc	dh
	cmp	dh, 2
	jl	checkloop
	ret
	
UkiAffectOpponent	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      	UkiDoAffect

DESCRIPTION:   	turn over opponents along given line

PASS:          	al, bl position moved to
		dl, dh = direction vector
		cl = number of opponents in this row to be affected
RETURN:        

DESTROYED:      

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
UkiDoAffect	proc	near
	uses	ax, bx, dx
	.enter
	cmp	es:[whoseTurn], offset player1
	jnz	doplayer2
	add	es:[player1].SP_numberOfGuys, cx
	sub	es:[player2].SP_numberOfGuys, cx
	jmp	doloop
doplayer2:
	add	es:[player2].SP_numberOfGuys, cx
	sub	es:[player1].SP_numberOfGuys, cx
doloop:
	add	al, dl
	add	bl, dh
	push	cx, dx
	mov	si, es:[whoseTurn]
	mov	cl, es:[si].SP_player
	call	UkiSetNode
	call	UkiDrawCurrentPlayer
	pop	cx, dx
	loop	doloop
	.leave
	ret
UkiDoAffect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      UkiComputerFindBestMove

DESCRIPTION:   find the best move for the computer


PASS:          nothing

RETURN:        si: 0 if no move found, 1 otherwise

DESTROYED:      ???

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiComputerFindBestMove	proc	far
	mov	bx, es:[gameBoard]
	call	MemLock
	mov	ds, ax
	clr	ax
	mov	bx, ax
	mov	si, ax
	mov	es:[bestMoveSoFar], al
	mov	es:[bestMoveCoord].x_pos, BAD_COORD
gridloop:
	call	UkiGetNodeNL
	tst	cl
	jnz	cont
	call	UkiDoBestMoveFromHere
cont:
	inc	al
	cmp	al, es:[cells]
	jl	gridloop
	inc	bl
	clr	al
	cmp	bl, es:[cells]
	jl	gridloop
	mov	bx, es:[gameBoard]
	call	MemUnlock
	ret
UkiComputerFindBestMove	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

FUNCTION:      	UkiDoBestFromHere

DESCRIPTION:   	see if this spot would be valid, and if so get its move value
		if its better than the best move so far then mark it as the
		best move so far

PASS:		al, bl = position 

RETURN:        

DESTROYED:      

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
     

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        jimmy     2/91            initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiDoBestMoveFromHere	proc	near 
	uses si, dx, bp, cx
	.enter
	
	mov	cl, al
	mov	dl, bl
	call	UkiIsClickValidMove

	tst	cl
	jz	done
	
	add	cl, UKI_BASE_MOVE_VALUE 
					; add to cl so base value of a
					; legal move is a value great
					; enough, so that a "bad"
					; move can have a positive value
	call	UkiFindMoveValue
	
	cmp	cl, es:[bestMoveSoFar]
	jl	done
	jg	doNewOne
	cmp	es:[bestMoveCoord].x_pos, BAD_COORD
	jz	doNewOne
	call	FastRandom
	and	dl, UKI_EQUAL_BESTMOVE_FACTOR
	jz	doNewOne
	jmp	done
doNewOne:
	mov	dx, bp
	mov	es:[bestMoveSoFar], cl
	mov	es:[bestMoveCoord].x_pos, al
	mov	es:[bestMoveCoord].y_pos, bl
done:
	.leave
	ret
UkiDoBestMoveFromHere	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiFindMoveValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get the value for a given move

CALLED BY:	GLOBAL

PASS:		al, bl = board position

RETURN:		move value

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	this is my strategy....
	
		a)
			if a move is in the "center" that is, not an edge
			or next to an edge then the move value is worth
			the base value + the number of opponents turned
		b)
			if it is next to an edge than subtract a constant
			value from the number of stones turned
		c)
			if its an edge then calculate the number of neighbors
			along the edge of the opposing player are there,
			if there is one, then the move value is
		
		base value + # players turned - edge_neighbors_constant

			if the value isn't 1, (0 or 2), then the move value is

		base value + edge_constant + # of players turned

		the corners get extra high values

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiFindMoveValue	proc	near
	uses	ax, bx, si
	.enter
	push	ax, bx
	mov	bx, es:[gameBoard]
	call	MemLock
	mov	ds, ax
	pop	ax, bx
	clr	ah
	mov	bh, ah
	mov	dx, 0
	mov	si, ax
	call	UkiFindMoveValueHelp
	mov	dx, 1
	mov	si, bx
	call	UkiFindMoveValueHelp
	tst	cl
	jg	done
	mov	cl, 1
done:
	mov	bx, es:[gameBoard]
	call	MemUnlock
	.leave
	ret
UkiFindMoveValue	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiFindMoveValueHelp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	helper routine for finding out a moves value

CALLED BY:	????

PASS:		al, bl = board position
		dl = horizontal edge(1) or vertical edge (0)
		cl = move value so far
		si = relevent coordinate
		ds = gameBoard segment
		es = dgroup

RETURN:		cl = move value

DESTROYED:	dx

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UkiFindMoveValueHelp	proc	near
	uses	ax, bx
	.enter
	; if si is zero we are at an edge so find value of edge position
	tst	si
	jnz	testALhigh	; else cont
	; if an edge has one opponent by it then its not "safe"
	call	UkiCaptureEdgeNeighbors
	call	UkiCheckEdgeNeighbors	
	cmp	dh, 1		; as long as not one neighbor, safe move
	jnz	doEdgeValue
	; if the edge has 1 neighbor then make the move value lower
	sub	cl, UKI_EDGE_NEIGHBORS_VALUE
	jmp	done
doEdgeValue:
	; if its a "safe" edge, add some value to the move, this changes
	; of time
	add	cl, es:[generalValue2]
	jmp	done
testALhigh:
	; if si+1 == cells we are at an edge so find edge position value
	xchg	ax, si
	inc	al
	cmp	al, es:[cells]
	xchg	ax, si
	jnz	checkAL2	; else cont
	call	UkiCaptureEdgeNeighbors
	call	UkiCheckEdgeNeighbors
	cmp	dh, 1
	jnz	doEdgeValue
checkAL2:
	dec	si 	; restore si to passed in value
	; if si == 1 we are next to an edge so subtract from the move value
	cmp	si, 1
	jnz	checkALHigh2
doNextToEdge:
	tst	dl
	jz	doVertical
checkNextToCorner:
	cmp	al, 1
	jz	nextToCorner
	mov	bl, al
	inc	al
	cmp	al, es:[cells]
	jnz	notNextToCorner
nextToCorner:
	sub	cl, 20
	jmp	done
notNextToCorner:
	sub	cl, UKI_NEXT_TO_EDGE_VALUE
	jmp	done
doVertical:
	xchg	ax, bx
	jmp	checkNextToCorner
checkALHigh2:
	; if si+2 == cells we are enxt to an edge so subtract from move value
	add	si, 2
	xchg	ax, si
	cmp	al, es:[cells]
	xchg	ax, si
	jnz	done
	jmp	doNextToEdge
done:
	.leave
	ret
UkiFindMoveValueHelp	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiCaptureEdgeNeighbors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	????

PASS:		al, bl = board position
		dl = 0 for vertical edge, 1 for horizontal edge

RETURN:		cl = new move value

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/18/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCaptureEdgeNeighbors	proc	near
	uses	ax, bx, dx, si
	.enter
	push	cx
	tst	dl
	jz	doVertical
	clr	dh
	mov	dl, -1
	clr	cl
	call	UkiCheckLine
	mov	dh, 1
common:
	call	UkiCheckLine
	tst	cl
	pop	cx
	jz	done
	add	cl, UKI_CAPTURE_EDGE_VALUE
	jmp	done
doVertical:
	clr	dl
	mov	dh, -1
	clr	cl
	call	UkiCheckLine
	mov	dl, 1
	jmp	common	
done:
	.leave
	ret
UkiCaptureEdgeNeighbors	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UkiCheckEdgeNeighbors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	????

PASS:		al, bl = board position
		dl = 0 for vertical edge, 1 for horizontal edge

RETURN:		dh = number of opposing neighbors 0, 1 or 2 
		ds = gameBoard segment
		es = dgroup

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	????

KNOWN BUGS/SIDEFFECTS/IDEAS:	????

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/13/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UkiCheckEdgeNeighbors	proc	near
	uses	ax, bx, cx
	.enter
	mov	si, es:[whoseTurn]
	clr	dh		; init our edge neighbors value to zero
	tst	dl		; check to see if we are doing vertical
	jnz	doHoriz		; or horizontal

	; if we are doing a horizontal edge the first test to see
	; if bl is zero, if so then check below (since the upper left
	; corner is [0,0]) else check "above"
	tst	bl
	jz	checkBelow
	; set al, bl to cell above this cell
	dec	bl
	; set the current state of that cell
	call	UkiGetNodeNL

	; if that cell is empty, then there is no neigbor
	; else check to see if it is an oppoising neighbor or a friendly
	; one, if opposing, then increment dh else cont
	tst	cl
	jz	checkBelowIncBL
	and	cl, es:[si].SP_player
	and	cl, 0xf0	; zero out non relevant bits
	tst	cl
	jnz	checkBelowIncBL
	inc	dh
checkBelowIncBL:
	inc	bl
checkBelow:
	; if we are at the bottom of the board, don't check beyond boundary
	inc	bl
	cmp	bl, es:[cells]
	jz	done
	; else get the cell node and check for noeghbors
	call	UkiGetNodeNL
	tst	cl
	; if a neighbor, check for friendliness
	jz	done
	and	cl, es:[si].SP_player
	and	cl, 0xf0	; zero out non relevant bits
	tst	cl
	jnz	done
	inc	dh
	jmp	done
doHoriz:
	; check left boundary
	tst	al
	; if at check do right
	jz	checkRight
	; else get node and check for neighbors
	dec	al
	call	UkiGetNodeNL
	tst	cl
	; if neighbor, check for friendliness
	jz	checkRightIncAL
	and	cl, es:[si].SP_player
	and	cl, 0xf0	; zero out piece type info
	tst	cl
	jnz	checkRightIncAL
	inc	dh
checkRightIncAL:
	inc	al
checkRight:
	; now check right boudary
	inc	al
	cmp	al, es:[cells]
	jz	done
	; if within boundary get node data
	call	UkiGetNodeNL
	; check for neighbors
	tst	cl
	jz	done
	; if neighbors, check for friendliness
	and	cl, es:[si].SP_player
	and	cl, 0xf0
	tst	cl
	jnz	done
	inc	dh
	jmp	done
done:		
	.leave
	ret
UkiCheckEdgeNeighbors	endp

UkiCode	ends

	

