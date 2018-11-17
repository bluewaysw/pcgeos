COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Eyes
FILE:		eyes.asm

AUTHOR:		Mark Hirayama, July 23, 1993

	
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	7/23/93		Initial revision

DESCRIPTION:
	This is a specific screen-saver library to move a Spotlight 
	around on the screen.
	
	$Id: eyes.asm,v 1.1 97/04/04 16:48:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def
include hugearr.def
include Internal/im.def

UseLib	ui.def
UseLib	saver.def

include	eyes.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

EyesApplicationClass	class	SaverApplicationClass

MSG_EYES_APP_DRAW				message
;
;	Draw the next line of the spotlight. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    EI_ballSize		word		BALL_DEFAULT_SIZE
    EI_ballSpeed	word		BALL_DEFAULT_SPEED


    EI_ballLeftPos	word		0 	; ball left side
    EI_ballTopPos	word		0	; ball top side
    EI_dir		word		0	; current direction

    EI_pupil1LeftPos	word		42	; pupil1 left side
    EI_pupil1TopPos	word		325	; pupil1 top side
    EI_pupil2LeftPos	word		76	; pupil2 left side
    EI_pupil2TopPos	word		325	; pupil2 top side
    EI_timerHandle	hptr		0
	noreloc	EI_timerHandle

    EI_timerID		word		0

    EI_random		hptr		0	; Random number generator
	noreloc	EI_random

EyesApplicationClass	endc

EyesProcessClass	class	GenProcessClass
EyesProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	eyes.rdef
ForceRef EyesApp

udata	segment

udata	ends

idata	segment

EyesProcessClass	mask CLASSF_NEVER_SAVED
EyesApplicationClass

idata	ends

EyesCode	segment resource

.warn -private
eyesOptionTable	SAOptionTable	<
	eyesCategory, length eyesOptions
>
eyesOptions	SAOptionDesc	<
	eyesSizeKey, size EI_ballSize, offset EI_ballSize
>, <
	eyesSpeedKey, size EI_ballSpeed, offset EI_ballSpeed
> 
.warn @private
eyesCategory	char	'eyes', 0
eyesSizeKey	char	'size', 0
eyesSpeedKey	char	'speed', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= EyesApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	7/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesLoadOptions	method	dynamic	EyesApplicationClass, 
						MSG_META_LOAD_OPTIONS
		uses	ax, es
		.enter
		
		segmov	es, cs
		mov	bx, offset eyesOptionTable
		call	SaverApplicationGetOptions
		
		.leave
		mov	di, offset EyesApplicationClass
		GOTO	ObjCallSuperNoLock
EyesLoadOptions	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	For now, this handler does nothing.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= EyesApplicationClass object
		ds:di	= EyesApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	7/23/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesAppGetWinColor	method dynamic EyesApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
		uses	cx, dx, bp
		.enter

	;
	; May want to later subclass, if we want window to start out
	; as another color.  For now, does nothing.
	;
		
		.leave
		ret
EyesAppGetWinColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= EyesApplication object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	We'll create 2 bitmaps:  1 that contains the contents of
	the screen (before blanking, of course), and 1 square the
	size of the spotlight.  The first one will have a filled
	circle in its mask that defines the spotlight.  This
	circle moves around, and we call GrDrawHugeBitmap, which
	only draws the pixels defined by the circle in the mask,
	thus defining the spotlight.

	To erase the crud left when the spotlight moves, we have
	another, square bitmap whose mask is the inverse of the
	spotlight bitmap's.  The data is just a black rectangle.
	When this "eraser" bitmap is drawn, it draws black over
	everything not in the current spotlight.  (We also draw
	black lines where the spotlight bounding square was
	before it moved, to clear the 1-pixel greebles that the
	eraser bitmap can't cover).


REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	7/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesAppSetWin	method dynamic EyesApplicationClass,
							MSG_SAVER_APP_SET_WIN
		.enter
	;
	; Let the superclass do its little thing.
	; 
		mov	di, offset EyesApplicationClass
		call	ObjCallSuperNoLock
		
		mov	di, ds:[si]
		add	di, ds:[di].EyesApplication_offset
	;
	; Create a random number generator.
	; 
		call	TimerGetCount
		mov	dx, bx		; dxax <- seed
		clr	bx		; bx <- allocate a new one
		call	SaverSeedRandom
		mov	ds:[di].EI_random, bx
	;
	;  Clear the screen.
	;
		call	EyesClearScreen
	;
	;  Get a random starting position and direction.
	;
		call	EyesInitBallPosition
	;
	; We always draw in COPY mode.
	;
		mov	di, ds:[di].SAI_curGState
		mov	ax, MM_COPY
		call	GrSetMixMode
	;
	; Start up the timer to draw a new line.
	;
		call	EyesSetTimer
	;
	; Draw the eyes outlines
	;
		mov	ax, 30
		mov	bx, 300
		call	EyesDrawEyes

		.leave
		ret
EyesAppSetWin	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesClearScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the screen before starting the bouncing ball.

CALLED BY:	EyesAppSetWin

PASS:		*ds:si	= EyesApplication object
		ds:di	= EyesApplicationInstance

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	We have stored the contents of the screen in a huge bitmap,
	so we can clear the passed gstate with impunity.

REVISION HISTORY:
	Name		Date			Description
	----		----			-----------
	hirayama	7/23/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesClearScreen	proc	near
		class	EyesApplicationClass
		uses	ax,bx,cx,dx,di
		.enter

		mov	di, ds:[di].SAI_curGState

		mov	ax, (CF_INDEX shl 8) or C_BLACK
		call	GrSetAreaColor

		call	GrGetWinBounds
		call	GrFillRect

		.leave
		ret
EyesClearScreen	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesInitBallPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the starting position and direction of the
		bouncing ball.

CALLED BY:	EyesAppSetWin

PASS:		*ds:si	= EyesApplication object
		ds:di	= EyesApplicationInstance

RETURN:		nothing (EI_ballLeftPos, EI_ballTopPos & EI_dir initialized)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date			Description
	----		----			-----------
	hirayama	7/23/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesInitBallPosition	proc	near
		class	EyesApplicationClass
		uses	ax,bx,dx
		.enter
	;
	;  Get random values for left & top, and store them.
	;
		mov	bx, ds:[di].EI_random
		mov	dx, ds:[di].SAI_bounds.R_right
		sub	dx, ds:[di].EI_ballSize
		call	SaverRandom		; dx <- left side
		mov	ds:[di].EI_ballLeftPos, dx

		mov	dx, ds:[di].SAI_bounds.R_bottom
		sub	dx, ds:[di].EI_ballSize
		call	SaverRandom		; dx <- top side
		mov	ds:[di].EI_ballTopPos, dx
	;
	;  Get a random direction and store it.
	;
		mov	dx, 4
		call	SaverRandom
		shl	dx			; word-sized etype
		mov	ds:[di].EI_dir, dx
		
		.leave
		ret
EyesInitBallPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= EyesApplication object
		ds:di	= EyesApplicationInstance
		ax	= the message

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	cx

PSEUDO CODE/STRATEGY:

	- stop the draw timer
	- kill the random number generator
	- destroy the bitmaps

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	7/23/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesAppUnsetWin	method dynamic EyesApplicationClass,
						MSG_SAVER_APP_UNSET_WIN
		uses	ax, bp
		.enter
	;
	;  Stop the draw timer.
	; 
		clr	bx
		xchg	bx, ds:[di].EI_timerHandle
		mov	ax, ds:[di].EI_timerID
		call	TimerStop
	;
	;  Nuke the random number generator.
	; 
		clr	bx
		xchg	bx, ds:[di].EI_random
		call	SaverEndRandom
	;
	;  Call our superclass to take care of the rest.
	;
		.leave
		mov	di, offset EyesApplicationClass
		GOTO	ObjCallSuperNoLock
EyesAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	EyesAppSetWin, EyesAppDraw
PASS:		*ds:si	= EyesApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	7/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesSetTimer	proc	near
		class	EyesApplicationClass
		uses	di
		.enter
		
		mov	di, ds:[si]
		add	di, ds:[di].EyesApplication_offset
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, 2
		mov	dx, MSG_EYES_APP_DRAW
		mov	bx, ds:[LMBH_handle]	; ^lbx:si <- destination
		
		call	TimerStart
		mov	ds:[di].EI_timerHandle, bx
		mov	ds:[di].EI_timerID, ax

		.leave
		ret
EyesSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Eyes line.

CALLED BY:	MSG_EYES_APP_DRAW

PASS:		*ds:si	= EyesApplication object
		ds:di	= EyesApplicationInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	hirayama	7/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesAppDraw	method	dynamic EyesApplicationClass, 
						MSG_EYES_APP_DRAW
		.enter
		
		mov	bp, di			; save instance
		segmov	es, ds, ax		; es:[bp] = instance data
	;
	;  See if we have a valid gstate.
	;
		mov	di, ds:[di].SAI_curGState
		tst	di
		LONG	jz	done
	;
	; Redraw the eyes, in case the ball has gone over it (note, position
	; is hard coded in!!!).
	;
		mov	ax, 30
		mov	bx, 300
		call	EyesDrawEyes
	;
	; erase pupils by drawing them in black.
	;
		push	ax
		mov	ah, CF_INDEX
		mov	al, C_BLACK
		call	GrSetAreaColor
		pop	ax
		call	EyesDrawPupils
	;
	; Erase the ball in its old position by drawing it black.
	;
		mov	ax, ds:[bp].EI_ballLeftPos
		mov	bx, ds:[bp].EI_ballTopPos
		call	EyesDrawBouncingBall
	;		
	;  Calculate the new position of the spotlight.
	;
		call	CalcNewBallPosition
	;
	; Calculate the new position of each of the pupils, and store
	; in appropriate instance data.
	;
		mov	cx, LEFT_EYE_CENTER_LEFT	; (cx,dx) <- left cent.
		mov	dx, LEFT_EYE_CENTER_TOP
		call	CalcNewPupilPositions		; (cx,dx) <- left pup
		mov	ds:[bp].EI_pupil1LeftPos, cx
		mov	ds:[bp].EI_pupil1TopPos, dx

		mov	cx, RIGHT_EYE_CENTER_LEFT	; (cx,dx) <- right cent
		mov	dx, RIGHT_EYE_CENTER_TOP
		call	CalcNewPupilPositions		; (cx,dx) <- right pup
		mov	ds:[bp].EI_pupil2LeftPos, cx
		mov	ds:[bp].EI_pupil2TopPos, dx
	;
	; Set pupils to white, and draw them.
	;
		mov	ah, CF_INDEX
		mov	al, C_WHITE
		call	GrSetAreaColor
		call	EyesDrawPupils
	;
	;  Draw the ball in its new position (currently in cyan).
	;
		mov	ah, CF_INDEX
		mov	al, C_YELLOW
		call	GrSetAreaColor
		
		mov	ax, ds:[bp].EI_ballLeftPos
		mov	bx, ds:[bp].EI_ballTopPos
		call	EyesDrawBouncingBall
	;
	; Set another timer for next time.
	;
		call	EyesSetTimer
done:
		.leave
		ret  
EyesAppDraw		endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesDrawEyes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		ax,bx - upper left corner
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesDrawEyes	proc	near
	uses	ax,bx,cx,dx
	.enter

	;
	; Set color of eyes to white.
	;
		push	ax
		mov	ah, CF_INDEX
		mov	al, C_WHITE
		call	GrSetLineColor
		pop	ax
	;
	; Draw first eye (note, position/size is hard coded in!!!)
	;
		mov	cx, ax
		add	cx, 24
		mov	dx, bx
		add	dx, 50
		call	GrDrawEllipse
	;
	; Draw second eye (note, position/size is hard coded in!!!)
	;
		add	ax, 35
		add	cx, 35
		call	GrDrawEllipse
		
	.leave
	ret
EyesDrawEyes	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesDrawPupils
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		
RETURN:		
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesDrawPupils	proc	near
	class	EyesApplicationClass
	uses	ax,bx,cx,dx,di,si
	.enter

	;
	; draw pupils, as solid circles for now....
	;
		push	di				; save GState handle
		mov	di, ds:[si]			; dereference inst
		
		add	di, ds:[di].EyesApplication_offset
		mov	ax, ds:[di].EI_pupil1LeftPos
		mov	bx, ds:[di].EI_pupil1TopPos
		mov	cx, ds:[di].EI_pupil2LeftPos
		mov	dx, ds:[di].EI_pupil2TopPos
		
		pop	di				; restore GState

		push	ds
		segmov	ds, cs
		mov	si, offset eyePupils
		call	GrDrawRegion			; draw left pupil

		mov	ax, cx
		mov	bx, dx
		call	GrDrawRegion			; draw right pupil
		pop	ds

	.leave
	ret
EyesDrawPupils	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EyesDrawBouncingBall
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws a circle as a region, so it is quick.

CALLED BY:	global

PASS:		ax,bx - position of region
		di - handle to graphics state

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		uses GrDrawRegion to draw ball.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EyesDrawBouncingBall	proc	near
	uses	ds, si
	.enter

	;
	; Set up registers, and call GrDrawRegion
	;
		segmov	ds, cs
		mov	si, offset bouncingBall
		call	GrDrawRegion
		
	.leave
	ret
EyesDrawBouncingBall	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNewBallPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the eyes.

CALLED BY:	EyesAppDraw

PASS:		*ds:si	= EyesApplication object
		ds:bp	= EyesApplicationInstance

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date			Description
	----		----			-----------
	stevey		4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcNewBallPosition	proc	near
		class	EyesApplicationClass
		uses	di,bx
		.enter
	;
	;  Call the appropriate movement routine.
	;
		mov	di, bp
		mov	bx, ds:[di].EI_dir
		call	cs:[dirTable][bx]
		
		.leave
		ret

dirTable	nptr	offset NWHandler,
			offset NEHandler,
			offset SEHandler,
			offset SWHandler

CalcNewBallPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NEHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the right wall, top wall, or both.

CALLED BY:	CalcNewPosition

PASS: 		*ds:si	= EyesApplication object
		ds:di	= EyesApplication instance

RETURN:		nothing (EI_dir initialized)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date			Description
	----		----			-----------
	stevey		4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NEHandler	proc	near
		class	EyesApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the upper-left corner.
	;
		mov	ax, ds:[di].EI_ballLeftPos
		add	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballLeftPos, ax

		mov	ax, ds:[di].EI_ballTopPos
		sub	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballTopPos, ax
	;
	;  Put eyes right & top sides in cx & dx.
	;
		mov	cx, ds:[di].EI_ballLeftPos
		mov	dx, ds:[di].EI_ballTopPos
		add	cx, ds:[di].EI_ballSize		; check other side
		add	cx, 2*FUDGE_FACTOR		; cx = right
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_right	; right wall
		mov	bx, ds:[di].SAI_bounds.R_top	; top wall
		cmp	cx, ax				; check right
		jl	doneRight

		ornf	si, mask WH_RIGHT
doneRight:		
		cmp	dx, bx				; check top
		jg	doneTop

		ornf	si, mask WH_TOP
doneTop:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_RIGHT or mask WH_TOP)
		je	hitBoth
		cmp	si, mask WH_RIGHT
		je	hitRight
		cmp	si, mask WH_TOP
		je	hitTop
		jmp	short	gotNewDir		; didn't hit a wall
hitRight:
		mov	ds:[di].EI_dir, BD_NW
		jmp	short	gotNewDir
hitTop:
		mov	ds:[di].EI_dir, BD_SE
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].EI_dir, BD_SW
gotNewDir:
		.leave
		ret
NEHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		NWHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the left wall, top wall, or both.

CALLED BY:	CalcNewPosition

PASS:		*ds:si	= EyesApplication object
		ds:di	= EyesApplication instance

RETURN:		EI_dir initialized

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date			Description
	----		----			-----------
	stevey		4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
NWHandler	proc	near
		class	EyesApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the upper-left corner
	;
		mov	ax, ds:[di].EI_ballLeftPos
		sub	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballLeftPos, ax

		mov	ax, ds:[di].EI_ballTopPos
		sub	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballTopPos, ax
	;
	;  Put eyes right & top sides in cx & dx.
	;
		mov	cx, ds:[di].EI_ballLeftPos
		mov	dx, ds:[di].EI_ballTopPos
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_left	; left wall
		mov	bx, ds:[di].SAI_bounds.R_top	; top wall
		cmp	cx, ax				; check left
		jg	doneLeft

		ornf	si, mask WH_LEFT		; hit left
doneLeft:		
		cmp	dx, bx				; check top
		jg	doneTop

		ornf	si, mask WH_TOP			; hit top
doneTop:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_LEFT or mask WH_TOP)
		je	hitBoth
		cmp	si, mask WH_LEFT
		je	hitLeft
		cmp	si, mask WH_TOP
		je	hitTop
		jmp	short	gotNewDir		; didn't hit a wall
hitLeft:
		mov	ds:[di].EI_dir, BD_NE
		jmp	short	gotNewDir
hitTop:
		mov	ds:[di].EI_dir, BD_SW
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].EI_dir, BD_SE
gotNewDir:
		.leave
		ret
NWHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SEHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the right wall, bottom wall, or both.

CALLED BY:	CalcNewPosition

PASS:		*ds:si	= EyesApplication object
		ds:di	= EyesApplication instance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date			Description
	----		----			-----------
	stevey		4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SEHandler	proc	near
		class	EyesApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the left & top position.
	;
		mov	ax, ds:[di].EI_ballLeftPos
		add	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballLeftPos, ax

		mov	ax, ds:[di].EI_ballTopPos
		add	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballTopPos, ax
	;
	;  Put eyes right & top sides in cx & dx.
	;
		mov	cx, ds:[di].EI_ballLeftPos
		mov	dx, ds:[di].EI_ballTopPos
		add	cx, ds:[di].EI_ballSize
		add	dx, ds:[di].EI_ballSize
		add	cx, 2*FUDGE_FACTOR		; cx = right
		add	dx, 2*FUDGE_FACTOR		; dx = bottom
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_right
		mov	bx, ds:[di].SAI_bounds.R_bottom
		cmp	cx, ax				; check right
		jl	doneRight

		ornf	si, mask WH_RIGHT		; hit right
doneRight:		
		cmp	dx, bx				; check bottom
		jl	doneBottom

		ornf	si, mask WH_BOTTOM		; hit bottom
doneBottom:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_RIGHT or mask WH_BOTTOM)
		je	hitBoth
		cmp	si, mask WH_RIGHT
		je	hitRight
		cmp	si, mask WH_BOTTOM
		je	hitBottom
		jmp	short	gotNewDir		; didn't hit a wall
hitRight:
		mov	ds:[di].EI_dir, BD_SW
		jmp	short	gotNewDir
hitBottom:
		mov	ds:[di].EI_dir, BD_NE
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].EI_dir, BD_NW
gotNewDir:
		.leave
		ret
SEHandler	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SWHandler
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We'll hit the left wall, bottom wall, or both.

CALLED BY:	CalcNewPosition

PASS:		*ds:si	= EyesApplication object
		ds:di	= EyesApplication instance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date			Description
	----		----			-----------
	stevey		4/28/93			Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SWHandler	proc	near
		class	EyesApplicationClass
		uses	ax,bx,cx,dx,si
		.enter
	;
	;  Update the left & top position.
	;
		mov	ax, ds:[di].EI_ballLeftPos
		sub	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballLeftPos, ax

		mov	ax, ds:[di].EI_ballTopPos
		add	ax, ds:[di].EI_ballSpeed
		mov	ds:[di].EI_ballTopPos, ax
	;
	;  Put eyes right & top sides in cx & dx.
	;
		mov	cx, ds:[di].EI_ballLeftPos
		mov	dx, ds:[di].EI_ballTopPos
		add	dx, ds:[di].EI_ballSize
		add	dx, 2*FUDGE_FACTOR		; dx = bottom
		clr	si				; WallsHit
	;
	;  See which walls we hit.
	;
		mov	ax, ds:[di].SAI_bounds.R_left
		mov	bx, ds:[di].SAI_bounds.R_bottom
		cmp	cx, ax				; check left
		jg	doneLeft

		ornf	si, mask WH_LEFT		; hit left
doneLeft:		
		cmp	dx, bx				; check bottom
		jl	doneBottom

		ornf	si, mask WH_BOTTOM		; hit bottom
doneBottom:
	;
	;  Go to the appropriate direction label based on WallsHit.
	;
		cmp	si, (mask WH_LEFT or mask WH_BOTTOM)
		je	hitBoth
		cmp	si, mask WH_LEFT
		je	hitLeft
		cmp	si, mask WH_BOTTOM
		je	hitBottom
		jmp	short	gotNewDir		; didn't hit a wall
hitLeft:
		mov	ds:[di].EI_dir, BD_SE
		jmp	short	gotNewDir
hitBottom:
		mov	ds:[di].EI_dir, BD_NW
		jmp	short	gotNewDir
hitBoth:
		mov	ds:[di].EI_dir, BD_NE
gotNewDir:
		.leave
		ret
SWHandler	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcNewPupilPositions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	
PASS:		cx - x-pos of center
		dx - y-pos of center

RETURN:		cx - x-pos of pupil
		dx - y-pos of pupil

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	- Calculate (dx)^2 and (dy)^2
	- Calculate hypotenuse as sqrt(dx^2 + dy^2)
	- Calculate sine as dx/hypotenuse
	- Determine x-pos as sine*20, store in instance variable
	- Calculate cos as dy/hypotenuse
	- Determine y-pos as cosine*10, store in instance variable

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	MH	7/26/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcNewPupilPositions	proc	near
	class	EyesApplicationClass

tempX	local	word
tempY	local	word
fixed1	local	WWFixed
		
	uses	ax,bx, si,di,bp
	.enter

	;
	; Save center coordinates
	;
		mov	ss:tempX, cx
		mov	ss:tempY, dx
	;
	; Dereference instance variables.
	;
		mov	di, ds:[si]			; dereference
		add	di, ds:[di].EyesApplication_offset
	;
	; Calculate delta-x, and push onto stack
	;
		mov	dx, ds:[di].EI_ballLeftPos	; dx <- (dx)
		sub	dx, cx				; dx <- centerX
		sar	dx				; divide by 4
		sar	dx
		push	dx				; store (dx)/2
	;
	; Calculate (delta-x)^2, and store in local variable fixed1.
	;
		clr	cx
		call	GrSqrWWFixed			; dxcx <- (dx/2)^2
		mov	ss:fixed1.WWF_int, dx		; fixed1 <- (dx/2)^2
		mov	ss:fixed1.WWF_frac, cx
	;
	; Calculate delta-y, and push onto stack
	;
		mov	dx, ds:[di].EI_ballTopPos	; dx <- (dy)
		sub	dx, tempY			; dx <- centerY
		sar	dx				; divide by 4
		sar	dx
		push	dx				; store (dy)/2
	;
	; Calculate (delta-y)^2.
	;
		clr	cx
		call	GrSqrWWFixed			; dxcx <- (dy/2)^2
	;
	; Calculate (delta-x)^2 + (delta-y)^2.
	;
		add	dx, ss:fixed1.WWF_int		; dx<-(dx/2)^2+(dy/2)^2
		add	cx, ss:fixed1.WWF_frac
	;
	; Calculate the hypotenuse by taking square root of
	; (delta-x)^2 + (delta-y)^2, and store in fixed1.
	;
		call	GrSqrRootWWFixed		; dxcx <- hyp.
		mov	ss:fixed1.WWF_int, dx		; fixed1 <- hyp.
		mov	ss:fixed1.WWF_frac, cx
	;
	; Calculate sine by dividing delta-y by hypotenuse.
	;
		mov	bx, dx				; bxax <- hyp.
		mov	ax, cx
		pop	dx				; dxcx <- (dy)/2
		clr	cx
		call	GrSDivWWFixed			; dxcx <- sine of angle
	;
	; Calculate y-coordinate of pupil, and store in tempX.
	;
		mov	bx, 20				; bxax <- vert-axis
		clr	ax
		call	GrMulWWFixed			; dx <- y-pos (int)
		add	dx, ss:tempY			; dx <- y-coord
		mov	ss:tempY, dx			; tempX <- y-coord
	;
	; Calculate cosine by dividing delta-x by hypotenuse.
	;
		mov	bx, ss:fixed1.WWF_int		; bxax <- hyp.
		mov	ax, ss:fixed1.WWF_frac
		pop	dx				; dxcx <- (dx)/2
		clr	cx
		call	GrSDivWWFixed			; dxcx <- cos of angle
	;
	; Calculate x-coordinate of pupil, move to dx
	;
		mov	bx, 9				; bxax <- horiz-axis
		clr	ax
		call	GrMulWWFixed			; dx <- y-pos (int)
		add	dx, ss:tempX			; dx <- y-coord
	;
	; Move x-coordinate to cx, y coordinate into dx
	;
		mov	cx, dx
		mov	dx, tempY
		
	.leave
	ret
CalcNewPupilPositions	endp


;
; Our little ball, defined as a region so it will redraw quickly.
;

bouncingBall	label	Region
	word	0,0,BALL_DEFAULT_SIZE,BALL_DEFAULT_SIZE	; bounds
	word	-1, EOREGREC			; from infinity to here
	word	0,  9, 15, EOREGREC
	word	1,  7, 17, EOREGREC
	word	2,  5, 19, EOREGREC
	word	3,  4, 20, EOREGREC
	word	4,  3, 21, EOREGREC
	word	6,  2, 22, EOREGREC
	word	8,  1, 23, EOREGREC
	word	15, 0, 24, EOREGREC
	word	17, 1, 23, EOREGREC
	word	19, 2, 22, EOREGREC
	word	20, 3, 21, EOREGREC
	word	21, 4, 20, EOREGREC
	word	22, 5, 19, EOREGREC
	word	23, 7, 17, EOREGREC
	word	24, 9, 15, EOREGREC
	word	EOREGREC

eyePupils	label	Region
	word	0,0,PUPILS_DEFAULT_SIZE ,PUPILS_DEFAULT_SIZE	; bounds
	word	-1, EOREGREC			; from infinity to here
	word	0, 1, 4, EOREGREC
	word	1, 0, 5, EOREGREC
	word	3, 0, 5, EOREGREC
	word	4, 1, 4, EOREGREC
	word	EOREGREC


EyesCode	ends

