COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Black Hole screen saver
FILE:		blackhole.asm

AUTHOR:		David Loftesness, Sep 19, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/11/91		Initial revision
	DaveL	9/20/91		made into black hole
	stevey	1/5/93		port to 2.0

DESCRIPTION:

	Specific screen-saver library to suck the screen into oblivion

	$Id: blackhole.asm,v 1.1 97/04/04 16:44:20 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include	blackhole.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

BlackHoleApplicationClass	class	SaverApplicationClass

MSG_BLACKHOLE_APP_DRAW				message
;
;	Draw the next line of the blackhole. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    BAI_speed	word	BLACK_MEDIUM_DELTA_MAX
    BAI_size	word	BLACK_MEDIUM_SIZE

    BAI_timerHandle	hptr		0
    	noreloc	BAI_timerHandle
    BAI_timerID		word

    BAI_random		hptr		0	; Random number generator
	noreloc	BAI_random

BlackHoleApplicationClass	endc

BlackHoleProcessClass	class	GenProcessClass
BlackHoleProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	blackhole.rdef
ForceRef BlackHoleApp

udata	segment

winHeight	word
winWidth	word
blitSize	word
blitBorder	word

randomStor1	word
randomStor2	word

udata	ends

idata	segment

BlackHoleProcessClass	mask CLASSF_NEVER_SAVED
BlackHoleApplicationClass

idata	ends

;==============================================================================
;
;				CODE	   
;
;==============================================================================
BlackCode	segment resource

.warn -private
blackholeOptionTable	SAOptionTable	<
	blackholeCategory, length blackholeOptions
>
blackholeOptions	SAOptionDesc	<
>, <
	blackholeSpeedKey, size BAI_speed, offset BAI_speed
>, <
	blackholeSizeKey, size BAI_size, offset BAI_size
> 
.warn @private
blackholeCategory	char	'blackhole', 0
blackholeSpeedKey	char	'speed', 0
blackholeSizeKey	char	'size', 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlackHoleLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= BlackHoleApplicationClass object
		ds:di	= BlackHoleApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlackHoleLoadOptions	method dynamic BlackHoleApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax,es
	.enter

	segmov	es, cs
	mov	bx, offset blackholeOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset BlackHoleApplicationClass
	GOTO	ObjCallSuperNoLock
BlackHoleLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlackHoleAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the screen isn't blanked first.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= BlackHoleApplicationClass object
		ds:di	= BlackHoleApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlackHoleAppGetWinColor	method dynamic BlackHoleApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thang.
	;

	mov	di, offset BlackHoleApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT

	ret
BlackHoleAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlackHoleAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate and start things rolling.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= BlackHoleApplicationClass object
		ds:di	= BlackHoleApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlackHoleAppSetWin	method dynamic BlackHoleApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	.enter
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset BlackHoleApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].BlackHoleApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].BAI_random, bx

	;
	;  Do other stuff.  (great comment, eh?)
	;

	call	BlackStart

	;
	; Start up the timer to draw a new line.
	;

	call	BlackSetTimer
	.leave
	ret
BlackHoleAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlackStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	BlackHoleAppSetWin

PASS: 		ds:[di]	= BlackHoleApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlackStart	proc	near
	class	BlackHoleApplicationClass
	uses	ax,bx,cx,dx,si,di
	.enter

	;
	; Save the window and gstate we were given for later use.
	;

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	mov	si, ds:[di].SAI_bounds.R_bottom
	sub	si, ds:[di].SAI_bounds.R_top

	mov	es:[winHeight], dx
	mov	es:[winWidth], si
	shr	si, 1
	shr	si, 1
	shr	si, 1				; si <- width / 8
	mov	es:[blitSize], si
	shr	si, 1
	shr	si, 1				; si <- width / 64
	shr	si, 1				; si <- width / 128
	mov	es:[blitBorder], si

	;
	; We're dull - we always draw in black
	;

	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor

	;
	; Draw Box around the edge
	;

	clr	ax			; left side
	mov	bx, ax
	mov	cx, es:[blitBorder]
	mov	dx, es:[winHeight]
	call	GrFillRect

	mov	cx, es:[winWidth]	; top
	mov	dx, es:[blitBorder]
	call	GrFillRect

	mov	bx, es:[winHeight]	; bottom
	mov	dx, bx
	sub	bx, es:[blitBorder]
	call	GrFillRect

	mov	ax, cx			; right side
	sub	ax, es:[blitBorder]
	clr	bx
	call	GrFillRect

	.leave
	ret
BlackStart	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlackHoleAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= BlackHoleApplicationClass object
		ds:di	= BlackHoleApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlackHoleAppUnsetWin	method dynamic BlackHoleApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].BAI_timerHandle
	mov	ax, ds:[di].BAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	;

	clr	bx
	xchg	bx, ds:[di].BAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset BlackHoleApplicationClass
	GOTO	ObjCallSuperNoLock
BlackHoleAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlackSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	BlackHoleAppSetWin, BlackHoleAppDraw

PASS:		*ds:si 	= BlackHoleApplicationInstance

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlackSetTimer	proc	near
	class	BlackHoleApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].BlackHoleApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[di].BAI_speed
	mov	dx, MSG_BLACKHOLE_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si <- destination

	call	TimerStart
	mov	ds:[di].BAI_timerHandle, bx
	mov	ds:[di].BAI_timerID, ax

	.leave
	ret
BlackSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BlackHoleAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of the screen Blacking

CALLED BY:	MSG_BLACKHOLE_APP_DRAW

PASS:		*ds:si	= BlackHoleApplication object
		ds:[di]	= BlackHoleApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
	This routine *must* be sure there's still a gstate around, as there
	is no synchronization provided by our parent to deal with timer
	methods that have already been queued after the SAVER_STOP method
	is received.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/11/91		Initial version
	dloft	12/10/91	eh, what?
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BlackHoleAppDraw	method	dynamic	BlackHoleApplicationClass,
					MSG_BLACKHOLE_APP_DRAW
	.enter

	;
	; Make sure there is a GState to draw with
	;

	tst	ds:[di].SAI_curGState
	LONG	jz	quit

	push	si				; save object

	;
	; Set up on-stack arguments
	;

	mov	si, ds:[di].BAI_size		; si <- width of block
	push	si				; <- height of block
	mov	ax, MM_COPY
	push	ax

	; 
	; Setup random variables
	;

	mov	dx, ds:[di].BAI_speed
	mov	bx, ds:[di].BAI_random
	call	SaverRandom
	mov	es:[randomStor1], dx

	mov	dx, ds:[di].BAI_speed
	call	SaverRandom
	mov	es:[randomStor2], dx

	;
	; Setup source
	;

	mov	dx, es:[winWidth]
	call	SaverRandom
	sub	dx, es:[blitBorder]		; make sure we grab
						; from upper left
	push	dx				; push source x
	mov	dx, es:[winHeight]
	call	SaverRandom
	sub	dx, es:[blitBorder]
	mov	bx, dx				; bx <- source y

	;
	; Setup destination
	;

	mov	dx, es:[winWidth]
	shr	dx				; winWidth / 2
	pop	ax				; ax <- source x
	mov	cx, ax				; cx <- dest x
	cmp	ax, dx
	jl	leftHalf

rightHalf::
	mov	dx, es:[winHeight]
	shr	dx
	cmp	bx, dx
	jl	upperRightQuarter

lowerRightQuarter::				; Want to move block LEFT
	mov	dx, bx
	sub	cx, es:[randomStor1]		; left
	sub	dx, es:[randomStor2]		; up
	jmp	sourceAndDestReady

upperRightQuarter:				; Want to move block DOWN
	mov	dx, bx
	add	dx, es:[randomStor1]		; down
	sub	cx, es:[randomStor2]		; left
	jmp	sourceAndDestReady

leftHalf:
	mov	dx, es:[winHeight]
	shr	dx
	cmp	bx, dx
	jl	upperLeftQuarter

lowerLeftQuarter::				; Want to move block UP
	mov	dx, bx
	sub	dx, es:[randomStor1]		; up
	add	cx, es:[randomStor2]		; right
	jmp	sourceAndDestReady
	
upperLeftQuarter:				; Want to move block RIGHT
	mov	dx, bx
	add	cx, es:[randomStor1]		; right
	add	dx, es:[randomStor2]		; down
	jmp	sourceAndDestReady

sourceAndDestReady:

	mov	di, ds:[di].SAI_curGState
	call	GrBitBlt
done::
	;
	; Set another timer for next time.
	; 

	pop	si				; *ds:si = BlackHoleApp
	call	BlackSetTimer
quit:

	.leave
	ret
BlackHoleAppDraw	endm

BlackCode	ends

