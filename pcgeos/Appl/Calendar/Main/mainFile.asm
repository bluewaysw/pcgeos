COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Appl/Calendar
FILE:		mainFile.asm

AUTHOR:		Don Reeves, March 16, 1990

ROUTINES:
	Name				Description
	----				-----------
    MTD MSG_GEN_DOCUMENT_OPEN	Force My_Schedule into PRIVDATA for
				Responder

    MTD MSG_GEN_DOCUMENT_UPDATE_EARLIER_INCOMPATIBLE_DOCUMENT
				Handle updating of an earlier protocol file
				that is not compatible with the protocol of
				the document control.

    MTD MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE
				Opens a new file for the calendar

    INT CalendarWarnIfNotEnoughSpace
				Just like FoamWarnIfNotEnoughSpace, but the
				warning dialog is blocking.

 ?? INT CreateMemoNameArray	Creates the chunk array to hold the memo
				token/ memo names.

    INT CreateEventIDArray	Create array of event ID and event Gr:It
				pairs

 ?? INT ToDoListInit		Initializes the To Do list structures for
				the database

 ?? INT InitDummyEvent		Set up one dummy alarm list structure

    MTD MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT
				Create/enable all the UI for a document

    MTD MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT
				Destroys & disables any UI associated with
				an open document

    MTD MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT
				Destroy any UI associated with a document

    MTD MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE
				Load our "cache" with variables from the
				file we don't want to read in all the time.

    MTD MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE
				Force all changes to be written back to the
				file

    MTD MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
				Notify that a Save-As has ocurred

    INT ObjMessageDayPlan	Send via ObjMessage a message to the
				DayPlan or Year objects

    INT ObjMessageYear		Send via ObjMessage a message to the
				DayPlan or Year objects

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/16/89		Initial revision
	Don	12/17/91	Bring stuff into 2.0
	Richard	5/17/95		Add PrivDocOpen for Responder

DESCRIPTION:
	Responds to the methods necessary to implement the generic file
	operations defind by the GenDocumentControl.
		
	$Id: mainFile.asm,v 1.2 97/12/16 13:13:33 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

FileCode	segment	resource




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarInitializeDocumentFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Opens a new file for the calendar

CALLED BY:	UI (MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE)

PASS:		DS, ES	= DGroup
		CX:DX	= Document
		BP	= File handle

RETURN:		carry - set if error

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/16/90		Initial version
	simon	2/16/97		Create event ID array 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarInitializeDocumentFile	method	dynamic	GeoPlannerClass,
				MSG_META_DOC_OUTPUT_INITIALIZE_DOCUMENT_FILE
	.enter
	
	; Set the thread DB file - set the VM file attributes
	;
	mov	bx, bp				; file handle => BX
	mov	ds:[vmFile], bx			; store the VM file away
	clr	ah				; no bits to reset
        mov     al, mask VMA_NOTIFY_DIRTY or \
		    mask VMA_SYNC_UPDATE	; bits to set
        call    VMSetAttributes			; set-up the VM file

	; Create the header structure
	;
	call	DBGroupAlloc			; allocate a group
	mov	cx, size YearMapHeader		; get size of the header struct
	call	DBAlloc				; allocate a chunk
	call	DBSetMap			; this will be the map block
	mov	si, di				; store the item in SI
	mov	cx, size EventStruct
	call	DBAlloc				; allocate one dummy alarm
	push	di
	call	DBAlloc				; allocate another alarm
	xchg	di, si				; exchange header, dummy alarm
	call	DBLock				; lock the block
	mov	di, es:[di]			; dereference the handle
	pop	bx				; store 1st alarm

if	SEARCH_EVENT_BY_ID
	call	CreateEventIDArray		; make array to keep unique
						; ID and event Gr:It
endif
	; Now initialize the header structure
	;
	mov	{byte} es:[di].YMH_secure1, SECURITY1
	mov	{byte} es:[di].YMH_secure2, SECURITY2
	mov	es:[di].YMH_numYears, 0
	mov	es:[di].YMH_undoBufGr, 0
	mov	es:[di].YMH_undoBufIt, 0	; no inital undo buffer
	mov	es:[di].YMH_undoRmGroup, FALSE	; don't delete the group
	mov	es:[di].YMH_nextAlarmGr, ax	; store the next alarm group
	mov	es:[di].YMH_nextAlarmIt, si	; store the next alarm item
if	UNIQUE_EVENT_ID
	movdw	es:[di].YMH_nextEventID, FIRST_EVENT_ID
endif
	call	DBUnlock			; unlock the header (map)

	; Initialize the alarm structures
	;
	mov	di, si				; put second EventStruct to DI
	mov	cx, nil				; no next item
	mov	dx, HIGH_MONTH_DAY		; highest month, day
	mov	bp, HIGH_YEAR
	call	InitDummyEvent			; set the alarm up

	xchg	bx, cx				; nil <==> 1st handle
	xchg	cx, di				; 1st handle <==> 2nd handle
	clr	dx				; lowest month and day
	mov	bp, LOW_YEAR
	call	InitDummyEvent

if	_TODO
	; Initialize the To Do list stuff
	;	
	call	ToDoListInit
endif

	; Now initialize the repeating events stuff
	;
	call	RepeatInitFile
		
	clc

exit::
	.leave
	ret
CalendarInitializeDocumentFile	endp


if	SEARCH_EVENT_BY_ID


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CreateEventIDArray
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create array of event ID and event Gr:It pairs

CALLED BY:	(INTERNAL) CalendarInitializeDocumentFile
PASS:		es:di	= fptr to map block YearMapHeader
		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	simon   	2/16/97    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CreateEventIDArray	proc	near
		uses	bx, cx
		.enter
		Assert	dgroup	ds

		mov	bx, ds:[vmFile]
		Assert	vmFileHandle	bx
	;
	; Create a huge array first
	;
		push	di
		mov	cx, size EventIDArrayElemStruct
		clr	di			; no additional space
		call	HugeArrayCreate		; di = array handle
		mov	cx, di			; cx = array handle
		pop	di			; es:di = YearMapHeader

		Assert	fptr	esdi
		mov	es:[di].YMH_eventIDArray, cx

		.leave
		ret
CreateEventIDArray	endp

endif	; SEARCH_EVENT_BY_ID

if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ToDoListInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initializes the To Do list structures for the database

CALLED BY:	CalendarInitializeDocumentFile
PASS:		ds	= dgroup
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SS	3/ 6/95    	Initial version
	kho	5/03/96		Call GP_DBDirtyUnlock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ToDoListInit	proc	near
	uses	ax,bx,cx,dx,di,si,bp
	.enter

	; get map block
	;
        call    GP_DBLockMap                    ; get the map block, lock it
        mov     bx, di                          ; move the handle to BX

	; create the to do list group and map item
	;
        call    GP_DBGroupAlloc                 ; allocate a group
	mov	cx, size EventMapHeader
	call	GP_DBAlloc			; allocate the toDoListMap
	
	; store to do list stuff in year map header
	;
        mov     si, es:[bx]                     ; dereference the Map handle
        mov     es:[si].YMH_toDoListGr, ax     	; store the map group
        mov     es:[si].YMH_toDoListIt, di     	; and the map item
        call    GP_DBDirtyUnlock                ; unlock it

	; initialize to do list header info
	;
        mov     dx, di                          ; item # => DX
        call    GP_DBLockDerefSI                ; lock the map item
        mov     es:[si].EMH_item, dx           ; store the item #
        mov     es:[si].EMH_numEvents, 0       ; Zero items initially
        call    GP_DBDirtyUnlock               ; unlock the RepeatMap
	
	.leave
	ret
ToDoListInit	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitDummyEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up one dummy alarm list structure

CALLED BY:	CalendarInitializeDocumentFile

PASS:		AX	= Group #
		BX	= Prev item #
		CX	= Next item #
		DX	= Month/Day to use
		BP	= Year to use
		DI	= Item #

RETURN:		Nothing

DESTROYED:	BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitDummyEvent	proc	near
	uses	di
	.enter

	; Stuff some data
	;
	call	GP_DBLockDerefDI
	mov	es:[di].ES_parentMap, nil	; no parent map
	mov	es:[di].ES_timeYear, bp
	mov	{word} es:[di].ES_timeDay, dx
	mov	{word} es:[di].ES_timeMinute, 0
	mov	es:[di].ES_alarmYear, bp
	mov	{word} es:[di].ES_alarmDay, dx
	mov	{word} es:[di].ES_alarmMinute, 0
	
	; Set the alarm linkage
	;
	mov	es:[di].ES_alarmPrevGr, ax
	mov	es:[di].ES_alarmPrevIt, bx	; store the previous item
	mov	es:[di].ES_alarmNextGr, ax
	mov	es:[di].ES_alarmNextIt, cx	; store the next item

if	UNIQUE_EVENT_ID
	movdw	es:[di].ES_uniqueID, INVALID_EVENT_ID
endif

if	HANDLE_MAILBOX_MSG
	clr	es:[di].ES_sentToArrayBlock
	clr	es:[di].ES_sentToArrayChunk
	clr	es:[di].ES_nextBookID
endif
	; On of the groups is NIL. Which one?
	;
	mov	bp, offset ES_alarmPrevGr	; assume this group
	cmp	bx, nil				; is previous item # nil ?
	je	setGroupNil			; yes, so set group # nil
	mov	bp, offset ES_alarmNextGr	; else uses next group #
setGroupNil:
	mov	{word} es:[di][bp], nil
	call	DBUnlock			; unlock the item

	.leave
	ret
InitDummyEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                CalendarVMFileDirty
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:       Deal with the current document being marked dirty

CALLED BY:      MSG_META_VM_FILE_DIRTY (from VM code in the kernel)

PASS:           DS      = dgroup
                CX      = our file handle open to the document file

RETURN:         Nothing

DESTROYED:	AX, BX, SI, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
        Name    Date            Description
        ----    ----            -----------
        ardeb   3/9/90		Initial version
	don	9/1/90		Added clearing of SF_CLEAN_VM_FILE flag

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarVMFileDirty	method GeoPlannerClass,	MSG_META_VM_FILE_DIRTY
	.enter

	; Pass this on to the application document control
	;
	test	ds:[systemStatus], SF_VALID_FILE	; are we exiting ??
	jz	done					; yes, so ignore
	and	ds:[systemStatus], not SF_CLEAN_VM_FILE	; clear this flag
	GetResourceHandleNS	CalendarDocumentGroup, bx
	mov	si, offset CalendarDocumentGroup
	mov	ax, MSG_GEN_DOCUMENT_GROUP_MARK_DIRTY_BY_FILE
	clr	di
	call	ObjMessage
done:
	.leave
	ret
CalendarVMFileDirty endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarAttachUIToDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create/enable all the UI for a document

CALLED BY:	UI (MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT)

PASS:		DS, ES	= DGroup
		CX:DX	= Document
		BP	= File handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/16/90		Initial version
	sean	7/20/95		Added AlarmClockTick
	sean	4/25/96		Took out AlarmClockTick

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarAttachUIToDocument	method	dynamic	GeoPlannerClass,
				MSG_META_DOC_OUTPUT_ATTACH_UI_TO_DOCUMENT
	.enter

	; Do some initialization work
	;
	mov	ds:[vmFile], bp			; store the VM file away
	or	ds:[systemStatus], SF_VALID_FILE

	; Start the repeat event stuff
	;
	call	RepeatStart			; start the repeat stuff

	; Tell the DayPlan to make its UI available
	;
	mov	ax, MSG_DP_FILE_OPEN
	clr	di
	call	ObjMessageDayPlan

	
	.leave
	ret
CalendarAttachUIToDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarDetachUIFromDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroys & disables any UI associated with an open document

CALLED BY:	UI (MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT)

PASS:		DS, ES	= DGroup
		CX:DX	= Document
		BP	= File handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarDetachUIFromDocument	method	dynamic	GeoPlannerClass,
				MSG_META_DOC_OUTPUT_DETACH_UI_FROM_DOCUMENT 
	.enter

	; No valid file
	;
	and	ds:[systemStatus], not SF_VALID_FILE
	call	UndoNotifyClear			; clear the undo stuff

	; Force the DayPlan to update the current events
	;
	mov	ax, MSG_DP_FILE_CLOSE
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessageDayPlan

	; Clean up the Repeating event stuff
	;
	call	RepeatStop			; end the repeat stuff

	; Force the Months to update their MonthMaps
	;
	mov	ax, MSG_YEAR_CHANGE_MONTH_MAP
	clr	bp				; all months must change
	clr	di
	call	ObjMessageYear

	; Done with file
	;   This used to be at the beginning of the handler, but
	;   due to some changes (possibly for Responder), clearing
	;   the file that early caused death due to illegal handle
	;   as things still tried to access it. eca 12/15/97
	;
	clr	ds:[vmFile]

	.leave
	ret
CalendarDetachUIFromDocument	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarDestroyUIForDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destroy any UI associated with a document

CALLED BY:	GLOBAL (MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT)

PASS:		*DS:SI	= GeoPlannerClass object
		DS:DI	= GeoPlannerClassInstance

RETURN:		Nothing

DESTROYED:	CX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/12/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarDestroyUIForDocument	method dynamic	GeoPlannerClass,
				MSG_META_DOC_OUTPUT_DESTROY_UI_FOR_DOCUMENT
	.enter

	; We need to destroy all reminder (alarm) windows, else
	; they could attempt to reference invalid data in a new file
	; Also, we don't want old alarms displayed for a new file
	; that is opened.
	;
	mov	cx, -1
	call	AlarmCheckActive		; destroy all reminders

	.leave
	ret
CalendarDestroyUIForDocument	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarReadCachedDataFromFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load our "cache" with variables from the file we don't want
		to read in all the time.

CALLED BY:	UI (MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE)

PASS:		DS, ES	= DGroup
		CX:DX	= Document object
		BP	= File handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/16/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarReadCachedDataFromFile	method	dynamic	GeoPlannerClass,
				MSG_META_DOC_OUTPUT_READ_CACHED_DATA_FROM_FILE
	.enter

	; Read in or initialize any cached data
	;
	mov	ds:[vmFile], bp			; store the VM file away
	call	UndoReset			; initialize the undo code
	call	RepeatReset			; set-up any repeat vars
	call	AlarmClockReset			; reload the alarm clock data

	; Tell the DayPlan object to re-initialize itself
	;
	mov	ax, MSG_DP_RESET_UI
	clr	di
	call	ObjMessageDayPlan
	
	; Tell the Year to update any event displays
	;
	mov	ax, MSG_YEAR_CHANGE_MONTH_MAP
	clr	bp				; all months must change
	clr	di
	call	ObjMessageYear

	.leave
	ret
CalendarReadCachedDataFromFile	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarWriteCachedDataToFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force all changes to be written back to the file

CALLED BY:	UI (MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE)

PASS:		DS, ES	= DGroup
		CX:DX	= Document Object
		BP	= File handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		This should not get called if the file is not dirty!

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/16/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarWriteCachedDataToFile	method	dynamic	GeoPlannerClass,
				MSG_META_DOC_OUTPUT_WRITE_CACHED_DATA_TO_FILE
	.enter

	; Write out any cached data
	;
	call	UndoWrite
	call	AlarmClockWrite

	; Tell the DayPlan to write-back all events
	;
	mov	ax, MSG_DP_UPDATE_ALL_EVENTS
	mov	cl, BufferUpdateFlags<1, 1, 0>
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessageDayPlan

	.leave
	ret
CalendarWriteCachedDataToFile	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSaveAsCompleted
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Notify that a Save-As has ocurred

CALLED BY:	GLOBAL (MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED)

PASS:		DS, ES	= DGroup
		CX:DX	= GenDocument object
		BP	= VM file handle

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/23/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarSaveAsCompleted	method dynamic	GeoPlannerClass,
					MSG_META_DOC_OUTPUT_SAVE_AS_COMPLETED
		.enter

		mov	ds:[vmFile], bp			; store the VM file away

		.leave
		ret
CalendarSaveAsCompleted	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessageDayPlan, ObjMessageYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send via ObjMessage a message to the DayPlan or Year objects

CALLED BY:	INTERNAL

PASS:		AX		= Message
		CX, DX, BP	= Data

RETURN:		AX, CX, DX, BP	= Data returned by ObjMessage

DESTROYED:	BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/17/91	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessageDayPlan	proc	near
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	call	ObjMessage
	ret
ObjMessageDayPlan	endp

ObjMessageYear	proc	near
	GetResourceHandleNS	Interface, bx
	mov	si, offset Interface:YearObject	; YearObject => BX:SI
	call	ObjMessage			; send the method
	ret
ObjMessageYear	endp

FileCode	ends
