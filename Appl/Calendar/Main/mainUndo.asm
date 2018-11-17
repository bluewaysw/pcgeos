COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Main
FILE:		undo.asm

AUTHOR:		Don Reeves, January 8, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial revision

DESCRIPTION:
		
	$Id: mainUndo.asm,v 1.1 97/04/04 14:47:56 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

udata		segment

undoRemoveGroup	byte	(?)			; TRUE or FALSE
undoBufferGroup	word	(?)			; buffer - group
undoBufferItem	word	(?)			; buffer - item

undoWord1	word	(?)			; check for specific usage
undoWord2	word	(?)			;
undoWord3	word	(?)			;
undoWord4	word	(?)			;

udata		ends

FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the undo variables

CALLED BY:	GLOBAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial version
	Don	4/14/90		Added retrieval from the MapBlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoReset	proc	near
	.enter

EC <	call	GP_DBVerify			; verify the map block	>
	call	GP_DBLockMap			; get the map block
	mov	di, es:[di]			; dereference the handle
	mov	al, es:[di].YMH_undoRmGroup
	mov	ds:[undoRemoveGroup], al
	mov	ax, es:[di].YMH_undoBufGr
	mov	ds:[undoBufferGroup], ax
	mov	ax, es:[di].YMH_undoBufIt
	mov	ds:[undoBufferItem], ax
	call	DBUnlock			; unlock the map item
	CallMod	UndoNotifyClear

	.leave
	ret
UndoReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the undo variables

CALLED BY:	GLOBAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial version
	Don	4/14/90		Added retrieval from the MapBlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoWrite	proc	near
	.enter

EC <	call	GP_DBVerify			; verify the map block	>
	call	GP_DBLockMap			; get the map block
	mov	di, es:[di]			; dereference the handle
	mov	ax, ds:[nextAlarmGroup]		; the next alarm group
	mov	es:[di].YMH_nextAlarmGr, ax
	mov	ax, ds:[nextAlarmItem]		; the next alarm item
	mov	es:[di].YMH_nextAlarmIt, ax
	call	GP_DBDirtyUnlock

	.leave
	ret
UndoWrite	endp

FileCode	ends



CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyClear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify undo of no possible action

CALLED BY:	GLOBAL

PASS:		Nothing

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyClear	proc	far
	uses	ax, bx, di, ds
	.enter

	; Tell everyone we have nothing to undo
	;
	GetResourceSegmentNS	dgroup, ds, ax
	test	ds:[systemStatus], SF_IN_UNDO
	jnz	done
	mov	ax, MSG_GEN_PROCESS_UNDO_FLUSH_ACTIONS
	call	GeodeGetProcessHandle
	call	ObjMessage_common_send
done:
	.leave
	ret
UndoNotifyClear	endp

CommonCode	ends



UndoNotifyCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Notification of actions that are "undo-able"
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to a delete in the database

CALLED BY:	GLOBAL

PASS:		DS	= DGroup
		AX	= EventStruct to delete - group
		DI	= EventStruct to delete - item

RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyDelete	proc	far
	uses	cx, dx, si
	.enter

	; Set the new action
	;
	push	ax
	segmov	es, ds
	mov	ax, UNDO_DELETE_EVENT
	call	UndoNotifyAction
	pop	ax

	; Free the existing undo buffer
	;
	mov	cx, ax
	mov	dx, di				; current group:item to CX:DX
	xchg	ax, ds:[undoBufferGroup]	; store new; retrieve old
	xchg	di, ds:[undoBufferItem]
	tst	ax				; no old buffer ??
	je	done				; if so, jump
	call	GP_DBFree			; else free the buffer
	cmp	ds:[undoRemoveGroup], TRUE	; remove the group ??
	jne	done
	mov	ds:[undoRemoveGroup], FALSE
	call	GP_DBGroupFree
done:
	call	UndoUpdateMapBlock		; write back the changes
	mov	ax, cx				; restore the group
	mov	di, dx				; restore the item

	.leave
	ret
UndoNotifyDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyDeleteVirgin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepare for possible undo of virgin delete

CALLED BY:	GLOBAL

PASS:		CX	= Hour/minute
		DX	= Month/day
		BP	= Year
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyDeleteVirgin	proc	far
	uses	ax
	.enter

	mov	es:[undoWord1], cx		; hour/minute
	mov	es:[undoWord2], dx		; month/day
	mov	es:[undoWord3], bp		; year
	mov	ax, UNDO_DELETE_VIRGIN
	call	UndoNotifyAction

	.leave
	ret
UndoNotifyDeleteVirgin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyInsertEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify that an event is about to be inserted, and can be
		undone

CALLED BY:	GLOBAL

PASS:		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	3/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyInsertEvent	proc	far
	uses	ax
	.enter
	
	mov	ax, UNDO_INSERT_EVENT		; the correct undo action
	call	UndoNotifyAction

	.leave
	ret
UndoNotifyInsertEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyStateChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify the undo of an impending change of state from a 
		virgin or repeat event to a normal event

CALLED BY:	GLOBAL

PASS: 		ES	= DGroup
		BP	= DayEventHandle
		CX:DX	= Group:Item of the EventStruct or the RepeatStruct
		AX	= Current Time of Event

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyStateChange	proc	far
	uses	ax, bx, cx, dx, bp, si, di
	.enter

	; Store the information away
	;
	mov	es:[undoWord1], cx		; store the group
	mov	es:[undoWord2], dx		; store the item
	mov	es:[undoWord3], bp		; store the DayEvent handle
	mov	es:[undoWord4], ax		; store the time

	; Notify undo of the proper action
	;
	mov	ax, UNDO_STATE_CHANGE
	call	UndoNotifyAction

	.leave
	ret
UndoNotifyStateChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prepere for possible undo of text changes

CALLED BY:	GLOBAL

PASS:		CX	= EventStruct - Group
		DX	= EventStruct - Item
		BP	= DayEvent handle
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyText	proc	far
	uses	ax
	.enter

	; Store the information away
	;
	mov	es:[undoWord1], cx
	mov	es:[undoWord2], dx
	mov	es:[undoWord3], bp

	; If not a normal event, we're done
	;
	tst	cx				; is CX zero ?? (vrigin event)
	je	done				; if so, do nothing!
	test	cx, REPEAT_MASK			; a repeating event ??
	jne	done				; if so, do nothing!

	; Else need to backup copy of text to a buffer
	;
	push	bx, cx, di, si, es
	push	ds:[LMBH_handle]		; save the block handle
	segmov	ds, es				; DGroup => DS
	mov	ax, cx				; group to AX
	mov	di, dx				; item to DI
	call	GP_DBLock			; lock the source EventStruct
	mov	si, di				; set up the handle
	call	UndoGetBuffer			; get a buffer to hold info

	; Resize the buffer
	;
	mov	bx, es:[si]			; dereference the handle
	mov	cx, es:[bx].ES_dataLength	; total size => CX
	mov	ds:[undoWord4], cx		; store the text size
	segmov	ds, es				; DS:*SI is source EventStruct
	call	GP_DBReAlloc			; resize the destination
	call	GP_DBLock			; and lock it

	; Copy the bytes
	;
	mov	si, ds:[si]			; dereference source handle
	add	si, offset ES_data		; add in offset to text
	mov	di, es:[di]			; dereference dest handle
	rep	movsb				; copy them bytes
	call	DBUnlock			; unlock destination
	segmov	es, ds
	call	DBUnlock			; unlock the source
	pop	bx				; pop the block handle
	call	MemDerefDS			; restore the segment
	pop	bx, cx, di, si, es

	; Now notify of proper undo action
	;
	mov	ax, UNDO_REVERT_TEXT
	call	UndoNotifyAction
done:
	.leave
	ret
UndoNotifyText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify of ability to undo a time change

CALLED BY:	GLOBAL

PASS:		CX	= EventStruct - item
		DX	= EventStruct - group
		BP	= DayEvent handle
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Exit:
			undoWord1	= EventStruct - group
			undoWord2	= EventStruct - item
			undoWord3	= DayEvent Handle
			undoWord4	= Current Hour/Minute

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/20/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyTime	proc	far
	uses	ax
	.enter

	; Store the information away
	;
	mov	es:[undoWord1], cx		; store the group
	mov	es:[undoWord2], dx		; store the item
	mov	es:[undoWord3], bp		; store the DayEvent handle

	; Is this not a normal event?  If so, we're done
	;
	tst	cx				; is CX zero ?? (vrigin event)
	je	done				; if so, do nothing!
	test	cx, REPEAT_MASK			; a repeating event ??
	jne	done				; if so, do nothing!

	; Else get the current time, please
	;
	push	di, es				; save these registers
	mov	ax, cx				; group to AX
	mov	di, dx				; item to DI
	call	GP_DBLockDerefDI		; lock the source EventStruct
	mov	ax, {word} es:[di].ES_timeMinute ; Hour/Minute => CX
	call	DBUnlock
	pop	di, es				; restore the registers
	mov	es:[undoWord4], ax		; store the time

	; Now notify of proper undo action
	;
	mov	ax, UNDO_REVERT_TIME
	call	UndoNotifyAction
done:
	.leave
	ret
UndoNotifyTime	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyGroupFree
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to tell us to delete a group

CALLED BY:	DBDeleteYear

PASS:		AX	= Group #
		DS	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/11/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoNotifyGroupFree	proc	far
	.enter

EC <	cmp	ax, ds:[undoBufferGroup]	; same group? (should be)  >
EC <	ERROR_NZ	UNDO_NOTIFY_GROUP_FREE_BAD_GROUP		>
	mov	ds:[undoRemoveGroup], TRUE
	call	UndoUpdateMapBlock		; write back the changes

	.leave
	ret
UndoNotifyGroupFree	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoUpdateMapBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the information in the file's MapBlock

CALLED BY:	INTERNAL
	
PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:
		We leave the variable in dgroup for convenience (and speed
		at ths time), but force the MapBlock to get updated each
		time a change is made by an Undo routine.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoUpdateMapBlock	proc	near
	uses	ax, di, es
	.enter

EC <	VerifyDGroupDS				; verify it		>
	call	GP_DBLockMap
	mov	di, es:[di]			; dereference the handle
	mov	al, ds:[undoRemoveGroup]
	mov	es:[di].YMH_undoRmGroup, al
	mov	ax, ds:[undoBufferGroup]
	mov	es:[di].YMH_undoBufGr, ax
	mov	ax, ds:[undoBufferItem]
	mov	es:[di].YMH_undoBufIt, ax
	call	GP_DBDirtyUnlock		; unlock the map item

	.leave
	ret
UndoUpdateMapBlock	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoGetBuffer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current undo buffer, or create one based on AX

CALLED BY:	Undo - GLOBAL

PASS:		AX	= Possible group for buffer
		DS	= DGroup

RETURN:		AX	= EventStruct - Group
		DI	= EventStruct - Item

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoGetBuffer	proc	near
	uses	cx
	.enter

	mov	cx, ax				; passed group => CX
	mov	ax, ds:[undoBufferGroup]
	mov	di, ds:[undoBufferItem]
	tst	ax				; buffer ??
	jne	done				; if so, jump

	; Else must allocate a buffer
	;
	mov	ax, cx				; use the passed group
	mov	cx, size EventStruct
	call	GP_DBAlloc			; else allocate a buffer
	mov	ds:[undoBufferGroup], ax
	mov	ds:[undoBufferItem], di
	call	UndoUpdateMapBlock		; store all changes
done:
	.leave
	ret
UndoGetBuffer	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoNotifyAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify undo of possible undo action

CALLED BY:	UNDO - global

PASS:		ES	= DGroup
		AX	= New action

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CALENDAR_UNDO_DATA	equ	<UADU_flags.UADF_flags.low>

undoStrings	lptr \
		undoDeleteEventStr, \
		undoDeleteEventStr, \
		undoInsertEventStr, \
		undoRevertTextStr, \
		undoRevertTextStr, \
		undoRevertTextStr, \
		undoRevertTimeStr

UndoNotifyActionFar	proc	far
	call	UndoNotifyAction
	ret
UndoNotifyActionFar	endp

UndoNotifyAction	proc	near
	uses	ax, bx, cx, dx, di, si, bp
	.enter

	; Store the undo action away
	;
	test	es:[systemStatus], SF_IN_UNDO
	jnz	done

	push	ds:[LMBH_handle]

EC <	test	ax, 1				; check for odd		>
EC <	ERROR_NZ	UNDO_NOTIFY_ACTION_BAD_UNDO_VALUE		>
EC <	cmp	ax, UndoActionValue		; check the last value	>
EC <	ERROR_AE	UNDO_NOTIFY_ACTION_BAD_UNDO_VALUE		>
	call	GeodeGetProcessHandle		; process handle => BX
	mov_tr	si, ax				; UndoActionValue => SI

	; Start an undo chain
	;
	clr	ax
	mov	dx, size StartUndoChainStruct
	sub	sp, dx
	mov	bp, sp				; StartUndoActionChain => SS:BP
	movdw	ss:[bp].SUCS_owner, bxax
	mov	ss:[bp].SUCS_title.handle, handle DataBlock
	mov	cx, cs:[undoStrings][si]
	mov	ss:[bp].SUCS_title.chunk, cx
	mov	ax, MSG_GEN_PROCESS_UNDO_START_CHAIN
	call	ObjMessage_notify_process_stack
	add	sp, dx
	
	; Now write the undo action
	;
	clr	ax
	mov	dx, size AddUndoActionStruct
	sub	sp, dx
	mov	bp, sp				; AddUndoActionStruct => SS:BP
	mov	ss:[bp].AUAS_data.UAS_dataType, UADT_FLAGS
	mov	ss:[bp].AUAS_data.UAS_data.CALENDAR_UNDO_DATA, si
	movdw	ss:[bp].AUAS_output, bxax
	mov	ss:[bp].AUAS_flags, ax		; no notification needed
	mov	ax, MSG_GEN_PROCESS_UNDO_ADD_ACTION
	call	ObjMessage_notify_process_stack
	add	sp, dx

	; Now end the chain
	;
	mov	cx, 1				; delete if no actions
	mov	ax, MSG_GEN_PROCESS_UNDO_END_CHAIN
	clr	di
	call	ObjMessage_notify_process

	call	MemDerefStackDS
done:
	.leave
	ret
UndoNotifyAction	endp

ObjMessage_notify_process_stack	proc	near
	mov	di, mask MF_STACK
	FALL_THRU	ObjMessage_notify_process
ObjMessage_notify_process_stack	endp

ObjMessage_notify_process	proc	near
	call	GeodeGetProcessHandle		; process handle => BX
	FALL_THRU	ObjMessage_notify
ObjMessage_notify_process	endp

ObjMessage_notify	proc	near
	call	ObjMessage
	ret
ObjMessage_notify	endp

UndoNotifyCode	ends



UndoActionCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarUndo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform an undo action

CALLED BY:	GLOBAL (MSG_META_UNDO)

PASS:		DS, ES	= DGroup
		SS:BP	= UndoActionStruct

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 8/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

undoRoutineTable	nptr.near \
			UndoActionDelete, \
			UndoActionDeleteVirgin, \
			UndoActionInsert, \
			UndoActionStateChange, \
			UndoActionStateRestore, \
			UndoActionRevertText, \
			UndoActionRevertTime

CalendarUndo	method dynamic	GeoPlannerClass, MSG_META_UNDO
	.enter

	; Check the currently stored action
	;
	ornf	ds:[systemStatus], SF_IN_UNDO
	mov	bx, ss:[bp].UAS_data.CALENDAR_UNDO_DATA
EC <	test	bx, 1							>
EC <	ERROR_NZ	UNDO_ACTION_BAD_UNDO_VALUE			>
EC <	cmp	bx, UndoActionValue		; check for bad value	>
EC <	ERROR_AE	UNDO_ACTION_BAD_UNDO_VALUE			>
	call	cs:[undoRoutineTable][bx]
	andnf	ds:[systemStatus], not (SF_IN_UNDO)

	; Now set the new undo action
	;
	cmp	ax, -1
	je	done
	segmov	es, ds				; DGroup => ES
	call	UndoNotifyActionFar	
done:
	.leave
	ret
CalendarUndo	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoActionDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo the action of deleting!

CALLED BY:	CalendarUndo - UNDO_DELETE_EVENT

PASS:		DS	= DGroup

RETURN:		AX	= UndoActionValue

DESTROYED:	BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
	Enter:
		undoBufferGroup:	
		undoBufferItem:		Valid, pointing to deleted EventStruct
	Exit:
		undoWord1:
		undoWord2:		Group:item of re-inserted EventStruct
		undoAction:		UNDO_INSERT_EVENT

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoActionDelete	proc	near
	.enter

	; First re-insert the structure into the EventMap
	;
	mov	ax, ds:[undoBufferGroup]	; group # to AX
	mov	di, ds:[undoBufferItem]		; item # to DI
	push	ds				; save the DGroup
	call	RecreateEvent			; create & insert the event
	pop	ds				; restore DGroup

	; Insert the event into the DayPlan
	;
	mov	ds:[undoWord1], ax		; store the inserted group
	mov	ds:[undoWord2], di		; store the insert item
	mov	cx, ax				; group # to CX
	mov	dx, di				; item # to DX
	clr	bp				; calculate insertion point
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_LOAD_EVENT
	call	ObjMessage_undo_call

	; Notify of the new undoAction
	;
	mov	ax, UNDO_INSERT_EVENT

	.leave
	ret
UndoActionDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoActionDeleteVirgin
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo the action of deleting a virgin event

CALLED BY:	CalendarUndo - UNDO_DELETE_VIRGIN

PASS:		DS	= DGroup

RETURN:		AX	= UndoActionValue

DESTROYED:	BX, CX, DX, SI, BP, ES

PSEUDO CODE/STRATEGY:
	Enter:
		undoWord1:		hour/minute
		undoWord2:		month/day
		undoWord3:		year
	Exit:
		Nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoActionDeleteVirgin	proc	near
	.enter

	; Perform the undo
	;
	mov	bp, ds:[undoWord3]		; the year
	mov	dx, ds:[undoWord2]		; month & day
	mov	cx, ds:[undoWord1]		; hour & minute
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_NEW_EVENT
	call	ObjMessage_undo_call

	; Return the nudo action
	;
	mov	ax, UNDO_INSERT_EVENT

	.leave
	ret
UndoActionDeleteVirgin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoActionInsert
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo the action of inserting.

CALLED BY:	CalendarUndo - UNDO_INSERT_EVENT

PASS:		DS	= DGroup

RETURN:		AX	= UndoActionValue

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
	Enter:
		DPI_selectEvent		; points to just-inserted Event
	Exit:
		Nothing

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoActionInsert	proc	near
	.enter

	; Simply send a MSG_DP_DELETE_EVENT to the DayPlan
	;
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_DELETE_EVENT
	call	ObjMessage_undo_call		; UndoActionValue => AX

	.leave
	ret
UndoActionInsert	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoActionStateChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Undo the change to the DayEvent's state.  Possibilties:
			NORMAL => REPEAT
			NORAM => VIRGIN

CALLED BY:	CalendarUndo (UNDO_STATE_CHANGE)

PASS:		DS	= DGroup

RETURN:		AX	= UndoActionValue

DESTROYED:	BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoActionStateChange	proc	near
	.enter

	; Update the contents of the EventStruct
	;
	and	ds:[systemStatus], not SF_DISPLAY_ERRORS
	GetResourceHandleNS	DPResource, bx
	mov	si, ds:[undoWord3]		; BX:SI is our DayEvent
	mov	cl, DBUF_IF_NECESSARY
	mov	ax, MSG_DE_UPDATE_TIME		; update time, and check to see
	call	ObjMessage_undo_call		; ...if current time is invalid
	pushf					; save result for later use
	mov	ax, MSG_DE_UPDATE
	call	ObjMessage_undo_call

	; Obtain the current EventStruct, and remove it from the database
	;
	mov	ax, MSG_DE_GET_DATABASE
	call	ObjMessage_undo_call
	mov	bp, si				; DayEvent handle => BP
	call	DeleteEvent			; Delete the event

	; Determine the type of undo we are performing here
	;
	mov	cx, ds:[undoWord1]		; old group # => CX
	mov	dx, ds:[undoWord2]		; old item # => DX
	mov	bp, DESC_NORMAL_TO_VIRGIN	; assume NORMAL => VIRGIN
	jcxz	changeBack
	mov	bp, DESC_NORMAL_TO_REPEAT	; else NORMAL => REPEAT
changeBack:
	mov	ax, MSG_DE_CHANGE_STATE
	GetResourceHandleNS	DPResource, bx
	mov	si, ds:[undoWord3]		; DayEvent => BX:SI
	call	ObjMessage_undo_call

	; Tell the DayEvent to re-display the time & event text
	;
	mov	cx, ds:[undoWord4]		; old time => CX
	mov	ax, MSG_DE_REDISPLAY
	call	ObjMessage_undo_call		; new text length => AX
	mov	ds:[undoWord4], cx		; store the new time
	
	; Finally, store the new undo action (or clear it)
	;
	mov	ax, -1				; assume time was invalid
	or	ds:[systemStatus], SF_DISPLAY_ERRORS
	popf					; restore UPDATE result
	jc	done				; time was bogus, so we're done
	mov	ax, UNDO_STATE_RESTORE
done:
	.leave
	ret
UndoActionStateChange	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoActionStateRestore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore the state of the DayEvent

CALLED BY:	CalendarUndo (UNDO_ACTION_RESTORE)

PASS:		DS	= DGroup

RETURN:		AX	= UndoActionValue

DESTROYED:	BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/26/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoActionStateRestore	proc	near
	.enter

	; Obtain the current EventStruct, and re-insert it into the database
	;
	mov	ax, ds:[undoBufferGroup]	; group => AX
	mov	di, ds:[undoBufferItem]		; item => DI
	push	ds				; save DGroup
	call	RecreateEvent
	pop	ds
	mov	ds:[undoWord1], ax		; store the group
	mov	ds:[undoWord2], di		; store the item

	; Call for the change of state from VIRGIN or REPEAT to NORMAL
	;
	GetResourceHandleNS	DPResource, bx
	mov	ax, MSG_DE_GET_DATABASE
	mov	si, ds:[undoWord3]		; DayEvent handle => SI
	call	ObjMessage_undo_call
	xchg	ds:[undoWord1], cx		; swap old/new group numbers
	xchg	ds:[undoWord2], dx		; swap old/new item numbers
	mov	bp, DESC_REPEAT_OR_VIRGIN_TO_NORMAL
	mov	ax, MSG_DE_CHANGE_STATE
	call	ObjMessage_undo_call

	; Tell the DayEvent to re-display the time & event text
	;
	mov	cx, ds:[undoWord4]		; old time => CX
	mov	ax, MSG_DE_REDISPLAY
	call	ObjMessage_undo_call		; new text length => AX
	mov	ds:[undoWord4], cx		; store the new time

	; Finally, store the new undo action
	;
	mov	ax, UNDO_STATE_CHANGE

	.leave
	ret
UndoActionStateRestore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoActionRevertText
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert the text displayed by going to the database

CALLED BY:	CalendarUndo - UNDO_REVERT_TEXT

PASS:		DS	= DGroup

RETURN:		AX	= UndoActionValue

DESTROYED:	BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:
	Enter:
		undoWord1:
		undoWord2:		Group:item of current EventStruct
		undoWord3:		DayEvent handle of current EventStruct
		undoBufferGroup:
		undoBufferItem:		Group:item of stored TextBlock
	Exit:
		undoAction:		UNDO_REVERT_TEXT

		Resize the buffer
		Store the text string
		Call for text to be "swapped"

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version
	Don	1/25/90		Completely re-written

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoActionRevertText	proc	near
	.enter

	; Handle the normal case (buffer's text to EventStruct)
	;
	mov	cx, ds:[undoWord4]		; size of text => CX
	mov	ax, ds:[undoBufferGroup]
	mov	di, ds:[undoBufferItem]
	push	ax, di, ds			; group, item, Dgroup
	call	GP_DBLock			; lock the text block
	mov	si, di				; ES:*SI points to text block
	mov	ax, ds:[undoWord1]		; EventStruct group #
	mov	di, ds:[undoWord2]		; EventStruct item #
	segmov	ds, es				; DS:*SI points to text block
SBCS <	add	cx, size EventStruct		; new size to CX	>
DBCS <	add	cx, (size EventStruct)+1	; new size to CX	>
	call	GP_DBReAlloc			; re-size the EventStruct 
	call	GP_DBLockDerefDI		; lock it & dereference => ES:DI
SBCS <	sub	cx, size EventStruct		; text size back in CX >
DBCS <	sub	cx, (size EventStruct)+1	; text size back in CX >

	; Copy the bytes
	;
	mov	si, ds:[si]			; derference source handle
	mov	es:[di].ES_dataLength, cx	; store the data length
	add	di, offset ES_data
	rep	movsb				; copy them bytes
SBCS <	mov	{byte} es:[di], 0		; add in the NULL termination >
DBCS <	mov	{wchar} es:[di], 0		; add in the NULL termination >
	call	DBUnlock			; unlock the EventStruct
	segmov	es, ds
	call	DBUnlock			; unlock the buffer
	pop	cx, dx, ds			; group, item, Dgroup

	; Finish out our common work (CX = group, DX = item for buffer)
	; New text to buffer; call for DayEvent to be re-stuffed
	;
	GetResourceHandleNS	DPResource, bx	; Block handle => BX
	mov	si, ds:[undoWord3]		; DayEvent handle in word3
	mov	bp, offset DEI_textHandle	; offset to the text handle
	mov	ax, MSG_DE_RETRIEVE_TEXT
	call	ObjMessage_undo_call		; new text length => AX
DBCS <	shl	ax, 1				; size of string	>
	mov	ds:[undoWord4], ax		; store the new text size

	; Return the next UndoActionValue
	;
	mov	ax, UNDO_REVERT_TEXT

	.leave
	ret
UndoActionRevertText	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UndoActionRevertTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Revert the time displayed by going to the database

CALLED BY:	CalendarUndo - UNDO_REVERT_TIME

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
	Enter:
		undoWord1	EventStruct - group
		undoWord2	EventStruct - item
		undoWord3	DayEvent handle
		undoWord4	Old time (Hour/Minute)
	Exit:
		undoWord4	New time (Hour/Minute)

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UndoActionRevertTime	proc	near
	.enter

	; Get the currently stored time
	;
	GetResourceHandleNS	DPResource, bx
	mov	si, ds:[undoWord3]		; DayEvent handle => SI
	and	ds:[systemStatus], not SF_DISPLAY_ERRORS
	mov	ax, MSG_DE_PARSE_TIME
	call	ObjMessage_undo_call
	pushf					; save the flags
	or	ds:[systemStatus], SF_DISPLAY_ERRORS

	; Exchange the old & new times
	;
	xchg	cx, ds:[undoWord4]		; swap the times
	mov	ax, MSG_DE_SET_TIME		; reset the time
	call	ObjMessage_undo_call

	; Notify the database
	;
	mov	ax, ds:[undoWord1]		; group => AX
	mov	di, ds:[undoWord2]		; item => DI
	call	DBUpdateEventTime		; alter the event time!

	; Determine if we can "redo"
	;
	mov	ax, -1				; assume time was invalid
	popf					; restore the flags
	jc	done				; time was bogus, so we're done
	mov	ax, UNDO_REVERT_TIME		; else we can perform undo
done:
	.leave
	ret
UndoActionRevertTime	endp

ObjMessage_undo_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	ret
ObjMessage_undo_call	endp

UndoActionCode	ends
