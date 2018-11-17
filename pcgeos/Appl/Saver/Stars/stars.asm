COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Stars
FILE:		stars.asm

AUTHOR:		Gene, Mar  26, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial revision
	stevey	12/14/92	port to 2.0

DESCRIPTION:
	Hahahahaha...what a bunch of hacks...

	$Id: stars.asm,v 1.1 97/04/04 16:47:18 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include stars.def

;=============================================================================
;
;		OBJECT CLASSES
;
;=============================================================================

StarsApplicationClass	class	SaverApplicationClass

MSG_STARS_APP_DRAW			message
;
;	Draw some stars.  Sent by our timer.
;
;	Pass: nothing
;	Return: nothing
;
	SAI_numStars	sword		STARS_DEFAULT_NUM
	SAI_doColor	BooleanByte	BB_FALSE
	SAI_timerHandle	hptr	0
		noreloc SAI_timerHandle
	SAI_timerID	word
	SAI_random	hptr	0		;random number generator
	SAI_width	word			;width w/fraction
	SAI_height	word			;height w/fraction
	SAI_stars	lptr.StarStruct	0	;array of stars

StarsApplicationClass	endc

StarsProcessClass	class	GenProcessClass
StarsProcessClass	endc

;=============================================================================
;
;		VARIABLES
;
;=============================================================================

include	stars.rdef
ForceRef StarsApp

udata	segment

udata	ends

idata	segment

StarsProcessClass	mask CLASSF_NEVER_SAVED
StarsApplicationClass

idata	ends

;=============================================================================
;
;		CODE 'N' STUFF
;
;=============================================================================

StarsCode	segment resource

.warn -private
starsOptionTable	SAOptionTable	<
	starsCategory, length starsOptions
>
starsOptions	SAOptionDesc	<
	starsNumStarsKey, size SAI_numStars, offset SAI_numStars
>,<
	starsDoColorKey, size SAI_doColor, offset SAI_doColor
>
.warn @private
starsCategory		char	'stars', 0
starsNumStarsKey	char	'numStars', 0
starsDoColorKey		char	'doColor', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StarsLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= StarsApplicationClass object
		ds:di	= StarsApplicationClass instance data
		ds:bx	= StarsApplicationClass object (same as *ds:si)

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StarsLoadOptions	method dynamic StarsApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	es
	.enter

	segmov	es, cs
	mov	bx, offset starsOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset StarsApplicationClass
	GOTO	ObjCallSuperNoLock
StarsLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StarsAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= StarsApplicationClass object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StarsAppSetWin	method dynamic StarsApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	.enter
	;
	; Let the superclass do its little thing.
	;
	mov	di, offset StarsApplicationClass
	call	ObjCallSuperNoLock
	;
	; Now initialize our state. 
	; 
	mov	di, ds:[si]
	add	di, ds:[di].StarsApplication_offset
	;
	; Create a random number generator.
	; 
	call	TimerGetCount
	mov	dx, bx				;dxax <- seed
	clr	bx				;bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].SAI_random, bx
	push	si
	;
	; Create a chunk for the stars
	;
	mov	al, {byte}ds:[di].SAI_numStars	;al <- # of stars
	mov	cl, (size StarStruct)		;cl <- size of star
	mul	cl
	mov_tr	cx, ax				;cx <- total size
	mov	al, mask OCF_IGNORE_DIRTY
	call	LMemAlloc
	mov	di, ds:[si]
	add	di, ds:[di].StarsApplication_offset
	mov	ds:[di].SAI_stars, ax
	;
	;  Initialize the rest of the instance data.  First get window
	;  width & window height into si & dx.
	;
	mov	cl, STARS_FRACTION_BITS
	mov	ax, ds:[di].SAI_bounds.R_right
	sub	ax, ds:[di].SAI_bounds.R_left	;ax <- width
	shl	ax, cl
	mov	ds:[di].SAI_width, ax

	mov	ax, ds:[di].SAI_bounds.R_bottom
	sub	ax, ds:[di].SAI_bounds.R_top	;ax <- height
	shl	ax, cl
	mov	ds:[di].SAI_height, ax

	mov	cx, ds:[di].SAI_numStars
EC <	tst	ch				;>
EC <	ERROR_NZ -1				;>
	;
	; Initialize the star field
	;
	mov	si, ds:[di].SAI_stars
	mov	si, ds:[si]			;ds:si <- ptr to 1st star
starLoop:
	call	InitStar
	add	si, (size StarStruct)		;ds:si <- next star
	loop	starLoop
	;
	; Set the GState to dither, so colors look interesting
	; on B&W systems
	;
	mov	di, ds:[di].SAI_curGState
	mov	al, CMT_DITHER
	call	GrSetAreaColorMap
	;
	; Start up the timer.
	;
	pop	si				;*ds:si <- app obj
	call	StarsSetTimer

	.leave
	ret
StarsAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StarsAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= StarsApplicationClass object
		ds:di	= StarsApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StarsAppUnsetWin	method dynamic StarsApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
	clr	bx
	xchg	bx, ds:[di].SAI_timerHandle
	mov	ax, ds:[di].SAI_timerID
	call	TimerStop
	;
	; Nuke the random number generator.
	; 
	clr	bx
	xchg	bx, ds:[di].SAI_random
	call	SaverEndRandom
	;
	; Free up the stars array
	; 
	clr	ax
	xchg	ds:[di].SAI_stars, ax
	call	LMemFree
	;
	; Call our superclass to take care of the rest.
	; 
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset StarsApplicationClass
	GOTO	ObjCallSuperNoLock
StarsAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitStar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a star's position and give it a random velocity
CALLED BY:	StarsStart

PASS:		ds:di - StarsApplicationClass instance data
		ds:si - ptr to current StarStruct

RETURN:		(ax,bx) = position of star
DESTROYED:	dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/26/91		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitStar	proc	near
	uses	cx
	class	StarsApplicationClass
	.enter

	;
	; Initialize the color
	;
	mov	dl, C_WHITE
	tst	ds:[di].SAI_doColor
	jz	gotColor
chooseColor:
	mov	dx, 16
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	tst	dl				;don't allow black
	jz	chooseColor			;branch if black
gotColor:
	mov	ds:[si].SS_color, dl
initVelocity:
	;
	; Initialize the velocity
	;
	mov	dx, (STARS_MAX_DX * 2)+1
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	sub	dx, (STARS_MAX_DX)
	sal	dx, 1
	mov	ds:[si].SS_dx, dx
	mov	bx, dx

	push	bx
	mov	bx, ds:[di].SAI_random
	mov	dx, (STARS_MAX_DY * 2)+1
	call	SaverRandom
	sub	dx, (STARS_MAX_DY)
	sal	dx, 1
	mov	ds:[si].SS_dy, dx
	;
	; Make sure both velocities are non-zero,
	; otherwise the star will get stuck in the middle.
	;
	pop	bx
	mov	ax, bx
	or	ax, dx
	jz	initVelocity
	;
	; Make sure the little bugger is moving along decently
	;
	AbsVal	bx
	AbsVal	dx
	add	bx, dx
	cmp	bx, (1 shl (STARS_FRACTION_BITS/2))
	jbe	initVelocity
	;
	; Initalize the acceleration.  To give a 3-D effect, the
	; acceleration is somewhat random.
	;
	mov	ax, ds:[si].SS_dx
	mov	cl, STARS_FRACTION_BITS/2
	sar	ax, cl
	mov	ds:[si].SS_ddx, ax

	mov	ax, ds:[si].SS_dy
	mov	cl, STARS_FRACTION_BITS/2
	sar	ax, cl
	mov	ds:[si].SS_ddy, ax
	;
	; Initialize the star position to the middle of the Window.
	;
	mov	ax, ds:[di].SAI_width
	shr	ax, 1
	mov	ds:[si].SS_x, ax
	mov	bx, ds:[di].SAI_height
	shr	bx, 1
	mov	ds:[si].SS_y, bx

	.leave
	ret
InitStar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StarsAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the next Star update

CALLED BY:	MSG_STARS_APP_DRAW

PASS:		*ds:si - stars app obj
		ds:di - *ds:si
RETURN:		nothing

DESTROYED:	anything I want

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/25/91		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StarsAppDraw		method	dynamic	StarsApplicationClass,
						MSG_STARS_APP_DRAW
	.enter

	tst	ds:[di].SAI_curGState
	LONG	jz	done

	push	si

	mov	si, ds:[di].SAI_stars
	mov	si, ds:[si]			;ds:si <- ptr to stars
	mov	cx, ds:[di].SAI_numStars

starLoop:
	push	cx, di				; save # of stars

	mov	ax, ds:[si].SS_x
	mov	bx, ds:[si].SS_y

	call	SetStarSize
	push	ax, bx, dx

	add	ax, ds:[si].SS_dx
	add	bx, ds:[si].SS_dy

	cmp	ax, ds:[di].SAI_width
	ja	resetStar

	tst	ax
	js	resetStar

	cmp	bx, ds:[di].SAI_height
	ja	resetStar

	tst	bx
	js	resetStar

afterReset:

	mov	di, ds:[di].SAI_curGState	;di <- handle of GState
	mov	ds:[si].SS_x, ax
	mov	ds:[si].SS_y, bx
	call	SetStarSize
	call	DrawStar
	pop	ax, bx, dx
	call	EraseStar
	;
	; Accelerate me jesus
	;
	mov	ax, ds:[si].SS_ddx
	add	ds:[si].SS_dx, ax
	mov	ax, ds:[si].SS_ddy
	add	ds:[si].SS_dy, ax

	pop	cx, di				;cx <- # of stars left
	add	si, (size StarStruct)		;ds:si <- next
	loop	starLoop

	pop	si				;*ds:si = StarsApplication
	call	StarsSetTimer			;for next time...
done:

	.leave
	ret

resetStar:
	call	InitStar
	jmp	afterReset
StarsAppDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawStar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a star
CALLED BY:	StarsAppDraw

PASS:		(ax,bx) - (x,y) pos (12.4 coordinates)
		dx - star size
		ds:si =- ptr to current StarStruct
		di - handle of GState

RETURN:		(cx,bp) = (x,y) pos (document coordinates)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/92		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawStar	proc	near
	uses	ax, bx, dx
	.enter

	push	ax
	mov	al, ds:[si].SS_color
	mov	ah, CF_INDEX
	call	GrSetAreaColor
	pop	ax
	;
	; Draw the new point
	;
	mov	cl, STARS_FRACTION_BITS
	shr	ax, cl
	shr	bx, cl
	mov	cx, dx
	add	cx, ax
	add	dx, bx
	call	GrFillRect			;draw new point

	mov	cx, ax
	mov	bp, bx				;(cx,bp) <- new pos

	.leave
	ret
DrawStar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EraseStar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Erase the current star
CALLED BY:	StarsAppDraw

PASS:		(ax,bx) - (x,y) pos (12.4 coordinates)
		dx - star size
		(cx,bp) - current (x,y) pos (document coordinates)

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 2/92		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
EraseStar	proc	near
	.enter

	push	ax
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	pop	ax
	;
	; Erase the old point
	;
	push	cx
	mov	cl, STARS_FRACTION_BITS
	shr	ax, cl
	shr	bx, cl
	pop	cx
	cmp	ax, cx				;x's match?
	jne	eraseStar
	cmp	bx, bp				;y's match
	je	skipErase			;branch if they both match

eraseStar:
	mov	cx, dx
	add	cx, ax
	add	dx, bx
	call	GrFillRect			;erase old point

skipErase:

	.leave
	ret
EraseStar	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetStarSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size for drawing a star
CALLED BY:	StarsAppDraw

PASS:		ds:si - ptr to current StarStruct
RETURN:		dx - size of star
DESTROYED:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/28/91		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetStarSize	proc	near
	uses	ax, cx
	.enter

	mov	ax, ds:[si].SS_dx
	AbsVal	ax
	mov	dx, ds:[si].SS_dy
	AbsVal	dx
	add	dx, ax

	mov	cl, STARS_FRACTION_BITS+2
	shr	dx, cl

	.leave
	ret
SetStarSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StarsSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer 

CALLED BY:	StarsAppSetWin, StarsAppDraw

PASS:		*ds:si = StarsApplicationObject

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/19/91		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StarsSetTimer	proc near	
	class	StarsApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].StarsApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, STARS_TIMER_SPEED
	mov	dx, MSG_STARS_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination

	call	TimerStart

	mov	ds:[di].SAI_timerHandle, bx
	mov	ds:[di].SAI_timerID, ax

	.leave
	ret
StarsSetTimer	endp

StarsCode	ends
