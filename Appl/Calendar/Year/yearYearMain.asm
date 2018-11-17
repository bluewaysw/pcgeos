COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Year
FILE:		yearYearMain.asm

AUTHOR:		Don Reeves, August 24, 1989

ROUTINES:
	Name			Description
	----			-----------
InitCode:
	YearInit		MSG_YEAR_INIT handler
	YearClassSpecBuild	MSG_SPEC_BUILD handler
	YearViewToday		MSG_YEAR_VIEW_TODAY handler

GeometryCode:
	YearRecalcSize		MSG_VIS_RECALC_SIZE handler
	YearCheckWidthMinMax	Ensure width of a month is within tolerances
	YearCheckHeightMinMax	Ensure height of a month is within tolerances
	StartMonthsBoundsCalc	Recalculate the size/bounds of all the months
	YearSetMonthsBounds	Recalculate the size/bounds of one month (CB)
	YearSetMonthSize	MSG_YEAR_SET_MONTH_SIZE handler

YearCode:
	YearPosition		MSG_VIS_POSITION_BRANCH handler
	YearTrackScrolling	MSG_META_CONTENT_TRACK_SCROLLING
	YearDraw		MSG_VIS_DRAW handler
	YearDrawSelection	Draw the selected dates (if any) for a year
	YearChangeMonthMap	MSG_YEAR_CHANGE_MONTH_MAP handler
	YearChangeYear		MSG_YEAR_CHANGE_YEAR handler
	YearChangeNow		MSG_YEAR_CHANGE_NOW handler
	YearSetMonthAndYear	MSG_YEAR_SET_MONTH_AND_YEAR handler
	SetAllMonths		Set all the months to the proper month/year
	PositionYearDocument	Re-positions the make the correct month visible
	YearNameDisplay		Esnure the year (number) is displayed properly
	YearSelectedDatesToDP	MSG_YEAR_SELECTED_DATES_TO_DP handler
	YearSelectDates		MSG_YEAR_SELECT_DATES handler
	YearGetDate		MSG_YEAR_GET_DATE handler (if Responder)
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/25/89		Initial revision
	Don	12/4/89		Use new class & method declarations
	Don	 5/1/92		Reorganized resources

DESCRIPTION:
	Define the procedures that operate on the year object

	$Id: yearYearMain.asm,v 1.1 97/04/04 14:49:11 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the year object

CALLED BY:	(MSG_YEAR_INIT)

PASS:		ES	= DGroup
		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data
		BP	= Year
		DX	= Month/Day

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		This call takes a long time to complete!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/5/89		Initial version
	Don	10/11/90	Added AWLAYS_TODAY code

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearInit	method	YearClass, MSG_YEAR_INIT
	
	; Always grab the trarget exclusive
	;
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjCallInstanceNoLock

	; Mark object as dirty, and check to see if we need to init stuff
	;
	mov	ax, si				; chunk handle => AX
	mov	bx, mask OCF_DIRTY		; bits to set in BL,reset in BH
	call	ObjSetFlags			; change the flags
	mov	di, ds:[si]
	add	di, ds:[di].Year_offset
	test	ds:[di].YI_flags, YI_NEEDS_INIT	; need to be initialized
	jnz	resetSelect			; yes, so do the work
	test	es:[showFlags], mask SF_SHOW_TODAY_ON_RELAUNCH
	jnz	resetSelect			; select & display today if...
						; Preference option is set

	; Call for loading the events for the day(s) already selected
	;
	or	ds:[di].YI_flags, (YI_SEL_REGION or YI_MANUAL_CHANGE)
	call	YearNameDisplay
	call	MonthNameDisplay
	and	ds:[di].YI_flags, not (YI_MANUAL_CHANGE)
	mov	ax, MSG_YEAR_COMPLETE_SELECTION
	GOTO	ObjCallInstanceNoLock		; bring up the range of events

	; Set the selected region
	;
resetSelect:
	mov	ax, MSG_YEAR_VIEW_TODAY
	GOTO	ObjCallInstanceNoLock		; send the method
YearInit	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearClassSpecBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Visually build a YearClass

CALLED BY:	UI (MSG_SPEC_BUILD)

PASS:		AX	= MSG_SPEC_BUILD
		DS:*SI	= Instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearClassSpecBuild	method	YearClass, MSG_SPEC_BUILD

	; Call superclass to perform a normal Vis Build
	;
	mov	di, offset YearClass
	call	ObjCallSuperNoLock		; call my superclass

	; Now set up our state
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Vis_offset		; access visual data
	or	ds:[di].VCI_geoAttrs, mask VCGA_CUSTOM_MANAGE_CHILDREN

	; Since this thing's size depends on things (the subview dimensions) 
	; other than what it's passed by the geometry manager, it 
	; needs to always have its geometry done, regardless of its 
	; invalid flags.
	;
	or	ds:[di].VI_geoAttrs, mask VGA_ALWAYS_RECALC_SIZE

	; Ensure the color scheme is set up, and attempt to initialize stuff
	;
	call	CalendarColorScheme		; set the color scheme

	; If we are running on a TV, switch to the system font (likely
	; FID_BERKELEY) to increase readablity.
	;
	and	al, mask DT_DISP_ASPECT_RATIO
	cmp	al, DAR_TV shl offset DT_DISP_ASPECT_RATIO
	jne	done
	mov	ax, MSG_MONTH_SET_FONT
	mov	cx, dx
	call	GenSendToChildren
done:
	ret
YearClassSpecBuild	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearViewToday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Force today's events to come up.

CALLED BY:	GLOBAL (MSG_YEAR_VIEW_TODAY)
	
PASS:		DS:DI	= YearClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/11/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearViewToday	method	YearClass,	MSG_YEAR_VIEW_TODAY

	; Set the selected region
	;
	call	TimerGetDateAndTime		; get the date information
	xchg	bh, bl				; put month in high byte
	mov	ds:[di].YI_startYear, ax
	mov	{word} ds:[di].YI_startDay, bx
	mov	ds:[di].YI_endYear, ax
	mov	{word} ds:[di].YI_endDay, bx
	mov	ds:[di].YI_curYear, ax		; first year is current
	mov	ds:[di].YI_curMonth, bh		; first month is current

	; Set the correct year & months
	;
	or	ds:[di].YI_flags, YI_MANUAL_CHANGE or YI_IMAGE_INVALID
	clr	ch
	xchg	ch, ds:[di].YI_curMonth		; set to zero to force redraw
	clr	dx
	xchg	dx, ds:[di].YI_curYear		; set to zero to force redraw
	mov	ax, MSG_YEAR_SET_MONTH_AND_YEAR	; set the current display
	call	ObjCallInstanceNoLock		; send the method
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; access instance data

	; Now call for loading the events
	;
	and	ds:[di].YI_flags, not (YI_MANUAL_CHANGE or YI_NEEDS_INIT)
	or	ds:[di].YI_flags, YI_SEL_REGION	; set this flag
	mov	ax, MSG_YEAR_COMPLETE_SELECTION
	GOTO	ObjCallInstanceNoLock		; bring up the range of events
YearViewToday 	endp

InitCode	ends



GeometryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Calculate the proper size of the year object

CALLED BY:	UI - (MSG_VIS_RECALC_SIZE)

PASS:		CX	= Width hint
		DX	= Height hint
		DS:*SI	= Instance data
		ES	= DGroup

RETURN:		CX	= Desired width
		DX	= Desired height

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/7/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
	
YearRecalcSize	method	YearClass, MSG_VIS_RECALC_SIZE
		
	; First obtain and store the view's dimmensions
	;
	mov	ax, MSG_VIS_CONTENT_GET_WIN_SIZE	; get size of view
	call	VisCallParent			;    
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; access instance data
	mov	ds:[di].YI_viewWidth, cx	; Width in CX
	mov	ds:[di].YI_viewHeight, dx	; Height in DX
		
	; Work on the One Month Size
	;
	mov	ax, cx				; width => AX
	call	YearCheckWidthMinMax
	mov	ds:[di].YI_maxMonthWidth, bx	; store the width
	mov	ax, dx				; height => AX
	call	YearCheckHeightMinMax
	mov	ds:[di].YI_maxMonthHeight, bx	; store the height
	
	; Work on the Small (twelve) Month Size
	;
	mov	ax, cx				; width => AX
	shr	ax, 1
	shr	ax, 1
	call	YearCheckWidthMinMax
	mov	ds:[di].YI_minMonthWidth, bx
	mov	ax, dx				; height => DX
	clr	dx
	mov	bx, 3
	div	bx
	call	YearCheckHeightMinMax
	mov	ds:[di].YI_minMonthHeight, bx

	; Now re-size the months
	;
	test	ds:[di].YI_flags, YI_ONE_MONTH_SIZE
	jne	oneMonth
	mov	ax, ds:[di].YI_minMonthWidth
	mov	bx, ds:[di].YI_minMonthHeight	
	jmp	doResize
oneMonth:
	mov	ax, ds:[di].YI_maxMonthWidth
	mov	bx, ds:[di].YI_maxMonthHeight	
	
	; Store the approriate month size, and return total width/height
doResize:
	mov	ds:[di].YI_monthWidth, ax	; store the month width
	mov	ds:[di].YI_monthHeight, bx	; store the month height
	shl	ax, 1				; 2 * width => AX
	shl	ax, 1				; 4 * width => AX
	mov	cx, ax				; 4 * width => CX
	mov	dx, bx				; total height => DX
	test	ds:[di].YI_flags, YI_ONE_MONTH_SIZE
	jz	yearLayout			; jump if not one month layout

	; Year width = 12 * month width; year height = 1 * month height
	;
	shl	ax, 1				; 8 * width => AX
	add	cx, ax				; total width => CX
	ret

	; Year width = 4 * month width; year height = 3 * month height
	;
yearLayout:
	shl	bx, 1				; 2 * height => BX
	add	dx, bx				; total height => DX
	ret
YearRecalcSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearCheckWidthMinMax, YearCheckHeightMinMax
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check the for width or height in the proper range

CALLED BY:	GLOBAL
	
PASS:		AX	= New width/height

RETURN:		BX	= Width/Height in range

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NPZ <MIN_CHAR_POINT_SIZE = 9					>
PZ <MIN_CHAR_POINT_SIZE	= 12	;not really, but it works	>

MIN_DATE_WIDTH		= 20
MIN_MONTH_WIDTH		= (2 * MONTH_BORDER_HORIZ) + (7 * MIN_DATE_WIDTH) + 1
MIN_DATE_HEIGHT		= (MIN_CHAR_POINT_SIZE + 5)
MIN_MONTH_HEIGHT	= (2 * MONTH_BORDER_TOP) + (8 * MIN_DATE_HEIGHT) + 3
			
; the graphics system can only support a size of 4000h, so max month
; dimension = 4000h / 12 = 1365.33
;
MAX_MONTH_WIDTH		= 1350
MAX_MONTH_HEIGHT 	= 1350

YearCheckWidthMinMax	proc	near

	mov	bx, MIN_MONTH_WIDTH
	cmp	bx, ax
	jg	done
	mov	bx, MAX_MONTH_WIDTH
	cmp	bx, ax
	jl	done
	mov	bx, ax
done:
	ret
YearCheckWidthMinMax	endp

YearCheckHeightMinMax	proc	near

	mov	bx, MIN_MONTH_HEIGHT
	cmp	bx, ax
	jg	done
	mov	bx, MAX_MONTH_HEIGHT
	cmp	bx, ax
	jl	done
	mov	bx, ax
done:
	ret
YearCheckHeightMinMax	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPosition
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Called to position the year's children, and possibly scrolls
		the document to present the correct month.

CALLED BY:	UI (MSG_VIS_POSITION_BRANCH)

PASS:		DS:*SI	= Year instance data
		ES	= DGroup
		
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
       		Assumes that MSG_GEN_VIEW_SET_DOC_BOUNDS is sent between the
		RecalcSize and the Position of the content object, so that
		the size of the view is correct when it receives any
		positioning.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	1/21/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearPosition	method	YearClass,	MSG_VIS_POSITION_BRANCH
	
	; Now the real work
	;
	call	StartMonthsBoundsCalc		; move the months
	call	PositionYearDocument		; re-position the document
	ret
YearPosition	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StartMonthsBoundsCalc
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Begin the month bounds calculation

CALLED BY:	YearRecalcSize

PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		Set up the callback routine to process children

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/8/89		Initial version
	Don	5/12/90		Added formal month size invalidation

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StartMonthsBoundsCalc	proc	near
	class	YearClass			; friend to this class

	; Set up the increment values for the scrollbar
	;
	push	si
	sub	sp, size PointDWord
	mov	bp, sp
	mov	cx, ds:[di].YI_monthWidth	; horiz increment amount
	mov	dx, ds:[di].YI_monthHeight	; vertical increment amount
	shr	dx				; divide by two
	mov	ss:[bp].PD_x.low, cx
	mov	ss:[bp].PD_y.low, dx
	clr	dx
	mov	ss:[bp].PD_x.high, dx
	mov	ss:[bp].PD_y.high, dx
	mov	si, offset Interface:YearView	; DS:*SI points at the view
	mov	ax, MSG_GEN_VIEW_SET_INCREMENT
	call	ObjCallInstanceNoLock
	add	sp, size PointDWord
	pop	si
	
	; Get the bounds information
	;
	call	VisGetBounds			; get my boundaries
	mov	dx, bx				; top bounds into DX
	mov	cx, ax				; left bounds into CX
	clr	al				; clear the count byte
	mov	bp, Month12			; last object

	; Start the callback routine
	;
	clr	bx
	push	bx				; start with the first object
	push	bx				; in the composite
	mov	bx, offset VI_link
	push	bx				; push offset to the LinkPart
	push	cs				; segment of callback routine
	mov	bx, offset GeometryCode:YearSetMonthsBounds
	push	bx				; offset of callback routine
	mov	bx, offset Vis_offset		; offset to master part offset
	mov	di, offset VCI_comp		; offset to CompPart
	call	ObjCompProcessChildren		; process my children

	; Ensure all the font sizes are correct
	;
	CallMod	SetAllMonths			; set all the months
	ret
StartMonthsBoundsCalc	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearSetMonthsBounds
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Callback routine to determine the month objects' boundaries

CALLED BY:	StartMonthsBoundsCalc()

PASS:		DS:*SI	= Month instance data
		ES:*DI	= Year instance data
		AL	= Position counter (varies between 0 & 3 or 0 & 11)
		CX	= Left boundary for this month
		DX	= Top boundary for this month
		BP	= Last object to process
		
RETURN:		Carry Set if done!!

DESTROYED:	BX, SI, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/8/89		Initial version
	Don	5/12/90		Removed nasty month-invalid hack

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearSetMonthsBounds	proc	far

	; Perform some set-up work
	;
	push	si				; save month handle
	push	ax, cx				; save the counter value, pos
	mov	ax, MSG_MONTH_SET_STATE	; invalidate the month
	clr	cl				; clear no flags
	mov	ch, MI_NEW_SIZE			; set this flag
	call	ObjCallInstanceNoLock		; send the method
	segmov	es, ds, ax			; restore the seg register
	pop	ax, cx				; restore counter value, pos
	mov	di, es:[di]			; dereference year handle
	mov	bx, di				; move deref'd handle (year)
	add	di, es:[di].Year_offset		; access my instance data
	mov	si, ds:[si]			; dereference month handle
	add	si, ds:[si].Vis_offset		; access the visual bounds

	; Set the month's boundaries
	;
	push	cx, dx				; save the upper-left corner
	mov	ds:[si].VI_bounds.R_left, cx	; save left bounds
	mov	ds:[si].VI_bounds.R_top, dx	; save top bounds
	add	cx, es:[di].YI_monthWidth	; calculate month width
	add	dx, es:[di].YI_monthHeight	; calculate month height
	dec	cx
	dec	dx
	mov	ds:[si].VI_bounds.R_right, cx	; save right bounds
	mov	ds:[si].VI_bounds.R_bottom, dx	; save bottom bounds
	pop	cx, dx				; restore the upper-left corner

	; Prepare for the next call
	;
	inc	al				; increment counter
	add	cx, es:[di].YI_monthWidth	; get next month
	mov	ah, 12				; assume month view
	test	ds:[di].YI_flags, YI_ONE_MONTH_SIZE	
	jnz	checkRightEdge
	mov	ah, 4
checkRightEdge:
	cmp	al, ah				; month too far over ??
	jl	done
	clr	al				; reset counter	
	add	dx, es:[di].YI_monthHeight	; go down
	add	bx, es:[bx].Vis_offset		; access instance data
	mov	cx, es:[bx].VI_bounds.R_left	; start at left boundary again
done:
	pop	si				; restore the month handle
	cmp	si, bp				; compare stop with current
	cmc					; invert the carry
	ret
YearSetMonthsBounds	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearSetMonthSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the size of the months 

CALLED BY:	GLOBAL (MSG_YEAR_SET_MONTH_SIZE)

PASS:		*DS:SI	= YearClass object
		DS:DI	= YearClassInstance
		CX	= YearInfoFlags
				YI_ONE_MONTH_SIZE
				YI_SMALL_MONTH_SIZE

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/11/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearSetMonthSize	method dynamic	YearClass, MSG_YEAR_SET_MONTH_SIZE
	.enter

	; Some set-up work
	;
	test	ds:[di].YI_flags, cx
	jnz	exit				; if already set, do nothing
	and	ds:[di].YI_flags, not (YI_SMALL_MONTH_SIZE or YI_ONE_MONTH_SIZE)
	or	ds:[di].YI_flags, cx		; set the new size flag

	; Assume "one-month" size values, else use "small-month" values
	;
	mov	ax, ds:[di].YI_maxMonthWidth
	mov	bx, ds:[di].YI_maxMonthHeight
	mov	dx, MPOT_GR_MONTH		; default print action
	mov	bp, (LG_TITLE_FONT_SIZE shl 8) or LG_DATE_FONT_SIZE
	cmp	cx, YI_ONE_MONTH_SIZE
	je	common
	mov	ax, ds:[di].YI_minMonthWidth
	mov	bx, ds:[di].YI_minMonthHeight
	inc	dx				; MPOT_GR_YEAR => DX
	mov	bp, (SM_TITLE_FONT_SIZE shl 8) or SM_DATE_FONT_SIZE

	; Store the new month dimensions
common:
	mov	ds:[di].YI_monthWidth, ax	; store the month width
	mov	ds:[di].YI_monthHeight, bx	; store the month height
	mov	{word} ds:[di].YI_smallFontSize, bp	; store the font sizes

	; Change three things depending on what mode we're in:
	; 1) Make the scrollbars on the YearView appear or not
	; 2) Display the MonthValueObject or not
	; 3) Display the YearValue moniker or not
	;
	push	si
	mov	ax, MSG_GEN_SET_USABLE
	mov	dx, mask GVDA_DONT_DISPLAY_SCROLLBAR
	mov	bp, offset YearValueMonikerFake
	cmp	cx, YI_ONE_MONTH_SIZE
	je	setScrollbarState
	mov	ax, MSG_GEN_SET_NOT_USABLE
	xchg	dl, dh
	mov	bp, offset YearValueMonikerReal
setScrollbarState:
	push	ax				; save message
	push	bp				; save moniker

	; Accomplish #1

	mov	ax, MSG_GEN_VIEW_SET_DIMENSION_ATTRS
	mov	cx, dx
	mov	bp, VUM_DELAYED_VIA_UI_QUEUE
	GetResourceHandleNS	Interface, bx
	mov	si, offset Interface:YearView
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage_geometry_call

	; Accomplish #2

	mov	ax, MSG_GEN_USE_VIS_MONIKER
	pop	cx
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	mov	si, offset Interface:YearValue		
	call	ObjMessage_geometry_call
		
	; Accomplish #3

	pop	ax
	mov	si, offset Interface:MonthValueObject
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjMessage_geometry_call
	pop	si

	; Ensure the document size is set correctly
	;
	mov	cl, mask VOF_GEOMETRY_INVALID	; mark our geometry invalid
	mov	dl, VUM_NOW			; do it now, please
	call	VisMarkInvalid
	call	PositionYearDocument		; and move the document origin
	mov	di, ds:[si]
	add	di, ds:[di].Year_offset
	call	MonthNameDisplay		; ensure month name is correct
exit:
	.leave
	ret
YearSetMonthSize	endm

GeometryCode	ends



CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearGainedTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that we've gained the target

CALLED BY:	GLOBAL (MSG_META_GAINED_TARGET_EXCL)

PASS:		ES	= DGroup
		*DS:SI	= YearClass object
		DS:DI	= YearClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearGainedTargetExcl	method dynamic	YearClass, MSG_META_GAINED_TARGET_EXCL

		; First call our superclass
		;
		mov	di, offset YearClass
		call	ObjCallSuperNoLock

		; Record the fact that we are now selected, and cause
		; the months' titles to be re-drawn to reflect this fact.
		;
		mov	cx, MI_HAS_FOCUS shl 8	; set this flag
		call	InvalidateMonthTitles

if	not _TODO
		; Tell the DayPlan to remove the selected object
		;
		mov	ax, MSG_DP_SET_SELECT
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		clr	bp
		call	ObjMessage_common_send

		; Now set the ViewType
		;
		mov	cx, VT_CALENDAR
		GOTO	UpdateViewType
else
		ret
endif
YearGainedTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearLostTargetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Note that we've lost the target

CALLED BY:	GLOBAL (MSG_META_LOST_TARGET_EXCL)

PASS:		ES	= DGroup
		*DS:SI	= YearClass object
		DS:DI	= YearClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/10/93		Initial version
		Don	6/13/95		Changed to TARGET, to avoid screen
					flashing when bringing down menus

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearLostTargetExcl	method dynamic	YearClass, MSG_META_LOST_TARGET_EXCL

		; Re-draw the titles in the month objects
		;
		mov	cx, MI_HAS_FOCUS	; clear this flag
		call	InvalidateMonthTitles

		; Now call our superclass
		;
		mov	di, offset YearClass
		GOTO	ObjCallSuperNoLock
YearLostTargetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalidateMonthTitles
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate the title of every month object that is
		a child of the Year object

CALLED BY:	YearGainedFocusExcl, YearLostFocusExcl

PASS:		*DS:SI	= Year object
		CL	= MonthInfoFlags to clear (MI_HAS_FOCUS)
		CH	= MonthInfoFlags to set   (MI_HAS_FOCUS)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	12/21/93	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InvalidateMonthTitles	proc	near
		.enter
	
		; Tell the month objects about their new state
		;
		mov	ax, MSG_MONTH_SET_STATE
		call	VisSendToChildren

		; If the window exists, tell each month object to
		; invalidate its title. Else, do nothing
		;
		call	GetYearViewOrigin
		call	VisQueryWindow		; origin => (CX, DX)
		tst	di
		jz	done
		mov	ax, MSG_MONTH_INVALIDATE_TITLE
		mov	bp, di			; Window handle => BP
		call	VisSendToChildren
done:
		.leave
		ret
InvalidateMonthTitles	endp

CommonCode	ends



YearCode	segment resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearTrackScrolling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Normalize the scrolling of the year object. Only normalize
		when in OneMonth mode.

CALLED BY:	UI (MSG_META_CONTENT_TRACK_SCROLLING)
	
PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data
		ES	= DGroup
		SS:BP	= TrackScrollingParams
		CX	= Scrollbar handle

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/21/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearTrackScrolling	method	YearClass, MSG_META_CONTENT_TRACK_SCROLLING
	.enter

	; If we haven't been initialized or are in the 12-month mode, do
	; not change the scroll. If we are in the middle of a document
	; size change, then determine the new origin rather than
	; "normalizing" the scroll
	;
	call	GenSetupTrackingArgs		; set up some extra values
	mov	di, ds:[si]
	add	di, ds:[di].Year_offset		; YearInstance => DS:DI
	test	ds:[di].YI_flags, YI_SMALL_MONTH_SIZE or YI_NEEDS_INIT
	jnz	done				; if no work, we're done
	test	ss:[bp].TSP_flags, mask SF_DOC_SIZE_CHANGE
	jnz	calcOrigin			; calculate the new origin

	; Normalize the scroll
	;
	mov	ax, ss:[bp].TSP_newOrigin.PD_x.low	; get the next X origin
	clr	dx				; dividend => DX:AX
	mov	bx, ds:[di].YI_monthWidth	; divisor => BX
	tst	bx				; normalize before visible ??
	jz	done				; if so, don't change anything
	div	bx				; perform the division
	inc	al
	shr	bx, 1				; divide divisor by 2
	cmp	dx, bx				; check the remainder
	jl	rounded				; round down!
	sub	dx, ds:[di].YI_monthWidth	; else negative difference=>DX
	inc	al				; go to the next month
rounded:
EC <	cmp	al, 1				; must at least by Jan	>
EC <	ERROR_L	YEAR_ILLEGAL_CURRENT_MONTH				>
EC <	cmp	al, 12				; must be less than Dec	>
EC <	ERROR_G	YEAR_ILLEGAL_CURRENT_MONTH				>

	; We now know what month to display, and the difference (if any)
	; between the offset the user requested, and the one we're going to
	; give him/her. Store our changes, and we're done
	;
	mov	ds:[di].YI_curMonth, al		; store the new current month!
	mov_tr	ax, dx
	cwd
	subdw	ss:[bp].TSP_change.PD_x, dxax
	subdw	ss:[bp].TSP_newOrigin.PD_x, dxax
done:
	call	GenReturnTrackingArgs		; return arguments

	.leave
	ret

	; Calculate the new origin
calcOrigin:
	mov	ax, ds:[di].YI_monthWidth
	mov	dl, ds:[di].YI_curMonth
	clr	dl
	dec	dx				; make it zero-based
	mul	dx				; origin.x => AX
	mov	ss:[bp].TSP_newOrigin.PD_x.low, ax
	clr	ss:[bp].TSP_newOrigin.PD_y.low
	or	ss:[bp].TSP_flags, mask SF_ABSOLUTE
	jmp	done
YearTrackScrolling	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the year object, then draw the month children

CALLED BY:	GLOBAL

PASS:		CL	= DrawFlags
		BP	= GState to use
		DS:*SI	= Instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/6/89		Initial version
	Chris	7/ 3/91		Fixed to not assume MSG_VIS_DRAW preserves bp

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearDraw	method	YearClass, MSG_VIS_DRAW
	.enter

	; Set up the Gstate first
	;
	test	ds:[di].YI_flags, YI_NEEDS_INIT	; need to be initialized ??
	jnz	quit				; if so, do nothing.	
	mov	di, bp				; GState to DI	
	call	GrSaveState			; save the GState' state
	push	cx, cx				; save the DrawFlag, twice

	; Set the appropriate colors. Text and the line colors are always
	; black, and the background color is read from a variable.
	;
	movdw	bxax, es:[monthBGColor]
	call	GrSetAreaColor			; set the background color
	mov	ax, CF_INDEX shl 8 or TEXT_COLOR
	call	GrSetLineColor
	call	GrSetTextColor			; set the foreground colors

	; Simply call my superclass to draw the months
	;
	mov	di, bp				; move GState to DI
	call	VisGetBounds			; get my bounds
	call	GrFillRect			; clear the window first
	pop	cx				; DrawFlag => CL
	push	bp				; preserve bp
	mov	ax, MSG_VIS_DRAW		; method to pass
	mov	di, offset YearClass
	call	ObjCallSuperNoLock		; call my SuperClass
	pop	bp				; restore bp

if PZ_PCGEOS ; Pizza
	; DESTROYED:	cx, di, ax
	; Check holiday setting mode
	;
	push	bx, dx, bp, si
	mov	ax, MSG_JC_SHIC_GET_USABLE
	GetResourceHandleNS	SetHoliday, bx
	mov	si, offset SetHoliday
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	bx, dx, bp, si
	jnc	nextJob				; if not usable
	pop	cx				; DrawFlag => CL
	jmp	done
nextJob:
endif
	
	; Do we need to hi-light an area ??
	;
	pop	cx				; DrawFlag => CL
	test	cl, mask DF_PRINT		; if we're printing...
	jnz	done				; then skip all this crap
	mov	di, ds:[si]			; dereference this handle
	add	di, ds:[di].Year_offset		; access instance data
	test	ds:[di].YI_flags, YI_SEL_REGION	; selected region ??
	jz	done				; no, so do nothing
	clr	ax				; assume in bounds
	test	ds:[di].YI_flags, YI_OUT_OF_BOUNDS
	jz	drawSelection			; yes - in bounds
	mov	ax, 1				; else use the old bounds
drawSelection:
	call	YearDrawSelection		; draw using current dates

	; Clean up
	;
done:
	mov	di, bp				; GState handle => DI
	call	GrRestoreState			; restore the GState' state
quit:
	.leave
	ret
YearDraw	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearDrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw any selection that appears in this year

CALLED BY:	GLOBAL

PASS:		DS:*SI	= YearClass instance data
		BP	= GState or nothing
		AX	= 0 for the current range
		AX	= 1 for the old range

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/1/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearDrawSelection	proc	near
	class	YearClass			; friend to this class

	; Some set-up work
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; access instance data
	tst	ax				; old or new
	jne	old

	; Get the current range
	;
	mov	ax, ds:[di].YI_startYear
	mov	bx, ds:[di].YI_endYear
	mov	cx, {word} ds:[di].YI_startDay
	mov	dx, {word} ds:[di].YI_endDay
	jmp	common

	; Get the old range
old:
	mov	ax, ds:[di].YI_oldStartYear
	mov	bx, ds:[di].YI_oldEndYear
	mov	cx, {word} ds:[di].YI_oldStartDay
	mov	dx, {word} ds:[di].YI_oldEndDay

	; Get the start boundary
common:
	cmp	ax, ds:[di].YI_curYear		; start year with current
	jg	done				; if greater, done!
	je	last				; if equal, check last date
	mov	cx, (1 shl 8) or 1		; January 1st
last:
	cmp	bx, ds:[di].YI_curYear		; last year with current
	jl	done				; if less than current, done
	je	draw				; if equal, draw now
	mov	dx, (12 shl 8) or 31		; else use the last date
draw:
	call	DrawSelection			; draw selection in CX:DX
done:
	ret
YearDrawSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearChangeMonthMap
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	A change removing or adding days with events has occurred.
		Call for the update of the appropriate months.

CALLED BY:	DBNotifyMonthChange (MSG_YEAR_CHANGE_MONTH_MAP)
	
PASS:		DS:DI	= YearClass specific instance data
		BP	= Year (or 0 for every month)
		DH	= Month

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/1/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearChangeMonthMap	method	YearClass,	MSG_YEAR_CHANGE_MONTH_MAP
	.enter

	; Do we need to do anything
	;
	clr	dl				; assume all months
	tst	bp				; any month ??
	jz	startWork			; yes, setup for loop
	cmp	bp, ds:[di].YI_curYear		; change to current year ??
	jne	done				; no, so do nothing
	mov	dl, dh				; changed month => DL

	; Perform some set-up work
	;
startWork:
	mov	bp, ds:[di].YI_curYear		; current year => BP
	call	GeodeGetProcessHandle		; process handle => BX
	mov	cx, offset Month1		; first month handle => CX
	mov	dh, 1				; start with the first month

	; Loop here until done
methodLoop:
	tst	dl				; work with any month
	je	doCall				; yes
	cmp	dl, dh				; else comapre the months
	jne	next
doCall:
	mov	ax, MSG_DB_GET_MONTH_MAP
	clr	di
	call	ObjMessage
next:
	inc	dh				; go to the next month
	add	cx, 2				; go to the next chunk
	cmp	dh, 12				; compare with last month
	jle	methodLoop			; continue until done
done:
	.leave
	ret
YearChangeMonthMap	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearChangeYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the year that is displayed

CALLED BY:	UI (MSG_YEAR_CHANGE_YEAR)

PASS:		DS:DI	= YearClass specific instance data
		DS:*SI	= YearClass instance data
		DX	= Year

RETURN:		Nothing

DESTROYED:	DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearChangeYear	method dynamic YearClass,	MSG_YEAR_CHANGE_YEAR
	mov	ds:[di].YI_changeYear, dx	; set the change year
	mov	bx, ds:[LMBH_handle]		; BX:SI points to me
	mov	di, mask MF_FORCE_QUEUE or mask MF_CHECK_DUPLICATE
	mov	ax, MSG_YEAR_CHANGE_NOW
	GOTO	ObjMessage
YearChangeYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearChangeNow
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Change the year and month displayed now (if necessary)

CALLED BY:	Internal (MSG_YEAR_CHANGE_NOW)

PASS:		DS:DI	= YearClass specific instance data
		DS:*SI	= YearClass instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/27/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearChangeNow	method dynamic YearClass,	MSG_YEAR_CHANGE_NOW
	.enter

	mov	ch, ds:[di].YI_changeMonth
	mov	dx, ds:[di].YI_changeYear
	tst	ch
	jnz	alter
	tst	dx
	jz	done

	; Something has changed - reset the months
alter:
	clr	ax
	mov	ds:[di].YI_changeMonth, al	; clear the change value
	mov	ds:[di].YI_changeYear, ax	; clear the change value
	call	YearSetMonthAndYear
done:
	.leave
	ret
YearChangeNow	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearSetMonthAndYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the given month & year as the displayed month

CALLED BY:	[Decrement,Increment][Month,Year], MSG_YEAR_SET_MONTH_AND_YEAR

PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data
		CH	= Month (or 0 to do nothing)
		DX	= Year (or 0 to do nothing)

RETURN:		Nothing

DESTROYED:	BX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Set the new month and year
		Update display as needed

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/28/89		Initial version
	Don	12/27/89	Modified to allow RangeGadget
	kho	8/26/96		Handle CLAIM_UNUSED_MONTH_SPACE.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearSetMonthAndYear	method	YearClass,	MSG_YEAR_SET_MONTH_AND_YEAR
	uses	ax, cx, dx, si
	.enter

	; Check the month & the year
	;
	tst	ch				; do nothing with month ??
	jz	checkYear			; if zero, check the year
	cmp	ch, ds:[di].YI_curMonth		; compare the months
	je	checkYear
	ornf	ds:[di].YI_flags, YI_MANUAL_CHANGE
	mov	ds:[di].YI_curMonth, ch		; save the new month
	call	MonthNameDisplay		; display the month text
checkYear:
	tst	dx
	je	update
	cmp	dx, ds:[di].YI_curYear		; compare the years
	je	update
	mov	ds:[di].YI_curYear, dx		; save the new year
	or	ds:[di].YI_flags, YI_IMAGE_INVALID
	call	YearNameDisplay			; display the year text
	call	SetAllMonths			; set all the months
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; access my instance data
	and	ds:[di].YI_flags, not (YI_NEEDS_INIT)

	; Reset the months (if necessary)
	;
update:	
	test	ds:[di].YI_flags, YI_MANUAL_CHANGE ; if not a manual change
	jz	checkInvalid			; ...don't mess with doc pos
	call	PositionYearDocument		; position it correctly
	pushf					; save the flags
	mov	di, ds:[si]			; dereference my handle
	add	di, ds:[di].Year_offset		; acess my instance data
	popf
	jnc	checkInvalid			; jump if not re-positioned
	or	ds:[di].YI_flags, YI_IMAGE_INVALID

	; Check the invalid stuff
	;
checkInvalid:
	test	ds:[di].YI_flags, YI_IMAGE_INVALID
	jz	done
if CLAIM_UNUSED_MONTH_SPACE

	; Resize the YearView according to the current month.
	;
	call	ResetYearViewSize
endif
	and	ds:[di].YI_flags, not (YI_IMAGE_INVALID or YI_MANUAL_CHANGE)
	mov	cl, mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	mov	ax, MSG_VIS_MARK_INVALID	; invalidate method
	call	ObjCallInstanceNoLock		; send it to myself
done:
	.leave
	ret
YearSetMonthAndYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearGetMonthAndYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the month & year that are currently displayed

CALLED BY:	MSG_YEAR_GET_MONTH_AND_YEAR

PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data

RETURN:		CH	= Month
		DX	= Year

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/29/00		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearGetMonthAndYear	method	dynamic	YearClass,
					MSG_YEAR_GET_MONTH_AND_YEAR
	.enter

	; Just retrieve the requested information
	;
	mov	ch, ds:[di].YI_curMonth
	mov	dx, ds:[di].YI_curYear

	.leave
	ret
YearGetMonthAndYear	endp
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetYearViewWidth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the width of YearView object according to the current
		month.

CALLED BY:	(INTERNAL) YearSetMonthAndYear
PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kho	8/26/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
if CLAIM_UNUSED_MONTH_SPACE
ResetYearViewSize	proc	near
		class	YearClass
		uses	ax, bx, cx, dx, si, di, bp
		.enter
		Assert	objectPtr, dssi, YearClass
	;
	; Find the active month object.
	;
		mov	si, Month1			; first handle => SI
		mov	al, ds:[di].YI_curMonth
		clr	ah
		dec	al				; change to zero-based
		shl	ax				; double to make a
							; handle
		add	si, ax				; starting handle => SI
	;
	; Get the MonthInfoFlags of the month object.
	;
		mov	ax, MSG_MONTH_GET_STATE
		call	ObjCallInstanceNoLock		; cl <- MonthInfoFlags
	;
	; Set the size of YeaarView object, depending on the info flag.
	;
		mov	ax, SpecWidth <SST_PIXELS,VIEW_WIDTH_INITIAL>
		test	cl, MI_SPAN_6_WEEKS
		jz	smallView
		mov	ax, SpecWidth <SST_PIXELS,VIEW_6_WEEKS_WIDTH>
smallView:
	;
	; Set up SetSizeArgs.
	;
		sub	sp, size SetSizeArgs
		mov	bp, sp				; ss:bp = SetSizeArgs
		mov	ss:[bp].SSA_width, ax
		mov	ss:[bp].SSA_height, SpecHeight <>
		clr	ss:[bp].SSA_count
		mov	ss:[bp].SSA_updateMode, VUM_NOW
	;
	; Call YearView.
	;
		GetResourceHandleNS	YearView, bx
		mov	si, offset YearView
		mov	ax, MSG_GEN_SET_FIXED_SIZE
		mov	dx, size SetSizeArgs
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage			; ax, cx, dx, bp gone
		add	sp, size SetSizeArgs
	;
	; Reset the size of CalendarRight.
	;
		mov	ax, MSG_VIS_MARK_INVALID
		GetResourceHandleNS	CalendarSizeControl, bx
		mov	si, offset CalendarSizeControl
		mov	cl, mask VOF_GEOMETRY_INVALID
		mov	dl, VUM_MANUAL
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		
		.leave
		ret
ResetYearViewSize	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SetAllMonths
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the month objects to their appropriate month & year

CALLED BY:	YearSetMonthAndYear

PASS:		DS:*SI	Year instance data

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/11/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SetAllMonths	proc	far
	class	YearClass			; friend to this class
	uses	si
	.enter

	; Access the instance data to determine current month and year
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; access instance data
	mov	bp, ds:[di].YI_curYear		; get current year
	mov	cx, {word} ds:[di].YI_smallFontSize ; large => CH, small => CL
	mov	dh, 1				; January as the start month
	mov	bl, 12				; count up to twelve
	mov	si, offset Month1		; handle of the first month

	; Now loop through the months
resetLoop:
	mov	ax, MSG_MONTH_SET_MONTH	; method to send
	call	ObjCallInstanceNoLock		; send the method
	add	si, 2				; next month object
	inc	dh				; increment month
	dec	bl
	jg	resetLoop

	.leave
	ret
SetAllMonths	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PositionYearDocument
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Position the year "document" such that the first selected
		month is visible.

CALLED BY:	GLOBAL

PASS:		DS:*SI	= Year instance data

RETURN:		Carry	= Set if the document was moved
			= Clear if not

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:
		The monthWidth & monthHeight must be correct!!!

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/12/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PositionYearDocument	proc	far
	class	YearClass
	uses	si
	.enter

	; Get the current document position
	;
	mov	di, si				; Year object => DI
	call	GetYearViewOrigin
	
	; Is our frame in the window's boundary?  If not, must re-position
	;
	mov	di, ds:[di]			; dereference the Year handle
	add	di, ds:[di].Year_offset		; access the instance data
	test	ds:[di].YI_flags, YI_NEEDS_INIT	; need to be initialized ??
	jnz	done				; if so, do nothing.	
	mov	bl, ds:[di].YI_curMonth		; get the current month
	dec	bl				; change to zero-based
	clr	bh
	shl	bx, 1				; from 0, count by two
	add	bx, Month1			; DS:*BX => MonthObject
	mov	bx, ds:[bx]			; dereference the month handle
	tst	ds:[bx].Vis_offset		; are we visually built yet ??
	jz	done				; if not vis-built, done
	add	bx, ds:[bx].Vis_offset		; access the visual data
	cmp	cx, ds:[bx].VI_bounds.R_left
	jg	reset
	cmp	dx, ds:[bx].VI_bounds.R_top
	jg	reset
	add	cx, ds:[di].YI_viewWidth
	add	dx, ds:[di].YI_viewHeight
	cmp	cx, ds:[bx].VI_bounds.R_right
	jl	reset
	cmp	dx, ds:[bx].VI_bounds.R_bottom
	jge	done	

	; Now set the document position
	;
reset:
	mov	cx, ds:[bx].VI_bounds.R_left	; new X offset
	mov	dx, ds:[bx].VI_bounds.R_top	; new Y offset
	sub	sp, size PointDWord
	mov	bp, sp
	mov	ss:[bp].PD_x.low, cx
	mov	ss:[bp].PD_y.low, dx
	clr	dx
	mov	ss:[bp].PD_x.high, dx
	mov	ss:[bp].PD_y.high, dx
	mov	si, offset Interface:YearView
	mov	ax, MSG_GEN_VIEW_SET_ORIGIN
	call	ObjCallInstanceNoLock
	add	sp, size PointDWord
	stc					; clear the carry bit
done:
	.leave
	ret
PositionYearDocument	endp

GetYearViewOrigin	proc	far
	uses	bx, si
	.enter

	sub	sp, size PointDWord
	mov	dx, sp
	mov	cx, ss				; pass buffer in cx:dx
	mov	si, offset Interface:YearView
	mov	ax, MSG_GEN_VIEW_GET_ORIGIN
	call	ObjCallInstanceNoLock
	mov	bp, dx
	mov	cx, ss:[bp].PD_x.low		; get origin in cx, dx
	mov	dx, ss:[bp].PD_y.low
	add	sp, size PointDWord

	.leave
	ret
GetYearViewOrigin	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearNameDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write out a string 

CALLED BY:	YearInit, YearSetMonthAndYear

PASS:		DS:*SI	= Month instance data
		DS:DI	= Dereference instance data

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		Display the new year string

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearNameDisplay	proc	far
	class	YearClass			; friend to this class
	.enter

	; Change the displayed year
	;
	push	si				; save the year handle
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cx, ds:[di].YI_curYear		; get the current jump year
	clr	bp				; a "determinate" value
	mov	si, offset Interface:YearValue
	call	ObjCallInstanceNoLock
	pop	si				; restore the year handle
	mov	di, ds:[si]			; dereference it
	add	di, ds:[di].Year_offset		; access the year data

	.leave
	ret
YearNameDisplay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MonthNameDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the month name to be displayed

CALLED BY:	YearInit, YearSetMonthAndYear

PASS:		DS:*SI	= Month instance data
		DS:DI	= Dereference instance data

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:
		Display the new month string

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/21/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MonthNameDisplay	proc	far
	class	YearClass			; friend to this class
	uses	ax, cx, dx, bp
	.enter

	; Change the displayed year
	;
	push	si				; save the year handle
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	mov	cl, ds:[di].YI_curMonth		; get the current month
	clr	ch
	clr	bp				; a "determinate" value
	mov	si, offset Interface:MonthValueObject
	call	ObjCallInstanceNoLock
	pop	si				; restore the year handle
	mov	di, ds:[si]			; dereference it
	add	di, ds:[di].Year_offset		; access the year data

	.leave
	ret
MonthNameDisplay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearCompleteSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send the selected range (dates) to the DayPlanObject

CALLED BY:	UI (MSG_YEAR_COMPLETE_SELECTION)

PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Check to see if a region is selected
			If not, put up GenSummons, quit
			If so, tell the DayPlan the range to open

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/22/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearCompleteSelection	method dynamic YearClass, MSG_YEAR_COMPLETE_SELECTION

	; Access instance data
	;
	test	ds:[di].YI_flags, YI_SEL_REGION	; is a region selected ??
	jnz	checkDates			; yes, so jump

	; Nothing selected - re-draw the old selection
	;
noRegion:
	call	OldRangeToCurrent		; move the old range to new
	clr	bp				; no GState
	clr	ax				; use the current range
	call	YearDrawSelection		; re-draw the selection
	ret

	; Load the days into registers
	;
checkDates:
	mov	ax, {word} ds:[di].YI_startDay
	mov	bx, ds:[di].YI_startYear	; AX = M/D, BX = Year (start)
	mov	dx, {word} ds:[di].YI_endDay
	mov	bp, ds:[di].YI_endYear		; DX = M/D, BP = Year (end)

	; Now fixup the dates - if necessary (check the start date)
	;
	tst	al				; first bad case
	jne	intFirst			; jump if OK
	mov	al, 1				; should be 1st of the month
	jmp	checkSecond
intFirst:
	cmp	al, 63				; second bad case
	jne	checkSecond			; jump if OK
	mov	al, 1				; reset to 1st day...
	inc	ah				; ...of the next month
	cmp	ah, 12				; check for overflow
	jle	checkSecond
	mov	ah, 1				; else month = January
	inc	bx				; and increment the year

	; Check the second date
	;
checkSecond:
	tst	dl				; first bad case
	jne	intSecond
	dec	dh				; back up one month
	jg	fixSecond
	mov	dh, 12
	dec	bp
	jmp	fixSecond
intSecond:
	cmp	dl, 63				; second bad case
	jne	new				; jump if OK
fixSecond:
	call	CalcDaysInMonth			; get days in the month
	mov	dl, ch				; last day to DL
	
	; Finally, check for the end of month 1 to begin of month 2 case
	;
new:
	mov	cx, dx				; last M/D to CX
	mov	dx, bp				; last Year to DX
	cmp	bx, dx				; compare the years
	jg	noRegion			; if greater, no region
	jl	go				; if less, OK
	cmp	ax, cx				; compare the month & day
	jg	noRegion			; if greater, no region

	; Selected - set up struct to pass to DuplicateDayPlan
	;
go:
	mov	{word} ds:[di].YI_startDay, ax
	mov	{word} ds:[di].YI_endDay, cx
	mov	ds:[di].YI_startYear, bx
	mov	ds:[di].YI_endYear, dx

if PZ_PCGEOS ; Pizza
	; DESTROYED:	ax, bx, si, di
	; Check holiday setting mode
	;
	push	cx, dx, bp
	mov	ax, MSG_JC_SHIC_GET_USABLE
	GetResourceHandleNS	SetHoliday, bx
	mov	si, offset SetHoliday
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	jnb	notHolidaySetting		; if not usable

	; Set holiday range
	;
	mov	ax, MSG_JC_SHIC_SET_RANGE
	GetResourceHandleNS	SetHoliday, bx
	mov	si, offset SetHoliday
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage
	pop	cx, dx, bp
	ret					; <-EXIT

notHolidaySetting:
	pop	cx, dx, bp
endif

	; Now make the call
	;
	mov	ax, MSG_DP_SET_RANGE
	GetResourceHandleNS	DayPlanObject, bx
	mov	si, offset DayPlanObject
	mov	di, mask MF_CHECK_DUPLICATE or \
		    mask MF_REPLACE or \
		    mask MF_FORCE_QUEUE
	GOTO	ObjMessage			; set the range to view
YearCompleteSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearSetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Used to set the dates to show as selected within the Year

CALLED BY:	DayPlanSetRange (MSG_YEAR_SET_SELECTION)

PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific intstance data
		SS:BP	= RangeStruct

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearSetSelection	method dynamic YearClass, MSG_YEAR_SET_SELECTION
	.enter

	; First unselect any selected area
	;
	test	ds:[di].YI_flags, YI_SEL_REGION	; a selected region ??
	jz	newZoom				; no, so jump
	push	bp				; save the RangeStruct
	clr	ax, bp				; current range no GState
	call	YearDrawSelection		; clear the selection
	pop	bp				; restore the RangeStruct

	; Load the year with the new selection range
newZoom:
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; go to instance data
	and	ds:[di].YI_flags, (not YI_SEL_REGION)
	call	CurrentRangeToOld		; update old range data
	mov	dx, ss:[bp].RS_endYear	
	mov	ds:[di].YI_endYear, dx		; ...and the end year
	mov	dx, {word} ss:[bp].RS_endDay
	mov	{word} ds:[di].YI_endDay, dx	; ...and the end M/D
	mov	dx, ss:[bp].RS_startYear	
	mov	ds:[di].YI_startYear, dx	; save the start year
	mov	cx, {word} ss:[bp].RS_startDay
	mov	{word} ds:[di].YI_startDay, cx	; ...and the start M/D

	; Show a new year (??) and draw the selection
	;
	push	bp
	or	ds:[di].YI_flags, YI_MANUAL_CHANGE
	call	YearSetMonthAndYear		; set the years
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; access instance data
	or	ds:[di].YI_flags, YI_SEL_REGION
	and	ds:[di].YI_flags, not YI_MANUAL_CHANGE
	clr	bp
	clr	ax				; use the new current range
	call	YearDrawSelection		; and draw it...
	pop	bp

	.leave
	ret
YearSetSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearGetSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Gets the selected days in the Year (Calendar View)

CALLED BY:	GLOBAL (MSG_YEAR_GET_SELECTION)

PASS:		*DS:SI	= YearClass object
		DS:DI	= YearClassInstance
		DX:BP	= RangeStruct to fill
		CX	= YearRangeType

RETURN:		DX:BP	= RangeStruct (filled)
		CX	= # of days in range

DESTROYED:	AX, DI, SI, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/14/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearGetSelection	method dynamic	YearClass, MSG_YEAR_GET_SELECTION
	.enter

	; See if we are getting the old or new range
	;
EC <	cmp	cx, YearRangeType					>
EC <	ERROR_AE	YEAR_ILLEGAL_YEAR_RANGE_TYPE			>
	mov	si, di
	add	si, offset YI_oldStartDay
	cmp	cx, YRT_PREVIOUS
	je	copyRange
	sub	si, (offset YI_oldStartDay) - (offset YI_startDay)

	; Load the structure, and determine the # of days in the range
copyRange:
	mov	es, dx
	mov	di, bp				; RangeStruct => ES:DI
	mov	cx, size RangeStruct / 2
	rep	movsw				; copy those words
	call	CalcDaysInRange			; days => CX

	.leave
	ret
YearGetSelection	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearSwitchToMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Switch to a different month

CALLED BY:	MonthValueObject (MSG_YEAR_SWITCH_TO_MONTH)

PASS:		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific intstance data
		DX	= New month (1-based)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/7/99		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearSwitchToMonth	method dynamic YearClass, MSG_YEAR_SWITCH_TO_MONTH
	.enter

	; See if we really need to do any work. Unless no month is
	; selected, we always forece a change, as the user could have
	; been silly and scrolled the month around. D'oh!
	;
	mov	ch, dl				; month => CH
	clr	ds:[di].YI_curMonth		; force change!

	; Yes, we need to do some work.
	;
	clr	dx				; don't change the year
	mov	ax, MSG_YEAR_SET_MONTH_AND_YEAR
	call	ObjCallInstanceNoLock

	.leave
	ret
YearSwitchToMonth	endp

YearCode	ends


