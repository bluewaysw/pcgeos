COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		maze screen saver
FILE:		mzsolve.asm

AUTHOR:		Steve Yegge, Dec 20, 1992

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	4/8/91		initial version
	stevey	12/20/92	port to 2.0 + file header

DESCRIPTION:
	

	$Id: mzsolve.asm,v 1.1 97/04/04 16:45:48 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeInitSolve
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	initialize the solver(s)

CALLED BY:	MazeStep

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/26/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeInitSolve	proc	near
	mov	di, es:[saverGState]
	clr	al
	add	al, 4			; CGA, writing on black background
	call	GrSetLineColorMap
if 0
	cmp	es:[WallHeight], 5
	jg	doThickLine
	mov	dx, 2
	jmp	setThickness
doThickLine:
	mov	dx, 3
setThickness:
endif
	mov	dx, es:[WallWidth]
	sub	dx, 2
	clr	ax
	call	GrSetLineWidth
	mov	al, MM_XOR
	call	GrSetMixMode		; init gstate

	cmp	es:[Hand], LEFTSOLVER
	je	doLeft
	
	tst	es:[rightSolver].MS_cheat ; init start direction, right hand
	jnz	rightCheat		; if cheating, init direction is
	mov	cl, mask MZN_down	; opposite of normal init direction
	jmp	initRight
rightCheat:
	mov	cl, mask MZN_left
	mov	es:[leftSolver].MS_done, 1
	mov	es:[Hand], RIGHTSOLVER
initRight:	
	clr	ax
	clr	bx
	mov	bl, es:[Start]		; get start position
	dec	bl
	mov	es:[rightSolver].MS_xpos, al	; context switch for racing
	mov	es:[rightSolver].MS_ypos, bl		; algorithms
	mov	es:[rightSolver].MS_direction, cl
	cmp	es:[Hand], RIGHTSOLVER or LEFTSOLVER
					; test for whether both alorithms
	jne	done			; are running
doLeft:
	tst	es:[leftSolver].MS_cheat	
					; init start direction, left hand
	jnz	leftCheat		; same as right hand but opposite
	mov	cl, mask MZN_up
	jmp	initLeft
leftCheat:
	mov	cl, mask MZN_left
	mov	es:[Hand], LEFTSOLVER
	mov	es:[rightSolver].MS_done, 1
initLeft:
	clr	ax
	clr	bx
	mov	bl, es:[Start]
	dec	bl
	mov	es:[leftSolver].MS_xpos, al	; more context switch stuff
	mov	es:[leftSolver].MS_ypos, bl
	mov	es:[leftSolver].MS_direction, cl
done:
	ret
MazeInitSolve	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeSolveOneStep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take one step forward in the Maze

CALLED BY:	MazeSolveFourSteps

PASS:		es:si = MazeSolver

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/26/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeSolveOneStep	proc	near
	tst	es:[si].MS_done
	jnz	checkOtherGuy
	clr	ax
	mov	bx, ax
	mov	cx, ax
	mov	al, es:[si].MS_xpos		; context switch
	mov	bl, es:[si].MS_ypos
	mov	cl, es:[si].MS_direction
;	tst	es:[saverWindow]
;	jz	done
	cmp	es:[si].MS_whoami, LEFTSOLVER
	jnz	doRight
	call	MazeGoForwardLeft			; right hand loop
	jmp	cont
doRight:
	call	MazeGoForwardRight
cont:
	push	cx
	call	MazeIsDone			; test for finish
	tst 	cl
	pop	cx
	jnz	mazeDone
	mov	es:[si].MS_xpos, al			; context switch stuff
	mov	es:[si].MS_ypos, bl
	mov	es:[si].MS_direction, cl
	jmp	done
mazeDone:
	mov	es:[si].MS_done, 1			; set right hand done
done:
	ret

checkOtherGuy:
	cmp	es:[si].MS_whoami, LEFTSOLVER
	jne	checkleft
	tst	es:[rightSolver].MS_done
	jmp	testdone
checkleft:
	tst	es:[leftSolver].MS_done
testdone:
	jz	mazeDone
	clr	es:[solving]
	jmp	mazeDone
MazeSolveOneStep	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeSolveOneStepLeft
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	have the left hand solver take a step

CALLED BY:	MazeStep

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/26/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeSolveOneStepLeft 	proc	near
	mov	si, offset leftSolver
	call	MazeSolveFourSteps
	ret
MazeSolveOneStepLeft	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeSolveOneStepRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	have the right solver take a step

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/26/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeSolveOneStepRight 	proc	near
	mov	si, offset rightSolver
	call	MazeSolveFourSteps
	ret
MazeSolveOneStepRight	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeSolveFourSteps
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take four steps in a row

CALLED BY:	GLOBAL

PASS:		es:si = MazeSolver

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/26/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeSolveFourSteps proc	near
	call	MazeSolveOneStep
	call	MazeSolveOneStep
	call	MazeSolveOneStep
	call	MazeSolveOneStep
	ret
MazeSolveFourSteps	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
			MazeIsDone

	SYNOPSIS:	tests for exit

	CALLED BY:

	PASS:         

			ax: xposition
			bx : y position
	RETURN

			cl: 1 = done, 0 = not done
	Known BUGS/SIDE EFFECTS/IDEAS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeIsDone	proc	far
	uses	ax, bx
	.enter
	inc	bx
	mov	dl, es:[ExitY]		; test current value against exit
	cmp	bl, dl
	jnz	nope
	mov	dl, es:[ExitX]
	cmp	al, dl
	jnz	nope
	mov	cl, 1
done:
	.leave
	ret
nope:
	mov	cl, 0
	jmp	done
MazeIsDone	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeGoForwardRight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	makes next step in right hand algorithm

CALLED BY:	MazeDrawSolution

PASS:         	ax: x position
		bx: y position
		cl: direction

RETURN:		ax: new x position
		bx: new y position
		cl new direction

DESTROYED:	dx?

PSEUDO CODE/STRATEGY:

	if we can move forward, then we go forward, then
	we turn right and try to go forward again
	if we can't go forward, we turn to the left and try to go
	forward

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	Since the maze is guaranteed to have a solution this
	algorithm needs no memory of where's its been

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeGoForwardRight 	proc far

	mov	di, es:[saverGState]
	push	ax
	mov	al, C_LIGHT_RED
	mov	ah, CF_INDEX
	call	GrSetLineColor
	pop	ax
	cmp	cl, mask MZN_right		; try to go right ?
	jnz	tryDown
	inc	ax
	mov	cl, mask MZN_vert		; test for wall
	call	MazeTestNode
	dec	ax
	tst	dl
	mov	cl, mask MZN_up			; if we can't go,try up
	LONG jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	add	cx, es:[WallWidth]
	mov	dx, bx
	call	GrDrawLine			; go forward
	pop	ax, bx
	inc	ax
	mov	cl, mask MZN_down		; turn down
	jmp	done
tryDown:
	cmp	cl, mask MZN_down		; try down ?
	jnz	tryLeft

	inc	bx
	mov	cl, mask MZN_horz	
	call	MazeTestNode			; test for wall
	dec	bx
	tst	dl
	mov	cl, mask MZN_right		; if we can't go, try right
	jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	mov	dx, bx
	add	dx, es:[WallHeight]
	call	GrDrawLine			; go forward
	pop	ax, bx
	inc	bx
	mov	cl, mask MZN_left		; turn left
	jmp	done
tryLeft:
	cmp	cl, mask MZN_left		; try left?
	jnz	tryUp
	push	ax, bx
	mov	cl, mask MZN_vert		
	call	MazeTestNode			; test for wall
	pop	ax, bx
	tst	dl
	mov	cl, mask MZN_down		; if we can't go, try down
	jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	sub	cx, es:[WallWidth]
	mov	dx, bx
	call	GrDrawLine			; go forward
	pop	ax, bx
	dec	ax
	mov	cl, mask MZN_up			; turn up
	jmp	done
tryUp:
	cmp	cl, mask MZN_up			; try up?
	jnz	done
	mov	cl, mask MZN_horz
	call	MazeTestNode			; test for wall
	tst	dl
	mov	cl, mask MZN_left		; if we can't go, try left
	jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	mov	dx, bx
	sub	dx, es:[WallWidth]
	call	GrDrawLine			; go forward
	pop	ax, bx
	dec	bx
	mov	cl, mask MZN_right		; turn right
done:
	ret
MazeGoForwardRight		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeGoForwardLeft 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
SYNOPSIS:	makes next step in left hand algorithm 
		(same as MazeGoForwardRight but opposite directions)
		
CALLED BY:	MazeDrawSolution

PASS:		ax: x position
		bx: y position
		cl: direction

RETURN: 	ax: new x position
		bx: new y position
		cl new direction

DESTROYED:	dx?

PSEUDO CODE/STRATEGY:

	if we can move forward, then we go forward, then
	we turn left and try to go forward again
	if we can't go forward, we turn to the right and try to go
	forward.

KNOWN BUGS/SIDE EFFECTS/IDEAS:

	since the maze is guaranteed to have a solution this
	algorithm needs no memory of where's its been

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92	port to 2.0 + fixed header
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeGoForwardLeft 	proc far

	mov	di, es:[saverGState]
	push	ax
	mov	al, C_LIGHT_BLUE
	mov	ah, CF_INDEX
	call	GrSetLineColor
	pop	ax
	cmp	cl, mask MZN_right
	jnz	tryDown
	inc	ax
	mov	cl, mask MZN_vert
	call	MazeTestNode
	dec	ax
	tst	dl
	mov	cl, mask MZN_down
	LONG jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	add	cx, es:[WallWidth]
	mov	dx, bx
	call	GrDrawLine
	pop	ax, bx
	inc	ax
	mov	cl, mask MZN_up
	jmp	done
tryDown:
	cmp	cl, mask MZN_down
	jnz	tryLeft
	inc	bx
	mov	cl, mask MZN_horz	
	call	MazeTestNode
	dec	bx
	tst	dl
	mov	cl, mask MZN_left
	jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	mov	dx, bx
	add	dx, es:[WallHeight]
	call	GrDrawLine
	pop	ax, bx
	inc	bx
	mov	cl, mask MZN_right
	jmp	done
tryLeft:
	cmp	cl, mask MZN_left
	jnz	tryUp
	mov	cl, mask MZN_vert
	call	MazeTestNode
	tst	dl
	mov	cl, mask MZN_up
	jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	sub	cx, es:[WallWidth]
	mov	dx, bx
	call	GrDrawLine
	pop	ax, bx
	dec	ax
	mov	cl, mask MZN_down
	jmp	done
tryUp:
	cmp	cl, mask MZN_up
	jnz	done
	mov	cl, mask MZN_horz
	call	MazeTestNode
	tst	dl
	mov	cl, mask MZN_right
	jnz	done
	push	ax, bx
	call	MazeGetCoord
	mov	cx, ax
	mov	dx, bx
	sub	dx, es:[WallWidth]
	call	GrDrawLine
	pop	ax, bx
	dec	bx
	mov	cl, mask MZN_left
done:

	ret
MazeGoForwardLeft		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeGetCoord
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	calculates pixel coordinates

CALLED BY:	

PASS:		ax = x position
		bx = y position

RETURN:		ax = x pixel
		bx = y pixel

DESTROYED:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/20/92		port to 2.0 + header

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeGetCoord	proc	far

	; add a hack for cheating...

	inc	al
	inc	bl

	clr	ah
	clr	bh
	push	ax
	mov	ax, bx					
	mov	cx, es:[WallHeight]		
	mul	cx				
	mov	bx, ax				; bx <- bx * WallHeight
	shr	cx
	add	bx, cx				; bx <- bx + WallHeight/2
	pop	ax
	mov	cx, es:[WallWidth]
	mul	cx				; ax <- ax * WallWidth
	shr	cx
	add	ax, cx				; ax <- ax + WalWidth/2
	add	ax, es:[Xstart]			; mov over entire grid
	add	bx, es:[Ystart]			; to start at (Xstart,Ystart)

	sub	ax, es:[WallWidth]
	sub	bx, es:[WallHeight]
	ret
MazeGetCoord		endp

	
CommonCode	ends	
	



