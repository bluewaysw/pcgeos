COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayPlan
FILE:		dayplanMain.asm

AUTHOR:		Don Reeves, June 28, 1989

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/89		Initial revision
	Don	7/17/89		Moved to new UI
	Don	11/10/89	Modified for spec of 11/9
	Don	12/4/89		Use new class & method declarations

DESCRIPTION:
	Defines the "DayPlan" procedures that operate on this class.
		
	$Id: dayplanMain.asm,v 1.1 97/04/04 14:47:40 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include 	foam.def
include		timedate.def


GeometryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanViewSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of the view's size

CALLED BY:	UI

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data
		CX	= Width hint
		DX	= Height hint

RETURN:		CX	= Desired width
		DX	= Desired height

DESTROYED:	AX, BX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/5/89		Initial version
	sean	2/3/96		Responder version using
				fixed values

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanViewSize	method	DayPlanClass, MSG_VIS_RECALC_SIZE
	.enter

	; Store the event view height.  Then, depending on what 
	; view is being shown, store the event view width.
	;
	; Keep track of the size
	;
	mov	ax, MSG_VIS_CONTENT_GET_WIN_SIZE ; get the size of the view
	mov	di, offset DayPlanClass		; ES:DI points to my class
	call	ObjCallSuperNoLock		; call my superclass
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
	clr	bx				; set a "all clear" flag
	xchg	ds:[di].DPI_viewWidth, cx	; store the width
	xchg	ds:[di].DPI_viewHeight, dx	; store the height
	cmp	cx, ds:[di].DPI_viewWidth	; compare new & old widths
	pushf					; save the comparison result
	cmp	dx, ds:[di].DPI_viewHeight	; compare new & old height
	jge	checkWidth			; if greater or equal, do nada

	; The screen is now longer. Allocate sufficient buffers...
	;
	mov	di, ds:[di].DPI_eventTable	; event table handle => DI
	mov	di, ds:[di]			; dereference the chunk
	push	ds:[di].ETH_screenLast		; save the last offset
	call	BufferEnsureEnough		; make enough buffers
	pop	cx				; EventTable offset => CX
	mov	bx, 1				; must re-draw the screen

	; Now check to see if the width has changed
	;
checkWidth:
	popf					; restore comparison results
	je	checkUpdate			; no, so check for update
	mov	ax, MSG_DP_RECALC_HEIGHT	; resize every event
	call	ObjCallInstanceNoLock		; EventTable offset => CX
	mov	bx, 1				; must re-draw the screen

	; Finally, update the screen (if necessary)
	;
checkUpdate:
	tst	bx				; no changes ??
	jz	done				; then we're done
	mov	dl, SUF_STEAL_FROM_TOP or SUF_NO_REDRAW or SUF_NO_INVALIDATE
	mov	ax, MSG_DP_SCREEN_UPDATE	; send screen update method
	call	ObjCallInstanceNoLock

	; We're done - return the dimmensions
	;
done::
	call	VisGetSize			; return the correct size

	.leave
	ret
DayPlanViewSize	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanRecalcHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the height of every Event in the DayPlan

CALLED BY:	GLOBAL (MSG_DP_RECALC_HEIGHT)

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data

RETURN:		CX	= Offset to first event on screen

DESTROYED:	BX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version
	Don	6/28/90		Added update of current event text
	sean	4/6/95		Bogus dirty corrected

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanRecalcHeight	method	DayPlanClass,	MSG_DP_RECALC_HEIGHT
	.enter

; These lines cause the program to think that it needs to be saved
; after a view change.  For instance, when an event is selected in the
; To Do list, and we change to Calendar view, this code causes the 
; program to think that the database is dirty.  SeanS 4/6/95
;
	; Force the text of the current event to be updated
	;
	push	si				; store the DayPlan chunk
;	tst	ds:[di].DPI_selectEvent		; get the selected event
;	jz	setup				; if none, do nothing
;	mov	cl, DBUF_EVENT			; update the text only
;	mov	si, ds:[di].DPI_selectEvent	; selected event => SI
;	mov	ax, MSG_DE_UPDATE		; method to send
; 	call	ObjCallInstanceNoLock		; do it!

	; Some set-up work
; setup:	
	mov	cx, ds:[di].DPI_viewWidth	; window width => CX
	sub	cx, es:[timeOffset]		; take away offset to time 
	sub	cx, es:[timeWidth]		; take away the time width
	mov	si, ds:[di].DPI_eventTable	; get the table handle
	mov	di, ds:[si]			; derference the handle
	mov	bx, size EventTableHeader	; initial offset to BX
	mov	ds:[di].ETH_temp, 0		; clear the document height
	jmp	midLoop

	; Now loop, calculating
calcLoop:
	mov	ax, ds:[di][bx].ETE_group
	mov	di, ds:[di][bx].ETE_item
	call	EventCalcHeightFar
	mov	di, ds:[si]			; derference the EventTable
	mov	ds:[di][bx].ETE_size, dx	; store the new size
	add	ds:[di].ETH_temp, dx		; keep track of total size
	add	bx, size EventTableEntry	; go to the next entry
midLoop:
	cmp	bx, ds:[di].ETH_last
	jl	calcLoop
		
	; Store the new document size
	;
	mov	ax, ds:[di].ETH_temp		; total document height => AX
	pop	si				; DayPlan chunk => SI
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access the instance data
	mov	ds:[di].DPI_docHeight, ax	; store the new document height
	mov	cx, size EventTableHeader	; start update from top

	.leave
	ret
DayPlanRecalcHeight	endp

GeometryCode	ends



DayPlanCode segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepts the drawing of the DayPlan to display any
		additional information or to alter the drawing that is done.

CALLED BY:	UI (MSG_VIS_DRAW)
	
PASS:		ES	= Segment where DayPlanClass defined
		DS:DI	= DayPlanClass specific instance data
		DS:*SI	= DayPlanClass instance data
		BP	= GState handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanDraw	method	DayPlanClass,	MSG_VIS_DRAW
	.enter

	; Complete the drawing
	;
	push	bp				; save the GState handle
	mov	di, offset DayPlanClass
	call	ObjCallSuperNoLock		; have superclass draw first
	pop	di				; GState handle => DI

	; Check for no events whatsoever
	;
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access the instance data
	mov	bx, ds:[si].DPI_eventTable	; go to the event table
	mov	bx, ds:[bx]
	cmp	ds:[bx].ETH_last, size EventTableHeader
	jg	done				; if any events, done

	; Else display the "No Events" string
	;
if PZ_PCGEOS
	mov	cx, FID_PIZZA_KANJI		; cx <- FontID
	mov	dx, 16
	clr	ah				; dx.ah <- pointsize
	call	GrSetFont
endif

	mov	ax, ds:[si].DPI_viewWidth	; width => AX
	clr	cx				; string NULL terminated
	mov	si, offset NoEventsString	; chunk handle => SI
	mov	si, ds:[si]			; dereference the chunk
	call	GrTextWidth			; get length of string
	sub	ax, dx				; subtract length of string
	shr	ax, 1				; divide it by 2 to center
	mov	bx, 5				; draw near the top
	call	GrDrawText			; write it!!
done:

	.leave
	ret

DayPlanDraw	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanLoadEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an event into a day plan from the database

CALLED BY:	Database (MSG_DP_LOAD_EVENT)

PASS:		CX	= Group # of DB event
		DX	= Item # of DB event
		BP	= 0 to calculate insertion point
			= anything else to blindly insert at the end
		DS:*SI	= DayPlan instance data

RETURN:		Carry	= Set if error (too many events)

DESTROYED:	BX, DI, SI, ES

PSEUDO CODE/STRATEGY:
		Create an event
		Stuff the data to:
			Structure to the DayEvent
			Time to the TimeText object
			Event to the EventText object
		Call for insertion into the event table

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/2/89		Initial version
	Don	9/26/89		Major revision
	sean	3/19/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanLoadEvent	method	DayPlanClass, MSG_DP_LOAD_EVENT
	uses	ax, cx, dx, bp
	.enter

	; A little set up work
	;
	mov	ax, bp
	sub	sp, size EventTableEntry
	mov	bp, sp				; SS:BP points to structure
	push	ax				; save the insert value

	; Stuff the EventTableEntry structure
	;
	mov	ss:[bp].ETE_group, cx
	mov	ss:[bp].ETE_item, dx		; store the group # item #'s
	mov	ax, cx
	mov	di, dx
	call	GP_DBLockDerefDI		; lock the DB event
	mov	ax, es:[di].ES_timeYear
	mov	ss:[bp].ETE_year, ax		; copy the event year
	mov	ax, {word} es:[di].ES_timeDay
	mov	{word} ss:[bp].ETE_day, ax	; copy the event M/D
	mov	ax, {word} es:[di].ES_timeMinute
	mov	{word} ss:[bp].ETE_minute, ax	; copy the event time
	mov	ax, es:[di].ES_repeatID
	mov	ss:[bp].ETE_repeatID, ax	; copy the repeat ID
	mov	ax, es:[di].ES_dataLength	; length of text => AX


	RespCheckDB				; EC check db
	call	DBUnlock			; unlock the DB event

	;
	; Insert the EventTableEntry
	;
	pop	dx				; restore insertion indicator
	cmp	ax, INK_DATA_LENGTH		; check for INK (hack, hack)
	mov	ax, MSG_DP_LOAD_INK		; assume we have ink
	je	sendMessage			; if we have ink, jump
	mov	ax, MSG_DP_INSERT_ETE		; insert the event
sendMessage:
	call	ObjCallInstanceNoLock
	jc	done				; if too many events - fail

	; Do we need to insert it into the screen ??
	;
	clr	bp				; don't know buffer handle
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access instance data
	test	ds:[di].DPI_flags, DP_LOADING	; are we loading ??
	jne	done				; yes, do nothing (carry clear)
	push	dx				; save the actual event offset
	mov	ax, MSG_DP_SCREEN_UPDATE
	mov	dl, SUF_STEAL_FROM_BOTTOM	; steal from the bottom, if nec
	call	ObjCallInstanceNoLock		; else insert in the screen

	; Force the event to be selected
	;
	pop	cx				; actual event offset => CX
if	_TODO					; if showing To Do list, 
	mov	di, ds:[si]			; don't force event to be
	add	di, ds:[di].DayPlan_offset	; selected
	test	ds:[di].DPI_prefFlags, PF_TODO	
	jnz	done				
	call	CalendarIgnoreInput
endif	
	sub	sp, size ForceSelectArgs
	mov	bp, sp
	mov	ss:[bp].FSA_message, MSG_META_DUMMY
	mov	ss:[bp].FSA_callBack, 0		; must zero this out
	mov	ax, MSG_DP_FORCE_SELECT
	call	ObjCallInstanceNoLock
	add	sp, size ForceSelectArgs	; SP can't overflow, so CF = 0

	; Clean up
done:
	lahf					; flags => AH
	add	sp, size EventTableEntry	; restore the stack
	sahf					; restore carry flag

	.leave
	ret
DayPlanLoadEvent	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanLoadRepeat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load a repeat event

CALLED BY:	RepeatLoadEvent

PASS:		CX	= RepeatStruct group #
		DX	= RepeatStruct item #
		SS:BP	= EventRangeStruct
		DS:*SI	= DayPlan instance data

RETURN:		Carry	= Set if error (too many events)

DESTROYED:	BX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanLoadRepeat	method	DayPlanClass,	MSG_DP_LOAD_REPEAT
	uses	ax, cx, dx
	.enter

	; A little set up work
	;
	mov	bx, bp				; SS:BX points to EventRange
	sub	sp, size EventTableEntry
	mov	bp, sp				; SS:BP points to ETE struct

	; Stuff the EventTableEntry structure
	;
	mov	ss:[bp].ETE_group, cx
	mov	ss:[bp].ETE_item, dx		; store the group # item #'s
	mov	di, ss:[bx].ERS_startYear
	mov	ss:[bp].ETE_year, di		; store the year
	mov	ax, ss:[bx].ERS_curMonthDay
	mov	{word} ss:[bp].ETE_day, ax	; store the month & day

	xchg	ax, cx				; swap Month/Day & group
	xchg	di, dx				; swap Year, item #
	and	ax, not REPEAT_MASK		; clear the repeat bit
	call	GP_DBLockDerefDI		; lock the DB event
	mov	ax, {word} es:[di].RES_minute
	mov	{word} ss:[bp].ETE_minute, ax	; copy the event time
	mov	ax, es:[di].RES_ID
	mov	ss:[bp].ETE_repeatID, ax	; copy the repeat ID

	RespCheckDB
	call	DBUnlock

	; Insert the EventTableEntry (if necessary)
	;
	call	RepeatExistAlready		; look for this repeat event
	cmc					; invert the carry
	jnc	done				; if found, don't add!
	clr	dx				; calc insertion point
	mov	ax, MSG_DP_INSERT_ETE	; insert the event
	call	ObjCallInstanceNoLock		; insert the event
	jc	done				; if no room, fail

	; Do we need to insert it into the screen ??
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access instance data
	test	ds:[di].DPI_flags, DP_LOADING	; are we loading ??
	jnz	done				; yes, so do nothing
	mov	ax, MSG_DP_SCREEN_UPDATE
	mov	dl, SUF_STEAL_FROM_BOTTOM	; steal from the bottom, if nec
	call	ObjCallInstanceNoLock		; else insert in the screen
	clc					; clear the carry
	
	; Clean up (carry flag correct at this point)
done:
	lahf					; flags => AH
	add	sp, size EventTableEntry	; restore the stack
	mov	bp, bx				; put EventRange back to SS:BP
	sahf					; restore the carry flag

	.leave
	ret
DayPlanLoadRepeat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatExistAlready
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a specific RepeatID has already been loaded

CALLED BY:	DayPlanLoadRepeat

PASS:		DS:*SI	= DayPlan instance dat
		AX	= Repeat ID
		CX	= Month/Day
		DX	= Year

RETURN:		Carry	= Set if found
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/28/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatExistAlready	proc	near
	class	DayPlanClass
	uses	bx, di
	.enter

	; Access the EventTable, to search for the RepeatID
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access instance data
	mov	di, ds:[di].DPI_eventTable	; get table handle
	mov	di, ds:[di]			; dereference the handle
	mov	bx, ds:[di].ETH_last		; last offset position
	add	bx, di				; last true position
	add	di, (size EventTableHeader) - (size EventTableEntry)

	; Look for the ID
	;
searchLoop:
	add	di, size EventTableEntry
	cmp	di, bx
	je	done				; carry flag clear when equal
	cmp	dx, ds:[di].ETE_year
	jne	searchLoop
	cmp	cx, {word} ds:[di].ETE_day
	jne	searchLoop
	cmp	ax, ds:[di].ETE_repeatID
	jne	searchLoop			; jump if not equal
	stc					; found - set the carry flag
done:
	.leave
	ret
RepeatExistAlready	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DPHandleKeyStroke
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A key was pressed from month view or week view
		Bring up details dialog

CALLED BY:	MSG_DP_HANDLE_KEY_STROKE
PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #
		cx	= character
		dx	= hour
		bp	= DayPlanHandleKeyStrokeFlag
RETURN:		nothing
DESTROYED:	ax, cx, dx

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	2/10/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanNewEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new event to a day plan at the specified date/time

CALLED BY:	Many (MSG_DP_NEW_EVENT)

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data
		BP	= Year 
		DX	= Month/Day
		CX	= Hour/Minute

RETURN:		BP	= Handle of new DayEvent (if on screen, else 0)
		Carry	= Set if load failed

DESTROYED:	AX, BX, CX, DX, SI, DI, ES

PSEUDO CODE/STRATEGY:
		Create the EventTableEntry
		Insert it into the EventTable
		Insert the event visually
		Attempt to select it
		Set the undo action

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/29/89		Initial version
	Don	12/6/89		Major revision

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanNewEvent	method	DayPlanClass, MSG_DP_NEW_EVENT
	.enter

	; Some set-up work
	;
	mov	di, bp				; Year to DI
	sub	sp, size EventTableEntry	; allocate room on the stack
	mov	bp, sp				; SS:BP points to struct

		
	; Stuff the EventTableEntry
	;
	clr	ax
	mov	{word} ss:[bp].ETE_minute, cx
	mov	{word} ss:[bp].ETE_day, dx
	mov	ss:[bp].ETE_year, di
	mov	ss:[bp].ETE_group, ax
	mov	ss:[bp].ETE_item, ax
	mov	ss:[bp].ETE_size, ax
	mov	ss:[bp].ETE_handle, ax
	mov	ss:[bp].ETE_repeatID, ax
	clr	dx				; calculate the insertion point
	mov	ax, MSG_DP_INSERT_ETE
	call	ObjCallInstanceNoLock		; call myself to insert it
	jc	done				; if no space, fail
	push	dx				; save the actual event offset

	; Now handle the screen update
	;
	mov	ax, MSG_DP_SCREEN_UPDATE
	mov	dl, SUF_STEAL_FROM_BOTTOM	; steal from the bottom, if nec
	call	ObjCallInstanceNoLock

	; Now attempt to make it the selected item, and select the time
	;
	pop	cx				; event offset => CX


	sub	sp, size ForceSelectArgs
	mov	bp, sp
	mov	ss:[bp].FSA_message, MSG_DE_SELECT_TIME
	mov	ss:[bp].FSA_callBack, 0		; must zero this out
	mov	ax, MSG_DP_FORCE_SELECT
	call	ObjCallInstanceNoLock
	add	sp, size ForceSelectArgs
	call	UndoNotifyInsertEvent
	clc					; ensure carry is clear


	; We're outta here
done:

	lahf					; flags => AH	
	add	sp, size EventTableEntry	; restore the stack
	sahf					; restore the carry flag

	.leave
	ret	
DayPlanNewEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDeleteEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the selected event from the dayplan

CALLED BY:	UI (MSG_DP_DELETE_EVENT)

PASS:		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
		ES	= DGroup

RETURN:		AX	= UndoActionValue, if event deleted (-1 otherwise)

DESTROYED:	CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/7/90		Initial version
	Don	6/2/90		Incorporated DayPlanDeleteETE
	Don	7/10/90		Do nothing if event not found
	sean	1/3/96		Responder re-add template events
	reza	2/7/97		broke out Responder code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanDeleteEvent	method	dynamic	DayPlanClass,	MSG_DP_DELETE_EVENT
	.enter

	; Access the current selected event
	;
	mov	bp, ds:[di].DPI_selectEvent	; get handle of selected event

	tst	bp				; something selected ??
	jz	doneShort			; no, so do nothing

if	HANDLE_MAILBOX_MSG

	; Do delete update SMS, if necessary.
	;
	push	si
	mov	si, bp				; *ds:si <- DayEvent obj
	mov	ax, MSG_DE_CANCEL_ALL_APPOINTMENT
	call	ObjCallInstanceNoLock		; ax, cx, dx, bp destroyed
	mov	bp, si
	pop	si
endif

	call	DayPlanSearchByBuffer		; carry set it found
	jnc	doneShort			; do nothing if not found

	; Make certain we're not deleting a Repeating Event
	;
	push	di				; save the EventTable handle
	mov	di, ds:[di]			; dereference the handle
	test	ds:[di][bx].ETE_group, REPEAT_MASK
	mov	cx, ds:[di][bx].ETE_repeatID
	pop	di				; restore the EventTable handle
	jnz	doneShort			; if RepeatEvent, do nothing!

	; If we are deleting the descendant of a repeating event that still
	; exists, we want to re-display the repeating event
	;
	jcxz	nukeEvent			; if not descendant, nuke event
	call	RepeatIDStillExist		; RepeatStruct group:item=>CX:DX
						; time => AX
	jnc	nukeEvent			; if ID not found, delete event

	; Now here is where things get cute. We fool ourselves by saying
	; that we are about to perform a state change, from repeat to
	; normal, and then immediately perform an undo of that non-existent
	; change, which will result in the repeating event appearing.
	;
	call	UndoNotifyStateChange		; (registers already set up)
	mov	ax, MSG_GEN_PROCESS_UNDO_PLAYBACK_CHAIN
	call	GeodeGetProcessHandle
	call	ObjMessage_dayplan_call
doneShort:
	mov	ax, -1				; can't UNDO this	
	jmp	done

	; Clear the selection; set the triggers' status
nukeEvent:
	push	bp				; save the DayEvent handle
	clr	bp				; disable the undo trigger
	mov	ax, MSG_DP_SET_SELECT		
	call	ObjCallInstanceNoLock
	pop	bp				; restore the DayEvent handle

	; Remove the EventTableEntry, the DayEvent from the visual tree,
	; and ensure the DayEvent data is updated. Also, disable the
	; display errors bit in case of an invalid time.
	;
	and	es:[systemStatus], not SF_DISPLAY_ERRORS
	push	bp				; save the DayEvent handle
	mov	ax, bp				; buffer handle => AX
	mov	bp, di				; Event table => DS:*BP
	call	BufferFree			; free the DayEvent
	call	DayPlanDeleteCommon		; do the dirty work!

	; For Responder, we want to re-add template events, if we
	; happen to be deleting a template event.  (sean 1/3/96)
	;

	pop	bp				; DayEvent handle => BP
	push	bx				; save the EventTable offset
	or	es:[systemStatus], SF_DISPLAY_ERRORS

	; Now delete it from the database (also sets the undo action!)
	;
	call	GeodeGetProcessHandle
	mov	ax, MSG_CALENDAR_DELETE_EVENT
	call	ObjMessage_dayplan_call		; UndoActionValue => AX

	; Finally, call for the screen to be updated properly
	;
	pop	cx				; offset to begin working
	push	ax
	mov	ax, MSG_DP_SCREEN_UPDATE	; update the screen
	mov	dl, SUF_STEAL_FROM_TOP		; steal from the top, if nec
	call	ObjCallInstanceNoLock		; send that method
	call	DayPlanAbortSearch		; abort any search
	pop	ax
done:
	.leave
	ret
DayPlanDeleteEvent	endp




if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DPChangeToDoEventStatus
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes DayPlan's selected event priority.  This
		only makes sense for To Do list events.
		*Note*--An event's priority information is stored
		in the timeMinute field.  Since To Do events don't use
		this field, and since code already exists to order
		events on time, we can prioritize To Do list events with
		use of the timeMinute field.	


CALLED BY:	MSG_DP_CHANGE_EVENT_TO_NORMAL_PRIORITY,
		MSG_DP_CHANGE_EVENT_TO_HIGH_PRIORITY

PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,si,bp	

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Get the DayPlan's selected event
		If already this priority
		  done
		Else
		  Clear the event's complete field (no longer complete)
		  Set event's time (since the timeMinute field is the
		    event's priority for To do list events)
		  Update this change to the database
		  Change event within the EventTable
		  Redraw Screen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/15/95   	Initial version
	sean 	10/2/95		Force the event to be selected/EC code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPChangeToDoEventStatus		method dynamic DayPlanClass, 
					MSG_DP_CHANGE_EVENT_TO_NORMAL_PRIORITY,
					MSG_DP_CHANGE_EVENT_TO_HIGH_PRIORITY
	.enter

	; Access the current selected event
	;
	mov	dx, ax				; dx = message
	mov	ax, MSG_DP_GET_SELECT
	call	ObjCallInstanceNoLock		; bp = selected event
	tst	bp				; something selected ??
EC  <	ERROR_Z		MEMORY_HANDLE_DOESNT_EXIST		    >
NEC <	jz	done				; no, so do nothing >
	call	IsSamePriority			; check if same
	jc	done				; priority

	; Calculate the event's offset into EventTable
	;
	call	DayPlanSearchByBuffer		; bx = event ETE offset
EC  <	ERROR_NC	EVENT_TABLE_SEARCH_FAILED		>
NEC <	jnc	done						>

	; Clear the complete field
	;
	mov	ax, MSG_DP_CLEAR_COMPLETE	; clear completed field
	call	ObjCallInstanceNoLock

	; Since the priority information of a To Do event is
	; stored in a DayEvent's time, we set its time
	;
	mov	ax, MSG_DE_SET_TIME
	mov	ch, TODO_DUMMY_HOUR
	mov	cl, TODO_NORMAL_PRIORITY	; priority info in event minute
	cmp	dx, MSG_DP_CHANGE_EVENT_TO_NORMAL_PRIORITY
	je	continue
	mov	cl, TODO_HIGH_PRIORITY
continue:
	push	si				; save DayPlan handle
	mov	si, bp				; DayEvent handle => si
	call	ObjCallInstanceNoLock
	pop	bp				; restore DayPlan handle

	; Update this event
	;
	mov	ax, MSG_DE_UPDATE
	mov	cl, DBUF_TIME			; we're updating event time
	call	ObjCallInstanceNoLock

	; Place event into correct place in EventTable
	; Note--bx = offset of event in event table prior to shuffle 
	;
	call	ShuffleETE			; cx => offset of new position
	push	cx				; for event in event table

	; We use the lower of the two offsets in the EventTable
	; between bx and cx.
	;
	mov	ax, MSG_DP_SCREEN_UPDATE
	cmp	cx, bx				; which is smaller ?
	jle	highPriority			; cx = offset in EventTable
	mov	cx, bx				; to begin update
highPriority:
	mov	si, bp				; dayPlan => si
	clr	dl
	call	ObjCallInstanceNoLock

	; Force the changed event to be selected
	;
	call	CalendarIgnoreInput
	mov	ax, MSG_DP_FORCE_SELECT
	pop	cx				; restore offset in ETE
	mov	dx, size ForceSelectArgs
	sub	sp, dx
	mov	bp, sp
	mov	ss:[bp].FSA_message, MSG_DE_SELECT_TIME
	clr	ss:[bp].FSA_callBack
	call	ObjCallInstanceNoLock
	add	sp, size ForceSelectArgs	
done:
	.leave
	ret
DPChangeToDoEventStatus		endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		IsSamePriority
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks if a DayEvent is changing status.

CALLED BY:	DPNormalPriority (MSG_DP_CHANGE_EVENT_TO_NORMAL_PRIORITY)
		DPHighPriority   (MSG_DP_CHANGE_EVENT_TO_HIGH_PRIORITY)

PASS:		dx 	= message
			    TODO_NORMAL_PRIORITY
			    TODO_HIGH_PRIORITY
		bp	= DayEvent handle

RETURN:		carry set if event already has passed priority
		carry clear if event has different priority
		
DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		If completed or different priority
		  clear the carry flag
		Else (not completed and same priority)
		  set the carry flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/16/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
IsSamePriority	proc	near
	uses	bx,di,bp
	.enter

EC <	Assert	objectPtr, dsbp, DayEventClass			>

	mov	bl, TODO_NORMAL_PRIORITY
	cmp	dx, MSG_DP_CHANGE_EVENT_TO_NORMAL_PRIORITY
	je	continue
	mov	bl, TODO_HIGH_PRIORITY
continue:
	mov	di, ds:[bp]			; dereference dayevent
	add	di, ds:[di].DayEvent_offset
	cmp	ds:[di].DEI_alarmMinute, TODO_COMPLETED
	clc
	jz	done				; completed--clear carry 
	cmp	ds:[di].DEI_timeMinute, bl
	clc
	jnz	done				; not same priority--clear
	stc					; same priority & not complete
done:
	.leave
	ret
IsSamePriority	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ShuffleETE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Changes an EventTableEntry's position within the
		Event Table after its priority has changed.

CALLED BY:	DPHighPriority (MSG_DP_CHANGE_EVENT_TO_HIGH_PRIORITY)
		DPNormalPriority (MSG_DP_CHANGE_EVENT_TO_NORMAL_PRIORITY)
	
PASS:		ds:*si	= DayEvent object
		ds:*bp	= DayPlan object
		ds:*di	= EventTable 
		bx	= offset of ETE into EventTable
			  (i.e. ds:[*di][bx] = ETE)
			
RETURN:		cx	= EventTableEntry offset for shuffled event

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Copy event's EventTableEntry to stack
		call InsertETE putting Event into new position
		  (based on new priority)
		Find old EventTableEntry with old DayEvent handle
		Delete old EventTableEntry	
		Calculate new EventTableEntry offset

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/16/95    	Initial version
	sean	10/2/95		Fixed bug, EC code
	sean	12/13/95	Fixed 40716

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ShuffleETE	proc	near
	uses	ax,bx,dx,si,di,bp,es
	.enter

EC <	Assert	objectPtr, dssi, DayEventClass			>
EC < 	Assert 	objectPtr, dsbp, DayPlanClass			>

	; Force DayEvent to update if necessary.  Fixes #40716.
	; (sean 12/13/95).
	;
	mov	ax, MSG_DE_UPDATE
	mov	cl, DBUF_IF_NECESSARY
	call	ObjCallInstanceNoLock	

	; Copy EventTableEntry onto stack, then insert it
	;
	push	si				; save DayEvent handle
	mov	si, ds:[di]			; deref EventTable
EC <	cmp	bx, ds:[si].ETH_last				>
EC <	ERROR_GE	DP_SELECT_IF_POSSIBLE_BAD_OFFSET 	>
	cmp	ds:[si].ETH_last, LARGEST_EVENT_TABLE
	jge	popExit				; event table full
	add	si, bx				; ds:si = EventTableEntry

	sub	sp, size EventTableEntry	; create EventTableEntry 
	segmov	es, ss, di			; on stack
	mov	di, sp				; es:di = EventTableEntry
	mov	cx, size EventTableEntry	; # bytes to copy
	rep 	movsb				; copy 

	; Insert EventTableEntry into new position
	;
	mov	ax, MSG_DP_INSERT_ETE
	mov	si, bp				; DayPlan handle
	mov	bp, sp				; ss:bp = EventTableEntry
	clr	dx				; calculate insertion
	call	ObjCallInstanceNoLock		; dx => offset of event

	add	sp, size EventTableEntry	; restore stack
	
	; Delete old EventTableEntry
	;
	pop	bp				; DayEvent handle => bp
	call 	DayPlanSearchByBuffer		; bx = offset into EventTable

	mov	ax, bp				; buffer handle => ax
	mov	bp, di				; Event table => bp
	call	BufferFree			; free the DayEvent
	call	DayPlanDeleteCommon		; cx:dx = Gr:It of event

	; Return new offset of event
	;
	call	DayPlanSearchByEvent		; bx = event ETE offset
EC <	ERROR_NC	EVENT_TABLE_SEARCH_FAILED		>
	mov	cx, bx				; cx = event ETE offset
exit:
	.leave
	ret

	; Trying to shuffle when table is full.  So pop, then
	; return offset to update & force select first event.
	;
popExit:
	pop	si
	mov	cx, bx
	jmp	exit

ShuffleETE	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DPEventCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells the DayPlan object to mark the selected 
		DayEvent as completed.  Only To Do list events
		can be marked completed or not completed.
		*Note*--An event's completed information is 
		stored in its alarmMinute field.  To Do list
		events do not use this field, so it is reused
		to store completed information.

CALLED BY:	MSG_DP_EVENT_COMPLETED

PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #

RETURN:		nothing		

DESTROYED:	ax,bx,cx,dx,si,bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Get the DayPlan's selected event
		If completed field set
		  done
		Else
		  Clear the selected event
		  Change the event's alarmMinute (completed) field
		  Update event (store new alarmMinute info to database)
		  Redraw screen	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/17/95   	Initial version
	sean	10/2/95		Cleaned up/EC code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPEventCompleted	method dynamic DayPlanClass, 
					MSG_DP_EVENT_COMPLETED
	.enter

	; Access the current selected event
	;
	mov	ax, MSG_DP_GET_SELECT
	call	ObjCallInstanceNoLock		; bp = selected event
	tst	bp				; something selected ??
EC  <	ERROR_Z		MEMORY_HANDLE_DOESNT_EXIST		    >
NEC <	jz	done				; no, so do nothing >

	; If completed field is not set, we set it
	; otherwise, nothing.  Completed information
	; is stored in the To Do event's alarmMinute field
	;
	mov	di, ds:[bp]			; dereference dayevent
	add	di, ds:[di].DayEvent_offset
	cmp	ds:[di].DEI_alarmMinute, TODO_COMPLETED
	je	done				; completed info in alarmMinute

	; Store this change
	;
	mov	ax, MSG_DE_UPDATE		; update DayEvent
	mov	si, bp				; DayEvent => si
	mov	dl, TODO_COMPLETED		; changing completed info
	mov	ds:[di].DEI_alarmMinute, dl	; completed info in alarmMinute
	mov	cl, DBUF_ALARM			; so we up date alarm info
	call	ObjCallInstanceNoLock

	; Redisplay event
	;
	mov	ax, MSG_VIS_INVALIDATE		; redraw DayEvent object
	call	ObjCallInstanceNoLock	

done:
	.leave
	ret
DPEventCompleted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DPClearComplete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the completed field for the DayPlan's selected
		To Do list event.  This method only makes sense if the
		DayPlan is in "To Do List" mode.
		*Note*--An event's completed information is 
		stored in its alarmMinute field.  To Do list
		events do not use this field, so it is reused
		to store completed information.

CALLED BY:	MSG_DP_CLEAR_COMPLETE

PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #

RETURN:		nothing		

DESTROYED:	ax,cx,di,si	

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		Get the DayPlan's selected event
		If completed field clear
		  done
		Else
		  Clear the selected event
		  Change the event's alarmMinute (completed) field
		  Update event (store new alarmMinute info to database)

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/29/95   	Initial version
	sean	10/2/95		Cleaned up/EC code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPClearComplete 	method dynamic DayPlanClass, 
					MSG_DP_CLEAR_COMPLETE
	uses	dx, bp
	.enter

	; Access the current selected event
	;
	mov	ax, MSG_DP_GET_SELECT
	call	ObjCallInstanceNoLock		; bp = selected event
	tst	bp				; something selected ??
EC  <	ERROR_Z		MEMORY_HANDLE_DOESNT_EXIST		    >
NEC <	jz	done				; no, so do nothing >

	; If event is already NotCompleted, then done.
	; Else change completed field (alarmMinute) to NotCompleted.
	;
	mov	di, ds:[bp]			; dereference dayevent
	mov	si, bp				; DayEvent handle => si
	add	di, ds:[di].DayEvent_offset
	cmp	ds:[di].DEI_alarmMinute, TODO_NOT_COMPLETED
	je	done				; completed info in alarmMinute
	mov	dl, TODO_NOT_COMPLETED
	
	; Store this change
	;
	mov	ds:[di].DEI_alarmMinute, dl	; completed info in alarmMinute
	mov	ax, MSG_DE_UPDATE		; so we update alarm info
	mov	cl, DBUF_ALARM
	call	ObjCallInstanceNoLock

done:
	.leave
	ret
DPClearComplete	endm

endif		; if	_TODO


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDeleteRepeatEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove all occurrences of the repeating event from the DayPlan

CALLED BY:	RepeatDelete (MSG_DP_DELETE_REPEAT_EVENT)

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data
		CX	= RepeatStruct - Group #
		DX	= RepeatStruct - Item #

RETURN:		Nothing

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This implementation is very slow, but hopefully easy.
		It should be OK to be slow becuase multiple occurrences
		of a single RepeatEvent should be pretty unusual.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/15/90		Initial version
	Don	4/20/90		Utilized common search routine
	sean	1/3/96		Responder re-add template events
				Also, we update from deletion instead
				of entire screen.

				*Note*--Since Responder doesn't have
				more than occurance of a repeat event
				in the DayPlan at a time, we don't
				have to update the entire screen.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanDeleteRepeatEvent	method	DayPlanClass,
					MSG_DP_DELETE_REPEAT_EVENT
	uses	cx, dx, bp
	.enter

	; A little set-up work
	;
	clr	ax				; clear the initial offset
	or	cx, REPEAT_MASK			; set the low bit, thank you

	; Loop from the top
loopAll:
	push	ax				; save inital delete offset
	call	DayPlanSearchByEvent		; => carry set if found
	jnc	cleanUp				; if no carry, done!
	mov	bp, di				; table handle => BP
	tst	ax				; a valid handle (on screen?)
	je	finishDelete			; no, so jump
	call	BufferFree			; else free the buffer
finishDelete:
	call	DayPlanDeleteCommon		; delete the ETE (& header)
	pop	ax				; restore the initial offset
	tst	ax				; have we deleted yet?
	jnz	loopAll				; yes, so loop
	mov	ax, bx				; set first delete offset
	jmp	loopAll				; loop again, dude!

	; Finish by re-drawing the screen
cleanUp:
	pop	ax				; restore the initial offset
	tst	ax				; did we delete any events?
	jz	done				; no, so exit
	call	DayPlanAbortSearch		; abort any search
	push	ax				; save the first offset
	mov	di, ds:[di]			; dereference the table handle
	mov	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP
	mov	ds:[di].ETH_screenLast, OFF_SCREEN_BOTTOM
	mov	cl, BufferUpdateFlags<1, 1, 1>	; delete, write-back, notify
	call	BufferAllWriteAndFree		; free all buffer usage
	pop	cx				; restore first offset
	mov	ax, MSG_DP_SCREEN_UPDATE	; method to send
	clr	dl				; send no ScreenUpdateFlags
	call	ObjCallInstanceNoLock		; update the screen
done:
	.leave
	ret
DayPlanDeleteRepeatEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAbortSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Abort the search that is in progress

CALLED BY:	DayPlan & DayEvent INTERNAL
	
PASS:		DS	= DPResource segment
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/14/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAbortSearch	proc	near
	.enter

	; Indicate that the next search should start from the beginning
	;
	or	es:[searchInfo], mask SI_RESET

	.leave
	ret
DayPlanAbortSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanInsertETE
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert the events properly within the EventTable

CALLED BY:	DayPlanAddEvent, DayPlanNewEvent (MSG_DP_INSERT_ETE)

PASS: 		DS:*SI	= DayPlan instance data
		ES	= DGroup
		DX	= 0 to calculate insertion point
			= anything else to insert at end (blindly)
		SS:BP	= EventTableEntry

RETURN:		CX	= Offset to insertion point (update from here)
		DX	= Offset to the actual event
		Carry	= Set if too many events are now loaded

DESTROYED:	DI

PSEUDO CODE/STRATEGY:
		Search for correct place to insert (if DX == 0)
		Do we need to insert a header
			Yes - insrt the header
		Increase table size (if necessary)
		Write the data		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Note: Notice that the actual event offset may differ from
		the insertion point, as a header event could have been
		inserted BEFORE the actual event.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/26/89		Initial version
	Don	9/26/89		Major revision
	Don	12/4/89		Changed to manage myself
	Don	6/2/90		Return both offsets, not just update offset

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

LARGEST_EVENT_TABLE	= (size EventTableHeader + \
			  (MAX_NUM_EVENTS * (size EventTableEntry)))

DayPlanInsertETE	method	DayPlanClass, MSG_DP_INSERT_ETE
	uses	ax, bx, si, bp
	.enter

	; Set some update flags, see if we need to delete events
	;
	push	si				; save the DayPlan chunk
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
	or	ds:[di].DPI_flags, DP_NEEDS_REDRAW
	test	ds:[di].DPI_flags, DP_DEL_ON_LOAD
	je	startInsert			; no need to delete, so jump
	and	ds:[di].DPI_flags, not DP_DEL_ON_LOAD
	mov	cl, BufferUpdateFlags <1, 0, 1>	; write back & visually remove
	mov	ax, MSG_DP_DELETE_RANGE
	call	ObjCallInstanceNoLock		; delete the template...
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data

	; Go to the beginning of the table
startInsert:
	or	ds:[di].DPI_flags, DP_DIRTY	; set the dirty bit
	push	ds:[di].DPI_viewWidth		; save width on the stack
	mov	si, ds:[di].DPI_eventTable	; move the chunk handle to DI
	mov	di, ds:[si]			; dereference the pointer
	mov	bx, ds:[di].ETH_last		; go to the last position
	cmp	bx, LARGEST_EVENT_TABLE		; too many events ??
	jae	tooManyEvents			; yes, so display error
	cmp	dx, 1				; just insert at the end ??
	je	insert				; go to insert the entry

	; Search for the insertion point
	;
	push	bp				; save the EventTableEntry
	mov	ax, ss:[bp].ETE_repeatID
	mov	cx, {word} ss:[bp].ETE_minute
	mov	dx, {word} ss:[bp].ETE_day
	mov	bp, ss:[bp].ETE_year
	mov	bx, (size EventTableHeader) - (size EventTableEntry)

	; Loop until we find the insertion point
search:
	add	bx, size EventTableEntry	; go to the next structure
	cmp	bx, ds:[di].ETH_last		; at the least entry ??
	je	doneSearch
	call	EventCompare			; else compare the events
	jge	search				; continue until time is less
doneSearch:
	pop	bp				; restore the EventTableEntry

	; Perform the insertion
insert:
	mov	dx, bx				; original offset => DX
	call	DayPlanInsertHeader		; insert the header here!
	call	InsertETEAndUpdate		; insert an ETE; update header
	
	; Store the EventTable information
	;
	add	di, bx				; go the this entry
	mov	ax, ss:[bp].ETE_year
	mov	ds:[di].ETE_year, ax	
	mov	ax, {word} ss:[bp].ETE_day
	mov	{word} ds:[di].ETE_day, ax	
	mov	ax, {word} ss:[bp].ETE_minute
	mov	{word} ds:[di].ETE_minute, ax	
	mov	ax, ss:[bp].ETE_repeatID
	mov	ds:[di].ETE_repeatID, ax
	mov	ax, ss:[bp].ETE_group
	mov	ds:[di].ETE_group, ax		; group # => AX
	mov	cx, ss:[bp].ETE_item
	mov	ds:[di].ETE_item, cx		; item # => CX
	mov	ds:[di].ETE_handle, 0		; not currently displayed

	; Calculate the correct size
	;
	mov	di, cx				; item # to DI
	pop	cx				; width of window to CX
	sub	cx, es:[timeOffset]		; take away offset to time 
	sub	cx, es:[timeWidth]		; take away the time width
	push	dx				; save the original offset
	call	EventCalcHeight			; calculate the height
	pop	cx				; original insertion to CX
	mov	di, ds:[si]			; dereference the table
	mov	ds:[di][bx].ETE_size, dx	; save the size
	pop	si				; DayPlan chunk => SI
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
	add	ds:[di].DPI_docHeight, dx	; update the document size
	mov	dx, bx				; actual event offset => DX
	clc					; return success
done:
	.leave
	ret

	; Display error for too many events.  For Responder, we
	; display this error only when in wide mode(i.e event view
	; or To-do list).  Furthermore, if To-do list turn off "Mark
	; as" trigger, since this messes with EventTable(bad).
	;
tooManyEvents:
	mov	bp, CAL_ERROR_ET_TOO_BIG
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	mov	bx, ds:[LMBH_handle]		; resource handle => BX
	call	MemOwner			; my process => BX
	call	ObjMessage_dayplan_call		; display the error
	pop	ax, ax				; clear the stack
	stc					; carry indicates failure
	jmp	done				; we're outta here
DayPlanInsertETE	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EventCompare
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Compare's two events by their time. If the times are the
		same, and both are repeating events, then order by Repeat
		ID (this is to ensure that modified repeating events are
		displayed in the correct order immediately after modification)

CALLED BY:	DayPlanInsertEvent

PASS: 		DS:DI	= EventTable
		BX	= Offset to the EventTableEntry
		BP	= Year
		DX	= Month/Day
		CX	= Hour/Minute
		AX	= Repeat ID (if any)

RETURN:		Sets N & Z flags

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/27/89		Initial version
	Don	10/13/94	Ordering for repeating events

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EventCompare	proc	near
	class	DayPlanClass			; friend to this class
	.enter

	; Just do the comparison
	;
		
	; for responder this is removed because Reserve whole day events
	; are treated as multiple day events and if we are on the 2nd
	; reserve whole day event, event will automatically inserted into
	; slot 00:00 regardless of its start time because ETE_day is smaller
	; than current date.
	;
	cmp	bp, ds:[di][bx].ETE_year
	jne	done
	cmp	dx, {word} ds:[di][bx].ETE_day
	jne	done
	cmp	cx, {word} ds:[di][bx].ETE_minute
	jne	done

	; Times are the same. Perform comparison based upon Repeat ID, if
	; both events are repeating (or a descendants of a repeating event)
	;
	tst	ax
	jz	done				; not repeat, return Z = 1
	tst	ds:[di][bx].ETE_repeatID
	jz	done				; not repeat, return Z = 1
	cmp	ax, ds:[di][bx].ETE_repeatID	; ...else perform comparison
done:
	.leave
	ret
EventCompare	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDeleteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Involved in removing an EventTableEntry.  Does the following:
			- Update the document size
			- Remove a header, if necessary
			- Remove this structure

CALLED BY:	DayPlanDeleteETE, DayPlanDeleteRepeatEvent

PASS:		ES	= DGroup
		DS:*SI	= DayPlan instance data
		DS:*BP	= EventTable
		BX	= Offset to EventTableEntry to be removed

RETURN:		CX	= Group of deleted ETE
		DX	= Item of deleted ETE

DESTROYED:	AX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/15/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanDeleteCommon	proc	near
	class	DayPlanClass
	.enter

	; Update the document height
	;
	mov	di, ds:[bp]			; dereference the event table
	push	ds:[di][bx].ETE_group
	push	ds:[di][bx].ETE_item		; push the group & item #'s
	mov	cx, ds:[di][bx].ETE_size	; event size => CX
	mov	di, ds:[si]			; dereference the DayPlan
	add	di, ds:[di].DayPlan_offset	; access my instance data
	or	ds:[di].DPI_flags, (DP_NEEDS_REDRAW or DP_DIRTY)
	sub	ds:[di].DPI_docHeight, cx	; update the document size
	
	; Delete (??) the header event, and this EventTableEntry
	;
	mov	di, bp				; EventTable handle => DI
	call	DayPlanDeleteHeader		; delete header if any
	call	DeleteETEAndUpdate		; delete the structure
	pop	cx, dx				; group => CX; item => DX

	.leave
	ret
DayPlanDeleteCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanInsertHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert a header event into the EventTable (if necessary)

CALLED BY:	DayPlanInsertEvent

PASS:		DS:*SI	= EventTable
		ES	= DGroup
		SS:BP	= New EventTableEntry
		BX	= Offset to insert new entry

RETURN:		BX	= Adjusted offset

DESTROYED:	AX, CX, DI

PSEUDO CODE/STRATEGY:
		We need to insert a header event iff:
			headerFlag = TRUE
			EventTableEntry prior to new is of a different day

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/1/90		Initial version
	sean	3/19/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanInsertHeader	proc	near
	class	DayPlanClass
	.enter

	; First check the header flag
	;
	sub	bx, size EventTableEntry	; go backward one entry
	mov	di, offset DPResource:DayPlanObject
	mov	di, ds:[di]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access the instance data
TODO <	test	ds:[di].DPI_prefFlags, PF_TODO		>
TODO <	jnz	done					>	
	test	ds:[di].DPI_printFlags, mask DPPF_FORCE_HEADERS
	jnz	checkPrior
	cmp	ds:[di].DPI_rangeLength, 1	; do we want headers ??
	je	done				; jump if only one day!

	; Is prior ETE of the same day ??
checkPrior:
	mov	di, ds:[si]			; derference the EventTable
	cmp	bx, size EventTableHeader
	jl	doInsert			; first entry - insert
	mov	cx, {word} ss:[bp].ETE_day	; new month/day to CX
	cmp	cx, {word} ds:[di][bx].ETE_day
	jne	doInsert			; month/day not equal - insert
	mov	cx, ss:[bp].ETE_year		; new year to CX
	cmp	cx, ds:[di][bx].ETE_year
	je	done				; years equal - done

	; Insert the header
doInsert:
	add	bx, size EventTableEntry	; restore BX to insert position
	call	InsertETEAndUpdate

	; Store the EventTable information
	;
	clr	ax				; zero to AX
	add	di, bx				; go the this entry
	mov	cx, ss:[bp].ETE_year
	mov	ds:[di].ETE_year, cx	
	mov	cx, {word} ss:[bp].ETE_day
	mov	{word} ds:[di].ETE_day, cx	
	mov	{word} ds:[di].ETE_minute, -2	; must precede blank, which =-1
	mov	ds:[di].ETE_repeatID, ax
	mov	ds:[di].ETE_group, ax
	mov	ds:[di].ETE_item, 1
	mov	ds:[di].ETE_handle, ax

	; Update the size information
	;
	mov	cx, es:[oneLineTextHeight]	; one line size to CX
	mov	ds:[di].ETE_size, cx		; store the size
	mov	di, offset DPResource:DayPlanObject
	mov	di, ds:[di]
	add	di, ds:[di].DayPlan_offset
	add	ds:[di].DPI_docHeight, cx	; track the document size
done:
	add	bx, size EventTableEntry	; update (or restore) index
	.leave
	ret
DayPlanInsertHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDeleteHeader
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete header event, if no events on the given date no
		longer exist.

CALLED BY:	DayPlanDeleteEvent

PASS:		DS:*SI	= DayPlan instance data
		DS:*DI	= EventTable
		BX	= Offset to ETE that will be deleted

RETURN:		BX	= Updated offset

DESTROYED:	AX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanDeleteHeader	proc	near
	class	DayPlanClass
	uses	di, si, bp
	.enter

	; First some set-up work
	;
	mov	si, ds:[si]			; dereference the dayplan
	add	si, ds:[si].DayPlan_offset	; access instance data
	cmp	ds:[si].DPI_rangeLength, 1	; if one day, no header
	je	done
	test	ds:[si].DPI_flags, DP_HEADERS	; do we want all headers??
	jne	done				; if so, do nothing
	mov	ax, di				; table handle to AX
	mov	di, ds:[di]			; dereference the table handle
	mov	cx, {word} ds:[di][bx].ETE_day	; month/day => CX
	mov	dx, ds:[di][bx].ETE_year	; year => DX
	
	; Check for event of same date after us
	;
	mov	bp, bx				; offset to BP
	add	bp, size EventTableEntry	; BP points at next ETE
	cmp	bp, ds:[di].ETH_last		; offset too big ??
	jge	checkBefore			; yes, jump
	cmp	cx, {word} ds:[di][bp].ETE_day	; compare month & day
	jne	checkBefore
	cmp	dx, ds:[di][bp].ETE_year	; compare the year
	je	done				; a match - don't delete header

	; Check for header before us
checkBefore:
	mov	bp, bx
	sub	bp, size EventTableEntry	; go to previous ETE
	cmp	ds:[di][bp].ETE_group, 0	; is the group zero ??
	jne	done				; no, so can't be header
	cmp	ds:[di][bp].ETE_item, 1		; is this a header
	jne	done				; no, so can't be a header

	; We have a header - so remove it!
	;
	mov	bx, bp				; offset to delete to BX
	mov	cx, ds:[di][bx].ETE_size	; size to CX
	push	ds:[di][bx].ETE_handle		; save the handle
	sub	ds:[si].DPI_docHeight, cx	; update document size
	mov	di, ax				; Table handle back to DI
	call	DeleteETEAndUpdate		; delete the header !!

	; Free the handle, if any
	;
	pop	ax				; buffer handle to AX
	tst	ax
	je	done
	call	BufferFree			; else free the buffer
done:	
	.leave
	ret
DayPlanDeleteHeader	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertETEAndUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Inserts an EventTableEntry into the EventTable, and updates
		the header

CALLED BY:	DayPlanInsertEvent, DayPlanInsertHeader

PASS:		DS:*SI	= EventTable
		BX	= Offset to insert at

RETURN:		DS:DI	= EventTable

DESTROYED:	AX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InsertETEAndUpdate	proc	near
	.enter

	; First insert the bytes
	;
	mov	ax, si
	mov	cx, size EventTableEntry
	call	LMemInsertAt			; insert the bytes at BX

	; Update the header
	;
	mov	di, ds:[si]			; dereference the handle again
	add	ds:[di].ETH_last, cx		; move things along
	cmp	ds:[di].ETH_screenLast, OFF_SCREEN_BOTTOM
EC <	jne	continue						>
EC <	cmp	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP			>
EC <	je	done							>
EC <	ERROR	DP_VERIFY_INVALID_EVENT_TABLE				>
EC <continue:								>
	je	done				; if no prev events, do nothing
	cmp	bx, ds:[di].ETH_screenLast
	ja	done				; jump if larger
	add	ds:[di].ETH_screenLast, cx
	cmp	bx, ds:[di].ETH_screenFirst
	ja	done				; jump if larger
	add	ds:[di].ETH_screenFirst, cx
done:
	.leave
	ret
InsertETEAndUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DeleteETEAndUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Deletes an EventTableEntry from the EventTable, and updates
		the header

CALLED BY:	GLOBAL

PASS:		DS:*DI	= EventTable
		BX	= Offset to delete at

RETURN:		Nothing

DESTROYED:	AX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		ScreenFirst could become garbaged!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/6/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DeleteETEAndUpdate	proc	near
	uses	si
	.enter

	; First delete the bytes
	;
	mov	ax, di				; chunk handle to AX
	mov	cx, size EventTableEntry	; bytes to remove
	call	LMemDeleteAt			; insert the bytes at BX

	; Update the header
	;
	mov	si, ds:[di]			; dereference the handle again
	sub	ds:[si].ETH_last, cx		; move things along
	mov	ax, ds:[si].ETH_screenLast
	cmp	ax, ds:[si].ETH_screenFirst	; if first = last
	jne	updateHeader			; then no more buffers are used
	mov	ds:[si].ETH_screenFirst, OFF_SCREEN_TOP
	mov	ds:[si].ETH_screenLast, OFF_SCREEN_BOTTOM
	jmp	done	
updateHeader:
	cmp	bx, ds:[si].ETH_screenLast
	ja	done				; jump if larger
	sub	ds:[si].ETH_screenLast, cx
	cmp	bx, ds:[si].ETH_screenFirst
	jae	done				; jump if larger
	sub	ds:[si].ETH_screenFirst, cx
done:
	.leave
	ret
DeleteETEAndUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		EventCalcHeight
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the height of an event

CALLED BY:	GLOBAL

PASS:		AX	= Group # for the Event
		DI	= Item # for the Event
		CX	= Width of the event's text field (not the window)
		DS	= DPResource segment
		ES	= DGroup

RETURN:		DX	= The height of the object

DESTROYED:	AX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		If (AX == 0)
			Then size = one line height (header or virgin)
		Else {
			Stuff size object with the text
			Calculate the height
		}						

		Also, if we are printing events inside of a month object,
		we want events without a time to occupy the entire width,
		so we calculate by re-adding in the timeWidth offset.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/4/89		Initial version
	sean	8/1/95		Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

EventCalcHeightFar	proc	far
	call	EventCalcHeight
	ret
EventCalcHeightFar	endp

EventCalcHeight	proc	near
	uses	ax, cx, si, es
	.enter

	; Handle the header & virgin events
	;
	mov	dx, es:[oneLineTextHeight]	; one line height to DX
	tst	ax				; no group ?? (VRIGIN EVENT ?)
	jz	done

	; If we're in "Narrow" mode for Responder, then we don't want
	; multi-line events.
	;
	test	es:[searchInfo], mask SI_SEARCHING
	jnz	done				; searching doesn't height
	push	cx				; save the width
	test	ax, REPEAT_MASK			; test for a repeat event
	jne	repeat

	; Handle the normal event
	;
	call	GP_DBLock			; lock the Event Struct
	mov	bp, es:[di]			; dereference the handle
	mov	cx, es:[bp].ES_dataLength	; # of bytes
	add	bp, offset ES_data		; DX:BP points to the text
	jmp	common

	; Handle the repeat case
repeat:
	and	ax, not REPEAT_MASK		; clear the mask bit
	call	GP_DBLock			; lock the Repeat Struct
	mov	bp, es:[di]			; dereference the handle
	mov	cx, es:[bp].RES_dataLength
	add	bp, offset RES_data

	; Set the text and call for the resize
common:
DBCS <	shr	cx, 1				; cx <- # of chars	>
	mov	dx, es
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR ; set the text
	mov	si, ss:[SizeTextObject]		; handle of object to SI
	call	ObjCallInstanceNoLock
	RespCheckDB
	call	DBUnlock			; unlock the database
	pop	cx				; width => CX
	clr	dx				; don't use cached size
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT	; calculate the height
	call	ObjCallInstanceNoLock		; returned in DX
done:
	.leave
	ret
EventCalcHeight	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanETEUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the group & item numbers of an EventTableEntry

CALLED BY:	DayEventUpdate (MSG_DP_ETE_UPDATE)

PASS:		DS:*SI	= DayPlan instance data
		DS:DI	= DayPlan specific instance data (by method call)
		CX	= Group #
		DX	= Item #
		BP	= DayEvent handle

RETURN:		Nothing

DESTROYED:	BX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/13/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanETEUpdate	method	DayPlanClass,	MSG_DP_ETE_UPDATE
	.enter

	; Find the handle from the corresponding EventTableEntry
	;
	or	ds:[di].DPI_flags, DP_DIRTY	; the DayPlan is now dirty
	call	DayPlanSearchByBuffer
	jnc	done				; jump if not found

	; Else reset the group & item numbers
	;
	mov	di, ds:[di]			; dereference the EventTable
	mov	ds:[di][bx].ETE_group, cx	; store the group #
	mov	ds:[di][bx].ETE_item, dx	; store the item #


	; Get the current selection - see if we are it
	;
	mov	bx, bp				; buffer handle => BX
	mov	ax, MSG_DP_GET_SELECT
	call	ObjCallInstanceNoLock
	xchg	bx, bp				; swap the handles
	cmp	bx, bp				; are they the same ??
	jne	done				; no, so do nothing
	mov	ax, MSG_DP_SET_SELECT		; else resert the selection
	call	ObjCallInstanceNoLock		; send the method
done:
	.leave
	ret
DayPlanETEUpdate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanETEHeightNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Updates an ETE's size value as the event text changes height

CALLED BY:	DayEventHeightNotify

PASS:		DS:*SI	= DayPlan instance data
		BP	= Handle of DayEvent
		CX	= DayEvent's top boundary
		DX	= New height

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanETEHeightNotify	method	DayPlanClass,	MSG_DP_ETE_HEIGHT_NOTIFY
	.enter

	; For Responder, if we're showing the main view(Calendar &
	; Events) we don't want events to be multi-line.  This fixes
	; it so events will only be shown as single-line. (Bug #39100)
	;

	; Find the handle in the corresponding EventTableEntry
	;
	call	DayPlanSearchByBuffer		; look for the event
	jnc	done				; if not found, exit!

	; Compare the sizes
	;
	mov	di, ds:[di]			; dereference the table handle
	sub	dx, ds:[di][bx].ETE_size	; size difference to DX
	jz	done				; if none, do nothing
	add	ds:[di][bx].ETE_size, dx
	mov	di, ds:[si]			; derference the DayPlan handle
	add	di, ds:[di].DayPlan_offset	; access the instance data
	add	ds:[di].DPI_docHeight, dx	; adjust the document height
	
	; Assume the height has changed, and mark the thing's geometry as 
	; invalid.
	;
	mov	cl, mask VOF_GEOMETRY_INVALID	; mark the geometry as invalid
	mov	dl, VUM_MANUAL
	call	VisMarkInvalid
	
	; Now re-position everything (and redraw)
	;
	mov	cx, bx				; ETE offset to CX
	mov	dl, SUF_STEAL_FROM_TOP		; steal from the top
	mov	ax, MSG_DP_SCREEN_UPDATE	; update the screen
	call	ObjCallInstanceNoLock		; re-draws the screen!
done:
	.leave
	ret
DayPlanETEHeightNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanTimeNotify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the DayPlan of a change in event time

CALLED BY:	GLOBAL
	
PASS:		DS:*SI	= DayPlan instance data
		BP	= DayEvent handle (buffer)
		CX	= New time (hours:minutes)

RETURN:		Nothing

DESTROYED:	BX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanTimeNotify	method	DayPlanClass,	MSG_DP_ETE_TIME_NOTIFY
	.enter

	; Find the handle in the corresponding EventTableEntry
	;
	call	DayPlanSearchByBuffer		; look for the event
	jnc	done				; if not found, exit!
	mov	di, ds:[di]			; dereference the table handle
	mov	{word} ds:[di][bx].ETE_minute, cx
done:
	.leave
	ret
DayPlanTimeNotify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanETELostBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify an EventTableEntry that it no longer has a buffer
		(a DayEvent handle)

CALLED BY:	DayEventVisClose (MSG_DE_ETE_LOST_BUFFER)

PASS:		DS:*SI	= DayEvent instance
		BP	= DayEvent handle that's been lost
		
RETURN:		Nothing

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanETELostBuffer	method	DayPlanClass,	MSG_DP_ETE_LOST_BUFFER
	.enter

	; Find the EventTableEntry; clear the handle
	;
	call	DayPlanSearchByBuffer
	jnc	done				; not found - do nothing
	mov	di, ds:[di]			; dereference the EventTable
	mov	ds:[di][bx].ETE_handle, 0	; clear the stored handle
done:
	.leave
	ret
DayPlanETELostBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanETEForceUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find (and update) a specific EventStruct

CALLED BY:	AlarmToScreen

PASS:		DS:*SI	= DayPlan instance data
		CX	= Group #
		DX	= Item #

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/1/90		Initial version
	Don	3/22/90		Broke out separate search routine

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanETEForceUpdate	method	DayPlanClass,	MSG_DP_ETE_FORCE_UPDATE
	uses	cx
	.enter

	; Find the event
	;
	call	DayPlanSearchByEvent		; find the sucker
	jnc	done				; if not found, done
	mov	di, ds:[di]			; dereference the handle
	mov	si, ds:[di][bx].ETE_handle
	tst	si				; valid handle ??
	je	done				; no, so jump
	mov	ax, MSG_DE_UPDATE		; else update as needed...
	mov	cl, DBUF_IF_NECESSARY
	call	ObjCallInstanceNoLock
done:	
	.leave
	ret
DayPlanETEForceUpdate	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanETEFindEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search to see if the EventStruct is currently loaded into
		a DayEvent buffer.

CALLED BY:	GLOBAL (MSG_DP_ETE_FIND_EVENT)

PASS:		ES	= DGroup
		DS:*SI	= DayEvent instance data
		CX:DX	= Event Group:Item

RETURN:		BP	= Offset in EventTable
		AX	= DayEvent buffer (if present)
		Carry	= Set if found (clear if not)

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanETEFindEvent	method	DayPlanClass,	MSG_DP_ETE_FIND_EVENT
	.enter

	call	DayPlanSearchByEvent		; look for the event
	mov	bp, bx				; offset to BP

	.leave
	ret
DayPlanETEFindEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSearchByBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Look for a specific EventTableEntry in the EventTable

CALLED BY:	GLOBAL

PASS:		DS	= DPResource segment
		BP	= DayEvent handle to look for

RETURN:		DS:*DI	= EventTable
		BX	= Offset to the EventTableEntry
		Carry	= Set if found

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DayPlanSearchByBuffer	proc	near
	uses	si
	.enter

	; Some set-up work
	;
	mov	di, offset DPResource:EventTable
	mov	si, ds:[di]			; derference the handle
	mov	bx, (size EventTableHeader - size EventTableEntry)

	; Search loop
searchLoop:
	add	bx, size EventTableEntry
	cmp	bx, ds:[si].ETH_last		; at the end of the table ??
	jge	done				; not found, exit (carry clear)
	cmp	bp, ds:[si][bx].ETE_handle
	jne	searchLoop
	stc					; found, so set the carry bit
done:
	.leave
	ret
DayPlanSearchByBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSearchByEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search through the EventTable by event GROUP:ITEM values

CALLED BY:	GLOBAL

PASS:		DS	= DPResource segment
		CX:DX	= Event Group:Item to find

RETURN: 	DS:*DI	= EventTable
		BX	= Offset to the EventTableEntry
		AX	= DayEvent buffer handle (or 0 if none)
		Carry	= Set if found

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSearchByEvent	proc	near
	uses	si
	.enter

	; Some set-up work
	;
	mov	di, offset DPResource:EventTable
	mov	si, ds:[di]			; derference the handle
	mov	bx, size EventTableHeader - (size EventTableEntry)

	; Search loop
searchLoop:
	add	bx, size EventTableEntry
	cmp	bx, ds:[si].ETH_last		; at the end of the table ??
	jge	done				; not found, exit (carry clear)
	cmp	dx, ds:[si][bx].ETE_item	; compare the items
	jne	searchLoop			; jump if not equal
	cmp	cx, ds:[si][bx].ETE_group	; compare the groups
	jne	searchLoop			; jump if not equal
	mov	ax, ds:[si][bx].ETE_handle	; buffer handle => AX
	stc					; set carry bit (we found it)
done:
	.leave
	ret
DayPlanSearchByEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanSearchByPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Search through the EventTable for an event by its Y position

CALLED BY:	GLOBAL

PASS: 		DS:*SI	= DayPlanClass instance data
		CX	= Y position (document offset)

RETURN: 	DS:*DI	= EventTable
		BX	= Offset to the EventTableEntry
		AX	= Top position of the event

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		If the position passed no longer exists, then the offset
		to the end of the last event is returned.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanSearchByPosition	proc	far
	class	DayPlanClass
	uses	si
	.enter

	; Some set-up work
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access instance data
	mov	di, ds:[di].DPI_eventTable	; access the event table
	mov	si, ds:[di]			; dereference the handle
	mov	bx, (size EventTableHeader) - (size EventTableEntry)
	clr	ax				; begin offset count

	; Loop to find position of the first object (actually one past)
	;
positionLoop:
	add	bx, size EventTableEntry	; go to the next entry
	cmp	bx, ds:[si].ETH_last		; compare with last entry
	je	done				; we're done (carry clear)
EC <	ERROR_G	DP_VERIFY_INVALID_EVENT_TABLE	; bizarre event table	>
	add	ax, ds:[si][bx].ETE_size	; add event size => doc offset
	cmp	ax, cx				; compare current with desired
	jl	positionLoop			; go 'round again
	sub	ax, ds:[si][bx].ETE_size	; start position => AX
done:
	.leave
	ret
DayPlanSearchByPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanScreenUpdate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the screen after an insertion

CALLED BY:	GLOBAL (MSG_DP_SCREEN_UPDATE)

PASS:		DS:*SI	= DayEvent instance data
		CX	= Offset to EventTableEntry to start update
		DL	= ScreenUpdateFlags
				SUF_STEAL_FROM_TOP
				SUF_STEAL_FROM_BOTTOM
				SUF_NO_REDRAW
				SUF_NO_INVALIDATE

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanScreenUpdate	method	DayPlanClass,	MSG_DP_SCREEN_UPDATE
	.enter

	; See if memory is a problem
	;
	mov	ax, ds:[LMBH_blockSize]
	sub	ax, ds:[LMBH_totalFree]		; used space => AX
	cmp	ax, LARGE_BLOCK_SIZE		; using too much ?
	jb	setup				; if smaller, don't worry
	mov	ax, MSG_DP_FREE_MEM		; else free some memory
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	mov	di, mask MF_FORCE_QUEUE		; put on end of the queue
	call	ObjMessage

	; Access the event table
	;
setup:
	push	dx				; save ScreenUpdateFlags
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].DayPlan_offset	; access the instance data
	and	ds:[bp].DPI_flags, not DP_NEEDS_REDRAW
	mov	di, ds:[bp].DPI_eventTable	; get the table handle
	mov	di, ds:[di]			; dereference the table handle

 	; Find the upper screen position of the first buffer
	;
	clr	ax				; inital screen offset
	mov	bx, size EventTableHeader	; offset to first ETE
	jmp	midLoop
posLoop:
	add	ax, ds:[di][bx].ETE_size	; update the screen
	add	bx, size EventTableEntry	; go to the next structure
midLoop:
	cmp	bx, cx
	jl	posLoop
	push	ax, bx				; screen & EventTable offset
	cmp	bx, ds:[di].ETH_last		; if buffer was very last one
	LONG je	position			; ...then just update screen
						; ...as that buffer was deleted

	; At this point, we need to know if any portion of the original screen
	; will still be displayed. If so, we allow the buffer to be allocated
	; on an as-needed basis.  Else we free all the buffers.  This is all
	; to keep the buffers allocated contiguously...
	;
	mov	cx, bx				; current position => CX
	sub	cx, size EventTableEntry	; can actually be one past...
	cmp	cx, ds:[di].ETH_screenLast	; beyond the last ??
	jg	freeAll				; yes, so free all
	mov	ds:[di].ETH_temp, ax		; store the screen offset here
	mov	cx, ds:[bp].DPI_docOffset
	add	ax, ds:[di][bx].ETE_size	; bottom of event => AX
	cmp	ax, cx				; my bottom vs document offset
	jl	freeAll				; if not on screen, free all
	push	ds:[di].ETH_temp		; save screen offset
	push	bx				; save table offset
	add	cx, ds:[bp].DPI_viewHeight	; final screen position => CX
	call	CheckScreenPosition		; handle of last event => BX
	cmp	bx, ds:[di].ETH_screenFirst	; compare with first on screen
	pop	ax, bx				; restore screen, table offsets
	jge	midStuffLoop			; if last >= original first

	; Free all the current buffers & re-stuff visible events!
freeAll:
	mov	cl, BufferUpdateFlags <1, 1, 1>	; write back, notify, delete
	call	BufferAllWriteAndFree		; else free all the buffers
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].DayPlan_offset	; access the instance data
	mov	di, ds:[bp].DPI_eventTable	; get the table handle
	mov	di, ds:[di]			; dereference the handle
	mov	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP
	mov	ds:[di].ETH_screenLast, OFF_SCREEN_BOTTOM
	pop	ax, bx				; remove bogus values
	clr	ax				; start at the top of screen
	mov	bx, size EventTableHeader	; start with the first event
	push	ax, bx				; screen & EventTable offset
	jmp	midStuffLoop			; start at boundary check

	; Loop here, allocating & stuffing events as needed
	; DS:BP => DayPlan instance data
	; DS:DI => EventTable
	;    AX => Current screen offset
	;    BX => Current table offset
stuffLoop:
	mov	cx, ds:[bp].DPI_docOffset	; screen offset => CX
	add	ax, ds:[di][bx].ETE_size	; update the current offset
	cmp	ax, cx				; compare with our position
	jl	next				; if less, go the next ETE
	add	cx, ds:[bp].DPI_viewHeight	; bottom offset => CX
	add	cx, ds:[di][bx].ETE_size	; comparing with TOP offset
	cmp	ax, cx				; compare current with bottom
	jge	removeEndBuffers		; if greater, just re-position

	; Yes, on screen.  Need to allocate a buffer (maybe)
	;
	tst	ds:[di][bx].ETE_handle		; is this already filled ??
	jnz	next				; if filled, go to next event
	push	ax				; save the screen position
	call	BufferAllocNoErr		; allocate a buffer
	call	InsertAndStuffEvent		; position & stuff it
	pop	ax				; restore the screen position

	; Go to the next event
next:
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].DayPlan_offset	; access the instance data
	mov	di, ds:[bp].DPI_eventTable	; get the event table handle
	mov	di, ds:[di]			; dereference the handle
	add	bx, size EventTableEntry	; go to next EventTableEntry
midStuffLoop:					; AX & BX MUST BE VALID HERE
	cmp	bx, ds:[di].ETH_last		; any more events ??
	jb	stuffLoop			; yes, continue
	
	; Remove any buffers that my be present between the current position
	; and the ETH_screenLast, iff there is at least one EventTableEntry
	; w/o a buffer.
	;
removeEndBuffers:
	cmp	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP
	je	position			; if no buffers, skip test
	sub	bx, size EventTableEntry
removeLoop:	
	add	bx, size EventTableEntry
	cmp	bx, ds:[di].ETH_screenLast	; check end condition...
	jae	position			; jump if done
	tst	ds:[di][bx].ETE_handle		; buffer present ??
	jnz	removeLoop			; yes, so loop again

	; Else must free all buffers between current & screenLast
	;
	push	si				; save the DayPlan handle
	mov	bp, ds:[di].ETH_screenLast	; last offset for buffers
	mov	ds:[di].ETH_screenLast, bx	; store the new screenLast
	sub	ds:[di].ETH_screenLast, size EventTableEntry
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access the instance data
	mov	di, ds:[si].DPI_eventTable	; get the event table handle
	call	DayPlanRemoveBuffers		; remove a range of buffers
	pop	si				; restore the DayPlan handle

	; Now position the events
position:
EC <	call	DayPlanVerifyEventTable		; ensure valid table	>
	pop	cx, dx				; screen & EventTable offset
	pop	bp				; restore ScreenUpdateFlags
	mov	ax, MSG_DP_POSITION_RANGE
	call	ObjCallInstanceNoLock		; send the method
	mov	cx, dx				; ETE offset back to CX

	; If we're showing the To Do list, we need to 
	; renumber the To Do events
	;
if	_TODO
	push	si
	mov	si, ds:[si]		
	add 	si, ds:[si].DayPlan_offset
	test	ds:[si].DPI_prefFlags, PF_TODO	; To Do mode ?
	pop	si
	jz	continue
	call	RenumberToDoEvents
continue:
endif
	.leave
	ret
DayPlanScreenUpdate	endp

if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RenumberToDoEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Renumbers the To Do list events	

CALLED BY:	DayPlanScreenUpdate

PASS:		ds:*si	= DayPlan object

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,si,bp

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Get Event table
	number = 0
	for each event in event table (events are in sequence)
	  number++
	  send it the correct number (MSG_DE_TODO_NUMBER)
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/18/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RenumberToDoEvents	proc	near
	.enter

	; Get event table
	;
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	mov	bp, ds:[di].DPI_eventTable


	mov	di, ds:[bp]			; deref Event table
	mov	bx, size EventTableHeader	; first ETE => bx
	mov	dx, ds:[di].ETH_last		; end of table => dx
	clr	cx				; 0 => cx
numberLoop:	
	cmp	bx, dx				; are we at end of Event
	jge	done				; Table ?
	inc	cx				; number for this event
	mov	si, ds:[di][bx].ETE_handle	; DayEvent handle => si
	mov	ax, MSG_DE_TODO_NUMBER
	cmp	si,0				; is there a DayEvent ?
	jz	next				; if not don't number it
EC <	Assert	objectPtr, dssi, DayEventClass			>
	call	ObjCallInstanceNoLock		; give event new number
next:
	add	bx, size EventTableEntry
	mov	di, ds:[bp]			; redereference EventTable
	jmp	numberLoop
done:
	.leave
	ret
RenumberToDoEvents	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanRemoveBuffers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Free buffers from the EventTable over the specified range

CALLED BY:	INTERNAL
	
PASS:		DS:*DI	= EventTable
		BX	= Offset to first ETE to delete at
		BP	= Offset to last ETE to delete

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanRemoveBuffers	proc	near
	uses	ax, si
	.enter

	; Some set-up work
	;
	mov	si, ds:[di]			; dereference the table handle
	jmp	middle

	; Loop until all handles deleted
	;
deleteLoop:
	mov	ax, ds:[si][bx].ETE_handle	; buffer handle => AX
	tst	ax				; valid handle ??
	jz	next				; no, so go to next ETE
	call	BufferFree			; else free the buffer
	mov	si, ds:[di]			; re-dereference the table
next:
	add	bx, size EventTableEntry	; go to the next entry
middle:
	cmp	bx, bp
	jbe	deleteLoop

	.leave
	ret
DayPlanRemoveBuffers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckScreenPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the first buffer whose position exceeds the passed
		screen offset

CALLED BY:	DayPlanScreenUpdate

PASS:		DS:DI	= EventTable
		BX	= Offset in the EventTable with which to begin
		AX	= Initial screen offset
		CX	= Limit screen offset

RETURN:		BX	= Offset in the EventTable
		AX	= End offset of this Event

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckScreenPosition	proc	near
	.enter

	jmp	midLoop				; start at bounds check
positionLoop:
	add	ax, ds:[di][bx].ETE_size	; update the screen offset
	cmp	ax, cx				; compare screen positions
	jge	done
	add	bx, size EventTableEntry	; go to the next entry
midLoop:
	cmp	bx, ds:[di].ETH_last		; end of table ??
	jb	positionLoop			; loop if smaller
done:
	.leave
	ret
CheckScreenPosition	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InsertAndStuffEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert event into visual tree, and stuff the event

CALLED BY: 	DayPlanScreenInsert

PASS:		DS:*SI	= DayPlan instance data
		AX	= DayEvent buffer
		BX	= Offset to new EventTableEntry

RETURN:		Nothing

DESTROYED:	DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/18/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InsertAndStuffEvent	proc	near
	class	DayPlanClass
	uses	bx, cx, dx
	.enter

	; Some set up work
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access the instance data
	mov	di, ds:[di].DPI_eventTable	; get the table handle
	mov	di, ds:[di]			; dereference the handle
	mov	ds:[di][bx].ETE_handle, ax	; store the handle
	mov	cx, bx

	; Update the header
	;
	cmp	bx, ds:[di].ETH_screenFirst	; compare new offset with first
	jae	last				; jump if larger or equal
	mov	ds:[di].ETH_screenFirst, bx
last:
	cmp	bx, ds:[di].ETH_screenLast	; compare new offset with last
	jbe	continue			; jump if less or equal
	mov	ds:[di].ETH_screenLast, bx

	; Three case (True first, first in window, other)
continue:
	mov	bp, ICO_FIRST			; assume we're 1st visual child
	cmp	bx, size EventTableHeader	; are we absolute first ??
	je	stuff				; yes, jump
	sub	bx, size EventTableEntry	; else look at previous
	mov	dx, ds:[di][bx].ETE_handle	; get the handle
	tst	dx				; is it zero ??
	je	stuff				; jump - first in window
	mov	bp, ICO_AFTER_REFERENCE		; else visually add after

	; Now stuff and leave
stuff:
	add	di, cx				; go to correct ETE
	call	StuffDayEvent			; stuff all the values in

	.leave
	ret
InsertAndStuffEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanScreenScroll
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to the scrolling work

CALLED BY:	UI (MSG_META_CONTENT_TRACK_SCROLLING)

PASS:		DS:*SI	= DayPlan instance data
		DX	= size NormalPositionArgs
		CX	= Scrollbar handle
		SS:BP	= TrackScrollingParams

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:
		Only scrolls vertically (ignores any horizontal scrolling)

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/15/89	Initial version
	Don	4/4/90		Major changes (simplification)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanScreenScroll	method	DayPlanClass,	MSG_META_CONTENT_TRACK_SCROLLING
	
	; Now see if we need to scroll at all.  If so, which direction??
	;
	call	GenSetupTrackingArgs		; set up some extra values
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my data
	mov	dx, ss:[bp].TSP_newOrigin.PD_y.low ; new document offset => DX
	xchg	dx, ds:[di].DPI_docOffset	; get new value; reset it also
	cmp	ds:[di].DPI_docOffset, dx	; compare the offsets
	je	ReturnCall			; if equal, do nothing

	; Else store the new offset and request a screen update
	;
	push	cx, bp				; save the scrollbar handle
	mov	dl, SUF_STEAL_FROM_TOP		; assume scrolling down
	jg	continue			; new greater than old ??
	mov	dl, SUF_STEAL_FROM_BOTTOM	; actually scrolling up
continue:
	mov	cx, ds:[di].DPI_docOffset	; offset => CX
	mov	bx, size EventTableHeader	; assume the worst
	test	ds:[di].DPI_flags, DP_FILE_VALID
	jz	update				; if no valid file, jump
	call	DayPlanSearchByPosition		; else search for the position
update:
	mov	cx, bx				; EventTable offset => CX
	or	dl, SUF_NO_REDRAW		; don't re-draw the DayPlan
	mov	ax, MSG_DP_SCREEN_UPDATE	; update the screen
	call	ObjCallInstanceNoLock		; send the method

	; Make the return call
	;
	pop	cx, bp				; chunk handle to CX
ReturnCall:
	call	GenReturnTrackingArgs		; return arguments
	ret
DayPlanScreenScroll	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanScrollIntoSubview
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Forces a scroll into subview to occur, delayed via the queue
		from a MyText object to enure the DP's height is correct.

CALLED BY:	MyTextShowSelection (MSG_DP_SCROLL_INTO_SUBVIEW)
	
PASS:		DS:SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
		SS:BP	= MakeRectVisibleParams
		DX	= # of bytes on the stack
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanScrollIntoSubview	method	DayPlanClass,
					MSG_DP_SCROLL_INTO_SUBVIEW

	mov	ax, MSG_GEN_VIEW_MAKE_RECT_VISIBLE
	mov	di, mask MF_STACK
	GOTO	MessageToEventView
DayPlanScrollIntoSubview	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffDayEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff a DayEvent with the database data

CALLED BY:	GLOBAL

PASS:		AX	= DayEvent handle
		DX	= Object to insert after if BP != ICO_LAST
			= or DO_NOT_INSERT_VALUE to not insert into a tree
		BP	= InsertChildFlags (or none to not insert into tree)
		DS:DI	= Event table entry

RETURN:		Nothing

DESTROYED:	DI

PSEUDO CODE/STRATEGY:
		Must initialize the DayEvent
		Must position the DayEvent
		Insert the DayEvent

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/5/89		Initial version
	SS	3/19/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DO_NOT_INSERT_VALUE	= 0xffff	; reference child value to not add
					; DayEvent into the visual tree

StuffDayEvent	proc	far
	class	DayPlanClass
	uses	ax, bx, cx, dx, si
	.enter

	; Some set-up work
	;
	push	dx, bp				; save precede object, CCFlags
EC <	tst	ax							>
EC <	ERROR_Z	DP_STUFF_DAY_EVENT_BAD_HANDLE				>

	; Initialize the event
	;
	mov	cx, ds:[di].ETE_group		; DBGroup => CX
	mov	dx, ds:[di].ETE_item		; DBItem => DX
	mov	si, ax				; DayEvent handle => SI
	tst	cx				; no group number ??
	je	virgin
	test	cx, REPEAT_MASK			; a repeat event ??
	jne	repeat

	; Handle the regular case:
	;
	mov	ax, MSG_DE_INIT		; method to call
	jmp	initialize			; initialize

	; Handle the repeat case
repeat:
	mov	cx, di
	mov	si, offset DPResource:DayPlanObject
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	mov	di, ds:[di].DPI_eventTable
	sub	cx, ds:[di]			; true offset to CX
	mov	dx, di				; table handle to DX
	mov	si, ax				; DayEvent handle to SI
	mov	ax, MSG_DE_INIT_REPEAT
	jmp	initialize

	; Initialize the virgin event
virgin:
if	_TODO					; a virgin "To Do" event?
	mov	ax, MSG_DE_INIT_TODO
	push	si, di				; if so, initialize it as
	mov	si, offset DPResource:DayPlanObject
	mov	di, ds:[si]			; a "To Do" event
	add	di, ds:[di].DayPlan_offset
	test	ds:[di].DPI_prefFlags, PF_TODO
	pop	si, di
	jnz	contVirgin
endif
	mov	ax, MSG_DE_INIT_VIRGIN	; assume not a header
	tst	dx				; check the item #
	je	contVirgin			; if zero, not a header event
	mov	ax, MSG_DE_INIT_HEADER	; else we have a header
contVirgin:
	mov	bp, ds:[di].ETE_year
	mov	dx, {word} ds:[di].ETE_day
	mov	cx, {word} ds:[di].ETE_minute

	; Now make the call
initialize:
	call	ObjCallInstanceNoLock		; method must be in AX

	; Insert event into the visible tree
	;
	mov	cx, ds:[LMBH_handle]
	mov	dx, si				; object to add (new)
	mov	ax, cx
	pop	bp				; CompChildFlags	
	pop	bx				; reference object
	mov	si, offset DPResource:DayPlanObject
	cmp	bx, DO_NOT_INSERT_VALUE		; should we not insert
	je	done				; then don't insert
	call	VisInsertChild
done:
	.leave
	ret
StuffDayEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPositionRange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position a range (1 or more) or DayEvents

CALLED BY:	GLOBAL (MSG_DP_POSITION_RANGE)

PASS:		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
		DS:BX	= Dereferenced handle
		ES	= DGroup
		CX	= Y position of first object
		DX	= Offset in the EventTable to start at (an ETE)
		BP	= ScreenUpdateFlags
				SUF_NO_REDRAW
				SUF_NO_INVALIDATE

RETURN:		Nothing

DESTROYED:	AX, BX, CX, SI, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/15/89	Initial version
	Don	6/18/90		Somewhat optimized
	Don	9/4/90		Fixed off-by-one bug in window width

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

; Must leave room for an icon to get drawn, else we 
; may go outside of the graphics bounds!!
if	ERROR_CHECK
	DP_MAX_COORD	= 2000h
else
	DP_MAX_COORD	= MAX_COORD - (ICON_Y_OFFSET - ICON_HEIGHT)
endif

DayPlanPositionRange	method	DayPlanClass,	MSG_DP_POSITION_RANGE
	uses	dx
	.enter

	; Some set-up work
	;
	mov	bx, bp				; flag => BX
	sub	sp, size PositionStruct
	mov	bp, sp
	push	cx, bx, si			; save the draw flag, handle
	mov	ax, ds:[di].DPI_viewWidth	; set up the Position struct
	mov	ss:[bp].PS_totalWidth, ax	; store right position
	mov	ax, ds:[di].DPI_textHeight	;
	mov	ss:[bp].PS_timeHeight, ax	;
	mov	ss:[bp].PS_timeLeft, EVENT_TIME_OFFSET

	; If we're showing events in narrow mode, we don't show icons.
	; Therefore, EVENT_TIME_OFFSET = 0 (Responder only)
	;

	; Set up the loop
	;
	mov	ax, ds:[di].DPI_docOffset	; top of the screen
	add	ax, ds:[di].DPI_viewHeight	; ending offset => AX
	mov	di, ds:[di].DPI_eventTable	; access the event table
	mov	bx, dx				; offset to begin at
	jmp	midLoop				; start position loop

	; We ran out of screen space. Must remove all of the buffers
	; below the current one, and reset the current to be the bottom
	; of the screen.
	;
outOfSpace:
	mov	si, ds:[di]			; derference the EventTable
	mov	ds:[si].ETH_screenLast, bx	; this buffer is now the last
	add	bx, size EventTableEntry	; go to the next ETE
	mov	bp, ds:[si].ETH_last		; last offset => BP
	sub	bp, size EventTableEntry	; point to start of last ETE
	call	DayPlanRemoveBuffers		; nuke buffers [BX, BP]
	jmp	update				; continue update process

	; Loop while we find DayEvents (proceed until end of the table)
sizeLoop:
	mov	dx, ds:[si][bx].ETE_size	; Event height => DX
	mov	si, ds:[si][bx].ETE_handle	; DayEvent handle => SI
	tst	si				; look for no handle
	jz	next				; if none, go to next handle
	call	PositionDayEvent		; else position the event
	jc	outOfSpace			; position failed -> abort!
next:
	add	cx, dx				; update the screen offset
	add	bx, size EventTableEntry	; go to the next entry
midLoop:
	mov	si, ds:[di]			; derference the EventTable
	cmp	bx, ds:[si].ETH_last		; are we done yet ??
	jb	sizeLoop			; go through the entire table

	; Reset my geometry
update:
EC <	call	DayPlanVerifyEventTable		; ensure valid table	>
	pop	si				; DayPlan chunk => SI

	; Resize if necessary
	;
	mov	di, ds:[si]			; dereference the handle
	mov	bp, di				; also => BP
	add	di, ds:[di].DayPlan_offset	; access my DayPlan data
	add	bp, ds:[bp].Vis_offset		; access my visual data
	and	ds:[bp].VI_optFlags, not (mask VOF_GEO_UPDATE_PATH)
	mov	cx, ds:[di].DPI_viewWidth	; new width => CX
	mov	dx, ds:[di].DPI_docHeight	; new height => DX
	mov	bx, ds:[bp].VI_bounds.R_bottom
	sub	bx, ds:[bp].VI_bounds.R_top
	inc	bx				; old height => BX
	cmp	dx, bx				; compare old/new heights
	jne	resize
	mov	ax, ds:[bp].VI_bounds.R_right
	sub	ax, ds:[bp].VI_bounds.R_left
	inc	ax				; width => AX
	cmp	cx, ax
	je	updateOnly
resize:

	; No bound on document size for Responder.  We have a hard
	; limit on the number of events instead.
	;
	cmp	dx, DP_MAX_COORD		; check for large value
	jbe	resizeNow			; OK, so jump
	mov	dx, DP_MAX_COORD		; else put in the maximum value
	call	DayPlanDisplayTooBigError	; display the error!
resizeNow:

	or	ds:[bp].VI_optFlags, (mask VOF_GEO_UPDATE_PATH)
	call	VisSetSize			; set the document size

	; Now update the children's geometry flags & possibly the image
	;
updateOnly:
	pop	dx				; ScreenUpdateFlags => DL
	pop	bx				; restore screen position
	mov	dh, dl				; ScreenUpdateFlags => DH
	test	dh, SUF_NO_INVALIDATE		; don't invalidate ??
	jnz	done
	mov	cl, mask VOF_WINDOW_INVALID	; force children update
	mov	dl, VUM_NOW
	call	VisMarkInvalid
	test	dh, SUF_NO_REDRAW		; don't redraw (one pending)
	jnz	done				; if set, don't redraw

	; Attempt to setup a clip region, to prevent unecessary redraws
	;
	call	VisQueryWindow			; get our window => DI
	tst	di				; a valid window ??
	jz	done				; no, so do nothing

	; We need a gstate, so let's VUP for it

	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	call	ObjCallInstanceNoLock
	mov	di, bp

	; load up the bounds of what we want to invalidate

	clr	ax				; left boundary
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].Vis_offset		; access my visual data
	mov	cx, ds:[bp].VI_bounds.R_right	; right boundary
	mov	bp, ds:[si]
	add	bp, ds:[bp].DayPlan_offset
	mov	dx, ds:[bp].DPI_docOffset
	add	dx, ds:[bp].DPI_viewHeight
	inc	dx				; bottom boundary => DX
	call	GrInvalRect
	call	GrDestroyState			; get rid of VUP_CREATED GState
done:
	add	sp, size PositionStruct		; restore the stack

	.leave
	ret
DayPlanPositionRange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionDayEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the DayEvent

CALLED BY:	DayPlanPositionRange

PASS:		DS:*SI	= DayEvent instance data
		SS:BP	= PositionStruct
		ES	= DGroup
		CX	= Y document position
		DX	= DayEvent height

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Position the composite
		Position the event time
		Position the event text

		|----------Window width----------|
		|_______________________________ |
		|----------Event width----------||
		|icon|-time-|--------text-------||
		|___________|___________________||

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		For DayEvent "headers", we do not want to see the time.
		Hence, we put the time TextObj off the screen.

		It is VERY important that the width of the event here
		EXACTLY match the width that was provided when the length
		of the event text was calculated. If these widths are not
		equal, the DayPlan code will die!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/5/89		Initial version
	Don	12/13/89	Added the header check
	Don	9/4/90		Fixed off-by-one bug in positioning
	sean	3/19/95		Changes to position To Do list events
				correctly
	sean	8/9/95		Changes to correctly position end times

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

	; The event window is getting too long, so tell the user
eventsTooLong:
	call	DayPlanDisplayTooBigError
	mov	dx, DP_MAX_COORD		; reset the bottom boundary
	jmp	doneCheck			; we're done

PositionDayEvent	proc	far
	class	VisClass
	uses	ax, bx, cx, dx, di, si
	.enter

	; First position the composite
	;
	mov	di, ds:[si]			; dereference the handle
	mov	bx, di
	add	bx, ds:[bx].DayEvent_offset
	mov	al, ds:[bx].DEI_stateFlags	; flags to AL
	mov	ss:[bp].PS_flags, al		; store in the structure
	mov	al, ds:[bx].DEI_timeHour	; time's hour => AL
	mov	ss:[bp].PS_hour, al		; store in the structure
	add	di, ds:[di].Vis_offset		; access visual bounds

	; Set up the registers:
	;   AX => left
	;   BX => right
	;   CX => top
	;   DX => bottom
	add	dx, cx				; bottom => DX

	; For Responder, we don't have a bound on the document
	; size.  We have a bound on the number of events.
	;
EC <	cmp	cx, DP_MAX_COORD		; too big ??		>
EC <	ERROR_G	DP_TEST_IN_BOUNDS_TOP_SHOULD_ALWAYS_FIT			>
	cmp	dx, DP_MAX_COORD		; bottom too big ??
	ja	eventsTooLong			; yes, so tell user

	clc					; else clear the carry

doneCheck	label 	near

	pushf					; save the carry flag
	push	ds:[bx].DEI_textHandle
	push	ds:[bx].DEI_timeHandle
	clr	ax				; left => AX
	mov	bx, ss:[bp].PS_totalWidth	; screen width => BX

	; Position the composite first
	;
	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_right, bx
	mov	ds:[di].VI_bounds.R_top, cx
	mov	ds:[di].VI_bounds.R_bottom, dx
	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)

	; Now position the event time object
	;
	pop	si				; restore the time handle
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Vis_offset		; access visual data
	push	bx, dx				; save the bottom & right
	add	ax, ss:[bp].PS_timeLeft		; adjust the left boundary
	mov	dx, cx
	add	dx, ss:[bp].PS_timeHeight	; new bottom => DX
	test	ss:[bp].PS_flags, mask EIF_HEADER 
	jnz	finishPositionTime
	mov	bx, ax
	add	bx, es:[timeWidth]		; right boundary => BX

	; For Responder, we need to see 1) if we're showing events in
	; "narrow" mode, and 2) if this event has an end time.  If
	; we're in "wide" mode with an end time, then the time object
	; must be made wider to accomodate the end time.
	;
finishPositionTime:
if	_TODO
	or	ds:[di].VI_attrs, mask VA_DETECTABLE
	test	ss:[bp].PS_flags, mask EIF_TODO
	jz	continue			; if not todo it's detectable
	and	ds:[di].VI_attrs, not (mask VA_DETECTABLE)
	mov	bx, ax				
	add	bx, TODO_NUMBER_WIDTH		
continue:
endif
	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_right, bx
	mov	ds:[di].VI_bounds.R_top, cx
	mov	ds:[di].VI_bounds.R_bottom, dx

	; This "optimization" breaks the ability to right-justify the time
	; text, so it was removed. I have no idea as to the performance
	; gain it offers - but it no longer seems necessary. -Don 9/30/99
	;
;;;	clr	ds:[di].VTI_leftOffset		; one-line text optimization

	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)
	push	bx
	push	cx, bp				; save the bounds info
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	ObjCallInstanceNoLock		; notify the text object
	pop	cx, bp				; restore bounds (right=>left)
	pop	ax
	inc	ax				; move left over by one pixel
	pop	bx, dx				; restore right & bottom
	
	; Now position the event text object
	;
	pop	si				; restore the event handle
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Vis_offset		; access visual data
	test	es:[systemStatus], SF_PRINT_MONTH_EVENTS
	jz	headerCheck			; if not printing, ignore
	clr	ax				; else left bounds always 0
headerCheck:
	or	ds:[di].VI_attrs, (mask VA_DRAWABLE or mask VA_DETECTABLE)
	test	ss:[bp].PS_flags, mask EIF_HEADER 
	jz	normalText			; if not a header, jump
	and	ds:[di].VI_attrs, not (mask VA_DRAWABLE or mask VA_DETECTABLE)
normalText:
	mov	ds:[di].VI_bounds.R_left, ax
	mov	ds:[di].VI_bounds.R_right, bx
	mov	ds:[di].VI_bounds.R_top, cx
	mov	ds:[di].VI_bounds.R_bottom, dx
	and	ds:[di].VI_optFlags, not (mask VOF_GEOMETRY_INVALID or \
					  mask VOF_GEO_UPDATE_PATH)
	mov	ax, MSG_VIS_NOTIFY_GEOMETRY_VALID
	call	ObjCallInstanceNoLock

	popf					; restore the carry flag

	.leave
	ret
PositionDayEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanDisplayTooBigError
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Displays the "document too large error" box.

CALLED BY:	INTERNAL
	
PASS:		ES	= DGroup

RETURN:		Carry	= Set

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Will only display error iff the SF_DOC_TOO_BIG_ERROR flag
		is clear, and sets this flag after displaying the message.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanDisplayTooBigError	proc	near
	uses	ax, bx, di, bp
	.enter

	test	es:[systemStatus], SF_DOC_TOO_BIG_ERROR
	jnz	done
	or	es:[systemStatus], SF_DOC_TOO_BIG_ERROR

	call	GeodeGetProcessHandle		; process handle => BX
	mov	bp, CAL_ERROR_DOC_TOO_LARGE	; error to display
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	call	ObjMessage_dayplan_send		; send the method
done:
	stc					; bad size return flag

	.leave
	ret
DayPlanDisplayTooBigError	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanChangePreferences
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force the DayPlan to reload its information

CALLED BY:	DayPlan preference routines

PASS:		DS:DI	= DayPlanClass specific instance data
		CX	= Start day minute/hour
		DX	= End day minute/hour
		BP	= (High) interval between events
		BP	= (Low) DayPlanInfoFlags (modified)

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanChangePreferences method	DayPlanClass,	MSG_DP_CHANGE_PREFERENCES

	; Tell year object to "zoom" on the selected day(s)
	;
	mov	dh, ds:[di].DPI_prefFlags	; preference flags => DH
	mov	dl, dh				; also to DL
	and	ds:[di].DPI_prefFlags, not (PF_SINGLE or PF_RANGE or PF_GLOBAL)
	and	dh, (DP_HEADERS or DP_TEMPLATE)	; only real flags
	and	ds:[di].DPI_flags, not (DP_HEADERS or DP_TEMPLATE)
	or	ds:[di].DPI_flags, dh		; store new flags
	mov	dh, PF_SINGLE			; assume one day displayed
	cmp	ds:[di].DPI_rangeLength, 1	; range length, please
	je	needToChange
	mov	dh, PF_RANGE

	; Check if we need to change the Event Window display
	;
needToChange:
	test	dl, dh				; is the flag set ??
	jz	checkGlobal			; no - just check for globals
	or	ds:[di].DPI_flags, DP_RELOAD or DP_DIRTY
	mov	ax, MSG_DP_SET_RANGE
	call	ObjCallInstanceNoLock

	; Check if globals have changes:
	;
checkGlobal:
	test	dl, PF_GLOBAL			; global changes ??
	jz	done				; none - so leave
	or	es:[showFlags], mask SF_SHOW_TODAY_ON_RELAUNCH or \
				mask SF_SHOW_NEW_DAY_ON_DATE_CHANGE
	test	dl, PF_ALWAYS_TODAY
	jnz	checkDateChange
	and	es:[showFlags], not (mask SF_SHOW_TODAY_ON_RELAUNCH)
checkDateChange:
	test	dl, PF_DATE_CHANGE
	jnz	done
	and	es:[showFlags], not (mask SF_SHOW_NEW_DAY_ON_DATE_CHANGE)
done:
	ret
DayPlanChangePreferences	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo an action

CALLED BY:	UI (MSG_DP_UNDO)

PASS:		DS:DI	= DayPlan instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanUndo	method	DayPlanClass,	MSG_DP_UNDO
	.enter

	; Find this event's group & item
	;
	mov	bp, ds:[di].DPI_selectEvent	; DayEvent buffer handle => BP
	call	DayPlanSearchByBuffer		; search for the event
EC <	ERROR_NC	DP_UNDO_COULD_NOT_FIND_SELECT_EVENT		>
	mov	di, ds:[di]			; dereference the table handle
	mov	cx, ds:[di][bx].ETE_group	; group # => CX
	mov	dx, ds:[di][bx].ETE_item	; item # => DX

	; Perform the undo action
	;
	call	GeodeGetProcessHandle		; get this process' handle
	mov	ax, MSG_CALENDAR_UNDO	; method to send
	call	ObjMessage_dayplan_call
	
	.leave
	ret
DayPlanUndo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanQuickAdd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an empty event to the current day plan

CALLED BY:	UI (MSG_DP_QUICK_ADD)

PASS:		DS:*SI	= DayPlan instance data
		DS:DI	= DayPlan specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:
		Must loop once through queue, to ensure that any previous
		Quick Add's are complete (scrolling might have occurred)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/15/89	Initial version
	Don	4/21/90		Now adds event after current event
	Don	7/11/90		Added loop mechanism

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanQuickAdd	method	DayPlanClass, MSG_DP_QUICK_ADD

	; See if the current event's time is valid
	;
	mov	ax, MSG_DP_ENSURE_EVENTS_VISIBLE
	call	ObjCallInstanceNoLock
	mov	ax, MSG_DP_GET_SELECT		; get the selected event
	call	ObjCallInstanceNoLock		; DayEvent => BP
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	mov	cx, {word} ds:[di].DPI_beginMinute  ; first Hour/Minute => CX
	tst	bp				; is there a selected event ??
	jz	addFirst			; no, add the first event
	push	si
	mov	si, bp
	mov	ax, MSG_DE_UPDATE_TIME
	call	ObjCallInstanceNoLock
	mov	bp, si
	pop	si
	jc	exit				; if error, don't add event

	; Update the event time (if necessary)
	;
	mov	ax, MSG_DP_UPDATE_ALL_EVENTS	; cuase any times being edited
	call	ObjCallInstanceNoLock		; ...to be updated now!

	; Get the event's time & date
	;
	call	DayPlanSearchByBuffer		; look for the buffer
EC <	ERROR_NC	DP_QUICK_ADD_SELECT_EVENT_NOT_FOUND		>
	mov	di, ds:[di]			; dereference the EventTable
	mov	bp, ds:[di][bx].ETE_year
	mov	dx, {word} ds:[di][bx].ETE_day
	cmp	ds:[di][bx].ETE_item, 1		; is this a header event ??
	je	common				; then add at the time in CX
	mov	cx, {word} ds:[di][bx].ETE_minute
	cmp	cx, -1				; is this time empty ??
	je	common				; yes, make the new one also!
	cmp	bx, ds:[di].ETH_last		; are we past the last entry ?
	je	common				; if so, no average time
	add	bx, size EventTableEntry	; else go to the next event
	cmp	bp, ds:[di][bx].ETE_year
	jne	common				; if years equal, do nothing...
	cmp	dx, {word} ds:[di][bx].ETE_day
	jne	common				; if day/month not equal, jmp
	mov	ax, {word} ds:[di][bx].ETE_minute	; else next time => AX
	cmp	ax, cx				; if next hour/minute is before
	jl	common				; ...current time, use current
	call	CalcAverageTime			; calculate the average time
	jmp	common

	; Else add an event to the top
addFirst:
	mov	dx, {word} ds:[di].DPI_startDay	; Month/Day => DX
	mov	bp, ds:[di].DPI_startYear	; Year => BP

	; Quickly add an event to the DayPlan
common:
	mov	ax, MSG_DP_NEW_EVENT		; add a new event
	call	ObjCallInstanceNoLock
exit:
	ret
DayPlanQuickAdd	endp

if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DPNewTodoEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a new To Do list event, making sure the To Do
		list is shown.

CALLED BY:	MSG_DP_NEW_TODO_EVENT

PASS:		*ds:si	= DayPlanClass object
		ds:di	= DayPlanClass instance data
		ds:bx	= DayPlanClass object (same as *ds:si)
		es 	= segment of DayPlanClass
		ax	= message #

RETURN:		nothing

DESTROYED:	ax,cx,dx,bp

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	3/ 9/95   	Initial version
	sean	9/1/95		Changes to allow an alarm event to
				be added to the To-do list with this message
	sean	10/27/95	Simplified immensely

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DPNewTodoEvent	method dynamic DayPlanClass, 
					MSG_DP_NEW_TODO_EVENT
	.enter	
	
	; Must be showing DayPlan in To-do mode.
	; 
EC <	cmp	es:[viewInfo], VT_TODO				>
EC <	ERROR_NE	WRONG_VIEW_FOR_NEW_TO_DO_ITEM		>

	; Create new event w/ To Do event values.
	;
	mov	ax, MSG_DP_NEW_EVENT
	mov	bp, TODO_DUMMY_YEAR
	mov	dx, TODO_DUMMY_MONTH_DAY
	mov	ch, TODO_DUMMY_HOUR
	mov	cl, TODO_NORMAL_PRIORITY		; priority in minute
	call	ObjCallInstanceNoLock

	; New event created, and we only want one new To-do item
	; available at any time, so turn off "New" trigger.
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	call	ChangeToDoNewTrigger

	.leave
	ret

DPNewTodoEvent	endm

endif		; if	_TODO



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanEnsureEventsVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure the events window is made visible

CALLED BY:	GLOBAL (MSG_DP_ENSURE_EVENTS_VISIBLE)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanEnsureEventsVisible	method dynamic	DayPlanClass,
						MSG_DP_ENSURE_EVENTS_VISIBLE
	.enter
	
	; If we have the additional view of a To Do list we 
	; must do things differentely
	;
if	_TODO
	call	CheckView
else
	; First ensure the right hand side is visible
	;
	GetResourceHandleNS	MenuBlock, bx
	test	es:[viewInfo], VT_CALENDAR
	jz	checkInk
	mov	si, offset MenuBlock:ViewViewList
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cx, VT_EVENTS
	clr	dx
	call	ObjMessage_dayplan_send
	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, 1				; mark as modified
	call	ObjMessage_dayplan_send
	mov	ax, MSG_GEN_APPLY
	call	ObjMessage_dayplan_send

	; Now ensure the EventView is visible
checkInk:
	test	es:[viewInfo], mask VI_INK
	jz	done
if _USE_INK
	mov	si, offset MenuBlock:ViewInkList
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	cx, dx
	call	ObjMessage_dayplan_send
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	mov	cx, mask VI_INK
	call	ObjMessage_dayplan_send
	mov	ax, MSG_GEN_APPLY
	call	ObjMessage_dayplan_send
endif		; if	_USE_INK
done:	
endif		; if	_TODO
	.leave
	ret
DayPlanEnsureEventsVisible	endm

if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine needed if we are using the To Do list, to
		ensure the correct view is shown when we
		press the "New Event" button.	

CALLED BY:	DayPlanEnsureEventsVisible

PASS:		es	= dgroup
		bx 	= MenuBlock

RETURN:		zeroFlag - clear if we want to pop up the Event window
		zeroFlag - set if we don't want to pop up Event window
 
DESTROYED:	ax,cx,dx,si	

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SS	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckView	proc	near
	.enter

	; Check what type of view we are showing currently
	; 
	mov	dl, es:[viewInfo]
	and	dl, mask VI_TYPE
	; clr	dh
	; mov	cx,dx
	; call 	ToDoGrabFocusAndTarget
	cmp	dl, VT_EVENTS				; event view ?
	je	done
	cmp	dl, VT_CALENDAR_AND_EVENTS		; Calendar/Event view ?
	je	done					; don't change view
	cmp	dl, VT_TODO				; To Do list view ?
	mov	cx, VT_EVENTS shl offset VI_TYPE
	je	eventView				; Show event view
	mov	cx, VT_CALENDAR_AND_EVENTS shl offset VI_TYPE
	cmp	dl, VT_CALENDAR_AND_TODO_LIST		; Calendar/To Do ?
	je	eventView				; Show Calendar/Events
	
	; Must be Calendar view
	;
	push	si					; Save DayPlan
	mov	ax, MSG_GEN_SET_USABLE
	GetResourceHandleNS	CalendarRight, bx	; Show CalendarRight
	mov	si,	offset  CalendarRight
	clr	di
	call	ObjMessage
	pop	si					; restore DayPlan

eventView:
	; Update viewInfo global
	;
	and	es:[viewInfo], not (mask VI_TYPE)
	or	es:[viewInfo], cl

	; Change view menu button
	;
	push	si					; save DayPlan
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	GetResourceHandleNS	MenuBlock, bx
	mov	si, offset MenuBlock:ViewViewList
	clr	dx					; not indeterminate
	clr 	di
	call	ObjMessage
	pop	si					; restore DayPlan
	
	; Make sure DayPlan is in "Event" mode
	;
	mov	ax, MSG_DP_EVENT_VIEW		
	call	ObjCallInstanceNoLock

	; Give focus and target to EventView
	;
	GetResourceHandleNS	EventView, bx
	mov	si, offset 	EventView
	
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	clr	di
	call	ObjMessage

	mov	ax, MSG_META_GRAB_TARGET_EXCL
	clr	di
	call	ObjMessage
done:
	.leave
	ret
CheckView	endp
endif	; if	_TODO





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalcAverageTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes the average of two times (always rounds down)

CALLED BY:	GLOBAL
	
PASS:		CX	= Hours:Minutes
		AX	= Hours:Minutes

RETURN:		CX:	= Average - Hours:Minutes

DESTROYED:	BX

PSEUDO CODE/STRATEGY:
		Assumes that CX is not -1 (the emtpy time)
		If AX is -1, then CX is unchanged

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalcAverageTime	proc	near
	.enter

	; Turn AX into minutes
	;
	cmp	ax, -1				; is the last time empty ??
	je	done				; if so, perfrom no average
	mov	bh, 60				; divisor & multiplicand
	mov	bl, al				; store the inital minutes
	mov	al, ah				; hours => AL
	clr	ah
	mul	bh				; compute minutes
	clr	bh
	add	ax, bx				; total minutes => AX
	xchg	cx, ax
	
	; Turn CX into minutes
	;
	mov	bh, 60				; divisor & multiplicand
	mov	bl, al				; store the inital minutes
	mov	al, ah				; hours => AL
	clr	ah
	mul	bh				; compute minutes
	clr	bh
	add	ax, bx				; total minutes => AX
	add	ax, cx				; total minutes => AX
	shr	ax, 1				; take the average
	jnc	makeTime
	inc	ax				; always round up

	; Turn minutes into hours:minutes
makeTime:
	mov	bl, 60
	div	bl				; perform the division
	mov	ch, al				; hours => CH
	mov	cl, ah				; minutes => CL
done:
	.leave
	ret
CalcAverageTime	endp

ObjMessage_dayplan_send	proc	near
	clr	di
	GOTO	ObjMessage_dayplan
ObjMessage_dayplan_send	endp

ObjMessage_dayplan_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	FALL_THRU	ObjMessage_dayplan
ObjMessage_dayplan_call	endp

ObjMessage_dayplan	proc	near
	call	ObjMessage
	ret
ObjMessage_dayplan	endp

MessageToYearObject	proc	near
	GetResourceHandleNS	YearObject, bx
	mov	si, offset YearObject
	GOTO	ObjMessage_dayplan
MessageToYearObject	endp

MessageToEventView	proc	far
	GetResourceHandleNS	EventView, bx
	mov	si, offset EventView		; view OD => BX:SI
	GOTO	ObjMessage
MessageToEventView	endp

DayPlanCode	ends



ReminderCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanAlarmSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Brings up the Alarm Settings box for the selected DayEvent

CALLED BY:	UI (MSG_DP_ALARM_SETTINGS)
	
PASS:		DS:DI	= DayPlanClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/3/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanAlarmSettings	method	DayPlanClass,	MSG_DP_ALARM_SETTINGS
	.enter

	mov	si, ds:[di].DPI_selectEvent	; selected event => SI
	tst	si				; is there one ??
	jz	done
	mov	ax, MSG_DE_UPDATE		; force an update, please
	mov	cl, DBUF_IF_NECESSARY
	call	ObjCallInstanceNoLock
	mov	ax, MSG_DE_STUFF_ALARM		; stuff the alarm...
	call	ObjCallInstanceNoLock		; and put it on the screen
done:
	.leave
	ret
DayPlanAlarmSettings	endp



ReminderCode	ends



if _USE_INK
InkCode		segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCleanInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the current ink from the screen.

CALLED BY:	GLOBAL (MSG_DP_CLEAN_INK)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanCleanInk	method dynamic	DayPlanClass, MSG_DP_CLEAN_INK
		uses	cx, dx, bp
		.enter

		; Clean all the ink off of the page
		;
		clr	ds:[di].DPI_inkGroup
		clr	ds:[di].DPI_inkItem
		and	ds:[di].DPI_inkFlags, mask DPIF_INK_DIRTY
		mov	si, offset DPResource:InkObject

;	Clear out the ink data, and mark the object as clean.

		sub	sp, size InkDBFrame
		mov	bp, sp
		clr	ss:[bp].IDBF_VMFile
		clrdw	ss:[bp].IDBF_DBGroupAndItem
		clr	ss:[bp].IDBF_bounds.R_left
		clr	ss:[bp].IDBF_bounds.R_top
		mov	ax, MSG_INK_LOAD_FROM_DB_ITEM
		call	ObjCallInstanceNoLock
		add	sp, size InkDBFrame

		.leave
		ret
DayPlanCleanInk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanLInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load data into the ink object

CALLED BY:	GLOBAL (MSG_DP_LOAD_INK)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance
		SS:BP	= EventTableEntry

RETURN:		CX	= Offset to insertion point (bougs)
		Carry	= Clear (continue loading events)

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanLoadInk	method dynamic	DayPlanClass, MSG_DP_LOAD_INK
		uses	dx, bp
		.enter

		; First see if we have the correct day
		;
		mov	ax, {word} ss:[bp].ETE_day
		cmp	ax, {word} ds:[di].DPI_startDay
		jne	done
		mov	ax, ss:[bp].ETE_year
		cmp	ax, ds:[di].DPI_startYear
		jne	done

		; We have the correct day. Load the ink
		;
		mov	bx, bp			; EventTableEntry => SS:BX
		mov	dx, size InkDBFrame
		sub	sp, dx
		mov	bp, sp			; InkDBFrame => SS:BP
		mov	ax, ss:[bx].ETE_group
		mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_group, ax
		mov	ds:[di].DPI_inkGroup, ax		
		mov	ax, ss:[bx].ETE_item
		mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_item, ax
		mov	ds:[di].DPI_inkItem, ax
		mov	ss:[bp].IDBF_DBExtra, (size EventStruct)
		call	GP_GetVMFileHanFar
		mov	ss:[bp].IDBF_VMFile, bx
		clr	ss:[bp].IDBF_bounds.R_left
		clr	ss:[bp].IDBF_bounds.R_top

		; Now send messages to the ink object
		;
		mov	si, offset DPResource:InkObject
		mov	ax, MSG_INK_LOAD_FROM_DB_ITEM
		call	ObjCallInstanceNoLock
		add	sp, size InkDBFrame
done:
		mov	cx, size EventTableHeader
		clc

		.leave
		ret
DayPlanLoadInk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanStoreInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the ink away into a DB item

CALLED BY:	GLOBAL (MSG_DP_STORE_INK)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanStoreInk	method dynamic	DayPlanClass, MSG_DP_STORE_INK
		uses	cx, dx, bp
		.enter

		; If we need to save anything away, do it
		;
		test	ds:[di].DPI_inkFlags, mask DPIF_INK_DIRTY
		jz	done			; if not dirty, do nothing
		and	ds:[di].DPI_inkFlags, not (mask DPIF_INK_DIRTY)
		tst	ds:[di].DPI_inkGroup
		jnz	update
		
		; We have new ink, so create a new ink event
		;
		mov	bp, ds:[di].DPI_startYear
		mov	dx, {word} dS:[di].DPI_startDay
		call	DBCreateInkEvent
		mov	ds:[di].DPI_inkGroup, cx
		mov	ds:[di].DPI_inkItem, dx

		; We need to update an existing ink event
update:
		mov	dx, size InkDBFrame
		sub	sp, dx
		mov	bp, sp			; InkDBFrame => SS:BP
		mov	ax, ds:[di].DPI_inkGroup
		mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_group, ax
		mov	ax, ds:[di].DPI_inkItem
		mov	ss:[bp].IDBF_DBGroupAndItem.DBGI_item, ax
		mov	ss:[bp].IDBF_DBExtra, (size EventStruct)
		call	GP_GetVMFileHanFar
		mov	ss:[bp].IDBF_VMFile, bx
		clr	ss:[bp].IDBF_bounds.R_left
		clr	ss:[bp].IDBF_bounds.R_top
		mov	ss:[bp].IDBF_bounds.R_right, 0xffff
		mov	ss:[bp].IDBF_bounds.R_bottom, 0xffff

		; Now send messages to the ink object
		;
		mov	si, offset DPResource:InkObject
		mov	ax, MSG_INK_SAVE_TO_DB_ITEM
		call	ObjCallInstanceNoLock
		add	sp, size InkDBFrame	; clean up the stack		
done:		
		.leave
		ret
DayPlanStoreInk	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanInkDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the ink has become dirty

CALLED BY:	GLOBAL (MSG_DP_INK_DIRTY)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanInkDirty	method dynamic	DayPlanClass, MSG_DP_INK_DIRTY
		.enter

		; Set the dirty flag
		;
		or	ds:[di].DPI_inkFlags, mask DPIF_INK_DIRTY

		.leave
		ret
DayPlanInkDirty	endm

InkCode		ends
endif 	; if _USE_INK



