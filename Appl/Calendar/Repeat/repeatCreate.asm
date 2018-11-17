COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Repeat
FILE:		repeatCreate.asm

AUTHOR:		Don Reeves, Nov 20, 1989

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial revision


DESCRIPTION:
	Implements the creation of repeating events.
		
	$Id: repeatCreate.asm,v 1.1 97/04/04 14:48:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatNewEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set-up the New Repeat Event DB

CALLED BY:	UI (MSG_REPEAT_NEW_EVENT)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatNewEvent	proc	far
	.enter

	; Create the starting time
	;
	call	TimerGetDateAndTime
	mov	bp, ax				; year to BP also
	mov	dx, bx				; day/month => DX
	xchg	dh, dl				; month to high byte
	mov	cx, (12 shl 8) or 31		; December 31
	mov	bx, 1				; don't adjust the forever excl
	call	RepeatSetupDuration		; set up the duration stuff
		
	; Clear the event text & reset the time text
	;
	mov	si, offset RepeatBlock:RepeatTimeText
	mov	bx, 1				; want a time string
	mov	cx, ds:[repeatTime]		; hour/minute => CX
	call	RepeatDateOrTimeToString	; stuff text into object
	mov	si, offset RepeatBlock:RepeatEventText
	call	ClearTextField			; clear the text field

	; Set up the dialog for use
	;
	mov	ax, MSG_REPEAT_ADD_NOW	; action for OK trigger
	mov	bx, offset RepeatBlock:NewRepeatMoniker
ifdef GPC_ONLY
	mov	cx, offset RepeatBlock:RepeatOKCreateMoniker
	mov	dx, offset RepeatBlock:RepeatCancelCreateMoniker
endif
	call	RepeatSetupCommon

	.leave
	ret
RepeatNewEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatChangeEventLow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the dialog box with the current RepeatStruct values

CALLED BY:	RepeatChangeEvent

PASS:		DS, ES	= DGroup
		AX	= RepeatStruct - group
		DI	= RepeatStruct - item

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatChangeEventLow	proc	far
	.enter

	; Some set-up work
	;
	call	GP_DBLockDerefSI		; lock the RepeatStruct

	; Stuff the begining and ending dates
	;
	mov	bp, es:[si].RES_startYear
	mov	dx, {word} es:[si].RES_startDay
	mov	ax, es:[si].RES_endYear
	mov	cx, {word} es:[si].RES_endDay
	clr	bx				; adjust the forever excl
	call	RepeatSetupDuration		; setup all the duration stuff

	; Stuff the time of day
	;
	mov	si, es:[di]			; re-dereference the hanlde
	mov	cx, {word} es:[si].RES_minute	; Hour/Minute => CX
	mov	bx, 1
	mov	si, offset RepeatBlock:RepeatTimeText
	call	RepeatDateOrTimeToString

	; Stuff the event text
	;
	push	di
	mov	si, es:[di]			; re-dereference the handle
	mov	cx, es:[si].RES_dataLength
DBCS <	shr	cx, 1				; # bytes -> # chars	>
	mov	dx, es
	mov	bp, si
	add	bp, offset RES_data		; DX:BP points to the text
	mov	si, offset RepeatBlock:RepeatEventText
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage_repeat_call
	pop	di

	; Setup the control area
	;
	call	RepeatSetupControlArea

	; Almost done - set the additional date information
	;
	call	RepeatSetupDateInfo
	call	DBUnlock			; unlock the RepeatStruct

	; Finally, let's set the moniker, the action, and the box usable
	;
	mov	ax, MSG_REPEAT_CHANGE_NOW
	mov	bx, offset RepeatBlock:ChangeRepeatMoniker
ifdef GPC_ONLY
	mov	cx, offset RepeatBlock:RepeatOKChangeMoniker
	mov	dx, offset RepeatBlock:RepeatCancelChangeMoniker
endif
	call	RepeatSetupCommon
	
	.leave
	ret
RepeatChangeEventLow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetupDuration
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the duration fields and list

CALLED BY:	INTERNAL - RepeatNewEvent, RepeatChangeEventLow
	
PASS: 		DS	= DGroup
		DX:BP	= Month/Day/Year to start with
		CX:AX	= Month/Day/Year to end with
		BX	= 0 - adjust the forever exclusive, else don't

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetupDuration	proc	near
	uses	di
	.enter

	; Create the starting and ending dates
	;
	mov	di, bx				; flag => DI
	push	ax, cx				; save flag, the last date
	mov	si, offset RepeatBlock:RepeatStartText
	clr	bx				; create a date string
	call	RepeatDateOrTimeToString
	pop	bp, dx				; year => BP, month/day => DX
	cmp	bp, HIGH_YEAR+1			; forever ??
	pushf					; save this flag
	mov	si, offset RepeatBlock:RepeatEndText
	clr	bx				; create a date string
	call	RepeatDateOrTimeToString

	; Set the list properly
	;
	mov	cx, MSG_GEN_SET_NOT_ENABLED	; assume forever
	popf					; restore comparison results
	je	setList
	CheckHack <(MSG_GEN_SET_NOT_ENABLED-1) eq (MSG_GEN_SET_ENABLED)>
	dec	cx				; else set the other entry
setList:
	tst	di				; check the exclusive flag
	jnz	done				; don't change the exclusive
	mov	si, offset RepeatBlock:RepeatDurationList
	call	RepeatSetItemGroupSelection	; set an item group selection
done:
	.leave
	ret
RepeatSetupDuration	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatDateOrTimeToString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes a year/month/day and stuff the resulting string
		into the deisred text object

CALLED BY:	GLOBAL

PASS:		BX	= 0
			BP = Year
			DX = Month/Day
		BX	= Anything else
			CX = Hour/Minute
		SI	= Text Object in RepeatBlock to hold string
		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatDateOrTimeToString	proc	near
	uses	di
	.enter

	; Create the string
	;
	push	es:[LMBH_handle]		; save the block handle
	segmov	es, ds, di			; DGroup => ES
	mov	di, ds:[repeatBlockHan]		; TextObject => DI:SI
	tst	bx				; date or time ??
	jne	timeString
	mov	cx, DTF_SHORT			; DateTimeFormat
	call	DateToTextObject		; create & stuff date text
	jmp	common
timeString:
	call	TimeToTextObject		; create & stuff time text
common:
	pop	bx				; block handle => BX
	call	MemDerefES			; restore the segment

	.leave
	ret
RepeatDateOrTimeToString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetupControlArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the control area for the RepeatAdd/Change Box

CALLED BY:	RepeatChangeEventLow

PASS:		ES:*DI	= RepeatStruct

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetupControlArea	proc	near
	uses	di
	.enter

	; Set up the specify type
	;
	mov	si, es:[di]			; re-dereference the handle
	clr	ch
	mov	cl, es:[si].RES_type		; get the event type
	cmp	cx, RET_WEEKLY			; is this weekly ?
	je	setFrequency			; if so, jump
	push	cx				; save the RepeatEventType
	andnf	cx, 1				; clear all but the low bit
	mov	si, offset RepeatBlock:RepeatSpecifyList
	call	RepeatSetItemGroupSelection
	pop	cx				; restore the RepeatEventType

	; Now set the frequency
	;
	andnf	cx, not 1			; clear low bit
setFrequency:
	mov	si, offset RepeatBlock:RepeatFrequencyList
	call	RepeatSetItemGroupSelection	
		
	.leave
	ret
RepeatSetupControlArea	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetupDateInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up all the additional date information

CALLED BY:	RepeatChangeEventLow

PASS:		ES:*DI	= RepeatStruct

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetupDateInfo	proc	near
	.enter

	; Set-up all the individual DOW fields
	;
	push	di
	mov	si, es:[di]			; re-dereference the handle
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx				; indeterminate booleans => DX
	mov	ch, dh
	mov	cl, es:[si].RES_DOWFlags	; determinate booleans => CX
	mov	si, offset RepeatBlock:RepeatLongDOW
	call	ObjMessage_repeat_send
	pop	di

	; Set the month spin
	;
	mov	si, es:[di]			; re-dereference the handle
	mov	cl, es:[si].RES_month
	mov	si, offset RepeatBlock:RepeatMonthValue
	call	RepeatSetCustomSpinState

	; Set the date text
	;
	mov	si, es:[di]			; dereference the handle
	mov	cl, es:[si].RES_day		; day => CL	
	call	RepeatSetDayRange		; setup the DayRange stuff

	; Set the the DOW spin
	;
	mov	si, es:[di]			; re-dereference the handle
	mov	cl, es:[si].RES_DOW
	mov	si, offset RepeatBlock:RepeatShortDOW
	call	RepeatSetCustomSpinState

	; Set the date text
	;
	mov	si, es:[di]			; re-dereference the handle
	mov	cl, es:[si].RES_occur
	mov	si, offset RepeatBlock:RepeatOccurrence
	call	RepeatSetCustomSpinState

	.leave
	ret
RepeatSetupDateInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetDayRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call to set the index value of a CustomSpin gadget

CALLED BY:	RepeatSetupDateInfo

PASS:		DS	= DGroup
		CL	= Day

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetDayRange	proc	near
	uses	di
	.enter

	; Setup the list first
	;
	clr	ch
	push	cx				; save the day value
	jcxz	setList
	mov	cx, -1
setList:
	CheckHack <(MSG_GEN_SET_NOT_ENABLED - 1) eq MSG_GEN_SET_ENABLED>
	add	cx, MSG_GEN_SET_NOT_ENABLED
	mov	si, offset RepeatBlock:RepeatDateList
	call	RepeatSetItemGroupSelection

	; Now setup the range
	;
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	pop	cx				; day value => CX
	tst	cx				; is it zero ??
	jnz	setRange
	mov	cx, 1				; else make it start at day 1
setRange:
	clr	bp				; a "determinate" value
	mov	si, offset RepeatBlock:RepeatDateValue
	call	ObjMessage_repeat_send

	.leave
	ret
RepeatSetDayRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearTextField
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text to either the number passed or blank if CL = -1

CALLED BY:	RepeatSetupDateInfo

PASS:		SI	= Handle of TextObject in RepeatBlock
		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LocalDefNLString blankByte1	<0>

ClearTextField	proc	near
	uses	di
	.enter

	; Setup the text buffer to use
	;
	mov	dx, cs
	mov	bp, offset blankByte1		; text string => DX:BP
	clr	cx				; no text
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage_repeat_send

	.leave
	ret
ClearTextField	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetupCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the OK action, the box moniker, and initiates the
		interaction

CALLED BY:	RepeatNewEvent, RepeatChangeEventLow

PASS:		DS	= DGroup
		AX	= Method for OK action
		BX	= Chunk containing dialog box moniker
		GPC_ONLY:
		CX	= Chunk containing OK trigger moniker
		DX	= Chunk containing Cancel trigger moniker

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetupCommon	proc	near

	; Set the OK trigger message
	;
	push	bx				; save dialog box moniker
ifdef GPC_ONLY
	push	dx				; save cancel trigger moniker
	push	cx				; save OK trigger moniker
endif
	mov_tr	cx, ax				; message => CX
	mov	ax, MSG_GEN_TRIGGER_SET_ACTION_MSG
	mov	si, offset RepeatBlock:RepeatOKTrigger
	call	ObjMessage_repeat_send

ifdef GPC_ONLY
	; Set the OK moniker
	;
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	si, offset RepeatBlock:RepeatOKTrigger
	pop	cx				; Moniker chunk => CX
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage_repeat_send		; set the moniker chunk

	; Set the Cancel moniker
	;
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	si, offset RepeatBlock:RepeatCancelTrigger
	pop	cx				; Moniker chunk => CX
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage_repeat_send		; set the moniker chunk
endif	

	; Set the window moniker
	;
	mov	ax, MSG_GEN_USE_VIS_MONIKER
	mov	si, offset RepeatBlock:RepeatAddBox
	pop	cx				; Moniker chunk => CX
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage_repeat_send		; set the moniker chunk

	; Now put it on the screen
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GOTO	ObjMessage_repeat_send		; make the dialog box visible
RepeatSetupCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetFrequency
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the type of the RepeatEvent

CALLED BY:	UI (MSG_REPEAT_SET_FREQUENCY)

PASS:		DS	= DGroup
		CL	= RepeatEventType

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetFrequency	proc	far

	; Some set-up work
	;
	mov	ds:[curRepeatType], cl		; store the type of event
	cmp	cl, RET_WEEKLY

	; Enable/disable some of the gadgets
	;
	mov	ax, MSG_GEN_SET_ENABLED	; assume not weekly
	mov	bp, MSG_GEN_SET_NOT_ENABLED
	jne	doPart1
	xchg	ax, bp				; swap the methods
	mov	si, offset RepeatBlock:RepeatOccurrence
	call	RepeatSetState
	mov	si, offset RepeatBlock:RepeatShortDOW
	call	RepeatSetState
doPart1:
	mov	si, offset RepeatBlock:RepeatSpecifyList
	call	RepeatSetState
	mov	si, offset RepeatBlock:RepeatInfoPart1
	call	RepeatSetState

	; Enable/disable another group of gadgets
	;
	mov	ax, bp				; do reverse of above
	mov	si, offset RepeatBlock:RepeatLongDOW
	call	RepeatSetState
	cmp	ax, MSG_GEN_SET_ENABLED	; was it weekly ??
	je	done				; if so, we're done

	; Either enable or diable the month field
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	cmp	ds:[curRepeatType], RET_MONTHLY_DATE
	je	setMonthField
	mov	ax, MSG_GEN_SET_ENABLED
setMonthField:
	mov	si, offset RepeatBlock:RepeatMonthValue
	call	RepeatSetState

	; Finally, set the rest of the fields
	;
	mov	si, offset RepeatBlock:RepeatSpecifyList
	call	RepeatItemGroupGetSelection
	mov_tr	cx, ax				; result => CX
	call	RepeatSetSpecify		; Set the specify types
done:
	ret
RepeatSetFrequency	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetSpecify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the Date or Day of Week type of RepeatEvent

CALLED BY:	RepeatSetSpecifyDate, RepeatSetSpecifyDOW

PASS:		DS	= DGroup
		CL	= 0 for Date
			= 1 for Day of Week

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetSpecify	proc	far
	.enter

	; Set up the Repeat Event type
	;
	and	ds:[curRepeatType], not 1	; clear the low bit
	or	ds:[curRepeatType], cl		; set the proper event type

	; Enable/disable the short DOW list & the occur field
	;
	mov	ax, MSG_GEN_SET_ENABLED
	test	ds:[curRepeatType], 1		; low bit set ??
	jne	setShortDOW
	mov	ax, MSG_GEN_SET_NOT_ENABLED
setShortDOW:
	mov	si, offset RepeatBlock:RepeatShortDOW
	call	RepeatSetState
	mov	si, offset RepeatBlock:RepeatOccurrence
	call	RepeatSetState

	; Enable/disable the date field
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	ds:[curRepeatType], 1		; low bit set ??
	jne	setDateField
	mov	ax, MSG_GEN_SET_ENABLED
setDateField:
	mov	si, offset RepeatBlock:RepeatDateGroup
	call	RepeatSetState

	.leave
	ret
RepeatSetSpecify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetDateExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable or disable the date range

CALLED BY:	UI (MSG_REPEAT_SET_DATE_EXCL)
	
PASS:		DS, ES	= DGroup
		CX	= Method to send

RETURN:		Nothing

DESTROYED:	AX, BX, DL, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetDateExcl	proc	far
	.enter

	mov	si, offset RepeatBlock:RepeatDateValue
	mov	ax, cx				; method to AX
	call	RepeatSetState			; set the state

	.leave
	ret
RepeatSetDateExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatSetDurationExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Enable/dsiable the duration date fields

CALLED BY:	UI (MSG_REPEAT_SET_DURATION_EXCL)
	
PASS:		ES, DS	= DGroup
		CX	= Method to send

RETURN:		Nothing

DESTROYED:	AX, BX, DL, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatSetDurationExcl	proc	far
	.enter

	mov	ax, cx				; method to AX
	mov	si, offset RepeatBlock:RepeatStartText
	call	RepeatSetState
	mov	si, offset RepeatBlock:RepeatEndText
	call	RepeatSetState
	
	.leave
	ret
RepeatSetDurationExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatAddNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a repeating event to this calendar

CALLED BY:	UI (MSG_REPEAT_ADD_NOW)

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatAddNow	proc	far
	.enter

	; Verify the information; store Repeat Event if valid
	;
	sub	sp, size RepeatStruct		; allocate a repeat struct
	mov	bp, sp				; SS:BP points to the struct
	call	RepeatNewCommon			; attempt to create the Repeat
	jc	done				; if carry set, fail
	call	RepeatStore			; store the event
done:
	add	sp, size RepeatStruct		; clean up the stack

	.leave
	ret
RepeatAddNow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatChangeNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change a repeating event to a new type

CALLED BY:	UI (MSG_REPEAT_CHANGE_NOW)

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatChangeNow	proc	far
	.enter

	; Load & verify the Repeat Event data
	;
	sub	sp, size RepeatStruct		; allocate a repeat struct
	mov	bp, sp				; SS:BP points to the struct
	call	RepeatNewCommon			; attempt to create the Repeat
	jc	done				; if carry set, fail

	; Delete the existing Repeat Event. Store the new one
	;
	mov	ax, ds:[repeatChangeIndex]	; get existing ID
	call	RepeatModify			; modifiy existing event
done:
	add	sp, size RepeatStruct		; clean up the stack

	.leave
	ret
RepeatChangeNow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatNewCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new repeat struct based on the infromarion in the
		current RepeatBox (either Add or Change)

CALLED BY:	RepeatAddNow, RepeatChangeNow

PASS:		DS	= DGroup
		SS:BP	= RepeatStruct buffer

RETURN:		SS:BP	= Filled RepeatStruct
		DX	= Handle to event text
		CX	= Length of event text
		Carry	= Clear if valid
			= Set if invalid (no text handle in that case)

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

repeatCallTable	nptr.near \
		CreateWeekly,
		CreateMonthlyByDate,
		CreateMonthlyByDOW,
		CreateYearlyByDate,
		CreateYearlyByDOW

RepeatNewCommon	proc	near
	.enter

	; Some set up work, & initialize some instance data
	;
	mov	bx, ds:[repeatBlockHan]		; RepeatBlock handle to BX
	mov	al, ds:[curRepeatType]		; move the RepeatEventType
	mov	ss:[bp].RES_flags, mask EIF_REPEAT
	mov	ss:[bp].RES_type, al		; store the EventType
	mov	ss:[bp].RES_DOWFlags, 0		; no flags set
	mov	ss:[bp].RES_day, 1		; 1st day
	mov	ss:[bp].RES_month, 1		; January
	mov	ss:[bp].RES_DOW, 0		; Sunday
	mov	ss:[bp].RES_occur, 0		; First
	mov	ss:[bp].RES_startYear, LOW_YEAR - 1
	mov	ss:[bp].RES_endYear, HIGH_YEAR + 1
	mov	{word} ss:[bp].RES_startDay, -1
	mov	{word} ss:[bp].RES_endDay, -1

	; Now call the approriate creation routine
	;
	clr	ah				; turn into a word
	mov	si, ax				; enumerated type to SI
EC <	cmp	si, RepeatEventType		; bad enumerated type ??>
EC <	ERROR_GE	REPEAT_NEW_BAD_REPEAT_EVENT_TYPE		>
	sub	si, RET_WEEKLY			; make type zero-based
EC <	ERROR_L		REPEAT_NEW_BAD_REPEAT_EVENT_TYPE		>
	shl	si, 1				; double to word counter
	call	{word} cs:[repeatCallTable][si]	; call the handler
	jc	shortShortDone			; exit with carry set

	; First get the time, and store it if possible
	;
	mov	di, ds:[repeatBlockHan]		; RepeatBlock handle to DI
	mov	si, offset RepeatBlock:RepeatTimeText	; OD => DI:SI
	clr	cx				; allow no time
	call	StringToTime			; get the time, if any
	jc	shortShortDone			; if fail, we're done
	mov	{word} ss:[bp].RES_minute, cx	; store the time
	mov	ds:[repeatTime], cx		; store the time value

	; Now deal with the dates
	;
	push	bp				; save the structure
	mov	si, offset RepeatBlock:RepeatDurationList
	call	RepeatItemGroupGetSelection
	pop	bp				; restore the structure
	mov	di, bx				; RepeatBlock handle => DI
	cmp	ax, MSG_GEN_SET_NOT_ENABLED	; if "forever",
	je	getText				; then don't bother with dates
	mov	si, offset RepeatBlock:RepeatStartText	; OD => DI:SI
	call	StringToDate			; get the date
	jc	shortDone			; if fail, we're done
	mov	ss:[bp].RES_startYear, dx	; store the year
	mov	{word} ss:[bp].RES_startDay, cx	; store the month & day

	mov	si, offset RepeatBlock:RepeatEndText	; OD => DI:SI
	call	StringToDate			; get the date
shortShortDone:
	jc	shortDone			; if fail, we're done
	mov	bx, CAL_ERROR_REPEAT_DATES	; assume the worst
	cmp	dx, ss:[bp].RES_startYear	; compare last with start year
	jl	showError				; if less, failure!
	jg	datesOK				; if greater, always OK
	cmp	cx, {word} ss:[bp].RES_startDay	; if equal, check month & day
	jl	showError			; if less, failure
datesOK:
	mov	ss:[bp].RES_endYear, dx		; store the year
	mov	{word} ss:[bp].RES_endDay, cx	; store the month & day

	; Finally get the text
getText:
	push	bp				; save the RangeStruct
	mov	si, offset RepeatBlock:RepeatEventText	; OD => BX:SI
	clr	dx
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	call	ObjMessage_repeat_call		; get the event text
	pop	bp				; restore the RangeStruct
	mov	bx, cx				; handle of text => BX
	mov_tr	cx, ax				; text length => CX
	jcxz	badText				; nope, so display error
	call	VerifyVisibleString		; as long as we have at least
	jz	dismiss				; ...one visible character, OK

	; Else make this object the focus & target
badText:
	mov	ax, MSG_GEN_MAKE_FOCUS
	call	ObjMessage_repeat_send
	mov	ax, MSG_GEN_MAKE_TARGET
	call	ObjMessage_repeat_send
	mov	bx, CAL_ERROR_REPEAT_NOTEXT	; error message => BX
showError:
	mov	bp, bx				; error message => BP
	call	RepeatDisplayError		; display the error
shortDone:
	jmp	done

	; Dismiss the interaction, and store the Repeat event
dismiss:
	push	bx, cx				; save text handle, length
	mov	si, offset RepeatBlock:RepeatAddBox
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessage_repeat_send		; dismiss the sucker
	clc					; ensure the carry is clear
	pop	dx, cx				; restore text handle, length
done:
	.leave
	ret
RepeatNewCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		VerifyVisibleString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that at least one character in the passed string
		is visible (i.e. can be seen by the user)

CALLED BY:	GLOBAL

PASS:		BX	= Handle of text
		CX	= Length of text

RETURN:		Zero	= Set if at least one character is visible

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/12/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

VerifyVisibleString	proc	near
		uses	ax, cx, si, ds
		.enter
	;
	; Lock down the text block, and go through each character
	;
		call	MemLock
		mov	ds, ax
		clr	ax, si			; clear AH for SBCS
charLoop:
		LocalGetChar	ax, dssi
		call	LocalIsSpace
		jz	done
		loop	charLoop
done:	
		.leave
		ret
VerifyVisibleString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateWeekly
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create weekly events by filling in the appropriate info

CALLED BY:	RepeatAddNow

PASS:		SS:BP	= RepeatStruct
		BX	= RepeatBlock handle
		
RETURN:		Carry	= Set if bad input

DESTROYED:	AX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version
	Don	11/20/89	Tried again

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateWeekly	proc	near

	; Get all the DOW's invloved
	;
	push	bp
	mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
	mov	si, offset RepeatBlock:RepeatLongDOW
	call	ObjMessage_repeat_call		; selections => AL
	pop	bp

	; Do we have at least one day?  If so, store the data
	;
	tst	al				; check for no days
	je	fail
	mov	ss:[bp].RES_DOWFlags, al	; store the DOWFlag
	clc	
	ret

	; Display the error box
fail:
	mov	bp, CAL_ERROR_REPEAT_WEEKLY	; error message to display
	GOTO	RepeatDisplayError		; returns carry set
CreateWeekly	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMonthlyByDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the monthly events (by date)

CALLED BY:	RepeatAddNow

PASS:		SS:BP	= RepeatStruct
		BX	= RepeatBlock handle
		
RETURN:		Carry	= Set if input error

DESTROYED:	AX, CX, DX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version
	Don	11/21/89	Tried again

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateMonthlyByDate	proc	near

	; Get the date from the window
	;
	push	bp				; save the RepeatStruct
	mov	si, offset RepeatBlock:RepeatDateList
	call	RepeatItemGroupGetSelection	; selection => AX
	clr	dl
	cmp	ax, MSG_GEN_SET_NOT_ENABLED	; if "last", 
	je	storeValue			; then go store the value
	mov	si, offset RepeatBlock:RepeatDateValue
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjMessage_repeat_call		; value => DX
storeValue:
	pop	bp				; restore the RepeatStruct
	mov	ss:[bp].RES_day, dl		; store the date value
	clc					; ensure the carry is clear
	ret
CreateMonthlyByDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMonthlyByDOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the monthly events (by Day of Week)

CALLED BY:	RepeatAddNow

PASS:		SS:BP	= RepeatStruct
		BX	= RepeatBlock handle
		
RETURN:		Carry	= Clear

DESTROYED:	AX, CX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version
	Don	11/21/89	Tried again

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateMonthlyByDOW	proc	near

	; Get the correct day of week
	;
	mov	si, offset RepeatBlock:RepeatShortDOW
	call	RepeatCustomSpinGetIndex	; get the DOW
	mov	ss:[bp].RES_DOW, cl		; store the Day of Week

	; Now obtain the occurrence
	;
	mov	si, offset RepeatBlock:RepeatOccurrence
	call	RepeatCustomSpinGetIndex	; get the occur value
	mov	ss:[bp].RES_occur, cl		; store the occurrence
	clc
	ret
CreateMonthlyByDOW	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateYearlyByDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create yearly events (by date)

CALLED BY:	RepeatAddNow

PASS:		SS:BP	= RepeatStruct
		BX	= RepeatBlock handle
		
RETURN:		Carry	= Set if input error

DESTROYED:	AX, CX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/30/89	Initial version
	Don	11/21/89	Tried again

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateYearlyByDate	proc	near

	; Get the month and day values
	;
	call	CreateMonthlyByDate		; get the day
	jc	done
	mov	si, offset RepeatBlock:RepeatMonthValue
	call	RepeatCustomSpinGetIndex
	mov	ss:[bp].RES_month, cl		; store the month

	; Now check for legal day value
	;
	push	bp
	mov	bp, 1984			; this is a leap year...
	mov	dh, cl				; month => DH
	call	CalcDaysInMonth			; days in month => CH
	pop	bp				; restore RepeatStruct
	cmp	ch, ss:[bp].RES_day		; cannot exceed days in month
	jge	done				; if valid, we're OK
	mov	bp, CAL_ERROR_REPEAT_DATE_Y	; error message to display
	call	RepeatDisplayError		; returns carry set
done:
	ret
CreateYearlyByDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateYearlyByDOW
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates yearly events (by Day of Week)

CALLED BY:	RepeatAddNow

PASS:		SS:BP	= RepeatStruct
		BX	= RepeatBlock handle
		
RETURN:		CarrySet if input error

DESTROYED:	AX, CX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/25/89	Initial version
	Don	11/20/89	Tried again

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateYearlyByDOW	proc	near

	; Do everything the month does - except get a month
	;
	call	CreateMonthlyByDOW		; get the DOW & occurrence
	mov	si, offset RepeatBlock:RepeatMonthValue
	call	RepeatCustomSpinGetIndex
	mov	ss:[bp].RES_month, cl		; store the month
	clc
	ret	
CreateYearlyByDOW	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatDisplayError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the calendar error box

CALLED BY:	Repeat - GLOBAL

PASS:		BP	= CalErrorValue

RETURN:		Carry	= Set

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatDisplayError	proc	near

	call	GeodeGetProcessHandle		; get my process handle
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	clr	di
	call	ObjMessage			; send the message
	stc
	ret
RepeatDisplayError	endp



RepeatSetCustomSpinState	proc	near
	push	di
	clr	ch
	clr	bp
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	call	ObjMessage_repeat_send
	pop	di
	ret
RepeatSetCustomSpinState	endp

RepeatSetItemGroupSelection	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx				; determinate selection
	call	ObjMessage_repeat_send
	mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
	GOTO	ObjMessage_repeat_send
RepeatSetItemGroupSelection	endp

RepeatSetState	proc	near
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	FALL_THRU	ObjMessage_repeat_send
RepeatSetState	endp

ObjMessage_repeat_send	proc	near
	clr	di
omrCommon	label	near
	mov	bx, ds:[repeatBlockHan]		; OD => BX:SI
	call	ObjMessage
	ret
ObjMessage_repeat_send	endp


RepeatItemGroupGetSelection	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	GOTO	ObjMessage_repeat_call
RepeatItemGroupGetSelection	endp

RepeatCustomSpinGetIndex	proc	near
	push	dx, bp
	mov	ax, MSG_GEN_VALUE_GET_VALUE
	call	ObjMessage_repeat_call
	mov	cx, dx
	pop	dx, bp
	ret
RepeatCustomSpinGetIndex	endp		

ObjMessage_repeat_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES	
	GOTO	omrCommon
ObjMessage_repeat_call	endp

RepeatCode ends
