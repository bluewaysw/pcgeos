COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Repeat
FILE:		repeatTable.asm

AUTHOR:		Don Reeves, Dec 20, 1989

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial revision

DESCRIPTION:
	Maintain the YearRepeat tables, which store all the 
	occurrences of every repeat event for that year.
		
	$Id: repeatTable.asm,v 1.1 97/04/04 14:48:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CommonCode	segment	resource

OVERFLOW	= 0x0001			; overflow mask


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetMonthMapRepeats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the MonthMap for Repeat Events for the specified month

CALLED BY:	DatabaseGetMonthMap
	
PASS:		ES	= DGroup
		BP	= Year
		DH	= Month
	
RETURN:		CX:DX	= MonthMap

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetMonthMapRepeats	proc	near
	uses	ax, bx, si, ds, es
	.enter

	; Get the YearMap, and call to create the month map
	;
	segmov	ds, es, ax			; DGroup => DS
	call	GenerateRepeat			; generate events for this year
	mov	bx, ds:[tableHandle]		; table handle => BX
	mov	si, ds:[tableChunk]		; table chunk => SI
	call	MemLock				; lock the block
	mov	es, ax				; RepeatMap => ES:*SI
	mov	si, es:[si]			; dereference the chunk handle
	call	CreateMonthMap			; MonthMap => CX:DX
	call	MemUnlock			; unlock the block

	.leave
	ret
GetMonthMapRepeats	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetRangeOfRepeats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get repeat events for the given range

CALLED BY:	GLOBAL

PASS:		SS:BP	= EventRangeStruct
		DS	= Relocatable segment, DS:0 = block handle
		ES	= DGroup

RETURN:		Carry	= Set if aborted
			= Clear if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version
	Don	4/8/90		Changed to use LMem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetRangeOfRepeats	proc	far
	uses	ax, bx, cx, dx, si, di
	.enter

	; Some set-up work
	;
	push	ds:[LMBH_handle]		; save the block handle
	segmov	ds, es				; DGroup to DS
	mov	bx, bp				; EventRangeStruct to BX
	mov	bp, ss:[bx].ERS_startYear	; get the desired year
EC <	cmp	bp, ss:[bx].ERS_endYear		; same year		>
EC <	ERROR_NZ REPEAT_GET_EVENTS_DIFFERENT_YEARS			>
	call	GenerateRepeat			; generate the events
	mov	bp, bx				; EventRangeStruct back to BP

	; Now set up to send Repeat Events to the DayPlan
	;
	mov	bx, ds:[tableHandle]		; table handle => BX
	mov	si, ds:[tableChunk]		; table chunk => DI
	call	MemLock				; lock the block
	mov	es, ax				; ES:*DI is the RepeatTable
	mov	dx, {word} ss:[bp].ERS_endDay
	call	DateToTablePos
	push	bx				; save the last offset
	mov	dx, {word} ss:[bp].ERS_startDay
	call	DateToTablePos			; first position => BX
	pop	dx				; lastr offset => DX
	jmp	midLoop				; start looping
	
	; Now loop through the table
	;
tableLoop:
	mov	cx, es:[di]			; get value of position
EC <	tst	cx				; any ID or handle ??	>
EC <	ERROR_Z	GET_RANGE_OF_REPEATS_BAD_MAP_ITEM			>
	test	cx, OVERFLOW			; OVERFLOW bit set ?
	je	notOverflow			; no - easy case
	and	cx, (not OVERFLOW)		; clear the OVERFLOW bit
	call	GetOverflowEvents		; load all these events
	jmp	next
notOverflow:
	call	RepeatLoadEvent			; load the event into the DP

	; Find the next entry by scanning, unless curtailed by carry set
	;
next:
	jc	done				; if carry set, abort
	add	bx, 2				; go to the next entry
midLoop:
	clr	ax				; comparison value => AX
	mov	di, es:[si]			; dereference the table handle
	mov	cx, YearMapSize			; raw size of the table
	add	di, bx				; go to current offset
	sub	cx, bx				; bytes left in table = CX
	shr	cx				; want it in words!
	repz	scasw				; look for non-zero value
	jz	calcOffset			; if over array, don't back up
	sub	di, 2				; account for overscan
calcOffset:
	mov	bx, di				; memory offset => BX
	sub	bx, es:[si]			; table offset => BX
	cmp	bx, dx				; else check past bounds
	jle	tableLoop			; within bounds - continue

	; Clean up (carry flag must be preserved)
done:
	pushf					; save the carry flag
	cmp	bx, ss:[bp].ERS_nextOffset	; compare with existing offset
	jge	postDone			; if not sooner, do nothing
	mov	ss:[bp].ERS_nextOffset, bx	; store the next offset 
postDone:
	mov	bx, es:[LMBH_handle]		; block handle => BX
	call	MemUnlock			; unlock the block
	segmov	es, ds				; DGroup back to DS
	popf					; restore the carry flag
	pop	bx				; restore the block handle
	call	MemDerefDS			; restore segment to DS

	.leave
	ret
GetRangeOfRepeats	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GetOverflowEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Cause all RepeatEvents in the Overflow table to be loaded

CALLED BY:	GetRangeOfRepeats

PASS:		ES:*CX	= Overflow table
		BX	= Table offset
		SS:BP	= EventRangeStruct

RETURN:		Carry	= Set if aborted
			= Clear if not

DESTROYED:	CX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version
	Don	7/13/90		Change register usage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GetOverflowEvents	proc	near
	uses	ax, si
	.enter

	; Loop through the events
	;
	mov	di, cx				; item to DI
	mov	si, es:[di]			; dereference the handle
	mov	ax, es:[si]			; store the size in AX
	clr	si				; initalize the counter

loadLoop:
	add	si, 2				; go to next entry
	cmp	si, ax				; check the size
	je	done	
EC <	ERROR_G	REPEAT_GET_OVERFLOW_BAD_OFFSET				>
	add	si, es:[di]			; SI now holds absolute address
	mov	cx, es:[si]			; obtain the RepeatID
	sub	si, es:[di]			; SI now holds offset
	tst	cx				; is the overflow zero ??
	jz	loadLoop			; jump if zero
	call	RepeatLoadEvent			; else load the repeat event
	jnc	loadLoop			; if carry clear, continue
done:
	.leave
	ret
GetOverflowEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateRepeat
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Generate all the repeating events for a year

CALLED BY:	GLOBAL

PASS: 		BP	= Year of generation
		DS	= DGroup
		
RETURN:		Nothing

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenerateRepeat	proc	far
	uses	ax, bx, cx, dx, di, si
	.enter

	; Some set-up work
	;
	call	EnterRepeat			; enter the repeat routines
	jnc	exit				; if clear, events already gen
	mov	ax, ds:[repeatMapGroup]
	mov	di, ds:[repeatMapItem]
	call	GP_DBLockDerefSI		; lock the RepeatMap
	mov	cx, es:[si].RMH_size		; get the size of the table
	mov	bx, (size RepeatMapHeader) - (size RepeatMapStruct)
	jmp	next

	; Now loop through all of the RepeatEvents
	;
genLoop:
	mov	dx, es:[si][bx].RMS_item	; get the Repeat item #
	tst	dx				; a non-event ??
	je	next
	call	GenerateParse			; parse it, dude
	mov	si, es:[di]			; dereference the handle
next:
	add	bx, size RepeatMapStruct	; go to the next RepeatEvent
	cmp	bx, cx				
	jl	genLoop				; continue until through table
	call	DBUnlock			; unlock the block
exit:
	.leave
	ret
GenerateRepeat	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateRepeatYearTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a year table

CALLED BY:	EnterRepeat

PASS:		Nothing

RETURN:		CX:DX	= RepeatTable OD

DESTROYED:	ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/20/89	Initial version
	Don	4/6/90		Changed to LMem allocation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CreateRepeatYearTable	proc	near
	uses	ax, bx, ds
	.enter

	; Allocate the LMem block
	;
	mov	ax, YearMapSize+50	; bytes to allocate
	mov	cl, mask HF_SWAPABLE
	mov	ch, mask HAF_LOCK or mask HAF_NO_ERR
	call	MemAlloc			; allocate the memory
	mov	ds, ax				; segment => DS
	call	RepeatInitTable			; initalize a table

	.leave
	ret
CreateRepeatYearTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ClearRepeatYearTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Clear the RepeatTable

CALLED BY:	GLOBAL

PASS: 		CX:DX	= RepeatTable OD

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	4/6/90		Changed to LMem stuff
	sean	2/7/96		Got rid of code to DerefES

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ClearRepeatYearTable	proc	near
	uses	ax, bx, ds
	.enter

	; Basically, just restart the heap
	;
	mov	bx, cx				; handle => BX
	call	MemLock				; lock the block
	mov	ds, ax
	call	RepeatInitTable			; re-initialize the table

	.leave
	ret
ClearRepeatYearTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RepeatInitTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create an LMem heap and allocate an empty table chunk

CALLED BY:	CreateRepeatYearTable, ClearRepeatYearTable

PASS:		DS	= Segment of locked LMem block
		BX	= LMem block handle

RETURN:		CX:DX	= RepeatTable OD

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RepeatInitTable	proc	near
	uses	bp, di, si
	.enter

	; Initalize the heap
	;
	mov	ax, LMEM_TYPE_GENERAL		; a general type of heap
	mov	cx, 10				; allocate ten handles
	mov	dx, size LMemBlockHeader	; offset at which to begin heap
	mov	si, YearMapSize + 30		; initial heap size in bytes
	clr	bp				; allocate end of block
	clr	di				; LocalMemoryFlags
	call	LMemInitHeap			; initialize the heap

	; Now allocate the actual table item
	;
	mov	cx, YearMapSize			; bytes to allocate
	call	LMemAlloc			; allocate the table
	mov	dx, ax				; table chunk => DX

	; Now initialize the table
	;
	mov	si, ax
	segmov	es, ds, ax			; ES:*SI is the table
	mov	si, es:[si]			; dereference the handle
	call	ClearSomeBytes			; clear those bytes
	call	MemUnlock			; unlock the table block
	mov	cx, bx				; table handle  => CX

	.leave
	ret
RepeatInitTable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenerateAddEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add an event to the RepeatTable

CALLED BY:	Generate - GLOBAL

PASS:		DS	= DGroup
		ES:*DI	= RepeatStruct
		DH	= Month
		DL	= Day

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Keep a table of words, 384 = 12 months by 32 word each
		If just one repeat event, word value is Repeat ID with the
			low bit is set.
		Else value is an item #, containing a list of repeat events
			for that day. Format for the list:
				1st word: Size of list (in bytes)
				2nd word: 1st Repeat ID
				3rd word: 2nd Repeat ID
				...
		A value of zero in either the table or list indicates no
		Repeat ID Present.
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	4/7/90		Update to use LMem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_REPEAT_DATE_EXCEPTIONS
GenerateAddEventFar	proc	far
	call	GenerateAddEvent
	ret
GenerateAddEventFar	endp
endif

GenerateAddEvent	proc	near
	uses	ax, bx, cx, dx, bp, si, di
	.enter

	; Now add (or delete) the sucker
	;
	push	es:[LMBH_handle]		; save this handle
	push	ds				; save DGroup
	mov	bx, ds:[tableHandle]		; table handle => BX
	call	MemLock				; lock the table
	call	DateToTablePos			; calc table position => BX
	mov	si, es:[di]			; dereference the handle
	mov	dx, es:[si].RES_ID		; get the ID
	mov	es, ax				; setup this segment
	mov	di, ds:[tableChunk]		; chunk handle => DI
	mov	si, ds:[repeatGenProc]		; generate routine => SI
	mov	ds, ax				; setup this segment also
	call	si				; call either AddNewEvent
						; ...or RemoveEvent

	; We're done
	;
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	call	MemUnlock			; unlock the block
	pop	ds				; restore the DGroup segment
	pop	bx				; restore the LMem handle
	call	MemDerefES			; and dereference it

	.leave
	ret
GenerateAddEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddNewEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Adds the event to the bleeping table

CALLED BY:	GenerateAddEvent

PASS:		DS:*DI	= RepeatTable
		ES:*DI	= RepeatTable
		BX	= Offset
		DX	= Repeat ID

RETURN:		Nothing

DESTROYED:	BX, CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	4/7/90		Update to use LMem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddNewEvent	proc	near

	; Determine how to add the event
	;
	mov	si, ds:[di]			; dereference the handle
	add	si, bx				; go to correct entry
	test	{word} ds:[si], 0xffff		; an empty event ??
	je	Easy				; 1st event - jump
	test	{word} ds:[si], OVERFLOW	; check the low bit
	jne	Overflow

	; Must add a new overflow event
	;
	push	dx				; save the RepeatID
	push	ds:[si]				; save the old Repeat ID
	mov	bp, di				; move the RepeatTable chunk
	mov	cx, 10				; initial size
	call	LMemAlloc			; allocate another chunk
	mov	si, ds:[bp]			; dereference the handle
	add	si, bx				; go to the correct entry 
	mov	ds:[si], ax			; store the item #
	or	{word} ds:[si], OVERFLOW	; set the OVERFLOW bit

	; Initialize the overflow block
	;
	mov	di, ax				; chunk handle => DI
	mov	si, ds:[di]			; dereference the handle
	call	ClearSomeBytes	
	mov	{word} ds:[si], 10		; its size
	pop	ds:[si]+2			; restore the old RepeatID
	pop	ds:[si]+4			; restore the new RepeatID
	ret

	; A normal overflow event
	;
Overflow:
	push	di				; save the chunk handle
	mov	di, ds:[si]			; get the item #	
	and	di, not OVERFLOW		; clear the overflow bit
	call	AddOverflowEvent		; add the event
	pop	di				; restore the chunk handle
	ret
	
	; The first event - easy
	;
Easy:
	mov	es:[si], dx			; store that value
	ret
AddNewEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		AddOverflowEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Add a Repeat ID to the overflow list

CALLED BY:	AddNewEvent

PASS: 		DS:*DI	= Overflow table chunk
		ES:*DI	= Overflow table chunk
		DX	= Repeat ID to add

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/30/89	Initial version
	Don	4/7/90		Update to use LMem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

AddOverflowEvent	proc	near

	; Find an empty space
	;
	mov	bp, di				; chunk handle => BP
	mov	di, es:[di]			; ES:DI is the overflow table
	clr	ax				; initialize the count
	mov	cx, es:[di]			; chunk size => CX
	shr	cx, 1				; turn into words
	repne	scasw				; look for a zero
	jnz	addSpace			; if done, add space to chunk
	mov	es:[di-2], dx			; store the RepeatID
	ret

	; Add some open space
	;
addSpace:
	mov	di, es:[bp]			; ES:DI is the overflow table
	mov	bx, es:[di]			; old table size => BX
	mov	cx, bx
	add	cx, 10				; increase the size
	mov	ax, bp				; chunk handle => AX
	call	LMemReAlloc			; re-allocate the chunk
	mov	si, es:[bp]			; dererference the handle
	mov	es:[si], cx			; store the new size
	mov	cx, 10				; bytes to zero out
	add	si, bx				; start of new mem to SI
	call	ClearSomeBytes
	mov	es:[si], dx			; store the RepeatID

	.leave
	ret
AddOverflowEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove the event from the bleeping table

CALLED BY:	GenerateAddEvent

PASS:		ES:*DI	= RepeatTable chunk
		DS:*DI	= RepeatTable chunk
		BX	= Offset
		DX	= Repeat ID

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/20/89	Initial version
	Don	4/7/90		Update to use LMem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemoveEvent	proc	near

	; Determine how to delete the event
	;
	mov	si, es:[di]			; dereference the handle
	add	si, bx				; go to correct entry
	test	{word} es:[si], OVERFLOW	; check the low bit
	je	easy				; jump if bit not set!

	; An overflow event
	;
	push	di
	mov	di, es:[si]			; get the item #	
	and	di, not OVERFLOW		; clear the overflow bit
	call	RemoveOverflowEvent		; add the event
	pop	di
	jnc	done				; jump if overflow still exists
	mov	si, es:[di]			; dereference the handle
	mov	{word} es:[si][bx], 0		; clear the overflow table
done:
	ret
	
	; The first event - easy. When we have repeat date exceptions,
	; we can no longer assume that every day in the range of a
	; particular repeating event holds that repeat ID, so we
	; have no easy way of performing this sanity check (well, we
	; could compare today against any of the repeat date
	; exceptions, but we're lazy) - Don 2/13/96
easy:
if	not _REPEAT_DATE_EXCEPTIONS
EC <	cmp	dx, es:[si]			; check the word	>
EC <	ERROR_NZ REMOVE_EVENT_REPEAT_ID_NOT_FOUND			>
endif
	mov	{word} es:[si], 0		; clear the value
	ret
RemoveEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RemoveOverflowEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Remove a Repeat ID to the overflow list

CALLED BY:	RemoveEvent

PASS: 		ES:*DI	= Overflow table
		DS:*DI	= Overflow table
		DX	= Repeat ID to remove

RETURN:		Carry	= Set if overflow table is removed

DESTROYED:	DX, BP, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/30/89	Initial version
	Don	4/7/90		Update to use LMem stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RemoveOverflowEvent	proc	near

	; Find the repeat ID
	;
	mov	bp, di				; chunk handle => BP
	mov	di, es:[di]			; derefernce the handle
	mov	ax, dx				; Repeat ID => AX
	mov	cx, es:[di]			; table size => CX
	shr	cx, 1				; change to word count
	add	di, 2				; start at proper offset
	repne	scasw				; look for the ID

	; Before exception dates, if we did not find the Repeat ID, then
	; we knew the data structures were hosed. With the addition of
	; this wonderful feature, we can't be so sure. I also made the code
	; a bit more robust for the non-EC case. - Don 11/6/95
	;
if	not _REPEAT_DATE_EXCEPTIONS
EC <	ERROR_NZ	REMOVE_EVENT_REPEAT_ID_NOT_FOUND		>
endif
	jnz	exit
	mov	{word} es:[di-2], 0		; remove the repeat ID

	; Any events left in the table ??
	;
	mov	di, es:[bp]			; re-dereference the handle
	mov	cx, es:[di]			; table size => CX
	shr	cx, 1				; change to word count
	dec	cx				; account for count word
	add	di, 2				; start at proper offset
	clr	ax				; look for non-zero ID
	repe	scasw				; scan the string
	jz	nukeChunk			; if no ID's found, jump
exit:
	clc
	ret 

	; Else nuke the useless chunk
	;
nukeChunk:
	mov	ax, bp				; chunk handle => AX
	call	LMemFree			; free up the chunk
	stc
	ret
RemoveOverflowEvent	endp

CommonCode	ends



FileCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DestroyRepeatYearTable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destory a repeat year table

CALLED BY:	RepeatEnd

PASS:		CX:DX	= RepeatTable OD

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/7/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DestroyRepeatYearTable	proc	near
	uses	bx
	.enter

	mov	bx, cx				; handle => BX
EC <	call	ECCheckMemHandleNS		; verify the handle	>
	call	MemFree				; free up the block

	.leave
	ret
DestroyRepeatYearTable	endp

FileCode	ends



