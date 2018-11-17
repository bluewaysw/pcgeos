COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Year
FILE:		yearMonth.asm

AUTHOR:		Don Reeves, July 6, 1989

ROUTINES:
	Name			Description
	----			-----------
GeometryCode:
    EXT MonthDrawCalculate	Calculate size of the dates

YearCode:
    GLB MonthSetMonth		Handler for MSG_MONTH_SET_MONTH
    GLB MonthSetState		Handler for MSG_MONTH_SET_STATE
    GLB MonthSetMonthMap	Handler for MSG_MONTH_SET_MONTH_MAP
    GLB MonthDraw		Handler for MSG_VIS_DRAW
    INT MonthCreateTitle	Create this month's title string
    INT MonthDrawTitle		Draw the month's title string
    INT MonthDrawGrid		Draw the month grid (date outlines)
    INT MonthDrawWeekDays	Draw the day of week strings
    INT MonthDrawDates		Draw the date strings in their correct places
    INT MonthDrawWeekNumbers	Draw week numbers for Responder
    INT MonthDrawDateBG		Draw the background of a day of the month
    INT MonthDrawNoteToday	Invert today's box if possible
    INT MonthDrawMonthMap	Draw the month map for this month
    INT MonthDrawMonthMapDay	Draws the indication that an event is on a day
    GLB MonthSelectDraw		Handler for MSG_MONTH_SELECT_DRAW
    INT MonthSelectCalcFar	Caclulate first day's position
    INT MonthSelectCalc		Caclulate first day's position
    INT MonthSelectRect		Draw a single inverted rectangle
    INT SelectedDayHasEvent	Check if a day of the current month has event
    INT SelectedDayIsToday	Check if selected day is today 
    INT ResponderSelectRectAdjustForToday
				Adjust the selection area so that nothing is
				drawn over the indication of today. 

YearInputCode:
    GLB MonthMetaPtr		Handler for MSG_META_PTR
    INT MonthMetaPtrCalc	Take raw mouse position, and decide what
				(if any) day the button is over.

PrintCode:
    GLB	MonthSetFont		Handler for MSG_MONTH_SET_FONT
    GLB	MonthDrawEvents		Handler for MSG_MONTH_DRAW_EVENTS

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/6/89		Initial revision
	Don	12/4/89		Use new class & method declarations
	RR	4/12/95		Add Responder flavored UI
	RR	5/31/95		Fix month navigation
	RR	8/4/95		Responder navigation fix

DESCRIPTION:
	Define the procedures that operate on the month object

	$Id: yearMonth.asm,v 1.1 97/04/04 14:49:00 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


GeometryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawCalculate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate size (length and width) of the dates.
		Sets month's dateWidth and dateHeight variables.
CALLED BY:	MonthDraw

PASS:		DS:*SI	= Pointer to instance data
		
RETURN:		DS:DI	= MonthClass specific instance data

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Drawing starts from:
			(MONTH_BRODER_HORIZ, MONTH_BORDER_TOP)
		The title is draw at an additional offset:
			(centered horizontally, TITLE_Y_OFFSET)
			Also, allow % of title font size for decenders
		The days of the week (DOW) are drawn at:
			(centered horizontally, MI_offsetDOW)
			
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/10/89		Initial version
	Don	6/11/90		Optimized
	RR	4/20/95		Changes for responder

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	COL_MAJOR_MONTH
TITLE_OFFSET_Y		equ	4
else
TITLE_OFFSET_Y		equ	2
endif

MonthDrawCalculate	proc	far
	class	MonthClass			; friend to this class
	uses	ax, bx, cx, dx, di, bp
	.enter
	
	; Get everything ready
	;
	mov	di, ds:[si]			; dereferecne the handle
	add	di, ds:[di].Month_offset	; access instance data
	and	ds:[di].MI_flags, NOT MI_NEW_SIZE ; clear the flag

	; Determine the spacing. Register usage:
	;	AX = scratch register
	;	BX = offset to bottom of the title area
	;	CX = height of the DOW area
	;
	clr	ax, cx
	mov	bx, MONTH_BORDER_TOP + TITLE_OFFSET_Y
	mov	al, ds:[di].MI_titleFont	; title font size => AL
	add	bx, ax
	sar	ax, 1
	sar	ax, 1				; 25% of size for decsenders
	test	ds:[di].MI_flags, MI_PRINT	
	jnz	doneDOW				; if not printing, add 12.5%
	add	bx, ax				; ...more for decsenders
	sar	ax, 1				; ...as it just looks better
doneDOW:
	add	bx, ax				; bottom of title => BX
	mov	ds:[di].MI_offsetDOW, bx	; save the day of week offset

	mov	cl, ds:[di].MI_datesFont	; dates & DOW font size
;;;	add	cx, 3				; height of DOW area => CX
	add	cx, 5				; height of DOW area => CX
						; (leave room for white space)
						; (and two double-think lines)
	add	cx, bx				; Grid offset => CX
if	COL_MAJOR_MONTH
	mov	ds:[di].MI_offsetGrid, bx	; DOWs not on top 
else
	mov	ds:[di].MI_offsetGrid, cx	; save the grid offset
endif

	; First calculate the width of each date
	;
	call	VisGetBounds			; get my boundaries
	push	ax				; save left
	sub	cx, ax				; width in CX
	mov	ax, cx				; move width to AX
	sub	dx, bx				; height in DX
	test	ds:[di].MI_flags, MI_PRINT	
	jz	storeHeight			; if not printing, we're OK
	mov	bp, dx				; ...otherwise, leave some room
	sar	bp, 1				; ...between the months
	sar	bp, 1				; 25%
	sar	bp, 1				; 12.5%
	sar	bp, 1				; 6.25%
	sar	bp, 1				; 3.125%
	sub	dx, bp
storeHeight:
	mov	bp, dx				; move height => BP
if 	not COL_MAJOR_MONTH			; responder--no border
	sub	ax, 2 * MONTH_BORDER_HORIZ	; account for border	
endif
	clr	dx				; value in DX:AX

if	CLAIM_UNUSED_MONTH_SPACE
	; If the month spans across 6 weeks, divide by 7, else divide
	; by 6.
	;
	mov	cx, 6
	test	ds:[di].MI_flags, MI_SPAN_6_WEEKS
	jz	10$
	inc	cx
10$:
else
	mov	cx, 7				; divisor => CX
endif

if	HAS_MIN_WEEK_DAY_WIDTH
	mov	bx, ax				; bx = save the number
	push	dx
endif
	div	cx				; do the divsion

if	HAS_MIN_WEEK_DAY_WIDTH
	; If the week day min width is bigger, we need to recalculate day
	; width.
	;
	pop	dx
	mov	ds:[di].MI_weekdayWidth, ax
	cmp	ax, MIN_WEEK_DAY_WIDTH
	jae	gotDayWidth

	; New day width = (Width - week day width) / # weeks
	;
	mov_tr	ax, bx				; restore orig number
	subdw	dxax, MIN_WEEK_DAY_WIDTH	; ax = width of all weeks
	dec	cx				; don't count weekday col
	div	cx

	; We know week day column is wider than the rest.
	;
	mov	ds:[di].MI_weekdayWidth, MIN_WEEK_DAY_WIDTH
gotDayWidth:	
endif   ; HAS_MIN_WEEK_DAY_WIDTH

	mov	ds:[di].MI_dateWidth, ax	; save the width (quotient)

	; Calculate month's rightmost position while we're at it
	;
if	HAS_MIN_WEEK_DAY_WIDTH

	cmp	ax, MIN_WEEK_DAY_WIDTH		; Calc width with 7 cols
	jae	calc7col			;   if col Width > min width

	; Unequal week day col width and dates width. We first get the width
	; of 6 weekds and then to check if we span 6 weeks or 5 weeks to calc
	; the correct width.
	;
	mov	cx, ax				; width to CX
	shl	cx				; 2 * date width
	add	cx, ax				; 3 * date width
	shl	cx				; 6 * date width

if	CLAIM_UNUSED_MONTH_SPACE
	test	ds:[di].MI_flags, mask SPAN_6_WEEKS
	jnz	addMinWeekWidth
	sub	cx, ax				; 5 * date width
addMinWeekWidth:
endif   ; CLAIM_UNUSED_MONTH_SPACE

	add	cx, MIN_WEEK_DAY_WIDTH		; cx = width of all columns
	mov_tr	ax, cx				; ax = width of all columns
	jmp	gotColWidths
endif   ; HAS_MIN_WEEK_DAY_WIDTH
	
calc7col::
	mov	cx, ax				; width to AX
	shl	cx				; double CX
	add	ax, cx				; 3 * width => AX
	shl	cx				; double CX
	add	ax, cx				; 7 * width => AX

gotColWidths::
	pop	cx
	add	ax, cx				; calculate rightmost position
if	not COL_MAJOR_MONTH
	add	ax, MONTH_BORDER_HORIZ		; account for the border
endif
	mov	ds:[di].MI_monthRight, ax	; and save it

	; Now calculate the height
	;
if COL_MAJOR_MONTH
	mov	cx, 8				; 8 rows
else
	mov	cx, 6				; always 6 rows => CL
endif
	mov	ds:[di].MI_numberRows, cl	; save the number of rows
	mov	ax, bp				; month height to AX
	sub	ax, ds:[di].MI_offsetGrid	; account for title, DOW
	clr	dx				; value in DX:AX
	div	cx				; divisor already in CL
	mov	ds:[di].MI_dateHeight, ax	; save the height

	; And calculate the month height
	;
if COL_MAJOR_MONTH
	shl	ax
	shl	ax
	shl	ax				; 8 * height
else
	shl	ax				; 2 * height => AX
	mov	cx, ax
	shl	ax				; 4 * height => AX
	add	ax, cx				; 6 * height => AX
endif
	mov	ds:[di].MI_monthBottom, ax	; and save the position

	; Finally, center the month horizontally
	;
	mov	ds:[di].MI_leftMargin, MONTH_BORDER_HORIZ
	test	ds:[di].MI_flags, MI_PRINT	
	jnz	done				; if printing, we're done
	call	VisGetBounds			; get my boundaries
	sub	cx, ds:[di].MI_monthRight	; calc right border
	sub	cx, MONTH_BORDER_HORIZ		; if small enough
	jle	done				; ...we're done
	inc	cx				; ...otherwise center things
	shr	cx, 1				
	add	ds:[di].MI_leftMargin, cx
	add	ds:[di].MI_monthRight, cx
done:
	.leave
	ret
MonthDrawCalculate	endp

GeometryCode	ends



YearCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSetMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the month object's date, year & size

CALLED BY:	CalendarAttach, ChangeMonth (MSG_MONTH_SET_MONTH)

PASS:		DS:DI	= MonthClass specific instance data
		BP	= New year
		DH	= New month
		CH	= Point size of month title
		CL	= Point size of month days & dates
		ES	= Dgroup

RETURN:		Nothing

DESTROYED:	AX, BX, DL, SI

PSEUDO CODE/STRATEGY:
		Set the new year and month, and the NEW_MONTH flag
		if the year and month are different.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/10/89		Initial version
	kho	8/21/96		Responder change.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSetMonth	method	MonthClass, MSG_MONTH_SET_MONTH
	.enter

	; Compare the current month with new
	;
	cmp	dh, ds:[di].MI_month		; compare the months
	jne	new				; set the NEW flag if diff
	cmp	bp, ds:[di].MI_year		; compare the years
	je	checkSize			; check sizes if equal

	; Reset the month & year, set display flags
new:
	push	cx				; save font sizes
	or	ds:[di].MI_flags, MI_NEW_MONTH
	mov	ds:[di].MI_year, bp		; set up the new year
	mov	ds:[di].MI_month, dh		; set up the new month
	mov	dl, 1				; first day of the month
	CallMod	CalcDayOfWeek			; call for calculation
	CallMod	CalcDaysInMonth			; get days in the month
	mov	ds:[di].MI_daysThisMonth, ch	; store the days this month
	mov	ds:[di].MI_firstDayPos, cl	; store first day position
	mov	ds:[di].MI_monthMap.high, 0	; clear the old MonthMap...
	mov	ds:[di].MI_monthMap.low, 0
	pop	cx				; restore font sizes

	; Check if size flag is already set
checkSize:
	cmp	{word} ds:[di].MI_datesFont, cx
	je	done
	or	ds:[di].MI_flags, MI_NEW_SIZE	; set the size flag
	mov	{word} ds:[di].MI_datesFont, cx
done:

if CLAIM_UNUSED_MONTH_SPACE ;--------------------------------------------

	; Find out if this month spans across 6 week-columns.
	; if (#day + first day) > 35  {YES}
	;
	mov	al, ds:[di].MI_firstDayPos
	add	al, ds:[di].MI_daysThisMonth
	BitClr	ds:[di].MI_flags, SPAN_6_WEEKS
	cmp	al, 35
	jbe	done2
	BitSet	ds:[di].MI_flags, SPAN_6_WEEKS
done2:
endif	; ---------------------------------------------------------------

	.leave
	ret
MonthSetMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force a month to recalculate its geometry

CALLED BY:	GLOBAL (MSG_MONTH_SET_STATE)

PASS:		DS:DI	= MonthClass specific instance data
		CL	= MonthInfoFlags to clear
		CH	= MonthInfoFlags to set

RETURN:		Nothing

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/13/90		Initial version
	Don	5/29/90		Expanded version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSetState	method	MonthClass,	MSG_MONTH_SET_STATE
	mov	bl, cl
	not	bl
	and	ds:[di].MI_flags, bl		; clear these flags
	or	ds:[di].MI_flags, ch		; set the flags
	ret
MonthSetState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthGetState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the MonthInfoFlags.

CALLED BY:	MSG_MONTH_GET_STATE
PASS:		*ds:si	= MonthClass object
		ds:di	= MonthClass instance data
		ds:bx	= MonthClass object (same as *ds:si)
		es 	= segment of MonthClass
		ax	= message #
RETURN:		cl	= MonthInfoFlags
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/26/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if CLAIM_UNUSED_MONTH_SPACE
MonthGetState	method dynamic MonthClass, 
					MSG_MONTH_GET_STATE
		.enter
		mov	cl, ds:[di].MI_flags
		.leave
		ret
MonthGetState	endm
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSetMonthMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the MonthMap for this specific month

CALLED BY:	GLOBAL (MSG_MONTH_SET_MONTH_MAP)
	
PASS:
		ES	= MonthClass segment
		DS:DI	= MonthClass specific instance data
		AX:BX	= ReservedMap
		CX:DX	= MonthMap (not including reserved day)
		BP	= year (Responder only)
		
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTOR:Y
	Name	Date		Description
	----	----		-----------
	Don	5/30/90		Initial version
	sean	3/20/96		Responder change to check the year
	kliu	2/21/97

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSetMonthMap	method	MonthClass,	MSG_MONTH_SET_MONTH_MAP
		.enter
	
	; See if we need to clear any days
	;
	push	cx, dx				; save the new MonthMap
	tst	ds:[di].MI_year			; if year is zero, then
	jz	done				; we can't possibly show a map
	mov	ax, cx
	mov	bx, dx
	not	ax
	not	bx
	and	ax, ds:[di].MI_monthMap.high	; MonthMap to clear => AX:BX
	and	bx, ds:[di].MI_monthMap.low
	push	ax, bx				; save MonthMap on the stack

	; See if we need to mark any new days
	;
	not	ds:[di].MI_monthMap.high
	not	ds:[di].MI_monthMap.low
	and	ds:[di].MI_monthMap.high, cx	; MonthMap to set => instance
	and	ds:[di].MI_monthMap.low, dx

	; Now do the common work of updating
	; 
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE
	mov	di, offset MonthClass		; ClassStruc => ES:DI
	call	ObjCallSuperNoLock		; GState => BP	
	mov	di, bp				; GState => DI
	call	MonthDrawMonthMap		; MonthMap bits to draw
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].Month_offset	; access my instance data
	pop	ds:[bp].MI_monthMap.low		; MonthMap bits to clear...
	pop	ds:[bp].MI_monthMap.high
	call	MonthDrawMonthMap		; clear these days...

	call	GrDestroyState			; destroy the GState
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Month_offset	; access my instance data
done:
	pop	ds:[di].MI_monthMap.low		; store the new month map!
	pop	ds:[di].MI_monthMap.high
exit::
			
		.leave
		ret
MonthSetMonthMap	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthInvalidateTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the title, so that it will be re-drawn

CALLED BY:	GLOBAL (MSG_MONTH_INVALIDATE_TITLE)

PASS:		*DS:SI	= MonthClass object
		DS:DI	= MonthClassInstance
		CX, DX	= View origin
		DI	= Window handle

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthInvalidateTitle	method dynamic	MonthClass, MSG_MONTH_INVALIDATE_TITLE
	uses	cx, dx
	.enter

	; Invalidate the entire title area. Remember to account for
	; the origin of the view (which is nicely passed to us).
	;
	push	bp				; save Window handle
	push	cx, dx				; save origin
	call	VisGetBounds			; get my bounds => left to AX
	add	ax, ds:[di].MI_leftMargin
	inc	ax
	mov	dx, bx
	add	bx, MONTH_BORDER_TOP+1
	mov	cx, ds:[di].MI_monthRight		
	dec	cx
	add	dx, ds:[di].MI_offsetDOW
	dec	dx
	pop	bp, si
	sub	ax, bp				; account for view origin
	sub	cx, bp				; ...
	sub	bx, si				; ...
	sub	dx, si				; ...
	clr	bp, si				; rectangular region
	pop	di
	call	WinInvalReg
	mov	bp, di				; Window handle => BP

	.leave
	ret
MonthInvalidateTitle	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 		MonthDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the "date", a title showing month and year displayed

CALLED BY:	UI (MSG_VIS_DRAW)

PASS:		DS:*SI	= MonthClass instance data
		DS:DI	= MonthClass specific instance data
		BP	= Graphics state

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:
		If a new month, get first day of month
		Draw the month/year string
		Draw the month grid
		Position date strings accordingly

		For responder with CLAIM_UNUSED_MONTH_SPACE on: if the
		month next to current month draws, it will cause some
		glitches. That's why the optimization at the top is
		necessary.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	06/89		Initial version
	Don	7/6/89		Moved to new UI

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDraw	method	MonthClass, MSG_VIS_DRAW
	uses	bp
	.enter

	; Do we have a new month ??  If so, create the correct string
	;
	push	bp				; save GState
	test	ds:[di].MI_flags, MI_NEW_MONTH	; a new month ??
	je	checkSize			; jump if not
	call	MonthCreateTitle

	; Do we need to perform size calculations ??
	;
checkSize:
	test	ds:[di].MI_flags, MI_NEW_SIZE	; check the flag
	jz	finishDraw			; jump if not set
	CallMod	MonthDrawCalculate		; clears the flag

	; Set the correct font stuff
	;
finishDraw:
	mov	bp, di
	pop	di				; GState => DI
	mov	dl, ds:[bp].MI_titleFont	; font size => DL
	mov	cx, ds:[bp].MI_fontID		; font ID => CX
	clr	dh
	clr	ah
	call	GrSetFont			; set the correct font & size
	push	bp				; save specific instance data

	call	MonthDrawTitle			; draw the title
	pop	bp				; restore the instance data
	mov	dl, ds:[bp].MI_datesFont	; font size => DL
	mov	cx, ds:[bp].MI_fontID		; font ID => CX
	clr	dh
	clr	ah
	call	GrSetFont			; set the correct font & size
	mov	al, LE_BUTTCAP			; to fix-up the edges
	call	GrSetLineEnd			; set the line end type

	; Now draw the month grid
	;
	call	MonthDrawGrid

	; Now draw the days of the week
	;
	call	MonthDrawWeekDays

if WEEK_NUMBERING
	; Draw week numbers
	;
	call	MonthDrawWeekNumbers
endif
	; Note if today is in this month
	;
NRSP <	call    MonthDrawNoteToday					>
 
	; Now draw the date strings
	;
	call	MonthDrawDates			; Month instance data => DS:BP

if PZ_PCGEOS ; Pizza
	; Now draw holiday
	;
	call	MonthDrawHoliday
endif
	test	ds:[bp].MI_flags, MI_PRINT	; are we printing ??
	jnz	printing			; jump if printing

	;
	;	Draw both reserved and normal month map
	;
	call	MonthDrawMonthMap


done:
	.leave
	ret

	; We're printing - so do some special stuff
	;
printing:
	call	MonthDrawGrid			; re-draw the grid
RSP <	jmp	drawToday						>
NRSP <	jmp	done				; we're done		>
MonthDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthCreateTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Create this month's title string

CALLED BY:	MonthDraw

PASS: 		DS:DI	= MonthClass specific instance data
		DS:*SI	= MonthClass instance data		

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		Copy the correct month string to instance data
		Put in correct year
		Write it to the window

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Clears the MI_NEW_MONTH flag

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/6/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthCreateTitle	proc	near
	class	MonthClass			; friend to this class
	uses	es, di
	.enter

	; Set up work
	;
	and	ds:[di].MI_flags, not (MI_NEW_MONTH)
	mov	bp, ds:[di].MI_year		; Year => BP
	mov	dh, ds:[di].MI_month		; Month/Day => DH
	mov	bl, ds:[di].MI_flags		; MonthInfoFlags => BL
	add	di, offset MI_titleString
	segmov	es, ds				; ES:DI points to the string

	; Now create the string
	;
	mov	cx, DTF_MONTH
	test	bl, MI_YEAR_TITLE		; year in the title ??
	jz	createString			; no, don't bother
	mov	cx, DTF_MY_LONG
createString:
	call	CreateDateString

	; Get the MonthMap information
	;
	mov	cx, si				; my handle => CX
	call	GeodeGetProcessHandle		; process handle => BX
	mov	ax, MSG_DB_GET_MONTH_MAP	; request the MonthMap info
	clr	di				; no message flags
	call	ObjMessage			; send the method

	.leave	
	ret
MonthCreateTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawTitle
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the month's title string

CALLED BY:	MonthDraw

PASS:		*DS:SI	= Month object
		DS:BP	= Month instance data
		DI	= GState

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/6/89		Initial version
	Don	7/3/90		Should draw over the center of the grid

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDrawTitle	proc	near
	class	MonthClass			; friend to this class
	uses	si
	.enter

	; If the month object does not have the focus, then we simply
	; draw the name of the month in black text. If the month does
	; have the focus, then we'll draw white text on top of a black
	; title area.
	;
	call	GrGetTextColor
	push	ax, bx				; save the text color
	call	GrGetAreaColor
	push	ax, bx				; save the area color
	test	ds:[bp].MI_flags, MI_HAS_FOCUS
	jz	calcPos
	
	; OK, we have the focus, so tweak the colors
	; 
	mov	ax, (CF_INDEX shl 8) or C_WHITE
	call	GrSetTextColor
	mov	ax, (CF_INDEX shl 8) or C_BLACK
	call	GrSetAreaColor

	; Calculate the bounds of the title area
calcPos:
	call	VisGetBounds			; get my bounds => left to AX
	add	ax, ds:[bp].MI_leftMargin
	mov	dx, bx
	add	bx, MONTH_BORDER_TOP
	mov	cx, ds:[bp].MI_monthRight		
	add	dx, ds:[bp].MI_offsetDOW

	; Draw the reverse rectangle unless we are not selected
	;
if	not COL_MAJOR_MONTH
	test	ds:[bp].MI_flags, MI_HAS_FOCUS
	jz	drawTitle
	call	GrFillRect
endif		
	; Determine the width of the string so we can center it
	;
drawTitle::
	push	cx				; save width
	clr	cx				; string is NULL terminated
	mov	si, bp
	add	si, offset MI_titleString	; title string => DS:SI
	call	GrTextWidth			; length of string => DX
	pop	cx				; restore width of month

	; Determine the position at which to draw the string. We
	; still have the upper-left corner of the title area in (AX, BX)
	; and the right of the title area in CX
	;
	sub	cx, ax				; cx = width of title area
	sub	cx, dx				; cx = month - text width
	sar	cx, 1				; divide by 2 to center
if	not COL_MAJOR_MONTH
	add	ax, cx				; X pos for string => AX
	add	bx, TITLE_OFFSET_Y		; Y pos for string => BX
else
	mov	bx, TITLE_OFFSET_Y
endif
	; For whatever reason, things just look better when I position
	; the text up a bit. -Don 9/30/99
	;
	dec	bx

	; Draw the title already
	;
	clr	cx				; string is NULL terminated
	call	GrDrawText			; write it!!

	; Restore the text and area colors
	;
	pop	ax, bx
	call	GrSetAreaColor
	pop	ax, bx
	call	GrSetTextColor

	.leave
	ret
MonthDrawTitle	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawGrid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the month grid

CALLED BY:	MonthDraw

PASS:		DS:*SI	= Pointer to instance data
		DI	= GState handle		

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		Draw some lines

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/10/89		Initial version
	RR	4/12/95		column major layout for responder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	not COL_MAJOR_MONTH
MonthDrawGrid	proc	near
	class	MonthClass			; friend to this class
	uses	si
	.enter

	; Do some set-up work
	;
	call	VisGetBounds			; get my boundaries
	mov	si, ds:[si]			; dereference it
	add	si, ds:[si].Month_offset	; access my instance data
	mov	cx, ax
	mov	dx, bx
	add	cx, ds:[si].MI_leftMargin
	add	dx, MONTH_BORDER_TOP
	push	cx, dx				; save upper-left corner (adj)
	push	ax, bx				; save upper-left corner
	push	ax, bx				; save upper-left corner

	; Draw the vertical lines first (we can skip the first and last
	; ones, as we draw a rectange around the entire object last)
	;
	add	ax, ds:[si].MI_leftMargin	; left boundary => AX
	mov	dx, bx
	add	bx, ds:[si].MI_offsetDOW	; upper boundary => BX
	add	dx, ds:[si].MI_offsetGrid
	add	dx, ds:[si].MI_monthBottom	; lower boundary => DX
	mov	bp, ds:[si].MI_dateWidth	; put date width into BP
	mov	cx, 6				; # lines to draw
verticalLoop:
	push	cx				; save the count
	add	ax, bp				; position next line
	mov	cx, ax				; left = right
	call	GrDrawLine			; draw the line
	pop	cx
	loop	verticalLoop			; loop if not done

	; Draw the line between the month title & the DOW
	;
	pop	ax, bx				; restore upper-left corner
	add	ax, ds:[si].MI_leftMargin	; left boundary => AX
	add	bx, ds:[si].MI_offsetDOW	; top boundary => BX
	mov	cx, ds:[si].MI_monthRight	; right boundary => CX
	mov	dx, bx				; bottom boundary => DX
	call	DrawThickLine			; draw the line

	; Now for the rest of the horizontal lines
	;
	pop	ax, bx				; restore upper-left corner
	add	ax, ds:[si].MI_leftMargin	; left boundary => AX
	add	bx, ds:[si].MI_offsetGrid	; top boundary => BX
	mov	cx, ds:[si].MI_monthRight	; right boundary => CX
	mov	bp, ds:[si].MI_dateHeight	; date height => BP

	; Do thick line first (under days of week)

	mov	dx, bx
	call	DrawThickLine

	; Now move on to the rest of the lines

	mov	dl, ds:[si].MI_numberRows	; get number of rows
	dec	dl
horizontalLoop:
	push	dx				; save the count
	add	bx, bp				; position the next line
	mov	dx, bx				; upper = lower
	call	GrDrawLine			; draw the line
	pop	dx				; get count back
	dec	dl				; count down
	jge	horizontalLoop			; jump if not done

	; Draw a 2-pixel wide rectagle around the entire object. At
	; this point, we have the lower-right corner in (CX, BX), so
	; don't lose it!
	;
	call	GrGetLineWidth
	movdw	bpsi, dxax
	mov	dx, 2
	clr	ax
	call	GrSetLineWidth
	mov	dx, bx				; lower-right => CX:DX
	pop	ax, bx				; restore upper-left corner
						; ...of month (margins inc.)
	inc	cx
	inc	dx
	call	GrDrawRect			; draw the rectangle
	movdw	dxax, bpsi
	call	GrSetLineWidth

	.leave
	ret
MonthDrawGrid	endp

DrawThickLine	proc	near
	uses	ax, dx, bp, si
	.enter

	movdw	bpsi, dxax
	call	GrGetLineWidth
	pushdw	dxax				; save original thickness
	mov	dx, 2
	clr	ax
	call	GrSetLineWidth
	movdw	dxax, bpsi			; restore upper-left corner
	call	GrDrawLine			; draw the line
	popdw	dxax
	call	GrSetLineWidth

	.leave
	ret
DrawThickLine	endp
endif

if	COL_MAJOR_MONTH
MonthDrawGrid	proc	near
	class	MonthClass			; friend to this class
	uses	si
	.enter

	call	VisGetBounds			; get my boundaries
	mov	si, ds:[si]			; dereference it
	add	si, ds:[si].Month_offset	; access my instance data
	mov	bp, ds:[si].MI_dateWidth	; put date width into BP
if	not COL_MAJOR_MONTH			; responder--no border
	add	ax, ds:[si].MI_leftMargin	; left boundary
endif
	add	bx, ds:[si].MI_offsetGrid	; upper boundary
	push	ax, bx				; save upper left corner

	; Draw the vertical lines first
	;
	mov	dx, bx				; top into DX
	add	dx, ds:[si].MI_monthBottom	; lower boundary
	mov	cx, 8

if	CLAIM_UNUSED_MONTH_SPACE
	;
	; Do not draw an extra line if the month does not span 6 weeks.
	;
	test	ds:[si].MI_flags, mask SPAN_6_WEEKS
	jnz	gotNumOfLines	
	mov	cx, 7				; we only have 5 weeks
gotNumOfLines:
endif	; CLAIM_UNUSED_MONTH_SPACE

	sub	ax, bp				; start at left edge

	; Draw the vertical lines
	;

if	HAS_MIN_WEEK_DAY_WIDTH
	;-----------------------------------------------------------------
	; There is minimum space in the weekday column. So, we want to draw
	; out left month border first and then the weekday column (2nd
	; line) as this is the only different column.
	;-----------------------------------------------------------------

	;
	; Draw equal column space if column width is bigger than minimum
	;
	cmp	ds:[si].MI_dateWidth, MIN_WEEK_DAY_WIDTH
	jae	verticalLoop

	;
	; Draw the month view's left border
	;
	sub	cx, 2				; don't count these 2 lines 
	push	cx				; save line count
	add	ax, bp
	mov	cx, ax
	call	GrDrawLine

	;
	; Draw the right line of weekday's column
	;
	add	ax, MIN_WEEK_DAY_WIDTH
	mov	cx, ax
	call	GrDrawLine
	pop	cx				; restore line count
endif   ; HAS_MIN_WEEK_DAY_WIDTH

verticalLoop:
	push	cx				; save the count
	add	ax, bp				; position next line
	mov	cx, ax				; left = right
	call	GrDrawLine			; draw the line
	pop	cx
	loop	verticalLoop			; loop if not done

	; Now for the horizontal lines
	;
	pop	ax, bx				; restore upper-left corner
	push	bx				; save the top position
	mov	bp, ds:[si].MI_dateHeight	; date height into BP
	mov	cx, ds:[si].MI_monthRight	; right boundary

	; Now draw the horizontal lines
	;	
	pop	bx				; y coord of upper left
	mov	dx, bx
	push	ax, bx, cx, dx
	call	GrDrawLine
	add	bx, bp
RSP <	dec	bx				; not draw too close to dates>
	mov	dx, bx
	call	GrDrawLine
	pop 	ax, bx, cx, dx
	add	bx, ds:[si].MI_monthBottom
	mov	dx, bx
	inc	cx
	call	GrDrawLine

	.leave
	ret
MonthDrawGrid	endp
endif

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawWeekDays
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the day of week strings in their correct positions

CALLED BY:	MonthDraw

PASS:		DS:*SI	= Month instance data
		DI	= GState handle
		ES	= dgroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		Center all strings over the date columns

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDrawWeekDays	proc	near
	class	MonthClass			; friend to this class
	uses	si, ds, es
	.enter

	; Initialize counters and stuff
	;
	call	VisGetBounds			; get my bounds
	mov	si, ds:[si]
	add	si, ds:[si].Month_offset	; access instance data
if COL_MAJOR_MONTH
if	HAS_MIN_WEEK_DAY_WIDTH
	mov	bp, ds:[si].MI_weekdayWidth
else
	mov	bp, ds:[si].MI_dateWidth	; Hello!!! Get more REGISTERS
endif

	mov	es:[dateWidth], bp
	mov	bp, ds:[si].MI_dateHeight
else
	mov	bp, ds:[si].MI_dateWidth	; put date width into BP
	add	ax, ds:[si].MI_leftMargin	; starting position
endif
if COL_MAJOR_MONTH
	mov	es:[startXPos], ax
	add	bx, ds:[si].MI_offsetGrid	; days of week offset
else
	add	bx, ds:[si].MI_offsetDOW	; days of week offset
	inc	bx
endif
	push	ax, bx

	; Set up to write day names
	;
	mov	bx, handle DataBlock
	call	MemLock				; lock the block
if COL_MAJOR_MONTH
	mov	si, offset DataBlock:wktext
else
	mov	si, offset DataBlock:suntext
endif
	mov	ds, ax				; set up the segment
	pop	ax, bx				; get beginning position

	; Begin string draw loop
drawLoop:
	push	si				; save the handle
	mov	si, ds:[si]			; dereference the handle
if COL_MAJOR_MONTH
	ChunkSizePtr	ds, si, cx		; length of string => CX
	call	GrTextWidth			; get width of string
	
	; Calculate the string position, and write it
	;
	push	bp
	mov	bp, es:[dateWidth]
	sub	bp, dx
	sub	bp, WEEK_DAY_RIGHT_MARGIN
	add	ax, bp
	pop	bp
	call	GrDrawText
else
	ChunkSizePtr	ds, si, cx		; length of string => CX
	call	GrTextWidth			; get width of string
	
	; Calculate the string position, and write it
	;
	sub	dx, bp				; subtract total width 
	neg	dx
	shr	dx, 1				; divide difference by two
	add	ax, dx				; finish center calculation
	call	GrDrawText			; write the string
endif
	; Calculate next string and its position
	;
	pop	si				; get string handle
if COL_MAJOR_MONTH
	mov	ax, es:[startXPos]
else
	sub	ax, dx				; back to left X position
endif
	add	si, 2				; increment the handle
if COL_MAJOR_MONTH
	add	bx, bp
else
	add	ax, bp				; move over by one width
endif
if COL_MAJOR_MONTH
	cmp	si, offset DataBlock:suntext	; the last string ??
else
	cmp	si, offset DataBlock:sattext	; the last string ??
endif
	jle	drawLoop			; jump if not done

	; We're done now
	;
	mov	bx, handle DataBlock
	call	MemUnlock			; unlock the block	

	.leave
	ret
MonthDrawWeekDays	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawDates
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write the date strings in their correct positions

CALLED BY:	MonthDraw

PASS:		DS:*SI	= Month instance data
		DI	= GState handle
		ES	= dgroup
		
RETURN:		DS:BP	= MonthClass specific instance data

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/6/89		Initial version
	RR	4/12/95		draw in column major for responder
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DATES_OFFSET	= 2				; hor offset for date strings

MonthDrawDates	proc	near
	class	MonthClass			; friend to this class
	uses	si
	.enter

	; A lot of set-up work
	;
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].Month_offset	; access instance data

if COL_MAJOR_MONTH				; remember date width for
	mov	ax, ds:[bp].MI_dateWidth	; right justification
	mov	es:[dateWidth], ax
endif
	call	VisGetBounds			; top-left to AX:BX
if COL_MAJOR_MONTH
	add	ax, DATES_OFFSET		; starting X position

if	HAS_MIN_WEEK_DAY_WIDTH
	add	ax, ds:[bp].MI_weekdayWidth
else
	add	ax, ds:[bp].MI_dateWidth
endif   ; HAS_MIN_WEEK_DAY_WIDTH

else
	add	ax, ds:[bp].MI_leftMargin
	add	ax, DATES_OFFSET		; starting X position
endif
	add	bx, ds:[bp].MI_offsetGrid	; starting Y position
	mov	cl, ds:[bp].MI_firstDayPos	; offset to first date
if COL_MAJOR_MONTH
	cmp	cl, 0				; fix week to start at Mon
	jne	continue
	mov	cl, 7
endif
continue::
	mov	ch, ds:[bp].MI_daysThisMonth	; total count into CH
	push	ax				; save left boundary
	neg	cl				; create a countdown value
	mov	ds:[bp].MI_lastDayGrid, cl	; store the last day value...
	add	ds:[bp].MI_lastDayGrid, 42	; after we add # of gird spaces
	mov	dl, '1'				; set the ones character
	mov	dh, '0'				; set the tens character
	mov	si, bp	
	add	si, offset MI_dateString	; DS:SI points at string
SBCS <	mov	{byte} ds:[si] + 2, 0		; NULL terminated	>
DBCS <	mov	{wchar} ds:[si][4], 0		; NULL terminated	>

	; Begin string write loop
	;
writeLoop:
	inc	cl				; go to the next position
	call	MonthDrawDateBG			; draw the day's background
	tst	cl
	jle	nextPosition			; if before 1st, do nothing
	cmp	cl, ch				; compare with last date
	jg	nextPosition			; if after last, do nothing
	cmp	dh, '0'				; is first character a space ?
	je	shortString			; jump if true
SBCS <	mov	ds:[si] + 0, dh			; tens character	>
SBCS <	mov	ds:[si] + 1, dl			; ones character	>
DBCS <	mov	ds:[si] + 0, dh						>
DBCS <	mov	{byte}ds:[si] + 1, 0					>
DBCS <	mov	ds:[si] + 2, dl						>
DBCS <	mov	{byte}ds:[si] + 3, 0					>
	jmp	writeString
shortString:
	mov	ds:[si] + 0, dl			; ones character
DBCS <	mov	{byte}ds:[si] + 1, 0					>
SBCS <	mov	{byte} ds:[si] + 1, 0		; end of string		>
DBCS <	mov	{wchar} ds:[si][2], 0		; end of string		>

	; Write the string, & set-up for the next string
	;
writeString:
if COL_MAJOR_MONTH				; right justify
	push	ax
endif
	push	cx				; save the day counter

if COL_MAJOR_MONTH				; right justify
	mov	cx, 3
	push	dx
	call	GrTextWidth
	mov	cx, es:[dateWidth]
	sub	cx, dx
	pop	dx
	sub	cx, 6
	add	ax, cx
endif
	clr	cx				; null-terminated string
	call	GrDrawText			; write the string
	pop	cx				; restore day counter
if COL_MAJOR_MONTH				; right justify
	pop 	ax
endif
	inc	dl				; update ones-digit
	cmp	dl, '9'				; too big ??
	jle	nextPosition			; no, loop again
	mov	dl, '0'				; reset ones digit
	inc	dh				; increment tens digit

	; Now set up position for the next string
	;
nextPosition:
	cmp	cl, ds:[bp].MI_lastDayGrid	; are we done yet ??
	je	done				; yes, boogie
if COL_MAJOR_MONTH
	add	bx, ds:[bp].MI_dateHeight	; update y-postion
	push 	cx
	mov	cx, ds:[bp].MI_monthBottom
	add	cx, ds:[bp].MI_dateHeight
	cmp	bx, cx				; too far bottom ?
	pop	cx
	jl	writeLoop			; no
	add	ax, ds:[bp].MI_dateWidth	; update x-postion
	mov	bx, ds:[bp].MI_offsetGrid	; adjust y-position
	add	bx, ds:[bp].MI_dateHeight
	jmp	writeLoop
else
	add	ax, ds:[bp].MI_dateWidth	; update x-postion
	cmp	ax, ds:[bp].MI_monthRight	; too far over ?
	jl	writeLoop			; no
	pop	ax				; get left boundary back
	push	ax				; push it again
	add	bx, ds:[bp].MI_dateHeight	; adjust y-position
	jmp	writeLoop
endif
done:
	pop	ax				; clear the stack

	.leave
	ret
MonthDrawDates	endp

if WEEK_NUMBERING

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawWeekNumbers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw week numbers for current month

CALLED BY:	MonthDrawDates

PASS:		DS:*SI	= Month instance data
		DI	= GState handle
		ES	= dgroup
				
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

	Frighten the sheep
	if month is not Jan
		calculate days between Jan 1 and current month's 1
		;
		MUST ADD DAYS WHICH ARE MISSING IN FIRST WEEK
		(sean 12/12/95)
		; 
		divide it by 7 and add 1 to get week number
		if Jan 1 is after Thursday
			add 1 to week number
		write week numbers
	else
		if Jan 1 is after Thursday 
			first column = 52, then 1 ...
		else
			first column = 1 ...	
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RR	4/20/95    	Initial version
	sean	10/5/95		Fixed one day too many bug
	sean 	12/12/95	Fixed bugs #48617 & #48114
	sean	4/4/96		Fixed 53 week year problem.
				Fixes #54031.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
MonthDrawWeekNumbers	proc	near
	class	MonthClass
	range	local	RangeStruct	; Jan 1 to month 1
	cWidth	local	word		; width of columns
	yPos	local	word		; starting y position
	xPos	local	word		; starting x position
	extraWeek	local	BooleanByte	; if this year has 53 weeks
	uses	ax,bx,cx,dx,si,di,bp
	.enter

	call	VisGetBounds
	mov	xPos, ax

	; find days between month and Jan 1

	mov	bx, ds:[si]			; dereference the handle
	add	bx, ds:[bx].Month_offset	; access instance data

	mov	extraWeek, BB_FALSE
	call	CheckIfFiftyThreeWeeksInCurrentYear
	jnc	noExtraWeek
	mov	extraWeek, BB_TRUE	
noExtraWeek:
	
	mov	ax, ds:[bx].MI_dateWidth
	mov	cWidth, ax

	mov	ax, ds:[bx].MI_offsetGrid
	mov	yPos, ax

	cmp	ds:[bx].MI_month, 1		; Is it jan?
	jne	saneCase

	push	bp
	mov	dl, 1
	mov	dh, 1
 	mov	bp, ds:[bx].MI_year
	call	CalcDayOfWeek		; cl = dow for Jan 1
	pop	bp

	; if Jan 1 is fri, sat, or sun, first week = 52

	tst	cl			; check for sunday
	jz	start52

	cmp	cl, 5
	jge	start52			; check fri, sat
	
	; Jan 1 is in week 1

	mov	dl, '1'			; ones digit
	mov	dh, '0'			; tens digit
	mov	si, bx
	add	si, offset MI_dateString	; DS:SI -> string
	mov     {byte} ds:[si] + 2, 0           ; NULL terminated       

	mov	ax, xPos
if	COL_MAJOR_MONTH
	add	ax, DATES_OFFSET
else
	add	ax, MONTH_BORDER_TOP + DATES_OFFSET
endif

if	HAS_MIN_WEEK_DAY_WIDTH
	add	ax, ds:[bx].MI_weekdayWidth
else
	add	ax, cWidth
endif
	mov	bx, yPos
	mov	cx, 6				; 6 columns

	jmp	writeLoop

start52:
	; Jan 1 is in week 52 of previous year

	mov	si, bx
	add	si, offset MI_dateString
	mov	{byte} ds:[si] + 0, '5'
	mov	{byte} ds:[si] + 1, '3'		; assume 53
	call	CheckIfFiftyThreeWeeksInPreviousYear
	jc	fiftyThreeWeeks		
	mov	{byte} ds:[si] + 1, '2'		; only 52 weeks
fiftyThreeWeeks:
	mov     {byte} ds:[si] + 2, 0           ; NULL terminated       >

	mov	cx, cWidth
	call	GrTextWidth
	sub	cx, dx
	sub	cx, 6				; cx = offset for right just.

	mov	ax, xPos
if	COL_MAJOR_MONTH
	add	ax, DATES_OFFSET
else
	add	ax, MONTH_BORDER_TOP + DATES_OFFSET
endif

if	HAS_MIN_WEEK_DAY_WIDTH
	add	ax, ds:[bx].MI_weekdayWidth
else
	add	ax, cWidth
endif	; HAS_MIN_WEEK_DAY_WIDTH

	push	ax
	add	ax, cx				; right justification
	mov	bx, yPos

	call	GrDrawText

	pop	ax
	add	ax, cWidth			; 2nd column
	mov	dl, '1'
	mov	dh, '0'

	mov	cx, 5				; 5 more columns
	jmp	writeLoop	

saneCase:

;*******************************

	mov	range.RS_startDay, 1
	mov	range.RS_startMonth, 1

	mov	range.RS_endDay, 1

	mov	al, ds:[bx].MI_month
	mov	range.RS_endMonth, al

	mov	ax, ds:[bx].MI_year
	mov	range.RS_startYear, ax
	mov	range.RS_endYear, ax

	push	es, bp
	segmov	es, ss, ax
	lea	bp, range
	call	CalcDaysInRange			; days in cx
	dec	cx			; range inclusive--decrement(sean)
	pop	es, bp
	mov	ax, cx			

	push	bp
	mov	dl, 1
	mov	dh, 1
	mov	bp, ds:[bx].MI_year
	call	CalcDayOfWeek		; cl = dow for Jan 1
	pop 	bp

 	; if Jan 1 is fri, sat, or sun, add 1 to week #

	tst	cl			; check for sunday
	jne	checkFri
	dec	ax			; Year starts Jan 2
	jmp	drawWeekNumbers

checkFri:
	cmp	cl, 5
	jne	checkSat		; check fri
	sub	ax, 3			; year starts Jan 4
	jmp	drawWeekNumbers

checkSat:
	cmp	cl, 6
	jne	notFriSatSun
	sub	ax, 2			; year starts Jan 3
	jmp	drawWeekNumbers

	; We have to add the number of days that we're missing in
	; first week.  For example, if Jan 1st is on a Wed., then
	; the first week can only hold 5 days, and we must add two
	; days for our upcoming division.  sean 12/12/95.  Fixes
	; #48114 & #48617.
	;
notFriSatSun:
	dec	cl			; cl = number of days missing
	clr	ch
	add	ax, cx			; in first week of year
	
drawWeekNumbers:

	mov	dl, 7		; divide range by 7 to get week #
	div	dl
	inc	al			; al = week #
	mov	cx, 6			; 6 columns

        ; al change to correct number string in dh.dl

	clr	ah
	mov	dl, 10
	div	dl			
	xchg	al, ah			; tens in al, ones in ah

	add	al, '0'
	add	ah, '0'
	mov	dx, ax			; dh.dl = number

	mov	si, bx
	add	si, offset MI_dateString	; DS:SI -> string

	mov     {byte} ds:[si] + 2, 0           ; NULL terminated      

	mov	ax, xPos
if	COL_MAJOR_MONTH
	add	ax, DATES_OFFSET
else
	add	ax, MONTH_BORDER_TOP + DATES_OFFSET
endif

if	HAS_MIN_WEEK_DAY_WIDTH
	add	ax, ds:[bx].MI_weekdayWidth
else
	add	ax, cWidth
endif	; HAS_MIN_WEEK_DAY_WIDTH

	mov	bx, yPos

writeLoop:

	; Ok, at this point, cx is the number of columns that still need
	; to be numbered.  ax is the left co-ord of the next column to
	; number.  bx is the y co-ord (doesn't change).  dh.dl are the
 	; ascii chars for the next column's number.  ds:si -> MI_dateString,
	; and the string is null terminated.  the sheep are quite scared.

	cmp	dh, '0'			; short string?
	jne	longString
	mov	{byte} ds:[si], C_SPACE
	jmp	onesPlace
	
longString:
	
	; Check that we don't go past week 52 (or 53 if this year has
	; an extra week).  If we do, then make wrap.  sean 12/12/95.
	;
	cmp	dh, C_FIVE
	jne	noOverflow
	cmp	dl, C_TWO
	jle	noOverflow

	; If there's 53 weeks in this year, we don't wrap.  Instead
	; we write 53.
	;
	cmp	extraWeek, BB_TRUE	; extra week ?
	mov	extraWeek, BB_FALSE	; reset regardless
	je	noOverflow

	; Past last week, so wrap to week 1 or week 2
	;
	mov	{byte} ds:[si], C_SPACE
	mov	dl, C_ONE		
	mov	ds:[si] + 1, dl		; ones
	mov	dh, C_ZERO
	jmp	overFlow	
noOverflow:
	mov	ds:[si] + 0, dh		; tens

onesPlace:
	mov	ds:[si] + 1, dl		; ones
overFlow:
	push	cx, dx
	mov	cx, cWidth
	call	GrTextWidth
	sub	cx, dx
	sub	cx, 6				; cx = offset for right just.

	push	ax
	add	ax, cx				; right justification
	clr 	cx			; null terminated

	call	GrDrawText

	pop	ax
	add	ax, cWidth			; next column

	pop	cx, dx 

	cmp	dl, '9'
	je	upTens

	inc	dl
	jmp	endLoop

upTens:
	mov	dl, '0'
	inc	dh

endLoop:
	loop	writeLoop
	.leave
	ret
MonthDrawWeekNumbers	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckIfFiftyThreeWeeksInPrevious/CurrentYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns carry set if 53 weeks in previous/current year.
		Needed for drawing week numbers for January.

CALLED BY:	MonthDrawWeekNumbers

PASS:		*ds:bx	= Month object

RETURN:		carry set 	= YES, fifty-three weeks in previous/
					current year
		carry clear 	= NO, only fifty-two weeks in
					previous/current year

DESTROYED:	nothing

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	sean	4/ 4/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CheckIfFiftyThreeWeeksInPreviousYear	proc	near
	uses	bp
	.enter

 	mov	bp, ds:[bx].MI_year
	dec	bp			; previous year
	call	CheckFiftyThreeWeeks

	.leave
	ret
	
CheckIfFiftyThreeWeeksInPreviousYear	endp

CheckIfFiftyThreeWeeksInCurrentYear	proc	near
	uses	bp
	.enter

	mov	bp, ds:[bx].MI_year
	call	CheckFiftyThreeWeeks

	.leave
	ret
CheckIfFiftyThreeWeeksInCurrentYear	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawDateBG
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the background of a day of the month

CALLED BY:	MonthDrawDates()
	
PASS:		DS:BP	= MonthClass specific instance data
		DI	= GString/GState
		AX	= Left position
		BX	= Top position
		CL	= Current date (may be negative!)
		CH	= Days in this month

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDrawDateBG	proc	near
	class	MonthClass
	uses	ax, bx, cx, dx
	.enter

	; If we're drawing to screen, draw BG only for actual days
	;
	test	ds:[bp].MI_flags, MI_PRINT
	jne	checkPrinting		
	tst	cl
	jle	exit				; if before 1st, do nothing
	cmp	cl, ch				; compare with last date
	jg	exit				; if after last, do nothing

	; Set-up the area color
drawCommon:
	mov_tr	cx, ax
	mov	dx, bx
	call	GrGetAreaColor
	push	ax, bx				; save old color
	movdw	bxax, es:[monthBGColor]
	call	GrSetAreaColor			; set area color to black

	; Draw a square
	;
	sub	cx, DATES_OFFSET		; account for the string offset
	mov	ax, cx	
	mov	bx, dx
	add	cx, ds:[bp].MI_dateWidth	; right bounds
	add	dx, ds:[bp].MI_dateHeight	; lower bounds
	inc	ax
	inc	bx
	call	GrFillRect			; draw the square

	; Restore the area color
	;
	pop	ax, bx
	call	GrSetAreaColor			; restore the area color
exit:
	.leave
	ret

	; If we're printing, then we invert where we draw the background
	; (only on non-days in each month) in order to make it easier to
	; read and to save ink.
checkPrinting:
	tst	cl
	jle	drawCommon
	cmp	cl, ch
	jle	exit
	jmp	drawCommon
MonthDrawDateBG	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawNoteToday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invert today's box if possible

CALLED BY:	(INTERNAL) MonthDraw, MonthSetMonthMap
PASS:		DS:*SI	= MonthClass instance data
		DI	= GState handle
		
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/24/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDrawNoteToday	proc	near
	class	MonthClass			; friend to this class
	
	; See if month displayed is current month
	;
	mov	bp, ds:[si]			; dereference handle
	add	bp, ds:[bp].Month_offset	; access my instance data
	test	ds:[bp].MI_flags, MI_PRINT	; are we printing ??
	jnz	done				; yes, so don't do anything
	call	TimerGetDateAndTime		; get today's date
	cmp	ax, ds:[bp].MI_year		; compare the years
	jne	done
	cmp	bl, ds:[bp].MI_month		; compare the months
	jne	done

	; Yes, we can invert today
	;
	push	di				; save the GState
	mov	di, bp				; instance data => DS:DI
	mov	cl, bh				; today => CL
	mov	ch, bh				; also to CH
	mov	bp, ds:[si]			; dereference the handle
	add	bp, ds:[bp].Vis_offset		; access visual data
	call	MonthSelectCalc			; left => AX
						; top => BX
	mov	cx, ax
	add	cx, ds:[di].MI_dateWidth	; right position in CX
	mov	dx, bx
	add	dx, ds:[di].MI_dateHeight	; bottom position in DX
	pop	di				; GState => DI

	; Simply draw a box for both color and B&W
	;
	inc	ax				; left
if	not COL_MAJOR_MONTH		
	inc	bx				; top
endif		
	dec	cx				; bottom
	dec	dx				; right
	call	GrDrawRect			; draw the frame

done:
	ret
MonthDrawNoteToday	endp

	
MonthDrawMonthMap	proc	near
	class MonthClass

	uses	si
	.enter
		
	push	di				; save the GState handle
	mov	al, MM_INVERT			; want invert color	
	call	GrSetMixMode			; set the drawing mode

	mov	di, ds:[si]			; dereference the chunk handle
	mov	bp, di
	add	di, ds:[di].Month_offset	; access my instance data
	add	bp, ds:[bp].Vis_offset		; access my visual data
	mov	cl, 1				; start at day 1
	mov	ch, 32				; calculate the true last day
	call	MonthSelectCalc			; upper-left corner => AX:BX
						; last day of month => CH
	mov	si, bp				; Vis instance dara => SI
	mov	bp, di				; Month instance data => BP
	pop	di				; GState => DI
	test	ds:[bp].MI_flags, MI_PRINT	; are we printing ??
	jnz	done				; yes, so don't do anything
	mov	dx, ds:[bp].MI_monthMap.low	; low monthMap word => DX
	tst	ds:[bp].MI_monthMap.high	; any data ??
	jnz	doWork				; yes, so do real work
	tst	ds:[bp].MI_monthMap.low		; any data ??
	jz	done				; none at all, so we're done
doWork:
	shr	dx				; clear day 0
	push	ds:[bp].MI_monthMap.high	; save the high word
	add	ax, ds:[bp].MI_dateWidth
	dec	ax				; right boundary => AX
	add	bx, ds:[bp].MI_dateHeight
if 	COL_MAJOR_MONTH
else
	dec	bx				; bottom boundary => BX
endif
	
	; Draw loop
	;
drawLoop:
	shr	dx				; shift out the next day
	jnc	next1				; if bit not set, skip
	call	MonthDrawMonthMapDay		; draw one day
next1:
	inc	cl				; go to the next day
	cmp	cl, 16				; get the high word ??
	jne	next2				; no, continue
	pop	dx				; high MonthMap word => DX
next2:
if	COL_MAJOR_MONTH
	add	bx, ds:[bp].MI_dateHeight
	push	cx
	mov	cx, ds:[bp].MI_monthBottom
	add	cx, ds:[bp].MI_dateHeight
	add	cx, ds:[bp].MI_dateHeight
	cmp	bx, cx				; too far down??
	pop 	cx
	jle	next3

	add	ax, ds:[bp].MI_dateWidth	; update x
	mov	bx, ds:[bp].MI_offsetGrid	; adjust y
	add	bx, ds:[bp].MI_dateHeight
	add	bx, ds:[bp].MI_dateHeight
else
	add	ax, ds:[bp].MI_dateWidth
	cmp	ax, ds:[bp].MI_monthRight	; too far right ??
	jle	next3
	mov	ax, ds:[si].VI_bounds.R_left	; calculate left-most...
	add	ax, ds:[bp].MI_leftMargin
	add	ax, ds:[bp].MI_dateWidth	;
	dec	ax				; ...right-side boundary
	add	bx, ds:[bp].MI_dateHeight	; go to the next row
endif
next3:
	cmp	cl, ch
	jle	drawLoop

done:
	mov	al, MM_COPY			; set back to normal mode
	call	GrSetMixMode			; set the drawing mode

	.leave
	ret
MonthDrawMonthMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawMonthMapDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draws the indication that an event is on this day

CALLED BY:	(INTERNAL) MonthDrawMonthMap
PASS:		DS:BP	= MonthClass specific instance data
		AX	= Right boundary of the day
		BX	= Bottom boundary of the day
		DI	= GState handle
		CL	= Resp. Color index (responder only)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/30/90		Initial version
	RR	5/31/95		Responder Icon
	kliu	2/23/97		Add parameter cl for resp. color index

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TRIANGLE_SIZE		= 5
TRIANGLE_SIZE_CUI	= 12

MonthDrawMonthMapDay	proc	near
	class	MonthClass
	uses	ax, bx, cx, si, ds
	.enter

	; Set up for the call
	;
	sub	sp, size MonthMapDayStruct	; allocate point array on stack
	mov	si, sp
	segmov	ds, ss, cx			; DS:SI => point array
	dec	ax
	dec	bx
	mov	ds:[si].MMDS_point1.P_x, ax	; first point
	mov	ds:[si].MMDS_point1.P_y, bx
	mov	ds:[si].MMDS_point2.P_x, ax	; second point
	mov	ds:[si].MMDS_point2.P_y, bx
	mov	ds:[si].MMDS_point3.P_x, ax	; third point
	mov	ds:[si].MMDS_point3.P_y, bx
	sub	ds:[si].MMDS_point1.P_x, TRIANGLE_SIZE
	sub	ds:[si].MMDS_point3.P_y, TRIANGLE_SIZE

	; Make the triangle larger in the CUI to make it more visible.
	; We really should check to see how large the month is to
	; make sure this size will fit, but in the CUI the calendar is
	; maximized and the minimum screen size supported in 640x440, so
	; we never hit the size limitation. Still, not great. -Don 5/14/00
	;
	call	UserGetDefaultUILevel		; UIInterfaceLevel => AX
	cmp	ax, UIIL_INTRODUCTORY
	jne	draw
	sub	ds:[si].MMDS_point1.P_x, (TRIANGLE_SIZE_CUI - TRIANGLE_SIZE)
	sub	ds:[si].MMDS_point3.P_y, (TRIANGLE_SIZE_CUI - TRIANGLE_SIZE)
draw:
	mov	al, RFR_ODD_EVEN		; use this fill rule
	mov	cx, 3				; 3 points in the polygon
	call	GrFillPolygon			; draw the triangle
	add	sp, size MonthMapDayStruct	; clean up the stack

	.leave
	ret
MonthDrawMonthMapDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSelectDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw selected regions of a month.

CALLED BY:	UI (MSG_MONTH_SELECT_DRAW)

PASS:		BP	= GState
		DS:DI	= MonthClass specific instance data
		CL	= First day
		CH	= Last day

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:
		

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/20/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSelectDraw	method	dynamic MonthClass, MSG_MONTH_SELECT_DRAW
	
	; Calculate first day's position
	;
	cmp	cl, ch				; compare first with last
	jg	done
	cmp	ch, 1				; not in month
	jl	done				; don't do anything
	cmp	cl, ds:[di].MI_daysThisMonth
	jg	done				; not in month
	cmp	cl, 1
	jge	calculate
	mov	cl, 1
calculate:
	push	bp				; save the GState handle
	mov	bp, ds:[si]
	add	bp, ds:[bp].Vis_offset		; access visual data
	call	MonthSelectCalc			; calculate vital data

	; Keep track of left boundary
	;
	mov	dx, ds:[bp].VI_bounds.R_left
if	not COL_MAJOR_MONTH			; responder--no border
	add	dx, ds:[di].MI_leftMargin	; left boundary
endif
	mov	bp, di				; DS:BP points to instance data
	pop	di				; GState into DI
	sub	ch, cl				; count => CH
	mov	cl, ch				; count => CL
	inc	cl				; want end-start+1
	clr	ch				; count => CX

if PZ_PCGEOS ; Pizza
	; Check holiday setting mode
	;
	push	ax, bx, cx, dx, bp, si, di
	mov	ax, MSG_JC_SHIC_GET_USABLE
	GetResourceHandleNS	SetHoliday, bx
	mov	si, offset SetHoliday
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	ax, bx, cx, dx, bp, si, di
	jnb	drawLoop			; if not usable

	; Just holiday loop
drawHolidayLoop:
	call	MonthSelectHolidayRect		; draw the rectangle
	add	ax, ds:[bp].MI_dateWidth
	cmp	ax, ds:[bp].MI_monthRight	; too far right ??
	jl	nextHoliday
	mov	ax, dx				; AX = left boundary
	add	bx, ds:[bp].MI_dateHeight	; go to the next row
nextHoliday:
	loop	drawHolidayLoop			; loop until done
	mov	bp, di				; GState returned to BP
	jmp	done
endif

	; Just loop
drawLoop:
	call	MonthSelectRect			; draw the rectangle
	add	ax, ds:[bp].MI_dateWidth
	cmp	ax, ds:[bp].MI_monthRight	; too far right ??
	jl	next
	mov	ax, dx				; AX = left boundary
	add	bx, ds:[bp].MI_dateHeight	; go to the next row
next:
	loop	drawLoop			; loop until done
	mov	bp, di				; GState returned to BP
done:
	ret
MonthSelectDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSelectCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Caclulate first day's position

CALLED BY:	(EXTERNAL) MonthDrawMonthMap, MonthDrawNoteToday,
		MonthSelectDraw, MonthDrawEvents
PASS:		DS:DI	= Month instance data
		DS:BP	= Month visual data
		CL	= First day
		CH	= Last day

RETURN:		AX	= Left position of square
		BX	= Top position of square
		CH	= Correct last day (if greater than true days in month)

DESTROYED:	DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/16/89		Initial version
	RR	5/31/95		Change to column major for Responder
	RR	8/4/95		Fixed Sunday bug

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSelectCalcFar	proc	far
	call	MonthSelectCalc
	ret
MonthSelectCalcFar	endp

MonthSelectCalc	proc	near
	class	MonthClass			; friend to this class
	
	; Do we need to re-calculate the size stuff
	;
	test	ds:[di].MI_flags, MI_NEW_SIZE	; do we need to recalc the size
	jz	start				; no, we're OK
	CallMod	MonthDrawCalculate		; else perform the calculation

	; Calculate column and row
	;
start:
if 	COL_MAJOR_MONTH
	mov	al, ds:[di].MI_firstDayPos	; convert to col. major
	tst	al
	jz	SundayHack			; (0 - 1) % 7 = 6
	dec	al
	jmp	Continue

SundayHack:
	mov	al, 6

Continue:
	add	al, cl				; add in first day's position
	clr	ah
	mov	dl, 7
	div	dl				; AL = rows, AH = columns
	tst	ah
	jnz	Transpose

	dec	al
	mov	ah, 7
Transpose:
	mov	bl, ah				; BL = columns
	xchg	al, bl				; Transpose
	inc	bl
else
	mov	al, cl
	add	al, ds:[di].MI_firstDayPos	; add in first day's position
	dec	al
	clr	ah
	mov	dl, 7
	div	dl				; AL = rows, AH = columns
	mov	bl, ah				; BL = columns
endif
	; Now calculate true position
	;
	clr	ah				; clear the high byte
	mul	ds:[di].MI_dateHeight		; multiply height by rows
	xchg	bx, ax				; assume less than 2^16
	clr	ah
if	HAS_MIN_WEEK_DAY_WIDTH
	;
	; Multiply by 1 fewer column, then add the weekday column width
	;
	dec	al				; multiply 1 fewer column
	mul	ds:[di].MI_dateWidth
	add	ax, ds:[di].MI_weekdayWidth
else
	mul	ds:[di].MI_dateWidth		; multiply width by columns
endif

	; Now position this square 
	;
if	not COL_MAJOR_MONTH
	add	ax, ds:[di].MI_leftMargin	; add in X offset
endif
	add	bx, ds:[di].MI_offsetGrid	; add in Y offset
	add	ax, ds:[bp].VI_bounds.R_left	; add left position of month
	add	bx, ds:[bp].VI_bounds.R_top	; andd in top position.

	; Check last day
	;
	cmp	ch, ds:[di].MI_daysThisMonth
	jle	done
	mov	ch, ds:[di].MI_daysThisMonth
done:
	ret
MonthSelectCalc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSelectRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single inverted rectangle	

CALLED BY:	MonthSelectDraw

PASS:		AX	= Left boundary
		BX	= Top boundary
		DI	= GState
		DS:BP	= Instance data (MonthInstance)

		Responder only:
		DL	= selected day of the month (1-31)		

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/16/89		Initial version
	sean	10/5/95		Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSelectRect	proc	near
	class	MonthClass			; friend to this class

	; Draw the rectangle
	;
	push	cx, dx
	mov	cx, ax	
	mov	dx, bx
	add	cx, ds:[bp].MI_dateWidth	; right bounds
	add	dx, ds:[bp].MI_dateHeight	; lower bounds
	add	ax, 2
	add	bx, 2
	dec	cx
	dec	dx
	call	GrFillRect			; invert the region

	; Clean up
	;
	pop	cx, dx
	sub	ax, 2
	sub	bx, 2
	ret
MonthSelectRect	endp


if PZ_PCGEOS ; Pizza

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSelectHolidayRect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw a single inverted holiday rectangle	

CALLED BY:	MonthSelectDraw

PASS:		AX	= Left boundary
		BX	= Top boundary
		DI	= GState
		DS:BP	= Instance data (MonthInstance)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	6/29/93		Initial version
	Tera	1/3/94		Correspond to various font size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSelectHolidayRect	proc	near
	class	MonthClass			; friend to this class
	uses	ax, bx, cx, dx
	.enter
	
	; Set rect width and height
	;
	mov	cx, ds:[bp].MI_holidayWidth	; width
	mov	dx, ds:[bp].MI_holidayHeight	; height

	; Draw the rectangle
	;
	add	ax, 2
	add	bx, 2
	add	cx, ax				; right bounds
	add	dx, bx				; lower bounds
	call	GrFillRect			; invert the region

	.leave
	ret
MonthSelectHolidayRect	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthMetaPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a button event

CALLED BY:	UI (MSG_META_PTR)

PASS:		CX	= Mouse X position
		DX	= Mouse Y position
		DS:*SI	= Month instance data
		BP	= (low)  ButtonInfo
			  (high) UIFunctionsActive

RETURN:		DX	= Year
		CH	= Month
		CL	= Day

DESTROYED:	AX, BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/20/89		Initial version
	Don	9/13/89		Modified for genGadget usage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthMetaPtr	method	MonthClass, MSG_META_PTR

	test	ds:[di].MI_flags, MI_NEW_SIZE	; check the flag
	jz	buttonCalc			; jump if not set	
	CallMod	MonthDrawCalculate		; calculate my bounds
buttonCalc:
	FALL_THRU	MonthMetaPtrCalc
MonthMetaPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthMetaPtrCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Take raw mouse position, and decide what (if any) day
		the button is over.

CALLED BY:	MonthMetaPtr()

PASS:		CX	= Mouse X position
		DX	= Mouse Y position
		DS:*SI	= Month instance data
		BP	= RoundType
				RT_CLOSEST
				RT_BACKWARD
				RT_FORWARD

RETURN:		CL	= Day of month (if 0, not over a day & data invalid)
		CH	= This month
		DX	= This year
	
DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/13/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthMetaPtrCalc	proc	far
	class	MonthClass			; friend to this class
	uses	di
	.enter

	; Access visual instance data to adjust coordinates
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Vis_offset		; access visual data
	sub	cx, ds:[di].VI_bounds.R_left	; subtract off left boundary
	sub	dx, ds:[di].VI_bounds.R_top	; subtract off top boundary

	; Account for offset within the month
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Month_offset	; access my instance data
	sub	dx, ds:[di].MI_offsetGrid
	sub	cx, ds:[di].MI_leftMargin
	jl	beforeFirst
	cmp	dx, 0				; check top bounds
	jl	beforeFirst			; before first day of the month

	; Find column and row information
	;
	mov	bx, ds:[di].MI_dateWidth
	push	dx				; store the height data
	mov	ax, cx
	clr	dx
	div	bx
	mov	cx, ax				; columns in CL

	pop	ax
	clr	dx
	mov	bx, ds:[di].MI_dateHeight
	div	bx				; do the division
	mov	dx, ax				; rows in DL

	; Check validty of row & column, calaculate day of month
	;
	cmp	cl, 6				; more than six columns
	jg	afterLast

	; Inside the month boundary - calculate the day
	;
	mov	al, dl				; rows to al
	mov	bl, 7
	mul	bl				; multiply
	add	al, cl
	sub	al, ds:[di].MI_firstDayPos	; subtract first day's position
	jl	beforeFirst			; before first day
	inc	al				; increment to actual day
	mov	cl, al				; store day in CL
	cmp	cl, ds:[di].MI_daysThisMonth	; compare with actual days
	jle	done				; if OK - we're done

	; After last day - may be OK or invalid
	;
afterLast:
	mov	cl, 63				; return the last day
	jmp	done
beforeFirst:
	clr	cl				; return 0 as day
done:
	mov	ch, ds:[di].MI_month		; get current month
	mov	dx, ds:[di].MI_year		; get the year

	.leave
	ret
MonthMetaPtrCalc	endp

if PZ_PCGEOS ; Pizza

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawHoliday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw holiday

CALLED BY:	MonthDraw

PASS:		DS:*SI	= Month instance data
		DI	= GState handle
		
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Tera	6/17/93		Initial version
	Tera	1/3/94		Correspond to various font size

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthDrawHoliday	proc	near
	class	MonthClass			; friend to this class
	uses	si
	.enter

	; Some set-up work
	;
	push	di				; save the GState handle
	mov	al, MM_INVERT			; want invert color	
	call	GrSetMixMode			; set the drawing mode
	mov	di, ds:[si]			; dereference the chunk handle
	mov	bp, di
	add	di, ds:[di].Month_offset	; access my instance data
	add	bp, ds:[bp].Vis_offset		; access my visual data
	mov	cl, 1				; start at day 1
	mov	ch, 32				; calculate the true last day
	call	MonthSelectCalc			; upper-left corner => AX:BX
						; last day of month => CH
	mov	si, bp				; Vis instance dara => SI
	mov	bp, di				; Month instance data => BP
	pop	di				; GState => DI
	add	ax, 2h				; add space
	add	bx, 2h				; add space

	; Calc holiday rect width and height
	;	
	push	ax, bx, si			; save AX,BX,SI
						; DI : GState
	mov	ax, '0'				; AX : character
	call	GrCharWidth			; DX,AH = char width
	add	dx, dx				; calc width of 2 chars
	add	ah, ah
	jnc	cnext
	inc	dx				; round AH
cnext:	add	dx, 2h				; extra margin
	mov	ds:[bp].MI_holidayWidth, dx	; save holiday width

	mov	si, GFMI_BASELINE or GFMI_ROUNDED
	call	GrFontMetrics			; DX = height
	mov	ds:[bp].MI_holidayHeight, dx	; save holiday height
	pop	ax, bx, si			; restore AX,BX,SI

	; Get holiday date
	;
	push	ax, si, di, bx, bp
	mov	cx, ds:[bp].MI_year		; set number for this year
	mov	dh, ds:[bp].MI_month		; set number for this month
	mov	dl, ds:[bp].MI_firstDayPos	; set pos of first day of month
	mov	ax, MSG_JC_SHIC_GETHOLIDAYDATE
	GetResourceHandleNS	SetHoliday, bx
	mov	si, offset SetHoliday
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage			; holiday date low => DX
						; holiday date high => CX
	pop	ax, si, di, bx, bp

	push	cx				; save CX
	mov	cl, 1				; start at day 1
	mov	ch, ds:[bp].MI_daysThisMonth	; total count => CH
	shr	dx				; clear day 0

	; Draw loop
	;
drawLoop:
	shr	dx				; shift out the next day
	jnc	next1				; if bit not set, skip

	push	cx, dx				; save data
	mov	cx, ax
	add	cx, ds:[bp].MI_holidayWidth	; width
	mov	dx, bx
	add	dx, ds:[bp].MI_holidayHeight	; height
	call	GrFillRect			; write holiday mark
	pop	cx, dx				; restore data
next1:
	inc	cl				; go to the next day
	cmp	cl, 16				; get the high word ??
	jne	next2				; no, continue
	pop	dx				; hight word
next2:
	add	ax, ds:[bp].MI_dateWidth
	cmp	ax, ds:[bp].MI_monthRight	; too far right ??
	jle	next3
	mov	ax, ds:[si].VI_bounds.R_left	; calculate left-most...
	add	ax, ds:[bp].MI_leftMargin
	add	ax, 2h				; add space
	add	bx, ds:[bp].MI_dateHeight	; go to the next row
next3:
	cmp	cl, ch
	jle	drawLoop

	mov	al, MM_COPY			; set back to normal mode
	call	GrSetMixMode			; set the drawing mode

	.leave
	ret
MonthDrawHoliday	endp
endif

YearCode	ends



PrintCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthSetFont
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the font to draw the month in

CALLED BY:	GLOBAL (MSG_MONTH_SET_FONT)
	
PASS:		DS:DI	= MonthClass specific instance data
		CX	= FontID to use

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthSetFont	method	MonthClass,	MSG_MONTH_SET_FONT
	mov	ds:[di].MI_fontID, cx		; store the font
	ret
MonthSetFont	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthDrawEvents
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call to have events drawn in all the days for this month.

CALLED BY:	GLOBAL (MSG_MONTH_DRAW_EVENTS)
	
PASS:		DS:SI	= MonthClass instance data
		DS:DI	= MonthClass specific instance data
		CX:DX	= OD of the DayPlanObject
		BP	= GState
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/1/90		Initial version
	Don	10/1/90		Moved day loop into the DayPlan code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PRINT_BORDERS	= 2
 
MonthDrawEvents	method	MonthClass,	MSG_MONTH_DRAW_EVENTS
	uses	cx, dx
	.enter

	; Some set-up work
	;
	sub	sp, size MonthPrintRangeStruct
	mov	ax, sp				; PrintRangeStruct => SS:BX
	push	cx, dx, bp, ax			; save everything
	mov	bp, bx
	add	bp, ds:[bx].Vis_offset		; VisInstance => DS:BP
	mov	cx, 1 or 32 shl 8		; 1st and last day
	call	MonthSelectCalcFar		; last day => CH
						; top/left => AX:BX
	; Initialize the PrintRangeStruct
	;
	pop	bp				; PrintRangeStruct => SS:BP
	push	cx				; save start/end date
	mov	dx, ds:[di].MI_year
	mov	ss:[bp].PRS_range.RS_startYear, dx
	mov	ss:[bp].PRS_range.RS_endYear, dx
	mov	dh, ds:[di].MI_month
	mov	ss:[bp].PRS_range.RS_startMonth, dh
	mov	ss:[bp].PRS_range.RS_endMonth, dh
	mov	dx, ds:[di].MI_dateWidth
	mov	ss:[bp].MPRS_dateWidth, dx
	sub	dx, PRINT_BORDERS		; leave a little space
	mov	ss:[bp].PRS_width, dx
	mov	dx, ds:[di].MI_dateHeight
	mov	ss:[bp].MPRS_dateHeight, dx	; store the true height
	mov	cl, ds:[di].MI_datesFont
	clr	ch
	sub	dx, cx				; account for the date
	add	bx, cx				; start down by this much more
	mov	ss:[bp].PRS_height, dx
	pop	cx				; restore the start/end date
	pop	ss:[bp].PRS_gstate
	mov	ss:[bp].PRS_pointSize, 9
	mov	ss:[bp].PRS_specialValue, 1	; limit to one page
	mov	cl, ds:[di].MI_firstDayPos	; 1st day's DOW => CL
	mov	ss:[bp].MPRS_newXOffset, ax	; store the start X offset
	mov	ss:[bp].MPRS_newYOffset, bx	; store the start Y offset
	pop	bx, si				; DayPlanObject => BX:SI

	; Call for all of the events to be drawn
	;
	mov	ax, MSG_DP_PRINT_DATES_EVENTS
	mov	dx, size MonthPrintRangeStruct	; size of the structure
	mov	di, mask MF_STACK		; not a call on the stack
	call	ObjMessage			; send the method
	add	sp, size MonthPrintRangeStruct	; clean up the stack

	.leave
	ret
MonthDrawEvents	endp

PrintCode	ends
