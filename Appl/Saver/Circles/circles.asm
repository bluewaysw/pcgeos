COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Circles
FILE:		circles.asm

AUTHOR:		Gene, Mar  25, 1992

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/23/92		Initial revision

DESCRIPTION:
	This is a specific screen-saver library

	$Id: circles.asm,v 1.1 97/04/04 16:44:38 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

include	circles.def

;=============================================================================
;
;			CONSTANTS AND DATA TYPES
;
;=============================================================================

CirclesApplicationClass	class	SaverApplicationClass

MSG_CIRCLES_APP_DRAW				message
;
;	Draw the next circle. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

	SAI_interval	word		CIRCLES_DEFAULT_INTERVAL;
	SAI_numCircles	word		CIRCLES_DEFAULT_NUM;
	SAI_clearMode	byte		FALSE
	SAI_drawMode	byte		MM_COPY
	SAI_inColor	byte		CRC_RANDOM
	SAI_outColor	byte		CRC_NONE

	SAI_timerHandle	hptr		0
    		noreloc	SAI_timerHandle
	SAI_timerID		word

	SAI_random		hptr	0
		noreloc	SAI_random

CirclesApplicationClass	endc

CirclesProcessClass	class	GenProcessClass
CirclesProcessClass	endc

;=============================================================================
;
;				VARIABLES
;
;=============================================================================

include	circles.rdef
ForceRef CirclesApp

udata	segment

;
; all our circles
;
circles		CircleGroupStruct	<>

;
; Number of circles drawn
;
numCircles	word

udata	ends

idata	segment

CirclesProcessClass	mask	CLASSF_NEVER_SAVED
CirclesApplicationClass

idata	ends

;=============================================================================
;
;				CODE
;
;=============================================================================

CircleCode	segment resource

.warn -private
circlesOptionTable	SAOptionTable	<
	circlesCategory, length circlesOptions
>
circlesOptions	SAOptionDesc	<
	circlesIntervalKey, size SAI_interval, offset SAI_interval
>, <
	circlesNumCirclesKey, size SAI_numCircles, offset SAI_numCircles
>, <
	circlesClearModeKey, size SAI_clearMode, offset SAI_clearMode
>, <
	circlesDrawModeKey, size SAI_drawMode, offset SAI_drawMode
>, <
	circlesInColorKey, size SAI_inColor, offset SAI_inColor
>, <
	circlesOutColorKey, size SAI_outColor, offset SAI_outColor
>
.warn @private
circlesCategory		char	'circles', 0
circlesIntervalKey	char	'interval', 0
circlesNumCirclesKey	char	'number', 0
circlesClearModeKey	char	'clearScreen', 0
circlesDrawModeKey	char	'drawMode', 0
circlesInColorKey	char	'inside', 0
circlesOutColorKey	char	'outside', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CirclesLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= CirclesApplicationClass object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CirclesLoadOptions	method dynamic CirclesApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax,es
	.enter

	segmov	es, cs
	mov	bx, offset circlesOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset CirclesApplicationClass
	GOTO	ObjCallSuperNoLock
CirclesLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CirclesAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= CirclesApplicationClass object
		ds:di	= CirclesApplicationClass instance data
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CirclesAppSetWin	method dynamic CirclesApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	.enter

	;
	; Let the superclass do its little thing.
	;

	mov	di, offset CirclesApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].CirclesApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].SAI_random, bx
	
	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	mov	es:[circles].CGS_width, dx

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	mov	es:[circles].CGS_height, dx

	;
	; Set the map mode
	;

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	al, CMT_DITHER
	call	GrSetAreaColorMap
	pop	di

	;
	; Set drawing mode
	;

	push	di
	mov	al, ds:[di].SAI_drawMode
	mov	di, ds:[di].SAI_curGState
	call	GrSetMixMode
	pop	di

	;
	; Fetch the number of circles the user wants us to draw concurrently
	;

	clr	es:[numCircles]
	mov	cx, ds:[di].SAI_numCircles
	mov	es:[circles].CGS_numCircles, cx

	push	si				; save CircleApp object

	clr	si

circleLoop:
	call	InitCircle
	add	si, size CircleStruct		; si <- offset to next circle
	loop	circleLoop

	;
	; Start up the timer to draw a new circle.
	;

	pop	si				; *ds:si = CircleApp
	call	CircleSetTimer

	.leave
	ret
CirclesAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CirclesAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= CirclesApplicationClass object
		ds:di	= CirclesApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CirclesAppUnsetWin	method dynamic CirclesApplicationClass, 
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
	; Call our superclass to take care of the rest.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset CirclesApplicationClass
	GOTO	ObjCallSuperNoLock
CirclesAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CirclesAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines whether the screen should be cleared at first.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= CirclesApplicationClass object
		ds:di	= CirclesApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CirclesAppGetWinColor	method dynamic CirclesApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its little thing.
	;

	mov	di, offset CirclesApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].CirclesApplication_offset

	cmp	ds:[di].SAI_clearMode, TRUE
	je	done

	ornf	ah, mask WCF_TRANSPARENT
done:
	ret
CirclesAppGetWinColor	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CircleSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next circle.

CALLED BY:	CirclesAppDraw, CirclesAppSetWin
PASS:		*ds:si = CirclesApplicationObject
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	6/28/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CircleSetTimer	proc	near
	class	CirclesApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].CirclesApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, CIRCLE_TIMER_SPEED
	mov	dx, MSG_CIRCLES_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination
	call	TimerStart

	mov	ds:[di].SAI_timerHandle, bx
	mov	ds:[di].SAI_timerID, ax

	.leave
	ret
CircleSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitCircle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one circle

CALLED BY:	CirclesAppDraw, CirclesAppSetWin

PASS:		es	= dgroup
		si	= offset of CircleStruct
		ds:[di] = CirclesApplicationInstance

RETURN:		nothing
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitCircle	proc	near
	class	CirclesApplicationClass
	.enter

	mov	bx, ds:[di].SAI_random

	;
	; Get random (x,y) position for circle
	;

	mov	dx, es:[circles].CGS_width
	call	SaverRandom
	mov	es:[circles].CGS_circles[si].CS_pos.P_x, dx
	mov	dx, es:[circles].CGS_height
	call	SaverRandom
	mov	es:[circles].CGS_circles[si].CS_pos.P_y, dx

	;
	; Get random maximum size
	;

	mov	dx, (CIRCLE_MAX_SIZE - CIRCLE_MIN_MAX_SIZE)
	call	SaverRandom
	add	dx, CIRCLE_MIN_MAX_SIZE
	mov	es:[circles].CGS_circles[si].CS_maxSize, dx

	;
	; Get random initial size
	;

	mov	dx, CIRCLE_MAX_INIT_SIZE
	call	SaverRandom
	mov	es:[circles].CGS_circles[si].CS_size, dx

	;
	; Set the inside color
	;

	mov	al, ds:[di].SAI_inColor
	cmp	al, CRC_RANDOM
	jne	gotInsideColor

	call	PickAColor

gotInsideColor:

	mov	es:[circles].CGS_circles[si].CS_insideColor.CC_color, al

	;
	; Set the outside color
	;

	mov	al, ds:[di].SAI_outColor
	cmp	al, CRC_RANDOM
	jne	gotOutsideColor

	call	PickAColor

gotOutsideColor:

	mov	es:[circles].CGS_circles[si].CS_outsideColor.CC_color, al

	;
	; One more circle drawn
	;

	inc	es:[numCircles]
	mov	ax, es:[numCircles]
	cmp	ax, ds:[di].SAI_interval	; enough circles drawn?
	jb	done

	;
	; If we've drawn enough circles, clear the screen
	;

	call	ClearForMode
	clr	es:[numCircles]
done:

	.leave
	ret
InitCircle	endp

ClearForMode	proc	near
	class	CirclesApplicationClass
	uses	ax
	.enter

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	al, MM_COPY
	call	GrSetMixMode
	pop	di

	mov	ax, C_BLACK or (CF_INDEX shl 8)
	cmp	ds:[di].SAI_drawMode, MM_AND
	jne	doClear

	mov	ax, C_WHITE or (CF_INDEX shl 8)

doClear:
	call	DoClear

	push	di
	mov	al, ds:[di].SAI_drawMode
	mov	di, ds:[di].SAI_curGState
	call	GrSetMixMode
	pop	di

	.leave
	ret
ClearForMode	endp

DoClear	proc	near
	class	CirclesApplicationClass
	uses	bx,cx,dx,si,di
	.enter

	mov	di, ds:[di].SAI_curGState
	call	GrSetAreaColor
	clr	ax
	clr	bx
	mov	cx, es:[circles].CGS_width
	mov	dx, es:[circles].CGS_height	;(ax,bx),(cx,dx) <- bounds
	mov	si, SAVER_FADE_FAST_SPEED
	call	SaverFadePatternFade

	.leave
	ret
DoClear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PickAColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pick a random color

CALLED BY:	INTERNAL

PASS:		ds:[di] = CirclesApplicationInstance

RETURN:		al - Color
		ah - CF_INDEX

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/23/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PickAColor	proc	near
	class	CirclesApplicationClass
	uses	bx, dx
	.enter

	mov	bx, ds:[di].SAI_random
	mov	dx, 16
	call	SaverRandom
	mov	al, dl				; al <- random color
	mov	ah, CF_INDEX

	.leave
	ret
PickAColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcCircleBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate circle bounds

CALLED BY:	DrawCircleOutside(), DrawCircleInside()

PASS:		(ax,bx) = center of circle
		dx	= radius of circle

RETURN:		(ax,bx,cx,dx) = bounds of circle
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcCircleBounds	proc	near
	uses	si
	.enter

	mov	cx, ax				; cx <- y position
	add	cx, dx				; cx <- right of circle
	sub	ax, dx				; ax <- left of circle
	mov	si, bx
	add	bx, dx				; bx <- top of circle
	sub	si, dx
	mov	dx, si				; dx <- bottom of circle

	.leave
	ret
CalcCircleBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCircleOutside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw outside of one circle

CALLED BY:	CirclesAppDraw

PASS:		ds:[di] = CirclesApplicationInstance
		(ax,bx) = center of circle
		dx	= radius of circle
		es	= dgroup
		si	= offset to current CircleStruct

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCircleOutside	proc	near
	class	CirclesApplicationClass
	uses	ax,bx,cx,dx,di
	.enter

	;
	; Draw the outside, if any
	;

	cmp	es:[circles].CGS_circles[si].CS_outsideColor.CC_random, CRC_NONE
	je	noOutside

	call	CalcCircleBounds
	push	ax
	mov	ah, CF_INDEX
	mov	al, es:[circles].CGS_circles[si].CS_outsideColor.CC_color
	cmp	al, CRC_VERY_RANDOM
	jne	gotColor

	call	PickAColor

gotColor:

	mov	di, ds:[di].SAI_curGState

	call	GrSetLineColor
	pop	ax
	call	GrDrawEllipse

noOutside:

	.leave
	ret
DrawCircleOutside	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawCircleInside
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw inside of one circle

CALLED BY:	CirclesAppDraw

PASS:		ds:[di] = CirclesApplicationInstance
		(ax,bx) = center of circle
		dx	= radius of circle
		es	= dgroup
		si	= offset to current CircleStruct

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawCircleInside	proc	near
	class	CirclesApplicationClass
	uses	ax,bx,cx,dx,di
	.enter

	;
	; Draw the inside, if any
	;

	cmp	es:[circles].CGS_circles[si].CS_insideColor.CC_random, CRC_NONE
	je	noInside

	call	CalcCircleBounds
	push	ax
	mov	ah, CF_INDEX
	mov	al, es:[circles].CGS_circles[si].CS_insideColor.CC_color
	cmp	al, CRC_VERY_RANDOM
	jne	gotColor

	call	PickAColor

gotColor:

	mov	di, ds:[di].SAI_curGState

	call	GrSetAreaColor
	pop	ax
	call	GrFillEllipse

noInside:

	.leave
	ret
DrawCircleInside	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CirclesAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the circles

CALLED BY:	MSG_CIRCLES_APP_DRAW

PASS:		*ds:si	= CirclesApplication object
		ds:[di] = CirclesApplication instance data
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/25/92		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CirclesAppDraw	method	dynamic	CirclesApplicationClass,
					MSG_CIRCLES_APP_DRAW
	.enter

	tst	ds:[di].SAI_curGState
	LONG	jz	quit

	push	si					; save *ds:si	

	mov	cx, es:[circles].CGS_numCircles		; cx <- # of circles

	clr	si

circleLoop:
	mov	ax, es:[circles].CGS_circles[si].CS_pos.P_x
	mov	bx, es:[circles].CGS_circles[si].CS_pos.P_y
	mov	dx, es:[circles].CGS_circles[si].CS_size
	cmp	dx, es:[circles].CGS_circles[si].CS_maxSize
	jae	circleDone

	add	dx, CIRCLE_CHANGE_RATE
	call	DrawCircleOutside

	xchg	dx, es:[circles].CGS_circles[si].CS_size
	call	DrawCircleInside

	add	si, size CircleStruct
	loop	circleLoop

nextDraw:

	pop	si				; *ds:si = CircleApp
	call	CircleSetTimer			; start timer for next draw
quit:

	.leave
	ret

circleDone:
	call	DrawCircleInside		; one last draw (to erase)
	call	InitCircle			; start a new circle
	jmp	nextDraw
CirclesAppDraw		endm

CircleCode	ends

