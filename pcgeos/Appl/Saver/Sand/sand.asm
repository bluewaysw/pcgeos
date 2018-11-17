COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		sand
FILE:		sand.asm

AUTHOR:		Gene Anderson, Sep 11, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/11/91		Initial revision
	stevey	12/14/92	port to 2.0

DESCRIPTION:

	Sand screen saver

	$Id: sand.asm,v 1.1 97/04/04 16:47:05 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include library.def
include win.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include	sand.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

SandApplicationClass	class	SaverApplicationClass

MSG_SAND_APP_DRAW				message
;
;	Draw the next sand thing. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    SAI_speed		word		SAND_MEDIUM_SPEED
    SAI_winHeight	word		0
    SAI_winWidth	word		0
    SAI_dropWidth	word		0
    SAI_dropCenter	word		0

    SAI_timerHandle	hptr		0
    	noreloc	SAI_timerHandle
    SAI_timerID		word

    SAI_random		hptr		0	; Random number generator
						;  we use
	noreloc	SAI_random

SandApplicationClass	endc

SandProcessClass	class	GenProcessClass
SandProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	sand.rdef
ForceRef SandApp

udata	segment

udata	ends

idata	segment

SandProcessClass	mask CLASSF_NEVER_SAVED
SandApplicationClass

idata	ends

;==============================================================================
;
;		   CODE 'N' STUFF
;
;==============================================================================
SandCode	segment resource

.warn -private
sandOptionTable	SAOptionTable	<
	sandCategory, length sandOptions
>
sandOptions	SAOptionDesc	<

	sandSpeedKey, size SAI_speed, offset SAI_speed

>
.warn @private

sandCategory	char	'sand', 0
sandSpeedKey	char	'speed', 0



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SandLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS
PASS:		*ds:si	= SandApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SandLoadOptions	method dynamic SandApplicationClass, MSG_META_LOAD_OPTIONS
		uses	ax, es
		.enter

		segmov	es, cs
		mov	bx, offset sandOptionTable
		call	SaverApplicationGetOptions

		.leave
		mov	di, offset SandApplicationClass
		GOTO	ObjCallSuperNoLock
SandLoadOptions	endm

;==============================================================================
;
;		    DRAWING ROUTINES
;
;==============================================================================


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SASetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= SandApplication object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SASetWin	method 	dynamic SandApplicationClass, 
						MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	; 

	mov	di, offset SandApplicationClass
	call	ObjCallSuperNoLock

	;
	;  Save window & gstate, and init some variables.
	;

	mov	di, ds:[si]
	add	di, ds:[di].SandApplication_offset
	mov	ds:[di].SAI_curWindow, dx
	mov	ds:[di].SAI_curGState, bp

	mov	ax, ds:[di].SAI_bounds.R_left
	mov	bx, ds:[di].SAI_bounds.R_top
	mov	cx, ds:[di].SAI_bounds.R_right
	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	cx, ax				; cx = width
	sub	dx, bx				; dx = height

	mov	ds:[di].SAI_winHeight, dx
	mov	ds:[di].SAI_winWidth, cx

	mov	ds:[di].SAI_dropWidth, SAND_INIT_WIDTH
	shr	cx, 1
	mov	ds:[di].SAI_dropCenter, cx	; cx <- center = width / 2

	;
	; We're dull - we always draw in black
	;

	xchg	di, bp				; di <- gstate
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	xchg	di, bp				; di <- instance

	;
	; Create a random number generator.
	; 

	call	TimerGetCount
	mov	dx, bx				; dxax <- seed
	clr	bx				; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].SAI_random, bx

	;
	; Start up the timer to draw a sand.
	;

	call	SandSetTimer

	ret
SASetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SAUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= SandApplication object
		ds:di	= SandApplicationInstance

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	12/10/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SAUnsetWin	method dynamic SandApplicationClass, MSG_SAVER_APP_UNSET_WIN
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
	mov	di, offset SandApplicationClass
	GOTO	ObjCallSuperNoLock
SAUnsetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SandGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keeps the screen from being cleared first.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= SandApplicationClass object
		ds:di	= SandApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/14/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SandGetWinColor	method dynamic SandApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thang.
	;

	mov	di, offset SandApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT

	ret
SandGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SandSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	SASetWin, SandDraw
PASS:		*ds:si	= SandApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SandSetTimer	proc	near
	class	SandApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].SandApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[di].SAI_speed
	mov	dx, MSG_SAND_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si <- destination
	call	TimerStart

	mov	ds:[di].SAI_timerHandle, bx
	mov	ds:[di].SAI_timerID, ax

	.leave
	ret
SandSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SandDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of drawing the screen saver
CALLED BY:	MSG_SAND_APP_DRAW

PASS:		*ds:si = SandApplication object
		ds:[di] = SandApplication instance data

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
	eca	9/16/91		Initial version
	stevey	12/14/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SandDraw	method	dynamic	SandApplicationClass, 
					MSG_SAND_APP_DRAW

	ourChunk	local	word
	gstate		local	hptr.GState

	.enter

	;
	; Make sure there is a GState to draw with (and save it)
	;		

	mov	ourChunk, si
	mov	ax, ds:[di].SAI_curGState
	mov	gstate, ax
	tst	ax
	jz	quit

	;
	; Do our cool stuff
	;

	push	ds:[di].SAI_winHeight		; height of block
	mov	ax, BLTM_COPY			;
	push	ax				; BLTMode

	mov	ax, ds:[di].SAI_dropCenter	; ax <- center of drop area
	mov	si, ds:[di].SAI_dropWidth
	sub	ax, si				; ax <- x source
	shl	si, 1				; si <- blit width
	mov	cx, ax				; cx <- x destination
	clr	bx				; bx <- y source
	mov	dx, ds:[di].SAI_speed
	mov	di, gstate
	call	GrBitBlt			; bit-blit me jesus

	;
	; Fill in with black from above
	;

	add	cx, si				; cx <- right side
	clr	bx				; bx <- top
	call	GrFillRect			; paint it black

	mov	si, ourChunk
	mov	di, ds:[si]
	add	di, ds:[di].SandApplication_offset

	;
	; Calculate the next drop width
	;

	mov	ax, ds:[di].SAI_winWidth	; ax <- width of window
	shr	ax, 1				; ax <- width / 2
	shr	ax, 1				; ax <- width / 4
	shr	ax, 1				; ax <- width / 8
	shr	ax, 1				; ax <- width / 16
	inc	ax				; to account for odd size
	cmp	ds:[di].SAI_dropWidth, ax	; drop area large enough?
	ja	goneVertical			; branch if above half

	mov	dx, ds:[di].SAI_speed
	mov	bx, ds:[di].SAI_random
	call	SaverRandom
	inc	dx
	add	ds:[di].SAI_dropWidth, dx		; next width

nextDraw:
	;
	; Set another timer for next time.
	; 

	call	SandSetTimer
quit:

	.leave
	ret

goneVertical:
	;
	; We've dropped enough in that area -- pick a new one
	;

	mov	ds:[di].SAI_dropWidth, SAND_INIT_WIDTH
	mov	dx, ds:[di].SAI_winWidth
	add	dx, SAND_INIT_WIDTH/2
	mov	bx, ds:[di].SAI_random
	call	SaverRandom

	sub	dx, SAND_INIT_WIDTH/2
	mov	ds:[di].SAI_dropCenter, dx
	jmp	nextDraw

SandDraw	endm

SandCode	ends

