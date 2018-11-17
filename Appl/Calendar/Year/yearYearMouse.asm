COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Year
FILE:		yearYearMouse.asm

AUTHOR:		Don Reeves, April 5, 1991

ROUTINES:
	Name			Description
	----			-----------
	YearStartSelect		MSG_META_START_SELECT handler
	YearDrawSelect		MSG_DRAW_SELECT handler
	YearPtr			MSG_META_PTR handler
	YearEndSelect		MSG_META_END_SELECT handler
	OldRangeToCurrent	Move the old selected range back to the current
	CurrentRangeToOld	Copy the current selected range back to the old
	YearCallChildUnderPoint	My version of VisCallChildUnderPoint
	UpdateSelection		Update the selected range, based on new input
	DrawSelection		Draws the currently selected area on screen

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/5/89		Initial revision
	Don	12/19/91	Brought into 2.0, documented
	RR	5/31/95		Responder column major changes

DESCRIPTION:
	Mouse and selection procedures that operate on the Year Class

	$Id: yearYearMouse.asm,v 1.1 97/04/04 14:49:02 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearCode	segment	resource

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Mouse Input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to a mouse start selection event

CALLED BY:	UI (MSG_META_START_SELECT)

PASS:		ES	= DGroup
		DS:*SI	= MonthClass instance data
		DS:DI	= MonthClass specific instance data
		CX	= X position of mouse
		DX	= Y position of mouse
		BP	= (low) ButtonInfo
			= (high) UIFunctionsActive

RETURN:		AX	= MRF_PROCESSED or MRF_REPLAY

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		Want to grab mouse until select is released.
		Will not relinquish control to another UI object
		while we have the select.

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearStartSelect	method	dynamic	YearClass, MSG_META_START_SELECT

	; Grab mouse, and process event
	;
	test	ds:[di].YI_flags, (YI_NEEDS_INIT or YI_SELECT) ; if initialized
	jnz	done				; or already selecting, exit

	; New selection
	;
	or	ds:[di].YI_flags, YI_SELECT or YI_CLOSEST
	test	ds:[di].YI_flags, YI_GRAB_MOUSE	; need to grab the mouse ?
	jne	processNow
	or	ds:[di].YI_flags, YI_GRAB_MOUSE	; set the flag
	push	cx, dx				; save mouse position
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL	; get the grab
	mov	cx, ds:[LMBH_handle]		; block handle => CX
	mov	dx, si				; chunk handle => DX
	call	VisCallParent			; tell parent we want excl
	call	VisGrabMouse			; grab the mouse
	pop	cx, dx				; restore mouse position
	
	; Now do the work
	;
processNow:
	mov	ax, MSG_META_PTR			; method to pass
	call	YearCallChildUnderPoint
	jnc	done				; if no child, do nothing
	and	ds:[di].YI_flags, not YI_PIVOT_LAST
	clr	ax				; denotes a new selection
	call	UpdateSelection			; draw the hi-light
done:
	mov	ax, mask MRF_PROCESSED
	ret
YearStartSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearDrawSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Tells us that its OK to begin drag selecting

CALLED BY:	UI (MSG_META_DRAG_SELECT)

PASS:		ES	= DGroup
		DS:*SI	= Year instance data
		CX	= X position of mouse
		DX	= Y position of mouse
		BP	= (low) ButtonInfo
			= (high) UIFunctionsActive

RETURN:		AX	= MRF_PROCESSED

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/14/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearDrawSelect	method	dynamic YearClass,	MSG_META_DRAG_SELECT
	or	ds:[di].YI_flags, YI_DRAG_OK	; OK to drag select
	FALL_THRU	YearPtr			; now move the mouse
YearDrawSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearPtr
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to mouse movement

CALLED BY:	UI (MSG_META_PTR)

PASS:		ES	= DGroup
		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data
		CX	= X position of mouse
		DX	= Y position of mouse
		BP	= (low) ButtonInfo
			= (high) UIFunctionsActive

RETURN:		AX	= MRF_PROCESSED

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/19/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearPtr	method	YearClass, MSG_META_PTR

	; Check instance data for selection
	;
	and	ds:[di].YI_flags, not YI_CLOSEST ; clear the closest flag
	test	ds:[di].YI_flags, YI_SELECT	; test select flag
	jz	done				; if not set, done
	test	ds:[di].YI_flags, YI_DRAG_OK	; can we drag select yet?
	jz	done				; no, so do nothing

	; Call child; update selection area
	;
	mov	ax, MSG_META_PTR			; method to pass
	call	YearCallChildUnderPoint
	jnc	notOverChild			; jump if not over a child

	; Over a child - do the right thing
	;
	test	ds:[di].YI_flags, YI_OUT_OF_BOUNDS
	je	update				; if flags not set, update!
	and	ds:[di].YI_flags, not YI_OUT_OF_BOUNDS
	push	cx, dx				; save the position data
	clr	bp				; no GState
	mov	ax, 1				; use the old selection
	call	YearDrawSelection		; clear the old selection...
	clr	ax				; now use the current selection
	call	YearDrawSelection		; & draw it instead
	pop	cx, dx				; restore the position data
	jmp	update
	
	; Not over a child - do the right thing
	;
notOverChild:
	test	ds:[di].YI_flags, YI_OUT_OF_BOUNDS
	jne	done				; if flag already set, do nada
	or	ds:[di].YI_flags, YI_OUT_OF_BOUNDS
	clr	bp				; no GState
	clr	ax				; use the current selection
	call	YearDrawSelection		; clear the current selection
	mov	ax, 1				; use the old selection
	call	YearDrawSelection		; and draw it instead
	jmp	done				; we're done

	; Update and leave
update:
	call	UpdateSelection			; draw new selection
done:
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
	ret
YearPtr	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearEndSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to a mouse end selection event

CALLED BY:	UI (MSG_META_END_SELECT)

PASS:		ES	= DGroup
		DS:*SI	= YearClass instance data
		DS:DI	= YearClass specific instance data
		CX	= X position of mouse
		DX	= Y position of mouse
		BP	= (low) ButtonInfo
			= (high) UIFunctionsActive

RETURN:		AX	= MRF_PROCESSED or MRF_REPLAY

DESTROYED:	BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearEndSelect	method dynamic	YearClass, MSG_META_END_SELECT

	; Process event & release the mouse
	;
	mov	ax, ds:[di].YI_flags		; YearInfoFlags => AL
	and	ds:[di].YI_flags, not (YI_SELECT or \
		                       YI_CLOSEST or \
		                       YI_DRAG_OK or \
		                       YI_GRAB_MOUSE)
	test	ax, YI_SELECT			; are we selecting ??
	jz	done				; no! - exit
	call	VisReleaseMouse			; release the mouse
	test	ax, YI_DRAG_OK			; can we drag yet ??
	jz	zoom				; no, so just select one day
	mov	ax, MSG_META_PTR			; method to pass
	call	YearCallChildUnderPoint
	jnc	notOverChild			; if no child, replay event

	; Else update the selection & zoom
	;
	and	ds:[di].YI_flags, not YI_OUT_OF_BOUNDS
	call	UpdateSelection
zoom:
	mov	ax, MSG_YEAR_COMPLETE_SELECTION
	call	ObjCallInstanceNoLock		; display events in date range
	mov	ax, mask MRF_PROCESSED		; we took the event
	ret

	; Clear the selected area
	;
notOverChild:
	test	ds:[di].YI_flags, YI_SEL_REGION	; is a region selected ??
	jz	finish				; if not, jump
	test	ds:[di].YI_flags, YI_OUT_OF_BOUNDS
	jnz	finish				; if already out, do nothing
	clr	bp				; no GState is passed
	clr	ax				; use the current selection
	call	YearDrawSelection		; clear the current selection

	; Move the old values back to the current selection & redraw
	;
finish:
	or	ds:[di].YI_flags, YI_SEL_REGION	; set the flag
	call	OldRangeToCurrent		; move the range to current
	test	ds:[di].YI_flags, YI_OUT_OF_BOUNDS
	jne	done				; if already out of bounds, jmp
	clr	ax				; draw the current selection
	call	YearDrawSelection		; else redraw the range
done:
	and	ds:[di].YI_flags, not (YI_OUT_OF_BOUNDS)
	mov	ax, mask MRF_REPLAY		; replay the event
	ret
YearEndSelect	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearCallChildUnderPoint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Replaces VisCallChildUnderPoint, except that CX, DX, and BP
		are not preserved.

CALLED BY:	GLOBAL

PASS:		DS:*SI	= YearClass Instance data
		AX	= Method to pass
		CX, DX	= Location in document corrdinates
		BP	= Data to pass

RETURN:		CX	= }
		DX	= } child's return data
		BP	= }
		Carry	= Set if a child responded
			= Clear if no child under point
		AX	= Non-zero
		DS:DI	= YearClass specific instance data

DESTROYED:	BX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/19/89		Initial version
	Don	7/30/90		Return YearClass instance data

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearCallChildUnderPoint	proc	near
	class	YearClass
	.enter

	; Set up the VisCallChildUnderPoint call
	;
	call	VisCallChildUnderPoint
	mov	ax, 1				; force AX non-zero
	pushf	
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; instance data => DS:DI
	popf

	.leave
	ret
YearCallChildUnderPoint	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Keyboard Input
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearSpecNavigationQuery
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Determine what types of navigation this class supports.

CALLED BY:	GLOBAL (MSG_SPEC_NAVIGATION_QUERY)

PASS:		*DS:SI	= YearClass object
		DS:DI	= YearClassInstance
		CX:DX	= Originating objecct OD
		BP	= NavigateFlags

RETURN:		see NavigateCommon

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/12/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearSpecNavigationQuery	method dynamic	YearClass, MSG_SPEC_NAVIGATION_QUERY
		.enter

		; Respond with what we can handle
		;
		mov	bl, mask NCF_IS_FOCUSABLE
		mov	di, si		; handle of generic object
		call	VisNavigateCommon

		.leave
		ret
YearSpecNavigationQuery	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process a keyboard character

CALLED BY:	GLOBAL (MSG_META_KBD_CHAR)

PASS:		ES	= DGroup
		*DS:SI	= YearClass object
		DS:DI	= YearClassInstance
		BP high	= (ignored) scan code
		BP low	= (ignored) ToggleState
		DH	= ShiftState
		DL	= CharFlags
		CX	= Character value

RETURN:		Nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/11/92		Initial version
		sean	1/24/96		Responder added shortcut for
					Ctrl-N & Ctrl-P
		sean	4/5/96		Responder added shortcut for
					Enter(carriage return)
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearKbdChar	method dynamic	YearClass, MSG_META_KBD_CHAR

	; First let's see if we want to swallow this event
	;
	test	dl, mask CF_FIRST_PRESS or \
		    mask CF_REPEAT_PRESS
	jz	fup				; ignore all other CharFlags
	test	dh, not (mask SS_LSHIFT or mask SS_RSHIFT)
	jnz	fup				; ignore all but these states
	push	ds, si				; save object
	segmov	ds, cs
	mov	si, offset yearShortcutTable	; shortcut table => DS:SI
	mov	ax, YEAR_NUM_SHORTCUTS		; # entries in table => AX
	call	FlowCheckKbdShortcut		; do we understand ??
	mov	bx, si				; offset => BX
	pop	ds, si				; restore object
	jc	goodKey				; yes, so jump

		
	; We don't understand the key-press. Pass it on to
	; our parent, in quick fashion
fup:
	mov	si, offset YearView		; parent view OD => *DS:SI
	mov	ax, MSG_META_FUP_KBD_CHAR	; message to send, of course
	GOTO	ObjCallInstanceNoLock		; send it on up

	; We found a keypress/character that we understand. Call the
	; correct routine to return the newly selected area
goodKey:
	clr	ax				; assume a new selection
	mov	bp, offset YI_endDay		; assume pivot on first day
	test	ds:[di].YI_flags, YI_PIVOT_LAST
	jz	getCurrent			; if good assumtion, jump
	mov	bp, offset YI_startDay		; else we muck with the start
getCurrent:
	mov	dx, ds:[di][bp+0]		; month/day => DX
	mov	bp, ds:[di][bp+2]		; year => BP
	call	cs:[yearShortcutRoutines][bx]
	jc	done				; if error, abort

	; We have selected a new range of events - go display them now.
	;
	mov	cx, dx				; month/day => CX
	mov	dx, bp				; year => DX
	call	YearSetMonthAndYear		; change to new month/year
	call	UpdateSelection			; update the selection
	call	PositionYearDocument		; ensure selection is on-screen
	mov	ax, MSG_YEAR_COMPLETE_SELECTION
	call	ObjCallInstanceNoLock		; display events in date range
done:
	ret
YearKbdChar	endm

if DBCS_PCGEOS
yearShortcutTable	KeyboardShortcut \
	<1, 0, 0, 0, C_SYS_LEFT and mask KS_CHAR>, 
	<1, 0, 0, 1, C_SYS_LEFT and mask KS_CHAR>, 
	<1, 0, 0, 0, C_SYS_RIGHT and mask KS_CHAR>, 
	<1, 0, 0, 1, C_SYS_RIGHT and mask KS_CHAR>, 
	<1, 0, 0, 0, C_SYS_UP and mask KS_CHAR>, 
	<1, 0, 0, 1, C_SYS_UP and mask KS_CHAR>, 
	<1, 0, 0, 0, C_SYS_DOWN and mask KS_CHAR>, 
	<1, 0, 0, 1, C_SYS_DOWN and mask KS_CHAR>
else
yearShortcutTable	KeyboardShortcut \
			<1, 0, 0, 0, (CS_CONTROL and 0fh), VC_LEFT>, 
			<1, 0, 0, 1, (CS_CONTROL and 0fh), VC_LEFT>, 
			<1, 0, 0, 0, (CS_CONTROL and 0fh), VC_RIGHT>, 
			<1, 0, 0, 1, (CS_CONTROL and 0fh), VC_RIGHT>, 
			<1, 0, 0, 0, (CS_CONTROL and 0fh), VC_UP>, 
			<1, 0, 0, 1, (CS_CONTROL and 0fh), VC_UP>, 
			<1, 0, 0, 0, (CS_CONTROL and 0fh), VC_DOWN>, 
			<1, 0, 0, 1, (CS_CONTROL and 0fh), VC_DOWN>
endif

YEAR_NUM_SHORTCUTS	= ($ - yearShortcutTable) / 2

yearShortcutRoutines	nptr.near \
			YearKbdProcessArrowLeft,
			YearKbdProcessArrowLeftExtend,
			YearKbdProcessArrowRight,
			YearKbdProcessArrowRightExtend,
			YearKbdProcessArrowUp,
			YearKbdProcessArrowUpExtend,
			YearKbdProcessArrowDown,
			YearKbdProcessArrowDownExtend


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		YearKbdProcessArrow[Left, Right, Up, Down]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process an arrow key keyboard press

CALLED BY:	YearKbdChar()

PASS:		DS:DI	= YearInstance
		BP	= Year
		DH	= Month
		DL	= Day
		AL	= 0

RETURN:		BP	= New year
		DH	= New month
		DL	= New day
		AL	= 0 - new selection
			!=0 - extend selection
		Carry	= Set if error

DESTROYED:	CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/11/92		Initial version
		RR	5/31/95		column major mangling
		sean	2/10/96		Handle Ctrl-N/P for month

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

YearKbdProcessArrowLeftExtend	proc	near
		mov	al, 1
YearKbdProcessArrowLeft		label	near
if	COL_MAJOR_MONTH
		mov	cx, -7			; go backwards one week
else
		mov	cx, -1			; go backwards one day
endif
		call	CalcDateAltered		; new year/month/day => BP/DX
		ret
YearKbdProcessArrowLeftExtend	endp



YearKbdProcessArrowRightExtend	proc	near
		mov	al, 1
YearKbdProcessArrowRight	label	near
if	COL_MAJOR_MONTH
		mov	cx, 7
else
		mov	cx, 1			; go forward one day
endif
		call	CalcDateAltered		; new year/month/day => BP/DX
		ret
YearKbdProcessArrowRightExtend	endp



YearKbdProcessArrowUpExtend	proc	near
		mov	al, 1
YearKbdProcessArrowUp		label	near
if	COL_MAJOR_MONTH
		mov	cx, -1
else
		mov	cx, -7			; go backwards one week
endif
		call	CalcDateAltered		; new year/month/day => BP/DX
		ret
YearKbdProcessArrowUpExtend	endp



YearKbdProcessArrowDownExtend	proc	near
		mov	al, 1			; extend the selection
YearKbdProcessArrowDown		label	near
if	COL_MAJOR_MONTH
		mov	cx, 1
else
		mov	cx, 7			; go forward one week
endif
		call	CalcDateAltered		; new year/month/day => BP/DX
		ret
YearKbdProcessArrowDownExtend	endp





COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		BringUpDetailsDialog
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Bring up details dialog and make its description text object
		the focus so that characters typed in by the user appears
		in it.

		Actually, we need to "send" a message to DayPlanObject to
		accomplish this since we are run by UI thread and we cannot
		make any "calls."

CALLED BY:	MakeDetailsDialogFocus
PASS:		ax	= passed hour
		cx	= character value
		bp	= DayPlanHandleKeyStrokeFlag
RETURN:		nothing
DESTROYED:	nothing

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	jang    	2/ 5/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Common routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OldRangeToCurrent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the old range to the current range

CALLED BY:	INTERNAL
	
PASS:		DS:DI	= YearClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OldRangeToCurrent	proc	near
	class	YearClass
	.enter

	mov	ax, ds:[di].YI_oldStartYear
	mov	bx, ds:[di].YI_oldEndYear
	mov	cx, {word} ds:[di].YI_oldStartDay
	mov	dx, {word} ds:[di].YI_oldEndDay
	mov	ds:[di].YI_startYear, ax
	mov	ds:[di].YI_endYear, bx
	mov	{word} ds:[di].YI_startDay, cx
	mov	{word} ds:[di].YI_endDay, dx

	.leave
	ret
OldRangeToCurrent	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CurrentRangeToOld
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Move the old range to the current range

CALLED BY:	INTERNAL
	
PASS:		DS:DI	= YearClass specific instance data

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CurrentRangeToOld	proc	near
	class	YearClass
	.enter

	mov	ax, ds:[di].YI_startYear
	mov	bx, ds:[di].YI_endYear
	mov	cx, {word} ds:[di].YI_startDay
	mov	dx, {word} ds:[di].YI_endDay
	mov	ds:[di].YI_oldStartYear, ax
	mov	ds:[di].YI_oldEndYear, bx
	mov	{word} ds:[di].YI_oldStartDay, cx
	mov	{word} ds:[di].YI_oldEndDay, dx

	.leave
	ret
CurrentRangeToOld	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call for selection update, in various forms

CALLED BY:	Year[Start, End]Selection, YearMoveMouse

PASS:		ES	= DGroup
		DS:*SI	= Year instance data
		AX	= 0 for new selection
		CL	= Day (or 0 for a bad day)
		CH	= Month
		DX	= Year

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/16/89		Initial version
	sean	10/5/95		Responder changes for drawing selected
				date in month

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateSelection	proc	near
	class	YearClass			; friend to this class

	; Access instance data
	;
	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].Year_offset		; access instance data
	clr	bp				; no GState here !!!!
	test	es:[features], mask CF_SELECTION
	LONG	jz	singleSelection		; just perform single selection
	tst	ax				; update or new ??
	jnz	old				; we need to update selection

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
	jb	new				; if usable
endif

	; Clear old selection
	;
	test	ds:[di].YI_flags, YI_SEL_REGION	; a region is selected
 	je	new				; jump if not set
	push	cx, dx				; save the new range values
	call	CurrentRangeToOld		; copy to old range
	clr	ax				; use the current selection
	call	YearDrawSelection		; and clear it
	pop	cx, dx				; restore the new range values

	; A new region to hi-light ??
new:
	or	ds:[di].YI_flags, YI_SEL_REGION	; set this flag
	mov	ds:[di].YI_curMonth, ch		; a new current month
	mov	{word} ds:[di].YI_startDay, cx	; store start day
	mov	{word} ds:[di].YI_endDay, cx	; store end day
	mov	ds:[di].YI_startYear, dx	; store start year
	mov	ds:[di].YI_endYear, dx		; store end year
	mov	dx, cx				; end = start
	GOTO	DrawSelection			; new inversion

	; Undraw the old selection area
old:
	or	ds:[di].YI_flags, YI_SEL_REGION	; set this flag
	test	ds:[di].YI_flags, YI_PIVOT_LAST	; which direction ??
	jne	last

	; Drawing with pivot point as start point
	;
	cmp	dx, ds:[di].YI_endYear
	jg	after
	jl	first2
	cmp	cx, {word} ds:[di].YI_endDay
	jg	after
	LONG	je	done
first2:
	cmp	dx, ds:[di].YI_startYear
	jl	before1
	jg	inter1
	cmp	cx, {word} ds:[di].YI_startDay
	jl	before1
	jmp	inter1

	; Draw with pivot date as end date
last:
	cmp	dx, ds:[di].YI_startYear
	jl	before2
	jg	last2
	cmp	cx, {word} ds:[di].YI_startDay
	jl	before2
last2:
	cmp	dx, ds:[di].YI_endYear
	jg	after
	jl	inter2
	cmp	cx, {word} ds:[di].YI_endDay
	jg	after
	jmp	inter2
	
	; Selection between start and end (undraw part), pivot is start
inter1:
	mov	ds:[di].YI_endYear, dx		; store end year
	mov	dx, {word} ds:[di].YI_endDay
	mov	{word} ds:[di].YI_endDay, cx	; store end day/month
	inc	cl				; start one day over
	jmp	drawAndDone

	; Selection between start and end (undraw part), pivot is end
inter2:
	mov	ds:[di].YI_startYear, dx	; store end year
	mov	dx, cx				; new start in DX
	xchg	cx, {word} ds:[di].YI_startDay	; xchg old/new 1st M/D
	dec	dl				; start one day over
	jmp	drawAndDone
	
	; Before case 1, start time before the pivot point
before1:
	or	ds:[di].YI_flags, YI_PIVOT_LAST
	xchg	ds:[di].YI_startYear, dx	; exchange start years
	mov	ds:[di].YI_endYear, dx		; 1st year => end year
	xchg	cx, {word} ds:[di].YI_startDay	; exchange start days
	mov	dx, cx				; old start day into DX
	xchg	dx, {word} ds:[di].YI_endDay	; xchg end day/months
	call	DrawSelection			; new inversion
	mov	dx, cx				; old start D/M => end
	mov	cx, {word} ds:[di].YI_startDay	; new start D/M => CX
	jmp	drawAndDone

	; Before case 2, repeatedly before the pivot point (just adjust start)
before2:
	mov	ds:[di].YI_startYear, dx	; new start year
	mov	dx, {word} ds:[di].YI_startDay	; get the old 1st M/D
	mov	{word} ds:[di].YI_startDay, cx	; store new 1st M/D
	dec	dl				; no draw old 1st M/D
	jmp	drawAndDone

	; Selection after end (draw new)
after:
	test	ds:[di].YI_flags, YI_PIVOT_LAST	; pivot on end ??
	je	after2

	; Must uninvert between start and end, and move end to start
	;
	push	cx, dx
	mov	cx, {word} ds:[di].YI_startDay	; get start M/D
	mov	dx, {word} ds:[di].YI_endDay	; get end M/D (pivot)
	mov	{word} ds:[di].YI_startDay, dx	; end => start (pivot)
	dec	dl				; back up one day
	call	DrawSelection
	pop	cx, dx

	; Simply change end bound, and invert between old and new end
after2:
	and	ds:[di].YI_flags, not YI_PIVOT_LAST	; clear this flag
	mov	ds:[di].YI_endYear, dx		; store new end year
	mov	dx, cx				; end M/D => DX
	xchg	cx, {word} ds:[di].YI_endDay	; xchg old/new end M/D
	inc	cl				; start one day over
drawAndDone:
	call	DrawSelection			; invert or uninvert

	; Check for end day = last day. If so, clear pivot last flag
done:
	mov	ch, ds:[di].YI_startMonth	; start month => CL
	mov	ds:[di].YI_curMonth, ch		; this is now the current month
	mov	cx, {word} ds:[di].YI_startDay	; start month/day => CX
	cmp	cx, {word} ds:[di].YI_endDay	; compare with end month/day
	jne	realDone			; if start > end, do nothing
	mov	cx, ds:[di].YI_startYear	; start year => CX
	cmp	cx, ds:[di].YI_endYear		; compare with the end year
	jne	realDone			; if start != end, do nothing
	and	ds:[di].YI_flags, not YI_PIVOT_LAST
realDone:
	ret
	
	; Erase the old selection (if things have changed)
singleSelection:
	test	ds:[di].YI_flags, YI_SEL_REGION	; a region is selected
 	jz	brandNew			; jump if not set
	cmp	dx, {word} ds:[di].YI_startYear	; compare the years
	jne	continue
	cmp	cx, {word} ds:[di].YI_startDay	; compare month/day
	je	realDone			; if equal, do nothing
continue:
	push	ax, cx, dx
	clr	ax				; use the current selection
	call	YearDrawSelection		; and clear it
	pop	ax, cx, dx

	; Highlight the new region
brandNew:
	tst	ax				; update or new ??
	jnz	updateNew			; we need to update selection
	push	cx, dx
	call	CurrentRangeToOld		; backup current range to old
	pop	cx, dx
updateNew:
	or	ds:[di].YI_flags, YI_SEL_REGION	; set this flag
	mov	ds:[di].YI_curMonth, ch		; a new current month
	mov	{word} ds:[di].YI_startDay, cx	; store start day
	mov	{word} ds:[di].YI_endDay, cx	; store end day
	mov	ds:[di].YI_startYear, dx	; store start year
	mov	ds:[di].YI_endYear, dx		; store end year
	mov	dx, cx				; end = start
	call	DrawSelection			; new inversion
	ret
UpdateSelection	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the current selection

CALLED BY:	UpdateSelection

PASS:		DS:*SI	= Instance data
		CH	= Start month
		CL	= Start day
		DH	= End month
		DL	= End day
		BP	= GState (if not, BP = 0)

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/16/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawSelection	proc	near
	class	YearClass			; friend to this class
	uses	bx, cx, dx, di, si
	.enter

	; Create the GState
	;
	mov	di, bp				; GState or zero => DI
	tst	di				; was a GState passed ??
	jnz	setMode				; already have a GState
	mov	ax, MSG_VIS_VUP_CREATE_GSTATE	; create the GState
	call	ObjCallInstanceNoLock		; GState => BP
setMode:
	push	di				; save the original GState/0
	mov	al, MM_INVERT
	mov	di, bp				; GState into DI
	call	GrSetMixMode			; set to invert mode

	; Calculate handle of start month to draw to
	;
	mov	si, Month1			; first handle => SI
	mov	al, ch				; first month to AL
	clr	ah
	dec	al				; change to zero-based
	shl	ax				; double to make a handle
	add	si, ax				; starting handle => SI

	; Loop through the months for drawing
drawLoop:
	push	cx, dx				; handle, start MD, end MD
	cmp	ch, dh				; compare the months
	je	10$				; jump if equal
	mov	ch, 32				; maximum day is end day
	jmp	20$			
10$:
	mov	ch, dl				; move end day to CH
20$:
	mov	ax, MSG_MONTH_SELECT_DRAW	; draw the selection
	call	ObjCallInstanceNoLock
	pop	cx, dx
	add	si, 2				; go to the next month
	cmp	ch, dh				; compare the months
	je	done				; we're done if equal
	mov	cl, 1				; after 1st month, start= day 1
	inc	ch				; go to the next month
	cmp	ch, 12				; month == December ??
	jle	drawLoop			; no, so continue
	mov	ch, 1				; set month to January
	jmp	drawLoop
	
	; We're done - kill the GState
done:
	mov	di, bp				; move the GState to DI
	mov	al, MM_COPY				
	call	GrSetMixMode			; set to normal mode
	pop	bp				; restore passed BP
	tst	bp				; was there a passed GState??
	jne	exit				; don't destroy passed GState
	call	GrDestroyState 			; destroy the GState
exit:
	.leave
	ret
DrawSelection	endp

YearCode	ends
