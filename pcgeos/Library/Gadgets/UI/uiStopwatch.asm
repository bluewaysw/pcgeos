COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1994 -- All Rights Reserved

PROJECT:	Interface Gadgets
MODULE:		Stopwatch
FILE:		uiStopwatch.asm

AUTHOR:		Skarpi Hedinsson, Jul  8, 1994

ROUTINES:
	Name			Description
	----			-----------
    INT SendSWActionMessage     Sends the action message (SWI_actionMsg) to
				the output (GCI_output).

    INT StopwatchInc            Increment the stopwatch timer by one.

    INT StopwatchGetTime        Return the time in StopwatchStruct

    INT StopwatchSetTime        Set time to StopwatchStruct

    INT StopwatchUpdateText     Formats and updates the string in SWText to
				show the currect time of the stopwatch.

    INT StopwatchFormatText     Formats the text to show SWI_time (the
				stopwatch time). Format: #:##:##.#s

    INT AppendZero              Formats the text to show SWI_time (the
				stopwatch time). Format: #:##:##.#s

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94   	Initial revision


DESCRIPTION:
	
		

	$Id: uiStopwatch.asm,v 1.1 97/04/04 17:59:34 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if 0						; THIS OBJECT IS NO LONGER
						; USED!

GadgetsClassStructures	segment resource

	StopwatchClass		; declare the control class record

GadgetsClassStructures	ends

;---------------------------------------------------

GadgetsSelectorCode segment resource

COMMENT @----------------------------------------------------------------------

MESSAGE:	StopwatchGetInfo --
		MSG_GEN_CONTROL_GET_INFO for StopwatchClass

DESCRIPTION:	Return group

PASS:
	*ds:si 	- instance data
	es 	- segment of StopwatchClass
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
StopwatchGetInfo	method dynamic	StopwatchClass,
					MSG_GEN_CONTROL_GET_INFO

	mov	si, offset SWC_dupInfo
	call	CopyBuildInfoCommon
	ret
StopwatchGetInfo	endm

SWC_dupInfo	GenControlBuildInfo	<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
	0,				; GCBI_initFileKey
	0,				; GCBI_gcnList
	0,				; GCBI_gcnCount
	0,				; GCBI_notificationList
	0,				; GCBI_notificationCount
	0,				; GCBI_controllerName

	handle StopwatchUI,		; GCBI_dupBlock
	SWC_childList,			; GCBI_childList
	length SWC_childList,		; GCBI_childCount
	SWC_featuresList,		; GCBI_featuresList
	length SWC_featuresList,	; GCBI_featuresCount
	SW_DEFAULT_FEATURES,		; GCBI_features

	0,				; GCBI_toolBlock
	0,				; GCBI_toolList
	0,				; GCBI_toolCount
	0,				; GCBI_toolFeaturesList
	0,				; GCBI_toolFeaturesCount
	0>				; GCBI_toolFeatures

GadgetsControlInfo	segment resource

SWC_childList	GenControlChildInfo	\
   <offset StopwatchGroup, mask SWF_TIME, mask GCCF_ALWAYS_ADD>

; Careful, this table is in the *opposite* order as the record which
; it corresponds to.

SWC_featuresList	GenControlFeaturesInfo	\
	<offset StopwatchGroup, offset StopwatchName, 0>

GadgetsControlInfo	ends

COMMENT @----------------------------------------------------------------------

MESSAGE:	StopwatchGenerateUI -- MSG_GEN_CONTROL_GENERATE_UI
						for StopwatchClass

DESCRIPTION:	This message is subclassed to set the monikers of
		the filled/unfilled items

PASS:
	*ds:si - instance data
	es - segment of StopwatchClass
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
StopwatchGenerateUI		method dynamic	StopwatchClass,
				MSG_GEN_CONTROL_GENERATE_UI
		.enter
	;
	; Call the superclass
	;
		mov	di, offset StopwatchClass
		call	ObjCallSuperNoLock

		.leave
		ret
StopwatchGenerateUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchMetaDetach
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This message is subclassed to stop the stopwatch timer if
		it is going.

CALLED BY:	MSG_META_DETACH
PASS:		*ds:si	= StopwatchClass object
		ds:di	= StopwatchClass instance data
		ds:bx	= StopwatchClass object (same as *ds:si)
		es 	= segment of StopwatchClass
		ax	= message #
		cx	= caller ID
		dx:bp   = OD of caller
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/11/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopwatchMetaDetach	method dynamic StopwatchClass, 
					MSG_META_DETACH
		uses	ax, cx, dx, bp
		.enter
	;
	; If the stopwatch is going we stop it.
	;
		mov	bx, ds:[di].SWI_timerHandle	; bx <- timerhandle
		tst	bx
		jz	done
	;
	; Stop the stopwatch timer
	;
		push	ax
		clr	ax				; timer ID
		call	TimerStop
		pop	ax
	;
	; Clear SWI_timerHandle indicating that the timer is stop.
	;
		clr	ds:[di].SWI_timerHandle
done:
	;
	; Setup the detach
	;
		call	ObjInitDetach
	;
	; Call the superclass
	;
		mov	di, offset StopwatchClass
		call	ObjCallSuperNoLock
	;
	; Send MSG_META_ACK
	;
		call	ObjEnableDetach

		.leave
		ret
StopwatchMetaDetach	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchStartStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts the timer that updates the time and display

CALLED BY:	MSG_STOPWATCH_START_STOP
PASS:		*ds:si	= StopwatchClass object
		ds:di	= StopwatchClass instance data
		ds:bx	= StopwatchClass object (same as *ds:si)
		es 	= segment of StopwatchClass
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
StopwatchStartStop	method dynamic StopwatchClass, 
					MSG_STOPWATCH_START_STOP
		uses	ax, cx, dx, bp
		.enter
	;
	; If the stopwatch is going we stop it.
	;
		mov	bx, ds:[di].SWI_timerHandle
		tst	bx
		jnz	stopTimer
	;
	; Start the timer.
	;
		mov	bx, ds:[LMBH_handle]
		mov	al, TIMER_EVENT_CONTINUAL
		mov	dx, MSG_STOPWATCH_UPDATE
		clr	cx
		mov	di, 6			; 1/10 sec
		call	TimerStart		; ax <- Timer ID
						; bx <- Timer Handle
	;
	; Store the timer handle - used when stopping timer.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ds:[di].SWI_timerHandle, bx
	;
	; Set the action type which is sent with the action message telling
	; output what action was taken
	;
		mov	cx, SAT_START
done:
	;
	; Send the action message
	;
		call	SendSWActionMessage
		.leave
		ret
stopTimer:
	;
	; Stop the stopwatch timer.
	;
		clr	ax			; timer ID
		call	TimerStop
	;
	; Clear SWI_timerHandle indicating that the timer is stop.
	;
		clr	ds:[di].SWI_timerHandle
	;
	; Show the time when stopped.
	;
		call	StopwatchUpdateText
	;
	; Set the action type so the output knows that the stopwatch has
	; stopped.
	;
		mov	cx, SAT_STOP		; cx <- StopwatchActionType
		jmp	done

StopwatchStartStop	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the time to 0 on the stopwatch.

CALLED BY:	MSG_STOPWATCH_RESET
PASS:		*ds:si	= StopwatchClass object
		ds:di	= StopwatchClass instance data
		ds:bx	= StopwatchClass object (same as *ds:si)
		es 	= segment of StopwatchClass
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
StopwatchReset	method dynamic StopwatchClass, 
					MSG_STOPWATCH_RESET
		uses	ax, cx, dx, bp
		.enter
	;
	; Check if the timer is running if so there is nothing we can do
	;
		tst	ds:[di].SWI_timerHandle
		jnz	done
	;
	; Clear the time in instace data
	;
		clr	ds:[di].SWI_time.SW_hours
		clr	ds:[di].SWI_time.SW_minutes
		clr	ds:[di].SWI_time.SW_seconds
		clr	ds:[di].SWI_time.SW_tenths
	;
	; Send the action message
	;
		mov	cx, SAT_RESET
		call	SendSWActionMessage
	;
	; Update the text to show all zeros
	;
		call	StopwatchUpdateText
done:
		.leave
		ret
StopwatchReset	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sent every 1/10 sec. to update the stopwatch timer.

CALLED BY:	MSG_STOPWATCH_UPDATE
PASS:		*ds:si	= StopwatchClass object
		ds:di	= StopwatchClass instance data
		ds:bx	= StopwatchClass object (same as *ds:si)
		es 	= segment of StopwatchClass
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
StopwatchUpdate	method dynamic StopwatchClass, 
					MSG_STOPWATCH_UPDATE
		uses	ax, cx, dx, bp
		.enter
	;
	; First check if the SWI_timerHandle is 0 if so then the timer is
	; no longer running so this update should not take place.
	;
		tst	ds:[di].SWI_timerHandle
		jz	done
	;
	; Increment the stopwatch timer by one
	;
		add	di, offset SWI_time
		call	StopwatchInc
	;
	; Only update every other tenth of a second.
	;
		mov	al, ds:[di].SW_tenths
		cmp	al, 1
		je	done
		cmp	al, 3
		je	done
		cmp	al, 5
		je	done
		cmp	al, 7
		je	done
		cmp	al, 9
		je	done
	;
	; Update the stopwatch GenText to show the new count
	;
		call	StopwatchUpdateText
done:
		.leave
		ret
StopwatchUpdate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SendSWActionMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends the action message (SWI_actionMsg) to the output 
		(GCI_output).

CALLED BY:	StopwatchStartStop, StopwatchReset
PASS:		*ds:si - Object
		cx     - StopwatchActionType
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	6/30/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SendSWActionMessage	proc	near
		uses	ax,bx,cx,dx,di,bp
	class	StopwatchClass
		.enter
	;
	; Get the action message and destination from instance data and
	; send message.
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		mov	ax, ds:[di].SWI_actionMsg	; ax <- msg to send
		mov	bx, segment @CurClass
		mov	di, offset @CurClass
		call	GenControlSendToOutputRegs

		.leave
		ret
SendSWActionMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StopwatchUpdateText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Formats and updates the string in SWText to show the
		currect time of the stopwatch.

CALLED BY:	StopwatchUpdate
PASS:		*ds:si - Stopwatch Object
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SH	7/ 8/94    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StopwatchUpdateText	proc	near
		uses	ax,bx,cx,dx,si,di,bp,es
	class	StopwatchClass
		.enter
	;
	; Get the timer count
	;
		mov	di, ds:[si]
		add	di, ds:[di].Gen_offset
		add	di, offset SWI_time
		call	StopwatchGetTime	; ch, dx, dp <- time
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
		mov	di, offset SWText
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallControlChild
	;
	; Reset the stack
	;
		add	sp, size DateTimeBuffer

		.leave
		ret
StopwatchUpdateText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SStopwatchGetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the time currently held in the stopwatch.

CALLED BY:	MSG_STOPWATCH_GET_TIME
PASS:		ds:di	= StopwatchClass instance data
		ax	= message #
RETURN:		ch	= hours (0 through 23)
		dl	= minutes (0 through 59)
		dh	= seconds (0 through 59)
		bp	= 1/10 sec.
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	JAG	11/29/94   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
SStopwatchGetTime	method dynamic StopwatchClass, 
					MSG_STOPWATCH_GET_TIME
		uses	ax
		.enter

		mov	ch, ds:[di].SWI_time.SW_hours
		mov	dl, ds:[di].SWI_time.SW_minutes
		mov	dh, ds:[di].SWI_time.SW_seconds
		mov	al, ds:[di].SWI_time.SW_tenths
		clr	ah
		mov	bp, ax			; bp <- tenths of seconds
		
		.leave
		ret
SStopwatchGetTime	endm


GadgetsSelectorCode ends

endif						; THIS OBJECT IS GONE
