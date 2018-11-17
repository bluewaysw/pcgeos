COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Specific Screen Saver -- Worms
FILE:		worms.asm

AUTHOR:		Jeremy Dashe, April 2nd, '91

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/23/91		Initial revision
	jeremy	4/2/91		Revamped to do worms instead
	stevey	12/15/92	port to 2.0

DESCRIPTION:

	This is a specific screen-saver library ("Worms").

	$Id: worms.asm,v 1.1 97/04/04 16:48:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include	timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def

include	worms.def

WormsApplicationClass	class	SaverApplicationClass

MSG_WORMS_APP_DRAW			message
;
;	Draw some worms
;
;	Pass: nothing
;	Return: nothing
;

	WAI_numWorms	word	WORMS_DEFAULT_NUMBER_OF_WORMS
	WAI_length	word	WORMS_DEFAULT_WORM_LENGTH
	WAI_wiggle	word	WORMS_DEFAULT_WIGGLE_FACTOR
	WAI_thickness	word	WORMS_DEFAULT_SEGMENT_SIZE
	WAI_speed	word	WORMS_DEFAULT_SPEED
	WAI_clear	byte	TRUE

	WAI_timerHandle	hptr	0
		noreloc	WAI_timerHandle
	WAI_timerID	word
	WAI_random	hptr	0
		noreloc	WAI_random

WormsApplicationClass	endc

WormsProcessClass	class	GenProcessClass
WormsProcessClass	endc

;=============================================================================
;
;				VARIABLES
;
;=============================================================================

include	worms.rdef
ForceRef WormsApp

udata	segment

;
; Data describing the Worms we move around.
;
canOfWorms		CanOfWormsStruct	<>

udata	ends

idata	segment

;
; Pointer to the segment region
;
wormSegmentRegion		word	wormMediumSegmentRegion

; Table of segment region pointers
segmentDataTable		label	word
	word	wormTinySegmentRegion
	word	wormSmallSegmentRegion
	word	wormMediumSegmentRegion
	word	wormLargeSegmentRegion

; Segment definitions:
wormTinySegmentRegion		label	word
	word	-1, -1, 1, 1		; These are the region's bounds.
	word	-1, EOREGREC
	word	 0, -1, 1, EOREGREC
	word	 EOREGREC

wormSmallSegmentRegion		label	word
	word	-2, -2, 2, 2		; These are the region's bounds.
	word	-2, EOREGREC
	word	-1, -1, 1, EOREGREC
	word	 0, -2, 2, EOREGREC
	word	 1, -1, 1, EOREGREC
	word	 EOREGREC

wormMediumSegmentRegion		label	word
	word	-4, -4, 4, 4		; These are the region's bounds.
	word	-4, EOREGREC
	word	-3, -1, 1, EOREGREC
	word	-2, -2, 2, EOREGREC
	word	-1, -3, 3, EOREGREC
	word	 1, -3, 3, EOREGREC
	word	 2, -2, 2, EOREGREC
	word	 3, -1, 1, EOREGREC 
	word	 EOREGREC

wormLargeSegmentRegion		label	word
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

;	
; Movement offset definitions for the different segment sizes:
;
NO_X_MOVEMENT			equ	0
NO_Y_MOVEMENT			equ	0

TINY_POSITIVE_X_MOVEMENT	equ	 1
TINY_POSITIVE_Y_MOVEMENT	equ	 1
TINY_NEGATIVE_X_MOVEMENT	equ	-1
TINY_NEGATIVE_Y_MOVEMENT	equ	-1

SMALL_POSITIVE_X_MOVEMENT	equ	 2
SMALL_POSITIVE_Y_MOVEMENT	equ	 2
SMALL_NEGATIVE_X_MOVEMENT	equ	-2
SMALL_NEGATIVE_Y_MOVEMENT	equ	-2

MED_POSITIVE_X_MOVEMENT		equ	 4
MED_POSITIVE_Y_MOVEMENT		equ	 4
MED_NEGATIVE_X_MOVEMENT		equ	-4
MED_NEGATIVE_Y_MOVEMENT		equ	-4

LARGE_POSITIVE_X_MOVEMENT	equ	 6
LARGE_POSITIVE_Y_MOVEMENT	equ	 6
LARGE_NEGATIVE_X_MOVEMENT	equ	-6
LARGE_NEGATIVE_Y_MOVEMENT	equ	-6

headMovementTableX		word	headMediumMovementX
headMovementTableY		word	headMediumMovementY

; Table of pointers to the head movement tables
headMovementTableXSource	label	word
	word	headTinyMovementX
	word	headSmallMovementX
	word	headMediumMovementX
	word	headLargeMovementX

headMovementTableYSource	label	word
	word	headTinyMovementY
	word	headSmallMovementY
	word	headMediumMovementY
	word	headLargeMovementY

headTinyMovementX		label	word
	word	NO_X_MOVEMENT
	word	TINY_POSITIVE_X_MOVEMENT
	word	TINY_POSITIVE_X_MOVEMENT
	word	TINY_POSITIVE_X_MOVEMENT
	word	NO_X_MOVEMENT
	word	TINY_NEGATIVE_X_MOVEMENT
	word	TINY_NEGATIVE_X_MOVEMENT
	word	TINY_NEGATIVE_X_MOVEMENT

headTinyMovementY		label	word
	word	TINY_NEGATIVE_Y_MOVEMENT
	word	TINY_NEGATIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	TINY_POSITIVE_Y_MOVEMENT
	word	TINY_POSITIVE_Y_MOVEMENT
	word	TINY_POSITIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	TINY_NEGATIVE_Y_MOVEMENT

headSmallMovementX		label	word
	word	NO_X_MOVEMENT
	word	SMALL_POSITIVE_X_MOVEMENT
	word	SMALL_POSITIVE_X_MOVEMENT
	word	SMALL_POSITIVE_X_MOVEMENT
	word	NO_X_MOVEMENT
	word	SMALL_NEGATIVE_X_MOVEMENT
	word	SMALL_NEGATIVE_X_MOVEMENT
	word	SMALL_NEGATIVE_X_MOVEMENT

headSmallMovementY		label	word
	word	SMALL_NEGATIVE_Y_MOVEMENT
	word	SMALL_NEGATIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	SMALL_POSITIVE_Y_MOVEMENT
	word	SMALL_POSITIVE_Y_MOVEMENT
	word	SMALL_POSITIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	SMALL_NEGATIVE_Y_MOVEMENT

headMediumMovementX		label	word
	word	NO_X_MOVEMENT
	word	MED_POSITIVE_X_MOVEMENT
	word	MED_POSITIVE_X_MOVEMENT
	word	MED_POSITIVE_X_MOVEMENT
	word	NO_X_MOVEMENT
	word	MED_NEGATIVE_X_MOVEMENT
	word	MED_NEGATIVE_X_MOVEMENT
	word	MED_NEGATIVE_X_MOVEMENT

headMediumMovementY		label	word
	word	MED_NEGATIVE_Y_MOVEMENT
	word	MED_NEGATIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	MED_POSITIVE_Y_MOVEMENT
	word	MED_POSITIVE_Y_MOVEMENT
	word	MED_POSITIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	MED_NEGATIVE_Y_MOVEMENT

headLargeMovementX		label	word
	word	NO_X_MOVEMENT
	word	LARGE_POSITIVE_X_MOVEMENT
	word	LARGE_POSITIVE_X_MOVEMENT
	word	LARGE_POSITIVE_X_MOVEMENT
	word	NO_X_MOVEMENT
	word	LARGE_NEGATIVE_X_MOVEMENT
	word	LARGE_NEGATIVE_X_MOVEMENT
	word	LARGE_NEGATIVE_X_MOVEMENT

headLargeMovementY		label	word
	word	LARGE_NEGATIVE_Y_MOVEMENT
	word	LARGE_NEGATIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	LARGE_POSITIVE_Y_MOVEMENT
	word	LARGE_POSITIVE_Y_MOVEMENT
	word	LARGE_POSITIVE_Y_MOVEMENT
	word	NO_Y_MOVEMENT
	word	LARGE_NEGATIVE_Y_MOVEMENT

NUMBER_OF_COLORS	equ	13
visibleColorTable	label	word
	word	C_BLUE, C_GREEN, C_CYAN, C_RED, C_VIOLET
	word	C_LIGHT_GRAY, C_LIGHT_BLUE, C_LIGHT_GREEN
	word	C_LIGHT_CYAN, C_LIGHT_RED, C_LIGHT_VIOLET
	word	C_YELLOW, C_WHITE

WormsProcessClass	mask CLASSF_NEVER_SAVED
WormsApplicationClass

idata	ends

WormsCode	segment resource

.warn -private
wormsOptionTable	SAOptionTable	<
	wormsCategory, length wormsOptions
>
wormsOptions	SAOptionDesc	<
	wormsNumWormsKey, size WAI_numWorms, offset WAI_numWorms
>, <
	wormsLengthKey, size WAI_length, offset WAI_length
>, <
	wormsWiggleKey, size WAI_wiggle, offset WAI_wiggle
>, <
	wormsThicknessKey, size WAI_thickness, offset WAI_thickness
>, <
	wormsSpeedKey, size WAI_speed, offset WAI_speed
>, <
	wormsClearKey, size WAI_clear, offset WAI_clear
>

.warn @private
wormsCategory		char	'worms', 0
wormsNumWormsKey	char	'numWorms', 0
wormsLengthKey		char	'length', 0
wormsWiggleKey		char	'wiggle', 0
wormsThicknessKey	char	'thickness', 0
wormsSpeedKey		char	'speed', 0
wormsClearKey		char	'clear', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= WormsApplicationClass object

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsLoadOptions	method dynamic WormsApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	es
	.enter

	segmov	es, cs
	mov	bx, offset wormsOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset WormsApplicationClass
	GOTO	ObjCallSuperNoLock
WormsLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate to use, and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= WormsApplicationClass object
		dx	= window
		bp	= gstate

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsAppSetWin	method dynamic WormsApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset WormsApplicationClass
	call	ObjCallSuperNoLock

	;
	; Now initialize our state. 
	;
 
	mov	di, ds:[si]
	add	di, ds:[di].WormsApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx				; dxax <- seed
	clr	bx				; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].WAI_random, bx

	;
	; Now initialize all the worms and set the timer.
	;

	call	WormsStart

	ret
WormsAppSetWin	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= WormsApplicationClass object
		ds:di	= WormsApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsAppUnsetWin	method dynamic WormsApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].WAI_timerHandle
	mov	ax, ds:[di].WAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	;

	clr	bx
	xchg	bx, ds:[di].WAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset WormsApplicationClass
	GOTO	ObjCallSuperNoLock
WormsAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decide whether to clear the screen or not.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= WormsApplicationClass object
		ds:di	= WormsApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/15/92   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsAppGetWinColor	method dynamic WormsApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thing.
	;

	mov	di, offset WormsApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].WormsApplication_offset

	cmp	ds:[di].WAI_clear, TRUE
	je	done

	ornf	ah, mask WCF_TRANSPARENT
done:
	ret
WormsAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	WormsAppSetWin

PASS:		*ds:si	= WormsApplication object
		ds:di	= WormsApplication instance data
		es	= dgroup

RETURN:		nothing
DESTROYED:	anything

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/24/91		Initial version
	jeremy	4/2/91		Cannibalized for worms (yuck...)
	stevey	12/16/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsStart	proc	near
	class	WormsApplicationClass

	;
	;  store width & height (and make them a little larger)
	;

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	inc	dx
	inc	dx
	mov	es:[canOfWorms].COWS_width, dx

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	inc	dx
	inc	dx
	mov	es:[canOfWorms].COWS_height, dx

	mov	bp, ds:[di].SAI_bounds.R_right
	sub	bp, ds:[di].SAI_bounds.R_left
	inc	bp
	inc	bp
	mov	es:[canOfWorms].COWS_width, bp

	;
	; Set drawing colors and modes
	;

	mov	di, ds:[di].SAI_curGState
	mov	al, MM_COPY
	call	GrSetMixMode

	mov	al, CMT_DITHER
	call	GrSetAreaColorMap

	;
	; Load the correct segment widths
	;

	mov	di, ds:[si]
	add	di, ds:[di].WormsApplication_offset
	mov	cx, ds:[di].WAI_thickness
	call	WormsSetSegmentSize

	;
	; Figure out where all of the worms should start.
	;

	inc	dx			; == height + 1
	mov	bx, ds:[di].WAI_random
	call	SaverRandom

	push	si			; save WormsApp object chunk handle
	mov	si, bp			; si = width
	
	mov	bp, dx			; bp <- random y position
	mov	dx, si
	inc	dx			; == width + 1
	call	SaverRandom
	mov	ax, dx			; ax <- random x position

	;
	; Fetch the number of worms the user wants us to draw.
	;
	

	mov	cx, ds:[di].WAI_numWorms
	clr	si

wormLoop:
	call	InitWorm
	add	si, size Worm		; si <- offset to next worm
	loop	wormLoop

	;
	;  Restore *ds:si and set the timer.
	;

	pop	si			; *ds:si = WormsApplication object
	call	WormsSetTimer

	ret
WormsStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitWorm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one worm

CALLED BY:	WormsAppDraw, WormsStart

PASS:		es 	= dgroup
		si	= offset of Worm
		ax	= x position for worm
		bp	= y position for worm
		bx	= token for SaverRandom

RETURN:		nothing
DESTROYED:	cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/91		Initial version
	jeremy	4/91		worms version
	stevey	12/16/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitWorm	proc	near	
	uses	ax, bp
	.enter

	;
	; Set the random position for the worm.
	;

	mov	es:[canOfWorms].COWS_worms[si].W_positions.P_x, ax
	mov	es:[canOfWorms].COWS_worms[si].W_positions.P_y, bp

	;
	; Set the head and tail pointers to the same point.
	;

	mov	es:[canOfWorms].COWS_worms[si].W_head, 0
	mov	es:[canOfWorms].COWS_worms[si].W_tail, 0
	
	;
	; Get random initial direction
	;

	mov	dx, WORMS_HIGHEST_DIRECTION
	call	SaverRandom
	mov	es:[canOfWorms].COWS_worms[si].W_direction, dx

	; Clear the whimsy counter

	mov	es:[canOfWorms].COWS_worms[si].W_wiggleChance, 0

	;
	; Determine color of this worm.
	;

	mov	dx, NUMBER_OF_COLORS
	call	SaverRandom
	mov	bp, dx
	shl	bp, 1
	mov	dx, es:visibleColorTable[bp]
	mov	es:[canOfWorms].COWS_worms[si].W_color, dx

	.leave
	ret
InitWorm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSegment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a worm's segment

CALLED BY:	WormsDraw

PASS:		ds:[di] = WormsApplication instance data
		(ax,bp) = center of the segment to draw
		dx	= color of segment to draw

RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/2/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawWormSegment	proc	near
	class	WormsApplicationClass
	uses	ax,bx,cx,dx,si,di,bp,ds
	.enter

	mov	bx, bp

	mov	di, ds:[di].SAI_curGState

	mov_tr	cx, ax		; save x position
	mov	ah, CF_INDEX
	mov	al, dl		; get color index
	call	GrSetAreaColor

	mov	ax, cx		; recover x position
	mov	si, es:[wormSegmentRegion]
	segmov	ds, es, bp
	call	GrDrawRegion

	.leave
	ret
DrawWormSegment	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNewPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to update the head's x, y, and direction.

CALLED BY:	WormsDraw

PASS:		(ax, bp) = current head x and y position
		dx	 = direction
		es	 = segment of canOfWorms

RETURN:		(ax, bp) = new x and y
		dx	 = new direction

DESTROYED:	anything I want

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	4/8/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNewPosition		proc	near	
	uses	si
	.enter

	mov	cx, bp		; save x position

calculateNewXY:
	mov	bp, dx
	shl	bp, 1		; bp <- index into movement table

	mov	si, es:[headMovementTableX]
	add	ax, es:[si][bp]
	cmp	ax, -2
	jge	checkXBoundary
tryXAgain:
	mov	si, es:[headMovementTableX]
	sub	ax, es:[si][bp] 		; reset ax
	call	GetNewDirection			; dx <- new direction
	jmp	calculateNewXY

checkXBoundary:
	cmp	ax, es:[canOfWorms].COWS_width
	jg	tryXAgain

checkYZeroBoundary::
	mov	si, es:[headMovementTableY]
	add	cx, es:[si][bp]
	cmp	cx, -2
	jge	checkYBoundary
tryYAgain:
	mov	si, es:[headMovementTableY]
	sub	cx, es:[si][bp]
	call	GetNewDirection			; dx <- new direction
	jmp	calculateNewXY

checkYBoundary:
	cmp	cx, es:[canOfWorms].COWS_height
	jg	tryYAgain

	mov	bp, cx

	.leave
	ret
GetNewPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetNewDirection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We just hit a wall, so get a new direction pointing away
		from the collision.

CALLED BY:	GetNewPosition

PASS:		ds:[di] = WormsApplication instance data
		es = dgroup
		dx = current direction
		ax = X position
		cx = Y position

RETURN:		dx = new direction
		ax = (possibly) adjusted X
		cx = (possibly) adjusted Y

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	jeremy	4/8/91			Initial version
	stevey	12/16/92		header + port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetNewDirection	proc	near
	class	WormsApplicationClass
	uses	bx
	.enter

	push	ax, cx			; save passed x & y for return and
					;  possible maladjustment
	mov	cx, dx
	mov	dx, 3
	mov	bx, ds:[di].WAI_random	; bx <- RNG
	call	SaverRandom
	add	dx, cx
	inc	dx
	inc	dx
	inc	dx
	and	dx, 7			; dx <- new head direction

	mov	ax, ds:[di].WAI_wiggle
	tst	ax
	pop	ax, cx			; recover x, y
	jnz	done

	;
	; Since the wiggle factor is zero, jitter the worm a bit.
	;

	test	ax, 1			; random test?  Who knows...
	jz	incX			; jump to increase X
	dec	ax
	jge	done
	inc	ax
	inc	ax
	jmp	done

incX:
	inc	ax
	cmp	ax, es:[canOfWorms].COWS_width
	jle	done
	dec	ax
	dec	ax

done:
	.leave
	ret
GetNewDirection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the can of worms.

CALLED BY:	MSG_WORMS_APP_DRAW

PASS:		*ds:si	= WormsApplication object
		ds:di	= WormsApplication instance data
		es	= dgroup

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/25/91		Initial version
	jeremy	4/2/91		confounded with worms
	stevey	12/16/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsAppDraw	method	dynamic	WormsApplicationClass,
						MSG_WORMS_APP_DRAW
	.enter

	tst	ds:[di].SAI_curGState
	LONG	jz	quit

	push	si				; save object


	mov	cx, ds:[di].WAI_numWorms
	clr	si

	mov	bx, ds:[di].WAI_random

wormLoop:
	push	cx		; Save loop number...

	;
	; Determine the wiggle for this worm.
	;
	mov	dx, ds:[di].WAI_wiggle

	;
	; If there's no change in direction, move straight ahead.
	;
	tst	dx
	jnz	determineNewDirection

moveInSameDirection::
	;
	; Will the worm get a sudden feeling that it should take a turn?
	;
	mov	dx, WHIMSY_SEED
	call	SaverRandom
	tst	dx
	jnz	notWhimsical	; usually the case
	mov	dx, 1
	jmp	determineNewDirection

notWhimsical:
	;
	; Move in the same direction we're already pointing...
	;
	mov	dx, es:[canOfWorms].COWS_worms[si].W_direction
	jmp	determineNextHeadSpot

determineNewDirection:

	push	dx
	rol	dx, 1		; we want a number between 0 and
	inc	dx		;  2 * wiggle_factor + 1.
	call	SaverRandom	; dx <- random number
	pop	ax		; ax <- wiggle factor
	sub	dx, ax		; dx <- number to add to direction number
				;       (can be negative).
	add	dx, es:[canOfWorms].COWS_worms[si].W_direction
	and	dx, 7		; dx <- new direction!

determineNextHeadSpot:
	;
	; At this point, dx has a new direction number.
	; Move the head one segment in the new direction and erase the tail.
	;
	mov	bp, es:[canOfWorms].COWS_worms[si].W_head
		CheckHack <size Point eq 4>
	shl	bp
	shl	bp
	mov	ax, es:[canOfWorms].COWS_worms[si].W_positions[bp].P_x
	mov	bp, es:[canOfWorms].COWS_worms[si].W_positions[bp].P_y

	;
	; (ax, bp) is the head's current position, dx is the new direction
	; number.  Determine the new head position (and direction, if
	; we've hit a wall).
	;

	call	GetNewPosition	; (ax, bp) <- new pos, dx <- new direction
	push	ax, bp, dx	; Save new (x, y) and direction
	mov	dx, es:[canOfWorms].COWS_worms[si].W_color

	call	DrawWormSegment

	;
	; Determine the head's new index.
	;
	mov	ax, ds:[di].WAI_length
	mov	bp, es:[canOfWorms].COWS_worms[si].W_head
	inc	bp
	cmp	bp, ax
	jne	handleTailCollision
	clr	bp				; bp <- new head index

handleTailCollision:

	mov	ax, es:[canOfWorms].COWS_worms[si].W_tail
	cmp	ax, bp				; head/tail collision?
	jne	setNewHead			; if not, don't reset tail

	;
	; The tail needs to be erased.
	;
	push	bp				; save head's index
	push	ax				; save tail's index	
	mov_tr	bp, ax
		CheckHack <size Point eq 4>
	shl	bp
	shl	bp
	mov	ax, es:[canOfWorms].COWS_worms[si].W_positions[bp].P_x
	mov	bp, es:[canOfWorms].COWS_worms[si].W_positions[bp].P_y

	mov	dx, WORMS_ERASE_COLOR
	call	DrawWormSegment

	;
	; Increment tail index
	;
	pop	ax				; recover tail index
	inc	ax
	cmp	ax, ds:[di].WAI_length
	jne	setTailIndex
	xor	ax, ax

setTailIndex:

	mov	es:[canOfWorms].COWS_worms[si].W_tail, ax
	pop	bp				; recover head index

setNewHead:

	mov	es:[canOfWorms].COWS_worms[si].W_head, bp

	;	
	; Now move new head position and direction into new spot.
	;
		CheckHack <size Point eq 4>
	shl	bp
	shl	bp
	pop	es:[canOfWorms].COWS_worms[si].W_direction
	pop	es:[canOfWorms].COWS_worms[si].W_positions[bp].P_y
	pop	es:[canOfWorms].COWS_worms[si].W_positions[bp].P_x

	add	si, size Worm
	pop	cx
	dec	cx
	tst	cx
	jz	done
	jmp	wormLoop

done:
	pop	si				; restore object

	call	WormsSetTimer			; setup another timer
quit:
	.leave
	ret
WormsAppDraw		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer

CALLED BY:	WormsStart, WormsDraw

PASS:		*ds:si = WormsApplication object

RETURN:		nothing
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	CDB	9/19/91		Initial version.
	stevey	12/15/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsSetTimer	proc near
	class	WormsApplicationClass
	uses ax,bx,cx,dx,di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].WormsApplication_offset

	;
	; Start up the timer to draw a worm
	;

	mov	cx, ds:[di].WAI_speed
	mov	al, TIMER_EVENT_ONE_SHOT
	mov	dx, MSG_WORMS_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si <- destination
	call	TimerStart

	mov	ds:[di].WAI_timerHandle, bx
	mov	ds:[di].WAI_timerID, ax

	.leave
	ret
WormsSetTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		WormsSetSegmentSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the width of the worms' segments.

CALLED BY:	WormSegmentSize

PASS:		es = dgroup
		cx = index to size

RETURN:		nothing

DESTROYED:	ax, bx

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jeremy	5/3/91		initial version
	stevey	12/16/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
WormsSetSegmentSize	proc	near	

	mov	bx, cx

	mov	ax, es:[segmentDataTable][bx]
	mov	es:[wormSegmentRegion],  ax

	mov	ax, es:[headMovementTableXSource][bx]
	mov	es:[headMovementTableX], ax

	mov	ax, es:[headMovementTableYSource][bx]
	mov	es:[headMovementTableY], ax

	ret
WormsSetSegmentSize	endp

WormsCode	ends
