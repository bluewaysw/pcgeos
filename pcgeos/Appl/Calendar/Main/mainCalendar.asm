COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) GeoWorks 1989 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainCalendar.asm

AUTHOR:		Don Reeves, July 11, 1989

ROUTINES:
	Name			Who   	Description
	----			---   	-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/11/89		Initial revision
	Don	12/4/89		Use new class & method declarations
	RR	6/14/95		Variable length events
	RR	6/22/95		memos
	RR	7/27/95		Responder repeat events
	RR	8/4/95		Fixed repsonder navigation

DESCRIPTION:
	Define my own object classes

	$Id: mainCalendar.asm,v 1.1 97/04/04 14:47:52 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

idata		segment

CalendarClass	mask CLASSF_NEVER_SAVED
GeoPlannerClass	mask CLASSF_NEVER_SAVED

if	_TODO
method AlarmTodo,		GeoPlannerClass, MSG_CALENDAR_ALARM_TODO
endif


method AlarmDestroy,		GeoPlannerClass, MSG_CALENDAR_ALARM_DESTROY
method AlarmSnooze,		GeoPlannerClass, MSG_CALENDAR_ALARM_SNOOZE
method AlarmClockTick,		GeoPlannerClass, MSG_CALENDAR_CLOCK_TICK
method AlarmTimeChange,		GeoPlannerClass, MSG_CALENDAR_TIME_CHANGE
method UpdateEvent,		GeoPlannerClass, MSG_CALENDAR_UPDATE_EVENT
method DeleteEvent,		GeoPlannerClass, MSG_CALENDAR_DELETE_EVENT
method DBGetMonthMap,		GeoPlannerClass, MSG_DB_GET_MONTH_MAP

method RepeatGetEventMoniker,	GeoPlannerClass, MSG_REPEAT_GET_EVENT_MONIKER
method RepeatSelectEvent,	GeoPlannerClass, MSG_REPEAT_SELECT_EVENT
method RepeatChangeEvent,	GeoPlannerClass, MSG_REPEAT_CHANGE_EVENT
method RepeatDeleteEvent, 	GeoPlannerClass, MSG_REPEAT_DELETE_EVENT
method RepeatNewEvent,		GeoPlannerClass, MSG_REPEAT_NEW_EVENT

method RepeatSetFrequency,	GeoPlannerClass, MSG_REPEAT_SET_FREQUENCY
method RepeatSetSpecify,	GeoPlannerClass, MSG_REPEAT_SET_SPECIFY
method RepeatSetDateExcl,	GeoPlannerClass, MSG_REPEAT_SET_DATE_EXCL
method RepeatSetDurationExcl,	GeoPlannerClass, MSG_REPEAT_SET_DURATION_EXCL
method RepeatAddNow,		GeoPlannerClass, MSG_REPEAT_ADD_NOW
method RepeatChangeNow,		GeoPlannerClass, MSG_REPEAT_CHANGE_NOW

idata		ends

idata		segment
	CalendarPrimaryClass
	SizeControlClass
	CalendarTimeDateControlClass

	systemStatus	SystemFlags	SF_DISPLAY_ERRORS or SF_CLEAN_VM_FILE
EC <	calendarDGroup	word		DGROUP_CHECK_VALUE		>
	currentYear	word		0	; used for window moniker
	currentDay	byte		0	;
	currentMonth	byte		0	;
	currentMinute	byte		-1	; used for the time display
	currentHour	byte		-1	;
	eventBGColor	ColorQuad <EVENT_BG_COLOR_RED, EVENT_BG_COLOR_FLAGS, \
				   EVENT_BG_COLOR_GREEN, EVENT_BG_COLOR_BLUE>
	monthBGColor	ColorQuad <MONTH_BG_COLOR_RED, MONTH_BG_COLOR_FLAGS, \
				   MONTH_BG_COLOR_GREEN, MONTH_BG_COLOR_BLUE>
idata		ends

udata		segment
	sysFontSize	word		(?)	; System font size
RestoreStateBegin	label	byte
	alarmsUp	byte		(?)	; How many alarm windows are up
	features	CalendarFeatures <>	; Current CalendarFeatures
	showFlags	ShowFlags 	< >	; Current window show state
	viewInfo	ViewInfo	< >	; Current view information
	curRepeatType	RepeatEventType	(?)	; The current RepeatEvent type
	precedeDay	word		(?)	; used to set alarm times
	precedeMinute	byte		(?)
	precedeHour	byte		(?)	; used to set alarm times
	repeatTime	word		(?)	; used to store time from DB
	vmFile		word		(?)	; current VM file
RestoreStateEnd		label	byte

udata		ends

ForceRef	currentMonth			; accessed by currentDay
ForceRef	currentHour			; accessed by currentMinute


InitCode		segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarColorScheme
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set up the color scheme for the DayPlan

CALLED BY:	CalendarAttach, YearInit

PASS: 		ES	= DGroup

RETURN:		AL	= DisplayType
		DX	= FontID used by system

DESTROYED:	AH, BX, CX, BP

PSEUDO CODE/STRATEGY:
		Runs in either UI or Calendar provess

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/11/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarColorScheme 	proc	far
	uses	di, si
	.enter
	
	; Get the display scheme from the application
	;
	mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
	clr	bx
	call	GeodeGetAppObject
	call	ObjMessage_init_call		; DisplayType => AH
	mov	al, ah				; DisplayType => AL
	and	ah, 0fh				; DisplayClass => AH
	mov	es:[sysFontSize], bp

	; If we are running on a B&W system, tweak the colors
	;
	cmp	ah, DC_GRAY_1			; look for B&W monitor
	jne	done
	mov	es:[eventBGColor].CQ_info, CF_INDEX
	mov	es:[eventBGColor].CQ_redOrIndex, C_WHITE
	mov	es:[monthBGColor].CQ_info, CF_INDEX
	mov	es:[monthBGColor].CQ_redOrIndex, C_WHITE
done:
	.leave
	ret
CalendarColorScheme	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarOpenAsApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the Calendar as an application

CALLED BY:	UI (MSG_GEN_PROCESS_OPEN_APPLICATION)

PASS:		AX	= Method
		CX	= AppAttachFlags
		DX	= Handle to AppLaunchBlock
		BP	= Block handle
		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, SI, DI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/5/90		Initial version
	sean	12/6/95		Responder GCN change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarOpenAsApplication method	GeoPlannerClass,
					MSG_GEN_PROCESS_OPEN_APPLICATION
	.enter

	; Open as an engine
	;
	call	CalendarOpenAsEngine
	
	; Start the only application-only functionality
	;
	push	cx				; save AppAttachFlags
	call	AlarmClockStart			; start the alarm clock
	pop	cx				; AppAttachFlags => CX

	; Initialize which windows we should be displaying. If we are
	; restoring from state, there is no need to do this.
	;
	test	cx, mask AAF_RESTORING_FROM_STATE
	jnz	initDayPlan
	mov	ax, MSG_SIZE_CONTROL_INIT
	GetResourceHandleNS	CalendarSizeControl, bx
	mov	si, offset CalendarSizeControl
	call	ObjMessage_init_send

	; Initialize the DayPlan
initDayPlan:
	GetResourceHandleNS	DayPlanObject, bx
	mov	si, offset DayPlanObject
	mov	ax, MSG_DP_INIT
	call	ObjMessage_init_send

	; Initialize the Year object
	;
	GetResourceHandleNS	YearObject, bx
	mov	si, offset YearObject
	mov	ax, MSG_YEAR_INIT
	call	ObjMessage_init_send

	; Add Calendar object to the selection notification list
	;
	mov	ax, MSG_META_GCN_LIST_ADD
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	call	CalendarSendToAppGCNList

if USE_RTCM
	;
	; Some versions have RTCM library to notify the app that
	; the system time is changed. The good part is the app will be
	; launched if the app is not running when time is changed.
	; (So, no need to get on GCN list) -- kho, 11/25/95
	;
	; Register to RTCM library for date/time change notification.
	; -- kho, 8/6/96
	;
	call	SetTimeChangeAlarm		; user setting system time
else
	; Add Calendar object to the date/time notification list
	;
	movdw	cxdx, bxsi			; application object => CX:DX
	mov	ax, GCNSLT_DATE_TIME
	mov	bx, MANUFACTURER_ID_GEOWORKS
	call	GCNListAdd
endif

	; In Responder, put the DayPlan object on the list
	; for date/time format change notifications.
	;

	.leave
	ret
CalendarOpenAsApplication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarInstallToken
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Install tokens
CALLED BY:	MSG_GEN_PROCESS_INSTALL_TOKEN

PASS:		none
RETURN:		none
DESTROYED:	ax, cx, dx, si, di

PSEUDO CODE/STRATEGY:
KNOWN BUGS/SIDE EFFECTS/IDEAS:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	2/19/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarInstallToken	method GeoPlannerClass, MSG_GEN_PROCESS_INSTALL_TOKEN

	; Call our superclass to get the ball rolling...
	;
	mov	di, offset GeoPlannerClass
	call	ObjCallSuperNoLock

	; install datafile token

	mov	ax, ('p') or ('l' shl 8)	; ax:bx:si = token used for
	mov	bx, ('n') or ('r' shl 8)	;	datafile
	mov	si, MANUFACTURER_ID_GEOWORKS
	call	TokenGetTokenInfo		; is it there yet?
	jnc	done				; yes, do nothing
	mov	cx, handle DatafileMonikerList	; cx:dx = OD of moniker list
	mov	dx, offset DatafileMonikerList
	clr	bp				; moniker list is in data
						;  resource, so it's relocated
	call	TokenDefineToken		; add icon to token database
done:
	ret
CalendarInstallToken	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarOpenAsEngine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open the calendar to be used as an engine

CALLED BY:	UI (MSG_GEN_PROCESS_OPEN_ENGINE), CalendarOPenAsApplication

PASS:		ES	= DGroup
		CX	= AppAttachFlags

RETURN:		Nothing

DESTROYED:	AX, BX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/5/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarOpenAsEngine	method	GeoPlannerClass, MSG_GEN_PROCESS_OPEN_ENGINE
	uses	cx
	.enter

	; Set up some state (if any)
	;
	call	CalRestoreSavedState

	; Now call the superclass
	;
	segmov	ds, es				; DGroup => DS
	mov	di, offset GeoPlannerClass	; class of SuperClass we call
	call	ObjCallSuperNoLock		; method already in AX

	.leave
	ret
CalendarOpenAsEngine	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalRestoreSavedState
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Restore any saved state variables

CALLED BY:	CalendarOpenAsApplication, CalendarOpenAsEngine

PASS:		BP	= Block handle
		ES	= DGroup

RETURN:		Nothing

DESTROYED:	BX, DI, SI

PSEUDO CODE/STRATEGY:
		Get the data
		Call superclass

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	12/8/89		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalRestoreSavedState	proc	near 

	; Some set-up work
	;
	tst	bp
	jz	manual

	; Restore the data
	;
	push	ax, cx, es			; save the method #, segment
	mov	bx, bp				; block handle to BX
	call	MemLock
	mov	ds, ax				; set up the segment
	mov	cx, (RestoreStateEnd - RestoreStateBegin)
	clr	si
	mov	di, offset RestoreStateBegin
	rep	movsb				; copy the bytes
	call	MemUnlock
	pop	ax, cx, es			; restore the method #, segment
	ret

	; Set up the data
manual:	
	mov	es:[features], DEFAULT_FEATURES
if	_TODO
	mov	es:[viewInfo], ViewInfo<0, 1, 0, VT_CALENDAR_AND_EVENTS>
else
	mov	es:[viewInfo], ViewInfo<0, 1, 0, VT_CALENDAR>
endif
	mov	es:[alarmsUp], 0		; no alarms can be up
	mov	es:[showFlags], DEFAULT_SHOW_FLAGS
	mov	es:[curRepeatType], RET_WEEKLY	; store the current type
	mov	es:[repeatTime], -1		; initialize to no time
	ret
CalRestoreSavedState	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarCloseApplication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the calendar, started as an application

CALLED BY:	UI (MSG_GEN_PROCESS_CLOSE_APPLICATION)

PASS:		DS, ES	= DGroup
		AX	= MSG_GEN_PROCESS_CLOSE_APPLICATION

RETURN:		CX	= Block handle holding CalendarState

DESTROYED:	AX, BX, DI, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version
	sean	12/6/95		Responder GCN change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarCloseApplication method	GeoPlannerClass,
				MSG_GEN_PROCESS_CLOSE_APPLICATION
	.enter

	; Close the DayPlan
	;
	GetResourceHandleNS	DayPlanObject, bx
	mov	si, offset DayPlanObject	; OD => BX:SI
	mov	ax, MSG_DP_QUIT
	call	ObjMessage_init_call

	; Add Calendar object to the selection notification list
	;
	mov	ax, MSG_META_GCN_LIST_REMOVE
	mov	cx, GAGCNLT_APP_TARGET_NOTIFY_SELECT_STATE_CHANGE
	call	CalendarSendToAppGCNList

if USE_RTCM
	;
	; These versions depend on RTCM library for date/time change,
	; rather than GCN list
	;
else
	; Remove Calendar object to the general notification list
	;
	movdw	cxdx, bxsi			; application object => CX:DX
	mov	bx, MANUFACTURER_ID_GEOWORKS
	mov	ax, GCNSLT_DATE_TIME
	call	GCNListRemove
endif
	; Close everything else down
	;
	call	CalendarCloseEngine		; save the state
	call	AlarmClockStop			; stop the alarm clock

	; In Responder, take the DayPlan object off the list
	; for date/time format change notifications.
	;

	.leave
	ret
CalendarCloseApplication	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarCloseEngine
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Closes the calendar, ending engine-necessary functionality

CALLED BY:	UI (MSG_GEN_PROCESS_CLOSE_ENGINE), CalendarCloseApplication

PASS:		DS	= DGroup
		AX	= Method to pass on to superclass

RETURN:		CX	= Handle holding Calendar state

DESTROYED:	AX, BX, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/9/90		Initial version
	Don	5/21/90		Removed call to my SuperClass

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarCloseEngine	method	GeoPlannerClass, MSG_GEN_PROCESS_CLOSE_ENGINE
	.enter

	; Store the state
	;
	or	ds:[systemStatus], SF_EXITING	; set the exiting flag
	mov	ax, (RestoreStateEnd - RestoreStateBegin)
	mov	cx, ALLOC_DYNAMIC_NO_ERR or \
		    mask HF_SHARABLE or \
		    (mask HAF_LOCK shl 8)
	call	MemAlloc
	mov	es, ax

	; Copy the state into the locked block, and then unlock it.
	;
	mov	cx, (RestoreStateEnd - RestoreStateBegin)
	clr	di
	mov	si, offset RestoreStateBegin
	rep	movsb				; copy the bytes
	call	MemUnlock
	mov	cx, bx

	.leave
	ret
CalendarCloseEngine	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSetMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the calendar window moniker

CALLED BY:	CalendarSetDate

PASS:		BP	= Year
		DH	= Month
		DL	= Day
		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/15/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if _DATE_ON_TITLE_BAR
CalendarSetMoniker	proc	far
	uses	es
	.enter
	; Allocate a block to hold the data
	;
	sub	sp, DATE_BUFFER_SIZE		; allocate buffer on the stack
	mov	di, sp				; SS:DI => buffer
	segmov	es, ss				; ES:DI => buffer

	; Set up the moniker & create the string
	;
	push	di				; save start of the string
	mov	si, offset todayis		; pass in proper chunk handle
	CallMod	WriteLocalizedString		; write part of the string
	mov	cx, DTF_LONG or USES_DAY_OF_WEEK ; append the rest of the date
	CallMod	CreateDateString		; create the title

	; Now copy in the moniker
	;
	mov	cx, es
	pop	dx				; string => CX:DX
	mov	bp, VUM_NOW			; update now
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	GetResourceHandleNS	PlannerPrimary, bx
	mov	si, offset PlannerPrimary
	call	ObjMessage_init_call		; make the call!
	add	sp, DATE_BUFFER_SIZE
	.leave
	ret
CalendarSetMoniker	endp
endif


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSendToAppGCNList
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sends an add or remove message to the application object's
		GCN list

CALLED BY:	INTERNAL

PASS:		AX	= Message to send
		CX	= GCN list to work with

RETURN:		BX:SI	= Application object's OD

DESTROYED:	AX, DX, BP, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/ 1/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarSendToAppGCNList	proc	near
	.enter
	
	mov	dx, size GCNListParams
	sub	sp, dx
	mov	bp, sp				; GCNListParams => SS:BP
	clr	bx				; use this geode!
	call    GeodeGetAppObject		; application object => BX:SI
	mov	ss:[bp].GCNLP_ID.GCNLT_manuf, MANUFACTURER_ID_GEOWORKS
	mov	ss:[bp].GCNLP_ID.GCNLT_type, cx
	mov	ss:[bp].GCNLP_optr.handle, bx
	mov	ss:[bp].GCNLP_optr.chunk, si	
	mov	di, mask MF_STACK
	call	ObjMessage_init			; send it!!
	add	sp, dx				; clean up the stack

	.leave
	ret
CalendarSendToAppGCNList	endp

ObjMessage_init_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	GOTO	ObjMessage_init
ObjMessage_init_call	endp

ObjMessage_init_send	proc	near
	mov	di, mask MF_FIXUP_DS
	FALL_THRU	ObjMessage_init
ObjMessage_init_send	endp

ObjMessage_init		proc	near
	call	ObjMessage
	ret
ObjMessage_init		endp

InitCode	ends



ResidentCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Sets the date to appear in the window title

CALLED BY:	GLOBAL (MSG_CALENDAR_SET_DATE)

PASS:		BP	= Year
		DH	= Month
 		DL	= Day
		CH	= Hour
		CL	= Minute
		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	TBD

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/15/89	Initial version
	Don	12/6/89		Added time stuff

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarSetDate	method	GeoPlannerClass, MSG_CALENDAR_SET_DATE

	; Check for the same date
	;
	test	es:[systemStatus], SF_VISIBLE	; are we visible ??
	jz	done				; no, so get out of here
	cmp	es:[currentYear], bp		; compare the years
	jne	newDate
	cmp	{word} es:[currentDay], dx	; compare the month & day
	je	timeCheck

	; A new date
newDate:
	push	cx				; save the time
	tst	es:[currentYear]		; any year yet ??
	mov	es:[currentYear], bp		; save the year
	mov	{word} es:[currentDay], dx	; save the month & day
if _DATE_ON_TITLE_BAR
	pushf					; save the flags
	call	CalendarSetMoniker		; draw the damm thing
	popf					; restore the flags
endif
	jz	timeCheckPop			; if no prev year, continue

	; Force the year to redraw to update date box
	;
	mov	ax, MSG_VIS_MARK_INVALID	; else force year to redraw
	mov	cl, mask VOF_IMAGE_INVALID	; image is invalid
	mov	dl, VUM_NOW			; update now
	GetResourceHandleNS	YearObject, bx	; OD -> BX:SI
	mov	si, offset YearObject
	clr	di				; not a call
	call	ObjMessage			; send the method

	; If date change flag set, view today's events
	;
	test	es:[showFlags], mask SF_SHOW_NEW_DAY_ON_DATE_CHANGE
	jz	timeCheckPop
	mov	ax, MSG_YEAR_VIEW_TODAY
	clr	di
	call	ObjMessage

	; Update the time, if it is different
timeCheckPop:
	pop	cx				; restore the time
timeCheck:
	cmp	cx, {word} es:[currentMinute]	; compare with current time
	je	done				; if equal, do nothing
	mov	{word} es:[currentMinute], cx	; store the time
if _DISPLAY_TIME
	GetResourceHandleNS	Interface, di
	mov	si, offset Interface:CalendarTime1 ; OD => DI:SI
	push	cx				; save the time
	call	TimeToMoniker			; stuff in the time string
	pop	cx				; restore the time
	mov	si, offset Interface:CalendarTime2 ; OD => DI:SI
	call	TimeToMoniker			; stuff in the time string
endif
done:
	ret
CalendarSetDate	endp

ResidentCode	ends



CommonCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quickly display today's events

CALLED BY:	UI (MSG_CALENDAR_QUICK)

PASS:		DS	= DGroup
		ES	= DGroup
		CX	= QuickEnum
		BP:DX	= Gr:It # of event to select (Responder Only)

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/17/89	Initial version
	RR	8/3/95		Responder changes
	sean	8/30/95		facilitating event date change

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

quickJumpTable	nptr.near \
		QuickToday,
		QuickWeek,
		QuickWeekend,
		QuickMonth,
		QuickQuarter,
		QuickYear,
		QuickGoto,
		QuickPrevious

QuickView	method	GeoPlannerClass, MSG_CALENDAR_QUICK

	; Create a RangeStructure to use
	;
	mov	di, cx				; QuickEnum => DI
	call	TimerGetDateAndTime		; get today's date
	mov	dh, bl				; month => DH
	mov	dl, bh				; day => DL
	mov	bp, ax				; year => BP
	sub	sp, size RangeStruct
	mov	bx, sp				; SS:BX points to the struct
		
	; Now parse the quick type to fill the structure
	;
EC <	cmp	di, QuickEnum			; compare with largest enum >
EC <	ERROR_AE	QUICK_VIEW_BAD_ENUM				>
EC <	test	di, 1				; low bit cannot be set	>
EC <	ERROR_NZ	QUICK_VIEW_BAD_ENUM				>
	call	{word} cs:[quickJumpTable][di]	; call the proper routine
	jcxz	exit				; if error, do nothing
	mov	bp, bx				; RangeStruct => SS:BP

	; Tell the year what to display
	;
	mov	ax, MSG_YEAR_SET_SELECTION
	mov	dx, size RangeStruct		; needed to pass stack
	mov	di, mask MF_CALL or mask MF_STACK
	call	ObjMessage_year_common		; do it, dude!

	; Tell the DayPlan to start loading
	;
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject	; BX:SI = object
	mov	ax, MSG_DP_SET_RANGE		; message to send
	call	ObjMessage_common_call		; do it, dude!
exit:
	add	sp, size RangeStruct		; fix up stack
	ret
QuickView	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickToday
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the RangeStruct to display today

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/17/89	Initial version
	Don	5/6/90		Changed passed arguments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickToday	proc	near

	mov	{word} ss:[bx].RS_startDay, dx
	mov	{word} ss:[bx].RS_endDay, dx
	mov	ss:[bx].RS_startYear, bp
	mov	ss:[bx].RS_endYear, bp
	mov	cx, 1				; 1 day in the range

	ret
QuickToday	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickWeek
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the RangeStruct to display this week

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range

DESTROYED:	AX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/17/89	Initial version
	Don	5/6/90		Changed passed arguments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickWeek	proc	near

	; Find today's day of week, & calculate first day of the week
	;
	push	dx, bp				; M/D, year
	call	CalcDayOfWeek			; day of week => CL
	push	cx				; save this information
	tst	cl				; is today a Sunday ?
	jz	stuffStart			; if yes, jump
	clr	ch
	neg	cx
	call	CalcDateAltered			; first day => DX:BP

	; Stuff the start date
stuffStart:
	pop	ax				; restore the DOW info
	mov	{word} ss:[bx].RS_startDay, dx
	mov	ss:[bx].RS_startYear, bp
	pop	dx, bp				; restore orig M/D, year
	
	; Now find the ending date
	;
	cmp	al, 6				; was today Saturday ?
	je	stuffEnd
	mov	cl, 6
	sub	cl, al
	clr	ch
	call	CalcDateAltered

	; Stuff the end date
stuffEnd:
	mov	{word} ss:[bx].RS_endDay, dx
	mov	ss:[bx].RS_endYear, bp
	mov	cx, 7				; seven days in a week
	ret
QuickWeek	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickWeekend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the RangeStruct to display today

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range

DESTROYED:	AX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	11/17/89	Initial version
	Don	5/6/90		Changed passed arguments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickWeekend	proc	near

	; Get today's day of week
	;
	push	dx, bp				; M/D, year
	call	CalcDayOfWeek			; calculate the day of week
	push	cx				; save this information

	; Find the starting date
	;
	cmp	cl, 6				; is today a Saturday
	je	stuffStart			; if yes, jump
	sub	cl, 1				; sets carry flag
	jl	calcFirst			; if negative (Sunday) jump
	mov	ch, 5
	sub	ch, cl
	mov	cl, ch
calcFirst:
	mov	al, cl				; byte value => AL
	cbw					; covert it to a word
	mov	cx, ax				; want value in CX
	call	CalcDateAltered			; calculate the altered date

	; Stuff the start date
stuffStart:
	pop	ax				; DOW => AX
	mov	{word} ss:[bx].RS_startDay, dx
	mov	ss:[bx].RS_startYear, bp
	pop	dx, bp				; restore orig M/D, year
	
	; Now find the ending date
	;
	tst	al				; was today Sunday ?
	jz	stuffEnd			; yes, so do nothing.
	mov	cl, 7
	sub	cl, al
	clr	ch
	call	CalcDateAltered			; calculate date of Sunday

	; Stuff the end date
stuffEnd:
	mov	{word} ss:[bx].RS_endDay, dx
	mov	ss:[bx].RS_endYear, bp
	mov	cx, 2				; two days in a weekend
	ret
QuickWeekend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickMonth
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the RangeStruct to display today

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range

DESTROYED:	DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/6/90		Changed passed arguments
	Don	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickMonth	proc	near

	; Get days in this month
	;
	call	CalcDaysInMonth			; get number of days in month
	mov	cl, ch
	clr	ch				; days in range to CX

	; Now set up the range structure
	;
	mov	dl, 1
	mov	{word} ss:[bx].RS_startDay, dx
	mov	dl, cl
	mov	{word} ss:[bx].RS_endDay, dx
	mov	ss:[bx].RS_startYear, bp
	mov	ss:[bx].RS_endYear, bp
	ret
QuickMonth	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickQuarter
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the RangeStruct to display today

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range

DESTROYED:	AX, DX, BP

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	5/6/90		Changed passed arguments
	Don	11/17/89	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickQuarter	proc	near

	; Determine which quarter we're in
	;
	mov	ah, 1				; start with January
	mov	cx, 4				; loop up to four times
quarterLoop:
	add	ah, 3
	cmp	dh, ah
	jl	doneLoop
	loop	quarterLoop
doneLoop:
	mov	dh, ah
	sub	dh, 3				; first month in quarter => DH

	; Call other routine to do our work for us
	;
	call	QuickMonth			; calculate 1st month
	mov	ax, cx
	push	{word} ss:[bx].RS_startDay	; save start month/day
	inc	dh
	call	QuickMonth			; calculate 2nd month
	add	ax, cx
	inc	dh
	call	QuickMonth			; calculate 3rd month
	add	cx, ax				; total days => CX
	pop	{word} ss:[bx].RS_startDay	; restore start month/day
	ret
QuickQuarter	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff the RangeStruct to display this year

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	3/12/91		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickYear	proc	near

	; Set up the range structure
	;
	mov	{word} ss:[bx].RS_startDay, JAN_1
	mov	{word} ss:[bx].RS_endDay, DEC_31
	mov	ss:[bx].RS_startYear, bp
	mov	ss:[bx].RS_endYear, bp

	; Return the proper number of days
	;
	mov	cx, 365				; assume not a leap year
	call	IsLeapYear			; sets/clears carry flag
	jnc	done				; jump if not leap year
	inc	cx
done:
	ret
QuickYear	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickGoto
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quickly go to a specific date

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range (0 if error)

DESTROYED:	AX, DX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickGoto	proc	near
	.enter

	; Go grab the date from the date picker...
	;
	mov	ax, MSG_PTDC_GET_DATE
	GetResourceHandleNS	QuickGotoDateCtrl, bx
	mov	si, offset QuickGotoDateCtrl
	call	ObjMessage_common_call
		
	; ...and now store that information away
	;
	mov	{word} ss:[bx].RS_startDay, cx
	mov	{word} ss:[bx].RS_endDay, cx
	mov	ss:[bx].RS_startYear, dx
	mov	ss:[bx].RS_endYear, dx
	mov	cx, 1				; single day

	.leave
	ret
QuickGoto	endp

CalendarTimeDateControlIgnore	method dynamic	CalendarTimeDateControlClass,
						MSG_PTDC_SET_DATE,
						MSG_PTDC_SET_TIME
	; Do nothing to make sure the system time & date are not touched
	;
	ret
CalendarTimeDateControlIgnore	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		QuickPrevious
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Quickly go to the previous selection

CALLED BY:	QuickView

PASS:		DS, ES	= DGroup
		SS:BX	= RangeStruct
		BP	= Year
		DX	= Month/Day

RETURN:		CX	= Days in range

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

QuickPrevious	proc	near
	.enter
	
	; Ask the YearObject for the old selection
	;
	mov	ax, MSG_YEAR_GET_SELECTION
	mov	cx, YRT_PREVIOUS
	mov	dx, ss
	mov	bp, bx				; RangeStruct => DX:BP
	mov	di, mask MF_CALL
	call	ObjMessage_year_common		; # of days in range => CX
	mov	bx, bp				; RangeStruct => SS:BX	
	tst	ss:[bx].RS_startYear		; check start year
	jnz	done				; ...and if non-zero, we're OK
	clr	cx				; else no previous day
done:
	.leave
	ret
QuickPrevious	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_year_common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to the YearObject via ObjMessage

CALLED BY:	INTERNAL - CommonCode

PASS:		AX	 = Message to send
		CX,DX,BP = Data
		DI	 = MessageFlags

RETURN:		see ObjMessage

DESTROYED:	see ObjMessage

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	10/16/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_year_common	proc	near
	GetResourceHandleNS	Interface, bx
	mov	si, offset Interface:YearObject		; BX:SI = object
	GOTO	ObjMessage_common
ObjMessage_year_common	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ObjMessage_common
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Near varieties of the most popular ObjMessage calls.

CALLED BY:	INTERNAL
	
PASS:		BX:SI	= Object
		AX	= Method to send
		CX, DX, BP	= Data
		DI	= MessageFlags (for ObjMessage_common only)

RETURN:		Same as ObjMessage

DESTROYED:	Same as ObjMessage

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	7/24/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ObjMessage_common_forceQueue	proc	near
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage_common
ObjMessage_common_forceQueue	endp

ObjMessage_common_send	proc	near
	clr	di
	GOTO	ObjMessage_common
ObjMessage_common_send	endp

ObjMessage_common_call	proc	near
	mov	di, mask MF_CALL or mask MF_FIXUP_DS or mask MF_FIXUP_ES
	FALL_THRU	ObjMessage_common
ObjMessage_common_call	endp

ObjMessage_common	proc	near
	call	ObjMessage
	ret
ObjMessage_common	endp


CommonCode	ends



ObscureCode	segment	resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarRequestSearch
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Respond to external search requests

CALLED BY:	GLOBAL

PASS:		DS, ES	= DGroup
		CX	= Length of text string
		DX	= Block handle containing text
		
RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI, SE

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version
	Don	3/17/90		Added real search code
	Don	6/11/90		Added dialog box when no file is present

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarRequestSearch	method	GeoPlannerClass,
				MSG_CALENDAR_REQUEST_SEARCH
	.enter

	; If no file open, display warning box
	;
	tst	dx				; ensure we have a valid block
	jz	done				; if not, jump
	test	es:[systemStatus], SF_EXITING	; are we leaving soon?
	jnz	done				; yes, so abort
	test	es:[systemStatus], SF_VALID_FILE
	jz	noFile				; jump if no calendar file
	test	es:[features], mask CF_DO_SEARCH
	jz	done				; if no search, ignore request
	push	cx, dx				; save the text block handle

	;
	; Bring ourselves to the fore in a way that ensures nice transfer
	; of target & focus, and de-iconifies our primary, too.
	; 
	mov	ax, MSG_META_NOTIFY_TASK_SELECTED
	call	UserCallApplication
	
	mov	ax, MSG_GEN_BRING_TO_TOP
	call	UserCallApplication

	; Bring up the search dialog box, and initiate the search
	;
	pop	bx				; text block handle => BX
	call	MemLock				; lock the block
	mov_tr	dx, ax				; segment to DX
	clr	bp				; DX:BP points to the text
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	CalendarSearch, bx
	mov	si, offset CalendarSearch
	call	ObjMessage_obscure_send

	pop	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjMessage_obscure_record	; recorded event => DI
	mov	bp, di				; event handle => BP
	mov	ax, MSG_SRC_SEND_EVENT_TO_SEARCH_TEXT
	call	ObjMessage_obscure_send

	mov	ax, MSG_SRC_FIND_NEXT
	call	ObjMessage_obscure_call
done:
	.leave
	ret					; we're done

	; Display the "no file" error message
noFile:
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	call	GeodeGetProcessHandle		; get the process handle
	mov	bp, CAL_ERROR_NO_FILE		; put up "no file" error box
	call	ObjMessage_obscure_send		; send the method on
	jmp	done				; and we're done
CalendarRequestSearch	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CalendarSearchGeoDex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send off a search request to the GeoDex

CALLED BY:	UI (MSG_CALENDAR_SEARCH_GEODEX)

PASS:		DS, ES	= DGroup

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/27/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

CalendarSearchGeoDex	method	dynamic	GeoPlannerClass,
					MSG_CALENDAR_SEARCH_GEODEX

	; Get the target object
	;
	GetResourceHandleNS	DPResource, bx
	mov	si, offset DPResource:DayPlanObject
	mov	ax, MSG_META_GET_TARGET_EXCL
	call	ObjMessage_obscure_call		; send the method
	mov	bx, cx
	mov	si, dx				; target object's OD => BX:SI
	mov	ax, MSG_META_GET_CLASS
	call	ObjMessage_obscure_call		; class of target => CX:DX
	mov	ax, es
	cmp	ax, cx				; compare Class segments
	jne	done				; abort if not equal
	cmp	dx, offset MyTextClass		; compare Class offsets
	jne	done

	; Ask the MyTextObject for its selected text
	;
	mov	dx, size VisTextGetTextRangeParameters
	sub	sp, dx
	mov	bp, sp				; structure => SS:BP
	mov	ss:[bp].VTGTRP_range.VTR_start.low, 0
	mov	ss:[bp].VTGTRP_range.VTR_start.high, VIS_TEXT_RANGE_SELECTION
	movdw	ss:[bp].VTGTRP_range.VTR_end, TEXT_ADDRESS_PAST_END
	mov	ss:[bp].VTGTRP_textReference.TR_type, TRT_BLOCK
	mov	ss:[bp].VTGTRP_flags, mask VTGTRF_ALLOCATE
	mov	ax, MSG_VIS_TEXT_GET_TEXT_RANGE	; get the selected text
	mov	di, mask MF_STACK or mask MF_CALL
	call	ObjMessage_obscure		; # of characters => AX
						; block holding text => CX
	add	sp, size VisTextGetTextRangeParameters
	tst	ax				; any text ??
	jz	done				; nope, so we're done

	; Now send the stuff to the GeoDex
	;
	call	CallGeoDex
	jnc	done				; if method sent OK, we're done
	call	GeodeGetProcessHandle		; process handle => BX
	mov	ax, MSG_CALENDAR_DISPLAY_ERROR
	mov	bp, CAL_ERROR_NO_GEODEX		; CalErrorValue
	call	ObjMessage_obscure_send		; do the dirty work
done:
	ret
CalendarSearchGeoDex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CallGeoDex
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Call the rolodex with the given method

CALLED BY:	INTERNAL

PASS: 		AX	= Text length
		CX	= Text block handle

RETURN:		Nothing

DESTROYED:	BX, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		none

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/25/90		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

geodexToken 	GeodeToken	ROLODEX_TOKEN

CallGeoDex	proc	near
	.enter

	; Create a launch block so IACP can launch the app if it's not
	; around yet.
	; 
	push	ax, cx			; save text parameters
	mov	dx, MSG_GEN_PROCESS_OPEN_APPLICATION
	call	IACPCreateDefaultLaunchBlock
	;
	; Set ALF_DESK_ACCESSORY to match our own.
	; 
	mov	bx, dx
	mov	ax, MSG_GEN_APPLICATION_GET_LAUNCH_FLAGS
	call	UserCallApplication
	andnf	ax, mask ALF_DESK_ACCESSORY
	mov_tr	dx, ax
	call	MemLock
	mov	es, ax
	ornf	es:[ALB_launchFlags], dl
	call	MemUnlock

	; Connect to all GeoDex apps currently functional, using our
	; application object as the client OD
	; 
	segmov	es, cs
	mov	di, offset geodexToken
	mov	ax, IACPSM_USER_INTERACTIBLE shl offset IACPCF_SERVER_MODE
	call	IACPConnect
	mov	ax, cx			; # of connections => AX
	pop	cx, bx			; restore text parameters
	jc	error

	; Initialize reference count for block to be the number of servers
	; to which we're connected so we can free the block when they're all
	; done. Then record the message we're going to send.
	; 
	call	MemInitRefCount
	mov	dx, bx			; text handle => DX
	mov	ax, MSG_ROLODEX_REQUEST_SEARCH
	clr	bx, si			; any class acceptable
	call	ObjMessage_obscure_record
	push	di			; save handle

	; Record completion message for nuking text block
	; 
	call	GeodeGetProcessHandle
	mov	ax, MSG_META_DEC_BLOCK_REF_COUNT
	clr	cx			; no block in cx (block is in dx)
	call	ObjMessage_obscure_record

	; Finally, send the message through IACP
	;
	mov	cx, di			; cx <- completion msg
	pop	bx			; bx <- msg to send
	mov	dx, TO_PROCESS		; dx <- TravelOption
	mov	ax, IACPS_CLIENT	; ax <- side doing the send
	call	IACPSendMessage

	; That's it, we're done.  Shut down the connection we opened up, so
	; that GeoDex is allowed to exit.  -- Doug 2/93
	;
	clr	cx, dx			; shutting down the client
	call	IACPShutdown

	clc	
done:
	.leave
	ret

	; There was an error, so delete the text and return carry set
error:
	call	MemFree
	stc
	jmp	done
CallGeoDex	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayErrorBox
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the calendar error box!!

CALLED BY:	GLOBAL (MSG_CALENDAR_DISPLAY_ERROR) or directly

PASS:		ES	= DGroup
		BP	= CalErrorValue
		CX:DX	= Possible data for first string argument
		BX:SI	= Possible data for second string argument

RETURN:		AX	= InteractionCommand from error box

DESTROYED:	BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Must be running in the calendar thread!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/3/90		Initial version
	Don	7/17/90		Added support for string arguments

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayErrorBox	method	GeoPlannerClass,	MSG_CALENDAR_DISPLAY_ERROR
	uses	bp, ds
	.enter

	; Some set-up work
	;
	test	es:[systemStatus], SF_DISPLAY_ERRORS
	jz	done				; jump to not display errors
	push	bx, si				; save second string arguments
	mov	bx, handle ErrorBlock
	call	MemLock		; lock the block
	mov	ds, ax				; set up the segment
	mov	si, offset ErrorBlock:ErrorArray ; handle of error messages 
	mov	si, ds:[si]			; dereference the handle
EC <	cmp	bp, CalErrorValue					>
EC <	ERROR_GE	DISPLAY_ERROR_BAD_ERROR_VALUE			>

	; Put up the error box (always warning for now)
	;
	add	si, bp				; go to the correct messages
	mov	ax, ds:[si+2]			; custom values => AX
	mov	di, ds:[si]			; text handle => DI
	mov	di, ds:[di]			; error string in DS:DI
	pop	bx, si				; restore second string args
	sub	sp, size StandardDialogParams
	mov	bp, sp
	mov	ss:[bp].SDP_customFlags, ax
	mov	ss:[bp].SDP_customString.segment, ds
	mov	ss:[bp].SDP_customString.offset, di
	mov	ss:[bp].SDP_stringArg1.segment, cx
	mov	ss:[bp].SDP_stringArg1.offset, dx
	mov	ss:[bp].SDP_stringArg2.segment, bx
	mov	ss:[bp].SDP_stringArg2.offset, si
	clr	ss:[bp].SDP_helpContext.segment
	call	UserStandardDialog		; put up the dialog box

	; Clean up
	;
	mov	bx, handle ErrorBlock		; block handle to BX
	call	MemUnlock			; unlock the block
done:
	.leave
	ret
DisplayErrorBox	endp

ObjMessage_obscure_record	proc	near
	mov	di, mask MF_RECORD
	GOTO	ObjMessage_obscure
ObjMessage_obscure_record	endp

ObjMessage_obscure_send	proc	near
	clr	di				; no MessageFlags => DI
	GOTO	ObjMessage_obscure
ObjMessage_obscure_send	endp

ObjMessage_obscure_call	proc	near
	mov	di, mask MF_CALL		; MessageFlags => DI
	FALL_THRU	ObjMessage_obscure
ObjMessage_obscure_call	endp

ObjMessage_obscure	proc	near
	call	ObjMessage			; send the message
	ret
ObjMessage_obscure	endp



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerDispatchEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To handle a synchronization problem with geodex,
		we need to make sure that the completion message going
		back to geodex gets put on our queue.
		(When there is a password on the document, the completion 
		message was going through, while the IACP message was being
		held up)

CALLED BY:	MSG_META_DISPATCH_EVENT
PASS:		*ds:si	= GeoPlannerClass object
		ds:di	= GeoPlannerClass instance data
		ds:bx	= GeoPlannerClass object (same as *ds:si)
		es 	= segment of GeoPlannerClass
		ax	= message #
		cx	= handle of event
		dx 	= MessageFlags to pass to ObjDispatchMessage

RETURN:		If MF_CALL specified:
			carry, ax, cx, dx, bp - return values
		Otherwise:
			ax, cx, dx, bp - destroyed
		(event freed)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	7/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
GeoPlannerDispatchEvent	method dynamic GeoPlannerClass, 
					MSG_META_DISPATCH_EVENT
	;
	; Should we hold up this message on the queue?	

	mov	bx, cx				; event handle
	call	ObjGetMessageInfo
	mov	cx, bx				; cx = event handle
	cmp	ax, MSG_META_DEC_BLOCK_REF_COUNT
	je	sendAgain

	;
	; Send to super
	;
callSuper::
	mov	ax, MSG_META_DISPATCH_EVENT
	mov	di, offset GeoPlannerClass
	GOTO	ObjCallSuperNoLock

sendAgain:
	mov	ax, MSG_CALENDAR_DISPATCH_EVENT
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	GOTO	ObjMessage

GeoPlannerDispatchEvent	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GeoPlannerDispatchEvent
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Routine to use for synchronization purposes.
		We need to make sure that the completion routine
		sent from IACP happens after the initial routine is called.
		Therfore we use the routine to stick the message back
		in the queue.

CALLED BY:	MSG_CALENDAR_DISPATCH_EVENT
PASS:		*ds:si	= GeoPlannerClass object
		ds:di	= GeoPlannerClass instance data
		ds:bx	= GeoPlannerClass object (same as *ds:si)
		es 	= segment of GeoPlannerClass
		ax	= message #
		cx	= handle of event
		dx 	= MessageFlags to pass to ObjDispatchMessage

RETURN:		If MF_CALL specified:
			carry, ax, cx, dx, bp - return values
		Otherwise:
			ax, cx, dx, bp - destroyed
		(event freed)
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	RB	7/29/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CalendarDispatchEvent	method dynamic GeoPlannerClass, 
					MSG_CALENDAR_DISPATCH_EVENT

		mov	ax, MSG_META_DISPATCH_EVENT
		mov	di, offset GeoPlannerClass
		GOTO	ObjCallSuperNoLock

CalendarDispatchEvent	endm

ObscureCode	ends




