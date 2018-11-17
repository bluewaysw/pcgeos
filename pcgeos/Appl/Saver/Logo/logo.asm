COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1994 -- All Rights Reserved

PROJECT:	GEOS
MODULE:		Appl/Saver/Logo
FILE:		logo.asm

AUTHOR:		Don Reeves, Aug 16, 1994

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/16/94		Initial revision

DESCRIPTION:
	Implements the "Logo" screen saver

	$Id: logo.asm,v 1.1 97/04/04 16:49:35 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	stdapp.def

include	timer.def
include	initfile.def

UseLib	ui.def
UseLib	saver.def

;------------------------------------------------------------------------------
;	Constants
;------------------------------------------------------------------------------

LOGO_TIMER_SPEED	= 90			; 1.5 seconds between re-draw


;------------------------------------------------------------------------------
;	Class declarations
;------------------------------------------------------------------------------

LogoApplicationClass	class	SaverApplicationClass

MSG_LOGO_APP_DRAW						message
;
; Draw the next logo (message sent out by our timer)
;
;	Pass:	Nothing
;	Return:	Nothing
;		AX, CX, DX, BP - destroyed
;

	LAI_timerHandle	hptr		0
		noreloc	LAI_timerHandle
	LAI_timerID	word		0

	LAI_random	hptr		0
		noreloc	LAI_random

LogoApplicationClass	endc

LogoProcessClass	class	GenProcessClass
LogoProcessClass	endc

;------------------------------------------------------------------------------
;	Variables
;------------------------------------------------------------------------------

udata	segment
	logoPosition		Point <>	; origin of current logo
	screenWidth		word		; usable screen width
	screenHeight		word		; usable screen height
udata	ends

idata	segment
	LogoProcessClass	mask CLASSF_NEVER_SAVED
	LogoApplicationClass
idata	ends

;------------------------------------------------------------------------------
;	Logo data
;------------------------------------------------------------------------------

LOGO_WIDTH		= 100
LOGO_HEIGHT		=  60

NUM_DIAMOND_POINTS	= 4
DIAMOND_DELTA		= LOGO_HEIGHT / 2

ELLIPSE_DIAMETER	= 34
ELLIPSE_X_INSET		= 6
ELLIPSE_LEFT		= (LOGO_WIDTH - ELLIPSE_DIAMETER) / 2 + ELLIPSE_X_INSET
ELLIPSE_TOP		= (LOGO_HEIGHT - ELLIPSE_DIAMETER) / 2
ELLIPSE_RIGHT		= (LOGO_WIDTH - ELLIPSE_LEFT) + 2 * ELLIPSE_X_INSET
ELLIPSE_BOTTOM		= (LOGO_HEIGHT - ELLIPSE_TOP)

ARC_X_INSET		= 10
ARC_LEFT		= ARC_X_INSET
ARC_TOP			= 18
ARC_RIGHT		= LOGO_WIDTH - ARC_X_INSET
ARC_BOTTOM		= LOGO_HEIGHT - ARC_TOP
ARC_START		= 150
ARC_MIDDLE		= 330
ARC_END			=  50

BALL_DIAMETER		= 10
BALL_BOTTOM		= (LOGO_HEIGHT / 2) + (BALL_DIAMETER / 2)
BALL_RIGHT		= LOGO_WIDTH - 7
BALL_TOP		= BALL_BOTTOM - BALL_DIAMETER
BALL_LEFT		= BALL_RIGHT - BALL_DIAMETER

INVAL_BORDER		= 2
INVAL_LEFT		= ARC_X_INSET - INVAL_BORDER
INVAL_TOP		= -INVAL_BORDER
INVAL_RIGHT		= LOGO_WIDTH + INVAL_BORDER
INVAL_BOTTOM		= LOGO_HEIGHT + INVAL_BORDER

LogoCode	segment	resource

diamondPoints		Point \
			<(LOGO_WIDTH - DIAMOND_DELTA), 0>,
			<(LOGO_WIDTH - 2 * DIAMOND_DELTA), DIAMOND_DELTA>,
			<(LOGO_WIDTH - DIAMOND_DELTA), 2 * DIAMOND_DELTA>,
			< LOGO_WIDTH, DIAMOND_DELTA>
			
purpleArcParams		ArcParams <
			ACT_OPEN,
			ARC_LEFT,
			ARC_TOP,
			ARC_RIGHT,
			ARC_BOTTOM,
			ARC_START,
			ARC_MIDDLE>

whiteArcParams		ArcParams <
			ACT_OPEN,
			ARC_LEFT,
			ARC_TOP,
			ARC_RIGHT,
			ARC_BOTTOM,
			ARC_MIDDLE,
			ARC_END>
			
LogoCode	ends

;------------------------------------------------------------------------------
;	Code
;------------------------------------------------------------------------------

include	logo.rdef
ForceRef LogoApp

LogoCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogoAppSetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recrod the window & GState to use and start drawing

CALLED BY:	GLOBAL (MSG_SAVER_APP_SET_WIN)

PASS:		*DS:SI	= LogoApplicationClass object
		DS:DI	= LogoApplicationInstance
		DX	= Window
		BP	= GState

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LogoAppSetWin	method dynamic	LogoApplicationClass, MSG_SAVER_APP_SET_WIN
		.enter
	;
	; Call the superclass first
	;
		mov	di, offset LogoApplicationClass
		call	ObjCallSuperNoLock
		mov	di, ds:[si]
		add	di, ds:[di].LogoApplication_offset
	;
	; Initialize the random number generator
	;
		call	TimerGetCount
		mov	dx, bx			; seed => DX:AX
		clr	bx			; create new random token
		call	SaverSeedRandom
		mov	ds:[di].LAI_random, bx	; store random token
	;
	; Initialize the usable width & height
	;
		mov	ax, ds:[di].SAI_bounds.R_right
		sub	ax, ds:[di].SAI_bounds.R_left
		sub	ax, LOGO_WIDTH
		mov	es:[screenWidth], ax
		mov	ax, ds:[di].SAI_bounds.R_bottom
		sub	ax, ds:[di].SAI_bounds.R_top
		sub	ax, LOGO_HEIGHT
		mov	es:[screenHeight], ax
	;
	; Initialize the color mapping
	;
		mov	di, ds:[di].SAI_curGState
		mov	al, CMT_CLOSEST shl offset CMM_MAP_TYPE
		call	GrSetAreaColorMap
		call	GrSetLineColorMap
	;
	; Start our drawing
	;
		call	LogoSetTimer

		.leave
		ret
LogoAppSetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogoAppUnsetWin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The window is going away, so stop saving the screen

CALLED BY:	GLOBAL (MSG_SAVER_APP_UNSET_WIN)

PASS:		*DS:SI	= LogoApplicationClass object
		DS:DI	= LogoApplicationInstance

RETURN:		DX	= Old Window
		BP	= Old GState

DESTROYED:	AX, CX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LogoAppUnsetWin	method dynamic	LogoApplicationClass, MSG_SAVER_APP_UNSET_WIN

	;
	; Stop our timer so we won't draw again
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
		mov	di, offset LogoApplicationClass
		GOTO	ObjCallSuperNoLock
LogoAppUnsetWin	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogoSetTimer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set a on-shot timer to draw the next logo

CALLED BY:	LogoAppSetWin, LogoAppDraw

PASS:		*DS:SI	= LogoApplicationclass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LogoSetTimer	proc	near
		class	LogoApplicationClass
		uses	di
		.enter
	;
	; Create a one-shot timer, and store its handle & ID away
	;
		mov	di, ds:[si]
		add	di, ds:[di].LogoApplication_offset
		mov	al, TIMER_EVENT_ONE_SHOT
		mov	cx, LOGO_TIMER_SPEED
		mov	dx, MSG_LOGO_APP_DRAW
		mov	bx, ds:[LMBH_handle]	; destination => ^lBX:SI
		call	TimerStart
		mov	ds:[di].LAI_timerHandle, bx
		mov	ds:[di].LAI_timerID, ax

		.leave
		ret
LogoSetTimer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogoAppDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the next logo (after clearing the current one)

CALLED BY:	GLOBAL (MSG_LOGO_APP_DRAW)

PASS:		*DS:SI	= LogoApplicationClass object
		DS:DI	= LogoApplicationClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LogoAppDraw	method dynamic	LogoApplicationClass, MSG_LOGO_APP_DRAW
		.enter
	;
	; See if we should abort (if the GState is NULL)
	;
		mov	bp, di
		mov	di, ds:[bp].SAI_curGState
		tst	di
		jz	exit
	;
	; Clear the old logo
	;
		mov	ax, C_BLACK or (CF_INDEX shl 8)
		call	GrSetAreaColor
		mov	ax, es:[logoPosition].P_x
		mov	bx, es:[logoPosition].P_y
		mov	cx, ax
		mov	dx, bx
		add	ax, INVAL_LEFT
		add	bx, INVAL_TOP
		add	cx, INVAL_RIGHT
		add	dx, INVAL_BOTTOM
		call	GrFillRect
	;
	; Draw the logo in a new position
	;
		call	LogoCalcNewPosition	; origin => (AX, BX)
		call	LogoDrawLogo
		call	LogoSetTimer
exit:
		.leave
		ret
LogoAppDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogoCalcNewPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the new position for the logo

CALLED BY:	LogoAppDraw

PASS:		DS:BP	= LogoApplicationInstance
		ES	= DGroup

RETURN:		(AX,BX)	= Origin for next logo

DESTROYED:	DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LogoCalcNewPosition	proc	near
		class	LogoApplicationClass
		.enter
	;
	; Call the random number generator a few times
	;
		mov	bx, ds:[bp].LAI_random
		mov	dx, es:[screenHeight]
		call	SaverRandom
		mov	es:[logoPosition].P_y, dx
		push	dx
		mov	dx, es:[screenWidth]
		call	SaverRandom
		mov_tr	ax, dx
		mov	es:[logoPosition].P_x, ax
		pop	bx

		.leave
		ret
LogoCalcNewPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LogoDrawLogo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the logo at a specific location

CALLED BY:	LogoAppDraw

PASS:		(AX,BX)	= Origin of logo
		DI	= GState

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	8/16/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LogoDrawLogo	proc	near
		uses	ds, si
		.enter
	;
	; Translate the GState to the correct location
	;
		mov_tr	dx, ax
		pushdw	dxbx
		clr	ax, cx
		call	GrApplyTranslation
	;
	; Draw a white background
	;
		mov	ax, C_WHITE or (CF_INDEX shl 8)
		call	GrSetAreaColor
		mov	ax, INVAL_LEFT
		mov	bx, INVAL_TOP
		mov	cx, INVAL_RIGHT
		mov	dx, INVAL_BOTTOM
		call	GrFillRect
	;
	; Draw the diamond
	;
		mov	ax, C_VIOLET or (CF_INDEX shl 8)
		call	GrSetAreaColor
		mov	al, RFR_ODD_EVEN
		mov	cx, NUM_DIAMOND_POINTS
		segmov	ds, cs
		mov	si, offset diamondPoints
		call	GrFillPolygon
	;
	; Now draw a white ellipse
	;
		mov	ax, C_WHITE or (CF_INDEX shl 8)
		call	GrSetAreaColor
		mov	ax, ELLIPSE_LEFT
		mov	bx, ELLIPSE_TOP
		mov	cx, ELLIPSE_RIGHT
		mov	dx, ELLIPSE_BOTTOM
		call	GrFillEllipse
	;
	; Draw a purple arc
	;
		mov	ax, C_VIOLET or (CF_INDEX shl 8)
		call	GrSetLineColor
		mov	si, offset purpleArcParams
		call	GrDrawArc
	;
	; Draw a white arc
	;
		mov	ax, C_WHITE or (CF_INDEX shl 8)
		call	GrSetLineColor
		mov	si, offset whiteArcParams
		call	GrDrawArc
	;
	; Finally, draw the yellow ball
	;
		mov	al, ColorMapMode <1, CMT_CLOSEST>
		call	GrSetAreaColorMap	; set draw on black
		call	GrSetLineColorMap
		mov	ax, C_YELLOW or (CF_INDEX shl 8)
		call	GrSetAreaColor
		call	GrSetLineColor
		mov	ax, BALL_LEFT
		mov	bx, BALL_TOP
		mov	cx, BALL_RIGHT
		mov	dx, BALL_BOTTOM
		call	GrFillEllipse
		call	GrDrawEllipse
		mov	al, ColorMapMode <0, CMT_CLOSEST>
		call	GrSetAreaColorMap	; return to previous state
		call	GrSetLineColorMap
	;
	; Clean up
	;
		popdw	dxbx
		neg	dx
		neg	bx
		clr	ax, cx
		call	GrApplyTranslation
	
		.leave
		ret
LogoDrawLogo	endp

LogoCode	ends
