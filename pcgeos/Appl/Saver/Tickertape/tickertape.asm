COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Tickertape
FILE:		tickertape.asm

AUTHOR:		Jeremy Dashe, April 2nd, '91

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/23/91		Initial revision
	jeremy	4/2/91		Revamped to do tickertape instead

DESCRIPTION:
	This is a specific screen-saver library

	$Id: tickertape.asm,v 1.1 97/04/04 16:47:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

include	tickertape.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

TickertapeApplicationClass	class	SaverApplicationClass

MSG_TICKERTAPE_APP_DRAW				message
;
;	Draw the next line of the tickertape. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    TAI_number		word		TICKERTAPE_DEFAULT_NUMBER
    TAI_length		word		TICKERTAPE_DEFAULT_LENGTH
    TAI_speed		word		TICKERTAPE_DEFAULT_SPEED
    TAI_clear		byte		TICKERTAPE_DEFAULT_CLEAR_MODE

    TAI_timerHandle	hptr		0
    	noreloc	TAI_timerHandle
    TAI_timerID		word		0

    TAI_random		hptr		0	; Random number generator
	noreloc	TAI_random

TickertapeApplicationClass	endc

TickertapeProcessClass	class	GenProcessClass
TickertapeProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	tickertape.rdef
ForceRef TickertapeApp

udata	segment

;
; Data describing the Tickertape we move around.
;
tickertapeParty		TickertapePartyStruct	<>

udata	ends

idata	segment

TickertapeProcessClass	mask	CLASSF_NEVER_SAVED
TickertapeApplicationClass

; Table of segment region pointers
segmentDataTable		label	word
	word	tickertapeTinySegmentRegion
	word	tickertapeSmallSegmentRegion
	word	tickertapeMediumSegmentRegion
	word	tickertapeLargeSegmentRegion

; Segment definitions:
tickertapeTinySegmentRegion		label	word
	word	-1, -1, 1, 1		; These are the region's bounds.
	word	-1, EOREGREC
	word	 0, -1, 1, EOREGREC
	word	 EOREGREC

tickertapeSmallSegmentRegion		label	word
	word	-2, -2, 2, 2		; These are the region's bounds.
	word	-2, EOREGREC
	word	-1, -1, 1, EOREGREC
	word	 0, -2, 2, EOREGREC
	word	 1, -1, 1, EOREGREC
	word	 EOREGREC

tickertapeMediumSegmentRegion		label	word
	word	-4, -4, 4, 4		; These are the region's bounds.
	word	-4, EOREGREC
	word	-3, -1, 1, EOREGREC
	word	-2, -2, 2, EOREGREC
	word	-1, -3, 3, EOREGREC
	word	 1, -3, 3, EOREGREC
	word	 2, -2, 2, EOREGREC
	word	 3, -1, 1, EOREGREC 
	word	 EOREGREC

tickertapeLargeSegmentRegion		label	word
	word	-6, -6, 6, 6		; These are the region's bounds.
	word	-6, EOREGREC
	word	-5, -3, 3, EOREGREC
	word	-4, -4, 4, EOREGREC
	word	-3, -5, 5, EOREGREC
	word	-1, -6, 6, EOREGREC
	word	 1, -6, 6, EOREGREC
	word	 3, -5, 5, EOREGREC
	word	 4, -4, 4, EOREGREC
	word	 5, -3, 3, EOREGREC
	word	 EOREGREC
	
tickertapeSizeTable	label	word
	word	TICKERTAPE_TINY
	word	TICKERTAPE_SMALL
	word	TICKERTAPE_MEDIUM
	word	TICKERTAPE_LARGE

NUMBER_OF_COLORS	equ	13
visibleColorTable	label	word
	word	C_BLUE, C_GREEN, C_CYAN, C_RED, C_VIOLET
	word	C_LIGHT_GRAY, C_LIGHT_BLUE, C_LIGHT_GREEN
	word	C_LIGHT_CYAN, C_LIGHT_RED, C_LIGHT_VIOLET
	word	C_YELLOW, C_WHITE

idata	ends

TickertapeCode	segment resource

.warn -private
tickertapeOptionTable	SAOptionTable	<
	tickertapeCategory, length tickertapeOptions
>
tickertapeOptions	SAOptionDesc	<
	tickertapeNumberKey, size TAI_number, offset TAI_number
>, <
	tickertapeLengthKey, size TAI_length, offset TAI_length
>, <
	tickertapeSpeedKey, size TAI_speed, offset TAI_speed
>, <
	tickertapeClearKey, size TAI_clear, offset TAI_clear
> 
.warn @private
tickertapeCategory	char	'tickertape', 0
tickertapeNumberKey	char	'number', 0
tickertapeLengthKey	char	'length', 0
tickertapeSpeedKey	char	'speed', 0
tickertapeClearKey	char	'clear', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickertapeLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= TickertapeApplication object
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickertapeLoadOptions	method dynamic TickertapeApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax,es
	.enter

	segmov	es, cs
	mov	bx, offset tickertapeOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset TickertapeApplicationClass
	GOTO	ObjCallSuperNoLock
TickertapeLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickertapeAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determines whether the screen will clear or not.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= TickertapeApplicationClass object
		ds:di	= TickertapeApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickertapeAppGetWinColor	method dynamic TickertapeApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its little thing.
	;

	mov	di, offset TickertapeApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].TickertapeApplication_offset

	ornf	ah, ds:[di].TAI_clear

	ret
TickertapeAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickertapeAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate, and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= TickertapeApplicationClass object
		ds:di	= TickertapeApplicationClass instance data
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickertapeAppSetWin	method dynamic TickertapeApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset TickertapeApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].TickertapeApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].TAI_random, bx

	;
	;  Initialize all the tickertape.
	;

	call	TickertapeStart

	;
	; Start up the timer to draw a new line.
	;

	call	TickertapeSetTimer
	.leave
	ret
TickertapeAppSetWin	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickertapeStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	TickertapeAppSetWin

PASS:		cx	= window handle
		dx	= window height
		si	= window width
		di	= gstate handle

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/24/91		Initial version
	jeremy	4/2/91		Cannibalized for worms
	jeremy	10/1/91		tickertapeized
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickertapeStart	proc	near
	class	TickertapeApplicationClass
	uses	ax,bx,cx,dx,si
	.enter

	mov	si, ds:[di].SAI_bounds.R_right
	sub	si, ds:[di].SAI_bounds.R_left
	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top

	inc	si			; make the screen a bit larger...
	inc	si
	inc	dx
	inc	dx
	mov	es:[tickertapeParty].TTPS_width, si
	mov	es:[tickertapeParty].TTPS_height, dx

	;
	; Set drawing colors and modes
	;

	push	di			; save instance data
	mov	di, ds:[di].SAI_curGState
	mov	al, MM_COPY
	call	GrSetMixMode

	mov	al, CMT_DITHER 
	call	GrSetAreaColorMap
	pop	di			; restore instance data

	;
	; Fetch the number of tickertape the user wants us to draw.
	;

	mov	cx, ds:[di].TAI_number
	clr	si

tickertapeLoop:
	call	InitTickertape
	add	si, size Tickertape	; si <- offset to next tickertape
	loop	tickertapeLoop

	.leave
	ret
TickertapeStart	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickertapeUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= TickertapeApplicationClass object

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickertapeUnsetWin	method dynamic TickertapeApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].TAI_timerHandle
	mov	ax, ds:[di].TAI_timerID
	call	TimerStop
	;
	; Nuke the random number generator.
	;

	clr	bx
	xchg	bx, ds:[di].TAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset TickertapeApplicationClass
	GOTO	ObjCallSuperNoLock
TickertapeUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTickertape
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one tickertape

CALLED BY:	TickertapeAppDraw, TickertapeStart

PASS:		ds:[di] = TickertapeApplicationInstance
		es	= dgroup
		si	= offset of Tickertape
		ax	= max x position for tickertape

RETURN:		nothing
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/91		Initial version
	jeremy	4/91		tickertape version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitTickertape	proc	near	
	class	TickertapeApplicationClass
	uses	ax, bx
	.enter

	mov	dx, es:[tickertapeParty].TTPS_width
	mov	bx, ds:[di].TAI_random
	call	SaverRandom
	mov	ax, dx			; ax <- random x position

	;
	; Set the random x position for the tickertape, and clear the y.
	;

	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_positions.P_x, ax
	clr	es:[tickertapeParty].TTPS_tickertape[si].TT_positions.P_y

	;
	; Pick a random size for this piece of tickertape.
	;

	mov	dx, TICKERTAPE_MAX_SIZE
	call	SaverRandom

	shl	dx, 1		; HACK!
	mov	bx, dx
	mov	dx, es:tickertapeSizeTable[bx]
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_size, dx
	mov	dx, es:segmentDataTable[bx]
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_regionPtr, dx

	;
	; Pick a random length for this piece of tickertape.
	;

	mov	dx, ds:[di].TAI_length
	mov	bx, ds:[di].TAI_random
	call	SaverRandom
	inc	dx			; make it at least 1.
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_length, dx

	;
	; Set the head and tail pointers to the same point.
	;

	clr	es:[tickertapeParty].TTPS_tickertape[si].TT_head
	clr	es:[tickertapeParty].TTPS_tickertape[si].TT_tail

	;
	; Choose a delay before the tickertape comes on screen
	;

	mov	dx, TICKERTAPE_INVISIBILITY_DELAY
	call	SaverRandom
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_countDown, dx

	;
	; Set initial direction.
	;

	mov	dx, TICKERTAPE_MAX_DIRECTION
	call	SaverRandom
	dec	dx
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_direction, dx

	;
	; Determine color of this tickertape.
	;

	mov	dx, NUMBER_OF_COLORS
	call	SaverRandom
	mov	bx, dx
	shl	bx, 1
	mov	dx, es:[visibleColorTable][bx]
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_color, dx

	.leave
	ret
InitTickertape	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawTickertapeSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a tickertape's segment

CALLED BY:	TickertapeAppDraw

PASS:		ds:[di] = TickertapeApplicationInstance
		(ax,bx) = center of the segment to draw
		dx	= color of segment to draw
		es:si	= segment region to draw

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/2/91		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawTickertapeSegment	proc	near
	class	TickertapeApplicationClass
	uses	ax,bx,cx,dx,ds,si,di
	.enter

	mov	di, ds:[di].SAI_curGState

	segmov	ds, es, cx	; ds:si = region

	mov	cx, ax		; save x position
	clr	ax
	mov	al, dl		; get color index
	call	GrSetAreaColor

	mov	ax, cx		; recover x position
	call	GrDrawRegion

	.leave
	ret
DrawTickertapeSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNewPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to update the head's x, y, and direction.

CALLED BY:	TickertapeAppDraw

PASS:		(ax, bx) = current head x and y position
		cx       = size of this tickertape
		dx	 = direction
		es	 = segment of tickertapeParty

RETURN:		(ax, bx) = new x and y
		cx	 = new size
		dx	 = new direction

DESTROYED:	anything but si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/8/91		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNewPosition		proc	near	
	class	TickertapeApplicationClass
	uses	si
	.enter

	cmp	dx, TICKERTAPE_LEFT	; is this tickertape going left?
	jne	checkForRight		; jump if not.

	;
	; The tickertape is pointing to the left.
	;
	sub	ax, cx				; move to the left a bit.
	mov	dx, TICKERTAPE_DOWN_AND_RIGHT	; reverse the direction,
					    	; pointing down.
	jmp	moveDown

checkForRight:
	cmp	dx, TICKERTAPE_RIGHT	; is this tickertape going right?
	jne	figureNewDirection 	; jump if not.

	;
	; The tickertape is pointing to the right.
	;
	add	ax, cx				; move to the right a bit
	mov	dx, TICKERTAPE_DOWN_AND_LEFT 	; reverse the direction,
					 	; pointing down.
	jmp	moveDown

figureNewDirection:
	;
	; The tickertape is going straight down, swinging in some direction.
	;
	add	dx, 1		; This makes the direction 0 or 2,
				; which is left or right.
moveDown:
	add	bx, cx		; move down a bit.
	push	ax
	mov	ax, es:[tickertapeParty].TTPS_height
	add	ax, 130
	cmp	bx, ax
	pop	ax
	jle	success

	;
	; We've hit the bottom... tell the caller to reset this tickertape.
	;

	stc
	jmp	allDone

success:
	clc			; signal that stuff is updated.
allDone:
	.leave
	ret
GetNewPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickertapeDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the can of tickertape

CALLED BY:	MSG_TICKERTAPE_APP_DRAW

PASS:		ds:[di] = TickertapeApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/25/91		Initial version
	jeremy	4/2/91		confounded with tickertape
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickertapeDraw	method	dynamic	TickertapeApplicationClass,
					MSG_TICKERTAPE_APP_DRAW
	.enter

	tst	ds:[di].SAI_curGState
	LONG	jz	quit

	push	si				; save object


	mov	cx, ds:[di].TAI_number		; cx <- # of tickertape
	clr	si

tickertapeLoop:
	push	cx				; Save loop number...

	;
	; Check to see if the tickertape is visible yet.
	;
	tst	es:[tickertapeParty].TTPS_tickertape[si].TT_countDown
	jz	visibleTickertape

	;
	; Nope, still waiting.  Go on to the next one.
	;
	dec	es:[tickertapeParty].TTPS_tickertape[si].TT_countDown
	jmp	endOfLoop

visibleTickertape:

	mov	dx, es:[tickertapeParty].TTPS_tickertape[si].TT_direction

	;
	; Move the head one segment in the new direction and erase the tail.
	;
	mov	bx, es:[tickertapeParty].TTPS_tickertape[si].TT_head
		CheckHack <size Point eq 4>
	shl	bx
	shl	bx
	mov	ax, es:[tickertapeParty].TTPS_tickertape[si].TT_positions[bx].P_x
	mov	bx, es:[tickertapeParty].TTPS_tickertape[si].TT_positions[bx].P_y
	mov	cx, es:[tickertapeParty].TTPS_tickertape[si].TT_size

	;
	; (ax, bx) is the head's current position, cx is the size of movement,
	; and dx is the new direction number.  Determine the new head
	; position.  If the tickertape has hit the bottom, we need to reset.
	;
	call	GetNewPosition	; (ax, bx) <- new pos, dx <- new direction
	jnc	drawTheSegment

	;
	; We need to reset the segment!
	;
	mov	ax, es:[tickertapeParty].TTPS_width
	call	InitTickertape
	jmp	endOfLoop

drawTheSegment:

	push	ax, bx, dx		; Save new (x, y) and direction
	mov	dx, es:[tickertapeParty].TTPS_tickertape[si].TT_color
	push	si			; save this segment
	mov	si, es:[tickertapeParty].TTPS_tickertape[si].TT_regionPtr
	call	DrawTickertapeSegment
	pop	si			; recover segment ptr

	;
	; Determine the head's new index.
	;
	mov	ax, es:[tickertapeParty].TTPS_tickertape[si].TT_length
	mov	bx, es:[tickertapeParty].TTPS_tickertape[si].TT_head
	inc	bx
	cmp	bx, ax
	jne	handleTailCollision
	clr	bx			; bx <- new head index

handleTailCollision:
	mov	ax, es:[tickertapeParty].TTPS_tickertape[si].TT_tail
	cmp	ax, bx			; head/tail collision?
	jne	setNewHead		; if not, don't reset tail

	;
	; The tail needs to be erased.
	;
	push	bx			; save head's index
	push	ax			; save tail's index	
	mov_tr	bx, ax
		CheckHack <size Point eq 4>
	shl	bx
	shl	bx
	mov	ax, es:[tickertapeParty].TTPS_tickertape[si].TT_positions[bx].P_x
	mov	bx, es:[tickertapeParty].TTPS_tickertape[si].TT_positions[bx].P_y

	mov	dx, TICKERTAPE_ERASE_COLOR
	push	si			; save this segment
	mov	si, es:[tickertapeParty].TTPS_tickertape[si].TT_regionPtr
	call	DrawTickertapeSegment	;
	pop	si			; recover segment ptr

	;
	; Increment tail index
	;
	pop	ax		; recover tail index
	inc	ax
	cmp	ax, es:[tickertapeParty].TTPS_tickertape[si].TT_length
	jne	setTailIndex
	clr	ax

setTailIndex:
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_tail, ax
	pop	bx		; recover head index

setNewHead:
	mov	es:[tickertapeParty].TTPS_tickertape[si].TT_head, bx
	
	;
	; Now move new head position and direction into new spot.
	;
		CheckHack <size Point eq 4>
	shl	bx
	shl	bx
	pop	es:[tickertapeParty].TTPS_tickertape[si].TT_direction
	pop	es:[tickertapeParty].TTPS_tickertape[si].TT_positions[bx].P_y
	pop	es:[tickertapeParty].TTPS_tickertape[si].TT_positions[bx].P_x

endOfLoop:
	add	si, size Tickertape
	pop	cx
	dec	cx
	and	cx, cx
	je	done
	jmp	tickertapeLoop

done:
	pop	si				; *ds:si = TickertapeApp
	call	TickertapeSetTimer		; setup another timer
quit:
	.leave
	ret

TickertapeDraw		endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TickertapeSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer

CALLED BY:	TickertapeStart, TickertapeDraw

PASS:		*ds:si = TickertapeApplicationInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/19/91		Initial version.
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TickertapeSetTimer	proc near		
	class	TickertapeApplicationClass
	uses ax,bx,cx,dx,di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].TickertapeApplication_offset

	;
	; Start up the timer to draw a tickertape
	;

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[di].TAI_speed
	mov	dx, MSG_TICKERTAPE_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination
	call	TimerStart

	mov	ds:[di].TAI_timerHandle, bx
	mov	ds:[di].TAI_timerID, ax

	.leave
	ret
TickertapeSetTimer	endp


TickertapeCode	ends
