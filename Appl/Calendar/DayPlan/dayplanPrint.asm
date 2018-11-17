COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayPlan
FILE:		dayplanPrint.asm

AUTHOR:		Don Reeves, May 27, 1990

ROUTINES:
	Name			Description
	----			-----------
	DayPlanPrint		High level print routine for EventWindow
	DayPlanPrintsetup	Internal setup for printing EventWindow
	DayPlanPrintDatesEvents	High level printing of events in a month
	DayPlanPrintSingleDate	High level printing of single date in month
	DayPlanPrintEngine	Medium level print routine for events
	DayPlanCreatePrintEvent	Creates a PrintEvent object used for printing
	DayPlanNukePrintEvent	Destroys the forementioned object
	DayPlanPrintAllEvents	Medium level routine to print built EventTable
	DayPlanPrintOneEvent	Low level print rouinte for a single event
	DayPlanPrepareDateEvent	Specialized routine to max space used in date
	DayPlanPrintEventCrossesPage
				Handles events that cross 1 or more pages
	DayPlanPrintCalcNextOffset
				Sub-routine for events that cross page boundary
	InitPagePosition	Simple routine to create new page

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/27/90		Initial revision


DESCRIPTION:
		
	$Id: dayplanPrint.asm,v 1.1 97/04/04 14:47:30 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanStartPrinting
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Responds to all printing requests from the PrintControl
		for event information.

CALLED BY:	GLOBAL (MSG_PRINT_START_PRINTING)
	
PASS:		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
		BP	= GState
		CX:DX	= PrintControl OD

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanStartPrinting	method	DayPlanClass,	MSG_PRINT_START_PRINTING
	.enter

	; Some set-up work
	;
	push	cx, dx				; save the SPC OutputDesc.
	call	DayPlanPrintSetup		; => CX:DX width, height
	sub	sp, size PrintRangeStruct	; allocate this structure
	mov	bx, sp				; PrintRangeStruct => SS:BX
	mov	ss:[bx].PRS_width, cx
	mov	ss:[bx].PRS_height, dx
	mov	ss:[bx].PRS_gstate, bp		; store the GState
	mov	ss:[bx].PRS_pointSize, 12	; twelve point text
	mov	ss:[bx].PRS_specialValue, 2	; normal event printing
	mov	dx, ds:[di].DPI_startYear
	mov	ss:[bx].PRS_range.RS_startYear, dx
	mov	dx, ds:[di].DPI_endYear
	mov	ss:[bx].PRS_range.RS_endYear, dx
	mov	dx, {word} ds:[di].DPI_startDay	
	mov	{word} ss:[bx].PRS_range.RS_startDay, dx
	mov	dx, {word} ds:[di].DPI_endDay	
	mov	{word} ss:[bx].PRS_range.RS_endDay, dx
	mov	ss:[bx].PRS_currentSizeObj, 0	; no handle allocated

	; Perform the actual printing
	;
	mov	cx, {word} ds:[di].DPI_flags	; DayPlanInfoFlags => CL
						; DayPlanPrintFlags => CH
	cmp	ds:[di].DPI_rangeLength, 1
	jne	doPrinting
	or	ch, mask DPPF_FORCE_HEADERS	; if 1 day, force a header
doPrinting:
	mov	bp, bx				; PrintRangeStruct => SS:BP
	mov	ax, MSG_DP_PRINT_ENGINE		; now do the real work
	call	ObjCallInstanceNoLock

	; End the page properly
	;
	mov_tr	dx, ax				; number of pages => DX
	mov	di, ss:[bp].PRS_gstate	
	mov	al, PEC_FORM_FEED
	call	GrNewPage
	add	sp, size PrintRangeStruct	; clean up the stack

	; Now clean up
	;
	pop	bx, si				; PrintControl OD => BX:SI
	mov	cx, 1
	mov	ax, MSG_PRINT_CONTROL_SET_TOTAL_PAGE_RANGE
	call	ObjMessage_print_send		; number of pages = (DX-CX+1)
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
	call	ObjMessage_print_send

	.leave
	ret
DayPlanStartPrinting	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintSetup
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets up the DayPlan for printing, and returns the print
		information.

CALLED BY:	INTERNAL - DayPlanStartPrinting
	
PASS:		DS:*SI	= DayPlanClass instance data
		ES	= DGroup
		CX:DX	= PrintControl OD
		BP	= GState to print with

RETURN: 	CX	= Usable width of document
		DX	= Usable height of document
		DS:DI	= DayPlanClass specific instance data

DESTROYED:	AX, BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/27/90		Initial version
	Don	6/28/90		Took out unnecessary calls

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanPrintSetup	proc	near
	.enter

	; Set the inital translation
	;
	mov	di, bp				; GState => DI
	call	InitPagePosition		; account for the page borders
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access the instance data
	mov	cx, es:[printWidth]
	mov	dx, es:[printHeight]

	.leave
	ret
DayPlanPrintSetup	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintDatesEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a date's worth of events - designed to work with
		printing events inside of a Calendar.
		
CALLED BY:	GLOBAL (MSG_DP_PRINT_DATES_EVENTS)
	
PASS:		DS:*SI	= DayPlanClass instance data
		ES	= DGroup
		SS:BP	= MonthPrintRangeStruct
		CL	= DOW of 1st day
		CH	= Last day in month

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/2/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanPrintDatesEvents	method	DayPlanClass,	MSG_DP_PRINT_DATES_EVENTS
	.enter

	; Some set-up work
	;
	push	ds:[di].DPI_rangeLength		; save the range length
	mov	ds:[di].DPI_rangeLength, 1	; to avoid header events
	or	es:[systemStatus], SF_PRINT_MONTH_EVENTS
	mov	dl, 7				; seven columns
	sub	dl, cl				; start at DOW
	mov	cl, 1				; start with 1st day in month
	mov	ax, mask PEI_IN_DATE		; PrintEventInfo => AX
	call	DayPlanCreatePrintEvent		; print event => DS:*BX
	mov	ss:[bp].PRS_currentSizeObj, bx	; store the handle
	jnc	printDates			; if carry clear, A-OK

	; Else ask the user what to do
	;
	push	cx, dx, bp			; save MonthPrintRangeStruct
	mov	bp, CAL_ERROR_EVENTS_WONT_FIT	; message to display
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	call	MemOwner			; process handle => BX
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	mov	di, mask MF_FIXUP_DS or mask MF_CALL
	call	ObjMessage
	pop	cx, dx, bp			; restore MonthPrintRangeStruct
	cmp	ax, IC_YES			; print empty month ?
	je	cleanUpOK			; yes
	mov	ax, MSG_PRINT_CONTROL_PRINTING_CANCELLED
	jmp	cleanUp
		
	; Draw the events, day by day
	;
printDates:
	mov	ax, ss:[bp].MPRS_newXOffset	; X position => AX
	mov	bx, ss:[bp].MPRS_newYOffset	; Y position => BX
anotherDay:
	mov	ss:[bp].MPRS_newXOffset, ax	; store the current X offset
	mov	ss:[bp].MPRS_newYOffset, bx	; store the current Y offset
	push	ax, bx, cx, dx			; save important data
	mov	ss:[bp].PRS_range.RS_startDay, cl
	mov	ss:[bp].PRS_range.RS_endDay, cl
	call	DayPlanPrintSingleDate		; print this date
	pop	ax, bx, cx, dx			; restore the important data
	add	ax, ss:[bp].MPRS_dateWidth	; move over one date
	dec	dl				; one less column in this row
	jnz	nextDate			; if not done, next
	add	bx, ss:[bp].MPRS_dateHeight	; else go down one row...
	mov	ax, MONTH_BORDER_HORIZ		; and to the left column
	mov	dl, 7				; reset the day counter
nextDate:
	inc	cl				; increment the day
	cmp	cl, ch				; are we done yet ??
	jle	anotherDay

	; Clean up
	;
cleanUpOK:
	mov	ax, MSG_PRINT_CONTROL_PRINTING_COMPLETED
cleanUp:
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset
	pop	ds:[di].DPI_rangeLength		; restore range length
	push	ax				; save the method to send
	and	es:[systemStatus], not SF_PRINT_MONTH_EVENTS
	mov	dx, ss:[bp].PRS_currentSizeObj	; size object => DS:*DX
	call	DayPlanNukePrintEvent		; free up the event

	; End the page properly
	;
	mov	di, ss:[bp].PRS_gstate
	mov	al, PEC_FORM_FEED
	call	GrNewPage

	; Now tell the PrintControl that we're done
	;
	pop	ax				; method to send
	GetResourceHandleNS	CalendarPrintControl, bx
	mov	si, offset CalendarPrintControl
	call	ObjMessage_print_call		; send that method

	.leave
	ret
DayPlanPrintDatesEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintSingleDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Print a single date's events, that appear inside of
		a month.

CALLED BY:	INTERNAL - DayPlanPrintDatesEvents
	
PASS:		DS:*SI	= DayPlanClass instance data
		SS:BP	= MonthPrintRangeStruct
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanPrintSingleDate	proc	near
	.enter

	; First translate
	;
	push	si				; save the DayPlan handle
	mov	di, ss:[bp].PRS_gstate		; GState => DI
	call	GrSetNullTransform		; go back to 0,0
	mov	dx, ss:[bp].MPRS_newXOffset	; raw X offset => DX
	add	dx, es:[printMarginLeft]
	inc	dx
	mov	bx, ss:[bp].MPRS_newYOffset	; raw Y offset => BX
	add	bx, es:[printMarginTop]		; y offset => BX
	clr	ax				; no fractions
	clr	cx				; no fractions
	call	GrApplyTranslation		; perform the translation

	; Now set the clip region
	;
	mov	bx, ax				; top (and left) zero
	mov	cx, ss:[bp].PRS_width		; right
	mov	dx, ss:[bp].PRS_height		; bottom
	mov	si, PCT_REPLACE
	call	GrSetClipRect			; set the clip rectangle

	; Now do the real printing
	;
	pop	si				; restore the DayPlan handle
	clr	cx				; no template or headers
	mov	ax, MSG_DP_PRINT_ENGINE		; do the real work
	call	ObjCallInstanceNoLock

	.leave
	ret
DayPlanPrintSingleDate	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintEngine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Performs the actual printing of events that fall within the
		desired range.

CALLED BY:	GLOBAL
	
PASS:		ES	= DGroup
		DS:*SI	= DayPlanClass instance data
		SS:BP	= PrintRangeStruct
		CL	= DayPlanInfoFlags
				DP_TEMPLATE (attempt template mode)
				DP_HEADERS (attempt headers mode)
		CH	= DayPlanPrintFlags

RETURN:		AX	= Number of pages that were printed

DESTROYED:	BX, DI, SI

NOTES:		PRS_currentSizeObj must be accurately filled in when passed
			If no current print object, then zero
			Else, valid handle in DPResource block

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanPrintEngine	method	DayPlanClass,	MSG_DP_PRINT_ENGINE
	uses	cx, dx, bp
	.enter

	; First call for everything to be updated
	;
	mov	ax, 1				; assume 1 page printed
	test	es:[systemStatus], SF_VALID_FILE
	LONG	jz	done			; if no file, do nothing!
	push	cx				; save the flags
	mov	ax, MSG_DP_UPDATE_ALL_EVENTS
	call	ObjCallInstanceNoLock
	cmp	ds:[LMBH_blockSize], LARGE_BLOCK_SIZE
	jb	eventTable			; if smaller, don't worry
	mov	ax, MSG_DP_FREE_MEM		; free as much mem as possible
	call	ObjCallInstanceNoLock		; do the work now!

	; Allocate an EventTable, and initialize it
eventTable:
	mov	cx, size EventTableHeader	; allocate an EventTable
	mov	al, mask OCF_IGNORE_DIRTY	; not dirty
	call	LMemAlloc			; chunk handle => AX
	mov	bx, ax				; table handle => BX
	mov	di, ds:[bx]			; derference the handle
	mov	ds:[di].ETH_last, cx		; initialize the header...
	mov	ds:[di].ETH_screenFirst, OFF_SCREEN_TOP
	mov	ds:[di].ETH_screenLast, OFF_SCREEN_BOTTOM

	; Save some important values, and reload them
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
	pop	cx				; restore the flags
	push	ds:[di].DPI_eventTable		; save these values...
	push	{word} ds:[di].DPI_flags	; save InfoFlags & PrintFlags
	push	ds:[di].DPI_textHeight		; save one-line text height
	push	ds:[di].DPI_viewWidth		; save the view width
	push	ds:[di].DPI_docHeight		; save the document height
	mov	ds:[di].DPI_eventTable, ax	; store the new EventTable
	mov	{word} ds:[di].DPI_flags, cx	; store some new flags
	or	ds:[di].DPI_flags, DP_LOADING	; to avoid re-draw requests
	mov	cx, ss:[bp].PRS_width		; screen width => CX
	mov	ds:[di].DPI_viewWidth, cx	; store the width here
	mov	bx, ss:[bp].PRS_currentSizeObj	; current handle => BX
	tst	bx				; check for valid handle
	jnz	havePrintEvent			; if exists, then print
if SUPPORT_ONE_LINE_PRINT
	clr	ax				; assume not one-line print
	test	ds:[di].DPI_printFlags, mask DPPF_ONE_LINE_EVENT
	jz	notOneLine
	mov	ax, mask PEI_ONE_LINE_PRINT
notOneLine:
else
	clr	ax				; PrintEventInfo => AX
endif
	call	DayPlanCreatePrintEvent		; print event => DS:*BX
havePrintEvent:
EC <	push	si				; save DayPlan handle	>
EC <	mov	si, bx				; move event handle	>
EC <	call	ECCheckLMemObject		; object in DS:*SI	>
EC <	pop	si				; restore DayPlan handle>
	mov	es:[timeOffset], 0		; no time offset !
	push	bp, bx				; save structure & DayEvent
		
	; Load the events, and then print them out
	;
	call	DayPlanLoadEvents		; load all of the events
	pop	bp, dx				; restore structure & DayEvent
	call	DayPlanPrintAllEvents		; print all of the events
						; number of pages => CX	
	; Clean up
	;
	tst	ss:[bp].PRS_currentSizeObj	; start with a size object ??
	jnz	finishUp			; yes, so don't kill it
	call	DayPlanNukePrintEvent		; else destroy the print event
finishUp:
	mov	di, ds:[si]			; dereference the chunk
	add	di, ds:[di].DayPlan_offset	; access my instace data
	mov	ax, ds:[di].DPI_eventTable	; print EventTable => AX
	pop	ds:[di].DPI_docHeight		; restore the document height
	pop	ds:[di].DPI_viewWidth		; restore the view width
	pop	ds:[di].DPI_textHeight		; resotre one-line text height
	pop	{word} ds:[di].DPI_flags	; restore InfoFlags & PrintFlags
	pop	ds:[di].DPI_eventTable		; save these values...
	call	LMemFree			; free up the print table
	mov	ax, cx				; number of pages => AX
done:
	.leave
	ret
DayPlanPrintEngine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanCreatePrintEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create a DayEvent to use only for printing. Also use one
		of the MyText Objects created as the SizeObject, so that
		all the text heights will be correctly calculated.

CALLED BY:	DayPlanPrintEngine
	
PASS:		DS:*SI	= DayPlanClass instance data
		ES	= DGroup
		SS:BP	= PrintRangeStruct
		AX	= PrintEventInfo

RETURN:		DS:*BX	= DayEventClass object to print with
		Carry	= Clear if sufficient room to print
			= Set if not

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Query the SPC for the print mode
		Create the event buffer
		Set the proper font
		Calculate the height of a one-line TEO

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/29/90		Initial version
	kho	12/18/96	One-line printing added

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanCreatePrintEvent	proc	near
	class	DayEventClass
	uses	ax, cx, dx, di
	.enter

	; Store some important information
	;
	push	bp, si				; save DayPlan, structure
	push	ax				; save PrintEventInfo
if SUPPORT_ONE_LINE_PRINT
	push	ax				; one more time
endif
	mov	ax, es:[SizeTextObject]
	mov	ss:[bp].PRS_sizeTextObj, ax
	mov	ax, es:[oneLineTextHeight]
	mov	ss:[bp].PRS_oneLineText, ax
	mov	ax, es:[timeWidth]
	mov	ss:[bp].PRS_timeWidth, ax
	mov	ax, es:[timeOffset]
	mov	ss:[bp].PRS_timeOffset, ax

	; Query the MyPrint for the output mode
	;
	push	ss:[bp].PRS_pointSize		; save the pointsize
	GetResourceHandleNS	CalendarPrintOptions, bx
	mov	si, offset CalendarPrintOptions	; OD => BX:SI
	mov	ax, MSG_MY_PRINT_GET_INFO
	call	ObjMessage_print_call
	push	cx				; save the FontID
	mov	di, offset PrintEventClass	; parent Event class => ES:DI
	call	BufferCreate			; PrintEvent => CX:*DX
EC <	cmp	cx, ds:[LMBH_handle]		; must be in this block	>
EC <	ERROR_NE	DP_CREATE_PRINT_EVENT_WRONG_RESOURCE		>

	; Now tell the DayEvent to set a new font & size
	;
	mov	si, dx				; DayEvent OD => DS:*SI
	pop	cx				; FontID => CX
	pop	dx				; pointsize => DX
	pop	bp				; PrintEventInfo => BP
	mov	ax, MSG_PE_SET_FONT_AND_SIZE	; set the font and pointsize
	call	ObjCallInstanceNoLock		; send the method

	; Set up the event text for multiple rulers
	;
	mov	bx, si				; DayEvent handle => BX
	mov	di, ds:[si]			; dereference the DayEvent
	add	di, ds:[di].DayEvent_offset	; instance data => DS:DI
	mov	si, ds:[di].DEI_textHandle	; text MyText => DS:*DI
	mov	es:[SizeTextObject], si		; store the handle here

if SUPPORT_ONE_LINE_PRINT

	; If one-line-print, set the VisTextStates of event text accordingly
	;
	pop	ax
	test	ax, mask PEI_ONE_LINE_PRINT
	jz	notOneLine
	mov	ax, MSG_VIS_TEXT_MODIFY_EDITABLE_SELECTABLE
	mov	cx, (0 shl 8) or mask VTS_ONE_LINE ; Set VTS_ONE_LINE
	call	ObjCallInstanceNoLock
notOneLine:
endif

	mov	ax, MSG_VIS_TEXT_CREATE_STORAGE
	mov	cx, mask VTSF_MULTIPLE_PARA_ATTRS
	call	ObjCallInstanceNoLock		; send the method

	mov	ax, MSG_VIS_TEXT_SET_MAX_LENGTH
	mov	cx, MAX_TEXT_FIELD_LENGTH+1	; possibly 1 character too big
	call	ObjCallInstanceNoLock		; send the method	

	; Finally, calculate the one line height
	;
	pop	si				; DayPlan handle => SI
	mov	ax, MSG_DP_CALC_ONE_LINE_HEIGHT
	call	ObjCallInstanceNoLock		; perform the calculation
	pop	bp				; PrintRangeStruct => SS:BP
	mov	ss:[bp].PRS_oneLineHeight, dx	; store the height

	; Check to see if there is sufficient room to print events
	;
	mov	ax, es:[timeWidth]		; move the time width => AX
	cmp	ss:[bp].PRS_width,ax		; compare with widths
						; this sets/clears the carry
	.leave
	ret
DayPlanCreatePrintEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanNukePrintEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Destory the DayEvent object used to print with

CALLED BY:	DayPlanPrintEngine
	
PASS:		DS:*DX	= DayEventClass object to nuke
		SS:BP	= PrintRangeStruct
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanNukePrintEvent	proc	near
	uses	ax, cx, dx, bp, si
	.enter

	; Restore some important information
	;
	mov	ax, ss:[bp].PRS_sizeTextObj 
	mov	es:[SizeTextObject], ax 
	mov	ax, ss:[bp].PRS_oneLineText 
	mov	es:[oneLineTextHeight], ax 
	mov	ax, ss:[bp].PRS_timeWidth 
	mov	es:[timeWidth], ax 
	mov	ax, ss:[bp].PRS_timeOffset 
	mov	es:[timeOffset], ax 

	; Now destroy the print event
	;
	mov	si, dx				; OD => DS:*SI
	mov	ax, MSG_VIS_DESTROY		; destroy the entire branch
	mov	dl, VUM_NOW			; destroy stuff now
	call	ObjCallInstanceNoLock		; send the method

	.leave
	ret
DayPlanNukePrintEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintAllEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prints all of the events in the EventTable

CALLED BY:	DayPlanPrintEngine
	
PASS:		ES	= DGroup
		DS:SI	= DayPlanClass instance data
		SS:BP	= PrintRangeStruct
		DS:DX	= DayEventClass object to use for printing

RETURN:		CX	= Number of pages printed

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:
		A PrintPositionStruct is allocated on the stack, which is
		used to pass values to PositionDayEvent(), and to 
		maintain some internal state. Note that a PositionStruct
		is the first element of a PrintPositionStruct.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanPrintAllEvents	proc	near
	class	DayPlanClass
	uses	dx, si, bp
	.enter

	; Some set-up work
	;
	sub	sp, size PrintPositionStruct	; allocate the PositionStruct
	mov	bx, sp				; structure => SS:BX
	mov	ax, ss:[bp].PRS_width			
	mov	ss:[bx].PS_totalWidth, ax	; store the document width
	mov	ss:[bx].PS_timeLeft, 0		; never draw the icons
	mov	ax, ss:[bp].PRS_oneLineHeight	
	mov	ss:[bx].PS_timeHeight, ax	; store the one line height
	mov	ax, ss:[bp].PRS_height		
	mov	ss:[bx].PPS_pageHeight, ax	; store the page height
	mov	ax, ss:[bp].PRS_specialValue	; either 1 or 2
	mov	ss:[bx].PPS_singlePage, al	; store the page boolean
	mov	ss:[bx].PPS_numPages, 1		; initally, one page
	mov	ss:[bx].PPS_nextOffset, 0	; no next offset
	mov	ax, dx				; PrintEvent => DS:*AX
	mov	dx, bx				; PositionStruct => SS:DX
	mov	bp, ss:[bp].PRS_gstate		; GState => BP
	mov	si, ds:[si]			; dereference the handle
	add	si, ds:[si].DayPlan_offset	; access my instance data
	mov	si, ds:[si].DPI_eventTable	; event table handle => SI
	mov	di, ds:[si]			; dereference the handle
	mov	bx, size EventTableHeader	; go to the first event
	clr	cx				; start at the top!
	jmp	midLoop				; start looping

	; Loop here
eventLoop:
	call	DayPlanPrintOneEvent		; print the event
	jc	done				; if carry set, abort
	add	bx, size EventTableEntry
midLoop:
	cmp	bx, ds:[di].ETH_last		; are we done ??
	jl	eventLoop
	
	; Let's do some clean up work
	;
done:
	mov	bp, dx				; PrintPositionStruct => SS:BP
	mov	cx, ss:[bp].PPS_numPages	; number of pages => AX
	add	sp, size PrintPositionStruct	; clean up the stack

	.leave
	ret
DayPlanPrintAllEvents	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintOneEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Prints one event corresponding to the EventTableEntry

CALLED BY:	DayPlanPrintEngine()
	
PASS:		ES	= DGroup
		DS:*SI	= EventTable
		DS:DI	= EventTable
		DS:*AX	= PrintEvent to use
		SS:DX	= PrintPositionStruct
		BP	= GState
		CX	= Y-position
		BX	= Offset to the EventTableEntry to be printed
		
RETURN:		DS:DI	= EventTable (updated)
		CX	= Y-position in document (updated)
		Carry	= Set to stop printing of this range

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanPrintOneEvent	proc	near
	.enter

	; First stuff the event
	;
	push	si, bp, dx			; table handle, GState, struct
	add	di, bx				; go to the proper ETE
	mov	bp, ds:[di].ETE_size		; event height => BP
	mov	dx, DO_NOT_INSERT_VALUE		; don't insert into vistree
	call	StuffDayEvent			; load time & text strings
	mov	si, ax				; DayEvent => SI
	mov	dx, bp				; event height => DX
	pop	bp				; PositionStruct => SS:BP
	pop	di				; GState => DI
	cmp	ss:[bp].PPS_singlePage, 1	; printing events in a month?
	jnz	position			; no, so use regular values
	call	DayPlanPrintPrepareDateEvent	; set some styles, etc...

	; Now position the sucker (possibly on a new page)
	;
position:
	mov	ax, cx				; y-position => AX
	add	ax, dx				; calculate to end of event
	cmp	ss:[bp].PPS_pageHeight, ax	; does it fit on the page ??
	jge	positionNow			; yes, so jump
printAgain:
	call	DayPlanPrintEventCrossesPage	; determine what to do
positionNow:
	pushf					; save the carry flag
	call	PositionDayEvent		; position the event (at CX)
	add	cx, dx				; update the document position

	; Enable the event for printing
	;
	mov	ax, MSG_PE_PRINT_ENABLE
	call	ObjCallInstanceNoLock		; CX, DX, BP are preserved

	; Finally draw the event
	;
	push	bp, dx, cx			; save doc offset & struct
	mov	bp, di				; GState => BP
	mov	ax, MSG_VIS_DRAW
	mov	cl, mask DF_PRINT		; we're printing
	call	ObjCallInstanceNoLock		; draw the event
	pop	bp, dx, cx			; restore doc offset, struct
	cmp	ss:[bp].PPS_singlePage, 1	; print to single page only ?
	je	noLoop				; yes, so don't loop again
	popf					; restore the carry flag
	jc	printAgain			; multiple-page event
	pushf					; else store CF=0
noLoop:
	popf					; restore the CF

	; Clean up work
	;
	mov	dx, bp				; PrintPositionStruct => SS:DX
	mov	bp, di				; GState => BP
	mov	ax, si				; PrintEvent => DS:*AX
	pop	si				; restore the EventTable chunk
	mov	di, ds:[si]			; dereference the handle

	.leave
	ret
DayPlanPrintOneEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintPrepareDateEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the margin and border information for this event
		to fully utilize the space inside of a date.

CALLED BY:	GLOBAL
	
PASS:		DS:*SI	= DayEventClass object used for printing
		SS:BP	= PrintPositionStruct
		ES	= DGroup

RETURN:		DX	= Height of the event

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		We are being very tricky here, because the SizeTextObject,
		at this point, holds the text of the event. All we need to
		do is determine if there is a valid time, and if so, 
		set up the first paragraph and the rest of the object
		rulers.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/4/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TEXT_INDENT_LEVEL	= 2			; basic text indentation level
CRString	byte	'\r', 0		; a carriage return
VTRP_textPtr	equ	<VTRP_textReference.TR_ref.TRU_pointer.TRP_pointer>

DayPlanPrintPrepareDateEvent	proc	near
	uses	ax, bx, cx, di, si, bp
	class	VisTextClass
	.enter

	; Set the default margin
	;
	mov	di, bp				; PrintPositionStruct => SS:DI
	push	si				; save the DayEvent handle
	mov	si, es:[SizeTextObject]		; OD => DS:*SI
	sub	sp, size VisTextSetMarginParams
	mov	bp, sp
	clrdw	ss:[bp].VTSMP_range.VTR_start
	movdw	ss:[bp].VTSMP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTSMP_position, TEXT_INDENT_LEVEL * 8
	mov	ax, MSG_VIS_TEXT_SET_LEFT_AND_PARA_MARGIN
	call	ObjCallInstanceNoLock		; send the method
	add	sp, size VisTextSetMarginParams

	; Do we have any time ?
	;
	mov	bx, si				; MyText handle => BX
	pop	si				; DayEvent handle => SI
	mov	ax, MSG_DE_GET_TIME
	call	ObjCallInstanceNoLock		; time => CX
	mov	si, bx				; MyText handle => SI
	cmp	cx, -1				; no time ??
	je	calcSize			; just re-calculate the size

	; Check if the space between the time and the border is wide enough
	; to hold some text. If it is not, insert a CR at the front of the
	; text.
	;
	mov	cx, ss:[di].PPS_posStruct.PS_totalWidth
	sub	cx, es:[timeWidth]		; 1st line's wdith => CX
	cmp	cx, VIS_TEXT_MIN_TEXT_FIELD_WIDTH
	jge	setMargin			; if big enough, continue
	sub	sp, size VisTextReplaceParameters
	mov	bp, sp				; structure => SS:BP
	clr	ax
	mov	ss:[bp].VTRP_flags, ax
	clrdw	ss:[bp].VTRP_range.VTR_start, ax
	clrdw	ss:[bp].VTRP_range.VTR_end, ax
	mov	ss:[bp].VTRP_insCount.high, ax
	inc	ax
	mov	ss:[bp].VTRP_insCount.low, ax	; insert one character
	mov	ss:[bp].VTRP_textReference.TR_type, TRT_POINTER
	mov	ss:[bp].VTRP_textPtr.segment,  cs
	mov	ss:[bp].VTRP_textPtr.offset, offset CRString
	mov	ax, MSG_VIS_TEXT_REPLACE_TEXT
	call	ObjCallInstanceNoLock		; insert the CR.
	add	sp, size VisTextReplaceParameters
	jmp	calcSize			; finish up

	; Else set the paragraph margin for the first paragraph
	;
setMargin:
	sub	sp, size VisTextSetMarginParams
	mov	bp, sp
	clr	ax
	clrdw	ss:[bp].VTSMP_range.VTR_start, ax
	clrdw	ss:[bp].VTSMP_range.VTR_end, ax
	mov	ax, es:[timeWidth]		; time width => AX
	shl	ax, 1
	shl	ax, 1
	shl	ax, 1
	mov	ss:[bp].VTSMP_position, ax	
	mov	ax, MSG_VIS_TEXT_SET_PARA_MARGIN
	call	ObjCallInstanceNoLock		; set paragraph margin in BP
	add	sp, size VisTextSetMarginParams

	; Calculate the final size. I had to add a horrible hack to
	; clear a field in the text object, so that the actual height
	; of the text will be properly returned, rather than the height
	; of the first text to be drawn. -Don 9/29/93
	;
calcSize:
	mov	cx, ss:[di].PPS_posStruct.PS_totalWidth
	clr	dx				; don't cache the height
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	clr	ds:[di].VTI_lastWidth
	mov	ax, MSG_VIS_TEXT_CALC_HEIGHT	; using width in CX
	call	ObjCallInstanceNoLock		; height => DX

	.leave
	ret
DayPlanPrintPrepareDateEvent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintEventCrossesPage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	An event does not fit on one page, by the amount in AX.
		Determine where to print the event.

CALLED BY:	DayPlanPrintOneEvent
	
PASS:		ES	= DGroup
		SS:BP	= PrintPositionStruct
		CX	= Offset in page to the top of the event
		DX	= Length of the event
		DI	= GState		

RETURN:		CX	= Offset at which we should print the event.
		Carry	= Set to print this event again

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/30/90		Initial version
	Don	7/19/90		Deal with multi-page events better

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MAX_SPACE_AT_BOTTOM_OF_PAGE	= 36		; (up to 3 lines of 12pt text)

DayPlanPrintEventCrossesPage	proc	near
	uses	bx, dx	
	.enter

	; Will we need to draw again ??
	;
	mov	bx, ss:[bp].PPS_pageHeight	; height of a page => BX
	cmp	ss:[bp].PPS_singlePage, 1	; keep on one page ??
	je	forceClip			; force event to be clipped

	; Are we in the middle of a multi-page event
	;
	tst	ss:[bp].PPS_nextOffset		; is there a next offset ??
	jz	firstTime			; no, so continue
	mov	cx, ss:[bp].PPS_nextOffset	; grab the next offset
	jmp	newPage

	; See where we should place this event
	;
firstTime:
	mov	ax, bx				; bottom of page => AX
	sub	ax, cx				; how far from the bottom => AX
	cmp	ax, MAX_SPACE_AT_BOTTOM_OF_PAGE	; split on two pages ??
	jg	nextPageCalc			; yes, so calc next offset
	clr	cx				; else offset = 0 on a new page

	; Create a new page
	;
newPage:
	inc	ss:[bp].PPS_numPages		; count the number of pages
	mov	al, PEC_FORM_FEED
	call	GrNewPage			; new page to the GString
	call	InitPagePosition		; initialize the drawing

	; See if it will now fit on the rest of this page
	;
nextPageCalc:
	mov	ss:[bp].PPS_nextOffset, 0	; assume no next offset
	mov	ax, cx				; offset => AX
	add	ax, dx				; length of the page
	cmp	bx, ax				; does it fit on the page ??
	jge	done				; yes
forceClip:
	call	DayPlanPrintCalcNextOffset	; else do the dirty work!
	stc					; ensure the carry is set!
done:
	.leave
	ret
DayPlanPrintEventCrossesPage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayPlanPrintCalcNextOffset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the offset of the event text for the next page,
		to ensure the text starts with a complete line. Also sets
		the clip rectangle (if any) for the bottom of the current
		page.

CALLED BY:	DayPlanPrintEventCrossesPage
	
PASS:		ES	= DGroup
		SS:BP	= PrintPositionStruct
		BX	= Page length
		CX	= Offset of the event text
		DX	= Length of the event text
		DI	= GState		
		
RETURN:		Nothing

DESTROYED:	AX, BX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DayPlanPrintCalcNextOffset	proc	near
	uses	cx
	.enter

	; Calculate the raw offset to the next page
	;
	mov	ss:[bp].PPS_nextOffset, cx	; store the current offset
	sub	ss:[bp].PPS_nextOffset, bx	; subtract offset to next page

	; See if we break between lines
	;
	mov	ax, bx				; page width => AX
	sub	ax, cx				; space left on page => AX
	sub	ax, EVENT_TB_MARGIN		; allow for top margin
	mov	cx, es:[oneLineTextHeight]
	sub	cx, 2 * EVENT_TB_MARGIN		; space per line => CX
	clr	dx				; difference => DX:AX
	div	cx				; perform the division
	tst	dx				; any remainder ??
	jz	done				; no, so we're done

	; Else we must set a clip rectangle, and adjust the next offset
	;
	push	si				; save this register
	add	ss:[bp].PPS_nextOffset, dx	; adjust next offset!
	sub	bx, dx				; offset to end of text
;;;	dec	bx				; text goes from 0->N-1
	mov	dx, bx				; bottom edge
	mov	cx, ss:[bp].PS_totalWidth	; right edge
	clr	ax				; left edge
	mov	bx, ax				; top edge
	mov	si, PCT_REPLACE			; set a new clip rectangle
	call	GrSetClipRect			; set the clip rectangle
	pop	si				; restore this register
done:
	.leave
	ret
DayPlanPrintCalcNextOffset	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitPagePosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Account for the page borders by translating the page down
		and right by the border amount

CALLED BY:	INTERNAL
	
PASS:		DI	= GString

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/29/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitPagePosition	proc	near
	uses	ax, bx, cx, dx, si

	.enter

	; Initialize the page position
	;
	mov	dx, es:[printMarginLeft]
	clr	cx				; x translation => DX:CX
	mov	bx, es:[printMarginTop]
	mov	ax, cx				; y translation => BX:AX
	call	GrApplyTranslation		; allow fro print margins

	; Alse set the color mapping mode
	;
	mov	al, ColorMapMode <1, 0, CMT_CLOSEST>
	call	GrSetAreaColorMap		; map to solid colors

	; Set a clip rectangle for the entire page
	;
	clr	ax, bx
	mov	cx, es:[printWidth]
	mov	dx, es:[printHeight]
	mov	si, PCT_REPLACE			; set a new clip rectangle
	call	GrSetClipRect			; set the clip rectangle

	.leave
	ret
InitPagePosition	endp

PrintCode	ends
