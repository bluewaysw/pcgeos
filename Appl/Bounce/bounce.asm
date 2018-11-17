COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1990 -- All Rights Reserved

PROJECT:	PC/GEOS
MODULE:		Bounce (Bouncing balls demo)
FILE:		bounce.asm

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1990		Initial version
	Eric	5/91		doc update, cleanup
	Don	6/91		Updated to 2.0, added regions

DESCRIPTION:
	This file source code for the Bounce application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: bounce.asm,v 1.1 97/04/04 14:41:00 newdeal Exp $

------------------------------------------------------------------------------@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

_Application		= 1

;
;Standard include files
;
include geos.def
include heap.def
include geode.def
include resource.def
include ec.def
include sem.def
include object.def
include win.def
include graphics.def
include lmem.def
include	file.def
include	localize.def			; needed for UI resources files
include timer.def
include char.def
include thread.def
include gstring.def			; for the application icon
include	Objects/winC.def		; for MSG_META_EXPOSED

;------------------------------------------------------------------------------
;			Libraries used
;------------------------------------------------------------------------------

UseLib	ui.def

;------------------------------------------------------------------------------
;			Resource Definitions
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Macros
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
;			Constants
;------------------------------------------------------------------------------

NUM_BALLS	=	20

BALL_WIDTH	=	25
BALL_HEIGHT	=	25

BALL_MOVE_X	=	25
BALL_MOVE_Y	=	25

BACKGROUND_COLOR	=	C_WHITE

;misc stuff

BOUNCE_ERROR						enum FatalErrors
BOUNCE_ERROR_BAD_UI_ARGUMENTS				enum FatalErrors

;------------------------------------------------------------------------------
;			Records and Structures
;------------------------------------------------------------------------------

Ball	struct
    B_pos	Point <>
    B_color	Color
Ball	ends

BounceDrawType	etype word
    BDT_SQUARE	enum BounceDrawType
    BDT_CIRCLE	enum BounceDrawType



;------------------------------------------------------------------------------
;			Definitions
;------------------------------------------------------------------------------

;This class is used for this application's Process object.

BounceProcessClass	class	GenProcessClass

;This message is sent by the "On/Off" ItemGroup, which the user changes it.

MSG_BOUNCE_SET_ON_OFF_STATE		message

;This message is sent by the "Draw Type" ItemGroup, which the user changes
; it.

MSG_BOUNCE_SET_DRAW_TYPE		message

;This message is sent to this object every time the timer expires.

MSG_DO_NEXT				message

BounceProcessClass	endc

;------------------------------------------------------------------------------
;			Resources
;------------------------------------------------------------------------------

include		bounce.rdef

;------------------------------------------------------------------------------
;			Variables
;------------------------------------------------------------------------------

idata	segment

	BounceProcessClass	mask CLASSF_NEVER_SAVED

;------------------------------------------------------------------------------
;			Application State Data
;
;All of the following variables are saved to the application's state file.
;------------------------------------------------------------------------------

StartStateData	label	byte	;beginning of application state data

;On/Off state:

onOffState	byte		FALSE	;ON by default

drawType	BounceDrawType	BDT_SQUARE
xChange		word		BALL_MOVE_X
yChange		word		BALL_MOVE_Y

balls		Ball		NUM_BALLS dup (<>)

curBallValues	Ball		<>

nextBallPtr	word		offset balls

EndStateData	label	byte	;beginning of application state data

idata	ends

;---------------------------------------------------

udata	segment

viewWindow	word		;handle of the window in the GenView.
backColor	Color		;color of background of view

udata	ends

;------------------------------------------------------------------------------
;			Code
;------------------------------------------------------------------------------

CommonCode segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceUIOpenApplication -- MSG_GEN_PROCESS_OPEN_APPLICATION

DESCRIPTION:	

CALLED BY:	

PASS:		AX	= Method
		CX	= AppAttachFlags
		DX	= Handle to AppLaunchBlock
		BP	= Block handle
		DS, ES	= DGroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

BounceUIOpenApplication	method	BounceProcessClass, MSG_GEN_PROCESS_OPEN_APPLICATION

	tst	bp
	jz	10$

	;Restore the data (if any)

	push	ax, cx, es			; save the method #, segment
	mov	bx, bp				; block handle to BX
	call	MemLock
	mov	ds, ax				; set up the segment
	mov	cx, (EndStateData - StartStateData)
	clr	si
	mov	di, offset StartStateData
	rep	movsb				; copy the bytes
	call	MemUnlock
	pop	ax, cx, es			; restore the method #, segment

10$:	;Now call the superclass

	segmov	ds, es				; DGroup => DS
	mov	di, offset BounceProcessClass	; class of SuperClass we call
	call	ObjCallSuperNoLock		; method already in AX

initUIComponents:
	ForceRef initUIComponents

	;initialize our UI components according to current state

	push	ax, cx, dx, bp

	;set up the user interface state

	call	BounceInitUIComponents

	pop	ax, cx, dx, bp
	ret
BounceUIOpenApplication	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceUICloseApplication -- MSG_GEN_PROCESS_CLOSE_APPLICATION

DESCRIPTION:	

CALLED BY:	

PASS:		DS, ES	= DGroup
		AX	= MSG_GEN_PROCESS_CLOSE_APPLICATION

RETURN:		CX	= Block handle holding state data

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/27/91		Initial version

------------------------------------------------------------------------------@

BounceUICloseApplication	method	BounceProcessClass, \
						MSG_GEN_PROCESS_CLOSE_APPLICATION

	; Allocate the block

	mov	ax, (EndStateData - StartStateData)
	mov	cx, ALLOC_DYNAMIC_NO_ERR or mask HF_SHARABLE or (mask HAF_LOCK shl 8)
	call	MemAlloc
	mov	es, ax

	; Store the state

	mov	cx, (EndStateData - StartStateData)
	clr	di
	mov	si, offset StartStateData
	rep	movsb				; copy the bytes

	;Clean up

	call	MemUnlock
	mov	cx, bx
	ret
BounceUICloseApplication	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceInitUIComponents

DESCRIPTION:	This routine will initialize all of our UI components
		according to the current state of our variables.

CALLED BY:	BounceAttach

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	4/28/91		Initial version

------------------------------------------------------------------------------@

BounceInitUIComponents	proc	near

	;set the on/off state

	mov	cx, TRUE
	tst	ds:[onOffState]		;is it on?
	jnz	setOnOffState		;skip if so...
	mov	cx, FALSE

setOnOffState:

	GetResourceHandleNS	OnOffItemGroup, bx
	mov	si, offset OnOffItemGroup	;object OD => BX:SI

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	clr	di
	call	ObjMessage


	;set the draw type state

	mov	cx, ds:[drawType]

	GetResourceHandleNS	DrawTypeItemGroup, bx
	mov	si, offset DrawTypeItemGroup

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	clr	di
	call	ObjMessage

	;determine the background color of the View

	GetResourceHandleNS	BounceView, bx
	mov	si, offset BounceView
	mov	ax, MSG_GEN_VIEW_GET_COLOR
	mov	di, mask MF_CALL
	call	ObjMessage
	mov	ds:[backColor], cl	; assume indexed color - store value

	ret
BounceInitUIComponents	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceAttach -- MSG_META_ATTACH handler

DESCRIPTION:	Perform initialization.

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam 	1990		Initial version
	Eric	5/91		doc update

------------------------------------------------------------------------------@

BounceAttach	method	BounceProcessClass, MSG_META_ATTACH

	;Call our superclass (the UI) to get stuff started

	mov	di,offset BounceProcessClass
	call	ObjCallSuperNoLock

	tst	ds:[onOffState]
	jz	done

	call	GeodeGetProcessHandle
	mov	ax,MSG_DO_NEXT
	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	ret
BounceAttach	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceDetach

DESCRIPTION:	Cleans up the application prior to exiting

CALLED BY:	GLOBAL

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1990		Initial version
	Eric	5/91		improvements, doc update

------------------------------------------------------------------------------@

;BounceDetach	method	BounceProcessClass, MSG_META_DETACH
;
;	;turn off timers, etc.
;
;	; Call our superclass (the UI) to finish
;
;	mov	ax,MSG_META_DETACH
;	mov	di,offset BounceProcessClass
;	call	ObjCallSuperNoLock
;	ret
;BounceDetach	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceViewWinClosed

DESCRIPTION:	This method is sent by the window inside the GenView,
		as it is closing. This indicates that the application
		is exiting, or is being iconified.

PASS:		ds	= dgroup
		bp	- window handle

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam	1990		Initial version
	Eric	5/91		doc update

------------------------------------------------------------------------------@

BounceViewWinClosed	method	BounceProcessClass, 
				MSG_META_CONTENT_VIEW_WIN_CLOSED

	cmp	bp, ds:[viewWindow]	;is it our window?
	jnz	50$			;skip if not...

	;nuke our window and GState handles

	mov	ds:[viewWindow], 0	;indicate that we don't have a window

50$:
	mov	di,offset BounceProcessClass
	GOTO	ObjCallSuperNoLock

BounceViewWinClosed	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceSetOnOffState -- MSG_BOUNCE_SET_ON_OFF_STATE

DESCRIPTION:	This method is sent by our "On/Off" ItemGroup,
		when the user makes a change.

PASS:		ds	= dgroup
		cx	= TRUE/FALSE

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

BounceSetOnOffState	method	BounceProcessClass, \
						MSG_BOUNCE_SET_ON_OFF_STATE

	;cx = TRUE or FALSE, so just store lower byte of this value

	mov	ds:[onOffState], cl	;save the new state

	tst	cl
	jz	90$			;skip if now is off...

	mov	ds:[onOffState],1
	call	GeodeGetProcessHandle

	mov	ax,MSG_DO_NEXT
	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessage

90$:
	ret
BounceSetOnOffState	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceSetDrawType -- MSG_BOUNCE_SET_DRAW_TYPE

DESCRIPTION:	This method is sent by our "Draw Type" ItemGroup,
		when the user makes a change.

PASS:		ds	= dgroup
		cx	= BounceDrawType

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

BounceSetDrawType	method	BounceProcessClass, \
				MSG_BOUNCE_SET_DRAW_TYPE

	; cx = BounceDrawType, so just store the value
	;
	mov	ds:[drawType], cx	; store the draw type

	; force the window to get re-drawn
	;
	mov	cx, ds:[viewWindow]	; window handle => CX
	jcxz	done			; if none, do nothing

	; Tell the window that its image is invalid
	;
	mov	di, cx
	call	GrCreateState
	call	GrGetWinBounds		; bounds => AX, BX, CX, DX
	call	GrInvalRect		; invalidate the image in the Window
	call	GrDestroyState
done:
	ret
BounceSetDrawType	endm


COMMENT @----------------------------------------------------------------------

FUNCTION:	BounceExposed -- MSG_META_EXPOSED handler.

DESCRIPTION:	Draws all of the balls

CALLED BY:	GLOBAL

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		initial version
	Eric	5/91		doc update, cleanup

------------------------------------------------------------------------------@

BounceExposed	method BounceProcessClass, MSG_META_EXPOSED
	;if we have just appeared on-screen, or have been opened from 
	;the iconified state, then send method to self to continue bouncing

	tst	ds:[viewWindow]
	jnz	10$			;skip if already was visible...

	mov	ds:[viewWindow],cx	;save handle of window.

	;if we are on, then start up loop:

	tst	ds:[onOffState]
	jz	10$			;skip if not on...

	call	GeodeGetProcessHandle

	mov	ax,MSG_DO_NEXT
	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessage

10$:	;Create us a GState

	mov	di, ds:[viewWindow]		;di = window
	call	GrCreateState	 		;returns gstate in di

	;Updating the window...

	call	GrBeginUpdate

	mov	cx, NUM_BALLS			;draw them all
	mov	si, offset balls

BEW_loop:
	push	cx
	call	DrawBall
	pop	cx
	add	si,size Ball
	loop	BEW_loop

	call	GrEndUpdate			;done updating...

	call	GrDestroyState	 		;destroy our gstate
	ret
BounceExposed	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	Bounce -- MSG_ handler

DESCRIPTION:	Draw the next ball

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam 	1990		Initial version
	Eric	5/91		doc update

------------------------------------------------------------------------------@

BounceDoNext	method BounceProcessClass, MSG_DO_NEXT
	mov	di, ds:[viewWindow]		;di = window
	tst	di
	jz	done

	call	GrCreateState 		;returns gstate in di

	; Suck up a bit of CPU time, so we can play w/new thread model
	;
;	mov	cx, 100
;nextBallLoop:
;	push	cx
	call	NextBall
;	pop	cx
;	loop	nextBallLoop

	call	GrDestroyState 		;destroy our gstate

	;this is what decides our CPU load! If you comment this out,
	;Bounce will suck up 100% of the CPU.

	mov	ax,1
	call	TimerSleep
	tst	ds:[onOffState]
	jz	done

	call	GeodeGetProcessHandle
	mov	ax,MSG_DO_NEXT
	mov	di,mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	ret
BounceDoNext	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	NextBall()

DESCRIPTION:	Draws the next ball, by erasing the last one, and determining
		the next ball atributes and drawing the ball

PASS:		DI	= GState

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam 	1990		Initial version
	Don	6/91		Documentation update

------------------------------------------------------------------------------@

NextBall	proc	near

	mov	si,ds:[nextBallPtr]
	call	EraseBall			;erase current ball

	call	GetNextBallValues

	; store vars for next ball

	mov	ds:[si].B_color,cl
	mov	ds:[si].B_pos.P_x,ax
	mov	ds:[si].B_pos.P_y,bx

	; draw the ball

	call	DrawBall

	; move to next ball

	add	si,size Ball			;move to next ball
	cmp	si,offset balls + ((size Ball) * NUM_BALLS)
	jnz	noWrap
	mov	si,offset balls
noWrap:
	mov	ds:[nextBallPtr],si
	ret
NextBall	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetNextBallValues()

DESCRIPTION:	Determine all the attributes of the nest ball, including
		position and color

PASS:		DS	= Color

RETURN:		AX	= Horizontal position
		BX	= Vertical position
		CL	= Color

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam 	1990		Initial version
	Don	6/91		Documentation update

------------------------------------------------------------------------------@

GetNextBallValues	proc	near
	call	GrGetWinBounds		;cx = right, dx = bottom
	sub	cx,BALL_WIDTH		;make cx = max x position
	sub	dx,BALL_HEIGHT		;make dx = max y position

	; move to next x position

	mov	ax,ds:[curBallValues].B_pos.P_x
	add	ax,ds:[xChange]
	js	leftWall		;if <0 then hit left wall
	cmp	ax,cx
	jl	xGood
	mov	ax,cx			;past right edge, turn around
	jmp	xTurnAround
leftWall:
	clr	ax			;past left edge, turn around
xTurnAround:
	neg	ds:[xChange]
xGood:
	mov	ds:[curBallValues].B_pos.P_x,ax

	; move to next y position

	mov	bx,ds:[curBallValues].B_pos.P_y
	add	bx,ds:[yChange]
	js	topWall		;if <0 then hit top wall
	cmp	bx,dx
	jl	yGood
	mov	bx,dx			;past bottom edge, turn around
	jmp	yTurnAround
topWall:
	clr	bx			;past top edge, turn around
yTurnAround:
	neg	ds:[yChange]
yGood:
	mov	ds:[curBallValues].B_pos.P_y,bx

	; move to next color

	mov	cl,ds:[curBallValues].B_color
newColor:
	inc	cl
	and	cl,15
	cmp	cl, ds:[backColor]	;don't draw in same color as background
	je	newColor		;if so, get the next color
	mov	ds:[curBallValues].B_color,cl
	ret
GetNextBallValues	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	DrawBall()

DESCRIPTION:	Draws a ball

PASS:		DS:SI	= Ball
		DI	= GState

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam 	1990		Initial version
	Don	6/91		Documentation update

------------------------------------------------------------------------------@

drawBallFuncs	nptr \
	DrawSquareBall,
	DrawCircleBall

DrawBall	proc	near
	mov	al,ds:[si].B_color
	clr	ah
	call	GrSetAreaColor
	call	GetBallPos
	mov	bp, ds:[drawType]
	shl	bp, 1				; change offset to words
	call	cs:drawBallFuncs[bp]
	ret
DrawBall	endp

DrawSquareBall	proc	near
	mov	cx, ax
	mov	dx, bx
	add	cx, BALL_WIDTH
	add	dx, BALL_HEIGHT
	call	GrFillRect
	ret
DrawSquareBall	endp

DrawCircleBall	proc	near
	push	ds, si
	segmov	ds, cs
	mov	si, offset circleBall
	call	GrDrawRegion
	pop	ds, si
	ret
DrawCircleBall	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	EraseBall

DESCRIPTION:	Erases a ball from the screen

PASS:		DS:SI	= Ball
		DI	= GState

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam 	1990		Initial version
	Don	6/91		Documentation update

------------------------------------------------------------------------------@

EraseBall	proc	near
	mov	al,BACKGROUND_COLOR
	clr	ah
	call	GrSetAreaColor
	call	GetBallPos
	mov	bp, ds:[drawType]
	shl	bp, 1				; change offset to words
	call	cs:drawBallFuncs[bp]
	ret
EraseBall	endp



COMMENT @----------------------------------------------------------------------

FUNCTION:	GetBallPos()

DESCRIPTION:	Returns the position of the next ball

PASS:		DS:SI	= Ball

RETURN:		AX	= Horizontal position
		BX	= Vertical position

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam 	1990		Initial version
	Don	6/91		Documentation update

------------------------------------------------------------------------------@

	; pass: ds:si - ball, di - gstate
	; return: ax, bx, cx, dx - bounds to draw

GetBallPos	proc	near
	mov	ax, ds:[si].B_pos.P_x
	mov	bx, ds:[si].B_pos.P_y
	ret
GetBallPos	endp


; Our wonderful little circle, done as a region to be quick
;
circleBall	label	Region
	word	0,0,BALL_WIDTH,BALL_HEIGHT	; bounds
	word	-1, EOREGREC			; from infinity to here
	word	0,  9, 15, EOREGREC
	word	1,  7, 17, EOREGREC
	word	2,  5, 19, EOREGREC
	word	3,  4, 20, EOREGREC
	word	4,  3, 21, EOREGREC
	word	6,  2, 22, EOREGREC
	word	8,  1, 23, EOREGREC
	word	15, 0, 24, EOREGREC
	word	17, 1, 23, EOREGREC
	word	19, 2, 22, EOREGREC
	word	20, 3, 21, EOREGREC
	word	21, 4, 20, EOREGREC
	word	22, 5, 19, EOREGREC
	word	23, 7, 17, EOREGREC
	word	24, 9, 15, EOREGREC
	word	EOREGREC

CommonCode ends
