
COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Palm Computing, Inc. 1992 -- All Rights Reserved

PROJECT:	PEN GEOS
MODULE:		World Clock
FILE:		wcUI.asm

AUTHOR:		Roger Flores, Oct 16, 1992

ROUTINES:
	Name			Description
	----			-----------
non Penelope routines
	CityInfoEntryLock
	WorldClockFormCityNameText
	WorldClockUpdateUserCities
	WorldClockClearAllUserCities
	WorldClockUpdateTimeDates
	DaysInMonth
	NormalizeTimeDate
	WorldClockGetDatelineTime
	WorldClockUpdateOneTimeDate
	WorldClockUpdateWorldClockTitleTime
	WorldClockSetDateAndTime
	WorldClockUpdateDaylightBar
	MSG_WC_SET_SYSTEM_CLOCK
	MSG_WC_SET_SUMMER_TIME
	WorldMapDrawTimeZone
	MSG_META_PTR
	WorldClockResolvePointToTimeZone
	IsPointInTimeZone
	MSG_WC_TIMER_TICK
	BlinkerStop
	BlinkerMove
	BlinkerBlink
	MSG_WC_BLINKER_ON
	BlinkerShowDestCity
	MSG_WC_START_USER_CITY_MODE
	InitiateSetLocationDialogAndBlinker
	MSG_GEN_INTERACTION_INITIATE
	MSG_GEN_APPLY
	SetUserCityText
	MSG_VIS_CLOSE
	MSG_SPEC_BUILD

PENELOPE routines:
Some of these are shared routines and others are rewritten versions for
Penelope but have the same name as non Penelope routines.

;PENELOPE routines:
;Some of these are shared routines and others are rewritten versions for
;Penelope but have the same name as non Penelope routines.

	CityInfoEntryLock 				(shared)	
		Lock a city info entry.

	WorldClockFormCityNameText 			(shared)
		Create the city name in text.

	WorldClockUpdateUserCities 			(rewritten)
		Update user city info when a city becomes a user city
		or the user city info changes.

	WorldClockUpdateUserCityName 			(new)
		Change a city name to the user city name.

	WorldClockUpdateTimeDates 			(rewritten)
		Update the time and dates on the world clock main view.

	WorldClockUpdateSelectedTimeZoneTimeDate	(new)
		Subset of WorldClockUpdateTimeDates to only change the
		selected time zone time and date when changing the
		time zone.

	DaysInMonth					(shared)
		Get the days for the given year and month.

	NormalizeTimeDate				(shared)

	WorldClockGetDatelineTime			(shared)
		Get the system time and date and apply the current
		system city offset.

	WorldClockUpdateOneTimeDate			(rewritten)
		Update the time and date for one object.

	WorldClockGetDateFormatOffset			(new)
		Get the specific date format string offset.

	WorldClockUpdateWorldClockTitleTime		(rewritten)
		Update the time and date in the main title object.

	WorldClockUpdateDaylightBar			(shared)
		Update the daylight bar on the world map as the time
		changes. 

	WorldMapDrawTimeZone				(shared)
		Draw the new selected time zone.

	WorldClockStartSelect				(new)
		Intercepts MSG_META_START_SELECT for dragging.

	WorldClockPtr					(new)
		Intercepts MSG_META_PTR to drag time zone.

	WorldClockEndSelect				(new)
		Intercepts MSG_META_END_SELECT for dragging.

	WorldClockViewPointMoved			(new)
		Finds and draws the new time zone associated with a
		new cursor position.  Used instead of
		WorldClockViewPointSelected.

	WorldClockChangeTimeZones			(new)
		Erases the existing time zone and draws the new one.

	WorldClockUpdateGMTOffsetText			(new)
		Updates the GMTOffset text when the selected time
		zone changes or the user city location changes.

	WorldClockGetGMTOffset
		Calculates the GMT offset field and translates it into
		text. 

	WorldClockKBDChar				(new)
		Allows cursor keys to move selected time zone.

	WorldClockResolvePointToTimeZone		(shared)
		Determine the time zone for the given pixel coordinates.

	IsPointInTimeZone				(shared)
		Determine if the given point is in the given time
		zone.

	WorldClockTimerTick				(shared)
		Update the time objects every minute.


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/16/92	Initial revision
	pm	08/15/96	PENELOPE changes

DESCRIPTION:
	Contains intialization routines for World Clock.
		
	$Id: wcUI.asm,v 1.1 97/04/04 16:22:01 newdeal Exp $


Flow of Code:

Options Box:
	The button brings up box.  The INTERACTION msg is intercepted to
	setup the ui



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;These parameters are used to udpdate each time and date object on the
;main view.  The parameters are set up in WorldClockUpdateTimeDates.

UpdateTimeDateParameters	struc
	UTDP_timeZoneHour	byte	; time zone hour (0 - 23)
	UTDP_timeZoneMinute	byte	; time zone minute (0 - 59)
	UTDP_summerTime		byte	; not zero if true
	UTDP_padding		byte	; padding for even sized structure
	UTDP_object		optr	; visual object to set moniker
	UTDP_buffer		fptr
UpdateTimeDateParameters	ends



CommonCode	segment	resource



COMMENT @-------------------------------------------------------------------

FUNCTION:	CityInfoEntryLock

DESCRIPTION:	Lock a city info entry given it's number

CALLED BY:	WorldClockFormCityNameText,
		WorldClockCountryChangeHandleListStuffOnly,
		WorldClockCountryCityListRequestMoniker, 
		WorldClockCountryListRequestMoniker

PASS:		es - dgroup
		ax - city index number
		si - index handle (to city, country, or citycountry index)
		cx:dx - buffer for element

RETURN:		bx - city info handle
		ds - city info segment

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/ 2/92	Initial version

----------------------------------------------------------------------------@

CityInfoEntryLock	proc	far
	.enter

EC <	call	ECCheckDGroupES						>

	; lock the block to pass to ChunkArrayGetElement
	push	ax				; city index number
	mov	bx, es:[cityIndexHandle]
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	ds, ax
	pop	ax				; city index number

	; get the number of cities in the list so we can tell the list object
	call	ChunkArrayGetElement		; pointer at cx:dx

	; we no longer need the city index block
 	call	MemUnlock


	; lock the block to copy to stack
	mov	bx, es:[cityInfoHandle]
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	ds, ax

	.leave
	ret
CityInfoEntryLock	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockFormCityNameText

DESCRIPTION:	Form the city name in text

CALLED BY:	WorldClockCityListRequestMoniker
		WorldClockUseCity

PASS:		es - dgroup
		ax - city index number
		cx:dx - buffer fptr

		if _PENELOPE
			si	= city or country names index handle

RETURN:		ax - x coord
		bx - y coord



DESTROYED:	bx, di, si

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/92	Initial version

----------------------------------------------------------------------------@

WorldClockFormCityNameText	proc	far
	uses	es
	.enter

EC <	call	ECCheckDGroupES						>

	mov	si, es:[cityNamesIndexHandle]	

	call	CityInfoEntryLock		; ds = city info segment.

	; get the number of cities in the list so we can tell the list object
	mov	es, cx				; buffer segment
	mov	di, dx				; buffer offset
	mov	si, dx				; move to indexing register
	mov	si, es:[si]			; get pointer
	LocalCopyString


SBCS <	mov	{word} es:[di][-1], (C_SPACE shl 8) or C_COMMA		>
DBCS <	mov	{word} es:[di][-2], C_SPACE				>
DBCS <	mov	{word} es:[di], C_LEFT_PAREN				>

						; ", " between strings

	LocalNextChar esdi			; skip newly written ' ' char


	; si ok because it points after the null char which was copied
	LocalCopyString

DBCS <	mov	{word} es:[di][-2], C_RIGHT_PAREN			>
DBCS <	clr	{word}es:[di]						>

	lodsw					; load x coordinates in ax
	mov	si, ds:[si]			; load y coordinates in si

	; we no longer need the city index block
	call	MemUnlock

	mov	bx, si				; return coordinates in bx

	.leave
	ret
WorldClockFormCityNameText	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockUpdateUserCities

DESCRIPTION:	This updates all user cities with the latest information.  It
		is used when a city becomes a user city or the user city
		info changes.

CALLED BY:	WorldClockUserCityApply

PASS:		es - dgroup


RETURN:		nothing

DESTROYED:	ax, cx, dx, di, si, bp, ds

PSEUDO CODE/STRATEGY:
	This routine replaces all of a city's information EXCEPT for the 
	CityPtr.  This allows restoring to the value before user city was
	selected.

	Also updates the blinker.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/ 9/93		Initial version

----------------------------------------------------------------------------@

WorldClockUpdateUserCities	proc	far
	uses	bx
	.enter

EC <	call	ECCheckDGroupES						>

	; The user city's location may have changed so resolve it.
	; lock the Time Zone Info block.  It's used by 
	; WorldClockResolvePointToTimeZone.
	mov	bx, es:[timeZoneInfoHandle]
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>

	mov	ds, ax
	mov	cx, es:[userCityX]
	mov	dx, es:[userCityY]
	call	WorldClockResolvePointToTimeZone
	mov	bx, es:[timeZoneInfoHandle]	; done with info
	call	MemUnlock
	mov	cx, ax				; user city time zone
	call	SetUserCityTimeZone

	test	es:[userCities], mask HOME_CITY
	jz	destCity

	mov	ax, es:[userCityTimeZone]
	mov	es:[homeCityTimeZone], ax
	mov	ax, es:[userCityX]
	mov	es:[homeCityX], ax
	mov	ax, es:[userCityY]
	mov	es:[homeCityY], ax

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, es				; buffer segment
	mov	dx, offset userCityName		; buffer offset
	mov	bp, VUM_NOW
	GetResourceHandleNS	HomeCityName, bx
	mov	si, offset HomeCityName
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, cx, dx, bp destroyed


destCity:
	test	es:[userCities], mask DEST_CITY
	jz	done

	mov	ax, es:[userCityTimeZone]
	mov	es:[destCityTimeZone], ax
	mov	cx, es:[userCityX]
	mov	es:[destCityX], cx
	mov	dx, es:[userCityY]
	mov	es:[destCityY], dx
	call	BlinkerMove

	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, es				; buffer segment
	mov	dx, offset userCityName		; buffer offset
	mov	bp, VUM_NOW
	GetResourceHandleNS	DestCityName, bx
	mov	si, offset DestCityName
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, cx, dx, bp destroyed


done:
	call	WorldClockUpdateTimeDates

	.leave
	ret
WorldClockUpdateUserCities	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockClearAllUserCities

DESCRIPTION:	Clear all user cites restoring them to original locations

CALLED BY:	

PASS:		es	- dgroup

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/10/93		Initial version

----------------------------------------------------------------------------@

WorldClockClearAllUserCities	proc	near
	.enter

	; clear the home city
	test	es:[userCities], mask HOME_CITY
	jz	homeCityClear

	andnf	es:[userCities], not mask HOME_CITY
	mov	es:[changeCity], mask HOME_CITY
	mov	cx, es:[homeCityPtr]
	call	WorldClockUseCity

homeCityClear:


	; clear the dest city
	test	es:[userCities], mask DEST_CITY
	jz	destCityClear

	andnf	es:[userCities], not mask DEST_CITY
	mov	es:[changeCity], mask DEST_CITY
	mov	cx, es:[destCityPtr]
	call	WorldClockUseCity

destCityClear:

	call	SetUserCities

	.leave
	ret
WorldClockClearAllUserCities	endp

COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockUpdateTimeDates

DESCRIPTION:	Recalc and display the times and dates

CALLED BY:	WorldClockCitySelected
		WorldClockSetSummerTime
		WorldClockUseCity
		WorldClockSetSystemClock
		WorldClockUpdateUserCities
		WorldClockSetupFromStateData
		WorldClockClearAllUserCities

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx, di, si, bp

PSEUDO CODE/STRATEGY:
	This either calls updates for the times displayed by the gadetry 
	of the primary or it calls updates for the time displayed while 
	minimized.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/92	Initial version

----------------------------------------------------------------------------@

WorldClockUpdateTimeDates	proc	far
	.enter

EC <	call	ECCheckDGroupES						>

	; if the ui is minimized and is setup then begin
	cmp	es:[uiMinimized], TRUE
	je	begin

	; this routine is called often when first setting the ui from
	; saved state.  Disable the updates to the screen until all of
	; the ui has been setup.
	cmp	es:[uiSetupSoUpdatingUIIsOk], FALSE
LONG	je	done

begin:
	segmov	ds, es, ax


	; the call WorldClockUpdateOneTimeDate requires both a buffer and
	; passed parameters.  Set up both of those here.
	sub	sp, DATE_TIME_BUFFER_SIZE	; not exact but close!
	mov	ax, sp				; offset to buffer in stack
	sub	sp, size UpdateTimeDateParameters
	mov	bp, sp				; bp points to parameters
	movdw	ss:[bp].UTDP_buffer, ssax	; buffer in stack
EC <	call	ECCheckStack						>

	call	WorldClockGetDatelineTime

	cmp	es:[uiMinimized], TRUE
LONG	je	updateTitleTime

	cmp	es:[homeCityPtr], CITY_NOT_SELECTED
	je	updateDestTime


	; update the home time
	push	ax					; save year
	mov	ah, es:[citySummerTime]
	andnf	ah, mask HOME_CITY
	mov	ss:[bp].UTDP_summerTime, ah

	mov	ax, es:[homeCityTimeZone]
	mov	{word} ss:[bp].UTDP_timeZoneHour, ax

	GetResourceHandleNS	HomeCityTimeDate, ax
	mov	ss:[bp].UTDP_object.handle, ax
	mov	ss:[bp].UTDP_object.offset, offset HomeCityTimeDate
	pop	ax					; restore year
	call	WorldClockUpdateOneTimeDate


updateDestTime:
	; don't update the time if the city hasn't been selected yet
	cmp	es:[destCityPtr], CITY_NOT_SELECTED
	je	updateSelectedTime

	; update the destination time
	push	ax					; save year
	mov	ah, es:[citySummerTime]
	andnf	ah, mask DEST_CITY
	mov	ss:[bp].UTDP_summerTime, ah

	mov	ax, es:[destCityTimeZone]
	mov	{word} ss:[bp].UTDP_timeZoneHour, ax

	GetResourceHandleNS	DestCityTimeDate, ax
	mov	ss:[bp].UTDP_object.handle, ax
	mov	ss:[bp].UTDP_object.offset, offset DestCityTimeDate
	pop	ax					; restore year
	call	WorldClockUpdateOneTimeDate

updateSelectedTime:
	;we can only update the selected time zone time if either the home
	;or dest time have been selected so the dateline can be determined.

	;The dest time is protected but not the home time, so test for it.
;	cmp	es:[homeCityPtr], CITY_NOT_SELECTED
;	je	updateDaylightBar

	; update the selected time zone time
	push	ax					; save year
	clr	ss:[bp].UTDP_summerTime

	mov	ax, es:[selectedTimeZone]
	mov	{word} ss:[bp].UTDP_timeZoneHour, ax

	GetResourceHandleNS	SelectedTimeZoneTimeDate, ax
	mov	ss:[bp].UTDP_object.handle, ax
	mov	ss:[bp].UTDP_object.offset, offset SelectedTimeZoneTimeDate
	pop	ax					; restore year
	call	WorldClockUpdateOneTimeDate

updateTitleTime:
	call	WorldClockUpdateWorldClockTitleTime

	cmp	es:[uiMinimized], TRUE
	je	doneUpdate

	call	WorldClockUpdateDaylightBar

doneUpdate:
	add	sp, size UpdateTimeDateParameters + \
		    DATE_TIME_BUFFER_SIZE		; not exact but close!

	segmov	es, ds, ax

done:
EC <	call	ECCheckStack						>
	.leave
	ret
WorldClockUpdateTimeDates	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	DaysInMonth

DESCRIPTION:	Calculate days in month even in leap years.

CALLED BY:	NormalizeTimeDate

PASS:		ax - year (1980 through 2099)
		bl - month (1 through 12)


RETURN:		di - days in month

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	Before August: even months have 30 days, odd have 31
	After August:  odd months have 30 days, even have 31
	February always has 28 days except during leap years
	February in a leap year always has 29 days except every 100 years
	February every 100 years always has 28 days except every 400 years
	February every 400 years always has 29 days except every 1200 years
							    ^^^ just kidding :)
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	12/3/92		Initial version
	rsf	3/2/93		Added leap year exceptions

----------------------------------------------------------------------------@

DaysInMonth	proc	far
	uses	bx
	.enter

EC <	cmp	bl, MONTHS_PER_YEAR					>
EC <	ERROR_G	WC_ERROR_BAD_NUMBER					>
EC <	cmp	bl, 1							>
EC <	ERROR_L	WC_ERROR_BAD_NUMBER					>


	mov	di, ax					; save the year

	cmp	bl, AUGUST
	jge	monthsAligned

	cmp	bl, FEBRUARY
	je	february

	inc	bl					; switch 31->30, 30->31
monthsAligned:

	mov	ax, 31					; default
	andnf	bx, 1
	sub	ax, bx
	jmp	done

february:
	; if the year is divisible by four it may be a leap year
	test	ax, 0x3
	jz	maybeLeapYear

notLeapYear:
	mov	ax, 28
	jmp	done


maybeLeapYear:
	; if the year is not the turn of a century then it is a leap year
	mov	bl, 100
	idiv	bl
	tst	ah				; mod 100
	jnz	LeapYear

	; if the year is not the divisble by 400 years the year isn't a leap year
	test	ah, 0x3
	jnz	notLeapYear


LeapYear:
	mov	ax, 29

done:
	xchg	ax, di				; switch days in month with saved year


	.leave
	ret
DaysInMonth	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	NormalizeTimeDate

DESCRIPTION:	Adjust the day and date if the hours are not within one day 
		(insure 0 <= day time <= 23)

CALLED BY:	

PASS:		ax - year (1980 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)
		cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		ch - hours (0 through 23)
		dl - minutes (0 through 59)

RETURN:		ax - year (1980 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)
		cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		ch - hours (0 through 23)
		dl - minutes (0 through 59)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	check minute adjusting hour
	check hour adjusting day and day of week
	check day adjusting month
	check month adjusting years
	check day of week without adjusting anything else

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/29/92	Initial version
	rsf	12/ 3/92	rewrote to work correctly and include minutes

----------------------------------------------------------------------------@

NormalizeTimeDate	proc	near
	uses	di
	.enter

	; checkMinutes
	cmp	dl, MINUTES_PER_HOUR
	jge	minuteTooLarge
	cmp	dl, 0
	jge	checkHour

	; minuteTooSmall
	add	dl, MINUTES_PER_HOUR		; add 60 minutes
	dec	ch				; subtract an hour
	jmp	checkHour

minuteTooLarge:
	sub	dl, MINUTES_PER_HOUR		; subtract 60 minutes
	inc	ch				; add an hour


checkHour:
	cmp	ch, HOURS_PER_DAY
	jge	hourTooLarge
	cmp	ch, 0
	jge	checkDay

	; hourTooSmall
	add	ch, HOURS_PER_DAY		; add 24 hours
	dec	bh				; subtract a day
	dec	cl				; subtract a day of week.
	jmp	checkDay

hourTooLarge:
	sub	ch, HOURS_PER_DAY		; subtract 24 hours
	inc	bh				; add a day
	inc	cl				; add a day of week


checkDay:

	; Before we call DaysInMonth we need to be sure that the month
	; is valid.  If it isn't valid we go to the checkMonth stuff
	; which will fix it, and then jump back to checkDayAgain
	; because changing the month can mean the days can be wrong.
	cmp	bl, MONTHS_PER_YEAR
	jg	monthTooLarge
	cmp	bl, 1
	jl	monthTooSmall

	; Remember that each month has different number of days.
checkDayAgain:

	call	DaysInMonth
	xchg	cx, di				; xchg to access 8 bits
	cmp	bh, cl
	jg	dayTooLarge
	cmp	bh, 1
	jge	checkMonth

	; dayTooSmall

	; The days are too small so we need days in the prior month.
	; Unfortunately, the month may be out of range for DaysInMonth.
	; If they are we let checkMonth fix it.  checkMonth will jump back
	; to checkDay if the month changes.
	xchg	cx, di				; flip back to normal
	dec	bl				; subtract a month
	jle	monthTooSmall

	call	DaysInMonth
	xchg	cx, di				; xchg to access 8 bits

	add	bh, cl				; add days in month
	jmp	checkMonth

dayTooLarge:
	sub	bh, cl				; subtract days in month
	inc	bl				; add a month



checkMonth:
	xchg	cx, di				; flip back from checkDay

	cmp	bl, MONTHS_PER_YEAR
	jg	monthTooLarge
	cmp	bl, 1
	jge	checkDayOfWeek

	; monthTooSmall
monthTooSmall:
	add	bl, MONTHS_PER_YEAR		; add 12 months
	dec	ax				; subtract a year
	cmp	bh, 1
	jge	checkDayAgain

	; If there are too few days then calculate here number of
	; days in the new month and add it to the current days.
	; We do this here instead of going back to check days which
	; will only decrement the month and jump back here!
	call	DaysInMonth
	xchg	cx, di				; xchg to access 8 bits
	add	bh, cl				; add days in month
	xchg	cx, di				; restore from xchg
	jmp	checkDayOfWeek


monthTooLarge:
	sub	bl, MONTHS_PER_YEAR		; subtract 12 months
	inc	ax				; add a year
	jmp	checkDayAgain



checkDayOfWeek:
	cmp	cl, DAYS_PER_WEEK
	jge	daysOfWeekTooLarge
	cmp	cl, 0
	jge	dateNormalized

	add	cl, DAYS_PER_WEEK		; add one week in days
	jmp	dateNormalized

daysOfWeekTooLarge:
	sub	cl, DAYS_PER_WEEK		; subtract one week in days



dateNormalized:
	.leave
	ret
NormalizeTimeDate	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockGetDatelineTime

DESCRIPTION:	Get the system time and normalize it to the dateline time

CALLED BY:	WorldClockUpdateTimeDates, 
		WorldClockSetDateAndTime, 
		WorldClockUpdateDaylightBar


PASS:		es - dgroup

RETURN:		ax - year (1980 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)
		cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		dh - seconds (0 through 59)

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/27/92	Initial version

----------------------------------------------------------------------------@

WorldClockGetDatelineTime	proc	far
	.enter

EC <	call	ECCheckDGroupES					>

	call	TimerGetDateAndTime

	test	es:[systemClockCity], mask HOME_CITY
	jz	setToDestCityTime

	sub	ch, {byte} es:[homeCityTimeZone]
	test	es:[citySummerTime], mask HOME_CITY
	jz	done
	dec	ch				; subtract one hour for summer
	jmp	done


setToDestCityTime:
	sub	ch, {byte} es:[destCityTimeZone]
	test	es:[citySummerTime], mask DEST_CITY
	jz	done
	dec	ch				; subtract one hour for summer

done::

	.leave
	ret
WorldClockGetDatelineTime	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockUpdateOneTimeDate

DESCRIPTION:	

CALLED BY:	WorldClockUpdateTimeDates,
		WorldClockUpdateSelectedTimeZoneTimeDate (Penelope only)

PASS:		ax - year (1980 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)
		cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		ss:bp - UpdateTimeDateParameters (declared at top of file)
		ds	= dgroup

RETURN:		nothing

DESTROYED:	si, bp, di

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/27/92	Initial version

----------------------------------------------------------------------------@

WorldClockCustomDateTimeFormat	TCHAR	" |SW| ", 0

WorldClockUpdateOneTimeDate	proc	far
	uses	ax, bx, cx, dx, ds
	.enter

EC <	call	ECCheckStack						>

	tst	ss:[bp].UTDP_summerTime		; summer time?
	jz	summerTimeAccounted
	inc	ch				; add one to the hour

summerTimeAccounted:
	add	ch, ss:[bp].UTDP_timeZoneHour	; time zone hours
	add	dl, ss:[bp].UTDP_timeZoneMinute	; time zone minutes

	call	NormalizeTimeDate

	; format the time in the registers to the buffer as text
	movdw	esdi, ss:[bp].UTDP_buffer

EC <	push	ax							>
EC <	mov	ax, es							>
EC <	call	ECCheckSegment						>
EC <	pop	ax							>

EC <	push	ds, si							>
EC <	segmov	ds, es							>
EC <	mov	si, di							>
EC <	call	ECCheckBounds						>
EC <	pop	ds, si							>

	; start with the localized time
	push	cx				; save weekday and hours
	mov	si, DTF_HM
	call	LocalFormatDateTime
DBCS  <	shl	cx, 1							>
	add	di, cx				; go to end to append
	pop	cx				; restore weekday and hours


	; append the short form of the weekday
	push	cx				; save weekday and hours
	segmov	ds, cs, si
	mov	si, offset WorldClockCustomDateTimeFormat
	call	LocalCustomFormatDateTime
DBCS  <	shl	cx, 1							>
	add	di, cx				; go to end to append
	pop	cx				; restore weekday and hours


	; lastly, append the localized short form of the date
	push	cx				; save weekday and hours
	mov	si, DTF_SHORT
	call	LocalFormatDateTime
DBCS  <	shl	cx, 1							>
	add	di, cx				; go to end to append
	pop	cx				; restore weekday and hours


	; set dest city time/date from the buffer
	push	bp				; save parameters
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	movdw	bxsi, ss:[bp].UTDP_object	; visual object
	movdw	cxdx, ss:[bp].UTDP_buffer	; fixed buffer

	; insure that the string is good
EC <	push	es, di, cx						>
EC <	movdw	esdi, cxdx						>
EC <	call	LocalStringLength					>
EC <	cmp	cx, DATE_TIME_BUFFER_SIZE				>
EC <	ERROR_G WC_ERROR_BAD_STRING					>
EC <	pop	es, di, cx						>

	mov	bp, VUM_NOW
	mov	di, mask MF_CALL
	call	ObjMessage			; ax, cx, dx, bp destroyed
	pop	bp				; restore parameters

	.leave
	ret
WorldClockUpdateOneTimeDate	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockUpdateWorldClockTitleTime

DESCRIPTION:	Update the time in the WorldClockHeader

CALLED BY:	WorldClockUpdateTimeDates

PASS:		ax - year (1980 through 2099)
		bl - month (1 through 12)
		bh - day (1 through 31)
		cl - day of the week (0 through 6, 0 = Sunday, 1 = Monday...)
		ch - hours (0 through 23)
		dl - minutes (0 through 59)
		ds - dgroup

RETURN:		nothing

DESTROYED:	si, bp, di

PSEUDO CODE/STRATEGY:
	The World Clock title is in a special moniker gstring with an 
	18 point font.  We prefer to modify the moniker to avoid dynamically
	recreating it.  It is also fixed in length to avoid reallocating it.
	There are extra zeros on the end.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/13/93		Initial version

----------------------------------------------------------------------------@

WorldClockUpdateWorldClockTitleTime	proc	far
	class	GenClass
	uses	ax, bx, cx, dx, ds, es
titleObject	local	nptr			; TitleGlyph or Primary?
titleString	local	(32 + DATE_TIME_FORMAT_SIZE) dup (char)

	.enter

EC <	call	ECCheckStack						>

	mov_tr	di, ax				; save year

	test	ds:[systemClockCity], mask HOME_CITY
	jz	destCityTime

	mov	ax, ds:[homeCityTimeZone]

	test	ds:[citySummerTime], mask HOME_CITY	; summer time?
	jz	haveSystemTime
	inc	ch				; add one to the hour
	jmp	haveSystemTime


destCityTime:
	mov	ax, ds:[destCityTimeZone]
	test	ds:[citySummerTime], mask DEST_CITY	; summer time?
	jz	haveSystemTime
	inc	ch				; add one to the hour

haveSystemTime:
	add	ch, al				; time zone hours
	add	dl, ah				; time zone minutes
	mov_tr	ax, di				; restore year

	call	NormalizeTimeDate


	; If the app displays the primary's title bar we update the
	; time in that visual moniker.  Otherwise we update the
	; TitleGlyph's visual moniker.
	cmp	ds:[haveTitleBar], TRUE
	je	titleBarAddress

	mov	titleObject, offset TitleGlyph
	; we are going to write the formatted time directly into the 
	; TitleGlyph's visMoniker.  So get the offsets.
	GetResourceHandleNS	TitleGlyph, bx
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	es, ax
	mov	di, offset TitleGlyph
	mov	di, es:[di]			; dereference title glyph
	add	di, es:[di].Gen_offset
	mov	di, es:[di].GI_visMoniker
	mov	di, es:[di]			; dereference visMoniker
	add	di, size VisMoniker + 15	; first char of title text
	push	bx				; save TitleGlyph handle
	jmp	haveStringToCopyTo

titleBarAddress:
	mov	titleObject, offset WorldClockPrimary

	segmov	es, ss
	lea	di, titleString

haveStringToCopyTo:

	; format the time in the registers to the buffer as text.  The
	; format contains the TitleGlyph text and time format codes and is
	; in a localizable resource.
	GetResourceHandleNS	worldClockTitle, bx
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	ds, ax
	mov	si, offset worldClockTitle
	mov	si, ds:[si]			; dereference chunk
	LocalCopyString				; copy the title string

	; append the localized time
	dec	di				; back over the null char
DBCS  <	dec	di				; ... 2-byte case	>
	mov	si, DTF_HM
	call	LocalFormatDateTime
DBCS  <	shl	cx, 1							>
	add	di, cx				; go to end to append

	cmp	titleObject, offset TitleGlyph	; have title glyph?
	jne	updateTitleGlyph

	; append trailing spaces for balance and to write over junk
	; from prior longer strings.  Needed for the title glyph.
	mov	si, offset worldClockTitleSpaces
	mov	si, ds:[si]			; dereference chunk
	LocalCopyString

	call	MemUnlock			;unlock worldClockTime resource

	segmov	ds, es				; object segment
	mov	si, offset TitleGlyph		; object handle
	mov	cl, mask VOF_GEOMETRY_INVALID or mask VOF_IMAGE_INVALID
	mov	dl, VUM_NOW
	call	VisMarkInvalid

	pop	bx				; save TitleGlyph handle
	call	MemUnlock			; unlock TitleGlyphResource

	push	bp				; save local variables
	mov	ax, MSG_VIS_VUP_UPDATE_WIN_GROUP
	mov	si, offset TitleGlyph		; reuse bx from above
	jmp	sendTheUpdateMessage

updateTitleGlyph:

	call	MemUnlock			;unlock worldClockTime resource

	push	bp				; save local variables
	mov	ax, MSG_GEN_REPLACE_VIS_MONIKER_TEXT
	mov	cx, es
	lea	dx, titleString
	mov	bp, VUM_NOW
	GetResourceHandleNS	WorldClockPrimary, bx
	mov	si, offset WorldClockPrimary


sendTheUpdateMessage:
	mov	di, mask MF_CALL
	call	ObjMessage


	pop	bp				; restore variable frame

	.leave
	ret
WorldClockUpdateWorldClockTitleTime	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockSetDateAndTime

DESCRIPTION:	Set the system time and date

CALLED BY:	WorldClockSetSystemClock

PASS:		es - dgroup
		di - city to set time to

RETURN:		es:[systemClockCity]

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/29/92	Initial version

----------------------------------------------------------------------------@

WorldClockSetDateAndTime	proc	far
	.enter

EC <	call	ECCheckDGroupES						>

	call	WorldClockGetDatelineTime

	test	di, mask HOME_CITY
	jz	setToDestCityTime

	add	ch, {byte} es:[homeCityTimeZone]
	test	es:[citySummerTime], mask HOME_CITY
	jz	timeCalced
	inc	ch				; add one hour for summer
	jmp	timeCalced


setToDestCityTime:
	add	ch, {byte} es:[destCityTimeZone]
	test	es:[citySummerTime], mask DEST_CITY
	jz	timeCalced
	inc	ch				; add one hour for summer

timeCalced:
	call	NormalizeTimeDate

	ornf	cl, mask SDTP_SET_DATE or mask SDTP_SET_TIME
	call	TimerSetDateAndTime

	mov	ax, di
	call	SetHomeIsSystemClock

	.leave
	ret
WorldClockSetDateAndTime	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockUpdateDaylightBar

DESCRIPTION:	Redraw the daylight bar as the time changes.

CALLED BY:	WorldClockExposed
		WorldClockUpdateTimeDate

PASS:		di - graphics handle to GenView (0 if none)
		es - dgroup

RETURN:		nothing

DESTROYED:	ax, bx, cx, dx
		di if no handle passed

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	12/18/92	Initial version

----------------------------------------------------------------------------@

WorldClockUpdateDaylightBar	proc	far
	uses	bp, ds
	.enter

EC <	call	ECCheckDGroupES					>

	cmp	es:[uiSetupSoUpdatingUIIsOk], FALSE
LONG	je	done


	; The daylight covers half of the world and starts a quarter through
	; the day.  So  
	; daylight position = current time in minutes	world width
	;		      ----------------------- + -----------
	;		      minutes per day		4

	call	WorldClockGetDatelineTime	; ch - hours, dl - minutes
	call	NormalizeTimeDate		; make sure time is normal
						; fixes bug between 0-7 am

	; calculate the time elasped in minutes
	mov	al, MINUTES_PER_HOUR
	mul	ch
	clr	dh
	add	ax, dx

	mov	bx, es:[worldWidth]
	mul	bx
	mov	cx, MINUTES_PER_HOUR * HOURS_PER_DAY
	div	cx
	neg	ax				; as hours pass the daylight
						; moves to the left...
	shr	bx, 1
	shr	bx, 1
	add	ax, bx

	; if the world map view was exposed then a handle will have
	; been passed (non zero).  If so then draw no matter what.
	mov	bp, di				; save whether handle passed
	tst	di
	jnz	updateDaylight

	; update the daylight display if different than before, otherwise exit
	; since the daylight displayed is correct and visible.
	cmp	ax, es:[daylightStart]
LONG	je	done

	mov	di, es:[winHandle]		; GenView window handle
	call	GrCreateState 			; returns gstate in di


updateDaylight:

	push	bp				; save if gstate passed

	mov	es:[daylightStart], ax

	mov	si, ax				; save daylight position

	; draw the background for the daylight bar
	; because there is a sun icon which must be erased, we must wipe
	; out the whole daylight bar and then draw a grayish pattern with mask
	; the area color now is black

	; wipe out the daylight and sun icon
	clr	ax, bx
	mov	cx, WORLD_MAP_WIDTH
	mov	dx, DAYLIGHT_AREA_HEIGHT -1
	call	GrFillRect

	; draw grayish pattern
	mov	ax, CF_INDEX shl 8 or C_WHITE
	call	GrSetAreaColor
	mov	al, SDM_50
	call	GrSetAreaMask
	mov	ax, bx				; clr for 0,0 coordinate
	call	GrFillRect

	; undo the area mask change
	mov	al, SDM_100
	call	GrSetAreaMask


	; draw a line to separate the daylight bar from the map
	mov	al, bl
	mov	bx, dx
	call	GrDrawLine		; line seperating daylight from map

	; draw the daylight bar
	mov	bx, 1			; set rectangle within background
	dec	dx
	mov	ax, si			; daylight position
	mov	cx, es:[worldWidth]
	shr	cx, 1			; daylight covers half the world
	add	cx, si
	call	GrFillRect

	push	ax, bx			; save position for the sun icon

	; draw the second daylight bar.  It covers daylight wraparound
	mov	si, es:[worldWidth]
	add	ax, si
	add	cx, si
	call	GrFillRect

	; draw the third daylight bar on the other side of the first bar.
	shl	si, 1				; double
	sub	ax, si
	sub	cx, si
	call	GrFillRect

	; we now draw the sun icon at the horizontal center of the
	; daylight patches we just drew
	; get the sun icon in ds:si
	shr	si, 1			; reduce back to width of world
	mov	cx, si			; width of world before si trashed
	mov	bp, si			; width of world before si trashed

	GetResourceHandleNS	ErrorBlock, bx
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	ds, ax
	mov	si, offset SunIcon
	mov	si, ds:[si]			; sun icon

	pop	ax, bx				; start position of daylight 
	shr	cx, 1				; makes width of daylight
	shr	cx, 1				; makes center of daylight
	add	ax, cx
	sub	ax, SUN_ICON_WIDTH / 2		; center the sun icon
	mov	cx, bp				; width of world
	clr	dx				; no callback routine
	call	GrDrawBitmap


	; draw the second sun icon
	add	ax, bp
	add	cx, bp
	call	GrDrawBitmap

	; draw the third sun icon
	shl	bp, 1				; double 
	sub	ax, bp
	sub	cx, bp
	call	GrDrawBitmap


	; we no longer need the sun icon so free it's resource
	GetResourceHandleNS	ErrorBlock, bx
	call	MemUnlock


	pop	bp				; restore passed gstate
	tst	bp				; was a gstate passed?
	jnz	done				; destroy if gstate created
	call	GrDestroyState

done:
	.leave
	ret
WorldClockUpdateDaylightBar	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_SET_SYSTEM_CLOCK for WorldClockProcessClass

DESCRIPTION:	

PASS:		es - dgroup
		cx - selection identifier


RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/92	Initial version

1 1	right
0 1	left


----------------------------------------------------------------------------@
WorldClockSetSystemClock	method dynamic WorldClockProcessClass, \
				MSG_WC_SET_SYSTEM_CLOCK
	.enter

EC <	mov	ax, es				; check dgroup		>
EC <	call	ECCheckSegment						>


	; if city selected is the city currently used for the system
	; time then do not do anything.  Most importantly we are to avoid
	; bothering the user with an approval message for something
	; which doesn't need to be done.
	cmp	es:[systemClockCity], cl
	je	done

	; the home city must be selected to do this
	cmp	es:[homeCityPtr], CITY_NOT_SELECTED
	je	dontSetTime

	; the dest city must be selected to do this
	cmp	es:[destCityPtr], CITY_NOT_SELECTED
	je	dontSetTime


	push	cx				; save the city

	cmp	cx, mask HOME_CITY
	jne	setToDestCity
	GetResourceHandleNS	homeCityText, cx
	mov	dx, offset homeCityText
	jmp	confirmSettingSystemClock

setToDestCity:
	GetResourceHandleNS	destCityText, cx
	mov	dx, offset destCityText

confirmSettingSystemClock:
	mov	bp, WC_MSG_NOTIFY_ABOUT_TO_SET_SYSTEM_CLOCK
	clr	bx, si				; no second arg
	mov	ax, MSG_WC_DISPLAY_USER_MESSAGE_OPTR	; args are optrs
	call	DisplayUserMessage		; put up an error dialog box

	pop	cx				; restore the city
	cmp	ax, IC_YES
	jne	dontSetTime

	mov	di, cx				; city for system time

	call	WorldClockSetDateAndTime

	call	WorldClockUpdateTimeDates

	jmp	done

dontSetTime:
	; The user has decided to not change the system clock.  We must
	; undo the ui changes.  We must pass it the other city.  The
	; easiest way is to toggle the city bits.
	not	cx
	andnf	cx, mask HOME_CITY or mask DEST_CITY
	clr	dx				; not indeterminate

	; send the item identifier in a selection message
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	GetResourceHandleNS	SetSystemClock, bx
	mov	si, offset SetSystemClock
	clr	di
	call	ObjMessage

done:
	.leave
	ret
WorldClockSetSystemClock	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_SET_SUMMER_TIME for WorldClockProcessClass

DESCRIPTION:	

PASS:		es - dgroup
		cx - city types that are selected
		bp - booleans whose state has changed

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/92	Initial version

1 2 10	both (left)
0 2 10	both (right)
1 1 01	right
0 1 01	left
f 0 00	none

----------------------------------------------------------------------------@
WorldClockSetSummerTime	method dynamic WorldClockProcessClass, \
				MSG_WC_SET_SUMMER_TIME
	.enter

EC <	call	ECCheckDGroupES						>

	;
	; In the dove ui the boolean items are split into two boolean
	; groups so you only get the status of one item at a time.
	; Consequently, we need to get the status of both items and
	; or them together to give us what this function expects.
	;

	call	SetCitySummerTime

	call	WorldClockUpdateTimeDates

	.leave
	ret
WorldClockSetSummerTime	endm


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldMapDrawTimeZone

DESCRIPTION:	This inverts 25% of the pixels in a time zone

CALLED BY:	

PASS:		al - time zone hour
		ah - time zone minutes
		di - GState handle
		es - dgroup
		ds - time zone info segment (LOCKED)

RETURN:		nothing

DESTROYED:	cx, si

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/26/92	Initial version

----------------------------------------------------------------------------@

WorldMapDrawTimeZone	proc	far
	uses	ax, bx
	.enter

EC <	call	ECCheckDGroupES						>
EC <	push	ax							>
EC <	mov	ax, ds				; check time zone info block >
EC <	call	ECCheckSegment						>
EC <	call	ECCheckGStateHandle					>
EC <	pop	ax							>

	mov	bp, di				; save graphics state
	clr	si				; start at first nptr

	; The polygons' coordinates use the map as the origin.  Translate
	; the graphics transformation matrix over to the map's origin.
	push	ax				; save time zone
	call	GrSaveTransform			; restore later - safer way
	clr	ax, cx, dx
	mov	bx, DAYLIGHT_AREA_HEIGHT
	call	GrApplyTranslation
	pop	ax				; restore time zone

loopTestTimeZone:
	shl	si, 1				; index into words
	mov	di, ds:[si]
	cmp	{word}ds:[di].TZE_hour, ax	; correct time zone?
	jne	timeZoneChecked
;	cmp	ds:[di].TZE_minute, al		; correct time zone?
;	jne	timeZoneChecked

	push	si, di, ax
	clr	ch
	mov	cl, ds:[di].TZE_pointCount
	lea	si, ds:[di].TZE_data
	mov	di, bp				; graphics state
	mov	al, RFR_ODD_EVEN
	call	GrFillPolygon
	pop	si, di, ax


timeZoneChecked:
	shr	si, 1				; words nptr to index
	inc	si
	cmp	si, es:[timeZoneCount]
	jl	loopTestTimeZone



	mov	di, bp				; restore graphics state

	call	GrRestoreTransform

	.leave
	ret
WorldMapDrawTimeZone	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_META_PTR for WorldClockProcessClass

DESCRIPTION:	Find the time zone containing the point selected and display 
		the new time zone.

PASS:		cx = pointer x position
		dx = pointer y position
		bp low = ButtonInfo
		bp high = ShiftState
		es - dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/26/92	Initial version
	rsf	3/16/93		Removed toggling time zones

----------------------------------------------------------------------------@
WorldClockViewPointSelected	method dynamic WorldClockProcessClass, MSG_META_START_SELECT
	.enter

EC <	mov	ax, es				; check dgroup		>
EC <	call	ECCheckSegment						>


	tst	es:[uiSetupSoUpdatingUIIsOk]
LONG	jz	done

	; is the left mouse button just pressed down?
	andnf	bp, mask ButtonInfo		; technically this isn't needed
	cmp	bp, BUTTON_0 shl offset BI_BUTTON or mask BI_PRESS or mask BI_B0_DOWN
LONG	jne	done

	sub	dx, DAYLIGHT_AREA_HEIGHT
LONG	jl	done


	; At this point we have the coordinates in (cx, dx).  If we are in
	; UserCityMode then we stash the coordinates.  Otherwise we treat
	; the action as the user selecting a time zone.

	tst	es:[userCityMode]
	jz	timeZoneSelected

	; the user's city is placed at the last selected coordinate.
	mov	es:[tempUserCityX], cx
	mov	es:[tempUserCityY], dx


	call	BlinkerMove			; move to where user tapped

	jmp	done

	; lock the time zone block
timeZoneSelected:
	mov	bx, es:[timeZoneInfoHandle]
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	ds, ax

	call	WorldClockResolvePointToTimeZone

	push	ax				; save time zone

	mov	di, es:[winHandle]		; set ^hdi = window handle
	call	GrCreateState 			; returns gstate in di


	; we prefer a look of partially inversion as opposed to 100%
	mov	al, SDM_12_5
	call	GrSetAreaMask

	; invert the time zones
	mov	al, MM_INVERT
	call	GrSetMixMode

	; clear up any showing time zone
	mov	ax, es:[selectedTimeZone]
	pop	bx				; restore new time zone
	cmp	ax, bx
	je	timeZonesGraphicallyDone	;do nothing - they are the same


	cmp	ax, NO_TIME_ZONE
	je	newTimeZone
	call	WorldMapDrawTimeZone

	; display a time zone only if it is new, otherwise turn off (toggle)
newTimeZone:
	xchg	ax, bx				; ax = new time zone, save bx
;	cmp	al, NO_TIME_ZONE
;	je	timeZonesGraphicallyDone


	call	WorldMapDrawTimeZone


timeZonesGraphicallyDone:
	call	GrDestroyState 			; destroy our gstate

	push	bx				; save old time zone
	mov	bx, es:[timeZoneInfoHandle]
	call	MemUnlock
	pop	bx				; restore old time zone


	; update times if the new time zone is different than before
	cmp	ax, bx
	je	done

	mov	cx, ax				; new time zone
	call	SetSelectedTimeZone
	call	WorldClockUpdateTimeDates

done:

	.leave
	ret
WorldClockViewPointSelected	endm



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockResolvePointToTimeZone

DESCRIPTION:	

CALLED BY:	WorldClockUseCity
		WorldClockUserModeKBDChar
		WorldClockUpdateUserCities
		WorldClockViewPointMoved

PASS:		es - dgroup
		ds - time zone segment
		cx - x coordinate
		dx - y coordinate

RETURN:		al - time zone hour
		ah - time zone minute

DESTROYED:	di, si

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/5/92		Initial version

----------------------------------------------------------------------------@

WorldClockResolvePointToTimeZone	proc	far
	.enter

EC <	call	ECCheckDGroupES						>
EC <	mov	ax, ds				; check time zone segment >
EC <	call	ECCheckSegment						>

	clr	si					; start at first nptr

loopTestTimeZone:
	shl	si, 1					; index into words
	mov	di, ds:[si]
	call	IsPointInTimeZone
	jc	resolvedTimeZone

	shr	si, 1					; words nptr to index
	inc	si
	cmp	si, es:[timeZoneCount]
	jl	loopTestTimeZone

	; default for when the point is not in a time zone
	mov	ax, NO_TIME_ZONE			; default to first zone
	jmp	done

resolvedTimeZone:
	mov	di, ds:[si]				; time zone entry
	mov	ax, {word}ds:[di].TZE_hour		; time zone hour

done:	
	.leave
	ret
WorldClockResolvePointToTimeZone	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	IsPointInTimeZone

DESCRIPTION:	Calculate if the passed point is within the passed time zone.

CALLED BY:	WorldClockResolvePointToTimeZone

PASS:		*ds:di - fptr to time zone element
		es - dgroup
		cx - x coordinate
		dx - y coordinate

RETURN:		carry set if point is in time zone
		carry clear if point is not in time zone

DESTROYED:	

PSEUDO CODE/STRATEGY:
	Fail if the point is outside the time zone extents.
	for each polygon edge
		if below and above edge endpoints
		calculate intersection between edge and horizontal line from point
		if point is greater than intersection then increment counter
	if counter is odd then point is in
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/ 5/92	Initial version

----------------------------------------------------------------------------@

X1	equ	0 * size word
Y1	equ	1 * size word
X2	equ	2 * size word
Y2	equ	3 * size word
nextXY	equ	2 * size word

IsPointInTimeZone	proc	far
rise	local	sword
run	local	sword
x2	local	sword
y2	local	sword
firstPoint	local	nptr
count	local	word
	uses	si
	.enter

EC <	call	ECCheckDGroupES					>

	cmp	cx, ds:[di].TZE_leftExtent
LONG	jl	isntPoint

	cmp	cx, ds:[di].TZE_rightExtent
LONG	jge	isntPoint

	clr	ax, count
	mov	al, ds:[di].TZE_pointCount	; high byte clear
	mov	si, ax
	add	di, TZE_data			; start at the first line
	mov	firstPoint, di

loopTestEdgeAndGetSecondPointNormally:
	mov	ax, ds:[di].X2
	mov	x2, ax
	mov	ax, ds:[di].Y2
	mov	y2, ax

	; does the line intersect horizontally?
loopTestEdge:
	mov	ax, ds:[di].Y1
	cmp	ax, y2
	jg	secondEndpointSmaller

	cmp	dx, ds:[di].Y1
	jl	nextPoint

	cmp	dx, y2
	jge	nextPoint
	jmp	findIntersection

secondEndpointSmaller:
	cmp	dx, y2
	jl	nextPoint

	cmp	dx, ds:[di].Y1
	jge	nextPoint

	; find the point of intersection between the line and a horizontal 
	; line passing through the point.  If the point's x position is 
	; greater then increment a pointer.  Use the odd/even polygon filling
	; rule to determine if the point is within the polygon.

	; 2 point line equation: (y - y1) = (y1 - y2)/(x1 - x2)*(x - x1)

	; intersection equation: x = x1 + (y - y1)*(x1 - x2)/(y1 - y2)

findIntersection:
;	mov	ax, ds:[di].Y1
	sub	ax, y2
	jz	nextPoint
	mov	rise, ax
	mov	ax, ds:[di].X1
	sub	ax, x2
	jnz	notVerticalLine	

	mov	ax, ds:[di].X1
	jmp	checkIfPointXGreaterThanIntersectionX

notVerticalLine:
	mov	run, ax

	push	dx				; save y point
	mov	ax, dx
	sub	ax, ds:[di].Y1
	imul	run
	idiv	rise
	; The result of the above division needs to be rounded to maintain
	; accurate calculations.  Without rounding truncation happens.  
	; This can lead to different values when the points are 
	; reversed.  This is a problem because the IsPointInTimeZone
	; requires that the point be on one side or the other of the line,
	; but if the value changes then the point can appear to be neither.
	; A sample case to work things out is (41,59) (43,47) and p (43,48).
	; The x with the line one direction leads to a y intersection
	; at 41 + 1R10 and the other way is 43 + 0R2.

	; round by incrementing the result if the remainder is ge to half.
	; do this easily by doubling the remainder and comparing to divisor.
	shl	dx, 1				; multiply by 2

	; dx is always positive, make dx match the sign of rise for a good comparison.
	cmp	rise, 0
	jge	risePositive
	neg	dx
	cmp	dx, rise
	jge	rounded
	dec	ax				; round the quotient (ax) down
risePositive:
	cmp	dx, rise
	jl	rounded
	inc	ax				; round the quotient (ax) up 
rounded:

	add	ax, ds:[di].X1
	pop	dx				; restore y point

checkIfPointXGreaterThanIntersectionX:
	cmp	cx, ax				; intersection x point to x point
	jl	nextPoint
	inc	count

nextPoint:
	dec	si
	jz	testedAllEdges

	add	di, nextXY

	cmp	si, 1				; last point
	jne	loopTestEdgeAndGetSecondPointNormally

	mov	si, firstPoint
	mov	ax, ds:[si].X1
	mov	x2, ax
	mov	ax, ds:[si].Y1
	mov	y2, ax
	mov	si, 1				; last point
	jmp	loopTestEdge
	
testedAllEdges:
	test	count, 1			; odd or even?
	jz	isntPoint

	stc
	jmp	done

isntPoint:
	clc

done:
	.leave
	ret
IsPointInTimeZone	endp



COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_TIMER_TICK for WorldClockProcessClass

DESCRIPTION:	Intercept every timer tick and update the time objects
		every minute.

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	1/4/93		Initial version

----------------------------------------------------------------------------@


WorldClockTimerTick	method dynamic WorldClockProcessClass, MSG_WC_TIMER_TICK
	.enter

EC <	call	ECCheckDGroupES						>

	cmp	es:[destCityPtr], CITY_NOT_SELECTED
	je	dontBlinkDestCity

	cmp	es:[destCityCanBlink], FALSE
	je	dontBlinkDestCity

	call	BlinkerBlink

dontBlinkDestCity:
	sub	es:[minuteCountdown], TICKS_PER_SECOND	; length of timer
	jnz	done

	call	WorldClockUpdateTimeDates

	mov	es:[minuteCountdown], TICKS_PER_SECOND * SECONDS_PER_MINUTE

done:
	.leave
	ret
WorldClockTimerTick	endm



COMMENT @-------------------------------------------------------------------

FUNCTION:	BlinkerStop

DESCRIPTION:	Stop the blinking indicator

CALLED BY:	BlinkerMove, OptionsInteractionInitiate

PASS:		es	- dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	5/27/93		Initial version

----------------------------------------------------------------------------@

BlinkerStop	proc	near

	mov	es:[destCityCanBlink], FALSE
	clr	es:[blinkerCountOfBlinksLeftToDisplayBlinkerBecauseItJustMoved]

	cmp	es:[destCityBlinkDrawn], FALSE
	je	destCityNotBlinking

	call	BlinkerBlink

destCityNotBlinking:

	ret
BlinkerStop	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	BlinkerMove

DESCRIPTION:	Safely move the blinker

CALLED BY:	WorldClockUpdateUserCities, WorldClockViewPointSelected,
		BlinkerShowDestCity, InitiateSetLocationDialogAndBlinker

PASS:		cx, dx	- new blinker coordinates

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	5/27/93		Initial version

----------------------------------------------------------------------------@

BlinkerMove	proc	near
	.enter

EC <	call	ECCheckDGroupES						>

	call	BlinkerStop

	mov	es:[blinkerX], cx
	mov	es:[blinkerY], dx

	cmp	es:[destCityBlinkDrawn], FALSE
	jne	blinkerVisible


	; this ensure that the blinker won't get erased as soon as it's 
	; drawn.  This means that the blinker should be displayed at least
	; twice.  Once is to display it.  Twice is keep it displayed 
	; for the next blink so that it appears for an entire blink.
	; Without this scheme the blinker can be erased as soon as it's
	; been moved.
	mov	es:[blinkerCountOfBlinksLeftToDisplayBlinkerBecauseItJustMoved], 2

	; call BlinkerOn after all the ui stuff has settled down.  We force
	; it on the queue so it occurs after the ui junk.
	mov	ax, MSG_WC_BLINKER_ON
	call	GeodeGetProcessHandle
	mov	di, mask MF_FORCE_QUEUE
	call	ObjMessage


blinkerVisible:

	.leave
	ret
BlinkerMove	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	BlinkerBlink

DESCRIPTION:	Visually toggle the Destination City indicator

CALLED BY:	WorldClockTimerTick, BlinkerStop, BlinkerOn

PASS:		es	- dgroup
		destCityCanBlink
		destCityBlinkDrawn

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	xor the blinker and toggle destCityBlinkDrawn
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	5/21/93		Initial version

----------------------------------------------------------------------------@

BlinkerBitmap	label	word
	Bitmap	<DEST_X_WIDTH, DEST_X_HEIGHT, 0, BMF_MONO>
	db	11000001b, 10000000b
	db	11100011b, 10000000b
	db	01110111b, 00000000b
	db	00111110b, 00000000b
	db	00011100b, 00000000b
	db	00111110b, 00000000b
	db	01110111b, 00000000b
	db	11100011b, 10000000b
	db	11000001b, 10000000b



BlinkerBlink	proc	near
	uses 	ax, bx, dx, di, si, ds
	.enter

EC <	call	ECCheckDGroupES						>


	cmp	es:[uiSetupSoUpdatingUIIsOk], FALSE
	je	done

	cmp	es:[uiMinimized], TRUE
	je	done

	; used to make the blinker nicely visible after a move.  See BlinkerMove.
	cmp	es:[blinkerCountOfBlinksLeftToDisplayBlinkerBecauseItJustMoved], 0
	je	toggleBlinker

	; decrement because we're skipping the blinking this time
	dec	es:[blinkerCountOfBlinksLeftToDisplayBlinkerBecauseItJustMoved]


	; if the blinker is drawn then leave without undrawing it
	; if it isn't drawn then draw it now.  This assures that the
	; blinker is drawn for at least one complete blink when moved
	cmp	es:[destCityBlinkDrawn], 0
	jne	done

toggleBlinker:
	xor	es:[destCityBlinkDrawn], 1	; flip FALSE -> TRUE -> FALSE

	mov	di, es:[winHandle]		; set ^hdi = window handle
	call	GrCreateState 			; returns gstate in di

	mov	al, MM_INVERT
	call	GrSetMixMode


	; draw the destination 'X' bitmap centered on the city coordinate
	mov	ax, es:[blinkerX]
	sub	ax, DEST_X_WIDTH / 2
	mov	bx, es:[blinkerY]
	add	bx, DAYLIGHT_AREA_HEIGHT - (DEST_X_HEIGHT / 2)
	segmov	ds, cs
	mov	si, offset BlinkerBitmap
	clr	dx
	call	GrFillBitmap

	call	GrDestroyState

done:

	.leave
	ret
BlinkerBlink	endp



COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_BLINKER_ON for WorldClockProcessClass

DESCRIPTION:	Turn on and display the blinker

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/15/93		Initial version

----------------------------------------------------------------------------@
BlinkerOn	method dynamic WorldClockProcessClass, MSG_WC_BLINKER_ON
	.enter

	mov	es:[destCityCanBlink], TRUE

	call	BlinkerBlink

	.leave
	ret
BlinkerOn	endm


COMMENT @-------------------------------------------------------------------

FUNCTION:	BlinkerShowDestCity

DESCRIPTION:	Show the destination city.  Handles user cities too.

CALLED BY:	

PASS:		es	- dgroup

RETURN:		nothing

DESTROYED:	cx, dx, 

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	5/28/93		Initial version

----------------------------------------------------------------------------@

BlinkerShowDestCity	proc	near
	.enter

	test	es:[userCities], mask DEST_CITY
	jnz	userCity
	mov	cx, es:[destCityX]
	mov	dx, es:[destCityY]
	jmp	show

userCity:
	mov	cx, es:[userCityX]
	mov	dx, es:[userCityY]

show:
	call	BlinkerMove

	.leave
	ret
BlinkerShowDestCity	endp

COMMENT @------------------------------------------------------------------

METHOD:		MSG_WC_START_USER_CITY_MODE for WorldClockProcessClass

DESCRIPTION:	Disable the Options dialog and ready the location selection.

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	Disable the Options dialog box
	Initiate the CitySelectionsInteraction


	This is partially duplicated in OptionsApply

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/ 2/93		Initial version

----------------------------------------------------------------------------@
WorldClockStartUserCityMode	method dynamic WorldClockProcessClass, MSG_WC_START_USER_CITY_MODE
	.enter

	mov	ds:[userCityMode], TRUE

	; dismiss the Options dialog because it is in the way of the map.
	mov	ax, MSG_GEN_GUP_INTERACTION_COMMAND
	mov	cx, IC_DISMISS
	mov	di, mask MF_CALL
	GetResourceHandleNS	OptionsGroup, bx
	mov	si, offset OptionsGroup
	call	ObjMessage


	call	InitiateSetLocationDialogAndBlinker


	.leave
	ret
WorldClockStartUserCityMode	endm




COMMENT @-------------------------------------------------------------------

FUNCTION:	InitiateSetLocationDialogAndBlinker

DESCRIPTION:	Handle setting up the dialog and blinker

CALLED BY:	WorldClockStartUserCityMode
		OptionsInteractionApplyRoutine

PASS:		

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/15/93		Initial version

----------------------------------------------------------------------------@

InitiateSetLocationDialogAndBlinker	proc	near
	.enter
	; the Options dialog has been dismissed and so isn't visible


	; make the normal ui gadetry below the map disappear
	mov	dl, VUM_NOW
	ObjCall	MSG_GEN_SET_NOT_USABLE, HomeDestOptionsInteraction

	; now enable the user city selection box to instruct the user what 
	; to do and to give the user a way to indicate when they are done.
	mov	dl, VUM_NOW
	ObjSend	MSG_GEN_SET_USABLE, UserCitySelectionInteraction


	; The user is about to change the user city location.  Show it's
	; current location if it hasn't been set before.  It hasn't been set
	; if both x and y are zero.  If never set, then let the user see 
	; where the home city is.
	mov	cx, es:[tempUserCityX]
	mov	dx, es:[tempUserCityY]

	cmp	cx, dx				; check if both possibly zero
	jne	showBlinker

	tst	cx				; both same, are both zero?
	jnz	showBlinker

	mov	cx, es:[homeCityX]
	mov	dx, es:[homeCityY]

showBlinker:
	call	BlinkerMove

	.leave
	ret
InitiateSetLocationDialogAndBlinker	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_GEN_INTERACTION_INITIATE for OptionsInteractionClass

DESCRIPTION:	Intercept because sometimes the dialog is reset and sometimes not.

PASS:		es:[userCityMode]
		lots of dgroup variables

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
	This routines relies on the fact that es is FIXED an will never move.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/ 8/93		Initial version

----------------------------------------------------------------------------@
OptionsInteractionInitiate	method dynamic OptionsInteractionClass, MSG_GEN_INTERACTION_INITIATE
	.enter

	call	BlinkerStop

	push	cx, dx, bp, si			; save for superclass

	; We do not initialize the dialog box if we are in user city mode 
	; because we are returning from setting the user city's location
	tst	es:[userCityMode]
	jnz	inUserCityMode


	; copy tempUserCity back into userCity.  userCity values were copied
	; into temp during the OptionBox's initialization.
	mov	ax, es:[userCityX]
	mov	es:[tempUserCityX], ax
	mov	ax, es:[userCityY]
	mov	es:[tempUserCityY], ax


	; set this to relect the current value
	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cl, es:[systemClockCity]
	clr	ch
	clr	dx
	GetResourceHandleNS	SetSystemClock, bx
	mov	si, offset SetSystemClock
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage


	; set this to relect the current value

	mov	ax, MSG_GEN_ITEM_GROUP_SET_SINGLE_SELECTION
	mov	cl, es:[citySummerTime]
	clr	ch
	clr	dx
	GetResourceHandleNS	SetSummerTime, bx
	mov	si, offset SetSummerTime
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage



	; set this to relect the current value
	mov	ax, MSG_VIS_TEXT_REPLACE_ALL_PTR	; buffer in dx:bp
	mov	dx, es				; buffer segment
	mov	bp, offset userCityName
	clr	cx				; null terminated
	GetResourceHandleNS	UserCityText, bx
	mov	si, offset UserCityText
	mov	di, mask MF_CALL or mask MF_FIXUP_DS
	call	ObjMessage


	jmp	callSuperClass


	; Restore the ui to normal by disabling the user city selection
	; interaction and enabling the normal gadetry below the map.
	; The location has changed so the dialog should be applyable...
inUserCityMode:

	; make the user city selection interaction disappear
	mov	dl, VUM_NOW
	ObjCall	MSG_GEN_SET_NOT_USABLE, UserCitySelectionInteraction, \
		<mask MF_FIXUP_DS>

	; make the normal ui gadetry below the map appear
	mov	dl, VUM_NOW
	ObjCall	MSG_GEN_SET_USABLE, HomeDestOptionsInteraction, \
		<mask MF_FIXUP_DS>

	cmp	es:[userCityMode], 2
	jne	noIntercept

	; This is when the set location dialog was displayed because
	; the user neglected to set it after setting the user city name.
	; Don't pop up the dialog box again. Just apply the settings.
	mov	es:[userCityMode], FALSE
	call	OptionsInteractionApplyRoutine

	; Normally the destination city is shown when Options Interaction
	; visually closes.  But in this case we haven't put the
	; interaction up. So we explicitly show the dest city now.
	call	BlinkerShowDestCity

	add	sp, 4 * size word		; discard four pushed registers
	jmp	done


noIntercept:
	ObjSend	MSG_GEN_MAKE_APPLYABLE, SetUserCityLocation, <mask MF_FIXUP_DS \
		or mask MF_FORCE_QUEUE>


callSuperClass:
	pop	cx, dx, bp, si

	mov	es:[userCityMode], FALSE

	mov	ax, MSG_GEN_INTERACTION_INITIATE
	mov	di, offset OptionsInteractionClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret
OptionsInteractionInitiate	endm



COMMENT @------------------------------------------------------------------

METHOD:		MSG_GEN_APPLY for OptionsInteractionClass

DESCRIPTION:	Apply the user city info and then call the super class for rest

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:

	There are three possibilities on entering this routine with sections
	of code to handle each one.

	NO USER CITY
	update ui moniker
	disable ui
	update cities
	update location
	update blinker


	USER CITY
	update ui moniker
	enable ui
	update cities
	update location
	update blinker


	GET USER CITY X,Y
	entry user city mode
	tear down dialog
	popup user city location
	move blinker to user city if user city <> 0 else to dest city


REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	4/12/93		Initial version

----------------------------------------------------------------------------@
OptionsInteractionApply	method dynamic OptionsInteractionClass, MSG_GEN_APPLY
	.enter


	mov	di, offset OptionsInteractionClass
	call	ObjCallSuperNoLock

	call	OptionsInteractionApplyRoutine


	.leave
	ret
OptionsInteractionApply	endm


OptionsInteractionApplyRoutine	proc near
	.enter


	mov	dx, es				; buffer segment
	mov	bp, offset userCityName		; buffer offset
	ObjCall	MSG_VIS_TEXT_GET_ALL_PTR, UserCityText

	; we want to disable the user city option if the city doesn't have
	; a name or a location
	tst	es:[userCityName]
	jz	noUserCity

	tst	es:[tempUserCityX]
	jnz	userCity

	tst	es:[tempUserCityY]
	jnz	userCity


; This is the condition where there is a user city name but no valid x, y
; coordinates.  It has been decided to go and ask the user for them.  

	mov	es:[userCityMode], 2

	call	InitiateSetLocationDialogAndBlinker

	jmp	done



noUserCity:
	call	WorldClockClearAllUserCities	; no user cities


	; There isn't a name for the user city so we fill in the ui option
	; with default text.
	GetResourceHandleNS	userCityDefaultText, bx
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	ds, ax
	mov	si, offset userCityDefaultText
	mov	si, ds:[si]			; dereference handle
	push	bx				; save handle
	call	SetUserCityText
	pop	bx				; restore handle
	call	MemUnlock

	mov	ax, MSG_GEN_SET_NOT_ENABLED
	jmp	commonUpdates



userCity:

	; Fill the ui option for a user city with the name in the options text.
	segmov	ds, es
	mov	si, offset userCityName
	call	SetUserCityText

	mov	ax, MSG_GEN_SET_ENABLED


commonUpdates:

	; This is passed either MSG_GEN_SET_NOT_ENABLED	or MSG_GEN_SET_ENABLED.
	mov	dl, VUM_NOW
	GetResourceHandleNS	UserCity, bx
	mov	si, offset UserCity
	clr	di
	call	ObjMessage


	call	SetUserCityName			; call before SetUserCityX
						; because it commits the ini
						; file while this doesn't

	; copy tempUserCity back into userCity.  userCity values were copied
	; into temp during the OptionBox's initialization.
	mov	cx, es:[tempUserCityX]
	call	SetUserCityX
	mov	cx, es:[tempUserCityY]
	call	SetUserCityY


	call	WorldClockUpdateUserCities


done:

	.leave
	ret
OptionsInteractionApplyRoutine	endp

COMMENT @-------------------------------------------------------------------

FUNCTION:	SetUserCityText

DESCRIPTION:	Set's the User City Text ui to the name passed with 'Use ' 
		prepended.

CALLED BY:	OptionsInteractionApplyRoutine

PASS:		ds:si	- city name to use
		es	- dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	copy the "Use " text
	append the city name
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/ 4/93		Initial version

----------------------------------------------------------------------------@

SetUserCityText	proc	far

	uses	es

; allocate buffer, + 1 to subtract even amount
string	local	(USER_CITY_NAME_LENGTH_MAX + 1 + 8 + 1) dup (TCHAR)

	.enter

	; point to the user city use text with ds:si
	push	ds, si				; save city name segment:offset
	GetResourceHandleNS	userCityUseText, bx; same resource as above 
	call	MemLock
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	mov	ds, ax
	mov	si, offset userCityUseText
	mov	si, ds:[si]			; dereference handle

	; copy the user city text into the string buffer
	segmov	es, ss				; string segment
	lea	di, string			; string offset
	LocalCopyString
	call	MemUnlock
	pop	ds, si			; restore city name segment:offset

	; append the city name
	dec	di				; back one character
DBCS <	dec	di				; ... double null	>
	LocalCopyString

	; Update the "Use User City" text to refer to the latest user city name
	push	bp				; save variable frame
	mov	cx, ss				; string segment
	lea	dx, string			; string offset
	mov	bp, VUM_NOW
	ObjCall	MSG_GEN_REPLACE_VIS_MONIKER_TEXT, UserCity	
						; ax, cx, dx destroyed
	pop	bp				; restore variable frame


	.leave
	ret
SetUserCityText	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_VIS_CLOSE for OptionsInteractionClass

DESCRIPTION:	Apply the user city info and then call the super class for rest
		This handles taps on both the Ok AND the Cancel buttons.

PASS:		es - dgroup

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
	After applying the information in the interaction and letting it
	tear itself down, enable the blinking.  The blinking will
	visually start on the next timer tick to reach 60 ticks.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	5/24/93		Initial version

----------------------------------------------------------------------------@

OptionsInteractionClose	method dynamic OptionsInteractionClass, \
	MSG_VIS_CLOSE

	.enter


	mov	di, offset OptionsInteractionClass
	call	ObjCallSuperNoLock


	; We do not show the destination city if we are going to 
	; ask the user to select their city's location because
	; the routines which initialize that interaction also
	; set the blinker.
	tst	es:[userCityMode]
	jnz	done

	call	BlinkerShowDestCity

done:
	.leave
	ret
OptionsInteractionClose	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_SPEC_BUILD for GenFastInteractionClass

DESCRIPTION:	Sub-class the MSG_SPEC_BUILD of the 
		superclass to add geometry optimization attributes. 

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	art	3/18/93		Initial version

----------------------------------------------------------------------------@
GenFastInteractionSpecBuild	method GenFastInteractionClass, MSG_SPEC_BUILD
	.enter

	mov	di, offset GenFastInteractionClass
	call	ObjCallSuperNoLock		; call it's super class


        call    VisCheckIfVisGrown
        jnc     done            	        ; exit, if not visually built yet

	mov	di, ds:[si]
	add	di, ds:[di].Vis_offset
	ornf	ds:[di].VCI_geoAttrs, mask VCGA_ONE_PASS_OPTIMIZATION

done:
	.leave
	ret
GenFastInteractionSpecBuild	endm

COMMENT @------------------------------------------------------------------

METHOD:		MSG_VIS_RECALC_SIZE for SpecialSizePrimaryClass

DESCRIPTION:	Set the primary to a specific size

PASS:		cx, dx	- suggested width, height

RETURN:		cx, dx	- width, height

DESTROYED:	ax, bp

PSEUDO CODE/STRATEGY:
	This is the first place where there is evidence which computing device
is being used.  By examining how ui hints are processed based on the system 
attributes we know if we're operating on the Zoomer or not.  We use this 
information here to customize the ui gadetry as needed per device.  The
customization code should be run *once*.

	The second part of this code attempts to keep the primary's size
within a desired size.  This is necessitated by the fact that 
HINT_MAXIMUM_SIZE and HINT_MINIMUM_SIZE are ignored by GenPrimaries.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	8/9/93		Initial version

----------------------------------------------------------------------------@
SSPVisRecalcSize	method dynamic SpecialSizePrimaryClass, MSG_VIS_RECALC_SIZE

	cmp	es:[formfactor], mask CD_UNKNOWN
	jne	formfactorHandled

	mov	ax, HINT_DISPLAY_NOT_RESIZABLE
	call	ObjVarFindData
	jc	otherDevice
	mov	es:[formfactor], mask CD_ZOOMER

	; There is nothing special to do for the Zoomer, so just call
	; the super class.
	jmp	sizeOk

otherDevice:
	mov	es:[formfactor], mask CD_OTHER


	; Configuring stuff to do for non zoomer versions
	; Currently, only a Zoomer needs the TitleGlyph, so disable it.
	cmp	es:[haveTitleBar], TRUE
	je	fixHeight
	push	cx, dx, si, ds, es			; dx set later
	mov	dl, VUM_DELAYED_VIA_UI_QUEUE
	ObjCall	MSG_GEN_SET_NOT_USABLE, TitleGlyph

	pop	cx, dx, si, ds, es

	mov	ax, MSG_VIS_RECALC_SIZE
	mov	es:[haveTitleBar], TRUE


formfactorHandled:

	; At this point the ui gadetry is set usable/not usable for 
	; this type of device.  The primary's size still may need
	; adjusting to keep it small.


	; keep the width less than a maximum
	cmp	cx, IDEAL_PRIMARY_MAXIMUM_WIDTH
	jle	widthOk

fixWidth::
	mov	cx, IDEAL_PRIMARY_MAXIMUM_WIDTH		; not actually followed

widthOk:

	; keep the height less than a maximum
	cmp	dx, IDEAL_PRIMARY_MAXIMUM_HEIGHT
	jle	heightOk

fixHeight:
	mov	dx, IDEAL_PRIMARY_MAXIMUM_HEIGHT

heightOk::


sizeOk:
	mov	ax, MSG_VIS_RECALC_SIZE
	mov	di, offset SpecialSizePrimaryClass
	call	ObjCallSuperNoLock		; call it's super class


	ret
SSPVisRecalcSize	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_GEN_DISPLAY_SET_MINIMIZED for SpecialSizePrimaryClass

DESCRIPTION:	Disable drawing to the ui when minimized.  This is 
		motivated by the blinker which attempts to draw to a
		non-existant window when the app is minimized.

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	8/25/93		Initial version

----------------------------------------------------------------------------@
SSPSetMinimized method dynamic SpecialSizePrimaryClass, MSG_GEN_DISPLAY_SET_MINIMIZED
	.enter

	mov	es:[uiMinimized], TRUE
;	mov	es:[uiSetupSoUpdatingUIIsOk], FALSE
	clr	es:[winHandle]


	mov	di, offset SpecialSizePrimaryClass
	call	ObjCallSuperNoLock		; call it's super class

	.leave
	ret
SSPSetMinimized	endm



COMMENT @------------------------------------------------------------------

METHOD:		MSG_GEN_DISPLAY_SET_NOT_MINIMIZED for SpecialSizePrimaryClass

DESCRIPTION:	Disable drawing to the ui when minimized.  This is 
		motivated by the blinker which attempts to draw to a
		non-existant window when the app is minimized.

PASS:		nothing

RETURN:		nothing

DESTROYED:	ax, cx, dx, bp

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	8/25/93		Initial version

----------------------------------------------------------------------------@
SSPSetNotMinimized method dynamic SpecialSizePrimaryClass, MSG_GEN_DISPLAY_SET_NOT_MINIMIZED
	.enter


	mov	di, offset SpecialSizePrimaryClass
	call	ObjCallSuperNoLock		; call it's super class


	ObjCall	MSG_GEN_VIEW_GET_WINDOW, WorldView
	mov	es:[winHandle], cx		; if the result is null it's ok

	mov	es:[uiMinimized], FALSE
;	mov	es:[uiSetup[SoUpdatingUIIsOk], TRUE
	call	WorldClockUpdateTimeDates

	.leave
	ret
SSPSetNotMinimized	endm

COMMENT @------------------------------------------------------------------

METHOD:		MSG_VIS_RECALC_SIZE for GenNotSmallerThanWorldMapInteractionClass

DESCRIPTION:	Insure the gen interaction is NEVER narrower than the world map.

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	11/12/93	Initial version

----------------------------------------------------------------------------@
GenNotSmallerThanWorldMapResize	method dynamic GenNotSmallerThanWorldMapInteractionClass, MSG_VIS_RECALC_SIZE

	.enter

	cmp	cx, WORLD_MAP_WIDTH
	jge	widthOk


	; A small width has been asked for.  From this point on never allow
	; a width bigger than the world map's width.  This is because the
	; text object in the other child interaction will ask for a wider
	; width and expand the primary.
	mov	cx, WORLD_MAP_WIDTH

;	mov	ax, HINT_FIXED_SIZE
;	call	ObjVarFindData
;EC <	ERROR_NC	WC_ERROR_ROUTINE_CALLED_FAILED			>

;	mov	ds:[bx], cx			; width in pixels
					; speed for SST_PIXELS << 10 | cx
						; since SST_PIXELS = 0


widthOk:
	mov	di, offset GenNotSmallerThanWorldMapInteractionClass
	call	ObjCallSuperNoLock		; call it's super class


	.leave
	ret
GenNotSmallerThanWorldMapResize	endm




CommonCode	ends









