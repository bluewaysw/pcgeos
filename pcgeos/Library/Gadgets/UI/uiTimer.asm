COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		TimeInput
FILE:		uiTimer.asm

AUTHOR:		Skarpi Hedinsson, Jul 11, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT TimerResetCountdown     Reset a countdown timer, dealing with the
				case of the user trying to reset to 0.

    INT TimerResetStopwatch     Do reset when TI_style == TS_STOPWATCH.

    INT TimerCopyCountdownTimeToTime 
				Copy TI_countdownTime to TI_time.

    INT TimerIncStopwatch       Increment the stopwatch timer by one.

    INT StopwatchSetTime        Set time to StopwatchStruct

    INT SendTMActionMessage     Sends the action message (TI_actionMsg) to
				the output (GCI_output).

    INT TimerSetStartTime       This function is called when a timer is
				started.  It checks to see if TI_time is
				zero.  If it's not zero we simply continue
				counting down from the value in TI_time.
				If it is zero we set the value in
				TI_countdownTime to TI_time.  If
				TI_countdownTime is zero we return a carry.

    INT TimerDec                Decrement the Timer timer by one.

    INT TimerIsTimeZero         Returns a carry if a StopwatchStruct is all
				zeros.

    INT TimerUpdateText         Formats and updates the string in TMText to
				show the currect time of the Timer.

    INT StopwatchGetTime        Return the time in StopwatchStruct

    INT StopwatchFormatText     Formats the text to show SWI_time (the
				stopwatch time). Format: #:##:##.#s

    INT AppendZero              Append a zero to string if value < 10.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/11/94   	Initial revision


DESCRIPTION:
	Implementation of TimerClass.
		

	$Id: uiTimer.asm,v 1.1 97/04/04 17:59:29 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GadgetsClassStructures	segment resource

	TimerClass		; declare the control class record

GadgetsClassStructures	ends

;---------------------------------------------------

GadgetsSelectorCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	TimerGetInfo --
		MSG_GEN_CONTROL_GET_INFO for TimerClass

DESCRIPTION:	Return group

PASS:
	*ds:si 	- instance data
	es 	- segment of TimerClass
	ax 	- The message
	cx:dx	- GenControlBuildInfo structure to fill in

RETURN:
	cx:dx - list of children

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tony	10/31/91		Initial version

------------------------------------------------------------------------------@
TimerGetInfo	method dynamic	TimerClass, 
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset TMC_dupInfo
	call	CopyBuildInfoCommon
	ret
TimerGetInfo	endm

TMC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
	0, 				; GCBI_initFileKey
	0, 				; GCBI_gcnList
	0, 				; GCBI_gcnCount
	0, 				; GCBI_notificationList
	0, 				; GCBI_notificationCount
	0, 				; GCBI_controllerName

	handle TimerUI, 		; GCBI_dupBlock
	TMC_childList, 			; GCBI_childList
	length TMC_childList, 		; GCBI_childCount
	TMC_featuresList, 		; GCBI_featuresList
	length TMC_featuresList, 	; GCBI_featuresCount
	TM_DEFAULT_FEATURES, 		; GCBI_features

	0, 				; GCBI_toolBlock
	0, 				; GCBI_toolList
	0, 				; GCBI_toolCount
	0, 				; GCBI_toolFeaturesList
	0, 				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

GadgetsControlInfo	segment resource

TMC_childList	GenControlChildInfo	\
   <offset TimerGroup, mask TMF_TIME, mask GCCF_ALWAYS_ADD>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

TMC_featuresList	GenControlFeaturesInfo	\
	<offset TimerGroup, offset TimerName, 0>

GadgetsControlInfo	ends

COMMENT @----------------------------------------------------------------------

MESSAGE:	TimerGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
						for TimerClass

DESCRIPTION:	This message is subclassed to set the monikers of
		the filled/unfilled items

PASS:
	*ds:si - instance data
	es - segment of TimerClass
	ax - The message

RETURN:
	nothing

DESTROYED:
	bx, si, di, ds, es (message handler)

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Skarpi	06/22/94	Initial version

------------------------------------------------------------------------------@
TimerGenerateUI		method dynamic	TimerClass, 
				MSG_GEN_CONTROL_GENERATE_UI
		.enter
	;
	; Call the superclass
	;
		mov	di, offset TimerClass
		call	ObjCallSuperNoLock

	;
	; If the do draw/don't draw feature isn't set, then we have no worries
	;
		call	GetChildBlockAndFeatures	; bx <- handle
		test	ax, mask TMF_TIME
		jz	done

	;
	; Set TI_time to be the same as TI_countdownTime
	;
		call	TimerSetStartTime		

	;
	; Update the text object to show the start time
	;
		call	TimerUpdateText

done:
		.leave
		ret
TimerGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is subclassed to stop the Timer timer if
		it is going.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
		cx	= caller ID
		dx:bp   = OD of caller
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerMetaDetach	method dynamic TimerClass, 
					MSG_META_DETACH
		.enter
	;
	; If the Timer is going we stop it.
	;
		mov	bx, ds:[di].TI_timerHandle	; bx <- timerhandle
		tst	bx
		jz	done
	;
	; Stop the Timer timer
	;
		push	ax
		clr	ax				; timer ID
		call	TimerStop
		pop	ax
	;
	; Clear SWI_timerHandle, indicating that the timer is stopped.
	;
		clr	ds:[di].TI_timerHandle
done:
	;
	; Setup the detach.
	;
		call	ObjInitDetach
	;
	; Call the superclass.
	;
		mov	di, offset TimerClass
		call	ObjCallSuperNoLock
	;
	; Send MSG_META_ACK
	;
		call	ObjEnableDetach

		.leave
		ret
TimerMetaDetach	endm

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TGenControlAddToGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add us to system GCN lists. 

CALLED BY:	MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
PASS:		*ds:si	= TimerClass object
		es 	= segment of TimerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TGenControlAddToGcnLists	method dynamic TimerClass, 
					MSG_GEN_CONTROL_ADD_TO_GCN_LISTS
		.enter

		call	AddSelfToDateTimeGCNLists
		
		.leave
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
		ret
TGenControlAddToGcnLists	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TGenControlRemoveFromGcnLists
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Name sez it all.

CALLED BY:	MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
PASS:		*ds:si	= TimerClass object
		es 	= segment of TimerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TGenControlRemoveFromGcnLists	method dynamic TimerClass, 
					MSG_GEN_CONTROL_REMOVE_FROM_GCN_LISTS
		.enter

		call	RemoveSelfFromDateTimeGCNLists

		.leave
		mov	di, offset @CurClass
		GOTO	ObjCallSuperNoLock
TGenControlRemoveFromGcnLists	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerStartStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts the timer that updates the time and display

CALLED BY:	MSG_TIMER_START_STOP
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerStartStop	method dynamic TimerClass, 
					MSG_TIMER_START_STOP
		uses	ax, cx, dx, bp
		.enter
	;
	; reset the ticks count
	;
		call	TimerGetCount
		movdw	ds:[di].TI_startCount, bxax
		clr	ds:[di].TI_remainder
	;
	; If the Timer is going we stop it.
	;
		mov	bx, ds:[di].TI_timerHandle
		tst	bx
		jnz	stopTimer

	;
	; For TS_COUNTDOWN only:
	;
	; Set TI_time from TI_countdownTime if needed.  If TI_countdownTime 
	; is zero return a warning.
	;
		cmp	ds:[di].TI_style, TS_COUNTDOWN
		jne	dontSetTime
		call	TimerSetStartTime		
		jc	timeNotSet
dontSetTime:
		
	;
	; Start the timer.
	;
		mov	bx, ds:[LMBH_handle]
		mov	al, TIMER_EVENT_CONTINUAL
		mov	dx, MSG_TIMER_UPDATE
		clr	cx
		mov	di, 6			; 1/10 sec
		call	TimerStart		; ax <- Timer ID
						; bx <- Timer Handle
	;
	; Store the timer handle - used when stopping timer.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].TI_timerHandle, bx

	;
	; Set the action type which is sent with the action message telling
	; output what action was taken
	;
		mov	cx, TAT_START

done:
	;
	; Send the action message.
	;
		call	SendTMActionMessage

		.leave
		ret
stopTimer:
	;
	; Stop the Timer timer.
	;
		clr	ax			; timer ID
		call	TimerStop
	;
	; Clear SWI_timerHandle indicating that the timer is stopped.
	;
		clr	ds:[di].TI_timerHandle
	;
	; Show the time when stopped.
	;
		call	TimerUpdateText
	;
	; Set the action type so the output knows that the Timer has
	; stopped.
	;
		mov	cx, TAT_STOP		; cx <- TimerActionType
		jmp	done

timeNotSet:
	;
	; For TS_COUNTDOWN only:
	;
	; The timer was not started since TI_time could not be set due
	; to the fact that TI_countdownTime is zero.  Let the output
	; know so they can beep or put up a dialog.
	;
		mov	cx, TAT_NO_TIME
		jmp	done

TimerStartStop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the time to countdownTime on the Timer.

CALLED BY:	MSG_TIMER_RESET
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerReset	method dynamic TimerClass, 
					MSG_TIMER_RESET
		uses	ax, cx, dx, bp
		.enter
	;
	; reset the ticks count
	;
		call	TimerGetCount
		movdw	ds:[di].TI_startCount, bxax
		clr	ds:[di].TI_remainder
	;
	; Fig'r out which function to call.
	;
		mov	bx, ds:[di].TI_style
		shl	bx, 1			; index nptrs
		call	{nptr.near} cs:resetFuncTable[bx]
						; cx <- TimerActionType
		
	;
	; Send the action message.
	;
		call	SendTMActionMessage

		.leave
		ret

resetFuncTable	nptr.near \
	offset cs:TimerResetCountdown,		; TS_COUNTDOWN
	offset cs:TimerResetStopwatch		; TS_STOPWATCH

.assert (size resetFuncTable) eq (TimerStyle * 2)

TimerReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerResetCountdown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset a countdown timer, dealing with the case of
		the user trying to reset to 0.

CALLED BY:	(INTERNAL) TimerReset
PASS:		ds:di	= TimerClass instance data
RETURN:		cx	= TimerActionType to send to GCI_output
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerResetCountdown	proc	near
		class	TimerClass
		.enter
	;
	; Check if the countdownTime is zero.
	;
		push	di
		add	di, offset TI_countdownTime
		call	TimerIsTimeZero
		pop	di				; di <- instance data
		jc	countdownIsZero

	;
	; Set the time to the countdown time.
	;
		call	TimerCopyCountdownTimeToTime

	;
	; Update the text to show the countdown time.
	;
		call	TimerUpdateText

	;
	; We'll send out the usual TimerActionType to everyone.
	;
		mov	cx, TAT_RESET

exit:
		.leave
		ret

countdownIsZero:
	;
	; Send the action message informing the countdown time is zero.
	;
		mov	cx, TAT_NO_TIME
		jmp	exit
TimerResetCountdown	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerResetStopwatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do reset when TI_style == TS_STOPWATCH.

CALLED BY:	(INTERNAL) TimerReset
PASS:		ds:di	= TimerClass object instance data
RETURN:		cx	= TimerActionType to send to GCI_output
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerResetStopwatch	proc	near
		class	TimerClass
		.enter
	;
	; Set the thing to zero.
	;
		clr	ds:[di].TI_time.SW_hours
		clr	ds:[di].TI_time.SW_minutes
		clr	ds:[di].TI_time.SW_seconds
		clr	ds:[di].TI_time.SW_tenths

	;
	; Redisplay.
	;
		call	TimerUpdateText

	;
	; Always send this out, 'cuz we don't have the weird error case
	; wot TS_COUNTDOWN does.
	;
		mov	cx, TAT_RESET

		.leave
		ret
TimerResetStopwatch	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerCopyCountdownTimeToTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copy TI_countdownTime to TI_time.

CALLED BY:	(INTERNAL) TimerReset TimerSetStartTime
PASS:		ds:di	= TimerClass instance data
RETURN:		nothing
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerCopyCountdownTimeToTime	proc near
		class	TimerClass
		.enter

		mov	al, ds:[di].TI_countdownTime.SW_hours
		mov	ds:[di].TI_time.SW_hours, al
		mov	al, ds:[di].TI_countdownTime.SW_minutes
		mov	ds:[di].TI_time.SW_minutes, al
		mov	al, ds:[di].TI_countdownTime.SW_seconds
		mov	ds:[di].TI_time.SW_seconds, al
		clr	ds:[di].TI_time.SW_tenths

		.leave
		ret
TimerCopyCountdownTimeToTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent every 1/10 sec. to update the Timer timer.

CALLED BY:	MSG_TIMER_UPDATE
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
RETURN:		nothing
DESTROYED:	everything
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerUpdate	method dynamic TimerClass, 
					MSG_TIMER_UPDATE
		.enter

		call	TimerGetCount
		movdw	dxcx, ds:[di].TI_startCount
		movdw	ds:[di].TI_startCount, bxax
	;
	; get the 1/10s of seconds that have gone by since our last update
	;
		call	GetElapsedTime
	;
	; First check if the TI_timerHandle is 0 if so then the timer is
	; no longer running so this update should not take place.
	;
		tst	ds:[di].TI_timerHandle
		jz	done
	;
	; Increment or decrement, based on style of timer.
	;
		add	di, offset TI_time
		cmp	ds:[di - offset TI_time].TI_style, TS_COUNTDOWN
		jne	updateStopwatch

	;
	; It's a TS_COUNTDOWN, so decrement the time displayed.
	; ax contains the 1/10s of seconds that have gone by, so we
	; want to decrement Timer once for each 10th that has gone by.
	; This is kind of hacked, but in the common case only 1 1/10
	; of a second has gone by.
	;	
		mov	cx, ax
		jcxz	updateDisplay
decLoop:	
		call	TimerDec
	;
	; Check to see if we have reached zero
	;
		call	TimerIsTimeZero
		jc	timeIsZero
		loop	decLoop
updateDisplay:
	;
	; Only update text every other tenth of a second.
	;
		test	ds:[di].SW_tenths, 1
		jnz	done

	;
	; Update the Timer GenText to show the new count
	;
		call	TimerUpdateText
done:
		.leave
		ret

	;
	; The TS_COUNTDOWN timer has reached zero.  Update the text and let
	; the output know that the timer has reached its end.  Also we
	; have to stop the timer.
	;
timeIsZero:	
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	bx, ds:[di].TI_timerHandle
		clr	ax
		call	TimerStop
		clr	ds:[di].TI_timerHandle
	;
	; Update and send action message.
	;
		call	TimerUpdateText
		mov	cx, TAT_ZERO
		call	SendTMActionMessage
		jmp	done

updateStopwatch:
	;
	; Increment the displayed value.
	; ax contains the 1/10s of seconds that have gone by, so we
	; want to increment Timer once for each 10th that has gone by.
	; This is kind of hacked, but in the common case only 1 1/10
	; of a second has gone by.
	;	
		mov	cx, ax
		jcxz	noInc
incLoop:	
		call	TimerIncStopwatch
		loop	incLoop
noInc:
		jmp	updateDisplay
TimerUpdate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetElapsedTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the elapsed time since we last updated the timer

CALLED BY:	TimerUpdate
PASS:		bxax	= new system count
		dxcx	= old system count
		ds:di	= TimerClass instance data
RETURN:		ax	= 10ths of seconds.
DESTROYED:	bx, cx, dx
SIDE EFFECTS:	
		the remainder of system ticks gets put in TI_remainder
PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	IP	7/ 3/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetElapsedTime	proc	near
	class	TimerClass
	.enter
	subdw	bxax, dxcx
	jnc	cont
	;
	; The system count has rolled over so we want to take the
	; negative. 
	;
	negdw	bxax
cont:
	add	ax, ds:[di].TI_remainder
EC<	ERROR_C	BAD_ELAPSED_TIME	>
	clr	dx
	mov	bx, 6
	div	bx		; ax = 10ths of seconds
	mov	ds:[di].TI_remainder, dx
	
	.leave
	ret
GetElapsedTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerIncStopwatch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Increment the stopwatch timer by one.

CALLED BY:	(INTERNAL) TimerUpdate
PASS:		ds:di	= ptr to StopwatchStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerIncStopwatch	proc	near
		uses	ax
		.enter

		clr	al			; for convenience
	;
	; bump tenth
	;
		inc	ds:[di].SW_tenths
		cmp	ds:[di].SW_tenths, 10
	LONG_EC	jne	done
		mov	ds:[di].SW_tenths, al
	;
	; bump seconds
	;
		inc	ds:[di].SW_seconds
		cmp	ds:[di].SW_seconds, 60
		jne	done
		mov	ds:[di].SW_seconds, al
	;
	; bump minutes
	;
		inc	ds:[di].SW_minutes
		cmp	ds:[di].SW_minutes, 60
		jne	done
		mov	ds:[di].SW_minutes, al
	;
	; bump hours
	;
		inc	ds:[di].SW_hours
		cmp	ds:[di].SW_hours, 24
		jne	done
		mov	ds:[di].SW_hours, al
done:
		.leave
		ret
TimerIncStopwatch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerGetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the timer time.

CALLED BY:	MSG_TIMER_GET_TIME
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
RETURN:		
		ch 	- hours (0 through 23)
	      	dl 	- minutes (0 through 59)
		dh 	- seconds (0 through 59)
		bp 	- 1/10 sec.

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerGetTime	method dynamic TimerClass, 
					MSG_TIMER_GET_TIME
		uses	ax
		.enter
	;
	; Return the time
	;
		add	di, offset TI_time
		call	StopwatchGetTime	; ch, dx, bp <- time

		.leave
		ret
TimerGetTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerSetCountdownTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the TI_countdownTime instance data.

CALLED BY:	MSG_TIMER_SET_COUNTDOWN_TIME
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
		ch 	= hours (0 through 23)
	        dl 	= minutes (0 through 59)
	        dh 	= seconds (0 through 59)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerSetCountdownTime	method dynamic TimerClass, 
					MSG_TIMER_SET_COUNTDOWN_TIME
		uses	ax, cx, dx, bp
		.enter
	;
	; Set the TI_countdownTime
	;
		clr	bp				; no 1/10sec.
		add	di, offset TI_countdownTime
		call	StopwatchSetTime

		.leave
		ret
TimerSetCountdownTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchSetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set time to StopwatchStruct

CALLED BY:	(INTERNAL) TimerSetCountdownTime
PASS:		ds:di  = ptr to StopwatchStruct
		ch     = hours
		dl     = minutes
		dh     = seconds
		bp     = 1/10 sec
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopwatchSetTime	proc	near
		mov	ds:[di].SW_hours, ch
		mov	ds:[di].SW_minutes, dl
		mov	ds:[di].SW_seconds, dh
		mov	cx, bp
		mov	ds:[di].SW_tenths, cl
		ret
StopwatchSetTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerGetCountdownTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns TI_countdownTime instance data.

CALLED BY:	MSG_TIMER_GET_COUNTDOWN_TIME
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
RETURN:		
		ch 	- hours (0 through 23)
	      	dl 	- minutes (0 through 59)
		dh 	- seconds (0 through 59)
		bp 	- 1/10 sec.

DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerGetCountdownTime	method dynamic TimerClass, 
					MSG_TIMER_GET_COUNTDOWN_TIME
		uses	ax
		.enter
	;
	; Return the countdown time.
	;
		add	di, offset TI_countdownTime
		call	StopwatchGetTime	; ch, dx, bp <- time

		.leave
		ret
TimerGetCountdownTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendTMActionMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the action message (TI_actionMsg) to the output 
		(GCI_output).

CALLED BY:	(INTERNAL) TimerReset TimerStartStop TimerUpdate
PASS:		*ds:si = TimerClass object
		cx     = TimerActionType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendTMActionMessage	proc	near
		uses	ax, bx, cx, dx, di, bp
		class	TimerClass
		.enter
	;
	; Get the action message and destination from instance data and
	; send message.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].TI_actionMsg	; ax <- msg to send
		mov	bx, segment @CurClass
		mov	di, offset @CurClass
		call	GenControlSendToOutputRegs
		
		.leave
		ret
SendTMActionMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerSetStartTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This function is called when a timer is started.  It checks
		to see if TI_time is zero.  If it's not zero we simply
		continue counting down from the value in TI_time.  If it is
		zero we set the value in TI_countdownTime to TI_time.  If
		TI_countdownTime is zero we return a carry.

CALLED BY:	TimerStartStop
PASS:		*ds:si	= TimerClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
		Updates TI_time instance data.

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerSetStartTime	proc	near
		uses	ax, bx, cx, dx, si, di, bp
		class	TimerClass
		.enter
	;
	; First check if the time in TI_time is zero.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		push	di
		add	di, offset TI_time
		call	TimerIsTimeZero
		pop	di
		jnc	done			; if not we are done
	;
	; Now we have to check if TI_countdownTime is zero.
	;
		push	di
		add	di, offset TI_countdownTime
		call	TimerIsTimeZero	
		pop	di
		jc	returnWarning
	;
	; Now we can copy TI_countdownTime to TI_time.	
	;
		call	TimerCopyCountdownTimeToTime
	;
	; Clear the carry since the time is set
	;
		clc
done:
		.leave
		ret
returnWarning:
	;
	; The countdownTime is zero so we could not set the start time.
	;	
		stc
		jmp	done
TimerSetStartTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerDec
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement the Timer timer by one.

CALLED BY:	(INTERNAL) TimerUpdate
PASS:		ds:di	= ptr to StopwatchStruct
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerDec	proc	near
		uses	ax
		.enter
		clr	al
	;
	; dec tenth
	;
		dec	ds:[di].SW_tenths
		cmp	ds:[di].SW_tenths, -1
	LONG_EC	jnz	done
		mov	ds:[di].SW_tenths, 9
	;
	; dec seconds
	;
		dec	ds:[di].SW_seconds
		cmp	ds:[di].SW_seconds, -1
		jnz	done
		mov	ds:[di].SW_seconds, 59
	;
	; dec minutes
	;
		dec	ds:[di].SW_minutes
		cmp	ds:[di].SW_minutes, -1
		jnz	done
		mov	ds:[di].SW_minutes, 59
	;
	; dec hours
	;
		dec	ds:[di].SW_hours
		cmp	ds:[di].SW_hours, -1
		jnz	done
		mov	ds:[di].SW_hours, 0
done:
		.leave
		ret
TimerDec	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerIsTimeZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a carry if a StopwatchStruct is all zeros.

CALLED BY:	(INTERNAL) TimerReset TimerSetStartTime TimerUpdate
PASS:		ds:di	= ptr to StopwatchStruct
RETURN:		carry set if zero
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/12/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerIsTimeZero	proc	near
		.enter

		tst_clc	ds:[di].SW_tenths
		jnz	done
		tst_clc	ds:[di].SW_seconds
		jnz	done
		tst_clc	ds:[di].SW_minutes
		jnz	done
		tst_clc	ds:[di].SW_hours
		jnz	done

	;
	; At this point we know that the time is zero so we set the carry.
	;
		stc

done:
		.leave
		ret
TimerIsTimeZero	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats and updates the string in TMText to show the
		currect time of the Timer.

CALLED BY:	(INTERNAL) TimerGenerateUI TimerReset TimerStartStop
		TimerUpdate
PASS:		*ds:si	= TimerClass object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TimerUpdateText	proc	near
		uses	ax, bx, cx, dx, si, di, bp, es
		class	TimerClass
		.enter
	;
	; Get the timer count
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset TI_time
		call	StopwatchGetTime	; ch, dx, bp <- time
	;
	; Format the various parts of the timer string
	;
		sub	sp, size DateTimeBuffer
		segmov	es, ss
		mov	di, sp			; es:di <- buffer for string
		call	StopwatchFormatText	; es:di <- formatted string
	;
	; Update the GenText
	;
		movdw	dxbp, esdi		; dx:bp <- timer string
		clr	cx			; null-terminated
		mov	di, offset TMText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallControlChild
	;
	; Reset the stack
	;
		add	sp, size DateTimeBuffer

		.leave
		ret
TimerUpdateText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchGetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the time in StopwatchStruct

CALLED BY:	(INTERNAL) StopwatchUpdateText TimerGetCountdownTime
		TimerGetTime TimerUpdateText
PASS:		ds:di  = ptr to StopwatchStruct
RETURN:		ch     = hours
		dl     = minutes
		dh     = seconds
		bp     = 1/10 sec
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopwatchGetTime	proc	near
		clr	cx
		mov	cl, ds:[di].SW_tenths
		mov	bp, cx
		mov	ch, ds:[di].SW_hours
		mov	dl, ds:[di].SW_minutes
		mov	dh, ds:[di].SW_seconds
		ret
StopwatchGetTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchFormatText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats the text to show SWI_time (the stopwatch time).
		Format:  #:##:##.#s

CALLED BY:	(INTERNAL) StopwatchUpdateText TimerUpdateText
PASS:		es:di - buffer for text
		ch    = hours
		dl    = min
		dh    = sec
		bp    = 1/10 sec.
RETURN:		es:di = Formatted string (null-terminated)
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopwatchFormatText	proc	near
		uses	ax, bx, cx, dx, si, bp, ds
		.enter
	;
	; Set the first char in es:di as zero so strcat will work.
	;
		mov	{byte} es:[di], C_NULL
	;
	; Format the hour
	;
		clr	ax
		mov	al, ch			; al <- hour
		call	AppendZero
		push	dx, di
		call	LocalStringSize		; cx
		add	di, cx
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	dx, di			; dx <- min/sec
	;
	; Get the system time separator to separate hours and minutes
	;
		call	GetSystemTimeSeparator	; ax <- separator
		push	ax
		segmov	ds, ss
		mov	si, sp
		clr	cx
		call	StrCat
	;
	; Format the minutes, first check if the minutes are less than ten.
	; if so then we append a zero in front.
	;
		mov	al, dl			; al <- min
		call	AppendZero
		push	dx, di
		call	LocalStringSize		; cx
		add	di, cx
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	dx, di
	;
	; Add separator (it's still on the stack)
	;
		segmov	ds, ss
		mov	si, sp
		clr	cx
		call	StrCat
		pop	bx		; not on stack anymore
	;
	; Format the seconds. First check if we need to padd a zero
	;
		mov	al, dh			; al <- sec
		call	AppendZero
		push	di
		call	LocalStringSize		; cx <- size
		add	di, cx
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	di
	;
	; Add second - tenth separator
	;
		clr	ax
		mov	al, C_PERIOD
		push	ax
		segmov	ds, ss
		mov	si, sp
		clr	cx
		call	StrCat
		pop	ax
	;
	; Format the tenth of second
	;
		push	di
		call	LocalStringSize		; cx
		add	di, cx
		mov	ax, bp			; al <- tenth
		clr	dx
		mov	cx, mask UHTAF_NULL_TERMINATE
		call	UtilHex32ToAscii	; cx <- length
		pop	di
	;
	; Add the last 's'
	;
		clr	ax
		mov	al, C_SMALL_S
		push	ax
		segmov	ds, ss
		mov	si, sp
		clr	cx
		call	StrCat
		pop	ax
	
		.leave
		ret
StopwatchFormatText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AppendZero
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Append a zero to string if value < 10.

CALLED BY:	(INTERNAL) StopwatchFormatText
PASS:		al	= value
		es:di	= string to append to
RETURN:		nothing
DESTROYED:	cx, ds, si
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	12/14/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AppendZero	proc near
		.enter
	;
	; Is the value less then ten?
	;
		cmp	al, 10
		jge	tenOrMore

	;
	; ...if so append a zero to the string.
	;
		push	ax
		clr	ax
		mov	al, C_ZERO
		push	ax
		segmov	ds, ss
		mov	si, sp
		clr	cx
		call	StrCat
		pop	ax
		pop	ax

tenOrMore:
		.leave
		ret
AppendZero	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TTimerSetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the displayed time.

CALLED BY:	MSG_TIMER_SET_TIME
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ch	= hours
		dl	= minutes
		dh	= seconds
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	12/14/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TTimerSetTime	method dynamic TimerClass, 
					MSG_TIMER_SET_TIME
		.enter

		mov	ds:[di].TI_time.SW_hours, ch
		mov	ds:[di].TI_time.SW_minutes, dl
		mov	ds:[di].TI_time.SW_seconds, dh
		clr	ds:[di].TI_time.SW_tenths

		call	TimerUpdateText
		
		.leave
		ret
TTimerSetTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TMetaNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deal with changes in date/time format in .INI file.

CALLED BY:	MSG_META_NOTIFY
PASS:		*ds:si	= TimerClass object
		ds:di	= TimerClass instance data
		ds:bx	= TimerClass object (same as *ds:si)
		es 	= segment of TimerClass
		ax	= message #
		cx:dx	= NotificationType
			cx - NT_manuf
			dx - NT_type
		bp	= change specific data (InitFileEntry)
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	1/16/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
TMetaNotify	method dynamic TimerClass, 
					MSG_META_NOTIFY
		.enter
	;
	; See if it's the notification we're interested in.
	;
		cmp	cx, MANUFACTURER_ID_GEOWORKS
		jne	callSoup
		cmp	dx, GWNT_INIT_FILE_CHANGE
		jne	callSoup

	;
	; We need to redraw if the time format has changed.
	;
		cmp	bp, IFE_DATE_TIME_FORMAT
		jne	exit
		call	TimerUpdateText

exit:
		.leave
		ret

callSoup:
		mov	di, offset @CurClass
		call	ObjCallSuperNoLock
		jmp	exit
TMetaNotify	endm

GadgetsSelectorCode ends
