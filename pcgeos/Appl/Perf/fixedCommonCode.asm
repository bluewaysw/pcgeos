COMMENT @----------------------------------------------------------------------

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	Perf	(Performance Meter)
FILE:		fixedCommonCode.asm (FIXED CommonCode resource)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

DESCRIPTION:
	This file source code for the Perf application. This code will
	be assembled by ESP, and then linked by the GLUE linker to produce
	a runnable .geo application file.

RCS STAMP:
	$Id: fixedCommonCode.asm,v 1.1 97/04/04 16:27:00 newdeal Exp $

------------------------------------------------------------------------------@

PerfFixedCommonCode segment resource


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetTimerInterval

DESCRIPTION:	Set the new timer interval (nuking the old one if necessary),
		so that the system will notify us when we need to update
		our statistics and draw the graphs.

CALLED BY:	PerfAttach, PerfSetUpdateRate

PASS:		ds	= dgroup

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Adam/Tony 1990		Initial version
	Eric	4/27/91		improvements, doc update

------------------------------------------------------------------------------@

PerfSetTimerInterval	proc	far		;in PerfFixedCommonCode resource
	;if a timer has already been established, then cancel it

	mov	bx, ds:[timerHandle]		;is there already a timer?
	tst	bx
	jz	50$				;skip if not...

	;stop the old timer so we can set up a new time interval

	mov	ax, ds:[timerID]
	call	TimerStop

	clr	ax
	mov	ds:[timerHandle], ax		;indicate that we nuked timer
	mov	ds:[timerID], ax

50$:	;IF the meter is ON, then set the new timer interval

	tst	ds:[onOffState]			;are we off?
	jz	90$				;skip if so...

	call	GeodeGetProcessHandle		;set ^lbx:si = OD of process

	mov	ax, 60				;60 ticks per second
	div	ds:[updateRate]			;al = # of 1/60 second ticks
						;to count between timer fires

	mov	cl, al				;cx = ticks
	clr	ch
	mov	ax, TIMER_EVENT_CONTINUAL	;ax = type
	clr	si
	mov	dx, MSG_PERF_TIMER_EXPIRED
	mov	di, cx				;interval (one second)
	call	TimerStart

	mov	ds:[timerHandle],bx		;save OD of timer
	mov	ds:[timerID],ax

90$:
	ret
PerfSetTimerInterval	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfSetGraphColorsChooseMeter

DESCRIPTION:	This method is sent by our "Meters" GenList (in the colors
		dialog box) when the user makes a change.

PASS:		ds	= dgroup
		cx	= StatType
		bp (high) = ListUpdateFlags
		bp (low)  = 

RETURN:		nothing

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfSetGraphColorsChooseMeter	proc	far	;in PerfFixedCommonCode resource
	mov	di, cx
EC <	cmp	di, ST_AFTER_LAST_STAT_TYPE				>
EC <	ERROR_GE PERF_ERROR						>

	mov	cx, word ptr ds:[graphColors][di]
	ANDNF	cx, 0x000F		;make sure is decent color value
	clr	dx			;set dxcx = ColorQuad

	GetResourceHandleNS	PerfColorSelector, bx
	mov	si, offset PerfColorSelector

	mov	ax, MSG_COLOR_SELECTOR_SET_COLOR
	clr	bp			;nothing is indeterminant
	clr	di
	call	ObjMessage

	ret
PerfSetGraphColorsChooseMeter	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfCalcNumGraphs

DESCRIPTION:	This routine calculates the number of active graphs.

CALLED BY:	

PASS:		ds	= dgroup

RETURN:		al	= number of graphs

DESTROYED:	di

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfCalcNumGraphs	proc	far	;in PerfFixedCommonCode resource
	clr	al			;reset counter
	mov	di, ST_AFTER_LAST_STAT_TYPE

10$:
	sub	di, 2

	cmp	word ptr ds:[graphModes][di], FALSE
	je	20$

	inc	al			;one more!

20$:
	tst	di			;was that the last graph type?
	jnz	10$			;loop if not...

	mov	ds:[curNumGraphs], al
	ret
PerfCalcNumGraphs	endp


COMMENT @----------------------------------------------------------------------

FUNCTION:	PerfLockStrings, PerfUnlockStrings

DESCRIPTION:	These routines lock & unlock the PerfProcStrings resource.

CALLED BY:	PerfExposed, DrawAllPerfMeters

PASS:		ds	= dgroup

RETURN:		ds, di= same

DESTROYED:	?

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Eric	5/91		Initial version

------------------------------------------------------------------------------@

PerfLockStrings	proc	far
	push	ax, bx

EC <	tst	ds:[procStringsSeg]					>
EC <	ERROR_NZ PERF_ERROR						>

	mov	bx, handle PerfProcStrings
	call	MemLock
	mov	ds:[procStringsSeg], ax

	pop	ax, bx
	ret
PerfLockStrings	endp

PerfUnlockStrings	proc	far
	push	ax, bx

EC <	tst	ds:[procStringsSeg]					>
EC <	ERROR_Z	PERF_ERROR						>

	mov	bx, handle PerfProcStrings
	call	MemUnlock		;unlock strings resource
EC <	clr	ds:[procStringsSeg]					>
	pop	ax, bx
	ret
PerfUnlockStrings	endp

PerfFixedCommonCode ends
