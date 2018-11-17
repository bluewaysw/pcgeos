COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		palette
FILE:		palette.asm

AUTHOR:		Gene Anderson, Apr 7, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	4/7/92		Initial revision

DESCRIPTION:
	Palette animator code

	$Id: palette.asm,v 1.1 97/04/04 16:46:27 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def
include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def
ACCESS_VIDEO_DRIVER	= 1
UseDriver	Internal/videoDr.def

include	palette.def

;==============================================================================
;
;			    OBJECT CLASSES
;
;==============================================================================

PaletteApplicationClass	class	SaverApplicationClass

MSG_PALETTE_APP_DRAW				message
;
;	Draw the next line of the palette. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    PAI_color		word		PALETTE_RANDOM_COLOR
    PAI_speed		word		PALETTE_MEDIUM_SPEED

    PAI_timerHandle	hptr		0
    	noreloc	PAI_timerHandle
    PAI_timerID		word

    PAI_random		hptr		0	; Random number generator
	noreloc	PAI_random

PaletteApplicationClass	endc

PaletteProcessClass	class	GenProcessClass
PaletteProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	palette.rdef
ForceRef PaletteApp

udata	segment

driverStrategy	fptr.far

NUM_PAL_ENTRIES	equ	16

sysPalette	RGBValue NUM_PAL_ENTRIES dup (<>)
ourPalette	RGBValue NUM_PAL_ENTRIES dup (<>)

;
; Number of times we've been called to draw
;
drawCount	word

udata	ends

idata	segment

PaletteProcessClass	mask CLASSF_NEVER_SAVED
PaletteApplicationClass

idata	ends

;==============================================================================
;
;		 	  CODE 'N' STUFF
;
;==============================================================================

PaletteCode	segment resource

.warn -private
paletteOptionTable	SAOptionTable	<
	paletteCategory, length paletteOptions
>
paletteOptions	SAOptionDesc	<
>, <
	paletteSpeedKey, size PAI_speed, offset PAI_speed
>, <
	paletteColorKey, size PAI_color, offset PAI_color
>
.warn @private
paletteCategory	char	'palette', 0
paletteColorKey	char	'color', 0
paletteSpeedKey	char	'speed', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaletteLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= PaletteApplicationClass object
		ds:di	= PaletteApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaletteLoadOptions	method dynamic PaletteApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax, es
	.enter

	segmov	es, cs
	mov	bx, offset paletteOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset PaletteApplicationClass
	GOTO	ObjCallSuperNoLock
PaletteLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaletteAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate and start things rolling.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= PaletteApplicationClass object
		ds:di	= PaletteApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaletteAppSetWin	method dynamic PaletteApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	.enter
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset PaletteApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].PaletteApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].PAI_random, bx

	;
	;  Do Palette-app-specific initialization.
	;

	call	PaletteStart

	;
	; Start up the timer to draw a new line.
	;

	call	PaletteSetTimer
	.leave
	ret
PaletteAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaletteStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	PaletteAppSetWin

PASS: 		*ds:si	= PaletteApplication object
		ds:[di]	= PaletteApplicationInstance

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaletteStart	proc	near
	class	PaletteApplicationClass
	uses	ax,bx,cx,dx,si,di
	.enter

	clr	es:[drawCount]

	;
	; Get the video driver strategy for later
	;

	mov	di, ds:[di].SAI_curGState
	mov	si, WIT_STRATEGY		; si <- WinInfoType
	call	WinGetInfo
	mov	es:[driverStrategy].segment, cx
	mov	es:[driverStrategy].offset, dx

	;
	; Save the original palette
	;

	mov	si, offset sysPalette		; ds:si <- ptr to palette
	mov	di, DR_VID_GET_PALETTE
	call	SetGetPalette

	;
	; Get another copy to muck with, if we want
	;

	mov	si, offset ourPalette		; ds:si <- ptr to palette
	mov	di, DR_VID_GET_PALETTE
	call	SetGetPalette

	.leave
	ret
PaletteStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaletteAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= PaletteApplicationClass object
		ds:di	= PaletteApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaletteAppUnsetWin	method dynamic PaletteApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].PAI_timerHandle
	mov	ax, ds:[di].PAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	;

	clr	bx
	xchg	bx, ds:[di].PAI_random
	call	SaverEndRandom

	;
	; Restore the original palette
	;
	mov	si, offset sysPalette		; es:si <- ptr to palette
	mov	di, DR_VID_SET_PALETTE
	call	SetGetPalette

	;
	; Call our superclass to take care of the rest.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset PaletteApplicationClass
	GOTO	ObjCallSuperNoLock
PaletteAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaletteSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	PaletteAppDraw, PaletteAppSetWin

PASS:		*ds:si	= PaletteApplication object

RETURN:		nothing
DESTROYED:	ax,bx,cx,dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaletteSetTimer	proc	near
	class	PaletteApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].PaletteApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, ds:[di].PAI_speed
	mov	dx, MSG_PALETTE_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si <- destination
	call	TimerStart

	mov	ds:[di].PAI_timerHandle, bx
	mov	ds:[di].PAI_timerID, ax

	.leave
	ret
PaletteSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PaletteAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of drawing the screen saver

CALLED BY:	MSG_PALETTE_APP_DRAW

PASS:		*ds:si	= PaletteApplication object
		ds:[di]	= PaletteApplicationInstance

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
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PaletteAppDraw	method	dynamic	PaletteApplicationClass,
						MSG_PALETTE_APP_DRAW
	.enter

	inc	es:[drawCount]

	;
	; Make sure there is a GState to draw with
	;		

	tst	ds:[di].SAI_curGState
	jz	quit

	push	ds:[LMBH_handle], si

	;
	; Animate the palette
	;

	mov	cx, NUM_PAL_ENTRIES		; cx <- # of entries
	clr	si				; si <- offset of 1st value
	mov	bx, ds:[di].PAI_color		; bx <- mode
	mov	bx, cs:[palModeRoutines][bx]	; bx <- correct routine for mode

palLoop:
	call	bx				; call specific routine
	add	si, size (RGBValue)		; si <- offset of next value
	loop	palLoop

	;
	; Set the new palette
	;

	mov	si, offset ourPalette		; ds:si <- ptr to palette
	mov	di, DR_VID_SET_PALETTE		; di <- VidEscCode
	call	SetGetPalette

	;
	; Set another timer for next time.
	; 

	pop	bx, si
	call	MemDerefDS
	call	PaletteSetTimer
quit:

	.leave
	ret
PaletteAppDraw	endm

palModeRoutines	nptr \
	RandomRGBColor,			; PALETTE_MODE_RANDOM
	ScaleRGBColor,			; PALETTE_MODE_SCALE
	SwapRandomColor,		; PALETTE_MODE_SHUFFLE
	DimColor			; PALETTE_MODE_DIM


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RandomRGBColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a random RGB color

CALLED BY:	PaletteAppDraw

PASS:		es:ourPalette[si] - ptr to RGBValue

RETURN:		es:ourPalette[si] - filled in

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RandomRGBColor	proc	near
	uses	ax, dx
	.enter

	call	GetRandomRGBValue
	mov	es:ourPalette[si].RGB_red, al
	call	GetRandomRGBValue
	mov	es:ourPalette[si].RGB_green, al
	call	GetRandomRGBValue
	mov	es:ourPalette[si].RGB_blue, al

	.leave
	ret
RandomRGBColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleRGBColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale the existing RGB color

CALLED BY:	PaletteAppDraw

PASS:		es:sysPalette[si] - ptr to current RGBValue

RETURN:		es:ourPalette[si] - filled in

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScaleRGBColor	proc	near
	uses	ax, bx, cx, dx
	.enter

	;
	; Find the maximum of R,G and B
	;

	mov	al, es:sysPalette[si].RGB_red	; al <- R is max
	mov	ah, es:sysPalette[si].RGB_blue
	cmp	al, ah
	jae	notBlueMax

	mov	al, ah				; al <- B is max

notBlueMax:
	mov	ah, es:sysPalette[si].RGB_green
	cmp	al, ah
	jae	notGreenMax

	mov	al, ah				; al <- G is max

notGreenMax:
	clr	ah
	mov	bx, ax				; bx <- maximum value

	;
	; Get a random RGB value from [0..255]
	;

	call	GetRandomRGBValue
	mov	dx, ax
	clr	ax				; bx.ax <- dividend
	clr	cx				; dx.cx <- divisor

	;
	; Calc the scale factor
	;	bx.ax = MAX(R,G,B)
	;	dx.cx = random RGB value [0..MAX(R,G,B)]
	;

	tst	bx				; random value zero?
	jz	gotScale			; branch if zero

	call	GrUDivWWFixed
	mov	bx, dx
	mov	ax, cx				; bx.ax <- scale factor

gotScale:
	;
	; Scale the color values
	;
	mov	dl, es:sysPalette[si].RGB_red	; dx.cx <- red value
	call	ScaleRGBValue
	mov	es:ourPalette[si].RGB_red, dl
	mov	dl, es:sysPalette[si].RGB_green	; dx.cx <- green value
	call	ScaleRGBValue
	mov	es:ourPalette[si].RGB_green, dl
	mov	dl, es:sysPalette[si].RGB_blue	; dx.cx <- blue value
	call	ScaleRGBValue
	mov	es:ourPalette[si].RGB_blue, dl

	.leave
	ret
ScaleRGBColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SwapRandomColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swap current entry with a random color

CALLED BY:	PaletteAppDraw

PASS:		ds:[di] = PaletteApplicationInstance  
		es:ourPalette[si] - ptr to RGBValue

RETURN:		es:ourPalette[si] - filled in

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(size RGBValue) eq 3>

SwapRandomColor	proc	near
	class	PaletteApplicationClass
	uses	ax,bx,cx,dx,si,di
	.enter

	mov	dx, NUM_PAL_ENTRIES		; dx <- # of entries
	mov	bx, ds:[di].PAI_random
	call	SaverRandom
	mov	di, dx
	shl	di, 1				; di <- # * 2
	add	di, dx				; di <- # * 3

	mov	cx, (size RGBValue)		; cx <- size of entry
swapLoop:
	mov	al, {byte}es:ourPalette[si]	; al <- byte from si
	xchg	{byte}es:ourPalette[di], al	; al <- byte from di
	mov	{byte}es:ourPalette[si], al	; store old di's in si's
	inc	di
	inc	si
	loop	swapLoop

	.leave
	ret
SwapRandomColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DimColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Dim an RGB color

CALLED BY:	PaletteAppDraw

PASS:		es:sysPalette[si] - ptr to current RGBValue

RETURN:		es:ourPalette[si] - filled in

DESTROYED:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/11/92		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DIM_MAX			equ	128
DIM_MAX_SHIFT 		equ	2	; =lg2(256*2-DIM_MAX)=lg2(4)
DIM_SPEED_SHIFT		equ	2

DimColor	proc	near
	uses	ax,bx,cx,dx
	.enter

	;
	; Calculate the scale factor
	;   0 to DIM_MAX/2-1 is getting darker
	;   DIM_MAX/2 to DIM_MAX-1 is getting lighter
	;

	mov	ax, es:[drawCount]
	mov	cl, DIM_SPEED_SHIFT
	shl	ax, cl

	andnf	ax, DIM_MAX-1			; ax <- 0..max-1
	cmp	ax, DIM_MAX/2 - 1
	jbe	darker

	sub	al, DIM_MAX/2 			; make ascending
	mov	ah, al				; ah <- value
	jmp	gotScale

darker:
	mov	ah, DIM_MAX/2 - 1		; make descending
	sub	ah, al				; ah <- value

gotScale:
	mov	cl, DIM_MAX_SHIFT
	shl	ah, cl				; ah <- multiply to get 256
	clr	al				; ax <- factor as percentage
	clr	bx				; bx.ax <- scale factor

	;
	; Scale the RGB values
	;

	mov	dl, es:sysPalette[si].RGB_red
	call	ScaleRGBValue
	mov	es:ourPalette[si].RGB_red, dl
	mov	dl, es:sysPalette[si].RGB_blue
	call	ScaleRGBValue
	mov	es:ourPalette[si].RGB_blue, dl
	mov	dl, es:sysPalette[si].RGB_green
	call	ScaleRGBValue
	mov	es:ourPalette[si].RGB_green, dl

	.leave
	ret
DimColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRandomRGBValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a random R,G, or B value

CALLED BY:	INTERNAL

PASS:		ds:[di] = PaletteApplicationInstance

RETURN:		ax - random R,G, or B value

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetRandomRGBValue	proc	near
	class	PaletteApplicationClass
	uses	bx, dx
	.enter

	mov	dx, 255+1			; dx <- range is 0-255
	mov	bx, ds:[di].PAI_random
	call	SaverRandom
	mov	ax, dx				; ax <- random R,G or B

	.leave
	ret
GetRandomRGBValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ScaleRGBValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scale an RGB value

CALLED BY:	INTERNAL

PASS:		bx.ax - scale factor (WWFixed)
		dl - value

RETURN:		dl - scaled value
DESTROYED:	cx, dh

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ScaleRGBValue	proc	near
	.enter

	clr	dh
	clr	cx				; dx.cx <- RGB value
	call	GrMulWWFixed

	.leave
	ret
ScaleRGBValue	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetGetPalette
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set or get a palette

CALLED BY:	PaletteAppDraw

PASS:		es:si - ptr to palette
		es - seg addr of dgroup
		di - DR_VID_SET_PALETTE or DR_VID_GET_PALETTE

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 7/92		Initial version
	stevey	1/5/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetGetPalette	proc	near
	uses	ax, cx, dx, di
	.enter

	mov	dx, es				; dx:si <- ptr to table
	mov	cx, NUM_PAL_ENTRIES		; cx <- # of entries
	clr	al				; al <- GetSetPalFlags
	clr	ah				; ah <- start at 0
	call	es:[driverStrategy]

	.leave
	ret
SetGetPalette	endp

PaletteCode	ends
