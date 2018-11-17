COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) New Deal 1999 -- All Rights Reserved

PROJECT:	GeoSafari
FILE:		safari.asm

AUTHOR:		Gene Anderson

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Gene	9/25/98		Initial revision

DESCRIPTION:
	Code for IndicatorClass, SpacerClass, PlayerIndicatorClass

	$Id$

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include safariGeode.def
include safariConstant.def

idata	segment
	IndicatorClass
	PlayerIndicatorClass
	SpacerClass
	IndicatorGroupClass
idata	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorGroupInitFlashing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the indicators flashing

CALLED BY:	MSG_INDICATOR_GROUP_INIT_FLASHING

PASS:		none
RETURN:		none
DESTROYED:	cx, dx, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/9/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorGroupInitFlashing method dynamic IndicatorGroupClass,
					MSG_INDICATOR_GROUP_INIT_FLASHING

	;
	; go through all our children and initialize them to flashing
	;
		mov	dx, ds:[di].IGI_startNum
		mov	cx, 5
childLoop:
		push	cx, dx
	;
	; flash the Nth child
	;
		call	setFlashing			;flash N
		add	dx, 5
		call	setFlashing			;flash N+5
		add	dx, 5
		call	setFlashing			;flash N+10
	;
	; sleep for the specified time to give an interesting effect
	;
		mov	ax, INDICATOR_FLASH_OFFSET
		call	TimerSleep
		pop	cx, dx
		inc	dx				;dx <- N=N+1
		loop	childLoop

	;
	; if there is another group, make them flash, too
	;
nextGroup::
		mov	di, ds:[si]
		add	di, ds:[di].IndicatorGroup_offset
		mov	bx, ds:[di].IGI_nextGroup.handle
		mov	si, ds:[di].IGI_nextGroup.offset
		tst	bx				;next group?
		jz	done				;branch if none
		mov	ax, MSG_INDICATOR_GROUP_INIT_FLASHING
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		ret

setFlashing:
		push	cx, dx, si
	;
	; get the Nth child
	;
		mov	cx, dx				;cx <- N
		mov	ax, MSG_INDICATOR_GROUP_GET_NTH
		call	ObjCallInstanceNoLock
	;
	; set it flashing
	;
		mov	bx, cx
		mov	si, dx				;^lbx:si <- OD
		tst	bx				;any child?
		jz	skipChild			;branch if not
		mov	cx, mask IS_FLASHING
		mov	ax, MSG_INDICATOR_SET_STATE
		mov	di, mask MF_FIXUP_DS or mask MF_CALL
		call	ObjMessage
skipChild:
		pop	cx, dx, si
		retn
IndicatorGroupInitFlashing endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorGroupSetAll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set all the indicators to the given state

CALLED BY:	MSG_INDICATOR_GROUP_SET_ALL

PASS:		cx - IndicatorState
RETURN:		none
DESTROYED:	dx, bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/7/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorGroupSetAll method dynamic IndicatorGroupClass,
					MSG_INDICATOR_GROUP_SET_ALL
	;
	; record a message
	;
		push	si
		mov	bx, segment IndicatorClass
		mov	si, offset IndicatorClass
		mov	di, mask MF_RECORD
		mov	ax, MSG_INDICATOR_SET_STATE
		call	ObjMessage
		pop	si
	;
	; send it to all our children
	;
		push	cx
		mov	cx, di				;cx <- recorded message
		mov	ax, MSG_GEN_SEND_TO_CHILDREN
		call	ObjCallInstanceNoLock
		pop	cx
	;
	; if there is another group, send to it, too
	;
		mov	di, ds:[si]
		add	di, ds:[di].IndicatorGroup_offset
		mov	bx, ds:[di].IGI_nextGroup.handle
		mov	si, ds:[di].IGI_nextGroup.offset
		tst	bx
		jz	done
		mov	di, mask MF_FIXUP_DS
		mov	ax, MSG_INDICATOR_GROUP_SET_ALL
		call	ObjMessage
done:
		ret
IndicatorGroupSetAll	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorGroupGetNth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the Nth indicator

CALLED BY:	MSG_INDICATOR_GROUP_GET_NTH

PASS:		cx - indicator #
RETURN:		cx:dx - optr of indicator (NULL if not found)
DESTROYED:	bp

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/7/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorGroupGetNth method dynamic IndicatorGroupClass,
					MSG_INDICATOR_GROUP_GET_NTH
	;
	; see if in our range
	;
		mov	dx, ds:[di].IGI_startNum
		add	dx, SAFARI_MAX_QUESTIONS/2	;+13
		cmp	cx, dx
		jae	nextGroup
	;
	; in our range - find it
	;
		sub	cx, ds:[di].IGI_startNum	;cx <- adjusted num
		mov	ax, MSG_GEN_FIND_CHILD_AT_POSITION
		GOTO	ObjCallInstanceNoLock

	;
	; try the next group, if any
	;
nextGroup:
		mov	bx, ds:[di].IGI_nextGroup.handle
		mov	si, ds:[di].IGI_nextGroup.offset
		tst	bx				;next group?
EC <		WARNING_Z	NTH_INDICATOR_NOT_FOUND		;>
		jz	notFound			;branch if none
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		GOTO	ObjMessage

notFound:
		clr	cx, dx
		ret
IndicatorGroupGetNth	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw an indicator

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - GState
RETURN:		none
DESTROYED:	di, ax, bx, cx, dx

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/7/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorColors	struct
	IC_main		Color
	IC_light	Color
	IC_dark		Color
IndicatorColors	ends

onColors IndicatorColors	<C_LIGHT_RED, C_WHITE, C_RED>
offColors IndicatorColors	<C_BLACK, C_DARK_GREY, C_DARK_GREY>

IndicatorDraw	method dynamic	IndicatorClass,
					MSG_VIS_DRAW

gstate		local	hptr.GState	push	bp
bounds		local	Rectangle

		mov	dl, ds:[di].II_state		;dl <- IndicatorState

		.enter

		mov	di, ss:gstate
		call	GrSaveState

		push	dx
		call	VisGetBounds
		add	ax, INDICATOR_LED_LEFT_MARGIN
		mov	cx, ax
		add	cx, INDICATOR_LED_WIDTH
		add	bx, INDICATOR_LED_TOP_MARGIN
		mov	dx, bx
		add	dx, INDICATOR_LED_HEIGHT
		mov	ss:bounds.R_left, ax
		mov	ss:bounds.R_top, bx
		mov	ss:bounds.R_right, cx
		mov	ss:bounds.R_bottom, dx
		pop	dx
	;
	; draw a rectangle, dark grey for off and light red for on
	;
		mov	si, offset onColors
		test	dx, mask IS_ON			;on or off?
		jnz	gotColor			;branch if on
		test	dx, mask IS_DISABLED		;disabled?
		jnz	noDraw				;branch if disabled
		mov	si, offset offColors		;else off
gotColor:

		mov	al, cs:[si].IC_main		;al <- color
		mov	ah, CF_INDEX
		call	GrSetAreaColor

		call	getBounds
		call	GrFillRect
	;
	; Draw some highlights
	;
		mov	al, cs:[si].IC_light
		mov	ah, CF_INDEX
		call	GrSetLineColor
		call	getBounds
if INDICATOR_WIDTH eq INDICATOR_LED_WIDTH
		dec	cx
endif
		call	GrDrawHLine
		call	GrDrawVLine
		inc	bx
		call	GrDrawHLine
		inc	ax
		call	GrDrawVLine
	;
	; Draw some lowlights
	;
		mov	al, cs:[si].IC_dark
		mov	ah, CF_INDEX
		call	GrSetLineColor
		mov	ax, cx
		call	GrDrawVLine
		dec	ax
		call	GrDrawVLine
		call	getBounds
if INDICATOR_WIDTH eq INDICATOR_LED_WIDTH
		dec	cx
endif
		mov	bx, dx
		call	GrDrawHLine
		inc	ax
		dec	bx
		call	GrDrawHLine

noDraw:
		call	GrRestoreState

		.leave
		ret

getBounds:
		mov	ax, ss:bounds.R_left
		mov	bx, ss:bounds.R_top
		mov	cx, ss:bounds.R_right
		mov	dx, ss:bounds.R_bottom
		retn
IndicatorDraw	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize an indicator light

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorRecalcSize	method dynamic	IndicatorClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, INDICATOR_WIDTH
		mov	dx, INDICATOR_HEIGHT
		ret
IndicatorRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the state of an indicator

CALLED BY:	MSG_INDICATOR_SET_STATE

PASS:		cl - IndicatorState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	9/25/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorSetState	method dynamic	IndicatorClass,
					MSG_INDICATOR_SET_STATE
	;
	; Set the state and save the old
	;
		xchg	ds:[di].II_state, cl
		cmp	ds:[di].II_state, cl
		je	done				;branch if no change
	;
	; See if there is a new timer we need to start
	;
		test	ds:[di].II_state, mask IS_FLASHING
		jz	noNewTimer			;no timer needed
		tst	ds:[di].II_timer
		jnz	noNewTimer			;timer already running
startTimer::
		push	cx
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:OLMBH_header.LMBH_handle	;bx:si <- OD (us)
		mov	dx, MSG_INDICATOR_FLASH		;dx <- message
		mov	cx, INDICATOR_FLASH_TIME	;cx <- first time
		mov	di, INDICATOR_FLASH_TIME	;di <- interval
		call	TimerStart
		pop	cx
		mov	di, ds:[si]
		add	di, ds:[di].Indicator_offset
		mov	ds:[di].II_timer, bx
noNewTimer:
	;
	; See if we should get rid of a timer
	;
		mov	di, ds:[si]
		add	di, ds:[di].Indicator_offset
		test	ds:[di].II_state, mask IS_FLASHING
		jnz	keepTimer
	;
	; See if there is an old timer we need to stop
	;
		test	cx, mask IS_FLASHING		;any old timer?
		jz	noOldTimer			;branch if not
		clr	ax, bx				;ax <- timer ID = 0
		xchg	bx, ds:[di].II_timer		;bx <- timer handle
		tst	bx				;any old timer?
		jz	noOldTimer			;branch if not
EC <		test	cx, mask IS_FLASHING		;>
EC <		ERROR_Z		NON_FLASHING_INDICATOR_HAD_TIMER ;>
		call	TimerStop
noOldTimer:
	;
	; Redraw ourselves. If we're disabled, redraw via an invalidation
	; It's too slow for flashing on and off, but required for
	; not drawing anything (i.e., reverting to the background)
	;
keepTimer:
		mov	ax, MSG_VIS_INVALIDATE
		test	ds:[di].II_state, mask IS_DISABLED
		jnz	gotMsg
		mov	ax, MSG_VIS_REDRAW_ENTIRE_OBJECT
gotMsg:
		call	ObjCallInstanceNoLock
done:
		ret
IndicatorSetState	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorFlash
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	flash on or off

CALLED BY:	MSG_INDICATOR_FLASH via timer

PASS:		none
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/6/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorFlash	method dynamic	IndicatorClass,
					MSG_INDICATOR_FLASH
		tst	ds:[di].II_timer
		jz	done				;branch if no timer
		mov	cl, ds:[di].II_state
		xor	cl, mask IS_ON
		mov	ax, MSG_INDICATOR_SET_STATE
		call	ObjCallInstanceNoLock
done:
		ret
IndicatorFlash	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SpacerRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a spacer

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

SpacerRecalcSize	method dynamic	SpacerClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, SPACER_WIDTH
		mov	dx, SPACER_HEIGHT
		ret
SpacerRecalcSize	endm

if 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FlashRemainingIndicators
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Flash the indicators remaining in this game
		prior to choosing a question to ask

CALLED BY:	GameCardNewQuestion()

PASS:		bx - quiz array
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/21/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

FlashRemainingIndicators	proc	near
		uses	ax, cx, di
		.enter

	;
	; turn up to 8 indicators on
	;
CheckHack <segment FlashRemainingIndicatorsCB eq segment CommonCode>
		mov	di, offset FlashRemainingIndicatorsCB
		mov	cx, 8				;cx <- max # to flash
		call	QuizEnumQuestions

		.leave
		ret
FlashRemainingIndicators	endp

FlashRemainingIndicatorsCB	proc	far
		uses	ax, bx, dx, bp, si, di
		.enter
	;
	; Get the indicator # and convert to an OD
	;
		mov	si, ds:[di].QQ_indicator	;si <- indicator #
		call	IndicatorGetNth
	;
	; Turn the indicator on
	;
		push	cx
		mov	di, mask MF_CALL
		mov	ax, MSG_INDICATOR_SET_STATE
		mov	cl, mask IS_ON			;cl <- IndicatorState
		call	ObjMessage
	;
	; Make some noise!
	;
		call	PlayRandomNote
	;
	; Sleep for a little bit then turn it back off
	;
		mov	ax, QUESTION_FLASH_TIME
		call	TimerSleep
		mov	di, mask MF_CALL
		mov	ax, MSG_INDICATOR_SET_STATE
		clr	cl				;cl <- IndicatorState
		call	ObjMessage
		pop	cx
	;
	; See if we've flashed enough indicators
	;

		stc					;carry <- abort
		dec	cx				;cx <- # left to flash
		jcxz	done				;branch if none
		clc					;carry <- don't abort
done:
		.leave
		ret
FlashRemainingIndicatorsCB	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IndicatorGetNth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the OD of the Nth indicator

CALLED BY:	FlashRemainingIndicatorsCB()
		GameCardNewQuestion()

PASS:		si - N (0-25)
RETURN:		^lbx:si - OD of Nth indicator
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	10/22/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

IndicatorGetNth	proc	near
EC <		cmp	si, 26				;>
EC <		ERROR_AE	ILLEGAL_INDICATOR_NUMBER ;>
		shl	si, 1				;si <- # * 2
		add	si, offset Indicator1		;si <- indicator chunk
		mov	bx, handle Indicator1		;^lbx:si <- indicator
EC <		call	ECCheckLMemOD			;>
		ret
IndicatorGetNth	endp

endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlayerIndicatorDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a player indicator light

CALLED BY:	MSG_VIS_DRAW

PASS:		bp - GState
RETURN:		carry - set if the state has changed
DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PlayerIndicatorDraw	method dynamic	PlayerIndicatorClass,
					MSG_VIS_DRAW
		uses	si, es
gstate		local	hptr.GState	push	bp
bounds		local	Rectangle
textLabel	local	lptr
state		local	IndicatorState

		.enter

		mov	dl, ds:[di].II_state		;dl <- IndicatorState
		mov	ss:state, dl
		mov	ax, ds:[di].PII_label
		mov	ss:textLabel, ax

		mov	di, ss:gstate
		call	GrSaveState

		call	VisGetBounds
		mov	ss:bounds.R_left, ax
		mov	ss:bounds.R_top, bx
		mov	ss:bounds.R_right, cx
		mov	ss:bounds.R_bottom, dx
		mov	si, PCT_INTERSECTION
		call	GrSetClipRect

	;
	; Figure out which bitmap to use
	;
		mov	dl, ss:state
		mov	si, offset ClickOnMoniker
		test	dl, mask IS_PRESSED
		jz	notPressed
		test	dl, mask IS_ON
		jnz	gotBitmap
		mov	si, offset ClickOffMoniker
		jmp	gotBitmap

notPressed:
		mov	si, offset IndOnMoniker
		test	dl, mask IS_ON
		jnz	gotBitmap
		mov	si, offset IndOffMoniker
gotBitmap:
		call	DrawIndBitmap
	;
	; get ready to draw the label
	;
		mov	cx, FID_DTC_URW_SANS		;cx <- FontID
		mov	dx, 22
		clr	ah				;dx.ah <- pointsize
		call	GrSetFont
		mov	ax, C_WHITE
		call	GrSetTextColor

		mov	si, ss:textLabel
		mov	si, ds:[si]			;ds:si <- ptr to text

		clr	cx				;cx <- NULL-terminated
		call	GrTextWidth			;dx <- text width
		mov	ax, ss:bounds.R_right
		sub	ax, ss:bounds.R_left		;ax <- obj width
		sub	ax, dx				;ax <- diff
		sar	ax, 1				;ax <- diff/2
		add	ax, ss:bounds.R_left		;ax <- x pos
		dec	ax

		push	si
		mov	si, GFMI_HEIGHT or GFMI_ROUNDED
		call	GrFontMetrics			;dx <- text height
		pop	si
		mov	bx, ss:bounds.R_bottom
		sub	bx, ss:bounds.R_top		;bx <- obj height
		sub	bx, dx				;bx <- diff
		sar	bx, 1				;bx <- diff/2
		add	bx, ss:bounds.R_top		;bx <- y pos
		dec	bx
	;
	; offset by a little if we're pressed
	;
		test	ss:state, mask IS_PRESSED	;pressed?
		jz	notPressed2			;branch if not
		inc	ax				;offset when pressed
		inc	bx
notPressed2:
	;
	; draw the number
	;
		call	GrDrawText

		call	GrRestoreState

		.leave
		ret
PlayerIndicatorDraw	endm

DrawIndBitmap	proc	near
		uses	ds, dx
		.enter	inherit PlayerIndicatorDraw
	;
	; Lock the bitmap and draw it
	;
		mov	bx, handle Bitmaps
		call	MemLock
		mov	ds, ax
		mov	si, ds:[si]			;ds:si <- bitmap
		clr	dx				;dx <- no callback
		mov	ax, ss:bounds.R_left
		mov	bx, ss:bounds.R_top
		call	GrDrawBitmap
	;
	; Unlock the bitmap
	;
		mov	bx, handle Bitmaps
		call	MemUnlock

		.leave
		ret
DrawIndBitmap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlayerIndicatorRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resize a player indicator light

CALLED BY:	MSG_VIS_RECALC_SIZE

PASS:		none
RETURN:		cx - width
		dx - height
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PlayerIndicatorRecalcSize	method dynamic	PlayerIndicatorClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, PLAYER_INDICATOR_WIDTH
		mov	dx, PLAYER_INDICATOR_HEIGHT
		ret
PlayerIndicatorRecalcSize	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PlayerIndicatorStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a mouse click on a player indicator

CALLED BY:	MSG_META_START_SELECT

PASS:		(cx,dx) - (x,y)
		bp.low = ButtonInfo
		bp.high = ShiftState
RETURN:		ax - MouseReturnFlags
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	8/3/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PlayerIndicatorStartSelect	method dynamic	PlayerIndicatorClass,
					MSG_META_START_SELECT
	;
	; quit if not the button click we want
	;
		test	bp, mask BI_B0_DOWN
		jz	quit				;branch if not click
	;
	; quit if not currently flashing
	;
		test	ds:[di].II_state, mask IS_FLASHING
		jz	quit
	;
	; mark the indicator as pressed
	;
		call	VisGrabMouse

		mov	cl, ds:[di].II_state
		ornf	cl, mask IS_PRESSED
		mov	ax, MSG_INDICATOR_SET_STATE
		call	ObjCallInstanceNoLock
quit:
		mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
		ret
PlayerIndicatorStartSelect	endm

PlayerIndicatorEndSelect	method dynamic	PlayerIndicatorClass,
					MSG_META_END_SELECT

		mov	cl, ds:[di].II_state
		test	cl, mask IS_PRESSED
		jz	quit
	;
	; quit if not currently flashing
	;
		test	cl, mask IS_FLASHING
		jz	quit
	;
	; mark the indicator as not pressed
	;
		mov	cl, mask IS_ON			;cl <- IndicatorState
		mov	ax, MSG_INDICATOR_SET_STATE
		call	ObjCallInstanceNoLock
	;
	; ask a new question
	;
		mov	di, ds:[si]
		add	di, ds:[di].PlayerIndicator_offset
		push	si
		mov	ax, ds:[di].PII_message
		mov	bx, ds:[di].PII_destination.handle
		mov	si, ds:[di].PII_destination.offset
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		pop	si

		call	VisReleaseMouse
quit:
		mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
		ret
PlayerIndicatorEndSelect	endm


CommonCode	ends
