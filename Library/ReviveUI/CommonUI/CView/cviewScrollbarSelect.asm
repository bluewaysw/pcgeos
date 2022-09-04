COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1990 -- All Rights Reserved
	GEOWORKS CONFIDENTIAL

PROJECT:	GEOS
MODULE:		CommonUI/CView
FILE:		cviewScrollbarSelect.asm

ROUTINES:
	Name			Description
	----			-----------
 ?? INT OLScrollbarStartPress	Starts a scrollbar press

 ?? INT OLScrollbarEndPress	Starts a scrollbar press

 ?? INT HandlePress		Handles a single press.  Can be called
				either by the user pressing or if the
				window is done redrawing and the user is
				still pressing.

 ?? INT DrawIfNotXoring		Redraws things if we're not currently doing
				an xor.

 ?? INT ShouldWeScroll?		Figures out if we should scroll the window
				on this action.

 ?? INT StartScrollbarTimer	Starts a timer.

 ?? INT CancelScrollbarTimer	Cancels any timer that's currently going.

    INT DoScrollCriteria	See what the mouse situation is.  Sees if
				mouse is pressed and figures out what was
				pressed on if so.

    INT DoScrollCriteria	See what the mouse situation is.  Sees if
				mouse is pressed and figures out what was
				pressed on if so.

    INT DoScrollCriteria	See what the mouse situation is.  Sees if
				mouse is pressed and figures out what was
				pressed on if so.

 ?? INT FSDoScrollCriteria	Do scroll criteria for floating scrollers.

    INT DoScrollAction		Takes action if the mouse is down.  Actions
				differ depending on who was pressed.

    INT DoIncDown		Does an incremental downward scroll.

 ?? INT DoIncUp			Handles incrementing up scrollbar.

 ?? INT ValueSendMsg		Handles incrementing up scrollbar.

 ?? INT DoPageDown		Pages down the scrollbar.

 ?? INT SetIfSlider		Pages down the scrollbar.

 ?? INT DoPageUp		Pages up the scrollbar.

    GLB DoEndAnchor		Goes to start of scrollbar.  Does nothing
				in motif.

    GLB DoBegAnchor		Goes to start of scrollbar.  Does nothing
				in motif.

 ?? INT DoDragArea		Drags the document to new location.

 ?? INT FinishDrag		Finishes dragging.

 ?? INT HandleDragXor		Handles the xor region when a-draggin.

 ?? INT XorElevator		Draws a new xor-ed rectangle.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	2/90		Broken off from regular scrollbar.

DESCRIPTION:

	$Id: cviewScrollbarSelect.asm,v 1.72 96/09/17 01:29:37 joon Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


ScrollbarCommon segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Process current ptr & function state to determine whether
		a button should be up or down

CALLED BY:	MSG_META_START_SELECT

PASS:		*ds:si	- object
		cx, dx	- ptr position (x, y)
		bp low  - ButtonInfo		(In input.def)
			  mask BI_PRESS		- set if press
			  mask BI_DOUBLE_PRESS	- set if double-press
			  mask BI_B3_DOWN	- state of button 3
			  mask BI_B2_DOWN	- state of button 2
			  mask BI_B1_DOWN	- state of button 1
			  mask BI_B0_DOWN	- state of button 0
			  mask BI_BUTTON	- for non-PTR events, is
						  physical button which has
						  caused this event to be
						  generated.

		bp high - UIFunctionsActive	(In Objects/uiInputC.def)


RETURN:		ax =	0 if ptr not in button,
			mask MRF_PROCESSED if ptr is inside

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:
      Motif version doesn't have an xor'ed region for the thumb.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	5/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

NO_XOR_ELEVATOR		=	-1		;used in OLSBI_xorElevOff
			
if _CUA_STYLE		;START of MOTIF/PM/CUA specific code -----

OLScrollbarSelect	method OLScrollbarClass, MSG_META_START_SELECT,   \
						 MSG_META_END_SELECT,	\
						 MSG_META_PTR
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	test	ds:[di].GI_attrs, mask GA_READ_ONLY
	LONG jnz	processed

	cmp	ax, MSG_META_START_SELECT
	jne	noSound
	call	OpenDoClickSound
noSound:
	;
	; Adjust mouse position to be offset into width of scrollbar in dx,
	; offset along length of scrollbar from top of scroll area in cx.
	;
	mov	di, ds:[si]
	push	di				;save pointer to instance
	add	di, ds:[di].Vis_offset

	sub	dx, ds:[di].VI_bounds.R_top	;make dx offset from top
	sub	cx, ds:[di].VI_bounds.R_left	;and cx offset from left
if SLIDER_INCLUDES_VALUES and DRAW_STYLES
	;
	; for sliders, adjust bounds for draw style inset
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	notSlider
	cmp	ds:[di].OLSBI_drawStyle, DS_FLAT
	je	notSlider
	sub	dx, DRAW_STYLE_INSET_WIDTH
	sub	cx, DRAW_STYLE_INSET_WIDTH
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jz	notSlider
						; thin inset for gauge
	add	dx, DRAW_STYLE_INSET_WIDTH-DRAW_STYLE_THIN_INSET_WIDTH
	add	cx, DRAW_STYLE_INSET_WIDTH-DRAW_STYLE_THIN_INSET_WIDTH
notSlider:
endif
	pop	di				;get back pointer to instance
	add	di, ds:[di].Vis_offset		;ds:di = SpecificInstance
	call	SwapIfHorizontal		;swap if horizontal

if FLOATING_SCROLLERS
	;
	;  We can pretty much dispense with most of the code that
	;  follows, unless we're a slider or GenValue scroller.
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER or mask OLSA_TWISTED
	jz	doneOffsets
endif

	;
	; Make dx relative to start of scroll area.  Act horizontal.
	;
MO <	clr	ax							>
if SLIDER_INCLUDES_VALUES
	;	
	; no arrow for gauges only
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	haveArrow
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jnz	5$
haveArrow:
else
MO <	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER			>
MO <	jnz	5$							>
endif

NOT_MO<	mov	ax, MO_SCR_AREA_MARGIN		;assume a normal scrollbar>
PMAN<	mov	ax, MO_SCR_AREA_MARGIN		;assume a normal scrollbar>
MO<	mov	ax, ds:[di].OLSBI_arrowSize				>

if	_MOTIF
ARROWSHADOW   <	add	ax, 3						>
NOARROWSHADOW <	add	ax, 2						>
endif	;_MOTIF

if _JEDIMOTIF	;--------------------------------------------------------------
	add	ax, 1				;add a total of 4 for vert
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jnz	vert
	add	ax, 2				;add a total for 6 for horiz
vert:
endif	; _JEDIMOTIF ----------------------------------------------------------

RUDY <	add	ax, 3				;add a total of 6	>

5$:
MO <	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED			>
MO <	jz	10$				;not twisted, branch	>
MO <	mov	ax, ds:[di].OLSBI_arrowSize	;else use width		>
MO <	inc	ax							>
JEDI <	add	ax, 5				;add a total of 6	>
RUDY <	add	ax, 5				;add a total of 6	>
MO <	xchg	cx, dx				;swap these back	>
MO <10$:								>

PMAN <	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED			>
PMAN <	jz	10$				;not twisted, branch	>
PMAN <	mov	ax, PM_SPIN_ARROW_HEIGHT+2	;else use height	>
PMAN <10$:								>
	sub	dx, ax				;dx <- offset along scrollbar
	
doneOffsets::
	;
	; If this is a release, always do the release, regardless of 
	; whether the scrollbar is scrollable!   We don't want to get caught
	; with the scrollbar becoming not scrollable between a press and a
	; release.   6/ 5/94 cbh
	;
	test	bp, (mask UIFA_SELECT) shl 8
	jz 	release				;if not, then release grab, etc.

	;
	; If Doc range is less than winLen, ignore everything.  Always handle
	; presses if stupid, or if there's no thumb.
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_STUPID
	jnz	skipCheck			;always handle presses if stupid

MO <	cmp	ds:[di].OLSBI_elevOffset, NO_THUMB_ELEV_OFFSET		>
PMAN <	cmp	ds:[di].OLSBI_elevOffset, NO_THUMB_ELEV_OFFSET		>
	je	skipCheck

	push	cx
	mov	cx, ds:[di].OLSBI_elevLen
	cmp	cx, ds:[di].OLSBI_scrArea
	pop	cx
	jz	processed			;exit if nothing to scroll
skipCheck:
	call	OLScrollbarStartPress		;start a press
	jmp	short exit

release:					;user is really releasing
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	clr	ds:[di].OLSBI_startState	;no more start state
	call	CancelScrollbarTimer		;turn off timer
	call	VisReleaseMouse			;Release the mouse
						
offScrollbar:					;user has moved off scrollbar
	call	OLScrollbarEndPress		;
	jmp	short exit
	
processed:					;if enter/leave of button
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
						;Say processed if ptr in bounds
exit:
	ret
OLScrollbarSelect	endm

endif		;END of MOTIF/PM/CUA specific code --------------------



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarLostGadgetExcl
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Turn off scrollbar timer, etc.

CALLED BY:	MSG_VIS_LOST_GADGET_EXCL

PASS:		*ds:si 	- instance data
		es     	- segment of MetaClass
		ax 	- MSG_VIS_LOST_GADGET_EXCL

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

OLScrollbarLostGadgetExcl	method OLScrollbarClass, \
					MSG_VIS_LOST_GADGET_EXCL
CUAS <	call	CancelScrollbarTimer		;turn off timer		>
CUAS <	call	VisReleaseMouse			;Release the mouse	>
	call	OLScrollbarEndPress		;stop drag
	ret
OLScrollbarLostGadgetExcl	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarStartPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a scrollbar press

CALLED BY:	OLScrollbarSelect

PASS:		*ds:si -- scrollbar
		cx, dx	- ptr position (x, y)

RETURN:		ax -- processed flags

DESTROYED:	bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CUA_STYLE
	
OLScrollbarStartPress	proc	near
	;
	; If we're moving into the scrollbar, and never clicked in the scrollbar
	; then forget about grabbing the mouse.  We'll ignore the event. 8/7/90
	;
	test	bp, mask BI_PRESS		;see if a new mouse press
	jnz	10$				;branch if so
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	tst	ds:[di].OLSBI_startState	;was anything ever pressed?
	mov	ax, mask MRF_REPLAY		;assume not, we don't want event
	LONG	jz	exit			;nothing pressed, exit
10$:
	;
	; Make sure scrollbar has some something depressed, and that we
	; have the grab, and that a function is being called for the
	; depressed item.
	;
	push	cx, dx, bp			;Save mouse position
	mov	cx, ds:[0]			;Take the gadget exclusive
	mov	dx, si
	mov	ax, MSG_VIS_TAKE_GADGET_EXCL
	call	VisCallParent
	pop	cx, dx, bp
	;
	; Grab the mouse if a new down press:
	;	al <- DoScrollCriteria
	;       if al is null, goto offScrollbar
	;       bl <- OLSBI_state & OLSS_DOWN_FLAGS
	;	if (OLSBI_startState == 0)	;new press
	;	    store al in OLSBI_startState
	;	    goto changeState
	;	else
	;	    if (OLSBI_startState <> OLSS_DRAG_AREA)
	;		and (al != OLSBI_startState)
	;		goto offScrollbar
	;	    else
	;		if al == bl
	;		    goto stillDown
	;		else if OLSBI_startState
	;		    goto changeState
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset

	call	DoScrollCriteria	        ;al <- where press was made
	tst	al				;anything pressed?
if SPINNER_GEN_VALUE
	;
	; stop timer if no action
	;
	jnz	haveAction
	test	ds:[di].OLSBI_attrs, mask OLSA_SPINNER
	jz	skipStopTimer
	call	CancelScrollbarTimer
skipStopTimer:
	jmp	OLScrollbarEndPress
	
haveAction:
else
	LONG	jz	OLScrollbarEndPress	;no, handle mouse up
endif
	mov	bl, ds:[di].OLSBI_state		;get current state
	and	bl, mask OLSS_DOWN_FLAGS	;just look at down flags

	test	bp, mask BI_PRESS		;see if a new mouse press
	jz	ptrEvent			;branch if not
	mov	ds:[di].OLSBI_startState, al	;else store as start state
	mov	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR		
	jmp	short changeState		;and go change states

ptrEvent:
	cmp	ds:[di].OLSBI_startState, OLSS_DRAG_AREA ;different code for
	jne	nonDrag			         ;  drag area
	cmp	bl, al				;let's keep original offsets
	je	stillDown			;   to the elevator
	jmp	short setState			;

nonDrag:
	cmp	al, ds:[di].OLSBI_startState	;original gadget still pressed?
	jne	OLScrollbarEndPress		;nope, branch to de-highlight

dragEvent::
	cmp	bl, al				;see if still down on same part
	je	stillDown			;yes, go process it

changeState:
	;
	; We need to start doing something.
	;
	mov	ds:[di].OLSBI_clickXOff,cx 	;save offset to width
	mov	bx, dx
	sub	bx, ds:[di].OLSBI_elevOffset    ;subtract offset to elevator
	mov	ds:[di].OLSBI_clickYOff, bx 	;and save

setState:
	mov	bl, ds:[di].OLSBI_state		;get other state flags
	and	bl, not mask OLSS_DOWN_FLAGS	;and off old down flags
	mov	al, ds:[di].OLSBI_startState	;get start state back
	or	al, bl				;or in new down flags
	mov	ds:[di].OLSBI_state, al		;and store
	and	al, mask OLSS_DOWN_FLAGS	;just look at down flags

	cmp	al, OLSS_DRAG_AREA		;if dragging, don't invalidate
	je	grabMouse
	or	ds:[di].OLSBI_state, mask OLSS_INVALID_IMAGE

grabMouse:
	call	VisGrabMouse			;Grab the mouse
	jmp	short handlePress

stillDown:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].OLSBI_startState
	and	al, mask OLSS_DOWN_FLAGS
	cmp	al, OLSS_DRAG_AREA
	jne	processed

handlePress:
	call	HandlePress			;handle the press
processed:					;if enter/leave of button
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
exit:						;Say processed if ptr in bounds
	ret
OLScrollbarStartPress	endp

endif	; _CUA_STYLE
	

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		OLScrollbarEndPress
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Starts a scrollbar press

CALLED BY:	OLScrollbarSelect

PASS:		*ds:si -- scrollbar
		cx, dx	- ptr position (x, y)

RETURN:		ax -- processed flags

DESTROYED:	bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 8/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	_CUA_STYLE 
	
OLScrollbarEndPress	proc	near
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = SpecificInstance

CUAS <	call	FinishDrag			;finish up drag		  >
CUAS <	jc	noChange			;if we were dragging, exit>
   
						;See if already up
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_state, mask OLSS_DOWN_FLAGS
	LONG	jz	noChange		;if up, OK, done
						;ELSE need to change state
	;
	; Make sure scrollbar is released.
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset		;ds:di = SpecificInstance
	mov	al, ds:[di].OLSBI_state		;get current state
	and	al, mask OLSS_DOWN_FLAGS	;just look at down flags
	
	;
	; Clear down flags and invalidate image if necessary.
	;
	cmp	al, OLSS_DRAG_AREA		;don't invalidate on drags  
	je	clearDownFlags						    
	or	ds:[di].OLSBI_state, mask OLSS_INVALID_IMAGE
	
clearDownFlags:							    
	and	ds:[di].OLSBI_state, not (mask OLSS_DOWN_FLAGS)
	call	OpenDrawObject		  	;redraw the scrollbar

if FLOATING_SCROLLERS
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER or mask OLSA_TWISTED
	jnz	afterUpdate

	mov	ax, MSG_SPEC_VIEW_UPDATE_FLOATING_SCROLLERS
	clr	cx				;don't close windows
	call	VisCallParent
afterUpdate:
endif

releaseMouse:
	mov	ax, mask MRF_REPLAY		;Replay this, since we didn't
	jmp	short exit			;	want it.

noChange:
	clr	ax
	test	bp, (mask UIFA_IN) shl 8	;is point in bounds?
	jz	exit				;if not, skip

OLSS_processed:					;if enter/leave of button
	mov	ax, mask MRF_PROCESSED or mask MRF_CLEAR_POINTER_IMAGE
exit:						;Say processed if ptr in bounds
	ret
OLScrollbarEndPress	endp

endif	; _CUA_STYLE



COMMENT @----------------------------------------------------------------------

ROUTINE:	HandlePress

SYNOPSIS:	Handles a single press.  Can be called either by the user
		pressing or if the window is done redrawing and the user
		is still pressing.

CALLED BY:	OLScrollbarSelect, OLScrollbarWinUpdateComplete

PASS:		*ds:si -- handle of scrollbar
		cx, dx -- offset along width, length of scrollbar
		bp -- OLButtonFlags

RETURN:		nothing

DESTROYED:	ax,bx,cx,dx,di,bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
      		Nobody really handles Oregon State's press very well, and
		sadly, this routine is no exception.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	7/19/89		Initial version

------------------------------------------------------------------------------@

HandlePress	proc	near
	push	cx, dx, bp			;save mouse position
	call	DoScrollAction			;and do an action
	call	ShouldWeScroll?			;see if we need a timer    
	jz	10$				;nah, blow it off	   
	call	StartScrollbarTimer		;start a timer up
10$:
	pop	cx, dx, bp
	call	DrawIfNotXoring			;else update visual

if FLOATING_SCROLLERS
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER or mask OLSA_TWISTED
	jnz	afterUpdate

	mov	ax, MSG_SPEC_VIEW_UPDATE_FLOATING_SCROLLERS
	clr	cx				;don't close windows
	call	VisCallParent
afterUpdate:
endif
	ret
HandlePress	endp

			

COMMENT @----------------------------------------------------------------------

ROUTINE:	DrawIfNotXoring

SYNOPSIS:	Redraws things if we're not currently doing an xor.

CALLED BY:	RedrawAndRescroll

PASS:		ds:di -- scrollbar instance

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 6/90		Initial version

------------------------------------------------------------------------------@

DrawIfNotXoring	proc	near
if	_CUA_STYLE
	test	bp, mask BI_PRESS		;always draw on presses    
	jnz	10$							   
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR
	jne	exit				;xor drawn, don't redrar
10$:								   
endif
	call	OpenDrawObject
exit:
	ret
DrawIfNotXoring	endp
	

COMMENT @----------------------------------------------------------------------

ROUTINE:	ShouldWeScroll?

SYNOPSIS:	Figures out if we should scroll the window on this action.

CALLED BY:	RedrawAndRescroll

PASS:		*ds:si -- handle
		bp     -- mouse flags, apparently...

RETURN:		zero flag set if we shouldn't

DESTROYED:	di, ax, bp

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 6/90		Initial version

------------------------------------------------------------------------------@
	
ShouldWeScroll?	proc	near

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	al, ds:[di].OLSBI_state		;get current state
	and	al, mask OLSS_DOWN_FLAGS	;keep drawn down bits
	cmp	al, OLSS_DRAG_AREA		;in the drag area?
	jne	exit				;no, return true
	test	bp, mask BI_PRESS		;see if press
exit:
	ret
ShouldWeScroll?	endp


COMMENT @----------------------------------------------------------------------

ROUTINE:	StartScrollbarTimer

SYNOPSIS:	Starts a timer.

CALLED BY:	HandlePress
	
PASS:		*ds:si -- scrollbar handle	

RETURN:		nothing

DESTROYED:	cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 5/90		Initial version

------------------------------------------------------------------------------@

StartScrollbarTimer	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset

if (not _JEDIMOTIF) and (not _ODIE)
	test	ds:[di].OLSBI_attrs, mask OLSA_STUPID
	jnz	exit				;stupid, no timer please!
endif
	or	ds:[di].OLSBI_optFlags, mask OLSOF_REPEAT_SCROLL_PENDING \
				     or mask OLSOF_TIMER_EXPIRED_PENDING
	mov	dx, si				;now pass ^lcx:dx 10/29/90 cbh
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_OL_APP_STOP_TIMER
	call	GenCallApplication		;turn timer off, if any
	mov	dx, si
	mov	cx, ds:[LMBH_handle]
	clr	bp				;use standard system time
	mov	ax, MSG_OL_APP_START_TIMER
	call	GenCallApplication
exit::
	ret
StartScrollbarTimer	endp



COMMENT @----------------------------------------------------------------------

ROUTINE:	CancelScrollbarTimer

SYNOPSIS:	Cancels any timer that's currently going.

CALLED BY:	OLScrollbarSelect

PASS:		*ds:si -- scrollbar

RETURN:		nothing

DESTROYED:	di, ax

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	6/ 5/90		Initial version

------------------------------------------------------------------------------@
CancelScrollbarTimer	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_STUPID
	jnz	exit				;stupid, no timer please!
	test	ds:[di].OLSBI_optFlags, mask OLSOF_REPEAT_SCROLL_PENDING \
				     or mask OLSOF_TIMER_EXPIRED_PENDING
	jz	exit				;nothin' goin', branch
	and	ds:[di].OLSBI_optFlags, not (mask OLSOF_REPEAT_SCROLL_PENDING \
					  or mask OLSOF_TIMER_EXPIRED_PENDING)
	push	cx, dx, bp
	mov	dx, si				;now pass ^lcx:dx 10/29/90 cbh
	mov	cx, ds:[LMBH_handle]
	mov	ax, MSG_OL_APP_STOP_TIMER	;stop the timer if running
	call	GenCallApplication
	DoPop	bp, dx, cx
exit:
	ret
CancelScrollbarTimer	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoScrollCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	See what the mouse situation is.   Sees if mouse is pressed
		and figures out what was pressed on if so.

CALLED BY:	INTERNAL

PASS:		ds:di	-- pointer to specific instance data
		bp 	-- mouse information
		cx	-- mouse position along width of scrollbar
		dx 	-- mouse position along length of scrollbar

RETURN:		cx -- width offset of mouse click
		dx -- length offset
		al -- flag to store in OLSS_DOWN_FLAGS, or zero if nothing
		      selected.

DESTROYED:	nothing
		if SPINNER_GEN_VALUE
			ah
		endif

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _CUA

DoScrollCriteria	proc	near
	class	OLScrollbarClass
	
	push	bx, bp, cx, si			;save these
	;
	; Have bx hold the height of the arrow (as viewed vertically) and bx
	; holds the width.  Twisted scrollbars have these rotated.
	;
	clr	bx
	mov	bx, MO_ARROW_HEIGHT		;assume a normal scrollbar
	mov	bp, MO_SCROLLBAR_WIDTH
	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED
	jz	10$				;not twisted, branch
	xchg	bx, bp				;else rotate
10$:
	clr	al
	;
	; If the mouse is outside of the selectable area (the scrollbar plus
	; some extra leeway around it), exit with al = 0.
	;
	cmp	cx, -SCROLLBAR_LATITUDE
	jl	exit				;
	mov	si, bp				;si <- width + latitude
	add	si, SCROLLBAR_LATITUDE
	cmp	cx, si				;see if within width
	jg	exit
	mov	si, bx				;si <- (-height + latitude)
	add	si, SCROLLBAR_LATITUDE
	neg	si
	cmp	dx, si				;see if within height
	jl	exit
	;
	; If the mouse is in the leeway area, exit with al = OLSS_BOGUS,
	; indicating that nothing is selected.
	;
	mov	al, ds:[di].OLSBI_startState	;return current state
	and	al, mask OLSS_DOWN_FLAGS
	cmp	cx, MO_SCROLLBAR_WIDTH		;not in scrollbar, exit
	ja	exit
	mov	si, bx				;si <- (- arrowHeight)
	neg	si
	cmp	dx, si				;see if in up arrow
	jl	exit				;yes, we're done
	;
	; Start comparing the position to different parts of the scrollbar.
	;
	mov	al, OLSS_INC_UP			;assume in up arrow
	tst	dx				;in up arrow?
	js	exit				;yes, branch
	mov	cx,ds:[di].OLSBI_elevOffset	;get offset to thumb
	tst	cx
	jns	pageUp				;there's a thumb, branch
	clr	cx				;else clear cx
	jmp	downArrow			;and check down arrow
pageUp:
	mov	al, OLSS_PAGE_UP		;else assume in page up area
	cmp	dx, cx				;
	jb	exit				;yes, branch

	mov	al, OLSS_DRAG_AREA		;assume in drag area
	add	cx, MO_THUMB_HEIGHT		;in drag area?
	cmp	dx, cx
	jb	exit				;yes, branch

	mov	al, OLSS_PAGE_DOWN		;assume in lower page area
	mov	cx, ds:[di].OLSBI_scrArea	;get bottom of scroll area
	cmp	dx, cx				;see if in scroll area
	jbe	exit				;yes, branch
downArrow:
	mov	al, OLSS_INC_DOWN		;assume we're in down arrow
	mov	si, bx				;si <- arrowHeight - 1
	dec	si
	mov	cx, ds:[di].OLSBI_scrArea	;get bottom of scroll area
	tst	cx
	jns	90$
	clr	cx				;scroll area negative? branch.
90$:
	add	cx, si				;get to bottom of arrow
	cmp	dx, cx				;are we in the arrow?
	jbe	exit				;we are, exit

	mov	al, ds:[di].OLSBI_startState	;return current state
	and	al, mask OLSS_DOWN_FLAGS
	add	cx, SCROLLBAR_LATITUDE		;see if in scrollbar
	cmp	dx, cx
	jbe	exit				;we are, branch
	clr	al				;else we're nowhere

exit:
	pop	bx, bp, cx, si			;restore these
	ret
DoScrollCriteria	endp

endif	; _CUA_STYLE
		
		
if _MOTIF

DoScrollCriteria	proc	near
	class	OLScrollbarClass
if SPINNER_GEN_VALUE
	uses	bx, cx, bp
else
	uses	bx, cx, si, bp			; save these
endif
	.enter	

if FLOATING_SCROLLERS
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER or mask OLSA_TWISTED
	jnz	notFloater
	;
	;  Figure out whether we were clicked in the up-arrow or
	;  in the down-arrow.
	;
	call	FSDoScrollCriteria
	jmp	returnValueOK
notFloater:
endif
	;
	; Have bx hold the height of the arrow (as viewed vertically) and bp
	; holds the width.  Twisted scrollbars have these rotated.
	;
	mov	bx, ds:[di].OLSBI_arrowSize				    
	mov	bp, bx
if SPINNER_GEN_VALUE
	;
	; for vertical spinners, width is full width of the spinner
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SPINNER
	jz	notVSpinner
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	notVSpinner
	mov	bp, ds:[di].VI_bounds.R_right
	sub	bp, ds:[di].VI_bounds.R_left
	sub	bp, DRAW_STYLE_FRAME_WIDTH*2	; adjust for frame
	cmp	ds:[di].OLSBI_drawStyle, DS_FLAT
	je	notVSpinner
	sub	bp, DRAW_STYLE_INSET_WIDTH*2	; adjust for inset
notVSpinner:
endif

if not _PCV					; PCV's buttons are square
	add	bx, 2
endif

	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED
	jz	10$				;not twisted, branch
if _PCV
	;
	; PCV spin buttons (the "twisted" case) has left as down, right as up.
	;
	add	dx, bx				; add arrow size back in
	mov	al, OLSS_INC_UP			; default to up
	cmp	dx, PCV_SPIN_BUTTONS_WIDTH/2
	jge	gotUpOrDown
	mov	al, OLSS_INC_DOWN
gotUpOrDown:
	sub	dx, bx				; fix up again
	jmp	returnValueOK
else
	xchg	bx, bp				;else rotate
endif
10$:

if SPINNER_GEN_VALUE
	push	si				; save scrollbar
endif

	clr	al
	inc	dx				;make relative to bottom of 
						;  up arrow, temporarily
	;
	; If the mouse is outside of the selectable area (the scrollbar plus
	; some extra leeway around it), exit with al = 0.
	;
	cmp	cx, -SCROLLBAR_LATITUDE
	jl	exit				;
	mov	si, bp				;si <- width + latitude
	add	si, SCROLLBAR_LATITUDE
	cmp	cx, si				;see if within width
	jg	exit
	mov	si, bx				;si <- (-height + latitude)
	add	si, SCROLLBAR_LATITUDE
	neg	si
	cmp	dx, si				;see if within height
	jl	exit
	;
	; If the mouse is in the leeway area, exit with al = OLSS_BOGUS,
	; indicating that nothing is selected.
	;
	; Start comparing the position to different parts of the scrollbar.
	;
	mov	al, OLSS_INC_UP			;assume in up arrow
	tst	dx				;in up arrow?
	js	exit				;yes, branch
	tst	dx				;if in grey area between up
	jz	30$				;  arrow and scroll area, don't
						;  decrement back -- treat
						;  as in scroll area
	dec	dx				;make relative to start of 
30$:						;  scroll area from now on
	mov	cx,ds:[di].OLSBI_elevOffset	;get offset to thumb
	tst	cx
	jns	pageUp				;there's a thumb, branch
	clr	cx				;else clear cx

	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED
	jz	pageDown			;not twisted, check for page
						;  down (nothing happens if so)
	jmp	short incDown			;twisted, skip page-down.

pageUp:
	mov	al, OLSS_PAGE_UP		;else assume in page up area
	cmp	dx, cx				;
	jb	exit				;yes, branch

	mov	al, OLSS_DRAG_AREA		;assume in drag area
	add	cx, ds:[di].OLSBI_elevLen	;see if in drag area
	cmp	dx, cx
	jb	exit				;yes, branch

pageDown:
	mov	al, OLSS_PAGE_DOWN		;assume in lower page area
	mov	cx, ds:[di].OLSBI_scrArea	;get bottom of scroll area
if _JEDIMOTIF
	tst	cx
	js	incDown
endif
	cmp	dx, cx				;see if in scroll area
	jbe	exit				;yes, branch

incDown:
	mov	al, OLSS_INC_DOWN		;assume we're in down arrow
	mov	si, bx				;si <- arrowHeight + 1
	mov	cx, ds:[di].OLSBI_scrArea	;get bottom of scroll area
	tst	cx
	jns	90$
	clr	cx				;scroll area negative? branch.
90$:
	add	cx, si				;get to bottom of arrow
	cmp	dx, cx				;are we in the arrow?
	jbe	exit				;we are, exit
	
	add	cx, SCROLLBAR_LATITUDE		;see if in scrollbar
	cmp	dx, cx
	jbe	exit				;we are, branch
	clr	al				;else we're nowhere

exit:
if SPINNER_GEN_VALUE
	;
	; if we are a spinner, only allow inc-up and inc-down
	;
	pop	si				; *ds:si = scrollbar
	test	ds:[di].OLSBI_attrs, mask OLSA_SPINNER
	jz	notSpinner
	cmp	al, OLSS_INC_UP
	je	checkSpinnerAction
	cmp	al, OLSS_INC_DOWN
	jne	returnNoSpinnerAction
checkSpinnerAction:
	call	CheckSpinnerAtEnd
	jne	returnValueOK
returnNoSpinnerAction:
	clr	al
	jmp	short returnValueOK

notSpinner:
endif
	;
	; If there's no thumb, and we pressed in the page area, let's forget
	; about doing anything.   -cbh 2/26/93
	;
	tst	ds:[di].OLSBI_elevOffset	;see if there's a thumb
	jns	returnValueOK
	cmp	al, OLSS_PAGE_DOWN
	jne	returnValueOK
	clr	al				

returnValueOK:
	.leave
	ret
DoScrollCriteria	endp

endif	; _MOTIF

if _PM	;START of PM specific code -----

DoScrollCriteria	proc	near
	class	OLScrollbarClass
	
	push	bx, bp, cx, si			;save these
	;
	; Have bx hold the height of the arrow (as viewed vertically) and bp
	; holds the width.  Twisted scrollbars have these rotated.
	;
	mov	bx, MO_ARROW_HEIGHT		;assume a normal scrollbar
	mov	bp, MO_ARROW_WIDTH+1
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL ;see if horizontal
	jnz	5$				;no, branch
	call	OpenMinimizeIfCGA		;check if on CGA
	jnc	5$				;no, branch
	sub	bp, MO_ARROW_WIDTH - CGA_HORIZ_ARROW_WIDTH
5$:
	test	ds:[di].OLSBI_attrs, mask OLSA_TWISTED
	jz	10$				;not twisted, branch
	mov	bx, PM_SPIN_ARROW_HEIGHT+2
	inc	bp				;SPIN_ARROW is 1 pixel wider
	
10$:
	mov	al, OLSS_DRAG_AREA
	inc	dx				;make relative to bottom of 
						;  up arrow, temporarily
	;
	; If the mouse is outside of the selectable area,
	; exit with al = OLSS_DRAG_AREA.
	;
	tst	cx
	jl	exit				;
	cmp	cx, bp				;see if within width
	jg	exit
	mov	si, bx				;si <- (-height)
	neg	si
	cmp	dx, si				;see if within height
	jl	exit
	
	;
	; Start comparing the position to different parts of the scrollbar.
	;
	mov	al, OLSS_INC_UP			;assume in up arrow
	tst	dx				;in up arrow?
	js	exit				;yes, branch
	tst	dx				;if in grey area between up
	jz	30$				;  arrow and scroll area, don't
						;  decrement back -- treat
						;  as in scroll area
	dec	dx				;make relative to start of 
30$:						;  scroll area from now on
	mov	cx,ds:[di].OLSBI_elevOffset	;get offset to thumb
	tst	cx
	jns	pageUp				;there's a thumb, branch
	clr	cx				;else clear cx
	jmp	downArrow			;and check down arrow
pageUp:
	mov	al, OLSS_PAGE_UP		;else assume in page up area
	cmp	dx, cx				;
	jb	exit				;yes, branch

	mov	al, OLSS_DRAG_AREA		;assume in drag area
	add	cx, ds:[di].OLSBI_elevLen	;see if in drag area
	cmp	dx, cx
	jb	exit				;yes, branch

	mov	al, OLSS_PAGE_DOWN		;assume in lower page area
	mov	cx, ds:[di].OLSBI_scrArea	;get bottom of scroll area
	cmp	dx, cx				;see if in scroll area
	jbe	exit				;yes, branch
downArrow:
	mov	al, OLSS_INC_DOWN		;assume we're in down arrow
	mov	si, bx				;si <- arrowHeight + 1
	mov	cx, ds:[di].OLSBI_scrArea	;get bottom of scroll area
	tst	cx
	jns	90$
	clr	cx				;scroll area negative? branch.
90$:
	add	cx, si				;get to bottom of arrow
	cmp	dx, cx				;are we in the arrow?
	jbe	exit				;we are, exit

	mov	al, OLSS_DRAG_AREA

exit:
	pop	bx, bp, cx, si			;restore these
	ret
DoScrollCriteria	endp

endif		;END of PM specific code --------------------


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CheckSpinnerAtEnd
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	check if spinner is at either end of range

CALLED BY:	INTERNAL
			DoScrollCriteria
PASS:		*ds:si = scrollbar (spinner)
		ds:di = scrollbar spec instance
		al = DownFlags
			OLSS_INC_UP
			OLSS_INC_DOWN
RETURN:		Z set if at end of range
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	brianc	8/27/96    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if SPINNER_GEN_VALUE

CheckSpinnerAtEnd	proc	near
	uses	ax, bx, cx, dx, bp, di
	.enter
	mov	ah, ds:[di].OLSBI_attrs.low
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	cmp	al, OLSS_INC_UP
	movdw	cxdx, ds:[di].GVLI_maximum
	movdw	bxbp, ds:[di].GVLI_minimum
	je	checkSpinnerValue
EC <	cmp	al, OLSS_INC_DOWN					>
EC <	ERROR_NE	OL_ERROR					>
	movdw	cxdx, ds:[di].GVLI_minimum
	movdw	bxbp, ds:[di].GVLI_maximum
checkSpinnerValue:
	test	ah, mask OLSA_VERTICAL
	jnz	haveEndValue
	movdw	cxdx, bxbp			; else, get other end
haveEndValue:
	cmpdw	cxdx, ds:[di].GVLI_value
	.leave
	ret
CheckSpinnerAtEnd	endp

endif ; SPINNER_GEN_VALUE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		FSDoScrollCriteria
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do scroll criteria for floating scrollers.

CALLED BY:	DoScrollCriteria

PASS:		ds:di	-- pointer to specific instance data
		*ds:si	-- scroller object
		bp 	-- mouse information
		cx	-- mouse position along width of scrollbar
		dx 	-- mouse position along length of scrollbar

		cx & dx were the original mouse coords passed into
		MSG_META_{START/END}_SELECT, but swapped if horizontal
		before entering this routine.

RETURN:		cx -- width offset of mouse click
		dx -- length offset
		al -- flag to store in OLSS_DOWN_FLAGS, or zero if nothing
		      selected.

PSEUDO CODE/STRATEGY:

	We do our criteria based on the type of region we're displaying:

		up-arrow only:	click goes in inc area
		dn-arrow only:	click goes in dec area
		both arrows:	use 50% of height for dividing line

	To determine which region is set, we use:

		* OLSS_AT_TOP:		dn-arrow region
		* OLSS_AT_BOTTOM:	up-arrow region
		* neither bit set:	up/dn-arrow region
		* both bits set:	empty (null) region

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	stevey	5/20/96		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if FLOATING_SCROLLERS

FSDoScrollCriteria	proc	near
		uses	bx, cx, dx
		.enter
	;
	;  If both are set, we return OLSS_BOGUS, since we shouldn't
	;  be getting any presses.
	;
		mov	al, OLSS_BOGUS
		mov	bl, ds:[di].OLSBI_state
		andnf	bl, mask OLSS_AT_BOTTOM or mask OLSS_AT_TOP
		cmp	bl, mask OLSS_AT_BOTTOM or mask OLSS_AT_TOP
		je	done
	;
	;  If OLSS_AT_TOP is set, we're displaying only a down-arrow,
	;  so we must've got a press in the down-arrow region.
	;
		mov	al, OLSS_INC_DOWN	; assume down-arrow
		test	bl, mask OLSS_AT_TOP	; at top?
		jnz	done			; yes, 'twas down-arrow

		mov	al, OLSS_INC_UP		; assume up-arrow
		test	bl, mask OLSS_AT_BOTTOM	; at bottom?
		jnz	done			; yep, 'twas up-arrow
	;
	; If we were pressing down on something, just keep doing it.
	;
		mov	al, ds:[di].OLSBI_state
		andnf	al, mask OLSS_DOWN_FLAGS
		jnz	done
	;
	;  OK, the hard one:  we're showing both arrows.  If the press
	;  was in the top 50% of our height (width for horizontal),
	;  it's the up-arrow.
	;
		mov	bx, dx			; bx = mouse Y coord
		call	VisGetSize		; cx = width, dx = height
		call	SwapIfHorizontal
		shr	dx			; dx = 50% of distance
		mov	al, OLSS_INC_DOWN
		cmp	bx, dx
		jae	done
		mov	al, OLSS_INC_UP		; pressed in top half
done:
		.leave
		ret
FSDoScrollCriteria	endp

endif	; FLOATING_SCROLLERS


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoScrollAction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Takes action if the mouse is down.   Actions differ
		depending on who was pressed.

CALLED BY:	INTERNAL

PASS:		*ds:si -- pointer to specific instance data
		bp     -- button state flags
		dx     -- mouse offset into scroll area

RETURN:		nothing

DESTROYED:	ax, bx, cx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoScrollAction	proc	near
	class	OLScrollbarClass
	
	push	bp				;save button flags
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	mov	bl, ds:[di].OLSBI_state		;get the current state
	and	bl, mask OLSS_DOWN_FLAGS 	;see if any presses
	jz	exit				;nothing down, exit

	;
	; Hack up the message to pass to depend on the action taken.
	;
	clr	bh				;now in bx
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	push	ds:[di].GVLI_applyMsg		;get base method
	dec	bx				;make RangeUserActionOffsets
	add	ds:[di].GVLI_applyMsg, bx	;add offset to base method
	inc	bx				;restore bx
	
	push	dx				;save offset into bar length
	shl	bl, 1				;double for word offset
	pop	di				;pass mouse offset in di
	call	cs:actionTab[bx]-2		;and call the right routine

	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	pop	ds:[di].GVLI_applyMsg		;restore apply message
exit:
	pop	bp				;restore button flags
	ret
DoScrollAction	endp

;
; Table of actions to take, based on OLSBI_state
;
actionTab	word	offset DoBegAnchor		;BEG_ANCHOR
		word	offset DoPageUp			;PAGE_UP
		word	offset DoIncUp			;INC_UP
		word	offset DoDragArea		;DRAG_AREA
		word	offset DoIncDown		;INC_DOWN
		word	offset DoPageDown		;PAGE_DOWN
		word	offset DoEndAnchor		;END_ANCHOR


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoIncDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Does an incremental downward scroll.

CALLED BY:	INTERNAL

PASS:		*ds:si -- pointer to specific instance data
		bp --	button state flags

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/13/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoIncDown	proc	near
	class	OLScrollbarClass

if _JEDIMOTIF
	;
	; position at click
	;
	call	SetIfSlider
	jc	done
endif

	mov	ax, MSG_GEN_VALUE_INCREMENT
	call	ValueSendMsg
done::
	ret    

DoIncDown	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoIncUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handles incrementing up scrollbar.

CALLED BY:	DoScrollbarAction

PASS:		*ds:si -- scrollbar
		bp -- button state flags

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoIncUp	proc	near
	class	OLScrollbarClass

if _JEDIMOTIF
	;
	; position at click
	;
	call	SetIfSlider
	jnc	notSlider
	ret
notSlider:
endif

	mov	ax, MSG_GEN_VALUE_DECREMENT
	FALL_THRU	ValueSendMsg
	
DoIncUp	endp

ValueSendMsg	proc	near
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	or	ds:[di].OLSBI_attrs, mask OLSA_SUPPRESS_DRAW
	mov	bx, si				;pass non-zero: is scrollbar
	call	SendMsgSetModifiedAndApplyIfNeeded
	ret
ValueSendMsg	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPageDown
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pages down the scrollbar.

CALLED BY:	DoScrollAction

PASS:		*ds:si -- scrollbar
		bp -- button state flags
		dx --   current docOffset

RETURN:		dx -- new docOffset
		carry set if normalizing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoPageDown	proc	near
	class	OLScrollbarClass

if _JEDIMOTIF
	;
	; position at click
	;
	call	SetIfSlider
	jc	done
endif

	mov	ax, MSG_GEN_VALUE_ADD_RANGE_LENGTH
	call	ValueSendMsg
done::
	ret

DoPageDown	endp

if _JEDIMOTIF
SetIfSlider	proc	near
	uses	cx, dx, bp
	.enter
	;
	; check if slider
	;
	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	done				; carry clear
	;
	; set value based on click position
	;
	clr	cx				; dx.cx = mouseOffset
						; (mouse offset is integer)
	
	mov	bx, ds:[di].OLSBI_scrArea	; get length of scroll area
	
	sub	bx, ds:[di].OLSBI_elevLen

	cmp	dx, bx				; see if over maximum
	jbe	divide				; no, branch
	mov	dx, bx				; else use maximum   
divide:
	clr	ax				; offset into scr area in bx.ax
	call	GrUDivWWFixed			; divide, fraction in dx.cx 

	;
	; On read-only, vertical scrollbars, we'll assume we're a gauge and
	; invert the ratio, so as to allow the measurement to take place from
	; the bottom of the gauge.
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	notVertical
	movdw	bxax, dxcx
	mov	dx, 1				; read-only, subtract from 1.0
	mov	cx, 0				;  so stuff is displayed
	subdw	dxcx, bxax
notVertical:

	tst	dx				; dx.cx > 1.0?
	jz	20$				; no, branch
	clr	cx
	mov	dx, 1				; else pass 1.0
20$:
	;
	; update ourselves and tell output (actual GenValue) to set its
	; value
	;
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	mov	ax, MSG_SPEC_SPIN_VALUE_CHANGED
	xchg	ds:[di].GVLI_applyMsg, ax	; set apply msg to set value
	push	ax
	mov	ax, MSG_GEN_VALUE_SET_VALUE_FROM_RATIO
	mov	bp, GVT_VALUE_AS_RATIO_OF_AVAILABLE_RANGE
	call	ValueSendMsg
	mov	di, ds:[si]
	add	di, ds:[di].Gen_offset
	pop	ds:[di].GVLI_applyMsg		; restore apply message
	stc
done:
	.leave
	ret
SetIfSlider	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoPageUp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Pages up the scrollbar.

CALLED BY:	DoScrollAction

PASS:		*ds:si -- scrollbar
		bp -- button state flags

RETURN:		nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoPageUp	proc	near
	class	OLScrollbarClass

if _JEDIMOTIF
	;
	; position at click
	;
	call	SetIfSlider
	jc	done
endif

	mov	ax, MSG_GEN_VALUE_SUBTRACT_RANGE_LENGTH
	call	ValueSendMsg
done::
	ret
DoPageUp	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoEndAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Moves to end of document.  Does nothing in motif.

CALLED BY:	DoScrollAction

PASS:		*ds:si -- scrollbar
		bp -- button state flags

RETURNED:	nothing

DESTROYED:	ax, bx, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoEndAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to start of scrollbar.   Does nothing in motif.

CALLED BY:	GLOBAL

PASS:		*ds:si -- scrollbar
		bp -- button state flags
		dx --   current docOffset

DESTROYED:	ax, bx, di

RETURNED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoEndAnchor	proc	near
	ret
DoEndAnchor	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoBegAnchor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Goes to start of scrollbar.   Does nothing in motif.

CALLED BY:	GLOBAL

PASS:		*ds:si -- scrollbar
		bp -- button state flags
		dx --   current docOffset

DESTROYED:	ax, bx, di

RETURNED:	nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoBegAnchor	proc	near
       	ret
DoBegAnchor	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DoDragArea
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Drags the document to new location.

CALLED BY:	DoScrollAction

PASS:		*ds:si -- scrollbar
		bp    -- button state flags
		di    -- mouse position along length of scrollbar

RETURN:		nothing

DESTROYED:	ax, bx, cx, di

PSEUDO CODE/STRATEGY:
       	     if ptr event
		subtract offset to first click to get place for elevator
		ratio = (yPos-top-NON_SCR_LEN)/scrArea-ELEV_HEIGHT

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	12/15/88	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DoDragArea	proc	near
	class	OLScrollbarClass
	
CUAS <	push	cx, dx			     ;save old position	         >
   
	test	bp, mask BI_PRESS		
	jnz	short exit		     ;exit if this is a press

	mov	bx, di			     ;mouse offset in bx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	sub	bx, ds:[di].OLSBI_clickYOff  ;make relative to top of elevator
	tst	bx
	jns	10$			     ;if negative already, set to zero
	clr	bx
10$:
	mov	dx, bx			     ;dx.cx = mouseOffset
	clr	cx		             ;  (mouse offset is integer)
	
	mov	bx, ds:[di].OLSBI_scrArea    ;get length of scroll area
	
CUA <	sub 	bx, MO_THUMB_HEIGHT					   >
MO <	sub	bx, ds:[di].OLSBI_elevLen    				   >
PMAN <	sub	bx, ds:[di].OLSBI_elevLen    				   >

	cmp	dx, bx			     ;see if over maximum
	jbe	divide			     ;no, branch
	mov	dx, bx			     ;else use maximum   
divide:
	clr	ax			     ;offset into scr area in bx.ax
	call	GrUDivWWFixed		     ;divide, fraction in dx.cx 

	;
	; On read-only, vertical scrollbars, we'll assume we're a gauge and
	; invert the ratio, so as to allow the measurement to take place from
	; the bottom of the gauge.
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	notSlider
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	notSlider
	movdw	bxax, dxcx
	mov	dx, 1				;read-only, subtract from 1.0
	mov	cx, 0				;  so stuff is displayed
	subdw	dxcx, bxax
notSlider:

	tst	dx			     ;dx.cx > 1.0?
	jz	20$			     ;no, branch
	clr	cx
	mov	dx, 1			     ;else pass 1.0
20$:
normalize:
	
if	_CUA_STYLE ;--------------------------------------------------------

	call	HandleDragXor		     ;else re-do the xor region.   

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_UPDATE_DURING_DRAGS
	jz	exit
	call	FinishDrag
exit:
	pop	cx, dx			     ;we won't change doc offset here
	clc				     ;no normalizing
endif ;----------------------------------------------------------------------
	
	ret
	
DoDragArea	endp

		
		

COMMENT @----------------------------------------------------------------------

ROUTINE:	FinishDrag

SYNOPSIS:	Finishes dragging.

CALLED BY:	OLScrollbarSelect

PASS:		*ds:si -- handle
		bp     -- flags

RETURN:		carry set if we were dragging

DESTROYED:	ax, cx, dx, bp, di

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/90		Initial version

------------------------------------------------------------------------------@

if	_CUA_STYLE
	
FinishDrag	proc	near
	uses	ax, cx, dx, bp
	.enter

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR
	clc					;assume nothing been done
	je	exit				;nope, branch

	push	cx
	call	XorElevator			;erase elevator
	pop	cx
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR
	;
	; Clear this now.
	;
	and	ds:[di].OLSBI_state, not (mask OLSS_DOWN_FLAGS)

	;
	; A bunch of stuff need not be done when constantly updating.
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_UPDATE_DURING_DRAGS
	jnz	setValue			

	;
	; If we originally started dragging, and we're no longer in the
	; scroll area, let's get out.  Otherwise, let's send a scroll method
	; to the port, who will later call back to us.
	;
	cmp	ds:[di].OLSBI_startState, OLSS_DRAG_AREA
	jne	invalImage			;not in drag area, branch
	call	DoScrollCriteria		;see where mouse is
	tst	al				;not in scrollbar, exit now
	jz	exitDragged

invalImage:
	;
	; Hack up the message to cause a drag to occur.
	;
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	push	ds:[di].GVLI_applyMsg		;get base method
	add	ds:[di].GVLI_applyMsg, OLSS_DRAG_AREA-1

setValue:
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	movdw	dxcx, ds:[di].OLSBI_xorDocRatio
	or	ds:[di].OLSBI_attrs, mask OLSA_SUPPRESS_DRAW
	mov	bp, GVT_VALUE_AS_RATIO_OF_AVAILABLE_RANGE
	mov	ax, MSG_GEN_VALUE_SET_VALUE_FROM_RATIO
	call	ValueSendMsg

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_UPDATE_DURING_DRAGS
	jnz	exitDragged
	mov	di, ds:[si]			
	add	di, ds:[di].Gen_offset
	pop	ds:[di].GVLI_applyMsg		;restore apply message
	
exitDragged:
	stc					;say we draggedp
exit:
	.leave
	ret
FinishDrag	endp

endif


COMMENT @----------------------------------------------------------------------

ROUTINE:	HandleDragXor

SYNOPSIS:	Handles the xor region when a-draggin.

CALLED BY:	DoDragArea

PASS:		*ds:si -- scrollbar handle
		dx:cx     -- new scrollbar ratio

RETURN:		nothing

DESTROYED:	ax, cx, di

PSEUDO CODE/STRATEGY:
       	        if (not press) or (dx <> docOffset)
       		        XorElevator()
		if this is a non-button event
			xorElevOff = CalcElevPos (dx)
			XorElevator()

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/90		Initial version

------------------------------------------------------------------------------@

if	_CUA_STYLE
	
HandleDragXor	proc	near		uses dx
	.enter
	;
	; Erase the previous xor rectangle, if there was one and it is moving.
	;
	test	bp, mask BI_PRESS		;if press skip next test
	jnz	short 10$
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	cmp	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR
	je	10$				;no xor region now, must xor
	cmpdw	dxcx, ds:[di].OLSBI_xorDocRatio
	je	exit				;no change, exit
10$:
	push	cx
	call	XorElevator			;start initial xor rect,
	pop	cx				; or remove old xor rect.
20$:						
	;
	; Draw a new xor rectangle, if this is not a press.
	;
	test	bp, mask BI_PRESS		;exit if this is a press
	jnz	short exit
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	movdw	ds:[di].OLSBI_xorDocRatio, dxcx
	call	CalcElevPos			;find a new position
	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	mov	ds:[di].OLSBI_xorElevOff, ax	;save it.
	call	XorElevator			;draw the new rectangle.
exit:	
	.leave
	ret
HandleDragXor	endp

endif
	

COMMENT @----------------------------------------------------------------------

ROUTINE:	XorElevator

SYNOPSIS:	Draws a new xor-ed rectangle.

CALLED BY:	HandleDragXor

PASS:		*ds:si -- scrollbar

RETURN:		nothing

DESTROYED:	ax, cx

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Chris	4/11/90		Initial version

------------------------------------------------------------------------------@

if	_CUA_STYLE
	
XorElevator	proc	near
	uses bx, dx, bp, di
	.enter

	mov	di, ds:[si]			
	add	di, ds:[di].Vis_offset
	test	ds:[di].OLSBI_attrs, mask OLSA_UPDATE_DURING_DRAGS
	LONG jnz done				;constantly updating, forget it

	cmp	ds:[di].OLSBI_xorElevOff, NO_XOR_ELEVATOR
	LONG je	done				;nothing to erase, branch
	call	ViewCreateDrawGState		;get a new gstate

	tst	di				;if no window, can't draw to it
	LONG jz	done

	;
	; Choose color to xor with.  In color, we'll use C_LIGHT_GREY because it
	; changes lt-grey to black, dk-grey to white, making the xor region
	; stand out better.  In B/W we'll use white.
	;
MO <	mov	di, C_LIGHT_GREY		;lt-grey to black, dk-grey to >
PMAN <	mov	di, C_LIGHT_GREY		;lt-grey to black, dk-grey to >

MO <	push	ds							>
MO <	mov	ax, segment dgroup					>
MO <	mov	ds, ax							>
MO <	test	ds:[moCS_flags], mask CSF_BW				>
MO <	pop	ds							>

MO <	jz	setColor			;color, branch		      >
	mov	di, C_WHITE			;use white in B/W
MO <setColor:								      >

PMAN <	push	ds							>
PMAN <	mov	ax, segment dgroup					>
PMAN <	mov	ds, ax							>
PMAN <	test	ds:[moCS_flags], mask CSF_BW				>
PMAN <	pop	ds							>

PMAN <	jz	setColor			;color, branch		      >
	mov	di, C_WHITE			;use white in B/W
PMAN <setColor:								      >

	mov	ax, di				;ax <- color
	mov	di, bp				;di <- gstate
	call	GrSetLineColor			;set xor color
if	 _ROUNDED_SCROLL_BAR_THUMB
	call	GrSetAreaColor
endif	;_ROUNDED_SCROLL_BAR_THUMB
	
	mov	al, SDM_50			;draw in 50% pattern
	call	GrSetLineMask
if	 _ROUNDED_SCROLL_BAR_THUMB
	call	GrSetAreaMask
endif	;_ROUNDED_SCROLL_BAR_THUMB
	
	mov	al, MM_XOR			;xor
	call	GrSetMixMode
	call	OpenGetLineBounds		;get scrollbar bounds for lines
	mov	di, ds:[si]			;point to instance
	add	di, ds:[di].Vis_offset		;ds:[di] -- SpecInstance
	test	ds:[di].OLSBI_attrs, mask OLSA_VERTICAL
	jz	horiz				;not vertical, branch
;vert:
	add	bx, ds:[di].OLSBI_xorElevOff	;get xor elevator offset

if SLIDER_INCLUDES_VALUES
	;
	; no arrow for gauges only
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	haveArrow
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jnz	noMargin
haveArrow:
else
MO <	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER		>
MO <	jnz	noMargin					>
endif

NOT_MO<	add	bx, MO_SCR_AREA_MARGIN		;add arrow height for thumb top>
PMAN<	add	bx, MO_SCR_AREA_MARGIN		;add arrow height for thumb top>
MO<	add	bx, ds:[di].OLSBI_arrowSize				       >

if	_MOTIF
ARROWSHADOW   <	add	bx, 3						>
NOARROWSHADOW <	add	bx, 2						>
endif	;_MOTIF

noMargin:

	mov	dx, bx				;dx <- bottom of elevator
MO <	add	dx, ds:[di].OLSBI_elevLen				     >
PMAN <	add	dx, ds:[di].OLSBI_elevLen				     >
NOT_MO<	add	dx, MO_THUMB_HEIGHT					     >
	dec	dx

if _JEDIMOTIF
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	notVSlider
	sub	cx, 2				;random JEDI slider adjustment
notVSlider:
endif

if	 _ROUNDED_SCROLL_BAR_THUMB
	; If the size of the scrollbar is greater than the minimum size,
	; then set si to the offset of the outline region for the rounded
	; scroll bar, otherwise, clear si which indicates that we should
	; draw a rectangle.
	
	inc	ax
	inc	dx				; account for what would be
	inc	dx				; the shaded area
	
	push	si				; popped by drawing code
	
	; Get SBRegionStruct for the vertical scrollbar/slider thumb
	push	di
	mov	di, offset vsbThumb+2
	mov	si, dx
	sub	si, bx				; si = height of thumb
	cmp	si, cs:[di].SBRS_minimumSize
	mov	si, 0				; don't affect flags
	jl	notVRound
	mov	si, cs:[di].SBRS_xorRegOffset

notVRound:
	pop	di
endif	;_ROUNDED_SCROLL_BAR_THUMB

	jmp	short draw
horiz:
	add	ax, ds:[di].OLSBI_xorElevOff	

if SLIDER_INCLUDES_VALUES
	;
	; no arrow for gauges only
	;
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	haveHArrow
	test	ds:[di].OLSBI_attrs, mask OLSA_READ_ONLY
	jnz	noHMargin
haveHArrow:
else
MO <	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER			>
MO <	jnz	noHMargin						>
endif

NOT_MO<	add	ax, MO_SCR_AREA_MARGIN		;add arrow height for thumb top>
PMAN<	add	ax, MO_SCR_AREA_MARGIN		;add arrow height for thumb top>
MO<	add	ax, ds:[di].OLSBI_arrowSize				       >

if	_MOTIF
ARROWSHADOW   <	add	ax, 3						>
NOARROWSHADOW <	add	ax, 2						>
endif	;_MOTIF

noHMargin:

	mov	cx, ax
MO <	add	cx, ds:[di].OLSBI_elevLen				    >
PMAN <	add	cx, ds:[di].OLSBI_elevLen				    >
NOT_MO<	add	cx, MO_THUMB_HEIGHT					    >
	dec	cx
if _JEDIMOTIF
	test	ds:[di].OLSBI_attrs, mask OLSA_SLIDER
	jz	notHSlider
	sub	dx, 3				;random JEDI slider adjustment
notHSlider:
endif

if	 _ROUNDED_SCROLL_BAR_THUMB
	; If the size of the scrollbar is greater than the minimum size,
	; then set si to the offset of the outline region for the rounded
	; scroll bar, otherwise, clear si which indicates that we should
	; draw a rectangle.
	
	inc	bx
	inc	cx				; account for what would be
	inc	cx				; the shaded area
	
	push	si				; popped by drawing code
	
	; Get SBRegionStruct for the horizontal scrollbar/slider thumb
	push	di
	mov	di, offset hsbThumb+2
	mov	si, cx
	sub	si, ax				; si = width of thumb
	cmp	si, cs:[di].SBRS_minimumSize
	mov	si, 0				; don't affect flags
	jl	notHRound
	mov	si, cs:[di].SBRS_xorRegOffset

notHRound:
	pop	di
endif	;_ROUNDED_SCROLL_BAR_THUMB

draw:
	
if	 _ROUNDED_SCROLL_BAR_THUMB
	; No round scrollbars under 10 pixels.. sorry.
	cmp	ds:[di].OLSBI_arrowSize, 10
	mov	di, bp				;di <- gstate
	jl	drawRect
	
	tst	si				; just draw rectangles?
	jz	drawRect			; yup
	
	push	ds

NOFXIP<	segmov	ds, cs							>

FXIP <	push	ax, bx							>
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemLock							>
FXIP <	mov	ds, ax							>
FXIP <	pop	ax, bx							>

	; round thumbs are inset a bit.
	sub	dx, bx				; cx = width, dx = height
	sub	cx, ax				; for the region
	call	GrDrawRegion

	; BX destroyed in FXIP only
FXIP <	mov	bx, handle DrawBWRegions				>
FXIP <	call	MemUnlock						>

	pop	ds
	jmp	afterInset

drawRect:
	; We need to adjust the right nad bottom coordinates so the
	; rectangle draws within the correct area.
	dec	cx
	dec	dx
else	;_ROUNDED_SCROLL_BAR_THUMB is FALSE
	mov	di, bp				;di <- gstate
endif	;_ROUNDED_SCROLL_BAR_THUMB
	
	call	GrDrawRect

if	_MOTIF
	;
	; Draw a second, inset rectangle so things show up better.
	;
	inc	ax
	inc	bx
	dec	cx
	dec	dx

	call	GrDrawRect

endif

if	 _ROUNDED_SCROLL_BAR_THUMB
afterInset:
	pop	si				; restore myself. :)
endif	;_ROUNDED_SCROLL_BAR_THUMB

	call	GrDestroyState			;destroy the gstate.

done:
	.leave
	ret
XorElevator	endp

endif	; _CUA_STYLE


ScrollbarCommon 	ends

