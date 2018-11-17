 COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Alarm
FILE:		alarmReminder.asm

AUTHOR:		Don Reeves, August 23, 1990

ROUTINES:
	Name			Description
	----			-----------
	AlarmCheckActive	Bring down alarm if matches criteria
	AlarmToScreen		Puts an alarm on the screen
	AlarmDestroy		Destroys a reminder previosuly created
	AlarmSnooze		Causes alarm to come down; resets alarm time
	ReminderStoreEvent	Stores event with associated reminder
	ReminderStoreDateTime	Stores date/time with associated reminder
	ReminderSnooze		Pass snooze method onto process for action
	ReminderDestroy		Visually remove myself, ask process to destroy
	ReminderSelfDestruct	Possibly kill myself or nuke snooze
	ReminderReset		Reset time/date strings - format change
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/23/90		Initial revision
	Don	2/26/91		Moved to different file/module

DESCRIPTION:
		
	$Id: alarmReminder.asm,v 1.1 97/04/04 14:47:14 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	ReminderClass
idata	ends

CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmCheckActive
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check to see if an alarm needs to br brought down at all.

CALLED BY:	GLOBAL (Running in the GeoPlanner thread)
	
PASS:		CX:DX	= EventStruct Group:Item
		CX	= -1 (Bring down all reminders)
		DX	= -1 (Disable snooze on all reminders)
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmCheckActive	proc	far
ifndef	GCM
	.enter

	; Check if any alarm boxes are showing. If none, do nothing
	;
EC <	VerifyDGroupES				; verify it		>
	tst	es:[alarmsUp]			; any alarms visible ??
	jz	done
	push	ax, bx, cx, dx, di, si, bp
	mov	ax, MSG_CALENDAR_KILL_REMINDER	; method to send to window list
						;	entries
	push	es
	GetResourceSegmentNS	ReminderClass, es
	mov	bx, es				; method is for Reminder objs
	pop	es
	mov	si, offset ReminderClass
	mov	di, mask MF_RECORD
	call	ObjMessage			; di = event handle
	mov	dx, size GCNListMessageParams
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].GCNLMP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLMP_ID.GCNLT_type, GAGCNLT_WINDOWS
	mov	ss:[bp].GCNLMP_block, 0
	mov	ss:[bp].GCNLMP_event, di
	mov	ss:[bp].GCNLMP_flags, 0
	mov	ax, MSG_META_GCN_LIST_SEND
	GetResourceHandleNS	Calendar, bx
	mov	si, offset Calendar		; send to my application
	mov	di, mask MF_CALL or mask MF_STACK or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size GCNListMessageParams
	pop	ax, bx, cx, dx, di, si, bp
done:	
	.leave
endif
	ret
AlarmCheckActive	endp

CommonCode	ends



ifndef		GCM
ReminderCode	segment	resource	



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmToScreen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Puts an alarm up on the screen
		
CALLED BY:	AlarmClockTick
		This is run in the GeoPlanner's thread

PASS:		DS	= DGroup
		AX	= EventStruct : Group #
		BP	= EventStruct : Item #
		
RETURN:		ES:*DI	= EventStruct

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/6/89		Initial version
	Don	11/5/90		Fixed problem with moving events in update

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmToScreen	proc	far
	uses	ax, bx, cx, dx, si, bp, ds
	.enter

	; Call for update (if necessary) of the event if on screen
	;
	push	ax, bp				; save EventStruct group & item
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	movdw	cxdx, axbp			; cx:dx = Gr:It to update
	mov	ax, MSG_DP_ETE_FORCE_UPDATE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage

	; First duplicate the alarm block
	;
EC <	cmp	ds:[alarmsUp], 255		; check for overflow	>
EC <	ERROR_E	ALARM_UP_VALUE_TOO_LARGE				>
	inc	ds:[alarmsUp]			; increase the alarm up count
	mov	bx, handle AlarmTemplate	; block to duplicate
	clr	ax				; have current geode own block
	mov	cx, -1				; copy running thread from
						;	template block
	call	ObjDuplicateResource		; duplicate this block

	; Stuff the triggers with the group & item #
	;
	pop	cx, dx				; CX:DX = group:item
	mov	si, offset AlarmTemplate:AlarmBox
	mov	ax, MSG_REMINDER_STORE_EVENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; CX, DX are preserved

	; Now let's stuff the data into the block
	;
	mov	ax, cx				; group => AX
	mov	di, dx				; item => DI

	call	GP_DBLock			; re-lock the EventStruct
	push	di, di				; save the EventStruct handle
	mov	bp, es:[di]			; dereference the event
	mov	cx, es:[bp].ES_dataLength	; length of data in CX

	
DBCS <	shr	cx, 1				; # bytes -> # chars	>
	add	bp, offset ES_data		; get the data
	mov	dx, es				; DX:BP points to the data
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	mov	si, offset AlarmTemplate:AlarmMessage
	call	ObjMessage_reminder_call	; stuff the text

	; Create & stuff the date string
	;
	pop	di				; restore event handle
	mov	si, es:[di]			; dereference the event handle
	mov	bp, es:[si].ES_timeYear		; year to BP
	mov	dx, {word} es:[si].ES_timeDay	; month/day to DX
	mov	cx, {word} es:[si].ES_timeMinute ; hour/minute to CX
	mov	si, offset AlarmTemplate:AlarmBox
	mov	ax, MSG_REMINDER_STORE_DATE_TIME
	call	ObjMessage_reminder_call
repeatEvent::
	mov	ax, MSG_CALENDAR_RESET_REMINDER
	call	ObjMessage_reminder_call

	; Now set the alarm window usable
	;
	mov	cx, bx				; AlarmBox OD => CX:DX
	mov	dx, si
	clr	bx
	call	GeodeGetAppObject		; application object => BX:SI
	mov	bp, mask CCF_MARK_DIRTY or CCO_LAST ; make it the last child
	mov	ax, MSG_GEN_ADD_CHILD		; yes - we're adding a child
	call	ObjMessage_reminder_call	; link window to parent

	mov	bx, cx
	mov	si, dx				; BX:SI is our object
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_NOW			; update the screen now!
	call	ObjMessage_reminder_call	; set the new window usable
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	call	ObjMessage_reminder_call

	; Ensure we can always interact with the window
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	call	ReminderAddRemoveAlwaysInteractibleWindowsGCNList

	; Finally, make some noise to alert user of the alarm
	;
	pop	di				; EventStruct => ES:*DI

	;
	; NON responder
	;
	mov	bx, es:[di]
	mov	bl, es:[bx].ES_flags		; EventInfoFlags => BL
	and	bx, mask EIF_ALARM_SOUND
	shl	bx, 1				; word offset => BX
	mov	ax, SST_CUSTOM_BUFFER		; play my own noise
	mov	dx, cs
	mov	si, cs:[alarmSounds][bx]	; sound buffer => DX:SI
	mov	cx, cs:[alarmLength][bx]	; buffer length => CX
	call	UserStandardSound		; play the sound


	.leave
	ret
AlarmToScreen	endp


alarmSounds	nptr \
		normalAlarmBuffer,
		silentAlarmBuffer,
		quietAlarmBuffer,
		panicAlarmBuffer

alarmLength	word \
		NORMAL_ALARM_BUFFER_SIZE,
		SILENT_ALARM_BUFFER_SIZE,
		QUIET_ALARM_BUFFER_SIZE,
		PANIC_ALARM_BUFFER_SIZE

silentAlarmBuffer	label	word
	General		GE_END_OF_SONG
SILENT_ALARM_BUFFER_SIZE	equ	$ - (offset silentAlarmBuffer)

quietAlarmBuffer	label	word
	ChangeEnvelope	0, IP_ACOUSTIC_GRAND_PIANO
	DeltaTick	1
	VoiceOn		0, HIGH_C, DYNAMIC_MF
	DeltaTick	7
	VoiceOff	0
	DeltaTick	1
	VoiceOn		0, HIGH_E, DYNAMIC_MF
	DeltaTick	7
	VoiceOff	0
	DeltaTick	1
	VoiceOn		0, HIGH_D, DYNAMIC_MF
	DeltaTick	7
	VoiceOff	0
	DeltaTick	1
	VoiceOn		0, HIGH_C, DYNAMIC_MF
	DeltaTick	7
	VoiceOff	0
	General		GE_END_OF_SONG
QUIET_ALARM_BUFFER_SIZE		equ	$ - (offset quietAlarmBuffer)

normalAlarmBuffer	label	word
	ChangeEnvelope	0, IP_FLUTE
	DeltaTick	1
	VoiceOn		0, HIGH_A, DYNAMIC_F
	DeltaTick	8	
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_G, DYNAMIC_F
	DeltaTick	8
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_F, DYNAMIC_F
	DeltaTick	8
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_A, DYNAMIC_F
	DeltaTick	8
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_G, DYNAMIC_F
	DeltaTick	8
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_F, DYNAMIC_F
	DeltaTick	8
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_A, DYNAMIC_F
	DeltaTick	8
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_G, DYNAMIC_F
	DeltaTick	10
	VoiceOff	0
	DeltaTick	2
	VoiceOn		0, HIGH_F, DYNAMIC_F
	DeltaTick       12
	VoiceOff	0
	General		GE_END_OF_SONG
NORMAL_ALARM_BUFFER_SIZE	equ	$ - (offset normalAlarmBuffer)

panicAlarmBuffer	label	word
	ChangeEnvelope	0, IP_TINKLE_BELL
	DeltaTick	1
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	18
	VoiceOff	0
	DeltaTick	6
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_D, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_D, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_D, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_D, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_D, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_C, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	VoiceOn		0, LOW_D, DYNAMIC_FF
	DeltaTick	5
	VoiceOff	0
	General		GE_END_OF_SONG
PANIC_ALARM_BUFFER_SIZE		equ	$ - (offset panicAlarmBuffer)

	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy an alarm we previosuly created

CALLED BY:	UI (MSG_CALENDAR_ALARM_DESTROY)
	
PASS: 		DS, ES	= DGroup
		CX:DX	= OD of the alarm to destroy

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:
		The Alarm/Reminder is already set not usable at this point

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		None

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AlarmDestroy	proc	far
	.enter

	; Remove it from the visual linkage
	;
EC <	tst	ds:[alarmsUp]			; check for underflow	>
EC <	ERROR_E	ALARM_UP_VALUE_TOO_SMALL				>
	dec	ds:[alarmsUp]			; decrease the alarm up count
	GetResourceHandleNS	AppResource, bx
	mov	si, offset AppResource:Calendar	; BX:SI = parent of the window
	mov	ax, MSG_GEN_REMOVE_CHILD
	mov	bp, mask CCF_MARK_DIRTY		; mark the links as dirty
	clr	di
	call	ObjMessage

	; Remove object from GCN list
	;
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	bx, cx
	mov	si, dx				; object in the block to free
	call	ReminderAddRemoveAlwaysInteractibleWindowsGCNList

	; Now free up the block
	;
	mov	ax, MSG_META_BLOCK_FREE
	clr	di
	call	ObjMessage

	.leave
	ret
AlarmDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmSnooze
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cause the alarm to go away for 5 minutes

CALLED BY:	UI (MSG_CALENDAR_ALARM_SNOOZE)
		This is run in the GeoPlanner's thread

PASS:		CX:DX	= Group:Item of the EventStruct
		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ALARM_SNOOZE_TIME	= 5

AlarmSnooze	proc	far
	
	; Reset the alarm time
	;
	push	cx, dx				; save the group & item #'s
	call	TimerGetDateAndTime
	mov	cl, dl				; Hour/Minute to CX
	mov	dx, bx
	xchg	dh, dl				; Month/Day to DX
	mov	bp, ax				; year to BP
	add	cl, ALARM_SNOOZE_TIME		; add on the snooze time
	cmp	cl, 60				
	jl	reset
	sub	cl, 60				; go to the next hour
	inc	ch				;
	cmp	ch, 24
	jl	reset
	push	cx				; save the time
	mov	cx, 1				; increment by one day
	call	CalcDateAltered			; calculate
	pop	cx				; restore the time

	; See if the DayPlan has this event loaded
reset:
	pop	ax, di				; group:item => AX:DI
	test	ds:[systemStatus], SF_VALID_FILE ; are we exiting ??
	jz	done				; yes, so ignore
	push	cx, dx, bp			; save the time values
	mov	cx, ax
	mov	dx, di				; goup:item => CX:DX
	GetResourceHandleNS	DayPlanObject, bx
	mov	si, offset DayPlanObject	; DayPlan OD => BX:SI
	mov	ax, MSG_DP_ETE_FIND_EVENT
	call	ObjMessage_reminder_call	; is the event present ??
	mov	si, ax				; DayEvent handle => SI
	mov	ax, cx				; group => AX
	mov	di, dx				; item => DI
	pop	cx, dx, bp			; restore the time data
	jnc	manualChange			; if carry clear, not found
	tst	si				; is it on screen ??
	jz	manualChange			; if not, do it ourself
	mov	ax, MSG_DE_SET_ALARM		; set the alarm remotely
	clr	di				; not a call
	call	ObjMessage			; send the method
	jmp	done				; we're done

	; Reset the alarm time
manualChange:
	call	DBDeleteAlarm			; remove the linkage
	push	di
	call	GP_DBLockDerefDI		; lock the item & mark it dirty
	mov	es:[di].ES_alarmYear, bp
	mov	{word} es:[di].ES_alarmDay, dx
	mov	{word} eS:[di].ES_alarmMinute, cx
	call	GP_DBDirtyUnlock		; unlock after storing data
	pop	di				; restore the item #
	call	DBInsertAlarm			; re-insert alarm
done:
	ret
AlarmSnooze	endp

if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AlarmTodo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Put alarmed event into To Do list		

CALLED BY:	MSG_CALENDAR_ALARM_TODO
		  run by process thread
	
PASS:		cx:dx	= Group:Item of alarm event

RETURN:		nothing		

DESTROYED:	ax,bx,cx,dx,di,si,bp,es

SIDE EFFECTS:	alters database by adding a To-do EventStruct

PSEUDO CODE/STRATEGY:
		Allocate new EventStruct
		Copy old EventStruct to new EventStruct
		Move To-do values to new EventStruct
		Add new EventStruct to To-do list in DB
		if(To-do list showing)
		  Reshow events
		Put up flashing note

		Note: In the long run, code inside AlarmToDo should
		be replaced by a call to CreateEvent anyway, since
		it is really identical. The way to do that is to create
		a bogus DayEvent and call the CreateEvent. As a quick
		fix right here for the unique ID, I just added the
		UniqueID part from CreateEvent. (kliu --  3/27/97)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/23/95    	Initial version
	sean	10/26/95	completely changed
	kliu	3/27/97		Added unique ID

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
AlarmTodo	proc	far
	.enter

	; First we create an EventStruct & copy the event text to
	; this new EventStruct.
	;
	push	cx, dx			; save Gr:It of old EventStruct
	movdw	axdi, cxdx		; ax:di = Gr:It of old EventStruct
	call	GetEventStructSize	; cx = size of EventStruct
	call	DBGetToDoMap		; ax:di = Gr:It of To Do map
	mov	bx, di			; ax:bx = Gr:It of To Do map
	call	GP_DBAlloc		; ax:di = Gr:It of new EventStruct
	pop	cx, dx			; restore Gr:It of old EventStruct
	call	StuffEventText		

	; Then we stuff it with To-do item values, and insert
	; it into the database as a To-do event.
	;
	call	StuffToDoEvent		; new EventStruct <- To-do item values
					; cxdx = unqiue ID (if UNIQUE_ID)
	;
	; Insert the IDArray for the event's unique ID
	;
		
if	SEARCH_EVENT_BY_ID
	call	DBInsertEventIDArray
endif
	mov	cx, (TODO_DUMMY_HOUR shl 8) or TODO_NORMAL_PRIORITY
	call	DBInsertEvent		; insert w/ normal priority

	;		
	; We reset the DayPlan's UI if the Calendar happens to
	; be showing the To-do list when we add this To-do item. 
	; Therefore, the To-do list will show this new To-do item.
	;
	GetResourceSegmentNS	dgroup, es
	cmp	es:[viewInfo], VT_TODO		; To-do list showing ?
	jne	continue
	mov	ax, MSG_DP_RESET_UI
	GetResourceHandleNS	DayPlanObject, bx
	mov	si, offset	DayPlanObject
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage

	; Put up flashing note telling that event was moved
	; to To-do list.
	;
	; It should be a flashing note -- kho, 11/20/95
	;
	; GetResourceHandleNS	MovedToToDoListString, cx
	; mov	dx, offset	MovedToToDoListString
	; call	FoamDisplayNoteNoBlock
continue:	
	GetResourceHandleNS MovedToToDoNote, bx
	mov	si, offset MovedToToDoNote
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	
	.leave
	ret
AlarmTodo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffEventText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Copies event text in source EventStruct to new 
		destination EventStruct.

CALLED BY:	AlarmTodo

PASS:		cx:dx	= Gr:It of source event text
		ax:di 	= Gr:It of desitination event text

RETURN:		nothing

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	10/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffEventText	proc	near
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	xchgdw	axdi, cxdx
	test	ax, REPEAT_MASK
	jnz	repeatEvent
	call	GP_DBLockDerefDI	; es:di = source EventStruct
	segmov	ds, es, si
	mov	si, di			; ds:si = source EventStruct
	movdw	axdi, cxdx		; ax:di = Gr:It of dest EventStuct
	call	GP_DBLockDerefDI	; es:di = dest EventStruct
	mov	cx, ds:[si].ES_dataLength
	mov	es:[di].ES_dataLength, cx	; store dataLength
	add	di, offset ES_data	; es:di = ptr dest event text
	add	si, offset ES_data	; ds:si = ptr source event text
copyIt:
	rep	movsb			; copy the text
	call	GP_DBDirtyUnlock	; write/unlock new EventStruct
	segmov	es, ds, di
	call	DBUnlock		; unlock source
	
	.leave
	ret

repeatEvent:
	and	ax, not (REPEAT_MASK)
	call	GP_DBLockDerefDI	; es:di = source EventStruct
	segmov	ds, es, si
	mov	si, di			; ds:si = source EventStruct
	movdw	axdi, cxdx		; ax:di = Gr:It of dest EventStuct
	call	GP_DBLockDerefDI	; es:di = dest EventStruct
	mov	cx, ds:[si].RES_dataLength
	mov	es:[di].ES_dataLength, cx	; store dataLength
	add	di, offset ES_data	; es:di = ptr dest event text
	add	si, offset RES_data	; ds:si = ptr source event text
	jmp	copyIt

StuffEventText	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetEventStructSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns size of EventStruct + size of data in
		EventStruct, so we can allocate a new EventStruct.

CALLED BY:	AlarmTodo

PASS:		ax:di	= Gr:It of old EventStruct

RETURN:		cx	= size of EventStruct to allocate

DESTROYED:	es

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	10/26/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GetEventStructSize	proc	near
	uses	ax,si,di
	.enter

	mov	cx, size EventStruct
	test	ax, REPEAT_MASK		; repeat event ?
	jnz	repeatEvent
	call	GP_DBLockDerefDI	; es:di = old EventStruct
	add	cx, es:[di].ES_dataLength
	jmp	exit
repeatEvent:
	and	ax, not REPEAT_MASK
	call	GP_DBLockDerefDI	; es:di = old EventStruct
	add 	cx, es:[di].RES_dataLength
exit:
	call	DBUnlock

	.leave
	ret
GetEventStructSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffToDoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuffs EventStruct with To-do list values.

CALLED BY:	AlarmTodo

PASS:		ax:di 	= Gr:It of new EventStruct
		bx	= It # for To-Do list map

RETURN:		cxdx = unique ID (if UNIQUE_EVENT_ID)

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	10/26/95    	Initial version
	kliu	3/28/97		added unique_event_id

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
StuffToDoEvent	proc	near
	uses	ax,bx,si,di,bp
	.enter

	call	GP_DBLockDerefDI	; es:di = new EventStruct
	mov	es:[di].ES_flags, mask EIF_TODO
	mov	es:[di].ES_parentMap, bx	; store parent map
	mov	es:[di].ES_timeYear, TODO_DUMMY_YEAR
	mov	{word} es:[di].ES_timeDay, TODO_DUMMY_MONTH_DAY
	mov	es:[di].ES_timeHour, TODO_DUMMY_HOUR
	mov	es:[di].ES_timeMinute, TODO_NORMAL_PRIORITY
	clr	es:[di].ES_endTimeMinute
	clr	es:[di].ES_endTimeHour
	clr	es:[di].ES_varFlags
	mov	es:[di].ES_memoToken, NO_MEMO_TOKEN
	clr	es:[di].ES_alarmYear
	clr	es:[di].ES_alarmDay
	clr	es:[di].ES_alarmMonth
	clr	es:[di].ES_alarmHour
	mov	es:[di].ES_alarmMinute, TODO_NOT_COMPLETED
	clr	es:[di].ES_repeatID
if	UNIQUE_EVENT_ID
	call	UseNextEventID		; cxdx <- next event id
	movdw	es:[di].ES_uniqueID, cxdx
endif
		
if	HANDLE_MAILBOX_MSG
	clr	es:[di].ES_sentToArrayBlock
	clr	es:[di].ES_sentToArrayChunk
	clr	es:[di].ES_nextBookID
endif
	call	GP_DBDirtyUnlock

	.leave
	ret
StuffToDoEvent	endp
endif		; if To Do list


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReminderStoreEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the corresponding EventStruct for this reminder

CALLED BY:	AlarmToScreen (MSG_REMINDER_STORE_EVENT)
		This is run in the UI thread

PASS:		DS:DI	= ReminderClass specific instance data
		CX:DX	= EventStruct Group:Item

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReminderStoreEvent	method	ReminderClass,	MSG_REMINDER_STORE_EVENT
	.enter

	mov	ds:[di].RCI_group, cx		; store the group #
	mov	ds:[di].RCI_item, dx		; store the item #

	.leave
	ret
ReminderStoreEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReminderStoreDateTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stores the date & time of the Reminder being displayed

CALLED BY:	GLOBAL (MSG_REMINDER_STORE_DATE_TIME)
	
PASS:		DS:DI	= ReminderClass specific instance data
		ES	= DGroup
		BP	= Year
		DX	= Month/day
		CX	= Hour/minute

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReminderStoreDateTime	method	ReminderClass,	MSG_REMINDER_STORE_DATE_TIME
	.enter

	mov	{word} ds:[di].RCI_minute, cx
	mov	{word} ds:[di].RCI_day, dx
	mov	ds:[di].RCI_year, bp

	.leave
	ret
ReminderStoreDateTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReminderSnooze
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user wants the reminder to re-appear in five minutes.
		Call the process to do the real work

		Or the user wants to put an Alarmed event into the 
		To Do list. (MSG_REMINDER_TODO)

CALLED BY:	UI (MSG_REMINDER_SNOOZE)
		   (MSG_REMINDER_TODO)
		This is run in the UI thread

PASS:		DS:DI	= ReminderClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/23/90		Initial version
	sean	4/5/95		To do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	_TODO
ReminderSnooze	method	ReminderClass,	MSG_REMINDER_SNOOZE,
					MSG_REMINDER_TODO
else
ReminderSnooze	method	ReminderClass,	MSG_REMINDER_SNOOZE
endif

	.enter

TODO <	mov	bp, ax				; bp = message 		>
	mov	cx, ds:[di].RCI_group
	tst	cx				; any group
	jz	done				; no, so do nothing
	mov	dx, ds:[di].RCI_item
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	call	MemOwner			; owner => BX
	mov	ax, MSG_CALENDAR_ALARM_SNOOZE
TODO <	cmp	bp, MSG_REMINDER_SNOOZE		; which message are	>
TODO <	je	notToDo				; we responding to ?	>
TODO <	mov	ax, MSG_CALENDAR_ALARM_TODO	; if To Do message	>
notToDo::
	clr	di
	call	ObjMessage
done:
	.leave
	ret
ReminderSnooze	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReminderDestroy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy a reminder when it is closed by the user

CALLED BY:	UI (MSG_GEN_GUP_INTERACTION_COMMAND)
		This is run in the UI thread

PASS: 		DS:DI	= ReminderClass specific instance data
		DS:*SI	= ReminderClass instance data
		AX	= MSG_GEN_GUP_INTERACTION_COMMAND
		CX	= InteractionCommand

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP
		(Responder) 

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/89	Initial version
	Don	8/23/90		Changed name & thread its running under
	sean	10/27/95	Responder focus/target code
	sean	11/30/95	Responder change.  Make sure all
				alarms gone before releasing focus.
	sean	1/11/96		Kill Responder code(use sys-modal
				dialog instead)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReminderDestroy	method	ReminderClass,	MSG_GEN_GUP_INTERACTION_COMMAND

	; First complete the method
	;
	push	cx
	mov	di, offset ReminderClass
	call	ObjCallSuperNoLock
	pop	cx
	cmp	cx, IC_DISMISS
	jne	done
	
	; Ensure the dialog box is no longer usable
	;
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_NOW
	call	ObjCallInstanceNoLock

	; Now kill the alarm entirely
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; CX:DX = object to remove
	mov	bx, cx
	call	MemOwner			; process => BX
	mov	ax, MSG_CALENDAR_ALARM_DESTROY
	clr	di
	call	ObjMessage

done:
	ret
ReminderDestroy	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReminderSelfDestruct
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A reminder must destroy itself if the corresponding 
		EventStruct is being altered or deleted.

CALLED BY:	AlarmCheckActive()
	
PASS:		DS:DI	= ReminderClass specific instance data
		DS:*SI	= ReminderClass instance data
		CX:DX	= EventStruct group:item that is changing
				- or -
		CX	= -1 to always destroy reminder
		DX	= -1 to disable the snooze trigger

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReminderSelfDestruct	method	ReminderClass,	MSG_CALENDAR_KILL_REMINDER
	.enter

	; If the group & item numbers match, destroy me...
	;
	cmp	cx, -1				; destroy regardless ??
	je	destroyMe
	cmp	dx, -1				; just disable Snooze?
	je	nukeSnooze
	cmp	cx, ds:[di].RCI_group
	jne	done
	cmp	dx, ds:[di].RCI_item
	jne	done
destroyMe:
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjCallInstanceNoLock
	jmp	done
nukeSnooze:
	mov	ds:[di].RCI_group, 0		; remove the group
	mov	ds:[di].RCI_item, 0		; remove the item
	mov	si, offset AlarmSnoozeTrigger	; snooze trigger OD => DS:*SI
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; disable the trigger
	mov	dl, VUM_NOW			; update now to ensure state
	call	ObjCallInstanceNoLock		; send the method
done:
	.leave
	ret
ReminderSelfDestruct	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReminderReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the time & date string for a reminder

CALLED BY:	GLOBAL
	
PASS:		DS:DI	= specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/28/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReminderReset	method	ReminderClass,	MSG_CALENDAR_RESET_REMINDER
	.enter

	; Reset the time & date strings
	;
	mov	bp, ds:[di].RCI_year		; year => BP
	mov	dx, {word} ds:[di].RCI_day	; month/day => DX
	push	{word} ds:[di].RCI_minute	; push hour/minute
	mov	cx, DTF_LONG_CONDENSED or USES_DAY_OF_WEEK
	mov	di, ds:[LMBH_handle]		; text object OD => DI:SI
	mov	si, offset AlarmTemplate:AlarmDate
	call	DateToTextObject		; stuff the date
	pop	cx				; put hour/minute to CX
	mov	si, offset AlarmTemplate:AlarmTime ; text object OD => DI:SI
	call	TimeToTextObject		; stuff the time

	.leave
	ret
ReminderReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ReminderAddRemovelwaysInteractibleWindowsGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an add or remove message to the application object's
		GCN list

CALLED BY:	INTERNAL

PASS:		AX	= Message to send
				MSG_META_GCN_LIST_ADD
				MSG_META_GCN_LIST_REMOVE
		BX:SI	= OD of ReminderClass object

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ReminderAddRemoveAlwaysInteractibleWindowsGCNList	proc	near
	uses	bx, cx, dx, di, si, bp
	.enter
	
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp				; GCNListParams => SS:BP
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, GAGCNLT_ALWAYS_INTERACTABLE_WINDOWS
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si	
	clr	bx				; use this geode!
	call    GeodeGetAppObject		; application object => BX:SI
	mov	di, mask MF_STACK
	call	ObjMessage_reminder		; send it!!
	add	sp, dx				; clean up the stack

	.leave
	ret
ReminderAddRemoveAlwaysInteractibleWindowsGCNList	endp




ObjMessage_reminder_send	proc	near
	clr	di
	GOTO	ObjMessage_reminder
ObjMessage_reminder_send	endp

ObjMessage_reminder_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_DS
	FALL_THRU	ObjMessage_reminder
ObjMessage_reminder_call	endp

ObjMessage_reminder	proc	near
	call	ObjMessage
	ret
ObjMessage_reminder	endp

ReminderCode	ends
endif







