COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayEvent
FILE:		dayeventMain.asm

AUTHOR:		Don Reeves, July 23, 1989

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_DE_INIT_TODO	Initialize a DayEvent object to be a "To
				Do" list event. This is only called for a
				new (virgin) To Do list event.

    MTD MSG_DE_INIT_REPEAT_BY_GR_IT
				Initialize a DayEvent with a RepeatStruct,
				specified by event Gr:It.

    INT CalculateAlarmTimeFar	Calculate alarm time based on given time &
				precede values

    INT CalculateAlarmTime	Calculate alarm time based on given time &
				precede values

    INT CalculateAlarmTime	Calculate alarm time based on given time &
				precede values

    INT DayEventInvalidate	Invalidate the DayEvent

    INT DayEventMarkInvalid	Invalidate the DayEvent

    MTD MSG_DE_GET_END_DATE_TIME
				Get the end date and time for an event.

    INT DayEventParseEndTime	Parse the end time

    INT DayEventParseStartTime	Parse the start time

    INT StartTimeAfterEndTime	Takes care of end time stuff if start time
				is changed to a time after end time.

    INT StringToEndTime		Converts a string into time

    INT CalendarCheckDiskSpace	Same as FoamWarnForSaving, bug only gives
				warning dialog once.

    MTD MSG_DE_CHANGE_TYPE	Change my type (repeated <-> normal)

    INT ChangingToRepeatFar	Takes care of an event changing from normal
				or repeat to repeat.  If we're changing
				from normal to repeat we use RepeatStore.
				If we're changing from repeat to repeat, we
				use RepeatModify.

    INT ChangingToRepeat	Takes care of an event changing from normal
				or repeat to repeat.  If we're changing
				from normal to repeat we use RepeatStore.
				If we're changing from repeat to repeat, we
				use RepeatModify.

    INT CheckIfChangeToNormal	Checks if we're changing from a Repeat
				event back to a normal one-time event.

    INT NormalToRepeatCommon	Common work for changing a normal event
				into a repeated

    INT NormalToDaily		Change a normal event into repeated daily

    INT NormalToWeekly		change normal event into repeated weekly

    INT NormalToMonthly		change normal event into repeated monthly

    INT NormalToAnniversary	change normal event into repeated yearly

    INT NormalToBiweekly	normal to biweekly change

    INT NormalToWorkingDays	change normal event to daily repeated event

    MTD MSG_DE_SET_MEMO_TOKEN	Set the memo token

    MTD MSG_DE_ATTACH_MEMO	Attach a memo to an event

    INT DESetMemoData		Attach a memo to an event

    INT CheckIfOpenPossible	Checks if memo can be opened.  If not, a
				dialog explaining why not is displayed.  If
				memo was deleted in another app, the data
				structures are updated to reflect this.

    INT OpenMemo		Open memo to make sure it exists or isn't
				open elsewhere.

    INT CreateNewMemo		Creates a new memo for this event

    INT GetMemoString		Gets Memo prefix string (e.g. "Memo 12.30
				4.6.96").

    INT MemoNameArrayAdd	Adds a memo name/token to the MemoName
				chunk array.

    INT MemoNameArrayDeleteFar	Given a memo token, deletes the memo name
				array entry associated with this token.

    INT MemoNameArrayDelete	Given a memo token, deletes the memo name
				array entry associated with this token.

    INT MemoNameArrayFind	Returns the memo name given the memo token

    INT LockMemoNameArray	Returns locked memo name array

    INT StuffMemoInfo		Given the memo token & a buffer for
				DocumentInfo, this routine fills in the
				buffer with the DocumentInfo for the
				specific memo.

    INT GetNextMemoToken	Returns next memo token & increments
				memoToken variable.

    INT DeleteDayEventMemoStuffFar
				Updates the DayEvent object's memo token &
				deletes the MemoNameStruct in the memo name
				array associated with the token.

    INT DeleteDayEventMemoStuff	Updates the DayEvent object's memo token &
				deletes the MemoNameStruct in the memo name
				array associated with the token.

    INT ECValidateMemoToken	Verifies a memo token in within acceptable
				bounds.

    MTD MSG_DE_UPDATE_TIME	Update the time of an event, by parsing the
				current text & resetting the text if the
				time is invalid (after warning the user as
				appropriate). Does NOT affect the database.

    INT DESelectCommon		Perform the common work of selecting text

    INT EnsureEventViewIsTarget	Ensures that the EventView has the target

    INT StuffTimeString		Stuff the event time string

    INT StuffTimeStringFar	Stuff the event time string

    INT StuffTimeString		Stuff the event time string

    MTD MSG_DE_TODO_NUMBER	Numbers a To Do list event

    INT CreateToDoNumber	Creates the number for the events

    INT StuffTextStringFar	Set the initial event text

    INT StuffTextString		Set the initial event text

    INT ModifyTextObject	Adds/deletes
				ATTR_UNDERLINED_VIS_TEXT_NO_UNDERLINES
				vardata to/from DayEvent's text child
				depending on the what mode we are viewing
				events(narrow vs. wide). Also changes text
				objects focusable/selectable/editable
				status.

    INT StuffHeaderString	Create and stuff a header string (DOW MONTH
				DAY, YEAR)

    INT StuffTextUtility	Sets the text object dirty, stuffs the
				text, and sets it clean

    INT SetTextStyle		Set text style for a text object This is
				used to set/clr bold face

    MTD MSG_DE_SET_ALARM_FROM_TIME
				This is the alarm time change message we
				receive if we've changed the event time or
				date.

    INT EnsureAlarmTimeValid	Ensures the alarm time being set is valid.
				If its not, we turn the alarm off.

    INT ChangeToDoNewTrigger	Sets the "New" trigger in the To-do list
				enabled/disabled.

    MTD MSG_META_KBD_CHAR	Handle key characters

    INT ResponderHandleSpecialChars
				Handles Ctrl-N or Ctrl-P input by going to
				next/previous day in DayView.

    MTD MSG_MT_SET_MODIFICATION_FLAG
				sets modification flag

    MTD MSG_MT_GET_MODIFICATION_FLAG
				gets modification flag

    MTD MSG_DE_UPDATE_END_TIME	Contemplate new endtime

    INT DayEventCheckStringHasWhiteSpaceOnly
				return carry set if the string block passed
				in only contains white spaces

    INT InvalidEndTime		Deals with necessary actions for the user
				entering an invalid end time.

    MTD MSG_DE_UPDATE_START_TIME
				contemplate new start time

    INT InvalidStartTime	Takes all steps necessary when the user
				enters an invalid start time.

    INT CheckIfRepeatEventUpdate
				Determines if the event is a repeat event.
				If it is, then we must determine if we're
				updating a single event or the entire
				repeat chain.

    MTD MSG_DE_START_DIRTY	set start dirty flag

    MTD MSG_DE_END_DIRTY	set end dirty flag

    MTD MSG_DE_RESPONDER_UPDATE_DATE
				Update the date of a day event

    MTD MSG_DE_UPDATE_END_DATE	Update end date

    MTD MSG_DE_SET_END_DATE	Set an end date

    MTD MSG_DE_GET_RESERVED_DAYS
				Get the number of reserved days

    MTD MSG_DE_SET_RESERVED_DAYS
				Set the reserved days of an event

    MTD MSG_DE_SET_REPEAT_UNTIL_DATE
				Set the repeat-until day of the event.

    MTD MSG_DE_CLEAR_REPEAT_UNTIL_DATE
				Clear the repeat-until date of the event.

    INT PassNDays		Pass N days from current date

    MTD MSG_DE_SANITY_CHECK	check if data in this day event are valid

    INT DayEventUpdateIfNecessary
				Update either the time or event text, if
				necessary

    MTD MSG_META_FUP_KBD_CHAR	Swallow and TAB & CR characters that are
				sent to us, as we've already dealt with the
				characters as needed. This is to get around
				a bug in the text object where it FUP's the
				character after sending out
				MSG_META_TEXT_TAB_FILTERED, even though
				we've already intercepted & used that
				character,

    INT DayEventProcessShortcut	Process a keyboard shortcut

    INT ChangeDetailsDialogEventType
				If we're a repeat event changing to a
				normal event, we should change the Event
				Type in the Details dialog. (Responder
				Only)

    MTD MSG_DE_SELECT		Select or de-select this DayEvent

    MTD MSG_DE_DESELECT		Select or de-select this DayEvent

    INT DrawGreyHighlight	Changes wash color of time text object to
				show highlight if selected, or restore
				normal background if deselected.

    INT RedrawHyphenIfNecessary	sends MSG_VIS_DRAW to itself so that hyphen
				is redrawn

    INT DayEventSelectCommon	Call for re-draw

    MTD MSG_VIS_TEXT_SCROLL_ONE_LINE
				Scroll a single-line text object onto the
				screen

    GLB MouseOverIcon		Determine whether the mouse is over the
				bell's bounding box

    INT DayEventToggleAlarm	Toggle the alarm on/off

    INT DayEventRedrawIconFar	Redraw the DayEvent icon, whatever it may
				be

    INT DayEventRedrawIcon	Redraw the DayEvent icon, whatever it may
				be

    MTD MSG_DE_GET_REPEAT_TYPE	Get the frequency type for an
				event. (i.e. one-time, weekly, etc)

    MTD MSG_DE_REPLACE_TEXT	Replace the text of the event obj with text
				referenced by a pointer.

    MTD MSG_DE_GET_TEXT_ALL_PTR	Replace the text of the event obj with text
				referenced by a pointer.

    MTD MSG_DE_GET_STATE_FLAGS	Get the DEI_stateFlags of the event obj.

    MTD MSG_DE_SET_STATE_FLAGS	Set the DEI_stateFlags of the event obj.

    MTD MSG_DE_GET_ALARM	Get the alarm time for an event.

    MTD MSG_DE_USE_NEXT_BOOK_ID	Mark that the next book ID be used, and
				return that value.

    MTD MSG_DE_SET_NEXT_BOOK_ID	Set the next book ID

    MTD MSG_DE_ADD_SENT_TO_INFO	Add the sent-to information (with the name
				/ sms number / contact ID / book ID etc in
				instance data of CalendarAddressCtrlClass
				object.)

    INT LockChunkArrayFar

    INT LockChunkArray

    INT CreateEventSentToArray	Create a EventSentToStruct chunk array and
				add handle/chunk to instance data.

    MTD MSG_DE_ADD_SENDER_INFO	Create the sent-to chunk array, and put
				sender info into chunk array header.

    MTD MSG_DE_GET_SENT_TO_CHUNK_ARRAY
				Get the block / chunk handle of sent-to
				array.

    MTD MSG_DE_SET_SENT_TO_CHUNK_ARRAY
				Set the block / chunk handle of sent-to
				array.

    MTD MSG_DE_GET_SENT_TO_COUNT
				Get the count of sent-to struct in the
				sent-to array.

    MTD MSG_DE_UPDATE_APPOINTMENT_IF_NECESSARY
				Update the booking in sent-to list, if the
				event time/text is changed.

    MTD MSG_DE_CANCEL_ALL_APPOINTMENT
				Cancel all booking in sent-to list, if the
				user wants to.

    MTD MSG_DE_SET_END_TIME	Set the end time of the event obj.

    MTD MSG_DE_GET_UNIQUE_ID	Get the unique ID of the event obj.

    MTD MSG_DE_SET_UNIQUE_ID	Set the unique ID of the event obj.

    MTD MSG_DE_DUPLICATE_SAME_HOUR_EVENT
				Tell our DayPlan object to create a new
				event as us, but with the same hour as this
				one.

    MTD MSG_DE_GET_ALARM_PRECEDE_TIME
				Return the precede minutes of the event
				alarm.

    INT DayEventMarkBookingUpdateNecessary
				Change object flags to mark that booking
				update is necessary on the day event.

    INT ObjMessage_dayevent_send

    INT ObjMessage_dayevent_call

    INT ObjMessage_dayevent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/23/89		Initial revision
	Don	9/25/89		Major changes for "new" calendar
	Don	12/4/89		Use new class & method declarations
	
DESCRIPTION:
	Defines the main "DayEvent" procedures that operate on this class.
		
	$Id: dayeventMain.asm,v 1.1 97/04/04 14:47:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventFreeMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the two children text objects to free up as much
		memory as possible.

CALLED BY:	GLOBAL (MSG_DE_FREE_MEM)
	
PASS:		DS:DI	= DayEventClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventFreeMem	method	DayEventClass,	MSG_DE_FREE_MEM
	uses	cx, dx, bp
	.enter

	; First clean the time text
	;
	mov	si, ds:[di].DEI_timeHandle	; time object => DS:*SI
	mov	di, ds:[di].DEI_textHandle	; text object => DS:*DI
	clr	cx				; NULL terminated
	mov	dx, cs
	mov	bp, offset blankByte		; a null string => DX:BP
	call	StuffTextUtility		; stuff the text

	; Now clean the event text
	;
	mov	si, di				; text object => DS:*SI
	clr	cx				; NULL terminated
	mov	dx, cs
	mov	bp, offset blankByte		; a null string => DX:BP
	call	StuffTextUtility		; stuff the text

	.leave
	ret
DayEventFreeMem	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs a DayEvent with the time & event text

CALLED BY:	GLOBAL (MSG_DE_INIT)

PASS: 		DS:*SI	= DayEvent instance data
		CX	= Group # for EventStruct
		DX	= Item # for EventStruct

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/2/89		Initial version
	SS	3/19/95		To Do list changes
	RR	6/5/95		Variable length events for Resposder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventInit	method	DayEventClass, MSG_DE_INIT

	; Set up to stuff the EventStruct
	;
	mov	ax, cx
	mov	di, dx
	call	GP_DBLockDerefDI		; lock the EventStruct
	mov	bx, ds:[si]			; dereference the DayEvent
	add	bx, ds:[bx].DayEvent_offset	; DS:BX points at the DayEvent

	; Now stuff the time information
	;
	mov	cx, es:[di].ES_timeYear
	mov	ds:[bx].DEI_timeYear, cx	; copy the event year
	mov	cx, {word} es:[di].ES_timeDay
	mov	{word} ds:[bx].DEI_timeDay, cx	; copy the event M/D
	mov	cx, {word} es:[di].ES_timeMinute
	mov	{word} ds:[bx].DEI_timeMinute, cx ; copy the event time
	mov	cx, es:[di].ES_alarmYear
	mov	ds:[bx].DEI_alarmYear, cx	; copy the alarm year
	mov	cx, {word} es:[di].ES_alarmDay
	mov	{word} ds:[bx].DEI_alarmDay, cx	; copy the alarm M/D
	mov	cx, {word} es:[di].ES_alarmMinute
	mov	{word} ds:[bx].DEI_alarmMinute, cx ; copy the alarm time
if	END_TIMES
	mov	cx, {word} es:[di].ES_endTimeMinute
	mov	{word} ds:[bx].DEI_endMinute, cx   
	mov	cl, es:[di].ES_varFlags
	mov	ds:[bx].DEI_varFlags, cl
endif
if	UNIQUE_EVENT_ID
	mov	cx, es:[di].ES_uniqueID.high	; copy unique ID
	mov	ds:[bx].DEI_uniqueID.high, cx
	mov	cx, es:[di].ES_uniqueID.low
	mov	ds:[bx].DEI_uniqueID.low, cx
endif
	mov	cl, es:[di].ES_flags
	mov	ds:[bx].DEI_stateFlags, cl	; copy the flags
	mov	ds:[bx].DEI_actFlags, 0		; clear these flags
	mov	cx, es:[di].ES_repeatID
	mov	ds:[bx].DEI_repeatID, cx	; copy the repeat ID
if	HANDLE_MAILBOX_MSG
	mov	cx, es:[di].ES_sentToArrayBlock  ; copy the sent-to info
	mov	ds:[bx].DEI_sentToArrayBlock, cx
	mov	cx, es:[di].ES_sentToArrayChunk
	mov	ds:[bx].DEI_sentToArrayChunk, cx
	mov	cx, es:[di].ES_nextBookID
	mov	ds:[bx].DEI_nextBookID, cx
endif
	mov	ds:[bx].DEI_DBitem, dx		; copy the item #
	mov	ds:[bx].DEI_DBgroup, ax		; copy the group #
	call	DBUnlock			; unlock the EventStruct

	; Set the event time & the event text
	;
	call	DayEventInvalidate
	call	StuffTimeString
	call	StuffTextString
	ret
DayEventInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventInitVirgin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a virgin DayEvent

CALLED BY:	GLOBAL (MSG_DE_INIT_VIRIGN)

		UNIQUE_EVENT_ID: (MSG_DE_INIT_VIRGIN_PRESERVE_UNIQUE_ID)
		Preserves unique ID in the dayevent object.

PASS:		ES	= DGroup
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		CX	= Time or
			(_RESPONDER+CALAPI features only)
			CAL_NO_TIME if this is a same day to-do event
		DX	= Month/Day
		BP	= Year

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/13/89	Initial version
	sean	3/19/95		To Do list changes
	RR	6/5/95		Variable length events for Responder
	RR	8/8/95		clear memo flags for responder
	simon	2/12/97		Allow CAL_NO_TIME to be passed in to declare
				a same-day to-do event

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if UNIQUE_EVENT_ID
DayEventInitVirgin	method	DayEventClass,	MSG_DE_INIT_VIRGIN,
				MSG_DE_INIT_VIRGIN_PRESERVE_UNIQUE_ID
else
DayEventInitVirgin	method	DayEventClass,	MSG_DE_INIT_VIRGIN
endif
	;
	; Now set up the limited instance data
	;
        mov     ds:[di].DEI_timeYear, bp
        mov     {word} ds:[di].DEI_timeDay, dx

		
        mov     {word} ds:[di].DEI_timeMinute, cx
if      END_TIMES
        mov     {word} ds:[di].DEI_endMinute, 0
        mov     ds:[di].DEI_varFlags, VL_START_TIME
endif


	mov	ds:[di].DEI_stateFlags, mask EIF_NORMAL
	mov	ds:[di].DEI_actFlags, DE_VIRGIN
	mov	ds:[di].DEI_repeatID, 0		; copy the repeat ID
	mov	ds:[di].DEI_DBgroup, 0
	mov	ds:[di].DEI_DBitem, 0	
if	UNIQUE_EVENT_ID
	;
	; If told to preserve unique ID, do so.
	;
	cmp	ax, MSG_DE_INIT_VIRGIN_PRESERVE_UNIQUE_ID
	je	skipID
	movdw	ds:[di].DEI_uniqueID, INVALID_EVENT_ID
skipID:
endif

if	HANDLE_MAILBOX_MSG
	clr	ds:[di].DEI_sentToArrayBlock
	clr	ds:[di].DEI_sentToArrayChunk
	clr	ds:[di].DEI_nextBookID
endif
	;
	; Calculate the alarm time
	;
	call	CalculateAlarmTime
	mov	ds:[di].DEI_alarmYear, bp
	mov	{word} ds:[di].DEI_alarmDay, dx
	mov	{word} ds:[di].DEI_alarmMinute, cx

	;
	; Set up the visible stuff
	;
	call	DayEventInvalidate
	call	StuffTimeString
	call	StuffTextString	
	ret
DayEventInitVirgin	endp


if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DEInitTodo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a DayEvent object to be a "To Do" list 
		event. This is only called for a new (virgin) To
		Do list event.

CALLED BY:	MSG_DE_INIT_TODO

PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cl	= priority:
			TODO_NORMAL_PRIORITY
			TODO_HIGH_PRIORITY

			(_RESPONDER and CALAPI only:)
			TODO_COMPLETED

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/ 8/95   	Initial version
	sean	12/6/95		End time changes
	simon	2/12/97		Allow TODO_COMPLETED to be passed in

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DEInitTodo	method dynamic DayEventClass, 
					MSG_DE_INIT_TODO
	.enter

	mov	ds:[di].DEI_timeYear, TODO_DUMMY_YEAR
	mov	{word} ds:[di].DEI_timeDay, TODO_DUMMY_MONTH_DAY
	mov	ch, TODO_DUMMY_HOUR


	mov	{word} ds:[di].DEI_timeMinute, cx
	mov	ds:[di].DEI_stateFlags, mask EIF_TODO	; a "To Do" event
	mov	ds:[di].DEI_actFlags, DE_VIRGIN		; event is new 
	mov	ds:[di].DEI_repeatID, 0
	mov	ds:[di].DEI_DBgroup, 0
	mov	ds:[di].DEI_DBitem, 0	

	mov	ds:[di].DEI_alarmYear, 0
	mov	{word} ds:[di].DEI_alarmDay, 0
	mov	ds:[di].DEI_alarmHour, 0

	mov	ds:[di].DEI_alarmMinute, TODO_NOT_COMPLETED

	mov	ds:[di].DEI_memoToken, NO_MEMO_TOKEN
	mov	ds:[di].DEI_varFlags, VL_START_TIME
	mov	{word} ds:[di].DEI_endMinute, 0

	;
	; Set up the visible stuff
	;
	call	DayEventInvalidate
	call	StuffTimeString
	call	StuffTextString	

	.leave
	ret
DEInitTodo	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventInitHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a header event

CALLED BY:	GLOBAL (MSG_DE_INIT_HEADER)

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		ES	= DGroup
		BP	= Year
		DX	= Month/Day

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventInitHeader	method	DayEventClass,	MSG_DE_INIT_HEADER
	.enter

	; Now set up the limited instance data
	;
	clr	ax				; zero => AX
	mov	ds:[di].DEI_timeYear, bp
	mov	{word} ds:[di].DEI_timeDay, dx
	mov	{word} ds:[di].DEI_timeMinute, ax
	mov	ds:[di].DEI_stateFlags, mask EIF_HEADER
	mov	ds:[di].DEI_actFlags, DE_VIRGIN
	mov	ds:[di].DEI_repeatID, ax
	mov	ds:[di].DEI_DBgroup, ax
	mov	ds:[di].DEI_DBitem, ax
	mov	ds:[di].DEI_alarmYear, ax
	mov	{word} ds:[di].DEI_alarmDay, ax
	mov	{word} ds:[di].DEI_alarmMinute, ax

	; Set up the visible stuff
	;
	push	dx, bp				; save the date values
	call	DayEventInvalidate
	pop	dx, bp				; restore the date values
	call	StuffHeaderString		; create & stuff the string

	.leave
	ret
DayEventInitHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventInitRepeat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a Repeating event

CALLED BY:	GLOBAL (MSG_DE_INIT_REPEAT)

PASS:		ES	= DGroup
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		CX	= Offset in EventTable
		DX	= EventTable handle

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/28/89	Initial version
	RR	8/8/95		Clear memo flag for responder, var length flags

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventInitRepeat	method	DayEventClass,	MSG_DE_INIT_REPEAT

	; Some setup work
	;
	mov	bp, di				; DS:BP => DayEventInstance 
	mov	bx, dx				; EventTable to bx
	mov	bx, ds:[bx]			; dereference the handle
	add	bx, cx				; go to my entry

	; Get information from the RepeatStruct
	;
	push	es				; save DGroup
	mov	ax, ds:[bx].ETE_group
	mov	di, ds:[bx].ETE_item
	mov	ds:[bp].DEI_DBgroup, ax		; store masked group #
	mov	ds:[bp].DEI_DBitem, di		; store the item #
	and	ax, not REPEAT_MASK		; clear the mask bit
	call	GP_DBLockDerefDI		; lock the RepeatStruct
	mov	cl, es:[di].RES_flags
	mov	ds:[bp].DEI_stateFlags, cl	; copy the state flags
	mov	ds:[bp].DEI_actFlags, 0		; clear the action flags
	mov	cx, es:[di].RES_ID
	mov	ds:[bp].DEI_repeatID, cx	; save the repeat ID
if	END_TIMES
	mov	cx, {word} es:[di].RES_endMinute
	mov	{word} ds:[bp].DEI_endMinute, cx   
	mov	cl, es:[di].RES_varFlags
	mov	ds:[bp].DEI_varFlags, cl
endif
if	UNIQUE_EVENT_ID
	mov	cx, es:[di].RES_uniqueID.high	; copy unique ID
	mov	ds:[bp].DEI_uniqueID.high, cx
	mov	cx, es:[di].RES_uniqueID.low
	mov	ds:[bp].DEI_uniqueID.low, cx
endif
if	HANDLE_MAILBOX_MSG
	mov	cx, es:[di].RES_sentToArrayBlock ; copy sent-to info
	mov	ds:[bp].DEI_sentToArrayBlock, cx
	mov	cx, es:[di].RES_sentToArrayChunk
	mov	ds:[bp].DEI_sentToArrayChunk, cx
	mov	cx, es:[di].RES_nextBookID
	mov	ds:[bp].DEI_nextBookID, cx
endif
	call	DBUnlock			; unlock the RepeatStruct
	pop	es				; restore DGroup

	; Set up the time information
	;
	mov	di, bp
	mov	bp, ds:[bx].ETE_year
	mov	ds:[di].DEI_timeYear, bp	; copy the event year
	mov	dx, {word} ds:[bx].ETE_day
	mov	{word} ds:[di].DEI_timeDay, dx	; copy the event M/D
	mov	cx, {word} ds:[bx].ETE_minute
	mov	{word} ds:[di].DEI_timeMinute, cx ; copy the event time
	call	CalculateAlarmTime		; calculate the alarm stuff
	mov	ds:[di].DEI_alarmYear, bp
	mov	{word} ds:[di].DEI_alarmDay, dx
	mov	{word} ds:[di].DEI_alarmMinute, cx

	; Set up the visible stuff
	;
	call	DayEventInvalidate
	call	StuffTimeString
	call	StuffTextString	
	ret
DayEventInitRepeat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		DayEventInitRepeatByGrIt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize a DayEvent with a RepeatStruct, specified
		by event Gr:It.

CALLED BY:	MSG_DE_INIT_REPEAT_BY_GR_IT
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cx:dx	= RepeatStruct Gr:It
RETURN:		carry set if error (not enough memory)
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Allocate an EventTableEntry in DPResource block,
		ie. current block.
		Fill in the entry.
		call MSG_DE_INIT_REPEAT.
		Free the block.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/24/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventInitRepeatByGrIt	method dynamic DayEventClass, 
					MSG_DE_INIT_REPEAT_BY_GR_IT
		.enter
		Assert	bitSet, cx, REPEAT_MASK
	;
	; Allocate a chunk of size EventTableEntry in DPResource.
	;
		push	cx
		mov	al, mask OCF_IGNORE_DIRTY
		mov	cx, size EventTableEntry
		call	LMemAlloc		; ax <- chunk handle,
						;  ds/es fixup'ed,
						;  carry set if error
		mov_tr	bx, ax
		pop	ax
		jc	quit
	;
	; Reference the EventTableEntry.
	;
		mov	bp, ds:[bx]		; ds:bp <- EventTableEntry
	;
	; Lock down the DB item.
	;
		andnf	ax, not REPEAT_MASK
		mov	di, dx			; ax:di <- Gr/It
		call	GP_DBLockDerefDI	; es:di <- RepeatStruct
	;
	; Copy DB info to EventTableEntry. We can ignore ETE_size.
	;
		; time
		movm	ds:[bp].ETE_year, es:[di].RES_startYear, cx
		mov	cx, {word} es:[di].RES_startDay
		mov	{word} ds:[bp].ETE_day, cx
		mov	cx, {word} es:[di].RES_minute
		mov	{word} ds:[bp].ETE_minute, cx

		; db info
		ornf	ax, REPEAT_MASK
		mov	ds:[bp].ETE_group, ax
		mov	ds:[bp].ETE_item, dx

		; repeat id
		movm	ds:[bp].ETE_repeatID, es:[di].RES_ID, cx

		; day event handle
		mov	ds:[bp].ETE_handle, si
	;
	; Unlock db item.
	;
		; es == segment
		Assert	segment, es
		call	DBUnlock		; es destroyed
	;
	; Call MSG_DE_INIT_REPEAT.
	;
		clr	cx
		mov	dx, bx			; dx <- handle
		mov	ax, MSG_DE_INIT_REPEAT
		call	ObjCallInstanceNoLock	; ax, cx, dx, bp destroyed
	;
	; Free EventTableEntry chunk.
	;
		mov_tr	ax, bx			; ax <- handle
		call	LMemFree

		clc				; no error!
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
DayEventInitRepeatByGrIt	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalculateAlarmTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate alarm time based on given time & precede values

CALLED BY:	DayEventInitVirgin

PASS:		ES	= DGroup
		BP	= Year
		DX	= Month/Day
		CX	= Hour/Minute

RETURN:		BP	= Alarm year
		DX	= Alarm month/day
		CX	= Alarm hour/minute

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		No of days of the alarm preceding the event cannot exceed
		255 days

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if HANDLE_MAILBOX_MSG
CalculateAlarmTimeFar	proc	far
	call	CalculateAlarmTime
	ret
CalculateAlarmTimeFar	endp
endif


CalculateAlarmTime	proc	near
	uses	ax
	.enter

	cmp	cx, -1				; check the time
	jne	calcAlarmTime
	clr	cx				; else alarm in 12:00 am
	jmp	done

	; Set up the alarm time
	;
calcAlarmTime:
	clr	ax				; clear counter
	sub	cl, es:[precedeMinute]		; change the minutes
	jge	hour				; if non-negative, jump
	add	cl, 60				; else adjust
	dec	ch
	jge	hour
	add	ch, 24
	dec	ax				; go back one day
hour:
	sub	ch, es:[precedeHour]
	jge	monthDayYear
	add	ch, 24
	dec	ax				; go back another day

	; Now handle the date
	;
monthDayYear:
	sub	ax, es:[precedeDay]		; go bac more days
	je	done				; if AX is 0, we're done
	xchg	cx, ax				; exchange time & day offset
	call	CalcDateAltered			; calculate the data
	mov	cx, ax				; restore time to CX
done:
	.leave
	ret
CalculateAlarmTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventInvalidate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the DayEvent

CALLED BY:	DayEventInit, DayEventInitVirgin

PASS:		DS:*SI	= DayEvent instance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EDITABLE_AND_SELECTABLE	= (mask VTS_EDITABLE) or (mask VTS_SELECTABLE)

DayEventInvalidate	proc	near
	class	DayEventClass
	uses	si
	.enter

	; Some set-up work. Assume we are a header
	;
	mov	bp, ds:[si]			; dereference handle
	mov	di, bp
	add	di, ds:[di].DayEvent_offset	; access my data
	mov	ax, (not (EDITABLE_AND_SELECTABLE)) shl 8
	mov	bx, mask VTDCA_UNDERLINE	; char attrs to set
	clr	cx				; char attrs to clear
	mov	dx, J_LEFT shl offset VTDPA_JUSTIFICATION
	
	; If we are printing, do some odd things
	;
	cmp	ds:[bp].offset, offset PrintEventClass
	je	printEvent			; deal with printing

	; If we are not a header, then we are editable and selectable
	;
	test	ds:[di].DEI_stateFlags, mask EIF_HEADER
	jnz	eventText
	xchg	bx, cx				; swap char attr set & clear
	mov	al, EDITABLE_AND_SELECTABLE	; editable & selectable
	mov	dx, J_RIGHT shl offset VTDPA_JUSTIFICATION

	; Work on the event text object
eventText:
	push	ds:[di].DEI_timeHandle
	mov	si, ds:[di].DEI_textHandle
	call	DayEventMarkInvalid

	; Work on the time text object
	;
	pop	si				
	call	DayEventMarkInvalid

	; Set/clear any necessary style bits
	;
	not	cx				; not clear bits
	and	ds:[di].VTI_charAttrRuns, cx	; clear style bits
	or	ds:[di].VTI_charAttrRuns, bx	; set style bits
	and	ds:[di].VTI_paraAttrRuns, not mask VTDPA_JUSTIFICATION
	or	ds:[di].VTI_paraAttrRuns, dx
	and	ds:[di].VTI_filters, not mask VTF_FILTER_CLASS
	cmp	dx, J_RIGHT shl offset VTDPA_JUSTIFICATION
	jne	done
	or	ds:[di].VTI_filters, VTFC_TIME shl offset VTF_FILTER_CLASS
done:
	.leave
	ret

	; We are printing, so do some interesting things
printEvent:
	or	bx, mask VTDCA_BOLD
	test	ds:[di].DEI_stateFlags, mask EIF_HEADER
	jnz	eventText			; if header, we're done
	xchg	bx, cx				; swap char attr set & clear
	test	ds:[di].PEI_printInfo, mask PEI_IN_DATE
	jnz	eventText			; if in a date, do nothing
	mov	dx, J_RIGHT shl offset VTDPA_JUSTIFICATION
	jmp	eventText			; else right-justify time
DayEventInvalidate	endp

DayEventMarkInvalid	proc	near
	uses	cx, dx
	.enter

	; We need to clear VOF_WINDOW_INVALID to ensure that the
	; object & its parent will receive a MSG_VIS_OPEN. It
	; is possible this bit was left set from when the DayEvent
	; was last used, if it were invalidated and then removed
	; from the visual tree before the update arrived. -Don 2/29/96

	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Vis_offset		; access visual information
	ornf	ds:[di].VI_optFlags, mask VOF_GEOMETRY_INVALID
	andnf	ds:[di].VI_optFlags, not (mask VOF_WINDOW_INVALID)
	and	ds:[di].VTI_state, ah
	or	ds:[di].VTI_state, al
	mov	cl, mask VOF_WINDOW_INVALID
	mov	dl, VUM_DELAYED_VIA_APP_QUEUE
	call	VisMarkInvalid			; the event time

	.leave
	ret
DayEventMarkInvalid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the event time of the DayEvent

CALLED BY:	GLOBAL (MSG_DE_SET_TIME)

PASS:		DS:DI	= DayEventClass specific instance data
		DS:*SI	= DayEventClass instance data
		ES	= DGroup
		CX	= New hour/minute

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version
	Don	1/6/89		Gets time string from display
	Don	10/14/94	Reset selection, to ensure fully visible
	SS	3/19/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSetTime	method	DayEventClass, MSG_DE_SET_TIME

RSP <	msg	local	word	push	ax				>
	uses	cx, dx
	.enter

RSP <	push	bp							>
RSP <	call	CalculateAlarmPrecedeTimeFar	; ax = alarm precede minute>

	; Store the time, clear dirty bit, and calculate alarm time
	;
	and	ds:[di].DEI_actFlags, not DE_TIME_DIRTY

	; on responder this routine may affect VLF_START_TIME flag, so
	; we go ahead and update time even if it is the same as before
	;
NRSP <	cmp	{word} ds:[di].DEI_timeMinute, cx ; compare old & new times>
NRSP <	je	reStuff				  ; if the same, exit	>
	mov	{word} ds:[di].DEI_timeMinute, cx ; store the hour and minute

	; Test whether we want to update flag
	;
RSP <	cmp	msg, MSG_DE_SET_TIME_NO_FLAG				>

	mov	dx, {word} ds:[di].DEI_timeDay	; month & day => DX
	mov	bp, {word} ds:[di].DEI_timeYear	; year => BP


TODO <	test	ds:[di].DEI_stateFlags, mask EIF_TODO	; To Do event ? >
TODO  <	jnz	noAlarm					; no alarm stuff >
	push	cx				; save the time
	call	CalculateAlarmTime		; time => CX:DX:BP
	mov	ax, MSG_DE_SET_ALARM
	call	ObjCallInstanceNoLock		; set the alarm time
	pop	cx				; restore the time
noAlarm::

	; Notify the DayPlan of the new time
	;
	mov	ax, MSG_DP_ETE_TIME_NOTIFY
	mov	bp, si				; my handle => BP
	mov	si, offset DPResource:DayPlanObject
	call	ObjCallInstanceNoLock
	mov	si, bp				; DayEvent handle => SI

	; Stuff the time string back into the time text object, and
	; then ensure that the text is not scrolled out of view. Due
	; to the code in TextCallShowSelection, we need to ensure that
	; the object is not marked as "targetable" during this update
	; (or else no scrolling will occur). It's a hack :)
NRSP < reStuff:								>
	call	StuffTimeString			; re-stuff the string
	mov	ax, MSG_VIS_TEXT_SELECT_START
	mov	si, di				; text object => *DS:SI
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VTI_state, not (mask VTS_TARGETABLE)
	call	ObjCallInstanceNoLock
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VTI_state, mask VTS_TARGETABLE

RSP <	pop	bp							>
	.leave	
	ret
DayEventSetTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetDMY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Hack to allow virgin DayEvent's to change their day/month/year
		while not coming off of the screen or being updated

CALLED BY:	GLOBAL
	
PASS:		DS:DI	= DayEventClass specific instance data
		BP	= Year
		DX	= Month/Day

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSetDMY	method	DayEventClass,	MSG_DE_SET_DMY
	uses	cx, dx, bp
	.enter

EC <	test	ds:[di].DEI_actFlags, DE_VIRGIN	; am I a virgin ??	>
EC <	ERROR_Z	DE_SET_DMY_NOT_VIRGIN		; I'd better be!	>
	mov	ds:[di].DEI_timeYear, bp
	mov	{word} ds:[di].DEI_timeDay, dx
	mov	cx, {word} ds:[di].DEI_timeMinute
	call	CalculateAlarmTime		; time => CX:DX:BP
	mov	ds:[di].DEI_alarmYear, bp
	mov	{word} ds:[di].DEI_alarmDay, dx
	mov	{word} ds:[di].DEI_alarmMinute, cx
	
	.leave
	ret
DayEventSetDMY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the time information for a day event

CALLED BY:	DayPlanAddEvent (MSG_DE_GET_TIME)

PASS:		DS:DI	= DayEventClass specific instance data

RETURN:		BP	= Year
		DH	= Month
		DL	= Day
		CH	= Hour
		CL	= Minute

		(RESPONDER and CALAPI only)
		carry set if no start time

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/27/89		Initial version
	simon	2/12/97		Return carry set if no start time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventGetTime	method	DayEventClass, MSG_DE_GET_TIME
	mov	cx, {word} ds:[di].DEI_timeMinute
	mov	dx, {word} ds:[di].DEI_timeDay
	mov	bp, ds:[di].DEI_timeYear


	ret
DayEventGetTime	endp

if END_TIMES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get theend  time information for a day event

CALLED BY:	DayPlanAddEvent (MSG_DE_GET_END_TIME)

PASS:		DS:DI	= DayEventClass specific instance data

RETURN:		CH	= Hour
		CL	= Minute
		carry	  set iff no endtime

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RR	5/31/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventGetEndTime	method	DayEventClass, MSG_DE_GET_END_TIME
	mov	cx, {word} ds:[di].DEI_endMinute
	test	ds:[di].DEI_varFlags, VL_END_TIME
	clc					; assume we have end time
	jnz	done

	stc					; ain't no end time
done:
	ret
DayEventGetEndTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetEndDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the end date and time for an event.

CALLED BY:	MSG_DE_GET_END_DATE_TIME
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		if has end date:
			bp	= year
			dx	= month/day
			cx	= hour/min, CAL_NO_TIME if no time
			carry	= cleared
		if no end date and no end time
			carry	= set
			cx, dx, bp = destroyed
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if (has end date and end time) {
			return them
		}
		if (has end time but no date) {
			return end time and start date
		}
		if (has end date but no time) {
			return end date, and -1 for end time
		}
		else {
			return carry set
		}
		
REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/16/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayEventGetEndDateTime	method dynamic DayEventClass, 
					MSG_DE_GET_END_DATE_TIME
		.enter
	;
	; Assume we return start year month day.
	;
		mov	dx, {word} ds:[di].DEI_timeDay
		mov	bp, ds:[di].DEI_timeYear
	;
	; Any end date?
	;
		test	ds:[di].DEI_varFlags, VL_END_DATE
		jz	noDate
	;
	; Return date.
	;
		mov	dx, {word} ds:[di].DEI_endDay
		mov	bp, ds:[di].DEI_endYear
noDate:
	;
	; Any time?
	;
		mov	cx, {word} ds:[di].DEI_endMinute
		test	ds:[di].DEI_varFlags, VL_END_TIME
		clc					; no error
		jnz	done
	;
	; No time. Do we have end date again?
	;
		mov	cx, CAL_NO_TIME
		test	ds:[di].DEI_varFlags, VL_END_DATE
		clc					; no error
		jnz	done
	;
	; No time, and no date. Return carry set.
	;
		stc
done:
		.leave
		Destroy	ax
		ret
DayEventGetEndDateTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventParseEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the end time

CALLED BY:	DEUpdateEndTime

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		cx	= block handle of text
		dx	= lenght of text

RETURN:		carry set--end time invalid
		  cx:dx = optr to string for error note
		carry clear--end time valid
		  cx 	= hour/minute of end time

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RR	6/2/95		Initial version
	sean	12/7/95		Changed to use FoamDisplayErrorNoBlock
	sean	12/13/95	Major overhaul

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventParseEndTime	proc near
	uses	di, si
	.enter

	; Get the time string
	;
	mov	bp, si				; DayEvent handle => DI
	mov	bx, cx
	mov	cx, dx
	clr	dx				; allow no time
	call	StringToEndTime			; parse the string
	jc	badFormat

	; Check if the text was empty
	;
	cmp	cx, -1				; empty text ?
	je	emptyEndTime

	; Check if end time is before start time
	;
	mov	di, ds:[bp]			; deref day event
	add	di, ds:[di].DayEvent_offset

	; if end date is set, end time doesn't have to be checked
	;
	test	ds:[di].DEI_varFlags, VL_WHOLE_DAY_RES
	jnz	doCheck
	test	ds:[di].DEI_varFlags, VL_END_DATE
	jnz	skipCheck
doCheck:	
	cmp	cx, {word} ds:[di].DEI_timeMinute 
	jle	endTimeBeforeStartTime
skipCheck:
	; Store new end time in DayEvent
	;
	mov	{word} ds:[di].DEI_endMinute, cx
	clc					; valid end time
done:
	.leave
	ret

emptyEndTime:
	clr	cx
	clc
	jmp	done

badFormat:
	GetResourceHandleNS	BadEndTimeText, cx
	mov	dx, offset	BadEndTimeText
	stc					; invalid end time
	jmp	done

endTimeBeforeStartTime:
	GetResourceHandleNS	EarlyEndTimeText, cx
	mov	dx, offset	EarlyEndTimeText
	stc					; invalid end time
	jmp	done				
	
DayEventParseEndTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventParseStartTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the start time

CALLED BY:	DEUpdateStarttime

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		cx	= block handle of text
		dx	= lenght of text

RETURN:		CX	= Hour/Minute
		Carry	= Set if time invalid.

DESTROYED:	AX, BX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		*Note*--If start time is after end time, event
		end time is modified in here & an error note
		is posted.  Look at StartTimeAfterEndTime().

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RR	6/2/95		Initial version
	sean	12/7/95		Major clean-up

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventParseStartTime	proc near
	uses	di, si
	.enter

	; Get the time string & parse it.
	;
	mov	bp, si				; DayEvent handle => bp
	mov	bx, cx
	mov	cx, dx
	mov	dx, 1				; empty time not allowed
	call	StringToEndTime			; parse the string
	jc	exit			

	; Check that the start time we're changing to is
	; before the end time(if there is an end time).
	;
	mov	si, bp				; *ds:si = DayEvent obj
	mov	di, ds:[si]			; deref day event
	add	di, ds:[di].DayEvent_offset
	test	ds:[di].DEI_varFlags, VL_END_TIME 	; no end time -> before
	jz	setTime
	test	ds:[di].DEI_varFlags, VL_END_DATE	; any end time is valid
	jnz	setTime	
	cmp	cx, {word} ds:[di].DEI_endMinute	
	jge	afterEndTime

setTime:
	mov	ax, MSG_DE_SET_TIME		; set new time
	call	ObjCallInstanceNoLock
	clc					; time accepted
exit:
	.leave
	ret

afterEndTime:
	call	StartTimeAfterEndTime
	jmp	setTime				; time still accepted

DayEventParseStartTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartTimeAfterEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes care of end time stuff if start time is changed
		to a time after end time.

CALLED BY:	DayEventParseStartTime

PASS:		*ds:si	= DayEvent object
		ds:di	= DayEventInstance

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Dirty DayEvent end time
		Display error note
		Clear end time in end time text
		Update DayEvent

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	12/ 7/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StartTimeAfterEndTime	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Dirty end time
	; 
	push	si				; save DayEvent object
	or	ds:[di].DEI_varFlags, VL_END_DIRTY	

	; Make sure interaction stays visible.  User may
	; have pressed "Close" trigger.
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	EventOptionsTopInteraction, bx
	mov	si, offset	EventOptionsTopInteraction
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; Clear end time text in "Details" dialog & give focus to
	; the end time text object.
	;
	mov	ax, MSG_VIS_TEXT_DELETE_ALL	; no end time
	mov	di, mask MF_FIXUP_DS or\
		    mask MF_CALL
	GetResourceHandleNS	EOEndingTime, bx
	mov	si, offset 	EOEndingTime
	call	ObjMessage

	mov	ax, MSG_GEN_MAKE_FOCUS
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage

	; Now update DayEvent end time.  This must be done after
	; clearing the EOEndingTime text.  Otherwise, the update
	; won't clear the end time for the day event.
	;
	pop	si			; restore DayEvent object
	mov	ax, MSG_DE_UPDATE_END_TIME
	call	ObjCallInstanceNoLock

	; Display error note
	;
	GetResourceHandleNS	LateStartTimeText, cx
	mov	dx, offset	LateStartTimeText
	call	FoamDisplayErrorNoBlock

	; If memo viewer is open--close it.  
	;
	mov	ax, MSG_CALENDAR_CLOSE_MEMO_VIEWER 
	GetResourceHandleNS	Calendar, bx
	mov	si, offset	Calendar
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	.leave
	ret
StartTimeAfterEndTime	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StringToEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Converts a string into time

CALLED BY:	DayEventParseEndTime

PASS: 		bx	= Block of text
		cx	= Length
		DX	= 0 to allow no time
			<>  to force time text

RETURN:		CH	= Hours
		CL	= Minutes
		Carry	= Set if not a number

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Must be called from the Calendar thread!
		Note: if CX is returned with -1, no time string was provided.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/21/89	Initial version
	sean	3/13/96		Changed to return carry on error
				like it's supposed to

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StringToEndTime	proc	far
	uses	ax, bx, dx, di, bp, es
	.enter

	; Get the text
	;
	push	bx, dx				; save the flag

	; Now parse the text
	;
	call	ParseTime			; parse the time
	pop	bx, di				; restore obj handle, time flag
	jc	fail				; jump if parse errors
	tst	di				; allow no time ??
	jz	done				; yes, so all times are OK
	cmp	cx, -1				; do we have empty time??
	je	fail
	clc					; clear the carry flag
done:
	.leave
	ret 

fail:
	stc
	jmp	done

StringToEndTime	endp
endif		; if END_TIMES




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventParseTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Parse the DayEvent time

CALLED BY:	GLOBAL (MSG_DE_PARSE_TIME)

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data

RETURN:		CX	= Hour/Minute
		Carry	= Set if time is was reverted, else clear

DESTROYED:	AX, BX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/29/90		Initial version
	Don	8/12/90		Preserve systemStatus flags

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventParseTime	method	DayEventClass,	MSG_DE_PARSE_TIME
	.enter

	; Get the time string
	;
	mov	al, es:[systemStatus]		; SystemFlags => AL
	and	es:[systemStatus], not SF_DISPLAY_ERRORS
	mov	bp, si				; DayEvent handle => DI
	mov	dx, {word} ds:[di].DEI_timeMinute	; old time => DX
	mov	si, ds:[di].DEI_timeHandle	; get time handle
	mov	di, ds:[LMBH_handle]		; OD => DI:SI
	clr	cx				; allow no time
	call	StringToTime			; parse the string
	mov	es:[systemStatus], al		; restore the SystemFlags
	jnc	done				; if valid time, done

	; Else must display the error box
	;
	push	dx				; save the old time
	mov	cx, dx				; old time => CX
	sub	sp, TIME_BUFFER_SIZE
	mov	di, sp				; buffer => SS:DI
	push	es				; save DGroup
	push	di				; save start of the string
	segmov	es, ss				; SS => ES
	call	CreateTimeString		; stuff with the time string
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx				; allocate a memory block
	call	ObjCallInstanceNoLock		; memory block => cX
	mov	bx, cx				; handle => BX
	call	MemLock				; segment => AX
	pop	si				; second string offset => SI
	pop	es				; dgroup => ES
	push	bx				; save the time text handle
	mov	cx, ax
	clr	dx				; first string	=> CX:DX
	mov	bx, ss				; second string => BX:SI
	mov	bp, CAL_ERROR_TIME_REVERTED	; the time was restored
	call	DisplayErrorBox			; display the error box
	pop	bx				; string handle => BX
	call	MemFree				; free the handle
	add	sp, TIME_BUFFER_SIZE		; restore the stack
	pop	cx				; old time => CX
	stc					; clear the carry
done:
	.leave
	ret
DayEventParseTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventUpdateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the time of an event, by parsing the current text
		& resetting the text if the time is invalid (after
		warning the user as appropriate). Does NOT affect the database.

CALLED BY:	GLOBAL (MSG_DE_UPDATE_TIME)

PASS:		*DS:SI	= DayEventClass object
		DS:DI	= DayEventClassInstance

RETURN:		Carry	= Set if an invalid time was found

DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventUpdateTime	method dynamic	DayEventClass, MSG_DE_UPDATE_TIME
		uses	cx, dx, bp
		.enter

		; Parse & then set the time
		;
		test	ds:[di].DEI_actFlags, DE_TIME_DIRTY
		jz	exit			; if time not dirty, do nothing
		mov	ax, MSG_DE_PARSE_TIME
		call	ObjCallInstanceNoLock
		pushf	
		mov	ax, MSG_DE_SET_TIME
		call	ObjCallInstanceNoLock
		popf
exit:
		.leave
		ret
DayEventUpdateTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSelectTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the time text, and give it the focus & the target

CALLED BY:	GLOBAL (MSG_DE_SELECT_TIME)

PASS:		ES	= DGroup
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/7/90		Initial version
	SS	4/7/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSelectTime	method	DayEventClass,	MSG_DE_SELECT_TIME

	; In Responder, time text is not editable, therefore
	; it is never given the focus.
	;
	; Ensure the event view has the target
	;
	push	ds:[di].DEI_timeHandle		; save the time handle 
	mov	bl, 1				; grab the focus exclusive
	call	EnsureEventViewIsTarget

	; Easy - get time handle, and select all
	;
	pop	si				; text object => DS:*SI 
	clr	cx				; select all of the text
	mov	dx, TEXT_ADDRESS_PAST_END_LOW
	GOTO	DESelectCommon
DayEventSelectTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSelectText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select a range of text in the Event text

CALLED BY:	GLOBAL (MSG_DE_SELECT_TEXT)

PASS:		ES	= DGroup
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		CX	= Start offset
		DX	= End offset

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/23/90		Initial version
	SS	4/7/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSelectText	method	DayEventClass,	MSG_DE_SELECT_TEXT

	; Now ensure the window is the target window
	;
	push	cx, dx				; save the selection data
	push	ds:[di].DEI_textHandle		; save the time handle
	mov	ax, MSG_GEN_MAKE_TARGET
	mov	bx, segment GenClass
	mov	si, offset GenClass
	mov	di, mask MF_RECORD 
	call	ObjMessage_dayevent
	mov	cx, di			; Get handle to ClassedEvent in cx
	mov	ax, MSG_VIS_VUP_CALL_WIN_GROUP
	mov	si, offset DPResource:DayPlanObject
	mov	di, offset DayPlanClass		; ES:DI is the DayPlanClass
	call	ObjCallSuperNoLock		; makes our window the target
	
	; Ensure the view also has the target exclusive
	;
if	_TODO
	mov	bl, 1				; if To Do, grab focus
else
	clr	bl				; don't grab the focus excl
endif
	call	EnsureEventViewIsTarget

	; Select the text & grab the exclusives
	;
	pop	si				; DS:*SI is the text object
	pop	cx, dx				; selection range => CX, DX
	FALL_THRU	DESelectCommon
DayEventSelectText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DESelectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the common work of selecting text

CALLED BY:	DayEventSelectTime, DayEventSelectText

PASS:		*DS:SI	= MyTextObject
		CX	= Start of selection range
		DX	= End of selection range

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DESelectCommon	proc	far
	
	; Select the text, and then grab the exclusives
	; (Responder only) don't select.  Just grab exclusives.
	;
	mov	ax, MSG_VIS_TEXT_SELECT_RANGE_SMALL	; select the range
	call	ObjCallInstanceNoLock		
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock		; and make it the target
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	GOTO	ObjCallInstanceNoLock		; and make it the focus
DESelectCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EnsureEventViewIsTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensures that the EventView has the target

CALLED BY:	DayEventSelectTime, DayEventSelectText

PASS:		DS:*SI	= DayEvent instance
		ES	= DGroup
		BL	= 0 Don't grab focus exclusive
			= ? Grab the focus exclusive

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EnsureEventViewIsTarget	proc	near
	.enter

	; Query upward for the GenView class (cheat by starting at the DP)
	;
	mov	ax, MSG_VIS_VUP_FIND_OBJECT_OF_CLASS
	mov	cx, segment GenViewClass
	mov	dx, offset GenViewClass		; class to look for
	mov	si, offset DPResource:DayPlanObject
	mov	di, offset DayPlanClass		; ES:DI is the DayPlanClass
	call	ObjCallSuperNoLock		; returns window in CX:DX
	jnc	done				; if not found, do nothing

	; Grab the target exclusive
	;
	push	bx				; save the focus excl flag
	mov	bx, cx
	mov	si, dx				; OD => BX:SI
	mov	ax, MSG_GEN_MAKE_TARGET
	call	ObjMessage_dayevent_call

	; Grab the focus exclusive
	;
	pop	ax				; focus exclusive flag => AL
	tst	al				; is DI zero
	jz	done				; then do nothing
	mov	ax, MSG_GEN_MAKE_FOCUS
	call	ObjMessage_dayevent_call
done:
	.leave
	ret
EnsureEventViewIsTarget	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffTimeString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the event time string

CALLED BY:	DayEventInit, DayEventSetTime

PASS:		DS:*SI	= DayEvent instance data

RETURN:		DS:*DI	= Time text object

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/5/89		Initial version
	sean	3/20/95		To Do list changes
	sean	8/9/95		Responder end time changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


StuffTimeString	proc	near
	class	DayEventClass
	uses	cx, dx, bp, si, es
	.enter

	; Now create the string
	;
	segmov	es, ss, di
	sub	sp, TIME_BUFFER_SIZE		; allocate room on the stack
	mov	di, sp				; ES:DI => string buffer

	; Create the string
	;
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayEvent_offset	; access instance data
	mov	cx, {word} ds:[si].DEI_timeMinute
TODO  <	test	ds:[si].DEI_stateFlags, mask EIF_TODO       	>
	mov	si, ds:[si].DEI_timeHandle	; time handle => DS:*SI
TODO  <	jnz	finish						>
	call	CreateTimeString		; create the time string
		
	; Now set the text
	;
	clr	cx				; string is NULL terminated
	mov	dx, es
	mov	bp, di				; DX:BP points to the text
	call	StuffTextUtility		; stuff the text
finish::
	mov	di, si				; time handle => DS:*DI
	add	sp, TIME_BUFFER_SIZE		; restore the stack

	.leave
	ret
StuffTimeString	endp



if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DETodoNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Numbers a To Do list event	

CALLED BY:	MSG_DE_TODO_NUMBER 
		  from DayPlanScreenUpdate

PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cx	= To Do list number

RETURN:		nothing		

DESTROYED:	es

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Create string buffer on stack
		Get DayEvent's time text handle
		  (used as a list number for To Do list)
		Create number in buffer
		Transfer string in stack buffer to time text object
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/18/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DETodoNumber	method dynamic DayEventClass, 
					MSG_DE_TODO_NUMBER
	uses	ax,cx,dx,bp
	.enter

	; Set up string buffer
	;
	segmov	es, ss, di
	sub	sp, TIME_BUFFER_SIZE		; allocate room on the stack
	mov	di, sp				; ES:DI => string buffer

	; Create the string
	;
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayEvent_offset	; access instance data	
	mov	si, ds:[si].DEI_timeHandle	; time handle => DS:*SI

	call	CreateToDoNumber		; es:di = number string

	; Now set the text
	;
	clr	cx				; string is NULL terminated
	mov	dx, es
	mov	bp, di				; DX:BP points to the text
	call	StuffTextUtility		; stuff the text
	mov	di, si				; time handle => DS:*DI
	add	sp, TIME_BUFFER_SIZE		; restore the stack

	.leave
	ret
DETodoNumber	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateToDoNumber
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the number for the events


CALLED BY:	DETodoNumber

PASS:		es:di 	= String buffer for number
		cx	= number

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/13/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateToDoNumber	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	; Get next number and create string out of it
	;
	mov	ax, cx
	clr	dx				; dx:ax = number to convert
	mov	cx, mask UHTAF_NULL_TERMINATE
	call	UtilHex32ToAscii		; es:di = number string
	
	; Put a period after the number
	;
	call	LocalStringLength		; cx = stringLength
	mov	si, di
	add	si, cx				; es:si = ptr to end of string
	LocalLoadChar ax, C_COLON
	LocalPutChar  essi, ax			; put period at end of string
	LocalLoadChar ax, C_NULL
	LocalPutChar  essi, ax  		; put null at end of string

	.leave
	ret
CreateToDoNumber	endp
endif		; if	_TODO


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffTextString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the initial event text

CALLED BY:	DayEventInit

PASS: 		DS:*SI	= DayEvent instance data

RETURN:		Nothing

DESTROYED:	AX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/23/89	Initial version
	Don	12/5/89		Use group & item numbers

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StuffTextStringFar	proc	far
	call	StuffTextString
	ret
StuffTextStringFar	endp

StuffTextString	proc	near
	uses	ax, cx, dx, bp, si, es	
	.enter


	; Some set up work
	;
RSP <	push	bx							>
RSP <	mov	bx, si							>
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].DayEvent_offset	; access my instance data
	mov	si, ds:[bp].DEI_textHandle	; DS:*SI = text object
RSP <	call	ModifyTextObject		; Responder modifications>
RSP <	mov	bp, ds:[bx]			; dereference DayEvent  >
RSP <	add	bp, ds:[bp].DayEvent_offset				>
RSP <	pop	bx							>

	test	ds:[bp].DEI_actFlags, DE_VIRGIN
	jne	virgin

	; Just set the text (both normal & repeat)
	;
	mov	ax, ds:[bp].DEI_DBgroup
	mov	di, ds:[bp].DEI_DBitem
	test	ds:[bp].DEI_stateFlags, mask EIF_REPEAT
	jne	repeat				; a repeat event!

	; Handle the normal Event
	;
	call	GP_DBLockDerefDI		; lock it, dude
	mov	cx, es:[di].ES_dataLength	; store the length of the data
	mov	bp, offset ES_data
	jmp	common

	; Handle the Repeat Event
repeat:
	and	ax, not REPEAT_MASK		; clear the low bit
	call	GP_DBLockDerefDI		; lock the RepeatStruct
	mov	cx, es:[di].RES_dataLength	; get length of the data
	mov	bp, offset RES_data
common:
DBCS <	shr	cx, 1							>
	mov	dx, es
	add	bp, di				; DX:BP points to the data
	call	StuffTextUtility		; stuff the text
	call	DBUnlock			; unlock the item
	jmp	done				; we're done

	; Handle the virgin case
virgin:
	clr	cx				; no text
	mov	dx, cs
	mov	bp, offset blankByte		; a null string
	call	StuffTextUtility		; stuff the text
done:
	.leave
	ret
StuffTextString	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffHeaderString
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create and stuff a header string (DOW MONTH DAY, YEAR)

CALLED BY:	DayEventInitHeader

PASS:		DS:*SI	= DayEvent instance data
		ES	= DGroup
		DX	= Month/Day
		BP	= Year

RETURN:		Nothing

DESTROYED:	AX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StuffHeaderString	proc	near
	uses	si, es
	.enter

	; Some set up work
	;
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayEvent_offset	; access my instance data
	push	ds:[si].DEI_textHandle		; save the text handle
	mov	si, ds:[si].DEI_timeHandle	; text handle => SI

	; Now create the text, and set it
	;
	segmov	es, ss, di
	sub	sp, DATE_BUFFER_SIZE		; allocate room on the stack
	mov	di, sp				; ES:DI => string buffer
	push	di				; save start of the buffer
	mov	cx, DTF_LONG_CONDENSED or USES_DAY_OF_WEEK
	call	CreateDateString
	mov	dx, es
	pop	bp				; DX:BP points to the strng
	clr	cx				; text is NULL terminated
	call	StuffTextUtility		; stuff the text
	add	sp, DATE_BUFFER_SIZE		; clean up the stack

	; Clear the event text
	;
	pop	si				; Event text obj => SI
	clr	cx				; NULL terminated
	mov	dx, cs
	mov	bp, offset blankByte		; a null string
	call	StuffTextUtility		; stuff the text

	.leave
	ret
StuffHeaderString	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffTextUtility
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the text object dirty, stuffs the text, and sets it clean

CALLED BY:	INTERNAL
	
PASS:		DS:*SI	= TextObject
		DX:BP	= Text
		CX	= Length of the text

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/30/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StuffTextUtility	proc	near
	.enter
	class	MyTextClass

	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock

	.leave
	ret
StuffTextUtility	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetTextStyle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set text style for a text object
		This is used to set/clr bold face

CALLED BY:	StuffTextString, StuffTimeString
PASS:		ch	= TextStyle bits to set
		cl	= TextStyle bits to clear
		*ds:si	= MyTextClass object
RETURN:		nothing
DESTROYED:	nothing		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	2/11/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the alarm time of the DayEvent

CALLED BY:	GLOBAL (MSG_DE_SET_ALARM)

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		CH	= Hours
		CL	= Minutes
		DH	= Month
		DL	= Day
		BP	= Year

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Must update through the qeuue to avoid bizzare problems
		when changing the time.  If we are either a virgin event
		or a repeating event, DO NOT notify the database of a
		change in the alarm time.  Basically, this is either
		uneccesary (we're changing to a normal event) or very
		undesirable (we're in the middle of an UNDO).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version
	sean	7/13/95		Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSetAlarm	method	DayEventClass, MSG_DE_SET_ALARM
	uses	cx
	.enter


	; Store the data
	;
	cmp	ds:[di].DEI_alarmYear, bp	; compare the years
	jne	new
	cmp	{word} ds:[di].DEI_alarmDay, dx	; compare month & day
	jne	new
	cmp	{word} ds:[di].DEI_alarmMinute, cx ; compare hour and minute
	je	done

	; New alarm time - save and update
	;
new:
	mov	ds:[di].DEI_alarmYear, bp	; store the year
	mov	{word} ds:[di].DEI_alarmDay, dx	; store month & day
	mov	{word} ds:[di].DEI_alarmMinute, cx ; store hour and minute

	test	ds:[di].DEI_stateFlags, mask EIF_REPEAT
	jnz	done				; ignore this if a RepeatEvent
	test	ds:[di].DEI_actFlags, DE_VIRGIN	; a virgin event now ??
	jnz	done				; yes, so do nothing
	mov	ax, MSG_DE_UPDATE		; tell use to update ourselves
	mov	cl, DBUF_ALARM 			; update the alarm
	call	ObjCallInstanceNoLock		; send the method
done:
	.leave
	ret

DayEventSetAlarm	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetSelectedText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns a block containing a copy of the selected text in
		the DayEvent's event TEO. If none selected, CX == 0.

CALLED BY:	GLOBAL (MSG_DE_GET_SELECTED_TEXT)

PASS:		ES	= DGroup
		DS:DI	= DayEventClass specific instance data

RETURN:		CX	= Length of text
		DX	= Handle of block containing text

DESTROYED:	DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	0
DayEventGetSelectedText	method	DayEventClass,	MSG_DE_GET_SELECTED_TEXT
	.enter

	mov	si, ds:[di].DEI_textHandle	; text handle => SI
	clr	dx				; allocate a global mem block
	mov	ax, MSG_VIS_TEXT_GET_SELECTION_BLOCK	; method to pass
	call	ObjCallInstanceNoLock		; call the method handler
	mov	dx, cx				; text block handle => DX
	mov_tr	cx, ax				; length of text => CX

	.leave
	ret
DayEventGetSelectedText	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note when a dayevent is made dirty

CALLED BY:	UI (MSG_META_TEXT_USER_MODIFIED)

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		CX:DX	= Text ojbect made dirty
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	CL, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/29/89	Initial version
	sean	1/30/96		Responder version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventDirty	method	DayEventClass,	MSG_META_TEXT_USER_MODIFIED

	; Do the common work
	;
	or	es:[searchInfo], mask SI_RESET	; indicate reset of search
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayEvent_offset	; access my instance data
	mov	ax, dx				; text object handle => AX
	mov	cx, ds:[di].DEI_DBgroup
	mov	dx, ds:[di].DEI_DBitem
	mov	bp, si
	cmp	ax, ds:[di].DEI_textHandle
	je	textDirty

	; The time is dirty
	;
	or	ds:[di].DEI_actFlags, DE_TIME_DIRTY
	call	UndoNotifyTime
	jmp	common

	; The text is dirty
textDirty:
	or	ds:[di].DEI_actFlags, DE_TEXT_DIRTY
	call	UndoNotifyText			; notify the undo code

	; Do we need to do change to a NORMAL event ??
common:
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayEvent_offset	; access the instance data
	test	ds:[di].DEI_stateFlags, mask EIF_REPEAT
	jnz	changeState			; no longer a repeat event!
	test	ds:[di].DEI_actFlags, DE_VIRGIN	; a virgin event now ??
	jnz	changeState			; yes, so change the state!

	call	AlarmCheckActive		; nuke associated reminder
	jmp	done

	; Must change the state of the DayEvent
changeState:
	mov	ax, {word} ds:[di].DEI_timeMinute
	call	UndoNotifyStateChange		; notify of a state change

	mov	cl, DBUF_NEW			; a new event
	mov	ax, MSG_DE_UPDATE		; send the update method
	call	ObjCallInstanceNoLock		; just do it

	; Must check to see if we are selected
done:
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayEvent_offset	; access the instance data
	test	ds:[di].DEI_actFlags, DE_SELECT	; are we selected
	jnz	reallyDone			; yes, so don't bother
	call	DayEventUpdateIfNecessary	; else we really better update
reallyDone:
	ret
DayEventDirty	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetClean
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear any dirty bits (also cleans the text handle)

CALLED BY:	MyTextClass (MSG_DE_SET_CLEAN)

PASS:		DS:DI	= DayEvent specific instance data

RETURN:		Nothing

DESTROYED:	AX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSetClean	method	DayEventClass,	MSG_DE_SET_CLEAN
	.enter

	and	ds:[di].DEI_actFlags, not (DE_TEXT_DIRTY or DE_TIME_DIRTY)
	mov	si, ds:[di].DEI_textHandle
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	call	ObjCallInstanceNoLock

	.leave
	ret
DayEventSetClean	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of height changes in a text object

CALLED BY:	TextObject (MSG_VIS_TEXT_HEIGHT_NOTIFY)

PASS:		DS:*SI	= MyTextObject
		ES	= DGroup
		DX	= Height of the sucker

RETURN:		Nothing

DESTROYED:	AX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextHeightNotify	method	MyTextClass,	MSG_VIS_TEXT_HEIGHT_NOTIFY
	.enter

	; Am I the text resize object, else notify my visual parent
	;
	cmp	si, es:[SizeTextObject]		; compare the handles
	je	done				; if equal, done
	mov	bp, si				; my handle => BP
	mov	ax, MSG_DE_HEIGHT_NOTIFY	; method to send
	call	VisCallParent			; call the DayEvent holding me
done:
	.leave
	ret
MyTextHeightNotify	endp


if 0
MyTextKbdChar	method MyTextClass, MSG_META_KBD_CHAR
	.enter
	cmp	cx, (CS_CONTROL shl 8) or VC_UP
	je	moveUp
	cmp	cx, (CS_CONTROL shl 8) or VC_DOWN
	jne	skip
	mov	si, offset MyTextClass
	mov	ax, MSG_SPEC_NAVIGATE_TO_NEXT_FIELD
	call	ObjCallInstanceNoLock
	jmp	done
moveUp:
	mov	si, offset MyTextClass
	mov	ax, MSG_SPEC_NAVIGATE_TO_PREVIOUS_FIELD
	call	ObjCallInstanceNoLock
	jmp	done
skip:
	mov	di, offset MyTextClass
	call	ObjCallSuperNoLock
done:		
	.leave
	ret
MyTextKbdChar	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify me of a height change

CALLED BY:	MyTextHeightNotify

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		BP	= Handle of child text object whose height has changed
		DX	= New height of event text

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventHeightNotify	method	DayEventClass,	MSG_DE_HEIGHT_NOTIFY
	.enter

	cmp	bp, ds:[di].DEI_textHandle	; is it the text handle
	jne	done				; if not, jump
	mov	bp, si				; my handle to BP
	add	bx, ds:[bx].Vis_offset		; access my visual data
	mov	cx, ds:[bx].VI_bounds.R_top	; get my top position
	mov	bx, ds:[LMBH_handle]		; OD => BX:SI
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_ETE_HEIGHT_NOTIFY

	mov	di, mask MF_INSERT_AT_FRONT or mask MF_FORCE_QUEUE
	call	ObjMessage_dayevent		; CX = my Y-position
						; DX = new TextObj height
						; BP = DayEvent handle
done:
	.leave
	ret
DayEventHeightNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextLostMouseExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of the MyText object losing the mouse excl

CALLED BY:	UI (MSG_META_LOST_MOUSE_EXCL)

PASS:		DS:*SI	= MyTextClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	CX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	11/7/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextLostMouseExcl	method	MyTextClass,	MSG_META_LOST_MOUSE_EXCL
	.enter

	; Call my wonderful superclass first
	;
	mov	di, offset MyTextClass		; ES:DI points to my Class
	call	ObjCallSuperNoLock		; call the superclass

	; Make sure we don't think we are still selecting text.  This is
	; needed if we enter a bad date in one event, click and hold the mouse
	; on another, get a UserDoDialog error message, then release the mouse.
	; The END_SELECT will never be delivered to this object as it no
	; longer has the mouse grab.  In a normal situation, this will be
	; received after the END_SELECT, so will have no effect.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	andnf	ds:[di].VTI_intSelFlags, not mask VTISF_DOING_SELECTION

	.leave
	ret
MyTextLostMouseExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of the MyText object losing the target

CALLED BY:	UI (MSG_META_LOST_TARGET_EXCL)

PASS:		DS:*SI	= MyTextClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	CX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/19/90		Initial version
	Don	6/22/90		Changed to LOST_TARGET

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextLostTargetExcl	method	MyTextClass,	MSG_META_LOST_TARGET_EXCL
	.enter

	; Call my wonderful superclass first
	;
	mov	di, offset MyTextClass		; ES:DI points to my Class
	call	ObjCallSuperNoLock		; call the superclass
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED	; & set myself clean
	call	ObjCallInstanceNoLock		; send the method

	; Now do some real work
	;
	cmp	si, es:[SizeTextObject]		; compare the handles
	je	done				; if equal, done
	mov	bp, si				; my handle => BP
	mov	ax, MSG_DE_TEXT_LOST_TARGET	; method to send
	call	VisCallParent			; call the DayEvent holding me
done:
	.leave
	ret
MyTextLostTargetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of when we gain the target exclusive

CALLED BY:	UI (MSG_META_GAINED_TARGET_EXCL)
	
PASS:		DS:DI	= MyTextClass specific instance data
		DS:*SI	= MyTextClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextGainedTargetExcl	method	MyTextClass,	MSG_META_GAINED_TARGET_EXCL
	.enter

	; Call my wonderful superclass first
	;
	mov	di, offset MyTextClass		; ES:DI points to my Class
	call	ObjCallSuperNoLock		; call the superclass
	cmp	si, es:[SizeTextObject]		; compare the handles
	je	done				; if equal, done
	mov	ax, MSG_DE_TEXT_GAINED_TARGET ; method to send
	call	VisCallParent			; call the DayEvent holding me
done:
	.leave
	ret
MyTextGainedTargetExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventTextLostTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an update now (if necessary)

CALLED BY:	MyTextLostTarget (MSG_DE_TEXT_LOST_TARGET)

PASS: 		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		BP	= Child text handle

RETURN:		Nothing

DESTROYED:	AX, CX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Does nothing if the DE_IGNORE_LOST_FOCUS bit is set.
		Always clears this bit after a LOST_FOCUS is received.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/19/90		Initial version
	Don	6/19/90		Added check for DE_IGNORE_LOST_FOCUS
	Don	6/22/90		Changed to LOST_TARGET

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventTextLostTarget	method	DayEventClass,	MSG_DE_TEXT_LOST_TARGET
	call	DayEventUpdateIfNecessary	; update if dirty
	clr	si				; nothing should be selected
	FALL_THRU	DayEventTextGainedTarget
DayEventTextLostTarget	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventTextGainedTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of when we gain/lose the target exclusive

CALLED BY:	MyTextGainedTargetExcl (MSG_DE_TEXT_GANIED_TARGET)
	
PASS:		DS:DI	= DayEventClass specific instance data
		DS:*SI	= DayEvent handle, or zero
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, SI, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventTextGainedTarget	method	DayEventClass,\
					MSG_DE_TEXT_GAINED_TARGET
	.enter

	; Make certain that we are the selected item
	;
	mov	bp, si				; my handle to BP
	mov	si, offset DPResource:DayPlanObject
	test	ds:[di].DEI_actFlags, DE_SELECT	; are we already selected ??
	jnz	done				; if so, don't notify anyone
	mov	ax, MSG_DP_SET_SELECT		; tell the DayPlan to select us
	call	ObjCallInstanceNoLock		; send the method now!
done:
	.leave

exitDE	label	far
	ret
DayEventTextGainedTarget	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventUpdateIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update either the time or event text, if necessary

CALLED BY:	INTERNAL
	
PASS:		DS:DI	= DayEventClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/23/90		Initial version
	sean	10/3/95		Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventUpdateIfNecessary	proc	near
	.enter

	; Check for dirtiness
	;
	mov	cl, DBUF_TIME			; assume the time changed
	mov	ch, DE_TIME_DIRTY
	cmp	bp, ds:[di].DEI_timeHandle
	je	checkUpdate
	mov	cl, DBUF_EVENT
	mov	ch, DE_TEXT_DIRTY
		
	; Do we need to update ?
checkUpdate:
	test	ds:[di].DEI_actFlags, ch	; is the flag set ?
	jz	exit				; no - quit
	mov	ax, MSG_DE_UPDATE		; method to send
	call	ObjCallInstanceNoLock		; update the database
	jc	exit				; if error, reset the focus
	mov	di, ds:[si]
	add	di, ds:[di].DayEvent_offset
	not	ch
	andnf	ds:[di].DEI_actFlags, ch	; clear the appropriate flag
exit:
	.leave
	ret
DayEventUpdateIfNecessary	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventFupKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Swallow and TAB & CR characters that are sent to us, as
		we've already dealt with the characters as needed. This
		is to get around a bug in the text object where it FUP's
		the character after sending out MSG_META_TEXT_TAB_FILTERED,
		even though we've already intercepted & used that character,

CALLED BY:	GLOBAL (MSG_META_FUP_KBD_CHAR)

PASS:		*DS:SI	= DayEventClass object
		DS:DI	= DayEventClassInstance
		BP high	= scan code
		BP low	= ToggleState
		DH	= ShiftState
		DL	= CharFlags
		CX	= Character value

RETURN:		Carry	= Set if character swallowed

DESTROYED:	see MSG_META_FUP_KBD_CHAR

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/11/93		Initial version
		Don	10/14/94	Small space optimization
		sean	12/14/95	Responder change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventFupKbdChar	method dynamic	DayEventClass, MSG_META_FUP_KBD_CHAR
	;
	; See if we understand the keypress, or else call superclass
	;
		test	dl, mask CF_RELEASE

	; For Responder, we only want to handle key presses, not 
	; key releases.  This fixes #38875.
	;
		jz	done
	
		mov	ax, MSG_DP_SELECT_PREVIOUS	; assume up
SBCS <		cmp	cx, (CS_CONTROL shl 8) or VC_UP			>
DBCS <		cmp	cx, C_SYS_UP					>
		je	move

		mov	ax, MSG_DP_SELECT_NEXT		; assume down
SBCS <		cmp	cx, (CS_CONTROL shl 8) or VC_DOWN		>
DBCS <		cmp	cx, C_SYS_DOWN					>
		je	move

	; Don't process keyboard shortcuts for Responder
	;
		call	DayEventProcessShortcut
		jc	done
		mov	ax, MSG_META_FUP_KBD_CHAR
		mov	di, offset DayEventClass
		GOTO	ObjCallSuperNoLock
	;
	; Move to either the previous or next event
	; 
move:
		mov	si, offset DPResource:DayPlanObject
		call	ObjCallInstanceNoLock
		stc
done:
		ret
DayEventFupKbdChar	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventHandleTab
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to a tab pressed in the time field

CALLED BY:	UI (through the text object)

PASS:		ES	= DGroup
		DS:DI	= DayEventClass specific instance data
		BP high	= scan code
		BP low	= ToggleState
		DH	= ShiftState
		DL	= CharFlags
		CX	= Character value

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		There are 6 possibilities:
			1) Tab:		Time -> Text
			2) Tab:		Text -> next Time
			3) Tab:		Header -> next Time
			4) Shift-Tab:	Text -> Time
			5) Shift-Tab:	Time -> prev text
			6) Shift-Tab:	Header -> prev text

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/11/90		Initial version
	Don	1/11/93		Added shift-tab capabilities

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayEventHandleTab	method	DayEventClass,	MSG_META_TEXT_TAB_FILTERED,
						MSG_META_TEXT_CR_FILTERED

	; First, let's see if we can handle this event
	;
	call	DayEventProcessShortcut
LONG	jnc	exitDE				; nope, no handler, so abort

	; See who has the target now
	;
	push	bx				; shortcut offset
	mov	al, ds:[di].DEI_stateFlags
	push	ax
	mov	bx, ds:[di].DEI_textHandle	; text handle => BX
	mov	di, ds:[di].DEI_timeHandle	; time handle => DI
	mov	ax, MSG_META_GET_TARGET_EXCL
	mov	si, offset DPResource:DayPlanObject
	call	ObjCallInstanceNoLock		; focus => CX:DX
EC <	cmp	cx, ds:[LMBH_handle]		; check block		>
EC <	ERROR_NE DE_MY_TEXT_OBJECT_MUST_BE_IN_SAME_BLOCK		>
	pop	cx				; EventInfoFlags => CL
	pop	bp				; shortcut offset => BP

	; Now see who should be getting the focus (TAB)
	;
	shr	bp, 1				; even = forward, odd = backward
	shr	bp, 1				; carry set = backward
	jc	backwards			; yes, so deal with it
	test	cl, mask EIF_HEADER
	mov	ax, MSG_DP_SELECT_NEXT
	mov	cx, 0				; end-select = 0
common:
	jnz	diffEvent
	cmp	dx, bx				; does the text	have the focus??
	je	diffEvent
	mov	si, bx				; MyTextObject => *DS:SI

	; Just set the focus to a different text object in the same event
	;
	mov	dx, cx				; end selection => DX
	clr	cx				; start selection => CX
	GOTO	DESelectCommon			; grab the target & focus

	; Give the focus & target to the next DayEvent
diffEvent:
	GOTO	ObjCallInstanceNoLock		; select the next event

	; Now check out the backwards case (SHIFT-TAB)
backwards:
	test	cl, mask EIF_HEADER
	mov	ax, MSG_DP_SELECT_PREVIOUS
	xchg	bx, di
	mov	cx, TEXT_ADDRESS_PAST_END_LOW	; end-select = end
	jmp	common
DayEventHandleTab	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventProcessShortcut
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a keyboard shortcut 

CALLED BY:	UTILITY

PASS:		BP high	= scan code
		BP low	= ToggleState
		DH	= ShiftState
		DL	= CharFlags
		CX	= Character value

RETURN:		Carry	= Set (match found)
		BX	= offset in shortcut table
			- or -
		Carry	= Clear (match not found

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 7/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventProcessShortcut	proc	near

	; Call the keyboard driver to process the shortcuts
	;
	test	dl, mask CF_FIRST_PRESS or \
		    mask CF_REPEAT_PRESS
	jz	done				; ignore all other CharFlags
	push	ds, si				; save object
	segmov	ds, cs
	mov	si, offset dayEventShortcutTable ; shortcut table => DS:SI
	mov	ax, DAY_EVENT_NUM_SHORTCUTS	; # entries in table => AX
	call	FlowCheckKbdShortcut		; do we understand ??
	mov	bx, si				; offset => BX
	pop	ds, si				; restore object
done:
	ret
DayEventProcessShortcut	endp

if DBCS_PCGEOS

dayEventShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0, C_SYS_TAB and mask KS_CHAR>,
	<1, 0, 0, 1, C_SYS_TAB and mask KS_CHAR>,
	<1, 0, 0, 0, C_SYS_ENTER and mask KS_CHAR>,
	<1, 0, 0, 1, C_SYS_ENTER and mask KS_CHAR>

else
dayEventShortcutTable	KeyboardShortcut \
			<1, 0, 0, 0, (CS_CONTROL and 0fh), VC_TAB>,
			<1, 0, 0, 1, (CS_CONTROL and 0fh), VC_TAB>,
			<1, 0, 0, 0, (CS_CONTROL and 0fh), VC_ENTER>,
			<1, 0, 0, 1, (CS_CONTROL and 0fh), VC_ENTER>
endif

DAY_EVENT_NUM_SHORTCUTS	= ($ - dayEventShortcutTable) / 2


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the database to update the DayEvent's record

CALLED BY:	GLOBAL (MSG_DE_UPDATE)

PASS:		CL	= DataBaseUpdateFlags
				DBUF_NEW
				DBUF_TIME
				DBUF_ALARM
				DBUF_EVENT
				DBUF_FLAGS
				DBUF_IF_NECESSARY
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		ES	= DGroup

RETURN:		Carry	= Set if error
		AX	= 0 if something was updated
			= <> 0 if not

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/12/89	Initial version
	sean	3/19/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventUpdate	method	DayEventClass, MSG_DE_UPDATE
	uses	cx, dx, bp, si
	.enter

	; Check for the the UpdateFlag
	;
	mov	bl, cl				; DataBaseUpdateFlag => BL

if	UNIQUE_EVENT_ID

	; Reserve event ID, and stick it to instance data if we are
	; creating new event.
	;
	test	bl, DBUF_NEW
	jz	notNew

	; Do we have an event ID for this event yet? We might (even
	; though this is DBUF_NEW) if we are converting a repeat event
	; to normal. See CheckIfChangeToNormal.
	;
	; If the event has valid ID already, don't use a new one.
	;
	cmpdw	ds:[di].DEI_uniqueID, INVALID_EVENT_ID
	ja	notNew
	
	; Note that we find the next ID, and put that ID to instance
	; data of DayEvent object, because the ID should be recorded to
	; DayEvent right when the event is create.
	;
	call	UseNextEventID			; cxdx <- next event id
	movdw	ds:[di].DEI_uniqueID, cxdx
notNew:
endif

if	HANDLE_MAILBOX_MSG

	; If we see any flags that change the properties of the event,
	; change a flag in the object to mark that SMS update should
	; be sent to recipient next time the details dialog is closed.
	;
	; DBUF_FLAGS has no effect, because all property changes
	; would call MSG_DE_UPDATE with other database flags.
	;
	; First, non-time change.
	;
	push	ax
	test	bl, DBUF_EVENT or DBUF_ALARM
	mov	ax, mask DEBF_NON_TIME_CHANGE
	jnz	addVardata

	;
	; Time related change.
	;
	test	bl, DBUF_TIME or DBUF_VARLEN
	jz	noSMSNeeded
	mov	ax, mask DEBF_TIME_CHANGED
	
addVardata:
	; Change the flag.
	;
	call	DayEventMarkBookingUpdateNecessary ; ds:di <- instance
	
noSMSNeeded:
	pop	ax
endif

TODO <	test	bl, DBUF_ALARM				>
TODO <	jnz	doUpdate				>
	test	ds:[di].DEI_stateFlags, mask EIF_HEADER
	jne	quit				; if it's a header, do nothing
	test	bl, DBUF_IF_NECESSARY		; update if necessary ??
	jz	checkUpdate
	test	ds:[di].DEI_actFlags, DE_TEXT_DIRTY
	jz	checkTime
	mov	bl, DBUF_EVENT			; set the text update flag
checkTime:	
	test	ds:[di].DEI_actFlags, DE_TIME_DIRTY
	jz	checkNecessary
	mov	bl, DBUF_TIME			; set the time update flag
checkNecessary:
	test	bl, DBUF_IF_NECESSARY		; no real flag set ??
	jnz	quit				; if so, then leave!

	; Allocate space on the stack, and call my procedure
	;
checkUpdate:
	test	bl, DBUF_TIME			; is the time dirty ??
	jz	doUpdate			; no - jump
	mov	ax, MSG_DE_UPDATE_TIME
	call	ObjCallInstanceNoLock		; parse & reset the time
doUpdate:
	mov	dx, size DayEventInstance	; DX = size of structure
	sub	sp, dx				; allocate room on the stack
	segmov	es, ss
	mov	di, sp				; structure => ES:DI
	mov	bp, sp				; also => ES:BP
	push	si				; save the DayEvent handle
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayEvent_offset	; instance data => DS:SI
	mov	cx, size DayEventInstance	; number of bytes to copy
	rep	movsb				; copy the bytes

	; Now call my process
	;
	mov	cl, bl				; update flags => CL
	push	bx				; save the update flags
	mov	ax, MSG_CALENDAR_UPDATE_EVENT
	call	GeodeGetProcessHandle		; process handle => BX
	mov	di, mask MF_CALL or mask MF_STACK or \
		    mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage_dayevent		; call for the update
	pop	bx				; restore the update flags
	pop	si				; restore the DayEvent handle
	jnc	done				; jump if no notify

	; Else we've changed from a virgin or a repeat to a normal event
	;
	mov	bp, 3				; a type 3 change (I know, bad)
	call	DayEventChangeState		; change the state (saves BL)

	; Clean up the stack, and maybe set the event text clean
	;
done:
	add	sp, size DayEventInstance	; restore the stack
	test	bl, DBUF_EVENT			; was the text dirty ??
	jz	done2				; no, so jump
	mov	ax, MSG_DE_SET_CLEAN		; else set it clean
	call	ObjCallInstanceNoLock
done2:
	clr	ax				; something was updated
quit:
	.leave
	ret
DayEventUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventChangeState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the state of a DayEvent
		Possible transiitions:
			1) NORMAL => VIRGIN
			2) NORMAL => REPEAT
			3) REPEAT or VIRGIN => NORMAL

CALLED BY:	DayEventUpdate

PASS:		DS:*SI	= DayEvent instance data
		CX	= Group #
		DX	= Item #
		BP	= DayEventStateChange

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/4/90		Initial version
	Don	1/26/90		Much revised and expanded

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventChangeState	method	DayEventClass,	MSG_DE_CHANGE_STATE
	uses	bx
	.enter

	; Some set-up work
	;
	mov	di, ds:[si]			; derference the handle
	add	di, ds:[di].DayEvent_offset	; access my instance data
	mov	ds:[di].DEI_DBgroup, cx		; store group #
	mov	ds:[di].DEI_DBitem, dx		; store item #	

	; Set up the state & action flags
	;
	cmp	bp, DESC_REPEAT_OR_VIRGIN_TO_NORMAL
	jne	checkCaseTwo
	and	ds:[di].DEI_stateFlags, not (mask EIF_REPEAT)
	and	ds:[di].DEI_actFlags, not DE_VIRGIN
	or	ds:[di].DEI_stateFlags, mask EIF_NORMAL
	jmp	common

	; NORMAL => REPEAT
	;
checkCaseTwo:
	cmp	bp, DESC_NORMAL_TO_REPEAT
	jne	checkCaseOne
	and	ds:[di].DEI_stateFlags, not (mask EIF_NORMAL)
	or	ds:[di].DEI_stateFlags, mask EIF_REPEAT
	and	ds:[di].DEI_actFlags, not (DE_TEXT_DIRTY or DE_TIME_DIRTY)
	jmp	common
	
	; NORAML => VIRGIN
	;
checkCaseOne:
	or	ds:[di].DEI_actFlags, DE_VIRGIN
	and	ds:[di].DEI_actFlags, not (DE_TEXT_DIRTY or DE_TIME_DIRTY)
	
	; Now perform the common work - notify the DayPlanObject
	;
common:
	mov	bp, si				; DayEvent handle => BP
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_ETE_UPDATE
	call	ObjCallInstanceNoLock		; notify the DayPlan

	; Re-draw my icon, and update the database
	;
	mov	si, bp				; DayEvent handle => SI
	call	DayEventRedrawIcon		; just do it!
	mov	cl, DBUF_FLAGS			; update the event flags
	mov	ax, MSG_DE_UPDATE		; method to send to myself
	call	ObjCallInstanceNoLock

	.leave
	ret
DayEventChangeState	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSelect, DayEventDeselect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select or de-select this DayEvent

CALLED BY:	DayPlanSelect (MSG_DE_SELECT, MSG_DE_DESELECT)

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance daya
		ES	= DGroup

RETURN:		AX	= MSG_GEN_SET_ENABLED or MSG_GEN_SET_NOT_ENABLED
			  see documentation for DayEventSelectCommon()

DESTROYED:	BL, DI, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/4/90		Initial version
	sean	8/23/95		Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSelect	method dynamic DayEventClass,	MSG_DE_SELECT
	.enter

	or	ds:[di].DEI_actFlags, DE_SELECT	; set the select bit
	mov	ax, CF_INDEX shl 8 or TEXT_COLOR
	call	DayEventSelectCommon		; call for draw update

	; For Responder, when an event is selected, we highlight
	; the time object with a light grey background.
	;
	.leave
	ret
DayEventSelect	endp

DayEventDeselect	method dynamic DayEventClass,	MSG_DE_DESELECT
	.enter
	and	ds:[di].DEI_actFlags, not DE_SELECT	; clear the select bit
	movdw	bxax, es:[eventBGColor]		; background color => AX:BX
	call	DayEventSelectCommon		; call for draw update

	; For Responder, when an event is deselected, we redraw
	; time object's background with the normal white background
	; to erase the grey highlight.
	;
	.leave
	ret
DayEventDeselect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedrawDayEventIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	sends MSG_VIS_DRAW to itself so that hyphen is redrawn

CALLED BY:	DayEventSelect, DayEventDeselect
PASS:		ds:*si	= DayEvent object
		es	= dgroup
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	2/ 4/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSelectCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call for re-draw

CALLED BY:	DayEventSelect, DayEventDeselect

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		AX:BX	= Line color

RETURN:		AX	= MSG_GEN_SET_ENABLED or MSG_GEN_SET_NOT_ENABLED
			  depending upon whether or not this event can be
			  deleted with the "Delete Event" trigger

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventSelectCommon	proc	near
	uses	bp
	.enter

	; Determine if this event can be normally deleted..
	;
	mov_tr	cx, ax
	mov	ax, MSG_GEN_SET_NOT_ENABLED		; assume not normal

	; For Responder, repeat events, to-do events are deletable
	;
	test	ds:[di].DEI_stateFlags, mask EIF_NORMAL 
	jz	continue				; no, so continue
	test	ds:[di].DEI_actFlags, DE_VIRGIN		; a vrigin event ??
	jnz	continue				; can't delete it...
	mov	ax, MSG_GEN_SET_ENABLED		; else enable trigger

	; Create a GState
continue:
	push	ax				; save the method in AX
	push	cx				; save half of the color info
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; GState => BP

	; Draw the select
	;
	mov	di, bp				; GState to DI
	pop	ax				; color info => AX:BX
	call	GrSetLineColor			; set the line color
	clr	cl				; no DrawFlags
	mov	ax, MSG_DE_DRAW_SELECT
	call	ObjCallInstanceNoLock		; send draw to myself
	call	GrDestroyState 			; kill the GState	
	pop	ax				; restore method => AX

	.leave
	ret
DayEventSelectCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextShowSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure the selection is visible in the DayPlan, by scrolling
		if necessary.

CALLED BY:	TextObject (MSG_VIS_TEXT_SHOW_SELECTION)

PASS:		DS:*SI	= MyText instance data
		SS:BP	= VisTextShowSelectionArgs

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	cbh	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextShowSelection	method MyTextClass, 	MSG_VIS_TEXT_SHOW_SELECTION

	test	ds:[di].VTI_intSelFlags, mask VTISF_IS_TARGET
	jz	exit				; if not target, do nothing
	test	ds:[di].VTI_intSelFlags, mask VTISF_DOING_DRAG_SELECTION
						; if dragging, exit (handled by
	jnz	exit				; port window)

	; Set-up the ScrollIntoSubview arguments
	;
	; Now send this to the DayPlanObject, via the queue.  We go via
	; the queue to ensure the height of the DayPlan is updated after
	; the height of a text object has been altered.
	;
	mov	ax, MSG_DP_SCROLL_INTO_SUBVIEW
	mov	bx, ds:[LMBH_handle]		; DayPlan OD => BX:SI
	mov	si, offset DayPlanObject
	mov	di, mask MF_STACK or mask MF_FORCE_QUEUE
	mov	dx, size MakeRectVisibleParams	; # of bytes on the stack
	call	ObjMessage_dayevent
exit:
	ret
MyTextShowSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextShowPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure that the object is not marked as targetable, or
		else there are bizarre cases where the time object
		is not properly re-drawn (changes in justification combined
		with the tricks Calendar already plays seems to cause the
		problem).

CALLED BY:	TextObject (MSG_VIS_TEXT_SHOW_POSITION)

PASS:		DS:*SI	= MyText object
		DS:DI	= VisTextInstance
		DX.CX	= Position to display

RETURN:		see MSG_VIS_TEXT_SHOW_POSITION

DESTROYED:	see MSG_VIS_TEXT_SHOW_POSITION

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/14/99	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextShowPosition	method dynamic	MyTextClass,
				 	MSG_VIS_TEXT_SHOW_POSITION
		.enter
	;
	; Just pass the message on to our superclass, after clearing
	; a bit. Of course, remember that we need to restore that bit.
	;
		test	ds:[di].VTI_state, mask VTS_TARGETABLE
		pushf
		andnf	ds:[di].VTI_state, not (mask VTS_TARGETABLE)
		mov	di, offset MyTextClass
		call	ObjCallSuperNoLock
		mov	di, ds:[si]
		add	di, ds:[di].VisText_offset
		popf
		jz	done
		ornf	ds:[di].VTI_state, mask VTS_TARGETABLE
done:
		.leave
		ret
MyTextShowPosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MyTextScrollOneLine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Scroll a single-line text object onto the screen

CALLED BY:	GLOBAL (MSG_VIS_TEXT_SCROLL_ONE_LINE)

PASS:		*DS:SI	= MyTextClass object
		CX	= Position to make visible

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/15/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MyTextScrollOneLine	method dynamic	MyTextClass,
					MSG_VIS_TEXT_SCROLL_ONE_LINE

	; We are a one-line text object, but we are inside of a scrolling
	; view. The text object doesn't handle this case, so it sends out
	; this simpler message, rather than MSG_VIS_TEXT_SHOW_SELECTION.
	; All we do is set up the VisTextShowSelectionArgs, and then
	; send the appropriate message to ourself
	;
	push	cx
	sub	sp, size VisTextShowSelectionArgs
	mov	bp, sp
	clr	ax
	mov	cx, ds:[di].VI_bounds.R_left
	movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_left, axcx
	mov	cx, ds:[di].VI_bounds.R_top
	movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_top, axcx
	mov	cx, ds:[di].VI_bounds.R_right
	movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_right, axcx
	mov	cx, ds:[di].VI_bounds.R_bottom
	movdw	ss:[bp].VTSSA_params.MRVP_bounds.RD_bottom, axcx
	mov	ss:[bp].VTSSA_params.MRVP_xMargin, MRVM_50_PERCENT
	mov	ss:[bp].VTSSA_params.MRVP_xFlags, ax
	mov	ss:[bp].VTSSA_params.MRVP_yMargin, MRVM_50_PERCENT
	mov	ss:[bp].VTSSA_params.MRVP_yFlags, ax
	mov	ss:[bp].VTSSA_flags, ax
	mov	ax, MSG_VIS_TEXT_SHOW_SELECTION
	call	ObjCallInstanceNoLock
	add	sp, size VisTextShowSelectionArgs

	; Now call our superclass
	;
	mov	ax, MSG_VIS_TEXT_SCROLL_ONE_LINE
	pop	cx
	mov	di, offset MyTextClass
	GOTO	ObjCallSuperNoLock
MyTextScrollOneLine	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MouseOverIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine whether the mouse is over the bell's bounding box

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		DS:*SI	= DayEvent instance data
		CX	= X mouse position
		DX	= Y mouse position

RETURN:		Carry	= Set if over
			= Clear if not over

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MouseOverIcon	proc	near
	class	DayEventClass			; friend to this class
	uses	ax, bx
	.enter

	; See if alarms are on
	;
	test	es:[features], mask CF_ALARMS	; clears carry
	jz	done				; not on - so do nothing

	; Get the upper left corner
	;
	mov	bx, ds:[si]			; dereference the handle
	add	bx, ds:[bx].Vis_offset		; access visual data
	mov	ax, ds:[bx].VI_bounds.R_left
	mov	bx, ds:[bx].VI_bounds.R_top

	; Now compare the positions (Y first). Since we center the
	; moniker vertically to account for differences in text
	; height, we don't worry about being exactly over the bell icon
	;
	add	bx, es:[yIconOffset]
	cmp	dx, bx				; check mouse vs. top
	jl	notOver
	add	bx, ICON_HEIGHT
	cmp	dx, bx				; check mouse vs. bottom
	jge	notOver

	; Now look at the y coordinate
	;
	add	ax, EVENT_LR_MARGIN		; add in left margin
	cmp	ax, cx				; check left versus mouse
	jge	notOver
	add	ax, ICON_WIDTH			; right + 1 => AX
	cmp	cx, ax				; check mouse versus right
	jge	notOver
	stc					; it's over the icon!!!
done:
	.leave
	ret
notOver:
	clc
	jmp	done
MouseOverIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventStartAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the selection of a dayevent

CALLED BY:	UI (MSG_META_START_SELECT or MSG_META_START_FEATURES)

PASS:		ES	= DGroup
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
 		CX	= X position of mouse
		DX	= Y position of mouse
		BP	= (low) ButtonInfo
			= (high) instance data

RETURN:		AX	= MRF_PROCESSED or MRF_REPLAY

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventStartAction	method	DayEventClass,	MSG_META_START_SELECT,
						MSG_META_START_FEATURES

	; Is the mouse over the icon ?? Else call my superclass.
	;
	call	MouseOverIcon			; over the icon ??
	jc	overIcon			; yes, mouse is over the icon
	mov	di, offset DayEventClass	; ES:DI is my class
	call	ObjCallSuperNoLock		; send method to my superclass
	jmp	done				; MouseReturnFlags => AX

	; Are we a virgin ?? If so, update the Database and proceed!
	;
overIcon:
	call	UndoNotifyClear			; clear the undo
	test	ds:[di].DEI_actFlags, DE_VIRGIN	; are we a virgin ??
	jnz	exit				; yes, so ignore the action
	test	ds:[di].DEI_stateFlags, mask EIF_REPEAT
	jz	takeGrab			; if not repeat, continue

	; Else must create a real event from the RepeatEvent
	;
	push	bp				; save the mouse flags
	mov	cl, DBUF_NEW			; a new event
	mov	ax, MSG_DE_UPDATE		; send the update method
	call	ObjCallInstanceNoLock		; just do it
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayEvent_offset	; access my instance data
	pop	bp				; restore the mouse flags
	
	; Get all of the exclusives...
	;
takeGrab:
	test	ds:[di].DEI_actFlags, DE_GRAB	; grab already ??
	jnz	exit				; if so, exit
	or	ds:[di].DEI_actFlags, DE_GRAB	; set the grab flag
	test	bp, (mask UIFA_FEATURES) shl 8	; test the features bit
	je	takeExcl			; jump if bit not set
	or	ds:[di].DEI_actFlags, DE_FEATURES
takeExcl:
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL	; get the grab
	mov	cx, ds:[LMBH_handle]		; block handle to CX
	mov	dx, si				; chunk handle to SI
	push	cx, dx				; save the OD
	call	VisCallParent			; notify my parent
	pop	cx, dx				; restore the OD
	call	VisGrabMouse			; grab that mouse
	call	MetaGrabFocusExclLow		; grab the focus excl
	call	MetaGrabTargetExclLow		; and the target exclusive
	mov	ax, mask MRF_PROCESSED		; we've process the event

	; Now grab the selection iff we've processed the event
done:
	cmp	ax, mask MRF_PROCESSED		; take the event ??
	jne	quit				; no - we're done
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayEvent_offset	; access my instance data
	test	ds:[di].DEI_actFlags, DE_SELECT	; are we already selected ??
	jnz	quit				; if so, don't notify anyone
	mov	bp, si				; my handle to BP
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_SET_SELECT
	call	ObjCallInstanceNoLock
exit:						; take event, not select
	mov	ax, mask MRF_PROCESSED		; yes, we swallowed the event
quit:
	ret
DayEventStartAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventEndAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	End the selection - toggle the alarm

CALLED BY:	UI (MSG_META_END_SELECT or MSG_META_END_FEATURES)

PASS:		CX	= X position of the mouse
		DX	= Y position of the mouse
		BP	= (low) ButtonInfo
			= (high) UIFunctionsActive
		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data

RETURN:		AX	= MRF_PROCESSED or MRF_REPLAY

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/18/89	Initial version
	Don	5/24/90		Cleaned up, & force mouse release

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventEndAction	method	DayEventClass,	MSG_META_END_SELECT, \
						MSG_META_END_FEATURES
	
	; Do we have the grab ??  The right action ??
	;
	test	ds:[di].DEI_actFlags, DE_GRAB	; do we have the grab ??
	jz	quit				
	test	ds:[di].DEI_actFlags, DE_FEATURES ; want SELECT or FEATURES ?
	jne	testFeatures			; jump if bit set
	test	bp, (mask UIFA_SELECT) shl 8	; test the SELECT bit
	jz	process				; go process the event if clear
quit:
	mov	ax, mask MRF_REPLAY		; we didn't want the event
	ret
testFeatures:
	test	bp, (mask UIFA_FEATURES) shl 8	; test the FEATURES bit
	jnz	quit				; if still set, jump

	; Was the mouse released over the bell icon ??
process:
	call	MouseOverIcon
	jc	overBell			; over the bell - process it
	mov	di, offset DayEventClass	; else notify my superclass
	call	ObjCallSuperNoLock
	ret

	; Now perform the correct action
overBell:
	test	ds:[di].DEI_actFlags, DE_FEATURES
	jne	performFeatures
	call	DayEventToggleAlarm
	jmp	done
performFeatures:
	push	si				; save the DayEvent handle
	GetResourceHandleNS	EditAlarm, bx	; Trigger OD => BX:SI
	mov	si, offset EditAlarm
	mov	ax, MSG_GEN_TRIGGER_SEND_ACTION	; method to send
	call	ObjMessage_dayevent_call	; send the method
	pop	si				; restore the DayEvent handle

	; Call for the exclusive to be released
done:
	mov	ax, MSG_VIS_LOST_GADGET_EXCL	; method to send
	call	ObjCallInstanceNoLock		; send it to myself
mouseProcessed	label	near
	mov	ax, mask MRF_PROCESSED
	ret
DayEventEndAction	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventDragSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This method gets sent out to initiate drag selection. Until
		A UI fix occurs, intercept this method and bury it if the
		DayEvent already has the grab.

CALLED BY:	UI (MSG_META_DRAG_SELECT)
	
PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		CX, DX, BP	= Data
		AX	= Method
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventDragSelect	method	DayEventClass,	MSG_META_DRAG_SELECT

	test	ds:[di].DEI_actFlags, DE_GRAB	; do we have the grab ??
	jnz	mouseProcessed			; yes, so do nothing
	mov	di, offset DayEventClass	; ES:DI is my class
	GOTO	ObjCallSuperNoLock		; pass on the method
DayEventDragSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventLostExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Lost the exclusive - release the mouse grab

CALLED BY:	UI (MSG_VIS_LOST_GADGET_EXCL)

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventLostExcl	method	DayEventClass, MSG_VIS_LOST_GADGET_EXCL

	; Release & call superclass
	;
	and	ds:[di].DEI_actFlags, not (DE_GRAB or DE_FEATURES)
	call	VisReleaseMouse			; release that mouse
	mov	di, offset DayEventClass	; ES:DI class to call super of
	call	ObjCallSuperNoLock		; call my superclass!
	ret
DayEventLostExcl	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventToggleAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Toggle the alarm on/off

CALLED BY:	DayEventEndAction

PASS:		DS:*SI	= DayEvent instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/19/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventToggleAlarm	proc	far
	class	DayEventClass			; friend to this class

	; Toggle the alarm on/off
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayEvent_offset	; access instance data
	xor	ds:[di].DEI_stateFlags, mask EIF_ALARM_ON

	; Now update the alarm information, and re-draw the icon
DayEventUpdateAlarm	label	far
	ON_STACK	retf
	mov	cl, DBUF_FLAGS
	mov	ax, MSG_DE_UPDATE
	call	ObjCallInstanceNoLock		; update the database
	call	DayEventRedrawIcon
	ret
DayEventToggleAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventRedrawIcon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Redraw the DayEvent icon, whatever it may be

CALLED BY:	DayEventToggleAlarm, DayEventChangeState

PASS:		DS:*SI	= DayEvent instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventRedrawIcon	proc	near
	.enter

	; Draw the new icon
	;
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock		; GState => BP

	; Set up the clip region
	;
	push	si				; save the DayEvent handle
	call	VisGetBounds			; get my bounds
	add	ax, EVENT_LR_MARGIN		; calculate left bound
	inc	bx
	mov	cx, ax
	add	cx, (ICON_WIDTH - 1)		; calculate right bound
	dec	dx
	mov	di, bp				; GState to DI
	mov	si, PCT_REPLACE			; replace the clip region
	call	GrSetClipRect			; set the clip region

	; Draw the bitmap
	;
	pop	si				; restore DayEvent handle
	push	bp				; save the GState
	mov	ax, MSG_VIS_DRAW
	clr	cl				; send no flags
	call	ObjCallInstanceNoLock		; send draw to myself
	pop	di				; restore the GState
	call	GrDestroyState 			; kill the GState	

	.leave
	ret
DayEventRedrawIcon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetRepeatType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the frequency type for an event. (i.e. one-time,
		weekly, etc)

CALLED BY:	MSG_DE_GET_REPEAT_TYPE
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		ax	= EventOptionsTypeType (bad type name huh?)
		if repeat until...
			bp = repeat until year
			dx = repeat until month/day
			carry set
		else
			dx, bp = CAL_NO_DATE
			carry cleared
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/17/96   	Initial version (mostly stolen from
				"SetEventType")

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventReplaceText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the text of the event obj with text referenced
		by a pointer.

CALLED BY:	MSG_DE_REPLACE_TEXT
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		dx:bp	= Pointer to the text string
		cx	= String length, or 0 if null-terminated
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 9/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventReplaceText	method dynamic DayEventClass, 
					MSG_DE_REPLACE_TEXT
		uses	ax, cx, dx, bp
		.enter
	;
	; Send the message to our text object.
	;
		mov	si, ds:[di].DEI_textHandle	; *ds:si = text obj
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock		; ax, cx, dx, bp gone
		
		.leave
		ret
DayEventReplaceText	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetTextAllPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replace the text of the event obj with text referenced
		by a pointer.

CALLED BY:	MSG_DE_GET_TEXT_ALL_PTR
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		dx:bp	= Pointer to the text string
RETURN:		cx	= String length not counting the NULL
		dx:bp	= Unchanged
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/15/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventGetTextAllPtr	method dynamic DayEventClass, 
					MSG_DE_GET_TEXT_ALL_PTR
		.enter
	;
	; Send the message to our text object.
	;
		mov	si, ds:[di].DEI_textHandle	; *ds:si = text obj
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	ObjCallInstanceNoLock		; buffer filled,
							; cx <- length,
							; ax destroyed
		.leave
		ret
DayEventGetTextAllPtr	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetStateFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the DEI_stateFlags of the event obj.

CALLED BY:	MSG_DE_GET_STATE_FLAGS
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		al	= EventInfoFlags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/18/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventGetStateFlags	method dynamic DayEventClass, 
					MSG_DE_GET_STATE_FLAGS
		.enter
		mov	al, ds:[di].DEI_stateFlags
		.leave
		ret
DayEventGetStateFlags	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetStateFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the DEI_stateFlags of the event obj.

CALLED BY:	MSG_DE_SET_STATE_FLAGS
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cl	= EventInfoFlags
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/14/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventSetStateFlags	method dynamic DayEventClass, 
					MSG_DE_SET_STATE_FLAGS
		uses	ax, cx
		.enter
		Assert	record, cl, EventInfoFlags
		ornf	ds:[di].DEI_stateFlags, cl
	;
	; update event
	;
		mov	ax, MSG_DE_UPDATE
		mov	cl, DBUF_FLAGS
		call	ObjCallInstanceNoLock

		.leave
		ret
DayEventSetStateFlags	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the alarm time for an event.

CALLED BY:	MSG_DE_GET_ALARM
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		if event has alarm:
			bp	= Year
			dx	= Month/Day
			cx	= Hour/Minute
			carry	= set
		else
			carry	= clear
			cx, dx, bp not changed
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	11/17/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventGetAlarm	method dynamic DayEventClass, 
					MSG_DE_GET_ALARM
		.enter
	;
	; Does event have alarm?
	;
		test	ds:[di].DEI_stateFlags, mask EIF_ALARM_ON
		clc					; assume no alarm
		jz	quit
	;
	; Just return the values.
	;
		mov	bp, ds:[di].DEI_alarmYear
		mov	dx, {word} ds:[di].DEI_alarmDay
		mov	cx, {word} ds:[di].DEI_alarmMinute
		stc					; I have alarm
quit:
		.leave
		ret
DayEventGetAlarm	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventUseNextBookID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Mark that the next book ID be used, and return that 
		value.

CALLED BY:	MSG_DE_USE_NEXT_BOOK_ID
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		cx	= book ID to be used
DESTROYED:	ax
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		HACK ALERT: because we are running out of bits in
		DataBaseUpdateFlags, we use DBUF_MEMO; hence 
		DBUpdateMemo has to update DEI_sentToArrayBlock /
		DEI_sentToArrayChunk / DEI_nextBookID too.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 3/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventUseNextBookID	method dynamic DayEventClass, 
					MSG_DE_USE_NEXT_BOOK_ID
		.enter
	;
	; Return ID.
	;
		mov	cx, ds:[di].DEI_nextBookID
	;
	; This ID is used, so update next book id.
	;
		inc	ds:[di].DEI_nextBookID
	;
	; update event
	;
		push	cx
		mov	ax, MSG_DE_UPDATE
		mov	cl, DBUF_MEMO
		call	ObjCallInstanceNoLock		; nothing destroyed
		pop	cx
		
		.leave
		Destroy	ax
		ret
DayEventUseNextBookID	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetNextBookID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the next book ID

CALLED BY:	MSG_DE_SET_NEXT_BOOK_ID
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
                ds:bx   = DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cx	= book ID to set		
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	** NOTES **

	Only the DayEvent instance data is updated. The datebase is not
	updated 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 5/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventSetNextBookID	method dynamic DayEventClass, 
					MSG_DE_SET_NEXT_BOOK_ID
		.enter

		mov	ds:[di].DEI_nextBookID, cx
	
		.leave
		ret
DayEventSetNextBookID	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventAddSentToInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add the sent-to information (with the name / sms
		number / contact ID / book ID etc in instance data of
		CalendarAddressCtrlClass object.)

CALLED BY:	MSG_DE_ADD_SENT_TO_INFO
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If (there is no ChunkArray created for sent-to info
		yet) {
			CreateEventSentToArray
		}

		Lock down chunk array of EventSentToStruct.

		Append an empty element.

		Call BookingSMSAddressControl to fill in the element.

		quit

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/29/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventAddSentToInfo	method dynamic DayEventClass, 
					MSG_DE_ADD_SENT_TO_INFO
		.enter
		segmov	es, ds, ax
	;
	; Should we create chunk array?
	;
		tst	es:[di].DEI_sentToArrayBlock
		jnz	hasArray
	;
	; Create array.
	;
		call	CreateEventSentToArray		; carry set if error
		jc	quit
hasArray:
	;
	; Redereference.
	;
		mov	di, es:[si]
		add	di, es:[di].DayEvent_offset
	;
	; Get ChunkArray locked down.
	;
		mov	ax, es:[di].DEI_sentToArrayBlock
		mov	si, es:[di].DEI_sentToArrayChunk
		call	LockChunkArray			; *ds:si <- array,
							;  bp <- mem handle
							;  ax, bx destroyed
	;
	; Create item. Element size is fixed.
	;
		call	ChunkArrayAppend		; carry set if error,
							; else ds:di <- element
EC <		ERROR_C	CALENDAR_NO_MEMORY_FOR_SENT_TO_INFO		>
		jc	unlockQuit
	;
	; Call BookingSMSAddressControl to fill in the struct.
	;
		mov	bx, handle BookingSMSAddressControl
		mov	si, offset BookingSMSAddressControl
		mov	cx, ds
		mov	dx, di				; cx:dx <- element
		mov	ax, MSG_CALENDAR_ADDRESS_CTRL_COPY_SENT_TO_INFO
		call	ObjMessage_dayevent_call	; ax, di destroyed
unlockQuit:
	;
	; Unlock vm block
	;
		; bp == VM mem handle
		Assert	vmMemHandle, bp
		call	VMDirty
		call	VMUnlock		
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
DayEventAddSentToInfo	endm

;
; SYNOPSIS:	Lock the sent-to chunk array.
;
; CALLED BY:	(INTERNAL) DayEventAddSentToInfo
; PASS:		ax	= array block
;		si	= array chunk
; RETURN:	*ds:si	= chunk array
;		bp	= memory handle
; DESTROYED:	ax, bx
; SIDE EFFECTS:	MUST call VMUnlock on the memory handle later.
; 

LockChunkArrayFar	proc	far
		.enter

		call	LockChunkArray

		.leave
		ret
LockChunkArrayFar	endp
		
LockChunkArray	proc	near
		.enter
	;
	; Get ChunkArray locked down.
	;
		GetResourceSegmentNS	dgroup, ds
		mov	bx, ds:[vmFile]
		Assert	vmFileHandle, bx
		call	VMLock				; ax <- segment,
							;  bp <- memory handle
		mov_tr	ds, ax
		Assert	ChunkArray, dssi
		
		.leave
		ret
LockChunkArray	endp

endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateEventSentToArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a EventSentToStruct chunk array and add
		handle/chunk to instance data.

CALLED BY:	(INTERNAL) DayEventAddSentToInfo
PASS:		*es:si	= DayEventClass object
		es:di	= DayEventClass instance data
RETURN:		carry set if error (creation failed)
		carry clear otherwise
DESTROYED:	nothing
	WARNING:  This routine MAY resize LMem and/or object blocks, moving
		  them on the heap and invalidating stored segment pointers
		  and current register or stored offsets to them.

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Allocate lmem block in vmfile.

		Create chunk array.

		Store chunk array block/chunk to instance.

		Update database. HACK ALERT: because we are running out of
		bits in DataBaseUpdateFlags, we use DBUF_MEMO; hence
		DBUpdateMemo has to update DEI_sentToArrayBlock /
		DEI_sentToArrayChunk / DEI_nextBookID too.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	1/31/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
CreateEventSentToArray	proc	near
		uses	ax, bx, cx, ds, si, es, bp
		.enter
		Assert	objectPtr, essi, DayEventClass
	;
	; Allocate LMem first.
	;
		GetResourceSegmentNS	dgroup, ds
		mov	ax, LMEM_TYPE_GENERAL
		mov	bx, ds:[vmFile]
		clr	cx				; no header
		call	VMAllocLMem			; ax <- VMBlock handle
		mov	es:[di].DEI_sentToArrayBlock, ax
	;
	; Create a chunk array.
	;
		push	si
		call	VMLock				; ax <- VMBlock segment
							;  bp <- Memory handle
		mov_tr	ds, ax				; ds <- VMBlock segment
		mov	bx, size EventSentToStruct	; bx <- element size
		mov	cx, size EventSentToHeader	; cx <- header size
		clr	ax, si
		call	ChunkArrayCreate		; si <- chunk handle
EC <		WARNING_C CALENDAR_NO_MEMORY_FOR_SENT_TO_INFO		>
		mov	ax, si				; ax <- chunk handle
		jc	unlockQuit
	;
	; Set default info in header.
	;
		mov	si, ds:[si]			; ds:si <-
							;  EventSentToHeader 
		LocalClrChar ds:[si].ESTH_senderSMS
		movdw	ds:[si].ESTH_senderEventID, INVALID_EVENT_ID
		clr	ds:[si].ESTH_senderBookID
unlockQuit:
	;
	; Unlock VM block.
	;
		call	VMDirty
		call	VMUnlock			; ds destroyed

		pop	si				; *es:si <- obj
		jc	noMem				; no memory
	;
	; Store chunk.
	;
		mov	es:[di].DEI_sentToArrayChunk, ax
	;
	; Update database because instance is changed, and it needs to
	; go to EventStruct. See notes above on why DBUF_MEMO is used.
	;
		segmov	ds, es, ax
		mov	ax, MSG_DE_UPDATE
		mov	cl, DBUF_MEMO
		call	ObjCallInstanceNoLock		; ax, es destroyed

		clc					; no error
quit:
		.leave
		ret
noMem:
	;
	; Free the lmem block allocated, and mark that we don't have
	; array.
	;
		clr	ax
		xchg	ax, es:[di].DEI_sentToArrayBlock
		GetResourceSegmentNS	dgroup, ds
		mov	bx, ds:[vmFile]
		call	VMFree
		stc					; error
		jmp	quit

CreateEventSentToArray	endp
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventAddSenderInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the sent-to chunk array, and put sender info into
		chunk array header.

CALLED BY:	MSG_DE_ADD_SENDER_INFO
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cx	= segment of MBAppointment struct
RETURN:		carray	= set if error (not enough disk space)
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Create sent-to array, if none exists.
		Lock down sent-to array.
		Copy sender event ID
			(header.ESTH_senderEventID := MBAppointment.eventID)
		Copy sender book ID.
			(header.ESTH_senderBookID := MBAppointment.bookID)
		Copy sender sms.
			(header.ESTH_senderSMS := MBAppointment.sms num)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 8/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventAddSenderInfo	method dynamic DayEventClass, 
					MSG_DE_ADD_SENDER_INFO
		.enter
		Assert	segment, cx
	;
	; Should we create chunk array?
	;
		tst	ds:[di].DEI_sentToArrayBlock
		jnz	hasArray
	;
	; Create array.
	;
		segmov	es, ds, ax
		call	CreateEventSentToArray		; carry set if error
		jc	quit
hasArray:
	;
	; Redereference.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DayEvent_offset
	;
	; Get ChunkArray locked down.
	;
		mov	ax, ds:[di].DEI_sentToArrayBlock
		mov	si, ds:[di].DEI_sentToArrayChunk
		call	LockChunkArray			; *ds:si <- array,
							;  bp <- mem handle
							;  ax, bx destroyed
		segmov	es, ds, ax			; *es:si <- array
		mov	si, es:[si]			; es:si <-
							;  EventSentToHeader
	;
	; Put sender info to array header.
	;
		mov	ds, cx				; ds <- MBAppointment
							;  struct
	;
	; Sender event ID.
	;
		movdw	es:[si].ESTH_senderEventID, \
			 ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderEventID, \
			 cx
	;
	; Sender book ID.
	;
		movm	es:[si].ESTH_senderBookID, \
			 ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderBookID, \
			 cx
	;
	; Copy sender SMS number.
	;
		lea	di, es:[si].ESTH_senderSMS	; es:di <- source
		lea	si, ds:[CALENDAR_ESCAPE_DATA_OFFSET].CAET_senderAddress
							; ds:si <- source
		LocalCopyString				; si, di, ax destroyed
	;
	; Unlock vm block
	;
		; bp == VM mem handle
		Assert	vmMemHandle, bp
		call	VMDirty
		call	VMUnlock

		clc					; no error
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
DayEventAddSenderInfo	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetSentToChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the block / chunk handle of sent-to array.

CALLED BY:	MSG_DE_GET_SENT_TO_CHUNK_ARRAY
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		cx	= block handle
		dx	= chunk handle
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/11/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventGetSentToChunkArray	method dynamic DayEventClass, 
					MSG_DE_GET_SENT_TO_CHUNK_ARRAY
		.enter
	;
	; Just do it.
	;
		mov	cx, ds:[di].DEI_sentToArrayBlock
		mov	dx, ds:[di].DEI_sentToArrayChunk
		
		.leave
		ret
DayEventGetSentToChunkArray	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetSentToChunkArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the block / chunk handle of sent-to array.

CALLED BY:	MSG_DE_SET_SENT_TO_CHUNK_ARRAY
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
                ds:bx   = DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cx	= VM block handle
		dx	= chunk handle
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	** NOTES **

	Only the DayEvent instance data is updated. The datebase is not
	updated 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 6/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventSetSentToChunkArray	method dynamic DayEventClass, 
					MSG_DE_SET_SENT_TO_CHUNK_ARRAY
		.enter
EC <		push	es						>
EC <		GetResourceSegmentNS	dgroup, es			>
		Assert	vmBlock	cx, es:[vmFile]
EC <		pop	es						>

		mov	ds:[di].DEI_sentToArrayBlock, cx
		mov	ds:[di].DEI_sentToArrayChunk, dx

		.leave
		ret
DayEventSetSentToChunkArray	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetSentToCount
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the count of sent-to struct in the sent-to array.

CALLED BY:	MSG_DE_GET_SENT_TO_COUNT
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		cx	= count
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	2/ 8/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventGetSentToCount	method dynamic DayEventClass, 
					MSG_DE_GET_SENT_TO_COUNT
		uses	ax, bp
		.enter
	;
	; Do we have any EventSentToStruct chunk array?
	;
		mov	cx, ds:[di].DEI_sentToArrayBlock
		jcxz	quit

		mov_tr	ax, cx
		mov	si, ds:[di].DEI_sentToArrayChunk
	;
	; Get ChunkArray locked down.
	;
		; ax:si == Block/Chunk
		call	LockChunkArray			; *ds:si <- array,
							;  bp <- mem handle
							;  ax, bx destroyed
		call	ChunkArrayGetCount		; cx <- count
	;
	; Unlock vm block
	;
		; bp == VM mem handle
		Assert	vmMemHandle, bp
		call	VMUnlock			; ds destroyed
quit:
		.leave
		ret
DayEventGetSentToCount	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		DayEventUpdateAppointmentIfNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the booking in sent-to list, if the event
		time/text is changed.

CALLED BY:	MSG_DE_UPDATE_APPOINTMENT_IF_NECESSARY
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/ 4/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventUpdateAppointmentIfNecessary	method dynamic DayEventClass, 
					MSG_DE_UPDATE_APPOINTMENT_IF_NECESSARY
		.enter
	;
	; Get our booking flags, and then clear it.
	;
		clr	dx
		xchg	dx, ds:[di].DEI_bookingFlags
	;
	; Do we have sent-to info? If not, we skip the whole thing.
	;
		mov	ax, MSG_DE_GET_SENT_TO_COUNT
		call	ObjCallInstanceNoLock		; cx <- count
		jcxz	done
	;
	; Is our time/text changed since last time the details dialog
	; is opened? To check, we look at booking flags.
	;
		test	dx, mask DEBF_TIME_CHANGED or \
				mask DEBF_NON_TIME_CHANGE or \
				mask DEBF_CANCEL_ALL_BOOKING
		jz	done
	;
	; Does user want to do update?
	;
		mov	bp, si				; bp <- chunk handle
		mov	si, dx
		
		mov	cx, handle ShouldUpdateBeMadeQuestion
		mov	dx, offset ShouldUpdateBeMadeQuestion
		call	FoamDisplayQuestion		; ax <- IC_YES/...
							;  carry set if no
		jc	done
	;
	; Call process a message to send update SMS.
	;
		; si == DayEventBookingFlags
		; bp == DayEvent chunk handle
		call	GeodeGetProcessHandle		; bx <- process
		mov	ax, MSG_CALENDAR_UPDATE_APPOINTMENT
		mov	cx, ds:[di].DEI_sentToArrayBlock
		mov	dx, ds:[di].DEI_sentToArrayChunk
		mov 	di, mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp gone
		
done:
		.leave
		Destroy	ax, cx, dx, bp
		ret
DayEventUpdateAppointmentIfNecessary	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventCancelAllAppointment
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cancel all booking in sent-to list, if the user
		wants to.

CALLED BY:	MSG_DE_CANCEL_ALL_APPOINTMENT
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/14/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventCancelAllAppointment	method dynamic DayEventClass, 
					MSG_DE_CANCEL_ALL_APPOINTMENT
		.enter
	;
	; Set the booking flag.
	;
		mov	ds:[di].DEI_bookingFlags, mask DEBF_CANCEL_ALL_BOOKING
	;
	; Call myself a message.
	;
		mov	ax, MSG_DE_UPDATE_APPOINTMENT_IF_NECESSARY
		call	ObjCallInstanceNoLock		; ax, cx, dx, bp gone

		.leave
		Destroy	ax, cx, dx, bp
		ret
DayEventCancelAllAppointment	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the end time of the event obj.

CALLED BY:	MSG_DE_SET_END_TIME
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cx	= end time (Hour/Min)
RETURN:		carry set if error (end time earlier than start time)
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/ 9/96   	Initial version
	simon	2/12/97		Do not check end time against start time if
				this is reserved whole day event or if end
				date is later than start date

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	END_TIMES
DayEventSetEndTime	method dynamic DayEventClass, 
					MSG_DE_SET_END_TIME
		.enter

		Assert	urange, ch, 0, 23
		Assert	urange, cl, 0, 59

	;
	; See if end time is earlier than start time.
	;
		CheckHack <((offset DEI_timeMinute)+1) eq (offset DEI_timeHour)>
		cmp	cx, {word} ds:[di].DEI_timeMinute
EC <		WARNING_BE END_TIME_EARLIER_THAN_OR_SAME_AS_START	>
		jbe	error

setEndTime::
		ornf	ds:[di].DEI_varFlags, mask VLF_END_TIME
		mov	{word} ds:[di].DEI_endMinute, cx
	;
	; Update the event.
	;
		mov	ax, MSG_DE_UPDATE
		mov	cl, DBUF_VARLEN
		call	ObjCallInstanceNoLock
		clc					; no error
quit:
		.leave
		ret
error:
		stc
		jmp	quit
DayEventSetEndTime	endm
endif		; END_TIMES


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetUniqueID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the unique ID of the event obj.

CALLED BY:	MSG_DE_GET_UNIQUE_ID
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
		ds:bx	= DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
RETURN:		cxdx	= unique ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/12/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	UNIQUE_EVENT_ID
DayEventGetUniqueID	method dynamic DayEventClass, 
					MSG_DE_GET_UNIQUE_ID
		.enter
	;
	; Just return the unique ID from instance data.
	;
		movdw	cxdx, ds:[di].DEI_uniqueID
		
		.leave
		ret
DayEventGetUniqueID	endm
endif	; UNIQUE_EVENT_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventSetUniqueID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the unique ID of the event obj.

CALLED BY:	MSG_DE_SET_UNIQUE_ID
PASS:		*ds:si	= DayEventClass object
		ds:di	= DayEventClass instance data
                ds:bx   = DayEventClass object (same as *ds:si)
		es 	= segment of DayEventClass
		ax	= message #
		cxdx	= unique ID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	
	** NOTES **

	Only the DayEvent instance data is updated. The datebase is not
	updated 

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	3/ 5/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	UNIQUE_EVENT_ID
DayEventSetUniqueID	method dynamic DayEventClass, 
					MSG_DE_SET_UNIQUE_ID
		.enter
		Assert	eventID	cxdx

		movdw	ds:[di].DEI_uniqueID, cxdx
		
		.leave
		ret
DayEventSetUniqueID	endm
endif	; UNIQUE_EVENT_ID



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventMarkBookingUpdateNecessary
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change object flags to mark that booking update is
		necessary on the day event.

CALLED BY:	(INTERNAL) DayEventInit, DayEventInitRepeat
		NormalToRepeatCommon, DayEventUpdate
PASS:		*ds:si	= DayEventClass instance data
		ax	= DayEventBookingFlags to add
RETURN:		ds:di	= DayEventClass instance data
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/ 5/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayEventMarkBookingUpdateNecessary	proc	near
		.enter
		Assert	objectPtr, dssi, DayEventClass
		Assert	record, ax, DayEventBookingFlags
	;
	; Redereference.
	;
		mov	di, ds:[si]
		add	di, ds:[di].DayEvent_offset
	;
	; Add flags.
	;
		ornf	ds:[di].DEI_bookingFlags, ax

		.leave
		ret
DayEventMarkBookingUpdateNecessary	endp
endif	; HANDLE_MAILBOX_MSG

if	0
ObjMessage_dayevent_send	proc	near
	clr	di
	GOTO	ObjMessage_dayevent
ObjMessage_dayevent_send	endp
endif

ObjMessage_dayevent_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	FALL_THRU	ObjMessage_dayevent
ObjMessage_dayevent_call	endp

ObjMessage_dayevent	proc	near
	call	ObjMessage
	ret
ObjMessage_dayevent	endp

DayEventCode	ends



UndoActionCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventGetDatabase
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current database group:item

CALLED BY:	GLOBAL

PASS:		DS:DI	= DayEventClass specific instance data

RETURN:		CX	= Group
		DX	= Item

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventGetDatabase	method	DayEventClass,	MSG_DE_GET_DATABASE
	.enter

	mov	cx, ds:[di].DEI_DBgroup		; group => CX
	mov	dx, ds:[di].DEI_DBitem		; item => DX

	.leave
	ret
DayEventGetDatabase	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventRetrieveText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Retrieve the current time & event text displayed

CALLED BY:	GLOBAL

PASS:		DS:*SI	= DayEvent instance data
		CX	= Group # of text block
		DX	= Item # of text block

RETURN:		AX	= Length of the text stored

DESTROYED:	BX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version
	Don	1/22/90		Modified to only replace one text buffer

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventRetrieveText	method	DayEventClass,	MSG_DE_RETRIEVE_TEXT
	uses	cx, dx, bp
	.enter

	; Some set-up work
	;
	mov	di, si				; the DayEvent => DI
	mov	si, ds:[di]			; dereference the handle
	add	si, ds:[si].DayEvent_offset	; point to instance data
	mov	si, ds:[si].DEI_textHandle	; text handle => SI

	; Resize the text block
	;
	push	cx, dx				; save the group & item numbers
	mov	ax, MSG_VIS_TEXT_GET_TEXT_SIZE
	call	ObjCallInstanceNoLock		; get size of time
	mov_tr	cx, ax
	inc	cx				; room for the NULL
	pop	ax, bp				; group => AX, item => DI
	xchg	di, bp
DBCS <	shl	cx, 1				; need size in bytes	>
	call	GP_DBReAlloc			; resize the item
DBCS <	shr	cx, 1				; restore length 	>
	dec	cx				; true size to CX
	push	cx, bp				; text length, DayEvent handle

	; Now get the text
	;
	call	GP_DBLockDerefDI		; lock the block
	mov	dx, es
	mov	bp, di				; CX:DX points to the buffer
	mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
	call	ObjCallInstanceNoLock
	call	DBUnlock			; unlock the block

	; Call for DayEvent to be re-stuffed
	;
	pop	si				; DS:*SI = DayEvent handle
	call	StuffTextStringFar		; stuff the text string
	pop	ax				; returns the text length

	.leave
	ret
DayEventRetrieveText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayEventRedisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-display the time & text after a state change

CALLED BY:	UndoActionStateRestore

PASS:		DS:*SI	= DayEventClass instance data
		DS:DI	= DayEventClass specific instance data
		CX	= New Hour/Minute

RETURN:		CX	= Old Hour/Minute

DESTROYED:	AX, BX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayEventRedisplay	method	DayEventClass,	MSG_DE_REDISPLAY
	.enter

	; Re-stuff the strings
	;
	push	{word} ds:[di].DEI_timeMinute	; save the old time
	mov	ax, MSG_DE_SET_TIME		; reset the time, alarm...
	call	ObjCallInstanceNoLock		; ...and re-stuff the time
	call	StuffTextStringFar		; redisplay the event text
	pop	cx				; and restore it

	.leave
	ret
DayEventRedisplay	endp

UndoActionCode	ends

