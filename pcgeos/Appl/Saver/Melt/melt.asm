COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		GeoCalc
FILE:		melt.asm

AUTHOR:		Gene Anderson, Sep 11, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/11/91		Initial revision

DESCRIPTION:
	Specific screen-saver library to melt the screen.

	$Id: melt.asm,v 1.1 97/04/04 16:46:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

include	melt.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

MeltApplicationClass	class	SaverApplicationClass

MSG_MELT_APP_DRAW				message
;
;	Draw the next line of the melt. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    MAI_speed		word		MELT_MEDIUM_SPEED
    MAI_timerHandle	hptr		0
    	noreloc	MAI_timerHandle
    MAI_timerID		word		0
    MAI_random		hptr		0 
	noreloc	MAI_random

MeltApplicationClass	endc

MeltProcessClass	class	GenProcessClass
MeltProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	melt.rdef
ForceRef MeltApp

udata	segment

;
; Current window and gstate to use for drawing.
;
winHeight	word
winWidth	word
blitSize	word
blitBorder	word

udata	ends

idata	segment

MeltProcessClass	mask CLASSF_NEVER_SAVED
MeltApplicationClass

idata	ends

MeltCode	segment resource

.warn -private
meltOptionTable	SAOptionTable	<
	meltCategory, length meltOptions
>
meltOptions	SAOptionDesc	<
	meltSpeedKey, size MAI_speed, offset MAI_speed
> 
.warn @private
meltCategory	char	'melt', 0
meltSpeedKey	char	'speed', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MeltLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= MeltApplicationClass object
		ds:di	= MeltApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MeltLoadOptions	method dynamic MeltApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs, bx
	mov	bx, offset	meltOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset	MeltApplicationClass
	GOTO	ObjCallSuperNoLock
MeltLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MeltAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Makes sure the screen isn't cleared first.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= MeltApplicationClass object

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MeltAppGetWinColor	method dynamic MeltApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thing.
	;

	mov	di, offset MeltApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT

	ret
MeltAppGetWinColor	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MeltAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use, and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= MeltApplicationClass object
		dx	= Window
		bp	= GState

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MeltAppSetWin	method dynamic MeltApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset MeltApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].MeltApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].MAI_random, bx

	;
	;  Initialize some global variables.
	;

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	mov	es:[winHeight], dx

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	mov	es:[winWidth], dx
	shr	dx, 1
	shr	dx, 1
	shr	dx, 1				; dx<- width / 8
	mov	es:[blitSize], dx
	shr	dx, 1
	shr	dx, 1				; dx <- width / 32
	mov	es:[blitBorder], dx

	;
	; We're dull - we always draw in black
	;

	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor

	;
	; Start up the timer to draw a new line.
	;

	call	MeltSetTimer

	ret
MeltAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MeltAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stops saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= MeltApplicationClass object
		
RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MeltAppUnsetWin	method dynamic MeltApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 

	clr	bx
	xchg	bx, ds:[di].MAI_timerHandle
	mov	ax, ds:[di].MAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	; 

	clr	bx
	xchg	bx, ds:[di].MAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	; 

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset MeltApplicationClass
	GOTO	ObjCallSuperNoLock
MeltAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MeltSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next melt.

CALLED BY:	MeltAppDraw, MeltAppSetWin
PASS:		*ds:si = MeltApplicationInstance
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MeltSetTimer	proc	near
	class	MeltApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].MeltApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, MELT_TIMER_SPEED
	mov	dx, MSG_MELT_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination
	call	TimerStart

	mov	ds:[di].MAI_timerHandle, bx
	mov	ds:[di].MAI_timerID, ax

	.leave
	ret
MeltSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MeltAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of the screen melting

CALLED BY:	timer

PASS:		ds:[di] = MeltApplicationInstance
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
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MeltAppDraw	method	dynamic	MeltApplicationClass,
					MSG_MELT_APP_DRAW


	;
	; Make sure there is a GState to draw with
	;		

	tst	ds:[di].SAI_curGState
	jz	quit

	mov	bp, si				; *ds:bp = object

	;
	; Set up on-stack arguments
	;

	mov	si, es:[blitSize]		; si <- width of block
	push	si				; <- height of block
	mov	ax, BLTM_COPY
	push	ax

	;
	; Setup source
	;

	mov	dx, es:[winWidth]
	add	dx, es:[blitSize]		; allow for left edge
	mov	bx, ds:[di].MAI_random
	call	SaverRandom

	sub	dx, es:[blitSize]		; dx <- source x
	push	dx				; save source x
	mov	dx, es:[winHeight]
	call	SaverRandom

	sub	dx, es:[blitSize]
	mov	bx, dx				; bx <- source y

	;
	; Setup destination
	;

	mov	dx, ds:[di].MAI_speed
	shl	dx, 1				; dx <- max delta * 2
	push	bx				; save source y
	mov	bx, ds:[di].MAI_random
	call	SaverRandom

	sub	dx, ds:[di].MAI_speed		; dx <- +/- delta x
	mov	cx, dx				; cx <- delta x
	mov	dx, ds:[di].MAI_speed
	call	SaverRandom
	pop	bx				; restore source y

	add	dx, bx				; dx <- destination y
	pop	ax				; ax <- source x
	add	cx, ax				; cx <- destination y

	;
	; Bit-blit me jesus!
	;

	mov	di, ds:[di].SAI_curGState
	call	GrBitBlt

	;
	; If we blitted from the top of the screen, fill in with black
	;

	cmp	bx, es:[blitBorder]
	ja	done				; branch if not top
	mov	cx, ax
	add	cx, es:[blitSize]		; cx <- right
	clr	dx				; dx <- top
	call	GrFillRect			; paint it black

done:
	;
	; Set another timer for next time.
	;

	mov	si, bp				; *ds:si = object
	call	MeltSetTimer
quit:

	ret
MeltAppDraw	endm

MeltCode	ends
