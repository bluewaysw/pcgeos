COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Repeat
FILE:		repeatDatabase.asm

AUTHOR:		Don Reeves, November 20, 1989

ROUTINES:
	Name			Description
	----			-----------
    GLB RepeatInitFile		Initializes the repeat event structures

    GLB RepeatStart		Resets the repeating events cached data

    GLB RepeatReset		Resets the repeating events cached data

 ?? INT RepeatStop		Delete all the RepeatYearTables

    INT RepeatReInitializeList	Re-initialize the repeat list's monikers

    GLB RepeatLoadEvent		Load an event into the DayPlan

 ?? INT RepeatFindRepeatMap	Find the RepeatMapStruct given the Repeat
				ID

    GLB RepeatIDStillExist	Determine if the passed Repeat ID still
				exists (as part of a current Repeating
				Event)

    GLB RepeatStore		Add a repeating event to the database

    GLB RepeatStore		Add a repeating event to the database

 ?? INT RepeatStoreCommon	Perform the common work of creating a new
				repeating event - that of notifying the
				rest of the world

    INT RepeatInsertDeleteEventIDArray
				Insert or delete the event ID and DB
				group:item into or from event ID array
				given a RepeatStruct

 ?? INT RepeatStuff		Stuff the repeat event. Assumes the DB item
				allocated has sufficient room for the
				RepeatStruct and the event text (whose size
				is passed to this routine). Note that it is
				crucial for date exceptions that any data
				beyond the end of the event is not
				modified.

 ?? INT RepeatAddToTable	Add a new repeat event to the table

    GLB RepeatDelete		Delete a repeating event from the database

    GLB RepeatDelete		Delete a repeating event from the database

 ?? INT RepeatDeleteCommon	Perform common work of deleting a repeating
				event - that of finding the RepeatStruct
				group:item, and generating the
				"de-insertion" events

 ?? INT RepeatModify		Modify an existing repeating event

 ?? INT RepeatModify		Modify an existing repeating event

    GLB RepeatAddExceptionDate	Delete a single occurrence of a repeating
				event, by storing an "exception date" with
				the event

    GLB RepeatDeleteExceptionDate
				Restore a repeating event to occur on a
				specific date, by removing the "exception
				date" stored with the event

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial revision

DESCRIPTION:
	Routines to handle storing, retrieving & deleting of repeating
	events.
		
	$Id: repeatDatabase.asm,v 1.1 97/04/04 14:48:50 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

REPEAT_TABLE_INCREMENT = 20

FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the repeat event structures

CALLED BY:	GLOBAL

PASS:		DS	= DGroup
		BP	= Year

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatInitFile	proc	near

	; Initialize the map block
	;
EC <	call	GP_DBVerify			; verify the block	>
	call	GP_DBLockMap			; get the map block, lock it
	mov	bx, di				; move the handle to BX

	; Now create a new group & two items
	;
	call	GP_DBGroupAlloc			; allocate a group
	mov	cx, REPEAT_TABLE_INCREMENT
	call	GP_DBAlloc			; allocate the RepeatMap
	
	; Store the information
	;
	mov	si, es:[bx]			; dereference the Map handle
	mov	es:[si].YMH_repeatMapGr, ax	; store the map group
	mov	es:[si].YMH_repeatMapIt, di	; and the map item
	call	DBUnlock			; unlock it

	; Initialize the RepeatMap
	;
	mov	dx, di				; item # => DX
	call	GP_DBLockDerefSI		; lock the map item
	mov	es:[si].RMH_item, dx		; store the item #
	mov	es:[si].RMH_size, REPEAT_TABLE_INCREMENT ; the initial size
	mov	es:[si].RMH_numItems, 0		; Zero items initially
	mov	es:[si].RMH_nextValue, REPEAT_FIRST_ID
	add	si, size RepeatMapHeader
	mov	cx, REPEAT_TABLE_INCREMENT - (size RepeatMapHeader)
	CallMod	ClearSomeBytes
	call	DBUnlock			; unlock the RepeatMap

	ret
RepeatInitFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatStart
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the repeating events cached data

CALLED BY:	GLOBAL

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/29/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatStart	proc	near
	.enter

	; Set up some all-important variables
	;
	GetResourceHandleNS	RepeatBlock, bx	; RepeatBlock handle => BX
	mov	ds:[repeatBlockHan], bx		; store this handle
	call	RepeatReInitializeList		; display monikers if visible

	.leave
	ret
RepeatStart	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Resets the repeating events cached data

CALLED BY:	GLOBAL

PASS:		DS	= DGroup

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

RepeatReset	proc	near
	.enter

	; First nuke any existing data
	; 
	call	RepeatStop
EC <	VerifyDGroupDS				; verify the segment	>

	; Now read any cached data
	;
EC <	call	GP_DBVerify			; verify it		>
	call	GP_DBLockMap			; get the map block, lock it
	mov	si, es:[di]			; dereference the handle
	mov	ax, es:[si].YMH_repeatMapIt
	mov	ds:[repeatMapItem], ax		; set global variable
	mov	ax, es:[si].YMH_repeatMapGr
	mov	ds:[repeatMapGroup], ax		; set global variable
	mov	ds:[repeatGenProc], offset AddNewEvent
	mov	ds:[repeatLoadID], 0
	mov	ds:[newYear], 0			; set the flag
	call	DBUnlock			; unlock the map block

	.leave
	ret
RepeatReset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatStop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete all the RepeatYearTables

CALLED BY:	DBCalEnd

PASS:		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatStop	proc	near
	.enter

	; Delete all the tables
	;
	mov	si, offset repeatTableStructs
deleteLoop:
	clr	cx
	clr	dx
	mov	ds:[si].RTS_yearYear, cx		; clear the year
	xchg	cx, ds:[si].RTS_tableOD.handle	; swap handle with zero
	xchg	dx, ds:[si].RTS_tableOD.chunk	; swap chunk with zero
	tst	cx				; is there a table
	jz	nextTable
	call	DestroyRepeatYearTable		; destroy the table
nextTable:
	add	si, size RepeatTableStruct	; go to the next struct
	cmp	si, offset endRepeatTable	; compare with end
	jl	deleteLoop			; else remove another table

	; Clean up some global variables
	;
EC <	VerifyDGroupDS				; verify the segment	>
	mov	ds:[repeatTableHeader].RTH_lastSwap, TOTAL_REPEAT_TABLE_SIZE
	mov	ds:[repeatMapItem], 0		; reset the map item
	mov	ds:[repeatMapGroup], 0		; reset the map group
	call	RepeatReInitializeList		; purge the list's monikers

	.leave
	ret
RepeatStop	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatReInitializeList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Re-initialize the repeat list's monikers

CALLED BY:	INTERNAL
	
PASS: 		DS	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/23/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatReInitializeList	proc	near
	.enter

	; Call for the monikers to be re-loaded, and the exclusive reset
	;
	call	RepeatGetNumEvents		; number => CX
	mov	bp, mask VUID_REPEAT_EVENTS	; NotifyUIData => BP
	call	UpdateVisibilityData		; update the visibility data

	.leave
	ret
RepeatReInitializeList	endp

FileCode	ends



CommonCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatLoadEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load an event into the DayPlan

CALLED BY:	GLOBAL

PASS:		BX	= RepeatTable offset
		CX	= Repeat ID
		SS:BP	= EventRangeStruct
		DS	= DGroup
		ES	= Relocatable segment, ES:0 = block handle

RETURN:		Carry	= Set or Clear depending on method call

DESTROYED:	CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatLoadEvent	proc	near

	; Some set-up work
	;
EC <	VerifyDGroupDS				; verify the segment	>
	tst	ds:[repeatLoadID]		; is the ID zero ?
	je	OK				; if so, everything's OK
	cmp	ds:[repeatLoadID], cx		; else are the ID's equal
	je	OK				; yes, so load the Repeat Event
	clc					; don't abort the loading
	ret					; and return
	
	; Now find this Repeating Event
OK:
	push	ax, bx, dx, di, si, ds		; store these registers
	push	es:[LMBH_handle]		; store the block handle
	mov	ax, ds:[repeatMapGroup]
	mov	di, ds:[repeatMapItem]
	call	RepeatFindRepeatMap		; Returns ES:SI pointing to RMS
	jnc	done				; jump if not found

	; Make the call
	;
	call	TablePosToDate			; calculate the date
	mov	ss:[bp].ERS_curMonthDay, dx	; store the month & day
	mov	dx, es:[si].RMS_item		; item number => DX
	mov	cx, ax				; group number => CX
	or	cx, REPEAT_MASK			; set the repeat mask bit
	mov	ax, ss:[bp].ERS_message
	mov	bx, ss:[bp].ERS_object.handle
	mov	si, ss:[bp].ERS_object.chunk
	call	MemDerefDS			; DS:*SI is the OD
	call	ObjCallInstanceNoLock		; make the call		

	; We're done
done:
	lahf					; flags => AH
	call	DBUnlock			; unlock the map group
	pop	bx
	call	MemDerefES			; fixup ES
	sahf					; restore the flags
	pop	ax, bx, dx, di, si, ds		; restore these registers
	ret
RepeatLoadEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatFindRepeatMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find the RepeatMapStruct given the Repeat ID

CALLED BY:	Repeat - GLOBAL

PASS:		AX	= RepeatMap group #
		DI	= RepeatMap item #
		CX	= Repeat ID

RETURN:		ES:*DI	= RepeatMapTable (locked)
		ES:SI	= Desired RepeatMapStruct
		Carry	= Set if found
			= Clear if not found

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/9/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatFindRepeatMap	proc	far
	uses	ax
	.enter

	; Find the Repeat Id
	;
	call	GP_DBLockDerefSI		; lock the item
	mov	ax, si
	add	ax, es:[si].RMH_size		; last table location => AX
	add	si, (size RepeatMapHeader)- (size RepeatMapStruct)
findLoop:
	add	si, size RepeatMapStruct	; go to the next structure
	cmp	si, ax				; check the find length
	je	done				; if done, leave
	cmp	cx, es:[si].RMS_indexValue	; compare the index values
	jne	findLoop			; if unequal, loop again
	stc					; else found - set carry
done:
	.leave
	ret
RepeatFindRepeatMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatIDStillExist
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine if the passed Repeat ID still exists (as part
		of a current Repeating Event)

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		CX	= Repeat ID

RETURN:		AX	= Time of RepeatStruct
		CX:DX	= Group:Item of RepeatStruct
		Carry	= Set if the ID exists
			- or -
		AX	= garbage
		CX:DX	= garbage
		Carry	= Clear

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/13/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatIDStillExist	proc	far
		uses	di, si, es
		.enter
	;
	; Search through the RepeatMap for the ID
	;
EC <		VerifyDGroupES			; verify the segment	>
		mov	ax, es:[repeatMapGroup]	; get the RepeatMap group #
		mov	di, es:[repeatMapItem]	; get the RepeatMap item #
		call	RepeatFindRepeatMap	; if found, carry = set
		jnc	done
		mov	cx, ax
		mov	dx, es:[si].RMS_item	; group:item => CX:DX
		call	DBUnlock
		mov	di, dx
		call	GP_DBLockDerefDI	; RepeatStruct => ES:DI
		mov	ax, {word} es:[di].RES_minute
		stc				; success!
done:
		call	DBUnlock
		
		.leave
		ret
RepeatIDStillExist	endp

CommonCode	ends



RepeatCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatStore
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a repeating event to the database

CALLED BY:	GLOBAL

PASS:		DS	= DGroup
		SS:BP	= RepeatStruct
		CX	= Length of the text
		DX	= Text block handle

RETURN:		CX	= New Repeat ID

DESTROYED:	AX, BX, DX, DI, SI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	simon	 2/23/97	Add repeat event to event ID array

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RepeatStore	proc	near
	uses	bp
	.enter

	; Allocate a RepeatStruct, store the text
	;
EC <	VerifyDGroupDS				; verify the segment	>
	mov	ds:[repeatEvents], TRUE		; we must now have some events
	mov	ax, ds:[repeatMapGroup]		; put the Repeat Group into AX
DBCS <	shl	cx, 1				; # chars -> # bytes	>
	add	cx, size RepeatStruct
	call	GP_DBAlloc			; allocate the structure
	push	di				; save the new repeat item
	sub	cx, size RepeatStruct		; true length of text to CX
	call	RepeatStuff			; stuff the repeat event

if	SEARCH_EVENT_BY_ID
	; Insert the repeat event Gr:It and ID into event ID array
	;
	clr	bx				; insert event
	call	RepeatInsertDeleteEventIDArray	; es destroyed
endif   ; SEARCH_EVENT_BY_ID

	; Now add this Repeat event to the table
	;
	pop	dx				; restore the RepeatEvent
	mov	di, ds:[repeatMapItem]		; RepeatMap item => DI
	call	RepeatAddToTable		; also returns the ID
	mov	di, dx
	call	GP_DBLockDerefSI		; lock the Repeat item
	mov	es:[si].RES_ID, cx		; store the ID #
	call	DBUnlock			; unlock the item	

	; Update the cached year data & UI
	;
	call	RepeatStoreCommon

	.leave	
	ret
RepeatStore	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatStoreCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform the common work of creating a new repeating event -
		that of notifying the rest of the world

CALLED BY:	RepeatStore(), RepeatModify()

PASS:		DS	= DGroup
		AX:DX	= RepeatStruct Group:Item
		CX	= Repeat ID

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/94	Initial version
	sean 	9/8/95		Responder changes/EC code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatStoreCommon	proc	near
	.enter

	; Update cached year tables
	;
	segmov	es, ds, si			; ES:0 contains valid handle
	call	GenerateInsert			; add to all current tables
	mov	ds:[repeatLoadID], cx		; initialize the ID

	; Update the Event view
	;
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_DP_ADD_REPEAT_EVENT
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	call	ObjMessage	
	; Update the Year view
	;
	clr	bp				; affects all months
	call	DBNotifyMonthChange		; notify of the month change
	clr	cx
	xchg	cx, ds:[repeatLoadID]		; clear the ID value
	
	.leave
	ret
RepeatStoreCommon	endp

if	SEARCH_EVENT_BY_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatInsertDeleteEventIDArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Insert or delete the event ID and DB group:item into or from
		event ID array given a RepeatStruct

CALLED BY:	(INTERNAL) RepeatDelete, RepeatStore
PASS:		ax:di	= DB Group:Item
		bx	= zero to insert OR
			  non-zero to delete
RETURN:		nothing
DESTROYED:	es
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/23/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RepeatInsertDeleteEventIDArray	proc	near
		uses	cx, dx
		.enter
	;
	; Lock down the item first
	;
		push	di
		call	GP_DBLockDerefDI	; es:di = RepeatStruct
		movdw	cxdx, es:[di].RES_uniqueID
		Assert	eventID	cxdx
		call	DBUnlock		; es destroyed
		pop	di			; ax:di = Gr:It of RepeatStruct
	;
	; To insert or delete an event?
	;
		tst	bx			; 0 to insert
		jnz	deleteEvent

		call	DBInsertEventIDArray	; es destroyed
		jmp	done

deleteEvent:
		call	DBDeleteEventIDArray	; es destroyed
						; carry set if event not found
EC <		ERROR_C CALENDAR_EVENT_ID_ARRAY_ELEMENT_NOT_FOUND	>

done:
		.leave
		ret
RepeatInsertDeleteEventIDArray	endp


endif	; SEARCH_EVENT_BY_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatStuff
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the repeat event. Assumes the DB item allocated
		has sufficient room for the RepeatStruct and the event
		text (whose size is passed to this routine). Note that
		it is crucial for date exceptions that any data beyond
		the end of the event is not modified.

CALLED BY:	RepeatStore

PASS:		AX	= Group # for Repeat Event
		DI	= Item # for Repeat Event
		SS:BP	= New RepeatStruct
		CX	= Size of text
		DX	= Text block handle

RETURN:		Nothing

DESTROYED:	BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	sean	11/8/95		Changed DBUnlock to GP_DBDirtyUnlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatStuff	proc	near
	uses	di, si, ds
	.enter

	; Copy the struct
	;
	push	ax				; save the group #
	call	GP_DBLockDerefDI		; lock the item
	push	di				; save the handle
	segmov	ds, ss
	mov	si, bp				; DS:SI points at the source
	push	cx				; save the size
	mov	cx, size RepeatStruct
	rep	movsb				; copy them bytes

	; Now copy in the text
	;
	pop	cx				; restore the text length
	mov	bx, dx
	call	MemLock				; lock the text block
	mov	ds, ax
	clr	si				; DS:SI points at the text
	pop	di				; restore the Repeat handle
	mov	es:[di].RES_dataLength, cx	; store the data length
	add	di, offset RES_data		; go to start of data
	rep	movsb				; copy the text
SBCS <	mov	{byte} es:[di], 0		; null termination	>
DBCS <	mov	{wchar} es:[di], 0		; null termination	>

	; Clean up
	;
	call	MemFree				; free up the text block
	pop	ax				; restore the group #
	call	GP_DBDirtyUnlock		; dirty/unlock the item

	.leave
	ret
RepeatStuff	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatAddToTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a new repeat event to the table

CALLED BY:	RepeatStore

PASS:		AX	= Group # for Repeat stuff
		DX	= New Repeat item #
		DI	= RepeatMap item #

RETURN:		CX	= Repeat ID # (offset in table)

DESTROYED:	BX, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	kho	5/02/96		Call GP_DBDirtyUnlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatAddToTable	proc	near
	uses	ax, dx, bp, di
	.enter

	; Search for an empty spot in the table
	;
	mov	bp, di				; save the map item #
	call	GP_DBLockDerefSI		; lock the RepeatMap
	mov	si, es:[di]			; dereference the handle
	mov	bx, size RepeatMapHeader	; initial offset
	jmp	midLoop				; start the loop

	; Loop, searching for a spot on the table
	;
repLoop:
	cmp	es:[si][bx].RMS_item, 0		; look for an open spot
	je	insert
	add	bx, size RepeatMapStruct	; go to the next struct
midLoop:
	cmp	bx, es:[si].RMH_size		; compare with the table size
	jl	repLoop

	; Need to insert some more space
	;
	mov	cx, bx				; get the old size
	add	cx, REPEAT_TABLE_INCREMENT	; increment # bytes
	mov	es:[si].RMH_size, cx		; store the size
	call	GP_DBDirtyUnlock		; unlock the RepeatMap
	mov	di, bp				; item # to DI
	call	GP_DBReAlloc			; resize the sucker
	call	GP_DBLockDerefSI		; lock the item
	mov	cx, REPEAT_TABLE_INCREMENT
	add	si, bx				; go to start of new data
	call	ClearSomeBytes
	sub	si, bx

	; Insert the RepeatMapStruct here
insert:
	mov	es:[si][bx].RMS_item, dx	; store the item #
	mov	cx, es:[si].RMH_nextValue	; index value => CX
	mov	es:[si][bx].RMS_indexValue, cx	; store the index value
	add	es:[si].RMH_nextValue, 2	; calculate the next one
	inc	es:[si].RMH_numItems		; increment the RS count
	call	GP_DBDirtyUnlock		; mark dirty & unlock RepeatMap

	; Update the RepeatDynamicList
	;
	push	cx				; save the Repeat ID
	mov	cx, bx				; offset to CX
	sub	cx, size RepeatMapHeader	; offset from first RMS
	shr	cx, 1
	shr	cx, 1				; size RepeatMapStruct = 4
	push	cx				; push the user value
	mov	ax, MSG_GEN_DYNAMIC_LIST_ADD_ITEMS
	mov	dx, 1				; add on item
	tst	cx
	jnz	sendMethod			; if not the 0th entry, jump
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	cx, dx				; just re-load monikers
sendMethod:
	mov	ds:[repeatEvents], TRUE		; events will now exist!
	mov	si, offset RepeatBlock:RepeatDynamicList
	call	ObjMessage_repeat_send		; send the message

	; Set the user value
	;
	pop	cx				; user value => CX
	call	RepeatSetItemGroupSelection	; set the selection
	pop	cx				; restore the Repeat ID

	.leave
	ret
RepeatAddToTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatDelete
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a repeating event from the database

CALLED BY:	(GLOBAL) CheckIfChangeToNormal, DayPlanDeleteEventByEvent,
		RepeatDeleteEvent, ResponderDeleteRepeatEvent
PASS:		DS	= DGroup
		CX	= Repeat ID

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/30/89	Initial version
	Don	2/9/90		Revised and bugs fixed

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RepeatDelete	proc	near
	.enter

	; Find the repeating event, and generate "un-insertion" event 
	;
	call	RepeatDeleteCommon		; group:item => AX:DI

if	SEARCH_EVENT_BY_ID
	mov	bx, di				; ax:bx = group:item
						; Free RepeatStruct later
else
	call	GP_DBFree			; Free the RepeatStruct
endif	; SEARCH_EVENT_BY_ID
	
	; Now remove the RepeatStruct from the RepeatMap
	;
	mov	di, dx				; RepeatMap handle => DI
	mov	di, es:[di]			; Dereference the Map handle
	mov	cx, size RepeatMapStruct	; Bytes to remove
	dec	es:[di].RMH_numItems		; Decrease the count
	pushf					; Save those flags
	sub	es:[di].RMH_size, cx		; Account for size change
	call	DBUnlock			; unlock the block 

if	SEARCH_EVENT_BY_ID
	; Delete repeat event from event ID array
	;
	mov	di, 1				; delete from event ID array
	xchg	bx, di				; ax:di = group:item
	call	RepeatInsertDeleteEventIDArray	; es destroyed
	call	GP_DBFree			; Free the RepeatStruct
endif   ; SEARCH_EVENT_BY_ID

	mov	di, bp				; Map item # => DI
	mov	dx, si				; Offset to delete at => DX
	call	GP_DBDeleteAt			; remove the RepeatMapStruct

	; Update the RepeatDynamicList
	;
	mov	cx, dx				; offset back to CX
	sub	cx, size RepeatMapHeader	; offset from first RMS
	shr	cx, 1
	shr	cx, 1				; size RepeatMapStruct = 4
	mov	ax, MSG_GEN_DYNAMIC_LIST_REMOVE_ITEMS
	mov	dx, 1				; remove one entry from pos CX
	popf					; restore the flags
	pushf					; re-push the flags
	jnz	sendMethod			; if events, jump!
	mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
	mov	cx, dx				; just re-load the monikers
	mov	ds:[repeatEvents], FALSE	; events will now not exist!
sendMethod:
	mov	si, offset RepeatBlock:RepeatDynamicList
	call	ObjMessage_repeat_send		; send the message
	popf					; restore the flags
	jne	done				; if events left, we're done

	; No RepeatEvents left - do something!
	;
	mov	cx, -1				; pass nothing as selected
	clr	bp				; no flags passed
	call	RepeatSelectEvent		; reset the trigger stuff
done:
	clr	bp				; affects all months
	call	DBNotifyMonthChange		; notify of the month change

	.leave
	ret
RepeatDelete	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatDeleteCommon
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform common work of deleting a repeating event -
		that of finding the RepeatStruct group:item, and generating
		the "de-insertion" events

CALLED BY:	RepeatDelete(), RepeatModify()

PASS:		DS	= DGroup
		CX	= Repeat ID

RETURN:		*ES:DX	= RepeatMap table (remember to call unlock this!!!)
		AX:BP	= RepeatMap table Group:Item
		AX:DI	= RepeatStruct Group:Item
		SI	= Offset into RepeatMap for RepeatMapStruct

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/13/94	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatDeleteCommon	proc	near
	.enter
	
	; Some set-up work
	;
EC <	VerifyDGroupDS				; verify DGroup 	>
	mov	ax, ds:[repeatMapGroup]		; get the RepeatMap group #
	mov	di, ds:[repeatMapItem]		; get the RepeatMap item #
	mov	bp, di				; also to BP

	; Now delete the Repeat event from the screen & the RepeatTables
	;
	call	RepeatFindRepeatMap
EC <	ERROR_NC	DELETE_REPEAT_ITEM_INVALID_ID			>
	mov	dx, es:[si].RMS_item		; RepeatStruct item # => DX
EC <	tst	dx				; is it already empty	>
EC <	ERROR_Z		DELETE_REPEAT_ITEM_IS_ZERO			>
	sub	si, es:[di]			; Offset into map table =>. SI
	call	GenerateUninsert		; remove all references to RS
	xchg	di, dx				; RepeatStruct handle => DI

if	HANDLE_MAILBOX_MSG

	; Clean sent-to information, if any.
	;
	push	ax, es, di
	call	GP_DBLockDerefDI		; es:di <- RepeatStruct
	clr	ax
	xchg	ax, es:[di].RES_sentToArrayBlock
	tst	ax
	jz	noSentTo

	; Clean up the chunk array of sent-to information.
	;
	push	bx
	Assert	dgroup, ds
	mov	bx, ds:[vmFile]
	Assert	vmFileHandle, bx
	call	VMFree
	pop	bx
noSentTo:
	call	GP_DBDirtyUnlock		; es destroyed
	pop	ax, es, di
endif

	.leave
	ret
RepeatDeleteCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatModify
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Modify an existing repeating event

CALLED BY:	RepeatChangeNow()

PASS:		DS	= DGroup
		SS:BP	= RepeatStruct (new)
		DX	= Text block handle (new)
		CX	= Length of text (new)
		AX	= Repeat ID (existing)
		
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Any exception dates are passed along to the new
		event, if any exist.

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/13/94	Initial version
		Don	11/6/95		Handled exception cases

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
RepeatModify	proc	near
		.enter

	; Verify parameters
	;
	;
	; Find the existing event, and generate "de-insertion" event
	;
		push	ax			; save Repeat ID
		mov	ss:[bp].RES_ID, ax	; initialize ID in RepeatStruct
		push	cx, dx, bp
		mov_tr	cx, ax			; Repeat ID => CX
		call	RepeatDeleteCommon	; group:item => AX:DI
						; offset into map => SI
		call	DBUnlock		; unlock map block

if	_REPEAT_DATE_EXCEPTIONS
	;
	; Re-allocate the existing repeat event, and stuff it
	; with the latest data. We have to be careful to keep
	; any RepeatExceptionDate structures around (which are stored
	; as an array at the end of the RepeatStruct), so we carefully
	; add/delete space from the structure (where the event text is
	; located) instead of just doing a complete re-allocation.
	;
		pop	cx, dx, bp
DBCS <		shl	cx, 1			; chars -> bytes	>
		push	cx, dx
		push	di
		call	GP_DBLockDerefDI
		sub	cx, es:[di].RES_dataLength
		call	DBUnlock
		pop	di
		jcxz	stuffEvent		; if same size, no reallocation
		mov	dx, offset RES_data	; offset for insertion/deletion
		jle	deleteSpace				
		call	GP_DBInsertAt
		jmp	stuffEvent
deleteSpace:
		neg	cx
		call	GP_DBDeleteAt
stuffEvent:
		pop	cx, dx
		call	RepeatStuff
else
	;
	; Re-allocate the existing repeating event, and stuff it
	; with the latest data.
	;
		pop	cx, dx, bp
DBCS <		shl	cx, 1			; chars -> bytes	>
		add	cx, (size RepeatStruct)
		call	GP_DBReAlloc
		sub	cx, (size RepeatStruct)
		call	RepeatStuff
endif
	;
	; Generate the "insertion" event, to update Calendar & Event windows
	;
		mov	dx, di			; group:item => AX:DX
		pop	cx			; Repeat ID => CX
		push	si			; save offset into RepeatMap
		call	RepeatStoreCommon	
	;
	; Finally, reset moniker for the correct item in the dynamic list
	;
		mov	cx, ds:[repeatBlockHan]
		mov	dx, offset RepeatBlock:RepeatDynamicList
		pop	bp			; offset into RepeatMap => BP
		sub	bp, (size RepeatMapHeader)
		shr	bp, 1
		shr	bp, 1			; moniker # => BP
		call	RepeatGetEventMoniker

		.leave
		ret
RepeatModify	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatAddExceptionDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Delete a single occurrence of a repeating event, by
		storing an "exception date" with the event

CALLED BY:	GLOBAL

PASS:		DS	= DGroup
		CX	= RepeatID
		DH	= Month
		DL	= Day
		BP	= Year

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/26/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_REPEAT_DATE_EXCEPTIONS
RepeatAddExceptionDate	proc	far
		uses	ax, cx, di, si, es
		.enter
	;
	; First, access the RepeatMapStruct to get the item # for the
	; actual repeating event (RepeatStruct)
	;
EC <		VerifyDGroupDS			; verify the segment	>
		mov	ax, ds:[repeatMapGroup]
		mov	di, ds:[repeatMapItem]
		call	RepeatFindRepeatMap	; ES:SI => RepeatMapStruct
EC <		ERROR_NC REPEAT_ID_UNKNOWN_FOR_EXCEPTION_DATE		>
		mov	di, es:[si].RMS_item
		call	DBUnlock		; unlock RepeatMap table
	;
	; Get the size of the current RepeatStruct (this is not a fixed
	; value, of course, due to the variable data (text & exception
	; structures) at the end of the chunk).
	;
		push	di
		call	GP_DBLockDerefDI
		ChunkSizePtr es, di, cx		; RepeatStruct size => CX
		call	DBUnlock
		pop	di
	;
	; Re-allocate the RepeatStruct to hold the date exception, and
	; store the data there
	;
		push	di
		mov	bx, cx
		add	cx, (size RepeatDateException)
		call	GP_DBReAlloc
		call	GP_DBLockDerefDI	; RepeatStruct => ES:DI
		mov	es:[di][bx].RDE_year, bp
		mov	{word} es:[di][bx].RDE_day, dx
		call	DBUnlock
		pop	di
	;		
	; Finally, update the RepeatYearTable. We don't want to have this
	; repeating event occur, so we *remove* the event from the year table
	;
		mov	si, offset RemoveEvent
		call	GenerateFixupException
	
		.leave
		ret
RepeatAddExceptionDate	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatDeleteExceptionDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore a repeating event to occur on a specific date, by
		removing the "exception date" stored with the event

CALLED BY:	GLOBAL

PASS:		DS	= DGroup
		CX	= RepeatID
		DH	= Month
		DL	= Day
		BP	= Year

RETURN:		Carry	= Set (if date did not exit)

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Never been tested!!!!!!!!!!!!!!!!!!!!!!!!!!


REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/26/95	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_REPEAT_DATE_EXCEPTIONS
RepeatDeleteExceptionDate	proc	far
		uses	ax, bx, cx, di, si, es
		.enter
	;
	; First, access the RepeatMapStruct to get the item # for the
	; actual repeating event (RepeatStruct)
	;
		push	dx			; save day/month
EC <		VerifyDGroupDS			; verify the segment	>
		mov	ax, ds:[repeatMapGroup]
		mov	di, ds:[repeatMapItem]
		call	RepeatFindRepeatMap	; ES:SI => RepeatMapStruct
EC <		ERROR_C	REPEAT_ID_UNKNOWN_FOR_EXCEPTION_DATE		>
		mov	di, es:[di].RMS_item
		call	DBUnlock		; unlock RepeatMap table
	;
	; Determine the offset of the exception structure in question
	;
		push	di			; save RepeatStruct item #
		call	GP_DBLockDerefDI	; RepeatStruct => ES:DI
		mov	si, di
		ChunkSizePtr es, di, bx		
		add	bx, di			; BX => offset to the end of
						;       the RepeatStruct
		add	di, es:[di].RES_dataLength
		sub	di, (size RepeatDateException)
findDateLoop:
		add	di, (size RepeatDateException)
		cmp	di, bx
		jae	notFound
		cmp	{word} es:[di].RDE_day, dx
		jne	findDateLoop
		cmp	es:[di].RDE_year, bp
		jne	findDateLoop
		sub	di, si			; DI => offset into RepeatStruct
						;       for exception structure
		call	DBUnlock
	;
	; Delete the exception structure
	;
		mov	cx, (size RepeatDateException)
		mov	dx, di
		pop	di
		call	GP_DBDeleteAt
	;		
	; Finally, update the RepeatYearTable. We want to have this
	; repeating event occur, so we *add* the event to the year table
	;
		pop	dx			;  DX = day/month
		mov	si, offset AddNewEvent
		call	GenerateFixupException
		clc
done:
		.leave
		ret

	;
	; The date in question was not found among the array of
	; RepeatDateException structures at the end of the RepeatStruct
	;
notFound:
EC <		ERROR_A	REPEAT_ILLEGAL_EXCEPTION_STRUCTURE		>
		call	DBUnlock
		pop	ax, dx			; restore regs
		stc
		jmp	done
RepeatDeleteExceptionDate	endp
endif

RepeatCode	ends

