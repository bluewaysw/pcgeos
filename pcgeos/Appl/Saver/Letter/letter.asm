COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Specific Screen Saver -- Letter
FILE:		letter.asm

AUTHOR:		Gene, March 14th 1992

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	3/14/92		Initial revision

DESCRIPTION:
	This is a specific screen-saver library

	$Id: letter.asm,v 1.1 97/04/04 16:45:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include timer.def
include initfile.def

UseLib	ui.def
UseLib	saver.def
UseLib	Objects/vTextC.def
UseLib	Objects/Text/tCtrlC.def

include	letter.def

;==============================================================================
;
;			      VARIABLES
;
;==============================================================================

include	letter.rdef
ForceRef LetterApp

udata	segment

;
; Current window and gstate to use for drawing.
;
winWidth	word
winHeight	word

curLetter	LetterDrop
letterSize	word

;
; Number of letters drawn since last clear
;
numLetters	word

udata	ends

idata	segment

LetterProcessClass	mask CLASSF_NEVER_SAVED
LetterApplicationClass

idata	ends

LetterCode	segment resource

.warn -private
letterOptionTable	SAOptionTable	<
	letterCategory, length letterOptions
>
letterOptions	SAOptionDesc	<
	letterFontIDKey, size LAI_fontID, offset LAI_fontID
>, <
	letterIntervalKey, size LAI_interval, offset LAI_interval
>, <
	letterDribblingKey, size LAI_dribbling, offset LAI_dribbling
>, <
	letterRotateKey, size LAI_rotate, offset LAI_rotate
>, <
	letterClearKey, size LAI_clear, offset LAI_clear
>
.warn @private
letterCategory		char	'letter', 0
letterFontIDKey		char	'letterfont', 0
letterIntervalKey	char	'interval', 0
letterDribblingKey	char	'dribble', 0
letterRotateKey		char	'rotate', 0
letterClearKey		char	'clear', 0

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our options from the ini file.

CALLED BY:	MSG_META_LOAD_OPTIONS

PASS:		*ds:si	= LetterApplicationClass object
		ds:di	= LetterApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterLoadOptions	method dynamic LetterApplicationClass, 
					MSG_META_LOAD_OPTIONS
	uses	es, si
	.enter

	segmov	es, cs
	mov	bx, offset letterOptionTable
	call	SaverApplicationGetOptions

	.leave
	mov	di, offset LetterApplicationClass
	GOTO	ObjCallSuperNoLock
LetterLoadOptions	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterAppGetWinColor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clears the screen, or not.

CALLED BY:	MSG_SAVER_APP_GET_WIN_COLOR

PASS:		*ds:si	= LetterApplicationClass object
		ds:di	= LetterApplicationClass instance data

RETURN:		ax	= WinColorFlags
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/14/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterAppGetWinColor	method dynamic LetterApplicationClass, 
					MSG_SAVER_APP_GET_WIN_COLOR
	;
	;  Let the superclass do its thang.
	;

	mov	di, offset LetterApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].LetterApplication_offset

	tst	ds:[di].LAI_clear			; clear screen?
	jnz	done
	
	ornf	ah, mask WCF_TRANSPARENT

done:
	ret
LetterAppGetWinColor	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Record the window & gstate, and start things going.

CALLED BY:	MSG_SAVER_APP_SET_WIN

PASS:		*ds:si	= LetterApplicationClass object
		ds:di	= LetterApplicationClass instance data

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterAppSetWin	method dynamic LetterApplicationClass, 
					MSG_SAVER_APP_SET_WIN
	.enter

	;
	; Let the superclass do its little thing.
	; 

	mov	di, offset LetterApplicationClass
	call	ObjCallSuperNoLock

	mov	di, ds:[si]
	add	di, ds:[di].LetterApplication_offset

	;
	; Create a random number generator.
	;

	call	TimerGetCount
	mov	dx, bx		; dxax <- seed
	clr	bx		; bx <- allocate a new one
	call	SaverSeedRandom
	mov	ds:[di].LAI_random, bx

	call	LetterStart

	;
	; Start up the timer to draw a new line.
	;

	call	LetterSetTimer

	.leave
	ret
LetterAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stop saving the screen.

CALLED BY:	MSG_SAVER_APP_UNSET_WIN

PASS:		*ds:si	= LetterApplicationClass object
		ds:di	= LetterApplicationClass instance data

RETURN:		dx	= old window
		bp	= old gstate

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jdashe	4/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterAppUnsetWin	method dynamic LetterApplicationClass, 
					MSG_SAVER_APP_UNSET_WIN
	;
	; Stop the draw timer.
	;

	clr	bx
	xchg	bx, ds:[di].LAI_timerHandle
	mov	ax, ds:[di].LAI_timerID
	call	TimerStop

	;
	; Nuke the random number generator.
	;

	clr	bx
	xchg	bx, ds:[di].LAI_random
	call	SaverEndRandom

	;
	; Call our superclass to take care of the rest.
	;

	mov	ax, MSG_SAVER_APP_UNSET_WIN
	mov	di, offset LetterApplicationClass
	GOTO	ObjCallSuperNoLock
LetterAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start saving the screen in our own little way

CALLED BY:	Generic screen saver library

PASS: 		*ds:si	= LetterApplication object
		ds:[di]	= LetterApplicationInstance
		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	jcw	3/24/91		Initial version
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterStart	proc	near
	class	LetterApplicationClass
	uses	ax, bx, cx, dx
	.enter

	mov	dx, ds:[di].SAI_bounds.R_right
	sub	dx, ds:[di].SAI_bounds.R_left
	mov	es:[winWidth], dx
	mov	dx, ds:[di].SAI_bounds.R_bottom
	sub	dx, ds:[di].SAI_bounds.R_top
	mov	es:[winHeight], dx

	;
	; Initialize common attributes
	;

	mov	di, ds:[di].SAI_curGState
	mov	al, CMT_DITHER			; al <- ColorMapType
	call	GrSetTextColorMap		; set dithering

	;
	; Initialize the font
	;

	mov	di, ds:[si]
	add	di, ds:[di].LetterApplication_offset

	inc	dx				; dx <- window height
	shr	dx, 1				; dx <- height / 2
	shr	dx, 1				; dx <- height / 4
	shr	dx, 1				; dx <- height / 8
	mov	es:[letterSize], dx		; save pointsize
	mov	cx, ds:[di].LAI_fontID		; cx <- FontID
	mov	di, ds:[di].SAI_curGState
	clr	ah				; dx.ah <- pointsize (WBFixed)
	call	GrSetFont

	;
	; Initalize the first dribble
	;

	mov	di, ds:[si]
	add	di, ds:[di].LetterApplication_offset

	call	InitLetter
	clr	es:[numLetters]

	.leave
	ret
LetterStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a one-shot timer to draw the next step

CALLED BY:	LetterAppSetWin, LetterAppDraw

PASS:		*ds:si	= LetterApplication object

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	ardeb	6/28/91		Initial version
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterSetTimer	proc	near
	class	LetterApplicationClass
	.enter

	mov	di, ds:[si]
	add	di, ds:[di].LetterApplication_offset	

	mov	al, TIMER_EVENT_ONE_SHOT
	mov	cx, LETTER_PAUSE
	mov	dx, MSG_LETTER_APP_DRAW
	mov	bx, ds:[LMBH_handle]		; ^lbx:si = destination

	call	TimerStart

	mov	ds:[di].LAI_timerHandle, bx
	mov	ds:[di].LAI_timerID, ax

	.leave
	ret
LetterSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitLetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize one letter

CALLED BY:	LetterAppDraw, LetterAppSetWin

PASS:		ds:[di]	= LetterApplicationInstance
		es	= dgroup

RETURN:		none
DESTROYED:	ax, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	3/14/92		Initial version
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InitLetter	proc	near
	class	LetterApplicationClass
	uses	bx, cx
	.enter

	;
	; Get a random letter to use
	;

	mov	dx, C_CARON-C_SPACE		; dx <- letter range
	mov	bx, ds:[di].LAI_random
	call	SaverRandom

	add	dl, C_SPACE			; dl <- random character
	mov	es:[curLetter].LD_char, dl

	;
	; Get random (x,y) position for drop
	;

	mov	dx, es:[winWidth]
	add	dx, es:[letterSize]
	call	SaverRandom

	sub	dx, es:[letterSize]	;adjust for left edge
	mov	es:[curLetter].LD_position.P_x, dx
	mov	dx, es:[winHeight]
	add	dx, es:[letterSize]
	call	SaverRandom

	sub	dx, es:[letterSize]		; adjust for top edge
	mov	es:[curLetter].LD_position.P_y, dx

	;
	; get the length of the dribble
	;

	mov	ax, dx				; ax <- y position
	mov	dx, es:[winHeight]		; dx <- win height
	sub	dx, ax				; dx <- difference
	call	SaverRandom

	shr	dx, 1				; shorter dribble
	mov	es:[curLetter].LD_length, dx

	;
	; Get random color
	;

	mov	dx, Color+1			; dx <- range of colors
	call	SaverRandom
	mov	es:[curLetter].LD_color, dl

	;
	; Get a random rotation, if appropriate
	;
	mov	cx, ds:[di].LAI_rotate		; cx <- rotation multiple
	tst	cx				; any rotation?
	je	noRotate			; branch if no rotation

	mov	ax, 360
	clr	dx				; dx:ax <- 360
	div	cx				; ax <- 360/multiple
	mov	dx, ax
	call	SaverRandom			; dx <- random value

	mov	ax, dx
	mul	cx				; ax <- random angle
	mov	es:[curLetter].LD_angle, ax	; set angle

noRotate:
	;
	; Draw the random character
	;
	call	DrawALetter
	
	.leave
	ret
InitLetter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawALetter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw one letter

CALLED BY:	LetterAppDraw

PASS:		ds:[di]	= LetterApplicationInstance
		(ax,bx)	= center of dribble drop

		es	= dgroup

RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/ 1/91		Initial version
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DrawALetter	proc	near
	class	LetterApplicationClass
	uses	ax, bx, dx, di
	.enter

	push	di
	mov	di, ds:[di].SAI_curGState
	call	GrSetDefaultTransform		; reset rotation to zero

	;
	; Apply any rotation....
	;

	mov	dx, es:[curLetter].LD_position.P_x
	mov	bx, es:[curLetter].LD_position.P_y
	clr	cx				; dx.cx = x trans (WWFixed)
	clr	ax				; bx.ax = y trans (WWFixed)
	call	GrApplyTranslation		; translate to origin

	pop	di
	tst	ds:[di].LAI_rotate		; any rotation?
	mov	di, ds:[di].SAI_curGState
	jz	noRotate			; branch if no rotation

	mov	dx, es:[curLetter].LD_angle
	clr	cx				; dx.cx <- angle (WWFixed)
	call	GrApplyRotation

noRotate:
	mov	al, es:[curLetter].LD_color
	mov	ah, CF_INDEX
	call	GrSetTextColor

	clr	ax
	clr	bx				; (ax,bx) <- (x,y)
	clr	dh
	mov	dl, es:[curLetter].LD_char
	call	GrDrawChar

	.leave
	ret
DrawALetter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine called to draw the dribble

CALLED BY:	MSG_LETTER_APP_DRAW

PASS:		*ds:si	= LetterApplication object
		ds:[di]	= LetterApplicationInstance

RETURN:		nothing
DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	roger	3/25/91		Initial version
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterAppDraw	method	dynamic	LetterApplicationClass,
					MSG_LETTER_APP_DRAW
	.enter

	tst	ds:[di].SAI_curGState
	jz	quit

	;
	; Dribbling or not?
	;

	tst	ds:[di].LAI_dribbling
	jz	dropDone			; branch if not dribbling

	;
	; Draw the current drop
	;

	call	DrawALetter

	;
	; dribble to the side, back and forth +-1
	;

	mov	dx, 3
	mov	bx, ds:[di].LAI_random
	call	SaverRandom
	dec	dx
	add	es:[curLetter].LD_position.P_x, dx

	;
	; Update the y position and the remainging length
	;

	add	es:[curLetter].LD_position.P_y, LETTER_Y_SPEED
	sub	es:[curLetter].LD_length, LETTER_Y_SPEED
	jl	dropDone
	
done:
	;
	; Set a timer for next time
	;

	call	LetterSetTimer
quit:

	.leave
	ret

dropDone:
	;
	; We've finished a drop.  Have we drawn enough to clear
	; the screen?
	;
	inc	es:[numLetters]
	mov	ax, es:[numLetters]		; ax <- # of drops drawn
	cmp	ax, ds:[di].LAI_interval	; enough drawn this time?
	jb	drawOK

	call	LetterClear
	clr	es:[numLetters]
drawOK:
	call	InitLetter			; initialize new drop
	jmp	short	done

LetterAppDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LetterClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the screen

CALLED BY:	LetterAppDraw

PASS:		ds:[di]	= LetterApplicationInstance

RETURN:		nothing
DESTROYED:	ax, bx, cx, dx

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	11/17/91	Initial version
	stevey	1/14/93		port to 2.0

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LetterClear	proc	near
	class	LetterApplicationClass
	uses	si, di
	.enter

	mov	di, ds:[di].SAI_curGState
	call	GrSetDefaultTransform		; reset rotation to zero

	;
	; Clear the screen
	;
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
LetterClear	endp

LetterCode	ends
