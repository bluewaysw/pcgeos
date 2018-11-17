COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1991 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		bobbin
FILE:		bobbin.asm

AUTHOR:		Gene Anderson, Sep 11, 1991

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	11/6/91		Initial revision

DESCRIPTION:
	.asm file for bobbin specific screen-saver library

	$Id: bobbin.asm,v 1.1 97/04/04 16:43:45 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

include	bobbin.def

;=============================================================================
;
;				OBJECT CLASSES
;
;=============================================================================

BobbinApplicationClass	class	SaverApplicationClass

MSG_BOBBIN_APP_DRAW				message
;
;	Draw the next line of the bobbin. Sent by our timer.
;
;	Pass:	nothing
;	Return:	nothing
;

    BAI_speed		word		BOBBIN_MEDIUM_SPEED

    BAI_timerHandle	hptr		0
    	noreloc	BAI_timerHandle
    BAI_timerID		word

    BAI_random		hptr		0	; Random number generator
	noreloc	BAI_random

BobbinApplicationClass	endc

BobbinProcessClass	class	GenProcessClass
BobbinProcessClass	endc

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	bobbin.rdef
ForceRef BobbinApp

udata	segment

winHeight	word
winWidth	word

;
; Amazing, astounding variables
;
bobbinEndX	SaverVector			; moving end of thread (x)
bobbinEndY	word				; moving end of thread (y)
bobbinStartX	SaverVector			; 'static' end of thread (x)
bobbinStartY	word				; static end of thread (y)
curStep	word					; current step amount

dudeIsWalking	byte				; non-zero if dude is walking
curDude	byte					; current bitmap for dude
dudePos	Point					; position to dude draw at
curDudeBitmaps	word				; offset of table of 3 bitmaps
						;  for the little dude in
						;  code segment.
curDudeBitmapsLength byte			; # of bitmaps in table
dudeWalkGoal	word				; X coord to which the dude
						;  is walking.
dudeHandle	hptr				; correct resource
displayType	DisplayType			; color or B&W

udata	ends

idata	segment

BobbinProcessClass	mask	CLASSF_NEVER_SAVED
BobbinApplicationClass

lastColor	Color C_DARK_GRAY		; last color drawn in

idata	ends

;==============================================================================
;
;		   EXTERNAL WELL-DEFINED INTERFACE
;
;==============================================================================
BobbinCode	segment resource

bobbinSteps	word	BOBBIN_STEP_SLOW,
			BOBBIN_STEP_MEDIUM,
			BOBBIN_STEP_FAST

timerSpeeds	word	BOBBIN_TIMER_SLOW,
			BOBBIN_TIMER_MEDIUM,
			BOBBIN_TIMER_FAST

walkSpeeds	word	BOBBIN_WALK_SLOW,
			BOBBIN_WALK_MEDIUM,
			BOBBIN_WALK_FAST

.warn -private
bobbinOptionTable	SAOptionTable	<
	bobbinCategory, length bobbinOptions
>
bobbinOptions	SAOptionDesc	<
	bobbinSpeedKey, size BAI_speed, offset BAI_speed
> 
.warn @private
bobbinCategory	char	'bobbin', 0
bobbinSpeedKey	char	'speed', 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BobbinLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	load our options from the ini file

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= BobbinApplicationClass object
		ds:di	= BobbinApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BobbinLoadOptions	method dynamic BobbinApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	ax,es
	.enter

	segmov	es, cs
	mov	bx, offset bobbinOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset BobbinApplicationClass
	GOTO	ObjCallSuperNoLock
BobbinLoadOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BobbinAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures the screen isn't cleared on startup.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= BobbinApplicationClass object

RETURN:		ax	= WinColorFlags
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BobbinAppGetWinColor	method dynamic BobbinApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its little thing.
	;

	mov	di, offset BobbinApplicationClass
	call	ObjCallSuperNoLock

	ornf	ah, mask WCF_TRANSPARENT

	ret
BobbinAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BobbinAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window and gstate, and get things rolling.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= BobbinApplicationClass object
		dx	= window
		bp	= gstate
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BobbinAppSetWin	method dynamic BobbinApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	.enter
	;
	; Let the superclass do its little thing.
	;

	mov	di, offset BobbinApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].BobbinApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].BAI_random, bx

	call	BobbinStart

	;
	; Start up the timer to draw a new line.
	;

	call	BobbinSetTimer
	.leave
	ret
BobbinAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BobbinStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	BobbinAppSetWin

PASS: 		*ds:si	= BobbinApplicationClass
		ds:[di]	= BobbinApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	 3/24/91	Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BobbinStart	proc	near
	class	BobbinApplicationClass
	uses	ax,bx,cx,dx,si,di
	.enter

	;
	; Figure out which set of bitmaps to use
	;

	mov	ax, handle ColorDudes
	call	GetDisplayType			; returns in bl
	andnf	bl, mask DT_DISP_CLASS
	mov	es:[displayType], bl

	cmp	bl, (DC_COLOR_2 shl offset DT_DISP_CLASS)
	jae	isColor
	mov	ax, handle BWDudes

isColor:
	mov	es:[dudeHandle], ax

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	mov	es:[winWidth], dx

	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	mov	es:[winHeight], dx

	;
	; Initalize common stuff
	;

	mov	bx, ds:[di].BAI_speed
	mov	ax, cs:[bobbinSteps][bx]
	mov	es:[curStep], ax		; save step size

	;
	; Initialize the moving end of the bobbin
	;

	mov	si, ds:[di].BAI_random		; si = random number generator
	push	si

	mov	dx, es:[winHeight]
	sub	dx, MARGIN_HEIGHT		; dx <- bottom - margin
	mov	es:[bobbinEndY], dx		; dx <- y pos
	mov	bx, ds:[di].BAI_speed
	mov	di, offset bobbinEndX		; es:di <- ptr to vector
	mov	bx, cs:[bobbinSteps][bx]	; bl <- delta max
	mov	bh, bl				; bh <- delta base
	clr	cx				; cx <- minimum
	mov	dx, es:[winWidth]		; dx <- maximum
	mov	ax, SVRT_BOUNCE			; ax <- SaverVectorReflectType
	call	SaverVectorInit

	;
	; Initialize the static end of the bobbin
	;

	pop	si				; si = random number generator
	mov	dx, es:[winHeight]
	sub	dx, DUDE_HEIGHT			; dx <- win height - dude hght
	mov	es:[bobbinStartY], dx

	mov	di, offset bobbinStartX		; es:di <- ptr to vector
	mov	cx, es:[winWidth]
	shr	cx, 1				; cx <- win width / 2
	mov	dx, cx
	sub	cx, BOBBIN_SPOOL_LEFT		; cx <- minimum
	add	dx, BOBBIN_SPOOL_RIGHT		; dx <- maximum
	mov	bl, 1				; bl <- delta max
	mov	bh, bl				; bh <- delta base
	mov	ax, SVRT_BOUNCE			; ax <- SaverVectorReflectType
	call	SaverVectorInit

	;
	; Figure initial goal of dude, who is walking in from the right
	; 

	mov	cx, es:[winWidth]
	shr	cx, 1				; cx <- win width / 2
	sub	cx, (DUDE_WIDTH / 2)		; cx <- centered for bitmap
	mov	es:[dudeWalkGoal], cx		; walk dude to here

	;
	; Initialize the dude position
	;

	mov	cx, es:[winWidth]
	add	cx, DUDE_WIDTH
	mov	es:[dudePos].P_x, cx
	mov	dx, es:[winHeight]
	sub	dx, DUDE_HEIGHT-1		; dx <- win height - dude hght
	mov	es:[dudePos].P_y, dx

	;
	; Set dude a-walking
	;

	mov	es:[dudeIsWalking], 1
	mov	es:[curDudeBitmaps], offset walkDudeBitmaps
	mov	es:[curDudeBitmapsLength], length walkDudeBitmaps
	mov	es:[curDude], 0

	.leave
	ret
BobbinStart	endp

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDisplayType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the current display type into bl.

CALLED BY:	BobbinStart

PASS:		*ds:si	= BobbinApplication object

RETURN:		bl	= DisplayType

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date			Description
	----	----			-----------
	stevey	12/29/92		initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetDisplayType	proc	near
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	call	ObjCallInstanceNoLock		; returns in ah
	mov	bl, ah

	.leave
	ret
GetDisplayType	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BobbinAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= BobbinApplicationClass object
		ds:di	= BobbinApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	12/29/92	initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BobbinAppUnsetWin	method dynamic BobbinApplicationClass, 
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
	mov	di, offset BobbinApplicationClass
	GOTO	ObjCallSuperNoLock
BobbinAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BobbinSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next line.

CALLED BY:	BobbinAppSetWin, BobbinAppDraw
PASS:		*ds:si = BobbinApplication object
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BobbinSetTimer	proc	near
	class	BobbinApplicationClass
	uses	di
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].BobbinApplication_offset

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	bx, ds:[di].BAI_speed
	mov	cx, cs:[timerSpeeds][bx]

	tst	es:[dudeIsWalking]
	jz	startTimer

	mov	cx, cs:[walkSpeeds][bx]

startTimer:
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination
	mov	dx, MSG_BOBBIN_APP_DRAW

	call	TimerStart
	mov	ds:[di].BAI_timerHandle, bx
	mov	ds:[di].BAI_timerID, ax

	.leave
	ret
BobbinSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BobbinAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do one step of drawing the screen saver

CALLED BY:	MSG_BOBBIN_APP_DRAW

PASS:		*ds:si	= BobbinApplication object
		ds:[di] = BobbinApplicationInstance
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
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
BobbinAppDraw	method	dynamic	BobbinApplicationClass,
					MSG_BOBBIN_APP_DRAW
	.enter

	;
	; Make sure there is a GState to draw with
	;		

	tst	ds:[di].SAI_curGState
	LONG	jz	quit			; branch if no GState

	push	si				; save object

	tst	es:[dudeIsWalking]
	LONG	jnz	walkDude

drawThreads::
	;
	; Erase the old bobbin
	;

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetLineColor

	mov	ax, es:[bobbinEndX].SV_point
	mov	bx, es:[bobbinEndY]
	mov	cx, es:[bobbinStartX].SV_point
	mov	dx, es:[bobbinStartY]
	call	GrDrawLine
	pop	di				; ds:[di] = instance

	;
	; Update the moving end of the bobbin
	;

	push	ds
	push	bx
	mov	bx, ds:[di].BAI_random
	segmov	ds, es, si
	mov	si, offset bobbinEndX		; ds:si <- ptr to SaverVector
	call	SaverVectorUpdate

	pop	bx
	pop	ds
	jnc	noBounce			; branch if no bounce

	;
	; If we're moving up a line, make sure the old area is erased
	;	

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor

	clr	ax				; ax <- x1
	mov	cx, es:[winWidth]		; cx <- x2
	mov	dx, bx
	add	dx, es:[curStep]
	call	GrFillRect
	pop	di				; ds:[di] = instance

	mov	ax, es:[curStep]
	sub	es:[bobbinEndY], ax
	jc	topOfScreen			; branch if at top

noBounce:
	;
	; Update the 'static' end of the bobbin
	;

	push	ds
	mov	bx, ds:[di].BAI_random
	segmov	ds, es, si
	mov	si, offset bobbinStartX		; ds:si <- ptr to SaverVector
	call	SaverVectorUpdate
	pop	ds

	;
	; Set the color for the thread based on what's under the end of it
	;

	call	SetThreadColor			; al <- color for thread

	;
	; Draw the new bobbin
	;

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	ax, es:[bobbinEndX].SV_point
	mov	bx, es:[bobbinEndY]		; (ax,bx) <- (x,y) of bobbin
	mov	cx, es:[bobbinStartX].SV_point
	mov	dx, es:[bobbinStartY]
	call	GrDrawLine
	pop	di

	;
	; Draw the correct little dude
	;

	call	DrawLittleDude

	;
	; Draw a bit o' thread on the spool, but a bit darker...
	;

	call	DrawSpoolThread

resetTimer:
	;
	; Set another timer for next time.
	; 

	pop	si				; *ds:si = BobbinApp object
	call	BobbinSetTimer
	jmp	short	quit

pop1:
	pop	si				; restore stack pointer
quit:

	.leave
	ret

walkDude:
	call	DrawLittleDude
	tst	es:[dudeIsWalking]
	jnz	resetTimer		; still walking, so go another time

	tst	es:[dudeWalkGoal]	; walking off-stage?
	jle	pop1			; yes => we're done

	mov	es:[curDudeBitmaps], offset dudeBitmaps
	mov	es:[curDudeBitmapsLength], length dudeBitmaps
	mov	es:[curDude], length dudeBitmaps - 1 ; start with the first one
	jmp	resetTimer		; no => want to start unravelling now

topOfScreen:
	;
	; Clear whatever remains at the top of the screen.
	;

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	clr	ax
	mov	cx, es:[winWidth]
	mov	bx, ax
	mov	dx, ds:[curStep]
	call	GrFillRect
	pop	di

	;
	; Now set the little guy to walking off to the left of the screen.
	;

	mov	es:[dudeIsWalking], 1
	mov	es:[curDudeBitmaps], offset walkDudeBitmaps
	mov	es:[curDudeBitmapsLength], length walkDudeBitmaps
	mov	es:[curDude], length walkDudeBitmaps - 1
	mov	es:[dudeWalkGoal], -DUDE_WIDTH
	jmp	resetTimer
BobbinAppDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetThreadColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set color for thread based on background

CALLED BY:	BobbinAppDraw

PASS:		ds:[di]	= BobbinApplicationInstance
		es	= dgroup

RETURN:		al	= Color

DESTROYED:	ah, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 8/91	Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SetThreadColor	proc	near
	class	BobbinApplicationClass
	uses	es
	.enter

	;
	; Get the color underneath the end of the bobbin
	;

	mov	ax, es:[bobbinEndX].SV_point
	mov	bx, es:[bobbinEndY]		; (ax,bx) <- source (x,y)
	dec	bx
;;;
;;; GrGetBitmap() doesn't actually return 0 if the beasty is completely
;;; off screen...or so it seems.
;;;
	cmp	ax, es:[winWidth]
	jge	skipGet				; branch if off screen
	cmp	ax, 0
	jl	skipGet				; branch if off screen

	;
	; Get a 2x1 bitmap in the area
	;

	mov	cx, 2				; cx <- width
	mov	dx, 1				; dx <- height
	push	di
	mov	di, ds:[di].SAI_curGState
	call	GrGetBitmap
	pop	di

	tst	bx
	jz	skipGet				; branch if get failed
	call	MemLock				; lock the bitmap
	mov	es, ax				; es <- seg addr of the bitmap

	;
	; This is really gross, I know...
	;

	mov	al, es:[size Bitmap]		; al <- first byte of Bitmap
	call	MemFree				; done with bitmap
	test	al, 0xf				; non-black?
	jnz	gotColor			; branch if not black
	mov	cl, 4
	shr	al, cl				; al <- Colors value
gotColor:
	and	al, 0xf				; al <- restrict
	jz	skipGet				; branch if black
CheckHack < C_BLACK eq 0>
	mov	ss:[lastColor], al
setColor:

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	ah, CF_INDEX
	call	GrSetLineColor
	pop	di

	.leave
	ret

skipGet:
	mov	al, ss:[lastColor]		; al <- last color drawn
	jmp	setColor
SetThreadColor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawLittleDude
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the correct little dude

CALLED BY:	BobbinAppDraw

PASS:		ds:[di]	= BobbinApplicationInstance
		es	= dgroup

RETURN:		none
DESTROYED:	ax, bx, cx, dx, si

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 8/91	Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawLittleDude	proc	near
	class	BobbinApplicationClass	
	.enter

	;
	; Update the current dude, and his position if he's walking.
	;

	inc	es:[curDude]
	mov	bl, es:[curDude]
	cmp	bl, es:[curDudeBitmapsLength]
	jb	checkWalking
	clr	bl
	mov	es:[curDude], bl
checkWalking:
	tst	es:[dudeIsWalking]
	jz	dudeOK
	mov	ax, es:[dudePos].P_x
	sub	ax, DUDE_STEP
	mov	es:[dudePos].P_x, ax
	cmp	ax, es:[dudeWalkGoal]
	jg	dudeOK
	mov	ax, es:[dudeWalkGoal]		; make sure the dude actually
	mov	es:[dudePos].P_x, ax		;  ends up where he's supposed
						;  to be, not just nearby...
	mov	es:[dudeIsWalking], 0
dudeOK:
	clr	bh
	mov	si, bx				; si <- dude #
	shl	si, 1				; si <- table of words
	add	si, es:[curDudeBitmaps]		; si <- walking or cranking
	push	es:[dudePos].P_x
	push	es:[dudePos].P_y

	;
	; If we're on a B&W system, we need to erase the area behind Oomao
	; and draw him in white.
	;

	cmp	es:[displayType], (DC_COLOR_2 shl offset DT_DISP_CLASS)
	jae	isColor

	push	di
	mov	di, ds:[di].SAI_curGState
	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetAreaColor
	mov	ax, es:[dudePos].P_x
	mov	bx, es:[dudePos].P_y
	mov	cx, ax
	mov	dx, bx
	add	cx, DUDE_WALK_WIDTH
	add	dx, DUDE_HEIGHT
	call	GrFillRect
	mov	ax, C_WHITE or (CF_INDEX shl 8)
	call	GrSetAreaColor
	pop	di

isColor:
	;
	; Draw the current little dude
	;

	pop	bx				; bx <- y pos
	pop	ax				; ax <- x pos
	push	ds, di
	push	bx, ax				; save x & y pos

	mov	di, ds:[di].SAI_curGState
	mov	bx, es:[dudeHandle]		; bx <- color or B&W bitmaps
	call	MemLock
	mov	ds, ax
	mov	si, ds:[si]			; ds:si = bitmap
	add	si, (size OpDrawBitmapAtCP)

	pop	bx, ax
	clr	dx				; no callback
	call	GrDrawBitmap

	pop	ds, di				; restore ds:[di] (instance)

	mov	bx, es:[dudeHandle]
	call	MemUnlock

	.leave
	ret
DrawLittleDude	endp

ColorDudes	segment	resource

dudeBitmaps	nptr \
	offset dude1,
	offset dude2,
	offset dude3
walkDudeBitmaps	nptr \
	offset walkDude1,
	offset walkDude2,
	offset walkDude3

dude1	label	byte
include	Art/mkrDude1.ui
dude2	label	byte
include	Art/mkrDude2.ui
dude3	label	byte
include	Art/mkrDude3.ui

walkDude1	label	byte
include Art/mkrWalkDude1.ui
walkDude2	label	byte
include Art/mkrWalkDude2.ui
walkDude3	label	byte
include Art/mkrWalkDude3.ui
GSCheck check

ColorDudes	ends

BWDudes	segment	resource

dudeBWBitmaps	nptr \
	offset dudeBW1,
	offset dudeBW2,
	offset dudeBW3
walkDudeBWBitmaps	nptr \
	offset walkDudeBW1,
	offset walkDudeBW2,
	offset walkDudeBW3

dudeBW1	label	byte
include	Art/mkrBWDude1.ui
dudeBW2	label	byte
include	Art/mkrBWDude2.ui
dudeBW3	label	byte
include	Art/mkrBWDude3.ui

walkDudeBW1	label	byte
include Art/mkrBWWalkDude1.ui
walkDudeBW2	label	byte
include Art/mkrBWWalkDude2.ui
walkDudeBW3	label	byte
include Art/mkrBWWalkDude3.ui
GSCheck check

BWDudes	ends

CheckHack <(offset walkDudeBitmaps - offset dudeBitmaps) eq \
	   (offset walkDudeBWBitmaps - offset dudeBWBitmaps)>

ForceRef dudeBWBitmaps
ForceRef walkDudeBMBitmaps


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSpoolThread
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the bit of thread on the spool

CALLED BY:	BobbinAppDraw

PASS:		ds:[di]	= BobbinApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/ 8/91	Initial version
	stevey	12/29/92	port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawSpoolThread	proc	near
	class	BobbinApplicationClass
	.enter

	push	di
	mov	di, ds:[di].SAI_curGState

	mov	ax, C_BLACK or (CF_INDEX shl 8)
	call	GrSetLineColor
	mov	ax, es:[bobbinStartX].SV_point
	mov	bx, es:[bobbinStartY]
	mov	cx, ax
	add	cx, es:[bobbinStartX].SV_delta
	mov	dx, bx
	add	dx, BOBBIN_SPOOL_HEIGHT
	call	GrDrawLine

	pop	di
	.leave
	ret
DrawSpoolThread	endp

BobbinCode	ends
