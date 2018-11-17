COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar/DayPlan
FILE:		dayplanPreference.asm

AUTHOR:		Don Reeves, May 31, 1990

ROUTINES:
	Name			Description
	----			-----------

	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/31/90		Initial revision


DESCRIPTION:
	Contains all the routines that initialize, read, and write the
	preference options.
		
	$Id: dayplanPreference.asm,v 1.1 97/04/04 14:47:31 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceLoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Loads all of the preference settings

CALLED BY:	UI (MSG_META_LOAD_OPTIONS)
	
PASS:		DS:DI	= DayPlanClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/31/90		Initial version
	Don	6/22/90		Added the beginup information
	SS	3/21/95		To Do list changes

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceLoadOptions	method	DayPlanClass,	MSG_META_LOAD_OPTIONS
	.enter

	; Load all the options not stored in UI "gadgets"
	;
	mov	bp, offset PrefReadInteger	; callback routine => BP
	call	PreferenceReadWrite		; read from the init file
	call	PreferenceResetTimes		; reset the time strings

	; Now setup all of the dialog box gadgetry, and mark myself dirty
	;
	mov	ax, MSG_DP_CHANGE_PREFERENCES
	call	ObjCallInstanceNoLock		; send the method to myself
	mov	ax, si				; chunk => SI
	mov	bx, mask OCF_DIRTY		; mark the chunk dirty
	call	ObjSetFlags

	; Set the default start-up mode. If it's both, do nothing
	;
	mov	di, ds:[si]
	add	di, ds:[di].DayPlan_offset	; DayPlanInstance => DS:DI
	mov	cl, ds:[di].DPI_startup		; startup choices => CL
if	_TODO					; if To Do list, we startup
	call	LoadOptions			; with Calendar/Events
else
	cmp	cl, mask VI_BOTH
	je	done
	
	; Switch to the correct view (calendar or events)
	;
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	bp, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	clr	dx
	mov	ch, dh
	GetResourceHandleNS	MenuBlock, bx
	mov	si, offset MenuBlock:ViewViewList
	call	SelectAndSendApply

	; Turn off the View->Both
	;
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	mov	bp, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_MODIFIED_STATE
	clr	cx, dx
	mov	si, offset MenuBlock:ViewBothList
	call	SelectAndSendApply
done:
endif
	.leave
	ret
PreferenceLoadOptions	endp

if	_TODO
else

SelectAndSendApply	proc	near
	clr	di
	call	ObjMessage_pref_low
	mov_tr	ax, bp				; modified message => AX
	mov	cx, mask VI_BOTH		; set this one modified
	clr	di
	call	ObjMessage_pref_low		; set the modified bit
	mov	ax, MSG_GEN_APPLY
	clr	di
	GOTO	ObjMessage_pref_low
SelectAndSendApply	endp
endif

if	_TODO

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Checks which load options are requested and brings
		the Geoplanner up with the correct view.

CALLED BY:	PreferenceLoadOption

PASS:		cl	= viewInfo
			    (VT_CALENDAR shl offset VI_TYPE,
			     VT_CALENDAR_AND_TODO_LIST shl offset VI_TYPE,...)

RETURN:		nothing	

DESTROYED:	ax,bx,cx,dx,si,di

SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		if we're loading the Calendar/Events view--do nothing
		otherwise
		  set the selection for the View menu
		  "press" that button with
		     MSG_..._SET_MODIFIED_STATE
		     MSG_GEN_APPLY

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	SS	3/21/95    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadOptions	proc	near
	.enter

	cmp	cl, VT_CALENDAR_AND_EVENTS shl offset VI_TYPE	; cal/events ?
	je 	done					; do nothing

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	mov	ch, dh
	GetResourceHandleNS	MenuBlock, bx
	mov	si, offset MenuBlock:ViewViewList
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_ITEM_GROUP_SET_MODIFIED_STATE
	mov	cx, 1
	clr	di
	call	ObjMessage

	mov	ax, MSG_GEN_APPLY
	clr	di
	call	ObjMessage
done:	
	.leave
	ret
LoadOptions	endp
endif



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceSaveOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Saves all of the preference settings

CALLED BY:	UI (MSG_META_SAVE_OPTONS)
	
PASS:		DS:DI	= DayPlanClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, DS

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/31/90		Initial version
	Don	6/22/90		Added the startup information

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceSaveOptions	method	DayPlanClass, MSG_META_SAVE_OPTIONS
	.enter

	; Write out all of the options not stored in gadgets
	;
	mov	bp, offset PrefWriteInteger	; callback routine => BP
	call	PreferenceReadWrite		; write to the init file
	
	; Finally, commit all of the changes
	;
	call	InitFileCommit			; update the file to disk

	.leave
	ret
PreferenceSaveOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceResetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset the Preference options to the default value as
		if the application had just been started (default values
		from .UI files + any .INI file changes)

CALLED BY:	GLOBAL (MSG_META_RESET_OPTIONS)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	2/15/95		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceResetOptions	method dynamic	DayPlanClass, MSG_META_RESET_OPTIONS
		.enter
	;
	; Restore the default Preference settings
	;
		mov	{word} ds:[di].DPI_beginMinute, DEFAULT_START_TIME
		mov	{word} ds:[di].DPI_endMinute, DEFAULT_END_TIME
		mov	ds:[di].DPI_interval, DEFAULT_INTERVAL
		mov	ds:[di].DPI_prefFlags, DEFAULT_PREF_FLAGS or \
			                       PF_GLOBAL or PF_SINGLE
		mov	ds:[di].DPI_startup, DEFAULT_VIEW_INFO
		mov	{word} es:[precedeMinute], 0
		clr	es:[precedeDay]
	;
	; Reset the UI in the Prefences dialog box to match these defaults
	;
		mov	bp, offset PrefReadInteger
		call	PreferenceReadWrite	; read from the init file
		mov	ax, MSG_PREF_RESET_OPTIONS
		call	ObjCallInstanceNoLock		
	;
	; Ask the UI to reload any default (network or ROM) .INI values
	;
		push	si
		mov	ax, MSG_META_LOAD_OPTIONS
		mov	si, offset PrefBlock:PreferencesBox
		call	ObjMessage_pref_call
		pop	si
	;
	; Finally, queue a message for the DayPlan object, telling it
	; to re-display the EventView relative to our option changes.
	; We queue the event so that all of the notifications of any
	; .INI default value changes will have been received by the time
	; the DayPlan object updates its display.
	;
		mov	ax, MSG_DP_CHANGE_PREFERENCES
		mov	bx, ds:[LMBH_handle]
		mov	di, mask MF_FORCE_QUEUE
		call	ObjMessage_pref_low

		.leave
		ret
PreferenceResetOptions	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferencePrefResetOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Reset all of the options in the preferences dialog box

CALLED BY:	UI (MSG_PREF_RESET_OPTIONS)
	
PASS:		DS:*SI	= DayPlanClass instance data
		DS:DI	= DayPlanClass specific instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	8/12/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferencePrefResetOptions	method	DayPlanClass,	MSG_PREF_RESET_OPTIONS
	.enter
		
	; Reset all of the various UI gadgets
	;
	push	si				; save DayPlan chunk handle
	mov	cl, ds:[di].DPI_prefFlags
	and	cl, PF_TEMPLATE or PF_HEADERS
	mov	si, offset PrefBlock:DisplayChoicesList
	call	PrefSetBooleanGroup

	mov	cl, ds:[di].DPI_interval
	clr	ch
	mov	si, offset PrefBlock:DayInterval
	call	PrefSetRange

	mov	cl, es:[precedeMinute]
	clr	ch
		
	mov	si, offset PrefBlock:PrecedeMinutes
	call	PrefSetRange

	mov	cl, es:[precedeHour]
	clr	ch
	mov	si, offset PrefBlock:PrecedeHours
	call	PrefSetRange

	mov	cx, es:[precedeDay]
	mov	si, offset PrefBlock:PrecedeDays
	call	PrefSetRange

	mov	cl, ds:[di].DPI_startup
	mov	si, offset PrefBlock:ViewModeChoices
	call	PrefSetItemGroup

	mov	cl, ds:[di].DPI_prefFlags
	and	cl, PF_ALWAYS_TODAY or PF_DATE_CHANGE
	mov	si, offset PrefBlock:DateChangeChoices
	call	PrefSetBooleanGroup

	; Now reset all of the time strings
	;
	pop	si				; restore DayPlan chunk handle
	call	PreferenceResetTimes

	; Finally, disable the OK button
	;
	mov	ax, MSG_GEN_MAKE_NOT_APPLYABLE
	GetResourceHandleNS PrefBlock, bx
	mov	si, offset PrefBlock:EndDayTime
	call	ObjMessage_pref_send

	.leave
	ret
PreferencePrefResetOptions	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceResetTimes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SNOPSIS:	Re-create the start & end time strings, based on internaal data

CALLED BY:	INTERNAL
	
PASS: 		DS:*SI	= DayPlanClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/31/90		Initial version
	Don	12/26/90	Made into a method handler
	Don	1/19/99		Made back into a near procedure

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceResetTimes	proc	near
	uses	si
	.enter

	mov	di, ds:[si]			; dereference the handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
	push	{word} ds:[di].DPI_endMinute
	mov	cx, {word} ds:[di].DPI_beginMinute ; begin time => CX
	mov	si, offset PrefBlock:StartDayTime
	call	PrefTimeToTextObject		; time string => text object
	pop	cx				; end time => CX
	mov	si, offset PrefBlock:EndDayTime
	call	PrefTimeToTextObject		; time string => text object

	.leave
	ret
PreferenceResetTimes	endp

PrefTimeToTextObject	proc	near
	GetResourceHandleNS	PrefBlock, di	; PrefBlock handle => DI
	call	TimeToTextObject		
	ret
PrefTimeToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceVerifyOptions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Check some things before the dialog box goes of screen

CALLED BY:	UI (MSG_PREF_VERIFY_OPTIONS)
	
PASS:		DS:DI	= DayPlanClass specific instance data
		DS:*SI	= DayPlanClass instance data
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/31/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceVerifyOptions	method	DayPlanClass,	MSG_PREF_VERIFY_OPTIONS

	; Mark the chunk as dirty. Pass method to superclass
	;
	mov	ax, si				; chunk => SI
	mov	bx, mask OCF_DIRTY		; mark the chunk dirty
	call	ObjSetFlags			; mark the chunk as dirty
	mov	bx, si				; Preference handle => BX

	; Now get the time fields
	;
	mov	si, offset PrefBlock:StartDayTime
	call	PrefStringToTime		; time => CX
	jc	quit				; if carry set, invalid time
	cmp	{word} ds:[di].DPI_beginMinute, cx
	je	endTime				; jump if time hasn't changed
	mov	{word} ds:[di].DPI_beginMinute, cx
	or	ds:[di].DPI_prefFlags, PF_SINGLE ; affects one day display
endTime:
	mov	si, offset PrefBlock:EndDayTime
	call	PrefStringToTime		; time => CX
	jc	quit				; if carry set, invalid time
	cmp	{word} ds:[di].DPI_endMinute, cx
	je	checkTimes			; if time hasn't changed, done
	mov	{word} ds:[di].DPI_endMinute, cx
	or	ds:[di].DPI_prefFlags, PF_SINGLE ; affects one day display

	; Start time must be before end time
checkTimes:
	cmp	cx, {word} ds:[di].DPI_beginMinute
	jge	done				; if begin <= end, OK
	call	GeodeGetProcessHandle		; process handle => BX
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	mov	bp, CAL_ERROR_START_GTR_END	; error to display
	clr	di
	GOTO	ObjMessage			; send the method

	; Bring down the DB, & call myself to notify the other objects
done:
	push	bx				; save the DayPlan handle
	mov	ax, MSG_GEN_APPLY
	mov	si, offset PrefBlock:PreferencesBox
	call	ObjMessage_pref_call
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	call	ObjMessage_pref_call
	pop	si				; DayPlan handle => SI
	call	PreferenceResetTimes		; re-stuff the time values
	mov	bx, ds:[LMBH_handle]		; block handle => BX
	mov	ax, MSG_DP_CHANGE_PREFERENCES
	mov	di, mask MF_FORCE_QUEUE		; send method via the queue
	call	ObjMessage			; send method back to myself

	; Also need to tell the application that I have options to be saved
	;
	GetResourceHandleNS Calendar, bx
	mov	si, offset Calendar
	mov	ax, MSG_GEN_APPLICATION_OPTIONS_CHANGED
	clr	di
	call	ObjMessage_pref_low
quit:
	ret
PreferenceVerifyOptions	endp

PrefStringToTime	proc	near
	GetResourceHandleNS	PrefBlock, di	; OD => DI:SI
	mov	cl, 1				; must have a valid time
	call	StringToTime			; time => CX
	jc	done
	mov	di, ds:[bx]			; dereference the Pref handle
	add	di, ds:[di].DayPlan_offset	; access my instance data
done:
	ret
PrefStringToTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceReadWrite
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read or write the values from/to the .INI file that
		cannot be handled by normal UI gadgetry.

CALLED BY:	INTERNAL	

PASS:		ES	= DGroup
		DS:DI	= DayPlanInstance
		BP	= Callback routine for reading or writing:
				- PrefReadInteger
				- PrefWriteInteger

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

auiCategoryStr	char 'calendar', 0
cuiCategoryStr	char 'calendar0', 0

beginHourKey	char 'beginHour', 0
beginMinuteKey	char 'beginMinute', 0
endHourKey	char 'endHour', 0
endMinuteKey	char 'endMinute', 0

prefReadWrite	PrefReadWriteStruct \
		<beginHourKey,		0, 23, DPI_beginHour>,
		<beginMinuteKey,	0, 59, DPI_beginMinute>,
		<endHourKey,		0, 23, DPI_endHour>,
		<endMinuteKey,		0, 59, DPI_endMinute>

NUM_READ_WRITE_ENTRIES	equ 4

PreferenceReadWrite	proc	near
	uses	es, ds, di, si
	.enter
	
	; First, some set-up work
	;
	segmov	es, ds, cx			; instance data => ES:DI
	segmov	ds, cs, cx			; category => DS:SI
	mov	si, offset cuiCategoryStr	; CUI category => DS:SI
	call	UserGetDefaultUILevel
	cmp	ax, UIIL_INTRODUCTORY
	je	goForIt
	mov	si, offset auiCategoryStr	; AUI category => DS:SI
goForIt:
	mov	cx, NUM_READ_WRITE_ENTRIES
	mov	bx, offset prefReadWrite

	; Now loop through all of the entries
readWriteLoop:
	push	cx
	mov	cx, cs
	mov	dx, cs:[bx].PRWS_key		; key string => CX:DX
	call	bp				; do reading or writing
	pop	cx
	add	bx, (size PrefReadWriteStruct)
	loop	readWriteLoop

	.leave
	ret
PreferenceReadWrite	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefReadInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Read an integer from the .INI file confirming its validity

CALLED BY:	PreferenceReadWrite

PASS:		ES:DI	= DayPlanInstance
		DS:SI	= Category string
		CX:DX	= Key string
		CS:BX	= PreferenceReadWriteStruct

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefReadInteger	proc	near
	uses	bp
	.enter

	; Read the integer value, and then check its bounds
	;
	call	InitFileReadInteger
	jc	done
	cmp	ax, cs:[bx].PRWS_lower
	jl	done
	cmp	ax, cs:[bx].PRWS_upper
	jg	done
	mov	bp, cs:[bx].PRWS_offset
	mov	es:[di][bp], al			; store the value away
done:
	.leave
	ret
PrefReadInteger	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefWriteInteger
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Write an integer to the .INI file

CALLED BY:	PreferenceReadWrite

PASS:		ES:DI	= DayPlanInstance
		DS:SI	= Category string
		CX:DX	= Key string
		CS:BX	= PreferenceReadWriteStruct

RETURN:		Nothing

DESTROYED:	AX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefWriteInteger	proc	near
	uses	bp
	.enter
	
	; Get the value, and write it out
	;
	mov	bp, cs:[bx].PRWS_offset
	mov	al, es:[di][bp]
	clr	ah
	mov_tr	bp, ax
	call	InitFileWriteInteger
		
	.leave
	ret
PrefWriteInteger	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		Handlers for options changes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceSetPrecede[Minute, Hour, Day]
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to user setting of the precede values

CALLED BY:	UI (MSG_PREF_SET_PRECEDE_[MINUTE, HOUR, DAY])

PASS:		ES	= DGroup
		DS:*SI	= Preference instance data
		DS:DI	= Preference specific instance data
		DX/DL	= Value

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/1/90		Initial version
	Don	5/31/90		Moved to the preference module

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceSetPrecedeMinute	method DayPlanClass, MSG_PREF_SET_PRECEDE_MINUTE
		
		mov	es:[precedeMinute], dl
	ret
PreferenceSetPrecedeMinute	endm

PreferenceSetPrecedeHour	method DayPlanClass, MSG_PREF_SET_PRECEDE_HOUR
	mov	es:[precedeHour], dl
	ret
PreferenceSetPrecedeHour	endm

PreferenceSetPrecedeDay		method DayPlanClass, MSG_PREF_SET_PRECEDE_DAY
	mov	es:[precedeDay], dx
	ret
PreferenceSetPrecedeDay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceSetInterval
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the interval between template events, and forces a reload
		if necessary.

CALLED BY:	UI (MSG_PREF_SET_INTERVAL)

PASS: 		DS:DI	= DayPlanClass specific instance data
		DL	= Interval (in mimutes)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	4/20/90		Initial version
	Don	5/31/90		Moved to preferece module

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceSetInterval	method	DayPlanClass, MSG_PREF_SET_INTERVAL
	mov	ds:[di].DPI_interval, dl	; store the new interval
	or	ds:[di].DPI_prefFlags, PF_SINGLE
	ret
PreferenceSetInterval	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceSetStartupChoices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the startup mode for the Calendar

CALLED BY:	UI (MSG_PREF_SET_STARTUP_CHOICES)
	
PASS:		DS:DI	= DayPlanClass specific instance data
		ES	= DGroup
		CX	= 0 (Calendar Only)
			= 1 (Events Only)
			= 2 (Both)

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	6/22/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceSetStartupChoices	method	DayPlanClass,
					MSG_PREF_SET_STARTUP_CHOICES
	mov	ds:[di].DPI_startup, cl		; store the startup value
	ret
PreferenceSetStartupChoices	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceUpdateEventChoices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI state based upon the event choice

CALLED BY:	GLOBAL (MSG_PREF_UPDATE_EVENT_CHOICES)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance
		CL	= PreferenceFlags set

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/ 9/93		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceUpdateEventChoices	method dynamic	DayPlanClass,
						MSG_PREF_UPDATE_EVENT_CHOICES
	.enter

	; Now disable/enable the interval amount
	;
	mov	ax, MSG_GEN_SET_NOT_ENABLED
	test	cl, PF_TEMPLATE
	jz	sendMessage
	mov	ax, MSG_GEN_SET_ENABLED
sendMessage:
	mov	si, offset DayInterval		; DS:*SI is the OD
	mov	dl, VUM_NOW			; update now
	call	ObjMessage_pref_send		; send the message

	.leave
	ret
PreferenceUpdateEventChoices	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceSetEventChoices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the event choices away

CALLED BY:	GLOBAL (MSG_PREF_SET_EVENT_CHOICES)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance
		CL	= PreferenceFlags set
		BP	= PreferenceFlags that changed

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceSetEventChoices	method dynamic	DayPlanClass,
						MSG_PREF_SET_EVENT_CHOICES
	.enter

	; Set the correct state of the HEADER flag
	;	
	test	bp, PF_TEMPLATE			; if this changed, then it
	jz	10$
	or	cl, PF_SINGLE			; ...affects one-day selection
10$:
	test	bp, PF_HEADERS			; if this changed, then it
	jz	20$
	or	cl, PF_RANGE			; ...affect range selection
20$:
	mov	ch, not (PF_HEADERS or PF_TEMPLATE) ; flags to clear
	call	PrefUpdateBooleans		; do the real work

	.leave
	ret
PreferenceSetEventChoices	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceSetDateChoices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Store the date choices away

CALLED BY:	GLOBAL (MSG_PREF_SET_DATE_CHOICES)

PASS:		*DS:SI	= DayPlanClass object
		DS:DI	= DayPlanClassInstance
		CL	= PreferenceFlags

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/ 5/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PreferenceSetDateChoices	method dynamic	DayPlanClass,
						MSG_PREF_SET_DATE_CHOICES
	.enter

	; Store the flags away, and then tell the DayPlan about it
	;
	or	cl, PF_GLOBAL			; we have a "global" change
	mov	ch, not (PF_ALWAYS_TODAY or PF_DATE_CHANGE)
	call	PrefUpdateBooleans		; do the real work

	.leave
	ret
PreferenceSetDateChoices	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PreferenceUpdateBooleans
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set or clear the boolean, depending on the state in BP

CALLED BY:	INTERNAL
	
PASS:		DS:DI	= DayPlanClassInstance
		CL	= Flag to set
		CH	= Flag to clear first

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/10/90	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefUpdateBooleans	proc	near
	class	DayPlanClass
	.enter

	; Clear or set the passed flag
	;
	and	ds:[di].DPI_prefFlags, ch
	or	ds:[di].DPI_prefFlags, cl

	.leave
	ret
PrefUpdateBooleans	endp



PrefSetBooleanGroup	proc	near
	mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
	clr	dx
	GOTO	ObjMessage_pref_send
PrefSetBooleanGroup	endp

PrefSetItemGroup	proc	near
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	clr	dx
	GOTO	ObjMessage_pref_send
PrefSetItemGroup	endp

PrefSetRange		proc	near
	mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
	clr	bp
	FALL_THRU	ObjMessage_pref_send
PrefSetRange		endp

ObjMessage_pref_send	proc	near
	push	di
	clr	di
	call	ObjMessage_pref
	pop	di
	ret
ObjMessage_pref_send	endp

ObjMessage_pref_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	FALL_THRU	ObjMessage_pref
ObjMessage_pref_call	endp

ObjMessage_pref		proc	near
	GetResourceHandleNS	PrefBlock, bx
	FALL_THRU	ObjMessage_pref_low

ObjMessage_pref		endp

ObjMessage_pref_low	proc	near
	call	ObjMessage
	ret
ObjMessage_pref_low	endp

PrefCode	ends
