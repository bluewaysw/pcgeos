COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (C) Palm Computing, Inc. 1993 -- All Rights Reserved

PROJECT:	PEN GEOS
MODULE:		World Clock
FILE:		wcInitFile.asm

AUTHOR:		Roger Flores, Oct 21, 1993

ROUTINES:
	Name			Description
	----			-----------
	
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial revision
	pam	10/15/96	added Penelope specific changes

DESCRIPTION:
	Contains code to handle reading and updating the init file.
		
	$Id: wcInitFile.asm,v 1.1 97/04/04 16:21:52 newdeal Exp $


This lists and describes the World Clock's usage of the init file.
All keys are located in the category [World Clock].  The contents
of the init file are read only if there is not a state file.  The
contents of the init file are written as the information is 
changed.

[worldClock]


homeCity = -1
; The number of the city selected for the home city.
; -1 = default


destCity = -1
; The number of the city selected for the home city.
; -1 = default


selectedTimeZone = 700
; The time zone selected.  When converted from decimal to hexadecimal,
; the high byte is the minutes and the low byte is the hours.
; type = sword
; default = 0

if _PENELOPE

systemTimeZoneOffset = 0
; The offset from the dateline of the system time zone set by the user.
; type = sword
; default = 4

homeCitySortOption = 0
destCitySortOption = 0
; The Sort options for the home and dest cities determines the correct
; city list index to use.
; type = CitySelection 
; default = mask CITY_SELECTION	(city sorted list)

endif

citySummerTime = 0
; This records which cities are on summer time.
; type = CityPlaces
; default = NO_CITY

homeIsSystemClock = true
; Whether the system time is the time at home or at the destination.

userCities = 0
; Which cities are user defined cities.
; type = CityPlaces
; default = NO_CITY

userCityTimeZone = 0
; The time zone where the user defined city is located. When converted 
; from decimal to hexadecimal, the high byte is the minutes and the low 
; byte is the hours.
; type = sword.
; default = 0.

userCityX = 0
; The x position where the user defined city is located.
; type = word.
; default = 0

userCityY = 0
; The y position where the user defined city is located.
; type = word
; default = 0

userCityName = 0
; The name of the user defined city.
; type = char string.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@


include initfile.def


InitFileCode	segment	resource


; all strings used by the world clock in the init file:
IniCategory		char	"worldClock", 0
IniHomeCity 		char	"homeCity", 0
IniDestCity 		char	"destCity", 0
IniSelectedTimeZone 	char	"selectedTimeZone", 0
IniCitySummerTime 	char	"citySummerTime", 0
IniHomeIsSystemClock	char	"homeIsSystemClock", 0
IniUserCities 		char	"userCities", 0

IniUserCityTimeZone 	char	"userCityTimeZone", 0
IniUserCityX 		char	"userCityX", 0
IniUserCityY 		char	"userCityY", 0
IniUserCityName 	char	"userCityName", 0


COMMENT @-------------------------------------------------------------------

FUNCTION:	WCInitFileReadInteger

DESCRIPTION:	Read an init file integer.
		Saves bytes.

CALLED BY:	This is called by many routines.  

PASS:		cs:dx - key string

RETURN:		ax - integer

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

WCInitFileReadInteger	proc	far
	uses	ds, si, cx
	.enter

EC <	push	ax							>
EC <	mov	ax, es				; check dgroup		>
EC <	call	ECCheckSegment						>
EC <	pop	ax							>


	; now write the value to the ini file.
	segmov	ds, cs, cx			; cx & ds <- cs
	mov	si, offset IniCategory
	call	InitFileReadInteger


	.leave
	ret
WCInitFileReadInteger	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WCInitFileWriteInteger

DESCRIPTION:	Write an init file integer.
		Saves bytes.

CALLED BY:	Many routines

PASS:		cs:dx	- ini key string
		cx	- integer

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93		Initial version

----------------------------------------------------------------------------@

WCInitFileWriteInteger	proc	far
	uses	ds, si, cx, bp
	.enter

EC <	push	ax							>
EC <	mov	ax, es				; check dgroup		>
EC <	call	ECCheckSegment						>
EC <	pop	ax							>


	; now write the value to the ini file.
	mov	bp, cx				; integer
	segmov	ds, cs, cx			; cx & ds <- cs
	mov	si, offset IniCategory
	call	InitFileWriteInteger
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	call	InitFileCommit


	.leave
	ret
WCInitFileWriteInteger	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetHomeCity

DESCRIPTION:	Set the home city variable and ini file key.

CALLED BY:	

PASS:		es - dgroup
		cx - home city ptr

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Set the dgroup variable from the ini file.
	Update the ini file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

SetHomeCity	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[homeCityPtr], cx

	mov	dx, offset IniHomeCity
	call	WCInitFileWriteInteger			; write cx

	.leave
	ret
SetHomeCity	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetHomeCity

DESCRIPTION:	Get the home city from the ini file.

CALLED BY:	

PASS:		es - dgroup

RETURN:		dx - home city ptr
		dgroup:[homeCityPtr]

DESTROYED:	ds, si, ax, bx, dx

PSEUDO CODE/STRATEGY:
	Get the dgroup variable from the ini file.
	Use it if valid.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

GetHomeCity	proc	far
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniHomeCity		; in this code segment
	call	WCInitFileReadInteger		; ax <- integer
	jc	ignoreBecauseError
	mov	dx, ax				; dx <- integer


	; lock the block to pass to ChunkArrayGetCount
	mov	bx, es:[cityIndexHandle]
	call	MemLock
	mov	ds, ax

	; the city selection list
	; get the number of cities in the list so we can tell the list object
	mov	si, es:[cityNamesIndexHandle]
	call	ChunkArrayGetCount		; count in cx


	; we no longer need the city index block
	mov	bx, es:[cityIndexHandle]
	call	MemUnlock


	cmp	dx, cx				; is it valid city?
	jge	ignoreBecauseError

	mov	es:[homeCityPtr], dx


ignoreBecauseError:

	.leave
	ret
GetHomeCity	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	SetDestCity

DESCRIPTION:	Set the dest city variable and ini file key.

CALLED BY:	

PASS:		es - dgroup
		cx - dest city ptr

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Set the dgroup variable
	Update the ini file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

SetDestCity	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[destCityPtr], cx

	mov	dx, offset IniDestCity
	call	WCInitFileWriteInteger			; write cx


	.leave
	ret
SetDestCity	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetDestCity

DESCRIPTION:	Get the dest city from the ini file.

CALLED BY:	

PASS:		es - dgroup

RETURN:		dx - dest city ptr
		dgroup:[destCityPtr]

DESTROYED:	ds, si, ax, bx, dx

PSEUDO CODE/STRATEGY:
	Get the dgroup variable from the ini file.
	Use it if valid.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

GetDestCity	proc	far
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniDestCity		; in this code segment
	call	WCInitFileReadInteger		; ax <- integer
	jc	ignoreBecauseError
	mov	dx, ax				; dx <- integer


	; lock the block to pass to ChunkArrayGetCount
	mov	bx, es:[cityIndexHandle]
	call	MemLock
	mov	ds, ax

	; the city selection list
	; get the number of cities in the list so we can tell the list object
	mov	si, es:[cityNamesIndexHandle]
	call	ChunkArrayGetCount		; count in cx


	; we no longer need the city index block
	mov	bx, es:[cityIndexHandle]
	call	MemUnlock


	cmp	dx, cx				; is it valid city?
	jge	ignoreBecauseError

	mov	es:[destCityPtr], dx


ignoreBecauseError:

	.leave
	ret
GetDestCity	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetSelectedTimeZone

DESCRIPTION:	Set the selected time zone variable and ini file key.

CALLED BY:	

PASS:		es - dgroup
		cx - selected time zone (ch - hours, cl - minutes)

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Set the dgroup variable
	Update the ini file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

SetSelectedTimeZone	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[selectedTimeZone], cx

	mov	dx, offset IniSelectedTimeZone
	call	WCInitFileWriteInteger			; write cx

	.leave
	ret
SetSelectedTimeZone	endp

COMMENT @-------------------------------------------------------------------

FUNCTION:	GetSelectedTimeZone

DESCRIPTION:	Get the selected time zone from the ini file.

CALLED BY:	

PASS:		es - dgroup

RETURN:		ax - user city time zone (ch - hours, cl - minutes)

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Get the dgroup variable from the ini file.
	Use it if valid.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

GetSelectedTimeZone	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniSelectedTimeZone		; in this code segment
	call	WCInitFileReadInteger			; ax <- integer
	jc	ignoreBecauseError


	cmp	al, MAX_TIME_ZONE
	jg	ignoreBecauseError

	cmp	ah, MINUTES_PER_HOUR
	jge	ignoreBecauseError

	mov	es:[selectedTimeZone], ax


ignoreBecauseError:

	.leave
	ret
GetSelectedTimeZone	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetCitySummerTime

DESCRIPTION:	Record which cities are on summer time.

CALLED BY:	WorldClockSetSummerTime

PASS:		es - dgroup
		cl - cities on summer time (CityPlaces)

RETURN:		nothing

DESTROYED:	ch

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

SetCitySummerTime	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[citySummerTime], cl
	; now write the value to the ini file.
	clr	ch
	mov	dx, offset IniCitySummerTime
	call	WCInitFileWriteInteger		; write cx


	.leave
	ret
SetCitySummerTime	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetCitySummerTime

DESCRIPTION:	Read which cities are on summer time.

CALLED BY:	

PASS:		es - dgroup

RETURN:		al - cities on summer time (CityPlaces)

DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

GetCitySummerTime	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniCitySummerTime
	call	WCInitFileReadInteger		; ax <- integer
	jc	ignoreBecauseError


	test	al, not CityPlaces
	jnz	ignoreBecauseError

	mov	es:[citySummerTime], al


ignoreBecauseError:

	.leave
	ret
GetCitySummerTime	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetUserCities

DESCRIPTION:	Record in the ini file which cities are user defined cities.

CALLED BY:	

PASS:		es - dgroup
		dgroup:userCities	- user defined cities (CityPlaces)

RETURN:		nothing

DESTROYED:	ch

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

SetUserCities	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	cl, es:[userCities]

	; now write the value to the ini file.
	clr	ch
	mov	dx, offset IniUserCities
	call	WCInitFileWriteInteger		; write cx


	.leave
	ret
SetUserCities	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetUserCities

DESCRIPTION:	Read which cities are user defined cities.

CALLED BY:	

PASS:		es - dgroup

RETURN:		al - user defined cities (CityPlaces)

DESTROYED:	ah

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

GetUserCities	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniUserCities		; in this code segment
	call	WCInitFileReadInteger			; ax <- integer
	jc	ignoreBecauseError


	test	al, not CityPlaces or mask USER_CITY
	jnz	ignoreBecauseError

	mov	es:[userCities], al


ignoreBecauseError:

	.leave
	ret
GetUserCities	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetHomeIsSystemClock

DESCRIPTION:	Record in the ini file if the system time is the
		home city's time.

CALLED BY:	

PASS:		es - dgroup
		al - system clock city (CityPlaces)

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

SetHomeIsSystemClock	proc	far
	uses	ds, si, cx, dx, ax
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[systemClockCity], al	; record the city ourself

	; are we using home city time? zero if false
	and	ax, mask HOME_CITY

	segmov	ds, cs, cx			; cx & ds <- cs
	mov	si, offset IniCategory
	mov	dx, offset IniHomeIsSystemClock
	call	InitFileWriteBoolean
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>
	call	InitFileCommit


	.leave
	ret
SetHomeIsSystemClock	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetHomeIsSystemClock

DESCRIPTION:	Read if the system time is the home city's time.

CALLED BY:	

PASS:		es - dgroup

RETURN:		es:[systemClockCity]

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/21/93	Initial version

----------------------------------------------------------------------------@

GetHomeIsSystemClock	proc	far
	uses	ds, si, cx, dx, ax
	.enter

EC <	call	ECCheckDGroupES					>

	segmov	ds, cs, cx			; cx & ds <- cs
	mov	si, offset IniCategory
	mov	dx, offset IniHomeIsSystemClock
	call	InitFileReadBoolean
	jc	done				; don't use if not valid!


	; set systemClockCity from the ini key
	cmp	ax, FALSE
	je	systemClockAtDestCity
	mov	es:[systemClockCity], mask HOME_CITY
	jmp	done

systemClockAtDestCity:
	mov	es:[systemClockCity], mask DEST_CITY


done:
	.leave
	ret
GetHomeIsSystemClock	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetUserCityTimeZone

DESCRIPTION:	Set the user city time zone variable and ini file key.

CALLED BY:	

PASS:		es - dgroup
		cx - user city time zone (ch - hours, cl - minutes)

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Set the dgroup variable
	Update the ini file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

SetUserCityTimeZone	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[userCityTimeZone], cx

	mov	dx, offset IniUserCityTimeZone
	call	WCInitFileWriteInteger			; write cx

	.leave
	ret
SetUserCityTimeZone	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetUserCityTimeZone

DESCRIPTION:	Get the user city time zone from the ini file.

CALLED BY:	

PASS:		es - dgroup

RETURN:		ax - user city time zone (ch - hours, cl - minutes)

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Get the dgroup variable from the ini file.
	Use it if valid.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

GetUserCityTimeZone	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniUserCityTimeZone		; in this code segment
	call	WCInitFileReadInteger			; ax <- integer
	jc	ignoreBecauseError

	cmp	al, MAX_TIME_ZONE
	jg	ignoreBecauseError

	cmp	ah, MINUTES_PER_HOUR
	jge	ignoreBecauseError

	mov	es:[userCityTimeZone], ax


ignoreBecauseError:

	.leave
	ret
GetUserCityTimeZone	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetUserCityX

DESCRIPTION:	Set the user city x variable and ini file key.

CALLED BY:	

PASS:		es - dgroup
		cx - user city x

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Set the dgroup variable
	Update the ini file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

SetUserCityX	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[userCityX], cx

	mov	dx, offset IniUserCityX
	call	WCInitFileWriteInteger			; write cx

	.leave
	ret
SetUserCityX	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetUserCityX

DESCRIPTION:	Get the user city x from the ini file.

CALLED BY:	

PASS:		es - dgroup

RETURN:		ax - user city x

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Get the dgroup variable

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

GetUserCityX	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniUserCityX		; in this code segment
	call	WCInitFileReadInteger			; ax <- integer
	jc	ignoreBecauseError


	cmp	ax, WORLD_MAP_WIDTH
	jg	ignoreBecauseError

	mov	es:[userCityX], ax


ignoreBecauseError:

	.leave
	ret
GetUserCityX	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetUserCityY

DESCRIPTION:	Set the user city y variable and ini file key.

CALLED BY:	

PASS:		es - dgroup
		cx - user city y

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Set the dgroup variable from the ini file.
	Update the ini file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

SetUserCityY	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	mov	es:[userCityY], cx

	mov	dx, offset IniUserCityY
	call	WCInitFileWriteInteger			; write cx

	.leave
	ret
SetUserCityY	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetUserCityY

DESCRIPTION:	Get the user city Y from the ini file.

CALLED BY:	

PASS:		es - dgroup

RETURN:		ax - user city Y

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Get the dgroup variable

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

GetUserCityY	proc	far
	uses	dx
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	mov	dx, offset IniUserCityY		; in this code segment
	call	WCInitFileReadInteger			; ax <- integer
	jc	ignoreBecauseError


	cmp	ax, WORLD_MAP_HEIGHT
	jg	ignoreBecauseError

	mov	es:[userCityY], ax


ignoreBecauseError:

	.leave
	ret
GetUserCityY	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	SetUserCityName

DESCRIPTION:	Set the user city name variable and ini file key.

CALLED BY:	

PASS:		es:[userCityName] - user city name

RETURN:		nothing

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Set the dgroup variable from the ini file.
	Update the ini file.
	does not save the changes to the ini file.
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

SetUserCityName	proc	far
	uses	ds, si, di, cx, dx
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	segmov	ds, cs, cx			; cx & ds <- cs
	mov	si, offset IniCategory
	mov	dx, offset IniUserCityName
	mov	di, offset userCityName		; es:di <- user city name
	call	InitFileWriteString
EC <	ERROR_C	WC_ERROR_ROUTINE_CALLED_FAILED				>


	.leave
	ret
SetUserCityName	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	GetUserCityName

DESCRIPTION:	Get the user city name from the ini file.

CALLED BY:	

PASS:		es - dgroup

RETURN:		cx - number of bytes retrieved (excluding null terminator)
			cx = 0 if category / key not found
		es:di - user city name from ini file

DESTROYED:	none

PSEUDO CODE/STRATEGY:
	Get the dgroup variable.

		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/22/93	Initial version

----------------------------------------------------------------------------@

GetUserCityName	proc	far
	uses	ds, si, di, dx, bp
	.enter

EC <	call	ECCheckDGroupES					>

	; now write the value to the ini file.
	segmov	ds, cs, cx			; cx & ds <- cs
	mov	si, offset IniCategory
	mov	dx, offset IniUserCityName		; in this code segment
	mov	di, offset userCityName			; es:di <- user city name
	mov	bp, (USER_CITY_NAME_LENGTH_MAX + 1) shl offset IFRF_SIZE
	call	InitFileReadString


	.leave
	ret
GetUserCityName	endp


InitFileCode	ends









