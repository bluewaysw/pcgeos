COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainDatabase.asm

AUTHOR:		Don Reeves, July 17, 1989

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/17/89		Initial revision

DESCRIPTION:
	Contains the routines needed to load, save, and manage a database
	of day events.
		
	$Id: mainDatabase.asm,v 1.1 97/04/04 14:48:01 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the database to reflect current state of the DayEvent.
		If this event is not  in the database, put it there.

CALLED BY:	GLOBAL (MSG_CALENDAR_UPDATE_EVENT)

PASS:		DS	= DGroup
		ES	= DGroup
		CL	= DataBaseUpdateFlags:
				DBUF_NEW
				DBUF_TIME
				DBUF_ALARM
				DBUF_EVENT
				DBUF_FLAGS
		DX	= Size of structure
		SS:BP	= DayEventInstance structure

RETURN:		CX:DX	= Group:Item of new event (if appropriate)

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	NAME	DATE		DESCRIPTION
	----	----		-----------
	Don	8/30/89		Initial revision
	Don	10/16/89	Restuctured, adding DBUpdateFlags
	RR	6/3/95		handle variable length events
	sean	8/29/95		Added DBUpdateDate/DBUF_DATE

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateEvent	proc	far

	; Check the size
	;
EC <	cmp	dx, size DayEventInstance	; compare size with actual    >
EC <	ERROR_NZ	DB_UPDATE_BAD_SIZE				      >

	; Set up for updates
	;
	mov	si, bp				; SS:SI contains DayEvent dat
	mov	ax, ss:[si].DEI_DBgroup		; group # to AX
	mov	di, ss:[si].DEI_DBitem		; item # to DI
	mov	bp, ss:[si].DEI_eventHandle	; handle to this DayEvent
	test	ss:[si].DEI_actFlags, DE_VIRGIN	; a virgin event ??
	jne	newEvent

	; If we're updating a repeat event in Responder, then we don't
	; just change it to a normal event.  We modify the
	; RepeatStruct & maybe the repeat tables.
	;
	test	ss:[si].DEI_stateFlags, mask EIF_REPEAT	; a repeat event ??
	jne	newEvent			; then also create an event

	; Now decipher type of update to occur
	;
	test	cl, DBUF_FLAGS
	jne	flags
	test	cl, DBUF_EVENT
	jne	event
	test	cl, DBUF_ALARM
	jne	alarm
	test	cl, DBUF_TIME
	jne	time
if	END_TIMES
	test	cl, DBUF_VARLEN
	jne	varLen
endif
EC <	ERROR		DB_UPDATE_UNKNOWN_UPDATE_FLAG			     >

	; Update the flags stuff
	;
flags:
	call	DBUpdateEventFlags
	jmp	done

	; Update the event text
	;
event:
	call	DBUpdateEventText		; just do it !!	
	jmp	done

	; Update the alarm
	;
alarm:
	call	DBDeleteAlarm			; delete the current position
	call	DBUpdateEventAlarm		; stuff the alarm time
	call	DBInsertAlarm			; insert it again
	jmp	done
	
	; Update the time (delete & re-create the event)
	;
time:
		
	mov	cx, {word} ss:[si].DEI_timeMinute ; New Hour/Minute => CX
	call	DBUpdateEventTime			; change the time
	jmp	done

if	END_TIMES
	; Store end time
	;
varLen:
	call 	DBUpdateEventEndTime		; update event

	; on responder, update start time as well since we may have changed
	; VLF_START_TIME of ES_varFlags filed
	;
RSP <	mov	cx, {word}ss:[si].DEI_timeMinute			>
RSP <	call	DBUpdateEventTime					>
	jmp	done
endif	


	; Create a new event for the database (note the fall-thru)
	;
newEvent:
	test	cl, DBUF_NEW or DBUF_EVENT or DBUF_TIME
	jz	done				; if alarm or flags, ignore!
	call	CreateEvent			; create the event
	stc					; set carry to handle notify
	jmp	exit
done:
	clc
exit:
	ret
UpdateEvent	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeOfEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads a range of events into the DayPlan

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		DS:0	= Memory block handle for segment
		SS:BP	= EventRangeStruct

RETURN:		Carry	= Set if aborted early (used by search)
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	5/24/90		Changed the DayMap structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRangeOfEvents	proc	far
	uses	ax, bx, cx, dx, di, si, bp, es
	.enter

	; A little set up work
	;
EC <	call	GP_DBVerify			; and verify the map block >
	push	ds:[LMBH_handle] 		; save this handle
	segmov	ds, es				; DGroup to DS
	mov	dx, {word} ss:[bp].ERS_endDay	; end month/day => DX
	call	DateToTablePos			; end offset => BX
	mov	cx, bx				; end offset => CX
	mov	bx, bp				; EventRangeStruct => SS:BX
	mov	bp, ss:[bx].ERS_startYear
	mov	dx, {word} ss:[bx].ERS_startDay	

	; Go to the first day of this series
	;
	call	DBSearchYear			; find the year
	tst	di				; look for no year...
	je	fail				; we're done - no year
	mov	bp, bx				; EventRangeStruct => SS:BP
	call	DateToTablePos			; start offset => BX
	call	GP_DBLock			; lock the YearMap
	mov	si, di				; ES:*SI => YearMap
	mov	dx, cx				; end offset => DX
	jmp	midLoop				; start looping, dude!

	; We've found a real day - now spit out the events
dayLoop:
	mov	di, es:[di]			; item # for EventMap => DI
EC <	tst	di				; EventMap here ??	>
EC <	ERROR_Z	GET_RANGE_OF_EVENTS_BAD_YEARMAP_ITEM			>
	call	GetDaysEvents
	jc	exit				; if carry set, exit
	add	bx, 2				; go to the next day
midLoop:
	mov	di, es:[si]			; derference the chunk
	add	di, bx				; go to the current offset
	push	ax				; save this reigster
	mov	cx, YearMapSize			; maximum string length
	sub	cx, bx				; longest possible length
	shr	cx				; want it in words!
	clr	ax				; comparison value => AX
	repz	scasw				; look for non-zero value
	pop	ax				; restore this register
	jz	calcOffset			; if off array, don't back up
	sub	di, 2				; account for over-scan
calcOffset:
	mov	bx, di				; current position => BX
	sub	bx, es:[si]			; new offset => BX
	cmp	bx, dx				; compare current w/ end offset
	jle	dayLoop				; loop again (else carry clear)

	; Clean up
exit:
	pushf					; save the flags
	cmp	bx, ss:[bp].ERS_nextOffset	; compare with existing offset
	jge	postExit			; if not sooner, do nothing
	mov	ss:[bp].ERS_nextOffset, bx	; store the next offset
postExit:
	call	DBUnlock			; unlock the DayMap (in ES)
	popf					; restore the flags
fail:
	pop	bx				; restore the block handle
	call	MemDerefDS			; restore DS

	.leave
	ret
GetRangeOfEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetDaysEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the events for a specific day/month/year

CALLED BY:	GLOBAL

PASS:		SS:BP	= EventRangeStruct
		AX	= EventMap : Group #
		DI	= EventMap : Item #
		ES	= Valid segment we can't destroy

RETURN:		Carry	= Determined by method call

DESTROYED:	DI

PSEUDO CODE/STRATEGY:
		Send MSGDP_LOAD_EVENT for each event found in this day
		If carry return set, abort loading of the rest of the event
			and return carry set
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/30/89		Initial version
	Don	11/27/89	Increased speed
	Don	5/24/90		Changed the DayMap structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetDaysEvents	proc	near
	uses	bx, cx, dx, si, es
	.enter

	; Some set up work before the loop
	;
	call	GP_DBLock			; lock the item
	mov	si, es:[di]			; dereference the handle
	mov	cx, {word} es:[si].EMH_day	; month/day => CX
	mov	ss:[bp].ERS_curMonthDay, cx	; store the value
	mov	cx, es:[si].EMH_numEvents	; get the number of events
	mov	bx, size EventMapHeader		; set my offset pointer

getLoop:
	push	ax, bx, cx, bp			; save the crucial reigsters
	mov	si, es:[di]			; dereference the handle
	mov	dx, es:[si][bx].EMS_event	; get the new item #
	mov	cx, ax				; group # to CX
	mov	ax, ss:[bp].ERS_message
	mov	bx, ss:[bp].ERS_object.handle
	mov	si, ss:[bp].ERS_object.chunk
	call	MemDerefDS			; DS:*SI is the OD
	call	ObjCallInstanceNoLock		; call to load the event
						; note: BP should not be 0
	; Clean up - go to next event
	;
	pop	ax, bx, cx, bp			; restore crucial regs
	jc	done				; exit on carry set
	add	bx, size EventMapStruct		; point to next event
	loop	getLoop				; loop on CX

	; We're done with loop, clean up
done:
	pushf					; save the carry flag
	call	DBUnlock			; unlock the event map block
	popf					; restore the carry flag

	.leave
	ret
GetDaysEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes an event from the database

CALLED BY:	GLOBAL (MSG_DELETE_EVENT)

PASS:		DS	= DGroup
		ES	= DGroup
		CX	= Group # event
		DX	= Item # event
		if CX = 0
			BP	= Chunk handle of DayEvent object holding data

RETURN:		AX	= UndoActionValue

DESTROYED:	CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version
	SS	3/20/95		To Do list changes
	simon	2/17/97		Delete event from ID array

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteEvent	proc	far

EC <	VerifyDGroupES						>

	; Else store the virgin event time
	;
	tst	cx				; virgin event ??
	jnz	regular
	GetResourceHandleNS	DPResource, bx
	mov	si, bp
	mov	ax, MSG_DE_GET_TIME
	call	ObjMessage_common_call
	call	UndoNotifyDeleteVirgin
	mov	ax, UNDO_DELETE_VIRGIN
	ret
	
	; Extract a little info. (VM file must be updated at this point!)
	;
regular:
	and	es:[systemStatus], not SF_CLEAN_VM_FILE
	call	AlarmCheckActive		; nuke an associated reminder
	mov 	ax, cx
	mov	di, dx				; group:item in AX:DI
	mov	bx, di				; store item # in BX
	call	GP_DBLockDerefDI

if	HANDLE_MAILBOX_MSG

	; Any sent-to information?
	;
	push	ax
	mov	ax, es:[di].ES_sentToArrayBlock
	tst	ax
	jz	noSentTo

	; Clean up the chunk array of sent-to information, if any.
	;
	push	bx
	Assert	dgroup, ds
	mov	bx, ds:[vmFile]
	Assert	vmFileHandle, bx
	call	VMFree
	pop	bx
noSentTo:
	pop	ax
endif

	mov	cx, {word} es:[di].ES_timeMinute
	mov	dx, {word} es:[di].ES_timeDay

if	SEARCH_EVENT_BY_ID
	PUSH_EC	SKIPMULTIDAY, cx, dx
	movdw	cxdx, es:[di].ES_uniqueID
endif

	mov	bp, es:[di].ES_timeYear
	mov	si, es:[di].ES_parentMap
	call	DBUnlock

if	SEARCH_EVENT_BY_ID
	call	DBDeleteEventIDArray		; es destroyed
						; carry set if elem not found
EC <	ERROR_C CALENDAR_EVENT_ID_ARRAY_ELEMENT_NOT_FOUND		>
	POP_EC	SKIPMULTIDAY, cx, dx		; cx=time, dx=date
endif	

	mov	di, bx				; item # back to DI

	; Now delete the event
	;
	call	DBRemoveEvent			; delete the event
	call	UndoNotifyDelete		; free me (via undo stuff)
	tst	si				; is the event count zero ??
	jne	done				; if not, we're done

	; Oops - must delete the day & possibly the year
	;
TODO <	cmp	bp, TODO_DUMMY_YEAR 		; To Do list event?	>
TODO <	je	done				; don't delete year	>
	call	DBSearchYear			; DI=DayMap, SI=Offset in YMap
EC <	cmp	di, nil				; is the year bad ?	      >
EC <	ERROR_Z		DB_DELETE_BAD_YEAR				      >
	push	si, di				; DayMap & offset into YearMap
	call	DBSearchDay			; DI = EventMap, SI = Offset DM
EC <	cmp	di, nil				; is the day bad ?	      >
EC <	ERROR_Z		DB_DELETE_BAD_DAY				      >
	pop	di				; DayMap item => DI
	call	DBDeleteDay			; Offset into DayMap = SI
	tst	si				; any days left ??
	pop	si
	jnz	done				; if not only end buffers, done
	call	DBDeleteYear			; offset into YearMap = SI
done:
	mov	ax, UNDO_DELETE_EVENT
ret
DeleteEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerGetNextEventID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the unique event ID that is to be assigned to the
		next new event.

CALLED BY:	MSG_CALENDAR_GET_NEXT_EVENT_ID
		MSG_CALENDAR_GET_NEXT_EVENT_ID_LOOP_BACK
PASS:		ax	= message #
		^lcx:dx	= recipient object,
			  pass cx == 0 if none
		bp	= message which the calendar app would call on
			  the recipient object with.
			prototype of reply message:
			cx:dx	= next event ID
RETURN:		cx:dx	= next event ID
DESTROYED:	ax, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		If the current file is not valid, and we keep force
		queueing the message, there will be an infinite loop.

		So we force queue another message. If we get that
		message, and the file is not valid, then return a
		dummy value.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/10/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	UNIQUE_EVENT_ID
GeoPlannerGetNextEventID	method dynamic GeoPlannerClass, 
				MSG_CALENDAR_GET_NEXT_EVENT_ID,
				MSG_CALENDAR_GET_NEXT_EVENT_ID_LOOP_BACK
		.enter
	;
	; Is the file opened yet? If not, force queue the message.
	;
		GetResourceSegmentNS	dgroup, es	; es <- dgroup
		test	es:[systemStatus], SF_VALID_FILE
		jz	tryLater
	;
	; Move recipient optr to meaningful registers.
	;
		movdw	bxsi, cxdx
	;
	; Lock down map block and fetch number.
	;
		call	GP_DBLockMap
		mov	di, es:[di]			; es:di = map block
		movdw	cxdx, es:[di].YMH_nextEventID
		call	DBUnlock			; es destroyed
reply:
	;
	; Any recipient to get this?
	;
		tst	bx
		jz	done
	;
	; Send recipient a message.
	;
		; ^lbx:si == recipient
		mov_tr	ax, bp
		call	ObjMessage_common_send		; di destroyed
done:
		.leave
		ret
tryLater:
	;
	; Did we fail to open the file last time?
	;
		cmp	ax, MSG_CALENDAR_GET_NEXT_EVENT_ID
		jne	fileNotOpenTheSecondTime
	;
	; Force queue another message.
	;
		call	GeodeGetProcessHandle		; bx = process handle
		mov	ax, MSG_CALENDAR_GET_NEXT_EVENT_ID_LOOP_BACK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	done
		
fileNotOpenTheSecondTime:
	;
	; So we get the loop-back version of the message. And this
	; time, the system file is still not valid. The file may be
	; corrupted, so let's not try to open it again. Just return a
	; dummy value.
	;
	; But first, force queue a MSG_META_QUIT message, because the
	; app is not going to attempt to open the file again.
	;
EC <		WARNING	CALENDAR_FILE_STILL_NOT_VALID_DUMMY_VALUE_RETURNED>
		mov	ax, MSG_META_QUIT
		mov	bx, handle Calendar
		mov	si, offset Calendar
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage			; nothing destroyed
	;
	; Return a dummy invalid event ID.
	;
		movdw	bxsi, cxdx			; ^lbx:si <- recipient
		movdw	cxdx, INVALID_EVENT_ID
		jmp	reply
		
GeoPlannerGetNextEventID	endm
endif	; UNIQUE_EVENT_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		GeoPlannerSetNextEventID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the unique event ID that is to be assigned to the
		next new event. If the argument is smaller than the
		current value, the value will NOT be changed.

CALLED BY:	MSG_CALENDAR_SET_NEXT_EVENT_ID
		MSG_CALENDAR_SET_NEXT_EVENT_ID_LOOP_BACK
PASS:		ax	= message #
		cx:dx	= next event ID
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		The minimum value is FIRST_EVENT_ID (00020001h).

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/10/97   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	UNIQUE_EVENT_ID
GeoPlannerSetNextEventID	method dynamic GeoPlannerClass, 
				MSG_CALENDAR_SET_NEXT_EVENT_ID,
				MSG_CALENDAR_SET_NEXT_EVENT_ID_LOOP_BACK
		.enter
	;
	; Is the file opened yet? If not, force queue the message.
	;
		GetResourceSegmentNS	dgroup, es	; es <- dgroup
		test	es:[systemStatus], SF_VALID_FILE
		jz	tryLater
	;
	; Lock down map block.
	;
		call	GP_DBLockMap
		mov	di, es:[di]			; es:di = map block
	;
	; Is the passed number bigger than what we have?
	;
		cmpdw	cxdx, es:[di].YMH_nextEventID
EC <		WARNING_B CALENDAR_PASSED_EVENT_ID_TOO_SMALL		>
		jb	quit
	;
	; Set it!
	;
		movdw	es:[di].YMH_nextEventID, cxdx
quit:
		call	GP_DBDirtyUnlock		; es destroyed
done:
		.leave
		ret
tryLater:
	;
	; Did we fail to open the file last time? If so, our file
	; might be corrupted somehow. Let's forget about it.
	;
		cmp	ax, MSG_CALENDAR_SET_NEXT_EVENT_ID
EC <		WARNING_NE CALENDAR_FILE_STILL_NOT_VALID_EVENT_ID_NOT_SET>
		jne	fileNotOpenTheSecondTime
	;
	; Force queue message.
	;
		call	GeodeGetProcessHandle		; bx = process handle
		mov	ax, MSG_CALENDAR_SET_NEXT_EVENT_ID_LOOP_BACK
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage
		jmp	done

fileNotOpenTheSecondTime:
	;
	; The application should silently quit, because it is
	; not going to attempt to open the file again.
	;
		mov	ax, MSG_META_QUIT
		mov	bx, handle Calendar
		mov	si, offset Calendar
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage			; nothing destroyed
		jmp	done
		
GeoPlannerSetNextEventID	endm
endif	; UNIQUE_EVENT_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		UseNextEventID
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the unique event ID that is to be assigned to
		the next new event, and consider that number used.

CALLED BY:	(INTERNAL) DayEventUpdate
PASS:		nothing
RETURN:		cx:dx	= next event ID
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	1/12/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	UNIQUE_EVENT_ID
UseNextEventID	proc	far
		uses	es, di
		.enter
	;
	; Find next event ID to use.
	;
		call	GP_DBLockMap
		mov	di, es:[di]			; es:di = map block
		movdw	cxdx, es:[di].YMH_nextEventID
	;
	; Change next event ID.
	;
		incdw	es:[di].YMH_nextEventID
EC <		tst	es:[di].YMH_nextEventID.high			>
EC <		ERROR_Z	CALENDAR_EVENT_ID_OVERFLOW			>

		call	GP_DBDirtyUnlock		; es destroyed
		
		.leave
		ret
UseNextEventID	endp
endif	; UNIQUE_EVENT_ID
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new event for the database

CALLED BY:	UpdateEvent

PASS:		SS:SI	= DayEvent instance data

RETURN:		CX	= Group # for the new event
		DX	= Item # for the new event

DESTROYED:	AX, BX, DI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version
	SS	3/19/95		To Do list changes
	simon	2/17/97		Insert event ID into array for
				SEARCH_EVENT_BY_ID 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateEvent	proc	near
	.enter

	; Let's create the event
	;
	mov	cx, {word} ss:[si].DEI_timeMinute	; Hour/Minute => CX
	mov	dx, {word} ss:[si].DEI_timeDay		; Month/Day => DX
	mov	bp, ss:[si].DEI_timeYear		; year => BP
	
	; Create or find the necessary EventMap
	; If we're creating an event for the To Do list,
	; we get the To Do list group:item
	;
TODO <	test	ss:[si].DEI_stateFlags, mask EIF_TODO	; event map or To Do >
TODO <	jnz	toDoEvent				; list map ?         >
	call	DBGetEventMap
TODO <	jmp	continue						>
toDoEvent::
TODO <	call	DBGetToDoMap						>
continue::

	; Create an event, and then insert it
	;
	mov	bx, di				; save the EventStruct
	push	cx				; save the time
	mov	cx, size EventStruct		; get size of item to create
	call	GP_DBAlloc			; allocate an item
	call	DBStuffEvent			; stuff the event
	pop	cx
	call	DBInsertEvent			; insert into the database

if	SEARCH_EVENT_BY_ID
	; Insert event ID and Gr:Item mmpping into array
	;
	movdw	cxdx, ss:[si].DEI_uniqueID
	call	DBInsertEventIDArray
endif   ; SERACH_EVENT_BY_ID

	; Return new event in CX:DX
	;
	mov	cx, ax				; CX:DX is the new item
	mov	dx, di

	.leave
	ret
CreateEvent	endp

if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGetToDoMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the map block for the To Do list	

CALLED BY:	CreateToDoEvent

PASS:		nothing

RETURN:		ax	= Group # of To Do Map
		di	= Item # of To Do Map 

DESTROYED:	nothing

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Lock Map Block
		Get To Do list Group:Item  => ax:di
		Unlock Map Block		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SS	3/ 8/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBGetToDoMap	proc	far
	uses	si,es
	.enter
	
	; get database map block
	;
	call	GP_DBLockMap			; *es:di = map block

	; get to do list map block from 
	; database map block
	;
        mov     si, es:[di]                     ; dereference the Map handle
        mov     ax, es:[si].YMH_toDoListGr   	
        mov     di, es:[si].YMH_toDoListIt     	; ax:bx = Group:Item To Do map 
        call    DBUnlock                        ; unlock it	
	
	.leave
	ret
DBGetToDoMap	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBGetEventMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find (or create) the EventMap for this date

CALLED BY:	CreateEvent, UndoDeleteAction

PASS:		BP	= Year
		DX	= Month/Day

RETURN:		AX	= EventMap - group
		DI	= EventMap - item

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBGetEventMap	proc	far
	uses	bx, si
	.enter

	; Look for the DayMap
	;
	call	DBSearchYear			; look for the year
	tst	di				; if found, good!
	jnz	day
	call	DBCreateYear			; if not, create the YearMap
day:
	mov	bx, di				; save the YearMap handle
	call	DBSearchDay			; look for the day
	tst	di				; if found, good!
	jnz	done
	mov	di, bx				; restore the YearMap handle
	call	DBCreateDay			; if not, create the EventMap
done:
	.leave
	ret
DBGetEventMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInsertEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an event into the database

CALLED BY:	CreateEvent

PASS:		AX	= Group # of this event's year
		BX	= Item # of this Day's event map
 		CX	= Hours & Minutes
		DI	= Item # of the event
		
RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:
		Create a new event
		Update the data
		Insert by time
		Insert by alarm

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBInsertEvent	proc	far
	uses	bx, cx, dx, bp, si
	.enter

	; Now insert it in the event map
	;
	xchg	bx, di				; exchange item #'s
	mov	bp, cx				; time -> bp
	push	di				; save item # again
	call	GP_DBLockDerefSI		; lock the map
	mov	cx, es:[si].EMH_numEvents	; get the number of events
	add	si, size EventMapHeader		; go to the first item
	tst	cx				; no events yet ??
	je	insert				; if so, just insert

	; Loop until we find location to insert
searchLoop:
	cmp	bp, {word} es:[si].EMS_time	; compare hour and minute
	jl	insert				; perform the insertion
	add	si, size EventMapStruct
	loop	searchLoop			; loop on CX

	; Insert the new EMS here
insert:
	mov	dx, si				; position to DX
	sub	dx, es:[di]			; create offset in DX
	call	DBUnlock			; unlock the item
	pop	di				; get item # back
	mov	cx, size EventMapStruct
	call	GP_DBInsertAt			; insert bytes here

	; Now initialize the struct
	;
	call	GP_DBLockDerefDI		; lock the sucker, dereference
	add	es:[di].EMH_numEvents, 1	; increment the count
	add	di, dx				; position SI at new EMS
	mov	es:[di].EMS_time, bp		; save the time
	mov	es:[di].EMS_event, bx		; and save the item #
	call	GP_DBDirtyUnlock		; unlock the item

	; Insert the event into the alarm structure
	;
	mov	di, bx				; new item number back to DI
	call	DBInsertAlarm			; takes AX:DI = group:item

	.leave
	ret
DBInsertEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBStuffEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff a new DB event with data from a DayEvent

CALLED BY:	DBCreateEvent

PASS:		SS:SI	= Instance data from DayEvent
		AX	= Group for DB
		BX	= Parent EventMap item #
		DI	= Item # for new event

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/31/89		Initial version
	Don	8/18/89		Modified to work with kernel DB stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBStuffEvent	proc	near
	uses	cx	
	.enter

	; Some set up
	;
	push	di				; save these registers
	call	GP_DBLockDerefDI		; lock the item, dereference

	; Initialize the event values
	;
	mov	es:[di].ES_parentMap, bx	; store the parent item #
	mov	cx, ss:[si].DEI_timeYear
	mov	es:[di].ES_timeYear, cx		; store the event time
	mov	cx, {word} ss:[si].DEI_timeDay
	mov	{word} es:[di].ES_timeDay, cx	; store the event M/D
	mov	cx, {word} ss:[si].DEI_timeMinute
	mov	{word} es:[di].ES_timeMinute, cx ; store the event H/M
	mov	cx, ss:[si].DEI_repeatID
	mov	es:[di].ES_repeatID, cx		; store repeating ID (maybe)

if	UNIQUE_EVENT_ID
	movdw	es:[di].ES_uniqueID, ss:[si].DEI_uniqueID, cx
						; store the unique ID
endif

if	HANDLE_MAILBOX_MSG
	mov	cx, ss:[si].DEI_sentToArrayBlock ; store the sent-to info
	mov	es:[di].ES_sentToArrayBlock, cx
	mov	cx, ss:[si].DEI_sentToArrayChunk
	mov	es:[di].ES_sentToArrayChunk, cx
	mov	cx, ss:[si].DEI_nextBookID	; store the book ID
	mov	es:[di].ES_nextBookID, cx
endif
	;	
	; Save the alarm time & event text
	;
	call	GP_DBDirtyUnlock
	pop	di				; restore the item #
	call	DBUpdateEventAlarm		; stuff the alarm time
	call	DBUpdateEventFlags		; stuff the flags
	call	DBUpdateEventText		; stuff the event text
if	END_TIMES
	call	DBUpdateEventEndTime	
endif
	.leave
	ret
DBStuffEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUpdateEventTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Alter the time of a database event

CALLED BY:	EventUpdate

PASS:		AX	= Group # of the current event
		DI	= Item # of the current event
		CX	= New Hour/Minute
		DS	= DGroup

RETURN:		Nothing

DESTROYED:	BX, CX, DX, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBUpdateEventTime	proc	far
	.enter

	; For a repeat event, we merely update the time in the
	; RepeatStruct.  Repeat events are only updated this 
	; way in Responder.
	;

	; Some set-up work
	;
notRepeatEvent::
	mov	bp, cx				; time also to BP
	mov	bx, di				; item # => BX
	call	GP_DBLockDerefDI		; lock the item, dereference
	xchg	bp, {word} es:[di].ES_timeMinute ; swap old/new times
	mov	si, es:[di].ES_parentMap
	call	GP_DBDirtyUnlock
	mov	di, bx				; item # back to DI

	; Now do the real work
	;
	cmp	bp, cx				; compare the two times
	je	done				; if equal, do nothing
	push	cx				; save the new time
	mov	cx, ax
	mov	dx, di				; group:item => CX:DX
	mov	bx, si				; EventTable handle => BX
	segmov	es, ds				; dgroup => ES
	call	DBRemoveEvent			; remove the event
	pop	cx				; new time => CX
	call	DBInsertEvent			; re-insert the event
done:
	.leave
	ret
DBUpdateEventTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUpdateEventAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the alarm time into the database event

CALLED BY:	DBStuffEvent, UpdateEvent

PASS:		AX	= Group # of the event
		DI	= Item # of the event
		SS:SI	= DayEventinstance data

RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/89	Initial version
	sean	9/7/95		Added ability to update repeat events
				(Responder only)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBUpdateEventAlarm	proc	near
	uses	cx, di
	.enter

	; For a repeat event, we merely update the alarm time in the
	; RepeatStruct.  Repeat events are only updated this 
	; way in Responder.
	;

	; Normal EventStruct
	;
	call	GP_DBLockDerefDI		; lock the item, dereference

	mov	cx, ss:[si].DEI_alarmYear
	mov	es:[di].ES_alarmYear, cx		; store the alarm year
	mov	cx, {word} ss:[si].DEI_alarmDay
	mov	{word} es:[di].ES_alarmDay, cx		; store the alarm M/D
	mov	cx, {word} ss:[si].DEI_alarmMinute
	mov	{word} es:[di].ES_alarmMinute, cx	; store the alarm H/M
done::
	call	GP_DBDirtyUnlock

	.leave
	ret
DBUpdateEventAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUpdateEventFlags
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the event flags (alarm on/off)

CALLED BY:	DBStuffEvent, UpdateEvent

PASS:		AX	= Group # of event
		DI	= Item # of event
		SS:SI	= DayEvent instance data

RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/13/89	Initial version
	sean	3/19/95		To Do list changes
	sean	9/9/95		Added ability to update repeat events

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBUpdateEventFlags	proc	near
	uses	cx, di
	.enter

	; Check if we're updating a repeat event or not
	;

	; Now stuff the data
	;
	call	GP_DBLockDerefDI		; lock the item, dereference
	mov	cl, ss:[si].DEI_stateFlags
	and	cl, mask EIF_ALARM_ON or \
		    mask EIF_NORMAL or \
		    mask EIF_ALARM_SOUND
if	_TODO
	or	cl, mask EIF_NORMAL		
	test	ss:[si].DEI_stateFlags, mask EIF_TODO
	jz	continue			; normal bit stays
	or	cl, mask EIF_TODO		; set To Do Event bit
	and 	cl, not (mask EIF_NORMAL)	; delete normal event bit
continue:
endif
	mov	es:[di].ES_flags, cl		; store only these flags
done::	
	call	GP_DBDirtyUnlock

	.leave
	ret
DBUpdateEventFlags	endp

if 	END_TIMES

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUpdateEventEndTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the event end time

CALLED BY:	DBStuffEvent, UpdateEvent

PASS:		AX	= Group # of event
		DI	= Item # of event
		SS:SI	= DayEvent instance data

RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RR	5/31/95		Initial version
	sean	9/7/95		Added ability to update repeat events
				(Responder only)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBUpdateEventEndTime	proc	near
	uses	cx, di
	.enter

	; If we're trying to update a repeat event, we treat the 
	; database item differently.
	;
	
	; Normal EventStruct in ax:di
	; update event end date as well
	;
	call	GP_DBLockDerefDI		; lock the item, dereference

	mov	cx, {word} ss:[si].DEI_endMinute	
	mov	{word} es:[di].ES_endTimeMinute, cx	
	mov	cl, ss:[si].DEI_varFlags
	mov	es:[di].ES_varFlags, cl

	call	GP_DBDirtyUnlock
done:
	.leave
	ret
DBUpdateEventEndTime	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBUpdateEventText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the text in the database event

CALLED BY:	DBStuffEvent, UpdateEvent

PASS:		AX	= Group # of event
		DI	= Item # of event
		SS:SI	= DayEvent instance data

RETURN:		Nothing

DESTROYED:	DS, ES

PSEUDO CODE/STRATEGY:

Known BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBUpdateEventText	proc	near
	uses	ax, bx, cx, dx, si, di, bp
	.enter

	; Get the text from the text edit object
	;
	push	ax, di
	mov	bx, ss:[si].DEI_block		; get the block handle
	mov	si, ss:[si].DEI_textHandle	; get the text obj handle
	clr	dx				; allocate a block handle
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	mov	di, mask MF_CALL
	call	ObjMessage			; get the text
	mov	bx, cx				; text handle => BX
	mov	cx, ax				; text length => CX
DBCS <	shl	cx, 1				; cx <- size of text>
	pop	ax, di

	; Now re-size the EventStruct and save the size
	;
SBCS <	add	cx, size EventStruct		; leave room for the ES	>
DBCS <	add	cx, (size EventStruct)+1	; leave room for the ES	>
	call	GP_DBReAlloc			; re-allocate the item
	call	GP_DBLockDerefDI		; lock the item, dereference
SBCS <	sub	cx, size EventStruct		; text size back in CX	>
DBCS <	sub	cx, (size EventStruct)+1	; text size back in CX	>
	mov	es:[di].ES_dataLength, cx	; store the length
	add	di, offset ES_data		; move to start of data
continue::
	jcxz	done				; if no text, we're done

	; Else store them bytes
	;
	call	MemLock				; lock that block
	mov	ds, ax
	clr	si				; DS:SI => text
SBCS <	rep	movsb				; copy the bytes	>
DBCS <	shr	cx, 1							>
DBCS <	rep	movsw				; copy the text		>

	; And we're done - clean up
done:
	call	MemFree				; free up the block
SBCS <	mov	{byte} es:[di], 0		; store the NULL-terminator >
DBCS <	mov	{wchar} es:[di], 0		; store the NULL-terminator >
	call	GP_DBDirtyUnlock		; unlock the EventStruct

	.leave
	ret
DBUpdateEventText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInsertAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert an event into the alarm time links

CALLED BY:	GLOBAL

PASS:		AX	= Group # for event to insert
		DI	= Item # for event to insert

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Simply insert into the linked list, both directions

		Register usage:
			BP:DX	= Group:item of new event
			DS:BX	= New event
			AX:CX	= Group:item of current event
			ES:DI	= Current event

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/29/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBInsertAlarm	proc	far

	; If we're a To Do list event or repeat event, then we don't
	; want to mess with the alarm linkages
	;
if	_TODO
	push	si,di
	call	GP_DBLockDerefSI
	test	es:[si].ES_flags, mask EIF_TODO
	call	DBUnlock 
	pop	si,di
LONG	jnz	finish
endif
	; Set up for search
	;
	push	ax,bx,cx,dx,si,di,bp,ds		; save these registers
	mov	bp, ax
	mov	dx, di				; BP:DX = new group:item
	call	GP_DBLock			; lock the new item
	segmov	ds, es				; move segment to DS
	mov	bx, di				; DS:*BX is new event now
	push	bx				; save the handle
	mov	bx, ds:[bx]			; dereference the new handle

	; Determine search direction
	;
	call	GetNextAlarm			; get the next alarm to go off
	mov	cx, di				; current handle is in DI
EC <	cmp	cx, nil 			; check for nil		      >
EC <	ERROR_Z	DB_INSERT_ALARM_BAD_ALARM	; bad alarm handle 	      >
	call	GP_DBLockDerefSI		; lock the current item
	call	CompareEventsByAlarm		; compare the events
	jl	backwardStart			; search backward
	jmp	forwardStart			; search forward

	; Loop searching backward
	;
loopBackward:
	mov	di, cx				; handle to DI
	call	GP_DBLockDerefSI		; lock the item
	call	CompareEventsByAlarm
	jg	insertAfter			; insert new before this item
backwardStart:
	cmp	es:[si].ES_alarmPrevGr, nil	; is the prev item nil ??
	je	insertBeforeIntermediate
	mov	ax, es:[si].ES_alarmPrevGr	; get the next group
	mov	cx, es:[si].ES_alarmPrevIt	; get the next item
	call	DBUnlock			; unlock the current block
	jmp	loopBackward			; continue the loop

	; Loop searching forward
	;
loopForward:
	mov	di, cx				; handle to DI
	call	GP_DBLockDerefSI		; lock the item
	call	CompareEventsByAlarm
	jl	insertBeforeIntermediate	; insert new before this item
forwardStart:
	cmp	es:[si].ES_alarmNextGr, nil	; is the next item nil
	je	insertAfter			; insert new after this item
	mov	ax, es:[si].ES_alarmNextGr	; get the next group
	mov	cx, es:[si].ES_alarmNextIt	; get the next item
	call	DBUnlock			; unlock the current block
	jmp	loopForward			; continue the loop

insertBeforeIntermediate:
	jmp	insertBefore			; perfore the real jump

	; Insert new event AFTER the current one (both events locked)
	;	
insertAfter:
	mov	ds:[bx].ES_alarmPrevGr, ax	; save new's prev group (cur)
	mov	ds:[bx].ES_alarmPrevIt, cx	; save new's prev item (cur)
	push	es:[si].ES_alarmNextGr		; push cur's next group
	push	es:[si].ES_alarmNextIt		; push cur's next item
	pop	ds:[bx].ES_alarmNextIt		; save new's next item (next)
	pop	ds:[bx].ES_alarmNextGr		; save new's next group (next)
	mov	es:[si].ES_alarmNextGr, bp	; save cur's next group (new)
	mov	es:[si].ES_alarmNextIt, dx	; save cur's next item (new)
	call	GP_DBDirtyUnlock		; mark dirty & unlock

	; If next item is nil, done.  Else set up next's back links
	;
	mov	ax, ds:[bx].ES_alarmNextGr	; get the next group
	cmp	ax, nil
	je	done				; if nil, done
	mov	di, ds:[bx].ES_alarmNextIt	; get the next item
	call	GP_DBLockDerefSI		; lock this item
	mov	es:[si].ES_alarmPrevGr, bp	; save next's prev group (new)
	mov	es:[si].ES_alarmPrevIt, dx	; save next's prev item (new)
	call	GP_DBDirtyUnlock		; mark dirty & unlock
	jmp	done				; we're done - hurrah
	
	; Insert new event BEFORE the current one (both events locked)
	;	
insertBefore:
	mov	ds:[bx].ES_alarmNextGr, ax	; save new's next group (cur)
	mov	ds:[bx].ES_alarmNextIt, cx	; save new's next item (cur)
	push	es:[si].ES_alarmPrevGr		; push cur's prev group
	push	es:[si].ES_alarmPrevIt		; push cur's prev item
	pop	ds:[bx].ES_alarmPrevIt		; save new's prev item (prev)
	pop	ds:[bx].ES_alarmPrevGr		; save new's prev group (prev)
	mov	es:[si].ES_alarmPrevGr, bp	; save cur's prev group (new)
	mov	es:[si].ES_alarmPrevIt, dx	; save cur's prev item (new)
	call	GP_DBDirtyUnlock		; mark dirty & unlock

	; If prev item is nil, done.  Else set up prev's forward links
	;
	mov	ax, ds:[bx].ES_alarmPrevGr	; get the next group
	cmp	ax, nil
	je	done				; if nil, done
	mov	di, ds:[bx].ES_alarmPrevIt	; get the next item
	call	GP_DBLockDerefSI		; lock this item
	mov	es:[si].ES_alarmNextGr, bp	; save prev's next group (new)
	mov	es:[si].ES_alarmNextIt, dx	; save prev's next item (new)
	call	GP_DBDirtyUnlock		; mark dirty & unlock
	jmp	done				; we're done - hurrah
	
	; We're done - finally
done:
	pop	di
	segmov	es, ds
	call	GP_DBDirtyUnlock		; mark dirty & unlock
	pop	ax,bx,cx,dx,si,di,bp,ds		; restore all registers
	call	SearchNextAlarm			; reset the next alarm ptr
finish::

	ret
DBInsertAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CompareEventsByAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare two event table entries

CALLED BY:	DayPlanEventToDB

PASS:		DS:BX	= Entry in the day plan
		ES:SI	= Entry in the DB

RETURN:		Sets the approriate flags

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/31/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CompareEventsByAlarm	proc	near
	uses	ax
	.enter

	; First check the years
	;
	mov	ax, ds:[bx].ES_alarmYear	; get the source year
	cmp	ax, es:[si].ES_alarmYear	; subtract destination year
	jne	done

	; Now check the month and day (byte order important!!)
	;
	mov	ax, {word} ds:[bx].ES_alarmDay 	; get day and month
	cmp	ax, {word} es:[si].ES_alarmDay 	; subtract dest day and month
	jne	done

	; Finally check the hour and minute (byte order important !!)
	;
	mov	ax, {word} ds:[bx].ES_alarmMinute ; get source min and hour
	cmp	ax, {word} es:[si].ES_alarmMinute ; subtract dest
done:
	.leave
	ret
CompareEventsByAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBRemoveEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an event from the database

CALLED BY:	GLOBAL

PASS:		AX	= Group # for the event
		DI	= Item # for the event
		SI	= Item # for the event map

RETURN: 	SI	= Number of events left in the day

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version
	kliu	2/27/97		Added NotifyMonths

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBRemoveEvent	proc	near
	uses	cx, dx, di, bp
	.enter

	; Access data to find 
	;
	call	DBDeleteAlarm			; clean up the alarm linkage

	; Now remove me from the EventMap
	;
	mov	cx, di				; deleted item to CX
	mov	di, si				; EventMap handle => DI
	call	GP_DBLockDerefDI		; lock EventMap & dereference
	mov	bp, di				; save start in BP
	sub	es:[di].EMH_numEvents, 1	; decrement number of events
	push	es:[di].EMH_numEvents		; save this number
	add	di, (size EventMapHeader) - (size EventMapStruct)

	; Now loop until we find my item #
	;
searchLoop:
	add	di, size EventMapStruct
	cmp	es:[di].EMS_event, cx
	jne	searchLoop

	; Remove the structure
	;
	mov	dx, di
	sub	dx, bp				; create offset in DX
	call	GP_DBDirtyUnlock		; unlock it first
	mov	di, si				; Event Map item # back to DI
	;
	;mov	bp, cx				; bp = event item #
	;


		mov	cx, size EventMapStruct
		call	GP_DBDeleteAt
		pop	si

		
		
	;
	; remove event structure ( can't because this item is still
	;			   referenced by objects )
	;
	;mov	di, bp			; ax:di = gr#:it# of old event
	;call	GP_DBFree		; free the item
	;
	.leave
	ret
DBRemoveEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDeleteAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete the alarm linkage

CALLED BY:	DBRemoveEvent

PASS:		AX	= Group # for the event
		DI	= Item # for the event

RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:
		Remove this event from the linkage

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBDeleteAlarm	proc	far
	uses	ax, bx, cx, dx, di, bp
	.enter

	; If we're a To Do list event or repeat event, then we don't
	; want to mess with the alarm linkages
	;	
if	_TODO
	push	si,di
	call	GP_DBLockDerefSI		; es:si = event struct
	test	es:[si].ES_flags, mask EIF_TODO	; is this a To Do event ?
	call	DBUnlock 
	pop	si,di
	jnz	done				; yes--done
endif

	; Are we the current alarm
	;
	mov	cx, ax
	mov	dx, di				; CX:DX = event in question
	call	GetNextAlarm			; get the current alarm
	mov	bx, 1				; assume they're the sane
	cmp	cx, ax
	jne	different
	cmp	dx, di
	je	delete

	; They're different, clear the flag
different:
	clr	bx
	mov	ax, cx
	mov	di, dx				; restore item to delete

	; Now extract the information from the current event
delete:
	call	GP_DBLockDerefDI		; lock the event
	mov	cx, es:[di].ES_alarmNextGr
	mov	dx, es:[di].ES_alarmNextIt	; CX:DX = next group:item
	mov	ax, es:[di].ES_alarmPrevGr
	mov	di, es:[di].ES_alarmPrevIt
	mov	bp, di				; AX:BP = prev group:item
	call	DBUnlock			; unlock the block

	; Now set up the previous event's linkage
	;
	call	GP_DBLockDerefDI		; lock the event
	mov	es:[di].ES_alarmNextGr, cx
	mov	es:[di].ES_alarmNextIt, dx	; store the next group:item
	call	GP_DBDirtyUnlock		; mark dirty & unlock this item

	; Now set up the next event's linkage
	;
	xchg	ax, cx				; exchange groups
	mov	di, dx				; item # to DI
	call	GP_DBLockDerefDI		; lock the event
	mov	es:[di].ES_alarmPrevGr, cx
	mov	es:[di].ES_alarmPrevIt, bp	; store the prev group:item
	call	GP_DBDirtyUnlock		; mark dirty & unlock the item
	
	; Need to reset the alarm ?
	;
	tst	bx				; is BX zero ??
	je	done				; if so, no need to reset alarm
	mov	bp, ax				; group to BP, item in DX
	call	SetNextAlarm
done:
	.leave
	ret
DBDeleteAlarm	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBSearchDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Searches a day map for a given day

CALLED BY:	CreateEvent, DeleteEvent, GetDaysEvents

PASS:		AX	= YearMap : Group #
		DI	= YeatMap : Item #
		DH	= Month
 		DL	= Day

RETURN: 	DI	= Item # for the EventMap or Zero
		SI	= Offset into the YearMap for this day

DESTROYED:	ES

PSEUDO CODE/STRATEGY:
		Input   0000MMMM:000DDDDD
		Output  000000MM:MMDDDDD0 (offset in table)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/29/89		Initial version
	Don	10/13/89	Made into search only
	Don	5/24/90		Changed the DayMap structure
	sean	9/4/95		Error checking far version for
				Responder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBSearchDay	proc	near
	uses	bx
	.enter

	; First lock the block, and initialize search
	;
	call	DateToTablePos			; offset => BX
	call	GP_DBLockDerefDI		; lock the yearMap
	mov	di, es:[di][bx]			; item # for this day...
	mov	si, bx				; offset => SI
	call	DBUnlock			; unlock the YearMap

	.leave
	ret
DBSearchDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCreateDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new day for the DB

CALLED BY:	CreateEvent

PASS:		AX	= YearMap : Group # (group for this year)
		DI	= YearMap : Item #
		BP	= Year
		DH	= Month
		DL	= Day
		SI	= Offset into YearMap for this day

RETURN:		DI	= Item # of EventMap for this day

DESTROYED:	ES

PSEUDO CODE/STRATEGY:
		Create the EventMap
		Store the EventMap item # in the YearMap

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/29/89		Initial version
	Don	5/24/90		Changed the DayMap structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBCreateDay	proc	near
	uses	bx, cx, bp
	.enter
	
	; First allocate the new day's event map
	;
	mov	bx, di				; YearMap item # => BX
	call	DBCreateEventMap		; Item # => DI

	; Now insert a DayMapStruct
	;
	xchg	bx, di				; exchange YearMap, EventMap
	call	GP_DBLockDerefDI		; lock the YearMap
	inc	{word} es:[di].yearMapDayCount	; increment the day count
	add	di, si				; add in offset to this day
	mov	es:[di], bx			; store the EventMap item #
	call	GP_DBDirtyUnlock		; unlock the day map block
	mov	di, bx				; EventMap item # => DI

	; Tell the YearObject what month has changed
	;
	call	DBNotifyMonthChange		; change in month DH/ BP

	.leave
	ret
DBCreateDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCreateEventMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create the event map for a day, and return the header

CALLED BY:	DBCreateDay

PASS:		AX	= Group of day map (group for this year)
		DX	= Month/Day
		BP	= Year
		DS	= DGroup

RETURN:		DI	= Item # for the event map

DESTROYED:	ES

PSEUDO CODE/STRATEGY:
		Create an event map block
		Create an item for the header event

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/30/89		Initial version
	Don	5/24/90		Changed the DayMap structure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBCreateEventMap	proc	near
	uses	cx, dx
	.enter

	; Create the event map, and initialize it
	;
	mov	cx, size EventMapHeader 	; Size of the EventMap
	call	GP_DBAlloc			; re-size this item
	mov	cx, di				; mov map item # to CX
	call	GP_DBLockDerefDI		; lock the item
	clr	es:[di].EMH_numEvents		; zero events
	mov	es:[di].EMH_item, cx		; save my item #
	mov	{word} es:[di].EMH_day, dx	; store the month/day
	call	GP_DBDirtyUnlock		; we're done
	mov	di, cx				; map item # back in DI

	.leave
	ret
DBCreateEventMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDeleteDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free the event map for that day, and remove the DayMapStruct

CALLED BY:	GLOBAL

PASS:		AX	= YearMap : Group # (group for this year)
		DI	= YearMap : Item #
		SI	= Offset to the day in the YearMap
		DX	= Month/Day to delete
		BP	= Year of this Month/Day

RETURN:		SI	= Number of days left in the YearMap

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version
	Don	5/24/90		Changed the DayMap structure
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBDeleteDay	proc	near
	uses	di
	.enter

	; Update the DayMapHeader
	;
	call	GP_DBLockDerefDI		; lock the DayMap
	dec	{word} es:[di].yearMapDayCount	; decrement day count
	push	es:[di].yearMapDayCount		; save the count
	
	; Find the correct EventMap
	;
	add	si, di				; EventMapStruct => ES:SI
	clr	di
	xchg	di, es:[si]			; EventMap item # => DI
EC <	tst	di				; valid Item #		      >
EC <	ERROR_Z		DB_DELETE_INVALID_EVENT_MAP			      >
EC <	push	es, di				; save the item #	      >
EC <	call	GP_DBLockDerefDI		; lock it		      >
EC <	cmp	es:[di].EMH_numEvents, 0	; check the number of events  >
EC <	ERROR_NZ	DB_DELETE_WRONG_EVENT_COUNT			      >
EC <	cmp	{word} es:[di].EMH_day, dx	; compare the month & day     >
EC <	ERROR_NZ	DB_DELETE_WRONG_DAY	; deleting the wrong day      >
EC <	call	DBUnlock			; unlock the item	      >
EC <	pop	es, di				; restore the item #	      >
	call	GP_DBFree			; free the EventMap (in AX:DI)
	call	GP_DBDirtyUnlock		; unlock the YearMap item
	pop	si				; restore day count

	;
	;	No need to notifyMonthChange in responder since removeEvent has taken
	;	care of that.
	;
	; Tell the YearObject what month has changed
	;
	call	DBNotifyMonthChange		; change in month DH/BP
	.leave
	ret
DBDeleteDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBSearchYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the desired year (get handle to that year's Day map)

CALLED BY:	INTERNAL

PASS: 		BP	= Year

RETURN:		AX	= Group # for the new year
		DI	= Item # number of the Day map block for year
		SI	= Offset to into the Year map block for this year

		Note:	If not found, AX & DI = Zero
			SI = offset to insert new year in the YearMapBlock

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Get the MapBlock for this database
		Search for the year's position

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/29/89		Initial version
	Don	10/12/89	Added deletion support
	sean	9/4/95		Error checking far version for
				Responder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBSearchYear	proc	near
	uses	cx, bp
	.enter

	; Access the map block, verify it, look at header
	;
EC <	call	GP_DBVerify			; verifiy it		>
	call	GP_DBLockMap			; get the map block, lock it
	mov	si, es:[di]			; dereference the handle
	mov	cx, es:[si].YMH_numYears	; get the number of years
	add	si, size YearMapHeader		; position SI to first year
	tst	cx				; no years ??
	je	notFound			; no years, so jump

	; Loop until we find year's position
	;
searchLoop:
	cmp	es:[si].YMS_year, bp		; compare the years
	jg	notFound			; if greater than desired, jmp
	je	found				; if equal, jump
	add	si, size YearMapStruct		; increment pointer
	loop	searchLoop			; loop on CX

	; Found or didn't find the desired year
	;
notFound:
	clr	ax
	clr	cx
	jmp	done
found:
	mov	ax, es:[si].YMS_group		; get the group #
	mov	cx, es:[si].YMS_yearMap		; get the day map
	
	; Perform the appropriate action
	;
done:
	sub	si, es:[di]			; calculate true offset
	call	DBUnlock			; unlock the locked block
	mov	di, cx				; mov day map item # into DI

	.leave
	ret					; we're done
DBSearchYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCreateYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new YearMapStruct, and a new DayMap for the year

CALLED BY:	GLOBAL

PASS: 		SI	= Location to insert new structure
		BP	= Year

RETURN:		AX	= Group # for YearMap
		DI	= Item # of YearMap

DESTROYED:	SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	---	----		-----------
	Don	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBCreateYear	proc	near
	uses	cx, dx
	.enter

	; Perform some set-up work
	;
EC <	call	GP_DBVerify			; verify the map block	>
	call	GP_DBGetMap			; get the map bloc
	mov	dx, si				; offset to DX
	mov	cx, size YearMapStruct		; size of struct to insert
	call	GP_DBInsertAt			; insert the bytes
	call	GP_DBLock			; lock the YearMapBlock
	
	; Allocate new group and YearMap
	;
	push	di				; save year map handle
	call	GP_DBGroupAlloc			; allocate a new group
	mov	cx, YearMapSize			; size of every YearMap
	call	GP_DBAlloc			; allocate the day map
	mov	cx, di				; put day map item # into CX
	pop	di				; restore year map handle

	; Fill in the YearMap struct
	;
	mov	si, es:[di]			; dereference YearMap handle
	inc	es:[si].YMH_numYears		; increment the number of years
	add	si, dx				; SI points to new data	
	mov	es:[si].YMS_year, bp		; save the new year
	mov	es:[si].YMS_group, ax		; save the new group
	mov	es:[si].YMS_yearMap, cx		; save the new item number
	call	GP_DBDirtyUnlock		; unlock the YearMapBlock

	; Initialize the new day map
	;
	mov	di, cx				; move the YearMap to DI
	mov	dx, cx				; YearMap item # => DX
	call	GP_DBLockDerefSI		; lock this item
	mov	cx, YearMapSize			; size of the YearMap
	call	ClearSomeBytes			; clear the YearMap
	call	GP_DBDirtyUnlock		; unlock the item
	mov	di, dx				; return YearMap item # in DI

	.leave
	ret
DBCreateYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDeleteYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes the given year from the database

CALLED BY:	GLOBAL

PASS: 		BP	= Year
		SI	= Offset to YearMap block for this year

RETURN:		SI	= Count of years remaining

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBDeleteYear	proc	near
	uses	ax, bx, cx, dx, di, bp
	.enter

	; First access the YearMapBlock
	;
EC <	call	GP_DBVerify			; verify it		      >
	call	GP_DBGetMap			; get the YearMap block
	mov	bx, ax				; put group # to BX
	mov	dx, di				; put item # to DX

	; Delete the DayMapBlock beneath us
	;
	call	GP_DBLockDerefDI		; lock the YearMapBlock
	dec	es:[di].YMH_numYears		; one less year
	push	es:[di].YMH_numYears		; save the year count
	add	di, si				; go to correct YearMapStruct
EC <	cmp	es:[di].YMS_year, bp					      >
EC <	ERROR_NZ	DB_DELETE_WRONG_YEAR	; deleting the wrong year     >
	mov	ax, es:[di].YMS_group
	mov	di, es:[di].YMS_yearMap		; get group & item #
	call	GP_DBDirtyUnlock		; unlock the YearMapBlock

	; Verify the DayMap is empty
	;
EC <	push	di				; save the item #	      >
EC <	call	GP_DBLockDerefDI		; lock the item		      >
EC <	tst	<{word} es:[di].yearMapDayCount> ; check the count	      >
EC <	ERROR_NZ	DB_DELETE_NON_EMPTY_DAYMAP			      >
EC <	call	DBUnlock			; unlock the block	      >
EC <	pop	di				; restore the item #	      >
	call	GP_DBFree			; free the YearMap item
	call	UndoNotifyGroupFree		; tell undo to remove group
	; Now delete this structure and clean up
	;
	mov	ax, bx				; YearMap group # to AX
	mov	di, dx				; YearMap item # to DI
	mov	dx, si				; offset to delete at
	mov	cx, size YearMapStruct		; bytes to delete
	call	GP_DBDeleteAt
	pop	si				; restore the # of years left

	.leave
	ret
DBDeleteYear	endp

if	SEARCH_EVENT_BY_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBInsertEventIDArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new event ID array element

CALLED BY:	(INTERNAL) CreateEvent, RepeatInsertDeleteEventIDArray
PASS:		cxdx	= unique event ID
		ax:di	= DB Group:Item of corresponding event
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	** WARNING **

	The event to insert has to be existing. The unique ID and that in DB 
	group:item have to match.

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/16/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBInsertEventIDArray	proc	far
	element	local	EventIDArrayElemStruct	; element to append
		uses	ax, bx, cx, dx, di, si, ds
		.enter
		Assert	eventIDFromDB	cxdx, ax, di
EC <		push	ax, cx, dx, di					>
EC <		call	DBSearchEventIDArray	; carry set if event found>
EC <						; ax:di=Gr:It, cxdx=index>
EC <		ERROR_C CALENDAR_EVENT_ID_ARRAY_ID_ALREADY_EXISTS	>
EC <		pop	ax, cx, dx, di					>
	;
	; Initialize element to insert with data
	;
		segmov	ds, ss, si
		lea	si, ss:[element]	; ds:si = empty element
		movdw	ds:[si].EIDAES_eventID, cxdx
		mov	ds:[si].EIDAES_eventGr, ax
		mov	ds:[si].EIDAES_eventIt, di
	;
	; Lock down map block and get event ID array block
	;
		call	GP_DBLockMap		; *es:di = map block
		mov	di, es:[di]		; es:di = YearMapHeader
		mov	di, es:[di].YMH_eventIDArray
						; di = huge array handle
		call	DBUnlock		; es destroyed
	;
	; Insert the element
	;
		push	bp
		mov	bp, ds			; bp:si = elem to insert
		GetResourceSegmentNS	dgroup, ds
		mov	bx, ds:[vmFile]		; bx = huge array file handle
		Assert	HugeArray	di, bx
		mov	cx, 1			; # of element to insert
		call	HugeArrayAppend		; dxax = element #
		pop	bp

		.leave
		ret
DBInsertEventIDArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBSearchEventIDArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look up event Group:Item by event ID

CALLED BY:	(INTERNAL) DBDeleteEventIDArray, DayPlanDeleteEventByIDFromApi,
		DayPlanGetEventByIDFromApi, DayPlanModifyEventByIDFromApi,
		GetCreatedEventGrIt, HandleAcceptDenyReply
PASS:		cxdx	= event ID
RETURN:		carry set if event found
			ax:di	= Group:Item of the event
			cxdx	= element index of matched event
		carry clear if event not found
DESTROYED:	es
		if carry clear,
			ax, cx, dx, di destroyed
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/16/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBSearchEventIDArray	proc	far
		uses	bx, bp
		.enter
		Assert	eventID	cxdx
	;
	; Enumerate the array to find the event Group:Item
	; Set up the arguments
	;
		GetResourceSegmentNS	dgroup, es
		Assert	vmFileHandle	es:[vmFile]
		push	es:[vmFile]		; VM File (1st arg)
		
		call	GP_DBLockMap		; *es:di = map block
		mov	di, es:[di]		; es:di = YearMapHeader
		push	es:[di].YMH_eventIDArray; huge array (2nd arg)
		call	DBUnlock		; es destroyed
						
		CheckHack <segment DBSearchEventIDArray eq \
			   segment DBSearchEventIDArrayCallback>
		mov	ax, SEGMENT_CS
		mov	bx, offset DBSearchEventIDArrayCallback
		pushdw	axbx			; vfptr of callback (3rd arg)

		clr	ax			; start from 1st elem
		pushdw	axax			; starting elem (4th arg)

		mov	ax, -1			; enum to the end 
		pushdw	axax			; # elem to process (5th arg)

		clrdw	axbp			; initialize element count
		call	HugeArrayEnum		; carry set if elem found
						;   ax:bp = Gr:It of elem
						;   cxdx = element index
		jnc	done
	;
	; Event Group:Item found. Return result
	;
		mov	di, bp			; ax:di = Gr:It of elem
done:
		.leave
		ret
DBSearchEventIDArray	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBSearchEventIDArrayCallback
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback of DBSearchEventIDArray via HugeArrayEnum

CALLED BY:	(INTERNAL) DBSearchEventIDArray via HugeArrayEnum callback
PASS:		cxdx	= event ID to match
		axbp	= current element index 
		ds:di	= EventIDArrayElemStruct of current element
RETURN:		carry set if event found, i.e., event ID matched (and abort
		enumeration) 
			ax:bp	= DB Group:Item of the event
			cxdx	= element index of this matched element
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	if (event ID matched) {
		Return event Group:Item and element index;
		Abort enumeration;
	} else {
		element index++;
		Enum next element;
	}

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	simon	2/17/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBSearchEventIDArrayCallback	proc	far
		.enter

		cmpdw	cxdx, ds:[di].EIDAES_eventID
		jne	noMatch
	;
	; It is a match. Grab the Group:Item from the array element
	;
EC <		pushdw	axbp			; save element index	>
NEC <		movdw	cxdx, axbp		; cxdx = element index	>
		mov	ax, ds:[di].EIDAES_eventGr
		mov	bp, ds:[di].EIDAES_eventIt
		Assert	eventIDFromDB	cxdx, ax, bp
EC <		popdw	cxdx			; cxdx = element index	>
		stc
		jmp	done

noMatch:
		incdw	axbp			; increase element count
		clc				; search next item

done:
		.leave
		ret
DBSearchEventIDArrayCallback	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBDeleteEventIDArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete an element from the event ID array

CALLED BY:	(INTERNAL) DBUpdateDate, DeleteEvent,
		RepeatInsertDeleteEventIDArray
PASS:		cxdx	= event ID of the element to delete
RETURN:		carry set if element not found
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get element index from huge array;
	if (there is a match) {
		delete element from array;
	}		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/16/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DBDeleteEventIDArray	proc	far
		uses	ax, bx, cx, dx, di
		.enter
	;
	; Search the element
	;
		call	DBSearchEventIDArray	; carry clear if no match
						;   otherwise, ax:di=Gr:It
						;   cxdx = element index
		cmc
		jc	done			; no match
	;
	; Delete the element from the array
	;
		mov_tr	ax, dx
		mov	dx, cx			; dxax = element index
		GetResourceSegmentNS	dgroup, es
		mov	bx, es:[vmFile]		; bx = VM file handle
		Assert	vmFileHandle	bx
		
		call	GP_DBLockMap		; *es:di = map block
		mov	di, es:[di]		; es:di = YearMapHeader
		mov	di, es:[di].YMH_eventIDArray
		call	DBUnlock		; es destroyed
						
		mov	cx, 1			; delete just 1 element
		call	HugeArrayDelete
		clc				; elem found and deleted
done:
		.leave
		ret
DBDeleteEventIDArray	endp

endif	; SEARCH_EVENT_BY_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBNotifyMonthChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tell the year about a change in one or more months

CALLED BY:	Database INTERNAL
	
PASS:		BP	= Year (or 0 for all years & months)
		DH	= Month

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBNotifyMonthChange	proc	far
	uses	ax, bx, di, si
	.enter

	mov	ax, MSG_YEAR_CHANGE_MONTH_MAP
	GetResourceHandleNS	YearObject, bx
	mov	si, offset YearObject
	call	ObjMessage_common_send		; send the message

	.leave
	ret
DBNotifyMonthChange	endp



DBGetMonthMap	proc	far
	uses	ax, bx
	.enter

	; Obtain the MonthMaps for both normal & repeat events
	;
	mov	si, cx				; Month chunk handle => SI
	clr	ax
	clr	bx
	test	es:[systemStatus], SF_VALID_FILE
	jz	done				; jump if no valid file
	call	GetMonthMapEvents		; Events MonthMap => BX:AX
	call	GetMonthMapRepeats		; Repeat MonthMap => DX:CX
	or	ax, cx				; OR-in these values...
	or	bx, dx
done:
	mov	cx, ax				; store the values...
	mov	dx, bx
	GetResourceHandleNS	Interface, bx
	mov	ax, MSG_MONTH_SET_MONTH_MAP
	call	ObjMessage_common_send

	.leave
	ret
DBGetMonthMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMonthMapEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the month map of events for the desired month

CALLED BY:	DBGetMonthMap
	
PASS: 		ES	= DGroup
		BP	= Year
		DH	= Month

RETURN:		AX:BX	= MonthMap

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetMonthMapEvents	proc	near
	uses	cx, dx, di, si, es
	.enter

	; Get the YearMap, and call to create the month map
	;
	clr	bx
	call	DBSearchYear			; look for the year
	tst	ax				; did we find one ??
	jz	done				; no - done!
	call	GP_DBLockDerefSI		; lock the YearMap
	call	CreateMonthMap			; MonthMap => CX:DX
	call	DBUnlock
	mov	ax, cx
	mov	bx, dx
done:
	.leave
	ret
GetMonthMapEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateMonthMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a bitfield array repore

CALLED BY:	INTERNAL to database routines
	
PASS:		ES:SI	= YearMap or RepeatMap
		DH	= month

RETURN:		CX:DX	= MonthMap bitfield

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateMonthMap	proc	near
	uses	ax, bx, si
	.enter

	mov	dl, 31				; start at day 31
	call	DateToTablePos			; offset => BX
	add	si, bx				; ES:SI => end of month
	mov	ax, -1				; set this flag

	; Loop here
outerLoop:
	mov	bx, dx				; old value => BX
	clr	dx				; no bits set initially
	mov	cx, 16				; loop sixteen times
	inc	ax				; increment the flag value
createLoop:
	shl	dx, 1
	tst	<{word} es:[si]>		; any events here ??
	jz	next				; no, jump
	or	dx, 1				; else set the low bit
next:
	sub	si, 2				; back up one word
	loop	createLoop			
	tst	ax				; have we looped before
	jz	outerLoop			; if not, loop again

	; We're done
	;
	mov	cx, bx				; high 16 bits => CX
						; low 16 bits already in DX
	.leave
	ret
CreateMonthMap	endp


CommonCode	ends

if _USE_INK
InkCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DBCreateInkEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new ink "event" for the database

CALLED BY:	UpdateEvent

PASS:		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Group # for the new ink "event"
		DX	= Item # for the new ink "event"

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DBCreateInkEvent	proc	far
	uses	ax, bx, di, es
	.enter

	; Create or find the necessary EventMap, and create an event
	;
	call	DBGetEventMap
	mov	bx, di				; save the EventStruct
	mov	cx, size EventStruct		; get size of item to create
	call	GP_DBAlloc			; allocate an item

	; Initialize the ink event values
	;
	push	di				; save the item #
	call	GP_DBLockDerefDI		; lock the item & dereference
	mov	es:[di].ES_parentMap, bx	; store the parent item #
	clr	es:[di].ES_repeatID
	mov	es:[di].ES_flags, mask EIF_INK
	mov	es:[di].ES_dataLength, INK_DATA_LENGTH
	clr	es:[di].ES_data
	mov	es:[di].ES_timeYear, bp
	mov	{word} es:[di].ES_timeDay, dx
	mov	{word} es:[di].ES_timeMinute, EVENT_TIME_INK
	call	GP_DBDirtyUnlock
	pop	di				; restore the item #

	; Return new event in CX:DX
	;
	mov	cx, EVENT_TIME_INK
	call	DBInsertEvent			; insert event into EventMap
	mov	cx, ax				; CX:DX is the new item
	mov	dx, di

	.leave
	ret
DBCreateInkEvent	endp

InkCode		ends
endif	; if _USE_INK


UndoActionCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RecreateEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-insert a previously existing event

CALLED BY:	Undo - Internal

PASS:		AX	= Group #
		DI	= Item #

RETURN:		AX	= Inserted Event: Group
		DI	=                 Item

DESTROYED:	BX, CX, DX, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/27/90		Initial version
	SS	3/23/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RecreateEvent	proc	near
	.enter

	; Obtain the year, month/day/ and minute/hour information
	;
	call	GP_DBLock			; lock the item
	segmov	ds, es
	mov	si, di				; DS:*SI points to source
	mov	bp, ds:[si]			; dereference the handle
	push	{word} ds:[bp].ES_timeMinute	; store the hour/minute
	mov	cx, ds:[bp].ES_dataLength	; Length of the data => CX
	mov	dx, {word} ds:[bp].ES_timeDay	; Month/Day => DX
	mov	bp, ds:[bp].ES_timeYear		; Year => BP
TODO <	cmp	bp, TODO_DUMMY_YEAR		; To Do event ?		>
TODO <	jz	toDoList						>
	call	DBGetEventMap			; EventMap: group => AX
TODO <	jmp	continue						>
toDoList::
TODO <	call	DBGetToDoMap			; Get To Do list map 	>
continue::					

	; Copy the EventStruct to the new block
	;
	mov	bx, di				; EventMap handle to BX
	add	cx, size EventStruct		; total size of EventStruct
	call	GP_DBAlloc
	mov	bp, di				; new item # => BP
	call	GP_DBLockDerefDI		; lock the new item, derefernce
	mov	si, ds:[si]
	mov	ds:[si].ES_parentMap, bx	; store the parent map
	rep	movsb				; copy the bytes
	call	GP_DBDirtyUnlock
	segmov	es, ds
	call	DBUnlock
	
	; Finally insert the event into the database
	;
	pop	cx				; hour/minute to CX
	mov	di, bp				; AX:DI is the new event
	call	DBInsertEvent			; insert it into the database

	.leave
	ret
RecreateEvent	endp

UndoActionCode	ends



SearchCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DatabaseGetFirstLastDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the date of the first OR last event in the database

CALLED BY:	GLOBAL (must be running in the Calendar process thread)

PASS:		CX	= 0 for date of the first event
			<> 0 for date of the last event

RETURN:		BP	= Year
		DH	= Month
		DL	= Day
		Note: if there are no events, DX will be 0

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DatabaseGetFirstLastDate	proc	far
	uses	ax, bx, cx, di, si, es
	.enter

	; Access the map block
	;
EC <	call	GP_DBVerify			; and verify the map block >
	call	GP_DBLockMap			; get the map block, lock it
	clr	dx
	clr	bp				; assume no events
	mov	di, es:[di]			; dereference the handle
	mov	ax, es:[di].YMH_numYears	; number of years => AX
	tst	ax				; any years ?
	jz	done				; if not, we're done!

	; Now find the first or last year
	;
	add	di, size YearMapHeader		; DS:DI points to first YMS
	clr	bx				; assume first
	tst	cx				; first or last
	jz	getYear				; if zero, first
	dec	ax				; go to zero-based system
	shl	ax, 1				; 2 * index => AX
	mov	bx, ax
	shl	ax, 1				; 4 * index => AX
	add	bx, ax				; YearMapStruct is 6 bytes long
getYear:
	mov	bp, es:[di][bx].YMS_year	; year => BP
	mov	ax, es:[di][bx].YMS_group
	mov	di, es:[di][bx].YMS_yearMap	; group:item => AX:DI
	call	DBUnlock			; unlock the Map block

	; Now get first or last date
	;
	call	GP_DBLockDerefDI		; lock the YearMap
	mov	si, di				; start of map also => SI
	add	di, 2				; ignore the inital count
	mov	bx, -2				; post-scan correction
	tst	cx				; scan forward ??
	jz	scanHere
	std					; scan backward
	mov	bx, 2				; post-scan correction
	add	di, (YearMapSize - 4)		; and start at the end	
scanHere:	
	clr	ax				; scan for a zero
	mov	cx, (YearMapSize - 2)		; bytes to scan
	repz	scasw				; scan forward or backward
	cld					; clear the direction flag
	jz	done				; if non-zero not found, done!
	add	bx, di				; add offset to correct value
	sub	bx, si				; actual offset => BX
	call	TablePosToDateFar		; month/day => DX
done:	
	call	DBUnlock			; unlock some block

	.leave
	ret
DatabaseGetFirstLastDate	endp

SearchCode	ends



FixedCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBGetMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBGetMap

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		AX	= Group # of map block
		DI	= Item # of map block

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBGetMap	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBGetMap
	pop	bx
	ret
GP_DBGetMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBLockMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBLockMap

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN: 	*ES:DI	= Map block

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBLockMap	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBLockMap
	pop	bx
	ret
GP_DBLockMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBGroupAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBGroupAlloc

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN: 	AX	= Group #

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBGroupAlloc	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBGroupAlloc
	pop	bx
	ret
GP_DBGroupAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBAlloc

CALLED BY:	GLOBAL

PASS:		AX	= Group #
		CX	= Size (in bytes)

RETURN: 	DI	= Item #

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBAlloc	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBAlloc
	pop	bx
	ret
GP_DBAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBReAlloc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBReAlloc

CALLED BY:	GLOBAL

PASS:		AX	= Group #
		DI	= Item #
		CX	= New Size (in bytes)

RETURN: 	Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBReAlloc	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBReAlloc
	pop	bx
	ret
GP_DBReAlloc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBInsertAt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBInsertAt

CALLED BY:	GLOBAL

PASS:		AX	= Group #
		DI	= Item #
		CX	= Size to insert (in bytes)
		DX	= Offset to insertion point

RETURN: 	Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBInsertAt	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBInsertAt
	pop	bx
	ret
GP_DBInsertAt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBDeleteAt
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBDeleteAt

CALLED BY:	GLOBAL

PASS:		AX	= Group #
		DI	= Item #
		CX	= Size to delete (in bytes)
		DX	= Offset to deletion point

RETURN: 	Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBDeleteAt	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBDeleteAt
	pop	bx
	ret
GP_DBDeleteAt	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBGroupFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBGroupFree

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN: 	AX	= Group # to free

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBGroupFree	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBGroupFree
	pop	bx
	ret
GP_DBGroupFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBFree

CALLED BY:	GLOBAL

PASS:		AX	= Group #
		DI	= Item # to free

RETURN: 	Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBFree	proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBFree
	pop	bx
	ret
GP_DBFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBLock, GP_DBLockDerefDI, GP_DBLockDerefSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform a DBLock followed by a dereference

CALLED BY:	INTERNAL

PASS:		AX	= Group #
		DI	= Item #

RETURN:		*ES:DI	= Item (GP_DBLock)
		ES:DI	= Dereferenced item (DerefDI)
		ES:SI	= Dereferenced item (DerefSI)
		
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBLock		proc	far
	push	bx
	call	GP_GetVMFileHan
	call	DBLock	
	pop	bx
	ret
GP_DBLock		endp

GP_DBLockDerefDI	proc	far
	call	GP_DBLock
	mov	di, es:[di]
	ret
GP_DBLockDerefDI	endp

GP_DBLockDerefSI	proc	far
	call	GP_DBLock
	mov	si, es:[di]
	ret
GP_DBLockDerefSI	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBDirtyUnlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stub for DBDirty folllowed by a DBUnlock

CALLED BY:	GLOBAL

PASS:		ES	= DB segment

RETURN: 	Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_DBDirtyUnlock	proc	far
		call	DBDirty
		call	DBUnlock
		ret
GP_DBDirtyUnlock	endp

if _USE_INK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_GetVMFileHan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the VM file handle for the current file

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GP_GetVMFileHanFar	proc	far
	call	GP_GetVMFileHan
	ret
GP_GetVMFileHanFar	endp
endif


GP_GetVMFileHan	proc	near
	push	ds
	GetResourceSegmentNS	dgroup, ds, TRASH_BX
	mov	bx, ds:[vmFile]
	pop	ds
	ret
GP_GetVMFileHan	endp


if	ERROR_CHECK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GP_DBVerify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that this is a calendar database

CALLED BY:	GLOBAL

PASS:		Nothing
		
RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Check the security bytes

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/18/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GP_DBVerify	proc	far
	uses	ax, di, es
	.enter
	
	; Now check the security bytes
	;
	call	GP_DBLockMap			; lock the map block
	mov	di, es:[di]			; dereference the handle
	cmp	es:[di].YMH_secure1, SECURITY1	; check the first byte
	ERROR_NZ	FAILED_SECURITY_TEST
	cmp	es:[di].YMH_secure2, SECURITY2	; check the second byte
	ERROR_NZ	FAILED_SECURITY_TEST
	call	DBUnlock			; unlock the map block

	.leave
	ret
GP_DBVerify	endp


endif		; if Responder

FixedCode	ends

CommonCode	segment resource

if	ERROR_CHECK
if	UNIQUE_EVENT_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ECValidateEventIDFromDB
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Validate an event ID is the same as the one in event in
		database 

CALLED BY:	(GLOBAL)
PASS:		cxdx	= event ID to check
		ax:di	= Event DB Group:Item to check
RETURN:		nothing
DESTROYED:	es and maybe ds if it points to the event block of DB
		Group:item  (flags preserved)
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/16/97    	Initial version
	simon		2/23/97		Added checks for repeat event

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ECValidateEventIDFromDB	proc	far
		pushf
		uses	bx, di
		.enter
		Assert	eventID	cxdx
	;
	; Since the DB item can be a repeat event (RepeatStruct) or a normal
	; event (EventsTruct), we want to figure out what offset to set to get
	; ID in the struct.
	;
	; As all repeat events are stored in the same group, we can tell
	; if the event is repeat event by checking its group number.
	;
		mov	bx, offset ES_uniqueID	; default is normal event.
		IsEventRepeatEvent	ax	; ZF set if repeat event
		jnz	checkEvent		; jmp if a normal event

		mov	bx, offset RES_uniqueID	; bx = offset in struct to
						; get unique ID
	;
	; Find the event from DB group:item
	;
checkEvent:
		call	GP_DBLockDerefDI	; es:di = event struct
		cmpdw	cxdx, es:[di][bx]
		ERROR_NE CALENDAR_ILLEGAL_EVENT_ID
		call	DBUnlock		; es destroyed

		.leave
		popf
		ret
ECValidateEventIDFromDB	endp

endif	; UNIQUE_EVENT_ID
endif	; ERROR_CHECK


CommonCode	ends
