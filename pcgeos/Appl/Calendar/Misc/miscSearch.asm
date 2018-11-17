COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Misc
FILE:		miscSearch.asm

AUTHOR:		Don Reeves, March 14, 1990

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/14/89		Initial revision
	Don	10/18/92	Re-written for 2.0

DESCRIPTION:
	Implements the pattern match code, and support routines. The search
	routine is stolen from Ted's Rolodex.
		
	In order to understand searching in the GeoPlanner, it is important
	to understand the two search objects, and how the searching is
	actually accomplished.

	1) There is a MySearch object, which conducts the actual search in
	   a daily-sequential manner. Searches are begun on the first day
	   in the Event Window, and continued through the end of one year
	   past the date of the last normal event. The MySearch object is
	   running in GeoPlanner's thread.

	2) The DayPlan object is used to load the actual events, both normal
	   and repeating, to ensure that they are searched in the proper
	   order. The MySearch object then simply goes through this table
	   of events for each day until a match is found, or the necessary
	   range of dates has been searched. 

	3) To optimize the spped of searching, both of the low level routines
	   which fetch events from the database return the next offset (date)
	   for which events can be found for that year. In this way, at most
	   one search is conducted for an emtpy year, and empty dates can
	   only be searched at the beginning of a year, or at the beginning
	   of a search.

	4) A flag is shared between the two search objects, to facilitate
	   the cessation of searches already in progress. The flag can only
	   be set in the UI thread, and only cleared & read in the GeoPlanner
	   thread.

	$Id: miscSearch.asm,v 1.1 97/04/04 14:48:37 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata	segment
	searchInfo	SearchInfo	mask SI_RESET
	MySearchClass
	CalendarSRCClass
idata	ends



SearchCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSRCMetaTextUserModified
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that the search text has been modified, so when we
		start searching again we'll know to reset our state

CALLED BY:	GLOBAL (MSG_META_TEXT_USER_MODIFIED)

PASS:		ES	= DGroup
		*DS:SI	= CalendarSRCClass object
		DS:DI	= CalendarSRCClassInstance
		CX:DX	= Text object that was dirtied

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/13/94		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarSRCMetaTextUserModified	method dynamic	CalendarSRCClass,
						MSG_META_TEXT_USER_MODIFIED
	;
	; Just set the reset flag, and call our superclass
	;
		or	es:[searchInfo], mask SI_RESET
		mov	di, offset CalendarSRCClass
		GOTO	ObjCallSuperNoLock
CalendarSRCMetaTextUserModified	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MySearchStartSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Start the search on the current year/month/day

CALLED BY:	GLOBAL (MSG_SEARCH)

PASS:		DS:*SI	= MySearchClass instance data
		DS:DI	= MySearchClass specific instance data
		ES	= DGroup
		DX	= SearchReplaceStruct memory handle

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/18/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MySearchStartSearch	method	dynamic	MySearchClass,	MSG_SEARCH
	.enter

	; Perform any initialization work necessary
	;
	mov	bx, dx
	call	MemLock				; lock the search data block
	mov	ds:[di].MSI_searchData, bx	; ...and store it away
	test	es:[searchInfo], mask SI_RESET
	jz	searchLoop			; if no reset, don't initialize
	call	SearchInit

	; Now enter into a search loop
searchLoop:
	call	SearchCurrentDay		; search the current day
	jc	done				; successful, so we're done
	call	SearchUpdateNext		; go to the next day
	jnc	searchLoop			; if no error, continue

	; Clean up the search data block
done:
	mov	bx, ds:[di].MSI_searchData
	call	MemFree

	.leave
	ret
MySearchStartSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform any initialization work for a search

CALLED BY:	MySearchStart

PASS:		ES	= DGroup
		*DS:SI	= MySearchClass objext
		DS:DI	= MySearchInstance

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/18/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchInit	proc	near
	class	MySearchClass
	.enter
	
	; Perform some initialization work
	;
	mov	ds:[di].MSI_eventOffset, size EventTableHeader
	mov	ds:[di].MSI_matchOffset, 0
	and	es:[searchInfo], not (mask SI_WRAPPED or \
				      mask SI_MATCHED or \
				      mask SI_RESET)

	; Tell the text object in SearchReplaceControl to set its
	; state to be clean, so we'll know if the user changes the
	; search text
	;
	push	si				; save the MySearch handle
	mov	ax, MSG_VIS_TEXT_SET_NOT_USER_MODIFIED
	mov	bx, segment VisTextClass
	mov	si, offset VisTextClass
	mov	di, mask MF_RECORD
	call	ObjMessage
	mov	bp, di				; event handle => BP
	mov	ax, MSG_SRC_SEND_EVENT_TO_SEARCH_TEXT
	GetResourceHandleNS	CalendarSearch, bx
	mov	si, offset CalendarSearch
	call	ObjMessage_search_call
	pop	si				; restore MySearch handle

	; Force all the event data to be written-back to the database
	;
	push	si				; save the MySearch handle
	mov	ax, MSG_DP_UPDATE_ALL_EVENTS
	call	MySearchCallDayPlan		; send the method

	; Call the DayPlan to get the current date
	;
	mov	ax, MSG_DP_GET_RANGE		; access the range
	call	MySearchCallDayPlan		; send the method
	pop	si				; restore the MySearch handle
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].MySearch_offset	; access the instance data
	mov	ds:[di].MSI_startYear, cx
	mov	ds:[di].MSI_currentYear, cx
	mov	ds:[di].MSI_startMonthDay, ax
	mov	ds:[di].MSI_currentMonthDay, ax

	; Get the first & last dates for data in the database. As we
	; may have only repeating events (but no normal events), we
	; ensure we always search to at least one year from the current date.
	;
	clr	cx
	call	DatabaseGetFirstLastDate	; first date => DH/DL/BP
	tst	bp				; any normal events ??
	jnz	storeFirst			; yes, so store the data away
	mov	dx, ds:[di].MSI_startMonthDay
	mov	bp, ds:[di].MSI_startYear
storeFirst:
	dec	bp				; go to prior year
	mov	ds:[di].MSI_firstMonthDay, dx
	mov	ds:[di].MSI_firstYear, bp

	mov	cx, 1
	call	DatabaseGetFirstLastDate	; last date => DH/DL/BP
	tst	bp				; any normal events ??
	jnz	storeLast			; yes, so store the data away
	mov	dx, ds:[di].MSI_startMonthDay
	mov	bp, ds:[di].MSI_startYear
storeLast:
	inc	bp				; go to next year
	mov	ds:[di].MSI_lastMonthDay, dx
	mov	ds:[di].MSI_lastYear, bp
	
	.leave
	ret
SearchInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchCurrentDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Continue the search from where we last left off

CALLED BY:	INTERNAL
	
PASS:		DS:*SI	= MySearchClass instance data
		DS:DI	= MySearchClass specific instance data
		ES	= DGroup

RETURN:		Carry	= Clear (no matches found in current day)
			- or -
		Carry	= Set (match was found)

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchCurrentDay	proc	near
	class	MySearchClass
	.enter

	; Some set-up work
	;
	call	SearchLoadEvents
	mov	bx, size EventTableHeader	; reset event offset
	xchg	bx, ds:[bp].MSI_eventOffset	; our last offset => BX

	; Now search the next event
searchLoop:
	cmp	bx, ds:[di].ETH_last		; any events today
	jae	done				; nope, so we're done
	mov	cx, ds:[di][bx].ETE_group
	mov	dx, ds:[di][bx].ETE_item
	clr	ax				; reset match offset
	xchg	ax, ds:[bp].MSI_matchOffset	; offset to start search => AX
	call	SearchSingleEvent		; search the event, dude
	jc	match				; if carry set, we're done
	add	bx, size EventTableEntry	; go to the next entry
	jmp	searchLoop			; looad again, dude

	; A match! Store some important information
match:
	mov	ds:[bp].MSI_eventOffset, bx	; store the last event
	mov	ds:[bp].MSI_matchOffset, ax	; store the match offset
	call	SearchSuccessful		; do all the real work
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].MySearch_offset	; access instance data
	inc	ds:[bp].MSI_matchOffset		; go to the next offset
	stc					; we've got a match
done:
	mov	di, bp				; instance data => DS:DI

	.leave
	ret
SearchCurrentDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchLoadEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get more events to be searched through

CALLED BY:	SearchCurrentDay
	
PASS:		DS:*SI	= MySearchClass object
		DS:DI	= MySearchInstance
		ES	= DGroup

RETURN:		DS:BP	= MySearchInstance
		DS:DI	= EventTable

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchLoadEvents	proc	near
	class	MySearchClass
	uses	bx, dx
	.enter
	
	; Get a day's worth of events loaded
	;
	push	si				; save the MySearch handle
	mov	ax, ds:[di].MSI_currentMonthDay
	mov	dx, ds:[di].MSI_currentYear
	mov	ds:[di].MSI_nextYear, dx	; store the next year
	mov	cx, ds:[di].MSI_eventTable
	sub	sp, size RangeStruct		; allocate structure on stack
	mov	bp, sp				; RangeStruct => SS:BP
	mov	ss:[bp].RS_startYear, dx
	mov	ss:[bp].RS_endYear, dx
	mov	{word} ss:[bp].RS_startDay, ax
	mov	{word} ss:[bp].RS_endDay, ax
	mov	ax, MSG_DP_SEARCH_DAY
	call	MySearchCallDayPlan		; next offset => DX
	add	sp, size RangeStruct		; clean up the stack
	mov	bx, dx				; next offset => BX	
	call	TablePosToDateFar		; month/day => DX
	
	; Set-up things before we return
	;
	pop	si				; MySearch handle => SI
	mov	bp, ds:[si]			; derference the handle
	add	bp, ds:[bp].MySearch_offset	; access my instance data
	mov	di, ds:[bp].MSI_eventTable	; event table handle => DI
	mov	di, ds:[di]			; dereference the handle
	mov	ds:[bp].MSI_nextMonthDay, dx	; store the next month/day
	cmp	dh, 13				; past year table ??
	jl	done
	mov	ds:[bp].MSI_nextMonthDay, JAN_1
	inc	ds:[bp].MSI_nextYear
done:
	.leave
	ret
SearchLoadEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchSingleEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Given an event (either Repeat or Normal), see if the given
		pattern appears in the event.

CALLED BY:	INTERNAL

PASS:		ES	= DGroup
		DS:*SI	= MySearchClass instance data
		DS:BP	= MySearchClass specific instance data
		AX	= Offset to start search in text
		CX	= DB group for event (possibly or'ed with REPEAT_MASK)
		DX	= DB item for event

RETURN:		Carry	= Clear if no match
			- or -
			= Set if match
		AX	= Offset in string to match
		CX	= # of characters matched

DESTROYED:	DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/14/90		Initial version
	Don	10/17/90	Updated to reflect new search scheme

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CheckHack <(offset RES_data) - (offset RES_dataLength) eq \
           (offset ES_data) - (offset ES_dataLength)>

CheckHack <(offset ES_data) - (offset ES_dataLength) eq 2>

SearchSingleEvent	proc	near
	class	MySearchClass
	uses	bx, bp, di, si, ds, es
	.enter

	; Lock the event text
	;
	mov	di, dx				; item => DI
	mov_tr	dx, ax				; offset => DX
	mov	ax, cx				; group => CX
	and	ax, not REPEAT_MASK		; clear repeat bit if necessary
	call	GP_DBLockDerefDI		; lock the event
	add	di, ES_data			; access the data
	test	cx, REPEAT_MASK			; was it really a repeat event
	je	getPattern			; no - jump
	add	di, (RES_data - ES_data)	; access the repeat data

	; Lock down the pattern data
getPattern:
	mov_tr	ax, dx				; search offset => AX
	mov	bx, ds:[bp].MSI_searchData
	call	MemDerefDS
	mov	si, offset SRS_searchString	; string #2 => DS:SI
	mov	dx, es:[di-2]			; chars in string #1 => DX
	tst	dx				; look for NULL string
	jz	done				; if NULL, we're done (CF = 0)
	cmp	dx, INK_DATA_LENGTH		; if we have an Ink event
	je	done				; ...ensure we skip it
	mov	bp, di				; string #1 => ES:BP (start)
	mov	bx, di
	add	bx, dx
DBCS <	add	bx, dx				; char offset -> byte offset>
	LocalPrevChar	esbx			; string #1 => ES:BX (end)
	add	di, ax				; string #1 => ES:DI (search)
DBCS <	add	di, ax				; char offset -> byte offset>
	clr	cx				; string #2 is NULL-terminated
	mov	al, ds:[SRS_params]		; SearchOptions => AL
	or	al, mask SO_NO_WILDCARDS or \
		    mask SO_IGNORE_CASE or \
		    mask SO_PARTIAL_WORD
	call	TextSearchInString
	cmc					; want carry *set* for match

	; Clean up
done:
	call	DBUnlock			; unlock the event
	lahf					; save the flags
	sub	di, bp
DBCS <	shr	di, 1				; byte offset -> char offset>
	sahf					; restore the flags
	mov_tr	ax, di				; match offset (maybe) => DI

	.leave
	ret
SearchSingleEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchUpdateNext
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the next day to search. Deal with wrapping
		around to the beginning of the data.

CALLED BY:	MySearchStartSearch

PASS:		ES	= DGroup
		*DS:SI	= MySearchClass object
		DS:DI	= MySearchInstance

RETURN:		Carry	= Clear (keep on searching)
			- or -
		Carry	= Set (stop searching)

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/19/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchUpdateNext	proc	near
	uses	di, si
	.enter
	
	; Compare the next day with either the end of the data, or the
	; start of the search (if we've wrapped around).
	;
	mov	ax, ds:[di].MSI_nextMonthDay
	mov	bx, ds:[di].MSI_nextYear
	mov	cx, ds:[di].MSI_lastMonthDay
	mov	dx, ds:[di].MSI_lastYear
	test	es:[searchInfo], mask SI_WRAPPED
	jz	compare
	mov	cx, ds:[di].MSI_startMonthDay
	mov	dx, ds:[di].MSI_startYear
	dec	cx				; don't include first day
compare:
	cmp	bx, dx				; compare years
	jg	pastEnd
	jl	setNext
	cmp	ax, cx				; compare month/day's
	jg	pastEnd
setNext:
	mov	ds:[di].MSI_currentMonthDay, ax
	mov	ds:[di].MSI_currentYear, bx
	clc					; keep searching
done:
	.leave
	ret
	
	; We're past the end of time. See if we should wrap, or if we
	; truly are done searching.
pastEnd:
	test	es:[searchInfo], mask SI_WRAPPED
	jz	askUserToWrap
	test	es:[searchInfo], mask SI_MATCHED
	jnz	matched

	; We're done searching, and we didn't match
	;
	mov	bx, ds:[di].MSI_searchData
	call	MemLock
	push	es
	mov	es, ax
	mov	ax, es:[SRS_replyMsg]
	movdw	cxsi, es:[SRS_replyObject]	
	pop	es
	call	MemUnlock
	mov	bx, cx
	call	ObjMessage_search_send
	jmp	reallyDone			; we're done searching

	; We're done searching, but at least one match was found
matched:
	mov	bp, CAL_ERROR_SEARCH_DONE	; message => BP
	call	MySearchDisplayMessage		; display the message
	jmp	reallyDone			; we're done searching

	; Ask the user if we should wrap around or not
askUserToWrap:
	or	es:[searchInfo], mask SI_WRAPPED
	push	es, di
	mov	bp, ds:[di].MSI_lastYear	; year => BP
	segmov	es, ss, cx
	sub	sp, DATE_TIME_BUFFER_SIZE
	mov	di, sp				; ES:DI is the string buffer
	mov	dx, di				
	mov	cx, DTF_YEAR
	call	CreateDateString		; create a year string
	mov	bp, CAL_ERROR_END_OF_DB		; put up the proper string
	mov	cx, es				; CX:DX is the year string
	call	MySearchDisplayMessage		; ask the question
	add	sp, DATE_TIME_BUFFER_SIZE	; clean up the stack
	pop	es, di
	cmp	ax, IC_YES			; compare with affirmative
	mov	ax, ds:[di].MSI_firstMonthDay
	mov	bx, ds:[di].MSI_firstYear
	je	setNext
reallyDone:
	or	es:[searchInfo], mask SI_RESET	; reset search next time
	stc					; indicate end of search
	jmp	done
SearchUpdateNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SearchSuccessful
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	We have found a match.  Load the events for this day, etc..

CALLED BY:	SearchEvent

PASS:		ES	= Dgroup
		DS:*SI	= MySearchClass instance data
		DS:BP	= MySearchClass specific instance data
		DS:DI	= EventTable
		BX	= Offset in table
		CX	= # of characters matched

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/17/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SearchSuccessful	proc	near
	class	MySearchClass
	uses	si
	.enter

	; A match!  Store today's date information, etc...
	;
EC <	VerifyDGroupES				; verify ES		>
	or	es:[searchInfo], mask SI_MATCHED
	push	cx				; save # of characters matched
	push	si				; save the MySearch handle
	mov	cx, ds:[di][bx].ETE_year
	mov	ax, {word} ds:[di][bx].ETE_day
	push	ds:[di][bx].ETE_group		; group on the stack
	push	ds:[di][bx].ETE_item		; item on the stack

	; Ensure all the events are visible
	;
	push	ax, cx
	mov	ax, MSG_DP_ENSURE_EVENTS_VISIBLE
	call	MySearchCallDayPlan
	pop	ax, cx

	; Bring up the day holding the matched event
	;
	sub	sp, size RangeStruct
	mov	bp, sp				; structure => SS:BP
	mov	{word} ss:[bp].RS_startDay, ax	; set the start month/day
	mov	{word} ss:[bp].RS_endDay, ax	; and the end month/day
	mov	ss:[bp].RS_startYear, cx
	mov	ss:[bp].RS_endYear, cx
	GetResourceHandleNS	Interface, bx
	mov	si, offset Interface:YearObject
	mov	ax, MSG_YEAR_SET_SELECTION
	mov	dx, size RangeStruct
	mov	di, mask MF_STACK or mask MF_CALL
	call	ObjMessage_search
	add	sp, size RangeStruct
	mov	ax, MSG_DP_SET_RANGE		; set the DayPlan's display
	call	MySearchCallDayPlan		; send the method

	; Find the selected event
	;
	pop	cx, dx				; group, item => CX:DX
	mov	ax, MSG_DP_ETE_FIND_EVENT	; let's find the event
	call	MySearchCallDayPlan		; send the method
	pop	di				; MySearch handle => DI
	pop	dx				; # of characters matched => DX
	jnc	done				; if clear, event not found

	; Now select the matching text
	;
	mov	cx, bp				; offset => CX
	sub	sp, size ForceSelectArgs
	mov	bp, sp
	mov	di, ds:[di]			; dereference the handle
	add	di, ds:[di].MySearch_offset	; access instance data
	mov	ss:[bp].FSA_callBack, 0		; must zero this out
	mov	ss:[bp].FSA_message, MSG_DE_SELECT_TEXT
	mov	ax, ds:[di].MSI_matchOffset	; start select
	mov	ss:[bp].FSA_dataCX, ax
	add	ax, dx				; end select
	mov	ss:[bp].FSA_dataDX, ax
	mov	ax, MSG_DP_FORCE_SELECT
	call	ObjMessage_search_send		; else select the event
	add	sp, size ForceSelectArgs
done:
	.leave
	ret
SearchSuccessful	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MySearchDisplayMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the normal Calendar error routine

CALLED BY:	MySearchNext
	
PASS:		BP	= CalErrorValue
		DS, ES	= Relocatable block segments

RETURN:		AX, CX, DX, BP

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MySearchDisplayMessage	proc	near
	call	GeodeGetProcessHandle		; process handle => BX
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	GOTO	ObjMessage_search_call		; send the method
MySearchDisplayMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MySearchCallDayPlan
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the DayPlan with the passed method & data

CALLED BY:	INTERNAL
	
PASS:		AX	= Method
		CX, DX, BP = Data

RETURN:		AX, CX, DX, BP = Return values
		BX:SI	= DayPlanObject

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/17/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MySearchCallDayPlan	proc	near
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	GOTO	ObjMessage_search_call
MySearchCallDayPlan	endp

ObjMessage_search_send	proc	near
	clr	di
	GOTO	ObjMessage_search
ObjMessage_search_send	endp

ObjMessage_search_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	FALL_THRU	ObjMessage_search
ObjMessage_search_call	endp

ObjMessage_search	proc	near
	call	ObjMessage
	ret
ObjMessage_search	endp
	
SearchCode	ends
