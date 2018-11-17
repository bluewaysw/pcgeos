COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	Copyright (c) Palm Computing, Inc. 1992 -- All Rights Reserved

PROJECT:	PEN GEOS
MODULE:		World Clock
FILE:		wcMain.asm

AUTHOR:		Roger Flores, Oct 15, 1992

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/15/92	Initial revision
	pam	10/16/96	Added Penelope specific changes.
DESCRIPTION:


ROUTINES:
	MSG_META_EXPOSED (WorldClockViewExposed)
	MSG_NOTIFY_DATE_TIME_CHANGE (WorldClockNotifyTimeDateChange)
	DisplayUserMessage

if not _PENELOPE
	WorldClockMarkAppNotBusy
	WorldClockMarkAppBusy
endif

	$Id: wcMain.asm,v 1.1 97/04/04 16:21:58 newdeal Exp $

	$Id: wcMain.asm,v 1.1 97/04/04 16:21:58 newdeal Exp $

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

;------------------------------------------------------------------------------
;			Common GEODE stuff
;------------------------------------------------------------------------------

include wcGeode.def

include wcApplication.def


idata	segment

	WorldClockApplicationClass			;declare the class
	CustomApplyInteractionClass
	GenFastInteractionClass
	GenNotSmallerThanWorldMapInteractionClass
	OptionsInteractionClass
	SpecialSizePrimaryClass


idata	ends

include wc.rdef

;------------------------------------------------------------------------------
;			Class definition
;------------------------------------------------------------------------------

idata	segment

	WorldClockProcessClass	mask CLASSF_NEVER_SAVED

;; method PROC_NAME,		CLASS_NAME,    MSG_NAME


;------------------------------------------------------------------------------
;			GeoCalcProcessInstance
;------------------------------------------------------------------------------
;procVars	WorldClockProcessInstance <,		; Meta instance
;>

RestoreStateBegin	label	byte
	changeCity		CityPlaces	mask HOME_CITY

	homeCityPtr		word	CITY_NOT_SELECTED
	homeCityTimeZone	sword	0
	homeCityX		word	0
	homeCityY		word	0

	destCityPtr		word	CITY_NOT_SELECTED
	destCityTimeZone	sword	0
	destCityX		word	0
	destCityY		word	0

	selectedTimeZone	sword	0

	citySummerTime		CityPlaces	NO_CITY
	systemClockCity		CityPlaces	mask HOME_CITY

	;Whether the city being selected is from the listbox or is a
	;user city.  In Penelope, also used to determine whether the
	;city listbox is sorted by city or by country.
	citySelection		CitySelection	0	
	userCities		CityPlaces	NO_CITY	;cities using user city
	userCityTimeZone	sword	0
	userCityX		word	0
	userCityY		word	0
	userCityName	     TCHAR  (USER_CITY_NAME_LENGTH_MAX + 1 + 8) dup (0)

	userCityMode		byte	FALSE	;picking city location from map

	; The following are not determinable if the app starts up minimized
	; since the deciding code is in the ui and decides from information
	; in the non-minimized ui.  We use the last known accurate values.
	haveTitleBar		byte	FALSE;is the primary's title displayed?
	formfactor		ComputingDevice	mask CD_UNKNOWN
	uiMinimized		byte	FALSE	; not minimized on startup

	;
	; The user may select a place for the user city and then cancel
	; the action.  These variables hold the user city's location until
	; the user applies the choice.
	;
	tempUserCityX		word
	tempUserCityY		word

	userSelectedCity	word		; city last selected by user
						; from the selection lists

RestoreStateEnd		label	byte

	currentCountry		word	GIGS_NONE
	timerHandle		hptr	0
	destCityBlinkDrawn	byte	FALSE
	destCityCanBlink	byte	TRUE
	blinkerX		word	0
	blinkerY		word	0

	uiSetupSoUpdatingUIIsOk	byte	FALSE	; used to avoid using invalid 
						; handles during setup.  Waits
						; until ok.  Also used to
						; supress ui updating during
						; shutdown because handles
						; become invalid unorderly.

	blinkerCountOfBlinksLeftToDisplayBlinkerBecauseItJustMoved byte	0
				;used when moving the blinker
				;guarantees blinker visible for at
				;least one entire blink. This makes
				;blinker visible on moves. See
				;BlinkerMove in wcUI.asm. 

	dataFileLoaded		byte	FALSE
	LocalDefNLString		dataFilePath <"WCLOCK", 0>
	LocalDefNLString		dataFileName <"WORLD.WCM", 0>


idata	ends



;------------------------------------------------------------------------------
;			Unitialized data
;------------------------------------------------------------------------------
udata	segment
	winHandle	hptr.Window

	; variables for the city information
	cityInfoHandle		hptr		; global block handle
	cityInfoSize		word		; City Info size
	cityIndexHandle		hptr		; global block handle
	cityNamesIndexHandle	hptr	       ;chunk handle in cityIndexHandle
	countryCityNamesIndexHandle	hptr   ;chunk handle in cityIndexHandle
	countryNamesIndexHandle	hptr	       ;chunk handle in cityIndexHandle
	firstCityInCountry	word	        ; both for converting between
	cityInCountryCount	word	        ; the city and
					        ; country/city lists

	timeZoneInfoHandle	hptr		; heap handle to block
	worldMapBitmapHandle	hptr		; heap handle to block


	daylightStart		word		;last calculated start position

	minuteCountdown		word	       ;remaining timer ticks in minute

	; the user may select a place for their user city and then cancel
	; the action.  These variables hold the user city's location until
	; the user applys their choice.
;	tempUserCityX		word
;	tempUserCityY		word

;	userSelectedCity	word		; city last selected by user
						; from the selection lists

	; these values are read in from the data file.  
	; THE ORDER OF THESE MATCHES THEIR ORDER IN THE DATA FILE!
DataFileVariablesBegin	label	byte
	versionWCM		word		; data file version number
	datelinePosition	sword		; position of the
						; dateline in pixels
	worldWidth		word		; width of world; may be larger
						; than the map
	timeZoneCount		word
	defaultHomeCity		word		; city to use at startup
	defaultDestinationCity	word		; city to use at startup
	defaultTimeZone		word		; time zone of the default home city
DataFileVariablesEnd	label	byte

	;
	;This variable is not used in any version so it causes a
	;compiler warning. It's needed because of the data file format.
	;
	ForceRef	datelinePosition

udata	ends


;------------------------------------------------------------------------------
;			Code Resources
;------------------------------------------------------------------------------

include wcInitFile.asm
include	wcInit.asm
include wcUI.asm
include wcLists.asm

;if _PENELOPE
include wcUser.asm
include wcAlarm.asm
;endif


CommonCode segment resource




COMMENT @----------------------------------------------------------------------

FUNCTION:	WorldClockExposedView -- MSG_META_EXPOSED for WorldClockProcessClass

DESCRIPTION:	Draw the world map bitmap in the genView

PASS:
	ds - core block of geode
	es - core block

	di - MSG_EXPOSED

	cx - window
	dx - ?
	bp - ?
	si - ?

REGISTER/STACK USAGE:

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/CAVEATS/IDEAS:

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/15		Initial version

------------------------------------------------------------------------------@

WorldClockViewExposed	method	WorldClockProcessClass, MSG_META_EXPOSED

FXIP <	GetResourceSegmentNS	dgroup, es			>

EC <	call	ECCheckDGroupES					>
EC <	call	ECCheckDGroupDS


	; don't draw the bitmap if there isn't one!  Prevents a handle error.
	cmp	es:[dataFileLoaded], TRUE
LONG	jne	done


	mov	di, cx			;set ^hdi = window handle

	call	GrCreateState 			;returns gstate in di

	;Updating the window...

	call	GrBeginUpdate

	call	WorldClockUpdateDaylightBar

	; Draw the world map bitmap in the view
	mov	bx, es:[worldMapBitmapHandle]
	call	MemLock

	mov	ds, ax				;world map resource segment
	clr	ax, dx, si			;bitmap at offset 0
	mov	bx, DAYLIGHT_AREA_HEIGHT	;bitmap at 0, DAYLIGHT_AREA_HEIGHT
	call	GrDrawBitmap
		
	mov	bx, es:[worldMapBitmapHandle]
	call	MemUnlock			; have drawn the bitmap


	; now it's time to draw a time zone if one's selected
	; we prefer a look of partially inversion as opposed to 100%
	cmp	es:[selectedTimeZone], NO_TIME_ZONE
	je	selectedTimeZoneUpdated

	mov	al, SDM_12_5
	call	GrSetAreaMask

	; invert the time zones
	mov	al, MM_INVERT
	call	GrSetMixMode

	; lock the time zone block
	mov	bx, es:[timeZoneInfoHandle]
	call	MemLock
	mov	ds, ax

	mov	ax, es:[selectedTimeZone]
	call	WorldMapDrawTimeZone

	call	MemUnlock


selectedTimeZoneUpdated:

	call	GrEndUpdate			;done updating...

	call	GrDestroyState 			;destroy our gstate

	; There is a problem with the blinker when restoring from minimized
	; state.  uiMinimized is turned false.  The blinker blinks and thinks
	; it's drawn, This view exosed event is handled erasing the blinker.
	; The blinker blinks, leaving an image, but turning off.  To fix
	; we indicate the blinker is no longer drawn.
	mov	es:[destCityBlinkDrawn], FALSE

done:
	ret
WorldClockViewExposed	endm


COMMENT @------------------------------------------------------------------

METHOD:		MSG_NOTIFY_DATE_TIME_CHANGE for WorldClockProcessClass

DESCRIPTION:	

PASS:		nothing

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	10/23/92	Initial version

----------------------------------------------------------------------------@
WorldClockNotifyTimeDateChange	method WorldClockProcessClass, MSG_NOTIFY_DATE_TIME_CHANGE
	.enter

	mov	di, offset WorldClockProcessClass
	call	ObjCallSuperNoLock

	call	WorldClockCalibrateClock

	call	WorldClockUpdateTimeDates

	.leave
	ret
WorldClockNotifyTimeDateChange	endm



COMMENT @%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
		DisplayUserMessage
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

SYNOPSIS:	Display the world clock error box!!

CALLED BY:	GLOBAL (MSG_WC_DISPLAY_USER_MESSAGE, 
		MSG_WC_DISPLAY_USER_MESSAGE_OPTR) or directly

PASS:		ES	= DGroup
		BP	= WCErrorValue
		CX:DX	= Possible data for first string argument (fixed or optr)
		BX:SI	= Possible data for second string argument (fixed or optr)

RETURN:		AX	= InteractionCommand from error box

DESTROYED:	BX, DI, SI

PSEUDO CODE/STRATEGY:

KNOWN BUGS/SIDE EFFECTS/IDEAS:
		Must be running in the world clock process thread!!

REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	Don	1/3/90		Initial version
	Don	7/17/90		Added support for string arguments
	rsf	9/19/92		Copied into world clock

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%@

DisplayUserMessage	method	WorldClockProcessClass,	\
	MSG_WC_DISPLAY_USER_MESSAGE, MSG_WC_DISPLAY_USER_MESSAGE_OPTR
	uses	bp, ds
	.enter


	push	ax				; save the msg type

	; Some set-up work
	;
;	test	es:[systemStatus], SF_DISPLAY_ERRORS
;	jz	done				; jump to not display errors
	push	bx, si				; save second string arguments
	GetResourceHandleNS	ErrorBlock, bx
	call	MemLock		; lock the block
	mov	ds, ax				; set up the segment
	mov	si, offset ErrorBlock:ErrorArray ; handle of error messages 
	mov	si, ds:[si]			; dereference the handle
EC <	cmp	bp, WCUserErrorValue					>
EC <	ERROR_GE	WC_ERROR_BAD_DISPLAY_ERROR_VALUE		>

	; Put up the error box (always warning for now)
	;
	add	si, bp				; go to the correct messages
	mov	ax, ds:[si+2]			; custom values => AX
	mov	di, ds:[si]			; text handle => DI

	pop	bx, si				; restore second string args
	pop	bp
	sub	sp, size StandardDialogParams
	push	bp
	mov	bp, sp
	add	bp, size word
	mov	ss:[bp].SDP_customFlags, ax
	mov	ss:[bp].SDP_stringArg1.segment, cx
	mov	ss:[bp].SDP_stringArg1.offset, dx
	mov	ss:[bp].SDP_stringArg2.segment, bx
	mov	ss:[bp].SDP_stringArg2.offset, si
	clr	ax
	mov	ss:[bp].SDP_customTriggers.segment, ax
	mov	ss:[bp].SDP_customTriggers.offset, ax
	mov	ss:[bp].SDP_helpContext.segment, ax	; no help context
	mov	ss:[bp].SDP_helpContext.offset, ax

	;no custom triggers

	GetResourceHandleNS	ErrorBlock, bx

	pop	ax
	cmp	ax, MSG_WC_DISPLAY_USER_MESSAGE_OPTR
	je	argsAreChunks
						; pass params on stack
	mov	ss:[bp].SDP_customString.segment, ds
	mov	di, ds:[di]			; dereference message string
	mov	ss:[bp].SDP_customString.offset, di
	call	UserStandardDialog		; put up the dialog box
	call	MemUnlock			; unlock the block after call
	jmp	dialogGone

argsAreChunks:
	call	MemUnlock			; unlock the block before call
	mov	ss:[bp].SDP_customString.segment, bx
	mov	ss:[bp].SDP_customString.offset, di
	call	UserStandardDialogOptr		; put up the dialog box

dialogGone:

	; Clean up
	;
;done:
	.leave
	ret
DisplayUserMessage	endp


COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockMarkAppNotBusy

DESCRIPTION:	Remove busy cursor after things have finished.

CALLED BY:	

PASS:		

RETURN:		nothing

DESTROYED:	ax, bx, si, di

PSEUDO CODE/STRATEGY:
	This forces the message onto the end of the queue so that
	everything else finishes first.
	
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/16/93		Initial version

----------------------------------------------------------------------------@

WorldClockMarkAppNotBusy	proc	near

	ObjSend	MSG_GEN_APPLICATION_MARK_NOT_BUSY, WorldClockApp, <mask MF_FORCE_QUEUE>

	ret
WorldClockMarkAppNotBusy	endp



COMMENT @-------------------------------------------------------------------

FUNCTION:	WorldClockMarkAppBusy

DESCRIPTION:	Display busy cursor immeadiately

CALLED BY:	

PASS:		

RETURN:		nothing

DESTROYED:	nothing

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/16/93		Initial version

----------------------------------------------------------------------------@

WorldClockMarkAppBusy	proc	near

	ObjCall	MSG_GEN_APPLICATION_MARK_BUSY, WorldClockApp

	ret
WorldClockMarkAppBusy	endp


COMMENT @------------------------------------------------------------------

METHOD:		MSG_GEN_APPLICATION_MARK_BUSY for WorldClockApplicationClass

DESCRIPTION:	Mark the application busy only if the event queue is empty
	This solves problems with the application being marked not busy
	but when lots of work remains in the queue (because of list initializing).

PASS:		nothing

RETURN:		nothing

DESTROYED:	

PSEUDO CODE/STRATEGY:
		
REVISION HISTORY:
	Name	Date		Description
	----	----		-----------
	rsf	6/16/93		Initial version

----------------------------------------------------------------------------@

ifdef foo
;
;	This code commented out because it seems to leave the cursor 
; busy more than it should.	rsf 6/18/93

WorldClockApplicationMarkNotBusy	method dynamic WorldClockApplicationClass, \
	MSG_GEN_APPLICATION_MARK_NOT_BUSY
	.enter

	clr	bx
	call	GeodeInfoQueue
	cmp	ax, 0
	je	callSuperClass

	; The queue isn't empty.  Delay marking not busy by not doing it
	; now and placing it on the end of the queue again.
	call	WorldClockMarkAppNotBusy
	jmp	done

callSuperClass:
	mov	ax, MSG_GEN_APPLICATION_MARK_NOT_BUSY
	mov	di, offset WorldClockApplicationClass
	call	ObjCallSuperNoLock

done:
	.leave
	ret
WorldClockApplicationMarkNotBusy	endm

endif


CommonCode	ends
