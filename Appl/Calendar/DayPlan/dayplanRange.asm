COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Dayplan
FILE:		dayplanRange.asm

AUTHOR:		Don Reeves, December 19, 1989

ROUTINES:
	Name			Description
	----			-----------
	DayPlanSetRange		Set the range of days to be displayed
	DayPlanSetTitle		Set the title text for the DayPlan
	DayPlanAddRange		Add a range of days to the DayPlan
	DayPlanDeleteRange	Delete a range of days from the DayPlan
	DayPlanAddTemplate	Add a template to the DayPlan
	DayPlanAlterRange	Request change of range (backward or forward)
	DayPlanAlterRangeNow	Actually alters displayed range
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/19/89	Initial revision

DESCRIPTION:
	Implements the functionality to change the range of displayed
	days in the DayPlan.  Does not actually store events, or allocate
	buffers (see dayplanEvent.asm)
		
	$Id: dayplanRange.asm,v 1.1 97/04/04 14:47:43 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanFileOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We now have a valid DB file.  Enable everything, and
		request that the events be loaded.

CALLED BY:	GLOBAL (MSG_DP_FILE_OPEN)

PASS:		ES	= DGroup
		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanFileOpen	method dynamic DayPlanClass,	MSG_DP_FILE_OPEN

	; Set everything enabled, and load the events
	;
	or	ds:[di].DPI_flags, DP_RELOAD or \
		                   DP_FILE_VALID or \
		                   DP_NEEDS_REDRAW
	mov	ax, MSG_DP_SET_RANGE
	mov	bx, ds:[LMBH_handle]		; DayPlan OD => BX:SI
	mov	di, mask MF_CHECK_DUPLICATE or \
		    mask MF_REPLACE or \
		    mask MF_FORCE_QUEUE
	call	ObjMessage			; set the range to view

	; Enable the appropriate UI
	;
	GetResourceHandleNS	CalendarRight, bx
	mov	si, offset 	CalendarRight
	mov	ax, MSG_GEN_SET_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	GOTO	DayPlanSetActionStatus
DayPlanFileOpen	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanFileClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called as a precursor to a file going away.  Remove all the
		events (and update all of them), and set the DayPlan stuff
		not enabled.

CALLED BY:	GLOBAL (MSG_DP_FILE_CLOSE)

PASS:		ES	= DGroup
		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanFileClose	method dynamic DayPlanClass, MSG_DP_FILE_CLOSE

	; Now force removal of the current day's events
	;
	and	ds:[di].DPI_flags, not DP_FILE_VALID
	mov	ax, MSG_DP_DELETE_RANGE
	mov	cl, BufferUpdateFlags <0, 0, 1>	; delete the events
	call	ObjCallInstanceNoLock		; send the method now
	mov	cx, size EventTableHeader	; no events left
	clr	dl				; pass no ScreenUpdateFlags
	mov	ax, MSG_DP_SCREEN_UPDATE	; update the screen
	call	ObjCallInstanceNoLock		; do it

	; Clear any displayed ink
	;
	test	es:[viewInfo], mask VI_PEN_MODE
	jz	disable
	mov	ax, MSG_DP_CLEAN_INK
	call	ObjCallInstanceNoLock

	; Set everything disabled
disable:
	GetResourceHandleNS	CalendarRight, bx
	mov	si, offset 	CalendarRight
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage
	FALL_THRU	DayPlanSetActionStatus
DayPlanFileClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSetActionStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Setup the EditNew trigger's ENABLE status

CALLED BY:	DayPlanFileOpen, DayPlanFileClose

PASS:		AX	= Message to send to the add trigger(s)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version
	Don	4/20/90		Much simplified

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSetActionStatus	proc	far

	; Tell the application object all about it
	;
	mov_tr	cx, ax				; message to send => AX
	mov	bp, mask VUID_DOCUMENT_STATE
	call	UpdateVisibilityData		; update the visibility data
	ret
DayPlanSetActionStatus	endp

FileCode	ends



DayPlanCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanVerifyEventTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Verify that the EventTable is consistent.
		Only defined (of course) for the EC version.

CALLED BY:	GLOBAL
	
PASS:		DS	= DPResource segment

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/10/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	ERROR_CHECK
DayPlanVerifyEventTable	proc	near
	class	DayPlanClass
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	; Access the event table
	;
	mov	si, offset DayPlanObject	; object handle => SI
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access my instance data
	mov	si, ds:[si].DPI_eventTable	; event table handle => SI
	mov	si, ds:[si]			; dereference the table

	; Let's perform some size checks
	;
	ChunkSizePtr	ds, si, cx		; table size => CX
	cmp	cx, ds:[si].ETH_last		; table size correct ?
	ERROR_NE	DP_VERIFY_INVALID_EVENT_TABLE
	cmp	cx, size EventTableHeader	; only a header present ?
	LONG	je	done			; then abort other checking
	mov	dx, ds:[si].ETH_screenFirst	; first offset => DX
	cmp	dx, OFF_SCREEN_TOP		; off the screen ?
	jne	continueHeader
	cmp	ds:[si].ETH_screenLast, OFF_SCREEN_BOTTOM
	je	done
	ERROR		DP_VERIFY_INVALID_EVENT_TABLE
continueHeader:
	cmp	dx, cx				; compare first with table size
	ERROR_AE	DP_VERIFY_INVALID_EVENT_TABLE
	mov	bp, ds:[si].ETH_screenLast	; last offset => BP
	cmp	bp, cx				; compare last with table size
	ERROR_AE	DP_VERIFY_INVALID_EVENT_TABLE
	cmp	dx, bp				; compare first with last
	ERROR_A		DP_VERIFY_INVALID_EVENT_TABLE

	; Now let's see if the table header is accurate...
	;
	mov	bx, (size EventTableHeader - size EventTableEntry)
checkLoop:
	add	bx, size EventTableEntry	; go to the next ETE
	cmp	bx, cx				; are we done ??
	je	done				; yes - valid table
	ERROR_A		DP_VERIFY_INVALID_EVENT_TABLE
	mov	ax, ds:[si][bx].ETE_handle	; move handle => AX
	tst	ax				; a valid handle ??
	jz	noHandle

	; See if valid handle is within first->last range
	;
	call	BufferVerifyUsedBuffer		; is this buffer in use ?
	cmp	bx, dx				; compare current with first
	ERROR_B		DP_VERIFY_INVALID_EVENT_TABLE
	cmp	bx, bp				; compare current with last
	jbe	checkLoop			; if less or equal, OK
	ERROR		DP_VERIFY_INVALID_EVENT_TABLE

	; See if non-handle is not in first->last range
	;
noHandle:
	cmp	bx, dx				; compare current with first
	jb	checkLoop			; if less, OK
	cmp	bx, bp				; compare current with last
	ja	checkLoop			; if larger, OK
	ERROR		DP_VERIFY_INVALID_EVENT_TABLE
done:
	.leave
	ret
DayPlanVerifyEventTable	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
		DayPlanResetUIIfDetailsNotUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Same as DP_RESET_UI, except that we skip the reset if
		Details dialog is up on screen.

CALLED BY:	MSG_DP_RESET_UI_IF_DETAILS_NOT_UP
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Where is this used? Mainly in booking (and perhaps
		calendar API) where an event could be added by another
		app (or message).

		If we blindly reset-ui, and details dialog is up, then
		the details dialog loses the connection with the
		DayEventClass object. (i.e. DPI_selectEvent == 0)

		On the other hand, if we don't reset-ui, and the user
		is in day view right now, then the added event would
		not show up on screen (yet).

		When Details dialog closes, it would do a reset-ui
		(DPSanityCheck.)

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kho     	3/24/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if	HANDLE_MAILBOX_MSG
DayPlanResetUIIfDetailsNotUp	method dynamic DayPlanClass, 
					MSG_DP_RESET_UI_IF_DETAILS_NOT_UP
		.enter
	;
	; Check if the EventOptions dialog is still up on screen.
	;
		push	si
		mov	bx, handle EventOptionsTopInteraction
		mov	si, offset EventOptionsTopInteraction
		mov	ax, MSG_VIS_GET_ATTRS
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; cl <- VisAttrs, ax,
							;  ch, dx, bp destroyed
		pop	si
	;
	; Is dialog opened? (Check VA_REALIZED)
	;
		test	cl, mask VA_REALIZED
EC <		WARNING_NZ CALENDAR_DETAILS_DLG_UP_SO_RESET_UI_SKIPPED	>
		jnz	quit
	;
	; OK, reset UI.
	;
		mov	ax, MSG_DP_RESPONDER_RESET_UI
		call	ObjCallInstanceNoLock		; nothing destroyed
quit:
		.leave
		Destroy	ax, cx, dx, bp
		ret
DayPlanResetUIIfDetailsNotUp	endm
endif	; HANDLE_MAILBOX_MSG


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanResetUI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the state of the DayPlan object

CALLED BY:	GLOBAL (MSG_DP_RESET_UI)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 8/92	Initial version
	sean	12/5/95		Calc one line height change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanResetUI	method dynamic	DayPlanClass, MSG_DP_RESET_UI

	; Delete all of the current events, and then load new ones
	;
	or	ds:[di].DPI_flags, DP_RELOAD
	mov	ax, MSG_DP_DELETE_RANGE
	mov	cl, BufferUpdateFlags <0, 0, 1>	; delete the events
	call	ObjCallInstanceNoLock		; send the method now
	FALL_THRU	DayPlanSetRange
DayPlanResetUI	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSetRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the display range of the dayplan

CALLED BY:	GLOBAL (MSG_DP_SET_RANGE)

PASS:		ES	= DGroup
		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/17/89		Initial version
	Don	9/25/89		Modified to pass a structure
	sean	3/19/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSetRange	method	DayPlanClass, MSG_DP_SET_RANGE

if	_TODO					
	; This case should only happen if we're restoring from
	; state & the To-do list was showing.  In this case
	; we want to change the DayPlanObject so it shows
	; the To-do list.
	;
	cmp	es:[viewInfo], VT_TODO
	jne	notToDoList
	mov	ax, MSG_DP_TODO_VIEW
	call	ObjCallInstanceNoLock
LONG	jmp	finish	
notToDoList:
endif

	; Let's get the current selection from the Year object
	;
	CheckHack <YRT_CURRENT eq 0>
	clr	cx				; YRT_CURRENT => CX
	mov	ax, MSG_YEAR_GET_SELECTION
	sub	sp, size RangeStruct
	mov	dx, ss
	mov	bp, sp				; empty RangeStruct => SS:BP
	push	di, si
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
						; fill the passed structure
	call	MessageToYearObject		; ...& return range length
	pop	di, si

	; Let's see if we need to do any work
	;
	test	ds:[di].DPI_flags, DP_RELOAD	; force a reload ??
	jne	newRange			; yes - jump
	mov	ax, {word} ds:[di].DPI_startDay	
	cmp	ax, {word} ss:[bp].RS_startDay	; compare start month/day's
	jne	newRange
	mov	ax, {word} ds:[di].DPI_endDay	
	cmp	ax, {word} ss:[bp].RS_endDay	; compare end month/day's
	jne	newRange
	mov	ax, ds:[di].DPI_startYear	
	cmp	ax, ss:[bp].RS_startYear	; compare start years
	jne	newRange
	mov	ax, ds:[di].DPI_endYear	
	cmp	ax, ss:[bp].RS_endYear		; compare end years
	jne	newRange
	jmp	exit				; we're done

	; Delete the old events if necessary...
	;
newRange:
	xchg	ds:[di].DPI_rangeLength, cx	; exchange old/new range length
	test	ds:[di].DPI_flags, DP_DIRTY	; is the DayPlan dirty??
	jnz	delete				; jump to delete
	test	ds:[di].DPI_flags, DP_TEMPLATE
	jz	new				; if not template, don't worry
	cmp	cx, ds:[di].DPI_rangeLength	; compare old/new lengths
	je	new				; if equal, don't worry...
	cmp	cx, 1				; if old equalled one...
	jne	new				; we must delete!
delete:
	mov	cl, BufferUpdateFlags <1, 1, 1>	; write-back & delete
	mov	ax, MSG_DP_DELETE_RANGE
	call	ObjCallInstanceNoLock		; delete the range

	; Notify the print setup of the new date
new:
	test	es:[viewInfo], mask VI_PEN_MODE
	jz	afterInk
	mov	ax, MSG_DP_STORE_INK
	call	ObjCallInstanceNoLock		; store an dirty ink
	mov	ax, MSG_DP_CLEAN_INK
	call	ObjCallInstanceNoLock		; delete any displayed ink

	; Now set up our own structure
afterInk:
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
	test	ds:[di].DPI_flags, DP_FILE_VALID
	pushf					; save results of the test
	test	ds:[di].DPI_flags, (DP_TEMPLATE or DP_RELOAD)
	jz	finishInit
	or	ds:[di].DPI_flags, DP_DEL_ON_LOAD
finishInit:
	or	ds:[di].DPI_flags, DP_LOADING

	; Store the new range of events
	;
	mov	bx, bp				; RangeStruct => SS:BX
	mov	cx, {word} ss:[bx].RS_startDay
	mov	{word} ds:[di].DPI_startDay, cx	; store start M/D
	mov	cx, ss:[bx].RS_startYear
	mov	ds:[di].DPI_startYear, cx	; store start year
	mov	cx, word ptr ss:[bx].RS_endDay
	mov	{word} ds:[di].DPI_endDay, cx	; store end M/D
	mov	cx, ss:[bx].RS_endYear
	mov	ds:[di].DPI_endYear, cx		; store end year

	; Now call to set up the title & events
	;
	GetResourceHandleNS	DayRangeDisplay, cx
	mov	dx, offset DayRangeDisplay	; TextObject OD => CX:DX

	; For Responder, we don't change the title upon changing views
	; because this is taken care of in MGIChangeView & 
	; TodoGenInteractionDismiss.  Fixes #52944 & 52945.
	;
	mov	ax, MSG_DP_SET_TITLE
	call	ObjCallInstanceNoLock		; set the window moniker
noTitleChange::
	mov	bp, bx				; RangeStruct => SS:BP
	popf					; restore document test results
	jz	done				; if none, we're done

	; Now add the events, after marking ourselves busy
	;
	mov	ax, MSG_GEN_APPLICATION_MARK_BUSY
	call	DayPlanCallApplication
	call	DayPlanLoadEvents		; add events, templates, headers

	; Finally call for screen update
	;
	and	ds:[di].DPI_flags, not (DP_LOADING or \
					DP_RELOAD or \
					DP_DEL_ON_LOAD)
	test	ds:[di].DPI_flags, DP_NEEDS_REDRAW
	jz	noUpdate			; not set, so don't redraw
	and	es:[systemStatus], not SF_DOC_TOO_BIG_ERROR
	mov	cx, size EventTableHeader	; offset to start update
	clr	dl				; no ScreenUpdateFlags
	mov	ax, MSG_DP_SCREEN_UPDATE	; screen update method
	call	ObjCallInstanceNoLock		; do all of the work
noUpdate:
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	call	DayPlanCallApplication		; now we're not busy
done:
	call	UndoNotifyClear			; clear the undo action
exit:
	add	sp, size RangeStruct		; clean up the stack
finish::
	ret
DayPlanSetRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanLoadEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load all possible events

CALLED BY:	DayPlanSetRange(), DayPlanPrintEngine()

PASS:		ES	= DGroup
		*DS:SI	= DayPlanClass instance data
		SS:BP	= RangeStruct

RETURN:		DS:DI	= DayPlanInstance

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	5/ 2/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanLoadEvents	proc	far
	class	DayPlanClass
	.enter

	; Add events, and templates & headers as appropriate
	;
	call	DayPlanAddRange	
	test	ds:[di].DPI_flags, DP_TEMPLATE
	jz	checkHeaders

	; If we're showing events in narrow mode, then we don't
	; show template events.  (Responder Only)
	;
	call	DayPlanAddTemplate		; add the template
checkHeaders:
	test	{word} ds:[di].DPI_flags, ((DP_HEADERS) or \
					  ((mask DPPF_FORCE_HEADERS) shl 8))
	jz	done				; jump if not set
	call	DayPlanAddHeaders		; else add the header events
done:
	.leave
	ret
DayPlanLoadEvents	endp


if	_TODO	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DPTodoView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called by UI when view menu is changed to show the 
		To Do List

CALLED BY:	MSG_DP_TODO_VIEW

PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax,dx	

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Set "To Do" mode bit of DayPlanObject
		Set Date Arrows not usable
		Set Title
		Delete events in event table
		Load To Do List events

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/ 3/95   	Initial version
	sean	1/17/96		Change to mark DayPlan loading,
				then update screen

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPTodoView	method dynamic DayPlanClass, 
					MSG_DP_TODO_VIEW
	uses	cx
	.enter

	; Ignore input while loading To-do items.
	;
	call	CalendarIgnoreInput
	
	; Set DayPlanObject flags for upcoming loading of
	; To-do list events.
	;
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	or	ds:[di].DPI_prefFlags, PF_TODO	; set to do mode bit
	or	ds:[di].DPI_flags, DP_DEL_ON_LOAD or\
				   DP_NEEDS_REDRAW or\
				   DP_RELOAD or\
				   DP_LOADING

	; Set the the Date Arrows of Day Plan View not usable, and
	; make sure We can't delete a DayPlan event while in "To Do"
	; mode
	;
	push	di, si
        mov     ax, MSG_GEN_SET_NOT_USABLE		
	mov	dl, VUM_NOW
	GetResourceHandleNS	EventDateArrows, bx
	mov	si, offset	EventDateArrows
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	pop	di, si
	; See if the file is valid.  It can be invalid if
	; the user presses To-do immediately upon startup.
	;
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	test	ds:[di].DPI_flags, DP_FILE_VALID	
	jz	exit

	; load to do list events
	;
	call	LoadToDoEvents

	; Finally call for screen update
	;
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	and	ds:[di].DPI_flags, not (DP_LOADING or \
					DP_RELOAD or \
					DP_DEL_ON_LOAD)
	mov	cx, size EventTableHeader	; offset to start update
	clr	dl				; no ScreenUpdateFlags
	mov	ax, MSG_DP_SCREEN_UPDATE	; screen update method
	call	ObjCallInstanceNoLock		; do all of the work

	mov	ax, MSG_DP_SELECT_FIRST
	call	ObjCallInstanceNoLock		; select first item

	; Set some UI related to the Event view not enabled
	; since we don't want to alter the regular events while
	; showing the To Do list
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	GetResourceHandleNS	EditDelete, bx
	mov	si, offset	EditDelete
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	mov	dl, VUM_NOW
	call	ObjMessage

	mov	si, offset	EditAlarm
	mov	di, mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage
	; finished loading and changing
	;
exit:
	call	CalendarAcceptInput

	.leave
	ret
DPTodoView	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DPEventView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the DayPlanObject we are in event view 
		(vs. To Do List view) so this object can do 
		some stuff to show itself correctly.	

CALLED BY:	MSG_DP_EVENT_VIEW

PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax,bx,dx,si,di	

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Reset "To Do" mode bit
		Set Date Arrows usable
		Set Title
		Delete events in event table
		Load events with DayPlanSetRange		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/ 3/95   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPEventView	method dynamic DayPlanClass, 
					MSG_DP_EVENT_VIEW
	.enter

	; Don't accept input while changing views.
	;
	call	CalendarIgnoreInput

	; check if we're already in "Event View".  If so do nothing
	;
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	test	ds:[di].DPI_prefFlags, PF_TODO
	jz	done				
	and 	ds:[di].DPI_prefFlags, not PF_TODO	; clear to do mode bit

	; show the correct events, and put the correct title
	; on the top of the CalendarRight
	;
	or	ds:[di].DPI_flags, DP_RELOAD or\
				   DP_NEEDS_REDRAW
	mov	ax, MSG_DP_SET_RANGE
	call	ObjCallInstanceNoLock

	; make the date arrows on the top of the 
	; CalendarRight visible
	;
        mov     ax, MSG_GEN_SET_USABLE		
	mov	dl, VUM_NOW
	GetResourceHandleNS	EventDateArrows, bx
	mov	si, offset	EventDateArrows	; bx:si = EventDateArrows
	mov	di, mask MF_FIXUP_DS
	call	ObjMessage

	; Make sure we don't try to alter the To Do list while
	; we're in "Event" mode
	; 
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	GetResourceHandleNS	EditTodoDelete, bx
	mov	si, offset	EditTodoDelete
	mov	dl, VUM_NOW
	clr	di
	call	ObjMessage

	mov	si, offset	MarkAsSubGroup
	clr	di
	call	ObjMessage
done:
	; finished loading and changing
	;
	call	CalendarAcceptInput

	.leave
	ret
DPEventView	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadToDoEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load "To Do" list events into DayPlanObjects event table

CALLED BY:	DPTodoView

PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ax	= create virgin sentinel

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,di,bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		get map block
		get to do list map block
		from map structs get item #'s of to do events
		for each event
		  MSG_DP_LOAD_EVENT	
		if no to do events, create a virgin To Do event	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/ 6/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadToDoEvents	proc	near
	.enter

	push	si				; save handle to DayPlan

	; We need to make sure the "New" trigger is enabled
	; if we're loading To-do events.
	;
	mov	ax, MSG_GEN_SET_ENABLED
	call	ChangeToDoNewTrigger

	; get database map block
	;
	call	GP_DBLockMap			; *es:di = map block

	; get to do list map block from 
	; database map block
	;
        mov     si, es:[di]                     ; dereference the Map handle
        mov     ax, es:[si].YMH_toDoListGr   	
        mov     di, es:[si].YMH_toDoListIt     	; ax:di = Group:Item To Do map 
        call    DBUnlock                        ; unlock it	

	; get to do list map header, get events, load `em
	;
        call    GP_DBLockDerefSI                ; lock the map item
        mov     bx, es:[si].EMH_numEvents	; cx = num to do events
	cmp	bx, 0				; if no events then 
	je	createVirgin			; create a virgin event

	; Load events 
	;
	add	si, size EventMapHeader	    	; es:si = first map struct
	mov	bp, si				; es:bp = first map
	mov	cx, ax				; Group # => cx
	mov	ax, MSG_DP_LOAD_EVENT		
	pop	si				; si = DayPlan
getEventLoop:
	mov	dx, es:[bp].EMS_event		; item # => dx
	call	ObjCallInstanceNoLock		
	dec	bx				
	cmp	bx, 0
	je	done				; any more events ?
	add	bp, size EventMapStruct
	jmp	getEventLoop

	; No events, so we create an empty one
	;
createVirgin:					; if no events, create one
	mov	ax, MSG_DP_NEW_TODO_EVENT		; initially
	pop	si
	call	ObjCallInstanceNoLock
	call	UndoNotifyClear			; no Undo for first To Do event

done:
       	call    DBUnlock                        ; unlock the ToDoListMap
	
	.leave
	ret
LoadToDoEvents	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanGetRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain the range of days currently displayed

CALLED BY:	GLOBAL (MSG_DP_GET_RANGE)

PASS:		DS:DI	= DayPlanClass specific instance data

RETURN:		AX	= Start day/month
		CX	= Start year
		DX	= End day/month
		BP	= End year

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/29/89	Initial version
	Don	3/18/90		Simplified use

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanGetRange	method	dynamic	DayPlanClass,	MSG_DP_GET_RANGE
	.enter

	; Simply stuff the data in
	;
	mov	ax, {word} ds:[di].DPI_startDay
	mov	cx, ds:[di].DPI_startYear
	mov	dx, {word} ds:[di].DPI_endDay
	mov	bp, ds:[di].DPI_endYear

	.leave
	ret
DayPlanGetRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSetTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Creates the moniker for the DayPlan window

CALLED BY:	DayPlanSetRange (MSG_DP_SET_TITLE)

PASS: 		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
		CX:DX	= OD of the TextObject to stuff
		ES	= Segment of DayPlan class

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Call to create the title string
		Set the text display object

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/17/89		Initial version
	Don	9/25/89		Modified to allow a displayed range
	sean	3/19/95		To Do list changes
	sean	8/1/95		Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSetTitle	method	DayPlanClass, MSG_DP_SET_TITLE
	uses	es
	.enter

	sub	sp, DATE_BUFFER_SIZE		; allocate room on the stack
	mov	bx, sp				; SS:BX points to the buffer
	push	cx, dx				; save the OD
	mov	bp, ds:[di].DPI_startYear	; get the start year
	mov	dx, {word} ds:[di].DPI_startDay	; get the month & day
	cmp	ds:[di].DPI_rangeLength, 1	; get # of days in the range 
	jg	range

	; Range is one day only
	;
	mov	cx, DTF_LONG_CONDENSED or USES_DAY_OF_WEEK
	pop	di, si				; OD => DI:SI
	CallMod	DateToTextObject		; create & stuff title
	jmp	done				; we're done

	; Actual range of days. Either draw:
	;	MMM DD - MMM DD, YYYY
	;		- or -
	;	MMM DD, YYYY - MMM DD, YYYY
range:
	segmov	es, ss, ax
	push	bx				; save beginning of the buffer
	push	si				; save DayPlan handle
	cmp	bp, ds:[di].DPI_endYear
	je	shortRange			; same year - do some work
longRange:
	mov	di, bx				; ES:DI => string buffer
	mov	cx, DTF_LONG_NO_WEEKDAY_CONDENSED
	CallMod	CreateDateString		; create first half of title
rangeCommon:
	mov	si, offset hyphen
	CallMod	WriteLocalizedString
	pop	si				; restore DayPlan handle
	mov	bp, ds:[si]			; dereference the handle again
	add	bp, ds:[bp].DayPlan_offset	; access the instance data
	mov	dx, {word} ds:[bp].DPI_endDay	; get the month & day
	mov	bp, ds:[bp].DPI_endYear		; get the start year
	mov	cx, DTF_LONG_NO_WEEKDAY_CONDENSED
	CallMod	CreateDateString

	; Now simply set the text
	;
	mov	dx, es
	pop	bp				; DX:BP points to the string
	clr	cx				; text is NULL terminated
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	pop	bx, si				; TextObject OD => BX:SI
	call	ObjMessage_dayplan_call		; set the text
done:
	add	sp, DATE_BUFFER_SIZE	; clean up the stack
finish::
	.leave
	ret

	; OK - have some real fun. We cannot just arbitrarily construct
	; our own date format - we need to extract the date format set
	; by the user and removed the year. Our algorithm is fairly
	; simple - we only look for the two year tokens at the end of
	; the string, and if we find either we back up until we find
	; a delimiter character and call that our format string.
	; Otherwise, we give up.
shortRange:
	mov	di, bx				; ES:DI => string buffer
	mov	si, DTF_LONG_NO_WEEKDAY_CONDENSED
	call	LocalGetDateTimeFormat		; format string => ES:DI
	call	LocalStringSize			; # of chars => CX
	sub	cx, 3				; length of token + delimiter
	add	di, cx
	cmp	{word} es:[di], TOKEN_LONG_YEAR
	je	foundYear
	cmp	{word} es:[di], TOKEN_SHORT_YEAR
	je	longRange		

	; OK! We found the year at the end. Now just back up until
	; we find an *ending* token delimiter.
foundYear:
	dec	di				; skip starting year delimiter
	dec	cx				; keep count current
findDelimiter:
	dec	di				; skip starting year delimiter
	dec	cx				; keep count current
	jcxz	longRange
	cmp	{byte} es:[di], TOKEN_DELIMITER
	jne	findDelimiter			; keep looking

	; OK! We found the string. Now just format our string. But
	; first we need to copy the format string into another buffer.
	;
	push	ds, si		
	segmov	ds, ss, si
	sub	sp, DATE_BUFFER_SIZE
	mov	di, sp				; new buffer -> ES:DI
	mov	si, bx				; format string => DS:SI
	inc	cx				; include current character
	rep	movsb				; copy
	clr	al				; ...and terminate
	stosb
	mov	si, sp				; format string => DS:SI
	mov	di, bx				; destinate buffer => ES:DI
	mov	bl, dh				; month => BL
	mov	bh, dl				; day => BH
	call	LocalCustomFormatDateTime
	add	di, cx				; ES:DI => end of string
	add	sp, DATE_BUFFER_SIZE
	pop	ds, si
	jmp	rangeCommon
DayPlanSetTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAddRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add events to the EventTable falling in the passed range

CALLED BY:	DayPlanUpdate

PASS:		ES	= DGroup
		DS:*SI	= DayPlanClass instance data
		SS:BP	= RangeStruct

RETURN:		DS:DI	= DayPlanClass specific instance data
		DX	= Offset to next date with events

DESTROYED:	AX, BX, CX

PSEUDO CODE/STRATEGY:
		For each day in the range
			Call database to load that day's event

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/26/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAddRange	proc	far
	class	DayPlanClass			; friend to this class
	uses	es
	.enter

	; Set up the loop
	;
	push	si				; save the DayPlan handle
	mov	bx, bp				; RangeStruct to BX
	sub	sp, size EventRangeStruct	; room on stack for the struct
	mov	bp, sp				; SS:BP points to the ERS
	mov	cx, {word} ss:[bx].RS_startDay	; the start month & day
	mov	dx, ss:[bx].RS_startYear	; and the start year

	; Stuff the EventRangeStruct
	;
	mov	ax, ds:[LMBH_handle]
	mov	ss:[bp].ERS_object.handle, ax
	mov	ss:[bp].ERS_object.chunk, si
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; acces the instance data
	mov	di, ds:[di].DPI_eventTable	; go to the event table
	mov	di, ds:[di]			; dereference the handle
	jmp	midLoop

	; Now loop on each year
addLoop:
	inc	dx				; go to the next year
	mov	cx, (1 shl 8) or 1		; starting month & day
midLoop:
	mov	ss:[bp].ERS_nextOffset, YearMapSize
	mov	ss:[bp].ERS_endYear, dx		; must loop year by year
	mov	ss:[bp].ERS_startYear, dx	
	mov	{word} ss:[bp].ERS_startDay, cx	; get the starting month & day
	mov	cx, {word} ss:[bx].RS_endDay
	cmp	dx, ss:[bx].RS_endYear		; if this year not end year
	je	doCall
	mov	cx, (12 shl 8) or 31		; ...then last day is Dec 31
doCall:
	mov	{word} ss:[bp].ERS_endDay, cx
	push	bx				; save the RangeStruct
	mov	ss:[bp].ERS_message, MSG_DP_LOAD_EVENT
	CallMod	GetRangeOfEvents		; get the range of events
	jc	stopLoad			; if aborted, load no more
	mov	ss:[bp].ERS_message, MSG_DP_LOAD_REPEAT
	CallMod	GetRangeOfRepeats		; get the repeat events also
stopLoad:
	pop	bx				; RangeStruct => SS:BX
	jc	done				; if aborted, load no more
	cmp	dx, ss:[bx].RS_endYear
	jl	addLoop

	; We're done
done:
	mov	dx, ss:[bp].ERS_nextOffset	; next offset => DX
	add	sp, size EventRangeStruct	; fixup the stack
	mov	bp, bx				; restore RangeStruct
	pop	si				; DayPlan handle => SI
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; specific data => DS:DI

	.leave
	ret
DayPlanAddRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDeleteRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all the events currently in the DayPlan

CALLED BY:	DayPlanUpdate, DayPlanFileClose

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data
		CL	= BufferUpdateFlags

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Resize the EventTable
		Update all the events

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		EXPECT the LMemBlock to move...

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/26/89		Initial version
	Don	12/4/89		Major revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanDeleteRange	method	DayPlanClass,	MSG_DP_DELETE_RANGE
	uses	ax, cx, di, bp
	.enter

	; Access my instance data
	;
	push	cx				; save the BufferUpdate flags
	clr	bp				; no new selected event
	mov	ax, MSG_DP_SET_SELECT
	call	ObjCallInstanceNoLock		; reset the triggers
	mov	di, ds:[si]			; acess instance data
	add	di, ds:[di].DayPlan_offset	; access my instance data
	and	ds:[di].DPI_flags, not DP_DIRTY
	or	ds:[di].DPI_flags, DP_NEEDS_REDRAW
	mov	ds:[di].DPI_docHeight, 0	; reset the document height

	; Resize the EventTable & reset the data
	;
	mov	ax, ds:[di].DPI_eventTable	; event table handle => AX
	mov	cx, size EventTableHeader	; re-size to the header size
	call	LMemReAlloc			; re-allocate the table
	mov	di, ax				; table handle => DI
	mov	di, ds:[di]			; dereference the table handle
	mov	ds:[di].ETH_last, cx
	mov	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP
	mov	ds:[di].ETH_screenLast, OFF_SCREEN_BOTTOM

	; Update & Free all of the DayEvent buffers
	;
	pop	cx				; restore the BufferUpdateFlags
EC <	test	cl, BUF_DELETE			; this flag must be set >
EC <	ERROR_Z	DP_DELETE_RANGE_DELETE_FLAG_NOT_SET			>
	and	cl, not BUF_NOTIFY_DAYPLAN	; clear unnecessary flag
	call	BufferAllWriteAndFree		; write-back all buffers

	.leave
	ret
DayPlanDeleteRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAddTemplate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add template events to the EventTable for a specific day

CALLED BY:	DayPlanLoadEvents

PASS:		DS:*SI	= DayPlan instance data
		ES	= DGroup

RETURN:		DS:DI	= DayPlan instance data

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		Get first template time
		Go to first entry in the EventTable
		Loop until done {
			If (TemplateTime > EventTime)
				Go to next EventTableEntry
			Else (TemplateTime = EventTime)
				Go to next ETE & TemplateTime
			Else
				Add the TemplateTime
				Go to next TemplateTime
		}

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/11/89	Initial version
	sean	1/3/96		Responder change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAddTemplate	proc	near
	class	DayPlanClass
	uses	si
	.enter

	; Some set-up work
	;
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access instance data

	; If we're showing To-do list, we don't want to
	; add template events
	;

	cmp	ds:[si].DPI_rangeLength, 1	; one day only ?
	jne	done				; if not, we're done
	mov	bp, ds:[si].DPI_startYear	; year => BP
	mov	dx, {word} ds:[si].DPI_startDay	; month/day => DX
	mov	cx, {word} ds:[si].DPI_beginMinute
EC <	tst	ds:[si].DPI_interval		; check for 0 interval	>
EC <	ERROR_Z	DP_ADD_TEMPLATE_BAD_INTERVAL				>
EC <	cmp	ds:[si].DPI_interval, 60	; check for less hour	>
EC <	ERROR_G	DP_ADD_TEMPLATE_BAD_INTERVAL				>
	mov	ax, ds:[si].DPI_eventTable	; access the eventTable
	mov	di, ax				; eventTable => DI
	mov	di, ds:[di]			; dereference the handle
	mov	bx, size EventTableHeader	; initial offset

	; Let's start the loop
	;
templateLoop:
	cmp	bx, ds:[di].ETH_last		; end of the table ??
	je	insert				; then just insert
	cmp	{word} ds:[di][bx].ETE_day, dx	; compare month/day with current
	jne	resetDMY			; if not, reset the value
	cmp	ds:[di][bx].ETE_year, bp	; compare year with current
	je	checkMinute
resetDMY:
	pop	si				; DayPlan chunk => SI
	push	si				; Re-save the chunk handle
	call	TemplateResetDMY		; reset the DMY
checkMinute:
	cmp	cx, {word} ds:[di][bx].ETE_minute	; compare the times
	jg	nextETE				; case 1: Go to the next ETE
	je	nextTemplate			; case 2: Go to both next

	; Else insert some bytes (case 3)
insert:
	push	cx				; save the time
	mov	cx, size EventTableEntry	; # bytes to insert
	call	LMemInsertAt			; insert them bytes
	pop	cx				; restore the time
	pop	si				; restore the DaPlan chunk
	push	si				; re-save it
	mov	di, ax				; EventTable chunk => DI
	call	TemplateCreateEvent		; create the EventTableEntry

	; Calculate the next template time
nextTemplate:
	add	cl, ds:[si].DPI_interval	; go to the next time
	cmp	cl, 60				; less than 60 minutes ?
	jl	templateCompare			; if so, compare
	inc	ch				; else increment the hour
	sub	cl, 60				; and correct the minutes
templateCompare:
	cmp	cx, {word} ds:[si].DPI_endMinute ; compare start, end time
	jg	done				; if greater, done
nextETE:
	add	bx, size EventTableEntry	; go to the next ETE
	jmp	templateLoop			; and loop
done:
	mov	di, si				; DS:DI = DayPlan specific data
exit::
	.leave
	ret
DayPlanAddTemplate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateCreateEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a template EventTableEntry

CALLED BY:	DayPlanAddTemplate
	
PASS:		DS:*SI	= DayPlanClass instance data
		DS:*DI	= EventTable
		BX	= Offset to the EventTableEntry
		BP	= Year
		DX	= Month/Day
		CX	= Time
		ES	= DGroup

RETURN:		DS:SI	= DayPlanClass specific instance data
		DS:DI	= EventTable

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Update the EventTableHeader buffer
		Update the document size & set redraw bit
		Fill in the EventTableEntry

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/23/90		Initial version
	sean	1/3/96		Responder change to re-add template events

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TemplateCreateEvent	proc	near
	class	DayPlanClass
	uses	ax
	.enter

EC <	call	ECCheckObject			; valid object ??	>
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; re-dereference it
	mov	di, ds:[di]			; derefernece the EventTable
	add	ds:[di].ETH_last, size EventTableEntry
	or	ds:[si].DPI_flags, DP_NEEDS_REDRAW
	mov	ds:[di][bx].ETE_year, bp	; store the year
	mov	{word} ds:[di][bx].ETE_day, dx	; store the month and day
	mov	{word} ds:[di][bx].ETE_minute, cx ; store the minute
	mov	ax, es:[oneLineTextHeight]	; height of one-line obj to AX
	add	ds:[si].DPI_docHeight, ax	; track the document height
	mov	ds:[di][bx].ETE_size, ax	; store the size
	mov	ds:[di][bx].ETE_group, 0	; no group #
	mov	ds:[di][bx].ETE_item, 0		; no item #
	mov	ds:[di][bx].ETE_handle, 0	; clear the handle field

	; For Responder, we want to re-add template events if they 
	; are deleted.  To do this, we need to update ETH_screenLast
	; if we're recreating a template event.  We should only update
	; ETH_screenLast if we're NOT loading (i.e. re-adding the 
	; template event.   (sean 1/3/96)
	;

	.leave
	ret
TemplateCreateEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TemplateResetDMY
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the Day/Month/Year of an EventTableEntry (& buffer)

CALLED BY:	DayPlanAddTemplate
	
PASS:		DS:*SI	= DayPlanClass instance data
		DS:DI	= EventTable
		BX	= Offset to the EventTableEntry
		BP	= Year
		DX	= Month

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TemplateResetDMY	proc	near
	class	DayPlanClass
	.enter

	; Reset the DMY values, and call the DayEvent if necessary
	;
	mov	ds:[di][bx].ETE_year, bp	; store the year
	mov	{word} ds:[di][bx].ETE_day, dx	; store the month & day
	tst	ds:[di][bx].ETE_handle		; a related DayEvent ??
	jz	done				; no, so done!
	
	; Else call the DayEvent with the new values
	;
	push	si				; save the DayPlan chunk
	mov	ax, MSG_DE_SET_DMY
	mov	si, ds:[di][bx].ETE_handle
EC <	call	ECCheckObject			; valid object ??	>
	call	ObjCallInstanceNoLock		; send the method
	pop	si				; restore the DayPlan chunk
done:
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access the instance data
	mov	ax, ds:[si].DPI_eventTable	; eventTable => AX
	mov	di, ax				; chunk  => DI
	mov	di, ds:[di]			; dereference the chunk	

	.leave
	ret
TemplateResetDMY	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAddHeaders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add headers to the EventTable for days not holding any events

CALLED BY:	DayPlanLoadEvents

PASS:		DS:*SI	= DayPlan instance data
		ES	= DGroup
		Responder only:
		SS:BP	= RangeStruct

RETURN:		DS:DI	= DayPlan instance data

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		Current date = Start date
		Loop
			If (Current Date >= End Date)
				Done
			Else {
				If (Current Date == Current ETE)
					Current Date++;
				If (Current Date > Current ETE)
					Current ETE++;
				Else
					AddHeaders[Current Date, Current ETE)
			}
		Goto Loop
		
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAddHeaders	proc	near
	class	DayPlanClass
	.enter

	; Some set-up work
	;
	mov	cx, si				; DayPlan handle => CX
	mov	si, ds:[si]			; dereference handle
	add	si, ds:[si].DayPlan_offset	; access instance data


	test	ds:[si].DPI_printFlags, mask DPPF_FORCE_HEADERS
	jnz	doHeaders			; force template to be used
	cmp	ds:[si].DPI_rangeLength, 1	; one day only ?
	je	done				; if not, we're done
doHeaders:
	mov	di, ds:[si].DPI_eventTable	; table handle to BP
	mov	di, ds:[di]			; dereference the handle
	mov	bp, ds:[si].DPI_startYear	; CurDate - year
	mov	dx, {word} ds:[si].DPI_startDay	; CurDate - month/day
	mov	bx, size EventTableHeader	; initial offset

	; Check case 1
addLoop:
	cmp	bp, ds:[si].DPI_endYear		; compare the years
	jg	done				; if greater, done
	jl	caseTwo				; if less, check case two
	cmp	dx, {word} ds:[si].DPI_endDay	; compare month & day
	jg	done				; if greater than range, done!

	; Check case 2
caseTwo:
	cmp	bx, ds:[di].ETH_last		; at the end of the table ??
	jl	caseTwoCont			; if less, continue
	call	AddLastHeader			; add the last header
	jmp	addHeaders			; yes, add the headers
caseTwoCont:
	cmp	bp, ds:[di][bx].ETE_year	; compare the years
	jl	addHeaders			; if less, add headers
	jg	nextEntry			; if greater, continue looping
	cmp	dx, {word} ds:[di][bx].ETE_day	; compare the month/day's
	je	nextDay				; if equal, go to next day
	jg	nextEntry			; if greater, go to next 

	; Add the headers here
addHeaders:
	call	AddRangeOfHeaders

	; Calculate the next day
nextDay:
	push	bx				; save the offset
	mov	si, cx				; DayPlan handle => SI
	mov	cx, 1				; increment by one day
	call	CalcDateAltered			; change the date
	mov	cx, si				; restore DayPlan info..
	mov	si, ds:[si]
	add	si, ds:[si].DayPlan_offset
	pop	bx				; restore our offset
nextEntry:
	add	bx, size EventTableEntry	; go to the next ETE
	jmp	addLoop

	; Some clean-up work!
done:
	mov	di, si				; dereference handle to DI
	mov	si, cx				; handle to SI


	.leave
	ret
DayPlanAddHeaders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddLastHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add last header onto the EventTable

CALLED BY:	DayPlanAddHeaders

PASS:		DS:DI	= Event Table
		DS:SI	= DayPlan instance data
		CX	= DayPlan handle
		BX	= Offset to end of table

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddLastHeader	proc	near
	class	DayPlanClass
	.enter

	; Allocate the bytes
	;	
	or	ds:[si].DPI_flags, (DP_DIRTY or DP_NEEDS_REDRAW)
	mov	ax, ds:[si].DPI_eventTable	; table handle => AX
	mov	si, cx				; DayPlan handle => SI
	mov	cx, size EventTableEntry	; bytes to insert
	call	LMemInsertAt			; insert the bytes
	mov	di, ax				; table handle to DI
	mov	di, ds:[di]			; dereference the table handle
	add	ds:[di].ETH_last, cx		; update the header...
	mov	cx, si				; restore CX
	mov	si, ds:[si]			; dereference DayPlan handle
	add	si, ds:[si].DayPlan_offset	; access instance data

	; Initialize the EventTableEntry
	;
	mov	ax, ds:[si].DPI_endYear
	mov	ds:[di][bx].ETE_year, ax
	mov	ax, {word} ds:[si].DPI_endDay
	mov	{word} ds:[di][bx].ETE_day, ax

	clr	ax				; zero out AX
	mov	{word} ds:[di][bx].ETE_minute, ax
	mov	ds:[di][bx].ETE_group, ax
	mov	ds:[di][bx].ETE_item, 1		; denotes a header event
	mov	ds:[di][bx].ETE_repeatID, ax
	mov	ds:[di][bx].ETE_handle, ax
	mov	ax, es:[oneLineTextHeight]
	mov	ds:[di][bx].ETE_size, ax
	add	ds:[si].DPI_docHeight, ax	; update document height

	.leave
	ret
AddLastHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddRangeOfHeaders
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add headers over the specified range of days

CALLED BY:	DayPlanAddHeaders

PASS:		DS:DI	= Event Table
		DS:SI	= DayPlan instance data
		ES	= DGroup
		BP	= CurDate - year
		DX	= CuyDate - month/day
		CX	= DayPlan handle
		BX	= Offset to current EventTableEntry

RETURN:		BX	= Offset to same EventTableEntry
		BP	= Updated CurDate - year
		DX	= Updated CurDate - month/day

DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		Add the headers
		Reset SI & DI to allow for block movement

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddRangeOfHeaders	proc	near
	class	DayPlanClass
	.enter

	; Some set-up work
	;
	push	cx				; save the DayPlan handle
	or	ds:[si].DPI_flags, (DP_DIRTY or DP_NEEDS_REDRAW)
	mov	si, ds:[si].DPI_eventTable	; table handle => SI
	mov	di, ds:[si]			; dereference the handle
	clr	cx				; clear the height value
	jmp	midLoop

	; Loop, creating the EventTableEntries
	;
CreateLoop:
	push	cx				; save the height total
	mov	ax, si				; handle => AX; size => SI
	mov	cx, size EventTableEntry	; bytes to insert
	call	LMemInsertAt			; insert the bytes
	xchg	ax, si				; habndle => SI; size => AX
	mov	di, ds:[si]			; dereference the table handle
	add	ds:[di].ETH_last, cx		; update the header...
	pop	cx				; restore the height total

	; Initialize the EventTableEntry
	;
	mov	ds:[di][bx].ETE_year, bp
	mov	{word} ds:[di][bx].ETE_day, dx
	mov	{word} ds:[di][bx].ETE_minute, -2 ; must precede no time (-1)
	clr	ax				; zero out AX
	mov	ds:[di][bx].ETE_group, ax
	mov	ds:[di][bx].ETE_item, 1		; denotes a header event
	mov	ds:[di][bx].ETE_repeatID, ax
	mov	ds:[di][bx].ETE_handle, ax
	mov	ax, es:[oneLineTextHeight]
	mov	ds:[di][bx].ETE_size, ax
	add	cx, ax

	; Go to the next day
	;
	push	cx, bx				; save total height, offset
	mov	cx, 1				; increase by one day
	call	CalcDateAltered			; go to the next day
	pop	cx, bx				; restore height, offset
	add	bx, size EventTableEntry	; go to original ETE
midLoop:
	cmp	bp, ds:[di][bx].ETE_year	; compare with year
	jl	CreateLoop
EC <	ERROR_G	DP_ADD_HEADER_DATE_OUT_OF_ORDER				>
	cmp	dx, {word} ds:[di][bx].ETE_day
	jl	CreateLoop
EC <	ERROR_G	DP_ADD_HEADER_DATE_OUT_OF_ORDER				>

	; Now clean up
	;
	mov	ax, cx				; total height to AX
	pop	cx				; DayPlan handle to CX
	mov	si, cx				; handle => SI
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access instance data
	add	ds:[si].DPI_docHeight, ax	; update the document height

	.leave
	ret
AddRangeOfHeaders	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanUpdateAllEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force all events to be updated (ie write back to the DB file)

CALLED BY:	GLOBAL (MSG_DP_UPDATE_ALL_EVENTS)

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data

RETURN:		AX	= 0 if any changes
			= else non-zero

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanUpdateAllEvents	method	DayPlanClass,	MSG_DP_UPDATE_ALL_EVENTS
	uses	cx
	.enter

	mov	cl, BufferUpdateFlags <1, 0, 0>	; write-back only
	call	BufferAllWriteAndFree		; do it

	.leave
exitDP	label	far
	ret
DayPlanUpdateAllEvents	endp


if	_TODO
else

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gained the target exclusive, so update View menu

CALLED BY:	GLOBAL (MSG_META_GAINED_TARGET_EXCL)

PASS:		ES	= DGroup
		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanGainedTargetExcl	method dynamic	DayPlanClass,
					MSG_META_GAINED_TARGET_EXCL

		; Set the ViewType properly
		;
		mov	cx, VT_EVENTS
		call	UpdateViewType

		; Call superclass
		;
		mov	di, offset DayPlanClass
		GOTO	ObjCallSuperNoLock
DayPlanGainedTargetExcl	endm
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanNavigationQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to navigation request

CALLED BY:	GLOBAL (MSG_META_CONTENT_NAVIGATION_QUERY)

PASS:		*DS:SI	= DayPlanClass object
		CX:DX	= Originating object
		BP	= (ignored) NavigateFlags

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanNavigationQuery	method 	dynamic	DayPlanClass, 
					MSG_META_CONTENT_NAVIGATION_QUERY

		; Undo the current selection, if any, and then select
		; the first interactable event
		;
		clr	bp			; no new event
		mov	ax, MSG_DP_SET_SELECT
		call	ObjCallInstanceNoLock
		mov	ax, MSG_DP_SELECT_NEXT
		GOTO	ObjCallInstanceNoLock
DayPlanNavigationQuery	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSetSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the selected DayEvent

CALLED BY:	GLOBAL (MSG_DP_SET_SELECT)

PASS:		DS:DI	= DayPlanClass specific instance data
		ES	= DGroup
		BP	= New selected event handle

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/4/90		Initial version
	sean	3/19/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSetSelect	method	DayPlanClass,	MSG_DP_SET_SELECT
	uses	dx
	.enter

	; Unselect the old DayEvent (if necessary)
	;
	mov	si, ds:[di].DPI_selectEvent	; get current selection
	mov	ds:[di].DPI_selectEvent, bp	; store the new select event
	tst	si				; check current selection
	jz	setNew				; if none, nothing to unselect
	cmp	bp, si				; are they the same DayEvent ?
	je	reselect			; if so, reselect
	mov	ax, MSG_DE_DESELECT		; else, unselect the old event
	call	ObjCallInstanceNoLock

	; Select the new DayEvent (if necessary)
setNew:
	mov	ax, MSG_GEN_SET_NOT_ENABLED	; disable the trigger
	mov	si, bp				; DayEvent handle to SI
	call	UndoNotifyClear			; reset the undoAction
reselect:
	tst	si				; no new selection ??
	jz	done				; if so, disable triggers
	mov	ax, MSG_DE_SELECT		; else draw it appropriately
	call	ObjCallInstanceNoLock		; appropriate method => AX

	; Set the trigger's state!
done:
	GetResourceHandleNS	MenuBlock, bx
	mov	si, offset MenuBlock:EditDelete	; OD => BX:SI
	mov	dl, VUM_NOW			; update now, please
	clr	di				; preserve AX, DL
	call	ObjMessage	
	mov	si, offset MenuBlock:EditAlarm	; OD => BX:SI
	clr	di
	call	ObjMessage

	.leave
	ret
DayPlanSetSelect	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanGetSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Obtain the selected DayEvent handle

CALLED BY:	GLOBAL (MSG_DP_GET_SELECT)

PASS:		DS:DI	= DayPlanClass specific instance data

RETURN:		BP	= DayEvent handle or 0

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanGetSelect	method	dynamic DayPlanClass, MSG_DP_GET_SELECT
	.enter
	mov	bp, ds:[di].DPI_selectEvent	; get current selection

	.leave
	ret
DayPlanGetSelect	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSelectFirst
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the next event, if there is one.

CALLED BY:	GLOBAL (MSG_DP_SELECT_NEXT)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/13/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSelectFirst	method	dynamic	DayPlanClass, MSG_DP_SELECT_FIRST

		; See if an object is currently selected, or else
		; select the first.
		;
		tst	ds:[di].DPI_selectEvent
LONG		jnz	exitDP
		FALL_THRU	DayPlanSelectNext		
DayPlanSelectFirst	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSelectNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the next event, if there is one.

CALLED BY:	GLOBAL (MSG_DP_SELECT_NEXT)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
vKNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/13/92		Initial version
		sean	10/10/95	Responder navigation fix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSelectNext	method	DayPlanClass, MSG_DP_SELECT_NEXT

		; Find the next event that a user may interact with
		;
		mov	bp, ds:[di].DPI_selectEvent
		mov	di, ds:[di].DPI_eventTable
		tst	bp			; check for no selection
		jz	postSearch		; then don't search (CF = 0) 
		call	DayPlanSearchByBuffer	; buffer offset => BX
postSearch:
		mov	di, ds:[di]		; EventTable => DS:DI
		jc	haveEvent		; if found, jump. Else use 1st
		mov	bx, (size EventTableHeader) - (size EventTableEntry)
haveEvent:
		add	bx, size EventTableEntry
		cmp	bx, ds:[di].ETH_last
		mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
		jae	selectFailed

		; Force the selection, and call the event when we're done
		; Switched to select the text obj (MSG_DE_SELECT_TEXT
		; instead of MSG_DE_SELECT_TIME) , as that is what
		; the user most likely wants anyway - Don 1/19/99
		;
		mov	ax, MSG_DP_FORCE_SELECT
		mov	cx, bx			; offset to EventTableEntry=>CX
		mov	dx, size ForceSelectArgs
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].FSA_message, MSG_DE_SELECT_TEXT

selectCommon	label	far
		clr	ss:[bp].FSA_callBack
		call	ObjCallInstanceNoLock
		add	sp, size ForceSelectArgs	
		ret

		; We have no object to navigate to, so navigate out of view
selectFailed	label	far
		push	ax
		clr	bp			; remove the current selection
		mov	ax, MSG_DP_SET_SELECT
		call	ObjCallInstanceNoLock
		pop	ax
		clr	di
		GOTO	MessageToEventView
DayPlanSelectNext	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSelectPrevious
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Select the previous event, if there is one

CALLED BY:	GLOBAL (MSG_DP_SELECT_PREVIOUS)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/11/93		Initial version
		sean	10/10/95	Responder navigation fix

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSelectPrevious	method dynamic	DayPlanClass, MSG_DP_SELECT_PREVIOUS

		; Find the next event that a user may interact with
		;
		mov	bp, ds:[di].DPI_selectEvent
		mov	di, ds:[di].DPI_eventTable
		tst	bp			; check for no selection
		jz	postSearch		; then don't search (CF = 0) 
		call	DayPlanSearchByBuffer	; buffer offset => BX
postSearch:
		mov	di, ds:[di]		; EventTable => DS:DI
		jc	haveEvent		; if found, jump. Else use last
		mov	bx, ds:[di].ETH_last
haveEvent:
		sub	bx, size EventTableEntry
		cmp	bx, (size EventTableHeader) - (size EventTableEntry)
		mov	ax, MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
		je	selectFailed
		; Force the selection, and call the event when we're done
		;
		mov	ax, MSG_DP_FORCE_SELECT
		mov	cx, bx			; offset to EventTableEntry=>CX
		mov	dx, size ForceSelectArgs
		sub	sp, dx
		mov	bp, sp
		mov	ss:[bp].FSA_message, MSG_DE_SELECT_TEXT
		clr	ss:[bp].FSA_dataCX	
		clr	ss:[bp].FSA_dataDX	
		jmp	selectCommon
DayPlanSelectPrevious	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanForceSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the selection of an EventTableEntry, by either grabbing
		the current buffer, or forcing a scroll to occur.

CALLED BY:	GLOBAL

PASS:		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
		CX	= Offset into the EventTable
		DX	= Size ForceSelectArgs
		SS:BP	= ForceSelectArgs
				FSA_callBack must be zero when initally called

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Basically, if the event we must select if off the screen,
		we must force a scroll event to occur. Unfortuately, this
		comes from the UI, so things do not happen in lock step.
		To ensure no mistakes (especially needed when creating new
		events at the bottom of the screen), we hold up input events
		until we are completely through with this process (gets
		through the callback)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version
	Don	5/22/90		Made this into a force select
	sean	2/9/96		Got rid of HOLD_UP_INPUT & added
				recovery in non-EC for bad offset

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanForceSelect	method	DayPlanClass,	MSG_DP_FORCE_SELECT

	; hopefully we will be done selecting the event by the time we
	; return.  So, we clear this bit:
	;
RSP <	BitClr	ds:[di].DPI_extraFlags, DPEF_TRYING_TO_SELECT		>
		
	; Get the handle
	;
	push	bp				; save the select arguments
	mov	di, ds:[di].DPI_eventTable	; get event table handle
	mov	di, ds:[di]			; dereference the handle
	mov	bx, cx				; offset to BX

	; If we're trying to select an event which doesn't exist
	; crash in EC, but recover in non-EC.
	;
EC <	cmp	bx, ds:[di].ETH_last					>
EC <	ERROR_GE	DP_SELECT_IF_POSSIBLE_BAD_OFFSET		>
	tst	ds:[di][bx].ETE_handle		; valid handle ??
	jz	scrollWindow			; must scroll the window
	mov	bp, ds:[di][bx].ETE_handle	; handle => BP
	mov	ax, MSG_DP_SET_SELECT		; set the selection
	call	ObjCallInstanceNoLock
	mov	dx, bp				; DayEvent handle => DX
	pop	bp				; ForceSelectArgs => SS:BP
	tst	ss:[bp].FSA_callBack		; did we perform a callback ??
	jz	finish				; no, so finish the call

	; We don't use this for Responder
	;
	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT	; we can now resume user input
	call	DayPlanCallApplication		; send the method
finish:
	call	DayPlanForceSelectComplete	; send the desired method call
exit::
	ret

	; This is recovery code in case of a bad offset.
	;

	; Else calculate the position of the event, and scroll it into view
	;
scrollWindow:
	pop	bp				; ForceSelectArgs => SS:BP
	push	bp				; re-save the structure
	tst	ss:[bp].FSA_callBack		; have we looped before ??
	jnz	noMoreHoldUp			; yes, so don't hold up

	; For Responder, we ignore input before sending this
	; message, accepting input in DayPlanForceSelectComplete
	;
	mov	ax, MSG_GEN_APPLICATION_HOLD_UP_INPUT	; must hold up input to allow
	call	DayPlanCallApplication		; ...scroll to come through
noMoreHoldUp:
	clr	ax				; position counter
	mov	bp, size EventTableHeader	; ETE offset to start loop
	mov	cx, bx				; EventTableEntry offset => CX
	shr	cx, 1				; ETE's are 16 byte long...
	shr	cx, 1
	shr	cx, 1
	shr	cx, 1				; ...so count => CX
	jz	scrollNow			; if zero, done!
offsetLoop:
	add	ax, ds:[di][bp].ETE_size	; update the position count
	add	bp, size EventTableEntry	; go to the next ETE
	loop	offsetLoop			; loop until done

	; Now scroll appropriately
	;
scrollNow:
	cmp	ax, DP_MAX_COORD		; compare top with max offset
	jae	abort				; if larger, abort
	push	bx, si				; save offset, DayPlan chunk
	mov	dx, size MakeRectVisibleParams	; buffer size => DX
	sub	sp, dx				; allocate the buffer
	mov	bp, sp				; SS:BP is the buffer
	mov	ss:[bp].MRVP_bounds.RD_left.low,0
	mov	ss:[bp].MRVP_bounds.RD_top.low, ax
	mov	ss:[bp].MRVP_bounds.RD_right.low, 1 ; not scrolling left-right
	add	ax, ds:[di][bx].ETE_size	; bottom offset + 1 => AX
	dec	ax				; bottom offset => AX
	mov	ss:[bp].MRVP_bounds.RD_bottom.low, ax
	mov	ss:[bp].MRVP_xMargin, MRVM_50_PERCENT
	mov	ss:[bp].MRVP_yMargin, MRVM_50_PERCENT
	clr	di
	mov	ss:[bp].MRVP_bounds.RD_left.high, di
	mov	ss:[bp].MRVP_bounds.RD_top.high, di
	mov	ss:[bp].MRVP_bounds.RD_right.high, di
	mov	ss:[bp].MRVP_bounds.RD_bottom.high, di
	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access the instance data
	GetResourceHandleNS	EventView, bx
	mov	si, offset EventView
	mov	di, mask MF_STACK or mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	add	sp, size MakeRectVisibleParams	; clean up the stack
	pop	bx, si				; restore offset, DayPlan chunk

	; before force queueing another MSG_DP_FORCE_SELECT, set a flag to
	; tell the world that we are in the middle of selecting the day event
	; object.  Some people may MF_CALL this routine and expect to have
	; the right event selected by the time this routine returns.  While
	; we cannot guarantee that behavior, we can provide a way to check on
	; us whether we are done selecting the event object
	;
RSP <	mov	di, ds:[si]						>
RSP <	add	di, ds:[di].DayPlan_offset				>
RSP <	BitSet	ds:[di].DPI_extraFlags, DPEF_TRYING_TO_SELECT		>
		
	; Send a method back to ourself (through the queue) to select
	; to allow the scrolling to happen.
	;
	mov	ax, MSG_DP_FORCE_SELECT
	mov	cx, bx				; offset => CX
	mov	dx, size ForceSelectArgs
	pop	bp				; ForceSelectArgs => SS:BP
	inc	ss:[bp].FSA_callBack		; we must perform a callback
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	mov	di, mask MF_FORCE_QUEUE or mask MF_STACK
	call	ObjMessage			; send the method
done::
	ret

	; Attempts to add events that are physically beyond the ability
	; of the view (doe to the document length). Abort the scroll.
	;
abort:
	pop	bp				; clean up the stack
	mov	ax, MSG_GEN_APPLICATION_RESUME_INPUT	; we can now resume user input
	call	DayPlanCallApplication		; send the method
	jmp	done				; and do nothing

DayPlanForceSelect	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCallApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calls the GenApplication object (Calendar) with the given
		method.

CALLED BY:	DayPlanForceSelect
	
PASS:		DS	= DPResource
		ES	= DGroup
		AX	= Method to send

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanCallApplication	proc	near
	uses	bx, cx, dx, bp, si, di
	.enter

	GetResourceHandleNS	Calendar, bx
	mov	si, offset Calendar		; Application OD => BX:SI
	call	ObjMessage_dayplan_call		; send the method

	.leave
	ret
DayPlanCallApplication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanForceSelectComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Finish the force selection process

CALLED BY:	DayPlanForceSelect
	
PASS:		DS:*DX	= DayEventClass object
		SS:BP	= ForceSelectArgs

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanForceSelectComplete	proc	near
	.enter

	; Simply call the method
	;
	mov	si, dx				; DayEvent => DS:*SI
EC <	call	ECCheckObject			; valid object ??	>
	mov	ax, ss:[bp].FSA_message
	mov	cx, ss:[bp].FSA_dataCX
	mov	dx, ss:[bp].FSA_dataDX
	mov	bp, ss:[bp].FSA_dataBP
	call	ObjCallInstanceNoLock


	.leave
	ret
DayPlanForceSelectComplete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAlterRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Request a change in the currently displayed range

CALLED BY:	UI (MSG_DP_ALTER_RANGE)

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data
		DS:DI	= DayPlan specific instance data (by method call) 
		DX	= DC_FORWARD or DC_BACKWARD

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/11/89	Initial version
	Don	12/6/89		Can handle range of days

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAlterRange	method	DayPlanClass, MSG_DP_ALTER_RANGE

	; Get the current range length
	;
EC <	cmp	dx, DateChange			; too big ??		>
EC <	ERROR_AE	DP_ALTER_RANGE_INVALID_FLAG			>
	mov	cx, ds:[di].DPI_rangeLength	; get the range length
	cmp	dx, DC_FORWARD			; go forward
	je	common				; yes, so jump
	neg	cx				; else negate the length

	; Update the new range offset, tell DP to change
	;
common:
	add	ds:[di].DPI_newRangeOff, cx	; update range offset
	mov	bx, ds:[LMBH_handle]
	mov	ax, MSG_DP_ALTER_RANGE_NOW
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
	ret
DayPlanAlterRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAlterRangeNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Decrement/Increment the event date

CALLED BY:	DayPlanAlterRange

PASS: 		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/11/89	Initial version
	Don	11/2/89		Slight change
	Don	12/6/89		Handles true ranges of days

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAlterRangeNow	method	DayPlanClass,	MSG_DP_ALTER_RANGE_NOW
	.enter

	; Some set up work
	;
	mov	cx, ds:[di].DPI_newRangeOff	; get the zoom offset
	tst	cx
	je	quit
	mov	ds:[di].DPI_newRangeOff, 0	; clear the zoom offset
	sub	sp, size RangeStruct
	mov	bx, sp

	; Alter the starting MM/DD/YY
	;
	mov	bp, ds:[di].DPI_startYear
	mov	dx, {word} ds:[di].DPI_startDay
	call	CalcDateAltered
	jc	badYear
	mov	{word} ss:[bx].RS_startDay, dx
	mov	ss:[bx].RS_startYear, bp

	; Alter the ending MM/DD/YY
	;
	mov	bp, ds:[di].DPI_endYear
	mov	dx, {word} ds:[di].DPI_endDay
	call	CalcDateAltered
	jc	badYear
	mov	{word} ss:[bx].RS_endDay, dx
	mov	ss:[bx].RS_endYear, bp
	mov	bp, bx

	; Notify the year of the change
	;
	push	si				; save DayPlanObject handle
	mov	ax, MSG_YEAR_SET_SELECTION
	mov	dx, size RangeStruct
	mov	di, mask MF_STACK or mask MF_CALL
	call	MessageToYearObject
	pop	si				; restore DayPlanObject handle

	; Now get the new events
	;
	mov	ax, MSG_DP_SET_RANGE		; set the viewing range
	mov	bx, ds:[LMBH_handle]		; DayPlan OD => BX:SI
	mov	di, mask MF_FORCE_QUEUE or \
		    mask MF_CHECK_DUPLICATE or \
		    mask MF_REPLACE
	call	ObjMessage			; send message to myself
	jmp	done				; we're done

	; Display the bad year warning box
	;
badYear:
	call	GeodeGetProcessHandle		; process handle => BX
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	mov	bp, CAL_ERROR_BAD_YEAR
	call	ObjMessage_dayplan_call		; display the warning box

	; Clean up
done:
	add	sp, size RangeStruct		; fixup the stack
quit:
	.leave
	ret
DayPlanAlterRangeNow	endp

DayPlanCode	ends



RepeatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAddRepeatEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the DayPlan with one new repeat event

CALLED BY:	RepeatStore (MSG_DP_ADD_REPEAT_EVENT)

PASS:		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAddRepeatEvent	method	DayPlanClass,	MSG_DP_ADD_REPEAT_EVENT
	.enter

	; Create & fill empty EventRange structure
	;
	or	ds:[di].DPI_flags, DP_LOADING	; don't update right away!
	mov	di, ds:[LMBH_handle]		; block handle => DI
	sub	sp, size EventRangeStruct	; allocate a structure
	mov	bx, sp				; SS:BX contains empty struct
	mov	ss:[bx].ERS_object.handle, di	; store the DayPlan OD
	mov	ss:[bx].ERS_object.chunk, si
	mov	ax, MSG_DP_GET_RANGE
	call	ObjCallInstanceNoLock
	mov	{word} ss:[bx].ERS_startDay, ax
	mov	ss:[bx].ERS_startYear, cx
	mov	{word} ss:[bx].ERS_endDay, dx
	mov	ss:[bx].ERS_endYear, bp
	mov	ss:[bx].ERS_message, MSG_DP_LOAD_REPEAT

	; Load the events as necessary (possibly two different years)
	;
	cmp	bp, ss:[bx].ERS_startYear	; compare start/end years
	je	callFirst			; if same, just load that year
	mov	ss:[bx].ERS_endYear, cx		; else load one year....
	mov	{word} ss:[bx].ERS_endDay, ((12 shl 8) or 31)
	mov	cx, bp				; end year => CX
callFirst:
	mov	bp, bx				; SS:BP contains the structure
	call	GetRangeOfRepeats		; call for first year
	jc	done				; if aborted, load no more
	cmp	cx, ss:[bp].ERS_startYear	; compare start/end years
	je	done
	mov	{word} ss:[bp].ERS_startDay, ((1 shl 8) or 1)
	mov	ss:[bp].ERS_startYear, cx
	mov	{word} ss:[bp].ERS_endDay, dx
	mov	ss:[bp].ERS_endYear, cx
	call	GetRangeOfRepeats		; call for second year (if nec)

	; Clean up by forcing the screen to re-draw
done:
	add	sp, size EventRangeStruct	; restore the stack
	mov	cl, BufferUpdateFlags<1, 1, 1>	; delete, write-back, notify
	call	BufferAllWriteAndFree		; free all buffer usage
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
	and	ds:[di].DPI_flags, not DP_LOADING
	mov	di, ds:[di].DPI_eventTable	; event table handle => DI
	mov	di, ds:[di]			; dereference the table handle
	mov	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP
	mov	ds:[di].ETH_screenLast, OFF_SCREEN_BOTTOM
	mov	ax, MSG_DP_SCREEN_UPDATE
	mov	cx, size EventTableHeader	; start with the first event
	mov	dl, SUF_STEAL_FROM_BOTTOM	; steal from the bottom, if nec
	call	ObjCallInstanceNoLock		; redraw the screen

	.leave
	ret
DayPlanAddRepeatEvent	endp

RepeatCode	ends



SearchCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSearchDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load the events for a day s.t. they can be searched

CALLED BY:	GLOBAL (MSG_DP_SEARCH_DAY)
	
PASS:		DS:DI	= DayPlanClass specific instance data
		SS:BP	= RangeStruct
		CX	= LMem chunk holding SearchTable
		ES	= DGroup

RETURN:		DX	= Offset to next date with events (repeat or normal)

DESTROYED:	AX, BX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSearchDay	method	DayPlanClass,	MSG_DP_SEARCH_DAY
	.enter

	; Store some important information
	;
	push	ds:[di].DPI_eventTable		; save these values...
	push	{word} ds:[di].DPI_flags	; save the flags & text height
	or	es:[searchInfo], mask SI_SEARCHING
	mov	ds:[di].DPI_eventTable, cx	; store the new EventTable
	mov	ds:[di].DPI_flags, DP_LOADING	; to avoid re-draw requests
	mov	ds:[di].DPI_rangeLength, 1	; no header!
		
	; Initialize the SearchTable
	;
	mov	ax, cx				; handle => AX
	mov	cx, size EventTableHeader
	call	LMemReAlloc			; re-size the sucker
	mov	bx, ax				; handle => BX
	mov	bx, ds:[bx]			; derference the handle
	mov	ds:[bx].ETH_last, cx		; store the size

	; Load the events & clean-up
	;
	call	DayPlanAddRange			; add the range of events
	and	es:[searchInfo], not (mask SI_SEARCHING)
	pop	{word} ds:[di].DPI_flags	; restore flags & text height
	pop	ds:[di].DPI_eventTable		; save these values...

	.leave
	ret
DayPlanSearchDay	endp

SearchCode	ends



ObscureCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanFreeMem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Frees as much memory as possible within the DPResource
		resource block by de-allocating buffers that aren't visible,
		and requesting unusued buffers to free as much memory as
		possible.

CALLED BY:	GLOBAL
	
PASS:		DS:DI	= DayPlanClass specific instance data
		DS:*SI	= DayPlanClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This is a potentially dangerous operation if called
		from DayPlanScreenUpdate(), as the screenFirst/Last
		pointers may not accurately portray what buffers are
		allocated. Fortunately, this is OK, since BufferAlloc()
		is guaranteed to succeed every time when called immediately
		following a call to DayPlanFreeMem,

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/13/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanFreeMem	method	DayPlanClass,	MSG_DP_FREE_MEM
	uses	cx, dx, bp
	.enter

	; Find offsets to top and bottom events in the window
	;
	mov	cx, ds:[di].DPI_docOffset	; document offset => CX
	mov	dx, ds:[di].DPI_viewHeight	; height of view => DX
	call	DayPlanSearchByPosition		; Offset to top ETE => BX
	add	cx, dx
	dec	cx				; bottom document offset => CX
	mov	dx, bx				; store offset => DX
	call	DayPlanSearchByPosition		; Offset to bottom ETE => BX
						; EventTable => DS:*DI

	; Now free all events that are not (or will not be) visible
	;
	push	si				; save the DayPlan handle
	mov	si, ds:[di]			; dereference the table
	cmp	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP
	je	done				; if no buffers used, done
	mov	bp, size EventTableHeader	; initial offset => BP	
freeLoop:
	cmp	bp, dx				; compare with first on screen
	jb	delete				; if smaller, delete
	cmp	bp, bx				; compare with last on screen
	jbe	next				; if less or equal, do nothing
delete:
	tst	ds:[si][bp].ETE_handle		; any handle now ??
	jz	next				; no, so do nothing
	mov	ax, ds:[si][bp].ETE_handle	; handle => AX
	call	BufferFreeFar			; free the buffer from use
	mov	si, ds:[di]			; re-dereference the table
next:
	add	bp, size EventTableEntry	; go to the next entry
	cmp	bp, ds:[si].ETH_last		; are we done ??
	jb	freeLoop			; continue until done
		
	; Finally, free memory of all unused buffers
	;
	mov	ds:[si].ETH_screenFirst, dx	; store the top offset
	mov	ds:[si].ETH_screenLast, bx	; store the bottom offset
done:
	pop	si				; DayPlan handle => SI
	call	BufferFreeMem			; free the memory

	.leave
	ret
DayPlanFreeMem	endp

ObscureCode	ends
