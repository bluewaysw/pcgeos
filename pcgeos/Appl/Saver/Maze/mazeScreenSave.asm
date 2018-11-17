COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		maze screen saver
FILE:		mazeScreenSave.asm

AUTHOR:		stolen from Gene Anderson, Jan 23, 1991

ROUTINES:
	Name			Description
	----			-----------
EXT	ForceWindowOnTop	Change window priority to force it on top

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	1/23/91		Initial revision

DESCRIPTION:

	Window-related routines for the timer.

	$Id: mazeScreenSave.asm,v 1.1 97/04/04 16:45:47 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeInitFreedom
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	establish maximun range for upper left hand corner of maze

CALLED BY:	MazeStart

PASS:		es = dgroup
		cx,dx = max X coord and maxY Y coord
		al = size of maze

RETURN:		ax, bx = x, y freedoms

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	take the size of the screen and subtract the
			size of the maze times the wall width/height
	
			we add two to the size of the maze as cheating 
			causes the line to be drawn around the border 

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	7/17/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeInitFreedom	proc	near
	uses	cx, dx
	.enter
	clr	ah
	push	ax
	add	al, 2
	mov	bx, es:[WallWidth]
	mul	bl
	sub	cx, ax
	dec	cx
	pop	ax
	push	cx
	add	al, 2
	mov	bx, es:[WallHeight]
	mul	bl
	sub	dx, ax
	dec	dx
	mov	bx, dx			; bx = vertical freedom
	pop	ax			; ax = horizontal freedom
	.leave
	ret
MazeInitFreedom	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revoke usage of the Window and GState

CALLED BY:	MSG_APP_SAVER_UNSET_WIN
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of MazeApplicationClass
		ax - the message
RETURN:		
DESTROYED:	bx, si, di, ds, es (method handler)

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/25/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeAppUnsetWin		method dynamic MazeApplicationClass,
						MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
	clr	bx
	xchg	bx, es:[timerHandle]
	mov	ax, es:[timerID]
	call	TimerStop

	mov	es:[solving], 0
	;
	; Nuke the random number generator.
	; 
	clr	bx
	xchg	bx, es:[randomSeed]
	call	SaverEndRandom

	mov	bx, es:[MazeData]
	call	MemFree
	mov	bx, es:[MazeFringe]
	call	MemFree
	;
	; Call our superclass to take care of the rest.
	; 
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset MazeApplicationClass
	GOTO	ObjCallSuperNoLock
MazeAppUnsetWin		endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                MazeStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Initialize a Maze

CALLED BY:      MazeStart
PASS:           ax      = qix number
                dx      = screen height
                si      = screen width
                es:di   = Qix to initialize
                ds      = dgroup
RETURN:         nothing
DESTROYED:      ax, bx

PSEUDO CODE/STRATEGY:


KNOWN BUGS/SIDE EFFECTS/IDEAS:


REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ardeb   4/2/91          Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeStart	method dynamic MazeApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	uses ds
	.enter

	mov	di, offset MazeApplicationClass
	call	ObjCallSuperNoLock

	segmov	es, dgroup, ax
	mov	es:[leftSolver].MS_whoami, LEFTSOLVER
	mov	es:[rightSolver].MS_whoami, RIGHTSOLVER

	push	si, bp
	mov	si, SAVER_FADE_FAST_SPEED
	mov	di, bp
	mov	bp, mask SWT_TOP
 	call	SaverFadeWipe
	pop	si, bp

	mov	ax, MAXDATA * MAXDATA
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	mov	es:[MazeData], bx

	mov	ax, MAXDATA * MAXDATA
	mov	cx, ALLOC_DYNAMIC
	call	MemAlloc
	mov	es:[MazeFringe], bx

	
	mov	ax, MAZE_SIZE
	mov	di, bp		; put gstate in di
	
	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx			; create new seed
	call	SaverSeedRandom
	mov	es:[randomSeed], bx

;	mov	es:[saverWindow], cx
	mov	es:[saverGState], di

	call	MazeSetTimer		; set one-shot deal

	.leave
	ret
MazeStart	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeInitMazeSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	GLOBAL

PASS:		ax = maze size

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/28/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeInitMazeSize	proc	near
	uses	ax
	.enter
	push	ax
	dec	al
	mov	es:[maxWidth], al
	mov	es:[maxHeight], al

	push	ax
	call	WinGetWinScreenBounds


	; use the smaller dimension for our bounding box
	mov	ax, dx
	cmp	cx, dx
	jge	gotSmaller
	mov	ax, cx
gotSmaller:		
	pop	bx
	add	bl, 3
	div	bl

	tst	ah		; if remainder is zero its a little tight
	jnz	gotWidth
	dec	al
	and	al, not 1		; make wall height on even value
gotWidth:
	clr	ah
	mov	es:[WallHeight], ax
	mov	es:[WallWidth], ax
	pop	ax
	call	MazeInitFreedom	
	.leave
	ret
MazeInitMazeSize	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeStep
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	take the next step in solving the maze

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/24/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeStep	method	MazeApplicationClass, MSG_MAZE_APP_DRAW
	.enter

	segmov	es, dgroup, ax
	tst	es:[saverGState]
	jz	done

	tst	es:[solving]
	jnz	startSolve
	call	MazeMakeGrid
	call	MazeChooseSolver
	call	MazeInitSolve
startSolve:
	mov	es:[solving], 1
	cmp	es:[Hand], BOTHSOLVERS
	jz	doBoth
	cmp	es:[Hand], RIGHTSOLVER
	jz	doRight
	cmp	es:[Hand], LEFTSOLVER
	jnz	done
	call	MazeSolveOneStepLeft
	jmp	done
doBoth:
	call	MazeSolveOneStepRight
	call	MazeSolveOneStepLeft
	jmp	done
doRight:
	call	MazeSolveOneStepRight
done:
	call	MazeSetTimer		; get ready for next time
	.leave
	ret
MazeStep	endm
public	MazeStep



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeChooseSolver
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	choose who will solve the maze

CALLED BY:	GLOBAL

PASS:		nothing

RETURN:		Void.

DESTROYED:	Nada.

PSEUDOCODE/STRATEGY:	

KNOWN BUGS/SIDEFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jimmy	5/28/93		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MazeChooseSolver proc near
	mov	di, es:[saverGState]
	mov	bp, di

setup:
	clr	es:[rightSolver].MS_cheat
	call	FastRandom
	and	dx, 15
	tst	dx
	jnz	afterCheatR
	inc	es:[rightSolver].MS_cheat	;once in a while (1/16) make
afterCheatR:	
	clr	es:[leftSolver].MS_cheat
	call	FastRandom
	and	dx, 15			; once in 16 times about make
	tst	dx			; left hand cheat
	jnz	afterCheatL
	inc	es:[leftSolver].MS_cheat
afterCheatL:
	call	FastRandom
	and	dx, BOTHSOLVERS
	tst	dx
	jz	setup
	mov	es:[Hand], dl
	cmp	dl, BOTHSOLVERS
	jne	tryRight
	clr	es:[leftSolver].MS_done
	clr	es:[rightSolver].MS_done
	jmp	done
tryRight:
	cmp	dl, RIGHTSOLVER
	jne	doLeft
	clr	es:[rightSolver].MS_done
	mov	es:[leftSolver].MS_done, 1
	jmp	done
doLeft:
	mov	es:[rightSolver].MS_done, 1
	clr	es:[leftSolver].MS_done
done:
	ret

MazeChooseSolver	endp






COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MazeSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer (continual timers are frowned upon)

CALLED BY:	MazeStart, MazeStep

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/19/91		Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MazeSetTimer	proc near	uses ax,bx,cx,dx
	.enter
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, 1
	mov	dx, MSG_MAZE_APP_DRAW
	mov	bx, handle MazeApp
	mov	si, offset MazeApp
	call	TimerStart
	mov	es:[timerHandle], bx
	mov	es:[timerID], ax
	.leave
	ret
MazeSetTimer	endp


CommonCode	ends







