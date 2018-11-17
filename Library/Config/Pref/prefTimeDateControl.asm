COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Geoworks 1993 -- All Rights Reserved

PROJECT:	PC GEOS
MODULE:		
FILE:		prefTimeDateControl.asm

AUTHOR:		Chris Boyke

ROUTINES:
	Name			Description
	----			-----------

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/19/93   	Initial version.

DESCRIPTION:
	

	$Id: prefTimeDateControl.asm,v 1.2 98/04/24 01:22:24 gene Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

include	timer.def
include timedate.def


MAX_TIME_TEXT_LENGTH_ON_STACK		equ	15


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlGetInfo
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get information about the Pref TimeDate controller

CALLED BY:	GLOBAL (MSG_GEN_CONTROL_GET_INFO)

PASS:		DS:*SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClassInstance
		CX:DX	= GenControlBuildInfo structure to fill

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DI, SI, BP, DS, ES

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	1/24/92		Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlGetInfo	method dynamic	PrefTimeDateControlClass,
					MSG_GEN_CONTROL_GET_INFO
		.enter

		; Copy the data into the structure
		;
		mov	ax, ds
		mov	bx, di			; instance data => AX:BX
		mov	bp, dx
		mov	es, cx
		mov	di, dx			; buffer to fill => ES:DI
		segmov	ds, cs
		mov	si, offset PTDC_dupInfo
		mov	cx, size GenControlBuildInfo
		rep	movsb

		.leave
		ret
PrefTimeDateControlGetInfo	endm

PTDC_dupInfo	GenControlBuildInfo		<
	mask GCBF_NOT_REQUIRED_TO_BE_ON_SELF_LOAD_OPTIONS_LIST, ; GCBI_flags
		PTDC_iniKey,			; GCBI_initFileKey
		PTDC_gcnList,			; GCBI_gcnList
		length PTDC_gcnList,		; GCBI_gcnCount
		PTDC_notifyList,		; GCBI_notificationList
		length PTDC_notifyList,		; GCBI_notificationCount
		0,				; GCBI_controllerName

		handle TimeDateControlUI,	; GCBI_dupBlock
		PTDC_childList,			; GCBI_childList
		length PTDC_childList,		; GCBI_childCount
		PTDC_featuresList,		; GCBI_featuresList
		length PTDC_featuresList,	; GCBI_featuresCount
		PTDC_DEFAULT_FEATURES,		; GCBI_features

		0,				; GCBI_toolBlock
		0,				; GCBI_toolList
		0,				; GCBI_toolCount
		0,				; GCBI_toolFeaturesList
		0,				; GCBI_toolFeaturesCount
		0,				; GCBI_toolFeatures
		PTDC_helpContext>		; GCBI_helpContext

PTDC_iniKey		char	"prefTimeDateControl", 0

PTDC_gcnList		GCNListType \
			<MANUFACTURER_ID_GEOWORKS, \
				GAGCNLT_APP_NOTIFY_DOC_SIZE_CHANGE>

PTDC_notifyList		NotificationType \
			<MANUFACTURER_ID_GEOWORKS, GWNT_SPOOL_DOC_OR_PAPER_SIZE>

ifdef DO_DOVE
PTDC_childList		GenControlChildInfo \
<offset DateTimeInteraction, mask PTDCF_DATE or mask PTDCF_TIME, 0>,
<offset TwelveTwentyFourGroup, mask PTDCF_TIME, mask GCCF_IS_DIRECTLY_A_FEATURE>
		

PTDC_featuresList	GenControlFeaturesInfo \
			<offset DateInteraction, 0, 0>,
			<offset TimeInteraction, 0, 0>
else
PTDC_childList		GenControlChildInfo \
<offset DateInteraction, mask PTDCF_DATE, mask GCCF_IS_DIRECTLY_A_FEATURE>,
<offset TimeInteraction, mask PTDCF_TIME, mask GCCF_IS_DIRECTLY_A_FEATURE>
		

PTDC_featuresList	GenControlFeaturesInfo \
			<offset TimeInteraction, 0, 0>,
			<offset DateInteraction, 0, 0>
endif	; DO_DOVE

PTDC_helpContext	char	"dbDate&Time", 0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlVisOpen
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the time/date screen

CALLED BY:	GLOBAL (MSG_ZC_SCREEN_INIT)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlVisOpen	method dynamic	PrefTimeDateControlClass,
						MSG_VIS_OPEN
		uses	ax, bp
		.enter
	;
	; Initialize the month list
	;
		mov	ax, MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
		mov	di, offset MonthList
		call	PrefObjMessageSend
	;
	; Look for vardata and reset minimum & maximum of
	; the DateValue object, if such vardata is found
	;
		mov	ax, ATTR_PREF_TIME_DATE_CONTROL_MINIMUM_YEAR
		call	ObjVarFindData
		jnc	checkMaximum
		mov	ax, MSG_GEN_VALUE_SET_MINIMUM
		call	sendDateValueMsg
checkMaximum:
		mov	ax, ATTR_PREF_TIME_DATE_CONTROL_MAXIMUM_YEAR
		call	ObjVarFindData
		jnc	doneVarData
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		call	sendDateValueMsg
doneVarData:		

	; Start a timer, unless one already exists
	;
		mov	di, ds:[si]
		add	di, ds:[di].PrefTimeDateControl_offset
		tst	ds:[di].PTDCI_timer.high
		LONG jnz	done
		mov	bp, di			; instance data => DS:BP
		mov	al, TIMER_EVENT_CONTINUAL
		mov	bx, ds:[LMBH_handle]	; OD => BX:SI
		mov	cx, 60			; ticks 'till first timeout
		mov	dx, MSG_PTDC_TIMER_TICK
		mov	di, 60			; once a second
		call	TimerStart		; handle & ID => BX:AX
		movdw	ds:[bp].PTDCI_timer, bxax

	; Initialize with the current date & time
	;
		call	PrefTimeDateControlTimerTick

ifndef DO_DOVE; DOVE uses hour range 00-23 and it's always usable, so skip this
	; Set the TimeAMPM {usable/not usable} based on time format
	;
		call	PrefTDCGetFeatures
		test	ax, mask PTDCF_TIME
		jz	skipAMPM
		call	TimerSetTimeAMPM
		call	InitTimezone
skipAMPM:
endif
		call	PrefTimeDateControlUpdateGenValues
done:
		.leave
		mov	di, offset PrefTimeDateControlClass
		GOTO	ObjCallSuperNoLock

	; Set the minimum or maximum of the DateValue object
	;
sendDateValueMsg:
		mov	dx, ds:[bx]
		cmp	dx, 1904
		jb	doneSend
		cmp	dx, 2099
		ja	doneSend
		clr	cx
		mov	di, offset DateYear
		call	PrefObjMessageSend
doneSend:
		retn
PrefTimeDateControlVisOpen	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlUpdateGenValues
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update the GenValues with the current date & time

CALLED BY:	PrefTimeDateControlVisOpen, PrefTimeDateControlReset

PASS:		*ds:si - PrefTimeDateControlClass

RETURN:		nothing 

DESTROYED:	ax,bx,cx,dx,si,di

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTimeDateControlUpdateGenValues	proc near
		
		class	PrefTimeDateControlClass

		.enter

ifdef DO_DOVE
	;	
	; Set the 12<>24 Hour GenItemGroup according to the ini setting.
	;
		push	ds, si			; save object
		segmov	ds, cs, si
		mov	si, offset time24Category
		mov	cx, cs
		mov	dx, offset time24Key
		call	InitFileReadInteger
		jnc	valueFound
		mov	ax, BW_TRUE		; default value if wasn't found
valueFound:
		pop	ds, si			; restore object

		clr	dx			; determinate
		mov	cx, ax
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	di, offset TwelveTwentyFourGroup
		call	PrefObjMessageCall
endif ; ifdef DO_DOVE

	; Get the current date/time
	;
		call	TimerGetDateAndTime	; data => AX, BX, CX, DX
		push	bx, ax, bx, cx, dx

	; Set time values
	;
		call	PrefTDCGetFeatures
		test	ax, mask PTDCF_TIME
		jz	skipTime
		mov	cl, dh
		mov	di, offset TimeSeconds
		call	GenValueSendByte

		pop	cx
		mov	di, offset TimeMinutes
		call	GenValueSendByte

		pop	cx			; hours => CH
		call	TimeSetHours		; set # of hours
	;
	; Set date values
	;
setDateValues:
		pop	cx
		mov	di, ds:[si]
		add	di, ds:[di].Pref_offset
		mov	ds:[di].PTDCI_month, cl
		dec	cl			;cl <- month 0-11
		clr	ch			;cx <- month 0-11
		mov	di, offset MonthList
		clr	dx			;not indeterminate
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		call	PrefObjMessageSend

		pop	cx
		mov	di, offset DateYear
		call	GenValueSend
		call	GenValueGetValue	;cx = actual year set, which
						; may be different due to
						; max/min constraints
		mov	di, ds:[si]
		add	di, ds:[di].Pref_offset
		mov	ds:[di].PTDCI_year, cx
	;
	; Set day last so it can do bounds checking based on month and year
	;
		pop	cx
		mov	cl, ch			;cl <- day
		mov	di, offset DayPicker
		mov	ax, MSG_PDP_SET_DAY
		call	PrefObjMessageCall

	;
	; update the timezone UI
	;

		.leave
		ret
skipTime:
		pop	ax, ax
		jmp	setDateValues
PrefTimeDateControlUpdateGenValues	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlReset
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	Restore the GenValues to the current system time

PASS:		*ds:si	- PrefTimeDateControlClass object
		ds:di	- PrefTimeDateControlClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	11/15/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlReset	method	dynamic	PrefTimeDateControlClass, 
					MSG_GEN_RESET

		call	PrefTimeDateControlUpdateGenValues
		ret
PrefTimeDateControlReset	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlVisClose
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Perform some work now that the time/date is correct

CALLED BY:	GLOBAL (MSG_VIS_CLOSE)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlVisClose	method dynamic	PrefTimeDateControlClass,
						MSG_VIS_CLOSE

		; Kill our timer
		;
		push	ax
		clrdw	bxax
		xchgdw	bxax, ds:[di].PTDCI_timer
		tst	bx
		jz	callSuper
		call	TimerStop		; kill the timer
	
		; Now call our superclass
callSuper:
		pop	ax
		mov	di, offset PrefTimeDateControlClass
		GOTO	ObjCallSuperNoLock
PrefTimeDateControlVisClose	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlTimerTick
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Another seocnd has gone by, so update time & date

CALLED BY:	GLOBAL (MSG_PTDC_TIMER_TICK)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlTimerTick	method 	PrefTimeDateControlClass,
					MSG_PTDC_TIMER_TICK
		.enter

		; Set the time & date strings
		;
ifdef NIKE_EUROPE
		mov	dx, DTF_HMS_24HOUR
else
		mov	dx, DTF_HMS
endif
		call	PrefTDCGetFeatures
		test	ax, mask PTDCF_TIME
		jz	done
		mov	di, offset TimeCurrent
		call	DateTimeToTextObject
done:
		.leave
		ret
PrefTimeDateControlTimerTick	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlMonthChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has changed the month

CALLED BY:	GLOBAL (MSG_PTDC_MONTH_CHANGE)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClass instance data
		cx	= new month (0-11)

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		PW	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlMonthChange method dynamic PrefTimeDateControlClass, 
						MSG_PTDC_MONTH_CHANGE

		mov	dl, cl				;dl <- month
		inc	dl				;dl <- month 1-12

		; If the month is different, go do some work
		;
		cmp	ds:[di].PTDCI_month, dl
		je	exitRoutineTDC
		mov	ds:[di].PTDCI_month, dl

		; Else update the maximum day
		;
		GOTO	PrefTimeDateControlChangeCommon
exitRoutineTDC	label	far
		ret
PrefTimeDateControlMonthChange	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlYearChange
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	The user has changed the year

CALLED BY:	GLOBAL (MSG_PTDC_YEAR_CHANGE)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClass instance data
		DX	= new year

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		PW	6/ 7/93   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlYearChange	method dynamic	PrefTimeDateControlClass, 
						MSG_PTDC_YEAR_CHANGE

		; Store the year, if it is different
		;
		cmp	ds:[di].PTDCI_year, dx
		je	exitRoutineTDC
		mov	ds:[di].PTDCI_year, dx

		; Else update the maximum day
		;
		FALL_THRU	PrefTimeDateControlChangeCommon
PrefTimeDateControlYearChange	endm

PrefTimeDateControlChangeCommon	proc	far
		class	PrefTimeDateControlClass

		; Calculate the maximum number of days in the month
		;
		mov	ax, ds:[di].PTDCI_year	; year => AX
		mov	bl, ds:[di].PTDCI_month	; month => BL
		call	LocalCalcDaysInMonth	; days => CH
		mov	ds:[di].PTDCI_maxDays, ch

		; Set the maximum value, and reset the current date
		; if it	is no longer valid (i.e. moving from 2/29/2000
		; to 2/29/1999 isn't kosher). Then force the month to
		; be re-drawn, either by invalidating it or re-setting
		; the day to be selected.
		;	
		mov	ax, MSG_PDP_GET_DAY
		mov	di, offset DayPicker
		call	PrefObjMessageCall
		mov	ax, MSG_VIS_INVALIDATE
		cmp	cl, ch			; compare today with max
		jbe	sendMessage
		mov	cl, ch
		mov	ax, MSG_PDP_SET_DAY
sendMessage:
		mov	di, offset DayPicker
		call	PrefObjMessageSend
		ret
PrefTimeDateControlChangeCommon	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlSetTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the system time

CALLED BY:	GLOBAL (MSG_PTDC_SET_TIME)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlSetTime	method dynamic	PrefTimeDateControlClass,
						MSG_PTDC_SET_TIME
		.enter

		; Set the system time
		;
		call	PrefTDCGetFeatures
		test	ax, mask PTDCF_TIME
		jz	done
		mov	di, offset TimeMinutes
		call	GenValueGetValue	; minutes => CL
		mov	dl, cl
		mov	di, offset TimeSeconds
		call	GenValueGetValue	; seconds => CL
		mov	dh, cl
		call	TimeGetHours		; hours => CL
		mov	ch, cl
		mov	cl, mask SDTP_SET_TIME
		call	TimerSetDateAndTime
done:
		; Initialize with the new time
		;
		mov	ax, MSG_PTDC_TIMER_TICK
		call	ObjCallInstanceNoLock

		.leave
		ret
PrefTimeDateControlSetTime	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlSetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the system time

CALLED BY:	GLOBAL (MSG_PTDC_SET_DATE)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClassInstance

RETURN:		Nothing

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlSetDate	method dynamic	PrefTimeDateControlClass,
						MSG_PTDC_SET_DATE
		.enter

		; Set the system time
		;
		mov	di, offset DateYear
		call	GenValueGetValue
		mov_tr	ax, cx
		push	ax
		mov	di, offset MonthList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	PrefObjMessageCall
		inc	al				;al <- month 1-12
		mov	bl, al
		mov	ax, MSG_PDP_GET_DAY
		mov	di, offset DayPicker
		call	PrefObjMessageCall		;cl <- day 1-31
		pop	ax
		mov	bh, cl
		mov	cl, mask SDTP_SET_DATE
		call	TimerSetDateAndTime

		; Initialize with the new date 
		;
		mov	ax, MSG_PTDC_TIMER_TICK
		call	ObjCallInstanceNoLock

		.leave
		ret
PrefTimeDateControlSetDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlGetDate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the system time

CALLED BY:	GLOBAL (MSG_PTDC_GET_DATE)

PASS:		*DS:SI	= PrefTimeDateControlClass object
		DS:DI	= PrefTimeDateControlClassInstance

RETURN:		CL	= Day
		CH	= Month
		DX	= Year

DESTROYED:	AX, CX, DX, BP

PSEUDO CODE/STRATEGY:
		
KNOWN BUGS/SIDE EFFECTS/IDEAS:
		
REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlGetDate	method dynamic	PrefTimeDateControlClass,
						MSG_PTDC_GET_DATE
		.enter

		; Return the date selected by the user
		;
		mov	di, offset DateYear
		call	GenValueGetValue
		push	cx				;save year
		mov	di, offset MonthList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	PrefObjMessageCall
		inc	al				;al <- month 1-12
		mov	ch, al				;ch <- month 1-12
		mov	ax, MSG_PDP_GET_DAY
		mov	di, offset DayPicker
		call	PrefObjMessageCall		;cl <- day 1-31
		pop	dx

		.leave
		ret
PrefTimeDateControlGetDate	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		*** Utility routines
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

ifndef DO_DOVE

COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerSetTimeAMPM
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will set the maximum value for TimeHours and will set
		the object TimeAMPM {usable/not usable} based
		on what format there is for displaying the time.

CALLED BY:	PrefTimeDateControlVisOpen

PASS:		*DS:SI	= PrefTimeDateControlClass object

RETURN:		Nothing

DESTROYED:	AX, BX, CX, DX, BP, DI

SIDE EFFECTS:	will enable/disable the object TimeAMPM and set maximum
		value for TimeHours. 

PSEUDO CODE/STRATEGY:		

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/15/93    	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TimerSetTimeAMPM	proc	near
		.enter

		call	TimerCheckIfMilitaryTime
		jc	useMilitaryTime
;use12HourTime:
		mov	ax, MSG_GEN_SET_USABLE
		push	ax				;save message

		mov	dx, 1
		push	dx				;save minimum time
		mov	dx, 12				;set 12hr time
		jmp	setStuff

useMilitaryTime:
		mov	ax, MSG_GEN_SET_NOT_USABLE
		push	ax				;save message

		clr	dx
		push	dx				;save minimum time
		mov	dx, 23				;set 24hr time
setStuff:
		clr	cx
		mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
		mov	di, offset TimeHours
		call	PrefObjMessageCall

		clr	cx
		pop	dx				;restore minimum
		mov	ax, MSG_GEN_VALUE_SET_MINIMUM
		mov	di, offset TimeHours
		call	PrefObjMessageCall

		pop	ax				;restore message
		mov	di, offset TimeAMPM
		mov	dl, VUM_NOW
		call	PrefObjMessageCall

		.leave
		ret
TimerSetTimeAMPM	endp
endif	; ifndef DO_DOVE


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimerCheckIfMilitaryTime
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Will Check the text in the TimeCurrent object to see
		if the character 'M' is in it (hence if using 12 or 24
		hour format).

		DOVE  Version checks the Ini file under [localization] for
		the key, "time24Hour" for TRUE or FALSE state.

CALLED BY:	TimerSetTimeAMPM

PASS:		*DS:SI	= PrefTimeDateControlClass object

RETURN:		carry set if using 24 hour time format
		carry clear if using 12 hour time format

DESTROYED:	Dove version:	Nothing
		Otherwise:	AX, BX, CX, DX, BP, DI

SIDE EFFECTS:	none

PSEUDO CODE/STRATEGY:


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	PW	4/15/93    	Initial version
	LEW	12/4/96		Dove version added

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
ifdef DO_DOVE
TimerCheckIfMilitaryTime	proc	far
	uses	ax, cx, dx, ds, si
	.enter

	segmov	ds, cs, si
	mov	si, offset time24Category
	mov	cx, cs
	mov	dx, offset time24Key
	call	InitFileReadInteger
	jnc	valueFound
	;
	; In the event that no such key is found, we will default to
	; 24-hour representation.
	;
	mov	ax, BW_TRUE	
valueFound:
	cmp	ax, BW_FALSE
	clc
	je	done
	stc
done:
	.leave
	ret

else	; non-DOVE version follows:
TimerCheckIfMilitaryTime	proc	near

SBCS <timeText	local	MAX_TIME_TEXT_LENGTH_ON_STACK dup (char)	>
DBCS <timeText	local	MAX_TIME_TEXT_LENGTH_ON_STACK dup (wchar)	>
		uses	es
		.enter

		push	bp				; save locals
		mov	dx, ss
		lea	bp, timeText
		mov	di, offset TimeCurrent
		mov	ax, MSG_VIS_TEXT_GET_ALL_PTR
		call	PrefObjMessageCall

		LocalLoadChar	ax, 'M'			; set character to 
							;   search for
		movdw	esdi, dxbp			; es:di <= time string
		add	di, cx
DBCS <		add	di, cx				; 2 bytes per char >
		std					; check in reverse
SBCS <		repnz scasb				; check if char is in>
SBCS <							;   string	>
DBCS <		repnz scasw				; check if char is in>
DBCS <							;   string	>
		cld					; set to forward
		clc					; set to 12 hr format
		jz	useAMPM
		stc					; set to 24 hr format
useAMPM:
		pop	bp				; restore locals

		.leave
		ret
endif	; non-DOVE version

TimerCheckIfMilitaryTime	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DateTimeToTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff a date or time string into a text object

CALLED BY:	UTILITY

PASS:		*DS:SI	= PrefControlClass object
		DI	= Text object chunk handle
		DX	= DateTimeFormat

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DateTimeToTextObject	proc	near
		uses	ax, bx, cx, dx, bp, es
		.enter
	
		; Create the string, and stuff it
		;
		segmov	es, ss
		sub	sp, DATE_TIME_BUFFER_SIZE
		mov	ax, sp
		push	si, di, dx
		mov_tr	di, ax			; buffer => ES:DI
		call	TimerGetDateAndTime
		pop	si			; DateTimeFormat => SI
		call	LocalFormatDateTime
		mov	dx, es
		mov	bp, di
		pop	si, di			; PrefControlClass, text obj
		mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR
		call	StuffTextObject
		add	sp, DATE_TIME_BUFFER_SIZE

		.leave
		ret
DateTimeToTextObject	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeSetHours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the # of hours to be displayed to the user

CALLED BY:	PrefTimeDateControlInitScreen

PASS:		*DS:SI	= PrefTimeDateControlClass object
		CH	= # of hours

RETURN:		Nothing

DESTROYED:	BX, CX, ES

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TimeSetHours	proc	near
		uses	ax, dx, bp, di		
		.enter
	
ifndef DO_DOVE
		; DOVE keeps the internal range [00-23] so skip this part...

		; See if we are in 24-hour mode or not
		;
		push	cx			; save number of hours
		call	TimerCheckIfMilitaryTime
		pop	cx			; restore number of hours
		jnc	useAMPM
endif	; ifndef DO_DOVE
;useMilitary:
		clr	dx			; assume AM
		mov	cl, ch
		cmp	cl, 12
		jl	setHours
		mov	dx, 12			; have PM
		jmp	setHours
ifndef DO_DOVE
useAMPM:
		; Set the hour value
		;
		clr	dx			; assume AM
		mov	cl, 12			; assume 12PM
		tst	ch
		jz	setHours
		mov	cl, ch
		cmp	cl, 12
		jl	setHours
		mov	dx, 12			; have PM
		je	setHours		; have 12PM
		sub	cl, 12
endif	; ifndef DO_DOVE
setHours:
		mov	di, offset TimeHours
		call	GenValueSendByte

		; Set the AM/PM value
		;
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	cx, dx
		clr	dx			; determinate
		mov	di, offset TimeAMPM
		call	PrefObjMessageSend

		.leave
		ret
TimeSetHours	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		TimeGetHours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the # of hours set by the user

CALLED BY:	PrefTimeDateControlSetTime

PASS:		*DS:SI	= PrefTimeDateControlClass object

RETURN:		CL	= # of hours

DESTROYED:	CH, BP, ES, DI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/30/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

TimeGetHours	proc	near
		uses	ax, dx, bp, di
		.enter
	
ifndef DO_DOVE
		; DOVE keeps the internal range [00-23] so skip this part...

		; See if we are in 24-hour mode or not
		;
		call	TimerCheckIfMilitaryTime
		jnc	useAMPM
endif	; ifndef DO_DOVE
;useMilitary:
		mov	di, offset TimeHours
		call	GenValueGetValue
		jmp	exitRoutine
ifndef DO_DOVE
useAMPM:
		; We're in AMP/PM mode, so go for it
		;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, offset TimeAMPM
		call	PrefObjMessageCall	; hours => AX
		push	ax
		mov	di, offset TimeHours
		call	GenValueGetValue
		pop	ax
		cmp	cx, 12
		jl	done			; if not 12 PM or AM, we're OK
		clr	cx			; else AM = 0, PM = 12
done:
		add	cx, ax			; hours => CX
endif	; ifndef DO_DOVE
exitRoutine:
		.leave
		ret
TimeGetHours	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenValueSend
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Send a message to a GenValue object

CALLED BY:	UTILITY

PASS:		*DS:SI	= PrefControlClass object
		DI	= Chunk handle of GenValue object
		CX	= Data to send

RETURN:		Nothing

DESTROYED:	CX

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenValueSendByte	proc	near
		clr	ch	
		FALL_THRU	GenValueSend
GenValueSendByte	endp

GenValueSend	proc	near
		uses	ax, bp
		.enter

		mov	ax, MSG_GEN_VALUE_SET_INTEGER_VALUE
		clr	bp
		call	PrefObjMessageSend
	
		.leave
		ret
GenValueSend	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		GenValueGetValue
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the integer value from a GenValue object

CALLED BY:	UTILITY

PASS:		*DS:SI	= PrefControlClass object
		DI	= Chunk handle of GenValueClass object

RETURN:		CX	= Integer value

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

GenValueGetValue	proc	near
		uses	ax, dx, bp
		.enter

		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	PrefObjMessageCall
		mov	cx, dx			; integer value => CX
		
		.leave
		ret
GenValueGetValue	endp



PrefObjMessageCall	proc	far
		uses	bx
		.enter

		mov	bx, mask MF_CALL or mask MF_FIXUP_DS
		call	PrefObjMessage

		.leave
		ret
PrefObjMessageCall	endp
		
PrefObjMessageSend	proc	far
		uses	bx
		.enter

		mov	bx, mask MF_FIXUP_DS
		call	PrefObjMessage

		.leave
		ret
PrefObjMessageSend	endp

PrefObjMessage	proc	far
		uses	bx, di, si
		.enter
	
		push	bx
		call	PrefGetChildBlock
		mov	si, di			; object's OD => BX:SI
		pop	di			; MessageFlags => DI
		jc	done
		call	ObjMessage
		clc
done:		
		.leave
		ret
PrefObjMessage	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefGetChildBlock
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the block holding the controller's child UI

CALLED BY:	UTILITY

PASS:		*DS:SI	= PrefControlClass

RETURN:		Carry	= Clear
		BX	= Handle of child block
			- or -
		Carry	= Set
		BX	= Garbage

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefGetChildBlock	proc	near
		uses	ax
		.enter
	
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData		; TempGenControlInstance=>DS:BX
		cmc
		jc	done			; not found, so no UI
		mov	bx, ds:[bx].TGCI_childBlock
done:
		.leave
		ret
PrefGetChildBlock	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTDCGetFeatures
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the block holding the controller's child UI

CALLED BY:	UTILITY

PASS:		*DS:SI	= PrefControlClass

RETURN:		AX	= PrefTimeDateControlFeatures

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTDCGetFeatures	proc	near
		uses	bx
		.enter
	
		mov	ax, TEMP_GEN_CONTROL_INSTANCE
		call	ObjVarFindData		; TempGenControlInstance=>DS:BX
		mov	ax, 0
		jnc	done			; not found, so no UI
		mov	ax, ds:[bx].TGCI_features
done:
		.leave
		ret
PrefTDCGetFeatures	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		StuffTextObject
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Stuff a text object with text

CALLED BY:	UTILITY

PASS:		*DS:SI	= ZoomerControlClass object
		AX	= Message to send to text object
		DI	= Chunk handle of text object
		DX:BP	= Null-terminated text string

RETURN:		Nothing

DESTROYED:	Nothing

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:

REVISION HISTORY:
		Name	Date		Description
		----	----		-----------
		Don	11/29/92	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

StuffTextObject	proc	near
		uses	ax, cx, dx, bp
		.enter
	
		; Get the text object OD, and send the message
		;
		clr	cx			; null-terminated text
		call	PrefObjMessageCall

		.leave
		ret
StuffTextObject	endp




COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlApply
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

DESCRIPTION:	

PASS:		*ds:si	- PrefTimeDateControlClass object
		ds:di	- PrefTimeDateControlClass instance data
		es	- dgroup

RETURN:		

DESTROYED:	nothing 

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:	

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
       chrisb	10/19/93   	Initial version.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlApply	method	dynamic	PrefTimeDateControlClass, 
					MSG_GEN_APPLY
		mov	di, offset PrefTimeDateControlClass
		call	ObjCallSuperNoLock

		mov	ax, MSG_PTDC_SET_DATE
		call	ObjCallInstanceNoLock

		mov	ax, MSG_PTDC_SET_TIME
		call	ObjCallInstanceNoLock

		mov	ax, MSG_PTDC_SET_TIMEZONE
		GOTO	ObjCallInstanceNoLock

PrefTimeDateControlApply	endm


ifdef DO_DOVE
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlToggle24Hours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_PTDC_TOGGLE_24_HOURS
PASS:		*ds:si	= PrefTimeDateControlClass object
		ds:di	= PrefTimeDateControlClass instance data
		ds:bx	= PrefTimeDateControlClass object (same as *ds:si)
		es 	= segment of PrefTimeDateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	Read the value of the time24Hour key in the localization category
	Toggle it
	Write it back
	Set the corresponding GenItemGroup accordingly.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	warner	11/11/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTimeDateControlToggle24Hours  method dynamic PrefTimeDateControlClass, 
					MSG_PTDC_TOGGLE_24_HOURS
	uses	ax, cx, dx, bp
	.enter

	push	ds, si				; save object
	segmov	ds, cs, si
	mov	si, offset time24Category
	mov	cx, cs
	mov	dx, offset time24Key
	call	InitFileReadInteger
	jnc	valueFound
	mov	ax, BW_TRUE			; default value if wasn't found
valueFound:
	xor	ax, BW_TRUE			; Boolean value gets flipped
	mov	bp, ax
	call	InitFileWriteInteger		; Write it back to the ini file
	pop	ds, si				; restore object

	; also change the state of the TwelveTwentyFourGroup:
	clr	dx				; determinate
	mov	cx, bp
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	di, offset TwelveTwentyFourGroup
	call	PrefObjMessageCall

	.leave
	ret
PrefTimeDateControlToggle24Hours	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlSet12Or24Hours
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_PTDC_SET_12_OR_24_HOURS
PASS:		*ds:si	= PrefTimeDateControlClass object
		ds:di	= PrefTimeDateControlClass instance data
		ds:bx	= PrefTimeDateControlClass object (same as *ds:si)
		es 	= segment of PrefTimeDateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
		Set the value of the time24Hour key in the localization
		category to match the GenItem chosen by the user.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	warner	11/13/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefTimeDateControlSet12Or24Hours  method dynamic PrefTimeDateControlClass, 
					MSG_PTDC_SET_12_OR_24_HOURS
	uses	ax, cx, dx, bp
	.enter

	mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
	mov	di, offset TwelveTwentyFourGroup
	call	PrefObjMessageCall

	mov_tr	bp, ax			; either BW_TRUE or BW_FALSE
	
	segmov	ds, cs, si
	mov	si, offset time24Category
	mov	cx, cs
	mov	dx, offset time24Key
	call	InitFileWriteInteger

	.leave
	ret
PrefTimeDateControlSet12Or24Hours	endm

time24Category	char	"localization",0
time24Key	char	"time24Hour",0


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PTDCAdjustHourDisplay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	

CALLED BY:	MSG_PTDC_ADJUST_HOUR_DISPLAY
PASS:		*ds:si	= PrefTimeDateControlClass object
		ds:di	= PrefTimeDateControlClass instance data
		ds:bx	= PrefTimeDateControlClass object (same as *ds:si)
		es 	= segment of PrefTimeDateControlClass
		ax	= message #
RETURN:		nothing
DESTROYED:	nothing
SIDE EFFECTS:	Toggles time24Hour Boolean in the init file.  This really
		should be undone if the user cancels.

PSEUDO CODE/STRATEGY:
		User has just hit one of the 12-hour or 24-hour GenItem
		buttons.  We want to adjust the hour display to use
		"military" time or "AM / PM" time without the user having
		to apply changes.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	warner	12/ 6/96   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PTDCAdjustHourDisplay	method dynamic PrefTimeDateControlClass, 
					MSG_PTDC_ADJUST_HOUR_DISPLAY
	uses	ax, cx, dx, bp
	.enter

	push	ds, si				; save object
	segmov	ds, cs, si
	mov	si, offset time24Category
	mov	cx, cs
	mov	dx, offset time24Key
	call	InitFileReadInteger
	jnc	valueFound
	mov	ax, BW_TRUE			; default value if wasn't found
valueFound:
	xor	ax, BW_TRUE			; Boolean value gets flipped
	mov	bp, ax
	call	InitFileWriteInteger		; Write it back to the ini file
	pop	ds, si				; restore object
	

	; Fiddle with the thing just a bit to wake it up and make it redraw
	clr	cx
	mov	dx, 99				; anything > 23
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	mov	di, offset TimeHours
	call	PrefObjMessageCall

	clr	cx
	mov	dx, 23				; back to normal
	mov	ax, MSG_GEN_VALUE_SET_MAXIMUM
	call	PrefObjMessageCall

	.leave
	ret
PTDCAdjustHourDisplay	endm


endif	; DO_DOVE



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMonthListBuild
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Build our list of months

CALLED BY:	MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
PASS:		*ds:si	= PrefMonthListClass object
		ds:di	= PrefMonthListClass instance data
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMonthListBuild	method dynamic PrefMonthListClass, 
					MSG_PREF_DYNAMIC_LIST_BUILD_ARRAY
	;
	; Initialize the dynamic list
	;
		mov	cx, 12				;cx <- # items
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		GOTO	ObjCallInstanceNoLock
PrefMonthListBuild	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMonthListFindItem
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Find a month in our list

CALLED BY:	MSG_PREF_DYNAMIC_LIST_FIND_ITEM
PASS:		*ds:si	= PrefMonthListClass object
		ds:di	= PrefMonthListClass instance data
		cx:dx - NULL-terminated string
		bp - non-zero to find best fit
RETURN:		carry - clear
			found
			ax - item #
		carry - set
			not found
			ax - item after requested item
DESTROYED:	
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@
PrefMonthListFindItem	method dynamic PrefMonthListClass, 
					MSG_PREF_DYNAMIC_LIST_FIND_ITEM
notFound::
		clr	ax				;ax <- item after
		stc					;carry <- not found
		ret
PrefMonthListFindItem	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefMonthListGetItemMoniker
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Return the moniker for a given item

CALLED BY:	MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
PASS:		*ds:si	= PrefMonthListClass object
		ds:di	= PrefMonthListClass instance data
		ss:bp - GetItemMonikerParams
RETURN:		bp - # of chars found (0 if too large)
DESTROYED:
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefMonthListGetItemMoniker	method dynamic PrefMonthListClass,
					MSG_PREF_ITEM_GROUP_GET_ITEM_MONIKER
	;
	; Get the name of the month
	;
		mov	bx, ss:[bp].GIMP_identifier	;bx <- item #
		inc	bl				;bl <- month 1-12
		les	di, ss:[bp].GIMP_buffer		;es:di <- buffer
		mov	si, DTF_MONTH			;si <- DateTimeFormat
		clr	ax, cx, dx
		call	LocalFormatDateTime
	;
	; Figure out the length
	;
		lds	si, ss:[bp].GIMP_buffer		;ds:si <- string
		call	LocalStringLength
		mov	bp, cx				;bp <- length
		ret
PrefMonthListGetItemMoniker	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDayPickerRecalcSize
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Recalculate the size

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= PrefDayPickerClass object
		ds:di	= PrefDayPickerClass instance data
RETURN:		cx - width
		dx - height
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDayPickerRecalcSize	method dynamic PrefDayPickerClass,
					MSG_VIS_RECALC_SIZE
		mov	cx, PREF_DAY_PICKER_WIDTH
		mov	dx, PREF_DAY_PICKER_HEIGHT
		ret
PrefDayPickerRecalcSize	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDayPickerKbdChar
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	handle a keypress

CALLED BY:	MSG_VIS_RECALC_SIZE
PASS:		*ds:si	= PrefDayPickerClass object
		ds:di	= PrefDayPickerClass instance data

		ax - MSG_META_KBD_CHAR:
			cl - Character		(Chars or VChar)
			ch - CharacterSet	(CS_BSW or CS_CONTROL)
			dl - CharFlags
			dh - ShiftState		(left from conversion)
			bp low - ToggleState
			bp high - scan code

RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	2/29/00   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDayPickerNav	method dynamic PrefDayPickerClass,
					MSG_SPEC_NAVIGATION_QUERY
	;
	; if we started it, don't answer it
	;
		cmp	cx, ds:LMBH_handle
		jne	notUs
		cmp	dx, si
		jne	notUs
		mov	di, offset PrefDayPickerClass
		call	ObjCallSuperNoLock
		jmp	done

notUs:
		mov	cx, ds:LMBH_handle
		mov	dx, si
		mov	al, mask NCF_IS_FOCUSABLE
		stc				;carry <- nav to me
done:
		ret
PrefDayPickerNav	endm

	;p  a  c  s  s    c
	;h  l  t  h  e    h
	;y  t  r  f  t    a
	;s     l  t       r
	;
dayPickerKbdShortcuts KeyboardShortcut \
	<0, 0, 0, 0, 0xf, VC_TAB>,		;<Tab>
	<0, 0, 0, 1, 0xf, VC_TAB>,		;<Shift><Tab>
	<1, 0, 0, 0, 0xf, VC_DOWN>,		;<down arrow>
	<1, 0, 0, 0, 0xf, VC_UP>,		;<up arrow>
	<1, 0, 0, 0, 0xf, VC_RIGHT>,		;<right arrow>
	<1, 0, 0, 0, 0xf, VC_LEFT>		;<left arrow>

dayPickerKbdActions nptr \
	DayPickerNavNext,
	DayPickerNavPrev,
	DayPickerNextWeek,
	DayPickerPrevWeek,
	DayPickerNextDay,
	DayPickerPrevDay

PrefDayPickerKbdChar	method dynamic PrefDayPickerClass,
					MSG_META_KBD_CHAR
	;
	; if a press, check if a shortcut
	;
		test	dl, mask CF_RELEASE
		jnz	done
		push	ds, si
		mov	ax, (length dayPickerKbdShortcuts)
		segmov	ds, cs
		mov	si, offset dayPickerKbdShortcuts
		call	FlowCheckKbdShortcut
		mov	di, si
		pop	ds, si
		jnc	callSuper
	;
	; call the routine with the current day
	;
		mov	ax, MSG_PDP_GET_DAY
		call	CallSelf
		call	cs:dayPickerKbdActions[di]
done:
		ret

callSuper:
		mov	ax, MSG_META_KBD_CHAR
		mov	di, offset PrefDayPickerClass
		GOTO	ObjCallSuperNoLock
PrefDayPickerKbdChar	endm

DayPickerPrevWeek	proc	near
		sub	cl, 7			;cl <- previous week
		ja	DayPickerSetDayCommon	;branch if OK
		mov	cl, 1			;else stop at 1
		GOTO	DayPickerSetDayCommon
DayPickerPrevWeek	endp

DayPickerNextWeek	proc	near
		add	cl, 7			;cl <- next week
		GOTO	DayPickerSetDayCommon
DayPickerNextWeek	endp

DayPickerPrevDay	proc	near
		dec	cl			;cl <- prev day
		GOTO	DayPickerSetDayCommon
DayPickerPrevDay	endp

DayPickerNextDay	proc	near
		inc	cl			;cl <- next day
		FALL_THRU DayPickerSetDayCommon
DayPickerNextDay	endp

DayPickerSetDayCommon	proc	near
		mov	ax, MSG_PDP_SET_DAY
		call	CallSelf
		FALL_THRU	MakeApplyable
DayPickerSetDayCommon	endp

MakeApplyable	proc	near
		mov	ax, MSG_GEN_MAKE_APPLYABLE
		FALL_THRU	CallSelf
MakeApplyable	endp

CallSelf	proc	near
		call	ObjCallInstanceNoLock
		ret
CallSelf	endp

DayPickerNavPrev	proc	near
		mov	ax, MSG_GEN_NAVIGATE_TO_PREVIOUS_FIELD
		GOTO	CallSelf
DayPickerNavPrev	endp

DayPickerNavNext	proc	near
		mov	ax, MSG_GEN_NAVIGATE_TO_NEXT_FIELD
		GOTO	CallSelf
DayPickerNavNext	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDayPickerDraw
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the day picker

CALLED BY:	MSG_VIS_DRAW
PASS:		*ds:si	= PrefDayPickerClass object
		ds:di	= PrefDayPickerClass instance data
		bp - GState
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDayPickerDraw	method dynamic PrefDayPickerClass,
					MSG_VIS_DRAW

gstate		local	hptr.GState		push	bp
bounds		local	Rectangle
stringBuffer	local	MAX_WEEKDAY_LENGTH dup (TCHAR)
dayOffset	local	word
curDay		local	word
numDays		local	byte
today		local	byte
		.enter

		mov	al, ds:[di].PDPI_currentDay
		mov	ss:today, al

		mov	di, ss:gstate
		call	GrSaveState

		call	VisGetBounds			;(ax,bx,cx,dx)<- bounds
		mov	ss:bounds.R_left, ax
		mov	ss:bounds.R_top, bx
		mov	ss:bounds.R_right, cx
		mov	ss:bounds.R_bottom, dx
	;
	; Draw lines to give the pseudo-3D look
	;
		call	DrawBevel
	;
	; Draw the days of the weeks
	;
drawDaysOfWeek::
		mov	cx, 0				;cx <- FontID
		mov	dx, 9
		clr	ah				;dx.ah <- pointsize
		call	GrSetFont

		push	ds
		clr	cx				;cx <- day index
		segmov	es, ss, si
		mov	ds, si
		lea	si, ss:stringBuffer		;ds:si <- buffer
dowLoop:
		push	cx
		call	DayToPos			;(ax,bx) <- (x,y)
		mov	di, si				;es:di <- buffer
		mov	si, DTF_WEEKDAY			;si <- DateTimeFormat
		call	LocalFormatDateTime
		mov	cx, 1				;cx <- 1st char only
		mov	si, di				;ds:si <- buffer
		mov	di, ss:gstate			;di <- GState
		call	GrDrawText
		pop	cx
		inc	cx
		cmp	cx, 7
		jb	dowLoop
		pop	ds
	;
	; Draw a separator line
	;
		add	bx, 13
		mov	ax, ss:bounds.R_left
		mov	cx, ss:bounds.R_right
		call	GrDrawHLine
		inc	bx
		call	GetLineColorScheme
		call	GrDrawHLine
	;
	; Get the month and year and figure out how many days in
	; the month and what day of the week it starts on.
	;
getDaysInMonth::
		mov	si, offset MonthList
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		call	ObjCallInstanceNoLock
		inc	al				;al <- month (1-12)
		mov	bl, al				;bl <- month
		mov	si, offset DateYear
		mov	ax, MSG_GEN_VALUE_GET_VALUE
		call	ObjCallInstanceNoLock
		mov	ax, dx				;ax <- year

		call	LocalCalcDaysInMonth
		mov	ss:numDays, ch			;save # of days
		mov	bh, 1				;bh <- day
		call	LocalCalcDayOfWeek
		add	cl, 6				;cl <- add for SMTWTFS
		clr	ch
		mov	ss:dayOffset, cx
	;
	; Draw the days
	;
drawDays::
		segmov	ds, es
		lea	si, ss:stringBuffer		;ds:si <- buffer
		mov	ss:curDay, 1
dayLoop:
		mov	cx, ss:curDay			;cx <- current day
		add	cx, ss:dayOffset		;cx <- adjust for 1st
		call	DayToPos
		push	ax
		clr	dx
		mov	ax, ss:curDay			;dx:ax <- day
		mov	cx, mask UHTAF_NULL_TERMINATE	;cx <- flags
		mov	di, si				;es:di <- buffer
		call	UtilHex32ToAscii
		pop	ax
		mov	si, di				;ds:si <- string
		mov	di, ss:gstate			;di <- GState
		call	GrDrawText
		inc	ss:curDay			;next day
		mov	al, {byte}ss:curDay
		cmp	al, ss:numDays			;reached last day?
		jbe	dayLoop				;branch if not
	;
	; Show the current day selected
	;
		mov	al, MM_INVERT			;al <- MixMode
		call	GrSetMixMode
		mov	cl, ss:today
		clr	ch				;cx <- today
		add	cx, ss:dayOffset
		call	DayToPos
		sub	ax, 2
		sub	bx, 2
		mov	cx, ax
		mov	dx, bx
		add	cx, 19
		add	dx, 14				;(ax,bx,cx,dx) <- rect
		call	GrFillRect

		call	GrRestoreState			;restore font, color

		.leave
		ret
PrefDayPickerDraw	endm

GetLineColorScheme	proc	near
		uses	ax, bx, cx, dx, si, bp
		.enter

		push	di
		clr	bx			;bx <- current process
		call	GeodeGetAppObject
		mov	ax, MSG_GEN_APPLICATION_GET_DISPLAY_SCHEME
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage
		pop	di
		mov	al, ch				;al <- dark color
		mov	ah, CF_INDEX
		call	GrSetLineColor

		.leave
		ret
GetLineColorScheme	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DayToPos
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert a day index to an (x,y) position

CALLED BY:	PrefDayPickerDraw
PASS:		ss:bp	- PrefDayPickerDraw stack frame
		cx	- day index (0-# where 0-6 is SMTWTFS line)
RETURN:		(ax,bx)	- (x,y) position including bounds
DESTROYED:	dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/9/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PDP_TOP_MARGIN	equ	3
PDP_LEFT_MARGIN	equ	9

DayToPos	proc	near
		.enter	inherit	PrefDayPickerDraw

		mov	ax, cx
		mov	dl, 7
		div	dl				;al <- #/7 = row#
		mov	bl, ah				;bl <- #%7 = col#
	;
	; Calculate the y position
	;
		mov	dl, PREF_DAY_PICKER_HEIGHT/7
		mul	dl
		add	ax, PDP_TOP_MARGIN
		add	ax, ss:bounds.R_top		;ax <- y pos
	;
	; Calculate the x position
	;
		xchg	ax, bx				;al <- col#, bx <- ypos
		mov	dl, PREF_DAY_PICKER_WIDTH/7
		mul	dl
		add	ax, PDP_LEFT_MARGIN
		add	ax, ss:bounds.R_left		;ax <- y pos

		.leave
		ret
DayToPos	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DrawBevel
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Draw the bevel

CALLED BY:	PrefDayPickerDraw
PASS:		*ds:si - PrefDayPickerClass object
		(ax,bx,cx,dx) - bounds
		di - GState
RETURN:		none
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DrawBevel	proc	near
		.enter

		call	GetLineColorScheme
		call	GrDrawVLine
		call	GrDrawHLine
		push	ax
		mov	ax, C_WHITE or (CF_INDEX shl 8)
		call	GrSetLineColor
		pop	ax
		xchg	ax, cx
		call	GrDrawVLine
		xchg	ax, cx
		xchg	bx, dx
		call	GrDrawHLine

		.leave
		ret
DrawBevel	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDayPickerGetDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current day

CALLED BY:	MSG_PDP_GET_DAY
PASS:		*ds:si	= PrefDayPickerClass object
		ds:di	= PrefDayPickerClass instance data
RETURN:		cl - day (1-31)
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDayPickerGetDay	method dynamic PrefDayPickerClass,
					MSG_PDP_GET_DAY
		mov	cl, ds:[di].PDPI_currentDay
		ret
PrefDayPickerGetDay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDayPickerSetDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the current day

CALLED BY:	MSG_PDP_SET_DAY
PASS:		*ds:si	= PrefDayPickerClass object
		ds:di	= PrefDayPickerClass instance data
		cl - day (1-31)
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefDayPickerSetDay	method dynamic PrefDayPickerClass,
					MSG_PDP_SET_DAY
	;
	; Save the day after checking for legality
	;
		call	MakeDayValid		; revised day => CL
		mov	di, ds:[si]
		add	di, ds:[di].PrefDayPicker_offset
		cmp	ds:[di].PDPI_currentDay, cl
		je	done
		mov	ds:[di].PDPI_currentDay, cl
	;
	; Redraw ourselves
	;
		mov	ax, MSG_VIS_INVALIDATE
		call	ObjCallInstanceNoLock
done:
		ret
PrefDayPickerSetDay	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefDayPickerStartSelect
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Handle a mouse press

CALLED BY:	MSG_META_START_SELECT

PASS:		(cx,dx) - (x,y)
		bp.low = ButtonInfo
		bp.high = ShiftState
RETURN:		none
DESTROYED:	none

PSEUDO CODE/STRATEGY:	

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		The major problem with this routine is that
		an illegal date (day, actually) can be stored
		until MSG_META_END_SELECT is called.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	eca	4/1/98   	Initial version.
	don	1/18/98		Eliminated screen flash

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@	

PrefDayPickerStartSelect	method dynamic	PrefDayPickerClass,
						MSG_META_START_SELECT,
						MSG_META_PTR
		call	VisGrabMouse
		test	bp, mask BI_B0_DOWN
		jz	done
	;
	; Convert the mouse (x,y) to a day
	;
		call	PosToDay
		jc	done			;branch if out of bounds
		call	MakeDayValid		;day is now valid for mon/year
	;
	; Set the day and perform an optimized re-draw (well, invalidation)
	;
		mov	ch, cl
		mov	di, ds:[si]
		add	di, ds:[di].PrefDayPicker_offset
		mov	cl, ds:[di].PDPI_currentDay
		mov	ds:[di].PDPI_currentDay, ch		
		call	RedrawSelection
	;
	; Make ourselves applyable
	;
		mov	ax, MSG_GEN_MAKE_APPLYABLE
		call	ObjCallInstanceNoLock
done:
		mov	ax, mask MRF_PROCESSED
		GOTO	VisReleaseMouse
PrefDayPickerStartSelect	endm


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PosToDay
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Convert an (x,y) position to a day

CALLED BY:	PrefDayPickerStartSelect
PASS:		*ds:si - PrefDayPickerClass object
		(ax,bx) - (x,y) position including bounds
RETURN:		cl - day index (1-31)
		carry - set if out of bounds
DESTROYED:	ch, dx, di
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/22/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PosToDay	proc	near
		class	PrefDayPickerClass

		push	cx, dx
		call	VisGetBounds			;(ax,bx) <- top,left
		pop	cx, dx
		sub	cx, ax
		sub	cx, PDP_LEFT_MARGIN
		jc	outOfBounds
		sub	dx, bx
		sub	dx, PDP_TOP_MARGIN
		jc	outOfBounds
		push	cx
	;
	; Calc the y portion
	;
		mov	ax, dx				;ax <- y pos
		mov	dl, PREF_DAY_PICKER_HEIGHT/7
		div	dl
		cmp	al, 0
		je	noAdjust
		dec	al				;dl <- adjust for SMT..
noAdjust:
		mov	dl, 7
		mul	dl				;al <- y portion
		mov	cl, al				;cl <- y portion
	;
	; Calc the x portion
	;
		pop	ax
		mov	dl, PREF_DAY_PICKER_WIDTH/7
		div	dl				;al <- x portion
	;
	; Make 1-based and add in the y portion
	;
		inc	al
		add	cl, al				;cl <- day
	;
	; Adjust for the start of the month
	;
		push	cx
		mov	ax, MSG_PTDC_GET_MONTH_YEAR
		call	CallController
		mov	bl, cl				;bl <- month
		mov	bh, 1				;bh <- day
		call	LocalCalcDayOfWeek		;cl <- DOW (0-6)
		mov	al, cl				;cl <- DOW (0-6)
		pop	cx
		sub	cl, al				;cl <- day (adjusted)
		clc					;carry <- in bounds
done:
		ret

outOfBounds:
		stc					;carry <- out of bounds
		jmp	done
PosToDay	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		MakeDayValid
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Ensure the passed day is valid for the current month/year

CALLED BY:	PrefDayPickerSetDay(), PrefDayPickerStartSelect()

PASS:		*ds:si	= PrefDayPickerClass object
		ds:di	= PrefDayPickerClass instance data
		cl	= day (1-31) & invalid days
RETURN:		cl	= valid day for current month/year
DESTROYED:	ax, bx, ch, dx
SIDE EFFECTS:

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	2/2/00   	Initial version (broke out Gene's code)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

MakeDayValid	proc	near

	;
	; Check for legality
	;
		push	cx
		mov	ax, MSG_PTDC_GET_MONTH_YEAR
		call	CallController
		mov	bl, cl				;bl <- month
		pop	dx
		cmp	dl, 1
		jl	tooSmall
		call	LocalCalcDaysInMonth		;ch <- # days
		cmp	dl, ch
		jbe	done
		mov	dl, ch				;dl <- set to max
done:
		mov	cl, dl
		ret

tooSmall:
		mov	dl, 1
		jmp	done
MakeDayValid	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		RedrawSelection
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Invalidate two days - the previously selected day and
		the new day. These can be the same.

CALLED BY:	PrefDayPickerDraw
PASS:		*ds:si	= PrefDayPickerClass object
		cl	- old day
		ch	- new day
RETURN:		nothing
DESTROYED:	ax, bx, cx, dx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/18/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

RedrawSelection	proc	near
		uses	di, bp
		.enter
	;
	; Some set-up work
	;
		push	cx
		mov	ax, MSG_VIS_VUP_CREATE_GSTATE
		call	ObjCallInstanceNoLock		; GState => BP
		mov	al, MM_INVERT
		mov	di, bp				; GState into DI
		call	GrSetMixMode			; set to invert mode
	;
	; Un-hi-lite the first day, and then hi-lite second
	;
		mov	ax, MSG_PTDC_GET_MONTH_YEAR
		call	CallController
		mov	bl, cl				;bl <- month
		mov	bh, 1				;bh <- day
		call	LocalCalcDayOfWeek		;cl <- DOW (0-6)
		pop	ax
		add	al, cl
		add	ah, cl
		push	ax
		clr	ah
		call	hiliteOneDay
		pop	ax
		mov	al, ah
		clr	ah
		call	hiliteOneDay
	;
	; Clean up
	;
		call	GrDestroyState 			; destroy the GState

		.leave
		ret

hiliteOneDay:
	;
	; Determine the location of our object
	;
		push	si
		add	ax, (7 - 1)			;index is 0-based, but
							;we must skip a week
							;to handle SMTWTFS
		mov	bp, ax
		call	VisGetBounds
		xchg	ax, bp				;bp <- left, ax<-index
		mov	si, bx				;si <-top
		mov	dl, 7
		div	dl				;al <- #/7 = row#
		mov	bl, ah				;bl <- #%7 = col#
	;
	; Calculate the y position
	;
		mov	dl, PREF_DAY_PICKER_HEIGHT/7
		mul	dl
		add	ax, PDP_TOP_MARGIN
		add	ax, si				;ax <- y pos
	;
	; Calculate the x position
	;
		xchg	ax, bx				;al <- col#, bx <- ypos
		mov	dl, PREF_DAY_PICKER_WIDTH/7
		mul	dl
		add	ax, PDP_LEFT_MARGIN
		add	ax, bp				;ax <- x pos
	;
	; Determine the bounds of the object (should be same code
	; as is located in PrefDayPickerDraw), and fill the rectangle
	;
		sub	ax, 2
		sub	bx, 2
		mov	cx, ax
		mov	dx, bx
		add	cx, 19
		add	dx, 14				;(ax,bx,cx,dx) <- rect
		call	GrFillRect
		pop	si
		retn
RedrawSelection	endp

CallController	proc	near
		uses	bx, si, di
		.enter

		mov	bx, ds:OLMBH_output.handle
		mov	si, ds:OLMBH_output.chunk
		mov	di, mask MF_CALL or mask MF_FIXUP_DS
		call	ObjMessage

		.leave
		ret
CallController	endp


COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlGetMonthYear
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get the current month and year

CALLED BY:	MSG_PTDC_GET_MONTH_YEAR
PASS:		*ds:si	= PrefDayPickerClass object
		ds:di	= PrefDayPickerClass instance data
		cl - day (1-31)
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	4/8/98   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlGetMonthYear	method dynamic PrefTimeDateControlClass,
					MSG_PTDC_GET_MONTH_YEAR
		mov	ax, ds:[di].PTDCI_year
		mov	cl, ds:[di].PTDCI_month
		ret
PrefTimeDateControlGetMonthYear	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlQueryTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Get a string for the timezone list

CALLED BY:	MSG_PTDC_QUERY_TIMEZONE
PASS:		*ds:si	= PrefTimeDateControlClass object
		ds:di	= PrefTimeDateControlClass data
		cx:dx - list
		bp - item #
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

qtzTab QTZStruct \
	<gmtM12Str, -12*60, <1, QTZ_MINUS_12>>,
	<gmtM11Str, -11*60, <1, QTZ_MINUS_11>>,
	<gmtM10Str, -10*60, <1, QTZ_ALASKA>>,
	<gmtM9Str,  -9*60,  <0, QTZ_HAWAII>>,
	<gmtM8Str,  -8*60,  <1, QTZ_PACIFIC>>,
	<gmtM7Str,  -7*60,  <1, QTZ_MOUNTAIN>>,
	<gmtAZStr,  -7*60,  <0, QTZ_ARIZONA>>,
	<gmtM6Str,  -6*60,  <1, QTZ_CENTRAL>>,
	<gmtM5Str,  -5*60,  <1, QTZ_EASTERN>>,
	<gmtINStr,  -5*60,  <0, QTZ_INDIANA>>,
	<gmtM4Str,  -4*60,  <1, QTZ_ATLANTIC>>,
	<gmtNewfStr, -(3*60+30), <1, QTZ_NEWFOUNDLAND>>,
	<gmtM3Str,  -3*60,  <1, QTZ_MINUS_3>>,
	<gmtM2Str,  -2*60,  <1, QTZ_MINUS_2>>,
	<gmtM1Str,  -1*60,  <1, QTZ_MINUS_1>>,
	<gmtGMTStr, 0,      <1, QTZ_GMT>>,
	<gmtP1Str,  +1*60,  <1, QTZ_WESTERN_EUROPE>>,
	<gmtP2Str,  +2*60,  <1, QTZ_PLUS_2>>,
	<gmtP3Str,  +3*60,  <1, QTZ_PLUS_3>>,
	<gmtIranStr, +(3*60+30), <1, QTZ_IRAN>>,
	<gmtP4Str,  +4*60,  <1, QTZ_PLUS_4>>,
	<gmtKabulStr, +(4*60+30), <1, QTZ_AFGHANISTAN>>,
	<gmtP5Str,  +5*60,  <1, QTZ_PLUS_5>>,
	<gmtIndiaStr, +(5*60+30), <0, QTZ_INDIA>>,
	<gmtP6Str,  +6*60,  <1, QTZ_PLUS_6>>,
	<gmtMyanmarStr, +(6*60+30), <1, QTZ_MYANMAR>>,
	<gmtP7Str,  +7*60,  <1, QTZ_PLUS_7>>,
	<gmtP8Str,  +8*60,  <1, QTZ_PLUS_8>>,
	<gmtP9Str,  +9*60,  <1, QTZ_PLUS_9>>,
	<gmtCentralAusStr, +(9*60+30), <1, QTZ_CENTRAL_AUSTRALIA>>,
	<gmtP10Str, +10*60, <1, QTZ_PLUS_10>>,
	<gmtP11Str, +11*60, <1, QTZ_PLUS_11>>,
	<gmtP12Str, +12*60, <1, QTZ_PLUS_12>>

GetQTZOffset	proc	near
		push	ax
		mov	ax, di				;ax <- #
		shl	di, 1				;*2
		shl	di, 1				;*4
		add	di, ax				;*5
	CheckHack <(size QTZStruct) eq 5>
		pop	ax
		ret
GetQTZOffset	endp

PrefTimeDateControlQueryTimezone method dynamic PrefTimeDateControlClass,
					MSG_PTDC_QUERY_TIMEZONE
	;
	; get the moniker to use
	;
		push	dx
		mov	di, bp				;di <- item #
		mov	cx, bp				;cx <- item #
		call	GetQTZOffset			;di <- item offset
		mov	dx, cs:qtzTab[di].QTZS_moniker
		pop	di				;di <- list chunk
	;
	; set the moniker in the list
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_REPLACE_ITEM_MONIKER
		sub	sp, (size ReplaceItemMonikerFrame)
		mov	bp, sp
		mov	ss:[bp].RIMF_source.handle, handle StringData
		mov	ss:[bp].RIMF_source.offset, dx
		mov	ss:[bp].RIMF_sourceType, VMST_OPTR
		mov	ss:[bp].RIMF_dataType, VMDT_TEXT
		mov	ss:[bp].RIMF_length, 0
		mov	ss:[bp].RIMF_itemFlags, 0
		mov	ss:[bp].RIMF_item, cx
		call	PrefObjMessageCall
		add	sp, (size ReplaceItemMonikerFrame)
		ret
PrefTimeDateControlQueryTimezone endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlTimezoneSelected
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Update UI when a timezone is selected

CALLED BY:	MSG_PTDC_TIMEZONE_SELECTED
PASS:		*ds:si	= PrefTimeDateControlClass object
		ds:di	= PrefTimeDateControlClass instance data
		cx - item #
		bp - # selections
		dl - GenItemGroupStateFlags
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

PrefTimeDateControlTimezoneSelected method dynamic PrefTimeDateControlClass,
					MSG_PTDC_TIMEZONE_SELECTED
	;
	; if no selection, enable DST
	;
		cmp	cx, GIGS_NONE
		je	enableDST
		mov	di, cx				;di <- item #
		call	GetQTZOffset			;di <- item offset
	;
	; if the timezone doesn't use DST, disable it
	;
		mov	ax, MSG_GEN_SET_NOT_ENABLED
		test	cs:qtzTab[di].QTZS_flags, mask QTZF_DAYLIGHT_TIME
		jz	gotMsg
enableDST:
		mov	ax, MSG_GEN_SET_ENABLED
gotMsg:
		mov	di, offset TimezoneDST
		mov	dl, VUM_DELAYED_VIA_APP_QUEUE
		call	PrefObjMessageCall
		ret
PrefTimeDateControlTimezoneSelected endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		PrefTimeDateControlSetTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Set the timezone

CALLED BY:	MSG_PTDC_SET_TIMEZONE
PASS:		*ds:si	= PrefTimeDateControlClass object
		ds:di	= PrefTimeDateControlClass instance data
RETURN:		none
DESTROYED:	none
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

localizationCat char "localization", 0
timezoneIndexKey char "tzindex", 0

PrefTimeDateControlSetTimezone method dynamic PrefTimeDateControlClass,
					MSG_PTDC_SET_TIMEZONE
	;
	; get the selected timezone
	;
		mov	ax, MSG_GEN_ITEM_GROUP_GET_SELECTION
		mov	di, offset TimezoneList
		call	PrefObjMessageCall
	;
	; get the entry for it
	;
		mov	di, ax				;di <- item #
		call	GetQTZOffset			;di <- item offset
	;
	; get the DST setting, if appropriate
	;
		clr	bx				;bx <- DST setting
		test	cs:qtzTab[di].QTZS_flags, mask QTZF_DAYLIGHT_TIME
		jz	gotDST				;branch if not used
		push	di
		mov	di, offset TimezoneDST
		mov	ax, MSG_GEN_BOOLEAN_GROUP_GET_SELECTED_BOOLEANS
		call	PrefObjMessageCall
		pop	di
		test	ax, mask QTZF_DAYLIGHT_TIME
		jz	gotDST				;branch if not set
		mov	bx, 60				;bx <- adjustment/TRUE
gotDST:
	;
	; set the offset to GMT and set the values in the kernel
	;
		mov	ax, cs:qtzTab[di].QTZS_offset	;ax <- offset GMT
		add	ax, bx				;ax <- adjusted
		call	LocalSetTimezone
	;
	; write the list index so we can find it later
	;
		clr	ax
		mov	al, cs:qtzTab[di].QTZS_flags
		andnf	al, mask QTZF_INDEX		;ax <- value
		mov	bp, ax				;bp <- value
		segmov	ds, cs, cx
		mov	si, offset localizationCat	;ds:si <- category
		mov	dx, offset timezoneIndexKey	;cx:dx <- key
		call	InitFileWriteInteger
		ret
PrefTimeDateControlSetTimezone endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		InitTimezone
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Initialize the timezone

CALLED BY:	PrefTimeDateControlVisOpen
PASS:		*ds:si	= PrefTimeDateControlClass object
RETURN:		none
DESTROYED:	ax, cx
SIDE EFFECTS:	

PSEUDO CODE/STRATEGY:
	We store an index for the timezone separate from the list index
	so that we can change the list later without invalidating existing
	.INI settings. Storing the GMT offset isn't unique.
	We could store the string in the .INI file, but that would take
	more time and space.
	If MSG_GEN_ITEM_GROUP_SET_MONIKER_SELECTION worked with GenDynamicLists
	we could use it, it would still take more time and space, but
	less code.

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	gene	8/10/99   	Initial version

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

InitTimezone	proc	near
		uses	bp
		.enter

	;
	; Initialize the timezone list
	;
		mov	ax, MSG_GEN_DYNAMIC_LIST_INITIALIZE
		mov	cx, length qtzTab		;cx <- # entries
		mov	di, offset TimezoneList
		call	PrefObjMessageCall
	;
	; find the timezone based on the index
	;
		push	ds, si
		segmov	ds, cs, cx
		mov	si, offset localizationCat	;ds:si <- category
		mov	dx, offset timezoneIndexKey	;cx:dx <- key
		call	InitFileReadInteger
		pop	ds, si
		jc	noTimezone			;branch if none
		clr	di				;di <- table index
		mov	cx, length qtzTab		;cx <- table length
		clr	bx				;bx <- list index
timezoneLoop:
		mov	ah, cs:qtzTab[di].QTZS_flags
		andnf	ah, mask QTZF_INDEX		;ah <- index in table
		cmp	al, ah				;same index?
		je	gotTimezone
		add	di, (size QTZStruct)		;di <- next index
		inc	bx				;bx <- next index
		loop	timezoneLoop
		mov	bx, GIGS_NONE			;bx <- clear selection
	;
	; set the timezone
	;
gotTimezone:
		mov	cx, bx				;cx <- list index #
		clr	dx				;dx <- not indtrmnt.
		mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
		mov	di, offset TimezoneList
		call	PrefObjMessageCall
noTimezone:
	;
	; enable or disable DST by sending the status message
	;
		mov	ax, MSG_GEN_ITEM_GROUP_SEND_STATUS_MSG
		clr	cx				;cx <- don't modify
		call	PrefObjMessageCall
	;
	; set the DST setting
	;
		call	LocalGetTimezone
		clr	cx, dx				;cx <- assume unset
		tst	bl				;use DST?
		jz	gotDST				;branch if not
		ornf	cl, mask QTZF_DAYLIGHT_TIME	;cx <- DST set
gotDST:
		mov	ax, MSG_GEN_BOOLEAN_GROUP_SET_GROUP_STATE
		mov	di, offset TimezoneDST
		call	PrefObjMessageCall

		.leave
		ret
InitTimezone	endp
