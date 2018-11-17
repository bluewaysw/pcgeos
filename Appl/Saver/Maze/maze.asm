COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

PROJECT:	After Hours Anarchy
MODULE:		Maze program
FILE:		maze.asm

Author		Jimmy Lefkowitz, January 14, 1991

Revision History:
	Name	Date		Description
	----	----		-----------
	jimmy	4/8/91		initial version

DESCRIPTION:
	$Id: maze.asm,v 1.1 97/04/04 16:45:50 newdeal Exp $
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;----------------------------------------------------------------------
;			Common Geode Stuff
;----------------------------------------------------------------------

_Application		 = 1

include stdapp.def
include timer.def
include Objects/winC.def

UseLib saver.def

include	maze.def

;=============================================================================
;
;			VARIABLES
;
;=============================================================================

include maze.rdef

udata segment
	MazeFringe	hptr
	MazeData	hptr		
	maxWidth 	byte			;maximun x value (interior)
	maxHeight 	byte			;maximun y value (interior)
	Hand		byte			;which algorithm to solve with
	Start		byte			;y value of entrance to maze
	ExitY		byte			;y value of exit of maze + 1
	ExitX		byte			;y value of exit of maze + 1
	timerID		word	
	timerHandle	hptr	
	saverGState	hptr	
	WallWidth	word			;pixel width of wall segment
	WallHeight	word			;pixel height of wall segment
	randomSeed	word			; seed for random numbers
	Xstart		word	
	Ystart		word		
	solving		byte
	leftSolver	MazeSolver
	rightSolver	MazeSolver
udata ends


idata segment

	MazeProcessClass	mask CLASSF_NEVER_SAVED	
	MazeApplicationClass
idata ends

CommonCode 	segment resource

MazeGrDrawLine MACRO	x1, y1, x2, y2
	mov	ax, es:[x1]
	mov	bx, es:[y1]
	mov	cx, es:[x2]
	mov	dx, es:[y2]
	call	GrDrawLine
ENDM

.warn	-private
mazeOptionTable	SAOptionTable	<
	mazeCategory, length mazeOptions
>
mazeOptions	SAOptionDesc	<
>

.warn @private
mazeCategory	char	'maze', 0

include	mzsolve.asm
include mazeScreenSave.asm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FastRandom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	pseudo-random number generator

CALLED BY:	GLOBAL
PASS:		es = dgroup
RETURN:		dx = random number
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MAGIC16_SEED	equ	2b41h	    	; magic seed

FastRandom 	proc	near 
	uses	bx, ax
	.enter
	mov	dx, 0fffh
	mov	bx, es:[randomSeed]
	call	SaverRandom
	.leave
	ret
FastRandom	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeBlankScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	blanks out the screen

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/25/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeBlankScreen	proc	near
	mov	al, C_BLACK
	mov	ah, CF_INDEX			; initial colors
	call	GrSetLineColor
	mov	dx, 1
	clr	ax
	call	GrSetLineWidth
	mov	al, MM_COPY
	call	GrSetMixMode		; init gstate
	call	WinGetWinScreenBounds
	call	GrFillRect			; blank screen
	ret
MazeBlankScreen		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeMakeGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets up a new maze but doesn't draw to screen

CALLED BY:	global

PASS:		nothing
		

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeMakeGrid	proc far
mazeSize	local	byte
drawMazeMode	local	byte
inputFringe	local	word
outputFringe	local	word
	.enter
getSize:
	mov	ax, MAZE_SIZE
	call	FastRandom
	and	al, dl
	cmp	al, 8
	jl	getSize
	mov	mazeSize, al
	call	FastRandom
	and	dl, 15
	mov	drawMazeMode, dl

	mov	di, es:[saverGState]

	; depending on the maze size, the possible positions for the upper
	; left corner vary as we always want to keep everything on the screen
	; but allow the maze to bounce around as much as possible
	call	MazeInitMazeSize	; ax, bx = x, y freedoms

	; now that we have the range of possible values, randomly pick one
	call	FastRandom
	and	dx, ax
	; add in the wall width as we might want to cheat
	add	dx, es:[WallWidth]
	mov	es:[Xstart], dx
	call	FastRandom
	and	dx, bx
	; add in the wall width as we might want to cheat
	add	dx, es:[WallHeight]
	mov	es:[Ystart], dx
afterFreedom:
	call	MazeBlankScreen
	mov	al, C_WHITE
	mov	ah, CF_INDEX			; initial colors
	call	GrSetLineColor
	clr	ax
	mov	inputFringe, ax
	mov	outputFringe, ax
	mov	es:[Start], al
	mov	es:[ExitY], al

	; clear out the board
	mov	bx, es:[MazeData]
	push	es, di
	call	MemLock
	mov	es, ax
	clr	di		
	mov	ax, MAXDATA * MAXDATA
	mov	cx, ax
	shr	cx, 1				; clear it in words
	clr	ax
	rep     stosw 				; zero out state variables
	call	MemUnlock
	pop	es, di

	mov	al, mazeSize
	shr	al
	mov	bl, mazeSize
	shr	bl
	call	MazeInputFringe		; input starting point to fringe
mainLoop:
	call	MazeOutputFringe		; main loop, loop until fringe
	mov	dl, mask MZN_maze		; has no more entries
	mov	dh, 1
	call	MazeSetNode			; set bit for current x,y
	mov	cl, drawMazeMode
	call	MazeDoWall			; main body of algorithm
	call	MazeInputNeighborsFringe	; put neighbors on fringe
	mov	cx, inputFringe
	mov	dx, outputFringe
	cmp	cx, dx
	jnz	mainLoop
	.leave
	ret
MazeMakeGrid	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeDoEdge
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	lights up edges of maze

CALLED BY:	MazeDoWall

PASS:		ax = x position
		bx = y position

RETURN:		nothing
DESTROYED:	oh god this program sucks

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeDoEdge	proc	near
	tst	ax
	jnz	tryTopEdge		; sees if we are at the edge
	tst	es:[Start]		; sees if there is already an entrance
	jz	addStart
addLeftEdge:
	mov	dl, mask MZN_vert	
	mov	dh, 1
	call	MazeSetNode		; add vertical wall
	call	MazeDrawNode		; draw vertical wall
	jmp	tryTopEdge
addStart:
	mov	es:[Start], bl
	inc	es:[Start]
tryTopEdge:
	tst	bx			; sees if we are at edge
	jnz	tryRightEdge
	mov	dl, mask MZN_horz
	mov	dh, 1
	call	MazeSetNode		; add horizontal wall
	call	MazeDrawNode		; draw horizontal wall
tryRightEdge:
	cmp	al, es:[maxWidth]	; sees if we are near edge
	jl	tryBottomEdge
	tst	es:[ExitY]		; sees if we have an exit yet
	jz	addExit
addRightEdge:
	mov	dl, mask MZN_vert	
	mov	dh, 1
	inc	ax
	call	MazeSetNode		; add vertical wall
	call	MazeDrawNode		; draw vertical wall
	dec	ax
	jmp	tryBottomEdge
addExit:
	mov	es:[ExitY], bl		; right corner
	inc	es:[ExitY] 
	push	ax
	mov	al, es:[maxWidth]
	mov	es:[ExitX], al
	pop	ax
tryBottomEdge:
	cmp	bl, es:[maxHeight]	; sees is we are at the edge
	jl	done
	mov	dl, mask MZN_horz
	mov	dh, 1
	inc	bx
	call	MazeSetNode		; adds horizontal wall
	call	MazeDrawNode		; draw horizontal wall
	dec	bx
done:
	ret
MazeDoEdge		endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeDoWall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	choose which walls to light

CALLED BY:	MazeMakeGrid

PASS: 		ax: x position
		bx: y position
		cl: drawMazeMode (used by MazeChooseWall)

RETURN:		nothing
DESTROYED:	my sanity

PSEUDO CODE/STRATEGY:

description of algorithm:
	when we add a point to the "maze" we must decide which walls
	to add, the number of walls to add is always one less than the
	number of neighbors already in the "maze", so i first go
	through and count the number of neighbors already in the
	"maze" and light  bit in ch for each one that is there, then
	i randomly chooes one of those bits and turn it off, that being
	the one passage that connests that node to the rest of the
	"maze", then this ch is passed on to MazeChooesWall which adds
	the apprpriate walls according to which bits in ch are still lit

	this code is somewhat convoluted, but i wanted to add as much
	randomness as possible, orderly code would not have had this
	affect...:)

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jimmy	long ago		wrote it
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeDoWall	proc	near
firstWall	local	byte
secondWall	local	byte
thirdWall	local	byte
drawMazeMode	local	byte
	uses ax, bx
	.enter
	mov	drawMazeMode, cl
	call	MazeDoEdge
;	clr	es:[FirstW]
;	clr	es:[SecondW]
;	clr	es:[ThirdW]
	clr	cx
	mov	firstWall, cl
	mov	secondWall, cl
	mov	thirdWall, cl

	inc	ax
	push	cx
	mov	cl, mask MZN_maze
	call	MazeTestNode		; test neighbor (x+1,y)
	pop	cx
	tst	dl
	jz	$10
	or	ch, 1
	mov	firstWall, 14
	inc	cl
$10:
	sub	ax, 2
	push	cx
	mov	cl, mask MZN_maze
	call	MazeTestNode		; test neighbor (x-1, y)
	pop	cx
	tst	dl
	jz	$20
	or	ch, 2
	inc	cl
	tst	firstWall
	jz	$15
	mov	secondWall, 13
	jmp	$20
$15:
	mov	firstWall, 13
$20:
	inc	ax

	inc	bx
	push	cx
	mov	cl, mask MZN_maze
	call	MazeTestNode		; test neighbor	(x, y+1)
	pop	cx
	tst	dl
	jz	$30
	or	ch, 4
	inc	cl
	tst	firstWall
	jz	$28
	tst	secondWall
	jz	$25
	mov	thirdWall, 11
	jmp	$30
$25:
	mov	secondWall, 11
	jmp	$30
$28:
	mov	firstWall, 11
$30:
	sub	bx, 2
	push	cx
	mov	cl, mask MZN_maze
	call	MazeTestNode		; test neighbor (x, y-1)
	pop	cx
	tst	dl
	jz	$40
	or	ch, 8
	inc	cl
	tst	firstWall
	jz	$38
	tst	secondWall
	jz	$35
	tst	thirdWall
	jnz	$40
	mov	thirdWall, 7
	jmp	$40
$35:
	mov	secondWall,7
	jmp	$40
$38:
	mov	firstWall, 7
$40:
					; now choose a bit to turn off
	inc	bx
	call	FastRandom		

	cmp	cl, 2
	jl	$95
	jz	$80
	cmp	cl, 3
	jz	$70
	call	FastRandom
	and	dl, 3
	tst	dl
	jnz	$71
	and	ch, 7
	jmp	$91
$70:
	call	FastRandom
	and	dl, 3
	jz	$70
$71:
	cmp	dl, 3
	jz	$87
	cmp	dl, 2
	jz	$81
	jmp	$85	
	
$80:	
	and	dl, 1
	jz	$85
$81:
	mov	cl, secondWall
	jmp	$90
$85:
	mov	cl, firstWall
	jmp	$90
$87:
	mov	cl, thirdWall
$90:
	and	ch, cl
$91:
	mov	cl, drawMazeMode
	call 	MazeChooseWall
$95:
	.leave
	ret
MazeDoWall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeChooseWall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	chooses walls to light

CALLED BY:	MazeDoWall

PASS:		ax = x position
		bx = y position
		cl = mask of which walls to put up
		dl = drawMazeMode

RETURN:		hooey

DESTROYED:	hooey

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeChooseWall	proc 	near
	
	mov	dl, ch			; add wall for (x+1, y) ?
	and	dl, mask MZN_right
	jz	tryLeft
	inc	ax
	mov	dh, 1
	mov	dl, mask MZN_vert
	call	MazeSetNode
;	tst	es:[drawMazeMode]
	tst	cl
	jz	skipDrawRight
	call	MazeDrawNode
skipDrawRight:
	dec	ax
tryLeft:	

	mov	dl, mask MZN_left		; add wall for (x-1, y) ?
	and	dl, ch
	tst	dl
	jz 	tryDown
	mov	dh, 1
	mov	dl, mask MZN_vert
	call	MazeSetNode
;	tst	es:[drawMazeMode]
	tst	cl
	jz	tryDown
	call	MazeDrawNode
tryDown:
	mov	dl, mask MZN_down		; add wall for (x, y+1) ?
	and	dl, ch
	tst	dl
	jz	tryUp
	inc	bx
	mov	dl, mask MZN_horz
	mov	dh, 1
	call	MazeSetNode
;	tst	es:[drawMazeMode]
	tst	cl
	jz	skipDrawDown
	call	MazeDrawNode
skipDrawDown:
	dec	bx
tryUp:
	mov	dl, mask MZN_up			; add wall for (x, y-1) ?
	and	dl, ch
	tst	dl
	jz	done
	mov	dl, mask MZN_horz
	mov	dh, 1
	call	MazeSetNode
;	tst	es:[drawMazeMode]
	tst	cl
	jz	done
	call	MazeDrawNode
done:
	ret
MazeChooseWall		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeFringeNeighbor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	adds a node to the fringe if it hasn't been there

CALLED BY:	MazeInputFringeNeighbors

PASS:		ax = x position
		bx = y position

RETURN:		nothing

DESTROYED:	arglebargle

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeFringeNeighbor	proc	near
	.enter inherit MazeMakeGrid
	mov	cl, mask MZN_fringe or mask MZN_maze
	call	MazeTestNode			
					; if this neghbor has not 
	tst	dl			; already been in the fringe
	jnz	done			; add it to the fringe
	push	ax, bx
	call	MazeInputFringe
	pop	ax, bx
done:	
	.leave
	ret
MazeFringeNeighbor		endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeInputFringeNeighbors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	add neighbors to fringe

CALLED BY:	MazeMakeGrid

PASS:		ax = x position
		bx = y position

RETURN:		nothing

DESTROYED:	lots o' things

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeInputNeighborsFringe	proc	near
	uses	ax, bx
	.enter
	add	ax, 1			; add neighbor (x+1, y)
	call	MazeFringeNeighbor

	sub	ax, 2			; add neighbor (x-1, y)
	call	MazeFringeNeighbor

	add	ax, 1
	add	bx, 1			; add neighbor (x, y+1)
	call	MazeFringeNeighbor

	sub	bx, 2			; add neighbor (x, y-1)
	call	MazeFringeNeighbor
	.leave
	ret
MazeInputNeighborsFringe		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeInputFringe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	decide where to actually put in new node, and do it.

CALLED BY:	MazeFringeNeighbor

PASS:		ax = x position
		bx = y position

RETURN:		nothing
DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeInputFringe	proc	near
	uses	ds
	.enter inherit MazeMakeGrid
	cmp	ax, 0
	jl	done
	cmp	bx, 0
	jl	done
	cmp	al, es:[maxWidth]
	jg	done
	cmp	bl, es:[maxHeight]     ; checks boundaries
	jg	done
	push	ax, bx
	mov	bx, es:[MazeFringe]
	call	MemLock
	mov	ds, ax			; ds:0 = MazeFringe
	pop	ax, bx

	mov	dl, mask MZN_fringe
	mov	dh, 1
	call	MazeSetNode		; sets fringe bit
	call	FastRandom		; randomly adds to beginning or
	and	dx, 1			; end of fringe list, if there
	jz	addAtEnd		; is no room at beginning adds to end
addAtFront:
	push	ax, bx
	mov	ax, MAXDATA
	mov	bx, ax
	mul	bx
	cmp	inputFringe, ax
	pop	ax, bx
	jg	addAtEnd
	mov	dl, bl			; add to end on fringe
	mov	bx, inputFringe
	mov	ds:[bx], al	
	add	bx, 1
	mov	ds:[bx], dl
	add	bx, 1
	mov	inputFringe, bx	; update input fringe pointer
	jmp	doneUnlock
addAtEnd:
	tst	outputFringe	; add to beginning if room
	jz	addAtFront
	mov	dl, bl
	mov	bx, outputFringe
	sub	bx, 2
	mov	outputFringe, bx
	mov	ds:[bx], al
	inc	bx
	mov	ds:[bx], dl
doneUnlock:
	mov	bx, es:[MazeFringe]
	call	MemUnlock
done:
	.leave
	ret
MazeInputFringe 	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeOutputFringe
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	get next element from fringe list

CALLED BY:	MazeMakeGrid

PASS:		nothing

RETURN:		ax = x position
		bx = y position

DESTROYED:	nothing?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeOutputFringe proc	near
	uses	ds
	.enter inherit MazeMakeGrid
	mov	bx, es:[MazeFringe]
	call	MemLock
	mov	ds, ax

	mov	bx, outputFringe
	clr	ax
	mov	al, ds:[bx]
	inc	bx
	clr	dx
	mov	dl, ds:[bx]
	inc	bx
	mov	outputFringe, bx		; update pointer
	mov	bx, dx
	
	push	bx
	mov	bx, es:[MazeFringe]
	call	MemUnlock
	pop	bx
	.leave
	ret	
MazeOutputFringe 	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeDrawNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	draw one vertical and/or one horizontal wall

CALLED BY:	MazeDrawGrid

PASS:		ax = x position
		bx = y position

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeDrawNode	proc near
	uses	ax, bx, cx
	.enter
	mov	cl, mask MZN_horz
	call	MazeTestNode		; checks for horizontal wall
	tst	dl
	jz	tryVertical
	push  	ax, bx
	push  	ax
	mov	ax, bx
	mov	cx, es:[WallHeight]
	mul	cx		; ax = cx * ax
	mov	bx, ax
	pop 	ax
	mov	cx, es:[WallWidth]
	mul	cx
	add	ax, es:[Xstart]
	add	bx, es:[Ystart]
	mov	cx, ax			; pixel calculations
	mov	dx, bx
	add	cx, es:[WallWidth]
	call	GrDrawLine		; draw wall
	pop	ax, bx
tryVertical:
	mov	cl, mask MZN_vert
	call	MazeTestNode		; checks to see if vertical wall exists
	tst	dl
	jz	done
	push 	ax
	mov	ax, bx
	mov	cx, es:[WallHeight] 
	mul	cx
	mov_tr	bx, ax
	pop	ax
	mov	cx, es:[WallWidth]
	mul	cx
	add	ax, es:[Xstart]
	add	bx, es:[Ystart]		; pixel calculations
	mov	cx, ax
	mov	dx, bx
	add	dx, es:[WallHeight]	
	call	GrDrawLine		; draw wall
done:
	.leave
	ret
MazeDrawNode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeIndexMaze
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	index into the maze given coordinates

CALLED BY:	MazeTestNode/MazeSetNode

PASS:		al, bl = maze coordinates

RETURN:		si = index

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	6/ 1/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeIndexMaze	proc	near
	uses	ax, bx
	.enter
	clr	ah
	mov	bh, ah
;	sub	ax, es:[Xmin]
;	sub	bx, es:[Ymin]
	inc	ax
	inc	bx
	push	bx
;	mov	bl, es:[yMax]
;	inc	bx
	mov	bl, es:[maxHeight]
	add	bl, 2
	mul	bl
	pop	bx
	add	bx, ax			; pointer calculation
	mov	si, bx
	.leave
	ret
MazeIndexMaze	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeSetNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sets a node in the MazeData structure

CALLED BY:	MazeMakeGrid

PASS:		ax = x position
		bx = y position
		dl = bit to set or unset
		dh = set or unset

RETURN:		nothing

DESTROYED:	all

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeSetNode  proc near
	uses	ax, bx, cx, si, es
	.enter
	call	MazeIndexMaze	; si = index into maze
	mov	bx, es:[MazeData]
	call	MemLock
	mov	es, ax

	tst	dh
	jz	unset
;set:
	mov	al, es:[si]
	or	al, dl			; set bit
	mov	es:[si], al
	jmp	done
unset:	
	mov	al, es:[si]
	not	dl			
	and	al, dl			; turn off bit
	mov	es:[si],al
done:
	call	MemUnlock
	.leave
	ret
MazeSetNode	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeTestNode
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	tests a node in the MazeData structure

CALLED BY:	MazeDrawNode

PASS:		al = x position
		bl = y position
		cl = which field(s) to test

RETURN:		dl = true if any fields in cl are set at (x,y)

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeTestNode proc near
	uses	ax, bx, es, si
	.enter
	clr	dl		; assume nothing there if not in maze
	tst	al
	jl	done
	tst	bl
	jl	done
	call	MazeIndexMaze	; si = index into maze
	mov	bx, es:[MazeData]
	call	MemLock
	mov	es, ax
	mov	dl, es:[si]		; test data
	call	MemUnlock
	and	dl, cl
done:
	.leave
	ret
MazeTestNode	endp

CommonCode 	ends
