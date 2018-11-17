
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1997.  All rights reserved.
	GEOWORKS CONFIDENTIAL

PROJECT:	PC GEOS
MODULE:		Calendar\Main
FILE:		mainMenu.asm

AUTHOR:		Ken Liu, Feb  6, 1997

ROUTINES:
	Name			Description
	----			-----------
    MTD MSG_CALENDAR_MENU_UPDATE_SETTINGS
				This update message is called every time
				the planner view is changed. The menu
				settings are default as month view.

    MTD MSG_CALENDAR_MENU_SWITCH_PLANNER_VIEW
				It is THE routine which handles all
				switching of Planner Views.

    MTD MSG_CALENDAR_MENU_CLOSE_DAYVIEW
				It handles the case when dayview is closed,
				it will drop back to the previous view.

    MTD MSG_CALENDAR_MENU_GET_CUR_PLANNER_VIEW
				Returns the current PlannerViewType

    MTD MSG_CALENDAR_MENU_GET_PREV_PLANNER_VIEW
				Returns the previous PlannerViewType

    MTD MSG_ASLT_VISIBILITY_LOST_GAINED
				Load or save to .ini file when visibility
				of the object changes.

 ?? INT LoadSaveInitFile	Do the actual loading and saving given the
				right category and key strings.

    MTD MSG_META_CLIPBOARD_CUT	Intercepted to prevent cut and copy.

    MTD MSG_DAT_VISIBILITY_LOST_GAINED
				To load or save to ini file as visibility
				of the object changes.

    MTD MSG_DAT_VALID_CHECK	

 ?? INT InvalidDefaultAlarm	Open dialog box to warn user that the
				default alarm should be less than the
				MAX_ALARM_MINUTES

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 6/97   	Initial revision


DESCRIPTION:
		
	Contains object class which is used inside calendar menu.

	$Id: mainMenu.asm,v 1.1 97/04/04 14:48:24 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

if	MAIN_MENU

idata	segment
	CalendarMenuClass
	AutoSaveLoadTextClass
	DefaultAlarmTextClass

	calendarCategory	char	CALENDAR_PASSWD_INIT_CATEGORY, 0
if	_REMOTE_CALENDAR
	passwdInitKey	char	"remotePass", 0
else
	passwdInitKey	char	CALENDAR_PASSWD_INIT_KEY, 0
endif
	defaultAlarmKey	char	"defaultAlarm", 0
idata	ends

CalendarMenuCode	segment resource


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMCalendarMenuUpdateSettings
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	This update message is called every time the planner view is
		changed. The menu settings are default as month view.

CALLED BY:	MSG_CALENDAR_MENU_UPDATE_SETTINGS
PASS:		*ds:si	= CalendarMenuClass object
		ds:di	= CalendarMenuClass instance data
		ds:bx	= CalendarMenuClass object (same as *ds:si)
		es 	= segment of CalendarMenuClass
		ax	= message #
		ch	= Current PlannerViewType
		cl	= previous PlannerViewType
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	1/29/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMCalendarMenuUpdateSettings	method dynamic CalendarMenuClass, 
					MSG_CALENDAR_MENU_UPDATE_SETTINGS
		.enter

		cmp	ch, cl		; same view?
		je	done

		push	cx		; save for enabling
	;
	;	First check previous view.
	;
		cmp	cl, PVT_MONTH
		je	disableMonth
		cmp	cl, PVT_WEEK
		je	disableWeek
		cmp	cl, PVT_DAY
		je	disableDay
EC <		ERROR_NE	PLANNER_VIEW_BAD_ENUM			>
		
disableMonth:
	;
	;	First need to re-enable the Month View button since we are
	;	no longer in month view.
	;

		mov	ax, MSG_GEN_SET_ENABLED
		GetResourceHandleNS	MenuMonthViewTrigger, bx
		mov	si, offset MenuMonthViewTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		
		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS	MenuNextMonthTrigger, bx
		mov	si, offset MenuNextMonthTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS	MenuPrevMonthTrigger, bx
		mov	si, offset MenuPrevMonthTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		jmp	enable


disableWeek:
		mov	ax, MSG_GEN_SET_ENABLED
		GetResourceHandleNS	MenuWeekViewTrigger, bx
		mov	si, offset MenuWeekViewTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS	MenuNextWeekTrigger, bx
		mov	si, offset MenuNextWeekTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS	MenuPrevWeekTrigger, bx
		mov	si, offset MenuPrevWeekTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		jmp	enable

disableDay:
		
		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS	MenuNextDayTrigger, bx
		mov	si, offset MenuNextDayTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_SET_NOT_USABLE
		GetResourceHandleNS	MenuPrevDayTrigger, bx
		mov	si, offset MenuPrevDayTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

enable:
		pop	cx

	;
	;	Now do set up for current view
	;
		cmp	ch, PVT_MONTH
		je	enableMonth
		cmp	ch, PVT_WEEK
		je	enableWeek
		cmp	ch, PVT_DAY
		je	enableDay
EC <		ERROR_NE	PLANNER_VIEW_BAD_ENUM			>

enableMonth:

	;	
	;	First do the MonthViewTrigger, disable it since we are in
	;	month view
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		GetResourceHandleNS	MenuMonthViewTrigger, bx
		mov	si, offset MenuMonthViewTrigger
		mov	dl, VUM_NOW
		clr	di			
		call	ObjMessage

		mov	ax, MSG_GEN_SET_USABLE
		GetResourceHandleNS	MenuNextMonthTrigger, bx
		mov	si, offset MenuNextMonthTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_SET_USABLE
		GetResourceHandleNS	MenuPrevMonthTrigger, bx
		mov	si, offset MenuPrevMonthTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		jmp	done

enableWeek:
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		GetResourceHandleNS	MenuWeekViewTrigger, bx
		mov	si, offset MenuWeekViewTrigger
		mov	dl, VUM_NOW
		clr	di			
		call	ObjMessage

		mov	ax, MSG_GEN_SET_USABLE
		GetResourceHandleNS	MenuNextWeekTrigger, bx
		mov	si, offset MenuNextWeekTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_SET_USABLE
		GetResourceHandleNS	MenuPrevWeekTrigger, bx
		mov	si, offset MenuPrevWeekTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
		jmp	done

enableDay:

		mov	ax, MSG_GEN_SET_USABLE
		GetResourceHandleNS	MenuNextDayTrigger, bx
		mov	si, offset MenuNextDayTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage

		mov	ax, MSG_GEN_SET_USABLE
		GetResourceHandleNS	MenuPrevDayTrigger, bx
		mov	si, offset MenuPrevDayTrigger
		mov	dl, VUM_NOW
		clr	di
		call	ObjMessage
done:
	.leave
	ret
CMCalendarMenuUpdateSettings	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMCalendarMenuSwitchPlannerView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It is THE routine which handles all switching of
		Planner Views.

CALLED BY:	MSG_CALENDAR_MENU_SWITCH_PLANNER_VIEW
PASS:		*ds:si	= CalendarMenuClass object
		ds:di	= CalendarMenuClass instance data
		ds:bx	= CalendarMenuClass object (same as *ds:si)
		es 	= segment of CalendarMenuClass
		ax	= message #
		cl	= PlannerViewType to switch to
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 4/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMCalendarMenuSwitchPlannerView	method dynamic CalendarMenuClass, 
					MSG_CALENDAR_MENU_SWITCH_PLANNER_VIEW
		.enter

		mov	ch, cl				; ch = new view
		mov	cl, ds:[di].CMI_curPlannerView	; cl = original view

		cmp	cl, ch
EC <		WARNING_Z REQUESTED_VIEW_IS_CURRENT_VIEW
		jz	done			; we are there already

		mov	ds:[di].CMI_prevPlannerView, cl
		mov	ds:[di].CMI_curPlannerView, ch

		push	cx
		mov	ax, MSG_CALENDAR_MENU_UPDATE_SETTINGS
		call	ObjCallInstanceNoLock
		pop	cx
		
		cmp	cl, PVT_DAY
		je	fromDayView
		cmp	cl, PVT_WEEK
		je	fromWeekView
		cmp	cl, PVT_MONTH
		je	fromMonthView
EC <		ERROR_NE PLANNER_VIEW_BAD_ENUM
NEC <		jmp	done

fromMonthView:
		cmp	ch, PVT_DAY
		je	monthToDay
		cmp	ch, PVT_WEEK
		je	monthToWeek
EC <		ERROR_NE PLANNER_VIEW_BAD_ENUM
NEC <		jmp	done

monthToDay:
	;
	;	Do initiate for MY_GEN_INTERACTION
	;
		mov	ax, MSG_MY_GEN_INTERACTION_INITIATE
		GetResourceHandleNS	CalendarRight, bx
		mov	si, offset CalendarRight
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		jmp	done

monthToWeek:
	;
	;	When changing from monthView to weekView, update flag for
	;	WeekView should be set to RESET so that it will reset
	;	to 8am or earlier event.
	;
		mov	cx, WVF_RESET
		mov	ax, MSG_WVI_SET_UPDATE_FLAG
		GetResourceHandleNS	WeekViewGroup, bx
		mov	si, offset WeekViewGroup
		clr	di
		call	ObjMessage
	;	
	;
	;
	;	Just initiate the weekView dialog
	;
		mov	ax, MSG_GEN_INTERACTION_INITIATE
		GetResourceHandleNS	WeekViewGroup, bx
		mov	si, offset	WeekViewGroup
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
		jmp	done

fromWeekView:
		cmp	ch, PVT_MONTH
		je	weekToMonth
		cmp	ch, PVT_DAY
		je	weekToDay
EC <		ERROR_NE PLANNER_VIEW_BAD_ENUM
NEC <		jmp	done

weekToDay:		
weekToMonth:
	;
	;	Just close the weekview dialog itself
	;
		push	cx
		mov	ax, MSG_WVI_WEEK_VIEW_END
		GetResourceHandleNS	WeekViewGroup, bx
		mov	si, offset	WeekViewGroup
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage

		pop	cx
		cmp	ch, PVT_DAY
		je	monthToDay
		jmp	done

fromDayView:
		cmp	ch, PVT_MONTH
		je	dayToMonth
		cmp	ch, PVT_WEEK
		je	dayToWeek
EC <		ERROR_NE PLANNER_VIEW_BAD_ENUM
NEC <		jmp	done

dayToWeek:
	;
	;	We need special handling for switching from day to week,
	;	since we have to set the correct y position. The problem
	;	is DayPlanObject is on process thread, but not the
	;	CalendarMenu nor the WeekSchedule/View objects. A hack
	;	but why not just let DayPlanObject do the initiation
	;	job for weekview. (kliu --3/21/97)
	;
		mov	ax, MSG_DP_INITIATE_WEEK_VIEW
		GetResourceHandleNS	DayPlanObject, bx
		mov	si, offset DayPlanObject
		clr	di
		call	ObjMessage
		jmp	done
dayToMonth:
	;
	;	Just close the day view itself, currently not using.
	;
		mov	ax, MSG_MY_GEN_INTERACTION_DISMISS
		GetResourceHandleNS	CalendarRight, bx
		mov	si, offset CalendarRight
		mov	di, mask MF_FIXUP_DS
		call	ObjMessage
done:
		.leave
		ret
CMCalendarMenuSwitchPlannerView	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMCalendarMenuCloseDayView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	It handles the case when dayview is closed, it will
		drop back to the previous view.

CALLED BY:	MSG_CALENDAR_MENU_CLOSE_DAYVIEW
PASS:		*ds:si	= CalendarMenuClass object
		ds:di	= CalendarMenuClass instance data
		ds:bx	= CalendarMenuClass object (same as *ds:si)
		es 	= segment of CalendarMenuClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 4/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMCalendarMenuCloseDayView	method dynamic CalendarMenuClass, 
					MSG_CALENDAR_MENU_CLOSE_DAYVIEW
	.enter
		mov	cl, ds:[di].CMI_prevPlannerView
		mov	ax, MSG_CALENDAR_MENU_SWITCH_PLANNER_VIEW
		call	ObjCallInstanceNoLock
	.leave
	ret
CMCalendarMenuCloseDayView	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMCalendarMenuGetCurPlannerView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the current PlannerViewType

CALLED BY:	MSG_CALENDAR_MENU_GET_CUR_PLANNER_VIEW
PASS:		*ds:si	= CalendarMenuClass object
		ds:di	= CalendarMenuClass instance data
		ds:bx	= CalendarMenuClass object (same as *ds:si)
		es 	= segment of CalendarMenuClass
		ax	= message #
RETURN:		cl	= current PlannerViewType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 4/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMCalendarMenuGetCurPlannerView	method dynamic CalendarMenuClass, 
					MSG_CALENDAR_MENU_GET_CUR_PLANNER_VIEW
	.enter
		mov	cl, ds:[di].CMI_curPlannerView
	.leave
	ret
CMCalendarMenuGetCurPlannerView	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		CMCalendarMenuGetPrevPlannerView
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Returns the previous PlannerViewType

CALLED BY:	MSG_CALENDAR_MENU_GET_PREV_PLANNER_VIEW
PASS:		*ds:si	= CalendarMenuClass object
		ds:di	= CalendarMenuClass instance data
		ds:bx	= CalendarMenuClass object (same as *ds:si)
		es 	= segment of CalendarMenuClass
		ax	= message #
RETURN:		cl	= previous PlannerViewType
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	awu     	2/13/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
CMCalendarMenuGetPrevPlannerView	method dynamic CalendarMenuClass, 
					MSG_CALENDAR_MENU_GET_PREV_PLANNER_VIEW
	.enter
		mov	cl, ds:[di].CMI_prevPlannerView
	.leave
	ret
CMCalendarMenuGetPrevPlannerView	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ASLTVisibilityLostGained
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Load or save to .ini file when visibility of the object changes.

CALLED BY:	MSG_ASLT_VISIBILITY_LOST_GAINED
PASS:		*ds:si	= AutoSaveLoadTextClass object
		ds:di	= AutoSaveLoadTextClass instance data
		ds:bx	= AutoSaveLoadTextClass object (same as *ds:si)
		es 	= segment of AutoSaveLoadTextClass
		ax	= message #
		bp	= open or close(0)
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 5/97   	
					
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ASLTVisibilityLostGained	method dynamic AutoSaveLoadTextClass, 
					MSG_ASLT_VISIBILITY_LOST_GAINED
	.enter

	;
	; Setup category & key pointers
	;
		movdw	esdi, dssi
		GetResourceSegmentNS	dgroup, ds
		mov	cx, ds
		mov	si, offset calendarCategory	; ds:si = category
		mov	dx, offset passwdInitKey	; cx:dx = key
		call	LoadSaveInitFile
	.leave
	ret
ASLTVisibilityLostGained	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		LoadSaveInitFile
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Do the actual loading and saving given the right category and key
		strings.

CALLED BY:	ASLTVisibilityLostGained, DATVisibilityLostGained
PASS:		es:di	= text object
		ds:si	= Category string
		cx:dx	= key string
		bp	= load or save(0)
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 7/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
LoadSaveInitFile	proc	near

glFlag	local	word	push	bp
thisObject	local	dword

		uses es, ds, di, si, ax, cx, dx, bp
		.enter

		movdw	thisObject, esdi, ax
		tst	ss:[glFlag]
		jnz	open
	;
	; Closing: save the text to ini file
	;
		mov	di, es:[di]
		add	di, es:[di].Gen_offset
		mov	di, es:[di].GTXI_text
		mov	di, es:[di]			; es:di = text

		call	InitFileWriteString
		call	InitFileCommit
		jmp	done
	;
	; Opening: load text from ini file
	;
open:		
		push	bp				; save stack ptr
		clr	bp				; allocate
							; buffer, no conversion
		call	InitFileReadString		; bx -> memHandle
		pop	bp
		mov	ds, ss:[thisObject].high	; DONT MAKE IT CLEAR
		mov	si, ss:[thisObject].low		; CARRY FLAG
		jc	noPassword

		push	bp
		call	MemLock
		mov	dx, ax
		clr	bp				; dx:bp = text
		clr	cx
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	ObjCallInstanceNoLock
		call	MemFree
		jmp	doneOpen
noPassword:
		push	bp
		mov	ax, MSG_VIS_TEXT_DELETE_ALL
		call	ObjCallInstanceNoLock
doneOpen:
		pop	bp				; recover stack ptr
done:
	.leave
	ret
LoadSaveInitFile	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		ASLTCutCopy
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Intercepted to prevent cut and copy.

CALLED BY:	MSG_META_CLIPBOARD_CUT/COPY
PASS:		*ds:si	= AutoSaveLoadTextClass object
		ds:di	= AutoSaveLoadTextClass instance data
RETURN:		nothing
DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		Do nothing, just beep at the user.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	kliu	2/ 5/97         very shamelessly copy from reza's security

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ASLTCutCopy	method dynamic AutoSaveLoadTextClass, 
					MSG_META_CLIPBOARD_CUT,
					MSG_META_CLIPBOARD_COPY
		mov	ax, SST_NO_INPUT
		call	UserStandardSound
		ret
ASLTCutCopy	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATVisibilityLostGained
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	To load or save to ini file as visibility of the object
		changes.

CALLED BY:	MSG_DAT_VISIBILITY_LOST_GAINED
PASS:		*ds:si	= DefaultAlarmTextClass object
		ds:di	= DefaultAlarmTextClass instance data
		ds:bx	= DefaultAlarmTextClass object (same as *ds:si)
		es 	= segment of DefaultAlarmTextClass
		ax	= message #
		bp	= open or close
RETURN:		nothing
DESTROYED:	cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 7/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATVisibilityLostGained	method dynamic DefaultAlarmTextClass, 
		MSG_DAT_VISIBILITY_LOST_GAINED

		movdw	esdi, dssi
		GetResourceSegmentNS	dgroup, ds
		mov	cx, ds
		mov	si, offset calendarCategory
		mov	dx, offset defaultAlarmKey

		call	LoadSaveInitFile
		ret
DATVisibilityLostGained	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DATValidCheck
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_DAT_VALID_CHECK
PASS:		*ds:si	= DefaultAlarmTextClass object
		ds:di	= DefaultAlarmTextClass instance data
		ds:bx	= DefaultAlarmTextClass object (same as *ds:si)
		es 	= segment of DefaultAlarmTextClass
		ax	= message #
RETURN:		nothing
DESTROYED:	ax, cx, dx, bp
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 9/97   	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
DATValidCheck	method dynamic DefaultAlarmTextClass, 
					MSG_DAT_VALID_CHECK
		.enter
	mov	ax, MSG_VIS_TEXT_GET_ALL_BLOCK
	clr	dx
	call	ObjCallInstanceNoLock

	tst	ax
	jz	useDefault

	;
	;	Convert text to minutes
	;
	push	ds:[LMBH_handle]		; save block
	mov	bx, cx				; bx = text block
	call	MemLock	
	mov	ds, ax
	clr	di				; ds:di = string ptr
	call	LocalAsciiToFixed		; dx = number
	call	MemFree				; free text block
	pop	bx				; restore  block
	call	MemDerefDS			; restore ds	
	cmp	dx, MAX_ALARM_MINUTES
	jg	invalidPrecedeTime

closeDialog:
	;
	;	Now we can close the Settings Dialog
	;
	GetResourceHandleNS	SettingsDialog, bx
	mov	si, offset SettingsDialog
	mov	ax, MSG_GEN_INTERACTION_ACTIVATE_COMMAND
	mov	cx, IC_DISMISS
	clr	di
	call	ObjMessage
exit:
	
	.leave
	ret
invalidPrecedeTime:
	call	InvalidDefaultAlarm
	jmp	exit
		
useDefault:
	;
	;	User hasn't provided anything. Use the DEFAULT_ALARM_MINUTES, write to
	;	text object and let the visibility message handle the saving to ini file
	;
	clr	cx
	clr	ax
	mov	dx, DEFAULT_ALARM_MINUTES
	sub	sp, ALARM_PRECEDE_MINUTES_BUFFER_SIZE
	segmov	es, ss, di
	mov	di, sp
	call	LocalFixedToAscii		; es:di = "10"

	mov	dx, es
	mov	bp, di
clr	cx
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
	call	ObjCallInstanceNoLock
	add	sp, ALARM_PRECEDE_MINUTES_BUFFER_SIZE		
	jmp	closeDialog

DATValidCheck	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InvalidDefaultAlarm
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Open dialog box to warn user that the default alarm should be
		less than the MAX_ALARM_MINUTES

CALLED BY:	DATValidCheck
PASS:		ds	= DefaultAlarmTextClass segment
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		

REVISION HISTORY:
	Name		Date		Description
	----		----		-----------
	kliu    	2/ 7/97    	Initial version
	
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
InvalidDefaultAlarm	proc	near
	uses	ax,bx,cx,dx,si,di,bp
		.enter

	; Delete invalid alarm precede minutes text
	;
	mov	ax, MSG_VIS_TEXT_DELETE_ALL
	call	ObjCallInstanceNoLock

	; Reinitiate the alarm interaction.
	;
	mov	ax, MSG_GEN_INTERACTION_INITIATE
	GetResourceHandleNS	SettingsAlarmInt, bx
	mov	si, offset	SettingsAlarmInt
	mov	di, mask MF_FIXUP_DS 
	call	ObjMessage

	; Show error dialog
	;
	GetResourceHandleNS	PrecedeMinuteTooBigError, cx
	mov	dx, offset	PrecedeMinuteTooBigError
	call	FoamDisplayErrorNoBlock

	.leave
	ret
InvalidDefaultAlarm	endp


CalendarMenuCode	ends

endif	; MAIN_MENU
