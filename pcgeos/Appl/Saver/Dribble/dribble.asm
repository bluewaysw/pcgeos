COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Specific Screen Saver -- Dribble
FILE:		dribble.asm

AUTHOR:		Roger, Nov 13, 1991

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/23/91		Initial revision

DESCRIPTION:
	This is a specific screen-saver library

	$Id: dribble.asm,v 1.1 97/04/04 16:44:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include	dribble.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

DribbleApplicationClass	class	SaverApplicationClass

MSG_DRIBBLE_APP_DRAW				message
;
;	Draw the next line of the dribble. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    DAI_interval	word		DRIBBLE_DEFAULT_INTERVAL
    DAI_paint		byte		1
    DAI_clear		byte		1
    DAI_timerHandle	hptr		0
    	noreloc	DAI_timerHandle
    DAI_timerID		word
    DAI_random		hptr		0
	noreloc	DAI_random

DribbleApplicationClass	endc

DribbleProcessClass	class	GenProcessClass
DribbleProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	dribble.rdef
ForceRef DribbleApp

udata	segment

winWidth	word
winHeight	word

;
; The current drop
;
curDrop	DribbleDrop

;
; Number of drops drawn since last clear
;
numDrops	word

udata	ends

idata	segment

DribbleProcessClass	mask CLASSF_NEVER_SAVED
DribbleApplicationClass

idata	ends

DribbleCode	segment resource

.warn -private
dribbleOptionTable	SAOptionTable	<
	dribbleCategory, length dribbleOptions
>
dribbleOptions	SAOptionDesc	<
	dribbleIntervalKey, size DAI_interval, offset DAI_interval
>, <
	dribblePaintKey, size DAI_paint, offset DAI_paint
>, <
	dribbleClearKey, size DAI_clear, offset DAI_clear
> 
.warn @private
dribbleCategory		char	'dribble', 0
dribbleIntervalKey	char	'interval', 0
dribblePaintKey		char	'paint', 0
dribbleClearKey		char	'clear', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DribbleAppLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= DribbleApplicationClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DribbleAppLoadOptions	method dynamic DribbleApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs, bx
	mov	bx, offset dribbleOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset DribbleApplicationClass
	GOTO	ObjCallSuperNoLock
DribbleAppLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DribbleAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide whether the screen will be cleared first.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= DribbleApplicationClass object

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DribbleAppGetWinColor	method dynamic DribbleApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thing.
	;

	mov	di, offset DribbleApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].DribbleApplication_offset

	tst	ds:[di].DAI_clear
	jnz	done

	ornf	ah, mask WCF_TRANSPARENT

done:
	ret
DribbleAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DribbleAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate, and start things moving.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= DribbleApplicationClass object
		dx	= window
		bp	= gstate
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/20/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DribbleAppSetWin	method dynamic DribbleApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset DribbleApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].DribbleApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].DAI_random, bx

	;
	;  Do dribble-specific initialization.
	;

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	mov	es:[winWidth], dx

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	mov	es:[winHeight], dx

	;
	; Initialize common attributes
	;

	mov	al, CMT_DITHER			; al = ColorMapMode
	mov	di, ds:[di].SAI_curGState
	call	GrSetLineColorMap
	call	GrSetAreaColorMap

	;
	; Initalize the first dribble
	;

	mov	di, ds:[si]
	add	di, ds:[di].DribbleApplication_offset

	call	InitDrop
	clr	es:[numDrops]

	;
	; Start up the timer to draw a new line.
	;

	call	DribbleSetTimer

	ret
DribbleAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DribbleAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revoke usage of the Window and GState

CALLED BY:	MSG_APP_SAVER_UNSET_WIN
PASS:		*ds:si - instance data
		ds:di - *ds:si
		es - seg addr of DribbleApplicationClass
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
DribbleAppUnsetWin		method dynamic DribbleApplicationClass,
						MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	; 
	clr	bx
	xchg	bx, ds:[di].DAI_timerHandle
	mov	ax, ds:[di].DAI_timerID
	call	TimerStop
	;
	; Nuke the random number generator.
	; 
	clr	bx
	xchg	bx, ds:[di].DAI_random
	call	SaverEndRandom
	;
	; Call our superclass to take care of the rest.
	; 
	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset DribbleApplicationClass
	GOTO	ObjCallSuperNoLock
DribbleAppUnsetWin		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DribbleSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next step

CALLED BY:	DribbleStart, DribbleAppDraw

PASS:		*ds:si = DribbleApplication object

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DribbleSetTimer	proc	near
	class	DribbleApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].DribbleApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, DRIBBLE_PAUSE
	mov	dx, MSG_DRIBBLE_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination

	call	TimerStart

	mov	ds:[di].DAI_timerHandle, bx
	mov	ds:[di].DAI_timerID, ax

	.leave
	ret
DribbleSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitDrop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one dribble drop

CALLED BY:	DribbleAppDraw, DribbleStart

PASS:		ds:[di]	= DribbleApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, bx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	4/ 1/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitDrop	proc	near
	class	DribbleApplicationClass
	uses	cx,si,di,ds
	.enter

	;
	; set the shrink distance
	;

	mov	ax, es:[winHeight]
	mov	dl, DRIBBLE_SHRINK_TIMES
	div	dl
	clr	ah
	mov	es:[curDrop].DD_shrinkDistance, ax

	;
	; Get random (x,y) position for drop
	;

	mov	dx, es:[winWidth]
	mov	bx, ds:[di].DAI_random
	call	SaverRandom

	mov	es:[curDrop].DD_pos.P_x, dx
	mov	dx, es:[winHeight]
	call	SaverRandom
	mov	es:[curDrop].DD_pos.P_y, dx

	;
	; get the length of the dribble
	;

	mov	ax, dx				; ax <- y position
	mov	dx, es:[winHeight]		; dx <- win height
	sub	dx, ax				; dx <- difference
	call	SaverRandom
	mov	es:[curDrop].DD_length, dx

	;
	; Get random maximum size
	;

	mov	dx, (DRIBBLE_MAX_DROP_SIZE - DRIBBLE_MIN_DROP_SIZE)
	call	SaverRandom
	add	dx, DRIBBLE_MIN_DROP_SIZE
	mov	es:[curDrop].DD_radius, dx

	;
	;  Get random color
	;

	mov	dx, length splotchTable
	call	SaverRandom
	mov	si, dx
	shl	si, 1				;table of 2 * Colors
	mov	dx, {word}cs:[colorTable][si]
	mov	{word}es:[curDrop].DD_color, dx

CheckHack <offset DD_shadow eq offset DD_color+1>

	;
	;  Load and draw the corresponding splotch bitmap
	;

	mov	di, ds:[di].SAI_curGState	; di = gstate
	segmov	ds, cs, ax
	mov	si, cs:[splotchTable][si]	; ds:si = bitmap

	mov	ax, es:[curDrop].DD_pos.P_x
	add	ax, DRIBBLE_SPLOTCH_X_OFFSET
	mov	bx, es:[curDrop].DD_pos.P_y
	add	bx, DRIBBLE_SPLOTCH_Y_OFFSET	; (ax, bx) = where to draw it
	clr	dx				; no callback
	call	GrDrawBitmap

	.leave
	ret
InitDrop	endp

colorTable	Color \
	C_LIGHT_BLUE, C_BLUE,
	C_LIGHT_RED, C_RED,
	C_LIGHT_VIOLET, C_VIOLET,
	C_LIGHT_GREEN, C_GREEN,
	C_YELLOW, C_BROWN

splotchTable	nptr \
	blueSplotch,
	redSplotch,
	violetSplotch,
	greenSplotch,
	yellowSplotch

blueSplotch	label	byte
include	Art/mkrBlue.ui
redSplotch	label	byte
include	Art/mkrRed.ui
violetSplotch	label	byte
include	Art/mkrViolet.ui
greenSplotch	label	byte
include	Art/mkrGreen.ui
yellowSplotch	label	byte
include	Art/mkrYellow.ui


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcDropBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate drop bounds

CALLED BY:	DrawDrop, EraseDrop

PASS:		(ax,bx) = center of dribble drop
		dx 	=radius of dribble drop

RETURN:		(ax,bx,cx,dx) - bounds of drop
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalcDropBounds	proc	near
	uses	si
	.enter

	mov	cx, ax				; cx <- y position
	add	cx, dx				; cx <- right of drop
	sub	ax, dx				; ax <- left of drop
	mov	si, bx
	add	bx, dx				; bx <- bottom of drop
	sub	si, dx
	mov	dx, si				; dx <- top of drop
	xchg	bx, dx

	.leave
	ret
CalcDropBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawDrop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one dribble drop

CALLED BY:	DribbleAppDraw

PASS:		ds:[di] = DribbleApplicationInstance
		(ax,bx) = center of dribble drop
		dx	= radius of dribble drop
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/91		Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawDrop	proc	near
	class	DribbleApplicationClass
	uses	ax,bx,cx,dx,di
	.enter

	mov	di, ds:[di].SAI_curGState

	push	ax
	mov	ah, CF_INDEX
	mov	al, es:[curDrop].DD_color
	call	GrSetAreaColor
	mov	al, es:[curDrop].DD_shadow
	call	GrSetLineColor
	pop	ax

	push	bx				; save drop center y
	call	CalcDropBounds
	call	GrFillEllipse
	pop	dx				; dx <- drop center y
	inc	dx
	call	GrDrawVLine
	mov	ax, cx				; ax <- right x
	call	GrDrawVLine

	.leave
	ret
DrawDrop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DribbleAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the dribble

CALLED BY:	MSG_DRIBBLE_APP_DRAW

PASS:		ds:[di] = DribbleApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	3/25/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DribbleAppDraw	method	dynamic	DribbleApplicationClass, 
						MSG_DRIBBLE_APP_DRAW

	tst	ds:[di].SAI_curGState
	jz	quit

	;
	; Dribbling or not?
	;

	tst	ds:[di].DAI_paint
	jz	dropDone			; branch if not dribbling

	;
	; Draw the current drop
	;

	mov	ax, es:[curDrop].DD_pos.P_x
	mov	bx, es:[curDrop].DD_pos.P_y
	mov	dx, es:[curDrop].DD_radius
	call	DrawDrop

	;
	; dribble to the side, back and forth +-1
	;

	mov	dx, 3
	push	bx
	mov	bx, ds:[di].DAI_random
	call	SaverRandom
	pop	bx
	dec	dx
	add	es:[curDrop].DD_pos.P_x, dx

	;
	; dribble down a bit
	;

	mov	dx, es:[curDrop].DD_radius
	shr	dx, 1

	sub	es:[curDrop].DD_shrinkDistance, dx
	jg	doneShrink

	;
	; Make the drop smaller, but not too small
	;

	mov	dx, es:[curDrop].DD_radius
	dec	dx
	cmp	dx, DRIBBLE_MIN_DROP_SIZE
	jge	dribbleSizeOk
	mov	dx, DRIBBLE_MIN_DROP_SIZE

dribbleSizeOk:

doneShrink:
	;
	; Update the y position and the remainging length
	;
	add	es:[curDrop].DD_pos.P_y, dx
	sub	es:[curDrop].DD_length, dx
	jl	dropDone
	
done:
	;
	; Set a timer for next time
	;

	call	DribbleSetTimer
quit:

	.leave
	ret

dropDone:
	;
	; We've finished a drop.  Have we drawn enough to clear
	; the screen?
	;
	inc	es:[numDrops]
	mov	ax, es:[numDrops]		; ax <- # of drops drawn
	cmp	ax, ds:[di].DAI_interval	; enough drawn this time?
	jb	drawOK

	call	DribbleClear
	clr	es:[numDrops]

drawOK:
	call	InitDrop			; initialize new drop
	jmp	short	done

DribbleAppDraw		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DribbleClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the screen

CALLED BY:	DribbleAppDraw

PASS:		ds:[di] = DribbleApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/17/91	Initial version
	stevey	12/20/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DribbleClear	proc	near
	class	DribbleApplicationClass
	uses	si, di
	.enter

	;
	; Clear the screen
	;

	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor

	clr	ax
	mov	bx, ax
	mov	cx, es:[winWidth]
	mov	dx, es:[winHeight]
	mov	si, SAVER_FADE_FAST_SPEED
	call	SaverFadePatternFade

	.leave
	ret
DribbleClear	endp

DribbleCode	ends
