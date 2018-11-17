COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1992 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/Main
FILE:		mainGeometry.asm

AUTHOR:		Don Reeves, May  1, 1992

ROUTINES:
	Name			Description
	----			-----------
    INT UpdateViewInfo		Update the ViewInfo

    INT ViewMakeVisible		Make the correct view(s), etc. visible.

 ?? INT ViewSwapUsable		Set one generic tree usable, another not
				usable

    GLB ViewGrabFocusAndTarget	Grab the focus exclusive of the proper view

    GLB ViewSendMessage		Grab the focus exclusive of the proper view

    GLB ObjMessage_geometry_send_menu
				Grab the focus exclusive of the proper view

    GLB ObjMessage_geometry_send
				Grab the focus exclusive of the proper view

 ?? INT ChangeEventViewMoniker	Changes the EventView's title.  When we
				change view, we change the EventView's
				title here instead of in DP_SET_RANGE
				because of the delay.

 ?? INT ClearEventViewMoniker	Changes EventView title to be of the
				form--Mon 03.06.96.

    EXT PutWeekday		Puts the abbreviated weekday string as the
				title for the EventView (e.g. "Fri" in "Fri"
				96.04.12).

 ?? INT TodoListTitle		Changes title of EventView to the To-do
				list string and bitmap.

 ?? INT GetDateCurrentlyShown	Returns the date that the user has selected

 ?? INT EventViewChangeTitleCommon
				Changes EventView's title moniker

 ?? INT ChangeHelpContext	Changes CalendarRight's help context
				depending on whether CalendarRight is the
				event view or to-do view.

 ?? INT ECCheckViewInfo		Validates the global variable view info for
				Responder Calendar.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 1/92		Initial revision

DESCRIPTION:
	Contains code to manage the geometry of the GeoPlanner application	

	$Id: mainGeometry.asm,v 1.1 97/04/04 14:48:12 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeControlInit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the window management of the SizeControlClass

CALLED BY:	GLOBAL (MSG_SIZE_CONTROL_INIT)

PASS:		ES	= DGroup
		*DS:SI	= SizeControlClass object
		DS:DI	= SizeControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/18/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SizeControlInit	method dynamic	SizeControlClass, MSG_SIZE_CONTROL_INIT
	.enter

	; Determine if we are pen based or not. If so, enable some stuff.
	;
	andnf	es:[viewInfo], not (mask VI_PEN_MODE)
	call	SysGetPenMode			; pen Boolean => AX
	tst	ax				; are we pen-based ??
	jz	done				; nope, so we're done
if _USE_INK
	ornf	es:[viewInfo], mask VI_PEN_MODE

	; Set the ink controls in the Edit menu usable
	;
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	GetResourceHandleNS	MenuBlock, bx
	mov	si, offset MenuBlock:EditInkControl
	call	ObjMessage_init_send

	; Enable Window->Ink trigger, and default to ink view
	;
	mov	si, offset MenuBlock:ViewInkList
	call	ObjMessage_init_send
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	cx, mask VI_INK
	clr	dx
	call	ObjMessage_init_send
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	call	ObjMessage_init_send
	mov	ax, MSG_GEN_APPLY
	call	ObjMessage_init_send

	; Finally, make the InkObject the defulat target & focus at its
	; level, so all tools will be properly enabled.
	;
	GetResourceHandleNS	InkObject, bx
	mov	si, offset InkObject
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ObjMessage_init_send
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ObjMessage_init_send
endif

done:
	.leave
	ret
SizeControlInit	endm

InitCode	ends



GeometryCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarPrimaryVisOpenAndClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Keep track of when we are iconified/visible

CALLED BY:	GLOBAL (MSG_VIS_OPEN, MSG_VIS_CLOSE)
	
PASS:		DS:*SI	= CalendarPrimaryClass instance data
		ES	= DGroup
		CX, DX, BP = Data

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	9/28/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarPrimaryVisOpenAndClose	method	CalendarPrimaryClass,	MSG_VIS_OPEN,
								MSG_VIS_CLOSE
	.enter

	; Keep track of what's visible, and then call superclass
	;
	push	ax				; save the method passed
	mov	di, offset CalendarPrimaryClass	; ES:DI is the class called
	call	ObjCallSuperNoLock		; call my superclass
	pop	ax				; passed method => AX
	and	es:[systemStatus], not SF_VISIBLE
	cmp	ax, MSG_VIS_CLOSE		; assume we're invisible
	je	done				; if so, do nothing

	; Else must update the time now (*after being invisible)
	;
	or	es:[systemStatus], SF_VISIBLE
	call	TimerGetDateAndTime
	mov	cl, dl				; minutes => CL
	mov	dh, bl				; month => DH
	mov	dl, bh				; day => DL
	mov	bp, ax				; year => BP
	mov	ax, MSG_CALENDAR_SET_DATE
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	call	MemOwner			; process handle => BX
	call	ObjMessage_geometry_send
done:
	.leave
	ret
CalendarPrimaryVisOpenAndClose	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeControlRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Attempts to equally share the available screen space between
		the Calendar & the DayPlan views

CALLED BY:	UI (MSG_VIS_RECALC_SIZE)
	
PASS:		DS:DI	= SizeControl specific instance data
		ES	= DGroup
		CX	= Width (suggested)
		DX	= Height (suggested)

RETURN:		CX	= Width (actual)
		DX	= Height (actual)

DESTROYED:	AX, BX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/25/90		Initial version
	sean	9/25/95		Responder changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SPACING_BETWEEN_VIEWS = 3

SCRS_LEFT		equ 0x1
SCRS_RIGHT		equ 0x2

SizeControlRecalcSize	method	SizeControlClass,	MSG_VIS_RECALC_SIZE
	.enter


	; Set-up work for the sizes
	;
	clr	bp				; initialize size flags
	mov	si, offset Interface:CalendarLeft
	mov	si, ds:[si]			
	add	si, ds:[si].Gen_offset
	test	ds:[si].GI_states, mask GS_USABLE	
	jz	checkRight
	or	bp, SCRS_LEFT
checkRight:
	mov	si, offset Interface:CalendarRight
	mov	si, ds:[si]			
	add	si, ds:[si].Gen_offset
	test	ds:[si].GI_states, mask GS_USABLE
	jz	checkSize
	or	bp, SCRS_RIGHT

checkSize:
	test	cx, mask RSA_CHOOSE_OWN_SIZE
	jnz	leftSize
	cmp	bp, SCRS_LEFT or SCRS_RIGHT
	jne	leftSize
	sub	cx, SPACING_BETWEEN_VIEWS	; account for space between
	sar	cx, 1				; and divide width by two

	; Get the calendar size if appropriate
leftSize:
	clr	bx				; initialize left width
	test	bp, SCRS_LEFT
	jz	rightSize
	push	cx				; save original width
	mov	si, offset Interface:CalendarLeft
	call	VisRecalcSizeAndInvalIfNeeded	; send the CALC_NEW_SIZE
	call	VisSetSize			; must resize the composite
	mov	bx, cx				; left width => BX
	pop	cx				; restore width

	; Get the dayplan size if appropriate
rightSize:
	clr	ax				; initialize right width
	test	bp, SCRS_RIGHT
	jz	totalSize
	push	dx				; save the passed height
	mov	si, offset Interface:CalendarRight
	call	VisRecalcSizeAndInvalIfNeeded	; send the CALC_NEW_SIZE
	call	VisSetSize			; must resize the composite
	mov_tr	ax, cx				; right width => AX
	pop	di				; restore passed height

	; Muck with the height, as needed
	;
	test	di, mask RSA_CHOOSE_OWN_SIZE
	jnz	totalSize
	cmp	dx, di				; use the larger of the two
	jae	totalSize
	mov	dx, di

	; Total the sizes (use the larger height)
totalSize:
	mov_tr	cx, ax				; left width
	add	cx, bx				; + right width
	cmp	bp, SCRS_LEFT or SCRS_RIGHT
	jne	done
	add	cx, SPACING_BETWEEN_VIEWS	; + margin = total width
done:
	.leave
	ret
SizeControlRecalcSize	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeControlGetSpacing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns various spacing information

CALLED BY:	UI (MSG_GET_SPACING)
	
PASS:		DS:DI	= SizeControlClassspecific instance data
		ES	= DGroup

RETURN:	
		cx -- spacing between children
        	dx -- spacing between wrapped lines of children

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SizeControlGetSpacing	method	SizeControlClass, MSG_VIS_COMP_GET_CHILD_SPACING
	.enter

	mov	cx, SPACING_BETWEEN_VIEWS
	clr	dx

	.leave
	ret
SizeControlGetSpacing	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeControlSetViewType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ViewType to be displayed.

CALLED BY:	GLOBAL (MSG_SIZE_CONTROL_SET_VIEW_TYPE)

PASS:		ES	= DGroup
		DS	= Interface segment
		CX	= ViewType

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 6/92	Initial version
		sean	3/19/95		To Do list changes
		sean	10/30/95	Got rid of changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SizeControlSetViewType	method dynamic	SizeControlClass,
					MSG_SIZE_CONTROL_SET_VIEW_TYPE
		.enter


		; See if anything has changed
		;
		mov	al, not (mask VI_TYPE)
		call	UpdateViewInfo		; ViewInfo => BL
		jnc	grabFocus

		; Now set one usable, and the other not
		;
		call	ViewMakeVisible
grabFocus:
		call	ViewGrabFocusAndTarget

		.leave
		ret
SizeControlSetViewType	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeControlSetViewBoth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ViewType to be displayed.

CALLED BY:	GLOBAL (MSG_SIZE_CONTROL_SET_VIEW_BOTH)

PASS:		ES	= DGroup
		DS	= Interface segment
		CX	= ViewInfo

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SizeControlSetViewBoth	method dynamic	SizeControlClass,
					MSG_SIZE_CONTROL_SET_VIEW_BOTH
		.enter

		; See if anything has changed
		;
		mov	al, not (mask VI_BOTH)
		call	UpdateViewInfo		; ViewInfo => BL
		jnc	done			; no change, so we're done

		; Else we need to set the other view usable
		;
		test	bl, mask VI_BOTH
		jz	makeVisible
		xor	bl, VT_CALENDAR		; invert this bit
makeVisible:
		call	ViewMakeVisible		; make the other view visible
done:
		.leave
		ret
SizeControlSetViewBoth	endm

if _USE_INK

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		SizeControlSetViewInk
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the ViewInk to be displayed.

CALLED BY:	GLOBAL (MSG_SIZE_CONTROL_SET_VIEW_INK)

PASS:		ES	= DGroup
		DS	= Interface segment
		CX	= ViewInfo

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

SizeControlSetViewInk	method dynamic	SizeControlClass,
					MSG_SIZE_CONTROL_SET_VIEW_INK
		.enter

		; See if anything has changed
		;
		mov	al, not (mask VI_INK or mask VI_TYPE)
		call	UpdateViewInfo		; ViewInfo => BL
		jnc	done			; no change, so we're done

		; Make the correct view visible, and then grab the focus
		;
		call	ViewMakeVisible
		call	ViewGrabFocusAndTarget

		; Finally, set the moniker for the Event View item
		;
		mov	cx, offset ViewEventsInkMoniker
		test	bl, mask VI_INK
		jnz	setMoniker
		mov	cx, offset ViewEventsMoniker
setMoniker:
		mov	ax, MSG_GEN_USE_VIS_MONIKER
		mov	si, offset MenuBlock:ViewViewEventsItem
		mov	dl, VUM_NOW
		call	ObjMessage_geometry_send_menu

		; Finally, update the ViewViewList
		;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, VT_EVENTS
		clr	dx
		mov	si, offset MenuBlock:ViewViewList
		call	ObjMessage_geometry_send_menu
done:
		.leave
		ret
SizeControlSetViewInk	endm
endif	;if _USE_INK



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateViewInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the ViewInfo

CALLED BY:	INTERNAL

PASS:		ES	= DGroup
		AL	= ViewInfo mask to ignore
		CL	= ViewInfo data to set

RETURN:		Carry	= Set if different
		BL	= ViewInfo

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
UpdateViewInfo	proc	near
		.enter
	
		mov	bl, es:[viewInfo]
		and	bl, al
		or	bl, cl
		cmp	bl, es:[viewInfo]
		mov	es:[viewInfo], bl
		je	done
		stc
done:
		.leave
		ret
UpdateViewInfo	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewMakeVisible
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Make the correct view(s), etc. visible.

CALLED BY:	INTERNAL

PASS:		ES	= DGroup
		BL	= ViewInfo

RETURN:		Nothing

DESTROYED:	AX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 6/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ViewMakeVisible	proc	near
		uses	bx
		.enter
	
		; Swap the usability of the sides first
		;
		mov	di, offset Interface:CalendarRight
		mov	si, offset Interface:CalendarLeft
		test	bl, mask VI_TYPE
		jz	checkForBoth
		xchg	di, si
checkForBoth:
		test	bl, mask VI_BOTH
		jz	setSideStatus
		clr	si
setSideStatus:
		call	ViewSwapUsable
		
if _USE_INK
		; Now see if the ink view should be dealt with
		;
		mov	di, offset Interface:InkView
		mov	si, offset Interface:EventView
		test	bl, mask VI_INK
		jnz	setViewStatus
		xchg	di, si
setViewStatus:
		call	ViewSwapUsable
endif

if _DISPLAY_TIME
		; Now see if we need to muck with the 2nd time object
		;
		mov	di, offset Interface:CalendarTime2
		clr	si
		test	bl, mask VI_BOTH or mask VI_TYPE
		jz	setTimeStatus
		xchg	di, si
setTimeStatus:
		call	ViewSwapUsable
endif
		.leave
		ret
ViewMakeVisible	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewSwapUsable
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set one generic tree usable, another not usable

CALLED BY:	SizeControlSetViewInfo

PASS:		*DS:SI	= Object to set NOT USABLE (may be NULL)
		*DS:DI	= Object to set USABLE (may be NULL)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/17/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ViewSwapUsable	proc	near
	.enter
	
	; Set one generic object usable
	;
	tst	si
	jz	usable
	mov	ax, MSG_GEN_SET_NOT_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock

	; Set on generic object not usable
usable:
	mov	si, di
	tst	si
	jz	done
	mov	ax, MSG_GEN_SET_USABLE
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	call	ObjCallInstanceNoLock
done:
	.leave
	ret
ViewSwapUsable	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ViewGrabFocusAndTarget
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Grab the focus exclusive of the proper view

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		cx,bl	= ViewInfo

RETURN:		Nothing

DESTROYED:	AX, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	10/ 6/92	Initial version
		sean	4/5/95		To Do list changes
		sean	10/30/95	Got rid of To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
viewList	lptr	Interface:EventView, \
			Interface:YearView 
if _USE_INK
		lptr	Interface:InkView 
endif
		lptr	Interface:YearView

ViewGrabFocusAndTarget	proc	near
	.enter

	; Find the correct view
	;
	and	bx, mask VI_TYPE or mask VI_INK
	mov	si, cs:[viewList][bx]	; view to grab focus => *DS:SI

	; Grab the focus
	;
	mov	ax, MSG_META_GRAB_FOCUS_EXCL
	call	ViewSendMessage

	; Grab the target
	;
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	call	ViewSendMessage

	; Send message to DayPlan, if needed, so that we'll select
	; an event if at all possible
	;
	cmp	si, offset EventView
	jne	checkYear
	mov	ax, MSG_DP_SELECT_FIRST
	GetResourceHandleNS	DayPlanObject, bx
	mov	si, offset DayPlanObject
	call	ObjMessage_geometry_send
	jmp	done

	; For some reason (maybe because the view was set usable),
	; the YearObject does not always grab the target when the
	; YearContent has the target. We'll fix that! -Don 1/19/98
checkYear:
	cmp	si, offset YearView
	jne	done
	mov	ax, MSG_META_GRAB_TARGET_EXCL
	GetResourceHandleNS	YearObject, bx
	mov	si, offset YearObject
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage
done:
	.leave
	ret
ViewGrabFocusAndTarget	endp

ViewSendMessage	proc	near
	call	ObjCallInstanceNoLock
	ret
ViewSendMessage	endp

if _USE_INK
ObjMessage_geometry_send_menu	proc	near
	GetResourceHandleNS	MenuBlock, bx
	FALL_THRU	ObjMessage_geometry_send
ObjMessage_geometry_send_menu	endp
endif

ObjMessage_geometry_send	proc	near
	clr	di
	GOTO	ObjMessage_geometry
ObjMessage_geometry_send	endp

ObjMessage_geometry_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	FALL_THRU	ObjMessage_geometry
ObjMessage_geometry_call	endp

ObjMessage_geometry		proc	near
	call	ObjMessage
	ret
ObjMessage_geometry		endp

GeometryCode	ends



CommonCode	segment	resource



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		UpdateViewType
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the ViewType

CALLED BY:	GLOBAL

PASS:		ES	= DGroup
		CX	= ViewType

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/10/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

UpdateViewType	proc	far
		uses	ax, bx, cx, dx, bp, si
		.enter
	
		andnf	es:[viewInfo], not (mask VI_TYPE)
		or	es:[viewInfo], cl
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		GetResourceHandleNS	ViewViewList, bx
		mov	si, offset ViewViewList
		clr	dx			; determinate
		call	ObjMessage_common_send

		.leave
		ret		

UpdateViewType	endp

CommonCode	ends










